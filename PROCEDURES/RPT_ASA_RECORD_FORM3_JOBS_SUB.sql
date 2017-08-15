--------------------------------------------------------
--  DDL for Procedure RPT_ASA_RECORD_FORM3_JOBS_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ASA_RECORD_FORM3_JOBS_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       VARCHAR2,
   parameter_1   IN       asa_record_events.c_asa_rep_status%TYPE,
   parameter_2   IN       asa_record_task.c_asa_accept_option%TYPE
)
IS
/*
* description used for report asa_report_form3

* @created pna 09.05.2007 proconcept china
* @lastupdate mzhu 19 feb 2009
* @public
* @param parameter_0: asa_record.asa_record_id
* @param parameter_1: repair file status
* @param parameter_2: c_asa_accept_option
*/
BEGIN
   OPEN arefcursor FOR
      SELECT ret.asa_record_task_id, ret.asa_record_id, rre.c_asa_rep_status,
             ret.c_asa_accept_option, ret.gco_bill_good_id, ret.ret_position,
             ret.ret_optional, ret.ret_finished, ret.ret_time,
             ret.ret_time_used, ret.ret_descr, ret.ret_sale_amount,
             ret.ret_sale_amount * ret.ret_time ret_total_amount,
             ret.ret_descr2, ret.a_datecre, goo.goo_major_reference
        FROM asa_record_task ret, asa_record_events rre, gco_good goo
       WHERE ret.asa_record_events_id = rre.asa_record_events_id
         AND ret.gco_bill_good_id = goo.gco_good_id(+)
         AND rre.asa_record_id = TO_NUMBER(parameter_0)
         AND rre.c_asa_rep_status = parameter_1
         AND ret.c_asa_accept_option <> parameter_2;
END rpt_asa_record_form3_jobs_sub;
