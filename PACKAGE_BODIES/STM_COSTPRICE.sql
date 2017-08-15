--------------------------------------------------------
--  DDL for Package Body STM_COSTPRICE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_COSTPRICE" 
is
  /**
  * Description
  *    Mise à jour de tous les prix de revient d'un bien selon un mouvement de stock
  */
  procedure Update_Costprices(
    aMovementId     in     number
  , aGoodId         in     number
  , aStockId        in     number
  , aMovementKindId in     number
  , aMoveQty        in     number
  , aMoveValue      in     number
  , aPrcsUpdated    out    number
  , aOldQtyPrcs     out    number
  , aOldValuePrcs   out    number
  , aOldPrcs        out    number
  , aNewQtyPrcs     out    number
  , aNewValuePrcs   out    number
  , aNewPrcs        out    number
  , aPrcsValue      in out number
  )
  is
    vEntityMovement FWK_I_TYP_STM_ENTITY.tStockMovement;
  begin
    -- Maj PRCS
    vEntityMovement.GCO_GOOD_ID                     := aGoodId;
    vEntityMovement.STM_STOCK_ID                    := aStockId;
    vEntityMovement.STM_MOVEMENT_KIND_ID            := aMovementKindId;
    vEntityMovement.SMO_MOVEMENT_QUANTITY           := aMoveQty;
    vEntityMovement.SMO_MOVEMENT_PRICE              := aMoveValue;
    vEntityMovement.SMO_PRCS_ADDED_QUANTITY_BEFORE  := aOldQtyPrcs;
    vEntityMovement.SMO_PRCS_ADDED_VALUE_BEFORE     := aOldValuePrcs;
    vEntityMovement.SMO_PRCS_BEFORE                 := aOldPrcs;
    STM_PRC_COSTPRICE.updateWAC(vEntityMovement);
    aPrcsUpdated                                    := vEntityMovement.SMO_PRCS_UPDATED;
    aOldQtyPrcs                                     := vEntityMovement.SMO_PRCS_ADDED_QUANTITY_BEFORE;
    aOldValuePrcs                                   := vEntityMovement.SMO_PRCS_ADDED_VALUE_BEFORE;
    aOldPrcs                                        := vEntityMovement.SMO_PRCS_BEFORE;
    aNewQtyPrcs                                     := vEntityMovement.SMO_PRCS_ADDED_QUANTITY_AFTER;
    aNewValuePrcs                                   := vEntityMovement.SMO_PRCS_ADDED_VALUE_AFTER;
    aNewPrcs                                        := vEntityMovement.SMO_PRCS_AFTER;
    aPrcsValue                                      := vEntityMovement.SMO_PRCS_VALUE;
    -- Mise à jour des prix de revient calculés
    STM_PRC_COSTPRICE.updateCCP(vEntityMovement);
  end Update_Costprices;

  /**
  * Description
  *    Mise à jour du prix de revient calculé standard d'un bien
  *    selon un mouvement de stock
  */
  procedure GCO_Update_Costprice(
    aGoodId         in     number
  , aStockId        in     number
  , aMovementKindId in     number
  , aMoveQty        in     number
  , aMoveValue      in     number
  , aPriceUpdated   out    number
  , aOldQtyPrcs     in out number
  , aOldValuePrcs   in out number
  , aOldPrcs        in out number
  , aNewQtyPrcs     out    number
  , aNewValuePrcs   out    number
  , aNewPrcs        out    number
  , aPrcsValue      in out number
  , aVirtual        in     boolean := false
  , aUpdateMvt      in     boolean := false
  , aUpdatePrcs     in     number := null
  , aPosDetailId    in     number := null
  )
  is
    vEntityMovement FWK_I_TYP_STM_ENTITY.tStockMovement;
  begin
    vEntityMovement.GCO_GOOD_ID                     := aGoodId;
    vEntityMovement.STM_STOCK_ID                    := aStockId;
    vEntityMovement.STM_MOVEMENT_KIND_ID            := aMovementKindId;
    vEntityMovement.SMO_MOVEMENT_QUANTITY           := aMoveQty;
    vEntityMovement.SMO_MOVEMENT_PRICE              := aMoveValue;
    vEntityMovement.SMO_PRCS_ADDED_QUANTITY_BEFORE  := aOldQtyPrcs;
    vEntityMovement.SMO_PRCS_ADDED_VALUE_BEFORE     := aOldValuePrcs;
    vEntityMovement.SMO_PRCS_BEFORE                 := aOldPrcs;
    vEntityMovement.SMO_UPDATE_PRCS                 := aUpdatePrcs;
    vEntityMovement.SMO_PRCS_VALUE                  := aPrcsValue;
    vEntityMovement.DOC_POSITION_DETAIL_ID          := aPosDetailId;
    STM_PRC_COSTPRICE.updateWAC(vEntityMovement, aVirtual, aUpdateMvt);
    aPriceUpdated                                   := vEntityMovement.SMO_PRCS_UPDATED;
    aOldQtyPrcs                                     := vEntityMovement.SMO_PRCS_ADDED_QUANTITY_BEFORE;
    aOldValuePrcs                                   := vEntityMovement.SMO_PRCS_ADDED_VALUE_BEFORE;
    aOldPrcs                                        := vEntityMovement.SMO_PRCS_BEFORE;
    aNewQtyPrcs                                     := vEntityMovement.SMO_PRCS_ADDED_QUANTITY_AFTER;
    aNewValuePrcs                                   := vEntityMovement.SMO_PRCS_ADDED_VALUE_AFTER;
    aNewPrcs                                        := vEntityMovement.SMO_PRCS_AFTER;
    aPrcsValue                                      := vEntityMovement.SMO_PRCS_VALUE;
  end GCO_Update_Costprice;

  /**
  * Description
  *    Mise à jour de tous les prix de revient calculés de la table PTC_CALC_COSTPRICE
  *    d'un bien selon un mouvement de stock
  */
  procedure PTC_Update_Costprice(
    aMovementId     in number
  , aGoodId         in number
  , aMovementKindId in number
  , aMoveQty        in number
  , aMoveValue      in number
  )
  is
    vEntityMovement FWK_I_TYP_STM_ENTITY.tStockMovement;
  begin
    vEntityMovement.GCO_GOOD_ID            := aGoodId;
    vEntityMovement.STM_MOVEMENT_KIND_ID   := aMovementKindId;
    vEntityMovement.SMO_MOVEMENT_QUANTITY  := aMoveQty;
    vEntityMovement.SMO_MOVEMENT_PRICE     := aMoveValue;
    STM_PRC_COSTPRICE.updateCCP(vEntityMovement);
  end PTC_Update_Costprice;
end STM_COSTPRICE;
