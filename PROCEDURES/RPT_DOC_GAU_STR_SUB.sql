--------------------------------------------------------
--  DDL for Procedure RPT_DOC_GAU_STR_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_GAU_STR_SUB" (
   arefcursor        IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid    IN       pcs.pc_lang.lanid%TYPE,
   pm_doc_gauge_id   IN       VARCHAR2
)
IS
/**
*    STORED PROCEDURE USED FOR THE REPORT GAU_FORM_STRUCTURED

* @CREATED IN PROCONCEPT CHINA
* @AUTHOR AWU 1 JUN 2009
* @LASTUPDATE 20 FEB 2009
* @VERSION
* @PUBLIC
* @PARAM pm_doc_gauge_id     DOC_GAUGE_ID
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT '1' group_string, --used for display of header in subreport
             v_afa.acc_number, v_afa.des_description_summary,
             v_dg.c_direction_number, v_dg.gau_use_managed_data,
             v_dg.dic_type_doc_custom_id, v_dgs.c_gauge_title,
             v_dgs.gcdtext1, v_dgs.dic_type_movement_id,
             v_dgs.dic_description, v_dgs.c_round_type,
             v_dgs.c_round_type_wording, v_dgs.gas_round_amount,
             v_dgs.gas_position__numbering, v_dgs.gas_modify_numbering,
             v_dgs.gas_increment, v_dgs.gas_first_no,
             v_dgs.gas_increment_nbr, v_dgs.gas_balance_status,
             v_dgs.gas_pcent, v_dgs.gas_financial_charge,
             v_dgs.gas_total_doc, v_dgs.acs_fin_acc_s_payment_id,
             v_dgs.cat_description, v_dgs.gas_financial_ref,
             v_dgs.acs_financial_account_id, v_dgs.gas_good_third,
             v_dgs.gas_weight, v_dgs.gas_correlation, v_dgs.gas_substitute,
             v_dgs.gas_characterization, v_dgs.gas_pay_condition,
             v_dgs.gas_vat, v_dgs.gas_taxe, v_dgs.c_type_edi,
             v_dgs.c_controle_date_docum,
             v_dgs.c_controle_date_docum_wording, v_dgs.gas_anal_charge,
             v_dgs.gas_sending_condition, v_dgs.gas_change_acc_s_payment,
             v_dgs.gas_visible_count, v_dgs.c_credit_limit,
             v_dgs.gas_commission_management, v_dgs.gas_calculate_commission,
             v_dgs.gas_cash_register, v_dgs.gas_form_cash_register,
             v_dgs.gas_vat_det_account_visible, v_dgs.gas_init_free_data,
             v_dgs.gas_auto_attribution, v_dgs.pac_payment_condition_wording,
             v_dgs.c_bvr_generation_method, v_dgs.c_start_control_date,
             v_dgs.c_start_control_date_wording, v_dgs.c_doc_pre_entry,
             v_dgs.c_doc_pre_entry_third, v_dgs.gas_calcul_credit_limit,
             v_dgs.gas_credit_limit_status_01,
             v_dgs.gas_credit_limit_status_02,
             v_dgs.gas_credit_limit_status_03,
             v_dgs.gas_credit_limit_status_04, v_dgs.cat_pmt_description,
             v_dgs.gas_unit_price_decimal, v_dgs.gas_pos_qty_decimal,
             v_dgs.gas_all_characterization, v_dgs.gas_cpn_account_modify,
             v_dgs.gas_auto_mrp, v_dgs.c_doc_creditlimit_mode,
             v_dgs.gas_weighing_mgm, v_dgs.gas_weight_mat,
             v_dgs.gas_use_partner_date, v_dgs.gas_cost, v_dgs.gas_discount,
             v_dgs.gas_charge, v_dgs.gas_cash_multiple_transaction,
             v_dgs.c_pic_forecast_control, v_dgs.gas_previous_periods_nb,
             v_dgs.gas_following_periods_nb, v_dgs.gas_multisourcing_mgm
        FROM v_doc_gauge v_dg,
             v_doc_gauge_structured v_dgs,
             v_acs_financial_account v_afa,
             v_acs_division_account v_ada,
             acs_description ade
       WHERE v_dg.doc_gauge_id = v_dgs.doc_gauge_id
         AND v_dgs.pc_lang_id = v_afa.pc_lang_id(+)
         AND v_dgs.acs_financial_account_id = v_afa.acs_financial_account_id(+)
         AND v_dgs.pc_lang_id = v_ada.pc_lang_id(+)
         AND v_dgs.acs_division_account_id = v_ada.acs_division_account_id(+)
         AND v_dgs.pc_lang_id = ade.pc_lang_id(+)
         AND v_dgs.acs_payment_method_id = ade.acs_payment_method_id(+)
         AND v_dgs.pc_lang_id = vpc_lang_id
         AND v_dg.pc_lang_id = vpc_lang_id
         AND v_dg.doc_gauge_id = TO_NUMBER (pm_doc_gauge_id);
END rpt_doc_gau_str_sub;
