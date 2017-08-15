--------------------------------------------------------
--  DDL for Procedure RPT_GCO_CORRELATION_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_CORRELATION_SUB" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       NUMBER
)
IS
/**Description - used for report GCO_PRODUCT_FORM_BATCH, GCO_SERVICE_FORM_BATCH

* @author AWU 13 OCT 2009
* @lastUpdate AWU 21 FEB 2009
* @public
* @PARAM PARAMETER_0 gco_good_id
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT con.gco_connected_good_id, con.gco_good_id,
             con.dic_connected_type_id, v_gca.goo_major_reference,
             v_gca.des_short_description
        FROM gco_connected_good con, v_gco_good_catalogue v_gca
       WHERE con.gco_gco_good_id = v_gca.gco_good_id
         AND v_gca.pc_lang_id = vpc_lang_id
         AND con.gco_good_id = parameter_0;
END rpt_gco_correlation_sub;
