--------------------------------------------------------
--  DDL for Package Body FAL_PRC_POSITION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_POSITION" 
is
  /**
  * Description
  *    Cette procédure va créer une position d'inventaire.
  */
  procedure createPosition(
    ivFpoDescription       in     FAL_POSITION.FPO_DESCRIPTION%type
  , inStmStockID           in     FAL_POSITION.STM_STOCK_ID%type default null
  , inFalFactoryFloorID    in     FAL_POSITION.FAL_FACTORY_FLOOR_ID%type default null
  , ivDicFreePosition1ID   in     FAL_POSITION.DIC_FREE_POSITION1_ID%type default null
  , ivDicFreePosition2ID   in     FAL_POSITION.DIC_FREE_POSITION2_ID%type default null
  , ivDicFreePosition3ID   in     FAL_POSITION.DIC_FREE_POSITION3_ID%type default null
  , ivDicFreePosition4ID   in     FAL_POSITION.DIC_FREE_POSITION4_ID%type default null
  , ivFpoFreeDescr         in     FAL_POSITION.FPO_FREE_DESCR%type default null
  , inFpoDelayInvent       in     FAL_POSITION.FPO_DELAY_INVENT%type default null
  , inFpoWastePosition     in     FAL_POSITION.FPO_WASTE_POSITION%type default 0
  , inPacSupplierPartnerID in     FAL_POSITION.PAC_SUPPLIER_PARTNER_ID%type default null
  , onFalPositionID        out    FAL_POSITION.FAL_POSITION_ID%type
  )
  as
    ltCRUD_FalPosition FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalPosition, ltCRUD_FalPosition, true);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalPosition, 'FPO_DESCRIPTION', ivFpoDescription);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalPosition, 'STM_STOCK_ID', inStmStockID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalPosition, 'FAL_FACTORY_FLOOR_ID', inFalFactoryFloorID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalPosition, 'DIC_FREE_POSITION1_ID', ivDicFreePosition1ID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalPosition, 'DIC_FREE_POSITION2_ID', ivDicFreePosition2ID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalPosition, 'DIC_FREE_POSITION3_ID', ivDicFreePosition3ID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalPosition, 'DIC_FREE_POSITION4_ID', ivDicFreePosition4ID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalPosition, 'FPO_FREE_DESCR', ivFpoFreeDescr);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalPosition, 'FPO_DELAY_INVENT', inFpoDelayInvent);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalPosition, 'FPO_WASTE_POSITION', inFpoWastePosition);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalPosition, 'PAC_SUPPLIER_PARTNER_ID', inPacSupplierPartnerID);
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_FalPosition);
    onFalPositionID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCRUD_FalPosition, 'FAL_POSITION_ID');
    FWK_I_MGT_ENTITY.Release(ltCRUD_FalPosition);
  end createPosition;

  /**
  * Description
  *    Cette procédure permet de créer les postes depuis les stocks et ateliers
  *    existants, si ceux ci n'ont pas déjà été créés.
  */
  procedure autoCreatePosition
  as
    lnPositionID      FAL_POSITION.FAL_POSITION_ID%type;
    lnPositionInitQty FAL_POSITION_INIT_QTY.FAL_POSITION_INIT_QTY_ID%type;
  begin
    /* Pour chaque atelier */
    for ltplFalFactFloor in (select FAL_FACTORY_FLOOR_ID
                                  , FAC_REFERENCE
                               from FAL_FACTORY_FLOOR
                              where FAC_IS_OPERATOR <> 1
                                and FAC_IS_PERSON <> 1) loop
      /* Si le poste n'existe pas pour l'atelier en cours */
      if FAL_LIB_POSITION.existsWithFactoryFloor(inFalFactoryFloorID => ltplFalFactFloor.FAL_FACTORY_FLOOR_ID) = 0 then
        /* Création du poste (GetValidPositionDescr assure de l'unicité de la référence pour la position) */
        FAL_PRC_POSITION.createPosition(ivFpoDescription      => FAL_LIB_POSITION.GetValidPositionDescr(ltplFalFactFloor.FAC_REFERENCE)
                                      , inFalFactoryFloorID   => ltplFalFactFloor.FAL_FACTORY_FLOOR_ID
                                      , onFalPositionID       => lnPositionID
                                       );

        /* Création des positions d'inventaire du poste (une par alliage) */
        for ltplGcoAlloy in (select GCO_ALLOY_ID
                               from GCO_ALLOY) loop
          FAL_PRC_POSITION_INIT_QTY.createPos(inFalPositionID          => lnPositionID
                                            , inGcoGoodID              => null
                                            , inGcoAlloyID             => ltplGcoAlloy.GCO_ALLOY_ID
                                            , ivCAlloyInventoryType    => null
                                            , idFpiLastDateInvent      => null
                                            , idFpiNextDateInvent      => null
                                            , inFpiWeightInit          => null
                                            , inFpiQtyInit             => null
                                            , onFalPositionInitQtyID   => lnPositionInitQty
                                             );
        end loop;
      end if;
    end loop;

    /* Pour chaque stock logique */
    for ltplStmStock in (select STM_STOCK_ID
                              , STO_DESCRIPTION
                           from STM_STOCK) loop
      /* Si le poste n'existe pas pour le stock logique en cours */
      if FAL_LIB_POSITION.existsWithStock(inStmStockID => ltplStmStock.STM_STOCK_ID) = 0 then
        /* Création du poste (GetValidPositionDescr assure de l'unicité de la référence pour la position) */
        FAL_PRC_POSITION.createPosition(ivFpoDescription   => FAL_LIB_POSITION.GetValidPositionDescr(ltplStmStock.STO_DESCRIPTION)
                                      , inStmStockID       => ltplStmStock.STM_STOCK_ID
                                      , onFalPositionID    => lnPositionID
                                       );

        /* Création des position d'inventaire du poste (une par alliage) */
        for ltplGcoAlloy in (select GCO_ALLOY_ID
                               from GCO_ALLOY) loop
          FAL_PRC_POSITION_INIT_QTY.createPos(inFalPositionID          => lnPositionID
                                            , inGcoGoodID              => null
                                            , inGcoAlloyID             => ltplGcoAlloy.GCO_ALLOY_ID
                                            , ivCAlloyInventoryType    => null
                                            , idFpiLastDateInvent      => null
                                            , idFpiNextDateInvent      => null
                                            , inFpiWeightInit          => null
                                            , inFpiQtyInit             => null
                                            , onFalPositionInitQtyID   => lnPositionInitQty
                                             );
        end loop;
      end if;
    end loop;
  end autoCreatePosition;

  /**
  * Description
  *    Cette procédure va supprimer les positions d'inventaire du poste transmis
  *    en paramètre dont le type d'inventaire est différent de celui transmis en
  *    paramètre
  */
  procedure deletePostionByInventoryType(
    inFalPositionID       in FAL_POSITION.FAL_POSITION_ID%type
  , ivCAlloyInventoryType in FAL_ALLOY_INVENTORY.C_ALLOY_INVENTORY_TYPE%type
  )
  as
  begin
    for ltplFalPositionInitQty in (select FAL_POSITION_INIT_QTY_ID
                                     from FAL_POSITION_INIT_QTY
                                    where FAL_POSITION_ID = inFalPositionID
                                      and C_ALLOY_INVENTORY_TYPE <> ivCAlloyInventoryType) loop
      FAL_PRC_POSITION_INIT_QTY.deletePos(inFalPositionInitQtyID => ltplFalPositionInitQty.FAL_POSITION_INIT_QTY_ID);
    end loop;
  end deletePostionByInventoryType;
end FAL_PRC_POSITION;
