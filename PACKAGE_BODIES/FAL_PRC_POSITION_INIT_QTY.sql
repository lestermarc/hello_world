--------------------------------------------------------
--  DDL for Package Body FAL_PRC_POSITION_INIT_QTY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_POSITION_INIT_QTY" 
is
  /**
  * Description
  *    Cette procédure va créer une position d'inventaire.
  */
  procedure createPos(
    inFalPositionID        in     FAL_POSITION_INIT_QTY.FAL_POSITION_ID%type
  , inGcoGoodID            in     FAL_POSITION_INIT_QTY.GCO_GOOD_ID%type
  , inGcoAlloyID           in     FAL_POSITION_INIT_QTY.GCO_ALLOY_ID%type
  , ivCAlloyInventoryType  in     FAL_POSITION_INIT_QTY.C_ALLOY_INVENTORY_TYPE%type
  , idFpiLastDateInvent    in     FAL_POSITION_INIT_QTY.FPI_LAST_DATE_INVENT%type
  , idFpiNextDateInvent    in     FAL_POSITION_INIT_QTY.FPI_NEXT_DATE_INVENT%type
  , inFpiWeightInit        in     FAL_POSITION_INIT_QTY.FPI_WEIGHT_INIT%type
  , inFpiQtyInit           in     FAL_POSITION_INIT_QTY.FPI_QTY_INIT%type
  , onFalPositionInitQtyID out    FAL_POSITION_INIT_QTY.FAL_POSITION_INIT_QTY_ID%type
  )
  as
    ltCRUD_FalPositionInitQty FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalPositionInitQty, ltCRUD_FalPositionInitQty, true);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalPositionInitQty, 'FAL_POSITION_ID', inFalPositionID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalPositionInitQty, 'GCO_GOOD_ID', inGcoGoodID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalPositionInitQty, 'GCO_ALLOY_ID', inGcoAlloyID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalPositionInitQty, 'C_ALLOY_INVENTORY_TYPE', ivCAlloyInventoryType);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalPositionInitQty, 'FPI_LAST_DATE_INVENT', idFpiLastDateInvent);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalPositionInitQty, 'FPI_NEXT_DATE_INVENT', idFpiNextDateInvent);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalPositionInitQty, 'FPI_WEIGHT_INIT', inFpiWeightInit);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalPositionInitQty, 'FPI_QTY_INIT', inFpiQtyInit);
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_FalPositionInitQty);
    onFalPositionInitQtyID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCRUD_FalPositionInitQty, 'FAL_POSITION_INIT_QTY_ID');
    FWK_I_MGT_ENTITY.Release(ltCRUD_FalPositionInitQty);
  end createPos;

  /**
  * Description
  *    Cette procédure va supprimer la position d'inventaire correspondant au
  *    poste et l'alliage fourni en paramètre et dont le bien n'est pas
  *    renseigné.
  */
  procedure deletePos(inFalPositionID in FAL_POSITION_INIT_QTY.FAL_POSITION_ID%type, inGcoAlloyID in FAL_POSITION_INIT_QTY.GCO_ALLOY_ID%type)
  as
    lnFalPositionInitQtyID FAL_POSITION_INIT_QTY.FAL_POSITION_INIT_QTY_ID%type;
  begin
    select FAL_POSITION_INIT_QTY_ID
      into lnFalPositionInitQtyID
      from FAL_POSITION_INIT_QTY
     where FAL_POSITION_ID = inFalPositionID
       and GCO_ALLOY_ID = inGcoAlloyID
       and GCO_GOOD_ID is null;

    deletePos(inFalPositionInitQtyID => lnFalPositionInitQtyID);
  end deletePos;

  /**
  * Description
  *    Cette procédure va supprimer la position d'inventaire dont la clef primaire
  *    est transmise en paramètre.
  */
  procedure deletePos(inFalPositionInitQtyID in FAL_POSITION_INIT_QTY.FAL_POSITION_INIT_QTY_ID%type)
  as
    ltCRUD_FalPositionInitQty FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalPositionInitQty, ltCRUD_FalPositionInitQty, false, inFalPositionInitQtyID);
    FWK_I_MGT_ENTITY.DeleteEntity(ltCRUD_FalPositionInitQty);
    FWK_I_MGT_ENTITY.Release(ltCRUD_FalPositionInitQty);
  end deletePos;

  /**
  * Description
  *    Cette procédure va mettre à jour la position d'inventaire reçue en paramètre
  *    suite au traitement de son inventaire. Sont mis à jour les quantités initiales
  *    ainsi que les dates du dernier et du prochain inventaire
  */
  procedure updatePosByInventoryProcess(
    inFalPositionInitQtyID in FAL_POSITION_INIT_QTY.FAL_POSITION_INIT_QTY_ID%type
  , idFliDateInvent        in FAL_LINE_INVENTORY.FLI_DATE_INVENT%type
  , inFpiWeightInit        in FAL_POSITION_INIT_QTY.FPI_WEIGHT_INIT%type
  , inFpiQtyInit           in FAL_POSITION_INIT_QTY.FPI_QTY_INIT%type
  )
  as
    ltCRUD_FalPositionInitQty FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalPositionInitQty, ltCRUD_FalPositionInitQty, true, inFalPositionInitQtyID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalPositionInitQty, 'FPI_LAST_DATE_INVENT', idFliDateInvent);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalPositionInitQty, 'FPI_WEIGHT_INIT', inFpiWeightInit);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalPositionInitQty, 'FPI_QTY_INIT', inFpiQtyInit);
    FWK_I_MGT_ENTITY_DATA.setcolumn
                                 (ltCRUD_FalPositionInitQty
                                , 'FPI_NEXT_DATE_INVENT'
                                , idFliDateInvent +
                                  nvl(FAL_LIB_POSITION.getDelayInvent(inFalPositionID   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCRUD_FalPositionInitQty
                                                                                                                               , 'FAL_POSITION_ID'
                                                                                                                                )
                                                                     )
                                    , 0
                                     )
                                 );
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalPositionInitQty, 'A_DATEMOD', idFliDateInvent);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalPositionInitQty, 'A_IDMOD', PCS.PC_I_LIB_SESSION.GetUSerINI);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_FalPositionInitQty);
    FWK_I_MGT_ENTITY.Release(ltCRUD_FalPositionInitQty);
  end updatePosByInventoryProcess;
end FAL_PRC_POSITION_INIT_QTY;
