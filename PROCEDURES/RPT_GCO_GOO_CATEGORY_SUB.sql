--------------------------------------------------------
--  DDL for Procedure RPT_GCO_GOO_CATEGORY_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_GOO_CATEGORY_SUB" (
   arefcursor                     IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid                 IN       pcs.pc_lang.lanid%TYPE,
   pm_dic_tabsheet_attribute_id   IN       gco_attribute_fields.dic_tabsheet_attribute_id%TYPE
)
IS
/**
 Description - used for the report GCO_GOOD_CATEGORY_LIST, GCO_GOOD_CATEGORY_BATCH

* @author EQI 1 JUN 2008
* @lastupdate 20 FEB 2009
* @public
* @PARAM pm_dic_tabsheet_attribute_id dic_tabsheet_attribute_id
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT dta.dic_tabsheet_attribute_id, dta.dic_description,
             gaf.atf_mandatory, gaf.atf_sequence_number, fdi.fdiheader,
             fld.fldname
        FROM dic_tabsheet_attribute dta,
             gco_attribute_fields gaf,
             pcs.pc_fdico fdi,
             pcs.pc_fldsc fld
       WHERE dta.dic_tabsheet_attribute_id = gaf.dic_tabsheet_attribute_id
         AND gaf.pc_fldsc_id = fld.pc_fldsc_id
         AND fdi.pc_fldsc_id = fld.pc_fldsc_id
         AND fdi.pc_lang_id = vpc_lang_id
         AND dta.dic_tabsheet_attribute_id = pm_dic_tabsheet_attribute_id;
END rpt_gco_goo_category_sub;
