--------------------------------------------------------
--  DDL for Package Body FAL_BATCH_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_BATCH_FUNCTIONS" 
is
  -- ID unique de la session utilisé dans toutes les procédures de (dé)réservation
  cSessionId   constant FAL_LOT1.LT1_ORACLE_SESSION%type   := DBMS_SESSION.unique_session_id;
  -- Configurations
  cInitLotRefCompl      varchar2(10)                       := PCS.PC_CONFIG.GetConfigUpper('FAL_INIT_LOTREFCOMPL');
  cCoupledGood          varchar2(10)                       := PCS.PC_CONFIG.GetConfig('FAL_COUPLED_GOOD');
  cCalcRecept           varchar2(10)                       := PCS.PC_CONFIG.GetConfig('FAL_CALC_RECEPT');
  cProgressType         varchar2(10)                       := PCS.PC_CONFIG.GetConfig('FAL_PROGRESS_TYPE');
  cPairingCaract        varchar2(10)                       := PCS.PC_CONFIG.GetConfig('FAL_PAIRING_CHARACT') || ',3';
  cfgFAL_PGM_REF_LENGTH integer                            := PCS.PC_CONFIG.GetConfig('FAL_PGM_REF_LENGTH');
  cfgFAL_ORD_REF_LENGTH integer                            := PCS.PC_CONFIG.GetConfig('FAL_ORD_REF_LENGTH');
  cfgFAL_LOT_REF_LENGTH integer                            := PCS.PC_CONFIG.GetConfig('FAL_LOT_REF_LENGTH');

  /**
  * Procedure ExecExternalProcBAUReception
  * Description : Execution des procédure avant / après réception PT, rebut PT, démontage
  *
  * @author ECA
  * @lastUpdate

  * @param   aCallMode               avant / après
  * @param   aCEvenType              Type d'évenement (C_EVEN_TYPE), parmis récetion PT, rebut PT, Démontage
  * @param   aFalLotId               Id du lot
  * @param   aCFabType               Type de lot
  * @param   aDismountQty            Quantité à démonter
  * @param   aReceptQty              Quantité à réceptionner
  * @param   aReceptRejectQty        Quantité à réceptionner rebut
  * @param   ReturnCompoIsScrap      Détermine si les composants restants au solde ou au démontage sont par défaut retourné en déchet ou stock
  * @param   aDate                   Date de réception
  * @param   aCompoStockId           Stock de destination du retour composants au solde ou au démontage
  * @param   aCompoLocationId        Emplacement de destination du retour composants au solde ou au démontage
  * @param   aCompoRejectStockId     Stock de destination des déchets composants au solde ou au démontage
  * @param   aCompoRejectLocationId  Emplacement de destination des déchets composants au solde ou au démontage
  * @param   aDestStockId            Stock de destination
  * @param   aDestLocationId         Emplacement de destination
  * @param   BatchBalance            Solde du lot ou non
  * @param   aUnitPrice              Prix unitaire (peut être envoyé par la post-calculation en réception)
  * @param   aFalOrderId             Id de l'ordre
  * @param   iStmStmStockId          Stock consommation des composants
  * @param   iStmStmLocationId       Emplacement consommation des composants
  */
  procedure ExecExternalProcBAUReception(
    iCallMode              in varchar2 default null
  , iCEvenType             in FAL_HISTO_LOT.C_EVEN_TYPE%type default null
  , iFalLotId              in FAL_LOT.FAL_LOT_ID%type default null
  , iDismountQty           in number default null
  , iReceptQty             in number default null
  , iReceptRejectQty       in number default null
  , iReturnCompoIsScrap    in integer default null
  , iDate                  in date default null
  , iCompoStockId          in STM_STOCK.STM_STOCK_ID%type default null
  , iCompoLocationId       in STM_LOCATION.STM_LOCATION_ID%type default null
  , iCompoRejectStockId    in STM_STOCK.STM_STOCK_ID%type default null
  , iCompoRejectLocationId in STM_LOCATION.STM_LOCATION_ID%type default null
  , iDestStockId           in STM_STOCK.STM_STOCK_ID%type default null
  , iDestLocationId        in STM_LOCATION.STM_LOCATION_ID%type default null
  , iBatchBalance          in integer default null
  , iUnitPrice             in number default null
  , iStmStmStockId         in STM_STOCK.STM_STOCK_ID%type default null
  , iStmStmLocationId      in STM_LOCATION.STM_LOCATION_ID%type default null
  )
  is
    cfgFAL_PROC_PL_AFTER_RECEPT  PCS.PC_CBASE.CBACVALUE%type;
    cfgFAL_PROC_PL_BEFORE_RECEPT PCS.PC_CBASE.CBACVALUE%type;
    lvExternalProc               varchar2(4000);
  begin
    cfgFAL_PROC_PL_AFTER_RECEPT   := PCS.PC_CONFIG.GetConfig('FAL_PROC_PL_AFTER_UNIT_RECEPT');
    cfgFAL_PROC_PL_BEFORE_RECEPT  := PCS.PC_CONFIG.GetConfig('FAL_PROC_PL_BEFORE_UNIT_RECEPT');

    -- Appel before
    if     iCallMode = 'BEFORE'
       and cfgFAL_PROC_PL_BEFORE_RECEPT is not null then
      lvExternalProc  :=
        'begin ' ||
        cfgFAL_PROC_PL_BEFORE_RECEPT ||
        '(' ||
        '      :iCEvenType' ||
        '     , :iFalLotId' ||
        '     , :iDismountQty' ||
        '     , :iReceptQty' ||
        '     , :iReceptRejectQty' ||
        '     , :iReturnCompoIsScrap' ||
        '     , :iReceptDate' ||
        '     , :iPTStockId' ||
        '     , :iPTLocationID' ||
        '     , :iCompoStockId' ||
        '     , :iCompoLocationId' ||
        '     , :iCompoRejectStockId' ||
        '     , :iCompoRejectLocationId' ||
        '     , :iUnitPrice' ||
        '     , :iConsoStockId' ||
        '     , :iConsoLocationId' ||
        '     , :iBatchBalance' ||
        '     ); ' ||
        'end;';
    -- Appel After
    elsif     iCallMode = 'AFTER'
          and cfgFAL_PROC_PL_AFTER_RECEPT is not null then
      lvExternalProc  :=
        'begin ' ||
        cfgFAL_PROC_PL_AFTER_RECEPT ||
        '(' ||
        '       :iCEvenType' ||
        '     , :iFalLotId' ||
        '     , :iDismountQty' ||
        '     , :iReceptQty' ||
        '     , :iReceptRejectQty' ||
        '     , :iReturnCompoIsScrap' ||
        '     , :iReceptDate' ||
        '     , :iPTStockId' ||
        '     , :iPTLocationID' ||
        '     , :iCompoStockId' ||
        '     , :iCompoLocationId' ||
        '     , :iCompoRejectStockId' ||
        '     , :iCompoRejectLocationId' ||
        '     , :iUnitPrice' ||
        '     , :iConsoStockId' ||
        '     , :iConsoLocationId' ||
        '     , :iBatchBalance' ||
        '  ); ' ||
        'end;';
    else
      return;
    end if;

    execute immediate lvExternalProc
                using in iCEvenType
                    , in iFalLotId
                    , in iDismountQty
                    , in iReceptQty
                    , in iReceptRejectQty
                    , in iReturnCompoIsScrap
                    , in iDate
                    , in iDestStockId
                    , in iDestLocationId
                    , in iCompoStockId
                    , in iCompoLocationId
                    , in iCompoRejectStockId
                    , in iCompoRejectLocationId
                    , in iUnitPrice
                    , in iStmStmStockId
                    , in iStmStmLocationId
                    , in iBatchBalance;
  exception
    when others then
      begin
        raise_application_error(-20000, PCS.PC_FUNCTIONS.TranslateWord('Erreur pendant l''exécution de la procédure stockée') || cfgFAL_PROC_PL_AFTER_RECEPT);
      end;
  end;

  /**
  * function UpdateSMORefCompl
  * Description : Mise à jour des référence de lots dans les mvts de stock en cas de renumérotation
  *
  * @author CLE
  */
  procedure UpdateSMORefCompl
  is
    VarFAL_LOT_ID FAl_LOT.FAL_LOT_ID%type;

    cursor Curs
    is
      select STM_STOCK_MOVEMENT_ID
           , SMO_WORDING
        from stm_stock_movement
       where smo_wording <= '999999999999999999'
         and smo_wording > '000000000000000000'
         and length(smo_wording) = 18;

    buff          varchar2(2000);

    type Tenrstm_stock_movement is record(
      stm_stock_movement_id stm_stock_movement.STM_STOCK_MOVEMENT_ID%type
    , smo_wording           stm_stock_movement.SMO_WORDING%type
    );

    enr           Tenrstm_stock_movement;
  begin
    open Curs;

    loop
      fetch Curs
       into enr;

      exit when Curs%notfound;

      select nvl(min(fal_lot_id), 0)
        into VarFAL_LOT_ID
        from fal_lot
       where lot_refcompl = enr.SMO_WORDING
         and nvl(C_FAB_TYPE, btManufacturing) <> btSubcontract;

      if VarFAL_LOT_ID > 0 then
        Buff  := FAL_TOOLS.Format_lot_generic(VarFAL_LOT_ID);

        declare
          vCRUD_DEF fwk_i_typ_definition.T_CRUD_DEF;
        begin
          FWK_I_MGT_ENTITY.new(FWK_I_TYP_STM_ENTITY.gcStmStockMovement, vCRUD_DEF, false, enr.stm_stock_movement_id, null, 'STM_STOCK_MOVEMENT_ID');
          FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_WORDING', buff);
          FWK_I_MGT_ENTITY.UpdateEntity(vCRUD_DEF);
          FWK_I_MGT_ENTITY.Release(vCRUD_DEF);
        end;
      else   -- Alors on recherche avec les FAL_LOT_HIST
        select nvl(min(fal_lot_hist_id), 0)
          into VarFAL_LOT_ID
          from fal_lot_HIST
         where lot_refcompl = enr.SMO_WORDING;

        if VarFAL_LOT_ID > 0 then
          Buff  := FAL_TOOLS.Format_lot_hist_generic(VarFAL_LOT_ID);

          declare
            vCRUD_DEF fwk_i_typ_definition.T_CRUD_DEF;
          begin
            FWK_I_MGT_ENTITY.new(FWK_I_TYP_STM_ENTITY.gcStmStockMovement, vCRUD_DEF, false, enr.stm_stock_movement_id, null, 'STM_STOCK_MOVEMENT_ID');
            FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_WORDING', buff);
            FWK_I_MGT_ENTITY.UpdateEntity(vCRUD_DEF);
            FWK_I_MGT_ENTITY.Release(vCRUD_DEF);
          end;
        end if;
      end if;
    end loop;

    close Curs;
  end UpdateSMORefCompl;

