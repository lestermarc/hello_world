--------------------------------------------------------
--  DDL for Procedure RPT_ACT_DOC_PRE_CTRL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_DOC_PRE_CTRL" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       NUMBER
)
/**
*Description  Used for report ACT_DOC_PRE_CTRL
*
*@created AWU 20 MAY 2009
*@lastUpdate
*@public
*@param PARAMETER_0 Only document with duplicate partner document ? (0=No / 1=Yes)
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
             job.a_datecre, par.par_document, p_cur.currency,
             act_functions.getduplicatepardocument
                                  (doc.act_document_id)
                                                      duplicate_par_document
        FROM act_job job,
             act_document doc,
             acj_job_type typ,
             acs_financial_year fye,
             act_part_imputation par,
             acs_financial_currency cur,
             acj_catalogue_document cat,
             pcs.pc_curr p_cur,
             acj_sub_set_cat ssc
       WHERE job.act_job_id = doc.act_job_id(+)
         AND job.acj_job_type_id = typ.acj_job_type_id
         AND job.acs_financial_year_id = fye.acs_financial_year_id
         AND doc.act_document_id = par.act_document_id(+)
         AND doc.acs_financial_currency_id = cur.acs_financial_currency_id(+)
         AND doc.acj_catalogue_document_id = cat.acj_catalogue_document_id(+)
         AND cur.pc_curr_id = p_cur.pc_curr_id(+)
         AND cat.acj_catalogue_document_id = ssc.acj_catalogue_document_id
         AND typ.typ_supplier_permanent = 1
         AND ssc.c_sub_set = 'ACC'
         AND ssc.c_type_cumul = 'PRE'
         AND (   act_functions.getduplicatepardocument (doc.act_document_id) <>
                                                                             0
              OR parameter_0 <> 1
             );
END rpt_act_doc_pre_ctrl;
