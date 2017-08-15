--------------------------------------------------------
--  DDL for Package Body WFL_TASK_MANAGEMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WFL_TASK_MANAGEMENT" 
is
  gGrantRelType      PCS.PC_WFL_PARTICIPANT_RELATIONS.C_PC_WFL_RELATION_TYPE%type   := 'GRANT';
  gMemberOfRelType   PCS.PC_WFL_PARTICIPANT_RELATIONS.C_PC_WFL_RELATION_TYPE%type   := 'MEMBER OF';
  gProxyOfRelType    PCS.PC_WFL_PARTICIPANT_RELATIONS.C_PC_WFL_RELATION_TYPE%type   := 'PROXY OF';


 /*********************** PrintError ******************************************************/
  procedure PrintError(aErrorCodes   varchar2
                     , aErrorMessages varchar2)
  is
  begin
    DBMS_OUTPUT.put_line('ErrorCodes: ' || aErrorCodes);
    DBMS_OUTPUT.put_line('Messages: ');
    DBMS_OUTPUT.put_line(aErrorMessages);
  end;

  /**
   * Procedure PrintText
   * Description
   *    Print title and message in TOAD console.
   */
  procedure PrintMessage(aTitle   varchar2
                       , aMessage varchar2)
  is
  begin
    DBMS_OUTPUT.put_line(aTitle || ': ' || aMessage);
  end;


/*********************** GetTaskId ******************************************/
  function  GetTaskId(  aObjectId          in PCS.PC_OBJECT.PC_OBJECT_ID%type
                      , aOwnerId           in WFL_ACTIVITY_INSTANCES.AIN_OWNER_ID%type
                      , aTaskTypeName      in WFL_ACTIVITIES.ACT_NAME%type
                      , aRecordId          in PCS.PC_TABLE.PC_TABLE_ID%type
                      , aState             in WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type
                      , aParticipantId     in WFL_ACTIVITY_INSTANCES.PC_WFL_PARTICIPANTS_ID%type
  ) return WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  is
    nTaskId WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type;
  begin

    --Récupération de l'id de l'instance de l'activité
    -- Si plusieurs instances d'activités, on prend le plus récent
    begin
      select ain.WFL_ACTIVITY_INSTANCES_ID
      into   nTaskId
      from   WFL_ACTIVITY_INSTANCES ain,
             WFL_ACTIVITIES act
      where  ain.PC_OBJECT_ID = aObjectId
         and ain.AIN_OWNER_ID = aOwnerId
         and ain.AIN_RECORD_ID = aRecordId
         and ain.C_WFL_ACTIVITY_STATE = aState
         and ain.WFL_ACTIVITIES_ID = act.WFL_ACTIVITIES_ID
         and ain.PC_WFL_PARTICIPANTS_ID is null
         and act.ACT_NAME = aTaskTypeName
         and act.ACT_TASK = 1
         and rownum = 1
         order by act.A_DATECRE desc;
      exception
      when no_data_found then
      begin
        nTaskId := 0;
      end;
    end;
    return nTaskId;
  end GetTaskId;

  /*********************** CreateTaskInstances ******************************************/
  procedure  ExistTask( aObjectId           in PCS.PC_OBJECT.PC_OBJECT_ID%type
                      , aOwnerId           in WFL_ACTIVITY_INSTANCES.AIN_OWNER_ID%type
                      , aTaskTypeName      in WFL_ACTIVITIES.ACT_NAME%type
                      , aRecordId          in PCS.PC_TABLE.PC_TABLE_ID%type
                      , aTaskExist         out number
                      )
  is
     nNumberTasks number;
  begin

    --Récupération du nobmre d'instances existante
    begin
      select Count(ain.WFL_ACTIVITY_INSTANCES_ID)
      into   nNumberTasks
      from   WFL_ACTIVITY_INSTANCES ain,
             WFL_ACTIVITIES act
      where  ain.PC_OBJECT_ID = aObjectId
         and ain.AIN_OWNER_ID = aOwnerId
         and ain.AIN_RECORD_ID = aRecordId
         and ain.C_WFL_ACTIVITY_STATE in ('NOTRUNNING', 'RUNNING', 'SUSPENDED')
         and ain.WFL_ACTIVITIES_ID = act.WFL_ACTIVITIES_ID
         and act.ACT_NAME = aTaskTypeName
         and act.ACT_TASK = 1
         order by act.A_DATECRE desc;
      exception
      when no_data_found then
      begin
        nNumberTasks := 0;
      end;
    end;

    aTaskExist := 0;
    if nNumberTasks > 0 then
      aTaskExist := 1;
    end if;

  end ExistTask;

