--------------------------------------------------------
--  DDL for Package Body WEB_LIB_CATEG
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WEB_LIB_CATEG" 
is
  /**
  * Description
  *   Vérifie qu'il n'y ait qu'un seul bien par défaut pour une catégorie donnée
  */
  function CheckCategDefaultIntegrity(iGoodId in WEB_GOOD.GCO_GOOD_ID%type, iCategArrayId in WEB_GOOD.WEB_CATEG_ARRAY_ID%type)
    return number
  is
    lCount pls_integer;
  begin
    select count(*)
      into lCount
      from WEB_GOOD
     where WEB_CATEG_ARRAY_ID <> iCategArrayId
       and GCO_GOOD_ID = iGoodId
       and WGO_DEFAULT_CATEG = 1;

    if lCount > 0 then
      return 0;
    else
      return 1;
    end if;
  end CheckCategDefaultIntegrity;
end WEB_LIB_CATEG;
