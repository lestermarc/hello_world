--------------------------------------------------------
--  DDL for Procedure RPT_GCO_GOOD_BY_THIRD
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_GOOD_BY_THIRD" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
IS
/**
 Description - used for the report GCO_GOOD_BY_THIRD

* @author AWU 1 SEP 2008
* @lastupdate 19 Feb 2009
* @public
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT gcp.cda_complementary_reference, gcp.cda_short_description,
             gcp.cda_long_description, gcp.cpu_default_supplier,
             gde.des_short_description, gde.des_long_description,
             goo.goo_major_reference, ppe.per_name
        FROM gco_compl_data_purchase gcp,
             gco_description gde,
             gco_good goo,
             pac_person ppe
       WHERE gcp.pac_supplier_partner_id = ppe.pac_person_id
         AND gcp.gco_good_id = goo.gco_good_id
         AND goo.gco_good_id = gde.gco_good_id
         AND gde.c_description_type = '01'
         AND gde.pc_lang_id = vpc_lang_id;
END rpt_gco_good_by_third;
