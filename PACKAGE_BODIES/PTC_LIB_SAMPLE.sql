--------------------------------------------------------
--  DDL for Package Body PTC_LIB_SAMPLE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PTC_LIB_SAMPLE" 
is

  /**
  * Description
  *   sample function to use as PL/SQL function in the creation options definition screen
  *   in the tariff wizard.
  *   the new prices wilbe 100% more for manufactured products and 50% more for buyed products
  */
  function NewPriceFromFCP(iFCPId in number)
    return number
  is
    lSupplyMode GCO_PRODUCT.C_SUPPLY_MODE%type;
    lSourcePrice PTC_FIXED_COSTPRICE.CPR_PRICE%type;
    lResult PTC_FIXED_COSTPRICE.CPR_PRICE%type;
  begin
    -- get supply mode and source price
    select C_SUPPLY_MODE, CPR_PRICE
      into lSupplyMode,lSourcePrice
      from GCO_PRODUCT PDT, PTC_FIXED_COSTPRICE FCP
     where PDT.GCO_GOOD_ID = FCP.GCO_GOOD_ID
       and FCP.PTC_FIXED_COSTPRICE_ID = iFCPId;
    -- apply transFromation rules (+50% for purchased products, +100% for manufactures products, same price for the others)
    case
      when lSupplyMode = '1' then -- purchased
        lResult := lSourcePrice*1.5;
      when lSupplyMode = '1' then -- manufactured
        lResult := lSourcePrice*2;
      else
        lResult := lSourcePrice;
    end case;
    return lResult;
  exception
    -- if source not found
    when NO_DATA_FOUND then
      lResult := null;
  end NewPriceFromFCP;

  /**
  * Description
  *   sample function to use as PL/SQL function in the creation options definition screen
  *   in the tariff wizard.
  *   the new prices will be based on the given calculated costprice adding 2% more
  *   for manufactured products and 5% more for buyed products
  */
  function NewPriceFromCCP(iCCPId in number)
    return number
  is
    lSupplyMode GCO_PRODUCT.C_SUPPLY_MODE%type;
    lSourcePrice PTC_FIXED_COSTPRICE.CPR_PRICE%type;
    lResult PTC_FIXED_COSTPRICE.CPR_PRICE%type;
  begin
    -- get supply mode and source price
    select C_SUPPLY_MODE, CPR_PRICE
      into lSupplyMode,lSourcePrice
      from GCO_PRODUCT PDT, PTC_CALC_COSTPRICE CCP
     where PDT.GCO_GOOD_ID = CCP.GCO_GOOD_ID
       and CCP.PTC_CALC_COSTPRICE_ID = iCCPId;
    -- apply transFromation rules (+2% for purchased products, +5% for manufactures products, same price for the others)
    case
      when lSupplyMode = '1' then -- purchased
        lResult := lSourcePrice*1.02;
      when lSupplyMode = '1' then -- manufactured
        lResult := lSourcePrice*1.05;
      else
        lResult := lSourcePrice;
    end case;
    return lResult;
  exception
    -- if source not found
    when NO_DATA_FOUND then
      lResult := null;
  end NewPriceFromCCP;

  /**
  * Description
  *   sample function to use as PL/SQL function in the creation options definition screen
  *   in the tariff wizard.
  *   the new prices will be 10% more for manufactured products and 20% more for buyed products
  */
  function NewPriceFromTariff(iTariffTableId in number)
    return number
  is
    lSupplyMode GCO_PRODUCT.C_SUPPLY_MODE%type;
    lSourcePrice PTC_FIXED_COSTPRICE.CPR_PRICE%type;
    lResult PTC_FIXED_COSTPRICE.CPR_PRICE%type;
  begin
    -- get supply mode and source price
    -- the tariff must be in local currency
    -- only table starting with qty 0
    select C_SUPPLY_MODE, TTA_PRICE
      into lSupplyMode, lSourcePrice
      from GCO_PRODUCT PDT, PTC_TARIFF TRF, PTC_TARIFF_TABLE TTA
     where PDT.GCO_GOOD_ID = TRF.GCO_GOOD_ID
       and TTA.PTC_TARIFF_TABLE_ID = iTariffTableId
       and TRF.PTC_TARIFF_ID = TTA.PTC_TARIFF_ID
       and TRF.ACS_FINANCIAL_CURRENCY_ID = ACS_FUNCTION.GetLocalCurrencyId
       and TTA.TTA_FROM_QUANTITY = 0;
    -- apply transformation rules (+50% for purchased products, +100% for manufactures products, same price for the others)
    case
      when lSupplyMode = '1' then -- purchased
        lResult := lSourcePrice*1.1;
      when lSupplyMode = '1' then -- manufactured
        lResult := lSourcePrice*1.2;
      else
        lResult := lSourcePrice;
    end case;
    return lResult;

  exception
    -- may be the source tarif is not in local currency, in this case the function return 0
    when NO_DATA_FOUND then
      return null;
  end NewPriceFromTariff;

  /**
  * Description
  *   sample function to use as PL/SQL function in the creation options definition screen
  *   in the tariff wizard.
  *   the new prices will be based on WAC of the given good adding 33% more
  *   for manufactured products and 66% more for buyed products
  */
  function NewPriceFromWAC(iGoodId in number)
    return number
  is
    lSupplyMode GCO_PRODUCT.C_SUPPLY_MODE%type;
    lSourcePrice PTC_FIXED_COSTPRICE.CPR_PRICE%type;
    lResult PTC_FIXED_COSTPRICE.CPR_PRICE%type;
  begin
    -- get supply mode and source price
    select C_SUPPLY_MODE, GOO_BASE_COST_PRICE
      into lSupplyMode,lSourcePrice
      from GCO_PRODUCT PDT, GCO_GOOD_CALC_DATA GCD
     where PDT.GCO_GOOD_ID = GCD.GCO_GOOD_ID
       and GCD.GCO_GOOD_ID = iGoodId;
    -- apply transFromation rules (+50% for purchased products, +100% for manufactures products, same price for the others)
    case
      when lSupplyMode = '1' then -- purchased
        lResult := lSourcePrice*1.5;
      when lSupplyMode = '1' then -- manufactured
        lResult := lSourcePrice*2;
      else
        lResult := lSourcePrice;
    end case;
    return lResult;
  end NewPriceFromWAC;

end PTC_LIB_SAMPLE;
