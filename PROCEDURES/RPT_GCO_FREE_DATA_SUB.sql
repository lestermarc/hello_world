--------------------------------------------------------
--  DDL for Procedure RPT_GCO_FREE_DATA_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_FREE_DATA_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       NUMBER
)
IS
/**Description - used for report GCO_PRODUCT_FORM_BATCH, GCO_SERVICE_FORM_BATCH

* @author AWU 13 OCT 2009
* @lastUpdate AWU 7 MAY 2009
* @public
* @PARAM PARAMETER_0 gco_good_id
*/
BEGIN
   OPEN arefcursor FOR
      SELECT dta.gco_free_data_id, dta.dic_free_table_1_id,
             dta.dic_free_table_2_id, dta.dic_free_table_3_id,
             dta.dic_free_table_4_id, dta.dic_free_table_5_id,
             dta.gco_good_id, dta.data_alpha_court_1, dta.data_alpha_court_2,
             dta.data_alpha_court_3, dta.data_alpha_court_4,
             dta.data_alpha_court_5, dta.data_alpha_long_1,
             dta.data_alpha_long_2, dta.data_alpha_long_3,
             dta.data_alpha_long_4, dta.data_alpha_long_5,
             dta.data_integer_1, dta.data_integer_2, dta.data_integer_3,
             dta.data_integer_4, dta.data_integer_5, dta.data_boolean_1,
             dta.data_boolean_2, dta.data_boolean_3, dta.data_boolean_4,
             dta.data_boolean_5, dta.data_dec_1, dta.data_dec_2,
             dta.data_dec_3, dta.data_dec_4, dta.data_dec_5
        FROM gco_free_data dta,
             dic_free_table_1 ftb1,
             dic_free_table_2 ftb2,
             dic_free_table_3 ftb3,
             dic_free_table_4 ftb4,
             dic_free_table_5 ftb5
       WHERE dta.dic_free_table_1_id = ftb1.dic_free_table_1_id(+)
         AND dta.dic_free_table_2_id = ftb2.dic_free_table_2_id(+)
         AND dta.dic_free_table_3_id = ftb3.dic_free_table_3_id(+)
         AND dta.dic_free_table_4_id = ftb4.dic_free_table_4_id(+)
         AND dta.dic_free_table_5_id = ftb5.dic_free_table_5_id(+)
         AND dta.gco_good_id = parameter_0;
END rpt_gco_free_data_sub;
