--------------------------------------------------------
--  DDL for Procedure RPT_SQM_AUDIT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_SQM_AUDIT" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       NUMBER
)
IS
/**Description - used for report SQM_AUDIT

* @author AWU 13 MAY 2009
* @lastUpdate
* @public
* @PARAM PARAMETER_0 SQM_AUDIT_ID
*/
BEGIN
   OPEN arefcursor FOR
      SELECT aum.aum_description, per.per_name, aud.aud_result, aud.aud_date,
             aud.aud_comment, ade.sqm_audit_chapter_id, ach.ach_title,
             ade.sqm_audit_question_id, aqu.aqu_description,
             ade.sqm_audit_id,
             (SELECT NVL (ade1.ade_points, 0)
                FROM sqm_audit_detail ade1
               WHERE ade1.sqm_audit_id = ade.sqm_audit_id
                 AND ade1.sqm_audit_chapter_id = ade.sqm_audit_chapter_id
                 AND ade1.sqm_audit_question_id IS NULL) chapter_ade_point,
             (SELECT ade1.ade_comment
                FROM sqm_audit_detail ade1
               WHERE ade1.sqm_audit_id = ade.sqm_audit_id
                 AND ade1.sqm_audit_chapter_id = ade.sqm_audit_chapter_id
                 AND ade1.sqm_audit_question_id IS NULL) chapter_ade_comment,
             NVL (TO_CHAR (ade.ade_answer_number),
                  NVL (ade.ade_answer_text,
                       NVL (axv.axv_description, axv.axv_value)
                      )
                 ) response,
             NVL (ade.ade_points, 0) ade_points, ade.ade_comment,
             aqu.aqu_seq, csm.csm_sequence, ade.sqm_axis_value_id
        FROM sqm_audit aud,
             sqm_audit_detail ade,
             sqm_audit_model aum,
             sqm_audit_chapter ach,
             sqm_audit_question aqu,
             sqm_axis sax,
             sqm_axis_value axv,
             sqm_audit_chap_s_model csm,
             pac_person per
       WHERE aud.sqm_audit_id = ade.sqm_audit_id(+)
         AND aud.sqm_audit_model_id = aum.sqm_audit_model_id(+)
         AND ade.sqm_audit_chapter_id = ach.sqm_audit_chapter_id(+)
         AND ade.sqm_audit_question_id = aqu.sqm_audit_question_id(+)
         AND aqu.sqm_axis_id = sax.sqm_axis_id(+)
         AND ade.sqm_axis_value_id = axv.sqm_axis_value_id(+)
         AND aud.pac_third_id = per.pac_person_id(+)
         AND ade.ade_mcq_selected = 1
         AND aud.sqm_audit_model_id = csm.sqm_audit_model_id
         AND ade.sqm_audit_chapter_id = csm.sqm_audit_chapter_id
         AND aud.sqm_audit_id = parameter_0;
END rpt_sqm_audit;
