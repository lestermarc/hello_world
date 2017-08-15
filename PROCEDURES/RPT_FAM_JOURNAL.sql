--------------------------------------------------------
--  DDL for Procedure RPT_FAM_JOURNAL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAM_JOURNAL" (
  aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, PARAMETER_00   in     varchar2
, PARAMETER_01   in     varchar2
, PARAMETER_02   in     varchar2
, PROCUSER_LANID in     pcs.pc_lang.lanid%type
)
is
/**
* Description - used for the report FAM_JOURNAL

* @CREATED IN PROCONCEPT CHINA
* @AUTHOR JLIU 12 MAY 2009
* @param PARAMETER_0    ACS_FINANCIAL_YEAR_ID
* @param PARAMETER_1    FJO_NUMBER
* @param PARAMETER_2    FJO_NUMBER
*/

VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;

begin
  pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
  VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

OPEN aRefCursor FOR
SELECT
FUR.FIN_LOCAL_CURRENCY,
YEA.FYE_NO_EXERCICE,
FDT.FAM_DOCUMENT_ID,
FDT.FDO_INT_NUMBER,
FDT.FDO_EXT_NUMBER,
FDT.FDO_DOCUMENT_DATE,
FIX.FIX_NUMBER,
FIX.FIX_SHORT_DESCR,
TEG.CAT_DESCR,
FIM.FIM_DESCR,
FIM.FIM_TRANSACTION_DATE,
FIM.FIM_VALUE_DATE,
FIM.FIM_AMOUNT_LC_D,
FIM.FIM_AMOUNT_LC_C,
FIM.FIM_AMOUNT_FC_D,
FIM.FIM_AMOUNT_FC_C,
FIM.FIM_EXCHANGE_RATE,
FIM.C_FAM_TRANSACTION_TYP,
JOU.FAM_JOURNAL_ID,
JOU.C_JOURNAL_STATUS,
JOU.FJO_NUMBER,
JOU.FJO_DESCR,
JOU.A_DATECRE,
JOU.A_DATEMOD,
JOU.A_IDCRE,
VAL.C_VALUE_CATEGORY,
VAL.VAL_KEY,
VAL.VAL_DESCR,
CUR.CURRENCY
FROM
ACS_FINANCIAL_CURRENCY FUR,
ACS_FINANCIAL_YEAR YEA,
FAM_CATALOGUE CAT,
FAM_DOCUMENT FDT,
FAM_FIXED_ASSETS FIX,
FAM_FIXED_ASSETS_CATEG TEG,
FAM_IMPUTATION FIM,
FAM_JOURNAL JOU,
FAM_MANAGED_VALUE VAL,
FAM_VAL_IMPUTATION VIM,
PCS.PC_CURR CUR
WHERE
FDT.FAM_DOCUMENT_ID = FIM.FAM_DOCUMENT_ID(+)
AND FIM.FAM_IMPUTATION_ID = VIM.FAM_IMPUTATION_ID(+)
AND VIM.FAM_MANAGED_VALUE_ID = VAL.FAM_MANAGED_VALUE_ID(+)
AND FIM.ACS_FINANCIAL_CURRENCY_ID = FUR.ACS_FINANCIAL_CURRENCY_ID
AND FUR.PC_CURR_ID = CUR.PC_CURR_ID
AND FIM.FAM_FIXED_ASSETS_ID = FIX.FAM_FIXED_ASSETS_ID(+)
AND FIM.FAM_FIXED_ASSETS_CATEG_ID = TEG.FAM_FIXED_ASSETS_CATEG_ID
AND FDT.FAM_CATALOGUE_ID = CAT.FAM_CATALOGUE_ID(+)
AND FDT.FAM_JOURNAL_ID = JOU.FAM_JOURNAL_ID
AND JOU.ACS_FINANCIAL_YEAR_ID = YEA.ACS_FINANCIAL_YEAR_ID
AND YEA.FYE_NO_EXERCICE = TO_NUMBER(PARAMETER_00)
AND JOU.FJO_NUMBER >= PARAMETER_01
AND JOU.FJO_NUMBER <= PARAMETER_02
;
end RPT_FAM_JOURNAL;
