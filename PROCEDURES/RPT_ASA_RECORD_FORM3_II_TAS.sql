--------------------------------------------------------
--  DDL for Procedure RPT_ASA_RECORD_FORM3_II_TAS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ASA_RECORD_FORM3_II_TAS" (
   AREFCURSOR    IN OUT   CRYSTAL_CURSOR_TYPES.DUALCURSORTYP,
   PARAMETER_0   IN       VARCHAR2,
   PARAMETER_1   IN       ASA_RECORD_EVENTS.ASA_RECORD_EVENTS_ID%TYPE,
   PARAMETER_2   IN       ASA_RECORD_TASK.RET_OPTIONAL%TYPE,
   PARAMETER_3   IN       VARCHAR2,
   PARAMETER_4   IN       NUMBER
)
IS
/*
* description used for report ASA_RECORD_FORM3_II

* @created VHA 05.09.2011
* @public
* @public
* @param parameter_0: asa_record.asa_record_id
* @param parameter_1: asa_record_events.asa_record_events_id
* @param parameter_2: ret_optional
* @param parameter_3: a_datecre of last offer
* @param parameter_4: boolean 0  date is smaller or equal, 1 - date is bigger or equal
*/
   OPTIONAL   VARCHAR2 (10);
BEGIN
   CASE PARAMETER_2
      WHEN 0
      THEN
         OPTIONAL := '0';
      WHEN 1
      THEN
         OPTIONAL := '1';
      WHEN 2
      THEN
         OPTIONAL := '0,1';
      ELSE NULL;
   END CASE;

   OPEN AREFCURSOR FOR
      SELECT RET.ASA_RECORD_TASK_ID,
             RET.ASA_RECORD_ID, RET.GCO_BILL_GOOD_ID,
             RET.RET_POSITION,
             RET.RET_OPTIONAL,
             RET.RET_FINISHED,
             RET.RET_TIME,
             RET.RET_DESCR,
             RET.RET_SALE_AMOUNT,
             RET.RET_SALE_AMOUNT * RET.RET_TIME RET_TOTAL_AMOUNT,
             RET.RET_DESCR2,
             RET.A_DATECRE,
             RET.C_ASA_ACCEPT_OPTION,
             RET.DIC_ASA_OPTION_ID,
             GOO.GOO_MAJOR_REFERENCE
        FROM ASA_RECORD_TASK RET,
             GCO_GOOD GOO
       WHERE RET.GCO_BILL_GOOD_ID = GOO.GCO_GOOD_ID(+)
         AND RET.ASA_RECORD_ID = TO_NUMBER (PARAMETER_0)
         AND RET.ASA_RECORD_EVENTS_ID = PARAMETER_1
         AND INSTR (OPTIONAL, TO_CHAR (RET.RET_OPTIONAL)) > 0
         AND ((PARAMETER_4 = '0'
                  AND (RET.A_DATECRE) <=(TO_DATE (PARAMETER_3, 'YYYYMMDD  HH24:MI:SS'))
              )
              OR (PARAMETER_4 = '1'
                  AND (RET.A_DATECRE) >(TO_DATE (PARAMETER_3, 'YYYYMMDD  HH24:MI:SS'))
                 )
             );
END RPT_ASA_RECORD_FORM3_II_TAS;
