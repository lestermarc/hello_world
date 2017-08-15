--------------------------------------------------------
--  DDL for Procedure RPT_ASA_MISSION_OPEN
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ASA_MISSION_OPEN" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       VARCHAR2,
   parameter_1      IN       VARCHAR2,
   parameter_2      IN       VARCHAR2,
   parameter_3      IN       VARCHAR2,
   parameter_4      IN       VARCHAR2,
   parameter_5      IN       VARCHAR2,
   parameter_6      IN       VARCHAR2
)
IS
/*
* Description stored procedure used for the report ASA_MISSION_OPEN

* @created awu 25 Jun 2008
* @lastupdate awu 8 Feb 2010
* @public
* @param PARAMETER_0: Printing all Technician 0:No, 1:Yes
* @param PARAMETER_1: COM_LIST.LIS_JOB_ID only if parameter_0 is 0
* @param PARAMETER_2: Printing all Customer 0:No, 1:Yes
* @param PARAMETER_3: COM_LIST.LIS_JOB_ID only if parameter_2 is 0
* @param PARAMETER_4: Date from
* @param PARAMETER_5: Date to
* @param PARAMETER_6: Sort
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
   vpc_no_cust   dico_description.dit_descr%TYPE;
   vpc_no_tech   dico_description.dit_descr%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;
   vpc_no_cust :=
                pcs.pc_functions.translateword2 ('Pas de client', vpc_lang_id);
   vpc_no_tech :=
            pcs.pc_functions.translateword2 ('Pas de technicien', vpc_lang_id);

   OPEN arefcursor FOR
      SELECT mis.asa_mission_id, mis.mis_number, rco.rco_title installation,
             goo.goo_major_reference, mis.pac_custom_partner_id,
             NVL (per.per_name, vpc_no_cust) customer, itr.itr_number,
             itr.itr_person_id,
             NVL (emp.per_fullname, vpc_no_tech) interluctor,
             emp.per_initials, itr.itr_expected_date,
             itr.asa_intervention_id, mis.mis_request_date,
             mis.mis_description,
             (SELECT MAX (dmt.dmt_number)
                FROM asa_invoicing_process aip, doc_document dmt
               WHERE aip.doc_document_id = dmt.doc_document_id
                 AND aip.asa_intervention_id = itr.asa_intervention_id)
                                                                  dmt_number,
             (SELECT MAX (dmt.dmt_date_document)
                FROM asa_invoicing_process aip,
                     doc_document dmt
               WHERE aip.doc_document_id = dmt.doc_document_id
                 AND aip.asa_intervention_id = itr.asa_intervention_id)
                                                           dmt_date_document
        FROM asa_mission mis,
             asa_intervention itr,
             doc_record rco,
             gco_good goo,
             asa_mission_type mit,
             pac_person per,
             hrm_person emp
       WHERE mis.asa_machine_id = rco.doc_record_id
         AND mis.asa_mission_id = itr.asa_mission_id
         AND rco.rco_machine_good_id = goo.gco_good_id
         AND mis.asa_mission_type_id = mit.asa_mission_type_id
         AND mis.pac_custom_partner_id = per.pac_person_id(+)
         AND itr.itr_person_id = emp.hrm_person_id(+)
         AND (   itr.itr_person_id IN (
                    SELECT lis.lis_id_1
                      FROM com_list lis
                     WHERE lis.lis_job_id = TO_NUMBER (parameter_1)
                       AND lis.lis_code = 'HRM_PERSON_ID')
              OR parameter_0 = '1'
             )
         AND (   mis.pac_custom_partner_id IN (
                    SELECT lis.lis_id_1
                      FROM com_list lis
                     WHERE lis.lis_job_id = TO_NUMBER (parameter_3)
                       AND lis.lis_code = 'PAC_CUSTOM_PARTNER_ID')
              OR parameter_2 = '1'
             )
         AND (   TRUNC (mis.mis_request_date) >=
                                             TO_DATE (parameter_4, 'YYYYMMDD')
              OR parameter_4 IS NULL
             )
         AND (   TRUNC (mis.mis_request_date) <=
                                             TO_DATE (parameter_5, 'YYYYMMDD')
              OR parameter_5 IS NULL
             )
         AND mis.mis_accomplished = 0;
END rpt_asa_mission_open;
