--------------------------------------------------------
--  DDL for Procedure RPT_ACT_JOB_PRE_BATCH
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_JOB_PRE_BATCH" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_1      IN       NUMBER,
   parameter_2      IN       VARCHAR2,
   parameter_3      IN       VARCHAR2,
   parameter_4      IN       NUMBER,
   parameter_5      IN       VARCHAR2,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
/**

*Description - used for report ACT_JOB_PRE_BATCH

* @author jliu 18 Nov 2008
* @lastupdate 12 Feb 2009
* @public
* @PARAM PARAMETER_1: ACJ_JOB_TYPE_ID
* @PARAM PARAMETER_2: Job description from
* @PARAM PARAMETER_3: Job description to
* @PARAM PARAMETER_4: ACS_FINANCIAL_YEAR_ID
* @PARAM PARAMETER_5: PC_USER_ID
*/
IS
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT cat.acj_catalogue_document_id, cat.c_type_catalogue,
             acj_functions.translatecatdescr
                              (cat.acj_catalogue_document_id,
                               vpc_lang_id
                              ) cat_description,
             typ.acj_job_type_id, typ.typ_supplier_permanent,
             yea.fye_no_exercice, doc.act_document_id, doc.doc_number,
             doc.doc_total_amount_dc, doc.doc_document_date,
             doc.doc_pre_entry_expiry, doc.doc_pre_entry_validation,
             doc.doc_pre_entry_ini, job.act_job_id, job.job_description,
             job.acs_financial_year_id, cur.currency, usr.pc_user_id,
             usr.use_name, usr.use_descr, imp.par_document,
             per.per_name cus_name, per.per_forename cus_forname,
             per2.per_name sup_name, per2.per_forename sup_forname
        FROM acj_catalogue_document cat,
             acj_job_type typ,
             acs_financial_currency fur,
             acs_financial_year yea,
             act_document doc,
             act_job job,
             pcs.pc_curr cur,
             pcs.pc_user usr,
             act_part_imputation imp,
             pac_person per,
             pac_person per2
       WHERE job.act_job_id = doc.act_job_id(+)
         AND doc.pc_user_id = usr.pc_user_id(+)
         AND doc.acs_financial_currency_id = fur.acs_financial_currency_id(+)
         AND fur.pc_curr_id = cur.pc_curr_id(+)
         AND doc.acj_catalogue_document_id = cat.acj_catalogue_document_id(+)
         AND job.acj_job_type_id = typ.acj_job_type_id
         AND job.acs_financial_year_id = yea.acs_financial_year_id
         AND doc.act_document_id = imp.act_document_id
         AND imp.pac_custom_partner_id = per.pac_person_id(+)
         AND imp.pac_supplier_partner_id = per2.pac_person_id(+)
         AND job.acs_financial_year_id = parameter_4
         AND typ.typ_supplier_permanent = 1
         AND job.job_description >= parameter_2
         AND job.job_description <= parameter_3
         AND act_functions.isuserautorizedforjobtype (parameter_5,
                                                      job.acj_job_type_id
                                                     ) = 1
         AND (parameter_1 = 0 OR typ.acj_job_type_id = parameter_1);
END rpt_act_job_pre_batch;
