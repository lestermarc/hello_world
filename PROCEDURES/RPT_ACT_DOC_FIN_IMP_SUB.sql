--------------------------------------------------------
--  DDL for Procedure RPT_ACT_DOC_FIN_IMP_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_DOC_FIN_IMP_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       NUMBER
)
IS
/**
*Description - used for report ACT_DOCUMENT_EXAMPLE
* @author mzhu
* @lastupdate 11 Feb 2009 - Mai 2009
* @Published VHA 20 sept 2011
* @public
* @PARAM PARAMETER_0: ACT_DOCUMENT_ID
*/
BEGIN
   OPEN arefcursor FOR
      SELECT par.par_document, par.par_blocked_document,
             par.doc_date_delivery, cur.currency, cur_b.currency currency_b,
             imf.act_document_id, imf.act_financial_imputation_id,
             imf.acs_financial_account_id, imf.imf_primary,
             imf.imf_description, imf.imf_amount_lc_d, imf.imf_amount_lc_c,
             imf.imf_exchange_rate, imf.imf_amount_fc_d, imf.imf_amount_fc_c,
             imf.imf_value_date, imf.acs_tax_code_id,
             imf.imf_transaction_date, imf.imf_acs_aux_account_cust_id,
             imf.imf_acs_aux_account_supp_id, imf.acs_auxiliary_account_id,
             imf.act_part_imputation_id, imf.pac_person_id imp_pac_person,
             NVL (imf.imf_pac_custom_partner_id,
               imf.imf_pac_supplier_partner_id
              ) pac_person_id,
             imf.imf_acs_division_account_id,
             acs_function.getaccountnumber
                                     (imf.acs_auxiliary_account_id)
                                                                  aux_number,
             acs_function.getaccountnumber
                             (imf.imf_acs_aux_account_cust_id)
                                                             aux_number_cust,
             acs_function.getaccountnumber
                             (imf.imf_acs_aux_account_supp_id)
                                                             aux_number_supp,
             acs_function.getaccountnumber
                               (imf.imf_acs_division_account_id)
                                                               cpte_division,
             acs_function.getaccountnumber
                                 (imf.acs_financial_account_id)
                                                              cpte_financier,
             acs_function.getaccountnumber (imf.acs_tax_code_id) cpte_tva
        FROM acs_financial_currency afc,
             acs_financial_currency afc_b,
             pcs.pc_curr cur,
             pcs.pc_curr cur_b,
             act_part_imputation par,
             act_financial_imputation imf
       WHERE imf.act_part_imputation_id = par.act_part_imputation_id(+)
         AND imf.acs_financial_currency_id = afc.acs_financial_currency_id
         AND afc.pc_curr_id = cur.pc_curr_id
         AND imf.acs_acs_financial_currency_id =
                                               afc_b.acs_financial_currency_id
         AND afc_b.pc_curr_id = cur_b.pc_curr_id
         AND imf.act_document_id = parameter_0;
END rpt_act_doc_fin_imp_sub;
