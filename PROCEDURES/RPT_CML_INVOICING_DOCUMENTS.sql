--------------------------------------------------------
--  DDL for Procedure RPT_CML_INVOICING_DOCUMENTS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_CML_INVOICING_DOCUMENTS" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       VARCHAR2
)
IS
/**
* Description - used for the report CML_INVOICING_DOCUMENTS

* @CREATED IN PROCONCEPT CHINA
* @AUTHOR MZHU 01 DEC 2006
* @LASTUPDATE  24 FEB 2009
* @VERSION
* @PUBLIC
* @PARAM PROCPARAM_0     CML_INVOICING_JOB.CML_INVOICING_JOB_ID
*/
BEGIN
   OPEN arefcursor FOR
      SELECT inj.inj_description, inj_date, doc.dmt_number,
             per.pac_person_id, per.per_name, per.per_key1,
             foo.foo_document_total_amount, cur.currency, pco.pco_descr
        FROM cml_invoicing_job inj,
             doc_document doc,
             doc_foot foo,
             pac_person per,
             acs_financial_currency acs,
             pcs.pc_curr cur,
             pac_payment_condition pco
       WHERE inj.cml_invoicing_job_id = doc.cml_invoicing_job_id
         AND doc.doc_document_id = foo.doc_document_id
         AND doc.pac_third_id = per.pac_person_id
         AND doc.acs_financial_currency_id = acs.acs_financial_currency_id
         AND acs.pc_curr_id = cur.pc_curr_id
         AND doc.pac_payment_condition_id = pco.pac_payment_condition_id
         AND inj.cml_invoicing_job_id = TO_NUMBER (parameter_0);
END rpt_cml_invoicing_documents;
