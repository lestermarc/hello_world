--------------------------------------------------------
--  DDL for Procedure RPT_DOC_GAU_FORM_SIM
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_GAU_FORM_SIM" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
IS
/**
*    STORED PROCEDURE USED FOR THE REPORT GAU_FORM_SIMPLE

* @CREATED IN PROCONCEPT CHINA
* @AUTHOR AWU 1 JUN 2009
* @LASTUPDATE 20 FEB 2009
* @VERSION
* @PUBLIC
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT v_dg.doc_gauge_id, v_dg.gau_describe,
             v_dg.c_gauge_status_wording, v_dg.c_admin_domain,
             v_dg.c_admin_domain_wording, v_dg.c_gauge_type,
             v_dg.c_gauge_type_wording, v_dg.dic_gauge_categ_id,
             com_dic_functions.getdicodescr
                                ('DIC_GAUGE_CATEG',
                                 v_dg.dic_gauge_categ_id,
                                 vpc_lang_id
                                ) gauge_categ_wording,
             v_dg.dic_gauge_type_doc_id,
             com_dic_functions.getdicodescr
                          ('DIC_GAUGE_TYPE_DOC',
                           v_dg.dic_gauge_type_doc_id,
                           vpc_lang_id
                          ) gauge_type_doc_wording,
             v_dg.gau_numbering, v_dg.gau_ref_partner, v_dg.gau_traveller,
             v_dg.gau_dossier, v_dg.gau_expiry, v_dg.gau_edifact,
             v_dg.gau_expiry_nbr, v_dg.per_name, v_dg.gan_describe,
             v_dg.titel_text, v_dg.gau_edit_name, v_dg.gau_edit_name1,
             v_dg.gau_edit_name2, v_dg.gau_edit_name3, v_dg.gau_edit_name4,
             v_dg.gau_edit_name5, v_dg.gau_edit_text, v_dg.gau_edit_text1,
             v_dg.gau_edit_text2, v_dg.gau_edit_text3, v_dg.gau_edit_text4,
             v_dg.gau_edit_text5, v_dg.c_gauge_form_type,
             v_dg.gauge_form_type1, v_dg.gauge_form_type2,
             v_dg.gauge_form_type3, v_dg.gauge_form_type4,
             v_dg.gauge_form_type5, v_dg.gau_edit_bool1, v_dg.gau_edit_bool2,
             v_dg.gau_edit_bool3, v_dg.gau_edit_bool4, v_dg.gau_edit_bool5,
             v_dg.a_datecre, v_dg.a_datemod, dgd.gad_describe
        FROM v_doc_gauge v_dg, doc_gauge_description dgd
       WHERE v_dg.doc_gauge_id = dgd.doc_gauge_id(+)
         AND v_dg.pc_lang_id = vpc_lang_id
         AND dgd.pc_lang_id(+) = vpc_lang_id;
END rpt_doc_gau_form_sim;
