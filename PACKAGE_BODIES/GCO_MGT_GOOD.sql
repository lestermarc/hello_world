--------------------------------------------------------
--  DDL for Package Body GCO_MGT_GOOD
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_MGT_GOOD" 
is
  /**
  * Description
  *    Code métier de l'insertion d'un Bien
  */
  function insertGOOD(iotGood in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    GCO_I_PRC_GOOD.CheckGoodData(iotGood);
    lResult  := FWK_I_DML_TABLE.CRUD(iotGood);
    -- Génération de la nouvelle référence du bien (si en gén. automatique)
    GCO_PRC_GOOD.GenerateAutoRef(iGoodID => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotGood, 'GCO_GOOD_ID') );
    return lResult;
  end insertGOOD;

  /**
  * Description
  ||
  *    Code métier de l'insertion d'un produit
  */
  function insertPRODUCT(iotProduct in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    GCO_I_PRC_GOOD.CheckProductData(iotProduct);
    lResult  := FWK_I_DML_TABLE.CRUD(iotProduct);
    return lResult;
  end insertProduct;
end GCO_MGT_GOOD;
