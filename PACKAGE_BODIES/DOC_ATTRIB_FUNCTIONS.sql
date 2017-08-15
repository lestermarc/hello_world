--------------------------------------------------------
--  DDL for Package Body DOC_ATTRIB_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_ATTRIB_FUNCTIONS" 
is
  /*
  * Description
  * Retourne '1' si l'ensemble des composants d'une position de type 7, 8, 9 ou 10 sont attribués
  */
  function CtrlComponentsAttribs(aPT_PosID DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    qte_bal DOC_POSITION_DETAIL.PDE_BALANCE_QUANTITY%type;
    qte_att FAL_NETWORK_NEED.FAN_STK_QTY%type;
  begin
    select sum(PDE.PDE_BALANCE_QUANTITY)
         , sum(FAN.FAN_STK_QTY)
      into qte_bal
         , qte_att
      from GCO_GOOD GCO
         , GCO_PRODUCT PDT
         , FAL_NETWORK_NEED FAN
         , DOC_POSITION_DETAIL PDE
         , DOC_POSITION POS
     where POS.DOC_DOC_POSITION_ID = aPT_PosID
       and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
       and POS.GCO_GOOD_ID = GCO.GCO_GOOD_ID
       and GCO.GCO_GOOD_ID = PDT.GCO_GOOD_ID
       and PDT.PDT_STOCK_MANAGEMENT = 1
       and PDE.DOC_POSITION_DETAIL_ID = FAN.DOC_POSITION_DETAIL_ID(+);

    if qte_att < qte_bal then
      return 0;
    else
      return 1;
    end if;
  exception
    when no_data_found then
      return 0;
  end CtrlComponentsAttribs;

  /*
  * Description
  * Retourne la quantité maximum "livrable" pour une position de type 7, 8, 9 ou 10
  */
  function GetAttribComponentsQty(aPT_PosID DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    result FAL_NETWORK_NEED.FAN_STK_QTY%type;
  begin
    select trunc(min(FAN.FAN_STK_QTY / decode(POS.POS_UTIL_COEFF, null, 1, 0, 1, POS.POS_UTIL_COEFF) ) )
      into result
      from GCO_GOOD GCO
         , GCO_PRODUCT PDT
         , FAL_NETWORK_NEED FAN
         , DOC_POSITION_DETAIL PDE
         , DOC_POSITION POS
     where POS.DOC_DOC_POSITION_ID = aPT_PosID
       and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
       and POS.GCO_GOOD_ID = GCO.GCO_GOOD_ID
       and GCO.GCO_GOOD_ID = PDT.GCO_GOOD_ID
       and PDT.PDT_STOCK_MANAGEMENT = 1
       and PDE.DOC_POSITION_DETAIL_ID = FAN.DOC_POSITION_DETAIL_ID(+);

    return nvl(result, 0);
  exception
    when no_data_found then
      return 0;
  end GetAttribComponentsQty;

  /*
  * Description
  * Retourne la quantité maximum "livrable" pour une position de type 7, 8, 9 ou 10 sans arrondi
  */
  function GetAttribCPTQuantityReal(aPT_PosID DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    result FAL_NETWORK_NEED.FAN_STK_QTY%type;
  begin
    select min(FAN.FAN_STK_QTY / decode(POS.POS_UTIL_COEFF, null, 1, 0, 1, POS.POS_UTIL_COEFF) )
      into result
      from GCO_GOOD GCO
         , GCO_PRODUCT PDT
         , FAL_NETWORK_NEED FAN
         , DOC_POSITION_DETAIL PDE
         , DOC_POSITION POS
     where POS.DOC_DOC_POSITION_ID = aPT_PosID
       and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
       and POS.GCO_GOOD_ID = GCO.GCO_GOOD_ID
       and GCO.GCO_GOOD_ID = PDT.GCO_GOOD_ID
       and PDT.PDT_STOCK_MANAGEMENT = 1
       and PDE.DOC_POSITION_DETAIL_ID = FAN.DOC_POSITION_DETAIL_ID(+);

    return nvl(result, 0);
  exception
    when no_data_found then
      return 0;
  end GetAttribCPTQuantityReal;

  /*
  * Description
  *   Retourne la quantité attribuée sur une position
  */
  function GetAttribQuantity(aPositionID DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    result FAL_NETWORK_NEED.FAN_STK_QTY%type;
  begin
    select FAN.FAN_STK_QTY
      into result
      from GCO_GOOD GCO
         , GCO_PRODUCT PDT
         , FAL_NETWORK_NEED FAN
         , DOC_POSITION_DETAIL PDE
         , DOC_POSITION POS
     where POS.DOC_POSITION_ID = aPositionID
       and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
       and POS.GCO_GOOD_ID = GCO.GCO_GOOD_ID
       and GCO.GCO_GOOD_ID = PDT.GCO_GOOD_ID
       and PDT.PDT_STOCK_MANAGEMENT = 1
       and PDE.DOC_POSITION_DETAIL_ID = FAN.DOC_POSITION_DETAIL_ID(+);

    return result;
  exception
    when no_data_found then
      return 0;
  end GetAttribQuantity;

  /*
  * Description
  *   Retourne '1' si au moins un composant du PT est attribué même partiellement
  */
  function CtrlComponentsAttribsPartial(aPositionIDPT DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    qte_bal DOC_POSITION_DETAIL.PDE_BALANCE_QUANTITY%type;
    qte_att FAL_NETWORK_NEED.FAN_STK_QTY%type;
  begin
    select sum(PDE.PDE_BALANCE_QUANTITY)
         , sum(FAN.FAN_STK_QTY)
      into qte_bal
         , qte_att
      from GCO_GOOD GCO
         , GCO_PRODUCT PDT
         , FAL_NETWORK_NEED FAN
         , DOC_POSITION_DETAIL PDE
         , DOC_POSITION POS
     where POS.DOC_DOC_POSITION_ID = aPositionIDPT
       and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
       and POS.GCO_GOOD_ID = GCO.GCO_GOOD_ID
       and GCO.GCO_GOOD_ID = PDT.GCO_GOOD_ID
       and PDT.PDT_STOCK_MANAGEMENT = 1
       and PDE.DOC_POSITION_DETAIL_ID = FAN.DOC_POSITION_DETAIL_ID(+);

    if (qte_att = 0) then
      return 0;
    else
      return 1;
    end if;
  exception
    when no_data_found then
      return 0;
  end CtrlComponentsAttribsPartial;

  /*
  * Description
  *   Retourne la quantité déjà déchargé pour une position.
  */
  function GetDischargedQuantity(aPositionID DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    result DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY%type;
  begin
    select   sum(PDE_CPT_SONS.PDE_FINAL_QUANTITY + PDE_CPT_SONS.PDE_BALANCE_QUANTITY_PARENT)
        into result
        from DOC_POSITION_DETAIL PDE_CPT_SONS
           , DOC_POSITION_DETAIL PDE_CPT
       where PDE_CPT.DOC_POSITION_ID = aPositionID
         and PDE_CPT_SONS.DOC_DOC_POSITION_DETAIL_ID(+) = PDE_CPT.DOC_POSITION_DETAIL_ID
    group by PDE_CPT.DOC_POSITION_ID;

    return nvl(result, 0);
  exception
    when no_data_found then
      return 0;
  end GetDischargedQuantity;
end DOC_ATTRIB_FUNCTIONS;
