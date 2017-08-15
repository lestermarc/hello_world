--------------------------------------------------------
--  DDL for Package Body FAL_SUIVI_OPERATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_SUIVI_OPERATION" 
is
  -- Configurations
  cPfgEndProcessProc          varchar2(64)                               := PCS.PC_CONFIG.GetConfig('FAL_PFG_END_PROCESS_PROC');
  cPfgUpdateLot               integer                                    := PCS.PC_CONFIG.GetConfig('FAL_PFG_UPDATE_LOT');
  cProgressMvtCpt             integer                                    := PCS.PC_CONFIG.GetConfig('FAL_PROGRESS_MVT_CPT');
  cPpsAscDsc                  integer                                    := PCS.PC_CONFIG.GetConfig('PPS_ASC_DSC');
  cProgressMode               integer                                    := PCS.PC_CONFIG.GetConfig('FAL_PROGRESS_MODE');
  cProgressTime               boolean                                    := PCS.PC_CONFIG.GetBooleanConfig('FAL_PROGRESS_TIME');
  cInitOnOperationProgress    boolean                                    := PCS.PC_CONFIG.GetBooleanConfig('FAL_InitOnOperationProgress');
  cPFGInitOnOperationProgress boolean                                    := PCS.PC_CONFIG.GetBooleanConfig('FAL_PFGInitOnOperationProgress');
  cMultiplUnit                boolean                                    := PCS.PC_CONFIG.GetBooleanConfig('FAL_MULTIPL_UNIT');
  cPfgAllowIncreaseQty        boolean                                    := PCS.PC_CONFIG.GetBooleanConfig('FAL_PFG_ALLOW_INCREASE_QTY');
  cWorkBalance                boolean                                    := PCS.PC_CONFIG.GetBooleanConfig('FAL_WORK_BALANCE');
  -- Origines d'avancement
  poProduction                FAL_TIME_STAMPING.C_PROGRESS_ORIGIN%type   := '10';   -- Opération d'OF
  poProject                   FAL_TIME_STAMPING.C_PROGRESS_ORIGIN%type   := '20';   -- Opération de DF
  -- Statuts d'enregistrement du brouillard
  fsToConfirm                 FAL_LOT_PROGRESS_FOG.C_PFG_STATUS%type     := '10';   -- A confirmer
  fsToProcess                 FAL_LOT_PROGRESS_FOG.C_PFG_STATUS%type     := '20';   -- A traiter
  fsError                     FAL_LOT_PROGRESS_FOG.C_PFG_STATUS%type     := '30';   -- En erreur
  fsProcessed                 FAL_LOT_PROGRESS_FOG.C_PFG_STATUS%type     := '40';   -- Traité sans erreur
  -- Statuts de lot
  lsLaunched                  FAL_LOT.C_LOT_STATUS%type                  := '2';   -- Lancé
  lsBalancedRecept            FAL_LOT.C_LOT_STATUS%type                  := '5';   -- Soldé (réception)

  /**
  * procedure pExecuteProc
  * Description
  *    Exécution de la procédure renseignée dans la config "FAL_PFG_END_PROCESS_PROC".
  * @created cle
  * @lastUpdate age 11.12.2013
  * @private
  * @param iProgressId : Id du suivi créé.
  * @param iContext    : Contexte de création du suivi (pour la liste des contextes, voir FAL_COMPONENT_LINK_FUNCTIONS)
  */
  procedure pExecuteProc(iProgressId in FAL_LOT_PROGRESS.FAL_LOT_PROGRESS_ID%type, iContext in pls_integer)
  is
  begin
    if cPfgEndProcessProc is not null then
      execute immediate ' begin ' || cPfgEndProcessProc || '(:iProgressId, :iContext); end;'
                  using iProgressId, iContext;
    end if;
  end pExecuteProc;

  /**
  * procedure CorrectProgressTracking
  * Description
  *    Insertion d'un suivi opératoire de correction si besoin
  * @created
  * @lastUpdate CLG 10.2015
  * @private
  * @param iScheduleStepId : Id de l'opération de lot
  * @param iOperator       : Opérateur à affecter au nouveau suivi
  */
  procedure CorrectProgressTracking(iScheduleStepId FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type, iOperator FAL_LOT_PROGRESS.DIC_OPERATOR_ID%type)
  is
    nFalLotId          number;
    aErrorMsg          integer;
    lnNewTrackAdjTime  FAL_LOT_PROGRESS.FLP_ADJUSTING_TIME%type;
    lnNewTrackWorkTime FAL_LOT_PROGRESS.FLP_WORK_TIME%type;
    lnNewTrackAmount   FAL_LOT_PROGRESS.FLP_AMOUNT%type;
  begin
    select nvl(TAL_ACHIEVED_AD_TSK, 0) - TRACK.ADJ_TIME
         , nvl(TAL_ACHIEVED_TSK, 0) - TRACK.WORK_TIME
         , nvl(TAL_ACHIEVED_AMT, 0) - TRACK.AMOUNT
      into lnNewTrackAdjTime
         , lnNewTrackWorkTime
         , lnNewTrackAmount
      from FAL_TASK_LINK
         , (select nvl(sum(FLP_ADJUSTING_TIME), 0) ADJ_TIME
                 , nvl(sum(FLP_WORK_TIME), 0) WORK_TIME
                 , nvl(sum(FLP_AMOUNT), 0) AMOUNT
              from FAL_LOT_PROGRESS
             where FAL_SCHEDULE_STEP_ID = iScheduleStepId) TRACK
     where FAL_SCHEDULE_STEP_ID = iScheduleStepId;

    if    (lnNewTrackAdjTime <> 0)
       or (lnNewTrackWorkTime <> 0)
       or (lnNewTrackAmount <> 0) then
      insert into FAL_LOT_PROGRESS
                  (FAL_LOT_PROGRESS_ID
                 , FAL_LOT_ID
                 , FAL_SCHEDULE_STEP_ID
                 , FAL_TASK_ID
                 , FAL_FACTORY_FLOOR_ID
                 , FAL_FAL_FACTORY_FLOOR_ID
                 , PPS_TOOLS1_ID
                 , PPS_TOOLS2_ID
                 , PPS_TOOLS3_ID
                 , PPS_TOOLS4_ID
                 , PPS_TOOLS5_ID
                 , PPS_TOOLS6_ID
                 , PPS_TOOLS7_ID
                 , PPS_TOOLS8_ID
                 , PPS_TOOLS9_ID
                 , PPS_TOOLS10_ID
                 , PPS_TOOLS11_ID
                 , PPS_TOOLS12_ID
                 , PPS_TOOLS13_ID
                 , PPS_TOOLS14_ID
                 , PPS_TOOLS15_ID
                 , PPS_OPERATION_PROCEDURE_ID
                 , PPS_PPS_OPERATION_PROCEDURE_ID
                 , DIC_REBUT_ID
                 , DIC_WORK_TYPE_ID
                 , DIC_OPERATOR_ID
                 , LOT_REFCOMPL
                 , FLP_PRODUCT_QTY
                 , FLP_PT_REJECT_QTY
                 , FLP_CPT_REJECT_QTY
                 , FLP_ADJUSTING_TIME
                 , FLP_WORK_TIME
                 , FLP_AMOUNT
                 , FLP_SHORT_DESCR
                 , FLP_SEQ
                 , FLP_LABEL_CONTROL
                 , FLP_LABEL_REJECT
                 , FLP_DATE1
                 , FLP_DATE2
                 , FLP_EAN_CODE
                 , FLP_RATE
                 , A_DATECRE
                 , A_IDCRE
                 , FLP_SEQ_ORIGIN
                 , DIC_FREE_TASK_CODE2_ID
                 , DIC_FREE_TASK_CODE_ID
                 , FLP_ADJUSTING_RATE
                  )
        select GetNewId
             , FAL_LOT_ID
             , FAL_SCHEDULE_STEP_ID
             , FAL_TASK_ID
             , FAL_FACTORY_FLOOR_ID
             , FAL_FAL_FACTORY_FLOOR_ID
             , PPS_TOOLS1_ID
             , PPS_TOOLS2_ID
             , PPS_TOOLS3_ID
             , PPS_TOOLS4_ID
             , PPS_TOOLS5_ID
             , PPS_TOOLS6_ID
             , PPS_TOOLS7_ID
             , PPS_TOOLS8_ID
             , PPS_TOOLS9_ID
             , PPS_TOOLS10_ID
             , PPS_TOOLS11_ID
             , PPS_TOOLS12_ID
             , PPS_TOOLS13_ID
             , PPS_TOOLS14_ID
             , PPS_TOOLS15_ID
             , PPS_OPERATION_PROCEDURE_ID
             , PPS_PPS_OPERATION_PROCEDURE_ID
             , null
             , null
             , iOperator
             , (select LOT_REFCOMPL
                  from FAL_LOT LOT
                 where LOT.FAL_LOT_ID = FTL.FAL_LOT_ID)
             , 0
             , 0
             , 0
             , lnNewTrackAdjTime
             , lnNewTrackWorkTime
             , lnNewTrackAmount
             , SCS_SHORT_DESCR
             , SCS_STEP_NUMBER
             , null
             , null
             , sysdate
             , null
             , TAL_EAN_CODE
             , SCS_WORK_RATE
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
             , TAL_SEQ_ORIGIN
             , DIC_FREE_TASK_CODE2_ID
             , DIC_FREE_TASK_CODE_ID
             , SCS_ADJUSTING_RATE
          from FAL_TASK_LINK FTL
         where FAL_SCHEDULE_STEP_ID = iScheduleStepId;

      -- Imputation automatique en finance
      if upper(PCS.PC_CONFIG.GetConfig('FAL_AUTO_ACI_TIME_ENTRY') ) = 'TRUE' then
        select FAL_LOT_ID
          into nFalLotId
          from FAL_TASK_LINK
         where FAL_SCHEDULE_STEP_ID = iScheduleStepId;

        FAL_ACI_TIME_ENTRY_FCT.ProcessBatch(nFalLotId, aErrorMsg);
      end if;
    end if;
  end CorrectProgressTracking;

  procedure MAJ_LotFabricationPseudo(PrmFAL_LOT_ID FAL_LOT.FAL_LOT_ID%type, PrmLOT_INPROD_QTY FAL_LOT.LOT_INPROD_QTY%type)
  is
  begin
    update FAL_LOT
       set LOT_MAX_RELEASABLE_QTY = FAL_COMPONENT_TOOLS.GetMinQteMaxReceptionnable_Lot(PrmFAL_LOT_ID, PrmLOT_INPROD_QTY)
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_LOT_ID = PrmFAL_LOT_ID;
  end MAJ_LotFabricationPseudo;

  procedure MAJ_OrdrePseudo(PrmFAL_ORDER_ID FAL_ORDER.FAL_ORDER_ID%type)
  is
  begin
    update FAL_ORDER
       set ORD_MAX_RELEASABLE = (select sum(nvl(LOT_MAX_RELEASABLE_QTY, 0) )
                                   from FAL_LOT
                                  where FAL_ORDER_ID = PrmFAL_ORDER_ID)
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_ORDER_ID = PrmFAL_ORDER_ID;
  end MAJ_OrdrePseudo;

  /**
  * Description
  *    Génération des composants temporaires ainsi que des
  *    liens de réservation pour la sortie de composants durant
  *    le suivi de fabrication. Retourne le nombre de composants sortis
  */
  procedure SortieComposantsAuSuivi(
    PrmFAL_LOT_ID        in     FAL_LOT.FAL_LOT_ID%type
  , PrmLOM_SESSION       in     varchar2
  , PrmSequence1         in     FAL_LOT_PROGRESS.FLP_SEQ%type
  , PrmSequence2         in     FAL_LOT_PROGRESS.FLP_SEQ%type
  , aErrorCode           in out varchar2
  , aErrorMsg            in out varchar2
  , aiShutDownExceptions in     integer default 0
  , aCptOutCount         out    number
  )
  is
    aNbComponents integer;
  begin
    -- Purge enreg temporaires
    FAL_LOT_MAT_LINK_TMP_FUNCTIONS.PurgeAllTemporaryTable(PrmLOM_SESSION);
    -- Génération composants et liens composants temporaires.
    FAL_COMPONENT_MVT_SORTIE.ComponentAndLinkGenForOutput(PrmFAL_LOT_ID
                                                        , 0
                                                        , 0
                                                        , PrmLOM_SESSION
                                                        , PrmSequence1
                                                        , PrmSequence2
                                                        , 1   -- Uniquement les composants avec besoin
                                                        , 1   -- Solder besoin
                                                        , FAL_COMPONENT_LINK_FUNCTIONS.ctxtProductionAdvance
                                                         );
    -- Des composants ont été créés
    FAL_LOT_MAT_LINK_TMP_FCT.ExistsTmpComponents(PrmLOM_SESSION, aNbComponents);
    aCptOutCount  := aNbComponents;

    if aNbComponents > 0 then
      -- Application des mouvements préparés.
      FAL_COMPONENT_MVT_SORTIE.ApplyOutputMovements(aFAL_LOT_ID            => PrmFAL_LOT_ID
                                                  , aLOM_SESSION           => PrmLOM_SESSION
                                                  , aOutPutDate            => sysdate
                                                  , aErrorCode             => aErrorCode
                                                  , aErrorMsg              => aErrorMsg
                                                  , aiShutDownExceptions   => aiShutdownExceptions
                                                   );
    end if;

    -- Purge enreg temporaires
    FAL_LOT_MAT_LINK_TMP_FCT.PurgeAllTemporaryTable(PrmLOM_SESSION);
  exception
    when others then
      -- Mise à jour du code et du message d'erreur
      if aErrorCode is null then
        aErrorCode  := 'unknown';
      end if;

      addText(aErrorMsg, sqlerrm || co.cLineBreak || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);

      -- On relance l'exception si l'appelant ne l'a pas désactivé
      if aiShutDownExceptions = 0 then
        raise;
      end if;
  end SortieComposantsAuSuivi;

  /**
  * Description
  *    Génération des composants temporaires ainsi que des
  *    liens de réservation pour la sortie de composants durant
  *    le suivi de fabrication. Retourne le nombre de composants sortis
  */
  procedure SortieComposantsAuSuivi(
    aLOM_SESSION          in     varchar2 default null
  , aFAL_SCHEDULE_STEP_ID in     number
  , aErrorCode            in out varchar2
  , aErrorMsg             in out varchar2
  , aiShutDownExceptions  in     integer default 0
  , aCptOutCount          out    number
  )
  is
    nFAL_LOT_ID number;
    iSequenceOp integer;
  begin
    select SCS_STEP_NUMBER
         , FAL_LOT_ID
      into iSequenceOp
         , nFAL_LOT_ID
      from FAL_TASK_LINK
     where FAL_SCHEDULE_STEP_ID = aFAL_SCHEDULE_STEP_ID;

    SortieComposantsAuSuivi(PrmFAL_LOT_ID          => nFAL_LOT_ID
                          , PrmLOM_SESSION         => nvl(aLOM_SESSION, DBMS_SESSION.unique_session_id)
                          , PrmSequence1           => iSequenceOp
                          , PrmSequence2           => iSequenceOp
                          , aErrorCode             => aErrorCode
                          , aErrorMsg              => aErrorMsg
                          , aiShutDownExceptions   => aiShutDownExceptions
                          , aCptOutCount           => aCptOutCount
                           );
  exception
    when no_data_found then
      aErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('Opération non trouvée !');
    when others then
      raise;
  end SortieComposantsAuSuivi;

  /**
  * Description
  *    Génération des composants temporaires ainsi que des
  *    liens de réservation pour la sortie de composants durant
  *    le suivi de fabrication. Ne retourne pas le nombre de composants sortis
  */
  procedure SortieComposantsAuSuivi(
    aLOM_SESSION          in     varchar2 default null
  , aFAL_SCHEDULE_STEP_ID in     number
  , aErrorCode            in out varchar2
  , aErrorMsg             in out varchar2
  , aiShutDownExceptions  in     integer default 0
  )
  as
    lCptOutCount number;
  begin
    SortieComposantsAuSuivi(aLOM_SESSION            => aLOM_SESSION
                          , aFAL_SCHEDULE_STEP_ID   => aFAL_SCHEDULE_STEP_ID
                          , aErrorCode              => aErrorCode
                          , aErrorMsg               => aErrorMsg
                          , aiShutDownExceptions    => aiShutDownExceptions
                          , aCptOutCount            => lCptOutCount
                           );
  end SortieComposantsAuSuivi;

  /**
   * procedure MustClearOperationInDaybook
   * Description
   *    Retourne 1 si suppression de l'enregistrement nécessaire (ie pour tout
   *    enregistrement lié à une opération non principale ou secondaire
   *    et non interne).
   */
  function MustClearOperationInDaybook(aTaskLinkId in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return integer
  is
    vResult integer;
  begin
    vResult  := 0;

    if aTaskLinkId > 0 then
      select case
               when(    TAL.C_OPERATION_TYPE <> '1'
                    and TAL.C_OPERATION_TYPE <> '4') then 1
               else 0
             end
        into vResult
        from FAL_TASK_LINK TAL
       where TAL.FAL_SCHEDULE_STEP_ID = aTaskLinkId;

      if vResult = 0 then
        select case
                 when TAL.C_TASK_TYPE <> '1' then 1
                 else 0
               end
          into vResult
          from FAL_TASK_LINK TAL
         where TAL.FAL_SCHEDULE_STEP_ID = aTaskLinkId;
      end if;
    end if;

    return vResult;
  end MustClearOperationInDaybook;

  /**
   * procedure ClearOperationInDaybook
   * Description
   *    Suppression de toutes les opérations non principales ou secondaires
   *    et non internes dans le brouillard
   */
  procedure ClearOperationInDaybook
  is
  begin
    delete from FAL_LOT_PROGRESS_FOG PFG
          where exists(
                  select 1
                    from FAL_TASK_LINK FTL
                       , FAL_LOT LOT
                   where LOT.LOT_REFCOMPL = PFG.PFG_LOT_REFCOMPL
                     and FTL.FAL_LOT_ID = LOT.FAL_LOT_ID
                     and FTL.SCS_STEP_NUMBER = PFG.PFG_SEQ
                     and (    FTL.C_OPERATION_TYPE <> '1'
                          and FTL.C_OPERATION_TYPE <> '4') );

    delete from FAL_LOT_PROGRESS_FOG PFG
          where exists(
                  select 1
                    from FAL_TASK_LINK FTL
                       , FAL_LOT LOT
                   where LOT.LOT_REFCOMPL = PFG.PFG_LOT_REFCOMPL
                     and FTL.FAL_LOT_ID = LOT.FAL_LOT_ID
                     and FTL.SCS_STEP_NUMBER = PFG.PFG_SEQ
                     and FTL.C_TASK_TYPE <> '1');
  end ClearOperationInDaybook;

  /**
   * procedure UpdateOperationQty
   * Description
   *    MAJ des qtés rebuts PT et CPT pour les opérations liées à un lot soldé
   */
  procedure UpdateOperationQty
  is
  begin
    update FAL_LOT_PROGRESS_FOG PFG
       set PFG_PT_REFECT_QTY = 0
         , PFG_CPT_REJECT_QFY = 0
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where exists(select 1
                    from FAL_LOT LOT
                   where LOT.LOT_REFCOMPL = PFG.PFG_LOT_REFCOMPL
                     and LOT.C_LOT_STATUS = lsBalancedRecept);
  end UpdateOperationQty;

  /**
   * procedure UpdateOperationAmount
   * Description
   *     Mise à jour des montants de l'opération à l'origine de la position de la commande sous-traitance
  */
  procedure UpdateOperationAmount(
    iDocPositionId        DOC_POSITION.doc_position_id%type
  , iDocGaugeReceiptId in DOC_POSITION_DETAIL.DOC_GAUGE_RECEIPT_ID%type default null
  )
  is
    aDocGaugeReceiptId DOC_POSITION_DETAIL.DOC_GAUGE_RECEIPT_ID%type;

    --  Lecture de la moyenne du prix unitaire des positions d'une CST / CAST qui mettent a jour les opérations de l'OF
    cursor crPosition
    is
      -- sous traitance D'achat
      select (nvl(pos.POS_NET_VALUE_EXCL_B, 0) / decode(POS.POS_FINAL_QUANTITY_SU, 0, 1, POS.POS_FINAL_QUANTITY_SU) ) Price
           , FAL_SCHEDULE_STEP_ID
           , FAL_LOT_ID
           , DOC_POSITION_ID
        from DOC_POSITION POS
       where DOC_POSITION_ID = iDocPositionId
         and (   FAL_SCHEDULE_STEP_ID is not null   -- sous traitance opératoire
              or FAL_LOT_ID is not null)   -- sous traitance d'achat
         and (   STM_MOVEMENT_KIND_ID is null   -- pas de genre de mouvement (en principe CST et CAST)
              or exists(select SMK.STM_MOVEMENT_KIND_ID
                          from STM_MOVEMENT_KIND SMK
                         where SMK.STM_MOVEMENT_KIND_ID = POS.STM_MOVEMENT_KIND_ID
                           and SMK.MOK_UPDATE_OP = 1)   -- demande de mise à jour de l'opération (en principe BRST et FFST)
             )
         and (   aDocGaugeReceiptId is null
              or DOC_GAUGE_FUNCTIONS.GetGaugeReceiptFlag(aDocGaugeReceiptId, 'GAR_INIT_PRICE_MVT') = 1);   -- transfert du prix

    tplPosition        crPosition%rowtype;
  begin
    aDocGaugeReceiptId  := iDocGaugeReceiptId;

    if aDocGaugeReceiptId is null then
      select max(DOC_GAUGE_RECEIPT_ID)
        into aDocGaugeReceiptId
        from DOC_POSITION_DETAIL
       where DOC_POSITION_ID = iDocPositionId;
    end if;

    open crPosition;

    fetch crPosition
     into tplPosition;

    close crPosition;

    if tplPosition.Price > 0 then
      -- Mise à jour du montant dû de l'opération.
      update FAL_TASK_LINK
         set TAL_CST_UNIT_PRICE_B = tplPosition.Price
       where FAL_SCHEDULE_STEP_ID = tplPosition.FAL_SCHEDULE_STEP_ID
          or FAL_LOT_ID = tplPosition.FAL_LOT_ID;
    end if;

    -- Vide le flag de mise à jour de l'opération sur la position.
    update DOC_POSITION
       set POS_UPDATE_OP = 0
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_POSITION_ID = tplPosition.DOC_POSITION_ID
       and POS_UPDATE_OP = 2;
  end UpdateOperationAmount;

  /**
   * procedure ApplyDaybook
   * Description
   *    Application du brouillard d'avancement
   */
  procedure ApplyDaybook
  is
    cursor curLotProgressFog
    is
      select   FAL_LOT_PROGRESS_FOG_ID
          from FAL_LOT_PROGRESS_FOG
         where C_PFG_STATUS = fsToProcess
      order by PFG_LOT_REFCOMPL
             , PFG_GAL_REFCOMPL
             , PFG_SEQ
             , PFG_DATE;

    vError    integer;
    vErrorMsg varchar2(4000);
  begin
    /*  Traiter un à un les enregistrements. Ils doivent être triés par Lot ou
        DF, par Sequence puis par date */
    for tplLotProgressFog in curLotProgressFog loop
      ProcessDaybook(aFAL_LOT_PROGRESS_FOG_ID => tplLotProgressFog.FAL_LOT_PROGRESS_FOG_ID, aError => vError, aErrorMsg => vErrorMsg);
    end loop;
  end ApplyDaybook;

  /* Retourne le FAL_LOT_ID en fonction de la référence complète du lot.
     NULL si rien trouvé ou si le lot n'est pas en statut "Lancé" ou "Soldé réception". */
  function GetLotIdFromRefCompl(aLotRefCompl varchar2)
    return number
  is
    cursor curFalLotId
    is
      select FAL_LOT_ID
        from FAL_LOT
       where LOT_REFCOMPL = aLotRefCompl
         and C_LOT_STATUS in(lsLaunched, lsBalancedRecept);

    result number;
  begin
    result  := null;

    open curFalLotId;

    fetch curFalLotId
     into result;

    close curFalLotId;

    return result;
  end GetLotIdFromRefCompl;

  /* Retourne l'ID de l'opération de lot en fonction de l'id du lot et
     de la séquence opération. NULL si rien trouvé. */
  function GetScheduleStepID(aSeq number, FalLotId number)
    return number
  is
    cursor curFalScheduleStepId
    is
      select FAL_SCHEDULE_STEP_ID
        from FAL_TASK_LINK
       where FAL_LOT_ID = FalLotId
         and SCS_STEP_NUMBER = aSeq;

    result number;
  begin
    result  := null;

    open curFalScheduleStepId;

    fetch curFalScheduleStepId
     into result;

    close curFalScheduleStepId;

    return result;
  end GetScheduleStepID;

  /* Retourne l'ID de l'atelier en fonction de sa référence
     NULL si rien trouvé. */
  function GetFactoryFloorID(aRefFloor varchar2)
    return number
  is
    cursor curFalFactoryFloorId
    is
      select FAL_FACTORY_FLOOR_ID
        from FAL_FACTORY_FLOOR
       where upper(FAC_REFERENCE) = upper(aRefFloor);

    result number;
  begin
    result  := null;

    open curFalFactoryFloorId;

    fetch curFalFactoryFloorId
     into result;

    close curFalFactoryFloorId;

    return result;
  end GetFactoryFloorID;

  function GetOperationProcID(aRefProc varchar2)
    return number
  is
    cursor curPpsOperationProcedureId
    is
      select PPS_OPERATION_PROCEDURE_ID
        from PPS_OPERATION_PROCEDURE
       where upper(OPP_REFERENCE) = upper(aRefProc);

    result number;
  begin
    result  := null;

    open curPpsOperationProcedureId;

    fetch curPpsOperationProcedureId
     into result;

    close curPpsOperationProcedureId;

    return result;
  end GetOperationProcID;

  function GetToolID(aRefTool varchar2)
    return number
  is
    cursor curToolId
    is
      select GCO_GOOD_ID
        from GCO_GOOD
       where upper(GOO_MAJOR_REFERENCE) = upper(aRefTool);

    result number;
  begin
    result  := null;

    open curToolId;

    fetch curToolId
     into result;

    close curToolId;

    return result;
  end GetToolID;

  function CheckLotFields(
    aPFG_LOT_REFCOMPL            in     varchar2
  , aPFG_SEQ                     in     number
  , aPFG_DATE                    in     date
  , aPFG_REF_FACTORY_FLOOR       in     varchar2
  , aPFG_REF_FACTORY_FLOOR2      in     varchar2
  , aPFG_RATE_FACTORY_FLOOR      in     number
  , aPFG_PROC_CONTROL            in     varchar2
  , aPFG_PROC_EXECUTION          in     varchar2
  , aPFG_TOOLS1                  in     varchar2
  , aPFG_TOOLS2                  in     varchar2
  , aPFG_TOOLS3                  in     varchar2
  , aPFG_TOOLS4                  in     varchar2
  , aPFG_TOOLS5                  in     varchar2
  , aPFG_TOOLS6                  in     varchar2
  , aPFG_TOOLS7                  in     varchar2
  , aPFG_TOOLS8                  in     varchar2
  , aPFG_TOOLS9                  in     varchar2
  , aPFG_TOOLS10                 in     varchar2
  , aPFG_TOOLS11                 in     varchar2
  , aPFG_TOOLS12                 in     varchar2
  , aPFG_TOOLS13                 in     varchar2
  , aPFG_TOOLS14                 in     varchar2
  , aPFG_TOOLS15                 in     varchar2
  , aPFG_DIC_OPERATOR_ID         in     varchar2
  , aPFG_DIC_REBUT_ID            in     varchar2
  , aPFG_DIC_WORK_TYPE_ID        in     varchar2
  , aPFG_PRODUCT_QTY             in     number
  , aPFG_PT_REJECT_QTY           in     number
  , aFAL_LOT_PROGRESS_FOG_ID     in     number
  , FalLotId                     in out number
  , FalTaskLinkId                in out number
  , FalFactoryFloorId            in out number
  , FalFactoryFloor2Id           in out number
  , PpsOperationProcId_Control   in out number
  , PpsOperationProcId_Execution in out number
  , GcoGoodId_Tool1              in out number
  , GcoGoodId_Tool2              in out number
  , GcoGoodId_Tool3              in out number
  , GcoGoodId_Tool4              in out number
  , GcoGoodId_Tool5              in out number
  , GcoGoodId_Tool6              in out number
  , GcoGoodId_Tool7              in out number
  , GcoGoodId_Tool8              in out number
  , GcoGoodId_Tool9              in out number
  , GcoGoodId_Tool10             in out number
  , GcoGoodId_Tool11             in out number
  , GcoGoodId_Tool12             in out number
  , GcoGoodId_Tool13             in out number
  , GcoGoodId_Tool14             in out number
  , GcoGoodId_Tool15             in out number
  )
    return integer
  is
    CountEnreg number;
  begin
    /* Vérifier les champs obligatoires : PFG_LOT_REFCOMPL, PFG_SEQ, PFG_DATE */
    if aPFG_LOT_REFCOMPL is null then
      return faLotRefRequired;
    elsif aPFG_SEQ is null then
      return faSeqRequired;
    elsif aPFG_DATE is null then
      return faDateRequired;
    end if;

    FalLotId                      := null;
    FalTaskLinkId                 := null;
    FalFactoryFloorId             := null;
    FalFactoryFloor2Id            := null;
    PpsOperationProcId_Control    := null;
    PpsOperationProcId_Execution  := null;
    GcoGoodId_Tool1               := null;
    GcoGoodId_Tool2               := null;
    GcoGoodId_Tool3               := null;
    GcoGoodId_Tool4               := null;
    GcoGoodId_Tool5               := null;
    GcoGoodId_Tool6               := null;
    GcoGoodId_Tool7               := null;
    GcoGoodId_Tool8               := null;
    GcoGoodId_Tool9               := null;
    GcoGoodId_Tool10              := null;
    GcoGoodId_Tool11              := null;
    GcoGoodId_Tool12              := null;
    GcoGoodId_Tool13              := null;
    GcoGoodId_Tool14              := null;
    GcoGoodId_Tool15              := null;
    /* Vérifier les éventuelles références. Renseigner les valeurs d'ID récupérées ... */
      -- FAL_LOT_ID (obligatoire)
    FalLotId                      := GetLotIdFromRefCompl(aPFG_LOT_REFCOMPL);

    if FalLotId is null then
      return faLotRefNotFound;
    end if;

    -- FAL_TASK_LINK_ID (obligatoire)
    FalTaskLinkId                 := GetScheduleStepID(aPFG_SEQ, FalLotId);

    if FalTaskLinkId is null then
      return faSeqNotFound;
    end if;

    -- Pesées matière précieuse
    if FAL_LIB_TASK_LINK.isWeighingManaged(inFalTaskLinkID => FalTaskLinkId) = 1 then
      /* Si la pesée est obligatoire */
      if FAL_LIB_TASK_LINK.isWeighingMandatory(inFalTaskLinkID => FalTaskLinkId) = 1 then
        /* Il existe une (des) pesées pour le brouillard d'avancement en quantité suffisante */
        if FAL_LIB_LOT_PROGRESS.isWeighingNeeded(inFalLotProgressID      => null
                                               , inFalTaskLinkID         => FalTaskLinkId
                                               , inFalLotProgressFogId   => aFAL_LOT_PROGRESS_FOG_ID
                                               , inPFG_PRODUCT_QTY       => aPFG_PRODUCT_QTY
                                               , inPFG_PT_REJECT_QTY     => aPFG_PT_REJECT_QTY
                                                ) = 1 then
          /* Ou il existe une (des) pesées en qtés suffisantes pour l'opération à avancer (Qté pesées >=
             Qté suivi avancement (Réalisé + Rebut PT) + Qté déja avancées de l'opération) */
          if FAL_LIB_LOT_PROGRESS.isWeighingNeeded(inFalLotProgressID    => null
                                                 , inFalTaskLinkID       => FalTaskLinkId
                                                 , inPFG_PRODUCT_QTY     => aPFG_PRODUCT_QTY
                                                 , inPFG_PT_REJECT_QTY   => aPFG_PT_REJECT_QTY
                                                  ) = 1 then
            return faWeighingNeeded;
          end if;
        end if;
      end if;
    end if;

    if aPFG_REF_FACTORY_FLOOR is not null then
      -- FAL_FACTORY_FLOOR_ID...
      FalFactoryFloorId  := GetFactoryFloorID(aPFG_REF_FACTORY_FLOOR);

      if FalFactoryFloorId is null then
        return faFactoryNotFound;
      end if;
    end if;

    if aPFG_REF_FACTORY_FLOOR2 is not null then
      -- FAL_FAL_FACTORY_FLOOR_ID...
      FalFactoryFloor2Id  := GetFactoryFloorID(aPFG_REF_FACTORY_FLOOR2);

      if FalFactoryFloor2Id is null then
        return faSecondFactoryNotFound;
      end if;
    end if;

    if     (FalFactoryFloorId is not null)   -- +++ NULL doit être correct. A tester
       and (aPFG_RATE_FACTORY_FLOOR not in(1, 2, 3, 4, 5) ) then
      -- Taux machine doit être Null, 1, 2, 3, 4 ou 5
      return faFactoryRateNotFound;
    end if;

    -- PpsOperationProcedureId_Control
    if aPFG_PROC_CONTROL is not null then
      PpsOperationProcId_Control  := GetOperationProcID(aPFG_PROC_CONTROL);

      if PpsOperationProcId_Control is null then
        return faControlProcNotFound;
      end if;
    end if;

    -- PpsOperationProcedureId_Execution
    if aPFG_PROC_EXECUTION is not null then
      PpsOperationProcId_Execution  := GetOperationProcID(aPFG_PROC_EXECUTION);

      if PpsOperationProcId_Execution is null then
        return faExecutionProcNotFound;
      end if;
    end if;

    if aPFG_TOOLS1 is not null then
      GcoGoodId_Tool1  := GetToolID(aPFG_TOOLS1);

      if GcoGoodId_Tool1 is null then
        return faTool1NotFound;
      end if;
    end if;

    if aPFG_TOOLS2 is not null then
      GcoGoodId_Tool2  := GetToolID(aPFG_TOOLS2);

      if GcoGoodId_Tool2 is null then
        return faTool2NotFound;
      end if;
    end if;

    if aPFG_TOOLS3 is not null then
      GcoGoodId_Tool3  := GetToolID(aPFG_TOOLS3);

      if GcoGoodId_Tool3 is null then
        return faTool3NotFound;
      end if;
    end if;

    if aPFG_TOOLS4 is not null then
      GcoGoodId_Tool4  := GetToolID(aPFG_TOOLS4);

      if GcoGoodId_Tool4 is null then
        return faTool4NotFound;
      end if;
    end if;

    if aPFG_TOOLS5 is not null then
      GcoGoodId_Tool5  := GetToolID(aPFG_TOOLS5);

      if GcoGoodId_Tool5 is null then
        return faTool5NotFound;
      end if;
    end if;

    if aPFG_TOOLS6 is not null then
      GcoGoodId_Tool6  := GetToolID(aPFG_TOOLS6);

      if GcoGoodId_Tool6 is null then
        return faTool6NotFound;
      end if;
    end if;

    if aPFG_TOOLS7 is not null then
      GcoGoodId_Tool7  := GetToolID(aPFG_TOOLS7);

      if GcoGoodId_Tool7 is null then
        return faTool7NotFound;
      end if;
    end if;

    if aPFG_TOOLS8 is not null then
      GcoGoodId_Tool8  := GetToolID(aPFG_TOOLS8);

      if GcoGoodId_Tool8 is null then
        return faTool8NotFound;
      end if;
    end if;

    if aPFG_TOOLS9 is not null then
      GcoGoodId_Tool9  := GetToolID(aPFG_TOOLS9);

      if GcoGoodId_Tool9 is null then
        return faTool9NotFound;
      end if;
    end if;

    if aPFG_TOOLS10 is not null then
      GcoGoodId_Tool10  := GetToolID(aPFG_TOOLS10);

      if GcoGoodId_Tool10 is null then
        return faTool10NotFound;
      end if;
    end if;

    if aPFG_TOOLS11 is not null then
      GcoGoodId_Tool11  := GetToolID(aPFG_TOOLS11);

      if GcoGoodId_Tool11 is null then
        return faTool11NotFound;
      end if;
    end if;

    if aPFG_TOOLS12 is not null then
      GcoGoodId_Tool12  := GetToolID(aPFG_TOOLS12);

      if GcoGoodId_Tool12 is null then
        return faTool12NotFound;
      end if;
    end if;

    if aPFG_TOOLS13 is not null then
      GcoGoodId_Tool13  := GetToolID(aPFG_TOOLS13);

      if GcoGoodId_Tool13 is null then
        return faTool13NotFound;
      end if;
    end if;

    if aPFG_TOOLS14 is not null then
      GcoGoodId_Tool14  := GetToolID(aPFG_TOOLS14);

      if GcoGoodId_Tool14 is null then
        return faTool14NotFound;
      end if;
    end if;

    if aPFG_TOOLS15 is not null then
      GcoGoodId_Tool15  := GetToolID(aPFG_TOOLS15);

      if GcoGoodId_Tool15 is null then
        return faTool15NotFound;
      end if;
    end if;

    -- DIC_OPERATOR_ID ...
    if aPFG_DIC_OPERATOR_ID is not null then
      select count(*)
        into CountEnreg
        from dic_operator
       where dic_operator_id = aPFG_DIC_OPERATOR_ID;

      if CountEnreg = 0 then
        return faOperatorNotFound;
      end if;
    end if;

    -- DIC_REBUT_ID ...
    if aPFG_DIC_REBUT_ID is not null then
      select count(*)
        into CountEnreg
        from dic_rebut
       where dic_rebut_id = aPFG_DIC_REBUT_ID;

      if CountEnreg = 0 then
        return faRebutNotFound;
      end if;
    end if;

    -- DIC_WORK_TYPE_ID ...
    if aPFG_DIC_WORK_TYPE_ID is not null then
      select count(*)
        into CountEnreg
        from dic_work_type
       where dic_work_type_id = aPFG_DIC_WORK_TYPE_ID;

      if CountEnreg = 0 then
        return faWorkTypeNotFound;
      end if;
    end if;

    return 0;
  end CheckLotFields;

  /* Retourne l'ID de l'opération de lot en fonction de l'id du lot et
     de la séquence opération. NULL si rien trouvé. */
  function GetGalTaskLinkId(aSeq number, aTaskId number)
    return GAL_TASK_LINK.GAL_TASK_LINK_ID%type
  is
    cursor curGalTaskLinkId
    is
      select GAL_TASK_LINK_ID
        from GAL_TASK_LINK
       where GAL_TASK_ID = aTaskId
         and SCS_STEP_NUMBER = aSeq;

    vResult GAL_TASK_LINK.GAL_TASK_LINK_ID%type;
  begin
    -- Recherche de l'ID de l'opération
    vResult  := null;

    open curGalTaskLinkId;

    fetch curGalTaskLinkId
     into vResult;

    close curGalTaskLinkId;

    return vResult;
  end GetGalTaskLinkId;

  /* Retourne le numéro de l'employé correspondant au dic opérateur. NULL si rien trouvé. */
  function GetEmpNumber(aDicOperatorId DIC_OPERATOR.DIC_OPERATOR_ID%type)
    return HRM_PERSON.EMP_NUMBER%type
  is
    cursor curGetEmpNumber
    is
      select EMP_NUMBER
        from HRM_PERSON PER
           , HRM_PERSON_COMPANY PEC
       where PEC.DIC_OPERATOR_ID(+) = aDicOperatorId
         and PER.HRM_PERSON_ID(+) = PEC.HRM_PERSON_ID;

    vResult HRM_PERSON.EMP_NUMBER%type;
  begin
    -- Recherche de l'ID de l'opération
    vResult  := null;

    open curGetEmpNumber;

    fetch curGetEmpNumber
     into vResult;

    close curGetEmpNumber;

    return vResult;
  end GetEmpNumber;

  function CheckGalFields(
    aPFG_GAL_REFCOMPL        FAL_LOT_PROGRESS_FOG.PFG_GAL_REFCOMPL%type
  , aPFG_SEQ                 FAL_LOT_PROGRESS_FOG.PFG_SEQ%type
  , aPFG_DATE                FAL_LOT_PROGRESS_FOG.PFG_DATE%type
  , aPFG_DIC_OPERATOR_ID     FAL_LOT_PROGRESS_FOG.PFG_DIC_OPERATOR_ID%type
  , aTaskId              out GAL_TASK.GAL_TASK_ID%type
  , aTaskLinkId          out GAL_TASK_LINK.GAL_TASK_LINK_ID%type
  , aEmpNumber           out HRM_PERSON.EMP_NUMBER%type
  )
    return integer
  is
    vCountEnreg number;
  begin
    /* Vérifier les champs obligatoires : PFG_LOT_REFCOMPL, PFG_SEQ, PFG_DATE */
    if aPFG_GAL_REFCOMPL is null then
      return faGalRefRequired;
    elsif aPFG_DATE is null then
      return faGalDateRequired;
    end if;

    aTaskId      := null;
    aTaskLinkId  := null;
    aEmpNumber   := null;
    -- Recherche de l'ID de la tâche
    aTaskId      := FAL_TIME_STAMPING_TOOLS.ParseTaskRef(aPFG_GAL_REFCOMPL);

    if aTaskId is not null then
      -- Recherche de l'ID de l'opération
      aTaskLinkId  := GetGalTaskLinkId(aPFG_SEQ, aTaskId);

      if aTaskLinkId is null then
        return faGalSeqNotFound;
      end if;
    end if;

    -- Vérification du dic. opérateur
    if aPFG_DIC_OPERATOR_ID is not null then
      select count(*)
        into vCountEnreg
        from DIC_OPERATOR
       where DIC_OPERATOR_ID = aPFG_DIC_OPERATOR_ID;

      if vCountEnreg = 0 then
        return faOperatorNotFound;
      end if;

      -- Recherche de l'ID de l'employé
      aEmpNumber  := GetEmpNumber(aPFG_DIC_OPERATOR_ID);

      if aEmpNumber is null then
        return faEmpNumberNotFound;
      end if;
    end if;

    return faNoError;
  end CheckGalFields;

  function CreateAdvancement(
    FalLotId                            number
  , FalTaskLinkId                       number
  , LotRefcompl                         varchar2
  , aDate                               date
  , aRealizedQty                 in out number
  , RejectPTQty                         number
  , RejectCPTQty                        number
  , WorkTime                            number
  , AdjustingTime                       number
  , Amount                              number
  , aOperator                           varchar2
  , RejectCode                          varchar2
  , DicWorkType                         varchar2
  , FalFactoryFloorId                   number
  , FalFactoryFloor2Id                  number
  , FactoryRate                         number
  , PpsOperationProcId_Control          number
  , PpsOperationProcId_Execution        number
  , GcoGoodId_Tool1                     number
  , GcoGoodId_Tool2                     number
  , GcoGoodId_Tool3                     number
  , GcoGoodId_Tool4                     number
  , GcoGoodId_Tool5                     number
  , GcoGoodId_Tool6                     number
  , GcoGoodId_Tool7                     number
  , GcoGoodId_Tool8                     number
  , GcoGoodId_Tool9                     number
  , GcoGoodId_Tool10                    number
  , GcoGoodId_Tool11                    number
  , GcoGoodId_Tool12                    number
  , GcoGoodId_Tool13                    number
  , GcoGoodId_Tool14                    number
  , GcoGoodId_Tool15                    number
  , EanCode                             varchar2
  , ProductQtyUOP                       number
  , PTRejectQtyUOP                      number
  , CPTRejectQtyUOP                     number
  , aPFG_LABEL_CONTROL                  varchar2
  , aPFG_LABEL_REJECT                   varchar2
  , aManualProgressTrack                integer
  , aFAL_LOT_PROGRESS_ID         in out number
  , aFAL_LOT_PROGRESS_FOG_ID     in     number default null
  )
    return integer
  is
    cursor cur_Operation
    is
      select FAL_FACTORY_FLOOR_ID
           , FAL_FAL_FACTORY_FLOOR_ID
           , SCS_WORK_RATE
           , PPS_PPS_OPERATION_PROCEDURE_ID
           , PPS_OPERATION_PROCEDURE_ID
           , PPS_TOOLS1_ID
           , PPS_TOOLS2_ID
           , PPS_TOOLS3_ID
           , PPS_TOOLS4_ID
           , PPS_TOOLS5_ID
           , PPS_TOOLS6_ID
           , PPS_TOOLS7_ID
           , PPS_TOOLS8_ID
           , PPS_TOOLS9_ID
           , PPS_TOOLS10_ID
           , PPS_TOOLS11_ID
           , PPS_TOOLS12_ID
           , PPS_TOOLS13_ID
           , PPS_TOOLS14_ID
           , PPS_TOOLS15_ID
           , C_TASK_TYPE
           , nvl(TAL_AVALAIBLE_QTY, 0) TAL_AVALAIBLE_QTY
           , TAL_BEGIN_REAL_DATE
           , SCS_ADJUSTING_TIME
           , SCS_QTY_REF_WORK
           , SCS_WORK_TIME
           , SCS_DIVISOR_AMOUNT
           , SCS_QTY_REF_AMOUNT
           , SCS_AMOUNT
           , FAL_TASK_ID
           , SCS_QTY_FIX_ADJUSTING
           , nvl(TAL_TSK_AD_BALANCE, 0) TAL_TSK_AD_BALANCE
           , SCS_SHORT_DESCR
           , SCS_STEP_NUMBER
           , TAL_SEQ_ORIGIN
           , DIC_FREE_TASK_CODE_ID
           , DIC_FREE_TASK_CODE2_ID
           , SCS_ADJUSTING_RATE
           , SCS_QTY_REF2_WORK
           , DIC_UNIT_OF_MEASURE_ID
           , SCS_CONVERSION_FACTOR
           , nvl(TAL_DUE_QTY, 0) TAL_DUE_QTY
        from FAL_TASK_LINK
       where FAL_SCHEDULE_STEP_ID = FalTaskLinkId;

    curOperation                  Cur_Operation%rowtype;
    aError                        integer;
    aFalFactoryFloorId            number;
    aFalFactoryFloor2Id           number;
    aFactoryRate                  number;
    aPpsOperationProcId_Control   number;
    aPpsOperationProcId_Execution number;
    aGcoGoodId_Tool1              number;
    aGcoGoodId_Tool2              number;
    aGcoGoodId_Tool3              number;
    aGcoGoodId_Tool4              number;
    aGcoGoodId_Tool5              number;
    aGcoGoodId_Tool6              number;
    aGcoGoodId_Tool7              number;
    aGcoGoodId_Tool8              number;
    aGcoGoodId_Tool9              number;
    aGcoGoodId_Tool10             number;
    aGcoGoodId_Tool11             number;
    aGcoGoodId_Tool12             number;
    aGcoGoodId_Tool13             number;
    aGcoGoodId_Tool14             number;
    aGcoGoodId_Tool15             number;
    aAdjustingTime                number;
    aRejectPTQty                  number;
    aRejectCPTQty                 number;
    aWorkTime                     number;
    aAmount                       number;
    aSuppQty                      number;
    aSupQty                       number;
    aErrorMsg                     varchar2(255);
  begin
    aError          := faNoError;

    open cur_Operation;

    fetch cur_Operation
     into curOperation;

    close cur_Operation;

    -- Atelier
    if    (nvl(FalFactoryFloorId, 0) = 0)
       or (curOperation.C_TASK_TYPE = 2) then
      aFalFactoryFloorId  := curOperation.FAL_FACTORY_FLOOR_ID;
    else
      aFalFactoryFloorId  := FalFactoryFloorId;
    end if;

    -- Ressource Numéro Deux
    if    (nvl(FalFactoryFloor2Id, 0) = 0)
       or (curOperation.C_TASK_TYPE = 2) then
      aFalFactoryFloor2Id  := curOperation.FAL_FAL_FACTORY_FLOOR_ID;
    else
      aFalFactoryFloor2Id  := FalFactoryFloor2Id;
    end if;

    -- Taux atelier
    if    (nvl(FactoryRate, 0) = 0)
       or (curOperation.C_TASK_TYPE = 2) then
      aFactoryRate  := curOperation.SCS_WORK_RATE;
    else
      aFactoryRate  := FactoryRate;
    end if;

    -- Procédure exécution ( = PPS_OPERATION_PROCEDURE_ID)
    if nvl(PpsOperationProcId_Execution, 0) = 0 then
      aPpsOperationProcId_Execution  := curOperation.PPS_OPERATION_PROCEDURE_ID;
    else
      aPpsOperationProcId_Execution  := PpsOperationProcId_Execution;
    end if;

    -- Procédure contrôle ( = PPS_PPS_OPERATION_PROCEDURE_ID)
    if nvl(PpsOperationProcId_Control, 0) = 0 then
      aPpsOperationProcId_Control  := curOperation.PPS_PPS_OPERATION_PROCEDURE_ID;
    else
      aPpsOperationProcId_Control  := PpsOperationProcId_Control;
    end if;

    -- Outil 1
    if nvl(GcoGoodId_Tool1, 0) = 0 then
      aGcoGoodId_Tool1  := curOperation.PPS_TOOLS1_ID;
    else
      aGcoGoodId_Tool1  := GcoGoodId_Tool1;
    end if;

    -- Outil 2
    if nvl(GcoGoodId_Tool2, 0) = 0 then
      aGcoGoodId_Tool2  := curOperation.PPS_TOOLS2_ID;
    else
      aGcoGoodId_Tool2  := GcoGoodId_Tool2;
    end if;

    -- Outil 3
    if nvl(GcoGoodId_Tool3, 0) = 0 then
      aGcoGoodId_Tool3  := curOperation.PPS_TOOLS3_ID;
    else
      aGcoGoodId_Tool3  := GcoGoodId_Tool3;
    end if;

    -- Outil 4
    if nvl(GcoGoodId_Tool4, 0) = 0 then
      aGcoGoodId_Tool4  := curOperation.PPS_TOOLS4_ID;
    else
      aGcoGoodId_Tool4  := GcoGoodId_Tool4;
    end if;

    -- Outil 5
    if nvl(GcoGoodId_Tool5, 0) = 0 then
      aGcoGoodId_Tool5  := curOperation.PPS_TOOLS5_ID;
    else
      aGcoGoodId_Tool5  := GcoGoodId_Tool5;
    end if;

    -- Outil 6
    if nvl(GcoGoodId_Tool6, 0) = 0 then
      aGcoGoodId_Tool6  := curOperation.PPS_TOOLS6_ID;
    else
      aGcoGoodId_Tool6  := GcoGoodId_Tool6;
    end if;

    -- Outil 7
    if nvl(GcoGoodId_Tool7, 0) = 0 then
      aGcoGoodId_Tool7  := curOperation.PPS_TOOLS7_ID;
    else
      aGcoGoodId_Tool7  := GcoGoodId_Tool7;
    end if;

    -- Outil 8
    if nvl(GcoGoodId_Tool8, 0) = 0 then
      aGcoGoodId_Tool8  := curOperation.PPS_TOOLS8_ID;
    else
      aGcoGoodId_Tool8  := GcoGoodId_Tool8;
    end if;

    -- Outil 9
    if nvl(GcoGoodId_Tool9, 0) = 0 then
      aGcoGoodId_Tool9  := curOperation.PPS_TOOLS9_ID;
    else
      aGcoGoodId_Tool9  := GcoGoodId_Tool9;
    end if;

    -- Outil 10
    if nvl(GcoGoodId_Tool10, 0) = 0 then
      aGcoGoodId_Tool10  := curOperation.PPS_TOOLS10_ID;
    else
      aGcoGoodId_Tool10  := GcoGoodId_Tool10;
    end if;

    -- Outil 11
    if nvl(GcoGoodId_Tool11, 0) = 0 then
      aGcoGoodId_Tool11  := curOperation.PPS_TOOLS11_ID;
    else
      aGcoGoodId_Tool11  := GcoGoodId_Tool11;
    end if;

    -- Outil 12
    if nvl(GcoGoodId_Tool12, 0) = 0 then
      aGcoGoodId_Tool12  := curOperation.PPS_TOOLS12_ID;
    else
      aGcoGoodId_Tool12  := GcoGoodId_Tool12;
    end if;

    -- Outil 13
    if nvl(GcoGoodId_Tool13, 0) = 0 then
      aGcoGoodId_Tool13  := curOperation.PPS_TOOLS13_ID;
    else
      aGcoGoodId_Tool13  := GcoGoodId_Tool13;
    end if;

    -- Outil 14
    if nvl(GcoGoodId_Tool14, 0) = 0 then
      aGcoGoodId_Tool14  := curOperation.PPS_TOOLS14_ID;
    else
      aGcoGoodId_Tool14  := GcoGoodId_Tool14;
    end if;

    -- Outil 15
    if nvl(GcoGoodId_Tool15, 0) = 0 then
      aGcoGoodId_Tool15  := curOperation.PPS_TOOLS15_ID;
    else
      aGcoGoodId_Tool15  := GcoGoodId_Tool15;
    end if;

    aAdjustingTime  := AdjustingTime;
    aRejectPTQty    := RejectPTQty;
    aRejectCPTQty   := RejectCPTQty;
    aWorkTime       := WorkTime;
    aAmount         := Amount;

    -- Initialisation des qtés, temps et montants avec les valeurs théoriques de l'opération
    -- en fonction des configurations, pour le suivi manuel et pour le brouillard
    if    (    nvl(aFAL_LOT_PROGRESS_FOG_ID, 0) = 0
           and cInitOnOperationProgress)
       or (    nvl(aFAL_LOT_PROGRESS_FOG_ID, 0) > 0
           and cPFGInitOnOperationProgress) then
      -- Qté réalisée (garantit que aRealizedQty n'est pas null)
      if aRealizedQty is null then
        aRealizedQty  := curOperation.TAL_AVALAIBLE_QTY;
      end if;

      -- Réglage
      if    (aAdjustingTime is null)
         or (curOperation.C_TASK_TYPE = 2) then
        /* La config FAL_WORK_BALANCE est implicitement prise en compte à
          travers la valeur de FAL_TASK_LINK.TAL_TSK_AD_BALANCE.
          Une quantité fixe de réglage différente de 0 prédomine sur
          cette config. */
        if nvl(curOperation.SCS_QTY_FIX_ADJUSTING, 0) = 0 then
          aAdjustingTime  := curOperation.TAL_TSK_AD_BALANCE;
        else
          aAdjustingTime  :=
            FAL_TOOLS.RoundSuccInt( (aRealizedQty + nvl(aRejectPTQty, 0) + nvl(aRejectCPTQty, 0) ) / curOperation.SCS_QTY_FIX_ADJUSTING) *
            curOperation.SCS_ADJUSTING_TIME;
        end if;
      end if;

      -- Travail
      if    (aWorkTime is null)
         or (curOperation.C_TASK_TYPE = 2) then
        aWorkTime  := ( (aRealizedQty + nvl(aRejectPTQty, 0) + nvl(aRejectCPTQty, 0) ) / curOperation.SCS_QTY_REF_WORK) * curOperation.SCS_WORK_TIME;
      end if;

      -- Montant
      if    (aAmount is null)
         or (curOperation.C_TASK_TYPE = 2) then
        if nvl(curOperation.SCS_DIVISOR_AMOUNT, 0) = 1 then
          aAmount  := ( (aRealizedQty + nvl(aRejectPTQty, 0) + nvl(aRejectCPTQty, 0) ) / curOperation.SCS_QTY_REF_AMOUNT) * curOperation.SCS_AMOUNT;
        else
          aAmount  := ( (aRealizedQty + nvl(aRejectPTQty, 0) + nvl(aRejectCPTQty, 0) ) * curOperation.SCS_QTY_REF_AMOUNT) * curOperation.SCS_AMOUNT;
        end if;
      end if;
    else
      -- Réglage
      if    (aAdjustingTime is null)
         or (curOperation.C_TASK_TYPE = 2) then
        aAdjustingTime  := 0;
      end if;

      -- Travail
      if    (aWorkTime is null)
         or (curOperation.C_TASK_TYPE = 2) then
        aWorkTime  := 0;
      end if;

      -- Montant
      if    (aAmount is null)
         or (curOperation.C_TASK_TYPE = 2) then
        aAmount  := 0;
      end if;
    end if;

    -- Garantit que ces variables ne sont pas null
    aRealizedQty    := nvl(aRealizedQty, 0);
    aAdjustingTime  := nvl(aAdjustingTime, 0);
    aWorkTime       := nvl(aWorkTime, 0);
    aAmount         := nvl(aAmount, 0);

    if cMultiplUnit then
      if ProductQtyUOP is not null then
        aRealizedQty  := ProductQtyUOP / curOperation.SCS_CONVERSION_FACTOR;
      end if;

      if PTRejectQtyUOP is not null then
        aRejectPTQty  := PTRejectQtyUOP / curOperation.SCS_CONVERSION_FACTOR;
      end if;

      if CPTRejectQtyUOP is not null then
        aRejectCPTQty  := CPTRejectQtyUOP / curOperation.SCS_CONVERSION_FACTOR;
      end if;
    end if;

    -- Vérifier que la quantité saisie n'est pas négative
    if    (aRealizedQty < 0)
       or (aRejectPTQty < 0)
       or (aRejectCPTQty < 0) then
      return faNegativeQty;
    end if;

    -- Calcul de la quantité supplémentaire saisie
    aSupQty         := greatest(0,(aRealizedQty + nvl(aRejectPTQty, 0) + nvl(aRejectCPTQty, 0) ) - curOperation.TAL_AVALAIBLE_QTY);

    if aSupQty > 0 then
      -- Quantité suppl. autorisée selon config 'FAL_PFG_ALLOW_INCREASE_QTY'
      if not cPfgAllowIncreaseQty then
        return faNotEnoughAvailability;
      end if;

      -- Quantité suppl. autorisée uniquement si les quantités des opérations précédentes ont été saisies.
      if curOperation.TAL_DUE_QTY - curOperation.TAL_AVALAIBLE_QTY <> 0 then
        return faNotEnoughAvailability;
      end if;
    end if;

    if aError = faNoError then
      aFAL_LOT_PROGRESS_ID  := GetNewId;

      insert into FAL_LOT_PROGRESS
                  (FAL_LOT_PROGRESS_ID
                 , FAL_LOT_ID
                 , LOT_REFCOMPL
                 , FAL_SCHEDULE_STEP_ID
                 , FAL_TASK_ID
                 , FAL_FACTORY_FLOOR_ID
                 , FAL_FAL_FACTORY_FLOOR_ID
                 , FLP_RATE
                 , PPS_OPERATION_PROCEDURE_ID
                 , PPS_PPS_OPERATION_PROCEDURE_ID
                 , PPS_TOOLS1_ID
                 , PPS_TOOLS2_ID
                 , PPS_TOOLS3_ID
                 , PPS_TOOLS4_ID
                 , PPS_TOOLS5_ID
                 , PPS_TOOLS6_ID
                 , PPS_TOOLS7_ID
                 , PPS_TOOLS8_ID
                 , PPS_TOOLS9_ID
                 , PPS_TOOLS10_ID
                 , PPS_TOOLS11_ID
                 , PPS_TOOLS12_ID
                 , PPS_TOOLS13_ID
                 , PPS_TOOLS14_ID
                 , PPS_TOOLS15_ID
                 , DIC_WORK_TYPE_ID
                 , FLP_SEQ
                 , FLP_SEQ_ORIGIN
                 , FLP_SHORT_DESCR
                 , FLP_DATE1
                 , FLP_PRODUCT_QTY
                 , FLP_PT_REJECT_QTY
                 , FLP_CPT_REJECT_QTY
                 , FLP_ADJUSTING_TIME
                 , FLP_WORK_TIME
                 , FLP_AMOUNT
                 , FLP_SUP_QTY
                 , DIC_FREE_TASK_CODE_ID
                 , DIC_FREE_TASK_CODE2_ID
                 , FLP_ADJUSTING_RATE
                 , FLP_QTY_REF2_WORK
                 , DIC_UNIT_OF_MEASURE_ID
                 , FLP_CONVERSION_FACTOR
                 , DIC_OPERATOR_ID
                 , DIC_REBUT_ID
                 , FLP_EAN_CODE
                 , FLP_PRODUCT_QTY_UOP
                 , FLP_PT_REJECT_QTY_UOP
                 , FLP_CPT_REJECT_QTY_UOP
                 , FLP_LABEL_CONTROL
                 , FLP_LABEL_REJECT
                 , FLP_MANUAL
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (   -- FAL_LOT_PROGRESS_ID
                   aFAL_LOT_PROGRESS_ID
                 ,   -- FAL_LOT_ID
                   FalLotId
                 ,   -- LOT_REFCOMPL
                   LotRefcompl
                 ,   -- FAL_SCHEDULE_STEP_ID
                   FalTaskLinkId
                 ,   -- FAL_TASK_ID
                   curOperation.FAL_TASK_ID
                 ,   -- FAL_FACTORY_FLOOR_ID,
                   aFalFactoryFloorId
                 ,   -- FAL_FAL_FACTORY_FLOOR_ID,
                   aFalFactoryFloor2Id
                 ,   -- FLP_RATE
                   aFactoryRate
                 ,   -- PPS_OPERATION_PROCEDURE_ID
                   aPpsOperationProcId_Execution
                 ,   -- PPS_PPS_OPERATION_PROCEDURE_ID
                   aPpsOperationProcId_Control
                 ,   -- PPS_TOOLS1_ID
                   aGcoGoodId_Tool1
                 ,   -- PPS_TOOLS2_ID
                   aGcoGoodId_Tool2
                 ,   -- PPS_TOOLS3_ID
                   aGcoGoodId_Tool3
                 ,   -- PPS_TOOLS4_ID
                   aGcoGoodId_Tool4
                 ,   -- PPS_TOOLS5_ID
                   aGcoGoodId_Tool5
                 ,   -- PPS_TOOLS6_ID
                   aGcoGoodId_Tool6
                 ,   -- PPS_TOOLS7_ID
                   aGcoGoodId_Tool7
                 ,   -- PPS_TOOLS8_ID
                   aGcoGoodId_Tool8
                 ,   -- PPS_TOOLS9_ID
                   aGcoGoodId_Tool9
                 ,   -- PPS_TOOLS10_ID
                   aGcoGoodId_Tool10
                 ,   -- PPS_TOOLS11_ID
                   aGcoGoodId_Tool11
                 ,   -- PPS_TOOLS12_ID
                   aGcoGoodId_Tool12
                 ,   -- PPS_TOOLS13_ID
                   aGcoGoodId_Tool13
                 ,   -- PPS_TOOLS14_ID
                   aGcoGoodId_Tool14
                 ,   -- PPS_TOOLS15_ID
                   aGcoGoodId_Tool15
                 ,   -- DIC_WORK_TYPE_ID
                   DicWorkType
                 ,   -- FLP_SEQ
                   curOperation.SCS_STEP_NUMBER
                 ,   -- FLP_SEQ_ORIGIN
                   curOperation.TAL_SEQ_ORIGIN
                 ,   -- FLP_SHORT_DESCR
                   curOperation.SCS_SHORT_DESCR
                 ,   -- FLP_DATE1
                   nvl(aDate, sysdate)
                 ,   -- FLP_PRODUCT_QTY
                   aRealizedQty
                 ,   -- FLP_PT_REJECT_QTY
                   aRejectPTQty
                 ,   -- FLP_CPT_REJECT_QTY
                   aRejectCPTQty
                 ,   -- FLP_ADJUSTING_TIME
                   aAdjustingTime
                 ,   -- FLP_WORK_TIME
                   aWorkTime
                 ,   -- FLP_AMOUNT
                   aAmount
                 ,   -- FLP_SUP_QTY
                   aSupQty
                 ,   -- DIC_FREE_TASK_CODE_ID
                   curOperation.DIC_FREE_TASK_CODE_ID
                 ,   -- DIC_FREE_TASK_CODE2_ID
                   curOperation.DIC_FREE_TASK_CODE2_ID
                 ,   -- FLP_ADJUSTING_RATE
                   curOperation.SCS_ADJUSTING_RATE
                 ,   -- FLP_QTY_REF2_WORK
                   curOperation.SCS_QTY_REF2_WORK
                 ,   -- DIC_UNIT_OF_MEASURE_ID
                   curOperation.DIC_UNIT_OF_MEASURE_ID
                 ,   -- FLP_CONVERSION_FACTOR
                   curOperation.SCS_CONVERSION_FACTOR
                 ,   -- DIC_OPERATOR_ID
                   aOperator
                 ,   -- DIC_REBUT_ID
                   RejectCode
                 ,   -- FLP_EAN_CODE
                   EanCode
                 ,   -- FLP_PRODUCT_QTY_UOP
                   ProductQtyUOP
                 ,   -- FLP_PT_REJECT_QTY_UOP
                   PTRejectQtyUOP
                 ,   -- FLP_CPT_REJECT_QTY_UOP
                   CPTRejectQtyUOP
                 , aPFG_LABEL_CONTROL
                 , aPFG_LABEL_REJECT
                 , aManualProgressTrack
                 ,   -- A_DATECRE
                   sysdate
                 ,   -- A_IDCRE
                   PCS.PC_I_LIB_SESSION.GetUserIni
                  );

      -- Imputation automatique en finance
      if upper(PCS.PC_CONFIG.GetConfig('FAL_AUTO_ACI_TIME_ENTRY') ) = 'TRUE' then
        FAL_ACI_TIME_ENTRY_FCT.ProcessBatch(FalLotId, aError);
      end if;
    end if;

    return aError;
  end CreateAdvancement;

/*
  Processus : Mise à jour LienTacheLotPseudo
  Graphe d'evenements : Création Saisie Opérations
*/
  procedure UpdateBatchOperation(
    aFAL_SCHEDULE_STEP_ID number
  , aFLP_PRODUCT_QTY      number
  , aFLP_PT_REJECT_QTY    number
  , aFLP_CPT_REJECT_QTY   number
  , aFLP_SUP_QTY          number
  , aFLP_WORK_TIME        number
  , aFLP_ADJUSTING_TIME   number
  , aFLP_AMOUNT           number
  , aFLP_DATE1            date
  , aContext              integer
  )
  is
    cursor Cur_Operation
    is
      select nvl(TAL_PLAN_QTY, 0) TAL_PLAN_QTY
           , FFF.PAC_CALENDAR_TYPE_ID
           , FFF.PAC_SCHEDULE_ID
           , FFF.FAL_FACTORY_FLOOR_ID
           , nvl(TAL_RELEASE_QTY, 0) TAL_RELEASE_QTY
           , nvl(TAL_REJECTED_QTY, 0) TAL_REJECTED_QTY
           , nvl(TAL_R_METER, 0) TAL_R_METER
           , case nvl(SCS_QTY_REF_AMOUNT, 0)
               when 0 then 1
               else SCS_QTY_REF_AMOUNT
             end SCS_QTY_REF_AMOUNT
           , case nvl(SCS_QTY_REF_WORK, 0)
               when 0 then 1
               else SCS_QTY_REF_WORK
             end SCS_QTY_REF_WORK
           , SCS_PLAN_RATE
           , nvl(TAL_ACHIEVED_TSK, 0) TAL_ACHIEVED_TSK
           , nvl(TAL_TSK_AD_BALANCE, 0) TAL_TSK_AD_BALANCE
           , nvl(TAL_TSK_W_BALANCE, 0) TAL_TSK_W_BALANCE
           , SCS_QTY_FIX_ADJUSTING
           , SCS_ADJUSTING_TIME
           , SCS_WORK_TIME
           , TAL_BEGIN_REAL_DATE
           , TAL_END_REAL_DATE
           , TAL_TASK_REAL_TIME
           , PAC_SUPPLIER_PARTNER_ID
           , FTL.C_TASK_TYPE
           , FTL.TAL_SUBCONTRACT_QTY
           , FTL.TAL_AVALAIBLE_QTY
           , TAL_CONFIRM_DATE
           , TAL_CONFIRM_DESCR
        from FAL_TASK_LINK FTL
           , FAL_FACTORY_FLOOR FFF
       where FTL.FAL_FACTORY_FLOOR_ID = FFF.FAL_FACTORY_FLOOR_ID(+)
         and FAL_SCHEDULE_STEP_ID = aFAL_SCHEDULE_STEP_ID;

    CurOperation         Cur_Operation%rowtype;
    aTAL_RELEASE_QTY     number;
    aTAL_REJECTED_QTY    number;
    aTAL_DUE_QTY         number;
    aTAL_PLAN_RATE       number;
    aSCS_PLAN_RATE       number;
    aTAL_ACHIEVED_TSK    number;
    aTAL_TSK_AD_BALANCE  number;
    aTAL_TSK_W_BALANCE   number;
    aTAL_BEGIN_REAL_DATE date;
    aTAL_END_REAL_DATE   date;
    aTAL_TASK_REAL_TIME  number;
    aTAL_SUBCONTRACT_QTY number;
    aTAL_AVALAIBLE_QTY   number;
    aTAL_CONFIRM_DATE    FAL_TASK_LINK.TAL_CONFIRM_DATE%type;
    aTAL_CONFIRM_DESCR   FAL_TASK_LINK.TAL_CONFIRM_DESCR%type;
    Z                    number;
  begin
    open Cur_Operation;

    fetch Cur_Operation
     into CurOperation;

    close Cur_Operation;

    -- Qté réalisée
    aTAL_RELEASE_QTY      := CurOperation.TAL_RELEASE_QTY + aFLP_PRODUCT_QTY;
    -- Qté rebut
    aTAL_REJECTED_QTY     := CurOperation.TAL_REJECTED_QTY + aFLP_PT_REJECT_QTY + aFLP_CPT_REJECT_QTY;
    -- Qté solde
    aTAL_DUE_QTY          :=
      greatest( (CurOperation.TAL_PLAN_QTY + aFLP_SUP_QTY) -
               (CurOperation.TAL_RELEASE_QTY + aFLP_PRODUCT_QTY) -
               (CurOperation.TAL_R_METER + aFLP_PT_REJECT_QTY + aFLP_CPT_REJECT_QTY)
             , 0
              );
    -- Travail réalisé
    aTAL_ACHIEVED_TSK     := CurOperation.TAL_ACHIEVED_TSK + aFLP_WORK_TIME;

    -- Cadencement et Nbre unités de cadencement
    if     cProgressTime
       and (aFLP_PRODUCT_QTY + aFLP_PT_REJECT_QTY + aFLP_CPT_REJECT_QTY = 0) then
      aTAL_PLAN_RATE  := 0;
      aSCS_PLAN_RATE  := 0;
    else
      aTAL_PLAN_RATE  := (aTAL_DUE_QTY / CurOperation.SCS_QTY_REF_WORK) * CurOperation.SCS_PLAN_RATE;
      aSCS_PLAN_RATE  := CurOperation.SCS_PLAN_RATE;
    end if;

    if    (aTAL_DUE_QTY = 0)
       or (CurOperation.C_TASK_TYPE = '2') then
      aTAL_TSK_AD_BALANCE  := 0;
      aTAL_TSK_W_BALANCE   := 0;
    else
      if     cProgressTime
         and (aFLP_PRODUCT_QTY + aFLP_PT_REJECT_QTY + aFLP_CPT_REJECT_QTY = 0) then
        if cProgressMode = 1 then
          -- Solde Réglage
          aTAL_TSK_AD_BALANCE  := greatest(CurOperation.TAL_TSK_AD_BALANCE - aFLP_ADJUSTING_TIME, 0);
          -- Solde travail
          aTAL_TSK_W_BALANCE   := greatest(CurOperation.TAL_TSK_W_BALANCE - aFLP_WORK_TIME, 0);
        else
          /* La config FAL_PROGRESS_MODE = 0 => Saisie uniquement d'un seul temps,
             cumulant le réglage et le travail, dans le temps travail réalisé. */
          -- Solde Réglage
          Z                    := CurOperation.TAL_TSK_AD_BALANCE - aFLP_WORK_TIME;
          -- On "consomme" du réglage, et s'il en reste, on "consomme" du travail
          aTAL_TSK_AD_BALANCE  := greatest(Z, 0);

          -- Solde travail (Idem Z et X dans Delphi et l'analyse)
          if Z < 0 then
            aTAL_TSK_W_BALANCE  := greatest(CurOperation.TAL_TSK_W_BALANCE + Z, 0);
          else
            aTAL_TSK_W_BALANCE  := CurOperation.TAL_TSK_W_BALANCE;
          end if;
        end if;
      else
        -- Solde travail
        aTAL_TSK_W_BALANCE  := (aTAL_DUE_QTY / CurOperation.SCS_QTY_REF_WORK) * CurOperation.SCS_WORK_TIME;

        if nvl(CurOperation.SCS_QTY_FIX_ADJUSTING, 0) = 0 then
          -- Solde réglage
          if cWorkBalance then
            if (     ( (aTAL_RELEASE_QTY + aTAL_REJECTED_QTY) = 0)
                and (aTAL_ACHIEVED_TSK = 0) ) then
              /* Si la config FAL_PROGRESS_MODE = 0 (Saisie uniquement d'un seul temps,
                 cumulant le réglage et le travail, dans le temps travail réalisé)
                 alors aTAL_ACHIEVED_TSK est forcément <> 0 (puisque incluant le
                 temps de travail saisi sur l'avancement), donc on ne passe pas
                 ici. */
              aTAL_TSK_AD_BALANCE  := greatest(CurOperation.TAL_TSK_AD_BALANCE - aFLP_ADJUSTING_TIME, 0);
            else
              aTAL_TSK_AD_BALANCE  := 0;
            end if;
          else
            aTAL_TSK_AD_BALANCE  := CurOperation.SCS_ADJUSTING_TIME;
          end if;
        else
          aTAL_TSK_AD_BALANCE  :=(FAL_TOOLS.RoundSuccInt(aTAL_DUE_QTY / CurOperation.SCS_QTY_FIX_ADJUSTING) * CurOperation.SCS_ADJUSTING_TIME);
        end if;
      end if;
    end if;

    -- Date début réelle
    aTAL_BEGIN_REAL_DATE  := nvl(CurOperation.TAL_BEGIN_REAL_DATE, aFLP_DATE1);

    -- Date fin réelle
    if aTAL_DUE_QTY = 0 then
      aTAL_END_REAL_DATE  := aFLP_DATE1;
    else
      aTAL_END_REAL_DATE  := CurOperation.TAL_END_REAL_DATE;
    end if;

    if aTAL_END_REAL_DATE is not null then
      if CurOperation.C_TASK_TYPE = '1' then
        aTAL_TASK_REAL_TIME  :=
          FAL_SCHEDULE_FUNCTIONS.GetDuration(aFAL_FACTORY_FLOOR_ID      => CurOperation.FAL_FACTORY_FLOOR_ID
                                           , aPAC_SUPPLIER_PARTNER_ID   => null
                                           , aPAC_CUSTOM_PARTNER_ID     => null
                                           , aPAC_DEPARTMENT_ID         => null
                                           , aHRM_PERSON_ID             => null
                                           , aCalendarID                => nvl(CurOperation.PAC_SCHEDULE_ID, FAL_SCHEDULE_FUNCTIONS.GetDefaultCalendar)
                                           , aBeginDate                 => aTAL_BEGIN_REAL_DATE
                                           , aEndDate                   => aTAL_END_REAL_DATE
                                            );
      else
        aTAL_TASK_REAL_TIME  :=
          FAL_SCHEDULE_FUNCTIONS.GetDuration(aFAL_FACTORY_FLOOR_ID      => null
                                           , aPAC_SUPPLIER_PARTNER_ID   => CurOperation.PAC_SUPPLIER_PARTNER_ID
                                           , aPAC_CUSTOM_PARTNER_ID     => null
                                           , aPAC_DEPARTMENT_ID         => null
                                           , aHRM_PERSON_ID             => null
                                           , aCalendarID                => nvl(CurOperation.PAC_SCHEDULE_ID, FAL_SCHEDULE_FUNCTIONS.GetDefaultCalendar)
                                           , aBeginDate                 => aTAL_BEGIN_REAL_DATE
                                           , aEndDate                   => aTAL_END_REAL_DATE
                                            );
      end if;
    else
      aTAL_TASK_REAL_TIME  := CurOperation.TAL_TASK_REAL_TIME;
    end if;

    if     (aContext <> FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchSplitting)
       and (CurOperation.C_TASK_TYPE = '2') then
      aTAL_AVALAIBLE_QTY    := CurOperation.TAL_AVALAIBLE_QTY;
      aTAL_SUBCONTRACT_QTY  :=
                              greatest(nvl(CurOperation.TAL_SUBCONTRACT_QTY, 0) - aFLP_PRODUCT_QTY - aFLP_PT_REJECT_QTY - aFLP_CPT_REJECT_QTY + aFLP_SUP_QTY
                                     , 0);

      if aTAL_SUBCONTRACT_QTY = 0 then
        aTAL_CONFIRM_DATE   := null;
        aTAL_CONFIRM_DESCR  := null;
      else
        aTAL_CONFIRM_DATE   := CurOperation.TAL_CONFIRM_DATE;
        aTAL_CONFIRM_DESCR  := CurOperation.TAL_CONFIRM_DESCR;
      end if;
    else
      aTAL_AVALAIBLE_QTY    := greatest(nvl(CurOperation.TAL_AVALAIBLE_QTY, 0) - aFLP_PRODUCT_QTY - aFLP_PT_REJECT_QTY - aFLP_CPT_REJECT_QTY, 0);
      aTAL_SUBCONTRACT_QTY  := CurOperation.TAL_SUBCONTRACT_QTY;
      aTAL_CONFIRM_DATE     := CurOperation.TAL_CONFIRM_DATE;
      aTAL_CONFIRM_DESCR    := CurOperation.TAL_CONFIRM_DESCR;
    end if;

    update FAL_TASK_LINK
       set TAL_RELEASE_QTY = aTAL_RELEASE_QTY
         , TAL_REJECTED_QTY = aTAL_REJECTED_QTY
         , TAL_PLAN_QTY = nvl(TAL_PLAN_QTY, 0) + aFLP_SUP_QTY
         , TAL_R_METER = nvl(TAL_R_METER, 0) + aFLP_PT_REJECT_QTY + aFLP_CPT_REJECT_QTY
         , TAL_DUE_QTY = aTAL_DUE_QTY
         , TAL_AVALAIBLE_QTY = aTAL_AVALAIBLE_QTY
         , TAL_TSK_W_BALANCE = aTAL_TSK_W_BALANCE
         , TAL_TSK_AD_BALANCE = aTAL_TSK_AD_BALANCE
         , TAL_TSK_BALANCE = aTAL_TSK_W_BALANCE + aTAL_TSK_AD_BALANCE
         , TAL_ACHIEVED_TSK = aTAL_ACHIEVED_TSK
         , TAL_ACHIEVED_AD_TSK = nvl(TAL_ACHIEVED_AD_TSK, 0) + aFLP_ADJUSTING_TIME
         , TAL_PLAN_RATE = aTAL_PLAN_RATE
         , SCS_PLAN_RATE = aSCS_PLAN_RATE
         , TAL_BEGIN_REAL_DATE = aTAL_BEGIN_REAL_DATE
         , TAL_END_REAL_DATE = aTAL_END_REAL_DATE
         , TAL_TASK_REAL_TIME = aTAL_TASK_REAL_TIME
         , TAL_SUBCONTRACT_QTY = aTAL_SUBCONTRACT_QTY
         , TAL_CONFIRM_DATE = aTAL_CONFIRM_DATE
         , TAL_CONFIRM_DESCR = aTAL_CONFIRM_DESCR
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_SCHEDULE_STEP_ID = aFAL_SCHEDULE_STEP_ID;
  end UpdateBatchOperation;

/*
  Processus : Mise à jour Lien Tache Lot Pseudo Secondaire
  Graphe d'evenements : Création Saisie Opérations
*/
  procedure UpdateBatchSecondaryOperation(
    aFAL_SCHEDULE_STEP_ID number
  , aFLP_PRODUCT_QTY      number
  , aFLP_PT_REJECT_QTY    number
  , aFLP_CPT_REJECT_QTY   number
  , aFLP_SUP_QTY          number
  , aFLP_DATE1            date
  )
  is
    cursor Cur_Operation
    is
      select nvl(TAL_PLAN_QTY, 0) TAL_PLAN_QTY
           , FFF.PAC_CALENDAR_TYPE_ID
           , FFF.PAC_SCHEDULE_ID
           , FFF.FAL_FACTORY_FLOOR_ID
           , nvl(TAL_RELEASE_QTY, 0) TAL_RELEASE_QTY
           , nvl(TAL_REJECTED_QTY, 0) TAL_REJECTED_QTY
           , nvl(TAL_R_METER, 0) TAL_R_METER
           , case nvl(SCS_QTY_REF_AMOUNT, 0)
               when 0 then 1
               else SCS_QTY_REF_AMOUNT
             end SCS_QTY_REF_AMOUNT
           , case nvl(SCS_QTY_REF_WORK, 0)
               when 0 then 1
               else SCS_QTY_REF_WORK
             end SCS_QTY_REF_WORK
           , SCS_QTY_FIX_ADJUSTING
           , nvl(SCS_ADJUSTING_TIME, 0) SCS_ADJUSTING_TIME
           , nvl(SCS_WORK_TIME, 0) SCS_WORK_TIME
           , TAL_BEGIN_REAL_DATE
           , TAL_END_REAL_DATE
           , TAL_TASK_REAL_TIME
           , nvl(TAL_ACHIEVED_AD_TSK, 0) TAL_ACHIEVED_AD_TSK
           , nvl(TAL_TSK_AD_BALANCE, 0) TAL_TSK_AD_BALANCE
           , FTL.PAC_SUPPLIER_PARTNER_ID
           , FTL.C_TASK_TYPE
        from FAL_TASK_LINK FTL
           , FAL_FACTORY_FLOOR FFF
       where FTL.FAL_FACTORY_FLOOR_ID = FFF.FAL_FACTORY_FLOOR_ID(+)
         and FAL_SCHEDULE_STEP_ID = aFAL_SCHEDULE_STEP_ID;

    CurOperation         Cur_Operation%rowtype;
    aTAL_RELEASE_QTY     number;
    aTAL_REJECTED_QTY    number;
    aTAL_DUE_QTY         number;
    aTAL_PLAN_RATE       number;
    aSCS_PLAN_RATE       number;
    aTAL_TSK_AD_BALANCE  number;
    aTAL_TSK_W_BALANCE   number;
    aTAL_BEGIN_REAL_DATE date;
    aTAL_END_REAL_DATE   date;
    aTAL_TASK_REAL_TIME  number;
    aTAL_ACHIEVED_AD_TSK number;
  begin
    open Cur_Operation;

    fetch Cur_Operation
     into CurOperation;

    close Cur_Operation;

    -- Qté réalisée
    aTAL_RELEASE_QTY      := CurOperation.TAL_RELEASE_QTY + aFLP_PRODUCT_QTY;
    -- Qté solde
    aTAL_DUE_QTY          :=
                greatest( (CurOperation.TAL_PLAN_QTY + aFLP_SUP_QTY) -(aTAL_RELEASE_QTY) -(CurOperation.TAL_R_METER + aFLP_PT_REJECT_QTY + aFLP_CPT_REJECT_QTY)
                       , 0);

    -- Réglage réalisé
    /* La config FAL_WORK_BALANCE est implicitement prise en compte à travers
       la valeur de FAL_TASK_LINK.TAL_TSK_AD_BALANCE.
       Une quantité fixe de réglage différente de 0 prédomine sur cette config. */
    if nvl(CurOperation.SCS_QTY_FIX_ADJUSTING, 0) = 0 then
      aTAL_ACHIEVED_AD_TSK  := CurOperation.TAL_ACHIEVED_AD_TSK + CurOperation.TAL_TSK_AD_BALANCE;
    else
      aTAL_ACHIEVED_AD_TSK  :=
             CurOperation.TAL_ACHIEVED_AD_TSK
             +(FAL_TOOLS.RoundSuccInt(aFLP_PRODUCT_QTY / CurOperation.SCS_QTY_FIX_ADJUSTING) * CurOperation.SCS_ADJUSTING_TIME);
    end if;

    if aTAL_DUE_QTY = 0 then
      aTAL_TSK_AD_BALANCE  := 0;
      aTAL_TSK_W_BALANCE   := 0;
    else
      if nvl(CurOperation.SCS_QTY_FIX_ADJUSTING, 0) = 0 then
        if     cWorkBalance
           and (aTAL_ACHIEVED_AD_TSK > 0) then
          aTAL_TSK_AD_BALANCE  := 0;
        else
          aTAL_TSK_AD_BALANCE  := CurOperation.SCS_ADJUSTING_TIME;
        end if;
      else
        aTAL_TSK_AD_BALANCE  :=(FAL_TOOLS.RoundSuccInt(aTAL_DUE_QTY / CurOperation.SCS_QTY_FIX_ADJUSTING) * CurOperation.SCS_ADJUSTING_TIME);
      end if;

      -- Solde travail
      aTAL_TSK_W_BALANCE  := (aTAL_DUE_QTY / CurOperation.SCS_QTY_REF_WORK) * CurOperation.SCS_WORK_TIME;
    end if;

    -- Date début réelle
    aTAL_BEGIN_REAL_DATE  := nvl(CurOperation.TAL_BEGIN_REAL_DATE, aFLP_DATE1);

    -- Date fin réelle
    if aTAL_DUE_QTY = 0 then
      aTAL_END_REAL_DATE  := aFLP_DATE1;
    else
      aTAL_END_REAL_DATE  := CurOperation.TAL_END_REAL_DATE;
    end if;

    if aTAL_END_REAL_DATE is not null then
      if CurOperation.C_TASK_TYPE = '1' then
        aTAL_TASK_REAL_TIME  :=
          FAL_SCHEDULE_FUNCTIONS.GetDuration(aFAL_FACTORY_FLOOR_ID      => CurOperation.FAL_FACTORY_FLOOR_ID
                                           , aPAC_SUPPLIER_PARTNER_ID   => null
                                           , aPAC_CUSTOM_PARTNER_ID     => null
                                           , aPAC_DEPARTMENT_ID         => null
                                           , aHRM_PERSON_ID             => null
                                           , aCalendarID                => nvl(CurOperation.PAC_SCHEDULE_ID, FAL_SCHEDULE_FUNCTIONS.getdefaultcalendar)
                                           , aBeginDate                 => aTAL_BEGIN_REAL_DATE
                                           , aEndDate                   => aTAL_END_REAL_DATE
                                            );
      else
        aTAL_TASK_REAL_TIME  :=
          FAL_SCHEDULE_FUNCTIONS.GetDuration(aFAL_FACTORY_FLOOR_ID      => null
                                           , aPAC_SUPPLIER_PARTNER_ID   => CurOperation.PAC_SUPPLIER_PARTNER_ID
                                           , aPAC_CUSTOM_PARTNER_ID     => null
                                           , aPAC_DEPARTMENT_ID         => null
                                           , aHRM_PERSON_ID             => null
                                           , aCalendarID                => nvl(CurOperation.PAC_SCHEDULE_ID, FAL_SCHEDULE_FUNCTIONS.getdefaultcalendar)
                                           , aBeginDate                 => aTAL_BEGIN_REAL_DATE
                                           , aEndDate                   => aTAL_END_REAL_DATE
                                            );
      end if;
    else
      aTAL_TASK_REAL_TIME  := CurOperation.TAL_TASK_REAL_TIME;
    end if;

    update FAL_TASK_LINK
       set TAL_RELEASE_QTY = aTAL_RELEASE_QTY
         , TAL_R_METER = nvl(TAL_R_METER, 0) + aFLP_PT_REJECT_QTY + aFLP_CPT_REJECT_QTY
         , TAL_PLAN_QTY = nvl(TAL_PLAN_QTY, 0) + aFLP_SUP_QTY
         , TAL_DUE_QTY = aTAL_DUE_QTY
         , TAL_ACHIEVED_TSK = nvl(TAL_ACHIEVED_TSK, 0) +( (aFLP_PRODUCT_QTY / CurOperation.SCS_QTY_REF_WORK) * SCS_WORK_TIME)
         , TAL_ACHIEVED_AD_TSK = aTAL_ACHIEVED_AD_TSK
         , TAL_TSK_W_BALANCE = aTAL_TSK_W_BALANCE
         , TAL_TSK_AD_BALANCE = aTAL_TSK_AD_BALANCE
         , TAL_TSK_BALANCE = aTAL_TSK_W_BALANCE + aTAL_TSK_AD_BALANCE
         , TAL_PLAN_RATE = (aTAL_DUE_QTY / CurOperation.SCS_QTY_REF_WORK) * SCS_PLAN_RATE
         , TAL_BEGIN_REAL_DATE = aTAL_BEGIN_REAL_DATE
         , TAL_END_REAL_DATE = aTAL_END_REAL_DATE
         , TAL_TASK_REAL_TIME = aTAL_TASK_REAL_TIME
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_SCHEDULE_STEP_ID = aFAL_SCHEDULE_STEP_ID;
  end UpdateBatchSecondaryOperation;

  procedure UpdateBatchSecondaryOperations(
    aFalLotId           number
  , aScsStepNumber      number
  , aFLP_PRODUCT_QTY    number
  , aFLP_PT_REJECT_QTY  number
  , aFLP_CPT_REJECT_QTY number
  , aFLP_SUP_QTY        number
  , aFLP_DATE1          date
  )
  is
    cursor Cur_OperationAsc
    is
      select   FAL_SCHEDULE_STEP_ID
             , C_OPERATION_TYPE
          from FAL_TASK_LINK
         where FAL_LOT_ID = aFalLotId
           and SCS_STEP_NUMBER > aScsStepNumber
      order by SCS_STEP_NUMBER asc;

    cursor Cur_OperationDesc
    is
      select   FAL_SCHEDULE_STEP_ID
             , C_OPERATION_TYPE
          from FAL_TASK_LINK
         where FAL_LOT_ID = aFalLotId
           and SCS_STEP_NUMBER < aScsStepNumber
      order by SCS_STEP_NUMBER desc;
  begin
    if cPpsAscDsc = 1 then
      for CurOperation in Cur_OperationDesc loop
        if CurOperation.C_OPERATION_TYPE = 1 then
          exit;
        end if;

        if CurOperation.C_OPERATION_TYPE = 2 then
          UpdateBatchSecondaryOperation(CurOperation.FAL_SCHEDULE_STEP_ID, aFLP_PRODUCT_QTY, aFLP_PT_REJECT_QTY, aFLP_CPT_REJECT_QTY, aFLP_SUP_QTY, aFLP_DATE1);
        end if;
      end loop;
    else
      for CurOperation in Cur_OperationAsc loop
        if CurOperation.C_OPERATION_TYPE = 1 then
          exit;
        end if;

        if CurOperation.C_OPERATION_TYPE = 2 then
          UpdateBatchSecondaryOperation(CurOperation.FAL_SCHEDULE_STEP_ID, aFLP_PRODUCT_QTY, aFLP_PT_REJECT_QTY, aFLP_CPT_REJECT_QTY, aFLP_SUP_QTY, aFLP_DATE1);
        end if;
      end loop;
    end if;
  end UpdateBatchSecondaryOperations;

  /* Processus : Mise à jour LienTacheLotPseudo CompteurR
     (Processus_MiseAjourLienTacheLotPseudoCompteurR)      */
  procedure UpdateRMeterOperation(aFAL_SCHEDULE_STEP_ID number, aFLP_PT_REJECT_QTY number, aFLP_CPT_REJECT_QTY number, aFLP_SUP_QTY number)
  is
    cursor Cur_Operation
    is
      select nvl(TAL_PLAN_QTY, 0) TAL_PLAN_QTY
           , nvl(TAL_RELEASE_QTY, 0) TAL_RELEASE_QTY
           , nvl(TAL_R_METER, 0) TAL_R_METER
           , case nvl(SCS_QTY_REF_WORK, 0)
               when 0 then 1
               else SCS_QTY_REF_WORK
             end SCS_QTY_REF_WORK
           , case nvl(SCS_QTY_REF_AMOUNT, 0)
               when 0 then 1
               else SCS_QTY_REF_AMOUNT
             end SCS_QTY_REF_AMOUNT
           , SCS_QTY_FIX_ADJUSTING
           , SCS_ADJUSTING_TIME
           , SCS_WORK_TIME
           , nvl(TAL_TSK_AD_BALANCE, 0) TAL_TSK_AD_BALANCE
        from FAL_TASK_LINK
       where FAL_SCHEDULE_STEP_ID = aFAL_SCHEDULE_STEP_ID;

    CurOperation        Cur_Operation%rowtype;
    aTAL_DUE_QTY        number;
    aTAL_TSK_AD_BALANCE number;
    aTAL_TSK_W_BALANCE  number;
  begin
    open Cur_Operation;

    fetch Cur_Operation
     into CurOperation;

    close Cur_Operation;

    aTAL_DUE_QTY  :=
      greatest( (CurOperation.TAL_PLAN_QTY + aFLP_SUP_QTY) - CurOperation.TAL_RELEASE_QTY
               -(CurOperation.TAL_R_METER + aFLP_PT_REJECT_QTY + aFLP_CPT_REJECT_QTY)
             , 0
              );

    if aTAL_DUE_QTY = 0 then
      aTAL_TSK_AD_BALANCE  := 0;
      aTAL_TSK_W_BALANCE   := 0;
    else
      -- Solde réglage (si SCS_QTY_FIX_ADJUSTING = 0 alors le solde réglage ne
      -- dépend pas de la quantité solde donc on ne fait pas de mise à jour)
      if nvl(CurOperation.SCS_QTY_FIX_ADJUSTING, 0) = 0 then
        aTAL_TSK_AD_BALANCE  := CurOperation.TAL_TSK_AD_BALANCE;
      else
        aTAL_TSK_AD_BALANCE  := FAL_TOOLS.RoundSuccInt(aTAL_DUE_QTY / CurOperation.SCS_QTY_FIX_ADJUSTING) * CurOperation.SCS_ADJUSTING_TIME;
      end if;

      -- Solde Travail
      aTAL_TSK_W_BALANCE  := (aTAL_DUE_QTY / CurOperation.SCS_QTY_REF_WORK) * CurOperation.SCS_WORK_TIME;
    end if;

    update FAL_TASK_LINK
       set TAL_R_METER = nvl(TAL_R_METER, 0) + aFLP_PT_REJECT_QTY + aFLP_CPT_REJECT_QTY
         , TAL_PLAN_QTY = nvl(TAL_PLAN_QTY, 0) + aFLP_SUP_QTY
         , TAL_DUE_QTY = aTAL_DUE_QTY
         , TAL_TSK_AD_BALANCE = aTAL_TSK_AD_BALANCE
         , TAL_TSK_W_BALANCE = aTAL_TSK_W_BALANCE
         , TAL_TSK_BALANCE = aTAL_TSK_AD_BALANCE + aTAL_TSK_W_BALANCE
         , TAL_PLAN_RATE = (aTAL_DUE_QTY / CurOperation.SCS_QTY_REF_WORK) * SCS_PLAN_RATE
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_SCHEDULE_STEP_ID = aFAL_SCHEDULE_STEP_ID;
  end UpdateRMeterOperation;

  procedure UpdateRMeterSecondOperations(aFalLotId number, aScsStepNumber number, aFLP_PT_REJECT_QTY number, aFLP_CPT_REJECT_QTY number, aFLP_SUP_QTY number)
  is
    cursor Cur_OperationAsc
    is
      select   FAL_SCHEDULE_STEP_ID
             , C_OPERATION_TYPE
          from FAL_TASK_LINK
         where FAL_LOT_ID = aFalLotId
           and SCS_STEP_NUMBER > aScsStepNumber
      order by SCS_STEP_NUMBER asc;
  begin
    for CurOperation in Cur_OperationAsc loop
      if CurOperation.C_OPERATION_TYPE = 1 then
        exit;
      end if;

      if CurOperation.C_OPERATION_TYPE = 2 then
        UpdateRMeterOperation(CurOperation.FAL_SCHEDULE_STEP_ID, aFLP_PT_REJECT_QTY, aFLP_CPT_REJECT_QTY, aFLP_SUP_QTY);
      end if;
    end loop;
  end UpdateRMeterSecondOperations;

  /**
  * procedure UpdateNextPrincipalOperation
  * Description
  *    Met à jour la prochaine opération principale (C_OPERATION_TYPE = '1')
  *    Processus_MiseAjourLienTacheLotPseudoPrincipalSuivant
  * @created
  * @lastUpdate age 24.09.2013
  * @private
  * @param iSrcTaskLinkID      : ID de l'opération sur laquelle a été fait le suivi
  * @param iTaskLinkToUpdateID : ID de l'opération à mettre à jour
  * @param iPtRejectQty        : Quantité Rebut Produit terminé sur l'opération principale précédente
  * @param iCptRejectQty       : Quantité Rebut composant sur l'opération principale précédente
  * @param iSupQty             : Quantité supplémentaire produite sur l'opération principale précédente
  * @param iProductQty         : Quantité produite sur l'opération principale précédente
  */
  procedure updateNextPrincipalOperation(
    iSrcTaskLinkID      in FAL_LOT_PROGRESS.FAL_SCHEDULE_STEP_ID%type
  , iTaskLinkToUpdateID in FAL_LOT_PROGRESS.FAL_SCHEDULE_STEP_ID%type
  , iPtRejectQty        in FAL_LOT_PROGRESS.FLP_PT_REJECT_QTY%type
  , iCptRejectQty       in FAL_LOT_PROGRESS.FLP_CPT_REJECT_QTy%type
  , iSupQty             in FAL_LOT_PROGRESS.FLP_SUP_QTY%type
  , iProductQty         in FAL_LOT_PROGRESS.FLP_PRODUCT_QTY%type
  )
  is
    cursor curTaskLinkData
    is
      select nvl(TAL_PLAN_QTY, 0) TAL_PLAN_QTY
           , nvl(TAL_RELEASE_QTY, 0) TAL_RELEASE_QTY
           , nvl(TAL_REJECTED_QTY, 0) TAL_REJECTED_QTY
           , nvl(TAL_AVALAIBLE_QTY, 0) TAL_AVAILABLE_QTY
           , nvl(TAL_SUBCONTRACT_QTY, 0) TAL_SUBCONTRACT_QTY
           , nvl(TAL_R_METER, 0) TAL_R_METER
           , case nvl(SCS_QTY_REF_WORK, 0)
               when 0 then 1
               else SCS_QTY_REF_WORK
             end SCS_QTY_REF_WORK
           , case nvl(SCS_QTY_REF_AMOUNT, 0)
               when 0 then 1
               else SCS_QTY_REF_AMOUNT
             end SCS_QTY_REF_AMOUNT
           , SCS_QTY_FIX_ADJUSTING
           , SCS_ADJUSTING_TIME
           , SCS_WORK_TIME
           , nvl(TAL_TSK_AD_BALANCE, 0) TAL_TSK_AD_BALANCE
           , nvl(TAL_TSK_W_BALANCE, 0) TAL_TSK_W_BALANCE
           , C_TASK_TYPE
           , nvl(SCS_DIVISOR_AMOUNT, 0) SCS_DIVISOR_AMOUNT
           , nvl(SCS_AMOUNT, 0) SCS_AMOUNT
           , nvl(SCS_PLAN_RATE, 0) SCS_PLAN_RATE
        from FAL_TASK_LINK
       where FAL_SCHEDULE_STEP_ID = iTaskLinkToUpdateID;

    ltplTask                curTaskLinkData%rowtype;
    lDueQty                 FAL_TASK_LINK.TAL_DUE_QTY%type;   -- Quantité Solde
    lTskAdBalance           FAL_TASK_LINK.TAL_TSK_AD_BALANCE%type;   -- Solde Réglage
    lTskWBalance            FAL_TASK_LINK.TAL_TSK_W_BALANCE%type;   -- Solde Travail
    lQtyToAddToAvailableQty FAL_TASK_LINK.TAL_AVALAIBLE_QTY%type;   -- Quantité à ajouter à la quantité disponible de l'opération
    ltCRUD_DEF              FWK_I_TYP_DEFINITION.t_crud_def;
    lPreviousReleaseQty     FAL_TASK_LINK.TAL_RELEASE_QTY%type;
    lCurrentDoneQty         FAL_TASK_LINK.TAL_RELEASE_QTY%type;
    lCstFreeQty             FAL_TASK_LINK.TAL_RELEASE_QTY%type;
  begin
    open curTaskLinkData;

    fetch curTaskLinkData
     into ltplTask;

    close curTaskLinkData;

    -- Qté solde
    lDueQty  := greatest( (ltplTask.TAL_PLAN_QTY + iSupQty) - ltplTask.TAL_RELEASE_QTY -(ltplTask.TAL_R_METER + iPtRejectQty + iCptRejectQty), 0);

    if lDueQty = 0 then
      lTskAdBalance  := 0;
      lTskWBalance   := 0;
    else
      -- Solde réglage (si SCS_QTY_FIX_ADJUSTING = 0 alors le solde réglage ne dépend pas de la quantité solde donc on ne fait pas de mise à jour)
      if nvl(ltplTask.SCS_QTY_FIX_ADJUSTING, 0) = 0 then
        lTskAdBalance  := ltplTask.TAL_TSK_AD_BALANCE;
      else
        lTskAdBalance  := FAL_TOOLS.RoundSuccInt(lDueQty / ltplTask.SCS_QTY_FIX_ADJUSTING) * ltplTask.SCS_ADJUSTING_TIME;
      end if;

      lTskWBalance  := (lDueQty / ltplTask.SCS_QTY_REF_WORK) * ltplTask.SCS_WORK_TIME;
    end if;

    /* Calcul de la quantité à ajouter au disponible (TAL_AVALAIBLE_QTY) */
    if ltplTask.C_TASK_TYPE = '1' then
      lQtyToAddToAvailableQty  := iProductQty;
    else
      -- Quantité réalisée sur opération précédente
      lPreviousReleaseQty      := FAL_LIB_TASK_LINK.getReleaseQty(iTaskLinkID => iSrcTaskLinkID);
      -- Quantité réalisée + rebut sur opération courante
      lCurrentDoneQty          := ltplTask.TAL_RELEASE_QTY + ltplTask.TAL_REJECTED_QTY;
      -- Quantité libre sur CST (non attribuée)
      lCstFreeQty              := greatest(ltplTask.TAL_SUBCONTRACT_QTY - greatest(lPreviousReleaseQty - iProductQty - lCurrentDoneQty, 0), 0);
      -- Qté à ajouter au dispo = Qté du suivi - Qté libre sur CST
      lQtyToAddToAvailableQty  := greatest(iProductQty - lCstFreeQty, 0);
    end if;

    -- Mise à jour de l'opération
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalTaskLink, ltCRUD_DEF, true, iTaskLinkToUpdateID, null, 'FAL_SCHEDULE_STEP_ID');
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'TAL_AVALAIBLE_QTY', ltplTask.TAL_AVAILABLE_QTY + lQtyToAddToAvailableQty);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'TAL_R_METER', ltplTask.TAL_R_METER + iPtRejectQty + iCptRejectQty);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'TAL_PLAN_QTY', ltplTask.TAL_PLAN_QTY + iSupQty);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'TAL_DUE_QTY', lDueQty);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'TAL_TSK_AD_BALANCE', lTskAdBalance);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'TAL_TSK_W_BALANCE', lTskWBalance);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'TAL_TSK_BALANCE', lTskAdBalance + lTskWBalance);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'TAL_PLAN_RATE',(lDueQty / ltplTask.SCS_QTY_REF_WORK) * ltplTask.SCS_PLAN_RATE);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end updateNextPrincipalOperation;

  -- GraphePartie_MiseAJourLienTacheLotPseudoPrincipal
  procedure UpdateNextPrincipalOperations(
    aFalLotId              number
  , iTaskLinkID         in FAL_LOT_PROGRESS.FAL_SCHEDULE_STEP_ID%type
  , aScsStepNumber         number
  , aFLP_PT_REJECT_QTY     number
  , aFLP_CPT_REJECT_QTY    number
  , aFLP_SUP_QTY           number
  , aFLP_PRODUCT_QTY       number
  )
  is
    cursor Cur_OperationAsc(ScsStepNumber number)
    is
      select   FAL_SCHEDULE_STEP_ID
             , C_OPERATION_TYPE
             , SCS_STEP_NUMBER
          from FAL_TASK_LINK
         where FAL_LOT_ID = aFalLotId
           and SCS_STEP_NUMBER > ScsStepNumber
      order by SCS_STEP_NUMBER asc;

    newScsStepNumber number;
  begin
    for CurOperation in Cur_OperationAsc(aScsStepNumber) loop
      if CurOperation.C_OPERATION_TYPE = 1 then
        UpdateNextPrincipalOperation(iTaskLinkID, CurOperation.FAL_SCHEDULE_STEP_ID, aFLP_PT_REJECT_QTY, aFLP_CPT_REJECT_QTY, aFLP_SUP_QTY, aFLP_PRODUCT_QTY);
        newScsStepNumber  := CurOperation.SCS_STEP_NUMBER;
        exit;
      end if;
    end loop;

    for CurOperation in Cur_OperationAsc(newScsStepNumber) loop
      if CurOperation.C_OPERATION_TYPE <> 4 then
        UpdateRMeterOperation(CurOperation.FAL_SCHEDULE_STEP_ID, aFLP_PT_REJECT_QTY, aFLP_CPT_REJECT_QTY, aFLP_SUP_QTY);
      end if;
    end loop;
  end UpdateNextPrincipalOperations;

  -- Mise à jour des liens brouillard-pesées en suivi-pesées
  procedure UpdateWeighLinks(
    aLotProgressFogId in FAL_LOT_PROGRESS_FOG.FAL_LOT_PROGRESS_FOG_ID%type
  , aLotProgressId    in FAL_LOT_PROGRESS.FAL_LOT_PROGRESS_ID%type
  )
  is
  begin
    if aLotProgressFogId is not null then
      -- Mise à jour de l'id du suivi d'après l'id du brouillard pour les pesées
      -- effectuées en suivi par code-barre
      update FAL_WEIGH
         set FAL_LOT_PROGRESS_ID = aLotProgressId
       where FAL_LOT_PROGRESS_FOG_ID = aLotProgressFogId;
    end if;
  end UpdateWeighLinks;

  /**
   * procedure LienComposantLotPseudo
   * Description
   *   Mise à jour des composants d'OF lors d'une création ou d'une suppression de suivi de fabrication
   * @version 2003
   * @author CLE
   * @lastUpdate
   * @param deleteCoef  Coefficient qui prend une valuer "-1" lors d'une suppression
   */
  procedure UpdateBatchComponents(
    aFalLotId           number
  , aScsStepNumber      number
  , aFLP_PT_REJECT_QTY  number
  , aFLP_CPT_REJECT_QTY number
  , aFLP_SUP_QTY        number
  , deleteCoef          integer default 1
  )
  is
    cursor Cur_Components
    is
      select LOM.FAL_LOT_MATERIAL_LINK_ID
           , LOT.GCO_GOOD_ID GOOD_PT
           , nvl(LOT.LOT_INPROD_QTY, 0) LOT_INPROD_QTY
           , LOM.GCO_GOOD_ID GCO_GOOD_ID
           , nvl(LOM.LOM_BOM_REQ_QTY, 0) LOM_BOM_REQ_QTY
           , LOM_UTIL_COEF
           , nvl(LOM.LOM_REF_QTY, 0) LOM_REF_QTY
           , nvl(LOM.LOM_PT_REJECT_QTY, 0) LOM_PT_REJECT_QTY
           , nvl(LOM.LOM_CPT_TRASH_QTY, 0) LOM_CPT_TRASH_QTY
           , LOM.LOM_TASK_SEQ
           , nvl(LOM.LOM_ADJUSTED_QTY, 0) LOM_ADJUSTED_QTY
           , nvl(LOM.LOM_REJECTED_QTY, 0) LOM_REJECTED_QTY
           , nvl(LOM.LOM_BACK_QTY, 0) LOM_BACK_QTY
           , nvl(LOM.LOM_CONSUMPTION_QTY, 0) LOM_CONSUMPTION_QTY
           , nvl(LOM.LOM_NEED_QTY, 0) LOM_NEED_QTY
           , nvl(LOM.LOM_ADJUSTED_QTY_RECEIPT, 0) LOM_ADJUSTED_QTY_RECEIPT
           , nvl(LOM.LOM_CPT_RECOVER_QTY, 0) LOM_CPT_RECOVER_QTY
           , nvl(LOM.LOM_CPT_REJECT_QTY, 0) LOM_CPT_REJECT_QTY
           , nvl(LOM.LOM_EXIT_RECEIPT, 0) LOM_EXIT_RECEIPT
        from FAL_LOT_MATERIAL_LINK LOM
           , FAL_LOT LOT
       where LOT.FAL_LOT_ID = LOM.FAL_LOT_ID
         and LOT.FAL_LOT_ID = aFalLotId
         and LOM.C_TYPE_COM = '1'
         and LOM.C_KIND_COM = '1'
         and LOM.LOM_STOCK_MANAGEMENT = 1;

    OriginalProcessPlan   number;
    ProcessPlanInRelation number;
    ProcessPlanIdentical  boolean;
    aNumberOfDecimal      number;
    A                     number;
    aLOM_BOM_REQ_QTY      number;
    aLOM_PT_REJECT_QTY    number;
    aLOM_CPT_TRASH_QTY    number;
    aLOM_ADJUSTED_QTY     number;
    aLOM_FULL_REQ_QTY     number;
    aLOM_NEED_QTY         number;
    aLOM_MAX_RECEIPT_QTY  number;
  begin
    select FAL_SCHEDULE_PLAN_ID
         , FAL_FAL_SCHEDULE_PLAN_ID
      into OriginalProcessPlan
         , ProcessPlanInRelation
      from FAL_LOT
     where FAL_LOT_ID = aFalLotId;

    ProcessPlanIdentical  :=(nvl(OriginalProcessPlan, 0) = nvl(ProcessPlanInRelation, 0) );

    for CurComponents in Cur_Components loop
      aNumberOfDecimal      := FAL_TOOLS.GetGoo_Number_Of_Decimal(CurComponents.GCO_GOOD_ID);
      aLOM_BOM_REQ_QTY      :=
        round(CurComponents.LOM_BOM_REQ_QTY +
              deleteCoef * FAL_TOOLS.ArrondiSuperieur( (aFLP_SUP_QTY * CurComponents.LOM_UTIL_COEF) / CurComponents.LOM_REF_QTY, CurComponents.GCO_GOOD_ID)
            , aNumberOfDecimal
             );
      -- Qté rebut PT
      aLOM_PT_REJECT_QTY    :=
        round(CurComponents.LOM_PT_REJECT_QTY +
              deleteCoef
              * FAL_TOOLS.ArrondiSuperieur( (aFLP_PT_REJECT_QTY * CurComponents.LOM_UTIL_COEF) / CurComponents.LOM_REF_QTY, CurComponents.GCO_GOOD_ID)
            , aNumberOfDecimal
             );
      -- Qté rebut CPT
      aLOM_CPT_TRASH_QTY    :=
        round(CurComponents.LOM_CPT_TRASH_QTY +
              deleteCoef *
              FAL_TOOLS.ArrondiSuperieur( (aFLP_CPT_REJECT_QTY * CurComponents.LOM_UTIL_COEF) / CurComponents.LOM_REF_QTY, CurComponents.GCO_GOOD_ID)
            , aNumberOfDecimal
             );

      -- Qté SupINF
      if     ProcessPlanIdentical
         and (CurComponents.LOM_TASK_SEQ > aScsStepNumber) then
        aLOM_ADJUSTED_QTY  :=
          round(CurComponents.LOM_ADJUSTED_QTY -
                deleteCoef *
                FAL_TOOLS.ArrondiSuperieur( ( (aFLP_PT_REJECT_QTY + aFLP_CPT_REJECT_QTY) * CurComponents.LOM_UTIL_COEF / CurComponents.LOM_REF_QTY)
                                         , CurComponents.GCO_GOOD_ID
                                          ) -
                deleteCoef * FAL_TOOLS.ArrondiSuperieur(aFLP_SUP_QTY, CurComponents.GCO_GOOD_ID)
              , aNumberOfDecimal
               );
      else
        aLOM_ADJUSTED_QTY  :=
          round(CurComponents.LOM_ADJUSTED_QTY -
                deleteCoef * FAL_TOOLS.ArrondiSuperieur( (aFLP_SUP_QTY * CurComponents.LOM_UTIL_COEF) / CurComponents.LOM_REF_QTY, CurComponents.GCO_GOOD_ID)
              , aNumberOfDecimal
               );
      end if;

      -- quantité besoin totale
      aLOM_FULL_REQ_QTY     := aLOM_BOM_REQ_QTY + aLOM_ADJUSTED_QTY;

      -- Besoin CPT
      if ProcessPlanIdentical then
        if aLOM_ADJUSTED_QTY < 0 then
          aLOM_NEED_QTY  := aLOM_FULL_REQ_QTY + CurComponents.LOM_REJECTED_QTY + CurComponents.LOM_BACK_QTY - CurComponents.LOM_CONSUMPTION_QTY;
        else
          aLOM_NEED_QTY  :=
            aLOM_FULL_REQ_QTY + greatest(CurComponents.LOM_REJECTED_QTY - aLOM_ADJUSTED_QTY, 0) + CurComponents.LOM_BACK_QTY
            - CurComponents.LOM_CONSUMPTION_QTY;
        end if;
      else
        aLOM_NEED_QTY  := CurComponents.LOM_NEED_QTY;   --Pas de mises a jour
      end if;

      aLOM_MAX_RECEIPT_QTY  :=
        FAL_COMPONENT_FUNCTIONS.getMaxReceptQty(aGCO_GOOD_ID                => CurComponents.GOOD_PT
                                              , aLOT_INPROD_QTY             => CurComponents.LOT_INPROD_QTY
                                              , aLOM_ADJUSTED_QTY           => aLOM_ADJUSTED_QTY
                                              , aLOM_CONSUMPTION_QTY        => CurComponents.LOM_CONSUMPTION_QTY
                                              , aLOM_REF_QTY                => CurComponents.LOM_REF_QTY
                                              , aLOM_UTIL_COEF              => CurComponents.LOM_UTIL_COEF
                                              , aLOM_ADJUSTED_QTY_RECEIPT   => CurComponents.LOM_ADJUSTED_QTY_RECEIPT
                                              , aLOM_BACK_QTY               => CurComponents.LOM_BACK_QTY
                                              , aLOM_CPT_RECOVER_QTY        => CurComponents.LOM_CPT_RECOVER_QTY
                                              , aLOM_CPT_REJECT_QTY         => CurComponents.LOM_CPT_REJECT_QTY
                                              , aLOM_CPT_TRASH_QTY          => aLOM_CPT_TRASH_QTY
                                              , aLOM_EXIT_RECEIPT           => CurComponents.LOM_EXIT_RECEIPT
                                              , aLOM_PT_REJECT_QTY          => aLOM_PT_REJECT_QTY
                                              , aLOM_REJECTED_QTY           => CurComponents.LOM_REJECTED_QTY
                                               );

      update FAL_LOT_MATERIAL_LINK
         set LOM_BOM_REQ_QTY = aLOM_BOM_REQ_QTY
           , LOM_PT_REJECT_QTY = aLOM_PT_REJECT_QTY
           , LOM_CPT_TRASH_QTY = aLOM_CPT_TRASH_QTY
           , LOM_ADJUSTED_QTY = aLOM_ADJUSTED_QTY
           , LOM_FULL_REQ_QTY = aLOM_FULL_REQ_QTY
           , LOM_NEED_QTY = aLOM_NEED_QTY
           , LOM_MAX_RECEIPT_QTY = aLOM_MAX_RECEIPT_QTY
       where FAL_LOT_MATERIAL_LINK_ID = CurComponents.FAL_LOT_MATERIAL_LINK_ID;
    end loop;
  end UpdateBatchComponents;

  -- Processus : MiseAJourLotPseudo
  procedure UpdateBatch(aFAL_LOT_ID number, aFLP_SUP_QTY number, aFLP_PT_REJECT_QTY number, aFLP_CPT_REJECT_QTY number, deleteCoef integer default 1)
  is
    cursor cur_Lot
    is
      select nvl(LOT_ASKED_QTY, 0) LOT_ASKED_QTY
           , nvl(LOT_PT_REJECT_QTY, 0) LOT_PT_REJECT_QTY
           , nvl(LOT_CPT_REJECT_QTY, 0) LOT_CPT_REJECT_QTY
           , nvl(LOT_TOTAL_QTY, 0) LOT_TOTAL_QTY
           , nvl(LOT_RELEASED_QTY, 0) LOT_RELEASED_QTY
           , nvl(LOT_REJECT_RELEASED_QTY, 0) LOT_REJECT_RELEASED_QTY
           , nvl(LOT_DISMOUNTED_QTY, 0) LOT_DISMOUNTED_QTY
           , nvl(LOT_FREE_QTY, 0) LOT_FREE_QTY
           , nvl(LOT_ALLOCATED_QTY, 0) LOT_ALLOCATED_QTY
           , nvl(LOT_REJECT_PLAN_QTY, 0) LOT_REJECT_PLAN_QTY
        from FAL_LOT
       where FAL_LOT_ID = aFAL_LOT_ID;

    curLot                  cur_Lot%rowtype;
    aLOT_ASKED_QTY          number;
    aLOT_PT_REJECT_QTY      number;
    aLOT_CPT_REJECT_QTY     number;
    aLOT_INPROD_QTY         number;
    aLOT_MAX_RELEASABLE_QTY number;
    aLOT_FREE_QTY           number;
    aLOT_ALLOCATED_QTY      number;
    Y                       number;
  begin
    open cur_Lot;

    fetch cur_Lot
     into curLot;

    close cur_Lot;

    aLOT_ASKED_QTY           := curLot.LOT_ASKED_QTY + deleteCoef * aFLP_SUP_QTY;

    if cPfgUpdateLot = 0 then
      aLOT_PT_REJECT_QTY   := curLot.LOT_PT_REJECT_QTY + deleteCoef * aFLP_PT_REJECT_QTY;
      aLOT_CPT_REJECT_QTY  := curLot.LOT_CPT_REJECT_QTY + deleteCoef * aFLP_CPT_REJECT_QTY;
    else
      aLOT_PT_REJECT_QTY   := curLot.LOT_PT_REJECT_QTY;
      aLOT_CPT_REJECT_QTY  := curLot.LOT_CPT_REJECT_QTY;
    end if;

    aLOT_INPROD_QTY          :=
      (curLot.LOT_TOTAL_QTY + deleteCoef * aFLP_SUP_QTY) -
      aLOT_PT_REJECT_QTY -
      aLOT_CPT_REJECT_QTY -
      curLot.LOT_RELEASED_QTY -
      curLot.LOT_REJECT_RELEASED_QTY -
      curLot.LOT_DISMOUNTED_QTY;
    aLOT_MAX_RELEASABLE_QTY  := FAL_COMPONENT_TOOLS.GetMinQteMaxReceptionnable_Lot(aFAL_LOT_ID, aLOT_INPROD_QTY);

    if deleteCoef = 1 then
      -- Mise à jour sur création de suivi
      Y  := curLot.LOT_FREE_QTY +(aLOT_INPROD_QTY -(curLot.LOT_FREE_QTY + curLot.LOT_ALLOCATED_QTY) );

      if Y >= 0 then
        aLOT_FREE_QTY       := Y;
        aLOT_ALLOCATED_QTY  := curLot.LOT_ALLOCATED_QTY;
      else
        aLOT_FREE_QTY       := 0;
        aLOT_ALLOCATED_QTY  := greatest(curLot.LOT_ALLOCATED_QTY + Y, 0);
      end if;
    else
      -- mise à jour sur suppression de suivi
      aLOT_ALLOCATED_QTY  := curLot.LOT_ALLOCATED_QTY;

      if (aLOT_PT_REJECT_QTY + aLOT_CPT_REJECT_QTY + curLot.LOT_REJECT_RELEASED_QTY + curLot.LOT_DISMOUNTED_QTY) <= curLot.LOT_REJECT_PLAN_QTY then
        aLOT_FREE_QTY  := aLOT_ASKED_QTY - curLot.LOT_ALLOCATED_QTY;
      else
        aLOT_FREE_QTY  := aLOT_INPROD_QTY - curLot.LOT_ALLOCATED_QTY;
      end if;
    end if;

    update FAL_LOT
       set LOT_ASKED_QTY = aLOT_ASKED_QTY
         , LOT_TOTAL_QTY = nvl(LOT_TOTAL_QTY, 0) + deleteCoef * aFLP_SUP_QTY
         , LOT_PT_REJECT_QTY = aLOT_PT_REJECT_QTY
         , LOT_CPT_REJECT_QTY = aLOT_CPT_REJECT_QTY
         , LOT_INPROD_QTY = aLOT_INPROD_QTY
         , LOT_FREE_QTY = aLOT_FREE_QTY
         , LOT_ALLOCATED_QTY = aLOT_ALLOCATED_QTY
         , LOT_MAX_RELEASABLE_QTY = aLOT_MAX_RELEASABLE_QTY
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_LOT_ID = aFAL_LOT_ID;
  end UpdateBatch;

  /**
  * procedure : UpdatePostProcessTrack
  * Description
  *    Mise à jour OF, composants, opération, réseau, ... suite à l'insertion d'un suivi de fabrication
  * @created CLE
  * @lastUpdate age 14.09.2012
  * @public
  * @return    aFalLotProgressId    : Id du suivi créé
  * @param     aFalScheduleStepId   : Id de l'opération sur laquelle est effectuée le suivi
  * @param     aFalLotProgressFogId : Id de l'enregistrement du brouillard qui a généré le suivi
  * @param     aSessionId           : Session Oracle
  * @param     aContext             : Contexte
  * @param     aiShutdownExceptions : indique si l'on doit faire le raise en PL
  * @param out aErrorMsg            : Retour Message erreur
  * @param out aCptOutCount         : Nombre de composants sortis suite à l'avancement.
  */
  procedure UpdatePostProcessTrack(
    aFalLotProgressId    in     number
  , aFalScheduleStepId   in     number
  , aFalLotProgressFogId in     number default null
  , aSessionId           in     varchar2
  , aContext             in     integer
  , aiShutdownExceptions in     integer default 0
  , aErrorMsg            out    varchar2
  , aCptOutCount         out    number
  )
  is
    cursor curAdvancement
    is
      select nvl(FLP_SUP_QTY, 0) FLP_SUP_QTY
           , nvl(FLP_PRODUCT_QTY, 0) FLP_PRODUCT_QTY
           , nvl(FLP_PT_REJECT_QTY, 0) FLP_PT_REJECT_QTY
           , nvl(FLP_CPT_REJECT_QTY, 0) FLP_CPT_REJECT_QTY
           , FLP.FAL_SCHEDULE_STEP_ID
           , nvl(FLP_WORK_TIME, 0) FLP_WORK_TIME
           , nvl(FLP_ADJUSTING_TIME, 0) FLP_ADJUSTING_TIME
           , nvl(FLP_AMOUNT, 0) FLP_AMOUNT
           , FLP_DATE1
           , FLP_SEQ
           , LOT.FAL_LOT_ID
           , LOT.FAL_ORDER_ID
           , LOT.C_LOT_STATUS
           , TAL.C_OPERATION_TYPE
           , TAL.C_TASK_TYPE
        from FAL_LOT_PROGRESS FLP
           , FAL_LOT LOT
           , FAL_TASK_LINK TAL
       where FAL_LOT_PROGRESS_ID = aFalLotProgressId
         and LOT.FAL_LOT_ID = FLP.FAL_LOT_ID
         and TAL.FAL_SCHEDULE_STEP_ID = FLP.FAL_SCHEDULE_STEP_ID;

    tplAdvancement curAdvancement%rowtype;
    vLotStatus     FAL_LOT.C_LOT_STATUS%type;
    vErrorCode     varchar2(4000);
  begin
    open curAdvancement;

    fetch curAdvancement
     into tplAdvancement;

    close curAdvancement;

    /*  Processus : Mise à jour LienTacheLotPseudo */
    UpdateBatchOperation(tplAdvancement.FAL_SCHEDULE_STEP_ID
                       , tplAdvancement.FLP_PRODUCT_QTY
                       , tplAdvancement.FLP_PT_REJECT_QTY
                       , tplAdvancement.FLP_CPT_REJECT_QTY
                       , tplAdvancement.FLP_SUP_QTY
                       , tplAdvancement.FLP_WORK_TIME
                       , tplAdvancement.FLP_ADJUSTING_TIME
                       , tplAdvancement.FLP_AMOUNT
                       , tplAdvancement.FLP_DATE1
                       , aContext
                        );
    /*  Processus : Mise à jour LienTacheLotPseudo Secondaire */
    UpdateBatchSecondaryOperations(tplAdvancement.FAL_LOT_ID
                                 , tplAdvancement.FLP_SEQ
                                 , tplAdvancement.FLP_PRODUCT_QTY
                                 , tplAdvancement.FLP_PT_REJECT_QTY
                                 , tplAdvancement.FLP_CPT_REJECT_QTY
                                 , tplAdvancement.FLP_SUP_QTY
                                 , tplAdvancement.FLP_DATE1
                                  );

    if     (cPpsAscDsc = 1)
       and (    (tplAdvancement.FLP_PT_REJECT_QTY > 0)
            or (tplAdvancement.FLP_CPT_REJECT_QTY > 0)
            or (tplAdvancement.FLP_SUP_QTY > 0) ) then
      UpdateRMeterSecondOperations(tplAdvancement.FAL_LOT_ID
                                 , tplAdvancement.FLP_SEQ
                                 , tplAdvancement.FLP_PT_REJECT_QTY
                                 , tplAdvancement.FLP_CPT_REJECT_QTY
                                 , tplAdvancement.FLP_SUP_QTY
                                  );
    end if;

    -- Pas de mise à jour des opérations principales suivantes en éclatement d'OF
    -- pour le report du suivi des opérations indépendantes
    if not(     (aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchSplitting)
           and (tplAdvancement.C_OPERATION_TYPE = '4') ) then
      UpdateNextPrincipalOperations(tplAdvancement.FAL_LOT_ID
                                  , tplAdvancement.FAL_SCHEDULE_STEP_ID
                                  , tplAdvancement.FLP_SEQ
                                  , tplAdvancement.FLP_PT_REJECT_QTY
                                  , tplAdvancement.FLP_CPT_REJECT_QTY
                                  , tplAdvancement.FLP_SUP_QTY
                                  , tplAdvancement.FLP_PRODUCT_QTY
                                   );
    end if;

    /* Mise à jour de la quantité disponible */
    FAL_PRC_TASK_LINK.UpdateAvailQtyOp(tplAdvancement.FAL_LOT_ID);

    -- Mise à jour des liens brouillard-pesées en suivi-pesées
    if aFalLotProgressFogId is not null then
      UpdateWeighLinks(aFalLotProgressFogId, aFalLotProgressId);
    end if;

    if     (tplAdvancement.C_LOT_STATUS = lsLaunched)
       and (    ( (tplAdvancement.FLP_PT_REJECT_QTY + tplAdvancement.FLP_CPT_REJECT_QTY) > 0)
            or (tplAdvancement.FLP_SUP_QTY > 0) ) then
      -- Processus : MiseAJourLienComposantLotPseudo ...
      UpdateBatchComponents(tplAdvancement.FAL_LOT_ID
                          , tplAdvancement.FLP_SEQ
                          , tplAdvancement.FLP_PT_REJECT_QTY
                          , tplAdvancement.FLP_CPT_REJECT_QTY
                          , tplAdvancement.FLP_SUP_QTY
                           );
      -- Processus : MiseAJourLotPseudo
      UpdateBatch(tplAdvancement.FAL_LOT_ID, tplAdvancement.FLP_SUP_QTY, tplAdvancement.FLP_PT_REJECT_QTY, tplAdvancement.FLP_CPT_REJECT_QTY);
      -- Processus : MiseAJourOrdrePseudo
      FAL_ORDER_FUNCTIONS.UpdateOrder(aFAL_ORDER_ID => tplAdvancement.FAL_ORDER_ID);
    end if;

    select C_LOT_STATUS
      into vLotStatus
      from FAL_LOT
     where FAL_LOT_ID = tplAdvancement.FAL_LOT_ID;

    if vLotStatus = lsLaunched then
      FAL_NETWORK.MiseAJourReseaux(tplAdvancement.FAL_LOT_ID, FAL_NETWORK.ncSuiviAvancementCreation, '');
    end if;

    -- Exécution de la procédure individualisée définie dans la config FAL_PFG_END_PROCESS_PROC
    pExecuteProc(aFalLotProgressId, aContext);

    -- Mouvements automatiques des composants si requis
    -- (pour les opérations externes on ne le fait pas ici en raison du savepoint qui ne peut être appelé depuis un trigger
    --  voir FAL_PRC_SUBCONTRACTO)
    if     (cProgressMvtCpt = 1)
       and (tplAdvancement.C_TASK_TYPE = '1')
       and (aContext <> FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchSplitting) then
      savepoint spBeforeCompOutput;
      SortieComposantsAuSuivi(aLOM_SESSION            => aSessionId
                            , aFAL_SCHEDULE_STEP_ID   => aFalScheduleStepId
                            , aErrorCode              => vErrorCode
                            , aErrorMsg               => aErrorMsg
                            , aiShutdownExceptions    => aiShutdownExceptions
                            , aCptOutCount            => aCptOutCount
                             );

      if aErrorMsg is not null then
        aErrorMsg  :=
          PCS.PC_FUNCTIONS.TranslateWord('Erreurs détectées lors des sorties de composants associées aux suivi d''avancement exécutés!') ||
          co.cLineBreak ||
          aErrorMsg;
      end if;

      -- Annulation si une erreur s'est produite
      if    vErrorCode is not null
         or aErrorMsg is not null then
        rollback to savepoint spBeforeCompOutput;
        aCptOutCount  := 0;
      end if;
    end if;
  end UpdatePostProcessTrack;

  /**
  * Description
  *    Ajout d'un suivi de fabrication sur une opération d'OF. Ne retourne pas le
  *    nombre de composants sortis suite au suivi
  */
  procedure AddProcessTracking(
    aFalScheduleStepId                 number
  , aFlpDate1                          date default sysdate
  , aFlpProductQty                     number default 0
  , aFlpPtRejectQty                    number default 0
  , aFlpCptRejectQty                   number default 0
  , aFlpSupQty                         number default 0
  , aFlpAdjustingTime                  number default 0
  , aFlpWorkTime                       number default 0
  , aFlpAmount                         number default 0
  , aFalFactoryFloorId                 number default null
  , aFalFalFactoryFloorId              number default null
  , aDicWorkTypeId                     varchar2 default null
  , aDicOperatorId                     varchar2 default null
  , aDicRebutId                        varchar2 default null
  , aFlpRate                           number default 0
  , aFlpAdjustingRate                  number default 0
  , aFlpEanCode                        varchar2 default null
  , aPpsTools1Id                       number default null
  , aPpsTools2Id                       number default null
  , aPpsTools3Id                in     number default null
  , aPpsTools4Id                in     number default null
  , aPpsTools5Id                in     number default null
  , aPpsTools6Id                in     number default null
  , aPpsTools7Id                in     number default null
  , aPpsTools8Id                in     number default null
  , aPpsTools9Id                in     number default null
  , aPpsTools10Id               in     number default null
  , aPpsTools11Id               in     number default null
  , aPpsTools12Id               in     number default null
  , aPpsTools13Id               in     number default null
  , aPpsTools14Id               in     number default null
  , aPpsTools15Id               in     number default null
  , aPpsOperationProcedureId           number default null
  , aPpsPpsOperationProcedureId        number default null
  , aFlpLabelControl                   varchar2 default null
  , aFlpLabelReject                    varchar2 default null
  , aFlpProductQtyUop                  number default 0
  , aFlpPtRejectQtyUop                 number default 0
  , aFlpCptRejectQtyUop                number default 0
  , aManualProgressTrack               integer default 0
  , aSessionId                         varchar2
  , aFalLotProgressId                  number default null
  , aiShutdownExceptions        in     integer default 0
  , aErrorMsg                   out    varchar2
  , aUpdateBatch                       integer default 1
  , aContext                           integer default FAL_COMPONENT_LINK_FUNCTIONS.ctxtProductionAdvance
  , aDocPositionDetailId               number default null
  , aDocPositionId                     number default null
  , aAIdcre                     in     FAL_LOT_PROGRESS.A_IDCRE%type default pcs.PC_I_LIB_SESSION.GetUserIni
  , aADatecre                   in     FAL_LOT_PROGRESS.A_DATECRE%type default sysdate
  , aDocGaugeReceiptId          in     DOC_POSITION_DETAIL.DOC_GAUGE_RECEIPT_ID%type default null
  , aFlpSubcontractQty          in     FAL_LOT_PROGRESS.FLP_SUBCONTRACT_QTY%type default null
  )
  is
    lCptOutCount number := 0;
  begin
    AddProcessTracking(aFalScheduleStepId            => aFalScheduleStepId
                     , aFlpDate1                     => aFlpDate1
                     , aFlpProductQty                => aFlpProductQty
                     , aFlpPtRejectQty               => aFlpPtRejectQty
                     , aFlpCptRejectQty              => aFlpCptRejectQty
                     , aFlpSupQty                    => aFlpSupQty
                     , aFlpAdjustingTime             => aFlpAdjustingTime
                     , aFlpWorkTime                  => aFlpWorkTime
                     , aFlpAmount                    => aFlpAmount
                     , aFalFactoryFloorId            => aFalFactoryFloorId
                     , aFalFalFactoryFloorId         => aFalFalFactoryFloorId
                     , aDicWorkTypeId                => aDicWorkTypeId
                     , aDicOperatorId                => aDicOperatorId
                     , aDicRebutId                   => aDicRebutId
                     , aFlpRate                      => aFlpRate
                     , aFlpAdjustingRate             => aFlpAdjustingRate
                     , aFlpEanCode                   => aFlpEanCode
                     , aPpsTools1Id                  => aPpsTools1Id
                     , aPpsTools2Id                  => aPpsTools2Id
                     , aPpsTools3Id                  => aPpsTools3Id
                     , aPpsTools4Id                  => aPpsTools4Id
                     , aPpsTools5Id                  => aPpsTools5Id
                     , aPpsTools6Id                  => aPpsTools6Id
                     , aPpsTools7Id                  => aPpsTools7Id
                     , aPpsTools8Id                  => aPpsTools8Id
                     , aPpsTools9Id                  => aPpsTools9Id
                     , aPpsTools10Id                 => aPpsTools10Id
                     , aPpsTools11Id                 => aPpsTools11Id
                     , aPpsTools12Id                 => aPpsTools12Id
                     , aPpsTools13Id                 => aPpsTools13Id
                     , aPpsTools14Id                 => aPpsTools14Id
                     , aPpsTools15Id                 => aPpsTools15Id
                     , aPpsOperationProcedureId      => aPpsOperationProcedureId
                     , aPpsPpsOperationProcedureId   => aPpsPpsOperationProcedureId
                     , aFlpLabelControl              => aFlpLabelControl
                     , aFlpLabelReject               => aFlpLabelReject
                     , aFlpProductQtyUop             => aFlpProductQtyUop
                     , aFlpPtRejectQtyUop            => aFlpPtRejectQtyUop
                     , aFlpCptRejectQtyUop           => aFlpCptRejectQtyUop
                     , aManualProgressTrack          => aManualProgressTrack
                     , aSessionId                    => aSessionId
                     , aFalLotProgressId             => aFalLotProgressId
                     , aiShutdownExceptions          => aiShutdownExceptions
                     , aErrorMsg                     => aErrorMsg
                     , aUpdateBatch                  => aUpdateBatch
                     , aContext                      => aContext
                     , aDocPositionDetailId          => aDocPositionDetailId
                     , aDocPositionId                => aDocPositionId
                     , aCptOutCount                  => lCptOutCount
                     , aAIdcre                       => aAIdcre
                     , aADatecre                     => aADatecre
                     , aDocGaugeReceiptId            => aDocGaugeReceiptId
                     , aFlpSubcontractQty            => aFlpSubcontractQty
                      );
  end AddProcessTracking;

  /**
  * Description
  *    Ajout d'un suivi de fabrication sur une opération d'OF. Retourne le nombre de composants sortis
  *    suite au suivi
  */
  procedure AddProcessTracking(
    aFalScheduleStepId          in     number
  , aFlpDate1                   in     date default sysdate
  , aFlpProductQty              in     number default 0
  , aFlpPtRejectQty             in     number default 0
  , aFlpCptRejectQty            in     number default 0
  , aFlpSupQty                  in     number default 0
  , aFlpAdjustingTime           in     number default 0
  , aFlpWorkTime                in     number default 0
  , aFlpAmount                  in     number default 0
  , aFalFactoryFloorId          in     number default null
  , aFalFalFactoryFloorId       in     number default null
  , aDicWorkTypeId              in     varchar2 default null
  , aDicOperatorId              in     varchar2 default null
  , aDicRebutId                 in     varchar2 default null
  , aFlpRate                    in     number default 0
  , aFlpAdjustingRate           in     number default 0
  , aFlpEanCode                 in     varchar2 default null
  , aPpsTools1Id                in     number default null
  , aPpsTools2Id                in     number default null
  , aPpsTools3Id                in     number default null
  , aPpsTools4Id                in     number default null
  , aPpsTools5Id                in     number default null
  , aPpsTools6Id                in     number default null
  , aPpsTools7Id                in     number default null
  , aPpsTools8Id                in     number default null
  , aPpsTools9Id                in     number default null
  , aPpsTools10Id               in     number default null
  , aPpsTools11Id               in     number default null
  , aPpsTools12Id               in     number default null
  , aPpsTools13Id               in     number default null
  , aPpsTools14Id               in     number default null
  , aPpsTools15Id               in     number default null
  , aPpsOperationProcedureId    in     number default null
  , aPpsPpsOperationProcedureId in     number default null
  , aFlpLabelControl            in     varchar2 default null
  , aFlpLabelReject             in     varchar2 default null
  , aFlpProductQtyUop           in     number default 0
  , aFlpPtRejectQtyUop          in     number default 0
  , aFlpCptRejectQtyUop         in     number default 0
  , aManualProgressTrack        in     integer default 0
  , aSessionId                  in     varchar2
  , aFalLotProgressId           in     number default null
  , aiShutdownExceptions        in     integer default 0
  , aErrorMsg                   out    varchar2
  , aUpdateBatch                in     integer default 1
  , aContext                    in     integer default FAL_COMPONENT_LINK_FUNCTIONS.ctxtProductionAdvance
  , aDocPositionDetailId        in     number default null
  , aDocPositionId              in     number default null
  , aCptOutCount                out    number
  , aAIdcre                     in     FAL_LOT_PROGRESS.A_IDCRE%type default pcs.PC_I_LIB_SESSION.GetUserIni
  , aADatecre                   in     FAL_LOT_PROGRESS.A_DATECRE%type default sysdate
  , aDocGaugeReceiptId          in     DOC_POSITION_DETAIL.DOC_GAUGE_RECEIPT_ID%type default null
  , aFlpSubcontractQty          in     FAL_LOT_PROGRESS.FLP_SUBCONTRACT_QTY%type default null
  )
  is
    cursor crOperation
    is
      select FAL_LOT_ID
           , (select LOT_REFCOMPL
                from FAL_LOT
               where FAL_LOT_ID = FTL.FAL_LOT_ID) LOT_REFCOMPL
           , SCS_STEP_NUMBER
           , FAL_TASK_ID
           , TAL_SEQ_ORIGIN
           , SCS_SHORT_DESCR
           , DIC_FREE_TASK_CODE_ID
           , DIC_FREE_TASK_CODE2_ID
           , SCS_QTY_REF2_WORK
           , DIC_UNIT_OF_MEASURE_ID
           , SCS_CONVERSION_FACTOR
           , C_TASK_TYPE
        from FAL_TASK_LINK FTL
       where FAL_SCHEDULE_STEP_ID = aFalScheduleStepId;

    tplOperation       crOperation%rowtype;
    aErrorcode         integer;
    nFalLotProgressId  number;
    batch_not_reserved exception;
    pragma exception_init(batch_not_reserved, -20084);
  begin
    open crOperation;

    fetch crOperation
     into tplOperation;

    close crOperation;

    -- Vérification de la présence de la réservation du lot.
    -- Limitation au context de l'avancement de production.
    if     FAL_BATCH_RESERVATION.isBatchReserved(iLotID => tplOperation.FAL_LOT_ID) = 0
       and aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtProductionAdvance then
      raise batch_not_reserved;
    end if;

    if aDocPositionId is not null then
      -- Lecture de la moyenne du prix unitaire des positions du BRAST qui mettent a jour les opérations de l'OF
      UpdateOperationAmount(iDocPositionId => aDocPositionId, iDocGaugeReceiptId => aDocGaugeReceiptId);
    end if;

    nFalLotProgressId  := nvl(aFalLotProgressId, GetNewId);

    insert into FAL_LOT_PROGRESS
                (FAL_LOT_PROGRESS_ID
               , FAL_LOT_ID
               , LOT_REFCOMPL
               , FAL_SCHEDULE_STEP_ID
               , FAL_TASK_ID
               , FAL_FACTORY_FLOOR_ID
               , FAL_FAL_FACTORY_FLOOR_ID
               , FLP_RATE
               , FLP_ADJUSTING_RATE
               , PPS_OPERATION_PROCEDURE_ID
               , PPS_PPS_OPERATION_PROCEDURE_ID
               , PPS_TOOLS1_ID
               , PPS_TOOLS2_ID
               , PPS_TOOLS3_ID
               , PPS_TOOLS4_ID
               , PPS_TOOLS5_ID
               , PPS_TOOLS6_ID
               , PPS_TOOLS7_ID
               , PPS_TOOLS8_ID
               , PPS_TOOLS9_ID
               , PPS_TOOLS10_ID
               , PPS_TOOLS11_ID
               , PPS_TOOLS12_ID
               , PPS_TOOLS13_ID
               , PPS_TOOLS14_ID
               , PPS_TOOLS15_ID
               , DOC_POSITION_DETAIL_ID
               , DIC_WORK_TYPE_ID
               , FLP_SEQ
               , FLP_SEQ_ORIGIN
               , FLP_SHORT_DESCR
               , FLP_DATE1
               , FLP_PRODUCT_QTY
               , FLP_PT_REJECT_QTY
               , FLP_CPT_REJECT_QTY
               , FLP_ADJUSTING_TIME
               , FLP_WORK_TIME
               , FLP_AMOUNT
               , FLP_SUP_QTY
               , DIC_FREE_TASK_CODE_ID
               , DIC_FREE_TASK_CODE2_ID
               , FLP_QTY_REF2_WORK
               , DIC_UNIT_OF_MEASURE_ID
               , FLP_CONVERSION_FACTOR
               , DIC_OPERATOR_ID
               , DIC_REBUT_ID
               , FLP_EAN_CODE
               , FLP_PRODUCT_QTY_UOP
               , FLP_PT_REJECT_QTY_UOP
               , FLP_CPT_REJECT_QTY_UOP
               , FLP_LABEL_CONTROL
               , FLP_LABEL_REJECT
               , FLP_MANUAL
               , FLP_SUBCONTRACT_QTY
               , A_DATECRE
               , A_IDCRE
                )
         values (nFalLotProgressId
               , tplOperation.FAL_LOT_ID
               , tplOperation.LOT_REFCOMPL
               , aFalScheduleStepId
               , tplOperation.FAL_TASK_ID
               , decode(aFalFactoryFloorId, 0, null, aFalFactoryFloorId)
               , decode(aFalFalFactoryFloorId, 0, null, aFalFalFactoryFloorId)
               , aFlpRate
               , aFlpAdjustingRate
               , decode(aPpsOperationProcedureId, 0, null, aPpsOperationProcedureId)
               , decode(aPpsPpsOperationProcedureId, 0, null, aPpsPpsOperationProcedureId)
               , decode(aPpsTools1Id, 0, null, aPpsTools1Id)
               , decode(aPpsTools2Id, 0, null, aPpsTools2Id)
               , decode(aPpsTools3Id, 0, null, aPpsTools3Id)
               , decode(aPpsTools4Id, 0, null, aPpsTools4Id)
               , decode(aPpsTools5Id, 0, null, aPpsTools5Id)
               , decode(aPpsTools6Id, 0, null, aPpsTools6Id)
               , decode(aPpsTools7Id, 0, null, aPpsTools7Id)
               , decode(aPpsTools8Id, 0, null, aPpsTools8Id)
               , decode(aPpsTools9Id, 0, null, aPpsTools9Id)
               , decode(aPpsTools10Id, 0, null, aPpsTools10Id)
               , decode(aPpsTools11Id, 0, null, aPpsTools11Id)
               , decode(aPpsTools12Id, 0, null, aPpsTools12Id)
               , decode(aPpsTools13Id, 0, null, aPpsTools13Id)
               , decode(aPpsTools14Id, 0, null, aPpsTools14Id)
               , decode(aPpsTools15Id, 0, null, aPpsTools15Id)
               , aDocPositionDetailId
               , aDicWorkTypeId
               , tplOperation.SCS_STEP_NUMBER
               , tplOperation.TAL_SEQ_ORIGIN
               , tplOperation.SCS_SHORT_DESCR
               , nvl(aFlpDate1, sysdate)   -- FLP_DATE1
               , nvl(aFlpProductQty, 0)
               , aFlpPtRejectQty
               , aFlpCptRejectQty
               , aFlpAdjustingTime
               , aFlpWorkTime
               , aFlpAmount
               , aFlpSupQty
               , tplOperation.DIC_FREE_TASK_CODE_ID
               , tplOperation.DIC_FREE_TASK_CODE2_ID
               , tplOperation.SCS_QTY_REF2_WORK
               , tplOperation.DIC_UNIT_OF_MEASURE_ID
               , tplOperation.SCS_CONVERSION_FACTOR
               , aDicOperatorId
               , aDicRebutId
               , aFlpEanCode
               , aFlpProductQtyUop
               , aFlpPtRejectQtyUop
               , aFlpCptRejectQtyUop
               , aFlpLabelControl
               , aFlpLabelReject
               , aManualProgressTrack
               , aFlpSubcontractQty
               , aADatecre
               , aAIdcre
                );

    if aUpdateBatch = 1 then
      -- Mise à jour OF, composants, opération, réseau, ...
      UpdatePostProcessTrack(aFalLotProgressId      => nFalLotProgressId
                           , aFalScheduleStepId     => aFalScheduleStepId
                           , aSessionId             => aSessionId
                           , aiShutdownExceptions   => aiShutdownExceptions
                           , aErrorMsg              => aErrorMsg
                           , aContext               => aContext
                           , aCptOutCount           => aCptOutCount
                            );
    end if;

    -- Imputation automatique en finance
    if     (upper(PCS.PC_CONFIG.GetConfig('FAL_AUTO_ACI_TIME_ENTRY') ) = 'TRUE')
       and (tplOperation.C_TASK_TYPE = '1') then
      FAL_ACI_TIME_ENTRY_FCT.ProcessBatch(tplOperation.FAL_LOT_ID, aErrorcode);

      if aErrorCode = faErrorWithACI then
        aErrorMsg  :=
          PCS.PC_FUNCTIONS.TranslateWord('Erreur dans l''imputation des heures en ACI !') ||
          PCS.PC_FUNCTIONS.TranslateWord('Certaines heures n''ont pu être imputées.');
      end if;
    end if;
  exception
    when batch_not_reserved then
      aErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('La réservation sur ce lot n''est plus valide !');
    when others then
      if aiShutdownExceptions = 0 then
        raise;
      else
        aErrorMsg  :=
          PCS.PC_FUNCTIONS.TranslateWord('Une erreur s''est produite lors du traitement de l''enregistrement :') ||
          co.cLineBreak ||
          DBMS_UTILITY.FORMAT_ERROR_STACK;
      end if;
  end AddProcessTracking;

  function processLotAdvancement(
    aPFG_LOT_REFCOMPL        in     FAL_LOT_PROGRESS_FOG.PFG_LOT_REFCOMPL%type
  , aPFG_SEQ                 in     FAL_LOT_PROGRESS_FOG.PFG_SEQ%type
  , aPFG_DATE                in     FAL_LOT_PROGRESS_FOG.PFG_DATE%type
  , aPFG_REF_FACTORY_FLOOR   in     FAL_LOT_PROGRESS_FOG.PFG_REF_FACTORY_FLOOR%type
  , aPFG_REF_FACTORY_FLOOR2  in     FAL_LOT_PROGRESS_FOG.PFG_REF_FACTORY_FLOOR2%type
  , aPFG_RATE_FACTORY_FLOOR  in     FAL_LOT_PROGRESS_FOG.PFG_RATE_FACTORY_FLOOR%type
  , aPFG_PROC_CONTROL        in     FAL_LOT_PROGRESS_FOG.PFG_PROC_CONTROL%type
  , aPFG_PROC_EXECUTION      in     FAL_LOT_PROGRESS_FOG.PFG_PROC_EXECUTION%type
  , aPFG_TOOLS1              in     FAL_LOT_PROGRESS_FOG.PFG_TOOLS1%type
  , aPFG_TOOLS2              in     FAL_LOT_PROGRESS_FOG.PFG_TOOLS2%type
  , aPFG_TOOLS3              in     FAL_LOT_PROGRESS_FOG.PFG_TOOLS3%type
  , aPFG_TOOLS4              in     FAL_LOT_PROGRESS_FOG.PFG_TOOLS4%type
  , aPFG_TOOLS5              in     FAL_LOT_PROGRESS_FOG.PFG_TOOLS5%type
  , aPFG_TOOLS6              in     FAL_LOT_PROGRESS_FOG.PFG_TOOLS6%type
  , aPFG_TOOLS7              in     FAL_LOT_PROGRESS_FOG.PFG_TOOLS7%type
  , aPFG_TOOLS8              in     FAL_LOT_PROGRESS_FOG.PFG_TOOLS8%type
  , aPFG_TOOLS9              in     FAL_LOT_PROGRESS_FOG.PFG_TOOLS9%type
  , aPFG_TOOLS10             in     FAL_LOT_PROGRESS_FOG.PFG_TOOLS10%type
  , aPFG_TOOLS11             in     FAL_LOT_PROGRESS_FOG.PFG_TOOLS11%type
  , aPFG_TOOLS12             in     FAL_LOT_PROGRESS_FOG.PFG_TOOLS12%type
  , aPFG_TOOLS13             in     FAL_LOT_PROGRESS_FOG.PFG_TOOLS13%type
  , aPFG_TOOLS14             in     FAL_LOT_PROGRESS_FOG.PFG_TOOLS14%type
  , aPFG_TOOLS15             in     FAL_LOT_PROGRESS_FOG.PFG_TOOLS15%type
  , aPFG_DIC_OPERATOR_ID     in     FAL_LOT_PROGRESS_FOG.PFG_DIC_OPERATOR_ID%type
  , aPFG_DIC_REBUT_ID        in     FAL_LOT_PROGRESS_FOG.PFG_DIC_REBUT_ID%type
  , aPFG_DIC_WORK_TYPE_ID    in     FAL_LOT_PROGRESS_FOG.PFG_DIC_WORK_TYPE_ID%type
  , aPFG_PRODUCT_QTY         in     FAL_LOT_PROGRESS_FOG.PFG_PRODUCT_QTY%type
  , aPFG_PT_REJECT_QTY       in     FAL_LOT_PROGRESS_FOG.PFG_PT_REFECT_QTY%type
  , aPFG_CPT_REJECT_QTY      in     FAL_LOT_PROGRESS_FOG.PFG_CPT_REJECT_QFY%type
  , aPFG_WORK_TIME           in     FAL_LOT_PROGRESS_FOG.PFG_WORK_TIME%type
  , aPFG_ADJUSTING_TIME      in     FAL_LOT_PROGRESS_FOG.PFG_ADJUSTING_TIME%type
  , aPFG_AMOUNT              in     FAL_LOT_PROGRESS_FOG.PFG_AMOUNT%type
  , aPFG_EAN_CODE            in     FAL_LOT_PROGRESS_FOG.PFG_EAN_CODE%type
  , aPFG_PRODUCT_QTY_UOP     in     FAL_LOT_PROGRESS_FOG.PFG_PRODUCT_QTY_UOP%type
  , aPFG_PT_REJECT_QTY_UOP   in     FAL_LOT_PROGRESS_FOG.PFG_PT_REJECT_QTY_UOP%type
  , aPFG_CPT_REJECT_QTY_UOP  in     FAL_LOT_PROGRESS_FOG.PFG_CPT_REJECT_QTY_UOP%type
  , aPFG_LABEL_CONTROL       in     FAL_LOT_PROGRESS_FOG.PFG_LABEL_CONTROL%type
  , aPFG_LABEL_REJECT        in     FAL_LOT_PROGRESS_FOG.PFG_LABEL_REJECT%type
  , aFAL_LOT_PROGRESS_FOG_ID in     FAL_LOT_PROGRESS_FOG.FAL_LOT_PROGRESS_FOG_ID%type default null
  , aErrorMsg                out    varchar2
  , aiShutdownExceptions     in     integer default 0
  )
    return integer
  is
    vError                     integer;
    vErrorMsg                  varchar2(4000);
    vLotId                     FAL_LOT.FAL_LOT_ID%type;
    vLotStatus                 FAL_LOT.C_LOT_STATUS%type;
    vFactoryFloorId            FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type;
    vFactoryFloor2Id           FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type;
    vOperationProcId_Control   PPS_OPERATION_PROCEDURE.PPS_OPERATION_PROCEDURE_ID%type;
    vOperationProcId_Execution PPS_OPERATION_PROCEDURE.PPS_OPERATION_PROCEDURE_ID%type;
    vGoodId_Tool1              number;
    vGoodId_Tool2              number;
    vGoodId_Tool3              number;
    vGoodId_Tool4              number;
    vGoodId_Tool5              number;
    vGoodId_Tool6              number;
    vGoodId_Tool7              number;
    vGoodId_Tool8              number;
    vGoodId_Tool9              number;
    vGoodId_Tool10             number;
    vGoodId_Tool11             number;
    vGoodId_Tool12             number;
    vGoodId_Tool13             number;
    vGoodId_Tool14             number;
    vGoodId_Tool15             number;
    vSessionId                 FAL_LOT1.LT1_ORACLE_SESSION%type;
    vTaskLinkId                FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type;
    vLotProgressId             number;
    vPfgProductQty             number;
    lCptOutCount               number;
  begin
    begin
      vSessionId      := DBMS_SESSION.unique_session_id;
      vPfgProductQty  := aPFG_PRODUCT_QTY;
      -- Vérification et initialisation des données
      vError          :=
        CheckLotFields(aPFG_LOT_REFCOMPL
                     , aPFG_SEQ
                     , aPFG_DATE
                     , aPFG_REF_FACTORY_FLOOR
                     , aPFG_REF_FACTORY_FLOOR2
                     , aPFG_RATE_FACTORY_FLOOR
                     , aPFG_PROC_CONTROL
                     , aPFG_PROC_EXECUTION
                     , aPFG_TOOLS1
                     , aPFG_TOOLS2
                     , aPFG_TOOLS3
                     , aPFG_TOOLS4
                     , aPFG_TOOLS5
                     , aPFG_TOOLS6
                     , aPFG_TOOLS7
                     , aPFG_TOOLS8
                     , aPFG_TOOLS9
                     , aPFG_TOOLS10
                     , aPFG_TOOLS11
                     , aPFG_TOOLS12
                     , aPFG_TOOLS13
                     , aPFG_TOOLS14
                     , aPFG_TOOLS15
                     , aPFG_DIC_OPERATOR_ID
                     , aPFG_DIC_REBUT_ID
                     , aPFG_DIC_WORK_TYPE_ID
                     , aPFG_PRODUCT_QTY
                     , aPFG_PT_REJECT_QTY
                     , aFAL_LOT_PROGRESS_FOG_ID
                     , vLotId
                     , vTaskLinkId
                     , vFactoryFloorId
                     , vFactoryFloor2Id
                     , vOperationProcId_Control
                     , vOperationProcId_Execution
                     , vGoodId_Tool1
                     , vGoodId_Tool2
                     , vGoodId_Tool3
                     , vGoodId_Tool4
                     , vGoodId_Tool5
                     , vGoodId_Tool6
                     , vGoodId_Tool7
                     , vGoodId_Tool8
                     , vGoodId_Tool9
                     , vGoodId_Tool10
                     , vGoodId_Tool11
                     , vGoodId_Tool12
                     , vGoodId_Tool13
                     , vGoodId_Tool14
                     , vGoodId_Tool15
                      );

      /* Suppression de l'enregistrement si nécessaire (ie pour tout
         enregistrement lié à une opération non principale ou secondaire
         et non interne). */
      if MustClearOperationInDaybook(vTaskLinkId) = 1 then
        delete from FAL_LOT_PROGRESS_FOG
              where FAL_LOT_PROGRESS_FOG_ID = aFAL_LOT_PROGRESS_FOG_ID;

        return faNoError;
      end if;

      if vError <> faNoError then
        return vError;
      end if;

      -- Réservation du lot
      FAL_BATCH_RESERVATION.BatchReservation(aFAL_LOT_ID => vLotId, aLT1_ORACLE_SESSION => vSessionId, aErrorMsg => aErrorMsg);

      if aErrorMsg is not null then
        return faLotUnavailable;
      end if;

      -- Pour un lot soldé, les quantités de rebut sont ignorées
      select C_LOT_STATUS
        into vLotStatus
        from FAL_LOT
       where FAL_LOT_ID = vLotId;

      vError          :=
        CreateAdvancement(vLotId
                        , vTaskLinkId
                        , aPFG_LOT_REFCOMPL
                        , aPFG_DATE
                        , vPfgProductQty
                        , case
                            when vLotStatus = lsBalancedRecept then 0
                            else aPFG_PT_REJECT_QTY
                          end
                        , case
                            when vLotStatus = lsBalancedRecept then 0
                            else aPFG_CPT_REJECT_QTY
                          end
                        , aPFG_WORK_TIME
                        , aPFG_ADJUSTING_TIME
                        , aPFG_AMOUNT
                        , aPFG_DIC_OPERATOR_ID
                        , aPFG_DIC_REBUT_ID
                        , aPFG_DIC_WORK_TYPE_ID
                        , vFactoryFloorId
                        , vFactoryFloor2Id
                        , aPFG_RATE_FACTORY_FLOOR
                        , vOperationProcId_Control
                        , vOperationProcId_Execution
                        , vGoodId_Tool1
                        , vGoodId_Tool2
                        , vGoodId_Tool3
                        , vGoodId_Tool4
                        , vGoodId_Tool5
                        , vGoodId_Tool6
                        , vGoodId_Tool7
                        , vGoodId_Tool8
                        , vGoodId_Tool9
                        , vGoodId_Tool10
                        , vGoodId_Tool11
                        , vGoodId_Tool12
                        , vGoodId_Tool13
                        , vGoodId_Tool14
                        , vGoodId_Tool15
                        , aPFG_EAN_CODE
                        , aPFG_PRODUCT_QTY_UOP
                        , case
                            when vLotStatus = lsBalancedRecept then null
                            else aPFG_PT_REJECT_QTY_UOP
                          end
                        , case
                            when vLotStatus = lsBalancedRecept then null
                            else aPFG_CPT_REJECT_QTY_UOP
                          end
                        , aPFG_LABEL_CONTROL
                        , aPFG_LABEL_REJECT
                        , 0   -- aManualProgressTrack
                        , vLotProgressId
                        , aFAL_LOT_PROGRESS_FOG_ID
                         );

      if vError = faNoError then
        -- Mise à jour OF, composants, opération, réseau, ...
        UpdatePostProcessTrack(aFalLotProgressId      => vLotProgressId
                             , aFalScheduleStepId     => vTaskLinkId
                             , aFalLotProgressFogId   => aFAL_LOT_PROGRESS_FOG_ID
                             , aSessionId             => vSessionId
                             , aContext               => FAL_COMPONENT_LINK_FUNCTIONS.ctxtProductionAdvance
                             , aiShutdownExceptions   => aiShutdownExceptions
                             , aErrorMsg              => aErrorMsg
                             , aCptOutCount           => lCptOutCount
                              );
      end if;

      if vError = faNoError then
        -- Réception automatique si requise
        -- Réservation du lot déjà effectuée -> on passe l'ID de la session qui a fait la réservation
        FAL_BATCH_FUNCTIONS.AutoRecept(aFalTaskLinkId   => vTaskLinkId
                                     , aQty             => vPfgProductQty
                                     , aSessionId       => vSessionId
                                     , aResult          => vError
                                     , aMsgResult       => vErrorMsg
                                      );

        if vError <> FAL_BATCH_FUNCTIONS.arReceptionOk then
          -- Enregistrement du message d'erreur
          addText(aErrorMsg, vErrorMsg);
        end if;

        -- La réception automatique ne doit pas arrêter le traitement
        vError  := faNoError;
      end if;
    exception
      when others then
        if aiShutdownExceptions = 0 then
          raise;
        else
          vError     := faUnknownError;
          aErrorMsg  :=
            PCS.PC_FUNCTIONS.TranslateWord('Une erreur s''est produite lors du traitement de l''enregistrement :') ||
            chr(13) ||
            chr(10) ||
            DBMS_UTILITY.FORMAT_ERROR_STACK;
        end if;
    end;

    -- Libération du lot
    FAL_BATCH_RESERVATION.ReleaseBatch(aFalLotId => vLotId, aSessionId => vSessionId);
    return vError;
  end processLotAdvancement;

  function processGalAdvancement(
    aPFG_GAL_REFCOMPL    in     FAL_LOT_PROGRESS_FOG.PFG_GAL_REFCOMPL%type
  , aPFG_SEQ             in     FAL_LOT_PROGRESS_FOG.PFG_SEQ%type
  , aPFG_DATE            in     FAL_LOT_PROGRESS_FOG.PFG_DATE%type
  , aPFG_DIC_OPERATOR_ID in     FAL_LOT_PROGRESS_FOG.PFG_DIC_OPERATOR_ID%type
  , aPFG_WORK_TIME       in     FAL_LOT_PROGRESS_FOG.PFG_WORK_TIME%type
  , aPFG_ADJUSTING_TIME  in     FAL_LOT_PROGRESS_FOG.PFG_ADJUSTING_TIME%type
  , aErrorMsg            out    varchar2
  , aiShutdownExceptions in     integer default 0
  )
    return integer
  is
    vTaskId      GAL_TASK.GAL_TASK_ID%type;
    vTaskLinkId  GAL_TASK_LINK.GAL_TASK_LINK_ID%type;
    vEmpNumber   HRM_PERSON.EMP_NUMBER%type;
    vHoursTempId GAL_FAL_HOURS_TEMP.GAL_FAL_HOURS_TEMP_ID%type;
    vError       integer;
    vType        GAL_FAL_HOURS_TEMP.HTP_TYPE%type;
  begin
    begin
      -- Vérification et initialisation des données
      vError  := CheckGalFields(aPFG_GAL_REFCOMPL, aPFG_SEQ, aPFG_DATE, aPFG_DIC_OPERATOR_ID, vTaskId, vTaskLinkId, vEmpNumber);

      if vError <> faNoError then
        return vError;
      end if;

      -- Insertion des données dans la table temporaire pour l'importation
      -- dans GAL_HOURS
      insert into GAL_FAL_HOURS_TEMP
                  (GAL_FAL_HOURS_TEMP_ID
                 , HTP_DATE
                 , HTP_GAL_FAL_TASK_LINK_ID
                 , HTP_EMP_NUMBER
                 , HTP_WORKED_TIME
                 , HTP_PROVENANCE
                  )
           values (INIT_TEMP_ID_SEQ.nextval
                 , aPFG_DATE
                 , nvl(to_char(vTaskLinkId), aPFG_GAL_REFCOMPL)
                 , vEmpNumber
                 , nvl(aPFG_WORK_TIME, 0) + nvl(aPFG_ADJUSTING_TIME, 0)
                 , 'P'
                  )
        returning GAL_FAL_HOURS_TEMP_ID
             into vHoursTempId;

      -- Initialisation des variables
      GAL_FAL_IMPORT_TIME_PROD.init_var_check_gal_hours;

      -- Pour l'enregistrement qui vient d'être inséré
      for tplHoursTemp in (select *
                             from GAL_FAL_HOURS_TEMP
                            where GAL_FAL_HOURS_TEMP_ID = vHoursTempId) loop
        -- Détermination du type (O/I pour Opération/Indirect)
        GAL_FAL_IMPORT_TIME_PROD.det_which_type_of_hours_gal(tplHoursTemp, vType);
        -- Contrôle et importation dans GAL_HOURS
        GAL_FAL_IMPORT_TIME_PROD.import_hours_in_gal(vError, aErrorMsg, tplHoursTemp, sysdate, vType, false, '1');

        if vError > 0 then
          vError  := etGalHoursError;
        end if;
      end loop;
    exception
      when others then
        if aiShutdownExceptions = 0 then
          raise;
        else
          vError     := faUnknownError;
          aErrorMsg  :=
            PCS.PC_FUNCTIONS.TranslateWord('Une erreur s''est produite lors du traitement de l''enregistrement :') ||
            chr(13) ||
            chr(10) ||
            DBMS_UTILITY.FORMAT_ERROR_STACK;
        end if;
    end;

    return vError;
  end processGalAdvancement;

  /**
   * procedure ProcessDaybook
   * Description
   *   Traitement de l'enregistrement du brouillard (création de l'avancement
   *   du lot ou du DF en fonction de l'origine)
   */
  procedure ProcessDaybook(aFAL_LOT_PROGRESS_FOG_ID in FAL_LOT_PROGRESS_FOG.FAL_LOT_PROGRESS_FOG_ID%type, aError out integer, aErrorMsg out varchar2)
  is
    cursor crProcessDaybook(aFAL_LOT_PROGRESS_FOG_ID FAL_LOT_PROGRESS_FOG.FAL_LOT_PROGRESS_FOG_ID%type)
    is
      select     FAL_LOT_PROGRESS_FOG_ID
               , C_PROGRESS_ORIGIN
               , PFG_LOT_REFCOMPL
               , PFG_GAL_REFCOMPL
               , PFG_SEQ
               , PFG_DATE
               , PFG_REF_FACTORY_FLOOR
               , PFG_REF_FACTORY_FLOOR2
               , PFG_RATE_FACTORY_FLOOR
               , PFG_PROC_CONTROL
               , PFG_PROC_EXECUTION
               , PFG_TOOLS1
               , PFG_TOOLS2
               , PFG_TOOLS3
               , PFG_TOOLS4
               , PFG_TOOLS5
               , PFG_TOOLS6
               , PFG_TOOLS7
               , PFG_TOOLS8
               , PFG_TOOLS9
               , PFG_TOOLS10
               , PFG_TOOLS11
               , PFG_TOOLS12
               , PFG_TOOLS13
               , PFG_TOOLS14
               , PFG_TOOLS15
               , PFG_DIC_OPERATOR_ID
               , PFG_DIC_REBUT_ID
               , PFG_DIC_WORK_TYPE_ID
               , PFG_PRODUCT_QTY
               , PFG_PT_REFECT_QTY PFG_PT_REJECT_QTY
               , PFG_CPT_REJECT_QFY PFG_CPT_REJECT_QTY
               , PFG_WORK_TIME
               , PFG_ADJUSTING_TIME
               , PFG_AMOUNT
               , PFG_EAN_CODE
               , PFG_PRODUCT_QTY_UOP
               , PFG_PT_REJECT_QTY_UOP
               , PFG_CPT_REJECT_QTY_UOP
               , PFG_LABEL_CONTROL
               , PFG_LABEL_REJECT
            from FAL_LOT_PROGRESS_FOG
           where FAL_LOT_PROGRESS_FOG_ID = aFAL_LOT_PROGRESS_FOG_ID
      for update nowait;

    tplProcessDaybook crProcessDaybook%rowtype;
  begin
    aError  := faNoError;

    -- Vérification que l'enregistrement n'est pas en cours de modification
    begin
      open crProcessDaybook(aFAL_LOT_PROGRESS_FOG_ID);

      -- et recherche des valeurs
      fetch crProcessDaybook
       into tplProcessDaybook;

      if crProcessDaybook%notfound then
        aError  := faDaybookNotFound;
      end if;

      close crProcessDaybook;
    exception
      when others then
        close crProcessDaybook;

        raise;
    end;

    savepoint spBeforeProcessDaybook;

    -- Si aucune erreur
    if aError = faNoError then
      -- Traitement de l'enregistrement selon l'origine
      if tplProcessDaybook.C_PROGRESS_ORIGIN = poProduction then
        aError  :=
          processLotAdvancement(aPFG_LOT_REFCOMPL          => tplProcessDaybook.PFG_LOT_REFCOMPL
                              , aPFG_SEQ                   => tplProcessDaybook.PFG_SEQ
                              , aPFG_DATE                  => tplProcessDaybook.PFG_DATE
                              , aPFG_REF_FACTORY_FLOOR     => tplProcessDaybook.PFG_REF_FACTORY_FLOOR
                              , aPFG_REF_FACTORY_FLOOR2    => tplProcessDaybook.PFG_REF_FACTORY_FLOOR2
                              , aPFG_RATE_FACTORY_FLOOR    => tplProcessDaybook.PFG_RATE_FACTORY_FLOOR
                              , aPFG_PROC_CONTROL          => tplProcessDaybook.PFG_PROC_CONTROL
                              , aPFG_PROC_EXECUTION        => tplProcessDaybook.PFG_PROC_EXECUTION
                              , aPFG_TOOLS1                => tplProcessDaybook.PFG_TOOLS1
                              , aPFG_TOOLS2                => tplProcessDaybook.PFG_TOOLS2
                              , aPFG_TOOLS3                => tplProcessDaybook.PFG_TOOLS3
                              , aPFG_TOOLS4                => tplProcessDaybook.PFG_TOOLS4
                              , aPFG_TOOLS5                => tplProcessDaybook.PFG_TOOLS5
                              , aPFG_TOOLS6                => tplProcessDaybook.PFG_TOOLS6
                              , aPFG_TOOLS7                => tplProcessDaybook.PFG_TOOLS7
                              , aPFG_TOOLS8                => tplProcessDaybook.PFG_TOOLS8
                              , aPFG_TOOLS9                => tplProcessDaybook.PFG_TOOLS9
                              , aPFG_TOOLS10               => tplProcessDaybook.PFG_TOOLS10
                              , aPFG_TOOLS11               => tplProcessDaybook.PFG_TOOLS11
                              , aPFG_TOOLS12               => tplProcessDaybook.PFG_TOOLS12
                              , aPFG_TOOLS13               => tplProcessDaybook.PFG_TOOLS13
                              , aPFG_TOOLS14               => tplProcessDaybook.PFG_TOOLS14
                              , aPFG_TOOLS15               => tplProcessDaybook.PFG_TOOLS15
                              , aPFG_DIC_OPERATOR_ID       => tplProcessDaybook.PFG_DIC_OPERATOR_ID
                              , aPFG_DIC_REBUT_ID          => tplProcessDaybook.PFG_DIC_REBUT_ID
                              , aPFG_DIC_WORK_TYPE_ID      => tplProcessDaybook.PFG_DIC_WORK_TYPE_ID
                              , aPFG_PRODUCT_QTY           => tplProcessDaybook.PFG_PRODUCT_QTY
                              , aPFG_PT_REJECT_QTY         => tplProcessDaybook.PFG_PT_REJECT_QTY
                              , aPFG_CPT_REJECT_QTY        => tplProcessDaybook.PFG_CPT_REJECT_QTY
                              , aPFG_WORK_TIME             => tplProcessDaybook.PFG_WORK_TIME
                              , aPFG_ADJUSTING_TIME        => tplProcessDaybook.PFG_ADJUSTING_TIME
                              , aPFG_AMOUNT                => tplProcessDaybook.PFG_AMOUNT
                              , aPFG_EAN_CODE              => tplProcessDaybook.PFG_EAN_CODE
                              , aPFG_PRODUCT_QTY_UOP       => tplProcessDaybook.PFG_PRODUCT_QTY_UOP
                              , aPFG_PT_REJECT_QTY_UOP     => tplProcessDaybook.PFG_PT_REJECT_QTY_UOP
                              , aPFG_CPT_REJECT_QTY_UOP    => tplProcessDaybook.PFG_CPT_REJECT_QTY_UOP
                              , aPFG_LABEL_CONTROL         => tplProcessDaybook.PFG_LABEL_CONTROL
                              , aPFG_LABEL_REJECT          => tplProcessDaybook.PFG_LABEL_REJECT
                              , aFAL_LOT_PROGRESS_FOG_ID   => aFAL_LOT_PROGRESS_FOG_ID
                              , aErrorMsg                  => aErrorMsg
                              , aiShutdownExceptions       => 1
                               );
      elsif tplProcessDaybook.C_PROGRESS_ORIGIN = poProject then
        aError  :=
          processGalAdvancement(aPFG_GAL_REFCOMPL      => tplProcessDaybook.PFG_GAL_REFCOMPL
                              , aPFG_SEQ               => tplProcessDaybook.PFG_SEQ
                              , aPFG_DATE              => tplProcessDaybook.PFG_DATE
                              , aPFG_DIC_OPERATOR_ID   => tplProcessDaybook.PFG_DIC_OPERATOR_ID
                              , aPFG_WORK_TIME         => tplProcessDaybook.PFG_WORK_TIME
                              , aPFG_ADJUSTING_TIME    => tplProcessDaybook.PFG_ADJUSTING_TIME
                              , aErrorMsg              => aErrorMsg
                              , aiShutdownExceptions   => 1
                               );
      else
        aError  := faUnknownOrigin;
      end if;
    end if;

    if aError <> faNoError then
      rollback to savepoint spBeforeProcessDaybook;
    end if;

    -- Si aucune erreur
    if aError = faNoError then
      -- Mise à jour du statut
      update FAL_LOT_PROGRESS_FOG PFG
         set C_FOG_APPLY_ERROR = null
           , C_PFG_STATUS = fsProcessed
           , PFG_ERROR_MESSAGE = aErrorMsg
           , PFG_APPLY_DATE = sysdate
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_LOT_PROGRESS_FOG_ID = aFAL_LOT_PROGRESS_FOG_ID;

      -- Archivage de l'enregistrement
      ArchiveDayBook(aFAL_LOT_PROGRESS_FOG_ID);
    else
      -- Sinon l'application a échoué (erreur). Noter l'erreur
      update FAL_LOT_PROGRESS_FOG PFG
         set C_FOG_APPLY_ERROR = lpad(aError, 2, '0')
           , C_PFG_STATUS = fsError
           , PFG_ERROR_MESSAGE = aErrorMsg
           , PFG_APPLY_DATE = sysdate
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_LOT_PROGRESS_FOG_ID = aFAL_LOT_PROGRESS_FOG_ID;

      -- Correction en attendant de normaliser les codes erreurs GAL
      if tplProcessDaybook.C_PROGRESS_ORIGIN = poProject then
        aErrorMsg  := null;
      end if;
    end if;
  exception
    when others then
      case sqlcode
        when -54 then
          aError     := faDaybookUnavailable;
          aErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('L''enregistrement est en cours de modification par un autre utilisateur.');
        else
          aError     := faUnknownError;
          aErrorMsg  :=
            PCS.PC_FUNCTIONS.TranslateWord('Une erreur s''est produite lors du traitement de l''enregistrement :') ||
            chr(13) ||
            chr(10) ||
            DBMS_UTILITY.FORMAT_ERROR_STACK;
      end case;
  end ProcessDaybook;

  /**
   * procedure ArchiveDaybook
   * Description
   *   Archivage de l'enregistrement du brouillard (insertion dans
   *   FAL_LOT_PROGRESS_FOG_HIST et suppression de FAL_LOT_PROGRESS_FOG)
   */
  procedure ArchiveDaybook(aProgressFogId in FAL_LOT_PROGRESS_FOG.FAL_LOT_PROGRESS_FOG_ID%type)
  is
  begin
    -- Insertion dans l'historique
    insert into FAL_LOT_PROGRESS_FOG_HIST
                (FAL_LOT_PROGRESS_FOG_HIST_ID
               , C_FOG_APPLY_ERROR
               , C_PFG_STATUS
               , C_PROGRESS_ORIGIN
               , PFG_SELECTION
               , PFG_LOT_REFCOMPL
               , PFG_GAL_REFCOMPL
               , PFG_SEQ
               , PFG_REF_FACTORY_FLOOR
               , PFG_REF_FACTORY_FLOOR2
               , PFG_RATE_FACTORY_FLOOR
               , PFG_PROC_CONTROL
               , PFG_PROC_EXECUTION
               , PFG_TOOLS1
               , PFG_TOOLS2
               , PFG_TOOLS3
               , PFG_TOOLS4
               , PFG_TOOLS5
               , PFG_TOOLS6
               , PFG_TOOLS7
               , PFG_TOOLS8
               , PFG_TOOLS9
               , PFG_TOOLS10
               , PFG_TOOLS11
               , PFG_TOOLS12
               , PFG_TOOLS13
               , PFG_TOOLS14
               , PFG_TOOLS15
               , PFG_DATE
               , PFG_DIC_OPERATOR_ID
               , PFG_DIC_REBUT_ID
               , PFG_DIC_WORK_TYPE_ID
               , PFG_PRODUCT_QTY
               , PFG_PT_REFECT_QTY
               , PFG_CPT_REJECT_QFY
               , PFG_ADJUSTING_TIME
               , PFG_WORK_TIME
               , PFG_AMOUNT
               , PFG_APPLY_DATE
               , PFG_EAN_CODE
               , PFG_SUP_QTY
               , PFG_DIC_UNIT_OF_MEASURE_ID
               , PFG_QTY_REF2_WORK
               , PFG_PRODUCT_QTY_UOP
               , PFG_PT_REJECT_QTY_UOP
               , PFG_CPT_REJECT_QTY_UOP
               , PFG_LABEL_CONTROL
               , PFG_LABEL_REJECT
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
                )
      select FAL_LOT_PROGRESS_FOG_ID
           , C_FOG_APPLY_ERROR
           , C_PFG_STATUS
           , C_PROGRESS_ORIGIN
           , PFG_SELECTION
           , PFG_LOT_REFCOMPL
           , PFG_GAL_REFCOMPL
           , PFG_SEQ
           , PFG_REF_FACTORY_FLOOR
           , PFG_REF_FACTORY_FLOOR2
           , PFG_RATE_FACTORY_FLOOR
           , PFG_PROC_CONTROL
           , PFG_PROC_EXECUTION
           , PFG_TOOLS1
           , PFG_TOOLS2
           , PFG_TOOLS3
           , PFG_TOOLS4
           , PFG_TOOLS5
           , PFG_TOOLS6
           , PFG_TOOLS7
           , PFG_TOOLS8
           , PFG_TOOLS9
           , PFG_TOOLS10
           , PFG_TOOLS11
           , PFG_TOOLS12
           , PFG_TOOLS13
           , PFG_TOOLS14
           , PFG_TOOLS15
           , PFG_DATE
           , PFG_DIC_OPERATOR_ID
           , PFG_DIC_REBUT_ID
           , PFG_DIC_WORK_TYPE_ID
           , PFG_PRODUCT_QTY
           , PFG_PT_REFECT_QTY
           , PFG_CPT_REJECT_QFY
           , PFG_ADJUSTING_TIME
           , PFG_WORK_TIME
           , PFG_AMOUNT
           , PFG_APPLY_DATE
           , PFG_EAN_CODE
           , PFG_SUP_QTY
           , PFG_DIC_UNIT_OF_MEASURE_ID
           , PFG_QTY_REF2_WORK
           , PFG_PRODUCT_QTY_UOP
           , PFG_PT_REJECT_QTY_UOP
           , PFG_CPT_REJECT_QTY_UOP
           , PFG_LABEL_CONTROL
           , PFG_LABEL_REJECT
           , A_DATECRE
           , A_DATEMOD
           , A_IDCRE
           , A_IDMOD
        from FAL_LOT_PROGRESS_FOG
       where FAL_LOT_PROGRESS_FOG_ID = aProgressFogId;

    -- et suppression du brouillard
    delete from FAL_LOT_PROGRESS_FOG
          where FAL_LOT_PROGRESS_FOG_ID = aProgressFogId;
  end ArchiveDaybook;

  /**
   * procedure processLotAdvancement
   * Description
   *   Génération d'un avancement pour une opération de lot
   */
  procedure processLotAdvancement(
    aPFG_LOT_REFCOMPL              FAL_LOT_PROGRESS_FOG.PFG_LOT_REFCOMPL%type
  , aPFG_SEQ                       FAL_LOT_PROGRESS_FOG.PFG_SEQ%type
  , aPFG_DATE                      FAL_LOT_PROGRESS_FOG.PFG_DATE%type
  , aPFG_REF_FACTORY_FLOOR         FAL_LOT_PROGRESS_FOG.PFG_REF_FACTORY_FLOOR%type
  , aPFG_REF_FACTORY_FLOOR2        FAL_LOT_PROGRESS_FOG.PFG_REF_FACTORY_FLOOR2%type
  , aPFG_RATE_FACTORY_FLOOR        FAL_LOT_PROGRESS_FOG.PFG_RATE_FACTORY_FLOOR%type
  , aPFG_PROC_CONTROL              FAL_LOT_PROGRESS_FOG.PFG_PROC_CONTROL%type
  , aPFG_PROC_EXECUTION            FAL_LOT_PROGRESS_FOG.PFG_PROC_EXECUTION%type
  , aPFG_TOOLS1                    FAL_LOT_PROGRESS_FOG.PFG_TOOLS1%type
  , aPFG_TOOLS2                    FAL_LOT_PROGRESS_FOG.PFG_TOOLS2%type
  , aPFG_TOOLS3                    FAL_LOT_PROGRESS_FOG.PFG_TOOLS3%type
  , aPFG_TOOLS4                    FAL_LOT_PROGRESS_FOG.PFG_TOOLS4%type
  , aPFG_TOOLS5                    FAL_LOT_PROGRESS_FOG.PFG_TOOLS5%type
  , aPFG_TOOLS6                    FAL_LOT_PROGRESS_FOG.PFG_TOOLS6%type
  , aPFG_TOOLS7                    FAL_LOT_PROGRESS_FOG.PFG_TOOLS7%type
  , aPFG_TOOLS8                    FAL_LOT_PROGRESS_FOG.PFG_TOOLS8%type
  , aPFG_TOOLS9                    FAL_LOT_PROGRESS_FOG.PFG_TOOLS9%type
  , aPFG_TOOLS10                   FAL_LOT_PROGRESS_FOG.PFG_TOOLS10%type
  , aPFG_TOOLS11                   FAL_LOT_PROGRESS_FOG.PFG_TOOLS11%type
  , aPFG_TOOLS12                   FAL_LOT_PROGRESS_FOG.PFG_TOOLS12%type
  , aPFG_TOOLS13                   FAL_LOT_PROGRESS_FOG.PFG_TOOLS13%type
  , aPFG_TOOLS14                   FAL_LOT_PROGRESS_FOG.PFG_TOOLS14%type
  , aPFG_TOOLS15                   FAL_LOT_PROGRESS_FOG.PFG_TOOLS15%type
  , aPFG_DIC_OPERATOR_ID           FAL_LOT_PROGRESS_FOG.PFG_DIC_OPERATOR_ID%type
  , aPFG_DIC_REBUT_ID              FAL_LOT_PROGRESS_FOG.PFG_DIC_REBUT_ID%type
  , aPFG_DIC_WORK_TYPE_ID          FAL_LOT_PROGRESS_FOG.PFG_DIC_WORK_TYPE_ID%type
  , aPFG_PRODUCT_QTY               FAL_LOT_PROGRESS_FOG.PFG_PRODUCT_QTY%type
  , aPFG_PT_REJECT_QTY             FAL_LOT_PROGRESS_FOG.PFG_PT_REFECT_QTY%type
  , aPFG_CPT_REJECT_QTY            FAL_LOT_PROGRESS_FOG.PFG_CPT_REJECT_QFY%type
  , aPFG_WORK_TIME                 FAL_LOT_PROGRESS_FOG.PFG_WORK_TIME%type
  , aPFG_ADJUSTING_TIME            FAL_LOT_PROGRESS_FOG.PFG_ADJUSTING_TIME%type
  , aPFG_AMOUNT                    FAL_LOT_PROGRESS_FOG.PFG_AMOUNT%type
  , aPFG_EAN_CODE                  FAL_LOT_PROGRESS_FOG.PFG_EAN_CODE%type
  , aPFG_PRODUCT_QTY_UOP           FAL_LOT_PROGRESS_FOG.PFG_PRODUCT_QTY_UOP%type
  , aPFG_PT_REJECT_QTY_UOP         FAL_LOT_PROGRESS_FOG.PFG_PT_REJECT_QTY_UOP%type
  , aPFG_CPT_REJECT_QTY_UOP        FAL_LOT_PROGRESS_FOG.PFG_CPT_REJECT_QTY_UOP%type
  , aPFG_LABEL_CONTROL             FAL_LOT_PROGRESS_FOG.PFG_LABEL_CONTROL%type
  , aPFG_LABEL_REJECT              FAL_LOT_PROGRESS_FOG.PFG_LABEL_REJECT%type
  , aError                  out    integer
  , aErrorMsg               out    varchar2
  , aiShutdownExceptions    in     integer default 0
  )
  is
  begin
    aError  :=
      processLotAdvancement(aPFG_LOT_REFCOMPL         => aPFG_LOT_REFCOMPL
                          , aPFG_SEQ                  => aPFG_SEQ
                          , aPFG_DATE                 => aPFG_DATE
                          , aPFG_REF_FACTORY_FLOOR    => aPFG_REF_FACTORY_FLOOR
                          , aPFG_REF_FACTORY_FLOOR2   => aPFG_REF_FACTORY_FLOOR2
                          , aPFG_RATE_FACTORY_FLOOR   => aPFG_RATE_FACTORY_FLOOR
                          , aPFG_PROC_CONTROL         => aPFG_PROC_CONTROL
                          , aPFG_PROC_EXECUTION       => aPFG_PROC_EXECUTION
                          , aPFG_TOOLS1               => aPFG_TOOLS1
                          , aPFG_TOOLS2               => aPFG_TOOLS2
                          , aPFG_TOOLS3               => aPFG_TOOLS3
                          , aPFG_TOOLS4               => aPFG_TOOLS4
                          , aPFG_TOOLS5               => aPFG_TOOLS5
                          , aPFG_TOOLS6               => aPFG_TOOLS6
                          , aPFG_TOOLS7               => aPFG_TOOLS7
                          , aPFG_TOOLS8               => aPFG_TOOLS8
                          , aPFG_TOOLS9               => aPFG_TOOLS9
                          , aPFG_TOOLS10              => aPFG_TOOLS10
                          , aPFG_TOOLS11              => aPFG_TOOLS11
                          , aPFG_TOOLS12              => aPFG_TOOLS12
                          , aPFG_TOOLS13              => aPFG_TOOLS13
                          , aPFG_TOOLS14              => aPFG_TOOLS14
                          , aPFG_TOOLS15              => aPFG_TOOLS15
                          , aPFG_DIC_OPERATOR_ID      => aPFG_DIC_OPERATOR_ID
                          , aPFG_DIC_REBUT_ID         => aPFG_DIC_REBUT_ID
                          , aPFG_DIC_WORK_TYPE_ID     => aPFG_DIC_WORK_TYPE_ID
                          , aPFG_PRODUCT_QTY          => aPFG_PRODUCT_QTY
                          , aPFG_PT_REJECT_QTY        => aPFG_PT_REJECT_QTY
                          , aPFG_CPT_REJECT_QTY       => aPFG_CPT_REJECT_QTY
                          , aPFG_WORK_TIME            => aPFG_WORK_TIME
                          , aPFG_ADJUSTING_TIME       => aPFG_ADJUSTING_TIME
                          , aPFG_AMOUNT               => aPFG_AMOUNT
                          , aPFG_EAN_CODE             => aPFG_EAN_CODE
                          , aPFG_PRODUCT_QTY_UOP      => aPFG_PRODUCT_QTY_UOP
                          , aPFG_PT_REJECT_QTY_UOP    => aPFG_PT_REJECT_QTY_UOP
                          , aPFG_CPT_REJECT_QTY_UOP   => aPFG_CPT_REJECT_QTY_UOP
                          , aPFG_LABEL_CONTROL        => aPFG_LABEL_CONTROL
                          , aPFG_LABEL_REJECT         => aPFG_LABEL_REJECT
                          , aErrorMsg                 => aErrorMsg
                          , aiShutdownExceptions      => aiShutdownExceptions
                           );
  end processLotAdvancement;

  /**
   * procedure processGalAdvancement
   * Description
   *   Génération d'un avancement pour une opération de dossier de fab
   */
  procedure processGalAdvancement(
    aPFG_GAL_REFCOMPL    in     FAL_LOT_PROGRESS_FOG.PFG_GAL_REFCOMPL%type
  , aPFG_SEQ             in     FAL_LOT_PROGRESS_FOG.PFG_SEQ%type
  , aPFG_DATE            in     FAL_LOT_PROGRESS_FOG.PFG_DATE%type
  , aPFG_DIC_OPERATOR_ID in     FAL_LOT_PROGRESS_FOG.PFG_DIC_OPERATOR_ID%type
  , aPFG_WORK_TIME       in     FAL_LOT_PROGRESS_FOG.PFG_WORK_TIME%type
  , aPFG_ADJUSTING_TIME  in     FAL_LOT_PROGRESS_FOG.PFG_ADJUSTING_TIME%type
  , aError               out    integer
  , aErrorMsg            out    varchar2
  , aiShutdownExceptions in     integer default 0
  )
  is
  begin
    aError  :=
      processGalAdvancement(aPFG_GAL_REFCOMPL      => aPFG_GAL_REFCOMPL
                          , aPFG_SEQ               => aPFG_SEQ
                          , aPFG_DATE              => aPFG_DATE
                          , aPFG_DIC_OPERATOR_ID   => aPFG_DIC_OPERATOR_ID
                          , aPFG_WORK_TIME         => aPFG_WORK_TIME
                          , aPFG_ADJUSTING_TIME    => aPFG_ADJUSTING_TIME
                          , aErrorMsg              => aErrorMsg
                          , aiShutdownExceptions   => aiShutdownExceptions
                           );
  end processGalAdvancement;

