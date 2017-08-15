--------------------------------------------------------
--  DDL for Procedure RPT_GCO_SERVICE_FORM_BATCH
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_SERVICE_FORM_BATCH" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       NUMBER
)
IS
/**Description - used for report GCO_PRODUCT_FORM_BATCH

* @author AWU 15 OCT 2009
* @lastUpdate AWU 6 MAY 2009 - PYB Avril 09
* @public
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT ser.gco_good_id, goo.goo_major_reference,
             goo.goo_secondary_reference, goo.goo_ean_code,
             goo.goo_number_of_decimal, goo.a_datecre, goo.a_datemod,
             gco_functions.getdescription
                                      (goo.gco_good_id,
                                       procuser_lanid,
                                       1,
                                       '01'
                                      ) des_short_description,
             gco_functions.getdescription
                                       (goo.gco_good_id,
                                        procuser_lanid,
                                        2,
                                        '01'
                                       ) des_long_description,
             gco_functions.getdescription
                                       (goo.gco_good_id,
                                        procuser_lanid,
                                        3,
                                        '01'
                                       ) des_free_description,
             ume.dic_unit_of_measure_id, goo.c_management_mode,
             (SELECT cds.gcd_wording
                FROM gco_good_category cat,
                     gco_good_category_descr cds
               WHERE goo.gco_good_category_id = cat.gco_good_category_id
                 AND cat.gco_good_category_id = cds.gco_good_category_id
                 AND cds.pc_lang_id = vpc_lang_id) gcd_wording
        FROM gco_service ser, gco_good goo, dic_unit_of_measure ume
       WHERE ser.gco_good_id = parameter_0
         AND ser.gco_good_id = goo.gco_good_id
         AND goo.dic_unit_of_measure_id = ume.dic_unit_of_measure_id(+);
END rpt_gco_service_form_batch;
