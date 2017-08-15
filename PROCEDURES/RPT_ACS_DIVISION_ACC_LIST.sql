--------------------------------------------------------
--  DDL for Procedure RPT_ACS_DIVISION_ACC_LIST
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACS_DIVISION_ACC_LIST" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
/**
*Description

 Used for report ACS_DIVISION_ACC_LIST
*@created JLIU 30.JULY.2009
*@lastUpdate 30.JULY.2009
*@public
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
    ACC.ACS_SUB_SET_ID,
    DES.DES_DESCRIPTION_SUMMARY,
    DES.DES_DESCRIPTION_LARGE,
    ACC.ACC_VALID_SINCE,
    ACC.ACC_VALID_TO,
    DIV.DIV_DEFAULT_ACCOUNT
   FROM
    ACS_ACCOUNT ACC,
    ACS_DIVISION_ACCOUNT DIV,
    ACS_DESCRIPTION DES
   WHERE
    DIV.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
   AND ACC.ACS_ACCOUNT_ID = DES.ACS_ACCOUNT_ID
   AND DES.PC_LANG_ID = vpc_lang_id
    ;

END RPT_ACS_DIVISION_ACC_LIST;
