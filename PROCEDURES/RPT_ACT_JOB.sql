--------------------------------------------------------
--  DDL for Procedure RPT_ACT_JOB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_JOB" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0      IN       VARCHAR2,
   parameter_4      IN       VARCHAR2,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
/**
*Description - used for report ACT_JOB
* @author jliu 18 nov 2008
* @lastupdate 12 Feb 2009
* @public
* @param PARAMETER_0: ACT_JOB_ID
* @param PARAMETER_4: ACS_FINANCIAL_YEAR_ID
*/

IS
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT cat.acj_catalogue_document_id,
             acj_functions.translatecatdescr
                              (cat.acj_catalogue_document_id,
                               vpc_lang_id
                              ) cat_description,
             fur.fin_local_currency,
                                    doc.act_document_id, doc.doc_number,
             doc.doc_total_amount_dc, doc.doc_document_date,
             doc.act_journal_id, doc.act_act_journal_id, job.act_job_id,
             job.job_description, job.acs_financial_year_id, job.a_datecre,
             job.a_datemod, job.a_idcre, job.a_idmod, cur.currency
        FROM acj_catalogue_document cat,
             acj_job_type typ,
             acs_financial_currency fur,
             acs_financial_year yea,
             act_document doc,
             act_job job,
             pcs.pc_curr cur
       WHERE job.act_job_id = doc.act_job_id(+)
         AND doc.acs_financial_currency_id = fur.acs_financial_currency_id(+)
         AND fur.pc_curr_id = cur.pc_curr_id(+)
         AND doc.acj_catalogue_document_id = cat.acj_catalogue_document_id(+)
         AND job.acj_job_type_id = typ.acj_job_type_id
         AND job.acs_financial_year_id = yea.acs_financial_year_id
         AND JOB.ACS_FINANCIAL_YEAR_ID = TO_NUMBER (parameter_4)
         AND (parameter_0 =0 OR job.act_job_id = TO_NUMBER (parameter_0));
END rpt_act_job;
