--------------------------------------------------------
--  DDL for Package Body SHP_LIB_STOCK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SHP_LIB_STOCK" 
as
  /**
  * function
  * Description
  *   Cette fonction retourne sous forme binaire le noeud XML "product" contenant
  *   les informations relatives à une catégorie.
  */
  function getStockXmlType(
    iGoodID                       in GCO_GOOD.GCO_GOOD_ID%type
  , ivDicTariffPrice              in DIC_TARIFF.DIC_TARIFF_ID%type
  , ivDicTariffListPrice          in DIC_TARIFF.DIC_TARIFF_ID%type
  , ivDataSource4Quantity         in varchar2
  , inDiscountsAndChargesIncluded in number
  )
    return xmltype
  is
    lxXmlData xmltype;
  begin
    select XMLElement("product"
                    , XMLElement("product_id", GCO_GOOD_ID)
                    , XMLElement("list_price"
                               , SHP_LIB_STOCK.getPrice(iGoodID                         => GCO_GOOD_ID
                                                      , iCurrencyId                     => PTC_I_LIB_PRICE.getCurrIdFromDicTariff(ivDicTariffListPrice)
                                                      , ivDicTariffID                   => ivDicTariffListPrice
                                                      , inDiscountsAndChargesIncluded   => inDiscountsAndChargesIncluded
                                                       )
                                )
                    , XMLElement("price"
                               , SHP_LIB_STOCK.getPrice(iGoodID                         => GCO_GOOD_ID
                                                      , iCurrencyId                     => PTC_I_LIB_PRICE.getCurrIdFromDicTariff(ivDicTariffPrice)
                                                      , ivDicTariffID                   => ivDicTariffPrice
                                                      , inDiscountsAndChargesIncluded   => inDiscountsAndChargesIncluded
                                                       )
                                )
                    , XMLElement("quantity", SHP_LIB_STOCK.getQuantity(iGoodID => GCO_GOOD_ID, ivDataSource4Quantity => ivDataSource4Quantity) )
                    , XMLElement("status", SHP_LIB_STOCK.getStatus(iGoodID => GCO_GOOD_ID) )
                    , XMLElement("displayable", 'Y')
                    , XMLElement("displayable_permission_level", GOO_WEB_VISUAL_LEVEL)
                    , XMLElement("orderable", decode(nvl(GOO_WEB_CAN_BE_ORDERED, 0), 0, 'N', 'Y') )
                    , XMLElement("orderable_permission_level", GOO_WEB_ORDERABILITY_LEVEL)
                    , XMLElement("usergroup_prices"
                               , SHP_LIB_STOCK.getUserGroupPriceXmlType(iGoodID => GCO_GOOD_ID, iDiscountsAndChargesIncluded => inDiscountsAndChargesIncluded)
                                )
                    , XMLElement("product_combinations", null)   /* pas dans la version 1.0 */
                     )
      into lxXmlData
      from GCO_GOOD
     where GCO_GOOD_ID = iGoodID;

    return lxXmlData;
  end getStockXmlType;

  /**
  * Description
  *   Retourne sous forme binaire les noeuds XML "usergroup_price" contenant
  *   les informations relatives à un prix de vente pour un groupe.
  */
  function getUserGroupPriceXmlType(iGoodID in GCO_GOOD.GCO_GOOD_ID%type, iDiscountsAndChargesIncluded in number)
    return xmltype
  as
    lxXmlData xmltype;
  begin
    select XMLAgg(XMLElement("usergroup_price"
                           , XMLElement("usergroup_id", WEB_GROUP_ID)
                           , XMLElement("min_quantity", '1')
                           , XMLElement("price"
                                      , getPrice(iGoodID                         => iGoodID
                                               , iCurrencyId                     => PTC_I_LIB_PRICE.getCurrIdFromDicTariff(DIC_TARIFF_ID)
                                               , ivDicTariffID                   => DIC_TARIFF_ID
                                               , inDiscountsAndChargesIncluded   => iDiscountsAndChargesIncluded
                                                )
                                       )
                            )
                 )
      into lxXmlData
      from (select distinct weg.WEB_GROUP_ID
                          , dic.DIC_TARIFF_ID
                       from WEB_GROUP weg
                          , WEB_USER_GROUP_ROLE wugr
                          , WEB_USER weu
                          , DIC_TARIFF dic
                      where wugr.WEB_GROUP_ID = weg.WEB_GROUP_ID
                        and weu.WEB_USER_ID = wugr.WEB_USER_ID
                        and upper(weg.WEG_GROUP_NAME) = upper(dic.DIC_TARIFF_ID)
                        and weu.PAC_CUSTOM_PARTNER_ID is not null);

    return lxXmlData;
  end getUserGroupPriceXmlType;

  /**
  * function
  * Description
  *   Cette fonction retourne le contenu du fichier XML sous forme de CLOB contenant
  *   les informations relatives à la quantité en stock des produits exportés.
  */
  function getStocksXml(
    ittProductIDs                 in ID_TABLE_TYPE
  , ivVendorID                    in varchar2
  , ivVendorKey                   in varchar2
  , ivVendorContentType           in varchar2
  , ivDicTariffPrice              in DIC_TARIFF.DIC_TARIFF_ID%type
  , ivDicTariffListPrice          in DIC_TARIFF.DIC_TARIFF_ID%type
  , ivDataSource4Quantity         in varchar2
  , inDiscountsAndChargesIncluded in number
  )
    return clob
  is
    lxXmlData xmltype;
  begin
    select XMLElement("products"
                    , SHP_LIB_VENDOR.getVendorXmltype(ivVendorID => ivVendorID, ivVendorKey => ivVendorKey, ivVendorContentType => ivVendorContentType)
                    , XMLAgg(SHP_LIB_STOCK.getStockXmlType(iGoodID                         => tbl.column_value
                                                         , ivDicTariffPrice                => ivDicTariffPrice
                                                         , ivDicTariffListPrice            => ivDicTariffListPrice
                                                         , ivDataSource4Quantity           => ivDataSource4Quantity
                                                         , inDiscountsAndChargesIncluded   => inDiscountsAndChargesIncluded
                                                          )
                            )
                     )
      into lxXmlData
      from table(PCS.IdTableTypeToTable(aIdList => ittProductIDs) ) tbl;

    if lxXmlData is not null then
      return lxXmlData.getClobVal();
    else
      return null;
    end if;
  end getStocksXml;

  /**
  * Description
  *   Retourne le tarif du produit dont la clef primaire est transmise
  *   en paramètre dans la monnaie transmise en paramètre.
  */
  function getPrice(
    iGoodID                       in GCO_GOOD.GCO_GOOD_ID%type
  , iCurrencyId                   in ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  , ivDicTariffID                 in DIC_TARIFF.DIC_TARIFF_ID%type
  , inDiscountsAndChargesIncluded in number
  )
    return number
  is
    lnReturn number(15, 4);
    lnCurrID ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    -- Contrairement à GCO_LIB_PRICE.GetGoodPrice qui ne retourne que le prix brut (hors taxes et remise),
    -- PTC_FIND_TARIFF.GetFullPrice retourne avec ou sans les taxes et remise selon paramètre, d'où son
    -- utilisation dans CE cas précis.
    lnReturn  :=
      PTC_FIND_TARIFF.GetFullPrice(aGoodId              => iGoodID
                                 , aQuantity            => 1
                                 , aThirdId             => null
                                 , aRecordId            => null
                                 , aGaugeId             => null
                                 , aCurrencyId          => iCurrencyId
                                 , aTariffType          => 'A_FACTURER'
                                 , aTarifficationMode   => '1'
                                 , aDicTariffId         => ivDicTariffID
                                 , aDateRef             => sysdate
                                 , aChargeType          => '1'   --client
                                 , aPositionId          => null
                                 , aDocumentId          => null
                                 , aBlnCharge           => inDiscountsAndChargesIncluded
                                 , aBlnDiscount         => inDiscountsAndChargesIncluded
                                 , aTariffId            => null
                                  );
    return lnReturn;
  end getPrice;

  /**
  * Description
  *   Retourne la quantité disponible pour le produit dont l'ID est transmis en paramètre
  *   en utilisant la source de données transmise en paramètre.
  */
  function getQuantity(iGoodID in GCO_GOOD.GCO_GOOD_ID%type, ivDataSource4Quantity in varchar2)
    return number
  is
    lnReturn   number(15, 4);
    lvSqlQuery varchar2(4000);
  begin
    lvSqlQuery  :=
      ' select nvl(sum(SPO_AVAILABLE_QUANTITY), 0)
                    from TABLE(' || ivDataSource4Quantity || '(' || to_char(iGoodID, 'FM999999999990') || '))';

    execute immediate lvSqlQuery
                 into lnReturn;

    if nvl(lnReturn, 0) < 1 then
      lnReturn  := 0;
    end if;

    return lnReturn;
  end getQuantity;

  /**
  * Description
  *   Retourne le statut du produit dont l'ID est transmis. Retourne "D" si le produit
  *   n'est pas publié, sinon "A".
  */
  function getStatus(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return varchar2
  is
    lnGooWebPublished GCO_GOOD.GOO_WEB_PUBLISHED%type;
  begin
    select nvl(GOO_WEB_PUBLISHED, 0)
      into lnGooWebPublished
      from GCO_GOOD
     where GCO_GOOD_ID = iGoodID;

    if (lnGooWebPublished = 0) then
      return 'D';
    else
      return 'A';
    end if;
  end getStatus;
end SHP_LIB_STOCK;
