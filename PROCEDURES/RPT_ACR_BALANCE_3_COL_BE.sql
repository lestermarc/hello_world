--------------------------------------------------------
--  DDL for Procedure RPT_ACR_BALANCE_3_COL_BE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACR_BALANCE_3_COL_BE" (
  arefcursor     in out crystal_cursor_types.dualcursortyp
, parameter_0    in     varchar2
, parameter_1    in     number
, parameter_4    in     number
, parameter_5    in     number
, parameter_8    in     number
, parameter_9    in     number
, parameter_12   in     number
, parameter_33   in     varchar2
, account_from   in     varchar2
, account_to     in     varchar2
, procuser_lanid in     PCS.PC_LANG.LANID%type
, pc_user_id     in     PCS.PC_USER.PC_USER_ID%type
)
/**
*Description used for report ACR_BALANCE_THREE_COL_BE / ACR_BALANCE_THREE_COL_BE_RECAP /ACR_BUDGET_BE / ACR_BUDGET_RECAP_BE
*replace procedure ACR_BALANCE_3_COL_BE_RPT
*@created MZHU 06.06.2007 -- PYB dec 2008 (ajout des param 1-12)
*@lastUpdate SMA 22.08.2013
*@public
*@param parameter_0:  Classification ID      (CLASSIFICATION_ID)
*@param parameter_1:  Financial year id      (ACS_FINANCIAL_YEAR_ID)
*@param parameter_4:  Budget version id      (ACB_BUDGET_VERSION_ID)
*@param parameter_5:  Financial year id      (ACS_FINANCIAL_YEAR_ID)
*@param parameter_8:  Budget version id      (ACB_BUDGET_VERSION_ID)
*@param parameter_9:  Financial year id      (ACS_FINANCIAL_YEAR_ID)
*@param parameter_12: Budget version id      (ACB_BUDGET_VERSION_ID)
*@param parameter_33  Impression soldes à 0   CHECK_NULL_BALANCE
*@param ACCOUNT_FROM: Minimum account number (SUBSTR(LTRIM(CFL.LEAF_DESCR),1,3)
*@param ACCOUNT_TO:   Maximum account number (SUBSTR(LTRIM(CFL.LEAF_DESCR),1,3)
*/
is
  vpc_lang_id PCS.PC_LANG.PC_LANG_ID%type   := null;
  vpc_user_id PCS.PC_USER.PC_USER_ID%type   := null;
