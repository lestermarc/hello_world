--------------------------------------------------------
--  DDL for Package Body GCO_PUBLIC
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_PUBLIC" 
as
  function GetCostPriceWithManagementMode(aGCO_GOOD_ID in number)
    return number
  is
  begin
    return GCO_FUNCTIONS.GetCostPriceWithManagementMode(aGCO_GOOD_ID);
  end;

  function GetFixedStockPosition(
    GoodId     GCO_COMPL_DATA_INVENTORY.GCO_GOOD_ID%type
  , StockId    GCO_COMPL_DATA_INVENTORY.STM_STOCK_ID%type
  , LocationId GCO_COMPL_DATA_INVENTORY.STM_LOCATION_ID%type
  )
    return GCO_COMPL_DATA_INVENTORY.CIN_FIXED_STOCK_POSITION%type
  is
  begin
    return GCO_FUNCTIONS.GetFixedStockPosition(GoodId, StockId, LocationId);
  end;

  function GetGenCod(aFirmNumber in varchar2, aReference in varchar2)
    return varchar2
  is
  begin
    return GCO_EAN.GetGenCod(aFirmNumber, aReference);
  end;
end GCO_PUBLIC;
