--------------------------------------------------------
--  DDL for Procedure RPT_GCO_PRODUCT_FORM_DIS_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_PRODUCT_FORM_DIS_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       NUMBER
)
IS
/**Description - used for report GCO_PRODUCT_FORM_BATCH

* @author AWU 12 JAN 2009
* @lastUpdate
* @public
* @PARAM  parameter_0 GCO_GOOD_ID
*/
BEGIN
   OPEN arefcursor FOR
      SELECT cdi.gco_good_id, diu.diu_name, diu.diu_description,
             cdi.dic_unit_of_measure_id, cdi.cdi_stock_min,
             cdi.cdi_economical_quantity
        FROM gco_compl_data_distrib cdi, stm_distribution_unit diu
       WHERE cdi.stm_distribution_unit_id = diu.stm_distribution_unit_id(+)
         AND cdi.gco_good_id = parameter_0;
END rpt_gco_product_form_dis_sub;
