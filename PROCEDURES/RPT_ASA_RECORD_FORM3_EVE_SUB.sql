--------------------------------------------------------
--  DDL for Procedure RPT_ASA_RECORD_FORM3_EVE_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ASA_RECORD_FORM3_EVE_SUB" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0      IN       VARCHAR2,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
IS
/*
* Description used for report asa_report_form3

* @created pna 05.09.2007 proconcept china
* @lastupdate mzhu 19 Feb 2009
* @public
* @param parameter_0: asa_record.are_number
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT   rre.rre_seq, rre.rre_date,
               com_functions.getdescodedescr
                                            ('C_ASA_REP_STATUS',
                                             rre.c_asa_rep_status,
                                             vpc_lang_id
                                            ) rep_status,
               dmt.dmt_number
          FROM asa_record_events rre, doc_position pos, doc_document dmt
         WHERE rre.doc_position_id = pos.doc_position_id(+)
           AND pos.doc_document_id = dmt.doc_document_id(+)
           AND rre.asa_record_id = TO_NUMBER(parameter_0)
      ORDER BY rre_seq;
END rpt_asa_record_form3_eve_sub;
