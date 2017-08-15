--------------------------------------------------------
--  DDL for Procedure RPT_ACR_ACC_BALANCE_PER
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACR_ACC_BALANCE_PER" (
  aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, procparam_0    in     number
, procparam_1    in     varchar2
, procparam_2    in     varchar2
, parameter_5    in     varchar2
, procuser_lanid in     pcs.pc_lang.lanid%type
, pc_user_id     in     pcs.pc_user.pc_user_id%type
, pc_comp_id     in     PCS.PC_COMP.PC_COMP_ID%type
, pc_conli_id    in     PCS.PC_CONLI.PC_CONLI_ID%type
)
is
/**
* description used for report ACR_ACC_BALANCE_PER (Balance CG à une période, avec sélection de comptes

* @author SDO 2003
* @lastUpdate VHA 26 JUNE MAY 2013
* @public
* @param procparam_0    Exercice    (FYE_NO_EXERCICE)
* @param procparam_1    Compte du   (ACC_NUMBER)
* @param procparam_2    Compte au   (ACC_NUMBER)
* @param parameter_5    Division_ID (List) # = All  or ACS_DIVISION_ACCOUNT_ID list

*/
  tmp          number;
  vpc_lang_id  PCS.PC_LANG.PC_LANG_ID%type := null;
  vpc_user_id  PCS.PC_USER.PC_USER_ID%type := null;
  vpc_comp_id  PCS.PC_COMP.PC_COMP_ID%type := null;
  vpc_conli_id PCS.PC_CONLI.PC_CONLI_ID%type := null;
  vlstdivisions varchar2(4000);
begin
  if procparam_0 is not null then
    PCS.PC_LIB_SESSION.setLanUserId(iLanId    => procuser_lanid
                                  , iPcUserId => pc_user_id
                                  , iPcCompId => pc_comp_id
                                  , iConliId  => pc_conli_id);
      vpc_lang_id                   := PCS.PC_I_LIB_SESSION.getuserlangid;
      vpc_user_id                   := PCS.PC_I_LIB_SESSION.getUserId;
      vpc_comp_id                   := PCS.PC_I_LIB_SESSION.getCompanyId;
      vpc_conli_id                  := PCS.PC_I_LIB_SESSION.getConliId;
  end if;

  if (parameter_5 = '#') then
    vlstdivisions := null;
  else
    vlstdivisions := parameter_5;
  end if;

  select decode(min(acs_sub_set_id), null, 0, 1)
    into tmp
    from acs_sub_set
   where c_type_sub_set = 'DIVI';

  acr_functions.exist_division  := tmp;

  if (ACS_FUNCTION.ExistDIVI = 1) then
  open aRefCursor for
    select TOT.ACS_PERIOD_ID ACS_PERIOD_ID
         , TOT.C_TYPE_PERIOD C_TYPE_PERIOD
         , TOT.C_TYPE_CUMUL C_tYPE_CUMUL
         , TOT.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
         , ACS_FUNCTION.GetAccountNumber(TOT.ACS_FINANCIAL_ACCOUNT_ID) ACC_NUMBER_FIN
         , ACS_FUNCTION.GetAccountDescriptionSummary(TOT.ACS_FINANCIAL_ACCOUNT_ID) ACCOUNT_FIN_DESCR
         , ACC.C_BALANCE_SHEET_PROFIT_LOSS C_BALANCE_SHEET_PROFIT_LOSS
         , TOT.ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
         , ACS_FUNCTION.GetAccountNumber(TOT.ACS_DIVISION_ACCOUNT_ID) ACC_NUMBER_DIV
         , TOT.ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID
         , FIN.PC_CURR_ID PC_CURR_ID
         , ACS_FUNCTION.GetCurrencyName(TOT.ACS_FINANCIAL_CURRENCY_ID) CURRENCY_MB
         , ACS_FUNCTION.GetLocalCurrencyName LOCAL_CURRENCY_NAME
         , TOT.TOT_DEBIT_LC AMOUNT_LC_D
         , TOT.TOT_CREDIT_LC AMOUNT_LC_C
         , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID
         , ACS_FUNCTION.GetCurrencyName(TOT.ACS_ACS_FINANCIAL_CURRENCY_ID) CURRENCY_ME
         , TOT.TOT_DEBIT_FC AMOUNT_FC_D
         , TOT.TOT_CREDIT_FC AMOUNT_FC_C
         , PER.PER_NO_PERIOD PER_NO_PERIOD
      from ACS_FINANCIAL_YEAR FYE
         , ACS_PERIOD PER
         , ACS_DIVISION_ACCOUNT DIV
         , ACS_FINANCIAL_ACCOUNT ACC
         , ACS_FINANCIAL_CURRENCY FIN
         , ACT_TOTAL_BY_PERIOD TOT
         , table(RPT_FUNCTIONS.TableAuthRptDivisions(vpc_user_id, vlstdivisions) ) AUT
     where TOT.ACS_FINANCIAL_CURRENCY_ID = FIN.ACS_FINANCIAL_CURRENCY_ID
       and TOT.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_FINANCIAL_ACCOUNT_ID
       and TOT.ACS_DIVISION_ACCOUNT_ID = DIV.ACS_DIVISION_ACCOUNT_ID(+)
       and FYE.FYE_NO_EXERCICE = procparam_0
       and FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
       and PER.ACS_PERIOD_ID = TOT.ACS_PERIOD_ID
       and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
       and ACS_FUNCTION.GetAccountNumber(TOT.ACS_FINANCIAL_ACCOUNT_ID) >= procparam_1
       and ACS_FUNCTION.GetAccountNumber(TOT.ACS_FINANCIAL_ACCOUNT_ID) <= procparam_2
       and TOT.ACS_DIVISION_ACCOUNT_ID is not null
       and AUT.column_value = TOT.ACS_DIVISION_ACCOUNT_ID;
