--------------------------------------------------------
--  DDL for Procedure RPT_GCO_GOO_CATEGORY_INTER_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_GOO_CATEGORY_INTER_SUB" (
   arefcursor                IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid            IN       pcs.pc_lang.lanid%TYPE,
   pm_gco_good_category_id   IN       VARCHAR2
)
IS
/**
 Description - used for the report GCO_GOOD_CATEGORY_LIST, GCO_GOOD_CATEGORY_BATCH

* @author EQI 1 JUN 2008
* @lastupdate 20 FEB 2009
* @public
* @PARAM PM_GCO_GOOD_CATEGORY_ID  GCO_GOOD_CATEGORY_ID
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT gtl.gco_transfer_list_id, gtl.c_default_repl,
             gtl.c_transfer_type, gtl.xli_table_name, gtl.xli_field_name,
             gtl.xli_substitution, gtl.gco_good_category_id,
             gts.xsu_original, gts.xsu_replacement, gts.xsu_is_default_value
        FROM gco_transfer_subst gts, gco_transfer_list gtl
       WHERE gts.gco_transfer_list_id = gtl.gco_transfer_list_id
         AND gtl.gco_good_category_id = TO_NUMBER (pm_gco_good_category_id);
END rpt_gco_goo_category_inter_sub;
