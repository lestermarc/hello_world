--------------------------------------------------------
--  DDL for Procedure RPT_ACT_JOURNAL_OPT_TYP
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_JOURNAL_OPT_TYP" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   afrom            IN       VARCHAR2,
   ato              IN       VARCHAR2,
   parameter_1      IN       VARCHAR2,
   parameter_2      IN       VARCHAR2,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
/**
* description used for report ACT_JOURNAL_OPERATION_TYP

* @author jliu 18 nov 2008
* @lastupdate 12 Feb 2009
* @public
* @PARAM PARAMETER_0    ACS_FINANCIAL_YEAR_ID
* @PARAM PARAMETER_1    journal from (Nr)
* @PARAM PARAMETER_2    journal to(Nr)
*/
IS
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   IF (afrom IS NOT NULL) AND (LENGTH (TRIM (afrom)) > 0)
   THEN
      act_functions.date_from := TO_DATE (afrom, 'yyyymmdd');
   END IF;

   IF (ato IS NOT NULL) AND (LENGTH (TRIM (ato)) > 0)
   THEN
      act_functions.date_to := TO_DATE (ato, 'yyyymmdd');
   END IF;

   OPEN arefcursor FOR
      SELECT NVL(cat.dic_operation_typ_id,pcs.pc_functions.translateword2 ('Pas d opération', vpc_lang_id)) dic_operation_typ_id,
             tax_acc.acc_number tax_acc_number,
             aux_acc.acc_number aux_acc_number,
             div_acc.acc_number div_acc_number,
             fin_acc.acc_number fin_acc_number, des.des_description_summary,
             atd.act_document_id, atd.doc_number, atd.doc_document_date,
             par.act_part_imputation_id, par.par_document,
             cur_me.pc_curr_id pc_curr_id_me, cur_me.currency currency_me,
             cur_mb.pc_curr_id pc_curr_id_mb, cur_mb.currency currency_mb,
             v_imp.act_financial_imputation_id, v_imp.act_document_id,
             v_imp.imf_primary, v_imp.imf_description, v_imp.imf_amount_lc_d,
             v_imp.imf_amount_lc_c, v_imp.imf_exchange_rate,
             v_imp.imf_amount_fc_d, v_imp.imf_amount_fc_c,
             v_imp.imf_value_date, v_imp.imf_transaction_date,
             v_jou.jou_number, v_jou.acs_financial_year_id
        FROM acj_catalogue_document cat,
             acj_job_type typ,
             acs_account tax_acc,
             acs_account aux_acc,
             acs_account div_acc,
             acs_account fin_acc,
             acs_description des,
             acs_financial_currency fur_mb,
             acs_financial_currency fur_me,
             acs_financial_year yea,
             act_document atd,
             act_financial_distribution dis,
             act_job job,
             act_part_imputation par,
             pcs.pc_curr cur_mb,
             pcs.pc_curr cur_me,
             pcs.pc_user usr,
             v_act_fin_imputation_date v_imp,
             v_act_journal v_jou
       WHERE v_imp.act_financial_imputation_id = dis.act_financial_imputation_id(+)
         AND dis.acs_division_account_id = div_acc.acs_account_id(+)
         AND v_imp.act_document_id = atd.act_document_id
         AND atd.act_job_id = job.act_job_id
         AND job.acj_job_type_id = typ.acj_job_type_id
         AND atd.acj_catalogue_document_id = cat.acj_catalogue_document_id
         AND atd.act_journal_id = v_jou.act_journal_id
         AND v_jou.pc_user_id = usr.pc_user_id(+)
         AND v_jou.acs_financial_year_id = yea.acs_financial_year_id
         AND v_imp.acs_financial_account_id = fin_acc.acs_account_id
         AND v_imp.acs_tax_code_id = tax_acc.acs_account_id(+)
         AND v_imp.acs_financial_currency_id = fur_me.acs_financial_currency_id(+)
         AND fur_me.pc_curr_id = cur_me.pc_curr_id(+)
         AND v_imp.acs_auxiliary_account_id = aux_acc.acs_account_id(+)
         AND aux_acc.acs_account_id = des.acs_account_id(+)
         AND v_imp.acs_acs_financial_currency_id = fur_mb.acs_financial_currency_id(+)
         AND fur_mb.pc_curr_id = cur_mb.pc_curr_id(+)
         AND v_imp.act_part_imputation_id = par.act_part_imputation_id(+)
         AND (des.pc_lang_id IS NULL OR des.pc_lang_id = vpc_lang_id)
         AND v_jou.c_sub_set = 'ACC'
         AND (       (parameter_1 <> parameter_2)
                 AND (parameter_1 IS NOT NULL AND parameter_2 IS NOT NULL)
                 AND (    cat.dic_operation_typ_id >= parameter_1
                      AND cat.dic_operation_typ_id <= parameter_2
                     )
              OR (    (parameter_1 <> parameter_2)
                  AND (parameter_1 IS NOT NULL AND parameter_2 IS NULL)
                  AND (cat.dic_operation_typ_id >= parameter_1)
                 )
              OR (    (parameter_1 <> parameter_2)
                  AND (parameter_1 IS NULL AND parameter_2 IS NOT NULL)
                  AND (cat.dic_operation_typ_id <= parameter_2)
                 )
              OR (    (    parameter_1 = parameter_2
                       AND parameter_1 IS NOT NULL
                       AND parameter_2 IS NOT NULL
                      )
                  AND (cat.dic_operation_typ_id = parameter_1)
                 )
              OR (parameter_1 IS NULL AND parameter_2 IS NULL)
             );
END rpt_act_journal_opt_typ;
