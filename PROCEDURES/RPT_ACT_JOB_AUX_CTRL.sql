--------------------------------------------------------
--  DDL for Procedure RPT_ACT_JOB_AUX_CTRL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_JOB_AUX_CTRL" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_00     IN       NUMBER,
   parameter_01     IN       NUMBER,
   parameter_02     IN       VARCHAR2,
   parameter_03     IN       VARCHAR2,
   parameter_04     IN       NUMBER,
   parameter_05     IN       NUMBER,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
/**
*Description - used in report ACT_JOB_BATCH
* @author JLIU 18 Nov 2008
* @lastupdate 12 Feb 20009
* @public
* @PARAM PARAMETER_0: ACT_JOB_ID
* @PARAM PARAMETER_1: ACJ_JOB_TYPE_ID
* @PARAM PARAMETER_2: Job description from
* @PARAM PARAMETER_3: Job description to
* @PARAM PARAMETER_4: ACS_FINANCIAL_YEAR_ID
* @PARAM PARAMETER_5: PC_USER_ID
*/
IS
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT acj_functions.translatecatdescr
                              (cat.acj_catalogue_document_id,
                               vpc_lang_id
                              ) cat_description,
             typ.acj_job_type_id, acc.acs_account_id, acc.acc_number,
             acc_aux.acs_account_id aux_account_id,
             acc_aux.acc_number aux_acc_number,
             acc_div.acs_account_id div_account_id,
             acc_div.acc_number div_acc_number, div.acs_division_account_id,
             fcc.acs_financial_account_id, fcc.fin_collective,
             atd.act_document_id, atd.doc_number, imp.imf_amount_lc_d,
             imp.imf_amount_lc_c, imp.imf_amount_fc_d, imp.imf_amount_fc_c,
             imp.imf_transaction_date, job.act_job_id, job.job_description,
             job.acj_job_type_id, job.acs_financial_year_id,
             par.par_document, par.doc_date_delivery,
             cus.per_short_name cus_short_name,
             cus.pac_person_id cus_person_id, cus.per_name cus_name,
             sup.per_short_name sup_short_name,
             sup.pac_person_id sup_person_id, sup.per_name sup_name,
             cur_me.currency currency_me, cur_mb.currency currency_mb,
             des_div.des_description_summary div_description_summary,
             des_fin.des_description_summary fin_description_summary,
             acs_function.getlocalcurrencyname c_monnaie_mb
        FROM act_job job,
             act_document atd,
             act_financial_imputation imp,
             act_financial_distribution dis,
             acs_financial_account fcc,
             acs_division_account div,
             acs_account acc,
             acs_account acc_div,
             acs_account acc_aux,
             act_part_imputation par,
             acs_financial_currency fcr_me,
             acs_financial_currency fcr_mb,
             pcs.pc_curr cur_me,
             pcs.pc_curr cur_mb,
             pac_person cus,
             pac_person sup,
             acj_catalogue_document cat,
             acj_job_type typ,
             acs_description des_fin,
             acs_description des_div
       WHERE job.act_job_id = atd.act_job_id(+)
         AND atd.act_document_id = imp.act_document_id(+)
         AND imp.act_financial_imputation_id = dis.act_financial_imputation_id(+)
         AND dis.acs_division_account_id = div.acs_division_account_id(+)
         AND dis.acs_division_account_id = acc_div.acs_account_id(+)
         AND imp.acs_financial_account_id = fcc.acs_financial_account_id(+)
         AND imp.acs_financial_account_id = acc.acs_account_id(+)
         AND imp.acs_auxiliary_account_id = acc_aux.acs_account_id(+)
         AND imp.acs_financial_currency_id = fcr_me.acs_financial_currency_id(+)
         AND imp.acs_acs_financial_currency_id = fcr_mb.acs_financial_currency_id(+)
         AND fcr_me.pc_curr_id = cur_me.pc_curr_id(+)
         AND fcr_mb.pc_curr_id = cur_mb.pc_curr_id(+)
         AND atd.act_document_id = par.act_document_id(+)
         AND par.pac_custom_partner_id = cus.pac_person_id(+)
         AND par.pac_supplier_partner_id = sup.pac_person_id(+)
         AND atd.acj_catalogue_document_id = cat.acj_catalogue_document_id(+)
         AND job.acj_job_type_id = typ.acj_job_type_id(+)
         AND fcc.acs_financial_account_id = des_fin.acs_account_id(+)
         AND des_fin.pc_lang_id(+) = vpc_lang_id
         AND div.acs_division_account_id = des_div.acs_account_id(+)
         AND des_div.pc_lang_id(+) = vpc_lang_id
         AND job.acs_financial_year_id = parameter_04
         AND act_functions.isuserautorizedforjobtype (parameter_05,
                                                      job.acj_job_type_id
                                                     ) = 1
         AND (   (    (parameter_02 <> parameter_03)
                  AND (parameter_02 IS NOT NULL AND parameter_03 IS NOT NULL
                      )
                  AND (    job.job_description >= parameter_02
                       AND job.job_description <= parameter_03
                      )
                 )
              OR (    (parameter_02 <> parameter_03)
                  AND (parameter_02 IS NOT NULL AND parameter_03 IS NULL)
                  AND (job.job_description >= parameter_02)
                 )
              OR (    (parameter_02 <> parameter_03)
                  AND (parameter_02 IS NULL AND parameter_03 IS NOT NULL)
                  AND (job.job_description <= parameter_03)
                 )
              OR (    (parameter_02 = parameter_03
                       AND parameter_02 IS NOT NULL
                      )
                  AND (job.job_description = parameter_02)
                 )
              OR (    parameter_02 IS NULL
                  AND parameter_03 IS NULL
                  AND job.act_job_id = parameter_00
                 )
             );
END rpt_act_job_aux_ctrl;
