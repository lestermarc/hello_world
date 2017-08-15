--------------------------------------------------------
--  DDL for Procedure RPT_GCO_PRODUCT_FORM_CTR_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_PRODUCT_FORM_CTR_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       NUMBER
)
IS
/**Description - used for report GCO_PRODUCT_FORM_BATCH

* @author AWU 10 FEB 2009
* @lastUpdate
* @public
* @PARAM  parameter_0 GCO_GOOD_ID
*/
BEGIN
   OPEN arefcursor FOR
      SELECT csu.gco_good_id, per.per_name, csu.csu_default_subcontracter,
             csu.dic_unit_of_measure_id, csu.csu_economical_quantity,
             csu.csu_subcontracting_delay
        FROM gco_compl_data_subcontract csu, pac_person per
       WHERE csu.pac_supplier_partner_id = per.pac_person_id(+)
         AND csu.gco_good_id = parameter_0;
END rpt_gco_product_form_ctr_sub;
