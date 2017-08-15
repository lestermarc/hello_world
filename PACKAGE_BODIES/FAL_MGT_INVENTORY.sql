--------------------------------------------------------
--  DDL for Package Body FAL_MGT_INVENTORY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_MGT_INVENTORY" 
is
  /**
  * Description
  *    Code métier de l'insertion d'une ligne d'inventaire MP
  */
  function insertLINE_INVENTORY(iotLineInventory in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    /* Calcul du poids corrigé et de la quantité corrigés */
    FAL_PRC_LINE_INVENTORY.beforeInsUpdLineInventory(iotCRUD_FalLineInventory => iotLineInventory);
    lResult  := FWK_I_DML_TABLE.CRUD(iotLineInventory);
    return lResult;
  end insertLINE_INVENTORY;

  /**
  * Description
  *    Code métier de la mise à jour d'une ligne d'inventaire MP
  */
  function updateLINE_INVENTORY(iotLineInventory in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    /* Calcul du poids corrigé et de la quantité corrigés */
    --FAL_PRC_LINE_INVENTORY.beforeInsUpdLineInventory(iotCRUD_FalLineInventory => iotLineInventory);
    lResult  := FWK_I_DML_TABLE.CRUD(iotLineInventory);
    return lResult;
  end updateLINE_INVENTORY;
end FAL_MGT_INVENTORY;
