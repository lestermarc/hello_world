--------------------------------------------------------
--  DDL for Procedure RPT_ASA_RECORD_FORM3_TAS_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ASA_RECORD_FORM3_TAS_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       VARCHAR2,
   parameter_1   IN       asa_record_events.asa_record_events_id%TYPE,
   parameter_2   IN       asa_record_task.ret_optional%TYPE,
   parameter_3   IN       VARCHAR2,
   parameter_4   IN       NUMBER
)
IS
/*
* description used for report asa_report_form3

* @created pna 03.09.2007 proconcept china
* @lastupdate VHA 26 JUNE 2013
* @public
* @param parameter_0: asa_record.asa_record_id
* @param parameter_1: asa_record_events.asa_record_events_id
* @param parameter_2: ret_optional
* @param parameter_3: a_datecre of last offer
* @param parameter_4: boolean 0  date is smaller or equal, 1 - date is bigger or equal
*/
   optional   VARCHAR2 (10) := null;
BEGIN
    if (parameter_2 is not null) then
       CASE parameter_2
          WHEN 0
          THEN
             optional := '0';
          WHEN 1
          THEN
             optional := '1';
          WHEN 2
          THEN
             optional := '0,1';
       END CASE;
    end if;

   OPEN arefcursor FOR
      SELECT ret.asa_record_task_id, ret.asa_record_id, ret.gco_bill_good_id,
             ret.ret_position, ret.ret_optional, ret.ret_finished,
             ret.ret_time, ret.ret_descr, ret.ret_sale_amount,
             ret.ret_sale_amount * ret.ret_time ret_total_amount,
             ret.ret_descr2, ret.a_datecre, ret.c_asa_accept_option,
             goo.goo_major_reference
        FROM asa_record_task ret, gco_good goo
       WHERE ret.gco_bill_good_id = goo.gco_good_id(+)
         AND ret.asa_record_id = TO_NUMBER (parameter_0)
         AND ret.asa_record_events_id = parameter_1
         AND INSTR (optional, TO_CHAR (ret.ret_optional)) > 0
         AND (   (    parameter_4 = '0'
                  AND (ret.a_datecre) <=
                              (TO_DATE (parameter_3, 'YYYYMMDD  HH24:MI:SS')
                              )
                 )
              OR (    parameter_4 = '1'
                  AND (ret.a_datecre) >
                              (TO_DATE (parameter_3, 'YYYYMMDD  HH24:MI:SS')
                              )
                 )
             );
END rpt_asa_record_form3_tas_sub;
