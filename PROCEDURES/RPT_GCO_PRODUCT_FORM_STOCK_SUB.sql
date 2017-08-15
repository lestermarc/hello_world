--------------------------------------------------------
--  DDL for Procedure RPT_GCO_PRODUCT_FORM_STOCK_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_PRODUCT_FORM_STOCK_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       NUMBER
)
IS
/**Description - used for report GCO_PRODUCT_FORM_BATCH

* @author AWU 13 JUL 2009
* @lastUpdate
* @public
* @PARAM  parameter_0 GCO_GOOD_ID
*/
BEGIN
   OPEN arefcursor FOR
      SELECT cds.gco_good_id, sto.sto_description, loc.loc_description,
             cds.cst_quantity_min, cds.cst_quantity_max,
             cds.cst_trigger_point
        FROM gco_compl_data_stock cds, stm_stock sto, stm_location loc
       WHERE cds.stm_stock_id = sto.stm_stock_id(+)
         AND cds.stm_location_id = loc.stm_location_id(+)
         AND cds.gco_good_id = parameter_0;
END rpt_gco_product_form_stock_sub;
