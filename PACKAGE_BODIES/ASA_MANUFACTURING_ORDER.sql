--------------------------------------------------------
--  DDL for Package Body ASA_MANUFACTURING_ORDER
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_MANUFACTURING_ORDER" 
is
/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * Description
  *   Génération d'OF depuis le SAV
  */
  procedure GenerateMO(
    aASA_RECORD_ID      in     ASA_RECORD.ASA_RECORD_ID%type
  , aFAL_JOB_PROGRAM_ID in     FAL_JOB_PROGRAM.FAL_JOB_PROGRAM_ID%type
  , aBeginDate          in     ASA_DELAY_HISTORY.ARE_DATE_START_REP%type
  , aFAL_LOT_ID         out    FAL_LOT.FAL_LOT_ID%type
  )
  is
    tplRecord                ASA_RECORD%rowtype;
    vOrderID                 FAL_ORDER.FAL_ORDER_ID%type;
    aUserCode                number;
    vLotCompId               FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type;
    aC_SCHEDULE_PLANNING     FAL_LOT.C_SCHEDULE_PLANNING%type;
    vListIDTemp              TLIST_ID_TEMP;
    vIndex                   integer;
    vUtilCoef                FAL_LOT_MATERIAL_LINK.LOM_UTIL_COEF%type;
    lcfgASA_OF_PLANNING_CODE pcs.PC_CBASE.CBACVALUE%type;
  begin
    vIndex    := 0;

    -- recherche des infos du dossier SAV
    select *
      into tplRecord
      from ASA_RECORD
     where ASA_RECORD_ID = aASA_RECORD_ID;

    -- Création d'un OF de type SAV
    vOrderID  :=
      FAL_ORDER_FUNCTIONS.CreateManufactureOrder(aFAL_JOB_PROGRAM_ID   => aFAL_JOB_PROGRAM_ID
                                               , aGCO_GOOD_ID          => tplRecord.GCO_NEW_GOOD_ID
                                               , aDOC_RECORD_ID        => tplRecord.DOC_RECORD_ID
                                               , aC_FAB_TYPE           => FAL_BATCH_FUNCTIONS.btAfterSales
                                                );

    if nvl(vOrderID, 0) <> 0 then
      -- Création d'un lot dans l'OF créé, de type SAV
      aFAL_LOT_ID               := getNewId;
      -- Récupération du type de planification de la gamme opératoire selon config ASA_OF_PLANNING_CODE :
      --   1 : Planification selon produit
      --   2 : Planification selon Opération
      lcfgASA_OF_PLANNING_CODE  := PCS.PC_CONFIG.GetConfig('ASA_OF_PLANNING_CODE');
      FAL_BATCH_FUNCTIONS.InsertBatch(aFAL_LOT_ID             => aFAL_LOT_ID
                                    , aFAL_ORDER_ID           => vOrderID
                                    , aDIC_FAB_CONDITION_ID   => null
                                    , aSTM_STOCK_ID           => null
                                    , aSTM_LOCATION_ID        => null
                                    , aLOT_PLAN_BEGIN_DTE     => aBeginDate
                                    , aLOT_PLAN_END_DTE       => null
                                    , aLOT_ASKED_QTY          => tplRecord.ARE_REPAIR_QTY
                                    , aPPS_NOMENCLATURE_ID    => null
                                    , aFAL_SCHEDULE_PLAN_ID   => null
                                    , aC_SCHEDULE_PLANNING    => lcfgASA_OF_PLANNING_CODE
                                    , aDOC_RECORD_ID          => tplRecord.DOC_RECORD_ID
                                    , aC_FAB_TYPE             => FAL_BATCH_FUNCTIONS.btAfterSales
                                    , aLOT_SHORT_DESCR        => tplRecord.ARE_NUMBER
                                    , aC_PRIORITY             => tplRecord.C_PRIORITY
                                     );

      -- Ajout des composants dans le lot
      for tplComponents in (select *
                              from ASA_RECORD_COMP
                             where ASA_RECORD_ID = aASA_RECORD_ID
                               and ASA_RECORD_EVENTS_ID = tplRecord.ASA_RECORD_EVENTS_ID
                               and STM_COMP_STOCK_MVT_ID is null   -- Aucun mouvement manuel déjà effectué
                               and C_ASA_ACCEPT_OPTION <> 1   -- Option acceptée ou pas d'option géré
                               and ARC_CDMVT = 1) loop   -- Composant géré en stock
        select INIT_ID_SEQ.nextval
          into aUserCode
          from dual;

        -- Détermine la coefficient d'utilisation du composant par rapport au produit à réparer.
        vUtilCoef   := 1;

        if     (tplRecord.ARE_REPAIR_QTY <> 0)
           and (tplRecord.ARE_REPAIR_QTY <> tplComponents.ARC_QUANTITY) then
          vUtilCoef  := tplComponents.ARC_QUANTITY / tplRecord.ARE_REPAIR_QTY;
        end if;

        vLotCompId  :=
          FAL_COMPONENT_FUNCTIONS.CreateNewComponent(aFAL_LOT_ID        => aFAL_LOT_ID
                                                   , aGCO_GOOD_ID       => tplComponents.GCO_COMPONENT_ID
                                                   , aSTM_STOCK_ID      => tplComponents.STM_COMP_STOCK_ID
                                                   , aSTM_LOCATION_ID   => tplComponents.STM_COMP_LOCATION_ID
                                                   , aFOC_QUANTITY      => tplComponents.ARC_QUANTITY
                                                   , aLOM_NEED_DATE     => null
                                                   , aLOM_UTIL_COEF     => vUtilCoef
                                                    );

        -- Infos pour le transfert des attributions
        if tplComponents.DOC_ATTRIB_POSITION_ID is not null then
          vIndex                                        := vIndex + 1;
          vListIDTemp(vIndex).DOC_ATTRIB_POSITION_ID    := tplComponents.DOC_ATTRIB_POSITION_ID;
          vListIDTemp(vIndex).FAL_LOT_MATERIAL_LINK_ID  := vLotCompId;
        end if;
      end loop;

      -- récupération du Code planification
      select C_SCHEDULE_PLANNING
        into aC_SCHEDULE_PLANNING
        from FAL_LOT
       where FAL_LOT_ID = aFAL_LOT_ID;

      -- Ajout des opérations dans le lot
      for tplTask in (select RET.FAL_TASK_ID
                           , RET.RET_TIME
                           , RET.RET_POSITION
                        from ASA_RECORD_TASK RET
                       where RET.ASA_RECORD_ID = aASA_RECORD_ID
                         and RET.ASA_RECORD_EVENTS_ID = tplRecord.ASA_RECORD_EVENTS_ID
                         and RET.RET_TIME_USED is null
                         and RET.C_ASA_ACCEPT_OPTION <> 1) loop   -- Option acceptée ou pas d'option géré
        FAL_TASK_GENERATOR.CALL_TASK_GENERATOR(iFAL_SCHEDULE_PLAN_ID   => null
                                             , iFAL_LOT_ID             => aFAL_LOT_ID
                                             , iLOT_TOTAL_QTY          => tplRecord.ARE_REPAIR_QTY
                                             , iC_SCHEDULE_PLANNING    => aC_SCHEDULE_PLANNING
                                             , iCONTEXTE               => FAL_TASK_GENERATOR.ctxtAfterSales
                                             , iSequence               => tplTask.RET_POSITION
                                             , iFAL_TASK_ID            => tplTask.FAL_TASK_ID
                                             , iSCS_WORK_TIME          => tplTask.RET_TIME
                                              );
      end loop;

      -- Création de l'historique "Création du lot"
      FAL_BATCH_FUNCTIONS.CreateBatchHistory(aFAL_LOT_ID => aFAL_LOT_ID, aC_EVEN_TYPE => '1');
      -- Planification
      FAL_PLANIF.Planification_Lot(PrmFAL_LOT_ID              => aFAL_LOT_ID
                                 , DatePlanification          => null
                                 , SelonDateDebut             => 1
                                 , MAJReqLiensComposantsLot   => FAL_PLANIF.ctAvecMAJLienCompoLot
                                 , MAJ_Reseaux_Requise        => FAL_PLANIF.ctSansMAJReseau
                                  );

      -- Planification de base en fonction de la configuration FAL_INITIAL_PLANIFICATION
      if nvl(PCS.PC_CONFIG.GetConfig('FAL_INITIAL_PLANIFICATION'), '0') = '1' then
        FAL_BATCH_FUNCTIONS.DoBasisLotPlanification(aFAL_LOT_ID);
      end if;

      -- Mise à jour de l'ordre
      FAL_ORDER_FUNCTIONS.UpdateOrder(vOrderID);
      -- Mise à jour du programme
      FAL_PROGRAM_FUNCTIONS.UpdateManufactureProgram(aFAL_JOB_PROGRAM_ID);
      -- Mise à jour réseau Produit Terminé
      FAL_NETWORK.MiseAJourReseaux(aFAL_LOT_ID, FAL_NETWORK.ncCreationLot, null);   -- param null = AStockPositionIDList

      -- Transfert des attributions
      if vListIDTemp.count > 0 then
        for vIndex in vListIDTemp.first .. vListIDTemp.last loop
          TransferAttrib(vListIDTemp(vIndex).DOC_ATTRIB_POSITION_ID, vListIDTemp(vIndex).FAL_LOT_MATERIAL_LINK_ID);
        end loop;
      end if;

      -- Mise à jour du lot sur le Dossier SAV
      update ASA_RECORD_EVENTS
         set FAL_LOT_ID = aFAL_LOT_ID
       where ASA_RECORD_EVENTS_ID = tplRecord.ASA_RECORD_EVENTS_ID;

      -- Protection du dossier SAV
      update ASA_RECORD
         set ARE_PROTECTED = 1
       where ASA_RECORD_ID = aASA_RECORD_ID;
    end if;
  end GenerateMO;

  /**
  * procedure GenerateMO
  * Description
  *   idem précédemmment mais avec retour d'un message d'erreur
  * @created ECA 31/07/08
  */
  procedure GenerateMO(
    aASA_RECORD_ID      in     ASA_RECORD.ASA_RECORD_ID%type
  , aFAL_JOB_PROGRAM_ID in     FAL_JOB_PROGRAM.FAL_JOB_PROGRAM_ID%type
  , aBeginDate          in     ASA_DELAY_HISTORY.ARE_DATE_START_REP%type
  , aFAL_LOT_ID         out    FAL_LOT.FAL_LOT_ID%type
  , aErrorMsg           out    varchar2
  )
  is
  begin
    aErrorMsg  := '';
    GenerateMO(aASA_RECORD_ID, aFAL_JOB_PROGRAM_ID, aBeginDate, aFAL_LOT_ID);
  exception
    when FAL_BATCH_FUNCTIONS.excMissingFixedCostprice then
      aErrorMsg  := FAL_BATCH_FUNCTIONS.excMissingFixedCostpriceMsg;
    when others then
      aErrorMsg  := FAL_BATCH_FUNCTIONS.excGenericErrorMsg || sqlerrm;
  end;

