--------------------------------------------------------
--  DDL for Package Body DOC_INTERFACE_POSITION_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_INTERFACE_POSITION_FCT" 
is
/**************************************************************************************************/
  procedure GetGoodInfo(
    pGoodId        in     DOC_INTERFACE_POSITION.GCO_GOOD_ID%type
  , pGoodCharId1   in out DOC_INTERFACE_POSITION.GCO_CHARACTERIZATION_ID%type
  , pGoodCharId2   in out DOC_INTERFACE_POSITION.GCO_GCO_CHARACTERIZATION_ID%type
  , pGoodCharId3   in out DOC_INTERFACE_POSITION.GCO2_GCO_CHARACTERIZATION_ID%type
  , pGoodCharId4   in out DOC_INTERFACE_POSITION.GCO3_GCO_CHARACTERIZATION_ID%type
  , pGoodCharId5   in out DOC_INTERFACE_POSITION.GCO4_GCO_CHARACTERIZATION_ID%type
  , pGoodDelivery  in out DOC_INTERFACE_POSITION.C_PRODUCT_DELIVERY_TYP%type
  , pStkManagement in out GCO_PRODUCT.PDT_STOCK_MANAGEMENT%type   /*Gestion stock*/
  )
  is
    /*Déclaration du curseur sur l' interface*/
    cursor GoodInfo(pGoodId DOC_INTERFACE_POSITION.GCO_GOOD_ID%type)
    is
      select   CHA.GCO_CHARACTERIZATION_ID
             , PDT.C_PRODUCT_DELIVERY_TYP
             , PDT_STOCK_MANAGEMENT
          from GCO_CHARACTERIZATION CHA
             , GCO_PRODUCT PDT
         where PDT.GCO_GOOD_ID = pGoodId
           and CHA.GCO_GOOD_ID(+) = PDT.GCO_GOOD_ID
           and CHA.CHA_STOCK_MANAGEMENT = 1
           and PDT.PDT_STOCK_MANAGEMENT = 1
      order by CHA.GCO_CHARACTERIZATION_ID;

    /* Déclaration de réception des données du curseur*/
    Good GoodInfo%rowtype;
  begin
    pGoodCharId1   := null;
    pGoodCharId2   := null;
    pGoodCharId3   := null;
    pGoodCharId4   := null;
    pGoodCharId5   := null;
    pGoodDelivery  := '';

    /*Ouverture du curseur et réception des données du bien*/
    open GoodInfo(pGoodId);

    fetch GoodInfo
     into Good;

    while GoodInfo%found loop
      if pGoodCharId1 is null then
        pGoodCharId1  := Good.GCO_CHARACTERIZATION_ID;
      elsif pGoodCharId2 is null then
        pGoodCharId2  := Good.GCO_CHARACTERIZATION_ID;
      elsif pGoodCharId3 is null then
        pGoodCharId3  := Good.GCO_CHARACTERIZATION_ID;
      elsif pGoodCharId4 is null then
        pGoodCharId4  := Good.GCO_CHARACTERIZATION_ID;
      elsif pGoodCharId5 is null then
        pGoodCharId5  := Good.GCO_CHARACTERIZATION_ID;
      elsif pGoodDelivery = '' then
        pGoodDelivery  := Good.C_PRODUCT_DELIVERY_TYP;
      end if;

      pStkManagement  := Good.PDT_STOCK_MANAGEMENT;

      fetch GoodInfo
       into Good;
    end loop;

    close GoodInfo;
  end GetGoodInfo;

/**************************************************************************************************/
/* Retourne l'id du bien en fonction de sa référence, du tiers, etc.
*/
  function GetGoodInfo(aMajor_ref in varchar2, aRef_type in varchar2, aRef_party in varchar2, aThirdId in PAC_THIRD.PAC_THIRD_ID%type)
    return GCO_GOOD.GCO_GOOD_ID%type
  is
    result GCO_GOOD.GCO_GOOD_ID%type;
  begin
    if     (aRef_party = 'recipient')
       and (   aRef_type = 'internal'
            or aRef_type = 'ean') then
      select GCO_GOOD_ID
        into result
        from GCO_GOOD
       where GOO_MAJOR_REFERENCE = aMajor_ref;
    elsif     aRef_party = 'sender'
          and aRef_type = 'internal' then
      select GCO_GOOD_ID
        into result
        from GCO_COMPL_DATA_SALE
       where PAC_CUSTOM_PARTNER_ID = aThirdId
         and CDA_COMPLEMENTARY_REFERENCE = aMajor_ref;
    elsif     aRef_party = 'sender'
          and aRef_type = 'ean' then
      select GCO_GOOD_ID
        into result
        from GCO_COMPL_DATA_SALE
       where PAC_CUSTOM_PARTNER_ID = aThirdId
         and CDA_COMPLEMENTARY_EAN_CODE = aMajor_ref;
    end if;

    return result;
  exception
    when no_data_found then
      return null;
  end GetGoodInfo;

