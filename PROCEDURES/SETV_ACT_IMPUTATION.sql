--------------------------------------------------------
--  DDL for Procedure SETV_ACT_IMPUTATION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "SETV_ACT_IMPUTATION" (
  aACC_NUMBER_From       varchar2
, aACC_NUMBER_To         varchar2
, aACS_FINANCIAL_YEAR_ID varchar2
)
is
/**
* Description
*
* @author BL
* @lastUpdate
* @version 2003
* @public
* @param aACC_NUMBER_From
* @param aACC_NUMBER_To
* @param aACS_FINANCIAL_YEAR_ID
*/
begin
  ACR_FUNCTIONS.ACC_NUMBER1  := aACC_NUMBER_From;
  ACR_FUNCTIONS.ACC_NUMBER2  := aACC_NUMBER_To;
  ACR_FUNCTIONS.FIN_YEAR_ID  := aACS_FINANCIAL_YEAR_ID;

  if ACS_FUNCTION.GetFirstDivision is not null then
    ACR_FUNCTIONS.EXIST_DIVISION  := 1;
  else
    ACR_FUNCTIONS.EXIST_DIVISION  := 0;
  end if;
end SetV_ACT_IMPUTATION;
