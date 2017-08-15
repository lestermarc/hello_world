--------------------------------------------------------
--  DDL for Package Body WFL_WORKFLOW_MANAGEMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WFL_WORKFLOW_MANAGEMENT" 
is
  -- declare AutoCommit Boolean True;

  /** Défini si il faut logger les opération dans une table de debug (désactivé) */
  FLogging                     boolean                            default false;
  /** Défini si il faut archiver les instances de process */
  FArchive                     boolean                            default true;
  /** Contient le résultat précédent de la requête pour récupérer le SysTimeStamp */
  FPreviousLogCallTime         number(15, 6);
  /** Indique qu'il faut terminer le process si il n'y a aucune condition ?*/
  FNoConditionsCompleteProcess boolean                            default true;
  /** Commande sql pour récupérer la date limite (deadline) (30000 dans code original pour longueur) */
  FSqlQuery                    varchar2(30000);
  /** Contexte pour log */
  GLogCTX                      PCS.PC_LOG_DEBUG_FUNCTIONS.LOG_CTX
    := PCS.PC_LOG_DEBUG_FUNCTIONS.Init(pLOG_TABNAME   => 'WFL_PROCESS_INSTANCES'
                                     , pLEVEL         => PCS.PC_LOG_DEBUG_FUNCTIONS.LALL
                                      );

/*********************** SetLogging **************************************/
  procedure SetLogging(aLogging in boolean)
  is
  begin
    WFL_WORKFLOW_MANAGEMENT.FLogging  := aLogging;
  end SetLogging;

/*********************** SetArchive ****************************************/
  procedure SetArchive(aArchive in boolean)
  is
  begin
    WFL_WORKFLOW_MANAGEMENT.FArchive  := aArchive;
  end SetArchive;

  /*********************** InitLogContext ************************************/
  procedure InitLogContext(
    aSection  in PCS.PC_LOG_DEBUG.LOG_SECTION%type
  , aRecordId in PCS.PC_LOG_DEBUG.LOG_RECORD_ID%type default null
  )
  is
  begin
    --initialisation texte section
    GLogCTX.LOG_SECTION  := aSection;

    if     (aRecordId is not null)
       and (aRecordId > 0) then
      GLogCTX.LOG_RECORD_ID  := aRecordId;
    end if;
  end InitLogContext;

