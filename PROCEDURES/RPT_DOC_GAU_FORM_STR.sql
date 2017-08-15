--------------------------------------------------------
--  DDL for Procedure RPT_DOC_GAU_FORM_STR
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_GAU_FORM_STR" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
IS
/**
*    STORED PROCEDURE USED FOR THE REPORT GAU_FORM_STRUCTURED

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
      SELECT dgd.gad_describe, v_dg.doc_gauge_id, v_dg.gau_describe,
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
             v_dg.pc__pc_appltxt_id, v_dg.titel_text, v_dg.gau_edit_name,
             v_dg.gau_edit_name1, v_dg.gau_edit_name2, v_dg.gau_edit_name3,
             v_dg.gau_edit_name4, v_dg.gau_edit_name5, v_dg.gau_edit_name6,
             v_dg.gau_edit_name7, v_dg.gau_edit_name8, v_dg.gau_edit_name9,
             v_dg.gau_edit_name10, v_dg.gau_edit_text, v_dg.gau_edit_text1,
             v_dg.gau_edit_text2, v_dg.gau_edit_text3, v_dg.gau_edit_text4,
             v_dg.gau_edit_text5, v_dg.gau_edit_text6, v_dg.gau_edit_text7,
             v_dg.gau_edit_text8, v_dg.gau_edit_text9, v_dg.gau_edit_text10,
             v_dg.c_gauge_form_type, v_dg.gauge_form_type1,
             v_dg.gauge_form_type2, v_dg.gauge_form_type3,
             v_dg.gauge_form_type4, v_dg.gauge_form_type5,
             v_dg.gauge_form_type6, v_dg.gauge_form_type7,
             v_dg.gauge_form_type8, v_dg.gauge_form_type9,
             v_dg.gauge_form_type10, v_dg.gau_edit_bool1,
             v_dg.gau_edit_bool2, v_dg.gau_edit_bool3, v_dg.gau_edit_bool4,
             v_dg.gau_edit_bool5, v_dg.gau_edit_bool6, v_dg.gau_edit_bool7,
             v_dg.gau_edit_bool8, v_dg.gau_edit_bool9, v_dg.gau_edit_bool10,
             v_dg.gau_confirm_cancel, v_dg.c_gauge_record_verify,
             v_dg.c_gau_auto_create_record, v_dg.gau_show_forms_on_insert,
             v_dg.gau_show_forms_on_update, v_dg.dic_gauge_group_id,
             v_dg.gau_incoterms, v_dg.gau_collate_printed_reports,
             v_dg.c_gauge_type_comment_visible, v_dg.gau_always_show_comment,
             v_dg.gau_cancel_status, v_dg.gau_show_forms_on_confirm,
             v_dg.gau_asa_record, v_dg.gau_confirm_status, v_dg.gau_history,
             v_dg.a_datecre, v_dg.a_datemod, v_dgs.gas_differed_confirmation,
             v_dgs.gas_auth_balance_return, v_dgs.gas_auth_balance_no_return,
             pcs.pc_functions.getappltxtlabel
                                             (v_dg.pc__pc_appltxt_id,
                                              vpc_lang_id
                                             ) appltxt
        FROM doc_gauge_description dgd,
             v_doc_gauge v_dg,
             v_doc_gauge_structured v_dgs
       WHERE v_dg.doc_gauge_id = dgd.doc_gauge_id(+)
         AND v_dg.doc_gauge_id = v_dgs.doc_gauge_id(+)
         AND v_dg.pc_lang_id = vpc_lang_id
         AND dgd.pc_lang_id = vpc_lang_id
         AND v_dgs.pc_lang_id = vpc_lang_id;
END rpt_doc_gau_form_str;