else     -- if (ACS_FUNCTION.ExistDIVI = 0) = No divisions
  open aRefCursor for
    select TOT.ACS_PERIOD_ID ACS_PERIOD_ID
         , TOT.C_TYPE_PERIOD C_TYPE_PERIOD
         , TOT.C_TYPE_CUMUL C_tYPE_CUMUL
         , TOT.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
         , ACS_FUNCTION.GetAccountNumber(TOT.ACS_FINANCIAL_ACCOUNT_ID) ACC_NUMBER_FIN
         , ACS_FUNCTION.GetAccountDescriptionSummary(TOT.ACS_FINANCIAL_ACCOUNT_ID) ACCOUNT_FIN_DESCR
         , ACC.C_BALANCE_SHEET_PROFIT_LOSS C_BALANCE_SHEET_PROFIT_LOSS
         , TOT.ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
         , ACS_FUNCTION.GetAccountNumber(TOT.ACS_DIVISION_ACCOUNT_ID) ACC_NUMBER_DIV
         , TOT.ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID
         , FIN.PC_CURR_ID PC_CURR_ID
         , ACS_FUNCTION.GetCurrencyName(TOT.ACS_FINANCIAL_CURRENCY_ID) CURRENCY_MB
         , ACS_FUNCTION.GetLocalCurrencyName LOCAL_CURRENCY_NAME
         , TOT.TOT_DEBIT_LC AMOUNT_LC_D
         , TOT.TOT_CREDIT_LC AMOUNT_LC_C
         , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID
         , ACS_FUNCTION.GetCurrencyName(TOT.ACS_ACS_FINANCIAL_CURRENCY_ID) CURRENCY_ME
         , TOT.TOT_DEBIT_FC AMOUNT_FC_D
         , TOT.TOT_CREDIT_FC AMOUNT_FC_C
         , PER.PER_NO_PERIOD PER_NO_PERIOD
      from ACS_FINANCIAL_YEAR FYE
         , ACS_PERIOD PER
         , ACS_DIVISION_ACCOUNT DIV
         , ACS_FINANCIAL_ACCOUNT ACC
         , ACS_FINANCIAL_CURRENCY FIN
         , ACT_TOTAL_BY_PERIOD TOT
     where TOT.ACS_FINANCIAL_CURRENCY_ID = FIN.ACS_FINANCIAL_CURRENCY_ID
       and TOT.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_FINANCIAL_ACCOUNT_ID
       and TOT.ACS_DIVISION_ACCOUNT_ID = DIV.ACS_DIVISION_ACCOUNT_ID(+)
       and FYE.FYE_NO_EXERCICE = procparam_0
       and FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
       and PER.ACS_PERIOD_ID = TOT.ACS_PERIOD_ID
       and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
       and ACS_FUNCTION.GetAccountNumber(TOT.ACS_FINANCIAL_ACCOUNT_ID) >= procparam_1
       and ACS_FUNCTION.GetAccountNumber(TOT.ACS_FINANCIAL_ACCOUNT_ID) <= procparam_2;
end if;
end RPT_ACR_ACC_BALANCE_PER;
