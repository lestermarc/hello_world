--------------------------------------------------------
--  DDL for Procedure RPT_ACT_DOC_MGM_IMP_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_DOC_MGM_IMP_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       NUMBER
)
IS
/**
*Description - used for report ACT_DOCUMENT_EXAMPLE
* @author mzhu
* @lastupdate 11 feb 2009
* @Published VHA 20 sept 2011
* @PUBLIC
* @PARAM PARAMETER_0: ACT_DOCUMENT_ID
*/
BEGIN
   OPEN arefcursor FOR
      SELECT imm.act_mgm_imputation_id, imm.act_document_id,
             imm.acs_cpn_account_id, imm.acs_cda_account_id,
             imm.acs_pf_account_id, imm.imm_description, imm.imm_amount_lc_d,
             imm.imm_amount_lc_c, imm.imm_exchange_rate, imm.imm_amount_fc_d,
             imm.imm_amount_fc_c, imm.imm_value_date,
             imm.imm_transaction_date, imm.acs_qty_unit_id,
             imm.imm_quantity_d, imm.imm_quantity_c, cur.pc_curr_id,
             cur.currency, cur_b.pc_curr_id pc_curr_id_b,
             cur_b.currency currency_b,
             acs_function.getaccountnumber (imm.acs_cda_account_id) cpte_cda,
             acs_function.getaccountnumber (imm.acs_cpn_account_id) cpte_cpn,
             acs_function.getaccountnumber (imm.acs_pf_account_id) cpte_pf,
             acs_function.getaccountnumber (imm.acs_qty_unit_id) cpte_qty
        FROM acs_financial_currency afc,
             acs_financial_currency afc_b,
             pcs.pc_curr cur,
             pcs.pc_curr cur_b,
             act_mgm_imputation imm
       WHERE imm.acs_financial_currency_id = afc.acs_financial_currency_id
         AND afc.pc_curr_id = cur.pc_curr_id
         AND imm.acs_acs_financial_currency_id =
                                               afc_b.acs_financial_currency_id
         AND afc_b.pc_curr_id = cur_b.pc_curr_id
         AND imm.act_document_id = parameter_0;
END rpt_act_doc_mgm_imp_sub;
