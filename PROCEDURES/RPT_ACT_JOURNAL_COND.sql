--------------------------------------------------------
--  DDL for Procedure RPT_ACT_JOURNAL_COND
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_JOURNAL_COND" (
   arefcursor               IN OUT   crystal_cursor_types.dualcursortyp,
   ajou_number_from         IN       VARCHAR2,
   ajou_number_to           IN       VARCHAR2,
   aacs_financial_year_id   IN       VARCHAR2,
   procuser_lanid           IN       pcs.pc_lang.lanid%TYPE
)
/**
* description used for report act_journal_cond

* @author jliu 18 nov 2008
* @lastupdate 12 Feb 2009
* @public
*/
IS
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   IF     (ajou_number_from IS NOT NULL)
      AND (LENGTH (TRIM (ajou_number_from)) > 0)
   THEN
      acr_functions.jou_number1 := ajou_number_from;
   ELSE
      acr_functions.jou_number1 := ' ';
   END IF;

   IF (ajou_number_to IS NOT NULL) AND (LENGTH (TRIM (ajou_number_to)) > 0)
   THEN
      acr_functions.jou_number2 := ajou_number_to;
   END IF;

   IF     (aacs_financial_year_id IS NOT NULL)
      AND (LENGTH (TRIM (aacs_financial_year_id)) > 0)
   THEN
      acr_functions.fin_year_id := aacs_financial_year_id;
   END IF;

   OPEN arefcursor FOR
      SELECT acj_functions.translatecatdescr
                              (cat.acj_catalogue_document_id,
                               vpc_lang_id
                              ) cat_description,
             acj_functions.translatetypdescr
                                        (typ.acj_job_type_id,
                                         vpc_lang_id
                                        ) typ_description,
             yea.fye_no_exercice, prd.per_no_period, eta.c_etat_journal,
             eta.c_sub_set, job.job_description, jou.act_journal_id,
             jou.a_idmod, jou.a_idcre, jou.a_datemod, jou.a_datecre,
             jou.jou_number, jou.jou_description, des.des_description_summary,
             cur_mb.currency currency_mb, cur_me.currency currency_me,
             v_jou.act_journal_id, v_jou.imf_transaction_date,
             v_jou.acs_financial_account_id, v_jou.acs_division_account_id,
             v_jou.imf_amount_lc_d_sum, v_jou.imf_amount_lc_c_sum,
             v_jou.imf_amount_fc_d_sum, v_jou.imf_amount_fc_c_sum,
             v_jou.imf_amount_eur_d_sum, v_jou.imf_amount_eur_c_sum,
             acs_function.getaccountnumber
                                (v_jou.acs_division_account_id)
                                                               div_acc_number,
             acs_function.getaccountnumber
                                   (v_jou.acs_financial_account_id)
                                                                   acc_number,
             acs_function.getaccountnumber
                                        (v_jou.acs_tax_code_id)
                                                               tax_acc_number
        FROM v_act_journal_cond v_jou,
             act_journal jou,
             act_job job,
             acs_financial_year yea,
             acj_job_type typ,
             act_etat_journal eta,
             acs_financial_currency fur_mb,
             acs_financial_currency fur_me,
             pcs.pc_curr cur_mb,
             pcs.pc_curr cur_me,
             acj_catalogue_document cat,
             acs_period prd,
             acs_description des
       WHERE v_jou.act_journal_id = jou.act_journal_id
         AND jou.act_job_id = job.act_job_id
         AND jou.acs_financial_year_id = yea.acs_financial_year_id
         AND job.acj_job_type_id = typ.acj_job_type_id
         AND v_jou.act_journal_id = eta.act_journal_id
         AND v_jou.acs_acs_financial_currency_id =
                                              fur_mb.acs_financial_currency_id
         AND fur_mb.pc_curr_id = cur_mb.pc_curr_id
         AND v_jou.acs_financial_currency_id =
                                              fur_me.acs_financial_currency_id
         AND fur_me.pc_curr_id = cur_me.pc_curr_id
         AND v_jou.acj_catalogue_document_id = cat.acj_catalogue_document_id
         AND v_jou.acs_period_id = prd.acs_period_id
         AND eta.c_sub_set = 'ACC'
         AND v_jou.acs_financial_account_id = des.acs_account_id
         AND des.pc_lang_id = vpc_lang_id;
END rpt_act_journal_cond;
