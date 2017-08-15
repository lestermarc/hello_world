--------------------------------------------------------
--  DDL for Procedure RPT_ACS_MGM_PLAN
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACS_MGM_PLAN" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   PARAMETER_0      IN       VARCHAR2,
   PARAMETER_1      IN       VARCHAR2
)
/**
*Description

 Used for report ACS_MGM_PLAN
*@created JLIU 30.JULY.2009
*@lastUpdate 30.JULY.2009
*@public
*@PARAM PARAMETER_0    ACCCOUNT NUMBER (FROM)
*@PARAM PARAMETER_1    ACCCOUNT NUMBER (TO)
*/

IS

   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;              --user language id
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

  OPEN arefcursor FOR
  SELECT
    ACC.ACC_NUMBER,
    ACC.ACC_BLOCKED,
    ACC.ACC_VALID_TO,
    ACC.ACC_VALID_SINCE,
    CPN.ACS_CPN_ACCOUNT_ID,
    DES.PC_LANG_ID,
    DES.DES_DESCRIPTION_SUMMARY,
    DES.DES_DESCRIPTION_LARGE
   FROM
    ACS_ACCOUNT ACC,
    ACS_DESCRIPTION DES,
    ACS_CPN_ACCOUNT CPN
   WHERE
    CPN.ACS_CPN_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
    AND CPN.ACS_CPN_ACCOUNT_ID = DES.ACS_ACCOUNT_ID(+)
    AND DES.PC_LANG_ID = vpc_lang_id
    AND ((PARAMETER_0 IS NULL  AND PARAMETER_1 IS NULL ) OR
    (PARAMETER_1 IS NULL AND ACC.ACC_NUMBER >= PARAMETER_0) OR
    (PARAMETER_0 IS NULL AND ACC.ACC_NUMBER <= PARAMETER_1) OR
    (PARAMETER_0 IS NOT NULL AND PARAMETER_1 IS NOT NULL AND ACC.ACC_NUMBER >= PARAMETER_0 AND ACC.ACC_NUMBER <= PARAMETER_1))

    ;

END RPT_ACS_MGM_PLAN;
