--------------------------------------------------------
--  DDL for Procedure RPT_ACR_BALANCE_CDA
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACR_BALANCE_CDA" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_00     IN       VARCHAR2,
   parameter_01     IN       VARCHAR2,
   parameter_04     IN       VARCHAR2,
   parameter_10     IN       VARCHAR2,
   parameter_11     IN       VARCHAR2,
   parameter_14     IN       VARCHAR2,
   parameter_20     IN       VARCHAR2,
   parameter_21     IN       VARCHAR2,
   parameter_24     IN       VARCHAR2,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
/**
* description used for report ACR_BALANCE_CPN

*@CREATED EQI 08.08.2009
*@LASTUPDATE EQI   03.09.2009
*@PUBLIC
*@param PARAMETER_00:   ID Classification
*@param PARAMETER_01:   ID Financial year Réf
*@param PARAMETER_04:   ID Version budget REF
*@param PARAMETER_10:   CDA Account from
*@param PARAMETER_11:   ID Financial year Comp1
*@param PARAMETER_14:   ID Version budget Comp1
*@param PARAMETER_20:   CDA Account to
*@param PARAMETER_21:   ID Financial year Comp2
*@param PARAMETER_24:   ID Version budget Comp2
*@param PARAMETER_25:   C_TYPE_CUMUL Comp2 = 'ENG' : 0=No / 1=Yes
*/
IS
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT acb_budget_version.acb_budget_version_id acb_budget_version_id1,
             acb_period_amount.per_amount_d, acb_period_amount.per_amount_c,
             acs_account_cda.acc_number acc_number1,
             acs_account_cpn.acc_number acc_number2,
             acs_description.pc_lang_id,
             acs_description.des_description_summary,
             acs_period_bud.per_no_period per_no_period1,
             acs_period_tot.acs_financial_year_id acs_financial_year_id1,
             acs_period_tot.per_no_period per_no_period2,
             act_mgm_tot_by_period.mto_debit_lc,
             act_mgm_tot_by_period.mto_credit_lc,
             act_mgm_tot_by_period.c_type_cumul, classif_flat.node01,
             classif_flat.node02, classif_flat.node03, classif_flat.node04,
             classif_flat.node05, classif_flat.node06, classif_flat.node07,
             classif_flat.node08, classif_flat.node09, classif_flat.node10,
             classif_flat.leaf_descr, pc_lang.lanid,
             v_acr_balance_cda.acs_financial_year_id acs_financial_year_id2,
             v_acr_balance_cda.acb_budget_version_id acb_budget_version_id2,
             v_acs_account_classif.classification_id,
             acs_function.getlocalcurrencyname localcurrencyname
        FROM v_acr_balance_cda,
             classif_flat,
             acs_account acs_account_cpn,
             acs_account acs_account_cda,
             act_mgm_tot_by_period,
             acs_period acs_period_tot,
             acb_period_amount,
             acs_period acs_period_bud,
             acb_global_budget,
             acb_budget_version,
             acs_description,
             pcs.pc_lang pc_lang,
             v_acs_account_classif
       WHERE v_acr_balance_cda.acs_cpn_account_id =
                                                  classif_flat.classif_leaf_id
         AND v_acr_balance_cda.acs_cpn_account_id =
                                                acs_account_cpn.acs_account_id
         AND v_acr_balance_cda.acs_cda_account_id =
                                                acs_account_cda.acs_account_id
         AND v_acr_balance_cda.ID = act_mgm_tot_by_period.act_mgm_tot_by_period_id(+)
         AND act_mgm_tot_by_period.acs_period_id = acs_period_tot.acs_period_id(+)
         AND v_acr_balance_cda.ID = acb_period_amount.acb_period_amount_id(+)
         AND acb_period_amount.acs_period_id = acs_period_bud.acs_period_id(+)
         AND acb_period_amount.acb_global_budget_id = acb_global_budget.acb_global_budget_id(+)
         AND acb_global_budget.acb_budget_version_id = acb_budget_version.acb_budget_version_id(+)
         AND v_acr_balance_cda.acs_cda_account_id =
                                                acs_description.acs_account_id
         AND pc_lang.lanid = procuser_lanid
         AND acs_description.pc_lang_id = vpc_lang_id
         AND classif_flat.classification_id =
                                       v_acs_account_classif.classification_id
         AND classif_flat.pc_lang_id = pc_lang.pc_lang_id
         AND v_acs_account_classif.classification_id = parameter_00
         AND acs_account_cda.acc_number >= parameter_10
         AND acs_account_cda.acc_number <= parameter_20
         AND (   v_acr_balance_cda.acs_financial_year_id = parameter_01
              OR v_acr_balance_cda.acs_financial_year_id = parameter_11
              OR v_acr_balance_cda.acs_financial_year_id = parameter_21
             )
         AND (   v_acr_balance_cda.acb_budget_version_id = parameter_04
              OR v_acr_balance_cda.acb_budget_version_id = parameter_14
              OR v_acr_balance_cda.acb_budget_version_id = parameter_24
             );
END rpt_acr_balance_cda;
