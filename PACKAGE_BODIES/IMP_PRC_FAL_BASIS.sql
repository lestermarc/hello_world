--------------------------------------------------------
--  DDL for Package Body IMP_PRC_FAL_BASIS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IMP_PRC_FAL_BASIS" 
as
  /**
  * Description
  *    importation des données d'Excel dans la table temporaire IMP_FAL_FACTORY_FLOOR. Cette procédure est appelée depuis Excel
  */
  procedure IMP_TMP_FAL_FACTORY_FLOOR(
    iFacReference         in     IMP_FAL_FACTORY_FLOOR.FAC_REFERENCE%type
  , iFacDescribe          in     IMP_FAL_FACTORY_FLOOR.FAC_DESCRIBE%type
  , iFacType              in     varchar2
  , iFalFalFactoryFloorId in     IMP_FAL_FACTORY_FLOOR.FAL_FAL_FACTORY_FLOOR_ID%type
  , iFalGrpFactoryFloorId in     IMP_FAL_FACTORY_FLOOR.FAL_GRP_FACTORY_FLOOR_ID%type
  , iFacResourceNumber    in     IMP_FAL_FACTORY_FLOOR.FAC_RESOURCE_NUMBER%type
  , iHrmPersonId          in     IMP_FAL_FACTORY_FLOOR.HRM_PERSON_ID%type
  , iPacScheduleId        in     IMP_FAL_FACTORY_FLOOR.PAC_SCHEDULE_ID%type
  , iFacPic               in     IMP_FAL_FACTORY_FLOOR.FAC_PIC%type
  , iFacInfiniteFloor     in     IMP_FAL_FACTORY_FLOOR.FAC_INFINITE_FLOOR%type
  , iFacDayCapacity       in     IMP_FAL_FACTORY_FLOOR.FAC_DAY_CAPACITY%type
  , iFacPiecesHourCap     in     IMP_FAL_FACTORY_FLOOR.FAC_PIECES_HOUR_CAP%type
  , iFacUnitMarginRate    in     IMP_FAL_FACTORY_FLOOR.FAC_UNIT_MARGIN_RATE%type
  , iAcsCdaAccountId      in     IMP_FAL_FACTORY_FLOOR.ACS_CDA_ACCOUNT_ID%type
  , iGalCostCenterId      in     IMP_FAL_FACTORY_FLOOR.GAL_COST_CENTER_ID%type
  , iFfrValidityDate      in     varchar2
  , iFfrRate1             in     IMP_FAL_FACTORY_RATE.FFR_RATE1%type
  , iFfrRate2             in     IMP_FAL_FACTORY_RATE.FFR_RATE2%type
  , iFfrRate3             in     IMP_FAL_FACTORY_RATE.FFR_RATE3%type
  , iFfrRate4             in     IMP_FAL_FACTORY_RATE.FFR_RATE4%type
  , iFfrRate5             in     IMP_FAL_FACTORY_RATE.FFR_RATE5%type
  , iFree1                in     IMP_FAL_FACTORY_FLOOR.FREE1%type
  , iFree2                in     IMP_FAL_FACTORY_FLOOR.FREE2%type
  , iFree3                in     IMP_FAL_FACTORY_FLOOR.FREE3%type
  , iFree4                in     IMP_FAL_FACTORY_FLOOR.FREE4%type
  , iFree5                in     IMP_FAL_FACTORY_FLOOR.FREE5%type
  , iFree6                in     IMP_FAL_FACTORY_FLOOR.FREE6%type
  , iFree7                in     IMP_FAL_FACTORY_FLOOR.FREE7%type
  , iFree8                in     IMP_FAL_FACTORY_FLOOR.FREE8%type
  , iFree9                in     IMP_FAL_FACTORY_FLOOR.FREE9%type
  , iFree10               in     IMP_FAL_FACTORY_FLOOR.FREE10%type
  , iExcelLine            in     IMP_FAL_FACTORY_FLOOR.EXCEL_LINE%type
  , oResult               out    integer
  )
  as
    lFacFloorTmpId number;
    ltFacFloorImp  FWK_I_TYP_DEFINITION.t_crud_def;
    ltFacRateImp   FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Insertion de l'atelier dans l'entité IMP_FAL_FACTORY_FLOOR si inexistant.
    select nvl(max(IMP_FAL_FACTORY_FLOOR_ID), 0)
      into lFacFloorTmpId
      from IMP_FAL_FACTORY_FLOOR
     where upper(FAC_REFERENCE) = upper(iFacReference);

    if (lFacFloorTmpId = 0) then
      lFacFloorTmpId  := GetNewId;
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_IMP_ENTITY.gcImpFalFactoryFloor, ltFacFloorImp);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'IMP_FAL_FACTORY_FLOOR_ID', lFacFloorTmpId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'EXCEL_LINE', trim(iExcelLine) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'FAC_REFERENCE', trim(iFacReference) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'FAC_DESCRIBE', trim(iFacDescribe) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'FAC_IS_BLOCK', Bool2Byte(nvl(trim(iFacType), '1') = '1') );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'FAC_IS_MACHINE', Bool2Byte(nvl(trim(iFacType), '1') = '2') );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'FAC_IS_OPERATOR', Bool2Byte(nvl(trim(iFacType), '1') = '3') );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'FAC_IS_PERSON', Bool2Byte(nvl(trim(iFacType), '1') = '4') );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'FAL_GRP_FACTORY_FLOOR_ID', trim(iFalGrpFactoryFloorId) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'HRM_PERSON_ID', trim(iHrmPersonId) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'FAC_RESOURCE_NUMBER', nvl(trim(iFacResourceNumber), 1) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'FAC_PIC', nvl(trim(iFacPic), 0) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'FAL_FAL_FACTORY_FLOOR_ID', trim(iFalFalFactoryFloorId) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'FAC_INFINITE_FLOOR', nvl(trim(iFacInfiniteFloor), 0) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'FAC_PIECES_HOUR_CAP', trim(iFacPiecesHourCap) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'ACS_CDA_ACCOUNT_ID', trim(iAcsCdaAccountId) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'GAL_COST_CENTER_ID', trim(iGalCostCenterId) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp
                                    , 'PAC_SCHEDULE_ID'
                                    , nvl(trim(iPacScheduleId)
                                        , FWK_I_LIB_ENTITY.getVarchar2FieldFromPk(FWK_I_TYP_PAC_ENTITY.gcPacSchedule
                                                                                , 'SCE_DESCR'
                                                                                , PAC_I_LIB_SCHEDULE.GetDefaultSchedule
                                                                                 )
                                         )
                                     );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'FAC_UNIT_MARGIN_RATE', trim(iFacUnitMarginRate) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'FAC_DAY_CAPACITY', trim(iFacDayCapacity) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'FREE1', trim(iFree1) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'FREE2', trim(iFree2) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'FREE3', trim(iFree3) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'FREE4', trim(iFree4) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'FREE5', trim(iFree5) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'FREE6', trim(iFree6) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'FREE7', trim(iFree7) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'FREE8', trim(iFree8) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'FREE9', trim(iFree9) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'FREE10', trim(iFree10) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImp, 'A_IDCRE', IMP_LIB_TOOLS.GetImportUserIni);
      FWK_I_MGT_ENTITY.InsertEntity(ltFacFloorImp);
      FWK_I_MGT_ENTITY.Release(ltFacFloorImp);
    end if;

    -- Insertion du taux dans l'entité IMP_FAL_FACTORY_RATE si au moins un taux est défini.
    if (nvl(trim(iFfrRate1), 0) + nvl(trim(iFfrRate2), 0) + nvl(trim(iFfrRate3), 0) + nvl(trim(iFfrRate4), 0) + nvl(trim(iFfrRate5), 0) ) > 0 then
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_IMP_ENTITY.gcImpFalFactoryRate, ltFacRateImp);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRateImp, 'IMP_FAL_FACTORY_FLOOR_ID', lFacFloorTmpId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRateImp, 'EXCEL_LINE', trim(iExcelLine) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRateImp, 'FFR_VALIDITY_DATE', to_date(trim(iFfrValidityDate), 'DD.MM.YYYY') );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRateImp, 'FFR_RATE1', nvl(trim(iFfrRate1), 0) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRateImp, 'FFR_RATE2', nvl(trim(iFfrRate2), 0) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRateImp, 'FFR_RATE3', nvl(trim(iFfrRate3), 0) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRateImp, 'FFR_RATE4', nvl(trim(iFfrRate4), 0) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRateImp, 'FFR_RATE5', nvl(trim(iFfrRate5), 0) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRateImp, 'A_IDCRE', IMP_LIB_TOOLS.GetImportUserIni);
      FWK_I_MGT_ENTITY.InsertEntity(ltFacRateImp);
      FWK_I_MGT_ENTITY.Release(ltFacRateImp);
    end if;

    oResult  := 1;
    commit;
  end IMP_TMP_FAL_FACTORY_FLOOR;

  procedure IMP_TMP_FAL_TASK(
    iCTaskType            in     IMP_FAL_TASK.C_TASK_TYPE%type
  , iTasRef               in     IMP_FAL_TASK.TAS_REF%type
  , iTasShortDescr        in     IMP_FAL_TASK.TAS_SHORT_DESCR%type
  , iTasLongDescr         in     IMP_FAL_TASK.TAS_LONG_DESCR%type
  , iTasFreeDescr         in     IMP_FAL_TASK.TAS_FREE_DESCR%type
  , iCSchedulePlanning    in     IMP_FAL_TASK.C_SCHEDULE_PLANNING%type
  , iFalFactoryFloorId    in     IMP_FAL_TASK.FAL_FACTORY_FLOOR_ID%type
  , iPacSupplierPartnerId in     IMP_FAL_TASK.PAC_SUPPLIER_PARTNER_ID%type
  , iGcoGoodId            in     IMP_FAL_TASK.GCO_GCO_GOOD_ID%type
  , iTasPlanRate          in     IMP_FAL_TASK.TAS_PLAN_RATE%type
  , iTasPlanProp          in     IMP_FAL_TASK.TAS_PLAN_PROP%type
  , iCTaskImputation      in     IMP_FAL_TASK.C_TASK_IMPUTATION%type
  , iFalFalFactoryFloorId in     IMP_FAL_TASK.FAL_FAL_FACTORY_FLOOR_ID%type
  , iTasWorkRate          in     IMP_FAL_TASK.TAS_WORK_RATE%type
  , iTasAdjustingRate     in     IMP_FAL_TASK.TAS_ADJUSTING_RATE%type
  , iTasNumFloor          in     IMP_FAL_TASK.TAS_NUM_FLOOR%type
  , iTasTransfertTime     in     IMP_FAL_TASK.TAS_TRANSFERT_TIME%type
  , iTasAdjustingFloor    in     IMP_FAL_TASK.TAS_ADJUSTING_FLOOR%type
  , iTasAdjustingOperator in     IMP_FAL_TASK.TAS_ADJUSTING_OPERATOR%type
  , iTasNumAdjustOperator in     IMP_FAL_TASK.TAS_NUM_ADJUST_OPERATOR%type
  , iTasPercentAdjustOper in     IMP_FAL_TASK.TAS_PERCENT_ADJUST_OPER%type
  , iTasWorkFloor         in     IMP_FAL_TASK.TAS_WORK_FLOOR%type
  , iTasWorkOperator      in     IMP_FAL_TASK.TAS_WORK_OPERATOR%type
  , iTasNumWorkOperator   in     IMP_FAL_TASK.TAS_NUM_WORK_OPERATOR%type
  , iTasPercentWorkOper   in     IMP_FAL_TASK.TAS_PERCENT_WORK_OPER%type
  , iTasAmount            in     IMP_FAL_TASK.TAS_AMOUNT%type
  , iTasQtyRefAmount      in     IMP_FAL_TASK.TAS_QTY_REF_AMOUNT%type
  , iTasDivisorAmount     in     IMP_FAL_TASK.TAS_DIVISOR_AMOUNT%type
  , iTasWeigh             in     IMP_FAL_TASK.TAS_WEIGH%type
  , iTasWeighMandatory    in     IMP_FAL_TASK.TAS_WEIGH_MANDATORY%type
  , iFree1                in     IMP_FAL_TASK.FREE1%type
  , iFree2                in     IMP_FAL_TASK.FREE2%type
  , iFree3                in     IMP_FAL_TASK.FREE3%type
  , iFree4                in     IMP_FAL_TASK.FREE4%type
  , iFree5                in     IMP_FAL_TASK.FREE5%type
  , iFree6                in     IMP_FAL_TASK.FREE6%type
  , iFree7                in     IMP_FAL_TASK.FREE7%type
  , iFRee8                in     IMP_FAL_TASK.FREE8%type
  , iFRee9                in     IMP_FAL_TASK.FREE9%type
  , iFRee10               in     IMP_FAL_TASK.FREE10%type
  , iExcelLine            in     IMP_FAL_TASK.EXCEL_LINE%type
  , oResult               out    integer
  )
  as
    ltTaskImp FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Insertion du taux dans l'entité IMP_FAL_TASK
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_IMP_ENTITY.gcImpFalTask, ltTaskImp);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'EXCEL_LINE', trim(iExcelLine) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'C_TASK_TYPE', trim(iCTaskType) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'TAS_REF', trim(iTasRef) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'TAS_SHORT_DESCR', trim(iTasShortDescr) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'TAS_LONG_DESCR', trim(iTasLongDescr) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'TAS_FREE_DESCR', trim(iTasFreeDescr) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'C_SCHEDULE_PLANNING', nvl(trim(iCSchedulePlanning), '3') );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'FAL_FACTORY_FLOOR_ID', trim(iFalFactoryFloorId) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'PAC_SUPPLIER_PARTNER_ID', trim(iPacSupplierPartnerId) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'GCO_GCO_GOOD_ID', trim(iGcoGoodId) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'C_TASK_IMPUTATION', nvl(trim(iCTaskImputation), '1') );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'FAL_FAL_FACTORY_FLOOR_ID', trim(iFalFalFactoryFloorId) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'TAS_ADJUSTING_RATE', nvl(trim(iTasAdjustingRate), 1) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'TAS_WORK_RATE', nvl(trim(iTasWorkRate), 2) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'TAS_NUM_FLOOR', nvl(trim(iTasNumFloor), 1) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'TAS_ADJUSTING_FLOOR', nvl(trim(iTasAdjustingFloor), 0) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'TAS_ADJUSTING_OPERATOR', nvl(trim(iTasAdjustingOperator), 0) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'TAS_NUM_ADJUST_OPERATOR', nvl(trim(iTasNumAdjustOperator), 1) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'TAS_PERCENT_ADJUST_OPER', nvl(trim(iTasPercentAdjustOper), 100) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'TAS_WORK_FLOOR', nvl(trim(iTasWorkFloor), 0) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'TAS_WORK_OPERATOR', nvl(trim(iTasWorkOperator), 0) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'TAS_NUM_WORK_OPERATOR', nvl(trim(iTasNumWorkOperator), 1) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'TAS_PERCENT_WORK_OPER', nvl(trim(iTasPercentWorkOper), 100) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'TAS_WEIGH', nvl(trim(iTasWeigh), 0) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'TAS_WEIGH_MANDATORY', nvl(trim(iTasWeighMandatory), 0) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'TAS_TRANSFERT_TIME', nvl(trim(iTasTransfertTime), 0) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'TAS_AMOUNT', nvl(trim(iTasAmount), 0) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'TAS_QTY_REF_AMOUNT', nvl(trim(iTasQtyRefAmount), 1) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'TAS_DIVISOR_AMOUNT', nvl(trim(iTasDivisorAmount), 0) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'TAS_PLAN_RATE', nvl(trim(iTasPlanRate), 0) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'TAS_PLAN_PROP', nvl(trim(iTasPlanProp), 0) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'FREE1', trim(iFree1) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'FREE2', trim(iFree2) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'FREE3', trim(iFree3) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'FREE4', trim(iFree4) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'FREE5', trim(iFree5) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'FREE6', trim(iFree6) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'FREE7', trim(iFree7) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'FREE8', trim(iFRee8) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'FREE9', trim(iFRee9) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'FREE10', trim(iFRee10) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImp, 'A_IDCRE', IMP_LIB_TOOLS.GetImportUserIni);
    FWK_I_MGT_ENTITY.InsertEntity(ltTaskImp);
    FWK_I_MGT_ENTITY.Release(ltTaskImp);
    oResult  := 1;
    commit;
  end IMP_TMP_FAL_TASK;

  procedure IMP_TMP_FAL_SCHEDULE_PLAN(
    iSchRef               in     IMP_FAL_SCHEDULE_PLAN.SCH_REF%type
  , iSchShortDescr        in     IMP_FAL_SCHEDULE_PLAN.SCH_SHORT_DESCR%type
  , iSchLongDescr         in     IMP_FAL_SCHEDULE_PLAN.SCH_LONG_DESCR%type
  , iSchFreeDescr         in     IMP_FAL_SCHEDULE_PLAN.SCH_FREE_DESCR%type
  , iCSchedulePlanning    in     IMP_FAL_SCHEDULE_PLAN.C_SCHEDULE_PLANNING%type
  , iScsStepNumber        in     IMP_FAL_LIST_STEP_LINK.SCS_STEP_NUMBER%type
  , iFalTaskId            in     IMP_FAL_LIST_STEP_LINK.FAL_TASK_ID%type
  , iScsShortDescr        in     IMP_FAL_LIST_STEP_LINK.SCS_SHORT_DESCR%type
  , iScsLongDescr         in     IMP_FAL_LIST_STEP_LINK.SCS_LONG_DESCR%type
  , iScsFreeDescr         in     IMP_FAL_LIST_STEP_LINK.SCS_FREE_DESCR%type
  , iCOperationType       in     IMP_FAL_LIST_STEP_LINK.C_OPERATION_TYPE%type
  , iCRelationType        in     IMP_FAL_LIST_STEP_LINK.C_RELATION_TYPE%type
  , iScsDelay             in     IMP_FAL_LIST_STEP_LINK.SCS_DELAY%type
  , iFalFactoryFloorId    in     IMP_FAL_LIST_STEP_LINK.FAL_FACTORY_FLOOR_ID%type
  , iScsNumFloor          in     IMP_FAL_LIST_STEP_LINK.SCS_NUM_FLOOR%type
  , iScsWorkRate          in     IMP_FAL_LIST_STEP_LINK.SCS_WORK_RATE%type
  , iFalFalFactoryFloorId in     IMP_FAL_LIST_STEP_LINK.FAL_FAL_FACTORY_FLOOR_ID%type
  , iScsAdjustingRate     in     IMP_FAL_LIST_STEP_LINK.SCS_ADJUSTING_RATE%type
  , iPacSupplierPartnerId in     IMP_FAL_LIST_STEP_LINK.PAC_SUPPLIER_PARTNER_ID%type
  , iGcoGcoGoodId         in     IMP_FAL_LIST_STEP_LINK.GCO_GCO_GOOD_ID%type
  , iScsAdjustingTime     in     IMP_FAL_LIST_STEP_LINK.SCS_ADJUSTING_TIME%type
  , iScsQtyFixAdjusting   in     IMP_FAL_LIST_STEP_LINK.SCS_QTY_FIX_ADJUSTING%type
  , iScsWorkTime          in     IMP_FAL_LIST_STEP_LINK.SCS_WORK_TIME%type
  , iScsQtyRefWork        in     IMP_FAL_LIST_STEP_LINK.SCS_QTY_REF_WORK%type
  , iScsTransfertTime     in     IMP_FAL_LIST_STEP_LINK.SCS_TRANSFERT_TIME%type
  , iScsPlanRate          in     IMP_FAL_LIST_STEP_LINK.SCS_PLAN_RATE%type
  , iScsPlanProp          in     IMP_FAL_LIST_STEP_LINK.SCS_PLAN_PROP%type
  , iScsAmount            in     IMP_FAL_LIST_STEP_LINK.SCS_AMOUNT%type
  , iScsQtyRefAmount      in     IMP_FAL_LIST_STEP_LINK.SCS_QTY_REF_AMOUNT%type
  , iScsDivisorAmount     in     IMP_FAL_LIST_STEP_LINK.SCS_DIVISOR_AMOUNT%type
  , iScsAdjustingFloor    in     IMP_FAL_LIST_STEP_LINK.SCS_ADJUSTING_FLOOR%type
  , iScsAdjustingOperator in     IMP_FAL_LIST_STEP_LINK.SCS_ADJUSTING_OPERATOR%type
  , iScsNumAdjustOperator in     IMP_FAL_LIST_STEP_LINK.SCS_NUM_ADJUST_OPERATOR%type
  , iScsPercentAdjustOper in     IMP_FAL_LIST_STEP_LINK.SCS_PERCENT_ADJUST_OPER%type
  , iScsWorkFloor         in     IMP_FAL_LIST_STEP_LINK.SCS_WORK_FLOOR%type
  , iScsWorkOperator      in     IMP_FAL_LIST_STEP_LINK.SCS_WORK_OPERATOR%type
  , iScsNumWorkOperator   in     IMP_FAL_LIST_STEP_LINK.SCS_NUM_WORK_OPERATOR%type
  , iScsPercentWorkOper   in     IMP_FAL_LIST_STEP_LINK.SCS_PERCENT_WORK_OPER%type
  , iCTaskImputation      in     IMP_FAL_LIST_STEP_LINK.C_TASK_IMPUTATION%type
  , iScsWeigh             in     IMP_FAL_LIST_STEP_LINK.SCS_WEIGH%type
  , iScsWeighMandatory    in     IMP_FAL_LIST_STEP_LINK.SCS_WEIGH_MANDATORY%type
  , iFree1                in     IMP_FAL_LIST_STEP_LINK.FREE1%type
  , iFree2                in     IMP_FAL_LIST_STEP_LINK.FREE2%type
  , iFree3                in     IMP_FAL_LIST_STEP_LINK.FREE3%type
  , iFree4                in     IMP_FAL_LIST_STEP_LINK.FREE4%type
  , iFree5                in     IMP_FAL_LIST_STEP_LINK.FREE5%type
  , iFree6                in     IMP_FAL_LIST_STEP_LINK.FREE6%type
  , iFree7                in     IMP_FAL_LIST_STEP_LINK.FREE7%type
  , iFree8                in     IMP_FAL_LIST_STEP_LINK.FREE8%type
  , iFree9                in     IMP_FAL_LIST_STEP_LINK.FREE9%type
  , iFree10               in     IMP_FAL_LIST_STEP_LINK.FREE10%type
  , iExcelLine            in     IMP_FAL_SCHEDULE_PLAN.EXCEL_LINE%type
  , oResult               out    integer
  )
  as
    lSchedulePlanTmpId number;
    ltSchedulePlanTmp  FWK_I_TYP_DEFINITION.t_crud_def;
    ltListStepLinkTmp  FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Insertion de la gamme opératoire dans l'entité IMP_FAL_SCHEDULE_PLAN si inexistant.
    select nvl(max(IMP_FAL_SCHEDULE_PLAN_ID), 0)
      into lSchedulePlanTmpId
      from IMP_FAL_SCHEDULE_PLAN
     where upper(SCH_REF) = upper(iSchRef);

    if (lSchedulePlanTmpId = 0) then
      lSchedulePlanTmpId  := GetNewId;
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_IMP_ENTITY.gcImpFalSchedulePlan, ltSchedulePlanTmp);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltSchedulePlanTmp, 'IMP_FAL_SCHEDULE_PLAN_ID', lSchedulePlanTmpId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltSchedulePlanTmp, 'EXCEL_LINE', trim(iExcelLine) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltSchedulePlanTmp, 'SCH_REF', trim(iSchRef) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltSchedulePlanTmp, 'SCH_SHORT_DESCR', trim(iSchShortDescr) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltSchedulePlanTmp, 'SCH_LONG_DESCR', trim(iSchLongDescr) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltSchedulePlanTmp, 'SCH_FREE_DESCR', trim(iSchFreeDescr) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltSchedulePlanTmp, 'C_SCHEDULE_PLANNING', nvl(trim(iCSchedulePlanning), '3') );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltSchedulePlanTmp, 'A_IDCRE', IMP_LIB_TOOLS.GetImportUserIni);
      FWK_I_MGT_ENTITY.InsertEntity(ltSchedulePlanTmp);
      FWK_I_MGT_ENTITY.Release(ltSchedulePlanTmp);
    end if;

    -- Insertion du taux dans l'entité IMP_FAL_FACTORY_RATE
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_IMP_ENTITY.gcImpFalListStepLink, ltListStepLinkTmp);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'IMP_FAL_SCHEDULE_PLAN_ID', lSchedulePlanTmpId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'EXCEL_LINE', trim(iExcelLine) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_STEP_NUMBER', trim(iScsStepNumber) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'FAL_TASK_ID', trim(iFalTaskId) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_WORK_TIME', trim(iScsWorkTime) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_QTY_REF_WORK', nvl(trim(iScsQtyRefWork), 1) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_WORK_RATE', nvl(trim(iScsWorkRate), 1) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_AMOUNT', nvl(trim(iScsAmount), 0) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_QTY_REF_AMOUNT', nvl(trim(iScsQtyRefAmount), 1) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_DIVISOR_AMOUNT', nvl(trim(iScsDivisorAmount), 0) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_PLAN_RATE', nvl(trim(iScsPlanRate), 0) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_SHORT_DESCR', trim(iScsShortDescr) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_LONG_DESCR', trim(iScsLongDescr) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_FREE_DESCR', trim(iScsFreeDescr) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'PAC_SUPPLIER_PARTNER_ID', trim(iPacSupplierPartnerId) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'FAL_FACTORY_FLOOR_ID', trim(iFalFactoryFloorId) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'GCO_GCO_GOOD_ID', trim(iGcoGcoGoodId) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'C_OPERATION_TYPE', nvl(trim(iCOperationType), 1) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_ADJUSTING_TIME', trim(iScsAdjustingTime) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_PLAN_PROP', nvl(trim(iScsPlanProp), 0) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'C_TASK_IMPUTATION', nvl(trim(iCTaskImputation), '1') );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_TRANSFERT_TIME', nvl(trim(iScsTransfertTime), 0) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_QTY_FIX_ADJUSTING', nvl(trim(iScsQtyFixAdjusting), 0) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_ADJUSTING_RATE', nvl(trim(iScsAdjustingRate), 2) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'C_RELATION_TYPE', nvl(trim(iCRelationType), '1') );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_DELAY', nvl(trim(iScsDelay), 0) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'FAL_FAL_FACTORY_FLOOR_ID', trim(iFalFalFactoryFloorId) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_NUM_FLOOR', trim(iScsNumFloor) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_ADJUSTING_FLOOR', nvl(trim(iScsAdjustingFloor), 0) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_ADJUSTING_OPERATOR', nvl(trim(iScsAdjustingOperator), 0) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_NUM_ADJUST_OPERATOR', nvl(trim(iScsNumAdjustOperator), 1) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_PERCENT_ADJUST_OPER', nvl(trim(iScsPercentAdjustOper), 100) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_WORK_FLOOR', nvl(trim(iScsWorkFloor), 0) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_WORK_OPERATOR', nvl(trim(iScsWorkOperator), 0) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_NUM_WORK_OPERATOR', nvl(trim(iScsNumWorkOperator), 1) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_PERCENT_WORK_OPER', nvl(trim(iScsPercentWorkOper), 100) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_WEIGH', nvl(trim(iScsWeigh), 0) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'SCS_WEIGH_MANDATORY', nvl(trim(iScsWeighMandatory), 0) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'FREE1', trim(iFree6) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'FREE2', trim(iFree7) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'FREE3', trim(iFree8) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'FREE4', trim(iFree9) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'FREE5', trim(iFree10) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'FREE6', trim(iFree6) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'FREE7', trim(iFree7) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'FREE8', trim(iFree8) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'FREE9', trim(iFree9) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'FREE10', trim(iFree10) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkTmp, 'A_IDCRE', IMP_LIB_TOOLS.GetImportUserIni);
    FWK_I_MGT_ENTITY.InsertEntity(ltListStepLinkTmp);
    FWK_I_MGT_ENTITY.Release(ltListStepLinkTmp);
    oResult  := 1;
    commit;
  end IMP_TMP_FAL_SCHEDULE_PLAN;

  /**
  * Description
  *    Contrôle des données de la table IMP_FAL_FACTORY_FLOOR (Ateliers) avant importation.
  */
  procedure IMP_FAL_FACTORY_FLOOR_CTRL
  as
    lExists       number;
    lErrMsg       varchar2(32767);
    lNbLinkedRes  number;
    lNbFreeRes    number;
    lFacResNumber number;
    lcDomain      varchar2(30)    := 'FAL_FACTORY_FLOOR';
  begin
    --Effacement des erreurs
    IMP_PRC_TOOLS.deleteErrors(lcDomain);

    --Parcours de tous les enregistrements de la table IMP_FAL_FACTORY_FLOOR
    for ltplFacFloor in (select *
                           from IMP_FAL_FACTORY_FLOOR) loop
      -- ***** Contrôle des champs obligatoires *****
      if ltplFacFloor.FAC_REFERENCE is null then
        IMP_PRC_TOOLS.insertError(lcDomain, ltplFacFloor.IMP_FAL_FACTORY_FLOOR_ID, ltplFacFloor.EXCEL_LINE, pcs.PC_FUNCTIONS.TranslateWord('IMP_REQUIRED') );
      else
        -- ***** Contrôle des booleans *****
        IMP_PRC_TOOLS.checkBooleanValue('FAC_IS_BLOCK', ltplFacFloor.FAC_IS_BLOCK, lcDomain, ltplFacFloor.IMP_FAL_FACTORY_FLOOR_ID, ltplFacFloor.EXCEL_LINE);
        IMP_PRC_TOOLS.checkBooleanValue('FAC_IS_MACHINE', ltplFacFloor.FAC_IS_MACHINE, lcDomain, ltplFacFloor.IMP_FAL_FACTORY_FLOOR_ID
                                      , ltplFacFloor.EXCEL_LINE);
        IMP_PRC_TOOLS.checkBooleanValue('FAC_IS_PERSON', ltplFacFloor.FAC_IS_PERSON, lcDomain, ltplFacFloor.IMP_FAL_FACTORY_FLOOR_ID, ltplFacFloor.EXCEL_LINE);
        IMP_PRC_TOOLS.checkBooleanValue('FAC_IS_OPERATOR'
                                      , ltplFacFloor.FAC_IS_OPERATOR
                                      , lcDomain
                                      , ltplFacFloor.IMP_FAL_FACTORY_FLOOR_ID
                                      , ltplFacFloor.EXCEL_LINE
                                       );
        IMP_PRC_TOOLS.checkBooleanValue('FAC_PIC', ltplFacFloor.FAC_PIC, lcDomain, ltplFacFloor.IMP_FAL_FACTORY_FLOOR_ID, ltplFacFloor.EXCEL_LINE);
        IMP_PRC_TOOLS.checkBooleanValue('FAC_INFINITE_FLOOR'
                                      , ltplFacFloor.FAC_INFINITE_FLOOR
                                      , lcDomain
                                      , ltplFacFloor.IMP_FAL_FACTORY_FLOOR_ID
                                      , ltplFacFloor.EXCEL_LINE
                                       );
        -- ***** Contrôle des valeurs numériques *****
        IMP_PRC_TOOLS.checkNumberValue('IMP_FAL_FACTORY_FLOOR'
                                     , 'IMP_FAL_FACTORY_FLOOR_ID'
                                     , ltplFacFloor.FAC_RESOURCE_NUMBER
                                     , lcDomain
                                     , ltplFacFloor.IMP_FAL_FACTORY_FLOOR_ID
                                     , ltplFacFloor.EXCEL_LINE
                                      );
        -- ***** Contrôle des valeurs numériques
        IMP_PRC_TOOLS.checkIntegerValue('FAC_RESOURCE_NUMBER'
                                      , ltplFacFloor.FAC_RESOURCE_NUMBER
                                      , lcDomain
                                      , ltplFacFloor.IMP_FAL_FACTORY_FLOOR_ID
                                      , ltplFacFloor.EXCEL_LINE
                                       );

        -- ***** Contrôles métiers *****
        -- Contrôle de l'absence d'une référence identique
        select count('x')
          into lExists
          from dual
         where exists(
                 select 'x'
                   from IMP_FAL_FACTORY_FLOOR
                  where upper(FAC_REFERENCE) = upper(ltplFacFloor.FAC_REFERENCE)
                    and IMP_FAL_FACTORY_FLOOR_ID <> ltplFacFloor.IMP_FAL_FACTORY_FLOOR_ID
                 union
                 select 'x'
                   from FAL_FACTORY_FLOOR
                  where upper(FAC_REFERENCE) = upper(ltplFacFloor.FAC_REFERENCE) );

        if lExists = 1 then
          IMP_PRC_TOOLS.insertError(lcDomain
                                  , ltplFacFloor.IMP_FAL_FACTORY_FLOOR_ID
                                  , ltplFacFloor.EXCEL_LINE
                                  , pcs.PC_FUNCTIONS.TranslateWord('La référence de l''atelier doit être unique dans la société.')
                                   );
        end if;

        -- Contrôle du type de l'atelier.
        if ltplFacFloor.FAC_IS_BLOCK + ltplFacFloor.FAC_IS_MACHINE + ltplFacFloor.FAC_IS_PERSON + ltplFacFloor.FAC_IS_OPERATOR <> '1' then
          lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('Incohérence dans la définition du type d''atelier.');
          lErrMsg  := lErrMsg || ' ' || pcs.PC_FUNCTIONS.TranslateWord('Un atelier doit être un îlot, une machine, un opérateur ou un groupe d''opérateur.');
          IMP_PRC_TOOLS.insertError(lcDomain, ltplFacFloor.IMP_FAL_FACTORY_FLOOR_ID, ltplFacFloor.EXCEL_LINE, lErrMsg);
        end if;

        -- Contrôle de l'existence de l'employé si renseigné.
        if ltplFacFloor.HRM_PERSON_ID is not null then
          -- Une personne ne peut être renseignée que sur un opérateur.
          if ltplFacFloor.FAC_IS_PERSON = 0 then
            IMP_PRC_TOOLS.insertError(lcDomain
                                    , ltplFacFloor.IMP_FAL_FACTORY_FLOOR_ID
                                    , ltplFacFloor.EXCEL_LINE
                                    , pcs.PC_FUNCTIONS.TranslateWord('Une personne ne peut être renseignée que sur un opérateur.')
                                     );
          -- Contrôle de l'existence de l'employé
          elsif not IMP_LIB_TOOLS.hrmEmployeeExists(ltplFacFloor.HRM_PERSON_ID) then
            lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('L''employé avec le numéro ''[XXX]'' est inexistant dans la société.');
            IMP_PRC_TOOLS.insertError(lcDomain
                                    , ltplFacFloor.IMP_FAL_FACTORY_FLOOR_ID
                                    , ltplFacFloor.EXCEL_LINE
                                    , replace(lErrMsg, '[XXX]', ltplFacFloor.HRM_PERSON_ID)
                                     );
          end if;
        end if;

        -- Contrôle de l'existence du centre d'analyse si renseignée
        if     ltplFacFloor.ACS_CDA_ACCOUNT_ID is not null
           and not IMP_LIB_TOOLS.cdaAccountExists(ltplFacFloor.ACS_CDA_ACCOUNT_ID) then
          lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('Le centre d''analyse avec le numéro ''[XXX]'' est inexistant dans la société.');
          IMP_PRC_TOOLS.insertError(lcDomain
                                  , ltplFacFloor.IMP_FAL_FACTORY_FLOOR_ID
                                  , ltplFacFloor.EXCEL_LINE
                                  , replace(lErrMsg, '[XXX]', ltplFacFloor.ACS_CDA_ACCOUNT_ID)
                                   );
        end if;

        -- Contrôle de l'existence de la nature analytique si renseignée
        if     ltplFacFloor.GAL_COST_CENTER_ID is not null
           and not IMP_LIB_TOOLS.costCenterExists(ltplFacFloor.GAL_COST_CENTER_ID) then
          lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('La nature analytique avec le code ''[XXX]'' est inexistante dans la société.');
          IMP_PRC_TOOLS.insertError(lcDomain
                                  , ltplFacFloor.IMP_FAL_FACTORY_FLOOR_ID
                                  , ltplFacFloor.EXCEL_LINE
                                  , replace(lErrMsg, '[XXX]', ltplFacFloor.GAL_COST_CENTER_ID)
                                   );
        end if;

        -- Contrôle de l'existence du calendrier
        if not IMP_LIB_TOOLS.scheduleExists(ltplFacFloor.PAC_SCHEDULE_ID) then
          lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('Le calendrier avec la description ''[XXX]'' est inexistant dans la société.');
          IMP_PRC_TOOLS.insertError(lcDomain
                                  , ltplFacFloor.IMP_FAL_FACTORY_FLOOR_ID
                                  , ltplFacFloor.EXCEL_LINE
                                  , replace(lErrMsg, '[XXX]', ltplFacFloor.PAC_SCHEDULE_ID)
                                   );
        end if;

        if     ltplFacFloor.FAC_IS_MACHINE = 0
           and ltplFacFloor.FAL_FAL_FACTORY_FLOOR_ID is not null then
          IMP_PRC_TOOLS.insertError(lcDomain
                                  , ltplFacFloor.IMP_FAL_FACTORY_FLOOR_ID
                                  , ltplFacFloor.EXCEL_LINE
                                  , pcs.PC_FUNCTIONS.TranslateWord('Un îlot ne peut être renseigné que sur une machine.')
                                   );
        end if;

        -- S'il s'agit d'une machine, contrôle de l'existence d'un îlot.
        if ltplFacFloor.FAC_IS_MACHINE = 1 then
          if ltplFacFloor.FAL_FAL_FACTORY_FLOOR_ID is null then
            lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('La référence de l''îlot est obligatoire pour une machine');
            IMP_PRC_TOOLS.insertError(lcDomain
                                    , ltplFacFloor.IMP_FAL_FACTORY_FLOOR_ID
                                    , ltplFacFloor.EXCEL_LINE
                                    , replace(lErrMsg, '[XXX]', ltplFacFloor.FAL_FAL_FACTORY_FLOOR_ID)
                                     );
          elsif not IMP_LIB_TOOLS.blockExists(ltplFacFloor.FAL_FAL_FACTORY_FLOOR_ID) then
            lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('L''îlot avec la référence ''[XXX]'' est inexistant dans la société.');
            IMP_PRC_TOOLS.insertError(lcDomain
                                    , ltplFacFloor.IMP_FAL_FACTORY_FLOOR_ID
                                    , ltplFacFloor.EXCEL_LINE
                                    , replace(lErrMsg, '[XXX]', ltplFacFloor.FAL_FAL_FACTORY_FLOOR_ID)
                                     );
          else
            -- Contrôler que l'îlot ait suffisamment de "place" (FAC_RESSOURCE_NUMBER >= au nombre de machines liées)
            select sum(MACHINES_LIEES)
              into lNbLinkedRes
              from (select count('x') MACHINES_LIEES   -- machine liées dans l'ERP
                      from FAL_FACTORY_FLOOR ilots
                         , FAL_FACTORY_FLOOR machines
                     where machines.FAL_FAL_FACTORY_FLOOR_ID = ilots.FAL_FACTORY_FLOOR_ID
                       and upper(ilots.FAC_REFERENCE) = upper(ltplFacFloor.FAL_FAL_FACTORY_FLOOR_ID)
                    union
                    select count('x') MACHINES_LIEES   --
                      from IMP_FAL_FACTORY_FLOOR ilots
                         , IMP_FAL_FACTORY_FLOOR machines
                     where upper(machines.FAL_FAL_FACTORY_FLOOR_ID) = upper(ilots.FAC_REFERENCE)
                       and upper(ilots.FAC_REFERENCE) = upper(ltplFacFloor.FAL_FAL_FACTORY_FLOOR_ID) );

            select sum(FAC_RESOURCE_NUMBER)
              into lFacResNumber
              from FAL_FACTORY_FLOOR
             where upper(FAC_REFERENCE) = upper(ltplFacFloor.FAL_FAL_FACTORY_FLOOR_ID);

            if (lNbLinkedRes - lFacResNumber < 0) then
              lErrMsg  :=
                pcs.PC_FUNCTIONS.TranslateWord
                                           ('Le nombre de ressources affectées ([XXX]) de l''îlot ''[YYY]'' est inférieur au nombre de machines liées ([ZZZ]).');
              IMP_PRC_TOOLS.insertError(lcDomain
                                      , ltplFacFloor.IMP_FAL_FACTORY_FLOOR_ID
                                      , ltplFacFloor.EXCEL_LINE
                                      , replace(replace(replace(lErrMsg, '[XXX]', lFacResNumber), '[YYY]', ltplFacFloor.FAL_FAL_FACTORY_FLOOR_ID)
                                              , '[ZZZ]'
                                              , lNbLinkedRes
                                               )
                                       );
            end if;
          end if;
        -- S'il s'agit d'un opérateur, contrôle de l'existence d'un groupe d'opérateurs.
        elsif ltplFacFloor.FAC_IS_PERSON = 1 then
          if ltplFacFloor.FAL_GRP_FACTORY_FLOOR_ID is null then
            lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('La référence du groupe d''opérateurs est obligatoire pour un opérateur');
            IMP_PRC_TOOLS.insertError(lcDomain
                                    , ltplFacFloor.IMP_FAL_FACTORY_FLOOR_ID
                                    , ltplFacFloor.EXCEL_LINE
                                    , replace(lErrMsg, '[XXX]', ltplFacFloor.FAL_GRP_FACTORY_FLOOR_ID)
                                     );
          elsif not IMP_LIB_TOOLS.operatorExists(ltplFacFloor.FAL_GRP_FACTORY_FLOOR_ID) then
            lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('Le groupe d''opérateurs avec la référence ''[XXX]'' est inexistant dans la société.');
            IMP_PRC_TOOLS.insertError(lcDomain
                                    , ltplFacFloor.IMP_FAL_FACTORY_FLOOR_ID
                                    , ltplFacFloor.EXCEL_LINE
                                    , replace(lErrMsg, '[XXX]', ltplFacFloor.FAL_GRP_FACTORY_FLOOR_ID)
                                     );
          else
            -- Contrôler que le groupe d'opérateurs ait suffisamment de "place" (FAC_RESSOURCE_NUMBER >= au nombre d'opérateurs liés)
            select sum(OPERATEURS_LIES)
              into lNbLinkedRes
              from (select count('x') OPERATEURS_LIES
                      from FAL_FACTORY_FLOOR grp_oper
                         , FAL_FACTORY_FLOOR operateurs
                     where operateurs.FAL_FAL_FACTORY_FLOOR_ID = grp_oper.FAL_FACTORY_FLOOR_ID
                       and upper(grp_oper.FAC_REFERENCE) = upper(ltplFacFloor.FAL_GRP_FACTORY_FLOOR_ID)
                    union
                    select count('x') OPERATEURS_LIES
                      from IMP_FAL_FACTORY_FLOOR grp_oper
                         , IMP_FAL_FACTORY_FLOOR operateurs
                     where upper(operateurs.FAL_FAL_FACTORY_FLOOR_ID) = upper(grp_oper.FAC_REFERENCE)
                       and upper(grp_oper.FAC_REFERENCE) = upper(ltplFacFloor.FAL_GRP_FACTORY_FLOOR_ID) );

            select sum(FAC_RESOURCE_NUMBER)
              into lFacResNumber
              from FAL_FACTORY_FLOOR
             where upper(FAC_REFERENCE) = upper(ltplFacFloor.FAL_GRP_FACTORY_FLOOR_ID);

            if (lNbLinkedRes - lFacResNumber < 0) then
              lErrMsg  :=
                pcs.PC_FUNCTIONS.TranslateWord
                               ('Le nombre d''opérateur affectés ([XXX]) du groupe d''opérateurs ''[YYY]'' est inférieur au nombre d''opérateurs liés ([ZZZ]).');
              IMP_PRC_TOOLS.insertError(lcDomain
                                      , ltplFacFloor.IMP_FAL_FACTORY_FLOOR_ID
                                      , ltplFacFloor.EXCEL_LINE
                                      , replace(replace(replace(lErrMsg, '[XXX]', lFacResNumber), '[YYY]', ltplFacFloor.FAL_GRP_FACTORY_FLOOR_ID)
                                              , '[ZZZ]'
                                              , lNbLinkedRes
                                               )
                                       );
            end if;
          end if;
        end if;
      end if;
    end loop;

    --Parcours de tous les enregistrements de la table IMP_FAL_FACTORY_RATE
    for ltplFacRate in (select *
                          from IMP_FAL_FACTORY_RATE) loop
      -- ***** Contrôle des valeurs numériques
      -- Les taux horaires doivent être positifs (zéro inclus).
      IMP_PRC_TOOLS.checkNumberValue('IMP_FAL_FACTORY_RATE'
                                   , 'FFR_RATE1'
                                   , ltplFacRate.FFR_RATE1
                                   , lcDomain
                                   , ltplFacRate.IMP_FAL_FACTORY_RATE_ID
                                   , ltplFacRate.EXCEL_LINE
                                   , true
                                    );
      IMP_PRC_TOOLS.checkNumberValue('IMP_FAL_FACTORY_RATE'
                                   , 'FFR_RATE2'
                                   , ltplFacRate.FFR_RATE2
                                   , lcDomain
                                   , ltplFacRate.IMP_FAL_FACTORY_RATE_ID
                                   , ltplFacRate.EXCEL_LINE
                                   , true
                                    );
      IMP_PRC_TOOLS.checkNumberValue('IMP_FAL_FACTORY_RATE'
                                   , 'FFR_RATE3'
                                   , ltplFacRate.FFR_RATE3
                                   , lcDomain
                                   , ltplFacRate.IMP_FAL_FACTORY_RATE_ID
                                   , ltplFacRate.EXCEL_LINE
                                   , true
                                    );
      IMP_PRC_TOOLS.checkNumberValue('IMP_FAL_FACTORY_RATE'
                                   , 'FFR_RATE4'
                                   , ltplFacRate.FFR_RATE4
                                   , lcDomain
                                   , ltplFacRate.IMP_FAL_FACTORY_RATE_ID
                                   , ltplFacRate.EXCEL_LINE
                                   , true
                                    );
      IMP_PRC_TOOLS.checkNumberValue('IMP_FAL_FACTORY_RATE'
                                   , 'FFR_RATE5'
                                   , ltplFacRate.FFR_RATE5
                                   , lcDomain
                                   , ltplFacRate.IMP_FAL_FACTORY_RATE_ID
                                   , ltplFacRate.EXCEL_LINE
                                   , true
                                    );

      -- ***** Contrôles métiers *****
      if     ltplFacRate.FFR_VALIDITY_DATE is null
         and (ltplFacRate.FFR_RATE1 + ltplFacRate.FFR_RATE2 + ltplFacRate.FFR_RATE3 + ltplFacRate.FFR_RATE4 + ltplFacRate.FFR_RATE5 > 0) then
        IMP_PRC_TOOLS.insertError(lcDomain
                                , ltplFacRate.IMP_FAL_FACTORY_RATE_ID
                                , ltplFacRate.EXCEL_LINE
                                , pcs.PC_FUNCTIONS.TranslateWord('La date de validité est obligatoire si un taux horaire est renseigné.')
                                 );
      end if;
    end loop;

    --Si la table d'erreurs est vide, alors on insère le message repris par le pilotage de contrôle indiquant l'absence d'erreur
    IMP_PRC_TOOLS.checkErrors(lcDomain);
    commit;
  end IMP_FAL_FACTORY_FLOOR_CTRL;

  /**
  * Description
  *    Contrôle des données de la table IMP_FAL_TASK (opérations standards) avant importation.
  */
  procedure IMP_FAL_TASK_CTRL
  as
    lExists  integer;
    lErrMsg  varchar2(32767);
    lcDomain varchar2(30)    := 'FAL_TASK';
  begin
    --Effacement des tables d'erreurs
    IMP_PRC_TOOLS.deleteErrors(lcDomain);

    --Parcours de tous les enregistrements de la table IMP_FAL_TASK
    for ltplTask in (select *
                       from IMP_FAL_TASK) loop
      -- ***** Contrôle des champs obligatoires *****
      if (   ltplTask.C_TASK_TYPE is null
          or ltplTask.TAS_REF is null) then
        IMP_PRC_TOOLS.insertError(lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE, pcs.PC_FUNCTIONS.TranslateWord('IMP_REQUIRED') );
      else
        -- ***** Contrôle des booleans *****
        IMP_PRC_TOOLS.checkBooleanValue('TAS_ADJUSTING_FLOOR', ltplTask.TAS_ADJUSTING_FLOOR, lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE);
        IMP_PRC_TOOLS.checkBooleanValue('TAS_ADJUSTING_OPERATOR', ltplTask.TAS_ADJUSTING_OPERATOR, lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE);
        IMP_PRC_TOOLS.checkBooleanValue('TAS_WORK_FLOOR', ltplTask.TAS_WORK_FLOOR, lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE);
        IMP_PRC_TOOLS.checkBooleanValue('TAS_WORK_OPERATOR', ltplTask.TAS_WORK_OPERATOR, lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE);
        IMP_PRC_TOOLS.checkBooleanValue('TAS_WEIGH', ltplTask.TAS_WEIGH, lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE);
        IMP_PRC_TOOLS.checkBooleanValue('TAS_WEIGH_MANDATORY', ltplTask.TAS_WEIGH_MANDATORY, lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE);
        IMP_PRC_TOOLS.checkBooleanValue('TAS_DIVISOR_AMOUNT', ltplTask.TAS_DIVISOR_AMOUNT, lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE);
        IMP_PRC_TOOLS.checkBooleanValue('TAS_PLAN_PROP', ltplTask.TAS_PLAN_PROP, lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE);
        -- ***** Contrôle des descodes *****
        IMP_PRC_TOOLS.checkDescodeValue('C_TASK_TYPE', ltplTask.C_TASK_TYPE, '{1,2}', lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE);
        IMP_PRC_TOOLS.checkDescodeValue('C_SCHEDULE_PLANNING', ltplTask.C_SCHEDULE_PLANNING, '{1,2,3}', lcDomain, ltplTask.IMP_FAL_TASK_ID
                                      , ltplTask.EXCEL_LINE);
        IMP_PRC_TOOLS.checkDescodeValue('C_TASK_IMPUTATION', ltplTask.C_TASK_IMPUTATION, '{1,2,3,4}', lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE);
        IMP_PRC_TOOLS.checkDescodeValue('TAS_ADJUSTING_RATE'
                                      , ltplTask.TAS_ADJUSTING_RATE
                                      , '{1,2,3,4,5}'
                                      , lcDomain
                                      , ltplTask.IMP_FAL_TASK_ID
                                      , ltplTask.EXCEL_LINE
                                       );
        IMP_PRC_TOOLS.checkDescodeValue('TAS_WORK_RATE', ltplTask.TAS_WORK_RATE, '{1,2,3,4,5}', lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE);
        -- ***** Contrôle des valeurs numériques
        -- Le temps de transfert doit être supérieur ou égal à zéro.
        IMP_PRC_TOOLS.checkNumberValue('IMP_FAL_TASK'
                                     , 'TAS_TRANSFERT_TIME'
                                     , ltplTask.TAS_TRANSFERT_TIME
                                     , lcDomain
                                     , ltplTask.IMP_FAL_TASK_ID
                                     , ltplTask.EXCEL_LINE
                                     , true
                                      );
        -- le montant doit être supérieur ou égal à zéro.
        IMP_PRC_TOOLS.checkNumberValue('IMP_FAL_TASK', 'TAS_AMOUNT', ltplTask.TAS_AMOUNT, lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE, true);
        -- la quantité de référence pour le montant doit être supérieure ou égale à zéro.
        IMP_PRC_TOOLS.checkNumberValue('IMP_FAL_TASK'
                                     , 'TAS_QTY_REF_AMOUNT'
                                     , ltplTask.TAS_QTY_REF_AMOUNT
                                     , lcDomain
                                     , ltplTask.IMP_FAL_TASK_ID
                                     , ltplTask.EXCEL_LINE
                                     , true
                                      );
        -- le temps de planification doit être supérieur ou égal à zéro.
        IMP_PRC_TOOLS.checkNumberValue('IMP_FAL_TASK', 'TAS_PLAN_RATE', ltplTask.TAS_PLAN_RATE, lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE, true);
        -- Le nombre de ressources allouées doit être supérieur à zéro.
        IMP_PRC_TOOLS.checkNumberValue('IMP_FAL_TASK', 'TAS_NUM_FLOOR', ltplTask.TAS_NUM_FLOOR, lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE);
        IMP_PRC_TOOLS.checkNumberValue('IMP_FAL_TASK'
                                     , 'TAS_NUM_ADJUST_OPERATOR'
                                     , ltplTask.TAS_NUM_ADJUST_OPERATOR
                                     , lcDomain
                                     , ltplTask.IMP_FAL_TASK_ID
                                     , ltplTask.EXCEL_LINE
                                      );
        IMP_PRC_TOOLS.checkNumberValue('IMP_FAL_TASK'
                                     , 'TAS_PERCENT_ADJUST_OPER'
                                     , ltplTask.TAS_PERCENT_ADJUST_OPER
                                     , lcDomain
                                     , ltplTask.IMP_FAL_TASK_ID
                                     , ltplTask.EXCEL_LINE
                                     , true
                                      );
        IMP_PRC_TOOLS.checkNumberValue('IMP_FAL_TASK'
                                     , 'TAS_NUM_WORK_OPERATOR'
                                     , ltplTask.TAS_NUM_WORK_OPERATOR
                                     , lcDomain
                                     , ltplTask.IMP_FAL_TASK_ID
                                     , ltplTask.EXCEL_LINE
                                      );
        IMP_PRC_TOOLS.checkNumberValue('IMP_FAL_TASK'
                                     , 'TAS_PERCENT_WORK_OPER'
                                     , ltplTask.TAS_PERCENT_WORK_OPER
                                     , lcDomain
                                     , ltplTask.IMP_FAL_TASK_ID
                                     , ltplTask.EXCEL_LINE
                                     , true
                                      );
        -- ***** Contrôle des valeurs entières *****
        IMP_PRC_TOOLS.checkIntegerValue('TAS_NUM_FLOOR', ltplTask.TAS_NUM_FLOOR, lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE);
        IMP_PRC_TOOLS.checkIntegerValue('TAS_NUM_ADJUST_OPERATOR', ltplTask.TAS_NUM_ADJUST_OPERATOR, lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE);
        IMP_PRC_TOOLS.checkIntegerValue('TAS_PERCENT_ADJUST_OPER', ltplTask.TAS_PERCENT_ADJUST_OPER, lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE);
        IMP_PRC_TOOLS.checkIntegerValue('TAS_NUM_WORK_OPERATOR', ltplTask.TAS_NUM_WORK_OPERATOR, lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE);
        IMP_PRC_TOOLS.checkIntegerValue('TAS_PERCENT_WORK_OPER', ltplTask.TAS_PERCENT_WORK_OPER, lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE);

        -- ***** Contrôles métiers *****
        -- Contrôle de l'absence d'une référence identique
        select count('x')
          into lExists
          from dual
         where exists(
                      select 'x'
                        from IMP_FAL_TASK
                       where upper(TAS_REF) = upper(ltplTask.TAS_REF)
                         and IMP_FAL_TASK_ID <> ltplTask.IMP_FAL_TASK_ID
                      union
                      select 'x'
                        from FAL_TASK
                       where upper(TAS_REF) = upper(ltplTask.TAS_REF) );

        if lExists = 1 then
          lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('La référence ''[XXX]'' de l''opération doit être unique dans la société.');
          IMP_PRC_TOOLS.insertError(lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE, replace(lErrMsg, '[XXX]', ltplTask.TAS_REF) );
        end if;

        if ltplTask.C_TASK_TYPE = '1' then
          -- L'atelier doit être fourni et exister pour une opération interne
          if ltplTask.FAL_FACTORY_FLOOR_ID is null then
            IMP_PRC_TOOLS.insertError(lcDomain
                                    , ltplTask.IMP_FAL_TASK_ID
                                    , ltplTask.EXCEL_LINE
                                    , pcs.PC_FUNCTIONS.TranslateWord('La référence de l''atelier est obligatoire pour une opération interne.')
                                     );
          elsif not IMP_LIB_TOOLS.factoryFloorExists(ltplTask.FAL_FACTORY_FLOOR_ID) then
            lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('L''atelier avec la référence ''[XXX]'' est inexistant dans la société.');
            IMP_PRC_TOOLS.insertError(lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE, replace(lErrMsg, '[XXX]', ltplTask.FAL_FACTORY_FLOOR_ID) );
          end if;

          if ltplTask.PAC_SUPPLIER_PARTNER_ID is not null then
            lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('Le fournisseur ne doit pas être renseigné sur une opération interne.');
            IMP_PRC_TOOLS.insertError(lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE, lErrMsg);
          end if;

          if ltplTask.GCO_GCO_GOOD_ID is not null then
            lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('Le bien connecté ne doit pas être renseigné sur une opération interne.');
            IMP_PRC_TOOLS.insertError(lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE, lErrMsg);
          end if;
        else
          -- Le service et le bien connecté doivent être fournis et exister pour une opération externe
          if ltplTask.PAC_SUPPLIER_PARTNER_ID is null then
            IMP_PRC_TOOLS.insertError(lcDomain
                                    , ltplTask.IMP_FAL_TASK_ID
                                    , ltplTask.EXCEL_LINE
                                    , pcs.PC_FUNCTIONS.TranslateWord('Le fournisseur est obligatoire pour une opération externe.')
                                     );
          elsif not IMP_LIB_TOOLS.supplierKey2Exists(ltplTask.PAC_SUPPLIER_PARTNER_ID) then
            lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('Le fournisseur ave la clef 2 ''[XXX]'' est inexistant dans la société.');
            IMP_PRC_TOOLS.insertError(lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE, replace(lErrMsg, '[XXX]', ltplTask.FAL_FACTORY_FLOOR_ID) );
          end if;

          if ltplTask.GCO_GCO_GOOD_ID is null then
            IMP_PRC_TOOLS.insertError(lcDomain
                                    , ltplTask.IMP_FAL_TASK_ID
                                    , ltplTask.EXCEL_LINE
                                    , pcs.PC_FUNCTIONS.TranslateWord('Le bien connecté est obligatoire pour une opération externe.')
                                     );
          elsif not IMP_LIB_TOOLS.serviceExists(ltplTask.GCO_GCO_GOOD_ID) then
            lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('Le bien connecté avec la référence ''[XXX]'' est inexistant dans la société.');
            IMP_PRC_TOOLS.insertError(lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE, replace(lErrMsg, '[XXX]', ltplTask.GCO_GCO_GOOD_ID) );
          end if;

          if ltplTask.FAL_FACTORY_FLOOR_ID is not null then
            lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('L''atelier ne doit pas être renseigné sur une opération externe.');
            IMP_PRC_TOOLS.insertError(lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE, lErrMsg);
          end if;

          if ltplTask.FAL_FAL_FACTORY_FLOOR_ID is not null then
            lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('L''opérateur ne doit pas être renseigné sur une opération externe.');
            IMP_PRC_TOOLS.insertError(lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE, lErrMsg);
          end if;
        end if;

        -- Si renseigné, l'opérateur doit exister
        if     ltplTask.FAL_FAL_FACTORY_FLOOR_ID is not null
           and not IMP_LIB_TOOLS.factoryFloorExists(ltplTask.FAL_FAL_FACTORY_FLOOR_ID) then
          lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('L''opérateur avec la référence ''[XXX]'' est inexistant dans la société.');
          IMP_PRC_TOOLS.insertError(lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE, replace(lErrMsg, '[XXX]', ltplTask.FAL_FAL_FACTORY_FLOOR_ID) );
        end if;

        -- Cohérence entre la case diviseur et la qté réf. montant. On ne doit pas diviser par 0.
        if     ltplTask.TAS_DIVISOR_AMOUNT = 1
           and ltplTask.TAS_QTY_REF_AMOUNT = 0 then
          lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('Incohérence : la qté réf. montant ne peut pas être égale à 0 si le champ Diviseur est à 1.');
          IMP_PRC_TOOLS.insertError(lcDomain, ltplTask.IMP_FAL_TASK_ID, ltplTask.EXCEL_LINE, lErrMsg);
        end if;
      end if;
    end loop;

    --Si la table d'erreurs est vide, alors on insère le message repris par le pilotage de contrôle indiquant l'absence d'erreur
    IMP_PRC_TOOLS.checkErrors(lcDomain);
    commit;
  end IMP_FAL_TASK_CTRL;

  /**
  * Description
  *    Contrôle des données de la table IMP_FAL_SCHEDULE_PLAN (gammes opératoires) avant importation.
  */
  procedure IMP_FAL_SCHEDULE_PLAN_CTRL
  as
    lExists  integer;
    lErrMsg  varchar2(32767);
    lcDomain varchar2(30)                := 'FAL_SCHEDULE_PLAN';
    lTaskId  FAL_TASK.FAL_TASK_ID%type;
  begin
    --Effacement des tables d'erreurs
    IMP_PRC_TOOLS.deleteErrors(lcDomain);

    --Parcours de tous les enregistrements de la table IMP_FAL_SCHEDULE_PLAN
    for tdata in (select *
                    from IMP_FAL_SCHEDULE_PLAN) loop
      -- ***** Contrôle des champs obligatoires *****
      if (   tdata.SCH_REF is null
          or tdata.C_SCHEDULE_PLANNING is null) then
        IMP_PRC_TOOLS.insertError(lcDomain, tdata.IMP_FAL_SCHEDULE_PLAN_ID, tdata.EXCEL_LINE, pcs.PC_FUNCTIONS.TranslateWord('IMP_REQUIRED') );
      else
        -- ***** Contrôle des descodes *****
        IMP_PRC_TOOLS.checkDescodeValue('C_SCHEDULE_PLANNING', tdata.C_SCHEDULE_PLANNING, '{1,2,3}', lcDomain, tdata.IMP_FAL_SCHEDULE_PLAN_ID
                                      , tdata.EXCEL_LINE);

        -- ***** Contrôles métiers *****
        -- Vérifier l'unicité de la référence de la gamme
        if IMP_LIB_TOOLS.schedulePlanExists(tdata.SCH_REF) then
          lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('La référence de la gamme ''[XXX]'' est déjà existante dans la société.');
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.IMP_FAL_SCHEDULE_PLAN_ID, tdata.EXCEL_LINE, replace(lErrMsg, '[XXX]', tdata.SCH_REF) );
        end if;

        -- Parcours des opérations de la gamme en cours de contrôle.
        for ltplStep in (select *
                           from IMP_FAL_LIST_STEP_LINK
                          where IMP_FAL_SCHEDULE_PLAN_ID = tdata.IMP_FAL_SCHEDULE_PLAN_ID) loop
          -- ***** Contrôle des champs obligatoires *****
          if (   ltplStep.SCS_STEP_NUMBER is null
              or ltplStep.FAL_TASK_ID is null
              or ltplStep.C_OPERATION_TYPE is null) then
            IMP_PRC_TOOLS.insertError(lcDomain, ltplStep.IMP_FAL_LIST_STEP_LINK_ID, ltplStep.EXCEL_LINE, pcs.PC_FUNCTIONS.TranslateWord('IMP_REQUIRED') );
          else
            -- ***** Contrôle des booleans *****
            IMP_PRC_TOOLS.checkBooleanValue('SCS_ADJUSTING_FLOOR'
                                          , ltplStep.SCS_ADJUSTING_FLOOR
                                          , lcDomain
                                          , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                          , ltplStep.EXCEL_LINE
                                           );
            IMP_PRC_TOOLS.checkBooleanValue('SCS_ADJUSTING_OPERATOR'
                                          , ltplStep.SCS_ADJUSTING_OPERATOR
                                          , lcDomain
                                          , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                          , ltplStep.EXCEL_LINE
                                           );
            IMP_PRC_TOOLS.checkBooleanValue('SCS_WORK_FLOOR', ltplStep.SCS_WORK_FLOOR, lcDomain, ltplStep.IMP_FAL_LIST_STEP_LINK_ID, ltplStep.EXCEL_LINE);
            IMP_PRC_TOOLS.checkBooleanValue('SCS_WORK_OPERATOR', ltplStep.SCS_WORK_OPERATOR, lcDomain, ltplStep.IMP_FAL_LIST_STEP_LINK_ID, ltplStep.EXCEL_LINE);
            IMP_PRC_TOOLS.checkBooleanValue('SCS_WEIGH', ltplStep.SCS_WEIGH, lcDomain, ltplStep.IMP_FAL_LIST_STEP_LINK_ID, ltplStep.EXCEL_LINE);
            IMP_PRC_TOOLS.checkBooleanValue('SCS_WEIGH_MANDATORY'
                                          , ltplStep.SCS_WEIGH_MANDATORY
                                          , lcDomain
                                          , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                          , ltplStep.EXCEL_LINE
                                           );
            IMP_PRC_TOOLS.checkBooleanValue('SCS_DIVISOR_AMOUNT', ltplStep.SCS_DIVISOR_AMOUNT, lcDomain, ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                          , ltplStep.EXCEL_LINE);
            IMP_PRC_TOOLS.checkBooleanValue('SCS_PLAN_PROP', ltplStep.SCS_PLAN_PROP, lcDomain, ltplStep.IMP_FAL_LIST_STEP_LINK_ID, ltplStep.EXCEL_LINE);
            -- ***** Contrôle des descodes *****
            IMP_PRC_TOOLS.checkDescodeValue('C_OPERATION_TYPE'
                                          , ltplStep.C_OPERATION_TYPE
                                          , '{1,2,3}'
                                          , lcDomain
                                          , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                          , ltplStep.EXCEL_LINE
                                           );
            IMP_PRC_TOOLS.checkDescodeValue('C_TASK_IMPUTATION'
                                          , ltplStep.C_TASK_IMPUTATION
                                          , '{1,2,3,4}'
                                          , lcDomain
                                          , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                          , ltplStep.EXCEL_LINE
                                           );
            IMP_PRC_TOOLS.checkDescodeValue('C_RELATION_TYPE'
                                          , ltplStep.C_RELATION_TYPE
                                          , '{1,2,3,4,5}'
                                          , lcDomain
                                          , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                          , ltplStep.EXCEL_LINE
                                           );
            IMP_PRC_TOOLS.checkDescodeValue('SCS_ADJUSTING_RATE'
                                          , ltplStep.SCS_ADJUSTING_RATE
                                          , '{1,2,3,4,5}'
                                          , lcDomain
                                          , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                          , ltplStep.EXCEL_LINE
                                           );
            IMP_PRC_TOOLS.checkDescodeValue('SCS_WORK_RATE'
                                          , ltplStep.SCS_WORK_RATE
                                          , '{1,2,3,4,5}'
                                          , lcDomain
                                          , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                          , ltplStep.EXCEL_LINE
                                           );
            -- ***** Contrôle des valeurs numériques *****
            IMP_PRC_TOOLS.checkNumberValue('FAL_LIST_STEP_LINK'
                                         , 'SCS_ADJUSTING_TIME'
                                         , ltplStep.SCS_ADJUSTING_TIME
                                         , lcDomain
                                         , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                         , ltplStep.EXCEL_LINE
                                         , true
                                          );
            IMP_PRC_TOOLS.checkNumberValue('FAL_LIST_STEP_LINK'
                                         , 'SCS_WORK_TIME'
                                         , ltplStep.SCS_WORK_TIME
                                         , lcDomain
                                         , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                         , ltplStep.EXCEL_LINE
                                         , true
                                          );
            IMP_PRC_TOOLS.checkNumberValue('FAL_LIST_STEP_LINK'
                                         , 'SCS_QTY_REF_WORK'
                                         , ltplStep.SCS_QTY_REF_WORK
                                         , lcDomain
                                         , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                         , ltplStep.EXCEL_LINE
                                          );
            -- Le temps de transfert doit être supérieur ou égal à zéro.
            IMP_PRC_TOOLS.checkNumberValue('FAL_LIST_STEP_LINK'
                                         , 'SCS_TRANSFERT_TIME'
                                         , ltplStep.SCS_TRANSFERT_TIME
                                         , lcDomain
                                         , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                         , ltplStep.EXCEL_LINE
                                         , true
                                          );
            -- le montant doit être supérieur ou égal à zéro.
            IMP_PRC_TOOLS.checkNumberValue('FAL_LIST_STEP_LINK'
                                         , 'SCS_AMOUNT'
                                         , ltplStep.SCS_AMOUNT
                                         , lcDomain
                                         , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                         , ltplStep.EXCEL_LINE
                                         , true
                                          );
            -- la quantité de référence pour le montant doit être supérieure ou égale à zéro.
            IMP_PRC_TOOLS.checkNumberValue('FAL_LIST_STEP_LINK'
                                         , 'SCS_QTY_REF_AMOUNT'
                                         , ltplStep.SCS_QTY_REF_AMOUNT
                                         , lcDomain
                                         , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                         , ltplStep.EXCEL_LINE
                                         , true
                                          );
            -- le temps de planification doit être supérieur ou égal à zéro.
            IMP_PRC_TOOLS.checkNumberValue('FAL_LIST_STEP_LINK'
                                         , 'SCS_PLAN_RATE'
                                         , ltplStep.SCS_PLAN_RATE
                                         , lcDomain
                                         , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                         , ltplStep.EXCEL_LINE
                                         , true
                                          );
            -- le quantité fixe de réglage doit être supérieure ou égale à zéro.
            IMP_PRC_TOOLS.checkNumberValue('FAL_LIST_STEP_LINK'
                                         , 'SCS_QTY_FIX_ADJUSTING'
                                         , ltplStep.SCS_QTY_FIX_ADJUSTING
                                         , lcDomain
                                         , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                         , ltplStep.EXCEL_LINE
                                         , true
                                          );
            -- Le nombre de ressources allouées doit être supérieur à zéro.
            IMP_PRC_TOOLS.checkNumberValue('FAL_LIST_STEP_LINK'
                                         , 'SCS_NUM_FLOOR'
                                         , ltplStep.SCS_NUM_FLOOR
                                         , lcDomain
                                         , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                         , ltplStep.EXCEL_LINE
                                          );
            -- Le nombre d'opérateur pour le réglage doit être supérieur à zéro.
            IMP_PRC_TOOLS.checkNumberValue('FAL_LIST_STEP_LINK'
                                         , 'SCS_NUM_ADJUST_OPERATOR'
                                         , ltplStep.SCS_NUM_ADJUST_OPERATOR
                                         , lcDomain
                                         , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                         , ltplStep.EXCEL_LINE
                                          );
            -- Le pourcentage des o
            IMP_PRC_TOOLS.checkNumberValue('FAL_LIST_STEP_LINK'
                                         , 'SCS_PERCENT_ADJUST_OPER'
                                         , ltplStep.SCS_PERCENT_ADJUST_OPER
                                         , lcDomain
                                         , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                         , ltplStep.EXCEL_LINE
                                         , true
                                          );
            IMP_PRC_TOOLS.checkNumberValue('FAL_LIST_STEP_LINK'
                                         , 'SCS_NUM_WORK_OPERATOR'
                                         , ltplStep.SCS_NUM_WORK_OPERATOR
                                         , lcDomain
                                         , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                         , ltplStep.EXCEL_LINE
                                          );
            IMP_PRC_TOOLS.checkNumberValue('FAL_LIST_STEP_LINK'
                                         , 'SCS_PERCENT_WORK_OPER'
                                         , ltplStep.SCS_PERCENT_WORK_OPER
                                         , lcDomain
                                         , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                         , ltplStep.EXCEL_LINE
                                         , true
                                          );
            -- ***** Contrôles métiers *****
            IMP_PRC_TOOLS.checkIntegerValue('SCS_NUM_FLOOR', ltplStep.SCS_NUM_FLOOR, lcDomain, ltplStep.IMP_FAL_LIST_STEP_LINK_ID, ltplStep.EXCEL_LINE);
            IMP_PRC_TOOLS.checkIntegerValue('SCS_NUM_ADJUST_OPERATOR'
                                          , ltplStep.SCS_NUM_ADJUST_OPERATOR
                                          , lcDomain
                                          , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                          , ltplStep.EXCEL_LINE
                                           );
            IMP_PRC_TOOLS.checkIntegerValue('SCS_PERCENT_ADJUST_OPER'
                                          , ltplStep.SCS_PERCENT_ADJUST_OPER
                                          , lcDomain
                                          , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                          , ltplStep.EXCEL_LINE
                                           );
            IMP_PRC_TOOLS.checkIntegerValue('SCS_NUM_WORK_OPERATOR'
                                          , ltplStep.SCS_NUM_WORK_OPERATOR
                                          , lcDomain
                                          , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                          , ltplStep.EXCEL_LINE
                                           );
            IMP_PRC_TOOLS.checkIntegerValue('SCS_PERCENT_WORK_OPER'
                                          , ltplStep.SCS_PERCENT_WORK_OPER
                                          , lcDomain
                                          , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                          , ltplStep.EXCEL_LINE
                                           );
            IMP_PRC_TOOLS.checkIntegerValue('SCS_NUM_FLOOR', ltplStep.SCS_NUM_FLOOR, lcDomain, ltplStep.IMP_FAL_LIST_STEP_LINK_ID, ltplStep.EXCEL_LINE);

            -- Contrôle de l'absence de référence identique pour l'opération
            select count('x')
              into lExists
              from dual
             where exists(
                     select 'x'
                       from IMP_FAL_LIST_STEP_LINK
                      where upper(SCS_STEP_NUMBER) = upper(ltplStep.SCS_STEP_NUMBER)
                        and IMP_FAL_SCHEDULE_PLAN_ID = ltplStep.IMP_FAL_SCHEDULE_PLAN_ID
                        and IMP_FAL_LIST_STEP_LINK_ID <> ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                     union
                     select 'x'
                       from FAL_LIST_STEP_LINK scs
                          , FAL_SCHEDULE_PLAN sch
                      where scs.FAL_SCHEDULE_PLAN_ID = sch.FAL_SCHEDULE_PLAN_ID
                        and upper(SCH_REF) = upper(tdata.SCH_REF)
                        and upper(scs.SCS_STEP_NUMBER) = upper(ltplStep.SCS_STEP_NUMBER) );

            if lExists = 1 then
              lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('La référence ''[XXX]'' de l''opération est déjà existante dans la gamme ''[YYY]''.');
              IMP_PRC_TOOLS.insertError(lcDomain
                                      , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                      , ltplStep.EXCEL_LINE
                                      , replace(replace(lErrMsg, '[XXX]', ltplStep.SCS_STEP_NUMBER), '[YYY]', tdata.SCH_REF)
                                       );
            end if;

            -- Contrôle de l'existence de l'opération standard
            if not IMP_LIB_TOOLS.taskExists(ltplStep.FAL_TASK_ID) then
              lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('L''opération standard avec la référence ''[XXX]'' est inexistante dans la société.');
              IMP_PRC_TOOLS.insertError(lcDomain, ltplStep.IMP_FAL_LIST_STEP_LINK_ID, ltplStep.EXCEL_LINE, replace(lErrMsg, '[XXX]', ltplStep.FAL_TASK_ID) );
            else
              lTaskId  := FWK_I_LIB_ENTITY.getIdfromPk2(FWK_I_TYP_FAL_ENTITY.gcFalTask, 'TAS_REF', ltplStep.FAL_TASK_ID);
            end if;

            if FWK_I_LIB_ENTITY.getVarchar2FieldFromPk(FWK_I_TYP_FAL_ENTITY.gcFalTask
                                                     , 'C_TASK_TYPE'
                                                     , FWK_I_LIB_ENTITY.getIdfromPk2(FWK_I_TYP_FAL_ENTITY.gcFalTask, 'TAS_REF', ltplStep.FAL_TASK_ID)
                                                      ) = '1' then
              -- L'atelier doit être fourni et exister pour une opération interne ou être renseigné sur l'opération standard.
              if     (ltplStep.FAL_FACTORY_FLOOR_ID is null)
                 and (FWK_I_LIB_ENTITY.getNumberFieldFromPk(FWK_I_TYP_FAL_ENTITY.gcFalTask, 'FAL_FACTORY_FLOOR_ID', lTaskId) is null) then
                IMP_PRC_TOOLS.insertError(lcDomain
                                        , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                        , ltplStep.EXCEL_LINE
                                        , pcs.PC_FUNCTIONS.TranslateWord('La référence de l''atelier est obligatoire sur une opération interne.')
                                         );
              elsif     (ltplStep.FAL_FACTORY_FLOOR_ID is not null)
                    and not IMP_LIB_TOOLS.factoryFloorExists(ltplStep.FAL_FACTORY_FLOOR_ID) then
                lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('L''atelier avec la référence ''[XXX]'' est inexistant dans la société.');
                IMP_PRC_TOOLS.insertError(lcDomain
                                        , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                        , ltplStep.EXCEL_LINE
                                        , replace(lErrMsg, '[XXX]', ltplStep.FAL_FACTORY_FLOOR_ID)
                                         );
              end if;

              if ltplStep.PAC_SUPPLIER_PARTNER_ID is not null then
                lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('Le fournisseur ne doit pas être renseigné sur une opération interne.');
                IMP_PRC_TOOLS.insertError(lcDomain, ltplStep.IMP_FAL_LIST_STEP_LINK_ID, ltplStep.EXCEL_LINE, lErrMsg);
              end if;

              if ltplStep.GCO_GCO_GOOD_ID is not null then
                lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('Le bien connecté ne doit pas être renseigné sur une opération interne.');
                IMP_PRC_TOOLS.insertError(lcDomain, ltplStep.IMP_FAL_LIST_STEP_LINK_ID, ltplStep.EXCEL_LINE, lErrMsg);
              end if;
            else
              -- Le service et le bien connecté doivent être fournis et exister pour une opération externe ou être renseignés sur l'opération standard.
              if     (ltplStep.PAC_SUPPLIER_PARTNER_ID is null)
                 and (FWK_I_LIB_ENTITY.getNumberFieldFromPk(FWK_I_TYP_FAL_ENTITY.gcFalTask, 'PAC_SUPPLIER_PARTNER_ID', lTaskId) is null) then
                IMP_PRC_TOOLS.insertError(lcDomain
                                        , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                        , ltplStep.EXCEL_LINE
                                        , pcs.PC_FUNCTIONS.TranslateWord('Le fournisseur est obligatoire sur une opération externe.')
                                         );
              elsif     (ltplStep.PAC_SUPPLIER_PARTNER_ID is not null)
                    and not IMP_LIB_TOOLS.supplierKey2Exists(ltplStep.PAC_SUPPLIER_PARTNER_ID) then
                lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('Le fournisseur ave la clef 2 ''[XXX]'' est inexistant dans la société.');
                IMP_PRC_TOOLS.insertError(lcDomain
                                        , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                        , ltplStep.EXCEL_LINE
                                        , replace(lErrMsg, '[XXX]', ltplStep.FAL_FACTORY_FLOOR_ID)
                                         );
              end if;

              if     (ltplStep.GCO_GCO_GOOD_ID is null)
                 and (FWK_I_LIB_ENTITY.getNumberFieldFromPk(FWK_I_TYP_FAL_ENTITY.gcFalTask, 'GCO_GCO_GOOD_ID', lTaskId) is null) then
                IMP_PRC_TOOLS.insertError(lcDomain
                                        , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                        , ltplStep.EXCEL_LINE
                                        , pcs.PC_FUNCTIONS.TranslateWord('Le bien connecté est obligatoire sur une opération externe.')
                                         );
              elsif     (ltplStep.GCO_GCO_GOOD_ID is not null)
                    and not IMP_LIB_TOOLS.serviceExists(ltplStep.GCO_GCO_GOOD_ID) then
                lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('Le bien connecté avec la référence ''[XXX]'' est inexistant dans la société.');
                IMP_PRC_TOOLS.insertError(lcDomain
                                        , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                        , ltplStep.EXCEL_LINE
                                        , replace(lErrMsg, '[XXX]', ltplStep.GCO_GCO_GOOD_ID)
                                         );
              end if;

              if ltplStep.FAL_FACTORY_FLOOR_ID is not null then
                lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('L''atelier ne doit pas être renseigné sur une opération externe.');
                IMP_PRC_TOOLS.insertError(lcDomain, ltplStep.IMP_FAL_LIST_STEP_LINK_ID, ltplStep.EXCEL_LINE, lErrMsg);
              end if;

              if ltplStep.FAL_FAL_FACTORY_FLOOR_ID is not null then
                lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('L''opérateur ne doit pas être renseigné sur une opération externe.');
                IMP_PRC_TOOLS.insertError(lcDomain, ltplStep.IMP_FAL_LIST_STEP_LINK_ID, ltplStep.EXCEL_LINE, lErrMsg);
              end if;
            end if;

            -- Si renseigné, l'opérateur doit exister
            if     ltplStep.FAL_FAL_FACTORY_FLOOR_ID is not null
               and not IMP_LIB_TOOLS.factoryFloorExists(ltplStep.FAL_FAL_FACTORY_FLOOR_ID) then
              lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('L''opérateur avec la référence ''[XXX]'' est inexistant dans la société.');
              IMP_PRC_TOOLS.insertError(lcDomain
                                      , ltplStep.IMP_FAL_LIST_STEP_LINK_ID
                                      , ltplStep.EXCEL_LINE
                                      , replace(lErrMsg, '[XXX]', ltplStep.FAL_FAL_FACTORY_FLOOR_ID)
                                       );
            end if;

            -- Cohérence entre la case diviseur et la qté réf. montant. On ne doit pas diviser par 0.
            if     ltplStep.SCS_DIVISOR_AMOUNT = 1
               and ltplStep.SCS_QTY_REF_AMOUNT = 0 then
              lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('Incohérence : la qté réf. montant ne peut pas être égale à 0 si le champ Diviseur est à 1.');
              IMP_PRC_TOOLS.insertError(lcDomain, ltplStep.IMP_FAL_LIST_STEP_LINK_ID, ltplStep.EXCEL_LINE, lErrMsg);
            end if;

            -- Cohérence entre le retards et le type de relation : retard uniquement sur opération parallèle
            if     ltplStep.C_RELATION_TYPE not in('2', '4', '5')
               and ltplStep.SCS_DELAY > 0 then
              lErrMsg  := pcs.PC_FUNCTIONS.TranslateWord('Incohérence : Un retard ne peut être défini que sur une opération paralèlle.');
              IMP_PRC_TOOLS.insertError(lcDomain, ltplStep.IMP_FAL_LIST_STEP_LINK_ID, ltplStep.EXCEL_LINE, lErrMsg);
            end if;
          end if;
        end loop;
      end if;
    end loop;

    --Si la table d'erreurs est vide, alors on insère le message repris par le pilotage de contrôle indiquant l'absence d'erreur
    IMP_PRC_TOOLS.checkErrors(lcDomain);
    commit;
  end IMP_FAL_SCHEDULE_PLAN_CTRL;

  /**
  * Description
  *    Importation des ateliers
  */
  procedure IMP_FAL_FACTORY_FLOOR_IMPORT
  as
    ltFacFloor        FWK_I_TYP_DEFINITION.t_crud_def;
    ltFacFloorImpHist FWK_I_TYP_DEFINITION.t_crud_def;
    ltFacRate         FWK_I_TYP_DEFINITION.t_crud_def;
    ltFacRateImpHist  FWK_I_TYP_DEFINITION.t_crud_def;
    lAcsAccountId     ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    lFacFloorId       FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type;
    lFacHisFloorId    IMP_HIST_FAL_FACTORY_FLOOR.IMP_HIST_FAL_FACTORY_FLOOR_ID%type;
    lFacRateId        FAL_FACTORY_RATE.FAL_FACTORY_RATE_ID%type;
  begin
    --Contrôle que la table d'erreurs soit vide
    IMP_PRC_TOOLS.checkErrorsBeforeImport('FAL_FACTORY_FLOOR');

    -- Parcours de tous les enregistrements de la table IMP_FAL_FACTORY_FLOOR en commençant par les îlots puis les machine,
    -- puis les groupes d'opérateurs et enfin les opérateurs
    for tdata in (select   *
                      from IMP_FAL_FACTORY_FLOOR
                  order by FAC_IS_BLOCK desc
                         , FAC_IS_MACHINE desc
                         , FAC_IS_OPERATOR desc
                         , FAC_IS_PERSON desc) loop
      select max(acc.ACS_ACCOUNT_ID)
        into lAcsAccountId
        from ACS_ACCOUNT acc
           , ACS_CDA_ACCOUNT cda
           , ACS_SUB_SET sse
       where acc.ACS_ACCOUNT_ID = cda.ACS_CDA_ACCOUNT_ID
         and acc.ACS_SUB_SET_ID = sse.ACS_SUB_SET_ID
         and sse.C_SUB_SET = 'CDA'
         and acc.C_VALID = 'VAL'
         and acc.ACC_NUMBER = tdata.ACS_CDA_ACCOUNT_ID;

      lFacFloorId     := GetNewId;
      -- ***** Insertion dans la table FAL_FACTORY_FLOOR *****
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalFactoryFloor, ltFacFloor, true);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor, 'FAL_FACTORY_FLOOR_ID', lFacFloorId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor, 'FAC_REFERENCE', tdata.FAC_REFERENCE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor, 'FAC_DESCRIBE', tdata.FAC_DESCRIBE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor, 'FAC_IS_BLOCK', tdata.FAC_IS_BLOCK);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor, 'FAC_IS_MACHINE', tdata.FAC_IS_MACHINE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor, 'FAC_IS_PERSON', tdata.FAC_IS_PERSON);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor, 'FAC_IS_OPERATOR', tdata.FAC_IS_OPERATOR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor, 'FAC_RESOURCE_NUMBER', tdata.FAC_RESOURCE_NUMBER);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor, 'FAC_PIC', tdata.FAC_PIC);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor, 'FAC_INFINITE_FLOOR', tdata.FAC_INFINITE_FLOOR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor, 'FAC_PIECES_HOUR_CAP', tdata.FAC_PIECES_HOUR_CAP);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor, 'FAC_UNIT_MARGIN_RATE', tdata.FAC_UNIT_MARGIN_RATE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor, 'FAC_DAY_CAPACITY', tdata.FAC_DAY_CAPACITY);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor, 'ACS_CDA_ACCOUNT_ID', lAcsAccountId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor
                                    , 'FAL_GRP_FACTORY_FLOOR_ID'
                                    , FWK_I_LIB_ENTITY.getIdfromPk2(FWK_I_TYP_FAL_ENTITY.gcFalFactoryFloor, 'FAC_REFERENCE', tdata.FAL_GRP_FACTORY_FLOOR_ID)
                                     );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor
                                    , 'HRM_PERSON_ID'
                                    , FWK_I_LIB_ENTITY.getIdfromPk2(FWK_I_TYP_HRM_ENTITY.gcHrmPerson, 'EMP_NUMBER', tdata.HRM_PERSON_ID)
                                     );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor
                                    , 'FAL_FAL_FACTORY_FLOOR_ID'
                                    , FWK_I_LIB_ENTITY.getIdfromPk2(FWK_I_TYP_FAL_ENTITY.gcFalFactoryFloor, 'FAC_REFERENCE', tdata.FAL_FAL_FACTORY_FLOOR_ID)
                                     );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor
                                    , 'GAL_COST_CENTER_ID'
                                    , FWK_I_LIB_ENTITY.getIdfromPk2(FWK_I_TYP_GAL_ENTITY.gcGalCostCenter, 'GCC_CODE', tdata.GAL_COST_CENTER_ID)
                                     );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor
                                    , 'PAC_SCHEDULE_ID'
                                    , FWK_I_LIB_ENTITY.getIdfromPk2(FWK_I_TYP_PAC_ENTITY.gcPacSchedule, 'SCE_DESCR', tdata.PAC_SCHEDULE_ID)
                                     );
