--------------------------------------------------------
--  DDL for Procedure RPT_ACT_INTEREST_DETAIL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_INTEREST_DETAIL" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_00     IN       VARCHAR2,
   parameter_01     IN       VARCHAR2,
   parameter_02     IN       VARCHAR2,
   parameter_03     IN       VARCHAR2,
   parameter_04     IN       VARCHAR2,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
IS
/**
*DESCRIPTION
USED FOR REPORT ACT_INTEREST_DETAIL
*author JLI
*lastUpdate 2009-4-7
*public
*@param PARAMETER_00:  JOB ID
*@param PARAMETER_01:  JOB TYPE ID
*@param PARAMETER_02:  JOB DESCRIPTION
*@param PARAMETER_03:  JOB DESCRIPTION
*@param PARAMETER_04:  FINANCIAL YEAR ID
*/

tmp           NUMBER;
vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;

BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT ide.act_interest_detail_id, ide.acs_financial_account_id,
             ide.acs_division_account_id, ide.act_financial_imputation_id,
             ide.act_job_id, ide.ide_value_date,
             NVL (ide.ide_transaction_date,
                  ide_value_date
                 ) ide_transaction_date,
             ide.ide_amount_lc_d, ide.ide_amount_lc_c, ide.ide_amount_fc_d,
             ide.ide_amount_fc_c, ide.ide_balance_amount,
             ide.ide_interest_rate_d, ide.ide_interest_rate_c,
             ide.ide_days_nbr_d, ide.ide_days_nbr_c, ide.ide_nbr_d,
             ide.ide_nbr_c, ide.a_confirm, ide.a_datecre, ide.a_datemod,
             ide.a_idcre, ide.a_idmod, ide.a_reclevel, ide.a_recstatus,
             (SELECT imp.imf_description
                FROM act_financial_imputation imp
               WHERE imp.act_financial_imputation_id =
                              ide.act_financial_imputation_id)
                                                             imf_description,
             (SELECT imp.act_part_imputation_id
                FROM act_financial_imputation imp
               WHERE imp.act_financial_imputation_id =
                        ide.act_financial_imputation_id)
                                                      act_part_imputation_id,
             NVL
                ((SELECT dis.act_financial_distribution_id
                    FROM act_financial_distribution dis
                   WHERE dis.act_financial_imputation_id =
                                               ide.act_financial_imputation_id),
                 0
                ) act_financial_distribution_id,
             NVL
                ((SELECT doc.doc_number
                    FROM act_document doc
                   WHERE doc.act_document_id =
                            (SELECT imp.act_document_id
                               FROM act_financial_imputation imp
                              WHERE imp.act_financial_imputation_id =
                                               ide.act_financial_imputation_id)),
                 ' '
                ) doc_number,
             NVL ((SELECT cur.currency
                     FROM pcs.pc_curr cur, acs_financial_currency afc
                    WHERE ide.acs_financial_currency_id =
                                                 afc.acs_financial_currency_id
                      AND afc.pc_curr_id = cur.pc_curr_id),
                  (SELECT cur.currency
                     FROM pcs.pc_curr cur, acs_financial_currency afc
                    WHERE afc.pc_curr_id = cur.pc_curr_id
                      AND afc.fin_local_currency = 1)
                 ) currency,
             (SELECT cur.currency
                     FROM pcs.pc_curr cur, acs_financial_currency afc
                    WHERE afc.pc_curr_id = cur.pc_curr_id
                      AND afc.fin_local_currency = 1) local_cur,
             0 tri,
             (SELECT des.des_description_summary
                FROM acs_description des
               WHERE des.acs_account_id = ide.acs_financial_account_id
                 AND des.pc_lang_id = vpc_lang_id) fin_des,
             (SELECT des.des_description_summary
                FROM acs_description des
               WHERE des.acs_account_id = ide.acs_division_account_id
                 AND des.pc_lang_id = vpc_lang_id) div_des,
             ACS_FUNCTION.GetAccountNumber(ide.acs_division_account_id) div_acc,
             ACS_FUNCTION.GetAccountNumber(ide.acs_financial_account_id) fin_acc
        FROM
        act_interest_detail ide,
        act_job job
        WHERE
        (PARAMETER_00 =0 OR JOB.ACT_JOB_ID = TO_NUMBER(PARAMETER_00))
        AND ide.ACT_JOB_ID = JOB.ACT_JOB_ID
        AND (PARAMETER_01 =0 OR JOB.ACJ_JOB_TYPE_ID = TO_NUMBER(PARAMETER_01))
        AND (PARAMETER_02 IS NULL OR JOB.JOB_DESCRIPTION >= PARAMETER_02)
        AND (PARAMETER_03 IS NULL OR JOB.JOB_DESCRIPTION <= PARAMETER_03)
        AND (PARAMETER_04 =0 OR JOB.ACS_FINANCIAL_YEAR_ID = TO_NUMBER(PARAMETER_04))
      UNION ALL
      SELECT imf.act_financial_imputation_id act_interest_detail_id,
             imf.acs_financial_account_id acs_financial_account_id,
             imf.imf_acs_division_account_id acs_division_account_id,
             imf.act_financial_imputation_id act_financial_imputation_id,
             doc.act_job_id act_job_id, imf.imf_value_date ide_value_date,
             imf.imf_transaction_date ide_transaction_date,
             imf.imf_amount_lc_d ide_amount_lc_d,
             imf.imf_amount_lc_c ide_amount_lc_c,
             imf.imf_amount_fc_d ide_amount_fc_d,
             imf.imf_amount_fc_c ide_amount_fc_c, 0 ide_balance_amount,
             0 ide_interest_rate_d, 0 ide_interest_rate_d, 0 ide_days_nbr_d,
             0 ide_days_nbr_c, 0 ide_nbr_d, 0 ide_nbr_c, imf.a_confirm,
             imf.a_datecre, imf.a_datemod, imf.a_idcre, imf.a_idmod,
             imf.a_reclevel, imf.a_recstatus, imf.imf_description,
             imf.act_part_imputation_id,
             NVL
                ((SELECT dis.act_financial_distribution_id
                    FROM act_financial_distribution dis
                   WHERE dis.act_financial_imputation_id =
                                               imf.act_financial_imputation_id),
                 0
                ) act_financial_distribution_id,
             NVL (doc.doc_number, ' ') doc_number,
             NVL ((SELECT cur.currency
                     FROM pcs.pc_curr cur, acs_financial_currency afc
                    WHERE imf.acs_financial_currency_id =
                                                 afc.acs_financial_currency_id
                      AND afc.pc_curr_id = cur.pc_curr_id),
                  ' '
                 ) currency,
             (SELECT cur.currency
                     FROM pcs.pc_curr cur, acs_financial_currency afc
                    WHERE afc.pc_curr_id = cur.pc_curr_id
                      AND afc.fin_local_currency = 1) local_cur,
             1 tri,
             (SELECT des.des_description_summary
                FROM acs_description des
               WHERE des.acs_account_id = imf.acs_financial_account_id
                 AND des.pc_lang_id = vpc_lang_id) fin_des,
             (SELECT des.des_description_summary
                FROM acs_description des
               WHERE des.acs_account_id = imf.imf_acs_division_account_id
                 AND des.pc_lang_id = vpc_lang_id) div_des,
             ACS_FUNCTION.GetAccountNumber(imf.imf_acs_division_account_id) div_acc,
             ACS_FUNCTION.GetAccountNumber(imf.acs_financial_account_id) fin_acc
        FROM
             act_financial_imputation imf,
             act_document doc,
             act_job job
       WHERE doc.act_document_id = imf.act_document_id(+)
         AND EXISTS (
                SELECT 1
                  FROM act_etat_event eve
                 WHERE eve.c_type_event = '9'
                   AND eve.act_job_id = doc.act_job_id)
         AND doc.ACT_JOB_ID = job.ACT_JOB_ID
         AND (PARAMETER_00 =0 OR JOB.ACT_JOB_ID = TO_NUMBER(PARAMETER_00))
         AND (PARAMETER_01 =0 OR JOB.ACJ_JOB_TYPE_ID = TO_NUMBER(PARAMETER_01))
         AND (PARAMETER_02 IS NULL OR JOB.JOB_DESCRIPTION >= PARAMETER_02)
         AND (PARAMETER_03 IS NULL OR JOB.JOB_DESCRIPTION <= PARAMETER_03)
         AND (PARAMETER_04 =0 OR JOB.ACS_FINANCIAL_YEAR_ID = TO_NUMBER(PARAMETER_04))
;
END rpt_act_interest_detail;
