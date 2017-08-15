--------------------------------------------------------
--  DDL for Procedure RPT_ACR_BALANCE_3_COL_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACR_BALANCE_3_COL_SUB" (
   arefcursor                       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid                   IN       pcs.pc_lang.lanid%TYPE,
   parameter_1                      IN       NUMBER,
   parameter_4                      IN       NUMBER,
   parameter_5                      IN       NUMBER,
   parameter_8                      IN       NUMBER,
   parameter_9                      IN       NUMBER,
   parameter_12                     IN       NUMBER,
   param_acs_financial_account_id   IN       NUMBER
)
/**
* description used for report ACR_BALANCE_THREE_COL_RPT (Ech??¡§?|anciers fournisseurs)

*@CREATED MZHU 17.09.2007
*@LASTUPDATE
*@PUBLIC
*@param PARAMETER_0:  Classification ID       CLASSIFICATION_ID
*@param PARAMETER_1:  Financial year id       ACS_FINANCIAL_YEAR_ID
*@param PARAMETER_4:  Budget version id       ACB_BUDGET_VERSION_ID
*@param PARAMETER_5:  Financial year id       ACS_FINANCIAL_YEAR_ID
*@param PARAMETER_8:  Budget version id       ACB_BUDGET_VERSION_ID
*@param PARAMETER_9:  Financial year id       ACS_FINANCIAL_YEAR_ID
*@param PARAMETER_12: Budget version id       ACB_BUDGET_VERSION_ID
*/
IS
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;              --USER LANGUAGE ID
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT ver.acb_budget_version_id, pam.per_amount_d, pam.per_amount_c,
             acc.acs_account_id, acs.fin_local_currency, cur.currency,
             per.acs_financial_year_id, per.per_no_period,
             per_bud.per_no_period bud_per_no_period, tot.tot_debit_lc,
             tot.tot_credit_lc, tot.tot_debit_fc, tot.tot_credit_fc,
             tot.acs_auxiliary_account_id, tot.c_type_cumul,
             tot.acs_division_account_id, vac.acc_number
        FROM acb_budget_version ver,
             acb_global_budget glo,
             acb_period_amount pam,
             acs_account acc,
             acs_financial_currency acs,
             acs_period per,
             acs_period per_bud,
             act_total_by_period tot,
             pcs.pc_curr cur,
             (SELECT acc.acs_financial_account_id,
                     tot.acs_division_account_id,
                     tot.act_total_by_period_id ID, 'TOT' typ,
                     per.acs_financial_year_id, 0 acb_budget_version_id
                FROM acs_financial_account acc,
                     act_total_by_period tot,
                     acs_period per
               WHERE acc.acs_financial_account_id =
                                                  tot.acs_financial_account_id
                 AND tot.acs_period_id = per.acs_period_id
                 AND tot.acs_auxiliary_account_id IS NULL
              UNION ALL
              SELECT acc.acs_financial_account_id,
                     glo.acs_division_account_id, amo.acb_period_amount_id ID,
                     'BUD' typ, per.acs_financial_year_id,
                     glo.acb_budget_version_id
                FROM acs_financial_account acc,
                     acb_period_amount amo,
                     acb_global_budget glo,
                     acs_period per,
                     acs_financial_currency cur
               WHERE acc.acs_financial_account_id =
                                                  glo.acs_financial_account_id
                 AND glo.acb_global_budget_id = amo.acb_global_budget_id
                 AND glo.acs_financial_currency_id =
                                                 cur.acs_financial_currency_id
                 AND cur.fin_local_currency = 1
                 AND amo.acs_period_id = per.acs_period_id) vba,
             (SELECT acs_financial_account.acs_financial_account_id,
                     acs_account.acc_number, acs_description.pc_lang_id,
                     acs_description.des_description_summary,
                     acs_function.isfinaccountinme
                        (acs_financial_account.acs_financial_account_id
                        ) isfinaccountinme
                FROM acs_description,
                     acs_account,
                     acs_financial_account,
                     acs_sub_set
               WHERE acs_financial_account.acs_financial_account_id =
                                                    acs_account.acs_account_id
                 AND acs_account.acs_account_id =
                                                acs_description.acs_account_id
                 AND acs_account.acs_sub_set_id = acs_sub_set.acs_sub_set_id
                 AND acs_sub_set.c_sub_set = 'ACC') vac
       WHERE vac.pc_lang_id = vpc_lang_id
         AND vac.acs_financial_account_id = vba.acs_financial_account_id
         AND vba.ID = tot.act_total_by_period_id(+)
         AND tot.acs_period_id = per.acs_period_id(+)
         AND tot.acs_acs_financial_currency_id = acs.acs_financial_currency_id(+)
         AND acs.pc_curr_id = cur.pc_curr_id(+)
         AND vba.acs_division_account_id = acc.acs_account_id(+)
         AND vba.ID = pam.acb_period_amount_id(+)
         AND pam.acb_global_budget_id = glo.acb_global_budget_id(+)
         AND glo.acb_budget_version_id = ver.acb_budget_version_id(+)
         AND pam.acs_period_id = per_bud.acs_period_id(+)
         AND vac.acs_financial_account_id = param_acs_financial_account_id
         AND vba.acs_financial_year_id IN
                                      (parameter_1, parameter_5, parameter_9)
         AND vba.acb_budget_version_id IN
                                     (parameter_4, parameter_8, parameter_12);
END rpt_acr_balance_3_col_sub;
