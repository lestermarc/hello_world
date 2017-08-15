--------------------------------------------------------
--  DDL for Procedure RPT_DOC_GAU_FT_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_GAU_FT_SUB" (
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
             dgs.doc_gauge_signatory_id, dgs.gag_name, dgs.gag_function,
             dgs1.doc_gauge_signatory_id, dgs1.gag_name, dgs1.gag_function,
             v_pap.aph_code, v_pap.apt_label
        FROM doc_gauge dga,
             doc_gauge_signatory dgs,
             doc_gauge_signatory dgs1,
             pcs.v_pc_appltxt v_pap
       WHERE dga.doc_gauge_signatory_id = dgs.doc_gauge_signatory_id(+)
         AND dga.doc_doc_gauge_signatory_id = dgs1.doc_gauge_signatory_id(+)
         AND dga.pc_3_pc_appltxt_id = v_pap.pc_appltxt_id(+)
         AND v_pap.pc_lang_id = vpc_lang_id
         AND dga.doc_gauge_id = TO_NUMBER (pm_doc_gauge_id);
END rpt_doc_gau_ft_sub;
