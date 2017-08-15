--------------------------------------------------------
--  DDL for Package Body VDOC_HRM_OEM_PERSON_DATA
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "VDOC_HRM_OEM_PERSON_DATA" 
IS
   PROCEDURE merge_person (
      sys_creator             IN   VARCHAR2,
      pcschar_rec_id          IN   VARCHAR2,
      task_type               IN   VARCHAR2,
      pcschar_surname         IN   VARCHAR2,
      pcschar_address         IN   VARCHAR2,
      pcschar_zipcode         IN   VARCHAR2,
      pcschar_city            IN   VARCHAR2,
      pcschar_country         IN   VARCHAR2,
      pcschar_phone           IN   VARCHAR2,
      pcschar_phone2          IN   VARCHAR2,
      pcschar_mobile          IN   VARCHAR2,
      pcschar_civilstatus     IN   VARCHAR2,
      pcschar_placeoforigin   IN   VARCHAR2,
      pcsdate_civilstatus     IN   VARCHAR2,
      pcschar_bank            IN   VARCHAR2,
      pcschar_bank_account    IN   VARCHAR2,
      children                IN   CLOB,
      req_comment             IN   VARCHAR2
   )
   IS
   BEGIN
      IF task_type = '01'
      THEN
         UPDATE hrm_person
            SET per_home_phone = pcschar_phone,
                per_home2_phone = pcschar_phone2,
                per_mobile_phone = pcschar_mobile
          WHERE hrm_person_id = pcschar_rec_id;
      ELSIF task_type = '02'
      THEN
         UPDATE hrm_person
            SET per_homestreet = pcschar_address,
                per_homecity = pcschar_city,
                per_homepostalcode = pcschar_zipcode,
                per_homecountry = pcschar_country,
                per_mail_add_selected =
                      NVL2 (pcschar_address, pcschar_address || CHR (10), '')
                   || NVL2 (pcschar_zipcode, pcschar_zipcode || ' ', '')
                   || NVL (pcschar_city, ' ')
                   || NVL (pcschar_country, ' ')
          WHERE hrm_person_id = pcschar_rec_id;
      ELSIF task_type = '03'
      THEN
         UPDATE hrm_person
            SET per_last_name = pcschar_surname,
                emp_maiden_name = per_last_name,
                emp_civil_status_since = pcsdate_civilstatus,
                c_civil_status = pcschar_civilstatus
          WHERE hrm_person_id = pcschar_rec_id;
      ELSIF task_type = '04'
      THEN
         FOR x IN
            (SELECT EXTRACTVALUE (COLUMN_VALUE, '//PCSCHAR_RELATED_ID') ID,
                    EXTRACTVALUE (COLUMN_VALUE,
                                  '//PCSCHAR_CHILD_FIRSTNAME'
                                 ) firstname,
                    EXTRACTVALUE (COLUMN_VALUE,
                                  '//PCSCHAR_CHILD_LASTNAME'
                                 ) lastname,
                    TO_DATE
                       (SUBSTR (EXTRACTVALUE (COLUMN_VALUE,
                                              '//PCSCHAR_CHILD_BIRTHDATE'
                                             ),
                                1,
                                10
                               ),
                        'YYYY-MM-DD'
                       ) birthdate,
                    EXTRACTVALUE (COLUMN_VALUE,
                                  '//PCSCHAR_CHILD_GENDER'
                                 ) gender
               FROM TABLE (XMLSEQUENCE (EXTRACT (XMLTYPE (children), '//ROW'))))
         LOOP
            IF x.ID IS NULL
            THEN
               INSERT INTO hrm_related_to
                           (hrm_related_to_id, hrm_employee_id,
                            c_related_to_type, c_sex, rel_name, a_datecre,
                            a_idcre, rel_first_name,
                            rel_birth_date
                           )
                    VALUES (init_id_seq.NEXTVAL, pcschar_rec_id,
                            '2', x.gender, x.lastname, SYSDATE,
                            pcs.PC_I_LIB_SESSION.getuserini, x.firstname,
                            x.birthdate
                           );
            ELSE
               UPDATE hrm_related_to
                  SET rel_name = x.lastname,
                      rel_first_name = x.firstname,
                      rel_birth_date = x.birthdate,
                      c_sex = x.gender
                WHERE hrm_related_to_id = x.ID;
            END IF;
         END LOOP;
      ELSIF task_type = '05'
      THEN
         UPDATE hrm_financial_ref
            SET pc_bank_id = pcschar_bank,
                fin_account_number = pcschar_bank_account
          WHERE hrm_employee_id = pcschar_rec_id AND fin_sequence = 0;
      ELSIF task_type = '06'
      THEN
         NULL;
      END IF;
   END;
END vdoc_hrm_oem_person_data;
