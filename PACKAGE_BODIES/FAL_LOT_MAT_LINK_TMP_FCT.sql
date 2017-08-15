--------------------------------------------------------
--  DDL for Package Body FAL_LOT_MAT_LINK_TMP_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LOT_MAT_LINK_TMP_FCT" 
is
  /**
  * procedure : ExistsTmpComponents
  * Description : Indique l'existance ou non de composants FAL_LOT_MAT_LINK_TMP
  *               pour la session en cours
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param     aLOM_SESSION    Session oracle
  */
  procedure ExistsTmpComponents(aLOM_SESSION FAL_LOT_MAT_LINK_TMP.LOM_SESSION%type, aNbComponents in out integer)
  is
  begin
    select count(*)
      into aNbComponents
      from FAL_LOT_MAT_LINK_TMP
     where LOM_SESSION = aLOM_SESSION;
  exception
    when others then
      aNbComponents  := 0;
  end;

  /**
  * function : ExistsTmpComponents
  * Description : Indique l'existance ou non de composants FAL_LOT_MAT_LINK_TMP
  *               pour la session en cours et le lot passé en paramètre
  *
  * @created CLG
  * @lastUpdate
  * @public
  * @param   aFalLotId              ID de lot
  * @param   aSessionId             ID unique de Session Oracle
  */
  function ExistsTmpComponents(aFalLotId fal_lot.fal_lot_id%type, aSessionId fal_lot_mat_link_tmp.lom_session%type)
    return boolean
  is
    cntCompo number;
  begin
    select count(*)
      into cntCompo
      from FAL_LOT_MAT_LINK_TMP
     where FAL_LOT_ID = aFalLotId
       and LOM_SESSION = aSessionId;

    return(nvl(cntCompo, 0) > 0);
  exception
    when others then
      return false;
  end;

  /**
  * Description
  *   Création des composants par duplication des composants d'un lot donné
  */
  procedure CreateComponents(
    aFalLotId                     FAL_LOT.FAL_LOT_ID%type default null
  , aDocumentId                   DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null
  , aPositionId                   DOC_POSITION.DOC_POSITION_ID%type default null
  , aFalLotMaterialLinkId         FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type default null
  , aSessionId                    FAL_LOT_MAT_LINK_TMP.LOM_SESSION%type default null
  , aContext                      integer default 0
  , aOpSeqFrom                    number default null
  , aOpSeqTo                      number default null
  , aComponentWithNeed            integer default null
  , aBalanceNeed                  integer default null
  , aComponentSeqFrom             number default null
  , aComponentSeqTo               number default null
  , aStepNumber                   number default null
  , aStepNumberNextOp             number default null
  , aBalanceQty                   FAL_TASK_LINK.TAL_DUE_QTY%type default null
  , aCaseReleaseCode              integer default 0
  , aGcoGoodId                    number default null
  , aFalJobProgramId              number default null
  , aCPriority                    number default null
  , aDocRecordId                  number default null
  , aPriorityDate                 date default null
  , aReceptionQty                 number default null
  , aQtyToSwitch                  number default 0
  , ReceptionType                 integer default 1   -- 1 = FAL_BATCH_FUNCTIONS.rtFinishedProduct
  , aDisplayAllComponentsDispo    integer default 0
  , aQtySup                       number default 0
  , iStmStmStockId             in number default 0
  , iStmStmLocationId          in number default 0
  )
  is
    vInsertQuery varchar2(32000);
    testjfr      integer;
    lSupplierId  STM_STOCK.PAC_SUPPLIER_PARTNER_ID%type;
    lDocumentId  DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    lPositionId  DOC_POSITION.DOC_POSITION_ID%type;
  begin
    vInsertQuery  :=
      ' insert into FAL_LOT_MAT_LINK_TMP ' ||
      '    (FAL_LOT_MAT_LINK_TMP_ID ' ||
      '   , FAL_LOT_MATERIAL_LINK_ID ' ||
      '   , C_CHRONOLOGY_TYPE ' ||
      '   , C_KIND_COM ' ||
      '   , C_TYPE_COM ' ||
      '   , GCO_GOOD_ID ' ||
      '   , STM_STOCK_ID ' ||
      '   , STM_LOCATION_ID ' ||
      '   , C_DISCHARGE_COM ' ||
      '   , FAL_LOT_ID ' ||
      '   , DOC_DOCUMENT_ID ' ||
      '   , DOC_POSITION_ID ' ||
      '   , GCO_GCO_GOOD_ID ' ||
      '   , PC_YEAR_WEEK_ID ' ||
      '   , LOM_SESSION ' ||
      '   , LOM_SELECTED ' ||
      '   , LOM_SEQ ' ||
      '   , LOM_SUBSTITUT ' ||
      '   , LOM_STOCK_MANAGEMENT ' ||
      '   , LOM_SECONDARY_REF ' ||
      '   , LOM_SHORT_DESCR ' ||
      '   , LOM_LONG_DESCR ' ||
      '   , LOM_FREE_DECR ' ||
      '   , LOM_POS ' ||
      '   , LOM_FRE_NUM ' ||
      '   , LOM_TEXT ' ||
      '   , LOM_FREE_TEXT ' ||
      '   , LOM_UTIL_COEF ' ||
      '   , LOM_ADJUSTED_QTY_RECEIPT ' ||
      '   , LOM_CONSUMPTION_QTY ' ||
      '   , LOM_REJECTED_QTY ' ||
      '   , LOM_BACK_QTY ' ||
      '   , LOM_PT_REJECT_QTY ' ||
      '   , LOM_CPT_TRASH_QTY ' ||
      '   , LOM_CPT_RECOVER_QTY ' ||
      '   , LOM_CPT_REJECT_QTY ' ||
      '   , LOM_EXIT_RECEIPT ' ||
      '   , LOM_MAX_RECEIPT_QTY ' ||
      '   , LOM_MAX_FACT_QTY ' ||
      '   , LOM_AVAILABLE_QTY ' ||
      '   , LOM_INTERVAL ' ||
      '   , LOM_MARK_TOPO ' ||
      '   , LOM_WEIGHING ' ||
      '   , LOM_WEIGHING_MANDATORY ' ||
      '   , LOM_NEED_DATE ' ||
      '   , LOM_PRICE ' ||
      '   , LOM_MISSING ' ||
      '   , LOM_TASK_SEQ ' ||
      '   , LOM_REF_QTY ' ||
      '   , LOM_INCREASE_COST ' ||
      '   , LOM_IS_FULL_TRACABILITY ' ||
      '   , LOM_PDT_WITH_PEREMP_DATE ' ||
      '   , LOM_BOM_REQ_QTY ' ||
      '   , LOM_NEED_QTY' ||
      '   , LOM_ADJUSTED_QTY ' ||
      '   , LOM_FULL_REQ_QTY ' ||
      '   , A_DATECRE ' ||
      '   , A_IDCRE ' ||
      '   , LOM_QTY_REFERENCE_LOSS ' ||
      '   , LOM_FIXED_QUANTITY_WASTE ' ||
      '   , LOM_PERCENT_WASTE ' ||
      '   ) ' ||
      '   select GetNewId ' ||
      '        , LOM.FAL_LOT_MATERIAL_LINK_ID ' ||
      '        , (select C_CHRONOLOGY_TYPE ' ||
      '             from GCO_CHARACTERIZATION ' ||
      '            where GCO_GOOD_ID (+) = LOM.GCO_GOOD_ID ' ||
      '              and C_CHARACT_TYPE = ''5'') C_CHRONOLOGY_TYPE ' ||
      '        , LOM.C_KIND_COM ' ||
      '        , LOM.C_TYPE_COM ' ||
      '        , LOM.GCO_GOOD_ID ';

    if not aContext in(FAL_COMPONENT_LINK_FUNCTIONS.ctxtSubContractOTransfer) then
      vInsertQuery  :=
        vInsertQuery ||
        '        , (case ' ||
        '             when NVL(:aStmStmStockId, 0) = 0 then decode(LOM.C_DISCHARGE_COM,''6'', STM_I_LIB_STOCK.getSubCStockID(TAL.PAC_SUPPLIER_PARTNER_ID), LOM.STM_STOCK_ID) ' ||
        '             else :aStmStmStockId ' ||
        '          end) ' ||
        '        , (case ' ||
        '             when NVL(:aStmStmLocationId, 0) = 0 then decode(LOM.C_DISCHARGE_COM,''6'', STM_I_LIB_STOCK.GetDefaultLocation(STM_I_LIB_STOCK.getSubCStockID(TAL.PAC_SUPPLIER_PARTNER_ID)), LOM.STM_LOCATION_ID) ' ||
        '             else :aStmStmLocationId ' ||
        '          end) ';
    else
      vInsertQuery  :=
        vInsertQuery ||
        '        , (case ' ||
        '             when NVL(:aStmStmStockId, 0) = 0 then LOM.STM_STOCK_ID ' ||
        '             else :aStmStmStockId ' ||
        '          end) ' ||
        '        , (case ' ||
        '             when NVL(:aStmStmLocationId, 0) = 0 then  LOM.STM_LOCATION_ID ' ||
        '             else :aStmStmLocationId ' ||
        '          end) ';
    end if;

    vInsertQuery  :=
      vInsertQuery ||
      '        , LOM.C_DISCHARGE_COM ' ||
      '        , LOM.FAL_LOT_ID ' ||
      '        , :iDocumentId ' ||
      '        , :iPositionId ' ||
      '        , LOM.GCO_GCO_GOOD_ID ' ||
      '        , LOM.PC_YEAR_WEEK_ID ' ||
      '        , :aSessionId ' ||
      '        , 0 ' ||   -- LOM_SELECTED
      '        , LOM.LOM_SEQ ' ||
      '        , LOM.LOM_SUBSTITUT ' ||
      '        , LOM.LOM_STOCK_MANAGEMENT ' ||
      '        , LOM.LOM_SECONDARY_REF ' ||
      '        , LOM.LOM_SHORT_DESCR ' ||
      '        , LOM.LOM_LONG_DESCR ' ||
      '        , LOM.LOM_FREE_DECR ' ||
      '        , LOM.LOM_POS ' ||
      '        , LOM.LOM_FRE_NUM ' ||
      '        , LOM.LOM_TEXT ' ||
      '        , LOM.LOM_FREE_TEXT ' ||
      '        , LOM.LOM_UTIL_COEF ' ||
      '        , LOM.LOM_ADJUSTED_QTY_RECEIPT ';

    if (        (aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtManufacturingReceipt)
           and (ReceptionType <> FAL_BATCH_FUNCTIONS.rtBatchAssembly)
        or (aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtDerivativeReturn)
       ) then
      vInsertQuery  := vInsertQuery || ' , 0 LOM_CONSUMPTION_QTY ';
    else
      vInsertQuery  := vInsertQuery || ' , LOM.LOM_CONSUMPTION_QTY ';
    end if;

    vInsertQuery  :=
      vInsertQuery ||
      '        , LOM.LOM_REJECTED_QTY ' ||
      '        , LOM.LOM_BACK_QTY ' ||
      '        , LOM.LOM_PT_REJECT_QTY ' ||
      '        , LOM.LOM_CPT_TRASH_QTY ' ||
      '        , LOM.LOM_CPT_RECOVER_QTY ' ||
      '        , LOM.LOM_CPT_REJECT_QTY ' ||
      '        , LOM.LOM_EXIT_RECEIPT ' ||
      '        , LOM.LOM_MAX_RECEIPT_QTY ' ||
      '        , LOM.LOM_MAX_FACT_QTY ' ||
      '        , LOM.LOM_AVAILABLE_QTY ' ||
      '        , LOM.LOM_INTERVAL ' ||
      '        , LOM.LOM_MARK_TOPO ' ||
      '        , LOM.LOM_WEIGHING ' ||
      '        , LOM.LOM_WEIGHING_MANDATORY ';

    -- Affectation de composants de stocks vers des lots de fabrication
    if    aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtStockToBatchAllocation
       or aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchToStockAllocation then
      vInsertQuery  :=
        vInsertQuery ||
        ' , Case ' ||
        '     when LOM.LOM_NEED_DATE IS NOT NULL' ||
        '       and LOT.LOT_PLAN_END_DTE IS NOT NULL ' ||
        '       and LOM.LOM_NEED_DATE > LOT.LOT_PLAN_END_DTE then' ||
        '       TRUNC(LOT.LOT_PLAN_END_DTE)' ||
        '     when LOM.LOM_NEED_DATE IS NOT NULL' ||
        '       and LOT.LOT_PLAN_END_DTE IS NOT NULL ' ||
        '       and LOM.LOM_NEED_DATE < LOT.LOT_PLAN_END_DTE then' ||
        '       TRUNC(LOM.LOM_NEED_DATE)' ||
        '     else TRUNC(NVL(LOM.LOM_NEED_DATE, LOT.LOT_PLAN_END_DTE))' ||
        '     end LOM_NEED_DATE';
    else
      vInsertQuery  := vInsertQuery || '        , LOM.LOM_NEED_DATE ';
    end if;

    -- Prix pour le suivi d'avancement, la sortie de composants, l'affectation de composants et la réception.
    if    aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtComponentOutput
       or aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtSubContractPTransfer
       or aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtSubContractOTransfer
       or aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtProductionAdvance
       or aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtStockToBatchAllocation
       or aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtManufacturingReceipt
       or aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBarCodeComponentOutput
       or aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtComponentReplacingIn
       or aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtComponentReplacingOut
       or aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchLaunch
       or aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtDerivativeReturn then
      vInsertQuery  := vInsertQuery || '        , GCO_FUNCTIONS.GetCostPriceWithManagementMode(LOM.GCO_GOOD_ID)';
    -- Par defaut, celui du composant
    else
      vInsertQuery  := vInsertQuery || '        , LOM.LOM_PRICE ';
    end if;

    vInsertQuery  :=
      vInsertQuery ||
      '        , LOM.LOM_MISSING ' ||
      '        , LOM.LOM_TASK_SEQ ' ||
      '        , LOM.LOM_REF_QTY ' ||
      '        , LOM.LOM_INCREASE_COST ' ||
      '        , FAL_TOOLS.prcIsFullTracability(LOM.GCO_GOOD_ID) ' ||
      '        , FAL_TOOLS.ProductHasPeremptionDate(LOM.GCO_GOOD_ID) ';

    -- Quantité besoin réception et Quantité sup/inf
    if (        (aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtManufacturingReceipt)
           and (ReceptionType <> FAL_BATCH_FUNCTIONS.rtBatchAssembly)
        or (aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtDerivativeReturn)
       ) then
      vInsertQuery  :=
        vInsertQuery ||
        '        , FAL_LOT_MAT_LINK_TMP_FCT.GetLomBomReqQtyOnRecept(:aReceptionQty ' ||
        '                                                               , LOM.LOM_UTIL_COEF ' ||
        '                                                               , LOM.LOM_FULL_REQ_QTY ' ||
        '                                                               , LOM.LOM_REF_QTY ' ||
        '                                                               , LOM.GCO_GOOD_ID ' ||
        '                                                               , LOM.FAL_LOT_ID ' ||
        '                                                               , LOM.LOM_EXIT_RECEIPT) LOM_BOM_REQ_QTY ' ||
        '        , greatest(0, FAL_TOOLS.ArrondiSuperieur( (LOM.LOM_UTIL_COEF * :aReceptionQty / LOM.LOM_REF_QTY), LOM.GCO_GOOD_ID)) LOM_NEED_QTY ' ||
        '        , FAL_LOT_MAT_LINK_TMP_FCT.GetLomAdjustedQtyOnRecept(:aReceptionQty ' ||
        '                                                                 , LOM.LOM_MAX_RECEIPT_QTY ' ||
        '                                                                 , LOM.LOM_ADJUSTED_QTY ' ||
        '                                                                 , LOM.LOM_ADJUSTED_QTY_RECEIPT ' ||
        '                                                                 , LOM.LOM_UTIL_COEF ' ||
        '                                                                 , LOM.LOM_REF_QTY ' ||
        '                                                                 , LOM.GCO_GOOD_ID) LOM_ADJUSTED_QTY ' ||

        -- Qté besoin totale (LOM_FULL_REQ_QTY = newLOM_NEED_QTY + newLOM_ADJUSTED_QTY)
        '        , FAL_LOT_MAT_LINK_TMP_FCT.GetLomFullReqQtyOnRecept(:aReceptionQty ' ||
        '                                                                 , LOM.LOM_MAX_RECEIPT_QTY ' ||
        '                                                                 , LOM.LOM_ADJUSTED_QTY ' ||
        '                                                                 , LOM.LOM_ADJUSTED_QTY_RECEIPT ' ||
        '                                                                 , LOM.LOM_UTIL_COEF ' ||
        '                                                                 , LOM.LOM_REF_QTY ' ||
        '                                                                 , LOM.GCO_GOOD_ID ' ||
        '                                                                 , LOM.LOM_FULL_REQ_QTY ' ||
        '                                                                 , LOM.FAL_LOT_ID ' ||
        '                                                                 , LOM.LOM_EXIT_RECEIPT) LOM_FULL_REQ_QTY ';
    elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchSplitting then
      vInsertQuery  :=
        vInsertQuery ||
        '          , LOM.LOM_BOM_REQ_QTY ' ||
        '          , FAL_BREAKUP_LOT.GetLomNeedQty(LOM.LOM_REF_QTY ' ||
        '                                         , LOM.LOM_UTIL_COEF ' ||
        '                                         , LOM.GCO_GOOD_ID ' ||
        '                                         , :aQteToSwitch) LOM_NEED_QTY ' ||
        '          , FAL_BREAKUP_LOT.GetLomAdjustedQty(LOM.LOM_REF_QTY ' ||
        '                                          , LOM.LOM_UTIL_COEF ' ||
        '                                          , LOM.GCO_GOOD_ID ' ||
        '                                          , :aQteToSwitch ' ||
        '                                          , LOM.LOM_ADJUSTED_QTY ' ||
        '                                          , LOM.LOM_ADJUSTED_QTY_RECEIPT) LOM_ADJUSTED_QTY ' ||
        '          , FAL_BREAKUP_LOT.GetLomFullReqQty(LOM.LOM_REF_QTY ' ||
        '                                           , LOM.LOM_UTIL_COEF ' ||
        '                                           , LOM.GCO_GOOD_ID ' ||
        '                                           , :aQteToSwitch ' ||
        '                                           , LOM.LOM_ADJUSTED_QTY ' ||
        '                                           , LOM.LOM_ADJUSTED_QTY_RECEIPT) LOM_FULL_REQ_QTY ';
    elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBarCodeComponentOutput then
      vInsertQuery  :=
        vInsertQuery ||
        '          , LOM.LOM_BOM_REQ_QTY ' ||
        '          , LOM.LOM_NEED_QTY ' ||
        '          , LOM.LOM_ADJUSTED_QTY + :aQtySup ' ||
        '          , LOM.LOM_FULL_REQ_QTY + :aQtySup ';
    elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtSubCOComponentOutput then
      vInsertQuery  :=
        vInsertQuery ||
        '          , LOM.LOM_BOM_REQ_QTY' ||
        '          , (select sum(PDE.PDE_FINAL_QUANTITY_SU + ' ||
        '                        ACS_FUNCTION.RoundNear(PDE.PDE_BALANCE_QUANTITY_PARENT * POS.POS_CONVERT_FACTOR, ' ||
        '                              1 / power(10, GCO_LIB_FUNCTIONS.GetNumberOfDecimal(POS.GCO_GOOD_ID) ), 0)) ' ||
        '               from DOC_POSITION_DETAIL PDE where DOC_POSITION_ID = POS.DOC_POSITION_ID)' ||
        '            * LOM.LOM_UTIL_COEF / LOM.LOM_REF_QTY + LOM.LOM_ADJUSTED_QTY - LOM.LOM_ADJUSTED_QTY_RECEIPT LOM_NEED_QTY' ||
        '          , LOM.LOM_ADJUSTED_QTY' ||
        '          , LOM.LOM_FULL_REQ_QTY';
    else
      vInsertQuery  :=
        vInsertQuery ||
        '          , LOM.LOM_BOM_REQ_QTY ' ||
        '          , LOM.LOM_NEED_QTY ' ||
        '          , LOM.LOM_ADJUSTED_QTY ' ||
        '          , LOM.LOM_FULL_REQ_QTY ';
    end if;

    vInsertQuery  :=
      vInsertQuery ||
      '        , sysdate ' ||
      '        , PCS.PC_INIT_SESSION.GetUserIni ' ||
      '        , LOM_QTY_REFERENCE_LOSS ' ||
      '        , LOM_FIXED_QUANTITY_WASTE ' ||
      '        , LOM_PERCENT_WASTE ' ||
      '     from FAL_LOT_MATERIAL_LINK LOM, FAL_TASK_LINK TAL ';

    -- contruction condition WHERE

    -- Affectation de composants de stocks vers des lots de fabrication
    if aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtStockToBatchAllocation then
      vInsertQuery  :=
        vInsertQuery ||
        '      , FAL_LOT LOT ' ||
        '      , FAL_LOT1 LOT1 ' ||
        '  where LOM.GCO_GOOD_ID = :aGcoGoodId ' ||
        '    and NVL(LOT.C_FAB_TYPE, ''0'')  <> ''4'' ' ||
        '    and LOM.C_KIND_COM = ''1'' ' ||
        '    and LOM.C_TYPE_COM = ''1'' ' ||
        '    and NVL(LOM.LOM_NEED_QTY,0) > 0 ' ||
        '    and LOM.FAL_LOT_ID = TAL.FAL_LOT_ID(+) ' ||
        '    and LOM.LOM_TASK_SEQ = TAL.SCS_STEP_NUMBER(+) ' ||
        '    and LOM.FAL_LOT_ID = LOT.FAL_LOT_ID ' ||
        '    and LOT.FAL_LOT_ID = LOT1.FAL_LOT_ID ' ||
        '    and LOT1.LT1_ORACLE_SESSION = :aSessionId ' ||
        '    and LOT1.C_LOT_STATUS = ''2'' ' ||
        '    and (NVL(:aFAL_JOB_PROGRAM_ID,0) = 0 ' ||
        '         or LOT.FAL_JOB_PROGRAM_ID = :aFAL_JOB_PROGRAM_ID)' ||
        '    and (:aC_PRIORITY IS NULL ' ||
        '         or LOT.C_PRIORITY <= :aC_PRIORITY) ' ||
        '    and (NVL(:aDOC_RECORD_ID,0) = 0 ' ||
        '         or LOT.DOC_RECORD_ID = :aDOC_RECORD_ID)';
    -- Affectation de composants de stocks sous-traitants vers des lots de fabrication
    elsif    aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtSubContractOTransfer
          or aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtSubContractOReturn then
      vInsertQuery  :=
        vInsertQuery ||
        '      , FAL_LOT LOT ' ||
        '      , DOC_POSITION POS ' ||
        '  where (POS.DOC_DOCUMENT_ID = :aDocumentId or POS.DOC_POSITION_ID = :aPositionId) ' ||
        '    and TAL.FAL_SCHEDULE_STEP_ID = POS.FAL_SCHEDULE_STEP_ID ' ||
        '    and NVL(LOT.C_FAB_TYPE, ''0'')  <> ''4'' ' ||
        '    and POS.C_GAUGE_TYPE_POS = ''1'' ' ||
        '    and LOM.C_KIND_COM = ''1'' ' ||
        '    and LOM.C_TYPE_COM = ''1'' ' ||
        '    and LOM.C_DISCHARGE_COM = ''6'' ' ||
        '    and NVL(LOM.LOM_NEED_QTY,0) > 0 ' ||
        '    and LOM.FAL_LOT_ID = TAL.FAL_LOT_ID(+) ' ||
        '    and LOM.LOM_TASK_SEQ = TAL.SCS_STEP_NUMBER(+) ' ||
        '    and LOM.FAL_LOT_ID = TAL.FAL_LOT_ID ' ||
        '    and LOT.FAL_LOT_ID = TAL.FAL_LOT_ID ';
    -- Affectation de composants de stocks sous-traitants vers des lots de fabrication
    elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtSubCOComponentOutput then
      vInsertQuery  :=
        vInsertQuery ||
        '      , FAL_LOT LOT ' ||
        '      , DOC_POSITION POS ' ||
        '  where (POS.DOC_DOCUMENT_ID = :aDocumentId or POS.DOC_POSITION_ID = :aPositionId) ' ||
        '    and TAL.FAL_SCHEDULE_STEP_ID = POS.FAL_SCHEDULE_STEP_ID ' ||
        '    and NVL(LOT.C_FAB_TYPE, ''0'')  <> ''4'' ' ||
        '    and POS.C_GAUGE_TYPE_POS = ''1'' ' ||
        '    and LOM.C_KIND_COM = ''1'' ' ||
        '    and LOM.C_TYPE_COM = ''1'' ' ||
        '    and LOM.C_DISCHARGE_COM = ''6'' ' ||
        '    and NVL(LOM.LOM_NEED_QTY,0) > 0 ' ||
        '    and LOM.FAL_LOT_ID = TAL.FAL_LOT_ID(+) ' ||
        '    and LOM.LOM_TASK_SEQ = TAL.SCS_STEP_NUMBER(+) ' ||
        '    and LOM.FAL_LOT_ID = TAL.FAL_LOT_ID ' ||
        '    and LOT.FAL_LOT_ID = TAL.FAL_LOT_ID ' ||
        '    and LOM.FAL_LOT_MATERIAL_LINK_ID not in (select FIN.FAL_LOT_MATERIAL_LINK_ID from FAL_FACTORY_IN FIN where FIN.DOC_DOCUMENT_ID in (select column_value from table(DOC_I_LIB_DOCUMENT.getPosDocParentIdList(POS.DOC_POSITION_ID))))';
    elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchToStockAllocation then
      vInsertQuery  :=
        vInsertQuery ||
        '      , FAL_LOT LOT ' ||
        '      , FAL_LOT1 LOT1 ' ||
        '  where LOM.GCO_GOOD_ID = :aGcoGoodId ' ||
        '    and NVL(LOT.C_FAB_TYPE, ''0'') <> ''4'' ';
      lSupplierId   := STM_I_LIB_STOCK.getSubCPartnerID(iStockId => iStmStmStockId);

      if lSupplierId is null then
        vInsertQuery  := vInsertQuery || '    and LOM.FAL_LOT_ID = TAL.FAL_LOT_ID(+) ' || '    and LOM.LOM_TASK_SEQ = TAL.SCS_STEP_NUMBER(+) ';
      else
        vInsertQuery  :=
          vInsertQuery ||
          '    and LOM.FAL_LOT_ID = TAL.FAL_LOT_ID ' ||
          '    and LOM.LOM_TASK_SEQ = TAL.SCS_STEP_NUMBER ' ||
          '    and TAL.PAC_SUPPLIER_PARTNER_ID = ' ||
          lSupplierId;
      end if;

      vInsertQuery  :=
        vInsertQuery ||
        '    and LOM.FAL_LOT_ID = LOT.FAL_LOT_ID ' ||
        '    and LOT.FAL_LOT_ID = LOT1.FAL_LOT_ID ' ||
        '    and LOT1.LT1_ORACLE_SESSION = :aSessionId ' ||
        '    and LOM.C_KIND_COM = ''1'' ' ||
        '    and LOM.C_TYPE_COM = ''1'' ' ||
        '    and LOT.C_LOT_STATUS = ''2'' ' ||
        '    and (nvl(LOM.LOM_CONSUMPTION_QTY, 0) ' ||
        '            - nvl(LOM.LOM_REJECTED_QTY, 0) ' ||
        '            - nvl(LOM.LOM_BACK_QTY, 0) ' ||
        '            - nvl(LOM.LOM_CPT_RECOVER_QTY, 0) ' ||
        '            - nvl(LOM.LOM_CPT_REJECT_QTY, 0) ' ||
        '            - nvl(LOM.LOM_EXIT_RECEIPT, 0)) > 0 ' ||
        '    and (NVL(:aFAL_JOB_PROGRAM_ID, 0) = 0 or LOT.FAL_JOB_PROGRAM_ID = :aFAL_JOB_PROGRAM_ID) ' ||
        '    and (NVL(:aC_PRIORITY, 0) = 0 or LOT.C_PRIORITY <= :aC_PRIORITY) ' ||
        '    and (:aPriorityDate is null ' ||
        '         or (LOT.LOT_PLAN_END_DTE IS NOT NULL AND LOM.LOM_NEED_DATE IS NOT NULL ' ||
        '             AND LOT.LOT_PLAN_END_DTE > :aPriorityDate AND LOM.LOM_NEED_DATE > :aPriorityDate) ' ||
        '         or (LOT.LOT_PLAN_END_DTE IS NULL AND LOM.LOM_NEED_DATE IS NOT NULL ' ||
        '             AND LOM.LOM_NEED_DATE > :aPriorityDate) ' ||
        '         or (LOT.LOT_PLAN_END_DTE IS NOT NULL AND LOM.LOM_NEED_DATE IS NULL ' ||
        '             AND LOT.LOT_PLAN_END_DTE > :aPriorityDate)) ';
    elsif    aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtSubContractPTransfer
          or aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtSubContractPReturn then
      -- Recherche le document et la position liés au lot spécifié
      if (    aDocumentId is null
          and aPositionId is null) then
        FAL_LIB_SUBCONTRACTP.GetBatchOriginDocument(iFalLotId => aFalLotId, ioDocDocumentId => lDocumentId, ioDocPositionId => lPositionId);
      else
        lDocumentId  := aDocumentId;
        lPositionId  := aPositionId;
      end if;

      vInsertQuery  :=
        vInsertQuery ||
        '    where LOM.FAL_LOT_ID in (select POS.FAL_LOT_ID from DOC_POSITION POS where (POS.DOC_DOCUMENT_ID = :aDocumentId or POS.DOC_POSITION_ID = :aPositionId))  ' ||
        '    and LOM.FAL_LOT_ID = TAL.FAL_LOT_ID(+) ' ||
        '    and LOM.LOM_TASK_SEQ = TAL.SCS_STEP_NUMBER(+) ';
    else
      vInsertQuery  :=
        vInsertQuery ||
        '    where LOM.FAL_LOT_ID = :aFalLotId ' ||
        '    and LOM.FAL_LOT_ID = TAL.FAL_LOT_ID(+) ' ||
        '    and LOM.LOM_TASK_SEQ = TAL.SCS_STEP_NUMBER(+) ';
    end if;

    -- Clause where pour le suivi d'avancement ou la sortie de composants
    if    aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtComponentOutput
       or aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtSubContractPTransfer
       or aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtSubContractOTransfer
       or aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtProductionAdvance then
      vInsertQuery  :=
        vInsertQuery ||
        '     and (nvl(:aComponentSeqFrom, 0) = 0 or LOM.LOM_SEQ >= :aComponentSeqFrom) ' ||
        '     and (nvl(:aComponentSeqTo, 0) = 0 or LOM.LOM_SEQ <= :aComponentSeqTo) ' ||
        '     and FAL_COMPONENT_MVT_SORTIE.MustDoOutput(:aOpSeqFrom ' ||
        '                                             , :aOpSeqTo ' ||
        '                                             , :aComponentWithNeed ' ||
        '                                             , :aStepNumber ' ||
        '                                             , :aStepNumberNextOpe ' ||
        '                                             , :aBalanceQty ' ||
        '                                             , :aContext ' ||
        '                                             , LOM.C_DISCHARGE_COM ' ||
        '                                             , LOM.C_TYPE_COM ' ||
        '                                             , LOM.LOM_NEED_QTY ' ||
        '                                             , LOM.LOM_STOCK_MANAGEMENT ' ||
        '                                             , LOM.C_KIND_COM ' ||
        '                                             , LOM.LOM_TASK_SEQ) = 1 ';
    -- Clause Where pour la sortie de composants code barre
    -- ou le remplacement de composants
    elsif    aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBarCodeComponentOutput
          or aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtComponentReplacingIn
          or aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtComponentReplacingOut then
      vInsertQuery  := vInsertQuery || '     and LOM.FAL_LOT_MATERIAL_LINK_ID = :aFAL_LOT_MATERIAL_LINK_ID ';
    -- Clause where pour le lancement de lots de fabrication
    elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchLaunch then
      vInsertQuery  := vInsertQuery || '     and LOM.C_TYPE_COM = ''1'' ' || '     and LOM.LOM_STOCK_MANAGEMENT = ''1'' ' || '     and LOM.C_KIND_COM = ''1'' ';

      if aCaseReleaseCode = 1 then
        if aDisplayAllComponentsDispo = 0 then
          vInsertQuery  := vInsertQuery || ' and (LOM.C_DISCHARGE_COM = ''1'' or LOM.C_DISCHARGE_COM = ''5'' or LOM.C_DISCHARGE_COM = ''6'') ';
        end if;
      else
        -- Il ne faut pas permettre la sortie des composants qui doivent être pesés
        if PCS.PC_CONFIG.GetConfig('FAL_MVT_WEIGHING_MODE') = '2' then
          vInsertQuery  := vInsertQuery || ' and GCO_PRECIOUS_MAT_FUNCTIONS.IsProductWithPMatWithWeighing(LOM.GCO_GOOD_ID) <> 0 ';
        elsif PCS.PC_CONFIG.GetConfig('FAL_MVT_WEIGHING_MODE') = '3' then
          vInsertQuery  := vInsertQuery || ' and not (GCO_PRECIOUS_MAT_FUNCTIONS.IsProductWithPMatWithWeighing(LOM.GCO_GOOD_ID) = 1 ';
          vInsertQuery  := vInsertQuery || '      and LOM.LOM_WEIGHING_MANDATORY = 1) ';
        end if;
      end if;
    -- Clause where pour le retour de composants
    elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtComponentReturn then
      vInsertQuery  :=
        vInsertQuery ||
        ' and LOM.LOM_STOCK_MANAGEMENT = 1 ' ||
        ' and LOM.C_KIND_COM = ''1'' ' ||
        ' and ((nvl(LOM.LOM_CONSUMPTION_QTY,0) ' ||
        '       - (nvl(LOM.LOM_REJECTED_QTY,0) ' ||
        '            + nvl(LOM.LOM_BACK_QTY,0) ' ||
        '            + nvl(LOM.LOM_CPT_RECOVER_QTY,0) ' ||
        '            + nvl(LOM.LOM_CPT_REJECT_QTY,0) ' ||
        '            + nvl(LOM.LOM_EXIT_RECEIPT,0))) > 0) ' ||
        ' and (NVL(:aOpSeqFrom, 0) = 0 or (NVL(:aOpSeqFrom, 0) <> 0 and NVL(:aOpSeqFrom, 0) <= NVL(LOM.LOM_TASK_SEQ, 0))) ' ||
        ' and (NVL(:aOpSeqTo, 0) = 0 or (NVL(:aOpSeqTo, 0) <> 0 and NVL(LOM.LOM_TASK_SEQ, 0) <= NVL(:aOpSeqTo, 0))) ' ||
        ' and (nvl(:aComponentSeqFrom, 0) = 0 or LOM.LOM_SEQ >= :aComponentSeqFrom) ' ||
        ' and (nvl(:aComponentSeqTo, 0) = 0 or LOM.LOM_SEQ <= :aComponentSeqTo) ';
    -- Clause where pour le retour de composants STT
    elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtSubContractPReturn then
      vInsertQuery  :=
        vInsertQuery ||
        ' and LOM.LOM_STOCK_MANAGEMENT = 1 ' ||
        ' and LOM.C_KIND_COM = ''1'' ' ||
        ' and (NVL(:aOpSeqFrom, 0) = 0 or (NVL(:aOpSeqFrom, 0) <> 0 and NVL(:aOpSeqFrom, 0) <= NVL(LOM.LOM_TASK_SEQ, 0))) ' ||
        ' and (NVL(:aOpSeqTo, 0) = 0 or (NVL(:aOpSeqTo, 0) <> 0 and NVL(LOM.LOM_TASK_SEQ, 0) <= NVL(:aOpSeqTo, 0))) ' ||
        ' and (nvl(:aComponentSeqFrom, 0) = 0 or LOM.LOM_SEQ >= :aComponentSeqFrom) ' ||
        ' and (nvl(:aComponentSeqTo, 0) = 0 or LOM.LOM_SEQ <= :aComponentSeqTo) ';
    elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtSubContractOReturn then
      vInsertQuery  :=
        vInsertQuery ||
        ' and LOM.LOM_STOCK_MANAGEMENT = 1 ' ||
        ' and LOM.C_KIND_COM = ''1'' ' ||
        ' and LOM.C_DISCHARGE_COM = ''6'' ' ||
        ' and (NVL(:aOpSeqFrom, 0) = 0 or (NVL(:aOpSeqFrom, 0) <> 0 and NVL(:aOpSeqFrom, 0) <= NVL(LOM.LOM_TASK_SEQ, 0))) ' ||
        ' and (NVL(:aOpSeqTo, 0) = 0 or (NVL(:aOpSeqTo, 0) <> 0 and NVL(LOM.LOM_TASK_SEQ, 0) <= NVL(:aOpSeqTo, 0))) ' ||
        ' and (nvl(:aComponentSeqFrom, 0) = 0 or LOM.LOM_SEQ >= :aComponentSeqFrom) ' ||
        ' and (nvl(:aComponentSeqTo, 0) = 0 or LOM.LOM_SEQ <= :aComponentSeqTo) ';
    -- Clause where pour la réception
    elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtManufacturingReceipt then
      if ReceptionType = FAL_BATCH_FUNCTIONS.rtDismantling then
        -- En démontage, on ne prend pas les composants dérivés
        vInsertQuery  := vInsertQuery || ' and LOM.C_TYPE_COM = ''1'' ' || ' and LOM.C_KIND_COM = ''1'' ' || ' and LOM_STOCK_MANAGEMENT = 1 ';
      else
        vInsertQuery  :=
          vInsertQuery || ' and LOM.C_TYPE_COM = ''1'' ' || ' and (LOM.C_KIND_COM = ''2'' '
          || '      or (LOM.C_KIND_COM = ''1'' and LOM_STOCK_MANAGEMENT = 1)) ';
      end if;
    -- Clause where pour le solde du lot
    elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchBalance then
      vInsertQuery  :=
        vInsertQuery ||
        ' and LOM.FAL_LOT_MATERIAL_LINK_ID in (select FAL_LOT_MATERIAL_LINK_ID ' ||
        '                                        from FAL_FACTORY_IN ' ||
        '                                       where FAL_LOT_ID = :aFalLotId ' ||
        '                                         and nvl(IN_BALANCE, 0) > 0) ';
    -- Clause where pour l'éclatement du lot
    elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchSplitting then
