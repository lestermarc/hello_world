--------------------------------------------------------
--  DDL for Procedure RPT_ASA_MISSION_TECHNICIAN
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ASA_MISSION_TECHNICIAN" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       VARCHAR2,
   parameter_1      IN       VARCHAR2,
   parameter_2      IN       VARCHAR2,
   parameter_3      IN       VARCHAR2,
   parameter_4      IN       VARCHAR2
)
IS
/*
* Description stored procedure used for the report ASA_MISSION_TECHNICIAN

* @created awu 24 Jun 2008
* @lastupdate awu 8 Feb 2010
* @public
* @param PARAMETER_0: Technician list
* @param PARAMETER_1: DATE
* @param PARAMETER_2: DATE
* @param PARAMETER_3: STATUS LIST
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
      SELECT mis.mis_number, rco.rco_title installation,
             NVL (per.per_name, vpc_no_cust) customer, itr.itr_number,
             itr.itr_person_id,
             NVL (emp.per_fullname, vpc_no_tech) interluctor,
             mis.c_asa_mis_status, itr.itr_expected_date,
             itr.asa_intervention_id, mis.mis_request_date,
             mis.mis_description
        FROM asa_mission mis,
             asa_intervention itr,
             doc_record rco,
             asa_mission_type mit,
             pac_person per,
             hrm_person emp
       WHERE mis.asa_machine_id = rco.doc_record_id
         AND mis.asa_mission_id = itr.asa_mission_id
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
         AND (   TRUNC (mis.mis_request_date) >=
                                             TO_DATE (parameter_2, 'YYYYMMDD')
              OR parameter_2 IS NULL
             )
         AND (   TRUNC (mis.mis_request_date) <=
                                             TO_DATE (parameter_3, 'YYYYMMDD')
              OR parameter_3 IS NULL
             )
         AND (   parameter_4 IS NULL
              OR INSTR (',' || parameter_4 || ',',
                        ',' || mis.c_asa_mis_status || ','
                       ) > 0
             );
END rpt_asa_mission_technician;
