--------------------------------------------------------
--  DDL for Package Body FAL_GANTT_UPDATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_GANTT_UPDATE" 
is
  -- Configurations
  cFalOrtDefaultService constant varchar(30) := PCS.PC_CONFIG.GetConfig('FAL_ORT_DEFAULT_SERVICE');
  cDefaultStockID       constant number      := FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_NETWORK');
  cDefaultLocationID    constant number      := FAL_TOOLS.GetConfig_LocationID('PPS_DefltLOCATION_NETWORK', cDefaultStockID);

    /**
  * procedure : UpdateSSTADELAY
  * Description : Modification des délais des commandes d'achat sous-traitance liés of of de sous-traitance
  *
  * @created ECA
  * @lastUpdate SMA 14.02.2013
  * @public
  *
  * @param   iSessionId : Session oracle
  */
  procedure UpdateSSTADelay(iSessionId varchar2)
  is
  begin
    --Recherche de la position et infos correspondantes
    for tplGetPositionDetail in (select PDE.DOC_POSITION_DETAIL_ID
                                      , GAP.C_GAUGE_SHOW_DELAY
                                      , GAP.GAP_POS_DELAY
                                      , DOC.PAC_THIRD_CDA_ID
                                      , POS.GCO_GOOD_ID
                                      , POS.STM_STOCK_ID
                                      , POS.STM_STM_STOCK_ID
                                      , GAU.C_ADMIN_DOMAIN
                                      , GAU.C_GAUGE_TYPE
                                      , GAP.GAP_TRANSFERT_PROPRIETOR
                                      , POS.GCO_COMPL_DATA_ID
                                      , PDE.PDE_BASIS_QUANTITY
                                      , OPE.FGO_PLAN_START_DATE
                                      , LOT.FAL_LOT_ID
                                      , TAL.PAC_SUPPLIER_PARTNER_ID
                                      , TAL.FAL_SCHEDULE_STEP_ID
                                   from FAL_LOT LOT
                                      , FAL_TASK_LINK TAL
                                      , DOC_POSITION_DETAIL PDE
                                      , DOC_POSITION POS
                                      , DOC_DOCUMENT DOC
                                      , DOC_GAUGE_POSITION GAP
                                      , DOC_GAUGE GAU
                                      , FAL_GAN_TASK FGT
                                      , FAL_GAN_OPERATION OPE
                                      , table(DOC_LIB_SUBCONTRACTP.GetSUPOGaugeId(TAL.PAC_SUPPLIER_PARTNER_ID) ) DocGauge
                                  where LOT.FAL_LOT_ID = FGT.FAL_LOT_ID
                                    and FGT.FAL_GAN_SESSION_ID = iSessionId
                                    and FGT.FAL_GAN_TASK_ID = OPE.FAL_GAN_TASK_ID
                                    and LOT.FAL_LOT_ID = POS.FAL_LOT_ID
                                    and LOT.FAL_LOT_ID = TAL.FAL_LOT_ID
                                    and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
                                    and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                                    and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
                                    and DOC.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                                    and LOT.C_FAB_TYPE = '4'
                                    and PDE.DOC_GAUGE_ID = DocGauge.column_value
                                    and TAL.FAL_SCHEDULE_STEP_ID in(
                                          select FGO2.FAL_SCHEDULE_STEP_ID
                                            from FAL_GAN_OPERATION FGO2
                                           where FGO2.FAL_GAN_SESSION_ID = iSessionId
                                             and not exists(select FGE.FAL_GAN_TASK_ID
                                                              from FAL_GAN_EXCEPTION FGE
                                                             where FGE.FAL_GAN_SESSION_ID = iSessionId
                                                               and FGE.FAL_GAN_TASK_ID = FGO2.FAL_GAN_TASK_ID) ) ) loop
      FAL_PRC_SUBCONTRACTP.UpdateSubcontractDelay(tplGetPositionDetail.FGO_PLAN_START_DATE
                                                , tplGetPositionDetail.C_GAUGE_SHOW_DELAY
                                                , tplGetPositionDetail.GAP_POS_DELAY
                                                , tplGetPositionDetail.PAC_THIRD_CDA_ID
                                                , tplGetPositionDetail.GCO_GOOD_ID
                                                , tplGetPositionDetail.STM_STOCK_ID
                                                , tplGetPositionDetail.STM_STM_STOCK_ID
                                                , tplGetPositionDetail.C_ADMIN_DOMAIN
                                                , tplGetPositionDetail.C_GAUGE_TYPE
                                                , tplGetPositionDetail.GAP_TRANSFERT_PROPRIETOR
                                                , tplGetPositionDetail.GCO_COMPL_DATA_ID
                                                , tplGetPositionDetail.PDE_BASIS_QUANTITY
                                                , tplGetPositionDetail.DOC_POSITION_DETAIL_ID
                                                , tplGetPositionDetail.PAC_SUPPLIER_PARTNER_ID
                                                , tplGetPositionDetail.FAL_SCHEDULE_STEP_ID
                                                , tplGetPositionDetail.FAL_LOT_ID
                                                 );
    end loop;
  end UpdateSSTADelay;

  /**
  * procedure : CheckModifiedBatches
  * Description : Ajout en exception des OF modifiées
  *               Valeurs de C_EXCEPTION_CODE :
  *               - cExcpBatchDeleted         = OF a été supprimé
  *               - cExcpBatchBalanced        = OF soldé
  *               - cExcpBatchQtyModified     = Quantité d'OF modifié
  *               - cExcpProcessPlanModified  = La gamme a été modifiée
  *                 (sum des FAL_SCHEDULE_STEP_ID différents entre FAL_TASK_LINK et FAL_GAN_OPERATION pour le même OF)
  *               - cExcpProcessTrackModified = Du suivi a été effectué ou supprimé sur une des opérations
  *                 (des suivis ont été créés ou supprimés (extournés) avec une date de création suppérieure à A_DATECRE de la session)
  * @created CLG
  * @lastUpdate
  * @public
  *
  * @param   iSessionId   session oracle
  */
  procedure CheckModifiedBatches(iSessionId in number)
  is
  begin
    insert into FAL_GAN_EXCEPTION
                (FAL_GAN_EXCEPTION_ID
               , FGE_MESSAGE
               , C_EXCEPTION_CODE
               , FAL_GAN_TASK_ID
               , FAL_GAN_SESSION_ID
                )
      select GetNewId
           , FGT.FGT_REFERENCE
           , case
               when nvl(LOT.FAL_LOT_ID, 0) = 0 then cExcpBatchDeleted
               when LOT.C_LOT_STATUS not in('1', '2') then cExcpBatchBalanced
               when FGT.FGT_LOT_TOTAL_QTY <> LOT.LOT_TOTAL_QTY then cExcpBatchQtyModified
               when (select sum(FAL_SCHEDULE_STEP_ID)
                       from FAL_TASK_LINK TAL
                      where TAL.FAL_LOT_ID = LOT.FAL_LOT_ID
                        and TAL.TAL_DUE_QTY > 0) <> (select sum(FAL_SCHEDULE_STEP_ID)
                                                       from FAL_GAN_OPERATION OPE
                                                      where OPE.FAL_GAN_TASK_ID = FGT.FAL_GAN_TASK_ID) then cExcpProcessPlanModified
               else cExcpProcessTrackModified
             end C_EXCEPTION_CODE
           , FGT.FAL_GAN_TASK_ID
           , iSessionId
        from FAL_GAN_TASK FGT
           , FAL_LOT LOT
       where FGT.FAL_LOT_ID = LOT.FAL_LOT_ID(+)
         and FGT.FAL_GAN_SESSION_ID = iSessionId
         and FGT.FAL_LOT_ID is not null
         and not exists(select FAL_GAN_TASK_ID
                          from FAL_GAN_EXCEPTION
                         where FAL_GAN_TASK_ID = FGT.FAL_GAN_TASK_ID)
         and (   LOT.FAL_LOT_ID is null
              or FGT.FGT_LOT_TOTAL_QTY <> LOT.LOT_TOTAL_QTY
              or LOT.C_LOT_STATUS not in('1', '2')
              or (select sum(FAL_SCHEDULE_STEP_ID)
                    from FAL_TASK_LINK TAL
                   where TAL.FAL_LOT_ID = LOT.FAL_LOT_ID
                     and TAL.TAL_DUE_QTY > 0) <> (select sum(FAL_SCHEDULE_STEP_ID)
                                                    from FAL_GAN_OPERATION OPE
                                                   where OPE.FAL_GAN_TASK_ID = FGT.FAL_GAN_TASK_ID)
              or exists(select FAL_LOT_PROGRESS_ID
                          from FAL_LOT_PROGRESS
                         where FAL_SCHEDULE_STEP_ID in(select FAL_SCHEDULE_STEP_ID
                                                         from FAL_GAN_OPERATION OPE
                                                        where OPE.FAL_GAN_TASK_ID = FGT.FAL_GAN_TASK_ID)
                           and A_DATECRE > (select A_DATECRE
                                              from FAL_GAN_SESSION
                                             where FAL_GAN_SESSION_ID = iSessionId) )
             );
  end CheckModifiedBatches;

  /**
  * procedure : UpdateResourceOfOperations
  * Description : Mise à jour des opérations qui ont changé d'atelier ou de sous-traitant
  *               (restriction sur opérations d'OF qui ne sont ni supprimés ni soldés)
  *    - Mise à jour du code "Interne", "Externe"
  *    - Mise à null de l'opérateur si c'est une opération externe
  *    - Ajout du service par défaut (défini par config) si opération externe qui n'en a pas
  *
  * @created CLG
  * @lastUpdate
  * @public
  *
  * @param   iSessionId        Session oracle
  * @param   dFixPlanningDate  Date jusqu'à laquelle le planning est figé
  */
  procedure UpdateResourceOfOperations(iSessionId in number, dFixPlanningDate in date)
  is
  begin
    if cFalOrtDefaultService is null then
      Raise_Application_Error(-20000, 'You have to define the configuration FAL_ORT_DEFAULT_SERVICE');
    end if;

    for tplOper in (select TAL.FAL_SCHEDULE_STEP_ID
                         , case
                             when OPE.FGO_PLAN_START_DATE < dFixPlanningDate then RES.FAL_FACTORY_FLOOR_ID
                             else TAL.FAL_FACTORY_FLOOR_ID
                           end FAL_FACTORY_FLOOR_ID
                         , RES.PAC_SUPPLIER_PARTNER_ID
                         , decode(RES.FAL_FACTORY_FLOOR_ID, null, '2', '1') C_TASK_TYPE
                         , decode(RES.FAL_FACTORY_FLOOR_ID, null, null, TAL.FAL_FAL_FACTORY_FLOOR_ID) FAL_FAL_FACTORY_FLOOR_ID
                         , decode(RES.FAL_FACTORY_FLOOR_ID, null, nvl(TAL.GCO_GCO_GOOD_ID, SERVICE.GCO_GOOD_ID), null) GCO_GCO_GOOD_ID
                      from FAL_GAN_OPERATION OPE
                         , FAL_GAN_TIMING_RESOURCE RES
                         , FAL_TASK_LINK TAL
                         , (select GCO_GOOD_ID
                              from GCO_GOOD
                             where GOO_MAJOR_REFERENCE = cFalOrtDefaultService) SERVICE
                     where OPE.FAL_SCHEDULE_STEP_ID = TAL.FAL_SCHEDULE_STEP_ID
                       and OPE.FAL_GAN_RESULT_TIMING_RES_ID = RES.FAL_GAN_TIMING_RESOURCE_ID
                       and OPE.FAL_GAN_SESSION_ID = iSessionId
                       and TAL.FAL_SCHEDULE_STEP_ID in(
                             select FAL_SCHEDULE_STEP_ID
                               from FAL_GAN_OPERATION FGO
                              where FAL_GAN_SESSION_ID = iSessionId
                                and nvl(FGO.FAL_GAN_RESULT_TIMING_RES_ID, 0) <> nvl(FGO.FAL_GAN_TIMING_RESOURCE_ID, 0)
                                and not exists(
                                      select FAL_GAN_TASK_ID
                                        from FAL_GAN_EXCEPTION
                                       where FAL_GAN_TASK_ID = FGO.FAL_GAN_TASK_ID
                                         and C_EXCEPTION_CODE in(cExcpBatchDeleted, cExcpBatchBalanced, cExcpErrorPlanifInGantt) ) ) ) loop
      update FAL_TASK_LINK TAL
         set FAL_FACTORY_FLOOR_ID = tplOper.FAL_FACTORY_FLOOR_ID
           , PAC_SUPPLIER_PARTNER_ID = tplOper.PAC_SUPPLIER_PARTNER_ID
           , C_TASK_TYPE = tplOper.C_TASK_TYPE
           , FAL_FAL_FACTORY_FLOOR_ID = tplOper.FAL_FAL_FACTORY_FLOOR_ID
           , GCO_GCO_GOOD_ID = tplOper.GCO_GCO_GOOD_ID
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_SCHEDULE_STEP_ID = tplOper.FAL_SCHEDULE_STEP_ID;
    end loop;
  end UpdateResourceOfOperations;

  /**
  * procedure : DeleteObsoleteLUM
  * Description : Suppression des LMU dans les cas suivants :
  *    - Changement d'îlot
  *    - Atelier à capacité infini
  *    - Sous-traitant
  *
  * @created CLG
  * @lastUpdate
  * @public
  *
  * @param   iSessionId   session oracle
  */
  procedure DeleteObsoleteLUM(iSessionId in number)
  is
  begin
    delete from FAL_TASK_LINK_USE
          where FAL_SCHEDULE_STEP_ID in(
                  select OPE.FAL_SCHEDULE_STEP_ID
                    from FAL_GAN_OPERATION OPE
                       , FAL_GAN_TIMING_RESOURCE RES
                       , FAL_FACTORY_FLOOR FAC
                   where OPE.FAL_GAN_RESULT_TIMING_RES_ID <> OPE.FAL_GAN_TIMING_RESOURCE_ID
                     and OPE.FAL_GAN_RESULT_TIMING_RES_ID = RES.FAL_GAN_TIMING_RESOURCE_ID
                     and RES.FAL_FACTORY_FLOOR_ID = FAC.FAL_FACTORY_FLOOR_ID(+)
                     and OPE.FAL_GAN_SESSION_ID = iSessionId
                     and (   nvl( (FAC.FAC_INFINITE_FLOOR), 1) = 0
                          or nvl( (select FAL_FACTORY_FLOOR_ID
                                     from FAL_FACTORY_FLOOR
                                    where FAL_FACTORY_FLOOR_ID = FAC.FAL_FAL_FACTORY_FLOOR_ID), FAC.FAL_FACTORY_FLOOR_ID) <>
                               nvl( (select FAL_FACTORY_FLOOR_ID
                                       from FAL_FACTORY_FLOOR
                                      where FAL_FACTORY_FLOOR_ID =
                                                              (select FAL_FAL_FACTORY_FLOOR_ID
                                                                 from FAL_FACTORY_FLOOR
                                                                where FAL_FACTORY_FLOOR_ID = (select FAL_FACTORY_FLOOR_ID
                                                                                                from FAL_GAN_TIMING_RESOURCE
                                                                                               where FAL_GAN_TIMING_RESOURCE_ID = OPE.FAL_GAN_TIMING_RESOURCE_ID) ) )
                                 , (select FAL_FACTORY_FLOOR_ID
                                      from FAL_GAN_TIMING_RESOURCE
                                     where FAL_GAN_TIMING_RESOURCE_ID = OPE.FAL_GAN_TIMING_RESOURCE_ID)
                                  )
                         )
                     and not exists(
                             select FAL_GAN_TASK_ID
                               from FAL_GAN_EXCEPTION
                              where FAL_GAN_TASK_ID = OPE.FAL_GAN_TASK_ID
                                and C_EXCEPTION_CODE in(cExcpBatchDeleted, cExcpBatchBalanced, cExcpErrorPlanifInGantt) ) );
  end DeleteObsoleteLUM;

  /**
  * procedure : UpdatePlanifOperations
  * Description : Mise à jour de la planification des opérations
  *               (restriction sur opérations d'OF qui ne sont pas dans la table d'exception)
  *    - Mise à jour date début
  *    - Mise à jour date fin
  *    - Recalcul du champ planification si atelier à capacité infini ou sous-traitant
  *    - Durée non proportionnelle pour atelier à capacité infini ou sous-traitant
  *
  * @created CLG
  * @lastUpdate
  * @public
  *
  * @param   iSessionId   session oracle
  */
  procedure UpdatePlanifOperations(iSessionId in number)
  is
  begin
    update FAL_TASK_LINK TAL
       set (TAL_BEGIN_PLAN_DATE, TAL_END_PLAN_DATE, SCS_PLAN_RATE, SCS_PLAN_PROP, A_DATEMOD, A_IDMOD) =
             (select OPE.FGO_PLAN_START_DATE
                   , OPE.FGO_PLAN_END_DATE
                   , decode(nvl( (FAC.FAC_INFINITE_FLOOR), 1)
                          , 1, FAL_PLANIF.GetDurationInDay(RES.FAL_FACTORY_FLOOR_ID, RES.PAC_SUPPLIER_PARTNER_ID, OPE.FGO_PLAN_START_DATE
                                                         , OPE.FGO_PLAN_END_DATE)
                          , TAL.SCS_PLAN_RATE
                           ) SCS_PLAN_RATE
                   , decode(nvl( (FAC.FAC_INFINITE_FLOOR), 1), 1, 0, TAL.SCS_PLAN_PROP) SCS_PLAN_PROP
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                from FAL_GAN_OPERATION OPE
                   , FAL_GAN_TIMING_RESOURCE RES
                   , FAL_FACTORY_FLOOR FAC
               where OPE.FAL_SCHEDULE_STEP_ID = TAL.FAL_SCHEDULE_STEP_ID
                 and OPE.FAL_GAN_RESULT_TIMING_RES_ID = RES.FAL_GAN_TIMING_RESOURCE_ID
                 and RES.FAL_FACTORY_FLOOR_ID = FAC.FAL_FACTORY_FLOOR_ID(+)
                 and OPE.FAL_GAN_SESSION_ID = iSessionId)
     where FAL_SCHEDULE_STEP_ID in(
                           select FAL_SCHEDULE_STEP_ID
                             from FAL_GAN_OPERATION FGO
                            where FAL_GAN_SESSION_ID = iSessionId
                              and not exists(select FAL_GAN_TASK_ID
                                               from FAL_GAN_EXCEPTION
                                              where FAL_GAN_SESSION_ID = iSessionId
                                                and FAL_GAN_TASK_ID = FGO.FAL_GAN_TASK_ID) );

    -- Pour les opérations externes, la durée de la tâche est la même que celle de la planification
    update FAL_TASK_LINK
       set TAL_TASK_MANUF_TIME = SCS_PLAN_RATE
     where PAC_SUPPLIER_PARTNER_ID is not null
       and FAL_SCHEDULE_STEP_ID in(
                           select FAL_SCHEDULE_STEP_ID
                             from FAL_GAN_OPERATION FGO
                            where FAL_GAN_SESSION_ID = iSessionId
                              and not exists(select FAL_GAN_TASK_ID
                                               from FAL_GAN_EXCEPTION
                                              where FAL_GAN_SESSION_ID = iSessionId
                                                and FAL_GAN_TASK_ID = FGO.FAL_GAN_TASK_ID) );
  end UpdatePlanifOperations;

   /**
  * procedure : UpdatePlanifOperations
  * Description : Mise à jour des documents liés aux opérations externes
  *               (pas de mise à jour pour les documents autre que "A confirmer")
  * @created CLG
  * @lastUpdate  age 08.07.2013
  * @public
  *
  * @param   iSessionId        Session oracle
  */
  procedure UpdateSubcontractOperations(iSessionId in number)
  is
  begin
    for tplDetail in (select PDE.DOC_POSITION_DETAIL_ID
                           , FGO.FGO_PLAN_END_DATE
                           , GAP.C_GAUGE_SHOW_DELAY
                           , GAP.GAP_POS_DELAY
                           , DOC.PAC_THIRD_CDA_ID
                           , POS.GCO_GOOD_ID
                           , POS.STM_STOCK_ID
                           , POS.STM_STM_STOCK_ID
                           , GAU.C_ADMIN_DOMAIN
                           , GAU.C_GAUGE_TYPE
                           , GAP.GAP_TRANSFERT_PROPRIETOR
                           , POS.GCO_COMPL_DATA_ID
                           , PDE.PDE_BASIS_QUANTITY
                           , PDE.FAL_SCHEDULE_STEP_ID
                        from DOC_POSITION_DETAIL PDE
                           , DOC_POSITION POS
                           , DOC_DOCUMENT DOC
                           , DOC_GAUGE_POSITION GAP
                           , DOC_GAUGE GAU
                           , FAL_GAN_OPERATION FGO
                       where POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
                         and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                         and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
                         and DOC.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                         and POS.FAL_SCHEDULE_STEP_ID = FGO.FAL_SCHEDULE_STEP_ID
                         and DOC_LIB_SUBCONTRACTO.IsSUOOGauge(DOC.DOC_GAUGE_ID) = 1
                         and DOC.C_DOCUMENT_STATUS = '01'
                         and FGO.FAL_GAN_SESSION_ID = iSessionId
                         and exists(
                               select FAL_SCHEDULE_STEP_ID
                                 from FAL_GAN_OPERATION OPE
                                where FAL_GAN_SESSION_ID = iSessionId
                                  and OPE.FAL_SCHEDULE_STEP_ID = FGO.FAL_SCHEDULE_STEP_ID
                                  and not exists(select FAL_GAN_TASK_ID
                                                   from FAL_GAN_EXCEPTION
                                                  where FAL_GAN_SESSION_ID = iSessionId
                                                    and FAL_GAN_TASK_ID = OPE.FAL_GAN_TASK_ID) ) ) loop
      FAL_I_PRC_SUBCONTRACTO.UpdateSubcontractDelay(iDocPositionDetailId      => tplDetail.DOC_POSITION_DETAIL_ID
                                                  , iNewDelay                 => tplDetail.FGO_PLAN_END_DATE
                                                  , iUpdatedDelay             => 'FINAL'
                                                  , iCGaugeShowDelay          => tplDetail.C_GAUGE_SHOW_DELAY
                                                  , iGapPosDelay              => tplDetail.GAP_POS_DELAY
                                                  , iPacThirdCdaId            => tplDetail.PAC_THIRD_CDA_ID
                                                  , iGcoGoodId                => tplDetail.GCO_GOOD_ID
                                                  , iStmStockId               => tplDetail.STM_STOCK_ID
                                                  , iStmStmStockId            => tplDetail.STM_STM_STOCK_ID
                                                  , iCAdminDomain             => tplDetail.C_ADMIN_DOMAIN
                                                  , iCGaugeType               => tplDetail.C_GAUGE_TYPE
                                                  , iGapTransfertProprietor   => tplDetail.GAP_TRANSFERT_PROPRIETOR
                                                  , iGcoComplDataId           => tplDetail.GCO_COMPL_DATA_ID
                                                  , iPdeBasisQuantity         => tplDetail.PDE_BASIS_QUANTITY
                                                  , iScheduleStepId           => tplDetail.FAL_SCHEDULE_STEP_ID
                                                   );
    end loop;
  end UpdateSubcontractOperations;

  /**
  * procedure : UpdateOperations
  * Description : Mise à jour des opérations
  *
  * @created CLG
  * @lastUpdate
  * @public
  *
  * @param   iSessionId        session oracle
  * @param   dFixPlanningDate  Date jusqu'à laquelle le planning est figé
  */
  procedure UpdateOperations(iSessionId in number, dFixPlanningDate in date)
  is
  begin
    -- Mise à jour des ressources
    UpdateResourceOfOperations(iSessionId, dFixPlanningDate);
    -- Suppression des machines obsolètes
    DeleteObsoleteLUM(iSessionId);
    -- Mise à jour de la planification sur les opérations
    UpdatePlanifOperations(iSessionId);
    -- Mise à jour des documents liés aux opérations externes
    UpdateSubcontractOperations(iSessionId);
  end UpdateOperations;

  /**
  * procedure : PlanifBatchesInException
  * Description : Planification des OF en exception (OF dont la quantité, la gamme ou le suivi a été modifié)
  *               - Planification arrière pour les OF qui sont prédécesseur et jamais successeur
  *               - Planification avant pour tous les autres
  *
  * @created CLG
  * @lastUpdate
  * @public
  *
  * @param   iSessionId   session oracle
  */
  procedure PlanifBatchesInException(iSessionId in number)
  is
    cursor crFalGanBatchInExcept
    is
      select TSK.FAL_LOT_ID
           , decode(C_EXCEPTION_CODE
                  , cExcpErrorPlanifInGantt, (select FGO_PLAN_START_DATE
                                                from FAL_GAN_OPERATION
                                               where FAL_GAN_TASK_ID = TSK.FAL_GAN_TASK_ID
                                                 and FGO_STEP_NUMBER = (select min(FGO_STEP_NUMBER)
                                                                          from FAL_GAN_OPERATION
                                                                         where FAL_GAN_TASK_ID = TSK.FAL_GAN_TASK_ID) )
                  , FGT_RESULT_START_DATE
                   ) FGT_RESULT_START_DATE
           , FGT_RESULT_END_DATE
           , (select count(*)
                from FAL_GAN_LINK
               where FAL_GAN_PRED_TASK_ID = EXCP.FAL_GAN_TASK_ID) CNT_PRED_LNK
           , (select count(*)
                from FAL_GAN_LINK
               where FAL_GAN_SUCC_TASK_ID = EXCP.FAL_GAN_TASK_ID) CNT_SUCC_LNK
           , C_EXCEPTION_CODE
        from FAL_GAN_EXCEPTION EXCP
           , FAL_GAN_TASK TSK
       where EXCP.FAL_GAN_TASK_ID = TSK.FAL_GAN_TASK_ID
         and TSK.FAL_LOT_ID is not null
         and EXCP.FAL_GAN_SESSION_ID = iSessionId
         and C_EXCEPTION_CODE not in(cExcpBatchDeleted, cExcpBatchBalanced);
  begin
    for tplFalGanBatchInExcept in crFalGanBatchInExcept loop
      if     (tplFalGanBatchInExcept.CNT_PRED_LNK > 0)
         and (tplFalGanBatchInExcept.CNT_SUCC_LNK = 0)
         and (tplFalGanBatchInExcept.C_EXCEPTION_CODE <> cExcpErrorPlanifInGantt) then
        -- Si l'OF est prédécesseur et jamais successeur d'un autre OF, planification date fin
        FAL_PLANIF.PLANIFICATION_LOT(PrmFAL_LOT_ID              => tplFalGanBatchInExcept.FAL_LOT_ID
                                   , DatePlanification          => tplFalGanBatchInExcept.FGT_RESULT_END_DATE
                                   , SelonDateDebut             => FAL_PLANIF.ctDateFin
                                   , MAJReqLiensComposantsLot   => FAL_PLANIF.ctSansMAJLienCompoLot
                                   , MAJ_Reseaux_Requise        => FAL_PLANIF.ctSansMAJReseau
                                    );
      else
        -- Dans tous les autres cas, planification date début
        FAL_PLANIF.PLANIFICATION_LOT(PrmFAL_LOT_ID              => tplFalGanBatchInExcept.FAL_LOT_ID
                                   , DatePlanification          => tplFalGanBatchInExcept.FGT_RESULT_START_DATE
                                   , SelonDateDebut             => FAL_PLANIF.ctDateDebut
                                   , MAJReqLiensComposantsLot   => FAL_PLANIF.ctSansMAJLienCompoLot
                                   , MAJ_Reseaux_Requise        => FAL_PLANIF.ctSansMAJReseau
                                    );
      end if;
    end loop;
  end PlanifBatchesInException;

  /**
  * procedure : UpdatePlanifBatches
  * Description : Mise à jour de la planification des OF
  *               - Date planifiée début
  *               - Date planifiée fin
  *               - Durée planifiée = somme des durée des opérations (uniquement pour les OF qui ne sont pas en planification selon produit)
  * @created CLG
  * @lastUpdate
  * @public
  *
  * @param   iSessionId   session oracle
  */
  procedure UpdatePlanifBatches(iSessionId in number)
  is
  begin
    update FAL_LOT LOT
       set (LOT_PLAN_BEGIN_DTE, LOT_PLAN_END_DTE, LOT_PLAN_LEAD_TIME, A_DATEMOD, A_IDMOD) =
             (select FGT_RESULT_START_DATE
                   , FGT_RESULT_END_DATE
                   , decode(C_SCHEDULE_PLANNING, '1', LOT_PLAN_LEAD_TIME, (select sum(nvl(TAL_TASK_MANUF_TIME, 0) )
                                                                             from FAL_TASK_LINK
                                                                            where FAL_LOT_ID = LOT.FAL_LOT_ID) )
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                from FAL_GAN_TASK
               where FAL_LOT_ID = LOT.FAL_LOT_ID
                 and FAL_GAN_SESSION_ID = iSessionId)
     where FAL_LOT_ID in(
             select FAL_LOT_ID
               from FAL_GAN_TASK TSK
              where FAL_GAN_SESSION_ID = iSessionId
                and FAL_LOT_ID is not null
                and not exists(select FAL_GAN_TASK_ID
                                 from FAL_GAN_EXCEPTION
                                where FAL_GAN_SESSION_ID = iSessionId
                                  and FAL_GAN_TASK_ID = TSK.FAL_GAN_TASK_ID) );
  end UpdatePlanifBatches;

  /**
  * procedure : UpdateNetwork
  * Description : Mise à jour des réseaux
  *
  * @created CLG
  * @lastUpdate
  * @public
  *
  * @param   iSessionId   session oracle
  */
  procedure UpdateNetwork(iSessionId in number)
  is
  begin
    for crBatchesInGantt in (select LOT.FAL_LOT_ID
                                  , LOT.LOT_PLAN_BEGIN_DTE
                                  , LOT.LOT_PLAN_END_DTE
                               from FAL_GAN_TASK TSK
                                  , FAL_LOT LOT
                              where FAL_GAN_SESSION_ID = iSessionId
                                and LOT.FAL_LOT_ID = TSK.FAL_LOT_ID
                                and LOT.C_LOT_STATUS in('1', '2') ) loop
      -- Mise à jour des liens composants
      FAL_PLANIF.MAJ_LiensComposantsLot(crBatchesInGantt.FAL_LOT_ID, crBatchesInGantt.LOT_PLAN_END_DTE);
      -- Mise à jour de l'historique de lot de fabrication
      FAL_PLANIF.StorePlanifOrigin(aFAL_LOT_ID           => crBatchesInGantt.FAL_LOT_ID
                                 , aC_EVEN_TYPE          => cPlanifTypeGantt
                                 , aLOT_PLAN_BEGIN_DTE   => crBatchesInGantt.LOT_PLAN_BEGIN_DTE
                                 , aLOT_PLAN_END_DTE     => crBatchesInGantt.LOT_PLAN_END_DTE
                                  );
      -- Mise à jour des réseaux si nécéssaire
      FAL_NETWORK.MiseAJourReseaux(crBatchesInGantt.FAL_LOT_ID, FAL_NETWORK.ncPlannificationLot, null);
    end loop;
  end UpdateNetwork;

  /**
  * procedure : CheckModifiedPropositions
  * Description : Ajout en exception des propositions modifiées
  *               Valeurs de C_EXCEPTION_CODE :
  *               - cExcpBatchDeleted         = proposition supprimée
  *               - cExcpBatchQtyModified     = Quantité d'OF modifié
  * @created CLG
  * @lastUpdate
  * @public
  *
  * @param   iSessionId   session oracle
  */
  procedure CheckModifiedPropositions(iSessionId in number)
  is
  begin
    insert into FAL_GAN_EXCEPTION
                (FAL_GAN_EXCEPTION_ID
               , FGE_MESSAGE
               , C_EXCEPTION_CODE
               , FAL_GAN_TASK_ID
               , FAL_GAN_SESSION_ID
                )
      select GetNewId
           , FGT.FGT_REFERENCE
           , case
               when nvl(PROP.FAL_LOT_PROP_ID, 0) = 0 then cExcpBatchDeleted
               else cExcpBatchQtyModified
             end C_EXCEPTION_CODE
           , FGT.FAL_LOT_ID
           , iSessionId
        from FAL_GAN_TASK FGT
           , FAL_LOT_PROP PROP
       where FGT.FAL_LOT_PROP_ID = PROP.FAL_LOT_PROP_ID(+)
         and FGT.FAL_GAN_SESSION_ID = iSessionId
         and FGT.FAL_LOT_PROP_ID is not null
         and not exists(select FAL_GAN_TASK_ID
                          from FAL_GAN_EXCEPTION
                         where FAL_GAN_TASK_ID = FGT.FAL_GAN_TASK_ID)
         and (   PROP.FAL_LOT_PROP_ID is null
              or FGT.FGT_LOT_TOTAL_QTY <> PROP.LOT_TOTAL_QTY);
  end CheckModifiedPropositions;

  /**
  * procedure : UpdateResourceOfPropOperations
  * Description : Mise à jour des opérations de propositions qui ont changé d'atelier ou de sous-traitant
  *               (restriction sur opérations d'OF qui ne sont ni supprimés ni soldés)
  *    - Mise à jour du code "Interne", "Externe"
  *    - Mise à null de l'opérateur si c'est une opération externe
  *    - Ajout du service par défaut (défini par config) si opération externe qui n'en a pas
  *    - Si opération de prop de Sous-traitance d'achat, mise à jour des champs en provenance de la donnée complémentaire
  *
  * @created CLG
  * @lastUpdate
  * @public
  *
  * @param   iSessionId        Session oracle
  * @param   dFixPlanningDate  Date jusqu'à laquelle le planning est figé
  */
  procedure UpdateResourceOfPropOperations(iSessionId in number, dFixPlanningDate in date)
  is
    lrtGcoComplDataSubContract GCO_COMPL_DATA_SUBCONTRACT%rowtype;
  begin
    if cFalOrtDefaultService is null then
      Raise_Application_Error(-20000, 'You have to define the configuration FAL_ORT_DEFAULT_SERVICE');
    end if;

    -- Opérations de propositions standards
    update FAL_TASK_LINK_PROP TAL
       set (FAL_FACTORY_FLOOR_ID, PAC_SUPPLIER_PARTNER_ID, C_TASK_TYPE, FAL_FAL_FACTORY_FLOOR_ID, GCO_GOOD_ID, A_DATEMOD, A_IDMOD) =
             (select case
                       when OPE.FGO_PLAN_START_DATE < dFixPlanningDate then RES.FAL_FACTORY_FLOOR_ID
                       else TAL.FAL_FACTORY_FLOOR_ID
                     end
                   , RES.PAC_SUPPLIER_PARTNER_ID
                   , decode(RES.FAL_FACTORY_FLOOR_ID, null, '2', '1')
                   , decode(RES.FAL_FACTORY_FLOOR_ID, null, null, TAL.FAL_FAL_FACTORY_FLOOR_ID)
                   , decode(RES.FAL_FACTORY_FLOOR_ID, null, nvl(TAL.GCO_GOOD_ID, SERVICE.GCO_GOOD_ID), null)
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                from FAL_GAN_OPERATION OPE
                   , FAL_GAN_TIMING_RESOURCE RES
                   , (select GCO_GOOD_ID
                        from GCO_GOOD
                       where GOO_MAJOR_REFERENCE = cFalOrtDefaultService) SERVICE
               where OPE.FAL_TASK_LINK_PROP_ID = TAL.FAL_TASK_LINK_PROP_ID
                 and OPE.FAL_GAN_RESULT_TIMING_RES_ID = RES.FAL_GAN_TIMING_RESOURCE_ID)
     where FAL_TASK_LINK_PROP_ID in(
             select FGO.FAL_TASK_LINK_PROP_ID
               from FAL_GAN_OPERATION FGO
                  , FAL_GAN_TASK FGT
              where FGO.FAL_GAN_SESSION_ID = iSessionId
                and FGO.FAL_GAN_TASK_ID = FGT.FAL_GAN_TASK_ID
                and nvl(FGT.C_FAB_TYPE, '0') <> '4'
                and FGO.FAL_GAN_RESULT_TIMING_RES_ID <> FGO.FAL_GAN_TIMING_RESOURCE_ID
                and not exists(select FGE.FAL_GAN_TASK_ID
                                 from FAL_GAN_EXCEPTION FGE
                                where FGE.FAL_GAN_TASK_ID = FGO.FAL_GAN_TASK_ID
                                  and FGE.C_EXCEPTION_CODE in(cExcpBatchDeleted, cExcpErrorPlanifInGantt) ) );

    -- Opérations de propositions de sous-traitance d'achat
    for tplSSTAOperations in (select FGO.FAL_TASK_LINK_PROP_ID
                                   , FGT.GCO_GOOD_ID
                                   , RES.PAC_SUPPLIER_PARTNER_ID
                                   , FGO.FGO_PLAN_START_DATE
                                   , FGT.FGT_LOT_TOTAL_QTY
                                from FAL_GAN_OPERATION FGO
                                   , FAL_GAN_TASK FGT
                                   , FAL_GAN_TIMING_RESOURCE RES
                               where FGO.FAL_GAN_SESSION_ID = iSessionId
                                 and FGO.FAL_GAN_TASK_ID = FGT.FAL_GAN_TASK_ID
                                 and FGO.FAL_GAN_RESULT_TIMING_RES_ID = RES.FAL_GAN_TIMING_RESOURCE_ID
                                 and nvl(FGT.C_FAB_TYPE, '0') = '4'
                                 and FGO.FAL_GAN_RESULT_TIMING_RES_ID <> FGO.FAL_GAN_TIMING_RESOURCE_ID
                                 and not exists(
                                         select FGE.FAL_GAN_TASK_ID
                                           from FAL_GAN_EXCEPTION FGE
                                          where FGE.FAL_GAN_TASK_ID = FGO.FAL_GAN_TASK_ID
                                            and FGE.C_EXCEPTION_CODE in(cExcpBatchDeleted, cExcpErrorPlanifInGantt) ) ) loop
      lrtGcoComplDataSubContract  :=
        GCO_LIB_COMPL_DATA.GetDefaultSubCComplData(tplSSTAOperations.GCO_GOOD_ID
                                                 , tplSSTAOperations.PAC_SUPPLIER_PARTNER_ID
                                                 , null
                                                 , tplSSTAOperations.FGO_PLAN_START_DATE
                                                  );

      if lrtGcoComplDataSubContract.GCO_COMPL_DATA_SUBCONTRACT_ID is not null then
        update FAL_TASK_LINK_PROP
           set PAC_SUPPLIER_PARTNER_ID = lrtGcoComplDataSubContract.PAC_SUPPLIER_PARTNER_ID
             , GCO_GOOD_ID = lrtGcoComplDataSubContract.GCO_GCO_GOOD_ID
             , SCS_AMOUNT = lrtGcoComplDataSubContract.CSU_AMOUNT
             , SCS_WEIGH = lrtGcoComplDataSubContract.CSU_WEIGH
             , SCS_WEIGH_MANDATORY = lrtGcoComplDataSubContract.CSU_WEIGH_MANDATORY
             , SCS_PLAN_RATE = nvl(lrtGcoComplDataSubContract.CSU_SUBCONTRACTING_DELAY, 0)
             , SCS_PLAN_PROP = decode(nvl(lrtGcoComplDataSubContract.CSU_FIX_DELAY, 0), 0, 1, 0)
             , SCS_QTY_REF_WORK = nvl(lrtGcoComplDataSubContract.CSU_LOT_QUANTITY, 1)
             , TAL_PLAN_RATE =
                 (tplSSTAOperations.FGT_LOT_TOTAL_QTY / FAL_TOOLS.nvla(lrtGcoComplDataSubContract.CSU_LOT_QUANTITY, 1) ) *
                 nvl(lrtGcoComplDataSubContract.CSU_SUBCONTRACTING_DELAY, 0)
             , TAL_DUE_AMT = tplSSTAOperations.FGT_LOT_TOTAL_QTY * nvl(lrtGcoComplDataSubContract.CSU_AMOUNT, 0)
         where FAL_TASK_LINK_PROP_ID = tplSSTAOperations.FAL_TASK_LINK_PROP_ID;
      end if;
    end loop;
  end UpdateResourceOfPropOperations;

  /**
  * procedure : DeleteObsoletePropOpeLUM
  * Description : Suppression des LMU dans les cas suivants :
  *    - Changement d'îlot
  *    - Atelier à capacité infini
  *    - Sous-traitant
  *
  * @created CLG
  * @lastUpdate
  * @public
  *
  * @param   iSessionId   session oracle
  */
  procedure DeleteObsoletePropOpeLUM(iSessionId in number)
  is
  begin
    delete from FAL_TASK_LINK_PROP_USE
          where FAL_TASK_LINK_PROP_ID in(
                  select OPE.FAL_TASK_LINK_PROP_ID
                    from FAL_GAN_OPERATION OPE
                       , FAL_GAN_TIMING_RESOURCE RES
                       , FAL_FACTORY_FLOOR FAC
                   where OPE.FAL_GAN_RESULT_TIMING_RES_ID <> OPE.FAL_GAN_TIMING_RESOURCE_ID
                     and OPE.FAL_GAN_RESULT_TIMING_RES_ID = RES.FAL_GAN_TIMING_RESOURCE_ID
                     and RES.FAL_FACTORY_FLOOR_ID = FAC.FAL_FACTORY_FLOOR_ID(+)
                     and OPE.FAL_GAN_SESSION_ID = iSessionId
                     and (   nvl( (FAC.FAC_INFINITE_FLOOR), 1) = 0
                          or nvl( (select FAL_FACTORY_FLOOR_ID
                                     from FAL_FACTORY_FLOOR
                                    where FAL_FACTORY_FLOOR_ID = FAC.FAL_FAL_FACTORY_FLOOR_ID), FAC.FAL_FACTORY_FLOOR_ID) <>
                               nvl( (select FAL_FACTORY_FLOOR_ID
                                       from FAL_FACTORY_FLOOR
                                      where FAL_FACTORY_FLOOR_ID =
                                                              (select FAL_FAL_FACTORY_FLOOR_ID
                                                                 from FAL_FACTORY_FLOOR
                                                                where FAL_FACTORY_FLOOR_ID = (select FAL_FACTORY_FLOOR_ID
                                                                                                from FAL_GAN_TIMING_RESOURCE
                                                                                               where FAL_GAN_TIMING_RESOURCE_ID = OPE.FAL_GAN_TIMING_RESOURCE_ID) ) )
                                 , (select FAL_FACTORY_FLOOR_ID
                                      from FAL_GAN_TIMING_RESOURCE
                                     where FAL_GAN_TIMING_RESOURCE_ID = OPE.FAL_GAN_TIMING_RESOURCE_ID)
                                  )
                         )
                     and not exists(select FAL_GAN_TASK_ID
                                      from FAL_GAN_EXCEPTION
                                     where FAL_GAN_TASK_ID = OPE.FAL_GAN_TASK_ID
                                       and C_EXCEPTION_CODE in(cExcpBatchDeleted, cExcpErrorPlanifInGantt) ) );
  end DeleteObsoletePropOpeLUM;

  /**
  * procedure : UpdatePlanifPropOperations
  * Description : Mise à jour des la planification des opérations
  *               (restriction sur opérations d'OF qui ne sont pas dans la table d'exception)
  *    - Mise à jour date début
  *    - Mise à jour date fin
  *    - Recalcul du champ planification si atelier à capacité infini ou sous-traitant
  *    - Durée non proportionnelle pour atelier à capacité infini ou sous-traitant
  *
  * @created CLG
  * @lastUpdate
  * @public
  *
  * @param   iSessionId   session oracle
  */
  procedure UpdatePlanifPropOperations(iSessionId in number)
  is
  begin
    update FAL_TASK_LINK_PROP TAL
       set (TAL_BEGIN_PLAN_DATE, TAL_END_PLAN_DATE, SCS_PLAN_RATE, SCS_PLAN_PROP, A_DATEMOD, A_IDMOD) =
             (select OPE.FGO_PLAN_START_DATE
                   , OPE.FGO_PLAN_END_DATE
                   , decode(nvl( (FAC.FAC_INFINITE_FLOOR), 1)
                          , 1, FAL_PLANIF.GetDurationInDay(RES.FAL_FACTORY_FLOOR_ID, RES.PAC_SUPPLIER_PARTNER_ID, OPE.FGO_PLAN_START_DATE
                                                         , OPE.FGO_PLAN_END_DATE)
                          , TAL.SCS_PLAN_RATE
                           ) SCS_PLAN_RATE
                   , decode(nvl( (FAC.FAC_INFINITE_FLOOR), 1), 1, 0, TAL.SCS_PLAN_PROP) SCS_PLAN_PROP
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                from FAL_GAN_OPERATION OPE
                   , FAL_GAN_TIMING_RESOURCE RES
                   , FAL_FACTORY_FLOOR FAC
               where OPE.FAL_TASK_LINK_PROP_ID = TAL.FAL_TASK_LINK_PROP_ID
                 and OPE.FAL_GAN_RESULT_TIMING_RES_ID = RES.FAL_GAN_TIMING_RESOURCE_ID
                 and RES.FAL_FACTORY_FLOOR_ID = FAC.FAL_FACTORY_FLOOR_ID(+)
                 and OPE.FAL_GAN_SESSION_ID = iSessionId)
     where FAL_TASK_LINK_PROP_ID in(
                           select FAL_TASK_LINK_PROP_ID
                             from FAL_GAN_OPERATION FGO
                            where FAL_GAN_SESSION_ID = iSessionId
                              and not exists(select FAL_GAN_TASK_ID
                                               from FAL_GAN_EXCEPTION
                                              where FAL_GAN_SESSION_ID = iSessionId
                                                and FAL_GAN_TASK_ID = FGO.FAL_GAN_TASK_ID) );

    -- Pour les opérations externes, la durée de la tâche est la même que celle de la planification
    update FAL_TASK_LINK_PROP
       set TAL_TASK_MANUF_TIME = SCS_PLAN_RATE
     where PAC_SUPPLIER_PARTNER_ID is not null
       and FAL_TASK_LINK_PROP_ID in(
                           select FAL_TASK_LINK_PROP_ID
                             from FAL_GAN_OPERATION FGO
                            where FAL_GAN_SESSION_ID = iSessionId
                              and not exists(select FAL_GAN_TASK_ID
                                               from FAL_GAN_EXCEPTION
                                              where FAL_GAN_SESSION_ID = iSessionId
                                                and FAL_GAN_TASK_ID = FGO.FAL_GAN_TASK_ID) );
  end UpdatePlanifPropOperations;

  /**
  * procedure : UpdatePropOperations
  * Description : Mise à jour des opérations de propositions
  *
  * @created CLG
  * @lastUpdate
  * @public
  *
  * @param   iSessionId        session oracle
  * @param   dFixPlanningDate  Date jusqu'à laquelle le planning est figé
  */
  procedure UpdatePropOperations(iSessionId in number, dFixPlanningDate in date)
  is
  begin
    -- Mise à jour des ressources
    UpdateResourceOfPropOperations(iSessionId, dFixPlanningDate);
    -- Suppression des machines obsolètes
    DeleteObsoletePropOpeLUM(iSessionId);
    -- Mise à jour de la planification sur les opérations
    UpdatePlanifPropOperations(iSessionId);
  end UpdatePropOperations;

  /**
  * procedure : PlanifPropInException
  * Description : Planification des propositions en exception (prop. dont la quantité a été modifié)
  *               - Planification arrière pour les propositions qui sont prédécesseur et jamais successeur
  *               - Planification avant pour toutes les autres
  *
  * @created CLG
  * @lastUpdate
  * @public
  *
  * @param   iSessionId   session oracle
  */
  procedure PlanifPropInException(iSessionId in number)
  is
    cursor crFalGanPropositionInExcept
    is
      select TSK.FAL_LOT_PROP_ID
           , decode(C_EXCEPTION_CODE
                  , cExcpErrorPlanifInGantt, (select FGO_PLAN_START_DATE
                                                from FAL_GAN_OPERATION
                                               where FAL_GAN_TASK_ID = TSK.FAL_GAN_TASK_ID
                                                 and FGO_STEP_NUMBER = (select min(FGO_STEP_NUMBER)
                                                                          from FAL_GAN_OPERATION
                                                                         where FAL_GAN_TASK_ID = TSK.FAL_GAN_TASK_ID) )
                  , FGT_RESULT_START_DATE
                   ) FGT_RESULT_START_DATE
           , FGT_RESULT_END_DATE
           , (select count(*)
                from FAL_GAN_LINK
               where FAL_GAN_PRED_TASK_ID = EXCP.FAL_GAN_TASK_ID) CNT_PRED_LNK
           , (select count(*)
                from FAL_GAN_LINK
               where FAL_GAN_SUCC_TASK_ID = EXCP.FAL_GAN_TASK_ID) CNT_SUCC_LNK
           , EXCP.C_EXCEPTION_CODE
        from FAL_GAN_EXCEPTION EXCP
           , FAL_GAN_TASK TSK
       where EXCP.FAL_GAN_TASK_ID = TSK.FAL_GAN_TASK_ID
         and EXCP.FAL_GAN_SESSION_ID = iSessionId
         and TSK.FAL_LOT_PROP_ID is not null
         and C_EXCEPTION_CODE <> cExcpBatchDeleted;
  begin
    for tplFalGanPropositionInExcept in crFalGanPropositionInExcept loop
      if     (tplFalGanPropositionInExcept.CNT_PRED_LNK > 0)
         and (tplFalGanPropositionInExcept.CNT_SUCC_LNK = 0)
         and (tplFalGanPropositionInExcept.C_EXCEPTION_CODE <> cExcpErrorPlanifInGantt) then
        -- Si la proposition est prédécesseur et jamais successeur d'une autre tâche, planification date fin
        FAL_PLANIF.Planification_Lot_Prop(PrmFAL_LOT_PROP_ID          => tplFalGanPropositionInExcept.FAL_LOT_PROP_ID
                                        , DatePlanification           => tplFalGanPropositionInExcept.FGT_RESULT_END_DATE
                                        , SelonDateDebut              => FAL_PLANIF.ctDateFin
                                        , MAJReqLiensComposantsProp   => FAL_PLANIF.ctSansMAJLienCompoLot
                                        , MAJ_Reseaux_Requise         => FAL_PLANIF.ctSansMAJReseau
                                         );
      else
        -- Dans tous les autres cas, planification date début
        FAL_PLANIF.Planification_Lot_Prop(PrmFAL_LOT_PROP_ID          => tplFalGanPropositionInExcept.FAL_LOT_PROP_ID
                                        , DatePlanification           => tplFalGanPropositionInExcept.FGT_RESULT_START_DATE
                                        , SelonDateDebut              => FAL_PLANIF.ctDateDebut
                                        , MAJReqLiensComposantsProp   => FAL_PLANIF.ctSansMAJLienCompoLot
                                        , MAJ_Reseaux_Requise         => FAL_PLANIF.ctSansMAJReseau
                                         );
      end if;
    end loop;
  end PlanifPropInException;

  /**
  * procedure : UpdatePlanifPropositions
  * Description : Mise à jour de la planification des propositions
  *               - Date planifiée début
  *               - Date planifiée fin
  *               - Durée planifiée = somme des durée des opérations
  *                 (uniquement pour les propositions qui ne sont pas en planification selon produit)
  * @created CLG
  * @lastUpdate
  * @public
  *
  * @param   iSessionId   session oracle
  */
  procedure UpdatePlanifPropositions(iSessionId in number)
  is
  begin
    update FAL_LOT_PROP PROP
       set (LOT_PLAN_BEGIN_DTE, LOT_PLAN_END_DTE, LOT_PLAN_LEAD_TIME, A_DATEMOD, A_IDMOD) =
             (select FGT_RESULT_START_DATE
                   , FGT_RESULT_END_DATE
                   , decode(C_SCHEDULE_PLANNING, '1', (select sum(nvl(TAL_TASK_MANUF_TIME, 0) )
                                                         from FAL_TASK_LINK_PROP
                                                        where FAL_LOT_PROP_ID = PROP.FAL_LOT_PROP_ID) )
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                from FAL_GAN_TASK
               where FAL_LOT_PROP_ID = PROP.FAL_LOT_PROP_ID
                 and FAL_GAN_SESSION_ID = iSessionId)
     where FAL_LOT_PROP_ID in(
             select FAL_LOT_PROP_ID
               from FAL_GAN_TASK TSK
              where FAL_GAN_SESSION_ID = iSessionId
                and FAL_LOT_PROP_ID is not null
                and not exists(select FAL_GAN_TASK_ID
                                 from FAL_GAN_EXCEPTION
                                where FAL_GAN_SESSION_ID = iSessionId
                                  and FAL_GAN_TASK_ID = TSK.FAL_GAN_TASK_ID) );
  end UpdatePlanifPropositions;

  /**
  * procedure : UpdateNetworkForProp
  * Description : Mise à jour des réseaux pour les propositions
  *
  * @created CLG
  * @lastUpdate
  * @public
  *
  * @param   iSessionId   session oracle
  */
  procedure UpdateNetworkForProp(iSessionId in number)
  is
  begin
    for crPropInGantt in (select PROP.FAL_LOT_PROP_ID
                               , PROP.LOT_PLAN_END_DTE
                            from FAL_GAN_TASK TSK
                               , FAL_LOT_PROP PROP
                           where FAL_GAN_SESSION_ID = iSessionId
                             and PROP.FAL_LOT_PROP_ID = TSK.FAL_LOT_PROP_ID) loop
      -- Mise à jour des liens composants
      FAL_PLANIF.MAJ_LiensComposantsProp(crPropInGantt.FAL_LOT_PROP_ID, crPropInGantt.LOT_PLAN_END_DTE);
      -- Mise à jour des réseaux si nécéssaire
      FAL_NETWORK.MiseAJourReseaux(crPropInGantt.FAL_LOT_PROP_ID, FAL_NETWORK.ncPlanificationLotProp, null);
    end loop;
  end UpdateNetworkForProp;

  /**
   * procedure : CheckModifiedDF
   * Description : Ajout en exception des OF modifiées
   *               Valeurs de C_EXCEPTION_CODE :
   *               - cExcpBatchDeleted         = DF a été supprimé
   *               - cExcpBatchBalanced        = DF soldé
   *               - cExcpBatchSuspended      = DF suspendu
   *               - cExcpBatchQtyModified     = Quantité d'DF modifié
   *               - cExcpProcessPlanModified  = La gamme a été modifiée
   *                 (sum des FAL_SCHEDULE_STEP_ID différents entre FAL_TASK_LINK et FAL_GAN_OPERATION pour le même OF)
   *               - cExcpProcessTrackModified = Du suivi a été effectué ou supprimé sur une des opérations
   *                 (des suivis ont été créés ou supprimés (extournés) avec une date de création suppérieure à A_DATECRE de la session)
   * @created CLG
   * @lastUpdate
   * @public
   *
   * @param   iSessionId   session oracle
   */
  procedure CheckModifiedDF(iSessionId in number)
  is
  begin
    insert into FAL_GAN_EXCEPTION
                (FAL_GAN_EXCEPTION_ID
               , FGE_MESSAGE
               , C_EXCEPTION_CODE
               , FAL_GAN_TASK_ID
               , FAL_GAN_SESSION_ID
                )
      select GetNewId
           , FGT.FGT_REFERENCE
           , case
               when nvl(TAS.GAL_TASK_ID, 0) = 0 then cExcpBatchDeleted
               when TAS.C_TAS_STATE = '40'   -- soldé
                                          then cExcpBatchBalanced
               when TAS.C_TAS_STATE = '99'   -- suspendu
                                          then cExcpBatchSuspended
               when FGT.FGT_LOT_TOTAL_QTY <> TAS.TAS_QUANTITY then cExcpBatchQtyModified
               when (select sum(GAL_TASK_LINK_ID)
                       from GAL_TASK_LINK TAL
                      where TAL.GAL_TASK_ID = TAS.GAL_TASK_ID) <> (select sum(GAL_TASK_LINK_ID)
                                                                     from FAL_GAN_OPERATION OPE
                                                                    where OPE.FAL_GAN_TASK_ID = FGT.FAL_GAN_TASK_ID) then cExcpProcessPlanModified
             end C_EXCEPTION_CODE
           , FGT.FAL_GAN_TASK_ID
           , iSessionId
        from FAL_GAN_TASK FGT
           , GAL_TASK TAS
       where FGT.GAL_TASK_ID = TAS.GAL_TASK_ID(+)
         and FGT.FAL_GAN_SESSION_ID = iSessionId
         and FGT.GAL_TASK_ID is not null
         and FGT.GAL_FATHER_TASK_ID is not null   -- DF
         and not exists(select FAL_GAN_TASK_ID
                          from FAL_GAN_EXCEPTION
                         where FAL_GAN_TASK_ID = FGT.FAL_GAN_TASK_ID)
         and (   TAS.GAL_TASK_ID is null
              or TAS.C_TAS_STATE not in('10', '20', '30')
              or FGT.FGT_LOT_TOTAL_QTY <> TAS.TAS_QUANTITY
              or (select sum(GAL_TASK_LINK_ID)
                    from GAL_TASK_LINK TAL
                   where TAL.GAL_TASK_ID = TAS.GAL_TASK_ID) <> (select sum(GAL_TASK_LINK_ID)
                                                                  from FAL_GAN_OPERATION OPE
                                                                 where OPE.FAL_GAN_TASK_ID = FGT.FAL_GAN_TASK_ID)
             );
  end CheckModifiedDF;

   /**
  * procedure : UpdateResourceOfOperationsDF
  * Description : Mise à jour des opérations qui ont changé d'atelier ou de sous-traitant
  *               (restriction sur opérations de dossier de fabrication PRP (DF) qui ne sont ni supprimés ni soldés)
  *    - Mise à jour du code "Interne", "Externe"
  *    - Mise à null de l'opérateur si c'est une opération externe
  *    - Ajout du service par défaut (défini par config) si opération externe qui n'en a pas
  *
  * @created CLG
  * @lastUpdate
  * @public
  *
  * @param   iSessionId        Session oracle
  * @param   dFixPlanningDate  Date jusqu'à laquelle le planning est figé
  */
  procedure UpdateResourceOfOperationsDF(iSessionId in number, dFixPlanningDate in date)
  is
  begin
    if cFalOrtDefaultService is null then
      Raise_Application_Error(-20000, 'You have to define the configuration FAL_ORT_DEFAULT_SERVICE');
    end if;

    update GAL_TASK_LINK TAL
       set (FAL_FACTORY_FLOOR_ID, PAC_SUPPLIER_PARTNER_ID, C_TASK_TYPE, FAL_FAL_FACTORY_FLOOR_ID, GCO_GCO_GOOD_ID, A_DATEMOD, A_IDMOD) =
             (select case
                       when OPE.FGO_PLAN_START_DATE < dFixPlanningDate then RES.FAL_FACTORY_FLOOR_ID
                       else TAL.FAL_FACTORY_FLOOR_ID
                     end
                   , RES.PAC_SUPPLIER_PARTNER_ID
                   , decode(RES.FAL_FACTORY_FLOOR_ID, null, '2', '1')
                   , decode(RES.FAL_FACTORY_FLOOR_ID, null, null, TAL.FAL_FAL_FACTORY_FLOOR_ID)
                   , decode(RES.FAL_FACTORY_FLOOR_ID, null, nvl(TAL.GCO_GCO_GOOD_ID, SERVICE.GCO_GOOD_ID), null)
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                from FAL_GAN_OPERATION OPE
                   , FAL_GAN_TIMING_RESOURCE RES
                   , (select GCO_GOOD_ID
                        from GCO_GOOD
                       where GOO_MAJOR_REFERENCE = cFalOrtDefaultService) SERVICE
               where OPE.GAL_TASK_LINK_ID = TAL.GAL_TASK_LINK_ID
                 and OPE.FAL_GAN_RESULT_TIMING_RES_ID = RES.FAL_GAN_TIMING_RESOURCE_ID
                 and OPE.FAL_GAN_SESSION_ID = iSessionId)
     where GAL_TASK_LINK_ID in(
             select GAL_TASK_LINK_ID
               from FAL_GAN_OPERATION FGO
                  , FAL_GAN_TASK FGT
              where FGT.FAL_GAN_SESSION_ID = iSessionId
                and FGT.GAL_FATHER_TASK_ID is not null
                and FGO.FAL_GAN_TASK_ID = FGT.FAL_GAN_TASK_ID
                and nvl(FGO.FAL_GAN_RESULT_TIMING_RES_ID, 0) <> nvl(FGO.FAL_GAN_TIMING_RESOURCE_ID, 0)
                and not exists(
                             select FAL_GAN_TASK_ID
                               from FAL_GAN_EXCEPTION
                              where FAL_GAN_TASK_ID = FGO.FAL_GAN_TASK_ID
                                and C_EXCEPTION_CODE in(cExcpBatchDeleted, cExcpBatchBalanced, cExcpErrorPlanifInGantt) ) );
  end UpdateResourceOfOperationsDF;

  /**
  * procedure : UpdatePlanifOperationsdf
  * Description : Mise à jour de la planification des opérations
  *               (restriction sur opérations de DF qui ne sont pas dans la table d'exception)
  *    - Mise à jour date début
  *    - Mise à jour date fin
  *    - Recalcul du champ planification si atelier à capacité infini ou sous-traitant
  *    - Durée non proportionnelle pour atelier à capacité infini ou sous-traitant
  *
  * @created CLG
  * @lastUpdate
  * @public
  *
  * @param   iSessionId   session oracle
  */
  procedure UpdatePlanifOperationsDF(iSessionId in number)
  is
  begin
    update GAL_TASK_LINK TAL
       set (TAL_BEGIN_PLAN_DATE, TAL_END_PLAN_DATE, SCS_PLAN_RATE, A_DATEMOD, A_IDMOD) =
             (select OPE.FGO_PLAN_START_DATE
                   , OPE.FGO_PLAN_END_DATE
                   , decode(nvl( (FAC.FAC_INFINITE_FLOOR), 1)
                          , 1, FAL_PLANIF.GetDurationInDay(RES.FAL_FACTORY_FLOOR_ID, RES.PAC_SUPPLIER_PARTNER_ID, OPE.FGO_PLAN_START_DATE
                                                         , OPE.FGO_PLAN_END_DATE)
                          , TAL.SCS_PLAN_RATE
                           ) SCS_PLAN_RATE
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                from FAL_GAN_OPERATION OPE
                   , FAL_GAN_TIMING_RESOURCE RES
                   , FAL_FACTORY_FLOOR FAC
               where OPE.GAL_TASK_LINK_ID = TAL.GAL_TASK_LINK_ID
                 and OPE.FAL_GAN_RESULT_TIMING_RES_ID = RES.FAL_GAN_TIMING_RESOURCE_ID
                 and RES.FAL_FACTORY_FLOOR_ID = FAC.FAL_FACTORY_FLOOR_ID(+)
                 and OPE.FAL_GAN_SESSION_ID = iSessionId)
     where GAL_TASK_LINK_ID in(
             select GAL_TASK_LINK_ID
               from FAL_GAN_OPERATION FGO
                  , FAL_GAN_TASK FGT
              where FGT.FAL_GAN_SESSION_ID = iSessionId
                and FGT.GAL_FATHER_TASK_ID is not null
                and FGO.FAL_GAN_TASK_ID = FGT.FAL_GAN_TASK_ID
                and not exists(select FAL_GAN_TASK_ID
                                 from FAL_GAN_EXCEPTION
                                where FAL_GAN_SESSION_ID = iSessionId
                                  and FAL_GAN_TASK_ID = FGO.FAL_GAN_TASK_ID) );
  end UpdatePlanifOperationsDF;

  /**
  * procedure : UpdateOperations
  * Description : Mise à jour des opérations
  *
  * @created CLG
  * @lastUpdate
  * @public
  *
  * @param   iSessionId        session oracle
  * @param   dFixPlanningDate  Date jusqu'à laquelle le planning est figé
  */
  procedure UpdateOperationsDF(iSessionId in number, dFixPlanningDate in date)
  is
  begin
    -- Mise à jour des ressources
    UpdateResourceOfOperationsDF(iSessionId, dFixPlanningDate);
    -- Mise à jour de la planification sur les opérations
    UpdatePlanifOperationsDF(iSessionId);
  end UpdateOperationsDF;

  /**
  * procedure : UpdatePlanifTaskDF
  * Description : Mise à jour de la planification des tâches relatives aux DF PRP
  *               - Date planifiée début
  *               - Date planifiée fin
  *               - Durée planifiée = somme des durée des opérations (uniquement pour les OF qui ne sont pas en planification selon produit)
  * @created CLG
  * @lastUpdate
  * @public
  *
  * @param   iSessionId   session oracle
  */
  procedure UpdatePlanifTaskDF(iSessionId in number)
  is
  begin
    update GAL_TASK TAS
       set (TAS_START_DATE, TAS_END_DATE, A_DATEMOD, A_IDMOD) = (select FGT_RESULT_START_DATE
                                                                      , FGT_RESULT_END_DATE
                                                                      , sysdate
                                                                      , PCS.PC_I_LIB_SESSION.GetUserIni
                                                                   from FAL_GAN_TASK
                                                                  where GAL_TASK_ID = TAS.GAL_TASK_ID
                                                                    and FAL_GAN_SESSION_ID = iSessionId)
     where GAL_TASK_ID in(
             select TSK.GAL_TASK_ID
               from FAL_GAN_TASK TSK
              where FAL_GAN_SESSION_ID = iSessionId
                and TSK.GAL_TASK_ID is not null
                and TSK.GAL_FATHER_TASK_ID is not null
                and not exists(select FAL_GAN_TASK_ID
                                 from FAL_GAN_EXCEPTION GAE
                                where GAE.FAL_GAN_SESSION_ID = iSessionId
                                  and GAE.FAL_GAN_TASK_ID = TSK.FAL_GAN_TASK_ID) );
  end UpdatePlanifTaskDF;

  /**
  * procedure : UpdatePlanification
  * Description : Mise à jour de la planification depuis le Gantt
  *
  * @created CLG
  * @lastUpdate
  * @public
  *
  * @param   iSessionId        Session oracle
  * @param   dFixPlanningDate  Date jusqu'à laquelle le planning est figé
  * @param   iSaveBatches      Indique si on effectue la mise à jour des OF
  * @param   iSavePropositions Indique si on effectue la mise à jour des propositions
  */
  procedure UpdatePlanification(iSessionId in number, dFixPlanningDate in date, iSaveBatches in integer, iSavePropositions in integer, iSaveDF in integer)
  is
  begin
    -- Suppression des exceptions déja existantes pour la session (exceptée celle d'erreur venant du planning Gantt)
    delete from FAL_GAN_EXCEPTION
          where FAL_GAN_SESSION_ID = iSessionId
            and C_EXCEPTION_CODE <> cExcpErrorPlanifInGantt;

    if iSaveBatches = 1 then
      CheckModifiedBatches(iSessionId);
      -- Mise à jour des opérations
      UpdateOperations(iSessionId, dFixPlanningDate);
      -- Planification des OF en exception
      PlanifBatchesInException(iSessionId);
      -- Mise à jour de la planification des OF
      UpdatePlanifBatches(iSessionId);
      -- Mise à jour de la sous-traiatnce d'achat
      UpdateSSTADelay(iSessionId);
      -- Mise à jour des réseaux et de l'historique de l'OF
      UpdateNetwork(iSessionId);
    end if;

    if iSavePropositions = 1 then
      CheckModifiedPropositions(iSessionId);
      -- Mise à jour des opérations de propositions
      UpdatePropOperations(iSessionId, dFixPlanningDate);
      -- Planification des propositions en exception
      PlanifPropInException(iSessionId);
      -- Mise à jour de la planification des propositions
      UpdatePlanifPropositions(iSessionId);
      -- Mise à jour des réseaux et de l'historique des propositions
      UpdateNetworkForProp(iSessionId);
    end if;

    if iSaveDF = 1 then
      CheckModifiedDF(iSessionId);
      -- Mise à jour de la planification des OF
      UpdatePlanifTaskDF(iSessionId);
                                        -- DOIT précéder l'appel de UpdateOperationDF  (trigger sur GAL_TASK -> maj opérations)
      -- Mise à jour des opérations
      UpdateOperationsDF(iSessionId, dFixPlanningDate);
    end if;
  end UpdatePlanification;
end FAL_GANTT_UPDATE;
