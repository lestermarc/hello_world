--------------------------------------------------------
--  DDL for Package Body VDOC_ACT_OEM_REMINDER
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "VDOC_ACT_OEM_REMINDER" 
IS
   FUNCTION communications (rec_in IN pac_person.pac_person_id%TYPE)
      RETURN VARCHAR2
   IS
      l_result   VARCHAR2 (4000);
   BEGIN
      FOR comm IN (SELECT   t.dic_communication_type_id,
                               NVL2 (com_area_code,
                                     com_area_code || ' ',
                                     ''
                                    )
                            || com_ext_number ext_number,
                            CASE
                               WHEN dco_default1 = 1
                                  THEN 1
                               WHEN dco_default2 = 1
                                  THEN 2
                               WHEN dco_default3 = 1
                                  THEN 3
                               ELSE 4
                            END ordre
                       FROM pac_communication c, dic_communication_type t
                      WHERE c.dic_communication_type_id =
                                                  t.dic_communication_type_id
                   ORDER BY 3, 2)
      LOOP
         SELECT    NVL2 (l_result, l_result || CHR (10), '')
                || RPAD (comm.dic_communication_type_id, 10, ' ')
                || comm.ext_number
           INTO l_result
           FROM DUAL;
      END LOOP;

      RETURN l_result;
   END;

   FUNCTION claim_level (cust_in IN pac_person.pac_person_id%TYPE)
      RETURN VARCHAR2
   IS
      l_result   VARCHAR2 (10);
   BEGIN
      SELECT rde_no_remainder
        INTO l_result
        FROM pac_remainder_detail
       WHERE rde_claims_level = 1
         AND pac_remainder_category_id =
                                      (SELECT pac_remainder_category_id
                                         FROM pac_custom_partner c
                                        WHERE pac_custom_partner_id = cust_in);

      RETURN l_result;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN 100;
   END;

   PROCEDURE wfl_complete_activity (p_rec_id VARCHAR2, p_state VARCHAR2)
   IS
      l_rec_id   wfl_process_instances.pri_rec_id%TYPE;
   BEGIN
      l_rec_id := TO_NUMBER (p_rec_id);
      com_vdoc.wfl_attribute_by_name ('ACT_DOCUMENT',
                                      p_rec_id,
                                      'ACCEPTED',
                                      p_state
                                     );
      com_vdoc.wfl_complete_activity ('ACT_DOCUMENT', p_rec_id);
   END;
END vdoc_act_oem_reminder;
