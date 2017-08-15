--------------------------------------------------------
--  DDL for Procedure RPT_GCO_PRODUCT_FORM_INV_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_PRODUCT_FORM_INV_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       NUMBER
)
IS
/**Description - used for report GCO_PRODUCT_FORM_BATCH

* @author AWU 5 JAN 2010
* @lastUpdate
* @public
* @PARAM  parameter_0 GCO_GOOD_ID
*/
BEGIN
   OPEN arefcursor FOR
      SELECT cin.gco_good_id, sto.sto_description, loc.loc_description,
             qpr.qpr_quality_principle_design, cin.cin_fixed_stock_position,
             cin.cin_turning_inventory, cin.cin_turning_inventory_delay,
             cin.cin_last_inventory_date, cin.cin_next_inventory_date
        FROM gco_compl_data_inventory cin,
             stm_stock sto,
             stm_location loc,
             gco_quality_principle qpr
       WHERE cin.stm_stock_id = sto.stm_stock_id(+)
         AND cin.stm_location_id = loc.stm_location_id(+)
         AND cin.gco_quality_principle_id = qpr.gco_quality_principle_id(+)
         AND cin.gco_good_id = parameter_0;
END rpt_gco_product_form_inv_sub;
