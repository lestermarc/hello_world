--------------------------------------------------------
--  DDL for Procedure RPT_ACT_REMINDER_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_REMINDER_SUB" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_1      IN       VARCHAR2,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
/**
*Description - used for report ACT_REMINDER, ACT_JOB

* @author jliu 18 Nov 2009
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
      SELECT atd.doc_number, EXP.exp_adapted, EXP.exp_amount_lc,
             EXP.exp_amount_fc, imp.imf_primary, imp.imf_transaction_date,
             rmd.acs_financial_currency_id,
             rmd.acs_acs_financial_currency_id, rmd.rem_payable_amount_lc,
             rmd.rem_payable_amount_fc, rmd.rem_number,
             cus.pac_person_id cus_person_id, cus.per_name cus_name,
             sup.pac_person_id sup_person_id, sup.per_name sup_name
        FROM act_reminder rmd,
             act_expiry EXP,
             act_part_imputation par,
             act_document atd,
             pac_person cus,
             pac_person sup,
             act_financial_imputation imp
       WHERE rmd.act_expiry_id = EXP.act_expiry_id
         AND EXP.act_part_imputation_id = par.act_part_imputation_id
         AND par.act_document_id = atd.act_document_id
         AND atd.act_document_id = imp.act_document_id
         AND par.pac_custom_partner_id = cus.pac_person_id(+)
         AND par.pac_supplier_partner_id = sup.pac_person_id(+)
         AND imp.imf_primary = 1
         AND rmd.act_document_id = TO_NUMBER (parameter_1);
END rpt_act_reminder_sub;
