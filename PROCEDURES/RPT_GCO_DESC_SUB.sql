--------------------------------------------------------
--  DDL for Procedure RPT_GCO_DESC_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_DESC_SUB" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       NUMBER
)
IS
/**Description - used for report GCO_PSEUDO_FORM_BATCH, GCO_SERVICE_FORM_BATCH

* @author AWU 13 OCT 2009
* @lastUpdate AWU 7 MAY 2009
* @public
* @param parameter_0: GCO_GOOD_ID
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT v_des.des_short_description, v_des.des_long_description,
             v_des.des_free_description, v_des.des_short_descr_st,
             v_des.des_long_descr_st, v_des.des_free_descr_st,
             v_des.des_short_descr_pu, v_des.des_long_descr_pu,
             v_des.des_free_descr_pu, v_des.des_short_descr_sa,
             v_des.des_long_descr_sa, v_des.des_free_descr_sa, lan.lanname,
             lan.pc_lang_id, v_des.gco_good_id
        FROM v_good_description v_des, pcs.pc_lang lan
       WHERE v_des.pc_lang_id = lan.pc_lang_id
         AND v_des.gco_good_id = parameter_0;
END rpt_gco_desc_sub;
