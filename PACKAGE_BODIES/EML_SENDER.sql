--------------------------------------------------------
--  DDL for Package Body EML_SENDER
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "EML_SENDER" 
/**
 * Description
 *    Package allowing to send multipart e-mails with attachements by SMTP
 *    using stored Java classes.
 * @author JCH
 * @created 18.06.2005
 * @version 2003
 * @lastUpdate
 */
is
/*-**************************************************************************-*/
/*                                                                            */
/*    Package allowing to Send multipart e-mails with attachements by SMTP    */
/*                         using stored Java classes.                         */
/*                                                                            */
/*                Copyright (c) 2005 ProConcept International                 */
/*                                                                            */
/*                 Author PCS - JCH    Created : 18.06.2005                   */
/*                                                                            */
/*-**************************************************************************-*/

  /**
   * Procedure SetDebug
   * Description
   *    Sets debugging flag.
   * @author JCH
   * @created 15.12.2005
   * @version 2003
   * @lastUpdate
   * @public
   * @param aValue true for debugging, false for not
  */
  procedure SetDebug(aValue in boolean)
  is
  begin
    gDebug  := aValue;
  end SetDebug;

  /**
   * Function CreateMail
   * Description
   *    Creates a new TMAIL instance and stores it in default e-mail object.
   *    Addresses in address groups are coma-separated.
   * @param aErrorMessages  a string were to return error messages
   * @param aSender         sender's e-mail address
   * @param aReplyTo        e-mail address for replies
   * @param aRecipients     recipients' e-mail adresses
   * @param aCcRecipients   recipients' e-mail adresses, in carbon copy mode
   * @param aBccRecipients  recipients' e-mail adresses, in blind carbon copy
   *   mode
   * @param aNotification   flag for notification request on reception of this
   *   e-mail
   * @param aPriority       priority value of this e-mail, from 1 (Higher) to 5
   *   (Lower). Please use PriorityLevels constants.
   * @param aCustomHeaders  custom headers of this e-mail, must be CRLF
        separated
   * @param aSubject        subject of this e-mail
   * @param aBodyPlain      body of this e-mail in text/plain format
   * @param aBodyHtml       body of this e-mail in text/html format
   * @param aSendMode       sending mode, IMMEDIATE, IMMEDIATE_FORCED,
   *   DELAYED_REAL_DATE or DELAYED_FIXED_DATE
   * @param aDateToSend     date when to send the e-mail if in delayed mode
   * @param aTimeZoneOffset offset to apply to aDate ToSend. UTC (GMT, '00:00')
       is used if null. An accepted format is '+/-HH:MI', others are all those
       accepted by Oracle function from_tz.
   * @param aBackupMode     backup mode for sent items
   * @param aBackupOptions  backup options for future use
   * @return a list of error codes. Detailed error messages are returned in
   *   aErrorMessages.
   */
  function CreateMail(
    aErrorMessages  out nocopy    varchar2
  , aSender         in            varchar2 default ''
  , aReplyTo        in            varchar2 default ''
  , aRecipients     in            varchar2 default ''
  , aCcRecipients   in            varchar2 default ''
  , aBccRecipients  in            varchar2 default ''
  , aNotification   in            integer default 0
  , aPriority       in            integer default 3
  , aCustomHeaders  in            varchar2 default ''
  , aSubject        in            varchar2 default ''
  , aBodyPlain      in            clob default null
  , aBodyHTML       in            clob default null
  , aSendMode       in            EML_TO_SEND_EMAILS_QUEUE.C_EMAIL_SEND_MODE%type default cSENDMODE_IMMEDIATE
  , aDateToSend     in            EML_TO_SEND_EMAILS_QUEUE.SDQ_DATE_TO_SEND%type default sysdate
  , aTimeZoneOffset in            varchar2 default sessiontimezone
  , aBackupMode     in            EML_TO_SEND_EMAILS_QUEUE.C_EMAIL_BACKUP_MODE%type default cBACKUP_NONE
  , aBackupOptions  in            EML_TO_SEND_EMAILS_QUEUE.SDQ_BACKUP_OPTIONS%type default ''
  )
    return varchar2
  is
    vTempMail        TMAIL;
    vLocalDateToSend timestamp with time zone;
  begin
    vTempMail.mSender         := aSender;
    vTempMail.mReplyTo        := aReplyTo;
    vTempMail.mRecipients     := aRecipients;
    vTempMail.mCcRecipients   := aCcRecipients;
    vTempMail.mBccRecipients  := aBccRecipients;
    vTempMail.mNotification   := aNotification;
    vTempMail.mPriority       := aPriority;
    vTempMail.mCustomHeaders  := aCustomHeaders;
    vTempMail.mSubject        := aSubject;
    vTempMail.mBodyPlain      := aBodyPlain;
    vTempMail.mBodyHtml       := aBodyHtml;
    vTempMail.mAttachments    := TATTACHMENTS_LIST();
    vTempMail.mSendMode       := aSendMode;

    if aDateToSend is not null then
      if aTimeZoneOffset is not null then
        vLocalDateToSend  := from_tz(cast(aDateToSend as timestamp), aTimeZoneOffset) at time zone dbtimezone;
      else
        vLocalDateToSend  := from_tz(cast(aDateToSend as timestamp), '00:00') at time zone dbtimezone;
      end if;
    else
      vLocalDateToSend  := from_tz(cast(sysdate as timestamp), sessiontimezone) at time zone dbtimezone;
    end if;

    vTempMail.mDateToSend     := vLocalDateToSend;
    vTempMail.mBackupMode     := aBackupMode;
    vTempMail.mBackupOptions  := aBackupOptions;
    gTempMail                 := vTempMail;
    aErrorMessages            := '';
    return '';
  exception
    when others then
      aErrorMessages  := cDEFAULT_CODE || 'Error initializing e-mail record: ' || sqlerrm;
      return cDEFAULT_CODE;
  end CreateMail;

  /**
   * Function AddBody
   * Description
   *    Adds a body to default e-mail object.
   * @param aErrorMessages  a string were to return error messages
   * @param aContent        the body content
   * @param aContentType    the body content type (constant for text/plain, text/html or text/calendar)
   * @param aVCalMethod     (optional) vcalendar method for text/calendar body
   * @return a list of error codes. Detailed error messages are returned in
   *   aErrorMessages.
   */
  function AddBody(
    aErrorMessages out nocopy    varchar2
  , aContent       in            clob
  , aContentType   in            integer
  , aVCalMethod    in            varchar2 default null
  )
    return varchar2
  is
  begin
    return AddBody(aErrorMessages, aContent, aContentType, gTempMail, aVCalMethod);
  end AddBody;

  /**
   * Function AddBody
   * Description
   *    Adds a body to e-mail passed in parameter.
   * @author JCH
   * @created 18.06.2005
   * @version 2003
   * @lastUpdate
   * @public
   * @param aErrorMessages  a string were to return error messages
   * @param aContent        the body content
   * @param aContentType    the body content type (constant for text/plain, text/html or text/calendar)
   * @param aMail           mail object to use
   * @param aVCalMethod     (optional) vcalendar method for text/calendar body
   * @return a list of error codes. Detailed error messages are returned in
   *   aErrorMessages.
   */
  function AddBody(
    aErrorMessages out nocopy    varchar2
  , aContent       in            clob
  , aContentType   in            integer
  , aMail          in out nocopy TMAIL
  , aVCalMethod    in            varchar2 default null
  )
    return varchar2
  is
    vErrorCodes varchar2(4000) := '';
  begin
    case aContentType
      when cTEXT_PLAIN then
        aMail.mBodyPlain  := aContent;
      when cTEXT_HTML then
        aMail.mBodyHtml  := aContent;
      when cTEXT_VCAL then
        aMail.mBodyVCal        := aContent;
        aMail.mBodyVCalMethod  := aVCalMethod;
      else
        aErrorMessages  := aErrorMessages || cBAD_ATTACHMENT_TYPE || 'Bad body content type';
        vErrorCodes     := vErrorCodes || cBAD_ATTACHMENT_TYPE;
    end case;

    return vErrorCodes;
  end AddBody;

  /**
   * Function AddBlobAttachment
   * Description
   *    Adds an attachment to default e-mail object.
   * @param aErrorMessages a string were to return error messages.
   * @param aFileName      attachment filename
   * @param aContent       attachment content
   * @param aContentType   attachment content-type
   * @return a list of error codes. Detailed error messages are returned in
   *   aErrorMessages.
   */
  function AddBlobAttachment(
    aErrorMessages out nocopy    varchar2
  , aFileName      in            varchar2
  , aContent       in            blob
  , aContentType   in            varchar2 default ''
  )
    return varchar2
  is
  begin
    return AddBlobAttachment(aErrorMessages, aFileName, aContent, aContentType, gTempMail);
  end AddBlobAttachment;

  /**
   * Function AddBlobAttachment
   * Description
   *    Adds an attachment to e-mail passed in parameter.
   * @param aErrorMessages a string were to return error messages.
   * @param aFileName      attachment filename
   * @param aContent       attachment content
   * @param aContentType   attachment content-type
   * @param aMail          mail object to use
   * @return a list of error codes. Detailed error messages are returned in
   *   aErrorMessages.
   */
  function AddBlobAttachment(
    aErrorMessages out nocopy    varchar2
  , aFileName      in            varchar2
  , aContent       in            blob
  , aContentType   in            varchar2 default ''
  , aMail          in out nocopy TMAIL
  )
    return varchar2
  is
    vTempAttachment TATTACHMENT;
    vBlob           blob;
    vContentID      number;
  begin
    if aMail.mAttachments is null then
      aMail.mAttachments  := TATTACHMENTS_LIST();
    end if;

    insert into EML_ATTACHMENT_DATA_TEMP
                (EML_ATTACHMENT_DATA_TEMP_ID
               , ATD_FILENAME
                )
         values (init_id_seq.nextval
               , aFileName
                )
      returning EML_ATTACHMENT_DATA_TEMP_ID
           into vContentID;

    select ATD_BINARY_ATTACHMENT_DATA
      into vBlob
      from EML_ATTACHMENT_DATA_TEMP
     where EML_ATTACHMENT_DATA_TEMP_ID = vContentID;

    DBMS_LOB.open(vBlob, DBMS_LOB.lob_readwrite);
    DBMS_LOB.copy(vBlob, aContent, DBMS_LOB.getlength(aContent) );
    DBMS_LOB.close(vBlob);
    vTempAttachment.mFileName                     := aFileName;
    vTempAttachment.mAttachmentType               := cBLOB_TYPE;
    vTempAttachment.mContentType                  := aContentType;
    vTempAttachment.mContentID                    := vContentID;
    aMail.mAttachments.extend;
    aMail.mAttachments(aMail.mAttachments.count)  := vTempAttachment;
    return '';
  exception
    when others then
      aErrorMessages  := cATTACHMENT_ERROR || 'Error adding attachment ' || aFileName || ': ' || sqlerrm;
      return cATTACHMENT_ERROR;
  end AddBlobAttachment;

  /**
   * Function AddClobAttachment
   * Description
   *    Adds an attachment to default e-mail object.
   * @param aErrorMessages a string were to return error messages.
   * @param aFileName      attachment filename
   * @param aContent       attachment content
   * @param aContentType   attachment content-type
   * @return a list of error codes. Detailed error messages are returned in
   *   aErrorMessages.
   */
  function AddClobAttachment(
    aErrorMessages out nocopy    varchar2
  , aFileName      in            varchar2
  , aContent       in            clob
  , aContentType   in            varchar2 default ''
  )
    return varchar2
  is
  begin
    return AddClobAttachment(aErrorMessages, aFileName, aContent, aContentType, gTempMail);
  end AddClobAttachment;

  /**
   * Function AddClobAttachment
   * Description
   *    Adds an attachment to e-mail passed in parameter.
   * @param aErrorMessages a string were to return error messages.
   * @param aFileName      attachment filename
   * @param aContent       attachment content
   * @param aContentType   attachment content-type
   * @param aMail          mail object to use
   * @return a list of error codes. Detailed error messages are returned in
   *   aErrorMessages.
   */
  function AddClobAttachment(
    aErrorMessages out nocopy    varchar2
  , aFileName      in            varchar2
  , aContent       in            clob
  , aContentType   in            varchar2 default ''
  , aMail          in out nocopy TMAIL
  )
    return varchar2
  is
  begin
    return AddAttachment(aErrorMessages    => aErrorMessages
                       , aFileName         => aFileName
                       , aContent          => aContent
                       , aAttachmentType   => cCLOB_TYPE
                       , aContentType      => aContentType
                       , aMail             => aMail
                        );
  end AddClobAttachment;

  /**
   * Function AddCalendarEvent
   * Description
   *    Adds an attachment to default e-mail object.
   * @param aErrorMessages a string were to return error messages.
   * @param aContent        event content (used for body and attachment)
   * @param aEventMethod    event method (used for body as Content-Type=text/calendar; METHOD=???)
   * @param aAttFileName    attachment filename
   * @param aAttContentType attachment content-type
   * @return a list of error codes. Detailed error messages are returned in
   *   aErrorMessages.
   */
  function AddCalendarEvent(
    aErrorMessages  out nocopy    varchar2
  , aContent        in            clob
  , aEventMethod    in            varchar2 default 'REQUEST'
  , aAttFileName    in            varchar2 default 'invite.ics'
  , aAttContentType in            varchar2 default 'application/ics'
  )
    return varchar2
  is
  begin
    return AddCalendarEvent(aErrorMessages, aContent, aEventMethod, aAttFileName, aAttContentType, gTempMail);
  end AddCalendarEvent;

  /**
   * Function AddCalendarEvent
   * Description
   *    Adds a calendar event body and an ics attachment to e-mail passed in parameter.
   * @param aErrorMessages  a string were to return error messages.
   * @param aContent        event content (used for body and attachment)
   * @param aEventMethod    event method (used for body as Content-Type=text/calendar; METHOD=???)
   * @param aAttFileName    attachment filename
   * @param aAttContentType attachment content-type
   * @param aMail           mail object to use
   * @return a list of error codes. Detailed error messages are returned in
   *   aErrorMessages.
   */
  function AddCalendarEvent(
    aErrorMessages  out nocopy    varchar2
  , aContent        in            clob
  , aEventMethod    in            varchar2 default 'REQUEST'
  , aAttFileName    in            varchar2 default 'invite.ics'
  , aAttContentType in            varchar2 default 'application/ics'
  , aMail           in out nocopy TMAIL
  )
    return varchar2
  is
    vErrorCodes varchar2(4000);
  begin
    vErrorCodes  :=
      AddBody(aErrorMessages   => aErrorMessages
            , aContent         => aContent
            , aContentType     => cTEXT_VCAL
            , aMail            => aMail
            , aVCalMethod      => aEventMethod
             );

    if vErrorCodes is null then
      vErrorCodes  :=
        AddAttachment(aErrorMessages    => aErrorMessages
                    , aFileName         => aAttFileName
                    , aContent          => aContent
                    , aAttachmentType   => cCAL_REQ_TYPE
                    , aContentType      => aAttContentType
                    , aMail             => aMail
                     );
    end if;

    return vErrorCodes;
  end AddCalendarEvent;

  /**
   * Function AddAttachment
   * Description
   *    Adds an attachment to e-mail passed in parameter.
   * @param aErrorMessages  a string were to return error messages.
   * @param aFileName       attachment filename
   * @param aContent        attachment content
   * @param aAttachmentType attachment type
   * @param aContentType    attachment content-type
   * @param aMail           mail object to use
   * @return a list of error codes. Detailed error messages are returned in
   *   aErrorMessages.
   */
  function AddAttachment(
    aErrorMessages  out nocopy    varchar2
  , aFileName       in            varchar2 default ''
  , aContent        in            clob
  , aAttachmentType in            integer
  , aContentType    in            varchar2 default ''
  , aMail           in out nocopy TMAIL
  )
    return varchar2
  is
    vTempAttachment TATTACHMENT;
    vClob           clob;
    vContentID      number;
  begin
    if aMail.mAttachments is null then
      aMail.mAttachments  := TATTACHMENTS_LIST();
    end if;

    insert into EML_ATTACHMENT_DATA_TEMP
                (EML_ATTACHMENT_DATA_TEMP_ID
               , ATD_FILENAME
                )
         values (init_id_seq.nextval
               , aFileName
                )
      returning EML_ATTACHMENT_DATA_TEMP_ID
           into vContentID;

    select ATD_TEXT_ATTACHMENT_DATA
      into vClob
      from EML_ATTACHMENT_DATA_TEMP
     where EML_ATTACHMENT_DATA_TEMP_ID = vContentID;

    DBMS_LOB.open(vClob, DBMS_LOB.lob_readwrite);
    DBMS_LOB.copy(vClob, aContent, DBMS_LOB.getlength(aContent) );
    DBMS_LOB.close(vClob);
    vTempAttachment.mFileName                     := aFileName;
    vTempAttachment.mAttachmentType               := aAttachmentType;
    vTempAttachment.mContentType                  := aContentType;
    vTempAttachment.mContentID                    := vContentID;
    aMail.mAttachments.extend;
    aMail.mAttachments(aMail.mAttachments.count)  := vTempAttachment;
    return '';
  exception
    when others then
      aErrorMessages  := cATTACHMENT_ERROR || 'Error adding attachment ' || aFileName || ': ' || sqlerrm;
      return cATTACHMENT_ERROR;
  end AddAttachment;

  /**
   * Function Send
   * Description
   *    Send the e-mail passed in parameter or default e-mail object.
   * @param aErrorMessages  a string were to return error messages
   * @param aMailID         e-mail ID
   * @param aRFCMail        a BLOB where to return mail in RFC format
   * @return a list of error codes. Detailed error messages are returned in
   *   aErrorMessages.
   */
  function Send(aErrorMessages out nocopy varchar2, aMailID out nocopy number)
    return varchar2
  is
  begin
    return Send(aErrorMessages, aMailID, gTempMail);
  end Send;

  /**
   * Function Send
   * Description
   *    Send the e-mail passed in parameter.
   * @param aErrorMessages  a string were to return error messages
   * @param aMailID         e-mail ID
   * @param aMail           mail object to use
   * @return a list of error codes. Detailed error messages are returned in
   *   aErrorMessages.
   */
  function Send(aErrorMessages out nocopy varchar2, aMailID out nocopy number, aMail in TMAIL)
    return varchar2
  is
    vErrorCodes    varchar2(4000) := '';
    vErrorMessages varchar2(4000) := '';
    vRFCMail       blob;
  begin
    EML_JSENDER.JSetDebug(sys.DIUTIL.bool_to_int(gDebug) );
    vErrorCodes     :=
      EML_JSENDER.JCreateMail(vErrorMessages
                            , aMail.mSender
                            , aMail.mReplyTo
                            , aMail.mRecipients
                            , aMail.mCcRecipients
                            , aMail.mBccRecipients
                            , aMail.mNotification
                            , aMail.mPriority
                            , aMail.mCustomHeaders
                            , aMail.mSubject
                            , aMail.mBodyPlain
                            , aMail.mBodyHtml
                             );
    aErrorMessages  := aErrorMessages || vErrorMessages;

    if aMail.mBodyVCal is not null then
      vErrorCodes     :=
                vErrorCodes || EML_JSENDER.JAddBody(vErrorMessages, aMail.mBodyVCal, cTEXT_VCAL, aMail.mBodyVCalMethod);
      aErrorMessages  := aErrorMessages || vErrorMessages;
    end if;

    if aMail.mAttachments is not null then
      for vIndex in 1 .. aMail.mAttachments.count loop
        if    (aMail.mAttachments(vIndex).mAttachmentType = cCLOB_TYPE)
           or (aMail.mAttachments(vIndex).mAttachmentType = cBLOB_TYPE)
           or (aMail.mAttachments(vIndex).mAttachmentType = cCAL_REQ_TYPE) then
          vErrorCodes     :=
            vErrorCodes ||
            EML_JSENDER.JAddAttachment(vErrorMessages
                                     , aMail.mAttachments(vIndex).mContentID
                                     , aMail.mAttachments(vIndex).mAttachmentType
                                     , aMail.mAttachments(vIndex).mContentType
                                     , aMail.mAttachments(vIndex).mFileName
                                      );
          aErrorMessages  := aErrorMessages || vErrorMessages;
        else
          vErrorCodes     := vErrorCodes || cBAD_ATTACHMENT_TYPE;
          aErrorMessages  :=
            aErrorMessages ||
            cBAD_ATTACHMENT_TYPE ||
            'Bad attachment content type for ' ||
            aMail.mAttachments(vIndex).mFileName;
        end if;
      end loop;
    end if;

    DBMS_LOB.createtemporary(vRFCMail, false, DBMS_LOB.session);
    vErrorCodes     := vErrorCodes || EML_JSENDER.JGetRFCMail(vErrorMessages, vRFCMail);
    aErrorMessages  := aErrorMessages || vErrorMessages;

    if vErrorCodes is null then
      insert into EML_TO_SEND_EMAILS_QUEUE SDQ
                  (SDQ.EML_TO_SEND_EMAILS_QUEUE_ID
                 , SDQ.C_EMAIL_STATUS
                 , SDQ.SDQ_RFC_MAIL
                 , SDQ.C_EMAIL_SEND_MODE
                 , SDQ.SDQ_DATE_TO_SEND
                 , SDQ.SDQ_DATE_NEXT_TRY
                 , SDQ.C_EMAIL_BACKUP_MODE
                 , SDQ.SDQ_BACKUP_OPTIONS
                 , SDQ.A_DATECRE
                 , SDQ.A_IDCRE
                  )
           values (init_id_seq.nextval
                 , cTO_SEND
                 , vRFCMail
                 , aMail.mSendMode
                 , aMail.mDateToSend
                 , aMail.mDateToSend
                 , aMail.mBackupMode
                 , aMail.mBackupOptions
                 , sysdate
                 , PCS.PC_LIB_SESSION.GetUserIni
                  )
        returning EML_TO_SEND_EMAILS_QUEUE_ID
             into aMailID;

      -- If send mode is immediate
      if aMail.mSendMode = cSENDMODE_IMMEDIATE_FORCED then
        -- Sends e-mail
        ProcessMail(aMailID, vRFCMail, aMail.mSendMode, from_tz(cast(aMail.mDateToSend as timestamp), dbtimezone) at time zone 'GMT'
                  , aMail.mBackupMode, aMail.mBackupOptions);
        -- Get error codes and messages if exists
        vErrorCodes  := GetMailErrors(aErrorMessages, aMailID);
      end if;
    else
      aErrorMessages  := aErrorMessages || ' The e-mail hasn''t been sent.';
      aMailID         := -1;
    end if;

    return vErrorCodes;
  end Send;

  /**
   * Function GetMailErrors
   * Description
   *    Return error codes and messages of mail passed by ID
   * @param aErrorMessages  a string were to return error messages
   * @param aMailID         mail ID
   * @return a list of error codes. Detailed error messages are returned in
   *   aErrorMessages.
   */
  function GetMailErrors(aErrorMessages out nocopy varchar2, aMailID in number)
    return varchar2
  is
    vResult varchar2(4000);
  begin
    begin
      -- Recherche dans la table file d'attente
      select SDQ_ERROR_CODES
           , SDQ_ERROR_MESSAGES
        into vResult
           , aErrorMessages
        from EML_TO_SEND_EMAILS_QUEUE
       where EML_TO_SEND_EMAILS_QUEUE_ID = aMailID;
    exception
      -- Si non trouvé
      when no_data_found then
        begin
          -- Recherche dans la table de backup
          select STB_ERROR_CODES
               , STB_ERROR_MESSAGES
            into vResult
               , aErrorMessages
            from EML_SENT_EMAILS_BACKUP
           where EML_SENT_EMAILS_BACKUP_ID = aMailID;
        exception
          -- Si non trouvé
          when no_data_found then
            -- Le mail a été envoyé sans erreur
            vResult  := '';
        end;
    end;

    return vResult;
  end GetMailErrors;

  /**
   * Procedure ReadQueue
   * Description
   *    Reads queue and sends ready e-mails.
   */
  procedure ReadQueue(aDebug in boolean default null, aMaxConsecutiveEmails in integer default null)
  is
    vMaxConsecutiveEmails integer;
    vProcessedCount       integer;
    vCurrentMail          EML_TO_SEND_EMAILS_QUEUE%rowtype;
    vCurrentMailID        EML_TO_SEND_EMAILS_QUEUE.EML_TO_SEND_EMAILS_QUEUE_ID%type;
  begin
    if aDebug is not null then
      gDebug  := aDebug;
    end if;

    EML_JSENDER.JSetDebug(sys.DIUTIL.bool_to_int(gDebug) );
    vMaxConsecutiveEmails  := coalesce(aMaxConsecutiveEmails, PCS.PC_CONFIG.getConfig('EML_MAX_CONSECUTIVE_EMAILS'), 50);
    vProcessedCount        := 0;
    vCurrentMailID         := GetNextMail;

    -- Tant qu'il existe un email à envoyer et que, dans le cas ou un nombre
    -- maximal d'emails consécutif a été spécifié, le nombre d'emails envoyés
    -- ne dépasse pas cette limite, on envoie l'email.
    while(vCurrentMailID is not null)
     and (    (vMaxConsecutiveEmails = 0)
          or (vProcessedCount < vMaxConsecutiveEmails) ) loop
      update EML_TO_SEND_EMAILS_QUEUE SDQ
         set SDQ.C_EMAIL_STATUS = cSENDING
       where SDQ.EML_TO_SEND_EMAILS_QUEUE_ID = vCurrentMailID;

      select *
        into vCurrentMail
        from EML_TO_SEND_EMAILS_QUEUE SDQ
       where SDQ.EML_TO_SEND_EMAILS_QUEUE_ID = vCurrentMailID;

      ProcessMail(vCurrentMail.EML_TO_SEND_EMAILS_QUEUE_ID
                , vCurrentMail.SDQ_RFC_MAIL
                , vCurrentMail.C_EMAIL_SEND_MODE
                , from_tz(cast(vCurrentMail.SDQ_DATE_TO_SEND as timestamp), dbtimezone) at time zone 'GMT'
                , vCurrentMail.C_EMAIL_BACKUP_MODE
                , vCurrentMail.SDQ_BACKUP_OPTIONS
                 );
      commit;
      vProcessedCount  := vProcessedCount + 1;
      vCurrentMailID   := GetNextMail;
    end loop;
  end ReadQueue;

  /**
   * Function GetNextMail
   * Description
   *    Gets and returns the ID of the next unlocked e-mail to send.
   * @return the ID of the next e-mail to send
   */
  function GetNextMail
    return EML_TO_SEND_EMAILS_QUEUE.EML_TO_SEND_EMAILS_QUEUE_ID%type
  is
    vMailID EML_TO_SEND_EMAILS_QUEUE.EML_TO_SEND_EMAILS_QUEUE_ID%type;

    -- List of all ready to be sent e-mails
    cursor crMailIDs
    is
      select   EML_TO_SEND_EMAILS_QUEUE_ID
          from (select EML_TO_SEND_EMAILS_QUEUE_ID
                     , SDQ_DATE_TO_SEND
                     , from_tz(cast(SDQ_DATE_NEXT_TRY as timestamp), dbtimezone) as SDQ_DATE_NEXT_TRY
                  from EML_TO_SEND_EMAILS_QUEUE
                 where C_EMAIL_STATUS in(cTO_SEND, cTRY_AGAIN) )
         where SDQ_DATE_NEXT_TRY <= sysdate
      order by SDQ_DATE_TO_SEND;
  begin
    /* Tries to lock e-mail and returns its ID if successfull. If not, tries
    with next one.  */
    for tplMailIDs in crMailIDs loop
      begin
        select     EML_TO_SEND_EMAILS_QUEUE_ID
              into vMailID
              from EML_TO_SEND_EMAILS_QUEUE SDQ
             where SDQ.EML_TO_SEND_EMAILS_QUEUE_ID = tplMailIDs.EML_TO_SEND_EMAILS_QUEUE_ID
        for update nowait;

        -- Returns data if unlocked item found
        return vMailID;
      exception
        -- If item is locked by another job, do nothing and tries with next
        when ex.ROW_LOCKED then
          null;
        -- If item was processed by another job, do nothing and tries with next
        when no_data_found then
          null;
      end;
    end loop;

    -- Returns null if no ready item found
    return null;
  end GetNextMail;

  /**
   * Procedure ProcessMail
   * Description
   *    Sends and update e-mail.
   */
  procedure ProcessMail(
    aMailID        in number
  , aRFCMail       in blob
  , aSendMode      in EML_TO_SEND_EMAILS_QUEUE.C_EMAIL_SEND_MODE%type
  , aDateToSend    in EML_TO_SEND_EMAILS_QUEUE.SDQ_DATE_TO_SEND%type
  , aBackupMode    in EML_TO_SEND_EMAILS_QUEUE.C_EMAIL_BACKUP_MODE%type
  , aBackupOptions in EML_TO_SEND_EMAILS_QUEUE.SDQ_BACKUP_OPTIONS%type
  )
  is
    vErrorCodes    varchar2(4000);
    vErrorMessages varchar2(4000);
    vDateToSend    date;
    vDateNextTry   date;
    vTimeDiff      number;
  begin
    -- E-mail sending
    vErrorCodes  :=
      EML_JSENDER.JSendNow(vErrorMessages
                         , aRFCMail
                         , aSendMode
                         , aDateToSend
                         , PCS.PC_CONFIG.getConfig('EML_SMTP_SERVER_NAME')
                         , PCS.PC_CONFIG.getConfig('EML_SMTP_SERVER_PORT')
                         , PCS.PC_CONFIG.getConfig('EML_SMTP_USERNAME')
                         , PCS.PC_CONFIG.getConfig('EML_SMTP_PASSWORD')
                          );

    -- If no errors
    if (vErrorCodes is null) then
      -- Backup e-mail if asked
      if aBackupMode = cBACKUP_DATABASE then
        insert into EML_SENT_EMAILS_BACKUP STB
                    (STB.EML_SENT_EMAILS_BACKUP_ID
                   , STB.C_EMAIL_STATUS
                   , STB.STB_ERROR_CODES
                   , STB.STB_ERROR_MESSAGES
                   , STB.STB_RFC_MAIL
                   , STB.A_DATECRE
                   , STB.A_DATEMOD
                   , STB.A_IDCRE
                   , STB.A_IDMOD
                    )
          (select SDQ.EML_TO_SEND_EMAILS_QUEUE_ID
                , cSENT
                , vErrorCodes
                , vErrorMessages
                , SDQ.SDQ_RFC_MAIL
                , SDQ.A_DATECRE
                , sysdate
                , SDQ.A_IDCRE
                , SDQ.A_IDCRE
             from EML_TO_SEND_EMAILS_QUEUE SDQ
            where SDQ.EML_TO_SEND_EMAILS_QUEUE_ID = aMailID);
      end if;

      -- Delete e-mail from queue
      delete from EML_TO_SEND_EMAILS_QUEUE SDQ
            where SDQ.EML_TO_SEND_EMAILS_QUEUE_ID = aMailID;
    elsif vErrorCodes = '100 ' then
      -- If error code is 'partially sent'
      -- Backup e-mail if asked
      if aBackupMode = cBACKUP_DATABASE then
        insert into EML_SENT_EMAILS_BACKUP STB
                    (STB.EML_SENT_EMAILS_BACKUP_ID
                   , STB.C_EMAIL_STATUS
                   , STB.STB_ERROR_CODES
                   , STB.STB_ERROR_MESSAGES
                   , STB.STB_RFC_MAIL
                   , STB.A_DATECRE
                   , STB.A_DATEMOD
                   , STB.A_IDCRE
                   , STB.A_IDMOD
                    )
          (select SDQ.EML_TO_SEND_EMAILS_QUEUE_ID
                , cSENT
                , vErrorCodes
                , vErrorMessages
                , SDQ.SDQ_RFC_MAIL
                , SDQ.A_DATECRE
                , sysdate
                , SDQ.A_IDCRE
                , SDQ.A_IDCRE
             from EML_TO_SEND_EMAILS_QUEUE SDQ
            where SDQ.EML_TO_SEND_EMAILS_QUEUE_ID = aMailID);
      end if;

      -- Update e-mail with error code and message
      update EML_TO_SEND_EMAILS_QUEUE SDQ
         set SDQ.C_EMAIL_STATUS = cPARTIAL
           , SDQ.SDQ_ERROR_CODES = vErrorCodes
           , SDQ.SDQ_ERROR_MESSAGES = vErrorMessages
       where SDQ.EML_TO_SEND_EMAILS_QUEUE_ID = aMailID;
    elsif vErrorCodes = '000 ' then
      -- If error code is 'temporary error'
      -- Update the date of next try or abort if sending returned error for too many times
      select SDQ_DATE_TO_SEND
           , SDQ_DATE_NEXT_TRY
        into vDateToSend
           , vDateNextTry
        from EML_TO_SEND_EMAILS_QUEUE SDQ
       where SDQ.EML_TO_SEND_EMAILS_QUEUE_ID = aMailID;

      vTimeDiff  := cDELAY_RAISE_FACTOR *(vDateNextTry - vDateToSend + cMIN_DELAY_BETWEEN_TRIES /(3600 * 24) );

