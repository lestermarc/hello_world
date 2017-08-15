--------------------------------------------------------
--  DDL for Package Body ACI_XML_DOC_CONVERT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACI_XML_DOC_CONVERT" 
as
  /* Variables globales pour xPath du document XML venant de PCS (scan de document par ex) */
  vCntPathControl  constant varchar2(18) := '/DOCUMENT/CONTROL/';
  vCntPathHeader   constant varchar2(17) := '/DOCUMENT/HEADER/';
  vCntPathSender   constant varchar2(24) := '/DOCUMENT/HEADER/SENDER/';
  vCntPathThisDoc  constant varchar2(31) := '/DOCUMENT/HEADER/THIS_DOCUMENT/';
  vCntPathPosition constant varchar2(29) := '/DOCUMENT/POSITIONS/POSITION';

  type TACI_EXPIRY is table of ACI_EXPIRY%rowtype
    index by binary_integer;

  type TACI_DET_PAYMENT is table of ACI_DET_PAYMENT%rowtype
    index by binary_integer;

  type TACI_FINANCIAL_IMPUTATION is table of ACI_FINANCIAL_IMPUTATION%rowtype
    index by binary_integer;

  type TACI_MGM_IMPUTATION is table of ACI_MGM_IMPUTATION%rowtype
    index by binary_integer;

  type TACI_PART_IMPUTATION is table of ACI_PART_IMPUTATION%rowtype
    index by binary_integer;

  type TACI_REMINDER is table of ACI_REMINDER%rowtype
    index by binary_integer;

  type TACI_REMINDER_TEXT is table of ACI_REMINDER_TEXT%rowtype
    index by binary_integer;

  type TCatProperties is record(
    CatKey                 ACJ_CATALOGUE_DOCUMENT.CAT_KEY%type                     := ''
  , TypKey                 ACJ_JOB_TYPE.TYP_KEY%type                               := ''
  , CSubSet                ACJ_SUB_SET_CAT.C_SUB_SET%type                          := ''
  , CTypCat                ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type            := ''
  , TypSupplierPermanent   signtype                                                := 0
  , WithMgm                signtype                                                := 0
  , AcjJobTypeId           ACJ_JOB_TYPE.ACJ_JOB_TYPE_ID%type                       := 0
  , AcjCatalogueDocumentId ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type   := 0
  );

  -- Propriété des monnaies utilisées dans le document
   -- IsMBDocument = 1 si le document est libellé en monnaie de base
  type TDocCurrencies is record(
    DocCurrency  varchar2(2000)
  , MECurrencyId ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , MBCurrency   varchar2(2000)
  , MBCurrencyId ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , IsMBDocument signtype                                                := 0
  );

  -- curseur définissant la structure d'une imputation financaière avec les axes MGM
  cursor crFinMgmImputation
  is
    select IMP.*
         , lpad('', 30) CPN_NUMBER
         , lpad('', 30) CDA_NUMBER
         , lpad('', 30) PF_NUMBER
         , lpad('', 30) PJ_NUMBER
      from ACI_FINANCIAL_IMPUTATION IMP;

  type TFinMgmImputation is table of crFinMgmImputation%rowtype
    index by binary_integer;

  /**
  * function CheckDocumentVersion
  * Description
  *   Contrôle de la version du document reçu et le convertir si sa version est plus grande que celle de la conversion
  */
  function CheckDocumentVersion(aXML in xmltype, aConversionVersion in number, aDocumentVersion in number)
    return xmltype
  is
  begin
    -- Convertir le fichier reçu si son numéro de version est plus grand que la version de conversion
    if aDocumentVersion > aConversionVersion then
      -- appliquer une transformation
      return aXML;
    else
      return aXML;
    end if;
  end CheckDocumentVersion;

  /* Recherche du compte auxiliaire selon la clé et le sous-ensemble géré par le catalogue
  */
  procedure GetAuxAccountId(
    aCSubSet         in     ACS_SUB_SET.C_SUB_SET%type
  , aPerKey          in     PAC_PERSON.PER_KEY1%type
  , aAcsAuxAccountId out    ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type
  , aPacPersonId     out    PAC_PERSON.PAC_PERSON_ID%type
  )
  is
  begin
    if aCSubSet = 'PAY' then
      select max(SUP.ACS_AUXILIARY_ACCOUNT_ID)
           , max(SUP.PAC_SUPPLIER_PARTNER_ID)
        into aAcsAuxAccountId
           , aPacPersonId
        from PAC_SUPPLIER_PARTNER SUP
           , PAC_PERSON PER
       where SUP.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID
         and PER.PER_KEY1 = aPerKey;

      if aAcsAuxAccountId is null then   --Recherche avec la clé2
        select max(SUP.ACS_AUXILIARY_ACCOUNT_ID)
             , max(SUP.PAC_SUPPLIER_PARTNER_ID)
          into aAcsAuxAccountId
             , aPacPersonId
          from PAC_SUPPLIER_PARTNER SUP
             , PAC_PERSON PER
         where SUP.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID
           and PER.PER_KEY2 = aPerKey;
      end if;
    else
      select max(CUS.ACS_AUXILIARY_ACCOUNT_ID)
           , max(CUS.PAC_CUSTOM_PARTNER_ID)
        into aAcsAuxAccountId
           , aPacPersonId
        from PAC_CUSTOM_PARTNER CUS
           , PAC_PERSON PER
       where CUS.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
         and PER.PER_KEY1 = aPerKey;

      if aAcsAuxAccountId is null then   --Recherche avec la clé2
        select max(CUS.ACS_AUXILIARY_ACCOUNT_ID)
             , max(CUS.PAC_CUSTOM_PARTNER_ID)
          into aAcsAuxAccountId
             , aPacPersonId
          from PAC_CUSTOM_PARTNER CUS
             , PAC_PERSON PER
         where CUS.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
           and PER.PER_KEY2 = aPerKey;
      end if;
    end if;
  end GetAuxAccountId;

  /**
  * function GetDocCurrency
  * Description
  *   Extraction de la monnaie du document
  *  @param in aXML document XML converti venant de PCS
  *  @return la monnaie du document
  */
  function GetDocCurrency(aXML in xmltype)
    return varchar2
  is
    vResult varchar2(2000);
  begin
    select extractvalue(aXML, vCntPathThisDoc || 'CURRENCY') as CURRENCY1
      into vResult
      from dual;

    return vResult;
  end GetDocCurrency;

  /**
  * function GetDocumentDate
  * Description
  *   Extraction de la date du document
  *  @param in aXML document venant de PCS
  *  @return la date du document
  */
  function GetDocumentDate(aXML in xmltype)
    return date
  is
    vResult date;
  begin
    select to_date(replace(extractvalue(aXML, vCntPathSender || 'DOCUMENT_DATE'), 'T', ' '), 'YYYY-MM-DD HH24:MI:SS')
      into vResult
      from dual;

    return vResult;
  end GetDocumentDate;

  /**
  * function GetPerKey
  * Description
  *   Extraction de la clé du partenaire
  *  @param in aXML document venant de PCS
  *  @return la clé du partenaire
  */
  function GetPerKey(aXML in xmltype)
    return varchar2
  is
    vResult varchar2(2000);
  begin
    select extractvalue(aXML, vCntPathSender || 'IDENTIFIER/KEY')
      into vResult
      from dual;

    return vResult;
  end GetPerKey;

  /**
  * function GetTypKey
  * Description
  *   @param aXMLTypKey clé du catalogue fournie par le document XML
  *   @return la clé du modèle de travail selon une table de conversion
  */
  function GetTypKey(aXMLCatKey varchar2)
    return ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_S_CATALOGUE_ID%type
  is
  begin
