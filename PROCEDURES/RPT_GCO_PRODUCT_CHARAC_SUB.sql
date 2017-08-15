--------------------------------------------------------
--  DDL for Procedure RPT_GCO_PRODUCT_CHARAC_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_PRODUCT_CHARAC_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       NUMBER
)
IS
/**Description - used for report GCO_PRODUCT_FORM_BATCH

* @author AWU 13 OCT 2009
* @lastUpdate AWU 21 FEB 2009
* @public
* @PARAM PARAMETER_0 gco_good_id
*/
BEGIN
   OPEN arefcursor FOR
      SELECT caf.caf_numbering_function, che.che_value, che.che_allocation,
             che.che_ean_code, cha.gco_characterization_id,
             cha.c_chronology_type, cha.c_charact_type, cha.c_unit_of_time,
             cha.gco_good_id, cha.cha_characterization_design,
             cha.cha_automatic_incrementation, cha.cha_increment_ste,
             cha.cha_last_used_increment, cha.cha_lapsing_delay,
             cha.cha_minimum_value, cha.cha_maximum_value, cha.cha_comment,
             cha.cha_stock_management, cha.gco_char_autonum_func_id,
             cha.cha_prefixe, cha.cha_suffixe, cha.cha_free_text_1,
             cha.cha_free_text_2, cha.cha_free_text_3, cha.cha_free_text_4,
             cha.cha_free_text_5, cha.cha_lapsing_marge,
             dsl.gco_desc_language_id, dsl.dla_description
        FROM gco_characterization cha,
             gco_characteristic_element che,
             gco_desc_language dsl,
             gco_char_autonum_func caf
       WHERE cha.gco_characterization_id = che.gco_characterization_id(+)
         AND cha.gco_characterization_id = dsl.gco_characterization_id(+)
         AND cha.gco_char_autonum_func_id = caf.gco_char_autonum_func_id(+)
         AND cha.gco_good_id = parameter_0;
END rpt_gco_product_charac_sub;
