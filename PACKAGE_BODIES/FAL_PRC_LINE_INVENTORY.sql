--------------------------------------------------------
--  DDL for Package Body FAL_PRC_LINE_INVENTORY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_LINE_INVENTORY" 
is
  /**
  * Description
  *    Cette procédure va créer une ligne d'inventaire.
  */
  procedure createLine(
    inFalAlloyInventoryID in FAL_LINE_INVENTORY.FAL_ALLOY_INVENTORY_ID%type
  , inFalPositionID       in FAL_LINE_INVENTORY.FAL_POSITION_ID%type
  , inGcoGoodID           in FAL_LINE_INVENTORY.GCO_GOOD_ID%type
  , inGcoAlloyID          in FAL_LINE_INVENTORY.GCO_ALLOY_ID%type
  , inFliSelect           in FAL_LINE_INVENTORY.FLI_SELECT%type
  , ivDicOperatorID       in FAL_LINE_INVENTORY.DIC_OPERATOR_ID%type
  , idFliDateInvent       in FAL_LINE_INVENTORY.FLI_DATE_INVENT%type
  , ivCLineStatus         in FAL_LINE_INVENTORY.C_LINE_STATUS%type
  , inFliQtyInventCalcul  in FAL_LINE_INVENTORY.FLI_QTY_INVENT_CALCUL%type
  , inFliQtyInvent        in FAL_LINE_INVENTORY.FLI_QTY_INVENT%type
  , inFliInventCalcul     in FAL_LINE_INVENTORY.FLI_INVENT_CALCUL%type
  , inFliInvent           in FAL_LINE_INVENTORY.FLI_INVENT%type
  )
  as
    ltCRUD_FalLineInventory FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalLineInventory, ltCRUD_FalLineInventory, true);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalLineInventory, 'FAL_ALLOY_INVENTORY_ID', inFalAlloyInventoryID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalLineInventory, 'FAL_POSITION_ID', inFalPositionID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalLineInventory, 'GCO_GOOD_ID', inGcoGoodID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalLineInventory, 'GCO_ALLOY_ID', inGcoAlloyID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalLineInventory, 'FLI_SELECT', inFliSelect);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalLineInventory, 'DIC_OPERATOR_ID', ivDicOperatorID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalLineInventory, 'FLI_DATE_INVENT', idFliDateInvent);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalLineInventory, 'C_LINE_STATUS', ivCLineStatus);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalLineInventory, 'FLI_QTY_INVENT_CALCUL', inFliQtyInventCalcul);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalLineInventory, 'FLI_QTY_INVENT', inFliQtyInvent);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalLineInventory, 'FLI_INVENT_CALCUL', inFliInventCalcul);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalLineInventory, 'FLI_INVENT', inFliInvent);
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_FalLineInventory);
    FWK_I_MGT_ENTITY.Release(ltCRUD_FalLineInventory);
  end createLine;

  /**
  * Description
  *    Cette procédure calcule le poids corrigé et la quantité corrigée d'une ligne d'inventaire
  */
  procedure beforeInsUpdLineInventory(iotCRUD_FalLineInventory in out nocopy fwk_i_typ_definition.t_crud_def)
  as
  begin
    -- Calcul de la correction de quantité si quantité calculée et quantité inventaire ne sont pas nulles.
    if     not FWK_I_MGT_ENTITY_DATA.IsNull(iotCRUD_FalLineInventory, 'FLI_QTY_INVENT_CALCUL')
       and not FWK_I_MGT_ENTITY_DATA.IsNull(iotCRUD_FalLineInventory, 'FLI_QTY_INVENT') then
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotCRUD_FalLineInventory
                                    , 'FLI_QTY_CORRECT'
                                    , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotCRUD_FalLineInventory, 'FLI_QTY_INVENT') -
                                      FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotCRUD_FalLineInventory, 'FLI_QTY_INVENT_CALCUL')
                                     );
    end if;

    -- Calcul de la correction de poids si poids calculé et poids inventaire ne sont pas nulles.
    if     not FWK_I_MGT_ENTITY_DATA.IsNull(iotCRUD_FalLineInventory, 'FLI_INVENT_CALCUL')
       and not FWK_I_MGT_ENTITY_DATA.IsNull(iotCRUD_FalLineInventory, 'FLI_INVENT') then
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotCRUD_FalLineInventory
                                    , 'FLI_CORRECT'
                                    , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotCRUD_FalLineInventory, 'FLI_INVENT') -
                                      FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotCRUD_FalLineInventory, 'FLI_INVENT_CALCUL')
                                     );
    end if;
  end beforeInsUpdLineInventory;

  /**
  * Description
  *    Cette procedure va mettre à 0 le poids et la quantité inventaire pour la ligne
  *    d'inventaire transmise en paramètre. Elle met également son statut à "traité"
  */
  procedure closeInventoryLineStatus(inFalLineInventoryID in FAL_LINE_INVENTORY.FAL_LINE_INVENTORY_ID%type)
  as
    ltCRUD_FalLineInventory FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalLineInventory, ltCRUD_FalLineInventory, false, inFalLineInventoryID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalLineInventory, 'C_LINE_STATUS', '3');
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalLineInventory, 'FLI_INVENT', 0);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalLineInventory, 'FLI_QTY_INVENT', 0);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_FalLineInventory);
    FWK_I_MGT_ENTITY.Release(ltCRUD_FalLineInventory);
  end closeInventoryLineStatus;

  /**
  * Description
  *    Cette procedure va mettre à jour le statut de l'inventaire dont la clef primaire
  *    est transmise en paramètre avec le statut reçu en paramètre.
  */
  procedure updateLineInventoryStatus(
    inFalLineInventoryID in FAL_LINE_INVENTORY.FAL_LINE_INVENTORY_ID%type
  , ivCLineStatus    in FAL_LINE_INVENTORY.C_LINE_STATUS%type
  )
  as
    ltCRUD_FalLineInventory FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalLineInventory, ltCRUD_FalLineInventory, false, inFalLineInventoryID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalLineInventory, 'C_LINE_STATUS', ivCLineStatus);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_FalLineInventory);
    FWK_I_MGT_ENTITY.Release(ltCRUD_FalLineInventory);
  end updateLineInventoryStatus;
end FAL_PRC_LINE_INVENTORY;
