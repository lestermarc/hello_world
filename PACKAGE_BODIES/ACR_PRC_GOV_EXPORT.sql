--------------------------------------------------------
--  DDL for Package Body ACR_PRC_GOV_EXPORT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACR_PRC_GOV_EXPORT" 
is

  /**
  * Description
  *   Flux de création d'un nouvel enregistrement
  */
  procedure CreateNewRecord(iMainTable in varchar2, oCurrentId out number)
  is
    lnRefId number;
  begin
    if iMainTable = 'ACR_EDO' then
      ACR_LIB_EDO.DuplicateLastRecord(oCurrentId);
    elsif iMainTable = 'ACR_SOCIAL_BREAKDOWN' then
      --Copie de l'enregistrement référence
      ACR_PRC_SOCIAL_BREAKDOWN.DuplicateActiveRecord(lnRefId, oCurrentId);
      --Statut de l'enregistrement référence mis à 'Historié'
      ACR_PRC_SOCIAL_BREAKDOWN.SetStatusState(lnRefId, '2');
      --Statut de l'enregistrement nouvelement créé mis à actif
      ACR_PRC_SOCIAL_BREAKDOWN.SetStatusState(oCurrentId, '1');
    end if;
  end;

  /**
  * Description
  *   Création du xml data
  */
  procedure PrepareXml(iMainTable in varchar2, iCurrentId in number, oErrorMsg out varchar2)
  is
    lvErrorCode varchar2(500);
    lXml        Clob;
  begin
    if iCurrentId = 0 then
      return;
    end if;
    if iMainTable = 'ACR_SOCIAL_BREAKDOWN' then
      --Contrôle des données
      ACR_LIB_SOCIAL_BREAKDOWN.CheckDatasIntegrity(iCurrentId, lvErrorCode);
      if lvErrorCode is null then
        --Vide le contenu du champ XML
        ACR_PRC_SOCIAL_BREAKDOWN.SetXmlData(iCurrentId,'');
        --Videla référence au fichier physique
        ACR_PRC_SOCIAL_BREAKDOWN.SetXMLPath(iCurrentId,'');
        --Génération du XML
        lXml := ACR_LIB_SOCIAL_XML.GetSocialXML(iCurrentId);
        --Mise à jour du champ XML avec la valeur obtenue
        ACR_PRC_SOCIAL_BREAKDOWN.SetXmlData(iCurrentId,lXml);
      end if;
    end if;

    if lvErrorCode is not null then
      oErrorMsg := (PCS.PC_FUNCTIONS.TranslateWord(lvErrorCode));
    end if;

  end PrepareXml;


  procedure SendMail(iMainTable in varchar2,iCurrentId in number, oErrorMsg out varchar2)
  is
    lcbUSE_COMPRESSED constant boolean  := true;
    lTempBLOB                  blob;
    lTempCompBLOB              blob;
    lnMailID                   number;
    lnDest_offset              integer;
    lnSrc_offset               integer;
    lnLang_ctx                 integer;
    lnWarning                  varchar2(1000);

    lcXML          Clob;
    lvTo           varchar2(255);
    lvFilePath     varchar2(255);
    lvErrorCodes   varchar2(4000);
    lvSubject      varchar2(4000);
    lvBody         varchar2(4000);
    lvErrorMsg     varchar2(4000);
  begin
    if PCS.PC_OPTION_FUNCTIONS.IsOptionActive('MAIL_SENDER') = 1then

      if iMainTable = 'ACR_SOCIAL_BREAKDOWN' then
        --Préparation et formatage des données du mail
        ACR_LIB_SOCIAL_BREAKDOWN.PrepareEmailing(iCurrentId,
                                                 lcXML,
                                                 lvFilePath,
                                                 lvTo,
                                                 lvSubject,
                                                 lvBody);
      end if;

      if DBMS_LOB.getlength(lcXML) = 0 then
        oErrorMsg  := 'XML empty';
        return;
      end if;
      -- Creates e-mail and stores it in default e-mail object
      lvErrorCodes  :=
        EML_SENDER.CreateMail(aErrorMessages    => oErrorMsg
                            , aSender           => lvTo
                            , aReplyTo          => lvTo
                            , aRecipients       => lvTo
                            , aCcRecipients     => ''
                            , aBccRecipients    => ''
                            , aNotification     => 0
                            , aPriority         => EML_SENDER.cPRIOTITY_NORMAL_LEVEL
                            , aCustomHeaders    => 'X-Mailer: PCS mailer'
                            , aSubject          => lvSubject
                            , aBodyPlain        => lvBody
                            , aSendMode         => EML_SENDER.cSENDMODE_IMMEDIATE_FORCED
                            , aDateToSend       => sysdate
                            , aTimeZoneOffset   => sessiontimezone
                            , aBackupMode       => EML_SENDER.cBACKUP_DATABASE
                             );

      if oErrorMsg <> '' then
        return;
      end if;

      if not lcbUSE_COMPRESSED then
        -- Adds an ascii attachment to default e-mail object
        lvErrorCodes  :=
          EML_SENDER.AddClobAttachment(aErrorMessages   => oErrorMsg
                                     , aFileName        => lvFilePath
                                     , aContent         => lcXML
                                      );
      else
        DBMS_LOB.createtemporary(lob_loc => lTempBLOB, cache => true);
        lnDest_offset  := 1;
        lnSrc_offset   := 1;
        lnLang_ctx     := DBMS_LOB.default_lang_ctx;
        DBMS_LOB.converttoblob(lTempBLOB
                             , lcXML
                             , DBMS_LOB.getlength(lcXML)
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
          EML_SENDER.AddBlobAttachment(aErrorMessages   => oErrorMsg
                                     , aFileName        => lvFilePath || '.lzh'
                                     , aContent         => lTempCompBLOB
                                      );
        DBMS_LOB.freetemporary(lTempCompBLOB);
        DBMS_LOB.freetemporary(lTempBLOB);
      end if;

      if oErrorMsg <> '' then
        return;
      end if;

      -- Sends the e-mail contained in default e-mail object (in fact stores it in a queue)
      lvErrorCodes  := EML_SENDER.Send(aErrorMessages => oErrorMsg, aMailID => lnMailID);

      if oErrorMsg <> '' then
        return;
      end if;
    else
      oErrorMsg := PCS.PC_FUNCTIONS.TranslateWord('-20100_ACR_GOV_EXPORT'); --Option" EML_SENDER" non activée
    end if;
  end SendMail;

end ACR_PRC_GOV_EXPORT;
