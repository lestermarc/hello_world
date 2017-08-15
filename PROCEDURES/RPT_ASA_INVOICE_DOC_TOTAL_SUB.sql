--------------------------------------------------------
--  DDL for Procedure RPT_ASA_INVOICE_DOC_TOTAL_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ASA_INVOICE_DOC_TOTAL_SUB" (
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
      SELECT   dmt.currency,
               SUM (dmt.foo_document_total_amount) currency_total
          FROM (SELECT DISTINCT doc.doc_document_id, cur.currency,
                                foo.foo_document_total_amount
                           FROM asa_invoicing_job aij,
                                asa_invoicing_process aip,
                                doc_document doc,
                                doc_foot foo,
                                acs_financial_currency acs,
                                pcs.pc_curr cur
                          WHERE aij.asa_invoicing_job_id =
                                                      aip.asa_invoicing_job_id
                            AND aip.doc_document_id = doc.doc_document_id
                            AND doc.doc_document_id = foo.doc_document_id
                            AND doc.acs_financial_currency_id =
                                                 acs.acs_financial_currency_id
                            AND acs.pc_curr_id = cur.pc_curr_id
                            AND aij.asa_invoicing_job_id = parameter_0) dmt
      GROUP BY dmt.currency;
END rpt_asa_invoice_doc_total_sub;
