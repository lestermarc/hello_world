--------------------------------------------------------
--  DDL for Procedure RPT_GCO_GOOD_CATEGORY_LIST
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_GOOD_CATEGORY_LIST" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
IS
/**
 Description - used for the report GCO_GOOD_CATEGORY_LIST

* @author EQI 1 JUN 2008
* @lastupdate 20 FEB 2009
* @public
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT cat.gco_good_category_id, cat.gco_good_category_wording,
             cat.gco_category_code, cat.cat_stk_possession_rate,
             cat.cat_compl_achat, cat.cat_compl_vente, cat.cat_compl_sav,
             cat.cat_compl_stock, cat.cat_compl_inv, cat.cat_compl_fab,
             cat.cat_compl_strait, cat.dic_category_free_1_id,
             cat.dic_category_free_2_id, cat.cat_free_text_1,
             cat.cat_free_text_2, cat.cat_free_text_3, cat.cat_free_text_4,
             cat.cat_free_text_5, cat.cat_free_number_1,
             cat.cat_free_number_2, cat.cat_free_number_3,
             cat.cat_free_number_4, cat.cat_free_number_5, cat.c_ean_type,
             cat.dic_good_ean_gen_id, cat.c_ean_type_purchase,
             cat.dic_good_ean_gen_pur_id, cat.c_ean_type_sale,
             cat.dic_good_ean_gen_sale_id, cat.c_ean_type_asa,
             cat.dic_good_ean_gen_asa_id, cat.c_ean_type_stock,
             cat.dic_good_ean_gen_stock_id, cat.c_ean_type_inv,
             cat.dic_good_ean_gen_inv_id, cat.c_ean_type_fal,
             cat.dic_good_ean_gen_fal_id, cat.c_ean_type_subcontract,
             cat.dic_good_ean_gen_sco_id, cat.dic_tabsheet_attribute_1_id,
             cat.dic_tabsheet_attribute_2_id,
             cat.dic_tabsheet_attribute_3_id,
             cat.dic_tabsheet_attribute_4_id,
             cat.dic_tabsheet_attribute_5_id,
             cat.dic_tabsheet_attribute_6_id,
             cat.dic_tabsheet_attribute_7_id,
             cat.dic_tabsheet_attribute_8_id,
             cat.dic_tabsheet_attribute_9_id,
             cat.dic_tabsheet_attribute_10_id,
             cat.dic_tabsheet_attribute_11_id,
             cat.dic_tabsheet_attribute_12_id,
             cat.dic_tabsheet_attribute_13_id,
             cat.dic_tabsheet_attribute_14_id,
             cat.dic_tabsheet_attribute_15_id,
             cat.dic_tabsheet_attribute_16_id,
             cat.dic_tabsheet_attribute_17_id,
             cat.dic_tabsheet_attribute_18_id,
             cat.dic_tabsheet_attribute_19_id,
             cat.dic_tabsheet_attribute_20_id, cat.cat_compl_attribute,
             cat.c_replication_type, num.gcn_description,
             tem.rte_description, tem.rte_designation, des.gcd_wording
        FROM gco_good_category cat,
             gco_reference_template tem,
             gco_good_numbering num,
             gco_good_category_descr des
       WHERE cat.gco_good_numbering_id = num.gco_good_numbering_id(+)
         AND cat.gco_reference_template_id = tem.gco_reference_template_id
         AND cat.gco_good_category_id = des.gco_good_category_id
         AND des.pc_lang_id = vpc_lang_id;
END rpt_gco_good_category_list;
