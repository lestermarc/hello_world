--------------------------------------------------------
--  DDL for Package Body FAL_MGT_ADV_CALCULATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_MGT_ADV_CALCULATION" 
is
  /**
  * Description
  *    Code métier de la suppression d'une copie d'une rubrique.
  */
  function deleteFAL_ADV_CALC_RATE_STRUCT(iot_crud_definition in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    FWK_I_MGT_ENTITY.DeleteChildren(iv_child_name         => 'FAL_ADV_CALC_TOTAL_RATE'
                                  , iv_parent_key_name    => 'FAL_ADV_CALC_RATE_STRUCT_ID'
                                  , iv_parent_key_value   => FWK_TYP_FAL_ENTITY.gttAdvCalcRateStruct(iot_crud_definition.entity_id).FAL_ADV_CALC_RATE_STRUCT_ID
                                   );
    FWK_I_MGT_ENTITY.DeleteChildren(iv_child_name         => 'FAL_ADV_CALC_TOTAL_RATE'
                                  , iv_parent_key_name    => 'FAL_ADV_CALC_RATE_STRUCT1_ID'
                                  , iv_parent_key_value   => FWK_TYP_FAL_ENTITY.gttAdvCalcRateStruct(iot_crud_definition.entity_id).FAL_ADV_CALC_RATE_STRUCT_ID
                                   );
    lResult  := FWK_I_DML_TABLE.CRUD(iot_crud_definition);
    return lResult;
  end deleteFAL_ADV_CALC_RATE_STRUCT;

  /**
  * Description
  *    Code métier de la suppression d'une copie d'un taux atelier.
  */
  function deleteFAL_ADV_CALC_FACT_RATE(iot_crud_definition in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- Suppression des liens avec les lots calculés.
    FWK_I_MGT_ENTITY.DeleteChildren
                                   (iv_child_name         => 'FAL_ADV_CALC_FACT_RATE_DEC'
                                  , iv_parent_key_name    => 'FAL_ADV_CALC_FACTORY_RATE_ID'
                                  , iv_parent_key_value   => FWK_TYP_FAL_ENTITY.gttAdvCalcFactoryRate(iot_crud_definition.entity_id).FAL_ADV_CALC_FACTORY_RATE_ID
                                   );
    lResult  := FWK_I_DML_TABLE.CRUD(iot_crud_definition);
    return lResult;
  end deleteFAL_ADV_CALC_FACT_RATE;

  /**
  * Description
  *    Code métier de la suppression d'un calcul
  */
  function deleteFAL_ADV_BATCH_CALCUL(iot_crud_definition in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- Suppression des liens avec les lots calculés.
    FWK_I_MGT_ENTITY.DeleteChildren(iv_child_name         => 'FAL_ADV_BC_S_CALC_OPTIONS'
                                  , iv_parent_key_name    => 'FAL_ADV_BATCH_CALCUL_ID'
                                  , iv_parent_key_value   => FWK_TYP_FAL_ENTITY.gttAdvBatchCalcul(iot_crud_definition.entity_id).FAL_ADV_BATCH_CALCUL_ID
                                   );
    -- Suppression des copies de rubriques
    FWK_I_MGT_ENTITY.DeleteChildren(iv_child_name         => 'FAL_ADV_CALC_RATE_STRUCT'
                                  , iv_parent_key_name    => 'FAL_ADV_BATCH_CALCUL_ID'
                                  , iv_parent_key_value   => FWK_TYP_FAL_ENTITY.gttAdvBatchCalcul(iot_crud_definition.entity_id).FAL_ADV_BATCH_CALCUL_ID
                                   );
    -- Suppression des copies de taux ateliers
    FWK_I_MGT_ENTITY.DeleteChildren(iv_child_name         => 'FAL_ADV_CALC_FACTORY_RATE'
                                  , iv_parent_key_name    => 'FAL_ADV_BATCH_CALCUL_ID'
                                  , iv_parent_key_value   => FWK_TYP_FAL_ENTITY.gttAdvBatchCalcul(iot_crud_definition.entity_id).FAL_ADV_BATCH_CALCUL_ID
                                   );
    lResult  := FWK_I_DML_TABLE.CRUD(iot_crud_definition);
    return lResult;
  end deleteFAL_ADV_BATCH_CALCUL;

  /**
  * Description
  *    Code métier de la suppression d'un lien entre un calcul et ses options
  */
  function deleteFAL_ADV_BC_S_CALC_OPTS(iot_crud_definition in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    lResult  := FWK_I_DML_TABLE.CRUD(iot_crud_definition);
    -- Suppression des liens avec les lots calculés.
    FWK_I_MGT_ENTITY.DeleteChildren(iv_child_name         => 'FAL_ADV_CALC_OPTIONS'
                                  , iv_parent_key_name    => 'FAL_ADV_CALC_OPTIONS_ID'
                                  , iv_parent_key_value   => FWK_TYP_FAL_ENTITY.gttAdvBCSCalcOptions(iot_crud_definition.entity_id).FAL_ADV_CALC_OPTIONS_ID
                                   );
    return lResult;
  end deleteFAL_ADV_BC_S_CALC_OPTS;

  /**
  * Description
  *    Code métier de l'insertion d'un calcul
  */
  function insertFAL_ADV_BATCH_CALCUL(iot_crud_definition in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    lResult  := FWK_I_DML_TABLE.CRUD(iot_crud_definition);
    -- Insertion d'un copie des taux par atelier et de leur décomposition pour conserver l'historique de la décomposition des taux ateliers utilisés.
    FAL_I_PRC_WIP_CALCULATION.StoreFactoryRates(FWK_TYP_FAL_ENTITY.gttAdvBatchCalcul(iot_crud_definition.entity_id).FAL_ADV_BATCH_CALCUL_ID);
    return lResult;
  end insertFAL_ADV_BATCH_CALCUL;

  /**
  * Description
  *    Code métier de l'insertion d'un lien entre un calcul et ses options
  */
  function insertFAL_ADV_BC_S_CALC_OPTS(iot_crud_definition in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    lResult  := FWK_I_DML_TABLE.CRUD(iot_crud_definition);
    -- Insertion d'un copie des rubriques de la structure de calul utilisées pour conserver l'historique de la hiérarchie des rubriques.
    FAL_I_PRC_WIP_CALCULATION.StoreCalculationRubrics(FWK_TYP_FAL_ENTITY.gttAdvBCSCalcOptions(iot_crud_definition.entity_id).FAL_ADV_BATCH_CALCUL_ID);
    return lResult;
  end insertFAL_ADV_BC_S_CALC_OPTS;
end FAL_MGT_ADV_CALCULATION;
