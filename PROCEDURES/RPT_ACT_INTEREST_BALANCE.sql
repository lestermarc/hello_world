--------------------------------------------------------
--  DDL for Procedure RPT_ACT_INTEREST_BALANCE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_INTEREST_BALANCE" (
  aRefCursor             in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, PARAMETER_00           in     varchar2
, PARAMETER_01           in     varchar2
, PARAMETER_02           in     varchar2
, PROCUSER_LANID         in     pcs.pc_lang.lanid%type
)
is

/**
*DESCRIPTION
USED FOR REPORT ACT_INTEREST_BALANCE
*author JLI
*lastUpdate 2009-4-7
*public
*@param PARAMETER_00:  FINANCIAL YEAR ID
*@param PARAMETER_01:  icm_description
*@param PARAMETER_02:  icm_description
*/

TMP NUMBER;
VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;

BEGIN

pcs.PC_I_LIB_SESSION.setLanId (procuser_lanid);
VPC_LANG_ID:= pcs.PC_I_LIB_SESSION.GetUserLangId;

open aRefCursor for
SELECT DISTINCT
job.act_job_id,
icm.acs_int_calc_method_id,
icm.icm_description,
typ.c_type_cumul,
(SELECT MAX (cal.act_calc_period_id)
     FROM act_calc_period cal
     WHERE cal.act_job_id = job.act_job_id) act_calc_period_id,
(SELECT MAX (cal.acs_period_id)
     FROM act_calc_period cal
     WHERE cal.act_job_id = job.act_job_id) acs_period_id,
fye.acs_financial_year_id,
fye.fye_no_exercice,
mel.acs_financial_account_id,
mel.acs_financial_currency_id mel_acs_financial_currency_id,
fin.acc_number fin_number,
fin.pac_person_id,
imp.imf_acs_division_account_id
acs_division_account_id,
(SELECT acc.acc_number
     FROM acs_account acc
     WHERE acc.acs_account_id =imp.imf_acs_division_account_id) div_number,
doc.act_document_id,
doc.doc_number,
imp.imf_description,
imp.imf_amount_lc_d,
imp.imf_amount_lc_c,
imp.imf_amount_fc_d,
imp.imf_amount_fc_c,
imp.act_financial_imputation_id,
imp.c_genre_transaction,
des.DES_DESCRIPTION_SUMMARY,
imp.IMF_EXCHANGE_RATE,
imp.ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID,
cur_me.CURRENCY currency_me,
imp.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID,
cur_mb.CURRENCY currency_mb
FROM
act_financial_imputation imp,
act_document doc,
acs_account fin,
acs_method_elem mel,
act_calc_period cal,
acs_financial_year fye,
act_job job,
acs_calc_cumul_type typ,
acs_int_calc_method icm,
acs_description des,
acs_financial_currency fur_mb,
PCS.PC_CURR cur_mb,
acs_financial_currency fur_me,
PCS.PC_CURR cur_me
WHERE
(PARAMETER_00 = 0 OR fye.acs_financial_year_id = TO_NUMBER(PARAMETER_00))
AND (PARAMETER_01 IS NULL OR icm.icm_description >= PARAMETER_01)
AND (PARAMETER_02 IS NULL OR icm.icm_description <= PARAMETER_02)
AND job.act_job_id = cal.act_job_id
AND job.acs_financial_year_id = fye.acs_financial_year_id
AND cal.acs_int_calc_method_id = icm.acs_int_calc_method_id
AND icm.acs_int_calc_method_id = mel.acs_int_calc_method_id
AND typ.acs_int_calc_method_id = icm.acs_int_calc_method_id
AND mel.acs_financial_account_id = fin.acs_account_id
AND job.act_job_id = doc.act_job_id
AND doc.act_document_id = imp.act_document_id
AND mel.acs_financial_account_id = imp.acs_financial_account_id
AND des.ACS_ACCOUNT_ID = imp.acs_financial_account_id
AND des.PC_LANG_ID = VPC_LANG_ID
AND imp.ACS_FINANCIAL_CURRENCY_ID = fur_me.ACS_FINANCIAL_CURRENCY_ID
AND fur_me.PC_CURR_ID = cur_me.PC_CURR_ID
AND imp.ACS_ACS_FINANCIAL_CURRENCY_ID = fur_mb.ACS_FINANCIAL_CURRENCY_ID
AND fur_mb.PC_CURR_ID = cur_mb.PC_CURR_ID
;
END RPT_ACT_INTEREST_BALANCE;
