--------------------------------------------------------
--  DDL for Procedure SETV_ACT_JOURNAL_COND
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "SETV_ACT_JOURNAL_COND" (
  aJOU_NUMBER_From       varchar2
, aJOU_NUMBER_To         varchar2
, aACS_FINANCIAL_YEAR_ID varchar2
)
is
/**
* Description
*
* @author BL
* @version 2003
* @lastUpdate
* @public
* @param aJOU_NUMBER_From
* @param aJOU_NUMBER_To
* @param aACS_FINANCIAL_YEAR_ID
*/
begin
  ACR_FUNCTIONS.JOU_NUMBER1  := aJOU_NUMBER_From;
  ACR_FUNCTIONS.JOU_NUMBER2  := aJOU_NUMBER_To;
  ACR_FUNCTIONS.FIN_YEAR_ID  := aACS_FINANCIAL_YEAR_ID;
end SetV_ACT_JOURNAL_COND;
