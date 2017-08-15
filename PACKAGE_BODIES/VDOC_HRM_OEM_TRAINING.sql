--------------------------------------------------------
--  DDL for Package Body VDOC_HRM_OEM_TRAINING
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "VDOC_HRM_OEM_TRAINING" 
IS
   PROCEDURE inserts (
      rec_id_in        IN   VARCHAR2,
      training_in      IN   VARCHAR2,
      session_in       IN   VARCHAR2,
      date_from_in     IN   DATE,
      date_to_in       IN   DATE,
      req_comment_in   IN   VARCHAR2
   )
   IS
   BEGIN
      INSERT INTO hrm_subscription
                  (hrm_subscription_id, hrm_person_id, hrm_training_id,
                   c_subscription_status, hrm_session_id,
                   dic_training_categ1_id, dic_training_categ2_id, sub_date,
                   c_training_priority, sub_plan_date, sub_planned,
                   sub_comment)
         SELECT init_id_seq.NEXTVAL, rec_id_in, training_in, '1', session_in,
                dic_training_categ1_id, dic_training_categ2_id, SYSDATE, '2',
                CASE
                   WHEN date_from_in IS NOT NULL
                      THEN LAST_DAY (date_from_in)
                END,
                1, req_comment_in
           FROM hrm_training
          WHERE hrm_training_id = training_in;
   END;
END;
