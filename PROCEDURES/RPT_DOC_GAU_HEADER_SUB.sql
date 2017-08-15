--------------------------------------------------------
--  DDL for Procedure RPT_DOC_GAU_HEADER_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_GAU_HEADER_SUB" (
   arefcursor        IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid    IN       pcs.pc_lang.lanid%TYPE,
   pm_doc_gauge_id   IN       VARCHAR2
)
IS
/**
*    STORED PROCEDURE USED FOR THE REPORT GAU_FORM_STRUCTURED, GAU_FORM_SIMPLE

* @CREATED IN PROCONCEPT CHINA
* @AUTHOR AWU 1 JUN 2009
* @LASTUPDATE 20 FEB 2009
* @VERSION
* @PUBLIC
* @PARAM pm_doc_gauge_id     DOC_GAUGE_ID
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT '1' group_string, --used for display of header in subreport
             v_dg.header_text, v_dg.doc_text, v_dg.dic_address_type_id,
             v_dg.dic_add_typ_wording, v_dg.dic_address_type1_id,
             v_dg.dic_add_typ1_wording, v_dg.dic_address_type2_id,
             v_dg.dic_add_typ2_wording
        FROM v_doc_gauge v_dg
       WHERE v_dg.pc_lang_id = vpc_lang_id
         AND v_dg.doc_gauge_id = TO_NUMBER (pm_doc_gauge_id);
END rpt_doc_gau_header_sub;
