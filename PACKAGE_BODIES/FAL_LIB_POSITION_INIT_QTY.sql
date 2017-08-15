--------------------------------------------------------
--  DDL for Package Body FAL_LIB_POSITION_INIT_QTY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_POSITION_INIT_QTY" 
is
  /**
  * Description
  *    Cette fonction retourne le type d'inventaire unique du poste de matière
  *    précieuse dont la clef primaire est transmise en paramètre. Si plusieurs
  *    type d'inventaire existent (= erreur), la fonction retourne null.
  */
  function getUniqueInventoryTypeID(inFalPositionID in FAL_POSITION_INIT_QTY.FAL_POSITION_ID%type)
    return FAL_POSITION_INIT_QTY.C_ALLOY_INVENTORY_TYPE%type
  as
    lvCAlloyInventoryTypeID FAL_POSITION_INIT_QTY.C_ALLOY_INVENTORY_TYPE%type;
  begin
    select distinct C_ALLOY_INVENTORY_TYPE
               into lvCAlloyInventoryTypeID
               from FAL_POSITION_INIT_QTY
              where FAL_POSITION_ID = inFalPositionID
                and C_ALLOY_INVENTORY_TYPE is not null
             having (select count(distinct C_ALLOY_INVENTORY_TYPE)
                       from FAL_POSITION_INIT_QTY
                      where FAL_POSITION_ID = inFalPositionID
                        and C_ALLOY_INVENTORY_TYPE is not null) = 1;

    return lvCAlloyInventoryTypeID;
  exception
    when no_data_found then
      return null;
  end getUniqueInventoryTypeID;

  /**
  * function positionExists
  * Description
  *    Cette fonction recherche la position d'inventaire en fonction du poste, du
  *    bien (optionnel) et de l'alliage. Retourne 1 si elle existe, sinon 0
  * @created age 20.03.2012
  * @lastUpdate
  * @public
  * @param inFalPositionID : Poste de matière précieuse
  * @param inGcoGoodID     : Bien
  * @param inGcoAlloyID    : Alliage
  * @return : 1 si existant, sinon 0
  */
  function positionExists(
    inFalPositionID in FAL_POSITION.FAL_POSITION_ID%type
  , inGcoGoodID     in GCO_GOOD.GCO_GOOD_ID%type
  , inGcoAlloyID    in GCO_ALLOY.GCO_ALLOY_ID%type
  , ioFalPosInitQty in out FAL_POSITION_INIT_QTY.FAL_POSITION_INIT_QTY_ID%Type
  )
    return number
  as
  begin
    select FAL_POSITION_INIT_QTY_ID
      into ioFalPosInitQty
      from FAL_POSITION_INIT_QTY
     where FAL_POSITION_ID = inFalPositionID
       and nvl(GCO_GOOD_ID, 0) = nvl(inGcoGoodID, 0)
       and GCO_ALLOY_ID = inGcoAlloyID;

    return 1;
  exception
    when no_data_found then
      ioFalPosInitQty := null;
      return 0;
  end positionExists;

  /**
  * function getLastDateInvent
  * Description
  *    Cette fonction retourne la date du dernier inventaire de la position d'inventaire
  * @created age 22.03.2012
  * @lastUpdate
  * @public
  * @param inFalPositionInitQtyID : Position d'inventaire
  * @return : Date dernier inventaire
  */
  function getLastDateInvent(inFalPositionInitQtyID in FAL_POSITION_INIT_QTY.FAL_POSITION_INIT_QTY_ID%type)
    return FAL_POSITION_INIT_QTY.FPI_LAST_DATE_INVENT%type
  as
    ldLastDateInvent FAL_POSITION_INIT_QTY.FPI_LAST_DATE_INVENT%type;
  begin
    select FPI_LAST_DATE_INVENT
      into ldLastDateInvent
      from FAL_POSITION_INIT_QTY
     where FAL_POSITION_INIT_QTY_ID = inFalPositionInitQtyID;

    return ldLastDateInvent;
  exception
    when no_data_found then
      return null;
  end getLastDateInvent;

  /**
  * function getLastDateInvent
  * Description
  *    Cette fonction retourne le poids au début du dernier inventaire de la position d'inventaire
  * @created age 22.03.2012
  * @lastUpdate
  * @public
  * @param inFalPositionInitQtyID : Position d'inventaire
  * @return : Poids début dernier inventaire
  */
  function getLastInventWeight(inFalPositionInitQtyID in FAL_POSITION_INIT_QTY.FAL_POSITION_INIT_QTY_ID%type)
    return FAL_POSITION_INIT_QTY.FPI_WEIGHT_INIT%type
  as
    lnWeightInit FAL_POSITION_INIT_QTY.FPI_WEIGHT_INIT%type;
  begin
    select FPI_WEIGHT_INIT
      into lnWeightInit
      from FAL_POSITION_INIT_QTY
     where FAL_POSITION_INIT_QTY_ID = inFalPositionInitQtyID;

    return lnWeightInit;
  exception
    when no_data_found then
      return 0;
  end getLastInventWeight;

  /**
  * function getLastDateInvent
  * Description
  *    Cette fonction retourne  la quantité au début du dernier inventaire de la position d'inventaire
  * @created age 22.03.2012
  * @lastUpdate
  * @public
  * @param inFalPositionInitQtyID : Position d'inventaire
  * @return : Quantité début dernier inventaire
  */
  function getLastInventQty(inFalPositionInitQtyID in FAL_POSITION_INIT_QTY.FAL_POSITION_INIT_QTY_ID%type)
    return FAL_POSITION_INIT_QTY.FPI_QTY_INIT%type
  as
    lnQtyInit FAL_POSITION_INIT_QTY.FPI_QTY_INIT%type;
  begin
    select FPI_QTY_INIT
      into lnQtyInit
      from FAL_POSITION_INIT_QTY
     where FAL_POSITION_INIT_QTY_ID = inFalPositionInitQtyID;

    return lnQtyInit;
  exception
    when no_data_found then
      return 0;
  end getLastInventQty;

  function getPositionInitQtyID(
    inFalPositionID in FAL_POSITION_INIT_QTY.FAL_POSITION_ID%type
  , inGcoGoodID     in FAL_POSITION_INIT_QTY.GCO_GOOD_ID%type
  , inGcoAlloyID    in FAL_POSITION_INIT_QTY.GCO_ALLOY_ID%type
  )
    return FAL_POSITION_INIT_QTY.FAL_POSITION_INIT_QTY_ID%type
  as
    lnFalPositionInitQtyID FAL_POSITION_INIT_QTY.FAL_POSITION_INIT_QTY_ID%type;
  begin
    select FAL_POSITION_INIT_QTY_ID
      into lnFalPositionInitQtyID
      from FAL_POSITION_INIT_QTY
     where FAL_POSITION_ID = inFalPositionID
       and nvl(GCO_GOOD_ID, 0) = nvl(inGcoGoodID, 0)
       and GCO_ALLOY_ID = inGcoAlloyID;

    return lnFalPositionInitQtyID;
  end getPositionInitQtyID;
end FAL_LIB_POSITION_INIT_QTY;
