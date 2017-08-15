--------------------------------------------------------
--  DDL for Package Body EML_SENDER_TEST
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "EML_SENDER_TEST" 
as
/*-**************************************************************************-*/
/*                                                                            */
/*                 Sample code for use of EML_SENDER package                  */
/*                                                                            */
/*                Copyright (c) 2005 ProConcept International                 */
/*                                                                            */
/*                 Author PCS - JCH    Created : 20.06.2005                   */
/*                                                                            */
/*-**************************************************************************-*/

  /**
   * Description
   *    Sample code for use of EML_SENDER package.
   * @author JCH
   * @created 20.06.2005
   * @version 2003
   * @lastUpdate
   */

  /**
   * Procedure PrintError
   * Description
   *    Print error's code and message in TOAD console.
   */
  procedure PrintError(aTitle varchar2, aErrorCodes varchar2, aErrorMessages varchar2)
  is
  begin
    if     aErrorCodes is null
       and aErrorMessages is null then
      DBMS_OUTPUT.put_line(aTitle || ': No error');
    else
      DBMS_OUTPUT.put_line(aTitle);
      DBMS_OUTPUT.put_line('ErrorCodes: ' || aErrorCodes);
      DBMS_OUTPUT.put_line('Messages: ');
      DBMS_OUTPUT.put_line(aErrorMessages);
    end if;
  end;

  /**
   * Procedure PrintMessage
   * Description
   *    Print title and message in TOAD console.
   */
  procedure PrintMessage(aTitle varchar2, aMessage varchar2)
  is
  begin
    DBMS_OUTPUT.put_line(aTitle || ': ' || aMessage);
  end;

  /**
   * Procedure SendInternalMailVariable
   * Description
   *    Sends an e-mail using default e-mail object.
   */
  procedure SendInternalMailVariable(
    aRecipients in varchar2 default null
  , aSubject    in varchar2 default null
  , aBodyPlain  in clob default null
  , aBodyHTML   in clob default null
  )
  is
    vErrorMessages varchar2(4000);
    vErrorCodes    varchar2(4000);
    vTempRaw       raw(4000)      := 'E72848574873FE293482AB4930C93837D7839E00290F939A929BC03CB035';
    vTempBLOB      blob           := vTempRaw;
    vTempCLOB      clob           := 'Hello, this is an attachment';
    vMailID        number;
  --aRecipients    varchar2(4000) := '';
  --aSubject       varchar2(4000) := '';
  --aBodyPlain     clob := '';
  --aBodyHTML      clob := '';
  begin
    DBMS_JAVA.set_output(5000);

    -- Set debug printing
    EML_SENDER.SetDebug(true);

    -- Creates e-mail and stores it in default e-mail object
    vErrorCodes  :=
      EML_SENDER.CreateMail(aErrorMessages    => vErrorMessages
                          , aSender           => 'Sender <sender@exemple.ch>'
                          , aReplyTo          => 'ReplyTo <replyto@exemple.ch>'
                          , aRecipients       => nvl(aRecipients, 'recipient@exemple.ch')
                          , aCcRecipients     => ''   --CcRecipient <ccrecipient@exemple.ch>'
                          , aBccRecipients    => ''
                          , aNotification     => 0
                          , aPriority         => EML_SENDER.cPRIOTITY_HIGH_LEVEL
                          , aCustomHeaders    => 'X-Mailer: PCS mailer'
                          , aSubject          => nvl(aSubject, '[TestMail] Test internal var')
                          , aBodyPlain        => nvl(aBodyPlain, 'Hello world !')
                          , aBodyHTML         => nvl(aBodyHTML, 'Hello <B>World</B><BR>How are you ?')
                          , aSendMode         => EML_SENDER.cSENDMODE_IMMEDIATE_FORCED
                          , aDateToSend       => sysdate
                          , aTimeZoneOffset   => sessiontimezone   --'02:00'
                          , aBackupMode       => EML_SENDER.cBACKUP_DATABASE
                           --, aBackupOptions    => ''
                           );
    EML_SENDER_TEST.PrintError('CreateMail', vErrorCodes, vErrorMessages);

    -- Adds an ascii attachment to default e-mail object
    vErrorCodes := EML_SENDER.AddClobAttachment(aErrorMessages => vErrorMessages, aFileName => 'pj.txt', aContent => vTempCLOB);
    EML_SENDER_TEST.PrintError('AddClobAttachment', vErrorCodes, vErrorMessages);

    -- Adds a binary attachment to default e-mail object
    vErrorCodes := EML_SENDER.AddBlobAttachment(aErrorMessages => vErrorMessages, aFileName => 'fake.bin', aContent => vTempBLOB);
    EML_SENDER_TEST.PrintError('AddBlobAttachment', vErrorCodes, vErrorMessages);

    -- Sends the e-mail contained in default e-mail object (in fact stores it in a queue)
    vErrorCodes := EML_SENDER.Send(aErrorMessages => vErrorMessages, aMailID => vMailID);
    EML_SENDER_TEST.PrintError('Send', vErrorCodes, vErrorMessages);
    EML_SENDER_TEST.PrintMessage('Mail ID', to_char(vMailID));
  end SendInternalMailVariable;

  /**
   * Procedure SendExternalMailVariable
   * Description
   *    Sends an e-mail using a local e-mail object.
   */
  procedure SendExternalMailVariable(
    aRecipients in varchar2 default null
  , aSubject    in varchar2 default null
  , aBodyPlain  in clob default null
  , aBodyHTML   in clob default null
  )
  is
    vErrorMessages varchar2(4000);
    vErrorCodes    varchar2(4000);
    vTempRaw       raw(4000) := 'E72848574873FE293482AB4930C934567891374454DE6456465AB837D7839E00290F939A929BC03CB035132AB4';
    vTempBLOB      blob      := vTempRaw;
    vMailID        number;
    vMail          EML_SENDER.TMAIL;
  --aRecipients    varchar2(4000) := '';
  --aSubject       varchar2(4000) := '';
  --aBodyPlain     clob := '';
  --aBodyHTML      clob := '';
  begin
    DBMS_JAVA.set_output(5000);
    -- Fills e-mail's fields
    vMail.mSender         := 'Sender <sender@exemple.ch>';
    vMail.mReplyTo        := 'ReplyTo <replyto@exemple.ch>';
    vMail.mRecipients     := nvl(aRecipients, 'recipient1@exemple.ch,recipient2@exemple.ch');
    --vMail.mCcRecipients   := 'CcRecipient <ccrecipient@exemple.ch>';
    --vMail.mBccRecipients  := '';
    vMail.mNotification   := 0;
    vMail.mPriority       := EML_SENDER.cPRIOTITY_LOW_LEVEL;
    vMail.mCustomHeaders  := 'X-Mailer: PCS mailer';
    vMail.mSubject        := nvl(aSubject, '[TestMail] Test external var');
    vMail.mBodyPlain      := nvl(aBodyPlain, 'Hello world !');
    vMail.mBodyHTML       := nvl(aBodyHTML, 'Hello <B>World</B><BR>How are you ?');
    vMail.mSendMode       := EML_SENDER.cSENDMODE_DELAYED_FIXED_DATE;
    vMail.mDateToSend     := from_tz(cast(sysdate as timestamp), sessiontimezone) at time zone dbtimezone;
    vMail.mBackupMode     := EML_SENDER.cBACKUP_NONE;
    vMail.mBackupOptions  := '';

    -- And sends it (in fact stores it in a queue)
    vErrorCodes := EML_SENDER.Send(aErrorMessages => vErrorMessages, aMailID => vMailID, aMail => vMail);
    EML_SENDER_TEST.PrintError('Send', vErrorCodes, vErrorMessages);
    EML_SENDER_TEST.PrintMessage('Mail ID', to_char(vMailID));
  end SendExternalMailVariable;

  /**
   * Procedure SendCalendarEvent
   * Description
   *    Sends an e-mail with calendar request using default e-mail object.
   */
  procedure SendCalendarEvent(
    aRecipients  in varchar2 default null
  , aEventBody   in varchar2 default null
  , aEventMethod in varchar2 default null
  , aSubject     in varchar2 default null
  , aBodyPlain   in clob default null
  , aBodyHTML    in clob default null
  )
  is
    vErrorMessages varchar2(4000);
    vErrorCodes    varchar2(4000);
    vTempCLOB      clob :=
