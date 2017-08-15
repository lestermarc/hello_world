--------------------------------------------------------
--  DDL for Procedure RPT_GCO_PSEUDO_FORM_BATCH
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_PSEUDO_FORM_BATCH" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       NUMBER
)
IS
/**Description - used for report GCO_PSEUDO_FORM_BATCH

* @author AWU 13 OCT 2009
* @lastUpdate AWU 6 MAY 2009 - PYB avril 09
* @public
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT pse.gco_good_id, v_ca.goo_major_reference,
             v_ca.goo_secondary_reference, v_ca.goo_ean_code,
             v_ca.goo_number_of_decimal, v_ca.a_datecre, v_ca.a_datemod,
             v_ca.des_short_description, v_ca.des_long_description,
             v_ca.des_free_description, v_ca.dic_unit_of_measure_id,
             v_ca.c_management_mode, des.gcd_wording
        FROM gco_pseudo_good pse,
             v_gco_good_catalogue v_ca,
             gco_good_category_descr des
       WHERE pse.gco_good_id = parameter_0
         AND pse.gco_good_id = v_ca.gco_good_id
         AND v_ca.pc_lang_id = vpc_lang_id
         AND v_ca.gco_good_category_id = des.gco_good_category_id
         AND des.pc_lang_id = vpc_lang_id;
END rpt_gco_pseudo_form_batch;
