--------------------------------------------------------
--  DDL for Package Body SHP_MGT_DATA_EXPORT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SHP_MGT_DATA_EXPORT" 
as
  /**
  * Description
  *   exportation des données "produit"
  */
  procedure exportProductsXml(
    ivExchangeSystemKey         in PCS.PC_EXCHANGE_SYSTEM.ECS_KEY%type
  , ivDataSource4Descr          in varchar2 default SHP_LIB_TYPES.gcvDataSource4Descr
  , ivDataSource4Pictures       in varchar2 default SHP_LIB_TYPES.gcvDataSource4Pictures
  , ivDataSource4Components     in varchar2 default SHP_LIB_TYPES.gcvDataSource4Components
  , ivDataSource4AdditionalDocs in varchar2 default SHP_LIB_TYPES.gcvDataSource4AdditionalDocs
  , ivDataSource4Classif        in varchar2
  , inBomIncluded               in number default 0
  , ivPicturesRootPath          in varchar2
  , ivPicturesWebServerPath     in varchar2
  , ivDocsRootPath              in varchar2
  , ivDocsWebServerPath         in varchar2
  , ivFilename                  in PCS.PC_EXCHANGE_DATA_OUT.EDO_FILENAME%type default SHP_LIB_TYPES.gcvFilename4Products
  , ivVendorID                  in varchar2
  , ivVendorKey                 in varchar2
  , ivVendorContentType         in varchar2 default SHP_LIB_TYPES.gcvCtProducts
  , inMaxElementsPerXml         in number default SHP_LIB_TYPES.gcnMaxXmlElements
  , inUseWindowsPathDelimiter   in number default 1
  )
  is
    cursor curProductIDs
    is
      select COM_LIST_ID_TEMP_ID
        from COM_LIST_ID_TEMP
       where LID_CODE = 'SHP_PRODUCTS';

    lttProductIDs ID_TABLE_TYPE;
    ltDataOut     PCS.PC_LIB_EXCHANGE_DATA_CONST.t_exchange_data_type;
    lcProducts    clob;
  begin
    delete from COM_LIST_ID_TEMP
          where upper(LID_CODE) = 'SHP_PRODUCTS'
             or upper(LID_CODE) = 'SHP_STOCKS';

    /* Supression des Produits exportés via trigger mais n'étant pas publiables. */
    /* Lors de modification de description de produit, par exemple, on insère dans
       la table "SHP_TO_PUBLISH" le produit sans regarder s'il est publiable ou non
       pour éviter le risque d'erreur "table en mutation" */
    delete from SHP_TO_PUBLISH
          where STP_REC_ID in(
                  select STP_REC_ID
                    from SHP_TO_PUBLISH stp
                       , GCO_GOOD goo
                   where stp.STP_REC_ID = goo.GCO_GOOD_ID
                     and stp.STP_CONTEXT = SHP_LIB_TYPES.gcvCtxProduct
                     and stp.C_GOO_WEB_STATUS = '1'
                     and GOO.GOO_WEB_PUBLISHED = '0');

    /* Récupération des IDs des produits à exporter */
    for ltplToPublish in (select   STP_REC_ID
                              from SHP_TO_PUBLISH
                             where STP_CONTEXT = SHP_LIB_TYPES.gcvCtxProduct
                               and C_GOO_WEB_STATUS = '1'
                               and STP_REC_ID is not null
                          order by STP_REC_ID) loop
      /* Insertion dans la table d'ID temporaire */
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                  )
           values (ltplToPublish.STP_REC_ID
                 , 'SHP_PRODUCTS'
                  );
    end loop;

    open curProductIDs;

    loop
      fetch curProductIDs
      bulk collect into lttProductIDs limit inMaxElementsPerXml;

      exit when lttProductIDs.count = 0;
      /* Récupérations des données au format XML */
      lcProducts  :=
        SHP_LIB_PRODUCT.getProductsXml(ittProductIDs                 => lttProductIDs
                                     , ivDataSource4Descr            => ivDataSource4Descr
                                     , ivDataSource4Pictures         => ivDataSource4Pictures
                                     , ivDataSource4Components       => ivDataSource4Components
                                     , ivDataSource4AdditionalDocs   => ivDataSource4AdditionalDocs
                                     , ivDataSource4Classif          => ivDataSource4Classif
                                     , inBomIncluded                 => inBomIncluded
                                     , ivPicturesRootPath            => ivPicturesRootPath
                                     , ivPicturesWebServerPath       => ivPicturesWebServerPath
                                     , ivDocsRootPath                => ivDocsRootPath
                                     , ivDocsWebServerPath           => ivDocsWebServerPath
                                     , inUseWindowsPathDelimiter     => inUseWindowsPathDelimiter
                                     , ivVendorID                    => ivVendorID
                                     , ivVendorKey                   => ivVendorKey
                                     , ivVendorContentType           => ivVendorContentType
                                      );

      /* Transfert sur table "SHP_PUBLISHED" */
      for i in lttProductIDs.first .. lttProductIDs.last loop
        SHP_PRC_PUBLISH.updatePublishedRecord(inRecId => lttProductIDs(i), ivContext => SHP_LIB_TYPES.gcvCtxProduct);
      end loop;

      /* exportation du document XML */
      if DBMS_LOB.getlength(lcProducts) > 0 then
        ltDataOut  :=
          PCS.PC_MGT_EXCHANGE_DATA_OUT.open(iv_exchange_system_key   => ivExchangeSystemKey
                                          , iv_filename              => ivFilename || to_char(systimestamp, 'YYYYMMDDHH24MISSFF5') || '.xml'
                                          , iv_destination_url       => null
                                          , iv_file_encoding         => null
                                           );
        PCS.PC_MGT_EXCHANGE_DATA_OUT.put_xml_clob(ltDataOut, lcProducts);
        PCS.PC_MGT_EXCHANGE_DATA_OUT.close(ltDataOut);
      end if;
    end loop;

    close curProductIDs;
  end exportProductsXml;

  /**
  * Description
  *   exportation des données <PRODUCTS_CHARACTERISTICS>
  */
  procedure exportProductsCharactXml(
    ivExchangeSystemKey in PCS.PC_EXCHANGE_SYSTEM.ECS_KEY%type
  , ivFilename          in PCS.PC_EXCHANGE_DATA_OUT.EDO_FILENAME%type default SHP_LIB_TYPES.gcvFilename4PdtCharacteristics
  , ivVendorID          in varchar2
  , ivVendorKey         in varchar2
  , ivVendorContentType in varchar2 default SHP_LIB_TYPES.gcvCtProducthCaracteristics
  , inMaxElementsPerXml in number default SHP_LIB_TYPES.gcnMaxXmlElements
  )
  is
    cursor curPdtCharactIDs
    is
      select COM_LIST_ID_TEMP_ID
        from COM_LIST_ID_TEMP
       where LID_CODE = 'SHP_PRODUCTS_CHARACT';

    lttPdtCharactIDs ID_TABLE_TYPE;
    ltDataOut        PCS.PC_LIB_EXCHANGE_DATA_CONST.t_exchange_data_type;
    lcPdtCharacts    clob;
  begin
    delete from COM_LIST_ID_TEMP
          where upper(LID_CODE) = 'SHP_PRODUCTS_CHARACT';

    /* Supression des caractérisations exportés via trigger mais n'étant pas publiables. */
    /* Lors de modification de carctérisation d'un produit, par exemple, on insère dans
       la table "SHP_TO_PUBLISH" la caractérisation sans regarder si le produit auquelle
       elle est rattachée est publiable ou non pour éviter le risque d'erreur "table en mutation" */
    delete from SHP_TO_PUBLISH
          where STP_REC_ID in(
                  select STP_REC_ID
                    from SHP_TO_PUBLISH stp
                       , STM_ELEMENT_NUMBER sem
                       , GCO_GOOD goo
                   where stp.STP_REC_ID = sem.STM_ELEMENT_NUMBER_ID
                     and goo.GCO_GOOD_ID = sem.GCO_GOOD_ID
                     and stp.STP_CONTEXT = SHP_LIB_TYPES.gcvCtxProductCharacteristics
                     and stp.C_GOO_WEB_STATUS = '1'
                     and GOO.GOO_WEB_PUBLISHED = '0');

    /* Récupération des IDs des produits à exporter */
    for ltplToPublish in (select   STP_REC_ID
                              from SHP_TO_PUBLISH
                             where STP_CONTEXT = SHP_LIB_TYPES.gcvCtxProductCharacteristics
                               and C_GOO_WEB_STATUS = '1'
                               and STP_REC_ID is not null
                          order by STP_REC_ID) loop
      /* Insertion dans la table d'ID temporaire */
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                  )
           values (ltplToPublish.STP_REC_ID
                 , 'SHP_PRODUCTS_CHARACT'
                  );
    end loop;

    open curPdtCharactIDs;

    loop
      fetch curPdtCharactIDs
      bulk collect into lttPdtCharactIDs limit inMaxElementsPerXml;

      exit when lttPdtCharactIDs.count = 0;
      /* Récupérations des données au format XML */
      lcPdtCharacts  :=
        SHP_LIB_PRODUCT.getProductsCharactXml(ittPdtCharactIDs      => lttPdtCharactIDs
                                            , ivVendorID            => ivVendorID
                                            , ivVendorKey           => ivVendorKey
                                            , ivVendorContentType   => ivVendorContentType
                                             );

      /* Transfert sur table "SHP_PUBLISHED" */
      for i in lttPdtCharactIDs.first .. lttPdtCharactIDs.last loop
        SHP_PRC_PUBLISH.updatePublishedRecord(inRecId => lttPdtCharactIDs(i), ivContext => SHP_LIB_TYPES.gcvCtxProductCharacteristics);
      end loop;

      /* exportation du document XML */
      if DBMS_LOB.getlength(lcPdtCharacts) > 0 then
        ltDataOut  :=
          PCS.PC_MGT_EXCHANGE_DATA_OUT.open(iv_exchange_system_key   => ivExchangeSystemKey
                                          , iv_filename              => ivFilename || to_char(systimestamp, 'YYYYMMDDHH24MISSFF5') || '.xml'
                                          , iv_destination_url       => null
                                          , iv_file_encoding         => null
                                           );
        PCS.PC_MGT_EXCHANGE_DATA_OUT.put_xml_clob(ltDataOut, lcPdtCharacts);
        PCS.PC_MGT_EXCHANGE_DATA_OUT.close(ltDataOut);
      end if;
    end loop;

    close curPdtCharactIDs;
  end exportProductsCharactXml;

  /**
  * Description
  *   exportation des données "produit" supprimés
  */
  procedure exportDeletedProductsXml(
    ivExchangeSystemKey in PCS.PC_EXCHANGE_SYSTEM.ECS_KEY%type
  , ivFilename          in PCS.PC_EXCHANGE_DATA_OUT.EDO_FILENAME%type default SHP_LIB_TYPES.gcvFilename4DeletedProducts
  , ivVendorID          in varchar2
  , ivVendorKey         in varchar2
  , ivVendorContentType in varchar2 default SHP_LIB_TYPES.gcvCtDeletedProducts
  , inMaxElementsPerXml in number default SHP_LIB_TYPES.gcnMaxXmlElements
  )
  is
    cursor curProductIDs
    is
      select COM_LIST_ID_TEMP_ID
        from COM_LIST_ID_TEMP
       where LID_CODE = 'SHP_PRODUCTS';

    lttProductIDs ID_TABLE_TYPE;
    ltDataOut     PCS.PC_LIB_EXCHANGE_DATA_CONST.t_exchange_data_type;
    lcProducts    clob;
  begin
    delete from COM_LIST_ID_TEMP
          where upper(LID_CODE) = 'SHP_PRODUCTS'
             or upper(LID_CODE) = 'SHP_STOCKS';

    /* Récupération des IDs des produits à exporter */
    for ltplToPublish in (select   STP_REC_ID
                              from SHP_TO_PUBLISH
                             where STP_CONTEXT = SHP_LIB_TYPES.gcvCtxProduct
                               and C_GOO_WEB_STATUS = '3'
                               and STP_REC_ID is not null
                          order by STP_REC_ID) loop
      /* Insertion dans la table d'ID temporaire */
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                  )
           values (ltplToPublish.STP_REC_ID
                 , 'SHP_PRODUCTS'
                  );
    end loop;

    open curProductIDs;

    loop
      fetch curProductIDs
      bulk collect into lttProductIDs limit inMaxElementsPerXml;

      exit when lttProductIDs.count = 0;
      /* Récupérations des données au format XML */
      lcProducts  :=
        SHP_LIB_PRODUCT.getDeletedProductsXml(ittProductIDs         => lttProductIDs
                                            , ivVendorID            => ivVendorID
                                            , ivVendorKey           => ivVendorKey
                                            , ivVendorContentType   => ivVendorContentType
                                             );

      /* Transfert sur table "SHP_PUBLISHED" */
      for i in lttProductIDs.first .. lttProductIDs.last loop
        SHP_PRC_PUBLISH.updatePublishedRecord(inRecId => lttProductIDs(i), ivContext => SHP_LIB_TYPES.gcvCtxProduct);
      end loop;

      /* exportation du document XML */
      if DBMS_LOB.getlength(lcProducts) > 0 then
        ltDataOut  :=
          PCS.PC_MGT_EXCHANGE_DATA_OUT.open(iv_exchange_system_key   => ivExchangeSystemKey
                                          , iv_filename              => ivFilename || to_char(systimestamp, 'YYYYMMDDHH24MISSFF5') || '.xml'
                                          , iv_destination_url       => null
                                          , iv_file_encoding         => null
                                           );
        PCS.PC_MGT_EXCHANGE_DATA_OUT.put_xml_clob(ltDataOut, lcProducts);
        PCS.PC_MGT_EXCHANGE_DATA_OUT.close(ltDataOut);
      end if;
    end loop;

    close curProductIDs;
  end exportDeletedProductsXml;

  /**
  * Description
  *   exportation des données "catégorie"
  */
  procedure exportCategoriesXml(
    ivExchangeSystemKey       in PCS.PC_EXCHANGE_SYSTEM.ECS_KEY%type
  , ivDataSource4Pictures     in varchar2 default SHP_LIB_TYPES.gcvDataSource4Pictures
  , ivPicturesRootPath        in varchar2
  , ivPicturesWebServerPath   in varchar2
  , ivFilename                in PCS.PC_EXCHANGE_DATA_OUT.EDO_FILENAME%type default SHP_LIB_TYPES.gcvFilename4Categories
  , ivVendorID                in varchar2
  , ivVendorKey               in varchar2
  , ivVendorContentType       in varchar2 default SHP_LIB_TYPES.gcvCtCategories
  , inMaxElementsPerXml       in number default SHP_LIB_TYPES.gcnMaxXmlElements
  , inUseWindowsPathDelimiter in number default 1
  )
  is
    cursor curCategorieIDs
    is
      select COM_LIST_ID_TEMP_ID
        from COM_LIST_ID_TEMP
       where upper(LID_CODE) = 'SHP_CATEGORIES';

    lttCategorieIDs ID_TABLE_TYPE;
    ltDataOut       PCS.PC_LIB_EXCHANGE_DATA_CONST.t_exchange_data_type;
    lcCategories    clob;
  begin
    delete from COM_LIST_ID_TEMP
          where upper(LID_CODE) = 'SHP_CATEGORIES';

    for ltplToPublish in (select WEB_CATEG_ARRAY_ID
                            from WEB_CATEG_ARRAY
                           where WCA_IS_ACTIVE = 1) loop
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                  )
           values (ltplToPublish.WEB_CATEG_ARRAY_ID
                 , 'SHP_CATEGORIES'
                  );
    end loop;

    open curCategorieIDs;

    loop
      fetch curCategorieIDs
      bulk collect into lttCategorieIDs limit inMaxElementsPerXml;

      exit when lttCategorieIDs.count = 0;
      lcCategories  :=
        SHP_LIB_CATEGORY.getCategoriesXml(ittCategorieIDs             => lttCategorieIDs
                                        , ivDataSource4Pictures       => ivDataSource4Pictures
                                        , ivPicturesRootPath          => ivPicturesRootPath
                                        , ivPicturesWebServerPath     => ivPicturesWebServerPath
                                        , inUseWindowsPathDelimiter   => inUseWindowsPathDelimiter
                                        , ivVendorID                  => ivVendorID
                                        , ivVendorKey                 => ivVendorKey
                                        , ivVendorContentType         => ivVendorContentType
                                         );

      -- exportation du document xml
      if DBMS_LOB.getlength(lcCategories) > 0 then
        ltDataOut  :=
          PCS.PC_MGT_EXCHANGE_DATA_OUT.open(iv_exchange_system_key   => ivExchangeSystemKey
                                          , iv_filename              => ivFilename || to_char(systimestamp, 'YYYYMMDDHH24MISSFF5') || '.xml'
                                          , iv_destination_url       => null
                                          , iv_file_encoding         => null
                                           );
        PCS.PC_MGT_EXCHANGE_DATA_OUT.put_xml_clob(ltDataOut, lcCategories);
        PCS.PC_MGT_EXCHANGE_DATA_OUT.close(ltDataOut);
      end if;
    end loop;

    close curCategorieIDs;
  end exportCategoriesXml;

  /**
  * Description
  *   exportation des données "stocks"
  */
  procedure exportStocksXml(
    ivExchangeSystemKey           in PCS.PC_EXCHANGE_SYSTEM.ECS_KEY%type
  , ivDataSource4Quantity         in varchar2 default SHP_LIB_TYPES.gcvDataSource4Quantity
  , ivDictariffPrice              in DIC_TARIFF.DIC_TARIFF_ID%type
  , ivDictariffListPrice          in DIC_TARIFF.DIC_TARIFF_ID%type
  , ivFilename                    in PCS.PC_EXCHANGE_DATA_OUT.EDO_FILENAME%type default SHP_LIB_TYPES.gcvFilename4Stocks
  , ivVendorID                    in varchar2
  , ivVendorKey                   in varchar2
  , ivVendorContentType           in varchar2 default SHP_LIB_TYPES.gcvCtStocks
  , inMaxElementsPerXml           in number default SHP_LIB_TYPES.gcnMaxXmlElements
  , inDiscountsAndChargesIncluded in number default 0
  )
  is
    cursor curStockIDs
    is
      select COM_LIST_ID_TEMP_ID
        from COM_LIST_ID_TEMP
       where upper(LID_CODE) = 'SHP_STOCKS';

    lttStockIDs ID_TABLE_TYPE;
    ltDataOut   PCS.PC_LIB_EXCHANGE_DATA_CONST.t_exchange_data_type;
    lcStocks    clob;
  begin
    delete from COM_LIST_ID_TEMP
          where upper(LID_CODE) = 'SHP_STOCKS'
             or upper(LID_CODE) = 'SHP_PRODUCTS';

    for ltplToPublish in (select spp.SPP_REC_ID
                            from SHP_PUBLISHED spp
                               , GCO_GOOD goo
                           where spp.SPP_CONTEXT = SHP_LIB_TYPES.gcvCtxProduct
                             and spp.SPP_REC_ID = goo.GCO_GOOD_ID) loop
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                  )
           values (ltplToPublish.SPP_REC_ID
                 , 'SHP_STOCKS'
                  );
    end loop;

    open curStockIDs;

    loop
      fetch curStockIDs
      bulk collect into lttStockIDs limit inMaxElementsPerXml;

      exit when lttStockIDs.count = 0;
      lcStocks  :=
        SHP_LIB_STOCK.getStocksXml(ittProductIDs                   => lttStockIDs
                                 , ivVendorID                      => ivVendorID
                                 , ivVendorKey                     => ivVendorKey
                                 , ivVendorContentType             => ivVendorContentType
                                 , ivDictariffPrice                => ivDictariffPrice
                                 , ivDictariffListPrice            => ivDictariffListPrice
                                 , ivDatasource4Quantity           => ivDatasource4Quantity
                                 , inDiscountsAndChargesIncluded   => inDiscountsAndChargesIncluded
                                  );

      -- exportation du document xml
      if DBMS_LOB.getlength(lcStocks) > 0 then
        ltDataOut  :=
          PCS.PC_MGT_EXCHANGE_DATA_OUT.open(iv_exchange_system_key   => ivExchangeSystemKey
                                          , iv_filename              => ivFilename || to_char(systimestamp, 'YYYYMMDDHH24MISSFF5') || '.xml'
                                          , iv_destination_url       => null
                                          , iv_file_encoding         => null
                                           );
        PCS.PC_MGT_EXCHANGE_DATA_OUT.put_xml_clob(ltDataOut, lcStocks);
        PCS.PC_MGT_EXCHANGE_DATA_OUT.close(ltDataOut);
      end if;
    end loop;

    close curStockIDs;
  end exportStocksXml;

  /**
  * Description
  *   exportation des données "utilisateur"
  */
  procedure exportUsersXml(
    ivExchangeSystemKey          in PCS.PC_EXCHANGE_SYSTEM.ECS_KEY%type
  , ivDicAddressTypeId           in varchar2 default 'Liv'
  , ivDataSource4UserInfos       in varchar2 default SHP_LIB_TYPES.gcvDataSource4UserInfos
  , ivdataSource4BillingAddress  in varchar2 default SHP_LIB_TYPES.gcvDataSource4BillingAddress
  , ivdataSource4ShippingAddress in varchar2 default SHP_LIB_TYPES.gcvDataSource4ShippingAddress
  , iPhoneDicCommunicationID     in DIC_COMMUNICATION_TYPE.DIC_COMMUNICATION_TYPE_ID%type
  , iFaxDicCommunicationID       in DIC_COMMUNICATION_TYPE.DIC_COMMUNICATION_TYPE_ID%type
  , iWebSiteDicCommunicationID   in DIC_COMMUNICATION_TYPE.DIC_COMMUNICATION_TYPE_ID%type
  , ivFilename                   in PCS.PC_EXCHANGE_DATA_OUT.EDO_FILENAME%type default SHP_LIB_TYPES.gcvFilename4Users
  , ivVendorID                   in varchar2
  , ivVendorKey                  in varchar2
  , ivVendorContentType          in varchar2 default SHP_LIB_TYPES.gcvCtUsers
  , inMaxElementsPerXml          in number default SHP_LIB_TYPES.gcnMaxXmlElements
  )
  is
    cursor curUserIDs
    is
      select COM_LIST_ID_TEMP_ID
        from COM_LIST_ID_TEMP
       where upper(LID_CODE) = 'SHP_USERS';

    lttUserIDs ID_TABLE_TYPE;
    ltDataOut  PCS.PC_LIB_EXCHANGE_DATA_CONST.t_exchange_data_type;
    lcUsers    clob;
  begin
    delete from COM_LIST_ID_TEMP
          where upper(LID_CODE) = 'SHP_USERS';

    for ltplToPublish in (select   WEB_USER_ID
                              from WEB_USER
                             where PAC_CUSTOM_PARTNER_ID is not null
                               and WEU_DISABLED = 0
                          order by WEB_USER_ID) loop
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                  )
           values (ltplToPublish.WEB_USER_ID
                 , 'SHP_USERS'
                  );
    end loop;

    open curUserIDs;

    loop
      fetch curUserIDs
      bulk collect into lttUserIDs limit inMaxElementsPerXml;

      exit when lttUserIDs.count = 0;
      lcUsers  :=
        SHP_LIB_USER.GetUsersXml(ittUserIDs                    => lttUserIDs
                               , ivVendorID                    => ivVendorID
                               , ivVendorKey                   => ivVendorKey
                               , ivVendorContentType           => ivVendorContentType
                               , ivDicAddressTypeId            => ivDicAddressTypeId
                               , iDataSource4UserInfos         => ivDataSource4UserInfos
                               , idataSource4BillingAddress    => ivdataSource4BillingAddress
                               , idataSource4ShippingAddress   => ivdataSource4ShippingAddress
                               , iPhoneDicCommunicationID      => iPhoneDicCommunicationID
                               , iFaxDicCommunicationID        => iFaxDicCommunicationID
                               , iWebSiteDicCommunicationID    => iWebSiteDicCommunicationID
                                );

      -- exportation du document xml
      if DBMS_LOB.getlength(lcUsers) > 0 then
        ltDataOut  :=
          PCS.PC_MGT_EXCHANGE_DATA_OUT.open(iv_exchange_system_key   => ivExchangeSystemKey
                                          , iv_filename              => ivFilename || to_char(systimestamp, 'YYYYMMDDHH24MISSFF5') || '.xml'
                                          , iv_destination_url       => null
                                          , iv_file_encoding         => null
                                           );
        PCS.PC_MGT_EXCHANGE_DATA_OUT.put_xml_clob(ltDataOut, lcUsers);
        PCS.PC_MGT_EXCHANGE_DATA_OUT.close(ltDataOut);
      end if;
    end loop;

    close curUserIDs;
  end exportUsersXml;

  /**
  * Description
  *   exportation des données "groupes utilisateur"
  */
  procedure exportUserGroupsXml(
    ivExchangeSystemKey in PCS.PC_EXCHANGE_SYSTEM.ECS_KEY%type
  , ivDicAddressTypeId  in varchar2 default 'Liv'
  , ivFilename          in PCS.PC_EXCHANGE_DATA_OUT.EDO_FILENAME%type default SHP_LIB_TYPES.gcvFilename4UserGoups
  , ivVendorID          in varchar2
  , ivVendorKey         in varchar2
  , ivVendorContentType in varchar2 default SHP_LIB_TYPES.gcvCtUserGroups
  , inMaxElementsPerXml in number default SHP_LIB_TYPES.gcnMaxXmlElements
  )
  is
    cursor curUserGroupIDs
    is
      select COM_LIST_ID_TEMP_ID
        from COM_LIST_ID_TEMP
       where upper(LID_CODE) = 'SHP_GROUPS';

    lttUserGroupIDs ID_TABLE_TYPE;
    ltDataOut       PCS.PC_LIB_EXCHANGE_DATA_CONST.t_exchange_data_type;
    lcUserGroups    clob;
  begin
    delete from COM_LIST_ID_TEMP
          where upper(LID_CODE) = 'SHP_GROUPS';

    for ltplToPublish in (select   weg.WEB_GROUP_ID
                              from WEB_GROUP weg
                                 , DIC_TARIFF dic
                             where upper(weg.WEG_GROUP_NAME) = upper(dic.DIC_TARIFF_ID)
                          order by weg.WEB_GROUP_ID) loop
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                  )
           values (ltplToPublish.WEB_GROUP_ID
                 , 'SHP_GROUPS'
                  );
    end loop;

    open curUserGroupIDs;

    loop
      fetch curUserGroupIDs
      bulk collect into lttUserGroupIDs limit inMaxElementsPerXml;

      exit when lttUserGroupIDs.count = 0;
      lcUserGroups  :=
        SHP_LIB_USER.getGroupsXml(ittGroupIDs           => lttUserGroupIDs
                                , ivVendorID            => ivVendorID
                                , ivVendorKey           => ivVendorKey
                                , ivVendorContentType   => ivVendorContentType
                                 );

      -- exportation du document xml
      if DBMS_LOB.getlength(lcUserGroups) > 0 then
        ltDataOut  :=
          PCS.PC_MGT_EXCHANGE_DATA_OUT.open(iv_exchange_system_key   => ivExchangeSystemKey
                                          , iv_filename              => ivFilename || to_char(systimestamp, 'YYYYMMDDHH24MISSFF5') || '.xml'
                                          , iv_destination_url       => null
                                          , iv_file_encoding         => null
                                           );
        PCS.PC_MGT_EXCHANGE_DATA_OUT.put_xml_clob(ltDataOut, lcUserGroups);
        PCS.PC_MGT_EXCHANGE_DATA_OUT.close(ltDataOut);
      end if;
    end loop;

    close curUserGroupIDs;
  end exportUserGroupsXml;

  /**
  * Description
  *   exportation des données "Statut des documents". Exporte les statuts des documents
  *   provenant du Shop dont le statut est modifié (présent dans la table SHP_TO_PUBLISH)
  */
  procedure exportDocumentStatusXml(
    ivExchangeSystemKey   in PCS.PC_EXCHANGE_SYSTEM.ECS_KEY%type
  , ivFilename            in PCS.PC_EXCHANGE_DATA_OUT.EDO_FILENAME%type default SHP_LIB_TYPES.gcvFilename4DocumentStatus
  , ivDatasource4Document in varchar2 default SHP_LIB_TYPES.gcvDatasource4Document
  , ivVendorID            in varchar2
  , ivVendorKey           in varchar2
  , ivVendorContentType   in varchar2 default SHP_LIB_TYPES.gcvCtDocumentStatus
  , inMaxElementsPerXml   in number default SHP_LIB_TYPES.gcnMaxXmlElements
  )
  as
    /* Définition du curseur de récupération des IDs */
    cursor curDocumentIDs
    is
      select COM_LIST_ID_TEMP_ID
        from COM_LIST_ID_TEMP
       where upper(LID_CODE) = 'SHP_DOCUMENTS';

    lttDocumentIDs ID_TABLE_TYPE;
    ltDataOut      PCS.PC_LIB_EXCHANGE_DATA_CONST.t_exchange_data_type;
    lcDocuments    clob;
  begin
    /* Purge de la table temporaire */
    delete from COM_LIST_ID_TEMP
          where upper(LID_CODE) = 'SHP_DOCUMENTS';

    /* Insertion dans la table temporaire des IDs à traiter */
    for ltplToPublish in (select   STP_REC_ID
                              from SHP_TO_PUBLISH
                             where STP_CONTEXT = SHP_LIB_TYPES.gcvCtxDocumentStatus
                               and C_GOO_WEB_STATUS = '1'   -- A publier
                               and STP_REC_ID is not null
                          order by STP_REC_ID) loop
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                  )
           values (ltplToPublish.STP_REC_ID
                 , 'SHP_DOCUMENTS'
                  );
    end loop;

    open curDocumentIDs;

    loop
      fetch curDocumentIDs
      bulk collect into lttDocumentIDs limit inMaxElementsPerXml;

      /* Pour chaque tranche de X ID (X = inMaxElementsPerXml) */
      exit when lttDocumentIDs.count = 0;
      /* Récupération des données sous forme de XML et insertion dans table avec
         système PC_EXCHANGE_DATA */
      lcDocuments  :=
        SHP_LIB_DOCUMENT.GetDocumentStatusXml(ittDocumentIDs          => lttDocumentIDs
                                            , ivVendorID              => ivVendorID
                                            , ivVendorKey             => ivVendorKey
                                            , ivVendorContentType     => ivVendorContentType
                                            , ivDatasource4Document   => ivDatasource4Document
                                             );

      /* Transfert sur table "SHP_PUBLISHED" */
      for i in lttDocumentIDs.first .. lttDocumentIDs.last loop
        SHP_PRC_PUBLISH.updatePublishedRecord(inRecId => lttDocumentIDs(i), ivContext => SHP_LIB_TYPES.gcvCtxDocumentStatus);
      end loop;

      if DBMS_LOB.getlength(lcDocuments) > 0 then
        ltDataOut  :=
          PCS.PC_MGT_EXCHANGE_DATA_OUT.open(iv_exchange_system_key   => ivExchangeSystemKey
                                          , iv_filename              => ivFilename || to_char(systimestamp, 'YYYYMMDDHH24MISSFF5') || '.xml'
                                          , iv_destination_url       => null
                                          , iv_file_encoding         => null
                                           );
        PCS.PC_MGT_EXCHANGE_DATA_OUT.put_xml_clob(ltDataOut, lcDocuments);
        PCS.PC_MGT_EXCHANGE_DATA_OUT.close(ltDataOut);
      end if;
    end loop;

    close curDocumentIDs;
  end exportDocumentStatusXml;
end SHP_MGT_DATA_EXPORT;
