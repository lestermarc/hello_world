--------------------------------------------------------
--  DDL for Package Body FAL_LIB_ATTRIB
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_ATTRIB" 
is
  /**
  * Description
  *    Retourne la quantité attribuée pour le(les) composant(s) du lot correspondant au
  *    au bien de la position de stock transmis en paramètres
  */
  function getAttribQty(iLotID in FAL_LOT.FAL_LOT_ID%type, iStockPositionID in STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type)
    return number
  as
    lAttribQty number;
  begin
    select nvl(sum(fln.FLN_QTY), 0)
      into lAttribQty
      from FAL_NETWORK_LINK fln
         , FAL_NETWORK_NEED fan
         , FAL_LOT_MATERIAL_LINK lom
         , STM_STOCK_POSITION spo
     where fan.FAL_NETWORK_NEED_ID = fln.FAL_NETWORK_NEED_ID
       and fln.STM_STOCK_POSITION_ID = spo.STM_STOCK_POSITION_ID
       and fan.FAL_LOT_MATERIAL_LINK_ID = lom.FAL_LOT_MATERIAL_LINK_ID
       and lom.GCO_GOOD_ID = spo.GCO_GOOD_ID
       and spo.STM_STOCK_POSITION_ID = iStockPositionID
       and lom.FAL_LOT_ID = iLotID;

    return lAttribQty;
  end getAttribQty;

  /**
  * Description
  *    Retourne l'ID de l'attribution du besoin sur stock.
  */
  function getAttribByStockPosAndNeed(
    iStockPositionID in FAL_NETWORK_LINK.STM_STOCK_POSITION_ID%type
  , iNetworkNeedID   in FAL_NETWORK_NEED.FAL_NETWORK_NEED_ID%type
  )
    return FAL_NETWORK_LINK.FAL_NETWORK_LINK_ID%type
  as
    lNetworkLinkID FAL_NETWORK_LINK.FAL_NETWORK_LINK_ID%type;
  begin
    select FAL_NETWORK_LINK_ID
      into lNetworkLinkID
      from FAL_NETWORK_LINK
     where STM_STOCK_POSITION_ID = iStockPositionID
       and FAL_NETWORK_NEED_ID = iNetworkNeedID
       and rownum = 1;

    return lNetworkLinkID;
  exception
    when no_data_found then
      return null;
  end getAttribByStockPosAndNeed;

  /**
  * Description
  *    Retourne 1 si la position est attribuée au lot
  */
  function isCptBatchAttrib(
    iLotMaterialLinkID  in FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type
  , iCptStockPositionID in STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type
  )
    return number
  as
    lIsCptBatchAttrib number;
  begin
    select sign(count(fln.FAL_NETWORK_LINK_ID) )
      into lIsCptBatchAttrib
      from FAL_NETWORK_LINK fln
         , FAL_NETWORK_NEED fnn
     where fln.FAL_NETWORK_NEED_ID = fnn.FAL_NETWORK_NEED_ID
       and fln.STM_STOCK_POSITION_ID = iCptStockPositionID
       and fnn.FAL_LOT_MATERIAL_LINK_ID = iLotMaterialLinkID;

    return lIsCptBatchAttrib;
  exception
    when no_data_found then
      return 0;
  end isCptBatchAttrib;

  /**
  * Description
  *    Retourne la quantité attribuée sur stock pour le besoin du bien du composant
  *    de lot ou de proposition de lot.
  */
  function getStockAttribQtyByCptGoodNeed(
    iStockID   in STM_STOCK.STM_STOCK_ID%type
  , iCptGoodID in GCO_GOOD.GCO_GOOD_ID%type
  , iLotID     in FAL_LOT.FAL_LOT_ID%type default null
  , iLotPropID in FAL_LOT_PROP.FAL_LOT_PROP_ID%type default null
  )
    return FAL_NETWORK_LINK.FLN_QTY%type
  as
    lStockAttribQty FAL_NETWORK_LINK.FLN_QTY%type   := 0;
  begin
    if iLotID is not null then
      select nvl(sum(FLN.FLN_QTY), 0)
        into lStockAttribQty
        from FAL_NETWORK_LINK FLN
           , STM_STOCK_POSITION SPO
           , FAL_NETWORK_NEED FNN
           , FAL_LOT_MATERIAL_LINK LOM
       where SPO.STM_STOCK_POSITION_ID = FLN.STM_STOCK_POSITION_ID
         and FLN.FAL_NETWORK_NEED_ID = FNN.FAL_NETWORK_NEED_ID
         and FNN.FAL_LOT_MATERIAL_LINK_ID = LOM.FAL_LOT_MATERIAL_LINK_ID
         and SPO.STM_STOCK_ID = iStockID
         and LOM.FAL_LOT_ID = iLotID
         and LOM.GCO_GOOD_ID = iCptGoodID;
    elsif iLotPropID is not null then
      select nvl(sum(FLN.FLN_QTY), 0)
        into lStockAttribQty
        from FAL_NETWORK_LINK FLN
           , STM_STOCK_POSITION SPO
           , FAL_NETWORK_NEED FNN
           , FAL_LOT_MAT_LINK_PROP LOM
       where SPO.STM_STOCK_POSITION_ID = FLN.STM_STOCK_POSITION_ID
         and FLN.FAL_NETWORK_NEED_ID = FNN.FAL_NETWORK_NEED_ID
         and FNN.FAL_LOT_MAT_LINK_PROP_ID = LOM.FAL_LOT_MAT_LINK_PROP_ID
         and SPO.STM_STOCK_ID = iStockID
         and LOM.FAL_LOT_PROP_ID = iLotPropID
         and LOM.GCO_GOOD_ID = iCptGoodID;
    else
      ra('PCS - iLotID or iLotPropID are mandatory to call function FAL_LIB_ATTRIB.getStockAttribQtyByCptGoodNeed');
    end if;

    return lStockAttribQty;
  end getStockAttribQtyByCptGoodNeed;
end FAL_LIB_ATTRIB;
