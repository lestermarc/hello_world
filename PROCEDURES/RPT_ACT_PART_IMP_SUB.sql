--------------------------------------------------------
--  DDL for Procedure RPT_ACT_PART_IMP_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_PART_IMP_SUB" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_1      IN       VARCHAR2,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
/**
*Description - used in report act_part_imputation
* @author jliu 18 Nov 2008
* @lastupdate 12 Feb 2009
* @public
* @param PARAMETER_1: ACT_DOCUMENT_ID
*/
IS
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT fmp.imf_amount_lc_d, fmp.imf_amount_lc_c, fmp.imf_amount_fc_d,
             fmp.imf_amount_fc_c, fmp.acs_auxiliary_account_id,
             fmp.acs_financial_currency_id,
             fmp.acs_acs_financial_currency_id, imp.par_document,
             cus.pac_person_id cus_person_id, cus.per_name cus_name,
             cus.per_forename cus_forename, sup.pac_person_id sup_person_id,
             sup.per_name sup_name, sup.per_forename sup_forename,
             cmb.currency currency_mb, cme.currency currency_me
        FROM act_part_imputation imp,
             pac_person cus,
             pac_person sup,
             act_financial_imputation fmp,
             acs_financial_currency fmb,
             acs_financial_currency fme,
             pcs.pc_curr cmb,
             pcs.pc_curr cme
       WHERE imp.act_document_id = TO_NUMBER (parameter_1)
         AND imp.pac_custom_partner_id = cus.pac_person_id(+)
         AND imp.pac_supplier_partner_id = sup.pac_person_id(+)
         AND imp.act_part_imputation_id = fmp.act_part_imputation_id(+)
         AND fmp.acs_acs_financial_currency_id = fmb.acs_financial_currency_id(+)
         AND fmp.acs_financial_currency_id = fme.acs_financial_currency_id(+)
         AND fmb.pc_curr_id = cmb.pc_curr_id(+)
         AND fme.pc_curr_id = cme.pc_curr_id(+)
         AND fmp.acs_auxiliary_account_id IS NOT NULL;
END rpt_act_part_imp_sub;
