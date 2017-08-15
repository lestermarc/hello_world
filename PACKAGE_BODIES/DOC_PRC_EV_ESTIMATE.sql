--------------------------------------------------------
--  DDL for Package Body DOC_PRC_EV_ESTIMATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_PRC_EV_ESTIMATE" 
is
  /**
  * procedure ApplyEstimateChanges
  * Description
  *   Appliquer les valeurs de la vue à l'entité DOC_ESTIMATE
  */
  procedure ApplyEstimateChanges(iotEv in out nocopy fwk_i_typ_definition.t_crud_def, iotEstimate in out nocopy fwk_i_typ_definition.t_crud_def)
  is
  begin
    -- DOC_ESTIMATE_ID
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimate, 'DOC_ESTIMATE_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEv, 'DOC_ESTIMATE_ID') );
--    FWK_I_MGT_ENTITY_DATA.TransferColumns(iotEv, iotEstimate);
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotEstimate, 'DOC_GAUGE_OFFER_ID');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotEstimate, 'DOC_GAUGE_ORDER_ID');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotEstimate, 'PAC_CUSTOM_PARTNER_ID');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotEstimate, 'PC_LANG_ID');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotEstimate, 'ACS_FINANCIAL_CURRENCY_ID');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotEstimate, 'GAL_PROJECT_ID');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotEstimate, 'C_DOC_ESTIMATE_STATUS');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotEstimate, 'C_DOC_ESTIMATE_CODE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotEstimate, 'DES_NUMBER');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotEstimate, 'DES_HEADING_TEXT');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotEstimate, 'DES_FOOT_TEXT');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotEstimate, 'DES_RECALC_AMOUNTS');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotEstimate, 'A_DATECRE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotEstimate, 'A_DATEMOD');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotEstimate, 'A_IDCRE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotEstimate, 'A_IDMOD');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotEstimate, 'A_RECLEVEL');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotEstimate, 'A_RECSTATUS');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotEstimate, 'A_CONFIRM');
  end ApplyEstimateChanges;

  /**
  * procedure ApplyPosChanges
  * Description
  *   Appliquer les valeurs de la vue à l'entité DOC_ESTIMATE_POS
  */
  procedure ApplyPosChanges(iotEv in out nocopy fwk_i_typ_definition.t_crud_def, iotPos in out nocopy fwk_i_typ_definition.t_crud_def)
  is
  begin
    -- DOC_ESTIMATE_ID
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotPos, 'DOC_ESTIMATE_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEv, 'DOC_ESTIMATE_ID') );

    -- DOC_ESTIMATE_POS_ID
    if not FWK_I_MGT_ENTITY_DATA.IsNull(iotEv, 'DOC_ESTIMATE_POS_ID') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotPos, 'DOC_ESTIMATE_POS_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEv, 'DOC_ESTIMATE_POS_ID') );
    end if;