/**************************************************************************************************/
/* Retourne les champs de l'interface passé en paramètre
*/
  procedure GetInterfaceInfoForUpdate(
    pInterfaceId           in     DOC_INTERFACE.DOC_INTERFACE_ID%type
  , pInterfaceThirdId      in out DOC_INTERFACE.PAC_THIRD_ID%type
  ,   /*Tiers de l'interface*/
    pInterfaceLangId       in out DOC_INTERFACE.PC_LANG_ID%type
  ,   /*Langue de l'interface*/
    pInterfaceDicTypeSubId in out DOC_INTERFACE.DIC_TYPE_SUBMISSION_ID%type
  ,   /*Type de soumission de l'interface*/
    pInterfaceVatAccId     in out DOC_INTERFACE.ACS_VAT_DET_ACCOUNT_ID%type   /*Décompte TVA*/
  )
  is
    /*Déclaration du curseur sur l' interface*/
    cursor InterfaceInfo(pInterfaceId in DOC_INTERFACE.DOC_INTERFACE_ID%type)
    is
      select DOC_INTERFACE.PAC_THIRD_ID
           , DOC_INTERFACE.PC_LANG_ID
           , DOC_INTERFACE.DIC_TYPE_SUBMISSION_ID
           , DOC_INTERFACE.ACS_VAT_DET_ACCOUNT_ID
        from DOC_INTERFACE DOC_INTERFACE
       where DOC_INTERFACE.DOC_INTERFACE_ID = pInterfaceId;

    /* Déclaration de réception des données du curseur*/
    interface InterfaceInfo%rowtype;
  begin
    /*Ouverture du curseur et réception des données de l'interface*/
    open InterfaceInfo(pInterfaceId);

    fetch InterfaceInfo
     into interface;

    pInterfaceThirdId       := interface.PAC_THIRD_ID;
    pInterfaceLangId        := interface.PC_LANG_ID;
    pInterfaceDicTypeSubId  := interface.DIC_TYPE_SUBMISSION_ID;
    pInterfaceVatAccId      := interface.ACS_VAT_DET_ACCOUNT_ID;

    close InterfaceInfo;
  end GetInterfaceInfoForUpdate;

