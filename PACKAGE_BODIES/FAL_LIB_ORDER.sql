--------------------------------------------------------
--  DDL for Package Body FAL_LIB_ORDER
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_ORDER" 
is
  /**
  * Description
  *    Cette function retourne la clef primaire du bien lié à l'ordre de fabrication
  *    dont la clef primaire est transmise en paramètre.
  */
  function getGcoGoodID(inFalOrderID in FAL_ORDER.FAL_ORDER_ID%type)
    return GCO_GOOD.GCO_GOOD_ID%type
  as
    lnGcoGoodID GCO_GOOD.GCO_GOOD_ID%type;
  begin
    select GCO_GOOD_ID
      into lnGcoGoodID
      from FAL_ORDER
     where FAL_ORDER_ID = inFalOrderID;

    return lnGcoGoodID;
  end getGcoGoodID;
end FAL_LIB_ORDER;