/* La procédure convert_value permet de retourner l'ID d'un modèle de travail selon la clé d'un catalogue
   Valeurs possibles pour les options de recherche (cascade de recherche):
    'THIRD'
    'DEF_VALUE'
    'THIRD,DEF_VALUE'
  DESCODE FIN-001 correspond à  la recherche pour un modèle de travail selon une clé venant d'un catalogue
*/
    return nvl(com_lookup_functions.convert_value(aComLookupType    => 'FIN-001'
                                                , aThirdId          => null
                                                , aValueToConvert   => aXMLCatKey
                                                , aSearchPath       => 'DEF_VALUE'
                                                 )
             , 0
              );
  end GetTypKey;

  /* Prendre toutes les contre-écritures et cumuler les montants dans la première contre-écriture. Les lignes contenant les montants cumulés seront supprimées
  */
  procedure SuppPermUpdOffsetEntries(
    aDocumentDate           in            ACI_DOCUMENT.DOC_DOCUMENT_DATE%type
  , aAcjCatalogueDocumentId in            ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
  , aTblFinMgmImp           in out nocopy TFinMgmImputation
  )
  is
  begin
    --Recherche du compte financier et de la division pour la pré-saisie
    select (select ACC_NUMBER
              from ACS_ACCOUNT ACC
             where ACS_ACCOUNT_ID = CAT.ACS_FINANCIAL_ACCOUNT_ID) ACC_NUMBER
         , (select ACC_NUMBER
              from ACS_ACCOUNT
             where ACS_ACCOUNT_ID =
                            nvl(ACS_FUNCTION.GetDivisionOfAccount(CAT.ACS_FINANCIAL_ACCOUNT_ID, null, aDocumentDate), 0) )
                                                                                                             DIV_NUMBER
      into aTblFinMgmImp(aTblFinMgmImp.first).ACC_NUMBER
         , aTblFinMgmImp(aTblFinMgmImp.first).DIV_NUMBER
      from ACJ_CATALOGUE_DOCUMENT CAT
     where CAT.ACJ_CATALOGUE_DOCUMENT_ID = aAcjCatalogueDocumentId;

    --Cumuler tous les montants dans la première contre-écriture
    for vCpt in reverse aTblFinMgmImp.first + 1 .. aTblFinMgmImp.last loop
      aTblFinMgmImp(aTblFinMgmImp.first).TAX_LIABLED_AMOUNT  :=
                         aTblFinMgmImp(aTblFinMgmImp.first).TAX_LIABLED_AMOUNT + aTblFinMgmImp(vCpt).TAX_LIABLED_AMOUNT;
      aTblFinMgmImp(aTblFinMgmImp.first).TAX_VAT_AMOUNT_LC   :=
                           aTblFinMgmImp(aTblFinMgmImp.first).TAX_VAT_AMOUNT_LC + aTblFinMgmImp(vCpt).TAX_VAT_AMOUNT_LC;
      aTblFinMgmImp(aTblFinMgmImp.first).TAX_VAT_AMOUNT_FC   :=
                           aTblFinMgmImp(aTblFinMgmImp.first).TAX_VAT_AMOUNT_FC + aTblFinMgmImp(vCpt).TAX_VAT_AMOUNT_FC;
      aTblFinMgmImp(aTblFinMgmImp.first).IMF_AMOUNT_LC_D     :=
                               aTblFinMgmImp(aTblFinMgmImp.first).IMF_AMOUNT_LC_D + aTblFinMgmImp(vCpt).IMF_AMOUNT_LC_D;
      aTblFinMgmImp(aTblFinMgmImp.first).IMF_AMOUNT_LC_C     :=
                               aTblFinMgmImp(aTblFinMgmImp.first).IMF_AMOUNT_LC_C + aTblFinMgmImp(vCpt).IMF_AMOUNT_LC_C;
      aTblFinMgmImp(aTblFinMgmImp.first).IMF_AMOUNT_FC_D     :=
                               aTblFinMgmImp(aTblFinMgmImp.first).IMF_AMOUNT_FC_D + aTblFinMgmImp(vCpt).IMF_AMOUNT_FC_D;
      aTblFinMgmImp(aTblFinMgmImp.first).IMF_AMOUNT_FC_C     :=
                               aTblFinMgmImp(aTblFinMgmImp.first).IMF_AMOUNT_FC_C + aTblFinMgmImp(vCpt).IMF_AMOUNT_FC_C;
      aTblFinMgmImp.delete(vCpt);
    end loop;
  end SuppPermUpdOffsetEntries;

  /*Construction de l'imputation primaire
    Recherche du compte financier + division: aucune information ne vient du document XML.
    Pré-saisie:
      * Compte collectif du compte auxiliaire du tiers
        o Document de type 2,6 : ACS_AUXILIARY_ACCOUNT.ACS_INVOICE_COLL_ID
        o Document de type 5 : ACS_AUXILIARY_ACCOUNT.ACS_PREP_COLL_ID
  * Division relative au compte trouvé
  * Si pas pré-saisie: on va d'abord rechercher le compte financier du catalogue et, si pas trouvé, on prend celui du compte auxiliaire (ci-dessus)
  * Résolution: rechercher le compte financier + division liée du compte auxiliaire
  *             et si on n'est PAS en pré-saisie, rechercher le compte du catalogue
  *
  */
  procedure GetPrimaryFinDivAccount(
    aAcsAuxAccountId        in            ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type
  , aDocumentDate           in            ACI_DOCUMENT.DOC_DOCUMENT_DATE%type
  , aAcjCatalogueDocumentId in            ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
  , aCTypCat                in            ACJ_CATALOGUE_DOCUMENT.C_TYPE_CATALOGUE%type
  , aTypSupplierPermanent   in            signtype
  , aAuxFinNumber           out nocopy    ACS_ACCOUNT.ACC_NUMBER%type
  , aAuxDivNumber           out nocopy    ACS_ACCOUNT.ACC_NUMBER%type
  , aAuxNumber              out nocopy    ACS_ACCOUNT.ACC_NUMBER%type
  )
  is
    vAuxFinAccountId ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type;
    vAuxDivId        ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;
    vCatFinAccountId ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
  begin
    select AUX.AUX_FIN_ACCOUNT_ID
         , (select ACC_NUMBER
              from ACS_ACCOUNT
             where ACS_ACCOUNT_ID = AUX.AUX_FIN_ACCOUNT_ID) AUX_FIN_NUMBER
         , nvl(AUX.AUX_DIV_ACCOUNT_ID, AUX.FIN_DIV_ACCOUNT_ID) AUX_DIV_ID
         , (select ACC_NUMBER
              from ACS_ACCOUNT
             where ACS_ACCOUNT_ID = nvl(AUX.AUX_DIV_ACCOUNT_ID, AUX.FIN_DIV_ACCOUNT_ID) ) AUX_DIV_NUMBER
         , (select ACC_NUMBER
              from ACS_ACCOUNT
             where ACS_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID) AUX_NUMBER
      into vAuxFinAccountId
         , aAuxFinNumber
         , vAuxDivId
         , aAuxDivNumber
         , aAuxNumber
      from (select AUX1.AUX_FIN_ACCOUNT_ID
                 , AUX1.AUX_DIV_ACCOUNT_ID
                 , ACS_FUNCTION.GetDivisionOfAccount(AUX1.AUX_FIN_ACCOUNT_ID, AUX1.AUX_DIV_ACCOUNT_ID, aDocumentDate)
                                                                                                     FIN_DIV_ACCOUNT_ID
                 , AUX1.ACS_AUXILIARY_ACCOUNT_ID
              from (select case
                             when aCTypCat in('2', '6') then AUX.ACS_INVOICE_COLL_ID
                             else AUX.ACS_PREP_COLL_ID
                           end AUX_FIN_ACCOUNT_ID
                         , AUX.ACS_DIVISION_ACCOUNT_ID AUX_DIV_ACCOUNT_ID
                         , AUX.ACS_AUXILIARY_ACCOUNT_ID
                      from ACS_AUXILIARY_ACCOUNT AUX
                     where AUX.ACS_AUXILIARY_ACCOUNT_ID = aAcsAuxAccountId) AUX1) AUX;

    if aTypSupplierPermanent = 0 then   --Pas en pré-saisie, recherche du compte financier du catalogue
      select nvl(CAT.ACS_FINANCIAL_ACCOUNT_ID, vAuxFinAccountId) ACS_FINANCIAL_ACCOUNT_ID
        into vCatFinAccountId
        from ACJ_CATALOGUE_DOCUMENT CAT
       where CAT.ACJ_CATALOGUE_DOCUMENT_ID = aAcjCatalogueDocumentId;

      if (vCatFinAccountId <> vAuxFinAccountId) then
        select (select ACC_NUMBER
                  from ACS_ACCOUNT
                 where ACS_ACCOUNT_ID = vCatFinAccountId) FIN_ACC_NUMBER
             , (select ACC_NUMBER
                  from ACS_ACCOUNT
                 where ACS_ACCOUNT_ID =
                          nvl(vAuxDivId, ACS_FUNCTION.GetDivisionOfAccount(vCatFinAccountId, vAuxDivId, aDocumentDate) ) )
                                                                                                         FIN_DIV_NUMBER
          into aAuxFinNumber
             , aAuxDivNumber
          from dual;
      end if;
    end if;
  end GetPrimaryFinDivAccount;

  /* Cumul des montants des contre-écritures à  mettre dans l'imputation primaire
  */
  procedure SetPrimaryImpAmounts(aPrimaryIndex in integer, aTblFinMgmImp in out nocopy TFinMgmImputation)
  is
  begin
    if aTblFinMgmImp.count > 0 then
      aTblFinMgmImp(aPrimaryIndex).IMF_AMOUNT_LC_D  := 0;
      aTblFinMgmImp(aPrimaryIndex).IMF_AMOUNT_LC_C  := 0;
      aTblFinMgmImp(aPrimaryIndex).IMF_AMOUNT_FC_D  := 0;
      aTblFinMgmImp(aPrimaryIndex).IMF_AMOUNT_FC_C  := 0;

      for vCpt in aTblFinMgmImp.first .. aTblFinMgmImp.last - 1 loop   -- '-1' car la dernière ligne est l'imputation primaire
        --Les montants Débits-crédits sont inversés entre l'écriture primaire et la contre-écriture
        --Pas de taxe sur l'imputation primaire
        aTblFinMgmImp(aPrimaryIndex).IMF_AMOUNT_LC_D  :=
                                     aTblFinMgmImp(aPrimaryIndex).IMF_AMOUNT_LC_D + aTblFinMgmImp(vCpt).IMF_AMOUNT_LC_C;
        aTblFinMgmImp(aPrimaryIndex).IMF_AMOUNT_LC_C  :=
                                     aTblFinMgmImp(aPrimaryIndex).IMF_AMOUNT_LC_C + aTblFinMgmImp(vCpt).IMF_AMOUNT_LC_D;
        aTblFinMgmImp(aPrimaryIndex).IMF_AMOUNT_FC_D  :=
                                     aTblFinMgmImp(aPrimaryIndex).IMF_AMOUNT_FC_D + aTblFinMgmImp(vCpt).IMF_AMOUNT_FC_C;
        aTblFinMgmImp(aPrimaryIndex).IMF_AMOUNT_FC_C  :=
                                     aTblFinMgmImp(aPrimaryIndex).IMF_AMOUNT_FC_C + aTblFinMgmImp(vCpt).IMF_AMOUNT_FC_D;
      end loop;
    end if;
  end SetPrimaryImpAmounts;

  /**
  * procedure InitializeCurrencys
  * Description
  *   Initialisation des variables passées en paramètres
  *  @param out aCatProps Propriétés catalogue + modèle
  *  @param in aXML document XML
  *  @param out aDocCurrencies
  */
  procedure InitializeCurrencys(aXML in xmltype, aDocCurrencies out nocopy TDocCurrencies)
  is
    vDocCurrency ACI_DOCUMENT.CURRENCY%type;
  begin
    vDocCurrency  := GetDocCurrency(aXML);

    select vDocCurrency DOC_CURRENCY
         , (select CURRENCY
              from PCS.PC_CURR
             where PC_CURR_ID = FIN.PC_CURR_ID) MB_CURRENCY
         , case
             when (select CURRENCY
                     from PCS.PC_CURR
                    where PC_CURR_ID = FIN.PC_CURR_ID) = vDocCurrency then 1
             else 0
           end IsMBDocument
         , FIN.ACS_FINANCIAL_CURRENCY_ID MB_CURRENCY_ID
         , (select ACS_FINANCIAL_CURRENCY_ID
              from ACS_FINANCIAL_CURRENCY
             where PC_CURR_ID = (select PC_CURR_ID
                                   from PCS.PC_CURR
                                  where CURRENCY = vDocCurrency) ) ME_CURRENCY_ID
      into aDocCurrencies.DocCurrency
         , aDocCurrencies.MBCurrency
         , aDocCurrencies.IsMBDocument
         , aDocCurrencies.MBCurrencyId
         , aDocCurrencies.MECurrencyId
      from ACS_FINANCIAL_CURRENCY FIN
     where FIN.FIN_LOCAL_CURRENCY = 1;
  end InitializeCurrencys;

  /**
  * function InitializeJobTypeCatalogue
  * Description
  *   Recherche des propriétés du catalogue et du modèle
  *  @param in out aCatProps Propriétés catalogue + modèle
  *  @param in aXML document XML converti venant de PCS
  *  @return false (arrêt de l'intégration) si le catalogue ou le modèle ne sont pas trouvés
  */
  function InitializeJobTypeCatalogue(aCatProps out nocopy TCatProperties, aXML in xmltype)
    return boolean
  is
    vAcjJobSTypeCatalogueId ACJ_JOB_TYPE_S_CATALOGUE.ACJ_JOB_TYPE_S_CATALOGUE_ID%type;
    vLookupVal              com_lookup_values.clv_value_to_convert%type;
  begin
    --Recherche du catalogue
    select extractvalue(aXML, vCntPathThisDoc || 'DOCUMENT_TYPE/FINANCIAL')
      into vLookupVal
      from dual;

    vAcjJobSTypeCatalogueId  := GetTypKey(vLookupVal);

    begin
      --C'est l'exception (no_data_found) qui gère le résultat de retour
      select cat.ACJ_CATALOGUE_DOCUMENT_ID
           , cat.C_TYPE_CATALOGUE
           , cat.cat_key
           , TYP.ACJ_JOB_TYPE_ID
           , TYP.TYP_KEY
           , TYP.TYP_SUPPLIER_PERMANENT
        into aCatProps.AcjCatalogueDocumentId
           , aCatProps.CTypCat
           , aCatProps.CatKey
           , aCatProps.AcjJobTypeId
           , aCatProps.TypKey
           , aCatProps.TypSupplierPermanent
        from ACJ_CATALOGUE_DOCUMENT cat
           , ACJ_JOB_TYPE typ
           , ACJ_JOB_TYPE_S_CATALOGUE JCA
       where jca.acj_job_type_s_catalogue_id = vAcjJobSTypeCatalogueId
         and jca.acj_catalogue_document_id = cat.acj_catalogue_document_id
         and jca.acj_job_type_id = typ.acj_job_type_id;
    exception
      when no_data_found then
        return false;
    end;

    --Recherche des sous-ensembles gérés par le catalogue
    for tplSubSetCat in (select SCA.C_SUB_SET
                           from ACJ_SUB_SET_CAT SCA
                          where SCA.ACJ_CATALOGUE_DOCUMENT_ID = aCatProps.AcjCatalogueDocumentId
                            and SCA.C_SUB_SET in('REC', 'PAY', 'CPN') ) loop
      if tplSubSetCat.C_SUB_SET = 'CPN' then
        aCatProps.WithMgm  := 1;
      else
        aCatProps.CSubSet  := tplSubSetCat.C_SUB_SET;
      end if;
    end loop;

    return true;
  end InitializeJobTypeCatalogue;

  /**
  * function ExtractAciMgmImputation
  * Description
  *   Extraction des imputations financières du document venant de PCS
  */
  function ExtractAciMgmImputation(aTblFinMgmImp in crFinMgmImputation%rowtype)
    return xmltype
  is
    vResult           xmltype;
    vCpnFinNumber     ACS_ACCOUNT.ACC_NUMBER%type;
    vCpnId            ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID%type;
    vOldInteraction   ACT_MGM_MANAGEMENT.CPNLinkedAccountsRecType;
    vValidInteraction ACT_MGM_MANAGEMENT.CPNLinkedAccountsRecType;
    vExistInteraction boolean;
  begin
    if aTblFinMgmImp.CPN_NUMBER is not null then
      select nvl(max(ACC.ACC_NUMBER), '') CPN_NUMBER
           , nvl(max(ACC.ACS_ACCOUNT_ID), 0) ACS_ACCOUNT_ID
        into vCpnFinNumber
           , vCpnId
        from ACS_ACCOUNT ACC
           , ACS_CPN_ACCOUNT CPN
       where ACC.ACS_ACCOUNT_ID = CPN.ACS_CPN_ACCOUNT_ID
         and ACC.ACC_NUMBER = aTblFinMgmImp.CPN_NUMBER;
    else
      select nvl(max(ACC_NUMBER), '') ACC_NUMBER
           , nvl(max(ACS_ACCOUNT_ID), 0) ACS_ACCOUNT_ID
        into vCpnFinNumber
           , vCpnId
        from ACS_ACCOUNT
       where ACS_ACCOUNT_ID =
               (select ACS_CPN_ACCOUNT_ID
                  from ACS_FINANCIAL_ACCOUNT
                 where ACS_FINANCIAL_ACCOUNT_ID =
                         (select ACS_ACCOUNT_ID
                            from ACS_ACCOUNT ACC
                               , ACS_FINANCIAL_ACCOUNT FIN
                           where ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                             and ACC.ACC_NUMBER = aTblFinMgmImp.ACC_NUMBER) );
    end if;

    if vCpnId > 0 then
      --Contrôle et initialisation des axes qui ne sont pas renseignés dans le document
      select (select ACC.ACS_ACCOUNT_ID
                from ACS_ACCOUNT ACC
                   , ACS_CDA_ACCOUNT CDA
               where ACC.ACS_ACCOUNT_ID = CDA.ACS_CDA_ACCOUNT_ID
                 and ACC.ACC_NUMBER = aTblFinMgmImp.CDA_NUMBER) ACS_CDA_ACCOUNT_ID
           , (select ACC.ACS_ACCOUNT_ID
                from ACS_ACCOUNT ACC
                   , ACS_PF_ACCOUNT PF
               where ACC.ACS_ACCOUNT_ID = PF.ACS_PF_ACCOUNT_ID
                 and ACC.ACC_NUMBER = aTblFinMgmImp.PF_NUMBER) ACS_PF_ACCOUNT_ID
           , (select ACC.ACS_ACCOUNT_ID
                from ACS_ACCOUNT ACC
                   , ACS_PJ_ACCOUNT PJ
               where ACC.ACS_ACCOUNT_ID = PJ.ACS_PJ_ACCOUNT_ID
                 and ACC.ACC_NUMBER = aTblFinMgmImp.PJ_NUMBER) ACS_PJ_ACCOUNT_ID
        into vOldInteraction.CDAAccId
           , vOldInteraction.PFAccId
           , vOldInteraction.PJAccId
        from dual;

      vExistInteraction  :=
         ACT_MGM_MANAGEMENT.ReInitialize(vCpnId, aTblFinMgmImp.IMF_TRANSACTION_DATE, vOldInteraction, vValidInteraction);

      -- Construction de l'XML
      select XMLElement
               (ACI_MGM_IMPUTATION
              , XMLElement
                  (LIST_ITEM
                 , XMLForest(vCpnFinNumber as CPN_NUMBER
                           , (select ACC_NUMBER
                                from ACS_ACCOUNT
                               where ACS_ACCOUNT_ID = vValidInteraction.CDAAccId) as CDA_NUMBER
                           , (select ACC_NUMBER
                                from ACS_ACCOUNT
                               where ACS_ACCOUNT_ID = vValidInteraction.PFAccId) as PF_NUMBER
                           , (select ACC_NUMBER
                                from ACS_ACCOUNT
                               where ACS_ACCOUNT_ID = vValidInteraction.PJAccId) as PJ_NUMBER
                           , aTblFinMgmImp.RCO_TITLE as RCO_TITLE
                           , REP_UTILS.DateToReplicatorDate(aTblFinMgmImp.IMF_TRANSACTION_DATE) as IMM_TRANSACTION_DATE
                           , REP_UTILS.DateToReplicatorDate(aTblFinMgmImp.IMF_VALUE_DATE) as IMM_VALUE_DATE
                           , aTblFinMgmImp.IMF_DESCRIPTION as IMM_DESCRIPTION
                           , aTblFinMgmImp.CURRENCY1 as CURRENCY1   --ME
                           , aTblFinMgmImp.CURRENCY2 as CURRENCY2   --MB
                           , to_char(aTblFinMgmImp.IMF_AMOUNT_LC_D - aTblFinMgmImp.TAX_VAT_AMOUNT_LC) as IMM_AMOUNT_LC_D
                           , to_char(aTblFinMgmImp.IMF_AMOUNT_LC_C) as IMM_AMOUNT_LC_C
                           , to_char(aTblFinMgmImp.IMF_AMOUNT_FC_D - aTblFinMgmImp.TAX_VAT_AMOUNT_FC) as IMM_AMOUNT_FC_D
                           , to_char(aTblFinMgmImp.IMF_AMOUNT_FC_C) as IMM_AMOUNT_FC_C
                           , to_char(aTblFinMgmImp.IMF_BASE_PRICE) as IMM_BASE_PRICE
                           , to_char(aTblFinMgmImp.IMF_EXCHANGE_RATE) as IMM_EXCHANGE_RATE
                           , 'MAN' as IMM_TYPE
                           , 'STD' as IMM_GENRE
                            )
                  )
               )
        into vResult
        from dual;
    end if;

    return vResult;
  end ExtractAciMgmImputation;

  /**
   * function ExtractAciPartImputation
   * Description
   *   Extraction des imputations partenaire du document venant de PCS
   */
  function ExtractAciPartImputation(
    aXML           in xmltype
  , aFinXml        in xmltype
  , aDocumentDate  in ACI_DOCUMENT.DOC_DOCUMENT_DATE%type
  , aCatProps      in TCatProperties
  , aDocCurrencies in TDocCurrencies
  )
    return xmltype
  is
    vResult                xmltype;
    vPathPayInfo  constant varchar2(73)              := vCntPathThisDoc || 'FINANCIAL_INFORMATION/PAYMENT_INFORMATION/';
    vPathTermsPay constant varchar2(48)                              := vCntPathThisDoc || 'TERMS_OF_PAYMENT/';
    vPerKey                varchar2(2000);
    vExchangeRate          ACS_PRICE_CURRENCY.PCU_DAYLY_PRICE%type;
    vBasePrice             ACS_PRICE_CURRENCY.PCU_BASE_PRICE%type;
  begin
    vPerKey  := GetPerKey(aXML);
    ACS_FUNCTION.GetExchangeRate(aDocumentDate, aDocCurrencies.MECurrencyId, 1, vExchangeRate, vBasePrice);

    select XMLElement(ACI_PART_IMPUTATION
                    , XMLElement(LIST_ITEM
                               , XMLForest(case
                                             when aCatProps.CSubSet = 'PAY' then vPerKey
                                           end as PER_SUPP_KEY1
                                         , case
                                             when aCatProps.CSubSet = 'PAY' then vPerKey
                                           end as PER_SUPP_KEY2
                                         , case
                                             when aCatProps.CSubSet = 'REC' then vPerKey
                                           end as PER_CUST_KEY1
                                         , case
                                             when aCatProps.CSubSet = 'REC' then vPerKey
                                           end as PER_CUST_KEY2
                                         , extractvalue(aXML, vPathPayInfo || 'PAYMENT_METHOD') as DES_DESCRIPTION_SUMMARY
                                         , extractvalue(aXML, vPathPayInfo || 'PAYMENT_REFERENCE') as PAR_REF_BVR
                                         , extractvalue(aXML, vPathPayInfo || 'FINANCIAL_REFERENCE') as FRE_ACCOUNT_NUMBER
                                         , extractvalue(aXML, vPathPayInfo || 'PAYMENT_ENCODING_LINE') as PAR_BVR_CODE
                                         , case
                                             when extractvalue(aXML, vPathTermsPay || 'IDENTIFIER') is not null
                                                  then com_lookup_functions.convert_value('LOG-002-1'
                                                                                          ,null
                                                                                          ,extractvalue(aXML, vPathTermsPay || 'IDENTIFIER')
                                                                                          ,'THIRD,DEF_VALUE')
                                           end PAC_PAYMENT_CONDITION_ID
                                         , case
                                             when extractvalue(aXML, vPathTermsPay || 'IDENTIFIER') is not null
                                               then null
                                             else
                                                extractvalue(aXML, vPathTermsPay || 'DESCRIPTION')
                                           end  PCO_DESCR
                                         , decode (upper(extractvalue(aXML, vPathTermsPay || 'BLOCKED_DOCUMENT'))
                                                  ,'TRUE',1
                                                  ,0
                                                  ) as PAR_BLOCKED_DOCUMENT
                                         , extractvalue(aXML, vPathTermsPay || 'BLOCKING_REASON') as DIC_BLOCKED_REASON_ID
                                         , extractvalue(aXML, vCntPathSender || 'DOCUMENT_NUMBER') as PAR_DOCUMENT
                                         , aDocCurrencies.DocCurrency as CURRENCY1   --ME
                                         , aDocCurrencies.MBCurrency as CURRENCY2   --MB
                                         , vBasePrice as PAR_BASE_PRICE
                                         , vExchangeRate as PAR_EXCHANGE_RATE
                                          )
                                 ,aFinXml
                                )
                     )
      into vResult
      from dual;

    return vResult;
  end ExtractAciPartImputation;

  /*
   * Construction de l'XML ACI_FINANCIAL_IMPUTATION selon la table ACI_FIN_MGM_IMP
   */
  function BuildXmlAciFinImputation(aWithMgm in signtype, aTblFinMgmImp in TFinMgmImputation)
    return xmltype
  is
    vResult xmltype;
    vXMLMgm xmltype;
  begin
    for vCpt in aTblFinMgmImp.first .. aTblFinMgmImp.last loop
      if     (aWithMgm > 0)
         and (aTblFinMgmImp(vCpt).IMF_PRIMARY = 0) then
        vXMLMgm  := ExtractAciMgmImputation(aTblFinMgmImp(vCpt) );
      else
        vXMLMgm  := null;
      end if;

      select XMLConcat
               (vResult
              , XMLElement
                  (LIST_ITEM
                 , XMLForest
                       (to_char(aTblFinMgmImp(vCpt).IMF_PRIMARY) as IMF_PRIMARY
                      , aTblFinMgmImp(vCpt).IMF_TYPE as IMF_TYPE
                      , aTblFinMgmImp(vCpt).IMF_GENRE as IMF_GENRE
                      , aTblFinMgmImp(vCpt).C_GENRE_TRANSACTION as C_GENRE_TRANSACTION
                      , aTblFinMgmImp(vCpt).IMF_DESCRIPTION as IMF_DESCRIPTION
                      , aTblFinMgmImp(vCpt).AUX_NUMBER as AUX_NUMBER
                      , aTblFinMgmImp(vCpt).ACC_NUMBER as ACC_NUMBER
                      , aTblFinMgmImp(vCpt).DIV_NUMBER as DIV_NUMBER
                      , aTblFinMgmImp(vCpt).RCO_TITLE as RCO_TITLE
                      , REP_UTILS.DateToReplicatorDate(aTblFinMgmImp(vCpt).IMF_TRANSACTION_DATE) as IMF_TRANSACTION_DATE
                      , REP_UTILS.DateToReplicatorDate(aTblFinMgmImp(vCpt).IMF_VALUE_DATE) as IMF_VALUE_DATE
                      , aTblFinMgmImp(vCpt).TAX_NUMBER as TAX_NUMBER
                      , to_char(aTblFinMgmImp(vCpt).TAX_LIABLED_AMOUNT) as TAX_LIABLED_AMOUNT
                      , to_char(aTblFinMgmImp(vCpt).TAX_LIABLED_RATE) as TAX_LIABLED_RATE
                      , to_char(aTblFinMgmImp(vCpt).TAX_RATE) as TAX_RATE
                      , to_char(aTblFinMgmImp(vCpt).TAX_VAT_AMOUNT_LC) as TAX_VAT_AMOUNT_LC
                      , to_char(aTblFinMgmImp(vCpt).TAX_VAT_AMOUNT_FC) as TAX_VAT_AMOUNT_FC
                      , to_char(aTblFinMgmImp(vCpt).IMF_BASE_PRICE) as IMF_BASE_PRICE
                      , to_char(aTblFinMgmImp(vCpt).IMF_EXCHANGE_RATE) as IMF_EXCHANGE_RATE
                      , to_char(aTblFinMgmImp(vCpt).DET_BASE_PRICE) as DET_BASE_PRICE
                      , to_char(aTblFinMgmImp(vCpt).TAX_EXCHANGE_RATE) as TAX_EXCHANGE_RATE
                      , aTblFinMgmImp(vCpt).TAX_INCLUDED_EXCLUDED as TAX_INCLUDED_EXCLUDED
                      , aTblFinMgmImp(vCpt).CURRENCY1 as CURRENCY1   --ME
                      , aTblFinMgmImp(vCpt).CURRENCY2 as CURRENCY2   --MB
                      , to_char(aTblFinMgmImp(vCpt).IMF_AMOUNT_LC_D) as IMF_AMOUNT_LC_D
                      , to_char(aTblFinMgmImp(vCpt).IMF_AMOUNT_LC_C) as IMF_AMOUNT_LC_C
                      , to_char(aTblFinMgmImp(vCpt).IMF_AMOUNT_FC_D) as IMF_AMOUNT_FC_D
                      , to_char(aTblFinMgmImp(vCpt).IMF_AMOUNT_FC_C) as IMF_AMOUNT_FC_C
                       )
                 , vXMLMgm   --Imputation analytique
                  )
               )
        into vResult
        from dual;
    end loop;

    if vResult is not null then
      select XMLElement(ACI_FINANCIAL_IMPUTATION, vResult)
        into vResult
        from dual;
    end if;

    return vResult;
  end BuildXmlAciFinImputation;

  /**
  * function ExtractAciFinImputation
  * Description
  *   Extraction des imputations financières du document venant de PCS
  */
  function ExtractAciFinImputation(
    aXML           in xmltype
  , aDocumentDate  in ACI_DOCUMENT.DOC_DOCUMENT_DATE%type
  , aCatProps      in TCatProperties
  , aDocCurrencies in TDocCurrencies
  )
    return xmltype
  is
    vAcsAuxAccountId ACS_AUXILIARY_ACCOUNT.ACS_AUXILIARY_ACCOUNT_ID%type;
    vAuxFinNumber    ACS_ACCOUNT.ACC_NUMBER%type;
    vAuxDivNumber    ACS_ACCOUNT.ACC_NUMBER%type;
    vFinCpnNumber    ACS_ACCOUNT.ACC_NUMBER%type;
    vAuxNumber       ACS_ACCOUNT.ACC_NUMBER%type;
    vIndex           integer;
    vTblFinMgmImp    TFinMgmImputation;
    vWithTaxCode     signtype;
    vFinVatCodeId    ACS_FINANCIAL_ACCOUNT.ACS_DEF_VAT_CODE_ID%type;
    vTempTax1Id      ACS_FINANCIAL_ACCOUNT.ACS_DEF_VAT_CODE_ID%type;
    vTempTax2Id      ACS_FINANCIAL_ACCOUNT.ACS_DEF_VAT_CODE_ID%type;
    vExchangeRate    ACS_PRICE_CURRENCY.PCU_DAYLY_PRICE%type;
    vBasePrice       ACS_PRICE_CURRENCY.PCU_BASE_PRICE%type;
    vVatExchangeRate ACS_PRICE_CURRENCY.PCU_DAYLY_PRICE%type;
    vVatBasePrice    ACS_PRICE_CURRENCY.PCU_BASE_PRICE%type;
    vPacPersonId     PAC_PERSON.PAC_PERSON_ID%type;
    vTaxIE           varchar2(1);
  begin
    --Recherche du compte auxiliaire selon le sous-ensemble géré par le catalogue
    GetAuxAccountId(aCatProps.CSubSet, GetPerKey(aXML), vAcsAuxAccountId, vPacPersonId);

    -- Contre-écritures: recherche du compte financier + division du partenaire renseigné dans le compte auxiliaire
    -- au cas ou le document xml ne contient pas ces infos
    select (select ACC_NUMBER
              from ACS_ACCOUNT
             where ACS_ACCOUNT_ID = AUX.ACS_FINANCIAL_ACCOUNT_ID) AUX_FIN_NUMBER
         , (select ACC_NUMBER
              from ACS_ACCOUNT
             where ACS_ACCOUNT_ID = ACS_FUNCTION.GetCpnOfFinAcc(AUX.ACS_FINANCIAL_ACCOUNT_ID) ) FIN_CPN_NUMBER
         , (select ACC_NUMBER
              from ACS_ACCOUNT
             where ACS_ACCOUNT_ID =
                     nvl(AUX.ACS_DIVISION_ACCOUNT_ID
                       , ACS_FUNCTION.GetDivisionOfAccount(AUX.ACS_FINANCIAL_ACCOUNT_ID
                                                         , AUX.ACS_DIVISION_ACCOUNT_ID
                                                         , aDocumentDate
                                                          )
                        ) ) FIN_DIV_NUMBER
      into vAuxFinNumber
         , vFinCpnNumber
         , vAuxDivNumber
      from ACS_AUXILIARY_ACCOUNT AUX
     where AUX.ACS_AUXILIARY_ACCOUNT_ID = vAcsAuxAccountId;

    ACS_FUNCTION.GetExchangeRate(aDocumentDate, aDocCurrencies.MECurrencyId, 6, vVatExchangeRate, vVatBasePrice);   -- Cours de change TVA
    ACS_FUNCTION.GetExchangeRate(aDocumentDate, aDocCurrencies.MECurrencyId, 1, vExchangeRate, vBasePrice);   -- Cours de change standard
    vVatBasePrice  := vBasePrice;   -- même montant que IMF_BASE_PRICE

    /*Génération d'abord des contre-écritures afin d'obtenir le montant total du document à  mettre dans l'imputation primaire
      Positions des montants dans la contre-écriture: REC -> au crédit
                                                      PAY -> au débit
    */
    for tblFinImp in
      (select nvl(extractvalue(column_value, 'POSITION/FINANCIAL_PART/GL_ACCOUNT_NUMBER'), vAuxFinNumber) ACC_NUMBER
            , nvl(extractvalue(column_value, 'POSITION/FINANCIAL_PART/DIVISION_NUMBER'), vAuxDivNumber) DIV_NUMBER
            , substr(nvl(nvl(extractvalue(column_value, 'POSITION/LOGISTICS_PART/PRODUCT_REFERENCES/PRODUCT_REFERENCE')
                           , extractvalue(column_value, 'POSITION/LOGISTICS_PART/PRODUCT_REFERENCES/DESCRIPTION_SHORT')
                            )
                       , extractvalue(column_value, 'POSITION/LOGISTICS_PART/PRODUCT_REFERENCES/DESCRIPTION_LONG')
                        )
                   , 1
                   , 100
                    ) IMF_DESCRIPTION
            , extractvalue(column_value, 'POSITION/FINANCIAL_PART/RECORD_NUMBER') RCO_TITLE
            , nvl(extractvalue(column_value, 'POSITION/FINANCIAL_PART/CPN_NUMBER'), vFinCpnNumber) CPN_NUMBER
            , extractvalue(column_value, 'POSITION/FINANCIAL_PART/CDA_NUMBER') CDA_NUMBER
            , extractvalue(column_value, 'POSITION/FINANCIAL_PART/PF_NUMBER') PF_NUMBER
            , extractvalue(column_value, 'POSITION/FINANCIAL_PART/PJ_NUMBER') PJ_NUMBER
            , to_number(extractvalue(column_value, 'POSITION/PRICE/POSITION_NET_AMOUNT_VAT_EXCL') ) TAX_LIABLED_AMOUNT
            , to_number(extractvalue(column_value, 'POSITION/PRICE/VAT/RATE') ) TAX_RATE
            , to_number(extractvalue(column_value, 'POSITION/PRICE/VAT/AMOUNT') ) TAX_VAT_AMOUNT
            , to_number(extractvalue(column_value, 'POSITION/PRICE/POSITION_NET_AMOUNT_VAT_INCL') ) IMF_AMOUNT
         from table(xmlsequence(extract(aXML, vCntPathPosition) ) ) ) loop
      vIndex  := vTblFinMgmImp.count;

      --La gestion du code TVA est dépendante du compte financier
      select nvl(max(FIN.FIN_VAT_POSSIBLE), 0) FIN_VAT_POSSIBLE
           , nvl(max(FIN.ACS_DEF_VAT_CODE_ID), 0) ACS_DEF_VAT_CODE_ID
        into vWithTaxCode
           , vFinVatCodeId
        from ACS_FINANCIAL_ACCOUNT FIN
           , ACS_ACCOUNT ACC
       where FIN.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
         and ACC.ACC_NUMBER = tblFinImp.ACC_NUMBER;

      -- Recherche du code taxe
      if ACS_FUNCTION.IsSelfTax(vFinVatCodeId, vTempTax1Id, vTempTax2Id) then   --auto-taxation
        vTaxIE  := 'S';
      else
        vTaxIE  := 'E';
      end if;

      select 0 IMF_PRIMARY
           , 'MAN' IMF_TYPE
           , 'STD' IMF_GENRE
           , '1' C_GENRE_TRANSACTION
           , tblFinImp.IMF_DESCRIPTION
           , aDocumentDate as IMF_TRANSACTION_DATE
           , aDocumentDate as IMF_VALUE_DATE
           , tblFinImp.ACC_NUMBER
           , tblFinImp.DIV_NUMBER
           , case
               when vWithTaxCode > 0 then (select ACC_NUMBER
                                             from ACS_ACCOUNT
                                            where ACS_ACCOUNT_ID =
                                                    nvl
                                                      (ACT_VAT_MANAGEMENT.GetInitVat
                                                                            (vFinVatCodeId
                                                                           , aCatProps.AcjCatalogueDocumentId
                                                                           , case
                                                                               when aCatProps.CSubSet = 'PAY' then vPacPersonId
                                                                               else 0
                                                                             end
                                                                           , case
                                                                               when aCatProps.CSubSet = 'REC' then vPacPersonId
                                                                               else 0
                                                                             end
                                                                            )
                                                     , 0
                                                      ) )
               else null
             end TAX_NUMBER
           , tblFinImp.RCO_TITLE
           , tblFinImp.CPN_NUMBER
           , tblFinImp.CDA_NUMBER
           , tblFinImp.PF_NUMBER
           , tblFinImp.PJ_NUMBER
           , case
               when vWithTaxCode > 0 then (select TAX_LIABLED_RATE
                                             from ACS_TAX_CODE
                                            where ACS_TAX_CODE_ID = vFinVatCodeId)
               else null
             end TAX_LIABLED_RATE
           , case
               when vWithTaxCode > 0 then (select TAX_DEDUCTIBLE_RATE
                                             from ACS_TAX_CODE
                                            where ACS_TAX_CODE_ID = vFinVatCodeId)
               else null
             end TAX_DEDUCTIBLE_RATE
           , case
               when vWithTaxCode > 0 then tblFinImp.TAX_RATE
               else null
             end TAX_RATE
           , case
               when vWithTaxCode > 0 then case
                                           when aDocCurrencies.IsMBDocument > 0 then tblFinImp.TAX_LIABLED_AMOUNT
                                           else ACS_FUNCTION.ConvertAmountForView
                                                                               (tblFinImp.TAX_LIABLED_AMOUNT   --aAmount
                                                                              , aDocCurrencies.MECurrencyId   --FromCurrId
                                                                              , aDocCurrencies.MBCurrencyId   --ToCurrId
                                                                              , aDocumentDate
                                                                              , vVatExchangeRate   --ExchangeRate
                                                                              , vVatBasePrice   --BasePrice
                                                                              , 1   --Arrondi finance
                                                                               )
                                         end
               else null
             end TAX_LIABLED_AMOUNT
           , case
               when vWithTaxCode > 0 then case
                                           when aDocCurrencies.IsMBDocument > 0 then tblFinImp.TAX_VAT_AMOUNT
                                           else ACS_FUNCTION.ConvertAmountForView
                                                                               (tblFinImp.TAX_VAT_AMOUNT   --aAmount
                                                                              , aDocCurrencies.MECurrencyId   --FromCurrId
                                                                              , aDocCurrencies.MBCurrencyId   --ToCurrId
                                                                              , aDocumentDate
                                                                              , vVatExchangeRate   --ExchangeRate
                                                                              , vVatBasePrice   --BasePrice
                                                                              , 1   --Arrondi finance
                                                                               )
                                         end
               else null
             end TAX_VAT_AMOUNT_LC
           , case
               when(vWithTaxCode > 0)
               and (aDocCurrencies.IsMBDocument = 0) then tblFinImp.TAX_VAT_AMOUNT
               else null
             end TAX_VAT_AMOUNT_FC
           , case
               when aCatProps.CSubSet = 'PAY' then case
                                                    when aDocCurrencies.IsMBDocument > 0 then tblFinImp.IMF_AMOUNT
                                                    else ACS_FUNCTION.ConvertAmountForView
                                                                               (tblFinImp.IMF_AMOUNT   --aAmount
                                                                              , aDocCurrencies.MECurrencyId   --FromCurrId
                                                                              , aDocCurrencies.MBCurrencyId   --ToCurrId
                                                                              , aDocumentDate
                                                                              , vExchangeRate   --ExchangeRate
                                                                              , vBasePrice   --BasePrice
                                                                              , 1   --Arrondi finance
                                                                               )
                                                  end
               else 0
             end IMF_AMOUNT_LC_D
           , case
               when aCatProps.CSubSet = 'REC' then case
                                                    when aDocCurrencies.IsMBDocument > 0 then tblFinImp.IMF_AMOUNT
                                                    else ACS_FUNCTION.ConvertAmountForView
                                                                               (tblFinImp.IMF_AMOUNT   --aAmount
                                                                              , aDocCurrencies.MECurrencyId   --FromCurrId
                                                                              , aDocCurrencies.MBCurrencyId   --ToCurrId
                                                                              , aDocumentDate
                                                                              , vExchangeRate   --ExchangeRate
                                                                              , vBasePrice   --BasePrice
                                                                              , 1   --Arrondi finance
                                                                               )
                                                  end
               else 0
             end IMF_AMOUNT_LC_C
           , case
               when aDocCurrencies.IsMBDocument > 0 then 0
               else vBasePrice
             end IMF_BASE_PRICE
           , case
               when aDocCurrencies.IsMBDocument > 0 then 0
               else vExchangeRate
             end IMF_EXCHANGE_RATE
           , case
               when vWithTaxCode > 0 then vVatBasePrice
               else 0
             end DET_BASE_PRICE
           , case
               when vWithTaxCode > 0 then vVatExchangeRate
               else 0
             end TAX_EXCHANGE_RATE
           , vTaxIE TAX_INCLUDED_EXCLUDED
           , case
               when(aDocCurrencies.IsMBDocument > 0)
                or (aCatProps.CSubSet = 'REC') then 0
               else tblFinImp.IMF_AMOUNT
             end IMF_AMOUNT_FC_D
           , case
               when(aDocCurrencies.IsMBDocument > 0)
                or (aCatProps.CSubSet = 'PAY') then 0
               else tblFinImp.IMF_AMOUNT
             end IMF_AMOUNT_FC_C
           , aDocCurrencies.DocCurrency as CURRENCY1   --ME
           , aDocCurrencies.MBCurrency as CURRENCY2   --MB
        into vTblFinMgmImp(vIndex).IMF_PRIMARY
           , vTblFinMgmImp(vIndex).IMF_TYPE
           , vTblFinMgmImp(vIndex).IMF_GENRE
           , vTblFinMgmImp(vIndex).C_GENRE_TRANSACTION
           , vTblFinMgmImp(vIndex).IMF_DESCRIPTION
           , vTblFinMgmImp(vIndex).IMF_TRANSACTION_DATE
           , vTblFinMgmImp(vIndex).IMF_VALUE_DATE
           , vTblFinMgmImp(vIndex).ACC_NUMBER
           , vTblFinMgmImp(vIndex).DIV_NUMBER
           , vTblFinMgmImp(vIndex).TAX_NUMBER
           , vTblFinMgmImp(vIndex).RCO_TITLE
           , vTblFinMgmImp(vIndex).CPN_NUMBER
           , vTblFinMgmImp(vIndex).CDA_NUMBER
           , vTblFinMgmImp(vIndex).PF_NUMBER
           , vTblFinMgmImp(vIndex).PJ_NUMBER
           , vTblFinMgmImp(vIndex).TAX_LIABLED_RATE
           , vTblFinMgmImp(vIndex).TAX_DEDUCTIBLE_RATE
           , vTblFinMgmImp(vIndex).TAX_RATE
           , vTblFinMgmImp(vIndex).TAX_LIABLED_AMOUNT
           , vTblFinMgmImp(vIndex).TAX_VAT_AMOUNT_LC
           , vTblFinMgmImp(vIndex).TAX_VAT_AMOUNT_FC
           , vTblFinMgmImp(vIndex).IMF_AMOUNT_LC_D
           , vTblFinMgmImp(vIndex).IMF_AMOUNT_LC_C
           , vTblFinMgmImp(vIndex).IMF_BASE_PRICE
           , vTblFinMgmImp(vIndex).IMF_EXCHANGE_RATE
           , vTblFinMgmImp(vIndex).DET_BASE_PRICE
           , vTblFinMgmImp(vIndex).TAX_EXCHANGE_RATE
           , vTblFinMgmImp(vIndex).TAX_INCLUDED_EXCLUDED
           , vTblFinMgmImp(vIndex).IMF_AMOUNT_FC_D
           , vTblFinMgmImp(vIndex).IMF_AMOUNT_FC_C
           , vTblFinMgmImp(vIndex).CURRENCY1
           , vTblFinMgmImp(vIndex).CURRENCY2
        from dual;
    end loop;

    -- Pré-saisie: ne garder qu'une position, les montants y seront cumulés
    if     (aCatProps.TypSupplierPermanent > 0)
       and (vTblFinMgmImp.count > 0) then
      SuppPermUpdOffsetEntries(aDocumentDate, aCatProps.AcjCatalogueDocumentId, vTblFinMgmImp);
    end if;

    -- Construction de l'imputation primaire
    --  Recherche du compte financier + division: aucune information ne vient du document XML.
    GetPrimaryFinDivAccount(vAcsAuxAccountId
                          , aDocumentDate
                          , aCatProps.AcjCatalogueDocumentId
                          , aCatProps.CTypCat
                          , aCatProps.TypSupplierPermanent
                          , vAuxFinNumber
                          , vAuxDivNumber
                          , vAuxNumber
                           );
    -- Description de l'imputation primaire:
      -- Modèle de libellé du catalogue (ACJ_CATALOGUE_DOCUMENT.ACJ_DESCRIPTION_TYPE_ID) ou
      -- libellé du catalogue (ACJ_CATALOGUE_DOCUMENT.CAT_DESCRIPTION);
      -- traduction selon langue de l'utilisateur du modèle de travail (ACJ_JOB_TYPE.PC_USER_ID)
    vIndex         := vTblFinMgmImp.count;

    select 1 as IMF_PRIMARY
         , 'MAN' IMF_TYPE
         , 'STD' IMF_GENRE
         , '1' C_GENRE_TRANSACTION
         , (select nvl( (select max(DES.DES_DESCR)
                           from ACJ_DESCRIPTION_TYPE DES
                          where DES.ACJ_DESCRIPTION_TYPE_ID = CAT.ACJ_DESCRIPTION_TYPE_ID)
                     , (select nvl(max(TRA.TRA_TEXT), CAT.CAT_DESCRIPTION)
                          from ACJ_TRADUCTION TRA
                         where TRA.PC_LANG_ID = (select nvl(PC_LANG_ID, 0)
                                                   from PCS.PC_USER
                                                  where PC_USER_ID = (select nvl(PC_USER_ID, 0)
                                                                        from ACJ_JOB_TYPE
                                                                       where ACJ_JOB_TYPE_ID = aCatProps.AcjJobTypeId) )
                           and TRA.ACJ_CATALOGUE_DOCUMENT_ID = aCatProps.AcjCatalogueDocumentId)
                      )
              from ACJ_CATALOGUE_DOCUMENT CAT
             where CAT.ACJ_CATALOGUE_DOCUMENT_ID = aCatProps.AcjCatalogueDocumentId) as IMF_DESCRIPTION
         , vAuxFinNumber
         , vAuxDivNumber
         , vAuxNumber
         , aDocumentDate as IMF_TRANSACTION_DATE
         , aDocumentDate as IMF_VALUE_DATE
         , aDocCurrencies.DocCurrency as CURRENCY1   --ME
         , aDocCurrencies.MBCurrency as CURRENCY2   --MB
         , case
             when aDocCurrencies.IsMBDocument > 0 then 0
             else vBasePrice
           end IMF_BASE_PRICE
         , case
             when aDocCurrencies.IsMBDocument > 0 then 0
             else vExchangeRate
           end IMF_EXCHANGE_RATE
      into vTblFinMgmImp(vIndex).IMF_PRIMARY
         , vTblFinMgmImp(vIndex).IMF_TYPE
         , vTblFinMgmImp(vIndex).IMF_GENRE
         , vTblFinMgmImp(vIndex).C_GENRE_TRANSACTION
         , vTblFinMgmImp(vIndex).IMF_DESCRIPTION
         , vTblFinMgmImp(vIndex).ACC_NUMBER
         , vTblFinMgmImp(vIndex).DIV_NUMBER
         , vTblFinMgmImp(vIndex).AUX_NUMBER
         , vTblFinMgmImp(vIndex).IMF_TRANSACTION_DATE
         , vTblFinMgmImp(vIndex).IMF_VALUE_DATE
         , vTblFinMgmImp(vIndex).CURRENCY1
         , vTblFinMgmImp(vIndex).CURRENCY2
         , vTblFinMgmImp(vIndex).IMF_BASE_PRICE
         , vTblFinMgmImp(vIndex).IMF_EXCHANGE_RATE
      from dual;

    -- Cumul des montants des contre-écritures à  mettre dans l'imputation primaire
    SetPrimaryImpAmounts(vIndex, vTblFinMgmImp);
    --Construction de l'XML ACI_FINANCIAL_IMPUTATION
    return BuildXmlAciFinImputation(aCatProps.WithMgm, vTblFinMgmImp);
  end ExtractAciFinImputation;

  /**
  * function ConvertDocXmlPCS_ACI
  * Description
  *   Convertion d'un document XML venant de PCS(ex: document scanné) en un format intégrable par l'ACI
  *   Structure du document aXML: voire le fichier xsd dans le même répertoire
  *   Structure du document retourné: voire description en en-tête de ce fichier
  */
  function ConvertDocXmlPCS_ACI(aXML in xmltype)
    return xmltype
  is
    vConversionVersion constant number                                  := 1.0;
    vDocumentVersion            number;
    vResult                     xmltype;
    vConvertedXml               xmltype;
    vTblFinMgmImp               TACI_FINANCIAL_IMPUTATION;
    vXmlFinImp                  xmltype;
    vXmlPartImp                 xmltype;
    vCatProps                   TCatProperties;
    vTotalAmount                ACI_DOCUMENT.DOC_TOTAL_AMOUNT_DC%type;
    vDocCurrencies              TDocCurrencies;
    vPathAmount                 varchar2(2000);
    vDocumentDate               ACI_DOCUMENT.DOC_DOCUMENT_DATE%type;
  begin
    -- Comparaison des versions du document reçu et de la procédure de conversion.
    -- Convertir le doument reçu si nécessaire
    select extractvalue(aXML, vCntPathControl || 'VERSION') DOC_VERSION
      into vDocumentVersion
      from dual;

    vConvertedXml  := CheckDocumentVersion(aXML, vConversionVersion, vDocumentVersion);

    -- On ne poursuit que si le catalogue + modèle sont identifiés
    if not InitializeJobTypeCatalogue(vCatProps, vConvertedXml) then
      return null;
    end if;

    --Recherche de la MB, la monnaie document et les ID correspondants
    InitializeCurrencys(aXML, vDocCurrencies);
    vDocumentDate  := trunc(GetDocumentDate(aXML) );
    vXmlFinImp     :=
      ExtractAciFinImputation(aXml             => vConvertedXml
                            , aDocumentDate    => vDocumentDate
                            , aCatProps        => vCatProps
                            , aDocCurrencies   => vDocCurrencies
                             );
    -- vXmlFinImp fait partie de vXmlPartImp
    vXmlPartImp    :=
      ExtractAciPartImputation(aXML             => vConvertedXml
                             , aFinXml          => vXmlFinImp
                             , aDocumentDate    => vDocumentDate
                             , aCatProps        => vCatProps
                             , aDocCurrencies   => vDocCurrencies
                              );
    vPathAmount    :=
      case
        when vCatProps.CSubSet = 'REC' then case
                                             when vDocCurrencies.IsMBDocument > 0 then 'IMF_AMOUNT_LC_D'
                                             else 'IMF_AMOUNT_FC_D'
                                           end
        else case
        when vDocCurrencies.IsMBDocument > 0 then 'IMF_AMOUNT_LC_C'
        else 'IMF_AMOUNT_FC_C'
      end
      end;

    select extractvalue(vXmlFinImp, '/ACI_FINANCIAL_IMPUTATION/LIST_ITEM[IMF_PRIMARY=1]/' || vPathAmount)
      into vTotalAmount
      from dual;

    -- vResult sera le fichier "ACI_compatible", reconstruit à  partir du document reçu.
    select XMLElement
             (ACI_DOCUMENT
            , XMLForest
                ('' as DOC_NUMBER
               , (select FYE_NO_EXERCICE
                    from ACS_FINANCIAL_YEAR
                   where vDocumentDate between FYE_START_DATE and FYE_END_DATE) as FYE_NO_EXERCICE
               , extractvalue(vConvertedXml, vCntPathSender || 'IDENTIFIER/LOGISTICS_COMPANY_NAME') as COM_NAME_DOC
               , extractvalue(vConvertedXml, vCntPathSender || 'IDENTIFIER/FINANCIAL_COMPANY_NAME') as COM_NAME_ACT
               , REP_UTILS.DateToReplicatorDate(to_date(replace(extractvalue(vConvertedXml
                                                                           , vCntPathSender || 'DOCUMENT_DATE'
                                                                            )
                                                              , 'T'
                                                              , ' '
                                                               )
                                                      , 'YYYY-MM-DD HH24:MI:SS'
                                                       )
                                               ) as DOC_DOCUMENT_DATE
               , vCatProps.CatKey as CAT_KEY
               , vCatProps.TypKey as TYP_KEY
               , '5' as C_INTERFACE_ORIGIN
               , '3' as C_INTERFACE_CONTROL
               , extractvalue(vConvertedXml, vCntPathThisDoc || 'CURRENCY') as CURRENCY
               , extractvalue(vConvertedXml, vCntPathThisDoc || 'FINANCIAL_INFORMATION/SOURCE') as DIC_DOC_SOURCE_ID
               , extractvalue(vConvertedXml, vCntPathThisDoc || 'FINANCIAL_INFORMATION/DESTINATION') as DIC_DOC_DESTINATION_ID
               , to_char(vTotalAmount) as DOC_TOTAL_AMOUNT_DC
               , extractvalue(vConvertedXml, vCntPathThisDoc || 'EXTERNAL_INFORMATION/TECHNICAL_DOCUMENT_NUMBER') as DOC_FREE_TEXT1
                )
            , vXmlPartImp
             )
      into vResult
      from dual;

    return vResult;
  end ConvertDocXmlPCS_ACI;

  /**
  * procedure IntegrateDocXmlPCS_ACI
  * Description
  *   Integration d'un document XML venant de PCS(ex: document scanné) via l'ACI
  */
  procedure IntegrateDocXmlPCS_ACI(aPC_EXCHANGE_DATA_IN_ID in PCS.PC_EXCHANGE_DATA_IN.PC_EXCHANGE_DATA_IN_ID%type)
  is
    vConvertedDocXml xmltype;
    vTemp            xmltype;
    vCreateAciDocId  ACI_DOCUMENT.ACI_DOCUMENT_ID%type               := 0;
    vTestMode        varchar2(5);   --TRUE / FALSE
    vDocXml          xmltype;   --Document XML venant de PC_EXCHANGE_DATA_IN
    vFinancialLink   ACI_DOCUMENT_STATUS.C_ACI_FINANCIAL_LINK%type;
  begin
    -- Seul un document prêt pour l'intégration ('09') peut être traité
    begin
      select xmltype.CREATEXML(EDI_XML_DOCUMENT)
        into vDocXml
        from PCS.PC_EXCHANGE_DATA_IN
       where PC_EXCHANGE_DATA_IN_ID = aPC_EXCHANGE_DATA_IN_ID
         and C_EDI_PROCESS_STATUS = '09';
    exception
      when no_data_found then
        vDocXml  := null;
    end;

    if vDocXml is not null then
      -- Contrôle que le format du document reçu doit bien être converti. Il est possible de recevoir un document déjà  prêt à  intégrer
      select extract(vDocXml, '/ACI_DOCUMENT')
        into vTemp
        from dual;

      if vTemp is not null then
        -- Le document est directement intégrable
        -- Le mode "test" n'est pas possible dans ce cas
        vCreateAciDocId  := ACI_XML_DOC_INTEGRATE.ImportXml_ACI_DOCUMENT(vDocXml);
      else
        vConvertedDocXml  := ConvertDocXmlPCS_ACI(vDocXml);   -- Le document y est converti

        if vConvertedDocXml is not null then
          select nvl(extractvalue(vDocXml, vCntPathControl || 'TEST_MODE'), 'FALSE') TEST_MODE
            into vTestMode
            from dual;

          if upper(vTestMode) != 'TRUE' then
            --Changement du statut finance
            update PCS.PC_EXCHANGE_DATA_IN
               set C_EDI_STATUS_ACT = '1'
             where PC_EXCHANGE_DATA_IN_ID = aPC_EXCHANGE_DATA_IN_ID;

            --Intégration dans l'ACI
            vCreateAciDocId  := ACI_XML_DOC_INTEGRATE.ImportXml_ACI_DOCUMENT(vConvertedDocXml);
          else   -- En mode test
            update PCS.PC_EXCHANGE_DATA_IN
               set EDI_IMPORTED_XML_DOCUMENT = vConvertedDocXml.getClobVal()
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where PC_EXCHANGE_DATA_IN_ID = aPC_EXCHANGE_DATA_IN_ID;
          end if;
        end if;
      end if;

      --Après l'appel de la procédure d'intrégration de l'XML (converti) en ACI, insérer l'identifiant ACI_DOCUMENT_ID dans la table PC_EXCHANGE_DATE_IN
      if vCreateAciDocId > 0 then
        -- Status entête interface finance
        select nvl(min(TYP.C_ACI_FINANCIAL_LINK), '3')
          into vFinancialLink
          from ACJ_JOB_TYPE_S_CATALOGUE JCA
             , ACJ_JOB_TYPE TYP
             , ACJ_CATALOGUE_DOCUMENT CAT
             , ACI_DOCUMENT DOC
         where DOC.ACI_DOCUMENT_ID = vCreateAciDocId
           and CAT.CAT_KEY = DOC.CAT_KEY
           and TYP.TYP_KEY = DOC.TYP_KEY
           and JCA.ACJ_JOB_TYPE_ID = TYP.ACJ_JOB_TYPE_ID
           and JCA.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID;

        if vFinancialLink in('8', '9') then
          vFinancialLink  := '3';
        end if;

        insert into ACI_DOCUMENT_STATUS
                    (ACI_DOCUMENT_STATUS_ID
                   , ACI_DOCUMENT_ID
                   , C_ACI_FINANCIAL_LINK
                    )
          select ACI_ID_SEQ.nextval
               , vCreateAciDocId
               , vFinancialLink
            from dual;

        update PCS.PC_EXCHANGE_DATA_IN
           set ACI_DOCUMENT_ID = vCreateAciDocId
         where PC_EXCHANGE_DATA_IN_ID = aPC_EXCHANGE_DATA_IN_ID;
      end if;
    end if;
  end IntegrateDocXmlPCS_ACI;
end ACI_XML_DOC_CONVERT;