'BEGIN:VCALENDAR
PRODID:-//Google Inc//Google Calendar 70.9054//EN
VERSION:2.0
CALSCALE:GREGORIAN
METHOD:REQUEST
BEGIN:VEVENT
DTSTART:20160226T080000Z
DTEND:20160226T150000Z
DTSTAMP:20151217T130214Z
ORGANIZER;CN=Email tester:mailto:email.tester@solvaxis.com
ATTENDEE;CN=Testers;X-NUM-GUESTS=0:mailto:testers@solvaxis.com
CREATED:20151029T141135Z
DESCRIPTION:This is a calendar reqest test with special characters éöà.
LAST-MODIFIED:20151217T130213Z
LOCATION:Sonceboz
SEQUENCE:1
STATUS:CONFIRMED
SUMMARY:Calendar reqest test
TRANSP:OPAQUE
END:VEVENT
END:VCALENDAR';
    vMailID        number;
  --aRecipients    varchar2(4000) := '';
  --aEventBody     varchar2(4000) := '';
  --aEventMethod   varchar2(4000) := '';
  --aSubject       varchar2(4000) := '';
  --aBodyPlain     clob := '';
  --aBodyHTML      clob := '';
  begin
    DBMS_JAVA.set_output(5000);

    -- Set debug printing
    EML_SENDER.SetDebug(true);

    -- Creates e-mail and stores it in default e-mail object
    vErrorCodes  :=
      EML_SENDER.CreateMail(aErrorMessages   => vErrorMessages
                          , aSender          => 'Sender <sender@exemple.ch>'
                          , aReplyTo         => 'ReplyTo <replyto@exemple.ch>'
                          , aRecipients      => nvl(aRecipients, 'recipient@exemple.ch')
                          --, aCcRecipients    => 'CcRecipient <ccrecipient@exemple.ch>'
                          --, aBccRecipients   => ''
                          , aCustomHeaders   => 'X-Mailer: PCS mailer'
                          , aSubject         => nvl(aSubject, '[TestMail] Test calendar request')
                          , aBodyPlain       => nvl(aBodyPlain, 'This is a calendar request')
                          , aBodyHTML        => nvl(aBodyHTML, 'This is a <B>calendar</B> request')
                          , aSendMode        => EML_SENDER.cSENDMODE_IMMEDIATE_FORCED
                           );
    EML_SENDER_TEST.PrintError('CreateMail', vErrorCodes, vErrorMessages);

    -- Adds an ascii attachment to default e-mail object
    vErrorCodes  :=
      EML_SENDER.AddCalendarEvent(aErrorMessages   => vErrorMessages
                                , aContent         => nvl(aEventBody, vTempCLOB)
                                , aEventMethod     => aEventMethod
                                 );
    EML_SENDER_TEST.PrintError('AddCalendarEvent', vErrorCodes, vErrorMessages);

    -- Sends the e-mail contained in default e-mail object (in fact stores it in a queue)
    vErrorCodes := EML_SENDER.Send(aErrorMessages => vErrorMessages, aMailID => vMailID);
    EML_SENDER_TEST.PrintError('Send', vErrorCodes, vErrorMessages);
    EML_SENDER_TEST.PrintMessage('Mail ID', to_char(vMailID));
  end SendCalendarEvent;

  /**
   * Procedure sample_mail_doc
   * Description
   *    Sends an e-mail with document specifications.
   */
