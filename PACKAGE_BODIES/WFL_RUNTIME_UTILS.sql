--------------------------------------------------------
--  DDL for Package Body WFL_RUNTIME_UTILS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WFL_RUNTIME_UTILS" 
is
  /*************** GetProcessInfos *******************************************/
  function GetProcessInfos(aProcessId in WFL_PROCESSES.WFL_PROCESSES_ID%type)
    return WFL_WORKFLOW_TYPES.TWFLPROCESS_INFO
  is
    /**
     * Curseur pour conditions de déclenchement
     */
    cursor crTrigConds(aProcessId in WFL_PROCESSES.WFL_PROCESSES_ID%type)
    is
      select PRO_TRIGGERING_CONDITION
           , 0 IsObjProcess
        from WFL_PROCESSES
       where WFL_PROCESSES_ID = aProcessId
       union all
      select WOP_TRIGGERING_CONDITION as PRO_TRIGGERING_CONDITION
           , 1 IsObjProcess
        from WFL_OBJECT_PROCESSES
       where WFL_PROCESSES_ID = aProcessId;

    tplTrigConds crTrigConds%rowtype;
    result       WFL_WORKFLOW_TYPES.TWFLPROCESS_INFO;
  begin
    --recherche des informations du processus
    select PRO.WFL_PROCESSES_ID
         , PRO.PRO_NAME
         , nvl(PRD.PRD_DESCRIPTION,PRO.PRO_DESCRIPTION) PRO_DESCRIPTION
         , PRO.PRO_VERSION
         , PRO.PRO_TABNAME
         , PRO.C_WFL_START_MODE
         , PRO.C_WFL_PROC_STATUS
         , PRO.PRO_SHOW_PROC
         , PRO.PRO_GRAPHIC_XML
         , PRO.PC_SQLST_ID
         , SQLST.SQLSTMNT
      into result.pProcId
         , result.pName
         , result.pDescr
         , result.pVersion
         , result.pTabName
         , result.pStartMode
         , result.pProcStatus
         , result.pShowProc
         , result.pProGraphic
         , result.pSqlstId
         , result.pSqlstmnt
      from WFL_PROCESSES PRO
         , WFL_PROCESSES_DESCR PRD
         , PCS.PC_SQLST SQLST
     where PRD.WFL_PROCESSES_ID(+) = PRO.WFL_PROCESSES_ID
       and PRD.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.GetUserId2
       and SQLST.PC_SQLST_ID(+) = PRO.PC_SQLST_ID
       and PRO.WFL_PROCESSES_ID = aProcessId;

    --récupération des conditions de déclenchement
    for tplTrigConds in crTrigConds(aProcessId => aProcessId) loop
      result.pTrigConditions.extend;
      result.pTrigConditions(result.pTrigConditions.count).pTrigCondition := tplTrigConds.PRO_TRIGGERING_CONDITION;
      result.pTrigConditions(result.pTrigConditions.count).pIsObjProcess  := tplTrigConds.IsObjProcess;
    end loop;

    return result;
    exception
      when no_data_found then
        return null;
  end GetProcessInfos;

  /*************** GetProcessInstanceInfos ***********************************/
  function GetProcessInstanceInfos(aProcessInstanceId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type)
    return WFL_WORKFLOW_TYPES.TWFLPROC_INST_INFO
  is
    result WFL_WORKFLOW_TYPES.TWFLPROC_INST_INFO;
  begin
    select PRI.WFL_PROCESS_INSTANCES_ID
         , PRI.WFL_PROCESSES_ID
         , PRI.WFL_ACTIVITY_INSTANCES_ID
         , PRI.PC_OBJECT_ID
         , OGE.OBJ_NAME
         , PRI.C_WFL_PROCESS_STATE
         , PRI.PRI_TABNAME
         , PRI.PRI_REC_ID
         , PRI.PRI_DATE_STARTED
         , PRI.PRI_DATE_ENDED
         , PRI.PC_WFL_PARTICIPANTS_ID
         , WPA.WPA_NAME
         , PRI.PRI_SHOW_PROC
      into result.pProcInstId
         , result.pProcId
         , result.pActInstId
         , result.pObjectId
         , result.pObjectName
         , result.pProcState
         , result.pTabName
         , result.pRecordId
         , result.pDateStarted
         , result.pDateEnded
         , result.pParticipantId
         , result.pPartName
         , result.pShowProc
      from WFL_PROCESS_INSTANCES PRI
         , PCS.PC_OBJECT OGE
         , PCS.PC_WFL_PARTICIPANTS WPA
     where OGE.PC_OBJECT_ID(+) = PRI.PC_OBJECT_ID
       and WPA.PC_WFL_PARTICIPANTS_ID(+) = PRI.PC_WFL_PARTICIPANTS_ID
       and PRI.WFL_PROCESS_INSTANCES_ID = aProcessInstanceId;

    return result;
    exception
      when no_data_found then
        return null;
  end GetProcessInstanceInfos;

  /*************** GetActivityInfos ******************************************/
  function GetActivityInfos(aActivityId in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type)
    return WFL_WORKFLOW_TYPES.TWFLACTIVITY_INFO
  is
    result WFL_WORKFLOW_TYPES.TWFLACTIVITY_INFO;
  begin
    select ACT.WFL_ACTIVITIES_ID
         , ACT.WFL_PROCESSES_ID
         , ACT.WFL_HAS_SUBFLOW_PROCESSES_ID
         , ACT.WFL_APPLICATIONS_ID
         , ACT.C_WFL_ACTIVITY_OBJECT_TYPE
         , ACT.PC_OBJECT_ID
         , OGE.OBJ_NAME
         , ACT.C_WFL_ACT_PART_TYPE
         , ACT.PC_WFL_PARTICIPANTS_ID
         , ACT.ACT_ASSIGN_ID
         , ACT.ACT_PART_QUERY
         , ACT.ACT_PART_EXCLUDE_QUERY
         , ACT.ACT_PART_FUNCTION
         , ACT.ACT_NAME
         , nvl(ACT.ACT_DESCRIPTION,ACD.ACD_DESCRIPTION) ACT_DESCRIPTION
         , ACT.C_WFL_ACTIVITY_TYPE
         , ACT.ACT_START_MODE
         , ACT.ACT_FINISH_MODE
         , ACT.C_WFL_SPLIT
         , ACT.C_WFL_JOIN
         , ACT.ACT_VALIDATION_REQUIRED
         , ACT.ACT_GUESTS_AUTHORIZED
         , ACT.ACT_EMAILTO_PARTICIPANTS
         , ACT.ACT_OBJECT_START_REQUIRED
         , ACT.C_WFL_ACT_IMPLEMENTATION
         , ACT.C_WFL_SUBFLOW_EXECUTION
      into result.pActivityId
         , result.pProcessId
         , result.pSubProcessId
         , result.pApplicationId
         , result.pActObjectType
         , result.pObjectId
         , result.pObjectName
         , result.pActPartType
         , result.pParticipantId
         , result.pActAssignId
         , result.pPartQuery
         , result.pPartExcludeQuery
         , result.pPartFunction
         , result.pName
         , result.pDescr
         , result.pActivityType
         , result.pStartMode
         , result.pFinishMode
         , result.pSplit
         , result.pJoin
         , result.pValidation
         , result.pGuestsAuthorized
         , result.pEmailParticipants
         , result.pObjStartRequired
         , result.pImplementation
         , result.pSubflowExecution
      from WFL_ACTIVITIES ACT
         , WFL_ACTIVITIES_DESCR ACD
         , PCS.PC_OBJECT OGE
     where OGE.PC_OBJECT_ID(+) = ACT.PC_OBJECT_ID
       and ACD.WFL_ACTIVITIES_ID (+) = ACT.WFL_ACTIVITIES_ID
       and ACD.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.GetUserId2
       and ACT.WFL_ACTIVITIES_ID = aActivityId;

    return result;
    exception
      when no_data_found then
        return null;
  end GetActivityInfos;

  /*************** GetActivityInstanceInfos **********************************/
  function GetActivityInstanceInfos(aActivityInstanceId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type)
    return WFL_WORKFLOW_TYPES.TWFLACT_INST_INFO
  is
    result WFL_WORKFLOW_TYPES.TWFLACT_INST_INFO;
  begin
    select AIN.WFL_ACTIVITY_INSTANCES_ID
         , AIN.WFL_PROCESSES_ID
         , AIN.WFL_PROCESS_INSTANCES_ID
         , AIN.WFL_ACTIVITIES_ID
         , AIN.PC_WFL_PARTICIPANTS_ID
         , AIN.PC_WFL_EXCLUDE_PARTICIPANTS_ID
         , AIN.WFL_DEADLINES_ID
         , decode(ACT.C_WFL_ACTIVITY_OBJECT_TYPE, 'TrigObject', PRI.PC_OBJECT_ID, 'SpecObject', ACT.PC_OBJECT_ID, null)
                                                                                                               PC_OBJECT_ID
         , (select OBJ_NAME
              from PCS.PC_OBJECT OGE
             where OGE.PC_OBJECT_ID =
                     decode(ACT.C_WFL_ACTIVITY_OBJECT_TYPE
                          , 'TrigObject', PRI.PC_OBJECT_ID
                          , 'SpecObject', ACT.PC_OBJECT_ID
                          , null
                           ) ) OBJ_NAME
         , AIN.C_WFL_ACTIVITY_STATE
         , AIN.AIN_VALIDATION_REQUIRED
         , AIN.AIN_GUESTS_AUTHORIZED
         , AIN.AIN_EMAILTO_PARTICIPANTS
         , AIN.AIN_VALIDATED_BY
         , AIN.AIN_VALIDATION_DATE
         , AIN.AIN_OBJECT_START_REQUIRED
         , AIN.AIN_OBJECT_START_DATE
         , AIN.AIN_OBJECT_STARTED_BY
         , WFL_WORKFLOW_UTILS.GetActivityPerformer(AIN.WFL_ACTIVITY_INSTANCES_ID) PART_PERFORMER_ID
         , AIN.AIN_DATE_STARTED
         , AIN.AIN_DATE_ENDED
         , AIN.AIN_DATE_DUE
      into result.pActInstId
         , result.pProcessId
         , result.pProcInstId
         , result.pActivityId
         , result.pParticipantId
         , result.pPartExcludeId
         , result.pDeadLineId
         , result.pObjectId
         , result.pObjectName
         , result.pActState
         , result.pValidationReq
         , result.pGuestsAuthorized
         , result.pEmailParticipants
         , result.pValidateBy
         , result.pValidateDate
         , result.pObjStartRequired
         , result.pObjStartDate
         , result.pObjStartedBy
         , result.pPartPerfId
         , result.pDateStarted
         , result.pDateEnded
         , result.pDateDue
      from WFL_ACTIVITY_INSTANCES AIN
         , WFL_PROCESS_INSTANCES PRI
         , WFL_ACTIVITIES ACT
     where PRI.WFL_PROCESS_INSTANCES_ID = AIN.WFL_PROCESS_INSTANCES_ID
       and ACT.WFL_ACTIVITIES_ID = AIN.WFL_ACTIVITIES_ID
       and AIN.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;

    return result;
    exception
      when no_data_found then
        return null;
  end GetActivityInstanceInfos;

  /*************** SetProcessAttributeValue *********************************/
  procedure SetProcessAttributeValue(
    aAttributeId       in WFL_ATTRIBUTE_INSTANCES.WFL_ATTRIBUTES_ID%type
  , aProcessInstanceId in WFL_ATTRIBUTE_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  , aAttributeValue    in WFL_ATTRIBUTE_INSTANCES.ATI_VALUE%type
  )
  is
  begin
    update WFL_ATTRIBUTE_INSTANCES
       set ATI_VALUE = aAttributeValue
     where WFL_ATTRIBUTES_ID = aAttributeId
       and WFL_PROCESS_INSTANCES_ID = aProcessInstanceId;
  end SetProcessAttributeValue;

  /*************** GetProcessAttributeValue **********************************/
  function GetProcessAttributeValue(
    aAttributeId       in WFL_ATTRIBUTE_INSTANCES.WFL_ATTRIBUTES_ID%type
  , aProcessInstanceId in WFL_ATTRIBUTE_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  )
    return WFL_ATTRIBUTE_INSTANCES.ATI_VALUE%type
  is
    result WFL_ATTRIBUTE_INSTANCES.ATI_VALUE%type default '';
  begin
    select ATI_VALUE
      into result
      from WFL_ATTRIBUTE_INSTANCES
     where WFL_ATTRIBUTES_ID = aAttributeId
       and WFL_PROCESS_INSTANCES_ID = aProcessInstanceId;

    return result;
    exception
      when no_data_found then
        return null;
  end GetProcessAttributeValue;

  /*************** SetActivityAttributeValue *********************************/
  procedure SetActivityAttributeValue(
    aAttributeId        in WFL_ACT_ATTRIBUTE_INSTANCES.WFL_ACTIVITY_ATTRIBUTES_ID%type
  , aActivityInstanceId in WFL_ACT_ATTRIBUTE_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aAttributeValue     in WFL_ACT_ATTRIBUTE_INSTANCES.AAI_VALUE%type
  )
  is
  begin
    update WFL_ACT_ATTRIBUTE_INSTANCES
       set AAI_VALUE = aAttributeValue
     where WFL_ACTIVITY_ATTRIBUTES_ID = aAttributeId
       and WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;
  end SetActivityAttributeValue;

  /*************** GetActivityAttributeValue *********************************/
  function GetActivityAttributeValue(
    aAttributeId        in WFL_ACT_ATTRIBUTE_INSTANCES.WFL_ACTIVITY_ATTRIBUTES_ID%type
  , aActivityInstanceId in WFL_ACT_ATTRIBUTE_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  )
    return WFL_ACT_ATTRIBUTE_INSTANCES.AAI_VALUE%type
  is
    result WFL_ACT_ATTRIBUTE_INSTANCES.AAI_VALUE%type default '';
  begin
    select AAI_VALUE
      into result
      from WFL_ACT_ATTRIBUTE_INSTANCES
     where WFL_ACTIVITY_ATTRIBUTES_ID = aAttributeId
       and WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;

    return result;
    exception
      when no_data_found then
        return null;
  end GetActivityAttributeValue;

end WFL_RUNTIME_UTILS;
