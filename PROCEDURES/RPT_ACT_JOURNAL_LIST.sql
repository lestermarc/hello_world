--------------------------------------------------------
--  DDL for Procedure RPT_ACT_JOURNAL_LIST
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_JOURNAL_LIST" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0      IN       NUMBER,
   parameter_1      IN       NUMBER,
   parameter_2      IN       NUMBER,
   parameter_3      IN       NUMBER,
   parameter_4      IN       VARCHAR2,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
/**
* description - used for report act_journal_list.rpt

* @author jliu 18 nov 2008
* @lastupdate 12 Feb 2009
* @public
* @PARAM PARAMETER_0: ACS_FINANCIAL_YEAR_ID
* @PARAM PARAMETER_1: PC_USELANG_ID
* @PARAM PARAMETER_2: Journal from (Nr)
* @PARAM PARAMETER_3: Journal to (Nr)
* @PARAM PARAMETER_4: C_TYPE_ACCOUNTING (FIN/MAN/BUD)
*/
IS
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT des.des_description_summary, eta.c_etat_journal, job.act_job_id,
             jou.act_journal_id, jou.jou_description, jou.jou_number,
             jou.a_datecre, jou.a_datemod, jou.a_idcre, jou.a_idmod,
             (select count(*) from ACT_DOCUMENT WHERE ACT_JOB_ID = JOB.ACT_JOB_ID) doc_count
        FROM act_journal jou,
             act_etat_journal eta,
             acs_accounting atg,
             act_job job,
             acs_financial_year yea,
             acs_description des,
             acj_job_type typ,
             pcs.pc_lang lan
       WHERE jou.act_journal_id = eta.act_journal_id
         AND jou.acs_accounting_id = atg.acs_accounting_id
         AND atg.acs_accounting_id = des.acs_accounting_id
         AND des.pc_lang_id = lan.pc_lang_id
         AND jou.act_job_id = job.act_job_id
         AND job.acj_job_type_id = typ.acj_job_type_id
         AND jou.acs_financial_year_id = yea.acs_financial_year_id
         AND lan.pc_lang_id = vpc_lang_id
         AND yea.acs_financial_year_id = parameter_0
         AND act_functions.isuserautorizedforjobtype (parameter_1,
                                                      job.acj_job_type_id
                                                     ) = 1
         AND (jou.jou_number >= parameter_2 AND jou.jou_number <= parameter_3
             )
         AND atg.c_type_accounting = parameter_4
         AND eta.c_sub_set <> 'REC'
         AND eta.c_sub_set <> 'PAY';
END rpt_act_journal_list;