--       FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor, 'FAC_UPDATE_LMU', 0);
--       FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor, 'FREE1', tdata.FREE1);
--       FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor, 'FREE2', tdata.FREE2);
--       FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor, 'FREE3', tdata.FREE3);
--       FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor, 'FREE4', tdata.FREE4);
--       FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor, 'FREE5', tdata.FREE5);
--       FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor, 'FREE6', tdata.FREE6);
--       FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor, 'FREE7', tdata.FREE7);
--       FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor, 'FREE8', tdata.FREE8);
--       FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor, 'FREE9', tdata.FREE9);
--       FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloor, 'FREE10', tdata.FREE10);
      FWK_I_MGT_ENTITY.InsertEntity(ltFacFloor);
      -- ***** Insertion dans la table d'historique (IMP_HIST_FAL_FACTORY_FLOOR) *****
      lFacHisFloorId  := GetNewId;
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_IMP_ENTITY.gcImpHistFalFactoryFloor, ltFacFloorImpHist);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'IMP_HIST_FAL_FACTORY_FLOOR_ID', lFacHisFloorId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'EXCEL_LINE', tdata.EXCEL_LINE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'DATE_HIST', sysdate);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'FAL_FACTORY_FLOOR_ID', lFacFloorId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'FAC_REFERENCE', tdata.FAC_REFERENCE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'FAC_DESCRIBE', tdata.FAC_DESCRIBE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'FAC_IS_BLOCK', tdata.FAC_IS_BLOCK);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'FAC_IS_MACHINE', tdata.FAC_IS_MACHINE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'FAC_IS_PERSON', tdata.FAC_IS_PERSON);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'FAC_IS_OPERATOR', tdata.FAC_IS_OPERATOR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'FAL_GRP_FACTORY_FLOOR_ID', tdata.FAL_GRP_FACTORY_FLOOR_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'HRM_PERSON_ID', tdata.HRM_PERSON_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'FAC_RESOURCE_NUMBER', tdata.FAC_RESOURCE_NUMBER);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'FAC_PIC', tdata.FAC_PIC);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'FAL_FAL_FACTORY_FLOOR_ID', tdata.FAL_FAL_FACTORY_FLOOR_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'FAC_INFINITE_FLOOR', tdata.FAC_INFINITE_FLOOR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'FAC_PIECES_HOUR_CAP', tdata.FAC_PIECES_HOUR_CAP);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'ACS_CDA_ACCOUNT_ID', tdata.ACS_CDA_ACCOUNT_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'GAL_COST_CENTER_ID', tdata.GAL_COST_CENTER_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'PAC_SCHEDULE_ID', tdata.PAC_SCHEDULE_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'FAC_UNIT_MARGIN_RATE', tdata.FAC_UNIT_MARGIN_RATE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'FAC_DAY_CAPACITY', tdata.FAC_DAY_CAPACITY);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'FREE1', tdata.FREE1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'FREE2', tdata.FREE2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'FREE3', tdata.FREE3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'FREE4', tdata.FREE4);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'FREE5', tdata.FREE5);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'FREE6', tdata.FREE6);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'FREE7', tdata.FREE7);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'FREE8', tdata.FREE8);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'FREE9', tdata.FREE9);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacFloorImpHist, 'FREE10', tdata.FREE10);
      FWK_I_MGT_ENTITY.InsertEntity(ltFacFloorImpHist);

      -- Insertion des taux de l'atelier en cours
      for tplFacRate in (select *
                           from IMP_FAL_FACTORY_RATE
                          where IMP_FAL_FACTORY_FLOOR_ID = tdata.IMP_FAL_FACTORY_FLOOR_ID) loop
        lFacRateId  := GetNewId;
        -- ***** Insertion dans la table FAL_FACTORY_RATE *****
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalFactoryRate, ltFacRate, true);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRate, 'FAL_FACTORY_RATE_ID', lFacRateId);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRate, 'FAL_FACTORY_FLOOR_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltFacFloor, 'FAL_FACTORY_FLOOR_ID') );
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRate, 'FFR_VALIDITY_DATE', tplFacRate.FFR_VALIDITY_DATE);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRate, 'FFR_RATE1', tplFacRate.FFR_RATE1);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRate, 'FFR_RATE2', tplFacRate.FFR_RATE2);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRate, 'FFR_RATE3', tplFacRate.FFR_RATE3);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRate, 'FFR_RATE4', tplFacRate.FFR_RATE4);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRate, 'FFR_RATE5', tplFacRate.FFR_RATE5);
        FWK_I_MGT_ENTITY.InsertEntity(ltFacRate);
        -- ***** Insertion dans la table d'historique (IMP_HIST_FAL_FACTORY_RATE) *****
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_IMP_ENTITY.gcImpHistFalFactoryRate, ltFacRateImpHist);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRateImpHist, 'EXCEL_LINE', tplFacRate.EXCEL_LINE);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRateImpHist, 'DATE_HIST', sysdate);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRateImpHist, 'FAL_FACTORY_RATE_ID', lFacRateId);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRateImpHist, 'IMP_HIST_FAL_FACTORY_FLOOR_ID', lFacHisFloorId);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRateImpHist, 'FFR_VALIDITY_DATE', tplFacRate.FFR_VALIDITY_DATE);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRateImpHist, 'FFR_RATE1', tplFacRate.FFR_RATE1);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRateImpHist, 'FFR_RATE2', tplFacRate.FFR_RATE2);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRateImpHist, 'FFR_RATE3', tplFacRate.FFR_RATE3);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRateImpHist, 'FFR_RATE4', tplFacRate.FFR_RATE4);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltFacRateImpHist, 'FFR_RATE5', tplFacRate.FFR_RATE5);
        FWK_I_MGT_ENTITY.InsertEntity(ltFacRateImpHist);
        FWK_I_MGT_ENTITY.Release(ltFacRate);
        FWK_I_MGT_ENTITY.Release(ltFacRateImpHist);
      end loop;

      FWK_I_MGT_ENTITY.Release(ltFacFloor);
      FWK_I_MGT_ENTITY.Release(ltFacFloorImpHist);
    end loop;
  end IMP_FAL_FACTORY_FLOOR_IMPORT;

  /**
  * Description
  *    Importation des opérations standards
  */
  procedure IMP_FAL_TASK_IMPORT
  as
    ltTask        FWK_I_TYP_DEFINITION.t_crud_def;
    ltTaskImpHist FWK_I_TYP_DEFINITION.t_crud_def;
    lTaskId       FAL_TASK.FAL_TASK_ID%type;
  begin
    --Contrôle de l'absence d'erreurs.
    IMP_PRC_TOOLS.checkErrorsBeforeImport('FAL_TASK');

    --Parcours de tous les enregistrements de la table IMP_FAL_TASK
    for tdata in (select *
                    from IMP_FAL_TASK) loop
      -- ***** Insertion dans la table FAL_TASK *****
      lTaskId  := GetNewId;
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalTask, ltTask, true);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'FAL_TASK_ID', lTaskId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'C_TASK_TYPE', tdata.C_TASK_TYPE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'TAS_REF', tdata.TAS_REF);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'TAS_SHORT_DESCR', tdata.TAS_SHORT_DESCR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'TAS_LONG_DESCR', tdata.TAS_LONG_DESCR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'TAS_FREE_DESCR', tdata.TAS_FREE_DESCR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'C_SCHEDULE_PLANNING', tdata.C_SCHEDULE_PLANNING);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask
                                    , 'FAL_FACTORY_FLOOR_ID'
                                    , FWK_I_LIB_ENTITY.getIdfromPk2(FWK_I_TYP_FAL_ENTITY.gcFalFactoryFloor, 'FAC_REFERENCE', tdata.FAL_FACTORY_FLOOR_ID)
                                     );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask
                                    , 'PAC_SUPPLIER_PARTNER_ID'
                                    , FWK_I_LIB_ENTITY.getIdfromPk2(FWK_I_TYP_PAC_ENTITY.gcPacPerson, 'PER_KEY2', tdata.PAC_SUPPLIER_PARTNER_ID)
                                     );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask
                                    , 'GCO_GCO_GOOD_ID'
                                    , FWK_I_LIB_ENTITY.getIdfromPk2(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GOO_MAJOR_REFERENCE', tdata.GCO_GCO_GOOD_ID)
                                     );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'C_TASK_IMPUTATION', tdata.C_TASK_IMPUTATION);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask
                                    , 'FAL_FAL_FACTORY_FLOOR_ID'
                                    , FWK_I_LIB_ENTITY.getIdfromPk2(FWK_I_TYP_FAL_ENTITY.gcFalFactoryFloor, 'FAC_REFERENCE', tdata.FAL_FAL_FACTORY_FLOOR_ID)
                                     );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'TAS_ADJUSTING_RATE', tdata.TAS_ADJUSTING_RATE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'TAS_WORK_RATE', tdata.TAS_WORK_RATE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'TAS_NUM_FLOOR', tdata.TAS_NUM_FLOOR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'TAS_ADJUSTING_FLOOR', tdata.TAS_ADJUSTING_FLOOR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'TAS_ADJUSTING_OPERATOR', tdata.TAS_ADJUSTING_OPERATOR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'TAS_NUM_ADJUST_OPERATOR', tdata.TAS_NUM_ADJUST_OPERATOR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'TAS_PERCENT_ADJUST_OPER', tdata.TAS_PERCENT_ADJUST_OPER);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'TAS_WORK_FLOOR', tdata.TAS_WORK_FLOOR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'TAS_WORK_OPERATOR', tdata.TAS_WORK_OPERATOR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'TAS_NUM_WORK_OPERATOR', tdata.TAS_NUM_WORK_OPERATOR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'TAS_PERCENT_WORK_OPER', tdata.TAS_PERCENT_WORK_OPER);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'TAS_WEIGH', tdata.TAS_WEIGH);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'TAS_WEIGH_MANDATORY', tdata.TAS_WEIGH_MANDATORY);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'TAS_TRANSFERT_TIME', tdata.TAS_TRANSFERT_TIME);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'TAS_AMOUNT', tdata.TAS_AMOUNT);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'TAS_QTY_REF_AMOUNT', tdata.TAS_QTY_REF_AMOUNT);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'TAS_DIVISOR_AMOUNT', tdata.TAS_DIVISOR_AMOUNT);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'TAS_PLAN_RATE', tdata.TAS_PLAN_RATE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'TAS_PLAN_PROP', tdata.TAS_PLAN_PROP);
