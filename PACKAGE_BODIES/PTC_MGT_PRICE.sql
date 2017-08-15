--------------------------------------------------------
--  DDL for Package Body PTC_MGT_PRICE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PTC_MGT_PRICE" 
is
  /**
  * Description
  *    Code m�tier de l'insertion d'un dossier SAV
  */
  function insertFIXED_COSTPRICE(iotFixedCostprice in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
    lError  varchar2(4000);
  begin
    -- trunc des dates
    PTC_PRC_PRICE.TruncPRFDates(iotFixedCostprice);

    -- If the new price is checked "default", check the current default price to non-default
    if     FWK_I_MGT_ENTITY_DATA.getcolumnBoolean(iotFixedCostprice, 'CPR_DEFAULT')
       and FWK_I_MGT_ENTITY_DATA.getcolumnvarchar2(iotFixedCostprice, 'C_COSTPRICE_STATUS') = 'ACT' then
      PTC_LIB_PRICE.TestOtherDefaultPrice(iotFixedCostprice, lError);
    end if;

    -- Test parity of validity dates
    if lError is null then
      PTC_LIB_PRICE.TestPRFDates(iotFixedCostprice, lError);
    end if;

    -- si pas d'erreur, on ins�re le prix
    if lError is null then
      /***********************************
      ** execution of CRUD instruction
      ***********************************/
      lResult  := fwk_i_dml_table.CRUD(iotFixedCostprice);
      -- retourne le rowid de l'enregistrement cr�� (obligatoire)
      return lResult;
    else
      ra(lError);
    end if;
  end insertFIXED_COSTPRICE;

  /**
  * Description
  *    Code m�tier de l'insertion d'un dossier SAV
  */
  function updateFIXED_COSTPRICE(iotFixedCostprice in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
    lError  varchar2(4000);
  begin
    -- If the new price is checked "default", check the current default price to non-default
    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotFixedCostprice, 'CPR_DEFAULT')
       and FWK_I_MGT_ENTITY_DATA.getcolumnBoolean(iotFixedCostprice, 'CPR_DEFAULT')
       and FWK_I_MGT_ENTITY_DATA.getcolumnvarchar2(iotFixedCostprice, 'C_COSTPRICE_STATUS') = 'ACT' then
      PTC_LIB_PRICE.TestOtherDefaultPrice(iotFixedCostprice, lError);
    end if;

    if     lError is null
       and (   FWK_I_MGT_ENTITY_DATA.IsModified(iotFixedCostprice, 'FCP_START_DATE')
            or FWK_I_MGT_ENTITY_DATA.IsModified(iotFixedCostprice, 'FCP_END_DATE')
           ) then
      PTC_LIB_PRICE.TestPRFDates(iotFixedCostprice, lError);
    end if;

    -- si pas d'erreur, on met � jour le prix
    if lError is null then
      /***********************************
      ** execution of CRUD instruction
      ***********************************/
      lResult  := fwk_i_dml_table.CRUD(iotFixedCostprice);
      -- retourne le rowid de l'enregistrement cr�� (obligatoire)
      return lResult;
    else
      ra(lError);
    end if;
  end updateFIXED_COSTPRICE;

  /**
  * Description
  *    Code m�tier de la cr�ation d'un tarif
  */
  function insertTARIFF(iotTARIFF in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
    lError  varchar2(4000);
  begin
    -- trunc des dates
    PTC_PRC_PRICE.TruncTariffDates(iotTARIFF);

    -- monnaie locale par d�faut
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotTARIFF, 'ACS_FINANCIAL_CURRENCY_ID') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotTARIFF, 'ACS_FINANCIAL_CURRENCY_ID', ACS_FUNCTION.GetLocalCurrencyId);
    end if;

    -- test de la coh�rence des dates de validit�
    if not(   FWK_I_MGT_ENTITY_DATA.IsNull(iotTARIFF, 'TRF_ENDING_DATE')
           or FWK_I_MGT_ENTITY_DATA.IsNull(iotTARIFF, 'TRF_STARTING_DATE')
          ) then
      PTC_LIB_PRICE.TestTariffDates(iotTARIFF, lError);
    end if;

    if lError is null then
      /***********************************
      ** execution of CRUD instruction
      ***********************************/
      lResult  := fwk_i_dml_table.CRUD(iotTARIFF);
      -- retourne le rowid de l'enregistrement cr�� (obligatoire)
      return lResult;
    else
      ra(lError);
    end if;
  end insertTARIFF;

  /**
  * Description
  *    Code m�tier de la mise � jour d'un tarif
  */
  function updateTARIFF(iotTARIFF in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
    lError  varchar2(4000);
  begin
    -- trunc des dates
    PTC_PRC_PRICE.TruncTariffDates(iotTARIFF);

    -- test de la coh�rence des dates de validit�
    if (   FWK_I_MGT_ENTITY_DATA.IsModified(iotTARIFF, 'TRF_ENDING_DATE')
        or FWK_I_MGT_ENTITY_DATA.IsModified(iotTARIFF, 'TRF_STARTING_DATE')
       ) then
      PTC_LIB_PRICE.TestTariffDates(iotTARIFF, lError);
    end if;

    if lError is null then
      /***********************************
      ** execution of CRUD instruction
      ***********************************/
      lResult  := fwk_i_dml_table.CRUD(iotTARIFF);
      -- retourne le rowid de l'enregistrement cr�� (obligatoire)
      return lResult;
    else
      ra(lError);
    end if;
  end updateTARIFF;

  /**
  * Description
  *    Code m�tier de la mise � jour d'un tarif
  */
  function deleteTARIFF(iotTARIFF in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
    lError  varchar2(4000);
  begin
    -- Effacement en cascade des tabelles de tarifs
    FWK_I_MGT_ENTITY.DeleteChildren(iv_child_name         => 'PTC_TARIFF_TABLE'
                                  , iv_parent_key_name    => 'PTC_TARIFF_ID'
                                  , iv_parent_key_value   => FWK_I_MGT_ENTITY_DATA.getColumnNumber(iotTARIFF, 'PTC_TARIFF_ID')
                                   );
    /***********************************
    ** execution of CRUD instruction
    ***********************************/
    lResult  := fwk_i_dml_table.CRUD(iotTARIFF);
    -- retourne le rowid de l'enregistrement cr�� (obligatoire)
    return lResult;
  end deleteTARIFF;

  /**
  * Description
  *    Code m�tier de la cr�ation d'un �l�ment de tabelle de tarif
  */
  function insertTARIFF_TABLE(iotTARIFF_TABLE in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
    lError  varchar2(4000);
  begin
    -- test de la coh�rence de la tabelle de quantit�
    if not(   FWK_I_MGT_ENTITY_DATA.IsNull(iotTARIFF_TABLE, 'TTA_FROM_QUANTITY')
           or FWK_I_MGT_ENTITY_DATA.IsNull(iotTARIFF_TABLE, 'TTA_TO_QUANTITY')
          ) then
      PTC_LIB_PRICE.TestTariffTableQuantities(iotTARIFF_TABLE, lError);
    end if;

    if lError is null then
      /***********************************
      ** execution of CRUD instruction
      ***********************************/
      lResult  := fwk_i_dml_table.CRUD(iotTARIFF_TABLE);
      -- retourne le rowid de l'enregistrement cr�� (obligatoire)
      return lResult;
    else
      ra(lError);
    end if;
  end insertTARIFF_TABLE;

  /**
  * Description
  *    Code m�tier de la mise � jour d'un �l�ment de tabelle de tarif
  */
  function updateTARIFF_TABLE(iotTARIFF_TABLE in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
    lError  varchar2(4000);
  begin
    -- test de la coh�rence de la tabelle de quantit�
    if (   FWK_I_MGT_ENTITY_DATA.IsModified(iotTARIFF_TABLE, 'TTA_FROM_QUANTITY')
        or FWK_I_MGT_ENTITY_DATA.IsModified(iotTARIFF_TABLE, 'TTA_TO_QUANTITY')
       ) then
      PTC_LIB_PRICE.TestTariffTableQuantities(iotTARIFF_TABLE, lError);
    end if;

    if lError is null then
      /***********************************
      ** execution of CRUD instruction
      ***********************************/
      lResult  := fwk_i_dml_table.CRUD(iotTARIFF_TABLE);
      -- retourne le rowid de l'enregistrement cr�� (obligatoire)
      return lResult;
    else
      ra(lError);
    end if;
  end updateTARIFF_TABLE;
end PTC_MGT_PRICE;
