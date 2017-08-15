--------------------------------------------------------
--  DDL for Package Body WEB_REPORT_INIT_PROC
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WEB_REPORT_INIT_PROC" 
IS
  procedure InitWebPosition
  is
    cursor crInterfacePosInfo(cInterfacePosID in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type)
    is
      select DOP_DISCOUNT_RATE
           , STM_STOCK_ID
           , STM_STM_STOCK_ID
           , STM_LOCATION_ID
           , STM_STM_LOCATION_ID
           , DOP_GROSS_UNIT_VALUE
        from DOC_INTERFACE_POSITION
       where DOC_INTERFACE_POSITION_ID = cInterfacePosID;
    tplInterfacePosInfo  crInterfacePosInfo%rowtype;
  begin
    DOC_POSITION_INITIALIZE.InitPosition_140;

    open crInterfacePosInfo(DOC_POSITION_INITIALIZE.PositionInfo.DOC_INTERFACE_POSITION_ID);
    fetch crInterfacePosInfo into tplInterfacePosInfo;

    if crInterfacePosInfo%found then

      if tplInterfacePosInfo.DOP_GROSS_UNIT_VALUE is null then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_GOOD_PRICE := 0;
        DOC_POSITION_INITIALIZE.PositionInfo.GOOD_PRICE     := null;
      else
        DOC_POSITION_INITIALIZE.PositionInfo.USE_GOOD_PRICE  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.GOOD_PRICE      := tplInterfacePosInfo.DOP_GROSS_UNIT_VALUE;
      end if;

      if tplInterfacePosInfo.DOP_DISCOUNT_RATE is null then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_DISCOUNT_RATE  := 0;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_DISCOUNT_RATE      := null;
      else
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_DISCOUNT_RATE  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_DISCOUNT_RATE      := tplInterfacePosInfo.DOP_DISCOUNT_RATE;
      end if;

      if (tplInterfacePosInfo.STM_STOCK_ID is null) and (tplInterfacePosInfo.STM_LOCATION_ID is null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_STOCK        := 0;
        DOC_POSITION_INITIALIZE.PositionInfo.STM_STOCK_ID     := null;
        DOC_POSITION_INITIALIZE.PositionInfo.STM_LOCATION_ID  := null;
      else
        DOC_POSITION_INITIALIZE.PositionInfo.USE_STOCK        := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.STM_STOCK_ID     := tplInterfacePosInfo.STM_STOCK_ID;
        DOC_POSITION_INITIALIZE.PositionInfo.STM_LOCATION_ID  := tplInterfacePosInfo.STM_LOCATION_ID;
      end if;

      if (tplInterfacePosInfo.STM_STM_STOCK_ID is null) and (tplInterfacePosInfo.STM_STM_LOCATION_ID is null) then
        DOC_POSITION_INITIALIZE.PositionInfo.USE_TRANSFERT_STOCK  := 0;
        DOC_POSITION_INITIALIZE.PositionInfo.STM_STM_STOCK_ID     := null;
        DOC_POSITION_INITIALIZE.PositionInfo.STM_STM_LOCATION_ID  := null;
      else
        DOC_POSITION_INITIALIZE.PositionInfo.USE_TRANSFERT_STOCK  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.STM_STM_STOCK_ID     := tplInterfacePosInfo.STM_STM_STOCK_ID;
        DOC_POSITION_INITIALIZE.PositionInfo.STM_STM_LOCATION_ID  := tplInterfacePosInfo.STM_STM_LOCATION_ID;
      end if;
    end if;

    close crInterfacePosInfo;
  end InitWebPosition;

END WEB_REPORT_INIT_PROC;
