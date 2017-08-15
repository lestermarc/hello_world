--------------------------------------------------------
--  DDL for Package Body SHP_LIB_PICTURE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SHP_LIB_PICTURE" 
as
  /**
  * Description
  *    Retourne sous forme binaire le noeud XML contenant les deux groupes
  *    d'images de l'élément dont la clef primaire est transmise en paramètre.
  */
  function getPicturesXmlType(
    inRecID                    in COM_IMAGE_FILES.IMF_REC_ID%type
  , ivContext                  in COM_IMAGE_FILES.IMF_TABLE%type
  , ivDataSource4Pictures      in varchar2
  , ivPicturesRootPath         in varchar2
  , ivPicturesWebServerPath    in varchar2
  , ivGlobalPicsXmlElementName in varchar2
  , iv1stPicGrpXmlElementName  in varchar2
  , iv2ndPicGrpXmlElementName  in varchar2
  , iv3thPicGrpXmlElementName  in varchar2
  , iv1stPicGrpTypeName        in varchar2
  , iv2ndPicGrpTypeName        in varchar2
  , iv3thPicGrpTypeName        in varchar2
  , iv1stPicXmlElementName     in varchar2
  , iv2ndPicXmlElementName     in varchar2
  , iv3thPicXmlElementName     in varchar2
  , inUseWindowsPathDelimiter  in number
  , inAddSizeAttribute         in number
  )
    return xmltype
  as
    lNumberOfPictureGroup number  := 0;
    lx1stGrpPics          xmltype;
    lx2ndGrpPics          xmltype;
    lx3thGrpPics          xmltype;
    lxXmlData             xmltype;
  begin
    if iv1stPicGrpXmlElementName is not null then
      lNumberOfPictureGroup  := lNumberOfPictureGroup + 1;

      select XMLElement(evalname(iv1stPicGrpXmlElementName)
                      , XMLAgg(SHP_LIB_PICTURE.getPictureXmlType(inRecID                     => inRecID
                                                               , ivContext                   => ivContext
                                                               , ivDataSource4Pictures       => ivDataSource4Pictures
                                                               , ivPicturesRootPath          => ivPicturesRootPath
                                                               , ivPicturesWebServerPath     => ivPicturesWebServerPath
                                                               , ivPictureGroup              => PICTURE_GROUP
                                                               , ivPictureType               => iv1stPicGrpTypeName
                                                               , ivPicXmlElementName         => iv1stPicXmlElementName
                                                               , inUseWindowsPathDelimiter   => inUseWindowsPathDelimiter
                                                               , inAddSizeAttribute          => inAddSizeAttribute
                                                                )
                              )
                       )
        into lx1stGrpPics
        from (select   PICTURE_GROUP
                  from table(SHP_LIB_PICTURE.getPictureData(inRecID                 => inRecID
                                                          , ivContext               => ivContext
                                                          , ivPictureType           => iv1stPicGrpTypeName
                                                          , ivDataSource4Pictures   => ivDataSource4Pictures
                                                           )
                            )
              group by PICTURE_GROUP);
    end if;

    if iv2ndPicGrpXmlElementName is not null then
      lNumberOfPictureGroup  := lNumberOfPictureGroup + 1;

      select XMLElement(evalname(iv2ndPicGrpXmlElementName)
                      , XMLAgg(SHP_LIB_PICTURE.getPictureXmlType(inRecID                     => inRecID
                                                               , ivContext                   => ivContext
                                                               , ivDataSource4Pictures       => ivDataSource4Pictures
                                                               , ivPicturesRootPath          => ivPicturesRootPath
                                                               , ivPicturesWebServerPath     => ivPicturesWebServerPath
                                                               , ivPictureGroup              => PICTURE_GROUP
                                                               , ivPictureType               => iv2ndPicGrpTypeName
                                                               , ivPicXmlElementName         => iv2ndPicXmlElementName
                                                               , inUseWindowsPathDelimiter   => inUseWindowsPathDelimiter
                                                               , inAddSizeAttribute          => inAddSizeAttribute
                                                                )
                              )
                       )
        into lx2ndGrpPics
        from (select   PICTURE_GROUP
                  from table(SHP_LIB_PICTURE.getPictureData(inRecID                 => inRecID
                                                          , ivContext               => ivContext
                                                          , ivPictureType           => iv2ndPicGrpTypeName
                                                          , ivDataSource4Pictures   => ivDataSource4Pictures
                                                           )
                            )
              group by PICTURE_GROUP);
    end if;

    if iv3thPicGrpXmlElementName is not null then
      lNumberOfPictureGroup  := lNumberOfPictureGroup + 1;

      select XMLElement(evalname(iv3thPicGrpXmlElementName)
                      , XMLAgg(SHP_LIB_PICTURE.getPictureXmlType(inRecID                     => inRecID
                                                               , ivContext                   => ivContext
                                                               , ivDataSource4Pictures       => ivDataSource4Pictures
                                                               , ivPicturesRootPath          => ivPicturesRootPath
                                                               , ivPicturesWebServerPath     => ivPicturesWebServerPath
                                                               , ivPictureGroup              => PICTURE_GROUP
                                                               , ivPictureType               => iv3thPicGrpTypeName
                                                               , ivPicXmlElementName         => iv3thPicXmlElementName
                                                               , inUseWindowsPathDelimiter   => inUseWindowsPathDelimiter
                                                               , inAddSizeAttribute          => inAddSizeAttribute
                                                                )
                              )
                       )
        into lx3thGrpPics
        from (select   PICTURE_GROUP
                  from table(SHP_LIB_PICTURE.getPictureData(inRecID                 => inRecID
                                                          , ivContext               => ivContext
                                                          , ivPictureType           => iv3thPicGrpTypeName
                                                          , ivDataSource4Pictures   => ivDataSource4Pictures
                                                           )
                            )
              group by PICTURE_GROUP);
    end if;

    select case lNumberOfPictureGroup
             when 0 then null
             when 1 then XMLElement(evalname(ivGlobalPicsXmlElementName), lx1stGrpPics)
             when 2 then XMLElement(evalname(ivGlobalPicsXmlElementName), lx1stGrpPics, lx2ndGrpPics)
             when 3 then XMLElement(evalname(ivGlobalPicsXmlElementName), lx1stGrpPics, lx2ndGrpPics, lx3thGrpPics)
           end
      into lxXmlData
      from dual;

    return lxXmlData;
  end getPicturesXmlType;

  /**
  * Description
  *    Retourne sous forme binaire le noeud XML "category_picture"
  *    contenant les informations relatives à une image de la catégorie.
  */
  function getPictureXmlType(
    inRecID                   in COM_IMAGE_FILES.IMF_REC_ID%type
  , ivContext                 in COM_IMAGE_FILES.IMF_TABLE%type
  , ivDataSource4Pictures     in varchar2
  , ivPicturesRootPath        in varchar2
  , ivPicturesWebServerPath   in varchar2
  , ivPictureGroup            in varchar2
  , ivPictureType             in varchar2
  , ivPicXmlElementName       in varchar2
  , inUseWindowsPathDelimiter in number
  , inAddSizeAttribute        in number
  )
    return xmltype
  is
    lxXmlData xmltype;
  begin
    select XMLElement(evalname(ivPicXmlElementName)
                    , xmlattributes(ivPictureType as "type")
                    , XMLAgg(case inAddSizeAttribute
                               when 1 then XMLElement("url"
                                                    , xmlattributes(img.PICTURE_SIZE as "size")
                                                    , xmlcdata(SHP_LIB_UTL.getFormattedURL(ivUrl                       => img.url
                                                                                         , inUseWindowsPathDelimiter   => inUseWindowsPathDelimiter
                                                                                         , ivRootPath                  => ivPicturesRootPath
                                                                                         , ivWebServerPath             => ivPicturesWebServerPath
                                                                                          )
                                                              )
                                                     )
                               else XMLElement("url"
                                             , xmlcdata(SHP_LIB_UTL.getFormattedURL(ivUrl                       => img.url
                                                                                  , inUseWindowsPathDelimiter   => inUseWindowsPathDelimiter
                                                                                  , ivRootPath                  => ivPicturesRootPath
                                                                                  , ivWebServerPath             => ivPicturesWebServerPath
                                                                                   )
                                                       )
                                              )
                             end
                            )
                     )
      into lxXmlData
      from table(SHP_LIB_PICTURE.getPictureData(inRecID                 => inRecID
                                              , ivContext               => ivContext
                                              , ivPictureType           => ivPictureType
                                              , ivDataSource4Pictures   => ivDataSource4Pictures
                                               )
                ) img
     where img.PICTURE_GROUP = ivPictureGroup;

    return lxXmlData;
  end getPictureXmlType;

  /**
  * Description
  *    Retourne les informations sur les images de
  *    L'élément exporté dont la clef primaire est transmise en paramètre
  */
  function getPictureData(
    inRecID               in COM_IMAGE_FILES.IMF_REC_ID%type
  , ivContext             in COM_IMAGE_FILES.IMF_TABLE%type
  , ivPictureType         in varchar2
  , ivDataSource4Pictures in varchar2
  )
    return SHP_LIB_TYPES.ttPictures pipelined
  is
    cv         SYS_REFCURSOR;
    lvSqlQuery varchar2(4000);
    ltPicture  SHP_LIB_TYPES.tPicture;
  begin
    lvSqlQuery  :=
      'select PICTURE_GROUP
            , PICTURE_SIZE
            , URL
         from TABLE(' ||
      ivDataSource4Pictures ||
      '(' ||
      to_char(inRecID, 'FM999999999990') ||
      ',' ||
      '''' ||
      ivContext ||
      '''' ||
      ',' ||
      '''' ||
      ivPictureType ||
      '''' ||
      ')
      )';

    open cv for lvSqlQuery;

    fetch cv
     into ltPicture;

    while cv%found loop
      pipe row(ltPicture);

      fetch cv
       into ltPicture;
    end loop;

    close cv;
  exception
    when no_data_needed then
      return;
  end getPictureData;
end SHP_LIB_PICTURE;