/**************************************************************************************************/
/* Retourne les champs de l'interface passé en paramètre
*/
  procedure GetInterfaceInfoForCreation(
    pInterfaceId          in     DOC_INTERFACE.DOC_INTERFACE_ID%type
  , pInterfaceThirdId     in out DOC_INTERFACE.PAC_THIRD_ID%type
  ,   /*Tiers de l'interface*/
    pInterfaceRepresentId in out DOC_INTERFACE.PAC_REPRESENTATIVE_ID%type
  ,   /*Représentant de l'en-tête*/
    pInterfaceRecordId    in out DOC_INTERFACE.DOC_RECORD_ID%type
  ,   /*Dossier de l'interface*/
    pInterfaceFreeTable1  in out DOC_INTERFACE.DIC_POS_FREE_TABLE_1_ID%type
  ,   /*Code tabelle libre 1 de l'en-tête*/
    pInterfaceText1       in out DOC_INTERFACE.DOI_TEXT_1%type
  ,   /*Champ Texte 1*/
    pInterfaceDecimal1    in out DOC_INTERFACE.DOI_DECIMAL_1%type
  ,   /*Champ décimal 1 */
    pInterfaceDate1       in out DOC_INTERFACE.DOI_DATE_1%type
  ,   /*Champ Date 1*/
    pInterfaceFreeTable2  in out DOC_INTERFACE.DIC_POS_FREE_TABLE_2_ID%type
  ,   /*Code tabelle libre 2 de l'en-tête*/
    pInterfaceText2       in out DOC_INTERFACE.DOI_TEXT_2%type
  ,   /*Champ Texte 2*/
    pInterfaceDecimal2    in out DOC_INTERFACE.DOI_DECIMAL_2%type
  ,   /*Champ décimal 2 */
    pInterfaceDate2       in out DOC_INTERFACE.DOI_DATE_2%type
  ,   /*Champ Date 2*/
    pInterfaceFreeTable3  in out DOC_INTERFACE.DIC_POS_FREE_TABLE_3_ID%type
  ,   /*Code tabelle libre 3 de l'en-tête*/
    pInterfaceText3       in out DOC_INTERFACE.DOI_TEXT_3%type
  ,   /*Champ Texte 3*/
    pInterfaceDecimal3    in out DOC_INTERFACE.DOI_DECIMAL_3%type
  ,   /*Champ décimal 3 */
    pInterfaceDate3       in out DOC_INTERFACE.DOI_DATE_3%type   /*Champ Date 3*/
  )
  is
    /*Déclaration du curseur sur l' interface*/
    cursor InterfaceInfo(pInterfaceId in DOC_INTERFACE.DOC_INTERFACE_ID%type)
    is
      select DOC_INTERFACE.PAC_THIRD_ID
           , DOC_INTERFACE.PAC_REPRESENTATIVE_ID
           , DOC_INTERFACE.DOC_RECORD_ID
           , DOC_INTERFACE.DIC_POS_FREE_TABLE_1_ID
           , DOC_INTERFACE.DOI_TEXT_1
           , nvl(DOC_INTERFACE.DOI_DECIMAL_1, 0) DOI_DECIMAL_1
           , DOC_INTERFACE.DOI_DATE_1
           , DOC_INTERFACE.DIC_POS_FREE_TABLE_2_ID
           , DOC_INTERFACE.DOI_TEXT_2
           , nvl(DOC_INTERFACE.DOI_DECIMAL_2, 0) DOI_DECIMAL_2
           , DOC_INTERFACE.DOI_DATE_2
           , DOC_INTERFACE.DIC_POS_FREE_TABLE_3_ID
           , DOC_INTERFACE.DOI_TEXT_3
           , nvl(DOC_INTERFACE.DOI_DECIMAL_3, 0) DOI_DECIMAL_3
           , DOC_INTERFACE.DOI_DATE_3
        from DOC_INTERFACE DOC_INTERFACE
       where DOC_INTERFACE.DOC_INTERFACE_ID = pInterfaceId;

    /* Déclaration de réception des données du curseur*/
    interface InterfaceInfo%rowtype;
  begin
    /*Ouverture du curseur et réception des données de l'interface*/
    open InterfaceInfo(pInterfaceId);

    fetch InterfaceInfo
     into interface;

    pInterfaceThirdId      := interface.PAC_THIRD_ID;
    pInterfaceRepresentId  := interface.PAC_REPRESENTATIVE_ID;
    pInterfaceRecordId     := interface.DOC_RECORD_ID;
    pInterfaceFreeTable1   := interface.DIC_POS_FREE_TABLE_1_ID;
    pInterfaceText1        := interface.DOI_TEXT_1;
    pInterfaceDecimal1     := interface.DOI_DECIMAL_1;
    pInterfaceDate1        := interface.DOI_DATE_1;
    pInterfaceFreeTable2   := interface.DIC_POS_FREE_TABLE_2_ID;
    pInterfaceText2        := interface.DOI_TEXT_2;
    pInterfaceDecimal2     := interface.DOI_DECIMAL_2;
    pInterfaceDate2        := interface.DOI_DATE_2;
    pInterfaceFreeTable3   := interface.DIC_POS_FREE_TABLE_3_ID;
    pInterfaceText3        := interface.DOI_TEXT_3;
    pInterfaceDecimal3     := interface.DOI_DECIMAL_3;
    pInterfaceDate3        := interface.DOI_DATE_3;

    close InterfaceInfo;
  end GetInterfaceInfoForCreation;

/**************************************************************************************************/
  procedure GetConfigGaugeInfo(
    pConfigGaugeId               in     DOC_GAUGE.DOC_GAUGE_ID%type
  , pConfigGaugeIncludeTaxTariff in out DOC_GAUGE_POSITION.GAP_INCLUDE_TAX_TARIFF%type
  ,   /*Prix TTC du gabarit position*/
    pConfigGaugeRecord           in out DOC_GAUGE.GAU_DOSSIER%type
  ,   /*Gestion dossier du gabarit*/
    pConfigGaugeTraveller        in out DOC_GAUGE.GAU_TRAVELLER%type   /*Gestion représentant du gabarit*/
  )
  is
    /*Déclaration du curseur sur l' interface*/
    cursor ConfigGaugeInfo(pConfigGaugeId in DOC_GAUGE.DOC_GAUGE_ID%type)
    is
      select DOC_GAUGE_POSITION.GAP_INCLUDE_TAX_TARIFF
           , DOC_GAUGE.GAU_DOSSIER
           , DOC_GAUGE.GAU_TRAVELLER
        from DOC_GAUGE DOC_GAUGE
           , DOC_GAUGE_POSITION
       where DOC_GAUGE.DOC_GAUGE_ID = pConfigGaugeId
         and DOC_GAUGE_POSITION.DOC_GAUGE_ID(+) = DOC_GAUGE.DOC_GAUGE_ID
         and DOC_GAUGE_POSITION.C_GAUGE_TYPE_POS(+) = '1';

    /* Déclaration de réception des données du curseur*/
    ConfigGauge ConfigGaugeInfo%rowtype;
  begin
    /*Ouverture du curseur et réception des données du gabarit*/
    open ConfigGaugeInfo(pConfigGaugeId);

    fetch ConfigGaugeInfo
     into ConfigGauge;

    pConfigGaugeIncludeTaxTariff  := ConfigGauge.GAP_INCLUDE_TAX_TARIFF;
    pConfigGaugeRecord            := ConfigGauge.GAU_DOSSIER;
    pConfigGaugeTraveller         := ConfigGauge.GAU_TRAVELLER;

    close ConfigGaugeInfo;
  end GetConfigGaugeInfo;