/*
  Processus : Mise à jour opération sur suppression (extourne) d'un suivi opératoire
*/
  procedure UpdateMainOpeOnDeleteTrack(
    aFAL_SCHEDULE_STEP_ID number
  , aFLP_PRODUCT_QTY      number
  , aFLP_PT_REJECT_QTY    number
  , aFLP_CPT_REJECT_QTY   number
  , aFLP_SUP_QTY          number
  , aFLP_WORK_TIME        number
  , aFLP_ADJUSTING_TIME   number
  , aFLP_AMOUNT           number
  )
  is
    cursor crOperation
    is
      select TAL_PLAN_QTY
           , TAL_RELEASE_QTY
           , TAL_REJECTED_QTY
           , TAL_R_METER
           , case nvl(SCS_QTY_REF_WORK, 0)
               when 0 then 1
               else SCS_QTY_REF_WORK
             end SCS_QTY_REF_WORK
           , TAL_ACHIEVED_TSK
           , SCS_QTY_FIX_ADJUSTING
           , SCS_ADJUSTING_TIME
           , SCS_WORK_TIME
           , TAL_ACHIEVED_AD_TSK
           , TAL_DUE_TSK
           , C_OPERATION_TYPE
        from FAL_TASK_LINK FTL
       where FAL_SCHEDULE_STEP_ID = aFAL_SCHEDULE_STEP_ID;

    tplOperation           crOperation%rowtype;
    newTAL_RELEASE_QTY     number;
    newTAL_REJECTED_QTY    number;
    newTAL_PLAN_QTY        number;
    newTAL_R_METER         number;
    newTAL_ACHIEVED_TSK    number;
    newTAL_ACHIEVED_AD_TSK number;
    newTAL_DUE_QTY         number;
    newTAL_TSK_AD_BALANCE  number;
    newTAL_TSK_W_BALANCE   number;
    curDueAdjustingTime    number;
    curDueWorkTime         number;
    curAchievedAdjWorkTime number;
  begin
    open crOperation;

    fetch crOperation
     into tplOperation;

    close crOperation;

    -- Qté réalisée
    newTAL_RELEASE_QTY      := tplOperation.TAL_RELEASE_QTY - aFLP_PRODUCT_QTY;
    -- Qté rebut
    newTAL_REJECTED_QTY     := tplOperation.TAL_REJECTED_QTY - aFLP_PT_REJECT_QTY - aFLP_CPT_REJECT_QTY;

    -- Qté demandée
    if tplOperation.C_OPERATION_TYPE = '4' then
      newTAL_PLAN_QTY  := tplOperation.TAL_PLAN_QTY - aFLP_PRODUCT_QTY - aFLP_PT_REJECT_QTY - aFLP_CPT_REJECT_QTY;
    else
      newTAL_PLAN_QTY  := tplOperation.TAL_PLAN_QTY - aFLP_SUP_QTY;
    end if;

    -- Compteur R
    newTAL_R_METER          := tplOperation.TAL_R_METER - aFLP_PT_REJECT_QTY - aFLP_CPT_REJECT_QTY;
    -- Qté solde
    newTAL_DUE_QTY          := greatest(newTAL_PLAN_QTY - newTAL_RELEASE_QTY - newTAL_R_METER, 0);
    -- Travail réalisé
    newTAL_ACHIEVED_TSK     := tplOperation.TAL_ACHIEVED_TSK - aFLP_WORK_TIME;
    -- Réglage réalisé
    newTAL_ACHIEVED_AD_TSK  := tplOperation.TAL_ACHIEVED_AD_TSK - aFLP_ADJUSTING_TIME;

    if newTAL_DUE_QTY = 0 then
      newTAL_TSK_AD_BALANCE  := 0;
      newTAL_TSK_W_BALANCE   := 0;
    else
      -- Calcul du temps de réglage restant
      if tplOperation.SCS_QTY_FIX_ADJUSTING = 0 then
        curDueAdjustingTime  := tplOperation.SCS_ADJUSTING_TIME;
      else
        curDueAdjustingTime  := FAL_TOOLS.RoundSuccInt(newTAL_DUE_QTY / tplOperation.SCS_QTY_FIX_ADJUSTING) * tplOperation.SCS_ADJUSTING_TIME;
      end if;

      -- Calcul du temps de travail restant
      curDueWorkTime  := (newTAL_DUE_QTY / tplOperation.SCS_QTY_REF_WORK) * tplOperation.SCS_WORK_TIME;

      if     cProgressTime
         and (aFLP_PRODUCT_QTY + aFLP_PT_REJECT_QTY + aFLP_CPT_REJECT_QTY = 0) then
        if cProgressMode = 1 then
          -- Solde Réglage
          newTAL_TSK_AD_BALANCE  := greatest(0, curDueAdjustingTime - newTAL_ACHIEVED_AD_TSK);
          -- Solde travail
          newTAL_TSK_W_BALANCE   := greatest(0, curDueWorkTime - newTAL_ACHIEVED_TSK);
        else
          -- La config FAL_PROGRESS_MODE = 0 => Saisie uniquement d'un seul temps,
          -- cumulant le réglage et le travail, dans le temps travail réalisé.
          newTAL_TSK_AD_BALANCE  := greatest(0, curDueAdjustingTime - newTAL_ACHIEVED_TSK);

          if newTAL_TSK_AD_BALANCE = 0 then
            newTAL_TSK_W_BALANCE  := greatest(0, tplOperation.TAL_DUE_TSK - newTAL_ACHIEVED_TSK);
          else
            newTAL_TSK_W_BALANCE  := curDueWorkTime;
          end if;
        end if;
      else   -- FAL_PROGRESS_TIME = False ou quantité non nulle
        if     (tplOperation.SCS_QTY_FIX_ADJUSTING = 0)
           and cWorkBalance then
          -- Pas encore de quantité ni de travail réalisé
          if     ( (newTAL_RELEASE_QTY + newTAL_REJECTED_QTY) = 0)
             and (newTAL_ACHIEVED_TSK = 0) then
            curAchievedAdjWorkTime  := newTAL_ACHIEVED_TSK + newTAL_ACHIEVED_AD_TSK;
            newTAL_TSK_AD_BALANCE   := greatest(0, curDueAdjustingTime - curAchievedAdjWorkTime);
            newTAL_TSK_W_BALANCE    := greatest(0, curDueWorkTime - greatest(0,(curAchievedAdjWorkTime - curDueAdjustingTime) ) );
          else
            newTAL_TSK_AD_BALANCE  := 0;
            newTAL_TSK_W_BALANCE   := curDueWorkTime;
          end if;
        else   -- (SCS_QTY_FIX_ADJUSTING <> 0) or Config FAL_WORK_BALANCE = False
          newTAL_TSK_AD_BALANCE  := curDueAdjustingTime;
          newTAL_TSK_W_BALANCE   := curDueWorkTime;
        end if;
      end if;
    end if;

    update FAL_TASK_LINK
       set TAL_RELEASE_QTY = newTAL_RELEASE_QTY
         , TAL_REJECTED_QTY = newTAL_REJECTED_QTY
         , TAL_PLAN_QTY = newTAL_PLAN_QTY
         , TAL_R_METER = newTAL_R_METER
         , TAL_DUE_QTY = newTAL_DUE_QTY
         , TAL_AVALAIBLE_QTY =
             case C_OPERATION_TYPE
               when '4' then TAL_AVALAIBLE_QTY
               else greatest(TAL_AVALAIBLE_QTY + aFLP_PRODUCT_QTY + aFLP_PT_REJECT_QTY + aFLP_CPT_REJECT_QTY - aFLP_SUP_QTY, 0)
             end
         , TAL_ACHIEVED_TSK = newTAL_ACHIEVED_TSK
         , TAL_ACHIEVED_AD_TSK = newTAL_ACHIEVED_AD_TSK
         , TAL_TSK_W_BALANCE = newTAL_TSK_W_BALANCE
         , TAL_TSK_AD_BALANCE = newTAL_TSK_AD_BALANCE
         , TAL_TSK_BALANCE = newTAL_TSK_W_BALANCE + newTAL_TSK_AD_BALANCE
         , TAL_PLAN_RATE = (newTAL_DUE_QTY / decode(nvl(SCS_QTY_REF_WORK, 0), 0, 1, SCS_QTY_REF_WORK) ) * SCS_PLAN_RATE
         , TAL_END_REAL_DATE = null
         , TAL_TASK_REAL_TIME = null
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_SCHEDULE_STEP_ID = aFAL_SCHEDULE_STEP_ID;
  end UpdateMainOpeOnDeleteTrack;

  function updatePreviousIndependant(aFalLotId number, aScsStepNumber number, aQty number)
    return number
  is
    cursor crOperation
    is
      select   FAL_SCHEDULE_STEP_ID
             , C_OPERATION_TYPE
             , TAL_AVALAIBLE_QTY
          from FAL_TASK_LINK FTL
         where FAL_LOT_ID = aFalLotId
           and SCS_STEP_NUMBER < aScsStepNumber
      order by SCS_STEP_NUMBER desc;

    aQtyToUpdate         number;
    newTAL_AVALAIBLE_QTY number;
  begin
    aQtyToUpdate  := aQty;

    for tplOperation in crOperation loop
      if tplOperation.C_OPERATION_TYPE = '4' then
        newTAL_AVALAIBLE_QTY  := greatest(0, tplOperation.TAL_AVALAIBLE_QTY - aQtyToUpdate);
        aQtyToUpdate          := aQtyToUpdate - tplOperation.TAL_AVALAIBLE_QTY;

        update FAL_TASK_LINK
           set TAL_AVALAIBLE_QTY = newTAL_AVALAIBLE_QTY
         where FAL_SCHEDULE_STEP_ID = tplOperation.FAL_SCHEDULE_STEP_ID;

        if aQtyToUpdate <= 0 then
          exit;
        end if;
      else
        exit;
      end if;
    end loop;

    return aQtyToUpdate;
  end updatePreviousIndependant;

  procedure UpdateOtherOpeOnDeleteTrack(
    aFalLotId            number
  , aScsStepNumber       number
  , aFLP_PRODUCT_QTY     number
  , aFLP_PT_REJECT_QTY   number
  , aFLP_CPT_REJECT_QTY  number
  , aFLP_SUP_QTY         number
  , bUpdateNextOperation boolean default false
  , nextMainOperationId  number default null
  , bDelTrackOnIndepend  boolean default false
  , aContext             integer
  )
  is
    type TTabSecondaryOperation is record(
      FAL_SCHEDULE_STEP_ID  FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
    , C_OPERATION_TYPE      FAL_TASK_LINK.C_OPERATION_TYPE%type
    , C_TASK_TYPE           FAL_TASK_LINK.C_TASK_TYPE%type
    , TAL_RELEASE_QTY       FAL_TASK_LINK.TAL_RELEASE_QTY%type
    , TAL_R_METER           FAL_TASK_LINK.TAL_R_METER%type
    , TAL_PLAN_QTY          FAL_TASK_LINK.TAL_PLAN_QTY%type
    , SCS_QTY_FIX_ADJUSTING FAL_TASK_LINK.SCS_QTY_FIX_ADJUSTING%type
    , TAL_REJECTED_QTY      FAL_TASK_LINK.TAL_REJECTED_QTY%type
    , SCS_ADJUSTING_TIME    FAL_TASK_LINK.SCS_ADJUSTING_TIME%type
    , TAL_ACHIEVED_AD_TSK   FAL_TASK_LINK.TAL_ACHIEVED_AD_TSK%type
    , TAL_TSK_AD_BALANCE    FAL_TASK_LINK.TAL_TSK_AD_BALANCE%type
    , TAL_TSK_W_BALANCE     FAL_TASK_LINK.TAL_TSK_W_BALANCE%type
    , TAL_ACHIEVED_TSK      FAL_TASK_LINK.TAL_ACHIEVED_TSK%type
    , SCS_QTY_REF_WORK      FAL_TASK_LINK.SCS_QTY_REF_WORK%type
    , SCS_WORK_TIME         FAL_TASK_LINK.SCS_WORK_TIME%type
    , TAL_ACHIEVED_AMT      FAL_TASK_LINK.TAL_ACHIEVED_AMT%type
    , SCS_DIVISOR_AMOUNT    FAL_TASK_LINK.SCS_DIVISOR_AMOUNT%type
    , SCS_QTY_REF_AMOUNT    FAL_TASK_LINK.SCS_QTY_REF_AMOUNT%type
    , SCS_AMOUNT            FAL_TASK_LINK.SCS_AMOUNT%type
    , TAL_AVALAIBLE_QTY     FAL_TASK_LINK.TAL_AVALAIBLE_QTY%type
    , SCS_STEP_NUMBER       FAL_TASK_LINK.SCS_STEP_NUMBER%type
    );

    type TTabSecondaryOperations is table of TTabSecondaryOperation
      index by binary_integer;

    buffSelectSecOperations varchar2(32000);
    vOpeToUpdate            TTabSecondaryOperations;
    idx                     integer;
    newTAL_RELEASE_QTY      number;
    newTAL_R_METER          number;
    newTAL_PLAN_QTY         number;
    newTAL_DUE_QTY          number;
    newTAL_ACHIEVED_AD_TSK  number;
    newTAL_TSK_AD_BALANCE   number;
    newTAL_TSK_W_BALANCE    number;
    newTAL_ACHIEVED_TSK     number;
    newTAL_ACHIEVED_AMT     number;
    newTAL_AVALAIBLE_QTY    number;
    nBalanceQty             number;
  begin
    buffSelectSecOperations  :=
      'select FAL_SCHEDULE_STEP_ID' ||
      '     , C_OPERATION_TYPE' ||
      '     , C_TASK_TYPE' ||
      '     , TAL_RELEASE_QTY' ||
      '     , TAL_R_METER' ||
      '     , TAL_PLAN_QTY' ||
      '     , SCS_QTY_FIX_ADJUSTING' ||
      '     , TAL_REJECTED_QTY' ||
      '     , SCS_ADJUSTING_TIME' ||
      '     , TAL_ACHIEVED_AD_TSK' ||
      '     , TAL_TSK_AD_BALANCE' ||
      '     , TAL_TSK_W_BALANCE' ||
      '     , TAL_ACHIEVED_TSK' ||
      '     , decode(nvl(SCS_QTY_REF_WORK, 0), 0, 1, SCS_QTY_REF_WORK) SCS_QTY_REF_WORK' ||
      '     , SCS_WORK_TIME' ||
      '     , TAL_ACHIEVED_AMT' ||
      '     , SCS_DIVISOR_AMOUNT' ||
      '     , decode(nvl(SCS_QTY_REF_AMOUNT, 0), 0, 1, SCS_QTY_REF_AMOUNT) SCS_QTY_REF_AMOUNT' ||
      '     , SCS_AMOUNT' ||
      '     , TAL_AVALAIBLE_QTY' ||
      '     , SCS_STEP_NUMBER' ||
      '  from FAL_TASK_LINK' ||
      ' where FAL_LOT_ID = :aFalLotId';

    if bUpdateNextOperation then
      if nextMainOperationId is not null then
        -- Mise à jour des opérations principales et secondaires suivantes de la première principale après l'opération "suivie"
        buffSelectSecOperations  := buffSelectSecOperations || ' and C_OPERATION_TYPE in (''1'', ''2'') ';
        buffSelectSecOperations  := buffSelectSecOperations || ' and SCS_STEP_NUMBER > :aScsStepNumber' || ' order by SCS_STEP_NUMBER asc';
      else
        -- Mise à jour des opérations secondaires dépendantes de la première principale après l'opération "suivie"
        buffSelectSecOperations  := buffSelectSecOperations || ' and SCS_STEP_NUMBER > :aScsStepNumber' || ' order by SCS_STEP_NUMBER asc';
      end if;
    else
      if nextMainOperationId is not null then
        -- Mise à jour de la première opération principale après l'opération "suivie"
        buffSelectSecOperations  := buffSelectSecOperations || ' and FAL_SCHEDULE_STEP_ID = :nextMainOperationId';
      else
        -- Mise à jour des opérations secondaires dépendantes de l'opération "suivie"
        if (cPpsAscDsc = 1) then
          buffSelectSecOperations  := buffSelectSecOperations || ' and SCS_STEP_NUMBER < :aScsStepNumber' || ' order by SCS_STEP_NUMBER desc';
        else
          buffSelectSecOperations  := buffSelectSecOperations || ' and SCS_STEP_NUMBER > :aScsStepNumber' || ' order by SCS_STEP_NUMBER asc';
        end if;
      end if;
    end if;

    if     not bUpdateNextOperation
       and nextMainOperationId is not null then
      execute immediate buffSelectSecOperations
      bulk collect into vOpeToUpdate
                  using aFalLotId, nextMainOperationId;
    else
      execute immediate buffSelectSecOperations
      bulk collect into vOpeToUpdate
                  using aFalLotId, aScsStepNumber;
    end if;

    if vOpeToUpdate.count > 0 then
      for idx in vOpeToUpdate.first .. vOpeToUpdate.last loop
        if     (nextMainOperationId is null)
           and (vOpeToUpdate(idx).C_OPERATION_TYPE = '1') then
          exit;
        end if;

        if    (    nextMainOperationId is not null
               and vOpeToUpdate(idx).C_OPERATION_TYPE in('1', '2') )
           or (vOpeToUpdate(idx).C_OPERATION_TYPE = '2') then
          newTAL_RELEASE_QTY      := vOpeToUpdate(idx).TAL_RELEASE_QTY;
          newTAL_ACHIEVED_TSK     := vOpeToUpdate(idx).TAL_ACHIEVED_TSK;
          newTAL_ACHIEVED_AD_TSK  := vOpeToUpdate(idx).TAL_ACHIEVED_AD_TSK;
          newTAL_TSK_AD_BALANCE   := vOpeToUpdate(idx).TAL_TSK_AD_BALANCE;
          newTAL_TSK_W_BALANCE    := vOpeToUpdate(idx).TAL_TSK_W_BALANCE;
          newTAL_ACHIEVED_AMT     := vOpeToUpdate(idx).TAL_ACHIEVED_AMT;

          if     not bUpdateNextOperation
             and nextMainOperationId is null then
            -- Qté réalisée
            newTAL_RELEASE_QTY   := newTAL_RELEASE_QTY - aFLP_PRODUCT_QTY;
            -- Travail réalisé
            newTAL_ACHIEVED_TSK  := newTAL_ACHIEVED_TSK -( (aFLP_PRODUCT_QTY / vOpeToUpdate(idx).SCS_QTY_REF_WORK) * vOpeToUpdate(idx).SCS_WORK_TIME);

            -- Montant réalisé
            if vOpeToUpdate(idx).SCS_DIVISOR_AMOUNT = 1 then
              newTAL_ACHIEVED_AMT  := newTAL_ACHIEVED_AMT -( (aFLP_PRODUCT_QTY / vOpeToUpdate(idx).SCS_QTY_REF_AMOUNT) * vOpeToUpdate(idx).SCS_AMOUNT);
            else
              newTAL_ACHIEVED_AMT  := newTAL_ACHIEVED_AMT -( (aFLP_PRODUCT_QTY * vOpeToUpdate(idx).SCS_QTY_REF_AMOUNT) * vOpeToUpdate(idx).SCS_AMOUNT);
            end if;
          end if;

          -- Compteur R
          newTAL_R_METER          := vOpeToUpdate(idx).TAL_R_METER - aFLP_PT_REJECT_QTY - aFLP_CPT_REJECT_QTY;
          -- Qté demandée
          newTAL_PLAN_QTY         := vOpeToUpdate(idx).TAL_PLAN_QTY - aFLP_SUP_QTY;
          -- Qté solde
          newTAL_DUE_QTY          := greatest(0, newTAL_PLAN_QTY - newTAL_RELEASE_QTY - newTAL_R_METER);

          -- Réglage Réalise
          -- La config FAL_WORK_BALANCE est implicitement prise en compte à travers
          -- la valeur de FAL_TASK_LINK.TAL_TSK_AD_BALANCE.
          -- Une quantité fixe de réglage différente de 0 prédomine sur cette config.
          if     not bUpdateNextOperation
             and nextMainOperationId is null then
            if vOpeToUpdate(idx).SCS_QTY_FIX_ADJUSTING = 0 then
              if    not cWorkBalance
                 or ( (newTAL_RELEASE_QTY + vOpeToUpdate(idx).TAL_REJECTED_QTY) = 0) then
                newTAL_ACHIEVED_AD_TSK  := greatest(0, vOpeToUpdate(idx).TAL_ACHIEVED_AD_TSK - vOpeToUpdate(idx).SCS_ADJUSTING_TIME);
              end if;
            else
              newTAL_ACHIEVED_AD_TSK  :=
                vOpeToUpdate(idx).TAL_ACHIEVED_AD_TSK -
                FAL_TOOLS.RoundSuccInt(aFLP_PRODUCT_QTY / vOpeToUpdate(idx).SCS_QTY_FIX_ADJUSTING) * vOpeToUpdate(idx).SCS_ADJUSTING_TIME;
            end if;
          end if;

          if    nextMainOperationId is null
             or not cProgressTime then
            if newTAL_DUE_QTY = 0 then
              newTAL_TSK_AD_BALANCE  := 0;
              newTAL_TSK_W_BALANCE   := 0;
            else
              -- Solde Réglage
              if vOpeToUpdate(idx).SCS_QTY_FIX_ADJUSTING = 0 then
                if     not bUpdateNextOperation
                   and nextMainOperationId is null then
                  if     cWorkBalance
                     and (newTAL_ACHIEVED_AD_TSK > 0) then
                    newTAL_TSK_AD_BALANCE  := 0;
                  else
                    newTAL_TSK_AD_BALANCE  := vOpeToUpdate(idx).SCS_ADJUSTING_TIME;
                  end if;
                end if;
              else
                newTAL_TSK_AD_BALANCE  :=
                                         FAL_TOOLS.RoundSuccInt(newTAL_DUE_QTY / vOpeToUpdate(idx).SCS_QTY_FIX_ADJUSTING)
                                         * vOpeToUpdate(idx).SCS_ADJUSTING_TIME;
              end if;

              newTAL_TSK_W_BALANCE  := newTAL_DUE_QTY / vOpeToUpdate(idx).SCS_QTY_REF_WORK * vOpeToUpdate(idx).SCS_WORK_TIME;
            end if;
          end if;

          if     nextMainOperationId is not null
             and not bUpdateNextOperation then
            if bDelTrackOnIndepend then
              newTAL_AVALAIBLE_QTY  := vOpeToUpdate(idx).TAL_AVALAIBLE_QTY + aFLP_PT_REJECT_QTY + aFLP_CPT_REJECT_QTY;
            else
              if vOpeToUpdate(idx).TAL_AVALAIBLE_QTY >= aFLP_PRODUCT_QTY then
                newTAL_AVALAIBLE_QTY  := vOpeToUpdate(idx).TAL_AVALAIBLE_QTY - aFLP_PRODUCT_QTY;
              else
                -- Il y a plus de quantité à enlever que ce qui est en disponible, on en enlève alors sur les opérations indépendantes précédentes
                newTAL_AVALAIBLE_QTY  := 0;
                nBalanceQty           :=
                  updatePreviousIndependant(aFalLotId        => aFalLotId
                                          , aScsStepNumber   => vOpeToUpdate(idx).SCS_STEP_NUMBER
                                          , aQty             => aFLP_PRODUCT_QTY - vOpeToUpdate(idx).TAL_AVALAIBLE_QTY
                                           );

                if     (nBalanceQty > 0)
                   and (vOpeToUpdate(idx).C_TASK_TYPE = '2')
                   and (aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchSplitting) then
                  newTAL_AVALAIBLE_QTY  := -nBalanceQty;
                end if;
              end if;
            end if;
          else
            newTAL_AVALAIBLE_QTY  := vOpeToUpdate(idx).TAL_AVALAIBLE_QTY;
          end if;

          update FAL_TASK_LINK
             set TAL_AVALAIBLE_QTY = newTAL_AVALAIBLE_QTY
               , TAL_RELEASE_QTY = newTAL_RELEASE_QTY
               , TAL_R_METER = newTAL_R_METER
               , TAL_PLAN_QTY = newTAL_PLAN_QTY
               , TAL_DUE_QTY = newTAL_DUE_QTY
               , TAL_ACHIEVED_TSK = newTAL_ACHIEVED_TSK
               , TAL_ACHIEVED_AD_TSK = newTAL_ACHIEVED_AD_TSK
               , TAL_TSK_AD_BALANCE = newTAL_TSK_AD_BALANCE
               , TAL_TSK_W_BALANCE = newTAL_TSK_W_BALANCE
               , TAL_TSK_BALANCE = newTAL_TSK_W_BALANCE + newTAL_TSK_AD_BALANCE
               , TAL_PLAN_RATE = (newTAL_DUE_QTY / decode(nvl(SCS_QTY_REF_WORK, 0), 0, 1, SCS_QTY_REF_WORK) ) * SCS_PLAN_RATE
               , TAL_END_REAL_DATE = null
               , TAL_TASK_REAL_TIME = null
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where FAL_SCHEDULE_STEP_ID = vOpeToUpdate(idx).FAL_SCHEDULE_STEP_ID;
        end if;
      end loop;
    end if;
  end UpdateOtherOpeOnDeleteTrack;

  /**
   * procedure CreateReversalProgressTrack
   * Description
   *   Création du suivi de type extourne
   * @version 2003
   * @author CLE
   * @lastUpdate age 13.04.2012
   * @public
   * @param      aFalLotProgressId   ID du suivi d'origine
   * @param aFromCall : Provenance de l'appel. 1 = Supression suivi, 2 = Split lot, 3 = etc...
   */
  procedure CreateReversalProgressTrack(aFalLotProgressId FAL_LOT_PROGRESS.FAL_LOT_PROGRESS_ID%type, aFromCall in number)
  is
    aErrorMsg   varchar2(255);
    vFAL_LOT_ID number;
  begin
    insert into FAL_LOT_PROGRESS
                (FAL_LOT_PROGRESS_ID
               , FAL_LOT_ID
               , LOT_REFCOMPL
               , FAL_SCHEDULE_STEP_ID
               , FAL_TASK_ID
               , FAL_FACTORY_FLOOR_ID
               , FLP_PRODUCT_QTY
               , FLP_PT_REJECT_QTY
               , FLP_CPT_REJECT_QTY
               , FLP_ADJUSTING_TIME
               , FLP_WORK_TIME
               , FLP_AMOUNT
               , FLP_SHORT_DESCR
               , FLP_SEQ
               , FLP_LABEL_CONTROL
               , FLP_LABEL_REJECT
               , FLP_DATE1
               , FLP_DATE2
               , FLP_EAN_CODE
               , FLP_RATE
               , FLP_SEQ_ORIGIN
               , PPS_OPERATION_PROCEDURE_ID
               , PPS_PPS_OPERATION_PROCEDURE_ID
               , DIC_REBUT_ID
               , DIC_WORK_TYPE_ID
               , DIC_OPERATOR_ID
               , DIC_FREE_TASK_CODE_ID
               , DIC_FREE_TASK_CODE2_ID
               , FLP_ADJUSTING_RATE
               , FLP_SUP_QTY
               , FLP_MANUAL
               , FLP_CONVERSION_FACTOR
               , DIC_UNIT_OF_MEASURE_ID
               , FLP_QTY_REF2_WORK
               , FLP_PRODUCT_QTY_UOP
               , FLP_PT_REJECT_QTY_UOP
               , FLP_CPT_REJECT_QTY_UOP
               , FAL_FAL_FACTORY_FLOOR_ID
               , PPS_TOOLS1_ID
               , PPS_TOOLS2_ID
               , PPS_TOOLS3_ID
               , PPS_TOOLS4_ID
               , PPS_TOOLS5_ID
               , PPS_TOOLS6_ID
               , PPS_TOOLS7_ID
               , PPS_TOOLS8_ID
               , PPS_TOOLS9_ID
               , PPS_TOOLS10_ID
               , PPS_TOOLS11_ID
               , PPS_TOOLS12_ID
               , PPS_TOOLS13_ID
               , PPS_TOOLS14_ID
               , PPS_TOOLS15_ID
               , FLP_REVERSAL
               , FAL_FAL_LOT_PROGRESS_ID
               , DOC_POSITION_DETAIL_ID
               , A_DATECRE
               , A_IDCRE
                )
      select GetNewId
           , FAL_LOT_ID
           , LOT_REFCOMPL
           , FAL_SCHEDULE_STEP_ID
           , FAL_TASK_ID
           , FAL_FACTORY_FLOOR_ID
           , -FLP_PRODUCT_QTY
           , -FLP_PT_REJECT_QTY
           , -FLP_CPT_REJECT_QTY
           , -FLP_ADJUSTING_TIME
           , -FLP_WORK_TIME
           , -FLP_AMOUNT
           , FLP_SHORT_DESCR
           , FLP_SEQ
           , FLP_LABEL_CONTROL
           , FLP_LABEL_REJECT
           , FLP_DATE1
           , FLP_DATE2
           , FLP_EAN_CODE
           , FLP_RATE
           , FLP_SEQ_ORIGIN
           , PPS_OPERATION_PROCEDURE_ID
           , PPS_PPS_OPERATION_PROCEDURE_ID
           , DIC_REBUT_ID
           , DIC_WORK_TYPE_ID
           , DIC_OPERATOR_ID
           , DIC_FREE_TASK_CODE_ID
           , DIC_FREE_TASK_CODE2_ID
           , FLP_ADJUSTING_RATE
           , -FLP_SUP_QTY
           , FLP_MANUAL
           , FLP_CONVERSION_FACTOR
           , DIC_UNIT_OF_MEASURE_ID
           , FLP_QTY_REF2_WORK
           , -FLP_PRODUCT_QTY_UOP
           , -FLP_PT_REJECT_QTY_UOP
           , -FLP_CPT_REJECT_QTY_UOP
           , FAL_FAL_FACTORY_FLOOR_ID
           , PPS_TOOLS1_ID
           , PPS_TOOLS2_ID
           , PPS_TOOLS3_ID
           , PPS_TOOLS4_ID
           , PPS_TOOLS5_ID
           , PPS_TOOLS6_ID
           , PPS_TOOLS7_ID
           , PPS_TOOLS8_ID
           , PPS_TOOLS9_ID
           , PPS_TOOLS10_ID
           , PPS_TOOLS11_ID
           , PPS_TOOLS12_ID
           , PPS_TOOLS13_ID
           , PPS_TOOLS14_ID
           , PPS_TOOLS15_ID
           , 1   -- FLP_REVERSAL
           , aFalLotProgressId
           , DOC_POSITION_DETAIL_ID
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        from FAL_LOT_PROGRESS
       where FAL_LOT_PROGRESS_ID = aFalLotProgressId;

    if aFromCall = 1 then
      /* Supression des pesées liées au suivi */
      FAL_PRC_WEIGH.deleteWeighByLotProgress(inFalLotProgressID => aFalLotProgressId);
    elsif aFromCall = 2 then
      /* Extourne des pesées... (split de lot) */
      null;   --> TODO : A implémenter lors de la réalisation de la partie Eclatement de lots de fabrication
    end if;

    -- Imputation automatique en finance
    if upper(PCS.PC_CONFIG.GetConfig('FAL_AUTO_ACI_TIME_ENTRY') ) = 'TRUE' then
      begin
        select FAL_LOT_ID
          into vFAL_LOT_ID
          from FAL_LOT_PROGRESS
         where FAL_LOT_PROGRESS_ID = aFalLotProgressId;

        FAL_ACI_TIME_ENTRY_FCT.ProcessBatch(vFAL_LOT_ID, aErrorMsg);
      exception
        when no_data_found then
          null;
      end;
    end if;
  end CreateReversalProgressTrack;

  /**
   * procedure DeleteProcessTracking
   * Description
   *   Suppression (extournes) de suivis de fabrication
   * @version 2003
   * @author CLE
   * @lastUpdate
   * @public
   */
  procedure DeleteProcessTracking(
    aFalLotId         in FAL_LOT_PROGRESS.FAL_LOT_ID%type
  , aFalLotProgressId in FAL_LOT_PROGRESS.FAL_LOT_PROGRESS_ID%type
  , aContext             integer default 1   -- = FAL_COMPONENT_LINK_FUNCTIONS.ctxtProductionAdvance
  )
  is
    cursor crProgressTracking
    is
      select   flp.FAL_SCHEDULE_STEP_ID
             , nvl(flp.FLP_PRODUCT_QTY, 0) FLP_PRODUCT_QTY
             , nvl(flp.FLP_PT_REJECT_QTY, 0) FLP_PT_REJECT_QTY
             , nvl(flp.FLP_CPT_REJECT_QTY, 0) FLP_CPT_REJECT_QTY
             , nvl(flp.FLP_SUP_QTY, 0) FLP_SUP_QTY
             , flp.FLP_WORK_TIME
             , flp.FLP_ADJUSTING_TIME
             , flp.FLP_AMOUNT
             , flp.FLP_SEQ
             , lot.C_LOT_STATUS
             , lot.LOT_PT_REJECT_QTY
             , lot.LOT_CPT_REJECT_QTY
             , lot.FAL_ORDER_ID
             , flp.FAL_LOT_PROGRESS_ID
             , tal.C_OPERATION_TYPE
          from FAL_LOT_PROGRESS flp
             , FAL_LOT lot
             , FAL_TASK_LINK tal
         where flp.FAL_LOT_ID = aFalLotId
           and lot.FAL_LOT_ID = flp.FAL_LOT_ID
           and tal.FAL_SCHEDULE_STEP_ID = flp.FAL_SCHEDULE_STEP_ID
           and flp.FAL_LOT_PROGRESS_ID >= aFalLotProgressId
           and nvl(flp.FLP_REVERSAL, 0) = 0
      order by flp.FAL_LOT_PROGRESS_ID desc;

    nextMainOperationId FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type;
    ScsStepNumber       FAL_TASK_LINK.SCS_STEP_NUMBER%type;
  begin
    for tplProgressTracking in crProgressTracking loop
      -- Mise à jour de l'opération suivie
      UpdateMainOpeOnDeleteTrack(tplProgressTracking.FAL_SCHEDULE_STEP_ID
                               , tplProgressTracking.FLP_PRODUCT_QTY
                               , tplProgressTracking.FLP_PT_REJECT_QTY
                               , tplProgressTracking.FLP_CPT_REJECT_QTY
                               , tplProgressTracking.FLP_SUP_QTY
                               , tplProgressTracking.FLP_WORK_TIME
                               , tplProgressTracking.FLP_ADJUSTING_TIME
                               , tplProgressTracking.FLP_AMOUNT
                                );
      -- Mise à jour des opérations secondaires attachée à l'opération suivie (suivante si PPS_ASC_DESC = 2, précédente si = 1)
      -- bUpdateNextOperation = False, nextMainOperationId = Null
      UpdateOtherOpeOnDeleteTrack(aFalLotId             => aFalLotId
                                , aScsStepNumber        => tplProgressTracking.FLP_SEQ
                                , aFLP_PRODUCT_QTY      => tplProgressTracking.FLP_PRODUCT_QTY
                                , aFLP_PT_REJECT_QTY    => tplProgressTracking.FLP_PT_REJECT_QTY
                                , aFLP_CPT_REJECT_QTY   => tplProgressTracking.FLP_CPT_REJECT_QTY
                                , aFLP_SUP_QTY          => tplProgressTracking.FLP_SUP_QTY
                                , aContext              => aContext
                                 );

      if     (cPpsAscDsc = 1)
         and (    (tplProgressTracking.FLP_PT_REJECT_QTY > 0)
              or (tplProgressTracking.FLP_CPT_REJECT_QTY > 0)
              or (tplProgressTracking.FLP_SUP_QTY > 0) ) then
        -- Mise à jour des opérations secondaires suivantes (si du rebut ou de la qté sup a été fait et qu'elles ne dépendent pas de l'opération suivie - config PPS_ASC_DSC)
        -- bUpdateNextOperation = True, nextMainOperationId = Null
        UpdateOtherOpeOnDeleteTrack(aFalLotId              => aFalLotId
                                  , aScsStepNumber         => tplProgressTracking.FLP_SEQ
                                  , aFLP_PRODUCT_QTY       => tplProgressTracking.FLP_PRODUCT_QTY
                                  , aFLP_PT_REJECT_QTY     => tplProgressTracking.FLP_PT_REJECT_QTY
                                  , aFLP_CPT_REJECT_QTY    => tplProgressTracking.FLP_CPT_REJECT_QTY
                                  , aFLP_SUP_QTY           => tplProgressTracking.FLP_SUP_QTY
                                  , bUpdateNextOperation   => true
                                  , aContext               => aContext
                                   );
      end if;

      -- Recherche de l'opération principale suivante
      select max(FAL_SCHEDULE_STEP_ID)
           , max(SCS_STEP_NUMBER)
        into nextMainOperationId
           , ScsStepNumber
        from FAL_TASK_LINK
       where FAL_LOT_ID = aFalLotId
         and SCS_STEP_NUMBER = (select min(SCS_STEP_NUMBER)
                                  from FAL_TASK_LINK
                                 where FAL_LOT_ID = aFalLotId
                                   and SCS_STEP_NUMBER > tplProgressTracking.FLP_SEQ
                                   and C_OPERATION_TYPE = '1');

      if nextMainOperationId is not null then
        -- Mise à jour de l'opération principale suivante (première principale après l'opération suivie)
        -- bUpdateNextOperation = False, nextMainOperationId <> Null
        UpdateOtherOpeOnDeleteTrack(aFalLotId             => aFalLotId
                                  , aScsStepNumber        => tplProgressTracking.FLP_SEQ
                                  , aFLP_PRODUCT_QTY      => tplProgressTracking.FLP_PRODUCT_QTY
                                  , aFLP_PT_REJECT_QTY    => tplProgressTracking.FLP_PT_REJECT_QTY
                                  , aFLP_CPT_REJECT_QTY   => tplProgressTracking.FLP_CPT_REJECT_QTY
                                  , aFLP_SUP_QTY          => tplProgressTracking.FLP_SUP_QTY
                                  , nextMainOperationId   => nextMainOperationId
                                  , bDelTrackOnIndepend   => (tplProgressTracking.C_OPERATION_TYPE = '4')
                                  , aContext              => aContext
                                   );

        if    (tplProgressTracking.FLP_PT_REJECT_QTY > 0)
           or (tplProgressTracking.FLP_CPT_REJECT_QTY > 0)
           or (tplProgressTracking.FLP_SUP_QTY > 0) then
          -- Mise à jour rebut ou qté sup de toutes les opérations non indépendantes suivantes (qui suivent la première principale après l'opération suivie)
          -- bUpdateNextOperation = True, nextMainOperationId <> Null
          UpdateOtherOpeOnDeleteTrack(aFalLotId              => aFalLotId
                                    , aScsStepNumber         => ScsStepNumber
                                    , aFLP_PRODUCT_QTY       => tplProgressTracking.FLP_PRODUCT_QTY
                                    , aFLP_PT_REJECT_QTY     => tplProgressTracking.FLP_PT_REJECT_QTY
                                    , aFLP_CPT_REJECT_QTY    => tplProgressTracking.FLP_CPT_REJECT_QTY
                                    , aFLP_SUP_QTY           => tplProgressTracking.FLP_SUP_QTY
                                    , bUpdateNextOperation   => true
                                    , nextMainOperationId    => nextMainOperationId
                                    , aContext               => aContext
                                     );
        end if;
      end if;

      /* Mise à jour de la quantité disponible */
      FAL_PRC_TASK_LINK.UpdateAvailQtyOp(aFalLotId);

      if     (tplProgressTracking.C_LOT_STATUS = '2')
         and (   aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchSplitting
              or (    (     (tplProgressTracking.FLP_PT_REJECT_QTY + tplProgressTracking.FLP_CPT_REJECT_QTY > 0)
                       and (tplProgressTracking.LOT_PT_REJECT_QTY - tplProgressTracking.FLP_PT_REJECT_QTY >= 0)
                       and (tplProgressTracking.LOT_CPT_REJECT_QTY - tplProgressTracking.FLP_CPT_REJECT_QTY >= 0)
                      )
                  or (tplProgressTracking.FLP_SUP_QTY > 0)
                 )
             ) then
        -- Mise à jour des composants
        UpdateBatchComponents(aFalLotId             => aFalLotId
                            , aScsStepNumber        => tplProgressTracking.FLP_SEQ
                            , aFLP_PT_REJECT_QTY    => tplProgressTracking.FLP_PT_REJECT_QTY
                            , aFLP_CPT_REJECT_QTY   => tplProgressTracking.FLP_CPT_REJECT_QTY
                            , aFLP_SUP_QTY          => tplProgressTracking.FLP_SUP_QTY
                            , deleteCoef            => -1
                             );
        -- Mise à jour du lot
        UpdateBatch(aFAL_LOT_ID           => aFalLotId
                  , aFLP_SUP_QTY          => tplProgressTracking.FLP_SUP_QTY
                  , aFLP_PT_REJECT_QTY    => tplProgressTracking.FLP_PT_REJECT_QTY
                  , aFLP_CPT_REJECT_QTY   => tplProgressTracking.FLP_CPT_REJECT_QTY
                  , deleteCoef            => -1
                   );
        -- Mise à jour de l'ordre
        FAL_ORDER_FUNCTIONS.UpdateOrder(aFAL_ORDER_ID => tplProgressTracking.FAL_ORDER_ID);
      end if;

      if tplProgressTracking.C_LOT_STATUS = '2' then
        FAL_NETWORK.MiseAJourReseaux(aFalLotId, FAL_NETWORK.ncSuiviAvancementSuppression, '');
      end if;

      -- Marquer le suivi comme extourné
      update FAL_LOT_PROGRESS
         set FLP_REVERSAL = 1
       where FAL_LOT_PROGRESS_ID = tplProgressTracking.FAL_LOT_PROGRESS_ID;

      -- Supprimer les détails de suivi liés au suivi extourné
      -- (trigger sur le delete pour remise à jour des quantités rebut des détails lot liés)
      delete from FAL_LOT_PROGRESS_DETAIL
            where FAL_LOT_PROGRESS_ID = tplProgressTracking.FAL_LOT_PROGRESS_ID;

      -- Création du suivi de type extourne
      CreateReversalProgressTrack(tplProgressTracking.FAL_LOT_PROGRESS_ID, case aContext
                                    when FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchSplitting then 2
                                    else 1
                                  end);
    end loop;

    -- Mise à null de la date début réelle pour les opérations n'ayant plus de suivi de fabrication
    update FAL_TASK_LINK TAL
       set TAL_BEGIN_REAL_DATE = null
     where FAL_LOT_ID = AFALLOTID
       and not exists(select *
                        from FAL_LOT_PROGRESS
                       where FAL_SCHEDULE_STEP_ID = TAL.FAL_SCHEDULE_STEP_ID
                         and FLP_REVERSAL = 0);
  end DeleteProcessTracking;

  /**
   * procedure GenTrackingForAssemblyBatch
   * Description
   *   Génération des avancements pour les lots d'assemblage
   * @version 2003
   * @author ECA 24.07.2008
   * @lastUpdate KLA 03.10.2013
   * @public
   *
   * @param   aFAL_LOT_ID : lot d'assemblage
   */
  procedure GenTrackingForAssemblyBatch(aFAL_LOT_ID number)
  is
    --  Sélection des opération de l'of
    cursor crFAL_TASK_LINK
    is
      select TAL.FAL_SCHEDULE_STEP_ID
           , LOT.LOT_TOTAL_QTY
           , TAL.TAL_ACHIEVED_AD_TSK
           , TAL.TAL_ACHIEVED_TSK
           , TAL.TAL_ACHIEVED_AMT
           , TAL.FAL_FACTORY_FLOOR_ID
           , TAL.FAL_FAL_FACTORY_FLOOR_ID
           , TAL.SCS_WORK_RATE
           , TAL.SCS_ADJUSTING_RATE
           , TAL.PPS_TOOLS1_ID
           , TAL.PPS_TOOLS2_ID
           , TAL.PPS_TOOLS3_ID
           , TAL.PPS_TOOLS4_ID
           , TAL.PPS_TOOLS5_ID
           , TAL.PPS_TOOLS6_ID
           , TAL.PPS_TOOLS7_ID
           , TAL.PPS_TOOLS8_ID
           , TAL.PPS_TOOLS9_ID
           , TAL.PPS_TOOLS10_ID
           , TAL.PPS_TOOLS11_ID
           , TAL.PPS_TOOLS12_ID
           , TAL.PPS_TOOLS13_ID
           , TAL.PPS_TOOLS14_ID
           , TAL.PPS_TOOLS15_ID
           , TAL.PPS_OPERATION_PROCEDURE_ID
           , TAL.PPS_PPS_OPERATION_PROCEDURE_ID
           , TAL.SCS_CONVERSION_FACTOR
        from FAL_TASK_LINK TAL
           , FAL_LOT LOT
       where LOT.FAL_LOT_ID = aFAL_LOT_ID
         and LOT.FAL_LOT_ID = TAL.FAL_LOT_ID;

    aErrorMsg varchar2(4000);
  begin
    -- Parcours des opérations et génération des avancements
    for tplFAL_TASK_LINK in crFAL_TASK_LINK loop
      AddProcessTracking(aFalScheduleStepId            => tplFAL_TASK_LINK.FAL_SCHEDULE_STEP_ID
                       , aFlpDate1                     => sysdate
                       , aFlpProductQty                => tplFAL_TASK_LINK.LOT_TOTAL_QTY
                       , aFlpAdjustingTime             => tplFAL_TASK_LINK.TAL_ACHIEVED_AD_TSK
                       , aFlpWorkTime                  => tplFAL_TASK_LINK.TAL_ACHIEVED_TSK
                       , aFlpAmount                    => tplFAL_TASK_LINK.TAL_ACHIEVED_AMT
                       , aFalFactoryFloorId            => tplFAL_TASK_LINK.FAL_FACTORY_FLOOR_ID
                       , aFalFalFactoryFloorId         => tplFAL_TASK_LINK.FAL_FAL_FACTORY_FLOOR_ID
                       , aFlpRate                      => tplFAL_TASK_LINK.SCS_WORK_RATE
                       , aFlpAdjustingRate             => tplFAL_TASK_LINK.SCS_ADJUSTING_RATE
                       , aPpsTools1Id                  => tplFAL_TASK_LINK.PPS_TOOLS1_ID
                       , aPpsTools2Id                  => tplFAL_TASK_LINK.PPS_TOOLS2_ID
                       , aPpsTools3Id                  => tplFAL_TASK_LINK.PPS_TOOLS3_ID
                       , aPpsTools4Id                  => tplFAL_TASK_LINK.PPS_TOOLS4_ID
                       , aPpsTools5Id                  => tplFAL_TASK_LINK.PPS_TOOLS5_ID
                       , aPpsTools6Id                  => tplFAL_TASK_LINK.PPS_TOOLS6_ID
                       , aPpsTools7Id                  => tplFAL_TASK_LINK.PPS_TOOLS7_ID
                       , aPpsTools8Id                  => tplFAL_TASK_LINK.PPS_TOOLS8_ID
                       , aPpsTools9Id                  => tplFAL_TASK_LINK.PPS_TOOLS9_ID
                       , aPpsTools10Id                 => tplFAL_TASK_LINK.PPS_TOOLS10_ID
                       , aPpsTools11Id                 => tplFAL_TASK_LINK.PPS_TOOLS11_ID
                       , aPpsTools12Id                 => tplFAL_TASK_LINK.PPS_TOOLS12_ID
                       , aPpsTools13Id                 => tplFAL_TASK_LINK.PPS_TOOLS13_ID
                       , aPpsTools14Id                 => tplFAL_TASK_LINK.PPS_TOOLS14_ID
                       , aPpsTools15Id                 => tplFAL_TASK_LINK.PPS_TOOLS15_ID
                       , aPpsOperationProcedureId      => tplFAL_TASK_LINK.PPS_OPERATION_PROCEDURE_ID
                       , aPpsPpsOperationProcedureId   => tplFAL_TASK_LINK.PPS_PPS_OPERATION_PROCEDURE_ID
                       , aFlpProductQtyUop             => tplFAL_TASK_LINK.LOT_TOTAL_QTY * tplFAL_TASK_LINK.SCS_CONVERSION_FACTOR
                       , aSessionId                    => DBMS_SESSION.unique_session_id
                       , aiShutdownExceptions          => 0
                       , aErrorMsg                     => aErrorMsg
                       , aUpdateBatch                  => 0
                        );
    end loop;
  end GenTrackingForAssemblyBatch;
end FAL_SUIVI_OPERATION;
