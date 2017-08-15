--------------------------------------------------------
--  DDL for Package Body FAL_PRC_SUBCONTRACTP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_SUBCONTRACTP" 
is
  gSessionId FAL_LOT1.LT1_ORACLE_SESSION%type   := DBMS_SESSION.unique_session_id;

  /**
  * procedure UpdateDocPosDetLink
  * Description
  *   update foreign key on DOC_POSITION_DETAIL
  * @created fp 12.01.2011
  * @lastUpdate
  * @public
  * @param iPositionDetailId   : position detail
  * @param iLotid              : manufacturing order created
  * @param iManufacturedGoodId : manufactured good
  */
  procedure UpdateDocPosDetLink(
    iPositionDetailId   in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  , iLotId              in FAL_LOT.FAL_LOT_ID%type
  , iManufacturedGoodId in FAL_LOT.GCO_GOOD_ID%type
  )
  is
    lCRUD_DEF   FWK_I_TYP_DEFINITION.t_crud_def;
    lPositionID DOC_POSITION.DOC_POSITION_ID%type;
  begin
    -- update DOC_POSITION_DETAIL
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_DOC_ENTITY.gcDocPositionDetail, lCRUD_DEF, false, iPositionDetailId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'FAL_LOT_ID', iLotId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'GCO_MANUFACTURED_GOOD_ID', iManufacturedGoodId);
    FWK_I_MGT_ENTITY.UpdateEntity(lCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(lCRUD_DEF);
    -- update DOC_POSITION
    lPositionID  := FWK_I_LIB_ENTITY.getNumberFieldFromPk(FWK_I_TYP_DOC_ENTITY.gcDocPositionDetail, 'DOC_POSITION_ID', iPositionDetailId);
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_DOC_ENTITY.gcDocPosition, lCRUD_DEF, false, lPositionID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'FAL_LOT_ID', iLotId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lCRUD_DEF, 'GCO_MANUFACTURED_GOOD_ID', iManufacturedGoodId);
    FWK_I_MGT_ENTITY.UpdateEntity(lCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(lCRUD_DEF);
  end UpdateDocPosDetLink;

  /**
  * procedure ClearDocPosDetLink
  * Description
  *   clear foreign key on DOC_POSITION_DETAIL
  * @created fp 13.01.2011
  * @lastUpdate
  * @public
  * @param iPositionDetailId : position detail
  */
  procedure ClearDocPosDetLink(iPositionDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
  is
    lCRUD_DEF   FWK_I_TYP_DEFINITION.t_crud_def;
    lPositionID DOC_POSITION.DOC_POSITION_ID%type;
  begin
    -- update DOC_POSITION_DETAIL
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_DOC_ENTITY.gcDocPositionDetail, lCRUD_DEF, false, iPositionDetailId);
    FWK_I_MGT_ENTITY_DATA.SetColumnNull(lCRUD_DEF, 'FAL_LOT_ID');
    FWK_I_MGT_ENTITY.UpdateEntity(lCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(lCRUD_DEF);
    -- update DOC_POSITION
    lPositionID  := FWK_I_LIB_ENTITY.getNumberFieldFromPk(FWK_I_TYP_DOC_ENTITY.gcDocPositionDetail, 'DOC_POSITION_ID', iPositionDetailId);
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_DOC_ENTITY.gcDocPosition, lCRUD_DEF, false, lPositionID);
    FWK_I_MGT_ENTITY_DATA.SetColumnNull(lCRUD_DEF, 'FAL_LOT_ID');
    FWK_I_MGT_ENTITY.UpdateEntity(lCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(lCRUD_DEF);
  end ClearDocPosDetLink;

  /**
  * Description
  *   Generate a manufacturing order based on a subcontracting purchases order document
  */
  procedure GenerateBatch(iPositionDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type, oLotId out FAL_LOT.FAL_LOT_ID%type, oError out varchar2)
  is
    lGoodId               DOC_POSITION.GCO_GOOD_ID%type;
    lManufacturedGoodId   DOC_POSITION.GCO_MANUFACTURED_GOOD_ID%type;
    lSupplierId           DOC_POSITION.PAC_THIRD_ID%type;
    lStockId              DOC_POSITION.STM_STOCK_ID%type;
    lLocationId           DOC_POSITION.STM_LOCATION_ID%type;
    lRecordId             DOC_POSITION.DOC_RECORD_ID%type;
    lAskedQuantity        DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY_SU%type;
    lPlanBeginDate        DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type;
    lPlanEndDate          DOC_POSITION_DETAIL.PDE_FINAL_DELAY%type;
    ltplComplDataSubC     GCO_COMPL_DATA_SUBCONTRACT%rowtype;
    lJobProgramId         FAL_JOB_PROGRAM.FAL_JOB_PROGRAM_ID%type;
    lJobProgramReference  FAL_JOB_PROGRAM.JOP_REFERENCE%type;
    lJobProgramShortDescr FAL_JOB_PROGRAM.JOP_SHORT_DESCR%type;
    lOrderId              FAL_ORDER.FAL_ORDER_ID%type;
    lComplDataId          GCO_COMPL_DATA_SUBCONTRACT.GCO_COMPL_DATA_SUBCONTRACT_ID%type;
    lLotRefCompl          FAL_LOT.LOT_REFCOMPL%type                                       default null;
  begin
    savepoint spGenerateLotForSUBCONTRACTP;
    -- control source position
    oError  := DOC_I_LIB_SUBCONTRACTP.ControlDocPdeBeforeGenerate(iPositionDetailId);

    -- if no error with source position
    if oError is null then
      -- retrieve position informations
      select POS.GCO_GOOD_ID
           , POS.GCO_MANUFACTURED_GOOD_ID
           , POS.PAC_THIRD_ID
           , POS.DOC_RECORD_ID
           , PDE.PDE_BASIS_QUANTITY_SU
           , PDE.PDE_BASIS_DELAY
           , PDE.PDE_FINAL_DELAY
           , POS.GCO_COMPL_DATA_ID
           , FAL_I_LIB_SUBCONTRACTP.getNewSubCoRefCompl(iPositionID => POS.DOC_POSITION_ID)
        into lGoodId
           , lManufacturedGoodId
           , lSupplierId
           , lRecordId
           , lAskedQuantity
           , lPlanBeginDate
           , lPlanEndDate
           , lComplDataId
           , lLotRefCompl
        from DOC_DOCUMENT DMT
           , DOC_POSITION POS
           , DOC_POSITION_DETAIL PDE
       where PDE.DOC_POSITION_DETAIL_ID = iPositionDetailId
         and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID;

      -- get subcontracting complementary datas
      ltplComplDataSubC  := GCO_I_LIB_COMPL_DATA.GetSubCComplDataTuple(iComplDataId => lComplDataId);

      -- if subcontracting complementary datas have been found then continue
      if ltplComplDataSubC.GCO_COMPL_DATA_SUBCONTRACT_ID is not null then
        -- looking for reception stock and location
        if ltplComplDataSubC.STM_STOCK_ID is not null then
          lStockId     := ltplComplDataSubC.STM_STOCK_ID;
          lLocationId  := ltplComplDataSubC.STM_LOCATION_ID;
        else
          -- seek first on the good and if not defined seek in default configuration
          GCO_I_LIB_FUNCTIONS.GetGoodStockLocation(lManufacturedGoodId, lStockId, lLocationId);
        end if;

        -- looking for program
        lJobProgramReference  := FAL_LIB_SUBCONTRACTP.GetProgramNumber;
        lJobProgramId         := FAL_LIB_PROGRAM.GetJobProgramId(lJobProgramReference);

        if lJobProgramId is not null then
          -- if program exist try to retrieve order
          lOrderId  := FAL_LIB_SUBCONTRACTP.GetOrderId(lJobProgramId, lSupplierId, lManufacturedGoodId);
        else
          -- if program does not exists, create it
          lJobProgramId  := FAL_PROGRAM_FUNCTIONS.CreateSubContractProgram(lJobProgramReference, PCS.PC_FUNCTIONS.TranslateWord('Sous-traitance d''achat') );
        end if;

        if lOrderId is null then
          lOrderId  :=
            FAL_ORDER_FUNCTIONS.CreateManufactureOrder(aFAL_JOB_PROGRAM_ID        => lJobProgramId
                                                     , aGCO_GOOD_ID               => lManufacturedGoodId
                                                     , aDOC_RECORD_ID             => lRecordId
                                                     , aC_FAB_TYPE                => FAL_BATCH_FUNCTIONS.btSubcontract
                                                     , aPAC_SUPPLIER_PARTNER_ID   => lSupplierId
                                                      );
        end if;

        -- Generation of the manufactirung order
        FAL_BATCH_FUNCTIONS.CreateBatch(aFAL_ORDER_ID                 => lOrderId
                                      , aDIC_FAB_CONDITION_ID         => ltplComplDataSubC.DIC_FAB_CONDITION_ID
                                      , aSTM_STOCK_ID                 => lStockId
                                      , aSTM_LOCATION_ID              => lLocationId
                                      , aLOT_PLAN_BEGIN_DTE           => lPlanBeginDate
                                      , aLOT_PLAN_END_DTE             => lPlanEndDate
                                      , aLOT_ASKED_QTY                => lAskedQuantity
                                      , aPPS_NOMENCLATURE_ID          => ltplComplDataSubC.PPS_NOMENCLATURE_ID
                                      , aFAL_SCHEDULE_PLAN_ID         => FAL_LIB_SUBCONTRACTP.GetSchedulePlanId
                                      , aDOC_RECORD_ID                => lRecordId
                                      , aGCO_GOOD_ID                  => lManufacturedGoodId
                                      , aLOT_PLAN_VERSION             => ltplComplDataSubC.CSU_PLAN_VERSION
                                      , aLOT_PLAN_NUMBER              => ltplComplDataSubC.CSU_PLAN_NUMBER
                                      , aPPS_OPERATION_PROCEDURE_ID   => ltplComplDataSubC.PPS_OPERATION_PROCEDURE_ID
                                      , aFAL_JOB_PROGRAM_ID           => lJobProgramId
                                      , aC_FAB_TYPE                   => FAL_BATCH_FUNCTIONS.btSubcontract
                                      , aC_DISCHARGE_COM              => ltplComplDataSubC.C_DISCHARGE_COM
                                      , PlanifOnBeginDate             => 0
                                      , aCreatedFAL_LOT_ID            => oLotId
                                      , iPacSupplierPartnerId         => lSupplierId
                                      , iGcoGcoGoodId                 => lGoodId
                                      , iScsAmount                    => ltplComplDataSubC.CSU_AMOUNT
                                      , iScsQtyRefAmount              => 0
                                      , iScsDivisorAmount             => 0
                                      , iScsWeigh                     => ltplComplDataSubC.CSU_WEIGH
                                      , iScsWeighMandatory            => ltplComplDataSubC.CSU_WEIGH_MANDATORY
                                      , iLotRefCompl                  => lLotRefCompl
                                      , aErrorMsg                     => oError
                                       );
      else
        oError  := PCS.PC_FUNCTIONS.TranslateWord('Aucune données de sous-traitance trouvées pour le bien et le fournisseur du document.');
      end if;

      -- Maj of foreign key on DOC_POSITION_DETAIL
      UpdateDocPosDetLink(iPositionDetailId, oLotId, lManufacturedGoodId);
    end if;

    -- if some error, rollback all treatment
    if oError is not null then
      rollback to savepoint spGenerateLotForSUBCONTRACTP;
    end if;
  end GenerateBatch;

  /**
  * function pBatchQuantityModified
  * Description
  *    control if qty has been modified
  * @created fp 18.01.2011
  * @lastUpdate
  * @public
  * @param
  * @return
  */
  function pBatchQuantityModified(iPositionDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    return boolean
  is
    lBatchQty FAL_LOT.LOT_TOTAL_QTY%type;
    lPosQty   DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY_SU%type;
  begin
    select LOT.LOT_TOTAL_QTY
         , PDE.PDE_FINAL_QUANTITY_SU
      into lBatchQty
         , lPosQty
      from FAL_LOT LOT
         , DOC_POSITION_DETAIL PDE
     where LOT.FAL_LOT_ID = PDE.FAL_LOT_ID
       and PDE.DOC_POSITION_DETAIL_ID = iPositionDetailId;

    return(lBatchQty <> lPosQty);
  end pBatchQuantityModified;

  /**
  * function pBatchQuantityModified
  * Description
  *    control if delay has been modified
  * @created fp 18.01.2011
  * @lastUpdate
  * @public
  * @param
  * @return
  */
  function pBatchDelayModified(iPositionDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    return boolean
  is
    lBatchBegin    FAL_LOT.LOT_PLAN_BEGIN_DTE%type;
    lBatchEnd      FAL_LOT.LOT_PLAN_END_DTE%type;
    lPosBasisDelay DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type;
    lPosFinalDelay DOC_POSITION_DETAIL.PDE_FINAL_DELAY%type;
  begin
    select LOT.LOT_PLAN_BEGIN_DTE
         , LOT.LOT_PLAN_END_DTE
         , PDE.PDE_BASIS_DELAY
         , PDE.PDE_FINAL_DELAY
      into lBatchBegin
         , lBatchEnd
         , lPosBasisDelay
         , lPosFinalDelay
      from FAL_LOT LOT
         , DOC_POSITION_DETAIL PDE
     where LOT.FAL_LOT_ID = PDE.FAL_LOT_ID
       and PDE.DOC_POSITION_DETAIL_ID = iPositionDetailId;

    return    (lBatchBegin <> lPosBasisDelay)
           or (lBatchEnd <> lPosFinalDelay);
  end pBatchDelayModified;

  /**
  * Description
  *    update manufacturing lot when quantity is modified
  */
  procedure UpdateBatch(iPositionDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type, oError out varchar2)
  is
    lQtyModified   boolean := pBatchQuantityModified(iPositionDetailId);
    lDelayModified boolean := pBatchDelayModified(iPositionDetailId);
  begin
    -- one line cursor
    for ltplPosition in (select PDE.FAL_LOT_ID
                              , LOT.C_LOT_STATUS
                              , nvl(LOT.C_FAB_TYPE, '0') C_FAB_TYPE
                              , DOC_LIB_SUBCONTRACT.getSubcontractOperation(PDE.DOC_POSITION_ID) FAL_SCHEDULE_STEP_ID
                              , PDE.PDE_FINAL_QUANTITY_SU
                              , PDE.PDE_FINAL_DELAY
                           from DOC_POSITION_DETAIL PDE
                              , FAL_LOT LOT
                          where DOC_POSITION_DETAIL_ID = iPositionDetailId
                            and LOT.FAL_LOT_ID = PDE.FAL_LOT_ID) loop
      oError  := FAL_I_LIB_SUBCONTRACTP.ControlBatchBeforeUpdate(ltplPosition.FAL_LOT_ID);

      if oError is null then
        -- batch protection
        FAL_BATCH_RESERVATION.BatchReservation(aFAL_LOT_ID => ltplPosition.FAL_LOT_ID, aLT1_ORACLE_SESSION => gSessionId, aErrorMsg => oError);

        begin
          -- in case of quantity update
          if lQtyModified then
            FAL_PRC_BATCH.UpdateBatchQuantity(iFalLotId       => ltplPosition.FAL_LOT_ID
                                            , iQty            => ltplPosition.PDE_FINAL_QUANTITY_SU
                                            , iPlanning       => bool2byte(not lDelayModified)   -- if delay modified, planification done during UpdateBatchDelay
                                            , iCoupledGoods   => 1   -- update of coupled goods datas (may be a config should pilot?)
                                            , iLaunched       => (ltplPosition.C_LOT_STATUS = FAL_LIB_BATCH.cLotStatusLaunched)
                                            , oError          => oError
                                             );
          end if;

          -- in case of delay update
          if lDelayModified then
            -- Mise à jour des dates début/fin planifiée du lot de sous-traitance d'achat ainsi que son opération
            FAL_PRC_BATCH.UpdateBatchDelay(iFalLotId            => ltplPosition.FAL_LOT_ID
                                         , iBeginDate           => null
                                         , iEndDate             => ltplPosition.PDE_FINAL_DELAY
                                         , iUpdateNetwork       => 1
                                         , iFalScheduleStepId   => ltplPosition.FAL_SCHEDULE_STEP_ID
                                         , iCFabType            => ltplPosition.C_FAB_TYPE
                                         , oError               => oError
                                          );
          end if;
        exception
          when others then
            oError  := sqlerrm;
        end;
      end if;
    end loop;

    -- batch free protection
    FAL_BATCH_RESERVATION.ReleaseReservedBatches(aSessionId => gSessionId);
  end UpdateBatch;

  /**
  * procedure pDeleteBatch
  * Description
  *    remove manufacturing batch (batch is translation of "lot") (with batch identifier)
  * @created fp 13.01.2011
  * @lastUpdate
  * @public
  * @param  iPositionDetailId
  * @param  oError
  */
  procedure pDeleteBatch(
    iLotId            in     FAL_LOT.FAL_LOT_ID%type
  , iPositionDetailId in     DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type default null
  , oError            out    varchar2
  )
  is
  begin
    -- batch protection
    FAL_BATCH_RESERVATION.BatchReservation(aFAL_LOT_ID => iLotId, aLT1_ORACLE_SESSION => gSessionId, aErrorMsg => oError);

    if iPositionDetailId is not null then
      ClearDocPosDetLink(iPositionDetailId);
    end if;

    FAL_BATCH_FUNCTIONS.DeleteBatch(iLotId, 1);
  exception
    when others then
      oError  := sqlerrm;
  end pDeleteBatch;

  /**
  * Description
  *    remove manufacturing lot (with position detail identifier)
  */
  procedure DeleteBatch(iPositionDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type, oError out varchar2)
  is
    lLotId FAL_LOT.FAL_LOT_ID%type;
  begin
    select FAL_LOT_ID
      into lLotId
      from DOC_POSITION_DETAIL
     where DOC_POSITION_DETAIL_ID = iPositionDetailId
       and FAL_LOT_ID is not null;

    oError  := FAL_I_LIB_SUBCONTRACTP.ControlBatchBeforeDelete(iLotId => lLotId);

    if oError is null then
      pDeleteBatch(iLotId => lLotId, iPositionDetailId => iPositionDetailId, oError => oError);
    end if;
  end DeleteBatch;

  /**
  * procedure LaunchBatch
  * Description
  *    launch manufacturing batch (lot) (with position detail identifier)
  * @created fp 19.01.2011
  * @lastUpdate
  * @public
  * @param  iPositionDetailId
  * @param  oError
  */
  procedure LaunchBatch(iPositionDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type, oError out varchar2)
  is
    lAbort number(1);
    lFound boolean;
  begin
    -- one line cursor
    for ltplPosition in (select FAL_LOT_ID
                              , PDE_FINAL_QUANTITY
                              , nvl(PDE.PDE_FINAL_DELAY, nvl(PDE.PDE_INTERMEDIATE_DELAY, PDE.PDE_BASIS_DELAY) ) PDE_FINAL_DELAY
                           from DOC_POSITION_DETAIL PDE
                          where DOC_POSITION_DETAIL_ID = iPositionDetailId) loop
      -- batch protection / traitement dans une transaction autonome
      FAL_BATCH_RESERVATION.BatchReservation(aFAL_LOT_ID           => ltplPosition.FAL_LOT_ID
                                           , aLT1_ORACLE_SESSION   => gSessionId
                                           , aErrorMsg             => oError
                                           , aFalLotIdFound        => lFound
                                            );

      if not lFound then   -- traitement dans la transaction active (reprise POAST)
        FAL_BATCH_RESERVATION.InternalBatchReservation(aFAL_LOT_ID           => ltplPosition.FAL_LOT_ID
                                                     , aLT1_ORACLE_SESSION   => gSessionId
                                                     , aDoCommit             => false
                                                     , aErrorMsg             => oError
                                                      );
      end if;

      begin
        FAL_BATCH_LAUNCHING.ControlBeforeLaunch(iSessionId => gSessionId, iFalLotId => ltplPosition.FAL_LOT_ID, ioMessage => oError, ioAbortProcess => lAbort);

        -- is control OK then continue
        if lAbort = 0 then
          FAL_BATCH_LAUNCHING.LaunchBatch(aFalLotId => ltplPosition.FAL_LOT_ID, aSessionId => gSessionId, aCaseReleaseCode => 1, aManageBatchReservation => 0);
        end if;
      exception
        when others then
          oError  := sqlerrm;
      end;
    end loop;

    -- batch free protection
    FAL_BATCH_RESERVATION.ReleaseReservedBatches(aSessionId => gSessionId);
  end LaunchBatch;

  /**
  * Description
  *    balance manufacturing batch (lot) (with position detail identifier)
  */
  procedure BalanceBatch(iPositionDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type, oError out varchar2)
  is
    lReturn           pls_integer                         := 1;
    lSubCStockId      DOC_POSITION.STM_STOCK_ID%type;
    lSubCLocationId   DOC_POSITION.STM_LOCATION_ID%type;
    liAutoInitCharact integer                             := 0;
  begin
    -- one line cursor
    for ltplPosition in (select FAL_LOT_ID
                              , PAC_THIRD_ID
                           from DOC_POSITION_DETAIL PDE
                          where DOC_POSITION_DETAIL_ID = iPositionDetailId) loop
      -- Looking for consumption stock and location
      STM_I_LIB_STOCK.getSubCStockAndLocation(ltplPosition.PAC_THIRD_ID, lSubCStockId, lSubCLocationId);
      -- Reception
      FAL_BATCH_FUNCTIONS.Recept(aFalLotId               => ltplPosition.FAL_LOT_ID
                               , aSessionId              => gSessionId
                               , BatchBalance            => 1
                               , AnswerYesAllQuestions   => 1
                               , iAutoCommit             => 0
                               , ioAutoInitCharact       => liAutoInitCharact
                               , aResult                 => lReturn
                                );

      if lReturn > 0 then
        oError  := PCS.PC_FUNCTIONS.TranslateWord('Problème lors du solde d''un OF de sous-traitance.');
      end if;
    end loop;
  end BalanceBatch;

  /**
  * Description
  *    receipt manufacturing batch (lot) (with position detail identifier)
  *    important : the batch must have been checked before up to know if all
  *                components are available
  *
  *                iWaste parameter must be only active in balance position context
  */
  procedure ReceiptBatch(iPositionDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type, iWaste in number default 0, oError out varchar2)
  is
    lReturn           pls_integer                         := 1;
    lSubCStockId      DOC_POSITION.STM_STOCK_ID%type;
    lSubCLocationId   DOC_POSITION.STM_LOCATION_ID%type;
    lCLotStatus       FAL_LOT.C_LOT_STATUS%type;
    lRejectStockId    STM_STOCK.STM_STOCK_ID%type;
    lRejectLocationId STM_LOCATION.STM_LOCATION_ID%type;
    lBalance          number(1)                           := 0;
    lReceiptQty       number                              := 0;
    lRejectQty        number                              := 0;
    lDismountedQty    number                              := 0;
    liAutoInitCharact integer                             := 0;
  begin
    -- recherche des stock déchets
    lRejectStockId     := FWK_I_LIB_ENTITY.getIdfromPk2('STM_STOCK', 'STO_DESCRIPTION', PCS.PC_CONFIG.GetConfig('PPS_DefltSTOCK_TRASH') );
    lRejectLocationId  := FWK_I_LIB_ENTITY.getIdfromPk2('STM_LOCATION', 'LOC_DESCRIPTION', PCS.PC_CONFIG.GetConfig('PPS_DefltLOCATION_TRASH') );

    -- one line cursor
    for ltplPosition in (select PDE.FAL_LOT_ID
                              -- solde position avec mise en déchet
                         ,      decode(iWaste, 0, 0, PDE.PDE_FINAL_QUANTITY_SU *(PDE.PDE_BALANCE_QUANTITY / PDE.PDE_FINAL_QUANTITY) )
                                                                                                                                    PDE_BALANCE_REJECT_QUANTITY
                              , decode(iWaste, 1, 0, PDE.PDE_FINAL_QUANTITY_SU) PDE_FINAL_QUANTITY_SU
                              , PDE.DOC_POSITION_ID
                              , PDE.PAC_THIRD_ID
                              , LOT.LOT_INPROD_QTY
                              , LOT.LOT_PT_REJECT_QTY
                              , LOT.LOT_CPT_REJECT_QTY
                           from DOC_POSITION_DETAIL PDE
                              , FAL_LOT LOT
                          where PDE.DOC_POSITION_DETAIL_ID = iPositionDetailId
                            and LOT.FAL_LOT_ID = PDE.FAL_LOT_ID) loop
      lReceiptQty  := ltplPosition.PDE_FINAL_QUANTITY_SU;
      lRejectQty   := ltplPosition.PDE_BALANCE_REJECT_QUANTITY;
      -- Stockage de l'ID de la position déclenchant la réception pour la stocker dans les mouvements de stock provoqué par cette réception
      COM_I_LIB_LIST_ID_TEMP.setGlobalVar('DOC_STT_RECEPT_POSITION_ID', ltplPosition.DOC_POSITION_ID);

      -- Détermine si le lot doit être soldé lors de cette réception.
      if     ( (lReceiptQty + lRejectQty + lDismountedQty) >=(ltplPosition.LOT_INPROD_QTY + ltplPosition.LOT_PT_REJECT_QTY + ltplPosition.LOT_CPT_REJECT_QTY) )
         and (lRejectQty >= ltplPosition.LOT_PT_REJECT_QTY)
         and (lDismountedQty >= ltplPosition.LOT_CPT_REJECT_QTY) then
        lBalance  := 1;
      end if;

      -- Looking for consumption stock and location
      STM_I_LIB_STOCK.getSubCStockAndLocation(ltplPosition.PAC_THIRD_ID, lSubCStockId, lSubCLocationId);
      -- Reception
      FAL_BATCH_FUNCTIONS.Recept(aFalLotId               => ltplPosition.FAL_LOT_ID
                               , aSessionId              => gSessionId
                               , aFinishedProductQty     => lReceiptQty
                               , aRejectQty              => lRejectQty
                               , aRejectStockId          => lRejectStockId
                               , aRejectLocationId       => lRejectLocationId
                               , BatchBalance            => lBalance
                               , AnswerYesAllQuestions   => 1
                               , iAutoCommit             => 0
                               , aReleaseBatch           => 0
                               , aResult                 => lReturn
                               , iStmStmStockId          => lSubCStockId
                               , iStmStmLocationId       => lSubCLocationId
                               , ioAutoInitCharact       => liAutoInitCharact
                                );

      -- Status du lot
      select LOT.C_LOT_STATUS
        into lCLotStatus
        from FAL_LOT LOT
       where LOT.FAL_LOT_ID = ltplPosition.FAL_LOT_ID;

      -- Erreur : Réception retourne une erreur ou le lot n'a pas été réceptionné et soldé
      if    lReturn > 0
         or (     (lBalance = 1)
             and (lCLotStatus <> FAL_BATCH_FUNCTIONS.bsBalanced) ) then
        if     (lBalance = 1)
           and (lCLotStatus <> FAL_BATCH_FUNCTIONS.bsBalanced) then   -- Solde du lot demandé mais pas effectué
          oError  := PCS.PC_FUNCTIONS.TranslateWord('Problème lors du solde d''un OF de sous-traitance.');
        else
          oError  := PCS.PC_FUNCTIONS.TranslateWord('Problème lors de la réception d''un OF de sous-traitance.');
        end if;

        if (lReturn > 0) then
          oError  := oError || ' (' || lReturn || ')';
        end if;
      elsif lReturn < 0 then   -- Demande l'intervention de l'utilisateur. Interdit dans le cadre de la confirmation en série
        oError  := PCS.PC_FUNCTIONS.TranslateWord('La confirmation en série n''est pas autorisée dans ce contexte. Utiliser la confirmation unitaire.');
        oError  := oError || ' (' || lReturn || ')';
      end if;
    end loop;

    -- Supprimme l'ID de la position déclenchant la réception pour la stocker dans les mouvements de stock provoqué par cette réception
    COM_LIB_LIST_ID_TEMP.clearGlobalVar('DOC_STT_RECEPT_POSITION_ID');
  exception
    when others then
      -- Supprimme l'ID de la position déclenchant la réception pour la stocker dans les mouvements de stock provoqué par cette réception
      COM_LIB_LIST_ID_TEMP.clearGlobalVar('DOC_STT_RECEPT_POSITION_ID');
      raise;
  end ReceiptBatch;

  /**
  * procedure UpdateSubcontractDelay
  * Description
  *   Update subcontract document on update operation of a subcontract batch
  *
  * @created clg 14.09.2011
  * @lastUpdate
  * @public
  */
  procedure UpdateSubcontractDelay(
    iStartDate              in date
  , iCGaugeShowDelay        in DOC_GAUGE_POSITION.C_GAUGE_SHOW_DELAY%type
  , iGapPosDelay            in number
  , iPacThirdCdaId          in number
  , iGcoGoodId              in number
  , iStmStockId             in number
  , iStmStmStockId          in number
  , iCAdminDomain           in DOC_GAUGE.C_ADMIN_DOMAIN%type
  , iCGaugeType             in DOC_GAUGE.C_GAUGE_TYPE%type
  , iGapTransfertProprietor in number
  , iGcoComplDataId         in number
  , iPdeBasisQuantity       in number
  , iDocPositionDetailId    in number
  , iPacSupplierPartnerId   in number
  , iFalScheduleStepId      in number
  , iFalLotId               in number
  , iUpdatedDelay           in varchar2 default 'BASIS'
  )
  is
    lvBasisDelay varchar2(10);
    lvInterDelay varchar2(10);
    lvFinalDelay varchar2(10);
    ldBasisDelay date;
    ldInterDelay date;
    ldFinalDelay date;
    opDuration   number;
    ltCRUD_DEF   FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    lvBasisDelay  := null;
    lvInterDelay  := null;
    lvFinalDelay  := null;
    ldBasisDelay  := iStartDate;
    ldInterDelay  := iStartDate;
    ldFinalDelay  := iStartDate;
    -- Calculate final, intermediate and basis delays according to iUpdatedDelay
    DOC_POSITION_DETAIL_FUNCTIONS.GetPDEDelay(aShowDelay             => iCGaugeShowDelay   -- Management delay
                                            , aPosDelay              => iGapPosDelay   -- Unused with aShowDelay = 1
                                            , aUpdatedDelay          => iUpdatedDelay   -- Kind of delay referenced
                                            , aForward               => case iUpdatedDelay
                                                when 'FINAL' then 0
                                                else 1
                                              end   -- Forward calculation
                                            , aThirdID               => iPacThirdCdaId   -- subcontractor
                                            , aGoodID                => iGcoGoodId   -- Manufacturing good
                                            , aStockID               => iStmStockId   -- Unused in subcontracting domain
                                            , aTargetStockID         => iStmStmStockId   -- Unused in subcontracting domain
                                            , aAdminDomain           => iCAdminDomain
                                            , aGaugeType             => iCGaugeType
                                            , aTransfertProprietor   => iGapTransfertProprietor   -- Unused in subcontracting domain
                                            , aBasisDelayMW          => lvBasisDelay
                                            , aInterDelayMW          => lvInterDelay
                                            , aFinalDelayMW          => lvFinalDelay
                                            , aBasisDelay            => ldBasisDelay
                                            , aInterDelay            => ldInterDelay
                                            , aFinalDelay            => ldFinalDelay
                                            , iComplDataId           => iGcoComplDataId
                                            , iQuantity              => iPdeBasisQuantity
                                            , iScheduleStepId        => null   -- Unused in subcontracting domain
                                             );
    -- mise à jour des délais recalculés des positions de document
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcdocpositiondetail, ltCRUD_DEF, true, iDocPositionDetailId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PDE_BASIS_DELAY', ldBasisDelay);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PDE_INTERMEDIATE_DELAY', ldInterDelay);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PDE_FINAL_DELAY', ldFinalDelay);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    -- Mise à jour des dates début/fin planifiée du lot de sous-traitance d'achat ainsi que son opération
    UpdateSubcontractBatchDelay(iFalLotId               => iFalLotId
                              , iFalScheduleStepId      => iFalScheduleStepId
                              , iPacSupplierPartnerId   => iPacSupplierPartnerId
                              , iBasisDelay             => ldBasisDelay
                              , iInterDelay             => ldInterDelay
                              , iFinalDelay             => ldFinalDelay
                               );
  end UpdateSubcontractDelay;

  /**
  * procedure UpdateSubcontractDelay
  * Description
  *   Update subcontract document on update operation of a subcontract batch
  *
  * @created clg 14.09.2011
  * @lastUpdate
  * @public
  */
  procedure UpdateSubcontractDelay(iStartDate date, iFalLotId in number, iUpdatedDelay in varchar2 default 'BASIS')
  is
    cursor crSubcontractPositionDetail
    is
      select PDE.DOC_POSITION_DETAIL_ID
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
           , table(DOC_LIB_SUBCONTRACTP.GetSUPOGaugeId(DOC.PAC_THIRD_ID) ) DocGauge
       where LOT.FAL_LOT_ID = POS.FAL_LOT_ID
         and LOT.FAL_LOT_ID = TAL.FAL_LOT_ID
         and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
         and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
         and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
         and DOC.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and PDE.DOC_GAUGE_ID = DocGauge.column_value
         and LOT.FAL_LOT_ID = iFalLotId;
  begin
    for tplSubcontractPositionDetail in crSubcontractPositionDetail loop
      UpdateSubcontractDelay(iStartDate                => iStartDate
                           , iCGaugeShowDelay          => tplSubcontractPositionDetail.C_GAUGE_SHOW_DELAY
                           , iGapPosDelay              => tplSubcontractPositionDetail.GAP_POS_DELAY
                           , iPacThirdCdaId            => tplSubcontractPositionDetail.PAC_THIRD_CDA_ID
                           , iGcoGoodId                => tplSubcontractPositionDetail.GCO_GOOD_ID
                           , iStmStockId               => tplSubcontractPositionDetail.STM_STOCK_ID
                           , iStmStmStockId            => tplSubcontractPositionDetail.STM_STM_STOCK_ID
                           , iCAdminDomain             => tplSubcontractPositionDetail.C_ADMIN_DOMAIN
                           , iCGaugeType               => tplSubcontractPositionDetail.C_GAUGE_TYPE
                           , iGapTransfertProprietor   => tplSubcontractPositionDetail.GAP_TRANSFERT_PROPRIETOR
                           , iGcoComplDataId           => tplSubcontractPositionDetail.GCO_COMPL_DATA_ID
                           , iPdeBasisQuantity         => tplSubcontractPositionDetail.PDE_BASIS_QUANTITY
                           , iDocPositionDetailId      => tplSubcontractPositionDetail.DOC_POSITION_DETAIL_ID
                           , iPacSupplierPartnerId     => tplSubcontractPositionDetail.PAC_SUPPLIER_PARTNER_ID
                           , iFalScheduleStepId        => tplSubcontractPositionDetail.FAL_SCHEDULE_STEP_ID
                           , iFalLotId                 => iFalLotId
                           , iUpdatedDelay             => iUpdatedDelay
                            );
    end loop;
  end;

  /**
  * procedure UpdateSubcontractBatchDelay
  * Description
  *   Mise à jour des dates début/fin planifiée du lot de sous-traitance d'achat ainsi que son opération
  *
  * @created clg 14.09.2011
  * @lastUpdate vje 03.12.2012
  * @public
  */
  procedure UpdateSubcontractBatchDelay(
    iFalLotId             in FAL_LOT.FAL_LOT_ID%type
  , iFalScheduleStepId    in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  , iPacSupplierPartnerId in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  , iBasisDelay           in DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type
  , iInterDelay           in DOC_POSITION_DETAIL.PDE_INTERMEDIATE_DELAY%type
  , iFinalDelay           in DOC_POSITION_DETAIL.PDE_FINAL_DELAY%type
  )
  is
    opDuration number;
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Mise à jour opération
    opDuration  :=
      FAL_SCHEDULE_FUNCTIONS.GetDuration(aFAL_FACTORY_FLOOR_ID      => null
                                       , aPAC_SUPPLIER_PARTNER_ID   => iPacSupplierPartnerId
                                       , aPAC_CUSTOM_PARTNER_ID     => null
                                       , aPAC_DEPARTMENT_ID         => null
                                       , aHRM_PERSON_ID             => null
                                       , aCalendarID                => null
                                       , aBeginDate                 => iBasisDelay
                                       , aEndDate                   => iFinalDelay
                                        );
    FWK_I_MGT_ENTITY.new(FWK_TYP_FAL_ENTITY.gcFalTaskLink, ltCRUD_DEF, true, iFalScheduleStepId, null, 'FAL_SCHEDULE_STEP_ID');
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TAL_BEGIN_PLAN_DATE', iBasisDelay);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TAL_END_PLAN_DATE', iFinalDelay);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TAL_TASK_MANUF_TIME', opDuration);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCS_PLAN_RATE', opDuration);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCS_PLAN_PROP', 0);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    -- Mise à jour lot de fabrication
    FWK_I_MGT_ENTITY.new(FWK_TYP_FAL_ENTITY.gcFalLot, ltCRUD_DEF, true, iFalLotId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'LOT_PLAN_BEGIN_DTE', iBasisDelay);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'LOT_PLAN_END_DTE', iFinalDelay);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'LOT_PLAN_LEAD_TIME', opDuration);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    -- Mise à jour du délai composant
    FAL_PLANIF.MAJ_LiensComposantsLot(iFalLotId, iFinalDelay);
    -- Mise à jour du réseau besoin/appro
    FAL_NETWORK.MiseAJourReseaux(iFalLotId, FAL_NETWORK.ncPlannificationLot, '');
  end UpdateSubcontractBatchDelay;

  /**
  * procedure UpdateBatchPropDelay
  * Description
  *   Update subcontracting batch proposition (POAST) according to subcontracting delay
  *
  * @created vje 23.03.2015
  * @lastUpdate
  * @public
  */
  procedure UpdateBatchPropDelay(
    iFalLotPropID in FAL_LOT_PROP.FAL_LOT_PROP_ID%type
  , iStartDate    in FAL_LOT_PROP.LOT_PLAN_BEGIN_DTE%type default null
  , iEndDate      in FAL_LOT_PROP.LOT_PLAN_END_DTE%type default null
  , iGcoGoodID    in GCO_GOOD.GCO_GOOD_ID%type
  , iQuantity     in FAL_LOT_PROP.LOT_TOTAL_QTY%type
  )
  is
    lvBasisDelay           varchar2(10);
    lvInterDelay           varchar2(10);
    lvFinalDelay           varchar2(10);
    ldBasisDelay           DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type;
    ldInterDelay           DOC_POSITION_DETAIL.PDE_INTERMEDIATE_DELAY%type;
    ldFinalDelay           DOC_POSITION_DETAIL.PDE_FINAL_DELAY%type;
    opDuration             number;
    ltCRUD_DEF             FWK_I_TYP_DEFINITION.t_crud_def;
    lnComplDataID          GCO_COMPL_DATA_SUBCONTRACT.GCO_COMPL_DATA_SUBCONTRACT_ID%type;
    lvDicFabConditionID    GCO_COMPL_DATA_SUBCONTRACT.DIC_FAB_CONDITION_ID%type;
    lnPacSupplierParnterID PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type;
    lnGcoBindedServiceID   GCO_COMPL_DATA_SUBCONTRACT.GCO_GCO_GOOD_ID%type;
    lnFalTaskLinkPropID    FAL_TASK_LINK_PROP.FAL_TASK_LINK_PROP_ID%type;
    lnForward              number                                                          := 1;
    lvUpdateDelay          varchar2(10)                                                    := 'BASIS';
  begin
    lvBasisDelay   := null;
    lvInterDelay   := null;
    lvFinalDelay   := null;
    ldBasisDelay   := iStartDate;
    ldInterDelay   := iEndDate;
    ldFinalDelay   := iEndDate;

    -- Retrieve batch proposition subcontractor and subcontracting condition from unique subcontracting operation
    select LOP.DIC_FAB_CONDITION_ID
         , TAL.FAL_TASK_LINK_PROP_ID
         , TAL.PAC_SUPPLIER_PARTNER_ID
      into lvDicFabConditionID
         , lnFalTaskLinkPropID
         , lnPacSupplierParnterID
      from FAL_LOT_PROP LOP
         , FAL_TASK_LINK_PROP TAL
     where LOP.FAL_LOT_PROP_ID = iFalLotPropId
       and TAL.FAL_LOT_PROP_ID = LOP.FAL_LOT_PROP_ID;

    -- Retrieve all complementary subcontract information requiered to calculate delays
    lnComplDataID  :=
      FAL_LIB_SUBCONTRACTP.GetDefaultComplDataInfo(iDateValidity            => nvl(iEndDate, iStartDate)
                                                 , iGcoGoodID               => iGcoGoodID
                                                 , ioDicFabConditionID      => lvDicFabConditionID
                                                 , ioPacSupplierPartnerID   => lnPacSupplierParnterID
                                                  );
    if ldFinalDelay is not null then
      lnForward      := 0;
      lvUpdateDelay  := 'FINAL';
    end if;

    -- Calculate intermediate and basis delays according to final delay
    DOC_POSITION_DETAIL_FUNCTIONS.GetPDEDelay(aShowDelay             => 1   -- Day management delay
                                            , aPosDelay              => null   -- Unused with aShowDelay = 1
                                            , aUpdatedDelay          => lvUpdateDelay   -- Kind of delay referenced
                                            , aForward               => lnForward   -- Forward calculation
                                            , aThirdID               => lnPacSupplierParnterID   -- default subcontracting partner
                                            , aGoodID                => iGcoGoodID   -- Manufacturing good
                                            , aStockID               => null   -- Unused in subcontracting domain
                                            , aTargetStockID         => null   -- Unused in subcontracting domain
                                            , aAdminDomain           => DOC_POSITION_DETAIL_FUNCTIONS.cAdminDomainSubContract
                                            , aGaugeType             => 2   -- "Appro" type
                                            , aTransfertProprietor   => 0   -- Unused in subcontracting domain
                                            , aBasisDelayMW          => lvBasisDelay
                                            , aInterDelayMW          => lvInterDelay
                                            , aFinalDelayMW          => lvFinalDelay
                                            , aBasisDelay            => ldBasisDelay
                                            , aInterDelay            => ldInterDelay
                                            , aFinalDelay            => ldFinalDelay
                                            , iComplDataId           => lnComplDataID
                                            , iQuantity              => iQuantity
                                            , iScheduleStepId        => lnFalTaskLinkPropID   -- Unused in subcontracting domain
                                             );
    -- Update subcontracting batch manufacture proposition (POAST) begin/end plan according to subcontracting delay
    UpdateBatchPropPlan(iFalLotPropId           => iFalLotPropId
                      , iFalTaskLinkPropId      => lnFalTaskLinkPropID
                      , iPacSupplierPartnerId   => lnPacSupplierParnterID
                      , iBasisDelay             => ldBasisDelay
                      , iInterDelay             => ldInterDelay
                      , iFinalDelay             => ldFinalDelay
                       );
  end UpdateBatchPropDelay;

  /**
  * procedure UpdateBatchPropPlan
  * Description
  *   Update subcontracting batch manufacture proposition (POAST) begin/end plan according to subcontracting delay
  *
  * @created vje 23.03.2015
  * @lastUpdate
  * @public
  */
  procedure UpdateBatchPropPlan(
    iFalLotPropId         in FAL_LOT_PROP.FAL_LOT_PROP_ID%type
  , iFalTaskLinkPropId    in FAL_TASK_LINK_PROP.FAL_TASK_LINK_PROP_ID%type
  , iPacSupplierPartnerId in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  , iBasisDelay           in DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type
  , iInterDelay           in DOC_POSITION_DETAIL.PDE_INTERMEDIATE_DELAY%type
  , iFinalDelay           in DOC_POSITION_DETAIL.PDE_FINAL_DELAY%type
  )
  is
    lopDuration number;
    ltCRUD_DEF  FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Update unique subcontracting operation proposition
    lopDuration  :=
      FAL_SCHEDULE_FUNCTIONS.GetDuration(aFAL_FACTORY_FLOOR_ID      => null
                                       , aPAC_SUPPLIER_PARTNER_ID   => iPacSupplierPartnerId
                                       , aPAC_CUSTOM_PARTNER_ID     => null
                                       , aPAC_DEPARTMENT_ID         => null
                                       , aHRM_PERSON_ID             => null
                                       , aCalendarID                => null
                                       , aBeginDate                 => iBasisDelay
                                       , aEndDate                   => iFinalDelay
                                        );
    FWK_I_MGT_ENTITY.new(FWK_TYP_FAL_ENTITY.gcFalTaskLinkProp, ltCRUD_DEF, true, iFalTaskLinkPropId, null, 'FAL_TASK_LINK_PROP_ID');
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TAL_BEGIN_PLAN_DATE', iBasisDelay);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TAL_END_PLAN_DATE', iFinalDelay);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TAL_TASK_MANUF_TIME', lopDuration);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCS_PLAN_RATE', lopDuration);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCS_PLAN_PROP', 0);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    -- Update subcontracting batch manufacture proposition
    FWK_I_MGT_ENTITY.new(FWK_TYP_FAL_ENTITY.gcFalLotProp, ltCRUD_DEF, true, iFalLotPropId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'LOT_PLAN_BEGIN_DTE', iBasisDelay);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'LOT_PLAN_END_DTE', iFinalDelay);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'LOT_PLAN_LEAD_TIME', lopDuration);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    -- Mise à jour du délai composant
    FAL_PLANIF.MAJ_LiensComposantsProp(iFalLotPropId, iFinalDelay);
    -- Mise à jour du réseau besoin/appro
    FAL_NETWORK.MiseAJourReseaux(iFalLotPropId, FAL_NETWORK.ncPlanificationLotProp, '');
  end UpdateBatchPropPlan;
end FAL_PRC_SUBCONTRACTP;
