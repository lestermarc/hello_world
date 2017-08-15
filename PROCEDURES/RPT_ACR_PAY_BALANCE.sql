--------------------------------------------------------
--  DDL for Procedure RPT_ACR_PAY_BALANCE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACR_PAY_BALANCE" (
  aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, procparam_0    in     varchar2
, procparam_1    in     number
, procparam_2    in     varchar2
, procparam_3    in     varchar2
, procparam_4    in     varchar2
, procparam_5    in     varchar2
, procparam_6    in     number
, procparam_7    in     number
, procuser_lanid in     PCS.PC_LANG.LANID%type
, pc_user_id     in     PCS.PC_USER.PC_USER_ID%type
, pc_comp_id     in     PCS.PC_COMP.PC_COMP_ID%type
, pc_conli_id    in     PCS.PC_CONLI.PC_CONLI_ID%type
)
is
/**
* Procédure stockée utilisée pour le rapport ACR_PAY_BALANCE (Balance PAY à une période, avec sélection de comptes
* Replace report ACR_PAY_BALANCE_RPT
* @author SDO
* @lastUpdate VHA 26 JUNE 2013
* @version 2003
* @public
* @param procparam_0    Sous-ensemble       (ACS_SUB_SET_ID)
* @param procparam_1    Exercice            (FYE_NO_EXERCICE)
* @param procparam_2    Compte du...        (ACC_NUMBER)
* @param procparam_3    Compte au...        (ACC_NUMBER)
* @param procparam_4    Division_ID (List)  NULL = All or ACS_DIVISION_ACCOUNT_ID list
* @param procparam_5    Collectiv_ID (List) '' = All sinon liste des ID
* @param procparam_6    Periode du...       (PER_NO_PERIOD)
* @param procparam_7    Période au...       (PER_NO_PERIOD)
*/
  tmp          number;
  vpc_lang_id  PCS.PC_LANG.PC_LANG_ID%type := null;
  vpc_user_id  PCS.PC_USER.PC_USER_ID%type := null;
  vpc_comp_id  PCS.PC_COMP.PC_COMP_ID%type := null;
  vpc_conli_id PCS.PC_CONLI.PC_CONLI_ID%type := null;
begin
  if (procparam_1 is not null) then
    PCS.PC_LIB_SESSION.setLanUserId(iLanId    => procuser_lanid
                                  , iPcUserId => pc_user_id
                                  , iPcCompId => pc_comp_id
                                  , iConliId  => pc_conli_id);
      vpc_lang_id                   := PCS.PC_I_LIB_SESSION.getUserlangId;
      vpc_user_id                   := PCS.PC_I_LIB_SESSION.getUserId;
      vpc_comp_id                   := PCS.PC_I_LIB_SESSION.getCompanyId;
      vpc_conli_id                  := PCS.PC_I_LIB_SESSION.getConliId;
  end if;

  select decode(min(ACS_SUB_SET_ID), null, 0, 1)
    into TMP
    from ACS_SUB_SET
   where C_TYPE_SUB_SET = 'DIVI';

  ACR_FUNCTIONS.EXIST_DIVISION  := tmp;
  pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
  vpc_lang_id                   := pcs.PC_I_LIB_SESSION.GetUserLangId;

  if (ACS_FUNCTION.ExistDIVI = 1) then
  open aRefCursor for
    select AUX.ACS_AUXILIARY_ACCOUNT_ID
         , ACC.ACC_NUMBER AUX_NUMBER
         , (select DES.DES_DESCRIPTION_SUMMARY
              from ACS_DESCRIPTION DES
             where DES.ACS_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID
               and DES.PC_LANG_ID = vpc_lang_id) AUX_DESCR
         , ACS_FUNCTION.GetPer_short_Name(TOT.ACS_AUXILIARY_ACCOUNT_ID) PER_SHORT_NAME
         , TOT.ACS_FINANCIAL_CURRENCY_ID
         , (select CUB.CURRENCY
              from PCS.PC_CURR CUB
                 , ACS_FINANCIAL_CURRENCY CMB
             where CMB.ACS_FINANCIAL_CURRENCY_ID = TOT.ACS_FINANCIAL_CURRENCY_ID
               and CUB.PC_CURR_ID = CMB.PC_CURR_ID) CURRENCY_MB
         , TOT.TOT_DEBIT_LC
         , TOT.TOT_CREDIT_LC
         , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
         , (select CUE.CURRENCY
              from PCS.PC_CURR CUE
                 , ACS_FINANCIAL_CURRENCY CME
             where CME.ACS_FINANCIAL_CURRENCY_ID = TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
               and CUE.PC_CURR_ID = CME.PC_CURR_ID) CURRENCY_ME
         , TOT.TOT_DEBIT_FC
         , TOT.TOT_CREDIT_FC
         , TOT.ACS_FINANCIAL_ACCOUNT_ID
         , (select FIN.ACC_NUMBER
              from ACS_ACCOUNT FIN
             where FIN.ACS_ACCOUNT_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID) FIN_COLLECTIV
         , TOT.ACS_DIVISION_ACCOUNT_ID
         , TOT.ACS_PERIOD_ID
         , TOT.C_TYPE_PERIOD
         , TOT.C_TYPE_CUMUL
         , SUB.ACS_SUB_SET_ID
         , SUB.C_SUB_SET
         , (select DE1.DES_DESCRIPTION_SUMMARY
              from ACS_DESCRIPTION DE1
             where DE1.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
               and DE1.PC_LANG_ID = vpc_lang_id) SUB_SET_DESCR
         , PER.PER_NO_PERIOD
         , FYE.ACS_FINANCIAL_YEAR_ID
         , FYE.FYE_NO_EXERCICE
      from ACS_FINANCIAL_YEAR FYE
         , ACS_PERIOD PER
         , ACS_SUB_SET SUB
         , ACT_TOTAL_BY_PERIOD TOT
         , ACS_FINANCIAL_ACCOUNT FIN
         , ACS_ACCOUNT ACC
         , ACS_AUXILIARY_ACCOUNT AUX
         , table(RPT_FUNCTIONS.TableAuthRptDivisions(vpc_user_id, procparam_4) ) AUT
     where AUX.ACS_AUXILIARY_ACCOUNT_ID = TOT.ACS_AUXILIARY_ACCOUNT_ID
       and AUX.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
       and TOT.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
       and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
       and SUB.C_SUB_SET = 'PAY'
       and (   ACC.ACS_SUB_SET_ID = procparam_0
            or procparam_0 is null)
       and (   instr(',' || procparam_5 || ',', to_char(',' || FIN.ACS_FINANCIAL_ACCOUNT_ID || ',') ) > 0
            or procparam_5 is null)
       and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
       and PER.PER_NO_PERIOD >= procparam_6
       and PER.PER_NO_PERIOD <= procparam_7
       and PER.ACS_FINANCIAL_YEAR_ID = FYE.ACS_FINANCIAL_YEAR_ID
       and FYE.FYE_NO_EXERCICE = procparam_1
       and ACC.ACC_NUMBER >= procparam_2
       and ACC.ACC_NUMBER <= procparam_3
       and TOT.ACS_DIVISION_ACCOUNT_ID is not null
       and AUT.column_value = TOT.ACS_DIVISION_ACCOUNT_ID;