/**************************************************************************************************/
/* Retourne le n° de position
*/
  function GetNewPosNumber(pGaugeId DOC_GAUGE.DOC_GAUGE_ID%type, pDocumentId DOC_INTERFACE.DOC_INTERFACE_ID%type)
    return DOC_INTERFACE_POSITION.DOP_POS_NUMBER%type
  is
    vMaxPosNumber DOC_INTERFACE_POSITION.DOP_POS_NUMBER%type;   /* Num max du document*/
    vStartNum     DOC_GAUGE_STRUCTURED.GAS_FIRST_NO%type;   /* Pemier n° de pas de la numérotation*/
    vIncrement    DOC_GAUGE_STRUCTURED.GAS_INCREMENT%type;   /* Incrémentation */
    vStep         DOC_GAUGE_STRUCTURED.GAS_INCREMENT_NBR%type;   /* Pas d'incrément */
  begin
    select GAS_FIRST_NO
         , GAS_INCREMENT
         , GAS_INCREMENT_NBR
      into vStartNum
         , vIncrement
         , vStep
      from DOC_GAUGE_STRUCTURED
     where DOC_GAUGE_ID = pGaugeId;

    select nvl(max(DOP_POS_NUMBER), 0)
      into vMaxPosNumber
      from DOC_INTERFACE_POSITION
     where DOC_INTERFACE_ID = pDocumentId;

    if vMaxPosNumber = 0 then
      return(vStartNum);
    else
      if vIncrement = 1 then
        return(vMaxPosNumber + vStep);
      else
        return(vMaxPosNumber);
      end if;
    end if;
  end GetNewPosNumber;

