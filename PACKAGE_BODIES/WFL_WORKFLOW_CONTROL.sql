--------------------------------------------------------
--  DDL for Package Body WFL_WORKFLOW_CONTROL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WFL_WORKFLOW_CONTROL" 
is
  /*************** Types d'objets de controle ********************************/
  GlobalType                 WFL_CTRL_ERRORS.WCE_OBJECT_TYPE%type   default 'GLOBAL';
  ProcessType                WFL_CTRL_ERRORS.WCE_OBJECT_TYPE%type   default 'PROCESS';
  ActivityType               WFL_CTRL_ERRORS.WCE_OBJECT_TYPE%type   default 'ACTIVITY';
  TransitionType             WFL_CTRL_ERRORS.WCE_OBJECT_TYPE%type   default 'TRANSITION';
/*************** Codes d'erreur(types espacés de 20) *************************/
  --Processus
  ErrNoPartAllow             WFL_ERR_MESSAGES.WEM_CODE%type         default 1;
  ErrNoTrigObjects           WFL_ERR_MESSAGES.WEM_CODE%type         default 21;
  ErrManyStartActivity       WFL_ERR_MESSAGES.WEM_CODE%type         default 41;
  ErrNoProcMailPackages      WFL_ERR_MESSAGES.WEM_CODE%type         default 61;
  ErrNoProcPlSqlPackages     WFL_ERR_MESSAGES.WEM_CODE%type         default 62;
  --Activités
  ErrOrphanActivity          WFL_ERR_MESSAGES.WEM_CODE%type         default 401;
  ErrModeParticipant         WFL_ERR_MESSAGES.WEM_CODE%type         default 421;
  ErrModeManAuto             WFL_ERR_MESSAGES.WEM_CODE%type         default 422;
  ErrNoActParticipant        WFL_ERR_MESSAGES.WEM_CODE%type         default 441;
  ErrUserParticipant         WFL_ERR_MESSAGES.WEM_CODE%type         default 442;
  ErrRoleParticipant         WFL_ERR_MESSAGES.WEM_CODE%type         default 443;
  ErrOrgUnitParticipant      WFL_ERR_MESSAGES.WEM_CODE%type         default 444;
  ErrActPerfParticipant      WFL_ERR_MESSAGES.WEM_CODE%type         default 445;
  ErrPlSqlParticipant        WFL_ERR_MESSAGES.WEM_CODE%type         default 446;
  ErrRoleEmptyParticipant    WFL_ERR_MESSAGES.WEM_CODE%type         default 447;
  ErrOrgUnitEmptyParticipant WFL_ERR_MESSAGES.WEM_CODE%type         default 448;
  ErrInAndTransition         WFL_ERR_MESSAGES.WEM_CODE%type         default 461;
  ErrOutAndTransition        WFL_ERR_MESSAGES.WEM_CODE%type         default 462;
  ErrInXorNoTransition       WFL_ERR_MESSAGES.WEM_CODE%type         default 463;
  ErrInXorNullTransition     WFL_ERR_MESSAGES.WEM_CODE%type         default 464;
  ErrOutXorNoTransition      WFL_ERR_MESSAGES.WEM_CODE%type         default 465;
  ErrOutXorNullTransition    WFL_ERR_MESSAGES.WEM_CODE%type         default 466;
  ErrOutXorManyOtherwise     WFL_ERR_MESSAGES.WEM_CODE%type         default 467;
  ErrJoinUndefined           WFL_ERR_MESSAGES.WEM_CODE%type         default 468;
  ErrSplitUndefined          WFL_ERR_MESSAGES.WEM_CODE%type         default 469;
  ErrInAndAllConditions      WFL_ERR_MESSAGES.WEM_CODE%type         default 470;
  ErrOutAndAllConditions     WFL_ERR_MESSAGES.WEM_CODE%type         default 471;
  ErrOutAndOtherwise         WFL_ERR_MESSAGES.WEM_CODE%type         default 472;
  ErrNoActMailPackages       WFL_ERR_MESSAGES.WEM_CODE%type         default 481;
  ErrNoActPlSqlPackages      WFL_ERR_MESSAGES.WEM_CODE%type         default 482;
  ErrPlSqlPartPackage        WFL_ERR_MESSAGES.WEM_CODE%type         default 483;
  --Transitions
  ErrTraEmptyCondition       WFL_ERR_MESSAGES.WEM_CODE%type         default 801;
  /*************** Codes d'avertissement *************************************/
  --activités
  WarOutXorNoOtherwise       WFL_ERR_MESSAGES.WEM_CODE%type         default 1401;
  WarInAndTransitions        WFL_ERR_MESSAGES.WEM_CODE%type         default 1402;   --**inutilisé
  WarOutAndTransitions       WFL_ERR_MESSAGES.WEM_CODE%type         default 1403;   --**inutilisé
  --transitions
  WarExcept                  WFL_ERR_MESSAGES.WEM_CODE%type         default 1801;
  WarDefExcept               WFL_ERR_MESSAGES.WEM_CODE%type         default 1802;

  /*************** GetSecIdSeparator *****************************************/
  function GetSecIdSeparator
    return varchar2
  is
  begin
    return GSecIdSeparator;
  end GetSecIdSeparator;

  /*************** IsNullCondition *******************************************/
  function IsNullCondition(aCondition in WFL_TRANSITIONS.TRA_CONDITION%type)
    return boolean
  is
    cSeqNumber    varchar2(5);
    oXmlCondition xmltype;
    result        boolean     default false;
  begin
    if (length(aCondition) > 0) then
      oXmlCondition  := sys.xmltype.CreateXml(aCondition);

      select extractvalue(oXmlCondition, '/CONDITION/CONDITION_ROW[1]/@sequence')
        into cSeqNumber
        from dual;

      result         := cSeqNumber is null;
    else
      result  := true;
    end if;

    return result;
  end IsNullCondition;

  /*************** ExistsPlSqlCode *******************************************/
  function ExistsPlSqlCode(aPlSqlCode in varchar2)
    return boolean
  is
    nPosDot       pls_integer;
    bPackageDef   boolean                        default false;
    bExistsFct    WFL_WORKFLOW_TYPES.WFL_BOOLEAN;
    cPackageName  varchar2(200)                  default '';
    cFunctionName varchar2(200);
    nObjectId     USER_OBJECTS.OBJECT_ID%type    default null;
    result        boolean                        default true;
  begin
    if (length(aPlSqlCode) > 0) then
      --séparer le package de la fonction
      nPosDot        := instr(aPlSqlCode, '.');

      if nPosDot > 0 then
        cPackageName  := substr(aPlSqlCode, 1, nPosDot - 1);
        bPackageDef   := true;
      end if;

      cFunctionName  := substr(aPlSqlCode, nPosDot + 1, length(aPlSqlCode) - nPosDot);

      --on teste si package et fonction existent
      if bPackageDef then
        begin
          select OBJ.OBJECT_ID
            into nObjectId
            from USER_OBJECTS OBJ
           where OBJ.OBJECT_TYPE = 'PACKAGE'
             and OBJ.OBJECT_NAME = upper(cPackageName);
        exception
          when no_data_found then
            result  := false;
        end;
      end if;

      if     (length(cFunctionName) > 0)
         and result then
        --traitement différent selon si il s'agit d'une fonction ou d'une fonction de package
        if bPackageDef then
          select decode(count(*), 0, 0, 1)
            into bExistsFct
            from USER_PROCEDURES PROC
           where PROC.OBJECT_ID = nObjectId
             and PROC.PROCEDURE_NAME = upper(cFunctionName);
        else
          select decode(count(*), 0, 0, 1)
            into bExistsFct
            from USER_OBJECTS OBJ
           where OBJ.OBJECT_TYPE in('PROCEDURE', 'FUNCTION')
             and OBJ.OBJECT_NAME = upper(cFunctionName);
        end if;

        result  :=(bExistsFct = 1);
      end if;
    end if;

    return result;
  end ExistsPlSqlCode;

