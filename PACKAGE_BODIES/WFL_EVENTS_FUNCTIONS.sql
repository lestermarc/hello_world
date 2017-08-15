--------------------------------------------------------
--  DDL for Package Body WFL_EVENTS_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WFL_EVENTS_FUNCTIONS" 
is
  --macros pour e-mails
  gMacroProcName   constant varchar2(14) := '{PROCESS_NAME}';
  gMacroProcStatus constant varchar2(16) := '{PROCESS_STATUS}';
  gMacroProcOwner  constant varchar2(15) := '{PROCESS_OWNER}';
  gMacroActName    constant varchar2(15) := '{ACTIVITY_NAME}';
  gMacroActStatus  constant varchar2(17) := '{ACTIVITY_STATUS}';
  gMacroCurrentElt constant varchar2(17) := '{CURRENT_ELEMENT}';
  gMacroActPerf    constant varchar2(21) := '{ACTIVITY_PERFORMER}';

  /*************** GetMailLaunchFunction *************************************/
  function GetMailLaunchFunction(aMailProperties in WFL_PROCESS_EVENTS.WPV_EVENT_TYPE_PROPERTIES%type)
    return varchar2
  is
    oMailProp xmltype;
    result    varchar2(200);
  begin
    oMailProp  := sys.xmltype.CreateXml(aMailProperties);

    select extractvalue(oMailProp, '/EMAIL_PROPERTIES/@launch_condition')
      into result
      from dual;

    return result;
  exception
    when no_data_found then
      return '';
  end GetMailLaunchFunction;