/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * procedure TransferAttrib
  * Description
  *   Transfert de l'attribution du composant
  * @created David Saadé 02.11.2006
  */
  procedure TransferAttrib(aPositionID in ASA_RECORD_COMP.DOC_ATTRIB_POSITION_ID%type, aLotCompID in FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type)
  is
  begin
    null;
  end TransferAttrib;

/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * Description
  *   Mise à jour du dossier SAV après réception d'OF
  */
  procedure UpdateRecordOnReception(aFAL_LOT_ID in FAL_LOT.FAL_LOT_ID%type)
  is
    tplEvents ASA_RECORD_EVENTS%rowtype;
  begin
    -- Recherche du dossier SAV à mettre à jour
    select *
      into tplEvents
      from ASA_RECORD_EVENTS
     where FAL_LOT_ID = aFAL_LOT_ID;

    -- Suppression des composants, ainsi que leur référence sur les positions, qui ont été transféré sur le lot de fabrication
    update DOC_POSITION
       set ASA_RECORD_COMP_ID = null
     where ASA_RECORD_COMP_ID in(
             select ASA_RECORD_COMP_ID
               from ASA_RECORD_COMP
              where ASA_RECORD_EVENTS_ID = tplEvents.ASA_RECORD_EVENTS_ID
                and STM_COMP_STOCK_MVT_ID is null   -- Aucun mouvement manuel déjà effectué
                and C_ASA_ACCEPT_OPTION <> 1   -- Option acceptée ou pas d'option géré
                and ARC_CDMVT = 1);   -- Demande un mouvement de stock

    delete from ASA_RECORD_COMP
          where ASA_RECORD_EVENTS_ID = tplEvents.ASA_RECORD_EVENTS_ID
            and STM_COMP_STOCK_MVT_ID is null   -- Aucun mouvement manuel déjà effectué
            and C_ASA_ACCEPT_OPTION <> 1
            -- Option acceptée ou pas d'option géré
            and ARC_CDMVT = 1;   -- Demande un mouvement de stock

    -- Ajout des composants du lot
    AddComponents(tplEvents, aFAL_LOT_ID);

    -- Suppression des opérations, ainsi que leur référence sur les positions, qui ont été transféré sur le lot de fabrication
    update DOC_POSITION
       set ASA_RECORD_TASK_ID = null
     where ASA_RECORD_TASK_ID in(select ASA_RECORD_TASK_ID
                                   from ASA_RECORD_TASK
                                  where ASA_RECORD_EVENTS_ID = tplEvents.ASA_RECORD_EVENTS_ID
                                    and RET_TIME_USED is null
                                    and C_ASA_ACCEPT_OPTION <> 1);   -- Option acceptée ou pas d'option géré

    delete from ASA_RECORD_TASK
          where ASA_RECORD_EVENTS_ID = tplEvents.ASA_RECORD_EVENTS_ID
            and RET_TIME_USED is null
            and C_ASA_ACCEPT_OPTION <> 1;   -- Option acceptée ou pas d'option géré

    -- Ajout des opérations du lot
    AddTasks(tplEvents, aFAL_LOT_ID);

    -- Déprotection du dossier SAV
    update ASA_RECORD
       set ARE_PROTECTED = 0
     where ASA_RECORD_ID = tplEvents.ASA_RECORD_ID;
  end UpdateRecordOnReception;