/**************************************************************************************************/
  procedure GetComplData(
    aGoodID       in     DOC_INTERFACE_POSITION.GCO_GOOD_ID%type
  , aThirdID      in     DOC_INTERFACE.PAC_THIRD_ID%type
  , aDicComplData in     GCO_COMPL_DATA_SALE.DIC_COMPLEMENTARY_DATA_ID%type
  , aAdminDomain  in     DOC_GAUGE.C_ADMIN_DOMAIN%type
  , aTypePos      in out DOC_INTERFACE_POSITION.C_GAUGE_TYPE_POS%type
  , aStockId      in out DOC_INTERFACE_POSITION.STM_STOCK_ID%type
  , aLocationId   in out DOC_INTERFACE_POSITION.STM_LOCATION_ID%type
  )
  is
    /* Données compl de Vente */
    cursor crGetComplDataSale(
      cGoodID       in DOC_INTERFACE_POSITION.GCO_GOOD_ID%type
    , cThirdID      in DOC_INTERFACE.PAC_THIRD_ID%type
    , cDicComplData in GCO_COMPL_DATA_SALE.DIC_COMPLEMENTARY_DATA_ID%type
    )
    is
      select   1 CAS
             , CSA.C_GAUGE_TYPE_POS
             , STM_STOCK_ID
             , STM_LOCATION_ID
          from GCO_COMPL_DATA_SALE CSA
         where CSA.GCO_GOOD_ID = cGoodID
           and CSA.PAC_CUSTOM_PARTNER_ID = cThirdID
           and CSA.DIC_COMPLEMENTARY_DATA_ID is null
      union all
      select   2 CAS
             , CSA.C_GAUGE_TYPE_POS
             , STM_STOCK_ID
             , STM_LOCATION_ID
          from GCO_COMPL_DATA_SALE CSA
         where CSA.GCO_GOOD_ID = cGoodID
           and CSA.PAC_CUSTOM_PARTNER_ID is null
           and CSA.DIC_COMPLEMENTARY_DATA_ID = cDicComplData
      union all
      select   3 CAS
             , CSA.C_GAUGE_TYPE_POS
             , STM_STOCK_ID
             , STM_LOCATION_ID
          from GCO_COMPL_DATA_SALE CSA
         where CSA.GCO_GOOD_ID = cGoodID
           and CSA.PAC_CUSTOM_PARTNER_ID is null
           and CSA.DIC_COMPLEMENTARY_DATA_ID is null
      union all
      select   4 CAS
             , ''
             , STM_STOCK_ID
             , STM_LOCATION_ID
          from GCO_PRODUCT PDT
         where PDT.GCO_GOOD_ID = cGoodID
      order by 1;

    /* Données compl d' Achat */
    cursor crGetComplDataPurchase(
      cGoodID       in DOC_INTERFACE_POSITION.GCO_GOOD_ID%type
    , cThirdID      in DOC_INTERFACE.PAC_THIRD_ID%type
    , cDicComplData in GCO_COMPL_DATA_SALE.DIC_COMPLEMENTARY_DATA_ID%type
    )
    is
      select   1 CAS
             , STM_STOCK_ID
             , STM_LOCATION_ID
          from GCO_COMPL_DATA_PURCHASE
         where GCO_GOOD_ID = cGoodID
           and PAC_SUPPLIER_PARTNER_ID = cThirdID
           and DIC_COMPLEMENTARY_DATA_ID is null
      union all
      select   2 CAS
             , STM_STOCK_ID
             , STM_LOCATION_ID
          from GCO_COMPL_DATA_PURCHASE
         where GCO_GOOD_ID = cGoodID
           and PAC_SUPPLIER_PARTNER_ID is null
           and DIC_COMPLEMENTARY_DATA_ID = cDicComplData
      union all
      select   3 CAS
             , STM_STOCK_ID
             , STM_LOCATION_ID
          from GCO_COMPL_DATA_PURCHASE
         where GCO_GOOD_ID = cGoodID
           and PAC_SUPPLIER_PARTNER_ID is null
           and DIC_COMPLEMENTARY_DATA_ID is null
      union all
      select   4 CAS
             , STM_STOCK_ID
             , STM_LOCATION_ID
          from GCO_PRODUCT PDT
         where GCO_GOOD_ID = cGoodID
      order by 1;

    tplComplDataSale     crGetComplDataSale%rowtype;
    tplComplDataPurchase crGetComplDataPurchase%rowtype;
  begin
    if aAdminDomain = '2' then
      /*Ouverture du curseur et réception des données complémentaires de vente*/
      open crGetComplDataSale(aGoodID, aThirdID, aDicComplData);

      fetch crGetComplDataSale
       into tplComplDataSale;

      while crGetComplDataSale%found loop
        if     (tplComplDataSale.C_GAUGE_TYPE_POS <> '')
           and (aTypePos = '') then
          aTypePos  := tplComplDataSale.C_GAUGE_TYPE_POS;
        end if;

        if     (tplComplDataSale.STM_STOCK_ID is not null)
           and (aStockID is null) then
          aStockID  := tplComplDataSale.STM_STOCK_ID;
        end if;

        if     (tplComplDataSale.STM_LOCATION_ID is not null)
           and (aLocationID is null) then
          aLocationID  := tplComplDataSale.STM_LOCATION_ID;
        end if;

        fetch crGetComplDataSale
         into tplComplDataSale;
      end loop;

      close crGetComplDataSale;
    else
      -- Le type de position n'est pas dans les données compl d'achat
      aTypePos  := '';

      /*Ouverture du curseur et réception des données complémentaires d'achat*/
      open crGetComplDataPurchase(aGoodID, aThirdID, aDicComplData);

      fetch crGetComplDataPurchase
       into tplComplDataPurchase;

      while crGetComplDataPurchase%found loop
        if     (tplComplDataPurchase.STM_STOCK_ID is not null)
           and (aStockID is null) then
          aStockID  := tplComplDataPurchase.STM_STOCK_ID;
        end if;

        if     (tplComplDataPurchase.STM_LOCATION_ID is not null)
           and (aLocationID is null) then
          aLocationID  := tplComplDataPurchase.STM_LOCATION_ID;
        end if;

        fetch crGetComplDataPurchase
         into tplComplDataPurchase;
      end loop;

      close crGetComplDataPurchase;
    end if;

    /*Pas de stock dans les données compl. -> Config*/
    if aStockID is null then
      begin
        select   STO.STM_STOCK_ID
               , LOC.STM_LOCATION_ID
            into aStockID
               , aLocationID
            from STM_STOCK STO
               , STM_LOCATION LOC
           where upper(STO.STO_DESCRIPTION) = upper(PCS.PC_CONFIG.GETCONFIG('GCO_DefltSTOCK') )
             and LOC.STM_STOCK_ID(+) = STO.STM_STOCK_ID
             and rownum = 1
        order by LOC.LOC_CLASSIFICATION asc;
      exception
        when no_data_found then
          RAISE_APPLICATION_ERROR(-20001, 'No stock available');
      end;
    end if;
  end GetComplData;

