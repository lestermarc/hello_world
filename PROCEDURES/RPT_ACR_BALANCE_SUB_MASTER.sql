--------------------------------------------------------
--  DDL for Procedure RPT_ACR_BALANCE_SUB_MASTER
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACR_BALANCE_SUB_MASTER" (
  arefcursor     in out crystal_cursor_types.dualcursortyp
, parameter_0    in     varchar2
, procuser_lanid in     pcs.pc_lang.lanid%type
, pc_user_id     in     PCS.PC_USER.PC_USER_ID%type
, pc_comp_id     in     PCS.PC_COMP.PC_COMP_ID%type
, pc_conli_id    in     PCS.PC_CONLI.PC_CONLI_ID%type
)
/**
* description used for report ACR_BALANCE and ACR_BALANCE_DC

*@CREATED JLIU 04.09.2009
*@lastUpdate VHA 16 JULY 2013
*@PUBLIC
*@param PARAMETER_0:   CLASSIFICATION_ID
*@param PARAMETER_10:  ACB_BUDGET_VERSION_ID
*@param PARAMETER_11:  ACB_BUDGET_VERSION_ID
*/
is
  vpc_lang_id  PCS.PC_LANG.PC_LANG_ID%type := null;
  vpc_user_id  PCS.PC_USER.PC_USER_ID%type := null;
  vpc_comp_id  PCS.PC_COMP.PC_COMP_ID%type := null;
  vpc_conli_id PCS.PC_CONLI.PC_CONLI_ID%type := null;
begin
  if parameter_0 is not null then
    PCS.PC_LIB_SESSION.setLanUserId(iLanId    => procuser_lanid
                                  , iPcUserId => pc_user_id
                                  , iPcCompId => pc_comp_id
                                  , iConliId  => pc_conli_id);
      vpc_lang_id   := PCS.PC_I_LIB_SESSION.getuserlangid;
      vpc_user_id   := PCS.PC_I_LIB_SESSION.getUserId;
      vpc_comp_id   := PCS.PC_I_LIB_SESSION.getCompanyId;
      vpc_conli_id  := PCS.PC_I_LIB_SESSION.getConliId;
  end if;

  if (ACS_FUNCTION.ExistDIVI = 1) then
  open arefcursor for
    select VER.ACB_BUDGET_VERSION_ID
         , PAM.PER_AMOUNT_D
         , PAM.PER_AMOUNT_C
         , ACC.ACS_ACCOUNT_ID
         , FUR.ACS_FINANCIAL_CURRENCY_ID
         , PER.ACS_FINANCIAL_YEAR_ID
         , PER.PER_NO_PERIOD
         , PER_BUD.PER_NO_PERIOD BUD_PER_NO_PERIOD
         , TOT.TOT_DEBIT_FC
         , TOT.TOT_CREDIT_FC
         , TOT.ACS_AUXILIARY_ACCOUNT_ID
         , TOT.C_TYPE_CUMUL
         , TOT.ACS_DIVISION_ACCOUNT_ID
         , CUR.CURRENCY
         , VAC.ACS_FINANCIAL_ACCOUNT_ID
         , VAC.ACC_NUMBER
      from ACB_BUDGET_VERSION VER
         , ACB_GLOBAL_BUDGET GLO
         , ACB_PERIOD_AMOUNT PAM
         , ACS_ACCOUNT ACC
         , ACS_FINANCIAL_CURRENCY FUR
         , PCS.PC_CURR CUR
         , ACS_PERIOD PER
         , ACS_PERIOD PER_BUD
         , ACT_TOTAL_BY_PERIOD TOT
         , (select ACC.ACS_FINANCIAL_ACCOUNT_ID
                 , TOT.ACS_DIVISION_ACCOUNT_ID
                 , TOT.ACT_TOTAL_BY_PERIOD_ID id
                 , 'TOT' TYP
                 , PER.ACS_FINANCIAL_YEAR_ID
                 , 0 ACB_BUDGET_VERSION_ID
              from ACS_FINANCIAL_ACCOUNT ACC
                 , ACT_TOTAL_BY_PERIOD TOT
                 , ACS_PERIOD PER
             where ACC.ACS_FINANCIAL_ACCOUNT_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID
               and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
               and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
            union all
            select ACC.ACS_FINANCIAL_ACCOUNT_ID
                 , GLO.ACS_DIVISION_ACCOUNT_ID
                 , AMO.ACB_PERIOD_AMOUNT_ID id
                 , 'BUD' TYP
                 , PER.ACS_FINANCIAL_YEAR_ID
                 , GLO.ACB_BUDGET_VERSION_ID
              from ACS_FINANCIAL_ACCOUNT ACC
                 , ACB_PERIOD_AMOUNT AMO
                 , ACB_GLOBAL_BUDGET GLO
                 , ACS_PERIOD PER
                 , ACS_FINANCIAL_CURRENCY CUR
             where ACC.ACS_FINANCIAL_ACCOUNT_ID = GLO.ACS_FINANCIAL_ACCOUNT_ID
               and GLO.ACB_GLOBAL_BUDGET_ID = AMO.ACB_GLOBAL_BUDGET_ID
               and GLO.ACS_FINANCIAL_CURRENCY_ID = CUR.ACS_FINANCIAL_CURRENCY_ID
               and CUR.FIN_LOCAL_CURRENCY = 1
               and AMO.ACS_PERIOD_ID = PER.ACS_PERIOD_ID) VBA
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
         , table(RPT_FUNCTIONS.TableAuthRptDivisions(vpc_user_id, null) ) AUT
     where VAC.ACS_FINANCIAL_ACCOUNT_ID = to_number(parameter_0)
       and VAC.PC_LANG_ID = VPC_LANG_ID
       and VAC.ACS_FINANCIAL_ACCOUNT_ID = VBA.ACS_FINANCIAL_ACCOUNT_ID
       and VBA.id = TOT.ACT_TOTAL_BY_PERIOD_ID(+)
       and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID(+)
       and TOT.ACS_ACS_FINANCIAL_CURRENCY_ID = FUR.ACS_FINANCIAL_CURRENCY_ID(+)
       and FUR.FIN_LOCAL_CURRENCY <> 1
       and FUR.PC_CURR_ID = CUR.PC_CURR_ID(+)
       and VBA.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID(+)
       and VBA.id = PAM.ACB_PERIOD_AMOUNT_ID(+)
       and PAM.ACB_GLOBAL_BUDGET_ID = GLO.ACB_GLOBAL_BUDGET_ID(+)
       and GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID(+)
       and PAM.ACS_PERIOD_ID = PER_BUD.ACS_PERIOD_ID(+)
       and (    (     (    ACC.ACS_ACCOUNT_ID is not null
                       and AUT.column_value is not null)
                 and (ACC.ACS_ACCOUNT_ID = AUT.column_value) )
            or (    ACC.ACS_ACCOUNT_ID is null
                and AUT.column_value is null
                and TYP = 'BUD')
           );
