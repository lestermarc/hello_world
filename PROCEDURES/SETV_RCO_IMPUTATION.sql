--------------------------------------------------------
--  DDL for Procedure SETV_RCO_IMPUTATION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "SETV_RCO_IMPUTATION" (
  aRCO_TITLE_From        varchar2
, aRCO_TITLE_To          varchar2
, aACS_FINANCIAL_YEAR_ID varchar2
)
is
/**
* Description
*
* @author PVO
* @lastUpdate
* @version 2003
* @public
* @param aRCO_TITLE_From
* @param aRCO_TITLE_To
* @param aACS_FINANCIAL_YEAR_ID
* @param aLEVEL
*/
begin
  ACR_FUNCTIONS.RCO_TITLE1     := aRCO_TITLE_From;
  ACR_FUNCTIONS.RCO_TITLE2     := aRCO_TITLE_To;
  ACR_FUNCTIONS.FIN_YEAR_ID    := aACS_FINANCIAL_YEAR_ID;
end SetV_RCO_IMPUTATION;
