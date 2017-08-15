--------------------------------------------------------
--  DDL for Procedure RPT_ACS_AUXILIARY_ACC_LIST
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACS_AUXILIARY_ACC_LIST" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
/**
*Description

 Used for report ACS_AUXILIARY_ACC_LIST
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
    ACC.ACC_VALID_TO,
    ACC.ACC_VALID_SINCE,
    ACC_COL.ACC_NUMBER ACC_NUMBER_COL,
    ACC_SUB.ACC_NUMBER ACC_NUMBER_SUB,
    AUX.C_TYPE_ACCOUNT,
    SUB.ACS_SUB_SET_ID,
    DES_1.DES_DESCRIPTION_SUMMARY,
    DES_2.DES_DESCRIPTION_SUMMARY DES_DESCRIPTION_SUMMARY_2,
    DES_2.DES_DESCRIPTION_LARGE DES_DESCRIPTION_LARGE_2
   FROM
    ACS_ACCOUNT ACC,
    ACS_ACCOUNT ACC_COL,
    ACS_ACCOUNT ACC_SUB,
    ACS_AUXILIARY_ACCOUNT AUX,
    ACS_SUB_SET SUB,
    ACS_DESCRIPTION DES_1,
    ACS_DESCRIPTION DES_2
   WHERE
    AUX.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
    AND ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
    AND SUB.ACS_PROP_INVOICE_COLL_ID = ACC_SUB.ACS_ACCOUNT_ID
    AND AUX.ACS_INVOICE_COLL_ID = ACC_COL.ACS_ACCOUNT_ID
    AND SUB.ACS_SUB_SET_ID = DES_1.ACS_SUB_SET_ID
    AND DES_1.PC_LANG_ID = vpc_lang_id
    AND ACC.ACS_ACCOUNT_ID = DES_2.ACS_ACCOUNT_ID
    AND DES_2.PC_LANG_ID = vpc_lang_id


    ;

END RPT_ACS_AUXILIARY_ACC_LIST;
