--------------------------------------------------------
--  DDL for Procedure RPT_GCO_PRODUCT_FORM_PUR_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_PRODUCT_FORM_PUR_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       NUMBER
)
IS
/**Description - used for report GCO_PRODUCT_FORM_BATCH

* @author AWU 14 JUL 2009
* @lastUpdate
* @public
* @PARAM  parameter_0 GCO_GOOD_ID
*/
BEGIN
   OPEN arefcursor FOR
      SELECT cdp.gco_good_id, per.per_name,
                pad.add_zipcode
             || ' '
             || pad.add_city
             || ' '
             || ctr.cntname per_address,
             cdp.cda_complementary_reference, cdp.cpu_supply_delay,
             cdp.cpu_economical_quantity
        FROM gco_compl_data_purchase cdp,
             pac_person per,
             pac_address pad,
             pcs.pc_cntry ctr
       WHERE cdp.pac_supplier_partner_id = per.pac_person_id(+)
         AND per.pac_person_id = pad.pac_person_id(+)
         AND (pad.add_principal = 1 OR pad.add_principal IS NULL)
         AND pad.pc_cntry_id = ctr.pc_cntry_id(+)
         AND cdp.gco_good_id = parameter_0;
END rpt_gco_product_form_pur_sub;