/**************************************************************************************************/
  function GetVatCode(
    pCode            in number
  , pThirdId         in DOC_INTERFACE.PAC_THIRD_ID%type
  , pGoodId          in DOC_INTERFACE_POSITION.GCO_GOOD_ID%type
  , pDiscountId      in PTC_DISCOUNT.PTC_DISCOUNT_ID%type
  , pChargeId        in PTC_CHARGE.PTC_CHARGE_ID%type
  , pAdminDomain     in DOC_GAUGE.C_ADMIN_DOMAIN%type
  , pSubmissionType  in DIC_TYPE_SUBMISSION.DIC_TYPE_SUBMISSION_ID%type
  , pMovementType    in DIC_TYPE_MOVEMENT.DIC_TYPE_MOVEMENT_ID%type
  , pVatDetAccountId in ACS_VAT_DET_ACCOUNT.ACS_VAT_DET_ACCOUNT_ID%type
  )
    return ACS_TAX_CODE.ACS_TAX_CODE_ID%type
  is
    vSubmissionType  DIC_TYPE_SUBMISSION.DIC_TYPE_SUBMISSION_ID%type;
    vTypeVatGood     DIC_TYPE_VAT_GOOD.DIC_TYPE_VAT_GOOD_ID%type;
    vVatDetAccountId ACS_VAT_DET_ACCOUNT.ACS_VAT_DET_ACCOUNT_ID%type;
    vResult          ACS_TAX_CODE.ACS_TAX_CODE_ID%type;
  begin
    /*Recherche du décompte TVA et du type de soumission*/
    if pThirdId is null then   /*Sans liaison avec partenaire*/
      vSubmissionType  := PCS.PC_CONFIG.GetConfig('DOC_DefltTYPE_SUBMISSION');

      select nvl(pVatDetAccountId, max(ACS_VAT_DET_ACCOUNT_ID) )
        into vVatDetAccountId
        from ACS_VAT_DET_ACCOUNT
       where VDE_DEFAULT = 1;
    else   /*Avec liaison partenaire*/
      select nvl(pSubmissionType, decode(pAdminDomain, '2', CUS.DIC_TYPE_SUBMISSION_ID, '1', SUP.DIC_TYPE_SUBMISSION_ID, '5', SUP.DIC_TYPE_SUBMISSION_ID) )
           , nvl(pVatDetAccountId, decode(pAdminDomain, '2', CUS.ACS_VAT_DET_ACCOUNT_ID, '1', SUP.ACS_VAT_DET_ACCOUNT_ID, '5', SUP.ACS_VAT_DET_ACCOUNT_ID) )
        into vSubmissionType
           , vVatDetAccountId
        from PAC_PERSON PER
           , PAC_CUSTOM_PARTNER CUS
           , PAC_SUPPLIER_PARTNER SUP
       where PER.PAC_PERSON_ID = pThirdId
         and CUS.PAC_CUSTOM_PARTNER_ID(+) = PER.PAC_PERSON_ID
         and SUP.PAC_SUPPLIER_PARTNER_ID(+) = PER.PAC_PERSON_ID
         and SUP.C_PARTNER_STATUS(+) = '1'
         and CUS.C_PARTNER_STATUS(+) = '1';
    end if;

    /*Position de type bien*/
    if pCode = 1 then
      select nvl(max(DIC_TYPE_VAT_GOOD_ID), PCS.PC_CONFIG.GetConfig('GCO_DefltTYPE_VAT_GOOD') )
        into vTypeVatGood
        from GCO_VAT_GOOD
       where GCO_GOOD_ID = pGoodId
         and ACS_VAT_DET_ACCOUNT_ID = vVatdetAccountId;
    /*Position de type valeur*/
    elsif pCode = 2 then
      vTypeVatGood  := PCS.PC_CONFIG.GetConfig('DOC_DefltVALUE_TYPE_VAT_GOOD');
    /*Remise de document*/
    elsif pCode = 3 then
      select nvl(max(DIC_TYPE_VAT_GOOD_ID), PCS.PC_CONFIG.GetConfig('PTC_DefltDISCOUNTTYPE_VAT_GOOD') )
        into vTypeVatGood
        from PTC_VAT_DISCOUNT
       where PTC_DISCOUNT_ID = pDiscountId
         and ACS_VAT_DET_ACCOUNT_ID = vVatdetAccountId;
    /*Charge de document*/
    elsif pCode = 4 then
      select nvl(max(DIC_TYPE_VAT_GOOD_ID), PCS.PC_CONFIG.GetConfig('PTC_DefltCHARGETYPE_VAT_GOOD') )
        into vTypeVatGood
        from PTC_VAT_CHARGE
       where PTC_CHARGE_ID = pChargeId
         and ACS_VAT_DET_ACCOUNT_ID = vVatdetAccountId;
    /*Frais de document*/
    elsif pCode = 5 then
      vTypeVatGood  := PCS.PC_CONFIG.GetConfig('DOC_DefltCOSTTYPE_VAT_GOOD');
    end if;

    /*Recherche d'un code taxe et initialisation de la valeur de retour de la fonction*/
    select max(ACS_TAX_CODE_ID)
      into vResult
      from ACS_TAX_CODE
     where ACS_VAT_DET_ACCOUNT_ID = vVatDetAccountId
       and DIC_TYPE_SUBMISSION_ID = vSubmissionType
       and DIC_TYPE_MOVEMENT_ID = pMovementType
       and DIC_TYPE_VAT_GOOD_ID = vTypeVatGood;

    return vResult;
  end GetVatCode;