/*********************** DebugLog ******************************************/
  procedure DebugLog(
    aLogText  in PCS.PC_LOG_DEBUG.LOG_TEXTE%type
  , aLogLevel in PCS.PC_LOG_DEBUG.PC_LOG_DEBUG_LEVEL_ID%type default PCS.PC_LOG_DEBUG_FUNCTIONS.LINFO
  )
  is
  begin
    if FLogging then
      PCS.PC_LOG_DEBUG_FUNCTIONS.log(pCTX => GLogCTX, pLEVEL => aLogLevel, pTEXTE => aLogText);
    end if;
  end DebugLog;

  /********************** Internal CreateActivityInstance ********************/
  procedure CreateActivityInstance(
    aProcessInstanceId  in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  , aProcessId          in WFL_PROCESSES.WFL_PROCESSES_ID%type
  , aActivityId         in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  , aActivityInstanceId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type default null
  )
  is
    -- récupération du modèle des activités
    cursor crActivity(
      aProcessId  in WFL_PROCESSES.WFL_PROCESSES_ID%type
    , aActivityId in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
    )
    is
      select ACT.WFL_PROCESSES_ID
           , ACT.WFL_ACTIVITIES_ID
           , ACT.WFL_APPLICATIONS_ID
           , ACT.ACT_CREATE_DELAY_EXPR
           , ACT.ACT_START_MODE
           , ACT.ACT_FINISH_MODE
           , ACT.C_WFL_ACT_IMPLEMENTATION
           , ACT.WFL_HAS_SUBFLOW_PROCESSES_ID
           , ACT.C_WFL_SUBFLOW_EXECUTION
           , APP.APP_PLSQL_PROC_NAME
           , ACT.ACT_WORKLIST_DISPLAY_QUERY
           , ACT.C_WFL_ACT_PART_TYPE
           , ACT.ACT_ASSIGN_TO
           , ACT.ACT_PART_QUERY
           , ACT.ACT_PART_EXCLUDE_QUERY
           , ACT.ACT_ASSIGN_ID
           , ACT.ACT_PART_FUNCTION
           , ACT.ACT_VALIDATION_REQUIRED
           , ACT.ACT_GUESTS_AUTHORIZED
           , ACT.ACT_EMAILTO_PARTICIPANTS
           , ACT.ACT_OBJECT_START_REQUIRED
           , nvl( (select ACT2.ACT_NAME
                     from WFL_ACTIVITIES ACT2
                    where ACT2.WFL_ACTIVITIES_ID = ACT.ACT_ASSIGN_ID), '') ACT_ASSIGN_NAME
        from WFL_ACTIVITIES ACT
           , WFL_APPLICATIONS APP
       where ACT.WFL_APPLICATIONS_ID = APP.WFL_APPLICATIONS_ID(+)
         and ACT.WFL_PROCESSES_ID = aProcessId
         and ACT.WFL_ACTIVITIES_ID = aActivityId;

    tplActivity      crActivity%rowtype;

    -- récupération des conditions de date limites
    cursor crDeadline(
      aProcessId  in WFL_PROCESSES.WFL_PROCESSES_ID%type
    , aActivityId in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
    )
    is
      select DEA.WFL_DEADLINES_ID
           , DEA.C_WFL_DEADLINE_EXECUTION
           , DEA.DEA_CONDITION
           , DEA.DEA_EXCEPTION_NAME
        from WFL_DEADLINES DEA
       where DEA.WFL_PROCESSES_ID = aProcessId
         and DEA.WFL_ACTIVITIES_ID = aActivityId;

    tplDeadline      crDeadline%rowtype;
    nDueDays         number(15, 5);
    nDueDaysLowest   number(15, 5);
    nDeadlineId      WFL_DEADLINES.WFL_DEADLINES_ID%type;
    nPerfPartId      PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type;   --assigned person id, (if any)
    nAssignedPartId  PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type;   --assigned participant id, (if any)
    nAllowPartId     PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type;   --allowed human participant id, (if any)
    nExcludePartId   PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type;   --unallowed human participant id, (if any)
    nJobOut          binary_integer;
    nCreateDelayExpr number(15, 5)                                         default 0;
    cActivityId      varchar(150);
    cProcName        WFL_PROCESSES.PRO_NAME%type;
    cOldSection      PCS.PC_LOG_DEBUG.LOG_SECTION%type;
    oActInfo         WFL_WORKFLOW_TYPES.TWFLACTIVITY_INFO;
  begin
    --récupération identifiant activité, processus
    select ACT_NAME || ' [' || WFL_ACTIVITIES_ID || ']'
      into cActivityId
      from WFL_ACTIVITIES
     where WFL_ACTIVITIES_ID = aActivityId;

    select PRO_NAME
      into cProcName
      from WFL_PROCESSES
     where WFL_PROCESSES_ID = aProcessId;

    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection    => 'WFL_WORKFLOW_MANAGEMENT : procedure CreateActivityInstance'
                 , aRecordId   => aProcessInstanceId
                  );
    DebugLog(aLogText   => 'Start' ||
                           chr(10) ||
                           ' params : ' ||
                           chr(10) ||
                           'aProcessInstanceId  => ' ||
                           aProcessInstanceId ||
                           chr(10) ||
                           'aProcessId          => ' ||
                           aProcessId ||
                           chr(10) ||
                           'aActivityId         => ' ||
                           aActivityId ||
                           chr(10) ||
                           'aActivityInstanceId => ' ||
                           aActivityInstanceId
            );

    -- procédure interne pour créer une instance d'activité, si il s'agit d'une procédure plsql,
    -- alors appelle la procédure ou lance un job si il y a un délai pour le démarrage.
    open crActivity(aProcessId => aProcessId, aActivityId => aActivityId);

    fetch crActivity
     into tplActivity;

    --excution des requêtes du participant
    if (tplActivity.ACT_PART_QUERY is not null) then
      begin
        DebugLog(aLogText => 'About to convert to number ACT_PART_QUERY : ' || tplActivity.ACT_PART_QUERY);
        --on teste si il s'agit d'un participant et non d'une requête
        nAllowPartId  := to_number(tplActivity.ACT_PART_QUERY);
        DebugLog(aLogText   => 'Result is : participant ' ||
                               PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantName(aParticipantId => nAllowPartId) ||
                               ' [' ||
                               nAllowPartId ||
                               '] is allowed to perform activity ' ||
                               cActivityId
                );
      exception
        when others then
          begin
            DebugLog(aLogText   => 'About to execute SQL statement (ACT_PART_QUERY) ''' ||
                                   tplActivity.ACT_PART_QUERY ||
                                   ''' using ' ||
                                   aProcessInstanceId
                    );

            --il peut s'agit d'une erreur de formatage de nombre, soit c'est une vrai requête
            execute immediate tplActivity.ACT_PART_QUERY
                         into nAllowPartId
                        using aProcessInstanceId;

            DebugLog(aLogText   => 'Result is : participant ' ||
                                   PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantName
                                                                                      (aParticipantId   => nAllowPartId) ||
                                   ' [' ||
                                   nAllowPartId ||
                                   '] is allowed to perform activity ' ||
                                   cActivityId
                    );
          exception
            when no_data_found then
              DebugLog(aLogText   => 'The participant query for activity ' || cActivityId
                                     || ' didn''t return a result.');
              nAllowPartId  := null;
            when others then
              raise;
          end;
      end;
    end if;

    if (tplActivity.ACT_PART_EXCLUDE_QUERY is not null) then
      begin
        DebugLog(aLogText   => 'About to execute SQL statement (ACT_PART_EXCLUDE_QUERY)) ''' ||
                               tplActivity.ACT_PART_EXCLUDE_QUERY ||
                               ''' using ' ||
                               aProcessInstanceId
                );

        execute immediate tplActivity.ACT_PART_EXCLUDE_QUERY
                     into nExcludePartId
                    using aProcessInstanceId;

        DebugLog(aLogText   => 'Result is : participant ' ||
                               PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantName(aParticipantId   => nExcludePartId) ||
                               ' [' ||
                               nExcludePartId ||
                               '] is not allowed to perform activity ' ||
                               cActivityId
                );
      exception
        when no_data_found then
          DebugLog(aLogText   => 'The participant exclude query for activity' ||
                                 cActivityId ||
                                 ' didn''t return a result.'
                  );
          nExcludePartId  := null;
        when others then
          raise;
      end;
    end if;

    --si il l'utilisateur responsable est une personne alors utiliser ce user pour créer les instances d'activité
    nPerfPartId          := null;

    if PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.ParticipantIsType(nAllowPartId, 'HUMAN') then
      nPerfPartId  := nAllowPartId;
      DebugLog(aLogText   => 'Assigning performer of activity ' ||
                             cActivityId ||
                             ' with participant ' ||
                             PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantName(aParticipantId => nAllowPartId) ||
                             ' [' ||
                             nAllowPartId ||
                             ']'
              );
    end if;

    if (tplActivity.C_WFL_ACT_PART_TYPE = 'ACT_PERF') then
      --Recherche du participant ayant effectué une activité avant
      begin
        DebugLog(aLogText   => 'About to search activity performer of activity ' ||
                               tplActivity.ACT_ASSIGN_NAME ||
                               ' [' ||
                               tplActivity.ACT_ASSIGN_ID ||
                               ']'
                );

        select PFM.PC_WFL_PARTICIPANTS_ID
          into nAssignedPartId
          from WFL_PERFORMERS PFM
         where C_WFL_PER_STATE = 'CURRENT'
           and WFL_ACTIVITY_INSTANCES_ID =
                 (select max(AIN.WFL_ACTIVITY_INSTANCES_ID)
                    from WFL_ACTIVITY_INSTANCES AIN
                   where AIN.WFL_PROCESSES_ID = tplActivity.WFL_PROCESSES_ID
                     and AIN.WFL_ACTIVITIES_ID = tplActivity.ACT_ASSIGN_ID
                     and AIN.WFL_PROCESS_INSTANCES_ID = aProcessInstanceId);

        DebugLog(aLogText   => 'Result is : participant ' ||
                               PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantName
                                                                                   (aParticipantId   => nAssignedPartId) ||
                               ' [' ||
                               nAssignedPartId ||
                               '] is assigned to perform activity ' ||
                               cActivityId
                );
      exception
        when no_data_found then
          DebugLog(aLogText => 'The ''assign_to'' query for activity ' || cActivityId || ' didn''t return a result.');
          nAssignedPartId  := null;
        when others then
          raise;
      end;
    elsif(tplActivity.C_WFL_ACT_PART_TYPE = 'PROC_OWNER') then
      --participant ayant initialisé le processus
      DebugLog(aLogText   => 'About to search process participant owner of process ' ||
                             cProcName ||
                             ' [' ||
                             aProcessInstanceId ||
                             ']'
              );

      select PRIN.PC_WFL_PARTICIPANTS_ID
        into nAssignedPartId
        from WFL_PROCESS_INSTANCES PRIN
       where PRIN.WFL_PROCESS_INSTANCES_ID = aProcessInstanceId;

      DebugLog(aLogText   => 'Result is : participant ' ||
                             PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantName(aParticipantId => nAssignedPartId) ||
                             ' [' ||
                             nAssignedPartId ||
                             '] is assigned to perform activity ' ||
                             cActivityId
              );
    elsif(tplActivity.C_WFL_ACT_PART_TYPE = 'PART_PLSQL') then
      --participant dynamique récupérer le nom de la fonction appelée et execute immediate => nAssignedPartId -> except := null params ??? ActivityInstanceId => ...
      begin
        DebugLog(aLogText   => 'About to execute SQL statement (ACT_PART_QUERY) ' ||
                               tplActivity.ACT_PART_QUERY ||
                               ' using ' ||
                               nAssignedPartId
                );

        execute immediate 'select
            ' ||          tplActivity.ACT_PART_QUERY || '
             from dual'
                     into nAssignedPartId;

        DebugLog(aLogText   => 'Result is : participant ' ||
                               PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantName
                                                                                   (aParticipantId   => nAssignedPartId) ||
                               ' [' ||
                               nAssignedPartId ||
                               '] is assigned to perform activity ' ||
                               cActivityId
                );
      exception
        when others then
          nAssignedPartId  := null;
      end;
    end if;

    --teste si le participant exclu n'est pas égal à celui autorisé/assigné et si il s'agit d'une personne
    if (nExcludePartId is not null) then
      if not PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.ParticipantIsType(nExcludePartId, 'HUMAN') then
        DebugLog(aLogText    => 'The excluded participant for activity ' || cActivityId || ' is not a HUMAN participant'
               , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
                );
        Raise_Application_Error(-20123
                              , 'The excluded participant for activity ' || cActivityId || ' is not a HUMAN participant'
                               );
      end if;

      if (nExcludePartId = nAssignedPartId) then
        DebugLog(aLogText    => 'The excluded participant for activity ' ||
                                cActivityId ||
                                ' equals the assigned participant'
               , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
                );
        Raise_Application_Error(-20124
                              , 'The excluded participant for activity ' ||
                                cActivityId ||
                                'equals the assigned participant'
                               );
      end if;

      if (nExcludePartId = nPerfPartId) then
        DebugLog(aLogText    => 'The excluded participant for activity ' ||
                                cActivityId ||
                                ' equals the allowed participant'
               , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
                );
        Raise_Application_Error(-20125
                              , 'The excluded participant for activity ' ||
                                cActivityId ||
                                'equals the allowed participant'
                               );
      end if;
    end if;

    -- test pour voir si on a à faire a un subflow, alors l'identifiant du sous-process doit être non null
    if (tplActivity.C_WFL_ACT_IMPLEMENTATION = 'SUBFLOW') then
      if (tplActivity.WFL_HAS_SUBFLOW_PROCESSES_ID is null) then
        DebugLog(aLogText    => 'Activity ' ||
                                cActivityId ||
                                ' has implementation ''SUBFLOW'' but no sub process id is specified.'
               , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
                );
        Raise_Application_Error(-20122
                              , 'Activity ' ||
                                cActivityId ||
                                ' has implementation ''SUBFLOW'' but no sub process id is specified.'
                               );
      end if;
    end if;

    --récupération des dates limites
    for tplDeadline in crDeadline(aProcessId, aActivityId) loop
      --vérification des expressions de conditions de deadlines
      FSqlQuery  :=
        'select ' ||
        tplDeadline.DEA_CONDITION ||
        ' from WFL_PROCESS_INSTANCES
         where WFL_PROCESS_INSTANCES_ID = :PROC_INST_ID ';
      DebugLog(aLogText   => 'About to execute SQL statement (DEADLINE_QUERY) ' ||
                             FSqlQuery ||
                             ' using ' ||
                             aProcessInstanceId
              );

      execute immediate FSqlQuery
                   into nDueDays
                  using aProcessInstanceId;

      if    (nDueDaysLowest is null)
         or (nDueDaysLowest > nDueDays) then
        nDueDaysLowest  := nDueDays;
        nDeadlineId     := tplDeadline.WFL_DEADLINES_ID;
      end if;
    end loop;

    -- évaluation de l'expression du delai pour création
    if (tplActivity.ACT_CREATE_DELAY_EXPR is not null) then
      if     (tplActivity.C_WFL_ACT_IMPLEMENTATION = 'NO')
         and (tplActivity.ACT_START_MODE = 'MANUAL') then
        FSqlQuery  :=
          'select ' ||
          tplActivity.ACT_CREATE_DELAY_EXPR ||
          ' from  WFL_PROCESS_INSTANCES
           where WFL_PROCESS_INSTANCES_ID = :PROC_INST_ID';
        DebugLog(aLogText   => 'About to execute SQL statement (ACT_CREATE_DELAY_EXPR) ' ||
                               FSqlQuery ||
                               ' using ' ||
                               aProcessInstanceId
                );

        execute immediate FSqlQuery
                     into nCreateDelayExpr
                    using aProcessInstanceId;

        --Si la requête ne trouve rien, pas d'exception renvoyé du type no_data_found, donc il faut mettre le délai à jour en conséquence
        if (nCreateDelayExpr is null) then
          nCreateDelayExpr  := 0;
        end if;

        DebugLog(aLogText => 'Result is delay of : ' || nCreateDelayExpr || ' for activity ' || cActivityId);
      else
        DebugLog(aLogText    => 'Activity ' ||
                                cActivityId ||
                                ' has delay_expression "' ||
                                tplActivity.ACT_CREATE_DELAY_EXPR ||
                                '" but is not a ''MANUAL'' activity with ''NO'' implementation, it is ' ||
                                tplActivity.ACT_START_MODE ||
                                ',' ||
                                tplActivity.C_WFL_ACT_IMPLEMENTATION
               , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
                );
        Raise_Application_Error
                               (-20122
                              , 'Activity ' ||
                                cActivityId ||
                                ' has delay_expression "' ||
                                tplActivity.ACT_CREATE_DELAY_EXPR ||
                                '",
             but is not a ''MANUAL'' activity with ''NO'' implementation, it is ' ||
                                tplActivity.ACT_START_MODE ||
                                ',' ||
                                tplActivity.C_WFL_ACT_IMPLEMENTATION ||
                                ')'
                               );
      --**NB: If you need automatic activities to start in the future,
      --      then you have to change the source, e.g. give delayed activities
      --      a special state and adapt check_deadlines to check for those
      --      activities that have reached their start_date and start them then.
      --The construction with Oracle Jobs has been removed,
      --because jobs cannot be replicated and stored.
      end if;
    end if;

    --création de l'instance d'activité
    WFL_WORKFLOW_MANAGEMENT.InstantiateActivityInstance(aProcessInstanceId      => aProcessInstanceId
                                                      , aProcessId              => aProcessId
                                                      , aActivityId             => aActivityId
                                                      , aPerfParticipantId      => nPerfPartId
                                                      , aApplicationId          => tplActivity.WFL_APPLICATIONS_ID
                                                      , aPlsqlProcName          => tplActivity.APP_PLSQL_PROC_NAME
                                                      , aDeadlineId             => nDeadlineId
                                                      , aDaysDue                => nDueDaysLowest
                                                      , aSubflowProcId          => tplActivity.WFL_HAS_SUBFLOW_PROCESSES_ID
                                                      , aSubflowExecution       => tplActivity.C_WFL_SUBFLOW_EXECUTION
                                                      , aImplementation         => tplActivity.C_WFL_ACT_IMPLEMENTATION
                                                      , aStartMode              => tplActivity.ACT_START_MODE
                                                      , aFinishMode             => tplActivity.ACT_FINISH_MODE
                                                      , aAssignParticipantId    => nAssignedPartId
                                                      , aDateCreated            => sysdate + to_number(nCreateDelayExpr)
                                                      , aActivityInstanceId     => aActivityInstanceId
                                                      , aActParticipantId       => nAllowPartId
                                                      , aExcludeParticipantId   => nExcludePartId
                                                      , aValidationRequired     => tplActivity.ACT_VALIDATION_REQUIRED
                                                      , aGuestAuthorized        => tplActivity.ACT_GUESTS_AUTHORIZED
                                                      , aEmailToParticipants    => tplActivity.ACT_EMAILTO_PARTICIPANTS
                                                      , aObjectStartRequired    => tplActivity.ACT_OBJECT_START_REQUIRED
                                                       );

    close crActivity;

    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
  end CreateActivityInstance;

  /********************** Internal AssignActAttrib ***************************/
  procedure AssignActAttrib(
    aProcessId         in WFL_PROCESSES.WFL_PROCESSES_ID%type
  , aActivityId        in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  , aProcessInstanceId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  , aApplicationId     in WFL_APPLICATIONS.WFL_APPLICATIONS_ID%type
  )
  is
    nCnt        number;
    cOldSection PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection => 'WFL_WORKFLOW_MANAGEMENT : procedure AssignActAttrib', aRecordId => aProcessInstanceId);
    DebugLog(aLogText   => 'Start' ||
                           chr(10) ||
                           ' params : ' ||
                           chr(10) ||
                           'aProcessId          => ' ||
                           aProcessId ||
                           chr(10) ||
                           'aActivityId         => ' ||
                           aActivityId ||
                           chr(10) ||
                           'aProcessInstanceId  => ' ||
                           aProcessInstanceId ||
                           chr(10) ||
                           'aApplicationId      => ' ||
                           aApplicationId
            );
    --'copie' paramètres out resultants de outparm_tab vers les instances d'attributs du flux
    nCnt                 := 1;

    for tplAttrib in (select   ATT.ATT_NAME
                             , FPA.C_WFL_PARAM_MODE
                             , FPA.WFL_FORMAL_PARAMETERS_ID
                          from WFL_FORMAL_PARAMETERS FPA
                             , WFL_ACTUAL_PARAMETERS APA
                             , WFL_ATTRIBUTES ATT
                         where APA.WFL_PROCESSES_ID = aProcessId
                           and APA.WFL_ACTIVITIES_ID = aActivityId
                           and APA.WFL_FORMAL_PARAMETERS_ID = FPA.WFL_FORMAL_PARAMETERS_ID
                           and FPA.WFL_APPLICATIONS_ID = aApplicationId
                           and APA.WFL_ATTRIBUTES_ID = ATT.WFL_ATTRIBUTES_ID(+)
                      order by FPA.FPA_INDEX asc
                             , FPA.WFL_FORMAL_PARAMETERS_ID asc) loop
      if (tplAttrib.C_WFL_PARAM_MODE like '%OUT') then
        DebugLog(aLogText => 'Assigning OutParameter ' || nCnt || ' to attribute ' || tplAttrib.ATT_NAME);
        WFL_WORKFLOW_MANAGEMENT.AssignProcessInstanceAttribute
                                                       (aProcessInstanceId   => aProcessInstanceId
                                                      , aAttributeName       => tplAttrib.ATT_NAME
                                                      , aAttributeValue      => WFL_WORKFLOW_MANAGEMENT.OutParamTable
                                                                                                                   (nCnt)
                                                       );
      end if;

      nCnt  := nCnt + 1;
    end loop;

    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
  end AssignActAttrib;

  /*************** Internal GetActAutoPerformer ******************************/
  function GetActAutoPerformer(aActivityInstanceId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type)
    return WFL_ACTIVITIES.PC_WFL_PARTICIPANTS_ID%type
  is
    result       WFL_ACTIVITIES.PC_WFL_PARTICIPANTS_ID%type
                                                          default PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.WorkflowParticipant;
    nProcInstId  WFL_ACTIVITY_INSTANCES.WFL_PROCESS_INSTANCES_ID%type;
    nAssignId    WFL_ACTIVITIES.ACT_ASSIGN_ID%type;
    nProcessId   WFL_ACTIVITIES.WFL_PROCESSES_ID%type;
    cActPartType WFL_ACTIVITIES.C_WFL_ACT_PART_TYPE%type;
    cPartFunc    WFL_ACTIVITIES.ACT_PART_FUNCTION%type;
    cOldSection  PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection => 'WFL_WORKFLOW_MANAGEMENT : function GetActAutoPerformer');
    DebugLog(aLogText   => 'Start' || chr(10) || ' params : ' || chr(10) || 'aActivityInstanceId => '
                           || aActivityInstanceId
            );

    --récupération du rôle ou participant pour faire l'activité
    select ACT.PC_WFL_PARTICIPANTS_ID
         , ACT.C_WFL_ACT_PART_TYPE
         , ACT.ACT_ASSIGN_ID
         , ACT.ACT_PART_FUNCTION
         , ACT.WFL_PROCESSES_ID
         , AIN.WFL_PROCESS_INSTANCES_ID
      into result
         , cActPartType
         , nAssignId
         , cPartFunc
         , nProcessId
         , nProcInstId
      from WFL_ACTIVITY_INSTANCES AIN
         , WFL_ACTIVITIES ACT
     where AIN.WFL_ACTIVITIES_ID = ACT.WFL_ACTIVITIES_ID
       and AIN.WFL_PROCESSES_ID = ACT.WFL_PROCESSES_ID
       and AIN.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;

    if cActPartType = 'ACT_PERF' then
      select PFM.PC_WFL_PARTICIPANTS_ID
        into result
        from WFL_PERFORMERS PFM
       where C_WFL_PER_STATE = 'CURRENT'
         and WFL_ACTIVITY_INSTANCES_ID =
               (select max(AIN.WFL_ACTIVITY_INSTANCES_ID)
                  from WFL_ACTIVITY_INSTANCES AIN
                 where AIN.WFL_PROCESSES_ID = nProcessId
                   and AIN.WFL_ACTIVITIES_ID = nAssignId
                   and AIN.WFL_PROCESS_INSTANCES_ID = nProcInstId);
    elsif cActPartType = 'PROC_OWNER' then
      select PC_WFL_PARTICIPANTS_ID
        into result
        from WFL_PROCESS_INSTANCES
       where WFL_PROCESS_INSTANCES_ID = nProcInstId;
    elsif cActPartType = 'PART_PLSQL' then
      execute immediate 'select
        ' ||            cPartFunc || '
         from dual'
                   into result;
    end if;

    DebugLog(aLogText => 'End (result = ' || result || ')');
    GLogCTX.LOG_SECTION  := cOldSection;
    return result;
  exception
    when others then
      DebugLog(aLogText => 'End (result = ' || PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.WorkflowParticipant || ')');
      GLogCTX.LOG_SECTION  := cOldSection;
      return PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.WorkflowParticipant;
  end GetActAutoPerformer;

  /********************** InstantiateActivityInstance ************************/
  procedure InstantiateActivityInstance(
    aProcessInstanceId    in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  , aProcessId            in WFL_PROCESSES.WFL_PROCESSES_ID%type
  , aActivityId           in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  , aPerfParticipantId    in PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type
  , aApplicationId        in WFL_APPLICATIONS.WFL_APPLICATIONS_ID%type
  , aPlsqlProcName        in WFL_APPLICATIONS.APP_PLSQL_PROC_NAME%type
  , aDeadlineId           in WFL_DEADLINES.WFL_DEADLINES_ID%type
  , aDaysDue              in WFL_ACTIVITIES.ACT_LIMIT%type
  , aSubflowProcId        in WFL_ACTIVITIES.WFL_HAS_SUBFLOW_PROCESSES_ID%type
  , aSubflowExecution     in WFL_ACTIVITIES.C_WFL_SUBFLOW_EXECUTION%type
  , aImplementation       in WFL_ACTIVITIES.C_WFL_ACT_IMPLEMENTATION%type
  , aStartMode            in WFL_ACTIVITIES.ACT_START_MODE%type
  , aFinishMode           in WFL_ACTIVITIES.ACT_FINISH_MODE%type
  , aAssignParticipantId  in PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type
  , aDateCreated          in WFL_ACTIVITY_INSTANCES.AIN_DATE_CREATED%type
  , aActivityInstanceId   in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aActParticipantId     in WFL_ACTIVITY_INSTANCES.PC_WFL_PARTICIPANTS_ID%type
  , aExcludeParticipantId in WFL_ACTIVITY_INSTANCES.PC_WFL_EXCLUDE_PARTICIPANTS_ID%type
  , aValidationRequired   in WFL_ACTIVITY_INSTANCES.AIN_VALIDATION_REQUIRED%type default 0
  , aGuestAuthorized      in WFL_ACTIVITY_INSTANCES.AIN_GUESTS_AUTHORIZED%type default 0
  , aEmailToParticipants  in WFL_ACTIVITY_INSTANCES.AIN_EMAILTO_PARTICIPANTS%type default 0
  , aObjectStartRequired  in WFL_ACTIVITY_INSTANCES.AIN_OBJECT_START_REQUIRED%type default 0
  )
  is
    -- paramètres et valeurs pour construction liste des paramètres in du subflow
    cursor crSubflowFormalParams(
      aSubflowProcessId  in WFL_PROCESSES.WFL_PROCESSES_ID%type
    , aProcessInstanceId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
    , aActivityId        in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
    , aProcessId         in WFL_PROCESSES.WFL_PROCESSES_ID%type
    )
    is
      select *
        from (select FPA.FPA_DATA_TYPE
                   , FPA.C_WFL_PARAM_MODE
                   , FPA.FPA_INDEX
                   , ATI.ATI_VALUE
                   , null as APA_EXPRESSION
                   , ATT.ATT_NAME
                from WFL_FORMAL_PARAMETERS FPA
                   , WFL_ACTUAL_PARAMETERS APA
                   , WFL_ATTRIBUTE_INSTANCES ATI
                   , WFL_ATTRIBUTES ATT
               where FPA.WFL_FORMAL_PARAMETERS_ID = APA.WFL_FORMAL_PARAMETERS_ID
                 and APA.WFL_ACTIVITIES_ID = aActivityId
                 and APA.WFL_PROCESSES_ID = aProcessId
                 and FPA.C_WFL_PARAM_MODE like 'IN%'
                 and FPA.WFL_ATTRIBUTES_ID = ATT.WFL_ATTRIBUTES_ID
                 and APA.WFL_ATTRIBUTES_ID = ATI.WFL_ATTRIBUTES_ID
                 and ATI.WFL_PROCESS_INSTANCES_ID = aProcessInstanceId
                 and FPA.WFL_PROCESSES_ID = aSubflowProcessId
              union
              select FPA.FPA_DATA_TYPE
                   , FPA.C_WFL_PARAM_MODE
                   , FPA.FPA_INDEX
                   , null as ATI_VALUE
                   , APA.APA_EXPRESSION
                   , ATT.ATT_NAME
                from WFL_FORMAL_PARAMETERS FPA
                   , WFL_ACTUAL_PARAMETERS APA
                   , WFL_ATTRIBUTES ATT
               where FPA.WFL_FORMAL_PARAMETERS_ID = APA.WFL_FORMAL_PARAMETERS_ID
                 and APA.WFL_ACTIVITIES_ID = aActivityId
                 and APA.WFL_PROCESSES_ID = aProcessId
                 and
                     --FPA.C_WFL_PARAM_MODE like 'IN%' --can only be IN if expression
                     FPA.WFL_ATTRIBUTES_ID = ATT.WFL_ATTRIBUTES_ID
                 and APA.APA_EXPRESSION is not null
                 and APA.WFL_ATTRIBUTES_ID is null
                 and FPA.WFL_PROCESSES_ID = aSubflowProcessId);

    tplSubflowFormalParams crSubflowFormalParams%rowtype;

    -- récupérer les paramètres et valeurs pour la liste de paramètres tool
    cursor crToolFormalParams(
      aApplicationId     in WFL_APPLICATIONS.WFL_APPLICATIONS_ID%type
    , aProcessInstanceId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
    , aActivityId        in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
    , aProcessId         in WFL_PROCESSES.WFL_PROCESSES_ID%type
    )
    is
      select   rownum
             , FPA_NAME
             , FPA_INDEX
             , ATI_VALUE
             , APA_EXPRESSION
          from (select FPA.FPA_DATA_TYPE
                     , FPA.C_WFL_PARAM_MODE
                     , FPA.FPA_NAME
                     , FPA.FPA_INDEX
                     , FPA.WFL_FORMAL_PARAMETERS_ID
                     , ATI.ATI_VALUE
                     , null as APA_EXPRESSION
                  from WFL_FORMAL_PARAMETERS FPA
                     , WFL_ACTUAL_PARAMETERS APA
                     , WFL_ATTRIBUTE_INSTANCES ATI
                 where FPA.WFL_FORMAL_PARAMETERS_ID = APA.WFL_FORMAL_PARAMETERS_ID
                   and APA.WFL_ACTIVITIES_ID = aActivityId
                   and APA.WFL_PROCESSES_ID = aProcessId
                   and FPA.WFL_APPLICATIONS_ID = aApplicationId
                   and FPA.C_WFL_PARAM_MODE like 'IN%'
                   and   -- IN and INOUT
                       APA.WFL_ATTRIBUTES_ID = ATI.WFL_ATTRIBUTES_ID
                   and ATI.WFL_PROCESS_INSTANCES_ID = aProcessInstanceId
                union
                select FPA.FPA_DATA_TYPE
                     , FPA.C_WFL_PARAM_MODE
                     , FPA.FPA_NAME
                     , FPA.FPA_INDEX
                     , FPA.WFL_FORMAL_PARAMETERS_ID
                     , null as ATI_VALUE
                     , APA.APA_EXPRESSION
                  from WFL_FORMAL_PARAMETERS FPA
                     , WFL_ACTUAL_PARAMETERS APA
                 where FPA.WFL_FORMAL_PARAMETERS_ID = APA.WFL_FORMAL_PARAMETERS_ID
                   and APA.WFL_ACTIVITIES_ID = aActivityId
                   and APA.WFL_PROCESSES_ID = aProcessId
                   and FPA.WFL_APPLICATIONS_ID = aApplicationId
                   and APA.APA_EXPRESSION is not null
                   and APA.WFL_ATTRIBUTES_ID is null
                union
                select FPA.FPA_DATA_TYPE
                     , FPA.C_WFL_PARAM_MODE
                     , FPA.FPA_NAME
                     , FPA.FPA_INDEX
                     , FPA.WFL_FORMAL_PARAMETERS_ID
                     , null as ATI_VALUE
                     , null as APA_EXPRESSION
                  from WFL_FORMAL_PARAMETERS FPA
                     , WFL_ACTUAL_PARAMETERS APA
                 where FPA.WFL_FORMAL_PARAMETERS_ID = APA.WFL_FORMAL_PARAMETERS_ID
                   and APA.WFL_ACTIVITIES_ID = aActivityId
                   and APA.WFL_PROCESSES_ID = aProcessId
                   and FPA.WFL_APPLICATIONS_ID = aApplicationId
                   and FPA.C_WFL_PARAM_MODE = 'OUT')
      order by FPA_INDEX asc
             , WFL_FORMAL_PARAMETERS_ID asc;

    --tplToolFormalParams crToolFormalParams%RowType;

    --curseur pour activité d'instance
    cursor crActInstance(aActivityInstanceId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type)
    is
      select     *
            from WFL_ACTIVITY_INSTANCES
           where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
      for update;

    tplActInstance         crActInstance%rowtype;

    --curseur pour parcours des attributs d'activité
    cursor crActAttribute(
      aActivityId in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
    , aProcessId  in WFL_PROCESSES.WFL_PROCESSES_ID%type
    )
    is
      select WFL_ACTIVITY_ATTRIBUTES_ID
           , ACA_NAME
           , ACA_LENGTH
           , ACA_INITIAL_VALUE
           , ACA_KEEP
        from WFL_ACTIVITY_ATTRIBUTES
       where WFL_ACTIVITIES_ID = aActivityId
         and WFL_PROCESSES_ID = aProcessId;

    tplActAttribute        crActAttribute%rowtype;
    nActInstId             WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type;
    cWorkListLine          varchar2(4000)                                          default null;
    cParameterList         varchar2(4000)                                          default '';
    cLogParameterList      varchar2(4000)                                          default '';
    bCommaInParamList      boolean                                                 default false;
    cNotation              char(1)                                                 default null;
    nJobOut                binary_integer;   -- Numéro du job pour appels proc PL/SQL
    dDueDate               date                                                    default null;
    nProcInstId            WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type;   -- identifiant du sous-process
    cWorkListDisplayQuery  WFL_ACTIVITIES.ACT_WORKLIST_DISPLAY_QUERY%type;
    nLoopCnt               pls_integer;
    nParticipantId         WFL_ACTIVITY_INSTANCES.PC_WFL_PARTICIPANTS_ID%type;
    nSubflowPartId         WFL_ACTIVITY_INSTANCES.PC_WFL_PARTICIPANTS_ID%type;   -- utilisé pour récupérer le responsable de cette instance de process
    nAutoParticipantId     WFL_ACTIVITY_INSTANCES.PC_WFL_PARTICIPANTS_ID%type;
    cRemarks               WFL_ACTIVITY_INSTANCES.AIN_REMARKS%type;   -- remarques du process parent pour copie dans le SubFlow
    cActivityId            varchar2(150);
    cActivityName          WFL_ACTIVITIES.ACT_NAME%type;
    cProcName              WFL_PROCESSES.PRO_NAME%type;
    cOldSection            PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --récupération identifiant activité, processus
    select ACT_NAME || ' [' || WFL_ACTIVITIES_ID || ']'
         , ACT_NAME
      into cActivityId
         , cActivityName
      from WFL_ACTIVITIES
     where WFL_ACTIVITIES_ID = aActivityId;

    select PRO_NAME
      into cProcName
      from WFL_PROCESSES
     where WFL_PROCESSES_ID = aProcessId;

    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection    => 'WFL_WORKFLOW_MANAGEMENT : procedure InstantiateActivityInstance'
                 , aRecordId   => aProcessInstanceId
                  );
    DebugLog(aLogText   => 'Start' ||
                           chr(10) ||
                           ' params : ' ||
                           chr(10) ||
                           'aProcessInstanceId    => ' ||
                           aProcessInstanceId ||
                           chr(10) ||
                           'aProcessId            => ' ||
                           aProcessId ||
                           chr(10) ||
                           'aActivityId           => ' ||
                           aActivityId ||
                           chr(10) ||
                           'aPerfParticipantId    => ' ||
                           aPerfParticipantId ||
                           chr(10) ||
                           'aApplicationId        => ' ||
                           aApplicationId ||
                           chr(10) ||
                           'aPlsqlProcName        => ' ||
                           aPlsqlProcName ||
                           chr(10) ||
                           'aDeadlineId           => ' ||
                           aDeadlineId ||
                           chr(10) ||
                           'aDaysDue              => ' ||
                           aDaysDue ||
                           chr(10) ||
                           'aSubflowProcId        => ' ||
                           aSubflowProcId ||
                           chr(10) ||
                           'aSubflowExecution     => ' ||
                           aSubflowExecution ||
                           chr(10) ||
                           'aImplementation       => ' ||
                           aImplementation ||
                           chr(10) ||
                           'aStartMode            => ' ||
                           aStartMode ||
                           chr(10) ||
                           'aFinishMode           => ' ||
                           aFinishMode ||
                           chr(10) ||
                           'aAssignParticipantId  => ' ||
                           aAssignParticipantId ||
                           chr(10) ||
                           'aDateCreated          => ' ||
                           aDateCreated ||
                           chr(10) ||
                           'aActivityInstanceId   => ' ||
                           aActivityInstanceId ||
                           chr(10) ||
                           'aActParticipantId     => ' ||
                           aActParticipantId ||
                           chr(10) ||
                           'aExcludeParticipantId => ' ||
                           aExcludeParticipantId ||
                           chr(10) ||
                           'aValidationRequired   => ' ||
                           aValidationRequired ||
                           chr(10) ||
                           'aGuestAuthorized      => ' ||
                           aGuestAuthorized ||
                           chr(10) ||
                           'aEmailToParticipants  => ' ||
                           aEmailToParticipants ||
                           chr(10) ||
                           'aObjectStartRequired  => ' ||
                           aObjectStartRequired
            );

    -- calcule la date maximum a laquelle le process doit s'executer (duedate)
    if (aDaysDue is not null) then
      dDueDate  := sysdate + aDaysDue;
    end if;

    if    (aActParticipantId is null)
       or not(aActParticipantId > 0) then
      --récupération de l'utilisateur contenu dans ACT_PART_QUERY
      DebugLog(aLogText => 'About to convert to number ACT_PART_QUERY of activity ' || cActivityId);

      select to_number(ACT.ACT_PART_QUERY)
        into nParticipantId
        from WFL_ACTIVITIES ACT
       where ACT.WFL_ACTIVITIES_ID = aActivityId
         and ACT.WFL_PROCESSES_ID = aProcessId;

      DebugLog(aLogText   => 'Participant of activity is ' ||
                             PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantName(aParticipantId => nParticipantId) ||
                             ' [' ||
                             nParticipantId ||
                             ']'
              );
    else
      nParticipantId  := aActParticipantId;
      DebugLog(aLogText   => 'Participant of activity is ' ||
                             PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantName(aParticipantId => nParticipantId) ||
                             ' [' ||
                             nParticipantId ||
                             ']'
              );
    end if;

    if (aActivityInstanceId is null) then
      --création de l'activité de l'instance
      DebugLog(aLogText => 'Inserting in WFL_ACTIVITY_INSTANCES');

      insert into WFL_ACTIVITY_INSTANCES
                  (WFL_ACTIVITY_INSTANCES_ID
                 , WFL_PROCESS_INSTANCES_ID
                 , WFL_PROCESSES_ID
                 , WFL_ACTIVITIES_ID
                 , AIN_DATE_CREATED
                 , AIN_DATE_STARTED
                 , AIN_DATE_ENDED
                 , WFL_DEADLINES_ID
                 , AIN_DATE_DUE
                 , C_WFL_ACTIVITY_STATE
                 , AIN_REMARKS
                 , AIN_WORKLIST_DISPLAY
                 , AIN_SESSION_STATE
                 , AIN_NEGATION
                 , PC_WFL_PARTICIPANTS_ID
                 , PC_WFL_EXCLUDE_PARTICIPANTS_ID
                 , AIN_VALIDATION_REQUIRED
                 , AIN_GUESTS_AUTHORIZED
                 , AIN_EMAILTO_PARTICIPANTS
                 , AIN_OBJECT_START_REQUIRED
                  )
           values (WFL_ACTIVITY_INSTANCES_SEQ.nextval
                 , aProcessInstanceId
                 , aProcessId
                 , aActivityId
                 , aDateCreated
                 , null
                 , null
                 , aDeadlineId
                 , dDueDate
                 , 'NOTRUNNING'
                 , null
                 , null
                 , empty_blob()
                 , 0
                 ,   -- normal instance
                   nParticipantId
                 , aExcludeParticipantId
                 , aValidationRequired
                 , aGuestAuthorized
                 , aEmailToParticipants
                 , aObjectStartRequired
                  )
        returning WFL_ACTIVITY_INSTANCES_ID
             into nActInstId;

      --création des instances d'évènements pour l'activité en cours
      DebugLog(aLogText   => 'Inserting in WFL_ACTIVITY_INSTANCE_EVTS (ActivityInstanceId = ' ||
                             cActivityName ||
                             ' [' ||
                             nActInstId ||
                             '])'
              );

      insert into WFL_ACTIVITY_INSTANCE_EVTS
                  (WFL_ACTIVITY_EVENTS_ID
                 , WFL_ACTIVITY_INSTANCES_ID
                 , C_WFL_ACTIVITY_STATE
                 , C_WFL_EVENT_TIMING
                 , WAV_EVENT_SEQ
                 , WAI_EVENT_TYPE_PROPERTIES
                 , A_DATECRE
                 , A_IDCRE
                  )
        select WAV.WFL_ACTIVITY_EVENTS_ID
             , nActInstId
             , WAV.C_WFL_ACTIVITY_STATE
             , WAV.C_WFL_EVENT_TIMING
             , WAV.WAV_EVENT_SEQ
             , WAV.WAV_EVENT_TYPE_PROPERTIES
             , sysdate
             , PCS.PC_PUBLIC.GetUserIni
          from WFL_ACTIVITY_EVENTS WAV
         where WAV.WFL_ACTIVITIES_ID = aActivityId;

      --initialisation des attributs d'activité
      DebugLog(aLogText   => 'Assigning attributes for instance of activity (ActivityInstanceId = ' ||
                             cActivityName ||
                             ' [' ||
                             nActInstId ||
                             '])'
              );

      for tplActAttribute in crActAttribute(aActivityId => aActivityId, aProcessId => aProcessId) loop
        WFL_WORKFLOW_MANAGEMENT.AssignActInstAttrib(aActivityInstanceId   => nActInstId
                                                  , aActAttribName        => tplActAttribute.ACA_NAME
                                                  , aActAttribInstValue   => tplActAttribute.ACA_INITIAL_VALUE
                                                   );
      end loop;
    else
      nActInstId  := aActivityInstanceId;
      --initialisation des attributs d'activité
      DebugLog(aLogText   => 'Assigning attributes for instance of activity (ActivityInstanceId = ' ||
                             cActivityName ||
                             ' [' ||
                             nActInstId ||
                             '])'
              );

      for tplActAttribute in crActAttribute(aActivityId => aActivityId, aProcessId => aProcessId) loop
        WFL_WORKFLOW_MANAGEMENT.AssignActInstAttrib(aActivityInstanceId   => nActInstId
                                                  , aActAttribName        => tplActAttribute.ACA_NAME
                                                  , aActAttribInstValue   => tplActAttribute.ACA_INITIAL_VALUE
                                                   );
      end loop;

      --une instance d'activité a été créée, mais pas démarrée, ni initialisé, il faut mettre à jour les valeurs
      open crActInstance(aActivityInstanceId => aActivityInstanceId);

      fetch crActInstance
       into tplActInstance;

      if crActInstance%notfound then
        DebugLog(aLogText    => 'Activity instance with ActInstId (' ||
                                cActivityName ||
                                ' [' ||
                                aActivityInstanceId ||
                                '])  not found'
               , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
                );
        Raise_Application_Error
                          (-20114
                         , 'WFL_WORKFLOW_MANAGEMENT.InstantiateActivityInstance : Activity instance with ActInstId (' ||
                           cActivityName ||
                           ' [' ||
                           aActivityInstanceId ||
                           ']) not found'
                          );
      else
        DebugLog(aLogText   => 'Updating values of ActivityInstance (ActivityInstanceId = ' ||
                               cActivityName ||
                               ' [' ||
                               tplActInstance.WFL_ACTIVITY_INSTANCES_ID ||
                               '])'
                );

        update WFL_ACTIVITY_INSTANCES
           set WFL_PROCESS_INSTANCES_ID = aProcessInstanceId
             , WFL_PROCESSES_ID = aProcessId
             , AIN_DATE_CREATED = aDateCreated
             , AIN_DATE_STARTED = null
             , AIN_DATE_ENDED = null
             , WFL_DEADLINES_ID = aDeadlineId
             , AIN_DATE_DUE = dDueDate
             , C_WFL_ACTIVITY_STATE = 'NOTRUNNING'
             , AIN_REMARKS = null
             , AIN_WORKLIST_DISPLAY = null
             , AIN_SESSION_STATE = empty_blob()
             , AIN_NEGATION = 0
             , PC_WFL_PARTICIPANTS_ID = nParticipantId
             , PC_WFL_EXCLUDE_PARTICIPANTS_ID = aExcludeParticipantId
             , AIN_VALIDATION_REQUIRED = aValidationRequired
             , AIN_GUESTS_AUTHORIZED = aGuestAuthorized
             , AIN_EMAILTO_PARTICIPANTS = aEmailToParticipants
             , AIN_OBJECT_START_REQUIRED = aObjectStartRequired
         where current of crActInstance;
      end if;

      close crActInstance;
    end if;

    -- Is a worklist html query present?
    -- Example worklist_display_query:
    -- select ACT.ACT_NAME
    -- from WFL_ACTIVITY_INSTANCES AIN,
    --      WFL_ACTIVITIES ACT,
    --      WFL_ATTRIBUTE_INSTANCES ATI
    -- where AIN.WFL_ACTIVITY_INSTANCES_ID = :ACT_INST_ID and
    --       AIN.WFL_ACTIVITIES_ID = ACT.WFL_ACTIVITIES_ID and
    --       AIN.WFL_PROCESSES_ID = ACT.WFL_PROCESSES_ID and
    --       ATI.WFL_ATTRIBUTES_ID = XXX and
    --       ATI.WFL_PROCESS_INSTANCES_ID = :PROC_INST_ID and
    --       ATI.ATI_VALUE = MESSAGES.id

    -- récupération de la requête d'affichage de la worklist
    select ACT_WORKLIST_DISPLAY_QUERY
      into cWorklistDisplayQuery
      from WFL_ACTIVITIES
     where WFL_PROCESSES_ID = aProcessId
       and WFL_ACTIVITIES_ID = aActivityId;

    if (cWorklistDisplayQuery is not null) then
      Debuglog(aLogText   => 'About to execute ACT_WORKLIST_DISPLAY_QUERY ''' ||
                             cWorklistDisplayQuery ||
                             ''' using ' ||
                             nActInstId
              );

      begin
        execute immediate cWorklistDisplayQuery
                     into cWorkListLine
                    using nActInstId;
      exception
        when no_data_found then
          DebugLog(aLogText    => 'InstantiateActivtyInstance: The worklist query didn''t return a result.'
                 , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
                  );
          Raise_Application_Error(-20110, 'InstantiateActivtyInstance: The worklist query didn''t return a result.');
      end;

      update WFL_ACTIVITY_INSTANCES
         set AIN_WORKLIST_DISPLAY = cWorkListLine
       where WFL_ACTIVITY_INSTANCES_ID = nActInstId;
    end if;

    -- on teste si l'activité doit être lancée en automatique
    if    (aStartMode = 'AUTOMATIC')
       or (aImplementation = 'SUBFLOW')
       or (aPlsqlProcName is not null) then
      DebugLog(aLogText   => 'activity instance (' ||
                             cActivityName ||
                             ' [' ||
                             aActivityInstanceId ||
                             ']) started automatically'
              );
      WFL_WORKFLOW_MANAGEMENT.ChangeActivityInstanceState
                                              (aActivityInstanceId   => nActInstId
                                             , aNewState             => 'RUNNING'
                                             , aParticipantId        => GetActAutoPerformer
                                                                                      (aActivityInstanceId   => nActInstId)
                                              );
    end if;

    -- si le participant id est non null, alors il existe un responsable pour cette activité (insérer dans performers)
    if (aPerfParticipantId is not null) then
      DebugLog
              (aLogText   => 'Inserting performer (PerfParticipantId = ' ||
                             PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantName
                                                                                (aParticipantId   => aPerfParticipantId) ||
                             ' [' ||
                             aPerfParticipantId ||
                             ']) for ActivityInstance (ActivityInstanceId = ' ||
                             cActivityName ||
                             ' [' ||
                             nActInstId ||
                             '])'
              );

      insert into WFL_PERFORMERS
                  (WFL_PERFORMERS_ID
                 , WFL_ACTIVITY_INSTANCES_ID
                 , PC_WFL_PARTICIPANTS_ID
                 , C_WFL_PER_STATE
                 , PFM_CREATE_DATE
                 , PFM_ACCEPTED
                 , PFM_REMARKS
                 , WFL_WFL_PERFORMERS_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (WFL_PERFORMERS_SEQ.nextval
                 , nActInstId
                 , aPerfParticipantId
                 , 'CURRENT'
                 , aDateCreated
                 , null
                 , null
                 , null
                 , sysdate
                 , PCS.PC_PUBLIC.GetUserIni
                  );
    end if;

    -- si aAssignParticipantId <> null, alors il il y a un participant assigné (human or role or ...).
    -- NB: si aPerfParticipantId <> null, alors ce participant est le participant assigné ou un rôle équivalent,
    --     sinon, la tâche n'apparaît pas sur la liste de tâches. See OpenWorkList and RejectWorkItem procedures.
    if (aAssignParticipantId is not null) then
      DebugLog
            (aLogText   => 'Inserting performer (AssignParticipantId = ' ||
                           PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantName
                                                                              (aParticipantId   => aAssignParticipantId) ||
                           ' [' ||
                           aAssignParticipantId ||
                           ']) for ActivityInstance (ActivityInstanceId = ' ||
                           cActivityName ||
                           ' [' ||
                           nActInstId ||
                           '])'
            );

      insert into WFL_PERFORMERS
                  (WFL_PERFORMERS_ID
                 , WFL_ACTIVITY_INSTANCES_ID
                 , PC_WFL_PARTICIPANTS_ID
                 , C_WFL_PER_STATE
                 , PFM_CREATE_DATE
                 , PFM_ACCEPTED
                 , PFM_REMARKS
                 , WFL_WFL_PERFORMERS_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (WFL_PERFORMERS_SEQ.nextval
                 , nActInstId
                 , aAssignParticipantId
                 , 'ASSIGNED'
                 , aDateCreated
                 , 'Y'
                 , null
                 , null
                 , sysdate
                 , PCS.PC_PUBLIC.GetUserIni
                  );
    end if;

    -- teste si il s'agit d'une application ou une procedure PL/SQL lancée en automatique
    if     (aImplementation = 'TOOL')
       and (aPlsqlProcName is not null) then
      DebugLog(aLogText => 'Implementation is TOOL, PLSQL_PROC_NAME is ' || aPlsqlProcName);
      --effacement des éléments de la table des paramètres out
      WFL_WORKFLOW_MANAGEMENT.OutParamTable.delete;
      nLoopCnt  := 0;
      -- lecture des valeurs des attributs qui sont des paramètres formels
      DebugLog(aLogText => 'Initialize formal parameters');

      for tplToolFormalParams in crToolFormalParams(aApplicationId       => aApplicationId
                                                  , aProcessInstanceId   => aProcessInstanceId
                                                  , aProcessId           => aProcessId
                                                  , aActivityId          => aActivityId
                                                   ) loop
        -- augmenter la taille du tableau pour saisie paramètres
        WFL_WORKFLOW_MANAGEMENT.OutParamTable.extend;
        nLoopCnt           := nLoopCnt + 1;

        --si il y a une expression, il faut l'évaluer dans tplToolFormalParams.
        if (tplToolFormalParams.APA_EXPRESSION is not null) then
          FSqlQuery  :=
            'SELECT ' ||
            tplToolFormalParams.APA_EXPRESSION ||
            ' ' ||
            'FROM  WFL_ACTIVITY_INSTANCES AIN ' ||
            'WHERE AIN.WFL_ACTIVITY_INSTANCES_ID = :ACTIVITY_INSTANCES_ID';
          DebugLog(aLogText   => 'About to evaluate expression, execute SQL statement ''' ||
                                 FSqlQuery ||
                                 ''' using ' ||
                                 nActInstId
                  );

          execute immediate FSqlQuery
                       into WFL_WORKFLOW_MANAGEMENT.OutParamTable(nLoopCnt)
                      using nActInstId;
        else
          DebugLog(aLogText => 'OutParamTable(' || nLoopCnt || ') = ' || tplToolFormalParams.ATI_VALUE);
          WFL_WORKFLOW_MANAGEMENT.OutParamTable(nLoopCnt)  := tplToolFormalParams.ATI_VALUE;
        end if;

        if bCommaInParamList then
          cParameterList     := cParameterList || ', ';
          cLogParameterList  := cLogParameterList || ', ';
        end if;

        bCommaInParamList  := true;

        --Named notation ????
        if (tplToolFormalParams.FPA_NAME is not null) then
          cParameterList     := cParameterList || tplToolFormalParams.FPA_NAME || '=>';
          cParameterList     := cParameterList || 'WFL_WORKFLOW_MANAGEMENT.OutParamTable(' || nLoopCnt || ')';
          cLogParameterList  := cLogParameterList || tplToolFormalParams.FPA_NAME || '=>';
          cLogParameterList  := cLogParameterList || WFL_WORKFLOW_MANAGEMENT.OutParamTable(nLoopCnt);

          if (cNotation = 'P') then
            DebugLog(aLogText    => 'Error: mixed named and positional notation in  formal parameters for activity  ' ||
                                    cActivityId ||
                                    '. Either specify all parameters by name, or by fopa_index.'
                   , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
                    );
            Raise_Application_Error(-20111
                                  , 'InstantiateActivtyInstance: Error: mixed named and positional notation in ' ||
                                    'formal parameters for activity  ' ||
                                    cActivityId ||
                                    '. Either specify all parameters by name, or by fopa_index.'
                                   );
          end if;

          cNotation          := 'N';
        else
          -- positional notation
          cParameterList  := cParameterList || 'WFL_WORKFLOW_MANAGEMENT.OutParamTable(' || nLoopCnt || ')';

          if (cNotation = 'N') then
            DebugLog(aLogText    => 'Error: mixed named and positional notation in  formal parameters for activity  ' ||
                                    cActivityId ||
                                    '. Either specify all parameters by name, or by fopa_index.'
                   , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
                    );
            Raise_Application_Error(-20112
                                  , 'InstantiateActivtyInstance: Error: mixed named and positional notation in ' ||
                                    'formal parameters for activity  ' ||
                                    cActivityId ||
                                    '. Either specify all parameters by name, or by fopa_index.'
                                   );
          end if;

          cNotation       := 'P';
        end if;
      end loop;

      Debuglog(aLogText => 'Aboute calling procedure ' || aPlsqlProcName || '( ' || cLogParameterList || ');');

      -- mis dans un bloc, pour pouvoir envoyer par mail les erreurs
      begin
        execute immediate 'BEGIN ' || aPlsqlProcName || '( ' || cParameterList || ');' || 'END;';
      --**traiter ici l'exception et envoie du mail ...
      end;

      -- si il rester des paramètres out, on les sauvegarde dans la table des instances d'attributs
      if (WFL_WORKFLOW_MANAGEMENT.OutParamTable.count > 0) then
        AssignActAttrib(aProcessId           => aProcessId
                      , aActivityId          => aActivityId
                      , aProcessInstanceId   => aProcessInstanceId
                      , aApplicationId       => aApplicationId
                       );
      end if;
    end if;

    -- Terminaison automatique
    if (    (aImplementation = 'NO')
        or (aImplementation = 'TOOL') ) then
      if (aFinishMode = 'AUTOMATIC') then
        WFL_WORKFLOW_MANAGEMENT.ChangeActivityInstanceState
                                               (aActivityInstanceId   => nActInstId
                                              , aNewState             => 'COMPLETED'
                                              , aParticipantId        => PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.WorkflowParticipant
                                               );
        DebugLog(aLogText   => 'ActivityInstance (' || cActivityName || ' [' || nActInstId
                               || ']) completed automatically');
      end if;
    elsif(aImplementation = 'SUBFLOW') then
      --Subflow, lance une nouvelle instance de process
      select WFL_PROCESS_INSTANCES_SEQ.nextval
        into nProcInstId
        from dual;

      DebugLog(aLogText => 'Creating subflow process ' || aSubflowProcId || '/' || nProcInstId);
      WFL_WORKFLOW_MANAGEMENT.CreateProcessInstance(aProcessId => aSubflowProcId, aProcessInstanceId => nProcInstId);

      -- lecture des valeurs des attributs qui sont des paramètres formels
      for tplSubflowformalParams in crSubflowformalParams(aSubflowProcessId    => aSubflowProcId
                                                        , aProcessInstanceId   => aProcessInstanceId
                                                        , aActivityId          => aActivityId
                                                        , aProcessId           => aProcessId
                                                         ) loop
        -- si il s'agit d'une expression, évaluée dans tplSubflowFormalParams.ATI_VALUE
        if (tplSubflowformalParams.APA_EXPRESSION is not null) then
          FSqlQuery  :=
            'select ' ||
            tplSubflowformalParams.APA_EXPRESSION ||
            ' from  WFL_ACTIVITY_INSTANCES AIN' ||
            ' where AIN.WFL_ACTIVITY_INSTANCES_ID = :ACT_INST_ID';
          DebugLog(aLogText   => 'About to evaluate expression, execute SQL statement ''' ||
                                 FSqlQuery ||
                                 ''' using ' ||
                                 nActInstId
                  );

          execute immediate FSqlQuery
                       into tplSubflowformalParams.ATI_VALUE
                      using nActInstId;
        end if;

        -- assigne les attributs dans le sous-process
        DebugLog(aLogText   => 'About to assign in ProcessInstance (' ||
                               cProcName ||
                               ' [' ||
                               nProcInstId ||
                               ']) attribute ' ||
                               tplSubflowformalParams.ATT_NAME ||
                               ' with value ' ||
                               tplSubflowformalParams.ATI_VALUE ||
                               '.'
                );
        WFL_WORKFLOW_MANAGEMENT.AssignProcessinstanceAttribute(aProcessInstanceId   => nProcInstId
                                                             , aAttributeName       => tplSubflowformalParams.ATT_NAME
                                                             , aAttributeValue      => tplSubflowformalParams.ATI_VALUE
                                                              );
      end loop;

      -- teste le genre d'exécution du sous-flux
      -- From: TC-1025-10 (p34)
      -- In the case of synchronous execution the execution of the Activity is suspended after a process instance of the
      -- referenced Process Definition is initiated. After execution termination of this process instance the Activity is resumed.
      -- Return parameters may be used between the called and calling processes on completion of the subflow. This style of
      -- subflow is characterized as hierarchic subflow operation.
      if (aSubflowExecution = 'SYNCHR') then
        DebugLog(aLogText   => 'Suspending ActivityInstance(' ||
                               cActivityName ||
                               ' [' ||
                               nActInstId ||
                               ']) with synchronous subflow execution'
                );
        --suspension du process
        WFL_WORKFLOW_MANAGEMENT.ChangeActivityinstanceState
                                                (aActivityInstanceId   => nActInstId
                                               , aNewState             => 'SUSPENDED'
                                               , aParticipantId        => PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.WorkflowParticipant
                                                );

        --lien sur l'instance d'activité parent de ce process
        update WFL_PROCESS_INSTANCES
           set WFL_ACTIVITY_INSTANCES_ID = nActInstId
         where WFL_PROCESS_INSTANCES_ID = nProcInstId;

        --ajout des remarques à l'instance du process
        select PRI_REMARKS
          into cRemarks
          from WFL_PROCESS_INSTANCES
         where WFL_PROCESS_INSTANCES_ID = aProcessInstanceId;

        WFL_WORKFLOW_MANAGEMENT.AddProcessInstanceRemarks(aProcessInstanceId => nProcInstId, aRemarks => cRemarks);
      -- from: TC-1025-10 (p34)
      -- in the case of asynchronous execution the execution of the Activity is continued after a process instance of the
      -- referenced Process Definition is initiated (in this case execution proceeds to any post activity split logic after subflow
      -- initiation. No return parameters are supported from such called processes. Synchronization with the initiated subflow, if
      -- required, has to be done by other means such as events, not described in this document. This style of subflow is
      -- characterized as chained (or forked) subflow operation.
      elsif(aSubflowExecution = 'ASYNCHR') then
        -- execution des activités
        WFL_WORKFLOW_MANAGEMENT.ChangeActivityinstanceState
                                               (aActivityInstanceId   => nActInstId
                                              , aNewState             => 'COMPLETED'
                                              , aParticipantId        => PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.WorkflowParticipant
                                               );
      else
        DebugLog(aLogText    => 'Unknown subflow execution type ' || aSubflowExecution
               , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
                );
        Raise_Application_Error(-20113
                              , 'InstantiateActivtyInstance: unknown subflow execution type ' || aSubflowExecution
                               );
      end if;

      -- lancement du process une fois que tous les attributs sont en place
      select PC_WFL_PARTICIPANTS_ID
        into nSubFlowPartId
        from WFL_PROCESS_INSTANCES
       where WFL_PROCESS_INSTANCES_ID = aProcessInstanceId;

      DebugLog(aLogText => 'Starting process (' || cProcName || ' [' || nProcInstId || '])');
      WFL_WORKFLOW_MANAGEMENT.StartProcess(aProcessInstanceId => nProcInstId, aParticipantId => nSubFlowPartId);   --WF engine itself
    end if;

    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
  end InstantiateActivityInstance;

  /********************** Internal CleanProcessinstance **********************/
  procedure CleanProcessinstance(aProcessInstanceId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type)
  is
    cOldSection PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection    => 'WFL_WORKFLOW_MANAGEMENT : procedure CleanProcessInstance'
                 , aRecordId   => aProcessInstanceId
                  );
    DebugLog(aLogText   => 'Start' || chr(10) || ' params : ' || chr(10) || 'aProcessInstanceId    => '
                           || aProcessInstanceId
            );

    --procédure interne appelée lors de la fermeture d'un process (mise à l'état COMPLETED ou TERMINATED)
    -- suppression des attributs des process que l'on ne veut pas garder (ATT_Keep = 0)
    delete from WFL_ATTRIBUTE_INSTANCES
          where WFL_ATTRIBUTES_ID in(select distinct WFL_ATTRIBUTES_ID
                                                from WFL_ATTRIBUTES
                                               where ATT_KEEP = 0)
            and WFL_PROCESS_INSTANCES_ID = aProcessInstanceId;

    --suppression des attributs des activités que l'on ne veut pas garder
    delete from WFL_ACT_ATTRIBUTE_INSTANCES
          where WFL_ACTIVITY_ATTRIBUTES_ID in(select distinct WFL_ACTIVITY_ATTRIBUTES_ID
                                                         from WFL_ACTIVITY_ATTRIBUTES
                                                        where ACA_KEEP = 0)
            and WFL_ACTIVITY_INSTANCES_ID in(select WFL_ACTIVITY_INSTANCES_ID
                                               from WFL_ACTIVITY_INSTANCES
                                              where WFL_PROCESS_INSTANCES_ID = aProcessInstanceId);

    --suppression des transitions invalides
    delete from WFL_TRANSITION_INSTANCES TRI
          where exists(
                  select 1
                    from WFL_ACTIVITY_INSTANCES AIN
                   where TRI.WFL_FROM_ACTIVITY_INSTANCES_ID = AIN.WFL_ACTIVITY_INSTANCES_ID
                     and AIN.WFL_PROCESS_INSTANCES_ID = aProcessInstanceId)
            and TRI.TRI_NEGATION = 1;

    --suppression des instances d'activité avec le champ AIN_NEGATION à 1
    delete from WFL_ACTIVITY_INSTANCES AIN
          where AIN.AIN_NEGATION = 1
            and not exists(
                         select 1
                           from WFL_TRANSITION_INSTANCES TRI
                          where TRI.WFL_TO_ACTIVITY_INSTANCES_ID = AIN.WFL_ACTIVITY_INSTANCES_ID
                            and TRI.TRI_NEGATION = 0)
            and AIN.WFL_PROCESS_INSTANCES_ID = aProcessInstanceId;

    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
  end CleanProcessinstance;

  /********************** CheckDeadlines ************************************/
  procedure CheckDeadlines
  is
    -- lecture des éléments ayant dépassé la date limite
    cursor crLateItem
    is
      select AIN.WFL_ACTIVITY_INSTANCES_ID
           , AIN.WFL_PROCESS_INSTANCES_ID
           , AIN.WFL_PROCESSES_ID
           , AIN.WFL_ACTIVITIES_ID
           , AIN.AIN_DATE_CREATED
           , (AIN.AIN_DATE_DUE - AIN.AIN_DATE_CREATED) as DueTimeAmount
           , DEA.C_WFL_DEADLINE_EXECUTION
           , DEA.DEA_EXCEPTION_NAME
        from WFL_ACTIVITY_INSTANCES AIN
           , WFL_DEADLINES DEA
       where DEA.WFL_DEADLINES_ID = AIN.WFL_DEADLINES_ID
         and AIN.C_WFL_ACTIVITY_STATE in('NOTRUNNING', 'SUSPENDED', 'RUNNING')
         and AIN.AIN_NEGATION = 0
         and AIN.AIN_DATE_DUE < sysdate;

    tplLateItem         crLateItem%rowtype;

    -- cursor pour les exception de transitions
    cursor crTransition(
      aProcessId     in WFL_PROCESSES.WFL_PROCESSES_ID%type
    , aActivityId    in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
    , aExceptionName in WFL_DEADLINES.DEA_EXCEPTION_NAME%type
    )
    is
      select TRA.WFL_TO_ACTIVITIES_ID
           , TRA.WFL_FROM_ACTIVITIES_ID
        from WFL_TRANSITIONS TRA
       where GetConditionException(TRA.TRA_CONDITION) = aExceptionName
         and TRA.C_WFL_CONDITION_TYPE = 'EXCEPTION'
         and TRA.WFL_FROM_PROCESSES_ID = aProcessId
         and TRA.WFL_FROM_ACTIVITIES_ID = aActivityId;

    tplTransition       crTransition%rowtype;

    -- curseur pour récupérer une nouvelle date limite
    cursor crDeadline(
      aProcessId  in WFL_PROCESSES.WFL_PROCESSES_ID%type
    , aActivityId in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
    )
    is
      select DEA.WFL_DEADLINES_ID
           , DEA.C_WFL_DEADLINE_EXECUTION
           , DEA.DEA_CONDITION
           , DEA.DEA_EXCEPTION_NAME
        from WFL_DEADLINES DEA
       where DEA.WFL_PROCESSES_ID = aProcessId
         and DEA.WFL_ACTIVITIES_ID = aActivityId;

    tplDeadline         crDeadline%rowtype;
    nDueDays            number(15, 5);
    nDueDaysLowest      number(15, 5);
    nDeadlineId         WFL_DEADLINES.WFL_DEADLINES_ID%type;
    nActivityInstanceId WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type;
    cActJoin            WFL_ACTIVITIES.C_WFL_JOIN%type;
    cOldSection         PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection => 'WFL_WORKFLOW_MANAGEMENT : procedure CheckDeadlines');
    DebugLog(aLogText => 'Start');

    -- lecture de tous les éléments ayant dépassé la date limite
    for tplLateItem in crLateItem loop
      --recherche des transitions qui correspondent aux nom d'exceptions des deadlines
      open crTransition(aProcessId       => tplLateItem.WFL_PROCESSES_ID
                      , aActivityId      => tplLateItem.WFL_ACTIVITIES_ID
                      , aExceptionName   => tplLateItem.DEA_EXCEPTION_NAME
                       );

      fetch crTransition
       into tplTransition;

      -- Make the (first found) transition
      --ELSE
      if crTransition%found then
        DebugLog(aLogText => 'Deadline reached on workitem ' || tplLateItem.WFL_ACTIVITY_INSTANCES_ID);

        --test le workflow pour voir si il n'y a pas de transitions du type AND-join
        select C_WFL_JOIN
          into cActJoin
          from WFL_ACTIVITIES
         where WFL_PROCESSES_ID = tplLateItem.WFL_PROCESSES_ID
           and WFL_ACTIVITIES_ID = tplTransition.WFL_TO_ACTIVITIES_ID;

        if (cActJoin = 'AND') then
          exit;
        end if;

        --création de l'activité de l'instance
        DebugLog(aLogText   => 'Creating ActivityInstance with state PRECREATED, identified by ProcessInstanceId ' ||
                               tplLateItem.WFL_PROCESS_INSTANCES_ID
                );

        insert into WFL_ACTIVITY_INSTANCES
                    (WFL_ACTIVITY_INSTANCES_ID
                   , WFL_PROCESS_INSTANCES_ID
                   , WFL_PROCESSES_ID
                   , WFL_ACTIVITIES_ID
                   , AIN_DATE_CREATED
                   , AIN_DATE_STARTED
                   , AIN_DATE_ENDED
                   , AIN_DATE_DUE
                   , C_WFL_ACTIVITY_STATE
                   , AIN_REMARKS
                   , AIN_WORKLIST_DISPLAY
                   , AIN_SESSION_STATE
                   , AIN_NEGATION
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (WFL_ACTIVITY_INSTANCES_SEQ.nextval
                   , tplLateItem.WFL_PROCESS_INSTANCES_ID
                   , tplLateItem.WFL_PROCESSES_ID
                   , tplLateItem.WFL_ACTIVITIES_ID
                   , sysdate
                   , null
                   , null
                   , null
                   , 'PRECREATED'
                   ,
                     --l'instantiation n'intervient qu'après le calculs des deadlines
                     null
                   , null
                   , empty_blob()
                   , 0
                   , sysdate
                   , PCS.PC_PUBLIC.GetUserIni
                    )
          returning WFL_ACTIVITY_INSTANCES_ID
               into nActivityInstanceId;

        --création des instances d'évènements pour l'activité en cours
        insert into WFL_ACTIVITY_INSTANCE_EVTS
                    (WFL_ACTIVITY_EVENTS_ID
                   , WFL_ACTIVITY_INSTANCES_ID
                   , C_WFL_ACTIVITY_STATE
                   , C_WFL_EVENT_TIMING
                   , WAV_EVENT_SEQ
                   , WAI_EVENT_TYPE_PROPERTIES
                   , A_DATECRE
                   , A_IDCRE
                    )
          select WAV.WFL_ACTIVITY_EVENTS_ID
               , nActivityInstanceId
               , WAV.C_WFL_ACTIVITY_STATE
               , WAV.C_WFL_EVENT_TIMING
               , WAV.WAV_EVENT_SEQ
               , WAV.WAV_EVENT_TYPE_PROPERTIES
               , sysdate
               , PCS.PC_PUBLIC.GetUserIni
            from WFL_ACTIVITY_EVENTS WAV
           where WAV.WFL_ACTIVITIES_ID = tplLateItem.WFL_ACTIVITIES_ID;

        --création de l'instance de transition
        insert into WFL_TRANSITION_INSTANCES
                    (WFL_FROM_PROCESSES_ID
                   , WFL_FROM_ACTIVITIES_ID
                   , WFL_TO_PROCESSES_ID
                   , WFL_TO_ACTIVITIES_ID
                   , WFL_FROM_ACTIVITY_INSTANCES_ID
                   , WFL_TO_ACTIVITY_INSTANCES_ID
                   , TRI_NEGATION
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (tplLateItem.WFL_PROCESSES_ID
                   , tplTransition.WFL_FROM_ACTIVITIES_ID
                   , tplLateItem.WFL_PROCESSES_ID
                   , tplTransition.WFL_TO_ACTIVITIES_ID
                   , tplLateItem.WFL_ACTIVITY_INSTANCES_ID
                   , nActivityInstanceId
                   , 0
                   ,   --a real transition
                     sysdate
                   , PCS.PC_PUBLIC.GetUserIni
                    );

        if (tplLateItem.C_WFL_DEADLINE_EXECUTION = 'SYNCHR') then
          -- Synchronous deadline: terminate timed out activity instance
          WFL_WORKFLOW_MANAGEMENT.ChangeActivityinstanceState
                                               (aActivityInstanceId   => tplLateItem.WFL_ACTIVITY_INSTANCES_ID
                                              , aNewState             => 'TERMINATED'
                                              , aParticipantId        => PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.WorkflowParticipant
                                               );
        else
          -- Asynchronous deadline: is there a new deadline on the workitem? (possible synchronous)
          for tplDeadline in crDeadline(aProcessId    => tplLateItem.WFL_PROCESSES_ID
                                      , aActivityId   => tplLateItem.WFL_ACTIVITIES_ID
                                       ) loop
            begin
              -- Evaluate the deadline condition expression (in context of current Process instance).
              -- Return only those with a condition greater than the current deadline.
              FSqlQuery  :=
                'select duetime
                 from (select ' ||
                tplDeadline.DEA_CONDITION ||
                ' as duetime
                       from WFL_PROCESS_INSTANCES
                       where WFL_PROCESS_INSTANCES_ID = :PROCESS_INSTANCE_ID
                      )
                 where duetime > :DueTimeAmount';
              DebugLog(aLogText   => 'About to evaluate deadline condition expression with query ''' ||
                                     FSqlQuery ||
                                     ''' using ' ||
                                     tplLateItem.WFL_PROCESS_INSTANCES_ID
                      );

              execute immediate FSqlQuery
                           into nDueDays
                          using tplLateItem.WFL_PROCESS_INSTANCES_ID, tplLateItem.DueTimeAmount;

              if    (nDueDaysLowest is null)
                 or (nDueDaysLowest > nDueDays) then
                nDueDaysLowest  := nDueDays;
                nDeadlineId     := tplDeadline.WFL_DEADLINES_ID;
              end if;
            exception
              when no_data_found then
                null;
            end;
          end loop;

          -- Change deadline.
          if (nDeadlineId is not null) then
            DebugLog(aLogText => 'set new deadline');

            -- Set new deadline and date_due
            update WFL_ACTIVITY_INSTANCES
               set WFL_DEADLINES_ID = nDeadlineId
                 , AIN_DATE_DUE = tplLateItem.AIN_DATE_CREATED + nDueDaysLowest
             where WFL_ACTIVITY_INSTANCES_ID = tplLateItem.WFL_ACTIVITY_INSTANCES_ID;
          else
            --no new deadline found.
            DebugLog(aLogText => 'remove deadline');

            -- Remove deadline, but keep date_due
            update WFL_ACTIVITY_INSTANCES
               set WFL_DEADLINES_ID = null
             where WFL_ACTIVITY_INSTANCES_ID = tplLateItem.WFL_ACTIVITY_INSTANCES_ID;
          end if;
        end if;

        --création de l'instance d'activité et initialisation de celle-ci
        WFL_WORKFLOW_MANAGEMENT.CreateActivityInstance(aProcessInstanceId    => tplLateItem.WFL_PROCESS_INSTANCES_ID
                                                     , aProcessId            => tplLateItem.WFL_PROCESSES_ID
                                                     , aActivityId           => tplTransition.WFL_TO_ACTIVITIES_ID
                                                     , aActivityInstanceId   => nActivityInstanceId
                                                      );
      end if;

      --fermeture curseur
      close crTransition;
    end loop;

    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
    commit work;
  end CheckDeadlines;

  /********************** Internal MoveToArchive *****************************/
  procedure MoveToArchive(aProcessInstanceId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type)
  is
    --curseur pour parcourir les instances de process
    cursor crProcInst(aProcessInstanceId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type)
    is
      select     PRI.*
            from WFL_PROCESS_INSTANCES PRI
           where PRI.WFL_PROCESS_INSTANCES_ID = aProcessInstanceId
      for update;

    tplProcInst crProcInst%rowtype;

    --curseur pour parcourir les instances d'activités
    cursor crActInst(aProcessInstanceId in WFL_ACTIVITY_INSTANCES.WFL_PROCESS_INSTANCES_ID%type)
    is
      select     AIN.*
            from WFL_ACTIVITY_INSTANCES AIN
           where AIN.WFL_PROCESS_INSTANCES_ID = aProcessInstanceId
      for update;

    --curseur pour parcourir les sous-process des instances d'activités
    cursor crSubProcInst(aActivityInstanceId in WFL_PROCESS_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type)
    is
      select PRI.*
        from WFL_PROCESS_INSTANCES PRI
       where PRI.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;

    --curseur pour parcourir les transitions liées aux instances d'activités
    cursor crTransInst(aActivityInstanceId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type)
    is
      select     *
            from WFL_TRANSITION_INSTANCES TRI
           where TRI.WFL_FROM_ACTIVITY_INSTANCES_ID = aActivityInstanceId
              or TRI.WFL_TO_ACTIVITY_INSTANCES_ID = aActivityInstanceId
      for update;

    cOldSection PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection => 'WFL_WORKFLOW_MANAGEMENT : procedure MoveToArchive', aRecordId => aProcessInstanceId);
    DebugLog(aLogText   => 'Start' || chr(10) || ' params : ' || chr(10) || 'aProcessInstanceId => '
                           || aProcessInstanceId);

    --sortie de la procédure si le flag est désactivé
    if not WFL_WORKFLOW_MANAGEMENT.FArchive then
      DebugLog(aLogText => 'WFL_WORKFLOW_MANAGEMENT.FArchive = False, no archiving');
      goto End_MoveToArchive;
    end if;

    --insertion dans les logs des instances de process, suppression dans table courante
    open crProcInst(aProcessInstanceId => aProcessInstanceId);

    fetch crProcInst
     into tplProcInst;

    if crProcInst%notfound then
      DebugLog(aLogText    => 'Process instance with ProcInstId ' || aProcessInstanceId || ' not found'
             , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
              );
      Raise_Application_Error(-20130
                            , 'WFL_WORKFLOW_MANAGEMENT.MoveToArchive: ' ||
                              'Process instance with ProcInstId ' ||
                              aProcessInstanceId ||
                              'not found'
                             );
    end if;

    close crProcInst;

    --insertion de l'instance du process dans la table de log
    DebugLog(aLogText => 'Moving ProcessInstance with ProcessInstanceId ' || aProcessInstanceId || ' to archive');

    insert into WFL_PROCESS_INST_LOG
                (WFL_PROCESS_INST_LOG_ID
               , PC_WFL_PARTICIPANTS_ID
               , WFL_ACTIVITY_INST_LOG_ID
               , WFL_PROCESSES_ID
               , PC_OBJECT_ID
               , PRI_TABNAME
               , PRI_REC_ID
               , PRI_DATE_CREATED
               , PRI_DATE_STARTED
               , PRI_DATE_ENDED
               , C_WFL_PROCESS_STATE
               , PRI_REMARKS
               , PRI_SHOW_PROC
               , A_DATECRE
               , A_IDCRE
                )
         values (tplProcInst.WFL_PROCESS_INSTANCES_ID
               , tplProcInst.PC_WFL_PARTICIPANTS_ID
               , tplProcInst.WFL_ACTIVITY_INSTANCES_ID
               , tplProcInst.WFL_PROCESSES_ID
               , tplProcInst.PC_OBJECT_ID
               , tplProcInst.PRI_TABNAME
               , tplProcInst.PRI_REC_ID
               , tplProcInst.PRI_DATE_CREATED
               , tplProcInst.PRI_DATE_STARTED
               , tplProcInst.PRI_DATE_ENDED
               , tplProcInst.C_WFL_PROCESS_STATE
               , tplProcInst.PRI_REMARKS
               , tplProcInst.PRI_SHOW_PROC
               , sysdate
               , PCS.PC_PUBLIC.GetUserIni
                );

    --mise à jour des instances d'attributs
    insert into WFL_ATTRIBUTE_INST_LOG
                (WFL_PROCESS_INST_LOG_ID
               , WFL_ATTRIBUTES_ID
               , ATI_VALUE
               , A_DATECRE
               , A_IDCRE
                )
      select ATI.WFL_PROCESS_INSTANCES_ID
           , ATI.WFL_ATTRIBUTES_ID
           , ATI.ATI_VALUE
           , sysdate
           , PCS.PC_PUBLIC.GetUserIni
        from WFL_ATTRIBUTE_INSTANCES ATI
       where ATI.WFL_PROCESS_INSTANCES_ID = tplProcInst.WFL_PROCESS_INSTANCES_ID;

    delete from WFL_ATTRIBUTE_INSTANCES ATI
          where ATI.WFL_PROCESS_INSTANCES_ID = tplProcInst.WFL_PROCESS_INSTANCES_ID;

    --mise à jour des évènements de process
    insert into WFL_PROCESS_INST_EVTS_LOG
                (WFL_PROCESS_EVENTS_ID
               , WFL_PROCESS_INST_LOG_ID
               , C_WFL_PROCESS_STATE
               , C_WFL_EVENT_TIMING
               , WPV_EVENT_SEQ
               , WPI_ERROR_CODE
               , WPI_RETURNED_MESSAGE
               , WPI_EVENT_TYPE_PROPERTIES
               , A_DATECRE
               , A_IDCRE
                )
      select WPI.WFL_PROCESS_EVENTS_ID
           , WPI.WFL_PROCESS_INSTANCES_ID
           , WPI.C_WFL_PROCESS_STATE
           , WPI.C_WFL_EVENT_TIMING
           , WPI.WPV_EVENT_SEQ
           , WPI.WPI_ERROR_CODE
           , WPI.WPI_RETURNED_MESSAGE
           , WPI.WPI_EVENT_TYPE_PROPERTIES
           , sysdate
           , PCS.PC_PUBLIC.GetUserIni
        from WFL_PROCESS_INSTANCE_EVTS WPI
       where WPI.WFL_PROCESS_INSTANCES_ID = tplProcInst.WFL_PROCESS_INSTANCES_ID;

    delete from WFL_PROCESS_INSTANCE_EVTS WPI
          where WPI.WFL_PROCESS_INSTANCES_ID = tplProcInst.WFL_PROCESS_INSTANCES_ID;

    -- mise à jour des instances d'activités
    for tplActInst in crActInst(aProcessInstanceId => tplProcInst.WFL_PROCESS_INSTANCES_ID) loop
      DebugLog(aLogText   => 'Moving ActivityInstance ' ||
                             tplActInst.WFL_ACTIVITY_INSTANCES_ID ||
                             ' (' ||
                             tplActInst.WFL_PROCESSES_ID ||
                             '/' ||
                             tplActInst.WFL_ACTIVITIES_ID ||
                             ') to archive'
              );

      --insertion des instances d'activité dans le log
      insert into WFL_ACTIVITY_INST_LOG
                  (WFL_ACTIVITY_INST_LOG_ID
                 , WFL_PROCESS_INST_LOG_ID
                 , WFL_ACTIVITIES_ID
                 , WFL_PROCESSES_ID
                 , PC_WFL_PARTICIPANTS_ID
                 , AIN_DATE_CREATED
                 , AIN_DATE_STARTED
                 , AIN_DATE_ENDED
                 , WFL_DEADLINES_ID
                 , AIN_DATE_DUE
                 , C_WFL_ACTIVITY_STATE
                 , AIN_REMARKS
                 , AIN_WORKLIST_DISPLAY
                 , AIN_VALIDATION_REQUIRED
                 , AIN_VALIDATED_BY
                 , AIN_VALIDATION_DATE
                 , AIN_GUESTS_AUTHORIZED
                 , AIN_EMAILTO_PARTICIPANTS
                 , AIN_OBJECT_START_REQUIRED
                 , AIN_OBJECT_START_DATE
                 , AIN_OBJECT_STARTED_BY
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (tplActInst.WFL_ACTIVITY_INSTANCES_ID
                 , tplActInst.WFL_PROCESS_INSTANCES_ID
                 , tplActInst.WFL_ACTIVITIES_ID
                 , tplActInst.WFL_PROCESSES_ID
                 , tplActInst.PC_WFL_PARTICIPANTS_ID
                 , tplActInst.AIN_DATE_CREATED
                 , tplActInst.AIN_DATE_STARTED
                 , tplActInst.AIN_DATE_ENDED
                 , tplActInst.WFL_DEADLINES_ID
                 , tplActInst.AIN_DATE_DUE
                 , tplActInst.C_WFL_ACTIVITY_STATE
                 , tplActInst.AIN_REMARKS
                 , tplActInst.AIN_WORKLIST_DISPLAY
                 , tplActInst.AIN_VALIDATION_REQUIRED
                 , tplActInst.AIN_VALIDATED_BY
                 , tplActInst.AIN_VALIDATION_DATE
                 , tplActInst.AIN_GUESTS_AUTHORIZED
                 , tplActInst.AIN_EMAILTO_PARTICIPANTS
                 , tplActInst.AIN_OBJECT_START_REQUIRED
                 , tplActInst.AIN_OBJECT_START_DATE
                 , tplActInst.AIN_OBJECT_STARTED_BY
                 , sysdate
                 , PCS.PC_PUBLIC.GetUserIni
                  );

      --déplacement des évènements des instances d'activité dans les logs
      insert into WFL_ACTIVITY_INST_EVTS_LOG
                  (WFL_ACTIVITY_EVENTS_ID
                 , WFL_ACTIVITY_INST_LOG_ID
                 , C_WFL_ACTIVITY_STATE
                 , C_WFL_EVENT_TIMING
                 , WAV_EVENT_SEQ
                 , WAI_ERROR_CODE
                 , WAI_RETURNED_MESSAGE
                 , WAI_EVENT_TYPE_PROPERTIES
                 , A_DATECRE
                 , A_IDCRE
                  )
        select WAI.WFL_ACTIVITY_EVENTS_ID
             , WAI.WFL_ACTIVITY_INSTANCES_ID
             , WAI.C_WFL_ACTIVITY_STATE
             , WAI.C_WFL_EVENT_TIMING
             , WAI.WAV_EVENT_SEQ
             , WAI.WAI_ERROR_CODE
             , WAI.WAI_RETURNED_MESSAGE
             , WAI.WAI_EVENT_TYPE_PROPERTIES
             , sysdate
             , PCS.PC_PUBLIC.GetUserIni
          from WFL_ACTIVITY_INSTANCE_EVTS WAI
         where WAI.WFL_ACTIVITY_INSTANCES_ID = tplActInst.WFL_ACTIVITY_INSTANCES_ID;

      delete from WFL_ACTIVITY_INSTANCE_EVTS WAI
            where WAI.WFL_ACTIVITY_INSTANCES_ID = tplActInst.WFL_ACTIVITY_INSTANCES_ID;

      --déplacement des processus enfants(sous-process ?)
      for tplSubProcInst in crSubProcInst(aActivityInstanceId => tplActInst.WFL_ACTIVITY_INSTANCES_ID) loop
        DebugLog(aLogText => 'Moving SubProcessInstance ' || tplSubProcInst.WFL_PROCESS_INSTANCES_ID || ' to archive');
        WFL_WORKFLOW_MANAGEMENT.MoveToArchive(aProcessInstanceId => tplSubProcInst.WFL_PROCESS_INSTANCES_ID);
      end loop;

      --mise à jour des transitions
      for tplTransInst in crTransInst(aActivityInstanceId => tplActInst.WFL_ACTIVITY_INSTANCES_ID) loop
        begin
          DebugLog(aLogText   => 'Moving TransitionInstance (From ' ||
                                 tplTransInst.WFL_FROM_ACTIVITY_INSTANCES_ID ||
                                 ' to ' ||
                                 tplTransInst.WFL_TO_ACTIVITY_INSTANCES_ID ||
                                 ') to archive'
                  );

          insert into WFL_TRANSITION_INST_LOG
                      (WFL_FROM_ACTIVITY_INST_LOG_ID
                     , WFL_TO_ACTIVITY_INST_LOG_ID
                     , WFL_FROM_PROCESSES_ID
                     , WFL_FROM_ACTIVITIES_ID
                     , WFL_TO_PROCESSES_ID
                     , WFL_TO_ACTIVITIES_ID
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (tplTransInst.WFL_FROM_ACTIVITY_INSTANCES_ID
                     , tplTransInst.WFL_TO_ACTIVITY_INSTANCES_ID
                     , tplTransInst.WFL_FROM_PROCESSES_ID
                     , tplTransInst.WFL_FROM_ACTIVITIES_ID
                     , tplTransInst.WFL_TO_PROCESSES_ID
                     , tplTransInst.WFL_TO_ACTIVITIES_ID
                     , sysdate
                     , PCS.PC_PUBLIC.GetUserIni
                      );

          delete from WFL_TRANSITION_INSTANCES TRI
                where current of crTransInst;
        exception
          when others then
            if     (sqlcode = -2291)
               and (    (instr(sqlerrm, 'WFL_TRANS_LOG_S_ACT_LOG_TO') > 0)
                    or (instr(sqlerrm, 'WFL_TRANS_LOG_S_ACT_LOG_FROM') > 0)
                   ) then
              null;
            else
              rollback;
              raise;
            end if;
        end;
      end loop;

      --mise à jour des attributs des instances d'activités
      insert into WFL_ACT_ATTRIB_INST_LOG
                  (WFL_ACTIVITY_ATTRIBUTES_ID
                 , WFL_ACTIVITY_INST_LOG_ID
                 , AAI_VALUE
                 , A_DATECRE
                 , A_IDCRE
                  )
        select AAI.WFL_ACTIVITY_ATTRIBUTES_ID
             , AAI.WFL_ACTIVITY_INSTANCES_ID
             , AAI.AAI_VALUE
             , sysdate
             , PCS.PC_PUBLIC.GetUserIni
          from WFL_ACT_ATTRIBUTE_INSTANCES AAI
         where AAI.WFL_ACTIVITY_INSTANCES_ID = tplActInst.WFL_ACTIVITY_INSTANCES_ID;

      delete from WFL_ACT_ATTRIBUTE_INSTANCES AAI
            where AAI.WFL_ACTIVITY_INSTANCES_ID = tplActInst.WFL_ACTIVITY_INSTANCES_ID;

      --mise à jour des responsables d'activités
      DebugLog(aLogText => 'Moving Performers to archive');

      insert into WFL_PERFORMERS_LOG
                  (WFL_PERFORMERS_LOG_ID
                 , WFL_WFL_PERFORMERS_LOG_ID
                 , PC_WFL_PARTICIPANTS_ID
                 , WFL_ACTIVITY_INST_LOG_ID
                 , PFM_CREATE_DATE
                 , C_WFL_PER_STATE
                 , PFM_ACCEPTED
                 , PFM_REMARKS
                 , A_DATECRE
                 , A_IDCRE
                  )
        select WFL_PERFORMERS_ID
             , WFL_WFL_PERFORMERS_ID
             , PC_WFL_PARTICIPANTS_ID
             , WFL_ACTIVITY_INSTANCES_ID
             , PFM_CREATE_DATE
             , C_WFL_PER_STATE
             , PFM_ACCEPTED
             , PFM_REMARKS
             , sysdate
             , PCS.PC_PUBLIC.GetUserIni
          from WFL_PERFORMERS PFM
         where PFM.WFL_ACTIVITY_INSTANCES_ID = tplActInst.WFL_ACTIVITY_INSTANCES_ID;

      delete from WFL_PERFORMERS PFM
            where PFM.WFL_ACTIVITY_INSTANCES_ID = tplActInst.WFL_ACTIVITY_INSTANCES_ID;
    end loop;

    --suppression des instances d'activité
    delete from WFL_ACTIVITY_INSTANCES AIN
          where AIN.WFL_PROCESS_INSTANCES_ID = tplProcInst.WFL_PROCESS_INSTANCES_ID;

    --suppression de l'instance du process
    delete from WFL_PROCESS_INSTANCES PRI
          where PRI.WFL_PROCESS_INSTANCES_ID = tplProcInst.WFL_PROCESS_INSTANCES_ID;

    <<End_MoveToArchive>>
    null;
    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
  end MoveToArchive;

  /********************** Internal BooleanToChar *****************************/
  function BooleanToChar(aBoolValue in boolean)
    return varchar2
  is
  begin
    if aBoolValue then
      return 'TRUE';
    else
      return 'FALSE';
    end if;
  end BooleanToChar;

  /********************** Internal LastActivityChecks ************************/
  procedure LastActivityChecks(
    aProcessInstanceId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  , aFoundToTransition in boolean
  , aTransitionDone    in boolean
  )
  is
    -- parcours des autres instances du process ouvertes ("actives")
    cursor crActInst(aProcessInstanceId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type)
    is
      select 1
        from WFL_ACTIVITY_INSTANCES
       where WFL_PROCESS_INSTANCES_ID = aProcessInstanceId
         and C_WFL_ACTIVITY_STATE in('NOTRUNNING', 'RUNNING', 'SUSPENDED', 'PRECREATED')
         and
             --Open states and pseudoState PRECREATED
             AIN_NEGATION = 0;

    tplActInst        crActInst%rowtype;

    -- récupération des paramètres en sortie d'un sous-process
    cursor crOutParm(
      aProcessInstanceId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
    , aProcessId         in WFL_PROCESSES.WFL_PROCESSES_ID%type
    , aActivityId        in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
    )
    is
      select ATI.ATI_VALUE
           , ATT.ATT_NAME
        from WFL_FORMAL_PARAMETERS FPA
           , WFL_ATTRIBUTE_INSTANCES ATI
           , WFL_ACTUAL_PARAMETERS APA
           , WFL_ATTRIBUTES ATT
       where FPA.WFL_ATTRIBUTES_ID = ATI.WFL_ATTRIBUTES_ID
         and FPA.C_WFL_PARAM_MODE like '%OUT'
         and APA.WFL_FORMAL_PARAMETERS_ID = FPA.WFL_FORMAL_PARAMETERS_ID
         and APA.WFL_ACTIVITIES_ID = aActivityId
         and APA.WFL_PROCESSES_ID = aProcessId
         and APA.WFL_ATTRIBUTES_ID = ATT.WFL_ATTRIBUTES_ID
         and ATI.WFL_PROCESS_INSTANCES_ID = aProcessInstanceId;

    tplOutParm        crOutParm%rowtype;
    nParentActInstId  WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type;
    nParentProcInstId WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type;
    nParentActivityId WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type;
    nParentProcessId  WFL_PROCESSES.WFL_PROCESSES_ID%type;
    cSubflowExecution WFL_ACTIVITIES.C_WFL_SUBFLOW_EXECUTION%type;
    cParentActState   WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type;
    cOldSection       PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection    => 'WFL_WORKFLOW_MANAGEMENT : procedure LastActivityChecks'
                 , aRecordId   => aProcessInstanceId
                  );
    DebugLog(aLogText   => 'Start' ||
                           chr(10) ||
                           ' params : ' ||
                           chr(10) ||
                           'aProcessInstanceId => ' ||
                           aProcessInstanceId ||
                           'aFoundToTransition => ' ||
                           BooleanToChar(aFoundToTransition) ||
                           'aTransitionDone    => ' ||
                           BooleanToChar(aTransitionDone)
            );

    -- Teste si il s'agit de la dernière activité pour completer (terminer) l'instance du process
    -- et les instances d'activité parentes si c'est possible, procédure interne
    open crActInst(aProcessInstanceId => aProcessInstanceId);

    fetch crActInst
     into tplActInst;

    if crActInst%notfound then
      -- si pas de transitions dont l'activité est l'origine dans le model de process => dernière activité => complete
      if    not aFoundToTransition
         or (    not aTransitionDone
             and FNoConditionsCompleteProcess) then
        DebugLog(aLogText   => 'Process instance completed because no to-transitions found for ActivityInstance ' ||
                               ' and package variable FNoConditionsCompleteProcess = TRUE'
                );

        --récupération de l'instance d'activité parent
        select WFL_ACTIVITY_INSTANCES_ID
          into nParentActInstId
          from WFL_PROCESS_INSTANCES
         where WFL_PROCESS_INSTANCES_ID = aProcessInstanceId;

        DebugLog(aLogText => 'Subflow of ActivityInstance ' || nParentActInstId);

        -- on met l'état du process  a completed
        update WFL_PROCESS_INSTANCES
           set C_WFL_PROCESS_STATE = 'COMPLETED'
             , PRI_DATE_ENDED = sysdate
         where WFL_PROCESS_INSTANCES_ID = aProcessInstanceId
           and C_WFL_PROCESS_STATE not like 'ABORTED'
           and C_WFL_PROCESS_STATE not like 'TERMINATED';

        if sql%found then
          WFL_WORKFLOW_UTILS.CallAfterStartProc(aProcessInstanceId => aProcessInstanceId);
        end if;

        -- si le type d'execution est asynchrone, il n'y a plus rien a faire.
        -- Sinon il faut finir l'activitant parent
        if (nParentActInstId is not null) then
          -- Synchrone
          select ACT.C_WFL_SUBFLOW_EXECUTION
               , ACT.WFL_ACTIVITIES_ID
               , ACT.WFL_PROCESSES_ID
               , AIN.C_WFL_ACTIVITY_STATE
               , AIN.WFL_PROCESS_INSTANCES_ID
            into cSubflowExecution
               , nParentActivityId
               , nParentProcessId
               , cParentActState
               , nParentProcInstId
            from WFL_ACTIVITY_INSTANCES AIN
               , WFL_ACTIVITIES ACT
           where AIN.WFL_ACTIVITIES_ID = ACT.WFL_ACTIVITIES_ID
             and AIN.WFL_PROCESSES_ID = ACT.WFL_PROCESSES_ID
             and AIN.WFL_ACTIVITY_INSTANCES_ID = nParentActInstId;

          DebugLog(aLogText => 'Synchro = ' || cParentActState);

          -- récupération des paramètres en sortie de cette instance de process
          for tplOutParm in crOutParm(aProcessInstanceId   => aProcessInstanceId
                                    , aProcessId           => nParentProcessId
                                    , aActivityId          => nParentActivityId
                                     ) loop
            -- set value
            DebugLog(aLogText   => 'Put outparm from finished subproces in ProcessInstance ' ||
                                   nParentProcInstId ||
                                   ' name ' ||
                                   tplOutParm.ATT_NAME ||
                                   ' value ' ||
                                   tplOutParm.ATI_VALUE
                    );
            WFL_WORKFLOW_MANAGEMENT.AssignProcessinstanceAttribute(aProcessInstanceId   => nParentProcInstId
                                                                 , aAttributeName       => tplOutParm.ATT_NAME
                                                                 , aAttributeValue      => tplOutParm.ATI_VALUE
                                                                  );
          end loop;

          --effacement des variables, mais pas de déplacement vers les archives encore
          CleanProcessInstance(aProcessInstanceId => aProcessInstanceId);

          -- si l'activité parent est suspendu alors il faut faire un resum et la compléter
          if (cParentActState = 'SUSPENDED') then
            DebugLog(aLogText => 'Resume and complete ActivityInstance ' || nParentActInstId);
            WFL_WORKFLOW_MANAGEMENT.ChangeActivityinstanceState
                                               (aActivityInstanceId   => nParentActInstId
                                              , aNewState             => 'RUNNING'
                                              , aParticipantId        => PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.WorkflowParticipant
                                               );
            WFL_WORKFLOW_MANAGEMENT.ChangeActivityinstanceState
                                                (aActivityInstanceId   => nParentActInstId
                                               , aNewState             => 'COMPLETED'
                                               , aParticipantId        => PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.WorkflowParticipant
                                                );
          end if;
        else
          --process tout en haut effacement des variables et mise dans l'historique
          DebugLog(aLogText   => 'Clean process instance and move it to archive (ProcessInstanceId = ' ||
                                 aProcessInstanceId ||
                                 ')'
                  );
          CleanProcessInstance(aProcessInstanceId => aProcessInstanceId);
          MoveToArchive(aProcessInstanceId => aProcessInstanceId);
        end if;
      end if;

      -- si des transitions ont été trouvées et que les conditions n'ont pas étés remplies, erreur
      if     aFoundToTransition
         and not aTransitionDone
         and not FNoConditionsCompleteProcess then
        DebugLog
            (aLogText    => 'Possible transitions exists but no condition was met. Error in application? if not, set ' ||
                            'WFL_WORKFLOW_MANAGEMENT.FNoConditionsCompleteProcess  to TRUE.'
           , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
            );
        Raise_Application_Error
          (-20140
         , 'ChangeActivityinstanceState: Possible transitions exists but
                                          no condition was met. Error in application? if not, set
                                          WFL_WORKFLOW_MANAGEMENT.FNoConditionsCompleteProcess  to TRUE.'
          );
      end if;
    end if;

    close crActInst;

    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
  end LastActivityChecks;

  /*********************** CreateProcessInstance *****************************/
  procedure CreateProcessInstance(
    aProcessId         in WFL_PROCESSES.WFL_PROCESSES_ID%type
  , aProcessInstanceId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  , aParticipantId     in WFL_PROCESS_INSTANCES.PC_WFL_PARTICIPANTS_ID%type default null
  , aObjectId          in WFL_PROCESS_INSTANCES.PC_OBJECT_ID%type default null
  , aRecordId          in WFL_PROCESS_INSTANCES.PRI_REC_ID%type default null
  )
  is
    cursor crAttribute(aProcessId in WFL_PROCESSES.WFL_PROCESSES_ID%type)
    is
      select WFL_ATTRIBUTES_ID
           , WFL_PROCESSES_ID
           , ATT_NAME
           , ATT_LENGTH
           , ATT_INITIAL_VALUE
           , ATT_KEEP
        from WFL_ATTRIBUTES
       where WFL_PROCESSES_ID = aProcessId;

    tplAttribute crAttribute%rowtype;
    cOldSection  PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection    => 'WFL_WORKFLOW_MANAGEMENT : procedure CreateProcessInstance'
                 , aRecordId   => aProcessInstanceId
                  );
    DebugLog(aLogText   => 'Start' ||
                           chr(10) ||
                           ' params : ' ||
                           chr(10) ||
                           'aProcessId            => ' ||
                           aProcessId ||
                           chr(10) ||
                           'aProcessInstanceId    => ' ||
                           aProcessInstanceId ||
                           chr(10) ||
                           'aParticipantId        => ' ||
                           aParticipantId ||
                           chr(10) ||
                           'aObjectId             => ' ||
                           aObjectId ||
                           chr(10) ||
                           'aRecordId             => ' ||
                           aRecordId
            );

    -- création nouvel instance du process
    insert into WFL_PROCESS_INSTANCES
                (WFL_PROCESS_INSTANCES_ID
               , WFL_PROCESSES_ID
               , PC_WFL_PARTICIPANTS_ID
               , PC_OBJECT_ID
               , PRI_TABNAME
               , PRI_REC_ID
               , PRI_DATE_CREATED
               , PRI_DATE_STARTED
               , PRI_DATE_ENDED
               , C_WFL_PROCESS_STATE
               , PRI_REMARKS
               , PRI_SHOW_PROC
               , PRI_ACTIVE_DEBUG
               , A_DATECRE
               , A_IDCRE
                )
      select aProcessInstanceId
           , aProcessId
           , aParticipantId
           , aObjectId
           , PRO_TABNAME
           , aRecordId
           , sysdate
           , null
           , null
           , 'NOTSTARTED'
           , null
           , PRO_SHOW_PROC
           , PRO_ACTIVE_DEBUG
           , sysdate
           , PCS.PC_PUBLIC.GetUserIni
        from WFL_PROCESSES
       where WFL_PROCESSES_ID = aProcessId;

    --créé les évènements des instances process
    DebugLog(aLogText => 'Inserting process events');

    insert into WFL_PROCESS_INSTANCE_EVTS
                (WFL_PROCESS_EVENTS_ID
               , WFL_PROCESS_INSTANCES_ID
               , C_WFL_PROCESS_STATE
               , C_WFL_EVENT_TIMING
               , WPV_EVENT_SEQ
               , WPI_EVENT_TYPE_PROPERTIES
               , A_DATECRE
               , A_IDCRE
                )
      select WPV.WFL_PROCESS_EVENTS_ID
           , aProcessInstanceId
           , WPV.C_WFL_PROCESS_STATE
           , WPV.C_WFL_EVENT_TIMING
           , WPV.WPV_EVENT_SEQ
           , WPV.WPV_EVENT_TYPE_PROPERTIES
           , sysdate
           , PCS.PC_PUBLIC.GetUserIni
        from WFL_PROCESS_EVENTS WPV
       where WPV.WFL_PROCESSES_ID = aProcessId;

    -- crée les instances des attributs avec les valeurs par défaut
    WFL_WORKFLOW_MANAGEMENT.DebugLog(aLogText => 'Assigning process instance attributes');

    for tplAttribute in crAttribute(aProcessId => aProcessId) loop
      WFL_WORKFLOW_MANAGEMENT.AssignProcessInstanceAttribute(aProcessInstanceId   => aProcessInstanceId
                                                           , aAttributeName       => tplAttribute.ATT_NAME
                                                           , aAttributeValue      => tplAttribute.ATT_INITIAL_VALUE
                                                            );
    end loop;

    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
  end CreateProcessInstance;

/*********************** StartProcess **************************************/
  procedure StartProcess(
    aProcessInstanceId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  , aParticipantId     in PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type
  )
  is
    cCurrentState WFL_PROCESS_INSTANCES.C_WFL_PROCESS_STATE%type;
    nProcessId    WFL_PROCESSES.WFL_PROCESSES_ID%type;

    --curseur pour rechercher les activités de départ(sans transition)
    cursor crActivityStart(aProcessId in WFL_PROCESSES.WFL_PROCESSES_ID%type)
    is
      select WFL_ACTIVITIES_ID
        from WFL_ACTIVITIES ACT
       where ACT.WFL_PROCESSES_ID = aProcessId
         and not exists(select 1
                          from WFL_TRANSITIONS TRA
                         where TRA.WFL_TO_PROCESSES_ID = aProcessId
                           and TRA.WFL_TO_ACTIVITIES_ID = ACT.WFL_ACTIVITIES_ID);

    -- curseur pour rechercher l'activité avec le plus petit numéro d'activité si requête retourne eof
    cursor crActivityLeast(aProcessId in WFL_PROCESSES.WFL_PROCESSES_ID%type)
    is
      select min(WFL_ACTIVITIES_ID) WFL_ACTIVITIES_ID
        from WFL_ACTIVITIES ACT
       where ACT.WFL_PROCESSES_ID = aProcessId;

    tplActivity   crActivityStart%rowtype;
    bRecFound     boolean                                          default false;
    cOldSection   PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection => 'WFL_WORKFLOW_MANAGEMENT : procedure StartProcess', aRecordId => aProcessInstanceId);
    DebugLog(aLogText   => 'Start' ||
                           chr(10) ||
                           ' params : ' ||
                           chr(10) ||
                           'aProcessInstanceId => ' ||
                           aProcessInstanceId ||
                           chr(10) ||
                           'aParticipantId     => ' ||
                           aParticipantId
            );

    -- on teste si l'instance du process existe
    select C_WFL_PROCESS_STATE
      into cCurrentState
      from WFL_PROCESS_INSTANCES
     where WFL_PROCESS_INSTANCES_ID = aProcessInstanceId;

    if (cCurrentState <> 'NOTSTARTED') then
      -- message d'erreur si le process à déjà été lancé
      DebugLog(aLogText    => 'Cannot start a process more than one time'
             , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR);
      Raise_Application_Error(-20010, 'StartProcess: Cannot start a process more than one time.');
    end if;

    --création du process et récupération process_id dans variable pour instanciation activité
    update    WFL_PROCESS_INSTANCES
          set C_WFL_PROCESS_STATE = 'RUNNING'
            , PRI_DATE_STARTED = sysdate
            , PC_WFL_PARTICIPANTS_ID = aParticipantId
        where WFL_PROCESS_INSTANCES_ID = aProcessInstanceId
    returning WFL_PROCESSES_ID
         into nProcessId;

    --création des activités de départ
    DebugLog(aLogText => 'Creating starting ActivityInstances for process');

    for tplActivity in crActivityStart(nProcessId) loop
      WFL_WORKFLOW_MANAGEMENT.CreateActivityInstance(aProcessInstanceId   => aProcessInstanceId
                                                   , aProcessId           => nProcessId
                                                   , aActivityId          => tplActivity.WFL_ACTIVITIES_ID
                                                    );
      bRecFound  := true;
    end loop;

    if not bRecFound then
      DebugLog(aLogText => 'Creating default ActivityInstance to start process');

      for tplActivity in crActivityLeast(nProcessId) loop
        WFL_WORKFLOW_MANAGEMENT.CreateActivityInstance(aProcessInstanceId   => aProcessInstanceId
                                                     , aProcessId           => nProcessId
                                                     , aActivityId          => tplActivity.WFL_ACTIVITIES_ID
                                                      );
        bRecFound  := true;
      end loop;

      --si il n'y a pas d'activités alors le process ne contient pas d'activités => erreur
      if not bRecFound then
        DebugLog(aLogText => 'No activities to start', aLogLevel => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR);
        Raise_Application_Error(-20011, 'StartProcess: No activities to start.');
      end if;
    end if;

    --traitement des exceptions en commentaires supprimés
    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
  end StartProcess;

  /*********************** Internal ProcInstTerminate ************************/
  procedure ProcInstTerminate(
    aProcessInstanceId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  , aNewState          in WFL_PROCESS_INSTANCES.C_WFL_PROCESS_STATE%type
  )
  is
    cursor crWorkItem(aProcessInstanceId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type)
    is
      select *
        from WFL_ACTIVITY_INSTANCES
       where WFL_PROCESS_INSTANCES_ID = aProcessInstanceId
         and C_WFL_ACTIVITY_STATE in('NOTRUNNING', 'CREATED');

    tplWorkItem crWorkItem%rowtype;
    cOldSection PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection => 'WFL_WORKFLOW_MANAGEMENT : procedure ProcInstTerminate');
    DebugLog(aLogText   => 'Start' ||
                           chr(10) ||
                           ' params : ' ||
                           chr(10) ||
                           'aProcessInstanceId => ' ||
                           aProcessInstanceId ||
                           chr(10) ||
                           'aNewState          => ' ||
                           aNewState
            );

    update WFL_PROCESS_INSTANCES
       set C_WFL_PROCESS_STATE = aNewState
     where WFL_PROCESS_INSTANCES_ID = aProcessInstanceId;

    --terminaison des activités avec le status NOTRUNNING, les autres doivent se terminer normalement
    DebugLog(aLogText => 'Terminating ActivityInstances');

    for tlpWorkItem in crWorkItem(aProcessInstanceId) loop
      WFL_WORKFLOW_MANAGEMENT.ChangeActivityInstanceState
                                               (aActivityInstanceId   => tplWorkItem.WFL_ACTIVITY_INSTANCES_ID
                                              , aNewState             => 'TERMINATED'
                                              , aParticipantId        => PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.WorkflowParticipant
                                               );
    end loop;

    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
  end ProcInstTerminate;

  /*********************** Internal ProcInstAbort ****************************/
  procedure ProcInstAbort(
    aProcessInstanceId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  , aNewState          in WFL_PROCESS_INSTANCES.C_WFL_PROCESS_STATE%type
  )
  is
    cursor crActInst(aProcessInstanceId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type)
    is
      select WFL_ACTIVITY_INSTANCES_ID
        from WFL_ACTIVITY_INSTANCES
       where WFL_PROCESS_INSTANCES_ID = aProcessInstanceId;

    tplActInst  crActInst%rowtype;
    cOldSection PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection => 'WFL_WORKFLOW_MANAGEMENT : procedure ProcInstAbort');
    DebugLog(aLogText   => 'Start' ||
                           chr(10) ||
                           ' params : ' ||
                           chr(10) ||
                           'aProcessInstanceId => ' ||
                           aProcessInstanceId ||
                           chr(10) ||
                           'aNewState          => ' ||
                           aNewState
            );

    --abort de l'instance de process
    update WFL_PROCESS_INSTANCES
       set C_WFL_PROCESS_STATE = aNewState
     where WFL_PROCESS_INSTANCES_ID = aProcessInstanceId;

    --fait aussi un abort sur toutes les activités ouvertes
    update WFL_ACTIVITY_INSTANCES
       set C_WFL_ACTIVITY_STATE = aNewState
         , AIN_SESSION_STATE = empty_blob()
         ,   -- suppression de l'état de la session
           AIN_DATE_ENDED = sysdate
         , AIN_REMARKS =
             substrb(AIN_REMARKS, 1, 3850) ||
             '<br>Aborted by abort on process instance on' ||
             to_char(sysdate, 'DD-MON-YYYY HH:MI:SS')
     where WFL_PROCESS_INSTANCES_ID = aProcessInstanceId;

    --fermeture des sous-process ouverts des activités
    DebugLog(aLogText => 'Aborting ActivityInstances');

    for tplActInst in crActInst(aProcessInstanceId => aProcessInstanceId) loop
      for tplProcInst in (select WFL_PROCESS_INSTANCES_ID
                            from WFL_PROCESS_INSTANCES
                           where WFL_ACTIVITY_INSTANCES_ID = tplActInst.WFL_ACTIVITY_INSTANCES_ID
                             and C_WFL_PROCESS_STATE != 'COMPLETED'
                             and C_WFL_PROCESS_STATE != 'ABORTED'
                             and C_WFL_PROCESS_STATE != 'TERMINATED') loop
        ChangeProcessInstanceState(aProcessInstanceId => tplProcInst.WFL_PROCESS_INSTANCES_ID, aNewState => 'ABORTED');
      end loop;
    end loop;

    --teste si l'activité est la dernière du process, si oui complète l'instance de process et les éventuels process parents.
    DebugLog(aLogText => 'Check if it is last activity and complete parent processes');
    WFL_WORKFLOW_MANAGEMENT.LastActivityChecks(aProcessInstanceId   => aProcessInstanceId
                                             , aFoundToTransition   => false
                                             , aTransitionDone      => false
                                              );
    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
  end ProcInstAbort;

  /*********************** ChangeProcessInstanceState ************************/
  procedure ChangeProcessInstanceState(
    aProcessInstanceId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  , aNewState          in WFL_PROCESS_INSTANCES.C_WFL_PROCESS_STATE%type
  )
  is
    cCurrentState WFL_PROCESS_INSTANCES.C_WFL_PROCESS_STATE%type;
    cOldSection   PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection    => 'WFL_WORKFLOW_MANAGEMENT : procedure ChangeProcessInstanceState'
                 , aRecordId   => aProcessInstanceId
                  );
    DebugLog(aLogText   => 'Start' ||
                           chr(10) ||
                           ' params : ' ||
                           chr(10) ||
                           'aProcessInstanceId => ' ||
                           aProcessInstanceId ||
                           chr(10) ||
                           'aNewState          => ' ||
                           aNewState
            );

    --récupération de l'état actuel
    select C_WFL_PROCESS_STATE
      into cCurrentState
      from WFL_PROCESS_INSTANCES
     where WFL_PROCESS_INSTANCES_ID = aProcessInstanceId;

    -- schéma indiquant les changements d'état autorisés
    --
    -- Etat Actuel      Nouvel état
    --
    -- Suspended        Running (actuellement pas utilisé, pas implémenté)
    -- Running          Suspended (changement d'état uniquement)
    -- Running          Aborted
    --*** Running       Completed (transition effectuée en finissant la dernière activité, pas cette procédure)
    -- Running          Terminated
    -- Suspended        Aborted
    -- Suspended        Terminated
    -- NotStarted       Aborted
    -- NotStarted       Terminated
    --*** NotStarted    Running (transition effectuée par start_process, dans cette procédure erreur)
    -- Terminated       Abort (non standard WFMC, mais nécessaire pour implémenter la semantique du abort)
    DebugLog(aLogText => 'Changing ProcessInstance state from "' || cCurrentState || '" to "' || aNewState || '"');

    if     (cCurrentState = 'SUSPENDED')
       and (aNewState = 'RUNNING') then
      --Resume ProcessInstance
      update WFL_PROCESS_INSTANCES
         set C_WFL_PROCESS_STATE = aNewState
       where WFL_PROCESS_INSTANCES_ID = aProcessInstanceId;
    elsif     (cCurrentState = 'RUNNING')
          and (aNewState = 'SUSPENDED') then
      --Suspend ProcessInstance
      update WFL_PROCESS_INSTANCES
         set C_WFL_PROCESS_STATE = aNewState
       where WFL_PROCESS_INSTANCES_ID = aProcessInstanceId;
    elsif     (cCurrentState = 'RUNNING')
          and (aNewState = 'ABORTED') then
      ProcInstAbort(aProcessInstanceId => aProcessInstanceId, aNewState => aNewState);
    elsif     (cCurrentState = 'RUNNING')
          and (aNewState = 'TERMINATED') then
      ProcInstTerminate(aProcessInstanceId => aProcessInstanceId, aNewState => aNewState);
    elsif     (cCurrentState = 'SUSPENDED')
          and (aNewState = 'ABORTED') then
      ProcInstAbort(aProcessInstanceId => aProcessInstanceId, aNewState => aNewState);
    elsif     (cCurrentState = 'SUSPENDED')
          and (aNewState = 'TERMINATED') then
      ProcInstTerminate(aProcessInstanceId => aProcessInstanceId, aNewState => aNewState);
    elsif     (cCurrentState = 'NOTSTARTED')
          and (aNewState = 'ABORTED') then
      ProcInstAbort(aProcessInstanceId => aProcessInstanceId, aNewState => aNewState);
    elsif     (cCurrentState = 'NOTSTARTED')
          and (aNewState = 'TERMINATED') then
      ProcInstTerminate(aProcessInstanceId => aProcessInstanceId, aNewState => aNewState);
    elsif     (cCurrentState = 'TERMINATED')
          and (aNewState = 'ABORTED') then
      ProcInstAbort(aProcessInstanceId => aProcessInstanceId, aNewState => aNewState);
    elsif     (cCurrentState = 'NOTSTARTED')
          and (aNewState = 'RUNNING') then
      --message d'erreur spécial dans ce cas
      DebugLog(aLogText    => 'Start a process instance with startprocess'
             , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR);
      Raise_Application_Error(-20020, 'ChangeProcessInstanceState: Start a process instance with startprocess.');
    elsif     (cCurrentState = 'ABORTED')
          and (aNewState = 'ABORTED') then
      null;   -- transition ignorée
    else
      --erreur
      DebugLog(aLogText    => 'Invalid transition from state "' ||
                              cCurrentState ||
                              '" to "' ||
                              aNewState ||
                              '"" is not possible'
             , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
              );
      Raise_Application_Error(-20021
                            , 'ChangeProcessInstanceState: Invalid transition: from ' ||
                              cCurrentState ||
                              ' to ' ||
                              aNewState ||
                              ' is not possible.'
                             );
    end if;

    --**pas de traitement d'exceptions, commentaires
    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
  end ChangeProcessInstanceState;

  /********************** Internal ActInstStart ******************************/
  procedure ActInstStart(
    aActivityInstanceId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aParticipantId      in PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type
  , aActNewState        in WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type
  )
  is
    nPerformerId WFL_PERFORMERS.WFL_PERFORMERS_ID%type;
    cOldSection  PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection => 'WFL_WORKFLOW_MANAGEMENT : procedure ActInstStart');
    DebugLog(aLogText   => 'Start' ||
                           chr(10) ||
                           ' params : ' ||
                           chr(10) ||
                           'aActivityInstanceId => ' ||
                           aActivityInstanceId ||
                           chr(10) ||
                           'aParticipantId      => ' ||
                           aParticipantId ||
                           chr(10) ||
                           'aActNewState        => ' ||
                           aActNewState
            );

    --mise à jour des personnes assignées à l'activité (si il y en a). Le participant ne peut démarrer que des activités non assignées ou assignées à lui-même
    update WFL_PERFORMERS
       set PFM_ACCEPTED = 'Y'
     where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
       and C_WFL_PER_STATE = 'ASSIGNED'
       and PFM_ACCEPTED is null;

--**    DebugLog(aLogText  => 'Updating Performers Assigned (RowCount = ' || sql%rowcount || ')');

    --changement de personne responsable si le remplacant(proxy) échoue ? (takes over)
    update    WFL_PERFORMERS
          set C_WFL_PER_STATE = 'OVERTAKEN'
        where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
          and PC_WFL_PARTICIPANTS_ID != aParticipantId
          and C_WFL_PER_STATE = 'CURRENT'
          and (   PFM_ACCEPTED is null
               or PFM_ACCEPTED = 'Y')
    returning WFL_PERFORMERS_ID
         into nPerformerId;

--**    DebugLog(aLogText  => 'Updating Performers Overtaken (RowCount = ' || sql%rowcount || ')');

    --mise à jour de la personne qui prend en charge l'activité (insert or update)
    update WFL_PERFORMERS
       set PFM_ACCEPTED = 'Y'
         , C_WFL_PER_STATE = 'CURRENT'
     where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
       and C_WFL_PER_STATE = 'CURRENT'
       and (   PFM_ACCEPTED is null
            or PFM_ACCEPTED = 'Y')
       and PC_WFL_PARTICIPANTS_ID = aParticipantId;

--**    DebugLog(aLogText  => 'Updating Performers Current (RowCount = ' || sql%rowcount || ')');
    if (sql%rowcount = 0) then
      --insertion, car aucune ligne mise à jour
      DebugLog(aLogText   => 'Inserting performer (aParticipantId = ' ||
                             PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantName(aParticipantId => aParticipantId) ||
                             ' [' ||
                             aParticipantId ||
                             ']) for ActivityInstance (ActivityInstanceId =' ||
                             aActivityInstanceId ||
                             ')'
              );

      insert into WFL_PERFORMERS
                  (WFL_PERFORMERS_ID
                 , WFL_ACTIVITY_INSTANCES_ID
                 , PC_WFL_PARTICIPANTS_ID
                 , C_WFL_PER_STATE
                 , PFM_CREATE_DATE
                 , PFM_ACCEPTED
                 , PFM_REMARKS
                 , WFL_WFL_PERFORMERS_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (WFL_PERFORMERS_SEQ.nextval
                 , aActivityInstanceId
                 , aParticipantId
                 , 'CURRENT'
                 , sysdate
                 , 'Y'
                 , null
                 , nPerformerId
                 , sysdate
                 , PCS.PC_PUBLIC.GetUserIni
                  );
    end if;

    --mise à jour du status de l'instance de l'activité
    update WFL_ACTIVITY_INSTANCES
       set C_WFL_ACTIVITY_STATE = aActNewState
         , AIN_DATE_STARTED = sysdate
     where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;

    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
  end ActInstStart;

  /********************** Internal ActInstRelease ****************************/
  procedure ActInstRelease(
    aActivityInstanceId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aParticipantId      in PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type
  , aActNewState        in WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type
  )
  is
    nHumanPartId PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type;
    dDateStarted WFL_ACTIVITY_INSTANCES.AIN_DATE_STARTED%type;
    nPerformerId WFL_PERFORMERS.WFL_PERFORMERS_ID%type;
    cOldSection  PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection => 'WFL_WORKFLOW_MANAGEMENT : procedure ActInstRelease');
    DebugLog(aLogText   => 'Start' ||
                           chr(10) ||
                           ' params : ' ||
                           chr(10) ||
                           'aActivityInstanceId => ' ||
                           aActivityInstanceId ||
                           chr(10) ||
                           'aParticipantId      => ' ||
                           aParticipantId ||
                           chr(10) ||
                           'aActNewState        => ' ||
                           aActNewState
            );

    --libérer une instance peut être utilisé pour que l'activité réaparaisse dans les worklists
    --récupérer le responsable de l'activité si il s'agit d'une personne
    select PFM.PC_WFL_PARTICIPANTS_ID
         , AIN.AIN_DATE_STARTED
         , PFM.WFL_PERFORMERS_ID
      into nHumanPartId
         , dDateStarted
         , nPerformerId
      from WFL_ACTIVITY_INSTANCES AIN
         , WFL_PERFORMERS PFM
     where AIN.WFL_ACTIVITY_INSTANCES_ID = PFM.WFL_ACTIVITY_INSTANCES_ID
       and PFM.C_WFL_PER_STATE = 'CURRENT'   -- seul responsable courant
       and PFM.PFM_ACCEPTED = 'Y'
       and AIN.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;

    -- libère le responsable (etat released), uniquement pour historique
    update WFL_PERFORMERS
       set C_WFL_PER_STATE = 'RELEASED'
     where WFL_PERFORMERS_ID = nPerformerId;

    --met l'état de l'activité à l'état avant que l'utilisateur ne l'accepte
    --NB: le record dans performer n'est pas supprimé, donc la requête de la worklist ne doit pas afficher la dernière personne
    --ayant pris en charge l'activité
    update WFL_ACTIVITY_INSTANCES
       set C_WFL_ACTIVITY_STATE = aActNewState
         , AIN_DATE_STARTED = null
         , AIN_REMARKS =
             substrb(AIN_REMARKS, 1, 3700) ||
             '<br>Released by PC_WFL_PARTICIPANTS_ID' ||
             aParticipantId ||
             ' on ' ||
             to_char(sysdate, 'DD-MON-YYYY HH:MI:SS') ||
             '<br>(originally started by PC_WFL_PARTICIPANTS_ID)' ||
             nHumanPartId ||
             ' on ' ||
             to_char(dDateStarted, 'DD-MON-YYYY HH:MI:SS') ||
             ')'
     where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;

    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
  end ActInstRelease;

  /********************** Internal ActInstResume *****************************/
  procedure ActInstResume(
    aActivityInstanceId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aParticipantId      in PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type
  , aActNewState        in WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type
  )
  is
    nPerformerId WFL_PERFORMERS.WFL_PERFORMERS_ID%type;
    cOldSection  PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection => 'WFL_WORKFLOW_MANAGEMENT : procedure ActInstResume');
    DebugLog(aLogText   => 'Start' ||
                           chr(10) ||
                           ' params : ' ||
                           chr(10) ||
                           'aActivityInstanceId => ' ||
                           aActivityInstanceId ||
                           chr(10) ||
                           'aParticipantId      => ' ||
                           aParticipantId ||
                           chr(10) ||
                           'aActNewState        => ' ||
                           aActNewState
            );

    update WFL_ACTIVITY_INSTANCES
       set C_WFL_ACTIVITY_STATE = aActNewState
         , AIN_SESSION_STATE = empty_blob()
         , AIN_REMARKS = substrb(AIN_REMARKS, 1, 3900) || '<br>Resumed on ' || to_char(sysdate, 'DD-MON-YYYY HH:MI:SS')
     where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;

    --changement de la personne qui prend en charge, dans le cas d'un remplacant
    update    WFL_PERFORMERS
          set C_WFL_PER_STATE = 'OVERTAKEN'
        where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
          and PC_WFL_PARTICIPANTS_ID != aParticipantId
          and C_WFL_PER_STATE = 'CURRENT'
          and (   PFM_ACCEPTED is null
               or PFM_ACCEPTED = 'Y')
    returning WFL_PERFORMERS_ID
         into nPerformerId;

    --création ou mise à jour du record de la personne ayant pris en charge l'activité
    update WFL_PERFORMERS
       set PFM_ACCEPTED = 'Y'
         , C_WFL_PER_STATE = 'CURRENT'
     where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
       and C_WFL_PER_STATE = 'CURRENT'
       and (   PFM_ACCEPTED is null
            or PFM_ACCEPTED = 'Y')
       and PC_WFL_PARTICIPANTS_ID = aParticipantId;

    if (sql%rowcount = 0) then
      --insertion, car aucune ligne mise à jour
      DebugLog(aLogText   => 'Inserting performer (aParticipantId = ' ||
                             PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantName(aParticipantId => aParticipantId) ||
                             ' [' ||
                             aParticipantId ||
                             ']) for ActivityInstance (ActivityInstanceId =' ||
                             aActivityInstanceId ||
                             ')'
              );

      insert into WFL_PERFORMERS
                  (WFL_PERFORMERS_ID
                 , WFL_ACTIVITY_INSTANCES_ID
                 , PC_WFL_PARTICIPANTS_ID
                 , C_WFL_PER_STATE
                 , PFM_CREATE_DATE
                 , PFM_ACCEPTED
                 , PFM_REMARKS
                 , WFL_WFL_PERFORMERS_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (WFL_PERFORMERS_SEQ.nextval
                 , aActivityInstanceId
                 , aParticipantId
                 , 'CURRENT'
                 , sysdate
                 , 'Y'
                 , null
                 , nPerformerId
                 , sysdate
                 , PCS.PC_PUBLIC.GetUserIni
                  );
    end if;

    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
  end ActInstResume;

  /********************** Internal ActInstComplete ***************************/
  procedure ActInstComplete(
    aActivityInstanceId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aActNewState        in WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type
  )
  is
    --curseur pour parcourir les transitions sortantes (vers)
    cursor crTransitionsOut(
      aProcessId  in WFL_PROCESSES.WFL_PROCESSES_ID%type
    , aActivityId in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
    )
    is
      select   TRA.WFL_TO_ACTIVITIES_ID
             , TRA.TRA_CONDITION
             , TRA.C_WFL_CONDITION_TYPE
             , decode(TRA.C_WFL_CONDITION_TYPE, 'OTHERWISE', 1, 0) as OtherwiseOrderLast
          from WFL_TRANSITIONS TRA
         where TRA.WFL_FROM_PROCESSES_ID = aProcessId
           and TRA.WFL_FROM_ACTIVITIES_ID = aActivityId
           and (   TRA.C_WFL_CONDITION_TYPE is null
                or TRA.C_WFL_CONDITION_TYPE != 'EXCEPTION')
      order by OtherwiseOrderLast;

    --curseur pour parcourir les transitions entrantes pour une activité définie
    cursor crTransInstFromAct(
      aProcessId       in WFL_PROCESSES.WFL_PROCESSES_ID%type
    , aToActivityId    in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
    , aFromActivityId  in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
    , aToActInstanceId in WFL_TRANSITION_INSTANCES.WFL_TO_ACTIVITY_INSTANCES_ID%type
    )
    is
      select TRI.WFL_FROM_ACTIVITY_INSTANCES_ID
           , TRI.WFL_TO_ACTIVITY_INSTANCES_ID
        from WFL_TRANSITION_INSTANCES TRI
       where TRI.WFL_TO_ACTIVITY_INSTANCES_ID = aToActInstanceId
         and TRI.WFL_FROM_PROCESSES_ID = aProcessId
         and TRI.WFL_TO_PROCESSES_ID = aProcessId
         and TRI.WFL_FROM_ACTIVITIES_ID = aFromActivityId
         and TRI.WFL_TO_ACTIVITIES_ID = aToActivityId;

    tplTransInstFromAct  crTransInstFromAct%rowtype;

    -- récupère toutes les transitions entrantes pour une activité donnée, utilisé pour savoir si toutes les in-transitions d'un AND-JOIN sont finies
    cursor crValidTransitionsIn(
      aToActInstanceId in WFL_TRANSITION_INSTANCES.WFL_TO_ACTIVITY_INSTANCES_ID%type
    , aToActivityId    in WFL_TRANSITIONS.WFL_TO_ACTIVITIES_ID%type
    , aProcessId       in WFL_TRANSITION_INSTANCES.WFL_FROM_PROCESSES_ID%type
    )
    is
      select TRI.*
        from WFL_TRANSITIONS TRA
           , WFL_TRANSITION_INSTANCES TRI
       where TRA.WFL_TO_PROCESSES_ID = aProcessId
         and TRA.WFL_TO_ACTIVITIES_ID = aToActivityId
         and (   TRA.C_WFL_CONDITION_TYPE is null
              or TRA.C_WFL_CONDITION_TYPE != 'EXCEPTION')
         and TRI.WFL_TO_ACTIVITY_INSTANCES_ID(+) = aToActInstanceId
         and TRI.WFL_FROM_ACTIVITIES_ID(+) = TRA.WFL_FROM_ACTIVITIES_ID
         and TRI.WFL_TO_ACTIVITIES_ID(+) = TRA.WFL_TO_ACTIVITIES_ID
         and TRI.WFL_FROM_PROCESSES_ID(+) = TRA.WFL_FROM_PROCESSES_ID
         and TRI.WFL_TO_PROCESSES_ID(+) = TRA.WFL_TO_PROCESSES_ID;

    -- récupère toutes les transitions sortantes pour une activité donnée
    cursor crValidTransitionsOut(
      aFromActInstanceId in WFL_TRANSITION_INSTANCES.WFL_TO_ACTIVITY_INSTANCES_ID%type
    , aFromActivityId    in WFL_TRANSITIONS.WFL_FROM_ACTIVITIES_ID%type
    , aProcessId         in WFL_TRANSITION_INSTANCES.WFL_FROM_PROCESSES_ID%type
    )
    is
      select TRI.WFL_TO_ACTIVITY_INSTANCES_ID
           , TRI.WFL_TO_ACTIVITIES_ID
           , TRI.TRI_NEGATION
           , ACT.C_WFL_JOIN
        from WFL_TRANSITION_INSTANCES TRI
           , WFL_ACTIVITIES ACT   --next activity
       where ACT.WFL_PROCESSES_ID = aProcessId
         and ACT.WFL_ACTIVITIES_ID = TRI.WFL_TO_ACTIVITIES_ID
         and TRI.WFL_FROM_ACTIVITY_INSTANCES_ID = aFromActInstanceId
         and TRI.WFL_FROM_ACTIVITIES_ID = aFromActivityId;

    -- récupère les dernières instances de transitions et activités créées pour les supprimer
    cursor crDelTransitionsOut(aFromActInstanceId in WFL_TRANSITION_INSTANCES.WFL_FROM_ACTIVITY_INSTANCES_ID%type)
    is
      select     TRI.*
            from WFL_TRANSITION_INSTANCES TRI
               , WFL_TRANSITIONS TRA
           where TRI.WFL_FROM_ACTIVITY_INSTANCES_ID = aFromActInstanceId
             and TRA.WFL_FROM_ACTIVITIES_ID = TRI.WFL_FROM_ACTIVITIES_ID
             and TRA.WFL_FROM_PROCESSES_ID = TRI.WFL_FROM_PROCESSES_ID
             and TRA.WFL_TO_ACTIVITIES_ID = TRI.WFL_TO_ACTIVITIES_ID
             and TRA.WFL_TO_PROCESSES_ID = TRI.WFL_TO_PROCESSES_ID
             and (   TRA.C_WFL_CONDITION_TYPE is null
                  or TRA.C_WFL_CONDITION_TYPE != 'EXCEPTION')
      for update;

    --Cherche toutes les activités AND-JOIN qui sont en attente de threads pour se compléter
    cursor crActInst(
      aActivityId        in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITIES_ID%type
    , aProcessInstanceId in WFL_ACTIVITY_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
    )
    is
      select AIN.WFL_ACTIVITY_INSTANCES_ID
           , AIN.WFL_ACTIVITIES_ID
        from WFL_ACTIVITY_INSTANCES AIN
       where AIN.WFL_ACTIVITIES_ID = aActivityId
         and WFL_PROCESS_INSTANCES_ID = aProcessInstanceId
         and C_WFL_ACTIVITY_STATE = 'NOTRUNNING';

    cCurrentSplit        WFL_ACTIVITIES.C_WFL_SPLIT%type;
    nCurrentActivityId   WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type;
    nCurrentProcessId    WFL_PROCESSES.WFL_PROCESSES_ID%type;
    nCurrentProcInstId   WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type;
    bCurrentNegation     WFL_ACTIVITY_INSTANCES.AIN_NEGATION%type;
    bConditionEvaluation boolean                                                 default false;   -- peut-t'on réaliser cette transition (fired ?)
    bHasRealTransition   boolean                                                 default false;   -- existe-t'il une transition réelle depuis cette inst. d'activité
    bHasValidTransition  boolean                                                 default false;   -- existe-t'il une transition évalué à "TRUE"
    bFireActInst         boolean                                                 default false;   -- L'instance d'activité peut être démarrée ?
    bTransitionDone      boolean                                                 default false;   -- True si transition effectuée. (pour recherche last activity)
    nNewToActInstanceId  WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type;   -- l'instance d'activité liée à l'instance de transition
    bTransNegation       WFL_TRANSITION_INSTANCES.TRI_NEGATION%type;   -- S'agit-t'il d'une vrai transition ('N') ou "faked" ('Y')
    bActInstNegation     WFL_TRANSITION_INSTANCES.TRI_NEGATION%type;   -- est-ce qu'il s'agit d'une activité normale ('N') ou "faked" ('Y')
    nNumOfConditions     pls_integer;
    nToTransitionFound   pls_integer                                             default 0;   -- détemine si il s'agit de last acitivity, et teste si un AND-SPLIT a des transitions multiples.
    bActAttribute        boolean;
    bProcAttribute       boolean;
    cOldSection          PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection => 'WFL_WORKFLOW_MANAGEMENT : procedure ActInstComplete');
    DebugLog(aLogText   => 'Start' ||
                           chr(10) ||
                           ' params : ' ||
                           chr(10) ||
                           'aActivityInstanceId => ' ||
                           aActivityInstanceId ||
                           chr(10) ||
                           'aActNewState        => ' ||
                           aActNewState
            );

    --compléter l'instance de l'activité, comme ca les descendants pour continuer le workflow
    update WFL_ACTIVITY_INSTANCES
       set C_WFL_ACTIVITY_STATE = aActNewState
         , AIN_SESSION_STATE = empty_blob()
         , AIN_DATE_ENDED = sysdate
         , AIN_REMARKS = substrb(AIN_REMARKS, 1, 3900) || 'Completed on ' || to_char(sysdate, 'DD-MON-YYYY HH:MI:SS')
     where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;

    --récupération des informations de l'activité(split,...)
    select ACT.C_WFL_SPLIT
         , AIN.WFL_ACTIVITIES_ID
         , ACT.WFL_PROCESSES_ID
         , AIN.WFL_PROCESS_INSTANCES_ID
         , AIN.AIN_NEGATION
      into cCurrentSplit
         , nCurrentActivityId
         , nCurrentProcessId
         , nCurrentProcInstId
         , bCurrentNegation
      from WFL_ACTIVITIES ACT
         , WFL_ACTIVITY_INSTANCES AIN
     where ACT.WFL_ACTIVITIES_ID = AIN.WFL_ACTIVITIES_ID
       and ACT.WFL_PROCESSES_ID = AIN.WFL_PROCESSES_ID
       and AIN.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;

    DebugLog(aLogText   => 'ActivityInstanceId ' ||
                           aActivityInstanceId ||
                           ' of (activity ' ||
                           nCurrentProcessId ||
                           '/' ||
                           nCurrentActivityId ||
                           ') has completed. Checking transitions out...'
            );

    -- boucle sur les activités sortantes depuis l'instance d'activité en paramètre
    for tplTransitionsOut in crTransitionsOut(aProcessId => nCurrentProcessId, aActivityId => nCurrentActivityId) loop
      nToTransitionFound    := nToTransitionFound + 1;

      if     (nToTransitionFound > 1)
         and (cCurrentSplit is null) then
        DebugLog(aLogText    => 'Error: there is more than one outgoing transition of activity ' ||
                                nCurrentProcessId ||
                                '/' ||
                                nCurrentActivityId ||
                                ' but the split type is NULL. It should be ''AND'' or ''XOR''.'
               , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
                );
        Raise_Application_Error
           (-20030
          , 'WFL_WORKFLOW_MANAGEMENT.ActInstComplete: Error: there is more than one outgoing transition of activity ' ||
            nCurrentProcessId ||
            ' ' ||
            nCurrentActivityId ||
            ' but the split type is NULL. It should be ''AND'' or ''XOR''.'
           );
      end if;

      bConditionEvaluation  := false;   -- initialisé après la boucle

      if (bCurrentNegation = 1) then
        bConditionEvaluation  := true;
        DebugLog(aLogText   => 'faked transition ' ||
                               nCurrentActivityId ||
                               '->' ||
                               tplTransitionsOut.WFL_TO_ACTIVITIES_ID ||
                               ' evaluates to true'
                );
      elsif    (nvl(length(tplTransitionsOut.TRA_CONDITION), 0) = 0)
            or (tplTransitionsOut.C_WFL_CONDITION_TYPE is null) then
        --pas de condition évalué a True
        bConditionEvaluation  := true;
        DebugLog(aLogText   => 'Transition ' ||
                               nCurrentActivityId ||
                               '->' ||
                               tplTransitionsOut.WFL_TO_ACTIVITIES_ID ||
                               ' with no condition evaluates to true'
                );
      elsif(tplTransitionsOut.C_WFL_CONDITION_TYPE = 'OTHERWISE') then
        if not bHasValidTransition then
          bConditionEvaluation  := true;
          Debuglog(aLogText   => 'Otherwise transition ' ||
                                 nCurrentActivityId ||
                                 '->' ||
                                 tplTransitionsOut.WFL_TO_ACTIVITIES_ID ||
                                 ' evaluates to true'
                  );
        end if;
      elsif(tplTransitionsOut.C_WFL_CONDITION_TYPE = 'CONDITION') then
        --la condition contient une partie de la requête sql et doit être lancée pour être vérifiée
        --lorsqu'il y a plusieurs conditions dans le champ TRA_CONDITION (compter le nbre de or dans le string), alors toutes ces conditions
        --doivent être remplies
        bConditionEvaluation  :=
          WFL_WORKFLOW_MANAGEMENT.EvaluateCondition(aTraCondition         => tplTransitionsOut.TRA_CONDITION
                                                  , aActivityInstanceId   => aActivityInstanceId
                                                  , aProcessInstanceId    => nCurrentProcInstId
                                                   );
        DebugLog(aLogText   => 'Condition transition ' ||
                               nCurrentActivityId ||
                               '->' ||
                               tplTransitionsOut.WFL_TO_ACTIVITIES_ID ||
                               ' evaluates to ' ||
                               lower(BooleanToChar(bConditionEvaluation) )
                );
      else
        DebugLog(aLogText    => 'Unknown transition condition type ' ||
                                tplTransitionsOut.C_WFL_CONDITION_TYPE ||
                                ' and condition ' ||
                                tplTransitionsOut.TRA_CONDITION
               , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
                );
        Raise_Application_Error(-20031
                              , 'WFL_WORKFLOW_MANAGEMENT.ActInstComplete: Unknown transition condition type ' ||
                                tplTransitionsOut.C_WFL_CONDITION_TYPE ||
                                ' and condition ' ||
                                tplTransitionsOut.TRA_CONDITION
                               );
      end if;

      -- Réalise la transition et crée une nouvelle instance de transition
      if    (cCurrentSplit = 'AND')
         or bConditionEvaluation then
        --crée l'arc et l'instance d'activité connectée. Si la condition n'est pas remplie, mais que le split est du type AND,
        --alors on créée les arcs/Transitions "faked" pour synchroniser le AND-Join.

        --si le split est du type XOR, la transition est réalisée exclusivement. La première transition valide est choisie(répond aux critères aussi).
        if     (cCurrentSplit = 'XOR')
           and bHasValidTransition then
          if (bCurrentNegation = 1) then
            --si "faked", alors juste prendre un de ces XORs. ici on met null, comme ca toujours évalué à True.
            null;
          end if;

          --ne plus créer d'autres instances de transitions
          Debuglog(aLogText   => 'XOR has already fired. Skipping transition ' ||
                                 nCurrentActivityId ||
                                 '->' ||
                                 tplTransitionsOut.WFL_TO_ACTIVITIES_ID
                  );
          exit;
        end if;

        nNewToActInstanceId  := null;

        --teste si il existe déjà une instance d'activité à connecter à l'instance de la transition.(si la cible est un AND-Join, les autres transitions
        --peuvent avoir déjà créer les instances d'activités). Une activité peut avoir des instances multiples dans un process à cause des boucles. Si
        --l'instance d'activité trouvé à déjà un arc depuis l'activité courante, l'instance ne peut pas être utilisée(déjà utilisé par une autre boucle).
        for tplActInst in crActInst(aActivityId          => tplTransitionsOut.WFL_TO_ACTIVITIES_ID
                                  , aProcessInstanceId   => nCurrentProcInstId
                                   ) loop
          open crTransInstFromAct(aProcessId         => nCurrentProcessId
                                , aToActivityId      => tplActInst.WFL_ACTIVITIES_ID
                                , aFromActivityId    => nCurrentActivityId
                                , aToActInstanceId   => tplActInst.WFL_ACTIVITY_INSTANCES_ID
                                 );

          fetch crTransInstFromAct
           into tplTransInstFromAct;

          if crTransInstFromAct%notfound then
            --utilise cette instance d'activité
            nNewToActInstanceId  := tplActInst.WFL_ACTIVITY_INSTANCES_ID;
            DebugLog(aLogText => 'using target ActivityInstance with id ' || nNewToActInstanceId);

            close crTransInstFromAct;

            exit;
          end if;

          close crTransInstFromAct;
        end loop;

        if (nNewToActInstanceId is null) then
          --si il n'y a plus d'instance d'activité à connecter à l'instance de transition, il faut en créer en état "PRECREATED"
          insert into WFL_ACTIVITY_INSTANCES
                      (WFL_ACTIVITY_INSTANCES_ID
                     , WFL_PROCESS_INSTANCES_ID
                     , WFL_PROCESSES_ID
                     , WFL_ACTIVITIES_ID
                     , AIN_DATE_CREATED
                     , AIN_DATE_STARTED
                     , AIN_DATE_ENDED
                     , WFL_DEADLINES_ID
                     , AIN_DATE_DUE
                     , C_WFL_ACTIVITY_STATE
                     , AIN_REMARKS
                     , AIN_WORKLIST_DISPLAY
                     , AIN_SESSION_STATE
                     , AIN_NEGATION
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (WFL_ACTIVITY_INSTANCES_SEQ.nextval
                     , nCurrentProcInstId
                     , nCurrentProcessId
                     , tplTransitionsOut.WFL_TO_ACTIVITIES_ID
                     , sysdate
                     , null
                     , null
                     , null
                     , null
                     , 'PRECREATED'
                     , null
                     , null
                     , empty_blob()
                     , bCurrentNegation
                     , sysdate
                     , PCS.PC_PUBLIC.GetUserIni
                      )
            returning WFL_ACTIVITY_INSTANCES_ID
                 into nNewToActInstanceId;

          Debuglog(aLogText   => 'Created target ActivityInstance (state = "PRECREATED") with ID '
                                 || nNewToActInstanceId);

          --création des instances d'évènements pour l'activité en cours
          insert into WFL_ACTIVITY_INSTANCE_EVTS
                      (WFL_ACTIVITY_EVENTS_ID
                     , WFL_ACTIVITY_INSTANCES_ID
                     , C_WFL_ACTIVITY_STATE
                     , C_WFL_EVENT_TIMING
                     , WAV_EVENT_SEQ
                     , WAI_EVENT_TYPE_PROPERTIES
                     , A_DATECRE
                     , A_IDCRE
                      )
            select WAV.WFL_ACTIVITY_EVENTS_ID
                 , nNewToActInstanceId
                 , WAV.C_WFL_ACTIVITY_STATE
                 , WAV.C_WFL_EVENT_TIMING
                 , WAV.WAV_EVENT_SEQ
                 , WAV.WAV_EVENT_TYPE_PROPERTIES
                 , sysdate
                 , PCS.PC_PUBLIC.GetUserIni
              from WFL_ACTIVITY_EVENTS WAV
             where WAV.WFL_ACTIVITIES_ID = tplTransitionsOut.WFL_TO_ACTIVITIES_ID;
        end if;

        -- création de l'instance de transition
        if     bConditionEvaluation
           and (bCurrentNegation = 0) then
          bTransNegation      := 0;
          bHasRealTransition  := true;

          --si l'instance d'activité à été créée avant comme "fake", maintenant il faut la rendre réelle.(sinon cleanprocessinstance génère
          --une erreur lors du processabort, parce qu'il y a des arcs réels connectés à des instances d'activité "fake")
          update WFL_ACTIVITY_INSTANCES
             set AIN_NEGATION = 0
           where WFL_ACTIVITY_INSTANCES_ID = nNewToActInstanceId;
        else
          bTransNegation  := 1;
        end if;

        insert into WFL_TRANSITION_INSTANCES
                    (WFL_FROM_PROCESSES_ID
                   , WFL_FROM_ACTIVITIES_ID
                   , WFL_TO_PROCESSES_ID
                   , WFL_TO_ACTIVITIES_ID
                   , WFL_FROM_ACTIVITY_INSTANCES_ID
                   , WFL_TO_ACTIVITY_INSTANCES_ID
                   , TRI_NEGATION
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (nCurrentProcessId
                   , nCurrentActivityId
                   , nCurrentProcessId
                   , tplTransitionsOut.WFL_TO_ACTIVITIES_ID
                   , aActivityInstanceId
                   , nNewToActInstanceId
                   , bTransNegation
                   , sysdate
                   , PCS.PC_PUBLIC.GetUserIni
                    );

        --une transition a été créée. Si il s'agit d'un split XOR, ca signifie que aucune autre transition n'est autorisée
        bHasValidTransition  := true;
        DebugLog(aLogText   => 'Created fake =' ||
                               bTransNegation ||
                               ' transition ' ||
                               nCurrentActivityId ||
                               '->' ||
                               tplTransitionsOut.WFL_TO_ACTIVITIES_ID
                );
      end if;
    end loop;

    --les instances d'activités, transitions ont été créées/initialisées. Ceci doit arriver avant d'effectuer les transitions, sinon l'activité
    --courante peut finir et croire qu'il s'agit de la dernière instance d'activité et tout déplacer dans les tables de log, alors que la fonction
    --a encore d'autres transitions à traîter. On peut terminer les instances de transitions, activités si l'instance d'activité est "faked" ou si
    --il existe au moins une transition réelle. Sinon il faut finir les éléments "faked" dans une boucle.
    if    (bCurrentNegation = 1)
       or bHasRealTransition then
      for tplValidTransitionsOut in crValidTransitionsOut(aFromActInstanceId   => aActivityInstanceId
                                                        , aFromActivityId      => nCurrentActivityId
                                                        , aProcessId           => nCurrentProcessId
                                                         ) loop
        if    (tplValidTransitionsOut.C_WFL_JOIN = 'XOR')
           or (tplValidTransitionsOut.C_WFL_JOIN is null) then
          --xor signifie: la première transition qui est évaluée a True est utilisé.
          --Null signifie: C'est la seule transition, donc on doit l'utiliser.

          -- mise à jour du flag, car au moins une instance de transition est présente
          DebugLog(aLogText => 'Activate bFireActInst with Join = "XOR" or "null"');
          bFireActInst      := true;
          bActInstNegation  := tplValidTransitionsOut.TRI_NEGATION;
        else
          --teste pour l'instance de l'activité si toutes les transitions ont une instance
          --l'instance de l'activité est "faked" si toutes les transitions entrantes sont "fake" ou
          --si il manque des instances de transitions entrantes
          bActInstNegation  := 1;
          bFireActInst      := true;

          for tplValidTransitionsIn in
            crValidTransitionsIn(aToActInstanceId   => tplValidTransitionsOut.WFL_TO_ACTIVITY_INSTANCES_ID
                               , aToActivityId      => tplValidTransitionsOut.WFL_TO_ACTIVITIES_ID
                               , aProcessId         => nCurrentProcessId
                                ) loop
            if (tplValidTransitionsIn.WFL_TO_ACTIVITY_INSTANCES_ID is null) then
              --il manque des instances de transition, donc on ne peut pas compléter l'activité
              DebugLog(aLogText => 'Desactivate bFireActInst, because ActivityInstanceId is null');
              bFireActInst      := false;
              bActInstNegation  := 1;
              exit;
            end if;

            if (tplValidTransitionsIn.TRI_NEGATION = 0) then
              bActInstNegation  := 0;
            end if;
          end loop;
        end if;

        --si toutes les conditions sont trouvées, alors finir les instances d'activité
        if bFireActInst then
          if (bActInstNegation = 0) then
            --crée les instances d'activité qui ont été initialisées avant avec l'état "PRECREATED"
            WFL_WORKFLOW_MANAGEMENT.CreateActivityInstance
                                            (aProcessInstanceId    => nCurrentProcInstId
                                           , aProcessId            => nCurrentProcessId
                                           , aActivityId           => tplValidTransitionsOut.WFL_TO_ACTIVITIES_ID
                                           , aActivityInstanceId   => tplValidTransitionsOut.WFL_TO_ACTIVITY_INSTANCES_ID
                                            );
          else
            --toutes les instances de transitions sont "faked", on met l'état à running et on complète l'activité (faked, on continue dans cet état)
            update WFL_ACTIVITY_INSTANCES
               set C_WFL_ACTIVITY_STATE = 'RUNNING'
                 , AIN_NEGATION = 1
             where WFL_ACTIVITY_INSTANCES_ID = tplValidTransitionsOut.WFL_TO_ACTIVITY_INSTANCES_ID;

            WFL_WORKFLOW_MANAGEMENT.ChangeActivityInstanceState
                                            (aActivityInstanceId   => tplValidTransitionsOut.WFL_TO_ACTIVITY_INSTANCES_ID
                                           , aNewState             => 'COMPLETED'
                                           , aParticipantId        => PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.WorkflowParticipant
                                            );
          end if;

          bTransitionDone  := true;
          DebugLog(aLogText   => ' Fired ActivtyInstance ' ||
                                 tplValidTransitionsOut.WFL_TO_ACTIVITY_INSTANCES_ID ||
                                 ' as fake:' ||
                                 bActInstNegation
                  );
        else
          --suppression de l'état PRECREATED; on sait maintenant qu'il faut créer les instances d'activités, car des transitions valides existent
          --mais le flag negation peut être actif...
          update WFL_ACTIVITY_INSTANCES
             set C_WFL_ACTIVITY_STATE = 'NOTRUNNING'
               , AIN_NEGATION = bActInstNegation
           where WFL_ACTIVITY_INSTANCES_ID = tplValidTransitionsOut.WFL_TO_ACTIVITY_INSTANCES_ID;

          DebugLog(aLogText   => ' ActivityInstance ' ||
                                 tplValidTransitionsOut.WFL_TO_ACTIVITY_INSTANCES_ID ||
                                 ' cannot fire (not all threads ready)'
                  );
        end if;
      end loop;
    else
      --il n'y a pas de transitions réelles qui partent depuis cette instance d'activité complétée. On doit arrêter et supprimer les arc "faked"
      --et les instances d'activités PRECREATED.
      DebugLog(aLogText   => 'No real and valid transitions starting from ' ||
                             aActivityInstanceId ||
                             '. deleting transition instances and Activity Instances created'
              );

      for tplDelTransitionsOut in crDelTransitionsOut(aFromActInstanceId => aActivityInstanceId) loop
        nNewToActInstanceId  := tplDelTransitionsOut.WFL_TO_ACTIVITY_INSTANCES_ID;

        --suppression arc
        delete from WFL_TRANSITION_INSTANCES
              where current of crDelTransitionsOut;

        --suppression instance d'activité
        begin
          delete from WFL_ACTIVITY_INSTANCES
                where WFL_ACTIVITY_INSTANCES_ID = nNewToActInstanceId;
        exception
          when others then
            if     (sqlcode = -2292)
               and (instr(sqlerrm, 'WFL_TRANS_INST_S_INST_ACT') > 0) then
              --ORA-02292: contrainte d'intégrité sur la foreign key(WFL_TRANS_INST_S_INST_ACT_TO). Cette instance d'activité n'a pas été créée dans cette exécution.
              null;
            else
              rollback;
              raise;
            end if;
        end;
      end loop;
    end if;

    --teste si il s'agit de la dernière activité dans le process et si oui, complète l'instance du process et les processus parents eventuels.
    --NB: Rien n'est fait si une transition doit s'effectuer. Les autres instances d'activité complèteront le process.
    DebugLog(aLogText   => 'Checking if ActivityInstance ' ||
                           aActivityInstanceId ||
                           'is the last of ProcessInstance ' ||
                           nCurrentProcInstId
            );
    WFL_WORKFLOW_MANAGEMENT.LastActivityChecks(aProcessInstanceId   => nCurrentProcInstId
                                             , aFoundToTransition   => (nToTransitionFound > 0)
                                             , aTransitionDone      => bTransitionDone
                                              );
    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
  end ActInstComplete;

  /********************** Internal ActInstAbort ******************************/
  procedure ActInstAbort(
    aActivityInstanceId WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aParticipantId      PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type
  , aActNewState        WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type
  )
  is
    nProcessInstanceId WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type;
    cOldSection        PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection => 'WFL_WORKFLOW_MANAGEMENT : procedure ActInstAbort');
    DebugLog(aLogText   => 'Start' ||
                           chr(10) ||
                           ' params : ' ||
                           chr(10) ||
                           'aActivityInstanceId => ' ||
                           aActivityInstanceId ||
                           chr(10) ||
                           'aParticipantId      => ' ||
                           aParticipantId ||
                           chr(10) ||
                           'aActNewState        => ' ||
                           aActNewState
            );

    -- abort de l'instance d'activité
    update    WFL_ACTIVITY_INSTANCES
          set C_WFL_ACTIVITY_STATE = aActNewState
            , AIN_SESSION_STATE = empty_blob()
            , AIN_DATE_ENDED = sysdate
            , AIN_REMARKS =
                substrb(AIN_REMARKS, 1, 3850) ||
                '<br>Aborted by ParticipantId ' ||
                aParticipantID ||
                ' on ' ||
                to_char(sysdate, 'DD-MON-YYYY HH:MI:SS')
        where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
    returning WFL_PROCESS_INSTANCES_ID
         into nProcessInstanceId;

    -- abort des sous process
    for tplProcInst in (select WFL_PROCESS_INSTANCES_ID
                          from WFL_PROCESS_INSTANCES
                         where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
                           and C_WFL_PROCESS_STATE != 'COMPLETED'
                           and C_WFL_PROCESS_STATE != 'ABORTED'
                           and C_WFL_PROCESS_STATE != 'TERMINATED') loop
      DebugLog(aLogText => 'Aborting SubProcesses');
      ChangeProcessInstanceState(aProcessInstanceId => tplProcInst.WFL_PROCESS_INSTANCES_ID, aNewState => 'ABORTED');
    end loop;

    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
  end ActInstAbort;

  /********************** Internal ActInstTerminate **************************/
  procedure ActInstTerminate(
    aActivityInstanceId WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aParticipantId      PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type
  , aActNewState        WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type
  )
  is
    nProcessInstanceId WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type;
    cOldSection        PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection => 'WFL_WORKFLOW_MANAGEMENT : procedure ActInstTerminate');
    DebugLog(aLogText   => 'Start' ||
                           chr(10) ||
                           ' params : ' ||
                           chr(10) ||
                           'aActivityInstanceId => ' ||
                           aActivityInstanceId ||
                           chr(10) ||
                           'aParticipantId      => ' ||
                           aParticipantId ||
                           chr(10) ||
                           'aActNewState        => ' ||
                           aActNewState
            );

    update    WFL_ACTIVITY_INSTANCES
          set C_WFL_ACTIVITY_STATE = aActNewState
            , AIN_SESSION_STATE = empty_blob()
            , AIN_DATE_ENDED = sysdate
            , AIN_REMARKS =
                substrb(AIN_REMARKS, 1, 3850) ||
                '<br>Terminated by PC_WFL_PARTICIPANTS_ID ' ||
                aParticipantId ||
                ' on ' ||
                to_char(sysdate, 'DD-MON-YYYY HH:MI:SS')
        where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
    returning WFL_PROCESS_INSTANCES_ID
         into nProcessInstanceId;

    DebugLog('Checking if ActivityInstance ' ||
             aActivityInstanceId ||
             ' is the last of ProcessInstance ' ||
             nProcessInstanceId
            );
    -- teste si il s'agit de la dernière activité, si c'est le cas, complète l'instance du process et parents
    WFL_WORKFLOW_MANAGEMENT.LastActivityChecks(aProcessInstanceId   => nProcessInstanceId
                                             , aFoundToTransition   => false
                                             , aTransitionDone      => false
                                              );
    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
  end ActInstTerminate;

  /********************** ChangeActivityInstanceState ************************/
  procedure ChangeActivityInstanceState(
    aActivityInstanceId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aNewState           in WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type
  , aParticipantId      in PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type
  )
  is
    --Curseur pour récupérer la personne courante chargée d'une activité
    cursor crPerformer(aActivityInstanceId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type)
    is
      select PFM.PC_WFL_PARTICIPANTS_ID
        from WFL_PERFORMERS PFM
       where PFM.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
         and PFM.C_WFL_PER_STATE = 'CURRENT'
         and (   PFM.PFM_ACCEPTED is null
              or PFM.PFM_ACCEPTED <> 'N');

    tplPerformer       crPerformer%rowtype;
    cCurrentState      WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type;
    cProcessState      WFL_PROCESS_INSTANCES.C_WFL_PROCESS_STATE%type;
    cActNewState       WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type;
    nPartPerfId        PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type          default null;
    bIsProxyOf         integer                                                      default 0;   -- pour récupérer résultat IsProxyOf
    nDummy             integer;   -- Dummy pour "select into construct"
    nRoleParticipantId WFL_ACTIVITY_INSTANCES.PC_WFL_PARTICIPANTS_ID%type;
    nExcludePartId     WFL_ACTIVITY_INSTANCES.PC_WFL_EXCLUDE_PARTICIPANTS_ID%type;
    nProcInstId        WFL_ACTIVITY_INSTANCES.WFL_PROCESS_INSTANCES_ID%type;
    cOldSection        PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --récupération identifiant processus
    select WFL_PROCESS_INSTANCES_ID
      into nProcInstId
      from WFL_ACTIVITY_INSTANCES
     where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;

    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection    => 'WFL_WORKFLOW_MANAGEMENT : procedure ChangeActivityInstanceState'
                 , aRecordId   => nProcInstId
                  );
    DebugLog(aLogText   => 'Start' ||
                           chr(10) ||
                           ' params : ' ||
                           chr(10) ||
                           'aActivityInstanceId => ' ||
                           aActivityInstanceId ||
                           chr(10) ||
                           'aNewState           => ' ||
                           aNewState ||
                           chr(10) ||
                           'aParticipantId      => ' ||
                           aParticipantId
            );

    --seul les personnes et le system peuvent changer l'état d'une activité
    if     not PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.ParticipantIsType(aParticipantId, 'HUMAN')
       and not PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.ParticipantIsType(aParticipantId, 'SYSTEM') then
      DebugLog(aLogText    => 'Only HUMAN and SYSTEM participants may act on workitems.'
             , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
              );
      Raise_Application_Error
        (-20033
       , 'WFL_WORKFLOW_MANAGEMENT.ChangeActivityInstanceState: Only HUMAN and SYSTEM participants may act on workitems.'
        );
    end if;

    -- récupération de l'état des instances d'activité et process
    select PRI.C_WFL_PROCESS_STATE
         , AIN.C_WFL_ACTIVITY_STATE
         , AIN.PC_WFL_PARTICIPANTS_ID
         , AIN.PC_WFL_EXCLUDE_PARTICIPANTS_ID
      into cProcessState
         , cCurrentState
         , nRoleParticipantId
         , nExcludePartId
      from WFL_ACTIVITY_INSTANCES AIN
         , WFL_PROCESS_INSTANCES PRI
     where AIN.WFL_PROCESS_INSTANCES_ID = PRI.WFL_PROCESS_INSTANCES_ID
       and AIN.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;

    --récupère le responsable courant si il existe
    open crPerformer(aActivityInstanceId => aActivityInstanceId);

    fetch crPerformer
     into tplPerformer;

    if crPerformer%found then
      nPartPerfId  := tplPerformer.PC_WFL_PARTICIPANTS_ID;
      Debuglog(aLogText   => 'Getting ActivityPerformer, value = ' ||
                             PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantName(aParticipantId => nPartPerfId) ||
                             ' [' ||
                             nPartPerfId ||
                             ']'
              );
    end if;

    -- le participant ne doit pas être un remplacant si il libère, suspend ou démarre le process
    if    (nPartPerfId is not null)
       or (aParticipantId <> PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.WorkflowParticipant) then
      bIsProxyOf  :=
        PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.IsProxyOf(aProxyParticipantId   => aParticipantId
                                                  , aHumanParticipantId   => nPartPerfId
                                                   );

      --interdit le changement quand les participants sont différents et que le participant n'a pas les droits pour changer
      if     (    (aNewState = 'NOTRUNNING')
              or (aNewState = 'RUNNING')
              or (aNewState = 'SUSPENDED') )
         and (nPartPerfId <> aParticipantId)
         and (bIsProxyOf = 0) then
        DebugLog(aLogText    => 'Only the assigned participant can perform this change'
               , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
                );
        Raise_Application_Error
          (-20034
         , 'WFL_WORKFLOW_MANAGEMENT.ChangeActivityInstanceState: Only the assigned participant can perform this change.'
          );
      end if;
    end if;

    -- teste si le participant à le rôle nécessaire au changement de rôle (NotRunning => Running)
    if     (cCurrentState = 'NOTRUNNING')
       and (aNewState = 'RUNNING')
       and (aParticipantId <> PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.WorkflowParticipant) then
      -- changement autorisé si le role est une personne égale a aParticipantId
      if    (    PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.ParticipantIsType(nRoleParticipantId, 'HUMAN')
             and (nRoleParticipantId = aParticipantId)
            )
         or (nRoleParticipantId is null) then
        null;
      else
        --teste si le role de l'activié a les roles du participant
        begin
          Debuglog
              (aLogText   => 'About testing if user ' ||
                             PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantName(aParticipantId => aParticipantId) ||
                             ' [' ||
                             aParticipantId ||
                             '] has role ' ||
                             PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantName
                                                                                (aParticipantId   => nRoleParticipantId) ||
                             ' [' ||
                             nRoleParticipantId ||
                             ']'
              );

          execute immediate 'SELECT 1
             FROM TABLE(PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetRights(:PARTICIPANT_ID))
             WHERE COLUMN_VALUE = :ROLE_PARTICIPANT_ID'
                       into nDummy
                      using aParticipantId, nRoleParticipantId;
        exception
          --une exception de type No_Data_Found signifie que le participant n'a pas le rôle adéquat
          when no_data_found then
            DebugLog
              (aLogText    => 'Participant ' ||
                              PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantName(aParticipantId => aParticipantId) ||
                              ' [' ||
                              aParticipantId ||
                              '] is not granted the required role ' ||
                              PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantName
                                                                                (aParticipantId   => nRoleParticipantId) ||
                              ' [' ||
                              nRoleParticipantId ||
                              '] to perform this activity'
             , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
              );
            Raise_Application_Error(-20035
                                  , 'WFL_WORKFLOW_MANAGEMENT.ChangeActivityInstanceState: Participant ' ||
                                    aParticipantId ||
                                    ' is not granted the required role ' ||
                                    nRoleParticipantId ||
                                    ' to perform this activity.'
                                   );
        end;
      end if;

      --teste si le participant est exclu pour acomplir cette instance d'activité
      if     (nExcludePartId is not null)
         and (nExcludePartId = nRoleParticipantId) then
        DebugLog(aLogText    => 'Participant ' ||
                                PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantName
                                                                                    (aParticipantId   => aParticipantId) ||
                                ' [' ||
                                aParticipantId ||
                                '] is prohibited to perform this activity'
               , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
                );
        raise_application_error(-20037
                              , 'WFL_WORKFLOW_MANAGEMENT.ChangeActivityInstanceState: Participant ' ||
                                aParticipantId ||
                                ' is prohibited to perform this activity.'
                               );
      end if;
    end if;

    -- si l'activité est en attente de terminaison et que le nouvel état <> ABORT, alors nouvel état = TERMINATED
    cActNewState         := aNewState;

    if     (cProcessState = 'TERMINATED')
       and (aNewState <> 'ABORTED') then
      cActNewState  := 'TERMINATED';
    end if;

    -- transition Autorisées
    -- NB: voir wfmc spécification (http://www.wfmc.org/standards/docs/if2v20.pdf) p170 pour les transitions autorisées
    --
    -- Etat courant      Nouvel état
    --
    -- NotRunning        running
    -- Notrunning        Suspended   ???
    -- Notrunning        Aborted
    -- Notrunning        Terminated
    -- Running           NotRunning
    -- Running           Suspended
    -- Running           Completed
    -- Running           Aborted
    -- Running           Terminated
    -- Suspended         NotRunning
    -- Suspended         Running
    -- Suspended         Aborted
    -- Suspended         Terminated
    --
    -- Terminated        Aborted     ---- en dehors standard WFMC
    Debuglog(aLogText   => 'Changing state of ActivityInstance ' ||
                           aActivityInstanceId ||
                           ' from "' ||
                           cCurrentState ||
                           '" to "' ||
                           cActNewState ||
                           '"'
            );

    if     (cCurrentState = 'NOTRUNNING')
       and (cActNewState = 'RUNNING') then
      ActInstStart(aActivityInstanceId   => aActivityInstanceId
                 , aParticipantId        => aParticipantId
                 , aActNewState          => cActNewState
                  );
    --elsif (cCurrentState = 'NOTRUNNING') and (cActNewState = 'SUSPENDED') then
       /**
      update WFL_ACTIVITY_INSTANCES
         set C_WFL_ACTIVITY_STATE = cActNewState
           , AIN_REMARKS =
                         substrb(AIN_REMARKS, 1, 3900) || '<br>Suspended on '
                         || to_char(sysdate, 'DD-MON-YYYY HH:MI:SS')
       where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;
        */
    elsif     (cCurrentState = 'NOTRUNNING')
          and (cActNewState = 'ABORTED') then
      ActInstAbort(aActivityInstanceId   => aActivityInstanceId
                 , aParticipantId        => aParticipantId
                 , aActNewState          => cActNewState
                  );
    elsif     (cCurrentState = 'NOTRUNNING')
          and (cActNewState = 'TERMINATED') then
      ActInstTerminate(aActivityInstanceId   => aActivityInstanceId
                     , aParticipantId        => aParticipantId
                     , aActNewState          => cActNewState
                      );
    elsif     (cCurrentState = 'RUNNING')
          and (cActNewState = 'NOTRUNNING') then
      ActInstRelease(aActivityInstanceId   => aActivityInstanceId
                   , aParticipantId        => aParticipantId
                   , aActNewState          => cActNewState
                    );
    elsif     (cCurrentState = 'RUNNING')
          and (cActNewState = 'SUSPENDED') then
      DebugLog(aLogText => 'Suspending ActivityInstance ' || aActivityInstanceId);

      update WFL_ACTIVITY_INSTANCES
         set C_WFL_ACTIVITY_STATE = cActNewState
           , AIN_REMARKS =
                         substrb(AIN_REMARKS, 1, 3900) || '<br>Suspended on '
                         || to_char(sysdate, 'DD-MON-YYYY HH:MI:SS')
       where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;
    elsif     (cCurrentState = 'RUNNING')
          and (cActNewState = 'COMPLETED') then
      ActInstComplete(aActivityInstanceId => aActivityInstanceId, aActNewState => cActNewState);
    elsif     (cCurrentState = 'RUNNING')
          and (cActNewState = 'ABORTED') then
      ActInstAbort(aActivityInstanceId   => aActivityInstanceId
                 , aParticipantId        => aParticipantId
                 , aActNewState          => cActNewState
                  );
    elsif     (cCurrentState = 'RUNNING')
          and (cActNewState = 'TERMINATED') then
      ActInstTerminate(aActivityInstanceId   => aActivityInstanceId
                     , aParticipantId        => aParticipantId
                     , aActNewState          => cActNewState
                      );
    elsif     (cCurrentState = 'SUSPENDED')
          and (cActNewState = 'NOTRUNNING') then
      ActInstRelease(aActivityInstanceId   => aActivityInstanceId
                   , aParticipantId        => aParticipantId
                   , aActNewState          => cActNewState
                    );
    elsif     (cCurrentState = 'SUSPENDED')
          and (cActNewState = 'RUNNING') then
      ActInstResume(aActivityInstanceId   => aActivityInstanceId
                  , aParticipantId        => aParticipantId
                  , aActNewState          => cActNewState
                   );
    elsif     (cCurrentState = 'SUSPENDED')
          and (cActNewState = 'ABORTED') then
      ActInstAbort(aActivityInstanceId   => aActivityInstanceId
                 , aParticipantId        => aParticipantId
                 , aActNewState          => cActNewState
                  );
    elsif     (cCurrentState = 'SUSPENDED')
          and (cActNewState = 'TERMINATED') then
      ActInstTerminate(aActivityInstanceId   => aActivityInstanceId
                     , aParticipantId        => aParticipantId
                     , aActNewState          => cActNewState
                      );
    elsif     (cCurrentState = 'TERMINATED')
          and (cActNewState = 'ABORTED') then
      ActInstAbort(aActivityInstanceId   => aActivityInstanceId
                 , aParticipantId        => aParticipantId
                 , aActNewState          => cActNewState
                  );
    else
      --erreur
      DebugLog(aLogText    => 'ActivityInstanceId ' ||
                              aActivityInstanceId ||
                              ': transition from ' ||
                              cCurrentState ||
                              ' to ' ||
                              cActNewState ||
                              ' is not possible'
             , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
              );
      Raise_Application_Error(-20036
                            , 'WFL_WORKFLOW_MANAGEMENT.ChangeActivityInstanceState(' ||
                              aActivityInstanceId ||
                              '):
                               Invalid transition: from ' ||
                              cCurrentState ||
                              ' to ' ||
                              cActNewState ||
                              ' is not possible.'
                             );
    end if;

    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
  end ChangeActivityInstanceState;

  /********************** Assign ProcessInstanceAttribute ********************/
  procedure AssignProcessInstanceAttribute(
    aProcessInstanceId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  , aAttributeName     in WFL_ATTRIBUTES.ATT_NAME%type
  , aAttributeValue    in WFL_ATTRIBUTE_INSTANCES.ATI_VALUE%type
  )
  is
    cNewValue    WFL_ATTRIBUTE_INSTANCES.ATI_VALUE%type;
    nAttributeId WFL_ATTRIBUTES.WFL_ATTRIBUTES_ID%type;
    cDataType    WFL_ATTRIBUTES.C_WFL_DATA_TYPE%type;
    nAttLength   WFL_ATTRIBUTES.ATT_LENGTH%type;
    cOldSection  PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection    => 'WFL_WORKFLOW_MANAGEMENT : procedure AssignProcessInstanceAttribute'
                 , aRecordId   => aProcessInstanceId
                  );
    DebugLog(aLogText   => 'Start' ||
                           chr(10) ||
                           ' params : ' ||
                           chr(10) ||
                           'aProcessInstanceId => ' ||
                           aProcessInstanceId ||
                           chr(10) ||
                           'aAttributeName     => ' ||
                           aAttributeName ||
                           chr(10) ||
                           'aAttributeValue    => ' ||
                           aAttributeValue
            );

    --récupération des infos sur l'attribut d'après son nom
    begin
      select WFL_ATTRIBUTES_ID
           , C_WFL_DATA_TYPE
           , ATT_LENGTH
        into nAttributeId
           , cDataType
           , nAttLength
        from WFL_ATTRIBUTES
       where ATT_NAME = aAttributeName
         and WFL_PROCESSES_ID = (select WFL_PROCESSES_ID
                                   from WFL_PROCESS_INSTANCES
                                  where WFL_PROCESS_INSTANCES_ID = aProcessInstanceId);
    exception
      when no_data_found then
        DebugLog(aLogText    => 'Unknown process attribute name ' || aAttributeName
               , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
                );
        Raise_Application_Error
                           (-20040
                          , 'WFL_WORKFLOW_MANAGEMENT.AssignProcessInstanceAttribute: Unknown process attribute name ' ||
                            aAttributeName
                           );
    end;

    --contrôle du type de données
    if (cDataType = 'INTEGER') then
      cNewValue  := to_char(to_number(aAttributeValue) );   -- Erreur ORA-01722 si ce n'est pas un nombre
    elsif(cDataType = 'BOOLEAN') then
      cNewValue  := upper(aAttributeValue);

      if     (cNewValue <> 'TRUE')
         and (cNewValue <> 'FALSE')
         and (cNewValue <> 0)
         and (cNewValue <> 1) then
        DebugLog(aLogText    => 'Attribute ' ||
                                aAttributeName ||
                                ' (type = Boolean) with value ' ||
                                aAttributeValue ||
                                ' is not TRUE or FALSE'
               , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
                );
        Raise_Application_Error(-20041
                              , 'WFL_WORKFLOW_MANAGEMENT.AssignProcessInstanceAttribute: ' ||
                                aAttributeValue ||
                                ' is not TRUE or FALSE.'
                               );
      end if;
    elsif(cDataType = 'CHARACTER') then
      if (length(aAttributeValue) > nAttLength) then
        DebugLog(aLogText    => 'The predefined max. length of attribute ' ||
                                aAttributeName ||
                                ' is smaller than the length of "' ||
                                aAttributeValue ||
                                '"'
               , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
                );
        Raise_Application_Error
                  (-20042
                 , 'WFL_WORKFLOW_MANAGEMENT.AssignProcessInstanceAttribute: The predefined max. length of attribute ' ||
                   nAttributeId ||
                   ' is smaller than the length of "' ||
                   aAttributeValue ||
                   '".'
                  );
      end if;

      cNewValue  := aAttributeValue;
    end if;

    if (length(cNewValue) is null) then
      --suppression si valeur nulle
      DebugLog(aLogText => 'Deleting AttributeInstance if new value is null');

      delete from WFL_ATTRIBUTE_INSTANCES
            where WFL_ATTRIBUTES_ID = nAttributeId
              and WFL_PROCESS_INSTANCES_ID = aProcessInstanceId;
    else
      --mise à jour
      DebugLog(aLogText => 'Updating AttributeInstance with new value');

      update WFL_ATTRIBUTE_INSTANCES
         set ATI_VALUE = cNewValue
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_PUBLIC.GetUserIni
       where WFL_ATTRIBUTES_ID = nAttributeId
         and WFL_PROCESS_INSTANCES_ID = aProcessInstanceId;

      --si aucun record n'a été mis à jour alors insertion nouvel élément
      if (sql%rowcount = 0) then
        DebugLog(aLogText => 'Inserting AttributeInstance new value');

        insert into WFL_ATTRIBUTE_INSTANCES
                    (WFL_ATTRIBUTES_ID
                   , WFL_PROCESS_INSTANCES_ID
                   , ATI_VALUE
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (nAttributeId
                   , aProcessInstanceId
                   , cNewValue
                   , sysdate
                   , PCS.PC_PUBLIC.GetUserIni
                    );
      end if;
    end if;

    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
  end AssignProcessInstanceAttribute;

  /********************** AssignActInstAttrib ********************************/
  procedure AssignActInstAttrib(
    aActivityInstanceId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aActAttribName      in WFL_ACTIVITY_ATTRIBUTES.ACA_NAME%type
  , aActAttribInstValue in WFL_ACT_ATTRIBUTE_INSTANCES.AAI_VALUE%type
  )
  is
    cNewValue            WFL_ACT_ATTRIBUTE_INSTANCES.AAI_VALUE%type;
    nActivityAttributeId WFL_ACTIVITY_ATTRIBUTES.WFL_ACTIVITY_ATTRIBUTES_ID%type;
    cDataType            WFL_ACTIVITY_ATTRIBUTES.C_WFL_DATA_TYPE%type;
    nAcaLength           WFL_ACTIVITY_ATTRIBUTES.ACA_LENGTH%type;
    nProcInstId          WFL_ACTIVITY_INSTANCES.WFL_PROCESS_INSTANCES_ID%type;
    cOldSection          PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --récupération identifiant processus
    select WFL_PROCESS_INSTANCES_ID
      into nProcInstId
      from WFL_ACTIVITY_INSTANCES
     where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;

    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection => 'WFL_WORKFLOW_MANAGEMENT : procedure AssignActInstAttrib', aRecordId => nProcInstId);
    DebugLog(aLogText   => 'Start' ||
                           chr(10) ||
                           ' params : ' ||
                           chr(10) ||
                           'aActivityInstanceId => ' ||
                           aActivityInstanceId ||
                           chr(10) ||
                           'aActAttribName      => ' ||
                           aActAttribName ||
                           chr(10) ||
                           'aActAttribInstValue => ' ||
                           aActAttribInstValue
            );

    -- récupération des informations sur l'attribut d'après le nom
    begin
      select ACA.WFL_ACTIVITY_ATTRIBUTES_ID
           , ACA.C_WFL_DATA_TYPE
           , ACA.ACA_LENGTH
        into nActivityAttributeId
           , cDataType
           , nAcaLength
        from WFL_ACTIVITY_ATTRIBUTES ACA
           , WFL_ACTIVITY_INSTANCES AIN
       where ACA.ACA_NAME = aActAttribName
         and AIN.WFL_ACTIVITIES_ID = ACA.WFL_ACTIVITIES_ID
         and AIN.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;
    exception
      when no_data_found then
        DebugLog(aLogText    => 'Unknown activity attribute name ' || aActAttribName
               , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
                );
        Raise_Application_Error(-20050
                              , 'WFL_WORKFLOW_MANAGEMENT.AssignActInstAttrib: Unknown activity attribute name ' ||
                                aActAttribName ||
                                '.'
                               );
    end;

    --contrôle du type de données
    if (cDataType = 'INTEGER') then
      cNewValue  := to_char(to_number(aActAttribInstValue) );   -- Erreur ORA-01722 si ce n'est pas un nombre
    elsif(cDataType = 'BOOLEAN') then
      cNewValue  := upper(aActAttribInstValue);

      if     (cNewValue <> 'TRUE')
         and (cNewValue <> 'FALSE') then
        DebugLog(aLogText    => 'Attribute ' ||
                                aActAttribName ||
                                ' (type = Boolean) with value ' ||
                                aActAttribInstValue ||
                                ' is not TRUE or FALSE'
               , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
                );
        Raise_Application_Error(-20051
                              , 'WFL_WORKFLOW_MANAGEMENT.AssignActInstAttrib: ' ||
                                aActAttribInstValue ||
                                ' is not TRUE or FALSE.'
                               );
      end if;
    elsif(cDataType = 'CHARACTER') then
      if (length(aActAttribInstValue) > nAcaLength) then
        DebugLog(aLogText    => 'The predefined max. length of attribute ' ||
                                aActAttribName ||
                                ' (Length = ' ||
                                nAcaLength ||
                                ') is smaller than the length of "' ||
                                aActAttribInstValue ||
                                '"'
               , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
                );
        Raise_Application_Error(-20052
                              , 'WFL_WORKFLOW_MANAGEMENT.AssignActInstAttrib: ' ||
                                aActAttribInstValue ||
                                ' is bigger than max length ' ||
                                nAcaLength
                               );
      end if;

      cNewValue  := aActAttribInstValue;
    end if;

    --mise à jour ou création instance d'attribut
    DebugLog(aLogText => 'Updating ActivityAttributeInstance with new value');

    update WFL_ACT_ATTRIBUTE_INSTANCES
       set AAI_VALUE = cNewValue
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_PUBLIC.GetUserIni
     where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
       and WFL_ACTIVITY_ATTRIBUTES_ID = nActivityAttributeId;

    --aucun record trouvé, donc création
    if (sql%rowcount = 0) then
      DebugLog(aLogText => 'Inserting ActivityAttributeInstance new value');

      insert into WFL_ACT_ATTRIBUTE_INSTANCES
                  (WFL_ACTIVITY_ATTRIBUTES_ID
                 , WFL_ACTIVITY_INSTANCES_ID
                 , AAI_VALUE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (nActivityAttributeId
                 , aActivityInstanceId
                 , cNewValue
                 , sysdate
                 , PCS.PC_PUBLIC.GetUserIni
                  );
    end if;

    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
  end AssignActInstAttrib;

  /********************** AddProcessInstanceRemarks **************************/
  procedure AddProcessInstanceRemarks(
    aProcessInstanceId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  , aRemarks           in WFL_PROCESS_INSTANCES.PRI_REMARKS%type
  )
  is
    cRemarks    varchar2(9000);
    cOldSection PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection    => 'WFL_WORKFLOW_MANAGEMENT : procedure AddProcessInstanceRemarks'
                 , aRecordId   => aProcessInstanceId
                  );
    DebugLog(aLogText   => 'Start' ||
                           chr(10) ||
                           ' params : ' ||
                           chr(10) ||
                           'aProcessInstanceId => ' ||
                           aProcessInstanceId ||
                           chr(10) ||
                           'aRemarks           => ' ||
                           aRemarks
            );

    --pour éviter des problèmes de concatenation
    select PRI_REMARKS
      into cRemarks
      from WFL_PROCESS_INSTANCES
     where WFL_PROCESS_INSTANCES_ID = aProcessInstanceId;

    cRemarks             := cRemarks || aRemarks;
    --mise à jour de la remarque pour l'instance de process
    DebugLog(aLogText => 'Updating process remarks');

    update WFL_PROCESS_INSTANCES
       set PRI_REMARKS = substrb(cRemarks, 1, 4000)
     where WFL_PROCESS_INSTANCES_ID = aProcessInstanceId;

    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
  end AddProcessInstanceRemarks;

  /********************** AddActivityInstanceRemarks *************************/
  procedure AddActivityInstanceRemarks(
    aActivityInstanceId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aRemarks            in WFL_ACTIVITY_INSTANCES.AIN_REMARKS%type
  )
  is
    cRemarks    varchar2(9000);
    nProcInstId WFL_ACTIVITY_INSTANCES.WFL_PROCESS_INSTANCES_ID%type;
    cOldSection PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --récupération identifiant processus
    select WFL_PROCESS_INSTANCES_ID
      into nProcInstId
      from WFL_ACTIVITY_INSTANCES
     where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;

    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection    => 'WFL_WORKFLOW_MANAGEMENT : procedure AddActivityInstanceRemarks'
                 , aRecordId   => nProcInstId
                  );
    DebugLog(aLogText   => 'Start' ||
                           chr(10) ||
                           ' params : ' ||
                           chr(10) ||
                           'aActivityInstanceId => ' ||
                           aActivityInstanceId ||
                           chr(10) ||
                           'aRemarks            => ' ||
                           aRemarks
            );

    --pour éviter des problèmes de longueur du string
    select AIN_REMARKS
      into cRemarks
      from WFL_ACTIVITY_INSTANCES
     where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;

    cRemarks             := cRemarks || aRemarks;
    --mise à jour de l'instance d'activité
    DebugLog(aLogText => 'Updating activity remarks');

    update WFL_ACTIVITY_INSTANCES
       set AIN_REMARKS = substrb(cRemarks, 1, 4000)
     where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;

    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
  end AddActivityInstanceRemarks;

  /********************** DelegateActivityInstance *************************/
  procedure DelegateActivityInstance(
    aActivityInstanceId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aNewParticipantId   in PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type
  , aRemarks            in WFL_PERFORMERS.PFM_REMARKS%type
  )
  is
    cursor crPerformer(aActivityInstanceId in WFL_PERFORMERS.WFL_ACTIVITY_INSTANCES_ID%type)
    is
      select     WFL_PERFORMERS_ID
               , PC_WFL_PARTICIPANTS_ID
            from WFL_PERFORMERS
           where C_WFL_PER_STATE = 'CURRENT'
             and PFM_ACCEPTED = 'Y'
             and WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
      for update;

    tplPerformer   crPerformer%rowtype;
    cActState      WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type;
    nExcludePartId WFL_ACTIVITY_INSTANCES.PC_WFL_EXCLUDE_PARTICIPANTS_ID%type;
    nProcInstId    WFL_ACTIVITY_INSTANCES.WFL_PROCESS_INSTANCES_ID%type;
    cOldSection    PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --récupération identifiant processus
    select WFL_PROCESS_INSTANCES_ID
      into nProcInstId
      from WFL_ACTIVITY_INSTANCES
     where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;

    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection    => 'WFL_WORKFLOW_MANAGEMENT : procedure DelegateActivityInstance'
                 , aRecordId   => nProcInstId);
    DebugLog(aLogText   => 'Start' ||
                           chr(10) ||
                           ' params : ' ||
                           chr(10) ||
                           'aActivityInstanceId => ' ||
                           aActivityInstanceId ||
                           chr(10) ||
                           'aNewParticipantId   => ' ||
                           aNewParticipantId ||
                           chr(10) ||
                           'aRemarks            => ' ||
                           aRemarks
            );

    -- seule les activités suspendues peuvent être déléguées
    select C_WFL_ACTIVITY_STATE
         , PC_WFL_EXCLUDE_PARTICIPANTS_ID
      into cActState
         , nExcludePartId
      from WFL_ACTIVITY_INSTANCES
     where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;

    if (cActState <> 'SUSPENDED') then
      DebugLog(aLogText    => 'State of activity instance ' ||
                              aActivityInstanceId ||
                              ' must be SUSPENDED before delegation (current state is ' ||
                              cActState ||
                              ')'
             , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
              );
      Raise_Application_Error(-20060
                            , 'WFL_WORKFLOW_MANAGEMENT.DelegateActivityInstance: State of activity instance ' ||
                              aActivityInstanceId ||
                              ' must be SUSPENDED before delegation (current state is ' ||
                              cActState ||
                              ').'
                             );
    end if;

    --récupération du responsable
    open crPerformer(aActivityInstanceId => aActivityInstanceId);

    fetch crPerformer
     into tplPerformer;

    --création nouveau responsable
    DebugLog(aLogText   => 'Inserting performer (aNewParticipantId = ' ||
                           PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantName(aParticipantId => aNewParticipantId) ||
                           ' [' ||
                           aNewParticipantId ||
                           ']) for ActivityInstance (ActivityInstanceId =' ||
                           aActivityInstanceId ||
                           ')'
            );

    insert into WFL_PERFORMERS
                (WFL_PERFORMERS_ID
               , WFL_ACTIVITY_INSTANCES_ID
               , PC_WFL_PARTICIPANTS_ID
               , C_WFL_PER_STATE
               , PFM_CREATE_DATE
               , PFM_ACCEPTED
               , PFM_REMARKS
               , WFL_WFL_PERFORMERS_ID
               , A_DATECRE
               , A_IDCRE
                )
         values (WFL_PERFORMERS_SEQ.nextval
               , aActivityInstanceId
               , aNewParticipantId
               , 'CURRENT'
               , sysdate
               , null
               , null
               , tplPerformer.WFL_PERFORMERS_ID
               , sysdate
               , PCS.PC_PUBLIC.GetUserIni
                );

    -- mise à jour de l'ancien performer
    DebugLog(aLogText => 'Updating old performer with state "DELEGATED"');

    update WFL_PERFORMERS
       set C_WFL_PER_STATE = 'DELEGATED'
         , PFM_REMARKS = aRemarks
     where current of crPerformer;

    close crPerformer;

    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
  end DelegateActivityInstance;

  /********************** SaveSessionState *********************************/
  procedure SaveSessionState(
    aActivityInstanceId in     WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aSessionStateOut    out    WFL_ACTIVITY_INSTANCES.AIN_SESSION_STATE%type
  )
  is
    oLobLoc     blob;
    nProcInstId WFL_ACTIVITY_INSTANCES.WFL_PROCESS_INSTANCES_ID%type;
    cOldSection PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --récupération identifiant processus
    select WFL_PROCESS_INSTANCES_ID
      into nProcInstId
      from WFL_ACTIVITY_INSTANCES
     where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;

    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection => 'WFL_WORKFLOW_MANAGEMENT : procedure SaveSessionState', aRecordId => nProcInstId);
    DebugLog(aLogText   => 'Start' ||
                           chr(10) ||
                           ' in params : ' ||
                           chr(10) ||
                           'aActivityInstanceId => ' ||
                           aActivityInstanceId
            );

    update    WFL_ACTIVITY_INSTANCES
          set AIN_SESSION_STATE = empty_blob()
        where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
    returning AIN_SESSION_STATE
         into aSessionStateOut;

    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
  end SaveSessionState;

/********************** AssignWorkItem *************************************/
  procedure AssignWorkItem(
    aParticipantId      in PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type
  , aActivityInstanceId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aRemarks            in WFL_PERFORMERS.PFM_REMARKS%type
  )
  is
    cursor crAssign(
      aActivityInstanceId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
    , aParticipantType    in PCS.PC_WFL_PARTICIPANTS.C_PC_WFL_PARTICIPANT_TYPE%type
    )
    is
      select     PFM.*
            from WFL_PERFORMERS PFM
               , PCS.PC_WFL_PARTICIPANTS PAR
           where PFM.C_WFL_PER_STATE = 'ASSIGNED'
             and PFM.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
             and (   PFM_ACCEPTED is null
                  or PFM_ACCEPTED = 'Y')
             and PAR.PC_WFL_PARTICIPANTS_ID = PFM.PC_WFL_PARTICIPANTS_ID
             and PAR.C_PC_WFL_PARTICIPANT_TYPE = aParticipantType
      for update;

    tplAssign             crAssign%rowtype;
    cActivityState        WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type;
    cParticipantType      PCS.PC_WFL_PARTICIPANTS.C_PC_WFL_PARTICIPANT_TYPE%type;
    nExcludeParticipantId WFL_ACTIVITY_INSTANCES.PC_WFL_EXCLUDE_PARTICIPANTS_ID%type;
    nProcInstId           WFL_ACTIVITY_INSTANCES.WFL_PROCESS_INSTANCES_ID%type;
    cOldSection           PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --récupération identifiant processus
    select WFL_PROCESS_INSTANCES_ID
      into nProcInstId
      from WFL_ACTIVITY_INSTANCES
     where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;

    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection => 'WFL_WORKFLOW_MANAGEMENT : procedure AssignWorkItem', aRecordId => nProcInstId);
    DebugLog(aLogText   => 'Start' ||
                           chr(10) ||
                           ' in params : ' ||
                           chr(10) ||
                           'aParticipantId      => ' ||
                           aParticipantId ||
                           'aActivityInstanceId => ' ||
                           aActivityInstanceId ||
                           'aRemarks            => ' ||
                           aRemarks
            );

    --récupération informations
    select C_WFL_ACTIVITY_STATE
         , PC_WFL_EXCLUDE_PARTICIPANTS_ID
      into cActivityState
         , nExcludeParticipantId
      from WFL_ACTIVITY_INSTANCES
     where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;

    select C_PC_WFL_PARTICIPANT_TYPE
      into cParticipantType
      from PCS.PC_WFL_PARTICIPANTS PAR
     where PAR.PC_WFL_PARTICIPANTS_ID = aParticipantId;

    --seulement assigné si l'état est égal à NOTRUNNING
    if (cActivityState != 'NOTRUNNING') then
      DebugLog(aLogText    => 'cannot assign workitem when state <> NOTRUNNING'
             , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
              );
      Raise_Application_Error(-20080
                            , 'WFL_WORKFLOW_MANAGEMENT.AssignWorkitem: cannot assign workitem when state <> NOTRUNNING'
                             );
    end if;

    -- Assigne seulement 2 personnes qui sont autorisées à effectuer l'instance d'activité
    if (aParticipantId = nExcludeParticipantId) then
      DebugLog(aLogText    => 'cannot assign to someone who is prohibited to perform the activity instance (' ||
                              aActivityInstanceId ||
                              ')'
             , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
              );
      Raise_Application_Error
        (-20061
       , 'WFL_WORKFLOW_MANAGEMENT.AssignWorkitem: cannot assign to someone
          who is prohibited to perform the activity instance (' ||
         aActivityInstanceId ||
         ').'
        );
    end if;

    --teste si l'instance d'activité a été assignée auparavant
    open crAssign(aActivityInstanceId => aActivityInstanceId, aParticipantType => cParticipantType);

    fetch crAssign
     into tplAssign;

    if crAssign%found then
      if (tplAssign.PC_WFL_PARTICIPANTS_ID = aParticipantId) then
        DebugLog(aLogText    => 'workitem already assigned to participant'
               , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR);
        Raise_Application_Error(-20081
                              , 'WFL_WORKFLOW_MANAGEMENT.AssignWorkitem: workitem already assigned to participant'
                               );
      end if;

      -- désactive les anciens éléments assignés
      update WFL_PERFORMERS
         set PFM_ACCEPTED = 'N'
       where current of crAssign;
    end if;

    DebugLog(aLogText   => 'Inserting performer (aParticipantId = ' ||
                           PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.GetParticipantName(aParticipantId => aParticipantId) ||
                           ' [' ||
                           aParticipantId ||
                           ']) for ActivityInstance (ActivityInstanceId =' ||
                           aActivityInstanceId ||
                           ')'
            );

    insert into WFL_PERFORMERS
                (WFL_PERFORMERS_ID
               , WFL_WFL_PERFORMERS_ID
               , PC_WFL_PARTICIPANTS_ID
               , WFL_ACTIVITY_INSTANCES_ID
               , PFM_CREATE_DATE
               , C_WFL_PER_STATE
               , PFM_ACCEPTED
               , PFM_REMARKS
               , A_DATECRE
               , A_IDCRE
                )
         values (WFL_PERFORMERS_SEQ.nextval
               , tplAssign.WFL_PERFORMERS_ID
               , aParticipantId
               , aActivityInstanceId
               , sysdate
               , 'ASSIGNED'
               , null
               , aRemarks
               , sysdate
               , PCS.PC_PUBLIC.GetUserIni
                );

    close crAssign;

    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
  end AssignWorkItem;

  /********************** RejectWorkItem *************************************/
  procedure RejectWorkItem(
    aActivityInstanceId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aParticipantId      in PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type
  , aRemarks            in WFL_PERFORMERS.PFM_REMARKS%type
  )
  is
    cursor crAssign(aActivityInstanceId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type)
    is
      select     PFM.*
            from WFL_PERFORMERS PFM
           where (   PFM.C_WFL_PER_STATE = 'ASSIGNED'
                  or PFM.C_WFL_PER_STATE = 'CURRENT')
             and PFM.PC_WFL_PARTICIPANTS_ID = aParticipantId
             and PFM.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
             and PFM.PFM_ACCEPTED is null
      for update;

    tplAssign   crAssign%rowtype;
    nProcInstId WFL_ACTIVITY_INSTANCES.WFL_PROCESS_INSTANCES_ID%type;
    cOldSection PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --récupération identifiant processus
    select WFL_PROCESS_INSTANCES_ID
      into nProcInstId
      from WFL_ACTIVITY_INSTANCES
     where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;

    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection => 'WFL_WORKFLOW_MANAGEMENT : procedure RejectWorkItem', aRecordId => nProcInstId);
    DebugLog(aLogText   => 'Start' ||
                           chr(10) ||
                           ' in params : ' ||
                           chr(10) ||
                           'aActivityInstanceId => ' ||
                           aActivityInstanceId ||
                           'aParticipantId      => ' ||
                           aParticipantId ||
                           'aRemarks            => ' ||
                           aRemarks
            );

    --teste si le participant a été assigné auparavant
    open crAssign(aActivityInstanceId => aActivityInstanceId);

    fetch crAssign
     into tplAssign;

    if crAssign%found then
      DebugLog(aLogText => 'Update performer table and restores old performer if exists');

      --Rejette l'assignation
      update WFL_PERFORMERS
         set PFM_ACCEPTED = 'N'
           , PFM_REMARKS = aRemarks
       where current of crAssign;

      --Restaure la personne précédente ayant pris en charge l'activité ou ayant été assignée
      update WFL_PERFORMERS
         set C_WFL_PER_STATE = tplAssign.C_WFL_PER_STATE
           , PFM_REMARKS = null
           , PFM_ACCEPTED = 'Y'
       where WFL_PERFORMERS_ID = tplAssign.WFL_WFL_PERFORMERS_ID;
    else
      DebugLog(aLogText    => 'cannot reject workitem that is not assigned or already accepted/rejected'
             , aLogLevel   => PCS.PC_LOG_DEBUG_FUNCTIONS.LERROR
              );
      Raise_Application_Error
        (-20090
       , 'WFL_WORKFLOW_MANAGEMENT.RejectWorkitem: cannot reject workitem that
          is not assigned or already accepted/rejected'
        );
    end if;

    close crAssign;

    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
  end RejectWorkItem;

/********************** SortCondition **************************************/
  function SortCondition(aConditionRows in WFL_WORKFLOW_TYPES.TConditionRows)
    return WFL_WORKFLOW_TYPES.TConditionRows
  is
    oTmpConditions WFL_WORKFLOW_TYPES.TConditionRows   default WFL_WORKFLOW_TYPES.TConditionRows();
    result         WFL_WORKFLOW_TYPES.TConditionRows   default WFL_WORKFLOW_TYPES.TConditionRows();
    bMinDef        boolean                             default false;
    nCnt           number;
    nMin           number;
    nIndex         number;
    cOldSection    PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection => 'WFL_WORKFLOW_MANAGEMENT : procedure SortCondition');
    DebugLog(aLogText => 'Start');

    --assignation conditions à variable temporaire (**vérifier si ca marche comme ca)
    for nCnt in 1 .. aConditionRows.count loop
      oTmpConditions.extend;
      oTmpConditions(oTmpConditions.count).pSequence   := aConditionRows(nCnt).pSequence;
      oTmpConditions(oTmpConditions.count).pLeftPar    := aConditionRows(nCnt).pLeftPar;
      oTmpConditions(oTmpConditions.count).pAttrType   := aConditionRows(nCnt).pAttrType;
      oTmpConditions(oTmpConditions.count).pAttrId     := aConditionRows(nCnt).pAttrId;
      oTmpConditions(oTmpConditions.count).pAttrName   := aConditionRows(nCnt).pAttrName;
      oTmpConditions(oTmpConditions.count).pOperator   := aConditionRows(nCnt).pOperator;
      oTmpConditions(oTmpConditions.count).pValueTest  := aConditionRows(nCnt).pValueTest;
      oTmpConditions(oTmpConditions.count).pConnector  := aConditionRows(nCnt).pConnector;
      oTmpConditions(oTmpConditions.count).pRightPar   := aConditionRows(nCnt).pRightPar;
    end loop;

    --parcours des indexes et récupération du minimum
    while oTmpConditions.count > 0 loop
      --récupération du minimum
      for nCnt in 1 .. oTmpConditions.last loop
        if not bMinDef then
          nMin     := oTmpConditions(nCnt).pSequence;
          nIndex   := nCnt;
          bMinDef  := true;
        elsif oTmpConditions(nCnt).pSequence < nMin then
          nMin    := oTmpConditions(nCnt).pSequence;
          nIndex  := nCnt;
        end if;
      end loop;

      --insertion du minimum dans la collection triée
      result.extend;
      result(result.count).pSequence   := oTmpConditions(nIndex).pSequence;
      result(result.count).pLeftPar    := oTmpConditions(nIndex).pLeftPar;
      result(result.count).pAttrType   := oTmpConditions(nIndex).pAttrType;
      result(result.count).pAttrId     := oTmpConditions(nIndex).pAttrId;
      result(result.count).pAttrName   := oTmpConditions(nIndex).pAttrName;
      result(result.count).pOperator   := oTmpConditions(nIndex).pOperator;
      result(result.count).pValueTest  := oTmpConditions(nIndex).pValueTest;
      result(result.count).pConnector  := oTmpConditions(nIndex).pConnector;
      result(result.count).pRightPar   := oTmpConditions(nIndex).pRightPar;
      --suppression de l'élément dans la collection originale
      oTmpConditions.delete(nIndex);
    end loop;

    DebugLog(aLogText => 'End');
    GLogCTX.LOG_SECTION  := cOldSection;
    return result;
  end SortCondition;

  /********************** EvaluateCondition **********************************/
  function EvaluateCondition(
    aTraCondition       in WFL_TRANSITIONS.TRA_CONDITION%type
  , aActivityInstanceId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aProcessInstanceId  in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  )
    return boolean
  is
    --déclaration d'un ref cursor pour tester la condition
    type Weak_Curtype is ref cursor;

    --curseur pour le parcours des conditions
    crCondition      Weak_Curtype;

    --définition d'un curseur pour le type du résultat
    cursor crConditionType
    is
      select 1 as YesNo
        from dual;

    tplConditionType crConditionType%rowtype;
    result           boolean                                     default false;
    nCnt             number;
    nAttCnt          number                                      default 1;
    nAcaCnt          number                                      default 1;
    cXPath           varchar2(255);
    cSelectQuery     varchar2(1000);
    cFromQuery       varchar2(14000);
    cWhereQuery      varchar2(14000);
    cSqlQuery        varchar2(30000);
    cPrefAttr        varchar2(10);
    cPrefAttrInst    varchar2(10);
    cAttrName        varchar2(20);
    cAttrValue       varchar2(20);
    cConditionType   WFL_TRANSITIONS.C_WFL_CONDITION_TYPE%type;
    bProcessAttrib   boolean                                     default false;
    bActivityAttrib  boolean                                     default false;
    bNoAttribute     boolean                                     default false;
    oXmlCondition    xmltype;
    oCurrentRow      WFL_WORKFLOW_TYPES.TConditionRow;
    oRows            WFL_WORKFLOW_TYPES.TConditionRows           default WFL_WORKFLOW_TYPES.TConditionRows();
    oSortedRows      WFL_WORKFLOW_TYPES.TConditionRows           default WFL_WORKFLOW_TYPES.TConditionRows();
    cOldSection      PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --Initialisation du contexte
    cOldSection          := GLogCTX.LOG_SECTION;
    InitLogContext(aSection => 'WFL_WORKFLOW_MANAGEMENT : procedure EvaluateCondition');
    DebugLog(aLogText => 'Start');

    if length(aTraCondition) > 0 then
      oXmlCondition  := sys.xmltype.CreateXml(aTraCondition);

      select extractvalue(oXmlCondition, '/CONDITION/@type')
        into cConditionType
        from dual;

      if cConditionType = 'CONDITION' then
        --récupérer et générer la requête dynamiquement
        nCnt         := 1;

        while(nCnt > 0) loop
          cXPath                         := replace('/CONDITION/CONDITION_ROW[###]', '###', to_char(nCnt, 'FM999') );

          select to_number(extractvalue(oXmlCondition, cXPath || '/@sequence') )
               , decode(trim(upper(extractvalue(oXmlCondition, cXPath || '/@left_par') ) ), 'TRUE', 1, 0)
               , extractvalue(oXmlCondition, cXPath || '/@attribute_type')
               , to_number(extractvalue(oXmlCondition, cXPath || '/@attribute_id') )
               , extractvalue(oXmlCondition, cXPath || '/@attribute_name')
               , extractvalue(oXmlCondition, cXPath || '/@operator')
               , extractvalue(oXmlCondition, cXPath || '/@value_test')
               , extractvalue(oXmlCondition, cXPath || '/@connector')
               , decode(trim(upper(extractvalue(oXmlCondition, cXPath || '/@right_par') ) ), 'TRUE', 1, 0)
            into oCurrentRow.pSequence
               , oCurrentRow.pLeftPar
               , oCurrentRow.pAttrType
               , oCurrentRow.pAttrId
               , oCurrentRow.pAttrName
               , oCurrentRow.pOperator
               , oCurrentRow.pValueTest
               , oCurrentRow.pConnector
               , oCurrentRow.pRightPar
            from dual;

          if oCurrentRow.pSequence is null then
            exit;
          end if;

          --insertion de la ligne courante
          oRows.extend;
          oRows(oRows.count).pSequence   := oCurrentRow.pSequence;
          oRows(oRows.count).pLeftPar    := oCurrentRow.pLeftPar;
          oRows(oRows.count).pAttrType   := oCurrentRow.pAttrType;
          oRows(oRows.count).pAttrId     := oCurrentRow.pAttrId;
          oRows(oRows.count).pAttrName   := oCurrentRow.pAttrName;
          oRows(oRows.count).pOperator   := oCurrentRow.pOperator;
          oRows(oRows.count).pValueTest  := oCurrentRow.pValueTest;
          oRows(oRows.count).pConnector  := oCurrentRow.pConnector;
          oRows(oRows.count).pRightPar   := oCurrentRow.pRightPar;
          nCnt                           := nCnt + 1;
        end loop;

        --parcours de la collection et génération du where
        cSqlQuery    := '';
        cFromQuery   := 'from ';
        cWhereQuery  := 'where ';

        for nCnt in 1 .. oRows.count loop
          bNoAttribute  := false;

          --parenthèse
          if oRows(nCnt).pLeftPar = 1 then
            cSqlQuery  := cSqlQuery || '(';
          end if;

          --type d'attribut
          if oRows(nCnt).pAttrType = 'ACT_ATTR' then
            --attribut d'activité
            cPrefAttr        := 'ACA' || nAcaCnt;
            cPrefAttrInst    := 'AAI' || nAcaCnt;
            cAttrName        := cPrefAttr || '.ACA_NAME';
            cAttrValue       := cPrefAttrInst || '.AAI_VALUE';
            --définition du from
            cFromQuery       :=
              cFromQuery ||
              'WFL_ACTIVITY_ATTRIBUTES ' ||
              cPrefAttr ||
              ',
					   	WFL_ACT_ATTRIBUTE_INSTANCES ' ||
              cPrefAttrInst ||
              ',
                            ';
            --définition du where
            cWhereQuery      :=
              cWhereQuery ||
              cPrefAttrInst ||
              '.WFL_ACTIVITY_ATTRIBUTES_ID = ' ||
              cPrefAttr ||
              '.WFL_ACTIVITY_ATTRIBUTES_ID and
                        ' ||
              cPrefAttrInst ||
              '.WFL_ACTIVITY_INSTANCES_ID  = AIN.WFL_ACTIVITY_INSTANCES_ID and
                        ';
            --incrément du compteur d'alias et activation du flag indiquant la présence d'attributs d'activités
            nAcaCnt          := nAcaCnt + 1;
            bActivityAttrib  := true;
          elsif oRows(nCnt).pAttrType = 'PROC_ATTR' then
            --attributs de processu
            cPrefAttr       := 'ATT' || nAttCnt;
            cPrefAttrInst   := 'ATI' || nAttCnt;
            cAttrName       := cPrefAttr || '.ATT_NAME';
            cAttrValue      := cPrefAttrInst || '.ATI_VALUE';
            --définition du from
            cFromQuery      :=
              cFromQuery ||
              'WFL_ATTRIBUTES ' ||
              cPrefAttr ||
              ',
                             WFL_ATTRIBUTE_INSTANCES ' ||
              cPrefAttrInst ||
              ',
                             ';
            --définition du where
            cWhereQuery     :=
              cWhereQuery ||
              cPrefAttrInst ||
              '.WFL_ATTRIBUTES_ID = ' ||
              cPrefAttr ||
              '.WFL_ATTRIBUTES_ID and
                        ' ||
              cPrefAttrInst ||
              '.WFL_PROCESS_INSTANCES_ID = PRIN.WFL_PROCESS_INSTANCES_ID and
                        ';
            --incrément du compteur d'alias et activation du flag indiquant la présence d'attributs de process
            nAttCnt         := nAttCnt + 1;
            bProcessAttrib  := true;
          else
            bNoAttribute  := true;
          end if;

          --infos attribut
          if not bNoAttribute then
            cSqlQuery  :=
              cSqlQuery ||
              '(' ||
              cAttrName ||
              ' = ''' ||
              oRows(nCnt).pAttrName ||
              ''' and ' ||
              cAttrValue ||
              ' ' ||
              oRows(nCnt).pOperator ||
              ' ' ||
              oRows(nCnt).pValueTest ||
              ')';
          end if;

          --ajout parenthèse
          if oRows(nCnt).pRightPar = 1 then
            cSqlQuery  := cSqlQuery || ')';
          end if;

          --ajout connecteur
          if     (oRows(nCnt).pConnector is not null)
             and (length(oRows(nCnt).pConnector) > 0) then
            cSqlQuery  := cSqlQuery || ' ' || oRows(nCnt).pConnector;
          end if;

          --ajout d'un retour à la ligne avant condition suivante
          if nCnt < oRows.count then
            cSqlQuery  := cSqlQuery || chr(10);
          end if;
        end loop;

        --construction requête selon si on traite la table des attributs ou des process
        if     bProcessAttrib
           and bActivityAttrib then
          cSqlQuery  :=
            'select SUM(YesNo)
             from   (select 1 as YesNo
                    ' ||
            cFromQuery ||
            'WFL_PROCESS_INSTANCES PRIN,
                                        WFL_ACTIVITY_INSTANCES AIN
                    ' ||
            cWhereQuery ||
            'PRIN.WFL_PROCESS_INSTANCES_ID = :PROC_INST_ID and
                                         AIN.WFL_ACTIVITY_INSTANCES_ID = :ACT_INST_ID and
                                        (' ||
            cSqlQuery ||
            ') )';

          --ouverture refcursor
          open crCondition
           for cSqlQuery using aProcessInstanceId, aActivityInstanceId;

          fetch crCondition
           into tplConditionType;

          --si un élément est trouvé alors la condition est remplie
          if crCondition%found then
            result  :=(tplConditionType.YesNo is not null);
          end if;

          close crCondition;
        elsif bProcessAttrib then
          cSqlQuery  :=
            'select SUM(YesNo)
             from   (select 1 as YesNo
                    ' ||
            cFromQuery ||
            'WFL_PROCESS_INSTANCES PRIN
                    ' ||
            cWhereQuery ||
            'PRIN.WFL_PROCESS_INSTANCES_ID = :PROC_INST_ID and
                                       (' ||
            cSqlQuery ||
            ') )';

          --ouverture refcursor
          open crCondition
           for cSqlQuery using aProcessInstanceId;

          fetch crCondition
           into tplConditionType;

          --si un élément est trouvé alors la condition est remplie
          if crCondition%found then
            result  :=(tplConditionType.YesNo is not null);
          end if;

          close crCondition;
        elsif bActivityAttrib then
          cSqlQuery  :=
            'select SUM(YesNo)
             from   (select 1 as YesNo
                    ' ||
            cFromQuery ||
            'WFL_ACTIVITY_INSTANCES AIN
                    ' ||
            cWhereQuery ||
            'AIN.WFL_ACTIVITY_INSTANCES_ID = :ACT_INST_ID and
                                       (' ||
            cSqlQuery ||
            ') )';

          --ouverture refcursor
          open crCondition
           for cSqlQuery using aActivityInstanceId;

          fetch crCondition
           into tplConditionType;

          --si un élément est trouvé alors la condition est remplie
          if crCondition%found then
            result  :=(tplConditionType.YesNo is not null);
          end if;

          close crCondition;
        end if;
      elsif cConditionType = 'OTHERWISE' then
        --condition remplie, pas de tests à faire
        result  := true;
      else
        --**définir ici les règles dans le cas de conditions EXCEPTION, DEFEXCEPT
        result  := true;
      end if;
    end if;

    DebugLog(aLogText => 'End (result = ' || BooleanToChar(result) || ')');
    GLogCTX.LOG_SECTION  := cOldSection;
    return result;
  end EvaluateCondition;

  /********************** GetConditionException ******************************/
  function GetConditionException(aTraCondition in WFL_TRANSITIONS.TRA_CONDITION%type)
    return WFL_DEADLINES.DEA_EXCEPTION_NAME%type
  is
    result         WFL_DEADLINES.DEA_EXCEPTION_NAME%type       default '';
    cConditionType WFL_TRANSITIONS.C_WFL_CONDITION_TYPE%type;
    oXmlCondition  xmltype;
    cOldSection    PCS.PC_LOG_DEBUG.LOG_SECTION%type;
  begin
    --Initialisation du contexte
    cOldSection  := GLogCTX.LOG_SECTION;
    InitLogContext(aSection => 'WFL_WORKFLOW_MANAGEMENT : procedure GetConditionException');
    DebugLog(aLogText => 'Start');

    if length(aTraCondition) > 0 then
      oXmlCondition  := sys.xmltype.CreateXml(aTraCondition);

      select extractvalue(oXmlCondition, '/CONDITION/@type')
           , nvl(extractvalue(oXmlCondition, '/CONDITION/@exception_name'), '')
        into cConditionType
           , result
        from dual;

      if cConditionType = 'EXCEPTION' then
        DebugLog(aLogText => 'End (result = ' || result || ')');
        GLogCTX.LOG_SECTION  := cOldSection;
        return result;
      else
        DebugLog(aLogText => 'End (result = )');
        GLogCTX.LOG_SECTION  := cOldSection;
        return '';
      end if;
    end if;
  end GetConditionException;

  /**
  * procedure GetActivityXmlData
  * Description
  *   Récupère les coordonnées top left stockées dans le fichier xml
  *     stocké dans le champ WFL_PROCESSES.PRO_GRAPHIC_XML et màj des champs
  *     correspondants dans la table des activités
  *     WFL_ACTIVITIES.ACT_TOP et WFL_ACTIVITIES.ACT_LEFT
  */
  procedure GetActivityXmlData(aProcessID in WFL_PROCESSES.WFL_PROCESSES_ID%type)
  is
    vXml               xmltype;
    vXPath             varchar2(2000);
    nCnt               number(12);
    vTag               varchar2(2000);
    vLeft              varchar2(2000);
    vTop               varchar2(2000);
    vWFL_ACTIVITIES_ID WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type;
    vACT_LEFT          WFL_ACTIVITIES.ACT_LEFT%type;
    vACT_TOP           WFL_ACTIVITIES.ACT_TOP%type;
  begin
    -- Récuperer le fichier xml stocké dans le clob
    select xmltype(PRO_GRAPHIC_XML)
      into vXml
      from WFL_PROCESSES
     where WFL_PROCESSES_ID = aProcessID;

    if vXml is not null then
      -- Compteur pour balayer les noeuds
      nCnt  := 1;

      -- Boucler sur les noeuds appelés "NODE" dans l'xml
      while(nCnt > 0) loop
        --
        vXPath  := replace('/AddFlow/NODE[###]/', '###', to_char(nCnt, 'FM999') );

        -- Extraire du noeud courant, la valeur du "Tag" qui contient l'ID de l'activité
        select extractvalue(vXml, vXPath || 'Tag')
             , extractvalue(vXml, vXPath || '@Left')
             , extractvalue(vXml, vXPath || '@Top')
          into vTag
             , vLeft
             , vTop
          from dual;

        -- Sortir de la boucle lorsque la variable est à nul, ce qui signifie
        -- que l'on a balayé tous les noeuds de l'xml
        if vTag is null then
          -- Compteur à négatif pour sortir de la boucle
          nCnt  := -100;
        else
          -- Convertir les valeurs en numérique
          -- Dans le champ Tag on peut avoir des valeurs non-numériques
          -- du genre "JOIN_60042156321" dans ce cas, il ne s'agit pas
          -- d'une activité et donc il ne faut pas traiter ce noeud
          vWFL_ACTIVITIES_ID  := PCS.PC_FUNCTIONS.TO_NUMBER_DEF(vTag, -1);
          vACT_LEFT           := trunc(PCS.PC_FUNCTIONS.TO_NUMBER_DEF(vLeft) / 15);
          vACT_TOP            := trunc(PCS.PC_FUNCTIONS.TO_NUMBER_DEF(vTop) / 15);

          if vWFL_ACTIVITIES_ID <> -1 then
            -- Màj de l'activité avec les coordonnées Left et Top
            update WFL_ACTIVITIES
               set ACT_LEFT = vACT_LEFT
                 , ACT_TOP = vACT_TOP
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where WFL_ACTIVITIES_ID = vWFL_ACTIVITIES_ID
               and ACT_LEFT is null
               and ACT_TOP is null;
          end if;
        end if;

        nCnt    := nCnt + 1;
      end loop;
    end if;
  end GetActivityXmlData;
end WFL_WORKFLOW_MANAGEMENT;
