--------------------------------------------------------
--  DDL for Procedure RPT_GCO_PRODUCT_FORM_SAL_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_PRODUCT_FORM_SAL_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       NUMBER
)
IS
/**Description - used for report GCO_PRODUCT_FORM_BATCH

* @author AWU 7 Jan 2009
* @lastUpdate
* @public
* @PARAM  parameter_0 GCO_GOOD_ID
*/
BEGIN
   OPEN arefcursor FOR
      SELECT csa.gco_good_id, per.per_name, csa.cda_complementary_reference,
             csa.csa_th_supply_delay, csa.csa_dispatching_delay,
             csa.csa_delivery_delay
        FROM gco_compl_data_sale csa, pac_person per
       WHERE csa.pac_custom_partner_id = per.pac_person_id
         AND csa.gco_good_id = parameter_0;
END rpt_gco_product_form_sal_sub;