/*--------------------------------------------------------------------------------------------------------------------*/
/**
* Description
*   Ajout d'un composant au dossier SAV passé en paramètre
*/
  procedure AddComponents(tplEvents in ASA_RECORD_EVENTS%rowtype, aLotID in FAL_LOT.FAL_LOT_ID%type)
  is
  begin
    -- Ajout du composant
    insert into ASA_RECORD_COMP
                (ASA_RECORD_COMP_ID
               , ASA_RECORD_ID
               , ASA_RECORD_EVENTS_ID
               , FAL_FACTORY_OUT_ID
               , ARC_POSITION
               , GCO_COMPONENT_ID
               --   , GCO_CHAR1_ID
               --   , GCO_CHAR2_ID
               --   , GCO_CHAR3_ID
               --   , GCO_CHAR4_ID
               --   , GCO_CHAR5_ID
               --   , ARC_CHAR1_VALUE
               --   , ARC_CHAR2_VALUE
               --   , ARC_CHAR3_VALUE
               --   , ARC_CHAR4_VALUE
               --   , ARC_CHAR5_VALUE
    ,            ARC_PIECE
               , ARC_SET
               , ARC_VERSION
               , ARC_CHRONOLOGICAL
               , ARC_DESCR
               , ARC_DESCR2
               , ARC_DESCR3
               --    , STM_COMP_STOCK_ID
               --    , STM_COMP_LOCATION_ID
    ,            ARC_COST_PRICE
               --    , ARC_SALE_PRICE
    ,            ARC_QUANTITY
               , ARC_CDMVT
               , STM_COMP_MVT_KIND_ID
               , STM_COMP_STOCK_MVT_ID
               --    , ARC_MOVEMENT_DATE
               --    , ARC_OPTIONAL
               --    , ARC_GUARANTY_CODE
               --    , DIC_GARANTY_CODE_ID
               --    , C_ASA_GEN_DOC_POS
               --    , ARC_SALE_PRICE2
               --    , ARC_FREE_NUM1
               --    , ARC_FREE_NUM2
               --    , ARC_FREE_CHAR1
               --    , ARC_FREE_CHAR2
               --    , DIC_ASA_FREE_DICO_COMP1_ID
               --    , DIC_ASA_FREE_DICO_COMP2_ID
               --    , C_ASA_ACCEPT_OPTION
               --    , ARC_SALE_PRICE_ME
               --    , ARC_SALE_PRICE_EURO
               --    , ARC_SALE_PRICE2_ME
               --    , ARC_SALE_PRICE2_EURO
               --    , ARC_NB_DAYS_APPRO
               --    , STM_WORK_STOCK_ID
               --    , STM_WORK_LOCATION_ID
               --    , STM_WORK_STOCK_MOVEMENT_ID
               --    , DOC_ATTRIB_POSITION_ID
               --    , ARC_STD_CHAR_1
               --    , ARC_STD_CHAR_2
               --    , ARC_STD_CHAR_3
               --    , ARC_STD_CHAR_4
               --    , ARC_STD_CHAR_5
    ,            A_DATECRE
               , A_IDCRE
                )
      select init_id_seq.nextval   -- ASA_RECORD_COMP_ID
           , tplEvents.ASA_RECORD_ID   -- ASA_RECORD_ID
           , tplEvents.ASA_RECORD_EVENTS_ID   -- ASA_RECORD_EVENTS_ID
           , FFO.FAL_FACTORY_OUT_ID   -- FAL_FACTORY_OUT_ID
           , (select nvl(max(ARC_POSITION), 0)
                from ASA_RECORD_COMP
               where ASA_RECORD_EVENTS_ID = tplEvents.ASA_RECORD_EVENTS_ID) + 10 * rownum   -- ARC_POSITION
           , FFO.GCO_GOOD_ID   -- GCO_COMPONENT_ID
           --, -- GCO_CHAR1_ID
           --, -- GCO_CHAR2_ID
           --, -- GCO_CHAR3_ID
           --, -- GCO_CHAR4_ID
           --, -- GCO_CHAR5_ID
           --, -- ARC_CHAR1_VALUE
           --, -- ARC_CHAR2_VALUE
           --, -- ARC_CHAR3_VALUE
           --, -- ARC_CHAR4_VALUE
           --, -- ARC_CHAR5_VALUE
      ,      FFO.OUT_PIECE   -- ARC_PIECE
           , FFO.OUT_LOT   -- ARC_SET
           , FFO.OUT_VERSION   -- ARC_VERSION
           , FFO.OUT_CHRONOLOGY   -- ARC_CHRONOLOGICAL
           , DES.DES_SHORT_DESCRIPTION   -- ARC_DESCR
           , DES.DES_LONG_DESCRIPTION   -- ARC_DESCR2
           , DES.DES_FREE_DESCRIPTION   -- ARC_DESCR3
           -- ,      -- STM_COMP_STOCK_ID
                -- ,    -- STM_COMP_LOCATION_ID
      ,      FFO.OUT_PRICE   -- ARC_COST_PRICE
           --, -- ARC_SALE_PRICE
      ,      FFO.OUT_QTE   -- ARC_QUANTITY
           , 0   -- ARC_CDMVT
           , SMO.STM_MOVEMENT_KIND_ID   -- STM_COMP_MVT_KIND_ID
           , SMO.STM_STOCK_MOVEMENT_ID   -- STM_COMP_STOCK_MVT_ID
           --, -- ARC_MOVEMENT_DATE
           --, -- ARC_OPTIONAL
           --, -- ARC_GUARANTY_CODE
           --, -- DIC_GARANTY_CODE_ID
           --, -- C_ASA_GEN_DOC_POS
           --, -- ARC_SALE_PRICE2
           --, -- ARC_FREE_NUM1
           --, -- ARC_FREE_NUM2
           --, -- ARC_FREE_CHAR1
           --, -- ARC_FREE_CHAR2
           --, -- DIC_ASA_FREE_DICO_COMP1_ID
           --, -- DIC_ASA_FREE_DICO_COMP2_ID
           --, -- C_ASA_ACCEPT_OPTION
           --, -- ARC_SALE_PRICE_ME
           --, -- ARC_SALE_PRICE_EURO
           --, -- ARC_SALE_PRICE2_ME
           --, -- ARC_SALE_PRICE2_EURO
           --, -- ARC_NB_DAYS_APPRO
           --, -- STM_WORK_STOCK_ID
           --, -- STM_WORK_LOCATION_ID
           --, -- STM_WORK_STOCK_MOVEMENT_ID
           --, -- DOC_ATTRIB_POSITION_ID
           --, -- ARC_STD_CHAR_1
           --, -- ARC_STD_CHAR_2
           --, -- ARC_STD_CHAR_3
           --, -- ARC_STD_CHAR_4
           --, -- ARC_STD_CHAR_5
      ,      sysdate   -- A_DATECRE
           , pcs.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from FAL_FACTORY_OUT FFO
           , GCO_DESCRIPTION DES
           , STM_STOCK_MOVEMENT SMO
       where FFO.C_OUT_TYPE = '1'
         and FFO.C_OUT_ORIGINE = '1'
         and FFO.FAL_LOT_ID = aLotID
         and DES.GCO_GOOD_ID = FFO.GCO_GOOD_ID
         and DES.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
         and DES.C_DESCRIPTION_TYPE = '01'
         and FFO.FAL_FACTORY_OUT_ID(+) = SMO.FAL_FACTORY_OUT_ID;
  end AddComponents;

