--------------------------------------------------------
--  DDL for Procedure RPT_ACS_ACCOUNTING_PLAN
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACS_ACCOUNTING_PLAN" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   PARAMETER_2      IN       VARCHAR2,
   PARAMETER_3      IN       VARCHAR2
)
/**
*Description

 Used for report ACS_ACCOUNTING_PLAN
*@created JLIU 30.JULY.2009
*@lastUpdate MAY 2010
*@public
*@PARAM PARAMETER_2    ACCCOUNT NUMBER (FROM)
*@PARAM PARAMETER_3    ACCCOUNT NUMBER (TO)
*/

IS

   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;              --user language id

BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

  OPEN arefcursor FOR
  SELECT
    ACC.ACS_ACCOUNT_ID,
    ACC.ACC_NUMBER,
    ACC.ACC_BLOCKED,
    ACC.ACC_VALID_TO,
    ACC.ACC_VALID_SINCE,
    DES.PC_LANG_ID,
    DES.DES_DESCRIPTION_SUMMARY,
    DES.DES_DESCRIPTION_LARGE,
    FCC.ACS_FINANCIAL_ACCOUNT_ID,
    FCC.FIN_COLLECTIVE
   FROM
    ACS_ACCOUNT ACC,
    ACS_DESCRIPTION DES,
    ACS_FINANCIAL_ACCOUNT FCC
   WHERE
    FCC.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
    AND FCC.ACS_FINANCIAL_ACCOUNT_ID = DES.ACS_ACCOUNT_ID(+)
    AND DES.PC_LANG_ID = vpc_lang_id
    AND ACC.ACC_NUMBER >= NVL(PARAMETER_2,'00000')
    AND ACC.ACC_NUMBER <= NVL(PARAMETER_3,'ZZZZZZ');

END RPT_ACS_ACCOUNTING_PLAN ;
