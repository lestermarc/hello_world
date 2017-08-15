--------------------------------------------------------
--  DDL for Procedure RPT_ASA_RECORD_FORM3_II_COMP
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ASA_RECORD_FORM3_II_COMP" (
   AREFCURSOR    IN OUT   CRYSTAL_CURSOR_TYPES.DUALCURSORTYP,
   PARAMETER_0   IN       VARCHAR2,
   PARAMETER_1   IN       ASA_RECORD_COMP.ASA_RECORD_EVENTS_ID%TYPE,
   PARAMETER_2   IN       ASA_RECORD_COMP.ARC_OPTIONAL%TYPE,
   PARAMETER_3   IN       VARCHAR2,
   PARAMETER_4   IN       NUMBER
)
IS
/*
* description used for report ASA_RECORD_FORM3_II

* @created VHA 05.09.2011
* @public
* @param parameter_0: asa_record.asa_record_id
* @param parameter_1: asa_record_events.asa_record_events_id
* @param parameter_2: arc_optional
* @param parameter_3: a_datecre of last offer
* @param parameter_4: boolean 0  date is smaller or equal, 1 - date is bigger or equal
*/

   OPTIONAL   VARCHAR2 (10);

BEGIN
   CASE PARAMETER_2
      WHEN '0'
      THEN
         OPTIONAL := '0';
      WHEN '1'
      THEN
         OPTIONAL := '1';
      WHEN '2'
      THEN
         OPTIONAL := '0,1';
      ELSE NULL;
   END CASE;

   OPEN AREFCURSOR FOR
      SELECT ARC.ASA_RECORD_COMP_ID,
             ARC.ASA_RECORD_ID,
             ARC.ARC_POSITION,
             ARC.GCO_COMPONENT_ID,
             ARC.ARC_SALE_PRICE,
             ARC.ARC_QUANTITY,
             ARC.ARC_SALE_PRICE * ARC.ARC_QUANTITY ARC_TOTAL_PRICE,
             ARC.STM_COMP_LOCATION_ID,
             ARC.A_DATECRE,
             ARC.ARC_OPTIONAL,
             ARC.ASA_RECORD_EVENTS_ID,
             ARC.ARC_DESCR, ARC.ARC_DESCR2,
             ARC.STM_COMP_STOCK_MVT_ID,
             ARC.C_ASA_ACCEPT_OPTION,
             ARC.DIC_ASA_OPTION_ID,
             GOO.GOO_MAJOR_REFERENCE,
             GOO.DIC_GOOD_FAMILY_ID,
             GOO.GOO_NUMBER_OF_DECIMAL,
             CAT.DIC_CATEGORY_FREE_1_ID
      FROM   ASA_RECORD_COMP ARC,
             GCO_GOOD GOO,
             GCO_GOOD_CATEGORY CAT
      WHERE  ARC.GCO_COMPONENT_ID = GOO.GCO_GOOD_ID
        AND  GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID(+)
        AND  ARC.ASA_RECORD_ID = TO_NUMBER (PARAMETER_0)
        AND  ARC.ASA_RECORD_EVENTS_ID = PARAMETER_1
        AND  INSTR (OPTIONAL, TO_CHAR (ARC.ARC_OPTIONAL)) > 0
        AND  ((PARAMETER_4 = '0'
              AND (ARC.A_DATECRE) <=(TO_DATE (PARAMETER_3, 'YYYYMMDD HH24:MI:SS')))
              OR ( PARAMETER_4 = '1'
                  AND (ARC.A_DATECRE) > (TO_DATE (PARAMETER_3, 'YYYYMMDD HH24:MI:SS'))
                 )
             );
END RPT_ASA_RECORD_FORM3_II_COMP;
