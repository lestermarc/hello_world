--------------------------------------------------------
--  DDL for Package Body FAL_LIB_LINE_INVENTORY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_LINE_INVENTORY" 
is
  /**
  * Description
  *    Cette fonction retourne l'opérateur unique de l'extraction de l'inventaire
  *    dont la clef primaire est transmise en paramètre. Si plusieurs opérateur
  *    existent, la fonction retourne null.
  */
  function getUniqueOperatorID(inFalAlloyInventoryID in FAL_LINE_INVENTORY.FAL_ALLOY_INVENTORY_ID%type)
    return FAL_LINE_INVENTORY.DIC_OPERATOR_ID%type
  as
    lvDicOperatorID FAL_LINE_INVENTORY.DIC_OPERATOR_ID%type;
  begin
    select distinct DIC_OPERATOR_ID
               into lvDicOperatorID
               from FAL_LINE_INVENTORY
              where FAL_ALLOY_INVENTORY_ID = inFalAlloyInventoryID
             having (select count(distinct DIC_OPERATOR_ID)
                       from FAL_LINE_INVENTORY
                      where FAL_ALLOY_INVENTORY_ID = inFalAlloyInventoryID
                        and DIC_OPERATOR_ID is not null) = 1;

    return lvDicOperatorID;
  exception
    when no_data_found then
      return null;
  end getUniqueOperatorID;

  /**
  * Description
  *    Cette fonction retourne 1 si l'inventaire possède au moins une ligne dans
  *    un statut différent de "traité" (3).
  */
  function hasLinesNotHandled(inFalAlloyInventoryID in FAL_LINE_INVENTORY.FAL_ALLOY_INVENTORY_ID%type)
    return number
  as
    lnHasLinesNotHandled number;
  begin
    select sign(count(FAL_LINE_INVENTORY_ID) )
      into lnHasLinesNotHandled
      from FAL_LINE_INVENTORY
     where FAL_ALLOY_INVENTORY_ID = inFalAlloyInventoryID
       and C_LINE_STATUS <> '3';   -- <> traité

    return lnHasLinesNotHandled;
  exception
    when no_data_found then
      return 0;
  end hasLinesNotHandled;

  /**
  * Description
  *    Cette fonction retourne 1 si une ligne d'inventaire avec les mêmes poste,
  *    bien et alliage existe déjà dans un statut différent de "traité" (3).
  */
  function lineNotHandledAlreadyExists(
    inFalPositionID       in FAL_LINE_INVENTORY.FAL_POSITION_ID%type
  , inGcoGoodID           in FAL_LINE_INVENTORY.GCO_GOOD_ID%type
  , inGcoAlloyID          in FAL_LINE_INVENTORY.GCO_ALLOY_ID%type
  , inFalAlloyInventoryID in FAL_LINE_INVENTORY.FAL_ALLOY_INVENTORY_ID%type
  , inFalLineInventoryID  in FAL_LINE_INVENTORY.FAL_LINE_INVENTORY_ID%type
  )
    return number
  as
    lnExists number;
  begin
    select sign(count(FAL_LINE_INVENTORY_ID) )
      into lnExists
      from FAL_LINE_INVENTORY
     where FAL_POSITION_ID = inFalPositionID
       and GCO_GOOD_ID = inGcoGoodID
       and GCO_ALLOY_ID = inGcoAlloyID
       and FAL_ALLOY_INVENTORY_ID = inFalAlloyInventoryID
       and C_LINE_STATUS <> '3'   -- traité
       and FAL_LINE_INVENTORY_ID <> nvl(inFalLineInventoryID, 0);

    return lnExists;
  exception
    when no_data_found then
      return 0;
  end lineNotHandledAlreadyExists;
end FAL_LIB_LINE_INVENTORY;