--      vInsertQuery  := vInsertQuery || ' and LOM.C_TYPE_COM = ''1'' ' || ' and LOM.C_KIND_COM in (''2'', ''1'', ''4'', ''5'' ) ';
      vInsertQuery  := vInsertQuery || ' and LOM.C_TYPE_COM = ''1'' ';
    -- Clause pour les mouvements de dérivés
    elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtDerivativeReturn then
      vInsertQuery  := vInsertQuery || ' and LOM.C_TYPE_COM = ''1'' ' || ' and LOM.C_KIND_COM = ''2'' ';
    end if;

    -- Execution pour le suivi d'avancement ou la sortie de composants
    if    aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtComponentOutput
       or aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtProductionAdvance then
      execute immediate vInsertQuery
                  using iStmStmStockId
                      , iStmStmStockId
                      , iStmStmLocationId
                      , iStmStmLocationId
                      , aDocumentId
                      , aPositionId
                      , aSessionID
                      , aFalLotId
                      , aComponentSeqFrom
                      , aComponentSeqFrom
                      , aComponentSeqTo
                      , aComponentSeqTo
                      , aOpSeqFrom
                      , aOpSeqTo
                      , aComponentWithNeed
                      , aStepNumber
                      , aStepNumberNextOp
                      , aBalanceQty
                      , aContext;
    elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtSubContractPTransfer then
      execute immediate vInsertQuery
                  using iStmStmStockId
                      , iStmStmStockId
                      , iStmStmLocationId
                      , iStmStmLocationId
                      , lDocumentId
                      , lPositionId
                      , aSessionID
                      , lDocumentId
                      , lPositionId
                      , aComponentSeqFrom
                      , aComponentSeqFrom
                      , aComponentSeqTo
                      , aComponentSeqTo
                      , aOpSeqFrom
                      , aOpSeqTo
                      , aComponentWithNeed
                      , aStepNumber
                      , aStepNumberNextOp
                      , aBalanceQty
                      , aContext;
    elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBarCodeComponentOutput then
      execute immediate vInsertQuery
                  using iStmStmStockId
                      , iStmStmStockId
                      , iStmStmLocationId
                      , iStmStmLocationId
                      , aDocumentId
                      , aPositionId
                      , aSessionID
                      , aQtySup
                      , aQtySup
                      , aFalLotId
                      , aFalLotMaterialLinkId;
    -- Execution pour le suivi d'avancement, la sortie de composants code barre
    -- et pour le remplacement de composants
    elsif    aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBarCodeComponentOutput
          or aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtComponentReplacingIn
          or aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtComponentReplacingOut then
      execute immediate vInsertQuery
                  using iStmStmStockId
                      , iStmStmStockId
                      , iStmStmLocationId
                      , iStmStmLocationId
                      , aDocumentId
                      , aPositionId
                      , aSessionID
                      , aFalLotId
                      , aFalLotMaterialLinkId;
    elsif(aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtComponentReturn) then
      -- Execution pour le retour de composants.
      execute immediate vInsertQuery
                  using iStmStmStockId
                      , iStmStmStockId
                      , iStmStmLocationId
                      , iStmStmLocationId
                      , aDocumentId
                      , aPositionId
                      , aSessionID
                      , aFalLotId
                      , aOpSeqFrom
                      , aOpSeqFrom
                      , aOpSeqFrom
                      , aOpSeqTo
                      , aOpSeqTo
                      , aOpSeqTo
                      , aComponentSeqFrom
                      , aComponentSeqFrom
                      , aComponentSeqTo
                      , aComponentSeqTo;
    elsif(aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtSubContractPReturn) then
      -- Execution pour le retour de composants.
      execute immediate vInsertQuery
                  using iStmStmStockId
                      , iStmStmStockId
                      , iStmStmLocationId
                      , iStmStmLocationId
                      , lDocumentId
                      , lPositionId
                      , aSessionID
                      , lDocumentId
                      , lPositionId
                      , aOpSeqFrom
                      , aOpSeqFrom
                      , aOpSeqFrom
                      , aOpSeqTo
                      , aOpSeqTo
                      , aOpSeqTo
                      , aComponentSeqFrom
                      , aComponentSeqFrom
                      , aComponentSeqTo
                      , aComponentSeqTo;
    -- Affectation de composants de stocks vers des lots de fabrication
    elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtStockToBatchAllocation then
      execute immediate vInsertQuery
                  using iStmStmStockId
                      , iStmStmStockId
                      , iStmStmLocationId
                      , iStmStmLocationId
                      , aDocumentId
                      , aPositionId
                      , aSessionID
                      , aGcoGoodId
                      , aSessionID
                      , aFalJobProgramId
                      , aFalJobProgramId
                      , aCPriority
                      , aCPriority
                      , aDocRecordId
                      , aDocRecordId;
    -- Affectation de composants de lots de fabrication vers des stocks
    elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchToStockAllocation then
      execute immediate vInsertQuery
                  using iStmStmStockId
                      , iStmStmStockId
                      , iStmStmLocationId
                      , iStmStmLocationId
                      , aDocumentId
                      , aPositionId
                      , aSessionID
                      , aGcoGoodId
                      , aSessionID
                      , aFalJobProgramId
                      , aFalJobProgramId
                      , aCPriority
                      , aCPriority
                      , aPriorityDate
                      , aPriorityDate
                      , aPriorityDate
                      , aPriorityDate
                      , aPriorityDate;
    -- Réception de lot
    elsif(        (aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtManufacturingReceipt)
             and (ReceptionType <> FAL_BATCH_FUNCTIONS.rtBatchAssembly)
          or (aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtDerivativeReturn)
         ) then
      execute immediate vInsertQuery
                  using iStmStmStockId
                      , iStmStmStockId
                      , iStmStmLocationId
                      , iStmStmLocationId
                      , aDocumentId
                      , aPositionId
                      , aSessionID
                      , aReceptionQty
                      , aReceptionQty
                      , aReceptionQty
                      , aReceptionQty
                      , aFalLotId;
    -- Execution pour le solde du lot
    elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchBalance then
      execute immediate vInsertQuery
                  using iStmStmStockId, iStmStmStockId, iStmStmLocationId, iStmStmLocationId, aDocumentId, aPositionId, aSessionID, aFalLotId, aFalLotId;
    -- Execution pour l'éclatement de lots
    elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchSplitting then
      execute immediate vInsertQuery
                  using iStmStmStockId
                      , iStmStmStockId
                      , iStmStmLocationId
                      , iStmStmLocationId
                      , aDocumentId
                      , aPositionId
                      , aSessionID
                      , aQtyToSwitch
                      , aQtyToSwitch
                      , aQtyToSwitch
                      , aFalLotId;
    -- Execution pour sortie de composant en sous-traitance opératoire
    elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtSubCOComponentOutput then
      execute immediate vInsertQuery
                  using iStmStmStockId, iStmStmStockId, iStmStmLocationId, iStmStmLocationId, aDocumentId, aPositionId, aSessionID, aDocumentId, aPositionId;
    -- Transfert et retour de composants de sous-traitance opératoire
    elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtSubContractOTransfer then
      execute immediate vInsertQuery
                  using iStmStmStockId
                      , iStmStmStockId
                      , iStmStmLocationId
                      , iStmStmLocationId
                      , aDocumentId
                      , aPositionId
                      , aSessionID
                      , aDocumentId
                      , aPositionId
                      , aComponentSeqFrom
                      , aComponentSeqFrom
                      , aComponentSeqTo
                      , aComponentSeqTo
                      , aOpSeqFrom
                      , aOpSeqTo
                      , aComponentWithNeed
                      , aStepNumber
                      , aStepNumberNextOp
                      , aBalanceQty
                      , aContext;
    -- Transfert et retour de composants de sous-traitance opératoire
    elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtSubContractOReturn then
      execute immediate vInsertQuery
                  using iStmStmStockId
                      , iStmStmStockId
                      , iStmStmLocationId
                      , iStmStmLocationId
                      , aDocumentId
                      , aPositionId
                      , aSessionID
                      , aDocumentId
                      , aPositionId
                      , aOpSeqFrom
                      , aOpSeqFrom
                      , aOpSeqFrom
                      , aOpSeqTo
                      , aOpSeqTo
                      , aOpSeqTo
                      , aComponentSeqFrom
                      , aComponentSeqFrom
                      , aComponentSeqTo
                      , aComponentSeqTo;
    -- Execution par défaut
    else
      execute immediate vInsertQuery
                  using iStmStmStockId, iStmStmStockId, iStmStmLocationId, iStmStmLocationId, aDocumentId, aPositionId, aSessionID, aFalLotId;
    end if;
  end;

  /**
  * procédure PurgeLotMatLinkTmpTable
  * Description
  *   Suppression des enregistrements de la table FAL_LOT_MAT_LINK_TMP dont la
  *   session Oracle n'est plus valide
  * @created CLE
  * @lastUpdate
  * @public
  */
  procedure PurgeLotMatLinkTmpTable
  is
    cursor crOracleSession
    is
      select distinct LOM_SESSION
                 from FAL_LOT_MAT_LINK_TMP;
  begin
    FAL_COMPONENT_LINK_FUNCTIONS.PurgeComponentLinkTable;

    for tplOracleSession in crOracleSession loop
      if COM_FUNCTIONS.Is_Session_Alive(tplOracleSession.LOM_SESSION) = 0 then
        delete from FAL_LOT_MAT_LINK_TMP
              where LOM_SESSION = tplOracleSession.LOM_SESSION;
      end if;
    end loop;
  end;

  /**
  * procédure PurgeAllTemporaryTable
  * Description
  *   Suppression des enregistrements de la table FAL_LOT_MAT_LINK_TMP et
  *   FAL_COMPONENT_LINK  pour une session Oracle donnée en paramètre, ainsi
  *   que pour les éventuelles session invalides.
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aSessionId             ID unique de Session Oracle
  */
  procedure PurgeAllTemporaryTable(aSessionId FAL_COMPONENT_LINK.FCL_SESSION%type)
  is
  begin
    -- Liens Composants
    delete from FAL_COMPONENT_LINK
          where FCL_SESSION = aSessionId;

    -- Composants
    delete from FAL_LOT_MAT_LINK_TMP
          where LOM_SESSION = aSessionId;

    PurgeLotMatLinkTmpTable;
  end;

  /**
  * procédure PurgeTemporaryTableAT
  * Description
  *   Suppression des enregistrements de la table FAL_LOT_MAT_LINK_TMP et
  *   FAL_COMPONENT_LINK  pour un lot donné. Dans une trasaction autonome
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aFalLotId    Id du lot
  */
  procedure PurgeTemporaryTableAT(aFalLotId FAL_LOT.FAL_LOT_ID%type)
  is
  begin
    PurgeTemporaryTable(aFalLotId);
  end;

  /**
  * procédure PurgeTemporaryTable
  * Description
  *   Suppression des enregistrements de la table FAL_LOT_MAT_LINK_TMP et
  *   FAL_COMPONENT_LINK  pour un lot donné.
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aFalLotId    Id du lot
  */
  procedure PurgeTemporaryTable(aFalLotId FAL_LOT.FAL_LOT_ID%type)
  is
  begin
    -- Liens Composants
    delete from FAL_COMPONENT_LINK
          where FAL_LOT_ID = aFalLotId;

    -- Composants
    delete from FAL_LOT_MAT_LINK_TMP
          where FAL_LOT_ID = aFalLotId;
  end;

  /**
  * procédure PurgeLotMatLinkTmpTable
  * Description
  *   Suppression des enregistrements de la table FAL_LOT_MAT_LINK_TMP pour une
  *   session Oracle donnée en paramètre
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aSessionId             ID unique de Session Oracle
  */
  procedure PurgeLotMatLinkTmpTable(aSessionId FAL_COMPONENT_LINK.FCL_SESSION%type)
  is
  begin
    FAL_COMPONENT_LINK_FCT.PurgeComponentLinkTable(aSessionId);

    delete from FAL_LOT_MAT_LINK_TMP
          where LOM_SESSION = aSessionId;
  end;

  /**
  * procédure UpdateMaxReceiptQty
  * Description
  *   Mise à jour de la quantité max réceptionnable d'un composant.
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aSessionId             Id unique de Session Oracle
  * @param   FalLotMatLinkTmpId     Id du composant
  * @param   aUpdateBatch           Défini si on met à jour également le lot
  */
  procedure UpdateMaxReceiptQty(
    aSessionId         varchar2
  , FalLotMatLinkTmpId FAL_LOT_MAT_LINK_TMP.FAL_LOT_MAT_LINK_TMP_ID%type default null
  , aUpdateBatch       integer default 0
  )
  is
  begin
    update FAL_LOT_MAT_LINK_TMP LOM
       set LOM_MAX_RECEIPT_QTY =
             FAL_COMPONENT_FUNCTIONS.getMaxReceptQty( (select GCO_GOOD_ID
                                                         from FAL_LOT
                                                        where FAL_LOT_ID = LOM.FAL_LOT_ID)   -- aGCO_GOOD_ID
                                                   , (select LOT_INPROD_QTY
                                                        from FAL_LOT
                                                       where FAL_LOT_ID = LOM.FAL_LOT_ID)   -- aLOT_INPROD_QTY
                                                   , LOM_ADJUSTED_QTY   -- aLOM_ADJUSTED_QTY
                                                   , (select nvl(sum(FCL_HOLD_QTY), 0)
                                                        from FAL_COMPONENT_LINK
                                                       where FAL_LOT_MAT_LINK_TMP_ID = LOM.FAL_LOT_MAT_LINK_TMP_ID
                                                         and FCL_SESSION = aSessionId)   -- aLOM_CONSUMPTION_QTY
                                                   , LOM_REF_QTY   -- aLOM_REF_QTY
                                                   , LOM_UTIL_COEF   -- aLOM_UTIL_COEF
                                                    )
     where LOM_SESSION = aSessionId
       and (   FalLotMatLinkTmpId is null
            or (    FalLotMatLinkTmpId is not null
                and FAL_LOT_MAT_LINK_TMP_ID = FalLotMatLinkTmpId) );

    if aUpdateBatch = 1 then
      for tplBatch in (select FAL_LOT_ID
                         from FAL_LOT_MAT_LINK_TMP
                        where LOM_SESSION = aSessionId
                          and (   FalLotMatLinkTmpId is null
                               or (    FalLotMatLinkTmpId is not null
                                   and FAL_LOT_MAT_LINK_TMP_ID = FalLotMatLinkTmpId) ) ) loop
        FAL_BATCH_FUNCTIONS.UpdateMaxManufacturableQty(aSessionId => aSessionId, aFalLotId => tplBatch.FAL_LOT_ID);
      end loop;
    end if;
  end;

  /**
  * procédure GetSumOfComponentQty
  * Description
  *   Récupère la somme des qté saisies pour un composant
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aFAL_LOT_MAT_LINK_TMP_ID  Composants
  * @param   aSumHoldedQty    Somme des qté saisies
  * @param   aSumReturnQty    Somme des qté Retour
  * @param   aSumTrashQty     Somme des qté Déchet
  * @param   aSTM_LOCATION_ID Emplacment
  */
  procedure GetSumOfComponentQty(
    aFAL_LOT_MAT_LINK_TMP_ID in     number
  , aSumHoldedQty            in out number
  , aSumReturnQty            in out number
  , aSumTrashQty             in out number
  , aSTM_LOCATION_ID         in     number default null
  )
  is
  begin
    select nvl(sum(FCL_HOLD_QTY), 0)
         , nvl(sum(FCL_RETURN_QTY), 0)
         , nvl(sum(FCL_TRASH_QTY), 0)
      into aSumHoldedQty
         , aSumReturnQty
         , aSumTrashQty
      from FAL_COMPONENT_LINK
     where FAL_LOT_MAT_LINK_TMP_ID = aFAL_LOT_MAT_LINK_TMP_ID
       and (   nvl(aSTM_LOCATION_ID, 0) = 0
            or STM_LOCATION_ID = aSTM_LOCATION_ID);
  end;

  /**
  * procédure UpdateLomAdjustedQty
  * Description
  *   Mise à jour de la qté sup inf d'un composant temporaire
  *
  * @created ECA
  * @lastUpdate
  * @publics
  * @param   aLomadjustedQty nouvelle qté sup / Inf
  * @param   aLomFullReqQty Qté besoin totale
  * @param   aLomNeedQty Qté Besoin CPT
  * @param   aLomUtilCoef Coef utilisation
  * @param   aLomBomReqQty Qté besoin
  */
  procedure UpdateLomAdjustedQty(
    FalLotMatLinkTmpId number
  , aLomAdjustedQty    number
  , aLomFullReqQty     number
  , aLomNeedQty        number
  , aLomUtilCoef       number
  , aLomBomReqQty      number
  )
  is
  begin
    update FAL_LOT_MAT_LINK_TMP LML
       set LML.LOM_ADJUSTED_QTY = aLomAdjustedQty
         , LML.LOM_FULL_REQ_QTY = aLomFullReqQty
         , LML.LOM_NEED_QTY = aLomNeedQty
         , LML.LOM_UTIL_COEF = aLomUtilCoef
         , LML.LOM_BOM_REQ_QTY = aLomBomReqQty
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_INIT_SESSION.GetUserIni
     where LML.FAL_LOT_MAT_LINK_TMP_ID = FalLotMatLinkTmpId;
  end;

  /**
  * procedure UpdateLomCommentary
  * Description
  *   Mise à jour du code motif et du commentaire, destiné à être portés sur les
  *   entrées et sorties atelier
  *
  * @created ECA
  * @lastUpdate
  * @publics
  * @param   aFalLotMatLinkTmpId     Composant
  * @param   aApplyToAll             Appliquer à tous les composants de la session
  * @param   aSessionId              Session Oracle
  * @param   aDIC_COMPONENT_MVT_ID   Code Motif
  * @param   aCommentary             Commentaire
  */
  procedure UpdateLomCommentary(
    aSessionId            varchar2
  , aFalLotMatLinkTmpId   number default null
  , aApplyToAll           integer default 0
  , aDIC_COMPONENT_MVT_ID varchar2 default ''
  , aCommentary           varchar2 default ''
  )
  is
  begin
    update FAL_LOT_MAT_LINK_TMP
       set DIC_COMPONENT_MVT_ID = aDIC_COMPONENT_MVT_ID
         , LOM_MVT_COMMENT = aCommentary
     where (    nvl(aApplyToAll, 0) = 1
            and LOM_SESSION = aSessionId)
        or (    nvl(aApplyToAll, 0) = 0
            and FAL_LOT_MAT_LINK_TMP_ID = aFalLotMatLinkTmpId);
  end;

  /**
  * fonction : GetLomAdjustedQtyOnRecept
  * Description : Calcul de la quantité sup/inf des composants en réception d'OF
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aReceptionQty : Qté réceptionnée
  * @param   aLOM_MAX_RECEIPT_QTY : Qté max réceptionnable
  * @param   aLOM_ADJUSTED_QTY : Qté sup/Inf
  * @param   aLOM_ADJUSTED_QTY_RECEIPT : Qté sup/inf réception
  * @param   aLOM_UTIL_COEF : Coefficient d'utilisation
  * @param   aLOM_REF_QTY : Qté référence nomenclature
  * @param   aGCO_GOOD_ID : Bien du composant d'OF.
  */
  function GetLomAdjustedQtyOnRecept(
    aReceptionQty             number
  , aLOM_MAX_RECEIPT_QTY      number
  , aLOM_ADJUSTED_QTY         number
  , aLOM_ADJUSTED_QTY_RECEIPT number
  , aLOM_UTIL_COEF            number
  , aLOM_REF_QTY              number
  , aGCO_GOOD_ID              number
  )
    return number
  is
    nLOM_UTIL_COEF number;
  begin
    nLOM_UTIL_COEF  := case
                        when nvl(aLOM_UTIL_COEF, 0) = 0 then 1
                        else aLOM_UTIL_COEF
                      end;

    if aReceptionQty > aLOM_MAX_RECEIPT_QTY +( (aLOM_ADJUSTED_QTY - aLOM_ADJUSTED_QTY_RECEIPT) / nLOM_UTIL_COEF * aLOM_REF_QTY) then
      return -least(FAL_TOOLS.ArrondiSuperieur( (aReceptionQty * nLOM_UTIL_COEF) / aLOM_REF_QTY, aGCO_GOOD_ID)
                  , -(aLOM_ADJUSTED_QTY - aLOM_ADJUSTED_QTY_RECEIPT) );
    else
      return 0;
    end if;
  exception
    when others then
      return 0;
  end;

  /**
  * fonction : GetLomFullReqQtyOnRecept
  * Description : Calcul de la quantité besoin totale des composants en réception d'OF
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aReceptionQty : Qté réceptionnée
  * @param   aLOM_MAX_RECEIPT_QTY : Qté max réceptionnable
  * @param   aLOM_ADJUSTED_QTY : Qté sup/Inf
  * @param   aLOM_ADJUSTED_QTY_RECEIPT : Qté sup/inf réception
  * @param   aLOM_UTIL_COEF : Coefficient d'utilisation
  * @param   aLOM_REF_QTY : Qté référence nomenclature
  * @param   aGCO_GOOD_ID : Bien du composant d'OF.
  * @param   aLOM_FULL_REQ_QTY : Qté besoin totale du composants
  * @param   aFAL_LOT_ID : of
  * @param   aLOM_EXIT_RECEIPT : Qté sortie en réception
  */
  function GetLomFullReqQtyOnRecept(
    aReceptionQty             number
  , aLOM_MAX_RECEIPT_QTY      number
  , aLOM_ADJUSTED_QTY         number
  , aLOM_ADJUSTED_QTY_RECEIPT number
  , aLOM_UTIL_COEF            number
  , aLOM_REF_QTY              number
  , aGCO_GOOD_ID              number
  , aLOM_FULL_REQ_QTY         number
  , aFAL_LOT_ID               number
  , aLOM_EXIT_RECEIPT         number
  )
    return number
  is
  begin
    return GetLomAdjustedQtyOnRecept(aReceptionQty
                                   , aLOM_MAX_RECEIPT_QTY
                                   , aLOM_ADJUSTED_QTY
                                   , aLOM_ADJUSTED_QTY_RECEIPT
                                   , aLOM_UTIL_COEF
                                   , aLOM_REF_QTY
                                   , aGCO_GOOD_ID
                                    ) +
           GetLomBomReqQtyOnRecept(aReceptionQty, aLOM_UTIL_COEF, aLOM_FULL_REQ_QTY, aLOM_REF_QTY, aGCO_GOOD_ID, aFAL_LOT_ID, aLOM_EXIT_RECEIPT);
  exception
    when others then
      return 0;
  end;

  /**
  * fonction : GetLomBomReqQtyOnRecept
  * Description : Calcul de la quantité besoin nomenclature en réception
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aReceptionQty : Qté réceptionnée
  * @param   aLOM_UTIL_COEF : Coefficient d'utilisation
  * @param   aLOM_FULL_REQ_QTY : Qté besoin totale
  * @param   aLOM_REF_QTY : Qté référence nomenclature
  * @param   aGCO_GOOD_ID : Bien du composant d'OF.
  * @param   aFAL_LOT_ID : Of
  * @param   aLOM_EXIT_RECEIPT : Qté sortie réception
  */
  function GetLomBomReqQtyOnRecept(
    aReceptionQty     number
  , aLOM_UTIL_COEF    number
  , aLOM_FULL_REQ_QTY number
  , aLOM_REF_QTY      number
  , aGCO_GOOD_ID      number
  , aFAL_LOT_ID       number
  , aLOM_EXIT_RECEIPT number
  )
    return number
  is
    aLOT_TOTAL_QTY number;
  begin
    -- Cas de composants avec utilisation à 0 mais une Qté besoin due aux déchets fixes.
    if     nvl(aLOM_UTIL_COEF, 0) = 0
       and nvl(aLOM_FULL_REQ_QTY, 0) > 0 then
      select LOT_TOTAL_QTY
        into aLOT_TOTAL_QTY
        from FAL_LOT
       where FAL_LOT_ID = aFAL_LOT_ID;

      return greatest(0
                    , least(aLOM_FULL_REQ_QTY - aLOM_EXIT_RECEIPT, FAL_TOOLS.ArrondiSuperieur(aReceptionQty * aLOM_FULL_REQ_QTY / aLOT_TOTAL_QTY, aGCO_GOOD_ID) )
                     );
    else
      return FAL_TOOLS.ArrondiSuperieur( (aLOM_UTIL_COEF * aReceptionQty / aLOM_REF_QTY), aGCO_GOOD_ID);
    end if;
  exception
    when others then
      return 0;
  end;
end;
