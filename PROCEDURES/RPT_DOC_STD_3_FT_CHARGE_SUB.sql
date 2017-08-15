--------------------------------------------------------
--  DDL for Procedure RPT_DOC_STD_3_FT_CHARGE_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_STD_3_FT_CHARGE_SUB" (
  arefcursor in OUT CRYSTAL_CURSOR_TYPES.dualcursortyp
, parameter_3 in number
)
is
/**
*Description - Used for report DOC_STD_3

*@created MZHU 17 MAY 2009
*@lastUpdate VHA 15.05.2014
*@public
*@param parameter_3:  DOC_FOOT_ID
*/
begin
  open arefcursor for
    select ACC.ACC_NUMBER
         , FCH.FCH_DESCRIPTION
         , FCH.FCH_NAME
         , FCH.FCH_EXCL_AMOUNT
         , FCH.FCH_INCL_AMOUNT
         , FCH_RATE
         , FCH.PTC_DISCOUNT_ID
         , case nvl(FCH.C_CALCULATION_MODE, FCH.C_CALCULATION_MODE)
             when '0' then 'AMOUNT'
             when '1' then 'AMOUNT'
             when '6' then 'AMOUNT'
             when '8' then 'AMOUNT'
             when '2' then 'RATE'
             when '3' then 'RATE'
             when '4' then 'RATE'
             when '5' then 'RATE'
             when '7' then 'RATE'
             when '9' then 'RATE'
           end CHARGE_CALCULATION_MODE
         , FCH.FCH_EXPRESS_IN
         , FCH.PTC_CHARGE_ID
         , decode(FCH.PTC_DISCOUNT_ID, null, 2, 1) DIS_SUR_GRP
         , FCH_IN_SERIES_CALCULATION
      from ACS_ACCOUNT ACC
         , ACS_TAX_CODE TAX
         , DOC_FOOT_CHARGE FCH
     where TAX.ACS_TAX_CODE_ID(+) = FCH.ACS_TAX_CODE_ID
       and ACC.ACS_ACCOUNT_ID(+) = TAX.ACS_TAX_CODE_ID
       and FCH.DOC_FOOT_ID = parameter_3;
end RPT_DOC_STD_3_FT_CHARGE_SUB;
