--------------------------------------------------------
--  DDL for Package Body SHP_LIB_PRODUCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SHP_LIB_PRODUCT" 
as
  /**
  * Description
  *    Retourne sous forme binaire le noeud XML "product_descriptions"
  *    contenant les descriptions relatives au produit exporté
  */
  function getDescriptionsXmlType(inGcoGoodId in GCO_GOOD.GCO_GOOD_ID%type, ivDataSource4Descr in varchar2)
    return xmltype
  is
    lxXmlData xmltype;
  begin
    select XMLAgg(XMLElement("product_description"
                           , xmlattributes(upper(des.LAN_ISO_CODE_SHORT) as "lang")
                           , XMLElement("title", xmlcdata(des.MAIN_SHORT_DESCR) )
                           , XMLElement("short_description", xmlcdata(des.MAIN_LONG_DESCR) )
                           , XMLElement("long_description", xmlcdata(des.MAIN_FREE_DESCR) )
                           , XMLElement("metatitle", xmlcdata(des.META_SHORT_DESCR) )
                           , XMLElement("metadescription", xmlcdata(des.META_LONG_DESCR) )
                           , XMLElement("metakeywords", xmlcdata(des.META_FREE_DESCR) )
                            )
                 )
      into lxXmlData
      from table(SHP_LIB_PRODUCT.getDescriptionsData(inGcoGoodId => inGcoGoodId, ivDataSource4Descr => ivDataSource4Descr) ) des;

    if lxXmlData is not null then
      select XMLElement("product_descriptions", XMLElement("localization_code", 'N/A'), lxXmlData)   -- localizationCode ??
        into lxXmlData
        from dual;

      return lxXmlData;
    end if;

    return null;
  end getDescriptionsXmlType;

  /**
  * Description
  *    Retourne sous forme binaire le noeud XML "additional_categories"
  *    contenant les catégories du produit exporté
  */
  function getCategoriesXmlType(inGcoGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return xmltype
  is
    lxXmlData xmltype;
  begin
    select   XMLAgg(XMLElement("additional_category", wca.WCA_CODE) )
        into lxXmlData
        from (select distinct catdata.WCA_CODE
                         from table(SHP_LIB_PRODUCT.getCategoriesData(inGcoGoodId => inGcoGoodId) ) catdata
                        where catdata.WCA_CODE is not null) cat
           , WEB_CATEG wca
       where wca.WCA_CODE = cat.WCA_CODE
    order by wca.WCA_CODE;

    if lxXmlData is not null then
      select XMLElement("additional_categories", lxXmlData)
        into lxXmlData
        from dual;

      return lxXmlData;
    end if;

    return null;
  end getCategoriesXmlType;

  /**
  * Description
  *    Retourne sous forme binaire le noeud XML "product"
  *    contenant les informations relatives au produit exporté
  */
  function getProductXmlType(
    inGcoGoodId                 in GCO_GOOD.GCO_GOOD_ID%type
  , ivDataSource4Descr          in varchar2
  , ivDataSource4Pictures       in varchar2
  , ivDataSource4Components     in varchar2
  , ivDataSource4AdditionalDocs in varchar2
  , ivDataSource4Classif        in varchar2
  , inBomIncluded               in number
  , ivPicturesRootPath          in varchar2
  , ivPicturesWebServerPath     in varchar2
  , ivDocsRootPath              in varchar2
  , ivDocsWebServerPath         in varchar2
  , inUseWindowsPathDelimiter   in number
  )
    return xmltype
  is
    lxXmlData xmltype;
    lv3thPicGrpXmlElementName   varchar2(30) := null;
  begin
    if inBomIncluded = 1 then
      /* Si ce champ est null, le 3ème groupe d'image ne sera pas rajouté */
      lv3thPicGrpXmlElementName := 'bom_pictures';
    end if;

    select XMLElement("product"
                    , XMLElement("product_id", goo.GCO_GOOD_ID)
                    , XMLElement("product_reference", goo.GOO_MAJOR_REFERENCE)
                    , XMLElement("main_category", SHP_LIB_PRODUCT.getMainCategory(inGcoGoodId => inGcoGoodId) )
                    , SHP_LIB_PRODUCT.getCategoriesXmlType(inGcoGoodId => inGcoGoodId)
                    , XMLElement("weight", mea.MEA_NET_WEIGHT)
                    , XMLElement("creation_date", SHP_LIB_UTL.toDate1970Based(idDate => goo.A_DATECRE) )
                    , decode(inBomIncluded
                           , 1, SHP_LIB_PRODUCT.getComponentsXmlType(iGoodID => inGcoGoodId, ivDataSource4Components => ivDataSource4Components)
                            )
                    , XMLElement("product_attributes", null)   /* pas dans la version 1.0 */
                    , SHP_LIB_PRODUCT.getDescriptionsXmlType(inGcoGoodId => inGcoGoodId, ivDataSource4Descr => ivDataSource4Descr)
                    , SHP_LIB_PICTURE.getPicturesXmlType(inRecID                     => inGcoGoodId
                                                       , ivContext                   => 'GCO_GOOD'
                                                       , ivDataSource4Pictures       => ivDataSource4Pictures
                                                       , ivPicturesRootPath          => ivPicturesRootPath
                                                       , ivPicturesWebServerPath     => ivPicturesWebServerPath
                                                       , ivGlobalPicsXmlElementName  => 'product_pictures'
                                                       , iv1stPicGrpXmlElementName   => 'main_pictures'
                                                       , iv2ndPicGrpXmlElementName   => 'additional_pictures'
                                                       , iv3thPicGrpXmlElementName   => lv3thPicGrpXmlElementName
                                                       , iv1stPicGrpTypeName         => 'M'
                                                       , iv2ndPicGrpTypeName         => 'A'
                                                       , iv3thPicGrpTypeName         => 'B'
                                                       , iv1stPicXmlElementName      => 'product_picture'
                                                       , iv2ndPicXmlElementName      => 'product_picture'
                                                       , iv3thPicXmlElementName      => 'bom_picture'
                                                       , inUseWindowsPathDelimiter   => inUseWindowsPathDelimiter
                                                       , inAddSizeAttribute          => 1
                                                        )
                    , SHP_LIB_PRODUCT.getAdditionalDocsXmlType(inRecID                     => inGcoGoodId
                                                             , ivContext                   => 'GCO_GOOD'
                                                             , ivDataSource4AdditionalDocs => ivDataSource4AdditionalDocs
                                                             , ivDocsRootPath              => ivDocsRootPath
                                                             , ivDocsWebServerPath         => ivDocsWebServerPath
                                                             , ivGlobalDocsXmlElementName  => 'product_additional_documents'
                                                             , iv1stDocGrpXmlElementName   => 'X'
                                                             , iv1stDocGrpTypeName         => 'D'
                                                             , iv1stDocXmlElementName      => 'product_additional_document'
                                                             , inUseWindowsPathDelimiter   => inUseWindowsPathDelimiter
                                                             )
                    , SHP_LIB_PRODUCT.getClassifXmlType(iGoodID                   => inGcoGoodId
                                                      , ivDataSource4Classif      => ivDataSource4Classif
                                                      )
                    , XMLElement("product_options", null)   /* pas dans la version 1.0 */
                    , XMLElement("product_combinations", null)   /* pas dans la version 1.0 */
                     )
      into lxXmlData
      from GCO_GOOD goo
         , GCO_MEASUREMENT_WEIGHT mea
     where goo.GCO_GOOD_ID = inGcoGoodId
       and goo.GCO_GOOD_ID = mea.GCO_GOOD_ID(+);

    return lxXmlData;
  end getProductXmlType;

  /**
  * Description
  *    Retourne sous forme binaire le noeud XML "components"
  *    contenant les informations relatives aux composants du produit exporté
  */
  function getComponentsXmlType(iGoodID in GCO_GOOD.GCO_GOOD_ID%type, ivDataSource4Components in varchar2)
    return xmltype
  is
    lxXmlData xmltype;
  begin
    select XMLElement("components", XMLAgg(XMLElement("component", XMLElement("component_id", cpt.GCO_GOOD_ID)
                                                                 , XMLElement("bom_sequence", cpt.BOM_SEQUENCE)
                                                                 , XMLElement("index_on_bom_picture", cpt.BOM_INDEX)
                                                      )
                                          )
                     )
      into lxXmlData
      from table(SHP_LIB_PRODUCT.getComponentsData(iGoodID, ivDataSource4Components) ) cpt;

    return lxXmlData;
  end getComponentsXmlType;

  /**
  * Description
  *    Retourne le contenu du fichier XML sous forme de CLOB
  *    contenant les informations relatives aux produits exportés.
  */
  function getProductsXml(
    ittProductIDs               in ID_TABLE_TYPE
  , ivDataSource4Descr          in varchar2
  , ivDataSource4Pictures       in varchar2
  , ivDataSource4Components     in varchar2
  , ivDataSource4AdditionalDocs in varchar2
  , ivDataSource4Classif        in varchar2
  , inBomIncluded               in number
  , ivPicturesRootPath          in varchar2
  , ivPicturesWebServerPath     in varchar2
  , ivDocsRootPath              in varchar2
  , ivDocsWebServerPath         in varchar2
  , inUseWindowsPathDelimiter   in number
  , ivVendorID                  in varchar2
  , ivVendorKey                 in varchar2
  , ivVendorContentType         in varchar2
  )
    return clob
  is
    lxXmlData xmltype;
  begin
    select XMLElement("products"
                    , SHP_LIB_VENDOR.getVendorXmltype(ivVendorID => ivVendorID, ivVendorKey => ivVendorKey, ivVendorContentType => ivVendorContentType)
                    , XMLAgg(SHP_LIB_PRODUCT.getProductXmlType(inGcoGoodId                 => tbl.column_value
                                                             , ivDataSource4Descr          => ivDataSource4Descr
                                                             , ivDataSource4Pictures       => ivDataSource4Pictures
                                                             , ivDataSource4Components     => ivDataSource4Components
                                                             , ivDataSource4AdditionalDocs => ivDataSource4AdditionalDocs
                                                             , ivDataSource4Classif        => ivDataSource4Classif
                                                             , inBomIncluded               => inBomIncluded
                                                             , ivPicturesRootPath          => ivPicturesRootPath
                                                             , ivPicturesWebServerPath     => ivPicturesWebServerPath
                                                             , ivDocsRootPath              => ivDocsRootPath
                                                             , ivDocsWebServerPath         => ivDocsWebServerPath
                                                             , inUseWindowsPathDelimiter   => inUseWindowsPathDelimiter
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
  end getProductsXml;

  /**
  * Description
  *    Retourne le contenu du fichier XML sous forme de CLOB
  *    contenant les informations relatives aux produits supprimé à exporter.
  */
  function getDeletedProductsXml(ittProductIDs in ID_TABLE_TYPE, ivVendorID in varchar2, ivVendorKey in varchar2, ivVendorContentType in varchar2)
    return clob
  is
    lxXmlData xmltype;
  begin
    select XMLElement("products"
                    , SHP_LIB_VENDOR.getVendorXmltype(ivVendorID => ivVendorID, ivVendorKey => ivVendorKey, ivVendorContentType => ivVendorContentType)
                    , XMLAgg(XMLElement("product", XMLElement("product_id", tbl.column_value) ) )
                     )
      into lxXmlData
      from table(PCS.IdTableTypeToTable(aIdList => ittProductIDs) ) tbl;

    if lxXmlData is not null then
      return lxXmlData.getClobVal();
    else
      return null;
    end if;
  end getDeletedProductsXml;

  /**
  * Description
  *     Retourne sous forme binaire le noeud XML "product_characteristic"
  *     contenant les informations relatives à la caractérisation du produit exportée
  */
  function getProductsCharactXmlType(iElementNumberID in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type)
    return xmltype
  is
    lxXmlData xmltype;
  begin
    select XMLElement("product_characteristic"
                    , XMLElement("product_id", goo.GCO_GOOD_ID)
                    , XMLElement("product_reference", goo.GOO_MAJOR_REFERENCE)
                    , XMLElement("characteristic", xmlattributes(
                    case sem.C_ELEMENT_TYPE
                      when '01' then SHP_LIB_TYPES.gcvElemType01Name
                      when '02' then SHP_LIB_TYPES.gcvElemType02Name
                      when '03' then SHP_LIB_TYPES.gcvElemType03Name
                    end "type"), sem.SEM_VALUE)
                     )
      into lxXmlData
      from STM_ELEMENT_NUMBER sem
         , GCO_GOOD goo
     where STM_ELEMENT_NUMBER_ID = iElementNumberID
       and sem.GCO_GOOD_ID = goo.GCO_GOOD_ID;

    return lxXmlData;
  end getProductsCharactXmlType;

  /**
  * Description
  *     Retourne le contenu du fichier XML sous forme de CLOB
  *     contenant les informations relatives aux caractérisations de produit exportées.
  */
  function getProductsCharactXml(ittPdtCharactIDs in ID_TABLE_TYPE, ivVendorID in varchar2, ivVendorKey in varchar2, ivVendorContentType in varchar2)
    return clob
  is
    lxXmlData xmltype;
  begin
    select XMLElement("products_characteristics"
                    , SHP_LIB_VENDOR.getVendorXmltype(ivVendorID => ivVendorID, ivVendorKey => ivVendorKey, ivVendorContentType => ivVendorContentType)
                    , XMLAgg(SHP_LIB_PRODUCT.getProductsCharactXmlType(iElementNumberID => tbl.column_value) )
                     )
      into lxXmlData
      from table(PCS.IdTableTypeToTable(aIdList => ittPdtCharactIDs) ) tbl;

    if lxXmlData is not null then
      return lxXmlData.getClobVal();
    else
      return null;
    end if;
  end getProductsCharactXml;

  /**
  * Description
  *    Retourne sous forme binaire le noeud XML "product_additional_documents" contenant les
  *    groupes de documents (max 3) de l'élément dont la clef primaire est transmise en paramètre.
  */
  function getAdditionalDocsXmlType(
    inRecID                     in COM_IMAGE_FILES.IMF_REC_ID%type
  , ivContext                   in COM_IMAGE_FILES.IMF_TABLE%type
  , ivDataSource4AdditionalDocs in varchar2
  , ivDocsRootPath              in varchar2
  , ivDocsWebServerPath         in varchar2
  , ivGlobalDocsXmlElementName  in varchar2
  , iv1stDocGrpXmlElementName   in varchar2
  , iv2ndDocGrpXmlElementName   in varchar2 default null
  , iv3thDocGrpXmlElementName   in varchar2 default null
  , iv1stDocGrpTypeName         in varchar2
  , iv2ndDocGrpTypeName         in varchar2 default null
  , iv3thDocGrpTypeName         in varchar2 default null
  , iv1stDocXmlElementName      in varchar2
  , iv2ndDocXmlElementName      in varchar2 default null
  , iv3thDocXmlElementName      in varchar2 default null
  , inUseWindowsPathDelimiter   in number
  )
    return xmltype
  as
    lNumberOfDocsGroup number  := 0;
    lx1stGrpDocs       xmltype;
    lx2ndGrpDocs       xmltype;
    lx3thGrpDocs       xmltype;
    lxXmlData          xmltype;
  begin
  ------------------------------------------------------------------------------
    if iv1stDocGrpXmlElementName is not null then
      lNumberOfDocsGroup  := lNumberOfDocsGroup + 1;

--       select XMLElement(evalname(iv1stDocGrpXmlElementName)
                      select(XMLAgg(SHP_LIB_PRODUCT.getAdditionalDocXmlType(inRecID                     => inRecID
                                                                     , ivContext                   => ivContext
                                                                     , ivDataSource4AdditionalDocs => ivDataSource4AdditionalDocs
                                                                     , ivDocsRootPath              => ivDocsRootPath
                                                                     , ivDocsWebServerPath         => ivDocsWebServerPath
                                                                     , ivDocGroup                  => DOC_GROUP
                                                                     , ivDocType                   => iv1stDocGrpTypeName
                                                                     , ivDocXmlElementName         => iv1stDocXmlElementName
                                                                     , inUseWindowsPathDelimiter   => inUseWindowsPathDelimiter
                                                                      )
                              )
                       )
        into lx1stGrpDocs
        from (select   DOC_GROUP
                  from table(SHP_LIB_PRODUCT.getAdditionalDocsData(inRecID                     => inRecID
                                                                 , ivContext                   => ivContext
                                                                 , ivDocType                   => iv1stDocGrpTypeName
                                                                 , ivDataSource4AdditionalDocs => ivDataSource4AdditionalDocs
                                                                  )
                            )
              group by DOC_GROUP);
    end if;
  ------------------------------------------------------------------------------
    if iv2ndDocGrpXmlElementName is not null then
      lNumberOfDocsGroup  := lNumberOfDocsGroup + 1;

--       select XMLElement(evalname(iv2ndDocGrpXmlElementName)
                      select(XMLAgg(SHP_LIB_PRODUCT.getAdditionalDocXmlType(inRecID                     => inRecID
                                                                     , ivContext                   => ivContext
                                                                     , ivDataSource4AdditionalDocs => ivDataSource4AdditionalDocs
                                                                     , ivDocsRootPath              => ivDocsRootPath
                                                                     , ivDocsWebServerPath         => ivDocsWebServerPath
                                                                     , ivDocGroup                  => DOC_GROUP
                                                                     , ivDocType                   => iv2ndDocGrpTypeName
                                                                     , ivDocXmlElementName         => iv2ndDocXmlElementName
                                                                     , inUseWindowsPathDelimiter   => inUseWindowsPathDelimiter
                                                                      )
                              )
                       )
        into lx2ndGrpDocs
        from (select   DOC_GROUP
                  from table(SHP_LIB_PRODUCT.getAdditionalDocsData(inRecID                     => inRecID
                                                                 , ivContext                   => ivContext
                                                                 , ivDocType                   => iv2ndDocGrpTypeName
                                                                 , ivDataSource4AdditionalDocs => ivDataSource4AdditionalDocs
                                                                  )
                            )
              group by DOC_GROUP);
    end if;
  ------------------------------------------------------------------------------
    if iv3thDocGrpXmlElementName is not null then
      lNumberOfDocsGroup  := lNumberOfDocsGroup + 1;

--       select XMLElement(evalname(iv3thDocGrpXmlElementName)
                       select(XMLAgg(SHP_LIB_PRODUCT.getAdditionalDocXmlType(inRecID                     => inRecID
                                                                     , ivContext                   => ivContext
                                                                     , ivDataSource4AdditionalDocs => ivDataSource4AdditionalDocs
                                                                     , ivDocsRootPath              => ivDocsRootPath
                                                                     , ivDocsWebServerPath         => ivDocsWebServerPath
                                                                     , ivDocGroup                  => DOC_GROUP
                                                                     , ivDocType                   => iv3thDocGrpTypeName
                                                                     , ivDocXmlElementName         => iv3thDocXmlElementName
                                                                     , inUseWindowsPathDelimiter   => inUseWindowsPathDelimiter
                                                                      )
                              )
                       )
        into lx3thGrpDocs
        from (select   DOC_GROUP
                  from table(SHP_LIB_PRODUCT.getAdditionalDocsData(inRecID                     => inRecID
                                                                 , ivContext                   => ivContext
                                                                 , ivDocType                   => iv3thDocGrpTypeName
                                                                 , ivDataSource4AdditionalDocs => ivDataSource4AdditionalDocs
                                                                  )
                            )
              group by DOC_GROUP);
    end if;
  ------------------------------------------------------------------------------
    select case lNumberOfDocsGroup
             when 0 then null
             when 1 then XMLElement(evalname(ivGlobalDocsXmlElementName), lx1stGrpDocs)
             when 2 then XMLElement(evalname(ivGlobalDocsXmlElementName), lx1stGrpDocs, lx2ndGrpDocs)
             when 3 then XMLElement(evalname(ivGlobalDocsXmlElementName), lx1stGrpDocs, lx2ndGrpDocs, lx3thGrpDocs)
           end
      into lxXmlData
      from dual;

    return lxXmlData;
  end getAdditionalDocsXmlType;

  /**
  * Description
  *    Retourne sous forme binaire le noeud XML "product_additional_document" contenant un groupe
  *    de documents additionnels de l'élément dont l'ID est transmis en paramètre.
  */
  function getAdditionalDocXmlType(
    inRecID                     in COM_IMAGE_FILES.IMF_REC_ID%type
  , ivContext                   in COM_IMAGE_FILES.IMF_TABLE%type
  , ivDataSource4AdditionalDocs in varchar2
  , ivDocsRootPath              in varchar2
  , ivDocsWebServerPath         in varchar2
  , ivDocGroup                  in varchar2
  , ivDocType                   in varchar2
  , ivDocXmlElementName         in varchar2
  , inUseWindowsPathDelimiter   in number
  )
    return xmltype
  as
    lxXmlData xmltype;
  begin
    select XMLElement(evalname(ivDocXmlElementName)
                    , xmlattributes(ivDocType as "type")
                    , XMLAgg(XMLElement("url", xmlcdata(SHP_LIB_UTL.getFormattedURL(ivUrl                     => doc.url
                                                                                  , inUseWindowsPathDelimiter => inUseWindowsPathDelimiter
                                                                                  , ivRootPath                => ivDocsRootPath
                                                                                  , ivWebServerPath           => ivDocsWebServerPath
                                                                                   )
                                                       )
                                              )
                            )
                     )
      into lxXmlData
      from table(SHP_LIB_PRODUCT.getAdditionalDocsData(inRecID               => inRecID
                                                     , ivContext             => ivContext
                                                     , ivDocType             => ivDocType
                                                     , ivDataSource4AdditionalDocs => ivDataSource4AdditionalDocs
                                                       )
                ) doc
     where doc.DOC_GROUP = ivDocGroup;

    return lxXmlData;
  end getAdditionalDocXmlType;

  /**
  * Description
  *    Retourne sous forme binaire le noeud XML "classification" contenant les classifications définies dans la source
  *    de données.
  */
  function getClassifXmlType(
    iGoodID                   in GCO_GOOD.GCO_GOOD_ID%type
  , ivDataSource4Classif      in varchar2
  )
    return xmltype
  as
    lxXmlData xmltype;
  begin
     select xmlElement ("classification",
             xmlagg (SHP_LIB_PRODUCT.getClassifValueXmlType(iGoodID              => iGoodID
                                                          , ivDataSource4Classif => ivDataSource4Classif
                                                          , iClassifIndex        => tbl.CLASSIF_INDEX
                                                          , iClassifValue        => tbl.CLASSIF_VALUE)
               )
             )
       into lxXmlData
       from (select distinct CLASSIF_INDEX, CLASSIF_VALUE
                        from table (SHP_LIB_PRODUCT.getclassifdata(ivDataSource4Classif,iGoodId))
                    order by classif_index) tbl;

    return lxXmlData;
  end getClassifXmlType;

  /**
  * Description
  *    Retourne sous forme binaire le noeud XML "value" contenant la valeur
  *    de la classification du bien selon son index.
  */
  function getClassifValueXmlType(
    iGoodID                   in GCO_GOOD.GCO_GOOD_ID%type
  , ivDataSource4Classif      in varchar2
  , iClassifIndex             in number
  , iClassifValue             in varchar2
  )
    return xmltype
  as
    lxXmlData xmltype;
    lvTagName varchar2(30);
  begin
    lvTagName := 'classification_' || to_char (iClassifIndex , 'FM00');

    select xmlelement (evalName (lvTagName),
             XMLElement("value", iClassifValue),
             XmlElement("descriptions",
              xmlAgg(XMLElement("description", xmlattributes(upper(tbl.CLASSIF_LAN_ISO_CODE_SHORT) as "lang")
                                                     , XMLElement("description_01", tbl.CLASSIF_DESCRIPTION_01)
                                                     , XMLElement("description_02", tbl.CLASSIF_DESCRIPTION_02)
                ))))
      into lxXmlData
      from table(SHP_LIB_PRODUCT.getClassifData(iGoodID              => iGoodID
                                              , ivDataSource4Classif => ivDataSource4Classif
                                               )
                ) tbl
     where tbl.classif_index = iClassifIndex;

    return lxXmlData;
   end getClassifValueXmlType;

  /**
  * Description
  *    Retourne le code de la catégorie par défaut du produit
  *    exporté dont sa clef primaire est transmise en paramètre.
  */
  function getMainCategory(inGcoGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return WEB_CATEG.WCA_CODE%type
  is
    lvWcaCode WEB_CATEG.WCA_CODE%type;
  begin
    select min(wca.WCA_CODE)
      into lvWcaCode
      from WEB_GOOD wgo
         , WEB_CATEG_ARRAY wga
         , WEB_CATEG wca
     where wgo.GCO_GOOD_ID = inGcoGoodId
       and wgo.WGO_DEFAULT_CATEG = 1
       and wgo.WEB_CATEG_ARRAY_ID = wga.WEB_CATEG_ARRAY_ID
       and wga.WCA_IS_ACTIVE = 1
       and wga.WEB_CATEG_ID_LEVEL1 = wca.WEB_CATEG_ID;

    return lvWcaCode;
  end getMainCategory;

  /**
  * Description
  *    Retourne les descriptions dans les langues
  *    disponible du produit exporté selon la clef primaire transmise en paramètre.
  */
  function getDescriptionsData(inGcoGoodId in GCO_GOOD.GCO_GOOD_ID%type, ivDataSource4Descr in varchar2)
    return SHP_LIB_TYPES.ttDescriptions pipelined
  is
    cv            SYS_REFCURSOR;
    lvSqlQuery    varchar2(4000);
    ltDescription SHP_LIB_TYPES.tDescription;
  begin
    lvSqlQuery  :=
      'select LAN_ISO_CODE_SHORT
              , MAIN_SHORT_DESCR
              , MAIN_LONG_DESCR
              , MAIN_FREE_DESCR
              , META_SHORT_DESCR
              , META_LONG_DESCR
              , META_FREE_DESCR
           from TABLE(' ||
      ivDataSource4Descr ||
      '(' ||
      to_char(inGcoGoodId, 'FM999999999990') ||
      '))';

    open cv for lvSqlQuery;

    fetch cv
     into ltDescription;

    while cv%found loop
      pipe row(ltDescription);

      fetch cv
       into ltDescription;
    end loop;

    close cv;
  exception
    when no_data_needed then
      return;
  end getDescriptionsData;

  /**
  * Description
  *    Retourne la listes des codes des catégories du
  *    produit exporté selon la clef primaire transmise
  *    en paramètre.
  */
  function getCategoriesData(inGcoGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return SHP_LIB_TYPES.ttInternalCategory pipelined
  is
    ltInternalCategory SHP_LIB_TYPES.tInternalCategory;
  begin
    for ltplCategory in (select wct2.WCA_CODE WCA_CODE2
                              , wct3.WCA_CODE WCA_CODE3
                              , wct4.WCA_CODE WCA_CODE4
                              , wct5.WCA_CODE WCA_CODE5
                           from WEB_CATEG_ARRAY wca
                              , WEB_CATEG wct2
                              , WEB_CATEG wct3
                              , WEB_CATEG wct4
                              , WEB_CATEG wct5
                              , web_good wgo
                          where wgo.GCO_GOOD_ID = inGcoGoodId
                            and wgo.WEB_CATEG_ARRAY_ID = wca.WEB_CATEG_ARRAY_ID
                            and wca.WEB_CATEG_ID_LEVEL2 = wct2.WEB_CATEG_ID(+)
                            and wca.WEB_CATEG_ID_LEVEL3 = wct3.WEB_CATEG_ID(+)
                            and wca.WEB_CATEG_ID_LEVEL4 = wct4.WEB_CATEG_ID(+)
                            and wca.WEB_CATEG_ID_LEVEL5 = wct5.WEB_CATEG_ID(+)) loop
      ltInternalCategory.WCA_CODE  := ltplCategory.WCA_CODE2;
      pipe row(ltInternalCategory);
      ltInternalCategory.WCA_CODE  := ltplCategory.WCA_CODE3;
      pipe row(ltInternalCategory);
      ltInternalCategory.WCA_CODE  := ltplCategory.WCA_CODE4;
      pipe row(ltInternalCategory);
      ltInternalCategory.WCA_CODE  := ltplCategory.WCA_CODE5;
      pipe row(ltInternalCategory);
    end loop;
  exception
    when no_data_needed then
      return;
  end getCategoriesData;

  /**
  * Description
  *    Retourne la listes des ID des composants du
  *    produit exporté selon la source de données et la clef primaire transmise
  *    en paramètre.
  */
  function getComponentsData(iGoodID in GCO_GOOD.GCO_GOOD_ID%type, ivDataSource4Components in varchar2)
    return SHP_LIB_TYPES.ttComponents pipelined
  is
    cv          SYS_REFCURSOR;
    lvSqlQuery  varchar2(4000);
    ltComponent SHP_LIB_TYPES.tComponent;
  begin
    lvSqlQuery  := 'select BOM_INDEX, BOM_SEQUENCE, GCO_GOOD_ID from TABLE(' || ivDataSource4Components || '(' || to_char(iGoodID, 'FM999999999990') || '))';

    open cv for lvSqlQuery;

    fetch cv
     into ltComponent;

    while cv%found loop
      pipe row(ltComponent);

      fetch cv
       into ltComponent;
    end loop;

    close cv;
  exception
    when no_data_needed then
      return;
  end getComponentsData;

  /**
  * Description
  *    Retourne les informations sur les documents liés à un produit.
  */
  function getAdditionalDocsData(
    inRecID               in COM_IMAGE_FILES.IMF_REC_ID%type
  , ivContext             in COM_IMAGE_FILES.IMF_TABLE%type
  , ivDocType             in varchar2
  , ivDataSource4AdditionalDocs in varchar2
  )
    return SHP_LIB_TYPES.ttAdditionalDocs pipelined
  as
    cv              SYS_REFCURSOR;
    lvSqlQuery      varchar2(4000);
    ltAdditionalDoc SHP_LIB_TYPES.tAdditionalDoc;
  begin
    lvSqlQuery  :=
      'select DOC_GROUP
            , URL
         from TABLE(' ||
      ivDataSource4AdditionalDocs ||
      '(' ||
      to_char(inRecID, 'FM999999999990') ||
      ',' ||
      '''' ||
      ivContext ||
      '''' ||
      ',' ||
      '''' ||
      ivDocType ||
      '''' ||
      ')
      )';

    open cv for lvSqlQuery;

    fetch cv
     into ltAdditionalDoc;

    while cv%found loop
      pipe row(ltAdditionalDoc);

      fetch cv
       into ltAdditionalDoc;
    end loop;

    close cv;
  exception
    when no_data_needed then
      return;
  end getAdditionalDocsData;

  /**
  * Description
  *    Retourne le nom et la valeur de la classification selon son index.
  */
  function getClassifData(
    ivDataSource4Classif      in varchar2
  , iGoodID                   in GCO_GOOD.GCO_GOOD_ID%type
  )
    return SHP_LIB_TYPES.ttClassifValues pipelined
  as
    cv              SYS_REFCURSOR;
    lvSqlQuery      varchar2(4000);
    lClassifValue SHP_LIB_TYPES.tClassifValue;
  begin

    /* Récupération du nom et de la valeur de la classification */
    lvSqlQuery  :=
      'select CLASSIF_INDEX
            , CLASSIF_VALUE
            , CLASSIF_LAN_ISO_CODE_SHORT
            , CLASSIF_DESCRIPTION_01
            , CLASSIF_DESCRIPTION_02
         from TABLE(' ||
      ivDataSource4Classif ||
      '(' ||
      to_char(iGoodID, 'FM999999999990') ||
      ') )';

    open cv for lvSqlQuery;

    fetch cv
     into lClassifValue;

    while cv%found loop

      pipe row(lClassifValue);

      fetch cv
       into lClassifValue;

    end loop;
    close cv;
  exception
    when no_data_needed then
      return;
  end getClassifData;

end SHP_LIB_PRODUCT;