/*
  procedure sample_mail_doc(aDocumentID DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aRecipients in varchar2 default '')
  is
    vNumber        DOC_DOCUMENT.DMT_NUMBER%type;
    vAmount        DOC_FOOT.FOO_DOCUMENT_TOTAL_AMOUNT%type;
    vMail          EML_SENDER.TMAIL;
    vMailID        number;
    vErrorMessages varchar2(4000);
    vErrorCodes    varchar2(4000);
  begin
    -- Search dm number
    select DMT_NUMBER
      into vNumber
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = aDocumentID;

    select FOO_DOCUMENT_TOTAL_AMOUNT
      into vAmount
      from DOC_DOCUMENT DOC
         , DOC_FOOT FOO
     where DOC.DOC_DOCUMENT_ID = FOO.DOC_DOCUMENT_ID
       and DOC.DOC_DOCUMENT_ID = aDocumentID;

    if vAmount > 50 then
      -- Sends mail
      -- Veuillez valider le document NO xxxxxxx

      -- Fills e-mail's fields
      vMail.mSender         := 'ProConcept ERP generated mail<no_reponse@exemple.ch>';
      --vMail.mReplyTo        := '';
      vMail.mRecipients     := nvl(aRecipients, 'recipient@exemple.ch');
      --vMail.mCcRecipients   := '';
      --vMail.mBccRecipients  := '';
      vMail.mNotification   := 0;
      vMail.mPriority       := EML_SENDER.cPRIOTITY_NORMAL_LEVEL;
      vMail.mCustomHeaders  := 'X-Mailer: PCS mailer';
      vMail.mSubject        := '[TestMail] Test notification de facture fournisseur';
      vMail.mBodyPlain      := 'Veuillez valider le document n°' || to_char(vNumber) || '.';
      vMail.mBodyHTML       := 'Veuillez valider le document n°<B>' || to_char(vNumber) || '</B>.';
      vMail.mSendMode       := EML_SENDER.cSENDMODE_IMMEDIATE;
      --vMail.mDateToSend     := from_tz(cast(sysdate as timestamp), sessiontimezone) at time zone dbtimezone;
      vMail.mBackupMode     := EML_SENDER.cBACKUP_NONE;
      --vMail.mBackupOptions  := '';

      -- And sends it (in fact stores it in a queue)
      vErrorCodes := EML_SENDER.Send(aErrorMessages => vErrorMessages, aMailID => vMailID, aMail => vMail);

      if vErrorCodes is not null then
        raise_application_error('-20000', 'Code(s): ' || vErrorCodes || '- Message(s): ' || vErrorMessages);
      end if;
    end if;
  end sample_mail_doc;
*/
  /**
   * Procedure LaunchSenderJob
   * Description
   *    Launches job to send ready e-mails.
   */
  procedure LaunchSenderJob
  is
  begin
    DBMS_JAVA.set_output(5000);
    -- Reads queue and sends ready e-mails
    --EML_SENDER.ReadQueue; -- Default debug value
    --EML_SENDER.ReadQueue(false); -- False debug value
    EML_SENDER.ReadQueue(true); -- True debug value
  end LaunchSenderJob;
end EML_SENDER_TEST;