/**
  * function isBatchWithPairing
  * Description
  *   Détermine s'il faut faire de l'appairage sur le lot. L'appairage est demandé quand le produit terminé
  *   est caractérisé "Pièce" et qu'au moins un de ses composants est "Pièce" ou activé par la configuration FAL_PAIRING_CHARACT.
  * @author CLE
  * @param   aFalLotId           Id du lot du PT
  * @param   aGcoGoodId          Id du bien PT
  * @param   aComponentGoodId    Id du composant à tester. Recherche sur tous les composants si null.
  * @param   bSearchInTmpCompo   Détermine si on recherche dans les composants ou les composants temporaires
  * @return  Renvoie 1 si le produit et au moins un de ses composants sont gérés caractéristique pièce
  *          (caractéristique géré stock). False sinon
  */
  function isBatchWithPairing(aFalLotId number, aGcoGoodId number default null, aComponentGoodId number default null, bSearchInTmpCompo boolean default false)
    return integer
  is
    aChaStockManagement gco_characterization.cha_stock_management%type;
    cntComponents       number;
    nGcoGoodId          number;
  begin
    nGcoGoodId  := aGcoGoodId;

    if nvl(nGcoGoodId, 0) = 0 then
      select GCO_GOOD_ID
        into nGcoGoodId
        from FAL_LOT
       where FAL_LOT_ID = aFalLotId;
    end if;

    select max(CHA_STOCK_MANAGEMENT)
      into aChaStockManagement
      from GCO_CHARACTERIZATION
     where GCO_GOOD_ID = nGcoGoodId
       and C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypePiece;

    if nvl(aChaStockManagement, 0) = 1 then
      if bSearchInTmpCompo then
        select count(*)
          into cntComponents
          from FAL_LOT_MAT_LINK_TMP LOM
         where FAL_LOT_ID = aFalLotId
           and (   nvl(aComponentGoodId, 0) = 0
                or aComponentGoodId = LOM.GCO_GOOD_ID)
           and exists(select GCO_CHARACTERIZATION_ID
                        from GCO_CHARACTERIZATION
                       where GCO_GOOD_ID = LOM.GCO_GOOD_ID
                         and nvl(CHA_STOCK_MANAGEMENT, 0) = 1
                         and instr(cPairingCaract, C_CHARACT_TYPE) > 0);
      else
        select count(*)
          into cntComponents
          from FAL_LOT_MATERIAL_LINK LOM
         where FAL_LOT_ID = aFalLotId
           and (   nvl(aComponentGoodId, 0) = 0
                or aComponentGoodId = LOM.GCO_GOOD_ID)
           and exists(select GCO_CHARACTERIZATION_ID
                        from GCO_CHARACTERIZATION
                       where GCO_GOOD_ID = LOM.GCO_GOOD_ID
                         and nvl(CHA_STOCK_MANAGEMENT, 0) = 1
                         and instr(cPairingCaract, C_CHARACT_TYPE) > 0);
      end if;

      if cntComponents > 0 then
        return 1;
      else
        return 0;
      end if;
    end if;

    return 0;
  end;

  /**
  * function GetNewLotRef
  * Description
  *   Obtention d'une nouvelle référence de lot
  * @author CLE
  * @param      iFalOrderId   ordre d'apartenance du lot
  * @param      iStartValue   Référence du lot de départ
  * @return     Nouvel référence de lot en fonction de la config FAL_LOT_NUMBERING
  */
  function GetNewLotRef(iFalOrderId in number, iStartValue in integer default null)
    return number
  is
    liMaxLotRef        integer;
    licFalLotNumbering integer;
  begin
    licFalLotNumbering  := to_number(PCS.PC_CONFIG.GetConfig('FAL_LOT_NUMBERING') );

    if iStartValue is null then
      -- Sélection du plus grand LOT_REF des tables FAL_LOT et FAL_LOT_HIST
      select greatest( (select nvl(max(LOT_REF), 0)
                          from FAL_LOT
                         where FAL_ORDER_ID = iFalOrderId), (select nvl(max(LOT_REF), 0)
                                                               from FAL_LOT_HIST
                                                              where FAL_ORDER_HIST_ID = iFalOrderId) )
        into liMaxLotRef
        from dual;
    else
      liMaxLotRef  := iStartValue;
    end if;

    if (liMaxLotRef mod licFalLotNumbering) <> 0 then
      liMaxLotRef  := (round(liMaxLotRef / licFalLotNumbering) * licFalLotNumbering) + licFalLotNumbering;
    else
      liMaxLotRef  := liMaxLotRef + licFalLotNumbering;
    end if;

    if liMaxLotRef >= power(10, to_number(PCS.PC_CONFIG.GetConfig('FAL_LOT_REF_LENGTH') ) ) then
      raise_application_error(-20010, 'PCS - ' || excRefComplMsg);
    end if;

    return liMaxLotRef;
  end;

  /**
  * Procedure CreateBatchHistory
  * Description
  *   Historisation des événements des lots
  * @author CLE
  * @param      aFAL_LOT_ID   Id du lot
  * @param      aC_EVEN_TYPE  Type d'événement
  * @param      ReceptQty     Quantité à la réception
  * @param      aContext      Contexte (réception, solde)
  * @param      aFalHistoLotId Id de l'historique de l'OF qui sera créé
  * @version 2003
  * @lastUpdate
  */
  procedure CreateBatchHistory(
    aFAL_LOT_ID    in fal_lot.fal_lot_id%type
  , aC_EVEN_TYPE   in fal_histo_lot.c_even_type%type default null
  , ReceptQty      in fal_lot.lot_inprod_qty%type default null
  , aContext       in integer default null
  , aReceptionType in integer default null
  , aFalHistoLotId in number default null
  )
  is
    vCEvenType FAL_HISTO_LOT.C_EVEN_TYPE%type;
  begin
    if aC_EVEN_TYPE is not null then
      vCEvenType  := aC_EVEN_TYPE;
    elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchBalance then
      vCEvenType  := etBalanced;
    elsif aReceptionType = rtFinishedProduct then
      vCEvenType  := etReception;
    elsif aReceptionType = rtReject then
      vCEvenType  := etReceptionRejects;
    elsif aReceptionType = rtDismantling then
      vCEvenType  := etDismounting;
    elsif aReceptionType = rtBatchAssembly then
      vCEvenType  := etAssembly;
    end if;

    -- Insertion de l'historique
    insert into FAL_HISTO_LOT
                (FAL_HISTO_LOT_ID   -- Id Historique
               , FAL_LOT5_ID   -- Id Lot
               , HIS_REFCOMPL   -- Référence complète du lot
               , C_EVEN_TYPE   -- Le type d'évenement
               , HIS_PLAN_BEGIN_DTE   -- Date Planifiée Début
               , HIS_PLAN_END_DTE   -- Date Planifiée fin
               , HIS_INPROD_QTE   -- Qte en Fabrication 6
               , HIS_QTE   -- Qté réception
               , A_DATECRE   -- Date de création
               , A_IDCRE   -- Id Création
                )
      select nvl(aFalHistoLotId, GetNewId)
           , aFAL_LOT_ID
           , LOT_REFCOMPL
           , vCEvenType
           , LOT_PLAN_BEGIN_DTE
           , LOT_PLAN_END_DTE
           , LOT_INPROD_QTY
           , ReceptQty
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        from fal_lot
       where FAL_LOT_ID = aFAL_LOT_ID;
  exception
    when others then
      raise_application_error(-20011, 'PCS - ' || excBatchHistoryMsg);
  end;

  /**
  * Procedure CreateBatchHistory
  * Description
  *   Idem précédemment avec un code erreur en place d'exception
  */
  procedure CreateBatchHistory(
    aFAL_LOT_ID    in     fal_lot.fal_lot_id%type
  , aC_EVEN_TYPE   in     fal_histo_lot.c_even_type%type default null
  , aErrorCode     in out varchar2
  , ReceptQty      in     fal_lot.lot_inprod_qty%type default null
  , aContext       in     integer default null
  , aReceptionType in     integer default null
  , aFalHistoLotId in     number default null
  )
  is
  begin
    CreateBatchHistory(aFAL_LOT_ID, aC_EVEN_TYPE, ReceptQty, aContext, aReceptionType, aFalHistoLotId);
  exception
    when excBatchHistory then
      aErrorCode  := 'excBatchHistory';
  end;

  /**
  * Procedure DoBasisLotPlanification
  * Description
  *   Planification de base du lot de fabrication
  * @author CLE
  * @param      aFAL_LOT_ID   Id du lot
  * @version 2003
  * @lastUpdate
  */
  procedure DoBasisLotPlanification(aFAL_LOT_ID FAL_LOT.FAL_LOT_ID%type)
  is
  begin
    update FAL_LOT
       set LOT_BASIS_BEGIN_DTE = LOT_PLAN_BEGIN_DTE
         , LOT_BASIS_END_DTE = LOT_PLAN_END_DTE
         , LOT_BASIS_LEAD_TIME = LOT_PLAN_LEAD_TIME
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_LOT_ID = aFAL_LOT_ID;

    update FAL_TASK_LINK
       set TAL_BASIS_BEGIN_DATE = TAL_BEGIN_PLAN_DATE
         , TAL_BASIS_END_DATE = TAL_END_PLAN_DATE
         , TAL_TASK_BASIS_TIME = TAL_TASK_MANUF_TIME
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_LOT_ID = aFAL_LOT_ID;
  end;

  /**
   * Procedure GenerateLotRefcompl
   * Description
   *   Génère la référence complète du lot
   * @author CLE
   * @param      aJOP_REFERENCE   Référence du programme
   * @param      aORD_REF         Référence de l'ordre
   * @param      aLOT_REF         Référence du lot
   * @version 2003
   * @lastUpdate
   */
  function GenerateLotRefcompl(aJOP_REFERENCE fal_job_program.jop_reference%type, aORD_REF fal_order.ord_ref%type, aLOT_REF fal_lot.lot_ref%type)
    return varchar2
  is
  begin
    return PCS.PC_CONFIG.GetConfig('FAL_PROGRAM_PREFIX') ||
           lpad(aJOP_REFERENCE, PCS.PC_CONFIG.GetConfig('FAL_PGM_REF_LENGTH'), '0') ||
           PCS.PC_CONFIG.GetConfig('FAL_SEPAR_PROGRAM_ORDER') ||
           lpad(aORD_REF, PCS.PC_CONFIG.GetConfig('FAL_ORD_REF_LENGTH'), '0') ||
           PCS.PC_CONFIG.GetConfig('FAL_SEPAR_ORDER_LOT') ||
           lpad(aLOT_REF, PCS.PC_CONFIG.GetConfig('FAL_LOT_REF_LENGTH'), '0');
  end;

  /**
  * function InsertBatch
  * Description
  *   Création d'un nouveau lot de fabrication
  * @author CLE
  * @lastUpdate
  * @return     True si pas de problème à la création du lot, False sinon
  */
  function InsertBatch(
    -- paramètres obligatoire
    aFAL_LOT_ID                    fal_lot.fal_lot_id%type
  , aFAL_ORDER_ID                  fal_lot.fal_order_id%type
  , aDIC_FAB_CONDITION_ID          fal_lot.dic_fab_condition_id%type
  , aSTM_STOCK_ID                  fal_lot.stm_stock_id%type
  , aSTM_LOCATION_ID               fal_lot.stm_location_id%type
  , aLOT_PLAN_BEGIN_DTE            fal_lot.lot_plan_begin_dte%type
  , aLOT_PLAN_END_DTE              fal_lot.lot_plan_end_dte%type
  , aLOT_ASKED_QTY                 fal_lot.lot_asked_qty%type
  , aPPS_NOMENCLATURE_ID           fal_lot.pps_nomenclature_id%type
  , aFAL_SCHEDULE_PLAN_ID          fal_lot.fal_schedule_plan_id%type
  , aC_SCHEDULE_PLANNING           fal_lot.c_schedule_planning%type
  -- paramètres par défaut
  , aGCO_GOOD_ID                   fal_lot.gco_good_id%type default null
  , aDOC_RECORD_ID                 fal_lot.doc_record_id%type default null
  , aSTM_STM_STOCK_ID              fal_lot.stm_stock_id%type default null
  , aSTM_STM_LOCATION_ID           fal_lot.stm_stm_location_id%type default null
  , aLOT_TOLERANCE                 fal_lot.lot_tolerance%type default null
  , aLOT_SHORT_DESCR               fal_lot.lot_short_descr%type default null
  , aLOT_LONG_DESCR                fal_lot.lot_long_descr%type default null
  , aLOT_FREE_DESCR                fal_lot.lot_free_descr%type default null
  , aDIC_FAMILY_ID                 fal_lot.dic_family_id%type default null
  , aC_PRIORITY                    fal_lot.c_priority%type default null
  , aDIC_LOT_CODE2_ID              fal_lot.dic_lot_code2_id%type default null
  , aDIC_LOT_CODE3_ID              fal_lot.dic_lot_code3_id%type default null
  , aLOT_FREE_NUM1                 fal_lot.lot_free_num1%type default null
  , aLOT_FREE_NUM2                 fal_lot.lot_free_num2%type default null
  , aLOT_REJECT_PLAN_QTY           fal_lot.lot_reject_plan_qty%type default 0
  , aLOT_PLAN_VERSION              fal_lot.lot_plan_version%type default null
  , aLOT_PLAN_NUMBER               fal_lot.lot_plan_number%type default null
  , aGCO_QUALITY_PRINCIPLE_ID      fal_lot.gco_quality_principle_id%type default null
  , aPPS_OPERATION_PROCEDURE_ID    fal_lot.pps_operation_procedure_id%type default null
  , aC_FAB_TYPE                    fal_lot.C_FAB_TYPE%type default 0
  , aLOT_ORIGIN_REF                fal_lot.LOT_ORIGIN_REF%type default null
  , aPC_YEAR_WEEK_ID               fal_lot.PC_YEAR_WEEK_ID%type default null
  , aPC__PC_YEAR_WEEK_ID           fal_lot.PC__PC_YEAR_WEEK_ID%type default null
  , aPC_2_PC_YEAR_WEEK_ID          fal_lot.PC_2_PC_YEAR_WEEK_ID%type default null
  , aPC_3_PC_YEAR_WEEK_ID          fal_lot.PC_3_PC_YEAR_WEEK_ID%type default null
  , aC_LOT_STATUS                  fal_lot.C_LOT_STATUS%type default null
  , aLOT_TO_BE_RELEASED            fal_lot.LOT_TO_BE_RELEASED%type default null
  , aFAL_FAL_SCHEDULE_PLAN_ID      fal_lot.FAL_FAL_SCHEDULE_PLAN_ID%type default null
  , aLOT_REF_QTY                   fal_lot.LOT_REF_QTY%type default null
  , aLOT_VERSION_ORIGIN_NUM        fal_lot.LOT_VERSION_ORIGIN_NUM%type default null
  , aLOT_PSHORT_DESCR              fal_lot.LOT_PSHORT_DESCR%type default null
  , aLOT_PFREE_TEXT                fal_lot.LOT_PFREE_TEXT%type default null
  , aLOT_OPEN__DTE                 fal_lot.LOT_OPEN__DTE%type default null
  , aLOT_PTEXT                     fal_lot.LOT_PTEXT%type default null
  , aLOT_MODIFY                    fal_lot.LOT_MODIFY%type default null
  , aLOT_SECOND_REF                fal_lot.LOT_SECOND_REF%type default null
  , aLOT_TOTAL_QTY                 fal_lot.LOT_TOTAL_QTY%type default null
  , aLOT_INPROD_QTY                fal_lot.LOT_INPROD_QTY%type default null
  , aLOT_RELEASE_QTY               fal_lot.LOT_RELEASE_QTY%type default null
  , aPTC_FIXED_COSTPRICE_ID        fal_lot.PTC_FIXED_COSTPRICE_ID%type default null
  , aLOT_PLAN_LEAD_TIME            fal_lot.LOT_PLAN_LEAD_TIME%type default null
  , aLOT_ORT_UPDATE_DELAY          fal_lot.LOT_ORT_UPDATE_DELAY%type default null
  , iLotRefCompl                in fal_lot.lot_refcompl%type default null
  )
    return boolean
  is
    cursor Cur_FAL_ORDER
    is
      select FO.FAL_JOB_PROGRAM_ID
           , FO.ORD_SECOND_REF
           , FO.ORD_PSHORT_DESCR
           , FO.ORD_PLONG_DESCR
           , FO.ORD_PFREE_DESCR
           , FO.ORD_REF
           , FO.DIC_FAMILY_ID
           , FJP.JOP_REFERENCE
        from FAL_ORDER FO
           , FAL_JOB_PROGRAM FJP
       where FO.FAL_JOB_PROGRAM_ID = FJP.FAL_JOB_PROGRAM_ID
         and FAL_ORDER_ID = aFAL_ORDER_ID;

    cursor cur_PPS_NOMENCLATURE
    is
      select FAL_SCHEDULE_PLAN_ID   -- gamme opératoire liée à la nomenclature
           , NOM_VERSION   -- Version nomenclature origine
           , NOM_REF_QTY
        from PPS_NOMENCLATURE
       where PPS_NOMENCLATURE_ID = aPPS_NOMENCLATURE_ID;

    CurFAL_ORDER            Cur_FAL_ORDER%rowtype;
    curPPS_NOMENCLATURE     Cur_PPS_NOMENCLATURE%rowtype;
    aLOT_REF                fal_lot.lot_ref%type;
    nGCO_GOOD_ID            number;
    cLOT_TOTAL_QTY          FAL_LOT.LOT_TOTAL_QTY%type;
    aLOT_REFCOMPL           FAL_LOT.lot_refcompl%type;
    nC_SCHEDULE_PLANNING    FAL_LOT.C_SCHEDULE_PLANNING%type;
    nSTM_STOCK_ID           FAL_LOT.STM_STOCK_ID%type;
    nSTM_LOCATION_ID        FAL_LOT.STM_LOCATION_ID%type;
    nPTC_FIXED_COSTPRICE_ID number;
  begin
    open Cur_FAL_ORDER;

    fetch Cur_FAL_ORDER
     into CurFAL_ORDER;

    close Cur_FAL_ORDER;

    open cur_PPS_NOMENCLATURE;

    fetch cur_PPS_NOMENCLATURE
     into curPPS_NOMENCLATURE;

    close cur_PPS_NOMENCLATURE;

    -- Type de planification
    if aC_SCHEDULE_PLANNING is null then
      if aFAL_SCHEDULE_PLAN_ID is not null then
        select C_SCHEDULE_PLANNING
          into nC_SCHEDULE_PLANNING
          from FAL_SCHEDULE_PLAN
         where FAL_SCHEDULE_PLAN_ID = aFAL_SCHEDULE_PLAN_ID;
      else
        nC_SCHEDULE_PLANNING  := 1;
      end if;
    else
      nC_SCHEDULE_PLANNING  := aC_SCHEDULE_PLANNING;
    end if;

    -- Référence lot
    aLOT_REF        := null;
    aLOT_REF        := GetNewLotREF(aFAL_ORDER_ID, aLOT_REF);
    -- Référence complète
    aLOT_REFCOMPL   := nvl(iLotRefCompl, GenerateLotRefcompl(CurFAL_ORDER.JOP_REFERENCE, CurFAL_ORDER.ORD_REF, aLOT_REF) );

    -- Produit
    if aGCO_GOOD_ID is null then
      select GCO_GOOD_ID
        into nGCO_GOOD_ID
        from FAL_ORDER
       where FAL_ORDER_ID = aFAL_ORDER_ID;
    else
      nGCO_GOOD_ID  := aGCO_GOOD_ID;
    end if;

    -- Calcul de la quantité totale du lot
    cLOT_TOTAL_QTY  := nvl(aLOT_ASKED_QTY, 0) + nvl(aLOT_REJECT_PLAN_QTY, 0);
    -- Stock et emplacement de destination
    FAL_TOOLS.GetStockEmpWithPrmsAndGood(aSTM_STOCK_ID, aSTM_LOCATION_ID, nGCO_GOOD_ID, nSTM_STOCK_ID, nSTM_LOCATION_ID);

    -- Prix de revient pour comptabilité industrielle obligatoire si lot <> Planifié
    if     PCS.PC_CONFIG.GETCONFIG('FAL_USE_ACCOUNTING') in('1', '2')
       and nvl(aC_LOT_STATUS, 1) > 1 then
      nPTC_FIXED_COSTPRICE_ID  := nvl(aPTC_FIXED_COSTPRICE_ID, PTC_FUNCTIONS.GetAccountingFixedCostprice(nGCO_GOOD_ID) );

      if nPTC_FIXED_COSTPRICE_ID is null then
        Raise_Application_error(-20016, 'PCS - ' || excMissingFixedCostpriceMsg);
      end if;
    end if;

    insert into FAL_LOT
                (FAL_LOT_ID
               , FAL_ORDER_ID
               , FAL_JOB_PROGRAM_ID   -- Id du programme de Fab
               , LOT_REF   -- Référence du lot
               , GCO_GOOD_ID   -- Produit
               , LOT_SECOND_REF   -- référence secondaire
               , LOT_PSHORT_DESCR   -- Description courte produit
               , LOT_PTEXT   -- Description longue produit
               , LOT_PFREE_TEXT   -- Description libre Produit
               , LOT_REFCOMPL   -- Référence complète du lot
               , LOT_SHORT_DESCR   -- Description courte du lot
               , LOT_LONG_DESCR
               , LOT_FREE_DESCR
               , C_LOT_STATUS   -- Statut du lot
               , LOT_TO_BE_RELEASED   -- Lancer
               , DIC_FAB_CONDITION_ID   -- Condition de fabrication
               , C_SCHEDULE_PLANNING   -- Code Planification
               , FAL_SCHEDULE_PLAN_ID   -- Gamme opératoire
               , PPS_NOMENCLATURE_ID   -- Nomenclature origine
               , LOT_VERSION_ORIGIN_NUM   -- Version de Nomenclature origine
               , FAL_FAL_SCHEDULE_PLAN_ID   -- Gamme op liée à la nomenclature d'origine
               , LOT_PLAN_VERSION   -- version de plan
               , LOT_PLAN_NUMBER   -- N° de PLAN
               , GCO_QUALITY_PRINCIPLE_ID   -- Principe Qualité
               , PPS_OPERATION_PROCEDURE_ID   -- Procédure
               , DOC_RECORD_ID   -- Dossier
               , STM_STOCK_ID   -- Stock destination
               , STM_LOCATION_ID   -- Emplacement destination
               , STM_STM_STOCK_ID   -- Stock consommation
               , STM_STM_LOCATION_ID   -- Stock consommation
               , LOT_ASKED_QTY   -- Qte demandée
               , LOT_REJECT_PLAN_QTY   -- Qte rebut planifiée
               , LOT_TOTAL_QTY   -- Qte Lot Total
               , LOT_RELEASE_QTY   -- Qte Lancée
               , LOT_INPROD_QTY   -- Qte en Fabrication
               , LOT_PT_REJECT_QTY   -- Qte Rebut PT
               , LOT_CPT_REJECT_QTY   -- Qte Rebut CPT
               , LOT_RELEASED_QTY   -- Qte receptionnée
               , LOT_REJECT_RELEASED_QTY   -- Qte rebut receptionnée
               , LOT_DISMOUNTED_QTY   -- Qte démontée
               , LOT_FREE_QTY   -- Qte Libre
               , LOT_ALLOCATED_QTY   -- Qte Attribuée
               , LOT_MAX_PROD_QTY   -- Qte Max Fabricable
               , LOT_MAX_RELEASABLE_QTY   -- Qte Max Receptionnable
               , LOT_PLAN_BEGIN_DTE   -- Date Planifiée Début
               , LOT_PLAN_END_DTE   -- Date Planifiée fin
               , LOT_TOLERANCE   -- Marge
               , C_PRIORITY
               , C_FAB_TYPE
               , DIC_LOT_CODE2_ID
               , DIC_LOT_CODE3_ID
               , LOT_FREE_NUM1
               , LOT_FREE_NUM2
               , LOT_MODIFY   -- Lot modifié
               , DIC_FAMILY_ID   -- Code Famille
               , LOT_REF_QTY   -- Qté ref nomenclature
               , A_DATECRE   -- DAte création
               , A_IDCRE   -- Id Création
               , LOT_ORIGIN_REF
               , PC_YEAR_WEEK_ID
               , PC__PC_YEAR_WEEK_ID
               , PC_2_PC_YEAR_WEEK_ID
               , PC_3_PC_YEAR_WEEK_ID
               , LOT_OPEN__DTE
               , PTC_FIXED_COSTPRICE_ID
               , LOT_PLAN_LEAD_TIME
               , LOT_ORT_UPDATE_DELAY
                )
         values (aFAL_LOT_ID
               , aFAL_ORDER_ID
               , CurFAL_ORDER.FAL_JOB_PROGRAM_ID   -- Id du programme
               , aLOT_REF   -- Référence du lot
               , nGCO_GOOD_ID   -- Produit
               , nvl(aLOT_SECOND_REF, CurFAL_ORDER.ORD_SECOND_REF)   -- référence secondaire
               , nvl(aLOT_PSHORT_DESCR, CurFAL_ORDER.ORD_PSHORT_DESCR)   -- Description Courte
               , nvl(aLOT_PTEXT, CurFAL_ORDER.ORD_PLONG_DESCR)   -- Description Longue
               , nvl(aLOT_PFREE_TEXT, CurFAL_ORDER.ORD_PFREE_DESCR)   -- Description Free
               , aLOT_REFCOMPL   -- référence complète du lot
               , aLOT_SHORT_DESCR   -- Description courte du lot
               , aLOT_LONG_DESCR
               , aLOT_FREE_DESCR
               , nvl(aC_LOT_STATUS, bsPlanned)
               , nvl(aLOT_TO_BE_RELEASED, 0)
               , aDIC_FAB_CONDITION_ID   -- Condition de fabrication
               , nC_SCHEDULE_PLANNING   -- Code planification
               , aFAL_SCHEDULE_PLAN_ID   -- Gamme opératoire
               , aPPS_NOMENCLATURE_ID   -- Nomenclature d'origine
               , nvl(aLOT_VERSION_ORIGIN_NUM, curPPS_NOMENCLATURE.NOM_VERSION)   -- Version de nomenclature origine
               , nvl(aFAL_FAL_SCHEDULE_PLAN_ID, curPPS_NOMENCLATURE.FAL_SCHEDULE_PLAN_ID)   -- Gamme op liée à la nomenclature d'origine
               , aLOT_PLAN_VERSION   -- Version de Plan
               , aLOT_PLAN_NUMBER   -- N° de Plan
               , aGCO_QUALITY_PRINCIPLE_ID   -- Principe Qualité
               , aPPS_OPERATION_PROCEDURE_ID   -- Procédure
               , aDOC_RECORD_ID   -- Dossier
               , nSTM_STOCK_ID   -- Stock destination
               , nSTM_LOCATION_ID   -- Emlpacement destination
               , aSTM_STM_STOCK_ID   -- Stock consommation
               , aSTM_STM_LOCATION_ID   -- Stock consommation
               , aLOT_ASKED_QTY   -- Qte demandée
               , aLOT_REJECT_PLAN_QTY   -- Qte rebut planifiée
               , nvl(aLOT_TOTAL_QTY, cLOT_TOTAL_QTY)   -- Qte Lot Total
               , nvl(aLOT_RELEASE_QTY, 0)   -- Qte Lancée
               , nvl(aLOT_INPROD_QTY, cLOT_TOTAL_QTY)   -- Qte en Fabrication (= Qte Totale)
               , 0   -- Qte Rebut PT
               , 0   -- Qte Rebut CPT
               , 0   -- Qte Réceptionnée
               , 0   -- Qte rebut receptionnée
               , 0   -- Qte démontée
               , aLOT_ASKED_QTY   -- Qte Libre (= Qte Demandée)
               , 0   -- Qte Attribuée
               , 0   -- Qte Max Fabricable
               , 0   -- Qte Max Receptionnable
               , aLOT_PLAN_BEGIN_DTE   -- Date Planifiée Début
               , aLOT_PLAN_END_DTE   -- Date Planifiée fin
               , aLOT_TOLERANCE   -- Marge
               , aC_PRIORITY
               , aC_FAB_TYPE
               , aDIC_LOT_CODE2_ID
               , aDIC_LOT_CODE3_ID
               , aLOT_FREE_NUM1
               , aLOT_FREE_NUM2
               , nvl(aLOT_MODIFY, 0)   -- lot Modifié
               , nvl(aDIC_FAMILY_ID, CurFAL_ORDER.DIC_FAMILY_ID)   -- Code Famille
               , nvl(aLOT_REF_QTY, nvl(curPPS_NOMENCLATURE.NOM_REF_QTY, 1) )   -- Qté ref nomenclature
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , aLOT_ORIGIN_REF
               , aPC_YEAR_WEEK_ID
               , aPC__PC_YEAR_WEEK_ID
               , aPC_2_PC_YEAR_WEEK_ID
               , aPC_3_PC_YEAR_WEEK_ID
               , aLOT_OPEN__DTE
               , nPTC_FIXED_COSTPRICE_ID
               , aLOT_PLAN_LEAD_TIME
               , aLOT_ORT_UPDATE_DELAY
                );

    return true;
  exception
    when dup_val_on_index then
      return false;
    when others then
      raise;
  end;

  /**
  * Procedure InsertBatch
  * Description
  *   Création d'un nouveau lot de fabrication
  * @author CLG
  * @lastUpdate
  * @return
  */
  procedure InsertBatch(
    -- paramètres obligatoire
    aFAL_LOT_ID                    fal_lot.fal_lot_id%type
  , aFAL_ORDER_ID                  fal_lot.fal_order_id%type
  , aDIC_FAB_CONDITION_ID          fal_lot.dic_fab_condition_id%type
  , aSTM_STOCK_ID                  fal_lot.stm_stock_id%type
  , aSTM_LOCATION_ID               fal_lot.stm_location_id%type
  , aLOT_PLAN_BEGIN_DTE            fal_lot.lot_plan_begin_dte%type
  , aLOT_PLAN_END_DTE              fal_lot.lot_plan_end_dte%type
  , aLOT_ASKED_QTY                 fal_lot.lot_asked_qty%type
  , aPPS_NOMENCLATURE_ID           fal_lot.pps_nomenclature_id%type
  , aFAL_SCHEDULE_PLAN_ID          fal_lot.fal_schedule_plan_id%type
  , aC_SCHEDULE_PLANNING           fal_lot.c_schedule_planning%type
  -- paramètres par défaut
  , aGCO_GOOD_ID                   fal_lot.gco_good_id%type default null
  , aDOC_RECORD_ID                 fal_lot.doc_record_id%type default null
  , aSTM_STM_STOCK_ID              fal_lot.stm_stock_id%type default null
  , aSTM_STM_LOCATION_ID           fal_lot.stm_stm_location_id%type default null
  , aLOT_TOLERANCE                 fal_lot.lot_tolerance%type default null
  , aLOT_SHORT_DESCR               fal_lot.lot_short_descr%type default null
  , aLOT_LONG_DESCR                fal_lot.lot_long_descr%type default null
  , aLOT_FREE_DESCR                fal_lot.lot_free_descr%type default null
  , aDIC_FAMILY_ID                 fal_lot.dic_family_id%type default null
  , aC_PRIORITY                    fal_lot.c_priority%type default null
  , aDIC_LOT_CODE2_ID              fal_lot.dic_lot_code2_id%type default null
  , aDIC_LOT_CODE3_ID              fal_lot.dic_lot_code3_id%type default null
  , aLOT_FREE_NUM1                 fal_lot.lot_free_num1%type default null
  , aLOT_FREE_NUM2                 fal_lot.lot_free_num2%type default null
  , aLOT_REJECT_PLAN_QTY           fal_lot.lot_reject_plan_qty%type default 0
  , aLOT_PLAN_VERSION              fal_lot.lot_plan_version%type default null
  , aLOT_PLAN_NUMBER               fal_lot.lot_plan_number%type default null
  , aGCO_QUALITY_PRINCIPLE_ID      fal_lot.gco_quality_principle_id%type default null
  , aPPS_OPERATION_PROCEDURE_ID    fal_lot.pps_operation_procedure_id%type default null
  , aC_FAB_TYPE                    fal_lot.C_FAB_TYPE%type default 0
  , aLOT_ORIGIN_REF                fal_lot.LOT_ORIGIN_REF%type default null
  , aPC_YEAR_WEEK_ID               fal_lot.PC_YEAR_WEEK_ID%type default null
  , aPC__PC_YEAR_WEEK_ID           fal_lot.PC__PC_YEAR_WEEK_ID%type default null
  , aPC_2_PC_YEAR_WEEK_ID          fal_lot.PC_2_PC_YEAR_WEEK_ID%type default null
  , aPC_3_PC_YEAR_WEEK_ID          fal_lot.PC_3_PC_YEAR_WEEK_ID%type default null
  , aC_LOT_STATUS                  fal_lot.C_LOT_STATUS%type default null
  , aLOT_TO_BE_RELEASED            fal_lot.LOT_TO_BE_RELEASED%type default null
  , aFAL_FAL_SCHEDULE_PLAN_ID      fal_lot.FAL_FAL_SCHEDULE_PLAN_ID%type default null
  , aLOT_REF_QTY                   fal_lot.LOT_REF_QTY%type default null
  , aLOT_VERSION_ORIGIN_NUM        fal_lot.LOT_VERSION_ORIGIN_NUM%type default null
  , aLOT_PSHORT_DESCR              fal_lot.LOT_PSHORT_DESCR%type default null
  , aLOT_PFREE_TEXT                fal_lot.LOT_PFREE_TEXT%type default null
  , aLOT_OPEN__DTE                 fal_lot.LOT_OPEN__DTE%type default null
  , aLOT_PTEXT                     fal_lot.LOT_PTEXT%type default null
  , aLOT_MODIFY                    fal_lot.LOT_MODIFY%type default null
  , aLOT_SECOND_REF                fal_lot.LOT_SECOND_REF%type default null
  , aLOT_TOTAL_QTY                 fal_lot.LOT_TOTAL_QTY%type default null
  , aLOT_INPROD_QTY                fal_lot.LOT_INPROD_QTY%type default null
  , aLOT_RELEASE_QTY               fal_lot.LOT_RELEASE_QTY%type default null
  , aPTC_FIXED_COSTPRICE_ID        fal_lot.PTC_FIXED_COSTPRICE_ID%type default null
  , aLOT_PLAN_LEAD_TIME            fal_lot.LOT_PLAN_LEAD_TIME%type default null
  , aLOT_ORT_UPDATE_DELAY          fal_lot.LOT_ORT_UPDATE_DELAY%type default null
  , iLotRefCompl                in fal_lot.lot_refcompl%type default null
  )
  is
  begin
    loop
      exit when InsertBatch(aFAL_LOT_ID
                          , aFAL_ORDER_ID
                          , aDIC_FAB_CONDITION_ID
                          , aSTM_STOCK_ID
                          , aSTM_LOCATION_ID
                          , aLOT_PLAN_BEGIN_DTE
                          , aLOT_PLAN_END_DTE
                          , aLOT_ASKED_QTY
                          , aPPS_NOMENCLATURE_ID
                          , aFAL_SCHEDULE_PLAN_ID
                          , aC_SCHEDULE_PLANNING
                          , aGCO_GOOD_ID
                          , aDOC_RECORD_ID
                          , aSTM_STM_STOCK_ID
                          , aSTM_STM_LOCATION_ID
                          , aLOT_TOLERANCE
                          , aLOT_SHORT_DESCR
                          , aLOT_LONG_DESCR
                          , aLOT_FREE_DESCR
                          , aDIC_FAMILY_ID
                          , aC_PRIORITY
                          , aDIC_LOT_CODE2_ID
                          , aDIC_LOT_CODE3_ID
                          , aLOT_FREE_NUM1
                          , aLOT_FREE_NUM2
                          , aLOT_REJECT_PLAN_QTY
                          , aLOT_PLAN_VERSION
                          , aLOT_PLAN_NUMBER
                          , aGCO_QUALITY_PRINCIPLE_ID
                          , aPPS_OPERATION_PROCEDURE_ID
                          , aC_FAB_TYPE
                          , aLOT_ORIGIN_REF
                          , aPC_YEAR_WEEK_ID
                          , aPC__PC_YEAR_WEEK_ID
                          , aPC_2_PC_YEAR_WEEK_ID
                          , aPC_3_PC_YEAR_WEEK_ID
                          , aC_LOT_STATUS
                          , aLOT_TO_BE_RELEASED
                          , aFAL_FAL_SCHEDULE_PLAN_ID
                          , aLOT_REF_QTY
                          , aLOT_VERSION_ORIGIN_NUM
                          , aLOT_PSHORT_DESCR
                          , aLOT_PFREE_TEXT
                          , aLOT_OPEN__DTE
                          , aLOT_PTEXT
                          , aLOT_MODIFY
                          , aLOT_SECOND_REF
                          , aLOT_TOTAL_QTY
                          , aLOT_INPROD_QTY
                          , aLOT_RELEASE_QTY
                          , aPTC_FIXED_COSTPRICE_ID
                          , aLOT_PLAN_LEAD_TIME
                          , aLOT_ORT_UPDATE_DELAY
                          , iLotRefCompl
                           ) = true;
    end loop;
  end;

  /**
  * procedure CreateBatch
  * Description
  *   Création d'un lot de fabrication :
  *     - Création du lot
  *     - Génération des détails lot (produit couplé)
  *     - Génération des opérations
  *     - Générations des composants
  *     - Création de l'historique "Création du lot"
  *     - Planification du lot
  *     - Mise à jour de l'ordre
  *     - Mise à jour du programme
  *     - Mise à jour des réseaux
  * @author CLE
  * @lastUpdate
  * @public
  */
  procedure CreateBatch(
    aFAL_ORDER_ID               in     fal_lot.fal_order_id%type
  , aDIC_FAB_CONDITION_ID       in     fal_lot.dic_fab_condition_id%type
  , aSTM_STOCK_ID               in     fal_lot.stm_stock_id%type
  , aSTM_LOCATION_ID            in     fal_lot.stm_location_id%type
  , aLOT_PLAN_BEGIN_DTE         in     fal_lot.lot_plan_begin_dte%type
  , aLOT_PLAN_END_DTE           in     fal_lot.lot_plan_end_dte%type
  , aLOT_ASKED_QTY              in     fal_lot.lot_asked_qty%type
  , aPPS_NOMENCLATURE_ID        in     fal_lot.pps_nomenclature_id%type
  , aFAL_SCHEDULE_PLAN_ID       in     fal_lot.fal_schedule_plan_id%type
  -- Paramètre avec valeur par défaut
  , aDOC_RECORD_ID              in     fal_lot.doc_record_id%type default null
  , aGCO_GOOD_ID                in     fal_lot.gco_good_id%type
  , aLOT_REJECT_PLAN_QTY        in     fal_lot.lot_reject_plan_qty%type default 0
  , aLOT_TOLERANCE              in     fal_lot.lot_tolerance%type default null
  , aLOT_PLAN_VERSION           in     fal_lot.lot_plan_version%type default null
  , aLOT_PLAN_NUMBER            in     fal_lot.lot_plan_number%type default null
  , aLOT_SHORT_DESCR            in     fal_lot.lot_short_descr%type default null
  , aLOT_LONG_DESCR             in     fal_lot.lot_long_descr%type default null
  , aLOT_FREE_DESCR             in     fal_lot.lot_free_descr%type default null
  , aSTM_STM_STOCK_ID           in     fal_lot.stm_stock_id%type default null
  , aSTM_STM_LOCATION_ID        in     fal_lot.stm_stm_location_id%type default null
  , aDIC_FAMILY_ID              in     fal_lot.dic_family_id%type default null
  , aC_PRIORITY                 in     fal_lot.c_priority%type default null
  , aGCO_QUALITY_PRINCIPLE_ID   in     fal_lot.gco_quality_principle_id%type default null
  , aPPS_OPERATION_PROCEDURE_ID in     fal_lot.pps_operation_procedure_id%type default null
  , aDIC_LOT_CODE2_ID           in     fal_lot.dic_lot_code2_id%type default null
  , aDIC_LOT_CODE3_ID           in     fal_lot.dic_lot_code3_id%type default null
  , aLOT_FREE_NUM1              in     fal_lot.lot_free_num1%type default null
  , aLOT_FREE_NUM2              in     fal_lot.lot_free_num2%type default null
  , aC_EVEN_TYPE                in     fal_histo_lot.c_even_type%type default etCreated
  , PlanifOnBeginDate           in     integer default 1
  , aC_FAB_TYPE                 in     fal_lot.c_fab_type%type default 0
  , aC_DISCHARGE_COM            in     GCO_COMPL_DATA_SUBCONTRACT.C_DISCHARGE_COM%type default null
  , aFAL_JOB_PROGRAM_ID         in     fal_lot.fal_job_program_id%type default null
  , aJOP_SHORT_DESCR            in     fal_job_program.jop_short_descr%type default null
  , aORD_OSHORT_DESCR           in     fal_order.ord_oshort_descr%type default null
  , aPTC_FIXED_COSTPRICE_ID     in     fal_lot.PTC_FIXED_COSTPRICE_ID%type default null
  , iPacSupplierPartnerId       in     number default null
  , iGcoGcoGoodId               in     number default null
  , iScsAmount                  in     number default 0
  , iScsQtyRefAmount            in     integer default 0
  , iScsDivisorAmount           in     integer default 0
  , iScsWeigh                   in     integer default 0
  , iScsWeighMandatory          in     integer default 0
  , iLotRefCompl                in     fal_lot.lot_refcompl%type default null
  , aCreatedFAL_LOT_ID          in out number
  )
  is
    aLOT_TOTAL_QTY                 fal_lot.lot_total_qty%type;
    vGCO_GOOD_ID                   fal_lot.gco_good_id%type;
    lnDocRecordId                  fal_lot.doc_record_id%type;
    aLOT_REFCOMPL                  fal_lot.lot_refcompl%type;
    aC_SCHEDULE_PLANNING           fal_lot.c_schedule_planning%type;
    vFAL_JOB_PROGRAM_ID            fal_lot.fal_job_program_id%type;
    vFAL_ORDER_ID                  fal_lot.fal_order_id%type;
    aGCO_COMPL_DATA_MANUFACTURE_ID gco_compl_data_manufacture.gco_compl_data_manufacture_id%type;
    aUserCode                      number;
    nPTC_FIXED_COSTPRICE_ID        number;
    ltGCO_COMPL_DATA_SUBCONTRACT   GCO_COMPL_DATA_SUBCONTRACT%rowtype;
    lvProcName                     varchar2(4000);
  begin
    -- ID du lot
    aCreatedFAL_LOT_ID  := GetNewId;

    if nvl(aFAL_ORDER_ID, 0) = 0 then
      -- Création d'un programme de fabrication s'il n'existe pas
      if nvl(aFAL_JOB_PROGRAM_ID, 0) = 0 then
        vFAL_JOB_PROGRAM_ID  := FAL_PROGRAM_FUNCTIONS.CreateManufactureProgram(aJOP_SHORT_DESCR, aDOC_RECORD_ID);
      else
        vFAL_JOB_PROGRAM_ID  := aFAL_JOB_PROGRAM_ID;
      end if;

      -- Création d'un ordre de fabrication
      vGCO_GOOD_ID   := aGCO_GOOD_ID;
      vFAL_ORDER_ID  :=
        FAL_ORDER_FUNCTIONS.CreateManufactureOrder(aFAL_JOB_PROGRAM_ID   => vFAL_JOB_PROGRAM_ID
                                                 , aGCO_GOOD_ID          => vGCO_GOOD_ID
                                                 , aDOC_RECORD_ID        => aDOC_RECORD_ID
                                                 , aC_FAB_TYPE           => aC_FAB_TYPE
                                                 , aORD_OSHORT_DESCR     => aORD_OSHORT_DESCR
                                                  );
    else
      select FAL_JOB_PROGRAM_ID
           , FAL_ORDER_ID
           , GCO_GOOD_ID
           , DOC_RECORD_ID
        into vFAL_JOB_PROGRAM_ID
           , vFAL_ORDER_ID
           , vGCO_GOOD_ID
           , lnDocRecordId
        from FAL_ORDER
       where FAL_ORDER_ID = aFAL_ORDER_ID;
    end if;

    -- initialisation du Code planification
    if aFAL_SCHEDULE_PLAN_ID is not null then
      select C_SCHEDULE_PLANNING
        into aC_SCHEDULE_PLANNING
        from FAL_SCHEDULE_PLAN
       where FAL_SCHEDULE_PLAN_ID = aFAL_SCHEDULE_PLAN_ID;
    else
      aC_SCHEDULE_PLANNING  := 1;
    end if;

    -- insertion du lot de fabrication
    InsertBatch(aFAL_LOT_ID                   => aCreatedFAL_LOT_ID
              , aFAL_ORDER_ID                 => vFAL_ORDER_ID
              , aDIC_FAB_CONDITION_ID         => aDIC_FAB_CONDITION_ID
              , aSTM_STOCK_ID                 => aSTM_STOCK_ID
              , aSTM_LOCATION_ID              => aSTM_LOCATION_ID
              , aLOT_PLAN_BEGIN_DTE           => aLOT_PLAN_BEGIN_DTE
              , aLOT_PLAN_END_DTE             => aLOT_PLAN_END_DTE
              , aLOT_ASKED_QTY                => aLOT_ASKED_QTY
              , aPPS_NOMENCLATURE_ID          => aPPS_NOMENCLATURE_ID
              , aFAL_SCHEDULE_PLAN_ID         => aFAL_SCHEDULE_PLAN_ID
              , aC_SCHEDULE_PLANNING          => aC_SCHEDULE_PLANNING
              , aGCO_GOOD_ID                  => vGCO_GOOD_ID
              , aDOC_RECORD_ID                => nvl(aDOC_RECORD_ID, lnDocRecordId)
              , aSTM_STM_STOCK_ID             => aSTM_STM_STOCK_ID
              , aSTM_STM_LOCATION_ID          => aSTM_STM_LOCATION_ID
              , aLOT_TOLERANCE                => aLOT_TOLERANCE
              , aLOT_SHORT_DESCR              => aLOT_SHORT_DESCR
              , aLOT_LONG_DESCR               => aLOT_LONG_DESCR
              , aLOT_FREE_DESCR               => aLOT_FREE_DESCR
              , aDIC_FAMILY_ID                => aDIC_FAMILY_ID
              , aC_PRIORITY                   => aC_PRIORITY
              , aDIC_LOT_CODE2_ID             => aDIC_LOT_CODE2_ID
              , aDIC_LOT_CODE3_ID             => aDIC_LOT_CODE3_ID
              , aLOT_FREE_NUM1                => aLOT_FREE_NUM1
              , aLOT_FREE_NUM2                => aLOT_FREE_NUM2
              , aLOT_REJECT_PLAN_QTY          => aLOT_REJECT_PLAN_QTY
              , aLOT_PLAN_VERSION             => aLOT_PLAN_VERSION
              , aLOT_PLAN_NUMBER              => aLOT_PLAN_NUMBER
              , aGCO_QUALITY_PRINCIPLE_ID     => aGCO_QUALITY_PRINCIPLE_ID
              , aPPS_OPERATION_PROCEDURE_ID   => aPPS_OPERATION_PROCEDURE_ID
              , aC_FAB_TYPE                   => aC_FAB_TYPE
              , aPTC_FIXED_COSTPRICE_ID       => nPTC_FIXED_COSTPRICE_ID
              , iLotRefCompl                  => iLotRefCompl
               );

    -- Si produit couplé, génération des détails lot
    if nvl(cCoupledGood, '0') = '1' then
      select max(GCO_COMPL_DATA_MANUFACTURE_ID)
        into aGCO_COMPL_DATA_MANUFACTURE_ID
        from GCO_COMPL_DATA_MANUFACTURE
       where GCO_GOOD_ID = vGCO_GOOD_ID
         and DIC_FAB_CONDITION_ID = aDIC_FAB_CONDITION_ID;

      if FAL_COUPLED_GOOD.ExistsCoupledForDataManuf(aGCO_COMPL_DATA_MANUFACTURE_ID) then
        FAL_COUPLED_GOOD.Generate_detail_lot(aCreatedFAL_LOT_ID, aGCO_COMPL_DATA_MANUFACTURE_ID, aLOT_ASKED_QTY);
      end if;
    end if;

    -- calcul de la quantité totale du lot (recalculée dans insert lot de toute façon mais utilisé plus loin)
    aLOT_TOTAL_QTY      := nvl(aLOT_ASKED_QTY, 0) + nvl(aLOT_REJECT_PLAN_QTY, 0);

    -- Génération des opérations
    if aFAL_SCHEDULE_PLAN_ID is not null then
      -- Contexte de la sous traitance
      if nvl(aC_FAB_TYPE, btManufacturing) = btSubcontract then
        ltGCO_COMPL_DATA_SUBCONTRACT  := GCO_I_LIB_COMPL_DATA.GetDefaultSubCComplData(vGCO_GOOD_ID, iPacSupplierPartnerId, iGcoGcoGoodId, aLOT_PLAN_BEGIN_DTE);
      end if;

      FAL_TASK_GENERATOR.Call_Task_Generator(iFAL_SCHEDULE_PLAN_ID   => aFAL_SCHEDULE_PLAN_ID
                                           , iFAL_LOT_ID             => aCreatedFAL_LOT_ID
                                           , iLOT_TOTAL_QTY          => aLOT_TOTAL_QTY
                                           , iC_SCHEDULE_PLANNING    => aC_SCHEDULE_PLANNING
                                           , iContexte               => aC_FAB_TYPE   -- = Contexte de création lancement (et non assemblage)
                                           , iSequence               => null   -- Séquence
                                           , iPacSupplierPartnerId   => iPacSupplierPartnerId
                                           , iGcoGcoGoodId           => iGcoGcoGoodId
                                           , iScsAmount              => iScsAmount
                                           , iScsQtyRefAmount        => iScsQtyRefAmount
                                           , iScsDivisorAmount       => iScsDivisorAmount
                                           , iScsWeigh               => iScsWeigh
                                           , iScsWeighMandatory      => iScsWeighMandatory
                                           , iScsPlanRate            => ltGCO_COMPL_DATA_SUBCONTRACT.CSU_SUBCONTRACTING_DELAY
                                           , iScsPlanProp            => (case
                                                                           when nvl(ltGCO_COMPL_DATA_SUBCONTRACT.CSU_FIX_DELAY, 0) = 0 then 1
                                                                           else 0
                                                                         end)
                                           , iScsQtyRefWork          => nvl(ltGCO_COMPL_DATA_SUBCONTRACT.CSU_LOT_QUANTITY, 1)
                                            );
    end if;

    -- Générations des composants
    aUserCode           := GetNewId;
    FAL_COMPONENT.GenerateComponents(aCreatedFAL_LOT_ID, null, aC_DISCHARGE_COM);
    -- Création de l'historique "Création du lot"
    CreateBatchHistory(aCreatedFAL_LOT_ID, aC_EVEN_TYPE);

    -- Planification : planification selon date de fin à la création d'un lot de sous-traitance sinon selon date de début
    if nvl(aC_FAB_TYPE, btManufacturing) = btSubcontract then
      FAL_PLANIF.PlanificationLotSubcontractP(iLotID          => aCreatedFAL_LOT_ID
                                            , iLotBeginDate   => aLOT_PLAN_BEGIN_DTE
                                            , iLotEndDate     => aLOT_PLAN_END_DTE
                                            , iSupplierId     => iPacSupplierPartnerId
                                             );
    else
      FAL_PLANIF.Planification_Lot(aCreatedFAL_LOT_ID
                                 , null   -- DatePlanification
                                 , PlanifOnBeginDate
                                 , FAL_PLANIF.ctAvecMAJLienCompoLot
                                 , FAL_PLANIF.ctSansMAJReseau
                                  );
    end if;

    -- Planification de base en fonction de la configuration FAL_INITIAL_PLANIFICATION
    if nvl(PCS.PC_CONFIG.GetConfig('FAL_INITIAL_PLANIFICATION'), '0') = '1' then
      DoBasisLotPlanification(aCreatedFAL_LOT_ID);
    end if;

    -- Mise à jour de l'ordre
    FAL_ORDER_FUNCTIONS.UpdateOrder(vFAL_ORDER_ID);
    -- Mise à jour du programme
    FAL_PROGRAM_FUNCTIONS.UpdateManufactureProgram(vFAL_JOB_PROGRAM_ID);
    -- Mise à jour réseau Produit Terminé
    FAL_NETWORK.MiseAJourReseaux(aCreatedFAL_LOT_ID, FAL_NETWORK.ncCreationLot, null);   -- param null = AStockPositionIDList
    -- Exécution d'une procédure indiv en fin de création
    lvProcName          := PCS.PC_CONFIG.GetConfig('FAL_PROC_ON_END_CREATE_BATCH');

    if lvProcName is not null then
      execute immediate 'begin ' || lvProcName || '(:FAL_LOT_ID); ' || 'end;'
                  using in aCreatedFAL_LOT_ID;
    end if;
  exception
    when others then
      raise;
  end;

  -- Idem précédemment avec retour d'un message d'erreur
  procedure CreateBatch(
    aFAL_ORDER_ID               in     fal_lot.fal_order_id%type
  , aDIC_FAB_CONDITION_ID       in     fal_lot.dic_fab_condition_id%type
  , aSTM_STOCK_ID               in     fal_lot.stm_stock_id%type
  , aSTM_LOCATION_ID            in     fal_lot.stm_location_id%type
  , aLOT_PLAN_BEGIN_DTE         in     fal_lot.lot_plan_begin_dte%type
  , aLOT_PLAN_END_DTE           in     fal_lot.lot_plan_end_dte%type
  , aLOT_ASKED_QTY              in     fal_lot.lot_asked_qty%type
  , aPPS_NOMENCLATURE_ID        in     fal_lot.pps_nomenclature_id%type
  , aFAL_SCHEDULE_PLAN_ID       in     fal_lot.fal_schedule_plan_id%type
  -- Paramètre avec valeur par défaut
  , aDOC_RECORD_ID              in     fal_lot.doc_record_id%type default null
  , aGCO_GOOD_ID                in     fal_lot.gco_good_id%type
  , aLOT_REJECT_PLAN_QTY        in     fal_lot.lot_reject_plan_qty%type default 0
  , aLOT_TOLERANCE              in     fal_lot.lot_tolerance%type default null
  , aLOT_PLAN_VERSION           in     fal_lot.lot_plan_version%type default null
  , aLOT_PLAN_NUMBER            in     fal_lot.lot_plan_number%type default null
  , aLOT_SHORT_DESCR            in     fal_lot.lot_short_descr%type default null
  , aLOT_LONG_DESCR             in     fal_lot.lot_long_descr%type default null
  , aLOT_FREE_DESCR             in     fal_lot.lot_free_descr%type default null
  , aSTM_STM_STOCK_ID           in     fal_lot.stm_stock_id%type default null
  , aSTM_STM_LOCATION_ID        in     fal_lot.stm_stm_location_id%type default null
  , aDIC_FAMILY_ID              in     fal_lot.dic_family_id%type default null
  , aC_PRIORITY                 in     fal_lot.c_priority%type default null
  , aGCO_QUALITY_PRINCIPLE_ID   in     fal_lot.gco_quality_principle_id%type default null
  , aPPS_OPERATION_PROCEDURE_ID in     fal_lot.pps_operation_procedure_id%type default null
  , aDIC_LOT_CODE2_ID           in     fal_lot.dic_lot_code2_id%type default null
  , aDIC_LOT_CODE3_ID           in     fal_lot.dic_lot_code3_id%type default null
  , aLOT_FREE_NUM1              in     fal_lot.lot_free_num1%type default null
  , aLOT_FREE_NUM2              in     fal_lot.lot_free_num2%type default null
  , aC_EVEN_TYPE                in     fal_histo_lot.c_even_type%type default etCreated
  , PlanifOnBeginDate           in     integer default 1
  , aC_FAB_TYPE                 in     fal_lot.c_fab_type%type default 0
  , aC_DISCHARGE_COM            in     GCO_COMPL_DATA_SUBCONTRACT.C_DISCHARGE_COM%type default null
  , aFAL_JOB_PROGRAM_ID         in     fal_lot.fal_job_program_id%type default null
  , aJOP_SHORT_DESCR            in     fal_job_program.jop_short_descr%type default null
  , aORD_OSHORT_DESCR           in     fal_order.ord_oshort_descr%type default null
  , aPTC_FIXED_COSTPRICE_ID     in     fal_lot.PTC_FIXED_COSTPRICE_ID%type default null
  , iPacSupplierPartnerId       in     number default null
  , iGcoGcoGoodId               in     number default null
  , iScsAmount                  in     number default 0
  , iScsQtyRefAmount            in     integer default 0
  , iScsDivisorAmount           in     integer default 0
  , iScsWeigh                   in     integer default 0
  , iScsWeighMandatory          in     integer default 0
  , iLotRefCompl                in     fal_lot.lot_refcompl%type default null
  , aCreatedFAL_LOT_ID          in out number
  , aErrorMsg                   in out varchar2
  )
  is
  begin
    CreateBatch(aFAL_ORDER_ID                 => aFAL_ORDER_ID
              , aDIC_FAB_CONDITION_ID         => aDIC_FAB_CONDITION_ID
              , aSTM_STOCK_ID                 => aSTM_STOCK_ID
              , aSTM_LOCATION_ID              => aSTM_LOCATION_ID
              , aLOT_PLAN_BEGIN_DTE           => aLOT_PLAN_BEGIN_DTE
              , aLOT_PLAN_END_DTE             => aLOT_PLAN_END_DTE
              , aLOT_ASKED_QTY                => aLOT_ASKED_QTY
              , aPPS_NOMENCLATURE_ID          => aPPS_NOMENCLATURE_ID
              , aFAL_SCHEDULE_PLAN_ID         => aFAL_SCHEDULE_PLAN_ID
              , aDOC_RECORD_ID                => aDOC_RECORD_ID
              , aGCO_GOOD_ID                  => aGCO_GOOD_ID
              , aLOT_REJECT_PLAN_QTY          => aLOT_REJECT_PLAN_QTY
              , aLOT_TOLERANCE                => aLOT_TOLERANCE
              , aLOT_PLAN_VERSION             => aLOT_PLAN_VERSION
              , aLOT_PLAN_NUMBER              => aLOT_PLAN_NUMBER
              , aLOT_SHORT_DESCR              => aLOT_SHORT_DESCR
              , aLOT_LONG_DESCR               => aLOT_LONG_DESCR
              , aLOT_FREE_DESCR               => aLOT_FREE_DESCR
              , aSTM_STM_STOCK_ID             => aSTM_STM_STOCK_ID
              , aSTM_STM_LOCATION_ID          => aSTM_STM_LOCATION_ID
              , aDIC_FAMILY_ID                => aDIC_FAMILY_ID
              , aC_PRIORITY                   => aC_PRIORITY
              , aGCO_QUALITY_PRINCIPLE_ID     => aGCO_QUALITY_PRINCIPLE_ID
              , aPPS_OPERATION_PROCEDURE_ID   => aPPS_OPERATION_PROCEDURE_ID
              , aDIC_LOT_CODE2_ID             => aDIC_LOT_CODE2_ID
              , aDIC_LOT_CODE3_ID             => aDIC_LOT_CODE3_ID
              , aLOT_FREE_NUM1                => aLOT_FREE_NUM1
              , aLOT_FREE_NUM2                => aLOT_FREE_NUM2
              , aC_EVEN_TYPE                  => aC_EVEN_TYPE
              , PlanifOnBeginDate             => PlanifOnBeginDate
              , aC_FAB_TYPE                   => aC_FAB_TYPE
              , aC_DISCHARGE_COM              => aC_DISCHARGE_COM
              , aFAL_JOB_PROGRAM_ID           => aFAL_JOB_PROGRAM_ID
              , aJOP_SHORT_DESCR              => aJOP_SHORT_DESCR
              , aORD_OSHORT_DESCR             => aORD_OSHORT_DESCR
              , aPTC_FIXED_COSTPRICE_ID       => aPTC_FIXED_COSTPRICE_ID
              , aCreatedFAL_LOT_ID            => aCreatedFAL_LOT_ID
              , iPacSupplierPartnerId         => iPacSupplierPartnerId
              , iGcoGcoGoodId                 => iGcoGcoGoodId
              , iScsAmount                    => iScsAmount
              , iScsQtyRefAmount              => iScsQtyRefAmount
              , iScsDivisorAmount             => iScsDivisorAmount
              , iScsWeigh                     => iScsWeigh
              , iScsWeighMandatory            => iScsWeighMandatory
              , iLotRefCompl                  => iLotRefCompl
               );
  exception
    when excMissingFixedCostprice then
      aErrorMsg  := excMissingFixedCostpriceMsg;
    when others then
      begin
        aErrorMsg  := excGenericErrorMsg || sqlerrm;
      end;
  end;

  /**
  * Procedure DeleteBatch
  * Description
  *   Suppression d'un lot de fabrication
  * @author ECA
  * @public
  * @param     aFAL_LOT_ID   Id du lot
  * @param     aDeleteOrder  0 = Pas de suppression de l'ordre
  *                          1 = Suppression si plus aucun lots.
  */
  procedure DeleteBatch(aFAL_LOT_ID FAL_LOT.FAL_LOT_ID%type, aDeleteOrderMode integer default 0)
  is
    aUsedInTracability  integer;
    aC_LOT_STATUS       FAL_LOT.C_LOT_STATUS%type;
    vCFabType           FAL_LOT.C_FAB_TYPE%type;
    aFAL_ORDER_ID       FAL_ORDER.FAL_ORDER_ID%type;
    aFAL_JOB_PROGRAM_ID FAL_JOB_PROGRAM.FAL_JOB_PROGRAM_ID%type;
    nReceptQty          number;
    nMvtComponent       number;
    nProgressTrack      number;
    ResDelOrder         boolean;
    lcPositionDetailId  DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
  begin
    -- Test de présence du lot en tracabilité, et de son status
    select C_LOT_STATUS
         , C_FAB_TYPE
         , FAL_ORDER_ID
         , FAL_JOB_PROGRAM_ID
         , nvl(LOT_RELEASED_QTY, 0) + nvl(LOT_REJECT_RELEASED_QTY, 0) + nvl(LOT_DISMOUNTED_QTY, 0) RECEPT_QTY
         , (select count(*)
              from FAL_TRACABILITY
             where FAL_LOT_ID = LOT.FAL_LOT_ID) TRACABILITY
         , (select count(*)
              from FAL_FACTORY_IN
             where FAL_LOT_ID = LOT.FAL_LOT_ID) FACTORY_IN
         , (select count(*)
              from FAL_LOT_PROGRESS
             where FAL_LOT_ID = LOT.FAL_LOT_ID) LOT_PROGRESS
      into aC_LOT_STATUS
         , vCFabType
         , aFAL_ORDER_ID
         , aFAL_JOB_PROGRAM_ID
         , nReceptQty
         , aUsedInTracability
         , nMvtComponent
         , nProgressTrack
      from FAL_LOT LOT
     where FAL_LOT_ID = aFAL_LOT_ID;

    -- Si lot non plannifié
    if     (aC_LOT_STATUS <> bsPlanned)
       and (vCFabType <> btSubcontract) then
      raise_application_error(-20013, 'PCS - ' || excNotPlannedBatchMsg);
    end if;

    -- Si le lot possède de la tracabilité
    if aUsedInTracability > 0 then
      raise_application_error(-20012, 'PCS - ' || excUsedInTracablityMsg);
    end if;

    -- Si le lot a déjà été réceptionné ou démonté
    if nReceptQty > 0 then
      raise_application_error(-20017, 'PCS - ' || excReceptionExistsMsg);
    end if;

    -- Si le lot a déjà eu des mouvements de composants
    if nMvtComponent > 0 then
      raise_application_error(-20018, 'PCS - ' || excMvtComponentExistsMsg);
    end if;

    -- Si le lot a déjà eu du suivi de fabrication
    if nProgressTrack > 0 then
      raise_application_error(-20019, 'PCS - ' || excProgressTrackExistsMsg);
    end if;

    -- Recherche les opérations liées à un détail de position
    select max(PDE.DOC_POSITION_DETAIL_ID)
      into lcPositionDetailId
      from DOC_POSITION_DETAIL PDE
     where PDE.FAL_SCHEDULE_STEP_ID in(select FAL_SCHEDULE_STEP_ID
                                         from FAL_TASK_LINK
                                        where FAL_LOT_ID = aFAL_LOT_ID);

    -- Si des porsitions existent encore
    if lcPositionDetailId > 0 then
      raise_application_error(-20020, 'PCS - ' || excBoundDocumentMsg);
    end if;

    -- Suppression des détails lot
    delete from FAL_LOT_DETAIL
          where FAL_LOT_ID = aFAL_LOT_ID;

    -- Mise à jour des réseaux
    FAL_NETWORK.MiseAJourReseaux(aFAL_LOT_ID, FAL_NETWORK.ncSuppressionLot, null);

    -- Suppression du lot
    delete from FAL_LOT
          where FAL_LOT_ID = aFAL_LOT_ID;

    -- Mise a jour ordre ou suppression si demandée
    if aDeleteOrderMode = 0 then
      FAL_ORDER_FUNCTIONS.UpdateOrder(aFAL_ORDER_ID);
    else
      ResDelOrder  := FAL_ORDER_FUNCTIONS.DeleteOrder(aFAL_ORDER_ID);
    end if;

    -- Mise à jour programme
    FAL_PROGRAM_FUNCTIONS.UpdateManufactureProgram(aFAL_JOB_PROGRAM_ID);
  exception
    when no_data_found then
      raise_application_error(-20014, 'PCS - ' || excUnknownBatchMsg);
    when others then
      raise;
  end;

  /**
  * Procedure DeleteBatch
  * Description
  *   idem précédemment avec un code erreur en place d'exception
  */
  procedure DeleteBatch(aFAL_LOT_ID in FAL_LOT.FAL_LOT_ID%type, aErrorCode in out varchar2, aDeleteOrderMode in integer default 0)
  is
  begin
    DeleteBatch(aFAL_LOT_ID, aDeleteOrderMode);
  exception
    when excBoundDocument then
      aErrorCode  := 'excBoundDocument';
    when excNotPlannedBatch then
      aErrorCode  := 'excNotPlannedBatch';
    when excUsedInTracablity then
      aErrorCode  := 'excUsedInTracablity';
    when excUnknownBatch then
      aErrorCode  := 'excUnknownBatch';
    when others then
      raise;
  end;

  /**
  * Procedure UpdateBatchQtyForReceipt
  * Description
  *   Mise à jour de la quantité max réceptionnable d'un lot de fabrication
  * @author ECA
  * @lastUpdate
  * @public
  * @param    aFAL_LOT_ID   Lot
  * @param    aLOT_INPROD_  Quantité en fabrication
  */
  procedure UpdateBatchQtyForReceipt(aFAL_LOT_ID FAL_LOT.FAL_LOT_ID%type, aLOT_INPROD_QTY FAL_LOT.LOT_INPROD_QTY%type)
  is
    aLOT_MAX_RELEASABLE_QTY number;
  begin
    -- On passe par une variable afin d'éviter, dans certain cas un prbl. de Table mutating
    aLOT_MAX_RELEASABLE_QTY  := FAL_COMPONENT_TOOLS.GetMinQteMaxReceptionnable_Lot(aFAL_LOT_ID, aLOT_INPROD_QTY);

    update FAL_LOT
       set LOT_MAX_RELEASABLE_QTY = aLOT_MAX_RELEASABLE_QTY
     where FAL_LOT_ID = aFAl_LOT_ID;
  end;

  /**
  * Procedure UpdateBatch
  * Description : Mise à jour du lot de fabrication
  *
  * @author CLE
  * @lastUpdate
  * @public
  * @param    aFalLotId     Id du lot
  * @param    aContext      Context de mise à jour (lancement, réception, ...)
  * @param    aQty          Quantité en fabrication, de lancement ou de réception
  * @param    ReceptionType Type de réception (rebut, produit terminé)
  * @param    aDate         Date de la mise à jour (date de réception, utilisée en solde du lot)
  */
  procedure UpdateBatch(
    aFalLotId     FAL_LOT.FAL_LOT_ID%type
  , aContext      integer
  , aQty          FAL_LOT.LOT_INPROD_QTY%type default null
  , ReceptionType integer default null
  , aDate         FAL_LOT.LOT_FULL_REL_DTE%type default null
  )
  is
    cursor cur_FalLot
    is
      select nvl(LOT_RELEASED_QTY, 0) LOT_RELEASED_QTY
           , nvl(LOT_TOTAL_QTY, 0) LOT_TOTAL_QTY
           , nvl(LOT_PT_REJECT_QTY, 0) LOT_PT_REJECT_QTY
           , nvl(LOT_CPT_REJECT_QTY, 0) LOT_CPT_REJECT_QTY
           , nvl(LOT_REJECT_RELEASED_QTY, 0) LOT_REJECT_RELEASED_QTY
           , nvl(LOT_DISMOUNTED_QTY, 0) LOT_DISMOUNTED_QTY
        from FAL_LOT
       where FAL_LOT_ID = aFalLotId;

    curFalLot                cur_FalLot%rowtype;
    nLOT_RELEASED_QTY        FAL_LOT.LOT_RELEASED_QTY%type;
    nLOT_INPROD_QTY          FAL_LOT.LOT_INPROD_QTY%type;
    nLOT_PT_REJECT_QTY       FAL_LOT.LOT_PT_REJECT_QTY%type;
    nLOT_REJECT_RELEASED_QTY FAL_LOT.LOT_REJECT_RELEASED_QTY%type;
    nLOT_CPT_REJECT_QTY      FAL_LOT.LOT_CPT_REJECT_QTY%type;
    nLOT_DISMOUNTED_QTY      FAL_LOT.LOT_DISMOUNTED_QTY%type;
    nLotMaxReleasableQty     number;
  begin
    if aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchLaunch then
      -- Mise à jour du lot à la fin du lancement
      update FAL_LOT
         set LOT_OPEN__DTE = sysdate
           , LOT_TO_BE_RELEASED = 1
           , C_LOT_STATUS = bsLaunched
           , LOT_RELEASE_QTY = LOT_TOTAL_QTY
           , LOT_MAX_RELEASABLE_QTY = FAL_COMPONENT_TOOLS.GetMinQteMaxReceptionnable_Lot(aFalLotId, LOT_INPROD_QTY)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_LOT_ID = aFalLotId;
    -- Mise à jour à la réception
    elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtManufacturingReceipt then
      open cur_FalLot;

      fetch cur_FalLot
       into curFalLot;

      close cur_FalLot;

      -- Réception produit terminé
      if ReceptionType = rtFinishedProduct then
        nLOT_RELEASED_QTY     := curFalLot.LOT_RELEASED_QTY + aQty;
        nLOT_INPROD_QTY       :=
          curFalLot.LOT_TOTAL_QTY -
          curFalLot.LOT_PT_REJECT_QTY -
          curFalLot.LOT_CPT_REJECT_QTY -
          nLOT_RELEASED_QTY -
          curFalLot.LOT_REJECT_RELEASED_QTY -
          curFalLot.LOT_DISMOUNTED_QTY;
        nLotMaxReleasableQty  := FAL_COMPONENT_TOOLS.GetMinQteMaxReceptionnable_Lot(aFalLotId, nLOT_INPROD_QTY);

        update FAL_LOT
           set LOT_RELEASED_QTY = nLOT_RELEASED_QTY
             , LOT_INPROD_QTY = nLOT_INPROD_QTY
             , LOT_MAX_RELEASABLE_QTY = nLotMaxReleasableQty
             , LOT_ALLOCATED_QTY = greatest(nvl(LOT_ALLOCATED_QTY, 0) - aQty, 0)
             , LOT_FREE_QTY =
                            case
                              when(nvl(LOT_ALLOCATED_QTY, 0) - aQty >= 0) then LOT_FREE_QTY
                              else greatest(nvl(LOT_FREE_QTY, 0) +(nvl(LOT_ALLOCATED_QTY, 0) - aQty), 0)
                            end
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             , A_DATEMOD = sysdate
         where FAL_LOT_ID = aFalLotId;
      elsif ReceptionType = rtReject then
        -- Réception rebut
        nLOT_PT_REJECT_QTY        := greatest(curFalLot.LOT_PT_REJECT_QTY - aQty, 0);
        nLOT_REJECT_RELEASED_QTY  := curFalLot.LOT_REJECT_RELEASED_QTY + aQty;
        nLOT_INPROD_QTY           :=
          curFalLot.LOT_TOTAL_QTY -
          nLOT_PT_REJECT_QTY -
          curFalLot.LOT_CPT_REJECT_QTY -
          curFalLot.LOT_RELEASED_QTY -
          nLOT_REJECT_RELEASED_QTY -
          curFalLot.LOT_DISMOUNTED_QTY;
        nLotMaxReleasableQty      := FAL_COMPONENT_TOOLS.GetMinQteMaxReceptionnable_Lot(aFalLotId, nLOT_INPROD_QTY);

        update FAL_LOT
           set LOT_PT_REJECT_QTY = nLOT_PT_REJECT_QTY
             , LOT_REJECT_RELEASED_QTY = nLOT_REJECT_RELEASED_QTY
             , LOT_INPROD_QTY = nLOT_INPROD_QTY
             , LOT_MAX_RELEASABLE_QTY = nLotMaxReleasableQty
             , LOT_ALLOCATED_QTY = greatest(nvl(LOT_ALLOCATED_QTY, 0) - aQty, 0)
             , LOT_FREE_QTY =
                            case
                              when(nvl(LOT_ALLOCATED_QTY, 0) - aQty >= 0) then LOT_FREE_QTY
                              else greatest(nvl(LOT_FREE_QTY, 0) +(nvl(LOT_ALLOCATED_QTY, 0) - aQty), 0)
                            end
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             , A_DATEMOD = sysdate
         where FAL_LOT_ID = aFalLotId;
      else
        -- Démontage
        nLOT_CPT_REJECT_QTY   := greatest(curFalLot.LOT_CPT_REJECT_QTY - aQty, 0);
        nLOT_DISMOUNTED_QTY   := curFalLot.LOT_DISMOUNTED_QTY + aQty;
        nLOT_INPROD_QTY       :=
          curFalLot.LOT_TOTAL_QTY -
          curFalLot.LOT_PT_REJECT_QTY -
          nLOT_CPT_REJECT_QTY -
          curFalLot.LOT_RELEASED_QTY -
          curFalLot.LOT_REJECT_RELEASED_QTY -
          nLOT_DISMOUNTED_QTY;
        nLotMaxReleasableQty  := FAL_COMPONENT_TOOLS.GetMinQteMaxReceptionnable_Lot(aFalLotId, nLOT_INPROD_QTY);

        update FAL_LOT
           set LOT_CPT_REJECT_QTY = nLOT_CPT_REJECT_QTY
             , LOT_DISMOUNTED_QTY = nLOT_DISMOUNTED_QTY
             , LOT_INPROD_QTY = nLOT_INPROD_QTY
             , LOT_MAX_RELEASABLE_QTY = nLotMaxReleasableQty
             , LOT_FREE_QTY =
                 case
                   when(aQty > nvl(LOT_PT_REJECT_QTY, 0) )
                   and (nvl(LOT_PT_REJECT_QTY, 0) + nLOT_CPT_REJECT_QTY + nvl(LOT_REJECT_RELEASED_QTY, 0) + nLOT_DISMOUNTED_QTY > nvl(LOT_REJECT_PLAN_QTY, 0) ) then greatest
                                                                                                                                                                      (nLOT_INPROD_QTY -
                                                                                                                                                                       nvl
                                                                                                                                                                         (LOT_ALLOCATED_QTY
                                                                                                                                                                        , 0
                                                                                                                                                                         )
                                                                                                                                                                     , 0
                                                                                                                                                                      )
                   else LOT_FREE_QTY
                 end
             , LOT_ALLOCATED_QTY =
                 case
                   when(aQty > nvl(LOT_PT_REJECT_QTY, 0) )
                   and (nvl(LOT_PT_REJECT_QTY, 0) + nLOT_CPT_REJECT_QTY + nvl(LOT_REJECT_RELEASED_QTY, 0) + nLOT_DISMOUNTED_QTY > nvl(LOT_REJECT_PLAN_QTY, 0) )
                   and (nLOT_INPROD_QTY - nvl(LOT_ALLOCATED_QTY, 0) < 0) then greatest(nLOT_INPROD_QTY, 0)
                   else LOT_ALLOCATED_QTY
                 end
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             , A_DATEMOD = sysdate
         where FAL_LOT_ID = aFalLotId;
      end if;
    elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchBalance then
      update FAL_LOT
         set C_LOT_STATUS = bsBalanced
           , LOT_FULL_REL_DTE = aDate
           , LOT_INPROD_QTY = 0
           , LOT_MAX_RELEASABLE_QTY = 0
           , LOT_ALLOCATED_QTY = 0
           , LOT_FREE_QTY = 0
           , LOT_REAL_LEAD_TIME =
                               FAL_SCHEDULE_FUNCTIONS.getduration(null, null, null, null, null, FAL_SCHEDULE_FUNCTIONS.GetDefaultCalendar, LOT_OPEN__DTE, aDate)
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , A_DATEMOD = sysdate
       where FAL_LOT_ID = aFalLotId;
    end if;
  end;

  /**
  * procedure UpdateDetailLot
  * Description
  *   Mise à jour des quantités des détails lot à la réception
  * @author CLE
  * @param   aFalLotId       Id du lot
  * @param   ReceptionType   Type de réception (produit terminé, rebut)
  * @param   BatchBalance    Mise à jour pour le solde du lot ou non
  */
  procedure UpdateDetailLot(aFalLotId fal_lot.fal_lot_id%type, ReceptionType integer default null, BatchBalance integer default 0)
  is
  begin
    if BatchBalance = 1 then
      update FAL_LOT_DETAIL
         set FAD_CANCEL_QTY = FAD_BALANCE_QTY + FAD_MORPHO_REJECT_QTY
           , FAD_BALANCE_QTY = 0
           , FAD_MORPHO_REJECT_QTY = 0
       where FAL_LOT_ID = aFalLotId
         and nvl(FAD_BALANCE_QTY, 0) > 0;
    else
      update FAL_LOT_DETAIL
         set FAD_RECEPT_SELECT = 0
           , FAD_RECEPT_QTY = case ReceptionType
                               when rtDismantling then nvl(FAD_RECEPT_QTY, 0)
                               else nvl(FAD_RECEPT_QTY, 0) + nvl(FAD_RECEPT_INPROGRESS_QTY, 0)
                             end
           , FAD_CANCEL_QTY = case ReceptionType
                               when rtDismantling then nvl(FAD_CANCEL_QTY, 0) + nvl(FAD_RECEPT_INPROGRESS_QTY, 0)
                               else nvl(FAD_CANCEL_QTY, 0)
                             end
           , FAD_MORPHO_REJECT_QTY =
               case ReceptionType
                 when rtFinishedProduct then nvl(FAD_MORPHO_REJECT_QTY, 0)
                 else greatest(nvl(FAD_MORPHO_REJECT_QTY, 0) - nvl(FAD_RECEPT_INPROGRESS_QTY, 0), 0)
               end
           , FAD_RECEPT_INPROGRESS_QTY = 0
           , FAD_BALANCE_QTY =
               nvl(FAD_QTY, 0) -
               (nvl(FAD_RECEPT_QTY, 0) + nvl(FAD_RECEPT_INPROGRESS_QTY, 0) ) -
               nvl(FAD_CANCEL_QTY, 0) -
               (case ReceptionType
                  when rtFinishedProduct then nvl(FAD_MORPHO_REJECT_QTY, 0)
                  else greatest(nvl(FAD_MORPHO_REJECT_QTY, 0) - nvl(FAD_RECEPT_INPROGRESS_QTY, 0), 0)
                end
               )
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_LOT_ID = aFalLotId
         and FAD_RECEPT_SELECT = 1;
    end if;
  end UpdateDetailLot;

  /**
  * procedure pUpdatePartElementNumber
  * Description
  *   Mise à jour des numéros de pièce à la réception pour les PT qui ne font pas de mouvements de stock
  *   ex : Qté restante au solde, démontage
  * @author CLE
  * @LastUpdate AGE 17.09.2013
  * @private
  * @param iLotId         : Id du lot
  * @param iGoodId        : Id du produit terminé
  * @param iBatchBalance  : Mise à jour pour le solde du lot ou non
  * @param iReceptionType : Type de réception
  */
  procedure pUpdatePartElementNumber(
    iLotId         in FAL_LOT.FAL_LOT_ID%type
  , iGoodId        in FAL_LOT.GCO_GOOD_ID%type
  , iBatchBalance  in integer
  , iReceptionType in integer
  )
  is
    lNewEleNumStatus STM_ELEMENT_NUMBER.C_ELE_NUM_STATUS%type;
  begin
    if iBatchBalance = 1 then
      lNewEleNumStatus  := esActive;
    else
      lNewEleNumStatus  := esReturned;
    end if;

    for tplElementNumber in (select STM_ELEMENT_NUMBER_ID
                               from STM_ELEMENT_NUMBER
                              where GCO_GOOD_ID = iGoodId
                                and C_ELEMENT_TYPE = elmtPart
                                and SEM_VAlUE in(
                                      select FAD_PIECE
                                        from FAL_LOT_DETAIL
                                       where FAL_LOT_ID = iLotId
                                         and (    (    iBatchBalance = 0
                                                   and FAD_RECEPT_SELECT = 1
                                                   and iReceptionType = rtDismantling)
                                              or (    iBatchBalance = 1
                                                  and nvl(FAD_BALANCE_QTY, 0) > 0)
                                             )
                                         and FAD_PIECE is not null) ) loop
      STM_PRC_ELEMENT_NUMBER.UpdateElementNumber(iElementNumberID => tplElementNumber.STM_ELEMENT_NUMBER_ID, iStatus => lNewEleNumStatus);
    end loop;
  end pUpdatePartElementNumber;