/*--------------------------------------------------------------------------------------------------------------------*/
/**
* Description
*   Ajout d'un composant au dossier SAV passé en paramètre
*/
  procedure AddTasks(tplEvents in ASA_RECORD_EVENTS%rowtype, aLotID in FAL_LOT.FAL_LOT_ID%type)
  is
    vMinConflictNumber FAL_TASK_LINK.SCS_STEP_NUMBER%type;
  begin
    /* Controle conflit entre le numéro de séquence d'une opération du dossier SAV
    et d'une opération de l'Ordre de Fabrication.*/

    /* Récupérer la valeur minimal en conflit entre le numéro de séquence SAV
    et l'ordre de fabrication*/
    select min(TAL.SCS_STEP_NUMBER)
      into vMinConflictNumber
      from FAL_TASK_LINK TAL
         , ASA_RECORD_TASK RET
     where TAL.FAL_LOT_ID = aLotID
       and RET.ASA_RECORD_ID = tplEvents.ASA_RECORD_ID
       and TAL.SCS_STEP_NUMBER = RET.RET_POSITION;

    -- Si vMinConflictNumber a une valeur ==> conflit
    if vMinConflictNumber is not null then
      declare
        vStep          integer := PCS.PC_CONFIG.GetConfig('ASA_TASK_INCREMENT');
        vCurrentNumber integer;
      begin
        -- Récupération du numéro le plus élevé de séquence OF
        -- pour la numérotation selon Max(Séquence des opérations OF) +
        -- Séquence selon config.ASA_TASK_INCREMENT
        select max(SCS_STEP_NUMBER)
          into vCurrentNumber
          from FAL_TASK_LINK
         where FAL_LOT_ID = aLotId;

        -- Initialisation de vCurrentNumber a l'écart entre (max+incrément) et
        -- l'ancinne numérotation du premier conflit
        vCurrentNumber  := (vCurrentNumber + vStep) - vMinConflictNumber;

        -- Renumérotation depuis le denier ordre à être renuméroté
        -- au premier conflit
        for tplRenumbering in (select   RET_POSITION   --Le numéro de séquence
                                      , ASA_RECORD_TASK_ID
                                   from ASA_RECORD_TASK
                                  where ASA_RECORD_ID = tplEvents.ASA_RECORD_ID
                                    and RET_POSITION >= vMinConflictNumber   -- Tous les numéros de séquence => a la valeur du premier conflit
                               order by RET_POSITION desc) loop
          -- Mise à jour du numéro de séquence selon nouvelle numérotation
          update ASA_RECORD_TASK
             set RET_POSITION = tplRenumbering.RET_POSITION + vCurrentNumber   -- Ajout de l'écart au numéro existant
           where ASA_RECORD_TASK_ID = tplRenumbering.ASA_RECORD_TASK_ID;
        end loop;
      end;
    end if;

    -- Ajout du composant
    insert into ASA_RECORD_TASK
                (ASA_RECORD_TASK_ID
               , ASA_RECORD_ID
               , ASA_RECORD_EVENTS_ID
               , FAL_LOT_PROGRESS_ID
               , RET_FINISHED
               , RET_POSITION
               , GCO_BILL_GOOD_ID
               , FAL_TASK_ID
               , FAL_FACTORY_FLOOR_ID
               , DIC_OPERATOR_ID
               , RET_TIME
               , RET_TIME_USED
               , RET_DESCR
               , RET_DESCR2
               , RET_DESCR3
               -- , -- RET_AMOUNT
               -- , -- RET_SALE_AMOUNT
               -- , -- RET_SALE_AMOUNT2
    ,            RET_WORK_RATE
               , RET_COST_PRICE
               -- , -- RET_GUARANTY_CODE
               -- , -- DIC_GARANTY_CODE_ID
               -- , -- C_ASA_GEN_DOC_POS
               -- , -- RET_OPTIONAL
               -- , -- C_ASA_ACCEPT_OPTION
               -- , -- DIC_ASA_FREE_DICO_TASK1_ID
               -- , -- DIC_ASA_FREE_DICO_TASK2_ID
               -- , -- RET_FREE_NUM1
               -- , -- RET_FREE_NUM2
               -- , -- RET_FREE_CHAR1
               -- , -- RET_FREE_CHAR2
               -- , -- RET_SALE_AMOUNT_ME
               -- , -- RET_SALE_AMOUNT_EURO
               -- , -- RET_SALE_AMOUNT2_ME
               -- , -- RET_SALE_AMOUNT2_EURO
               -- , -- RET_AMOUNT_ME
               -- , -- RET_AMOUNT_EURO
               -- , -- RET_EXTERNAL
    ,            A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   -- ASA_RECORD_TASK_ID
           , tplEvents.ASA_RECORD_ID   -- ASA_RECORD_ID
           , tplEvents.ASA_RECORD_EVENTS_ID   -- ASA_RECORD_EVENTS_ID
           , FLP.FAL_LOT_PROGRESS_ID   -- FAL_LOT_PROGRESS_ID
           , 1   -- RET_FINISHED
           , TAL.SCS_STEP_NUMBER   -- RET_POSITION
           , (select max(GCO_GOOD_ID)
                from GCO_GOOD
               where GOO_MAJOR_REFERENCE = pcs.pc_config.GetConfig('ASA_DEFAULT_TASK_BILL_GOOD') )   -- GCO_BILL_GOOD_ID
           , FLP.FAL_TASK_ID   -- FAL_TASK_ID
           , FLP.FAL_FACTORY_FLOOR_ID   -- FAL_FACTORY_FLOOR_ID
           , FLP.DIC_OPERATOR_ID   -- DIC_OPERATOR_ID
           , nvl(TAL.TAL_DUE_TSK, 0)   -- RET_TIME
           , nvl(TAL.TAL_ACHIEVED_TSK, 0) + nvl(TAL.TAL_ACHIEVED_AD_TSK, 0)   --RET_TIME_USED
           , TAL.SCS_SHORT_DESCR   -- RET_DESCR
           , TAL.SCS_LONG_DESCR   -- RET_DESCR2
           , TAL.SCS_FREE_DESCR   -- RET_DESCR3
            --,   -- RET_AMOUNT
           -- , -- RET_SALE_AMOUNT
           -- , -- RET_SALE_AMOUNT2
      ,      1   -- RET_WORK_RATE
           , FAL_FACT_FLOOR.GetDateRateValue(FAC.FAL_FACTORY_FLOOR_ID, sysdate, 1)   -- RET_COST_PRICE = FAL_FACTORY_RATE.FFR_RATE1
           -- , -- RET_GUARANTY_CODE
           -- , -- DIC_GARANTY_CODE_ID
           -- , -- C_ASA_GEN_DOC_POS
           -- , -- RET_OPTIONAL
           -- , -- C_ASA_ACCEPT_OPTION
           -- , -- DIC_ASA_FREE_DICO_TASK1_ID
           -- , -- DIC_ASA_FREE_DICO_TASK2_ID
           -- , -- RET_FREE_NUM1
           -- , -- RET_FREE_NUM2
           -- , -- RET_FREE_CHAR1
           -- , -- RET_FREE_CHAR2
           -- , -- RET_SALE_AMOUNT_ME
           -- , -- RET_SALE_AMOUNT_EURO
           -- , -- RET_SALE_AMOUNT2_ME
           -- , -- RET_SALE_AMOUNT2_EURO
           -- , -- RET_AMOUNT_ME
           -- , -- RET_AMOUNT_EURO
           -- , -- RET_EXTERNAL
      ,      sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from FAL_TASK_LINK TAL
           , FAL_LOT_PROGRESS FLP
           , FAL_FACTORY_FLOOR FAC
       where TAL.FAL_LOT_ID = aLotID
         and TAL.FAL_SCHEDULE_STEP_ID = FLP.FAL_SCHEDULE_STEP_ID
         and FAC.FAL_FACTORY_FLOOR_ID = FLP.FAL_FACTORY_FLOOR_ID
         and FLP.FAL_LOT_PROGRESS_ID = (select max(SUB_FLP.FAL_LOT_PROGRESS_ID)
                                          from FAL_LOT_PROGRESS SUB_FLP
                                         where SUB_FLP.FAL_SCHEDULE_STEP_ID = TAL.FAL_SCHEDULE_STEP_ID);
  -- On teste le FAL_LOT_PROGRESS_ID avec le max de FAL_LOT_PROGRESS_ID afin :
  --   de n'insérer qu'un enregistrement par opération même s'il y a plusieurs suivis
  --   de n'insérer d'enregistrement que si l'opération possède au moins un suivi
  end AddTasks;
end ASA_MANUFACTURING_ORDER;
