--------------------------------------------------------
--  DDL for Package Body SHP_LIB_CATEGORY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SHP_LIB_CATEGORY" 
as
  /**
  * Description
  *   Cette fonction retourne sous forme binaire le noeud XML "category_descriptions"
  *   contenant les informations relatives à la descriptions dans les langues
  *   disponibles de la catégorie.
  */
  function getDescriptionsXmlType(inWebCategId in WEB_CATEG.WEB_CATEG_ID%type)
    return xmltype
  is
    lxXmlData xmltype;
  begin
    /* Récupération des aggrégation des descriptions dans les langues existantes */
    select XMLAgg(XMLElement("category_description"
                           , xmlattributes(lan.LANID as "lang")
                           , XMLElement("title", xmlcdata(des.WCD_DESCR) )
                           , XMLElement("description", xmlcdata(des.WCD_LONG_DESCR) )
                            )
                 )
      into lxXmlData
      from WEB_CATEG_DESCR des
         , PCS.PC_LANG lan
     where des.WEB_CATEG_ID = inWebCategId
       and des.PC_LANG_ID = lan.PC_LANG_ID;

    /* Si des descriptions existent, création du noeud "category_descriptions"
       contenant les descriptions (lxXmlData) + l'élément "localizationCode" */
    if lxXmlData is not null then
      select XMLElement("category_descriptions", XMLElement("localization_code", 'N/A'), lxXmlData)
        into lxXmlData
        from dual;

      return lxXmlData;
    end if;

    return null;
  end getDescriptionsXmlType;

  /**
  * Description
  *   Cette fonction retourne sous forme binaire le noeud XML "category" contenant
  *   les informations relatives à une catégorie.
  */
  function getCategoryXmlType(
    inWebCategArrayId         in WEB_CATEG_ARRAY.WEB_CATEG_ARRAY_ID%type
  , ivDataSource4Pictures     in varchar2
  , ivPicturesRootPath        in varchar2
  , ivPicturesWebServerPath   in varchar2
  , inUseWindowsPathDelimiter in number
  )
    return xmltype
  is
    lxXmlData xmltype;
  begin
    select XMLElement("category"
                    , XMLElement("category_reference", SHP_LIB_CATEGORY.getWebCategCode(inWebCategArrayId => inWebCategArrayId) )
                    , XMLElement("parent_category_reference", SHP_LIB_CATEGORY.getWebCategParentCode(inWebCategArrayId => inWebCategArrayId) )
                    , XMLElement("status", 'A')
                    , XMLElement("position", '1')
                    , XMLElement("creation_date", SHP_LIB_UTL.toDate1970Based(idDate => A_DATECRE) )
                    , SHP_LIB_CATEGORY.getDescriptionsXmlType(inWebCategId => SHP_LIB_CATEGORY.getWebCategID(inWebCategArrayId => inWebCategArrayId) )
                    , SHP_LIB_PICTURE.getPicturesXmlType(inRecID                     => SHP_LIB_CATEGORY.getWebCategID(inWebCategArrayId => inWebCategArrayId)
                                                       , ivContext                   => 'WEB_CATEG'
                                                       , ivDataSource4Pictures       => ivDataSource4Pictures
                                                       , ivPicturesRootPath          => ivPicturesRootPath
                                                       , ivPicturesWebServerPath     => ivPicturesWebServerPath
                                                       , ivGlobalPicsXmlElementName  => 'category_pictures'
                                                       , iv1stPicGrpXmlElementName   => 'thumbnail_pictures'
                                                       , iv2ndPicGrpXmlElementName   => 'popup_pictures'
                                                       , iv3thPicGrpXmlElementName   => null
                                                       , iv1stPicGrpTypeName         => 'T'
                                                       , iv2ndPicGrpTypeName         => 'P'
                                                       , iv3thPicGrpTypeName         => null
                                                       , iv1stPicXmlElementName      => 'category_picture'
                                                       , iv2ndPicXmlElementName      => 'category_picture'
                                                       , iv3thPicXmlElementName      => null
                                                       , inUseWindowsPathDelimiter   => inUseWindowsPathDelimiter
                                                       , inAddSizeAttribute          => 1
                                                        )
                     )
      into lxXmlData
      from WEB_CATEG_ARRAY
     where WEB_CATEG_ARRAY_ID = inWebCategArrayId;

    return lxXmlData;
  end getCategoryXmlType;

  /**
  * Description
  *   Cette fonction retourne le contenu du fichier XML sous forme de CLOB contenant
  *   les informations relatives aux catégories.
  */
  function getCategoriesXml(
    ittCategorieIDs           in ID_TABLE_TYPE
  , ivDataSource4Pictures     in varchar2
  , ivPicturesRootPath        in varchar2
  , ivPicturesWebServerPath   in varchar2
  , inUseWindowsPathDelimiter in number
  , ivVendorID                in varchar2
  , ivVendorKey               in varchar2
  , ivVendorContentType       in varchar2
  )
    return clob
  is
    lxXmlData xmltype;
  begin
    select XMLElement("categories"
                    , SHP_LIB_VENDOR.getVendorXmltype(ivVendorID => ivVendorID, ivVendorKey => ivVendorKey, ivVendorContentType => ivVendorContentType)
                    , XMLAgg(SHP_LIB_CATEGORY.getCategoryXmlType(inWebCategArrayId           => tbl.column_value
                                                               , ivDataSource4Pictures       => ivDataSource4Pictures
                                                               , ivPicturesRootPath          => ivPicturesRootPath
                                                               , ivPicturesWebServerPath     => ivPicturesWebServerPath
                                                               , inUseWindowsPathDelimiter   => inUseWindowsPathDelimiter
                                                                )
                            )
                     )
      into lxXmlData
      from table(PCS.IdTableTypeToTable(aIdList => ittCategorieIDs) ) tbl;

    if lxXmlData is not null then
      return lxXmlData.getClobVal();
    else
      return null;
    end if;
  end getCategoriesXml;

  /**
  * Description
  *   Cette fonction retourne le code de la catégorie parent dont l'ID du catalogue
  *   est transmis en paramètre.
  */
  function getWebCategParentCode(inWebCategArrayId in WEB_CATEG_ARRAY.WEB_CATEG_ARRAY_ID%type)
    return WEB_CATEG.WCA_CODE%type
  as
    lvReturn WEB_CATEG.WCA_CODE%type;
  begin
    begin
      select WCA_CODE
        into lvReturn
        from WEB_CATEG
       where WEB_CATEG_ID =
                       (select decode(WCA_LEVEL, 1, null, 2, WEB_CATEG_ID_LEVEL1, 3, WEB_CATEG_ID_LEVEL2, 4, WEB_CATEG_ID_LEVEL3, 5, WEB_CATEG_ID_LEVEL4, null)
                          from WEB_CATEG_ARRAY
                         where WEB_CATEG_ARRAY_ID = inWebCategArrayId);
    exception
      when no_data_found then
        lvReturn  := null;
    end;

    return lvReturn;
  end getWebCategParentCode;

  /**
  * Description
  *   Cette fonction retourne la clef primaire de la catégorie parent dont l'ID
  *   du catalogue est transmis en paramètre.
  */
  function getWebCategParentID(inWebCategArrayId in WEB_CATEG_ARRAY.WEB_CATEG_ARRAY_ID%type)
    return WEB_CATEG_ARRAY.WEB_CATEG_ARRAY_ID%type
  as
    lnReturn WEB_CATEG_ARRAY.WEB_CATEG_ARRAY_ID%type;
  begin
    begin
      select decode(WCA_LEVEL, 1, null, 2, WEB_CATEG_ID_LEVEL1, 3, WEB_CATEG_ID_LEVEL2, 4, WEB_CATEG_ID_LEVEL3, 5, WEB_CATEG_ID_LEVEL4, null)
        into lnReturn
        from WEB_CATEG_ARRAY
       where WEB_CATEG_ARRAY_ID = inWebCategArrayId;
    exception
      when no_data_found then
        lnReturn  := null;
    end;

    return lnReturn;
  end getWebCategParentID;

  /**
  * Description
  *   Cette fonction retourne le code de la catégorie dont l'ID du catalogue est
  *   transmis en paramètre.
  */
  function getWebCategCode(inWebCategArrayId in WEB_CATEG_ARRAY.WEB_CATEG_ARRAY_ID%type)
    return WEB_CATEG.WCA_CODE%type
  is
    lvReturn WEB_CATEG.WCA_CODE%type;
  begin
    begin
      select WCA_CODE
        into lvReturn
        from WEB_CATEG
       where WEB_CATEG_ID =
               (select decode(WCA_LEVEL
                            , 1, WEB_CATEG_ID_LEVEL1
                            , 2, WEB_CATEG_ID_LEVEL2
                            , 3, WEB_CATEG_ID_LEVEL3
                            , 4, WEB_CATEG_ID_LEVEL4
                            , 5, WEB_CATEG_ID_LEVEL5
                            , null
                             )
                  from WEB_CATEG_ARRAY
                 where WEB_CATEG_ARRAY_ID = inWebCategArrayId);
    exception
      when no_data_found then
        lvReturn  := null;
    end;

    return lvReturn;
  end getWebCategCode;

  /**
  * Description
  *   Cette fonction retourne la clef primaire de la catégorie dont l'ID du
  *   catalogue est transmis en paramètre.
  */
  function getWebCategID(inWebCategArrayId in WEB_CATEG_ARRAY.WEB_CATEG_ARRAY_ID%type)
    return WEB_CATEG_ARRAY.WEB_CATEG_ARRAY_ID%type
  is
    lnReturn WEB_CATEG_ARRAY.WEB_CATEG_ARRAY_ID%type;
  begin
    begin
      select decode(WCA_LEVEL, 1, WEB_CATEG_ID_LEVEL1, 2, WEB_CATEG_ID_LEVEL2, 3, WEB_CATEG_ID_LEVEL3, 4, WEB_CATEG_ID_LEVEL4, 5, WEB_CATEG_ID_LEVEL5, null)
        into lnReturn
        from WEB_CATEG_ARRAY
       where WEB_CATEG_ARRAY_ID = inWebCategArrayId;
    exception
      when no_data_found then
        lnReturn  := null;
    end;

    return lnReturn;
  end getWebCategID;
end SHP_LIB_CATEGORY;