else -- if (ACS_FUNCTION.ExistDIVI = 0) = No divisions
  open aRefCursor for
    select AUX.ACS_AUXILIARY_ACCOUNT_ID
         , ACC.ACC_NUMBER AUX_NUMBER
         , (select DES.DES_DESCRIPTION_SUMMARY
              from ACS_DESCRIPTION DES
             where DES.ACS_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID
               and DES.PC_LANG_ID = vpc_lang_id) AUX_DESCR
         , ACS_FUNCTION.GetPer_short_Name(TOT.ACS_AUXILIARY_ACCOUNT_ID) PER_SHORT_NAME
         , TOT.ACS_FINANCIAL_CURRENCY_ID
         , (select CUB.CURRENCY
              from PCS.PC_CURR CUB
                 , ACS_FINANCIAL_CURRENCY CMB
             where CMB.ACS_FINANCIAL_CURRENCY_ID = TOT.ACS_FINANCIAL_CURRENCY_ID
               and CUB.PC_CURR_ID = CMB.PC_CURR_ID) CURRENCY_MB
         , TOT.TOT_DEBIT_LC
         , TOT.TOT_CREDIT_LC
         , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
         , (select CUE.CURRENCY
              from PCS.PC_CURR CUE
                 , ACS_FINANCIAL_CURRENCY CME
             where CME.ACS_FINANCIAL_CURRENCY_ID = TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
               and CUE.PC_CURR_ID = CME.PC_CURR_ID) CURRENCY_ME
         , TOT.TOT_DEBIT_FC
         , TOT.TOT_CREDIT_FC
         , TOT.ACS_FINANCIAL_ACCOUNT_ID
         , (select FIN.ACC_NUMBER
              from ACS_ACCOUNT FIN
             where FIN.ACS_ACCOUNT_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID) FIN_COLLECTIV
         , TOT.ACS_DIVISION_ACCOUNT_ID
         , TOT.ACS_PERIOD_ID
         , TOT.C_TYPE_PERIOD
         , TOT.C_TYPE_CUMUL
         , SUB.ACS_SUB_SET_ID
         , SUB.C_SUB_SET
         , (select DE1.DES_DESCRIPTION_SUMMARY
              from ACS_DESCRIPTION DE1
             where DE1.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
               and DE1.PC_LANG_ID = vpc_lang_id) SUB_SET_DESCR
         , PER.PER_NO_PERIOD
         , FYE.ACS_FINANCIAL_YEAR_ID
         , FYE.FYE_NO_EXERCICE
      from ACS_FINANCIAL_YEAR FYE
         , ACS_PERIOD PER
         , ACS_SUB_SET SUB
         , ACT_TOTAL_BY_PERIOD TOT
         , ACS_FINANCIAL_ACCOUNT FIN
         , ACS_ACCOUNT ACC
         , ACS_AUXILIARY_ACCOUNT AUX
     where AUX.ACS_AUXILIARY_ACCOUNT_ID = TOT.ACS_AUXILIARY_ACCOUNT_ID
       and AUX.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
       and TOT.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
       and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
       and SUB.C_SUB_SET = 'PAY'
       and (   ACC.ACS_SUB_SET_ID = procparam_0
            or procparam_0 is null)
       and (   instr(',' || procparam_5 || ',', to_char(',' || FIN.ACS_FINANCIAL_ACCOUNT_ID || ',') ) > 0
            or procparam_5 is null)
       and TOT.ACS_DIVISION_ACCOUNT_ID is null
       and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
       and PER.PER_NO_PERIOD >= procparam_6
       and PER.PER_NO_PERIOD <= procparam_7
       and PER.ACS_FINANCIAL_YEAR_ID = FYE.ACS_FINANCIAL_YEAR_ID
       and FYE.FYE_NO_EXERCICE = procparam_1
       and ACC.ACC_NUMBER >= procparam_2
       and ACC.ACC_NUMBER <= procparam_3;
end if;
end RPT_ACR_PAY_BALANCE;
