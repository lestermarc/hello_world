--------------------------------------------------------
--  DDL for Procedure RPT_ACT_FIN_IMP_CML_BAL_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_FIN_IMP_CML_BAL_SUB" (
  aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, PROCPARAM_3    in     varchar2
, PROCPARAM_4    in     varchar2
, PROCPARAM_6    in     varchar2
, PROCPARAM_7    in     varchar2
, PROCPARAM_8    in     varchar2
, PROCPARAM_9    in     varchar2
, PARAMETER_2    in     varchar2
, PARAMETER_3    in     varchar2
, PARAMETER_4    in     varchar2
, PARAMETER_5    in     varchar2
, PARAMETER_6    in     varchar2
, PARAMETER_9    in     varchar2
, PROCUSER_LANID in     pcs.pc_lang.lanid%type
)
/**
* description used for report ACR_ACC_IMPUTATION_COMPARE

* @author jliu 18 nov 2008
* @lastupdate VHA 15 August 2012
* @public
* @param PROCPARAM_3    DIVISION_ID List ('' = tout), sinon liste des ID
* @param PROCPARAM_4    Date (yyyyMMdd)
* @param PROCPARAM_6    Journal status = BRO : 1=Yes / 0=No
* @param PROCPARAM_7    Journal status = PROV : 1=Yes / 0=No
* @param PROCPARAM_8    Journal status = DEF : 1=Yes / 0=No
* @param PROCPARAM_9    ACS_FINANCIAL_ACCOUNT_ID

* @param PARAMETER_2    Compare code : '0'=all / '1'=compared / '2'=not compared
* @param PARAMETER_3    C_TYPE_CUMUL = 'INT' :  0=No / 1=Yes
* @param PARAMETER_4    C_TYPE_CUMUL = 'EXT' :  0=No / 1=Yes
* @param PARAMETER_5    C_TYPE_CUMUL = 'PRE' :  0=No / 1=Yes
* @param PARAMETER_6    C_TYPE_CUMUL = 'ENG' :  0=No / 1=Yes
* @param PARAMETER_9    Only transaction without VAT
*/
is
  VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
