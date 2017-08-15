--------------------------------------------------------
--  DDL for Package Body ACR_PRC_FIN_EXPORT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACR_PRC_FIN_EXPORT" 
is
  /**
  * Description
  *   Flux de création d'un nouvel enregistrement
  */
  procedure CreateNewRecord(iMainTable in varchar2, oCurrentId out number)
  is
    lnRefId number;
  begin
    if iMainTable = 'ACR_GL_EXPORT' then
      --Copie de l'enregistrement référence
      ACR_PRC_GL_EXPORT.DuplicateActiveRecord(lnRefId, oCurrentId);
      --Statut de l'enregistrement référence mis à 'Historié'
      ACR_PRC_GL_EXPORT.SetStatusState(lnRefId, '2');
      --Statut de l'enregistrement nouvelement créé mis à actif
      ACR_PRC_GL_EXPORT.SetStatusState(oCurrentId, '1');
    end if;
  end;

  /**
  * Description
  *   Création du xml data
  */
  procedure PrepareXml(iMainTable in varchar2, iCurrentId in number, oErrorMsg out varchar2)
  is
    lvErrorCode varchar2(500);
    lXml        clob;
  begin
    if iCurrentId = 0 then
      return;
    end if;

    if iMainTable = 'ACR_GL_EXPORT' then
      if not(ACR_LIB_GL_EXPORT.CheckGranularity(iCurrentId) ) then
        lvErrorCode  := 'Incorrect XML file granularity';
        return;
      end if;

      if lvErrorCode is null then
        --Suppression des enregistrement relatifs aux fichiers XML à exporter
        ACR_PRC_GL_EXPORT.DeleteGLExportFile(iCurrentId);
        --Génération des enregistrement relatifs aux fichiers XML à exporter
        ACR_MGT_GL_EXPORT.GenerateGLExportFiles(iCurrentId);
        --Génération des données XML
        ACR_MGT_GL_EXPORT.GenerateXmlData(iCurrentId);
      end if;
    end if;

    if lvErrorCode is not null then
      oErrorMsg  :=(PCS.PC_FUNCTIONS.TranslateWord(lvErrorCode) );
    end if;
  end PrepareXml;

  procedure SendMail(
    iMainTable in     varchar2
  , iCurrentId in     number
  , oErrorMsg  out    varchar2
  , iCSID      in     number default DBMS_LOB.default_csid
  , iFileDescr in     clob default null
  )
  is
    lcbUSE_COMPRESSED constant boolean        := true;
    lTempBLOB                  blob;
    lTempCompBLOB              blob;
    lnMailID                   number;
    lnDest_offset              integer;
    lnSrc_offset               integer;
    lnLang_ctx                 integer;
    lnWarning                  varchar2(1000);
    lvTo                       varchar2(255);
    lvErrorCodes               varchar2(4000);
    lvSubject                  varchar2(4000);
    lvBody                     varchar2(4000);
    lvErrorMsg                 varchar2(4000);
  begin
    if PCS.PC_OPTION_FUNCTIONS.IsOptionActive('MAIL_SENDER') = 1 then
      if iMainTable = 'ACR_GL_EXPORT' then
        --Préparation et formatage des données du mail
        ACR_LIB_GL_EXPORT.PrepareEmailing(iCurrentId, lvTo, lvSubject, lvBody);
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

      -- Adds an ascii attachment to default e-mail object
      for tplGlExportFiles in (select ACR_LIB_GL_EXPORT.BuildFileName(ACR_GL_EXPORT_FILE_ID) FileName
                                    , AGF_XML
                                 from ACR_GL_EXPORT_FILE
                                where ACR_GL_EXPORT_ID = iCurrentId
                                  and AGF_XML is not null) loop
        DBMS_LOB.createtemporary(lob_loc => lTempBLOB, cache => true);
        lnDest_offset  := 1;
        lnSrc_offset   := 1;
        lnLang_ctx     := DBMS_LOB.default_lang_ctx;
        DBMS_LOB.converttoblob(lTempBLOB
                             , ACR_LIB_GL_EXPORT_FILE.ReplaceXmlEncoding(tplGlExportFiles.AGF_XML, iCSID)
                             , DBMS_LOB.LOBMAXSIZE
                             , lnDest_offset
                             , lnSrc_offset
                             , iCSID
                             , lnLang_ctx
                             , lnWarning
                              );
        if lcbUSE_COMPRESSED then
          DBMS_LOB.createtemporary(lob_loc => lTempCompBLOB, cache => true);
          -- Compress the data
          UTL_COMPRESS.lz_compress(src => lTempBLOB, dst => lTempCompBLOB);
          -- Adds a binary attachment to default e-mail object
          lvErrorCodes  :=
                         EML_SENDER.AddBlobAttachment(aErrorMessages   => oErrorMsg, aFileName => tplGlExportFiles.FileName || '.lzh'
                                                    , aContent         => lTempCompBLOB);
          DBMS_LOB.freetemporary(lTempCompBLOB);
        else
          -- Adds a binary attachment to default e-mail object
          lvErrorCodes  := EML_SENDER.AddBlobAttachment(aErrorMessages => oErrorMsg, aFileName => tplGlExportFiles.FileName, aContent => lTempBLOB);
        end if;

        DBMS_LOB.freetemporary(lTempBLOB);
      end loop;

      -- Adds the description file to the e-mail object
      if iFileDescr is not null then
        DBMS_LOB.createtemporary(lob_loc => lTempBLOB, cache => true);
        lnDest_offset  := 1;
        lnSrc_offset   := 1;
        lnLang_ctx     := DBMS_LOB.default_lang_ctx;
        DBMS_LOB.converttoblob(lTempBLOB, iFileDescr, DBMS_LOB.LOBMAXSIZE, lnDest_offset, lnSrc_offset, iCSID, lnLang_ctx, lnWarning);
        lvErrorCodes   :=
             EML_SENDER.AddBlobAttachment(aErrorMessages   => oErrorMsg, aFileName => PCS.PC_CONFIG.GetConfig('ACR_GL_EXPORT_DESCR_FILE')
                                        , aContent         => lTempBLOB);
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
      oErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('-20100_ACR_GL_EXPORT');   --Option" EML_SENDER" non activée
    end if;
  end SendMail;
end ACR_PRC_FIN_EXPORT;
