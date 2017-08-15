--------------------------------------------------------
--  DDL for Package Body SHP_LIB_USER
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SHP_LIB_USER" 
as
  /**
  * function getGroupXmlType
  * Description
  *   Retourne sous forme binaire le noeud XML "user_group"
  *   contenant les informations relatives à un groupe utilisateur Web.
  */
  function getGroupXmlType(iWebGroupID in WEB_GROUP.WEB_GROUP_ID%type)
    return xmltype
  is
    lxXmlData xmltype;
  begin
    select XMLElement("user_group", XMLElement("user_group_id", WEB_GROUP_ID), XMLElement("name", WEG_GROUP_NAME), XMLElement("status", 'A') )
      into lxXmlData
      from WEB_GROUP
     where WEB_GROUP_ID = iWebGroupID;

    return lxXmlData;
  end getGroupXmlType;

  /**
  * Description
  *   Retourne le contenu du fichier XML sous forme de CLOB contenant
  *   les informations relatives aux groupes utilisateurs
  */
  function getGroupsXml(ittGroupIDs in ID_TABLE_TYPE, ivVendorID in varchar2, ivVendorKey in varchar2, ivVendorContentType in varchar2)
    return clob
  is
    lxXmlData xmltype;
  begin
    select XMLElement("user_groups"
                    , SHP_LIB_VENDOR.getVendorXmltype(ivVendorID => ivVendorID, ivVendorKey => ivVendorKey, ivVendorContentType => ivVendorContentType)
                    , XMLAgg(SHP_LIB_USER.getGroupXmlType(iWebGroupID => tbl.column_value) )
                     )
      into lxXmlData
      from table(PCS.IdTableTypeToTable(aIdList => ittGroupIDs) ) tbl;

    if lxXmlData is not null then
      return lxXmlData.getClobVal();
    else
      return null;
    end if;
  end getGroupsXml;

  /**
  * Description
  *   Retourne sous forme binaire le noeud XML "user_info"
  *   contenant les informations relatives de l'utilisateur Web.
  */
  function getUserUserinfoXmlType(
    iWebUserID                 in PCS.PC_USER.PC_USER_ID%type
  , iDataSource4UserInfos      in varchar2
  , iPhoneDicCommunicationID   in DIC_COMMUNICATION_TYPE.DIC_COMMUNICATION_TYPE_ID%type
  , iFaxDicCommunicationID     in DIC_COMMUNICATION_TYPE.DIC_COMMUNICATION_TYPE_ID%type
  , iWebSiteDicCommunicationID in DIC_COMMUNICATION_TYPE.DIC_COMMUNICATION_TYPE_ID%type
  )
    return xmltype
  is
    lxXmlData xmltype;
  begin
    select XMLAgg(XMLElement("user_info"
                           , XMLElement("title", tbl.TITLE)
                           , XMLElement("firstname", tbl.FIRSTNAME)
                           , XMLElement("lastname", tbl.LASTNAME)
                           , XMLElement("company", tbl.COMPANY)
                           , XMLElement("email", tbl.EMAIL)
                           , XMLElement("phone", tbl.PHONE)
                           , XMLElement("fax", tbl.FAX)
                           , XMLElement("website", tbl.WEBSITE)
                           , XMLElement("tax_exempt", tbl.TAX_EXEMPT)
                           , XMLElement("language", upper(tbl.USER_LANGUAGE) )
                           , XMLElement("currency", upper(tbl.CURRENCY) )
                           , XMLElement("displayable_permission_level", upper(tbl.DISPLAYABLE_PERMISSION_LEVEL) )
                           , XMLElement("orderable_permission_level", upper(tbl.ORDERABLE_PERMISSION_LEVEL) )
                            )
                 )
      into lxXmlData
      from table(SHP_LIB_USER.getUserInfosData(iWebUserID                   => iWebUserID
                                             , iDataSource4UserInfos        => iDataSource4UserInfos
                                             , iPhoneDicCommunicationID     => iPhoneDicCommunicationID
                                             , iFaxDicCommunicationID       => iFaxDicCommunicationID
                                             , iWebSiteDicCommunicationID   => iWebSiteDicCommunicationID
                                              )
                ) tbl;

    return lxXmlData;
  end getUserUserinfoXmlType;

  /**
  * Description
  *   Retourne sous forme binaire le noeud XML "credentials" contenant les
  *   informations de connexion de l'utilisateur Web..
  */
  function getUserCredentialsXmlType(iWebUserID in PCS.PC_USER.PC_USER_ID%type)
    return xmltype
  is
    lxXmlData xmltype;
  begin
    select XMLElement("credentials"
                    , XMLElement("user_type", SHP_LIB_USER.GetWebUserType(iWebUserID => WEB_USER_ID) )
                    , XMLElement("status", SHP_LIB_USER.GetWebUserStatus(iWebUserID => WEB_USER_ID) )
                    , XMLElement("login", WEU_LOGIN_NAME)
                    , XMLElement("password", PCS.PC_LIB_CRYPTOADM_SYS.EncodeH(iv_value => WEU_PASSWORD_VALUE) )
                    , XMLElement("shop_userid", null)
                    , XMLElement("external_userid", WEB_USER_ID)
                    , XMLElement("registration_date", SHP_LIB_UTL.toDate1970Based(A_DATECRE) )
                    , SHP_LIB_USER.GetUserGroupsXmlType(iWebUserID => WEB_USER_ID)
                     )
      into lxXmlData
      from WEB_USER
     where WEB_USER_ID = iWebUserID;

    return lxXmlData;
  end getUserCredentialsXmlType;

  /**
  * Description
  *   Retourne le groupe auquel appartient l'utilisateur Web et dont le nom correspond
  *   au DIC_TARIFF_ID du PAC_CUSTOM_PARTNER_ID lié à l'utilisateur Web.
  */
  function getUserGroupsXmlType(iWebUserID in PCS.PC_USER.PC_USER_ID%type)
    return xmltype
  is
    lxXmlData xmltype;
  begin
    select distinct XMLElement("user_groups", XMLAgg(XMLElement("user_group", XMLElement("user_group_id", weg.WEB_GROUP_ID), XMLElement("status", 'A') ) ) )
               into lxXmlData
               from WEB_GROUP weg
                  , WEB_USER_GROUP_ROLE wugr
                  , WEB_USER weu
                  , PAC_CUSTOM_PARTNER cus
                  , DIC_TARIFF dic
              where wugr.WEB_GROUP_ID = weg.WEB_GROUP_ID
                and weu.WEB_USER_ID = wugr.WEB_USER_ID
                and weu.WEB_USER_ID = iWebUserID
                and cus.PAC_CUSTOM_PARTNER_ID = weu.PAC_CUSTOM_PARTNER_ID
                and upper(weg.WEG_GROUP_NAME) = upper(dic.DIC_TARIFF_ID)
                and upper(cus.DIC_TARIFF_ID) = upper(dic.DIC_TARIFF_ID);

    return lxXmlData;
  end getUserGroupsXmlType;

  /**
  * Description
  *   retourne sous forme binaire le noeud XML "billing_address" contenant l'adresse
  *   principale de l'utilisateur Web
  */
  function getUserBillingAddressXmlType(iWebUserID in PCS.PC_USER.PC_USER_ID%type, idataSource4BillingAddress in varchar2)
    return xmltype
  is
    lxXmlData xmltype;
  begin
    select XMLElement("billing_address"
                    , XMLElement("title", TITLE)
                    , XMLElement("firstname", FIRSTNAME)
                    , XMLElement("lastname", LASTNAME)
                    , XMLElement("address", ADDRESS)
                    , XMLElement("address2", ADDRESS2)
                    , XMLElement("zipcode", ZIPCODE)
                    , XMLElement("city", CITY)
                    , XMLElement("state", STATE)
                    , XMLElement("country", COUNTRY)
                    , XMLElement("phone", PHONE)
                     )
      into lxXmlData
      from table(SHP_LIB_USER.getUserBillingAddressData(iWebUserID => iWebUserID, idataSource4BillingAddress => idataSource4BillingAddress) );

    return lxXmlData;
  exception
    when no_data_found then
      select XMLElement("billing_address"
                      , XMLElement("title", null)
                      , XMLElement("firstname", null)
                      , XMLElement("lastname", null)
                      , XMLElement("address", null)
                      , XMLElement("address2", null)
                      , XMLElement("zipcode", null)
                      , XMLElement("city", null)
                      , XMLElement("state", null)
                      , XMLElement("country", null)
                      , XMLElement("phone", null)
                       )
        into lxXmlData
        from dual;

      return lxXmlData;
  end getUserBillingAddressXmlType;

  /**
  * Description
  *   Retourne sous forme binaire le noeud XML "shipping_address" contenant
  *   l'adresse de l'utilisateur Web correspondant au type transmis.
  */
  function getUserShippingAddressXmlType(
    iWebUserID                  in PCS.PC_USER.PC_USER_ID%type
  , iDicAddressTypeID           in PAC_ADDRESS.DIC_ADDRESS_TYPE_ID%type
  , idataSource4ShippingAddress in varchar2
  )
    return xmltype
  is
    lxXmlData xmltype;
  begin
    select XMLElement("shipping_address"
                    , XMLElement("title", TITLE)
                    , XMLElement("firstname", FIRSTNAME)
                    , XMLElement("lastname", LASTNAME)
                    , XMLElement("address", ADDRESS)
                    , XMLElement("address2", ADDRESS2)
                    , XMLElement("zipcode", ZIPCODE)
                    , XMLElement("city", CITY)
                    , XMLElement("state", STATE)
                    , XMLElement("country", COUNTRY)
                    , XMLElement("phone", PHONE)
                     )
      into lxXmlData
      from table(SHP_LIB_USER.getUserShippingAddressData(iWebUserID                    => iWebUserID
                                                       , iDicAddressTypeID             => iDicAddressTypeID
                                                       , idataSource4ShippingAddress   => idataSource4ShippingAddress
                                                        )
                );

    return lxXmlData;
  exception
    when no_data_found then
      select XMLElement("shipping_address"
                      , XMLElement("title", null)
                      , XMLElement("firstname", null)
                      , XMLElement("lastname", null)
                      , XMLElement("address", null)
                      , XMLElement("address2", null)
                      , XMLElement("zipcode", null)
                      , XMLElement("city", null)
                      , XMLElement("state", null)
                      , XMLElement("country", null)
                      , XMLElement("phone", null)
                       )
        into lxXmlData
        from dual;

      return lxXmlData;
  end getUserShippingAddressXmlType;

  /**
  * Description
  *   Retourne sous forme binaire le noeud XML "user" contenant l'ensemble des infos
  *   sur l'utilisateur Web.
  */
  function getUserXmlType(
    iWebUserID                  in PCS.PC_USER.PC_USER_ID%type
  , iDicAddressTypeID           in PAC_ADDRESS.DIC_ADDRESS_TYPE_ID%type
  , iDataSource4UserInfos       in varchar2
  , idataSource4BillingAddress  in varchar2
  , idataSource4ShippingAddress in varchar2
  , iPhoneDicCommunicationID    in DIC_COMMUNICATION_TYPE.DIC_COMMUNICATION_TYPE_ID%type
  , iFaxDicCommunicationID      in DIC_COMMUNICATION_TYPE.DIC_COMMUNICATION_TYPE_ID%type
  , iWebSiteDicCommunicationID  in DIC_COMMUNICATION_TYPE.DIC_COMMUNICATION_TYPE_ID%type
  )
    return xmltype
  is
    lxXmlData xmltype;
  begin
    select XMLElement("user"
                    , SHP_LIB_USER.getUserUserinfoXmlType(iWebUserID                   => WEB_USER_ID
                                                        , iDataSource4UserInfos        => iDataSource4UserInfos
                                                        , iPhoneDicCommunicationID     => iPhoneDicCommunicationID
                                                        , iFaxDicCommunicationID       => iFaxDicCommunicationID
                                                        , iWebSiteDicCommunicationID   => iWebSiteDicCommunicationID
                                                         )
                    , SHP_LIB_USER.getUserCredentialsXmlType(iWebUserID => WEB_USER_ID)
                    , SHP_LIB_USER.getUserBillingAddressXmlType(iWebUserID => WEB_USER_ID, idataSource4BillingAddress => idataSource4BillingAddress)
                    , SHP_LIB_USER.getUserShippingAddressXmlType(iWebUserID                    => WEB_USER_ID
                                                               , iDicAddressTypeID             => iDicAddressTypeID
                                                               , idataSource4ShippingAddress   => idataSource4ShippingAddress
                                                                )
                     )
      into lxXmlData
      from WEB_USER
     where WEB_USER_ID = iWebUserID;

    return lxXmlData;
  end getUserXmlType;

  /**
  * function
  *   Cette fonction retourne le contenu du noeud XML <user> sous forme de CLOB.
  */
  function getUsersXml(
    ittUserIDs                  in ID_TABLE_TYPE
  , ivVendorID                  in varchar2
  , ivVendorKey                 in varchar2
  , ivVendorContentType         in varchar2
  , ivDicAddressTypeID          in PAC_ADDRESS.DIC_ADDRESS_TYPE_ID%type
  , iDataSource4UserInfos       in varchar2
  , idataSource4BillingAddress  in varchar2
  , idataSource4ShippingAddress in varchar2
  , iPhoneDicCommunicationID    in DIC_COMMUNICATION_TYPE.DIC_COMMUNICATION_TYPE_ID%type
  , iFaxDicCommunicationID      in DIC_COMMUNICATION_TYPE.DIC_COMMUNICATION_TYPE_ID%type
  , iWebSiteDicCommunicationID  in DIC_COMMUNICATION_TYPE.DIC_COMMUNICATION_TYPE_ID%type
  )
    return clob
  is
    lxXmlData xmltype;
  begin
    select XMLElement("users"
                    , SHP_LIB_VENDOR.getVendorXmltype(ivVendorID => ivVendorID, ivVendorKey => ivVendorKey, ivVendorContentType => ivVendorContentType)
                    , XMLAgg(SHP_LIB_USER.getUserXmlType(iWebUserID                    => tbl.column_value
                                                       , iDicAddressTypeID             => ivDicAddressTypeID
                                                       , iDataSource4UserInfos         => iDataSource4UserInfos
                                                       , idataSource4BillingAddress    => idataSource4BillingAddress
                                                       , idataSource4ShippingAddress   => idataSource4ShippingAddress
                                                       , iPhoneDicCommunicationID      => iPhoneDicCommunicationID
                                                       , iFaxDicCommunicationID        => iFaxDicCommunicationID
                                                       , iWebSiteDicCommunicationID    => iWebSiteDicCommunicationID
                                                        )
                            )
                     )
      into lxXmlData
      from table(PCS.IdTableTypeToTable(aIdList => ittUserIDs) ) tbl;

    if lxXmlData is not null then
      return lxXmlData.getClobVal();
    else
      return null;
    end if;
  end getUsersXml;

  /**
  * Description
  *   Retourne le type de l'utilisateur Web (A = Admin)
  */
  function getWebUserType(iWebUserID in PCS.PC_USER.PC_USER_ID%type)
    return varchar2
  is
    lUserType varchar2(10);
  begin
    select case sign(count(wugr.WEB_USER_ID) )
             when 1 then 'A'
             else 'C'
           end
      into lUserType
      from WEB_USER_GROUP_ROLE wugr
         , WEB_ROLE wer
     where wugr.WEB_ROLE_ID = wer.WEB_ROLE_ID
       and wugr.WEB_USER_ID = iWebUserID
       and upper(wer.WER_ROLE_NAME) like 'ADMIN%';

    return lUserType;
  exception
    when no_data_found then
      return 'C';
  end getWebUserType;

  /**
  * Description
  *   Retourne le statut de l'utilisateur Web.
  */
  function getWebUserStatus(iWebUserID in PCS.PC_USER.PC_USER_ID%type)
    return varchar2
  is
    lvWebUserStatus varchar2(100);
  begin
    select case C_PARTNER_STATUS
             when '1' then 'A'
             else 'D'
           end
      into lvWebUserStatus
      from PAC_CUSTOM_PARTNER
     where PAC_CUSTOM_PARTNER_ID = getCustomPartnerID(iWebUserID => iWebUserID);

    return lvWebUserStatus;
  exception
    when no_data_found then
      return 'D';
  end getWebUserStatus;

  /**
  * Description
  *   Retourne l'ID de la personne (PAC_PERSON_ID) liée à l'utilisateur Web
  */
  function getCustomPartnerID(iWebUserID in PCS.PC_USER.PC_USER_ID%type)
    return PAC_PERSON.PAC_PERSON_ID%type
  as
    lPersonID PAC_PERSON.PAC_PERSON_ID%type;
  begin
    select PAC_CUSTOM_PARTNER_ID
      into lPersonID
      from WEB_USER
     where WEB_USER_ID = iWebUserID;

    return lPersonID;
  exception
    when no_data_found then
      return null;
  end getCustomPartnerID;

  /**
  * Description
  *    Retourne les informations sur l'utilisateur Web.
  */
  function getUserInfosData(
    iWebUserID                 in PCS.PC_USER.PC_USER_ID%type
  , iDataSource4UserInfos      in varchar2
  , iPhoneDicCommunicationID   in DIC_COMMUNICATION_TYPE.DIC_COMMUNICATION_TYPE_ID%type
  , iFaxDicCommunicationID     in DIC_COMMUNICATION_TYPE.DIC_COMMUNICATION_TYPE_ID%type
  , iWebSiteDicCommunicationID in DIC_COMMUNICATION_TYPE.DIC_COMMUNICATION_TYPE_ID%type
  )
    return SHP_LIB_TYPES.ttUserInfos pipelined
  is
    cv         SYS_REFCURSOR;
    lvSqlQuery varchar2(4000);
    ltUserInfo SHP_LIB_TYPES.tUserInfo;
  begin
    lvSqlQuery  :=
      'select TITLE
            , FIRSTNAME
            , LASTNAME
            , COMPANY
            , EMAIL
            , PHONE
            , FAX
            , WEBSITE
            , TAX_EXEMPT
            , USER_LANGUAGE
            , CURRENCY
            , DISPLAYABLE_PERMISSION_LEVEL
            , ORDERABLE_PERMISSION_LEVEL
         from TABLE(' ||
      iDataSource4UserInfos ||
      '(' ||
      to_char(iWebUserID, 'FM999999999990') ||
      ', ''' ||
      iPhoneDicCommunicationID ||
      ''', ''' ||
      iFaxDicCommunicationID ||
      ''', ''' ||
      iWebSiteDicCommunicationID ||
      '''))';

    open cv for lvSqlQuery;

    fetch cv
     into ltUserInfo;

    while cv%found loop
      pipe row(ltUserInfo);

      fetch cv
       into ltUserInfo;
    end loop;

    close cv;
  exception
    when no_data_needed then
      return;
  end getUserInfosData;

  /**
  * Description
  *    Retourne les informations sur l'addresse de facturation de l'utilisateur Web
  */
  function getUserBillingAddressData(iWebUserID in PCS.PC_USER.PC_USER_ID%type, idataSource4BillingAddress in varchar2)
    return SHP_LIB_TYPES.ttUserAddresses pipelined
  is
    cv                   SYS_REFCURSOR;
    lvSqlQuery           varchar2(4000);
    ltUserBillingAddress SHP_LIB_TYPES.tUserAddress;
  begin
    lvSqlQuery  :=
      'select TITLE
            , FIRSTNAME
            , LASTNAME
            , ADDRESS
            , ADDRESS2
            , ZIPCODE
            , CITY
            , STATE
            , COUNTRY
            , PHONE
         from TABLE(' ||
      idataSource4BillingAddress ||
      '(' ||
      to_char(iWebUserID, 'FM999999999990') ||
      '))';

    open cv for lvSqlQuery;

    fetch cv
     into ltUserBillingAddress;

    while cv%found loop
      pipe row(ltUserBillingAddress);

      fetch cv
       into ltUserBillingAddress;
    end loop;

    close cv;
  exception
    when no_data_needed then
      return;
  end getUserBillingAddressData;

  /**
  * Description
  *    Retourne les informations sur l'addresse d'expédition de l'utilisateur Web
  */
  function getUserShippingAddressData(
    iWebUserID                  in PCS.PC_USER.PC_USER_ID%type
  , iDicAddressTypeID           in PAC_ADDRESS.DIC_ADDRESS_TYPE_ID%type
  , idataSource4ShippingAddress in varchar2
  )
    return SHP_LIB_TYPES.ttUserAddresses pipelined
  is
    cv                    SYS_REFCURSOR;
    lvSqlQuery            varchar2(4000);
    ltUserShippingAddress SHP_LIB_TYPES.tUserAddress;
  begin
    lvSqlQuery  :=
      'select TITLE
            , FIRSTNAME
            , LASTNAME
            , ADDRESS
            , ADDRESS2
            , ZIPCODE
            , CITY
            , STATE
            , COUNTRY
            , PHONE
         from TABLE(' ||
      idataSource4ShippingAddress ||
      '(' ||
      to_char(iWebUserID, 'FM999999999990') ||
      ', ''' ||
      iDicAddressTypeID ||
      '''))';

    open cv for lvSqlQuery;

    fetch cv
     into ltUserShippingAddress;

    while cv%found loop
      pipe row(ltUserShippingAddress);

      fetch cv
       into ltUserShippingAddress;
    end loop;

    close cv;
  exception
    when no_data_needed then
      return;
  end getUserShippingAddressData;
end SHP_LIB_USER;
