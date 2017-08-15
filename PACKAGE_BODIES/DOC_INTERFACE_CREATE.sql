--------------------------------------------------------
--  DDL for Package Body DOC_INTERFACE_CREATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_INTERFACE_CREATE" 
is
  /**
  * Description
  *
  *     Création de l'interface document pour le tiers passé en paramètre
  *
  */
  procedure CREATE_INTERFACE(
    pThirdId         in     DOC_INTERFACE.PAC_THIRD_ID%type   /* Partenaire */
  , pConfigGaugeName in     DOC_GAUGE.GAU_DESCRIBE%type   /* Gabarit de configuration de l'interface document */
  , pDfltGaugeId     in     DOC_GAUGE.DOC_GAUGE_ID%type   /* ID du gabarit de destination */
  , pInterfaceOrigin in     DOC_INTERFACE.C_DOC_INTERFACE_ORIGIN%type   /* Origine de l'interface */
  , pInterfaceNumber in out DOC_INTERFACE.DOI_NUMBER%type   /* Numéro de la nouvelle interface */
  , pNewInterfaceId  in out DOC_INTERFACE.DOC_INTERFACE_ID%type   /* Id de la nouvelle interface document */
  , c_admin_domain   in     doc_gauge.c_admin_domain%type default '2'
  )
  is
    /*Déclaration variables de réception des données de recherche*/
    vPerName                     DOC_INTERFACE.DOI_PER_NAME%type;
    vPerShortName                DOC_INTERFACE.DOI_PER_SHORT_NAME%type;
    vPerKey1                     DOC_INTERFACE.DOI_PER_KEY1%type;
    vPerKey2                     DOC_INTERFACE.DOI_PER_KEY2%type;
    vDicTariffId                 DOC_INTERFACE.DIC_TARIFF_ID%type;
    vPacPaymentCondId            DOC_INTERFACE.PAC_PAYMENT_CONDITION_ID%type;
    vPacSendingCondId            DOC_INTERFACE.PAC_SENDING_CONDITION_ID%type;
    vDicTypeSubId                DOC_INTERFACE.DIC_TYPE_SUBMISSION_ID%type;
    vAcsVatDetAccountId          DOC_INTERFACE.ACS_VAT_DET_ACCOUNT_ID%type;
    vAcsFinAccSPaymentId         DOC_INTERFACE.ACS_FIN_ACC_S_PAYMENT_ID%type;
    vAcsFinancialCurrencyId      DOC_INTERFACE.ACS_FINANCIAL_CURRENCY_ID%type;
    vPacAdressId                 DOC_INTERFACE.PAC_ADDRESS_ID%type;
    vPacRepresentativeId         DOC_INTERFACE.PAC_REPRESENTATIVE_ID%type;
    vCTarificationMode           PAC_CUSTOM_PARTNER.C_TARIFFICATION_MODE%type;
    vDicComplementaryDataId      PAC_CUSTOM_PARTNER.DIC_COMPLEMENTARY_DATA_ID%type;
    vCDeliveryTyp                PAC_CUSTOM_PARTNER.C_DELIVERY_TYP%type;
    vDfltGaugeId                 DOC_GAUGE.DOC_GAUGE_ID%type;
    vDfltGaugeDicTariffId        DOC_INTERFACE.DIC_TARIFF_ID%type;
    vDfltGaugePacPaymentCondId   DOC_INTERFACE.PAC_PAYMENT_CONDITION_ID%type;
    vDfltAcsFinAccSPaymentId     DOC_INTERFACE.ACS_FIN_ACC_S_PAYMENT_ID%type;
    vConfigGaugeId               DOC_GAUGE.DOC_GAUGE_ID%type;
    vConfigGaugeDicTariffId      DOC_INTERFACE.DIC_TARIFF_ID%type;
    vConfigGaugePacPaymentCondId DOC_INTERFACE.PAC_PAYMENT_CONDITION_ID%type;
    vConfigAcsFinAccSPaymentId   DOC_INTERFACE.ACS_FIN_ACC_S_PAYMENT_ID%type;
    vAddressId1                  DOC_INTERFACE.PAC_ADDRESS_ID%type;
    vDoiAddress1                 DOC_INTERFACE.DOI_ADDRESS1%type;
    vDoiZipCode1                 DOC_INTERFACE.DOI_ZIPCODE1%type;
    vDoiTown1                    DOC_INTERFACE.DOI_TOWN1%type;
    vDoiState1                   DOC_INTERFACE.DOI_STATE1%type;
    vCntryId1                    DOC_INTERFACE.PC_CNTRY_ID%type;
    vLangId1                     DOC_INTERFACE.PC_LANG_ID%type;
    vAddressId2                  DOC_INTERFACE.PAC_PAC_ADDRESS_ID%type;
    vDoiAddress2                 DOC_INTERFACE.DOI_ADDRESS2%type;
    vDoiZipCode2                 DOC_INTERFACE.DOI_ZIPCODE2%type;
    vDoiTown2                    DOC_INTERFACE.DOI_TOWN2%type;
    vDoiState2                   DOC_INTERFACE.DOI_STATE2%type;
    vCntryId2                    DOC_INTERFACE.PC__PC_CNTRY_ID%type;
    vAddressId3                  DOC_INTERFACE.PAC2_PAC_ADDRESS_ID%type;
    vDoiAddress3                 DOC_INTERFACE.DOI_ADDRESS3%type;
    vDoiZipCode3                 DOC_INTERFACE.DOI_ZIPCODE3%type;
    vDoiTown3                    DOC_INTERFACE.DOI_TOWN3%type;
    vDoiState3                   DOC_INTERFACE.DOI_STATE3%type;
    vCntryId3                    DOC_INTERFACE.PC_2_PC_CNTRY_ID%type;
    step                         number;
  begin
    /* Réception de l'id du gabarit de configuration de l'interface document.
       On reprend le nom du gabarit transmis en paramètre et s'il est null,
       celui de la configuration. */
    step              := 1;
    vConfigGaugeId    := DOC_INTERFACE_FCT.GetGaugeId(nvl(pConfigGaugeName, PCS.PC_CONFIG.GETCONFIG('DOC_CART_CONFIG_GAUGE') ) );
    /* Réception de l'id du gabarit par défaut. On reprend le gabarit transmis en
       paramètre et s'il et null, celui du partenaire. */
    step              := 2;

    if    (pDfltGaugeId = 0)
       or (pDfltGaugeId is null) then
      vDfltGaugeId  := null;
    else
      vDfltGaugeId  := pDfltGaugeId;
    end if;

    if c_admin_domain = '1' then
      vDfltGaugeId  := vDfltGaugeId;
    elsif c_admin_domain = '2' then
      vDfltGaugeId  := nvl(vDfltGaugeId, DOC_INTERFACE_FCT.GetDefltGaugeId(pThirdId) );
    elsif c_admin_domain = '3' then
      vDfltGaugeId  := vDfltGaugeId;
    end if;

    /* Mise à jour du dernier n° utilisé dans la numérotation */
    step              := 3;
    DOC_INTERFACE_FCT.SetNewInterfaceNumber(vConfigGaugeId);
    step              := 4;

    if c_admin_domain = '1' then
      /* Réception des données du tiers */
      DOC_INTERFACE_FCT.GetSupplierInfo(pThirdID
                                      , vPerName
                                      , vPerShortName
                                      , vPerKey1
                                      , vPerKey2
                                      , vDicTariffId
                                      , vPacPaymentCondId
                                      , vPacSendingCondId
                                      , vDicTypeSubId
                                      , vAcsVatDetAccountId
                                      , vAcsFinAccSPaymentId
                                      , vPacAdressId
                                      , vCTarificationMode
                                      , vDicComplementaryDataId
                                      , vCDeliveryTyp
                                       );
    elsif c_admin_domain = '2' then
      /* Réception des données du tiers */
      DOC_INTERFACE_FCT.GetCustomInfo(pThirdID
                                    , vPerName
                                    , vPerShortName
                                    , vPerKey1
                                    , vPerKey2
                                    , vDicTariffId
                                    , vPacPaymentCondId
                                    , vPacSendingCondId
                                    , vDicTypeSubId
                                    , vAcsVatDetAccountId
                                    , vAcsFinAccSPaymentId
                                    , vPacAdressId
                                    , vPacRepresentativeId
                                    , vCTarificationMode
                                    , vDicComplementaryDataId
                                    , vCDeliveryTyp
                                     );
    end if;

    /* Réception des données du gabarit de config */
    step              := 5;
    DOC_INTERFACE_FCT.GetGaugeInfo(vConfigGaugeId, vConfigGaugeDicTariffId, vConfigGaugePacPaymentCondId, vConfigAcsFinAccSPaymentId);
    /* Réception des données du gabarit par défaut */
    step              := 6;
    DOC_INTERFACE_FCT.GetGaugeInfo(vDfltGaugeId, vDfltGaugeDicTariffId, vDfltGaugePacPaymentCondId, vDfltAcsFinAccSPaymentId);
    step              := 7;

    if c_admin_domain in('1', '2') then
      /* Réception des données du partenaire */
      DOC_INTERFACE_FCT.GetThirdAddress(pThirdId
                                      , vConfigGaugeId
                                      , vAddressId1
                                      , vDoiAddress1
                                      , vDoiZipCode1
                                      , vDoiTown1
                                      , vDoiState1
                                      , vCntryId1
                                      , vLangId1
                                      , vAddressId2
                                      , vDoiAddress2
                                      , vDoiZipCode2
                                      , vDoiTown2
                                      , vDoiState2
                                      , vCntryId2
                                      , vAddressId3
                                      , vDoiAddress3
                                      , vDoiZipCode3
                                      , vDoiTown3
                                      , vDoiState3
                                      , vCntryId3
                                       );
    end if;

    /* monnaie du document */
    if c_admin_domain in('1', '2') then
      step                     := 8;
      vAcsFinancialCurrencyId  := DOC_INTERFACE_FCT.GetFinancialCurrency(pThirdId, c_admin_domain);
    elsif c_admin_domain = '3' then
      step                     := 9;
      vAcsFinancialCurrencyId  := ACS_FUNCTION.GetLocalCurrencyId;
    end if;

    if nvl(pNewInterfaceId, 0) = 0 then
      select INIT_ID_SEQ.nextval
        into pNewInterfaceId
        from dual;
    end if;

    pInterfaceNumber  := DOC_INTERFACE_FCT.GetNewInterfaceNumber(vConfigGaugeId);

    /* Création de l'interface document */
    insert into DOC_INTERFACE
                (ACS_FINANCIAL_CURRENCY_ID   /* Id monnaie comptable*/
               , ACS_FIN_ACC_S_PAYMENT_ID   /* Méthode paiement*/
               , ACS_VAT_DET_ACCOUNT_ID   /* Décompte TVA*/
               , A_DATECRE   /* Date de création*/
               , A_IDCRE   /* ID de création*/
               , C_DOC_INTERFACE_ORIGIN   /* Origine du document*/
               , C_DOI_INTERFACE_FAIL_REASON   /* Code erreur*/
               , C_DOI_INTERFACE_STATUS   /* Statut du document*/
               , DIC_TARIFF_ID   /* Code tarif*/
               , DIC_TYPE_SUBMISSION_ID   /* Type de soumission*/
               , DOC_INTERFACE_ID   /* Interface document*/
               , DOI_ADDRESS1   /* Rue 1*/
               , DOI_ADDRESS2   /* Rue 2*/
               , DOI_ADDRESS3   /* Rue 3*/
               , DOI_DOCUMENT_DATE   /* Date document*/
               , DOI_NUMBER   /* Numéro de document*/
               , DOI_PER_KEY1   /* Clé 1*/
               , DOI_PER_KEY2   /* Clé 2*/
               , DOI_PER_NAME   /* Nom du tiers*/
               , DOI_PER_SHORT_NAME   /* Nom abrégé du tiers*/
               , DOI_PROTECTED   /* Code de protection*/
               , DOI_STATE1   /* Etat 1*/
               , DOI_STATE2   /* Etat 2*/
               , DOI_STATE3   /* Etat 3*/
               , DOI_TOWN1   /* Localité 1*/
               , DOI_TOWN2   /* Localité 2*/
               , DOI_TOWN3   /* Localité 3*/
               , DOI_VALUE_DATE   /* Date valeur du document*/
               , DOI_ZIPCODE1   /* Code postal 1*/
               , DOI_ZIPCODE2   /* Code postal 2*/
               , DOI_ZIPCODE3   /* Code postal 3*/
               , PAC2_PAC_ADDRESS_ID   /* Adresse*/
               , PAC_ADDRESS_ID   /* Adresse*/
               , PAC_PAC_ADDRESS_ID   /* Adresse*/
               , PAC_PAYMENT_CONDITION_ID   /* Condition de paiement*/
               , PAC_REPRESENTATIVE_ID   /* Représentant*/
               , PAC_SENDING_CONDITION_ID   /* Mode d'expédition*/
               , PAC_THIRD_ID   /* Tiers*/
               , PC_2_PC_CNTRY_ID   /* Pays*/
               , PC_CNTRY_ID   /* Code pays2*/
               , PC_LANG_ID   /* Code langue2*/
               , PC_USER_ID   /* Utilisateur2*/
               , PC__PC_CNTRY_ID   /* Pays*/
                )
         values (vAcsFinancialCurrencyId   /* Monnaie comptable     -> Monnaie du tiers ou monnaie de base*/
               , nvl(vAcsFinAccSPaymentId, vConfigAcsFinAccSPaymentId)   /* Méthode paiement      -> Celui du tiers sinon par gabarit*/
               , vAcsVatDetAccountId   /* Décompte TVA          -> Décompte Tva du tiers*/
               , sysdate   /* Date de création      -> Date système*/
               , PCS.PC_I_LIB_SESSION.GetUserIni   /* ID de création        -> Initiales du user*/
               , nvl(pInterfaceOrigin, '001')   /* Origine du document   -> Origin = ShoppingCart*/
               , ''   /* Code erreur           -> Vide pour l'instant*/
               , '01'   /* Statut du document    -> En préparation*/
               , nvl(vDfltGaugeDicTariffId, vDicTariffId)   /* Code tarif -> Tarif du gabarit par défaut sinon celui du tiers*/
               , vDicTypeSubId   /* Type de soumission    -> Type de soumission du tiers*/
               , pNewInterfaceId   /* Interface document    -> Nouvel Id */
               , vDoiAddress1   /* Rue 1                 -> Rue 1 du tiers*/
               , vDoiAddress2   /* Rue 2                 -> Rue 2 du tiers*/
               , vDoiAddress3   /* Rue 3                 -> Rue 3 du tiers*/
               , trunc(sysdate)   /* Date document         -> Date système*/
               , pInterfaceNumber   /* Numéro de document    -> Nouveau n° par rapport à la numérotation*/
               , vPerKey1   /* Clé 1                 -> Clé 1 du tiers*/
               , vPerKey2   /* Clé 2                 -> Clé 2 du tiers*/
               , vPerName   /* Nom du tiers          -> Nom du tiers*/
               , vPerShortName   /* Nom abrégé du tiers   -> Nom abrégé du tiers*/
               , 1   /* Code de protection    -> Protection par l'utilisateur connecté*/
               , vDoiState1   /* Etat 1                -> Etat 1 du tiers*/
               , vDoiState2   /* Etat 2                -> Etat 2 du tiers*/
               , vDoiState3   /* Etat 3                -> Etat 3 du tiers*/
               , vDoiTown1   /* Localité 1            -> Localité 1 du tiers*/
               , vDoiTown2   /* Localité 2            -> Localité 2 du tiers*/
               , vDoiTown3   /* Localité 3            -> Localité 3 du tiers*/
               , trunc(sysdate)   /* Date valeur  document -> Date système*/
               , vDoiZipCode1   /* Code postal 1         -> Code postal 1 du tiers*/
               , vDoiZipCode2   /* Code postal 2         -> Code postal 2 du tiers*/
               , vDoiZipCode3   /* Code postal 3         -> Code postal 3 du tiers*/
               , vAddressId3   /* Adresse               -> Adresse 3 du tiers*/
               , vAddressId1   /* Adresse               -> Adresse 1 du tiers*/
               , vAddressId2   /* Adresse               -> Adresse 2 du tiers*/
               , nvl(vDfltGaugePacPaymentCondId, vPacPaymentCondId)   /* Condition de paiement -> Condition du gabarit sinon du tiers*/
               , vPacRepresentativeId   /* Représentant          -> Représentant du tiers*/
               , vPacSendingCondId   /* Mode d'expédition     -> Mode d'expédition du tiers*/
               , pThirdId   /* Tiers                 -> Tiers passé en paramètre*/
               , vCntryId3   /* Pays                  -> Pays 3 du tiers*/
               , vCntryId1   /* Code pays2            -> Pays 1 du tiers*/
               , nvl(vLangId1, PCS.PC_I_LIB_SESSION.GetUserLangID)   /* Code langue2 -> Initialisation avec langue du tiers sinon du User*/
               , PCS.PC_I_LIB_SESSION.GetUserId   /* Utilisateur2          -> Initialisation du User*/
               , vCntryId2   /* Pays                  -> Pays 2 du tiers*/
                );
  exception
    when others then
      raise_application_error(-20099
                            , 'Step = ' ||
                              to_char(step) ||
                              co.cLineBreak ||
                              to_char(vConfigGaugeId) ||
                              co.cLineBreak ||
                              sqlerrm ||
                              co.cLineBreak ||
                              DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                             );
  end CREATE_INTERFACE;

  /**
  * Description
  *
  *     Mise à jour des données du document en fonction de l'interface.
  *     La procèdure demande le code d'origine de la génération pour garantir
  *     une compatibilité avec la version précédente.
  */
  procedure UpdateDocumentFromInterface(
    AInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type
  , ADocumentID  in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , AOriginCode  in DOC_INTERFACE.C_DOC_INTERFACE_ORIGIN%type
  )
  is
    cursor crGetDocProc(cInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type)
    is
      select   DOG.DOG_DOCUMENT_PROC
             , DOG.DOG_SUBTYPE
          from DOC_INTERFACE DOI
             , DOC_INTERFACE_CONFIG DOG
             , DOC_INTERFACE_POSITION DIP
         where DOI.DOC_INTERFACE_ID = cInterfaceID
           and DOI.C_DOC_INTERFACE_ORIGIN = DOG.C_DOC_INTERFACE_ORIGIN
           and DOI.DOC_INTERFACE_ID = DIP.DOC_INTERFACE_ID
      union
      select   DOG.DOG_DOCUMENT_PROC
             , DOG.DOG_SUBTYPE
          from DOC_INTERFACE DOI
             , DOC_INTERFACE_CONFIG DOG
             , DOC_INTERFACE_POSITION DIP
         where DOI.DOC_INTERFACE_ID = cInterfaceID
           and DOI.C_DOC_INTERFACE_ORIGIN = DOG.C_DOC_INTERFACE_ORIGIN
           and DOI.DOI_SUBTYPE = DOG.DOG_SUBTYPE
           and DOI.DOC_INTERFACE_ID = DIP.DOC_INTERFACE_ID
      order by 2;

    tplGetDocProc crGetDocProc%rowtype;
    cid           integer;
    ignore        integer;
    SqlCmd        varchar2(2000);
  begin
    open crGetDocProc(AInterfaceID);

    fetch crGetDocProc
     into tplGetDocProc;

    -- Aucune procédure à executer n'a été renseignée
    if tplGetDocProc.DOG_DOCUMENT_PROC is null then
      -- Mise à jour des données du document en fonction de l'interface, méthode PCS
      UpdateDocumentFromInterfacePCS(AInterfaceID, ADocumentID, AOriginCode);
    else   -- Executer la procédure utilisateur en DBMS_SQL
      SqlCmd  :=
              'BEGIN ' || tplGetDocProc.DOG_DOCUMENT_PROC || '(' || to_char(AInterfaceID) || ',' || to_char(ADocumentID) || ',' || AOriginCode || '); '
              || 'END;';
      -- Ouverture du curseur
      cid     := DBMS_SQL.OPEN_CURSOR;
      DBMS_SQL.PARSE(cid, SqlCmd, DBMS_SQL.v7);
      -- Exécution de la procédure
      ignore  := DBMS_SQL.execute(cid);
      -- Ferme le curseur
      DBMS_SQL.CLOSE_CURSOR(cid);
    end if;

    close crGetDocProc;
  end UpdateDocumentFromInterface;

  /**
  * Description
  *
  *     Mise à jour des données du pied en fonction de l'interface.
  *     La procèdure demande le code d'origine de la génération pour garantir
  *     une compatibilité avec la version précédente.
  */
  procedure UpdateFootFromInterface(
    AInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type
  , AFootID      in DOC_FOOT.DOC_FOOT_ID%type
  , AOriginCode  in DOC_INTERFACE.C_DOC_INTERFACE_ORIGIN%type
  )
  is
    cursor crGetFootProc(cInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type)
    is
      select   DOG.DOG_FOOT_PROC
             , DOG.DOG_SUBTYPE
          from DOC_INTERFACE DOI
             , DOC_INTERFACE_CONFIG DOG
             , DOC_INTERFACE_POSITION DIP
         where DOI.DOC_INTERFACE_ID = cInterfaceID
           and DOI.C_DOC_INTERFACE_ORIGIN = DOG.C_DOC_INTERFACE_ORIGIN
           and DOI.DOC_INTERFACE_ID = DIP.DOC_INTERFACE_ID
      union
      select   DOG.DOG_FOOT_PROC
             , DOG.DOG_SUBTYPE
          from DOC_INTERFACE DOI
             , DOC_INTERFACE_CONFIG DOG
             , DOC_INTERFACE_POSITION DIP
         where DOI.DOC_INTERFACE_ID = cInterfaceID
           and DOI.C_DOC_INTERFACE_ORIGIN = DOG.C_DOC_INTERFACE_ORIGIN
           and DOI.DOI_SUBTYPE = DOG.DOG_SUBTYPE
           and DOI.DOC_INTERFACE_ID = DIP.DOC_INTERFACE_ID
      order by 2;

    tplGetFootProc crGetFootProc%rowtype;
    cid            integer;
    ignore         integer;
    SqlCmd         varchar2(2000);
  begin
    open crGetFootProc(AInterfaceID);

    fetch crGetFootProc
     into tplGetFootProc;

    -- Aucune procédure à executer n'a été renseignée
    if tplGetFootProc.DOG_FOOT_PROC is null then
      -- Mise à jour des données du pied en fonction de l'interface, méthode PCS
      UpdateFootFromInterfacePCS(AInterfaceID, AFootID, AOriginCode);
    else   -- Executer la procédure utilisateur en DBMS_SQL
      SqlCmd  := 'BEGIN ' || tplGetFootProc.DOG_FOOT_PROC || '(' || to_char(AInterfaceID) || ',' || to_char(AFootID) || ',' || AOriginCode || '); ' || 'END;';
      -- Ouverture du curseur
      cid     := DBMS_SQL.OPEN_CURSOR;
      DBMS_SQL.PARSE(cid, SqlCmd, DBMS_SQL.v7);
      -- Exécution de la procédure
      ignore  := DBMS_SQL.execute(cid);
      -- Ferme le curseur
      DBMS_SQL.CLOSE_CURSOR(cid);
    end if;

    close crGetFootProc;
  end UpdateFootFromInterface;

  /**
  * Description
  *
  *     Mise à jour des données du document en fonction de l'interface.
  *     La procèdure demande le code d'origine de la génération pour garantir
  *     une compatibilité avec la version précédente.
  */
  procedure UpdateDocumentFromInterfacePCS(
    AInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type
  , ADocumentID  in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , AOriginCode  in DOC_INTERFACE.C_DOC_INTERFACE_ORIGIN%type
  )
  is
  begin
    if (AOriginCode = '201') then   /* EDI */
      update DOC_DOCUMENT DMT
         set (DMT.DMT_DATE_DOCUMENT, DMT.DMT_DATE_VALUE) =
               (select decode(doi.doi_document_date, null, dmt.dmt_date_document, doi.doi_document_date)
                     , decode(doi.doi_value_date, null, dmt.dmt_date_value, doi.doi_value_date)
                  from DOC_INTERFACE DOI
                 where DOI.DOC_INTERFACE_ID = AInterfaceID)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DMT.DOC_DOCUMENT_ID = ADocumentID;
    else   /* Autres */
      null;
    /*
    update DOC_DOCUMENT DMT
       set(
           )
         = (
    select
      from DOC_INTERFACE DOI
     where DOI.DOC_INTERFACE_ID = AInterfaceID)
     where DMT.DOC_DOCUMENT_ID = ADocumentID;
    */
    end if;
  end UpdateDocumentFromInterfacePCS;

  /**
  * Description
  *
  *     Mise à jour des données du pied en fonction de l'interface.
  *     La procèdure demande le code d'origine de la génération pour garantir
  *     une compatibilité avec la version précédente.
  */
  procedure UpdateFootFromInterfacePCS(
    AInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type
  , AFootID      in DOC_FOOT.DOC_FOOT_ID%type
  , AOriginCode  in DOC_INTERFACE.C_DOC_INTERFACE_ORIGIN%type
  )
  is
  begin
    if (AOriginCode = '201') then   /* EDI */
      update doc_foot foo
         set foo.ACJ_JOB_TYPE_S_CAT_PMT_ID = (select ACJ_JOB_TYPE_S_CAT_PMT_ID
                                                from doc_gauge_structured gas
                                                   , doc_document dmt
                                               where foo.doc_document_id = dmt.doc_document_id
                                                 and dmt.doc_gauge_id = gas.doc_gauge_id)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where doc_foot_id = AFootId;

      update doc_foot foo
         set FOO_PAID_AMOUNT_B = foo_document_tot_amount_b
           , FOO_RECEIVED_AMOUNT = foo_document_total_amount
           , FOO_PAID_BALANCED_AMOUNT = 0
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where doc_foot_id = AFootid
         and acj_job_type_s_Cat_pmt_id is not null;
    else   /* Autres */
      null;
    /*
    update DOC_FOOT FOO
       set(
           )
         = (
    select
      from DOC_INTERFACE DOI
     where DOI.DOC_INTERFACE_ID = AInterfaceID)
     where FOO.DOC_FOOT_ID = AFootID;
    */
    end if;
  end UpdateFootFromInterfacePCS;
end DOC_INTERFACE_CREATE;
