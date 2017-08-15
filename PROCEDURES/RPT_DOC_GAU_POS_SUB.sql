--------------------------------------------------------
--  DDL for Procedure RPT_DOC_GAU_POS_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_GAU_POS_SUB" (
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
             ddgp.gap_designation, dgp.c_gauge_type_pos,
             dgp.c_gauge_init_price_pos, dgp.gap_value,
             dgp.gap_bloc_access_value, dgp.gap_delay,
             dgp.c_gauge_show_delay, dgp.c_round_application,
             dgp.gap_pos_delay, dgp.gap_pcent, dgp.gap_txt, dgp.gap_default,
             dgp.gap_stock_access, dgp.gap_mvt_utility, dgp.gap_trans_access,
             dgp.gap_init_stock_place, dgp.gap_direct_remis,
             dgp.gap_designation, dgp.gap_delay_copy_prev_pos,
             dgp.gap_value_quantity, dgp.gap_include_tax_tariff,
             dgp.dic_tariff_id, dgp.gap_forced_tariff, dgp.gap_stock_mvt,
             dgp.dic_delay_update_type_id, dgp.stm_stock_id,
             dgp.stm_location_id, dgp.doc_doc_gauge_position_id, dgp.gap_mrp,
             dgp.gap_sqm_show_dflt, dgp.c_sqm_eval_type,
             dgp.gap_transfert_proprietor, dgp.gap_asa_task_imput,
             dgp.dic_type_movement_id, ggd.goo_major_reference,
             ggd.goo_secondary_reference, pap.aph_code, slo.loc_description,
             smk.c_movement_code, smk.mok_abbreviation, sst.sto_description,
             v_pde.gcdtext1, v_pde1.gcdtext1,
             pcs.pc_functions.getappltxtlabel (dgp.pc_appltxt_id,
                                               vpc_lang_id
                                              ) appltxt
        FROM doc_gauge_position ddgp,
             doc_gauge_position dgp,
             gco_good ggd,
             pcs.pc_appltxt pap,
             stm_location slo,
             stm_movement_kind smk,
             stm_stock sst,
             pcs.v_pc_descodes v_pde,
             pcs.v_pc_descodes v_pde1
       WHERE dgp.c_gauge_type_pos = v_pde.gclcode
         AND dgp.c_gauge_init_price_pos = v_pde1.gclcode
         AND dgp.stm_movement_kind_id = smk.stm_movement_kind_id(+)
         AND dgp.gco_good_id = ggd.gco_good_id(+)
         AND dgp.pc_appltxt_id = pap.pc_appltxt_id(+)
         AND dgp.stm_stock_id = sst.stm_stock_id(+)
         AND dgp.stm_location_id = slo.stm_location_id(+)
         AND dgp.doc_doc_gauge_position_id = ddgp.doc_gauge_position_id(+)
         AND v_pde.pc_lang_id = vpc_lang_id
         AND v_pde1.pc_lang_id = vpc_lang_id
         AND v_pde.gcgname = 'C_GAUGE_TYPE_POS'
         AND v_pde1.gcgname = 'C_GAUGE_INIT_PRICE_POS'
         AND dgp.doc_gauge_id = TO_NUMBER (pm_doc_gauge_id);
END rpt_doc_gau_pos_sub;
