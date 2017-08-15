--------------------------------------------------------
--  DDL for Package Body FAL_PRC_BATCH
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_BATCH" 
is
  /**
  * procedure pUpdateQuantity
  * Description
  *    update batch quantity on table FAL_LOT
  * @created fp 19.01.2011
  * @lastUpdate
  * @private
  * @param
  */
  procedure pUpdateQuantity(
    iFalLotId in     FAL_LOT.FAL_LOT_ID%type
  , iQty      in     FAL_LOT.LOT_INPROD_QTY%type
  , iLaunched in     boolean default false
  , oError    out    varchar2
  )
  is
    lCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
    ldelta    FAL_LOT.LOT_TOTAL_QTY%type;
  begin
    -- one row cursor
    for ltplLot in (select LOT_INPROD_QTY
                         , LOT_ASKED_QTY
                         , LOT_TOTAL_QTY
                         , LOT_FREE_QTY
                         , LOT_RELEASE_QTY
                      from FAL_LOT
                     where FAL_LOT_ID = iFalLotId) loop
      -- On travaille par rapport à la quantité totale (LOT_TOTAL_QTY). On calcul le delta par rapport à l'ancienne quantité.
      -- Le delta sera reporté sur les autres quantité
      lDelta  := ltplLot.LOT_TOTAL_QTY - iQty;
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalLot, lCRUD_DEF);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'FAL_LOT_ID', iFalLotId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'LOT_INPROD_QTY', ltplLot.LOT_INPROD_QTY - lDelta);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'LOT_ASKED_QTY', ltplLot.LOT_INPROD_QTY - lDelta);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'LOT_TOTAL_QTY', iQty);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'LOT_FREE_QTY', ltplLot.LOT_INPROD_QTY - lDelta);

      if iLaunched then
        FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'LOT_RELEASE_QTY', ltplLot.LOT_RELEASE_QTY - lDelta);
      end if;

      FWK_I_MGT_ENTITY.UpdateEntity(lCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(lCRUD_DEF);
    end loop;
  end pUpdateQuantity;

  /**
  * Description
  *   Mise à jour de la quantité du lot de fabrication
  */
  procedure UpdateBatchQuantity(
    iFalLotId     in     FAL_LOT.FAL_LOT_ID%type
  , iQty          in     FAL_LOT.LOT_INPROD_QTY%type
  , iPlanning     in     number default 0
  , iCoupledGoods in     number default 0
  , iLaunched     in     boolean default false
  , oError        out    varchar2
  )
  is
    lOrderId   FAL_ORDER.FAL_ORDER_ID%type;
    lProgramId FAL_JOB_PROGRAM.FAL_JOB_PROGRAM_ID%type;
    testQty    number;
    lBeginDate FAL_LOT.LOT_PLAN_BEGIN_DTE%type;
    lEndDate   FAL_LOT.LOT_PLAN_END_DTE%type;
    lCFabType  FAL_LOT.C_FAB_TYPE%type;
  begin
    -- update FAL_LOT_quantity
    pUpdateQuantity(iFalLotId => iFalLotId, iQty => iQty, iLaunched => iLaunched, oError => oError);

    select LOT_TOTAL_QTY
         , LOT_PLAN_BEGIN_DTE
         , LOT_PLAN_END_DTE
         , nvl(C_FAB_TYPE, '0')
      into testQty
         , lBegindate
         , lEndDate
         , lCFabType
      from FAL_LOT
     where FAL_LOT_ID = iFalLotId;

    -- update operations
    FAL_TASK_GENERATOR.UpdateBatchQty(aFalLotId => iFalLotId, aNewTotalQty => iQty, oError => oError);
    -- update components
    FAL_COMPONENT.UpdateBatchComponents(aFalLotId => iFalLotId, aNewLotTotalQty => iQty);

    if iPlanning = 1 then
      -- Mise à jour de la date de fin du lot de fabrication
      UpdateBatchDelay(iFalLotId        => iFalLotId
                     , iBeginDate       => lBeginDate
                     , iEndDate         => lEndDate
                     , iUpdateNetwork   => 0   -- already done at the end of this procedure
                     , iCFabType        => lCFabType
                     , oError           => oError
                      );
    end if;

    -- update coupled good
    if     PCS.PC_CONFIG.GetBooleanConfig('FAL_COUPLED_GOOD')
       and iCoupledGoods = 1
       and FAL_LIB_BATCH.ExistsDetails(iLotId => iFalLotId) then
      FAL_COUPLED_GOOD.UpdateCoupledProductQty(iFalLotId => iFalLotId, iNewQty => iQty);
    end if;

    -- update order quantities
    FAL_ORDER_FUNCTIONS.UpdateOrder(aFAL_ORDER_ID => FAL_LIB_BATCH.GetOrderId(iFalLotId) );
    -- update program
    FAL_PROGRAM_FUNCTIONS.UpdateManufactureProgram(aFalJobProgramId => FAL_LIB_BATCH.GetJobprogramId(iFalLotId) );
    -- update history of batch (c_even_type = '3')
    FAL_BATCH_FUNCTIONS.CreateBatchHistory(aFAL_LOT_ID => iFalLotId, aC_EVEN_TYPE => '3', aErrorCode => oError);
    -- update networks
    FAL_NETWORK.MiseAJourReseaux(ALotID => iFalLotId, AContext => 2, AStockPositionIDList => null);
  exception
    when others then
      oError  := sqlerrm;
  end UpdateBatchQuantity;

  /**
  * Procedure UpdateBatchDelay
  * Description
  *   Mise à jour de la date de fin du lot de fabrication
  * @created    FPE 18.01.2011
  * @lastUpdate VJE 03.12.2012
  * @public
  * @param iFalLotId          : Id du lot
  * @param iEndDate           : Date de fin du lot
  * @param iUpdateNetwork     : Mise à jour des résaux demandés
  * @param iFalScheduleStepId : Opération du lot
  * @param   aSearchBackwardFromTaskLinkId : utilisé uniquement si  PlanificationType = ctDateFin
  *          Défini l'opération à partir de laquelle se fait la recalculation arriere
  * @param iCFabType          : Type de lot
  * @param oError             : Code d'erreur
  */
  procedure UpdateBatchDelay(
    iFalLotId                     in     FAL_LOT.FAL_LOT_ID%type
  , iBeginDate                    in     FAL_LOT.LOT_PLAN_BEGIN_DTE%type
  , iEndDate                      in     FAL_LOT.LOT_PLAN_END_DTE%type
  , iUpdateNetwork                in     number default 1
  , iFalScheduleStepId            in     FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type default null
  , aSearchBackwardFromTaskLinkId in     FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type default null
  , iCFabType                     in     FAL_LOT.C_FAB_TYPE%type default '0'
  , oError                        out    varchar2
  )
  is
    ldBasisDelay          DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type;
    ldInterDelay          DOC_POSITION_DETAIL.PDE_INTERMEDIATE_DELAY%type;
    ldFinalDelay          DOC_POSITION_DETAIL.PDE_FINAL_DELAY%type;
    lFalScheduleStepId    FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type;
    lPacSupplierPartnerId PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type;
  begin
    if iCFabType = FAL_BATCH_FUNCTIONS.btSubcontract then
      --
      -- Pour un lot de sous-traitance d'achat, il faut uniqumement mettre à jour la date de début planifié avec le délai de base du
      -- détail de position de la CAST et la date de fin planifié avec le délai final.
      lFalScheduleStepId  := iFalScheduleStepId;

      if lFalScheduleStepId is null then
        select max(TAL.FAL_SCHEDULE_STEP_ID)
             , max(TAL.PAC_SUPPLIER_PARTNER_ID)
          into lFalScheduleStepId
             , lPacSupplierPartnerId
          from FAL_TASK_LINK TAL
         where TAL.FAL_LOT_ID = iFalLotId;
      end if;

      -- Recherche les délais de la commande CAST d'origine
      select PDE.PDE_BASIS_DELAY
           , PDE.PDE_INTERMEDIATE_DELAY
           , PDE.PDE_FINAL_DELAY
        into ldBasisDelay
           , ldInterDelay
           , ldFinalDelay
        from DOC_POSITION_DETAIL PDE
       where PDE.FAL_LOT_ID = iFalLotId
         and DOC_LIB_SUBCONTRACTP.IsSUPOGauge(PDE.DOC_GAUGE_ID) = 1;

      -- Mise à jour des dates début/fin planifiée du lot de sous-traitance d'achat ainsi que son opération
      FAL_PRC_SUBCONTRACTP.UpdateSubcontractBatchDelay(iFalLotId               => iFalLotId
                                                     , iFalScheduleStepId      => lFalScheduleStepId
                                                     , iPacSupplierPartnerId   => lPacSupplierPartnerId
                                                     , iBasisDelay             => ldBasisDelay
                                                     , iInterDelay             => ldInterDelay
                                                     , iFinalDelay             => ldFinalDelay
                                                      );
    elsif nvl(iFalScheduleStepId, 0) > 0 then
      -- Sous-traitance opératoire

      -- update planning
      FAL_PLANIF.Planification_Lot(PrmFAL_LOT_ID                   => iFalLotId
                                 , DatePlanification               => null   -- défini selon date fin de la tâche aSearchBackwardFromTaskLinkId
                                 , SelonDateDebut                  => FAL_PLANIF.ctDateFin
                                 , MAJReqLiensComposantsLot        => 0
                                 , MAJ_Reseaux_Requise             => iUpdateNetwork
                                 , aSearchBackwardFromTaskLinkId   => aSearchBackwardFromTaskLinkId
                                  );
    end if;
  exception
    when others then
      oError  := sqlerrm;
  end UpdateBatchDelay;

  /**
  * Procedure UpdateBatchStock
  * Description
  *   Mise à jour du stock et emplacement du lot de fabrication
  */
  procedure UpdateBatchStock(iFalLotID in FAL_LOT.FAL_LOT_ID%type, iStockID in FAL_LOT.STM_STOCK_ID%type, iLocationID in FAL_LOT.STM_LOCATION_ID%type)
  is
    lFalLot FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalLot, lFalLot);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lFalLot, 'FAL_LOT_ID', iFalLotID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lFalLot, 'STM_STOCK_ID', iStockID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lFalLot, 'STM_LOCATION_ID', iLocationID);
    FWK_I_MGT_ENTITY.UpdateEntity(lFalLot);
    FWK_I_MGT_ENTITY.Release(lFalLot);
  end UpdateBatchStock;
end FAL_PRC_BATCH;
