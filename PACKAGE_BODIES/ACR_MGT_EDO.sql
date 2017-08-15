--------------------------------------------------------
--  DDL for Package Body ACR_MGT_EDO
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACR_MGT_EDO" 
is
  /**
  * Description :
  *   Suppression d'une interaction d'investissement (IN)
  */
  procedure DeleteInteractionIN(iACR_EDO_IN_ID in ACR_EDO_IN.ACR_EDO_IN_ID%type)
  is
  begin
    ACR_PRC_EDO.DeleteInteractionIN(iACR_EDO_IN_ID);
  end DeleteInteractionIN;

  /**
  * Description :
  *   Suppression d'une interaction de fonctionnement (WO)
  */
  procedure DeleteInteractionWO(iACR_EDO_WO_ID in ACR_EDO_WO.ACR_EDO_WO_ID%type)
  is
  begin
    ACR_PRC_EDO.DeleteInteractionWO(iACR_EDO_WO_ID);
  end DeleteInteractionWO;

  /**
  * Description :
  *   Ajout d'une interaction de fonctionnement (WO)
  */
  procedure InsertInteractionWO(iEDW_TASK in ACR_EDO_WO.EDW_TASK%type, iACR_EDO_ID in ACR_EDO.ACR_EDO_ID%type)
  is
  begin
    ACR_PRC_EDO.InsertInteractionWO(iEDW_TASK, iACR_EDO_ID);
  end InsertInteractionWO;

  /**
  * Description :
  *   Ajout d'une interaction d'investissement (IN)
  */
  procedure InsertInteractionIN(iEDI_TASK in ACR_EDO_IN.EDI_TASK%type, iACR_EDO_ID in ACR_EDO.ACR_EDO_ID%type)
  is
  begin
    ACR_PRC_EDO.InsertInteractionIN(iEDI_TASK, iACR_EDO_ID);
  end InsertInteractionIN;

  /**
  * Description :
  *   Contrôle des règles selon l'OFS (BeforePost)
  */
  procedure CheckDatasBeforeCommit(
    iACR_EDO_ID in     ACR_EDO.ACR_EDO_ID%type
  , oErrorCode  out    integer
  , oErrorMsg   out    varchar2
  )
  is
  begin
    ACR_PRC_EDO.VerifyDatas(iACR_EDO_ID, oErrorCode, oErrorMsg);
  end CheckDatasBeforeCommit;

  /**
  * Description :
  *   Exportation des données selon scenario défini par l'OFS
  */
  procedure BuildXMLDocument(
    iACR_EDO_ID   in     ACR_EDO.ACR_EDO_ID%type
  , oEDO_XML_PATH out    ACR_EDO.EDO_XML%type
  , oErrorCode    out    integer
  , oErrorMsg     out    varchar2
  )
  is
    lxXml xmltype;
  begin
    /*
    Scenario
      1. Vérification des données
      2. Validation du document XML par le fichier de définition du schéma XSD1.
      3. Création du fichier XML (voir use-case „Créer le fichier XML“)
    */-- Vérification des données
    ACR_PRC_EDO.VerifyDatas(iACR_EDO_ID, oErrorCode, oErrorMsg);

    if oErrorCode <> 0 then
      return;
    end if;

    -- Génération du document et le retourne (oEDO_XML_PATH)
    ACR_PRC_EDO_XML.GenerateXML(iACR_EDO_ID, oEDO_XML_PATH);
  end BuildXMLDocument;

  /**
  * Description :
  *   Copie du dernier record historié
  */
  procedure DuplicateLastRecord(oACR_EDO out ACR_EDO.ACR_EDO_ID%type)
  is
  begin
    ACR_LIB_EDO.DuplicateLastRecord(oACR_EDO);
  end DuplicateLastRecord;

  /**
  * Description :
  *   Mise à jour du statut dans la table
  */
  procedure ChangeStatus(iACR_EDO_ID in ACR_EDO.ACR_EDO_ID%type, iC_EDO_STATUS in ACR_EDO.C_EDO_STATUS%type)
  is
  begin
    ACR_LIB_EDO.ChangeStatus(iACR_EDO_ID, iC_EDO_STATUS);
  end ChangeStatus;

  /**
  * Description :
  *   Retourne le document XSD de validation
  */
  function GetXsdSchema
    return ACR_EDO.EDO_XML%type
  is
  begin
    return ACR_PRC_EDO_XML.GetXsdSchema;
  end GetXsdSchema;

  /**
  * Description :
  *   construction du nom de fichier
  */
  function BuildFileName(iACR_EDO_ID in ACR_EDO.ACR_EDO_ID%type)
    return varchar2
  is
  begin
    return ACR_PRC_EDO.BuildFileName(iACR_EDO_ID);
  end BuildFileName;

  /**
  * Description :
  *   Sauvegarde du nom de fichier
  */
  procedure SaveFilePath(iACR_EDO_ID in ACR_EDO.ACR_EDO_ID%type, iEDO_XML_PATH in ACR_EDO.EDO_XML_PATH%type)
  is
  begin
    ACR_LIB_EDO.SaveFilePath(iACR_EDO_ID, iEDO_XML_PATH);
  end SaveFilePath;

  /**
  * Description :
  *   Sauvegarde du document XML
  */
  procedure SaveXMLDocument(iACR_EDO_ID in ACR_EDO.ACR_EDO_ID%type, iEDO_XML in ACR_EDO.EDO_XML%type)
  is
  begin
    ACR_LIB_EDO.SaveXMLDocument(iACR_EDO_ID, iEDO_XML);
  end SaveXMLDocument;

  /**
  * Description :
  *   Retourne 1 si l'envoi de l'EDO par email est disponible, sinon 0
  */
  function MailAvailable
    return integer
  is
  begin
    return ACR_PRC_EDO.MailAvailable;
  end MailAvailable;

  /**
  * Description :
  *   si l'envoi de l'EDO par email à réussi, sinon le message d'erreur du serveur
  */
  procedure SendMail(
    iACR_EDO_ID in     ACR_EDO.ACR_EDO_ID%type
  , iSubject    in     varchar2
  , iBody       in     varchar2
  , oMsg        out    varchar2
  )
  is
  begin
    ACR_PRC_EDO.SendMail(iACR_EDO_ID, iSubject, iBody, oMsg);
  end SendMail;
end ACR_MGT_EDO;
