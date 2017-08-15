--------------------------------------------------------
--  DDL for Package Body FAL_LIB_MOVEMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_MOVEMENT" 
is
  /**
  * Description
  *    Retourne la somme des quantités des mouvements de réception du lot (PT + Rebut PT)
  */
  function getReceivedMovementQty(iLotID in FAL_LOT.FAL_LOT_ID%type)
    return STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type
  as
    lReceivedMovementQty STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type;
  begin
    select nvl(sum(smo.SMO_MOVEMENT_QUANTITY), 0)
      into lReceivedMovementQty
      from STM_STOCK_MOVEMENT smo
         , STM_MOVEMENT_KIND mok
     where smo.STM_MOVEMENT_KIND_ID = mok.STM_MOVEMENT_KIND_ID
       and smo.FAL_LOT_ID = iLotID
       and mok.C_MOVEMENT_CODE in('020', '023');

    return lReceivedMovementQty;
  end getReceivedMovementQty;

  /**
  * Description
  *    Retourne la somme des montants des mouvements de réception du lot (PT + Rebut PT)
  */
  function getReceivedMovementPrice(iLotID in FAL_LOT.FAL_LOT_ID%type)
    return STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type
  as
    lReceivedMovementPrice STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type;
  begin
    select nvl(sum(smo.SMO_MOVEMENT_PRICE), 0)
      into lReceivedMovementPrice
      from STM_STOCK_MOVEMENT smo
         , STM_MOVEMENT_KIND mok
     where smo.STM_MOVEMENT_KIND_ID = mok.STM_MOVEMENT_KIND_ID
       and smo.FAL_LOT_ID = iLotID
       and mok.C_MOVEMENT_CODE in('020', '023');

    return lReceivedMovementPrice;
  end getReceivedMovementPrice;
end FAL_LIB_MOVEMENT;
