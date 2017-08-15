--------------------------------------------------------
--  DDL for Package Body GCO_LIB_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_LIB_FUNCTIONS" 
is
  -- constantes
  -- constantes descodes
  -- C_CHARAC_TYPE
  gcCharacTypeVersion        constant char(1) := '1';
  gcCharacTypeCharacteristic constant char(1) := '2';
  gcCharacTypePiece          constant char(1) := '3';
  gcCharacTypeSet            constant char(1) := '4';
  gcCharacTypeChrono         constant char(1) := '5';
  -- C_ELEMENT_TYPE
  gcElementTypeSet           constant char(2) := '01';
  gcElementTypePiece         constant char(2) := '02';
  gcElementTypeVersion       constant char(2) := '03';
  -- C_ADMIN_DOMAIN
  gcAdminDomainPurchase      constant char(1) := '1';
  gcAdminDomainSale          constant char(1) := '2';
  gcAdminDomainStock         constant char(1) := '3';
  gcAdminDomainFAL           constant char(1) := '4';
  gcAdminDomainSubContract   constant char(1) := '5';
  gcAdminDomainQuality       constant char(1) := '6';
  gcAdminDomainASA           constant char(1) := '7';
  gcAdminDomainInventory     constant char(1) := '8';
  -- C_MANAGEMENT_MODE
  gcManagementModePRCS       constant char(1) := '1';
  gcManagementModePRC        constant char(1) := '2';
  gcManagementModePRF        constant char(1) := '3';

  /**
  * function IsStockManagement
  * Description
  *    Recherche si un bien est géré en stock
  * @created fp 15.05.2008
  * @lastUpdate
  * @public
  * @param iGoodId : Id du bien à tester
  * @return true si géré en stock
  */
  function IsStockManagement(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return boolean
  is
  begin
    return(getStockManagement(iGoodId) = 1);
  end IsStockManagement;

  function getStockManagement(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    lResult GCO_PRODUCT.PDT_STOCK_MANAGEMENT%type;
  begin
    select PDT_STOCK_MANAGEMENT
      into lResult
      from GCO_PRODUCT
     where GCO_GOOD_Id = iGoodId;

    return lResult;
  exception
    when no_data_found then
      return 0;
  end getStockManagement;

  /**
  * Description
  *   Retourne le status du bien
  */
  function GetGoodStatus(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return GCO_GOOD.C_GOOD_STATUS%type
  is
    lResult GCO_GOOD.C_GOOD_STATUS%type;
  begin
    select C_GOOD_STATUS
      into lResult
      from GCO_GOOD
     where GCO_GOOD_ID = iGoodId;

    return lResult;
  end GetGoodStatus;

  /**
  * Description
  *    Recherche si un bien gère la fabrication (via sa catégorie)
  */
  function IsManufactureManagement(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return boolean
  is
  begin
    return(getManufactureManagement(iGoodId) = 1);
  end IsManufactureManagement;

  function getManufactureManagement(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    lResult GCO_GOOD_CATEGORY.CAT_COMPL_FAB%type;
  begin
    select CAT_COMPL_FAB
      into lResult
      from GCO_GOOD_CATEGORY CAT
         , GCO_GOOD GOO
     where GOO.GCO_GOOD_ID = iGoodId
       and CAT.GCO_GOOD_CATEGORY_ID = GOO.GCO_GOOD_CATEGORY_ID;

    return lResult;
  exception
    when no_data_found then
      return 0;
  end getManufactureManagement;

  /**
  * Description
  *    Recherche si un bien gère la fabrication (via sa catégorie)
  */
  function IsSubContractManagement(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return boolean
  is
  begin
    return(getSubContractManagement(iGoodId) = 1);
  end IsSubContractManagement;

  function getSubContractManagement(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    lResult GCO_GOOD_CATEGORY.CAT_COMPL_STRAIT%type;
  begin
    select CAT_COMPL_STRAIT
      into lResult
      from GCO_GOOD_CATEGORY CAT
         , GCO_GOOD GOO
     where GOO.GCO_GOOD_ID = iGoodId
       and CAT.GCO_GOOD_CATEGORY_ID = GOO.GCO_GOOD_CATEGORY_ID;

    return lResult;
  exception
    when no_data_found then
      return 0;
  end getSubContractManagement;

  /**
  * Description
  *    Recherche si un bien gère les codes EAN en sous-traitance (via sa catégorie)
  */
  function IsSubContractEANUpdatable(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return boolean
  is
  begin
    return(getSubContractEANUpdatable(iGoodId) = 1);
  end IsSubContractEANUpdatable;

  /**
  * Description
  *    Recherche si un bien gère les codes EAN en sous-traitance (via sa catégorie)
  */
  function getSubContractEANUpdatable(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    lResult GCO_GOOD_CATEGORY.CAT_EAN_SUB_UPDATABLE%type;
  begin
    select CAT_EAN_SUB_UPDATABLE
      into lResult
      from GCO_GOOD_CATEGORY CAT
         , GCO_GOOD GOO
     where GOO.GCO_GOOD_ID = iGoodId
       and CAT.GCO_GOOD_CATEGORY_ID = GOO.GCO_GOOD_CATEGORY_ID;

    return lResult;
  exception
    when no_data_found then
      return 0;
  end getSubContractEANUpdatable;

  /**
  * Description
  *    return supply mode of a good
  */
  function GetSupplyMode(iGoodId in GCO_PRODUCT.GCO_GOOD_ID%type)
    return GCO_PRODUCT.C_SUPPLY_MODE%type
  is
    lResult GCO_PRODUCT.C_SUPPLY_MODE%type;
  begin
    select C_SUPPLY_MODE
      into lResult
      from GCO_PRODUCT
     where GCO_GOOD_ID = iGoodId;

    return lResult;
  exception
    when no_data_found then
      return null;
  end GetSupplyMode;

  /**
  * Description
  *    Return major reference from good ID
  */
  function getMajorReference(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return GCO_GOOD.GOO_MAJOR_REFERENCE%type
  is
    lResult GCO_GOOD.GOO_MAJOR_REFERENCE%type;
  begin
    select GOO_MAJOR_REFERENCE
      into lResult
      from GCO_GOOD
     where GCO_GOOD_ID = iGoodId;

    return lResult;
  exception
    when no_data_found then
      return null;
  end;

  /**
  * Description
  *    Return secondary reference from good ID
  */
  function getSecondaryReference(inGcoGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return GCO_GOOD.GOO_SECONDARY_REFERENCE%type
  is
    lvGooSecondaryReference GCO_GOOD.GOO_SECONDARY_REFERENCE%type;
  begin
    select GOO_SECONDARY_REFERENCE
      into lvGooSecondaryReference
      from GCO_GOOD
     where GCO_GOOD_ID = inGcoGoodID;

    return lvGooSecondaryReference;
  exception
    when no_data_found then
      return null;
  end getSecondaryReference;

  /**
  * Description
  *    look for good management mode
  */
  function getManagementMode(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return GCO_GOOD.C_MANAGEMENT_MODE%type
  is
    lResult GCO_GOOD.C_MANAGEMENT_MODE%type;
  begin
    select max(C_MANAGEMENT_MODE)
      into lResult
      from GCO_GOOD
     where GCO_GOOD_ID = iGoodId;

    return lResult;
  end getManagementMode;

  /**
  * function GetNumberOfDecimal
  * Description
  *       Recherche du nombre de décimales
  * @created fp 13.11.2003
  * @public
  * @param iGoodId           : id du bien
  * @return : nombre de décimal
  */
  function GetNumberOfDecimal(iGoodId in number)
    return number
  is
    lResult GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
  begin
    select GOO_NUMBER_OF_DECIMAL
      into lResult
      from GCO_GOOD
     where GCO_GOOD_ID = iGoodId;

    return lResult;
  exception
    when no_data_found then
      return 0;
  end GetNumberOfDecimal;

  /**
  * Description
  *    Renvoie la plus petite qté d'un bien en fonction du nombre de décimales
  */
  function GetMinimumQuantity(iGoodId in number)
    return number
  is
  begin
    return power(10, -GetNumberOfDecimal(iGoodId) );
  end GetMinimumQuantity;

  --Renvoie la description du bien en fonction de la langue passée en param
  function GetDescription(iGoodId in GCO_GOOD.GCO_GOOD_ID%type, iLang in varchar2, iTypofDescrp in number, iDescriptionType in varchar2)
    return varchar2
  is
    cursor lcurDescr(iGoodId in number, iLang in varchar2, iTypofDescrp in number, iDescriptionType in varchar2)
    is
      select   DES_SHORT_DESCRIPTION
             , DES_LONG_DESCRIPTION
             , DES_FREE_DESCRIPTION
          from GCO_DESCRIPTION
             , PCS.PC_LANG
         where PCS.PC_LANG.PC_LANG_ID = GCO_DESCRIPTION.pc_lang_id
           and GCO_GOOD_ID = iGoodId
           and PCS.PC_LANG.LANID = upper(iLang)
           and (   C_DESCRIPTION_TYPE = iDescriptionType
                or C_DESCRIPTION_TYPE = '01')
      order by C_DESCRIPTION_TYPE desc;

    ltplDescr lcurDescr%rowtype;
  begin
    open lcurDescr(iGoodId, iLang, iTypofDescrp, iDescriptionType);

    fetch lcurDescr
     into ltplDescr;

    if iTypofDescrp = 1 then
      return ltplDescr.DES_SHORT_DESCRIPTION;
    else
      if iTypofDescrp = 2 then
        return ltplDescr.DES_LONG_DESCRIPTION;
      else
        return ltplDescr.DES_FREE_DESCRIPTION;
      end if;
    end if;

    close lcurDescr;
  end GetDescription;

--Renvoie la description du bien en fonction de la langue passée en param
  function GetDescription2(iGoodId in GCO_GOOD.GCO_GOOD_ID%type, iLang in number, iTypofDescrp in number, iDescriptionType in varchar2)
    return varchar2
  is
    cursor lcurDescr(iGoodId in number, iLang in number, iTypofDescrp in number, iDescriptionType in varchar2)
    is
      select   DES_SHORT_DESCRIPTION
             , DES_LONG_DESCRIPTION
             , DES_FREE_DESCRIPTION
          from gco_description
             , pcs.pc_lang
         where pcs.pc_lang.PC_LANG_ID = gco_description.pc_lang_id
           and GCO_GOOD_ID = iGoodId
           and pcs.pc_lang.PC_LANG_ID = iLang
           and (   c_description_type = iDescriptionType
                or c_description_type = '01')
      order by c_description_type desc;

    ltplDescr lcurDescr%rowtype;
  begin
    open lcurDescr(iGoodId, iLang, iTypofDescrp, iDescriptionType);

    fetch lcurDescr
     into ltplDescr;

    if iTypofDescrp = 1 then
      return ltplDescr.DES_SHORT_DESCRIPTION;
    else
      if iTypofDescrp = 2 then
        return ltplDescr.DES_LONG_DESCRIPTION;
      else
        return ltplDescr.DES_FREE_DESCRIPTION;
      end if;
    end if;

    close lcurDescr;
  end GetDescription2;

  /**
  * Description
  *      Recherche dus stock et emplacement du bien passé en paramètre
  */
  procedure GetGoodStockLocation(
    iGoodId            GCO_GOOD.GCO_GOOD_ID%type
  , oStockId    out    STM_STOCK.STM_STOCK_ID%type
  , oLocationId out    STM_LOCATION.STM_LOCATION_ID%type
  , iVersion    in     varchar2 default null
  )
  is
    cursor lcurGetStkLoc(iGoodId GCO_GOOD.GCO_GOOD_ID%type)
    is
      select   1 ORDER_FIELD
             , PDT.STM_STOCK_ID
             , nvl(PDT.STM_LOCATION_ID, LOC.STM_LOCATION_ID) STM_LOCATION_ID
             , LOC.LOC_CLASSIFICATION
          from GCO_PRODUCT as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion) PDT
             , STM_STOCK as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion) STO
             , STM_LOCATION as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion) LOC
         where PDT.GCO_GOOD_ID = iGoodId
           and STO.STM_STOCK_ID = PDT.STM_STOCK_ID
           and STO.C_ACCESS_METHOD = 'PUBLIC'
           and LOC.STM_STOCK_ID = STO.STM_STOCK_ID
      union all
      select   2
             , STO.STM_STOCK_ID
             , LOC.STM_LOCATION_ID
             , LOC.LOC_CLASSIFICATION
          from STM_STOCK as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion) STO
             , STM_LOCATION as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion) LOC
         where STO.STO_DESCRIPTION = PCS.PC_CONFIG.GETCONFIG('GCO_DefltSTOCK')
           and STO.C_ACCESS_METHOD = 'PUBLIC'
           and LOC.STM_STOCK_ID = STO.STM_STOCK_ID
      order by ORDER_FIELD
             , LOC_CLASSIFICATION;

    ltplGetStkLoc lcurGetStkLoc%rowtype;
  begin
    oStockId     := 0;
    oLocationId  := 0;

    open lcurGetStkLoc(iGoodId);

    fetch lcurGetStkLoc
     into ltplGetStkLoc;

    if lcurGetStkLoc%found then
      oStockId     := ltplGetStkLoc.STM_STOCK_ID;
      oLocationId  := ltplGetStkLoc.STM_LOCATION_ID;
    end if;

    close lcurGetStkLoc;
  end GetGoodStockLocation;

  /**
  * Description
  *      Recherche de l'unité de mesure du bien en fonction de la langue passé en paramètre
  */
  function GetDicUnitOfMeasure(iGoodId GCO_GOOD.GCO_GOOD_ID%type, iLang in varchar2)
    return dico_Description.dit_descr%type
  is
    lvDicoDescr dico_Description.dit_descr%type;
  begin
    select COM_DIC_FUNCTIONS.getDicoDescr('DIC_UNIT_OF_MEASURE', GOO.DIC_UNIT_OF_MEASURE_ID, iLang)
      into lvDicoDescr
      from GCO_GOOD GOO
     where GOO.GCO_GOOD_ID = iGoodId;

    return lvDicoDescr;
  end GetDicUnitOfMeasure;

  /**
  * Description
  *      Recherche de l'emplacement du bien passé en paramètre
  */
  function GetGoodLocation(iGoodId GCO_GOOD.GCO_GOOD_ID%type)
    return STM_LOCATION.STM_LOCATION_ID%type
  is
    lStockID    STM_STOCK.STM_STOCK_ID%type;
    lLocationID STM_LOCATION.STM_LOCATION_ID%type;
  begin
    GetGoodStockLocation(iGoodID => iGoodID, oStockId => lStockID, oLocationId => lLocationID);
    return lLocationID;
  end GetGoodLocation;

  /**
  * Description
  *      Recherche des qtés alternatives du bien passé en paramètre
  */
  procedure GetGoodAltQty(
    iGoodId       GCO_GOOD.GCO_GOOD_ID%type
  , oAltQty1  out GCO_PRODUCT.PDT_ALTERNATIVE_QUANTITY_1%type
  , oAltQty2  out GCO_PRODUCT.PDT_ALTERNATIVE_QUANTITY_2%type
  , oAltQty3  out GCO_PRODUCT.PDT_ALTERNATIVE_QUANTITY_3%type
  , oAltFac1  out GCO_PRODUCT.PDT_CONVERSION_FACTOR_1%type
  , oAltFac2  out GCO_PRODUCT.PDT_CONVERSION_FACTOR_2%type
  , oAltFac3  out GCO_PRODUCT.PDT_CONVERSION_FACTOR_3%type
  , oAltDesc1 out DIC_UNIT_OF_MEASURE.DIC_UNIT_OF_MEASURE_WORDING%type
  , oAltDesc2 out DIC_UNIT_OF_MEASURE.DIC_UNIT_OF_MEASURE_WORDING%type
  , oAltDesc3 out DIC_UNIT_OF_MEASURE.DIC_UNIT_OF_MEASURE_WORDING%type
  )
  is
    cursor lcurGetAlternativ(iGoodId GCO_GOOD.GCO_GOOD_ID%type)
    is
      select PDT.PDT_ALTERNATIVE_QUANTITY_1
           , PDT.PDT_ALTERNATIVE_QUANTITY_2
           , PDT.PDT_ALTERNATIVE_QUANTITY_3
           , PDT.PDT_CONVERSION_FACTOR_1
           , PDT.PDT_CONVERSION_FACTOR_2
           , PDT.PDT_CONVERSION_FACTOR_3
           , DIC1.DIC_UNIT_OF_MEASURE_WORDING DIC_UNIT_OF_MEASURE_WORDING1
           , DIC2.DIC_UNIT_OF_MEASURE_WORDING DIC_UNIT_OF_MEASURE_WORDING2
           , DIC3.DIC_UNIT_OF_MEASURE_WORDING DIC_UNIT_OF_MEASURE_WORDING3
        from GCO_PRODUCT PDT
           , DIC_UNIT_OF_MEASURE DIC1
           , DIC_UNIT_OF_MEASURE DIC2
           , DIC_UNIT_OF_MEASURE DIC3
       where PDT.GCO_GOOD_ID = iGoodId
         and DIC1.DIC_UNIT_OF_MEASURE_ID(+) = PDT.DIC_UNIT_OF_MEASURE_ID
         and DIC2.DIC_UNIT_OF_MEASURE_ID(+) = PDT.DIC_UNIT_OF_MEASURE1_ID
         and DIC3.DIC_UNIT_OF_MEASURE_ID(+) = PDT.DIC_UNIT_OF_MEASURE2_ID;

    ltplGetAlternativ lcurGetAlternativ%rowtype;
  begin
    open lcurGetAlternativ(iGoodId);

    fetch lcurGetAlternativ
     into ltplGetAlternativ;

    if lcurGetAlternativ%found then
      oAltQty1   := ltplGetAlternativ.PDT_ALTERNATIVE_QUANTITY_1;
      oAltQty2   := ltplGetAlternativ.PDT_ALTERNATIVE_QUANTITY_2;
      oAltQty3   := ltplGetAlternativ.PDT_ALTERNATIVE_QUANTITY_3;
      oAltFac1   := ltplGetAlternativ.PDT_CONVERSION_FACTOR_1;
      oAltFac2   := ltplGetAlternativ.PDT_CONVERSION_FACTOR_2;
      oAltFac3   := ltplGetAlternativ.PDT_CONVERSION_FACTOR_3;
      oAltDesc1  := ltplGetAlternativ.DIC_UNIT_OF_MEASURE_WORDING1;
      oAltDesc2  := ltplGetAlternativ.DIC_UNIT_OF_MEASURE_WORDING2;
      oAltDesc3  := ltplGetAlternativ.DIC_UNIT_OF_MEASURE_WORDING3;
    end if;

    close lcurGetAlternativ;
  end GetGoodAltQty;

  /**
  * Description
  *   retourne la quantité passée en paramètre formatée
  *   selon le nombre de décimales du bien
  *   Prévu pour un formattage number(15,4)
  */
  function GetGoodQuantityWithDecimals(iGoodId in number, iQuantity in number)
    return varchar2
  is
    lResult varchar2(15);
  begin
    select to_char(iQuantity, rtrim(lpad(' ', 10, '9') ) || decode(goo_number_of_decimal, 0, null, 'D' || rtrim(lpad(' ', goo_number_of_decimal + 1, '0') ) ) )
      into lResult
      from GCO_GOOD
     where GCO_GOOD_ID = iGoodId;

    return lResult;
  exception
    when no_data_found then
      return null;
    when others then
      return 'problème';
  end GetGoodQuantityWithDecimals;

  function GetEquivalentPropComponent(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return GCO_GOOD.GCO_GOOD_ID%type
  is
    cursor lcurStockPosition
    is
      select   SPO.GCO_GOOD_ID
          from STM_STOCK_POSITION SPO
             , GCO_EQUIVALENCE_GOOD EQUI
         where EQUI.GCO_GOOD_ID = iGoodId
           and EQUI.GCO_GCO_GOOD_ID = SPO.GCO_GOOD_ID
      order by SPO.SPO_CHRONOLOGICAL asc;

    ltplStockPosition lcurStockPosition%rowtype;
    lReplaceGoodId    GCO_GOOD.GCO_GOOD_ID%type;   -- Produit equivalent
  begin
    open lcurStockPosition;

    fetch lcurStockPosition
     into ltplStockPosition;

    if lcurStockPosition%notfound then
      begin
        select PUR.GCO_GCO_GOOD_ID
          into lReplaceGoodId
          from GCO_COMPL_DATA_PURCHASE PUR
         where PUR.GCO_GOOD_ID = iGoodId
           and PUR.CPU_DEFAULT_SUPPLIER = 1;
      exception
        when others then
          lReplaceGoodId  := 0;
      end;
    else
      lReplaceGoodId  := ltplStockPosition.GCO_GOOD_ID;
    end if;

    close lcurStockPosition;

    return lReplaceGoodId;
  exception
    when others then
      return 0;
  end GetEquivalentPropComponent;

  /**
  * Description
  *   Recherche le cours matière précieuse unitaire d'un produit lié à un alliage. Si l'alliage associé contient 100%
  *   d'une matière de base, on considère que c'est une matière de base, par contre, si l'alliage associé contient
  *   plusieurs matières de base, on considère que c'est un alliage.
  */
  function GetGoodMetalRate(
    iGoodID      in GCO_GOOD.GCO_GOOD_ID%type default null
  , iThirdID     in PAC_THIRD.PAC_THIRD_ID%type default null
  , iDate        in date default null
  , iAdminDomain in DOC_GAUGE.C_ADMIN_DOMAIN%type default '3'
  )
    return number
  is
    lDicTypeRateID          GCO_PRECIOUS_RATE.DIC_TYPE_RATE_ID%type;
    lbStop                  boolean;
    lbFounded               boolean;
    lbFoundRate             number;
    lAlloyID                GCO_ALLOY.GCO_ALLOY_ID%type;
    lDicBasisMaterialID     DIC_BASIS_MATERIAL.DIC_BASIS_MATERIAL_ID%type;
    lDicFreeCode1ID         DIC_FREE_CODE1.DIC_FREE_CODE1_ID%type;
    lDicComplementaryDataID DIC_COMPLEMENTARY_DATA.DIC_COMPLEMENTARY_DATA_ID%type;
  begin
    lbStop       := false;
    lbFoundRate  := 0;

    begin
      select decode(GAC.GAC_RATE, 100, null, GAL.GCO_ALLOY_ID) GCO_ALLOY_ID
           , decode(GAC.GAC_RATE, 100, GAC.DIC_BASIS_MATERIAL_ID, null) DIC_BASIS_MATERIAL_ID
        into lAlloyID
           , lDicBasisMaterialID
        from GCO_ALLOY GAL
           , GCO_ALLOY_COMPONENT GAC
       where GAL.GCO_GOOD_ID = iGoodID
         and GAC.GCO_ALLOY_ID(+) = GAL.GCO_ALLOY_ID
         and GAC.GAC_RATE(+) = 100;
    exception
      when no_data_found then
        lbStop  := true;
    end;

    if not lbStop then
      if iThirdID is not null then
        begin
          select PER.DIC_FREE_CODE1_ID
               , decode(iAdminDomain
                      , gcAdminDomainPurchase, SUP.DIC_COMPLEMENTARY_DATA_ID
                      , gcAdminDomainSale, CUS.DIC_COMPLEMENTARY_DATA_ID
                      , gcAdminDomainSubContract, SUP.DIC_COMPLEMENTARY_DATA_ID
                      , nvl(CUS.DIC_COMPLEMENTARY_DATA_ID, SUP.DIC_COMPLEMENTARY_DATA_ID)
                       ) DIC_COMPLEMENTARY_DATA_ID
            into lDicFreeCode1ID
               , lDicComplementaryDataID
            from PAC_CUSTOM_PARTNER CUS
               , PAC_SUPPLIER_PARTNER SUP
               , PAC_PERSON PER
           where PER.PAC_PERSON_ID = iThirdID
             and CUS.PAC_CUSTOM_PARTNER_ID(+) = PER.PAC_PERSON_ID
             and SUP.PAC_SUPPLIER_PARTNER_ID(+) = PER.PAC_PERSON_ID;
        exception
          when no_data_found then
            lbStop  := true;
        end;
      else
        lDicFreeCode1ID          := null;
        lDicComplementaryDataID  := null;
      end if;

      if not lbStop then
        if (iAdminDomain = gcAdminDomainPurchase) then
          lDicTypeRateID  := PCS.PC_CONFIG.GetConfig('DOC_MAT_TYPE_RATE_PURCHASE');
        elsif(iAdminDomain = gcAdminDomainInventory) then
          lDicTypeRateID  := PCS.PC_CONFIG.GetConfig('DOC_MAT_TYPE_RATE_INVENTORY');
        elsif(iAdminDomain = gcAdminDomainStock) then
          lDicTypeRateID  := PCS.PC_CONFIG.GetConfig('DOC_MAT_TYPE_RATE_STOCK');
        else   -- Vente par défaut
          lDicTypeRateID  := PCS.PC_CONFIG.GetConfig('DOC_MAT_TYPE_RATE_SALE');
        end if;

        -- Renvoie le cours d'une matière de base ou d'un alliage pour une unité
        lbFoundRate  :=
                     FAL_PRECALC_TOOLS.GetQuotedPrice(lAlloyID, lDicBasisMaterialID, iDate, lDicTypeRateID, lbFounded, lDicFreeCode1ID, lDicComplementaryDataID);
      end if;
    end if;

    return lbFoundRate;
  end GetGoodMetalRate;

  /**
   * Function IsProductInUse
   * Description
   *        Recherche si le produit est utilisé dans les domaines spécifiés.
   */
  function IsProductInUse(
    iGoodId                  in GCO_GOOD.GCO_GOOD_ID%type
  , iSearchInStocks          in integer default 1
  , iSearchInDocuments       in integer default 1
  , iSearchInBatches         in integer default 1
  , iSearchInBatchComponents in integer default 1
  , iSearchInBillOfMaterials in integer default 0
  , iSearchInStockMovements  in integer default 0
  , iSearchInDocPosition     in integer default 0
  , iSearchInWorshopInput    in integer default 0
  , iSearchInNeed            in integer default 0
  , iSearchInSupply          in integer default 0
  , iSearchInBatchProp       in integer default 0
  , iSearchInDocProp         in integer default 0
  , iSearchInBatchDetail     in integer default 0
  , iSearchInSubstitute      in integer default 0
  )
    return integer
  is
    lResult integer := 0;
  begin
    -- Recherche dans les stocks
    if iSearchInStocks = 1 then
      select case count(SPO.STM_STOCK_POSITION_ID)
               when 0 then 0
               else 1
             end
        into lResult
        from STM_STOCK_POSITION SPO
       where SPO.GCO_GOOD_ID = iGoodId;
    end if;

    -- Recherche dans les documents
    if     (lResult = 0)
       and (iSearchInDocuments = 1) then
      select case count(POS.DOC_POSITION_ID)
               when 0 then 0
               else 1
             end
        into lResult
        from DOC_POSITION POS
       where POS.GCO_GOOD_ID = iGoodId
         and POS.C_DOC_POS_STATUS not in('04', '05');
    end if;

    -- Recherche dans les OFs
    if     (lResult = 0)
       and (iSearchInBatches = 1) then
      select case count(LOT.FAL_LOT_ID)
               when 0 then 0
               else 1
             end
        into lResult
        from FAL_LOT LOT
       where LOT.GCO_GOOD_ID = iGoodId
         and LOT.C_LOT_STATUS in('1', '2', '4');
    end if;

    -- Recherche dans les composants d'OFs
    if     (lResult = 0)
       and (iSearchInBatchComponents = 1) then
      select case count(LOM.FAL_LOT_MATERIAL_LINK_ID)
               when 0 then 0
               else 1
             end
        into lResult
        from FAL_LOT_MATERIAL_LINK LOM
           , FAL_LOT LOT
       where LOM.GCO_GOOD_ID = iGoodId
         and LOT.FAL_LOT_ID = LOM.FAL_LOT_ID
         and LOT.C_LOT_STATUS in('1', '2', '4');
    end if;

    -- Recherche dans les nomenclatures
    if     (lResult = 0)
       and (iSearchInBillOfMaterials = 1) then
      select case count(NOM.PPS_NOMENCLATURE_ID)
               when 0 then 0
               else 1
             end
        into lResult
        from PPS_NOMENCLATURE NOM
       where NOM.GCO_GOOD_ID = iGoodId;
    end if;

    if     (lResult = 0)
       and (iSearchInBillOfMaterials = 1) then
      select case count(NBO.PPS_NOM_BOND_ID)
               when 0 then 0
               else 1
             end
        into lResult
        from PPS_NOM_BOND NBO
       where NBO.GCO_GOOD_ID = iGoodId;
    end if;

    -- Recherche dans les mouvements de stocks
    if     (lResult = 0)
       and (iSearchInStockMovements = 1) then
      select sign(count(GCO_GOOD_ID) )
        into lResult
        from STM_STOCK_MOVEMENT
       where GCO_GOOD_ID = iGoodId;
    end if;

    -- Recherche dans toutes les positions de document
    if     (lResult = 0)
       and (iSearchInDocPosition = 1) then
      select sign(count(GCO_GOOD_ID) )
        into lResult
        from DOC_POSITION
       where GCO_GOOD_ID = iGoodId;
    end if;

    -- Recherche dans les entrées atelier
    if     (lResult = 0)
       and (iSearchInWorshopInput = 1) then
      select sign(count(GCO_GOOD_ID) )
        into lResult
        from FAL_FACTORY_IN
       where GCO_GOOD_ID = iGoodId;
    end if;

    -- Recherche dans les besoins
    if     (lResult = 0)
       and (iSearchInNeed = 1) then
      select sign(count(GCO_GOOD_ID) )
        into lResult
        from FAL_NETWORK_NEED
       where GCO_GOOD_ID = iGoodId;
    end if;

    -- Recherche dans les approvisionnements
    if     (lResult = 0)
       and (iSearchInSupply = 1) then
      select sign(count(GCO_GOOD_ID) )
        into lResult
        from FAL_NETWORK_SUPPLY
       where GCO_GOOD_ID = iGoodId;
    end if;

    -- Recherche dans les propositions de lot de fabrication
    if     (lResult = 0)
       and (iSearchInBatchProp = 1) then
      select sign(count(GCO_GOOD_ID) )
        into lResult
        from FAL_LOT_PROP
       where GCO_GOOD_ID = iGoodId;
    end if;

    -- Recherche dans les propositions de documents
    if     (lResult = 0)
       and (iSearchInDocProp = 1) then
      select sign(count(GCO_GOOD_ID) )
        into lResult
        from FAL_DOC_PROP
       where GCO_GOOD_ID = iGoodId;
    end if;

    -- Recherche dans les détails de lot de fabrication
    if     (lResult = 0)
       and (iSearchInBatchDetail = 1) then
      select sign(count(GCO_GOOD_ID) )
        into lResult
        from FAL_LOT_DETAIL
       where GCO_GOOD_ID = iGoodId;
    end if;

    -- Recherche dans les substituts
    if     (lResult = 0)
       and (iSearchInSubstitute = 1) then
      select sign(count(GCO_GOOD_ID) )
        into lResult
        from GCO_SUBSTITUTE
       where GCO_GOOD_ID = iGoodId;
    end if;

    return lResult;
  end IsProductInUse;

  /**
  * function IsGoodInInventory
  * Description
  *   Indique si le bien est en cours d'inventaire
  * @created fp 03.02.2014
  * @updated
  * @public
  * @param iGoodId : bien à contrôler
  */
  function IsGoodInInventory(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return GCO_GOOD_CALC_DATA.GOO_IN_INVENTORY%type
  is
    lResult GCO_GOOD_CALC_DATA.GOO_IN_INVENTORY%type;
  begin
    select GOO_IN_INVENTORY
      into lResult
      from GCO_GOOD_CALC_DATA
     where GCO_GOOD_ID = iGoodId;

    return lResult;
  end IsGoodInInventory;

  /**
  * Function CanDeleteGood
  * Description
  *   Contrôle si un produit peut être effacé
  */
  function CanDeleteGood(iGoodID in GCO_GOOD.GCO_GOOD_ID%type, oMessage out varchar2)
    return integer
  is
    ln_UsedGood integer;
  begin
    -- Outil utilié dans des opérations
    select sign(max(SUB.GCO_GOOD_ID) )
      into ln_UsedGood
      from (select GCO_GOOD_ID
              from PPS_ALT_EXE_S_TOOLS
             where GCO_GOOD_ID = iGoodID
            union
            select GCO_GOOD_ID
              from PPS_SPECIAL_TOOLS
             where GCO_GOOD_ID = iGoodID
               and SPT_USE <> 0) SUB;

    if ln_UsedGood = 1 then
      oMessage  := PCS.PC_FUNCTIONS.TranslateWord('L''outil est utilisé par des opérations.');
      return 0;
    end if;

    -- Outil utilié dans des nomenclatures
    select sign(max(SUB.GCO_GOOD_ID) )
      into ln_UsedGood
      from (select GCO_GOOD_ID
              from PPS_NOMENCLATURE
             where GCO_GOOD_ID = iGoodID) SUB;

    if ln_UsedGood = 1 then
      oMessage  := PCS.PC_FUNCTIONS.TranslateWord('Le bien est utilisé dans au moins une nomenclature (PPS_NOMENCLATURE).');
      return 0;
    end if;

    select sign(max(SUB.GCO_GOOD_ID) )
      into ln_UsedGood
      from (select GCO_GOOD_ID
              from PPS_NOM_BOND
             where GCO_GOOD_ID = iGoodID) SUB;

    if ln_UsedGood = 1 then
      oMessage  := PCS.PC_FUNCTIONS.TranslateWord('Le bien est utilisé dans au moins une nomenclature (PPS_NOM_BOND).');
      return 0;
    end if;

    -- Outil utilié dans des dossiers SAV
    select sign(max(SUB.GCO_GOOD_ID) )
      into ln_UsedGood
      from (select GCO_NEW_GOOD_ID GCO_GOOD_ID
              from ASA_RECORD
             where GCO_NEW_GOOD_ID = iGoodID) SUB;

    if ln_UsedGood = 1 then
      oMessage  := PCS.PC_FUNCTIONS.TranslateWord('Le bien est utilisé dans au moins un dossier SAV (ASA_RECORD.GCO_NEW_GOOD_ID).');
      return 0;
    end if;

    -- Outil utilié dans des dossiers SAV
    select sign(max(SUB.GCO_GOOD_ID) )
      into ln_UsedGood
      from (select GCO_SUPPLIER_GOOD_ID GCO_GOOD_ID
              from ASA_RECORD
             where GCO_SUPPLIER_GOOD_ID = iGoodID) SUB;

    if ln_UsedGood = 1 then
      oMessage  := PCS.PC_FUNCTIONS.TranslateWord('Le bien est utilisé dans au moins un dossier SAV (ASA_RECORD.GCO_SUPPLIER_GOOD_ID).');
      return 0;
    end if;

    -- Bien utilié dans des dossiers SAV
    select sign(max(SUB.GCO_GOOD_ID) )
      into ln_UsedGood
      from (select GCO_BILL_GOOD_ID GCO_GOOD_ID
              from ASA_RECORD
             where GCO_BILL_GOOD_ID = iGoodID) SUB;

    if ln_UsedGood = 1 then
      oMessage  := PCS.PC_FUNCTIONS.TranslateWord('Le bien est utilisé dans au moins un dossier SAV (ASA_RECORD.GCO_BILL_GOOD_ID).');
      return 0;
    end if;

    -- Outil utilié dans des dossiers SAV
    select sign(max(SUB.GCO_GOOD_ID) )
      into ln_UsedGood
      from (select GCO_DEVIS_BILL_GOOD_ID GCO_GOOD_ID
              from ASA_RECORD
             where GCO_DEVIS_BILL_GOOD_ID = iGoodID) SUB;

    if ln_UsedGood = 1 then
      oMessage  := PCS.PC_FUNCTIONS.TranslateWord('Le bien est utilisé dans au moins un dossier SAV (ASA_RECORD.GCO_DEVIS_BILL_GOOD_ID).');
      return 0;
    end if;

    -- Outil utilié comme composant SAV
    select sign(max(SUB.GCO_GOOD_ID) )
      into ln_UsedGood
      from (select GCO_COMPONENT_ID GCO_GOOD_ID
              from ASA_RECORD_COMP
             where GCO_COMPONENT_ID = iGoodID) SUB;

    if ln_UsedGood = 1 then
      oMessage  := PCS.PC_FUNCTIONS.TranslateWord('Le bien est utilisé comme composant SAV (ASA_RECORD_COMP.GCO_COMPONENT_ID).');
      return 0;
    end if;

    -- Bien utilisé dans le calcul des besoins
    select sign(max(SUB.GCO_GOOD_ID) )
      into ln_UsedGood
      from (select GCO_GOOD_ID
              from FAL_CB_PARAMETERS
             where GCO_GOOD_ID = iGoodID) SUB;

    if ln_UsedGood = 1 then
      oMessage  := PCS.PC_FUNCTIONS.TranslateWord('Le bien est utilisé comme paramètre d''au moins un calcul des besoins (FAL_CB_PARAMETERS).');
      return 0;
    end if;

    -- controle si le bien est utilisé dans DOC_COMMISSION
    select sign(max(GCO_BONUS_GOOD_ID) )
      into ln_UsedGood
      from DOC_COMMISSION
     where GCO_BONUS_GOOD_ID = iGoodID;

    if ln_UsedGood = 1 then
      oMessage  := PCS.PC_FUNCTIONS.TranslateWord('Ce bien est utilisé comme "Pseudo bien bonus fin d''année" dans le commissionnement (DOC_COMMISSION).');
      return 0;
    end if;

    -- controle si le bien est utilisé dans DOC_COMMISSION
    select sign(max(GCO_GOOD_ID) )
      into ln_UsedGood
      from DOC_COMMISSION
     where GCO_GOOD_ID = iGoodID;

    if ln_UsedGood = 1 then
      oMessage  := PCS.PC_FUNCTIONS.TranslateWord('Ce bien est utilisé dans le commissionnement (DOC_COMMISSION).');
      return 0;
    end if;

    -- controle si le bien est utilisé dans DOC_GAUGE_FLOW
    select sign(max(GCO_GOOD_ID) )
      into ln_UsedGood
      from DOC_GAUGE_FLOW
     where GCO_GOOD_ID = iGoodID;

    if ln_UsedGood = 1 then
      oMessage  := PCS.PC_FUNCTIONS.TranslateWord('Ce bien est utilisé dans le flux de documents (DOC_GAUGE_FLOW).');
      return 0;
    end if;

    -- controle si le bien est utilisé dans DOC_GAUGE_POSITION
    select sign(max(GCO_GOOD_ID) )
      into ln_UsedGood
      from DOC_GAUGE_POSITION
     where GCO_GOOD_ID = iGoodID;

    if ln_UsedGood = 1 then
      oMessage  := PCS.PC_FUNCTIONS.TranslateWord('Ce bien est utilisé dans un gabarit position (DOC_GAUGE_POSITION).');
      return 0;
    end if;

    -- controle si le bien est utilisé dans DOC_POSITION
    select sign(max(GCO_GOOD_ID) )
      into ln_UsedGood
      from DOC_POSITION
     where GCO_GOOD_ID = iGoodID;

    if ln_UsedGood = 1 then
      oMessage  := PCS.PC_FUNCTIONS.TranslateWord('Ce bien est utilisé dans une position de document (DOC_POSITION).');
      return 0;
    end if;

    -- controle si le bien est utilisé dans DOC_POSITION
    select sign(max(GCO_MANUFACTURED_GOOD_ID) )
      into ln_UsedGood
      from DOC_POSITION
     where GCO_MANUFACTURED_GOOD_ID = iGoodID;

    if ln_UsedGood = 1 then
      oMessage  := PCS.PC_FUNCTIONS.TranslateWord('Ce bien est utilisé comme "Produit fabriqué" dans une position de document (DOC_POSITION).');
      return 0;
    end if;

    -- controle si le bien est utilisé dans FAL_DELAY
    select sign(max(GCO_GOOD_ID) )
      into ln_UsedGood
      from FAL_DELAY
     where GCO_GOOD_ID = iGoodID;

    if ln_UsedGood = 1 then
      oMessage  := PCS.PC_FUNCTIONS.TranslateWord('Ce bien est utilisé dans les retards (FAL_DELAY).');
      return 0;
    end if;

    -- controle si le bien est utilisé dans GCO_SUBSTITUTE
    select sign(max(GCO_GOOD_ID) )
      into ln_UsedGood
      from GCO_SUBSTITUTE
     where GCO_GOOD_ID = iGoodID;

    if ln_UsedGood = 1 then
      oMessage  := PCS.PC_FUNCTIONS.TranslateWord('Ce bien est utilisé dans les substituts (GCO_SUBSTITUTE).');
      return 0;
    end if;

    -- controle si le bien est utilisé dans STM_STOCK_POSITION
    select sign(max(GCO_GOOD_ID) )
      into ln_UsedGood
      from STM_STOCK_POSITION
     where GCO_GOOD_ID = iGoodID;

    if ln_UsedGood = 1 then
      oMessage  := PCS.PC_FUNCTIONS.TranslateWord('Ce bien est utilisé dans les positions de stock (STM_STOCK_POSITION).');
      return 0;
    end if;

    -- controle si le bien est utilisé dans PAC_REP_STRUCTURE
    select sign(max(GCO_BONUS_GOOD_ID) )
      into ln_UsedGood
      from PAC_REP_STRUCTURE
     where GCO_BONUS_GOOD_ID = iGoodID;

    if ln_UsedGood = 1 then
      oMessage  := PCS.PC_FUNCTIONS.TranslateWord('Ce bien est utilisé dans les structures des représentants (PAC_REP_STRUCTURE).');
      return 0;
    end if;

    -- controle si le bien est utilisé dans GCO_SUBSTITUTION_LIST
    -- effacement dans l'interface
    select sign(max(GCO_GOOD_ID) )
      into ln_UsedGood
      from GCO_SUBSTITUTION_LIST
     where GCO_GOOD_ID = iGoodID;

    if ln_UsedGood = 1 then
      oMessage  := PCS.PC_FUNCTIONS.TranslateWord('Ce bien est utilisé dans les liste de substitution (GCO_SUBSTITUTION_LIST).');
      return 0;
    end if;

    -- controle si le bien est utilisé dans STM_INVENTORY_LIST_POS
    -- effacement dans l'interface
    select sign(max(GCO_GOOD_ID) )
      into ln_UsedGood
      from STM_INVENTORY_LIST_POS
     where GCO_GOOD_ID = iGoodID;

    if ln_UsedGood = 1 then
      oMessage  := PCS.PC_FUNCTIONS.TranslateWord('Ce bien est utilisé dans les positions de l''inventaire (STM_INVENTORY_LIST_POS).');
      return 0;
    end if;

    -- controle si le bien est utilisé dans STM_EXERCISE_EVOLUTION
    select sign(max(GCO_GOOD_ID) )
      into ln_UsedGood
      from STM_EXERCISE_EVOLUTION
     where GCO_GOOD_ID = iGoodID;

    if ln_UsedGood = 1 then
      oMessage  := PCS.PC_FUNCTIONS.TranslateWord('Ce bien est utilisé dans les évolutions des exercices de stock (STM_EXERCISE_EVOLUTION).');
      return 0;
    end if;

    return 1;
  end CanDeleteGood;

  /**
  * procedure CanDeleteGood
  * Description
  *   Contrôle si un produit peut être effacé
  *     - Pour l'appel depuis Delphi de la fonction CanDeleteGood
  */
  procedure CanDeleteGood(iGoodID in GCO_GOOD.GCO_GOOD_ID%type, oResult out integer, oMessage out varchar2)
  is
  begin
    oResult  := CanDeleteGood(iGoodID => iGoodID, oMessage => oMessage);
  end CanDeleteGood;

  /**
  * function pGetOptionByName
  * Description
  *   Retourne la valeur d'une option de copie/synchronisation d'un produit selon son nom
  * @created age 03.02.2014
  * @lastUpdate
  * @private
  * @param iOption     : Options au format XML
  * @param iOptionName : Nom de l'option
  * @return la valeur de l'option
  */
  function pGetOptionByName(iOption in xmltype, iOptionName in varchar2)
    return integer
  as
    lValue integer;
  begin
    select extractvalue(iOption, '*/' || iOptionName || '[1]/text()')
      into lValue
      from dual;

    return lValue;
  end pGetOptionByName;

  /**
  * function loadProductCopySyncOptions
  * Description
  *   Charge les options de copie/synchronisation d'un produit dans le type record correspondant
  */
  function loadProductCopySyncOptions(iOptions in clob)
    return GCO_LIB_CONSTANT.gtProductCopySyncOptions
  as
    lxOptions xmltype;
    ltOptions GCO_LIB_CONSTANT.gtProductCopySyncOptions;
  begin
    if    (iOptions is null)
       or (DBMS_LOB.getLength(iOptions) = 0) then
      return null;
    end if;

    lxOptions                               := xmltype.CreateXML(iOptions);
    -- Chargement des options
    ltOptions.bFAL_SCHEDULE_PLAN            := pGetOptionByName(lxOptions, 'FAL_SCHEDULE_PLAN');
    ltOptions.bFREE_DATA                    := pGetOptionByName(lxOptions, 'FREE_DATA');
    ltOptions.bGCO_COMPL_DATA_ASS           := pGetOptionByName(lxOptions, 'GCO_COMPL_DATA_ASS');
    ltOptions.bGCO_COMPL_DATA_DISTRIB       := pGetOptionByName(lxOptions, 'GCO_COMPL_DATA_DISTRIB');
    ltOptions.bGCO_COMPL_DATA_EXTERNAL_ASA  := pGetOptionByName(lxOptions, 'GCO_COMPL_DATA_EXTERNAL_ASA');
    ltOptions.bGCO_COMPL_DATA_INVENTORY     := pGetOptionByName(lxOptions, 'GCO_COMPL_DATA_INVENTORY');
    ltOptions.bGCO_COMPL_DATA_MANUFACTURE   := pGetOptionByName(lxOptions, 'GCO_COMPL_DATA_MANUFACTURE');
    ltOptions.bGCO_COMPL_DATA_PURCHASE      := pGetOptionByName(lxOptions, 'GCO_COMPL_DATA_PURCHASE');
    ltOptions.bGCO_COMPL_DATA_SALE          := pGetOptionByName(lxOptions, 'GCO_COMPL_DATA_SALE');
    ltOptions.bGCO_COMPL_DATA_STOCK         := pGetOptionByName(lxOptions, 'GCO_COMPL_DATA_STOCK');
    ltOptions.bGCO_COMPL_DATA_SUBCONTRACT   := pGetOptionByName(lxOptions, 'GCO_COMPL_DATA_SUBCONTRACT');
    ltOptions.bGCO_CONNECTED_GOOD           := pGetOptionByName(lxOptions, 'GCO_CONNECTED_GOOD');
    ltOptions.bGCO_COUPLED_GOOD             := pGetOptionByName(lxOptions, 'GCO_COUPLED_GOOD');
    ltOptions.bGCO_GOOD                     := nvl(pGetOptionByName(lxOptions, 'GCO_GOOD'), 0);
    ltOptions.bGCO_GOOD_ATTRIBUTE           := pGetOptionByName(lxOptions, 'GCO_GOOD_ATTRIBUTE');
    ltOptions.bGCO_PRECIOUS_MAT             := pGetOptionByName(lxOptions, 'GCO_PRECIOUS_MAT');
    ltOptions.bPPS_NOMENCLATURE             := pGetOptionByName(lxOptions, 'PPS_NOMENCLATURE');
    ltOptions.bPPS_SPECIAL_TOOLS            := pGetOptionByName(lxOptions, 'PPS_SPECIAL_TOOLS');
    ltOptions.bPPS_TOOLS                    := pGetOptionByName(lxOptions, 'PPS_TOOLS');
    ltOptions.bPTC_CALC_COSTPRICE           := pGetOptionByName(lxOptions, 'PTC_CALC_COSTPRICE');
    ltOptions.bPTC_CHARGE                   := pGetOptionByName(lxOptions, 'PTC_CHARGE');
    ltOptions.bPTC_DISCOUNT                 := pGetOptionByName(lxOptions, 'PTC_DISCOUNT');
    ltOptions.bPTC_FIXED_COSTPRICE          := pGetOptionByName(lxOptions, 'PTC_FIXED_COSTPRICE');
    ltOptions.bPTC_TARIFF                   := pGetOptionByName(lxOptions, 'PTC_TARIFF');
    ltOptions.bSQM_CERTIFICATION            := pGetOptionByName(lxOptions, 'SQM_CERTIFICATION');
    ltOptions.bVIRTUAL_FIELDS               := pGetOptionByName(lxOptions, 'VIRTUAL_FIELDS');
    return ltOptions;
  exception
    when others then
      return null;
  end loadProductCopySyncOptions;

  /**
  * function loadProductCopySyncOptions
  * Description
  *   Charge les options de copie/synchronisation d'un produit sous forme de CLOB (xml)
  */
  function loadProductCopySyncOptions(iOptions in GCO_LIB_CONSTANT.gtProductCopySyncOptions)
    return clob
  is
    lxmlData xmltype;
  begin
    -- Création du xml
    select XMLElement("OPTIONS"
                    , XMLConcat(XMLElement("FAL_SCHEDULE_PLAN", iOptions.bFAL_SCHEDULE_PLAN)
                              , XMLElement("FREE_DATA", iOptions.bFREE_DATA)
                              , XMLElement("GCO_COMPL_DATA_ASS", iOptions.bGCO_COMPL_DATA_ASS)
                              , XMLElement("GCO_COMPL_DATA_DISTRIB", iOptions.bGCO_COMPL_DATA_DISTRIB)
                              , XMLElement("GCO_COMPL_DATA_EXTERNAL_ASA", iOptions.bGCO_COMPL_DATA_EXTERNAL_ASA)
                              , XMLElement("GCO_COMPL_DATA_INVENTORY", iOptions.bGCO_COMPL_DATA_INVENTORY)
                              , XMLElement("GCO_COMPL_DATA_MANUFACTURE", iOptions.bGCO_COMPL_DATA_MANUFACTURE)
                              , XMLElement("GCO_COMPL_DATA_PURCHASE", iOptions.bGCO_COMPL_DATA_PURCHASE)
                              , XMLElement("GCO_COMPL_DATA_SALE", iOptions.bGCO_COMPL_DATA_SALE)
                              , XMLElement("GCO_COMPL_DATA_STOCK", iOptions.bGCO_COMPL_DATA_STOCK)
                              , XMLElement("GCO_COMPL_DATA_SUBCONTRACT", iOptions.bGCO_COMPL_DATA_SUBCONTRACT)
                              , XMLElement("GCO_CONNECTED_GOOD", iOptions.bGCO_CONNECTED_GOOD)
                              , XMLElement("GCO_COUPLED_GOOD", iOptions.bGCO_COUPLED_GOOD)
                              , XMLElement("GCO_GOOD", iOptions.bGCO_GOOD)
                              , XMLElement("GCO_GOOD_ATTRIBUTE", iOptions.bGCO_GOOD_ATTRIBUTE)
                              , XMLElement("GCO_PRECIOUS_MAT", iOptions.bGCO_PRECIOUS_MAT)
                              , XMLElement("PPS_NOMENCLATURE", iOptions.bPPS_NOMENCLATURE)
                              , XMLElement("PPS_SPECIAL_TOOLS", iOptions.bPPS_SPECIAL_TOOLS)
                              , XMLElement("PPS_TOOLS", iOptions.bPPS_TOOLS)
                              , XMLElement("PTC_CALC_COSTPRICE", iOptions.bPTC_CALC_COSTPRICE)
                              , XMLElement("PTC_CHARGE", iOptions.bPTC_CHARGE)
                              , XMLElement("PTC_DISCOUNT", iOptions.bPTC_DISCOUNT)
                              , XMLElement("PTC_FIXED_COSTPRICE", iOptions.bPTC_FIXED_COSTPRICE)
                              , XMLElement("PTC_TARIFF", iOptions.bPTC_TARIFF)
                              , XMLElement("SQM_CERTIFICATION", iOptions.bSQM_CERTIFICATION)
                              , XMLElement("VIRTUAL_FIELDS", iOptions.bVIRTUAL_FIELDS)
                               )
                     )
      into lxmlData
      from dual;

    return PC_JUTILS.get_XMLPrologDefault || chr(10) || lxmlData.getClobVal();
  end loadProductCopySyncOptions;

  /**
  * Description
  *   retourne le dernier SCN d'une version de bien
  */
  function GetVersionLastScn(iGoodId in GCO_GOOD.GCO_GOOD_ID%type, iVersion in GCO_PRODUCT.PDT_VERSION%type)
    return number
  is
    lResult  number;
    lVersion GCO_PRODUCT.PDT_VERSION%type;
  begin
    if iVersion is not null then
      -- contrôle si la version demandée est la version courante
      select max(PDT_VERSION)
        into lVersion
        from GCO_PRODUCT
       where gco_good_id = iGoodId
         and PDT_VERSION = iVersion;

      -- si c'est la version en cours, alors on done le dernier scn
      if lVersion is not null then
        return DBMS_FLASHBACK.GET_SYSTEM_CHANGE_NUMBER;
      else
        -- recherche le scn correspondant au moment ou la version
        -- demandée à passé à la version suivante
        select max(VERSIONS_ENDSCN)
          into lResult
          from GCO_PRODUCT
               versions between scn 0 and maxvalue
         where gco_good_id = iGoodId
           and PDT_VERSION = iVersion
           and VERSIONS_ENDSCN is not null;

        if lResult is not null then
          -- Si on a trouvé le scn du premier commit sans la version demandée
          -- on renvoie le scn qui précède
          return lResult - 1;
        else
          -- si pas trouvé dans l'historique, on prend les dernières données
          return DBMS_FLASHBACK.GET_SYSTEM_CHANGE_NUMBER;
        end if;
      end if;
    else
      -- si pas de version donnée, on prend les dernières données
      return DBMS_FLASHBACK.GET_SYSTEM_CHANGE_NUMBER;
    end if;
  end GetVersionLastScn;

  /**
  * Description
  *   Retourne la description de la catégorie de bien
  */
  function GetGoodCategoryDescr(iGoodId in GCO_GOOD.GCO_GOOD_ID%type, iLangId in PCS.PC_LANG.PC_LANG_ID%type)
    return GCO_GOOD_CATEGORY_DESCR.GCD_WORDING%type
  is
    lResult GCO_GOOD_CATEGORY_DESCR.GCD_WORDING%type;
  begin
    select nvl(GCD.GCD_WORDING, CAT.GCO_GOOD_CATEGORY_WORDING) WORDING
      into lResult
      from GCO_GOOD GOO
         , GCO_GOOD_CATEGORY CAT
         , GCO_GOOD_CATEGORY_DESCR GCD
     where GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID
       and CAT.GCO_GOOD_CATEGORY_ID = GCD.GCO_GOOD_CATEGORY_ID
       and GOO.GCO_GOOD_ID = iGoodId
       and GCD.PC_LANG_ID = iLangId;

    return lResult;
  exception
    when no_data_found then
      return '';
  end GetGoodCategoryDescr;

  /**
  * procedure getProductStateReportFileName
  * Description
  *    Retourne le nom calculé du fichier de l'export du rapport de l'état du produit avant
  *    une synchronisation avec un autre produit à stocker dans la gestion des pièces jointes.
  *    Ce nom est calculé selon <REP_NAME>_v<PDT_VERSION>_<TIMESTAMP>'.pdf'
  *    Valeur des macros :
  *    - <REP_NAME>    : Nom du rapport.
  *    - <PDT_VERSION> : Version du produit avant synchronisation
  *    - <TIMESTAMP>   : Date et heure de l'exportation au format "YYYYMMDD_HH24MISS"
  */
  function getProductStateReportFileName(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return varchar2
  as
    lVersion    GCO_PRODUCT.PDT_VERSION%type;
    lReportName varchar2(32767);
  begin
    lReportName  := pcs.PC_CONFIG.GetConfigUpper('GCO_USE_SAVE_CURRENT_STATE_RPT');

    select PDT_VERSION
      into lVersion
      from GCO_PRODUCT
     where GCO_GOOD_ID = iGoodId;

    return lReportName || '_v' || lVersion || '_' || to_char(sysdate, 'YYYYMMDD_HH24MISS') || '.pdf';
  end getProductStateReportFileName;

  /**
  * function IsGoodDeleting
  * Description
  *   Indique que l'on est en train d'effacer un bien
  *     voir la méthode GCO_PRC_GOOD.SetGoodDeleting et son utilisation dans les
  *     triggers d'effacement d'un bien
  */
  function IsGoodDeleting(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return integer
  is
    lnCount integer;
  begin
    select count(*)
      into lnCount
      from COM_LIST_ID_TEMP
     where COM_LIST_ID_TEMP_ID = iGoodID
       and LID_CODE = 'GOOD_DELETING';

    return lnCount;
  end IsGoodDeleting;
end GCO_LIB_FUNCTIONS;
