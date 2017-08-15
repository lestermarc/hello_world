--------------------------------------------------------
--  DDL for Package Body FAL_OPERATION_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_OPERATION_FUNCTIONS" 
is
  -- Configurations
  cFalDefaultService constant varchar(30) := PCS.PC_CONFIG.GetConfig('FAL_ORT_DEFAULT_SERVICE');

  /**
  * function GetDuration
  * Description
  *   Calcul la durée d'une opération
  * @created CLE
  * @lastUpdate
  * @public
  * @param      ScsPlanRate   Planification de l'opération
  * @param      ScsPlanProp   Durée proportionnel ou non
  * @param      aQty          Quantité à planifier (quantité solde pour un lot)
  * @param      ScsQtyRefWork Quantité référence travail
  * @return     Durée planifiée
  */
  function GetDuration(
    ScsPlanRate           FAL_TASK_LINK.SCS_PLAN_RATE%type
  , ScsPlanProp           FAL_TASK_LINK.SCS_PLAN_PROP%type
  , aQty                  FAL_TASK_LINK.TAL_DUE_QTY%type
  , ScsQtyRefWork         FAL_TASK_LINK.SCS_QTY_REF_WORK%type
  , aFalFactoryFloorId    number default null
  , aPacSupplierPartnerId number default null
  , aTalBeginPlanDate     date default null
  )
    return number
  is
    result          number;
    aTypePlanif     integer;
    aItemIdToPlan   number;
    aItemTypeToPlan integer;
  begin
    if ScsPlanProp = 1 then
      result  := (aQty / ScsQtyRefWork) * ScsPlanRate * to_number(PCS.PC_CONFIG.GetConfig('PPS_RATE_DAY') );
    else
      result  := ScsPlanRate * to_number(PCS.PC_CONFIG.GetConfig('PPS_RATE_DAY') );
    end if;

    if nvl(result, 0) > 0 then
      if aFalFactoryFloorId is not null then
        aItemIdToPlan    := aFalFactoryFloorId;
        aItemTypeToPlan  := FAL_PLANIF.ctIdUniqueFactFloor;
      elsif aPacSupplierPartnerId is not null then
        aItemIdToPlan    := aPacSupplierPartnerId;
        aItemTypeToPlan  := FAL_PLANIF.ctIdUniqueSupplier;
      else
        aItemIdToPlan    := null;
        aItemTypeToPlan  := FAL_PLANIF.ctIdDefaultCalendar;
      end if;

      -- Calcul durée en minutes, en avant.
      result  := FAL_PLANIF.GetDurationInMinutes(aFalFactoryFloorId, aPacSupplierPartnerId, result, aTalBeginPlanDate) / 60;
    end if;

    return nvl(result, 0);
  end;

  /**
  * function GetJobDuration
  * Description
  *   Calcul du travail d'une opération
  * @created CLE
  * @lastUpdate
  * @public
  * @param      ScsWorkTime          Travail de l'opération
  * @param      ScsQtyFixAdjusting   Quantité fixe réglage
  * @param      ScsAdjustingTime     Réglage de l'opération
  * @param      aQty                 Quantité à planifier (quantité solde pour un lot)
  * @param      ScsQtyRefWork        Quantité référence travail
  * @return     Durée Travail d'une opération
  */
  function GetJobDuration(
    ScsWorkTime        FAL_TASK_LINK.SCS_WORK_TIME%type
  , ScsQtyFixAdjusting FAL_TASK_LINK.SCS_QTY_FIX_ADJUSTING%type
  , ScsAdjustingTime   FAL_TASK_LINK.SCS_ADJUSTING_TIME%type
  , aQty               FAL_TASK_LINK.TAL_DUE_QTY%type
  , ScsQtyRefWork      FAL_TASK_LINK.SCS_QTY_REF_WORK%type
  )
    return number
  is
    result number;
  begin
    if nvl(ScsWorkTime, 0) = 0 then
      if nvl(ScsQtyFixAdjusting, 0) = 0 then
        result  := nvl(ScsAdjustingTime, 0);
      else
        result  := FAL_TOOLS.RoundSuccInt(nvl(aQty, 0) / ScsQtyFixAdjusting) * nvl(ScsAdjustingTime, 0);
      end if;
    else
      if nvl(ScsQtyFixAdjusting, 0) <> 0 then
        result  := (aQty * nvl(ScsWorkTime, 0) / ScsQtyRefWork) +(FAL_TOOLS.RoundSuccInt(aQty / ScsQtyFixAdjusting) * nvl(ScsAdjustingTime, 0) );
      else
        result  := (aQty * nvl(ScsWorkTime, 0) / ScsQtyRefWork) + nvl(ScsAdjustingTime, 0);
      end if;
    end if;

    if PCS.PC_CONFIG.GetConfig('PPS_WORK_UNIT') = 'M' then
      result  := result / 60;
    end if;

    return nvl(result, 0);
  end;

  /**
  * function GetJobDuration
  * Description
  *   Calcul du travail d'une opération
  * @created CLE
  * @lastUpdate
  * @public
  * @param      OperationId  Id d'une opération de lot ou de POF
  * @return     Durée Travail d'une opération. Retourne NULL si l'opération n'a pas été trouvée
  */
  function GetJobDuration(OperationId FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return number
  is
    cursor CUR_OPERATION
    is
      select SCS_WORK_TIME
           , SCS_QTY_FIX_ADJUSTING
           , SCS_ADJUSTING_TIME
           , TAL_DUE_QTY
           , SCS_QTY_REF_WORK
        from FAL_TASK_LINK
       where FAL_SCHEDULE_STEP_ID = OperationId
      union
      select SCS_WORK_TIME
           , SCS_QTY_FIX_ADJUSTING
           , SCS_ADJUSTING_TIME
           , TAL_DUE_QTY
           , SCS_QTY_REF_WORK
        from FAL_TASK_LINK_PROP
       where FAL_TASK_LINK_PROP_ID = OperationId;

    curOperation CUR_OPERATION%rowtype;
    result       number;
  begin
    open CUR_OPERATION;

    fetch CUR_OPERATION
     into curOperation;

    if CUR_OPERATION%found then
      result  :=
        GetJobDuration(curOperation.SCS_WORK_TIME
                     , curOperation.SCS_QTY_FIX_ADJUSTING
                     , curOperation.SCS_ADJUSTING_TIME
                     , curOperation.TAL_DUE_QTY
                     , curOperation.SCS_QTY_REF_WORK
                      );
    else
      result  := null;
    end if;

    close CUR_OPERATION;

    return result;
  end;

  procedure CreateOperationFromStandardOpe(
    aFalLotId              FAL_LOT.FAL_LOT_ID%type
  , aFalTaskId             FAL_TASK.FAL_TASK_ID%type
  , aSequence              FAL_TASK_LINK.SCS_STEP_NUMBER%type
  , aQty                   FAL_TASK_LINK.TAL_PLAN_QTY%type
  , aScsWorkTime           FAL_TASK_LINK.SCS_WORK_TIME%type
  , aCreatedScheduleStepId FAL_LOT.FAL_LOT_ID%type
  )
  is
  begin
    insert into FAL_TASK_LINK
                (FAL_SCHEDULE_STEP_ID
               , FAL_LOT_ID
               , SCS_STEP_NUMBER
               , C_OPERATION_TYPE
               , FAL_TASK_ID
               , C_TASK_TYPE
               , SCS_SHORT_DESCR
               , SCS_LONG_DESCR
               , SCS_FREE_DESCR
               , FAL_FACTORY_FLOOR_ID
               , PAC_SUPPLIER_PARTNER_ID
               , GCO_GCO_GOOD_ID
               , PPS_OPERATION_PROCEDURE_ID
               , PPS_PPS_OPERATION_PROCEDURE_ID
               , TAL_PLAN_QTY
               , TAL_AVALAIBLE_QTY
               , TAL_RELEASE_QTY
               , TAL_REJECTED_QTY
               , TAL_R_METER
               , TAL_DUE_QTY
               , SCS_ADJUSTING_TIME
               , SCS_WORK_TIME
               , SCS_QTY_REF_WORK
               , SCS_WORK_RATE
               , TAL_DUE_TSK
               , TAL_TSK_BALANCE
               , TAL_ACHIEVED_TSK
               , SCS_AMOUNT
               , SCS_QTY_REF_AMOUNT
               , SCS_DIVISOR_AMOUNT
               , SCS_PLAN_RATE
               , TAL_PLAN_RATE
               , TAL_NUM_UNITS_ALLOCATED
               , TAL_SEQ_ORIGIN
               , SCS_QTY_FIX_ADJUSTING
               , SCS_ADJUSTING_RATE
               , SCS_TRANSFERT_TIME
               , C_TASK_IMPUTATION
               , SCS_PLAN_PROP
               , TAL_BEGIN_PLAN_DATE
               , TAL_END_PLAN_DATE
               , TAL_BEGIN_REAL_DATE
               , TAL_END_REAL_DATE
               , TAL_TASK_MANUF_TIME
               , TAL_ACHIEVED_AD_TSK
               , C_RELATION_TYPE
               , SCS_DELAY
               , FAL_FAL_FACTORY_FLOOR_ID
               , SCS_NUM_FLOOR
               , SCS_ADJUSTING_FLOOR
               , SCS_ADJUSTING_OPERATOR
               , SCS_NUM_ADJUST_OPERATOR
               , SCS_PERCENT_ADJUST_OPER
               , SCS_WORK_FLOOR
               , SCS_WORK_OPERATOR
               , SCS_NUM_WORK_OPERATOR
               , SCS_PERCENT_WORK_OPER
               , TAL_TSK_W_BALANCE
               , TAL_TSK_AD_BALANCE
               , DIC_UNIT_OF_MEASURE_ID
               , SCS_CONVERSION_FACTOR
               , SCS_QTY_REF2_WORK
               , SCS_FREE_NUM1
               , SCS_FREE_NUM2
               , SCS_FREE_NUM3
               , SCS_FREE_NUM4
               , SCS_WEIGH
               , SCS_WEIGH_MANDATORY
               , SCS_OPEN_TIME_MACHINE
               , DIC_FREE_TASK_CODE_ID
               , DIC_FREE_TASK_CODE2_ID
               , DIC_FREE_TASK_CODE3_ID
               , DIC_FREE_TASK_CODE4_ID
               , DIC_FREE_TASK_CODE5_ID
               , DIC_FREE_TASK_CODE6_ID
               , DIC_FREE_TASK_CODE7_ID
               , DIC_FREE_TASK_CODE8_ID
               , DIC_FREE_TASK_CODE9_ID
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
               , A_DATECRE
               , A_IDCRE
                )
      select aCreatedScheduleStepId
           , aFalLotId
           , aSequence   -- SCS_STEP_NUMBER
           , '1'
           , FAL_TASK_ID
           , C_TASK_TYPE
           , TAS_SHORT_DESCR
           , TAS_LONG_DESCR
           , TAS_FREE_DESCR
           , FAL_FACTORY_FLOOR_ID
           , PAC_SUPPLIER_PARTNER_ID
           , GCO_GCO_GOOD_ID
           , PPS_OPERATION_PROCEDURE_ID
           , PPS_PPS_OPERATION_PROCEDURE_ID
           , aQty   -- TAL_PLAN_QTY
           , 0   -- TAL_AVALAIBLE_QTY
           , 0   -- TAL_RELEASE_QTY
           , 0   -- TAL_REJECTED_QTY
           , 0   -- TAL_R_METER
           , aQty   -- TAL_DUE_QTY
           , null   -- SCS_ADJUSTING_TIME
           , aScsWorkTime   -- SCS_WORK_TIME
           , aQty   -- SCS_QTY_REF_WORK
           , TAS_WORK_RATE
           , aScsWorkTime   -- TAL_DUE_TSK
           , aScsWorkTime   -- TAL_TSK_BALANCE
           , 0   -- TAL_ACHIEVED_TSK
           , TAS_AMOUNT   -- SCS_AMOUNT
           , TAS_QTY_REF_AMOUNT   -- SCS_QTY_REF_AMOUNT
           , TAS_DIVISOR_AMOUNT   -- SCS_DIVISOR_AMOUNT
           , TAS_PLAN_RATE   -- SCS_PLAN_RATE
           , 0   -- TAL_PLAN_RATE
           , TAS_NUM_FLOOR   -- TAL_NUM_UNITS_ALLOCATED
           , null   -- TAL_SEQ_ORIGIN
           , 0   -- SCS_QTY_FIX_ADJUSTING
           , TAS_ADJUSTING_RATE   -- SCS_ADJUSTING_RATE
           , TAS_TRANSFERT_TIME   -- SCS_TRANSFERT_TIME
           , nvl(C_TASK_IMPUTATION, '1')
           , TAS_PLAN_PROP   -- SCS_PLAN_PROP
           , null   -- TAL_BEGIN_PLAN_DATE
           , null   -- TAL_END_PLAN_DATE
           , null   -- TAL_BEGIN_REAL_DATE
           , null   -- TAL_END_REAL_DATE
           , null   -- TAL_TASK_MANUF_TIME
           , null   -- TAL_ACHIEVED_AD_TSK
           , '1'   -- C_RELATION_TYPE
           , null   -- SCS_DELAY
           , FAL_FAL_FACTORY_FLOOR_ID
           , TAS_NUM_FLOOR
           , TAS_ADJUSTING_FLOOR
           , TAS_ADJUSTING_OPERATOR
           , TAS_NUM_ADJUST_OPERATOR
           , TAS_PERCENT_ADJUST_OPER
           , TAS_WORK_FLOOR
           , TAS_WORK_OPERATOR
           , TAS_NUM_WORK_OPERATOR
           , TAS_PERCENT_WORK_OPER
           , aScsWorkTime   -- TAL_TSK_W_BALANCE
           , 0   -- TAL_TSK_AD_BALANCE
           , DIC_UNIT_OF_MEASURE_ID
           , nvl(TAS_CONVERSION_FACTOR, '1')
           , 1   -- SCS_QTY_REF2_WORK
           , TAS_FREE_NUM1
           , TAS_FREE_NUM2
           , TAS_FREE_NUM3
           , TAS_FREE_NUM4
           , TAS_WEIGH
           , TAS_WEIGH_MANDATORY
           , TAS_OPEN_TIME_MACHINE
           , DIC_FREE_TASK_CODE_ID
           , DIC_FREE_TASK_CODE2_ID
           , DIC_FREE_TASK_CODE3_ID
           , DIC_FREE_TASK_CODE4_ID
           , DIC_FREE_TASK_CODE5_ID
           , DIC_FREE_TASK_CODE6_ID
           , DIC_FREE_TASK_CODE7_ID
           , DIC_FREE_TASK_CODE8_ID
           , DIC_FREE_TASK_CODE9_ID
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
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from FAL_TASK
           , (select C_SCHEDULE_PLANNING
                from FAL_LOT
               where FAL_LOT_ID = aFalLotId) LOT
       where FAL_TASK_ID = aFalTaskId;
  end;

  procedure CreateOperation(
    iFalLotId              in FAL_LOT.FAL_LOT_ID%type default null
  , iFalListStepLinkId     in FAL_LIST_STEP_LINK.FAL_SCHEDULE_STEP_ID%type default null
  , iFalTaskLinkId         in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type default null
  , iSequence              in FAL_TASK_LINK.SCS_STEP_NUMBER%type default null
  , iQty                   in FAL_TASK_LINK.TAL_PLAN_QTY%type default 0
  , iCreatedScheduleStepId in FAL_LOT.FAL_LOT_ID%type default null
  , iContext               in integer default 0
  , iPacSupplierPartnerId  in number default null
  , iGcoGcoGoodId          in number default null
  , iScsAmount             in number default 0
  , iScsQtyRefAmount       in integer default 0
  , iScsDivisorAmount      in integer default 0
  , iScsWeigh              in integer default 0
  , iScsWeighMandatory     in integer default 0
  , iScsPlanRate           in number default 1
  , iScsPlanProp           in integer default 0
  , iScsQtyRefWork         in integer default 1
  )
  is
    lvInsertQuery varchar2(32000);
  begin
    lvInsertQuery  :=
      'insert into FAL_TASK_LINK ' ||
      '           (FAL_SCHEDULE_STEP_ID ' ||
      '          , FAL_LOT_ID ' ||
      '          , SCS_STEP_NUMBER ' ||
      '          , C_OPERATION_TYPE ' ||
      '          , FAL_TASK_ID ' ||
      '          , C_TASK_TYPE ' ||
      '          , SCS_SHORT_DESCR ' ||
      '          , SCS_LONG_DESCR ' ||
      '          , SCS_FREE_DESCR ' ||
      '          , FAL_FACTORY_FLOOR_ID ' ||
      '          , PPS_OPERATION_PROCEDURE_ID ' ||
      '          , PPS_PPS_OPERATION_PROCEDURE_ID ' ||
      '          , TAL_PLAN_QTY ' ||
      '          , TAL_AVALAIBLE_QTY ' ||
      '          , TAL_RELEASE_QTY ' ||
      '          , TAL_REJECTED_QTY ' ||
      '          , TAL_R_METER ' ||
      '          , TAL_DUE_QTY ' ||
      '          , SCS_ADJUSTING_TIME ' ||
      '          , SCS_WORK_TIME ' ||
      '          , SCS_WORK_RATE ' ||
      '          , TAL_DUE_TSK ' ||
      '          , TAL_TSK_BALANCE ' ||
      '          , TAL_ACHIEVED_TSK ' ||
      '          , TAL_PLAN_RATE ' ||
      '          , TAL_NUM_UNITS_ALLOCATED ' ||
      '          , SCS_QTY_FIX_ADJUSTING ' ||
      '          , SCS_ADJUSTING_RATE ' ||
      '          , SCS_TRANSFERT_TIME ' ||
      '          , C_TASK_IMPUTATION ' ||
      '          , TAL_BEGIN_PLAN_DATE ' ||
      '          , TAL_END_PLAN_DATE ' ||
      '          , TAL_BEGIN_REAL_DATE ' ||
      '          , TAL_END_REAL_DATE ' ||
      '          , TAL_TASK_MANUF_TIME ' ||
      '          , TAL_ACHIEVED_AD_TSK ' ||
      '          , C_RELATION_TYPE ' ||
      '          , SCS_DELAY ' ||
      '          , FAL_FAL_FACTORY_FLOOR_ID ' ||
      '          , SCS_NUM_FLOOR ' ||
      '          , SCS_ADJUSTING_FLOOR ' ||
      '          , SCS_ADJUSTING_OPERATOR ' ||
      '          , SCS_NUM_ADJUST_OPERATOR ' ||
      '          , SCS_PERCENT_ADJUST_OPER ' ||
      '          , SCS_WORK_FLOOR ' ||
      '          , SCS_WORK_OPERATOR ' ||
      '          , SCS_NUM_WORK_OPERATOR ' ||
      '          , SCS_PERCENT_WORK_OPER ' ||
      '          , TAL_TSK_W_BALANCE ' ||
      '          , TAL_TSK_AD_BALANCE ' ||
      '          , DIC_UNIT_OF_MEASURE_ID ' ||
      '          , SCS_CONVERSION_FACTOR ' ||
      '          , SCS_QTY_REF2_WORK ' ||
      '          , SCS_OPEN_TIME_MACHINE ' ||
      '          , SCS_FREE_NUM1 ' ||
      '          , SCS_FREE_NUM2 ' ||
      '          , SCS_FREE_NUM3 ' ||
      '          , SCS_FREE_NUM4 ' ||
      '          , DIC_FREE_TASK_CODE_ID ' ||
      '          , DIC_FREE_TASK_CODE2_ID ' ||
      '          , DIC_FREE_TASK_CODE3_ID ' ||
      '          , DIC_FREE_TASK_CODE4_ID ' ||
      '          , DIC_FREE_TASK_CODE5_ID ' ||
      '          , DIC_FREE_TASK_CODE6_ID ' ||
      '          , DIC_FREE_TASK_CODE7_ID ' ||
      '          , DIC_FREE_TASK_CODE8_ID ' ||
      '          , DIC_FREE_TASK_CODE9_ID ' ||
      '          , PPS_TOOLS1_ID ' ||
      '          , PPS_TOOLS2_ID ' ||
      '          , PPS_TOOLS3_ID ' ||
      '          , PPS_TOOLS4_ID ' ||
      '          , PPS_TOOLS5_ID ' ||
      '          , PPS_TOOLS6_ID ' ||
      '          , PPS_TOOLS7_ID ' ||
      '          , PPS_TOOLS8_ID ' ||
      '          , PPS_TOOLS9_ID ' ||
      '          , PPS_TOOLS10_ID ' ||
      '          , PPS_TOOLS11_ID ' ||
      '          , PPS_TOOLS12_ID ' ||
      '          , PPS_TOOLS13_ID ' ||
      '          , PPS_TOOLS14_ID ' ||
      '          , PPS_TOOLS15_ID ' ||
      '          , A_DATECRE ' ||
      '          , A_IDCRE ' ||
      '          , SCS_QTY_REF_WORK ' ||
      '          , PAC_SUPPLIER_PARTNER_ID ' ||
      '          , GCO_GCO_GOOD_ID ' ||
      '          , SCS_AMOUNT ' ||
      '          , SCS_QTY_REF_AMOUNT ' ||
      '          , SCS_DIVISOR_AMOUNT ' ||
      '          , SCS_WEIGH ' ||
      '          , SCS_WEIGH_MANDATORY ' ||
      '          , SCS_PLAN_RATE ' ||
      '          , SCS_PLAN_PROP ' ||
      '          , TAL_SEQ_ORIGIN ' ||
      '           ) ' ||
      ' select :aCreatedScheduleStepId ' ||
      '      , :aFalLotId ' ||
      '      , :aSequence ' ||
      '      , C_OPERATION_TYPE ' ||
      '      , FAL_TASK_ID ' ||
      '      , C_TASK_TYPE ' ||
      '      , SCS_SHORT_DESCR ' ||
      '      , SCS_LONG_DESCR ' ||
      '      , SCS_FREE_DESCR ' ||
      '      , FAL_FACTORY_FLOOR_ID ' ||
      '      , PPS_OPERATION_PROCEDURE_ID ' ||
      '      , PPS_PPS_OPERATION_PROCEDURE_ID ' ||
      '      , LOT.LOT_QTY ' ||   -- TAL_PLAN_QTY
      '      , 0 ' ||   -- TAL_AVALAIBLE_QTY
      '      , 0 ' ||   -- TAL_RELEASE_QTY
      '      , 0 ' ||   -- TAL_REJECTED_QTY
      '      , 0 ' ||   -- TAL_R_METER
      '      , LOT.LOT_QTY ' ||   -- TAL_DUE_QTY
      '      , SCS_ADJUSTING_TIME ' ||
      '      , SCS_WORK_TIME ' ||
      '      , SCS_WORK_RATE ' ||
      '      , case nvl(SCS_QTY_FIX_ADJUSTING, 0) ' ||
      '          when 0 then nvl(SCS_ADJUSTING_TIME, 0) + (LOT.LOT_QTY / nvl(SCS_QTY_REF_WORK, 1) ) * nvl(SCS_WORK_TIME, 0) ' ||
      '          else FAL_TOOLS.RoundSuccInt(:aQty / SCS_QTY_FIX_ADJUSTING) * nvl(SCS_ADJUSTING_TIME, 0) + ' ||
      '               (LOT.LOT_QTY / nvl(SCS_QTY_REF_WORK, 1) ' ||
      '               ) * nvl(SCS_WORK_TIME, 0) ' ||
      '        end TAL_DUE_TSK ' ||
      '      , case nvl(SCS_QTY_FIX_ADJUSTING, 0) ' ||
      '          when 0 then nvl(SCS_ADJUSTING_TIME, 0) + (LOT.LOT_QTY / nvl(SCS_QTY_REF_WORK, 1) ) * nvl(SCS_WORK_TIME, 0) ' ||
      '          else FAL_TOOLS.RoundSuccInt(LOT.LOT_QTY / SCS_QTY_FIX_ADJUSTING) * nvl(SCS_ADJUSTING_TIME, 0) + ' ||
      '               (LOT.LOT_QTY / nvl(SCS_QTY_REF_WORK, 1) ' ||
      '               ) * nvl(SCS_WORK_TIME, 0) ' ||
      '        end TAL_TSK_BALANCE ' ||
      '      , 0 ' ||   -- TAL_ACHIEVED_TSK
      '      , (LOT.LOT_QTY / nvl(SCS_QTY_REF_WORK, 1) ) * nvl(SCS_PLAN_RATE, 0) ' || -- TAL_PLAN_RATE
      '      , SCS_NUM_FLOOR ' ||   -- TAL_NUM_UNITS_ALLOCATED
      '      , SCS_QTY_FIX_ADJUSTING ' ||
      '      , SCS_ADJUSTING_RATE ' ||
      '      , SCS_TRANSFERT_TIME ' ||
      '      , C_TASK_IMPUTATION ' ||
      '      , null ' ||   -- TAL_BEGIN_PLAN_DATE
      '      , null ' ||   -- TAL_END_PLAN_DATE
      '      , null ' ||   -- TAL_BEGIN_REAL_DATE
      '      , null ' ||   -- TAL_END_REAL_DATE
      '      , null ' ||   -- TAL_TASK_MANUF_TIME
      '      , 0    ' ||   -- TAL_ACHIEVED_AD_TSK
      '      , C_RELATION_TYPE ' ||
      '      , SCS_DELAY ' ||
      '      , FAL_FAL_FACTORY_FLOOR_ID ' ||
      '      , SCS_NUM_FLOOR ' ||
      '      , SCS_ADJUSTING_FLOOR ' ||
      '      , SCS_ADJUSTING_OPERATOR ' ||
      '      , SCS_NUM_ADJUST_OPERATOR ' ||
      '      , SCS_PERCENT_ADJUST_OPER ' ||
      '      , SCS_WORK_FLOOR ' ||
      '      , SCS_WORK_OPERATOR ' ||
      '      , SCS_NUM_WORK_OPERATOR ' ||
      '      , SCS_PERCENT_WORK_OPER ' ||
      '      , (LOT.LOT_QTY / nvl(SCS_QTY_REF_WORK, 1) ) * nvl(SCS_WORK_TIME, 0) ' ||   -- TAL_TSK_W_BALANCE
      '      , case nvl(SCS_QTY_FIX_ADJUSTING, 0) ' ||
      '          when 0 then nvl(SCS_ADJUSTING_TIME, 0) ' ||
      '          else FAL_TOOLS.RoundSuccInt(LOT.LOT_QTY / SCS_QTY_FIX_ADJUSTING) * nvl(SCS_ADJUSTING_TIME, 0) ' ||
      '        end TAL_TSK_AD_BALANCE ' ||
      '      , DIC_UNIT_OF_MEASURE_ID ' ||
      '      , SCS_CONVERSION_FACTOR ' ||
      '      , SCS_QTY_REF2_WORK ' ||
      '      , SCS_OPEN_TIME_MACHINE ' ||
      '      , SCS_FREE_NUM1 ' ||
      '      , SCS_FREE_NUM2 ' ||
      '      , SCS_FREE_NUM3 ' ||
      '      , SCS_FREE_NUM4 ' ||
      '      , DIC_FREE_TASK_CODE_ID ' ||
      '      , DIC_FREE_TASK_CODE2_ID ' ||
      '      , DIC_FREE_TASK_CODE3_ID ' ||
      '      , DIC_FREE_TASK_CODE4_ID ' ||
      '      , DIC_FREE_TASK_CODE5_ID ' ||
      '      , DIC_FREE_TASK_CODE6_ID ' ||
      '      , DIC_FREE_TASK_CODE7_ID ' ||
      '      , DIC_FREE_TASK_CODE8_ID ' ||
      '      , DIC_FREE_TASK_CODE9_ID ' ||
      '      , PPS_TOOLS1_ID ' ||
      '      , PPS_TOOLS2_ID ' ||
      '      , PPS_TOOLS3_ID ' ||
      '      , PPS_TOOLS4_ID ' ||
      '      , PPS_TOOLS5_ID ' ||
      '      , PPS_TOOLS6_ID ' ||
      '      , PPS_TOOLS7_ID ' ||
      '      , PPS_TOOLS8_ID ' ||
      '      , PPS_TOOLS9_ID ' ||
      '      , PPS_TOOLS10_ID ' ||
      '      , PPS_TOOLS11_ID ' ||
      '      , PPS_TOOLS12_ID ' ||
      '      , PPS_TOOLS13_ID ' ||
      '      , PPS_TOOLS14_ID ' ||
      '      , PPS_TOOLS15_ID ' ||
      '      , sysdate ' ||   -- A_DATECRE
      '      , PCS.PC_I_LIB_SESSION.GetUserIni ';

    -- Opération d'of standard
    if nvl(iContext, 0) <> FAL_TASK_GENERATOR.ctxtSubContracting then
      lvInsertQuery  :=
        lvInsertQuery ||
        '      , SCS_QTY_REF_WORK ' ||
        '      , PAC_SUPPLIER_PARTNER_ID ' ||
        '      , GCO_GCO_GOOD_ID ' ||
        '      , SCS_AMOUNT ' ||
        '      , SCS_QTY_REF_AMOUNT ' ||
        '      , SCS_DIVISOR_AMOUNT ' ||
        '      , SCS_WEIGH ' ||
        '      , SCS_WEIGH_MANDATORY ' ||
        '      , SCS_PLAN_RATE ' ||
        '      , SCS_PLAN_PROP ';
    -- Opération d'of de sous-traitance d'achat
    else
      lvInsertQuery  :=
        lvInsertQuery ||
        '      , :aScsQtyRefWork ' ||
        '      , :aPacSupplierPartnerId ' ||
        '      , :aGcoGcoGoodId ' ||
        '      , :aScsAmount ' ||
        '      , :aScsQtyRefAmount ' ||
        '      , :aScsDivisorAmount ' ||
        '      , :aScsWeigh ' ||
        '      , :aScsWeighMandatory ' ||
        '      , :aScsPlanRate' ||
        '      , :aScsPlanProp';
    end if;

    if iFalListStepLinkId is not null then
      lvInsertQuery  := lvInsertQuery || ' , SCS_STEP_NUMBER ' ||   -- TAL_SEQ_ORIGIN
                                                                 '    from FAL_LIST_STEP_LINK ';
    else
      lvInsertQuery  := lvInsertQuery || ' , TAL_SEQ_ORIGIN ' || '    from FAL_TASK_LINK ';
    end if;

    lvInsertQuery  :=
      lvInsertQuery ||
      '      , (select C_SCHEDULE_PLANNING ' ||
      '              , :aQty LOT_QTY ' ||
      '           from FAL_LOT ' ||
      '          where FAL_LOT_ID = :aFalLotId) LOT ' ||
      '  where FAL_SCHEDULE_STEP_ID = :aFalListStepLinkId ';

    -- Opération d'of standard
    if nvl(iContext, 0) <> FAL_TASK_GENERATOR.ctxtSubContracting then
      execute immediate lvInsertQuery
                  using iCreatedScheduleStepId, iFalLotId, iSequence, iQty, iQty, iFalLotId, nvl(iFalListStepLinkId, iFalTaskLinkId);
    -- Opération d'of de sous-traitance d'achat
    else
      execute immediate lvInsertQuery
                  using iCreatedScheduleStepId
                      , iFalLotId
                      , iSequence
                      , iQty
                      , iScsQtyRefWork
                      , iPacSupplierPartnerId
                      , iGcoGcoGoodId
                      , iScsAmount
                      , iScsQtyRefAmount
                      , iScsDivisorAmount
                      , iScsWeigh
                      , iScsWeighMandatory
                      , iScsPlanRate
                      , iScsPlanProp
                      , iQty
                      , iFalLotId
                      , nvl(iFalListStepLinkId, iFalTaskLinkId);
    end if;

    -- Génération des LMU
    if nvl(iContext, 0) <> FAL_TASK_GENERATOR.ctxtBatchAssembly then
      lvInsertQuery  :=
        '   insert into FAL_TASK_LINK_USE ' ||
        '               (FAL_TASK_LINK_USE_ID ' ||
        '              , FAL_FACTORY_FLOOR_ID ' ||
        '              , FAL_SCHEDULE_STEP_ID ' ||
        '              , A_DATECRE ' ||
        '              , A_IDCRE ' ||
        '              , SCS_QTY_REF_WORK ' ||
        '              , SCS_WORK_TIME ' ||
        '              , SCS_PRIORITY ' ||
        '              , SCS_EXCEPT_MACH ' ||
        '               ) ' ||
        '     select GetNewId ' ||
        '          , FAL_FACTORY_FLOOR_ID ' ||
        '          , :aCreatedScheduleStepId ' ||
        '          , sysdate ' ||
        '          , PCS.PC_I_LIB_SESSION.GetUserIni ';

      if iFalListStepLinkId is not null then
        lvInsertQuery  :=
          lvInsertQuery ||
          '          , LSU_QTY_REF_WORK ' ||
          '          , LSU_WORK_TIME ' ||
          '          , LSU_PRIORITY ' ||
          '          , LSU_EXCEPT_MACH ' ||
          '       from FAL_LIST_STEP_USE ';
      else
        lvInsertQuery  :=
          lvInsertQuery ||
          '          , SCS_QTY_REF_WORK ' ||
          '          , SCS_WORK_TIME ' ||
          '          , SCS_PRIORITY ' ||
          '          , SCS_EXCEPT_MACH ' ||
          '       from FAL_TASK_LINK_USE ';
      end if;

      lvInsertQuery  := lvInsertQuery || '  where FAL_SCHEDULE_STEP_ID = :aFalListStepLinkId';

      execute immediate lvInsertQuery
                  using iCreatedScheduleStepId, nvl(iFalListStepLinkId, iFalTaskLinkId);
    end if;
  end;

  /**
  * procedure CreateBatchOperation
  * Description : Génération d'une opération de lot
  *
  * @lastUpdate
  * @public
  * @param   iFalLotId              : lot de fabrication
  * @param   iQty                   : Quantité
  * @param   iFalListStepLinkId     : Opération de gamme
  * @param   iFalTaskId             : Opération standard
  * @param   iFalTaskLinkId         : Opération de lot
  * @param   iSequence              : Séquence
  * @param   iScsWorkTime           : Temps travail
  * @param   iContext               : Contexte d'appel
  * @param   iPacSupplierPartnerId  : Fournisseur
  * @param   iGcoGcoGoodId          : Bien liés
  * @param   iScsAmount             : Montant
  * @param   iScsQtyRefAmount       : Qté référence montant
  * @param   iScsDivisorAmount      : Diviseur
  * @param   iScsWeigh              : Pesées matières précieuses
  * @param   iScsWeighMandatory     : Pesées Obligatoires
  * @param   iScsPlanRate            Durée en jours
  * @param   iScsPlanProp            Durée proportionnelle ou fixe
  * @param   iScsQtyRefWork          Qté de référence travail
  */
  function CreateBatchOperation(
    iFalLotId             in FAL_LOT.FAL_LOT_ID%type
  , iQty                  in FAL_TASK_LINK.TAL_PLAN_QTY%type
  , iFalListStepLinkId    in FAL_LIST_STEP_LINK.FAL_SCHEDULE_STEP_ID%type default null
  , iFalTaskId            in FAL_TASK.FAL_TASK_ID%type default null
  , iFalTaskLinkId        in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type default null
  , iSequence             in FAL_TASK_LINK.SCS_STEP_NUMBER%type default null
  , iScsWorkTime          in FAL_TASK_LINK.SCS_WORK_TIME%type default 0
  , iContext              in integer default FAL_TASK_GENERATOR.ctxtBatchCreation
  , iPacSupplierPartnerId in number default null
  , iGcoGcoGoodId         in number default null
  , iScsAmount            in number default 0
  , iScsQtyRefAmount      in integer default 0
  , iScsDivisorAmount     in integer default 0
  , iScsWeigh             in integer default 0
  , iScsWeighMandatory    in integer default 0
  , iScsPlanRate          in number default 1
  , iScsPlanProp          in integer default 0
  , iScsQtyRefWork        in integer default 1
  )
    return FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  is
    liSequence              FAL_TASK_LINK.SCS_STEP_NUMBER%type;
    lnCreatedScheduleStepId FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type;
  begin
    lnCreatedScheduleStepId  := GetNewId;

    select max(SCS_STEP_NUMBER)
      into liSequence
      from FAL_TASK_LINK
     where FAL_LOT_ID = iFalLotId
       and SCS_STEP_NUMBER = iSequence;

    -- Si la séquence est null ou qu'elle existe déjà (vSequence <> null)
    if    (iSequence is null)
       or (liSequence is not null) then
      select nvl(max(SCS_STEP_NUMBER), 0) + PCS.PC_CONFIG.GetConfig('PPS_TASK_NUMBERING')
        into liSequence
        from FAL_TASK_LINK
       where FAL_LOT_ID = iFalLotId;
    else
      liSequence  := iSequence;
    end if;

    if    (iFalListStepLinkId is not null)
       or (iFalTaskLinkId is not null) then
      -- Création d'une opération de lot depuis une opération de gamme ou d'une autre opération de lot
      -- Contexte de sous-traitance d'achat, certaines infos proviennent des données compl de stt.
      CreateOperation(iFalLotId                => iFalLotId
                    , iFalListStepLinkId       => iFalListStepLinkId
                    , iFalTaskLinkId           => iFalTaskLinkId
                    , iSequence                => liSequence
                    , iQty                     => iQty
                    , iCreatedScheduleStepId   => lnCreatedScheduleStepId
                    , iContext                 => iContext
                    , iPacSupplierPartnerId    => iPacSupplierPartnerId
                    , iGcoGcoGoodId            => iGcoGcoGoodId
                    , iScsAmount               => iScsAmount
                    , iScsQtyRefAmount         => iScsQtyRefAmount
                    , iScsDivisorAmount        => iScsDivisorAmount
                    , iScsWeigh                => iScsWeigh
                    , iScsWeighMandatory       => iScsWeighMandatory
                    , iScsPlanRate             => iScsPlanRate
                    , iScsPlanProp             => iScsPlanProp
                    , iScsQtyRefWork           => iScsQtyRefWork
                     );
    else
      -- Création d'une opération de lot depuis une opération standard
      CreateOperationFromStandardOpe(aFalLotId                => iFalLotId
                                   , aFalTaskId               => iFalTaskId
                                   , aSequence                => liSequence
                                   , aQty                     => iQty
                                   , aScsWorkTime             => nvl(iScsWorkTime, 0)
                                   , aCreatedScheduleStepId   => lnCreatedScheduleStepId
                                    );
    end if;

    -- En contexte d'assemblage, la QtéRéalisée = Qté totale du lot et QtéSolde = 0, ...
    if iContext = FAL_TASK_GENERATOR.ctxtBatchAssembly then
      update FAL_TASK_LINK
         set TAL_RELEASE_QTY = iQty
           , TAL_DUE_QTY = 0
           , TAL_TSK_BALANCE = 0
           , TAL_ACHIEVED_TSK = (iQty / nvl(SCS_QTY_REF_WORK, 1) ) * nvl(SCS_WORK_TIME, 0)
           , TAL_PLAN_RATE = 0
           , TAL_TASK_MANUF_TIME = 0
           , TAL_ACHIEVED_AD_TSK =
               case nvl(SCS_QTY_FIX_ADJUSTING, 0)
                 when 0 then nvl(SCS_ADJUSTING_TIME, 0)
                 else FAL_TOOLS.RoundSuccInt(iQty / nvl(SCS_QTY_FIX_ADJUSTING, 1) ) * nvl(SCS_ADJUSTING_TIME, 0)
               end
           , TAL_BEGIN_PLAN_DATE = (select LOT_OPEN__DTE
                                      from FAL_LOT
                                     where FAL_LOT_ID = iFalLotId)
           , TAL_END_PLAN_DATE = (select LOT_OPEN__DTE
                                    from FAL_LOT
                                   where FAL_LOT_ID = iFalLotId)
           , TAL_BEGIN_REAL_DATE = (select LOT_OPEN__DTE
                                      from FAL_LOT
                                     where FAL_LOT_ID = iFalLotId)
           , TAL_END_REAL_DATE = (select LOT_OPEN__DTE
                                    from FAL_LOT
                                   where FAL_LOT_ID = iFalLotId)
       where FAL_SCHEDULE_STEP_ID = lnCreatedScheduleStepId;
    end if;

    /* Est-ce que la matière précieuse est gérée ? Si ce n'est pas le cas, on ne fait rien */
    if GCO_I_LIB_PRECIOUS_MAT.IsPreciousMat = 1 then
      /* Est-ce que le produit terminé contient un alliage de matière précieuse ? */
      if GCO_I_LIB_PRECIOUS_MAT.doesContainsPreciousMat(inGcoGoodID => FAL_LIB_BATCH.getGcoGoodID(inFalLotID => iFalLotId) ) = 1 then
        /* Copie des information de déchets récupérables (copeaux) pour chaque définition d'alliage de l'opération également présent dans le produit terminé. */
        if iFalListStepLinkId is null then
          /* Copie depuis l'opération de lot (éclatement) */
          FAL_I_PRC_TASK_CHIP.copyTaskChipInfos(inSrcTaskID                    => iFalTaskLinkId
                                              , inDestTaskID                   => lnCreatedScheduleStepId
                                              , ivCSrcTaskKind                 => '3'   -- Lot
                                              , ivCDestTaskKind                => '3'   -- Lot
                                              , ibOnlyIfRefGoodContainsAlloy   => true
                                               );
        else
          /* Copie depuis l'oppération de gamme (création, modification) */
          FAL_I_PRC_TASK_CHIP.copyTaskChipInfos(inSrcTaskID                    => iFalListStepLinkId
                                              , inDestTaskID                   => lnCreatedScheduleStepId
                                              , ivCSrcTaskKind                 => '2'   -- Gamme
                                              , ivCDestTaskKind                => '3'   -- Lot
                                              , ibOnlyIfRefGoodContainsAlloy   => true
                                               );
        end if;
      end if;
    end if;

    return lnCreatedScheduleStepId;
  end CreateBatchOperation;

  /**
  * procedure UpdateBatchOpeFixedLink
  * Description
  *   Mise à jour dans un lot des opérations de type relation 3 (lien solide)
  *   pour avoir les mêmes atelier (sous-traitant) et LMU que l'opération précédente
  * @author CLE
  * @lastUpdate
  * @Public
  * @param     aFalLotId   Lot à mettre à jour
  */
  procedure UpdateBatchOpeFixedLink(aFalLotId FAL_LOT.FAL_LOT_ID%type)
  is
  begin
    -- Mise à jour des opérations de type lien solide. L'atelier et le sous-traitant sont les mêmes que ceux de l'opération précédente,
    -- le nombre d'unités affecté est forcément de 1.
    update FAL_TASK_LINK FTL1
       set (FAL_FACTORY_FLOOR_ID, PAC_SUPPLIER_PARTNER_ID, TAL_NUM_UNITS_ALLOCATED) =
             (select FAL_FACTORY_FLOOR_ID
                   , PAC_SUPPLIER_PARTNER_ID
                   , 1
                from FAL_TASK_LINK
               where FAL_LOT_ID = aFalLotId
                 and SCS_STEP_NUMBER = (select max(SCS_STEP_NUMBER)
                                          from FAL_TASK_LINK
                                         where SCS_STEP_NUMBER < FTL1.SCS_STEP_NUMBER
                                           and C_RELATION_TYPE <> '3'
                                           and FAL_LOT_ID = aFalLotId) )
     where FAL_LOT_ID = aFalLotId
       and C_RELATION_TYPE = '3';

    -- Mise à 1 du nombre d'unités affectés pour les opérations précédant celles en affectation lien solide
    update FAL_TASK_LINK
       set TAL_NUM_UNITS_ALLOCATED = 1
     where FAL_LOT_ID = aFalLotId
       and FAL_SCHEDULE_STEP_ID in(
             select FAL_SCHEDULE_STEP_ID
               from FAL_TASK_LINK OPE
              where FAL_LOT_ID = aFalLotId
                and C_RELATION_TYPE <> '3'
                and (select C_RELATION_TYPE
                       from FAL_TASK_LINK
                      where FAL_LOT_ID = aFalLotId
                        and SCS_STEP_NUMBER = (select min(SCS_STEP_NUMBER)
                                                 from FAL_TASK_LINK
                                                where FAL_LOT_ID = aFalLotId
                                                  and SCS_STEP_NUMBER > OPE.SCS_STEP_NUMBER) ) = '3');

    -- Mise à jour de la priorité et de l'exception des LMU de même machine utilisable pour les opérations de type lien solide
    update FAL_TASK_LINK_USE FTLU
       set (SCS_PRIORITY, SCS_EXCEPT_MACH) =
             (select SCS_PRIORITY
                   , SCS_EXCEPT_MACH
                from FAL_TASK_LINK_USE
               where FAL_SCHEDULE_STEP_ID =
                       (select FAL_SCHEDULE_STEP_ID
                          from FAL_TASK_LINK
                         where FAL_LOT_ID = aFalLotId
                           and SCS_STEP_NUMBER =
                                 (select max(SCS_STEP_NUMBER)
                                    from FAL_TASK_LINK
                                   where SCS_STEP_NUMBER < (select SCS_STEP_NUMBER
                                                              from FAL_TASK_LINK
                                                             where FAL_SCHEDULE_STEP_ID = FTLU.FAL_SCHEDULE_STEP_ID)
                                     and C_RELATION_TYPE <> '3'
                                     and FAL_LOT_ID = aFalLotId) )
                 and FAL_FACTORY_FLOOR_ID = FTLU.FAL_FACTORY_FLOOR_ID)
     where FAL_SCHEDULE_STEP_ID in(select FAL_SCHEDULE_STEP_ID
                                     from FAL_TASK_LINK
                                    where FAL_LOT_ID = aFalLotId
                                      and C_RELATION_TYPE = '3');

    -- Suppression des LMU des opérations de type lien solide dont la machine n'est pas sur l'opération précédente
    delete from FAL_TASK_LINK_USE FTLU
          where FAL_SCHEDULE_STEP_ID in(select FAL_SCHEDULE_STEP_ID
                                          from FAL_TASK_LINK
                                         where FAL_LOT_ID = aFalLotId
                                           and C_RELATION_TYPE = '3')
            and FAL_FACTORY_FLOOR_ID not in(
                  select FAL_FACTORY_FLOOR_ID
                    from FAL_TASK_LINK_USE
                   where FAL_SCHEDULE_STEP_ID =
                           (select FAL_SCHEDULE_STEP_ID
                              from FAL_TASK_LINK FTL
                             where FAL_LOT_ID = aFalLotId
                               and SCS_STEP_NUMBER =
                                     (select max(SCS_STEP_NUMBER)
                                        from FAL_TASK_LINK
                                       where SCS_STEP_NUMBER < (select SCS_STEP_NUMBER
                                                                  from FAL_TASK_LINK
                                                                 where FAL_SCHEDULE_STEP_ID = FTLU.FAL_SCHEDULE_STEP_ID)
                                         and C_RELATION_TYPE <> '3'
                                         and FAL_LOT_ID = aFalLotId) ) );

    -- Insertion des LMU pour avoir la même liste que l'opération précédente
    insert into FAL_TASK_LINK_USE
                (FAL_TASK_LINK_USE_ID
               , FAL_SCHEDULE_STEP_ID
               , FAL_FACTORY_FLOOR_ID
               , SCS_QTY_REF_WORK
               , SCS_WORK_TIME
               , SCS_PRIORITY
               , SCS_EXCEPT_MACH
               , A_DATECRE
               , A_IDCRE
                )
      select GetNewId
           , FTL.FAL_SCHEDULE_STEP_ID
           , FTLU.FAL_FACTORY_FLOOR_ID
           , FTLU.SCS_QTY_REF_WORK
           , FTLU.SCS_WORK_TIME
           , FTLU.SCS_PRIORITY
           , FTLU.SCS_EXCEPT_MACH
           , sysdate
           , PCS.PC_I_LIB_SESSION.GETUSERINI
        from FAL_TASK_LINK_USE FTLU
           , FAL_TASK_LINK FTL
       where FTLU.FAL_SCHEDULE_STEP_ID in(
               select FAL_SCHEDULE_STEP_ID
                 from FAL_TASK_LINK
                where FAL_LOT_ID = aFalLotId
                  and SCS_STEP_NUMBER = (select max(SCS_STEP_NUMBER)
                                           from FAL_TASK_LINK
                                          where SCS_STEP_NUMBER < FTL.SCS_STEP_NUMBER
                                            and C_RELATION_TYPE <> '3'
                                            and FAL_LOT_ID = aFalLotId) )
         and FTLU.FAL_FACTORY_FLOOR_ID not in(select FAL_FACTORY_FLOOR_ID
                                                from FAL_TASK_LINK_USE
                                               where FAL_SCHEDULE_STEP_ID = FTL.FAL_SCHEDULE_STEP_ID)
         and FAL_LOT_ID = aFalLotId
         and C_RELATION_TYPE = '3';
  end;

  /**
  * procedure UpdateProcessPlanOpeFixedLink
  * Description
  *   Mise à jour dans une gamme des opérations de type relation 3 (lien solide)
  *   pour avoir les mêmes atelier (sous-traitant) et LMU que l'opération précédente
  * @author CLE
  * @lastUpdate
  * @Public
  * @param     aFalSchedulePlanId   Gamme à mettre à jour
  */
  procedure UpdateProcessPlanOpeFixedLink(aFalSchedulePlanId FAL_SCHEDULE_PLAN.FAL_SCHEDULE_PLAN_ID%type)
  is
  begin
    -- Mise à jour des opérations de type lien solide. L'atelier et le sous-traitant sont les mêmes que ceux de l'opération précédente,
    -- le nombre d'unités affecté est forcément de 1.
    update FAL_LIST_STEP_LINK FLSL
       set (FAL_FACTORY_FLOOR_ID, PAC_SUPPLIER_PARTNER_ID, SCS_NUM_FLOOR) =
             (select FAL_FACTORY_FLOOR_ID
                   , PAC_SUPPLIER_PARTNER_ID
                   , 1
                from FAL_LIST_STEP_LINK
               where FAL_SCHEDULE_PLAN_ID = aFalSchedulePlanId
                 and SCS_STEP_NUMBER = (select max(SCS_STEP_NUMBER)
                                          from FAL_LIST_STEP_LINK
                                         where SCS_STEP_NUMBER < FLSL.SCS_STEP_NUMBER
                                           and C_RELATION_TYPE <> '3'
                                           and FAL_SCHEDULE_PLAN_ID = aFalSchedulePlanId) )
     where FAL_SCHEDULE_PLAN_ID = aFalSchedulePlanId
       and C_RELATION_TYPE = '3';

    -- Mise à 1 du nombre d'unités affectés pour les opérations précédant celles en affectation lien solide
    update FAL_LIST_STEP_LINK
       set SCS_NUM_FLOOR = 1
     where FAL_SCHEDULE_PLAN_ID = aFalSchedulePlanId
       and FAL_SCHEDULE_STEP_ID in(
             select FAL_SCHEDULE_STEP_ID
               from FAL_LIST_STEP_LINK OPE
              where FAL_SCHEDULE_PLAN_ID = aFalSchedulePlanId
                and C_RELATION_TYPE <> '3'
                and (select C_RELATION_TYPE
                       from FAL_LIST_STEP_LINK
                      where FAL_SCHEDULE_PLAN_ID = aFalSchedulePlanId
                        and SCS_STEP_NUMBER = (select min(SCS_STEP_NUMBER)
                                                 from FAL_LIST_STEP_LINK
                                                where FAL_SCHEDULE_PLAN_ID = aFalSchedulePlanId
                                                  and SCS_STEP_NUMBER > OPE.SCS_STEP_NUMBER) ) = '3');

    -- Mise à jour de la priorité et de l'exception des LMU de même machine utilisable pour les opérations de type lien solide
    update FAL_LIST_STEP_USE FLSU
       set (LSU_PRIORITY, LSU_EXCEPT_MACH) =
             (select LSU_PRIORITY
                   , LSU_EXCEPT_MACH
                from FAL_LIST_STEP_USE
               where FAL_SCHEDULE_STEP_ID =
                       (select FAL_SCHEDULE_STEP_ID
                          from FAL_LIST_STEP_LINK
                         where FAL_SCHEDULE_PLAN_ID = aFalSchedulePlanId
                           and SCS_STEP_NUMBER =
                                 (select max(SCS_STEP_NUMBER)
                                    from FAL_LIST_STEP_LINK
                                   where SCS_STEP_NUMBER < (select SCS_STEP_NUMBER
                                                              from FAL_LIST_STEP_LINK
                                                             where FAL_SCHEDULE_STEP_ID = FLSU.FAL_SCHEDULE_STEP_ID)
                                     and C_RELATION_TYPE <> '3'
                                     and FAL_SCHEDULE_PLAN_ID = aFalSchedulePlanId) )
                 and FAL_FACTORY_FLOOR_ID = FLSU.FAL_FACTORY_FLOOR_ID)
     where FAL_SCHEDULE_STEP_ID in(select FAL_SCHEDULE_STEP_ID
                                     from FAL_LIST_STEP_LINK
                                    where FAL_SCHEDULE_PLAN_ID = aFalSchedulePlanId
                                      and C_RELATION_TYPE = '3');

    -- Suppression des LMU des opérations de type lien solide
    delete from FAL_LIST_STEP_USE FLSU
          where FAL_SCHEDULE_STEP_ID in(select FAL_SCHEDULE_STEP_ID
                                          from FAL_LIST_STEP_LINK
                                         where FAL_SCHEDULE_PLAN_ID = aFalSchedulePlanId
                                           and C_RELATION_TYPE = '3')
            and FAL_FACTORY_FLOOR_ID not in(
                  select FAL_FACTORY_FLOOR_ID
                    from FAL_LIST_STEP_USE
                   where FAL_SCHEDULE_STEP_ID =
                           (select FAL_SCHEDULE_STEP_ID
                              from FAL_LIST_STEP_LINK FTL
                             where FAL_SCHEDULE_PLAN_ID = aFalSchedulePlanId
                               and SCS_STEP_NUMBER =
                                     (select max(SCS_STEP_NUMBER)
                                        from FAL_LIST_STEP_LINK
                                       where SCS_STEP_NUMBER < (select SCS_STEP_NUMBER
                                                                  from FAL_LIST_STEP_LINK
                                                                 where FAL_SCHEDULE_STEP_ID = FLSU.FAL_SCHEDULE_STEP_ID)
                                         and C_RELATION_TYPE <> '3'
                                         and FAL_SCHEDULE_PLAN_ID = aFalSchedulePlanId) ) );

    -- Insertion des LMU pour avoir la même liste que l'opération précédente
    insert into FAL_LIST_STEP_USE
                (FAL_LIST_STEP_USE_ID
               , FAL_SCHEDULE_STEP_ID
               , FAL_FACTORY_FLOOR_ID
               , LSU_QTY_REF_WORK
               , LSU_WORK_TIME
               , LSU_PRIORITY
               , LSU_EXCEPT_MACH
               , A_DATECRE
               , A_IDCRE
                )
      select GetNewId
           , FLSL.FAL_SCHEDULE_STEP_ID
           , FLSU.FAL_FACTORY_FLOOR_ID
           , FLSU.LSU_QTY_REF_WORK
           , FLSU.LSU_WORK_TIME
           , FLSU.LSU_PRIORITY
           , FLSU.LSU_EXCEPT_MACH
           , sysdate
           , PCS.PC_I_LIB_SESSION.GETUSERINI
        from FAL_LIST_STEP_USE FLSU
           , FAL_LIST_STEP_LINK FLSL
       where FLSU.FAL_SCHEDULE_STEP_ID in(
               select FAL_SCHEDULE_STEP_ID
                 from FAL_LIST_STEP_LINK
                where FAL_SCHEDULE_PLAN_ID = aFalSchedulePlanId
                  and SCS_STEP_NUMBER = (select max(SCS_STEP_NUMBER)
                                           from FAL_LIST_STEP_LINK
                                          where SCS_STEP_NUMBER < FLSL.SCS_STEP_NUMBER
                                            and C_RELATION_TYPE <> '3'
                                            and FAL_SCHEDULE_PLAN_ID = aFalSchedulePlanId) )
         and FLSU.FAL_FACTORY_FLOOR_ID not in(select FAL_FACTORY_FLOOR_ID
                                                from FAL_LIST_STEP_USE
                                               where FAL_SCHEDULE_STEP_ID = FLSL.FAL_SCHEDULE_STEP_ID)
         and FAL_SCHEDULE_PLAN_ID = aFalSchedulePlanId
         and C_RELATION_TYPE = '3';
  end;

  /**
  * procedure UpdateOperationFixedLink
  * Description
  *   Mise à jour des opérations de type relation 3 (lien solide) pour avoir
  *   les mêmes ateliers (sous-traitants) et LMU que l'opération précédente
  * @author CLE
  * @lastUpdate
  * @Public
  * @param     aBatchOrProcessPlanId  Lot ou gamme à mettre à jour
  * @param     aIsBatch               Defini si aBatchOrProcessPlanId est un OF ou une gamme
  */
  procedure UpdateOperationFixedLink(aBatchOrProcessPlanId FAL_LOT.FAL_LOT_ID%type, aIsBatch integer default 1)
  is
  begin
    if aIsBatch = 1 then
      UpdateBatchOpeFixedLink(aBatchOrProcessPlanId);
    else
      UpdateProcessPlanOpeFixedLink(aBatchOrProcessPlanId);
    end if;
  end UpdateOperationFixedLink;

  /**
  * procedure UpdateSubcPurchaseOperation
  * Description
  *   Mise à jour des opérations de sous-traitance d'achat avec les informations en provenance
  *   de la fiche produit
  * @author ECA
  * @lastUpdate
  * @Public
  * @param   iFalLotPropId : Proposition de fabrication
  * @param   iGcoComplDataSubcontractID : Donnée complémentaire de sous-traitance
  * @param   iTotalQty : Qté totale
  */
  procedure UpdateSubcPurchaseOperation(iFalLotPropId in number, iGcoComplDataSubContractID in number, iTotalQty in number)
  is
    lrtGcoComplDataSubContract GCO_COMPL_DATA_SUBCONTRACT%rowtype;
  begin
    lrtGcoComplDataSubContract  := GCO_LIB_COMPL_DATA.GetSubCComplDataTuple(iGcoComplDataSubContractID);

    if nvl(lrtGcoComplDataSubContract.GCO_COMPL_DATA_SUBCONTRACT_ID, 0) <> 0 then
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
                      (iTotalQty / FAL_TOOLS.nvla(lrtGcoComplDataSubContract.CSU_LOT_QUANTITY, 1) )
                      * nvl(lrtGcoComplDataSubContract.CSU_SUBCONTRACTING_DELAY, 0)
           , TAL_DUE_AMT = iTotalQty * nvl(lrtGcoComplDataSubContract.CSU_AMOUNT, 0)
       where FAL_TASK_LINK_PROP_ID in(select TAL.FAL_TASK_LINK_PROP_ID
                                        from FAL_TASK_LINK_PROP TAL
                                           , FAL_LOT_PROP FLP
                                       where FLP.FAL_LOT_PROP_ID = TAL.FAL_LOT_PROP_ID
                                         and FLP.FAL_LOT_PROP_ID = iFalLotPropId
                                         and FLP.C_FAB_TYPE = '4');
    else
      update FAL_TASK_LINK_PROP
         set PAC_SUPPLIER_PARTNER_ID = FAL_TOOLS.GetDefaultSubcontract
           , GCO_GOOD_ID = (select GCO_GOOD_ID
                              from GCO_GOOD
                             where GOO_MAJOR_REFERENCE = cFalDefaultService)
           , SCS_QTY_REF_AMOUNT = 1
           , SCS_PLAN_RATE = nvl(PCS.PC_CONFIG.GetConfig('GCO_CSub_SUB_DELAY'), 0)
           , SCS_PLAN_PROP = decode(nvl(PCS.PC_CONFIG.GetConfig('GCO_CSub_FIXED_DELAY'), 0), 0, 1, 0)
           , TAL_PLAN_RATE = iTotalQty * nvl(PCS.PC_CONFIG.GetConfig('GCO_CSub_SUB_DELAY'), 0)
       where FAL_TASK_LINK_PROP_ID in(select TAL.FAL_TASK_LINK_PROP_ID
                                        from FAL_TASK_LINK_PROP TAL
                                           , FAL_LOT_PROP FLP
                                       where FLP.FAL_LOT_PROP_ID = TAL.FAL_LOT_PROP_ID
                                         and FLP.FAL_LOT_PROP_ID = iFalLotPropId
                                         and FLP.C_FAB_TYPE = '4');
    end if;
  end UpdateSubcPurchaseOperation;
end;