/**************************************************************************************************/
  procedure GetStockAndLocation(
    pGoodId           in     DOC_INTERFACE_POSITION.GCO_GOOD_ID%type
  ,   /*Bien courant*/
    pComplStockId     in     DOC_INTERFACE_POSITION.STM_STOCK_ID%type
  ,   /*Stock des données complémentaires*/
    pComplLocationId  in     DOC_INTERFACE_POSITION.STM_LOCATION_ID%type
  ,   /*Emplacement des données complémentaires*/
    pInitStk          in     DOC_GAUGE_POSITION.GAP_INIT_STOCK_PLACE%type
  ,   /*Initialisation stock et emplacement*/
    pUseMvtStk        in     DOC_GAUGE_POSITION.GAP_MVT_UTILITY%type
  ,   /*Utilisation du stock du mouvement*/
    pMvtKindId        in     DOC_GAUGE_POSITION.STM_MOVEMENT_KIND_ID%type
  ,   /*Genre de mouvement*/
    pStkmanagement    in     GCO_PRODUCT.PDT_STOCK_MANAGEMENT%type
  ,   /*Gestion stock*/
    pStockId          in out DOC_INTERFACE_POSITION.STM_STOCK_ID%type
  ,   /*stock recherché*/
    pLocationID       in out DOC_INTERFACE_POSITION.STM_LOCATION_ID%type
  ,   /*Emplacement recherché*/
    pTargetStockID    in out DOC_INTERFACE_POSITION.STM_STOCK_ID%type
  ,   /*Stock de transfert recherché*/
    pTargetLocationID in out DOC_INTERFACE_POSITION.STM_LOCATION_ID%type   /*Emplacement de transfert recherché*/
  )
  is
    vTargetMvtId DOC_GAUGE_POSITION.STM_MOVEMENT_KIND_ID%type;   /*Genre de mouvement lié au genre de mvt passé en param*/
  begin
    /*Le gabarit de config ne demande pas d'initialisation des stocks et emplacement*/
    if pInitStk = 0 then
      pStockId           := 0;
      pLocationID        := 0;
      pTargetStockID     := 0;
      pTargetLocationID  := 0;
    else
      /*Pas de gestion de stock -> Stock virtuel*/
      if pStkmanagement = 0 then
        select STM_STOCK_ID
          into pStockId
          from STM_STOCK
         where C_ACCESS_METHOD = 'DEFAULT';
      -- Inventaire uniquement
      elsif pStkmanagement = 2 then
        begin
          select STM_STOCK_ID
               , STM_LOCATION_ID
            into pStockId
               , pLocationID
            from GCO_PRODUCT
           where GCO_GOOD_ID = pGoodId;
        exception
          when no_data_found then
            pStockId     := 0;
            pLocationID  := 0;
        end;
      else
        /*Utilisation du stock du genre de mvt et genre de mvt existre*/
        if     (pUseMvtStk = 1)
           and (pMvtKindId is not null) then
          select MVT.STM_STOCK_ID
               , TRA.STM_STOCK_ID
               , TRA.STM_MOVEMENT_KIND_ID
            into pStockId
               , pTargetStockID
               , vTargetMvtId
            from STM_MOVEMENT_KIND MVT
               , STM_MOVEMENT_KIND TRA
           where MVT.STM_MOVEMENT_KIND_ID = pMvtKindId
             and TRA.STM_MOVEMENT_KIND_ID(+) = MVT.STM_STM_MOVEMENT_KIND_ID;
        else   /*Reprise du stock des données complémentaires*/
          pStockId     := pComplStockId;
          pLocationID  := pComplLocationId;
        end if;

        /*Premier emplacement selon classement des stocks*/
        if     (pLocationId is null)
           and (pStockId is not null) then
          select STM_LOCATION_ID
            into pLocationId
            from STM_LOCATION
           where STM_STOCK_ID = pStockId
             and LOC_CLASSIFICATION = (select min(LOC_CLASSIFICATION)
                                         from STM_LOCATION
                                        where STM_STOCK_ID = pStockId);
        end if;

        if vTargetMvtId is not null then
          if (pTargetStockID is null) then
            pTargetStockID     := pComplStockId;
            pTargetLocationID  := pComplLocationId;
          end if;

          if     (pTargetLocationID is null)
             and (pTargetStockID is not null) then
            select STM_LOCATION_ID
              into pTargetLocationID
              from STM_LOCATION
             where STM_STOCK_ID = pTargetStockID
               and LOC_CLASSIFICATION = (select min(LOC_CLASSIFICATION)
                                           from STM_LOCATION
                                          where STM_STOCK_ID = pTargetStockID);
          end if;
        end if;
      end if;
    end if;
  end GetStockAndLocation;

  /**
  * procedure GetPosPrice
  * Description
  *   Recherche le prix unitaire
  */
  procedure GetPosPrice(
    iGoodID        in     GCO_GOOD.GCO_GOOD_ID%type
  , iQuantity      in     DOC_POSITION.POS_BASIS_QUANTITY%type
  , iThirdID       in     PAC_THIRD.PAC_THIRD_ID%type
  , iRecordID      in     DOC_RECORD.DOC_RECORD_ID%type
  , iGaugeID       in     DOC_GAUGE.DOC_GAUGE_ID%type
  , iFinCurrID     in     ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , iDicTariffID   in     varchar2
  , oGoodPrice     out    DOC_POSITION.POS_GROSS_UNIT_VALUE%type
  , oNetTariff     out    DOC_POSITION.POS_NET_TARIFF%type
  , oSpecialTariff out    DOC_POSITION.POS_SPECIAL_TARIFF%type
  , oFlatRate      out    DOC_POSITION.POS_FLAT_RATE%type
  )
  is
    cursor crGaugeInfo(iGaugeID in DOC_GAUGE.DOC_GAUGE_ID%type)
    is
      select   GAU.C_ADMIN_DOMAIN
             , GAS.C_ROUND_TYPE
             , GAS.GAS_ROUND_AMOUNT
             , GAP.DIC_TARIFF_ID GAP_DIC_TARIFF_ID
             , GAP.GAP_FORCED_TARIFF
             , GAP.C_GAUGE_INIT_PRICE_POS
             , GAP.C_ROUND_APPLICATION
          from DOC_GAUGE GAU
             , DOC_GAUGE_STRUCTURED GAS
             , DOC_GAUGE_POSITION GAP
         where GAU.DOC_GAUGE_ID = iGaugeID
           and GAU.DOC_GAUGE_ID = GAP.DOC_GAUGE_ID
           and GAP.C_GAUGE_TYPE_POS = '1'
      order by nvl(GAP.GAP_DEFAULT, 0) desc;

    ltplGaugeInfo   crGaugeInfo%rowtype;
    lvDicTariffID   DOC_POSITION.DIC_TARIFF_ID%type;
    lnTariffUnit    DOC_POSITION.POS_TARIFF_UNIT%type;
    lnConvertFactor GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type;
  begin
    open crGaugeInfo(iGaugeID);

    fetch crGaugeInfo
     into ltplGaugeInfo;

    if crGaugeInfo%found then
      -- Recherche le facteur de conversion sur la donnée compl
      lnConvertFactor  := nvl(GCO_LIB_COMPL_DATA.GetConvertFactor(iGoodID => iGoodID, iThirdId => iThirdID, iAdminDomain => ltplGaugeInfo.C_ADMIN_DOMAIN), 1);
      --
      DOC_POSITION_FUNCTIONS.GetPosUnitPrice(aGoodID              => iGoodID
                                           , aQuantity            => iQuantity
                                           , aConvertFactor       => lnConvertFactor
                                           , aRecordID            => iRecordID
                                           , aFalScheduleStepID   => null
                                           , aDateRef             => trunc(sysdate)
                                           , aAdminDomain         => ltplGaugeInfo.C_ADMIN_DOMAIN
                                           , aThirdID             => iThirdID
                                           , aDmtTariffID         => iDicTariffID
                                           , aDocCurrencyID       => iFinCurrID
                                           , aExchangeRate        => 0 -- use official rate
                                           , aBasePrice           => 0 -- use official rate
                                           , aRoundType           => ltplGaugeInfo.C_ROUND_TYPE
                                           , aRoundAmount         => ltplGaugeInfo.GAS_ROUND_AMOUNT
                                           , aGapTariffID         => ltplGaugeInfo.GAP_DIC_TARIFF_ID
                                           , aForceTariff         => ltplGaugeInfo.GAP_FORCED_TARIFF
                                           , aTypePrice           => ltplGaugeInfo.C_GAUGE_INIT_PRICE_POS
                                           , aRoundApplication    => ltplGaugeInfo.C_ROUND_APPLICATION
                                           , aUnitPrice           => oGoodPrice
                                           , aTariffID            => lvDicTariffID
                                           , aNetTariff           => oNetTariff
                                           , aSpecialTariff       => oSpecialTariff
                                           , aFlatRate            => oFlatRate
                                           , aTariffUnit          => lnTariffUnit
                                            );
    end if;

    close crGaugeInfo;
  end GetPosPrice;
end DOC_INTERFACE_POSITION_FCT;