/*************** GetRecordName *********************************************/
  function GetRecordName(
    aObjectType in WFL_CTRL_ERRORS.WCE_OBJECT_TYPE%type
  , aRecordId   in WFL_CTRL_ERRORS.WCE_RECORD_ID%type
  )
    return varchar2
  is
    cObjectType WFL_CTRL_ERRORS.WCE_OBJECT_TYPE%type;
    result      varchar2(250)                          default '';
  begin
    --en fonction du type d'objet exécution de requêtes différentes
    cObjectType  := upper(trim(aObjectType) );

    if    (cObjectType = ProcessType)
       or (cObjectType = GlobalType) then
      begin
        select PRO.PRO_NAME
          into result
          from WFL_PROCESSES PRO
         where PRO.WFL_PROCESSES_ID = aRecordId;
      exception
        when no_data_found then
          result  := '';
      end;
    elsif(cObjectType = ActivityType) then
      begin
        select ACT.ACT_NAME
          into result
          from WFL_ACTIVITIES ACT
         where ACT.WFL_ACTIVITIES_ID = aRecordId;
      exception
        when no_data_found then
          result  := '';
      end;
    elsif(cObjectType = TransitionType) then
      begin
        select TRA.TRA_NAME
          into result
          from WFL_TRANSITIONS TRA
         where TRA.WFL_TRANSITIONS_ID = aRecordId;
      exception
        when no_data_found then
          result  := '';
      end;
    end if;

    return result;
  end GetRecordName;

  /*************** GetRecordDescr ********************************************/
  function GetRecordDescr(
    aObjectType in WFL_CTRL_ERRORS.WCE_OBJECT_TYPE%type
  , aRecordId   in WFL_CTRL_ERRORS.WCE_RECORD_ID%type
  )
    return varchar2
  is
    cObjectType WFL_CTRL_ERRORS.WCE_OBJECT_TYPE%type;
    result      varchar2(250)                          default '';
  begin
    --en fonction du type d'objet exécution de requêtes différentes
    cObjectType  := upper(trim(aObjectType) );

    if    (cObjectType = ProcessType)
       or (cObjectType = GlobalType) then
      begin
        select nvl(PRD.PRD_DESCRIPTION, PRO.PRO_DESCRIPTION) PRO_DESCRIPTION
          into result
          from WFL_PROCESSES PRO
             , WFL_PROCESSES_DESCR PRD
         where PRD.WFL_PROCESSES_ID(+) = PRO.WFL_PROCESSES_ID
           and PRD.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.GetUserLangId
           and PRO.WFL_PROCESSES_ID = aRecordId;
      exception
        when no_data_found then
          result  := '';
      end;
    elsif(cObjectType = ActivityType) then
      begin
        select nvl(ACD.ACD_DESCRIPTION, ACT.ACT_DESCRIPTION) ACT_DESCRIPTION
          into result
          from WFL_ACTIVITIES ACT
             , WFL_ACTIVITIES_DESCR ACD
         where ACD.WFL_ACTIVITIES_ID(+) = ACT.WFL_ACTIVITIES_ID
           and ACD.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.GetUserLangId
           and ACT.WFL_ACTIVITIES_ID = aRecordId;
      exception
        when no_data_found then
          result  := '';
      end;
    elsif(cObjectType = TransitionType) then
      begin
        select nvl(TRD.TRD_DESCRIPTION, TRA.TRA_DESCR) TRA_DESCR
          into result
          from WFL_TRANSITIONS TRA
             , WFL_TRANSITIONS_DESCR TRD
         where TRD.WFL_TRANSITIONS_ID(+) = TRA.WFL_TRANSITIONS_ID
           and TRD.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.GetUserLangId
           and TRA.WFL_TRANSITIONS_ID = aRecordId;
      exception
        when no_data_found then
          result  := '';
      end;
    end if;

    return result;
  end GetRecordDescr;

  /*************** GetErrorElement *******************************************/
  function GetErrorElement(aErrCode in WFL_ERR_MESSAGES.WEM_CODE%type)
    return varchar2
  is
    result varchar2(200) default '';
  begin
    if    (aErrCode = ErrNoPartAllow)
       or (aErrCode = ErrNoActParticipant)
       or (aErrCode = ErrUserParticipant)
       or (aErrCode = ErrRoleParticipant)
       or (aErrCode = ErrOrgUnitParticipant)
       or (aErrCode = ErrActPerfParticipant)
       or (aErrCode = ErrPlSqlParticipant)
       or (aErrCode = ErrRoleEmptyParticipant)
       or (aErrCode = ErrOrgUnitEmptyParticipant)
       or (aErrCode = ErrPlSqlPartPackage) then
      result  := 'PARTICIPANT';
    elsif(aErrCode = ErrNoTrigObjects) then
      result  := 'TRIG_OBJECT';
    elsif    (aErrCode = ErrManyStartActivity)
          or (aErrCode = ErrOrphanActivity) then
      result  := 'ACTIVITY';
    elsif    (aErrCode = ErrNoProcMailPackages)
          or (aErrCode = ErrNoActMailPackages) then
      result  := 'MAIL_EVENT';
    elsif    (aErrCode = ErrNoProcPlSqlPackages)
          or (aErrCode = ErrNoActPlSqlPackages) then
      result  := 'PLSQL_EVENT';
    elsif    (aErrCode = ErrModeParticipant)
          or (aErrCode = ErrModeManAuto) then
      result  := 'ACTIVITY_MODE';
    elsif    (aErrCode = ErrInAndTransition)
          or (aErrCode = ErrInXorNoTransition)
          or (aErrCode = ErrInXorNullTransition)
          or (aErrCode = ErrInAndAllConditions)
          or (aErrCode = ErrJoinUndefined)
          or (aErrCode = WarInAndTransitions) then
      result  := 'JOIN';
    elsif    (aErrCode = ErrOutAndTransition)
          or (aErrCode = ErrOutXorNoTransition)
          or (aErrCode = ErrOutXorNullTransition)
          or (aErrCode = ErrOutXorManyOtherwise)
          or (aErrCode = ErrOutAndAllConditions)
          or (aErrCode = ErrOutAndOtherwise)
          or (aErrCode = ErrSplitUndefined)
          or (aErrCode = WarOutXorNoOtherwise)
          or (aErrCode = WarOutAndTransitions) then
      result  := 'SPLIT';
    elsif    (aErrCode = ErrTraEmptyCondition)
          or (aErrCode = WarExcept)
          or (aErrCode = WarDefExcept) then
      result  := 'CONDITION';
    end if;

    return result;
  end GetErrorElement;

  /*************** GetSecondaryIds *******************************************/
  function GetSecondaryIds(
    aSecondaryId in     WFL_ERR_MESSAGES.WEM_SECONDARY_ID%type
  , aFirstId     out    varchar2
  , aSecondId    out    varchar2
  , aThirdId     out    varchar2
  , aFourthId    out    varchar2
  , aFifthId     out    varchar2
  )
    return pls_integer
  is
    nPosSep      pls_integer;
    cSecondaryId WFL_ERR_MESSAGES.WEM_SECONDARY_ID%type;
    cTempId      WFL_ERR_MESSAGES.WEM_SECONDARY_ID%type;
    result       pls_integer                              default 1;
  begin
    cSecondaryId  := aSecondaryId;
    nPosSep       := instr(cSecondaryId, GSecIdSeparator);

    while nPosSep > 0 loop
      cTempId       := substr(cSecondaryId, 1, nPosSep - 1);
      cSecondaryId  := substr(cSecondaryId, nPosSep + 1, length(cSecondaryId) );

      --on met à jour la variable d'après le nombre de paramètres
      if result = 1 then
        aFirstId  := cTempId;
      elsif result = 2 then
        aSecondId  := cTempId;
      elsif result = 3 then
        aThirdId  := cTempId;
      elsif result = 4 then
        aFourthId  := cTempId;
      elsif result = 5 then
        aFifthId  := cTempId;
      end if;

      result        := result + 1;
      nPosSep       := instr(cSecondaryId, GSecIdSeparator);
    end loop;

    --le dernier paramètre est dans la variable cSecondaryId
    if     (length(cSecondaryId) > 0)
       and (result < 6) then
      if result = 1 then
        aFirstId  := cSecondaryId;
      elsif result = 2 then
        aSecondId  := cSecondaryId;
      elsif result = 3 then
        aThirdId  := cSecondaryId;
      elsif result = 4 then
        aFourthId  := cSecondaryId;
      elsif result = 5 then
        aFifthId  := cSecondaryId;
      end if;
    end if;

    return result;
  end GetSecondaryIds;

  /*************** InsertMessageError ****************************************/
  procedure InsertMessageError(
    aErrCode     in     WFL_ERR_MESSAGES.WEM_CODE%type
  , aHintMessage in     WFL_ERR_MESSAGES.WEM_MESSAGE%type
  , aSecondaryId in     WFL_ERR_MESSAGES.WEM_SECONDARY_ID%type
  , aObjectType  in     WFL_CTRL_ERRORS.WCE_OBJECT_TYPE%type
  , aRecordId    in     WFL_CTRL_ERRORS.WCE_RECORD_ID%type
  , aCtrlErrId   in out WFL_CTRL_ERRORS.WFL_CTRL_ERRORS_ID%type
  )
  is
  begin
    if    (aCtrlErrId = 0)
       or (aCtrlErrId is null) then
      select nvl( (select WFL_CTRL_ERRORS_ID
                     from WFL_CTRL_ERRORS
                    where WCE_OBJECT_TYPE = aObjectType
                      and WCE_RECORD_ID = aRecordId), 0)
        into aCtrlErrId
        from dual;

      if    (aCtrlErrId = 0)
         or (aCtrlErrId is null) then
        insert into WFL_CTRL_ERRORS
                    (WFL_CTRL_ERRORS_ID
                   , WCE_OBJECT_TYPE
                   , WCE_RECORD_ID
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (init_id_seq.nextval
                   , aObjectType
                   , aRecordId
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    )
          returning WFL_CTRL_ERRORS_ID
               into aCtrlErrId;
      end if;
    end if;

    insert into WFL_ERR_MESSAGES
                (WFL_CTRL_ERRORS_ID
               , WEM_CODE
               , WEM_MESSAGE
               , WEM_SECONDARY_ID
               , A_DATECRE
               , A_IDCRE
                )
         values (aCtrlErrId
               , aErrCode
               , aHintMessage
               , aSecondaryId
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end InsertMessageError;

  /*************** GetTransitionErrors ***************************************/
  procedure GetTransitionErrors(
    aTransitionId   in WFL_TRANSITIONS.WFL_TRANSITIONS_ID%type
  , aClearTmpTables in WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  )
  is
    cCondType  WFL_TRANSITIONS.C_WFL_CONDITION_TYPE%type;
    cCondition WFL_TRANSITIONS.TRA_CONDITION%type;
    cWarCode   WFL_ERR_MESSAGES.WEM_CODE%type;
    cWarMsg    WFL_ERR_MESSAGES.WEM_MESSAGE%type;
    nCtrlErrId WFL_CTRL_ERRORS.WFL_CTRL_ERRORS_ID%type     default 0;
  begin
    if aClearTmpTables = 1 then
      --suppression dans les tables temporaires
      delete from WFL_ERR_MESSAGES;

      delete from WFL_CTRL_ERRORS;
    end if;

    select upper(C_WFL_CONDITION_TYPE) C_WFL_CONDITION_TYPE
         , TRA_CONDITION
      into cCondType
         , cCondition
      from WFL_TRANSITIONS
     where WFL_TRANSITIONS_ID = aTransitionId;

    if cCondType = 'CONDITION' then
      --erreur si condition indéfinie
      if WFL_WORKFLOW_CONTROL.IsNullCondition(cCondition) then
        WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrTraEmptyCondition
                                              , aHintMessage   => 'WFL-' || trim(to_char(ErrTraEmptyCondition, '0999') )
                                              , aSecondaryId   => ''
                                              , aObjectType    => TransitionType
                                              , aRecordId      => aTransitionId
                                              , aCtrlErrId     => nCtrlErrId
                                               );
      end if;
    elsif    (cCondType = 'EXCEPTION')
          or (cCondType = 'DEFEXCEPT') then
      --warnings, à voir si affichés à l'écran
      if (cCondType = 'DEFEXCEPT') then
        cWarCode  := WarDefExcept;
        cWarMsg   := 'WFL-' || trim(to_char(WarDefExcept, '0999') );   --** pour l'instant les hints ne contiennent que le code d'erreur, sans message
      else
        cWarCode  := WarExcept;
        cWarMsg   := 'WFL-' || trim(to_char(WarExcept, '0999') );
      end if;

      WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => cWarCode
                                            , aHintMessage   => cWarMsg
                                            , aSecondaryId   => ''
                                            , aObjectType    => TransitionType
                                            , aRecordId      => aTransitionId
                                            , aCtrlErrId     => nCtrlErrId
                                             );
    end if;
  end GetTransitionErrors;

  /*************** GetActivityErrors *****************************************/
  procedure GetActivityErrors(
    aActivityId     in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type
  , aClearTmpTables in WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  )
  is
    --curseurs pour transitions sortantes et entrantes
    cursor crInTransitions(aActivityId in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type)
    is
      select upper(C_WFL_CONDITION_TYPE) C_WFL_CONDITION_TYPE
           , TRA_CONDITION
        from WFL_TRANSITIONS
       where WFL_TO_ACTIVITIES_ID = aActivityId;

    cursor crOutTransitions(aActivityId in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type)
    is
      select upper(C_WFL_CONDITION_TYPE) C_WFL_CONDITION_TYPE
           , TRA_CONDITION
        from WFL_TRANSITIONS
       where WFL_FROM_ACTIVITIES_ID = aActivityId;

    --curseur pour événements Mail et PlSql
    cursor crEvents(aActivityId in WFL_ACTIVITY_EVENTS.WFL_ACTIVITIES_ID%type)
    is
      select upper(C_WFL_EVENT_TYPE) C_WFL_EVENT_TYPE
           , WAV_EVENT_TYPE_PROPERTIES
           , WFL_ACTIVITY_EVENTS_ID
           , (C_WFL_EVENT_TYPE ||
              GSecIdSeparator ||
              C_WFL_ACTIVITY_STATE ||
              GSecIdSeparator ||
              C_WFL_EVENT_TIMING ||
              GSecIdSeparator ||
              WAV_EVENT_SEQ
             ) EVENT_SEC_ID
        from WFL_ACTIVITY_EVENTS
       where WFL_ACTIVITIES_ID = aActivityId;

    tplInTransitions  crInTransitions%rowtype;
    tplOutTransitions crOutTransitions%rowtype;
    tplEvents         crEvents%rowtype;
    nInTransitions    pls_integer;
    nOutTransitions   pls_integer;
    nCntActivities    pls_integer;
    cStartMode        WFL_ACTIVITIES.ACT_START_MODE%type;
    cFinishMode       WFL_ACTIVITIES.ACT_FINISH_MODE%type;
    cActSplit         WFL_ACTIVITIES.C_WFL_SPLIT%type;
    cActJoin          WFL_ACTIVITIES.C_WFL_JOIN%type;
    cActPartType      WFL_ACTIVITIES.C_WFL_ACT_PART_TYPE%type;
    cAssignTo         WFL_ACTIVITIES.ACT_ASSIGN_TO%type;
    nAssignId         WFL_ACTIVITIES.ACT_ASSIGN_ID%type;
    nParticipantId    WFL_ACTIVITIES.PC_WFL_PARTICIPANTS_ID%type;
    cPartFunction     WFL_ACTIVITIES.ACT_PART_FUNCTION%type;
    cPlSqlCode        varchar2(200);
    bErrOutXor        boolean;
    bAllConditions    boolean;
    bAndOtherwise     boolean;
    nCntOtherwise     pls_integer                                  default 0;
    nCtrlErrId        WFL_CTRL_ERRORS.WFL_CTRL_ERRORS_ID%type      default 0;
  begin
    if aClearTmpTables = 1 then
      --suppression dans les tables temporaires
      delete from WFL_ERR_MESSAGES;

      delete from WFL_CTRL_ERRORS;
    end if;

    select (select count(WFL_TRANSITIONS_ID)
              from WFL_TRANSITIONS
             where WFL_FROM_ACTIVITIES_ID = aActivityId)
         , (select count(WFL_TRANSITIONS_ID)
              from WFL_TRANSITIONS
             where WFL_TO_ACTIVITIES_ID = aActivityId)
         , (select count(WFL_ACTIVITIES_ID)
              from WFL_ACTIVITIES
             where WFL_PROCESSES_ID = ACT.WFL_PROCESSES_ID)
         , upper(ACT.ACT_START_MODE)
         , upper(ACT.ACT_FINISH_MODE)
         , upper(ACT.C_WFL_SPLIT)
         , upper(ACT.C_WFL_JOIN)
         , upper(ACT.C_WFL_ACT_PART_TYPE)
         , ACT.ACT_ASSIGN_TO
         , ACT.ACT_ASSIGN_ID
         , ACT.PC_WFL_PARTICIPANTS_ID
         , ACT.ACT_PART_FUNCTION
      into nOutTransitions
         , nInTransitions
         , nCntActivities
         , cStartMode
         , cFinishMode
         , cActSplit
         , cActJoin
         , cActPartType
         , cAssignTo
         , nAssignId
         , nParticipantId
         , cPartFunction
      from WFL_ACTIVITIES ACT
     where WFL_ACTIVITIES_ID = aActivityId;

    --Aucune transition
    if     (nOutTransitions = 0)
       and (nInTransitions = 0)
       and (nCntActivities > 1) then
      WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrOrphanActivity
                                            , aHintMessage   => 'WFL-' || trim(to_char(ErrOrphanActivity, '0999') )
                                            , aSecondaryId   => ''
                                            , aObjectType    => ActivityType
                                            , aRecordId      => aActivityId
                                            , aCtrlErrId     => nCtrlErrId
                                             );
    end if;

    --modes de démarrage et de terminaison
    if     (cStartMode = 'AUTOMATIC')
       and (    (cActPartType = 'ROLE')
            or (cActPartType = 'ORGAN_UNIT') ) then
      WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrModeParticipant
                                            , aHintMessage   => 'WFL-' || trim(to_char(ErrModeParticipant, '0999') )
                                            , aSecondaryId   => ''
                                            , aObjectType    => ActivityType
                                            , aRecordId      => aActivityId
                                            , aCtrlErrId     => nCtrlErrId
                                             );
    end if;

    if     (cStartMode = 'MANUAL')
       and (cFinishMode = 'AUTOMATIC') then
      WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrModeManAuto
                                            , aHintMessage   => 'WFL-' || trim(to_char(ErrModeManAuto, '0999') )
                                            , aSecondaryId   => ''
                                            , aObjectType    => ActivityType
                                            , aRecordId      => aActivityId
                                            , aCtrlErrId     => nCtrlErrId
                                             );
    end if;

    --Participants
    if    (length(cActPartType) = 0)
       or cActPartType is null then
      WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrNoActParticipant
                                            , aHintMessage   => 'WFL-' || trim(to_char(ErrNoActParticipant, '0999') )
                                            , aSecondaryId   => ''
                                            , aObjectType    => ActivityType
                                            , aRecordId      => aActivityId
                                            , aCtrlErrId     => nCtrlErrId
                                             );
    elsif     (cActPartType = 'HUMAN')
          and (    (nParticipantId = 0)
               or nParticipantId is null) then
      WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrUserParticipant
                                            , aHintMessage   => 'WFL-' || trim(to_char(ErrUserParticipant, '0999') )
                                            , aSecondaryId   => ''
                                            , aObjectType    => ActivityType
                                            , aRecordId      => aActivityId
                                            , aCtrlErrId     => nCtrlErrId
                                             );
    elsif(cActPartType = 'ROLE') then
      if (    (nParticipantId = 0)
          or nParticipantId is null) then
        WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrRoleParticipant
                                              , aHintMessage   => 'WFL-' || trim(to_char(ErrRoleParticipant, '0999') )
                                              , aSecondaryId   => ''
                                              , aObjectType    => ActivityType
                                              , aRecordId      => aActivityId
                                              , aCtrlErrId     => nCtrlErrId
                                               );
      elsif(PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.ExistsUsersGrantedToRole(aRoleId => nParticipantId) = 0) then
        WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrRoleEmptyParticipant
                                              , aHintMessage   => 'WFL-' ||
                                                                  trim(to_char(ErrRoleEmptyParticipant, '0999') )
                                              , aSecondaryId   => to_char(nParticipantId)
                                              , aObjectType    => ActivityType
                                              , aRecordId      => aActivityId
                                              , aCtrlErrId     => nCtrlErrId
                                               );
      end if;
    elsif(cActPartType = 'ORGAN_UNIT') then
      if (    (nParticipantId = 0)
          or nParticipantId is null) then
        WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrOrgUnitParticipant
                                              , aHintMessage   => 'WFL-'
                                                                  || trim(to_char(ErrOrgUnitParticipant, '0999') )
                                              , aSecondaryId   => ''
                                              , aObjectType    => ActivityType
                                              , aRecordId      => aActivityId
                                              , aCtrlErrId     => nCtrlErrId
                                               );
      elsif(PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.ExistsUsersInOrgUnit(aOrgUnitId => nParticipantId) = 0) then
        WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrOrgUnitEmptyParticipant
                                              , aHintMessage   => 'WFL-' ||
                                                                  trim(to_char(ErrOrgUnitEmptyParticipant, '0999') )
                                              , aSecondaryId   => to_char(nParticipantId)
                                              , aObjectType    => ActivityType
                                              , aRecordId      => aActivityId
                                              , aCtrlErrId     => nCtrlErrId
                                               );
      end if;
    elsif     (cActPartType = 'ACT_PERF')
          and (    (nAssignId = 0)
               or nAssignId is null) then
      WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrActPerfParticipant
                                            , aHintMessage   => 'WFL-' || trim(to_char(ErrActPerfParticipant, '0999') )
                                            , aSecondaryId   => ''
                                            , aObjectType    => ActivityType
                                            , aRecordId      => aActivityId
                                            , aCtrlErrId     => nCtrlErrId
                                             );
    elsif     (cActPartType = 'PART_PLSQL')
          and (    (length(cPartFunction) = 0)
               or cPartFunction is null) then
      WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrPlSqlParticipant
                                            , aHintMessage   => 'WFL-' || trim(to_char(ErrPlSqlParticipant, '0999') )
                                            , aSecondaryId   => ''
                                            , aObjectType    => ActivityType
                                            , aRecordId      => aActivityId
                                            , aCtrlErrId     => nCtrlErrId
                                             );
    end if;

    --Split and Join
    if (cActJoin = 'AND') then
      if (nInTransitions < 2) then
        WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrInAndTransition
                                              , aHintMessage   => 'WFL-' || trim(to_char(ErrInAndTransition, '0999') )
                                              , aSecondaryId   => ''
                                              , aObjectType    => ActivityType
                                              , aRecordId      => aActivityId
                                              , aCtrlErrId     => nCtrlErrId
                                               );
      /** supprimé, plus de tests sur les conditions entrantes
      else
        --cherche si toutes les transitions entrantes sont conditionnées
        bAllConditions  := true;

        for tplInTransitions in crInTransitions(aActivityId => aActivityId) loop
          if    (tplInTransitions.C_WFL_CONDITION_TYPE <> 'CONDITION')
             or (tplInTransitions.C_WFL_CONDITION_TYPE is null) then
            bAllConditions  := false;
            exit;
          end if;
        end loop;

        if bAllConditions then
          WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrInAndAllConditions
                                                , aHintMessage   => 'WFL-' ||
                                                                    trim(to_char(ErrInAndAllConditions, '0999') )
                                                , aSecondaryId   => ''
                                                , aObjectType    => ActivityType
                                                , aRecordId      => aActivityId
                                                , aCtrlErrId     => nCtrlErrId
                                                 );
        end if;
      */
      end if;
    end if;

    if (cActSplit = 'AND') then
      if (nOutTransitions < 2) then
        WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrOutAndTransition
                                              , aHintMessage   => 'WFL-' || trim(to_char(ErrOutAndTransition, '0999') )
                                              , aSecondaryId   => ''
                                              , aObjectType    => ActivityType
                                              , aRecordId      => aActivityId
                                              , aCtrlErrId     => nCtrlErrId
                                               );
      else
        --cherche si toutes les transitions sortantes sont conditionnées
        bAllConditions  := true;
        bAndOtherwise   := false;

        for tplOutTransitions in crOutTransitions(aActivityId => aActivityId) loop
          if    (tplOutTransitions.C_WFL_CONDITION_TYPE <> 'CONDITION')
             or (tplOutTransitions.C_WFL_CONDITION_TYPE is null) then
            bAllConditions  := false;

            --teste si on a à faire à un and avec un otherwise
            if (tplOutTransitions.C_WFL_CONDITION_TYPE = 'OTHERWISE') then
              bAndOtherwise  := true;
            end if;
          end if;

          if     bAndOtherwise
             and not bAllConditions then
            exit;
          end if;
        end loop;

        if bAllConditions then
          WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrOutAndAllConditions
                                                , aHintMessage   => 'WFL-' ||
                                                                    trim(to_char(ErrOutAndAllConditions, '0999') )
                                                , aSecondaryId   => ''
                                                , aObjectType    => ActivityType
                                                , aRecordId      => aActivityId
                                                , aCtrlErrId     => nCtrlErrId
                                                 );
        end if;

        if bAndOtherwise then
          WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrOutAndOtherwise
                                                , aHintMessage   => 'WFL-' || trim(to_char(ErrOutAndOtherwise, '0999') )
                                                , aSecondaryId   => ''
                                                , aObjectType    => ActivityType
                                                , aRecordId      => aActivityId
                                                , aCtrlErrId     => nCtrlErrId
                                                 );
        end if;
      end if;
    end if;

    if (cActJoin = 'XOR') then
      --parcours des transitions en entrée et recherche si elles ont toutes une condition non nulle
