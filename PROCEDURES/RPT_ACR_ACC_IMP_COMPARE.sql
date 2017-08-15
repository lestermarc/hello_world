--------------------------------------------------------
--  DDL for Procedure RPT_ACR_ACC_IMP_COMPARE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACR_ACC_IMP_COMPARE" (
  aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, procparam_0    in     varchar2
, procparam_1    in     varchar2
, procparam_2    in     varchar2
, procparam_3    in     varchar2
, procparam_4    in     varchar2
, procparam_5    in     varchar2
, procparam_6    in     varchar2
, procparam_7    in     varchar2
, procparam_8    in     varchar2
, parameter_2    in     varchar2
, parameter_3    in     varchar2
, parameter_4    in     varchar2
, parameter_5    in     varchar2
, parameter_6    in     varchar2
, parameter_9    in     varchar2
, procuser_lanid in     pcs.pc_lang.lanid%type
, pc_user_id     in     PCS.PC_USER.PC_USER_ID%type
)
/**
* description used for report ACR_ACC_IMPUTATION_COMPARE

* @author jliu 18 nov 2008
* @lastUpdate SMA 19.03.2014
* @public
* @param procparam_0    ACS_FINANCIAL_YEAR_ID
* @param procparam_1    ACC_NUMBER from
* @param procparam_2    ACC_NUMBER to
* @param procparam_3    Division_ID (List) NULL = All  or ACS_DIVISION_ACCOUNT_ID list
* @param procparam_4    Date from (yyyyMMdd)
* @param procparam_5    Date to (yyyyMMdd)
* @param procparam_6    Journal status = BRO : 1=Yes / 0=No
* @param procparam_7    Journal status = PROV : 1=Yes / 0=No
* @param procparam_8    Journal status = DEF : 1=Yes / 0=No

* @param parameter_2    Compare code : '0'=all / '1'=compared / '2'=not compared
* @param parameter_3    C_TYPE_CUMUL = 'INT' :  0=No / 1=Yes
* @param parameter_4    C_TYPE_CUMUL = 'EXT' :  0=No / 1=Yes
* @param parameter_5    C_TYPE_CUMUL = 'PRE' :  0=No / 1=Yes
* @param parameter_6    C_TYPE_CUMUL = 'ENG' :  0=No / 1=Yes
* @param parameter_9    Only transaction without VAT
*/
is
  vpc_lang_id PCS.PC_LANG.PC_LANG_ID%type := null;
  vpc_user_id PCS.PC_USER.PC_USER_ID%type := null;
