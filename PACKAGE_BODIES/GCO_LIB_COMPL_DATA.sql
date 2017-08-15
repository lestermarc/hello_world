--------------------------------------------------------
--  DDL for Package Body GCO_LIB_COMPL_DATA
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_LIB_COMPL_DATA" 
is
  -- C_ADMIN_DOMAIN
  gcAdminDomainPurchase    constant char(1) := '1';
  gcAdminDomainSale        constant char(1) := '2';
  gcAdminDomainStock       constant char(1) := '3';
  gcAdminDomainFAL         constant char(1) := '4';
  gcAdminDomainSubContract constant char(1) := '5';
  gcAdminDomainQuality     constant char(1) := '6';
  gcAdminDomainASA         constant char(1) := '7';
  gcAdminDomainInventory   constant char(1) := '8';

  /**
  * Fonction de retour du flag "Bloquer pour inventaire" des donn�es
  * compl�mentaires d'inventaire du bien
  */
  function GetFixedStockPosition(
    iGoodId     GCO_COMPL_DATA_INVENTORY.GCO_GOOD_ID%type
  , iStockId    GCO_COMPL_DATA_INVENTORY.STM_STOCK_ID%type
  , iLocationId GCO_COMPL_DATA_INVENTORY.STM_LOCATION_ID%type
  )
    return GCO_COMPL_DATA_INVENTORY.CIN_FIXED_STOCK_POSITION%type
  is
    lTmpFlag GCO_COMPL_DATA_INVENTORY.CIN_FIXED_STOCK_POSITION%type;
  begin
    begin
      select CIN_FIXED_STOCK_POSITION
        into lTmpFlag
        from GCO_COMPL_DATA_INVENTORY
       where GCO_GOOD_ID = iGoodId
         and STM_STOCK_ID = iStockId
         and STM_LOCATION_ID = iLocationId;
    exception
      when no_data_found then
        begin
          select CIN_FIXED_STOCK_POSITION
            into lTmpFlag
            from GCO_COMPL_DATA_INVENTORY
           where GCO_GOOD_ID = iGoodId
             and STM_STOCK_ID = iStockId
             and STM_LOCATION_ID is null;
        exception
          when no_data_found then
            begin
              select CIN_FIXED_STOCK_POSITION
                into lTmpFlag
                from GCO_COMPL_DATA_INVENTORY
               where GCO_GOOD_ID = iGoodId
                 and STM_STOCK_ID is null
                 and STM_LOCATION_ID is null;
            exception
              when no_data_found then
                if PCS.PC_CONFIG.GetBooleanConfig('GCO_CInven_FIXED_ST_POS') then
                  lTmpFlag  := 1;
                else
                  lTmpFlag  := 0;
                end if;
            end;
        end;
    end;

    return lTmpFlag;
  end GetFixedStockPosition;

-----------------------------------------------------------------------------------------------------------------------
  function GetQuantityMin(iGoodId in number)
    return number
  is
    lQtyMin number;
  begin
    select sum(A.CST_QUANTITY_MIN)
      into lQtyMin
      from GCO_COMPL_DATA_STOCK A
         , STM_STOCK B
     where A.GCO_GOOD_ID = iGoodId
       and A.STM_STOCK_ID = B.STM_STOCK_ID
       and B.STO_NEED_CALCULATION = 1;

    return lQtyMin;
  end GetQuantityMin;

