--------------------------------------------------------
--  DDL for Procedure RPT_ACS_REMINDER_FILTER_DET
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACS_REMINDER_FILTER_DET" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
/**
*Description  Used for report ACS_AUX_REMINDER_FILTER_DET
*
*@created AWU 18 MAY 2009
*@lastUpdate
*@public
*@param
*/
IS
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;              --user language id
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT acc.acs_sub_set_id, fil.acs_auxiliary_account_id,
             fil.c_reminder_filter, job.job_aci_control_date, acc.acc_number,
             (SELECT des_a.des_description_summary
                FROM acs_description des_a
               WHERE des_a.acs_account_id =
                               acc.acs_account_id
                 AND des_a.pc_lang_id = vpc_lang_id)
                                                 des_description_summary_acc,
             (SELECT des_a.des_description_large
                FROM acs_description des_a
               WHERE des_a.acs_account_id =
                                 acc.acs_account_id
                 AND des_a.pc_lang_id = vpc_lang_id)
                                                   des_description_large_acc,
             (SELECT des_s.des_description_summary
                FROM acs_description des_s
               WHERE des_s.acs_sub_set_id =
                               acc.acs_sub_set_id
                 AND des_s.pc_lang_id = vpc_lang_id)
                                                 des_description_summary_sub
        FROM act_aux_account_filter fil, acs_account acc, act_job job
       WHERE fil.acs_auxiliary_account_id = acc.acs_account_id
         AND fil.act_job_id = job.act_job_id;
END rpt_acs_reminder_filter_det;
