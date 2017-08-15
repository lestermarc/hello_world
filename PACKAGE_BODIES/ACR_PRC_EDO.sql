--------------------------------------------------------
--  DDL for Package Body ACR_PRC_EDO
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACR_PRC_EDO" 
is
  /**
  * Description :
  *   Suppression d'une interaction IN (investissement))
  */
  procedure DeleteInteractionIN(iACR_EDO_IN_ID in ACR_EDO_IN.ACR_EDO_IN_ID%type)
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACR_ENTITY.gcAcrEdoIn, ltCRUD_DEF);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACR_EDO_IN_ID', iACR_EDO_IN_ID);
    FWK_I_MGT_ENTITY.DeleteEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end DeleteInteractionIN;

  /**
  * Description :
  *   Suppression d'une interaction WO (fonctionnement)
  */
  procedure DeleteInteractionWO(iACR_EDO_WO_ID in ACR_EDO_WO.ACR_EDO_WO_ID%type)
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACR_ENTITY.gcAcrEdoWo, ltCRUD_DEF);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACR_EDO_WO_ID', iACR_EDO_WO_ID);
    FWK_I_MGT_ENTITY.DeleteEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end DeleteInteractionWO;

  /**
  * Description :
  *   Ajout d'une interaction WO (fonctionnement)
  */
  procedure InsertInteractionWO(iEDW_TASK in ACR_EDO_WO.EDW_TASK%type, iACR_EDO_ID in ACR_EDO.ACR_EDO_ID%type)
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACR_ENTITY.gcAcrEdoWo, ltCRUD_DEF);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACR_EDO_ID', iACR_EDO_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EDW_TASK', iEDW_TASK);
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end InsertInteractionWO;

  /**
  * Description :
  *   Ajout d'une interaction IN (investissement)
  */
  procedure InsertInteractionIN(iEDI_TASK in ACR_EDO_IN.EDI_TASK%type, iACR_EDO_ID in ACR_EDO.ACR_EDO_ID%type)
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACR_ENTITY.gcAcrEdoIn, ltCRUD_DEF);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACR_EDO_ID', iACR_EDO_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EDI_TASK', iEDI_TASK);
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end InsertInteractionIN;

  /**
  * Description :
  *   Vérification des données
  */
  procedure VerifyDatas(iACR_EDO_ID in ACR_EDO.ACR_EDO_ID%type, oErrorCode out integer, oErrorMsg out varchar2)
  is
  begin
    /*
      Plage pour les codes d'erreur: (aErrorCode > 20099) and (aErrorCode < 21000)
      1. -20100 Le No. OFS et le NPA ne doivent pas être identiques.
      2. -20200 Règle pour les checkboxes concernant les années des comptes (année courante, année précédente, budget)
          a) Activer par défaut les checkboxes suivantes: Année courante, Année précédente
          b) Au moins une checkbox doit être activée.
      3. -20300 Vérifier le format de l’adresse e-mail.
    */
    oErrorCode  := 0;
    oErrorMsg   := '';

    if iACR_EDO_ID = 0 then
      return;
    end if;

    select case
             when EDP.EDO_MUNICIPALITY_NUMBER = EDP.EDO_CONTACT_ZIPCODE then -20100
             when(EDP.EDO_CURRENT_YEAR_DATAS + EDP.EDO_PREVIOUS_YEAR_DATAS + EDP.EDO_BUDGET_DATAS) = 0 then -20200
             when regexp_instr(EDP.EDO_CONTACT_EMAIL, '[^@]+@[^\.]+\..+') = 0 then -20300
             when EDP.EDO_RECEIVER_EMAIL is not null
             and regexp_instr(EDP.EDO_RECEIVER_EMAIL, '[^@]+@[^\.]+\..+') = 0 then -20310
             else 0
           end error_code
      into oErrorCode
      from ACR_EDO EDP
     where ACR_EDO_ID = iACR_EDO_ID;

    if oErrorCode < 0 then
      -- PCS.PC_FUNCTIONS.TranslateWord('Le No. OFS et le NPA ne doivent pas être identiques')
      -- PCS.PC_FUNCTIONS.TranslateWord('Au moins une case à cocher activée (année courante, année précédente, budget)')
      -- PCS.PC_FUNCTIONS.TranslateWord('Format de l’adresse e-mail incorrect')
      oErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord(to_char(oErrorCode, '99999') || '_ACR_ED_OFIN');
    end if;
  end VerifyDatas;

  /**
  * Description :
  *   Construction du nom de fichier
  */
  function BuildFileName(iACR_EDO_ID in ACR_EDO.ACR_EDO_ID%type)
    return varchar2
  is
    lvResult              varchar2(255);
    lcvToReplace constant varchar2(3)   := '/*?';
  begin
    select 'R' ||
           substr( (select FYE_NO_EXERCICE
                      from ACS_FINANCIAL_YEAR
                     where ACS_FINANCIAL_YEAR_ID = EDO.ACS_FINANCIAL_YEAR_ID), -2) ||
           '_' ||
           EDO.EDO_MUNICIPALITY_NUMBER ||
           '_' ||
           translate(EDO.EDO_MUNICIPALITY_NAME, lcvToReplace, lpad('_', length(lcvToReplace), '_') ) ||
           '_' ||
           'V02' ||
           '_' ||
           to_char(to_number(nvl(substr(EDO.EDO_XML_PATH
                                      , instr(EDO.EDO_XML_PATH, 'V02') + 4
                                      , instr(EDO.EDO_XML_PATH, '.XML') - instr(EDO.EDO_XML_PATH, 'V02') - 4
                                       )
                               , '0'
                                )
                            ) +
                   1
                 , '00'
                  ) ||
           '.XML' FILE_EXTENSION
      into lvResult
      from ACR_EDO EDO
     where EDO.ACR_EDO_ID = iACR_EDO_ID;

    return lvResult;
  end BuildFileName;

  /**
  * Description
  *   Retourne 1 si l'envoie de l'EDO par email est disponible, sinon 0
  */
  function MailAvailable
    return integer
  is
  begin
    return PCS.PC_OPTION_FUNCTIONS.IsOptionActive('MAIL_SENDER');
  end MailAvailable;

  /**
  * Description
  *   Envoi de l'EDO par email
  */
  procedure SendMail(
    iACR_EDO_ID in     ACR_EDO.ACR_EDO_ID%type
  , iSubject    in     varchar2
  , iBody       in     varchar2
  , oMsg        out    varchar2
  )
  is
    lcbUSE_COMPRESSED constant boolean           := true;
    lvFilename                 varchar2(255);
    lrEDOData                  ACR_EDO%rowtype;
    lvErrorMessages            varchar2(4000);
    lvErrorCodes               varchar2(4000);
    lTempBLOB                  blob;
    lTempCompBLOB              blob;
    lnMailID                   number;
    lnDest_offset              integer;
    lnSrc_offset               integer;
    lnLang_ctx                 integer;
    lnWarning                  varchar2(1000);
    lvSubject                  varchar2(4000);
    lvBody                     varchar2(4000);
  begin
    select *
      into lrEDOData
      from ACR_EDO
     where ACR_EDO.ACR_EDO_ID = iACR_EDO_ID;

    if DBMS_LOB.getlength(lrEDOData.EDO_XML) = 0 then
      oMsg  := 'XML empty';
      return;
    end if;

    lvFilename    := lrEDOData.EDO_XML_PATH;
    lvSubject     := iSubject;
    lvBody        := iBody;

    if iSubject is null then
      lvSubject  := 'EDO File ' || lvFilename;
    end if;

    if iBody is null then
      lvBody  :=
        lrEDOData.EDO_MUNICIPALITY_NUMBER ||
        ' ' ||
        lrEDOData.EDO_MUNICIPALITY_NAME ||
        chr(13) ||
        chr(13) ||
        'Contact:' ||
        chr(13) ||
        lrEDOData.C_EDO_CONTACT_TITLE ||
        ' ' ||
        lrEDOData.EDO_CONTACT_FORENAME ||
        ' ' ||
        lrEDOData.EDO_CONTACT_NAME ||
        chr(13) ||
        lrEDOData.EDO_CONTACT_STREET ||
        chr(13) ||
        lrEDOData.EDO_CONTACT_ZIPCODE ||
        ' ' ||
        lrEDOData.EDO_CONTACT_CITY ||
        chr(13) ||
        lrEDOData.EDO_CONTACT_TEL ||
        ' ' ||
        lrEDOData.EDO_CONTACT_EMAIL;
    end if;

    -- Creates e-mail and stores it in default e-mail object
    lvErrorCodes  :=
      EML_SENDER.CreateMail(aErrorMessages    => lvErrorMessages
                          , aSender           => lrEDOData.EDO_CONTACT_EMAIL
                          , aReplyTo          => lrEDOData.EDO_CONTACT_EMAIL
                          , aRecipients       => lrEDOData.EDO_RECEIVER_EMAIL
                          , aCcRecipients     => ''
                          , aBccRecipients    => ''
                          , aNotification     => 0
                          , aPriority         => EML_SENDER.cPRIOTITY_NORMAL_LEVEL
                          , aCustomHeaders    => 'X-Mailer: PCS mailer'
                          , aSubject          => lvSubject
                          , aBodyPlain        => lvBody
                          , aSendMode         => EML_SENDER.cSENDMODE_IMMEDIATE_FORCED
                          , aDateToSend       => sysdate
                          , aTimeZoneOffset   => sessiontimezone   --'02:00'
                          , aBackupMode       => EML_SENDER.cBACKUP_DATABASE
                           --, aBackupOptions    => ''
                           );

    if lvErrorCodes <> '' then
      oMsg  := lvErrorMessages;
      return;
    end if;

    if not lcbUSE_COMPRESSED then
      -- Adds an ascii attachment to default e-mail object
      lvErrorCodes  :=
        EML_SENDER.AddClobAttachment(aErrorMessages   => lvErrorMessages
                                   , aFileName        => lvFilename
                                   , aContent         => lrEDOData.EDO_XML
                                    );
    else
      DBMS_LOB.createtemporary(lob_loc => lTempBLOB, cache => true);
      lnDest_offset  := 1;
      lnSrc_offset   := 1;
      lnLang_ctx     := DBMS_LOB.default_lang_ctx;
      DBMS_LOB.converttoblob(lTempBLOB
                           , lrEDOData.EDO_XML
                           , DBMS_LOB.getlength(lrEDOData.EDO_XML)
                           , lnDest_offset
                           , lnSrc_offset
                           , DBMS_LOB.default_csid
                           , lnLang_ctx
                           , lnWarning
                            );
      DBMS_LOB.createtemporary(lob_loc => lTempCompBLOB, cache => true);
      -- Compress the data
      UTL_COMPRESS.lz_compress(src => lTempBLOB, dst => lTempCompBLOB);
      -- Adds a binary attachment to default e-mail object
      lvErrorCodes   :=
        EML_SENDER.AddBlobAttachment(aErrorMessages   => lvErrorMessages
                                   , aFileName        => lvFilename || '.zip'
                                   , aContent         => lTempCompBLOB
                                    );   --???
      DBMS_LOB.freetemporary(lTempCompBLOB);
      DBMS_LOB.freetemporary(lTempBLOB);
    end if;

    if lvErrorCodes <> '' then
      oMsg  := lvErrorMessages;
      return;
    end if;

    -- Sends the e-mail contained in default e-mail object (in fact stores it in a queue)
    lvErrorCodes  := EML_SENDER.Send(aErrorMessages => lvErrorMessages, aMailID => lnMailID);

    if lvErrorCodes <> '' then
      oMsg  := lvErrorMessages;
      return;
    end if;
  end SendMail;
end ACR_PRC_EDO;