-----------------------------------------------------------------------------------------------------------------------
  function GetSaleConvertFactor(iGoodId in number, iThirdId in number)
    return number
  is
  begin
    return PTC_FIND_TARIFF.GetSaleConvertFactor(iGoodId, iThirdId);
  end GetSaleConvertFactor;

  /**
  * Description
  *        Retourne l'id des donn�es compl�mentaires d'achat  li�es au couple bien/client
  */
  function GetComplDataPurchaseId(iGoodId in number, iThirdId in number)
    return number
  is
    lResult       GCO_COMPL_DATA_PURCHASE.GCO_COMPL_DATA_PURCHASE_ID%type;

    cursor lcurComplData(iGoodId number, iThirdId number)
    is
      select   rpad(decode(PAC_SUPPLIER_PARTNER_ID, null, '1            ', '0' || to_char(PAC_SUPPLIER_PARTNER_ID, '000000000000') ), 13, ' ') order1
             , '1          ' order2
             , GCO_COMPL_DATA_PURCHASE_ID
          from GCO_COMPL_DATA_PURCHASE
         where GCO_GOOD_ID = iGoodId
           and DIC_COMPLEMENTARY_DATA_ID is null
           and (   PAC_SUPPLIER_PARTNER_ID = iThirdId
                or PAC_SUPPLIER_PARTNER_ID is null)
      union
      select   '1            ' order1
             , decode(A.DIC_COMPLEMENTARY_DATA_ID, null, '1          ', '0' || rpad(A.DIC_COMPLEMENTARY_DATA_ID, 10) ) order2
             , GCO_COMPL_DATA_PURCHASE_ID
          from GCO_COMPL_DATA_PURCHASE A
             , PAC_SUPPLIER_PARTNER B
         where GCO_GOOD_ID = iGoodId
           and A.PAC_SUPPLIER_PARTNER_ID is null
           and A.DIC_COMPLEMENTARY_DATA_ID = B.DIC_COMPLEMENTARY_DATA_ID
           and B.PAC_SUPPLIER_PARTNER_ID = iThirdId
      order by 1
             , 2;

    ltplComplData lcurComplData%rowtype;
  begin
    open lcurComplData(iGoodId, iThirdId);

    fetch lcurComplData
     into ltplComplData;

    if lcurComplData%notfound then
      lResult  := -1;
    else
      lResult  := ltplComplData.GCO_COMPL_DATA_PURCHASE_ID;
    end if;

    close lcurComplData;

    return lResult;
  end GetComplDataPurchaseId;

  /**
  * Description
  *        Retourne l'id des donn�es compl�mentaires de vente  li�es au couple bien/client
  */
  function GetComplDataSaleId(iGoodId in number, iThirdId in number)
    return number
  is
    lResult       GCO_COMPL_DATA_SALE.GCO_COMPL_DATA_SALE_ID%type;

    cursor lcurComplData(iGoodId number, iThirdId number)
    is
      select   rpad(decode(PAC_CUSTOM_PARTNER_ID, null, '1            ', '0' || to_char(PAC_CUSTOM_PARTNER_ID, '000000000000') ), 13, ' ') order1
             , '1          ' order2
             , GCO_COMPL_DATA_SALE_ID
          from GCO_COMPL_DATA_SALE
         where GCO_GOOD_ID = iGoodId
           and DIC_COMPLEMENTARY_DATA_ID is null
           and (   PAC_CUSTOM_PARTNER_ID = iThirdId
                or PAC_CUSTOM_PARTNER_ID is null)
      union
      select   '1            ' order1
             , decode(A.DIC_COMPLEMENTARY_DATA_ID, null, '1          ', '0' || rpad(A.DIC_COMPLEMENTARY_DATA_ID, 10) ) order2
             , GCO_COMPL_DATA_SALE_ID
          from GCO_COMPL_DATA_SALE A
             , PAC_CUSTOM_PARTNER B
         where GCO_GOOD_ID = iGoodId
           and A.PAC_CUSTOM_PARTNER_ID is null
           and A.DIC_COMPLEMENTARY_DATA_ID = B.DIC_COMPLEMENTARY_DATA_ID
           and B.PAC_CUSTOM_PARTNER_ID = iThirdId
      order by 1
             , 2;

    ltplComplData lcurComplData%rowtype;
  begin
    open lcurComplData(iGoodId, iThirdId);

    fetch lcurComplData
     into ltplComplData;

    if lcurComplData%notfound then
      lResult  := -1;
    else
      lResult  := ltplComplData.GCO_COMPL_DATA_SALE_ID;
    end if;

    close lcurComplData;

    return lResult;
  end GetComplDataSaleId;

  /**
  * Function GetComplDataManufactureId
  * Description
  *        Retourne l'id des donn�es compl�mentaires de fabrication
  */
  function GetComplDataManufactureId(iGoodId in number)
    return number
  is
    lResult       GCO_COMPL_DATA_MANUFACTURE.GCO_COMPL_DATA_MANUFACTURE_ID%type;

    cursor lcurComplData(iGoodId number)
    is
      select   GCO_COMPL_DATA_MANUFACTURE_ID
             , CMA_DEFAULT
          from GCO_COMPL_DATA_MANUFACTURE
         where GCO_GOOD_ID = iGoodId
      order by CMA_DEFAULT desc;

    ltplComplData lcurComplData%rowtype;
  begin
    open lcurComplData(iGoodId);

    fetch lcurComplData
     into ltplComplData;

    if lcurComplData%notfound then
      lResult  := -1;
    else
      lResult  := ltplComplData.GCO_COMPL_DATA_MANUFACTURE_ID;
    end if;

    close lcurComplData;

    return lResult;
  end GetComplDataManufactureId;

  /**
  * Description
  *   Recherche les informations des donn�es compl�mentaires
  */
  procedure GetComplementaryData(
    iGoodID             in     number
  , iAdminDomain        in     varchar2
  , iThirdID            in     number
  , iLangID             in     number
  , iOperationID        in     number
  , iTransProprietor    in     number
  , iComplDataID        in     number
  , oStockId            out    number
  , oLocationId         out    number
  , oReference          out    varchar2
  , oSecondaryReference out    varchar2
  , oShortDescription   out    varchar2
  , oLongDescription    out    varchar2
  , oFreeDescription    out    varchar2
  , oEanCode            out    varchar2
  , oEanUCC14Code       out    varchar2
  , oHIBCPrimaryCode    out    varchar2
  , oDicUnitOfMeasure   out    varchar2
  , oConvertFactor      out    number
  , oNumberOfDecimal    out    number
  , oQuantity           out    number
  , iVersion            in     varchar2 default null
  )
  is
    /* Recherche des infos sur le bien (descriptions, nbr d�cimales, ...)
       Si domaine Achat, Vente ou Sous-traitance langue en param = langue du document
       Si autre domaine langue en param = langue de l'utilisateur

       Cascasde de recherche des descriptions
           1. Descriptions du domaine courant avec langue en param
           2. Descriptions de type principale avec langue en param
           3. Descriptions du domaine courant avec langue soci�t�
           4. Descriptions de type principale avec langue soci�t�
    */
    cursor lcurGoodDescr(iGoodID number, cLangID number, cTypeDescr varchar2)
    is
      select GOO.GOO_MAJOR_REFERENCE
           , GOO.GOO_SECONDARY_REFERENCE
           , GOO.GOO_EAN_CODE
           , GOO.GOO_EAN_UCC14_CODE
           , GOO.GOO_HIBC_PRIMARY_CODE
           , nvl(nvl(DES_1.DES_SHORT_DESCRIPTION, DES_2.DES_SHORT_DESCRIPTION), nvl(DES_3.DES_SHORT_DESCRIPTION, DES_4.DES_SHORT_DESCRIPTION) )
                                                                                                                                          DES_SHORT_DESCRIPTION
           , nvl(nvl(DES_1.DES_LONG_DESCRIPTION, DES_2.DES_LONG_DESCRIPTION), nvl(DES_3.DES_LONG_DESCRIPTION, DES_4.DES_LONG_DESCRIPTION) )
                                                                                                                                           DES_LONG_DESCRIPTION
           , nvl(nvl(DES_1.DES_FREE_DESCRIPTION, DES_2.DES_FREE_DESCRIPTION), nvl(DES_3.DES_FREE_DESCRIPTION, DES_4.DES_FREE_DESCRIPTION) )
                                                                                                                                           DES_FREE_DESCRIPTION
           , GOO.DIC_UNIT_OF_MEASURE_ID
           , 1 CDA_CONVERSION_FACTOR
           , GOO_NUMBER_OF_DECIMAL
        from GCO_GOOD as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion) GOO
           , GCO_PRODUCT as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion) PDT
           , GCO_DESCRIPTION as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion) DES_1
           , GCO_DESCRIPTION as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion) DES_2
           , GCO_DESCRIPTION as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion) DES_3
           , GCO_DESCRIPTION as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion) DES_4
       where GOO.GCO_GOOD_ID = iGoodID
         and PDT.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
         and DES_1.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
         and DES_1.C_DESCRIPTION_TYPE(+) = cTypeDescr
         and DES_1.PC_LANG_ID(+) = cLangID
         and DES_2.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
         and DES_2.C_DESCRIPTION_TYPE(+) = '01'
         and DES_2.PC_LANG_ID(+) = cLangID
         and DES_3.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
         and DES_3.C_DESCRIPTION_TYPE(+) = cTypeDescr
         and DES_3.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.GetCompLangId
         and DES_4.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
         and DES_4.C_DESCRIPTION_TYPE(+) = '01'
         and DES_4.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.GetCompLangId;

    ltplGoodDescr lcurGoodDescr%rowtype;
    lTypeDescr    varchar2(3);
    lLangID       number;
  begin
    oStockId             := null;
    oLocationId          := null;
    oReference           := null;
    oSecondaryReference  := null;
    oShortDescription    := null;
    oLongDescription     := null;
    oFreeDescription     := null;
    oEanCode             := null;
    oEanUCC14Code        := null;
    oHIBCPrimaryCode     := null;
    oDicUnitOfMeasure    := null;
    oConvertFactor       := null;
    oNumberOfDecimal     := null;
    oQuantity            := null;

    -- Si en domaine Achat, Vente ou Sous-Traitance la langue pass�e en param
    -- est g�n�ralement initialis�e (langue du document)
    -- Si la langue n'est pas pass�e en param, utiliser la langue de l'utilisateur
    if iLangID is null then
      lLangID  := PCS.PC_I_LIB_SESSION.GetUserLangId;
    else
      lLangID  := iLangID;
    end if;

    -- Achat
    if iAdminDomain = gcAdminDomainPurchase then
      lTypeDescr  := '03';   -- Description Achat
      -- Recherche les informations sur les donn�es compl. de Achat
      GetComplDataPurchase(iGoodID
                         , iThirdID
                         , iOperationID
                         , iComplDataID
                         , oStockId
                         , oLocationId
                         , oReference
                         , oSecondaryReference
                         , oShortDescription
                         , oLongDescription
                         , oFreeDescription
                         , oEanCode
                         , oEanUCC14Code
                         , oHIBCPrimaryCode
                         , oDicUnitOfMeasure
                         , oConvertFactor
                         , oNumberOfDecimal
                         , oQuantity
                         , iVersion
                          );
    -- Vente
    elsif iAdminDomain = gcAdminDomainSale then
      lTypeDescr  := '04';   -- Description Vente
      -- Recherche les informations sur les donn�es compl. de Vente
      GetComplDataSale(iGoodID
                     , iThirdID
                     , iComplDataID
                     , oStockId
                     , oLocationId
                     , oReference
                     , oSecondaryReference
                     , oShortDescription
                     , oLongDescription
                     , oFreeDescription
                     , oEanCode
                     , oEanUCC14Code
                     , oHIBCPrimaryCode
                     , oDicUnitOfMeasure
                     , oConvertFactor
                     , oNumberOfDecimal
                     , oQuantity
                     , iVersion
                      );
    -- Stock
    elsif iAdminDomain = gcAdminDomainStock then
      lTypeDescr  := '02';   -- Description Stock
      -- Recherche les informations sur les donn�es compl. de Stock
      GetComplDataStock(iGoodID
                      , iTransProprietor
                      , iComplDataID
                      , oStockId
                      , oLocationId
                      , oReference
                      , oSecondaryReference
                      , oShortDescription
                      , oLongDescription
                      , oFreeDescription
                      , oEanCode
                      , oEanUCC14Code
                      , oDicUnitOfMeasure
                      , oConvertFactor
                      , oNumberOfDecimal
                      , oQuantity
                      , iVersion
                       );
    -- Fabrication
    elsif iAdminDomain = gcAdminDomainFAL then
      lTypeDescr  := '05';   -- Description Fabrication
    -- Sous-traitance
    elsif iAdminDomain = gcAdminDomainSubContract then
      lTypeDescr  := '06';   -- Description Sous-Traitance
      -- Recherche les informations sur les donn�es compl. de Sous-Traitance
      GetComplDataSubcontract(iGoodID
                            , iThirdID
                            , iComplDataID
                            , oStockId
                            , oLocationId
                            , oReference
                            , oSecondaryReference
                            , oShortDescription
                            , oLongDescription
                            , oFreeDescription
                            , oEanCode
                            , oEanUCC14Code
                            , oDicUnitOfMeasure
                            , oConvertFactor
                            , oNumberOfDecimal
                            , oQuantity
                            , iVersion
                             );
    -- Qualit� ??
    elsif iAdminDomain = gcAdminDomainQuality then
      lTypeDescr  := '01';   -- Description Principale
    -- SAV
    elsif iAdminDomain = gcAdminDomainASA then
      lTypeDescr  := '07';   -- Description SAV
    -- Inventaire
    elsif iAdminDomain = gcAdminDomainInventory then
      lTypeDescr  := '11';   -- Description Inventaire
    end if;

    -- remplace donn�es compl�mentaires non trouv�es
    -- par les donn�es par d�faut du bien
    open lcurGoodDescr(iGoodID, lLangID, lTypeDescr);

    fetch lcurGoodDescr
     into ltplGoodDescr;

    -- Ne reprendre le stock et l'emplacement du bien que si l'on n'a pas
    -- trouv� le stock au niveau des donn�es compl�mentaires
    if oStockId is null then
      GCO_LIB_FUNCTIONS.GetGoodStockLocation(iGoodID, oStockId, oLocationId, iVersion);
    end if;

    oReference           := nvl(oReference, ltplGoodDescr.GOO_MAJOR_REFERENCE);
    oSecondaryReference  := nvl(oSecondaryReference, ltplGoodDescr.GOO_SECONDARY_REFERENCE);
    oShortDescription    := nvl(oShortDescription, ltplGoodDescr.DES_SHORT_DESCRIPTION);
    oLongDescription     := nvl(oLongDescription, ltplGoodDescr.DES_LONG_DESCRIPTION);
    oFreeDescription     := nvl(oFreeDescription, ltplGoodDescr.DES_FREE_DESCRIPTION);
    oEanCode             := nvl(oEanCode, ltplGoodDescr.GOO_EAN_CODE);
    oEanUCC14Code        := nvl(oEanUCC14Code, ltplGoodDescr.GOO_EAN_UCC14_CODE);
    oHIBCPrimaryCode     := nvl(oHIBCPrimarycode, ltplGoodDescr.GOO_HIBC_PRIMARY_CODE);
    oDicUnitOfMeasure    := nvl(oDicUnitOfMeasure, ltplGoodDescr.DIC_UNIT_OF_MEASURE_ID);
    oConvertFactor       := nvl(oConvertFactor, ltplGoodDescr.CDA_CONVERSION_FACTOR);
    oNumberOfDecimal     := nvl(oNumberOfDecimal, ltplGoodDescr.GOO_NUMBER_OF_DECIMAL);

    close lcurGoodDescr;
  end GetComplementaryData;

  /**
  * Description
  *    Return the default subcontracting nomenclature for a good and a supplier
  */
  function GetDefaultSubCComplData(
    iGoodId       in GCO_COMPL_DATA_SUBCONTRACT.GCO_GOOD_ID%type
  , iSupplierId   in GCO_COMPL_DATA_SUBCONTRACT.PAC_SUPPLIER_PARTNER_ID%type
  , iLinkedGoodId in GCO_COMPL_DATA_SUBCONTRACT.GCO_GCO_GOOD_ID%type default null
  , iDateRef      in GCO_COMPL_DATA_SUBCONTRACT.CSU_VALIDITY_DATE%type default sysdate
  )
    return GCO_COMPL_DATA_SUBCONTRACT%rowtype
  is
  begin
    for ltplNomenclature in (select   *
                                 from GCO_COMPL_DATA_SUBCONTRACT
                                where GCO_GOOD_ID = iGoodId
                                  and nvl(PAC_SUPPLIER_PARTNER_ID, iSupplierId) = iSupplierId
                                  and nvl(GCO_GCO_GOOD_ID, 0) = nvl(iLinkedGoodId, nvl(GCO_GCO_GOOD_ID, 0) )
                                  and nvl(trunc(CSU_VALIDITY_DATE), trunc(iDateRef) ) <= trunc(iDateRef)
                             order by CSU_VALIDITY_DATE desc
                                    , PAC_SUPPLIER_PARTNER_ID nulls last) loop
      return ltplNomenclature;
    end loop;

    return null;
  end GetDefaultSubCComplData;

  /**
  * Description
  *    Return the default subcontracting nomenclature for a good and a supplier
  */
  function GetSubCComplDataTuple(iComplDataId in GCO_COMPL_DATA_SUBCONTRACT.GCO_COMPL_DATA_SUBCONTRACT_ID%type)
    return GCO_COMPL_DATA_SUBCONTRACT%rowtype
  is
    lTplComplData GCO_COMPL_DATA_SUBCONTRACT%rowtype;
  begin
    select *
      into lTplComplData
      from GCO_COMPL_DATA_SUBCONTRACT
     where GCO_COMPL_DATA_SUBCONTRACT_ID = iComplDataId;

    return lTplComplData;
  exception
    when no_data_found then
      return null;
  end GetSubCComplDataTuple;

   /**
  * function GetStockComplDataID
  * Description
  *    Returnan ID of stock complementary data
  * @created fp 25.10.2013
  * @lastUpdate
  * @public
  * @param iGoodId
  * @return
  */
  function GetStockComplDataID(
    iGoodId     in GCO_COMPL_DATA_STOCK.GCO_GOOD_ID%type
  , iStockId    in GCO_COMPL_DATA_STOCK.STM_STOCK_ID%type default null
  , iLocationId in GCO_COMPL_DATA_STOCK.STM_LOCATION_ID%type default null
  )
    return GCO_COMPL_DATA_STOCK.GCO_COMPL_DATA_STOCK_ID%type
  is
  begin
    return GetStockComplDataTuple(iGoodId, iStockId, iLocationId).GCO_COMPL_DATA_STOCK_ID;
  end;

  /**
  * Description
  *    Return a tuple of stock complementary data
  */
  function GetStockComplDataTuple(
    iGoodId     in GCO_COMPL_DATA_STOCK.GCO_GOOD_ID%type
  , iStockId    in GCO_COMPL_DATA_STOCK.STM_STOCK_ID%type default null
  , iLocationId in GCO_COMPL_DATA_STOCK.STM_LOCATION_ID%type default null
  )
    return GCO_COMPL_DATA_STOCK%rowtype
  is
    lResult  GCO_COMPL_DATA_STOCK%rowtype;
    lStockID GCO_COMPL_DATA_STOCK.STM_STOCK_ID%type   := nvl(iStockId, FWK_I_LIB_ENTITY.getNumberFieldFromPk('STM_LOCATION', 'STM_STOCK_ID', iLocationId) );
  begin
    for ltplComplData in (select   *
                              from GCO_COMPL_DATA_STOCK
                             where (    GCO_GOOD_ID = iGoodId
                                    and STM_LOCATION_ID is null
                                    and STM_STOCK_ID is null)   -- valeur globale
                                or (    GCO_GOOD_ID = iGoodId
                                    and STM_LOCATION_ID = iLocationId)   -- valeur li�e � l'emplacement
                                or (    GCO_GOOD_ID = iGoodId
                                    and STM_STOCK_ID = lStockID
                                    and STM_LOCATION_ID is null)   -- valeur li�e au stock
                          order by STM_LOCATION_ID nulls last
                                 , STM_STOCK_ID nulls last) loop
      -- retourne la premi�re valeur trouv�e
      return ltplComplData;
    end loop;

    -- si rien trouv�, on retourne null
    return null;
  end GetStockComplDataTuple;

  /**
  * Description
  *   Indique si on g�re les conditions de stockage
  */
  function IsStorageConditionCheck(
    iGoodId     in GCO_COMPL_DATA_STOCK.GCO_GOOD_ID%type
  , iStockId    in GCO_COMPL_DATA_STOCK.STM_STOCK_ID%type default null
  , iLocationId in GCO_COMPL_DATA_STOCK.STM_LOCATION_ID%type default null
  )
    return number
  is
  begin
    return nvl(GetStockComplDataTuple(iGoodId => iGoodId, iStockId => iStockId, iLocationId => iLocationId).CST_CHECK_STORAGE_COND, 0);
  end IsStorageConditionCheck;

  /**
  * Description
  *    Return the default subcontracting nomenclature for a good and a supplier
  */
  function GetDefaultSubCComplDataId(
    iGoodId       in GCO_COMPL_DATA_SUBCONTRACT.GCO_GOOD_ID%type
  , iSupplierId   in GCO_COMPL_DATA_SUBCONTRACT.PAC_SUPPLIER_PARTNER_ID%type
  , iLinkedGoodId in GCO_COMPL_DATA_SUBCONTRACT.GCO_GCO_GOOD_ID%type default null
  , iDateRef      in GCO_COMPL_DATA_SUBCONTRACT.CSU_VALIDITY_DATE%type default sysdate
  )
    return GCO_COMPL_DATA_SUBCONTRACT.GCO_COMPL_DATA_SUBCONTRACT_ID%type
  is
  begin
    return GetDefaultSubCComplData(iGoodId, iSupplierId, iLinkedGoodId, iDateRef).GCO_COMPL_DATA_SUBCONTRACT_ID;
  end GetDefaultSubCComplDataId;

  /**
  * Description
  *   Recherche les informations sur les donn�es compl. de Achat
  */
  procedure GetComplDataPurchase(
    iGoodID             in     number
  , iThirdID            in     number
  , iOperationID        in     number
  , iComplDataID        in     number
  , oStockId            out    number
  , oLocationId         out    number
  , oReference          out    varchar2
  , oSecondaryReference out    varchar2
  , oShortDescription   out    varchar2
  , oLongDescription    out    varchar2
  , oFreeDescription    out    varchar2
  , oEanCode            out    varchar2
  , oEanUCC14Code       out    varchar2
  , oHIBCPrimaryCode    out    varchar2
  , oDicUnitOfMeasure   out    varchar2
  , oConvertFactor      out    number
  , oNumberOfDecimal    out    number
  , oQuantity           out    number
  , iVersion            in     varchar2 default null
  )
  is
    -- Recherche des donn�es compl d'Achat
    cursor lcurGetComplData(iGoodID number, iThirdID number)
    is
      select   rpad(decode(PAC_SUPPLIER_PARTNER_ID, null, '1            ', '0' || to_char(PAC_SUPPLIER_PARTNER_ID) ), 13, ' ') order1
             , '1          ' order2
             , CPU_DEFAULT_SUPPLIER
             , STM_STOCK_ID
             , STM_LOCATION_ID
             , CDA_COMPLEMENTARY_REFERENCE
             , CDA_SECONDARY_REFERENCE
             , CDA_SHORT_DESCRIPTION
             , CDA_LONG_DESCRIPTION
             , CDA_FREE_DESCRIPTION
             , CDA_COMPLEMENTARY_EAN_CODE
             , CDA_COMPLEMENTARY_UCC14_CODE
             , CPU_HIBC_CODE
             , DIC_UNIT_OF_MEASURE_ID
             , nvl(CDA_CONVERSION_FACTOR, 1) CDA_CONVERSION_FACTOR
             , CDA_NUMBER_OF_DECIMAL
             , CPU_ECONOMICAL_QUANTITY
          from GCO_COMPL_DATA_PURCHASE as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion) A
         where GCO_GOOD_ID = iGoodID
           and DIC_COMPLEMENTARY_DATA_ID is null
           and (   PAC_SUPPLIER_PARTNER_ID = iThirdID
                or PAC_SUPPLIER_PARTNER_ID is null)
      union
      select   '1            ' order1
             , decode(A.DIC_COMPLEMENTARY_DATA_ID, null, '1          ', '0' || rpad(A.DIC_COMPLEMENTARY_DATA_ID, 10) ) order2
             , CPU_DEFAULT_SUPPLIER
             , A.STM_STOCK_ID
             , A.STM_LOCATION_ID
             , CDA_COMPLEMENTARY_REFERENCE
             , CDA_SECONDARY_REFERENCE
             , CDA_SHORT_DESCRIPTION
             , CDA_LONG_DESCRIPTION
             , CDA_FREE_DESCRIPTION
             , CDA_COMPLEMENTARY_EAN_CODE
             , CDA_COMPLEMENTARY_UCC14_CODE
             , CPU_HIBC_CODE
             , DIC_UNIT_OF_MEASURE_ID
             , nvl(CDA_CONVERSION_FACTOR, 1) CDA_CONVERSION_FACTOR
             , CDA_NUMBER_OF_DECIMAL
             , CPU_ECONOMICAL_QUANTITY
          from GCO_COMPL_DATA_PURCHASE as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion) A
             , PAC_SUPPLIER_PARTNER as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion) B
         where GCO_GOOD_ID = iGoodID
           and A.PAC_SUPPLIER_PARTNER_ID is null
           and A.DIC_COMPLEMENTARY_DATA_ID = B.DIC_COMPLEMENTARY_DATA_ID
           and B.PAC_SUPPLIER_PARTNER_ID = iThirdID
      order by 1
             , 2
             , 3 desc;

    ltplGetComplData       lcurGetComplData%rowtype;

    -- Donn�es compl de vente de l'ID de la donn�e compl pass� en param
    cursor lcurGetComplDataWithID(iDataComplID number)
    is
      select STM_STOCK_ID
           , STM_LOCATION_ID
           , CDA_COMPLEMENTARY_REFERENCE
           , CDA_SECONDARY_REFERENCE
           , CDA_SHORT_DESCRIPTION
           , CDA_LONG_DESCRIPTION
           , CDA_FREE_DESCRIPTION
           , CDA_COMPLEMENTARY_EAN_CODE
           , CDA_COMPLEMENTARY_UCC14_CODE
           , CPU_HIBC_CODE
           , DIC_UNIT_OF_MEASURE_ID
           , nvl(CDA_CONVERSION_FACTOR, 1) CDA_CONVERSION_FACTOR
           , CDA_NUMBER_OF_DECIMAL
           , CPU_ECONOMICAL_QUANTITY
        from GCO_COMPL_DATA_PURCHASE as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion)
       where GCO_COMPL_DATA_PURCHASE_ID = iDataComplID;

    ltplGetComplDataWithID lcurGetComplDataWithID%rowtype;
    -- Descriptions de l'Op�ration
    lScsLongDescr          FAL_TASK_LINK.SCS_LONG_DESCR%type;
    lScsFreeDescr          FAL_TASK_LINK.SCS_FREE_DESCR%type;
  begin
    -- Si l'ID de l'op�ration est renseign�, il faut rechercher les descriptions au niveau de l'op�ration
    if nvl(iOperationID, 0) <> 0 then
      select SCS_LONG_DESCR
           , SCS_FREE_DESCR
        into lScsLongDescr
           , lScsFreeDescr
        from FAL_TASK_LINK as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion)
       where FAL_SCHEDULE_STEP_ID = iOperationID;
    else
      lScsLongDescr  := '';
      lScsFreeDescr  := '';
    end if;

    -- Pas d'ID de donn�e compl pass� en param
    if nvl(iComplDataID, 0) = 0 then
      open lcurGetComplData(iGoodID, iThirdID);

      fetch lcurGetComplData
       into ltplGetComplData;

      oStockId             := ltplGetComplData.STM_STOCK_ID;
      oLocationId          := ltplGetComplData.STM_LOCATION_ID;
      oReference           := ltplGetComplData.CDA_COMPLEMENTARY_REFERENCE;
      oSecondaryReference  := ltplGetComplData.CDA_SECONDARY_REFERENCE;
      oShortDescription    := ltplGetComplData.CDA_SHORT_DESCRIPTION;
      oLongDescription     := nvl(lScsLongDescr, ltplGetComplData.CDA_LONG_DESCRIPTION);
      oFreeDescription     := nvl(lScsFreeDescr, ltplGetComplData.CDA_FREE_DESCRIPTION);
      oEanCode             := ltplGetComplData.CDA_COMPLEMENTARY_EAN_CODE;
      oEanUCC14Code        := ltplGetComplData.CDA_COMPLEMENTARY_UCC14_CODE;
      oHIBCPrimaryCode     := ltplGetComplData.CPU_HIBC_CODE;
      oDicUnitOfMeasure    := ltplGetComplData.DIC_UNIT_OF_MEASURE_ID;
      oConvertFactor       := ltplGetComplData.CDA_CONVERSION_FACTOR;
      oNumberOfDecimal     := ltplGetComplData.CDA_NUMBER_OF_DECIMAL;
      oQuantity            := ltplGetComplData.CPU_ECONOMICAL_QUANTITY;

      close lcurGetComplData;
    -- L'ID de donn�e compl a �t� pass� en param
    else
      open lcurGetComplDataWithID(iComplDataID);

      fetch lcurGetComplDataWithID
       into ltplGetComplDataWithID;

      oStockId             := ltplGetComplDataWithID.STM_STOCK_ID;
      oLocationId          := ltplGetComplDataWithID.STM_LOCATION_ID;
      oReference           := ltplGetComplDataWithID.CDA_COMPLEMENTARY_REFERENCE;
      oSecondaryReference  := ltplGetComplDataWithID.CDA_SECONDARY_REFERENCE;
      oShortDescription    := ltplGetComplDataWithID.CDA_SHORT_DESCRIPTION;
      oLongDescription     := nvl(lScsLongDescr, ltplGetComplDataWithID.CDA_LONG_DESCRIPTION);
      oFreeDescription     := nvl(lScsFreeDescr, ltplGetComplDataWithID.CDA_FREE_DESCRIPTION);
      oEanCode             := ltplGetComplDataWithID.CDA_COMPLEMENTARY_EAN_CODE;
      oEanUCC14Code        := ltplGetComplDataWithID.CDA_COMPLEMENTARY_UCC14_CODE;
      oHIBCPrimaryCode     := ltplGetComplDataWithID.CPU_HIBC_CODE;
      oDicUnitOfMeasure    := ltplGetComplDataWithID.DIC_UNIT_OF_MEASURE_ID;
      oConvertFactor       := ltplGetComplDataWithID.CDA_CONVERSION_FACTOR;
      oNumberOfDecimal     := ltplGetComplDataWithID.CDA_NUMBER_OF_DECIMAL;
      oQuantity            := ltplGetComplDataWithID.CPU_ECONOMICAL_QUANTITY;

      close lcurGetComplDataWithID;
    end if;
  end GetComplDataPurchase;

  /**
  * Description
  *   Recherche les informations sur les donn�es compl. de Vente
  */
  procedure GetComplDataSale(
    iGoodID             in     number
  , iThirdID            in     number
  , iComplDataID        in     number
  , oStockId            out    number
  , oLocationId         out    number
  , oReference          out    varchar2
  , oSecondaryReference out    varchar2
  , oShortDescription   out    varchar2
  , oLongDescription    out    varchar2
  , oFreeDescription    out    varchar2
  , oEanCode            out    varchar2
  , oEanUCC14Code       out    varchar2
  , oHIBCPrimaryCode    out    varchar2
  , oDicUnitOfMeasure   out    varchar2
  , oConvertFactor      out    number
  , oNumberOfDecimal    out    number
  , oQuantity           out    number
  , iVersion            in     varchar2 default null
  )
  is
    -- Recherche des donn�es compl de vente
    cursor lcurGetComplData(iGoodID number, iThirdID number)
    is
      select   rpad(decode(PAC_CUSTOM_PARTNER_ID, null, '1            ', '0' || to_char(PAC_CUSTOM_PARTNER_ID, '000000000000') ), 13, ' ') order1
             , '1          ' order2
             , STM_STOCK_ID
             , STM_LOCATION_ID
             , CDA_COMPLEMENTARY_REFERENCE
             , CDA_SECONDARY_REFERENCE
             , CDA_SHORT_DESCRIPTION
             , CDA_LONG_DESCRIPTION
             , CDA_FREE_DESCRIPTION
             , CDA_COMPLEMENTARY_EAN_CODE
             , CDA_COMPLEMENTARY_UCC14_CODE
             , CSA_HIBC_CODE
             , DIC_UNIT_OF_MEASURE_ID
             , nvl(CDA_CONVERSION_FACTOR, 1) CDA_CONVERSION_FACTOR
             , CDA_NUMBER_OF_DECIMAL
             , CSA_QTY_CONDITIONING
          from GCO_COMPL_DATA_SALE as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion)
         where GCO_GOOD_ID = iGoodID
           and DIC_COMPLEMENTARY_DATA_ID is null
           and (   PAC_CUSTOM_PARTNER_ID = iThirdID
                or PAC_CUSTOM_PARTNER_ID is null)
      union
      select   '1            ' order1
             , decode(A.DIC_COMPLEMENTARY_DATA_ID, null, '1          ', '0' || rpad(A.DIC_COMPLEMENTARY_DATA_ID, 10) ) order2
             , A.STM_STOCK_ID
             , A.STM_LOCATION_ID
             , CDA_COMPLEMENTARY_REFERENCE
             , CDA_SECONDARY_REFERENCE
             , CDA_SHORT_DESCRIPTION
             , CDA_LONG_DESCRIPTION
             , CDA_FREE_DESCRIPTION
             , CDA_COMPLEMENTARY_EAN_CODE
             , CDA_COMPLEMENTARY_UCC14_CODE
             , CSA_HIBC_CODE
             , DIC_UNIT_OF_MEASURE_ID
             , nvl(CDA_CONVERSION_FACTOR, 1) CDA_CONVERSION_FACTOR
             , CDA_NUMBER_OF_DECIMAL
             , CSA_QTY_CONDITIONING
          from GCO_COMPL_DATA_SALE as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion) A
             , PAC_CUSTOM_PARTNER as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion) B
         where GCO_GOOD_ID = iGoodID
           and A.PAC_CUSTOM_PARTNER_ID is null
           and A.DIC_COMPLEMENTARY_DATA_ID = B.DIC_COMPLEMENTARY_DATA_ID
           and B.PAC_CUSTOM_PARTNER_ID = iThirdID
      order by 1
             , 2;

    ltplGetComplData       lcurGetComplData%rowtype;

    -- Donn�es compl de vente de l'ID de la donn�e compl pass� en param
    cursor lcurGetComplDataWithID(iDataComplID number)
    is
      select STM_STOCK_ID
           , STM_LOCATION_ID
           , CDA_COMPLEMENTARY_REFERENCE
           , CDA_SECONDARY_REFERENCE
           , CDA_SHORT_DESCRIPTION
           , CDA_LONG_DESCRIPTION
           , CDA_FREE_DESCRIPTION
           , CDA_COMPLEMENTARY_EAN_CODE
           , CDA_COMPLEMENTARY_UCC14_CODE
           , CSA_HIBC_CODE
           , DIC_UNIT_OF_MEASURE_ID
           , nvl(CDA_CONVERSION_FACTOR, 1) CDA_CONVERSION_FACTOR
           , CDA_NUMBER_OF_DECIMAL
           , CSA_QTY_CONDITIONING
        from GCO_COMPL_DATA_SALE as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion)
       where GCO_COMPL_DATA_SALE_ID = iDataComplID;

    ltplGetComplDataWithID lcurGetComplDataWithID%rowtype;
  begin
    -- Pas d'ID de donn�e compl pass� en param
    if nvl(iComplDataID, 0) = 0 then
      open lcurGetComplData(iGoodID, iThirdID);

      fetch lcurGetComplData
       into ltplGetComplData;

      oStockId             := ltplGetComplData.STM_STOCK_ID;
      oLocationId          := ltplGetComplData.STM_LOCATION_ID;
      oReference           := ltplGetComplData.CDA_COMPLEMENTARY_REFERENCE;
      oSecondaryReference  := ltplGetComplData.CDA_SECONDARY_REFERENCE;
      oShortDescription    := ltplGetComplData.CDA_SHORT_DESCRIPTION;
      oLongDescription     := ltplGetComplData.CDA_LONG_DESCRIPTION;
      oFreeDescription     := ltplGetComplData.CDA_FREE_DESCRIPTION;
      oEanCode             := ltplGetComplData.CDA_COMPLEMENTARY_EAN_CODE;
      oEanUCC14Code        := ltplGetComplData.CDA_COMPLEMENTARY_UCC14_CODE;
      oHIBCPrimaryCode     := ltplGetComplData.CSA_HIBC_CODE;
      oDicUnitOfMeasure    := ltplGetComplData.DIC_UNIT_OF_MEASURE_ID;
      oConvertFactor       := ltplGetComplData.CDA_CONVERSION_FACTOR;
      oNumberOfDecimal     := ltplGetComplData.CDA_NUMBER_OF_DECIMAL;
      oQuantity            := ltplGetComplData.CSA_QTY_CONDITIONING;

      close lcurGetComplData;
    -- L'ID de donn�e compl a �t� pass� en param
    else
      open lcurGetComplDataWithID(iComplDataID);

      fetch lcurGetComplDataWithID
       into ltplGetComplDataWithID;

      oStockId             := ltplGetComplDataWithID.STM_STOCK_ID;
      oLocationId          := ltplGetComplDataWithID.STM_LOCATION_ID;
      oReference           := ltplGetComplDataWithID.CDA_COMPLEMENTARY_REFERENCE;
      oSecondaryReference  := ltplGetComplDataWithID.CDA_SECONDARY_REFERENCE;
      oShortDescription    := ltplGetComplDataWithID.CDA_SHORT_DESCRIPTION;
      oLongDescription     := ltplGetComplDataWithID.CDA_LONG_DESCRIPTION;
      oFreeDescription     := ltplGetComplDataWithID.CDA_FREE_DESCRIPTION;
      oEanCode             := ltplGetComplDataWithID.CDA_COMPLEMENTARY_EAN_CODE;
      oEanUCC14Code        := ltplGetComplDataWithID.CDA_COMPLEMENTARY_UCC14_CODE;
      oHIBCPrimaryCode     := ltplGetComplDataWithID.CSA_HIBC_CODE;
      oDicUnitOfMeasure    := ltplGetComplDataWithID.DIC_UNIT_OF_MEASURE_ID;
      oConvertFactor       := ltplGetComplDataWithID.CDA_CONVERSION_FACTOR;
      oNumberOfDecimal     := ltplGetComplDataWithID.CDA_NUMBER_OF_DECIMAL;
      oQuantity            := ltplGetComplDataWithID.CSA_QTY_CONDITIONING;

      close lcurGetComplDataWithID;
    end if;
  end GetComplDataSale;

  /**
  * Description
  *   Recherche les informations sur les donn�es compl. de la Sous-traitance
  */
  procedure GetComplDataSubcontract(
    iGoodID             in     number
  , iThirdID            in     number
  , iComplDataID        in     number
  , oStockId            out    number
  , oLocationId         out    number
  , oReference          out    varchar2
  , oSecondaryReference out    varchar2
  , oShortDescription   out    varchar2
  , oLongDescription    out    varchar2
  , oFreeDescription    out    varchar2
  , oEanCode            out    varchar2
  , oEanUCC14Code       out    varchar2
  , oDicUnitOfMeasure   out    varchar2
  , oConvertFactor      out    number
  , oNumberOfDecimal    out    number
  , oQuantity           out    number
  , iVersion            in     varchar2 default null
  )
  is
    -- Recherche des donn�es compl de Sous-Traitance
    cursor lcurGetComplData(iGoodID number, iThirdID number)
    is
      select   rpad(decode(PAC_SUPPLIER_PARTNER_ID, null, '1            ', '0' || to_char(PAC_SUPPLIER_PARTNER_ID) ), 13, ' ') order1
             , '1          ' order2
             , STM_STOCK_ID
             , STM_LOCATION_ID
             , CDA_COMPLEMENTARY_REFERENCE
             , CDA_SECONDARY_REFERENCE
             , CDA_SHORT_DESCRIPTION
             , CDA_LONG_DESCRIPTION
             , CDA_FREE_DESCRIPTION
             , CDA_COMPLEMENTARY_EAN_CODE
             , CDA_COMPLEMENTARY_UCC14_CODE
             , DIC_UNIT_OF_MEASURE_ID
             , nvl(CDA_CONVERSION_FACTOR, 1) CDA_CONVERSION_FACTOR
             , CDA_NUMBER_OF_DECIMAL
             , CSU_ECONOMICAL_QUANTITY
          from GCO_COMPL_DATA_SUBCONTRACT as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion) A
         where GCO_GOOD_ID = iGoodId
           and DIC_COMPLEMENTARY_DATA_ID is null
           and (   PAC_SUPPLIER_PARTNER_ID = iThirdId
                or PAC_SUPPLIER_PARTNER_ID is null)
      union
      select   '1            ' order1
             , decode(A.DIC_COMPLEMENTARY_DATA_ID, null, '1          ', '0' || rpad(A.DIC_COMPLEMENTARY_DATA_ID, 10) ) order2
             , A.STM_STOCK_ID
             , A.STM_LOCATION_ID
             , CDA_COMPLEMENTARY_REFERENCE
             , CDA_SECONDARY_REFERENCE
             , CDA_SHORT_DESCRIPTION
             , CDA_LONG_DESCRIPTION
             , CDA_FREE_DESCRIPTION
             , CDA_COMPLEMENTARY_EAN_CODE
             , CDA_COMPLEMENTARY_UCC14_CODE
             , DIC_UNIT_OF_MEASURE_ID
             , nvl(CDA_CONVERSION_FACTOR, 1) CDA_CONVERSION_FACTOR
             , CDA_NUMBER_OF_DECIMAL
             , CSU_ECONOMICAL_QUANTITY
          from GCO_COMPL_DATA_SUBCONTRACT as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion) A
             , PAC_SUPPLIER_PARTNER as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion) B
         where GCO_GOOD_ID = iGoodId
           and A.PAC_SUPPLIER_PARTNER_ID is null
           and A.DIC_COMPLEMENTARY_DATA_ID = B.DIC_COMPLEMENTARY_DATA_ID
           and B.PAC_SUPPLIER_PARTNER_ID = iThirdId
      order by 1
             , 2;

    ltplGetComplData       lcurGetComplData%rowtype;

    -- Donn�es compl de Sous-Traitance de l'ID de la donn�e compl pass� en param
    cursor lcurGetComplDataWithID(iDataComplID number)
    is
      select STM_STOCK_ID
           , STM_LOCATION_ID
           , CDA_COMPLEMENTARY_REFERENCE
           , CDA_SECONDARY_REFERENCE
           , CDA_SHORT_DESCRIPTION
           , CDA_LONG_DESCRIPTION
           , CDA_FREE_DESCRIPTION
           , CDA_COMPLEMENTARY_EAN_CODE
           , CDA_COMPLEMENTARY_UCC14_CODE
           , DIC_UNIT_OF_MEASURE_ID
           , nvl(CDA_CONVERSION_FACTOR, 1) CDA_CONVERSION_FACTOR
           , CDA_NUMBER_OF_DECIMAL
           , CSU_ECONOMICAL_QUANTITY
        from GCO_COMPL_DATA_SUBCONTRACT as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion)
       where GCO_COMPL_DATA_SUBCONTRACT_ID = iDataComplID;

    ltplGetComplDataWithID lcurGetComplDataWithID%rowtype;
  begin
    -- Pas d'ID de donn�e compl pass� en param
    if nvl(iComplDataID, 0) = 0 then
      open lcurGetComplData(iGoodID, iThirdID);

      fetch lcurGetComplData
       into ltplGetComplData;

      oStockId             := ltplGetComplData.STM_STOCK_ID;
      oLocationId          := ltplGetComplData.STM_LOCATION_ID;
      oReference           := ltplGetComplData.CDA_COMPLEMENTARY_REFERENCE;
      oSecondaryReference  := ltplGetComplData.CDA_SECONDARY_REFERENCE;
      oShortDescription    := ltplGetComplData.CDA_SHORT_DESCRIPTION;
      oLongDescription     := ltplGetComplData.CDA_LONG_DESCRIPTION;
      oFreeDescription     := ltplGetComplData.CDA_FREE_DESCRIPTION;
      oEanCode             := ltplGetComplData.CDA_COMPLEMENTARY_EAN_CODE;
      oEanUCC14Code        := ltplGetComplData.CDA_COMPLEMENTARY_UCC14_CODE;
      oDicUnitOfMeasure    := ltplGetComplData.DIC_UNIT_OF_MEASURE_ID;
      oConvertFactor       := ltplGetComplData.CDA_CONVERSION_FACTOR;
      oNumberOfDecimal     := ltplGetComplData.CDA_NUMBER_OF_DECIMAL;
      oQuantity            := ltplGetComplData.CSU_ECONOMICAL_QUANTITY;

      close lcurGetComplData;
    -- L'ID de donn�e compl a �t� pass� en param
    else
      open lcurGetComplDataWithID(iComplDataID);

      fetch lcurGetComplDataWithID
       into ltplGetComplDataWithID;

      oStockId             := ltplGetComplDataWithID.STM_STOCK_ID;
      oLocationId          := ltplGetComplDataWithID.STM_LOCATION_ID;
      oReference           := ltplGetComplDataWithID.CDA_COMPLEMENTARY_REFERENCE;
      oSecondaryReference  := ltplGetComplDataWithID.CDA_SECONDARY_REFERENCE;
      oShortDescription    := ltplGetComplDataWithID.CDA_SHORT_DESCRIPTION;
      oLongDescription     := ltplGetComplDataWithID.CDA_LONG_DESCRIPTION;
      oFreeDescription     := ltplGetComplDataWithID.CDA_FREE_DESCRIPTION;
      oEanCode             := ltplGetComplDataWithID.CDA_COMPLEMENTARY_EAN_CODE;
      oEanUCC14Code        := ltplGetComplDataWithID.CDA_COMPLEMENTARY_UCC14_CODE;
      oDicUnitOfMeasure    := ltplGetComplDataWithID.DIC_UNIT_OF_MEASURE_ID;
      oConvertFactor       := ltplGetComplDataWithID.CDA_CONVERSION_FACTOR;
      oNumberOfDecimal     := ltplGetComplDataWithID.CDA_NUMBER_OF_DECIMAL;
      oQuantity            := ltplGetComplDataWithID.CSU_ECONOMICAL_QUANTITY;

      close lcurGetComplDataWithID;
    end if;
  end GetComplDataSubContract;

  /**
  * Description
  *   Recherche les informations sur les donn�es compl. de Stock
  */
  procedure GetComplDataStock(
    iGoodID             in     number
  , iTransProprietor    in     number
  , iComplDataID        in     number
  , oStockId            out    number
  , oLocationId         out    number
  , oReference          out    varchar2
  , oSecondaryReference out    varchar2
  , oShortDescription   out    varchar2
  , oLongDescription    out    varchar2
  , oFreeDescription    out    varchar2
  , oEanCode            out    varchar2
  , oEanUCC14Code       out    varchar2
  , oDicUnitOfMeasure   out    varchar2
  , oConvertFactor      out    number
  , oNumberOfDecimal    out    number
  , oQuantity           out    number
  , iVersion            in     varchar2 default null
  )
  is
    -- Recherche des donn�es compl de stock
    cursor lcurGetComplData(iGoodID number, cStockID STM_STOCK.STM_STOCK_ID%type)
    is
      select   STM_STOCK_ID
             , STM_LOCATION_ID
             , CDA_COMPLEMENTARY_REFERENCE
             , CDA_SECONDARY_REFERENCE
             , CDA_SHORT_DESCRIPTION
             , CDA_LONG_DESCRIPTION
             , CDA_FREE_DESCRIPTION
             , CDA_COMPLEMENTARY_EAN_CODE
             , CDA_COMPLEMENTARY_UCC14_CODE
             , DIC_UNIT_OF_MEASURE_ID
             , nvl(CDA_CONVERSION_FACTOR, 1) CDA_CONVERSION_FACTOR
             , CDA_NUMBER_OF_DECIMAL
          from GCO_COMPL_DATA_STOCK as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion)
         where GCO_GOOD_ID = iGoodID
           and STM_STOCK_ID = cStockID
      order by 1;

    ltplGetComplData       lcurGetComplData%rowtype;

    -- Donn�es compl de stock de l'ID de la donn�e compl pass� en param
    cursor lcurGetComplDataWithID(iDataComplID number)
    is
      select STM_STOCK_ID
           , STM_LOCATION_ID
           , CDA_COMPLEMENTARY_REFERENCE
           , CDA_SECONDARY_REFERENCE
           , CDA_SHORT_DESCRIPTION
           , CDA_LONG_DESCRIPTION
           , CDA_FREE_DESCRIPTION
           , CDA_COMPLEMENTARY_EAN_CODE
           , CDA_COMPLEMENTARY_UCC14_CODE
           , DIC_UNIT_OF_MEASURE_ID
           , nvl(CDA_CONVERSION_FACTOR, 1) CDA_CONVERSION_FACTOR
           , CDA_NUMBER_OF_DECIMAL
        from GCO_COMPL_DATA_STOCK as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion)
       where GCO_COMPL_DATA_STOCK_ID = iDataComplID;

    ltplGetComplDataWithID lcurGetComplDataWithID%rowtype;
    lComplDataStockID      GCO_COMPL_DATA_STOCK.GCO_COMPL_DATA_STOCK_ID%type;
  begin
    -- Utiliser l'ID de la donn�e compl. pass� en param si renseign�
    if nvl(iComplDataID, 0) <> 0 then
      lComplDataStockID  := iComplDataID;
    else
      -- Si en situation de stock propri�taire
      --  Rechercher l'ID de la donn�e de stock propri�taire
      if     (PCS.PC_CONFIG.GetConfig('STM_PROPRIETOR') = 1)
         and (iTransProprietor = 1) then
        -- Situation de stock propri�taire =
        --   Config STM_PROPRIETOR  = 1 ET
        --   DOC_GAUGE_POSITION.GAP_TRANSFERT_PROPRIETOR = 1
        select max(GCO_COMPL_DATA_STOCK_ID)
          into lComplDataStockID
          from GCO_COMPL_DATA_STOCK as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion)
         where GCO_GOOD_ID = iGoodID
           and CST_PROPRIETOR_STOCK = 1;
      else
        lComplDataStockID  := null;
      end if;
    end if;

    -- Pas d'ID de donn�e compl pass� en param
    if nvl(lComplDataStockID, 0) = 0 then
      open lcurGetComplData(iGoodID, oStockID);

      fetch lcurGetComplData
       into ltplGetComplData;

      oStockId             := ltplGetComplData.STM_STOCK_ID;
      oLocationId          := ltplGetComplData.STM_LOCATION_ID;
      oReference           := ltplGetComplData.CDA_COMPLEMENTARY_REFERENCE;
      oSecondaryReference  := ltplGetComplData.CDA_SECONDARY_REFERENCE;
      oShortDescription    := ltplGetComplData.CDA_SHORT_DESCRIPTION;
      oLongDescription     := ltplGetComplData.CDA_LONG_DESCRIPTION;
      oFreeDescription     := ltplGetComplData.CDA_FREE_DESCRIPTION;
      oEanCode             := ltplGetComplData.CDA_COMPLEMENTARY_EAN_CODE;
      oEanUCC14Code        := ltplGetComplData.CDA_COMPLEMENTARY_UCC14_CODE;
      oDicUnitOfMeasure    := ltplGetComplData.DIC_UNIT_OF_MEASURE_ID;
      oConvertFactor       := ltplGetComplData.CDA_CONVERSION_FACTOR;
      oNumberOfDecimal     := ltplGetComplData.CDA_NUMBER_OF_DECIMAL;
      oQuantity            := null;   -- Pour le moment aucune qt� en retour

      close lcurGetComplData;
    -- L'ID de donn�e compl a �t� pass� en param
    else
      open lcurGetComplDataWithID(lComplDataStockID);

      fetch lcurGetComplDataWithID
       into ltplGetComplDataWithID;

      oStockId             := ltplGetComplDataWithID.STM_STOCK_ID;
      oLocationId          := ltplGetComplDataWithID.STM_LOCATION_ID;
      oReference           := ltplGetComplDataWithID.CDA_COMPLEMENTARY_REFERENCE;
      oSecondaryReference  := ltplGetComplDataWithID.CDA_SECONDARY_REFERENCE;
      oShortDescription    := ltplGetComplDataWithID.CDA_SHORT_DESCRIPTION;
      oLongDescription     := ltplGetComplDataWithID.CDA_LONG_DESCRIPTION;
      oFreeDescription     := ltplGetComplDataWithID.CDA_FREE_DESCRIPTION;
      oEanCode             := ltplGetComplDataWithID.CDA_COMPLEMENTARY_EAN_CODE;
      oEanUCC14Code        := ltplGetComplDataWithID.CDA_COMPLEMENTARY_UCC14_CODE;
      oDicUnitOfMeasure    := ltplGetComplDataWithID.DIC_UNIT_OF_MEASURE_ID;
      oConvertFactor       := ltplGetComplDataWithID.CDA_CONVERSION_FACTOR;
      oNumberOfDecimal     := ltplGetComplDataWithID.CDA_NUMBER_OF_DECIMAL;
      oQuantity            := null;   -- Pour le moment aucune qt� en retour

      close lcurGetComplDataWithID;
    end if;
  end GetComplDataStock;

  /**
  * Description
  *   Recherche les informations sur les donn�es compl. de distribution
  */
  procedure GetOneComplDataDistrib(
    iGoodID              in     GCO_GOOD.GCO_GOOD_ID%type
  , iDistributionUnit    in     STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type
  , iDicDistribComplData in     GCO_COMPL_DATA_DISTRIB.DIC_DISTRIB_COMPL_DATA_ID%type
  , iResult              out    number
  , oDicUnitOfMeasure    out    GCO_GOOD.DIC_UNIT_OF_MEASURE_ID%type
  , oConvertFactor       out    GCO_COMPL_DATA_DISTRIB.CDA_CONVERSION_FACTOR%type
  , oNumberOfDecimal     out    GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type
  , oStockMin            out    GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MIN%type
  , oStockMax            out    GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MAX%type
  , oEconQuantity        out    GCO_COMPL_DATA_DISTRIB.CDI_ECONOMICAL_QUANTITY%type
  , oCDDBlockedFrom      out    GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_FROM%type
  , oCDDBlockedTo        out    GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_TO%type
  , oCoverPerCent        out    GCO_COMPL_DATA_DISTRIB.CDI_COVER_PERCENT%type
  , oUseCoverPercent     out    GCO_COMPL_DATA_DISTRIB.C_DRP_USE_COVER_PERCENT%type
  , oPriority            out    GCO_COMPL_DATA_DISTRIB.CDI_PRIORITY_CODE%type
  , oQuantityRule        out    GCO_COMPL_DATA_DISTRIB.C_DRP_QTY_RULE%type
  , oDocMode             out    GCO_COMPL_DATA_DISTRIB.C_DRP_DOC_MODE%type
  , oReliquat            out    GCO_COMPL_DATA_DISTRIB.C_DRP_RELIQUAT%type
  , iVersion             in     varchar2 default null
  )
  is
    -- Variables locales
    lGoodPresent      boolean;
    lPrgGrpPresent    boolean;
    lResult           integer;

    -- Recherche des donn�es compl de distribution du bien
    cursor lcurGetCDDGood(
      iGoodId                GCO_GOOD.GCO_GOOD_ID%type
    , iStmDiuId              STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type
    , iDicDistribComplDataId GCO_COMPL_DATA_DISTRIB.DIC_DISTRIB_COMPL_DATA_ID%type
    )
    is
      select C_DRP_QTY_RULE
           , C_DRP_DOC_MODE
           , C_DRP_RELIQUAT
           , C_DRP_USE_COVER_PERCENT
           , CDI_COVER_PERCENT
           , CDI_PRIORITY_CODE
           , CDI_STOCK_MIN
           , CDI_STOCK_MAX
           , CDI_ECONOMICAL_QUANTITY
           , CDI_BLOCKED_FROM
           , CDI_BLOCKED_TO
           , CDD.DIC_UNIT_OF_MEASURE_ID
           , GOO.DIC_UNIT_OF_MEASURE_ID DIC_UNIT_OF_MEASURE_ID_G
           , nvl(CDA_CONVERSION_FACTOR, 1) CDA_CONVERSION_FACTOR
           , CDA_NUMBER_OF_DECIMAL
           , GOO_NUMBER_OF_DECIMAL
        from GCO_COMPL_DATA_DISTRIB as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion) CDD
           , GCO_GOOD as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion) GOO
       where CDD.GCO_GOOD_ID = iGoodId
         and GOO.GCO_GOOD_ID = iGoodId
         and CDD.GCO_PRODUCT_GROUP_ID is null
         and nvl(cdd.STM_DISTRIBUTION_UNIT_ID, 0) = nvl(iStmDiuId, 0)
         and nvl(cdd.DIC_DISTRIB_COMPL_DATA_ID, 0) = nvl(iDicDistribComplDataId, 0);

    ltplGetCDDGood    lcurGetCDDGood%rowtype;

    -- Recherche des donn�es compl de distribution du groupe de produit
    cursor lcurGetCDDProdGrp(
      iGoodId                GCO_GOOD.GCO_GOOD_ID%type
    , iStmDiuId              STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type
    , iDicDistribComplDataId GCO_COMPL_DATA_DISTRIB.DIC_DISTRIB_COMPL_DATA_ID%type
    )
    is
      select decode(C_DRP_QTY_RULE, '0', '1', C_DRP_QTY_RULE) C_DRP_QTY_RULE
           , decode(C_DRP_DOC_MODE, '0', '1', C_DRP_DOC_MODE) C_DRP_DOC_MODE
           , decode(C_DRP_RELIQUAT, '0', '1', C_DRP_RELIQUAT) C_DRP_RELIQUAT
           , decode(C_DRP_USE_COVER_PERCENT, '0', '1', C_DRP_USE_COVER_PERCENT) C_DRP_USE_COVER_PERCENT
           , CDI_COVER_PERCENT
           , CDI_PRIORITY_CODE
           , CDI_STOCK_MIN
           , CDI_STOCK_MAX
           , CDI_ECONOMICAL_QUANTITY
           , trunc(CDI_BLOCKED_FROM) CDI_BLOCKED_FROM
           , trunc(CDI_BLOCKED_TO) CDI_BLOCKED_TO
           , GOO.DIC_UNIT_OF_MEASURE_ID
           , GOO_NUMBER_OF_DECIMAL
           , nvl(CDA_CONVERSION_FACTOR, 1) CDA_CONVERSION_FACTOR
        from GCO_COMPL_DATA_DISTRIB as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion) CDD
           , GCO_GOOD as of scn GCO_I_LIB_FUNCTIONS.GetVersionLastScn(iGoodID, iVersion) GOO
       where GOO.GCO_GOOD_ID = iGoodId
         and CDD.GCO_GOOD_ID is null
         and CDD.GCO_PRODUCT_GROUP_ID = GOO.GCO_PRODUCT_GROUP_ID
         and nvl(cdd.STM_DISTRIBUTION_UNIT_ID, 0) = nvl(iStmDiuId, 0)
         and nvl(cdd.DIC_DISTRIB_COMPL_DATA_ID, 0) = nvl(iDicDistribComplDataId, 0);

    ltplGetCDDProdGrp lcurGetCDDProdGrp%rowtype;
  begin
    -- Lires les donn�es compl de distrib du bien
    open lcurGetCDDGood(iGoodID, iDistributionUnit, iDicDistribComplData);

    fetch lcurGetCDDGood
     into ltplGetCDDGood;

    lGoodPresent    := lcurGetCDDGood%found;

    -- Lires les donn�es compl de distrib du groupe de produit
    open lcurGetCDDProdGrp(iGoodID, iDistributionUnit, iDicDistribComplData);

    fetch lcurGetCDDProdGrp
     into ltplGetCDDProdGrp;

    lPrgGrpPresent  := lcurGetCDDProdGrp%found;

    if lGoodPresent then
      -- su un des C_DRP codes pointe sur le groupe de produit et que celui-ci n'existe pas alors
      -- le produit n'est pas pris en compte
      if     not lPrgGrpPresent
         and (    (ltplGetCDDGood.C_DRP_USE_COVER_PERCENT = '0')
              or (ltplGetCDDGood.C_DRP_QTY_RULE = '0')
              or (ltplGetCDDGood.C_DRP_DOC_MODE = '0')
              or (ltplGetCDDGood.C_DRP_RELIQUAT = '0')
             ) then
        oUseCoverPercent  := ltplGetCDDGood.C_DRP_USE_COVER_PERCENT;
        oQuantityRule     := ltplGetCDDGood.C_DRP_QTY_RULE;
        oDocMode          := ltplGetCDDGood.C_DRP_DOC_MODE;
        oReliquat         := ltplGetCDDGood.C_DRP_RELIQUAT;

        close lcurGetCDDGood;

        close lcurGetCDDProdGrp;

        iResult           := -1;
        return;
      else
        -- prendre les valeurs d�finies dans les donn�es compl de distrib du bien, si null prendre celles
        -- du groupe de produit
        oDicUnitOfMeasure  := nvl(ltplGetCDDGood.DIC_UNIT_OF_MEASURE_ID, ltplGetCDDGood.DIC_UNIT_OF_MEASURE_ID_G);
        oConvertFactor     := nvl(ltplGetCDDGood.CDA_CONVERSION_FACTOR, 1);
        oNumberOfDecimal   := nvl(ltplGetCDDGood.CDA_NUMBER_OF_DECIMAL, ltplGetCDDGood.GOO_NUMBER_OF_DECIMAL);
        oStockMin          := nvl(ltplGetCDDGood.CDI_STOCK_MIN, ltplGetCDDProdGrp.CDI_STOCK_MIN);
        oStockMax          := nvl(ltplGetCDDGood.CDI_STOCK_MAX, ltplGetCDDProdGrp.CDI_STOCK_MAX);
        oEconQuantity      := nvl(ltplGetCDDGood.CDI_ECONOMICAL_QUANTITY, ltplGetCDDProdGrp.CDI_ECONOMICAL_QUANTITY);
        oCDDBlockedFrom    := nvl(ltplGetCDDGood.CDI_BLOCKED_FROM, ltplGetCDDProdGrp.CDI_BLOCKED_FROM);
        oCDDBlockedTo      := nvl(ltplGetCDDGood.CDI_BLOCKED_TO, ltplGetCDDProdGrp.CDI_BLOCKED_TO);
        oCoverPerCent      := nvl(ltplGetCDDGood.CDI_COVER_PERCENT, ltplGetCDDProdGrp.CDI_COVER_PERCENT);

        if ltplGetCDDGood.C_DRP_USE_COVER_PERCENT = '0' then
          oUseCoverPercent  := ltplGetCDDProdGrp.C_DRP_USE_COVER_PERCENT;
        else
          oUseCoverPercent  := ltplGetCDDGood.C_DRP_USE_COVER_PERCENT;
        end if;

        oPriority          := nvl(ltplGetCDDGood.CDI_PRIORITY_CODE, ltplGetCDDProdGrp.CDI_PRIORITY_CODE);

        if ltplGetCDDGood.C_DRP_QTY_RULE = '0' then
          oQuantityRule  := ltplGetCDDProdGrp.C_DRP_QTY_RULE;
        else
          oQuantityRule  := ltplGetCDDGood.C_DRP_QTY_RULE;
        end if;

        if ltplGetCDDGood.C_DRP_DOC_MODE = '0' then
          oDocMode  := ltplGetCDDProdGrp.C_DRP_DOC_MODE;
        else
          oDocMode  := ltplGetCDDGood.C_DRP_DOC_MODE;
        end if;

        if ltplGetCDDGood.C_DRP_RELIQUAT = '0' then
          oReliquat  := ltplGetCDDProdGrp.C_DRP_RELIQUAT;
        else
          oReliquat  := ltplGetCDDGood.C_DRP_RELIQUAT;
        end if;

        close lcurGetCDDGood;

        close lcurGetCDDProdGrp;

        iResult            := 1;   -- OK, donn�es du CDD Produit
        return;
      end if;
    elsif lPrgGrpPresent then
      -- les donn�es compl de distribution du bien ne sont pas pr�sentes, prendre celles du groupe de produit
      oDicUnitOfMeasure  := ltplGetCDDProdGrp.DIC_UNIT_OF_MEASURE_ID;
      oConvertFactor     := nvl(ltplGetCDDProdGrp.CDA_CONVERSION_FACTOR, 1);
      oNumberOfDecimal   := ltplGetCDDProdGrp.GOO_NUMBER_OF_DECIMAL;
      oStockMin          := ltplGetCDDProdGrp.CDI_STOCK_MIN;
      oStockMax          := ltplGetCDDProdGrp.CDI_STOCK_MAX;
      oEconQuantity      := ltplGetCDDProdGrp.CDI_ECONOMICAL_QUANTITY;
      oCDDBlockedFrom    := ltplGetCDDProdGrp.CDI_BLOCKED_FROM;
      oCDDBlockedTo      := ltplGetCDDProdGrp.CDI_BLOCKED_TO;
      oCoverPerCent      := ltplGetCDDProdGrp.CDI_COVER_PERCENT;
      oUseCoverPercent   := ltplGetCDDProdGrp.C_DRP_USE_COVER_PERCENT;
      oPriority          := ltplGetCDDProdGrp.CDI_PRIORITY_CODE;
      oQuantityRule      := ltplGetCDDProdGrp.C_DRP_QTY_RULE;
      oDocMode           := ltplGetCDDProdGrp.C_DRP_DOC_MODE;
      oReliquat          := ltplGetCDDProdGrp.C_DRP_RELIQUAT;

      close lcurGetCDDGood;

      close lcurGetCDDProdGrp;

      iResult            := 2;   -- OK, donn�es du CDD Groupe de produits
      return;
    else
      close lcurGetCDDGood;

      close lcurGetCDDProdGrp;

      iResult  := 0;
      return;
    end if;
  end GetOneComplDataDistrib;

  procedure GetComplDataDistrib(
    iGoodID              in     GCO_GOOD.GCO_GOOD_ID%type
  , iDistributionUnit    in     STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type
  , iDicDistribComplData in     GCO_COMPL_DATA_DISTRIB.DIC_DISTRIB_COMPL_DATA_ID%type
  , iResult              out    number
  , oDicUnitOfMeasure    out    GCO_GOOD.DIC_UNIT_OF_MEASURE_ID%type
  , oConvertFactor       out    GCO_COMPL_DATA_DISTRIB.CDA_CONVERSION_FACTOR%type
  , oNumberOfDecimal     out    GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type
  , oStockMin            out    GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MIN%type
  , oStockMax            out    GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MAX%type
  , oEconQuantity        out    GCO_COMPL_DATA_DISTRIB.CDI_ECONOMICAL_QUANTITY%type
  , oCDDBlockedFrom      out    GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_FROM%type
  , oCDDBlockedTo        out    GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_TO%type
  , oCoverPerCent        out    GCO_COMPL_DATA_DISTRIB.CDI_COVER_PERCENT%type
  , oUseCoverPercent     out    GCO_COMPL_DATA_DISTRIB.C_DRP_USE_COVER_PERCENT%type
  , oPriority            out    GCO_COMPL_DATA_DISTRIB.CDI_PRIORITY_CODE%type
  , oQuantityRule        out    GCO_COMPL_DATA_DISTRIB.C_DRP_QTY_RULE%type
  , oDocMode             out    GCO_COMPL_DATA_DISTRIB.C_DRP_DOC_MODE%type
  , oReliquat            out    GCO_COMPL_DATA_DISTRIB.C_DRP_RELIQUAT%type
  , iVersion             in     varchar2 default null
  )
  is
    -- Variables locales
    lComplDataFound   boolean;
    lResult           integer;
    lDicUnitOfMeasure GCO_GOOD.DIC_UNIT_OF_MEASURE_ID%type;
    lConvertFactor    GCO_COMPL_DATA_DISTRIB.CDA_CONVERSION_FACTOR%type;
    lNumberOfDecimal  GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
    lStockMin         GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MIN%type;
    lStockMax         GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MAX%type;
    lEconQuantity     GCO_COMPL_DATA_DISTRIB.CDI_ECONOMICAL_QUANTITY%type;
    lCDDBlockedFrom   GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_FROM%type;
    lCDDBlockedTo     STM_DISTRIBUTION_UNIT.DIU_BLOCKED_TO%type;
    lCoverPerCent     GCO_COMPL_DATA_DISTRIB.CDI_COVER_PERCENT%type;
    lUseCoverPercent  GCO_COMPL_DATA_DISTRIB.C_DRP_USE_COVER_PERCENT%type;
    lPriority         GCO_COMPL_DATA_DISTRIB.CDI_PRIORITY_CODE%type;
    lQuantityRule     GCO_COMPL_DATA_DISTRIB.C_DRP_QTY_RULE%type;
    lDocMode          GCO_COMPL_DATA_DISTRIB.C_DRP_DOC_MODE%type;
    lReliquat         GCO_COMPL_DATA_DISTRIB.C_DRP_RELIQUAT%type;
  begin
    lComplDataFound  := false;
    lResult          := 0;

    if iDistributionUnit is not null then
      GetOneComplDataDistrib(iGoodID
                           , iDistributionUnit
                           , null
                           , lResult
                           , lDicUnitOfMeasure
                           , lConvertFactor
                           , lNumberOfDecimal
                           , lStockMin
                           , lStockMax
                           , lEconQuantity
                           , lCDDBlockedFrom
                           , lCDDBlockedTo
                           , lCoverPerCent
                           , lUseCoverPercent
                           , lPriority
                           , lQuantityRule
                           , lDocMode
                           , lReliquat
                           , iVersion
                            );
      lComplDataFound  := lResult > 0;
      iResult          := lResult;
    end if;

    if     not lComplDataFound
       and iDicDistribComplData is not null then
      GetOneComplDataDistrib(iGoodID
                           , null
                           , iDicDistribComplData
                           , lResult
                           , lDicUnitOfMeasure
                           , lConvertFactor
                           , lNumberOfDecimal
                           , lStockMin
                           , lStockMax
                           , lEconQuantity
                           , lCDDBlockedFrom
                           , lCDDBlockedTo
                           , lCoverPerCent
                           , lUseCoverPercent
                           , lPriority
                           , lQuantityRule
                           , lDocMode
                           , lReliquat
                           , iVersion
                            );
      lComplDataFound  := lResult > 0;

      if lResult > 0 then
        iResult  := lResult + 2;
      else
        iResult  := lResult;
      end if;
    end if;

    if lComplDataFound then
      oDicUnitOfMeasure  := lDicUnitOfMeasure;
      oConvertFactor     := lConvertFactor;
      oNumberOfDecimal   := lNumberOfDecimal;
      oStockMin          := lStockMin;
      oStockMax          := lStockMax;
      oEconQuantity      := lEconQuantity;
      oCDDBlockedFrom    := lCDDBlockedFrom;
      oCDDBlockedTo      := lCDDBlockedTo;
      oCoverPerCent      := lCoverPerCent;
      oUseCoverPercent   := lUseCoverPercent;
      oPriority          := lPriority;
      oQuantityRule      := lQuantityRule;
      oDocMode           := lDocMode;
      oReliquat          := lReliquat;
    else
      oDicUnitOfMeasure  := null;
      oConvertFactor     := null;
      oNumberOfDecimal   := null;
      oStockMin          := null;
      oStockMax          := null;
      oEconQuantity      := null;
      oCDDBlockedFrom    := null;
      oCDDBlockedTo      := null;
      oCoverPerCent      := null;
      oUseCoverPercent   := null;
      oPriority          := null;
      oQuantityRule      := null;
      oDocMode           := null;
      oReliquat          := null;
    end if;
  end GetComplDataDistrib;

  /**
  * Description
  *       Recherche du nombre de d�cimal des donn�es compl�mentaires
  */
  procedure GetCDANumberOfDecimal(iGoodId in number, iType in varchar2, iThirdId in number, iLangId in number, oNumberOfDecimal out number)
  is
    cursor lcurComplDataPurchase(iGoodId number, iThirdId number)
    is
      select   rpad(decode(PAC_SUPPLIER_PARTNER_ID, null, '1            ', '0' || to_char(PAC_SUPPLIER_PARTNER_ID) ), 13, ' ') order1
             , '1          ' order2
             , CDA_NUMBER_OF_DECIMAL
             , CPU_DEFAULT_SUPPLIER
          from GCO_COMPL_DATA_PURCHASE A
         where GCO_GOOD_ID = iGoodId
           and DIC_COMPLEMENTARY_DATA_ID is null
           and (   PAC_SUPPLIER_PARTNER_ID = iThirdId
                or PAC_SUPPLIER_PARTNER_ID is null)
      union
      select   '1            ' order1
             , decode(A.DIC_COMPLEMENTARY_DATA_ID, null, '1          ', '0' || rpad(A.DIC_COMPLEMENTARY_DATA_ID, 10) ) order2
             , CDA_NUMBER_OF_DECIMAL
             , CPU_DEFAULT_SUPPLIER
          from GCO_COMPL_DATA_PURCHASE A
             , PAC_SUPPLIER_PARTNER B
         where GCO_GOOD_ID = iGoodId
           and A.PAC_SUPPLIER_PARTNER_ID is null
           and A.DIC_COMPLEMENTARY_DATA_ID = B.DIC_COMPLEMENTARY_DATA_ID
           and B.PAC_SUPPLIER_PARTNER_ID = iThirdId
      order by 1
             , 2
             , 4 desc;

    ltplComplDataPurchase lcurComplDataPurchase%rowtype;

    cursor lcurComplDataSale(iGoodId number, iThirdId number)
    is
      select   rpad(decode(PAC_CUSTOM_PARTNER_ID, null, '1            ', '0' || to_char(PAC_CUSTOM_PARTNER_ID, '000000000000') ), 13, ' ') order1
             , '1          ' order2
             , CDA_NUMBER_OF_DECIMAL
          from GCO_COMPL_DATA_SALE
         where GCO_GOOD_ID = iGoodId
           and DIC_COMPLEMENTARY_DATA_ID is null
           and (   PAC_CUSTOM_PARTNER_ID = iThirdId
                or PAC_CUSTOM_PARTNER_ID is null)
      union
      select   '1            ' order1
             , decode(A.DIC_COMPLEMENTARY_DATA_ID, null, '1          ', '0' || rpad(A.DIC_COMPLEMENTARY_DATA_ID, 10) ) order2
             , CDA_NUMBER_OF_DECIMAL
          from GCO_COMPL_DATA_SALE A
             , PAC_CUSTOM_PARTNER B
         where GCO_GOOD_ID = iGoodId
           and A.PAC_CUSTOM_PARTNER_ID is null
           and A.DIC_COMPLEMENTARY_DATA_ID = B.DIC_COMPLEMENTARY_DATA_ID
           and B.PAC_CUSTOM_PARTNER_ID = iThirdId
      order by 1
             , 2;

    ltplComplDataSale     lcurComplDataSale%rowtype;

    cursor lcurGood(iGoodId number, LangId number)
    is
      select GOO_NUMBER_OF_DECIMAL
        from GCO_GOOD GOO
           , GCO_DESCRIPTION DES
           , GCO_PRODUCT PDT
       where GOO.GCO_GOOD_ID = iGoodId
         and PDT.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
         and DES.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
         and DES.C_DESCRIPTION_TYPE(+) = '01'
         and DES.PC_LANG_ID(+) = LangId;

    ltplGood              lcurGood%rowtype;
    lbFound               boolean                         default false;
  begin
    -- donn�es compl�mentaires de vente
    if iType = 'SALE' then
      open lcurComplDataSale(iGoodId, iThirdId);

      fetch lcurComplDataSale
       into ltplComplDataSale;

      if lcurComplDataSale%found then
        lbFound           := true;
        oNumberOfDecimal  := ltplComplDataSale.CDA_NUMBER_OF_DECIMAL;
      end if;

      close lcurComplDataSale;
    -- donn�es compl�mentaires d'achat
    elsif iType = 'PURCHASE' then
      open lcurComplDataPurchase(iGoodId, iThirdId);

      fetch lcurComplDataPurchase
       into ltplComplDataPurchase;

      if lcurComplDataPurchase%found then
        lbFound           := true;
        oNumberOfDecimal  := ltplComplDataPurchase.CDA_NUMBER_OF_DECIMAL;
      end if;

      close lcurComplDataPurchase;
    end if;

    -- si donn�es compl�mentaires non trouv�es
    -- renvoie les donn�es du bien
    if not lbFound then
      open lcurGood(iGoodId, iLangId);

      fetch lcurGood
       into ltplGood;

      oNumberOfDecimal  := ltplGood.GOO_NUMBER_OF_DECIMAL;

      close lcurGood;
    end if;
  end GetCDANumberOfDecimal;

  /**
  * Description
  *       Retourne le nombre de d�cimal des donn�es compl�mentaires et si pas
  *       trouv�, le nombre de d�cimal du bien.
  */
  function GetCDADecimal(iGoodId in GCO_GOOD.GCO_GOOD_ID%type, iType in varchar2, iThirdId in number)
    return number
  is
    cursor lcurComplDataPurchase(iGoodId number, iThirdId number)
    is
      select   rpad(decode(PAC_SUPPLIER_PARTNER_ID, null, '1            ', '0' || to_char(PAC_SUPPLIER_PARTNER_ID) ), 13, ' ') order1
             , '1          ' order2
             , CDA_NUMBER_OF_DECIMAL
             , CPU_DEFAULT_SUPPLIER
          from GCO_COMPL_DATA_PURCHASE A
         where GCO_GOOD_ID = iGoodId
           and DIC_COMPLEMENTARY_DATA_ID is null
           and (   PAC_SUPPLIER_PARTNER_ID = iThirdId
                or PAC_SUPPLIER_PARTNER_ID is null)
      union
      select   '1            ' order1
             , decode(A.DIC_COMPLEMENTARY_DATA_ID, null, '1          ', '0' || rpad(A.DIC_COMPLEMENTARY_DATA_ID, 10) ) order2
             , CDA_NUMBER_OF_DECIMAL
             , CPU_DEFAULT_SUPPLIER
          from GCO_COMPL_DATA_PURCHASE A
             , PAC_SUPPLIER_PARTNER B
         where GCO_GOOD_ID = iGoodId
           and A.PAC_SUPPLIER_PARTNER_ID is null
           and A.DIC_COMPLEMENTARY_DATA_ID = B.DIC_COMPLEMENTARY_DATA_ID
           and B.PAC_SUPPLIER_PARTNER_ID = iThirdId
      order by 1
             , 2
             , 4 desc;

    ltplComplDataPurchase lcurComplDataPurchase%rowtype;

    cursor lcurComplDataSale(iGoodId number, iThirdId number)
    is
      select   rpad(decode(PAC_CUSTOM_PARTNER_ID, null, '1            ', '0' || to_char(PAC_CUSTOM_PARTNER_ID, '000000000000') ), 13, ' ') order1
             , '1          ' order2
             , CDA_NUMBER_OF_DECIMAL
          from GCO_COMPL_DATA_SALE
         where GCO_GOOD_ID = iGoodId
           and DIC_COMPLEMENTARY_DATA_ID is null
           and (   PAC_CUSTOM_PARTNER_ID = iThirdId
                or PAC_CUSTOM_PARTNER_ID is null)
      union
      select   '1            ' order1
             , decode(A.DIC_COMPLEMENTARY_DATA_ID, null, '1          ', '0' || rpad(A.DIC_COMPLEMENTARY_DATA_ID, 10) ) order2
             , CDA_NUMBER_OF_DECIMAL
          from GCO_COMPL_DATA_SALE A
             , PAC_CUSTOM_PARTNER B
         where GCO_GOOD_ID = iGoodId
           and A.PAC_CUSTOM_PARTNER_ID is null
           and A.DIC_COMPLEMENTARY_DATA_ID = B.DIC_COMPLEMENTARY_DATA_ID
           and B.PAC_CUSTOM_PARTNER_ID = iThirdId
      order by 1
             , 2;

    ltplComplDataSale     lcurComplDataSale%rowtype;
    lbFound               boolean                               default false;
    lResult               GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
  begin
    lResult  := 0;

    -- donn�es compl�mentaires de vente
    if iType = 'SALE' then
      open lcurComplDataSale(iGoodId, iThirdId);

      fetch lcurComplDataSale
       into ltplComplDataSale;

      if lcurComplDataSale%found then
        lbFound  := true;
        lResult  := ltplComplDataSale.CDA_NUMBER_OF_DECIMAL;
      end if;

      close lcurComplDataSale;
    -- donn�es compl�mentaires d'achat
    elsif iType = 'PURCHASE' then
      open lcurComplDataPurchase(iGoodId, iThirdId);

      fetch lcurComplDataPurchase
       into ltplComplDataPurchase;

      if lcurComplDataPurchase%found then
        lbFound  := true;
        lResult  := ltplComplDataPurchase.CDA_NUMBER_OF_DECIMAL;
      end if;

      close lcurComplDataPurchase;
    end if;

    -- si donn�es compl�mentaires non trouv�es
    -- renvoie les donn�es du bien
    if not lbFound then
      select GOO_NUMBER_OF_DECIMAL
        into lResult
        from GCO_GOOD
       where GCO_GOOD_ID = iGoodId;
    end if;

    return lResult;
  end GetCDADecimal;

  /**
  * Description
  *       Retourne l'unit� de mesure des donn�es compl�mentaires et si pas
  *       trouv�, l'unit� de mesure du bien (unit� de gestion).
  */
  function GetCDAUnit(iGoodId in GCO_GOOD.GCO_GOOD_ID%type, iType in varchar2, iThirdId in number)
    return varchar2
  is
    cursor lcurComplDataPurchase(iGoodId number, iThirdId number)
    is
      select   rpad(decode(PAC_SUPPLIER_PARTNER_ID, null, '1            ', '0' || to_char(PAC_SUPPLIER_PARTNER_ID) ), 13, ' ') order1
             , '1          ' order2
             , DIC_UNIT_OF_MEASURE_ID
             , CPU_DEFAULT_SUPPLIER
          from GCO_COMPL_DATA_PURCHASE A
         where GCO_GOOD_ID = iGoodId
           and DIC_COMPLEMENTARY_DATA_ID is null
           and (   PAC_SUPPLIER_PARTNER_ID = iThirdId
                or PAC_SUPPLIER_PARTNER_ID is null)
      union
      select   '1            ' order1
             , decode(A.DIC_COMPLEMENTARY_DATA_ID, null, '1          ', '0' || rpad(A.DIC_COMPLEMENTARY_DATA_ID, 10) ) order2
             , DIC_UNIT_OF_MEASURE_ID
             , CPU_DEFAULT_SUPPLIER
          from GCO_COMPL_DATA_PURCHASE A
             , PAC_SUPPLIER_PARTNER B
         where GCO_GOOD_ID = iGoodId
           and A.PAC_SUPPLIER_PARTNER_ID is null
           and A.DIC_COMPLEMENTARY_DATA_ID = B.DIC_COMPLEMENTARY_DATA_ID
           and B.PAC_SUPPLIER_PARTNER_ID = iThirdId
      order by 1
             , 2
             , 4 desc;

    ltplComplDataPurchase lcurComplDataPurchase%rowtype;

    cursor lcurComplDataSale(iGoodId number, iThirdId number)
    is
      select   rpad(decode(PAC_CUSTOM_PARTNER_ID, null, '1            ', '0' || to_char(PAC_CUSTOM_PARTNER_ID, '000000000000') ), 13, ' ') order1
             , '1          ' order2
             , DIC_UNIT_OF_MEASURE_ID
          from GCO_COMPL_DATA_SALE
         where GCO_GOOD_ID = iGoodId
           and DIC_COMPLEMENTARY_DATA_ID is null
           and (   PAC_CUSTOM_PARTNER_ID = iThirdId
                or PAC_CUSTOM_PARTNER_ID is null)
      union
      select   '1            ' order1
             , decode(A.DIC_COMPLEMENTARY_DATA_ID, null, '1          ', '0' || rpad(A.DIC_COMPLEMENTARY_DATA_ID, 10) ) order2
             , DIC_UNIT_OF_MEASURE_ID
          from GCO_COMPL_DATA_SALE A
             , PAC_CUSTOM_PARTNER B
         where GCO_GOOD_ID = iGoodId
           and A.PAC_CUSTOM_PARTNER_ID is null
           and A.DIC_COMPLEMENTARY_DATA_ID = B.DIC_COMPLEMENTARY_DATA_ID
           and B.PAC_CUSTOM_PARTNER_ID = iThirdId
      order by 1
             , 2;

    ltplComplDataSale     lcurComplDataSale%rowtype;
    lbFound               boolean                                default false;
    lResult               GCO_GOOD.DIC_UNIT_OF_MEASURE_ID%type;
  begin
    lResult  := 0;

    -- donn�es compl�mentaires de vente
    if iType = 'SALE' then
      open lcurComplDataSale(iGoodId, iThirdId);

      fetch lcurComplDataSale
       into ltplComplDataSale;

      if lcurComplDataSale%found then
        lbFound  := true;
        lResult  := ltplComplDataSale.DIC_UNIT_OF_MEASURE_ID;
      end if;

      close lcurComplDataSale;
    -- donn�es compl�mentaires d'achat
    elsif iType = 'PURCHASE' then
      open lcurComplDataPurchase(iGoodId, iThirdId);

      fetch lcurComplDataPurchase
       into ltplComplDataPurchase;

      if lcurComplDataPurchase%found then
        lbFound  := true;
        lResult  := ltplComplDataPurchase.DIC_UNIT_OF_MEASURE_ID;
      end if;

      close lcurComplDataPurchase;
    end if;

    -- si donn�es compl�mentaires non trouv�es
    -- renvoie les donn�es du bien
    if not lbFound then
      select DIC_UNIT_OF_MEASURE_ID
        into lResult
        from GCO_GOOD
       where GCO_GOOD_ID = iGoodId;
    end if;

    return lResult;
  end GetCDAUnit;

  /**
  * Description
  *       Recherche les donn�es compl�menaires en relation quantit� de stockage
  */
  procedure GetCDAStock(
    iGoodId           in     GCO_GOOD.GCO_GOOD_ID%type
  , iType             in     varchar2
  , iThirdId          in     number
  , ioConvertFactor   in out GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type
  , ioNumberOfDecimal in out GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type
  , ioUnitOfMeasure   in out GCO_GOOD.DIC_UNIT_OF_MEASURE_ID%type
  )
  is
    cursor lcurComplDataPurchase(iGoodId number, iThirdId number)
    is
      select   rpad(decode(PAC_SUPPLIER_PARTNER_ID, null, '1            ', '0' || to_char(PAC_SUPPLIER_PARTNER_ID) ), 13, ' ') order1
             , '1          ' order2
             , CDA_CONVERSION_FACTOR
             , CDA_NUMBER_OF_DECIMAL
             , DIC_UNIT_OF_MEASURE_ID
             , CPU_DEFAULT_SUPPLIER
          from GCO_COMPL_DATA_PURCHASE A
         where GCO_GOOD_ID = iGoodId
           and DIC_COMPLEMENTARY_DATA_ID is null
           and (   PAC_SUPPLIER_PARTNER_ID = iThirdId
                or PAC_SUPPLIER_PARTNER_ID is null)
      union
      select   '1            ' order1
             , decode(A.DIC_COMPLEMENTARY_DATA_ID, null, '1          ', '0' || rpad(A.DIC_COMPLEMENTARY_DATA_ID, 10) ) order2
             , CDA_CONVERSION_FACTOR
             , CDA_NUMBER_OF_DECIMAL
             , DIC_UNIT_OF_MEASURE_ID
             , CPU_DEFAULT_SUPPLIER
          from GCO_COMPL_DATA_PURCHASE A
             , PAC_SUPPLIER_PARTNER B
         where GCO_GOOD_ID = iGoodId
           and A.PAC_SUPPLIER_PARTNER_ID is null
           and A.DIC_COMPLEMENTARY_DATA_ID = B.DIC_COMPLEMENTARY_DATA_ID
           and B.PAC_SUPPLIER_PARTNER_ID = iThirdId
      order by 1
             , 2
             , 6 desc;

    ltplComplDataPurchase lcurComplDataPurchase%rowtype;

    cursor lcurComplDataSale(iGoodId number, iThirdId number)
    is
      select   rpad(decode(PAC_CUSTOM_PARTNER_ID, null, '1            ', '0' || to_char(PAC_CUSTOM_PARTNER_ID, '000000000000') ), 13, ' ') order1
             , '1          ' order2
             , CDA_CONVERSION_FACTOR
             , CDA_NUMBER_OF_DECIMAL
             , DIC_UNIT_OF_MEASURE_ID
          from GCO_COMPL_DATA_SALE
         where GCO_GOOD_ID = iGoodId
           and DIC_COMPLEMENTARY_DATA_ID is null
           and (   PAC_CUSTOM_PARTNER_ID = iThirdId
                or PAC_CUSTOM_PARTNER_ID is null)
      union
      select   '1            ' order1
             , decode(A.DIC_COMPLEMENTARY_DATA_ID, null, '1          ', '0' || rpad(A.DIC_COMPLEMENTARY_DATA_ID, 10) ) order2
             , CDA_CONVERSION_FACTOR
             , CDA_NUMBER_OF_DECIMAL
             , DIC_UNIT_OF_MEASURE_ID
          from GCO_COMPL_DATA_SALE A
             , PAC_CUSTOM_PARTNER B
         where GCO_GOOD_ID = iGoodId
           and A.PAC_CUSTOM_PARTNER_ID is null
           and A.DIC_COMPLEMENTARY_DATA_ID = B.DIC_COMPLEMENTARY_DATA_ID
           and B.PAC_CUSTOM_PARTNER_ID = iThirdId
      order by 1
             , 2;

    ltplComplDataSale     lcurComplDataSale%rowtype;
    lbFound               boolean                         default false;
  begin
    -- donn�es compl�mentaires de vente
    if iType = 'SALE' then
      open lcurComplDataSale(iGoodId, iThirdId);

      fetch lcurComplDataSale
       into ltplComplDataSale;

      if lcurComplDataSale%found then
        lbFound            := true;
        ioConvertFactor    := ltplComplDataSale.CDA_CONVERSION_FACTOR;
        ioNumberOfDecimal  := ltplComplDataSale.CDA_NUMBER_OF_DECIMAL;
        ioUnitOfMeasure    := ltplComplDataSale.DIC_UNIT_OF_MEASURE_ID;
      end if;

      close lcurComplDataSale;
    -- donn�es compl�mentaires d'achat
    elsif iType = 'PURCHASE' then
      open lcurComplDataPurchase(iGoodId, iThirdId);

      fetch lcurComplDataPurchase
       into ltplComplDataPurchase;

      if lcurComplDataPurchase%found then
        lbFound            := true;
        ioConvertFactor    := ltplComplDataPurchase.CDA_CONVERSION_FACTOR;
        ioNumberOfDecimal  := ltplComplDataPurchase.CDA_NUMBER_OF_DECIMAL;
        ioUnitOfMeasure    := ltplComplDataPurchase.DIC_UNIT_OF_MEASURE_ID;
      end if;

      close lcurComplDataPurchase;
    end if;

    -- si donn�es compl�mentaires non trouv�es
    -- renvoie les donn�es du bien
    if not lbFound then
      select 1
           , GOO_NUMBER_OF_DECIMAL
           , DIC_UNIT_OF_MEASURE_ID
        into ioConvertFactor
           , ioNumberOfDecimal
           , ioUnitOfMeasure
        from GCO_GOOD
       where GCO_GOOD_ID = iGoodId;
    end if;
  end GetCDAStock;

  /**
  * Function GetConvertFactor
  * Description
  *        Retourne la valeur du facteur de conversion pour un domaine, pour un bien et un tiers donn�
  */
  function GetConvertFactor(iGoodId in number, iThirdId in number, iAdminDomain in varchar2)
    return number
  is
    lCdiConvertFactor   GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type;
    lCdiNumberOfDecimal GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
    lCdaUnitOfMeasure   GCO_GOOD.DIC_UNIT_OF_MEASURE_ID%type;
  begin
    if iAdminDomain = '2' then
      GetCDAStock(iGoodId, 'SALE', iThirdId, lCdiConvertFactor, lCdiNumberOfDecimal, lCdaUnitOfMeasure);
    elsif iAdminDomain in('1', '5') then
      GetCDAStock(iGoodId, 'PURCHASE', iThirdId, lCdiConvertFactor, lCdiNumberOfDecimal, lCdaUnitOfMeasure);
    else
      lCdiConvertFactor  := 1;
    end if;

    return lCdiConvertFactor;
  end GetConvertFactor;

  /**
  * Function GetThirdConvertFactor
  * Description
  *        Retourne la valeur du facteur de conversion calcul� pour un bien, un tiers initial et un document
  *        cible donn�. La valeur nulle est retourn�e s'il n'y a pas de changement de partenaire ou que
  *        c'est une position kit ou assemblage.
  */
  function GetThirdConvertFactor(
    iGoodID           in number
  , iSourceThirdID    in number
  , iTypePos          in varchar2
  , iTargetDocumentID in number default null
  , iTargetThirdID    in number default null
  , iAdminDomain      in varchar2 default null
  )
    return number
  is
    lTargetThirdID           PAC_THIRD.PAC_THIRD_ID%type;
    lAdminDomain             DOC_GAUGE.C_ADMIN_DOMAIN%type;
    lTargetConvertFactorCalc GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type;
  begin
    if iGoodID is not null then
      -- Recherche les �ventuelles donn�es du document cible si elles ne sont pas sp�cifi�es en param�tre.
      if     iTargetDocumentID is not null
         and (   iTargetThirdID is null
              or iAdminDomain is null) then
        select nvl(iTargetThirdID, DMT.PAC_THIRD_ID)
             , nvl(iAdminDomain, GAU.C_ADMIN_DOMAIN)
          into lTargetThirdID
             , lAdminDomain
          from DOC_DOCUMENT DMT
             , DOC_GAUGE GAU
         where DMT.DOC_DOCUMENT_ID = iTargetDocumentID
           and GAU.DOC_GAUGE_ID(+) = DMT.DOC_GAUGE_ID;
      else
        lTargetThirdID  := iTargetThirdID;
        lAdminDomain    := iAdminDomain;
      end if;

      -- Traitement du changement de partenaire. Si le patenaire source est diff�rent du partenaire cible,
      -- Il faut rechercher le facteur de conversion calcul� sur la donn�e compl�mentaire du tiers cible.
      lTargetConvertFactorCalc  := null;

      if     lTargetThirdID is not null
         and iSourceThirdID is not null
         and lTargetThirdID <> iSourceThirdID
         and not(iTypePos in('7', '8', '9', '10') ) then
        lTargetConvertFactorCalc  := GetConvertFactor(iGoodID, lTargetThirdID, lAdminDomain);
      end if;
    end if;

    return lTargetConvertFactorCalc;
  end GetThirdConvertFactor;
end GCO_LIB_COMPL_DATA;
