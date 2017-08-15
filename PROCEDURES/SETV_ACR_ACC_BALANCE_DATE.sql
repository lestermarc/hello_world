--------------------------------------------------------
--  DDL for Procedure SETV_ACR_ACC_BALANCE_DATE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "SETV_ACR_ACC_BALANCE_DATE" (
  aACC_NUMBER_From       varchar2
, aACC_NUMBER_To         varchar2
, aACS_FINANCIAL_YEAR_ID varchar2
, aCUMUL_DATE            varchar2
, aCUMUL_DATE_FROM       varchar2
)
is
/**
* Description
*
* @author BL
* @version 2003
* @lastUpdate
* @public
* @param aACC_NUMBER_From
* @param aACC_NUMBER_To
* @param aACS_FINANCIAL_YEAR_ID
* @param aCUMUL_DATE
* @param aCUMUL_DATE_FROM
*/
begin
  ACR_FUNCTIONS.ACC_NUMBER1      := aACC_NUMBER_From;
  ACR_FUNCTIONS.ACC_NUMBER2      := aACC_NUMBER_To;
  ACR_FUNCTIONS.FIN_YEAR_ID      := aACS_FINANCIAL_YEAR_ID;
  ACR_FUNCTIONS.CUMUL_DATE       := to_date(aCUMUL_DATE, 'yyyymmdd');
  ACR_FUNCTIONS.CUMUL_DATE_FROM  := to_date(aCUMUL_DATE_FROM, 'yyyymmdd');

  if ACS_FUNCTION.GetFirstDivision is not null then
    ACR_FUNCTIONS.EXIST_DIVISION  := 1;
  else
    ACR_FUNCTIONS.EXIST_DIVISION  := 0;
  end if;
end SetV_ACR_ACC_BALANCE_DATE;
