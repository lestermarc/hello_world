--------------------------------------------------------
--  DDL for Procedure RPT_ACI_DOCUMENT_STATUS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACI_DOCUMENT_STATUS" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0      IN       VARCHAR2,
   parameter_1      IN       VARCHAR2,
   parameter_2      IN       VARCHAR2,
   parameter_3      IN       VARCHAR2,
   parameter_4      IN       VARCHAR2,
   parameter_5      IN       VARCHAR2,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
IS
/**
*DESCRIPTION
USED FOR REPORT ACI_DOCUMENT_STATUS
*author JLI
*lastUpdate 2009-7-29
*public
*@param PARAMETER_0:  USE_NAME(FROM)
*@param PARAMETER_1:  USE_NAME(TO)
*@param PARAMETER_2:  TYP_DESCRIPTION(FROM)
*@param PARAMETER_3:  TYP_DESCRIPTION(TO)
*@param PARAMETER_4:  DATE FROM
*@param PARAMETER_5:  DATE TO
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT doc.doc_number doc_number_aci, doc.doc_total_amount_dc,
             doc.doc_document_date, doc.c_status_document,
             doc.doc_integration_date, doc.a_datecre, doc.a_idcre,
             doc.c_fail_reason, cat.cat_description, typ.typ_description,
             atd.doc_number doc_number_act, acj.job_description,
             cur.currency, usr.use_name, usr.use_descr
        FROM aci_document doc,
             aci_document_status stu,
             acj_catalogue_document cat,
             acj_job_type typ,
             acj_job_type_s_catalogue tsc,
             acs_financial_currency fur,
             act_document atd,
             act_job acj,
             pcs.pc_curr cur,
             pcs.pc_user usr
       WHERE doc.aci_document_id = stu.aci_document_id
         AND doc.acj_job_type_s_catalogue_id = tsc.acj_job_type_s_catalogue_id
         AND tsc.acj_job_type_id = typ.acj_job_type_id(+)
         AND tsc.acj_catalogue_document_id = cat.acj_catalogue_document_id(+)
         AND doc.act_document_id = atd.act_document_id(+)
         AND atd.act_job_id = acj.act_job_id(+)
         AND doc.acs_financial_currency_id = fur.acs_financial_currency_id
         AND fur.pc_curr_id = cur.pc_curr_id
         AND doc.a_idcre = usr.use_ini(+)
         AND (   (parameter_0 = '0' AND parameter_1 = '0')
              OR (    parameter_0 = '0'
                  AND parameter_1 <> '0'
                  AND usr.use_name <= parameter_1
                 )
              OR (    parameter_1 = '0'
                  AND parameter_0 <> '0'
                  AND usr.use_name >= parameter_0
                 )
              OR (    parameter_1 <> '0'
                  AND parameter_0 <> '0'
                  AND usr.use_name >= parameter_0
                  AND usr.use_name <= parameter_1
                 )
             )
         AND (   (parameter_2 = '0' AND parameter_3 = '0')
              OR (    parameter_2 = '0'
                  AND parameter_3 <> '0'
                  AND typ.typ_description <= parameter_3
                 )
              OR (    parameter_3 = '0'
                  AND parameter_2 <> '0'
                  AND typ.typ_description >= parameter_2
                 )
              OR (    parameter_2 <> '0'
                  AND parameter_3 <> '0'
                  AND typ.typ_description >= parameter_2
                  AND typ.typ_description <= parameter_3
                 )
             )
         AND (    TO_CHAR (doc.a_datecre, 'YYYYMMDD') >=
                        SUBSTR (parameter_4, 1, 4)
                     || SUBSTR (parameter_4, 6, 2)
                     || SUBSTR (parameter_4, 9, 2)
              AND TO_CHAR (doc.a_datecre, 'YYYYMMDD') <=
                        SUBSTR (parameter_5, 1, 4)
                     || SUBSTR (parameter_5, 6, 2)
                     || SUBSTR (parameter_5, 9, 2)
             );
END rpt_aci_document_status;