else
  open arefcursor for
    select VER.ACB_BUDGET_VERSION_ID
         , PAM.PER_AMOUNT_D
         , PAM.PER_AMOUNT_C
         , ACC.ACS_ACCOUNT_ID
         , FUR.ACS_FINANCIAL_CURRENCY_ID
         , PER.ACS_FINANCIAL_YEAR_ID
         , PER.PER_NO_PERIOD
         , PER_BUD.PER_NO_PERIOD BUD_PER_NO_PERIOD
         , TOT.TOT_DEBIT_FC
         , TOT.TOT_CREDIT_FC
         , TOT.ACS_AUXILIARY_ACCOUNT_ID
         , TOT.C_TYPE_CUMUL
         , TOT.ACS_DIVISION_ACCOUNT_ID
         , CUR.CURRENCY
         , VAC.ACS_FINANCIAL_ACCOUNT_ID
         , VAC.ACC_NUMBER
      from ACB_BUDGET_VERSION VER
         , ACB_GLOBAL_BUDGET GLO
         , ACB_PERIOD_AMOUNT PAM
         , ACS_ACCOUNT ACC
         , ACS_FINANCIAL_CURRENCY FUR
         , PCS.PC_CURR CUR
         , ACS_PERIOD PER
         , ACS_PERIOD PER_BUD
         , ACT_TOTAL_BY_PERIOD TOT
         , (select ACC.ACS_FINANCIAL_ACCOUNT_ID
                 , TOT.ACS_DIVISION_ACCOUNT_ID
                 , TOT.ACT_TOTAL_BY_PERIOD_ID id
                 , 'TOT' TYP
                 , PER.ACS_FINANCIAL_YEAR_ID
                 , 0 ACB_BUDGET_VERSION_ID
              from ACS_FINANCIAL_ACCOUNT ACC
                 , ACT_TOTAL_BY_PERIOD TOT
                 , ACS_PERIOD PER
             where ACC.ACS_FINANCIAL_ACCOUNT_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID
               and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
               and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
            union all
            select ACC.ACS_FINANCIAL_ACCOUNT_ID
                 , GLO.ACS_DIVISION_ACCOUNT_ID
                 , AMO.ACB_PERIOD_AMOUNT_ID id
                 , 'BUD' TYP
                 , PER.ACS_FINANCIAL_YEAR_ID
                 , GLO.ACB_BUDGET_VERSION_ID
              from ACS_FINANCIAL_ACCOUNT ACC
                 , ACB_PERIOD_AMOUNT AMO
                 , ACB_GLOBAL_BUDGET GLO
                 , ACS_PERIOD PER
                 , ACS_FINANCIAL_CURRENCY CUR
             where ACC.ACS_FINANCIAL_ACCOUNT_ID = GLO.ACS_FINANCIAL_ACCOUNT_ID
               and GLO.ACB_GLOBAL_BUDGET_ID = AMO.ACB_GLOBAL_BUDGET_ID
               and GLO.ACS_FINANCIAL_CURRENCY_ID = CUR.ACS_FINANCIAL_CURRENCY_ID
               and CUR.FIN_LOCAL_CURRENCY = 1
               and AMO.ACS_PERIOD_ID = PER.ACS_PERIOD_ID) VBA
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
     where VAC.ACS_FINANCIAL_ACCOUNT_ID = to_number(parameter_0)
       and VAC.PC_LANG_ID = VPC_LANG_ID
       and VAC.ACS_FINANCIAL_ACCOUNT_ID = VBA.ACS_FINANCIAL_ACCOUNT_ID
       and VBA.id = TOT.ACT_TOTAL_BY_PERIOD_ID(+)
       and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID(+)
       and TOT.ACS_ACS_FINANCIAL_CURRENCY_ID = FUR.ACS_FINANCIAL_CURRENCY_ID(+)
       and FUR.FIN_LOCAL_CURRENCY <> 1
       and FUR.PC_CURR_ID = CUR.PC_CURR_ID(+)
       and VBA.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID(+)
       and VBA.id = PAM.ACB_PERIOD_AMOUNT_ID(+)
       and PAM.ACB_GLOBAL_BUDGET_ID = GLO.ACB_GLOBAL_BUDGET_ID(+)
       and GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID(+)
       and PAM.ACS_PERIOD_ID = PER_BUD.ACS_PERIOD_ID(+);
end if;
end rpt_acr_balance_sub_master;