begin
  if parameter_0 is not null then
    PCS.PC_LIB_SESSION.setLanUserId(iLanId    => procuser_lanid
                                  , iPcUserId => pc_user_id
                                  , iPcCompId => null
                                  , iConliId  => null);
    vpc_lang_id  := PCS.PC_I_LIB_SESSION.getUserlangId;
    vpc_user_id  := PCS.PC_I_LIB_SESSION.getUserId;
  end if;

  if (ACS_FUNCTION.ExistDIVI = 1) then
    if (upper(PCS.PC_CONFIG.GetConfig('ACJ_USER_DIV_REPORTING') ) = 'TRUE') then
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
             , cfl.node03
             , cfl.node04
             , cfl.node05
             , cfl.node06
             , cfl.node07
             , cfl.node08
             , cfl.node09
             , cfl.node10
             , cfl.classif_leaf_id
             , cfl.leaf_descr
             , vac.acc_number
             , vac.des_description_summary
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
             , table(RPT_FUNCTIONS.TableAuthRptDivisions(vpc_user_id, null) ) AUT
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
           and (substr(ltrim(cfl.leaf_descr), 1, 3) between account_from and account_to)
           and (    (     (    ACC.ACS_ACCOUNT_ID is not null
                           and AUT.column_value is not null)
                     and (ACC.ACS_ACCOUNT_ID = AUT.column_value) )
                or (    ACC.ACS_ACCOUNT_ID is null
                    and AUT.column_value is null
                    and TYP = 'BUD')
               )
        union all
        select 0 ACB_BUDGET_VERSION_ID
             , 0 PER_AMOUNT_D
             , 0 PER_AMOUNT_C
             , null ACS_ACCOUNT_ID
             , null DIVISION_ACC_NUMBER
             , 0 ACS_FINANCIAL_YEAR_ID
             , 0 PER_NO_PERIOD
             , 0 BUD_PER_NO_PERIOD
             , 0 TOT_DEBIT_LC
             , 0 TOT_CREDIT_LC
             , 0 ACS_AUXILIARY_ACCOUNT_ID
             , '' C_TYPE_CUMUL
             , 0 ACS_DIVISION_ACCOUNT_ID
             , CFL.NODE01
             , CFL.NODE02
             , CFL.NODE03
             , CFL.NODE04
             , CFL.NODE05
             , CFL.NODE06
             , CFL.NODE07
             , CFL.NODE08
             , CFL.NODE09
             , CFL.NODE10
             , CFL.CLASSIF_LEAF_ID
             , CFL.LEAF_DESCR
             , VAC.ACC_NUMBER
             , VAC.DES_DESCRIPTION_SUMMARY
             , CLA.CLA_DESCR
          from ACS_ACCOUNT ACC
             , CLASSIF_FLAT CFL
             , CLASSIFICATION CLA
             , (select CLA.CLASSIFICATION_ID
                  from CLASSIFICATION CLA
                     , CLASSIF_TABLES TAB
                 where CLA.CLASSIFICATION_ID = TAB.CLASSIFICATION_ID
                   and TAB.CTA_TABLENAME = 'ACS_ACCOUNT') VCL
             , (select ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID
                     , ACS_ACCOUNT.ACC_NUMBER
                     , ACS_DESCRIPTION.PC_LANG_ID
                     , ACS_DESCRIPTION.DES_DESCRIPTION_SUMMARY
                     , ACS_FUNCTION.ISFINACCOUNTINME(ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID) ISFINACCOUNTINME
                  from ACS_DESCRIPTION
                     , ACS_ACCOUNT
                     , ACS_FINANCIAL_ACCOUNT
                     , ACS_SUB_SET
                 where ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID = ACS_ACCOUNT.ACS_ACCOUNT_ID
                   and ACS_ACCOUNT.ACS_ACCOUNT_ID = ACS_DESCRIPTION.ACS_ACCOUNT_ID
                   and ACS_ACCOUNT.ACS_SUB_SET_ID = ACS_SUB_SET.ACS_SUB_SET_ID
                   and ACS_SUB_SET.C_SUB_SET = 'ACC') VAC
         where VAC.PC_LANG_ID = vpc_lang_id
           and VAC.ACS_FINANCIAL_ACCOUNT_ID = CFL.CLASSIF_LEAF_ID
           and ACC.ACS_ACCOUNT_ID = VAC.ACS_FINANCIAL_ACCOUNT_ID
           and CFL.CLASSIFICATION_ID = VCL.CLASSIFICATION_ID
           and CFL.PC_LANG_ID = vpc_lang_id
           and VCL.CLASSIFICATION_ID = CLA.CLASSIFICATION_ID(+)
           and VCL.CLASSIFICATION_ID = to_number(parameter_0)
           and parameter_33 = '1';
    else   --Config('ACJ_USER_DIV_REPORTING') ) = 'FALSE'
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
             , cfl.node03
             , cfl.node04
             , cfl.node05
             , cfl.node06
             , cfl.node07
             , cfl.node08
             , cfl.node09
             , cfl.node10
             , cfl.classif_leaf_id
             , cfl.leaf_descr
             , vac.acc_number
             , vac.des_description_summary
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
           and (substr(ltrim(cfl.leaf_descr), 1, 3) between account_from and account_to)
           and (    (    ACC.ACS_ACCOUNT_ID is null
                     and TYP = 'BUD')
                or (ACC.ACS_ACCOUNT_ID is not null) )
        union all
        select 0 ACB_BUDGET_VERSION_ID
             , 0 PER_AMOUNT_D
             , 0 PER_AMOUNT_C
             , null ACS_ACCOUNT_ID
             , null DIVISION_ACC_NUMBER
             , 0 ACS_FINANCIAL_YEAR_ID
             , 0 PER_NO_PERIOD
             , 0 BUD_PER_NO_PERIOD
             , 0 TOT_DEBIT_LC
             , 0 TOT_CREDIT_LC
             , 0 ACS_AUXILIARY_ACCOUNT_ID
             , '' C_TYPE_CUMUL
             , 0 ACS_DIVISION_ACCOUNT_ID
             , CFL.NODE01
             , CFL.NODE02
             , CFL.NODE03
             , CFL.NODE04
             , CFL.NODE05
             , CFL.NODE06
             , CFL.NODE07
             , CFL.NODE08
             , CFL.NODE09
             , CFL.NODE10
             , CFL.CLASSIF_LEAF_ID
             , CFL.LEAF_DESCR
             , VAC.ACC_NUMBER
             , VAC.DES_DESCRIPTION_SUMMARY
             , CLA.CLA_DESCR
          from ACS_ACCOUNT ACC
             , CLASSIF_FLAT CFL
             , CLASSIFICATION CLA
             , (select CLA.CLASSIFICATION_ID
                  from CLASSIFICATION CLA
                     , CLASSIF_TABLES TAB
                 where CLA.CLASSIFICATION_ID = TAB.CLASSIFICATION_ID
                   and TAB.CTA_TABLENAME = 'ACS_ACCOUNT') VCL
             , (select ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID
                     , ACS_ACCOUNT.ACC_NUMBER
                     , ACS_DESCRIPTION.PC_LANG_ID
                     , ACS_DESCRIPTION.DES_DESCRIPTION_SUMMARY
                     , ACS_FUNCTION.ISFINACCOUNTINME(ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID) ISFINACCOUNTINME
                  from ACS_DESCRIPTION
                     , ACS_ACCOUNT
                     , ACS_FINANCIAL_ACCOUNT
                     , ACS_SUB_SET
                 where ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID = ACS_ACCOUNT.ACS_ACCOUNT_ID
                   and ACS_ACCOUNT.ACS_ACCOUNT_ID = ACS_DESCRIPTION.ACS_ACCOUNT_ID
                   and ACS_ACCOUNT.ACS_SUB_SET_ID = ACS_SUB_SET.ACS_SUB_SET_ID
                   and ACS_SUB_SET.C_SUB_SET = 'ACC') VAC
         where VAC.PC_LANG_ID = vpc_lang_id
           and VAC.ACS_FINANCIAL_ACCOUNT_ID = CFL.CLASSIF_LEAF_ID
           and ACC.ACS_ACCOUNT_ID = VAC.ACS_FINANCIAL_ACCOUNT_ID
           and CFL.CLASSIFICATION_ID = VCL.CLASSIFICATION_ID
           and CFL.PC_LANG_ID = vpc_lang_id
           and VCL.CLASSIFICATION_ID = CLA.CLASSIFICATION_ID(+)
           and VCL.CLASSIFICATION_ID = to_number(parameter_0)
           and parameter_33 = '1';
    end if;
  else   --ExistDIVI = 0
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
           , cfl.node03
           , cfl.node04
           , cfl.node05
           , cfl.node06
           , cfl.node07
           , cfl.node08
           , cfl.node09
           , cfl.node10
           , cfl.classif_leaf_id
           , cfl.leaf_descr
           , vac.acc_number
           , vac.des_description_summary
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
         and (substr(ltrim(cfl.leaf_descr), 1, 3) between account_from and account_to)
      union all
      select 0 ACB_BUDGET_VERSION_ID
           , 0 PER_AMOUNT_D
           , 0 PER_AMOUNT_C
           , null ACS_ACCOUNT_ID
           , null DIVISION_ACC_NUMBER
           , 0 ACS_FINANCIAL_YEAR_ID
           , 0 PER_NO_PERIOD
           , 0 BUD_PER_NO_PERIOD
           , 0 TOT_DEBIT_LC
           , 0 TOT_CREDIT_LC
           , 0 ACS_AUXILIARY_ACCOUNT_ID
           , '' C_TYPE_CUMUL
           , 0 ACS_DIVISION_ACCOUNT_ID
           , CFL.NODE01
           , CFL.NODE02
           , CFL.NODE03
           , CFL.NODE04
           , CFL.NODE05
           , CFL.NODE06
           , CFL.NODE07
           , CFL.NODE08
           , CFL.NODE09
           , CFL.NODE10
           , CFL.CLASSIF_LEAF_ID
           , CFL.LEAF_DESCR
           , VAC.ACC_NUMBER
           , VAC.DES_DESCRIPTION_SUMMARY
           , CLA.CLA_DESCR
        from ACS_ACCOUNT ACC
           , CLASSIF_FLAT CFL
           , CLASSIFICATION CLA
           , (select CLA.CLASSIFICATION_ID
                from CLASSIFICATION CLA
                   , CLASSIF_TABLES TAB
               where CLA.CLASSIFICATION_ID = TAB.CLASSIFICATION_ID
                 and TAB.CTA_TABLENAME = 'ACS_ACCOUNT') VCL
           , (select ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID
                   , ACS_ACCOUNT.ACC_NUMBER
                   , ACS_DESCRIPTION.PC_LANG_ID
                   , ACS_DESCRIPTION.DES_DESCRIPTION_SUMMARY
                   , ACS_FUNCTION.ISFINACCOUNTINME(ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID) ISFINACCOUNTINME
                from ACS_DESCRIPTION
                   , ACS_ACCOUNT
                   , ACS_FINANCIAL_ACCOUNT
                   , ACS_SUB_SET
               where ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID = ACS_ACCOUNT.ACS_ACCOUNT_ID
                 and ACS_ACCOUNT.ACS_ACCOUNT_ID = ACS_DESCRIPTION.ACS_ACCOUNT_ID
                 and ACS_ACCOUNT.ACS_SUB_SET_ID = ACS_SUB_SET.ACS_SUB_SET_ID
                 and ACS_SUB_SET.C_SUB_SET = 'ACC') VAC
       where VAC.PC_LANG_ID = vpc_lang_id
         and VAC.ACS_FINANCIAL_ACCOUNT_ID = CFL.CLASSIF_LEAF_ID
         and ACC.ACS_ACCOUNT_ID = VAC.ACS_FINANCIAL_ACCOUNT_ID
         and CFL.CLASSIFICATION_ID = VCL.CLASSIFICATION_ID
         and CFL.PC_LANG_ID = vpc_lang_id
         and VCL.CLASSIFICATION_ID = CLA.CLASSIFICATION_ID(+)
         and VCL.CLASSIFICATION_ID = to_number(parameter_0)
         and parameter_33 = '1';
  end if;
end RPT_ACR_BALANCE_3_COL_BE;