--      if nInTransitions > 0 then
         /** supprimé car on ne fait plus de tests sur les transitions en entrée
         for tplInTransitions in crInTransitions(aActivityId => aActivityId) loop
          if    (tplInTransitions.C_WFL_CONDITION_TYPE <> 'CONDITION')
             or WFL_WORKFLOW_CONTROL.IsNullCondition(tplInTransitions.TRA_CONDITION) then
            WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrInXorNullTransition
                                                  , aHintMessage   => 'WFL-' ||
                                                                      trim(to_char(ErrInXorNullTransition, '0999') )
                                                  , aSecondaryId   => ''
                                                  , aObjectType    => ActivityType
                                                  , aRecordId      => aActivityId
                                                  , aCtrlErrId     => nCtrlErrId
                                                   );
            exit;
          end if;
        end loop;
  --    else
        */
      if (nInTransitions = 0) then
        WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrInXorNoTransition
                                              , aHintMessage   => 'WFL-' || trim(to_char(ErrInXorNoTransition, '0999') )
                                              , aSecondaryId   => ''
                                              , aObjectType    => ActivityType
                                              , aRecordId      => aActivityId
                                              , aCtrlErrId     => nCtrlErrId
                                               );
      end if;
    end if;

    if (cActSplit = 'XOR') then
      --parcours des transitions en sortie
      if nOutTransitions > 0 then
        for tplOutTransitions in crOutTransitions(aActivityId => aActivityId) loop
          bErrOutXor  := false;

          if tplOutTransitions.C_WFL_CONDITION_TYPE = 'CONDITION' then
            bErrOutXor  := WFL_WORKFLOW_CONTROL.IsNullCondition(tplOutTransitions.TRA_CONDITION);
          elsif tplOutTransitions.C_WFL_CONDITION_TYPE = 'OTHERWISE' then
            nCntOtherwise  := nCntOtherwise + 1;
          else
            bErrOutXor  := true;
          end if;
        end loop;

        if bErrOutXor then
          WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrOutXorNullTransition
                                                , aHintMessage   => 'WFL-' ||
                                                                    trim(to_char(ErrOutXorNullTransition, '0999') )
                                                , aSecondaryId   => ''
                                                , aObjectType    => ActivityType
                                                , aRecordId      => aActivityId
                                                , aCtrlErrId     => nCtrlErrId
                                                 );
        end if;

        if nCntOtherwise = 0 then
          WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => WarOutXorNoOtherwise
                                                , aHintMessage   => 'WFL-' ||
                                                                    trim(to_char(WarOutXorNoOtherwise, '0999') )
                                                , aSecondaryId   => ''
                                                , aObjectType    => ActivityType
                                                , aRecordId      => aActivityId
                                                , aCtrlErrId     => nCtrlErrId
                                                 );
        elsif nCntOtherwise > 1 then
          WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrOutXorManyOtherwise
                                                , aHintMessage   => 'WFL-' ||
                                                                    trim(to_char(ErrOutXorManyOtherwise, '0999') )
                                                , aSecondaryId   => ''
                                                , aObjectType    => ActivityType
                                                , aRecordId      => aActivityId
                                                , aCtrlErrId     => nCtrlErrId
                                                 );
        end if;
      else
        WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrOutXorNoTransition
                                              , aHintMessage   => 'WFL-'
                                                                  || trim(to_char(ErrOutXorNoTransition, '0999') )
                                              , aSecondaryId   => ''
                                              , aObjectType    => ActivityType
                                              , aRecordId      => aActivityId
                                              , aCtrlErrId     => nCtrlErrId
                                               );
      end if;
    end if;

    --on teste si pour des split ou join nuls il existe plusieurs transitions
    if     (    (length(cActSplit) = 0)
            or cActSplit is null)
       and (nOutTransitions > 1) then
      WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrSplitUndefined
                                            , aHintMessage   => 'WFL-' || trim(to_char(ErrSplitUndefined, '0999') )
                                            , aSecondaryId   => ''
                                            , aObjectType    => ActivityType
                                            , aRecordId      => aActivityId
                                            , aCtrlErrId     => nCtrlErrId
                                             );
    end if;

    if     (    (length(cActJoin) = 0)
            or cActJoin is null)
       and (nInTransitions > 1) then
      WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrJoinUndefined
                                            , aHintMessage   => 'WFL-' || trim(to_char(ErrJoinUndefined, '0999') )
                                            , aSecondaryId   => ''
                                            , aObjectType    => ActivityType
                                            , aRecordId      => aActivityId
                                            , aCtrlErrId     => nCtrlErrId
                                             );
    end if;

    --teste si les packages d'événements, ainsi que le plsql pour participant dynamique existent
    if     (cActPartType = 'PART_PLSQL')
       and (length(cPartFunction) > 0) then
      if not ExistsPlSqlCode(cPartFunction) then
        WFL_WORKFLOW_CONTROL.InsertMessageError
                               (aErrCode       => ErrPlSqlPartPackage
                              , aHintMessage   => 'WFL-' ||
                                                  trim(to_char(ErrPlSqlPartPackage, '0999') ) ||
                                                  ' : ' ||
                                                  '"' ||
                                                  cPartFunction ||
                                                  '" ' ||
                                                  PCS.PC_FUNCTIONS.TranslateWord
                                                                              ('n''existe pas dans la base de donnée')
                              , aSecondaryId   => ''
                              , aObjectType    => ActivityType
                              , aRecordId      => aActivityId
                              , aCtrlErrId     => nCtrlErrId
                               );
      end if;
    end if;

    for tplEvents in crEvents(aActivityId => aActivityId) loop
      --test pour les packages, pour chaque package inexistant
      cPlSqlCode  := null;

      if tplEvents.C_WFL_EVENT_TYPE = 'SEND_MAIL' then
        cPlSqlCode  :=
                     WFL_EVENTS_FUNCTIONS.GetMailLaunchFunction(aMailProperties   => tplEvents.WAV_EVENT_TYPE_PROPERTIES);

        if not ExistsPlSqlCode(cPlSqlCode) then
          WFL_WORKFLOW_CONTROL.InsertMessageError
                               (aErrCode       => ErrNoActMailPackages
                              , aHintMessage   => 'WFL-' ||
                                                  trim(to_char(ErrNoActMailPackages, '0999') ) ||
                                                  ' : ' ||
                                                  '"' ||
                                                  cPlSqlCode ||
                                                  '" ' ||
                                                  PCS.PC_FUNCTIONS.TranslateWord
                                                                              ('n''existe pas dans la base de donnée')
                              , aSecondaryId   => to_char(tplEvents.WFL_ACTIVITY_EVENTS_ID)
                              , aObjectType    => ActivityType
                              , aRecordId      => aActivityId
                              , aCtrlErrId     => nCtrlErrId
                               );
        end if;
      elsif tplEvents.C_WFL_EVENT_TYPE = 'PLSQL_PROC' then
        cPlSqlCode  := WFL_EVENTS_FUNCTIONS.GetPlSqlCode(aPlSqlProperties => tplEvents.WAV_EVENT_TYPE_PROPERTIES);

        if not ExistsPlSqlCode(cPlSqlCode) then
          WFL_WORKFLOW_CONTROL.InsertMessageError
                               (aErrCode       => ErrNoActPlSqlPackages
                              , aHintMessage   => 'WFL-' ||
                                                  trim(to_char(ErrNoActPlSqlPackages, '0999') ) ||
                                                  ' : ' ||
                                                  '"' ||
                                                  cPlSqlCode ||
                                                  '" ' ||
                                                  PCS.PC_FUNCTIONS.TranslateWord
                                                                              ('n''existe pas dans la base de donnée')
                              , aSecondaryId   => to_char(tplEvents.WFL_ACTIVITY_EVENTS_ID)
                              , aObjectType    => ActivityType
                              , aRecordId      => aActivityId
                              , aCtrlErrId     => nCtrlErrId
                               );
        end if;
      end if;
    end loop;
  end GetActivityErrors;

  /*************** GetProcessErrors ******************************************/
  procedure GetProcessErrors(
    aProcessId      in WFL_PROCESSES.WFL_PROCESSES_ID%type
  , aClearTmpTables in WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  )
  is
    --curseur pour événements Mail et PlSql
    cursor crEvents(aProcessId in WFL_PROCESS_EVENTS.WFL_PROCESSES_ID%type)
    is
      select upper(C_WFL_EVENT_TYPE) C_WFL_EVENT_TYPE
           , WPV_EVENT_TYPE_PROPERTIES
           , WFL_PROCESS_EVENTS_ID
           , (C_WFL_EVENT_TYPE ||
              GSecIdSeparator ||
              C_WFL_PROCESS_STATE ||
              GSecIdSeparator ||
              C_WFL_EVENT_TIMING ||
              GSecIdSeparator ||
              WPV_EVENT_SEQ
             ) EVENT_SEC_ID
        from WFL_PROCESS_EVENTS
       where WFL_PROCESSES_ID = aProcessId;

    tplEvents           crEvents%rowtype;
    nCntPartAllow       pls_integer;
    nCntTrigObjects     pls_integer;
    nCntStartActivities pls_integer;
    nCtrlErrId          WFL_CTRL_ERRORS.WFL_CTRL_ERRORS_ID%type   default 0;
    cPlSqlCode          varchar2(200);
  begin
    if aClearTmpTables = 1 then
      --suppression dans les tables temporaires
      delete from WFL_ERR_MESSAGES;

      delete from WFL_CTRL_ERRORS;
    end if;

    select (select count(*)
              from WFL_PROCESS_PART_ALLOW
             where WFL_PROCESSES_ID = aProcessId)
         , (select count(*)
              from WFL_OBJECT_PROCESSES
             where WFL_PROCESSES_ID = aProcessId)
         , (select count(*)
              from WFL_ACTIVITIES ACT
             where ACT.WFL_PROCESSES_ID = aProcessId
               and not exists(select WFL_TRANSITIONS_ID
                                from WFL_TRANSITIONS
                               where WFL_TO_ACTIVITIES_ID = ACT.WFL_ACTIVITIES_ID) )
      into nCntPartAllow
         , nCntTrigObjects
         , nCntStartActivities
      from dual;

    if not(nCntPartAllow > 0) then
      WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrNoPartAllow
                                            , aHintMessage   => 'WFL-' || trim(to_char(ErrNoPartAllow, '0999') )
                                            , aSecondaryId   => ''
                                            , aObjectType    => ProcessType
                                            , aRecordId      => aProcessId
                                            , aCtrlErrId     => nCtrlErrId
                                             );
    end if;

    if not(nCntTrigObjects > 0) then
      WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrNoTrigObjects
                                            , aHintMessage   => 'WFL-' || trim(to_char(ErrNoTrigObjects, '0999') )
                                            , aSecondaryId   => ''
                                            , aObjectType    => ProcessType
                                            , aRecordId      => aProcessId
                                            , aCtrlErrId     => nCtrlErrId
                                             );
    end if;

    if not(nCntStartActivities > 0) then
      WFL_WORKFLOW_CONTROL.InsertMessageError(aErrCode       => ErrManyStartActivity
                                            , aHintMessage   => 'WFL-' || trim(to_char(ErrManyStartActivity, '0999') )
                                            , aSecondaryId   => ''
                                            , aObjectType    => ProcessType
                                            , aRecordId      => aProcessId
                                            , aCtrlErrId     => nCtrlErrId
                                             );
    end if;

    for tplEvents in crEvents(aProcessId => aProcessId) loop
      --test pour les packages, pour chaque package inexistant
      cPlSqlCode  := null;

      if tplEvents.C_WFL_EVENT_TYPE = 'SEND_MAIL' then
        cPlSqlCode  :=
                     WFL_EVENTS_FUNCTIONS.GetMailLaunchFunction(aMailProperties   => tplEvents.WPV_EVENT_TYPE_PROPERTIES);

        if not ExistsPlSqlCode(cPlSqlCode) then
          WFL_WORKFLOW_CONTROL.InsertMessageError
                               (aErrCode       => ErrNoProcMailPackages
                              , aHintMessage   => 'WFL-' ||
                                                  trim(to_char(ErrNoProcMailPackages, '0999') ) ||
                                                  ' : ' ||
                                                  '"' ||
                                                  cPlSqlCode ||
                                                  '" ' ||
                                                  PCS.PC_FUNCTIONS.TranslateWord
                                                                              ('n''existe pas dans la base de donnée')
                              , aSecondaryId   => to_char(tplEvents.WFL_PROCESS_EVENTS_ID)
                              , aObjectType    => ProcessType
                              , aRecordId      => aProcessId
                              , aCtrlErrId     => nCtrlErrId
                               );
        end if;
      elsif tplEvents.C_WFL_EVENT_TYPE = 'PLSQL_PROC' then
        cPlSqlCode  := WFL_EVENTS_FUNCTIONS.GetPlSqlCode(aPlSqlProperties => tplEvents.WPV_EVENT_TYPE_PROPERTIES);

        if not ExistsPlSqlCode(cPlSqlCode) then
          WFL_WORKFLOW_CONTROL.InsertMessageError
                               (aErrCode       => ErrNoProcPlSqlPackages
                              , aHintMessage   => 'WFL-' ||
                                                  trim(to_char(ErrNoProcPlSqlPackages, '0999') ) ||
                                                  ' : ' ||
                                                  '"' ||
                                                  cPlSqlCode ||
                                                  '" ' ||
                                                  PCS.PC_FUNCTIONS.TranslateWord
                                                                              ('n''existe pas dans la base de donnée')
                              , aSecondaryId   => to_char(tplEvents.WFL_PROCESS_EVENTS_ID)
                              , aObjectType    => ProcessType
                              , aRecordId      => aProcessId
                              , aCtrlErrId     => nCtrlErrId
                               );
        end if;
      end if;
    end loop;
  end GetProcessErrors;

  /*************** ControlProcessIntegrity ***********************************/
  procedure ControlProcessIntegrity(aProcessId in WFL_PROCESSES.WFL_PROCESSES_ID%type)
  is
    --curseur qui récupère les activités du processus
    cursor crGetActivities(aProcessId in WFL_PROCESSES.WFL_PROCESSES_ID%type)
    is
      select WFL_ACTIVITIES_ID
        from WFL_ACTIVITIES
       where WFL_PROCESSES_ID = aProcessId;

    --curseur qui récupère les transitions d'un processus
    cursor crGetTransitions(aProcessId in WFL_PROCESSES.WFL_PROCESSES_ID%type)
    is
      select distinct (WFL_TRANSITIONS_ID)
                 from WFL_TRANSITIONS
                where WFL_FROM_PROCESSES_ID = aProcessId
                   or WFL_TO_PROCESSES_ID = aProcessId;

    tplActivities  crGetActivities%rowtype;
    tplTransitions crGetTransitions%rowtype;
  begin
    --Création utilisateur Workflow si inexistant
    PCS.PC_WFL_PARTICIPANTS_FUNCTIONS.CreateWorkflowParticipant;

    --Vide la liste des erreurs et controle le processus
    delete from WFL_ERR_MESSAGES;

    delete from WFL_CTRL_ERRORS;

    WFL_WORKFLOW_CONTROL.GetProcessErrors(aProcessId => aProcessId, aClearTmpTables => 0);

    --controle des activités du processus
    for tplActivities in crGetActivities(aProcessId => aProcessId) loop
      WFL_WORKFLOW_CONTROL.GetActivityErrors(aActivityId => tplActivities.WFL_ACTIVITIES_ID, aClearTmpTables => 0);
    end loop;

    --controle des transitions du processus
    for tplTransitions in crGetTransitions(aProcessId => aProcessId) loop
      WFL_WORKFLOW_CONTROL.GetTransitionErrors(aTransitionId     => tplTransitions.WFL_TRANSITIONS_ID
                                             , aClearTmpTables   => 0);
    end loop;
  end ControlProcessIntegrity;

  /*************** GetErrorsCtrl / GetErrorsCtrlXmlType **********************/
  function GetErrorsCtrl
    return clob
  is
    ErrCtrl xmltype;
  begin
    ErrCtrl  := WFL_WORKFLOW_CONTROL.GetErrorsCtrlXmlType;
    return PCS.PC_ISS_UTILS.XmlEncodingDef || ErrCtrl.getClobVal();
  end GetErrorsCtrl;

  function GetErrorsCtrlXmlType
    return xmltype
  is
    result xmltype;
  begin
    --requêtes sur les tables temporaires
    return result;
  end GetErrorsCtrlXmlType;
end WFL_WORKFLOW_CONTROL;
