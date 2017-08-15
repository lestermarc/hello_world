--------------------------------------------------------
--  DDL for Procedure RPT_ACT_ACC_IMP_ME_SUB_1
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_ACC_IMP_ME_SUB_1" (
  aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp,
  PROCPARAM_0    in number,
  PROCPARAM_3    in varchar2,
  PARAMETER_0    in varchar2,
  PARAMETER_1    in varchar2,
  PARAMETER_2    in varchar2,
  PARAMETER_3    in varchar2,
  PARAMETER_4    in varchar2,
  PARAMETER_5    in varchar2,
  PARAMETER_6    in varchar2,
  PARAMETER_7    in varchar2,
  PARAMETER_8    in varchar2,
  PARAMETER_12   in varchar2,
  PARAMETER_13   in varchar2,
  PARAMETER_14   in number
)
is

/**
* description used for report ACT_ACC_IMP_ME_1 , THE SUB REPORT OF ACR_ACC_IMPUTATION_DET.RPT

* @author SDO 2003
* @lastupdate May 2010
* @public
* @param PROCPARAM_0    FYE_NO_EXERCICE
* @param PROCPARAM_3    Division_ID (List)
* @param PARAMETER_0    DATE_FROM
* @param PARAMETER_1    DATE_TO
* @param PARAMETER_2    JOURNAL_STATUS
* @param PARAMETER_3    JOURNAL_STATUS
* @param PARAMETER_4    JOURNAL_STATUS
* @param PARAMETER_5    C_TYPE_CUMUL
* @param PARAMETER_5    C_TYPE_CUMUL
* @param PARAMETER_6    C_TYPE_CUMUL
* @param PARAMETER_7    C_TYPE_CUMUL
* @param PARAMETER_8    C_TYPE_CUMUL
* @param PARAMETER_12   WITH START SUBTOTAL
* @param PARAMETER_13   ONLY TRANSACTION WITH VAT CODE
* @param PARAMETER_14   ACS_FINANCIAL_ACCOUNT_ID
*/

BEGIN
open aRefCursor for
SELECT
'REEL' info,
 imp.imf_transaction_date imf_transaction_date,
 imp.imf_amount_lc_d imf_amount_lc_d,
 imp.imf_amount_lc_c imf_amount_lc_c,
 imp.imf_amount_fc_d imf_amount_fc_d,
 imp.imf_amount_fc_c imf_amount_fc_c,
 imp.acs_acs_financial_currency_id acs_acs_financial_currency_id,
 acs_function.getcurrencyname(imp.acs_acs_financial_currency_id) currency_mb,
 imp.acs_financial_currency_id acs_financial_currency_id,
 acs_function.getcurrencyname(imp.acs_financial_currency_id) currency_me,
 imp.acs_financial_account_id acs_financial_account_id,
 imp.imf_acs_division_account_id acs_division_account_id,
 imp.acs_tax_code_id acs_tax_code_id,
 fye.fye_no_exercice fye_no_exercice,
 eta.C_ETAT_JOURNAL,
 sca.C_TYPE_CUMUL
FROM
act_journal jou,
act_etat_journal eta,
acj_sub_set_cat sca,
act_document doc,
acs_period per,
acs_financial_year fye,
act_financial_imputation imp
WHERE
imp.acs_period_id = per.acs_period_id
AND per.acs_financial_year_id = fye.acs_financial_year_id
AND imp.act_document_id = doc.act_document_id
AND doc.act_journal_id = jou.act_journal_id
AND eta.act_journal_id = jou.act_journal_id
AND eta.c_sub_set = 'ACC'
AND sca.acj_catalogue_document_id = doc.acj_catalogue_document_id
AND sca.c_sub_set = 'ACC'
AND (INSTR(','||PROCPARAM_3||',', TO_CHAR(','||IMP.IMF_ACS_DIVISION_ACCOUNT_ID||',')) > 0 OR PROCPARAM_3 is null)
AND ((PARAMETER_12 = '1'AND imp.imf_transaction_date <= TO_DATE(PARAMETER_1,'yyyyMMdd'))
    OR (PARAMETER_12 = '0' AND imp.imf_transaction_date >= TO_DATE(PARAMETER_0,'yyyyMMdd') AND imp.imf_transaction_date <= TO_DATE(PARAMETER_1,'yyyyMMdd')))
