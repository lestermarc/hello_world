--------------------------------------------------------
--  DDL for Procedure RPT_ACT_DOC_MGM_DIS_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_DOC_MGM_DIS_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       NUMBER
)
IS
/**
*Description - used for the report ACT_DOCUMENT_EXAMPLE

* @author mzhu
* @lastupdate 11 Feb 2009
* @Published VHA 20 sept 2011
* @public
* @PARAM PARAMETER_0: ACT_DOCUMENT_ID
*/
BEGIN
   OPEN arefcursor FOR
      SELECT imm.act_document_id, imm.imm_exchange_rate, imm.imm_value_date,
             imm.imm_transaction_date,
             imm.acs_qty_unit_id,
             ACS_FUNCTION.GetAccountNumber(imm.acs_qty_unit_id) acs_qty_unit_num,
             mgm.act_mgm_distribution_id,
             mgm.acs_pj_account_id,
             ACS_FUNCTION.GetAccountNumber(acs_pj_account_id) acs_pj_account_num,
             mgm.mgm_description, mgm.mgm_amount_lc_d, mgm.mgm_amount_fc_d,
             mgm.mgm_amount_lc_c, mgm.mgm_amount_fc_c, mgm.mgm_quantity_d,
             mgm.mgm_quantity_c, cur.pc_curr_id, cur.currency,
             cur_b.pc_curr_id pc_curr_id_b, cur_b.currency currency_b
        FROM acs_financial_currency afc,
             acs_financial_currency afc_b,
             pcs.pc_curr cur,
             pcs.pc_curr cur_b,
             act_mgm_imputation imm,
             act_mgm_distribution mgm,
             acs_account acc_pj,
             acs_account acc_qty
       WHERE imm.acs_financial_currency_id = afc.acs_financial_currency_id
         AND afc.pc_curr_id = cur.pc_curr_id
         AND imm.acs_acs_financial_currency_id =
                                               afc_b.acs_financial_currency_id
         AND afc_b.pc_curr_id = cur_b.pc_curr_id
         AND imm.act_mgm_imputation_id = mgm.act_mgm_imputation_id
         AND mgm.acs_pj_account_id = acc_pj.acs_account_id
         AND imm.acs_qty_unit_id = acc_qty.acs_account_id(+)
         AND imm.act_document_id = parameter_0;
END rpt_act_doc_mgm_dis_sub;
