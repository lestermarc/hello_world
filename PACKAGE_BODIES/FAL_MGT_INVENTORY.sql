--------------------------------------------------------
--  DDL for Package Body FAL_MGT_INVENTORY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_MGT_INVENTORY" 
is
  /**
  * Description
  *    Code m�tier de l'insertion d'une ligne d'inventaire MP
  */
  function insertLINE_INVENTORY(iotLineInventory in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    /* Calcul du poids corrig� et de la quantit� corrig�s */
    FAL_PRC_LINE_INVENTORY.beforeInsUpdLineInventory(iotCRUD_FalLineInventory => iotLineInventory);
    lResult  := FWK_I_DML_TABLE.CRUD(iotLineInventory);
    return lResult;
  end insertLINE_INVENTORY;

  /**
  * Description
  *    Code m�tier de la mise � jour d'une ligne d'inventaire MP
  */
  function updateLINE_INVENTORY(iotLineInventory in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    /* Calcul du poids corrig� et de la quantit� corrig�s */
    --FAL_PRC_LINE_INVENTORY.beforeInsUpdLineInventory(iotCRUD_FalLineInventory => iotLineInventory);
    lResult  := FWK_I_DML_TABLE.CRUD(iotLineInventory);
    return lResult;
  end updateLINE_INVENTORY;
end FAL_MGT_INVENTORY;