/*************** GetPlSqlCode **********************************************/
  function GetPlSqlCode(aPlSqlProperties in WFL_PROCESS_EVENTS.WPV_EVENT_TYPE_PROPERTIES%type)
    return varchar2
  is
    oPlSqlProp xmltype;
    result     varchar2(200);
  begin
    oPlSqlProp  := sys.xmltype.CreateXml(aPlSqlProperties);

    select extractvalue(oPlSqlProp, '/PLSQL_PROC_PROPERTIES/PROC_NAME/text()')
      into result
      from dual;
  exception
    when no_data_found then
      return '';
  end GetPlSqlCode;

  /*************** ReplaceMailMacros *****************************************/
  procedure ReplaceMailMacros(
    aMailVar           in out EML_SENDER.TMAIL
  , aProcessInstanceId in     WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  )
  is
    cProcName   WFL_PROCESSES.PRO_NAME%type;
    cProcStatus WFL_PROCESS_INSTANCES.C_WFL_PROCESS_STATE%type;
    cShowProc   WFL_PROCESS_INSTANCES.PRI_SHOW_PROC%type;
    cPriRecId   wfl_process_instances.pri_rec_id%type;
    cRecInfo    varchar2(250);
    cProcOwner  PCS.PC_WFL_PARTICIPANTS.WPA_DESCRIPTION%type;
  begin
    --récupération des éléments pour faire les remplacements des macros
    select pro.PRO_NAME
         , pri.C_WFL_PROCESS_STATE
         , pri.PRI_SHOW_PROC
         , pri.pri_rec_id
         , wpa.WPA_DESCRIPTION
      into cProcName
         , cProcStatus
         , cShowProc
         , cPriRecId
         , cProcOwner
      from WFL_PROCESSES pro
         , WFL_PROCESS_INSTANCES pri
         , PCS.PC_WFL_PARTICIPANTS wpa
     where PRO.WFL_PROCESSES_ID = PRI.WFL_PROCESSES_ID
       and PRI.WFL_PROCESS_INSTANCES_ID = aProcessInstanceId
       and wpa.PC_WFL_PARTICIPANTS_ID = pri.PC_WFL_PARTICIPANTS_ID;

    --remplacement des macros dans le sujet
    aMailVar.mSubject    := replace(aMailVar.mSubject, gMacroProcName, cProcName);
    aMailVar.mSubject    := replace(aMailVar.mSubject, gMacroProcStatus, cProcStatus);

    if cShowProc is not null then
      begin

        execute immediate 'select ' || cShowProc || '(:aId)  from dual'
                     into cRecInfo
                    using cPriRecId;

      exception
        when others then
          cRecInfo  := '';
      end;

    end if;

    aMailVar.mSubject    := replace(aMailVar.mSubject, gMacroCurrentElt, cRecInfo);
    aMailVar.mSubject    := replace(aMailVar.mSubject, gMacroProcOwner, cProcOwner);

    --remplacement des macros dans le body (HTML et plain)
    aMailVar.mBodyHTML   := replace(aMailVar.mBodyHTML, gMacroProcName, cProcName);
    aMailVar.mBodyHTML   := replace(aMailVar.mBodyHTML, gMacroProcStatus, cProcStatus);
    aMailVar.mBodyHTML   := replace(aMailVar.mBodyHTML, gMacroCurrentElt, cRecInfo);
    aMailVar.mBodyHTML   := replace(aMailVar.mBodyHTML, gMacroProcOwner, cProcOwner);
    aMailVar.mBodyPlain  := replace(aMailVar.mBodyPlain, gMacroProcName, cProcName);
    aMailVar.mBodyPlain  := replace(aMailVar.mBodyPlain, gMacroProcStatus, cProcStatus);
    aMailVar.mBodyPlain  := replace(aMailVar.mBodyPlain, gMacroCurrentElt, cRecInfo);
    aMailVar.mBodyPlain  := replace(aMailVar.mBodyPlain, gMacroProcOwner, cProcOwner);
  end ReplaceMailMacros;

  procedure ReplaceMailMacros(
    aMailVar            in out EML_SENDER.TMAIL
  , aActivityInstanceId in     WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  )
  is
    cActivityName   WFL_ACTIVITIES.ACT_NAME%type;
    cActivityStatus WFL_ACTIVITY_INSTANCES.C_WFL_ACTIVITY_STATE%type;
    cCurElement     WFL_PROCESS_INSTANCES.PRI_SHOW_PROC%type;
    cActPerfName    PCS.PC_WFL_PARTICIPANTS.WPA_DESCRIPTION%type;
  begin
    --récupération des éléments pour faire les remplacements des macros
    select ACT.ACT_NAME
         , AIN.C_WFL_ACTIVITY_STATE
         , PRI.PRI_SHOW_PROC
         , wpa.WPA_DESCRIPTION
      into cActivityName
         , cActivityStatus
         , cCurElement
         , cActPerfName
      from WFL_ACTIVITIES ACT
         , WFL_ACTIVITY_INSTANCES AIN
         , WFL_PROCESS_INSTANCES PRI
         , WFL_PERFORMERS wpe
         , PCS.PC_WFL_PARTICIPANTS wpa
     where AIN.WFL_PROCESS_INSTANCES_ID = PRI.WFL_PROCESS_INSTANCES_ID
       and AIN.WFL_ACTIVITIES_ID = ACT.WFL_ACTIVITIES_ID
       and AIN.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
       and wpa.PC_WFL_PARTICIPANTS_ID (+)= wpe.PC_WFL_PARTICIPANTS_ID
       and wpe.WFL_ACTIVITY_INSTANCES_ID (+)= ain.WFL_ACTIVITY_INSTANCES_ID;

    --remplacement des macros dans le sujet
    aMailVar.mSubject    := replace(aMailVar.mSubject, gMacroActName, cActivityName);
    aMailVar.mSubject    := replace(aMailVar.mSubject, gMacroActStatus, cActivityStatus);
    aMailVar.mSubject    := replace(aMailVar.mSubject, gMacroCurrentElt, cCurElement);
    aMailVar.mSubject    := replace(aMailVar.mSubject, gMacroActPerf, cCurElement);
    --remplacement des macros dans le body (HTML et plain)
    aMailVar.mBodyHTML   := replace(aMailVar.mBodyHTML, gMacroActName, cActivityName);
    aMailVar.mBodyHTML   := replace(aMailVar.mBodyHTML, gMacroActStatus, cActivityStatus);
    aMailVar.mBodyHTML   := replace(aMailVar.mBodyHTML, gMacroCurrentElt, cCurElement);
    aMailVar.mBodyHTML   := replace(aMailVar.mBodyHTML, gMacroActPerf, cCurElement);
    aMailVar.mBodyPlain  := replace(aMailVar.mBodyPlain, gMacroActName, cActivityName);
    aMailVar.mBodyPlain  := replace(aMailVar.mBodyPlain, gMacroActStatus, cActivityStatus);
    aMailVar.mBodyPlain  := replace(aMailVar.mBodyPlain, gMacroCurrentElt, cCurElement);
    aMailVar.mBodyPlain  := replace(aMailVar.mBodyPlain, gMacroActPerf, cCurElement);
  end ReplaceMailMacros;

