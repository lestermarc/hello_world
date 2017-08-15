--------------------------------------------------------
--  DDL for Procedure RPT_GCO_PRODUCT_FORM_BATCH
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_PRODUCT_FORM_BATCH" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       NUMBER
)
IS
/**Description - used for report GCO_PRODUCT_FORM_BATCH

* @author AWU 13 OCT 2009
* @lastUpdate AWU 10 FEB 2010
* @public
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT goo.gco_good_id gc_gco_good_id, goo.goo_major_reference,
             goo.goo_secondary_reference, goo.goo_number_of_decimal,
             goo.a_datecre, goo.a_datemod, vpc_lang_id pc_lang_id,
             gco_functions.getdescription2
                                      (goo.gco_good_id,
                                       vpc_lang_id,
                                       1,
                                       '01'
                                      ) des_short_description,
             gco_functions.getdescription2
                                       (goo.gco_good_id,
                                        vpc_lang_id,
                                        2,
                                        '01'
                                       ) des_long_description,
             gco_functions.getdescription2
                                       (goo.gco_good_id,
                                        vpc_lang_id,
                                        3,
                                        '01'
                                       ) des_free_description,
             goo.dic_unit_of_measure_id, goo.c_management_mode,
             goo.goo_precious_mat, pdt.gco_good_id, pdt.stm_stock_id,
             pdt.pdt_full_tracability, sto.sto_description,
             pdt.stm_location_id, loc.loc_description, pdt.c_supply_mode,
             pdt.pdt_stock_management, pdt.pdt_stock_obtain_management,
             pdt.pdt_calc_requirement_mngment, pdt.pdt_continuous_inventar,
             pdt.pdt_pic, pdt.pdt_block_equi, pdt.pdt_guaranty_use,
             pdt.pdt_multi_sourcing,
             (SELECT gde.gcd_wording
                FROM gco_good_category_descr gde
               WHERE gde.gco_good_category_id =
                                         goo.gco_good_category_id
                 AND gde.pc_lang_id = vpc_lang_id) gcd_wording
        FROM gco_good goo, gco_product pdt, stm_stock sto, stm_location loc
       WHERE goo.gco_good_id = pdt.gco_good_id
         AND pdt.stm_stock_id = sto.stm_stock_id(+)
         AND pdt.stm_location_id = loc.stm_location_id(+)
         AND goo.gco_good_id = parameter_0;
END rpt_gco_product_form_batch;
