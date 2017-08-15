--------------------------------------------------------
--  DDL for Package Body DOC_EDI_IMPORT800
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_EDI_IMPORT800" 
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

  procedure PutError(aMessage varchar2)
  -- Message d'erreur dans le log avec le numéro de ligne, la ligne, le message avec colone
  -- Le message est reformatté en fonction de la position
  is
  begin
    LineRec.DID_ERROR_TEXT  := aMessage;
    DOC_EDI_IMPORT.PutError(LineRec.DID_ERROR_TEXT, LineRec.DOC_EDI_IMPORT_JOB_DATA_ID, LineRec.DID_VALUE, LineRec.DID_LINE_NUMBER, LineRec.NEW_ROW_POSITION);
  end;

  -- Mise en nombre une chaine de caractères
  function PutInNumber(paNumber varchar2, paFormat varchar2)
    return number
  is
  begin
    WRITELOG('*PutInNumber', 0);

    begin
      return to_number(paNumber, paFormat);
    --
    exception
      when others then
        PutError(PCS.PC_FUNCTIONS.TranslateWord('Format de nombre incorrect') || ' : ' || paNumber || ', ' || paFormat);
        return null;
    end;
  end;

  -- Mise en date une chaine de caractères
  function PutInDate(paDate varchar2, paFormat varchar2)
    return date
  is
  begin
    WRITELOG('*PutInDate', 0);

    begin
      return to_date(paDate, paFormat);
    --
    exception
      when others then
        PutError(PCS.PC_FUNCTIONS.TranslateWord('Format de date incorrect') || ' : ' || paDate || ', ' || paFormat);
        return null;
    end;
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

