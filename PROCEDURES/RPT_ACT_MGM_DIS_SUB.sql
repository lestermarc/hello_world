--------------------------------------------------------
--  DDL for Procedure RPT_ACT_MGM_DIS_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_MGM_DIS_SUB" (
  aRefCursor             in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, PARAMETER_1            in     varchar2
, PROCUSER_LANID         in     pcs.pc_lang.lanid%type
)
/**
* description used for report ACT_JOURNAL_MGM

* @author jliu 18 nov 2008
* @lastupdate 12 Feb 2009
* @public
* @PARAM PARAMETER_1:  ACT_MGM_DISTRIBUTION_ID
*/

is

VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;


begin

pcs.PC_I_LIB_SESSION.setLanId (procuser_lanid);
VPC_LANG_ID:= pcs.PC_I_LIB_SESSION.GetUserLangId;

open aRefCursor for
SELECT
PJ_ACC.ACC_NUMBER,
DIS.ACT_MGM_DISTRIBUTION_ID,
DIS.MGM_AMOUNT_LC_D,
DIS.MGM_AMOUNT_FC_D,
DIS.MGM_AMOUNT_LC_C,
DIS.MGM_AMOUNT_FC_C
FROM
ACT_MGM_DISTRIBUTION DIS,
ACT_MGM_IMPUTATION IMP,
ACS_ACCOUNT PJ_ACC
WHERE
DIS.ACT_MGM_IMPUTATION_ID = IMP.ACT_MGM_IMPUTATION_ID
AND DIS.ACS_PJ_ACCOUNT_ID = PJ_ACC.ACS_ACCOUNT_ID(+)
AND DIS.ACT_MGM_DISTRIBUTION_ID = to_number(PARAMETER_1)
;
END RPT_ACT_MGM_DIS_SUB;