/*********************** CreateTaskInstances ******************************************/
  procedure CreateTaskInstances(
    aObjectId          in PCS.PC_OBJECT.PC_OBJECT_ID%type
  , aOwnerId           in WFL_ACTIVITY_INSTANCES.AIN_OWNER_ID%type
  , aTaskDescription   in WFL_ACTIVITY_INSTANCES.AIN_LONG_DESCRIPTION%type
  , aTaskTypeName      in WFL_ACTIVITIES.ACT_NAME%type
  , aTableName         in PCS.PC_TABLE.TABNAME%type
  , aRecordId          in PCS.PC_TABLE.PC_TABLE_ID%type
  , aComment           in WFL_ACTIVITY_INSTANCES.AIN_REMARKS%type
  , aPriority          in WFL_ACTIVITY_INSTANCES.C_WFL_TASK_PRIORITY%type
  , aDueDate           in WFL_ACTIVITY_INSTANCES.AIN_DATE_DUE%type
  , aParentId          in WFL_ACTIVITY_INSTANCES.WFL_WFL_ACTIVITY_INSTANCES_ID%type
  , aState             in WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type
  , aDraftState        in WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type := null
  , aTopic             in WFL_ACTIVITY_INSTANCES.AIN_TOPIC%type
  , aAutoStart         in number
  , aSuccess           out number
  )
  is
    nTaskTypeId WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type;
    nProcessId  WFL_PROCESSES.WFL_PROCESSES_ID%type;
    nProcessInstanceId WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type;
    nValidationRequired WFL_ACTIVITIES.ACT_VALIDATION_REQUIRED%type;
    nGuestsAuthorized  WFL_ACTIVITIES.ACT_GUESTS_AUTHORIZED%type;
    nEmail  WFL_ACTIVITIES.ACT_EMAILTO_PARTICIPANTS%type;
    cUserIni  WFL_ACTIVITY_INSTANCES.A_IDCRE%type;
    nParticipantUserId PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type;
    nParentId WFL_ACTIVITY_INSTANCES.WFL_WFL_ACTIVITY_INSTANCES_ID%type;
    nTaskId   WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type;
  begin
    aSuccess := 0;

    begin
      select  ACT.WFL_ACTIVITIES_ID,
              ACT.WFL_PROCESSES_ID,
              wpo.WFL_PROCESS_INSTANCES_ID
      into    nTaskTypeId,
              nProcessId,
              nProcessInstanceId
      from    WFL_ACTIVITIES ACT,

              WFL_PROCESS_INSTANCES wpo
      where   ACT.ACT_NAME = aTaskTypeName
        and   wpo.WFL_PROCESSES_ID = ACT.WFL_PROCESSES_ID;

      exception
      when no_data_found then
      begin
        return;
      end;
    end;

    nParentId := aParentId;
    if aParentId = 0 then
      nParentId := null;
    end if;

    begin
      select  ACT.ACT_VALIDATION_REQUIRED
      into    nValidationRequired
      from    WFL_ACTIVITIES act
      where   act.WFL_ACTIVITIES_ID = nTaskTypeId;

      exception
      when no_data_found then
      begin
        nValidationRequired := 0;
      end;
    end;

    begin
      select  ACT.ACT_GUESTS_AUTHORIZED
      into    nGuestsAuthorized
      from    WFL_ACTIVITIES act
      where   act.WFL_ACTIVITIES_ID = nTaskTypeId;

      exception
      when no_data_found then
      begin
        nGuestsAuthorized := 0;
      end;
    end;

    begin
      select  ACT.ACT_EMAILTO_PARTICIPANTS
      into    nEmail
      from    WFL_ACTIVITIES act
      where   act.WFL_ACTIVITIES_ID = nTaskTypeId;

      exception
      when no_data_found then
      begin
        nEmail:= 0;
      end;
    end;

    begin
      select  pcu.USE_INI
      into    cUserIni
      from    PCS.PC_USER pcu
      where   pcu.PC_USER_ID = aOwnerId;

      exception
      when no_data_found then
      begin
        cUserIni:= 'AAA';
      end;
    end;


    nTaskId := 0;
    if aDraftState is not null then
     nTaskId :=  WFL_TASK_MANAGEMENT.GetTaskId(aObjectId,aOwnerId,aTaskTypeName,aRecordId,aDraftState,null);
    end if;

    if (aDraftState is null) or ((aDraftState is not null) and (nTaskId = 0)) then

      insert into WFL_ACTIVITY_INSTANCES(
                 WFL_ACTIVITY_INSTANCES_ID,
                 WFL_PROCESS_INSTANCES_ID,
                 WFL_PROCESSES_ID,
                 WFL_ACTIVITIES_ID,
                 AIN_LONG_DESCRIPTION,
                 AIN_DATE_CREATED,
                 C_WFL_ACTIVITY_STATE,
                 AIN_REMARKS,
                 A_DATECRE,
                 A_IDCRE,
                 AIN_VALIDATION_REQUIRED,
                 AIN_GUESTS_AUTHORIZED,
                 AIN_EMAILTO_PARTICIPANTS,
                 PC_OBJECT_ID,
                 AIN_OWNER_ID,
                 AIN_DATE_DUE,
                 C_WFL_TASK_PRIORITY,
                 AIN_RECORD_ID,
                 WFL_WFL_ACTIVITY_INSTANCES_ID,
                 AIN_TOPIC)
          values(INIT_ID_SEQ.NEXTVAL,
                 nProcessInstanceId,
                 nProcessId,
                 nTaskTypeId,
                 aTaskDescription,
                 sysdate,
                 aState,
                 aComment,
                 sysdate,
                 cUserIni,
                 nValidationRequired,
                 nGuestsAuthorized,
                 nEmail,
                 aObjectId,
                 aOwnerId,
                 aDueDate,
                 aPriority,
                 aRecordId,
                 nParentId,
                 aTopic);

      aSuccess := 1;
    else
      if nTaskId > 0 then
        UPDATE WFL_ACTIVITY_INSTANCES ain set
               ain.AIN_LONG_DESCRIPTION = aTaskDescription,
               ain.AIN_DATE_CREATED = sysdate,
               ain.C_WFL_ACTIVITY_STATE = aState,
               ain.AIN_REMARKS = aComment,
               ain.A_DATECRE = sysdate,
               ain.A_IDCRE = cUserIni,
               ain.AIN_VALIDATION_REQUIRED = nValidationRequired,
               ain.AIN_GUESTS_AUTHORIZED = nGuestsAuthorized,
               ain.AIN_EMAILTO_PARTICIPANTS = nEmail,
               ain.PC_OBJECT_ID = aObjectId,
               ain.AIN_OWNER_ID = aOwnerId,
               ain.AIN_DATE_DUE = aDueDate,
               ain.C_WFL_TASK_PRIORITY = aPriority,
               ain.AIN_RECORD_ID = aRecordId,
               ain.WFL_WFL_ACTIVITY_INSTANCES_ID = nParentId ,
               ain.AIN_TOPIC = aTopic
        where  ain.WFL_ACTIVITY_INSTANCES_ID = nTaskId;
          aSuccess := 1;
      end if;
    end if;
  end CreateTaskInstances;

  /*************** Procédure pour créer une tâche à partir d'une autre tâche********/
  function CreateTaskInstance(
    aTaskId            in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aParticipantId     in PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type
  ) return number
  is
    nResult number;
  begin
    select
    INIT_ID_SEQ.NEXTVAL
    into nResult
    from dual;

    if aTaskId > 0 then
      insert into WFL_ACTIVITY_INSTANCES(
                 WFL_ACTIVITY_INSTANCES_ID,
                 WFL_PROCESS_INSTANCES_ID,
                 WFL_PROCESSES_ID,
                 WFL_ACTIVITIES_ID,
                 AIN_LONG_DESCRIPTION,
                 AIN_DATE_CREATED,
                 C_WFL_ACTIVITY_STATE,
                 AIN_REMARKS,
                 PC_WFL_PARTICIPANTS_ID,
                 A_DATECRE,
                 A_IDCRE,
                 AIN_VALIDATION_REQUIRED,
                 AIN_GUESTS_AUTHORIZED,
                 AIN_EMAILTO_PARTICIPANTS,
                 PC_OBJECT_ID,
                 AIN_OWNER_ID,
                 AIN_DATE_DUE,
                 C_WFL_TASK_PRIORITY,
                 AIN_RECORD_ID,
                 WFL_WFL_ACTIVITY_INSTANCES_ID,
                 AIN_TOPIC)
         select
                 nResult,
                 ain.WFL_PROCESS_INSTANCES_ID,
                 ain.WFL_PROCESSES_ID,
                 ain.WFL_ACTIVITIES_ID,
                 ain.AIN_LONG_DESCRIPTION,
                 ain.AIN_DATE_CREATED,
                 ain.C_WFL_ACTIVITY_STATE,
                 ain.AIN_REMARKS,
                 aParticipantId,
                 sysdate,
                 ain.A_IDCRE,
                 ain.AIN_VALIDATION_REQUIRED,
                 ain.AIN_GUESTS_AUTHORIZED,
                 ain.AIN_EMAILTO_PARTICIPANTS,
                 ain.PC_OBJECT_ID,
                 ain.AIN_OWNER_ID,
                 ain.AIN_DATE_DUE,
                 ain.C_WFL_TASK_PRIORITY,
                 ain.AIN_RECORD_ID,
                 ain.WFL_WFL_ACTIVITY_INSTANCES_ID,
                 ain.AIN_TOPIC
        from WFL_ACTIVITY_INSTANCES ain
       where ain.WFL_ACTIVITY_INSTANCES_ID = aTaskId;
     end if;
     return nResult;
  end;

 /*********************** AddParticipantToTask ******************************************/
  procedure AddParticipantToTask( aParticipantId     in PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type
                                , aObjectId          in PCS.PC_OBJECT.PC_OBJECT_ID%type
                                , aOwnerId           in WFL_ACTIVITY_INSTANCES.AIN_OWNER_ID%type
                                , aTaskTypeName      in WFL_ACTIVITIES.ACT_NAME%type
                                , aRecordId          in PCS.PC_TABLE.PC_TABLE_ID%type
                                , aState             in WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type
  )
  is
    nTaskId WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type;
  begin

    nTaskId :=  WFL_TASK_MANAGEMENT.GetTaskId(aObjectId,aOwnerId,aTaskTypeName,aRecordId,aState,null);
    if (nTaskId > 0) and (aParticipantId > 0) then
      INSERT INTO WFL_TASK_PARTICIPANT_GROUP(
                   WFL_ACTIVITY_INSTANCES_ID,
                   PC_WFL_PARTICIPANTS_ID)
            values(nTaskId,
                   aParticipantId);
    end if;
  end AddParticipantToTask;

 /*********************** ClearParticipantsFromTask ******************************************/
  procedure ClearParticipantsFromTask(  aObjectId          in PCS.PC_OBJECT.PC_OBJECT_ID%type
                                      , aOwnerId           in WFL_ACTIVITY_INSTANCES.AIN_OWNER_ID%type
                                      , aTaskTypeName      in WFL_ACTIVITIES.ACT_NAME%type
                                      , aRecordId          in PCS.PC_TABLE.PC_TABLE_ID%type
                                      , aState             in WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type
    )
  is
    nTaskId WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type;
  begin
    nTaskId :=  WFL_TASK_MANAGEMENT.GetTaskId(aObjectId,aOwnerId,aTaskTypeName,aRecordId,aState,null);

    if (nTaskId > 0) then
      DELETE FROM WFL_TASK_PARTICIPANT_GROUP wpg
            WHERE wpg.WFL_ACTIVITY_INSTANCES_ID = nTaskId ;
    end if;
  end ClearParticipantsFromTask;

 /*********************** DeleteDraft ******************************************************/
  procedure DeleteDraft( aActivityInstanceId  in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
                       )
  is
  begin

    if (aActivityInstanceId > 0) then
      DELETE FROM WFL_TASK_PARTICIPANT_GROUP wpg
            WHERE wpg.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId ;
    end if;

    Delete from WFL_ACTIVITY_INSTANCES ain
          where ain.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;
  end DeleteDraft;

 /*********************** AffectTask ******************************************************/
  procedure AffectTask( aObjectId          in PCS.PC_OBJECT.PC_OBJECT_ID%type
                      , aOwnerId           in WFL_ACTIVITY_INSTANCES.AIN_OWNER_ID%type
                      , aTaskTypeName      in WFL_ACTIVITIES.ACT_NAME%type
                      , aRecordId          in PCS.PC_TABLE.PC_TABLE_ID%type
                      , aTaskTypeKind      in WFL_ACTIVITIES.C_WFL_TASK_KIND%type
                      , aState             in WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type
                      )
  is
    cursor crTask(aTaskId WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type)
    is
      select  ain.WFL_ACTIVITY_INSTANCES_ID, par.PC_USER_ID,wpg.PC_WFL_PARTICIPANTS_ID, act.ACT_AUTOMATIC_ALLOCATION
        from  WFL_ACTIVITY_INSTANCES ain
            , WFL_ACTIVITIES act
            , WFL_TASK_PARTICIPANT_GROUP wpg
            , PCS.PC_WFL_PARTICIPANTS par
        where ain.WFL_ACTIVITIES_ID = act.WFL_ACTIVITIES_ID
          and act.ACT_TASK = 1
          and wpg.WFL_ACTIVITY_INSTANCES_ID = ain.WFL_ACTIVITY_INSTANCES_ID
          and par.PC_WFL_PARTICIPANTS_ID = wpg.PC_WFL_PARTICIPANTS_ID
          and ain.WFL_ACTIVITY_INSTANCES_ID = aTaskId;
    tplTask crTask%rowtype;
    nTaskId WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type;
    nNewTaskId WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type;
    nLock number;
    nParticipantsCount number;
    nUserId  PCS.PC_WFL_PARTICIPANTS.PC_USER_ID%type;
    nParticipantsId PCS.PC_WFL_PARTICIPANTS.PC_WFL_PARTICIPANTS_ID%type;
  begin

    --L'état draft ne doit rien affecté
    if aState = 'DRAFT' then
      return;
    end if;

    nTaskId :=  WFL_TASK_MANAGEMENT.GetTaskId(aObjectId,aOwnerId,aTaskTypeName,aRecordId,aState,null);
    if aTaskTypeKind = 'STANDARD' then
      --Récupération du nombre de participants lié à la tâche
      begin
        select count(wpg.PC_WFL_PARTICIPANTS_ID)
          into nParticipantsCount
          from WFL_TASK_PARTICIPANT_GROUP wpg
         where wpg.WFL_ACTIVITY_INSTANCES_ID = nTaskId;
        exception
        when no_data_found then
        begin
          nParticipantsCount:= 0;
        end;
      end;

      --Mise à jour et démarrage de la tâche si un seul participant
      if nParticipantsCount = 1 then
        begin
          select wpg.PC_WFL_PARTICIPANTS_ID,
                 par.PC_USER_ID
            into nParticipantsId,
                 nUserId
            from WFL_TASK_PARTICIPANT_GROUP wpg,
                 PCS.PC_WFL_PARTICIPANTS par
           where wpg.WFL_ACTIVITY_INSTANCES_ID = nTaskId
             and par.PC_WFL_PARTICIPANTS_ID = wpg.PC_WFL_PARTICIPANTS_ID;
          exception
          when no_data_found then
          begin
            nParticipantsId := 0;
            nUserId := 0;
          end;
        end;

        if nParticipantsId > 0 then
          update WFL_ACTIVITY_INSTANCES ain set
                 ain.PC_WFL_PARTICIPANTS_ID = nParticipantsId;
        end if;

        if nUserId > 0 then
          WFL_WORKFLOW_UTILS.StartActivity(nTaskId,nUserId,nLock);
        end if;
      end if;
    else
      if  (nTaskId > 0) and aTaskTypeKind ='INFO' then
        for tplTask in crTask(nTaskId) loop
          nNewTaskId := CreateTaskInstance(tplTask.WFL_ACTIVITY_INSTANCES_ID,tplTask.PC_WFL_PARTICIPANTS_ID);
            if  (tplTask.ACT_AUTOMATIC_ALLOCATION = 1) and (nNewTaskId > 0)
              and tplTask.PC_USER_ID is not null then
              WFL_WORKFLOW_UTILS.StartActivity(nNewTaskId,tplTask.PC_USER_ID,nLock);
            end if;
        end loop;

        Delete from WFL_TASK_PARTICIPANT_GROUP wpg
              where wpg.WFL_ACTIVITY_INSTANCES_ID = nTaskId;

        Delete from WFL_ACTIVITY_INSTANCES ain
              where ain.WFL_ACTIVITY_INSTANCES_ID = nTaskId
                and ain.C_WFL_ACTIVITY_STATE <> 'DRAFT';

      end if;
    end if;
  end AffectTask;

  procedure DeadlineOverFunctionTaskEmail(
   aTaskId             in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  )
  is
    vErrorMessages        varchar2(4000);
    vErrorCodes           varchar2(4000);
    vTempRaw              raw(4000)  := 'E72848574873FE293482AB4930C93837D7839E00290F939A929BC03CB035';
    vTempBLOB             blob       := vTempRaw;
    vTempCLOB             clob       := 'Hello, this is an attachment';
    vMailID               number;
    cSenderEmail          varchar2(4000);
    cMailSubjectHeader    varchar2(4000);
    cTaskBody             varchar2(4000);
    nParticipantId        WFL_ACTIVITY_INSTANCES.PC_WFL_PARTICIPANTS_ID%type;
    nReceiverEmail        PCS.PC_WFL_PARTICIPANTS.WPA_NAME%type;
    cTaskName             WFL_ACTIVITY_INSTANCES.AIN_LONG_DESCRIPTION%type;
  begin
    dbms_java.set_output(5000);

    cMailSubjectHeader := pcs.pc_functions.TranslateWord('Tâche dépassée de date',pcs.PC_I_LIB_SESSION.GetUserLangId);
    cSenderEmail := 'workflow@proconcept.ch';

    select  ain.PC_WFL_PARTICIPANTS_ID
      into  nParticipantId
      from  WFL_ACTIVITY_INSTANCES ain
      where ain.WFL_ACTIVITY_INSTANCES_ID = aTaskId;

    select  ain.AIN_LONG_DESCRIPTION
      into  cTaskName
      from  WFL_ACTIVITY_INSTANCES ain
      where ain.WFL_ACTIVITY_INSTANCES_ID = aTaskId;

   cTaskBody := '<BR>'
                || pcs.pc_functions.TranslateWord('Bonjour',pcs.PC_I_LIB_SESSION.GetUserLangId)
                || '<BR>'
                || '<BR>'
                || pcs.pc_functions.TranslateWord('Vous n''avez pas pris en charge votre tâche dans les délais.',pcs.PC_I_LIB_SESSION.GetUserLangId)
                || pcs.pc_functions.TranslateWord('Vous êtes priés de compléter la tâche.',pcs.PC_I_LIB_SESSION.GetUserLangId)
                || '<BR>'
                || pcs.pc_functions.TranslateWord('Description de la tâche: ',pcs.PC_I_LIB_SESSION.GetUserLangId)
                || cTaskName
                || '<BR>'
                || '<BR>'
                || pcs.pc_functions.TranslateWord('Salutations',pcs.PC_I_LIB_SESSION.GetUserLangId);
   if nParticipantId is not null then
     select  par.WPA_EMAIL
       into  nReceiverEmail
       from  PCS.PC_WFL_PARTICIPANTS par
       where par.PC_WFL_PARTICIPANTS_ID = nParticipantId;
   end if;

    -- Creates e-mail and stores it in default e-mail object
    vErrorCodes  :=
      EML_SENDER.CreateMail(aErrorMessages    => vErrorMessages
                          , aSender           => cSenderEMail
                          , aRecipients       => nReceiverEmail
                          , aBccRecipients    => ''
                          , aNotification     => 0
                          , aPriority         => EML_SENDER.cPRIOTITY_HIGH_LEVEL
                          , aCustomHeaders    => 'X-Mailer: PCS mailer'
                          , aSubject          => cMailSubjectHeader
                          , aBodyPlain        => cTaskBody
                          , aBodyHTML         =>  cTaskBody
                          , aSendMode         => EML_SENDER.cSENDMODE_IMMEDIATE
                          , aDateToSend       => sysdate
                          , aTimeZoneOffset   => sessiontimezone   --'02:00'
                          , aBackupMode       => EML_SENDER.cBACKUP_DATABASE
                           --, aBackupOptions    => ''
                           );
     PrintError(vErrorCodes, vErrorMessages);

    -- Sends the e-mail contained in default e-mail object (in fact stores it in a queue)
    vErrorCodes  := vErrorCodes ||
    	EML_SENDER.Send(aErrorMessages => vErrorMessages, aMailID => vMailID);
  end DeadlineOverFunctionTaskEmail;


  procedure CheckTasksDeadline(
    aDate              in  WFL_ACTIVITY_INSTANCES.AIN_DATE_DUE%type
  )
  is
    nTaskId WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type;
    cursor crActTask(aDate WFL_ACTIVITY_INSTANCES.AIN_DATE_DUE%type)
    is
      select  ain.WFL_ACTIVITY_INSTANCES_ID
        from  WFL_ACTIVITY_INSTANCES ain, WFL_ACTIVITIES act
        where ain.WFL_ACTIVITIES_ID = act.WFL_ACTIVITIES_ID
          and act.ACT_TASK = 1
          and (ain.C_WFL_ACTIVITY_STATE ='RUNNING'
               or ain.C_WFL_ACTIVITY_STATE = 'NOTRUNNING'
               or ain.C_WFL_ACTIVITY_STATE = 'SUSPENDED')
          and ain.AIN_DATE_DUE < aDate;
    tplActTask crActTask%rowtype;
  begin
    for tplActTask in crActTask(aDate) loop
      WFL_TASK_MANAGEMENT.DeadlineOverFunctionTaskEmail(tplActTask.WFL_ACTIVITY_INSTANCES_ID);
    end loop;
  end CheckTasksDeadline;

  procedure ExistTaskDraft(
    aObjectId          in  WFL_ACTIVITY_INSTANCES.PC_OBJECT_ID%type
  , aOwnerId            in  WFL_ACTIVITY_INSTANCES.AIN_OWNER_ID%type
  , aTaskTypeName      in  WFL_ACTIVITIES.ACT_NAME%type
  , aRecordId          in  WFL_ACTIVITY_INSTANCES.AIN_RECORD_ID%type
  , aState             in  WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type
  , aDraftCount        out number
  )
  is
    nTaskCount number;
  begin
    nTaskCount := 0;
    begin
      select Count(ain.WFL_ACTIVITY_INSTANCES_ID)
        into nTaskCount
        from WFL_ACTIVITY_INSTANCES ain,
             WFL_ACTIVITIES act
       where ain.PC_OBJECT_ID = aObjectId
         and ain.AIN_OWNER_ID = aOwnerId
         and ain.AIN_RECORD_ID = aRecordId
         and ain.C_WFL_ACTIVITY_STATE = aState
         and ain.WFL_ACTIVITIES_ID = act.WFL_ACTIVITIES_ID
         and act.ACT_NAME = aTaskTypeName
         and act.ACT_TASK = 1;
    exception
      when no_data_found then
      begin
        nTaskCount := 0;
      end;
    end;
    aDraftCount := nTaskCount;
  end ExistTaskDraft;

  /*************** Teste si le type de tâche est read-only ********/
  procedure  isTaskTypeReadOnly(  aTaskTypeId  in WFL_ACTIVITIES.WFL_ACTIVITIES_ID%type,
                                  aReadOnly    out number  )
  is
   nTaskInstancesCnt number;
  begin
    aReadOnly := 0;
    --Le type de tâche est read-only si des tâches existent encore
    select count(ain.WFL_ACTIVITIES_ID)
      into nTaskInstancesCnt
      from WFL_ACTIVITIES act,
           WFL_ACTIVITY_INSTANCES ain
     where act.WFL_ACTIVITIES_ID = aTaskTypeId
       and ain.WFL_ACTIVITIES_ID = act.WFL_ACTIVITIES_ID
       and ain.C_WFL_ACTIVITY_STATE <> 'DRAFT';

    if nTaskInstancesCnt > 0 then
      aReadOnly := 1;
    end if;

  end isTaskTypeReadOnly;

  procedure CreateTaskProcessInstanceLog( aProcessInstanceLogId out WFL_PROCESS_INST_LOG.WFL_PROCESS_INST_LOG_ID%type)
  is
  begin
    INSERT INTO WFL_PROCESS_INST_LOG(
                WFL_PROCESS_INST_LOG_ID,
                WFL_PROCESSES_ID,
                C_WFL_PROCESS_STATE,
                PRI_DATE_CREATED,
                A_DATECRE
                )
       SELECT   INIT_ID_SEQ.NEXTVAL,
                pro.WFL_PROCESSES_ID,
                pri.C_WFL_PROCESS_STATE,
                sysdate,
                sysdate
          FROM  WFL_PROCESSES pro,
                WFL_PROCESS_INSTANCES pri
          WHERE pro.PRO_NAME = 'TASKTYPEPROCESS'
            AND pri.WFL_PROCESSES_ID = pro.WFL_PROCESSES_ID;

    select  pri.WFL_PROCESS_INST_LOG_ID
    into    aProcessInstanceLogId
    from    WFL_PROCESS_INST_LOG pri,
            WFL_PROCESSES        pro
    where   pri.WFL_PROCESSES_ID = pro.WFL_PROCESSES_ID
      and   pro.PRO_NAME = 'TASKTYPEPROCESS';


  end;

  procedure isTaskSubTreeCompleted(
    aTaskId            in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aisFinished        in out number
  )
  is
    cursor crTask(aTaskId WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type)
    is
      select  ain.WFL_ACTIVITY_INSTANCES_ID, ain.C_WFL_ACTIVITY_STATE
        from  WFL_ACTIVITY_INSTANCES ain, WFL_ACTIVITIES act
        where ain.WFL_ACTIVITIES_ID = act.WFL_ACTIVITIES_ID
          and act.ACT_TASK = 1
          and ain.WFL_WFL_ACTIVITY_INSTANCES_ID = aTaskId;
    tplTask crTask%rowtype;
    nisFinished number;
  begin
    nisFinished := 1;
    for tplTask in crTask(aTaskId) loop
      if tplTask.C_WFL_ACTIVITY_STATE = 'COMPLETED' then
        WFL_TASK_MANAGEMENT.isTaskSubTreeCompleted(tplTask.WFL_ACTIVITY_INSTANCES_ID, nisFinished);
      else
        nisFinished := 0;
      end if;
    end loop;

    if (nisFinished = 0) then
      aisFinished := 0;
    end if;

    if (nisFinished = 1) then
      aisFinished := 1;
    end if;

  end isTaskSubTreeCompleted;


  procedure ArchiveTasks(
    aTaskId            in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  )
  is
    cursor crTask(aTaskId WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type)
    is
      select  ain.WFL_ACTIVITY_INSTANCES_ID, ain.C_WFL_ACTIVITY_STATE
        from  WFL_ACTIVITY_INSTANCES ain, WFL_ACTIVITIES act
        where ain.WFL_ACTIVITIES_ID = act.WFL_ACTIVITIES_ID
          and act.ACT_TASK = 1
          and ain.WFL_WFL_ACTIVITY_INSTANCES_ID = aTaskId;
    tplTask crTask%rowtype;
    nProcessInstLogId  WFL_ACTIVITY_INST_LOG.WFL_ACTIVITY_INST_LOG_ID%type;
  begin

    begin
      select wpi.WFL_PROCESS_INST_LOG_ID
      into   nProcessInstLogId
      from   WFL_PROCESS_INST_LOG wpi,
             WFL_PROCESSES wpr
      where  wpi.WFL_PROCESSES_ID = wpr.WFL_PROCESSES_ID
        and  wpr.PRO_NAME = 'TASKTYPEPROCESS';
    exception
      when no_data_found then
      begin
        CreateTaskProcessInstanceLog(nProcessInstLogId);
      end;
    end;

    if nProcessInstLogId is null then
      ra('Failure to create or find the instance of the archived process for task');
    end if;

    INSERT INTO WFL_ACTIVITY_INST_LOG(
                WFL_ACTIVITY_INST_LOG_ID,
                WFL_DEADLINES_ID,
                WFL_PROCESS_INST_LOG_ID,
                WFL_PROCESSES_ID,
                WFL_ACTIVITIES_ID,
                C_WFL_ACTIVITY_STATE,
                AIN_DATE_CREATED,
                AIN_DATE_STARTED,
                AIN_DATE_ENDED,
                AIN_DATE_DUE,
                AIN_REMARKS,
                AIN_WORKLIST_DISPLAY,
                AIN_SESSION_STATE,
                AIN_REPLICATION_TIMESTAMP,
                A_DATECRE,
                A_IDCRE,
                AIN_VALIDATION_REQUIRED,
                AIN_VALIDATED_BY,
                AIN_VALIDATION_DATE,
                AIN_GUESTS_AUTHORIZED,
                AIN_EMAILTO_PARTICIPANTS,
                PC_WFL_PARTICIPANTS_ID,
                AIN_OBJECT_START_REQUIRED,
                AIN_OBJECT_START_DATE,
                AIN_OBJECT_STARTED_BY,
                AIN_OWNER_ID,
                WFL_WFL_ACTIVITY_INST_LOG_ID,
                PC_OBJECT_ID,
                AIN_LONG_DESCRIPTION,
                AIN_RECORD_ID,
                AIN_TOPIC,
                C_WFL_tASK_PRIORITY
                )
       SELECT   INIT_ID_SEQ.NEXTVAL,
                AIN.WFL_DEADLINES_ID,
                nProcessInstLogId,
                AIN.WFL_PROCESSES_ID,
                AIN.WFL_ACTIVITIES_ID,
                AIN.C_WFL_ACTIVITY_STATE,
                AIN.AIN_DATE_CREATED,
                AIN.AIN_DATE_STARTED,
                AIN.AIN_DATE_ENDED,
                AIN.AIN_DATE_DUE,
                AIN.AIN_REMARKS,
                AIN.AIN_WORKLIST_DISPLAY,
                AIN.AIN_SESSION_STATE,
                AIN.AIN_REPLICATION_TIMESTAMP,
                sysdate,
                AIN.A_IDCRE,
                AIN.AIN_VALIDATION_REQUIRED,
                AIN.AIN_VALIDATED_BY,
                AIN.AIN_VALIDATION_DATE,
                AIN.AIN_GUESTS_AUTHORIZED,
                AIN.AIN_EMAILTO_PARTICIPANTS,
                AIN.PC_WFL_PARTICIPANTS_ID,
                AIN.AIN_OBJECT_START_REQUIRED,
                AIN.AIN_OBJECT_START_DATE,
                AIN.AIN_OBJECT_STARTED_BY,
                AIN.AIN_OWNER_ID,
                AIN.WFL_WFL_ACTIVITY_INSTANCES_ID,
                AIN.PC_OBJECT_ID,
                AIN.AIN_LONG_DESCRIPTION,
                AIN.AIN_RECORD_ID,
                AIN.AIN_TOPIC,
                AIN.C_WFL_TASK_PRIORITY
          FROM  WFL_ACTIVITY_INSTANCES AIN
          WHERE AIN.WFL_ACTIVITY_INSTANCES_ID = aTaskId;

    for tplTask in crTask(aTaskId) loop
      WFL_TASK_MANAGEMENT.ArchiveTasks (tplTask.WFL_ACTIVITY_INSTANCES_ID);
    end loop;

    DELETE FROM WFL_ACTIVITY_INSTANCES ain where ain.WFL_ACTIVITY_INSTANCES_ID = aTaskId;

  end ArchiveTasks;


  procedure ArchiveTasks
  is
    cursor crTask
    is
      select  ain.WFL_ACTIVITY_INSTANCES_ID
        from  WFL_ACTIVITY_INSTANCES ain, WFL_ACTIVITIES act
        where ain.WFL_ACTIVITIES_ID = act.WFL_ACTIVITIES_ID
          and act.ACT_TASK = 1
          and ain.WFL_WFL_ACTIVITY_INSTANCES_ID is null
          and ain.C_WFL_ACTIVITY_STATE = 'COMPLETED';
    tplTask crTask%rowtype;
    bisFinished number;
  begin
    for tplTask in crTask loop
      WFL_TASK_MANAGEMENT.isTaskSubTreeCompleted(tplTask.WFL_ACTIVITY_INSTANCES_ID, bisFinished);
      if bisFinished = 1 then
        WFL_TASK_MANAGEMENT.ArchiveTasks(tplTask.WFL_ACTIVITY_INSTANCES_ID);
      end if;
    end loop;
  end ArchiveTasks;

  /*************** Récupère la valeur de la fonction  RecodFunction en fonction du record et de l'objet********/
  function getFieldValueFromRecord(
    aRecordFunction     in WFL_ACTIVITIES.ACT_SHOW_RECORD%type
  , aRecordId           in WFL_ACTIVITY_INSTANCES.AIN_RECORD_ID%type
  )
  return varchar
  is
  cResult varchar(4000);
  begin
    cResult := '';
    if (aRecordFunction is not null) then
      execute immediate ' select ' || aRecordFunction || '(' || aRecordId || ' ) from dual ' into cResult ;
    end if;
  return cResult;
  end getFieldValueFromRecord;

  function TestRecord(
   aRecordId           in WFL_ACTIVITY_INSTANCES.AIN_RECORD_ID%type
  )
  return varchar
  is
   cResult  varchar(4000);
  begin
  cResult :='Test';
   return cResult;
  end;

end WFL_TASK_MANAGEMENT;
