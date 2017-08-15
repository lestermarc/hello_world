--------------------------------------------------------
--  DDL for Procedure RPT_GCO_PRODUCT_AUX_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_PRODUCT_AUX_SUB" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       NUMBER
)
IS
/**Description - used for report GCO_PRODUCT_FORM_BATCH

* @author AWU 13 OCT 2009
* @lastUpdate AWU 21 FEB 2009
* @public
* @PARAM PARAMETER_0 gco_good_id
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT goo.goo_major_reference, goo.goo_secondary_reference,
             goo.goo_obsolete, pdg.prg_name, pdg.prg_description,
             per.per_name, v_goo.gco_good_id,
             v_goo.gco_multimedia_element_id,
             v_goo.mme_multimedia_designation, v_goo.mme_free_description,
             v_goo.gco_substitution_list_id, v_goo.sul_subst_design_short,
             v_goo.sul_comment, v_goo.sul_from_date, v_goo.sul_until_date,
             v_goo.dic_accountable_group_id,
             v_goo.dic_accountable_group_wording, v_goo.dic_good_line_id,
             v_goo.dic_good_line_wording, v_goo.dic_good_family_id,
             v_goo.dic_good_family_wording, v_goo.dic_good_model_id,
             v_goo.dic_good_model_wording, v_goo.dic_good_group_id,
             v_goo.dic_good_group_wording, v_goo.gco_product_group_id,
             v_goo.dic_ptc_good_group_id, v_goo.dic_pur_tariff_struct_id,
             v_goo.dic_sale_tariff_struct_id, v_goo.dic_commissioning_id,
             v_goo.dic_tariff_set_purchase_id, v_goo.dic_tariff_set_sale_id,
             v_pdt.pdt_end_life, v_pdt.dic_unit_of_measure_id,
             v_pdt.dic_unit_of_measure_wording,
             v_pdt.pdt_conversion_factor_1, v_pdt.dic_unit_of_measure1_id,
             v_pdt.dic_unit_of_measure1_wording,
             v_pdt.pdt_conversion_factor_2, v_pdt.dic_unit_of_measure2_id,
             v_pdt.dic_unit_of_measure2_wording,
             v_pdt.pdt_conversion_factor_3, v_pdt.gco_gco_service_id,
             v_pdt.gco_service_major_reference,
             v_pdt.gco_service_sec_reference, v_pdt.pdt_mark_nomenclature,
             v_pdt.pdt_mark_used, v_pdt.pdt_stock_alloc_batch,
             v_pdt.pdt_scale_link, v_pdt.c_supply_type,
             v_pdt.c_product_delivery_typ, v_pdt.dic_del_typ_explain_id,
             v_pdt.pac_supplier_partner_id,
             v_pdt.gco_dangerous_transp_adr_id, v_pdt.gtd_reference_adr,
             v_pdt.gco_dangerous_transp_iata_id, v_pdt.gtd_reference_iata,
             v_pdt.gco_dangerous_transp_imdg_id, v_pdt.gtd_reference_imdg
        FROM v_gco_good_list v_goo,
             v_gco_product_list v_pdt,
             gco_good goo,
             gco_product_group pdg,
             pac_person per
       WHERE v_goo.gco_good_id = v_pdt.gco_good_id(+)
         AND v_goo.sul_replacement_good_id = goo.gco_good_id(+)
         AND v_goo.gco_product_group_id = pdg.gco_product_group_id (+)
         AND v_pdt.pac_supplier_partner_id = per.pac_person_id(+)
         AND v_pdt.pc_lang_id = vpc_lang_id
         AND v_goo.gco_good_id = parameter_0;
END rpt_gco_product_aux_sub;
