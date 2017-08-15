--------------------------------------------------------
--  DDL for Procedure RPT_ACT_DOC_PRE_NOT_VAL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_DOC_PRE_NOT_VAL" (
   arefcursor   IN OUT   crystal_cursor_types.dualcursortyp,
   PROCPARAMDUMMY IN varchar2 default null
)
/**
*Description  Used for report ACT_DOC_PRE_VAL
*
*@created AWU 20 MAY 2009
*@lastUpdate
*@public
*@param
*/
IS
BEGIN
   OPEN arefcursor FOR
      SELECT cat.acj_catalogue_document_id, cat.c_type_catalogue,
             cat.cat_description, typ.typ_supplier_permanent,
             fye.fye_no_exercice, doc.act_document_id, doc.doc_number,
             doc.doc_total_amount_dc, doc.doc_document_date,
             doc.doc_pre_entry_expiry, doc.doc_pre_entry_validation,
             doc.doc_pre_entry_ini, job.act_job_id, job.job_description,
             p_cur.currency, p_use.pc_user_id, p_use.use_name,
             p_use.use_descr
        FROM act_job job,
             act_document doc,
             acj_job_type typ,
             acs_financial_year fye,
             pcs.pc_user p_use,
             acs_financial_currency cur,
             acj_catalogue_document cat,
             pcs.pc_curr p_cur,
             acj_sub_set_cat ssc
       WHERE job.act_job_id = doc.act_job_id(+)
         AND job.acj_job_type_id = typ.acj_job_type_id
         AND job.acs_financial_year_id = fye.acs_financial_year_id
         AND doc.pc_user_id = p_use.pc_user_id(+)
         AND doc.acs_financial_currency_id = cur.acs_financial_currency_id(+)
         AND doc.acj_catalogue_document_id = cat.acj_catalogue_document_id(+)
         AND cur.pc_curr_id = p_cur.pc_curr_id(+)
         AND cat.acj_catalogue_document_id = ssc.acj_catalogue_document_id
         AND doc.doc_pre_entry_validation IS NULL
         AND typ.typ_supplier_permanent = 1
         AND ssc.c_sub_set = 'ACC'
         AND ssc.c_type_cumul = 'PRE';
END rpt_act_doc_pre_not_val;
