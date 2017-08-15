--------------------------------------------------------
--  DDL for Procedure RPT_ACR_BALANCE_CPN
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACR_BALANCE_CPN" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_00     IN       VARCHAR2,
   parameter_01     IN       VARCHAR2,
   parameter_04     IN       VARCHAR2,
   parameter_10     IN       VARCHAR2,
   parameter_13     IN       VARCHAR2,
   parameter_19     IN       VARCHAR2,
   parameter_22     IN       VARCHAR2,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
/**
* description used for report ACR_BALANCE_CPN

*@CREATED EQI 08.08.2009
*@LASTUPDATE MZHU   03.09.2009
*@PUBLIC
*@param PARAMETER_00:   ID Classification
*@param PARAMETER_01:   ID Financial year
*@param PARAMETER_04:   ID Version budget
*@param PARAMETER_10:   ID Financial year Comp1
*@param PARAMETER_13:   ID Version budget Comp1
*@param PARAMETER_19:   ID Financial year Comp2
*@param PARAMETER_22:   ID Version budget Comp2
*/
IS
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT classif_flat.node01, v_acs_account_classif.classification_id,
             classif_flat.node02, classif_flat.node03, classif_flat.node04,
             classif_flat.node05, classif_flat.node06, classif_flat.node07,
             classif_flat.node08, classif_flat.node09, classif_flat.node10,
             acs_account_cpn.acc_number, acs_account_cpn.acs_account_id,
             classif_flat.leaf_descr,
             acs_period_tot.acs_financial_year_id acs_financial_year_id1,
             acs_period_tot.per_no_period per_no_period1,
             act_mgm_tot_by_period.mto_debit_lc,
             act_mgm_tot_by_period.mto_credit_lc,
             v_acr_balance_cpn.acs_financial_year_id acs_financial_year_id2,
             act_mgm_tot_by_period.c_type_cumul,
             acb_budget_version.acb_budget_version_id acb_budget_version_id1,
             acs_period_bud.per_no_period per_no_period2,
             acb_period_amount.per_amount_d, acb_period_amount.per_amount_c,
             v_acr_balance_cpn.acb_budget_version_id acb_budget_version_id2,
             classif_flat.pc_lang_id,
             acs_function.getlocalcurrencyname localcurrencyname
        FROM v_acr_balance_cpn,
             acb_period_amount,
             classif_flat,
             acs_account acs_account_cpn,
             act_mgm_tot_by_period,
             acs_period acs_period_tot,
             acb_global_budget,
             acs_period acs_period_bud,
             acb_budget_version,
             v_acs_account_classif
       WHERE v_acr_balance_cpn.ID = acb_period_amount.acb_period_amount_id(+)
         AND v_acr_balance_cpn.acs_cpn_account_id =
                                                  classif_flat.classif_leaf_id
         AND v_acr_balance_cpn.acs_cpn_account_id =
                                                acs_account_cpn.acs_account_id
         AND v_acr_balance_cpn.ID = act_mgm_tot_by_period.act_mgm_tot_by_period_id(+)
         AND act_mgm_tot_by_period.acs_period_id = acs_period_tot.acs_period_id(+)
         AND classif_flat.classification_id =
                                       v_acs_account_classif.classification_id
         AND acb_period_amount.acb_global_budget_id = acb_global_budget.acb_global_budget_id(+)
         AND acb_period_amount.acs_period_id = acs_period_bud.acs_period_id(+)
         AND acb_global_budget.acb_budget_version_id = acb_budget_version.acb_budget_version_id(+)
         AND classif_flat.pc_lang_id = vpc_lang_id
         AND v_acs_account_classif.classification_id = parameter_00
         AND (   v_acr_balance_cpn.acs_financial_year_id = parameter_01
              OR v_acr_balance_cpn.acs_financial_year_id = parameter_10
              OR v_acr_balance_cpn.acs_financial_year_id = parameter_19
             )
         AND (   v_acr_balance_cpn.acb_budget_version_id = parameter_04
              OR v_acr_balance_cpn.acb_budget_version_id = parameter_13
              OR v_acr_balance_cpn.acb_budget_version_id = parameter_22
             );
END rpt_acr_balance_cpn;