--    FWK_I_MGT_ENTITY_DATA.TransferColumns(iotEv, iotPos);
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'GCO_GOOD_ID');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'GCO_NEW_GOOD_ID');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'GCO_GOOD_CATEGORY_ID');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'STM_STOCK_ID');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'STM_LOCATION_ID');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'GAL_TASK_ID');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'GAL_BUDGET_ID');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'PPS_NOMENCLATURE_ID');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'C_MANAGEMENT_MODE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'C_DOC_ESTIMATE_CREATE_MODE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'C_SUPPLY_MODE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'C_SUPPLY_TYPE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'C_SCHEDULE_PLANNING');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'DIC_UNIT_OF_MEASURE_ID');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'DEP_NUMBER');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'DEP_REFERENCE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'DEP_SECONDARY_REFERENCE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'DEP_SHORT_DESCRIPTION');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'DEP_LONG_DESCRIPTION');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'DEP_DELIVERY_DATE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'DEP_OPTION');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'DEP_RECALC_AMOUNTS');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'DEP_FREE_DESCRIPTION');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'DEP_COMMENT');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'A_DATECRE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'A_DATEMOD');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'A_IDCRE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'A_IDMOD');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'A_RECLEVEL');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'A_RECSTATUS');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotPos, 'A_CONFIRM');
  end ApplyPosChanges;

  /**
  * procedure ApplyElementChanges
  * Description
  *   Appliquer les valeurs de la vue à l'entité DOC_ESTIMATE_ELEMENT
  * @created NGV 23.12.2011
  * @lastUpdate
  * @public
  * @param iotEv : T_CRUD_DEF d'une vue (EV_DOC_ESTIMATE_..)
  * @param iotElement : DOC_ESTIMATE_ELEMENT_COST de type T_CRUD_DEF
  */
  procedure ApplyElementChanges(iotEv in out nocopy fwk_i_typ_definition.t_crud_def, iotElement in out nocopy fwk_i_typ_definition.t_crud_def)
  is
  begin
    -- DOC_ESTIMATE_ELEMENT_ID
    if not FWK_I_MGT_ENTITY_DATA.IsNull(iotEv, 'DOC_ESTIMATE_ELEMENT_ID') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotElement, 'DOC_ESTIMATE_ELEMENT_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEv, 'DOC_ESTIMATE_ELEMENT_ID') );
    end if;

    -- DOC_ESTIMATE_POS_ID
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotElement, 'DOC_ESTIMATE_POS_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEv, 'DOC_ESTIMATE_POS_ID') );
--    FWK_I_MGT_ENTITY_DATA.TransferColumns(iotEv, iotElement);
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotElement, 'C_DOC_ESTIMATE_ELEMENT_TYPE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotElement, 'DED_NUMBER');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotElement, 'A_DATECRE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotElement, 'A_DATEMOD');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotElement, 'A_IDCRE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotElement, 'A_IDMOD');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotElement, 'A_RECLEVEL');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotElement, 'A_RECSTATUS');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotElement, 'A_CONFIRM');
  end ApplyElementChanges;

  /**
  * procedure ApplyCostChanges
  * Description
  *   Appliquer les valeurs de la vue à l'entité DOC_ESTIMATE_ELEMENT_COST
  */
  procedure ApplyCostChanges(iotEv in out nocopy fwk_i_typ_definition.t_crud_def, iotCost in out nocopy fwk_i_typ_definition.t_crud_def)
  is
  begin
    -- DOC_ESTIMATE_ELEMENT_COST_ID
    if not FWK_I_MGT_ENTITY_DATA.IsNull(iotEv, 'DOC_ESTIMATE_ELEMENT_COST_ID') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotCost, 'DOC_ESTIMATE_ELEMENT_COST_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEv, 'DOC_ESTIMATE_ELEMENT_COST_ID') );
    end if;

    -- DOC_ESTIMATE_ID
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotCost, 'DOC_ESTIMATE_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEv, 'DOC_ESTIMATE_ID') );

    -- DOC_ESTIMATE_ELEMENT_ID
    if not FWK_I_MGT_ENTITY_DATA.IsNull(iotEv, 'DOC_ESTIMATE_ELEMENT_ID') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotCost, 'DOC_ESTIMATE_ELEMENT_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEv, 'DOC_ESTIMATE_ELEMENT_ID') );
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotCost, 'DOC_ESTIMATE_POS_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotCost, 'DOC_ESTIMATE_FOOT_ID');
    -- DOC_ESTIMATE_POS_ID
    elsif not FWK_I_MGT_ENTITY_DATA.IsNull(iotEv, 'DOC_ESTIMATE_POS_ID') then
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotCost, 'DOC_ESTIMATE_ELEMENT_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotCost, 'DOC_ESTIMATE_POS_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEv, 'DOC_ESTIMATE_POS_ID') );
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotCost, 'DOC_ESTIMATE_FOOT_ID');
    -- DOC_ESTIMATE_FOOT_ID
    else
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotCost, 'DOC_ESTIMATE_ELEMENT_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotCost, 'DOC_ESTIMATE_POS_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotCost, 'DOC_ESTIMATE_FOOT_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEv, 'DOC_ESTIMATE_FOOT_ID') );
    end if;