--    dbms_output.put_line(to_char(vDateToSend,'DD-MON-YYYY HH24:MI'));
--    dbms_output.put_line(to_char(vDateNextTry,'DD-MON-YYYY HH24:MI'));
      if vTimeDiff > 7 then
        update EML_TO_SEND_EMAILS_QUEUE SDQ
           set SDQ.C_EMAIL_STATUS = cFAILED
             , SDQ.SDQ_ERROR_CODES = vErrorCodes
             , SDQ.SDQ_ERROR_MESSAGES = vErrorMessages
         where SDQ.EML_TO_SEND_EMAILS_QUEUE_ID = aMailID;
      else
        vDateNextTry  := vDateToSend + vTimeDiff;

        update EML_TO_SEND_EMAILS_QUEUE SDQ
           set SDQ.C_EMAIL_STATUS = cTRY_AGAIN
             , SDQ.SDQ_DATE_NEXT_TRY = vDateNextTry
             , SDQ.SDQ_ERROR_CODES = vErrorCodes
             , SDQ.SDQ_ERROR_MESSAGES = vErrorMessages
         where SDQ.EML_TO_SEND_EMAILS_QUEUE_ID = aMailID;
      end if;
    else
      update EML_TO_SEND_EMAILS_QUEUE SDQ
         set SDQ.C_EMAIL_STATUS = cFAILED
           , SDQ.SDQ_ERROR_CODES = vErrorCodes
           , SDQ.SDQ_ERROR_MESSAGES = vErrorMessages
       where SDQ.EML_TO_SEND_EMAILS_QUEUE_ID = aMailID;
    end if;
  end ProcessMail;
-- Initialization method
begin
  -- PC_LIB_SESSION global variables inititalization
  select nvl(PCS.PC_LIB_SESSION.COMPANY_ID, max(PC_COMP_ID) )
       , nvl(PCS.PC_LIB_SESSION.COMP_LANG_ID, max(PC_LANG_ID) )
    into PCS.PC_LIB_SESSION.COMPANY_ID
       , PCS.PC_LIB_SESSION.COMP_LANG_ID
    from PCS.V_PC_COMP_OWNER
   where SCRDBOWNER = COM_CURRENTSCHEMA   -- sys_context('USERENV', 'CURRENT_SCHEMA')
     and SCRDB_LINK is null;

  select nvl(PCS.PC_LIB_SESSION.USER_ID, max(PC_USER_ID) )
       , nvl(PCS.PC_LIB_SESSION.USER_LANG_ID, max(PC_LANG_ID) )
    into PCS.PC_LIB_SESSION.USER_ID
       , PCS.PC_LIB_SESSION.USER_LANG_ID
    from PCS.PC_USER
   where USE_NAME = user;
end EML_SENDER;