/*************** GetMailInfos **********************************************/
  procedure GetMailInfosProc(
    aProcessInstanceId  in     WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  , aActivityInstanceId in     WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type default null
  , aMailProperties     in     xmltype
  , aMailVar            out    EML_SENDER.TMAIL
  , aLaunchFunction     out    varchar2
  )
  is
    nCnt          integer;
    cXPath        varchar2(1000);
    cAddrType     varchar2(100);
    cRecipType    varchar2(100);
    cAddrInfo     varchar2(200);
    cAddress      varchar2(200);
    cBodyType     varchar2(10);
  begin

    select wpa.wpa_email
      into aMailVar.mSender
      from pcs.pc_wfl_participants wpa
     where wpa.pc_wfl_participants_id = 1;

    --parcours et récupération des informations de mail
    select extractvalue(aMailProperties, '/EMAIL_PROPERTIES/@subject')
         , to_number(extractvalue(aMailProperties, '/EMAIL_PROPERTIES/@priority') )
         , to_number(extractvalue(aMailProperties, '/EMAIL_PROPERTIES/@notification') )
         , extractvalue(aMailProperties, '/EMAIL_PROPERTIES/@send_mode')
         , extractvalue(aMailProperties, '/EMAIL_PROPERTIES/@custom_headers')
         , extractvalue(aMailProperties, '/EMAIL_PROPERTIES/@backup_mode')
         , extractvalue(aMailProperties, '/EMAIL_PROPERTIES/@launch_condition')
      into aMailVar.mSubject
         , aMailVar.mPriority
         , aMailVar.mNotification
         , aMailVar.mSendMode
         , aMailVar.mCustomHeaders
         , aMailVar.mBackupMode
         , aLaunchFunction
      from dual;

    --récupération des destinataires (To -> recipients, Cc -> Ccrecipitents) séparés par des virgules
    nCnt := 1;

    while(nCnt > 0) loop
      --récupération des éléments dans des variables temporaires
      cXPath  := replace('/EMAIL_PROPERTIES/RECIPIENTS_LIST/RECIPIENT[###]', '###', to_char(nCnt, 'FM999') );

      select upper(extractvalue(aMailProperties, cXPath || '/@address_type') )
           , upper(extractvalue(aMailProperties, cXPath || '/@recipient_type') )
           , extractvalue(aMailProperties, cXPath || '/text()')
        into cAddrType
           , cRecipType
           , cAddrInfo
        from dual;

      --si le type d'addresse ou le type de destinataire est null, alors il faut sortir de la boucle
      if    (cAddrType is null)
         or (length(cAddrType) = 0)
         or (cRecipType is null)
         or (length(cRecipType) = 0) then
        exit;
      else
        --on récupère l'addresse e-mail en fonction du type d'addresse (uniquement pour e-mails calculés)
        if cAddrType = 'INST_PROC_OWNER' then
          --récupérer l'instantiateur du process
          select (select WPA.WPA_EMAIL
                    from PCS.PC_WFL_PARTICIPANTS WPA
                       , WFL_PROCESS_INSTANCES PROC_INST
                   where PROC_INST.WFL_PROCESS_INSTANCES_ID = aProcessInstanceId
                     and PROC_INST.PC_WFL_PARTICIPANTS_ID = WPA.PC_WFL_PARTICIPANTS_ID)
            into cAddress
            from dual;
        elsif cAddrType = 'ACT_PERFORMER' then
          --récupérer la personne ayant pris en charge l'activité (aAddrInfo contient nom activité)
          select (select WPA.WPA_EMAIL
                    from PCS.PC_WFL_PARTICIPANTS WPA
                       , WFL_ACTIVITY_INSTANCES ACI
                       , WFL_ACTIVITIES ACT
                       , WFL_PERFORMERS PFM
                   where PFM.WFL_ACTIVITY_INSTANCES_ID = ACI.WFL_ACTIVITY_INSTANCES_ID
                     and ACI.WFL_ACTIVITIES_ID = ACT.WFL_ACTIVITIES_ID
                     and PFM.PC_WFL_PARTICIPANTS_ID = WPA.PC_WFL_PARTICIPANTS_ID
                     and PFM.PFM_ACCEPTED = 'Y'
                     and ACT.ACT_NAME = cAddrInfo
                     and ACI.WFL_PROCESS_INSTANCES_ID = aProcessInstanceId)
            into cAddress
            from dual;
        elsif cAddrType = 'PROC_PARTICIPANT' then
          --récupérer l'e-mail du participant (nom dans aAddrInfo)
          select (select WPA.WPA_EMAIL
                    from PCS.PC_WFL_PARTICIPANTS WPA
                   where WPA.WPA_NAME = cAddrInfo)
            into cAddress
            from dual;
        else
          cAddress  := cAddrInfo;
        end if;

        if aActivityInstanceId is not null then
          if cAddrType = 'INST_TASK_OWNER' then
            select (select WPA.WPA_EMAIL
                      from PCS.PC_WFL_PARTICIPANTS WPA
                         , WFL_ACTIVITY_INSTANCES ain
                     where WPA.PC_USER_ID = ain.AIN_OWNER_ID
                       and ain.WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId)
              into cAddress
              from dual;
           elsif cAddrType = 'TASK_PARTICIPANT' then
             cAddress  := cAddrInfo;
           end if;
        end if;



        --on teste le destinataire pour ajouter l'adresse au bon endroit
        if cRecipType = 'BCC' then
          --BlindCarbonCopy
          if length(aMailVar.mBccRecipients) > 0 then
            aMailVar.mBccRecipients  := aMailVar.mBccRecipients || ',' || cAddress;
          else
            aMailVar.mBccRecipients  := cAddress;
          end if;
        elsif cRecipType = 'CC' then
          --CarbonCopy
          if length(aMailVar.mCcRecipients) > 0 then
            aMailVar.mCcRecipients  := aMailVar.mCcRecipients || ',' || cAddress;
          else
            aMailVar.mCcRecipients  := cAddress;
          end if;
        else
          --ToRecipient
          if length(aMailVar.mRecipients) > 0 then
            aMailVar.mRecipients  := aMailVar.mRecipients || ',' || cAddress;
          else
            aMailVar.mRecipients  := cAddress;
          end if;
        end if;
      end if;

      nCnt    := nCnt + 1;
    end loop;

    --ajout du corps du message
    select upper(extractvalue(aMailProperties, '/EMAIL_PROPERTIES/BODY/@body_type') )
      into cBodyType
      from dual;

    if cBodyType = 'HTML' then
      select extractvalue(aMailProperties, '/EMAIL_PROPERTIES/BODY/text()')
        into aMailVar.mBodyHTML
        from dual;
    else
      select extractvalue(aMailProperties, '/EMAIL_PROPERTIES/BODY/text()')
        into aMailVar.mBodyPlain
        from dual;
    end if;

    --remplacement des macros
    ReplaceMailMacros(aMailVar => aMailVar, aProcessInstanceId => aProcessInstanceId);
  end GetMailInfosProc;

  --overload pour activités
  procedure GetMailInfosAct(
    aActivityInstanceId in     WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aMailProperties     in     xmltype
  , aMailVar            out    EML_SENDER.TMAIL
  , aLaunchFunction     out    varchar2
  )
  is
    nProcInstId WFL_ACTIVITY_INSTANCES.WFL_PROCESS_INSTANCES_ID%type;
  begin
    select WFL_PROCESS_INSTANCES_ID
      into nProcInstId
      from WFL_ACTIVITY_INSTANCES
     where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId;

    WFL_EVENTS_FUNCTIONS.GetMailInfosProc(aProcessInstanceId   => nProcInstId
                                        , aActivityInstanceId  => aActivityInstanceId
                                        , aMailProperties      => aMailProperties
                                        , aMailVar             => aMailVar
                                        , aLaunchFunction      => aLaunchFunction
                                         );
    --remplacement des macros
    ReplaceMailMacros(aMailVar => aMailVar, aActivityInstanceId => aActivityInstanceId);
  exception
    when no_data_found then
      aMailVar  := null;
  end GetMailInfosAct;