/**
  * procedure ManageBatchUpdates
  * Description
  *   Mise à jour du lot. Inclus :
  *            - Mise à jour lot
  *            - Mise à jour sorties atelier
  *            - Mise à jour détail lot
  *            - Mise à jour N° pièce
  *            - Mise à jour de l'ordre
  *            - Mise à jour du programme
  *            - Mise à jour réseaux
  * @author CLE
  * @LastUpdate AGE 17.09.2013
  * @param   aFalLotId       Id du lot
  * @param   aFalOrderId     Id de l'ordre
  * @param   aCFabType       Type de lot
  * @param   ReceptionType   Type de réception (PT, rebut, démontage)
  * @param   aGcoGoodId      Id du bien
  * @param   aQty            Qté réception
  * @param   aContext        Contexte (réception, solde)
  * @param   aDate           Date de réception
  * @param   aReceptedPositionID Liste des positions de stock. (pour les attributions complètes en réception PT)
  */
  procedure ManageBatchUpdates(
    aFalLotId           FAL_LOT.FAL_LOT_ID%type
  , aFalOrderId         FAL_LOT.FAL_ORDER_ID%type
  , aCFabType           FAL_LOT.C_FAB_TYPE%type
  , ReceptionType       integer
  , aGcoGoodId          FAL_LOT.GCO_GOOD_ID%type
  , aQty                FAL_LOT.LOT_INPROD_QTY%type default 0
  , aContext            integer
  , aDate               FAL_LOT.LOT_PLAN_END_DTE%type default sysdate
  , aReceptedPositionID varchar2 default null
  )
  is
    BatchBalance      integer;
    TypeUpdateNetwork integer;
  begin
    BatchBalance  := 0;

    if aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchBalance then
      BatchBalance       := 1;
      TypeUpdateNetwork  := FAL_NETWORK.ncSolderLot;
    elsif ReceptionType = rtFinishedProduct then
      TypeUpdateNetwork  := FAL_NETWORK.ncReceptionPT;
    elsif ReceptionType = rtReject then
      TypeUpdateNetwork  := FAL_NETWORK.ncReceptionRebut;
    elsif ReceptionType = rtDismantling then
      TypeUpdateNetwork  := FAL_NETWORK.ncDemontagePT;
    end if;

    if aCFabType <> btAfterSales then
      -- Mise à jour N° de pièce...
      pUpdatePartElementNumber(iLotId => aFalLotId, iGoodId => aGcoGoodId, iBatchBalance => BatchBalance, iReceptionType => ReceptionType);
      -- Mise à jour Détail Lot ...
      UpdateDetailLot(aFalLotId => aFalLotId, ReceptionType => ReceptionType, BatchBalance => BatchBalance);
    end if;

    -- Mise à jour du lot
    if ReceptionType <> rtBatchAssembly then
      UpdateBatch(aFalLotId => aFalLotId, aContext => aContext, aQty => aQty, ReceptionType => ReceptionType, aDate => aDate);
    end if;

    if ReceptionType <> rtDismantling then
      -- mise à jour des sorties atelier
      update FAL_FACTORY_OUT
         set OUT_POSTCALCULATED = 1
       where FAL_LOT_ID = aFalLotId;

      -- mise à jour des affectables
      update FAL_AFFECT
         set FAF_IS_POSTCALCULATED = 1
       where FAL_LOT_ID = aFalLotId;
    end if;

    -- Mise à jour de l'ordre
    FAL_ORDER_FUNCTIONS.UpdateOrder(aFAL_ORDER_ID => aFalOrderId);
    -- Mise à jour du programme
    FAL_PROGRAM_FUNCTIONS.UpdateManufactureProgram(aFalOrderId => aFalOrderId);

    -- Mise à jour Réseaux
    if ReceptionType <> rtBatchAssembly then
      FAL_NETWORK.MiseAJourReseaux(aFalLotId, TypeUpdateNetwork, aReceptedPositionID);
    end if;
  end;

  /**
  * Procedure ReserveBatch
  * Description
  *   Réservation d'un lot. aResult = rtErrBatchBusy si la réservation n'a pas pu avoir lieu.
  * @author CLE
  * @param     aFalLotId    Id du lot à réserver
  * @param     aSessionId   Session Oracle
  * @param     aResult      paramètre de retour. Retourne rtErrBatchBusy s'il le lot n'est pas disponible
  */
  procedure ReserveBatch(aFalLotId fal_lot.fal_lot_id%type, aSessionId fal_lot_mat_link_tmp.lom_session%type, aResult in out integer)
  is
    aErrorMsg varchar2(255);
  begin
    FAL_BATCH_RESERVATION.BatchReservation(aFAL_LOT_ID => aFalLotId, aLT1_ORACLE_SESSION => aSessionId, aErrorMsg => aErrorMsg);
    aResult  := rtOkBatchReserved;

    if trim(aErrorMsg) <> '' then
      aResult  := rtErrBatchBusy;   -- ERROR : Le lot n'est pas disponible
    end if;
  end;

  /**
  * procedure CheckStockAndLocation
  * Description
  *   Test des emplacements et stocks de destination du produit terminé et des rebuts
  *   (doivent être non nulls si quantité > 0) en réception
  * @author CLE
  * @param   aFinishedProductQty   Quantité produit terminé à réceptionner
  * @param   aRejectQty            Quantité rebut à réceptionner
  * @param   aStockId              Stock de destination PT
  * @param   aLocationId           Emplacement de destination PT
  * @param   aRejectStockId        Stock du rebut
  * @param   aRejectLocationId     Emplacement du rebut
  * @param   aResult               valeur de retour
  */
  procedure CheckStockAndLocation(
    aFinishedProductQty        fal_lot.lot_inprod_qty%type
  , aRejectQty                 fal_lot.lot_inprod_qty%type
  , aStockManagement           gco_product.pdt_stock_management%type
  , aStockId                   fal_lot.stm_stock_id%type
  , aLocationId                fal_lot.stm_location_id%type
  , aRejectStockId             fal_lot.stm_stock_id%type
  , aRejectLocationId          fal_lot.stm_location_id%type
  , aResult             in out integer
  )
  is
  begin
    if     (aStockManagement <> 0)
       and (    (     (nvl(aFinishedProductQty, 0) > 0)
                 and (    (nvl(aStockId, 0) = 0)
                      or (nvl(aLocationId, 0) = 0) ) )
            or (     (nvl(aRejectQty, 0) > 0)
                and (    (nvl(aRejectStockId, 0) = 0)
                     or (nvl(aRejectLocationId, 0) = 0) ) )
           ) then
      aResult  := rtErrStock;   -- ERROR : Veuillez préciser le stock et l'emplacement de destination
    end if;

    if aResult > 0 then
      aResult  := rtOkStock;
    end if;
  end;

  /**
   * procedure CheckDate
   * Description
   *   Test de la date de réception (doit être non nulle)
   * @author CLE
   * @param   aDate     Date de réception
   * @param   aResult   valeur de retour
   */
  procedure CheckDate(aDate fal_lot.lot_plan_end_dte%type, aResult in out integer)
  is
  begin
    if aDate is null then
      aResult  := -rtErrDate;   -- ERROR : Veuillez préciser la date de réception
    end if;

    if aResult > 0 then
      aResult  := rtOkDate;
    end if;
  end;

  /**
  * procedure CheckPartCharacteristic
  * Description
  *   Test de la caractérisation pièce. Si le produit terminé et au moins un de ses composants est caractérisé pièce
  *   (ou d'une caractérisation définie par la configuration FAL_PAIRING_CHARACT), ce type de composant doit être en
  *   quantité suffisante en atelier lors de la réception.
  * @created CLE
  * @lastUpdate age 09.05.2012
  * @param iCFabType      : Type de lot de fabrication
  * @param iLotID         : Id du lot
  * @param iGoodId        : Id du produit terminé
  * @param iQty           : Qté en réception
  * @param iReceptionType : Type de réception (PT, rebut, démontage)
  * @param ioResult       : Valeur de retour
  */
  procedure CheckPartCharacteristic(
    iCFabType      in     FAL_LOT.C_FAB_TYPE%type
  , iLotID         in     FAL_LOT.FAL_LOT_ID%type
  , iGoodId        in     FAL_LOT.GCO_GOOD_ID%type
  , iQty           in     FAL_LOT.LOT_INPROD_QTY%type
  , iReceptionType in     integer
  , ioResult       in out integer
  )
  is
    aChaStockManagement gco_characterization.cha_stock_management%type;
    cntComponents       number;
  begin
    -- Les Cpt des OF type STT se trouvent dans le stock STT. Ce contrôle ne doit donc pas être effectué.
    if (iCFabType = btSubcontract) then
      if iReceptionType = rtReject then
        ioResult  := rtOkCompoWithTraceabReject;
      else
        ioResult  := rtOkCompoWithTraceabPT;
      end if;
    else
      select max(CHA_STOCK_MANAGEMENT)
        into aChaStockManagement
        from GCO_CHARACTERIZATION
       where GCO_GOOD_ID = iGoodId
         and C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypePiece;

      if nvl(aChaStockManagement, 0) = 1 then
        select count(*)
          into cntComponents
          from FAL_LOT_MATERIAL_LINK FLML
         where FAL_LOT_ID = iLotID
           and C_TYPE_COM = cptActive
           and C_KIND_COM = ckComponent
           and LOM_STOCK_MANAGEMENT = 1
           and iQty > LOM_MAX_RECEIPT_QTY
           and (select nvl(max(CHA_STOCK_MANAGEMENT), 0)
                  from GCO_CHARACTERIZATION
                 where GCO_GOOD_ID = FLML.GCO_GOOD_ID
                   and instr(cPairingCaract, C_CHARACT_TYPE) > 0) = 1
           and iQty >
                 ( (LOM_CONSUMPTION_QTY - LOM_REJECTED_QTY - LOM_BACK_QTY - LOM_CPT_RECOVER_QTY - LOM_CPT_REJECT_QTY - LOM_EXIT_RECEIPT) /
                  (decode(nvl(LOM_UTIL_COEF, 0), 0, 1, LOM_UTIL_COEF) * LOM_REF_QTY
                  )
                 );

        if cntComponents > 0 then
          -- ERROR : Le lot contient au moins un composant impliquant un suivi de tracabilité
          --         en quantité insuffisante dans le stock Atelier pour la quantité réceptionnée.
          ioResult  := rtErrCompoWithTraceability;
        end if;
      end if;

      if ioResult > 0 then
        if iReceptionType = rtReject then
          ioResult  := rtOkCompoWithTraceabReject;
        else
          ioResult  := rtOkCompoWithTraceabPT;
        end if;
      end if;
    end if;
  end CheckPartCharacteristic;

  /**
  * procedure CheckTraceability
  * Description
  *    Test si un des composants est en traçabilité totale en quantité insufisante dans le stock lors de la réception
  * @created CLE
  * @lastUpdate age 09.05.2012
  * @param iCFabType              : Type de lot de fabrication
  * @param iLotID                 : Id du lot
  * @param iQty                   : Qté en réception
  * @param iAnswerYesAllQuestions : Passe automatiquement ou non les messages
  * @param iReceptionType         : Type de réception (PT, rebut, démontage)
  * @param ioResult               : Valeur de retour
  */
  procedure CheckTraceability(
    iCFabType              in     FAL_LOT.C_FAB_TYPE%type
  , iLotID                 in     FAL_LOT.FAL_LOT_ID%type
  , iQty                   in     FAL_LOT.LOT_INPROD_QTY%type
  , iAnswerYesAllQuestions in     integer
  , iReceptionType         in     integer
  , ioResult               in out integer
  )
  is
    cntComponents number;
  begin
    -- Pas de tracabilité totale pour les Cpt des OF type STT.
    if (iCFabType = btSubcontract) then
      if iReceptionType = rtReject then
        ioResult  := rtOkCompoWithTotTraceReject;
      else
        ioResult  := rtOkCompoWithTotalTrace;
      end if;
    else
      select count(*)
        into cntComponents
        from FAL_LOT_MATERIAL_LINK FLML
       where FAL_LOT_ID = iLotID
         and C_TYPE_COM = cptActive
         and C_KIND_COM = ckComponent
         and LOM_STOCK_MANAGEMENT = 1
         and iQty > LOM_MAX_RECEIPT_QTY
         and FAL_TOOLS.prcIsFullTracability(GCO_GOOD_ID) = 1;

      if     (iAnswerYesAllQuestions = 0)
         and (cntComponents > 0) then
        -- ERROR ASK : Au moins un composant en traçabilité totale n''est pas en quantité suffisante dans le stock atelier
        --             pour la réception. Rappel : pour ces composants la consommation pour un lot de fabrication doit
        --             provenir d''un même lot de stockage, voulez-vous continuer ?
        if iReceptionType = rtReject then
          ioResult  := rtAskCompoWithTotTraceReject;
        else
          ioResult  := rtAskCompoWithTotalTrace;
        end if;
      end if;

      if ioResult > 0 then
        if iReceptionType = rtReject then
          ioResult  := rtOkCompoWithTotTraceReject;
        else
          ioResult  := rtOkCompoWithTotalTrace;
        end if;
      end if;
    end if;
  end CheckTraceability;

  /**
  * procedure CharacteristicsExists
  * Description
  *    Test si le lot contient des détails avec quantité solde ou quantité rebut morpho supérieur à 0
  * @author CLE
  * @param   aFalLotId               Id du lot
  */
  function CharacteristicsExists(aFalLotId fal_lot.fal_lot_id%type)
    return boolean
  is
    cntDetail number;
  begin
    cntDetail  := 0;

    select count(*)
      into cntDetail
      from FAL_LOT_DETAIL
     where FAL_LOT_ID = aFalLotId
       and nvl(FAD_BALANCE_QTY, 0) + nvl(FAD_MORPHO_REJECT_QTY, 0) > 0;

    return(nvl(cntDetail, 0) > 0);
  end;

  function MissingComponentsCount(aFalLotId fal_lot.fal_lot_id%type, aSessionId fal_lot_mat_link_tmp.lom_session%type)
    return integer
  is
    cntMissingCompo integer;
  begin
    select count(*)
      into cntMissingCompo
      from FAL_LOT_MAT_LINK_TMP LOM
     where FAL_LOT_ID = aFalLotId
       and LOM_SESSION = aSessionId
       and C_KIND_COM = ckComponent
       and (    (    LOM_FULL_REQ_QTY > 0
                 and not exists(select FAL_LOT_MAT_LINK_TMP_ID
                                  from FAL_COMPONENT_LINK FCL
                                 where FCL.FAL_LOT_MAT_LINK_TMP_ID = LOM.FAL_LOT_MAT_LINK_TMP_ID) )
            or (LOM_FULL_REQ_QTY <> (select sum(nvl(FCL.FCL_RETURN_QTY, 0) + nvl(FCL.FCL_TRASH_QTY, 0) + nvl(FCL.FCL_HOLD_QTY, 0) )
                                       from FAL_COMPONENT_LINK FCL
                                      where FCL.FAL_LOT_MAT_LINK_TMP_ID = LOM.FAL_LOT_MAT_LINK_TMP_ID) )
           );

    return nvl(cntMissingCompo, 0);
  end;

/**
  * procedure CheckMissingComponents
  * Description
  *    Retourne une valeur négative s'il manque ou non des composants en atelier (affichage obligatoire de la consommation)
  *    lors de la réception.
  * @author CLE
  * @param   aFalLotId             Id du lot
  * @param   aSessionId            Session oracle
  * @param   DisplayConsumption    Détermine si on veut ou non l'affichage de la consommation
  * @param   ReceptionType         Type de réception (PT, rebut, démontage)
  * @param   aResult               Valeur de retour
  */
  procedure CheckMissingComponents(
    aFalLotId                 fal_lot.fal_lot_id%type
  , aSessionId                fal_lot_mat_link_tmp.lom_session%type
  , DisplayConsumption        integer
  , ReceptionType             integer
  , aResult            in out integer
  )
  is
    cntMissingCompo integer;
    bForceDisplay   boolean;
  begin
    -- Aucun composants temporaire n'a été créé, pas d'affichage de la consommation
    if not FAL_LOT_MAT_LINK_TMP_FCT.ExistsTmpComponents(aFalLotId, aSessionId) then
      bForceDisplay  := false;
    -- Affichage consommation
    elsif DisplayConsumption = 1 then
      bForceDisplay  := true;
    else
      cntMissingCompo  := MissingComponentsCount(aFalLotId, aSessionId);
      bForceDisplay    :=(cntMissingCompo > 0);
    end if;

    if bForceDisplay then
      if ReceptionType = rtReject then
        aResult  := rtAskDisplayConsumptReject;
      elsif ReceptionType = rtDismantling then
        aResult  := rtAskDisplayConsumptDismount;
      else
        aResult  := rtAskDisplayConsumpt;
      end if;
    else
      if ReceptionType = rtReject then
        aResult  := rtOkDisplayConsumptReject;
      elsif ReceptionType = rtDismantling then
        aResult  := rtOkDisplayConsumptDismount;
      else
        aResult  := rtOkDisplayConsumpt;
      end if;
    end if;
  end;

  /**
  * procedure CheckMissingWeigh
  * Description
  *    Retourne une valeur négative s'il manque ou non une pesée pour les matière précieuse (affichage obligatoire de la pesée)
  *    lors de la réception.
  * @author SMA MAR.2012
  * @param   iLotId         Id du lot
  * @param   iReceptionType Type de réception (PT, rebut, démontage)
  * @param   ioResult       Valeur de retour
  */
  procedure CheckMissingWeigh(
    iLotId                    fal_lot.fal_lot_id%type
  , iDicFabConditionId        varchar2
  , iGoodId                   GCO_GOOD.GCO_GOOD_ID%type
  , iQuantity                 number
  , iReceptionType            integer
  , ioResult           in out integer
  )
  is
  begin
    if     GCO_I_LIB_CDA_MANUFACTURE.isProductAskWeigh(iGoodId => iGoodId, iDicFabConditionId => iDicFabConditionId) = 1
       and FAL_LIB_BATCH.isWeighingNeeded(iLotId, iQuantity) = 1 then
      -- Affichage pesée
      if iReceptionType = rtReject then
        ioResult  := rtAskDisplayWeighReject;
      else
        ioResult  := rtAskDisplayWeigh;
      end if;
    else
      if iReceptionType = rtReject then
        ioResult  := rtOkDisplayWeighReject;
      else
        ioResult  := rtOkDisplayWeigh;
      end if;
    end if;
  end CheckMissingWeigh;

