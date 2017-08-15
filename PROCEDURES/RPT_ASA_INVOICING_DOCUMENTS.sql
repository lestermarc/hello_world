--------------------------------------------------------
--  DDL for Procedure RPT_ASA_INVOICING_DOCUMENTS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ASA_INVOICING_DOCUMENTS" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       NUMBER
)
IS
/**
* Description - used for the report ASA_INVOICING_DOCUMENTS

* @AUTHOR AWU 23 JUL 2009
* @LASTUPDATE
* @VERSION
* @PUBLIC
* @PARAM PROCPARAM_0     ASA_INVOICING_JOB_ID
*/
BEGIN
   OPEN arefcursor FOR
      SELECT DISTINCT aij.aij_description, aij.aij_date, doc.dmt_number,
                      per.pac_person_id, per.per_name, per.per_key1,
                      foo.foo_document_total_amount, cur.currency,
                      pco.pco_descr
                 FROM asa_invoicing_job aij,
                      asa_invoicing_process aip,
                      doc_document doc,
                      doc_foot foo,
                      pac_person per,
                      acs_financial_currency acs,
                      pcs.pc_curr cur,
                      pac_payment_condition pco
                WHERE aij.asa_invoicing_job_id = aip.asa_invoicing_job_id
                  AND aip.doc_document_id = doc.doc_document_id
                  AND doc.doc_document_id = foo.doc_document_id
                  AND doc.pac_third_id = per.pac_person_id
                  AND doc.acs_financial_currency_id =
                                                 acs.acs_financial_currency_id
                  AND acs.pc_curr_id = cur.pc_curr_id
                  AND doc.pac_payment_condition_id =
                                                  pco.pac_payment_condition_id
                  AND aij.asa_invoicing_job_id = parameter_0;
END rpt_asa_invoicing_documents;