/*************** GetPlSqlInfos *********************************************/
  procedure GetPlSqlInfos(aPlSqlProperties in xmltype, aPlSqlVar out WFL_WORKFLOW_TYPES.TWFLPLSQLEVENT)
  is
    nCnt        integer;
    cXPath      varchar2(1000);
    cLanid      varchar2(3);
    cMessage    varchar2(4000);
    oTmpMessage WFL_WORKFLOW_TYPES.TWFLMESSAGE;
  begin
    --parcours et récupération des informations de mail
    select extractvalue(aPlSqlProperties, '/PLSQL_PROC_PROPERTIES/PROC_NAME/text()')
      into aPlSqlVar.pProcName
      from dual;

    --le code d'erreur est à 0 initialement, mis à jour par exécution
    aPlSqlVar.pErrorCode  := 0;
    --récupération des messages de retour
    nCnt                  := 1;

    while(nCnt > 0) loop
      --récupération erreur et message
      cXPath  := replace('/PLSQL_PROC_PROPERTIES/RETURNED_MESSAGE[###]', '###', to_char(nCnt, 'FM999') );

      select upper(extractvalue(aPlSqlProperties, cXPath || '/@language') )
           , extractvalue(aPlSqlProperties, cXPath || '/text()')
        into oTmpMessage.pLanid
           , oTmpMessage.pText
        from dual;

      --si la langue est nulle alors il faut sortir de la boucle
      if oTmpMessage.pLanid is null then
        exit;
      else
        --ajout du message à la collection ds propriétés plsql
        aPlSqlVar.pOutMessages.extend;
        aPlSqlVar.pOutMessages(aPlSqlVar.pOutMessages.count)  := oTmpMessage;
      end if;

      nCnt    := nCnt + 1;
    end loop;
  end GetPlSqlInfos;

