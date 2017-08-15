--------------------------------------------------------
--  DDL for Procedure RPT_ASA_MISSION_GOOD
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ASA_MISSION_GOOD" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       VARCHAR2,
   parameter_1      IN       VARCHAR2,
   parameter_2      IN       VARCHAR2,
   parameter_3      IN       VARCHAR2,
   parameter_4      IN       VARCHAR2,
   parameter_5      IN       VARCHAR2,
   parameter_6      IN       VARCHAR2,
   parameter_7      IN       VARCHAR2,
   parameter_8      IN       VARCHAR2
)
IS
/*
* Description stored procedure used for the report ASA_MISSION_GOOD

* @created awu 22 Jun 2008
* @lastupdate
* @public
* @param PARAMETER_0: Printing all products 0:no, 1:yes
* @param PARAMETER_1: COM_LIST_LIS_JOB_ID only if parameter_0 is 0
* @param PARAMETER_2: Printing all customers 0:no, 1:yes
* @param PARAMETER_3: COM_LIST.LIS_JOB_ID only if parameter_1 is 0
* @param PARAMETER_4: Date from
* @param PARAMETER_5: Date to
* @param PARAMETER_6: number of minmum intervention
* @param PARAMETER_7: status of mission
* @param PARAMETER_8: Detail 0:no 1:yes
*/
BEGIN
   OPEN arefcursor FOR
      SELECT rco.rco_machine_good_id, goo.goo_major_reference,
             gco_functions.getdescription
                                    (rco.rco_machine_good_id,
                                     procuser_lanid,
                                     1,
                                     '01'
                                    ) goo_description,
             mis.mis_number, rco.rco_title installation,
             mis.pac_custom_partner_id, per.per_name customer,
             itr.itr_number,
                emp.per_title
             || ' '
             || emp.per_first_name
             || ' '
             || emp.per_last_name interluctor,
             itr.itr_expected_date, itr.asa_intervention_id,
             mis.mis_description, mis.mis_request_date, mis.c_asa_mis_status
        FROM asa_mission mis,
             asa_intervention itr,
             doc_record rco,
             gco_good goo,
             asa_mission_type mit,
             pac_person per,
             hrm_person emp,
             (SELECT   rco1.rco_machine_good_id
                  FROM asa_mission mis1,
                       asa_intervention itr1,
                       doc_record rco1,
                       gco_good goo1,
                       asa_mission_type mit1,
                       pac_person per1,
                       hrm_person emp1
                 WHERE mis1.asa_machine_id = rco1.doc_record_id
                   AND mis1.asa_mission_id = itr1.asa_mission_id
                   AND rco1.rco_machine_good_id = goo1.gco_good_id
                   AND mis1.asa_mission_type_id = mit1.asa_mission_type_id
                   AND mis1.pac_custom_partner_id = per1.pac_person_id(+)
                   AND itr1.itr_person_id = emp1.hrm_person_id(+)
                   AND (   rco1.rco_machine_good_id IN (
                              SELECT glt1.lis_id_1
                                FROM com_list glt1
                               WHERE glt1.lis_job_id = TO_NUMBER (parameter_1)
                                 AND glt1.lis_code = 'GCO_GOOD_ID')
                        OR parameter_0 = '1'
                       )
                   AND (   mis1.pac_custom_partner_id IN (
                              SELECT clt1.lis_id_1
                                FROM com_list clt1
                               WHERE clt1.lis_job_id = TO_NUMBER (parameter_3)
                                 AND clt1.lis_code = 'PAC_CUSTOM_PARTNER_ID')
                        OR parameter_2 = '1'
                       )
                   AND (   parameter_7 IS NULL
                        OR INSTR (',' || parameter_7 || ',',
                                  ',' || mis1.c_asa_mis_status || ','
                                 ) > 0
                       )
                   AND (   mis1.mis_request_date >=
                                             TO_DATE (parameter_4, 'YYYYMMDD')
                        OR parameter_4 IS NULL
                       )
                   AND (   mis1.mis_request_date <=
                                             TO_DATE (parameter_5, 'YYYYMMDD')
                        OR parameter_5 IS NULL
                       )
              GROUP BY rco1.rco_machine_good_id
                HAVING COUNT (itr1.asa_intervention_id) >=
                                              NVL (TO_NUMBER (parameter_6), 0)) gct
       WHERE mis.asa_machine_id = rco.doc_record_id
         AND mis.asa_mission_id = itr.asa_mission_id
         AND rco.rco_machine_good_id = goo.gco_good_id
         AND mis.asa_mission_type_id = mit.asa_mission_type_id
         AND mis.pac_custom_partner_id = per.pac_person_id(+)
         AND itr.itr_person_id = emp.hrm_person_id(+)
         AND rco.rco_machine_good_id = gct.rco_machine_good_id
         AND (   rco.rco_machine_good_id IN (
                    SELECT glt.lis_id_1
                      FROM com_list glt
                     WHERE glt.lis_job_id = TO_NUMBER (parameter_1)
                       AND glt.lis_code = 'GCO_GOOD_ID')
              OR parameter_0 = '1'
             )
         AND (   mis.pac_custom_partner_id IN (
                    SELECT clt.lis_id_1
                      FROM com_list clt
                     WHERE clt.lis_job_id = TO_NUMBER (parameter_3)
                       AND clt.lis_code = 'PAC_CUSTOM_PARTNER_ID')
              OR parameter_2 = '1'
             )
         AND (   parameter_7 IS NULL
              OR INSTR (',' || parameter_7 || ',',
                        ',' || mis.c_asa_mis_status || ','
                       ) > 0
             )
         AND (   mis.mis_request_date >= TO_DATE (parameter_4, 'YYYYMMDD')
              OR parameter_4 IS NULL
             )
         AND (   mis.mis_request_date <= TO_DATE (parameter_5, 'YYYYMMDD')
              OR parameter_5 IS NULL
             );
END rpt_asa_mission_good;
