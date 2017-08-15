--------------------------------------------------------
--  DDL for Procedure RPT_ACT_JOURNAL_MGM
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_JOURNAL_MGM" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0      IN       NUMBER,
   parameter_1      IN       NUMBER,
   parameter_2      IN       NUMBER,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
/**
* description used for report act_journal_mgm.rpt

* @author jliu 18 nov 2008
* @lastupdate 12 Feb 2009
* @public
* @PARAM PARAMETER_0    ACS_FINANCIAL_YEAR_ID
* @PARAM PARAMETER_1    journal from (Nr)
* @PARAM PARAMETER_2    journal to(Nr)
*/
IS
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT aux_acc.acc_number aux_acc_number,
             cda_acc.acc_number cda_acc_number,
             cpn_acc.acc_number cpn_acc_number,
             pf_acc.acc_number pf_acc_number,
             qty_acc.acc_number qty_acc_number, cur_mb.currency currency_mb,
             cur_me.currency currency_me, mgm.act_journal_id, mgm.jou_number,
             mgm.jou_description, mgm.pc_user_id, mgm.c_etat_journal,
             mgm.c_sub_set, mgm.acs_financial_year_id, mgm.job_description,
             mgm.act_document_id, mgm.doc_document_date, mgm.doc_number,
             mgm.imm_transaction_date, mgm.act_mgm_imputation_id,
             mgm.imm_value_date, mgm.imm_primary, mgm.imm_description,
             mgm.acs_cpn_account_id, mgm.acs_cda_account_id,
             mgm.acs_pf_account_id, mgm.acs_qty_unit_id,
             mgm.acs_acs_financial_currency_id, mgm.imm_amount_lc_d,
             mgm.imm_amount_lc_c, mgm.acs_financial_currency_id,
             mgm.imm_amount_fc_d, mgm.imm_amount_fc_c, mgm.imm_exchange_rate,
             mgm.imm_quantity_d, mgm.imm_quantity_c,
             mgm.act_mgm_distribution_id, mgm.acs_auxiliary_account_id,
             des.des_description_summary
        FROM v_act_rep_mgm_imputation mgm,
             acs_account aux_acc,
             acs_account cda_acc,
             acs_account cpn_acc,
             acs_account pf_acc,
             acs_account qty_acc,
             acs_description des,
             acs_financial_currency fur_mb,
             acs_financial_currency fur_me,
             pcs.pc_curr cur_mb,
             pcs.pc_curr cur_me
       WHERE mgm.acs_cpn_account_id = cpn_acc.acs_account_id
         AND mgm.acs_cda_account_id = cda_acc.acs_account_id(+)
         AND mgm.acs_pf_account_id = pf_acc.acs_account_id(+)
         AND mgm.acs_qty_unit_id = qty_acc.acs_account_id(+)
         AND mgm.acs_auxiliary_account_id = des.acs_account_id(+)
         AND des.pc_lang_id(+) = vpc_lang_id
         AND mgm.acs_acs_financial_currency_id =
                                              fur_mb.acs_financial_currency_id
         AND fur_mb.pc_curr_id = cur_mb.pc_curr_id
         AND mgm.acs_financial_currency_id = fur_me.acs_financial_currency_id
         AND fur_me.pc_curr_id = cur_me.pc_curr_id
         AND mgm.acs_auxiliary_account_id = aux_acc.acs_account_id(+)
         AND mgm.c_sub_set = 'CPN'
         AND mgm.acs_financial_year_id = parameter_0
         AND mgm.jou_number >= parameter_1
         AND mgm.jou_number <= parameter_2;
END rpt_act_journal_mgm;