/*************** EventSendMail *********************************************/
  function EventSendMailProc(
    aProcessEventId    in WFL_PROCESS_EVENTS.WFL_PROCESS_EVENTS_ID%type
  , aProcessInstanceId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  , aMailProperties    in WFL_PROCESS_EVENTS.WPV_EVENT_TYPE_PROPERTIES%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    result          WFL_WORKFLOW_TYPES.WFL_BOOLEAN default 0;
    oMailProp       xmltype;
    oMail           EML_SENDER.TMAIL;
    cErrorCodes     varchar2(4000);
    cErrorMessages  varchar2(4000);
    cLaunchFunction varchar2(200);
    nMailId         number;
    bSendMail       pls_integer                    default 0;
  begin

    wfl_workflow_management.initlogcontext (aSection    => 'WFL_EVENTS_FUNCTIONS');

    --récupération des propriétés dans une variable XmlType
    oMailProp  := sys.xmltype.CreateXml(aMailProperties);
    GetMailInfosProc(aProcessInstanceId   => aProcessInstanceId
                   , aMailProperties      => oMailProp
                   , aMailVar             => oMail
                   , aLaunchFunction      => cLaunchFunction
                    );

    if length(trim(cLaunchFunction) ) > 0 then
      begin
        --Lancement de la fonction de test pour le mail (doit recevoir l'instance de process en paramètre)
        execute immediate 'select ' || cLaunchFunction || '(:ProcInstId)
           from dual'
                     into bSendMail
                    using aProcessInstanceId;
      exception
        when others then
          bSendMail  := 0;
      end;
    else
      bSendMail  := 1;
    end if;

    if bSendMail = 1 then
      --envoie du mail et récupération codes d'erreur
      cErrorCodes := EML_SENDER.Send(aErrorMessages => cErrorMessages, aMailID => nMailId, aMail => oMail);

      wfl_workflow_management.debuglog (aLogText =>'mSender = ' || oMail.mSender);
      wfl_workflow_management.debuglog (aLogText =>'mReplyTo = ' || oMail.mReplyTo);
      wfl_workflow_management.debuglog (aLogText =>'mRecipients = ' || omail.mRecipients);
      wfl_workflow_management.debuglog (aLogText =>'mCcRecipients = ' || omail.mCcRecipients);
      wfl_workflow_management.debuglog (aLogText =>'mNotification = '|| omail.mNotification);
      wfl_workflow_management.debuglog (aLogText =>'mSubject = ' || omail.mSubject);
      wfl_workflow_management.debuglog (aLogText => 'ErrorCodes = ' || cErrorCodes || 'ErrorMessages = ' || cErrorMessages);

      if    (cErrorCodes is null)
         or not(length(cErrorCodes) > 0) then
        result  := 1;
      end if;
    end if;

    --**à voir si l'insertion dans la table d'instances d'events est nécessaire pour les mails
    return result;
  end EventSendMailProc;

  --fonction pour activités
  function EventSendMailAct(
    aActivityEventId    in WFL_ACTIVITY_EVENTS.WFL_ACTIVITY_EVENTS_ID%type
  , aActivityInstanceId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aMailProperties     in WFL_ACTIVITY_EVENTS.WAV_EVENT_TYPE_PROPERTIES%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    result          WFL_WORKFLOW_TYPES.WFL_BOOLEAN default 0;
    oMailProp       xmltype;
    oMail           EML_SENDER.TMAIL;
    cErrorCodes     varchar2(4000);
    cErrorMessages  varchar2(4000);
    cLaunchFunction varchar2(200);
    nMailId         number;
    bSendMail       pls_integer                    default 0;
  begin
    --récupération des propriétés dans une variable XmlType
    oMailProp  := sys.xmltype.CreateXml(aMailProperties);
    GetMailInfosAct(aActivityInstanceId   => aActivityInstanceId
                  , aMailProperties       => oMailProp
                  , aMailVar              => oMail
                  , aLaunchFunction       => cLaunchFunction
                   );

    if length(trim(cLaunchFunction) ) > 0 then
      begin
        --Lancement de la fonction de test pour le mail (doit recevoir l'instance de process en paramètre)
        execute immediate 'select ' || cLaunchFunction || '(:ActInstanceId)
           from dual'
                     into bSendMail
                    using aActivityInstanceId;
      exception
        when others then
          bSendMail  := 0;
      end;
    else
      bSendMail  := 1;
    end if;

    if bSendMail = 1 then
      --envoie du mail et récupération codes d'erreur
      cErrorCodes := EML_SENDER.Send(aErrorMessages => cErrorMessages, aMailID => nMailId, aMail => oMail);

      if    (cErrorCodes is null)
         or not(length(cErrorCodes) > 0) then
        result  := 1;
      end if;
    end if;

    --**à voir si l'insertion dans la table d'instances d'events est nécessaire pour les mails
    return result;
  end EventSendMailAct;

/*************** EventPlSql ************************************************/
  function EventPlSqlProc(
    aProcessEventId    in WFL_PROCESS_EVENTS.WFL_PROCESS_EVENTS_ID%type
  , aProcessInstanceId in WFL_PROCESS_INSTANCES.WFL_PROCESS_INSTANCES_ID%type
  , aPlSqlProperties   in WFL_PROCESS_EVENTS.WPV_EVENT_TYPE_PROPERTIES%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    result      WFL_WORKFLOW_TYPES.WFL_BOOLEAN      default 0;
    nCnt        number;
    oPlSqlProp  xmltype;
    oPlSqlEvt   WFL_WORKFLOW_TYPES.TWFLPLSQLEVENT;
    nOutCode    number;
    cOutMessage varchar2(4000);
    cUserLanid  PCS.PC_LANG.LANID%type;
  begin
    --récupération des propriétés dans une variable XmlType
    oPlSqlProp   := sys.xmltype.CreateXml(aPlSqlProperties);
    GetPlSqlInfos(aPlSqlProperties => oPlSqlProp, aPlSqlVar => oPlSqlEvt);

    --récupération code langue active
    select nvl(max(upper(LAN.LANID) ), '@@')
      into cUserLanid
      from PCS.PC_LANG LAN
     where LAN.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId;

    if cUserLanid = '@@' then
      cUserLanid  := 'EN';   --par défaut anglais
    end if;

    --récupération du message dans la langue de l'utilisateur
    cOutMessage  := '';

    for nCnt in 1 .. oPlSqlEvt.pOutMessages.count loop
      if oPlSqlEvt.pOutMessages(nCnt).pLanId = cUserLanId then
        cOutMessage  := oPlSqlEvt.pOutMessages(nCnt).pText;
      end if;
    end loop;

    --exécution de la procédure stockée et récupération codes d'erreurs et messages
    begin

      execute immediate 'begin ' ||
                        oPlSqlEvt.pProcName ||
                        '(:ProcInstId, :ErrorCode, :ReturnedMessage); end;'
                  using in aProcessInstanceId, out nOutCode, in out cOutMessage;

      oPlSqlEvt.pErrorCode  := nOutCode;

      if oPlSqlEvt.pErrorCode = 0 then
        result  := 1;
      end if;
    exception
      when others then
        oPlSqlEvt.pErrorCode  := 1;
        cOutMessage           := sqlerrm;   --si erreur oracle alors on stocke en lieu et place du message
    end;

    --mise à jour de l'instance avec le message d'erreur et code d'erreur
    update WFL_PROCESS_INSTANCE_EVTS
       set WPI_ERROR_CODE = oPlSqlEvt.pErrorCode
         , WPI_RETURNED_MESSAGE = cOutMessage
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_PUBLIC.GetUserIni
     where WFL_PROCESS_INSTANCES_ID = aProcessInstanceId
       and WFL_PROCESS_EVENTS_ID = aProcessEventId;

    return result;
  end EventPlSqlProc;

  --fonction pour activités
  function EventPlSqlAct(
    aActivityEventId    in WFL_ACTIVITY_EVENTS.WFL_ACTIVITY_EVENTS_ID%type
  , aActivityInstanceId in WFL_ACTIVITY_INSTANCES.WFL_ACTIVITY_INSTANCES_ID%type
  , aPlSqlProperties    in WFL_ACTIVITY_EVENTS.WAV_EVENT_TYPE_PROPERTIES%type
  )
    return WFL_WORKFLOW_TYPES.WFL_BOOLEAN
  is
    result      WFL_WORKFLOW_TYPES.WFL_BOOLEAN      default 0;
    nCnt        number;
    oPlSqlProp  xmltype;
    oPlSqlEvt   WFL_WORKFLOW_TYPES.TWFLPLSQLEVENT;
    nOutCode    number;
    cOutMessage varchar2(4000);
    cUserLanid  PCS.PC_LANG.LANID%type;
  begin
    --récupération des propriétés dans une variable XmlType
    oPlSqlProp   := sys.xmltype.CreateXml(aPlSqlProperties);
    GetPlSqlInfos(aPlSqlProperties => oPlSqlProp, aPlSqlVar => oPlSqlEvt);

    --récupération code langue active
    select nvl(max(upper(LAN.LANID) ), '@@')
      into cUserLanid
      from PCS.PC_LANG LAN
     where LAN.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId;

    if cUserLanid = '@@' then
      cUserLanid  := 'EN';   --par défaut anglais
    end if;

    --récupération du message dans la langue de l'utilisateur
    cOutMessage  := '';

    for nCnt in 1 .. oPlSqlEvt.pOutMessages.count loop
      if oPlSqlEvt.pOutMessages(nCnt).pLanId = cUserLanId then
        cOutMessage  := oPlSqlEvt.pOutMessages(nCnt).pText;
      end if;
    end loop;

    --exécution de la procédure stockée et récupération codes d'erreurs et messages
    begin
      execute immediate 'begin
          ' ||
                        oPlSqlEvt.pProcName ||
                        '(:ActivitiesId, :ErrorCode, :ReturnedMessage);
         end;'
                  using in aActivityInstanceId, out nOutCode, in out cOutMessage;

      oPlSqlEvt.pErrorCode  := nOutCode;

      if oPlSqlEvt.pErrorCode = 0 then
        result  := 1;
      --**voir avec PYV si dans le cas d'une exécution correcte
      --si est nécessaire d'ajouter le message à afficher dans la table (update ci-dessous)
      end if;
    exception
      when others then
        oPlSqlEvt.pErrorCode  := 1;
        cOutMessage           := sqlerrm;   --si erreur oracle alors on stocke en lieu et place du message
    end;

    --mise à jour de l'instance avec le message d'erreur et code d'erreur
    update WFL_ACTIVITY_INSTANCE_EVTS
       set WAI_ERROR_CODE = oPlSqlEvt.pErrorCode
         , WAI_RETURNED_MESSAGE = cOutMessage
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_PUBLIC.GetUserIni
     where WFL_ACTIVITY_INSTANCES_ID = aActivityInstanceId
       and WFL_ACTIVITY_EVENTS_ID = aActivityEventId;

    return result;
  end EventPlSqlAct;
end WFL_EVENTS_FUNCTIONS;