begin
  open aRefCursor for
    select 0 ACT_FINANCIAL_IMPUTATION_ID
         , TOT.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
         , FYE.FYE_START_DATE IMF_TRANSACTION_DATE
         , FYE.FYE_START_DATE IMF_VALUE_DATE
         , 'Report' IMF_DESCRIPTION
         , TOT.ACS_DIVISION_ACCOUNT_ID
         , 0 ACS_TAX_CODE_ID
         , null TAX_NUMBER
         , TOT.ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID
         , (select CUB.CURRENCY
              from PCS.PC_CURR CUB
                 , ACS_FINANCIAL_CURRENCY CFB
             where CFB.ACS_FINANCIAL_CURRENCY_ID = TOT.ACS_FINANCIAL_CURRENCY_ID
               and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_MB
         , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID
         , (select CUB.CURRENCY
              from PCS.PC_CURR CUB
                 , ACS_FINANCIAL_CURRENCY CFB
             where CFB.ACS_FINANCIAL_CURRENCY_ID = TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
               and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_ME
         , TOT.TOT_DEBIT_LC IMF_AMOUNT_LC_D
         , TOT.TOT_CREDIT_LC IMF_AMOUNT_LC_C
         , TOT.TOT_DEBIT_FC IMF_AMOUNT_FC_D
         , TOT.TOT_CREDIT_FC IMF_AMOUNT_FC_C
         , FYE.ACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR_ID
         , FYE.FYE_START_DATE FYE_START_DATE
         , FYE.FYE_END_DATE FYE_END_DATE
         , PER.PER_START_DATE PER_START_DATE
         , PER.PER_END_DATE PER_END_DATE
         , PER.C_TYPE_PERIOD C_TYPE_PERIOD
         , 0 ACT_JOURNAL_ID
         , null JOU_NUMBER
         , null JOU_DESCRIPTION
         , 'PROV' C_ETAT_JOURNAL
         , TOT.C_TYPE_CUMUL
         , 'OPB' C_TYPE_JOURNAL
         , 'MAN' IMF_TYPE
      from ACS_FINANCIAL_YEAR FYE
         , ACS_PERIOD PER
         , ACS_FINANCIAL_ACCOUNT FIN
         , ACT_TOTAL_BY_PERIOD TOT
     where FIN.ACS_FINANCIAL_ACCOUNT_ID = PROCPARAM_9
       and FIN.ACS_FINANCIAL_ACCOUNT_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID
       and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
       and to_date(PROCPARAM_4, 'yyyyMMdd') between FYE.FYE_START_DATE and FYE.FYE_END_DATE
       and FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
       and PER.ACS_PERIOD_ID = TOT.ACS_PERIOD_ID
       and PER.C_TYPE_PERIOD = '1'
       and (    (TOT.ACS_DIVISION_ACCOUNT_ID is not null)
            or (    TOT.ACS_DIVISION_ACCOUNT_ID is null
                and ACR_FUNCTIONS.ExistDivision = 0) )
       and (   PROCPARAM_3 is null
            or instr(',' || PROCPARAM_3 || ',', ',' || TOT.ACS_DIVISION_ACCOUNT_ID || ',') > 0)
       and PROCPARAM_7 = 1
       and decode(TOT.C_TYPE_CUMUL
                , 'INT', decode(PARAMETER_3, '1', 1, 0)
                , 'EXT', decode(PARAMETER_4, '1', 1, 0)
                , 'PRE', decode(PARAMETER_5, '1', 1, 0)
                , 'ENG', decode(PARAMETER_6, '1', 1, 0)
                , 0
                 ) = 1
    union all
    select IMP.ACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION_ID
         , IMP.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
         , IMP.IMF_TRANSACTION_DATE IMF_TRANSACTION_DATE
         , IMP.IMF_VALUE_DATE IMF_VALUE_DATE
         , IMP.IMF_DESCRIPTION IMF_DESCRIPTION
         , IMP.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
         , IMP.ACS_TAX_CODE_ID ACS_TAX_CODE_ID
         , (select ACV.ACC_NUMBER
              from ACS_ACCOUNT ACV
             where ACV.ACS_ACCOUNT_ID = IMP.ACS_TAX_CODE_ID) TAX_NUMBER
         , IMP.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID
         , (select CUB.CURRENCY
              from PCS.PC_CURR CUB
                 , ACS_FINANCIAL_CURRENCY CFB
             where CFB.ACS_FINANCIAL_CURRENCY_ID = IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
               and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_MB
         , IMP.ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID
         , (select CUB.CURRENCY
              from PCS.PC_CURR CUB
                 , ACS_FINANCIAL_CURRENCY CFB
             where CFB.ACS_FINANCIAL_CURRENCY_ID = IMP.ACS_FINANCIAL_CURRENCY_ID
               and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_ME
         , IMP.IMF_AMOUNT_LC_D IMF_AMOUNT_LC_D
         , IMP.IMF_AMOUNT_LC_C IMF_AMOUNT_LC_C
         , IMP.IMF_AMOUNT_FC_D IMF_AMOUNT_FC_D
         , IMP.IMF_AMOUNT_FC_C IMF_AMOUNT_FC_C
         , FYE.ACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR_ID
         , FYE.FYE_START_DATE FYE_START_DATE
         , FYE.FYE_END_DATE FYE_END_DATE
         , PER.PER_START_DATE PER_START_DATE
         , PER.PER_END_DATE PER_END_DATE
         , PER.C_TYPE_PERIOD C_TYPE_PERIOD
         , JOU.ACT_JOURNAL_ID ACT_JOURNAL_ID
         , JOU.JOU_NUMBER JOU_NUMBER
         , JOU.JOU_DESCRIPTION JOU_DESCRIPTION
         , (select ETA.C_ETAT_JOURNAL
              from ACT_ETAT_JOURNAL ETA
             where ETA.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
               and ETA.C_SUB_SET = 'ACC') C_ETAT_JOURNAL
         , (select SCA.C_TYPE_CUMUL
              from ACJ_SUB_SET_CAT SCA
             where SCA.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
               and SCA.C_SUB_SET = 'ACC') C_TYPE_CUMUL
         , JOU.C_TYPE_JOURNAL C_TYPE_JOURNAL
         , IMP.IMF_TYPE IMF_TYPE
      from ACT_JOURNAL JOU
         , ACT_DOCUMENT DOC
         , ACS_PERIOD PER
         , ACS_FINANCIAL_YEAR FYE
         , ACT_FINANCIAL_IMPUTATION IMP
     where IMP.ACS_FINANCIAL_ACCOUNT_ID = PROCPARAM_9
       and to_date(PROCPARAM_4, 'yyyyMMdd') between FYE.FYE_START_DATE and FYE.FYE_END_DATE
       and FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
       and IMP.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
       and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
       and IMP.IMF_TRANSACTION_DATE < to_date(PROCPARAM_4, 'yyyyMMdd')
       and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
       and (   PROCPARAM_3 is null
            or instr(',' || PROCPARAM_3 || ',', ',' || IMP.IMF_ACS_DIVISION_ACCOUNT_ID || ',') > 0)
       and decode( (select C_ETAT_JOURNAL
                      from ACT_ETAT_JOURNAL
                     where ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
                       and C_SUB_SET = 'ACC')
                , null, 1
                , 'BRO', decode(PROCPARAM_6, '1', 1, 0)
                , 'PROV', decode(PROCPARAM_7, '1', 1, 0)
                , 'DEF', decode(PROCPARAM_8, '1', 1, 0)
                , 0
                 ) = 1
       and decode( (select SCA.C_TYPE_CUMUL
                      from ACJ_SUB_SET_CAT SCA
                     where SCA.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
                       and SCA.C_SUB_SET = 'ACC')
                , 'INT', decode(PARAMETER_3, '1', 1, 0)
                , 'EXT', decode(PARAMETER_4, '1', 1, 0)
                , 'PRE', decode(PARAMETER_5, '1', 1, 0)
                , 'ENG', decode(PARAMETER_6, '1', 1, 0)
                , 0
                 ) = 1
       and decode(PARAMETER_9, 1, decode(IMP.IMF_TYPE, 'VAT', 0, decode(IMP.ACS_TAX_CODE_ID, null, 1, 0) ), 1) = 1;
end RPT_ACT_FIN_IMP_CML_BAL_SUB;
