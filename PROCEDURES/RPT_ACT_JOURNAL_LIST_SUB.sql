--------------------------------------------------------
--  DDL for Procedure RPT_ACT_JOURNAL_LIST_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_JOURNAL_LIST_SUB" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_1      IN       VARCHAR2,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
/**
* description - used for report act_journal_list.rpt

* @author jliu 18 nov 2008
* @lastupdate 12 Feb 2009
* @public
* @PARAM PARAMETER_1: ACT_JOB_ID
*/
IS
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT atd.act_document_id, job.act_job_id
        FROM act_job job, act_document atd
       WHERE job.act_job_id = TO_NUMBER (parameter_1)
         AND job.act_job_id = atd.act_job_id;
END rpt_act_journal_list_sub;