begin
  if (procuser_lanid is not null) and (pc_user_id is not null)  then
    PCS.PC_LIB_SESSION.setLanUserId(iLanId    => procuser_lanid
                                  , iPcUserId => pc_user_id
                                  , iPcCompId => null
                                  , iConliId  => null);
      vpc_lang_id  := PCS.PC_I_LIB_SESSION.getUserlangId;
      vpc_user_id  := PCS.PC_I_LIB_SESSION.getUserId;
  end if;

  if     (procparam_0 is not null)
     and (length(trim(procparam_0) ) > 0) then
    ACR_FUNCTIONS.FIN_YEAR_ID  := procparam_0;
  end if;

  if ACS_FUNCTION.GetFirstDivision is not null then
    ACR_FUNCTIONS.EXIST_DIVISION  := 1;
  else
    ACR_FUNCTIONS.EXIST_DIVISION  := 0;
  end if;

  if     (procparam_1 is not null)
     and (length(trim(procparam_1) ) > 0) then
    ACR_FUNCTIONS.ACC_NUMBER1  := procparam_1;
  else
    ACR_FUNCTIONS.ACC_NUMBER1  := '';
  end if;

  if     (procparam_2 is not null)
     and (length(trim(procparam_2) ) > 0) then
    ACR_FUNCTIONS.ACC_NUMBER2  := procparam_2;
  end if;

  if (ACS_FUNCTION.ExistDIVI = 1) then
  open aRefCursor for
    select (case
              when(V_IMP.IMF_COMPARE_DATE is not null)
                    and (V_IMP.ACT_JOURNAL_ID is not null) then 'COMPARED'
              when CAT.CAT_DESCRIPTION <> '7' then
                    case
                        when   (V_IMP.IMF_COMPARE_DATE is null)
                            and (V_IMP.ACT_JOURNAL_ID is not null)
                            and (JOU.C_TYPE_JOURNAL <> 'OPB') then 'NOT_COMPARED'
                        else ''
                    end
              else ''
            end
           ) INFO
         , FYR.ACS_FINANCIAL_YEAR_ID
         , ACS_FUNCTION.REPORTAMOUNT(V_ACC.ACS_FINANCIAL_ACCOUNT_ID, FYR.ACS_FINANCIAL_YEAR_ID, 'EXT', 1, 0) REPORT_AMOUNT
         , V_ACC.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
         , V_ACC.ACC_NUMBER ACC_NUMBER
         , V_ACC.ACC_DETAIL_PRINTING ACC_DETAIL_PRINTING
         , V_ACC.DES_DESCRIPTION_SUMMARY DES_DESCRIPTION_SUMMARY
         , V_ACC.DES_DESCRIPTION_LARGE DES_DESCRIPTION_LARGE
         , ACS_FUNCTION.isFinAccountInME(V_ACC.ACS_FINANCIAL_ACCOUNT_ID) isFinAccountInME
         , V_IMP.ACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION_ID
         , V_IMP.ACT_DOCUMENT_ID V_ACT_DOCUMENT_ID
         , V_IMP.ACS_FINANCIAL_ACCOUNT_ID V_ACS_FINANCIAL_ACCOUNT_ID
         , V_IMP.IMF_TYPE IMF_TYPE
         , V_IMP.IMF_DESCRIPTION IMF_DESCRIPTION
         , V_IMP.IMF_AMOUNT_LC_D IMF_AMOUNT_LC_D
         , V_IMP.IMF_AMOUNT_LC_C IMF_AMOUNT_LC_C
         , V_IMP.IMF_EXCHANGE_RATE IMF_EXCHANGE_RATE
         , V_IMP.IMF_AMOUNT_FC_D IMF_AMOUNT_FC_D
         , V_IMP.IMF_AMOUNT_FC_C IMF_AMOUNT_FC_C
         , V_IMP.IMF_VALUE_DATE IMF_VALUE_DATE
         , V_IMP.ACS_TAX_CODE_ID ACS_TAX_CODE_ID
         , V_IMP.IMF_TRANSACTION_DATE IMF_TRANSACTION_DATE
         , V_IMP.ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID
         , V_IMP.ACS_AUXILIARY_ACCOUNT_ID ACS_AUXILIARY_ACCOUNT_ID
         , DES_AUX.DES_DESCRIPTION_SUMMARY AUX_DESCRIPTION_SUMMARY
         , V_IMP.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID
         , V_IMP.DOC_DATE_DELIVERY DOC_DATE_DELIVERY
         , V_IMP.ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
         , V_IMP.DIV_NUMBER DIV_NUMBER
         , DES_DIV.DES_DESCRIPTION_SUMMARY DIV_DES_DESCRIPTION_SUMMARY
         , V_IMP.C_ETAT_JOURNAL C_ETAT_JOURNAL
         , V_IMP.C_TYPE_CUMUL C_TYPE_CUMUL
         , V_IMP.IMF_COMPARE_DATE IMF_COMPARE_DATE
         , V_IMP.IMF_COMPARE_TEXT IMF_COMPARE_TEXT
         , V_IMP.IMF_COMPARE_USE_INI IMF_COMPARE_USE_INI
         , CAT.C_TYPE_CATALOGUE C_TYPE_CATALOGUE
         , CAT.CAT_DESCRIPTION CAT_DESCRIPTION
         , AUX.ACC_NUMBER AUX_ACC_NUMBER
         , FIN.ACC_NUMBER FIN_ACC_NUMBER
         , VAT.ACS_ACCOUNT_ID VAT_ACS_ACCOUNT_ID
         , VAT.ACC_NUMBER VAT_ACC_NUMBER
         , FUR.PC_CURR_ID FUR_PC_CURR_ID
         , FUR_LC.PC_CURR_ID FUR_PC_CURR_ID_LC
         , TDO.ACT_DOCUMENT_ID ACT_DOCUMENT_ID
         , TDO.DOC_NUMBER DOC_NUMBER
         , JOU.JOU_DESCRIPTION JOU_DESCRIPTION
         , JOU.C_TYPE_JOURNAL C_TYPE_JOURNAL
         , JOU.JOU_NUMBER JOU_NUMBER
         , CUR.PC_CURR_ID CUR_PC_CURR_ID
         , CUR_LC.PC_CURR_ID CUR_PC_CURR_ID_LC
         , CUR.CURRENCY CUR_CURRENCY
         , CUR_LC.CURRENCY CUR_CURRENCY_LC
         , LAN.LANID LANID
         , PRD.C_TYPE_PERIOD C_TYPE_PERIOD
         , ACR_FUNCTIONS.GetReportAmountCompared(V_ACC.ACS_FINANCIAL_ACCOUNT_ID, null, to_date(procparam_4, 'yyyyMMdd') -1, 1) RPT_COMPARED_AMOUNT
         , ACR_FUNCTIONS.GetReportAmountCompared(V_ACC.ACS_FINANCIAL_ACCOUNT_ID, V_IMP.ACS_DIVISION_ACCOUNT_ID, to_date(procparam_4, 'yyyyMMdd') -1, 1) RPT_COMPARED_AMOUNT_DIV
         , ACR_FUNCTIONS.GetReportAmountCompared(V_ACC.ACS_FINANCIAL_ACCOUNT_ID, null, to_date(procparam_4, 'yyyyMMdd') -1, 0) RPT_NOT_COMPARED_AMOUNT
         , ACR_FUNCTIONS.GetReportAmountCompared(V_ACC.ACS_FINANCIAL_ACCOUNT_ID, V_IMP.ACS_DIVISION_ACCOUNT_ID, to_date(procparam_4, 'yyyyMMdd') -1, 0) RPT_NOT_COMPARED_AMOUNT_DIV
         , ACR_FUNCTIONS.GetReportAmountCompared(V_ACC.ACS_FINANCIAL_ACCOUNT_ID, null, to_date(procparam_4, 'yyyyMMdd') -1, 1, rpt_functions.getFinancialCurrencyId(V_IMP.ACS_FINANCIAL_ACCOUNT_ID)) RPT_COMPARED_AMOUNT_ME
         , ACR_FUNCTIONS.GetReportAmountCompared(V_ACC.ACS_FINANCIAL_ACCOUNT_ID, V_IMP.ACS_DIVISION_ACCOUNT_ID, to_date(procparam_4, 'yyyyMMdd') -1, 1, rpt_functions.getFinancialCurrencyId(V_IMP.ACS_FINANCIAL_ACCOUNT_ID)) RPT_COMPARED_AMOUNT_DIV_ME
         , ACR_FUNCTIONS.GetReportAmountCompared(V_ACC.ACS_FINANCIAL_ACCOUNT_ID, null, to_date(procparam_4, 'yyyyMMdd') -1, 0, rpt_functions.getFinancialCurrencyId(V_IMP.ACS_FINANCIAL_ACCOUNT_ID)) RPT_NOT_COMPARED_AMOUNT_ME
         , ACR_FUNCTIONS.GetReportAmountCompared(V_ACC.ACS_FINANCIAL_ACCOUNT_ID, V_IMP.ACS_DIVISION_ACCOUNT_ID, to_date(procparam_4, 'yyyyMMdd') -1, 0, rpt_functions.getFinancialCurrencyId(V_IMP.ACS_FINANCIAL_ACCOUNT_ID)) RPT_NOT_COMPARED_AMOUNT_DIV_ME
         , BAL.TOTAL_LC_D
         , BAL.TOTAL_LC_C
         , BAL.TOTAL_FC_D
         , BAL.TOTAL_FC_C
         , BAL.CURRENCY_MB
         , cast(rpt_functions.getCurrencyId(V_IMP.ACS_FINANCIAL_ACCOUNT_ID) as varchar2(5)) CURRENCY_ME
      from V_ACS_FINANCIAL_ACCOUNT V_ACC
         , V_ACT_ACC_IMP_REPORT V_IMP
         , (select ACS_ACCOUNT_ID
                 , DES_DESCRIPTION_SUMMARY
              from ACS_DESCRIPTION
             where PC_LANG_ID = VPC_LANG_ID) DES_DIV
         , (select ACS_ACCOUNT_ID
                 , DES_DESCRIPTION_SUMMARY
              from ACS_DESCRIPTION
             where PC_LANG_ID = VPC_LANG_ID) DES_AUX
         , ACS_PERIOD PRD
         , ACS_FINANCIAL_YEAR FYR
         , ACT_DOCUMENT TDO
         , ACJ_CATALOGUE_DOCUMENT CAT
         , ACT_JOURNAL JOU
         , ACS_ACCOUNT AUX
         , ACS_ACCOUNT FIN
         , ACS_ACCOUNT VAT
         , ACS_FINANCIAL_CURRENCY FUR
         , ACS_FINANCIAL_CURRENCY FUR_LC
         , ACT_FINANCIAL_IMPUTATION IMP
         , PCS.PC_CURR CUR
         , PCS.PC_CURR CUR_LC
         , PCS.PC_LANG LAN
         , (select ACS_FINANCIAL_ACCOUNT_ID
                   , sum(TOTAL_LC_D) TOTAL_LC_D
                   , sum(TOTAL_LC_C) TOTAL_LC_C
                   , sum(TOTAL_FC_D) TOTAL_FC_D
                   , sum(TOTAL_FC_C) TOTAL_FC_C
                   , CURRENCY_MB
            from
              (select   FIN.ACS_FINANCIAL_ACCOUNT_ID
                       , sum(TOT.TOT_DEBIT_LC) TOTAL_LC_D
                       , sum(TOT.TOT_CREDIT_LC) TOTAL_LC_C
                       , sum(TOT.TOT_DEBIT_FC) TOTAL_FC_D
                       , sum(TOT.TOT_CREDIT_FC) TOTAL_FC_C
                       , CUB.CURRENCY CURRENCY_MB
                    from ACS_FINANCIAL_YEAR FYE
                       , ACS_PERIOD PER
                       , ACS_FINANCIAL_ACCOUNT FIN
                       , ACT_TOTAL_BY_PERIOD TOT
                       , PCS.PC_CURR CUB
                       , ACS_FINANCIAL_CURRENCY CFB
                       , table(RPT_FUNCTIONS.TableAuthRptDivisions(vpc_user_id, procparam_3) ) AUT
                   where FIN.ACS_FINANCIAL_ACCOUNT_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID
                     and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
                     and FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
                     and PER.ACS_PERIOD_ID = TOT.ACS_PERIOD_ID
                     and PER.C_TYPE_PERIOD = '1'
                     and CFB.ACS_FINANCIAL_CURRENCY_ID = TOT.ACS_FINANCIAL_CURRENCY_ID
                     and CUB.PC_CURR_ID = CFB.PC_CURR_ID
                     and (    (TOT.ACS_DIVISION_ACCOUNT_ID is not null)
                          or (    TOT.ACS_DIVISION_ACCOUNT_ID is null
                              and ACR_FUNCTIONS.ExistDivision = 0) )
                     and TOT.ACS_DIVISION_ACCOUNT_ID is not null
                     and AUT.column_value = TOT.ACS_DIVISION_ACCOUNT_ID
                     and to_date(procparam_4, 'yyyyMMdd') between FYE.FYE_START_DATE and FYE.FYE_END_DATE
                     and procparam_7 = 1
                     and decode(TOT.C_TYPE_CUMUL
                              , 'INT', decode(parameter_3, '1', 1, 0)
                              , 'EXT', decode(parameter_4, '1', 1, 0)
                              , 'PRE', decode(parameter_5, '1', 1, 0)
                              , 'ENG', decode(parameter_6, '1', 1, 0)
                              , 0
                               ) = 1
                group by FIN.ACS_FINANCIAL_ACCOUNT_ID
                       , CUB.CURRENCY
                union all
                select   IMP.ACS_FINANCIAL_ACCOUNT_ID
                       , sum(IMP.IMF_AMOUNT_LC_D) TOTAL_LC_D
                       , sum(IMP.IMF_AMOUNT_LC_C) TOTAL_LC_C
                       , sum(IMP.IMF_AMOUNT_FC_D) TOTAL_FC_D
                       , sum(IMP.IMF_AMOUNT_FC_C) TOTAL_FC_C
                       , CUB.CURRENCY CURRENCY_MB
                    from ACT_JOURNAL JOU
                       , ACT_DOCUMENT DOC
                       , ACS_PERIOD PER
                       , ACS_FINANCIAL_YEAR FYE
                       , ACT_FINANCIAL_IMPUTATION IMP
                       , PCS.PC_CURR CUB
                       , ACS_FINANCIAL_CURRENCY CFB
                       , table(RPT_FUNCTIONS.TableAuthRptDivisions(vpc_user_id, procparam_3) ) AUT
                   where FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
                     and IMP.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                     and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                     and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
                     and CFB.ACS_FINANCIAL_CURRENCY_ID = IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
                     and CUB.PC_CURR_ID = CFB.PC_CURR_ID
                     and IMP.IMF_TRANSACTION_DATE < to_date(procparam_4, 'yyyyMMdd')
                     and IMP.IMF_ACS_DIVISION_ACCOUNT_ID is not null
                     and AUT.column_value = IMP.IMF_ACS_DIVISION_ACCOUNT_ID
                     and to_date(procparam_4, 'yyyyMMdd') between FYE.FYE_START_DATE and FYE.FYE_END_DATE
                     and decode( (select C_ETAT_JOURNAL
                                    from ACT_ETAT_JOURNAL
                                   where ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
                                     and C_SUB_SET = 'ACC')
                              , null, 1
                              , 'BRO', decode(procparam_6, '1', 1, 0)
                              , 'PROV', decode(procparam_7, '1', 1, 0)
                              , 'DEF', decode(procparam_8, '1', 1, 0)
                              , 0
                               ) = 1
                     and decode( (select SCA.C_TYPE_CUMUL
                                    from ACJ_SUB_SET_CAT SCA
                                   where SCA.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
                                     and SCA.C_SUB_SET = 'ACC')
                              , 'INT', decode(parameter_3, '1', 1, 0)
                              , 'EXT', decode(parameter_4, '1', 1, 0)
                              , 'PRE', decode(parameter_5, '1', 1, 0)
                              , 'ENG', decode(parameter_6, '1', 1, 0)
                              , 0
                               ) = 1
                     and decode(parameter_9, 1, decode(IMP.IMF_TYPE, 'VAT', 0, decode(IMP.ACS_TAX_CODE_ID, null, 1, 0) ), 1) = 1
                group by IMP.ACS_FINANCIAL_ACCOUNT_ID
                       , CUB.CURRENCY)
            group by ACS_FINANCIAL_ACCOUNT_ID
                   , CURRENCY_MB) BAL
          , table(RPT_FUNCTIONS.TableAuthRptDivisions(vpc_user_id, procparam_3) ) AUT
     where V_ACC.ACS_FINANCIAL_ACCOUNT_ID = V_IMP.ACS_FINANCIAL_ACCOUNT_ID
       and V_IMP.ACS_PERIOD_ID = PRD.ACS_PERIOD_ID(+)
       and PRD.ACS_FINANCIAL_YEAR_ID = FYR.ACS_FINANCIAL_YEAR_ID(+)
       and V_IMP.ACS_DIVISION_ACCOUNT_ID = DES_DIV.ACS_ACCOUNT_ID(+)
       and V_IMP.ACT_DOCUMENT_ID = TDO.ACT_DOCUMENT_ID(+)
       and TDO.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID(+)
       and TDO.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID(+)
       and V_IMP.ACS_TAX_CODE_ID = VAT.ACS_ACCOUNT_ID(+)
       and V_IMP.ACS_FINANCIAL_CURRENCY_ID = FUR.ACS_FINANCIAL_CURRENCY_ID(+)
       and FUR.PC_CURR_ID = CUR.PC_CURR_ID(+)
       and V_IMP.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_ACCOUNT_ID(+)
       and AUX.ACS_ACCOUNT_ID = DES_AUX.ACS_ACCOUNT_ID(+)
       and V_IMP.ACS_ACS_FINANCIAL_CURRENCY_ID = FUR_LC.ACS_FINANCIAL_CURRENCY_ID(+)
       and FUR_LC.PC_CURR_ID = CUR_LC.PC_CURR_ID(+)
       and V_IMP.ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID(+)
       and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_ACCOUNT_ID(+)
       and V_ACC.PC_LANG_ID(+) = VPC_LANG_ID
       and LAN.PC_LANG_ID(+) = VPC_LANG_ID
       and BAL.ACS_FINANCIAL_ACCOUNT_ID(+) = V_ACC.ACS_FINANCIAL_ACCOUNT_ID
       and AUT.column_value = V_IMP.ACS_DIVISION_ACCOUNT_ID
       and ( (case parameter_2
                when '0' then 1
                when '1' then case
                               when(V_IMP.IMF_COMPARE_DATE is not null)
                                   and (V_IMP.ACT_JOURNAL_ID is not null)
                                   and (JOU.C_TYPE_JOURNAL <> 'OPB') then 1
                               else 0
                             end
                when '2' then case
                               when CAT.CAT_DESCRIPTION <> '7' then
                                    case
                                         when   (V_IMP.IMF_COMPARE_DATE is null)
                                             and (V_IMP.ACT_JOURNAL_ID is not null)
                                             and (JOU.C_TYPE_JOURNAL <> 'OPB') then 1
                                         else 0
                                    end
                               else 0
                             end
                else 0
              end
             ) = 1
           )
       and V_IMP.IMF_TRANSACTION_DATE <= to_date(procparam_5, 'yyyyMMdd')
       and decode(V_IMP.C_ETAT_JOURNAL
                , null, 1
                , 'BRO', decode(procparam_6, '1', 1, 0)
                , 'PROV', decode(procparam_7, '1', 1, 0)
                , 'DEF', decode(procparam_8, '1', 1, 0)
                , 0
                 ) = 1
       and decode(V_IMP.C_TYPE_CUMUL
                , 'INT', decode(parameter_3, '1', 1, 0)
                , 'EXT', decode(parameter_4, '1', 1, 0)
                , 'PRE', decode(parameter_5, '1', 1, 0)
                , 'ENG', decode(parameter_6, '1', 1, 0)
                , 0
                 ) = 1
       and decode(parameter_9, 1, decode(V_IMP.IMF_TYPE, 'VAT', 0, decode(V_IMP.ACS_TAX_CODE_ID, null, 1, 0) ), 1) = 1
    union all
    select null INFO
         , null ACS_FINANCIAL_YEAR_ID
         , null REPORT_AMOUNT
         , V_ACC.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
         , V_ACC.ACC_NUMBER ACC_NUMBER
         , V_ACC.ACC_DETAIL_PRINTING ACC_DETAIL_PRINTING
         , V_ACC.DES_DESCRIPTION_SUMMARY DES_DESCRIPTION_SUMMARY
         , V_ACC.DES_DESCRIPTION_LARGE DES_DESCRIPTION_LARGE
         , ACS_FUNCTION.isFinAccountInME(V_ACC.ACS_FINANCIAL_ACCOUNT_ID) isFinAccountInME
         , null ACT_FINANCIAL_IMPUTATION_ID
         , null V_ACT_DOCUMENT_ID
         , null V_ACS_FINANCIAL_ACCOUNT_ID
         , 'COM' IMF_TYPE
         , null IMF_DESCRIPTION
         , null IMF_AMOUNT_LC_D
         , null IMF_AMOUNT_LC_C
         , null IMF_EXCHANGE_RATE
         , null IMF_AMOUNT_FC_D
         , null IMF_AMOUNT_FC_C
         , null IMF_VALUE_DATE
         , null ACS_TAX_CODE_ID
         , null IMF_TRANSACTION_DATE
         , null ACS_FINANCIAL_CURRENCY_ID
         , null ACS_AUXILIARY_ACCOUNT_ID
         , null AUX_DESCRIPTION_SUMMARY
         , null ACS_ACS_FINANCIAL_CURRENCY_ID
         , null DOC_DATE_DELIVERY
         , null ACS_DIVISION_ACCOUNT_ID
         , null DIV_NUMBER
         , null DIV_DES_DESCRIPTION_SUMMARY
         , null C_ETAT_JOURNAL
         , null C_TYPE_CUMUL
         , null IMF_COMPARE_DATE
         , null IMF_COMPARE_TEXT
         , null IMF_COMPARE_USE_INI
         , null C_TYPE_CATALOGUE
         , null CAT_DESCRIPTION
         , null AUX_ACC_NUMBER
         , null FIN_ACC_NUMBER
         , null VAT_ACS_ACCOUNT_ID
         , null VAT_ACC_NUMBER
         , null FUR_PC_CURR_ID
         , null FUR_PC_CURR_ID_LC
         , null ACT_DOCUMENT_ID
         , null DOC_NUMBER
         , null JOU_DESCRIPTION
         , null C_TYPE_JOURNAL
         , null JOU_NUMBER
         , null CUR_PC_CURR_ID
         , null CUR_PC_CURR_ID_LC
         , null CUR_CURRENCY
         , null CUR_CURRENCY_LC
         , null LANID
         , null C_TYPE_PERIOD
         , null RPT_COMPARED_AMOUNT
         , null RPT_COMPARED_AMOUNT_DIV
         , null RPT_NOT_COMPARED_AMOUNT
         , null RPT_NOT_COMPARED_AMOUNT_DIV
         , null RPT_COMPARED_AMOUNT_ME
         , null RPT_COMPARED_AMOUNT_DIV_ME
         , null RPT_NOT_COMPARED_AMOUNT_ME
         , null RPT_NOT_COMPARED_AMOUNT_DIV_ME
         , null TOTAL_LC_D
         , null TOTAL_LC_C
         , null TOTAL_FC_D
         , null TOTAL_FC_C
         , null CURRENCY_MB
         , null CURRENCY_ME
      from V_ACS_FINANCIAL_ACCOUNT V_ACC
     where V_ACC.ACS_FINANCIAL_ACCOUNT_ID not in(select V_IMP.ACS_FINANCIAL_ACCOUNT_ID
                                                                                 from V_ACT_ACC_IMP_REPORT V_IMP)
       and V_ACC.ACC_NUMBER >= ACR_FUNCTIONS.GetAccNumber(1)
       and V_ACC.ACC_NUMBER <= ACR_FUNCTIONS.GetAccNumber(0)
       and V_ACC.PC_LANG_ID = VPC_LANG_ID;
