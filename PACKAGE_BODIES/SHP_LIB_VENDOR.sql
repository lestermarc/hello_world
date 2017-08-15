--------------------------------------------------------
--  DDL for Package Body SHP_LIB_VENDOR
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SHP_LIB_VENDOR" 
as
  /**
  * Description
  *   Cette fonction retourne sous forme binaire le noeud XML "vendor" contenant
  *   les informations relatives au vendeur.
  */
  function getVendorXmltype(
    ivVendorID          in varchar2
  , ivVendorKey         in varchar2
  , ivVendorContentType in varchar2
  , ivVendorLanguage    in varchar2 default 'FR'
  )
    return xmltype
  as
    lxXmlData xmltype;
  begin
    select XMLElement("vendor"
                    , XMLElement("id", ivVendorID)
                    , XMLElement("key", ivVendorKey)
                    , XMLElement("language", ivVendorLanguage)
                    , XMLElement("type", ivVendorContentType)
                     )
      into lxXmlData
      from dual;

    return lxXmlData;
  end;
end SHP_LIB_VENDOR;