--------------------
-- Initialisation --
--------------------

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
    -- Nom du gabarit pour table INTERFACE
    JobRec.GAU_DESCR              := null;
    -- Pas de document ok
    JobRec.NEW_DOC_OK             := false;
    -- Pas de document en erreur
    JobRec.NEW_DOC_NOT_OK         := false;
    ---- pac_third_id
    JobRec.INTERM_CUS_EAN_NUMBER  := null;
    JobRec.PAC_THIRD_ID           := null;
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
    -- Document
    HeaderDocu.INTERM_DOI_PARTNER_DATE  := null;
    HeaderDocu.DOI_PARTNER_DATE         := null;
    -- Gabarit
    HeaderDocu.INTERM_DOCU_TYPE         := null;
    HeaderDocu.DOC_GAUGE_ID             := null;
  -- Remarque : Le champs DOI_PARTNER_NUMBER ne doit pas être initialisé ici, car il
  --            possède déjà une valeur utile
  end;

  -- Init des champs du détail
  procedure InitFieldsDetail
  is
  begin
    WRITELOG('*InitFieldsDetail', 0);
    --
    DetailDocu.DOC_INTERFACE_POSITION_ID  := null;
    --
    DetailDocu.C_GAUGE_TYPE_POS           := null;
    -- No Position
    DetailDocu.INTERM_DOP_POS_NUMBER      := null;
    -- No Cmd + No Position
    DetailDocu.DOP_POS_TEXT_1             := null;
    DetailDocu.DOP_PDE_TEXT_1             := null;
    -- Produit
    DetailDocu.DOP_MAJOR_REFERENCE        := null;
    DetailDocu.GCO_GOOD_ID                := null;
    -- Qte commandé
    DetailDocu.INTERM_DOP_QTY             := null;
    DetailDocu.DOP_QTY                    := null;
    -- Delai demandé
    DetailDocu.INTERM_DOP_BASIS_DELAY     := null;
    DetailDocu.DOP_BASIS_DELAY            := null;
    -- Prix HT
    DetailDocu.INTERM_DOP_GROSS_VALUE     := null;
    DetailDocu.DOP_GROSS_VALUE            := null;
    -- Prix TTC
    DetailDocu.INTERM_DOP_NET_VALUE_INCL  := null;
    DetailDocu.DOP_NET_VALUE_INCL         := null;
    -- Prix unitaire
    DetailDocu.DOP_GROSS_UNIT_VALUE       := null;
    -- Description produit
    DetailDocu.DOP_LONG_DESCRIPTION       := null;
    -- Texte commande
    DetailDocu.DOP_BODY_TEXT              := null;
    --
    -- Copie du gauge du document sur le détail
    DetailDocu.DOC_GAUGE_ID               := HeaderDocu.DOC_GAUGE_ID;
  end;

  function ConvertState(paState boolean)
    return integer
  -- Converti l'état boolean en integer
  -- True  -> 1
  -- False -> 0
  is
  begin
    if paState then
      return 1;
    else
      return 0;
    end if;
  end;

  procedure PutStatus(paStatus integer)
  -- Mise à jour du statut d'une ligne JOB DATA
  -- 0 -> ERREUR
  -- 1 -> OK
  -- 2 -> WARNING
  -- 3 -> UNDEF
  is
  begin
    WRITELOG('*PutStatus', 0);

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
  begin
    begin
      if not DocumentRec.NEW_DOC_STOP then
        WRITELOG('*InsertInterface', 0);
        -- Création d'un enregistrement avec valeurs par défaut
        DOC_INTERFACE_CREATE.CREATE_INTERFACE(JobRec.PAC_THIRD_ID
                                            ,   -- IN Id du client
                                              JobRec.GAU_DESCR
                                            ,   -- IN Nom du gabarit d'initialisation
                                              HeaderDocu.DOC_GAUGE_ID
                                            ,   -- IN Id du gabarit
                                              '201'
                                            ,   -- IN Edi
                                              DocumentRec.NEW_DOI_NUMBER
                                            ,   -- OUT Numéro d'interface
                                              DocumentRec.DOC_INTERFACE_ID
                                             );   -- OUT Id de l'interface

        -- Mise à jour de l'interface avec valeurs spécifiques
        update DOC_INTERFACE
           set DOI_PARTNER_NUMBER = HeaderDocu.DOI_PARTNER_NUMBER   -- Numéro de document source
             , DOI_PARTNER_DATE = HeaderDocu.DOI_PARTNER_DATE   -- Date document source
             , DOI_PROTECTED = 0   -- Pas de protection
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_INTERFACE_ID = DocumentRec.DOC_INTERFACE_ID;
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
        WRITELOG('*InsertInterfacePosition', 0);
        -- Détermine l'id de l'interface position
        DOC_INTERFACE_POSITION_CREATE.CREATE_INTERFACE_POSITION(DocumentRec.DOC_INTERFACE_ID
                                                              ,   -- IN ID de l'interface
                                                                JobRec.GAU_DESCR
                                                              ,   -- IN Nom du gabarit d'initialisation
                                                                HeaderDocu.DOC_GAUGE_ID
                                                              ,   -- IN Id du gabarit
                                                                DetailDocu.C_GAUGE_TYPE_POS
                                                              ,   -- IN Type de position : 1
                                                                DetailDocu.DOC_INTERFACE_POSITION_ID
                                                               );   -- OUT
        -- Mise a jour interface position en fonction du produit
        DOC_INTERFACE_POSITION_CREATE.UPDATE_INTERFACE_POSITION(DocumentRec.DOC_INTERFACE_ID, DetailDocu.DOC_INTERFACE_POSITION_ID, DetailDocu.GCO_GOOD_ID);

        -- Mise à jour interface position en fonction valeurs spécifiques
        if nvl(DetailDocu.DOP_QTY, 0) <> 0 then
          DetailDocu.DOP_GROSS_UNIT_VALUE  := DetailDocu.DOP_GROSS_VALUE / DetailDocu.DOP_QTY;
        end if;

        --
        update DOC_INTERFACE_POSITION
           set DOP_POS_TEXT_1 = DetailDocu.DOP_POS_TEXT_1
             , DOP_PDE_TEXT_1 = DetailDocu.DOP_PDE_TEXT_1
             , DOP_BASIS_DELAY = DetailDocu.DOP_BASIS_DELAY   -- Délai demandé
             , DOP_INTERMEDIATE_DELAY = DetailDocu.DOP_BASIS_DELAY
             , DOP_FINAL_DELAY = DetailDocu.DOP_BASIS_DELAY
             , DOP_GROSS_VALUE = DetailDocu.DOP_GROSS_VALUE   -- Prix HT
             , DOP_NET_VALUE_EXCL = DetailDocu.DOP_GROSS_VALUE
             , DOP_NET_VALUE_INCL = DetailDocu.DOP_NET_VALUE_INCL   -- Prix TTC
             , DOP_QTY = DetailDocu.DOP_QTY   -- Qte commandée
             , DOP_QTY_VALUE = DetailDocu.DOP_QTY
             , DOP_GROSS_UNIT_VALUE = DetailDocu.DOP_GROSS_UNIT_VALUE
             , DOP_BODY_TEXT = DetailDocu.DOP_BODY_TEXT   -- Texte commande
             , DOP_LONG_DESCRIPTION = DetailDocu.DOP_LONG_DESCRIPTION   -- Désignation produit
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_INTERFACE_POSITION_ID = DetailDocu.DOC_INTERFACE_POSITION_ID;
      end if;
    --
    exception
      when others then
        RAISE_APPLICATION_ERROR(-20001, sqlerrm);
    end;
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
    gauId     := null;
    --
    paraName  := 'GAUGE_FOR_CONTENT_TYPE_' || aCode;
    --
      -- Description du gabarit
    gauDescr  := DOC_EDI_FUNCTION.GetParamValue(paraName);

    --
    if gauDescr is null then
      PutError(PCS.PC_FUNCTIONS.TranslateWord('Valeur du paramètre inexistant') || ': ' || paraName);
    else
      -- Recherche Id du gabarit
      gauId  := GetGaugeFromDescr(gauDescr);
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
-- *****        Import SAP01 800               *****
-- *************************************************

  -- Recherche l'id d'un client en fonction de code ean
  procedure GetCustomId(paNumber in varchar2, PacThirdId out number)
  is
  begin
    WRITELOG('*GetCustomId', 0);

    begin
      select PAC_CUSTOM_PARTNER_ID
        into PacThirdId
        from PAC_CUSTOM_PARTNER
       where CUS_EAN_NUMBER = rtrim(paNumber);
    -- Fournisseur non Trouvé
    exception
      when no_data_found then
        begin
          -- Message d'erreur
          PutError(PCS.PC_FUNCTIONS.TranslateWord('Client non trouvé selon code EAN') || ' : ' || paNumber);
        end;
    end;
  end;

  -- Decode d'une ligne détail document import
  procedure DecodeDetailDocu
  is
    result boolean;
  begin
    WRITELOG('------------DECODEDETAILDOCU', 0);
    result  := true;

    -- Recherche Id du bien
    if result then
      PutRowPosition('17');
      DetailDocu.GCO_GOOD_ID  := GetGcoGoodId(DetailDocu.DOP_MAJOR_REFERENCE);
      result                  := DetailDocu.GCO_GOOD_ID is not null;
    end if;

    -- Délai demandé
    if result then
      PutRowPosition('76');
      DetailDocu.DOP_BASIS_DELAY  := PutInDate(DetailDocu.INTERM_DOP_BASIS_DELAY, 'DD.MM.YYYY');
      result                      := DetailDocu.DOP_BASIS_DELAY is not null;
    end if;

    -- Prix HT
    if result then
      PutRowPosition('96');
      DetailDocu.DOP_GROSS_VALUE  := PutInNumber(DetailDocu.INTERM_DOP_GROSS_VALUE, 'FM999999.00');
      result                      := DetailDocu.DOP_GROSS_VALUE is not null;
    end if;

    -- Prix TTC
    if result then
      PutRowPosition('106');
      DetailDocu.DOP_NET_VALUE_INCL  := PutInNumber(DetailDocu.INTERM_DOP_NET_VALUE_INCL, 'FM999999.00');
      result                         := DetailDocu.DOP_NET_VALUE_INCL is not null;
    end if;

    -- Quantité
    if result then
      PutRowPosition('126');
      DetailDocu.DOP_QTY  := PutInNumber(DetailDocu.INTERM_DOP_QTY, 'FM999999.0000');
      result              := DetailDocu.DOP_QTY is not null;
    end if;

    --
    if result then
      DetailDocu.DOP_POS_TEXT_1  := HeaderDocu.DOI_PARTNER_NUMBER || '/' || DetailDocu.INTERM_DOP_POS_NUMBER;
      DetailDocu.DOP_PDE_TEXT_1  := DetailDocu.DOP_POS_TEXT_1;
    end if;

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
         and rtrim(substr(DID_VALUE, 3, 10) ) = HeaderDocu.DOI_PARTNER_NUMBER
         and substr(DID_VALUE, 1, 2) = '02';

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
      -- Numéro de position
      DetailDocu.INTERM_DOP_POS_NUMBER      := substr(params.DID_VALUE, 13, 5);
      -- Numéro de produit
      DetailDocu.DOP_MAJOR_REFERENCE        := substr(params.DID_VALUE, 18, 18);
      -- Description produit
      DetailDocu.DOP_LONG_DESCRIPTION       := substr(params.DID_VALUE, 36, 40);
      -- Delai demandé
      DetailDocu.INTERM_DOP_BASIS_DELAY     := substr(params.DID_VALUE, 76, 10);
      -- NON UTILISE délai confirmé           := substr(params.DID_VALUE, 86,  10);
      -- Prix HT
      DetailDocu.INTERM_DOP_GROSS_VALUE     := substr(params.DID_VALUE, 96, 10);
      -- Prix TTC
      DetailDocu.INTERM_DOP_NET_VALUE_INCL  := substr(params.DID_VALUE, 106, 10);
      --  NON UTILISE Montant TVA             := substr(params.DID_VALUE, 116, 10);
      -- Qte commandée
      DetailDocu.INTERM_DOP_QTY             := substr(params.DID_VALUE, 126, 10);
      --  NON UTILISE No document MECAPRO     := substr(params.DID_VALUE, 136, 10);
        --  NON UTILISE statut traitement       := substr(params.DID_VALUE, 146, 3);
      -- Texte commande
      DetailDocu.DOP_BODY_TEXT              := substr(params.DID_VALUE, 149, 500);
      -- Décodage du détail
      DecodeDetailDocu;
      -- Ajout dans l'interface position
      InsertInterfacePosition;

      fetch DetailDocument
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
      PutRowPosition('1');
      HeaderDocu.DOC_GAUGE_ID  := GetGaugeId(HeaderDocu.INTERM_DOCU_TYPE);
      result                   := HeaderDocu.DOC_GAUGE_ID is not null;
    end if;

    -- Test format des dates
    if result then
      PutRowPosition('13');
      HeaderDocu.DOI_PARTNER_DATE  := PutInDate(HeaderDocu.INTERM_DOI_PARTNER_DATE, 'DD.MM.YYYY');
      result                       := HeaderDocu.DOI_PARTNER_DATE is not null;
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
             substr(DID_VALUE, 1, 2)
           , substr(DID_VALUE, 13, 10)
        into LineRec.DOC_EDI_IMPORT_JOB_DATA_ID
           ,   -- Pour la ligne
             DocumentRec.DOC_EDI_IMPORT_JOB_DATA_ID
           ,   -- Pour l'en-tête (mise à jour plus tard avec GENE)
             LineRec.DID_VALUE
           , LineRec.DID_LINE_NUMBER
           ,
             --
             -- Type de document -> gabarit
             HeaderDocu.INTERM_DOCU_TYPE
           ,
             -- Date du document
             HeaderDocu.INTERM_DOI_PARTNER_DATE
        from DOC_EDI_IMPORT_JOB_DATA
       where DOC_EDI_IMPORT_JOB_ID = SysRec.JOB_ID
         and rtrim(substr(DID_VALUE, 3, 10) ) = HeaderDocu.DOI_PARTNER_NUMBER
         and substr(DID_VALUE, 1, 2) = '01';

      -- Décodage de l'en-tête
      DecodeHeaderDocu;
      -- Ajout dans l'interface
      InsertInterface;
    --
    exception
      when no_data_found then
        DocumentRec.NEW_DOC_STOP  := false;
    end;
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
  end;

  -- Détection des documents pour import
  procedure HeaderDocuDetect
  is
    cursor HeaderDetect(paJobId number)
    is
      select rtrim(substr(DID_VALUE, 3, 10) ) dmtNumber
        from DOC_EDI_IMPORT_JOB_DATA
       where DOC_EDI_IMPORT_JOB_ID = paJobId
         and   -- Job en cours
             nvl(C_EDI_JOB_DATA_STATUS, ' ') <> 'GENE'
         and   -- Pas de génération effectuée
             substr(DID_VALUE, 38, 1) = 'N'
         and   -- Type New
             substr(DID_VALUE, 1, 2) = '01';   -- En-tête commande

    params HeaderDetect%rowtype;
  begin
    WRITELOG('------HEADERDOCUDETECT', 0);

    open HeaderDetect(SysRec.JOB_ID);

    fetch HeaderDetect
     into params;

    -- Parcours toutes les en-tête de documents du job
    while HeaderDetect%found loop
      -- Numéro de document attribué
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
        DOC_EDI_IMPORT.DeleteInterfaceRecords(DocumentRec.DOC_INTERFACE_ID);
        -- Inscription numéro interface dans le log
        PutMessage(PCS.PC_FUNCTIONS.TranslateWord('Document non traité') );
      else
        -- Document en ordre (pour statut de retour final à delphi)
        JobRec.NEW_DOC_OK  := true;
        -- Mise à jour des status, passage de en préparation à prêt
        DOC_EDI_IMPORT.UpdateInterfaceRecords(DocumentRec.DOC_INTERFACE_ID);
        -- Mise à jour de l'en-tête du document -> GENE
        UpdateDocHeaderRecord;
        -- Inscription numéro interface dans le log
        PutMessage(PCS.PC_FUNCTIONS.TranslateWord('Création de l''interface') || ' : ' || DocumentRec.NEW_DOI_NUMBER);
      end if;

      --
      fetch HeaderDetect
       into params;
    end loop;
  end;

  -- Decode d'une ligne entete de fichier import
  function DecodeHeaderFile
    return boolean
  is
    result    boolean;
    EanNumber varchar2(30);
  begin
    WRITELOG('--------DECODEHEADERFILE', 0);
    -- Nom du gabarit pour table INTERFACE
    JobRec.GAU_DESCR              := PCS.PC_CONFIG.GETCONFIG('DOC_EDI_CONFIG_GAUGE');
    -- Code EAN du client provenant des paramètres.
    JobRec.INTERM_CUS_EAN_NUMBER  := DOC_EDI_FUNCTION.GetParamValue('EAN_NUMBER');
    -- Recherche de l'id du client
    GetCustomId(JobRec.INTERM_CUS_EAN_NUMBER, JobRec.PAC_THIRD_ID);
    result                        := JobRec.PAC_THIRD_ID is not null;
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
    result  := DecodeHeaderFile;
    --
    return result;
  end;

  -- Import version 01
  procedure ImportV01
  is
    result boolean;
  begin
    WRITELOG('----IMPORTV01', 0);
    -- Pseudo entête du fichier, lecture client pour tous les documents du job
    result  := HeaderFile;

    -- Recherche et traitement complet de chaque document
    if result then
      HeaderDocuDetect;
    end if;
  end;

  -- Import800 SAP01
  procedure Import800
  is
    NoVersion varchar2(2);
  begin
    WRITELOG('--IMPORT800', 0);
    ImportV01;
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
      DOC_EDI_IMPORT.DeleteInterfaceRecords(DocumentRec.DOC_INTERFACE_ID);
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
    WRITELOG('IMPORT (DOC_EDI_IMPORT800)', 0);
    -- Init des variables du job
    InitVarJob;
    -- Recherche transfert
    DOC_EDI_FUNCTION.GetJob(SysRec.JOB_ID, glbEdiTypeId);
    -- Paramètres du transfert
    DOC_EDI_FUNCTION.FillParamsTable(glbEdiTypeId);
    -- Recherche de la fonction
    Import800;

    -- Retour de la valeur
    if SysRec.RETURN_VALUE is null then
      SysRec.RETURN_VALUE  := ReturnValue;
    end if;

    -- Retourne la valeur de retour des opérations
    DOC_EDI_IMPORT.SET_RETURN_VALUE(SYSREC.RETURN_VALUE);
  end;
end;
