--------------------------------------------------------
--  DDL for Procedure RPT_ACS_MGM_PLAN_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACS_MGM_PLAN_SUB" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   PARAMETER_0      IN       VARCHAR2
)
/**
*Description

 Used for sub report of ACS_MGM_PLAN and ACS_MGM_PLAN_STR
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
    DES_CDA.DES_DESCRIPTION_SUMMARY DES_DESCRIPTION_SUMMARY_CDA,
    DES_PF.DES_DESCRIPTION_SUMMARY DES_DESCRIPTION_SUMMARY_PF,
    DES_PJ.DES_DESCRIPTION_SUMMARY DES_DESCRIPTION_SUMMARY_PJ,
    RAC.ACS_CPN_ACCOUNT_ID,
    RAC.ACS_CDA_ACCOUNT_ID,
    RAC.ACS_PF_ACCOUNT_ID,
    RAC.ACS_PJ_ACCOUNT_ID,
    RAC.CDA_NUMBER,
    RAC.PF_NUMBER,
    RAC.PJ_NUMBER,
    RAC.MGM_DEFAULT
   FROM
    V_ACS_MGM_INTERACTION RAC,
    ACS_DESCRIPTION DES_CDA,
    ACS_DESCRIPTION DES_PF,
    ACS_DESCRIPTION DES_PJ
   WHERE
    RAC.ACS_CPN_ACCOUNT_ID = TO_NUMBER(PARAMETER_0 )
    AND RAC.ACS_CDA_ACCOUNT_ID = DES_CDA.ACS_ACCOUNT_ID(+)
    AND DES_CDA.PC_LANG_ID(+) = vpc_lang_id
    AND RAC.ACS_PF_ACCOUNT_ID = DES_PF.ACS_ACCOUNT_ID(+)
    AND DES_PF.PC_LANG_ID(+) = vpc_lang_id
    AND RAC.ACS_PJ_ACCOUNT_ID = DES_PJ.ACS_ACCOUNT_ID(+)
    AND DES_PJ.PC_LANG_ID(+) = vpc_lang_id

    ;

END RPT_ACS_MGM_PLAN_SUB;
