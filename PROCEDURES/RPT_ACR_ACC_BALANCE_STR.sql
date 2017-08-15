--------------------------------------------------------
--  DDL for Procedure RPT_ACR_ACC_BALANCE_STR
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACR_ACC_BALANCE_STR" (
  aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, procparam_0    in     number
, procparam_1    in     number
, procparam_2    in     number
, procparam_3    in     varchar2
, procparam_4    in     varchar2
, procparam_5    in     varchar2
, parameter_5    in     varchar2
, parameter_7    in     varchar2
, procuser_lanid in     PCS.PC_LANG.LANID%type
, pc_user_id     in     PCS.PC_USER.PC_USER_ID%type
, pc_comp_id     in     PCS.PC_COMP.PC_COMP_ID%type
, pc_conli_id    in     PCS.PC_CONLI.PC_CONLI_ID%type
)
is
/**
* description used for report  ACR_ACC_BALANCE_STR (Balance CG avec période ou dates, avec classification

* @author SDO 2003
* @lastUpdate VHA 26 JUNE 2013
* @public
* @param procparam_0    Exercice        (FYE_NO_EXERCICE)
* @param procparam_1    Période du      (PER_NO_PERIOD)
* @param procparam_2    Période au      (PER_NO_PERIOD)
* @param procparam_3    Date début      (IMF_TRANSACTION_DATE / IMF_VALUE_DATE)
* @param procparam_4    Date fin        (IMF_TRANSACTION_DATE / IMF_VALUE_DATE)
* @param procparam_5    Classification  (ClASSIFICATION_ID)
* @param parameter_5    Division_ID (List) # = All  or ACS_DIVISION_ACCOUNT_ID list
* @param parameter_7    Date type (0 = IMF_VALUE_DATE / 1 = IMF_TRANSACTION_DATE)
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
      vpc_lang_id                   := pcs.PC_I_LIB_SESSION.getuserlangid;
      vpc_user_id                   := pcs.PC_I_LIB_SESSION.getUserId;
      vpc_comp_id                   := pcs.PC_I_LIB_SESSION.getCompanyId;
      vpc_conli_id                  := pcs.PC_I_LIB_SESSION.getConliId;
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
  if     (procparam_3 is null)
     and (procparam_4 is null) then
    open aRefCursor for
      select trim(CFL.LEAF_DESCR) LEAF_DESCR
           , CFL.NODE01 NODE01
           , CFL.NODE02 NODE02
           , CFL.NODE03 NODE03
           , CFL.NODE04 NODE04
           , CFL.NODE05 NODE05
           , CFL.NODE06 NODE06
           , CFL.NODE07 NODE07
           , CFL.NODE08 NODE08
           , CFL.NODE09 NODE09
           , CFL.NODE10 NODE10
           , TOT.ACS_PERIOD_ID ACS_PERIOD_ID
           , TOT.C_TYPE_PERIOD C_TYPE_PERIOD
           , TOT.C_TYPE_CUMUL C_TYPE_CUMUL
           , TOT.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
           , ACC.ACC_NUMBER ACC_NUMBER_FIN
           , FIN.C_BALANCE_DISPLAY C_BALANCE_DISPLAY
           , TOT.ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
           , (select ACC.ACC_NUMBER
                from ACS_ACCOUNT ACC
               where ACC.ACS_ACCOUNT_ID = TOT.ACS_DIVISION_ACCOUNT_ID) ACC_NUMBER_DIV
           , TOT.ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID
           , ACS_FUNCTION.GetLocalCurrencyName LOCAL_CURRENCY_NAME
           , TOT.TOT_DEBIT_LC AMOUNT_LC_D
           , TOT.TOT_CREDIT_LC AMOUNT_LC_C
           , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID
           , (select CU1.CURRENCY
                from PCS.PC_CURR CU1
                   , ACS_FINANCIAL_CURRENCY CF1
               where CF1.ACS_FINANCIAL_CURRENCY_ID = TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
                 and CU1.PC_CURR_ID = CF1.PC_CURR_ID) CURRENCY_ME
           , TOT.TOT_DEBIT_FC AMOUNT_FC_D
           , TOT.TOT_CREDIT_FC AMOUNT_FC_C
           , 0 C_ETAT_JOURNAL
           , CFL.PC_LANG_ID PC_LANG_ID
        from ACS_FINANCIAL_YEAR FYE
           , ACS_PERIOD PER
           , ACS_FINANCIAL_ACCOUNT FIN
           , ACS_ACCOUNT ACC
           , ACS_FINANCIAL_CURRENCY CUR
           , ACT_TOTAL_BY_PERIOD TOT
           , CLASSIF_FLAT CFL
           , table(RPT_FUNCTIONS.TableAuthRptDivisions(vpc_user_id, vlstdivisions) ) AUT
       where CFL.CLASSIFICATION_ID = procparam_5
         and CFL.CLASSIF_LEAF_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID
         and TOT.ACS_FINANCIAL_CURRENCY_ID = CUR.ACS_FINANCIAL_CURRENCY_ID
         and TOT.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
         and FIN.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
         and FYE.FYE_NO_EXERCICE = procparam_0
         and FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
         and PER.PER_NO_PERIOD >= procparam_1
         and PER.PER_NO_PERIOD <= procparam_2
         and PER.ACS_PERIOD_ID = TOT.ACS_PERIOD_ID
         and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
         and (parameter_5 is not null)
         and TOT.ACS_DIVISION_ACCOUNT_ID is not null
         and AUT.column_value = TOT.ACS_DIVISION_ACCOUNT_ID;
  else
    open aRefCursor for
      select   trim(CFL.LEAF_DESCR) LEAF_DESCR
             , CFL.NODE01 NODE01
             , CFL.NODE02 NODE02
             , CFL.NODE03 NODE03
             , CFL.NODE04 NODE04
             , CFL.NODE05 NODE05
             , CFL.NODE06 NODE06
             , CFL.NODE07 NODE07
             , CFL.NODE08 NODE08
             , CFL.NODE09 NODE09
             , CFL.NODE10 NODE10
             , IMF.ACS_PERIOD_ID ACS_PERIOD_ID
             , PER.C_TYPE_PERIOD C_TYPE_PERIOD
             , SUB.C_TYPE_CUMUL C_TYPE_CUMUL
             , IMF.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
             , ACC.ACC_NUMBER ACC_NUMBER_FIN
             , FIN.C_BALANCE_DISPLAY C_BALANCE_DISPLAY
             , IMF.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
             , (select ACC.ACC_NUMBER
                  from ACS_ACCOUNT ACC
                 where ACC.ACS_ACCOUNT_ID = IMF.IMF_ACS_DIVISION_ACCOUNT_ID) ACC_NUMBER_DIV
             , IMF.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID
             , ACS_FUNCTION.GetLocalCurrencyName LOCAL_CURRENCY_NAME
             , sum(IMF.IMF_AMOUNT_LC_D) AMOUNT_LC_D
             , sum(IMF.IMF_AMOUNT_LC_C) AMOUNT_LC_C
             , IMF.ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID
             , (select CU1.CURRENCY
                  from PCS.PC_CURR CU1
                     , ACS_FINANCIAL_CURRENCY CF1
                 where CF1.ACS_FINANCIAL_CURRENCY_ID = IMF.ACS_FINANCIAL_CURRENCY_ID
                   and CU1.PC_CURR_ID = CF1.PC_CURR_ID) CURRENCY_ME
             , sum(IMF.IMF_AMOUNT_FC_D) AMOUNT_FC_D
             , sum(IMF.IMF_AMOUNT_FC_C) AMOUNT_FC_C
             , ACT_FUNCTIONS.GetBROState(DOC.ACT_JOURNAL_ID, 'ACC') C_ETAT_JOURNAL
             , CFL.PC_LANG_ID PC_LANG_ID
          from ACJ_SUB_SET_CAT SUB
             , ACT_DOCUMENT DOC
             , ACS_FINANCIAL_YEAR FYE
             , ACS_PERIOD PER
             , ACS_ACCOUNT ACC
             , ACS_FINANCIAL_ACCOUNT FIN
             , ACS_FINANCIAL_CURRENCY CUR
             , ACT_FINANCIAL_IMPUTATION IMF
             , CLASSIF_FLAT CFL
             , table(RPT_FUNCTIONS.TableAuthRptDivisions(vpc_user_id, vlstdivisions) ) AUT
         where CFL.CLASSIFICATION_ID = procparam_5
           and CFL.CLASSIF_LEAF_ID = IMF.ACS_FINANCIAL_ACCOUNT_ID
           and IMF.ACS_ACS_FINANCIAL_CURRENCY_ID = CUR.ACS_FINANCIAL_CURRENCY_ID
           and IMF.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and FIN.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and IMF.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SUB.ACJ_CATALOGUE_DOCUMENT_ID
           and SUB.C_SUB_SET = 'ACC'
           and FYE.FYE_NO_EXERCICE = procparam_0
           and FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
           and PER.ACS_PERIOD_ID = IMF.ACS_PERIOD_ID
           and PER.C_TYPE_PERIOD <> '1'
           and trunc(to_date(procparam_3, 'YYYYMMDD') ) <=(case parameter_7
                                                             when '0' then trunc(IMF.IMF_VALUE_DATE)
                                                             else trunc(IMF.IMF_TRANSACTION_DATE)
                                                           end)
           and trunc(to_date(procparam_4, 'YYYYMMDD') ) >=(case parameter_7
                                                             when '0' then trunc(IMF.IMF_VALUE_DATE)
                                                             else trunc(IMF.IMF_TRANSACTION_DATE)
                                                           end)
           and (parameter_5 is not null)
           and IMF.IMF_ACS_DIVISION_ACCOUNT_ID is not null
           and AUT.column_value = IMF.IMF_ACS_DIVISION_ACCOUNT_ID
      group by CFL.LEAF_DESCR
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
             , IMF.ACS_PERIOD_ID
             , PER.C_TYPE_PERIOD
             , SUB.C_TYPE_CUMUL
             , IMF.ACS_FINANCIAL_ACCOUNT_ID
             , ACC.ACC_NUMBER
             , FIN.C_BALANCE_DISPLAY
             , IMF.IMF_ACS_DIVISION_ACCOUNT_ID
             , IMF.ACS_ACS_FINANCIAL_CURRENCY_ID
             , ACS_FUNCTION.GetLocalCurrencyName
             , IMF.ACS_FINANCIAL_CURRENCY_ID
             , ACT_FUNCTIONS.GetBROState(DOC.ACT_JOURNAL_ID, 'ACC')
             , CFL.PC_LANG_ID
      union all
      select   trim(CFL.LEAF_DESCR) LEAF_DESCR
             , CFL.NODE01 NODE01
             , CFL.NODE02 NODE02
             , CFL.NODE03 NODE03
             , CFL.NODE04 NODE04
             , CFL.NODE05 NODE05
             , CFL.NODE06 NODE06
             , CFL.NODE07 NODE07
             , CFL.NODE08 NODE08
             , CFL.NODE09 NODE09
             , CFL.NODE10 NODE10
             , IMF.ACS_PERIOD_ID ACS_PERIOD_ID
             , PER.C_TYPE_PERIOD C_TYPE_PERIOD
             , SUB.C_TYPE_CUMUL C_TYPE_CUMUL
             , IMF.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
             , ACC.ACC_NUMBER ACC_NUMBER_FIN
             , FIN.C_BALANCE_DISPLAY C_BALANCE_DISPLAY
             , IMF.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
             , (select ACC.ACC_NUMBER
                  from ACS_ACCOUNT ACC
                 where ACC.ACS_ACCOUNT_ID = IMF.IMF_ACS_DIVISION_ACCOUNT_ID) ACC_NUMBER_DIV
             , IMF.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID
             , ACS_FUNCTION.GetLocalCurrencyName LOCAL_CURRENCY_NAME
             , sum(IMF.IMF_AMOUNT_LC_D) AMOUNT_LC_D
             , sum(IMF.IMF_AMOUNT_LC_C) AMOUNT_LC_C
             , IMF.ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID
             , (select CU1.CURRENCY
                  from PCS.PC_CURR CU1
                     , ACS_FINANCIAL_CURRENCY CF1
                 where CF1.ACS_FINANCIAL_CURRENCY_ID = IMF.ACS_FINANCIAL_CURRENCY_ID
                   and CU1.PC_CURR_ID = CF1.PC_CURR_ID) CURRENCY_ME
             , sum(IMF.IMF_AMOUNT_FC_D) AMOUNT_FC_D
             , sum(IMF.IMF_AMOUNT_FC_C) AMOUNT_FC_C
             , ACT_FUNCTIONS.GetBROState(DOC.ACT_JOURNAL_ID, 'ACC') C_ETAT_JOURNAL
             , CFL.PC_LANG_ID PC_LANG_ID
          from ACJ_SUB_SET_CAT SUB
             , ACT_DOCUMENT DOC
             , ACS_FINANCIAL_YEAR FYE
             , ACS_PERIOD PER
             , ACS_ACCOUNT ACC
             , ACS_FINANCIAL_ACCOUNT FIN
             , ACS_FINANCIAL_CURRENCY CUR
             , ACT_FINANCIAL_IMPUTATION IMF
             , CLASSIF_FLAT CFL
             , table(RPT_FUNCTIONS.TableAuthRptDivisions(vpc_user_id, vlstdivisions) ) AUT
         where CFL.CLASSIFICATION_ID = procparam_5
           and CFL.CLASSIF_LEAF_ID = IMF.ACS_FINANCIAL_ACCOUNT_ID
           and IMF.ACS_ACS_FINANCIAL_CURRENCY_ID = CUR.ACS_FINANCIAL_CURRENCY_ID
           and IMF.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and FIN.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and IMF.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SUB.ACJ_CATALOGUE_DOCUMENT_ID
           and SUB.C_SUB_SET = 'ACC'
           and FYE.FYE_NO_EXERCICE = procparam_0
           and FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
           and nvl(ACS_FUNCTION.GetStatePreviousFinancialYear(FYE.ACS_FINANCIAL_YEAR_ID), 'CLO') = 'CLO'
           and PER.ACS_PERIOD_ID = IMF.ACS_PERIOD_ID
           and PER.C_TYPE_PERIOD = '1'
           and trunc(to_date(procparam_3, 'YYYYMMDD') ) <=(case parameter_7
                                                             when '0' then trunc(IMF.IMF_VALUE_DATE)
                                                             else trunc(IMF.IMF_TRANSACTION_DATE)
                                                           end)
           and trunc(to_date(procparam_4, 'YYYYMMDD') ) >=(case parameter_7
                                                             when '0' then trunc(IMF.IMF_VALUE_DATE)
                                                             else trunc(IMF.IMF_TRANSACTION_DATE)
                                                           end)
           and (parameter_5 is not null)
           and IMF.IMF_ACS_DIVISION_ACCOUNT_ID is not null
           and AUT.column_value = IMF.IMF_ACS_DIVISION_ACCOUNT_ID
      group by CFL.LEAF_DESCR
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
             , IMF.ACS_PERIOD_ID
             , PER.C_TYPE_PERIOD
             , SUB.C_TYPE_CUMUL
             , IMF.ACS_FINANCIAL_ACCOUNT_ID
             , ACC.ACC_NUMBER
             , FIN.C_BALANCE_DISPLAY
             , IMF.IMF_ACS_DIVISION_ACCOUNT_ID
             , IMF.ACS_ACS_FINANCIAL_CURRENCY_ID
             , ACS_FUNCTION.GetLocalCurrencyName
             , IMF.ACS_FINANCIAL_CURRENCY_ID
             , ACT_FUNCTIONS.GetBROState(DOC.ACT_JOURNAL_ID, 'ACC')
             , CFL.PC_LANG_ID
      union all
      select   trim(CFL.LEAF_DESCR) LEAF_DESCR
             , CFL.NODE01 NODE01
             , CFL.NODE02 NODE02
             , CFL.NODE03 NODE03
             , CFL.NODE04 NODE04
             , CFL.NODE05 NODE05
             , CFL.NODE06 NODE06
             , CFL.NODE07 NODE07
             , CFL.NODE08 NODE08
             , CFL.NODE09 NODE09
             , CFL.NODE10 NODE10
             , TOT.ACS_PERIOD_ID ACS_PERIOD_ID
             , PER.C_TYPE_PERIOD C_TYPE_PERIOD
             , TOT.C_TYPE_CUMUL C_TYPE_CUMUL
             , TOT.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
             , ACC.ACC_NUMBER ACC_NUMBER_FIN
             , FIN.C_BALANCE_DISPLAY C_BALANCE_DISPLAY
             , TOT.ACS_DIVISION_ACCOUNT_ID
             , (select ACC.ACC_NUMBER
                  from ACS_ACCOUNT ACC
                 where ACC.ACS_ACCOUNT_ID = TOT.ACS_DIVISION_ACCOUNT_ID) ACC_NUMBER_DIV
             , TOT.ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID
             , ACS_FUNCTION.GetLocalCurrencyName LOCAL_CURRENCY_NAME
             , sum(TOT.TOT_DEBIT_LC) AMOUNT_LC_D
             , sum(TOT.TOT_CREDIT_LC) AMOUNT_LC_C
             , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID
             , (select CU1.CURRENCY
                  from PCS.PC_CURR CU1
                     , ACS_FINANCIAL_CURRENCY CF1
                 where CF1.ACS_FINANCIAL_CURRENCY_ID = TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
                   and CU1.PC_CURR_ID = CF1.PC_CURR_ID) CURRENCY_ME
             , sum(TOT.TOT_DEBIT_FC) AMOUNT_FC_D
             , sum(TOT.TOT_CREDIT_FC) AMOUNT_FC_C
             , 0 C_ETAT_JOURNAL
             , CFL.PC_LANG_ID PC_LANG_ID
          from ACS_FINANCIAL_CURRENCY CUR
             , ACS_ACCOUNT ACC
             , ACS_FINANCIAL_ACCOUNT FIN
             , ACT_TOTAL_BY_PERIOD TOT
             , ACS_FINANCIAL_YEAR FYE
             , ACS_PERIOD PER
             , CLASSIF_FLAT CFL
             , table(RPT_FUNCTIONS.TableAuthRptDivisions(vpc_user_id, vlstdivisions) ) AUT
         where CFL.CLASSIFICATION_ID = procparam_5
           and CFL.CLASSIF_LEAF_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID
           and TOT.ACS_FINANCIAL_CURRENCY_ID = CUR.ACS_FINANCIAL_CURRENCY_ID
           and TOT.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and FIN.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and FYE.FYE_NO_EXERCICE = procparam_0
           and ACS_FUNCTION.GetStatePreviousFinancialYear(FYE.ACS_FINANCIAL_YEAR_ID) = 'ACT'
           and FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
           and PER.ACS_PERIOD_ID = TOT.ACS_PERIOD_ID
           and PER.C_TYPE_PERIOD = '1'
           and trunc(PER.PER_START_DATE) >= trunc(to_date(procparam_3, 'YYYYMMDD') )
           and trunc(PER.PER_END_DATE) <= trunc(to_date(procparam_4, 'YYYYMMDD') )
           and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
           and (    (TOT.ACS_DIVISION_ACCOUNT_ID is not null)
                or (    TOT.ACS_DIVISION_ACCOUNT_ID is null
                    and ACR_FUNCTIONS.ExistDivision = 0) )
           and (parameter_5 is not null)
           and TOT.ACS_DIVISION_ACCOUNT_ID is not null
           and AUT.column_value = TOT.ACS_DIVISION_ACCOUNT_ID
      group by CFL.LEAF_DESCR
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
             , TOT.ACS_PERIOD_ID
             , PER.C_TYPE_PERIOD
             , TOT.C_TYPE_CUMUL
             , TOT.ACS_FINANCIAL_ACCOUNT_ID
             , ACC.ACC_NUMBER
             , FIN.C_BALANCE_DISPLAY
             , TOT.ACS_DIVISION_ACCOUNT_ID
             , TOT.ACS_FINANCIAL_CURRENCY_ID
             , ACS_FUNCTION.GetLocalCurrencyName
             , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
             , '  '
             , CFL.PC_LANG_ID;
  end if;
else    -- if (ACS_FUNCTION.ExistDIVI = 0) = No divisions
  if     (procparam_3 is null)
     and (procparam_4 is null) then
    open aRefCursor for
      select trim(CFL.LEAF_DESCR) LEAF_DESCR
           , CFL.NODE01 NODE01
           , CFL.NODE02 NODE02
           , CFL.NODE03 NODE03
           , CFL.NODE04 NODE04
           , CFL.NODE05 NODE05
           , CFL.NODE06 NODE06
           , CFL.NODE07 NODE07
           , CFL.NODE08 NODE08
           , CFL.NODE09 NODE09
           , CFL.NODE10 NODE10
           , TOT.ACS_PERIOD_ID ACS_PERIOD_ID
           , TOT.C_TYPE_PERIOD C_TYPE_PERIOD
           , TOT.C_TYPE_CUMUL C_TYPE_CUMUL
           , TOT.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
           , ACC.ACC_NUMBER ACC_NUMBER_FIN
           , FIN.C_BALANCE_DISPLAY C_BALANCE_DISPLAY
           , TOT.ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
           , (select ACC.ACC_NUMBER
                from ACS_ACCOUNT ACC
               where ACC.ACS_ACCOUNT_ID = TOT.ACS_DIVISION_ACCOUNT_ID) ACC_NUMBER_DIV
           , TOT.ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID
           , ACS_FUNCTION.GetLocalCurrencyName LOCAL_CURRENCY_NAME
           , TOT.TOT_DEBIT_LC AMOUNT_LC_D
           , TOT.TOT_CREDIT_LC AMOUNT_LC_C
           , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID
           , (select CU1.CURRENCY
                from PCS.PC_CURR CU1
                   , ACS_FINANCIAL_CURRENCY CF1
               where CF1.ACS_FINANCIAL_CURRENCY_ID = TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
                 and CU1.PC_CURR_ID = CF1.PC_CURR_ID) CURRENCY_ME
           , TOT.TOT_DEBIT_FC AMOUNT_FC_D
           , TOT.TOT_CREDIT_FC AMOUNT_FC_C
           , 0 C_ETAT_JOURNAL
           , CFL.PC_LANG_ID PC_LANG_ID
        from ACS_FINANCIAL_YEAR FYE
           , ACS_PERIOD PER
           , ACS_FINANCIAL_ACCOUNT FIN
           , ACS_ACCOUNT ACC
           , ACS_FINANCIAL_CURRENCY CUR
           , ACT_TOTAL_BY_PERIOD TOT
           , CLASSIF_FLAT CFL
       where CFL.CLASSIFICATION_ID = procparam_5
         and CFL.CLASSIF_LEAF_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID
         and TOT.ACS_FINANCIAL_CURRENCY_ID = CUR.ACS_FINANCIAL_CURRENCY_ID
         and TOT.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
         and FIN.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
         and FYE.FYE_NO_EXERCICE = procparam_0
         and FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
         and PER.PER_NO_PERIOD >= procparam_1
         and PER.PER_NO_PERIOD <= procparam_2
         and PER.ACS_PERIOD_ID = TOT.ACS_PERIOD_ID
         and TOT.ACS_AUXILIARY_ACCOUNT_ID is null;
  else
    open aRefCursor for
      select   trim(CFL.LEAF_DESCR) LEAF_DESCR
             , CFL.NODE01 NODE01
             , CFL.NODE02 NODE02
             , CFL.NODE03 NODE03
             , CFL.NODE04 NODE04
             , CFL.NODE05 NODE05
             , CFL.NODE06 NODE06
             , CFL.NODE07 NODE07
             , CFL.NODE08 NODE08
             , CFL.NODE09 NODE09
             , CFL.NODE10 NODE10
             , IMF.ACS_PERIOD_ID ACS_PERIOD_ID
             , PER.C_TYPE_PERIOD C_TYPE_PERIOD
             , SUB.C_TYPE_CUMUL C_TYPE_CUMUL
             , IMF.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
             , ACC.ACC_NUMBER ACC_NUMBER_FIN
             , FIN.C_BALANCE_DISPLAY C_BALANCE_DISPLAY
             , IMF.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
             , (select ACC.ACC_NUMBER
                  from ACS_ACCOUNT ACC
                 where ACC.ACS_ACCOUNT_ID = IMF.IMF_ACS_DIVISION_ACCOUNT_ID) ACC_NUMBER_DIV
             , IMF.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID
             , ACS_FUNCTION.GetLocalCurrencyName LOCAL_CURRENCY_NAME
             , sum(IMF.IMF_AMOUNT_LC_D) AMOUNT_LC_D
             , sum(IMF.IMF_AMOUNT_LC_C) AMOUNT_LC_C
             , IMF.ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID
             , (select CU1.CURRENCY
                  from PCS.PC_CURR CU1
                     , ACS_FINANCIAL_CURRENCY CF1
                 where CF1.ACS_FINANCIAL_CURRENCY_ID = IMF.ACS_FINANCIAL_CURRENCY_ID
                   and CU1.PC_CURR_ID = CF1.PC_CURR_ID) CURRENCY_ME
             , sum(IMF.IMF_AMOUNT_FC_D) AMOUNT_FC_D
             , sum(IMF.IMF_AMOUNT_FC_C) AMOUNT_FC_C
             , ACT_FUNCTIONS.GetBROState(DOC.ACT_JOURNAL_ID, 'ACC') C_ETAT_JOURNAL
             , CFL.PC_LANG_ID PC_LANG_ID
          from ACJ_SUB_SET_CAT SUB
             , ACT_DOCUMENT DOC
             , ACS_FINANCIAL_YEAR FYE
             , ACS_PERIOD PER
             , ACS_ACCOUNT ACC
             , ACS_FINANCIAL_ACCOUNT FIN
             , ACS_FINANCIAL_CURRENCY CUR
             , ACT_FINANCIAL_IMPUTATION IMF
             , CLASSIF_FLAT CFL
         where CFL.CLASSIFICATION_ID = procparam_5
           and CFL.CLASSIF_LEAF_ID = IMF.ACS_FINANCIAL_ACCOUNT_ID
           and IMF.ACS_ACS_FINANCIAL_CURRENCY_ID = CUR.ACS_FINANCIAL_CURRENCY_ID
           and IMF.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and FIN.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and IMF.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SUB.ACJ_CATALOGUE_DOCUMENT_ID
           and SUB.C_SUB_SET = 'ACC'
           and FYE.FYE_NO_EXERCICE = procparam_0
           and FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
           and PER.ACS_PERIOD_ID = IMF.ACS_PERIOD_ID
           and PER.C_TYPE_PERIOD <> '1'
           and trunc(to_date(procparam_3, 'YYYYMMDD') ) <=(case parameter_7
                                                             when '0' then trunc(IMF.IMF_VALUE_DATE)
                                                             else trunc(IMF.IMF_TRANSACTION_DATE)
                                                           end)
           and trunc(to_date(procparam_4, 'YYYYMMDD') ) >=(case parameter_7
                                                             when '0' then trunc(IMF.IMF_VALUE_DATE)
                                                             else trunc(IMF.IMF_TRANSACTION_DATE)
                                                           end)
      group by CFL.LEAF_DESCR
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
             , IMF.ACS_PERIOD_ID
             , PER.C_TYPE_PERIOD
             , SUB.C_TYPE_CUMUL
             , IMF.ACS_FINANCIAL_ACCOUNT_ID
             , ACC.ACC_NUMBER
             , FIN.C_BALANCE_DISPLAY
             , IMF.IMF_ACS_DIVISION_ACCOUNT_ID
             , IMF.ACS_ACS_FINANCIAL_CURRENCY_ID
             , ACS_FUNCTION.GetLocalCurrencyName
             , IMF.ACS_FINANCIAL_CURRENCY_ID
             , ACT_FUNCTIONS.GetBROState(DOC.ACT_JOURNAL_ID, 'ACC')
             , CFL.PC_LANG_ID
      union all
      select   trim(CFL.LEAF_DESCR) LEAF_DESCR
             , CFL.NODE01 NODE01
             , CFL.NODE02 NODE02
             , CFL.NODE03 NODE03
             , CFL.NODE04 NODE04
             , CFL.NODE05 NODE05
             , CFL.NODE06 NODE06
             , CFL.NODE07 NODE07
             , CFL.NODE08 NODE08
             , CFL.NODE09 NODE09
             , CFL.NODE10 NODE10
             , IMF.ACS_PERIOD_ID ACS_PERIOD_ID
             , PER.C_TYPE_PERIOD C_TYPE_PERIOD
             , SUB.C_TYPE_CUMUL C_TYPE_CUMUL
             , IMF.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
             , ACC.ACC_NUMBER ACC_NUMBER_FIN
             , FIN.C_BALANCE_DISPLAY C_BALANCE_DISPLAY
             , IMF.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
             , (select ACC.ACC_NUMBER
                  from ACS_ACCOUNT ACC
                 where ACC.ACS_ACCOUNT_ID = IMF.IMF_ACS_DIVISION_ACCOUNT_ID) ACC_NUMBER_DIV
             , IMF.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID
             , ACS_FUNCTION.GetLocalCurrencyName LOCAL_CURRENCY_NAME
             , sum(IMF.IMF_AMOUNT_LC_D) AMOUNT_LC_D
             , sum(IMF.IMF_AMOUNT_LC_C) AMOUNT_LC_C
             , IMF.ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID
             , (select CU1.CURRENCY
                  from PCS.PC_CURR CU1
                     , ACS_FINANCIAL_CURRENCY CF1
                 where CF1.ACS_FINANCIAL_CURRENCY_ID = IMF.ACS_FINANCIAL_CURRENCY_ID
                   and CU1.PC_CURR_ID = CF1.PC_CURR_ID) CURRENCY_ME
             , sum(IMF.IMF_AMOUNT_FC_D) AMOUNT_FC_D
             , sum(IMF.IMF_AMOUNT_FC_C) AMOUNT_FC_C
             , ACT_FUNCTIONS.GetBROState(DOC.ACT_JOURNAL_ID, 'ACC') C_ETAT_JOURNAL
             , CFL.PC_LANG_ID PC_LANG_ID
          from ACJ_SUB_SET_CAT SUB
             , ACT_DOCUMENT DOC
             , ACS_FINANCIAL_YEAR FYE
             , ACS_PERIOD PER
             , ACS_ACCOUNT ACC
             , ACS_FINANCIAL_ACCOUNT FIN
             , ACS_FINANCIAL_CURRENCY CUR
             , ACT_FINANCIAL_IMPUTATION IMF
             , CLASSIF_FLAT CFL
         where CFL.CLASSIFICATION_ID = procparam_5
           and CFL.CLASSIF_LEAF_ID = IMF.ACS_FINANCIAL_ACCOUNT_ID
           and IMF.ACS_ACS_FINANCIAL_CURRENCY_ID = CUR.ACS_FINANCIAL_CURRENCY_ID
           and IMF.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and FIN.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and IMF.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SUB.ACJ_CATALOGUE_DOCUMENT_ID
           and SUB.C_SUB_SET = 'ACC'
           and FYE.FYE_NO_EXERCICE = procparam_0
           and FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
           and nvl(ACS_FUNCTION.GetStatePreviousFinancialYear(FYE.ACS_FINANCIAL_YEAR_ID), 'CLO') = 'CLO'
           and PER.ACS_PERIOD_ID = IMF.ACS_PERIOD_ID
           and PER.C_TYPE_PERIOD = '1'
           and trunc(to_date(procparam_3, 'YYYYMMDD') ) <=(case parameter_7
                                                             when '0' then trunc(IMF.IMF_VALUE_DATE)
                                                             else trunc(IMF.IMF_TRANSACTION_DATE)
                                                           end)
           and trunc(to_date(procparam_4, 'YYYYMMDD') ) >=(case parameter_7
                                                             when '0' then trunc(IMF.IMF_VALUE_DATE)
                                                             else trunc(IMF.IMF_TRANSACTION_DATE)
                                                           end)
      group by CFL.LEAF_DESCR
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
             , IMF.ACS_PERIOD_ID
             , PER.C_TYPE_PERIOD
             , SUB.C_TYPE_CUMUL
             , IMF.ACS_FINANCIAL_ACCOUNT_ID
             , ACC.ACC_NUMBER
             , FIN.C_BALANCE_DISPLAY
             , IMF.IMF_ACS_DIVISION_ACCOUNT_ID
             , IMF.ACS_ACS_FINANCIAL_CURRENCY_ID
             , ACS_FUNCTION.GetLocalCurrencyName
             , IMF.ACS_FINANCIAL_CURRENCY_ID
             , ACT_FUNCTIONS.GetBROState(DOC.ACT_JOURNAL_ID, 'ACC')
             , CFL.PC_LANG_ID
      union all
      select   trim(CFL.LEAF_DESCR) LEAF_DESCR
             , CFL.NODE01 NODE01
             , CFL.NODE02 NODE02
             , CFL.NODE03 NODE03
             , CFL.NODE04 NODE04
             , CFL.NODE05 NODE05
             , CFL.NODE06 NODE06
             , CFL.NODE07 NODE07
             , CFL.NODE08 NODE08
             , CFL.NODE09 NODE09
             , CFL.NODE10 NODE10
             , TOT.ACS_PERIOD_ID ACS_PERIOD_ID
             , PER.C_TYPE_PERIOD C_TYPE_PERIOD
             , TOT.C_TYPE_CUMUL C_TYPE_CUMUL
             , TOT.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
             , ACC.ACC_NUMBER ACC_NUMBER_FIN
             , FIN.C_BALANCE_DISPLAY C_BALANCE_DISPLAY
             , TOT.ACS_DIVISION_ACCOUNT_ID
             , (select ACC.ACC_NUMBER
                  from ACS_ACCOUNT ACC
                 where ACC.ACS_ACCOUNT_ID = TOT.ACS_DIVISION_ACCOUNT_ID) ACC_NUMBER_DIV
             , TOT.ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID
             , ACS_FUNCTION.GetLocalCurrencyName LOCAL_CURRENCY_NAME
             , sum(TOT.TOT_DEBIT_LC) AMOUNT_LC_D
             , sum(TOT.TOT_CREDIT_LC) AMOUNT_LC_C
             , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID
             , (select CU1.CURRENCY
                  from PCS.PC_CURR CU1
                     , ACS_FINANCIAL_CURRENCY CF1
                 where CF1.ACS_FINANCIAL_CURRENCY_ID = TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
                   and CU1.PC_CURR_ID = CF1.PC_CURR_ID) CURRENCY_ME
             , sum(TOT.TOT_DEBIT_FC) AMOUNT_FC_D
             , sum(TOT.TOT_CREDIT_FC) AMOUNT_FC_C
             , 0 C_ETAT_JOURNAL
             , CFL.PC_LANG_ID PC_LANG_ID
          from ACS_FINANCIAL_CURRENCY CUR
             , ACS_ACCOUNT ACC
             , ACS_FINANCIAL_ACCOUNT FIN
             , ACT_TOTAL_BY_PERIOD TOT
             , ACS_FINANCIAL_YEAR FYE
             , ACS_PERIOD PER
             , CLASSIF_FLAT CFL
         where CFL.CLASSIFICATION_ID = procparam_5
           and CFL.CLASSIF_LEAF_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID
           and TOT.ACS_FINANCIAL_CURRENCY_ID = CUR.ACS_FINANCIAL_CURRENCY_ID
           and TOT.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and FIN.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and FYE.FYE_NO_EXERCICE = procparam_0
           and ACS_FUNCTION.GetStatePreviousFinancialYear(FYE.ACS_FINANCIAL_YEAR_ID) = 'ACT'
           and FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
           and PER.ACS_PERIOD_ID = TOT.ACS_PERIOD_ID
           and PER.C_TYPE_PERIOD = '1'
           and trunc(PER.PER_START_DATE) >= trunc(to_date(procparam_3, 'YYYYMMDD') )
           and trunc(PER.PER_END_DATE) <= trunc(to_date(procparam_4, 'YYYYMMDD') )
           and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
           and (    (TOT.ACS_DIVISION_ACCOUNT_ID is not null)
                or (    TOT.ACS_DIVISION_ACCOUNT_ID is null
                    and ACR_FUNCTIONS.ExistDivision = 0) )
      group by CFL.LEAF_DESCR
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
             , TOT.ACS_PERIOD_ID
             , PER.C_TYPE_PERIOD
             , TOT.C_TYPE_CUMUL
             , TOT.ACS_FINANCIAL_ACCOUNT_ID
             , ACC.ACC_NUMBER
             , FIN.C_BALANCE_DISPLAY
             , TOT.ACS_DIVISION_ACCOUNT_ID
             , TOT.ACS_FINANCIAL_CURRENCY_ID
             , ACS_FUNCTION.GetLocalCurrencyName
             , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
             , '  '
             , CFL.PC_LANG_ID;
  end if;
  end if;
end RPT_ACR_ACC_BALANCE_STR;