--       FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'FREE1', tdata.FREE1);
--       FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'FREE2', tdata.FREE2);
--       FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'FREE3', tdata.FREE3);
--       FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'FREE4', tdata.FREE4);
--       FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'FREE5', tdata.FREE5);
--       FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'FREE6', tdata.FREE6);
--       FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'FREE7', tdata.FREE7);
--       FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'FREE8', tdata.FREE8);
--       FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'FREE9', tdata.FREE9);
--       FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'FREE10', tdata.FREE10);
      FWK_I_MGT_ENTITY.InsertEntity(ltTask);
      -- ***** Insertion dans la table d'historique (IMP_HIST_FAL_TASK) *****
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_IMP_ENTITY.gcImpHistFalTask, ltTaskImpHist);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'EXCEL_LINE', tdata.EXCEL_LINE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'DATE_HIST', sysdate);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'FAL_TASK_ID', lTaskId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'C_TASK_TYPE', tdata.C_TASK_TYPE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'TAS_REF', tdata.TAS_REF);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'TAS_SHORT_DESCR', tdata.TAS_SHORT_DESCR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'TAS_LONG_DESCR', tdata.TAS_LONG_DESCR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'TAS_FREE_DESCR', tdata.TAS_FREE_DESCR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'C_SCHEDULE_PLANNING', tdata.C_SCHEDULE_PLANNING);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'FAL_FACTORY_FLOOR_ID', tdata.FAL_FACTORY_FLOOR_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'PAC_SUPPLIER_PARTNER_ID', tdata.PAC_SUPPLIER_PARTNER_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'GCO_GCO_GOOD_ID', tdata.GCO_GCO_GOOD_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'C_TASK_IMPUTATION', tdata.C_TASK_IMPUTATION);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'FAL_FAL_FACTORY_FLOOR_ID', tdata.FAL_FAL_FACTORY_FLOOR_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'TAS_ADJUSTING_RATE', tdata.TAS_ADJUSTING_RATE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'TAS_WORK_RATE', tdata.TAS_WORK_RATE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'TAS_NUM_FLOOR', tdata.TAS_NUM_FLOOR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'TAS_ADJUSTING_FLOOR', tdata.TAS_ADJUSTING_FLOOR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'TAS_ADJUSTING_OPERATOR', tdata.TAS_ADJUSTING_OPERATOR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'TAS_NUM_ADJUST_OPERATOR', tdata.TAS_NUM_ADJUST_OPERATOR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'TAS_PERCENT_ADJUST_OPER', tdata.TAS_PERCENT_ADJUST_OPER);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'TAS_WORK_FLOOR', tdata.TAS_WORK_FLOOR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'TAS_WORK_OPERATOR', tdata.TAS_WORK_OPERATOR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'TAS_NUM_WORK_OPERATOR', tdata.TAS_NUM_WORK_OPERATOR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'TAS_PERCENT_WORK_OPER', tdata.TAS_PERCENT_WORK_OPER);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'TAS_WEIGH', tdata.TAS_WEIGH);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'TAS_WEIGH_MANDATORY', tdata.TAS_WEIGH_MANDATORY);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'TAS_TRANSFERT_TIME', tdata.TAS_TRANSFERT_TIME);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'TAS_AMOUNT', tdata.TAS_AMOUNT);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'TAS_QTY_REF_AMOUNT', tdata.TAS_QTY_REF_AMOUNT);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'TAS_DIVISOR_AMOUNT', tdata.TAS_DIVISOR_AMOUNT);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'TAS_PLAN_RATE', tdata.TAS_PLAN_RATE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'TAS_PLAN_PROP', tdata.TAS_PLAN_PROP);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'FREE1', tdata.FREE1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'FREE2', tdata.FREE2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'FREE3', tdata.FREE3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'FREE4', tdata.FREE4);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'FREE5', tdata.FREE5);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'FREE6', tdata.FREE6);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'FREE7', tdata.FREE7);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'FREE8', tdata.FREE8);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'FREE9', tdata.FREE9);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaskImpHist, 'FREE10', tdata.FREE10);
      FWK_I_MGT_ENTITY.InsertEntity(ltTaskImpHist);
      FWK_I_MGT_ENTITY.Release(ltTask);
      FWK_I_MGT_ENTITY.Release(ltTaskImpHist);
    end loop;
  end IMP_FAL_TASK_IMPORT;

  /**
  * Description
  *    Importation des gammes opératoires
  */
  procedure IMP_FAL_SCHEDULE_PLAN_IMPORT
  as
    ltSchedulePlan        FWK_I_TYP_DEFINITION.t_crud_def;
    ltSchedulePlanImpHist FWK_I_TYP_DEFINITION.t_crud_def;
    ltListStepLink        FWK_I_TYP_DEFINITION.t_crud_def;
    ltListStepLinkImpHist FWK_I_TYP_DEFINITION.t_crud_def;
    lSchedulePlanId       FAL_SCHEDULE_PLAN.FAL_SCHEDULE_PLAN_ID%type;
    lHistSchedulePlanId   IMP_HIST_FAL_SCHEDULE_PLAN.IMP_HIST_FAL_SCHEDULE_PLAN_ID%type;
    lScheduleStepId       FAL_LIST_STEP_LINK.FAL_SCHEDULE_STEP_ID%type;
  begin
    --Contrôle de l'absence d'erreurs.
    IMP_PRC_TOOLS.checkErrorsBeforeImport('FAL_SCHEDULE_PLAN');

    --Parcours de tous les enregistrements de la table IMP_FAL_SCHEDULE_PLAN
    for tdata in (select *
                    from IMP_FAL_SCHEDULE_PLAN) loop
      -- ***** Insertion dans la table FAL_SCHEDULE_PLAN *****
      lSchedulePlanId      := GetNewId;
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalSchedulePlan, ltSchedulePlan, true);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltSchedulePlan, 'FAL_SCHEDULE_PLAN_ID', lSchedulePlanId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltSchedulePlan, 'SCH_REF', tdata.SCH_REF);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltSchedulePlan, 'SCH_SHORT_DESCR', tdata.SCH_SHORT_DESCR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltSchedulePlan, 'SCH_LONG_DESCR', tdata.SCH_LONG_DESCR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltSchedulePlan, 'SCH_FREE_DESCR', tdata.SCH_FREE_DESCR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltSchedulePlan, 'C_SCHEDULE_PLANNING', tdata.C_SCHEDULE_PLANNING);
      FWK_I_MGT_ENTITY.InsertEntity(ltSchedulePlan);
      -- ***** Insertion dans la table d'historique (IMP_HIST_FAL_SCHEDULE_PLAN) *****
      lHistSchedulePlanId  := GetNewId;
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_IMP_ENTITY.gcImpHistFalSchedulePlan, ltSchedulePlanImpHist);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltSchedulePlanImpHist, 'IMP_HIST_FAL_SCHEDULE_PLAN_ID', lHistSchedulePlanId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltSchedulePlanImpHist, 'EXCEL_LINE', tdata.EXCEL_LINE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltSchedulePlanImpHist, 'DATE_HIST', sysdate);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltSchedulePlanImpHist, 'FAL_SCHEDULE_PLAN_ID', lSchedulePlanId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltSchedulePlanImpHist, 'SCH_REF', tdata.SCH_REF);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltSchedulePlanImpHist, 'SCH_SHORT_DESCR', tdata.SCH_SHORT_DESCR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltSchedulePlanImpHist, 'SCH_LONG_DESCR', tdata.SCH_LONG_DESCR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltSchedulePlanImpHist, 'SCH_FREE_DESCR', tdata.SCH_FREE_DESCR);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltSchedulePlanImpHist, 'C_SCHEDULE_PLANNING', tdata.C_SCHEDULE_PLANNING);
      FWK_I_MGT_ENTITY.InsertEntity(ltSchedulePlanImpHist);

      for ltplStepLnk in (select imp.*
                               , tas.TAS_SHORT_DESCR
                               , tas.TAS_LONG_DESCR
                               , tas.TAS_FREE_DESCR
                               , tas.PAC_SUPPLIER_PARTNER_ID PAC_SUPPLIER_PARTNER_ID_TAS
                               , tas.FAL_FACTORY_FLOOR_ID FAL_FACTORY_FLOOR_ID_TAS
                               , tas.GCO_GCO_GOOD_ID GCO_GCO_GOOD_ID_TAS
                            from IMP_FAL_LIST_STEP_LINK imp
                               , FAL_TASK tas
                           where imp.IMP_FAL_SCHEDULE_PLAN_ID = tdata.IMP_FAL_SCHEDULE_PLAN_ID
                             and FWK_I_LIB_ENTITY.getIdfromPk2(FWK_I_TYP_FAL_ENTITY.gcFalTask, 'TAS_REF', imp.FAL_TASK_ID) = tas.FAL_TASK_ID) loop
        -- ***** Insertion dans la table  FAL_LIST_STEP_LINK *****
        lScheduleStepId  := GetNewId;
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalListStepLink, ltListStepLink, true, null, null, 'FAL_SCHEDULE_STEP_ID');
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'FAL_SCHEDULE_STEP_ID', lScheduleStepId);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'FAL_SCHEDULE_PLAN_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltSchedulePlan, 'FAL_SCHEDULE_PLAN_ID') );
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_STEP_NUMBER', ltplStepLnk.SCS_STEP_NUMBER);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink
                                      , 'FAL_TASK_ID'
                                      , FWK_I_LIB_ENTITY.getIdfromPk2(FWK_I_TYP_FAL_ENTITY.gcFalTask, 'TAS_REF', ltplStepLnk.FAL_TASK_ID)
                                       );
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink
                                      , 'C_TASK_TYPE'
                                      , FWK_I_LIB_ENTITY.getVarchar2FieldFromPk(FWK_I_TYP_FAL_ENTITY.gcFalTask
                                                                              , 'C_TASK_TYPE'
                                                                              , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltListStepLink, 'FAL_TASK_ID')
                                                                               )
                                       );
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_WORK_TIME', ltplStepLnk.SCS_WORK_TIME);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_QTY_REF_WORK', ltplStepLnk.SCS_QTY_REF_WORK);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_WORK_RATE', ltplStepLnk.SCS_WORK_RATE);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_AMOUNT', ltplStepLnk.SCS_AMOUNT);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_QTY_REF_AMOUNT', ltplStepLnk.SCS_QTY_REF_AMOUNT);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_DIVISOR_AMOUNT', ltplStepLnk.SCS_DIVISOR_AMOUNT);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_PLAN_RATE', ltplStepLnk.SCS_PLAN_RATE);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_SHORT_DESCR', nvl(ltplStepLnk.SCS_SHORT_DESCR, ltplStepLnk.TAS_SHORT_DESCR) );
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_LONG_DESCR', nvl(ltplStepLnk.SCS_LONG_DESCR, ltplStepLnk.TAS_LONG_DESCR) );
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_FREE_DESCR', nvl(ltplStepLnk.SCS_FREE_DESCR, ltplStepLnk.TAS_FREE_DESCR) );
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink
                                      , 'PAC_SUPPLIER_PARTNER_ID'
                                      , nvl(FWK_I_LIB_ENTITY.getIdfromPk2(FWK_I_TYP_PAC_ENTITY.gcPacPerson, 'PER_KEY2', ltplStepLnk.PAC_SUPPLIER_PARTNER_ID)
                                          , ltplStepLnk.PAC_SUPPLIER_PARTNER_ID_TAS
                                           )
                                       );
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink
                                      , 'FAL_FACTORY_FLOOR_ID'
                                      , nvl(FWK_I_LIB_ENTITY.getIdfromPk2(FWK_I_TYP_FAL_ENTITY.gcFalFactoryFloor
                                                                        , 'FAC_REFERENCE'
                                                                        , ltplStepLnk.FAL_FACTORY_FLOOR_ID
                                                                         )
                                          , ltplStepLnk.FAL_FACTORY_FLOOR_ID_TAS
                                           )
                                       );
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink
                                      , 'GCO_GCO_GOOD_ID'
                                      , nvl(FWK_I_LIB_ENTITY.getIdfromPk2(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GOO_MAJOR_REFERENCE', ltplStepLnk.GCO_GCO_GOOD_ID)
                                          , ltplStepLnk.GCO_GCO_GOOD_ID_TAS
                                           )
                                       );
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink
                                      , 'FAL_FAL_FACTORY_FLOOR_ID'
                                      , FWK_I_LIB_ENTITY.getIdfromPk2(FWK_I_TYP_FAL_ENTITY.gcFalFactoryFloor
                                                                    , 'FAC_REFERENCE'
                                                                    , ltplStepLnk.FAL_FAL_FACTORY_FLOOR_ID
                                                                     )
                                       );
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'C_OPERATION_TYPE', ltplStepLnk.C_OPERATION_TYPE);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_ADJUSTING_TIME', ltplStepLnk.SCS_ADJUSTING_TIME);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_PLAN_PROP', ltplStepLnk.SCS_PLAN_PROP);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'C_TASK_IMPUTATION', ltplStepLnk.C_TASK_IMPUTATION);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_TRANSFERT_TIME', ltplStepLnk.SCS_TRANSFERT_TIME);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_QTY_FIX_ADJUSTING', ltplStepLnk.SCS_QTY_FIX_ADJUSTING);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_ADJUSTING_RATE', ltplStepLnk.SCS_ADJUSTING_RATE);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'C_RELATION_TYPE', ltplStepLnk.C_RELATION_TYPE);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_DELAY', ltplStepLnk.SCS_DELAY);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_NUM_FLOOR', ltplStepLnk.SCS_NUM_FLOOR);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_ADJUSTING_FLOOR', ltplStepLnk.SCS_ADJUSTING_FLOOR);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_ADJUSTING_OPERATOR', ltplStepLnk.SCS_ADJUSTING_OPERATOR);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_NUM_ADJUST_OPERATOR', ltplStepLnk.SCS_NUM_ADJUST_OPERATOR);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_PERCENT_ADJUST_OPER', ltplStepLnk.SCS_PERCENT_ADJUST_OPER);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_WORK_FLOOR', ltplStepLnk.SCS_WORK_FLOOR);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_WORK_OPERATOR', ltplStepLnk.SCS_WORK_OPERATOR);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_NUM_WORK_OPERATOR', ltplStepLnk.SCS_NUM_WORK_OPERATOR);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_PERCENT_WORK_OPER', ltplStepLnk.SCS_PERCENT_WORK_OPER);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_WEIGH', ltplStepLnk.SCS_WEIGH);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'SCS_WEIGH_MANDATORY', ltplStepLnk.SCS_WEIGH_MANDATORY);
--         FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'FREE1', ltplStepLnk.FREE1);
--         FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'FREE2', ltplStepLnk.FREE2);
--         FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'FREE3', ltplStepLnk.FREE3);
--         FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'FREE4', ltplStepLnk.FREE4);
--         FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'FREE5', ltplStepLnk.FREE5);
--         FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'FREE6', ltplStepLnk.FREE6);
--         FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'FREE7', ltplStepLnk.FREE7);
--         FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'FREE8', ltplStepLnk.FREE8);
--         FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'FREE9', ltplStepLnk.FREE9);
--         FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLink, 'FREE10', ltplStepLnk.FREE10);
        FWK_I_MGT_ENTITY.InsertEntity(ltListStepLink);
        -- ***** Insertion dans la table d'historique (IMP_HIST_FAL_SLIST_STEP_LINK) *****
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_IMP_ENTITY.gcImpHistFalListStepLink, ltListStepLinkImpHist);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'EXCEL_LINE', ltplStepLnk.EXCEL_LINE);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'DATE_HIST', sysdate);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'FAL_SCHEDULE_STEP_ID', lScheduleStepId);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'IMP_HIST_FAL_SCHEDULE_PLAN_ID', lHistSchedulePlanId);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_STEP_NUMBER', ltplStepLnk.SCS_STEP_NUMBER);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'FAL_TASK_ID', ltplStepLnk.FAL_TASK_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_WORK_TIME', ltplStepLnk.SCS_WORK_TIME);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_QTY_REF_WORK', ltplStepLnk.SCS_QTY_REF_WORK);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_WORK_RATE', ltplStepLnk.SCS_WORK_RATE);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_AMOUNT', ltplStepLnk.SCS_AMOUNT);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_QTY_REF_AMOUNT', ltplStepLnk.SCS_QTY_REF_AMOUNT);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_DIVISOR_AMOUNT', ltplStepLnk.SCS_DIVISOR_AMOUNT);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_PLAN_RATE', ltplStepLnk.SCS_PLAN_RATE);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_SHORT_DESCR', ltplStepLnk.SCS_SHORT_DESCR);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_LONG_DESCR', ltplStepLnk.SCS_LONG_DESCR);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_FREE_DESCR', ltplStepLnk.SCS_FREE_DESCR);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'PAC_SUPPLIER_PARTNER_ID', ltplStepLnk.PAC_SUPPLIER_PARTNER_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'FAL_FACTORY_FLOOR_ID', ltplStepLnk.FAL_FACTORY_FLOOR_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'GCO_GCO_GOOD_ID', ltplStepLnk.GCO_GCO_GOOD_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'C_OPERATION_TYPE', ltplStepLnk.C_OPERATION_TYPE);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_ADJUSTING_TIME', ltplStepLnk.SCS_ADJUSTING_TIME);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_PLAN_PROP', ltplStepLnk.SCS_PLAN_PROP);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'C_TASK_IMPUTATION', ltplStepLnk.C_TASK_IMPUTATION);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_TRANSFERT_TIME', ltplStepLnk.SCS_TRANSFERT_TIME);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_QTY_FIX_ADJUSTING', ltplStepLnk.SCS_QTY_FIX_ADJUSTING);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_ADJUSTING_RATE', ltplStepLnk.SCS_ADJUSTING_RATE);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'C_RELATION_TYPE', ltplStepLnk.C_RELATION_TYPE);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_DELAY', ltplStepLnk.SCS_DELAY);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'FAL_FAL_FACTORY_FLOOR_ID', ltplStepLnk.FAL_FAL_FACTORY_FLOOR_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_NUM_FLOOR', ltplStepLnk.SCS_NUM_FLOOR);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_ADJUSTING_FLOOR', ltplStepLnk.SCS_ADJUSTING_FLOOR);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_ADJUSTING_OPERATOR', ltplStepLnk.SCS_ADJUSTING_OPERATOR);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_NUM_ADJUST_OPERATOR', ltplStepLnk.SCS_NUM_ADJUST_OPERATOR);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_PERCENT_ADJUST_OPER', ltplStepLnk.SCS_PERCENT_ADJUST_OPER);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_WORK_FLOOR', ltplStepLnk.SCS_WORK_FLOOR);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_WORK_OPERATOR', ltplStepLnk.SCS_WORK_OPERATOR);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_NUM_WORK_OPERATOR', ltplStepLnk.SCS_NUM_WORK_OPERATOR);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_PERCENT_WORK_OPER', ltplStepLnk.SCS_PERCENT_WORK_OPER);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_WEIGH', ltplStepLnk.SCS_WEIGH);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'SCS_WEIGH_MANDATORY', ltplStepLnk.SCS_WEIGH_MANDATORY);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'FREE1', ltplStepLnk.FREE1);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'FREE2', ltplStepLnk.FREE2);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'FREE3', ltplStepLnk.FREE3);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'FREE4', ltplStepLnk.FREE4);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'FREE5', ltplStepLnk.FREE5);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'FREE6', ltplStepLnk.FREE6);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'FREE7', ltplStepLnk.FREE7);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'FREE8', ltplStepLnk.FREE8);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'FREE9', ltplStepLnk.FREE9);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltListStepLinkImpHist, 'FREE10', ltplStepLnk.FREE10);
        FWK_I_MGT_ENTITY.InsertEntity(ltListStepLinkImpHist);
        FWK_I_MGT_ENTITY.Release(ltListStepLink);
        FWK_I_MGT_ENTITY.Release(ltListStepLinkImpHist);
      end loop;

      FWK_I_MGT_ENTITY.Release(ltSchedulePlan);
      FWK_I_MGT_ENTITY.Release(ltSchedulePlanImpHist);
    end loop;
  end IMP_FAL_SCHEDULE_PLAN_IMPORT;
end IMP_PRC_FAL_BASIS;
