--------------------------------------------------------
--  DDL for Procedure RPT_CML_INVOICE_DOC_TOTAL_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_CML_INVOICE_DOC_TOTAL_SUB" (
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
      SELECT   cur.currency,
               SUM (foo.foo_document_total_amount) currency_total
          FROM cml_invoicing_job inj,
               doc_document doc,
               doc_foot foo,
               acs_financial_currency acs,
               pcs.pc_curr cur
         WHERE inj.cml_invoicing_job_id = doc.cml_invoicing_job_id
           AND doc.doc_document_id = foo.doc_document_id
           AND doc.acs_financial_currency_id = acs.acs_financial_currency_id
           AND acs.pc_curr_id = cur.pc_curr_id
           AND inj.cml_invoicing_job_id = TO_NUMBER (parameter_0)
      GROUP BY cur.currency;
END rpt_cml_invoice_doc_total_sub;
