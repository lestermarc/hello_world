--------------------------------------------------------
--  DDL for Procedure RPT_GCO_PRODUCT_FORM_ASA_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_PRODUCT_FORM_ASA_SUB" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       NUMBER
)
IS
/**Description - used for report GCO_PRODUCT_FORM_BATCH

* @author AWU 12 JAN 2010
* @lastUpdate
* @public
* @PARAM  parameter_0 GCO_GOOD_ID
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT cda.gco_good_id, cda.cas_default_repair, cda.cas_with_guarantee,
             cda.cas_guarantee_delay, cda.c_asa_guaranty_unit,
             ret.ret_rep_type,
             (SELECT dtr.dtr_short_description
                FROM asa_rep_type_descr dtr
               WHERE dtr.c_asa_description_type = '1'
                 AND dtr.asa_rep_type_id = ret.asa_rep_type_id
                 AND dtr.pc_lang_id = vpc_lang_id) rep_type_descr
        FROM gco_compl_data_ass cda, asa_rep_type ret
       WHERE cda.asa_rep_type_id = ret.asa_rep_type_id(+)
             AND cda.gco_good_id = parameter_0;
END rpt_gco_product_form_asa_sub;