/**
  * procedure CheckConfirmBST
  * Description
  *    Retourne une valeur négative si toutes les BST liés aux opérations externes du lot ne sont pas confirmées
  *    lors de la réception.
  * @author SMA MAR.2012
  * @LastUpdate age 21.06.2012
  * @param   iLotId         Id du lot
  * @param   iReceptionType Type de réception (PT, rebut, démontage)
  * @param   ioResult       Valeur de retour
  */
  procedure CheckConfirmBST(iLotId FAL_LOT.FAL_LOT_ID%type, iCFabType FAL_LOT.C_FAB_TYPE%type, iReceptionType integer, ioResult in out integer)
  is
    lListNotOk varchar2(4000);
  begin
    lListNotOk  := null;

    if iCFabType <> btSubcontract then
      FAL_I_LIB_SUBCONTRACTO.CheckConfirmBST(iLotId, lListNotOk);
    end if;

    if lListNotOk is not null then
      -- Affichage pesée
      if iReceptionType = rtReject then
        ioResult  := rtAskDisplayConfirmBSTReject;
      else
        ioResult  := rtAskDisplayConfirmBST;
      end if;
    else
      if iReceptionType = rtReject then
        ioResult  := rtOkDisplayConfirmBSTReject;
      else
        ioResult  := rtOkDisplayConfirmBST;
      end if;
    end if;
  end CheckConfirmBST;

  /**
  * procedure UpdateReceptFlagDetailLot
  * Description
  *    Mise à 0 du flag de réception des détails du lot
  * @author CLE
  * @param   aFalLotId             Id du lot
  */
  procedure UpdateReceptFlagDetailLot(aFalLotId fal_lot.fal_lot_id%type, aQty fal_lot.lot_inprod_qty%type)
  is
    pragma autonomous_transaction;
  begin
    update FAL_LOT_DETAIL
       set FAD_RECEPT_SELECT = 0
         , FAD_RECEPT_INPROGRESS_QTY = 0
     where FAL_LOT_ID = aFalLotId
       and C_LOT_DETAIL = ldCharact;   -- Caractérisé

    update FAL_LOT_DETAIL
       set FAD_RECEPT_SELECT = 1
         , FAD_RECEPT_INPROGRESS_QTY = FAL_TOOLS.ArrondiInferieur(aQty *(GCG_QTY / GCG_REF_QTY), GCO_GOOD_ID)
     where FAL_LOT_ID = aFalLotId
       and (   C_LOT_DETAIL = ldCoupled
            or   -- Couplé
               C_LOT_DETAIL = ldCoupledRef)
       and   -- Couplé (produit de référence)
           GCG_INCLUDE_GOOD = '1';

    commit;
  end;

  /**
  * procedure CheckProductCharacteristic
  * Description
  *   Retour négatif si le produit a des caractérisations gérées sur stock ou si la config produit couplé est active
  *   (saisie des caractérisation obligatoire) lors de la réception
  * @author CLE
  * @param   aCFabType     Type de lot
  * @param   aGcoGoodId    Id du produit terminé
  * @param   ReceptionType Type de réception (PT, rebut, démontage)
  * @param   aResult       Valeur de retour
  */
  procedure CheckProductCharacteristic(iLotID in FAL_LOT.FAL_LOT_ID%type, ReceptionType integer, aResult in out integer)
  is
  begin
    if FAL_LIB_BATCH.useDetails(iLotID) = 1 then
      if ReceptionType = rtReject then
        aResult  := rtAskDisplayCharactReject;
      else
        aResult  := rtAskDisplayCharact;
      end if;
    else
      if ReceptionType = rtReject then
        aResult  := rtOkDisplayCharactReject;
      else
        aResult  := rtOkDisplayCharact;
      end if;
    end if;
  end;

  /**
   * procedure CheckBatchDetails
   * Description
   *    Contrôle que les détails lot existants permettent d'effectuer une
   *    réception automatique ou en série (sans affichage).
   * @param   aFalLotId               Id du lot
   * @param   aCFabType               Type de lot
   * @param   aGcoGoodId              Id du produit terminé
   * @param   aFinishedProductQty     Qté de réception du produit terminé (non null)
   * @param   aRejectQty              Qté rebut de réception (non null)
   * @param   aDismountedQty          Qté démontée (non null)
   * @param   aResult                 Valeur de retour
   */
  procedure CheckBatchDetails(
    aFalLotId           in     FAL_LOT.FAL_LOT_ID%type
  , aCFabType           in     FAL_LOT.C_FAB_TYPE%type
  , aGcoGoodId          in     FAL_LOT.GCO_GOOD_ID%type
  , aFinishedProductQty in     FAL_LOT.LOT_INPROD_QTY%type default 0
  , aRejectQty          in     FAL_LOT.LOT_INPROD_QTY%type default 0
  , aDismountedQty      in     FAL_LOT.LOT_INPROD_QTY%type default 0
  , aResult             in out integer
  )
  is
    cursor curBatchDetailCounts(aFalLotId in FAL_LOT.FAL_LOT_ID%type)
    is
      select (select count(*)
                from GCO_CHARACTERIZATION
               where GCO_GOOD_ID = LOT.GCO_GOOD_ID
                 and (    (C_CHARACT_TYPE <> GCO_I_LIB_CONSTANT.gcCharacTypeSet)
                      or (cInitLotRefCompl = 'FALSE') )
                 and C_CHARACT_TYPE <> GCO_I_LIB_CONSTANT.gcCharacTypeChrono
                 and CHA_STOCK_MANAGEMENT = 1) MANDATORY_CHARACT
           , (select count(*)
                from FAL_LOT_DETAIL
               where FAL_LOT_ID = LOT.FAL_LOT_ID
                 and C_LOT_DETAIL = ldCharact
                 and (   FAD_CHARACTERIZATION_VALUE_1 is null
                      or FAD_CHARACTERIZATION_VALUE_1 <> 'N/A')
                 and (   FAD_CHARACTERIZATION_VALUE_2 is null
                      or FAD_CHARACTERIZATION_VALUE_2 <> 'N/A')
                 and (   FAD_CHARACTERIZATION_VALUE_3 is null
                      or FAD_CHARACTERIZATION_VALUE_3 <> 'N/A')
                 and (   FAD_CHARACTERIZATION_VALUE_4 is null
                      or FAD_CHARACTERIZATION_VALUE_4 <> 'N/A')
                 and (   FAD_CHARACTERIZATION_VALUE_5 is null
                      or FAD_CHARACTERIZATION_VALUE_5 <> 'N/A')
                 and GCG_INCLUDE_GOOD = 1
                 and nvl(A_CONFIRM, 0) = 0
                 and (   FAD_BALANCE_QTY > 0
                      or FAD_MORPHO_REJECT_QTY > 0) ) LOT_CHARACT_DETAILS
           , (select count(*)
                from FAL_LOT_DETAIL
               where FAL_LOT_ID = LOT.FAL_LOT_ID
                 and C_LOT_DETAIL in(ldCoupled, ldCoupledRef)
                 and GCG_INCLUDE_GOOD = 1
                 and nvl(A_CONFIRM, 0) = 0
                 and (   FAD_BALANCE_QTY > 0
                      or FAD_MORPHO_REJECT_QTY > 0) ) LOT_COUPLED_DETAILS
        from FAL_LOT LOT
       where LOT.FAL_LOT_ID = aFalLotId;

    tplBatchDetailCounts curBatchDetailCounts%rowtype;

    cursor curBatchDetailSums(aFalLotId in FAL_LOT.FAL_LOT_ID%type, aCharactDetail in integer)
    is
      select (select sum(FAD_BALANCE_QTY)
                from FAL_LOT_DETAIL
               where FAL_LOT_ID = LOT.FAL_LOT_ID
                 and (    (    aCharactDetail = 1
                           and C_LOT_DETAIL = ldCharact)
                      or (    aCharactDetail = 0
                          and C_LOT_DETAIL in(ldCoupled, ldCoupledRef) ) )
                 and (   FAD_CHARACTERIZATION_VALUE_1 is null
                      or FAD_CHARACTERIZATION_VALUE_1 <> 'N/A')
                 and (   FAD_CHARACTERIZATION_VALUE_2 is null
                      or FAD_CHARACTERIZATION_VALUE_2 <> 'N/A')
                 and (   FAD_CHARACTERIZATION_VALUE_3 is null
                      or FAD_CHARACTERIZATION_VALUE_3 <> 'N/A')
                 and (   FAD_CHARACTERIZATION_VALUE_4 is null
                      or FAD_CHARACTERIZATION_VALUE_4 <> 'N/A')
                 and (   FAD_CHARACTERIZATION_VALUE_5 is null
                      or FAD_CHARACTERIZATION_VALUE_5 <> 'N/A')
                 and GCG_INCLUDE_GOOD = 1
                 and nvl(A_CONFIRM, 0) = 0
                 and FAD_BALANCE_QTY > 0) FAD_BALANCE_QTY
           , (select sum(FAD_MORPHO_REJECT_QTY)
                from FAL_LOT_DETAIL
               where FAL_LOT_ID = LOT.FAL_LOT_ID
                 and (    (    aCharactDetail = 1
                           and C_LOT_DETAIL = ldCharact)
                      or (    aCharactDetail = 0
                          and C_LOT_DETAIL in(ldCoupled, ldCoupledRef) ) )
                 and (   FAD_CHARACTERIZATION_VALUE_1 is null
                      or FAD_CHARACTERIZATION_VALUE_1 <> 'N/A')
                 and (   FAD_CHARACTERIZATION_VALUE_2 is null
                      or FAD_CHARACTERIZATION_VALUE_2 <> 'N/A')
                 and (   FAD_CHARACTERIZATION_VALUE_3 is null
                      or FAD_CHARACTERIZATION_VALUE_3 <> 'N/A')
                 and (   FAD_CHARACTERIZATION_VALUE_4 is null
                      or FAD_CHARACTERIZATION_VALUE_4 <> 'N/A')
                 and (   FAD_CHARACTERIZATION_VALUE_5 is null
                      or FAD_CHARACTERIZATION_VALUE_5 <> 'N/A')
                 and GCG_INCLUDE_GOOD = 1
                 and nvl(A_CONFIRM, 0) = 0
                 and FAD_MORPHO_REJECT_QTY > 0) FAD_MORPHO_REJECT_QTY
        from FAL_LOT LOT
       where LOT.FAL_LOT_ID = aFalLotId;

    tplBatchDetailSums   curBatchDetailSums%rowtype;
    vResult              integer;
    vDetailCount         integer;
  begin
    vResult  := 0;
    -- Le lot peut-il avoir des détails ?
    CheckProductCharacteristic(aFalLotId, rtFinishedProduct, aResult);

    -- Si oui
    if aResult < 0 then
      -- Recherche des informations
      open curBatchDetailCounts(aFalLotId);

      fetch curBatchDetailCounts
       into tplBatchDetailCounts;

      close curBatchDetailCounts;

      -- Pas de contrôle à effectuer s'il n'y a que du démontage et aucun détail défini
      if    tplBatchDetailCounts.LOT_CHARACT_DETAILS > 0
         or tplBatchDetailCounts.LOT_COUPLED_DETAILS > 0
         or aFinishedProductQty > 0
         or aRejectQty > 0 then
        -- Mais sinon, on commence les contrôles
        if     tplBatchDetailCounts.LOT_CHARACT_DETAILS = 0
           and tplBatchDetailCounts.MANDATORY_CHARACT > 0 then
          -- Le lot a des caractérisations obligatoires alors que les détails caractérisés ne sont pas définis
          -- Cas caractérisation de type 4 ou 5 précédemment géré en delphi mais pas en PL
          vResult  := arCharact4or5;
        elsif     tplBatchDetailCounts.LOT_CHARACT_DETAILS = 0
              and tplBatchDetailCounts.LOT_COUPLED_DETAILS = 0 then
          -- Aucun détail avec quantité solde
          FAL_LOT_DETAIL_FUNCTIONS.CreateBatchDetail(aFalLotId    => aFalLotId
                                                   , aGcoGoodId   => aGcoGoodId
                                                   , aQty         => aFinishedProductQty + aRejectQty + aDismountedQty
                                                    );
        else
          -- on teste prioritairement les détails caractérisés
          if tplBatchDetailCounts.LOT_CHARACT_DETAILS > 0 then
            -- Les contrôles suivants portent sur les détails caractérisés
            vDetailCount  := tplBatchDetailCounts.LOT_CHARACT_DETAILS;

            open curBatchDetailSums(aFalLotId, 1);
          else
            -- Les contrôles suivants portent sur les détails couplés
            vDetailCount  := tplBatchDetailCounts.LOT_COUPLED_DETAILS;

            open curBatchDetailSums(aFalLotId, 0);
          end if;

          fetch curBatchDetailSums
           into tplBatchDetailSums;

          close curBatchDetailSums;

          if vDetailCount = 1 then
            -- Autorisé :
            -- un seul détail lot avec (quantité solde + rebut morpho) >= (quantité réception bonne + rebut + démontage)
            -- et quantité solde >= quantité réception bonne
            if    (aFinishedProductQty > tplBatchDetailSums.FAD_BALANCE_QTY)
               or ( (aFinishedProductQty + aRejectQty + aDismountedQty) >(tplBatchDetailSums.FAD_BALANCE_QTY + tplBatchDetailSums.FAD_MORPHO_REJECT_QTY) ) then
              -- Le détail lot n'a pas de solde + rebut suffisant
              vResult  := arCharDetailWithoutEnoughQty + 1;
            end if;
          else
            -- Autorisé :
            -- réception sans rebut ni démontage, plusieurs détails lot avec somme des quantités solde = quantité réception bonne
            -- réception sans rebut , plusieurs détails lot avec somme des quantités solde = quantité réception bonne et somme des quantités rebut morpho = quantité réception démontage
            -- réception sans démontage, plusieurs détails lot avec somme des quantités solde = quantité réception bonne et somme des quantités rebut morpho = quantité réception rebut
            if (aRejectQty + aDismountedQty) = 0 then
              if aFinishedProductQty <> tplBatchDetailSums.FAD_BALANCE_QTY then
                -- La somme des quantités solde des détails lot ne correspond pas à la quantité en réception
                vResult  := arSeveralCharactDetailWithQty + 1;
              end if;
            elsif aDismountedQty = 0 then
              if    (aFinishedProductQty <> tplBatchDetailSums.FAD_BALANCE_QTY)
                 or (aRejectQty <> tplBatchDetailSums.FAD_MORPHO_REJECT_QTY) then
                -- La somme des quantités solde ou rebut des détails lot ne correspond pas à la quantité en réception ou réception rebut
                vResult  := arSeveralCharactDetailWithQty + 2;
              end if;
            elsif aRejectQty = 0 then
              if    (aFinishedProductQty <> tplBatchDetailSums.FAD_BALANCE_QTY)
                 or (aDismountedQty <> tplBatchDetailSums.FAD_MORPHO_REJECT_QTY) then
                -- La somme des quantités solde ou rebut des détails lot ne correspond pas à la quantité en réception ou démontage
                vResult  := arSeveralCharactDetailWithQty + 3;
              end if;
            else
              -- Impossible de faire de la réception rebut + démontage sur plusieurs détails
              vResult  := arSeveralCharactDetailWithQty + 4;
            end if;
          end if;
        end if;
      end if;
    end if;

    if vResult = 0 then
      aResult  := rtOkBatchDetails;
    else
      aResult  := rtErrBatchDetails;
    end if;
  end CheckBatchDetails;

  /**
   * procedure SelectBatchDetailsForRecept
   * Description
   *    Sélection des détails lot pour réception automatique ou en série
   *    (sans affichage).
   *    La valeur de aResult indique si on est en réception de pièces bonnes,
   *    rebut ou démontage.
   *    Si la sélection est réussie, aResult est mis à jour avec son opposé et
   *    la réception peut continuer, sinon il contient l'erreur.
   *    Attention : CheckBatchDetails doit avoir été appelé !!
   * @author JCH
   * @param   aFalLotId               Id du lot
   * @param   aFinishedProductQty     Qté de réception du produit terminé
   * @param   aRejectQty              Qté rebut de réception
   * @param   aDismountedQty          Qté démontée
   * @param   aResult                 Valeur de retour
   */
  procedure SelectBatchDetailsForRecept(
    aFalLotId           in     FAL_LOT.FAL_LOT_ID%type
  , aFinishedProductQty in     FAL_LOT.LOT_INPROD_QTY%type default 0
  , aRejectQty          in     FAL_LOT.LOT_INPROD_QTY%type default 0
  , aDismountedQty      in     FAL_LOT.LOT_INPROD_QTY%type default 0
  , aResult             in out integer
  )
  is
    vCharactDetail integer;
    vQty           FAL_LOT.LOT_INPROD_QTY%type;
  begin
    -- Mise à zéro
    update FAL_LOT_DETAIL
       set FAD_RECEPT_SELECT = 0
         , FAD_RECEPT_INPROGRESS_QTY = 0
     where FAL_LOT_ID = aFalLotId;

    -- Nombre de caractérisations pour savoir si l'on travaille sur les détails
    -- caractérisés ou couplés
    select sign(count(*) )
      into vCharactDetail
      from FAL_LOT LOT
         , GCO_PRODUCT PDT
         , GCO_CHARACTERIZATION CHA
     where LOT.FAL_LOT_ID = aFalLotId
       and PDT.GCO_GOOD_ID = LOT.GCO_GOOD_ID
       and CHA.GCO_GOOD_ID = PDT.GCO_GOOD_ID
       and PDT.PDT_STOCK_MANAGEMENT = 1
       and CHA.CHA_STOCK_MANAGEMENT = 1;

    -- Réception produit terminé vs rebut/démontage
    if aResult = rtAskDisplayCharact then
      -- Sélection des détails lots avec quantité solde
      update FAL_LOT_DETAIL
         set FAD_RECEPT_SELECT = 1
           , FAD_RECEPT_INPROGRESS_QTY = least(FAD_BALANCE_QTY, aFinishedProductQty)
       where FAL_LOT_ID = aFalLotId
         and (    (    vCharactDetail = 1
                   and C_LOT_DETAIL = ldCharact)
              or (    vCharactDetail = 0
                  and C_LOT_DETAIL in(ldCoupled, ldCoupledRef) ) )
         and (   FAD_CHARACTERIZATION_VALUE_1 is null
              or FAD_CHARACTERIZATION_VALUE_1 <> 'N/A')
         and (   FAD_CHARACTERIZATION_VALUE_2 is null
              or FAD_CHARACTERIZATION_VALUE_2 <> 'N/A')
         and (   FAD_CHARACTERIZATION_VALUE_3 is null
              or FAD_CHARACTERIZATION_VALUE_3 <> 'N/A')
         and (   FAD_CHARACTERIZATION_VALUE_4 is null
              or FAD_CHARACTERIZATION_VALUE_4 <> 'N/A')
         and (   FAD_CHARACTERIZATION_VALUE_5 is null
              or FAD_CHARACTERIZATION_VALUE_5 <> 'N/A')
         and GCG_INCLUDE_GOOD = 1
         and FAD_BALANCE_QTY > 0;
    else
      -- Réception rebut vs démontage
      if aResult = rtAskDisplayCharactReject then
        vQty  := aRejectQty;
      else
        vQty  := aDismountedQty;
      end if;

      -- Sélection des détails lots avec quantité rebut morpho
      update FAL_LOT_DETAIL
         set FAD_RECEPT_SELECT = 1
           , FAD_RECEPT_INPROGRESS_QTY = least(FAD_MORPHO_REJECT_QTY, vQty)
       where FAL_LOT_ID = aFalLotId
         and (    (    vCharactDetail = 1
                   and C_LOT_DETAIL = ldCharact)
              or (    vCharactDetail = 0
                  and C_LOT_DETAIL in(ldCoupled, ldCoupledRef) ) )
         and (   FAD_CHARACTERIZATION_VALUE_1 is null
              or FAD_CHARACTERIZATION_VALUE_1 <> 'N/A')
         and (   FAD_CHARACTERIZATION_VALUE_2 is null
              or FAD_CHARACTERIZATION_VALUE_2 <> 'N/A')
         and (   FAD_CHARACTERIZATION_VALUE_3 is null
              or FAD_CHARACTERIZATION_VALUE_3 <> 'N/A')
         and (   FAD_CHARACTERIZATION_VALUE_4 is null
              or FAD_CHARACTERIZATION_VALUE_4 <> 'N/A')
         and (   FAD_CHARACTERIZATION_VALUE_5 is null
              or FAD_CHARACTERIZATION_VALUE_5 <> 'N/A')
         and GCG_INCLUDE_GOOD = 1
         and FAD_MORPHO_REJECT_QTY > 0;

      -- Recherche de la quantité à attribuer sur quantité solde
      select vQty - sum(FAD_RECEPT_INPROGRESS_QTY)
        into vQty
        from FAL_LOT_DETAIL
       where FAL_LOT_ID = aFalLotId
         and (    (    vCharactDetail = 1
                   and C_LOT_DETAIL = ldCharact)
              or (    vCharactDetail = 0
                  and C_LOT_DETAIL in(ldCoupled, ldCoupledRef) ) )
         and (   FAD_CHARACTERIZATION_VALUE_1 is null
              or FAD_CHARACTERIZATION_VALUE_1 <> 'N/A')
         and (   FAD_CHARACTERIZATION_VALUE_2 is null
              or FAD_CHARACTERIZATION_VALUE_2 <> 'N/A')
         and (   FAD_CHARACTERIZATION_VALUE_3 is null
              or FAD_CHARACTERIZATION_VALUE_3 <> 'N/A')
         and (   FAD_CHARACTERIZATION_VALUE_4 is null
              or FAD_CHARACTERIZATION_VALUE_4 <> 'N/A')
         and (   FAD_CHARACTERIZATION_VALUE_5 is null
              or FAD_CHARACTERIZATION_VALUE_5 <> 'N/A')
         and GCG_INCLUDE_GOOD = 1;

      -- Sélection des détails lots avec quantité solde
      if vQty > 0 then
        update FAL_LOT_DETAIL
           set FAD_RECEPT_SELECT = 1
             , FAD_RECEPT_INPROGRESS_QTY = FAD_RECEPT_INPROGRESS_QTY + least(FAD_BALANCE_QTY, vQty)
         where FAL_LOT_ID = aFalLotId
           and (    (    vCharactDetail = 1
                     and C_LOT_DETAIL = ldCharact)
                or (    vCharactDetail = 0
                    and C_LOT_DETAIL in(ldCoupled, ldCoupledRef) ) )
           and (   FAD_CHARACTERIZATION_VALUE_1 is null
                or FAD_CHARACTERIZATION_VALUE_1 <> 'N/A')
           and (   FAD_CHARACTERIZATION_VALUE_2 is null
                or FAD_CHARACTERIZATION_VALUE_2 <> 'N/A')
           and (   FAD_CHARACTERIZATION_VALUE_3 is null
                or FAD_CHARACTERIZATION_VALUE_3 <> 'N/A')
           and (   FAD_CHARACTERIZATION_VALUE_4 is null
                or FAD_CHARACTERIZATION_VALUE_4 <> 'N/A')
           and (   FAD_CHARACTERIZATION_VALUE_5 is null
                or FAD_CHARACTERIZATION_VALUE_5 <> 'N/A')
           and GCG_INCLUDE_GOOD = 1
           and FAD_BALANCE_QTY > 0;
      end if;
    end if;

    -- La réception peut continuer
    aResult  := -aResult;
  end SelectBatchDetailsForRecept;

  /**
  * procedure CheckProductTraceability
  * Description
  *   Oblige l'affichage de l'appairage en réception si le produit est géré en caractéristique pièce ainsi
  *   qu'au moins un de ses composants ("pièce" ou caractérisation active dans la configuration FAL_PAIRING_CHARACT)
  * @author CLE
  * @param   aCFabType    Type de lot
  * @param   aFalLotId             Id du lot
  * @param   aGcoGoodId            Id du produit terminé
  * @param   aSessionId            Session oracle
  * @param   ReceptionType Type de réception (PT, rebut, démontage)
  * @param   aResult
  */
  procedure CheckProductTraceability(
    aCFabType            fal_lot.c_fab_type%type
  , aFalLotId            fal_lot.fal_lot_id%type
  , aGcoGoodId           fal_lot.gco_good_id%type
  , aSessionId           fal_lot_mat_link_tmp.lom_session%type
  , ReceptionType        integer
  , aResult       in out integer
  )
  is
  begin
    if aCFabType in(btAfterSales, btSubcontract) then
      -- Pas de traçabilité pour les OF de type SAV (type 3) ou STT (type 4)
      if ReceptionType = rtReject then
        aResult  := rtOkDisplayTraceReject;
      else
        aResult  := rtOkDisplayTrace;
      end if;
    else
      if isBatchWithPairing(aFalLotId => aFalLotId, aGcoGoodId => aGcoGoodId, bSearchInTmpCompo => true) = 1 then
        if ReceptionType = rtReject then
          aResult  := rtAskDisplayTraceReject;
        else
          aResult  := rtAskDisplayTrace;
        end if;
      else
        if ReceptionType = rtReject then
          aResult  := rtOkDisplayTraceReject;
        else
          aResult  := rtOkDisplayTrace;
        end if;
      end if;
    end if;
  end;

  /**
  * procedure ReadjustAlignedComponents
  * Description
  *   Création des liens composants pour les composants appairés. Ces composants sont sélectionnés au moment de l'appairage et le lien
  *   FAL_COMPONENT_LINK n'existe pas encore à ce moment.
  * @author CLE
  * @param   aFalLotId   Id du lot
  * @param   aSessionId  Session Oracle
  */
  procedure ReadjustAlignedComponents(
    aFalLotId     fal_lot.fal_lot_id%type
  , aSessionId    fal_lot_mat_link_tmp.lom_session%type
  , aQty          fal_lot.lot_inprod_qty%type
  , ReceptionType integer
  , BatchBalance  integer
  , iAutoCommit   integer
  )
  is
    /* Sélection des appairages créés manuellement */
    cursor crNewPairingComponents
    is
      select   FIN.FAL_FACTORY_IN_ID
             , FIN.FAL_LOT_MATERIAL_LINK_ID
             , CPT.FAL_LOT_MAT_LINK_TMP_ID
             , sum(LNK.LDL_QTY) LINK_QTY
          from FAL_LOT_DETAIL_LINK LNK
             , FAL_LOT_DETAIL DET
             , FAL_FACTORY_IN FIN
             , FAL_LOT_MAT_LINK_TMP CPT
             , (select nvl(max(CHA_STOCK_MANAGEMENT), 0) CHA_STOCK_MANAGEMENT
                  from GCO_CHARACTERIZATION
                 where GCO_GOOD_ID = (select GCO_GOOD_ID
                                        from FAL_LOT
                                       where FAL_LOT_ID = aFalLotId)
                   and C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypePiece) GOOD_PT
         where GOOD_PT.CHA_STOCK_MANAGEMENT = 1
           and LNK.FAL_LOT_DETAIL_ID = DET.FAL_LOT_DETAIL_ID
           and LNK.FAL_FACTORY_IN_ID = FIN.FAL_FACTORY_IN_ID
           and FIN.FAL_LOT_MATERIAL_LINK_ID = CPT.FAL_LOT_MATERIAL_LINK_ID
           and DET.FAD_RECEPT_SELECT = 1
           and DET.FAL_LOT_ID = aFalLotId
           and (select nvl(max(CHA_STOCK_MANAGEMENT), 0)
                  from GCO_CHARACTERIZATION
                 where GCO_GOOD_ID = FIN.GCO_GOOD_ID
                   and instr(cPairingCaract, C_CHARACT_TYPE) > 0) = 1
      group by FIN.FAL_FACTORY_IN_ID
             , FIN.FAL_LOT_MATERIAL_LINK_ID
             , CPT.FAL_LOT_MAT_LINK_TMP_ID
      order by FIN.FAL_LOT_MATERIAL_LINK_ID;

    lnPreviousCpt number := 0;
  begin
    -- Création des liens composants pour les composants qui ont été pris en appairage mais qui n'étaient pas présents dans les liens composants
    for tplNewPairingComponents in crNewPairingComponents loop
      if iAutoCommit = 1 then
        FAL_COMPONENT_LINK_FUNCTIONS.CreateCompoLinkFalFactoryIn(aSessionId            => aSessionId
                                                               , aFalLotMatLinkTmpId   => tplNewPairingComponents.FAL_LOT_MAT_LINK_TMP_ID
                                                               , aFalFactoryInId       => tplNewPairingComponents.FAL_FACTORY_IN_ID
                                                               , aHoldQty              => tplNewPairingComponents.LINK_QTY
                                                                );
      else
        FAL_COMPONENT_LINK_FCT.CreateCompoLinkFalFactoryIn(aSessionId            => aSessionId
                                                         , aFalLotMatLinkTmpId   => tplNewPairingComponents.FAL_LOT_MAT_LINK_TMP_ID
                                                         , aFalFactoryInId       => tplNewPairingComponents.FAL_FACTORY_IN_ID
                                                         , aHoldQty              => tplNewPairingComponents.LINK_QTY
                                                          );
      end if;

      if     (lnPreviousCpt <> 0)
         and (lnPreviousCpt <> tplNewPairingComponents.FAL_LOT_MATERIAL_LINK_ID) then
        -- Pour ces composants, mise à jour basée sur les liens composants (cette mise à jour est basée sur les FAL_COMPONENT_LINK et n'avait donc pas été faite pour ces composants).
        -- Il ne faut la faire qu'une fois que tous les liens sont créés (d'où l'utilisation de lnPreviousCpt).
        FAL_COMPONENT_FUNCTIONS.UpdateFalLotMatLinkafterOutput(aLOM_SESSION                => aSessionId
                                                             , aFAL_LOT_ID                 => aFalLotId
                                                             , aFAL_LOT_MATERIAL_LINK_ID   => lnPreviousCpt
                                                             , aContext                    => FAL_COMPONENT_LINK_FUNCTIONS.ctxtManufacturingReceipt
                                                             , ReceptionType               => ReceptionType
                                                             , BatchBalance                => BatchBalance
                                                             , aReceptQty                  => aQty
                                                              );
      end if;

      lnPreviousCpt  := tplNewPairingComponents.FAL_LOT_MATERIAL_LINK_ID;
    end loop;

    if nvl(lnPreviousCpt, 0) <> 0 then
      -- Mise à jour du dernier composant
      FAL_COMPONENT_FUNCTIONS.UpdateFalLotMatLinkafterOutput(aLOM_SESSION                => aSessionId
                                                           , aFAL_LOT_ID                 => aFalLotId
                                                           , aFAL_LOT_MATERIAL_LINK_ID   => lnPreviousCpt
                                                           , aContext                    => FAL_COMPONENT_LINK_FUNCTIONS.ctxtManufacturingReceipt
                                                           , ReceptionType               => ReceptionType
                                                           , BatchBalance                => BatchBalance
                                                           , aReceptQty                  => aQty
                                                            );
    end if;
  end ReadjustAlignedComponents;

  /**
  * procedure CreateMissingAlignedComponent
  * Description
  *   Création de l'appairage pour les composants caractérisés (l'appairage se fait en interface entre les détails lot N° de pièce et
  *   les composants N° de pièce (ou pris en compte par la configuration FAL_PAIRING_CHARACT). On crée ici les autres liens d'appairage
  *   qui servent ensuite à la traçabilité)
  * @author CLE
  * @param   iFalLotId   Id du lot
  */
  procedure CreateMissingAlignedComponent(iFalLotId in number)
  is
  begin
    merge into FAL_LOT_DETAIL_LINK FLDL
      using (select FCL.FAL_FACTORY_IN_ID
                  , FCL.FCL_HOLD_QTY
                  , DET.FAL_LOT_DETAIL_ID
               from FAL_LOT_DETAIL DET
                  , FAL_COMPONENT_LINK FCL
              where DET.FAD_RECEPT_SELECT = 1
                and DET.FAL_LOT_ID = iFalLotId
                and FCL.FAL_LOT_ID = iFalLotId
                and FCL.GCO_CHARACTERIZATION1_ID is not null
                and (   (select nvl(max(CHA_STOCK_MANAGEMENT), 0)
                           from GCO_CHARACTERIZATION
                          where GCO_GOOD_ID = FCL.GCO_GOOD_ID
                            and instr(cPairingCaract, C_CHARACT_TYPE) > 0) = 0
                     or (select nvl(max(CHA_STOCK_MANAGEMENT), 0) CHA_STOCK_MANAGEMENT
                           from GCO_CHARACTERIZATION
                          where GCO_GOOD_ID = (select GCO_GOOD_ID
                                                 from FAL_LOT
                                                where FAL_LOT_ID = iFalLotId)
                            and C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypePiece) = 0
                    ) ) SRC
      on (    FLDL.FAL_FACTORY_IN_ID = SRC.FAL_FACTORY_IN_ID
          and FLDL.FAL_LOT_DETAIL_ID = SRC.FAL_LOT_DETAIL_ID)
      when matched then
        update
           set LDL_QTY = nvl(LDL_QTY, 0) + SRC.FCL_HOLD_QTY, A_DATEMOD = sysdate, A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
      when not matched then
        insert(FAL_LOT_DETAIL_LINK_ID, FAL_LOT_DETAIL_ID, FAL_FACTORY_IN_ID, LDL_QTY, A_DATECRE, A_IDCRE)
        values(GetNewId, SRC.FAL_LOT_DETAIL_ID, SRC.FAL_FACTORY_IN_ID, SRC.FCL_HOLD_QTY, sysdate, PCS.PC_I_LIB_SESSION.GetUserIni);
  end CreateMissingAlignedComponent;

  /**
  * procedure UpdateExpiryDate
  * Description
  *   Mise à jour de la date de péremption des détails réceptionnés
  *   Si la configuration FAL_INIT_EXPIRY_DATE = 2, la date de péremption est la plus petite des dates de péremption des composants
  *   liés au détail. Si pas de péremption sur les composants, elle sera initialisé par la procédure standard.
  * @author CLE
  * @param   iFalLotId   Id du lot
  * @param   iGoodId     Id du bien produit terminé
  */
  procedure UpdateExpiryDate(iFalLotId in number, iGoodId number)
  is
    lvUpdateQuery      varchar2(32000);
    lCharactFieldIndex integer;
    lnGcoCharactId     number;
    lvCharactChrono    FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
  begin
    lCharactFieldIndex  := FAL_TOOLS.getCharactFieldIndex(iGoodId, GCO_I_LIB_CONSTANT.gcCharacTypeChrono, lnGcoCharactId);

    if lnGcoCharactId is not null then
      lvCharactChrono  := GCO_LIB_CHARACTERIZATION.PropChronologicalFormat(lnGcoCharactId, sysdate);

      -- Mise à jour du champ dénormalisé de la péremption
      update FAL_LOT_DETAIL DET
         set FAD_CHRONOLOGY =
               case FAL_I_LIB_CONSTANT.gcCfgInitExpiryDate
                 when 2 then nvl( (select min(IN_CHRONOLOGY)
                                     from FAL_FACTORY_IN FIN
                                    where FAL_LOT_ID = iFalLotId
                                      and exists(select *
                                                   from FAL_LOT_DETAIL_LINK LNK
                                                  where LNK.FAL_LOT_DETAIL_ID = DET.FAL_LOT_DETAIL_ID
                                                    and LNK.FAL_FACTORY_IN_ID = FIN.FAL_FACTORY_IN_ID) )
                               , lvCharactChrono
                                )
                 else lvCharactChrono
               end
       where FAL_LOT_ID = iFalLotId
         and FAD_RECEPT_SELECT = 1
         and FAD_CHRONOLOGY is null;

      -- Mise à jour de la caractérisation concernée
      lvUpdateQuery    :=
        ' update FAL_LOT_DETAIL ' ||
        '    set FAD_CHARACTERIZATION_VALUE_' ||
        lCharactFieldIndex ||
        ' =  FAD_CHRONOLOGY ' ||
        '      , A_DATEMOD = sysdate ' ||
        '      , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni ' ||
        '  where FAL_LOT_ID = :FAL_LOT_ID ' ||
        '    and FAD_RECEPT_SELECT = 1 ';

      execute immediate lvUpdateQuery
                  using iFalLotId;
    end if;
  end;

  /**
  * Procedure WeighingRequiered
  * Description
  *   Procedure qui indique si pour une session il existe des mouvements de
  *   composants avec pesée matière précieuse obligatoire.
  * @author ECA
  * @lastUpdate
  * @public
  * @param   aSessionID   Session oracle
  */
  function WeighingRequiered(aSessionID varchar)
    return integer
  is
    iMissingWeighing integer;
  begin
    -- Pesée obligatoire
    if PCS.PC_CONFIG.GetConfig('FAL_MVT_WEIGHING_MODE') = '2' then
      -- Recherche des pesées a effectuer pour les mvts de type Stock --> Atelier.
      select distinct 1
                 into iMissingWeighing
                 from GCO_PRECIOUS_MAT GPM
                    , FAL_LOT_MAT_LINK_TMP LOM
                    , FAL_COMPONENT_LINK FCL
                    , FAL_LOT LOT
                where LOM.LOM_SESSION = aSessionID
                  and LOM.FAL_LOT_ID = LOT.FAL_LOT_ID
                  and nvl(LOT.C_FAB_TYPE, btManufacturing) <> btSubcontract
                  and LOM.GCO_GOOD_ID = GPM.GCO_GOOD_ID
                  and LOM.FAL_LOT_MAT_LINK_TMP_ID = FCL.FAL_LOT_MAT_LINK_TMP_ID
                  and LOM.C_KIND_COM = '1'
                  and GPM.GPM_WEIGHT = 1
                  and GPM.GPM_REAL_WEIGHT = 1
                  and FCL.FCL_HOLD_QTY > 0
                  and FCL.FCL_RETURN_QTY = 0
                  and FCL.FCL_TRASH_QTY = 0
                  and FCL.FAL_FACTORY_IN_ID is null
                  and FCL.STM_LOCATION_ID is not null;

      return iMissingWeighing;
    -- Pas de pesées ou pesées facultatives
    else
      return 0;

      if PCS.PC_CONFIG.GetConfig('FAL_MVT_WEIGHING_MODE') = '3' then
        -- Recherche des pesées a effectuer pour les mvts de type Stock --> Atelier.
        select distinct 1
                   into iMissingWeighing
                   from GCO_PRECIOUS_MAT GPM
                      , FAL_LOT_MAT_LINK_TMP LOM
                      , FAL_COMPONENT_LINK FCL
                      , FAL_LOT LOT
                  where LOM.LOM_SESSION = aSessionID
                    and LOM.FAL_LOT_ID = LOT.FAL_LOT_ID
                    and nvl(LOT.C_FAB_TYPE, btManufacturing) <> btSubcontract
                    and LOM.GCO_GOOD_ID = GPM.GCO_GOOD_ID
                    and LOM.FAL_LOT_MAT_LINK_TMP_ID = FCL.FAL_LOT_MAT_LINK_TMP_ID
                    and LOM.C_KIND_COM = '1'
                    and GPM.GPM_WEIGHT = 1
                    and GPM.GPM_REAL_WEIGHT = 1
                    and FCL.FCL_HOLD_QTY > 0
                    and FCL.FCL_RETURN_QTY = 0
                    and FCL.FCL_TRASH_QTY = 0
                    and FCL.FAL_FACTORY_IN_ID is null
                    and FCL.STM_LOCATION_ID is not null
                    and LOM.LOM_WEIGHING_MANDATORY = 1;

        return iMissingWeighing;
      -- Pas de pesées ou pesées facultatives
      else
        return 0;
      end if;
    end if;
  exception
    when others then
      return 0;
  end;

  /**
  * procedure doComponentsIssue
  * Description
  *   Déclenche la sortie des composants (stock vers atelier) non encore en atelier à la réception
  * @author CLE
  * @param   aFalLotId   Id du lot
  * @param   aSessionId  Session Oracle
  * @param   aDate       Date de réception
  * @param   iCFabType   Type de lot de fabrication
  * @return  aResult     résultat
  */
  procedure doComponentsIssue(
    aFalLotId     in     FAL_LOT.FAL_LOT_ID%type
  , aSessionId    in     FAL_LOT_MAT_LINK_TMP.LOM_SESSION%type
  , aDate         in     FAL_LOT.LOT_PLAN_END_DTE%type
  , aQty          in     FAL_LOT.LOT_INPROD_QTY%type
  , iCFabType     in     FAL_LOT.C_FAB_TYPE%type
  , ReceptionType in     integer
  , BatchBalance  in     integer
  , aResult       in out integer
  )
  is
    aPreparedStockMovements  FAL_STOCK_MOVEMENT_FUNCTIONS.TPreparedStockMovements;
    lttSTTStockPositionInfos FAL_LIB_PAIRING.ttSTTStockPositionInfos;
    aErrorCode               varchar2(255);
    aErrorMsg                varchar2(255);
  begin
    -- Est-ce que des pesées matières précieuses, pour ces composants, sont requises ?
    if WeighingRequiered(aSessionID) = 1 then
      aResult  := rtErrComponentWeighing;
      return;
    end if;

    aPreparedStockMovements   := FAL_STOCK_MOVEMENT_FUNCTIONS.TPreparedStockMovements();
    lttSTTStockPositionInfos  := FAL_LIB_PAIRING.ttSTTStockPositionInfos();
    -- Création des entrées atelier pour le lot. si STT, mémorisation des infos positions stock STT.
    FAL_COMPONENT_FUNCTIONS.CreateAllFactoryMovements(aFAL_LOT_ID                => aFalLotId
                                                    , aFCL_SESSION               => aSessionId
                                                    , aPreparedStockMovement     => aPreparedStockMovements
                                                    , aOUT_DATE                  => aDate
                                                    , aMovementKind              => FAL_STOCK_MOVEMENT_FUNCTIONS.mktSortieStockVersAtelier
                                                    , aC_IN_ORIGINE              => case ReceptionType
                                                        when rtBatchAssembly then eoAssembly
                                                        else eoIssue
                                                      end
                                                    , aContext                   => FAL_COMPONENT_LINK_FUNCTIONS.ctxtManufacturingReceipt
                                                    , ittSTTStockPositionInfos   => lttSTTStockPositionInfos
                                                    , iCFabType                  => iCFabType
                                                     );
    -- Déclencher les mouvements de stock préalablement préparés
    FAL_STOCK_MOVEMENT_FUNCTIONS.ApplyPreparedStockMovements(aErrorCode                => aErrorCode
                                                           , aErrorMsg                 => aErrorMsg
                                                           , aPreparedStockMovements   => aPreparedStockMovements
                                                           , MvtsContext               => FAL_STOCK_MOVEMENT_FUNCTIONS.ctxDefault
                                                            );
    -- Mise à jour des réseaux
    FAL_NETWORK.MiseAJourReseaux(aFalLotId, FAL_NETWORK.ncSortieComposant, '');
    -- Mise à jour des Entrées Atelier avec les positions de stock créées
    -- dans le stock Atelier par les mouvements de stock
    FAL_STOCK_MOVEMENT_FUNCTIONS.UpdFactEntriesWthAppliedStkMvt(aPreparedStockMovements);

    if iCFabType = btSubcontract then
      -- Mise à jour des appairages avec les entrées ateliers créées si lot STT.
      FAL_PRC_PAIRING.updAlignementWithFactEntries(ittSTTStockPositionInfos => lttSTTStockPositionInfos);
    end if;
  end;

  /**
  * procedure UpdateFalFactoryIn
  * Description
  *   Mise à jour des entrées atelier à la réception et au solde. On ne met à jour que les entrées qui sont sélectionnées à la consommation
  *   (entrée liée au lien composants)
  *    - A la réception, les quantités retour et déchet (FCL_RETURN_QTY et FCL_TRASH_QTY) doivent être à 0
  *    - Au solde, la quantité saisie (FCL_HOLD_QTY) doit être à 0
  * @author CLE
  * @param   aFalLotId    Id du lot
  * @param   aSessionId   Session oracle
  */
  procedure UpdateFalFactoryIn(aFalLotId fal_lot.fal_lot_id%type, aSessionId fal_lot_mat_link_tmp.lom_session%type)
  is
  begin
    update FAL_FACTORY_IN FFI
       set IN_OUT_QTE = nvl(IN_OUT_QTE, 0) + (select sum(FCL_HOLD_QTY) + sum(FCL_RETURN_QTY) + sum(FCL_TRASH_QTY)
                                                from FAL_COMPONENT_LINK
                                               where FAL_FACTORY_IN_ID = FFI.FAL_FACTORY_IN_ID
                                                 and FAL_LOT_ID = aFalLotId
                                                 and FCL_SESSION = aSessionId)
         , IN_BALANCE =
                 nvl(IN_IN_QTE, 0) -
                 nvl(IN_OUT_QTE, 0) -
                 (select sum(FCL_HOLD_QTY) + sum(FCL_RETURN_QTY) + sum(FCL_TRASH_QTY)
                    from FAL_COMPONENT_LINK
                   where FAL_FACTORY_IN_ID = FFI.FAL_FACTORY_IN_ID
                     and FAL_LOT_ID = aFalLotId
                     and FCL_SESSION = aSessionId)
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         , A_DATEMOD = sysdate
     where FAL_FACTORY_IN_ID in(select FAL_FACTORY_IN_ID
                                  from FAL_COMPONENT_LINK
                                 where FAL_LOT_ID = aFalLotId
                                   and FCL_SESSION = aSessionId);
  end;

  /**
  * procedure doComponentsOutput
  * Description
  *   Déclenche la sortie atelier des composants en réception
  * @author CLE
  * @param   aFalLotId      Id du lot
  * @param   aSessionId     Session oracle
  * @param   ReceptionType  Type de réception (produit terminé, rebut)
  * @param   aDate          Date de réception
  */
  procedure doComponentsOutput(
    aFalLotId     fal_lot.fal_lot_id%type
  , aSessionId    fal_lot_mat_link_tmp.lom_session%type
  , ReceptionType integer
  , aDate         fal_lot.lot_plan_end_dte%type
  )
  is
    aPreparedStockMovements FAL_STOCK_MOVEMENT_FUNCTIONS.TPreparedStockMovements;
    aErrorCode              varchar2(255);
    aErrorMsg               varchar2(255);
  begin
    aPreparedStockMovements  := FAL_STOCK_MOVEMENT_FUNCTIONS.TPreparedStockMovements();
    -- Création des sorties atelier pour le lot
    FAL_COMPONENT_FUNCTIONS.CreateFactoryMvtsOnRecept(aFalLotId                 => aFalLotId
                                                    , aSessionId                => aSessionId
                                                    , ReceptionType             => ReceptionType
                                                    , aDate                     => aDate
                                                    , aPreparedStockMovements   => aPreparedStockMovements
                                                     );
    -- Déclencher les mouvements de stock préalablement préparés
    FAL_STOCK_MOVEMENT_FUNCTIONS.ApplyPreparedStockMovements(aErrorCode                => aErrorCode
                                                           , aErrorMsg                 => aErrorMsg
                                                           , aPreparedStockMovements   => aPreparedStockMovements
                                                           , MvtsContext               => FAL_STOCK_MOVEMENT_FUNCTIONS.ctxDefault
                                                           , aFalHistoLotId            => COM_I_LIB_LIST_ID_TEMP.getGlobalVar('ID_FOR_BATCH_RECEPT_HISTO')
                                                            );
  end;

  /**
  * procedure CreateTraceability
  * Description
  *   Création de la traçabilité
  * @author CLE
  * @param   aFalLotId      Id du lot
  */
  procedure CreateTraceability(aFalLotId fal_lot.fal_lot_id%type)
  is
  begin
    merge into FAL_TRACABILITY FT
      using (select   LOT.FAL_LOT_ID
                    , LOT.LOT_REFCOMPL
                    , LOT.LOT_VERSION_ORIGIN_NUM
                    , LOT.LOT_PLAN_NUMBER
                    , LOT.LOT_PLAN_VERSION
                    , LOT.GCO_GOOD_ID PT_GOOD_ID
                    , FLD.FAD_VERSION
                    , FLD.FAD_LOT_CHARACTERIZATION
                    , FLD.FAD_PIECE
                    , FLD.FAD_CHRONOLOGY
                    , FLD.FAD_STD_CHAR_1
                    , FLD.FAD_STD_CHAR_2
                    , FLD.FAD_STD_CHAR_3
                    , FLD.FAD_STD_CHAR_4
                    , FLD.FAD_STD_CHAR_5
                    , FFI.GCO_GOOD_ID CPT_GOOD_ID
                    , FFI.IN_VERSION
                    , FFI.IN_LOT
                    , FFI.IN_PIECE
                    , FFI.IN_CHRONOLOGY
                    , FFI.IN_STD_CHAR_1
                    , FFI.IN_STD_CHAR_2
                    , FFI.IN_STD_CHAR_3
                    , FFI.IN_STD_CHAR_4
                    , FFI.IN_STD_CHAR_5
                    , sum(LDL_QTY) LDL_QTY
                 from FAL_LOT_DETAIL_LINK FLDL
                    , FAL_FACTORY_IN FFI
                    , FAL_LOT_DETAIL FLD
                    , (select FAL_LOT_ID
                            , LOT_REFCOMPL
                            , LOT_VERSION_ORIGIN_NUM
                            , LOT_PLAN_NUMBER
                            , LOT_PLAN_VERSION
                            , GCO_GOOD_ID
                         from FAL_LOT
                        where FAL_LOT_ID = aFalLotId) LOT
                where FLDL.FAL_FACTORY_IN_ID = FFI.FAL_FACTORY_IN_ID
                  and FLD.FAL_LOT_DETAIL_ID = FLDL.FAL_LOT_DETAIL_ID
                  and FLD.FAL_LOT_ID = aFalLotId
                  and FAD_RECEPT_SELECT = 1
             group by LOT.FAL_LOT_ID
                    , LOT.LOT_REFCOMPL
                    , LOT.LOT_VERSION_ORIGIN_NUM
                    , LOT.LOT_PLAN_NUMBER
                    , LOT.LOT_PLAN_VERSION
                    , LOT.GCO_GOOD_ID
                    , FLD.FAD_VERSION
                    , FLD.FAD_LOT_CHARACTERIZATION
                    , FLD.FAD_PIECE
                    , FLD.FAD_CHRONOLOGY
                    , FLD.FAD_STD_CHAR_1
                    , FLD.FAD_STD_CHAR_2
                    , FLD.FAD_STD_CHAR_3
                    , FLD.FAD_STD_CHAR_4
                    , FLD.FAD_STD_CHAR_5
                    , FFI.GCO_GOOD_ID
                    , FFI.IN_VERSION
                    , FFI.IN_LOT
                    , FFI.IN_PIECE
                    , FFI.IN_CHRONOLOGY
                    , FFI.IN_STD_CHAR_1
                    , FFI.IN_STD_CHAR_2
                    , FFI.IN_STD_CHAR_3
                    , FFI.IN_STD_CHAR_4
                    , FFI.IN_STD_CHAR_5) SRC
      on (    FT.FAL_LOT_ID = SRC.FAL_LOT_ID
          and FT.GCO_GOOD_ID = SRC.PT_GOOD_ID
          and FT.GCO_GCO_GOOD_ID = SRC.CPT_GOOD_ID
          and nvl(FT.HIS_PT_VERSION, ' ') = nvl(SRC.FAD_VERSION, ' ')
          and nvl(FT.HIS_PT_LOT, ' ') = nvl(SRC.FAD_LOT_CHARACTERIZATION, ' ')
          and nvl(FT.HIS_PT_PIECE, ' ') = nvl(SRC.FAD_PIECE, ' ')
          and nvl(FT.HIS_CHRONOLOGY_PT, ' ') = nvl(SRC.FAD_CHRONOLOGY, ' ')
          and nvl(FT.HIS_PT_STD_CHAR_1, ' ') = nvl(SRC.FAD_STD_CHAR_1, ' ')
          and nvl(FT.HIS_PT_STD_CHAR_2, ' ') = nvl(SRC.FAD_STD_CHAR_2, ' ')
          and nvl(FT.HIS_PT_STD_CHAR_3, ' ') = nvl(SRC.FAD_STD_CHAR_3, ' ')
          and nvl(FT.HIS_PT_STD_CHAR_4, ' ') = nvl(SRC.FAD_STD_CHAR_4, ' ')
          and nvl(FT.HIS_PT_STD_CHAR_5, ' ') = nvl(SRC.FAD_STD_CHAR_5, ' ')
          and nvl(FT.HIS_CPT_VERSION, ' ') = nvl(SRC.IN_VERSION, ' ')
          and nvl(FT.HIS_CPT_LOT, ' ') = nvl(SRC.IN_LOT, ' ')
          and nvl(FT.HIS_CPT_PIECE, ' ') = nvl(SRC.IN_PIECE, ' ')
          and nvl(FT.HIS_CHRONOLOGY_CPT, ' ') = nvl(SRC.IN_CHRONOLOGY, ' ')
          and nvl(FT.HIS_CPT_STD_CHAR_1, ' ') = nvl(SRC.IN_STD_CHAR_1, ' ')
          and nvl(FT.HIS_CPT_STD_CHAR_2, ' ') = nvl(SRC.IN_STD_CHAR_2, ' ')
          and nvl(FT.HIS_CPT_STD_CHAR_3, ' ') = nvl(SRC.IN_STD_CHAR_3, ' ')
          and nvl(FT.HIS_CPT_STD_CHAR_4, ' ') = nvl(SRC.IN_STD_CHAR_4, ' ')
          and nvl(FT.HIS_CPT_STD_CHAR_5, ' ') = nvl(SRC.IN_STD_CHAR_5, ' ') )
      when matched then
        update
           set HIS_QTY = SRC.LDL_QTY, A_DATEMOD = sysdate, A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
      when not matched then
        insert(FAL_TRACABILITY_ID, FAL_LOT_ID, HIS_LOT_REFCOMPL, HIS_VERSION_ORIGIN_NUM, HIS_PLAN_NUMBER, HIS_PLAN_VERSION, GCO_GOOD_ID, HIS_PT_VERSION
             , HIS_PT_LOT, HIS_PT_PIECE, HIS_CHRONOLOGY_PT, HIS_PT_STD_CHAR_1, HIS_PT_STD_CHAR_2, HIS_PT_STD_CHAR_3, HIS_PT_STD_CHAR_4, HIS_PT_STD_CHAR_5
             , GCO_GCO_GOOD_ID, HIS_CPT_VERSION, HIS_CPT_LOT, HIS_CPT_PIECE, HIS_CHRONOLOGY_CPT, HIS_CPT_STD_CHAR_1, HIS_CPT_STD_CHAR_2, HIS_CPT_STD_CHAR_3
             , HIS_CPT_STD_CHAR_4, HIS_CPT_STD_CHAR_5, HIS_QTY, A_IDCRE, A_DATECRE)
        values(GetNewId, SRC.FAL_LOT_ID, SRC.LOT_REFCOMPL, SRC.LOT_VERSION_ORIGIN_NUM, SRC.LOT_PLAN_NUMBER, SRC.LOT_PLAN_VERSION, SRC.PT_GOOD_ID
             , SRC.FAD_VERSION, SRC.FAD_LOT_CHARACTERIZATION, SRC.FAD_PIECE, SRC.FAD_CHRONOLOGY, FAD_STD_CHAR_1, FAD_STD_CHAR_2, FAD_STD_CHAR_3, FAD_STD_CHAR_4
             , FAD_STD_CHAR_5, SRC.CPT_GOOD_ID, SRC.IN_VERSION, SRC.IN_LOT, SRC.IN_PIECE, SRC.IN_CHRONOLOGY, SRC.IN_STD_CHAR_1, SRC.IN_STD_CHAR_2
             , SRC.IN_STD_CHAR_3, SRC.IN_STD_CHAR_4, SRC.IN_STD_CHAR_5, SRC.LDL_QTY, PCS.PC_I_LIB_SESSION.GetUserIni, sysdate);
  end;

  /**
  * procedure pCheckValorization
  * Description
  *  En réception, détermine s'il faut déclencher la valorisation post-calculation en fonction de la demande de valorisation en fin de réception
  *  (configuration FAL_CALC_RECEPT), du type de lot et du mode de gestion du produit
  * @author CLE
  * @lastUpdate VJE
  * @param   iGoodId        Id du bien du lot
  * @param   iReceptionType Type de réception
  * @param   iCalcRecept    Mode de valorisation en fin de réception (1 = pas valorisation (hors sous-traitance d'achat), 2,3 = valorisation)
  * @param   iCFabType      Type de lot
  * @param   ioResult       Valeur de retour
  */
  procedure pCheckValorization(
    iGoodId        in     fal_lot.gco_good_id%type
  , iReceptionType in     integer
  , iCalcRecept    in     varchar2
  , iCFabType      in     FAL_LOT.C_FAB_TYPE%type
  , ioResult       in out integer
  )
  is
    lvCManagementMode GCO_GOOD.C_MANAGEMENT_MODE%type;
  begin
    -- Valorisation obligatoire en mode de gestion PRCS/PRC pour les lots de sous-traitance d'achat
    if     iCalcRecept = '1'
       and (iCFabType <> btSubcontract) then
      if iReceptionType = rtReject then
        ioResult  := rtOkDisplayValuationReject;
      else
        ioResult  := rtOkDisplayValuation;
      end if;
    else
      select max(C_MANAGEMENT_MODE)
        into lvCManagementMode
        from GCO_GOOD
       where GCO_GOOD_ID = iGoodId;

      if lvCManagementMode = mmStandardCalculatedCostPrice then
        if iReceptionType = rtReject then
          ioResult  := rtAskDisplayValuationReject;
        else
          ioResult  := rtAskDisplayValuation;
        end if;
      else
        if iReceptionType = rtReject then
          ioResult  := rtOkDisplayValuationReject;
        else
          ioResult  := rtOkDisplayValuation;
        end if;
      end if;
    end if;
  end;

  /**
  * function PreparePTReceptionStockMvts
  * Description
  *   Préparation des mouvements de stock du produit terminé à la réception
  * @author CLE
  * @param   aFalLotId       Id du lot
  * @param   aGcoGoodId      Id du produit terminé
  * @param   aQty            Qté en réception
  * @param   aStockId        Stock de destination
  * @param   aLocationId     Emplacement de destination
  * @param   aUnitPrice      Prix unitaire
  * @param   aDate           Date de réception
  * @param   ReceptionType   Type de réception (produit terminé, rebut)
  * @param   AnswerYesAllQuestions   Passe automatiquement ou non les messages
  * @param   aResult                 Valeur de retour
  * @return  ReceptedPositionID Positions PT réceptionnées.
  */
  function PreparePTReceptionStockMvts(
    aFalLotId                    fal_lot.fal_lot_id%type
  , aGcoGoodId                   fal_lot.gco_good_id%type
  , aQty                         fal_lot.lot_inprod_qty%type
  , aStockId                     fal_lot.stm_stock_id%type
  , aLocationId                  fal_lot.stm_location_id%type
  , aUnitPrice                   number
  , aDate                        fal_lot.lot_plan_end_dte%type
  , ReceptionType                integer
  , AnswerYesAllQuestions        integer
  , aResult               in out integer
  )
    return varchar2
  is
    cursor Cur_FAL_LOT_DETAIL
    is
      select GCO_GOOD_ID
           , FAD_RECEPT_INPROGRESS_QTY
           , GCO_CHARACTERIZATION_ID
           , GCO_GCO_CHARACTERIZATION_ID
           , GCO2_GCO_CHARACTERIZATION_ID
           , GCO3_GCO_CHARACTERIZATION_ID
           , GCO4_GCO_CHARACTERIZATION_ID
           , FAD_CHARACTERIZATION_VALUE_1
           , FAD_CHARACTERIZATION_VALUE_2
           , FAD_CHARACTERIZATION_VALUE_3
           , FAD_CHARACTERIZATION_VALUE_4
           , FAD_CHARACTERIZATION_VALUE_5
        from FAL_LOT_DETAIL
       where FAL_LOT_ID = aFalLotId
         and nvl(FAD_RECEPT_INPROGRESS_QTY, 0) > 0
         and FAD_RECEPT_SELECT = 1;

    UnitPrice               number;
    aPreparedStockMovements FAL_STOCK_MOVEMENT_FUNCTIONS.TPreparedStockMovements;
    aErrorCode              varchar2(255);
    aErrorMsg               varchar2(255);
    aReceptedPositionList   varchar2(32000);
    lbIsFabRcptComMvt       boolean                                              :=(aResult = rtOkValuationCompensation);
  begin
    aReceptedPositionList    := '';
    aPreparedStockMovements  := FAL_STOCK_MOVEMENT_FUNCTIONS.TPreparedStockMovements();
    UnitPrice                := aUnitPrice;

    if UnitPrice = -1 then
      UnitPrice  := GCO_LIB_PRICE.GetCostPriceWithManagementMode(iGCO_GOOD_ID => aGcoGoodId, iDateRef => aDate);
    end if;

    if     (UnitPrice = 0)
       and (AnswerYesAllQuestions = 0)
       and (    (    ReceptionType = rtReject
                 and aResult < rtOkStockMovementReject)
            or (    ReceptionType in(rtFinishedProduct, rtBatchAssembly)
                and aResult < rtOkStockMovementPT)
           ) then
      if ReceptionType = rtReject then
        aResult  := rtAskStockMovementReject;
      else
        aResult  := rtAskStockMovementPT;
      end if;
    else
      if ReceptionType = rtReject then
        aResult  := rtOkStockMovementReject;
      else
        aResult  := rtOkStockMovementPT;
      end if;
    end if;

    if aResult > 0 then
      if (    FAL_LIB_BATCH.useDetails(aFalLotId) = 1
          and FAL_TOOLS.AtLeastOneDetailLotExists(aFalLotId) ) then
        for CurFalLotDetail in Cur_FAL_LOT_DETAIL loop
          FAL_STOCK_MOVEMENT_FUNCTIONS.addPreparedStockMovements(aPreparedStockMovements     => aPreparedStockMovements
                                                               , aFAL_LOT_ID                 => aFalLotId
                                                               , aGCO_GOOD_ID                => CurFalLotDetail.GCO_GOOD_ID
                                                               , aSTM_STOCK_ID               => aStockId
                                                               , aSTM_LOCATION_ID            => aLocationId
                                                               , aOUT_QUANTITY               => CurFalLotDetail.FAD_RECEPT_INPROGRESS_QTY
                                                               , aLOM_PRICE                  => UnitPrice
                                                               , aOUT_DATE                   => nvl(aDate, sysdate)
                                                               , aMvtKind                    => case     (cCalcRecept <> '1')
                                                                                                     and (ReceptionType = rtReject)
                                                                   when true then FAL_STOCK_MOVEMENT_FUNCTIONS.mktReceptionRebut
                                                                   else case lbIsFabRcptComMvt
                                                                   when true then FAL_STOCK_MOVEMENT_FUNCTIONS.mktReceptionCompensation
                                                                   else FAL_STOCK_MOVEMENT_FUNCTIONS.mktReceptionProduitTermine
                                                                 end
                                                                 end
                                                               , aGCO_CHARACTERIZATION1_ID   => CurFalLotDetail.GCO_CHARACTERIZATION_ID
                                                               , aGCO_CHARACTERIZATION2_ID   => CurFalLotDetail.GCO_GCO_CHARACTERIZATION_ID
                                                               , aGCO_CHARACTERIZATION3_ID   => CurFalLotDetail.GCO2_GCO_CHARACTERIZATION_ID
                                                               , aGCO_CHARACTERIZATION4_ID   => CurFalLotDetail.GCO3_GCO_CHARACTERIZATION_ID
                                                               , aGCO_CHARACTERIZATION5_ID   => CurFalLotDetail.GCO4_GCO_CHARACTERIZATION_ID
                                                               , aCHARACT_VALUE1             => CurFalLotDetail.FAD_CHARACTERIZATION_VALUE_1
                                                               , aCHARACT_VALUE2             => CurFalLotDetail.FAD_CHARACTERIZATION_VALUE_2
                                                               , aCHARACT_VALUE3             => CurFalLotDetail.FAD_CHARACTERIZATION_VALUE_3
                                                               , aCHARACT_VALUE4             => CurFalLotDetail.FAD_CHARACTERIZATION_VALUE_4
                                                               , aCHARACT_VALUE5             => CurFalLotDetail.FAD_CHARACTERIZATION_VALUE_5
                                                                );
        end loop;
      else
        FAL_STOCK_MOVEMENT_FUNCTIONS.addPreparedStockMovements(aPreparedStockMovements   => aPreparedStockMovements
                                                             , aFAL_LOT_ID               => aFalLotId
                                                             , aGCO_GOOD_ID              => aGcoGoodId
                                                             , aSTM_STOCK_ID             => aStockId
                                                             , aSTM_LOCATION_ID          => aLocationId
                                                             , aOUT_QUANTITY             => aQty
                                                             , aLOM_PRICE                => UnitPrice
                                                             , aOUT_DATE                 => nvl(aDate, sysdate)
                                                             , aMvtKind                  => case     (cCalcRecept <> '1')
                                                                                                 and (ReceptionType = rtReject)
                                                                 when true then FAL_STOCK_MOVEMENT_FUNCTIONS.mktReceptionRebut
                                                                 else case lbIsFabRcptComMvt
                                                                 when true then FAL_STOCK_MOVEMENT_FUNCTIONS.mktReceptionCompensation
                                                                 else FAL_STOCK_MOVEMENT_FUNCTIONS.mktReceptionProduitTermine
                                                               end
                                                               end
                                                              );
      end if;

      -- Déclencher les mouvements de stock préalablement préparés
      FAL_STOCK_MOVEMENT_FUNCTIONS.ApplyPreparedStockMovements(aErrorCode                => aErrorCode
                                                             , aErrorMsg                 => aErrorMsg
                                                             , aReceptedPositionID       => aReceptedPositionList
                                                             , aPreparedStockMovements   => aPreparedStockMovements
                                                             , MvtsContext               => FAL_STOCK_MOVEMENT_FUNCTIONS.ctxDefault
                                                             , aFalHistoLotId            => COM_I_LIB_LIST_ID_TEMP.getGlobalVar('ID_FOR_BATCH_RECEPT_HISTO')
                                                              );
    end if;

    return aReceptedPositionList;
  end;

  /**
  * procedure GenerateTempComponents
  * Description
  *   Génération des composants temporaires à la réception
  * @author CLE
  * @param   aFalLotId           Id du lot
  * @param   aSessionId          Session oracle
  * @param   aContext            Contexte (réception, solde)
  * @param   aQty                Qté en réception
  * @param   ReturnCompoIsScrap  Les composants retournés sont par défaut des déchets
  * @param   ReceptionType       Type de réception (produit terminé, rebut)
  * @param   iStmStmStockId      Stock consommation des composants
  * @param   iStmStmLocationId   Emplacement consommation des composants
  */
  procedure GenerateTempComponents(
    aFalLotId             fal_lot.fal_lot_id%type
  , aSessionId            fal_lot_mat_link_tmp.lom_session%type
  , aContext              integer
  , aQty                  fal_lot.lot_inprod_qty%type default 0
  , ReturnCompoIsScrap    integer default 1
  , ReceptionType         integer default rtFinishedProduct
  , aCFabType             FAL_LOT.C_FAB_TYPE%type default 0
  , iLocationId        in number default null
  , iTrashLocationId   in number default null
  , iAutoCommit           integer
  )
  is
    lnReturnQty number := 0;
    lnTrashQty  number := 0;
  begin
    -- Génération des composants temporaires
    if iAutoCommit = 1 then
      FAL_LOT_MAT_LINK_TMP_FUNCTIONS.CreateComponents(aFalLotId       => aFalLotId
                                                    , aSessionId      => aSessionId
                                                    , aContext        => aContext
                                                    , aReceptionQty   => aQty
                                                    , ReceptionType   => ReceptionType
                                                     );
    else
      FAL_LOT_MAT_LINK_TMP_FCT.CreateComponents(aFalLotId       => aFalLotId
                                              , aSessionId      => aSessionId
                                              , aContext        => aContext
                                              , aReceptionQty   => aQty
                                              , ReceptionType   => ReceptionType
                                               );
    end if;

    if    (aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchBalance)
       or (     (aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtManufacturingReceipt)
           and (ReceptionType = rtDismantling) ) then
      if ReturnCompoIsScrap = 1 then
        lnTrashQty  := aQty;
      else
        lnReturnQty  := aQty;
      end if;
    end if;

    -- Génération des liens de réservation
    FAL_COMPONENT_LINK_FCT.GlobalComponentLinkGeneration(aFAL_LOT_ID          => aFalLotId
                                                       , aLOM_SESSION         => aSessionId
                                                       , aContext             => aContext
                                                       , ReturnCompoIsScrap   => ReturnCompoIsScrap
                                                       , ReceptionType        => ReceptionType
                                                       , aCFabType            => aCFabType
                                                       , aReturnQty           => lnReturnQty
                                                       , aTrashQty            => lnTrashQty
                                                       , iLocationId          => iLocationId
                                                       , iTrashLocationId     => iTrashLocationId
                                                       , iAutoCommit          => iAutoCommit
                                                        );
  end;

/**
  * procedure UpdateBatchErrorCode
  * Description
  *   Mise à jour du code erreur du lot en fin de réception
  * @author CLE
  * @param   aFalLotId               Id du lot
  * @param   aCodeRecept             Code erreur de réception
**/
  procedure UpdateBatchErrorCode(aFalLotId fal_lot.fal_lot_id%type, aCodeRecept integer)
  is
    CLotReceptError FAL_LOT.C_LOT_RECEPT_ERROR%type;
  begin
    if aCodeRecept >= 0 then
      CLotReceptError  := null;
    elsif aCodeRecept = rtErrBatchBusy then
      CLotReceptError  := '01';
    elsif aCodeRecept = rtErrStock then
      CLotReceptError  := '02';
    elsif(aCodeRecept = rtErrDate) then
      CLotReceptError  := '03';
    elsif    (aCodeRecept = rtErrTrackOpeBeforeRecept)
          or (aCodeRecept = rtErrTrackOpBeforeBatchBalance)
          or (aCodeRecept = rtAskTrackOpeOnReject)
          or (aCodeRecept = rtAskTrackOpeOnPT)
          or (aCodeRecept = rtAskTrackOpeOnDismount)
          or (aCodeRecept = rtAskTrackOpeOnBalance) then
      CLotReceptError  := '04';
    elsif(aCodeRecept = rtErrReceptRejectBeforeSupQty) then
      CLotReceptError  := '05';
    elsif(aCodeRecept = rtErrReceptRejectBeforeBalance) then
      CLotReceptError  := '06';
    elsif    (aCodeRecept = rtErrCompoWithTraceability)
          or (aCodeRecept = rtAskCompoWithTotTraceReject)
          or (aCodeRecept = rtAskCompoWithTotalTrace) then
      CLotReceptError  := '07';
    elsif    (aCodeRecept = rtAskDisplayConsumptDismount)
          or (aCodeRecept = rtAskDisplayConsumptReject)
          or (aCodeRecept = rtAskDisplayConsumpt)
          or (aCodeRecept = rtAskDisplayConsumptBalance) then
      CLotReceptError  := '08';
    elsif    (aCodeRecept = rtErrBatchDetails)
          or (aCodeRecept = rtAskDisplayCharactDismount)
          or (aCodeRecept = rtAskDisplayCharactReject)
          or (aCodeRecept = rtAskDisplayCharact) then
      CLotReceptError  := '09';
    elsif    (aCodeRecept = rtAskDisplayTraceReject)
          or (aCodeRecept = rtAskDisplayTrace) then
      CLotReceptError  := '10';
    elsif    (aCodeRecept = rtAskDisplayValuationReject)
          or (aCodeRecept = rtAskDisplayValuation) then
      CLotReceptError  := '11';
    elsif(aCodeRecept = rtErrComponentWeighing) then
      CLotReceptError  := '12';
    elsif(aCodeRecept = rtErrBalanceCurrentEleCost) then
      CLotReceptError  := '13';
    elsif(aCodeRecept = rtErrUnConfirmedDoc) then
      CLotReceptError  := '14';
    elsif(aCodeRecept = rtAskDisplayWeighReject) then
      CLotReceptError  := '15';
    elsif(aCodeRecept = rtAskDisplayWeigh) then
      CLotReceptError  := '16';
    elsif(aCodeRecept = rtAskDisplayConfirmBSTReject) then
      CLotReceptError  := '17';
    elsif(aCodeRecept = rtAskDisplayConfirmBST) then
      CLotReceptError  := '18';
    elsif(aCodeRecept = rtErrUnbalancedCST) then
      CLotReceptError  := '19';
    end if;

    update FAL_LOT
       set C_LOT_RECEPT_ERROR = CLotReceptError
     where FAL_LOT_ID = aFalLotId;
  end;

/**
  * procedure StartReception
  * Description
  *   Procédure principale de réception PT et rebut
  * @author CLE
  * @param   aFalLotId               Id du lot
  * @param   aCFabType               Type de lot
  * @param   aGcoGoodId              Id du produit terminé
  * @param   aQty                    Quantité en réception
  * @param   aStockId                Stock de destination
  * @param   aLocationId             Emplacement de destination
  * @param   aDate                   Date de réception
  * @param   ReceptionType           Type de réception (produit terminé, rebut)
  * @param   BatchBalance            Solde du lot ou non
  * @param   aSessionId              Session oracle
  * @param   AnswerYesAllQuestions   Passe automatiquement ou non les messages
  * @param   DisplayConsumption      Force ou non l'affichage de la consommation
  * @param   aUnitPrice              Prix unitaire (peut être envoyé par la post-calculation en réception)
  * @param   aFalOrderId             Id de l'ordre
  * @param   aResult                 Valeur de retour
  * @param   iStmStmStockId          Stock consommation des composants
  * @param   iStmStmLocationId       Emplacement consomation des composants
  * @param   ReturnCompoIsScrap      Détermine si les composants restants au solde ou au démontage sont par défaut retourné en déchet ou stock
  * @param   aCompoStockId           Stock de destination du retour composants au solde ou au démontage
  * @param   aCompoLocationId        Emplacement de destination du retour composants au solde ou au démontage
  * @param   aCompoRejectStockId     Stock de destination des déchets composants au solde ou au démontage
  * @param   aCompoRejectLocationId  Emplacement de destination des déchets composants au solde ou au démontage
  */
  procedure StartReception(
    aFalLotId                     fal_lot.fal_lot_id%type
  , aCFabType                     fal_lot.c_fab_type%type
  , aGcoGoodId                    fal_lot.gco_good_id%type
  , aQty                          fal_lot.lot_inprod_qty%type
  , aStockId                      fal_lot.stm_stock_id%type
  , aLocationId                   fal_lot.stm_location_id%type
  , aDate                         fal_lot.lot_plan_end_dte%type
  , ReceptionType                 integer
  , BatchBalance                  integer
  , aSessionId                    fal_lot_mat_link_tmp.lom_session%type
  , AnswerYesAllQuestions         integer
  , DisplayConsumption            integer
  , aUnitPrice                    number
  , aFalOrderId                   fal_lot.fal_order_id%type
  , aResult                in out integer
  , iStmStmStockId                number default 0
  , iStmStmLocationId             number default 0
  , iReturnCompoIsScrap           integer default 0
  , iCompoStockId                 number default null
  , iCompoLocationId              number default null
  , iCompoRejectStockId           number default null
  , iCompoRejectLocationId        number default null
  , iAutoCommit                   integer
  , iAutoInitCharact       in     integer
  )
  is
    aReceptedPositionList varchar2(32000);
    lvDicFabConditionId   varchar2(10);
  begin
    -- Récupération de la condition de fabrication
    begin
      select DIC_FAB_CONDITION_ID
        into lvDicFabConditionId
        from FAL_LOT
       where FAL_LOT_ID = aFalLotId;
    exception
      when no_data_found then
        lvDicFabConditionId  := null;
    end;

    -- Execution de la procédure individualisée avant réception
    if aResult > 0 then
      if    (    ReceptionType = rtFinishedProduct
             and aResult < rtOkExecExternalProcOnRecept)
         or (    ReceptionType = rtReject
             and aResult < rtOkExecExtProcOnRejectRecept) then
        ExecExternalProcBAUReception(iCallMode                => 'BEFORE'
                                   , iCEvenType               => (case
                                                                    when ReceptionType = rtFinishedProduct then etReception
                                                                    when ReceptionType = rtReject then etReceptionRejects
                                                                    when ReceptionType = rtBatchAssembly then etAssembly
                                                                    else ''
                                                                  end
                                                                 )
                                   , iFalLotId                => aFalLotId
                                   , iDismountQty             => null
                                   , iReceptQty               => (case
                                                                    when    ReceptionType = rtFinishedProduct
                                                                         or ReceptionType = rtBatchAssembly then aQty
                                                                    else null
                                                                  end
                                                                 )
                                   , iReceptRejectQty         => (case
                                                                    when ReceptionType = rtReject then aQty
                                                                    else null
                                                                  end)
                                   , iReturnCompoIsScrap      => iReturnCompoIsScrap
                                   , iDate                    => aDate
                                   , iCompoStockId            => iCompoStockId
                                   , iCompoLocationId         => iCompoLocationId
                                   , iCompoRejectStockId      => iCompoRejectStockId
                                   , iCompoRejectLocationId   => iCompoRejectLocationId
                                   , iDestStockId             => aStockId
                                   , iDestLocationId          => aLocationId
                                   , iBatchBalance            => BatchBalance
                                   , iUnitPrice               => aUnitPrice
                                   , iStmStmStockId           => iStmStmStockId
                                   , iStmStmLocationId        => iStmStmLocationId
                                    );

        if ReceptionType = rtFinishedProduct then
          aResult  := rtOkExecExternalProcOnRecept;
        else
          aResult  := rtOkExecExtProcOnRejectRecept;
        end if;
      end if;
    end if;

    if    (    ReceptionType = rtReject
           and aResult < rtOkCompoWithTraceabReject)
       or (    ReceptionType = rtFinishedProduct
           and aResult < rtOkCompoWithTraceabPT) then
      CheckPartCharacteristic(iCFabType        => aCFabType
                            , iLotID           => aFalLotId
                            , iGoodId          => aGcoGoodId
                            , iQty             => aQty
                            , iReceptionType   => ReceptionType
                            , ioResult         => aResult
                             );
    end if;

    if     (aResult > 0)
       and (    (    ReceptionType = rtReject
                 and aResult < rtOkCompoWithTotTraceReject)
            or (    ReceptionType in(rtFinishedProduct, rtBatchAssembly)
                and aResult < rtOkCompoWithTotalTrace)
           ) then
      CheckTraceability(iCFabType                => aCFabType
                      , iLotID                   => aFalLotId
                      , iQty                     => aQty
                      , iAnswerYesAllQuestions   => AnswerYesAllQuestions
                      , iReceptionType           => ReceptionType
                      , ioResult                 => aResult
                       );
    end if;

    if     (aResult > 0)
       and (    (    ReceptionType = rtReject
                 and aResult < rtOkDisplayCharactReject)
            or (    ReceptionType in(rtFinishedProduct, rtBatchAssembly)
                and aResult < rtOkDisplayCharact)
           ) then
      UpdateReceptFlagDetailLot(aFalLotId, aQty);
      -- Contrôle s'il faut afficher la forme de saisie des caractérisations du produit terminé
      CheckProductCharacteristic(aFalLotId, ReceptionType, aResult);

      -- Sélection automatique des détails lots en mode batch (réception en série ou réception auto)
      if     (AnswerYesAllQuestions = 1
              or iAutoInitCharact = 1)
         and aResult in(rtAskDisplayCharactReject, rtAskDisplayCharact) then
        SelectBatchDetailsForRecept(aFalLotId => aFalLotId, aFinishedProductQty => aQty, aRejectQty => aQty, aResult => aResult);
      end if;
    end if;

    -- Contrôle que les transferts de stock dans l'atelier soient confirmés pour la sous-traitance opératoire
    if     (aResult > 0)
       and (    (    ReceptionType = rtReject
                 and aResult < rtOkDisplayConfirmBSTReject)
            or (    ReceptionType = rtFinishedProduct
                and aResult < rtOkDisplayConfirmBST) )
       and (aCFabType <> btSubcontract) then
      CheckConfirmBST(aFalLotId, aCFabType, ReceptionType, aResult);
    end if;

    -- Génération des composants temporaires pour réception et contrôle s'il faut afficher la forme de consommation des composants
    if     (aResult > 0)
       and (    (    ReceptionType = rtReject
                 and aResult < rtOkDisplayConsumptReject)
            or (    ReceptionType in(rtFinishedProduct, rtBatchAssembly)
                and aResult < rtOkDisplayConsumpt)
           ) then
      GenerateTempComponents(aFalLotId       => aFalLotId
                           , aSessionId      => aSessionId
                           , aContext        => FAL_COMPONENT_LINK_FUNCTIONS.ctxtManufacturingReceipt
                           , aQty            => aQty
                           , ReceptionType   => ReceptionType
                           , aCFabType       => aCFabType
                           , iAutoCommit     => iAutoCommit
                            );
      CheckMissingComponents(aFalLotId, aSessionId, DisplayConsumption, ReceptionType, aResult);
    end if;

    -- Contrôle pesée
    if     (aResult > 0)
       and (    (    ReceptionType = rtReject
                 and aResult < rtOkDisplayWeighReject)
            or (    ReceptionType = rtFinishedProduct
                and aResult < rtOkDisplayWeigh) ) then
      CheckMissingWeigh(aFalLotId, lvDicFabConditionId, aGcoGoodId, aQty, ReceptionType, aResult);

      -- réception en série ou réception auto : blocage uniquement si pesée obligatoire
      if     (AnswerYesAllQuestions = 1)
         and aResult in(rtAskDisplayWeighReject, rtAskDisplayWeigh)
         and GCO_I_LIB_CDA_MANUFACTURE.isProductAskWeigh(aGcoGoodId, 1, lvDicFabConditionId) = 0 then
        aResult  := -aResult;   -- annule l'erreur car la pesée n'est pas obligatoire
      end if;
    end if;

    -- La forme des pesées a été affichée mais les pesées n'ont pas été réalisée alors que celles-ci sont obligatoires
    if     (   aResult = rtOkDisplayWeigh
            or aResult = rtOkDisplayWeighReject)
       and GCO_I_LIB_CDA_MANUFACTURE.isProductAskWeigh(aGcoGoodId, 1, lvDicFabConditionId) = 1
       and FAL_LIB_BATCH.isWeighingNeeded(aFalLotId, aQty) = 1 then
      aResult  := rtErrWeighMandatory;
    end if;

    if     (aResult > 0)
       and (    (    ReceptionType = rtReject
                 and aResult < rtOkDisplayTraceReject)
            or (    ReceptionType in(rtFinishedProduct, rtBatchAssembly)
                and aResult < rtOkDisplayTrace)
           ) then
      -- MAJ des liens composants lot pseudo selon les compos rattachés
      FAL_COMPONENT_FUNCTIONS.UpdateFalLotMatLinkafterOutput(aLOM_SESSION    => aSessionId
                                                           , aFAL_LOT_ID     => aFalLotId
                                                           , aContext        => FAL_COMPONENT_LINK_FUNCTIONS.ctxtManufacturingReceipt
                                                           , ReceptionType   => ReceptionType
                                                           , BatchBalance    => (case
                                                                                   when ReceptionType = rtBatchAssembly then 0
                                                                                   else BatchBalance
                                                                                 end)
                                                           , aReceptQty      => aQty
                                                            );
      -- Sortie des composants pris sur stock
      doComponentsIssue(aFalLotId       => aFalLotId
                      , aSessionId      => aSessionId
                      , aDate           => aDate
                      , aQty            => aQty
                      , ReceptionType   => ReceptionType
                      , BatchBalance    => (case
                                              when ReceptionType = rtBatchAssembly then 0
                                              else BatchBalance
                                            end)
                      , aResult         => aResult
                      , iCFabType       => aCFabType
                       );

      if aResult > 0 then
        -- Affichage de l'appairage
        CheckProductTraceability(aCFabType       => aCFabType
                               , aFalLotId       => aFalLotId
                               , aGcoGoodId      => aGcoGoodId
                               , aSessionId      => aSessionId
                               , ReceptionType   => ReceptionType
                               , aResult         => aResult
                                );
      end if;
    end if;

    if     (aResult > 0)
       and (    (    ReceptionType = rtReject
                 and aResult < rtOkDisplayValuationReject)
            or (    ReceptionType in(rtFinishedProduct, rtBatchAssembly)
                and aResult < rtOkDisplayValuation)
           ) then
      -- Mise à jour des liens composants d'après l'appairage utilisateur
      ReadjustAlignedComponents(aFalLotId       => aFalLotId
                              , aSessionId      => aSessionId
                              , aQty            => aQty
                              , ReceptionType   => ReceptionType
                              , BatchBalance    => (case
                                                      when ReceptionType = rtBatchAssembly then 0
                                                      else BatchBalance
                                                    end)
                              , iAutoCommit     => iAutoCommit
                               );

      -- Vérifie qu'aucun composant n'est en alerte (que les liens composants répondent bien aux besoins)
      if     FAL_LOT_MAT_LINK_TMP_FCT.ExistsTmpComponents(aFalLotId, aSessionId)
         and (MissingComponentsCount(aFalLotId, aSessionId) > 0) then
        raise_application_error(-20015, 'PCS - ' || excMissingComponentMsg);
      end if;

      -- Création de l'appairage pour les composants caractérisés autre que pièce ou défini par la configuration FAL_PAIRING_CHARACT
      if aCFabType <> btSubContract then
        CreateMissingAlignedComponent(aFalLotId);
      end if;

      -- Mise à jour entrée atelier
      UpdateFalFactoryIn(aFalLotId, aSessionId);
      -- Récupérer et stocker l'ID du future historique de lot pour la réception. Il ne peux pas être créé à
      -- ce stade, car la post-Calculation insère également un historique. Comme nous voulons lier le mouvement de sortie
      -- de sortie atelier des composants à l'historique de réception, nous devons utiliser ce mécanisme.
      COM_I_LIB_LIST_ID_TEMP.setGlobalVar('ID_FOR_BATCH_RECEPT_HISTO', GetNewId);
      -- Sortie atelier des composants
      doComponentsOutput(aFalLotId, aSessionId, ReceptionType, aDate);

      if aCFabType <> btAfterSales then
        -- Mise à jour de la date de péremption des détails réceptionnés
        UpdateExpiryDate(aFalLotId, aGcoGoodId);
        -- Création tracabilité ... (Pas de traçabilité pour les OF de type "SAV")
        CreateTraceability(aFalLotId);
        -- détermine s'il faut déclencher la valorisation post-calculation
        pCheckValorization(iGoodId => aGcoGoodId, iReceptionType => ReceptionType, iCalcRecept => cCalcRecept, iCFabType => aCFabType, ioResult => aResult);
      else
        if ReceptionType = rtReject then
          aResult  := rtOkDisplayValuationReject;
        else
          aResult  := rtOkDisplayValuation;
        end if;
      end if;
    end if;

    if     (aResult > 0)
       and (    (    ReceptionType = rtReject
                 and aResult < rtOkEndReject)
            or (    ReceptionType in(rtFinishedProduct, rtBatchAssembly)
                and aResult < rtOkEndReceptPT) ) then
      if aCFabType <> btAfterSales then
        -- Préparation des Mouvements de stock d'entrée en stock gestion des PT ...
        aReceptedPositionList  :=
              PreparePTReceptionStockMvts(aFalLotId, aGcoGoodId, aQty, aStockId, aLocationId, aUnitPrice, aDate, ReceptionType, AnswerYesAllQuestions, aResult);
      end if;

      if aResult > 0 then
        ManageBatchUpdates(aFalLotId             => aFalLotId
                         , aFalOrderId           => aFalOrderId
                         , aCFabType             => aCFabType
                         , ReceptionType         => ReceptionType
                         , aGcoGoodId            => aGcoGoodId
                         , aQty                  => aQty
                         , aContext              => FAL_COMPONENT_LINK_FUNCTIONS.ctxtManufacturingReceipt
                         , aReceptedPositionID   => aReceptedPositionList
                          );
        -- Création de l'historique du lot (Réception PT ou CPT)
        CreateBatchHistory(aFAL_LOT_ID      => aFalLotId
                         , ReceptQty        => aQty
                         , aContext         => FAL_COMPONENT_LINK_FUNCTIONS.ctxtManufacturingReceipt
                         , aReceptionType   => ReceptionType
                         , aFalHistoLotId   => COM_I_LIB_LIST_ID_TEMP.getGlobalVar('ID_FOR_BATCH_RECEPT_HISTO')
                          );
      end if;
    end if;

    if aResult > 0 then
      -- Execution de la procédure individualisée après réception
      ExecExternalProcBAUReception(iCallMode                => 'AFTER'
                                 , iCEvenType               => (case
                                                                  when ReceptionType = rtFinishedProduct then etReception
                                                                  when ReceptionType = rtReject then etReceptionRejects
                                                                  when ReceptionType = rtBatchAssembly then etAssembly
                                                                  else ''
                                                                end
                                                               )
                                 , iFalLotId                => aFalLotId
                                 , iDismountQty             => null
                                 , iReceptQty               => (case
                                                                  when    ReceptionType = rtFinishedProduct
                                                                       or ReceptionType = rtBatchAssembly then aQty
                                                                  else null
                                                                end)
                                 , iReceptRejectQty         => (case
                                                                  when ReceptionType = rtReject then aQty
                                                                  else null
                                                                end)
                                 , iReturnCompoIsScrap      => iReturnCompoIsScrap
                                 , iDate                    => aDate
                                 , iCompoStockId            => iCompoStockId
                                 , iCompoLocationId         => iCompoLocationId
                                 , iCompoRejectStockId      => iCompoRejectStockId
                                 , iCompoRejectLocationId   => iCompoRejectLocationId
                                 , iDestStockId             => aStockId
                                 , iDestLocationId          => aLocationId
                                 , iBatchBalance            => BatchBalance
                                 , iUnitPrice               => aUnitPrice
                                 , iStmStmStockId           => iStmStmStockId
                                 , iStmStmLocationId        => iStmStmLocationId
                                  );

      if ReceptionType = rtReject then
        aResult  := rtOkEndReject;
      else
        aResult  := rtOkEndReceptPT;
      end if;
    end if;
  end StartReception;

/**
  * procedure TestOperationForBatchBalance
  * Description
  *   Test l'état des opérations (et mise à jour si besoin) au moment de la réception en fonction
  *   de la configuration FAL_PROGRESS_TYPE
  * @author CLE
  * @param   aFalLotId                   Id du lot
  * @param   aQtyReception               Qté en réception
  * @param   AnswerYesAllQuestions       Passe automatiquement ou non les messages
  * @param   ReceptionType               Type de réception (produit terminé, rebut)
  * @param   aResult                     Valeur de retour
  */
  procedure TestOperationForBatchBalance(
    aFalLotId                    fal_lot.fal_lot_id%type
  , aQtyReception                number default 0
  , AnswerYesAllQuestions        integer
  , ReceptionType                integer default 0
  , aResult               in out integer
  )
  is
    cursor Cur_FalLot
    is
      select LOT_RELEASED_QTY
           , LOT_REJECT_RELEASED_QTY
           , LOT_DISMOUNTED_QTY
           , C_FAB_TYPE
           , LOT_PT_REJECT_QTY
           , LOT_CPT_REJECT_QTY
        from FAL_LOT
       where FAL_LOT_ID = aFalLotId;

    cursor Cur_FalTaskLink
    is
      select nvl(TAL_RELEASE_QTY, 0) TAL_RELEASE_QTY
           , nvl(TAL_R_METER, 0) TAL_R_METER
        from FAL_TASK_LINK
       where FAL_LOT_ID = aFalLotId
         and SCS_STEP_NUMBER = (select max(SCS_STEP_NUMBER)
                                  from FAL_TASK_LINK
                                 where C_OPERATION_TYPE = otPrinciple
                                   and FAL_LOT_ID = aFalLotId);

    curFalLot     Cur_FalLot%rowtype;
    TalReleaseQty FAL_TASK_LINK.TAL_RELEASE_QTY%type;
    TalRMeter     FAL_TASK_LINK.TAL_R_METER%type;
    Qty           fal_lot.lot_released_qty%type;
  begin
    open Cur_FalLot;

    fetch Cur_FalLot
     into CurFalLot;

    close Cur_FalLot;

    -- Force le mode 4 :  Pas de mise à jour automatique des temps et montant réalisés lors du solde du lot en réception avec les temps standards.
    if CurFalLot.C_FAB_TYPE = btSubcontract then
      cProgressType  := '4';
    end if;

    if cProgressType in('1', '2', '5', '6') then
      -- Recherche de la dernière opération principale
      open Cur_FalTaskLink;

      fetch Cur_FalTaskLink
       into TalReleaseQty
          , TalRMeter;

      /* La réception passe si :
         - Il n'y a pas d'opération
         - On réceptionne une quantité rebut <= à la quantité rebut PT déclarée sur l'OF
         - On démonte une quantité <= à la quantité rebut CPT déclarée sur l'OF
         - Il y a suffisamment de réalisé sur la dernière opération principale pour effectuer la réception
              - La réception PT ne peut pas prendre sur les rebut PT et CPT
              - La réception rebut et le démontage *peuvent* prendre sur des réaliséss bonnes */
      if     Cur_FalTaskLink%found
         and not(    ReceptionType = rtReject
                 and (aQtyReception <= CurFalLot.LOT_PT_REJECT_QTY) )
         and not(    ReceptionType = rtDismantling
                 and (aQtyReception <= CurFalLot.LOT_CPT_REJECT_QTY) )
         and (TalReleaseQty + TalRMeter - CurFalLot.LOT_PT_REJECT_QTY - CurFalLot.LOT_CPT_REJECT_QTY <
                                                   aQtyReception + CurFalLot.LOT_RELEASED_QTY + CurFalLot.LOT_REJECT_RELEASED_QTY + CurFalLot.LOT_DISMOUNTED_QTY
             ) then
        if cProgressType in('1', '5') then
          if aResult >= rtOkBeginBalance then
            aResult  := rtErrTrackOpBeforeBatchBalance;
          else
            aResult  := rtErrTrackOpeBeforeRecept;
          end if;
        elsif AnswerYesAllQuestions = 0 then
          -- cProgressType = 2 ou 6
          -- ERROR ASK : Les opérations de fabrication n''ont pas toutes été saisies pour la quantité réceptionnée.
          --             Voulez-vous poursuivre la réception ?
          if aResult >= rtOkBeginBalance then
            aResult  := rtAskTrackOpeOnBalance;
          elsif ReceptionType = rtReject then
            aResult  := rtAskTrackOpeOnReject;
          elsif ReceptionType = rtDismantling then
            aResult  := rtAskTrackOpeOnDismount;
          else
            aResult  := rtAskTrackOpeOnPT;
          end if;
        end if;
      end if;

      close Cur_FalTaskLink;
    elsif cProgressType = 3 then
      Qty  := CurFalLot.LOT_RELEASED_QTY + CurFalLot.LOT_REJECT_RELEASED_QTY + CurFalLot.LOT_DISMOUNTED_QTY + aQtyReception;

      update FAL_TASK_LINK
         set TAL_ACHIEVED_TSK = (Qty / SCS_QTY_REF_WORK) * SCS_WORK_TIME
           , TAL_RELEASE_QTY = Qty
           , TAL_ACHIEVED_AD_TSK = case
                                    when nvl(SCS_QTY_FIX_ADJUSTING, 0) = 0 then SCS_ADJUSTING_TIME
                                    else ceil(Qty / SCS_QTY_FIX_ADJUSTING) * SCS_ADJUSTING_TIME
                                  end
       where FAL_LOT_ID = aFalLotId;
    end if;

    if aResult > 0 then
      if aResult >= rtOkBeginBalance then
        aResult  := rtOkTestOpeOnBalance;
      elsif ReceptionType = rtReject then
        aResult  := rtOkTestOpeOnReject;
      elsif ReceptionType = rtDismantling then
        aResult  := rtOkTestOpeOnDismount;
      else
        aResult  := rtOkTestOpeOnPT;
      end if;
    end if;
  end;

  /**
  * procedure doStockMovementOnBalance
  * Description
  *    Effectue les mouvements de stock en solde et démontage
  * @author CLE
  * @param   aFalLotId               Id du lot
  * @param   aSessionId              Session Oracle
  * @param   aDate                   Date de réception
  * @param   OutOrigin               Type d'origine des sorties atelier
  */
  procedure doStockMovementOnBalance(
    aFalLotId  fal_lot.fal_lot_id%type
  , aSessionId fal_lot_mat_link_tmp.lom_session%type
  , aDate      fal_lot.lot_plan_end_dte%type
  , OutOrigin  integer
  )
  is
    aErrorCode      varchar2(255);
    aErrorMsg       varchar2(255);
    lLastHistoLotId FAL_HISTO_LOT.FAL_HISTO_LOT_ID%type;
  begin
    -- Récupération de l'id du dernier historique créé
    select max(FAL_HISTO_LOT_ID)
      into lLastHistoLotId
      from FAL_HISTO_LOT
     where FAL_LOT5_ID = aFalLotId;

    -- Modification ou suppression des appairages dépendant des entrées atelier démontées
    if OutOrigin = ooDismounting then
      FAL_LOT_DETAIL_FUNCTIONS.UpdateAlignementOnMvtComponent(aSessionId);
    end if;

    -- Préparation de la liste des mouvements de stock
    FAL_STOCK_MOVEMENT_FUNCTIONS.InitPreparedStockMovement;
    -- Création des sorties atelier de type retour
    FAL_COMPONENT_FUNCTIONS.CreateAllFactoryMovements(aFAL_LOT_ID              => aFalLotId
                                                    , aFCL_SESSION             => aSessionId
                                                    , aPreparedStockMovement   => FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements
                                                    , aOUT_DATE                => aDate
                                                    , aMovementKind            => FAL_STOCK_MOVEMENT_FUNCTIONS.mktRetourAtelierVersStock
                                                    , aC_OUT_ORIGINE           => OutOrigin
                                                     );
    -- Création des sorties atelier de type Déchet
    FAL_COMPONENT_FUNCTIONS.CreateAllFactoryMovements(aFAL_LOT_ID              => aFalLotId
                                                    , aFCL_SESSION             => aSessionId
                                                    , aPreparedStockMovement   => FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements
                                                    , aOUT_DATE                => aDate
                                                    , aMovementKind            => FAL_STOCK_MOVEMENT_FUNCTIONS.mktRetourAtelierVersDechet
                                                    , aC_OUT_ORIGINE           => OutOrigin
                                                     );
    -- Génération des mouvements de stock
    FAL_STOCK_MOVEMENT_FUNCTIONS.ApplyPreparedStockMovements(aErrorCode                => aErrorCode
                                                           , aErrorMsg                 => aErrorMsg
                                                           , aPreparedStockMovements   => FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements
                                                           , MvtsContext               => FAL_STOCK_MOVEMENT_FUNCTIONS.ctxDefault
                                                           , aFalHistoLotId            => lLastHistoLotId
                                                            );
  end;

  /**
  * procedure doDismount
  * Description
  *    Effectue démontage
  * @author CLE
  * @param   aFalLotId               Id du lot
  * @param   aGcoGoodId              Id du produit terminé
  * @param   aFalOrderId             Id de l'ordre
  * @param   aCFabType               Type de lot
  * @param   aSessionId              Session Oracle
  * @param   aQty                    Quantité à démonter
  * @param   ReturnCompoIsScrap      Détermine si les composants restants au solde ou au démontage sont par défaut retourné en déchet ou stock
  * @param   ManualAdaptation        Adaptation manuel ou non de la destination des composants lors du démontage ou solde
  * @param   AnswerYesAllQuestions   Passe automatiquement ou non les messages
  * @param   aDate                   Date de réception
  * @param   aCompoStockId           Stock de destination du retour composants au solde ou au démontage
  * @param   aCompoLocationId        Emplacement de destination du retour composants au solde ou au démontage
  * @param   aCompoRejectStockId     Stock de destination des déchets composants au solde ou au démontage
  * @param   aCompoRejectLocationId  Emplacement de destination des déchets composants au solde ou au démontage
  * @param   aBatchBalance           Solde
  * @param   aResult                 Valeur de retour
  */
  procedure doDismount(
    aFalLotId                     fal_lot.fal_lot_id%type
  , aGcoGoodId                    fal_lot.gco_good_id%type
  , aFalOrderId                   fal_lot.fal_order_id%type
  , aCFabType                     fal_lot.c_fab_type%type
  , aSessionId                    fal_lot_mat_link_tmp.lom_session%type
  , aQty                          fal_lot.lot_inprod_qty%type default 0
  , ReturnCompoIsScrap            integer default 1
  , ManualAdaptation              integer default 0
  , AnswerYesAllQuestions         integer default 0
  , aDate                         fal_lot.lot_plan_end_dte%type default sysdate
  , aCompoStockId                 fal_lot.stm_stock_id%type default null
  , aCompoLocationId              fal_lot.stm_location_id%type default null
  , aCompoRejectStockId           fal_lot.stm_stock_id%type default null
  , aCompoRejectLocationId        fal_lot.stm_location_id%type default null
  , aBatchBalance                 integer default 0
  , iAutoCommit                   integer
  , iAutoInitCharact       in     integer
  , aResult                in out integer
  )
  is
  begin
    -- Execution de la procédure individualisée avant démontage
    if     aResult > 0
       and aResult < rtOkExecExtProcOnDismount then
      ExecExternalProcBAUReception(iCallMode                => 'BEFORE'
                                 , iCEvenType               => etDismounting
                                 , iFalLotId                => aFalLotId
                                 , iDismountQty             => aQty
                                 , iReceptQty               => null
                                 , iReceptRejectQty         => null
                                 , iReturnCompoIsScrap      => ReturnCompoIsScrap
                                 , iDate                    => aDate
                                 , iCompoStockId            => aCompoStockId
                                 , iCompoLocationId         => aCompoLocationId
                                 , iCompoRejectStockId      => aCompoRejectStockId
                                 , iCompoRejectLocationId   => aCompoRejectLocationId
                                 , iDestStockId             => null
                                 , iDestLocationId          => null
                                 , iBatchBalance            => aBatchBalance
                                 , iUnitPrice               => null
                                 , iStmStmStockId           => null
                                 , iStmStmLocationId        => null
                                  );
      -- Création de l'historique du lot (démontage)
      CreateBatchHistory(aFAL_LOT_ID      => aFalLotId
                       , ReceptQty        => aQty
                       , aContext         => FAL_COMPONENT_LINK_FUNCTIONS.ctxtManufacturingReceipt
                       , aReceptionType   => rtDismantling
                        );
      aResult  := rtOkExecExtProcOnDismount;
    end if;

    if     (aResult > 0)
       and (aResult < rtOkDisplayConsumptDismount) then
      GenerateTempComponents(aFalLotId            => aFalLotId
                           , aSessionId           => aSessionId
                           , aContext             => FAL_COMPONENT_LINK_FUNCTIONS.ctxtManufacturingReceipt
                           , aQty                 => aQty
                           , ReceptionType        => rtDismantling
                           , ReturnCompoIsScrap   => ReturnCompoIsScrap
                           , aCFabType            => aCFabType
                           , iLocationId          => aCompoLocationId
                           , iTrashLocationId     => aCompoRejectLocationId
                           , iAutoCommit          => iAutoCommit
                            );
      -- On regarde s'il y a besoin d'afficher la boîte de dialogue d'ajustement manuel
      CheckMissingComponents(aFalLotId            => aFalLotId
                           , aSessionId           => aSessionId
                           , DisplayConsumption   => ManualAdaptation
                           , ReceptionType        => rtDismantling
                           , aResult              => aResult
                            );
    end if;

    if     (aResult > 0)
       and (aResult < rtOkDisplayCharactDismount) then
      if CharacteristicsExists(aFalLotId) then
        aResult  := rtAskDisplayCharactDismount;

        -- Sélection automatique des détails lots en mode batch (réception en série ou réception auto)
        if AnswerYesAllQuestions = 1
           or iAutoInitCharact = 1 then
          SelectBatchDetailsForRecept(aFalLotId => aFalLotId, aDismountedQty => aQty, aResult => aResult);
        end if;
      else
        aResult  := rtOkDisplayCharactDismount;
      end if;
    end if;

    if     (aResult > 0)
       and (aResult < rtOkEndDismount) then
      -- Mise à jour entrée atelier
      UpdateFalFactoryIn(aFalLotId, aSessionId);
      -- MAJ des liens composants lot pseudo selon les compos rattachés
      FAL_COMPONENT_FUNCTIONS.UpdateFalLotMatLinkafterOutput(aLOM_SESSION    => aSessionId
                                                           , aFAL_LOT_ID     => aFalLotId
                                                           , aContext        => FAL_COMPONENT_LINK_FUNCTIONS.ctxtManufacturingReceipt
                                                           , ReceptionType   => rtDismantling
                                                            );
      -- Préparation et génération des mouvements de stock
      doStockMovementOnBalance(aFalLotId => aFalLotId, aSessionId => aSessionId, aDate => aDate, OutOrigin => ooDismounting);
      ManageBatchUpdates(aFalLotId       => aFalLotId
                       , aFalOrderId     => aFalOrderId
                       , aCFabType       => aCFabType
                       , ReceptionType   => rtDismantling
                       , aGcoGoodId      => aGcoGoodId
                       , aQty            => aQty
                       , aContext        => FAL_COMPONENT_LINK_FUNCTIONS.ctxtManufacturingReceipt
                        );
      aResult  := rtOkEndDismount;

      -- Execution de la procédure individualisée après démontage
      if aResult > 0 then
        ExecExternalProcBAUReception(iCallMode                => 'AFTER'
                                   , iCEvenType               => etDismounting
                                   , iFalLotId                => aFalLotId
                                   , iDismountQty             => aQty
                                   , iReceptQty               => null
                                   , iReceptRejectQty         => null
                                   , iReturnCompoIsScrap      => ReturnCompoIsScrap
                                   , iDate                    => aDate
                                   , iCompoStockId            => aCompoStockId
                                   , iCompoLocationId         => aCompoLocationId
                                   , iCompoRejectStockId      => aCompoRejectStockId
                                   , iCompoRejectLocationId   => aCompoRejectLocationId
                                   , iDestStockId             => null
                                   , iDestLocationId          => null
                                   , iBatchBalance            => aBatchBalance
                                   , iUnitPrice               => null
                                   , iStmStmStockId           => null
                                   , iStmStmLocationId        => null
                                    );
      end if;
    end if;
  end;

  /**
  * procedure doBatchBalance
  * Description
  *    Effectue le solde du lot
  * @author CLE
  * @param   aFalLotId               Id du lot
  * @param   aGcoGoodId              Id du produit terminé
  * @param   aFalOrderId             Id de l'ordre
  * @param   aCFabType               Type de lot
  * @param   aSessionId              Session Oracle
  * @param   aDate                   Date de réception
  * @param   ManualAdaptation        Adaptation manuel ou non de la destination des composants lors du démontage ou solde
  * @param   ReturnCompoIsScrap      Détermine si les composants restants au solde ou au démontage sont par défaut retourné en déchet ou stock
  * @param   aCompoStockId           Stock de destination du retour composants au solde ou au démontage
  * @param   aCompoLocationId        Emplacement de destination du retour composants au solde ou au démontage
  * @param   aCompoRejectStockId     Stock de destination des déchets composants au solde ou au démontage
  * @param   aCompoRejectLocationId  Emplacement de destination des déchets composants au solde ou au démontage
  * @param   aResult                 Valeur de retour
  * @param   aReceptionType          Type de réception
  * @param   iStmStmStockId          Stock consommation des composants
  * @param   iStmStmLocationId       Emplacement consomation des composants
  */
  procedure doBatchBalance(
    aFalLotId                     fal_lot.fal_lot_id%type
  , aGcoGoodId                    fal_lot.gco_good_id%type
  , aFalOrderId                   fal_lot.fal_order_id%type
  , aCFabType                     fal_lot.c_fab_type%type
  , aSessionId                    fal_lot_mat_link_tmp.lom_session%type
  , aDate                         fal_lot.lot_plan_end_dte%type default sysdate
  , ManualAdaptation              integer default 0
  , ReturnCompoIsScrap            integer default 1
  , aCompoStockId                 fal_lot.stm_stock_id%type default null
  , aCompoLocationId              fal_lot.stm_location_id%type default null
  , aCompoRejectStockId           fal_lot.stm_stock_id%type default null
  , aCompoRejectLocationId        fal_lot.stm_location_id%type default null
  , aResult                in out integer
  , ReceptionType                 integer default rtFinishedProduct
  , iStmStmStockId                number default 0
  , iStmStmLocationId             number default 0
  , iAutoCommit                   integer
  )
  is
    SumInBalance fal_factory_in.in_balance%type;
  begin
    -- Exécution procédure avant solde du lot
    if     aResult > 0
       and (   ReceptionType = rtBatchAssembly
            or aResult < rtOkExecExternalProcOnBalance) then
      ExecExternalProcBAUReception(iCallMode                => 'BEFORE'
                                 , iCEvenType               => etBalanced
                                 , iFalLotId                => aFalLotId
                                 , iDismountQty             => null
                                 , iReceptQty               => null
                                 , iReceptRejectQty         => null
                                 , iReturnCompoIsScrap      => ReturnCompoIsScrap
                                 , iDate                    => aDate
                                 , iCompoStockId            => aCompoStockId
                                 , iCompoLocationId         => aCompoLocationId
                                 , iCompoRejectStockId      => aCompoRejectStockId
                                 , iCompoRejectLocationId   => aCompoRejectLocationId
                                 , iDestStockId             => null
                                 , iDestLocationId          => null
                                 , iBatchBalance            => 1
                                 , iUnitPrice               => null
                                 , iStmStmStockId           => iStmStmStockId
                                 , iStmStmLocationId        => iStmStmLocationId
                                  );
      -- Création de l'historique du lot (Solde)
      CreateBatchHistory(aFAL_LOT_ID => aFalLotId, aContext => FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchBalance);
      aResult  := rtOkExecExternalProcOnBalance;
    end if;

    -- Solde des ofs d'assemblage
    if ReceptionType = rtBatchAssembly then
      if aResult > 0 then
        aResult  := rtOkEndBalance;

        if PCS.PC_CONFIG.GETCONFIG('FAL_USE_ACCOUNTING') in('1', '2') then
          ManualAssemblyBatchBalance(aSessionId => aSessionId, aFalLotId => aFalLotId, aErrorCode => aResult, aDoReservation => 0, aDoCheck => 0);
        end if;
      end if;
    -- Solde of standards
    else
      if     (aResult > 0)
         and (aResult < rtOkDisplayConsumptBalance) then
        select nvl(sum(IN_BALANCE), 0)
          into SumInBalance
          from FAL_FACTORY_IN
         where FAL_LOT_ID = aFalLotId;

        if (SumInBalance > 0) then
          GenerateTempComponents(aFalLotId            => aFalLotId
                               , aSessionId           => aSessionId
                               , aContext             => FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchBalance
                               , ReturnCompoIsScrap   => ReturnCompoIsScrap
                               , aCFabType            => aCFabType
                               , iLocationId          => aCompoLocationId
                               , iTrashLocationId     => aCompoRejectLocationId
                               , iAutoCommit          => iAutoCommit
                                );

          -- On regarde s'il y a besoin d'afficher la boîte de dialogue d'ajustement manuel
          if ManualAdaptation = 1 then
            aResult  := rtAskDisplayConsumptBalance;
          end if;
        end if;

        if aResult > 0 then
          aResult  := rtOkDisplayConsumptBalance;
        end if;
      end if;

      if     (aResult > 0)
         and (aResult < rtOkEndBalance) then
        -- Mise à jour entrée atelier
        UpdateFalFactoryIn(aFalLotId, aSessionId);
        -- Préparation et génération des mouvements de stock
        doStockMovementOnBalance(aFalLotId => aFalLotId, aSessionId => aSessionId, aDate => aDate, OutOrigin => ooReception);
        -- MAJ des liens composants lot pseudo selon les compos rattachés
        FAL_COMPONENT_FUNCTIONS.UpdateFalLotMatLinkafterOutput(aLOM_SESSION   => aSessionId
                                                             , aFAL_LOT_ID    => aFalLotId
                                                             , aContext       => FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchBalance
                                                              );
        ManageBatchUpdates(aFalLotId       => aFalLotId
                         , aFalOrderId     => aFalOrderId
                         , aCFabType       => aCFabType
                         , ReceptionType   => 0
                         , aGcoGoodId      => aGcoGoodId
                         , aContext        => FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchBalance
                         , aDate           => aDate
                          );

        if PCS.PC_CONFIG.GETCONFIG('FAL_USE_ACCOUNTING') in('1', '2') then
          FAL_ACCOUNTING_FUNCTIONS.BalanceCurrentEleCost(aFAL_LOT_ID => aFalLotId);
        end if;

        aResult  := rtOkEndBalance;

        -- Exécution procédure Après solde du lot
        if aResult > 0 then
          ExecExternalProcBAUReception(iCallMode                => 'AFTER'
                                     , iCEvenType               => etBalanced
                                     , iFalLotId                => aFalLotId
                                     , iDismountQty             => null
                                     , iReceptQty               => null
                                     , iReceptRejectQty         => null
                                     , iReturnCompoIsScrap      => ReturnCompoIsScrap
                                     , iDate                    => aDate
                                     , iCompoStockId            => aCompoStockId
                                     , iCompoLocationId         => aCompoLocationId
                                     , iCompoRejectStockId      => aCompoRejectStockId
                                     , iCompoRejectLocationId   => aCompoRejectLocationId
                                     , iDestStockId             => null
                                     , iDestLocationId          => null
                                     , iBatchBalance            => 1
                                     , iUnitPrice               => null
                                     , iStmStmStockId           => iStmStmStockId
                                     , iStmStmLocationId        => iStmStmLocationId
                                      );
        end if;
      end if;
    end if;
  end doBatchBalance;

  /**
  * procedure Recept
  * Description
  *    Procédure d'appel d'une réception d'un lot
  * @author CLE
  * @param   aFalLotId               Id du lot
  * @param   aSessionId              Session Oracle
  * @param   aFinishedProductQty     Qté de réception du produit terminé
  * @param   aRejectQty              Qté rebut de réception
  * @param   aDismountedQty          Qté démontée
  * @param   aStockId                Stock de destination
  * @param   aLocationId             Emplacement de destination
  * @param   aRejectStockId          Stock de destination des rebuts
  * @param   aRejectLocationId       Emplacement de destination des rebuts
  * @param   aCompoStockId           Stock de destination du retour composants au solde ou au démontage
  * @param   aCompoLocationId        Emplacement de destination du retour composants au solde ou au démontage
  * @param   aCompoRejectStockId     Stock de destination des déchets composants au solde ou au démontage
  * @param   aCompoRejectLocationId  Emplacement de destination des déchets composants au solde ou au démontage
  * @param   aDate                   Date de réception
  * @param   BatchBalance            Solde du lot ou non
  * @param   AnswerYesAllQuestions   Passe automatiquement ou non les messages
  * @param   StopOnQuestion          Stop réception sur question
  * @param   DisplayConsumption      Force ou non l'affichage de la consommation
  * @param   aUnitPrice              Prix unitaire (peut être envoyé par la post-calculation en réception)
  * @param   ManualAdaptation        Adaptation manuel ou non de la destination des composants lors du démontage ou solde
  * @param   ReturnCompoIsScrap      Détermine si les composants restants au solde ou au démontage sont par défaut retourné en déchet ou stock
  * @param   ReceptionType           Type de réception
  * @param   iStmStmStockId          Stock consommation des composants
  * @param   iStmStmLocationId       Emplacement consomation des composants
  * @param   ioAutoInitCharact       Initialisation automatique si possible des caractérisations. Bacule à false si c'est impossible à faire en automatique.
  * @param   aResult                 Valeur de retour
  */
  procedure Recept(
    aFalLotId                     fal_lot.fal_lot_id%type
  , aSessionId                    fal_lot_mat_link_tmp.lom_session%type default DBMS_SESSION.unique_session_id
  , aFinishedProductQty           fal_lot.lot_inprod_qty%type default 0
  , aRejectQty                    fal_lot.lot_inprod_qty%type default 0
  , aDismountedQty                fal_lot.lot_inprod_qty%type default 0
  , aStockId                      fal_lot.stm_stock_id%type default null
  , aLocationId                   fal_lot.stm_location_id%type default null
  , aRejectStockId                fal_lot.stm_stock_id%type default null
  , aRejectLocationId             fal_lot.stm_location_id%type default null
  , aCompoStockId                 fal_lot.stm_stock_id%type default null
  , aCompoLocationId              fal_lot.stm_location_id%type default null
  , aCompoRejectStockId           fal_lot.stm_stock_id%type default null
  , aCompoRejectLocationId        fal_lot.stm_location_id%type default null
  , aDate                         fal_lot.lot_plan_end_dte%type default sysdate
  , BatchBalance                  integer default 0
  , AnswerYesAllQuestions         integer default 0
  , StopOnQuestion                integer default 0
  , DisplayConsumption            integer default 0
  , aUnitPrice                    number default -1
  , ManualAdaptation              integer default 0
  , ReturnCompoIsScrap            integer default 1
  , ReceptionType                 integer default rtFinishedProduct
  , aReleaseBatch                 integer default 0
  , iAutoCommit                   integer default 1
  , iStmStmStockId                number default 0
  , iStmStmLocationId             number default 0
  , ioAutoInitCharact      in out integer
  , aResult                in out integer
  )
  is
    cursor cur_FalLot
    is
      select nvl(C_FAB_TYPE, btManufacturing) C_FAB_TYPE
           , GCO_GOOD_ID
           , nvl(LOT_INPROD_QTY, 0) LOT_INPROD_QTY
           , nvl(LOT_PT_REJECT_QTY, 0) LOT_PT_REJECT_QTY
           , nvl(LOT_CPT_REJECT_QTY, 0) LOT_CPT_REJECT_QTY
           , nvl(LOT_RELEASED_QTY, 0) LOT_RELEASED_QTY
           , nvl(LOT_REJECT_RELEASED_QTY, 0) LOT_REJECT_RELEASED_QTY
           , nvl(LOT_ASKED_QTY, 0) LOT_ASKED_QTY
           , FAL_ORDER_ID
           , STM_STOCK_ID
           , STM_LOCATION_ID
           , (select PDT_STOCK_MANAGEMENT
                from GCO_PRODUCT
               where GCO_GOOD_ID = LOT.GCO_GOOD_ID) STOCK_MANAGEMENT
        from FAL_LOT LOT
       where FAL_LOT_ID = aFalLotId;

    curFalLot                   cur_FalLot%rowtype;
    lStockId                    fal_lot.stm_stock_id%type;
    lLocationId                 fal_lot.stm_location_id%type;
    nRejectStockId              fal_lot.stm_stock_id%type;
    nRejectLocationId           fal_lot.stm_location_id%type;
    lBatchBalance               number(1);
    lvProcedureAfterRecept      varchar2(4000);
    aReceptedPositionList       varchar2(32000);
    lValuationCompensationPrice STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type;
  begin
    nRejectStockId     := aRejectStockId;
    nRejectLocationId  := aRejectLocationId;

    -- Faire une réservation FAL_LOT1
    if aResult = rtOkStart then
      ReserveBatch(aFalLotId, aSessionId, aResult);
    end if;

    -- Recherche des informations du lot
    open cur_FalLot;

    fetch cur_FalLot
     into curFalLot;

    close cur_FalLot;

    if BatchBalance in(0, 1) then
      lBatchBalance  := BatchBalance;
    elsif(curFalLot.LOT_RELEASED_QTY + aFinishedProductQty >= curFalLot.LOT_ASKED_QTY) then
      lBatchBalance  := 1;
    else
      lBatchBalance  := 0;
    end if;

    -- Si les
    lStockId           := nvl(aStockId, curFalLot.STM_STOCK_ID);
    lLocationId        := nvl(aLocationId, curFalLot.STM_LOCATION_ID);

    if curFalLot.STOCK_MANAGEMENT = 0 then
      lStockId           := FAL_TOOLS.GetDefaultStock;
      nRejectStockId     := lStockId;
      lLocationId        := null;
      nRejectLocationId  := null;
    end if;

    -- Contrôle du stock et emplacement de stock
    if     (aResult > 0)
       and (aResult < rtOkStock) then
      CheckStockAndLocation(aFinishedProductQty, aRejectQty, curFalLot.STOCK_MANAGEMENT, lStockId, lLocationId, nRejectStockId, nRejectLocationId, aResult);
    end if;

    -- Contrôle de la date de réception
    if     (aResult > 0)
       and (aResult < rtOkDate) then
      CheckDate(aDate, aResult);
    end if;

    -- Contrôle des détails lot si l'on ne doit pas afficher la forme correspondante
    if     (aResult > 0)
       and (AnswerYesAllQuestions = 1
            or ioAutoInitCharact = 1)
       and (aResult < rtOkBatchDetails) then
      CheckBatchDetails(aFalLotId             => aFalLotId
                      , aCFabType             => curFalLot.C_FAB_TYPE
                      , aGcoGoodId            => curFalLot.GCO_GOOD_ID
                      , aFinishedProductQty   => nvl(aFinishedProductQty, 0)
                      , aRejectQty            => nvl(aRejectQty, 0)
                      , aDismountedQty        => nvl(aDismountedQty, 0)
                      , aResult               => aResult
                       );

      /* Si on n'est pas en mode batch et que l'initialisation automatique ne pourra pas avoir lieu, on ne passe pas en erreur mais on forcera l'affichage de sélection des
         carcatérisations (ioAutoInitCharact = 0) */
      if     aResult = rtErrBatchDetails
         and AnswerYesAllQuestions = 0
         and ioAutoInitCharact = 1 then
        aResult            := rtOkBatchDetails;
        ioAutoInitCharact  := 0;
      end if;
    end if;

    if     (aResult > 0)
       and (aResult < rtOkUnbalancedCST) then
      -- solde d'un lot comportant des op. externes dont les CST liées contiennent au moins une position de type bien liée à une op. externe non soldée.
      if     lBatchBalance = 1
         and curFalLot.C_FAB_TYPE <> btSubcontract
         and FAL_LIB_BATCH.hasExternalTask(iLotID => aFalLotId) = 1
         and FAL_LIB_BATCH.hasUnbalancedCstPos(iLotID => aFalLotId) = 1 then
        aResult  := rtErrUnbalancedCST;
      end if;
    end if;

    -- Début de la réception "Démontage"
    if     (aResult > 0)
       and (aResult < rtOkBeginDismount) then
      aResult  := rtOkBeginDismount;
    end if;

    if     (aResult > 0)
       and (aResult < rtOkEndDismount) then
      if nvl(aDismountedQty, 0) > 0 then
        if     (aResult < rtOkTestOpeOnDismount)
           and (   cProgressType in('5', '6')
                or lBatchBalance = 1) then
          TestOperationForBatchBalance(aFalLotId               => aFalLotId
                                     , aQtyReception           => nvl(aDismountedQty, 0)
                                     , AnswerYesAllQuestions   => AnswerYesAllQuestions
                                     , ReceptionType           => rtDismantling
                                     , aResult                 => aResult
                                      );
        end if;

        if aResult > 0 then
          doDismount(aFalLotId                => aFalLotId
                   , aGcoGoodId               => curFalLot.GCO_GOOD_ID
                   , aFalOrderId              => CurFalLot.FAL_ORDER_ID
                   , aCFabType                => curFalLot.C_FAB_TYPE
                   , aSessionId               => aSessionId
                   , aQty                     => aDismountedQty
                   , ReturnCompoIsScrap       => ReturnCompoIsScrap
                   , ManualAdaptation         => ManualAdaptation
                   , AnswerYesAllQuestions    => AnswerYesAllQuestions
                   , aDate                    => aDate
                   , aCompoStockId            => aCompoStockId
                   , aCompoLocationId         => aCompoLocationId
                   , aCompoRejectStockId      => aCompoRejectStockId
                   , aCompoRejectLocationId   => aCompoRejectLocationId
                   , aBatchBalance            => BatchBalance
                   , iAutoCommit              => iAutoCommit
                   , iAutoInitCharact         => ioAutoInitCharact
                   , aResult                  => aResult
                    );

          if aResult = rtOkEndDismount then
            -- Compta industrielle, génération des éléments de coût réalisé et en cours
            if PCS.PC_CONFIG.GETCONFIG('FAL_USE_ACCOUNTING') in('1', '2') then
              FAL_ACCOUNTING_FUNCTIONS.InsertRealizedWorkElementCost(aFalLotId, 0, 0, aDismountedQty);
            end if;

            -- Libération des composants provisoires
            if iAutoCommit = 1 then
              commit;
              FAL_LOT_MAT_LINK_TMP_FUNCTIONS.PurgeTemporaryTable(aFalLotId);
            else
              -- Appel direct de la fonction sans transaction autonome
              FAL_LOT_MAT_LINK_TMP_FCT.PurgeTemporaryTable(aFalLotId);
            end if;
          end if;
        end if;
      else
        aResult  := rtOkEndDismount;
      end if;
    end if;

    -- Début de la réception rebut
    if     (aResult > 0)
       and (aResult < rtOkBeginReject) then
      aResult  := rtOkBeginReject;
    end if;

    if     (aResult > 0)
       and (aResult < rtOkEndReject) then
      if nvl(aRejectQty, 0) > 0 then
        if     (aResult < rtOkTestOpeOnReject)
           and (   cProgressType in('5', '6')
                or lBatchBalance = 1)
           and (curFalLot.C_FAB_TYPE <> btSubcontract) then
          TestOperationForBatchBalance(aFalLotId               => aFalLotId
                                     , aQtyReception           => nvl(aRejectQty, 0)
                                     , AnswerYesAllQuestions   => AnswerYesAllQuestions
                                     , ReceptionType           => rtReject
                                     , aResult                 => aResult
                                      );
        end if;

        if aResult > 0 then
          StartReception(aFalLotId                => aFalLotId
                       , aCFabType                => curFalLot.C_FAB_TYPE
                       , aGcoGoodId               => curFalLot.GCO_GOOD_ID
                       , aQty                     => aRejectQty
                       , aStockId                 => nRejectStockId
                       , aLocationId              => nRejectLocationId
                       , aDate                    => aDate
                       , ReceptionType            => rtReject
                       , BatchBalance             => lBatchBalance
                       , aSessionId               => aSessionId
                       , AnswerYesAllQuestions    => AnswerYesAllQuestions
                       , DisplayConsumption       => DisplayConsumption
                       , aUnitPrice               => aUnitPrice
                       , aFalOrderId              => CurFalLot.FAL_ORDER_ID
                       , aResult                  => aResult
                       , iStmStmStockId           => iStmStmStockId
                       , iStmStmLocationId        => iStmStmLocationId
                       , iReturnCompoIsScrap      => ReturnCompoIsScrap
                       , iCompoStockId            => aCompoStockId
                       , iCompoLocationId         => aCompoLocationId
                       , iCompoRejectStockId      => aCompoRejectStockId
                       , iCompoRejectLocationId   => aCompoRejectLocationId
                       , iAutoCommit              => iAutoCommit
                       , iAutoInitCharact         => ioAutoInitCharact
                        );
        end if;

        if aResult = rtOkEndReject then
          -- Compta industrielle, génération des éléments de coût réalisé et en cours
          if PCS.PC_CONFIG.GETCONFIG('FAL_USE_ACCOUNTING') in('1', '2') then
            FAL_ACCOUNTING_FUNCTIONS.InsertRealizedWorkElementCost(aFalLotId, 0, aRejectQty, 0);
          end if;

          -- Libération des composants provisoires
          if iAutoCommit = 1 then
            commit;
            FAL_LOT_MAT_LINK_TMP_FUNCTIONS.PurgeTemporaryTable(aFalLotId);
          else
            FAL_LOT_MAT_LINK_TMP_FCT.PurgeTemporaryTable(aFalLotId);
          end if;
        end if;
      else
        aResult  := rtOkEndReject;
      end if;
    end if;

    -- Début de la réception PT
    if     (aResult > 0)
       and (aResult < rtOkBeginReceptPT) then
      aResult  := rtOkBeginReceptPT;
    end if;

    -- Mise à jour des informations du lot
    open cur_FalLot;

    fetch cur_FalLot
     into curFalLot;

    close cur_FalLot;

    -- Réception PT
    if     (aResult > 0)
       and (aResult < rtOkEndReceptPT) then
      if nvl(aFinishedProductQty, 0) > 0 then
        if ReceptionType = rtBatchAssembly then
          aResult  := greatest(aResult, rtOkReceptRejectBeforeSupQty);
        else
          if     (aResult < rtOkTestOpeOnPT)
             and (   cProgressType in('5', '6')
                  or lBatchBalance = 1)
             and (curFalLot.C_FAB_TYPE <> btSubcontract) then
            TestOperationForBatchBalance(aFalLotId               => aFalLotId
                                       , aQtyReception           => nvl(aFinishedProductQty, 0)
                                       , AnswerYesAllQuestions   => AnswerYesAllQuestions
                                       , ReceptionType           => rtFinishedProduct
                                       , aResult                 => aResult
                                        );
          end if;

          if     (aResult > 0)
             and (aResult < rtOkReceptRejectBeforeSupQty) then
            if     (aFinishedProductQty > curFalLot.LOT_INPROD_QTY)
               and (nvl(curFalLot.LOT_PT_REJECT_QTY, 0) + nvl(curFalLot.LOT_CPT_REJECT_QTY, 0) > 0) then
              -- ERROR : Veuillez réceptionner les rebuts avant de réceptionner des quantités supplémentaires aux prévisions
              aResult  := rtErrReceptRejectBeforeSupQty;
            else
              aResult  := rtOkReceptRejectBeforeSupQty;
            end if;
          end if;
        end if;

        if aResult > 0 then
          StartReception(aFalLotId                => aFalLotId
                       , aCFabType                => curFalLot.C_FAB_TYPE
                       , aGcoGoodId               => curFalLot.GCO_GOOD_ID
                       , aQty                     => aFinishedProductQty
                       , aStockId                 => lStockId
                       , aLocationId              => lLocationId
                       , aDate                    => aDate
                       , ReceptionType            => ReceptionType
                       , BatchBalance             => lBatchBalance
                       , aSessionId               => aSessionId
                       , AnswerYesAllQuestions    => AnswerYesAllQuestions
                       , DisplayConsumption       => DisplayConsumption
                       , aUnitPrice               => aUnitPrice
                       , aFalOrderId              => CurFalLot.FAL_ORDER_ID
                       , aResult                  => aResult
                       , iStmStmStockId           => iStmStmStockId
                       , iStmStmLocationId        => iStmStmLocationId
                       , iReturnCompoIsScrap      => ReturnCompoIsScrap
                       , iCompoStockId            => aCompoStockId
                       , iCompoLocationId         => aCompoLocationId
                       , iCompoRejectStockId      => aCompoRejectStockId
                       , iCompoRejectLocationId   => aCompoRejectLocationId
                       , iAutoCommit              => iAutoCommit
                       , iAutoInitCharact         => ioAutoInitCharact
                        );
        end if;

        if aResult = rtOkEndReceptPT then
          -- Compta industrielle, génération des éléments de coût réalisé et en cours
          if PCS.PC_CONFIG.GETCONFIG('FAL_USE_ACCOUNTING') in('1', '2') then
            FAL_ACCOUNTING_FUNCTIONS.InsertRealizedWorkElementCost(aFalLotId, aFinishedProductQty, 0, 0);
          end if;

          -- Libération des composants provisoires
          if iAutoCommit = 1 then
            commit;
            FAL_LOT_MAT_LINK_TMP_FUNCTIONS.PurgeTemporaryTable(aFalLotId);
          else
            FAL_LOT_MAT_LINK_TMP_FCT.PurgeTemporaryTable(aFalLotId);
          end if;
        end if;
      else
        aResult  := rtOkEndReceptPT;
      end if;
    end if;

    -- Compta industrielle, génération des éléments de coût réalisé et en cours
    if     (aResult > 0)
       and (aResult < rtOkUnConfirmedDoc)
       and (lBatchBalance = 1) then
      if PCS.PC_CONFIG.GETCONFIG('FAL_USE_ACCOUNTING') in('1', '2') then
        FAL_ACCOUNTING_FUNCTIONS.CheckCurrentEleCost(aFalLotId, aResult);
      end if;
    end if;

    -- Début du solde lot
    if     (aResult > 0)
       and (aResult < rtOkBeginBalance) then
      aResult  := rtOkBeginBalance;
    end if;

    -- Mise à jour des informations du lot
    open cur_FalLot;

    fetch cur_FalLot
     into curFalLot;

    close cur_FalLot;

    if     (aResult > 0)
       and (aResult < rtOkEndBalance) then
      if lBatchBalance = 1 then
        if ReceptionType = rtBatchAssembly then
          aResult  := rtOkTestOpeOnBalance;
        else
          if aResult < rtOkReceptRejectBeforeBalance then
            if nvl(curFalLot.LOT_PT_REJECT_QTY, 0) + nvl(curFalLot.LOT_CPT_REJECT_QTY, 0) > 0 then
              -- ERROR : Solde impossible, des rebuts doivent être réceptionnés
              aResult  := rtErrReceptRejectBeforeBalance;
            else
              aResult  := rtOkReceptRejectBeforeBalance;
            end if;
          end if;

          if     (aResult > 0)
             and (aResult < rtOkTestOpeOnBalance)
             and (curFalLot.C_FAB_TYPE <> btSubcontract) then
            TestOperationForBatchBalance(aFalLotId => aFalLotId, AnswerYesAllQuestions => AnswerYesAllQuestions, aResult => aResult);
          end if;
        end if;

        if aResult > 0 then
          doBatchBalance(aFalLotId
                       , curFalLot.GCO_GOOD_ID
                       , CurFalLot.FAL_ORDER_ID
                       , curFalLot.C_FAB_TYPE
                       , aSessionId
                       , aDate
                       , ManualAdaptation
                       , ReturnCompoIsScrap
                       , aCompoStockId
                       , aCompoLocationId
                       , aCompoRejectStockId
                       , aCompoRejectLocationId
                       , aResult
                       , ReceptionType
                       , iStmStmStockId      => iStmStmStockId
                       , iStmStmLocationId   => iStmStmLocationId
                       , iAutoCommit         => iAutoCommit
                        );
        end if;

        if aResult = rtOkEndBalance then
          -- Libération des composants provisoires
          if iAutoCommit = 1 then
            commit;
            FAL_LOT_MAT_LINK_TMP_FUNCTIONS.PurgeTemporaryTable(aFalLotId);
          else
            FAL_LOT_MAT_LINK_TMP_FCT.PurgeTemporaryTable(aFalLotId);
          end if;
        end if;
      else
        aResult  := rtOkEndBalance;
      end if;
    end if;

    if aResult > 0 then
      if CurFalLot.C_FAB_TYPE = btAfterSales then
        -- Appel d'une procédure "externe" pour les OF de type SAV
        ASA_MANUFACTURING_ORDER.UpdateRecordOnReception(aFalLotId);
      end if;
    end if;

    -- MAJ erreur en réception (Hors probl de réservation du lot)
    if aResult <> rtErrBatchBusy then
      UpdateBatchErrorCode(aFalLotId, aResult);
    end if;

    if    (aReleaseBatch = 1)
       or (     (StopOnQuestion = 1)
           and aResult in
                 (rtAskTrackOpeOnReject
                , rtAskTrackOpeOnPT
                , rtAskTrackOpeOnDismount
                , rtAskTrackOpeOnBalance
                , rtAskCompoWithTotTraceReject
                , rtAskCompoWithTotalTrace
                , rtAskDisplayConsumptReject
                , rtAskDisplayConsumpt
                , rtAskDisplayCharactReject
                , rtAskDisplayCharact
                , rtAskDisplayTraceReject
                , rtAskDisplayTrace
                , rtAskDisplayValuationReject
                , rtAskDisplayValuation
                , rtAskDisplayWeighReject
                , rtAskDisplayWeigh
                , rtAskDisplayConsumptBalance
                 )
          ) then
      -- Libération du lot
      FAL_BATCH_RESERVATION.ReleaseBatch(aFalLotId, aSessionId);
    end if;

    -- Appel de la procédure après réception défini dans la config
    -- FAL_PROCEDURE_PL_AFTER_RECEPT
    if     (aResult > 0)
       and (aResult < rtOkValuationCompensation) then
      lvProcedureAfterRecept  := PCS.PC_CONFIG.GetConfig('FAL_PROCEDURE_PL_AFTER_RECEPT');

      if lvProcedureAfterRecept is not null then
        execute immediate 'begin ' || lvProcedureAfterRecept || '(:FAL_LOT_ID); ' || 'end;'
                    using in aFalLotId;
      end if;
    end if;

    /* Si pas d'erreur, que le lots n'est pas un lot SAV ni sous-traitance achat et qu'il est soldé... */
    if     aResult > 0
       and (curFalLot.C_FAB_TYPE not in(btAfterSales) )
       and (lBatchBalance = 1) then
      /* Si le test du besoin de mouvement de compensation pas encore fait... */
      if (aResult < rtOkValuationCompensation) then
        /* ...Mise à jour des informations du lot */
        open cur_FalLot;

        fetch cur_FalLot
         into curFalLot;

        close cur_FalLot;

        /* ...Contrôle de la nécessesité d'un mouvement de compensation au solde du lot. La postcalculation étant en Delphi, on doit provoquer un retour. */
        pCheckValorization(iGoodId          => curFalLot.GCO_GOOD_ID
                         , iReceptionType   => rtReject
                         , iCalcRecept      => cCalcRecept
                         , iCFabType        => curFalLot.C_FAB_TYPE
                         , ioResult         => aResult
                          );

        /* Si les mouvements sont valorisés et tous effectués et que la compensation est activée... */
        if     (aResult = rtAskDisplayValuationReject)
           and pcs.PC_CONFIG.GetBooleanConfig('FAL_CALC_RECEPT_COMP', pcs.PC_I_LIB_SESSION.GetCompanyId, pcs.PC_I_LIB_SESSION.GetConliId)
           and (FAL_LIB_MOVEMENT.getReceivedMovementQty(iLotID => aFalLotId) =
                                                                       (curFalLot.LOT_RELEASED_QTY + curFalLot.LOT_REJECT_RELEASED_QTY   /* + LOT_DISMOUNTED_QTY*/
                                                                       )
               ) then
          /* ...Une Post-Calculation de l'ensemble du lot et nécessaire pour corriger les éventuelles erreur de prix de mouvement resultant
             par exemple d'un changement de taux atelier entre deux réceptions partielles. (cf. DEVPRD-11706)*/
          aResult  := rtAskValuationCompensation;
        else
          /* ...Sinon pas de Post-Calculation nécessaire */
          aResult  := rtValuationCompensationDone;
        end if;
      end if;

      /* Si compensation de mouvement pas encore effectuée... */
      if     aResult > 0
         and (aResult < rtValuationCompensationDone) then
        /*/!\ Afin de ne pas ajouter un énième paramètre supplémentaire au processus de réception et vu que la compensation
          /!\ des éventuels écarts de la valorisation se fait tout à la fin du processus, on s'est permis de mettre le coût
          /!\ total du lot dans le coût unitaire, sachant qu'on en tient compte de la même manière ici en PL.
          /!\ aUnitPrice représente donc ici à ce moment le coût total du lot calculé par la Post-Calculation du lot et non
          /!\ le prix unitaire. Il doit correspondre avec la somme des mouvements du lot. Si ce n'est pas le cas, on génère
          /!\ une mouvement de compensation. */
        if aUnitPrice <> FAL_LIB_MOVEMENT.getReceivedMovementPrice(iLotID => aFalLotId) then
          /* Calcul du prix du mouvement de compensation */
          lValuationCompensationPrice  := aUnitPrice - FAL_LIB_MOVEMENT.getReceivedMovementPrice(iLotID => aFalLotId);
          /* Préparation des Mouvements de stock d'entrée en stock gestion des PT ...*/
          aReceptedPositionList        :=
            PreparePTReceptionStockMvts(aFalLotId
                                      , curFalLot.GCO_GOOD_ID
                                      , 0
                                      , lStockId
                                      , lLocationId
                                      , lValuationCompensationPrice
                                      , aDate
                                      , rtFinishedProduct
                                      , AnswerYesAllQuestions
                                      , aResult
                                       );
        end if;

        /* Compensation Ok. */
        aResult  := rtValuationCompensationDone;
      end if;
    end if;

    if aResult > 0 then
      aResult  := rtOkFinished;
    end if;
  end Recept;

  /**
  * procedure AutoRecept
  * Description
  *    Procédure d'appel d'une réception d'un lot déclenchée à la fin d'un suivi opératoire.
  *    La réception est faite si les critères suivants sont remplis :
  *        - Le produit est en auto-récept
  *        - L'opération est la dernière principale du lot
  *        - Le lot n'a pas de caractérisation autre que 4 ou 5
  *        - La quantité max fabricable est supérieure à la quantité à réceptionner
  *        - Le lot n'a pas de détail de caractérisation avec une qté solde supérieure à 0
  *    On réceptionne d'abord la quantité passée en paramètre (quantité réalisée au suivi)
  *    S'il ne reste plus qu'à réceptionner les rebuts avant de solder le lot, on déclenche ce traitement
  *   (réception des rebuts déclarés sur le lot + solde).
  *   On ne réceptionne jamais les rebuts sinon sur le suivi (pour pouvoir rectifier le suivi si finalement,
  *   il s'avère que les pièces sont bonnes).
  * @author CLE
  * @param   aFalTaskLinkId          Id de l'opération déclenchant la réception
  * @param   aQty                    Qté de réception (quantité du suivi opératoire sur l'opération)
  * @param   aDate                   Date de réception
  * @param   aResult                 Valeur de retour
  * @param   aUnitPrice              Prix unitaire (issue de la valorisation en réception si besoin).
  */
  procedure AutoRecept(
    aFalTaskLinkId in     FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  , aQty           in     FAL_LOT.LOT_INPROD_QTY%type default 0
  , aDate          in     FAL_LOT.LOT_PLAN_END_DTE%type default sysdate
  , aSessionId     in     FAL_LOT_MAT_LINK_TMP.LOM_SESSION%type default null
  , aResult        out    integer
  )
  is
    vMsgResult varchar2(4000);
  begin
    AutoRecept(aFalTaskLinkId => aFalTaskLinkId, aQty => aQty, aDate => aDate, aSessionId => aSessionId, aResult => aResult, aMsgResult => vMsgResult);
  end AutoRecept;

  procedure AutoRecept(
    aFalTaskLinkId in     FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  , aQty           in     FAL_LOT.LOT_INPROD_QTY%type default 0
  , aDate          in     FAL_LOT.LOT_PLAN_END_DTE%type default sysdate
  , aSessionId     in     FAL_LOT_MAT_LINK_TMP.LOM_SESSION%type default null
  , aResult        out    integer
  , aMsgResult     out    varchar2
  )
  is
    vQtyToValorize FAL_TASK_LINK.TAL_RELEASE_QTY%type;
  begin
    savepoint spBeforeAutoRecept;

    begin
      aResult  := rtOkStart;

      while aResult in(rtOkStart, rtOkDisplayCharact, rtOkDisplayCharactReject) loop
        -- Réception automatique
        AutomaticBatchRecept(aFalTaskLinkId => aFalTaskLinkId, aQty => aQty, aSessionId => aSessionId, aResult => aResult, aQtyToValorize => vQtyToValorize);

        if aResult in(rtAskDisplayCharact, rtAskDisplayCharactReject) then
          -- AutomaticBatchRecept a déjà contrôlé le solde de détail lot
          aResult  := -aResult;
        end if;
      end loop;

      -- Valorisation impossible en PL/SQL tant que la post-calc n'a pas été migrée
      if aResult in(rtAskDisplayValuation, rtAskDisplayValuationReject, rtAskValuationCompensation) then
        aResult  := arNeedValorizationDisplay;
      end if;

      if aResult <> arReceptionOk then
        rollback to savepoint spBeforeAutoRecept;
      end if;
    exception
      when others then
        rollback to savepoint spBeforeAutoRecept;
        aResult  := arErrorReceptionCanceled;
    end;

    -- Message de retour
    case aResult
      when arReceptionOk then
        aMsgResult  := PCS.PC_FUNCTIONS.TranslateWord('Réception effectuée');
      when arTaskLinkNotFound then
        aMsgResult  := PCS.PC_FUNCTIONS.TranslateWord('Pas de réception : opération non trouvée');
      when arLotNotFound then
        aMsgResult  := PCS.PC_FUNCTIONS.TranslateWord('Pas de réception : lot non trouvé');
      when arCharact4or5 then
        aMsgResult  := PCS.PC_FUNCTIONS.TranslateWord('Pas de réception : le lot a des caractérisations de type autre que 4 ou 5');
      when arRlzedQtyLessThanMaxManufQty then
        aMsgResult  := PCS.PC_FUNCTIONS.TranslateWord('Pas de réception : la quantité réalisée est supérieure à la quantité max réceptionnable');
      when arSeveralCharactDetailWithQty then
        aMsgResult  :=
                  PCS.PC_FUNCTIONS.TranslateWord('Pas de réception : Le lot a plus d''un détails de caractérisation avec une quantité solde supérieure à zéro');
      when arCharDetailWithoutEnoughQty then
        aMsgResult  := PCS.PC_FUNCTIONS.TranslateWord('Pas de réception : Le lot a un détail de caractérisation avec une quantité solde insuffisante');
      when arIncorrectBatchDetails then
        aMsgResult  := PCS.PC_FUNCTIONS.TranslateWord('Pas de réception : les détails lot doivent être ajustés manuellement');
      when arErrorReceptionCanceled then
        aMsgResult  := PCS.PC_FUNCTIONS.TranslateWord('La réception a été annulée car une erreur est survenue lors du traitement.');
      when arNeedValorizationDisplay then
        aMsgResult  := PCS.PC_FUNCTIONS.TranslateWord('Pas de réception : le produit nécessite une valorisation en fin de réception');
      when arBatchBusy then
        aMsgResult  := PCS.PC_FUNCTIONS.TranslateWord('Pas de réception : le lot est cours de modification par un autre utilisateur');
      when arWeighMandatory then
        aMsgResult  := PCS.PC_FUNCTIONS.TranslateWord('Pas de réception : Pesée manquante');
      else
        if aResult not in(arProductNonAutoRecept, arNonLastOperation, arRealizedQtyLessOrEqualZero, arReceptionCanceled, arRejectReceptionCanceled) then
          aMsgResult  := PCS.PC_FUNCTIONS.TranslateWord('Réception automatique : erreur inconnue') || ' ' || aResult;
        end if;
    end case;
  end AutoRecept;

  /**
  * procedure AutomaticBatchRecept
  * Description
  *   Procédure appelée UNIQUEMENT depuis FAL_BATCH_FUNCTIONS.AutoRecept et
  *   TfctBatchAutoRecept.AutoRecept.
  *   Toute autre utilisation est PROSCRITE.
  */
  procedure AutomaticBatchRecept(
    aFalTaskLinkId in     FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  , aQty           in     FAL_LOT.LOT_INPROD_QTY%type default 0
  , aDate          in     FAL_LOT.LOT_PLAN_END_DTE%type default sysdate
  , aSessionId     in     FAL_LOT_MAT_LINK_TMP.LOM_SESSION%type default null
  , aResult        in out integer
  , aQtyToValorize out    FAL_TASK_LINK.TAL_RELEASE_QTY%type
  , aUnitPrice     in     number default -1
  )
  is
    cursor Cur_TalBatch
    is
      select LOT.FAL_LOT_ID
           , LOT.GCO_GOOD_ID
           , (select CMA_AUTO_RECEPT
                from GCO_COMPL_DATA_MANUFACTURE
               where GCO_GOOD_ID = LOT.GCO_GOOD_ID
                 and nvl(DIC_FAB_CONDITION_ID, 0) = nvl(LOT.DIC_FAB_CONDITION_ID, 0) ) CMA_AUTO_RECEPT
           , (select max(SCS_STEP_NUMBER) SCS_STEP_NUMBER
                from FAL_TASK_LINK
               where FAL_LOT_ID = LOT.FAL_LOT_ID
                 and C_OPERATION_TYPE = otPrinciple) LAST_STEP_NUMBER
           , FAL_COMPONENT_TOOLS.GetMinQteMaxReceptionnable_Lot(LOT.FAL_LOT_ID
                                                              , LOT.LOT_TOTAL_QTY
                                                                -(LOT.LOT_RELEASED_QTY + LOT.LOT_REJECT_RELEASED_QTY + LOT.LOT_DISMOUNTED_QTY)
                                                               ) LOT_MAX_RECEPT
           , TAL.SCS_STEP_NUMBER
           , nvl(LOT.LOT_INPROD_QTY, 0) LOT_INPROD_QTY
           , nvl(LOT.LOT_PT_REJECT_QTY, 0) LOT_PT_REJECT_QTY
           , nvl(LOT.LOT_CPT_REJECT_QTY, 0) LOT_CPT_REJECT_QTY
           , LOT.STM_STOCK_ID
           , LOT.STM_LOCATION_ID
           , nvl(TAL.TAL_END_REAL_DATE, sysdate) TAL_END_REAL_DATE
           , LOT.DIC_FAB_CONDITION_ID
        from FAL_TASK_LINK TAL
           , FAL_LOT LOT
       where LOT.FAL_LOT_ID(+) = TAL.FAL_LOT_ID
         and TAL.FAL_SCHEDULE_STEP_ID = aFalTaskLinkId;

    curTalBatch       Cur_TalBatch%rowtype;
    newLotInProdQty   FAL_LOT.LOT_INPROD_QTY%type;
    SessionId         FAL_LOT1.LT1_ORACLE_SESSION%type;
    vRejectStockId    FAL_LOT.STM_STOCK_ID%type;
    vRejectLocationId FAL_LOT.STM_LOCATION_ID%type;
    liAutoInitCharact integer                            := 0;
  begin
    if     aResult <> rtOkDisplayCharact
       and aResult <> rtOkDisplayCharactReject
       and aResult <> rtOkDisplayValuation
       and aResult <> rtOkDisplayValuationReject
       and aResult <> rtOkValuationCompensation then
      aResult  := rtOkStart;

      -- Recherche des paramètres
      open Cur_TalBatch;

      fetch Cur_TalBatch
       into curTalBatch;

      if Cur_TalBatch%notfound then
        -- Opération non trouvée
        aResult  := arTaskLinkNotFound;
      elsif curTalBatch.FAL_LOT_ID is null then
        -- Lot non trouvé
        aResult  := arLotNotFound;
      elsif nvl(curTalBatch.CMA_AUTO_RECEPT, 0) = 0 then
        -- Le produit n'est pas en auto-recept
        aResult  := arProductNonAutoRecept;
      elsif curTalBatch.SCS_STEP_NUMBER <> curTalBatch.LAST_STEP_NUMBER then
        -- Ce n'est pas la dernière opération principale
        aResult  := arNonLastOperation;
      elsif not(    (nvl(aQty, 0) > 0)
                or (     (curTalBatch.LOT_INPROD_QTY = 0)
                    and (curTalBatch.LOT_CPT_REJECT_QTY = 0) ) ) then
        -- Il n'y a aucune quantité à réceptionner
        aResult  := arRealizedQtyLessOrEqualZero;
      elsif     (nvl(aQty, 0) > 0)
            and (nvl(aQty, 0) > curTalBatch.LOT_MAX_RECEPT) then
        -- La quantité à réceptioner est supérieure à la quantité max réceptionable
        aResult  := arRlzedQtyLessThanMaxManufQty;
      elsif     GCO_I_LIB_CDA_MANUFACTURE.isProductAskWeigh(curTalBatch.GCO_GOOD_ID, 1, curTalBatch.DIC_FAB_CONDITION_ID) = 1
            and FAL_LIB_BATCH.isWeighingNeeded(curTalBatch.FAL_LOT_ID, aQty) = 1 then
        -- Pesée manquante
        aResult  := arWeighMandatory;
      end if;

      if aResult <> rtOkStart then
        return;
      end if;
    -- Retour après affichage valorisation ou demande d'affichage des caractérisations
    else
      -- Recherche des paramètres
      open Cur_TalBatch;

      fetch Cur_TalBatch
       into curTalBatch;
    end if;

    close Cur_TalBatch;

    SessionId  := nvl(aSessionId, DBMS_SESSION.unique_session_id);

    if     (    (aResult = rtOkStart)
            or (aResult = rtOkDisplayCharact)
            or (aResult = rtOkDisplayValuation) )
       and (nvl(aQty, 0) > 0) then
      aQtyToValorize  := aQty;
      -- Réception produit terminé
      Recept(aFalLotId               => curTalBatch.FAL_LOT_ID
           , aSessionId              => SessionId
           , aFinishedProductQty     => aQty
           , aStockId                => curTalBatch.STM_STOCK_ID
           , aLocationId             => curTalBatch.STM_LOCATION_ID
           , aDate                   => nvl(aDate, curTalBatch.TAL_END_REAL_DATE)
           , AnswerYesAllQuestions   => 1
           , aResult                 => aResult
           , aUnitPrice              => aUnitPrice
           , ioAutoInitCharact     => liAutoInitCharact
            );
    end if;

    -- Récupération de la nouvelle quantité en fabrication du lot (la réception ci-dessus l'a changée)
    select max(nvl(LOT_INPROD_QTY, 0) )
      into newLotInProdQty
      from FAL_LOT
     where FAL_LOT_ID = curTalBatch.FAL_LOT_ID;

    if     (aResult in(rtOkStart, rtOkDisplayCharactReject, rtOkDisplayValuationReject, rtOkValuationCompensation, rtValuationCompensationDone, rtOkFinished) )
       and (newLotInProdQty = 0)
       and (curTalBatch.LOT_CPT_REJECT_QTY = 0) then
      -- Réception du rebut avec solde du lot
      if aResult = rtOkFinished then
        aResult  := rtOkStart;
      end if;

      vRejectStockId     := FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_TRASH');
      vRejectLocationId  := FAL_TOOLS.GetConfig_LocationID('PPS_DefltLOCATION_TRASH', vRejectStockId);
      aQtyToValorize     := curTalBatch.LOT_PT_REJECT_QTY;
      Recept(aFalLotId                => curTalBatch.FAL_LOT_ID
           , aSessionId               => SessionId
           , aRejectQty               => curTalBatch.LOT_PT_REJECT_QTY
           , aRejectStockId           => vRejectStockId
           , aRejectLocationId        => vRejectLocationId
           , aCompoRejectStockId      => vRejectStockId
           , aCompoRejectLocationId   => vRejectLocationId
           , aDate                    => nvl(aDate, curTalBatch.TAL_END_REAL_DATE)
           , BatchBalance             => 1
           , ReturnCompoIsScrap       => 1
           , AnswerYesAllQuestions    => 1
           , ReceptionType            => rtReject
           , aResult                  => aResult
           , aUnitPrice               => aUnitPrice
           , ioAutoInitCharact        => liAutoInitCharact
            );
    end if;

    -- Lot en cours d'utilisation par un autre utilisateur
    if aResult = rtErrBatchBusy then
      aResult  := arBatchBusy;
    elsif aResult = rtErrBatchDetails then
      aResult  := arIncorrectBatchDetails;
    elsif aResult = rtOkFinished then
      aResult  := arReceptionOk;
    end if;
  exception
    when others then
      raise;
  end;

  /**
  * procedure : UpdateMaxManufacturableQty
  * Description : Mise à jour de la quantité max fabricable des lots sélectionnés
  *      ou du lot passé en paramètre s'il est non null
  *      Si le paramètre aReset = 1, on met à 0 cette quantité. Sinon on la calcule :
  *      - Qté max fab = plus petite quantité max fabricable des composants du lot
  *        arrondi à la valeur inférieure en fonction du nombre de décimale du PT
  *      - Si aucun composant sur le lot, = Qté lot totale du lot
  *
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aSessionId    Session Oracle
  * @param   aReset        Détermine s'il faut mettre à 0 la quantité max fabricable ou la calculer
  * @param   aFalLotId     Lot à mettre à jour (tous les lots1 sélectionnés si ce paramètre est null)
  * @param   aCaseReleaseCode Si = 1 à un calcul uniquement sur les composants en code décharge au lancement (ou dispo au lancement)
  *                           , sinon calcul sur tous lels composants générés pour l'of.
  */
  procedure UpdateMaxManufacturableQty(
    aSessionId       FAL_LOT1.LT1_ORACLE_SESSION%type default null
  , aReset           integer default 0
  , aFalLotId        FAL_LOT.FAL_LOT_ID%type default null
  , aCaseReleaseCode integer default 0
  )
  is
    pragma autonomous_transaction;
  begin
    if aReset = 1 then
      update FAL_LOT1 FL1
         set LT1_LOT_MAX_FAB_QTY = 0
       where LT1_ORACLE_SESSION = nvl(aSessionId, cSessionId)
         and (    (    aFalLotId is not null
                   and FAL_LOT_ID = aFalLotId)
              or (    aFalLotId is null
                  and LT1_SELECT = 1) );
    else
      update FAL_LOT1 FL1
         set LT1_LOT_MAX_FAB_QTY =
               decode( (select count(*)
                          from FAL_LOT_MAT_LINK_TMP
                         where LOM_SESSION = nvl(aSessionId, cSessionId)
                           and FAL_LOT_ID = FL1.FAL_LOT_ID
                           and nvl(LOM_UTIL_COEF, 0) <> 0
                           and (   aCaseReleaseCode = 0
                                or (    aCaseReleaseCode = 1
                                    and (   C_DISCHARGE_COM = '1'
                                         or C_DISCHARGE_COM = '5'
                                         or C_DISCHARGE_COM = '6') ) ) )
                    , 0, LT1_LOT_TOTAL_QTY
                    , FAL_TOOLS.ArrondiInferieur( (select min(LOM_MAX_RECEIPT_QTY)
                                                     from FAL_LOT_MAT_LINK_TMP
                                                    where LOM_SESSION = nvl(aSessionId, cSessionId)
                                                      and FAL_LOT_ID = FL1.FAL_LOT_ID
                                                      and nvl(LOM_UTIL_COEF, 0) <> 0
                                                      and (   aCaseReleaseCode = 0
                                                           or (    aCaseReleaseCode = 1
                                                               and (   C_DISCHARGE_COM = '1'
                                                                    or C_DISCHARGE_COM = '5'
                                                                    or C_DISCHARGE_COM = '6')
                                                              )
                                                          ) )
                                               , FL1.GCO_GOOD_ID
                                                )
                     )
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where LT1_ORACLE_SESSION = nvl(aSessionId, cSessionId)
         and (    (    aFalLotId is not null
                   and FAL_LOT_ID = aFalLotId)
              or (    aFalLotId is null
                  and LT1_SELECT = 1) );
    end if;

    commit;
  end;

  /**
  * Procedure DeleteBatch
  * Description : Suppression D'un lot de fabrication, ou d'un ensemble de lots
  *               sélectionnés dans la table FAL_LOT1 (Table du lancement).
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSessionID : SessionOracle
  * @param   aDeleteOrder : Suppression des ordres
  * @param   aDeleteProgram : Suppression des programmes
  * @return  aErrorMsg : Message d'erreur éventuel
  */
  procedure DeleteBatch(aSessionID in varchar2, aDeleteOrder in integer default 0, aDeleteProgram in integer default 0, aErrorMsg in out varchar2)
  is
    -- Ordres à mettre à jour.
    type TOrderId is table of number;

    TabOrderID           TOrderId                := TOrderId();

    -- Programmes à mettre à jour.
    type TProgramId is table of number;

    TabProgramID         TProgramId              := TProgramId();

    -- Curseur de sélection des OF à supprimer.
    cursor CrBatchDelete
    is
      select   LOT1.FAL_LOT_ID
             , LOT1.FAL_LOT1_ID
             , (select count(*)
                  from FAL_TRACABILITY TRA1
                 where TRA1.FAL_LOT_ID = LOT1.FAL_LOT_ID) TRACABILITY_USED
             , LOT.C_LOT_STATUS
             , LOT.FAL_ORDER_ID
             , LOT.FAL_JOB_PROGRAM_ID
             , nvl(LOT.C_FAB_TYPE, btManufacturing) C_FAB_TYPE
          from FAL_LOT1 LOT1
             , FAL_LOT LOT
         where LOT1.LT1_ORACLE_SESSION = aSessionID
           and nvl(LOT1.LT1_SELECT, 0) = 1
           and LOT1.FAL_LOT_ID = LOT.FAL_LOT_ID
      order by LOT.FAL_JOB_PROGRAM_ID
             , LOT.FAL_ORDER_ID;

    tplBatchDelete       CrBatchDelete%rowtype;
    blnUsedInTracability boolean;
    blnNotPlanned        boolean;
    BlnDoDelete          boolean;
    BlnSAVBatch          boolean;
    CurrentOrderId       number;
    CurrentProgramId     number;
  begin
    aErrorMsg             := '';
    blnUsedInTracability  := false;
    blnNotPlanned         := false;
    BlnDoDelete           := true;
    BlnSAVBatch           := false;
    CurrentOrderId        := 0;
    CurrentProgramId      := 0;

    -- Sélection des OF à Supprimer
    for tplBatchDelete in crBatchDelete loop
      -- Le lot est issu du SAV
      if tplBatchDelete.C_FAB_TYPE = btAfterSales then
        BlnSAVBatch  := true;
        BlnDoDelete  := false;
      end if;

      -- Le lot de fabrication est-il utilisé en tracabilité
      if nvl(tplBatchDelete.TRACABILITY_USED, 0) > 0 then
        blnUsedInTracability  := true;
        BlnDoDelete           := false;
      end if;

      -- Le lot de fabrication est-il en statut différent de planifié
      if tplBatchDelete.C_LOT_STATUS <> bsPlanned then
        blnNotPlanned  := true;
        BlnDoDelete    := false;
      end if;

      -- Si le lot peut être supprimé
      if BlnDoDelete then
        -- Suppression du FAL_LOT1 si existant
        if tplBatchDelete.FAL_LOT1_ID <> 0 then
          delete from FAL_LOT1
                where FAL_LOT1_ID = tplBatchDelete.FAL_LOT1_ID;
        end if;

        -- Suppression des détails lots (Ne sont pas supprimés en cascade)
        delete from FAL_LOT_DETAIL
              where FAL_LOT_ID = tplBatchDelete.FAL_LOT_ID;

        -- Mise à jour des réseaux.
        FAL_NETWORK.MiseAJourReseaux(tplBatchDelete.FAL_LOT_ID, FAL_NETWORK.ncSuppressionLot, null);

        -- Suppression de l'of
        delete from fal_lot
              where fal_lot_id = tplBatchDelete.FAL_LOT_ID;

        -- Stockage de l'ordre
        if CurrentOrderId <> tplBatchDelete.FAL_ORDER_ID then
          TabOrderID.extend;
          TabOrderID(TabOrderID.last)  := tplBatchDelete.FAL_ORDER_ID;
        end if;

        -- Stockage du programme
        if CurrentProgramId <> tplBatchDelete.FAL_JOB_PROGRAM_ID then
          TabProgramID.extend;
          TabProgramID(TabProgramID.last)  := tplBatchDelete.FAL_JOB_PROGRAM_ID;
        end if;

        CurrentOrderId    := tplBatchDelete.FAL_ORDER_ID;
        CurrentProgramId  := tplBatchDelete.FAL_JOB_PROGRAM_ID;
      end if;

      BlnDoDelete  := true;
    end loop;

    if TabOrderID.count > 0 then
      for i in TabOrderID.first .. TabOrderID.last loop
        -- Suppression éventuelle des ordres
        if aDeleteOrder = 1 then
          if not FAL_ORDER_FUNCTIONS.DeleteOrder(TabOrderID(i) ) then
            -- Mise à jour des ordres
            FAL_ORDER_FUNCTIONS.UpdateOrder(TabOrderID(i) );
          end if;
        else
          -- Mise à jour des ordres
          FAL_ORDER_FUNCTIONS.UpdateOrder(TabOrderID(i) );
        end if;
      end loop;
    end if;

    if TabProgramID.count > 0 then
      for i in TabProgramID.first .. TabProgramID.last loop
        -- Suppression éventuelle des programmes
        if aDeleteProgram = 1 then
          if not FAL_PROGRAM_FUNCTIONS.DeleteProgram(TabProgramID(i) ) then
            -- Mise à jour des programmes
            FAL_PROGRAM_FUNCTIONS.UpdateManufactureProgram(TabProgramID(i) );
          end if;
        else
          FAL_PROGRAM_FUNCTIONS.UpdateManufactureProgram(TabProgramID(i) );
        end if;
      end loop;
    end if;

    -- Retour message d'erreur
    if blnUsedInTracability then
      aErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('Certains lots n''ont pas été supprimés pour des raisons de tracabilité.');
    end if;

    if blnNotPlanned then
      if aErrorMsg = '' then
        aErrorMsg  := aErrorMsg || chr(13);
      end if;

      aErrorMsg  := aErrorMsg || PCS.PC_FUNCTIONS.TranslateWord('Certains lots, en statut différent de planifié n''ont pu être supprimés.');
    end if;

    if blnSAVBatch then
      if aErrorMsg = '' then
        aErrorMsg  := aErrorMsg || chr(13);
      end if;

      aErrorMsg  :=
        aErrorMsg ||
        PCS.PC_FUNCTIONS.TranslateWord('Certains lots, issus du SAV interne, ne peuvent être détruits que depuis les dossiers SAV leurs faisant référence');
    end if;
  end;

  /**
  * procedure : ManualAssemblyBatchBalance
  * Description : Procédure de solde des lots d'assemblage, quand ils n'ont été soldés
  *      de manière automatique, pour des raisons de non intégration de coûts en
  *      finance, nécessaire à la postcalculation des écarts pour la compta. indus.
  *      Le solde réalise :
  *         . Les contrôles inhérents à la comptabilité industrielle
  *         . La fermeture de l'of (modification de statut et calcul de la durée)
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSessionId    Session Oracle
  * @param   aFalLotId     Lot à Solder
  * @param   aErrorCode    Code Erreur
  * @param   aDoCheck      Effectuer les contrôles
  */
  procedure ManualAssemblyBatchBalance(
    aSessionId     in     FAL_LOT1.LT1_ORACLE_SESSION%type default null
  , aFalLotId      in     FAL_LOT.FAL_LOT_ID%type default null
  , aErrorCode     in out integer
  , aDoReservation in     integer default 1
  , aDoCheck       in     integer default 1
  )
  is
  begin
    -- Réservation de l'of
    if aDoReservation = 1 then
      ReserveBatch(aFalLotId => aFalLotId, aSessionId => aSessionId, aResult => aErrorCode);
    end if;

    -- Vérifications de la présence des éléments de coûts en ACI
    if     nvl(aErrorCode, 0) > 0
       and (aDoCheck = 1) then
      FAL_ACCOUNTING_FUNCTIONS.CheckCurrentEleCost(aFAL_LOT_ID => aFalLotId, aErrorMsg => aErrorCode);
    end if;

    -- Pas d'erreur détectée, solde du lot
    if nvl(aErrorCode, 0) > 0 then
      FAL_ACCOUNTING_FUNCTIONS.BalanceCurrentEleCost(aFAL_LOT_ID => aFalLotId);
      UpdateBatch(aFalLotId => aFalLotId, aContext => FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchBalance, aDate => sysdate);
      aErrorCode  := rtOkEndBalance;
    end if;

    -- Libération du lot
    if aDoReservation = 1 then
      FAL_BATCH_RESERVATION.ReleaseBatch(aFalLotId, aSessionId);
    end if;
  end ManualAssemblyBatchBalance;

  /**
  * Procedure UpdateBatchSchedulePlanning
  * Description : Mise à jour du code planification d'un lot de fabrication
  *
  * @author ECA
  * @lastUpdate
  * @public
  * @param   iFAL_LOT_ID : Session oracle
  * @param   iC_SCHEDULE_PLANNING : Code planification
  */
  procedure UpdateBatchSchedulePlanning(iFAL_LOT_ID in number, iC_SCHEDULE_PLANNING in varchar2)
  is
  begin
    update FAL_LOT
       set C_SCHEDULE_PLANNING = iC_SCHEDULE_PLANNING
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         , A_DATEMOD = sysdate
     where FAL_LOT_ID = iFAL_LOT_ID;
  end UpdateBatchSchedulePlanning;

  /**
  * Procedure BatchesReNumbering
  * Description : Re-numérotation des lots de fabrication
  *
  * @author ECA
  * @lastUpdate
  * @public
  */
  procedure BatchesReNumbering
  is
    MaxLot_REF       number;
    MaxOrd_REF       number;
    MaxJOP_REFERENCE number;
    vLotRefcompl     FAL_LOT.LOT_REFCOMPL%type;
    liMovtsUpdated   integer;
  begin
    savepoint StartOfModify;

    -- Teste la conformité des valeur de config avant la mise à jour pour éviter par exemple
    -- de formater un lot ayant la ref 123 et se retrouver avec un LOT_REFCOMPL = 12
    select max(JOP_REFERENCE)
      into MaxJop_Reference
      from FAL_JOB_PROGRAM;

    if MAXJOP_REFERENCE >= power(10, CfgFAL_PGM_REF_LENGTH) then
      raise_application_error(-20001
                            , PCS.PC_FUNCTIONS.TRANSLATEWORD('PCS - La valeur de la configuration FAL_PGM_REF_LENGTH n''est pas assez élevée,' ||
                                                             ' la plus grande valeur de référence de vos Programmes de fabrication étant ' ||
                                                             MAXJOP_REFERENCE
                                                            )
                             );
    end if;

    select max(JOP_REFERENCE)
      into MaxJop_Reference
      from FAL_JOB_PROGRAM_HIST;

    if MAXJOP_REFERENCE >= power(10, CfgFAL_PGM_REF_LENGTH) then
      raise_application_error(-20001
                            , PCS.PC_FUNCTIONS.TRANSLATEWORD('PCS - La valeur de la configuration FAL_PGM_REF_LENGTH n''est pas assez élevée,' ||
                                                             ' la plus grande valeur de référence de vos Programmes de fabrication archivés étant ' ||
                                                             MAXJOP_REFERENCE
                                                            )
                             );
    end if;

    select max(ORD_ref)
      into MaxOrd_Ref
      from FAL_ORDER;

    if MAXORD_REF >= power(10, CfgFAL_ORD_REF_LENGTH) then
      raise_application_error(-20001
                            , PCS.PC_FUNCTIONS.TRANSLATEWORD('PCS - La valeur de la configuration FAL_ORD_REF_LENGTH n''est pas assez élevée,' ||
                                                             ' la plus grande valeur de référence de vos Ordres de fabrication étant ' ||
                                                             MAXORD_REF
                                                            )
                             );
    end if;

    select max(ORD_ref)
      into MaxOrd_Ref
      from FAL_ORDER_HIST;

    if MAXORD_REF >= power(10, CfgFAL_ORD_REF_LENGTH) then
      raise_application_error(-20001
                            , PCS.PC_FUNCTIONS.TRANSLATEWORD('PCS - La valeur de la configuration FAL_ORD_REF_LENGTH n''est pas assez élevée,' ||
                                                             ' la plus grande valeur de référence de vos Ordres de fabrication archivés étant ' ||
                                                             MAXORD_REF
                                                            )
                             );
    end if;

    select max(LOT_REF)
      into MaxLot_Ref
      from FAL_LOT;

    if MAXLOT_REF >= power(10, CfgFAL_LOT_REF_LENGTH) then
      raise_application_error(-20001
                            , PCS.PC_FUNCTIONS.TRANSLATEWORD('PCS - La valeur de la configuration FAL_LOT_REF_LENGTH n''est pas assez élevée,' ||
                                                             ' la plus grande valeur de référence de vos Lots de fabrication étant ' ||
                                                             MAXLOT_REF
                                                            )
                             );
    end if;

    select max(LOT_ref)
      into MaxLot_Ref
      from FAL_LOT_HIST;

    if MAXLOT_REF >= power(10, CfgFAL_LOT_REF_LENGTH) then
      raise_application_error(-20001
                            , PCS.PC_FUNCTIONS.TRANSLATEWORD('PCS - La valeur de la configuration FAL_LOT_REF_LENGTH n''est pas assez élevée,' ||
                                                             ' la plus grande valeur de référence de vos Lots de fabrication archivés étant ' ||
                                                             MAXLOT_REF
                                                            )
                             );
    end if;

    -- Si ok, alors mise à jour des références de lots
    liMovtsUpdated  := 0;

    for tplBatches in (select FAL_LOT_ID
                         from FAL_LOT
                        where nvl(C_FAB_TYPE, btManufacturing) in(btManufacturing, btAssembly) ) loop
      vLotRefcompl  := FAL_TOOLS.Format_Lot_Generic(tplBatches.FAL_LOT_ID);

      -- Entrées atelier
      update FAL_FACTORY_IN FIN
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , IN_LOT_REFCOMPL = vLotRefcompl
       where FIN.FAL_LOT_ID = tplBatches.FAL_LOT_ID;

      -- Sorties atelier
      update FAL_FACTORY_OUT FOU
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , OUT_LOT_REFCOMPL = vLotRefcompl
       where FOU.FAL_LOT_ID = tplBatches.FAL_LOT_ID;

      -- Avancements
      update FAL_LOT_PROGRESS FLP
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , LOT_REFCOMPL = vLotRefcompl
       where FLP.FAL_LOT_ID = tplBatches.FAL_LOT_ID;

      -- Affectables
      update FAL_AFFECT FAF
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , LOT_REFCOMPL = vLotRefcompl
       where FAF.FAL_LOT_ID = tplBatches.FAL_LOT_ID;

      -- Lots réservés
      update FAL_LOT1 LOT1
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , LT1_LOT_REFCOMPL = vLotRefcompl
       where LOT1.FAL_LOT_ID = tplBatches.FAL_LOT_ID;

      -- détails lots
      update FAL_LOT_DETAIL FLD
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , FAD_LOT_REFCOMPL = vLotRefcompl
       where FLD.FAL_LOT_ID = tplBatches.FAL_LOT_ID;

      -- tracabilité
      update FAL_TRACABILITY FTR
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , HIS_LOT_REFCOMPL = vLotRefcompl
       where FTR.FAL_LOT_ID = tplBatches.FAL_LOT_ID;

      -- Réseaux appros
      update FAL_NETWORK_SUPPLY FNS
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , FAN_DESCRIPTION = vLotRefcompl
       where FNS.FAL_LOT_ID = tplBatches.FAL_LOT_ID;

      -- Réseaux besoins
      update FAL_NETWORK_NEED FNN
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , FAN_DESCRIPTION = vLotRefcompl
       where FNN.FAL_LOT_ID = tplBatches.FAL_LOT_ID;

      -- Mise à jour des mvts de stock, ne pas déplacer après la mise à jour des
      -- lots, car la recherche des mvts à mettre à jour se fait sur la base de
      -- l'ancienne référence complète
      if liMovtsUpdated = 0 then
        UpdateSMORefCompl;
        liMovtsUpdated  := 1;
      end if;

      -- Lots de fabrication
      update FAL_LOT LOT
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , LOT_REFCOMPL = vLotRefcompl
       where LOT.FAL_LOT_ID = tplBatches.FAL_LOT_ID;

      -- Historiques de lot
      update FAL_HISTO_LOT
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , HIS_REFCOMPL = vLotRefcompl
       where FAL_LOT5_ID = tplBatches.FAL_LOT_ID;

      -- Interrogation de maitrise
      update FAL_MAITRISE FMA
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , lot_refcompl = vLotRefcompl
       where FMA.FAL_LOT_ID = tplBatches.FAL_LOT_ID;

      -- Sorties code barre
      update FAL_OUT_COMPO_BARCODE FOC
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , FOC_lot_refcompl = vLotRefcompl
       where FOC.FAL_LOT_ID = tplBatches.FAL_LOT_ID;

      -- Pesées
      update FAL_WEIGH FWE
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , LOT_REFCOMPL = vLotRefcompl
       where FWE.FAL_LOT_ID = tplBatches.FAL_LOT_ID;

      -- Pesées historiées
      update FAL_WEIGH_HIST FWE
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , LOT_REFCOMPL = vLotRefcompl
       where FWE.FAL_LOT_ID = tplBatches.FAL_LOT_ID;
    end loop;

    -- Mise à jour des références de lots archivés
    liMovtsUpdated  := 0;

    for tplBatches in (select FAL_LOT_HIST_ID
                         from FAL_LOT_HIST
                        where nvl(C_FAB_TYPE, btManufacturing) in(btManufacturing, btAssembly) ) loop
      vLotRefcompl  := FAL_TOOLS.Format_lot_hist_generic(tplBatches.FAL_LOT_HIST_ID);

      -- Lot de fabrication archivés
      update FAL_LOT_HIST FLH
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , lot_refcompl = vLotRefcompl
       where FLH.FAL_LOT_HIST_ID = tplBatches.FAL_LOT_HIST_ID;

      -- Entrées atelier archivées
      update FAL_FACTORY_IN_HIST FFH
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , IN_LOT_REFCOMPL = vLotRefcompl
       where FFH.FAL_LOT_HIST_ID = tplBatches.FAL_LOT_HIST_ID;

      -- Sorties atelier archivées
      update FAL_FACTORY_OUT_HIST FFH
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , OUT_LOT_REFCOMPL = vLotRefcompl
       where FFH.FAL_LOT_HIST_ID = tplBatches.FAL_LOT_HIST_ID;

      -- avancement archivés
      update FAL_LOT_PROGRESS_HIST FLH
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , LOT_REFCOMPL = vLotRefcompl
       where FLH.FAL_LOT_HIST_ID = tplBatches.FAL_LOT_HIST_ID;

      -- Affectables archivés
      update FAL_AFFECT_HIST FAH
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , LOT_REFCOMPL = vLotRefcompl
       where FAH.FAL_LOT_HIST_ID = tplBatches.FAL_LOT_HIST_ID;

      -- historiques archivés
      update FAL_HISTO_LOT_HIST
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , HIS_REFCOMPL = vLotRefCompl
       where FAL_LOT_HIST5_ID = tplBatches.FAL_LOT_HIST_ID;

      -- Pesées historiées
      update FAL_WEIGH_HIST FWH
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , LOT_REFCOMPL_HIST = vLotRefCompl
       where FWH.FAL_LOT_HIST_ID = tplBatches.FAL_LOT_HIST_ID;

      -- Pesées
      update FAL_WEIGH FWH
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , LOT_REFCOMPL_HIST = vLotRefCompl
       where FWH.FAL_LOT_HIST_ID = tplBatches.FAL_LOT_HIST_ID;
    end loop;
  end;

  /**
  * Procedure DeleteNullReceptPositions
  * Description : Suppression des positions de stock null, après une réception
  *   abortée - Permet de régler le problème des stm_element_number_id n'existant
  *   plus (Rollback), sur des positions à null
  *
  * @author ECA
  * @lastUpdate
  * @public
  */
  procedure DeleteNullReceptPositions(iGcoGoodId in number)
  is
  begin
    for tplNullReceptPosition in (select SPO.STM_STOCK_POSITION_ID
                                    from STM_STOCK_POSITION SPO
                                   where SPO.SPO_STOCK_QUANTITY = 0
                                     and SPO.SPO_ASSIGN_QUANTITY = 0
                                     and SPO.SPO_PROVISORY_OUTPUT = 0
                                     and SPO.SPO_PROVISORY_INPUT = 0
                                     and SPO.SPO_AVAILABLE_QUANTITY = 0
                                     and SPO.SPO_ALTERNATIV_QUANTITY_1 = 0
                                     and SPO.SPO_ALTERNATIV_QUANTITY_2 = 0
                                     and SPO.SPO_ALTERNATIV_QUANTITY_3 = 0
                                     and SPO.GCO_GOOD_ID = iGcoGoodId) loop
      STM_PRC_STOCK_POSITION.DeleteNullPosition(tplNullReceptPosition.STM_STOCK_POSITION_ID);
    end loop;
  end DeleteNullReceptPositions;

    /**
  * Procedure UpdateReceptPositions
  * Description : Mise à jour des positions de stock null, après une réception
  *   abortée - Permet de régler le problème des stm_element_number_id n'existant
  *   plus (Rollback)
  *
  * @author AGA
  * @lastUpdate
  * @public
  */
  procedure UpdateReceptPositions(iGcoGoodId in number)
  is
    lEleNum1 STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    lEleNum2 STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    lEleNum3 STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
  begin
    for tplReceptPosition in (select STM_STOCK_POSITION_ID
                                   , GCO_CHARACTERIZATION_ID
                                   , GCO_GCO_CHARACTERIZATION_ID
                                   , GCO2_GCO_CHARACTERIZATION_ID
                                   , GCO3_GCO_CHARACTERIZATION_ID
                                   , GCO4_GCO_CHARACTERIZATION_ID
                                   , SPO_CHARACTERIZATION_VALUE_1
                                   , SPO_CHARACTERIZATION_VALUE_2
                                   , SPO_CHARACTERIZATION_VALUE_3
                                   , SPO_CHARACTERIZATION_VALUE_4
                                   , SPO_CHARACTERIZATION_VALUE_5
                                from STM_STOCK_POSITION A
                               where (GCO_GOOD_ID = iGcoGoodId)
                                 and (    (    A.STM_ELEMENT_NUMBER_ID is not null
                                           and not exists(select STM_ELEMENT_NUMBER_ID
                                                            from STM_ELEMENT_NUMBER B
                                                           where B.STM_ELEMENT_NUMBER_ID = A.STM_ELEMENT_NUMBER_ID) )
                                      or (    A.STM_STM_ELEMENT_NUMBER_ID is not null
                                          and not exists(select STM_ELEMENT_NUMBER_ID
                                                           from STM_ELEMENT_NUMBER B
                                                          where B.STM_ELEMENT_NUMBER_ID = A.STM_STM_ELEMENT_NUMBER_ID) )
                                      or (    A.STM2_STM_ELEMENT_NUMBER_ID is not null
                                          and not exists(select STM_ELEMENT_NUMBER_ID
                                                           from STM_ELEMENT_NUMBER B
                                                          where B.STM_ELEMENT_NUMBER_ID = A.STM2_STM_ELEMENT_NUMBER_ID)
                                         )
                                     ) ) loop
      GCO_LIB_CHARACTERIZATION.convertCharIdToElementNumber(iGcoGoodId
                                                          , tplReceptPosition.GCO_CHARACTERIZATION_ID
                                                          , tplReceptPosition.GCO_GCO_CHARACTERIZATION_ID
                                                          , tplReceptPosition.GCO2_GCO_CHARACTERIZATION_ID
                                                          , tplReceptPosition.GCO3_GCO_CHARACTERIZATION_ID
                                                          , tplReceptPosition.GCO4_GCO_CHARACTERIZATION_ID
                                                          , tplReceptPosition.SPO_CHARACTERIZATION_VALUE_1
                                                          , tplReceptPosition.SPO_CHARACTERIZATION_VALUE_2
                                                          , tplReceptPosition.SPO_CHARACTERIZATION_VALUE_3
                                                          , tplReceptPosition.SPO_CHARACTERIZATION_VALUE_4
                                                          , tplReceptPosition.SPO_CHARACTERIZATION_VALUE_5
                                                          , lEleNum1
                                                          , lEleNum2
                                                          , lEleNum3
                                                           );

      update STM_STOCK_POSITION
         set STM_ELEMENT_NUMBER_ID = lEleNum1
           , STM_STM_ELEMENT_NUMBER_ID = lEleNum2
           , STM2_STM_ELEMENT_NUMBER_ID = lEleNum3
       where STM_STOCK_POSITION_ID = tplReceptPosition.STM_STOCK_POSITION_ID;
    end loop;
  end UpdateReceptPositions;
end FAL_BATCH_FUNCTIONS;
