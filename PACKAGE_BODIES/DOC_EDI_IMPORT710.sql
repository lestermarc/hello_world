--------------------------------------------------------
--  DDL for Package Body DOC_EDI_IMPORT710
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_EDI_IMPORT710" 
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

  procedure HeadProc(paTitle varchar2)
  is
  begin
    DOC_EDI_IMPORT.HEADPROC(paTitle);
  end;

  procedure FootProc(paTitle varchar2)
  is
  begin
    DOC_EDI_IMPORT.FOOTPROC(paTitle);
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
  procedure PutRowPosition(aPos integer)
  is
  begin
    HeadProc('PutRowPosition');
    --
    LineRec.NEW_ROW_POSITION  := DOC_EDI_IMPORT.GetATokenPos(LineRec.DID_VALUE, '|', aPos);
    --
    FootProc('PutRowPosition');
  end;

--------------------
-- Initialisation --
--------------------
  procedure InitVarSys
  -- Initialisation des variables système
  is
  begin
    -- IMPORTANT : Pas de WRITELOG car JOB_ID n'est pas initialisé
    SysRec.JOB_ID           := null;
    SysRec.DOC_EDI_TYPE_ID  := null;
    SysRec.RETURN_VALUE     := null;
  end;

  -- Init des variables générales pour toutes les lignes d'un job
  procedure InitVarJob
  is
  begin
    HeadProc('InitVarJob');
    --
    -- Nom du gabarit pour table INTERFACE
    JobRec.GAU_DESCR                       := null;
    -- Pas de document ok
    JobRec.NEW_DOC_OK                      := false;
    -- Pas de document en erreur
    JobRec.NEW_DOC_NOT_OK                  := false;
    -- Gabarit
    JobRec.INTERM_GAU_DESCR_PAID_AMEX      := null;
    JobRec.INTERM_GAU_DESCR_PAID_VISA      := null;
    JobRec.INTERM_GAU_DESCR_PAID_EUROCARD  := null;
    JobRec.INTERM_GAU_DESCR_TO_BE_PAID     := null;
    JobRec.DOC_GAUGE_ID_PAID_AMEX          := null;
    JobRec.DOC_GAUGE_ID_PAID_VISA          := null;
    JobRec.DOC_GAUGE_ID_PAID_EUROCARd      := null;
    JobRec.DOC_GAUGE_ID_TO_BE_PAID         := null;
    --
    FootProc('InitVarJob');
  end;

  -- Init des variables générales pour le traiement d'un document d'un job
  procedure InitDocumentRec
  is
  begin
    HeadProc('InitDocumentRec');
    --
    -- Id interface non initialisé
    DocumentRec.DOC_INTERFACE_ID            := null;
    -- Document un ordre
    DocumentRec.NEW_DOC_STOP                := false;
    -- Numéro du document interface attribué
    DocumentRec.NEW_DOI_NUMBER              := null;
    -- Id client
    DocumentRec.PAC_THIRD_ID                := null;
    -- No client et facture
    DocumentRec.ORIGINAL_ORDER              := null;
    -- Mode de paiement
    DocumentRec.PAYEMENT                    := null;
    -- Id du record faisant office de headerdocu
    DocumentRec.DOC_EDI_IMPORT_JOB_DATA_ID  := null;
    -- Gabarit du document
    DocumentRec.DOC_GAUGE_ID                := null;
    --
    FootProc('InitDocumentRec');
  end;

  -- Init des variables pour la ligne data en cours
  procedure InitVarLine
  is
  begin
    HeadProc('InitVarLine');
    --
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
    LineRec.NEW_ROW_POSITION            := null;
    --
    FootProc('InitVarLine');
  end;

  -- Init des champs du détail
  procedure InitDetailRec
  is
  begin
    HeadProc('InitDetailRec');
    --
    -- Id de la position de l'interface
    DetailDocu.DOC_INTERFACE_POSITION_ID  := null;
    -- Type de détail
    DetailDocu.C_GAUGE_TYPE_POS           := null;
    -- Qte
    DetailDocu.INTERM_DOP_QTY             := null;
    DetailDocu.DOP_QTY                    := null;
    -- Produit
    DetailDocu.DOP_MAJOR_REFERENCE        := null;
    DetailDocu.GCO_GOOD_ID                := null;
    -- Copie du gabarit  du document sur le détail
    DetailDocu.DOC_GAUGE_ID               := null;
    --
    FootProc('InitDetailRec');
  end;

  function ConvertState(paState boolean)
    return integer
  -- Converti l'état boolean en integer
  -- True  -> 1
  -- False -> 0
  is
    result integer;
  begin
    if paState then
      result  := 1;
    else
      result  := 0;
    end if;

    --
    return result;
  end;

  procedure PutStatus(paStatus integer)
  -- Mise à jour du statut d'une ligne JOB DATA
  -- 0 -> ERREUR
  -- 1 -> OK
  -- 2 -> WARNING
  -- 3 -> UNDEF
  is
  begin
    HeadProc('PutStatus ' || paStatus);

    --
    if paStatus = 1 then   -- En ordre
      LineRec.C_EDI_JOB_DATA_STATUS  := 'OK';
    elsif paStatus = 0 then   -- Erreur
      LineRec.C_EDI_JOB_DATA_STATUS  := 'ERROR';   -- Erreur -> suppression des ajout dans l'interface
      DocumentRec.NEW_DOC_STOP       := true;
    elsif paStatus = 2 then   -- Avertissement
      LineRec.C_EDI_JOB_DATA_STATUS  := 'WARNING';
    else   -- Ligne non traitée
      LineRec.C_EDI_JOB_DATA_STATUS  := 'UNDEF';
    end if;

    --
    -- Mise du status et de message d'erreur du job data en cours
    -- Provient en principe suite à un PutError
    if LineRec.DOC_EDI_IMPORT_JOB_DATA_ID is not null then
      update DOC_EDI_IMPORT_JOB_DATA
         set C_EDI_JOB_DATA_STATUS = LineRec.C_EDI_JOB_DATA_STATUS
           , DID_ERROR_TEXT = LineRec.DID_ERROR_TEXT
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_EDI_IMPORT_JOB_DATA_ID = LineRec.DOC_EDI_IMPORT_JOB_DATA_ID;
    end if;

    --
    FootProc('PutStatus ' || LineRec.C_EDI_JOB_DATA_STATUS);
  end;

  -- Insertion des données dans l'interface document
  procedure InsertInterface
  is
  begin
    if not DocumentRec.NEW_DOC_STOP then
      begin
        HeadProc('InsertInterface');
        --
        -- Création d'un enregistrement avec valeurs par défaut
        DOC_INTERFACE_CREATE.CREATE_INTERFACE(DocumentRec.PAC_THIRD_ID
                                            ,   -- IN Id du client
                                              JobRec.GAU_DESCR
                                            ,   -- IN Nom du gabarit d'initialisation
                                              DocumentRec.DOC_GAUGE_ID
                                            ,   -- IN Id du gabarit
                                              '201'
                                            ,   -- IN Edi
                                              DocumentRec.NEW_DOI_NUMBER
                                            ,   -- OUT Numéro d'interface
                                              DocumentRec.DOC_INTERFACE_ID
                                             );   -- OUT Id de l'interface

        -- Mise à jour de l'interface avec valeurs spécifiques
        update DOC_INTERFACE
           set DOI_PROTECTED = 0   -- Pas de protection
         where DOC_INTERFACE_ID = DocumentRec.DOC_INTERFACE_ID;
      --
      exception
        when others then
          RAISE_APPLICATION_ERROR(-20001, sqlerrm);
      end;

      --
      FootProc('InsertInterface');
    end if;
  end;

  -- Insertion des données dans l'interface position
  procedure InsertInterfacePosition
  is
  begin
    if not DocumentRec.NEW_DOC_STOP then
      begin
        HeadProc('InsertInterfacePosition');
        --
        -- Détermine l'id de l'interface position
        DOC_INTERFACE_POSITION_CREATE.CREATE_INTERFACE_POSITION(DocumentRec.DOC_INTERFACE_ID
                                                              ,   -- IN ID de l'interface
                                                                JobRec.GAU_DESCR
                                                              ,   -- IN Nom du gabarit d'initialisation
                                                                DetailDocu.DOC_GAUGE_ID
                                                              ,   -- IN Id du gabarit
                                                                DetailDocu.C_GAUGE_TYPE_POS
                                                              ,   -- IN Type de position : 1
                                                                DetailDocu.DOC_INTERFACE_POSITION_ID
                                                               );   -- OUT
        -- Mise a jour interface position en fonction du produit
        DOC_INTERFACE_POSITION_CREATE.UPDATE_INTERFACE_POSITION(DocumentRec.DOC_INTERFACE_ID, DetailDocu.DOC_INTERFACE_POSITION_ID, DetailDocu.GCO_GOOD_ID);

        -- Mise à jour interface position en fonction valeurs spécifiques
        update DOC_INTERFACE_POSITION
           set DOP_BODY_TEXT = DetailDocu.INTERM_TEXT
             , DOP_QTY = DetailDocu.DOP_QTY
             , DOP_QTY_VALUE = DetailDocu.DOP_QTY
             , DOP_POS_TEXT_1 = DetailDocu.INTERM_DELIVERY_NR
             , DOP_POS_TEXT_2 = DetailDocu.INTERM_SHOP_CODE
             , DOP_POS_TEXT_3 = DetailDocu.INTERM_DELIVERY_DATE
             ,
               --
               DOP_INCLUDE_TAX_TARIFF = 1
             ,
               --
               DOP_NET_VALUE_INCL = DetailDocu.POS_NET_VALUE_INCL
             , DOP_NET_VALUE_EXCL = DetailDocu.POS_NET_VALUE_INCL -(DetailDocu.POS_NET_VALUE_INCL /( (10000 /(100 * DetailDocu.VAT_RATE) ) + 1) )
             , DOP_GROSS_VALUE = DetailDocu.POS_NET_VALUE_INCL
             , DOP_GROSS_UNIT_VALUE = DetailDocu.POS_NET_VALUE_INCL / decode(DOP_QTY, 0, 1, DOP_QTY)
             ,
               --
               DOP_DISCOUNT_RATE = 0
             , STM_STOCK_ID = 10645
             , STM_LOCATION_ID = null
             ,
               --
               DOP_POS_DECIMAL_1 = DetailDocu.TAX_1
             , DOP_POS_DECIMAL_2 = DetailDocu.TAX_2
             , DOP_POS_DECIMAL_3 = DetailDocu.VAT_RATE
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where DOC_INTERFACE_POSITION_ID = DetailDocu.DOC_INTERFACE_POSITION_ID;
      --
      exception
        when others then
          RAISE_APPLICATION_ERROR(-20001, sqlerrm);
      end;

      --
      FootProc('InsertInterfacePosition');
    end if;
  end;

  -- Mise à jour des enregistrements sans erreur en générés
  procedure UpdateOKRecords
  is
  begin
    HeadProc('UPDATEOKRECORDS');

    --
    update DOC_EDI_IMPORT_JOB_DATA
       set C_EDI_JOB_DATA_STATUS = 'GENE'
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_EDI_IMPORT_JOB_ID = SysRec.JOB_ID
       and DOC_EDI_IMPORT.GetAToken(DID_VALUE, '|', 2) = DocumentRec.ORIGINAL_ORDER
       and DOC_EDI_IMPORT.GetAToken(DID_VALUE, '|', 10) = DocumentRec.PAYEMENT;

    FootProc('UPDATEOKRECORDS');
  end;

  -- Détermine le valeur de retour en fonction des états ok et not_ok
  -- 0 Pas de document traité
  -- 1 Tous les documents généré
  -- 2 Documents ok + Documents en erreur
  -- 3 Tous les document en error
  function ReturnValue
    return integer
  is
    result integer;
  begin
    HeadProc('ReturnValue');

    --
    if JobRec.NEW_DOC_OK then
      if JobRec.NEW_DOC_NOT_OK then
        -- Partiellement ok
        result  := 2;
      else
        -- Tous les documents ok
        result  := 1;
      end if;
    else
      if JobRec.NEW_DOC_NOT_OK then
        -- Tous les documents en erreur
        result  := 3;
      else
        -- Aucun document détecté
        result  := 0;
      end if;
    end if;

    --
    FootProc('ReturnValue');
    return result;
  end;

  procedure GetCustomId(paNumber in varchar2, PacThirdId out number)
  -- Recherche l'id d'un client
  is
  begin
    HeadProc('GetCustomId');
    --
    PacThirdId  := null;

    --
    -- Si Numéro du client
    if paNumber is null then
      PutError(PCS.PC_FUNCTIONS.TranslateWord('Numéro du client non saisi') );
    else
      begin
        select PAC_PERSON_ID
          into PacThirdId
          from PAC_PERSON
         where PER_KEY1 = rtrim(paNumber);
      -- Client non trouvé
      exception
        when no_data_found then
          -- Message d'erreur
          PutError(PCS.PC_FUNCTIONS.TranslateWord('Client non trouvé selon clé 1') || ' : ' || paNumber);
        when others then
          PutError(sqlerrm);
      end;
    end if;

    --
    FootProc('GetCustomId');
  end;

  function GetGcoGoodId(aReference varchar2)
    return number
  -- Retourne l'id d'un bien en fonction de sa référence
  is
    GcoGoodId number(12);
  begin
    HeadProc('GetGcoGoodId');
    --
    GcoGoodId  := null;

    begin
      select GCO_GOOD_ID
        into GcoGoodId
        from GCO_GOOD
       where GOO_MAJOR_REFERENCE = rtrim(aReference);
    exception
      -- Bien non trouvé
      when no_data_found then
        -- Message d'erreur
        PutError(PCS.PC_FUNCTIONS.TranslateWord('Bien non trouvé') || ' : ' || aReference);
      when others then
        PutError(sqlerrm);
    end;

    --
    FootProc('GetGcoGoodId');
    return GcoGoodId;
  end;

  -- Détermine l'Id d'un gabarit en fonction de sa description.
  -- Si l'id de retoure est 0, cela signifie que le gabarit n'a pas été trouvé.
  function GetGaugeFromDescr(aDescr varchar2)
    return number
  is
    gauId number(12);
  begin
    HeadProc('GetGaugeFromDescr');

    --
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
      when others then
        PutError(sqlerrm);
    end;

    --
    FootProc('GetGaugeFromDescr');
    return gauId;
  end;

