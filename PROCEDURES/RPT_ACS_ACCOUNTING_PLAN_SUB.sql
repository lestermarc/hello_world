--------------------------------------------------------
--  DDL for Procedure RPT_ACS_ACCOUNTING_PLAN_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACS_ACCOUNTING_PLAN_SUB" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   PARAMETER_0      IN       VARCHAR2
)
/**
*Description

 Used for report ACS_ACCOUNTING_PLAN,ACS_ACCOUNTING_PLAN_STR
*@created MZHU 22.DEC.2009
*@lastUpdate
*@public
*@PARAM PARAMETER_0    ACCCOUNT NUMBER (FROM)
*/

IS


BEGIN


  OPEN arefcursor FOR
  SELECT
          acc.acc_number
     FROM ACS_INTERACTION acs,acs_account acc, acs_division_account div, acs_sub_set sub
    WHERE ACS.ACS_DIVISION_ACCOUNT_ID = DIV.ACS_DIVISION_ACCOUNT_ID
      AND div.acs_division_account_id = acc.acs_account_id
      AND acc.acs_sub_set_id = sub.acs_sub_set_id
      AND sub.c_type_sub_set = 'DIVI'
      and ACS.ACS_FINANCIAL_ACCOUNT_ID = to_number(parameter_0)
    ;

END RPT_ACS_ACCOUNTING_PLAN_SUB ;
