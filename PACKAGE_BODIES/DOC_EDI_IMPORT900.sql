--------------------------------------------------------
--  DDL for Package Body DOC_EDI_IMPORT900
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_EDI_IMPORT900" 
as
-- *************************************************
-- *****             GENERAL                   *****
-- *************************************************

  -- Ajout dans le log de traitement
  procedure WriteLog(aLine varchar2, aType_1 integer)
  is
  begin
    DOC_EDI_IMPORT.WRITELOG(aLine, aType_1);
  end;

  -- Affichage d'un message d'information dans le log
  procedure PutMessage(aMessage varchar2)
  is
  begin
    WRITELOG(' ', 10);
    WRITELOG(aMessage, 10);
    WRITELOG(' ', 10);
  end;

  -- Message d'erreur
  -- Attribution du message à la ligne en cours.
  -- Ajout de la position si existant
  -- Inscription numéro de ligne, ligne et message dans le log
  procedure PutError(aMessage varchar2)
  is
  begin
    WRITELOG('*PutError', 0);

    -- Erreur sur ligne effective
    if LineRec.DOC_EDI_IMPORT_JOB_DATA_ID is not null then
      -- Attribution pour mise à jour
      LineRec.DID_ERROR_TEXT  := aMessage;

      -- Si position de l'erreur
      if LineRec.NEW_ROW_POSITION is not null then
        LineRec.DID_ERROR_TEXT  := 'Pos' || ' : ' || LineRec.NEW_ROW_POSITION || ' ' || LineRec.DID_ERROR_TEXT;
      end if;

      --
      WRITELOG(' ', 10);
      WRITELOG(PCS.PC_FUNCTIONS.TranslateWord('Ligne') || ' : ' || to_char(LineRec.DID_LINE_NUMBER, '9999'), 90);
      WRITELOG(LineRec.DID_VALUE, 90);
      WRITELOG(LineRec.DID_ERROR_TEXT, 99);
      WRITELOG(' ', 10);
    -- Erreur sans ligne effective (par exemple : ligne devant existant mais manquante)
    -- Seul le message est important, car il n'existe ni ligne ni position de référence
    else
      WRITELOG(' ', 10);
      WRITELOG(aMessage, 99);
      WRITELOG(' ', 10);
    end if;
  end;

  -- Message d'avertissement
  -- Attribution du message à la ligne en cours.
  -- Ajout de la position si existant
  -- Inscription numéro de ligne, ligne et message dans le log
  procedure PutWarning(aMessage varchar2)
  is
  begin
    WRITELOG('*PutWarning', 0);

    -- Avertissement sur ligne effective
    if LineRec.DOC_EDI_IMPORT_JOB_DATA_ID is not null then
      -- Attribution pour mise à jour
      LineRec.DID_ERROR_TEXT  := aMessage;

      -- Si position de l'avertissement
      if LineRec.NEW_ROW_POSITION is not null then
        LineRec.DID_ERROR_TEXT  := 'Pos' || ' : ' || LineRec.NEW_ROW_POSITION || ' ' || LineRec.DID_ERROR_TEXT;
      end if;

      --
      WRITELOG(' ', 10);
      WRITELOG(PCS.PC_FUNCTIONS.TranslateWord('Ligne') || ' : ' || to_char(LineRec.DID_LINE_NUMBER, '9999'), 50);
      WRITELOG(LineRec.DID_VALUE, 50);
      WRITELOG(LineRec.DID_ERROR_TEXT, 59);
      WRITELOG(' ', 10);
    -- avertissement sans ligne effective.
    -- Seul le message est important, car ni ligne ni position de référence
    else
      WRITELOG(' ', 10);
      WRITELOG(aMessage, 59);
      WRITELOG(' ', 10);
    end if;
  end;

  -- Fonction sumulant une error - Pour test
  function RAISEERROR
    return boolean
  is
  begin
    RAISE_APPLICATION_ERROR(-20001, 'ERREUR PROVOQUEE POUR TEST');
    return false;
  end;

  -- Initialisation de la position de colonne pour la ligne en cours.
  -- Ce numéro est utilisé en cas d'erreur.
  procedure PutRowPosition(aPos varchar2)
  is
  begin
    LineRec.NEW_ROW_POSITION  := aPos;
  end;

  -- Initialisation des variables système
  procedure InitVarSys
  is
  begin
    -- IMPORTANT : Pas de WRITELOG car JOB_ID n'est pas initialisé
    SysRec.JOB_ID        := null;
    SysRec.RETURN_VALUE  := null;
  end;

  -- Init des variables générales pour toutes les lignes d'un job
  procedure InitVarJob
  is
  begin
    WRITELOG('*InitVarJob', 0);
    -- Pas de document ok
    JobRec.NEW_DOC_OK              := false;
    -- Pas de document en erreur
    JobRec.NEW_DOC_NOT_OK          := false;
    ---- pac_third_id
    JobRec.INTERM_CRE_EAN_NUMBER   := null;
    JobRec.ACS_VAT_DET_ACCOUNT_ID  := null;
    JobRec.DIC_TYPE_SUBMISSION_ID  := null;
    --
    JobRec.PAC_THIRD_ID            := null;
    ---- Code EAN recu
    JobRec.INTERM_RECEIVED_EAN     := null;
  end;

  -- Init des variables générales pour le traiement d'un document d'un job
  procedure InitVarDoc
  is
  begin
    WRITELOG('*InitVarDoc', 0);
    -- Id interface non initialisé
    DocumentRec.DOC_INTERFACE_ID            := null;
    -- Id de l'entête non initialisé
    DocumentRec.DOC_EDI_IMPORT_JOB_DATA_ID  := null;
    -- Document un ordre
    DocumentRec.NEW_DOC_STOP                := false;
    -- Numéro attribué
    DocumentRec.NEW_DOI_NUMBER              := null;

    -- Détermine l'id de l'interface
    select INIT_ID_SEQ.nextval
      into DocumentRec.DOC_INTERFACE_ID
      from dual;
  end;

  -- Init des variables pour la ligne data en cours
  procedure InitVarLine
  is
  begin
    WRITELOG('*InitVarLine', 0);
    -- Id de la ligne en cours non init.
    LineRec.DOC_EDI_IMPORT_JOB_DATA_ID  := null;
    -- Status par défaut de la ligne OK
    LineRec.C_EDI_JOB_DATA_STATUS       := 'OK';
    -- Pas d'erreur
    LineRec.DID_ERROR_TEXT              := null;
    -- pas de numéro de ligne
    LineRec.DID_LINE_NUMBER             := 0;
    -- Pas de ligne
    LineRec.DID_VALUE                   := null;
    -- Numéro de colonne
    PutRowPosition(null);
  end;

  -- Init des champs de l'entete du document (pour DOC_INTERFACE)
  procedure InitFieldsDoc
  is
  begin
    WRITELOG('*InitFieldsDoc', 0);
    -- document
    HeaderDocu.INTERM_DOI_PARTNER_DATE    := null;
    HeaderDocu.DOI_PARTNER_DATE           := null;
    --
    HeaderDocu.INTERM_DOI_VALUE_DATE      := null;
    HeaderDocu.DOI_VALUE_DATE             := null;
    --
    HeaderDocu.INTERM_DOI_DELIVERY_DATE   := null;
    HeaderDocu.DOI_DELIVERY_DATE          := null;
    --
    HeaderDocu.INTERM_DOI_RCO_NUMBER      := null;
    HeaderDocu.DOI_RCO_NUMBER             := null;
    HeaderDocu.DOI_RCO_TITLE              := null;
    HeaderDocu.DOC_RECORD_ID              := null;
    --
    HeaderDocu.PAC_SENDING_CONDITION_ID   := null;
    HeaderDocu.DOI_SEN_KEY                := null;
    --
    HeaderDocu.DOI_PARTNER_REFERENCE      := null;
    --
    HeaderDocu.DOI_CURRENCY               := null;
    HeaderDocu.ACS_FINANCIAL_CURRENCY_ID  := null;
    --
    HeaderDocu.DOI_LANID                  := null;
    HeaderDocu.PC_LANG_ID                 := null;
    --
    HeaderDocu.DOI_PCO_DESCR              := null;
    HeaderDocu.PAC_PAYMENT_CONDITION_ID   := null;
    -- document intermédiaire
    ---- id du gabarit
    HeaderDocu.INTERM_DOCU_TYPE           := null;
    HeaderDocu.DOC_GAUGE_ID               := null;
    -- adresses
    HeaderDocu.PC_CNTRY_ID                := null;
    HeaderDocu.PC__PC_CNTRY_ID            := null;
    HeaderDocu.PC_2_PC_CNTRY_ID           := null;
    --
    HeaderDocu.DOI_CNTID1                 := null;
    HeaderDocu.DOI_CNTID2                 := null;
    HeaderDocu.DOI_CNTID3                 := null;
    HeaderDocu.DOI_ZIPCODE1               := null;
    HeaderDocu.DOI_ZIPCODE2               := null;
    HeaderDocu.DOI_ZIPCODE3               := null;
    HeaderDocu.DOI_TOWN1                  := null;
    HeaderDocu.DOI_TOWN2                  := null;
    HeaderDocu.DOI_TOWN3                  := null;
    HeaderDocu.DOI_ADDRESS1               := null;
    HeaderDocu.DOI_ADDRESS2               := null;
    HeaderDocu.DOI_ADDRESS3               := null;
    HeaderDocu.DOI_STATE1                 := null;
    HeaderDocu.DOI_STATE2                 := null;
    HeaderDocu.DOI_STATE3                 := null;
  end;

  -- Init des champs du détail
  procedure InitFieldsDetail
  is
  begin
    WRITELOG('*InitFieldsDetail', 0);
    --
    DetailDocu.C_GAUGE_TYPE_POS           := null;
    --
    DetailDocu.INTERM_DOP_POS_NUMBER      := null;
    DetailDocu.DOP_POS_NUMBER             := null;
    --
    DetailDocu.DOP_MAJOR_REFERENCE        := null;
    DetailDocu.GCO_GOOD_ID                := null;
    --
    DetailDocu.INTERM_DOP_QTY             := null;
    DetailDocu.DOP_QTY                    := null;
    --
    DetailDocu.INTERM_DOP_QTY_VALUE       := null;
    DetailDocu.DOP_QTY_VALUE              := null;
    --
    DetailDocu.INTERM_DOP_RCO_NUMBER      := null;
    DetailDocu.DOP_RCO_NUMBER             := null;
    DetailDocu.DOP_RCO_TITLE              := null;
    DetailDocu.DOC_RECORD_ID              := null;
    --
    DetailDocu.INTERM_DOP_NET_VALUE_EXCL  := null;
    DetailDocu.DOP_NET_VALUE_EXCL         := null;
    --
    DetailDocu.INTERM_DOP_NET_VALUE_INCL  := null;
    DetailDocu.DOP_NET_VALUE_INCL         := null;
    --
    DetailDocu.INTERM_DOP_NET_TARIFF      := null;
    DetailDocu.DOP_NET_TARIFF             := null;
    --
    DetailDocu.DOP_SHORT_DESCRIPTION      := null;
    --
    DetailDocu.DOP_LONG_DESCRIPTION       := null;
    DetailDocu.DOP_FREE_DESCRIPTION       := null;
    DetailDocu.DOP_BODY_TEXT              := null;
    --
    -- Copie du gauge du document sur le détail
    DetailDocu.DOC_GAUGE_ID               := HeaderDocu.DOC_GAUGE_ID;
  end;

  -- Converti l'état boolean en integer
  -- True  -> 1
  -- False -> 0
  function ConvertState(paState boolean)
    return integer
  is
  begin
    if paState then
      return 1;
    else
      return 0;
    end if;
  end;

  -- Mise à jour du statut d'une ligne JOB DATA
  -- 0 ERREUR
  -- 1 OK
  -- 2 WARNING
  -- 3 UNDEF
  procedure PutStatus(paStatus integer)
  is
  begin
    WRITELOG('*PutStatus', 0);

    --
    -- En ordre
    if paStatus = 1 then
      LineRec.C_EDI_JOB_DATA_STATUS  := 'OK';
    -- Erreur
    elsif paStatus = 0 then
      LineRec.C_EDI_JOB_DATA_STATUS  := 'ERROR';
      -- Erreur -> suppression des ajout dans l'interface
      DocumentRec.NEW_DOC_STOP       := true;
    -- Avertissement
    elsif paStatus = 2 then
      LineRec.C_EDI_JOB_DATA_STATUS  := 'WARNING';
    -- Ligne non traitée
    else
      LineRec.C_EDI_JOB_DATA_STATUS  := 'UNDEF';
    end if;

    --
    -- Mise du status et de message d'erreur du job data en cours
    -- Le message d'erreur provient en général du put_error ou autres.
    update DOC_EDI_IMPORT_JOB_DATA
       set C_EDI_JOB_DATA_STATUS = LineRec.C_EDI_JOB_DATA_STATUS
         , DID_ERROR_TEXT = LineRec.DID_ERROR_TEXT
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_EDI_IMPORT_JOB_DATA_ID = LineRec.DOC_EDI_IMPORT_JOB_DATA_ID;
  end;

  -- Insertion des données dans l'interface document
  procedure InsertInterface
  is
    DocGaugeId DOC_GAUGE.DOC_GAUGE_ID%type;
  begin
    begin
      if not DocumentRec.NEW_DOC_STOP then
        --
        WRITELOG('*InsertInterface', 0);
        -- Id du gabarit en fonction de la configuration
        DocGaugeId                  := DOC_INTERFACE_FCT.GetGaugeId(PCS.PC_CONFIG.GETCONFIG('DOC_EDI_CONFIG_GAUGE') );
        -- Mise à jour du dernier n° utilisé dans la numérotation*/
        DOC_INTERFACE_FCT.SetNewInterfaceNumber(DocGaugeId);
        -- Attribution numérotation
        DocumentRec.NEW_DOI_NUMBER  := DOC_INTERFACE_FCT.GetNewInterfaceNumber(DocGaugeId);

        -- Insertion
        insert into DOC_INTERFACE
                    (DOC_INTERFACE_ID
                   , C_DOC_INTERFACE_ORIGIN
                   , C_DOI_INTERFACE_STATUS
                   , DOI_PROTECTED
                   , DOI_NUMBER
                   -- data
        ,            DOI_PARTNER_NUMBER
                   , DOI_PARTNER_DATE
                   , DOI_VALUE_DATE
                   , DOI_DELIVERY_DATE
                   , DOI_RCO_NUMBER
                   , DOI_RCO_TITLE
                   , DOI_SEN_KEY
                   , DOI_PARTNER_REFERENCE
                   , DOI_CURRENCY
                   , DOI_LANID
                   , DOI_PCO_DESCR
                   , DOI_DOCUMENT_DATE
                   -- adresse
        ,            PC_CNTRY_ID
                   , PC__PC_CNTRY_ID
                   , PC_2_PC_CNTRY_ID
                   , DOI_CNTID1
                   , DOI_CNTID2
                   , DOI_CNTID3
                   , DOI_ZIPCODE1
                   , DOI_ZIPCODE2
                   , DOI_ZIPCODE3
                   , DOI_TOWN1
                   , DOI_TOWN2
                   , DOI_TOWN3
                   , DOI_ADDRESS1
                   , DOI_ADDRESS2
                   , DOI_ADDRESS3
                   , DOI_STATE1
                   , DOI_STATE2
                   , DOI_STATE3
                   -- data Id
        ,            PAC_THIRD_ID
                   , ACS_VAT_DET_ACCOUNT_ID
                   , DIC_TYPE_SUBMISSION_ID
                   , DOC_GAUGE_ID
                   , PC_LANG_ID
                   , DOC_RECORD_ID
                   , ACS_FINANCIAL_CURRENCY_ID
                   , PAC_SENDING_CONDITION_ID
                   , PAC_PAYMENT_CONDITION_ID
                   -- Système
        ,            PC_USER_ID
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (DocumentRec.DOC_INTERFACE_ID
                   , '201'
                   , '01'
                   , 0
                   , DocumentRec.NEW_DOI_NUMBER
                   -- data
        ,            HeaderDocu.DOI_PARTNER_NUMBER
                   , HeaderDocu.DOI_PARTNER_DATE
                   , HeaderDocu.DOI_VALUE_DATE
                   , HeaderDocu.DOI_DELIVERY_DATE
                   , HeaderDocu.DOI_RCO_NUMBER
                   , HeaderDocu.DOI_RCO_TITLE
                   , HeaderDocu.DOI_SEN_KEY
                   , HeaderDocu.DOI_PARTNER_REFERENCE
                   , HeaderDocu.DOI_CURRENCY
                   , HeaderDocu.DOI_LANID
                   , HeaderDocu.DOI_PCO_DESCR
                   , sysdate
                   -- adresse
        ,            HeaderDocu.PC_CNTRY_ID
                   , HeaderDocu.PC__PC_CNTRY_ID
                   , HeaderDocu.PC_2_PC_CNTRY_ID
                   , HeaderDocu.DOI_CNTID1
                   , HeaderDocu.DOI_CNTID2
                   , HeaderDocu.DOI_CNTID3
                   , HeaderDocu.DOI_ZIPCODE1
                   , HeaderDocu.DOI_ZIPCODE2
                   , HeaderDocu.DOI_ZIPCODE3
                   , HeaderDocu.DOI_TOWN1
                   , HeaderDocu.DOI_TOWN2
                   , HeaderDocu.DOI_TOWN3
                   , HeaderDocu.DOI_ADDRESS1
                   , HeaderDocu.DOI_ADDRESS2
                   , HeaderDocu.DOI_ADDRESS3
                   , HeaderDocu.DOI_STATE1
                   , HeaderDocu.DOI_STATE2
                   , HeaderDocu.DOI_STATE3
                   -- data ID
        ,            JobRec.PAC_THIRD_ID
                   , JobRec.ACS_VAT_DET_ACCOUNT_ID
                   , JobRec.DIC_TYPE_SUBMISSION_ID
                   , HeaderDocu.DOC_GAUGE_ID
                   , HeaderDocu.PC_LANG_ID
                   , HeaderDocu.DOC_RECORD_ID
                   , HeaderDocu.ACS_FINANCIAL_CURRENCY_ID
                   , HeaderDocu.PAC_SENDING_CONDITION_ID
                   , HeaderDocu.PAC_PAYMENT_CONDITION_ID
                   -- Système
        ,            PCS.PC_I_LIB_SESSION.GetUserId
                   , sysdate
                   , pcs.PC_I_LIB_SESSION.GetUserIni
                    );
      end if;
    --
    exception
      when others then
        RAISE_APPLICATION_ERROR(-20001, sqlerrm);
    end;
  end;

  -- Insertion des données dans l'interface position
  procedure InsertInterfacePosition
  is
    newId number(12);
  begin
    begin
      if not DocumentRec.NEW_DOC_STOP then
        --
        WRITELOG('*InsertInterfacePosition', 0);

        -- Détermine l'id de l'interface position
        select INIT_ID_SEQ.nextval
          into newId
          from dual;

        -- Insert dans l'interface position
        insert into DOC_INTERFACE_POSITION
                    (DOC_INTERFACE_POSITION_ID
                   , DOC_INTERFACE_ID
                   , C_DOP_INTERFACE_STATUS
                   -- data
        ,            C_GAUGE_TYPE_POS
                   , DOP_POS_NUMBER
                   , DOP_MAJOR_REFERENCE
                   , DOP_QTY
                   , DOP_QTY_VALUE
                   , DOP_RCO_NUMBER
                   , DOP_RCO_TITLE
                   , DOP_NET_VALUE_EXCL
                   , DOP_NET_VALUE_INCL
                   , DOP_NET_TARIFF
                   , DOP_SHORT_DESCRIPTION
                   -- Text
        ,            DOP_BODY_TEXT
                   , DOP_FREE_DESCRIPTION
                   , DOP_LONG_DESCRIPTION
                   -- data id
        ,            GCO_GOOD_ID
                   , DOC_GAUGE_ID
                   , DOC_RECORD_ID
                   -- système
        ,            A_DATECRE
                   , A_IDCRE
                    )
             values (newId
                   , DocumentRec.DOC_INTERFACE_ID
                   , '01'
                   -- data
        ,            DetailDocu.C_GAUGE_TYPE_POS
                   , DetailDocu.DOP_POS_NUMBER
                   , DetailDocu.DOP_MAJOR_REFERENCE
                   , DetailDocu.DOP_QTY
                   , DetailDocu.DOP_QTY_VALUE
                   , DetailDocu.DOP_RCO_NUMBER
                   , DetailDocu.DOP_RCO_TITLE
                   , DetailDocu.DOP_NET_VALUE_EXCL
                   , DetailDocu.DOP_NET_VALUE_INCL
                   , nvl(DetailDocu.DOP_NET_TARIFF, 0)
                   , DetailDocu.DOP_SHORT_DESCRIPTION
                   -- Text
        ,            DetailDocu.DOP_BODY_TEXT
                   , DetailDocu.DOP_FREE_DESCRIPTION
                   , DetailDocu.DOP_LONG_DESCRIPTION
                   -- data id
        ,            DetailDocu.GCO_GOOD_ID
                   , DetailDocu.DOC_GAUGE_ID
                   , DetailDocu.DOC_RECORD_ID
                   -- système
        ,            sysdate
                   , pcs.PC_I_LIB_SESSION.GetUserIni
                    );
      end if;
    --
    exception
      when others then
        RAISE_APPLICATION_ERROR(-20001, sqlerrm);
    end;
  end;

  -- Suppression de toutes les enregistrements ajoutés dans l'interface et interface position
  -- dans le cas ou une erreur est survenue.
  procedure DeleteInterfaceRecords
  is
  begin
    -- Test existence ID
    if DocumentRec.DOC_INTERFACE_ID is not null then
      WRITELOG('*DeleteInterfaceRecords', 0);

      -- Suppression des interfaces positions
      delete from DOC_INTERFACE_POSITION
            where DOC_INTERFACE_ID = DocumentRec.DOC_INTERFACE_ID;

      -- Suppression de l'interface
      delete from DOC_INTERFACE
            where DOC_INTERFACE_ID = DocumentRec.DOC_INTERFACE_ID;
    end if;
  end;

  -- Mise à jour du status des enregistrements interfaces et interface position afin de prendre
  -- en compte les enregistrements au prochain traitement.
  procedure UpdateInterfaceRecords
  is
  begin
    WRITELOG('*UpdateInterfaceRecords', 0);

    -- Mise à jour des positions
    update DOC_INTERFACE_POSITION
       set C_DOP_INTERFACE_STATUS = '02'
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_INTERFACE_ID = DocumentRec.DOC_INTERFACE_ID;

    -- Mise à jour de l'interface
    update DOC_INTERFACE
       set C_DOI_INTERFACE_STATUS = '02'
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_INTERFACE_ID = DocumentRec.DOC_INTERFACE_ID;
  end;

  -- Mise à jour du status l'en-tête du document
  procedure UpdateDocHeaderRecord
  is
  begin
    WRITELOG('*UpdateDocHeaderRecord', 0);

    update DOC_EDI_IMPORT_JOB_DATA
       set C_EDI_JOB_DATA_STATUS = 'GENE'
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_EDI_IMPORT_JOB_DATA_ID = DocumentRec.DOC_EDI_IMPORT_JOB_DATA_ID;
  end;

  -- Détermine le valeur de retour en fonction des états ok et not_ok
  -- 0 Pas de document traité
  -- 1 Tous les documents généré
  -- 2 Documents ok + Documents en erreur
  -- 3 Tous les document en error
  function ReturnValue
    return integer
  is
  begin
    WRITELOG('*ReturnValue', 0);

    if JobRec.NEW_DOC_OK then
      if JobRec.NEW_DOC_NOT_OK then
        -- Partiellement ok
        return 2;
      else
        -- Tous les documents ok
        return 1;
      end if;
    else
      if JobRec.NEW_DOC_NOT_OK then
        -- Tous les documents en erreur
        return 3;
      else
        -- Aucun document détecté
        return 0;
      end if;
    end if;
  end;

  -- Lecture du code EAN du client et comparaison avec celui du fichier import
  function CompareEanCustomer(aNumber varchar2)
    return boolean
  is
    CreCustomerNumber varchar2(30);
    Ean1              varchar2(30);
    Ean2              varchar2(30);
  begin
    WRITELOG('*CompareEanCustomer', 0);
    -- Code EAN provenant des paramètres.
    CreCustomerNumber  := DOC_EDI_FUNCTION.GetParamValue('EAN_NUMBER');

    -- Lecture de son propre code EAN chez le fournisseur
    if CreCustomerNumber is null then
      select CRE_CUSTOMER_NUMBER
        into CreCustomerNumber
        from PAC_SUPPLIER_PARTNER
       where PAC_SUPPLIER_PARTNER_ID = JobRec.PAC_THIRD_ID;
    end if;

    Ean1               := rtrim(CreCustomerNumber);
    Ean2               := rtrim(JobRec.INTERM_RECEIVED_EAN);

    -- Comparaison entre le code recu et son code ean
    if    Ean1 is null
       or Ean2 is null
       or rtrim(CreCustomerNumber) <> rtrim(JobRec.INTERM_RECEIVED_EAN) then
      PutError(PCS.PC_FUNCTIONS.TranslateWord('Destinataire incorrect') || ' : ' || JobRec.INTERM_RECEIVED_EAN);
      return false;
    else
      return true;
    end if;
  end;

  -- Verification d'une date
  function VerifyDate(paDate varchar2, paFormat varchar2)
    return date
  is
  begin
    WRITELOG('*VerifyDate', 0);

    begin
      return to_date(paDate, paFormat);
    exception
      when others then
        PutError(PCS.PC_FUNCTIONS.TranslateWord('Format de la date incorrect') || ' : ' || paDate || ' ' || paFormat);
        return null;
    end;
  end;

  -- Mise en nombre une chaine de caractères
  function PutInNumber(paNumber varchar2, paEnt integer, paDec integer)
    return number
  is
    str9      varchar2(20);
    strFormat varchar2(20);
    strNumber varchar2(20);
  begin
    WRITELOG('*PutInNumber', 0);

    begin
      if paEnt = 0 then
        return to_number(paNumber);
      else
        -- Chaine de base pour formatage
        str9       := '99999999999999999999';
        -- Création du format
        strFormat  := substr(str9, 1, paEnt) || '.' || substr(str9, 1, paDec);
        -- Nombre transcrit
        strNumber  := substr(paNumber, 1, paEnt) || '.' || substr(paNumber, paEnt + 1, paDec);
        return to_number(strNumber, strFormat);
      end if;
    exception
      when others then
        PutError(PCS.PC_FUNCTIONS.TranslateWord('Format d''un nombre incorrect') || ' : ' || paNumber);
        return null;
    end;
  end;

  -- Fonction chargée de retourner l'id du dossier
  function GetRecordId(aTitle varchar2, aNumber number)
    return number
  is
    DocRecordId number(12);
  begin
    WRITELOG('*GetRecordId', 0);

    -- Si aNumber est Null, la fonction retourne null
    if aNumber is not null then
      -- Recherche en fonction du titre
      select max(DOC_RECORD_ID)
        into DocRecordId
        from DOC_RECORD
       where RCO_TITLE = rtrim(aTitle);

      -- Recherche en fonction du numéro
      if DocRecordId is not null then
        select max(DOC_RECORD_ID)
          into DocRecordId
          from DOC_RECORD
         where RCO_NUMBER = aNumber;
      end if;
    end if;

    --
    return DocRecordId;
  end;

  -- Fonction chargée de retourner l'id de la condition d'envoi
  function GetSendingConditionId(aDescr varchar2)
    return number
  is
    PacConditionId number(12);
  begin
    WRITELOG('*GetSendingConditionId', 0);

    --
    select max(PAC_SENDING_CONDITION_ID)
      into PacConditionId
      from PAC_SENDING_CONDITION
     where SEN_KEY = rtrim(aDescr);

    --
    return PacConditionId;
  end;

  -- Fonction chargée de retourner l'id de la condition de paiement
  function GetPaymentConditionId(aDescr varchar2)
    return number
  is
    PacConditionId number(12);
  begin
    WRITELOG('*GetPaymentConditionId', 0);

    --
    select max(PAC_PAYMENT_CONDITION_ID)
      into PacConditionId
      from PAC_PAYMENT_CONDITION
     where PCO_DESCR = rtrim(aDescr);

    --
    return PacConditionId;
  end;

  -- Fonction chargée de retourner l'id de la monnaie
  function GetCurrId(aCurrency varchar2)
    return number
  is
    PcAcsCurrId number(12);
  begin
    WRITELOG('*GetCurrId', 0);

    begin
      -- Attention, recherche de l'acs_financial_currency_id
      select ACS_FINANCIAL_CURRENCY_ID
        into PcAcsCurrId
        from PCS.PC_CURR CUR
           , ACS_FINANCIAL_CURRENCY ACS
       where CUR.CURRENCY = rtrim(aCurrency)
         and ACS.PC_CURR_ID = CUR.PC_CURR_ID;
    -- Langue non trouvée
    exception
      when no_data_found then
        begin
          -- Message d'erreur
          PutError(PCS.PC_FUNCTIONS.TranslateWord('Code monnaie non trouvé') || ' : ' || aCurrency);
          PcAcsCurrId  := null;
        end;
    end;

    --
    return PcAcsCurrId;
  end;

  -- Fonction chargée de retourner l'id du pays
  function GetCountryId(aCntId varchar2)
    return number
  is
    PcCntId number(12);
  begin
    WRITELOG('*GetCountryId', 0);

    begin
      select PC_CNTRY_ID
        into PcCntId
        from PCS.PC_CNTRY
       where CNTID = rtrim(aCntId);
    -- Pays non trouvée
    exception
      when no_data_found then
        begin
          -- Message d'erreur
          PutWarning(PCS.PC_FUNCTIONS.TranslateWord('Code pays non trouvé') || ' : ' || aCntId);
          PcCntId  := null;
        end;
    end;

    --
    return PcCntId;
  end;

  -- Fonction chargée de retourner l'id de la langue
  function GetLangId(aLanId varchar2)
    return number
  is
    PcLangId number(12);
  begin
    WRITELOG('*GetLanId', 0);

    begin
      select PC_LANG_ID
        into PcLangId
        from PCS.PC_LANG
       where LANID = rtrim(aLanId);
    -- Langue non trouvée
    exception
      when no_data_found then
        begin
          -- Message d'erreur
          PutError(PCS.PC_FUNCTIONS.TranslateWord('Code langue non trouvé') || ' : ' || aLanId);
          PcLangId  := null;
        end;
    end;

    --
    return PcLangId;
  end;

  -- Retourne l'id d'un bien en fonction de sa référence
  function GetGcoGoodId(aReference varchar2)
    return number
  is
    GcoGoodId number(12);
  begin
    WRITELOG('*GetGcoGoodId', 0);

    --
    begin
      select GCO_GOOD_ID
        into GcoGoodId
        from GCO_GOOD
       where GOO_MAJOR_REFERENCE = rtrim(aReference);
    -- Bien non trouvé
    exception
      when no_data_found then
        begin
          -- Message d'erreur
          PutError(PCS.PC_FUNCTIONS.TranslateWord('Bien non trouvé') || ' : ' || aReference);
          GcoGoodId  := null;
        end;
    end;

    --
    return GcoGoodId;
  end;

  -- Recherche l'id d'un fournisseur en fonction de code ean, ainsi que certaines données.
  procedure GetPacThirdId(paNumber in varchar2, PacThirdId out number, DicTypeSubmissionId out number, AcsVatDetAccountId out number)
  is
  begin
    WRITELOG('*GetPacThirdId', 0);

    begin
      select PAC_SUPPLIER_PARTNER_ID
           , DIC_TYPE_SUBMISSION_ID
           , ACS_VAT_DET_ACCOUNT_ID
        into PacThirdId
           , DicTypeSubmissionId
           , AcsVatDetAccountId
        from PAC_SUPPLIER_PARTNER
       where CRE_EAN_NUMBER = rtrim(paNumber);
    -- Fournisseur non Trouvé
    exception
      when no_data_found then
        begin
          -- Message d'erreur
          PutError(PCS.PC_FUNCTIONS.TranslateWord('Fournisseur non trouvé') || ' : ' || paNumber);
        end;
    end;
  end;

  -- Détermine l'Id d'un gabarit en fonction de sa description.
  -- Si l'id de retoure est 0, cela signifie que le gabarit n'a pas été trouvé.
  function GetGaugeFromDescr(aDescr varchar2)
    return number
  is
    gauId number(12);
  begin
    WRITELOG('*GetGaugeFromDescr', 0);

    begin
      select DOC_GAUGE_ID
        into gauId
        from DOC_GAUGE
       where rtrim(GAU_DESCRIBE) = aDescr;
    -- Gabarit non Trouvé
    exception
      when no_data_found then
        begin
          -- Message d'erreur
          PutError(PCS.PC_FUNCTIONS.TranslateWord('Gabarit non trouvé') || ': ' || aDescr);
          gauId  := null;
        end;
    end;

    --
    return gauId;
  end;

  -- Détermine l'Id du gabarit
  function GetGaugeId(aCode varchar2)
    return number
  is
    gauId    number(12);
    paraName varchar2(300);
    gauDescr varchar2(300);
  begin
    WRITELOG('*GetGaugeId', 0);
    --
    gauId  := null;

    --
    if aCode = '01' then
      paraName  := 'GAUGE_FOR_CONTENT_TYPE_01';
    else
      if aCode = '02' then
        paraName  := 'GAUGE_FOR_CONTENT_TYPE_02';
      else
        paraName  := null;
      end if;
    end if;

    --
    if paraName is null then
      PutError(PCS.PC_FUNCTIONS.TranslateWord('Type de gabarit inexistant') || ': ' || aCode);
    else
      -- Description du gabarit
      gauDescr  := DOC_EDI_FUNCTION.GetParamValue(paraName);

      if gauDescr is null then
        PutError(PCS.PC_FUNCTIONS.TranslateWord('Valeur du paramètre inexistant') || ': ' || paraName);
      else
        -- Recherche Id du gabarit
        gauId  := GetGaugeFromDescr(gauDescr);
      end if;
    end if;

    --
    return gauId;
  end;

  -- Détection des lignes non traitées
  procedure NoTreatedLines
  is
    okText boolean;

    cursor JobLines
    is
      select   DOC_EDI_IMPORT_JOB_DATA_ID
             , DID_VALUE
             , DID_LINE_NUMBER
          from DOC_EDI_IMPORT_JOB_DATA
         where DOC_EDI_IMPORT_JOB_ID = SysRec.JOB_ID
           and (   rtrim(C_EDI_JOB_DATA_STATUS) is null
                or C_EDI_JOB_DATA_STATUS = 'UNDEF')
      order by DOC_EDI_IMPORT_JOB_DATA_ID;

    params JobLines%rowtype;
  begin
    WRITELOG('**NoTreatedLines', 0);

    --
    open JobLines;

    fetch JobLines
     into params;

    while JobLines%found loop
      InitVarLine;
      -- Id du record
      LineRec.DOC_EDI_IMPORT_JOB_DATA_ID  := params.DOC_EDI_IMPORT_JOB_DATA_ID;
      -- Ligne
      LineRec.DID_VALUE                   := params.DID_VALUE;
      -- Numéro de ligne
      LineRec.DID_LINE_NUMBER             := params.DID_LINE_NUMBER;
      -- Message de warning
      PutError(PCS.PC_FUNCTIONS.TranslateWord('Ligne indéfinie et non traitée, car non rattachée à un document') );
      -- Statut UNDEF
      PutStatus(3);
      -- Agit comme si un document donnait des erreurs
      JobRec.NEW_DOC_NOT_OK               := true;

      fetch JobLines
       into params;
    end loop;
  end;

-- *************************************************
-- *****        Import PROCONCEPT 900          *****
-- *************************************************

  -- Decode d'une ligne entete de fichier import 900
  function DecodeHeaderFile
    return boolean
  is
    result boolean;
  begin
    WRITELOG('--------DECODEHEADERFILE', 0);
    -- Traitement
    -- Lecture du fournisseur et data associés
    PutRowPosition('27');
    GetPacThirdId(JobRec.INTERM_CRE_EAN_NUMBER, JobRec.PAC_THIRD_ID, JobRec.DIC_TYPE_SUBMISSION_ID, JobRec.ACS_VAT_DET_ACCOUNT_ID);
    result  := JobRec.PAC_THIRD_ID is not null;

    -- Test bon destinataire. Important de faire ce test après GetPacThirdId, car la
    -- CompareEanCustomer a besoin du pac_third_id.
    if result then
      PutRowPosition('40');
      result  := CompareEanCustomer(JobRec.INTERM_RECEIVED_EAN);
    end if;

    -- Préparation status de la ligne
    PutStatus(ConvertState(result) );
    --
    return result;
  end;

  -- Traitement de l'entête du fichier import
  function HeaderFile
    return boolean
  is
    result boolean;
  begin
    WRITELOG('------HEADERFILE', 0);
    -- Init des variables de la ligne
    InitVarLine;

    begin
      select DOC_EDI_IMPORT_JOB_DATA_ID
           , DID_VALUE
           , DID_LINE_NUMBER
           ,
             --
             substr(DID_VALUE, 27, 13)
           , substr(DID_VALUE, 40, 13)
        into LineRec.DOC_EDI_IMPORT_JOB_DATA_ID
           , LineRec.DID_VALUE
           , LineRec.DID_LINE_NUMBER
           ,
             --
             JobRec.INTERM_CRE_EAN_NUMBER
           , JobRec.INTERM_RECEIVED_EAN
        from DOC_EDI_IMPORT_JOB_DATA
       where DOC_EDI_IMPORT_JOB_ID = SysRec.JOB_ID
         and substr(DID_VALUE, 1, 4) = 'HEAD'
         and substr(DID_VALUE, 19, 6) = 'INVOIC';

      --
        -- Décodage de la ligne d'entete du fichier
      result  := DecodeHeaderFile;
    exception
      when no_data_found then
        begin
          -- Ligne non trouvée
          result  := false;
          -- Erreur
          PutError(PCS.PC_FUNCTIONS.TranslateWord('En-tête de fichier non trouvé') );
        end;
    end;

    --
    return result;
  end;

  -- Decode d'une ligne pied de fichier import
  procedure DecodeFooterFile
  is
    result boolean;
  begin
    WRITELOG('--------DECODEFOOTERFILE', 0);
    -- Traitement ok
    result  := true;
    -- Préparation status de la ligne
    PutStatus(ConvertState(result) );
  end;

  -- Traitement du pied du fichier import
  function FooterFile
    return boolean
  is
    result boolean;
  begin
    WRITELOG('------FOOTERFILE', 0);
    -- Init des variables de la ligne
    InitVarLine;

    begin
      select DOC_EDI_IMPORT_JOB_DATA_ID
           , DID_VALUE
           , DID_LINE_NUMBER
        into LineRec.DOC_EDI_IMPORT_JOB_DATA_ID
           , LineRec.DID_VALUE
           , LineRec.DID_LINE_NUMBER
        from DOC_EDI_IMPORT_JOB_DATA
       where DOC_EDI_IMPORT_JOB_ID = SysRec.JOB_ID
         and substr(DID_VALUE, 1, 4) = 'FOOT';

      --
        -- Décodage de la ligne d'adresse
      DecodeFooterFile;
      -- Ligne trouvée
      result  := true;
    --
    exception
      when no_data_found then
        begin
          -- Ligne non trouvée
          result  := false;
          -- Erreur
          PutError(PCS.PC_FUNCTIONS.TranslateWord('Pied de fichier non trouvé') );
        end;
    end;

    --
    return result;
  end;

  -- Decode d'une ligne détail document import
  procedure DecodeHeaderDocuAdr(paType varchar2, paLine varchar2)
  is
    result boolean;
  begin
    WRITELOG('--------------DECODEHEADERDOCUADR', 0);
    result  := true;

    --
    -- Adresse inexistante
    if rtrim(paLine) is not null then
      if paType = '1' then
        if rtrim(HeaderDocu.DOI_CNTID1) is not null then
          PutRowPosition('27');
          HeaderDocu.PC_CNTRY_ID  := GetCountryId(HeaderDocu.DOI_CNTID1);
          result                  := HeaderDocu.PC_CNTRY_ID is not null;
        end if;
      end if;

      --
      if paType = '2' then
        if rtrim(HeaderDocu.DOI_CNTID2) is not null then
          PutRowPosition('27');
          HeaderDocu.PC__PC_CNTRY_ID  := GetCountryId(HeaderDocu.DOI_CNTID2);
          result                      := HeaderDocu.PC__PC_CNTRY_ID is not null;
        end if;
      end if;

      --
      if paType = '3' then
        if rtrim(HeaderDocu.DOI_CNTID3) is not null then
          PutRowPosition('27');
          HeaderDocu.PC_2_PC_CNTRY_ID  := GetCountryId(HeaderDocu.DOI_CNTID3);
          result                       := HeaderDocu.PC_2_PC_CNTRY_ID is not null;
        end if;
      end if;
    end if;

    --
    if not result then
      -- Warning
      PutStatus(2);
    else
      -- Ok
      PutStatus(1);
    end if;
  end;

  -- Traitement de l'en-tête du document avec adresses import
  procedure HeaderDocuAdr
  is
    strType varchar2(1);

    cursor HeaderAdr
    is
      select DOC_EDI_IMPORT_JOB_DATA_ID
           , DID_VALUE
           , DID_LINE_NUMBER
        from DOC_EDI_IMPORT_JOB_DATA
       where DOC_EDI_IMPORT_JOB_ID = SysRec.JOB_ID
         and rtrim(substr(DID_VALUE, 5, 30) ) = HeaderDocu.DOI_PARTNER_NUMBER
         and substr(DID_VALUE, 1, 4) = 'H002';

    params  HeaderAdr%rowtype;
  begin
    WRITELOG('------------HEADERDOCUADR', 0);

    open HeaderAdr;

    fetch HeaderAdr
     into params;

    while HeaderAdr%found loop
      InitVarLine;
      -- Id du job data
      lineRec.DOC_EDI_IMPORT_JOB_DATA_ID  := params.DOC_EDI_IMPORT_JOB_DATA_ID;
      -- Ligne
      lineRec.DID_VALUE                   := params.DID_VALUE;
      -- Numéro de ligne
      LineRec.DID_LINE_NUMBER             := params.DID_LINE_NUMBER;
      -- Type d'adresse
      strType                             := substr(params.DID_VALUE, 38, 1);

      -- Cas adresse 1
      if strType = '1' then
        HeaderDocu.DOI_CNTID1    := substr(params.DID_VALUE, 39, 5);
        HeaderDocu.DOI_ZIPCODE1  := substr(params.DID_VALUE, 44, 10);
        HeaderDocu.DOI_TOWN1     := substr(params.DID_VALUE, 54, 30);
        HeaderDocu.DOI_ADDRESS1  := substr(params.DID_VALUE, 84, 255);
        HeaderDocu.DOI_STATE1    := substr(params.DID_VALUE, 339, 30);
        -- Décodage de la ligne d'adresse
        DecodeHeaderDocuAdr(strType, substr(params.DID_VALUE, 39, 330) );
      end if;

      -- Cas adresse 2
      if strType = '2' then
        HeaderDocu.DOI_CNTID2    := substr(params.DID_VALUE, 39, 5);
        HeaderDocu.DOI_ZIPCODE2  := substr(params.DID_VALUE, 44, 10);
        HeaderDocu.DOI_TOWN2     := substr(params.DID_VALUE, 54, 30);
        HeaderDocu.DOI_ADDRESS2  := substr(params.DID_VALUE, 84, 255);
        HeaderDocu.DOI_STATE2    := substr(params.DID_VALUE, 339, 30);
        -- Décodage de la ligne d'adresse
        DecodeHeaderDocuAdr(strType, substr(params.DID_VALUE, 39, 330) );
      end if;

      -- Cas adresse 3
      if strType = '3' then
        HeaderDocu.DOI_CNTID3    := substr(params.DID_VALUE, 39, 5);
        HeaderDocu.DOI_ZIPCODE3  := substr(params.DID_VALUE, 44, 10);
        HeaderDocu.DOI_TOWN3     := substr(params.DID_VALUE, 54, 30);
        HeaderDocu.DOI_ADDRESS3  := substr(params.DID_VALUE, 84, 255);
        HeaderDocu.DOI_STATE3    := substr(params.DID_VALUE, 339, 30);
        -- Décodage de la ligne d'adresse
        DecodeHeaderDocuAdr(strType, substr(params.DID_VALUE, 39, 330) );
      end if;

      --
      fetch HeaderAdr
       into params;
    end loop;
  end;

  -- Decode d'une ligne en-tête document import
  procedure DecodeHeaderDocu
  is
    result boolean;
  begin
    WRITELOG('------------DECODEHEADERDOCU', 0);
    result  := true;

    --
    -- Détermine l'Id du gabarit en fonction du type importé
    if result then
      PutRowPosition('35');
      HeaderDocu.DOC_GAUGE_ID  := GetGaugeId(HeaderDocu.INTERM_DOCU_TYPE);
      result                   := HeaderDocu.DOC_GAUGE_ID is not null;
    end if;

    -- Test format des dates
    if result then
      PutRowPosition('37');
      HeaderDocu.DOI_PARTNER_DATE  := VerifyDate(HeaderDocu.INTERM_DOI_PARTNER_DATE, 'YYYYMMDD');
      result                       := HeaderDocu.DOI_PARTNER_DATE is not null;
    end if;

    -- Test format des dates
    if result then
      PutRowPosition('45');
      HeaderDocu.DOI_VALUE_DATE  := VerifyDate(HeaderDocu.INTERM_DOI_VALUE_DATE, 'YYYYMMDD');
      result                     := HeaderDocu.DOI_VALUE_DATE is not null;
    end if;

    -- Test format des dates
    if result then
      PutRowPosition('53');
      HeaderDocu.DOI_DELIVERY_DATE  := VerifyDate(HeaderDocu.INTERM_DOI_DELIVERY_DATE, 'YYYYMMDD');
      result                        := HeaderDocu.DOI_DELIVERY_DATE is not null;
    end if;

    -- Détermine le numéro de dossier
    if result then
      PutRowPosition('61');

      -- DOI_RCO_NUMBER rempli d'espaces -> Null pour les deux valeurs (signifie que le
      -- DOC_RECORD_ID du document était null
      if rtrim(HeaderDocu.INTERM_DOI_RCO_NUMBER) is null then
        HeaderDocu.DOI_RCO_NUMBER  := null;
        HeaderDocu.DOI_RCO_TITLE   := null;
      -- Autres que des espaces -> décodage
      else
        HeaderDocu.DOI_RCO_NUMBER  := PutInNumber(HeaderDocu.INTERM_DOI_RCO_NUMBER, 9, 0);
        -- Si Null -> erreur
        result                     := HeaderDocu.DOI_RCO_NUMBER is not null;
      end if;
    end if;

    -- Détermine l'Id de la monnaie
    if result then
      PutRowPosition('180');
      HeaderDocu.ACS_FINANCIAL_CURRENCY_ID  := GetCurrId(HeaderDocu.DOI_CURRENCY);
      result                                := HeaderDocu.ACS_FINANCIAL_CURRENCY_ID is not null;
    end if;

    -- Détermine l'Id de la langue
    if result then
      PutRowPosition('183');
      HeaderDocu.PC_LANG_ID  := GetLangId(HeaderDocu.DOI_LANID);
      result                 := HeaderDocu.PC_LANG_ID is not null;
    end if;

    -- Tente de déterminer l'Id des conditions de paiement
    if result then
      HeaderDocu.PAC_PAYMENT_CONDITION_ID  := GetPaymentConditionId(HeaderDocu.DOI_PCO_DESCR);
    end if;

    -- Tente de déterminer l'Id des conditions d'envoi
    if result then
      HeaderDocu.PAC_SENDING_CONDITION_ID  := GetSendingConditionId(HeaderDocu.DOI_SEN_KEY);
    end if;

    -- Tente de déterminer l'Id du dossier
    if result then
      HeaderDocu.DOC_RECORD_ID  := GetRecordId(HeaderDocu.DOI_RCO_TITLE, HeaderDocu.DOI_RCO_NUMBER);
    end if;

    --
    PutStatus(ConvertState(result) );
  end;

  -- Traitement de l'entete du document import
  procedure Header_Docu
  is
  begin
    WRITELOG('----------HEADER_DOCU', 0);
    -- Init des champs de l'en-tête du document
    InitFieldsDoc;
    -- Init des variables de la ligne document
    InitVarDoc;
    -- Init des variables de la ligne
    InitVarLine;

    -- Recherche de l'en-tête du document
    begin
      select DOC_EDI_IMPORT_JOB_DATA_ID
           , DOC_EDI_IMPORT_JOB_DATA_ID
           , DID_VALUE
           , DID_LINE_NUMBER
           ,
             --
             substr(DID_VALUE, 35, 2)
           , substr(DID_VALUE, 37, 8)
           , substr(DID_VALUE, 45, 8)
           , substr(DID_VALUE, 53, 8)
           , substr(DID_VALUE, 61, 9)
           , substr(DID_VALUE, 70, 30)
           , substr(DID_VALUE, 100, 30)
           , substr(DID_VALUE, 130, 50)
           , substr(DID_VALUE, 180, 3)
           , substr(DID_VALUE, 183, 2)
           , substr(DID_VALUE, 265, 50)
        into LineRec.DOC_EDI_IMPORT_JOB_DATA_ID
           ,   -- Pour la ligne
             DocumentRec.DOC_EDI_IMPORT_JOB_DATA_ID
           ,   -- Pour l'en-tête (mise à jour plus tard avec GENE)
             LineRec.DID_VALUE
           , LineRec.DID_LINE_NUMBER
           ,
             --
             HeaderDocu.INTERM_DOCU_TYPE
           , HeaderDocu.INTERM_DOI_PARTNER_DATE
           , HeaderDocu.INTERM_DOI_VALUE_DATE
           , HeaderDocu.INTERM_DOI_DELIVERY_DATE
           , HeaderDocu.INTERM_DOI_RCO_NUMBER
           , HeaderDocu.DOI_RCO_TITLE
           , HeaderDocu.DOI_SEN_KEY
           , HeaderDocu.DOI_PARTNER_REFERENCE
           , HeaderDocu.DOI_CURRENCY
           , HeaderDocu.DOI_LANID
           , HeaderDocu.DOI_PCO_DESCR
        from DOC_EDI_IMPORT_JOB_DATA
       where DOC_EDI_IMPORT_JOB_ID = SysRec.JOB_ID
         and rtrim(substr(DID_VALUE, 5, 30) ) = HeaderDocu.DOI_PARTNER_NUMBER
         and substr(DID_VALUE, 1, 4) = 'H001';

      -- Décodage de l'en-tête
      DecodeHeaderDocu;
      -- Lecture des adresses
      HeaderDocuAdr;
      -- Ajout dans l'interface
      InsertInterface;
    exception
      when no_data_found then
        DocumentRec.NEW_DOC_STOP  := false;
    end;
  end;

  -- Decode d'une détail docu text import
  procedure DecodeDetailDocuText
  is
    result boolean;
  begin
    WRITELOG('--------------DECODEDETAILDOCUTEXT', 0);
    result  := true;
    --
    PutStatus(ConvertState(result) );
  end;

  -- Traitement des positions article avec texte pour import
  procedure DetailDocuText(paPosition varchar2)
  is
    strType varchar2(3);

    cursor DetailDocuText
    is
      select DOC_EDI_IMPORT_JOB_DATA_ID
           , DID_VALUE
           , DID_LINE_NUMBER
        from DOC_EDI_IMPORT_JOB_DATA
       where DOC_EDI_IMPORT_JOB_ID = SysRec.JOB_ID
         and rtrim(substr(DID_VALUE, 5, 30) ) = HeaderDocu.DOI_PARTNER_NUMBER
         and rtrim(substr(DID_VALUE, 35, 5) ) = paPosition
         and substr(DID_VALUE, 1, 4) = 'P002';

    params  DetailDocuText%rowtype;
  begin
    WRITELOG('------------DETAILDOCUTEXT', 0);

    open DetailDocuText;

    fetch DetailDocuText
     into params;

    while DetailDocuText%found loop
      InitVarLine;
      -- Id du job data
      LineRec.DOC_EDI_IMPORT_JOB_DATA_ID  := params.DOC_EDI_IMPORT_JOB_DATA_ID;
      -- Ligne
      LineRec.DID_VALUE                   := params.DID_VALUE;
      -- Numéro de ligne
      LineRec.DID_LINE_NUMBER             := params.DID_LINE_NUMBER;
      -- Type de record
      strType                             := substr(params.DID_VALUE, 40, 3);

      --
      if strType = '001' then
        DetailDocu.DOP_LONG_DESCRIPTION  := substr(params.DID_VALUE, 43, 1950);
      end if;

      --
      if strType = '002' then
        DetailDocu.DOP_FREE_DESCRIPTION  := substr(params.DID_VALUE, 43, 1950);
      end if;

      --
      if strType = '003' then
        DetailDocu.DOP_BODY_TEXT  := substr(params.DID_VALUE, 43, 1950);
      end if;

      --
      DecodeDetailDocuText;

      fetch DetailDocuText
       into params;
    end loop;
  end;

  -- Decode d'une ligne détail document import
  procedure DecodeDetailDocu
  is
    result boolean;
  begin
    WRITELOG('------------DECODEDETAILDOCU', 0);
    result  := true;

    -- Position
    if result then
      PutRowPosition('35');
      DetailDocu.DOP_POS_NUMBER  := PutInNumber(DetailDocu.INTERM_DOP_POS_NUMBER, 5, 0);
      result                     := DetailDocu.DOP_POS_NUMBER is not null;
    end if;

    -- Recherche Id du bien
    if result then
      PutRowPosition('40');
      DetailDocu.GCO_GOOD_ID  := GetGcoGoodId(DetailDocu.DOP_MAJOR_REFERENCE);
      result                  := DetailDocu.GCO_GOOD_ID is not null;
    end if;

    -- Quantité
    if result then
      PutRowPosition('70');
      DetailDocu.DOP_QTY  := PutInNumber(DetailDocu.INTERM_DOP_QTY, 11, 4);
      result              := DetailDocu.DOP_QTY is not null;
    end if;

    -- Quantité
    if result then
      PutRowPosition('85');
      DetailDocu.DOP_QTY_VALUE  := PutInNumber(DetailDocu.INTERM_DOP_QTY_VALUE, 11, 4);
      result                    := DetailDocu.DOP_QTY_VALUE is not null;
    end if;

    -- Détermine le numéro de dossier
    if result then
      PutRowPosition('103');

      -- DOP_RCO_NUMBER rempli d'espaces -> Null pour les deux valeurs (signifie que le
      -- DOC_RECORD_ID du document était null)
      if rtrim(DetailDocu.INTERM_DOP_RCO_NUMBER) is null then
        DetailDocu.DOP_RCO_NUMBER  := null;
        DetailDocu.DOP_RCO_TITLE   := null;
      -- Autres que des espaces -> décodage
      else
        DetailDocu.DOP_RCO_NUMBER  := PutInNumber(DetailDocu.INTERM_DOP_RCO_NUMBER, 9, 0);
        -- Si Null -> erreur
        result                     := DetailDocu.DOP_RCO_NUMBER is not null;
      end if;
    end if;

    -- Valeur
    if result then
      PutRowPosition('142');
      DetailDocu.DOP_NET_VALUE_EXCL  := PutInNumber(DetailDocu.INTERM_DOP_NET_VALUE_EXCL, 11, 4);
      result                         := DetailDocu.DOP_NET_VALUE_EXCL is not null;
    end if;

    -- Valeur
    if result then
      PutRowPosition('172');
      DetailDocu.DOP_NET_VALUE_INCL  := PutInNumber(DetailDocu.INTERM_DOP_NET_VALUE_INCL, 11, 4);
      result                         := DetailDocu.DOP_NET_VALUE_INCL is not null;
    end if;

    -- Tarif
    if result then
      PutRowPosition('187');
      DetailDocu.DOP_NET_TARIFF  := PutInNumber(DetailDocu.INTERM_DOP_NET_TARIFF, 1, 0);
      result                     := DetailDocu.DOP_NET_TARIFF is not null;
    end if;

    -- Tente de déterminer l'Id du dossier
    if result then
      DetailDocu.DOC_RECORD_ID  := GetRecordId(DetailDocu.DOP_RCO_TITLE, DetailDocu.DOP_RCO_NUMBER);
    end if;

    --
    PutStatus(ConvertState(result) );
  end;

  -- Traitement du détail du document import
  procedure Detail_Docu
  is
    okText boolean;

    cursor DetailDocument
    is
      select DOC_EDI_IMPORT_JOB_DATA_ID
           , DID_VALUE
           , DID_LINE_NUMBER
        from DOC_EDI_IMPORT_JOB_DATA
       where DOC_EDI_IMPORT_JOB_ID = SysRec.JOB_ID
         and rtrim(substr(DID_VALUE, 5, 30) ) = HeaderDocu.DOI_PARTNER_NUMBER
         and substr(DID_VALUE, 1, 4) = 'P001';

    params DetailDocument%rowtype;
  begin
    WRITELOG('----------DETAIL_DOCU', 0);

    open DetailDocument;

    fetch DetailDocument
     into params;

    while DetailDocument%found loop
      InitFieldsDetail;
      InitVarLine;
      -- Id du record
      LineRec.DOC_EDI_IMPORT_JOB_DATA_ID    := params.DOC_EDI_IMPORT_JOB_DATA_ID;
      -- Ligne
      LineRec.DID_VALUE                     := params.DID_VALUE;
      -- Numéro de ligne
      LineRec.DID_LINE_NUMBER               := params.DID_LINE_NUMBER;
      -- Type de position détail
      DetailDocu.C_GAUGE_TYPE_POS           := '1';
      DetailDocu.INTERM_DOP_POS_NUMBER      := substr(params.DID_VALUE, 35, 5);
      DetailDocu.DOP_MAJOR_REFERENCE        := substr(params.DID_VALUE, 40, 30);
      DetailDocu.INTERM_DOP_QTY             := substr(params.DID_VALUE, 70, 15);
      DetailDocu.INTERM_DOP_QTY_VALUE       := substr(params.DID_VALUE, 85, 15);
      --  NON UTILISE                         := substr(params.DID_VALUE, 100, 3);
      DetailDocu.INTERM_DOP_RCO_NUMBER      := substr(params.DID_VALUE, 103, 9);
      DetailDocu.DOP_RCO_TITLE              := substr(params.DID_VALUE, 112, 30);
      DetailDocu.INTERM_DOP_NET_VALUE_EXCL  := substr(params.DID_VALUE, 142, 15);
      ---- NON UTILISE                        := substr(params.DID_VALUE, 147, 15);
      DetailDocu.INTERM_DOP_NET_VALUE_INCL  := substr(params.DID_VALUE, 172, 15);
      DetailDocu.INTERM_DOP_NET_TARIFF      := substr(params.DID_VALUE, 187, 1);
      DetailDocu.DOP_SHORT_DESCRIPTION      := substr(params.DID_VALUE, 188, 30);
      ---- NON UTILISE                        := substr(params.DID_VALUE, 218, 30);
      -- Décodage du détail
      DecodeDetailDocu;
      -- Lecture des textes de la position
      DetailDocuText(DetailDocu.INTERM_DOP_POS_NUMBER);
      -- Ajout dans l'interface position
      InsertInterfacePosition;

      fetch DetailDocument
       into params;
    end loop;
  end;

  -- Decode d'une ligne détail texte import
  procedure DecodeDetailtext
  is
    result boolean;
  begin
    WRITELOG('------------DECODEDETAILTEXT', 0);
    --
    result  := true;

    -- Position
    if result then
      PutRowPosition('35');
      DetailDocu.DOP_POS_NUMBER  := PutInNumber(DetailDocu.INTERM_DOP_POS_NUMBER, 5, 0);
      result                     := DetailDocu.DOP_POS_NUMBER is not null;
    end if;

    --
    PutStatus(ConvertState(result) );
  end;

  -- Traitement des positions texte pour import
  procedure DetailText
  is
    okText boolean;

    cursor DetailDocument
    is
      select DOC_EDI_IMPORT_JOB_DATA_ID
           , DID_VALUE
           , DID_LINE_NUMBER
        from DOC_EDI_IMPORT_JOB_DATA
       where DOC_EDI_IMPORT_JOB_ID = SysRec.JOB_ID
         and rtrim(substr(DID_VALUE, 5, 30) ) = HeaderDocu.DOI_PARTNER_NUMBER
         and substr(DID_VALUE, 1, 4) = 'P003';

    params DetailDocument%rowtype;
  begin
    WRITELOG('----------DETAILTEXT', 0);

    open DetailDocument;

    fetch DetailDocument
     into params;

    while DetailDocument%found loop
      InitFieldsDetail;
      InitVarLine;
      LineRec.DOC_EDI_IMPORT_JOB_DATA_ID  := params.DOC_EDI_IMPORT_JOB_DATA_ID;
      -- Ligne
      LineRec.DID_VALUE                   := params.DID_VALUE;
      -- Numéro de ligne
      LineRec.DID_LINE_NUMBER             := params.DID_LINE_NUMBER;
      -- Type de position texte
      DetailDocu.C_GAUGE_TYPE_POS         := '4';
      --
      DetailDocu.INTERM_DOP_POS_NUMBER    := substr(params.DID_VALUE, 35, 5);
      DetailDocu.DOP_BODY_TEXT            := substr(params.DID_VALUE, 40, 1950);
      -- Décodage du détail
      DecodeDetailText;
      -- Ajout dans l'interface position
      InsertInterfacePosition;

      fetch DetailDocument
       into params;
    end loop;
  end;

  -- Traitement complet d'un document pour import
  procedure ProcessDocu
  is
  begin
    WRITELOG('--------PROCESSDOCU', 0);
    -- Entete du document avec adresse
    Header_Docu;
    -- Détail du document
    Detail_Docu;
    -- Position texte
    DetailText;
  end;

  -- Détection des documents pour import
  procedure HeaderDocuDetect
  is
    cursor HeaderDetect(paJobId number)
    is
      select rtrim(substr(DID_VALUE, 5, 30) ) dmtNumber
        from DOC_EDI_IMPORT_JOB_DATA
       where DOC_EDI_IMPORT_JOB_ID = paJobId
         and nvl(C_EDI_JOB_DATA_STATUS, ' ') <> 'GENE'
         and substr(DID_VALUE, 1, 4) = 'H001';

    params HeaderDetect%rowtype;
  begin
    WRITELOG('------HEADERDOCUDETECT', 0);

    open HeaderDetect(SysRec.JOB_ID);

    fetch HeaderDetect
     into params;

    -- Parcours toutes les en-tête de document
    while HeaderDetect%found loop
      -- Numéro de document
      HeaderDocu.DOI_PARTNER_NUMBER  := params.dmtNumber;
      -- Inscription numéro document dans le log
      PutMessage(PCS.PC_FUNCTIONS.TranslateWord('Traitement du document') || ' : ' || HeaderDocu.DOI_PARTNER_NUMBER);
      -- Traitement d'un document complet
      ProcessDocu;

      -- Problème document
      if DocumentRec.NEW_DOC_STOP then
        -- Document erreur (pour statut de retour final à delphi)
        JobRec.NEW_DOC_NOT_OK  := true;
        -- Suppression des enregistrements ajoutés
        DeleteInterfaceRecords;
        -- Inscription numéro interface dans le log
        PutMessage(PCS.PC_FUNCTIONS.TranslateWord('Document non traité') );
      else
        -- Document en ordre (pour statut de retour final à delphi)
        JobRec.NEW_DOC_OK  := true;
        -- Mise à jour des status, passage de en préparation à prêt
        UpdateInterfaceRecords;
        -- Mise à jour de l'en-tête du document
        UpdateDocHeaderRecord;
        -- Inscription numéro interface dans le log
        PutMessage(PCS.PC_FUNCTIONS.TranslateWord('Création de l''interface') || ' : ' || DocumentRec.NEW_DOI_NUMBER);
      end if;

      --
      fetch HeaderDetect
       into params;
    end loop;
  end;

  -- Determine la version de l'import
  function GetVersion
    return varchar2
  is
    result varchar2(2);
  begin
    WRITELOG('----GetVersion', 0);

    begin
      select substr(DID_VALUE, 25, 2)
        into result
        from DOC_EDI_IMPORT_JOB_DATA
       where DOC_EDI_IMPORT_JOB_ID = SysRec.JOB_ID
         and substr(DID_VALUE, 1, 4) = 'HEAD';
    exception
      when no_data_found then
        result  := '??';
    end;

    return result;
  end;

  -- Import900 ProConcept version 01
  procedure ImportV01
  is
    result boolean;
  begin
    WRITELOG('----IMPORTV01', 0);
    -- Entête du fichier
    result  := HeaderFile;

    -- Pied du fichier
    if result then
      result  := FooterFile;
    end if;

    -- Recherche et traitement complet de chaque document
    if result then
      HeaderDocuDetect;
    end if;
  end;

  -- Import900 ProConcept
  procedure Import900
  is
    NoVersion varchar2(2);
  begin
    WRITELOG('--IMPORT900', 0);
    -- Détermine la version
    NoVersion  := GetVersion;

    -- Version 01
    if NoVersion = '01' then
      ImportV01;
    else
      writelog(PCS.PC_FUNCTIONS.TranslateWord('Version') || ' ' || Noversion || ' ' || PCS.PC_FUNCTIONS.TranslateWord('non trouvée'), 99);
    end if;

    -- Traitement des lignes non traitées.
    NoTreatedLines;
  --
  exception
    when others then
      -- Erreur technique - retour de la fonction
      SysRec.RETURN_VALUE  := 9;
      -- Erreur dans le log
      PutError(sqlerrm);
      -- Maj statut de la ligne ERROR
      PutStatus(0);
      -- Suppression de records de l'interface
      DeleteInterfaceRecords;
  end;

  -- Importation générale
  procedure Import
  is
  begin
    -- Init des variables systeme
    InitVarSys;
    -- Id du job
    SysRec.JOB_ID  := DOC_EDI_IMPORT.GET_JOBID;
    -- Journal
    WRITELOG('IMPORT (DOC_EDI_IMPORT900)', 0);
    -- Init des variables du job
    InitVarJob;
    -- Recherche transfert
    DOC_EDI_FUNCTION.GetJob(SysRec.JOB_ID, glbEdiTypeId);
    -- Paramètres du transfert
    DOC_EDI_FUNCTION.FillParamsTable(glbEdiTypeId);
    -- Recherche de la fonction
    Import900;

    -- Retour de la valeur
    if SysRec.RETURN_VALUE is null then
      SysRec.RETURN_VALUE  := ReturnValue;
    end if;

    -- Retourne la valeur de retour des opérations
    DOC_EDI_IMPORT.SET_RETURN_VALUE(SYSREC.RETURN_VALUE);
  end;
end;