-- *************************************************
-- *****        Import 710                     *****
-- *************************************************

  -- Decode d'une ligne détail document import
  function DecodeDetailDocu
    return boolean
  is
    result boolean;
    Step   number;
  begin
    HeadProc('DECODEDETAILDOCU');
    --
    result  := true;
    Step    := 0;

    --
    begin
      Step                           := 1;
      PutRowPosition(5);
      DetailDocu.DOP_QTY             := to_number(DetailDocu.INTERM_DOP_QTY);
      --
      Step                           := 2;
      PutRowPosition(6);
      DetailDocu.POS_NET_VALUE_INCL  := to_number(DetailDocu.INTERM_POS_NET_VALUE_INCL);
      --
      Step                           := 3;
      PutRowPosition(8);
      DetailDocu.TAX_1               := to_number(DetailDocu.INTERM_TAX_1);
      --
      Step                           := 4;
      PutRowPosition(9);
      DetailDocu.TAX_2               := to_number(DetailDocu.INTERM_TAX_2);
      --
      Step                           := 5;
      PutRowPosition(7);
      DetailDocu.VAT_RATE            := to_number(DetailDocu.INTERM_VAT_RATE);
    --
    exception
      when others then   --Invalid_Number THEN
        result  := false;

        --
        if Step = 1 then
          PutError(PCS.PC_FUNCTIONS.TranslateWord('Qté erronée') );
        elsif Step = 2 then
          PutError(PCS.PC_FUNCTIONS.TranslateWord('Montant erroné') );
        elsif Step = 3 then
          PutError(PCS.PC_FUNCTIONS.TranslateWord('Frais 1 erroné') );
        elsif Step = 4 then
          PutError(PCS.PC_FUNCTIONS.TranslateWord('Frais 2 erroné') );
        elsif Step = 5 then
          PutError(PCS.PC_FUNCTIONS.TranslateWord('TVA erronée') );
        end if;
    end;   -- Exception

    --
    -- Test le shop code - lien avec un produit
    PutRowPosition(3);

    if result then
      if DetailDocu.INTERM_SHOP_CODE = '1' then
        DetailDocu.GCO_GOOD_ID  := GetGcoGoodId(DOC_EDI_FUNCTION.GetParamValue('GOOD_FOR_STORE1') );
      elsif DetailDocu.INTERM_SHOP_CODE = '2' then
        DetailDocu.GCO_GOOD_ID  := GetGcoGoodId(DOC_EDI_FUNCTION.GetParamValue('GOOD_FOR_STORE2') );
      elsif DetailDocu.INTERM_SHOP_CODE = '3' then
        DetailDocu.GCO_GOOD_ID  := GetGcoGoodId(DOC_EDI_FUNCTION.GetParamValue('GOOD_FOR_STORE3') );
      elsif DetailDocu.INTERM_SHOP_CODE = '4' then
        DetailDocu.GCO_GOOD_ID  := GetGcoGoodId(DOC_EDI_FUNCTION.GetParamValue('GOOD_FOR_STORE4') );
      elsif DetailDocu.INTERM_SHOP_CODE = '5' then
        DetailDocu.GCO_GOOD_ID  := GetGcoGoodId(DOC_EDI_FUNCTION.GetParamValue('GOOD_FOR_STORE5') );
      elsif DetailDocu.INTERM_SHOP_CODE = '6' then
        DetailDocu.GCO_GOOD_ID  := GetGcoGoodId(DOC_EDI_FUNCTION.GetParamValue('GOOD_FOR_STORE6') );
      elsif DetailDocu.INTERM_SHOP_CODE = 'NULL' then
        DetailDocu.GCO_GOOD_ID  := GetGcoGoodId(DOC_EDI_FUNCTION.GetParamValue('GOOD_FOR_STORE1') );
      end if;

      --
      if DetailDocu.GCO_GOOD_ID is null then
        PutError(PCS.PC_FUNCTIONS.TranslateWord('Vérifier la valeur du paramètre GOOD_FOR_STORE' || DetailDocu.INTERM_SHOP_CODE) );
        result  := false;
      end if;
    end if;

    --
    PutStatus(ConvertState(result) );
    --
    FootProc('DECODEDETAILDOCU');
    return result;
  end;

  procedure Detail_Docu
  is
    cursor detaildocument
    is
      select   doc_edi_import_job_data_id
             , did_value
             , did_line_number
          from doc_edi_import_job_data
         where doc_edi_import_job_id = sysrec.job_id
           and DOC_EDI_IMPORT.GetAToken(DID_VALUE, '|', 2) = DocumentRec.ORIGINAL_ORDER
           and DOC_EDI_IMPORT.GetAToken(DID_VALUE, '|', 10) = DocumentRec.PAYEMENT
      order by did_line_number;

    params detaildocument%rowtype;
    tax_1  number(15, 2);
    tax_2  number(15, 2);
  begin
    HeadProc('DETAIL_DOCU');
    --
    tax_1  := 0;
    tax_2  := 0;

    --
    open DetailDocument;

    fetch DetailDocument
     into params;

    while DetailDocument%found loop
      InitVarLine;
      InitDetailRec;
      -- Id du record
      LineRec.DOC_EDI_IMPORT_JOB_DATA_ID    := params.DOC_EDI_IMPORT_JOB_DATA_ID;
      -- Ligne
      LineRec.DID_VALUE                     := params.DID_VALUE;
      -- Numéro de ligne
      LineRec.DID_LINE_NUMBER               := params.DID_LINE_NUMBER;
      DetailDocu.C_GAUGE_TYPE_POS           := '1';
      DetailDocu.DOC_GAUGE_ID               := DocumentRec.DOC_GAUGE_ID;
      --
      DetailDocu.INTERM_DELIVERY_NR         := DOC_EDI_IMPORT.GetAToken(LineRec.DID_VALUE, '|', 1);
      DetailDocu.INTERM_ORDER_NR            := DocumentRec.ORIGINAL_ORDER;
      DetailDocu.INTERM_SHOP_CODE           := DOC_EDI_IMPORT.GetAToken(LineRec.DID_VALUE, '|', 3);
      DetailDocu.INTERM_TEXT                := DOC_EDI_IMPORT.GetAToken(LineRec.DID_VALUE, '|', 4);
      DetailDocu.INTERM_DOP_QTY             := DOC_EDI_IMPORT.GetAToken(LineRec.DID_VALUE, '|', 5);
      DetailDocu.INTERM_POS_NET_VALUE_INCL  := DOC_EDI_IMPORT.GetAToken(LineRec.DID_VALUE, '|', 6);
      DetailDocu.INTERM_VAT_RATE            := DOC_EDI_IMPORT.GetAToken(LineRec.DID_VALUE, '|', 7);
      DetailDocu.INTERM_TAX_1               := DOC_EDI_IMPORT.GetAToken(LineRec.DID_VALUE, '|', 8);
      DetailDocu.INTERM_TAX_2               := DOC_EDI_IMPORT.GetAToken(LineRec.DID_VALUE, '|', 9);
      DetailDocu.INTERM_PAYEMENT_METHOD     := DocumentRec.PAYEMENT;
      DetailDocu.INTERM_TRANSACTION_NR      := DOC_EDI_IMPORT.GetAToken(LineRec.DID_VALUE, '|', 11);
      DetailDocu.INTERM_DELIVERY_DATE       := DOC_EDI_IMPORT.GetAToken(LineRec.DID_VALUE, '|', 12);

      --
      -- Décodage du détail
      if DecodeDetailDocu then
        InsertInterfacePosition;   -- Ajout dans l'interface position
        tax_1  := DetailDocu.TAX_1;
        tax_2  := DetailDocu.TAX_2;
      else
        DocumentRec.New_Doc_Stop  := true;
      end if;

      --
      fetch DetailDocument
       into params;
    end loop;

    --
    if not DocumentRec.New_Doc_Stop then
      if tax_1 <> 0 then   -- insertion frais 1
        PutMessage('TAXE 1 détectée');
        DetailDocu.DOP_QTY             := 1;
        DetailDocu.POS_NET_VALUE_INCL  := tax_1;
        DetailDocu.VAT_RATE            := 7.60;
        DetailDocu.GCO_GOOD_ID         := GetGcoGoodId(DOC_EDI_FUNCTION.GETPARAMVALUE('GOOD_FOR_TAX1') );
        PutMessage(to_char(DetailDocu.GCO_GOOD_ID) );
        DetailDocu.INTERM_TEXT         := null;
        DetailDocu.TAX_1               := 0;
        DetailDocu.TAX_2               := 0;
        InsertInterfacePosition;
      end if;

      --
      if DetailDocu.TAX_2 <> 0 then   -- insertion frais 2
        PutMessage('TAXE 2 détectée');
        DetailDocu.DOP_QTY             := 1;
        DetailDocu.POS_NET_VALUE_INCL  := tax_2;
        DetailDocu.VAT_RATE            := 7.60;
        DetailDocu.GCO_GOOD_ID         := GetGcoGoodId(DOC_EDI_FUNCTION.GETPARAMVALUE('GOOD_FOR_TAX2') );
        PutMessage(to_char(DetailDocu.GCO_GOOD_ID) );
        DetailDocu.INTERM_TEXT         := null;
        DetailDocu.TAX_1               := 0;
        DetailDocu.TAX_2               := 0;
        InsertInterfacePosition;
      end if;
    end if;

    --
    FootProc('DETAIL_DOCU');
  end;

  function Header_Docu
    return boolean
  is
    result boolean;
  begin
    HeadProc('HEADER_DOCU');
    --
    InitVarLine;

    --
    -- Recherche de la pseudo-entête (doit forcément exister)
    --
    select DOC_EDI_IMPORT_JOB_DATA_ID
         , DID_VALUE
         , DID_LINE_NUMBER
      into LineRec.DOC_EDI_IMPORT_JOB_DATA_ID
         , LineRec.DID_VALUE
         , LineRec.DID_LINE_NUMBER
      from DOC_EDI_IMPORT_JOB_DATA
     where DOC_EDI_IMPORT_JOB_DATA_ID = DocumentRec.DOC_EDI_IMPORT_JOB_DATA_ID;

    --
    -- Pseudo décodage
    --
    -- Gabarit en fonction du paiement
    PutRowPosition(10);

    if DocumentRec.PAYEMENT = 'NULL' then
      DocumentRec.DOC_GAUGE_ID  := JobRec.DOC_GAUGE_ID_TO_BE_PAID;
    elsif DocumentRec.PAYEMENT = '1' then
      DocumentRec.DOC_GAUGE_ID  := JobRec.DOC_GAUGE_ID_PAID_AMEX;
    elsif DocumentRec.PAYEMENT = '2' then
      DocumentRec.DOC_GAUGE_ID  := JobRec.DOC_GAUGE_ID_PAID_EUROCARD;
    elsif DocumentRec.PAYEMENT = '3' then
      DocumentRec.DOC_GAUGE_ID  := JobRec.DOC_GAUGE_ID_PAID_VISA;
    else
      null;   --JPZ
    end if;

    --
    -- Id du tiers
    PutRowPosition(2);
    GetCustomId(DocumentRec.ORIGINAL_ORDER, DocumentRec.PAC_THIRD_ID);
    --
    result  := DocumentRec.PAC_THIRD_ID is not null;

    --
    if result then
      InsertInterface;
    else
      PutStatus(0);
    end if;

    --
    FootProc('HEADER_DOCU');
    return result;
  end;

  procedure ProcessDocu
  -- Traitement général du document
  is
    result boolean;
  begin
    HeadProc('PROCESSDOCU');
    --
    -- Traitement de l'entete
    result  := Header_docu;

    --
    -- Traitement du détail
    if result then
      Detail_Docu;
    end if;

    --
    FootProc('PROCESSDOCU');
  end;

  -- Détection des documents pour import
  procedure HeaderDocuDetect
  is
    -- Recherche des pseudo-header dans l'ordre des numéros de lignes
    -- (c'est pour cela que la sql parait complexe )
    cursor HeaderDetect(paJobId number)
    is
      select   B.*
          from DOC_EDI_IMPORT_JOB_DATA A
             , (select   DOC_EDI_IMPORT.GetAToken(DID_VALUE, '|', 2) ORIGINAL_ORDER
                       , DOC_EDI_IMPORT.GetAToken(DID_VALUE, '|', 10) PAYEMENT
                       , min(DOC_EDI_IMPORT_JOB_DATA_ID) DOC_EDI_IMPORT_JOB_DATA_ID
                    from DOC_EDI_IMPORT_JOB_DATA
                   where DOC_EDI_IMPORT_JOB_ID = paJobId
                     and nvl(C_EDI_JOB_DATA_STATUS, ' ') <> 'GENE'
                group by DOC_EDI_IMPORT.GetAToken(DID_VALUE, '|', 2)
                       , DOC_EDI_IMPORT.GetAToken(DID_VALUE, '|', 10) ) B
         where A.DOC_EDI_IMPORT_JOB_DATA_ID = B.DOC_EDI_IMPORT_JOB_DATA_ID
      order by A.DID_LINE_NUMBER;

    params HeaderDetect%rowtype;
  begin
    HeadProc('HEADERDOCUDETECT');

    --
    open HeaderDetect(SysRec.JOB_ID);

    fetch HeaderDetect
     into params;

    -- Parcours toutes les en-tête de documents du job
    while HeaderDetect%found loop
      InitVarLine;
      -- Init des variables de l'entete
      InitDocumentRec;
      -- Fait également office de HEADER_DOCU
      --
      -- Numéro de document attribué
      DocumentRec.ORIGINAL_ORDER              := Params.ORIGINAL_ORDER;
      -- Mode de paiement
      DocumentRec.PAYEMENT                    := Params.PAYEMENT;
      -- Id du record considéré comme header
      DocumentRec.DOC_EDI_IMPORT_JOB_DATA_ID  := Params.DOC_EDI_IMPORT_JOB_DATA_ID;
      --
      PutMessage(PCS.PC_FUNCTIONS.TranslateWord('Traitement du document') || ' : ' || DocumentRec.ORIGINAL_ORDER);
      --
      -- Traitement d'un document complet
      ProcessDocu;

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
        -- Mise à jour  OK -> GENE
        UpdateOkRecords;
        -- Inscription numéro interface dans le log
        PutMessage(PCS.PC_FUNCTIONS.TranslateWord('Création de l''interface') || ' : ' || DocumentRec.NEW_DOI_NUMBER);
      end if;

      --
      fetch HeaderDetect
       into params;
    end loop;

    --
    FootProc('HEADERDOCUDETECT');
  end HeaderDocuDetect;

  function DecodeHeaderFile
    return boolean
  -- Decode entete de fichier import
  -- Dans ce cas la ligne est fictive; elle ne provient que des paramètres ou configuration
  is
    result boolean;
  begin
    HeadProc('DECODEHEADERFILE');
    --
    result            := true;
    --
    -- Nom du gabarit dans la configuration pour table INTERFACE (doit exister)
    JobRec.GAU_DESCR  := PCS.PC_CONFIG.GETCONFIG('DOC_EDI_CONFIG_GAUGE');

    --
    -- test des gabarits des paramètres
    --
    if result then
      -- Gabarit provenant des paramètres
      JobRec.INTERM_GAU_DESCR_PAID_AMEX      := DOC_EDI_FUNCTION.GetParamValue('GAUGE_DESCRIPTION_PAID_AMEX');
      JobRec.DOC_GAUGE_ID_PAID_AMEX          := GetGaugeFromDescr(JobRec.INTERM_GAU_DESCR_PAID_AMEX);
      JobRec.INTERM_GAU_DESCR_PAID_VISA      := DOC_EDI_FUNCTION.GetParamValue('GAUGE_DESCRIPTION_PAID_VISA');
      JobRec.DOC_GAUGE_ID_PAID_VISA          := GetGaugeFromDescr(JobRec.INTERM_GAU_DESCR_PAID_VISA);
      JobRec.INTERM_GAU_DESCR_PAID_EUROCARD  := DOC_EDI_FUNCTION.GetParamValue('GAUGE_DESCRIPTION_PAID_EUROCARD');
      JobRec.DOC_GAUGE_ID_PAID_EUROCARD      := GetGaugeFromDescr(JobRec.INTERM_GAU_DESCR_PAID_EUROCARD);
      JobRec.INTERM_GAU_DESCR_TO_BE_PAID     := DOC_EDI_FUNCTION.GetParamValue('GAUGE_DESCRIPTION_TO_BE_PAID');
      JobRec.DOC_GAUGE_ID_TO_BE_PAID         := GetGaugeFromDescr(JobRec.INTERM_GAU_DESCR_TO_BE_PAID);
      -- Test existence
      result                                 :=
            JobRec.DOC_GAUGE_ID_TO_BE_PAID is not null
        and JobRec.DOC_GAUGE_ID_PAID_VISA is not null
        and JobRec.DOC_GAUGE_ID_PAID_AMEX is not null
        and JobRec.DOC_GAUGE_ID_PAID_EUROCARD is not null;
    end if;

    --
    FootProc('DECODEHEADERFILE');
    return result;
  end;

  function HeaderFile
    return boolean
  -- Traitement de la pseudo en-tête du fichier import
  is
    result boolean;
  begin
    HeadProc('HEADERFILE');
    --
    InitVarLine;
    result  := DecodeHeaderFile;
    --
    FootProc('HEADERFILE');
    return result;
  end;

  procedure Import710
  -- Importation 710
  is
    result boolean;
  begin
    begin
      HeadProc('IMPORT710');
      --
      -- Pseudo entête du fichier, lecture du gabarit à partir des paramètres
      result  := HeaderFile;

      --
      -- Recherche des documents (header)
      if result then
        HeaderDocuDetect;
      end if;
    --
    -- Problème divers
    exception
      when others then
        -- Erreur technique - retour de la fonction
        SysRec.RETURN_VALUE  := 9;
        -- Erreur dans le log
        PutError(sqlerrm);
        -- Maj statut de la ligne ERROR
        PutStatus(0);
        -- Suppression des enregistrements de l'interface
        DOC_EDI_IMPORT.DeleteInterfaceRecords(DocumentRec.DOC_INTERFACE_ID);
    end;

    --
    FootProc('IMPORT710');
  end;

  procedure UpdateTagValue
  -- Mise à jour du tag en fonction du numéro de commande
  is
  begin
    update DOC_EDI_IMPORT_JOB_DATA
       set DID_TAG = DOC_EDI_IMPORT.GetAToken(DID_VALUE, '|', 2)
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_EDI_IMPORT_JOB_ID = SysRec.JOB_ID;
  end;

  procedure Import
  -- Importation générale
  is
  begin
    -- Init des variables systeme
    InitVarSys;
    -- Id du job
    SysRec.JOB_ID  := DOC_EDI_IMPORT.GET_JOBID;
    -- Journal
    HeadProc('IMPORT (DOC_EDI_IMPORT710)');
    -- Init des variables du job
    InitVarJob;
    -- Recherche transfert
    DOC_EDI_FUNCTION.GetJob(SysRec.JOB_ID, SysRec.DOC_EDI_TYPE_ID);
    -- Paramètres du transfert
    DOC_EDI_FUNCTION.FillParamsTable(SysRec.DOC_EDI_TYPE_ID);
    -- Mise à jour du TAG de chaque ligne
    UpdateTagValue;
    -- Recherche de la fonction
    Import710;

    --
    -- Retour de la valeur
    --
    if SysRec.RETURN_VALUE is null then
      SysRec.RETURN_VALUE  := ReturnValue;
    end if;

    -- Retourne la valeur de retour des opérations
    DOC_EDI_IMPORT.SET_RETURN_VALUE(SYSREC.RETURN_VALUE);
    --
    FootProc('IMPORT (DOC_EDI_IMPORT710)');
  end;
end;