AND ((PARAMETER_2 = '1' AND  eta.C_ETAT_JOURNAL ='BRO')
    OR (PARAMETER_3 = '1' AND  eta.C_ETAT_JOURNAL ='PROV')
    OR (PARAMETER_4 = '1' AND  eta.C_ETAT_JOURNAL ='DEF'))
AND ((PARAMETER_5 ='1' AND sca.C_TYPE_CUMUL = 'EXT')
    OR (PARAMETER_6 ='1' AND  sca.C_TYPE_CUMUL ='INT')
    OR (PARAMETER_7 ='1' AND sca.C_TYPE_CUMUL ='PRE')
    OR (PARAMETER_8='1' AND sca.C_TYPE_CUMUL ='ENG'))
AND ((imp.acs_tax_code_id IS NULL) AND PARAMETER_13 = '1'
    OR PARAMETER_13 = '0' )
AND IMP.ACS_FINANCIAL_ACCOUNT_ID = PARAMETER_14
AND FYE.FYE_NO_EXERCICE = PROCPARAM_0
UNION ALL
SELECT
 'REPORT' info,
 fye.fye_start_date imf_transaction_date,
 tot.tot_debit_lc imf_amount_lc_d,
 tot.tot_credit_lc imf_amount_lc_c,
 tot.tot_debit_fc imf_amount_fc_d,
 tot.tot_credit_fc imf_amount_fc_c,
 tot.acs_financial_currency_id acs_acs_financial_currency_id,
 acs_function.getcurrencyname(tot.acs_financial_currency_id) currency_mb,
 tot.acs_acs_financial_currency_id acs_financial_currency_id,
 acs_function.getcurrencyname (tot.acs_acs_financial_currency_id) currency_me,
 tot.acs_financial_account_id acs_financial_account_id,
 tot.acs_division_account_id acs_division_account_id,
 0 acs_tax_code_id,
 fye.fye_no_exercice fye_no_exercice,
 'PROV' c_etat_journal,
 tot.c_type_cumul c_type_cumul
FROM
acs_period per,
acs_financial_year fye,
act_total_by_period tot
WHERE
tot.acs_period_id = per.acs_period_id
AND per.acs_financial_year_id = fye.acs_financial_year_id
AND acs_function.getstatepreviousfinancialyear(fye.acs_financial_year_id) = 'ACT'
AND tot.acs_auxiliary_account_id IS NULL
AND ((tot.acs_division_account_id IS NOT NULL)
    OR (tot.acs_division_account_id IS NULL
    AND acr_functions.existdivision = 0 ))
AND per.c_type_period = '1'
AND ((TOT.ACS_DIVISION_ACCOUNT_ID is not null) or (TOT.ACS_DIVISION_ACCOUNT_ID is null and ACR_FUNCTIONS.ExistDivision = 0)) AND
    (INSTR(','||PROCPARAM_3||',', TO_CHAR(','||TOT.ACS_DIVISION_ACCOUNT_ID||',')) > 0 OR PROCPARAM_3 is null)
AND PARAMETER_3 ='1'
AND (  (PARAMETER_12 = '1'AND fye.fye_start_date <= TO_DATE(PARAMETER_1,'yyyyMMdd'))
    OR (PARAMETER_12 = '0' AND fye.fye_start_date >= TO_DATE(PARAMETER_0,'yyyyMMdd') AND fye.fye_start_date <= TO_DATE(PARAMETER_1,'yyyyMMdd')))
AND (  (PARAMETER_5 ='1' AND TOT.C_TYPE_CUMUL = 'EXT')
    OR (PARAMETER_6 ='1' AND  TOT.C_TYPE_CUMUL ='INT')
    OR (PARAMETER_7 ='1' AND TOT.C_TYPE_CUMUL ='PRE')
    OR (PARAMETER_8='1' AND TOT.C_TYPE_CUMUL ='ENG'))
AND PARAMETER_13 = '0'
AND TOT.ACS_FINANCIAL_ACCOUNT_ID = PARAMETER_14
AND FYE.FYE_NO_EXERCICE = PROCPARAM_0
 ;
end RPT_ACT_ACC_IMP_ME_SUB_1;
