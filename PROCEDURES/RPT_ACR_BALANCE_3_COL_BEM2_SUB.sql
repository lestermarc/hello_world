--------------------------------------------------------
--  DDL for Procedure RPT_ACR_BALANCE_3_COL_BEM2_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACR_BALANCE_3_COL_BEM2_SUB" (
  arefcursor     in out crystal_cursor_types.dualcursortyp
, procuser_lanid in     pcs.pc_lang.lanid%type
, parameter_0    in     varchar2
, parameter_1    in     number
, parameter_4    in     number
, parameter_5    in     number
, parameter_8    in     number
, parameter_9    in     number
, parameter_12   in     number
, account_from   in     varchar2
, account_to     in     varchar2
)
is
/**
*Description
Used for SUB-report ACR_BALANCE_THREE_COL_BE_MCH2 / ACR_BALANCE_THREE_COL_BE_RECAP_MCH2 / ACR_BUDGET_BE_MCH2.RPT / ACR_BUDGET_RECAP_BE_MCH2
*@ replace procedure ACR_BALANCE_3_COL_BE_SUB_RPT
*@created MZHU 06.06.2007
*@lastUpdate
*                   EHO 31.01.2014 :  création de la procédure sur la base de RPT_ACR_BALANCE_3_COL_BE_SUB, pour gérer les n° de divisions (voir paramètres) sur 4 positions MCH2
*@public
*@param PARAMETER_0:  Classification ID      (CLASSIFICATION_ID)
*@param PARAMETER_1:  Financial year id      (ACS_FINANCIAL_YEAR_ID)
*@param PARAMETER_4:  Budget version id      (ACB_BUDGET_VERSION_ID)
*@param PARAMETER_5:  Financial year id      (ACS_FINANCIAL_YEAR_ID)
*@param PARAMETER_8:  Budget version id      (ACB_BUDGET_VERSION_ID)
*@param PARAMETER_9:  Financial year id      (ACS_FINANCIAL_YEAR_ID)
*@param PARAMETER_12: Budget version id      (ACB_BUDGET_VERSION_ID)
*@param ACCOUNT_FROM: Minimum account number (SUBSTR(LTRIM(CFL.LEAF_DESCR),1,4)
*@param ACCOUNT_TO:   Maximum account number (SUBSTR(LTRIM(CFL.LEAF_DESCR),1,4)
*/
  vpc_lang_id pcs.pc_lang.pc_lang_id%type;   --user language id
begin
  pcs.pc_init_session.setlanid(procuser_lanid);
  vpc_lang_id  := pcs.pc_init_session.getuserlangid;

  open arefcursor for
    select ver.acb_budget_version_id
         , pam.per_amount_d
         , pam.per_amount_c
         , acc.acs_account_id
         , acc.acc_number division_acc_number
         , per.acs_financial_year_id
         , per.per_no_period
         , per_bud.per_no_period bud_per_no_period
         , tot.tot_debit_lc
         , tot.tot_credit_lc
         , tot.acs_auxiliary_account_id
         , tot.c_type_cumul
         , tot.acs_division_account_id
         , cfl.node01
         , cfl.node02
         , cfl.leaf_descr
         , vac.acs_financial_account_id
         , cla.cla_descr
      from acb_budget_version ver
         , acb_global_budget glo
         , acb_period_amount pam
         , acs_account acc
         , acs_period per
         , acs_period per_bud
         , act_total_by_period tot
         , classif_flat cfl
         , classification cla
         , (select acc.acs_financial_account_id
                 , tot.acs_division_account_id
                 , tot.act_total_by_period_id id
                 , 'TOT' typ
                 , per.acs_financial_year_id
                 , 0 acb_budget_version_id
              from acs_financial_account acc
                 , act_total_by_period tot
                 , acs_period per
             where acc.acs_financial_account_id = tot.acs_financial_account_id
               and tot.acs_period_id = per.acs_period_id
               and tot.acs_auxiliary_account_id is null
            union all
            select acc.acs_financial_account_id
                 , glo.acs_division_account_id
                 , amo.acb_period_amount_id id
                 , 'BUD' typ
                 , per.acs_financial_year_id
                 , glo.acb_budget_version_id
              from acs_financial_account acc
                 , acb_period_amount amo
                 , acb_global_budget glo
                 , acs_period per
                 , acs_financial_currency cur
             where acc.acs_financial_account_id = glo.acs_financial_account_id
               and glo.acb_global_budget_id = amo.acb_global_budget_id
               and glo.acs_financial_currency_id = cur.acs_financial_currency_id
               and cur.fin_local_currency = 1
               and amo.acs_period_id = per.acs_period_id) vba
         , (select cla.classification_id
              from classification cla
                 , classif_tables tab
             where cla.classification_id = tab.classification_id
               and tab.cta_tablename = 'ACS_ACCOUNT') vcl
         , (select acs_financial_account.acs_financial_account_id
                 , acs_account.acc_number
                 , acs_description.pc_lang_id
                 , acs_description.des_description_summary
              from acs_description
                 , acs_account
                 , acs_financial_account
                 , acs_sub_set
             where acs_financial_account.acs_financial_account_id = acs_account.acs_account_id
               and acs_account.acs_account_id = acs_description.acs_account_id
               and acs_account.acs_sub_set_id = acs_sub_set.acs_sub_set_id
               and acs_sub_set.c_sub_set = 'ACC') vac
     where vac.pc_lang_id = vpc_lang_id
       and vac.acs_financial_account_id = cfl.classif_leaf_id
       and cfl.classification_id = vcl.classification_id
       and cfl.pc_lang_id = vpc_lang_id
       and vac.acs_financial_account_id = vba.acs_financial_account_id
       and vba.id = tot.act_total_by_period_id(+)
       and vba.acs_financial_account_id = tot.acs_financial_account_id(+)
       and tot.acs_period_id = per.acs_period_id(+)
       and vba.acs_division_account_id = acc.acs_account_id(+)
       and vba.id = pam.acb_period_amount_id(+)
       and pam.acb_global_budget_id = glo.acb_global_budget_id(+)
       and glo.acb_budget_version_id = ver.acb_budget_version_id(+)
       and pam.acs_period_id = per_bud.acs_period_id(+)
       and vcl.classification_id = cla.classification_id(+)
       and vcl.classification_id = to_number(parameter_0)
       and vba.acs_financial_year_id in(parameter_1, parameter_5, parameter_9)
       and vba.acb_budget_version_id in(parameter_4, parameter_8, parameter_12)
       and (substr(ltrim(cfl.leaf_descr), 1, 4) between account_from and account_to);
end RPT_ACR_BALANCE_3_COL_BEM2_SUB;
