--------------------------------------------------------
--  DDL for Procedure RPT_GCO_PRODUCT_FORM_EXT_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_PRODUCT_FORM_EXT_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       NUMBER
)
IS
/**Description - used for report GCO_PRODUCT_FORM_BATCH

* @author AWU 9 FEB 2010
* @lastUpdate
* @public
* @PARAM  parameter_0 GCO_GOOD_ID
*/
BEGIN
   OPEN arefcursor FOR
      SELECT ext.gco_good_id, rcy.rcy_key, rcy.rcy_descr,
             ext.cea_new_items_warranty, ext.c_asa_new_guaranty_unit,
             ext.cea_old_items_warranty, ext.c_asa_old_guaranty_unit
        FROM gco_compl_data_external_asa ext, doc_record_category rcy
       WHERE ext.doc_record_category_id = rcy.doc_record_category_id(+)
         AND ext.gco_good_id = parameter_0;
END rpt_gco_product_form_ext_sub;