else     -- if (ACS_FUNCTION.ExistDIVI = 0) = No divisions
  open aRefCursor for
    select (case
              when(V_IMP.IMF_COMPARE_DATE is not null)
                  and (V_IMP.ACT_JOURNAL_ID is not null)
                  and (JOU.C_TYPE_JOURNAL <> 'OPB') then 'COMPARED'
              when CAT.CAT_DESCRIPTION <> '7' then case
                                                    when (V_IMP.IMF_COMPARE_DATE is null)
                                                        and    (V_IMP.ACT_JOURNAL_ID is not null)
                                                        and    (JOU.C_TYPE_JOURNAL <> 'OPB') then 'NOT_COMPARED'
                                                    else ''
                                                  end
              else ''
            end
           ) INFO
         , FYR.ACS_FINANCIAL_YEAR_ID
         , ACS_FUNCTION.REPORTAMOUNT(V_ACC.ACS_FINANCIAL_ACCOUNT_ID, FYR.ACS_FINANCIAL_YEAR_ID, 'EXT', 1, 0) REPORT_AMOUNT
         , V_ACC.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
         , V_ACC.ACC_NUMBER ACC_NUMBER
         , V_ACC.ACC_DETAIL_PRINTING ACC_DETAIL_PRINTING
         , V_ACC.DES_DESCRIPTION_SUMMARY DES_DESCRIPTION_SUMMARY
         , V_ACC.DES_DESCRIPTION_LARGE DES_DESCRIPTION_LARGE
         , ACS_FUNCTION.isFinAccountInME(V_ACC.ACS_FINANCIAL_ACCOUNT_ID) isFinAccountInME
         , V_IMP.ACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION_ID
         , V_IMP.ACT_DOCUMENT_ID V_ACT_DOCUMENT_ID
         , V_IMP.ACS_FINANCIAL_ACCOUNT_ID V_ACS_FINANCIAL_ACCOUNT_ID
         , V_IMP.IMF_TYPE IMF_TYPE
         , V_IMP.IMF_DESCRIPTION IMF_DESCRIPTION
         , V_IMP.IMF_AMOUNT_LC_D IMF_AMOUNT_LC_D
         , V_IMP.IMF_AMOUNT_LC_C IMF_AMOUNT_LC_C
         , V_IMP.IMF_EXCHANGE_RATE IMF_EXCHANGE_RATE
         , V_IMP.IMF_AMOUNT_FC_D IMF_AMOUNT_FC_D
         , V_IMP.IMF_AMOUNT_FC_C IMF_AMOUNT_FC_C
         , V_IMP.IMF_VALUE_DATE IMF_VALUE_DATE
         , V_IMP.ACS_TAX_CODE_ID ACS_TAX_CODE_ID
         , V_IMP.IMF_TRANSACTION_DATE IMF_TRANSACTION_DATE
         , V_IMP.ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID
         , V_IMP.ACS_AUXILIARY_ACCOUNT_ID ACS_AUXILIARY_ACCOUNT_ID
         , DES_AUX.DES_DESCRIPTION_SUMMARY AUX_DESCRIPTION_SUMMARY
         , V_IMP.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID
         , V_IMP.DOC_DATE_DELIVERY DOC_DATE_DELIVERY
         , V_IMP.ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
         , V_IMP.DIV_NUMBER DIV_NUMBER
         , DES_DIV.DES_DESCRIPTION_SUMMARY DIV_DES_DESCRIPTION_SUMMARY
         , V_IMP.C_ETAT_JOURNAL C_ETAT_JOURNAL
         , V_IMP.C_TYPE_CUMUL C_TYPE_CUMUL
         , V_IMP.IMF_COMPARE_DATE IMF_COMPARE_DATE
         , V_IMP.IMF_COMPARE_TEXT IMF_COMPARE_TEXT
         , V_IMP.IMF_COMPARE_USE_INI IMF_COMPARE_USE_INI
         , CAT.C_TYPE_CATALOGUE C_TYPE_CATALOGUE
         , CAT.CAT_DESCRIPTION CAT_DESCRIPTION
         , AUX.ACC_NUMBER AUX_ACC_NUMBER
         , FIN.ACC_NUMBER FIN_ACC_NUMBER
         , VAT.ACS_ACCOUNT_ID VAT_ACS_ACCOUNT_ID
         , VAT.ACC_NUMBER VAT_ACC_NUMBER
         , FUR.PC_CURR_ID FUR_PC_CURR_ID
         , FUR_LC.PC_CURR_ID FUR_PC_CURR_ID_LC
         , TDO.ACT_DOCUMENT_ID ACT_DOCUMENT_ID
         , TDO.DOC_NUMBER DOC_NUMBER
         , JOU.JOU_DESCRIPTION JOU_DESCRIPTION
         , JOU.C_TYPE_JOURNAL C_TYPE_JOURNAL
         , JOU.JOU_NUMBER JOU_NUMBER
         , CUR.PC_CURR_ID CUR_PC_CURR_ID
         , CUR_LC.PC_CURR_ID CUR_PC_CURR_ID_LC
         , CUR.CURRENCY CUR_CURRENCY
         , CUR_LC.CURRENCY CUR_CURRENCY_LC
         , LAN.LANID LANID
         , PRD.C_TYPE_PERIOD C_TYPE_PERIOD
         , ACR_FUNCTIONS.GetReportAmountCompared(V_ACC.ACS_FINANCIAL_ACCOUNT_ID, null, to_date(procparam_4, 'yyyyMMdd') -1, 1) RPT_COMPARED_AMOUNT
         , ACR_FUNCTIONS.GetReportAmountCompared(V_ACC.ACS_FINANCIAL_ACCOUNT_ID, V_IMP.ACS_DIVISION_ACCOUNT_ID, to_date(procparam_4, 'yyyyMMdd') -1, 1) RPT_COMPARED_AMOUNT_DIV
         , ACR_FUNCTIONS.GetReportAmountCompared(V_ACC.ACS_FINANCIAL_ACCOUNT_ID, null, to_date(procparam_4, 'yyyyMMdd') -1, 0) RPT_NOT_COMPARED_AMOUNT
         , ACR_FUNCTIONS.GetReportAmountCompared(V_ACC.ACS_FINANCIAL_ACCOUNT_ID, V_IMP.ACS_DIVISION_ACCOUNT_ID, to_date(procparam_4, 'yyyyMMdd') -1, 0) RPT_NOT_COMPARED_AMOUNT_DIV
         , ACR_FUNCTIONS.GetReportAmountCompared(V_ACC.ACS_FINANCIAL_ACCOUNT_ID, null, to_date(procparam_4, 'yyyyMMdd') -1, 1, rpt_functions.getFinancialCurrencyId(V_IMP.ACS_FINANCIAL_ACCOUNT_ID)) RPT_COMPARED_AMOUNT_ME
         , ACR_FUNCTIONS.GetReportAmountCompared(V_ACC.ACS_FINANCIAL_ACCOUNT_ID, V_IMP.ACS_DIVISION_ACCOUNT_ID, to_date(procparam_4, 'yyyyMMdd') -1, 1, rpt_functions.getFinancialCurrencyId(V_IMP.ACS_FINANCIAL_ACCOUNT_ID)) RPT_COMPARED_AMOUNT_DIV_ME
         , ACR_FUNCTIONS.GetReportAmountCompared(V_ACC.ACS_FINANCIAL_ACCOUNT_ID, null, to_date(procparam_4, 'yyyyMMdd') -1, 0, rpt_functions.getFinancialCurrencyId(V_IMP.ACS_FINANCIAL_ACCOUNT_ID)) RPT_NOT_COMPARED_AMOUNT_ME
         , ACR_FUNCTIONS.GetReportAmountCompared(V_ACC.ACS_FINANCIAL_ACCOUNT_ID, V_IMP.ACS_DIVISION_ACCOUNT_ID, to_date(procparam_4, 'yyyyMMdd') -1, 0, rpt_functions.getFinancialCurrencyId(V_IMP.ACS_FINANCIAL_ACCOUNT_ID)) RPT_NOT_COMPARED_AMOUNT_DIV_ME
         , BAL.TOTAL_LC_D
         , BAL.TOTAL_LC_C
         , BAL.TOTAL_FC_D
         , BAL.TOTAL_FC_C
         , BAL.CURRENCY_MB
         , cast(rpt_functions.getCurrencyId(V_IMP.ACS_FINANCIAL_ACCOUNT_ID) as varchar2(5)) CURRENCY_ME
      from V_ACS_FINANCIAL_ACCOUNT V_ACC
         , V_ACT_ACC_IMP_REPORT V_IMP
         , (select ACS_ACCOUNT_ID
                 , DES_DESCRIPTION_SUMMARY
              from ACS_DESCRIPTION
             where PC_LANG_ID = VPC_LANG_ID) DES_DIV
         , (select ACS_ACCOUNT_ID
                 , DES_DESCRIPTION_SUMMARY
              from ACS_DESCRIPTION
             where PC_LANG_ID = VPC_LANG_ID) DES_AUX
         , ACS_PERIOD PRD
         , ACS_FINANCIAL_YEAR FYR
         , ACT_DOCUMENT TDO
         , ACJ_CATALOGUE_DOCUMENT CAT
         , ACT_JOURNAL JOU
         , ACS_ACCOUNT AUX
         , ACS_ACCOUNT FIN
         , ACS_ACCOUNT VAT
         , ACS_FINANCIAL_CURRENCY FUR
         , ACS_FINANCIAL_CURRENCY FUR_LC
         , ACT_FINANCIAL_IMPUTATION IMP
         , PCS.PC_CURR CUR
         , PCS.PC_CURR CUR_LC
         , PCS.PC_LANG LAN
         , (select ACS_FINANCIAL_ACCOUNT_ID
                   , sum(TOTAL_LC_D) TOTAL_LC_D
                   , sum(TOTAL_LC_C) TOTAL_LC_C
                   , sum(TOTAL_FC_D) TOTAL_FC_D
                   , sum(TOTAL_FC_C) TOTAL_FC_C
                   , CURRENCY_MB
            from
              (select   FIN.ACS_FINANCIAL_ACCOUNT_ID
                     , sum(TOT.TOT_DEBIT_LC) TOTAL_LC_D
                     , sum(TOT.TOT_CREDIT_LC) TOTAL_LC_C
                     , sum(TOT.TOT_DEBIT_FC) TOTAL_FC_D
                     , sum(TOT.TOT_CREDIT_FC) TOTAL_FC_C
                     , CUB.CURRENCY CURRENCY_MB
                  from ACS_FINANCIAL_YEAR FYE
                     , ACS_PERIOD PER
                     , ACS_FINANCIAL_ACCOUNT FIN
                     , ACT_TOTAL_BY_PERIOD TOT
                     , PCS.PC_CURR CUB
                     , ACS_FINANCIAL_CURRENCY CFB
                 where FIN.ACS_FINANCIAL_ACCOUNT_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID
                   and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
                   and FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
                   and PER.ACS_PERIOD_ID = TOT.ACS_PERIOD_ID
                   and PER.C_TYPE_PERIOD = '1'
                   and CFB.ACS_FINANCIAL_CURRENCY_ID = TOT.ACS_FINANCIAL_CURRENCY_ID
                   and CUB.PC_CURR_ID = CFB.PC_CURR_ID
                   and (    (TOT.ACS_DIVISION_ACCOUNT_ID is not null)
                        or (    TOT.ACS_DIVISION_ACCOUNT_ID is null
                            and ACR_FUNCTIONS.ExistDivision = 0) )
                   and to_date(procparam_4, 'yyyyMMdd') between FYE.FYE_START_DATE and FYE.FYE_END_DATE
                   and procparam_7 = 1
                   and decode(TOT.C_TYPE_CUMUL
                            , 'INT', decode(parameter_3, '1', 1, 0)
                            , 'EXT', decode(parameter_4, '1', 1, 0)
                            , 'PRE', decode(parameter_5, '1', 1, 0)
                            , 'ENG', decode(parameter_6, '1', 1, 0)
                            , 0
                             ) = 1
              group by FIN.ACS_FINANCIAL_ACCOUNT_ID
                     , CUB.CURRENCY
              union all
              select   IMP.ACS_FINANCIAL_ACCOUNT_ID
                     , sum(IMP.IMF_AMOUNT_LC_D) TOTAL_LC_D
                     , sum(IMP.IMF_AMOUNT_LC_C) TOTAL_LC_C
                     , sum(IMP.IMF_AMOUNT_FC_D) TOTAL_FC_D
                     , sum(IMP.IMF_AMOUNT_FC_C) TOTAL_FC_C
                     , CUB.CURRENCY CURRENCY_MB
                  from ACT_JOURNAL JOU
                     , ACT_DOCUMENT DOC
                     , ACS_PERIOD PER
                     , ACS_FINANCIAL_YEAR FYE
                     , ACT_FINANCIAL_IMPUTATION IMP
                     , PCS.PC_CURR CUB
                     , ACS_FINANCIAL_CURRENCY CFB
                 where FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
                   and IMP.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                   and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                   and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
                   and CFB.ACS_FINANCIAL_CURRENCY_ID = IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
                   and CUB.PC_CURR_ID = CFB.PC_CURR_ID
                   and IMP.IMF_TRANSACTION_DATE < to_date(procparam_4, 'yyyyMMdd')
                   and to_date(procparam_4, 'yyyyMMdd') between FYE.FYE_START_DATE and FYE.FYE_END_DATE
                   and decode( (select C_ETAT_JOURNAL
                                  from ACT_ETAT_JOURNAL
                                 where ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
                                   and C_SUB_SET = 'ACC')
                            , null, 1
                            , 'BRO', decode(procparam_6, '1', 1, 0)
                            , 'PROV', decode(procparam_7, '1', 1, 0)
                            , 'DEF', decode(procparam_8, '1', 1, 0)
                            , 0
                             ) = 1
                   and decode( (select SCA.C_TYPE_CUMUL
                                  from ACJ_SUB_SET_CAT SCA
                                 where SCA.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
                                   and SCA.C_SUB_SET = 'ACC')
                            , 'INT', decode(parameter_3, '1', 1, 0)
                            , 'EXT', decode(parameter_4, '1', 1, 0)
                            , 'PRE', decode(parameter_5, '1', 1, 0)
                            , 'ENG', decode(parameter_6, '1', 1, 0)
                            , 0
                             ) = 1
                   and decode(parameter_9, 1, decode(IMP.IMF_TYPE, 'VAT', 0, decode(IMP.ACS_TAX_CODE_ID, null, 1, 0) ), 1) = 1
              group by IMP.ACS_FINANCIAL_ACCOUNT_ID
                     , CUB.CURRENCY)
            group by ACS_FINANCIAL_ACCOUNT_ID
                   , CURRENCY_MB) BAL
     where V_ACC.ACS_FINANCIAL_ACCOUNT_ID = V_IMP.ACS_FINANCIAL_ACCOUNT_ID
       and V_IMP.ACS_PERIOD_ID = PRD.ACS_PERIOD_ID(+)
       and PRD.ACS_FINANCIAL_YEAR_ID = FYR.ACS_FINANCIAL_YEAR_ID(+)
       and V_IMP.ACS_DIVISION_ACCOUNT_ID = DES_DIV.ACS_ACCOUNT_ID(+)
       and V_IMP.ACT_DOCUMENT_ID = TDO.ACT_DOCUMENT_ID(+)
       and TDO.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID(+)
       and TDO.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID(+)
       and V_IMP.ACS_TAX_CODE_ID = VAT.ACS_ACCOUNT_ID(+)
       and V_IMP.ACS_FINANCIAL_CURRENCY_ID = FUR.ACS_FINANCIAL_CURRENCY_ID(+)
       and FUR.PC_CURR_ID = CUR.PC_CURR_ID(+)
       and V_IMP.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_ACCOUNT_ID(+)
       and AUX.ACS_ACCOUNT_ID = DES_AUX.ACS_ACCOUNT_ID(+)
       and V_IMP.ACS_ACS_FINANCIAL_CURRENCY_ID = FUR_LC.ACS_FINANCIAL_CURRENCY_ID(+)
       and FUR_LC.PC_CURR_ID = CUR_LC.PC_CURR_ID(+)
       and V_IMP.ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID(+)
       and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_ACCOUNT_ID(+)
       and V_ACC.PC_LANG_ID(+) = VPC_LANG_ID
       and LAN.PC_LANG_ID(+) = VPC_LANG_ID
       and BAL.ACS_FINANCIAL_ACCOUNT_ID(+) = V_ACC.ACS_FINANCIAL_ACCOUNT_ID
       and ( (case parameter_2
                when '0' then 1
                when '1' then case
                               when(V_IMP.IMF_COMPARE_DATE is not null)
                                   and (V_IMP.ACT_JOURNAL_ID is not null)
                                   and (JOU.C_TYPE_JOURNAL <> 'OPB') then 1
                               else 0
                             end
                when '2' then case
                               when CAT.CAT_DESCRIPTION <> '7' then case
                                                                     when (V_IMP.IMF_COMPARE_DATE is null)
                                                                         and   (V_IMP.ACT_JOURNAL_ID is not null)
                                                                         and   (JOU.C_TYPE_JOURNAL <> 'OPB') then 1
                                                                     else 0
                                                                   end
                               else 0
                             end
                else 0
              end
             ) = 1
           )
       and V_IMP.IMF_TRANSACTION_DATE <= to_date(procparam_5, 'yyyyMMdd')
       and decode(V_IMP.C_ETAT_JOURNAL
                , null, 1
                , 'BRO', decode(procparam_6, '1', 1, 0)
                , 'PROV', decode(procparam_7, '1', 1, 0)
                , 'DEF', decode(procparam_8, '1', 1, 0)
                , 0
                 ) = 1
       and decode(V_IMP.C_TYPE_CUMUL
                , 'INT', decode(parameter_3, '1', 1, 0)
                , 'EXT', decode(parameter_4, '1', 1, 0)
                , 'PRE', decode(parameter_5, '1', 1, 0)
                , 'ENG', decode(parameter_6, '1', 1, 0)
                , 0
                 ) = 1
       and decode(parameter_9, 1, decode(V_IMP.IMF_TYPE, 'VAT', 0, decode(V_IMP.ACS_TAX_CODE_ID, null, 1, 0) ), 1) = 1
    union all
    select null INFO
         , null ACS_FINANCIAL_YEAR_ID
         , null REPORT_AMOUNT
         , V_ACC.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
         , V_ACC.ACC_NUMBER ACC_NUMBER
         , V_ACC.ACC_DETAIL_PRINTING ACC_DETAIL_PRINTING
         , V_ACC.DES_DESCRIPTION_SUMMARY DES_DESCRIPTION_SUMMARY
         , V_ACC.DES_DESCRIPTION_LARGE DES_DESCRIPTION_LARGE
         , ACS_FUNCTION.isFinAccountInME(V_ACC.ACS_FINANCIAL_ACCOUNT_ID) isFinAccountInME
         , null ACT_FINANCIAL_IMPUTATION_ID
         , null V_ACT_DOCUMENT_ID
         , null V_ACS_FINANCIAL_ACCOUNT_ID
         , 'COM' IMF_TYPE
         , null IMF_DESCRIPTION
         , null IMF_AMOUNT_LC_D
         , null IMF_AMOUNT_LC_C
         , null IMF_EXCHANGE_RATE
         , null IMF_AMOUNT_FC_D
         , null IMF_AMOUNT_FC_C
         , null IMF_VALUE_DATE
         , null ACS_TAX_CODE_ID
         , null IMF_TRANSACTION_DATE
         , null ACS_FINANCIAL_CURRENCY_ID
         , null ACS_AUXILIARY_ACCOUNT_ID
         , null AUX_DESCRIPTION_SUMMARY
         , null ACS_ACS_FINANCIAL_CURRENCY_ID
         , null DOC_DATE_DELIVERY
         , null ACS_DIVISION_ACCOUNT_ID
         , null DIV_NUMBER
         , null DIV_DES_DESCRIPTION_SUMMARY
         , null C_ETAT_JOURNAL
         , null C_TYPE_CUMUL
         , null IMF_COMPARE_DATE
         , null IMF_COMPARE_TEXT
         , null IMF_COMPARE_USE_INI
         , null C_TYPE_CATALOGUE
         , null CAT_DESCRIPTION
         , null AUX_ACC_NUMBER
         , null FIN_ACC_NUMBER
         , null VAT_ACS_ACCOUNT_ID
         , null VAT_ACC_NUMBER
         , null FUR_PC_CURR_ID
         , null FUR_PC_CURR_ID_LC
         , null ACT_DOCUMENT_ID
         , null DOC_NUMBER
         , null JOU_DESCRIPTION
         , null C_TYPE_JOURNAL
         , null JOU_NUMBER
         , null CUR_PC_CURR_ID
         , null CUR_PC_CURR_ID_LC
         , null CUR_CURRENCY
         , null CUR_CURRENCY_LC
         , null LANID
         , null C_TYPE_PERIOD
         , null RPT_COMPARED_AMOUNT
         , null RPT_COMPARED_AMOUNT_DIV
         , null RPT_NOT_COMPARED_AMOUNT
         , null RPT_NOT_COMPARED_AMOUNT_DIV
         , null RPT_COMPARED_AMOUNT_ME
         , null RPT_COMPARED_AMOUNT_DIV_ME
         , null RPT_NOT_COMPARED_AMOUNT_ME
         , null RPT_NOT_COMPARED_AMOUNT_DIV_ME
         , null TOTAL_LC_D
         , null TOTAL_LC_C
         , null TOTAL_FC_D
         , null TOTAL_FC_C
         , null CURRENCY_MB
         , null CURRENCY_ME
      from V_ACS_FINANCIAL_ACCOUNT V_ACC
     where V_ACC.ACS_FINANCIAL_ACCOUNT_ID not in(select V_IMP.ACS_FINANCIAL_ACCOUNT_ID
                                                   from V_ACT_ACC_IMP_REPORT V_IMP)
       and V_ACC.ACC_NUMBER >= ACR_FUNCTIONS.GetAccNumber(1)
       and V_ACC.ACC_NUMBER <= ACR_FUNCTIONS.GetAccNumber(0)
       and V_ACC.PC_LANG_ID = VPC_LANG_ID;
end if;
end RPT_ACR_ACC_IMP_COMPARE;