--    FWK_I_MGT_ENTITY_DATA.TransferColumns(iotEv, iotCost);
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotCost, 'DEC_COST_PRICE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotCost, 'DEC_UNIT_SALE_PRICE_TH');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotCost, 'DEC_UNIT_SALE_PRICE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotCost, 'DEC_UNIT_MARGIN_AMOUNT');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotCost, 'DEC_UNIT_MARGIN_RATE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotCost, 'DEC_QUANTITY');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotCost, 'DEC_REF_QTY');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotCost, 'DEC_CONVERSION_FACTOR');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotCost, 'DEC_SALE_PRICE_TH');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotCost, 'DEC_SALE_PRICE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotCost, 'DEC_SALE_PRICE_CORR');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotCost, 'DEC_MARGIN_AMOUNT');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotCost, 'DEC_MARGIN_AMOUNT_CORR');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotCost, 'DEC_MARGIN_RATE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotCost, 'DEC_MARGIN_RATE_CORR');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotCost, 'DEC_GLOBAL_MARGIN_AMOUNT');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotCost, 'A_DATECRE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotCost, 'A_DATEMOD');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotCost, 'A_IDCRE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotCost, 'A_IDMOD');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotCost, 'A_RECLEVEL');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotCost, 'A_RECSTATUS');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotCost, 'A_CONFIRM');
  end ApplyCostChanges;

  /**
  * procedure ApplyCompChanges
  * Description
  *   Appliquer les valeurs de la vue à l'entité DOC_ESTIMATE_COMP
  */
  procedure ApplyCompChanges(iotEv in out nocopy fwk_i_typ_definition.t_crud_def, iotComp in out nocopy fwk_i_typ_definition.t_crud_def)
  is
  begin
    -- DOC_ESTIMATE_COMP_ID
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotComp, 'DOC_ESTIMATE_COMP_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEv, 'DOC_ESTIMATE_COMP_ID') );
--    FWK_I_MGT_ENTITY_DATA.TransferColumns(iotEv, iotComp);
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotComp, 'GCO_GOOD_ID');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotComp, 'GCO_NEW_GOOD_ID');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotComp, 'GCO_GOOD_CATEGORY_ID');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotComp, 'STM_STOCK_ID');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotComp, 'STM_LOCATION_ID');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotComp, 'C_MANAGEMENT_MODE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotComp, 'C_DOC_ESTIMATE_CREATE_MODE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotComp, 'C_SUPPLY_MODE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotComp, 'C_SUPPLY_TYPE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotComp, 'DIC_UNIT_OF_MEASURE_ID');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotComp, 'ECP_REFERENCE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotComp, 'ECP_SECONDARY_REFERENCE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotComp, 'ECP_SHORT_DESCRIPTION');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotComp, 'ECP_LONG_DESCRIPTION');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotComp, 'ECP_FREE_DESCRIPTION');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotComp, 'A_DATECRE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotComp, 'A_DATEMOD');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotComp, 'A_IDCRE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotComp, 'A_IDMOD');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotComp, 'A_RECLEVEL');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotComp, 'A_RECSTATUS');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotComp, 'A_CONFIRM');
  end ApplyCompChanges;

  /**
  * procedure ApplyTaskChanges
  * Description
  *   Appliquer les valeurs de la vue à l'entité DOC_ESTIMATE_TASK
  */
  procedure ApplyTaskChanges(iotEv in out nocopy fwk_i_typ_definition.t_crud_def, iotTask in out nocopy fwk_i_typ_definition.t_crud_def)
  is
  begin
    -- DOC_ESTIMATE_TASK_ID
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotTask, 'DOC_ESTIMATE_TASK_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEv, 'DOC_ESTIMATE_TASK_ID') );
--    FWK_I_MGT_ENTITY_DATA.TransferColumns(iotEv, iotTask);
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotTask, 'FAL_TASK_ID');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotTask, 'C_DOC_ESTIMATE_CREATE_MODE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotTask, 'C_TASK_TYPE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotTask, 'C_SCHEDULE_PLANNING');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotTask, 'FAL_LIST_STEP_LINK_ID');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotTask, 'DTK_REFERENCE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotTask, 'DTK_DESCRIPTION');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotTask, 'DTK_ADJUSTING_TIME');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotTask, 'DTK_WORK_TIME');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotTask, 'DTK_QTY_FIX_ADJUSTING');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotTask, 'DTK_QTY_REF_WORK');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotTask, 'DTK_AMOUNT');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotTask, 'DTK_QTY_REF_AMOUNT');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotTask, 'DTK_DIVISOR_AMOUNT');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotTask, 'DTK_RATE1');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotTask, 'DTK_RATE2');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotTask, 'A_DATECRE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotTask, 'A_DATEMOD');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotTask, 'A_IDCRE');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotTask, 'A_IDMOD');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotTask, 'A_RECLEVEL');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotTask, 'A_RECSTATUS');
    FWK_I_MGT_ENTITY_DATA.TransferColumn(iotEv, iotTask, 'A_CONFIRM');
  end ApplyTaskChanges;
end DOC_PRC_EV_ESTIMATE;
