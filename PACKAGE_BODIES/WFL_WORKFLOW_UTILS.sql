--------------------------------------------------------
--  DDL for Package Body WFL_WORKFLOW_UTILS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WFL_WORKFLOW_UTILS" 
is
  --participant système
  PlFlowParticipant         PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type   := 1;
  --descodes event timing
  EvtTmgBeforeStop constant varchar2(10)                                          := 'BEFORESTOP';
  EvtTmgAfterStart constant varchar2(10)                                          := 'AFTERSTART';
  --descodes event type
  EvtTypeMail      constant varchar2(9)                                           := 'SEND_MAIL';
  EvtTypePlSql     constant varchar2(10)                                          := 'PLSQL_PROC';

  /*************** GetProcessCreated *****************************************/
  function GetProcessCreated
    return number
  is
  begin
    return ProcessCreated;
  end;

  /*************** GetFieldsToInsert *****************************************/
  function GetFieldsToInsert(
    aTableName    in USER_TAB_COLUMNS.TABLE_NAME%type
  , aExceptFields in WFL_WORKFLOW_TYPES.TColFields
  )
    return clob
  is
    nCnt    number;
    oFields WFL_WORKFLOW_TYPES.TColFields;
    result  clob;
  begin
    result   := '';
    oFields  := WFL_WORKFLOW_UTILS.GetTableColumns(aTableName => aTableName, aExceptFields => aExceptFields);

    for nCnt in 1 .. oFields.count - 1 loop
      result  := result || oFields(nCnt) || ',' || chr(13);
    end loop;

    result   := result || oFields(oFields.count);
    return result;
  end GetFieldsToInsert;

  /*************** GetTableColumns *******************************************/
  function GetTableColumns(
    aTableName    in USER_TAB_COLUMNS.TABLE_NAME%type
  , aExceptFields in WFL_WORKFLOW_TYPES.TColFields
  )
    return WFL_WORKFLOW_TYPES.TColFields
  is
    --curseur qui retourne les colonnes d'une table
    cursor crGetTabCols(aTableName in USER_TAB_COLUMNS.TABLE_NAME%type)
    is
      select   COLUMN_NAME
          from USER_TAB_COLUMNS
         where TABLE_NAME = aTableName
      order by COLUMN_ID asc;

    tplTabCols   crGetTabCols%rowtype;   --contient l'information du curseur
    cColumnName  USER_TAB_COLUMNS.TABLE_NAME%type;
    nCnt         number;
    bExceptField boolean;
    result       WFL_WORKFLOW_TYPES.TColFields      default WFL_WORKFLOW_TYPES.TColFields();
  begin
    for tplTabCols in crGetTabCols(aTableName => aTableName) loop
      bExceptField  := false;

      for nCnt in 1 .. aExceptFields.count loop
        cColumnName  := aExceptFields(nCnt);

        if cColumnName = tplTabCols.COLUMN_NAME then
          bExceptField  := true;
        end if;
      end loop;

      if not bExceptField then
        result.extend;
        result(result.count)  := tplTabCols.COLUMN_NAME;
      end if;
    end loop;

    return result;
  end GetTableColumns;

  /*************** ExecuteQuerySql *******************************************/
  procedure ExecuteQuerySql(aStatement in clob, aListVars in WFL_WORKFLOW_TYPES.TCurrencyVars)
  is
    nCnt           number;
    nVarValue      number;
    cVarName       varchar2(255);
    cId            integer;
    rows_processes integer;
  begin
    cId             := DBMS_SQL.open_cursor;
    DBMS_SQL.parse(cId, aStatement, DBMS_SQL.v7);

    --on lie les variables
    for nCnt in 1 .. aListVars.count loop
      cVarName   := aListVars(nCnt).pVarName;
      nVarValue  := aListVars(nCnt).pVarValue;
      DBMS_SQL.bind_variable(c => cId, name => cVarName, value => nVarValue);
    end loop;

    rows_processes  := DBMS_SQL.execute(cId);
    DBMS_SQL.close_cursor(cId);
  end ExecuteQuerySql;

  /*************** ActivateLogging *******************************************/
  procedure ActivateLogging(
    aProcessInstanceId  in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type default null
  , aActivityInstanceId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type default null
  )
  is
    bActiveDebug WFL_PROCESS_INSTANCES.PRI_ACTIVE_DEBUG%type   default 0;
  begin
    if aProcessInstanceId is not null then
      select PRI_ACTIVE_DEBUG
        into bActiveDebug
        from WFL_PROCESS_INSTANCES
       where WFL_PROCESS_INSTANCES_ID = aProcessInstanceId;
    elsif aActivityInstanceId is not null then
      select PRI.PRI_ACTIVE_DEBUG
        into bActiveDebug
        from WFL_PROCESS_INSTANCES PRI
           , WFL_ACTIVITY_INSTANCES AIN
       where AIN.WFL_PROCESS_INSTANCES_ID = PRI.WFL_PROCESS_INSTANCES_ID
         and AIN.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;
    end if;

    if bActiveDebug = 1 then
      WFL_WORKFLOW_MANAGEMENT.SetLogging(aLogging => true);
    else
      WFL_WORKFLOW_MANAGEMENT.SetLogging(aLogging => false);
    end if;
  end ActivateLogging;

  /*************** GetProcessInstanceId **************************************/
  function GetProcessInstanceId(
    aObjectId      in     WFL_PROCESS_INSTANCES.PC_OBJECT_ID%type
  , aMainTable     in     WFL_PROCESS_INSTANCES.PRI_TABNAME%type
  , aRecordId      in     WFL_PROCESS_INSTANCES.PRI_REC_ID%type
  , aParticipantId in out PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type
  )
    return WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  is
    result WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type;
  begin
    aParticipantId  := null;

    --**une seule instance de process par objet et record
    select WFL_PROCESS_INSTANCES_ID
         , PC_WFL_PARTICIPANTS_ID
      into result
         , aParticipantId
      from WFL_PROCESS_INSTANCES
     where PC_OBJECT_ID = aObjectId
       and PRI_TABNAME = aMainTable
       and PRI_REC_ID = aRecordId;

    return result;
  exception
    when no_data_found then
      return null;
  end GetProcessInstanceId;

  /*************** IsUserProcessOwner ****************************************/
  function IsUserProcessOwner(
    aObjectId  in WFL_PROCESS_INSTANCES.PC_OBJECT_ID%type
  , aMainTable in WFL_PROCESS_INSTANCES.PRI_TABNAME%type
  , aRecordId  in WFL_PROCESS_INSTANCES.PRI_REC_ID%type
  , aUserId    in PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    nProcInstId    WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type;
    nParticipantId WFL_PROCESS_INSTANCES.PC_WFL_PARTICIPANTS_ID%type;
    cProcState     WFL_PROCESS_INSTANCES.C_WFL_PROCESS_STATE%type;
    result         WFL_WORKFLOW_TYPES.WFL_BOOLEAN                        default 0;
  begin
    nProcInstId  :=
      WFL_WORKFLOW_UTILS.GetProcessInstanceId(aObjectId        => aObjectId
                                            , aMainTable       => aMainTable
                                            , aRecordId        => aRecordId
                                            , aParticipantId   => nParticipantId
                                             );

    if nProcInstId is not null then
      select decode(count(PAR.PC_WFL_PARTICIPANTS_ID), 0, 0, 1)
        into result
        from PCS.PC_WFL_PARTICIPANTS PAR
           , WFL_PROCESS_INSTANCES PRI
       where PAR.PC_WFL_PARTICIPANTS_ID = PRI.PC_WFL_PARTICIPANTS_ID
         and PRI.WFL_PROCESS_INSTANCES_ID = nProcInstId
         and PRI.C_WFL_PROCESS_STATE = 'NOTSTARTED'
         and PAR.PC_USER_ID = aUserId;
    end if;

    return result;
  exception
    when no_data_found then
      return 0;
  end IsUserProcessOwner;

  function IsUserProcessOwner(
    aProcInstId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  , aUserId     in PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    result WFL_WORKFLOW_TYPES.WFL_BOOLEAN;
  begin
    select decode(count(PAR.PC_WFL_PARTICIPANTS_ID), 0, 0, 1)
      into result
      from PCS.PC_WFL_PARTICIPANTS PAR
         , WFL_PROCESS_INSTANCES PRI
     where PAR.PC_WFL_PARTICIPANTS_ID = PRI.PC_WFL_PARTICIPANTS_ID
       and PRI.WFL_PROCESS_INSTANCES_ID = aProcInstId
       and PRI.C_WFL_PROCESS_STATE = 'NOTSTARTED'
       and PAR.PC_USER_ID = aUserId;

    return result;
  exception
    when no_data_found then
      return 0;
  end IsUserProcessOwner;

  /*************** IsUserProcessAutoOwner ************************************/
  function IsUserProcessAutoOwner(
    aObjectId  in WFL_PROCESS_INSTANCES.PC_OBJECT_ID%type
  , aMainTable in WFL_PROCESS_INSTANCES.PRI_TABNAME%type
  , aRecordId  in WFL_PROCESS_INSTANCES.PRI_REC_ID%type
  , aUserId    in PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    nProcInstId    WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type;
    nParticipantId WFL_PROCESS_INSTANCES.PC_WFL_PARTICIPANTS_ID%type;
    cProcState     WFL_PROCESS_INSTANCES.C_WFL_PROCESS_STATE%type;
    result         WFL_WORKFLOW_TYPES.WFL_BOOLEAN                        default 0;
  begin
    nProcInstId  :=
      WFL_WORKFLOW_UTILS.GetProcessInstanceId(aObjectId        => aObjectId
                                            , aMainTable       => aMainTable
                                            , aRecordId        => aRecordId
                                            , aParticipantId   => nParticipantId
                                             );

    if nProcInstId is not null then
      select decode(count(PAR.PC_WFL_PARTICIPANTS_ID), 0, 0, 1)
        into result
        from PCS.PC_WFL_PARTICIPANTS PAR
           , WFL_PROCESS_INSTANCES PRI
           , WFL_PROCESSES PRO
       where PAR.PC_WFL_PARTICIPANTS_ID = PRI.PC_WFL_PARTICIPANTS_ID
         and PRI.WFL_PROCESS_INSTANCES_ID = nProcInstId
         and PRI.C_WFL_PROCESS_STATE = 'RUNNING'
         and PAR.PC_USER_ID = aUserId
         and PRO.WFL_PROCESSES_ID = PRI.WFL_PROCESSES_ID
         and PRO.C_WFL_START_MODE = 'AUTOMATIC'
         and   --Process avec mode de démarrage en automatique
             (nvl( (PRI_DATE_STARTED - PRI_DATE_CREATED) * 24 * 60, 0) < 1
             )
         and   --moins de 1 min entre création et démarrage
             WFL_WORKFLOW_UTILS.ProcessCreated = 1;
    end if;

    return result;
  exception
    when no_data_found then
      return 0;
  end;

  function IsUserProcessAutoOwner(
    aProcInstId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  , aUserId     in PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    result WFL_WORKFLOW_TYPES.WFL_BOOLEAN;
  begin
    select decode(count(PAR.PC_WFL_PARTICIPANTS_ID), 0, 0, 1)
      into result
      from PCS.PC_WFL_PARTICIPANTS PAR
         , WFL_PROCESS_INSTANCES PRI
         , WFL_PROCESSES PRO
     where PAR.PC_WFL_PARTICIPANTS_ID = PRI.PC_WFL_PARTICIPANTS_ID
       and PRI.WFL_PROCESS_INSTANCES_ID = aProcInstId
       and PRI.C_WFL_PROCESS_STATE = 'RUNNING'
       and PAR.PC_USER_ID = aUserId
       and PRO.WFL_PROCESSES_ID = PRI.WFL_PROCESSES_ID
       and PRO.C_WFL_START_MODE = 'AUTOMATIC'
       and   --Process avec mode de démarrage en automatique
           (nvl( (PRI_DATE_STARTED - PRI_DATE_CREATED) * 24 * 60, 0) < 1)
       and   --moins de 1 min entre création et démarrage
           WFL_WORKFLOW_UTILS.ProcessCreated = 1;

    return result;
  exception
    when no_data_found then
      return 0;
  end;

  /*************** IsUserActivityOwner ***************************************/
  function IsUserActivityOwner(
    aProcInstId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  , aUserId     in PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    result         WFL_WORKFLOW_TYPES.WFL_BOOLEAN               default 0;
    nParticipantId WFL_PERFORMERS.PC_WFL_PARTICIPANTS_ID%type;
  begin
    result  := 0;

    --récupération du participant attribué à l'activité
    select decode(count(PAR.PC_WFL_PARTICIPANTS_ID), 0, 0, 1)
      into result
      from WFL_PERFORMERS PER
         , WFL_PROCESS_INSTANCES PRI
         , PCS.PC_WFL_PARTICIPANTS PAR
     where PER.WFL_ACTIVITY_INSTANCES_ID = PRI.WFL_ACTIVITY_INSTANCES_ID
       and PER.C_WFL_PER_STATE = 'CURRENT'
       and PAR.PC_WFL_PARTICIPANTS_ID = PER.PC_WFL_PARTICIPANTS_ID
       and PAR.PC_USER_ID = aUserId;

    return result;
  end IsUserActivityOwner;

  /*************** IsParticipantInDefinitionProcess **************************/
  function IsParticipantInDefProcess(
    aParticipantId in WFL_PROCESS_INSTANCES.PC_WFL_PARTICIPANTS_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    result WFL_WORKFLOW_TYPES.WFL_BOOLEAN               default 0;
  begin
    --on teste si le participant est autorisé pour le processus
    select decode(count(*),0,0,1)
      into result
      from WFL_PROCESS_PART_ALLOW
     where PC_WFL_PARTICIPANTS_ID = aParticipantId;

    if result = 0 then
      --on teste si le participant est interdit pour une activité
      select decode(count(*),0,0,1)
        into result
        from WFL_ACTIVITY_PART_PROHIBITED
       where PC_WFL_PARTICIPANTS_ID = aParticipantId;

      if result = 0 then
        --on teste si le participant est désigné comme responsable d'une activité
        select decode(count(*),0,0,1)
          into result
          from WFL_ACTIVITIES
         where PC_WFL_PARTICIPANTS_ID = aParticipantId;

        if result = 0 then
          --on teste si le participant est défini dans une référence externe
          select decode(count(*),0,0,1)
            into result
            from WFL_EXTERNAL_REFERENCES
           where PC_WFL_PARTICIPANTS_ID = aParticipantId;
        end if;
      end if;
    end if;

    return result;
  end IsParticipantInDefProcess;

  /*************** IsParticipantInActiveProcess ******************************/
  function IsParticipantInActiveProcess(
    aParticipantId in WFL_PROCESS_INSTANCES.PC_WFL_PARTICIPANTS_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    result WFL_WORKFLOW_TYPES.WFL_BOOLEAN               default 0;
  begin
    --on teste si le participant est propriétaire d'une instance de processus
    select decode(count(*),0,0,1)
      into result
      from WFL_PROCESS_INSTANCES
     where PC_WFL_PARTICIPANTS_ID = aParticipantId;

    if result = 0 then
      --on teste si le participant est lié à une instance d'activité
      select decode(count(*),0,0,1)
        into result
        from WFL_ACTIVITY_INSTANCES
       where PC_WFL_PARTICIPANTS_ID = aParticipantId
          or PC_WFL_EXCLUDE_PARTICIPANTS_ID = aParticipantId;

      if result = 0 then
        --on teste si le participant a pris en charge une instance d'activité
        select decode(count(*),0,0,1)
          into result
          from WFL_PERFORMERS
         where PC_WFL_PARTICIPANTS_ID = aParticipantId;
      end if;
    end if;

    return result;
  end IsParticipantInActiveProcess;

  /*************** IsParticipantInLogProcess *********************************/
  function IsParticipantInLogProcess(
    aParticipantId in WFL_PROCESS_INSTANCES.PC_WFL_PARTICIPANTS_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    result WFL_WORKFLOW_TYPES.WFL_BOOLEAN               default 0;
  begin
    --on teste si le participant est propriétaire d'une instance de processus archivée
    select decode(count(*),0,0,1)
      into result
      from WFL_PROCESS_INST_LOG
     where PC_WFL_PARTICIPANTS_ID = aParticipantId;

    if result = 0 then
      --on teste si le participant est lié à une instance d'activité archivée
      select decode(count(*),0,0,1)
        into result
        from WFL_ACTIVITY_INST_LOG
       where PC_WFL_PARTICIPANTS_ID = aParticipantId;

      if result = 0 then
        --on teste si le participant a pris en charge une instance d'activité archivée
        select decode(count(*),0,0,1)
          into result
          from WFL_PERFORMERS_LOG
         where PC_WFL_PARTICIPANTS_ID = aParticipantId;
      end if;
    end if;

    return result;
  end IsParticipantInLogProcess;

  /*************** IsObjectInWorkflow ****************************************/
  function IsObjectInWorkflow(aObjectId in WFL_OBJECT_PROCESSES.PC_OBJECT_ID%type)
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    result WFL_WORKFLOW_TYPES.WFL_BOOLEAN default 0;
  begin
    --teste si un processus actif contient l'objet ou l'une de ses activités
    select decode( (select count(*)
                      from wfl_processes pro
                         , wfl_object_processes wop
                     where pro.c_wfl_proc_status in('IN_TEST', 'ACTIVATED', 'SUSPENDED')
                       and wop.wfl_processes_id = pro.wfl_processes_id
                       and wop.pc_object_id = aObjectId) +
                  (select count(*)
                     from wfl_activities act
                        , wfl_processes pro
                    where act.wfl_processes_id = pro.wfl_processes_id
                      and act.c_wfl_activity_object_type = 'SpecObject'
                      and act.pc_object_id = aObjectId
                      and pro.c_wfl_proc_status in('IN_TEST', 'ACTIVATED', 'SUSPENDED') )
                , 0, 0
                , 1
                 ) IsActive
      into result
      from dual;

    return result;
  exception
    when no_data_found then
      return 0;
  end IsObjectInWorkflow;

  /*************** ExistsUserActivities **************************************/
  function ExistsUserActivities(
    aObjectId  in WFL_OBJECT_PROCESSES.PC_OBJECT_ID%type
  , aMainTable in WFL_PROCESSES.PRO_TABNAME%type
  , aRecordId  in WFL_PROCESS_INSTANCES.PRI_REC_ID%type
  , aUserId    in PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    result             WFL_WORKFLOW_TYPES.WFL_BOOLEAN                        default 0;
    nProcOwner         WFL_PROCESS_INSTANCES.PC_WFL_PARTICIPANTS_ID%type;
    nParticipantId     PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type;
    nProcessInstanceId WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type;
  begin
    --récupération du participant et de l'instance du process
    nParticipantId  := PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantId(aUserId => aUserId);

    if nParticipantId is not null then
      --teste si il existe des activités déclenchant l'objet et qui sont associés à l'utilisateur
      select decode( (select count(*)
                        from WFL_ACTIVITY_INSTANCES AIN
                           , WFL_PROCESS_INSTANCES PRI
                           , WFL_ACTIVITIES ACT
                       where PRI.WFL_PROCESS_INSTANCES_ID = AIN.WFL_PROCESS_INSTANCES_ID
                         and PRI.PRI_TABNAME = aMainTable
                         and PRI.PRI_REC_ID = aRecordId
                         and AIN.WFL_ACTIVITIES_ID = ACT.WFL_ACTIVITIES_ID
                         and (    (     (ACT.PC_OBJECT_ID = aObjectId)
                                   and (ACT.C_WFL_ACTIVITY_OBJECT_TYPE = 'SpecObject') )
                              or (     (ACT.C_WFL_ACTIVITY_OBJECT_TYPE = 'TrigObject')
                                  and (PRI.PC_OBJECT_ID = aObjectId) )
                             )
                         and AIN.C_WFL_ACTIVITY_STATE in('RUNNING', 'SUSPENDED')
                         and WFL_WORKFLOW_UTILS.GetActivityPerformer(AIN.WFL_ACTIVITY_INSTANCES_ID) = nParticipantId) +
                    (select count(*)
                       from WFL_ACTIVITY_INSTANCES AIN
                          , WFL_PROCESS_INSTANCES PRI
                          , WFL_ACTIVITIES ACT
                      where PRI.WFL_PROCESS_INSTANCES_ID = AIN.WFL_PROCESS_INSTANCES_ID
                        and PRI.PRI_TABNAME = aMainTable
                        and PRI.PRI_REC_ID = aRecordId
                        and AIN.WFL_ACTIVITIES_ID = ACT.WFL_ACTIVITIES_ID
                        and (    (     (ACT.PC_OBJECT_ID = aObjectId)
                                  and (ACT.C_WFL_ACTIVITY_OBJECT_TYPE = 'SpecObject') )
                             or (     (ACT.C_WFL_ACTIVITY_OBJECT_TYPE = 'TrigObject')
                                 and (PRI.PC_OBJECT_ID = aObjectId) )
                            )
                        and AIN.C_WFL_ACTIVITY_STATE = 'NOTRUNNING'
                        and WFL_WORKFLOW_UTILS.CanPerformActivity(nParticipantId, AIN.WFL_ACTIVITY_INSTANCES_ID) = 1)
                  , 0, 0
                  , 1
                   )
        into result
        from dual;
    end if;

    return result;
  exception
    when no_data_found then
      return 0;
  end ExistsUserActivities;

  /*************** IsRecordEditable ******************************************/
  function IsRecordEditable(
    aObjectId  in WFL_OBJECT_PROCESSES.PC_OBJECT_ID%type
  , aMainTable in WFL_PROCESSES.PRO_TABNAME%type
  , aRecordId  in WFL_PROCESS_INSTANCES.PRI_REC_ID%type
  , aUserId    in PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    cursor crActivitiesRun(
      aMainTable in WFL_PROCESSES.PRO_TABNAME%type
    , aRecordId  in WFL_PROCESS_INSTANCES.PRI_REC_ID%type
    )
    is
      select AIN.WFL_ACTIVITY_INSTANCES_ID as WFL_ACTIVITY_INSTANCES_ID
           , ACT.C_WFL_ACTIVITY_OBJECT_TYPE as C_WFL_ACTIVITY_OBJECT_TYPE
           , ACT.PC_OBJECT_ID as ACT_OBJECT_ID
           , PRI.PC_OBJECT_ID as PRI_OBJECT_ID
        from WFL_ACTIVITY_INSTANCES AIN
           , WFL_PROCESS_INSTANCES PRI
           , WFL_ACTIVITIES ACT
       where PRI.WFL_PROCESS_INSTANCES_ID = AIN.WFL_PROCESS_INSTANCES_ID
         and PRI.PRI_TABNAME = aMainTable
         and PRI.PRI_REC_ID = aRecordId
         and AIN.WFL_ACTIVITIES_ID = ACT.WFL_ACTIVITIES_ID
         and AIN.C_WFL_ACTIVITY_STATE in('RUNNING', 'SUSPENDED');

    tplActivitiesRun   crActivitiesRun%rowtype;
    result             WFL_WORKFLOW_TYPES.WFL_BOOLEAN                        default 0;
    nProcOwner         WFL_PROCESS_INSTANCES.PC_WFL_PARTICIPANTS_ID%type;
    nParticipantId     PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type;
    nProcessInstanceId WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type;
    bExistsActivities  boolean                                               default false;
  begin
    --on teste si l'objet est dans un workflow
    if WFL_WORKFLOW_UTILS.IsObjectInWorkflow(aObjectId => aObjectId) = 1 then
      --récupération du participant et de l'instance du process
      nParticipantId  := PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantId(aUserId => aUserId);

      if nParticipantId is not null then
        --élément modifiable si utilisateur propriétaire du processus NOTSTARTED
        result  :=
          WFL_WORKFLOW_UTILS.IsUserProcessOwner(aObjectId    => aObjectId
                                              , aMainTable   => aMainTable
                                              , aRecordId    => aRecordId
                                              , aUserId      => aUserId
                                               );

        if result = 0 then
          --parcours des activités en mode Running, Suspended et test si l'utilisateur les à en charge
          for tplActivitiesRun in crActivitiesRun(aMainTable => aMainTable, aRecordId => aRecordId) loop
            --indique qu'il y a des activités associés à l'élément
            bExistsActivities  := true;

            --on teste si l'utilisateur associé à l'activité est le participant testé
            if    (     (tplActivitiesRun.C_WFL_ACTIVITY_OBJECT_TYPE = 'SpecObject')
                   and (tplActivitiesRun.ACT_OBJECT_ID = aObjectId)
                  )
               or     (     (tplActivitiesRun.C_WFL_ACTIVITY_OBJECT_TYPE = 'TrigObject')
                       and (tplActivitiesRun.PRI_OBJECT_ID = aObjectId)
                      )
                  and (WFL_WORKFLOW_UTILS.GetActivityPerformer(tplActivitiesRun.WFL_ACTIVITY_INSTANCES_ID) =
                                                                                                          nParticipantId
                      ) then
              result  := 1;
            end if;

            if result = 1 then
              exit;
            end if;
          end loop;

          if not bExistsActivities then
            --on teste si il y a des activités en préparation
            select decode(count(*), 0, 1, 0)
              into result
              from WFL_ACTIVITY_INSTANCES AIN
                 , WFL_PROCESS_INSTANCES PRI
             where PRI.WFL_PROCESS_INSTANCES_ID = AIN.WFL_PROCESS_INSTANCES_ID
               and PRI.PRI_TABNAME = aMainTable
               and PRI.PRI_REC_ID = aRecordId
               and AIN.C_WFL_ACTIVITY_STATE = 'NOTRUNNING';
          end if;
        end if;
      else
        --on cherche si l'élément fais partie d'un processus, sinon result = 1
        select decode(count(*), 0, 1, 0)
          into result
          from WFL_PROCESS_INSTANCES
         where PRI_TABNAME = aMainTable
           and PRI_REC_ID = aRecordId;
      end if;
    else
      --on cherche si l'élément fais partie d'un processus, sinon result = 1
      select decode(count(*), 0, 1, 0)
        into result
        from WFL_PROCESS_INSTANCES
       where PRI_TABNAME = aMainTable
         and PRI_REC_ID = aRecordId;
    end if;

    return result;
  exception
    when no_data_found then
      return 0;
  end IsRecordEditable;

  /*************** ExistsTriggeredProcess ************************************/
  function ExistsTriggeredProcess(
    aEvent     in     WFL_OBJECT_PROCESSES.C_WFL_TRIGGERING_EVENT_NAME%type
  , aObjectId  in     WFL_OBJECT_PROCESSES.PC_OBJECT_ID%type
  , aRecordId  in     WFL_PROCESS_INSTANCES.PRI_REC_ID%type
  , aProcessId out    WFL_OBJECT_PROCESSES.WFL_PROCESSES_ID%type
  , aStartMode out    WFL_PROCESSES.C_WFL_START_MODE%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    --curseur pour récupérer les process d'après l'évènement et l'objet
    cursor crTriggeredProc(
      aEvent    in WFL_OBJECT_PROCESSES.C_WFL_TRIGGERING_EVENT_NAME%type
    , aObjectId in WFL_OBJECT_PROCESSES.PC_OBJECT_ID%type
    )
    is
      select WOP.WFL_PROCESSES_ID
           , nvl(WOP.WOP_TRIGGERING_CONDITION, PRO.PRO_TRIGGERING_CONDITION) TRIGGERING_CONDITION
           , PRO.C_WFL_START_MODE
        from WFL_OBJECT_PROCESSES WOP
           , WFL_PROCESSES PRO
       where WOP.PC_OBJECT_ID = aObjectId
         and WOP.C_WFL_TRIGGERING_EVENT_NAME = aEvent
         and PRO.WFL_PROCESSES_ID = WOP.WFL_PROCESSES_ID
         and PRO.C_WFL_PROC_STATUS in('IN_TEST', 'ACTIVATED');

    tplTriggeredProc crTriggeredProc%rowtype;
    nCntRows         pls_integer;
    bCondOk          boolean;
    result           WFL_WORKFLOW_TYPES.WFL_BOOLEAN default 1;
  begin
    --valeurs de sortie
    aProcessId  := 0;
    aStartMode  := '';

    --parcours des processus associés à l'objet et à l'évènement
    for tplTriggeredProc in crTriggeredProc(aEvent => aEvent, aObjectId => aObjectId) loop
      --on teste si la condition de déclenchement est valide
      begin
        if length(trim(tplTriggeredProc.TRIGGERING_CONDITION) ) > 0 then
          execute immediate 'select count(*) from (' || tplTriggeredProc.TRIGGERING_CONDITION || ')'
                       into nCntRows
                      using aRecordId;

          bCondOk  :=(nCntRows > 0);
        else
          bCondOk  := true;
        end if;
      exception
        when others then
          bCondOk  := false;
      end;

      if bCondOk then
        --on vérifie si il n'y a pas d'autre process remplissant la condition
        if aProcessId = 0 then
          --récupération processus et status
          aProcessId  := tplTriggeredProc.WFL_PROCESSES_ID;
          aStartMode  := tplTriggeredProc.C_WFL_START_MODE;
        else
          result      := 0;
          aProcessId  := 0;
          aStartMode  := '';
          exit;
        end if;
      end if;
    end loop;

    return result;
  end ExistsTriggeredProcess;

/*************** InitProcess ***********************************************/
  procedure InitProcess(
    aObjectId  in WFL_OBJECT_PROCESSES.PC_OBJECT_ID%type
  , aMainTable in WFL_PROCESSES.PRO_TABNAME%type
  , aRecordId  in WFL_PROCESS_INSTANCES.PRI_REC_ID%type
  , aEvent     in WFL_OBJECT_PROCESSES.C_WFL_TRIGGERING_EVENT_NAME%type
  , aUserId    in PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  )
  is
    bDuplProc WFL_WORKFLOW_TYPES.WFL_BOOLEAN;
  begin
    WFL_WORKFLOW_UTILS.InitProcess(aObjectId    => aObjectId
                                 , aMainTable   => aMainTable
                                 , aRecordId    => aRecordId
                                 , aEvent       => aEvent
                                 , aUserId      => aUserId
                                 , aDuplProc    => bDuplProc
                                  );
  end;

  procedure InitProcess(
    aObjectId  in     WFL_OBJECT_PROCESSES.PC_OBJECT_ID%type
  , aMainTable in     WFL_PROCESSES.PRO_TABNAME%type
  , aRecordId  in     WFL_PROCESS_INSTANCES.PRI_REC_ID%type
  , aEvent     in     WFL_OBJECT_PROCESSES.C_WFL_TRIGGERING_EVENT_NAME%type
  , aUserId    in     PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  , aDuplProc  out    WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  )
  is
    bFoundProcess   WFL_WORKFLOW_TYPES.WFL_BOOLEAN;
    nProcessId      WFL_PROCESS_INSTANCES.WFL_PROCESSES_ID%type;
    cStartMode      WFL_PROCESSES.C_WFL_START_MODE%type;
    nProcInstId     WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type;
    nParticipantId  WFL_PROCESS_INSTANCES.PC_WFL_PARTICIPANTS_ID%type;
    bExistsProcInst WFL_WORKFLOW_TYPES.WFL_BOOLEAN;
  begin
    --mise à jour variable de package
    ProcessCreated  := 0;
    aDuplProc       := 0;
    --récupération du participant
    nParticipantId  := PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantId(aUserId => aUserId);

    if nParticipantId is not null then
      bFoundProcess  :=
        WFL_WORKFLOW_UTILS.ExistsTriggeredProcess(
                               aEvent       => aEvent
                             , aObjectId    => aObjectId
                             , aRecordId    => aRecordId
                             , aProcessId   => nProcessId
                             , aStartMode   => cStartMode
                              );

      if     (bFoundProcess = 1)
         and (nProcessId > 0) then
        --création de l'instance du process si et seulement si aucune instance de process n'existe pour le record et objet
        select decode(count(WFL_PROCESS_INSTANCES_ID), 0, 0, 1)
          into bExistsProcInst
          from WFL_PROCESS_INSTANCES
         where PRI_REC_ID = aRecordId
           and PC_OBJECT_ID = aObjectId;

        if bExistsProcInst = 0 then
          --récupération id séquence pour process
          select WFL_PROCESS_INSTANCES_SEQ.nextval
            into nProcInstId
            from dual;

          --??est-ce que l'on doit faire un test pour savoir si le process existe      -> OUI !!!
          --création instance process
          WFL_WORKFLOW_MANAGEMENT.CreateProcessInstance(aProcessId           => nProcessId
                                                      , aProcessInstanceId   => nProcInstId
                                                      , aParticipantId       => nParticipantId
                                                      , aObjectId            => aObjectId
                                                      , aRecordId            => aRecordId
                                                       );
          WFL_WORKFLOW_UTILS.ActivateLogging(aProcessInstanceId => nProcInstId);
          --On met à jour la variable de package indiquant la création d'un process
          ProcessCreated  := 1;
          --procédure après démarrage du process (état = NOTSTARTED, afterstart)
          WFL_WORKFLOW_UTILS.CallAfterStartProc(aProcessInstanceId => nProcInstId);

          --si mode process = automatique
          if upper(cStartMode) = 'AUTOMATIC' then
            WFL_WORKFLOW_UTILS.ActivateProcess(aObjectId    => aObjectId
                                             , aMainTable   => aMainTable
                                             , aRecordId    => aRecordId
                                             , aUserId      => aUserId
                                               );
          end if;
        end if;
      elsif bFoundProcess = 0 then
        --message d'erreur indiquant plusieurs process attachés au même élément
        aDuplProc  := 1;
      --raise_application_error(-20000, PCS.PC_FUNCTIONS.TranslateWord('Erreur, plusieurs processus sont déclenchés pour l''événement') || aEvent);
      end if;
    end if;
  end InitProcess;

  /*************** ActivateProcess *******************************************/
  procedure ActivateProcess(
    aObjectId  in WFL_OBJECT_PROCESSES.PC_OBJECT_ID%type
  , aMainTable in WFL_PROCESSES.PRO_TABNAME%type
  , aRecordId  in WFL_PROCESS_INSTANCES.PRI_REC_ID%type
  , aUserId    in PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  )
  is
    nParticipantId PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type;
    nProcInstId    WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type;
    bProcessOwner  WFL_WORKFLOW_TYPES.WFL_BOOLEAN;
  begin
    bProcessOwner  :=
       WFL_WORKFLOW_UTILS.IsUserProcessOwner(aObjectId    => aObjectId, aMainTable => aMainTable, aRecordId => aRecordId
                                           , aUserId      => aUserId);

    if bProcessOwner = 1 then
      --récupération identifiant process et participant
      nProcInstId  :=
        WFL_WORKFLOW_UTILS.GetProcessInstanceId(aObjectId        => aObjectId
                                              , aMainTable       => aMainTable
                                              , aRecordId        => aRecordId
                                              , aParticipantId   => nParticipantId
                                               );
      WFL_WORKFLOW_UTILS.ActivateLogging(aProcessInstanceId => nProcInstId);

      if     nProcInstId is not null
         and nParticipantId is not null then
        --initialisation des attributs du process
--        WFL_ATTRIBUTES_FUNCTIONS.InitProcessAttributes(aProcInstId => nProcInstId);

        --**pour les processus, pas de procédures stockées, donc à priori envoie d'emails non bloquants
        if WFL_WORKFLOW_UTILS.CallBeforeStopProc(aProcessInstanceId => nProcInstId) = 1 then
          --démarage du process
          WFL_WORKFLOW_MANAGEMENT.StartProcess(aProcessInstanceId => nProcInstId, aParticipantId => nParticipantId);
          --envoie mails après démarrage du process
          WFL_WORKFLOW_UTILS.CallAfterStartProc(aProcessInstanceId => nProcInstId);
        end if;
      end if;
    end if;
  end ActivateProcess;

  procedure ActivateProcess(
    aProcInstId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  , aUserId     in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  )
  is
    bProcessOwner  WFL_WORKFLOW_TYPES.WFL_BOOLEAN;
    nParticipantId PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type;
  begin
    WFL_WORKFLOW_UTILS.ActivateLogging(aProcessInstanceId => aProcInstId);

    if aProcInstId is not null then
      bProcessOwner  := IsUserProcessOwner(aProcInstId => aProcInstId, aUserId => aUserId);

      if bProcessOwner = 1 then
        nParticipantId  := PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantId(aUserId => aUserId);

        if nParticipantId is not null then
          --initialisation des attributs du process
--          WFL_ATTRIBUTES_FUNCTIONS.InitProcessAttributes(aProcInstId => aProcInstId);

          --opérations avant passage au status RUNNING
          if WFL_WORKFLOW_UTILS.CallBeforeStopProc(aProcessInstanceId => aProcInstId) = 1 then
            --démarrage du process
            WFL_WORKFLOW_MANAGEMENT.StartProcess(aProcessInstanceId => aProcInstId, aParticipantId => nParticipantId);
            --opérations après passage au status RUNNING
            WFL_WORKFLOW_UTILS.CallAfterStartProc(aProcessInstanceId => aProcInstId);
          end if;
        end if;
      end if;
    end if;
  end ActivateProcess;

  /*************** GetActivityParticipant ************************************/
  function GetActivityParticipant(aActivityInstId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type)
    return WFL_ACTIVITIES.PC_WFL_PARTICIPANTS_ID%type
  is
    result       WFL_ACTIVITIES.PC_WFL_PARTICIPANTS_ID%type;
    nProcInstId  WFL_ACTIVITY_INSTANCES.WFL_PROCESS_INSTANCES_ID%type;
    nAssignId    WFL_ACTIVITIES.ACT_ASSIGN_ID%type;
    nProcessId   WFL_ACTIVITIES.WFL_PROCESSES_ID%type;
    cActPartType WFL_ACTIVITIES.C_WFL_ACT_PART_TYPE%type;
    cPartFunc    WFL_ACTIVITIES.ACT_PART_FUNCTION%type;
    nProcOwnerId WFL_PROCESS_INSTANCES.PC_WFL_PARTICIPANTS_ID%TYPE;
    nOwnerAuth   WFL_ACTIVITIES.ACT_PROC_OWNER_AUTH%type;
  begin
    --récupération du rôle ou participant pour faire l'activité
    select ACT.PC_WFL_PARTICIPANTS_ID
         , ACT.C_WFL_ACT_PART_TYPE
         , ACT.ACT_ASSIGN_ID
         , ACT.ACT_PART_FUNCTION
         , ACT.WFL_PROCESSES_ID
         , AIN.WFL_PROCESS_INSTANCES_ID
         , PRI.PC_WFL_PARTICIPANTS_ID
         , ACT.ACT_PROC_OWNER_AUTH
      into result
         , cActPartType
         , nAssignId
         , cPartFunc
         , nProcessId
         , nProcInstId
         , nProcOwnerId
         , nOwnerAuth
      from WFL_ACTIVITY_INSTANCES AIN
         , WFL_ACTIVITIES ACT
         , WFL_PROCESS_INSTANCES PRI
     where AIN.WFL_ACTIVITIES_ID = ACT.WFL_ACTIVITIES_ID
       and AIN.WFL_PROCESSES_ID = ACT.WFL_PROCESSES_ID
       and PRI.WFL_PROCESS_INSTANCES_ID = AIN.WFL_PROCESS_INSTANCES_ID
       and AIN.WFL_ACTIVITY_INSTANCES_ID = aActivityInstId;

    if cActPartType = 'ACT_PERF' then
      select PFM.PC_WFL_PARTICIPANTS_ID
        into result
        from WFL_PERFORMERS PFM
       where PFM.C_WFL_PER_STATE = 'CURRENT'
         and PFM.WFL_ACTIVITY_INSTANCES_ID =
               (select max(AIN.WFL_ACTIVITY_INSTANCES_ID)
                  from WFL_ACTIVITY_INSTANCES AIN
                 where AIN.WFL_PROCESSES_ID = nProcessId
                   and AIN.WFL_ACTIVITIES_ID = nAssignId
                   and AIN.WFL_PROCESS_INSTANCES_ID = nProcInstId
                   and not ((nProcOwnerId = PFM.PC_WFL_PARTICIPANTS_ID) and (nOwnerAuth= 0))
                   );
    elsif cActPartType = 'PROC_OWNER' then
      select PC_WFL_PARTICIPANTS_ID
        into result
        from WFL_PROCESS_INSTANCES
       where WFL_PROCESS_INSTANCES_ID = nProcInstId
         and (nOwnerAuth = 1);
    elsif cActPartType = 'PART_PLSQL' then
      execute immediate 'select
        ' ||            cPartFunc || '
         from dual'
                   into result;
    end if;



    return result;
  exception
    when others then
      return null;
  end GetActivityParticipant;

  /*************** GetActivityPerformer **************************************/
  function GetActivityPerformer(aActivityInstanceId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type)
    return WFL_ACTIVITIES.PC_WFL_PARTICIPANTS_ID%type
  is
    nPerfPartId WFL_ACTIVITIES.PC_WFL_PARTICIPANTS_ID%type;
    nActPartId  WFL_ACTIVITIES.PC_WFL_PARTICIPANTS_ID%type;
    cActState   WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type;
  begin
    begin
      --si l'activité est completed ou suspended, alors on récupère la valeur ds performers
      select DISTINCT PFM.PC_WFL_PARTICIPANTS_ID
           , WFL_WORKFLOW_UTILS.GetActivityParticipant(AIN.WFL_ACTIVITY_INSTANCES_ID)
           , AIN.C_WFL_ACTIVITY_STATE
        into nPerfPartId
           , nActPartId
           , cActState
        from WFL_PERFORMERS PFM
           , WFL_ACTIVITY_INSTANCES AIN
       where PFM.WFL_ACTIVITY_INSTANCES_ID(+) = AIN.WFL_ACTIVITY_INSTANCES_ID
         and AIN.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
         and PFM.C_WFL_PER_STATE(+) = 'CURRENT'
         and PFM.PC_WFL_PARTICIPANTS_ID <> PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.WorkflowParticipant;

      --test le status et renvoie le résultat en conséquence
      if    (cActState = 'COMPLETED')
         or (cActState = 'SUSPENDED') then
        return nPerfPartId;
      elsif(cActState = 'NOTRUNNING') then
        return nActPartId;
      elsif(cActState = 'RUNNING') then
        return nPerfPartId;
      else
        return null;
      end if;
    exception
      when no_data_found then
        return null;
    end;
  end GetActivityPerformer;

  /*************** CanPerformProcess *****************************************/
  function CanPerformProcess(
    aUserId     in PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  , aProcInstId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  , aObjectId   in WFL_PROCESS_INSTANCES.PC_OBJECT_ID%type
  , aMainTable  in WFL_PROCESS_INSTANCES.PRI_TABNAME%type
  , aRecordId   in WFL_PROCESS_INSTANCES.PRI_REC_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    result WFL_WORKFLOW_TYPES.WFL_BOOLEAN default 0;
  begin
    select decode(count(PRI.WFL_PROCESS_INSTANCES_ID), 0, 0, 1)
      into result
      from WFL_PROCESS_INSTANCES PRI
     where PRI.PC_OBJECT_ID = aObjectId
       and PRI.PRI_TABNAME = aMainTable
       and PRI.PRI_REC_ID = aRecordId
       and PRI.WFL_PROCESS_INSTANCES_ID = aProcInstId;

    if result = 1 then
      result  := WFL_WORKFLOW_UTILS.IsUserProcessOwner(aProcInstId => aProcInstId, aUserId => aUserID);

      if result = 0 then
        result  := WFL_WORKFLOW_UTILS.IsUserProcessAutoOwner(aProcInstId => aProcInstId, aUserId => aUserId);
      end if;
    end if;

    return result;
  end CanPerformProcess;

  /*************** CanPerformActivity ****************************************/
  function CanPerformActivity(
    aParticipantId  in WFL_ACTIVITIES.PC_WFL_PARTICIPANTS_ID%type
  , aActivityInstId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    result      WFL_WORKFLOW_TYPES.WFL_BOOLEAN               default 0;
    nRolePartId WFL_ACTIVITIES.PC_WFL_PARTICIPANTS_ID%type;
  begin
    --seul les personnes peuvent prendre en charge l'activité
    if    PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.ParticipantIsType(aParticipantId, 'HUMAN')
       or (aParticipantId = PlFlowParticipant) then
      --récupère le role nécessaire pour l'activité
      nRolePartId  := GetActivityParticipant(aActivityInstId);

      --l'utilisateur peut prendre en charge l'activité si il à le rôle nécessaire
      if not(    PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.ParticipantIsType(nRolePartId, 'HUMAN')
             and (nRolePartId = aParticipantId)
            ) then
        --teste si le participant à le rôle pour prendre en charge l'activité
        result  :=
          greatest(PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.HasRole(aHumanParticipantId   => aParticipantId
                                                           , aRoleId               => nRolePartId
                                                            )
                 , PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.IsMemberOf(aHumanParticipantId   => aParticipantId
                                                              , aOrganUnitId          => nRolePartId
                                                               )
                  );
      elsif nRolePartId is not null then
        result  := 1;
      end if;
    end if;

    return result;
  end CanPerformActivity;

  function CanPerformActivity(
    aUserId         in PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  , aActivityInstId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aObjectId       in WFL_PROCESS_INSTANCES.PC_OBJECT_ID%type
  , aMainTable      in WFL_PROCESS_INSTANCES.PRI_TABNAME%type
  , aRecordId       in WFL_PROCESS_INSTANCES.PRI_REC_ID%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    result         WFL_WORKFLOW_TYPES.WFL_BOOLEAN                        default 0;
    bObjOwner      WFL_WORKFLOW_TYPES.WFL_BOOLEAN;
    nParticipantId PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type;
  begin
    result          := 0;
    nParticipantId  := PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantId(aUserId => aUserId);

    if nParticipantId is not null then
      select decode(count(PRI.WFL_PROCESS_INSTANCES_ID), 0, 0, 1)
        into bObjOwner
        from WFL_PROCESS_INSTANCES PRI
           , WFL_ACTIVITY_INSTANCES AIN
       where PRI.PC_OBJECT_ID = aObjectId
         and PRI.PRI_TABNAME = aMainTable
         and PRI.PRI_REC_ID = aRecordId
         and PRI.WFL_PROCESS_INSTANCES_ID = AIN.WFL_PROCESS_INSTANCES_ID
         and AIN.C_WFL_ACTIVITY_STATE in('RUNNING', 'NOTRUNNING', 'SUSPENDED')
         and AIN.WFL_ACTIVITY_INSTANCES_ID = aActivityInstId;

      if bObjOwner = 1 then
        result  := WFL_WORKFLOW_UTILS.CanPerformActivity(aParticipantId => nParticipantId, aActivityInstId => aActivityInstId);
      end if;
    end if;

    return result;
  end CanPerformActivity;

/*************** StartActivity *********************************************/
  procedure StartActivity(
    aActivityInstanceId in     WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aUserId             in     PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  , aLock               out    number
  )
  is
    cActState      WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type;
    nParticipantId PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type;
    bisTask        WFL_ACTIVITIES.ACT_TASK%type;
    cTaskKind      WFL_ACTIVITIES.C_WFL_TASK_KIND%type;
    nTaskReady     number;
  begin
    WFL_WORKFLOW_UTILS.ActivateLogging(aActivityInstanceId => aActivityInstanceId);
    aLock  := 0;

    --si état activité différent de NOTRUNNING -> exception
    select     C_WFL_ACTIVITY_STATE
          into cActState
          from WFL_ACTIVITY_INSTANCES
         where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
    for update nowait;

    select     act.ACT_TASK
          into bisTask
          from WFL_ACTIVITIES act, WFL_ACTIVITY_INSTANCES ain
         where  act.WFL_ACTIVITIES_ID = ain.WFL_ACTIVITIES_ID
           and  ain.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;

    if cActState = 'NOTRUNNING' then
      --récupération du participant
      nParticipantId  := PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantId(aUserId => aUserId);

      if nParticipantId is not null then
        if bisTask <>1 then

          --opérations avant passage au status RUNNING
          if WFL_WORKFLOW_UTILS.CallBeforeStopAct(aActivityInstanceId => aActivityInstanceId) = 1 then
            --activation de l'activité
            WFL_WORKFLOW_MANAGEMENT.ChangeActivityInstanceState(aActivityInstanceId   => aActivityInstanceId
                                                              , aNewState             => 'RUNNING'
                                                              , aParticipantId        => nParticipantId
                                                               );
            --opérations après passage au status RUNNING
            WFL_WORKFLOW_UTILS.CallAfterStartAct(aActivityInstanceId => aActivityInstanceId);
          else
            aLock  := 2;   --**remplacer par un code d'erreur 1 => Lock, 2 => Erreur durant les opération de contrôle BeforeStop
          end if;
        else
          --opérations avant passage au status RUNNING
          if WFL_WORKFLOW_UTILS.CallBeforeStopAct(aActivityInstanceId => aActivityInstanceId) = 1 then

          --Récupération du genre de type de tâche
          select act.C_WFL_TASK_KIND
            into cTaskKind
            from wfl_Activity_instances ain,
                 wfl_Activities act
           where ain.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
             and act.WFL_ACTIVITIES_ID = ain.WFL_ACTIVITIES_ID;

           -- Teste si la tâche peut passer en mode RUNNING
           -- Comportement différent si genre du type de tâche est INFO ou STANDARD
           begin
             select Count(*)
             into nTaskReady
             from WFL_ACTIVITY_INSTANCES ain,
                  WFL_TASK_PARTICIPANT_GROUP wpg,
                  PCS.PC_WFL_PARTICIPANTS par
             where ain.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
              and nParticipantId = par.PC_WFL_PARTICIPANTS_ID
              and (((wpg.WFL_ACTIVITY_INSTANCES_ID = ain.WFL_ACTIVITY_INSTANCES_ID
                   and par.PC_WFL_PARTICIPANTS_ID = wpg.PC_WFL_PARTICIPANTS_ID) and cTaskKind = 'STANDARD' )
                   or (cTaskKind = 'INFO')
                   ) ;
           exception
             when no_data_found then
               nTaskReady := 0;
             end;

          -- Si la tâche peut être traité ,a lors on la passe en mode running
          if nTaskReady >= 1 then
              update WFL_ACTIVITY_INSTANCES
              set C_WFL_ACTIVITY_STATE = 'RUNNING'
               , PC_WFL_PARTICIPANTS_ID = nParticipantId
               , AIN_DATE_STARTED = sysdate
              where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;
          end if;
            --opérations après passage au status RUNNING
            WFL_WORKFLOW_UTILS.CallAfterStartAct(aActivityInstanceId => aActivityInstanceId);
          else
            aLock  := 2;   --**remplacer par un code d'erreur 1 => Lock, 2 => Erreur durant les opération de contrôle BeforeStop
          end if;
        end if;
      else
        Raise_Application_Error(-20110, 'StartActivity, user ' || aUserId || ' is not a valid participant');
      end if;
    else
      --l'état n'est pas autorisé message d'erreur
      Raise_Application_Error(-20111, 'StartActivity, impossible to start a activity with state ' || cActState);
    end if;


  exception
    when ex.ROW_LOCKED then
      aLock  := 1;
    when no_data_found then
      Raise_Application_Error(-20112, 'StartActivity, activity_instance ' || aActivityInstanceId || ' does not exists');
  end StartActivity;

  /*************** procedure TerminateActivity *******************************/
  procedure TerminateActivity(
    aActivityInstanceId in     WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aUserId             in     PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  , aLock               out    number
  )
  is
    cActState      WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type;
    nParticipantId PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type;
    bisTask        WFL_ACTIVITIES.ACT_TASK%type;
  begin
    --si état activité différent de NOTRUNNING -> exception
    WFL_WORKFLOW_UTILS.ActivateLogging(aActivityInstanceId => aActivityInstanceId);
    aLock  := 0;

    select     C_WFL_ACTIVITY_STATE
          into cActState
          from WFL_ACTIVITY_INSTANCES
         where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
    for update nowait;

    select     act.ACT_TASK
          into bisTask
          from WFL_ACTIVITIES act, WFL_ACTIVITY_INSTANCES ain
         where  act.WFL_ACTIVITIES_ID = ain.WFL_ACTIVITIES_ID
           and  ain.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
    for update nowait;

    if    (cActState = 'NOTRUNNING')
       or (cActState = 'RUNNING')
       or (cActState = 'SUSPENDED') then
      --récupération du participant
      nParticipantId  := PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantId(aUserId => aUserId);

      if nParticipantId is not null then
        if bisTask <> 1 then
          --opérations avant passage au status TERMINATED
          if WFL_WORKFLOW_UTILS.CallBeforeStopAct(aActivityInstanceId => aActivityInstanceId) = 1 then
            --activation de l'activité
            WFL_WORKFLOW_MANAGEMENT.ChangeActivityInstanceState(aActivityInstanceId   => aActivityInstanceId
                                                              , aNewState             => 'TERMINATED'
                                                              , aParticipantId        => nParticipantId
                                                               );
            --opérations après passage au status TERMINATED
            WFL_WORKFLOW_UTILS.CallAfterStartAct(aActivityInstanceId => aActivityInstanceId);
          else
            aLock  := 2;
          end if;
        else
          --opérations avant passage au status TERMINATED
          if WFL_WORKFLOW_UTILS.CallBeforeStopAct(aActivityInstanceId => aActivityInstanceId) = 1 then

            update WFL_ACTIVITY_INSTANCES
               set C_WFL_ACTIVITY_STATE = 'TERMINATED'
                 , AIN_DATE_STARTED = sysdate
             where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;

            --opérations après passage au status TERMINATED
            WFL_WORKFLOW_UTILS.CallAfterStartAct(aActivityInstanceId => aActivityInstanceId);
          else
            aLock  := 2;   --**remplacer par un code d'erreur 1 => Lock, 2 => Erreur durant les opération de contrôle BeforeStop
          end if;
        end if;
      else
        Raise_Application_Error(-20120, 'TerminateActivity, user ' || aUserId || ' is not a valid participant');
      end if;
    else
      --l'état n'est pas autorisé message d'erreur
      Raise_Application_Error(-20121, 'TerminateActivity, impossible to terminate a activity with state ' || cActState);
    end if;
  exception
    when ex.ROW_LOCKED then
      aLock  := 1;
    when no_data_found then
      Raise_Application_Error(-20122
                            , 'TerminateActivity, activity_instance ' || aActivityInstanceId || ' does not exists'
                             );
  end TerminateActivity;

/*************** AbortActivity *********************************************/
  procedure AbortActivity(
    aActivityInstanceId in     WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aUserId             in     PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  , aLock               out    number
  )
  is
    cActState      WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type;
    nParticipantId PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type;
    bisTask        WFL_ACTIVITIES.ACT_TASK%type;
  begin
    --si état activité différent de NOTRUNNING -> exception
    WFL_WORKFLOW_UTILS.ActivateLogging(aActivityInstanceId => aActivityInstanceId);
    aLock  := 0;

    select     C_WFL_ACTIVITY_STATE
          into cActState
          from WFL_ACTIVITY_INSTANCES
         where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
    for update nowait;

    select     act.ACT_TASK
          into bisTask
          from WFL_ACTIVITIES act, WFL_ACTIVITY_INSTANCES ain
         where  act.WFL_ACTIVITIES_ID = ain.WFL_ACTIVITIES_ID
           and  ain.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
    for update nowait;

    if    (cActState = 'NOTRUNNING')
       or (cActState = 'RUNNING')
       or (cActState = 'SUSPENDED')
       or (cActState = 'TERMINATED') then
      --récupération du participant
      nParticipantId  := PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantId(aUserId => aUserId);

      if nParticipantId is not null then
        if bisTask <>1 then
          --opérations avant passage au status ABORTED
          if WFL_WORKFLOW_UTILS.CallBeforeStopAct(aActivityInstanceId => aActivityInstanceId) = 1 then
            --activation de l'activité
            WFL_WORKFLOW_MANAGEMENT.ChangeActivityInstanceState(aActivityInstanceId   => aActivityInstanceId
                                                              , aNewState             => 'ABORTED'
                                                              , aParticipantId        => nParticipantId
                                                               );
            --opérations après passage au status ABORTED
            WFL_WORKFLOW_UTILS.CallAfterStartAct(aActivityInstanceId => aActivityInstanceId);
          else
            aLock  := 2;
          end if;
        else
          --opérations avant passage au status ABORTED
          if WFL_WORKFLOW_UTILS.CallBeforeStopAct(aActivityInstanceId => aActivityInstanceId) = 1 then
            update WFL_ACTIVITY_INSTANCES
               set C_WFL_ACTIVITY_STATE = 'ABORTED'
                 , AIN_DATE_STARTED = sysdate
             where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;
            --opérations après passage au status ABORTED
            WFL_WORKFLOW_UTILS.CallAfterStartAct(aActivityInstanceId => aActivityInstanceId);
          else
            aLock  := 2;   --**remplacer par un code d'erreur 1 => Lock, 2 => Erreur durant les opération de contrôle BeforeStop
          end if;
        end if;
      else
        Raise_Application_Error(-20130, 'AbortActivity, user ' || aUserId || ' is not a valid participant');
      end if;
    else
      --l'état n'est pas autorisé message d'erreur
      Raise_Application_Error(-20131, 'AbortActivity, impossible to abort a activity with state ' || cActState);
    end if;
  exception
    when ex.ROW_LOCKED then
      aLock  := 1;
    when no_data_found then
      Raise_Application_Error(-20132, 'AbortActivity, activity_instance ' || aActivityInstanceId || ' does not exists');
  end AbortActivity;

  /*************** ReleaseActivity *******************************************/
  procedure ReleaseActivity(
    aActivityInstanceId in     WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aUserId             in     PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  , aLock               out    number
  )
  is
    cActState      WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type;
    nParticipantId PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type;
    bisTask        WFL_ACTIVITIES.ACT_TASK%type;
  begin
    --si état activité différent de NOTRUNNING -> exception
    WFL_WORKFLOW_UTILS.ActivateLogging(aActivityInstanceId => aActivityInstanceId);
    aLock  := 0;

    select     C_WFL_ACTIVITY_STATE
          into cActState
          from WFL_ACTIVITY_INSTANCES
         where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
    for update nowait;

    select     act.ACT_TASK
          into bisTask
          from WFL_ACTIVITIES act, WFL_ACTIVITY_INSTANCES ain
         where  act.WFL_ACTIVITIES_ID = ain.WFL_ACTIVITIES_ID
           and  ain.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
    for update nowait;

    if    (cActState = 'RUNNING')
       or (cActState = 'SUSPENDED') then
      --récupération du participant
      nParticipantId  := PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantId(aUserId => aUserId);

      if (nParticipantId is not null) then
        if  (bisTask <> 1) then
          --opérations avant passage à l'état NOTRUNNING
          if WFL_WORKFLOW_UTILS.CallBeforeStopAct(aActivityInstanceId => aActivityInstanceId) = 1 then
            --activation de l'activité
            WFL_WORKFLOW_MANAGEMENT.ChangeActivityInstanceState(aActivityInstanceId   => aActivityInstanceId
                                                              , aNewState             => 'NOTRUNNING'
                                                              , aParticipantId        => nParticipantId
                                                               );
            --opérations après passage à l'état NOTRUNNING
            WFL_WORKFLOW_UTILS.CallAfterStartAct(aActivityInstanceId => aActivityInstanceId);
          else
            aLock  := 2;
          end if;
        else
          --opérations avant passage à l'état NOTRUNNING
          if WFL_WORKFLOW_UTILS.CallBeforeStopAct(aActivityInstanceId => aActivityInstanceId) = 1 then
            update WFL_ACTIVITY_INSTANCES
               set C_WFL_ACTIVITY_STATE = 'NOTRUNNING'
                 , AIN_DATE_STARTED = sysdate
             where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;
            --opérations après passage à l'état NOTRUNNING
            WFL_WORKFLOW_UTILS.CallAfterStartAct(aActivityInstanceId => aActivityInstanceId);
          else
            aLock  := 2;   --**remplacer par un code d'erreur 1 => Lock, 2 => Erreur durant les opération de contrôle BeforeStop
          end if;
        end if;
      else
        Raise_Application_Error(-20140, 'ReleaseActivity, user ' || aUserId || ' is not a valid participant');
      end if;
    else
      --l'état n'est pas autorisé message d'erreur
      Raise_Application_Error(-20141, 'ReleaseActivity, impossible to release a activity with state ' || cActState);
    end if;
  exception
    when ex.ROW_LOCKED then
      aLock  := 1;
    when no_data_found then
      Raise_Application_Error(-20142
                            , 'ReleaseActivity, activity_instance ' || aActivityInstanceId || ' does not exists'
                             );
  end ReleaseActivity;

  /*************** SuspendActivity *******************************************/
  procedure SuspendActivity(
    aActivityInstanceId in     WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aUserId             in     PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  , aLock               out    number
  )
  is
    cActState      WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type;
    nParticipantId PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type;
    bisTask        WFL_ACTIVITIES.ACT_TASK%type;
  begin
    --si état activité différent de NOTRUNNING -> exception
    WFL_WORKFLOW_UTILS.ActivateLogging(aActivityInstanceId => aActivityInstanceId);
    aLock  := 0;

    select     C_WFL_ACTIVITY_STATE
          into cActState
          from WFL_ACTIVITY_INSTANCES
         where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
    for update nowait;

    select     act.ACT_TASK
          into bisTask
          from WFL_ACTIVITIES act, WFL_ACTIVITY_INSTANCES ain
         where  act.WFL_ACTIVITIES_ID = ain.WFL_ACTIVITIES_ID
           and  ain.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
    for update nowait;

    if (cActState = 'RUNNING') then
      --récupération du participant
      nParticipantId  := PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantId(aUserId => aUserId);

      if nParticipantId is not null then
        if bisTask <> 1 then
          --opérations avant le passage au status SUSPENDED
          if WFL_WORKFLOW_UTILS.CallBeforeStopAct(aActivityInstanceId => aActivityInstanceId) = 1 then
            --activation de l'activité
            WFL_WORKFLOW_MANAGEMENT.ChangeActivityInstanceState(aActivityInstanceId   => aActivityInstanceId
                                                              , aNewState             => 'SUSPENDED'
                                                              , aParticipantId        => nParticipantId
                                                               );
            --opérations après le passage au status SUSPENDED
            WFL_WORKFLOW_UTILS.CallAfterStartAct(aActivityInstanceId => aActivityInstanceId);
          else
            aLock  := 2;
          end if;
        else
          --opérations avant le passage au status SUSPENDED
          if WFL_WORKFLOW_UTILS.CallBeforeStopAct(aActivityInstanceId => aActivityInstanceId) = 1 then
            update WFL_ACTIVITY_INSTANCES
               set C_WFL_ACTIVITY_STATE = 'SUSPENDED'
                 , AIN_DATE_STARTED = sysdate
             where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;
            --opérations après le passage au status SUSPENDED
            WFL_WORKFLOW_UTILS.CallAfterStartAct(aActivityInstanceId => aActivityInstanceId);
          else
            aLock  := 2;   --**remplacer par un code d'erreur 1 => Lock, 2 => Erreur durant les opération de contrôle BeforeStop
          end if;
        end if;
      else
        Raise_Application_Error(-20150, 'SuspendActivity, user ' || aUserId || ' is not a valid participant');
      end if;
    else
      --l'état n'est pas autorisé message d'erreur
      Raise_Application_Error(-20151, 'SuspendActivity, impossible to suspend a activity with state ' || cActState);
    end if;
  exception
    when ex.ROW_LOCKED then
      aLock  := 1;
    when no_data_found then
      Raise_Application_Error(-20152
                            , 'SuspendActivity, activity_instance ' || aActivityInstanceId || ' does not exists'
                             );
  end SuspendActivity;

  /*************** CompleteActivity ******************************************/
  procedure CompleteActivity(
    aActivityInstanceId in     WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aUserId             in     PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  , aLock               out    number
  )
  is
    cActState      WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type;
    nParticipantId PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type;
    nActPerfId     PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type;
    bisTask        WFL_ACTIVITIES.ACT_TASK%type;
  begin
    --si état activité différent de NOTRUNNING -> exception
    WFL_WORKFLOW_UTILS.ActivateLogging(aActivityInstanceId => aActivityInstanceId);
    aLock  := 0;

    select     C_WFL_ACTIVITY_STATE
          into cActState
          from WFL_ACTIVITY_INSTANCES
         where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
    for update nowait;

    select     act.ACT_TASK
          into bisTask
          from WFL_ACTIVITIES act, WFL_ACTIVITY_INSTANCES ain
         where  act.WFL_ACTIVITIES_ID = ain.WFL_ACTIVITIES_ID
           and  ain.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
    for update nowait;

    if (cActState = 'RUNNING') then
      --récupération du participant
      nParticipantId  := PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantId(aUserId => aUserId);

      if nParticipantId is not null then
        if bisTask <>1 then
          --seul l'utilisateur ayant pris en charge l'activité peut la compléter ??
          nActPerfId  := WFL_WORKFLOW_UTILS.GetActivityPerformer(aActivityInstanceId => aActivityInstanceId);

          if nParticipantId = nActPerfId then
            --opérations avant le passage au status 'COMPLETED'
            if WFL_WORKFLOW_UTILS.CallBeforeStopAct(aActivityInstanceId => aActivityInstanceId) = 1 then
              --activation de l'activité
              WFL_WORKFLOW_MANAGEMENT.ChangeActivityInstanceState(aActivityInstanceId   => aActivityInstanceId
                                                                , aNewState             => 'COMPLETED'
                                                                , aParticipantId        => nParticipantId
                                                                 );
              --opérations après le passage au status COMPLETED
              WFL_WORKFLOW_UTILS.CallAfterStartAct(aActivityInstanceId => aActivityInstanceId);
            else
              aLock  := 2;
            end if;
          else
            Raise_Application_Error(-20160
                                  , 'CompleteActivity, user ' || aUserId || ' is not allowed to complete the activity'
                                   );
          end if;
        else
            --opérations avant le passage au status 'COMPLETED'
          if WFL_WORKFLOW_UTILS.CallBeforeStopAct(aActivityInstanceId => aActivityInstanceId) = 1 then
            update WFL_ACTIVITY_INSTANCES
               set C_WFL_ACTIVITY_STATE = 'COMPLETED'
                 , AIN_DATE_STARTED = sysdate
             where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;
              --opérations après le passage au status COMPLETED
            WFL_WORKFLOW_UTILS.CallAfterStartAct(aActivityInstanceId => aActivityInstanceId);
          else
            aLock  := 2;   --**remplacer par un code d'erreur 1 => Lock, 2 => Erreur durant les opération de contrôle BeforeStop
          end if;
        end if;
      else
        Raise_Application_Error(-20160, 'CompleteActivity, user ' || aUserId || ' is not a valid participant');
      end if;
    else
      --l'état n'est pas autorisé message d'erreur
      Raise_Application_Error(-20161, 'CompleteActivity, impossible to complete a activity with state ' || cActState);
    end if;
  exception
    when ex.ROW_LOCKED then
      aLock  := 1;
    when no_data_found then
      Raise_Application_Error(-20162
                            , 'CompleteActivity, activity_instance ' || aActivityInstanceId || ' does not exists'
                             );
  end CompleteActivity;

  /*************** ResumeActivity ********************************************/
  procedure ResumeActivity(
    aActivityInstanceId in     WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aUserId             in     PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  , aLock               out    number
  )
  is
    cActState      WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type;
    nParticipantId PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type;
    bisTask        WFL_ACTIVITIES.ACT_TASK%type;
  begin
    --si état activité différent de NOTRUNNING -> exception
    WFL_WORKFLOW_UTILS.ActivateLogging(aActivityInstanceId => aActivityInstanceId);
    aLock  := 0;

    select     C_WFL_ACTIVITY_STATE
          into cActState
          from WFL_ACTIVITY_INSTANCES
         where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
    for update nowait;

    select     act.ACT_TASK
          into bisTask
          from WFL_ACTIVITIES act, WFL_ACTIVITY_INSTANCES ain
         where  act.WFL_ACTIVITIES_ID = ain.WFL_ACTIVITIES_ID
           and  ain.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
    for update nowait;

    if (cActState = 'SUSPENDED') then
      --récupération du participant
      nParticipantId  := PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantId(aUserId => aUserId);

      if nParticipantId is not null then
        if bisTask <> 1 then
          --opérations avant le passage au status RUNNING
          if WFL_WORKFLOW_UTILS.CallBeforeStopAct(aActivityInstanceId => aActivityInstanceId) = 1 then
            --activation de l'activité
            WFL_WORKFLOW_MANAGEMENT.ChangeActivityInstanceState(aActivityInstanceId   => aActivityInstanceId
                                                              , aNewState             => 'RUNNING'
                                                              , aParticipantId        => nParticipantId
                                                               );
            --opérations après le passage au status RUNNING
            WFL_WORKFLOW_UTILS.CallAfterStartAct(aActivityInstanceId => aActivityInstanceId);
          else
            aLock  := 2;
          end if;
        else
          --opérations avant le passage au status RUNNING
          if WFL_WORKFLOW_UTILS.CallBeforeStopAct(aActivityInstanceId => aActivityInstanceId) = 1 then
            update WFL_ACTIVITY_INSTANCES
               set C_WFL_ACTIVITY_STATE = 'RUNNING'
                 , AIN_DATE_STARTED = sysdate
             where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;
            --opérations après le passage au status RUNNING
            WFL_WORKFLOW_UTILS.CallAfterStartAct(aActivityInstanceId => aActivityInstanceId);
          else
            aLock  := 2;   --**remplacer par un code d'erreur 1 => Lock, 2 => Erreur durant les opération de contrôle BeforeStop
          end if;
        end if;
      else
        Raise_Application_Error(-20170, 'ResumeActivity, user ' || aUserId || ' is not a valid participant');
      end if;
    else
      --l'état n'est pas autorisé message d'erreur
      Raise_Application_Error(-20171, 'ResumeActivity, impossible to resume a activity with state ' || cActState);
    end if;
  exception
    when ex.ROW_LOCKED then
      aLock  := 1;
    when no_data_found then
      Raise_Application_Error(-20172
                            , 'ResumeActivity, activity_instance ' || aActivityInstanceId || ' does not exists');
  end ResumeActivity;

  /*************** GetAllTasks ***********************************************/
  procedure GetAllTasksDbLink(
    aUserId    in PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  , aCompanyId in PCS.PC_WFL_WORKLIST.PC_COMP_ID%type
  )
  is
    /**
    bFirst        Boolean;
    cInsQry       clob;
    cValues       clob;
    oExceptFields WFL_WORKFLOW_TYPES.TColFields default WFL_WORKFLOW_TYPES.TColFields();
     */
  begin
    null;--**à faire une fois les instances définies
    /*
    --Récupération des tâches pour toutes les instances disponibles

    --récupération tâches schéma en cours
    GetAllTasks(aUserId,aCompanyId);


    --parcours d'un curseur des instances (DbLinks) pour l'utilisateur et recherche des tâches
    for tplUserInstance in (select INST.<DBLINK>
                                 , INST.<INSTANCE_NAME>
                              from <TABLE_INSTANCES> INST
                                 , PCS.PC_WFL_PARTICIPANTS WPA
                             where INST.PC_WFL_PARTICIPANTS_ID = WPA.PC_WFL_PARTICIPANTS_ID
                               and WPA.PC_USER_ID = aUserId) loop

      --récupération des tâches dans l'instance donnée par le dblink
      begin
        execute immediate 'begin ' || chr(10) ||
                          '  WFL_WORKFLOW_UTILS.GetAllTasks@' || tpUserInstance.<DBLINK> || '(:aUserId' || chr(10) ||
                                                                                           ', :aCompanyId' || chr(10) ||
                                                                                           ', :aInstName);' || chr(10) ||
                          'end;'
                    using aUserId
                        , aCompanyId-- ici éventuellement requête pour récupérer userid et companyid dans schéma DbLink
                        , tplUserInstance.<INSTANCE_NAME>;

        --insère les éléments de la table temporaire dans le schéma actuel en récupérant les données sur le dblink
        bFirst  := True;
        cInsQry := 'insert into PCS.PC_WFL_WORKLIST(' || chr(10) ||
        cValues := 'select ';
        for tplColumns in (select COLUMN_NAME
                             from ALL_TAB_COLUMNS
                            where TABLE_NAME = 'PC_WFL_WORKLIST'
                              and OWNER = 'PCS') loop
          if bFirst then
            cInsQry := ', ' || cInsQry;
            cValues := ', ' || cValues;
            bFirst  := False;
          end if;
          cInsQry := cInsQry || tplColumns.COLUMN_NAME;
          cValues := cValues || tplColumns.COLUMN_NAME;
        end loop;
        cInsQry := cInsQry || ')' || chr(10) ||
                   cValues || 'from PCS.PC_WFL_WORKLIST@' || tplUserInstance.<DBLINK> ';
        execute immediate cInsQry;
      exception
      end;
    end loop;
    */
  end;

  procedure GetAllTasks(
    aUserId    in PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  , aCompanyId in PCS.PC_WFL_WORKLIST.PC_COMP_ID%type
  , aInstName  in PCS.PC_WFL_WORKLIST.WOR_INSTANCE_NAME%type
  )
  is
  begin
    --récupération des tâches disponibles
    WFL_WORKFLOW_UTILS.GetWorkList(aUserId => aUserId, aCompanyId => aCompanyId, aInstName => aInstName);
    --récupération tâches suspendues
    WFL_WORKFLOW_UTILS.GetSuspendedTasks(aUserId => aUserId, aCompanyId => aCompanyId, aInstName => aInstName);
    --récupération tâches actives
    WFL_WORKFLOW_UTILS.GetActiveTasks(aUserId => aUserId, aCompanyId => aCompanyId, aInstName => aInstName);
    --récupération des tâches workflowlight(ACT_TASK = 1)
    WFL_WORKFLOW_UTILS.GetTaskTasks(aUserId => aUserId, aCompanyId => aCompanyId, aInstName => aInstName);
  end;

  /*************** GetProcInstTasks ******************************************/
  procedure GetProcInstTasks(
    aProcessInstanceId in PCS.PC_WFL_WORKLIST.WFL_PROCESS_INSTANCES_ID%type
  , aUserId            in PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  , aCompanyId         in PCS.PC_WFL_WORKLIST.PC_COMP_ID%type
  , aInstName          in PCS.PC_WFL_WORKLIST.WOR_INSTANCE_NAME%type default ''
  )
  is
  begin
    --suppression des records tables temporaires
    delete from PCS.PC_WFL_WORKLIST;

    --récupération tâches disponibles
    WFL_WORKFLOW_UTILS.GetWorkList(aUserId => aUserId, aCompanyId => aCompanyId, aInstName => aInstName);
    --récupération tâches suspendues
    WFL_WORKFLOW_UTILS.GetSuspendedTasks(aUserId => aUserId, aCompanyId => aCompanyId, aInstName => aInstName);
    --récupération tâches actives
    WFL_WORKFLOW_UTILS.GetActiveTasks(aUserId => aUserId, aCompanyId => aCompanyId, aInstName => aInstName);

    --suppression tâches n'appartenant pas à la même instance de processus
    delete from PCS.PC_WFL_WORKLIST
          where WFL_PROCESS_INSTANCES_ID <> aProcessInstanceId;
  end;

/*************** GetWorkList ***********************************************/
  procedure GetWorkList(
    aUserId    in PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  , aCompanyId in PCS.PC_WFL_WORKLIST.PC_COMP_ID%type
  , aInstName  in PCS.PC_WFL_WORKLIST.WOR_INSTANCE_NAME%type
  )
  is
    --curseur qui parcours les éléments de la worklist pour le lookup de pri_rec_id
    cursor crPriShowProc
    is
      select distinct (PRIN.PRI_SHOW_PROC) PRI_SHOW_PROC
                    , PRIN.WFL_PROCESS_INSTANCES_ID
                    , WOR.PRI_REC_ID
                 from WFL_PROCESS_INSTANCES PRIN
                    , WFL_WORKLIST WOR
                where PRIN.WFL_PROCESS_INSTANCES_ID = WOR.WFL_PROCESS_INSTANCES_ID;

    tplPriShowProc crPriShowProc%rowtype;
    nParticipantId PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type;
    cRecInfo       WFL_WORKLIST.PRI_REC_DISPLAY%type;   --information pri_rec_id
  begin
    --récupération du participant
    nParticipantId  := PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantId(aUserId => aUserId);

    if nParticipantId is not null then
      --suppression éléments table temporaire
      delete from WFL_WORKLIST;

      --insertion dans la table temporaire
      insert into WFL_WORKLIST
                  (WFL_PROCESSES_ID
                 , WFL_ACTIVITIES_ID
                 , WFL_PROCESS_INSTANCES_ID
                 , WFL_ACTIVITY_INSTANCES_ID
                 , PC_WFL_ACT_PARTICIPANTS_ID
                 , PC_WFL_PROC_PARTICIPANTS_ID
                 , PC_WFL_PERF_PARTICIPANTS_ID
                 , PC_OBJECT_ID
                 , C_WFL_ACTIVITY_STATE
                 , AIN_DATE_STARTED
                 , AIN_DATE_DUE
                 , PFM_ACCEPTED
                 , PRI_TABNAME
                 , PRI_REC_ID
                  )
        select AIN.WFL_PROCESSES_ID
             , AIN.WFL_ACTIVITIES_ID
             , AIN.WFL_PROCESS_INSTANCES_ID
             , AIN.WFL_ACTIVITY_INSTANCES_ID
             , nvl(PFM_DELEG.PC_WFL_PARTICIPANTS_ID, PRI.PC_WFL_PARTICIPANTS_ID) PC_WFL_ACT_PARTICIPANTS_ID
             , PRI.PC_WFL_PARTICIPANTS_ID PC_WFL_PROC_PARTICIPANTS_ID
             , nvl(PFM.PC_WFL_PARTICIPANTS_ID, WFL_WORKFLOW_UTILS.GetActivityParticipant(AIN.WFL_ACTIVITY_INSTANCES_ID) )
                                                                                            PC_WFL_PERF_PARTICIPANTS_ID
             , decode(ACT.C_WFL_ACTIVITY_OBJECT_TYPE
                    , 'SpecObject', ACT.PC_OBJECT_ID
                    , 'TrigObject', PRI.PC_OBJECT_ID
                    , null
                     ) PC_OBJECT_ID
             , AIN.C_WFL_ACTIVITY_STATE
             , AIN.AIN_DATE_STARTED
             , AIN.AIN_DATE_DUE
             , PFM.PFM_ACCEPTED
             , PRI.PRI_TABNAME
             , PRI.PRI_REC_ID
          from WFL_PROCESS_INSTANCES PRI
             , WFL_ACTIVITY_INSTANCES AIN
             , WFL_PERFORMERS PFM
             , WFL_PERFORMERS PFM_DELEG
             ,   -- délégué
               WFL_ACTIVITIES ACT
         where PRI.WFL_PROCESS_INSTANCES_ID = AIN.WFL_PROCESS_INSTANCES_ID
           and PFM.WFL_ACTIVITY_INSTANCES_ID(+) = AIN.WFL_ACTIVITY_INSTANCES_ID
           and PFM.C_WFL_PER_STATE(+) = 'CURRENT'
           and PFM_DELEG.WFL_PERFORMERS_ID(+) = PFM.WFL_PERFORMERS_ID
           and AIN.C_WFL_ACTIVITY_STATE in('NOTRUNNING')
           and AIN.AIN_NEGATION = 0
           and ACT.WFL_ACTIVITIES_ID(+) = AIN.WFL_ACTIVITIES_ID
           and not ((PRI.PC_WFL_PARTICIPANTS_ID = nParticipantId) and (ACT.ACT_PROC_OWNER_AUTH = 0))
           and WFL_WORKFLOW_UTILS.CanPerformActivity(nParticipantId, AIN.WFL_ACTIVITY_INSTANCES_ID) = 1;

      --récupérer au moyen d'un execute immediate l'information à afficher pour le pri_rec_id
      for tplPriShowProc in crPriShowProc loop
        begin
          execute immediate 'select ' || tplPriShowProc.PRI_SHOW_PROC || '(:aId)  from dual'
                       into cRecInfo
                      using tplPriShowProc.PRI_REC_ID;

          --execute immediate 'begin ' || tplPriShowProc.PRI_SHOW_PROC || '(:aId, :aValue); end;'
          --        using in tplPriShowProc.PRI_REC_ID, out cRecInfo;
        exception
          when others then
            cRecInfo  := 'erreur';
        end;

        --mise à jour infos lookup
        update WFL_WORKLIST WOR
           set WOR.PRI_REC_DISPLAY = cRecInfo
         where WOR.WFL_PROCESS_INSTANCES_ID = tplPriShowProc.WFL_PROCESS_INSTANCES_ID
           and WOR.PRI_REC_ID = tplPriShowProc.PRI_REC_ID;
      end loop;

      --insertion dans la table temporaire pc_wfl_worklist
      insert into PCS.PC_WFL_WORKLIST
                  (WFL_PROCESSES_ID
                 , WFL_ACTIVITIES_ID
                 , WFL_PROCESS_INSTANCES_ID
                 , WFL_ACTIVITY_INSTANCES_ID
                 , PC_WFL_ACT_PARTICIPANTS_ID
                 , PC_WFL_PROC_PARTICIPANTS_ID
                 , PC_WFL_PERF_PARTICIPANTS_ID
                 , PC_OBJECT_ID
                 , PC_COMP_ID
                 , PC_SQLST_ID
                 , C_WFL_ACTIVITY_STATE
                 , PRO_NAME
                 , PRO_DESCRIPTION
                 , ACT_NAME
                 , ACT_DESCRIPTION
                 , COM_NAME
                 , SCRDBOWNER
                 , OBJ_NAME
                 , PERF_WPA_NAME
                 , PROC_WPA_NAME
                 , ACT_WPA_NAME
                 , AIN_DATE_STARTED
                 , AIN_DATE_DUE
                 , AIN_VALIDATION_REQUIRED
                 , AIN_GUESTS_AUTHORIZED
                 , AIN_EMAILTO_PARTICIPANTS
                 , AIN_OBJECT_START_REQUIRED
                 , AIN_OBJECT_START_DATE
                 , AIN_OBJECT_STARTED_BY
                 , PRI_TABNAME
                 , PRI_REC_ID
                 , PRI_REC_DISPLAY
                 , PFM_ACCEPTED
                 , C_SQGTYPE
                 , WOR_SQL_TABLE
                 , SQLDBID
                 , SQLID
                 , WOR_INSTANCE_NAME
                 , AIN_TOPIC
                  )
        select WOR.WFL_PROCESSES_ID
             , WOR.WFL_ACTIVITIES_ID
             , WOR.WFL_PROCESS_INSTANCES_ID
             , WOR.WFL_ACTIVITY_INSTANCES_ID
             , WOR.PC_WFL_ACT_PARTICIPANTS_ID
             , WOR.PC_WFL_PROC_PARTICIPANTS_ID
             , WOR.PC_WFL_PERF_PARTICIPANTS_ID
             , WOR.PC_OBJECT_ID
             , COM.PC_COMP_ID
             , SQLST.PC_SQLST_ID
             , WOR.C_WFL_ACTIVITY_STATE
             , PRO.PRO_NAME
             , nvl(PRD.PRD_DESCRIPTION, PRO.PRO_DESCRIPTION)
             , ACT.ACT_NAME
             , nvl(ACD.ACD_DESCRIPTION, ACT.ACT_DESCRIPTION)
             , COM.COM_NAME
             , SCR.SCRDBOWNER
             , OBJ.OBJ_NAME
             , PART_PERF.WPA_NAME
             , PART_PROC.WPA_NAME
             , PART_ACT.WPA_NAME
             , AIN.AIN_DATE_STARTED
             , AIN.AIN_DATE_DUE
             , AIN.AIN_VALIDATION_REQUIRED
             , AIN.AIN_GUESTS_AUTHORIZED
             , AIN.AIN_EMAILTO_PARTICIPANTS
             , AIN.AIN_OBJECT_START_REQUIRED
             , AIN.AIN_OBJECT_START_DATE
             , AIN.AIN_OBJECT_STARTED_BY
             , WOR.PRI_TABNAME
             , WOR.PRI_REC_ID
             , WOR.PRI_REC_DISPLAY
             , WOR.PFM_ACCEPTED
             , SQLST.C_SQGTYPE
             , TBL.TABNAME
             , SQLST.SQLDBID
             , SQLST.SQLID
             , aInstName
             , AIN.AIN_TOPIC
          from WFL_WORKLIST WOR
             , WFL_ACTIVITY_INSTANCES AIN
             , WFL_PROCESSES PRO
             , WFL_PROCESSES_DESCR PRD
             , WFL_ACTIVITIES ACT
             , WFL_ACTIVITIES_DESCR ACD
             , PCS.PC_COMP COM
             , PCS.PC_SCRIP SCR
             , PCS.PC_OBJECT OBJ
             , PCS.PC_WFL_PARTICIPANTS PART_ACT
             , PCS.PC_WFL_PARTICIPANTS PART_PROC
             , PCS.PC_WFL_PARTICIPANTS PART_PERF
             , PCS.PC_SQLST SQLST
             , PCS.PC_TABLE TBL
         where AIN.WFL_ACTIVITY_INSTANCES_ID = WOR.WFL_ACTIVITY_INSTANCES_ID
           and PRO.WFL_PROCESSES_ID = WOR.WFL_PROCESSES_ID
           and PRD.WFL_PROCESSES_ID(+) = PRO.WFL_PROCESSES_ID
           and PRD.PC_LANG_ID(+) = PCS.PC_PUBLIC.GetUserLangId
           and ACT.WFL_ACTIVITIES_ID = WOR.WFL_ACTIVITIES_ID
           and ACD.WFL_ACTIVITIES_ID(+) = ACT.WFL_ACTIVITIES_ID
           and ACD.PC_LANG_ID(+) = PCS.PC_PUBLIC.GetUserLangId
           and COM.PC_COMP_ID = aCompanyId
           and SCR.PC_SCRIP_ID = COM.PC_SCRIP_ID
           and OBJ.PC_OBJECT_ID(+) = WOR.PC_OBJECT_ID
           and PART_ACT.PC_WFL_PARTICIPANTS_ID = WOR.PC_WFL_ACT_PARTICIPANTS_ID
           and PART_PROC.PC_WFL_PARTICIPANTS_ID = WOR.PC_WFL_PROC_PARTICIPANTS_ID
           and PART_PERF.PC_WFL_PARTICIPANTS_ID = WOR.PC_WFL_PERF_PARTICIPANTS_ID
           and SQLST.PC_SQLST_ID(+) = PRO.PC_SQLST_ID
           and TBL.PC_TABLE_ID = SQLST.PC_TABLE_ID;
    end if;
  end GetWorkList;

  /*************** CountWorkListItems ****************************************/
  function CountWorkListItems(aUserId in PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type)
    return pls_integer
  is
    result pls_integer;
  begin
    select count(AIN.WFL_ACTIVITY_INSTANCES_ID)
      into result
      from WFL_ACTIVITY_INSTANCES AIN
         , PCS.PC_WFL_PARTICIPANTS WPA
     where WPA.PC_USER_ID = aUserId
       and AIN.C_WFL_ACTIVITY_STATE = 'NOTRUNNING'
       and AIN.AIN_NEGATION = 0
       and WFL_WORKFLOW_UTILS.CanPerformActivity(WPA.PC_WFL_PARTICIPANTS_ID, AIN.WFL_ACTIVITY_INSTANCES_ID) = 1;

    return result;
  exception
    when no_data_found then
      return 0;
  end CountWorkListItems;

  /*************** GetSuspendedTasks *****************************************/
  procedure GetSuspendedTasks(
    aUserId    in PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  , aCompanyId in PCS.PC_WFL_WORKLIST.PC_COMP_ID%type
  , aInstName  in PCS.PC_WFL_WORKLIST.WOR_INSTANCE_NAME%type
  )
  is
    --curseur qui parcours les éléments de la worklist pour le lookup de pri_rec_id
    cursor crPriShowProc(aCompanyId PCS.PC_WFL_WORKLIST.PC_COMP_ID%type)
    is
      select distinct (PRIN.PRI_SHOW_PROC) PRI_SHOW_PROC
                    , PRIN.WFL_PROCESS_INSTANCES_ID
                    , WAT.PRI_REC_ID
                 from WFL_PROCESS_INSTANCES PRIN
                    , PCS.PC_WFL_WORKLIST WAT
                where PRIN.WFL_PROCESS_INSTANCES_ID = WAT.WFL_PROCESS_INSTANCES_ID
                  and WAT.PC_COMP_ID = aCompanyId;

    tplPriShowProc crPriShowProc%rowtype;
    cRecInfo       WFL_WORKLIST.PRI_REC_DISPLAY%type;   --information pri_rec_id
  begin
    --insertion au moyen d'un select dans PC_WFL_WORKLIST
    insert into PCS.PC_WFL_WORKLIST
                (WFL_PROCESSES_ID
               , WFL_ACTIVITIES_ID
               , WFL_PROCESS_INSTANCES_ID
               , WFL_ACTIVITY_INSTANCES_ID
               , PC_WFL_ACT_PARTICIPANTS_ID
               , PC_WFL_PROC_PARTICIPANTS_ID
               , PC_WFL_PERF_PARTICIPANTS_ID
               , PC_OBJECT_ID
               , PC_COMP_ID
               , PC_SQLST_ID
               , C_WFL_ACTIVITY_STATE
               , PRO_NAME
               , PRO_DESCRIPTION
               , ACT_NAME
               , ACT_DESCRIPTION
               , COM_NAME
               , SCRDBOWNER
               , OBJ_NAME
               , PERF_WPA_NAME
               , PROC_WPA_NAME
               , ACT_WPA_NAME
               , AIN_DATE_STARTED
               , AIN_DATE_DUE
               , AIN_VALIDATION_REQUIRED
               , AIN_GUESTS_AUTHORIZED
               , AIN_EMAILTO_PARTICIPANTS
               , AIN_OBJECT_START_REQUIRED
               , AIN_OBJECT_START_DATE
               , AIN_OBJECT_STARTED_BY
               , PRI_TABNAME
               , PRI_REC_ID
               , PFM_ACCEPTED
               , C_SQGTYPE
               , WOR_SQL_TABLE
               , SQLDBID
               , SQLID
               , WOR_INSTANCE_NAME
               , AIN_TOPIC
                )
      select AIN.WFL_PROCESSES_ID
           , AIN.WFL_ACTIVITIES_ID
           , AIN.WFL_PROCESS_INSTANCES_ID
           , AIN.WFL_ACTIVITY_INSTANCES_ID
           , nvl(PFM_DELEG.PC_WFL_PARTICIPANTS_ID, PRI.PC_WFL_PARTICIPANTS_ID) PC_WFL_ACT_PARTICIPANTS_ID
           , PRI.PC_WFL_PARTICIPANTS_ID PC_WFL_PROC_PARTICIPANTS_ID
           , PFM.PC_WFL_PARTICIPANTS_ID PC_WFL_PERF_PARTICIPANTS_ID
           , decode(ACT.C_WFL_ACTIVITY_OBJECT_TYPE
                  , 'SpecObject', ACT.PC_OBJECT_ID
                  , 'TrigObject', PRI.PC_OBJECT_ID
                  , null
                   )
           , COM.PC_COMP_ID
           , SQLST.PC_SQLST_ID
           , AIN.C_WFL_ACTIVITY_STATE
           , PRO.PRO_NAME
           , nvl(PRD.PRD_DESCRIPTION, PRO.PRO_DESCRIPTION)
           , ACT.ACT_NAME
           , nvl(ACD.ACD_DESCRIPTION, ACT.ACT_DESCRIPTION)
           , COM.COM_NAME
           , SCR.SCRDBOWNER
           , decode(ACT.C_WFL_ACTIVITY_OBJECT_TYPE
                  , 'SpecObject', ACT_OGE.OBJ_NAME
                  , 'TrigObject', PRI_OGE.OBJ_NAME
                  , null
                   ) OBJ_NAME
           , PAR_PFM.WPA_NAME PERF_WPA_NAME
           , PAR_PRI.WPA_NAME PROC_WPA_NAME
           , nvl(PAR_DELEG.WPA_NAME, PAR_PRI.WPA_NAME) ACT_WPA_NAME
           , AIN.AIN_DATE_STARTED
           , AIN.AIN_DATE_DUE
           , AIN.AIN_VALIDATION_REQUIRED
           , AIN.AIN_GUESTS_AUTHORIZED
           , AIN.AIN_EMAILTO_PARTICIPANTS
           , AIN.AIN_OBJECT_START_REQUIRED
           , AIN.AIN_OBJECT_START_DATE
           , AIN.AIN_OBJECT_STARTED_BY
           , PRI.PRI_TABNAME
           , PRI.PRI_REC_ID
           , PFM.PFM_ACCEPTED
           , SQLST.C_SQGTYPE
           , TBL.TABNAME
           , SQLST.SQLDBID
           , SQLST.SQLID
           , aInstName
           , AIN.AIN_TOPIC
        from WFL_ACTIVITY_INSTANCES AIN
           , WFL_PROCESS_INSTANCES PRI
           , WFL_PROCESSES PRO
           , WFL_PROCESSES_DESCR PRD
           , WFL_ACTIVITIES ACT
           , WFL_ACTIVITIES_DESCR ACD
           , WFL_PERFORMERS PFM
           , WFL_PERFORMERS PFM_DELEG
           , PCS.PC_WFL_PARTICIPANTS PAR_PFM
           , PCS.PC_WFL_PARTICIPANTS PAR_DELEG
           , PCS.PC_WFL_PARTICIPANTS PAR_PRI
           , PCS.PC_OBJECT ACT_OGE
           , PCS.PC_OBJECT PRI_OGE
           , PCS.PC_COMP COM
           , PCS.PC_SCRIP SCR
           , PCS.PC_SQLST SQLST
           , PCS.PC_TABLE TBL
       where PRI.WFL_PROCESS_INSTANCES_ID = AIN.WFL_PROCESS_INSTANCES_ID
         and PFM.WFL_ACTIVITY_INSTANCES_ID(+) = AIN.WFL_ACTIVITY_INSTANCES_ID
         and PFM.C_WFL_PER_STATE(+) = 'CURRENT'
         and PFM_DELEG.WFL_PERFORMERS_ID(+) = PFM.WFL_PERFORMERS_ID
         and AIN.C_WFL_ACTIVITY_STATE in('SUSPENDED')
         and ACT.WFL_ACTIVITIES_ID(+) = AIN.WFL_ACTIVITIES_ID
         and PRO.WFL_PROCESSES_ID(+) = AIN.WFL_PROCESSES_ID
         and PAR_PFM.PC_WFL_PARTICIPANTS_ID(+) = PFM.PC_WFL_PARTICIPANTS_ID
         and PAR_PFM.PC_USER_ID = aUserId
         and PAR_DELEG.PC_WFL_PARTICIPANTS_ID(+) = PFM_DELEG.PC_WFL_PARTICIPANTS_ID
         and PAR_PRI.PC_WFL_PARTICIPANTS_ID(+) = PRI.PC_WFL_PARTICIPANTS_ID
         and ACT_OGE.PC_OBJECT_ID(+) = ACT.PC_OBJECT_ID
         and PRI_OGE.PC_OBJECT_ID(+) = PRI.PC_OBJECT_ID
         and PRD.WFL_PROCESSES_ID(+) = AIN.WFL_PROCESSES_ID
         and PRD.PC_LANG_ID(+) = PCS.PC_PUBLIC.GetUserLangId
         and ACD.WFL_ACTIVITIES_ID(+) = AIN.WFL_ACTIVITIES_ID
         and ACD.PC_LANG_ID(+) = PCS.PC_PUBLIC.GetUserLangId
         and COM.PC_COMP_ID = aCompanyId
         and SCR.PC_SCRIP_ID = COM.PC_SCRIP_ID
         and SQLST.PC_SQLST_ID = PRO.PC_SQLST_ID
         and TBL.PC_TABLE_ID = SQLST.PC_TABLE_ID
         and not ((ACT.ACT_PROC_OWNER_AUTH = 0) and (PFM_DELEG.PC_WFL_PARTICIPANTS_ID is null))
         and not ((PFM_DELEG.PC_WFL_PARTICIPANTS_ID = PRI.PC_WFL_PARTICIPANTS_ID) and (ACT.ACT_PROC_OWNER_AUTH = 0));

    --récupérer au moyen d'un execute immediate l'information à afficher pour le pri_rec_id
    for tplPriShowProc in crPriShowProc(aCompanyId => aCompanyId) loop
      begin

        --execute immediate tplPriShowProc.PRI_SHOW_PROC
        --             into cRecInfo
        --            using tplPriShowProc.PRI_REC_ID;

        execute immediate 'select ' || tplPriShowProc.PRI_SHOW_PROC || '(:aId)  from dual'
             into cRecInfo
            using tplPriShowProc.PRI_REC_ID;

      exception
        when others then
          cRecInfo  := '';
      end;

      --mise à jour infos lookup
      update PCS.PC_WFL_WORKLIST WAT
         set WAT.PRI_REC_DISPLAY = cRecInfo
       where WAT.WFL_PROCESS_INSTANCES_ID = tplPriShowProc.WFL_PROCESS_INSTANCES_ID
         and WAT.PRI_REC_ID = tplPriShowProc.PRI_REC_ID
         and WAT.PC_COMP_ID = aCompanyId;
    end loop;
  end;

  /*************** CountSuspendedTasks ***************************************/
  function CountSuspendedTasks(aUserId in PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type)
    return pls_integer
  is
    result pls_integer;
  begin
    select count(AIN.WFL_ACTIVITY_INSTANCES_ID)
      into result
      from WFL_ACTIVITY_INSTANCES AIN
         , WFL_PERFORMERS PFM
         , PCS.PC_WFL_PARTICIPANTS PAR_PFM
     where PFM.WFL_ACTIVITY_INSTANCES_ID = AIN.WFL_ACTIVITY_INSTANCES_ID
       and PFM.C_WFL_PER_STATE = 'CURRENT'
       and AIN.C_WFL_ACTIVITY_STATE in('SUSPENDED')
       and PAR_PFM.PC_WFL_PARTICIPANTS_ID = PFM.PC_WFL_PARTICIPANTS_ID
       and PAR_PFM.PC_USER_ID = aUserId;

    return result;
  exception
    when no_data_found then
      return 0;
  end CountSuspendedTasks;

  /*************** GetActiveTasks ********************************************/
  procedure GetActiveTasks(
    aUserId    in PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  , aCompanyId in PCS.PC_WFL_WORKLIST.PC_COMP_ID%type
  , aInstName  in PCS.PC_WFL_WORKLIST.WOR_INSTANCE_NAME%type
  )
  is
    --curseur qui parcours les éléments de la worklist pour le lookup de pri_rec_id
    cursor crPriShowProc(aCompanyId PCS.PC_WFL_WORKLIST.PC_COMP_ID%type)
    is
      select distinct (PRIN.PRI_SHOW_PROC) PRI_SHOW_PROC
                    , PRIN.WFL_PROCESS_INSTANCES_ID
                    , WAT.PRI_REC_ID
                 from WFL_PROCESS_INSTANCES PRIN
                    , PCS.PC_WFL_WORKLIST WAT
                where PRIN.WFL_PROCESS_INSTANCES_ID = WAT.WFL_PROCESS_INSTANCES_ID
                  and WAT.PC_COMP_ID = aCompanyId;

    tplPriShowProc crPriShowProc%rowtype;
    cRecInfo       WFL_WORKLIST.PRI_REC_DISPLAY%type;   --information pri_rec_id
  begin
    --insertion au moyen d'un select dans PC_WFL_WORKLIST
    insert into PCS.PC_WFL_WORKLIST
                (WFL_PROCESSES_ID
               , WFL_ACTIVITIES_ID
               , WFL_PROCESS_INSTANCES_ID
               , WFL_ACTIVITY_INSTANCES_ID
               , PC_WFL_ACT_PARTICIPANTS_ID
               , PC_WFL_PROC_PARTICIPANTS_ID
               , PC_WFL_PERF_PARTICIPANTS_ID
               , PC_OBJECT_ID
               , PC_COMP_ID
               , PC_SQLST_ID
               , C_WFL_ACTIVITY_STATE
               , PRO_NAME
               , PRO_DESCRIPTION
               , ACT_NAME
               , ACT_DESCRIPTION
               , COM_NAME
               , SCRDBOWNER
               , OBJ_NAME
               , PERF_WPA_NAME
               , PROC_WPA_NAME
               , ACT_WPA_NAME
               , AIN_DATE_STARTED
               , AIN_DATE_DUE
               , AIN_VALIDATION_REQUIRED
               , AIN_GUESTS_AUTHORIZED
               , AIN_EMAILTO_PARTICIPANTS
               , AIN_OBJECT_START_REQUIRED
               , AIN_OBJECT_START_DATE
               , AIN_OBJECT_STARTED_BY
               , PRI_TABNAME
               , PRI_REC_ID
               , PFM_ACCEPTED
               , C_SQGTYPE
               , WOR_SQL_TABLE
               , SQLDBID
               , SQLID
               , WOR_INSTANCE_NAME
               , AIN_TOPIC
                )
      select AIN.WFL_PROCESSES_ID
           , AIN.WFL_ACTIVITIES_ID
           , AIN.WFL_PROCESS_INSTANCES_ID
           , AIN.WFL_ACTIVITY_INSTANCES_ID
           , nvl(PFM_DELEG.PC_WFL_PARTICIPANTS_ID, PRI.PC_WFL_PARTICIPANTS_ID) PC_WFL_ACT_PARTICIPANTS_ID
           , PRI.PC_WFL_PARTICIPANTS_ID PC_WFL_PROC_PARTICIPANTS_ID
           , PFM.PC_WFL_PARTICIPANTS_ID PC_WFL_PERF_PARTICIPANTS_ID
           , decode(ACT.C_WFL_ACTIVITY_OBJECT_TYPE
                  , 'SpecObject', ACT.PC_OBJECT_ID
                  , 'TrigObject', PRI.PC_OBJECT_ID
                  , null
                   )
           , COM.PC_COMP_ID
           , SQLST.PC_SQLST_ID
           , AIN.C_WFL_ACTIVITY_STATE
           , PRO.PRO_NAME
           , nvl(PRD.PRD_DESCRIPTION, PRO.PRO_DESCRIPTION)
           , ACT.ACT_NAME
           , nvl(ACD.ACD_DESCRIPTION, ACT.ACT_DESCRIPTION)
           , COM.COM_NAME
           , SCR.SCRDBOWNER
           , decode(ACT.C_WFL_ACTIVITY_OBJECT_TYPE
                  , 'SpecObject', ACT_OGE.OBJ_NAME
                  , 'TrigObject', PRI_OGE.OBJ_NAME
                  , null
                   ) OBJ_NAME
           , PAR_PFM.WPA_NAME PERF_WPA_NAME
           , PAR_PRI.WPA_NAME PROC_WPA_NAME
           , nvl(PAR_DELEG.WPA_NAME, PAR_PRI.WPA_NAME) ACT_WPA_NAME
           , AIN.AIN_DATE_STARTED
           , AIN.AIN_DATE_DUE
           , AIN.AIN_VALIDATION_REQUIRED
           , AIN.AIN_GUESTS_AUTHORIZED
           , AIN.AIN_EMAILTO_PARTICIPANTS
           , AIN.AIN_OBJECT_START_REQUIRED
           , AIN.AIN_OBJECT_START_DATE
           , AIN.AIN_OBJECT_STARTED_BY
           , PRI.PRI_TABNAME
           , PRI.PRI_REC_ID
           , PFM.PFM_ACCEPTED
           , SQLST.C_SQGTYPE
           , TBL.TABNAME
           , SQLST.SQLDBID
           , SQLST.SQLID
           , aInstName
           , AIN.AIN_TOPIC
        from WFL_ACTIVITY_INSTANCES AIN
           , WFL_PROCESS_INSTANCES PRI
           , WFL_PROCESSES PRO
           , WFL_PROCESSES_DESCR PRD
           , WFL_ACTIVITIES ACT
           , WFL_ACTIVITIES_DESCR ACD
           , WFL_PERFORMERS PFM
           , WFL_PERFORMERS PFM_DELEG
           , PCS.PC_WFL_PARTICIPANTS PAR_PFM
           , PCS.PC_WFL_PARTICIPANTS PAR_DELEG
           , PCS.PC_WFL_PARTICIPANTS PAR_PRI
           , PCS.PC_OBJECT ACT_OGE
           , PCS.PC_OBJECT PRI_OGE
           , PCS.PC_COMP COM
           , PCS.PC_SCRIP SCR
           , PCS.PC_SQLST SQLST
           , PCS.PC_TABLE TBL
       where PRI.WFL_PROCESS_INSTANCES_ID = AIN.WFL_PROCESS_INSTANCES_ID
         and PFM.WFL_ACTIVITY_INSTANCES_ID(+) = AIN.WFL_ACTIVITY_INSTANCES_ID
         and PFM.C_WFL_PER_STATE(+) = 'CURRENT'
         and PFM_DELEG.WFL_PERFORMERS_ID(+) = PFM.WFL_PERFORMERS_ID
         and AIN.C_WFL_ACTIVITY_STATE in('RUNNING', 'TERMINATED')
         and ACT.WFL_ACTIVITIES_ID(+) = AIN.WFL_ACTIVITIES_ID
         and PRO.WFL_PROCESSES_ID(+) = AIN.WFL_PROCESSES_ID
         and PAR_PFM.PC_WFL_PARTICIPANTS_ID(+) = PFM.PC_WFL_PARTICIPANTS_ID
         and PAR_PFM.PC_USER_ID = aUserId
         and PAR_DELEG.PC_WFL_PARTICIPANTS_ID(+) = PFM_DELEG.PC_WFL_PARTICIPANTS_ID
         and PAR_PRI.PC_WFL_PARTICIPANTS_ID(+) = PRI.PC_WFL_PARTICIPANTS_ID
         and ACT_OGE.PC_OBJECT_ID(+) = ACT.PC_OBJECT_ID
         and PRI_OGE.PC_OBJECT_ID(+) = PRI.PC_OBJECT_ID
         and PRD.WFL_PROCESSES_ID(+) = AIN.WFL_PROCESSES_ID
         and PRD.PC_LANG_ID(+) = PCS.PC_PUBLIC.GetUserLangId
         and ACD.WFL_ACTIVITIES_ID(+) = AIN.WFL_ACTIVITIES_ID
         and ACD.PC_LANG_ID(+) = PCS.PC_PUBLIC.GetUserLangId
         and COM.PC_COMP_ID = aCompanyId
         and SCR.PC_SCRIP_ID = COM.PC_SCRIP_ID
         and SQLST.PC_SQLST_ID = PRO.PC_SQLST_ID
         and TBL.PC_TABLE_ID = SQLST.PC_TABLE_ID
         and not ((ACT.ACT_PROC_OWNER_AUTH = 0) and (PFM_DELEG.PC_WFL_PARTICIPANTS_ID is null))
         and not ((PFM_DELEG.PC_WFL_PARTICIPANTS_ID = PRI.PC_WFL_PARTICIPANTS_ID) and (ACT.ACT_PROC_OWNER_AUTH = 0));

    --récupérer au moyen d'un execute immediate l'information à afficher pour le pri_rec_id
    for tplPriShowProc in crPriShowProc(aCompanyId => aCompanyId) loop
      begin

          --execute immediate 'begin ' || tplPriShowProc.PRI_SHOW_PROC || '(:aId, :aValue); end;'
          --        using in tplPriShowProc.PRI_REC_ID, out cRecInfo;
        execute immediate 'select ' || tplPriShowProc.PRI_SHOW_PROC || '(:aId)  from dual'
                     into cRecInfo
                    using tplPriShowProc.PRI_REC_ID;
      exception
        when others then
          cRecInfo  := '';
      end;

      --mise à jour infos lookup
      update PCS.PC_WFL_WORKLIST WAT
         set WAT.PRI_REC_DISPLAY = cRecInfo
       where WAT.WFL_PROCESS_INSTANCES_ID = tplPriShowProc.WFL_PROCESS_INSTANCES_ID
         and WAT.PRI_REC_ID = tplPriShowProc.PRI_REC_ID
         and WAT.PC_COMP_ID = aCompanyId;
    end loop;
  end GetActiveTasks;

  /*************** CountActiveTasks ******************************************/
  function CountActiveTasks(aUserId in PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type)
    return pls_integer
  is
    result pls_integer;
  begin
    select count(AIN.WFL_ACTIVITY_INSTANCES_ID)
      into result
      from WFL_ACTIVITY_INSTANCES AIN
         , WFL_PERFORMERS PFM
         , PCS.PC_WFL_PARTICIPANTS PAR_PFM
     where PFM.WFL_ACTIVITY_INSTANCES_ID = AIN.WFL_ACTIVITY_INSTANCES_ID
       and PFM.C_WFL_PER_STATE = 'CURRENT'
       and AIN.C_WFL_ACTIVITY_STATE in('RUNNING', 'TERMINATED')
       and PAR_PFM.PC_WFL_PARTICIPANTS_ID = PFM.PC_WFL_PARTICIPANTS_ID
       and PAR_PFM.PC_USER_ID = aUserId;

    return result;
  exception
    when no_data_found then
      return 0;
  end CountActiveTasks;

  /*************** GetActiveProcess ******************************************/
  procedure GetActiveProcess(
    aUserId    in PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  , aCompanyId in PCS.PC_WFL_TMP_PROCESSES.PC_COMP_ID%type
  )
  is
    --curseur qui parcours les éléments de la worklist pour le lookup de pri_rec_id
    cursor crPriShowProc(aCompanyId PCS.PC_WFL_WORKLIST.PC_COMP_ID%type)
    is
      select distinct (PRIN.PRI_SHOW_PROC) PRI_SHOW_PROC
                    , PRIN.WFL_PROCESS_INSTANCES_ID
                    , WTP.PRI_REC_ID
                 from WFL_PROCESS_INSTANCES PRIN
                    , PCS.PC_WFL_TMP_PROCESSES WTP
                where PRIN.WFL_PROCESS_INSTANCES_ID = WTP.WFL_PROCESS_INSTANCES_ID
                  and WTP.PC_COMP_ID = aCompanyId;

    tplPriShowProc crPriShowProc%rowtype;
    cRecInfo       WFL_WORKLIST.PRI_REC_DISPLAY%type;   --information pri_rec_id
  begin
    --insertion au moyen d'un select dans PC_WFL_WORKLIST
    insert into PCS.PC_WFL_TMP_PROCESSES
                (WFL_PROCESSES_ID
               , WFL_PROCESS_INSTANCES_ID
               , WFL_ACTIVITY_INSTANCES_ID
               , PC_WFL_PROC_PARTICIPANTS_ID
               , PC_OBJECT_ID
               , PC_COMP_ID
               , PRO_NAME
               , PRO_DESCRIPTION
               , C_WFL_THEME
               , C_WFL_START_MODE
               , C_WFL_PROC_STATUS
               , C_WFL_PROCESS_STATE
               , PRO_AUTHOR
               , PRO_TRIGGERING_CONDITION
               , PRO_VALID_FROM
               , PRO_VALID_TO
               , PRO_VERSION
               , PRI_TABNAME
               , PRI_REC_ID
               , PRI_DATE_CREATED
               , PRI_DATE_STARTED
               , PRI_DATE_ENDED
               , PROC_WPA_NAME
               , COM_NAME
               , SCRDBOWNER
               , OBJ_NAME
               , PRI_ACTIVE_DEBUG
                )
      select PRIN.WFL_PROCESSES_ID
           , PRIN.WFL_PROCESS_INSTANCES_ID
           , PRIN.WFL_ACTIVITY_INSTANCES_ID
           , PRIN.PC_WFL_PARTICIPANTS_ID PC_WFL_PROC_PARTICIPANTS_ID
           , OGE.PC_OBJECT_ID
           , COM.PC_COMP_ID
           , PRO.PRO_NAME
           , nvl(PRD.PRD_DESCRIPTION, PRO.PRO_DESCRIPTION)
           , PRO.C_WFL_THEME
           , PRO.C_WFL_START_MODE
           , PRO.C_WFL_PROC_STATUS
           , PRIN.C_WFL_PROCESS_STATE
           , PRO.PRO_AUTHOR
           , PRO.PRO_TRIGGERING_CONDITION
           , PRO.PRO_VALID_FROM
           , PRO.PRO_VALID_TO
           , PRO.PRO_VERSION
           , PRIN.PRI_TABNAME
           , PRIN.PRI_REC_ID
           , PRIN.PRI_DATE_CREATED
           , PRIN.PRI_DATE_STARTED
           , PRIN.PRI_DATE_ENDED
           , PAR_PROC.WPA_NAME PROC_WPA_NAME
           , COM.COM_NAME
           , SCR.SCRDBOWNER
           , OGE.OBJ_NAME
           , PRIN.PRI_ACTIVE_DEBUG
        from WFL_PROCESS_INSTANCES PRIN
           , WFL_PROCESSES PRO
           , WFL_PROCESSES_DESCR PRD
           , PCS.PC_WFL_PARTICIPANTS PAR_PROC
           , PCS.PC_OBJECT OGE
           , PCS.PC_COMP COM
           , PCS.PC_SCRIP SCR
       where PRO.WFL_PROCESSES_ID = PRIN.WFL_PROCESSES_ID
         and PAR_PROC.PC_WFL_PARTICIPANTS_ID = PRIN.PC_WFL_PARTICIPANTS_ID
         and PAR_PROC.PC_USER_ID = aUserId
         and OGE.PC_OBJECT_ID(+) = PRIN.PC_OBJECT_ID
         and PRD.WFL_PROCESSES_ID(+) = PRIN.WFL_PROCESSES_ID
         and PRD.PC_LANG_ID(+) = PCS.PC_PUBLIC.GetUserLangId
         and COM.PC_COMP_ID = aCompanyId
         and PRO.PRO_NAME <> 'TASKTYPEPROCESS'
         and SCR.PC_SCRIP_ID = COM.PC_SCRIP_ID;

    --récupérer au moyen d'un execute immediate l'information à afficher pour le pri_rec_id
    for tplPriShowProc in crPriShowProc(aCompanyId => aCompanyId) loop
      begin

        --execute immediate tplPriShowProc.PRI_SHOW_PROC
        --             into cRecInfo
        --            using tplPriShowProc.PRI_REC_ID;

        execute immediate 'select ' || tplPriShowProc.PRI_SHOW_PROC || '(:aId)  from dual'
                     into cRecInfo
                    using tplPriShowProc.PRI_REC_ID;
      exception
        when others then
          cRecInfo  := '';
      end;

      --mise à jour infos lookup
      update PCS.PC_WFL_TMP_PROCESSES WTP
         set WTP.PRI_REC_DISPLAY = cRecInfo
       where WTP.WFL_PROCESS_INSTANCES_ID = tplPriShowProc.WFL_PROCESS_INSTANCES_ID
         and WTP.PRI_REC_ID = tplPriShowProc.PRI_REC_ID
         and WTP.PC_COMP_ID = aCompanyId;
    end loop;
  end GetActiveProcess;

  procedure GetActiveProcess(aCompanyId in PCS.PC_WFL_TMP_PROCESSES.PC_COMP_ID%type)
  is
    --curseur qui parcours les éléments de la worklist pour le lookup de pri_rec_id
    cursor crPriShowProc(aCompanyId PCS.PC_WFL_WORKLIST.PC_COMP_ID%type)
    is
      select distinct (PRIN.PRI_SHOW_PROC) PRI_SHOW_PROC
                    , PRIN.WFL_PROCESS_INSTANCES_ID
                    , WTP.PRI_REC_ID
                 from WFL_PROCESS_INSTANCES PRIN
                    , PCS.PC_WFL_TMP_PROCESSES WTP
                where PRIN.WFL_PROCESS_INSTANCES_ID = WTP.WFL_PROCESS_INSTANCES_ID
                  and WTP.PC_COMP_ID = aCompanyId;

    tplPriShowProc crPriShowProc%rowtype;
    cRecInfo       WFL_WORKLIST.PRI_REC_DISPLAY%type;   --information pri_rec_id
  begin
    --insertion au moyen d'un select dans PC_WFL_WORKLIST
    insert into PCS.PC_WFL_TMP_PROCESSES
                (WFL_PROCESSES_ID
               , WFL_PROCESS_INSTANCES_ID
               , WFL_ACTIVITY_INSTANCES_ID
               , PC_WFL_PROC_PARTICIPANTS_ID
               , PC_OBJECT_ID
               , PC_COMP_ID
               , PRO_NAME
               , PRO_DESCRIPTION
               , C_WFL_THEME
               , C_WFL_START_MODE
               , C_WFL_PROC_STATUS
               , C_WFL_PROCESS_STATE
               , PRO_AUTHOR
               , PRO_TRIGGERING_CONDITION
               , PRO_VALID_FROM
               , PRO_VALID_TO
               , PRO_VERSION
               , PRI_TABNAME
               , PRI_REC_ID
               , PRI_DATE_CREATED
               , PRI_DATE_STARTED
               , PRI_DATE_ENDED
               , PROC_WPA_NAME
               , COM_NAME
               , SCRDBOWNER
               , OBJ_NAME
               , PRI_ACTIVE_DEBUG
                )
      select PRIN.WFL_PROCESSES_ID
           , PRIN.WFL_PROCESS_INSTANCES_ID
           , PRIN.WFL_ACTIVITY_INSTANCES_ID
           , PRIN.PC_WFL_PARTICIPANTS_ID PC_WFL_PROC_PARTICIPANTS_ID
           , OGE.PC_OBJECT_ID
           , COM.PC_COMP_ID
           , PRO.PRO_NAME
           , nvl(PRD.PRD_DESCRIPTION, PRO.PRO_DESCRIPTION)
           , PRO.C_WFL_THEME
           , PRO.C_WFL_START_MODE
           , PRO.C_WFL_PROC_STATUS
           , PRIN.C_WFL_PROCESS_STATE
           , PRO.PRO_AUTHOR
           , PRO.PRO_TRIGGERING_CONDITION
           , PRO.PRO_VALID_FROM
           , PRO.PRO_VALID_TO
           , PRO.PRO_VERSION
           , PRIN.PRI_TABNAME
           , PRIN.PRI_REC_ID
           , PRIN.PRI_DATE_CREATED
           , PRIN.PRI_DATE_STARTED
           , PRIN.PRI_DATE_ENDED
           , PAR_PROC.WPA_NAME PROC_WPA_NAME
           , COM.COM_NAME
           , SCR.SCRDBOWNER
           , OGE.OBJ_NAME
           , PRIN.PRI_ACTIVE_DEBUG
        from WFL_PROCESS_INSTANCES PRIN
           , WFL_PROCESSES PRO
           , WFL_PROCESSES_DESCR PRD
           , PCS.PC_WFL_PARTICIPANTS PAR_PROC
           , PCS.PC_OBJECT OGE
           , PCS.PC_COMP COM
           , PCS.PC_SCRIP SCR
       where PRO.WFL_PROCESSES_ID = PRIN.WFL_PROCESSES_ID
         and PAR_PROC.PC_WFL_PARTICIPANTS_ID = PRIN.PC_WFL_PARTICIPANTS_ID
         and OGE.PC_OBJECT_ID(+) = PRIN.PC_OBJECT_ID
         and PRD.WFL_PROCESSES_ID(+) = PRIN.WFL_PROCESSES_ID
         and PRD.PC_LANG_ID(+) = PCS.PC_PUBLIC.GetUserLangId
         and COM.PC_COMP_ID = aCompanyId
         and SCR.PC_SCRIP_ID = COM.PC_SCRIP_ID;

    --récupérer au moyen d'un execute immediate l'information à afficher pour le pri_rec_id
    for tplPriShowProc in crPriShowProc(aCompanyId => aCompanyId) loop
      begin

       -- execute immediate tplPriShowProc.PRI_SHOW_PROC
       --              into cRecInfo
       --             using tplPriShowProc.PRI_REC_ID;

        execute immediate 'select ' || tplPriShowProc.PRI_SHOW_PROC || '(:aId)  from dual'
                     into cRecInfo
                    using tplPriShowProc.PRI_REC_ID;
      exception
        when others then
          cRecInfo  := '';
      end;

      --mise à jour infos lookup
      update PCS.PC_WFL_TMP_PROCESSES WTP
         set WTP.PRI_REC_DISPLAY = cRecInfo
       where WTP.WFL_PROCESS_INSTANCES_ID = tplPriShowProc.WFL_PROCESS_INSTANCES_ID
         and WTP.PRI_REC_ID = tplPriShowProc.PRI_REC_ID
         and WTP.PC_COMP_ID = aCompanyId;
    end loop;
  end GetActiveProcess;

  /*************** GetArchivedProcess ****************************************/
  procedure GetArchivedProcess(
    aUserId    in PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  , aCompanyId in PCS.PC_WFL_TMP_PROCESSES.PC_COMP_ID%type
  )
  is
    --curseur qui parcours les éléments de la worklist pour le lookup de pri_rec_id
    cursor crPriShowProc(aCompanyId PCS.PC_WFL_WORKLIST.PC_COMP_ID%type)
    is
      select distinct (PRIN.PRI_SHOW_PROC) PRI_SHOW_PROC
                    , PRIN.WFL_PROCESS_INST_LOG_ID
                    , WTP.PRI_REC_ID
                 from WFL_PROCESS_INST_LOG PRIN
                    , PCS.PC_WFL_TMP_PROCESSES WTP
                where PRIN.WFL_PROCESS_INST_LOG_ID = WTP.WFL_PROCESS_INSTANCES_ID
                  and WTP.PC_COMP_ID = aCompanyId;

    tplPriShowProc crPriShowProc%rowtype;
    cRecInfo       WFL_WORKLIST.PRI_REC_DISPLAY%type;   --information pri_rec_id
  begin
    --insertion au moyen d'un select dans PC_WFL_WORKLIST
    insert into PCS.PC_WFL_TMP_PROCESSES
                (WFL_PROCESSES_ID
               , WFL_PROCESS_INSTANCES_ID
               , WFL_ACTIVITY_INSTANCES_ID
               , PC_WFL_PROC_PARTICIPANTS_ID
               , PC_OBJECT_ID
               , PC_COMP_ID
               , PRO_NAME
               , PRO_DESCRIPTION
               , C_WFL_THEME
               , C_WFL_START_MODE
               , C_WFL_PROC_STATUS
               , C_WFL_PROCESS_STATE
               , PRO_AUTHOR
               , PRO_TRIGGERING_CONDITION
               , PRO_VALID_FROM
               , PRO_VALID_TO
               , PRO_VERSION
               , PRI_TABNAME
               , PRI_REC_ID
               , PRI_DATE_CREATED
               , PRI_DATE_STARTED
               , PRI_DATE_ENDED
               , PROC_WPA_NAME
               , COM_NAME
               , SCRDBOWNER
               , OBJ_NAME
                )
      select PRIN.WFL_PROCESSES_ID
           , PRIN.WFL_PROCESS_INST_LOG_ID
           , PRIN.WFL_ACTIVITY_INST_LOG_ID
           , PRIN.PC_WFL_PARTICIPANTS_ID PC_WFL_PROC_PARTICIPANTS_ID
           , OGE.PC_OBJECT_ID
           , COM.PC_COMP_ID
           , PRO.PRO_NAME
           , nvl(PRD.PRD_DESCRIPTION, PRO.PRO_DESCRIPTION)
           , PRO.C_WFL_THEME
           , PRO.C_WFL_START_MODE
           , PRO.C_WFL_PROC_STATUS
           , PRIN.C_WFL_PROCESS_STATE
           , PRO.PRO_AUTHOR
           , PRO.PRO_TRIGGERING_CONDITION
           , PRO.PRO_VALID_FROM
           , PRO.PRO_VALID_TO
           , PRO.PRO_VERSION
           , PRIN.PRI_TABNAME
           , PRIN.PRI_REC_ID
           , PRIN.PRI_DATE_CREATED
           , PRIN.PRI_DATE_STARTED
           , PRIN.PRI_DATE_ENDED
           , PAR_PROC.WPA_NAME PROC_WPA_NAME
           , COM.COM_NAME
           , SCR.SCRDBOWNER
           , OGE.OBJ_NAME
        from WFL_PROCESS_INST_LOG PRIN
           , WFL_PROCESSES PRO
           , WFL_PROCESSES_DESCR PRD
           , PCS.PC_WFL_PARTICIPANTS PAR_PROC
           , PCS.PC_OBJECT OGE
           , PCS.PC_COMP COM
           , PCS.PC_SCRIP SCR
       where PRO.WFL_PROCESSES_ID = PRIN.WFL_PROCESSES_ID
         and PAR_PROC.PC_WFL_PARTICIPANTS_ID = PRIN.PC_WFL_PARTICIPANTS_ID
         and PAR_PROC.PC_USER_ID = aUserId
         and OGE.PC_OBJECT_ID(+) = PRIN.PC_OBJECT_ID
         and PRD.WFL_PROCESSES_ID(+) = PRIN.WFL_PROCESSES_ID
         and PRD.PC_LANG_ID(+) = PCS.PC_PUBLIC.GetUserLangId
         and COM.PC_COMP_ID = aCompanyId
         and SCR.PC_SCRIP_ID = COM.PC_SCRIP_ID;

    --récupérer au moyen d'un execute immediate l'information à afficher pour le pri_rec_id
    for tplPriShowProc in crPriShowProc(aCompanyId => aCompanyId) loop
      begin

       -- execute immediate tplPriShowProc.PRI_SHOW_PROC
       --              into cRecInfo
       --             using tplPriShowProc.PRI_REC_ID;

        execute immediate 'select ' || tplPriShowProc.PRI_SHOW_PROC || '(:aId)  from dual'
                     into cRecInfo
                    using tplPriShowProc.PRI_REC_ID;
      exception
        when others then
          cRecInfo  := '';
      end;

      --mise à jour infos lookup
      update PCS.PC_WFL_TMP_PROCESSES WTP
         set WTP.PRI_REC_DISPLAY = cRecInfo
       where WTP.WFL_PROCESS_INSTANCES_ID = tplPriShowProc.WFL_PROCESS_INST_LOG_ID
         and WTP.PRI_REC_ID = tplPriShowProc.PRI_REC_ID
         and WTP.PC_COMP_ID = aCompanyId;
    end loop;
  end GetArchivedProcess;

  procedure GetArchivedProcess(aCompanyId in PCS.PC_WFL_TMP_PROCESSES.PC_COMP_ID%type)
  is
    --curseur qui parcours les éléments de la worklist pour le lookup de pri_rec_id
    cursor crPriShowProc(aCompanyId PCS.PC_WFL_WORKLIST.PC_COMP_ID%type)
    is
      select distinct (PRIN.PRI_SHOW_PROC) PRI_SHOW_PROC
                    , PRIN.WFL_PROCESS_INST_LOG_ID
                    , WTP.PRI_REC_ID
                 from WFL_PROCESS_INST_LOG PRIN
                    , PCS.PC_WFL_TMP_PROCESSES WTP
                where PRIN.WFL_PROCESS_INST_LOG_ID = WTP.WFL_PROCESS_INSTANCES_ID
                  and WTP.PC_COMP_ID = aCompanyId;

    tplPriShowProc crPriShowProc%rowtype;
    cRecInfo       WFL_WORKLIST.PRI_REC_DISPLAY%type;   --information pri_rec_id
  begin
    --insertion au moyen d'un select dans PC_WFL_WORKLIST
    insert into PCS.PC_WFL_TMP_PROCESSES
                (WFL_PROCESSES_ID
               , WFL_PROCESS_INSTANCES_ID
               , WFL_ACTIVITY_INSTANCES_ID
               , PC_WFL_PROC_PARTICIPANTS_ID
               , PC_OBJECT_ID
               , PC_COMP_ID
               , PRO_NAME
               , PRO_DESCRIPTION
               , C_WFL_THEME
               , C_WFL_START_MODE
               , C_WFL_PROC_STATUS
               , C_WFL_PROCESS_STATE
               , PRO_AUTHOR
               , PRO_TRIGGERING_CONDITION
               , PRO_VALID_FROM
               , PRO_VALID_TO
               , PRO_VERSION
               , PRI_TABNAME
               , PRI_REC_ID
               , PRI_DATE_CREATED
               , PRI_DATE_STARTED
               , PRI_DATE_ENDED
               , PROC_WPA_NAME
               , COM_NAME
               , SCRDBOWNER
               , OBJ_NAME
                )
      select PRIN.WFL_PROCESSES_ID
           , PRIN.WFL_PROCESS_INST_LOG_ID
           , PRIN.WFL_ACTIVITY_INST_LOG_ID
           , PRIN.PC_WFL_PARTICIPANTS_ID PC_WFL_PROC_PARTICIPANTS_ID
           , OGE.PC_OBJECT_ID
           , COM.PC_COMP_ID
           , PRO.PRO_NAME
           , nvl(PRD.PRD_DESCRIPTION, PRO.PRO_DESCRIPTION)
           , PRO.C_WFL_THEME
           , PRO.C_WFL_START_MODE
           , PRO.C_WFL_PROC_STATUS
           , PRIN.C_WFL_PROCESS_STATE
           , PRO.PRO_AUTHOR
           , PRO.PRO_TRIGGERING_CONDITION
           , PRO.PRO_VALID_FROM
           , PRO.PRO_VALID_TO
           , PRO.PRO_VERSION
           , PRIN.PRI_TABNAME
           , PRIN.PRI_REC_ID
           , PRIN.PRI_DATE_CREATED
           , PRIN.PRI_DATE_STARTED
           , PRIN.PRI_DATE_ENDED
           , PAR_PROC.WPA_NAME PROC_WPA_NAME
           , COM.COM_NAME
           , SCR.SCRDBOWNER
           , OGE.OBJ_NAME
        from WFL_PROCESS_INST_LOG PRIN
           , WFL_PROCESSES PRO
           , WFL_PROCESSES_DESCR PRD
           , PCS.PC_WFL_PARTICIPANTS PAR_PROC
           , PCS.PC_OBJECT OGE
           , PCS.PC_COMP COM
           , PCS.PC_SCRIP SCR
       where PRO.WFL_PROCESSES_ID = PRIN.WFL_PROCESSES_ID
         and PAR_PROC.PC_WFL_PARTICIPANTS_ID = PRIN.PC_WFL_PARTICIPANTS_ID
         and OGE.PC_OBJECT_ID(+) = PRIN.PC_OBJECT_ID
         and PRD.WFL_PROCESSES_ID(+) = PRIN.WFL_PROCESSES_ID
         and PRD.PC_LANG_ID(+) = PCS.PC_PUBLIC.GetUserLangId
         and COM.PC_COMP_ID = aCompanyId
         and SCR.PC_SCRIP_ID = COM.PC_SCRIP_ID;

    --récupérer au moyen d'un execute immediate l'information à afficher pour le pri_rec_id
    for tplPriShowProc in crPriShowProc(aCompanyId => aCompanyId) loop
      begin

        execute immediate 'select ' || tplPriShowProc.PRI_SHOW_PROC || '(:aId)  from dual'
                     into cRecInfo
                    using tplPriShowProc.PRI_REC_ID;
      exception
        when others then
          cRecInfo  := '';
      end;

      --mise à jour infos lookup
      update PCS.PC_WFL_TMP_PROCESSES WTP
         set WTP.PRI_REC_DISPLAY = cRecInfo
       where WTP.WFL_PROCESS_INSTANCES_ID = tplPriShowProc.WFL_PROCESS_INST_LOG_ID
         and WTP.PRI_REC_ID = tplPriShowProc.PRI_REC_ID
         and WTP.PC_COMP_ID = aCompanyId;
    end loop;
  end GetArchivedProcess;

/*************** CallBeforeStop ********************************************/
  function CallBeforeStopProc(aProcessInstanceId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type)
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    result           WFL_WORKFLOW_TYPES.WFL_BOOLEAN default 1;
    tplProcessEvents crProcessEvents%rowtype;
  begin
    WFL_WORKFLOW_MANAGEMENT.InitLogContext(aSection => 'WFL_WORKFLOW_UTILS : function CallBeforeStopProc');
    WFL_WORKFLOW_MANAGEMENT.DebugLog(aLogText   => 'Start CallBeforeStopProc' ||
                                                   chr(10) ||
                                                   ' params : ' ||
                                                   chr(10) ||
                                                   'aProcessInstanceId  => ' ||
                                                   aProcessInstanceId
                                    );

    for tplProcessEvents in crProcessEvents(aProcessInstanceId => aProcessInstanceId, aEventTiming => EvtTmgBeforeStop) loop
      --on teste si il s'agit d'un mail
      if tplProcessEvents.C_WFL_EVENT_TYPE = EvtTypeMail then
        --envoie du mail et récupération résultat dans Result(si un des éléments = 0 alors result = 0)
        WFL_WORKFLOW_MANAGEMENT.DebugLog(aLogText => 'Do mail process event');
        result  :=
          WFL_EVENTS_FUNCTIONS.EventSendMailProc(aProcessEventId      => tplProcessEvents.WFL_PROCESS_EVENTS_ID
                                               , aProcessInstanceId   => aProcessInstanceId
                                               , aMailProperties      => tplProcessEvents.WPV_EVENT_TYPE_PROPERTIES
                                                ) *
          result;
      elsif tplProcessEvents.C_WFL_EVENT_TYPE = EvtTypePlSql then
        WFL_WORKFLOW_MANAGEMENT.DebugLog(aLogText => 'Do PlSql process event');
        result  :=
          WFL_EVENTS_FUNCTIONS.EventPlSqlProc(aProcessEventId      => tplProcessEvents.WFL_PROCESS_EVENTS_ID
                                            , aProcessInstanceId   => aProcessInstanceId
                                            , aPlSqlProperties     => tplProcessEvents.WPV_EVENT_TYPE_PROPERTIES
                                             ) *
          result;
      end if;
    end loop;

    WFL_WORKFLOW_MANAGEMENT.DebugLog(aLogText => 'End CallBeforeStopProc (result = ' || result || ')');
    return result;
  end CallBeforeStopProc;

  --overload pour activités
  function CallBeforeStopAct(aActivityInstanceId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type)
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    result            WFL_WORKFLOW_TYPES.WFL_BOOLEAN default 1;
    tplActivityEvents crActivityEvents%rowtype;
  begin
    WFL_WORKFLOW_MANAGEMENT.InitLogContext(aSection => 'WFL_WORKFLOW_UTILS : function CallBeforeStopAct');
    WFL_WORKFLOW_MANAGEMENT.DebugLog(aLogText   => 'Start CallBeforeStopAct' ||
                                                   chr(10) ||
                                                   ' params : ' ||
                                                   chr(10) ||
                                                   'aActivityInstanceId => ' ||
                                                   aActivityInstanceId
                                    );

    for tplActivityEvents in crActivityEvents(aActivityInstanceId   => aActivityInstanceId
                                            , aEventTiming          => EvtTmgBeforeStop
                                             ) loop
      if tplActivityEvents.C_WFL_EVENT_TYPE = EvtTypeMail then
        WFL_WORKFLOW_MANAGEMENT.DebugLog(aLogText => 'Do mail process event');
        result  :=
          WFL_EVENTS_FUNCTIONS.EventSendMailAct(aActivityEventId      => tplActivityEvents.WFL_ACTIVITY_EVENTS_ID
                                              , aActivityInstanceId   => aActivityInstanceId
                                              , aMailProperties       => tplActivityEvents.WAV_EVENT_TYPE_PROPERTIES
                                               ) *
          result;
      elsif tplActivityEvents.C_WFL_EVENT_TYPE = EvtTypePlSql then
        WFL_WORKFLOW_MANAGEMENT.DebugLog(aLogText => 'Do PlSql process event');
        result  :=
          WFL_EVENTS_FUNCTIONS.EventPlSqlAct(aActivityEventId      => tplActivityEvents.WFL_ACTIVITY_EVENTS_ID
                                           , aActivityInstanceId   => aActivityInstanceId
                                           , aPlSqlProperties      => tplActivityEvents.WAV_EVENT_TYPE_PROPERTIES
                                            ) *
          result;
      end if;
    end loop;

    WFL_WORKFLOW_MANAGEMENT.DebugLog(aLogText => 'End CallBeforeStopAct (result = ' || result || ')');
    return result;
  end CallBeforeStopAct;

/*************** CallAfterStart ********************************************/
  procedure CallAfterStartProc(aProcessInstanceId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type)
  is
    result           WFL_WORKFLOW_TYPES.WFL_BOOLEAN default 1;
    tplProcessEvents crProcessEvents%rowtype;
  begin
    WFL_WORKFLOW_MANAGEMENT.InitLogContext(aSection => 'WFL_WORKFLOW_UTILS : procedure CallAfterStartProc');
    WFL_WORKFLOW_MANAGEMENT.DebugLog(aLogText   => 'Start CallAfterStartProc' ||
                                                   chr(10) ||
                                                   ' params : ' ||
                                                   chr(10) ||
                                                   'aProcessInstanceId => ' ||
                                                   aProcessInstanceId
                                    );

    for tplProcessEvents in crProcessEvents(aProcessInstanceId => aProcessInstanceId, aEventTiming => EvtTmgAfterStart) loop
      --on teste si il s'agit d'un mail
      if tplProcessEvents.C_WFL_EVENT_TYPE = EvtTypeMail then
        --envoie du mail et récupération résultat dans Result(si un des éléments = 0 alors result = 0)
        WFL_WORKFLOW_MANAGEMENT.DebugLog(aLogText => 'Do mail process event');
        result  :=
          WFL_EVENTS_FUNCTIONS.EventSendMailProc(aProcessEventId      => tplProcessEvents.WFL_PROCESS_EVENTS_ID
                                               , aProcessInstanceId   => aProcessInstanceId
                                               , aMailProperties      => tplProcessEvents.WPV_EVENT_TYPE_PROPERTIES
                                                ) *
          result;
      elsif tplProcessEvents.C_WFL_EVENT_TYPE = EvtTypePlSql then
        WFL_WORKFLOW_MANAGEMENT.DebugLog(aLogText => 'Do PlSql process event');
        result  :=
          WFL_EVENTS_FUNCTIONS.EventPlSqlProc(aProcessEventId      => tplProcessEvents.WFL_PROCESS_EVENTS_ID
                                            , aProcessInstanceId   => aProcessInstanceId
                                            , aPlSqlProperties     => tplProcessEvents.WPV_EVENT_TYPE_PROPERTIES
                                             ) *
          result;

        WFL_WORKFLOW_MANAGEMENT.DebugLog(aLogText => 'Result of EventPlSqlProc ' || to_char (result) );
      end if;
    end loop;

    --return Result;
    WFL_WORKFLOW_MANAGEMENT.DebugLog(aLogText => 'End CallAfterStartProc ' || to_char (result) );
  end CallAfterStartProc;

  --overload pour activités
  procedure CallAfterStartAct(aActivityInstanceId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type)
  is
    result            WFL_WORKFLOW_TYPES.WFL_BOOLEAN default 1;
    tplActivityEvents crActivityEvents%rowtype;
  begin
    WFL_WORKFLOW_MANAGEMENT.InitLogContext(aSection => 'WFL_WORKFLOW_UTILS : procedure CallAfterStartAct');
    WFL_WORKFLOW_MANAGEMENT.DebugLog(aLogText   => 'Start CallAfterStartAct' ||
                                                   chr(10) ||
                                                   ' params : ' ||
                                                   chr(10) ||
                                                   'aActivityInstanceId => ' ||
                                                   aActivityInstanceId
                                    );

    for tplActivityEvents in crActivityEvents(aActivityInstanceId   => aActivityInstanceId
                                            , aEventTiming          => EvtTmgAfterStart
                                             ) loop
      if tplActivityEvents.C_WFL_EVENT_TYPE = EvtTypeMail then
        WFL_WORKFLOW_MANAGEMENT.DebugLog(aLogText => 'Do mail process event');
        result  :=
          WFL_EVENTS_FUNCTIONS.EventSendMailAct(aActivityEventId      => tplActivityEvents.WFL_ACTIVITY_EVENTS_ID
                                              , aActivityInstanceId   => aActivityInstanceId
                                              , aMailProperties       => tplActivityEvents.WAV_EVENT_TYPE_PROPERTIES
                                               ) *
          result;
      elsif tplActivityEvents.C_WFL_EVENT_TYPE = EvtTypePlSql then
        WFL_WORKFLOW_MANAGEMENT.DebugLog(aLogText => 'Do PlSql process event');
        result  :=
          WFL_EVENTS_FUNCTIONS.EventPlSqlAct(aActivityEventId      => tplActivityEvents.WFL_ACTIVITY_EVENTS_ID
                                           , aActivityInstanceId   => aActivityInstanceId
                                           , aPlSqlProperties      => tplActivityEvents.WAV_EVENT_TYPE_PROPERTIES
                                            ) *
          result;
      end if;
    end loop;

    --return Result; pas bloquant on ne retourne pas le résultat ???
    WFL_WORKFLOW_MANAGEMENT.DebugLog(aLogText => 'End CallAfterStartAct');
  end CallAfterStartAct;

 /*************** GetTaskTasks ********************************************/
  procedure GetTaskTasks(
    aUserId    in PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type
  , aCompanyId in PCS.PC_WFL_WORKLIST.PC_COMP_ID%type
  , aInstName  in PCS.PC_WFL_WORKLIST.WOR_INSTANCE_NAME%type
  )
  is
    --curseur qui parcours les éléments de la worklist pour le lookup de pri_rec_id
    cursor crPriShowAct(aCompanyId PCS.PC_WFL_WORKLIST.PC_COMP_ID%type)
    is
      select distinct (ACT.ACT_SHOW_RECORD) ACT_SHOW_RECORD
                    , ACT.WFL_ACTIVITIES_ID
                    , WAT.PRI_REC_ID
                 from WFL_ACTIVITIES ACT
                    , PCS.PC_WFL_WORKLIST WAT
                where ACT.WFL_ACTIVITIES_ID = WAT.WFL_ACTIVITIES_ID
                  and ACT.ACT_TASK = 1
                  and WAT.PC_COMP_ID = aCompanyId;

    tplPriShowAct crPriShowAct%rowtype;
    cRecInfo       WFL_WORKLIST.PRI_REC_DISPLAY%type;   --information pri_rec_id
  begin


    --insertion au moyen d'un select dans PC_WFL_WORKLIST
    --pour les tâches qui sont liés au workflow light
    insert into PCS.PC_WFL_WORKLIST
                (WFL_PROCESSES_ID
               , WFL_ACTIVITIES_ID
               , WFL_PROCESS_INSTANCES_ID
               , WFL_ACTIVITY_INSTANCES_ID
               , PC_WFL_ACT_PARTICIPANTS_ID
               , PC_WFL_PROC_PARTICIPANTS_ID
               , PC_WFL_PERF_PARTICIPANTS_ID
               , PC_OBJECT_ID
               , PC_COMP_ID
               , PC_SQLST_ID
               , C_WFL_ACTIVITY_STATE
               , PRO_NAME
               , PRO_DESCRIPTION
               , ACT_NAME
               , ACT_DESCRIPTION
               , COM_NAME
               , SCRDBOWNER
               , OBJ_NAME
               , PERF_WPA_NAME
               , PROC_WPA_NAME
               , ACT_WPA_NAME
               , AIN_DATE_STARTED
               , AIN_DATE_DUE
               , AIN_VALIDATION_REQUIRED
               , AIN_GUESTS_AUTHORIZED
               , AIN_EMAILTO_PARTICIPANTS
               , AIN_OBJECT_START_REQUIRED
               , AIN_OBJECT_START_DATE
               , AIN_OBJECT_STARTED_BY
               , PRI_TABNAME
               , PRI_REC_ID
               , C_SQGTYPE
               , WOR_SQL_TABLE
               , SQLDBID
               , SQLID
               , WOR_INSTANCE_NAME
               , AIN_TOPIC
                )
      select DISTINCT AIN.WFL_PROCESSES_ID
           , AIN.WFL_ACTIVITIES_ID
           , AIN.WFL_PROCESS_INSTANCES_ID
           , AIN.WFL_ACTIVITY_INSTANCES_ID
           , nvl(AIN.PC_WFL_PARTICIPANTS_ID, wpg.PC_WFL_PARTICIPANTS_ID) PC_WFL_ACT_PARTICIPANTS_ID
           , nvl(AIN.PC_WFL_PARTICIPANTS_ID, wpg.PC_WFL_PARTICIPANTS_ID) PC_WFL_PROC_PARTICIPANTS_ID
           , nvl(AIN.PC_WFL_PARTICIPANTS_ID, wpg.PC_WFL_PARTICIPANTS_ID) PC_WFL_PERF_PARTICIPANTS_ID
           , decode(ACT.C_WFL_ACTIVITY_OBJECT_TYPE
                    , 'SpecObject', ACT.PC_OBJECT_ID
                    , 'TrigAct', AIN.PC_OBJECT_ID
                    , null
                     ) PC_OBJECT_ID
           , COM.PC_COMP_ID
           , SQLST.PC_SQLST_ID
           , AIN.C_WFL_ACTIVITY_STATE
           , PRO.PRO_NAME
           , nvl(PRD.PRD_DESCRIPTION, PRO.PRO_DESCRIPTION)
           , ACT.ACT_NAME
           , nvl(ACD.ACD_DESCRIPTION, ACT.ACT_DESCRIPTION)
           , COM.COM_NAME
           , SCR.SCRDBOWNER
           , decode(ACT.C_WFL_ACTIVITY_OBJECT_TYPE
                    , 'SpecObject', ACT_OGE.OBJ_NAME
                    , 'TrigAct', AIN_OGE.OBJ_NAME
                    , null
                     ) OBJ_NAME
           , PAR.WPA_NAME PERF_WPA_NAME
           , PAR.WPA_NAME PROC_WPA_NAME
           , PAR.WPA_NAME ACT_WPA_NAME
           , AIN.AIN_DATE_STARTED
           , AIN.AIN_DATE_DUE
           , AIN.AIN_VALIDATION_REQUIRED
           , AIN.AIN_GUESTS_AUTHORIZED
           , AIN.AIN_EMAILTO_PARTICIPANTS
           , AIN.AIN_OBJECT_START_REQUIRED
           , AIN.AIN_OBJECT_START_DATE
           , AIN.AIN_OBJECT_STARTED_BY
           , TBL.TABNAME
           , AIN.AIN_RECORD_ID
           , SQLST.C_SQGTYPE
           , TBL.TABNAME
           , SQLST.SQLDBID
           , SQLST.SQLID
           , aInstName
           , AIN.AIN_TOPIC
        from WFL_ACTIVITY_INSTANCES AIN
           , WFL_PROCESS_INSTANCES PRI
           , WFL_PROCESSES PRO
           , WFL_PROCESSES_DESCR PRD
           , WFL_ACTIVITIES ACT
           , WFL_ACTIVITIES_DESCR ACD
           , WFL_TASK_PARTICIPANT_GROUP WPG
           , PCS.PC_WFL_PARTICIPANTS PAR
           , PCS.PC_OBJECT ACT_OGE
           , PCS.PC_OBJECT AIN_OGE
           , PCS.PC_COMP COM
           , PCS.PC_SCRIP SCR
           , PCS.PC_SQLST SQLST
           , PCS.PC_TABLE TBL
       where PRI.WFL_PROCESS_INSTANCES_ID = AIN.WFL_PROCESS_INSTANCES_ID
         and AIN.C_WFL_ACTIVITY_STATE in('RUNNING', 'TERMINATED','NOTRUNNING','SUSPENDED')
         and Act.ACT_TASK = '1'
         and AIN.WFL_ACTIVITIES_ID(+) = ACT.WFL_ACTIVITIES_ID
         and (
              ((AIN.PC_WFL_PARTICIPANTS_ID = PAR.PC_WFL_PARTICIPANTS_ID) and (AIN.C_WFL_ACTIVITY_STATE in('RUNNING', 'TERMINATED','SUSPENDED'))) or
              ((wpg.PC_WFL_PARTICIPANTS_ID = PAR.PC_WFL_PARTICIPANTS_ID) and (AIN.C_WFL_ACTIVITY_STATE = 'NOTRUNNING') )
             )
         and PAR.PC_USER_ID = aUserId
         and PRO.WFL_PROCESSES_ID(+) = AIN.WFL_PROCESSES_ID
         and ACT_OGE.PC_OBJECT_ID(+) = ACT.PC_OBJECT_ID
         and AIN_OGE.PC_OBJECT_ID(+) = AIN.PC_OBJECT_ID
         and PRD.WFL_PROCESSES_ID(+) = AIN.WFL_PROCESSES_ID
         and PRD.PC_LANG_ID(+) = PCS.PC_PUBLIC.GetUserLangId
         and ACD.WFL_ACTIVITIES_ID(+) = AIN.WFL_ACTIVITIES_ID
         and ACD.PC_LANG_ID(+) = PCS.PC_PUBLIC.GetUserLangId
         and COM.PC_COMP_ID = aCompanyId
         and SCR.PC_SCRIP_ID = COM.PC_SCRIP_ID
         and SQLST.PC_SQLST_ID = ACT.PC_SQLST_ID
         and WPG.WFL_ACTIVITY_INSTANCES_ID (+)= AIN.WFL_ACTIVITY_INSTANCES_ID
         and TBL.PC_TABLE_ID = SQLST.PC_TABLE_ID;


    --récupérer au moyen d'un execute immediate l'information à afficher pour le pri_rec_id
    for tplPriShowAct in crPriShowAct(aCompanyId => aCompanyId) loop
      begin
        cRecInfo := WFL_TASK_MANAGEMENT.getFieldValueFromRecord(tplPriShowAct.ACT_SHOW_RECORD,tplPriShowAct.PRI_REC_ID );
      exception
        when others then
          cRecInfo  := '';
      end;

      --mise à jour infos lookup
      update PCS.PC_WFL_WORKLIST WAT
         set WAT.PRI_REC_DISPLAY = cRecInfo
       where WAT.WFL_ACTIVITIES_ID = tplPriShowAct.WFL_ACTIVITIES_ID
         and WAT.PRI_REC_ID = tplPriShowAct.PRI_REC_ID
         and WAT.PC_COMP_ID = aCompanyId;
    end loop;
  end GetTaskTasks;

  procedure CleanSuspendedProcessInstances
  is
  begin
    update WFL_processes pro
       set pro.C_WFL_PROC_STATUS = 'ARCHIVED'
         , pro.A_DATEMOD = sysdate
     where pro.WFL_PROCESSES_ID in
         (
           select DISTINCT pro2.WFL_PROCESSES_ID
            from  WFL_process_instances pri
                , WFL_PROCESSES pro2
            where pro2.WFL_PROCESSES_ID <> pri.WFL_PROCESSES_ID
              and pro2.C_WFL_PROC_STATUS ='SUSPENDED'
              AND pro2.pro_name <> 'TASKTYPEPROCESS'
         );
  end CleanSuspendedProcessInstances;

  procedure TestElementLock(
    aTableName in PCS.PC_TABLE.TABNAME%type
  , aRecordId in WFL_PROCESS_INSTANCES.PRI_REC_ID%type
  , aLock out number
  )
  is
    nLockedElements number;
    nTaskLockedElements number;
  begin
    nLockedElements := 0;
    aLock := 0;

    select count(*)
    into  nLockedElements
    from  wfl_processes pro
        , wfl_process_instances pri
    where pri.PRI_REC_ID = aRecordId
      and pri.WFL_PROCESSES_ID = PRO.WFL_PROCESSES_ID
      and pro.PRO_REC_LOCK_ENABLED = 1
      and pro.PRO_TABNAME = aTableName
      and pro.PRO_NAME <>'TASKTYPEPROCESS';

    select count(*)
    into  nTaskLockedElements
    from wfl_activities act
        , wfl_activity_instances ain
        , wfl_Activity_obj_auth aob
        , pcs.pc_object obj
        , pcs.pc_basic_object oba
        , pcs.pc_table tab
    where ain.AIN_RECORD_ID = aRecordId
      and ((ain.C_WFL_ACTIVITY_STATE = 'RUNNING') or (ain.C_WFL_ACTIVITY_STATE = 'SUSPENDED'))
      and ain.wfl_activities_id = act.wfl_activities_id
      and act.wfl_activities_id = aob.wfl_activities_id
      and act.ACT_TASK = 1
      and aob.pc_object_id = obj.pc_object_id
      and obj.pc_basic_object_id = oba.pc_basic_object_id
      and oba.pc_table_id = tab.pc_table_id
      and tab.tabname = aTableName;

   nLockedElements := nLockedElements + nTaskLockedElements;

   -- In case the procedures above don't function in some cases (where aTableName is empty)
   -- , then the use of the research by recordId, without the table name, should be used.
   -- However this solution is not used currently, because the principle that each id is unique in
   -- a schema cannot be guaranted. (i.e. someone create a new record without using proconcept procedures)
   --
   --
   -- if nLockedElements = 0 then
   --
   --      select count(*)
   --      into  nLockedElements
   --      from  wfl_processes pro
   --          , wfl_process_instances pri
   --      where pri.PRI_REC_ID = aRecordId
   --        and pri.WFL_PROCESSES_ID = PRO.WFL_PROCESSES_ID
   --        and pro.PRO_REC_LOCK_ENABLED = 1
   --        and pro.PRO_NAME <>'TASKTYPEPROCESS';
   --
   --      select count(*)
   --      into  nTaskLockedElements
   --      from wfl_activities act
   --          , wfl_activity_instances ain
   --      where ain.AIN_RECORD_ID = aRecordId
   --        and ((ain.C_WFL_ACTIVITY_STATE = 'RUNNING') or (ain.C_WFL_ACTIVITY_STATE = 'SUSPENDED') or (ain.C_WFL_ACTIVITY_STATE = 'NOTRUNNING'))
   --        and ain.wfl_activities_id = act.wfl_activities_id
   --        and act.ACT_TASK = 1;
   --
   --      nLockedElements := nLockedElements + nTaskLockedElements;
   --
   --   end if;

    if nLockedElements > 0 then
      aLock := 1;
    end if;

  end TestElementLock;
end WFL_WORKFLOW_UTILS;
