--------------------------------------------------------
--  DDL for Procedure RPT_GCO_AUX_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_AUX_SUB" (
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
      SELECT goo.goo_major_reference, goo.goo_secondary_reference,
             v_goo.gco_multimedia_element_id,
             v_goo.mme_multimedia_designation, v_goo.mme_free_description,
             v_goo.gco_substitution_list_id, v_goo.sul_subst_design_short,
             v_goo.sul_comment, v_goo.sul_from_date, v_goo.sul_until_date,
             v_goo.dic_accountable_group_id, v_goo.dic_good_line_id,
             v_goo.dic_good_family_id, v_goo.dic_good_model_id,
             v_goo.dic_good_group_id, v_goo.gco_good_id
        FROM v_gco_good_list v_goo, gco_good goo
       WHERE v_goo.sul_replacement_good_id = goo.gco_good_id(+)
         AND v_goo.gco_good_id = parameter_0;
END rpt_gco_aux_sub;
