--------------------------------------------------------
--  DDL for Procedure RPT_ACR_ACC_IMPUTATION_DETMCH1
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACR_ACC_IMPUTATION_DETMCH1" (
  aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, procparam_0    in     varchar2
, procparam_1    in     varchar2
, procparam_2    in     varchar2
, procparam_3    in     varchar2
, procparam_4    in     varchar2
, parameter_0    in     varchar2
, parameter_1    in     varchar2
, parameter_2    in     varchar2
, parameter_3    in     varchar2
, parameter_4    in     varchar2
, parameter_5    in     varchar2
, parameter_6    in     varchar2
, parameter_7    in     varchar2
, parameter_8    in     varchar2
, parameter_11   in     varchar2
, parameter_12   in     varchar2
, parameter_13   in     varchar2
, parameter_15   in     varchar2
, parameter_16   in     varchar2
, parameter_17   in     varchar2
, procuser_lanid in     PCS.PC_LANG.LANID%type
)
is
/**
* description used for report ACR_ACC_IMPUTATION_DET
  (Grand livre standard et grand livre pour les communes bernoises)
* @author SDO 2003
* @lastUpdate VHA 10 April 2014
* @public
* @param procparam_0: FYE_NO_EXERCICE
* @param procparam_1: ACC_NUMBER
* @param procparam_2: ACC_NUMBER
* @param procparam_3: Divisions (# = All  / null = selection (COM_LIST))
* @param procparam_4: Job ID (COM_LIST)
* @param parameter_0: DATE_FROM
* @param parameter_1: DATE_TO
* @param parameter_2: JOURNAL_STATUS (ACC)
* @param parameter_3: JOURNAL_STATUS (PROV)
* @param parameter_4: JOURNAL_STATUS (DEF)
* @param parameter_5: C_TYPE_CUMUL (EXT)
* @param parameter_6: C_TYPE_CUMUL (INT)
* @param parameter_7: C_TYPE_CUMUL (PRE)
* @param parameter_8: C_TYPE_CUMUL (ENG)
* @param parameter_11: Classification
* @param parameter_12: REPORT Yes/No
* @param parameter_13: ONLY TRANSACTION WITH VAT CODE
* @param parameter_15: Budget print
* @param parameter_16: Print account without movement : 0 = No, 1 = Yes
* @param parameter_17: Group by division : 0 = No / 1 = Yes
*/
  vpc_lang_id PCS.PC_LANG.PC_LANG_ID%type;
begin
  if (procuser_lanid is not null) then
    pcs.pc_init_session.setLanId(procuser_lanid);
    vpc_lang_id  := PCS.PC_INIT_SESSION.GetUserLangId;
  end if;

  open aRefCursor for
    select 1 pseudo
         , IMP_TOT.INFO
         , IMP_TOT.ACT_FINANCIAL_IMPUTATION_ID
         , IMP_TOT.ACS_FINANCIAL_ACCOUNT_ID
         , IMP_TOT.FIN_NUMBER
         , IMP_TOT.FIN_DESCR
         , IMP_TOT.FIN_LARGE_DESCR
         , IMP_TOT.ACC_NUMBER_CE
         , IMP_TOT.IMF_TRANSACTION_DATE
         , IMP_TOT.IMF_VALUE_DATE
         , IMP_TOT.IMF_DESCRIPTION
         , IMP_TOT.ACS_DIVISION_ACCOUNT_ID
         , IMP_TOT.DIV_NUMBER
         , IMP_TOT.DIV_DESCR
         , IMP_TOT.ACS_TAX_CODE_ID
         , IMP_TOT.TAX_NUMBER
         , IMP_TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
         , IMP_TOT.CURRENCY_MB
         , IMP_TOT.ACS_FINANCIAL_CURRENCY_ID
         , IMP_TOT.CURRENCY_ME
         , IMP_TOT.IMF_EXCHANGE_RATE
         , IMP_TOT.IMF_AMOUNT_LC_D
         , IMP_TOT.IMF_AMOUNT_LC_C
         , IMP_TOT.IMF_AMOUNT_FC_D
         , IMP_TOT.IMF_AMOUNT_FC_C
         , IMP_TOT.ACS_PERIOD_ID
         , IMP_TOT.IMF_TYPE
         , IMP_TOT.ACS_AUXILIARY_ACCOUNT_ID
         , IMP_TOT.AUX_NUMBER
         , IMP_TOT.AUX_SHORT_DESCR
         , IMP_TOT.DIC_IMP_FREE1_ID
         , IMP_TOT.DIC_IMP_FREE2_ID
         , IMP_TOT.DIC_IMP_FREE3_ID
         , IMP_TOT.DIC_IMP_FREE4_ID
         , IMP_TOT.DIC_IMP_FREE5_ID
         , IMP_TOT.DOC_RECORD_ID
         , IMP_TOT.FAM_FIXED_ASSETS_ID
         , IMP_TOT.GCO_GOOD_ID
         , IMP_TOT.PAC_PERSON_ID
         , IMP_TOT.HRM_PERSON_ID
         , IMP_TOT.IMF_NUMBER
         , IMP_TOT.IMF_NUMBER2
         , IMP_TOT.IMF_NUMBER3
         , IMP_TOT.IMF_NUMBER4
         , IMP_TOT.IMF_NUMBER5
         , IMP_TOT.IMF_TEXT1
         , IMP_TOT.IMF_TEXT2
         , IMP_TOT.IMF_TEXT3
         , IMP_TOT.IMF_TEXT4
         , IMP_TOT.IMF_TEXT5
         , IMP_TOT.ACT_DOCUMENT_ID
         , IMP_TOT.DOC_NUMBER
         , IMP_TOT.DOC_DATE_DELIVERY
         , IMP_TOT.ACT_ACT_JOURNAL_ID
         , IMP_TOT.ACT_JOURNAL_ID
         , IMP_TOT.JOU_NUMBER
         , IMP_TOT.JOU_DESCRIPTION
         , IMP_TOT.C_ETAT_JOURNAL
         , IMP_TOT.C_TYPE_CUMUL
         , IMP_TOT.ACC_DETAIL_PRINTING
         , IMP_TOT.C_TYPE_JOURNAL
         , IMP_TOT.PER_AMOUNT_D
         , IMP_TOT.PER_AMOUNT_C
         , IMP_TOT.ACB_BUDGET_ID
         , IMP_TOT.ACB_BUDGET_VERSION_ID
         , IMP_TOT.ACB_GLOBAL_BUDGET_ID
         , CYN.CURRENCY_NO
      from (select 'REEL' INFO
                 , IMP.ACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION_ID
                 , IMP.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
                 , ACC.ACC_NUMBER FIN_NUMBER
                 , DES.DES_DESCRIPTION_SUMMARY FIN_DESCR
                 , DES.DES_DESCRIPTION_LARGE FIN_LARGE_DESCR
                 , (select ACC.ACC_NUMBER
                      from ACS_ACCOUNT ACC
                         , ACT_FINANCIAL_IMPUTATION IMC
                     where IMC.ACT_FINANCIAL_IMPUTATION_ID = ACR_FUNCTIONS.GetFinancialImputationId(IMP.ACT_FINANCIAL_IMPUTATION_ID)
                       and IMC.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID) ACC_NUMBER_CE
                 , IMP.IMF_TRANSACTION_DATE IMF_TRANSACTION_DATE
                 , IMP.IMF_VALUE_DATE IMF_VALUE_DATE
                 , IMP.IMF_DESCRIPTION IMF_DESCRIPTION
                 , IMP.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
                 , (select ACD.ACC_NUMBER
                      from ACS_ACCOUNT ACD
                     where ACD.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID) DIV_NUMBER
                 , (select DED.DES_DESCRIPTION_SUMMARY
                      from ACS_DESCRIPTION DED
                     where DED.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID
                       and DED.PC_LANG_ID = vpc_lang_id) DIV_DESCR
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
                 , IMP.IMF_EXCHANGE_RATE IMF_EXCHANGE_RATE
                 , IMP.IMF_AMOUNT_LC_D IMF_AMOUNT_LC_D
                 , IMP.IMF_AMOUNT_LC_C IMF_AMOUNT_LC_C
                 , IMP.IMF_AMOUNT_FC_D IMF_AMOUNT_FC_D
                 , IMP.IMF_AMOUNT_FC_C IMF_AMOUNT_FC_C
                 , IMP.ACS_PERIOD_ID ACS_PERIOD_ID
                 , IMP.IMF_TYPE IMF_TYPE
                 , ACT_FUNCTIONS.AuxAccountFromImputation(IMP.ACT_FINANCIAL_IMPUTATION_ID) ACS_AUXILIARY_ACCOUNT_ID
                 , ACS_FUNCTION.GetAccountNumber(ACT_FUNCTIONS.AuxAccountFromImputation(IMP.ACT_FINANCIAL_IMPUTATION_ID) ) AUX_NUMBER
                 , ACS_FUNCTION.GetAccountDescriptionSummary(ACT_FUNCTIONS.AuxAccountFromImputation(IMP.ACT_FINANCIAL_IMPUTATION_ID) ) AUX_SHORT_DESCR
                 , IMP.DIC_IMP_FREE1_ID DIC_IMP_FREE1_ID
                 , IMP.DIC_IMP_FREE2_ID DIC_IMP_FREE2_ID
                 , IMP.DIC_IMP_FREE3_ID DIC_IMP_FREE3_ID
                 , IMP.DIC_IMP_FREE4_ID DIC_IMP_FREE4_ID
                 , IMP.DIC_IMP_FREE5_ID DIC_IMP_FREE5_ID
                 , IMP.DOC_RECORD_ID DOC_RECORD_ID
                 , IMP.FAM_FIXED_ASSETS_ID FAM_FIXED_ASSETS_ID
                 , IMP.GCO_GOOD_ID GCO_GOOD_ID
                 , IMP.PAC_PERSON_ID PAC_PERSON_ID
                 , IMP.HRM_PERSON_ID HRM_PERSON_ID
                 , IMP.IMF_NUMBER IMF_NUMBER
                 , IMP.IMF_NUMBER2 IMF_NUMBER2
                 , IMP.IMF_NUMBER3 IMF_NUMBER3
                 , IMP.IMF_NUMBER4 IMF_NUMBER4
                 , IMP.IMF_NUMBER5 IMF_NUMBER5
                 , IMP.IMF_TEXT1 IMF_TEXT1
                 , IMP.IMF_TEXT2 IMF_TEXT2
                 , IMP.IMF_TEXT3 IMF_TEXT3
                 , IMP.IMF_TEXT4 IMF_TEXT4
                 , IMP.IMF_TEXT5 IMF_TEXT5
                 , DOC.ACT_DOCUMENT_ID ACT_DOCUMENT_ID
                 , DOC.DOC_NUMBER DOC_NUMBER
                 , (select PAR.DOC_DATE_DELIVERY
                      from ACT_PART_IMPUTATION PAR
                     where PAR.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID) DOC_DATE_DELIVERY
                 , DOC.ACT_ACT_JOURNAL_ID ACT_ACT_JOURNAL_ID
                 , JOU.ACT_JOURNAL_ID ACT_JOURNAL_ID
                 , JOU.JOU_NUMBER JOU_NUMBER
                 , JOU.JOU_DESCRIPTION JOU_DESCRIPTION
                 , ETA.C_ETAT_JOURNAL C_ETAT_JOURNAL
                 , (select SCA.C_TYPE_CUMUL
                      from ACJ_SUB_SET_CAT SCA
                     where SCA.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
                       and SCA.C_SUB_SET = 'ACC') C_TYPE_CUMUL
                 , ACC.ACC_DETAIL_PRINTING ACC_DETAIL_PRINTING
                 , JOU.C_TYPE_JOURNAL C_TYPE_JOURNAL
                 , 0 PER_AMOUNT_D
                 , 0 PER_AMOUNT_C
                 , 0 ACB_BUDGET_ID
                 , 0 ACB_BUDGET_VERSION_ID
                 , 0 ACB_GLOBAL_BUDGET_ID
              from ACT_FINANCIAL_IMPUTATION IMP
                 , ACS_FINANCIAL_ACCOUNT FIN
                 , ACS_PERIOD PER
                 , ACT_DOCUMENT DOC
                 , ACT_JOURNAL JOU
                 , ACT_ETAT_JOURNAL ETA
                 , ACS_ACCOUNT ACC
                 , ACS_DESCRIPTION DES
                 , (select LIS_ID_1
                      from COM_LIST
                     where LIS_JOB_ID = to_number(procparam_4)
                       and LIS_CODE = 'ACT_FINANCIAL_IMPUTATION_ID') LIS
             where IMP.ACT_FINANCIAL_IMPUTATION_ID = LIS.LIS_ID_1
               and FIN.ACS_FINANCIAL_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID
               and DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
               and JOU.ACT_JOURNAL_ID = DOC.ACT_JOURNAL_ID
               and ETA.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
               and ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
               and DES.ACS_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
               and DES.PC_LANG_ID = vpc_lang_id
               and PER.ACS_PERIOD_ID = IMP.ACS_PERIOD_ID
               and C_TYPE_PERIOD <> '1'
               and ETA.C_SUB_SET = 'ACC'
               and (    (     (parameter_2 = '1')
                         and (ETA.C_ETAT_JOURNAL = 'BRO') )
                    or (     (parameter_3 = '1')
                        and (ETA.C_ETAT_JOURNAL = 'PROV') )
                    or (     (parameter_4 = '1')
                        and (ETA.C_ETAT_JOURNAL = 'DEF') )
                   )
               and (    (     (parameter_12 = '0')
                         and (     (IMP.IMF_TRANSACTION_DATE >= to_date(parameter_0, 'YYYYMMDD') )
                              and (IMP.IMF_TRANSACTION_DATE <= to_date(parameter_1, 'YYYYMMDD') )
                             )
                        )
                    or (     (parameter_12 = '1')
                        and (IMP.IMF_TRANSACTION_DATE <= to_date(parameter_1, 'YYYYMMDD') ) )
                   )
            union all
            select 'REEL_M' INFO
                 , IMP.ACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION_ID
                 , IMP.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
                 , ACC.ACC_NUMBER FIN_NUMBER
                 , DES.DES_DESCRIPTION_SUMMARY FIN_DESCR
                 , DES.DES_DESCRIPTION_LARGE FIN_LARGE_DESCR
                 , (select ACC.ACC_NUMBER
                      from ACS_ACCOUNT ACC
                         , ACT_FINANCIAL_IMPUTATION IMC
                     where IMC.ACT_FINANCIAL_IMPUTATION_ID = ACR_FUNCTIONS.GetFinancialImputationId(IMP.ACT_FINANCIAL_IMPUTATION_ID)
                       and IMC.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID) ACC_NUMBER_CE
                 , IMP.IMF_TRANSACTION_DATE IMF_TRANSACTION_DATE
                 , IMP.IMF_VALUE_DATE IMF_VALUE_DATE
                 , IMP.IMF_DESCRIPTION IMF_DESCRIPTION
                 , IMP.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
                 , (select ACD.ACC_NUMBER
                      from ACS_ACCOUNT ACD
                     where ACD.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID) DIV_NUMBER
                 , (select DED.DES_DESCRIPTION_SUMMARY
                      from ACS_DESCRIPTION DED
                     where DED.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID
                       and DED.PC_LANG_ID = vpc_lang_id) DIV_DESCR
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
                 , IMP.IMF_EXCHANGE_RATE IMF_EXCHANGE_RATE
                 , IMP.IMF_AMOUNT_LC_D IMF_AMOUNT_LC_D
                 , IMP.IMF_AMOUNT_LC_C IMF_AMOUNT_LC_C
                 , IMP.IMF_AMOUNT_FC_D IMF_AMOUNT_FC_D
                 , IMP.IMF_AMOUNT_FC_C IMF_AMOUNT_FC_C
                 , IMP.ACS_PERIOD_ID ACS_PERIOD_ID
                 , IMP.IMF_TYPE IMF_TYPE
                 , ACT_FUNCTIONS.AuxAccountFromImputation(IMP.ACT_FINANCIAL_IMPUTATION_ID) ACS_AUXILIARY_ACCOUNT_ID
                 , ACS_FUNCTION.GetAccountNumber(ACT_FUNCTIONS.AuxAccountFromImputation(IMP.ACT_FINANCIAL_IMPUTATION_ID) ) AUX_NUMBER
                 , ACS_FUNCTION.GetAccountDescriptionSummary(ACT_FUNCTIONS.AuxAccountFromImputation(IMP.ACT_FINANCIAL_IMPUTATION_ID) ) AUX_SHORT_DESCR
                 , IMP.DIC_IMP_FREE1_ID DIC_IMP_FREE1_ID
                 , IMP.DIC_IMP_FREE2_ID DIC_IMP_FREE2_ID
                 , IMP.DIC_IMP_FREE3_ID DIC_IMP_FREE3_ID
                 , IMP.DIC_IMP_FREE4_ID DIC_IMP_FREE4_ID
                 , IMP.DIC_IMP_FREE5_ID DIC_IMP_FREE5_ID
                 , IMP.DOC_RECORD_ID DOC_RECORD_ID
                 , IMP.FAM_FIXED_ASSETS_ID FAM_FIXED_ASSETS_ID
                 , IMP.GCO_GOOD_ID GCO_GOOD_ID
                 , IMP.PAC_PERSON_ID PAC_PERSON_ID
                 , IMP.HRM_PERSON_ID HRM_PERSON_ID
                 , IMP.IMF_NUMBER IMF_NUMBER
                 , IMP.IMF_NUMBER2 IMF_NUMBER2
                 , IMP.IMF_NUMBER3 IMF_NUMBER3
                 , IMP.IMF_NUMBER4 IMF_NUMBER4
                 , IMP.IMF_NUMBER5 IMF_NUMBER5
                 , IMP.IMF_TEXT1 IMF_TEXT1
                 , IMP.IMF_TEXT2 IMF_TEXT2
                 , IMP.IMF_TEXT3 IMF_TEXT3
                 , IMP.IMF_TEXT4 IMF_TEXT4
                 , IMP.IMF_TEXT5 IMF_TEXT5
                 , DOC.ACT_DOCUMENT_ID ACT_DOCUMENT_ID
                 , DOC.DOC_NUMBER DOC_NUMBER
                 , (select PAR.DOC_DATE_DELIVERY
                      from ACT_PART_IMPUTATION PAR
                     where PAR.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID) DOC_DATE_DELIVERY
                 , DOC.ACT_ACT_JOURNAL_ID ACT_ACT_JOURNAL_ID
                 , JOU.ACT_JOURNAL_ID ACT_JOURNAL_ID
                 , JOU.JOU_NUMBER JOU_NUMBER
                 , JOU.JOU_DESCRIPTION JOU_DESCRIPTION
                 , ETA.C_ETAT_JOURNAL C_ETAT_JOURNAL
                 , (select SCA.C_TYPE_CUMUL
                      from ACJ_SUB_SET_CAT SCA
                     where SCA.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
                       and SCA.C_SUB_SET = 'ACC') C_TYPE_CUMUL
                 , ACC.ACC_DETAIL_PRINTING ACC_DETAIL_PRINTING
                 , JOU.C_TYPE_JOURNAL C_TYPE_JOURNAL
                 , 0 PER_AMOUNT_D
                 , 0 PER_AMOUNT_C
                 , 0 ACB_BUDGET_ID
                 , 0 ACB_BUDGET_VERSION_ID
                 , 0 ACB_GLOBAL_BUDGET_ID
              from ACT_FINANCIAL_IMPUTATION IMP
                 , ACS_FINANCIAL_ACCOUNT FIN
                 , ACS_PERIOD PER
                 , ACT_DOCUMENT DOC
                 , ACT_JOURNAL JOU
                 , ACT_ETAT_JOURNAL ETA
                 , ACS_ACCOUNT ACC
                 , ACS_DESCRIPTION DES
                 , (select LIS_ID_1
                      from COM_LIST
                     where LIS_JOB_ID = to_number(procparam_4)
                       and LIS_CODE = 'ACT_FINANCIAL_IMPUTATION_ID') LIS
             where IMP.ACT_FINANCIAL_IMPUTATION_ID = LIS.LIS_ID_1
               and FIN.ACS_FINANCIAL_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID
               and DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
               and JOU.ACT_JOURNAL_ID = DOC.ACT_JOURNAL_ID
               and ETA.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
               and ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
               and DES.ACS_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
               and DES.PC_LANG_ID = vpc_lang_id
               and PER.ACS_PERIOD_ID = IMP.ACS_PERIOD_ID
               and C_TYPE_PERIOD <> '1'
               and ETA.C_SUB_SET = 'ACC'
               and (    (     (parameter_2 = '1')
                         and (ETA.C_ETAT_JOURNAL = 'BRO') )
                    or (     (parameter_3 = '1')
                        and (ETA.C_ETAT_JOURNAL = 'PROV') )
                    or (     (parameter_4 = '1')
                        and (ETA.C_ETAT_JOURNAL = 'DEF') )
                   )
               and (    (     (parameter_12 = '0')
                         and (     (IMP.IMF_TRANSACTION_DATE >= to_date(parameter_0, 'YYYYMMDD') )
                              and (IMP.IMF_TRANSACTION_DATE <= to_date(parameter_1, 'YYYYMMDD') )
                             )
                        )
                    or (     (parameter_12 = '1')
                        and (IMP.IMF_TRANSACTION_DATE <= to_date(parameter_1, 'YYYYMMDD') ) )
                   )
            union all
            select 'REEL_D' INFO
                 , IMP.ACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION_ID
                 , IMP.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
                 , ACC.ACC_NUMBER FIN_NUMBER
                 , DES.DES_DESCRIPTION_SUMMARY FIN_DESCR
                 , DES.DES_DESCRIPTION_LARGE FIN_LARGE_DESCR
                 , (select ACC.ACC_NUMBER
                      from ACS_ACCOUNT ACC
                         , ACT_FINANCIAL_IMPUTATION IMC
                     where IMC.ACT_FINANCIAL_IMPUTATION_ID = ACR_FUNCTIONS.GetFinancialImputationId(IMP.ACT_FINANCIAL_IMPUTATION_ID)
                       and IMC.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID) ACC_NUMBER_CE
                 , IMP.IMF_TRANSACTION_DATE IMF_TRANSACTION_DATE
                 , IMP.IMF_VALUE_DATE IMF_VALUE_DATE
                 , IMP.IMF_DESCRIPTION IMF_DESCRIPTION
                 , IMP.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
                 , (select ACD.ACC_NUMBER
                      from ACS_ACCOUNT ACD
                     where ACD.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID) DIV_NUMBER
                 , (select DED.DES_DESCRIPTION_SUMMARY
                      from ACS_DESCRIPTION DED
                     where DED.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID
                       and DED.PC_LANG_ID = vpc_lang_id) DIV_DESCR
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
                 , IMP.IMF_EXCHANGE_RATE IMF_EXCHANGE_RATE
                 , IMP.IMF_AMOUNT_LC_D IMF_AMOUNT_LC_D
                 , IMP.IMF_AMOUNT_LC_C IMF_AMOUNT_LC_C
                 , IMP.IMF_AMOUNT_FC_D IMF_AMOUNT_FC_D
                 , IMP.IMF_AMOUNT_FC_C IMF_AMOUNT_FC_C
                 , IMP.ACS_PERIOD_ID ACS_PERIOD_ID
                 , IMP.IMF_TYPE IMF_TYPE
                 , ACT_FUNCTIONS.AuxAccountFromImputation(IMP.ACT_FINANCIAL_IMPUTATION_ID) ACS_AUXILIARY_ACCOUNT_ID
                 , ACS_FUNCTION.GetAccountNumber(ACT_FUNCTIONS.AuxAccountFromImputation(IMP.ACT_FINANCIAL_IMPUTATION_ID) ) AUX_NUMBER
                 , ACS_FUNCTION.GetAccountDescriptionSummary(ACT_FUNCTIONS.AuxAccountFromImputation(IMP.ACT_FINANCIAL_IMPUTATION_ID) ) AUX_SHORT_DESCR
                 , IMP.DIC_IMP_FREE1_ID DIC_IMP_FREE1_ID
                 , IMP.DIC_IMP_FREE2_ID DIC_IMP_FREE2_ID
                 , IMP.DIC_IMP_FREE3_ID DIC_IMP_FREE3_ID
                 , IMP.DIC_IMP_FREE4_ID DIC_IMP_FREE4_ID
                 , IMP.DIC_IMP_FREE5_ID DIC_IMP_FREE5_ID
                 , IMP.DOC_RECORD_ID DOC_RECORD_ID
                 , IMP.FAM_FIXED_ASSETS_ID FAM_FIXED_ASSETS_ID
                 , IMP.GCO_GOOD_ID GCO_GOOD_ID
                 , IMP.PAC_PERSON_ID PAC_PERSON_ID
                 , IMP.HRM_PERSON_ID HRM_PERSON_ID
                 , IMP.IMF_NUMBER IMF_NUMBER
                 , IMP.IMF_NUMBER2 IMF_NUMBER2
                 , IMP.IMF_NUMBER3 IMF_NUMBER3
                 , IMP.IMF_NUMBER4 IMF_NUMBER4
                 , IMP.IMF_NUMBER5 IMF_NUMBER5
                 , IMP.IMF_TEXT1 IMF_TEXT1
                 , IMP.IMF_TEXT2 IMF_TEXT2
                 , IMP.IMF_TEXT3 IMF_TEXT3
                 , IMP.IMF_TEXT4 IMF_TEXT4
                 , IMP.IMF_TEXT5 IMF_TEXT5
                 , DOC.ACT_DOCUMENT_ID ACT_DOCUMENT_ID
                 , DOC.DOC_NUMBER DOC_NUMBER
                 , (select PAR.DOC_DATE_DELIVERY
                      from ACT_PART_IMPUTATION PAR
                     where PAR.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID) DOC_DATE_DELIVERY
                 , DOC.ACT_ACT_JOURNAL_ID ACT_ACT_JOURNAL_ID
                 , JOU.ACT_JOURNAL_ID ACT_JOURNAL_ID
                 , JOU.JOU_NUMBER JOU_NUMBER
                 , JOU.JOU_DESCRIPTION JOU_DESCRIPTION
                 , (select ETA.C_ETAT_JOURNAL
                      from ACT_ETAT_JOURNAL ETA
                     where ETA.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
                       and ETA.C_SUB_SET = 'ACC'
                       and (    (     (parameter_2 = '1')
                                 and (ETA.C_ETAT_JOURNAL = 'BRO') )
                            or (     (parameter_3 = '1')
                                and (ETA.C_ETAT_JOURNAL = 'PROV') )
                            or (     (parameter_4 = '1')
                                and (ETA.C_ETAT_JOURNAL = 'DEF') )
                           ) ) C_ETAT_JOURNAL
                 , (select SCA.C_TYPE_CUMUL
                      from ACJ_SUB_SET_CAT SCA
                     where SCA.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
                       and SCA.C_SUB_SET = 'ACC') C_TYPE_CUMUL
                 , ACC.ACC_DETAIL_PRINTING ACC_DETAIL_PRINTING
                 , JOU.C_TYPE_JOURNAL C_TYPE_JOURNAL
                 , 0 PER_AMOUNT_D
                 , 0 PER_AMOUNT_C
                 , 0 ACB_BUDGET_ID
                 , 0 ACB_BUDGET_VERSION_ID
                 , 0 ACB_GLOBAL_BUDGET_ID
              from ACT_FINANCIAL_IMPUTATION IMP
                 , ACS_FINANCIAL_ACCOUNT FIN
                 , ACS_PERIOD PER
                 , ACT_DOCUMENT DOC
                 , ACT_JOURNAL JOU
                 , ACS_ACCOUNT ACC
                 , ACS_DESCRIPTION DES
                 , (select LIS_ID_1
                      from COM_LIST
                     where LIS_JOB_ID = to_number(procparam_4)
                       and LIS_CODE = 'ACT_FINANCIAL_IMPUTATION_ID') LIS
             where IMP.ACT_FINANCIAL_IMPUTATION_ID = LIS.LIS_ID_1
               and FIN.ACS_FINANCIAL_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID
               and DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
               and JOU.ACT_JOURNAL_ID = DOC.ACT_JOURNAL_ID
               and ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
               and DES.ACS_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
               and DES.PC_LANG_ID = vpc_lang_id
               and PER.ACS_PERIOD_ID = IMP.ACS_PERIOD_ID
               and C_TYPE_PERIOD <> '1'
               and parameter_17 = '1'
               and (    (     (parameter_12 = '0')
                         and (     (IMP.IMF_TRANSACTION_DATE >= to_date(parameter_0, 'YYYYMMDD') )
                              and (IMP.IMF_TRANSACTION_DATE <= to_date(parameter_1, 'YYYYMMDD') )
                             )
                        )
                    or (     (parameter_12 = '1')
                        and (IMP.IMF_TRANSACTION_DATE <= to_date(parameter_1, 'YYYYMMDD') ) )
                   )
            union all
            select 'REPORT' INFO
                 , 0 ACT_FINANCIAL_IMPUTATION_ID
                 , TOT.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
                 , ACC.ACC_NUMBER FIN_NUMBER
                 , DES.DES_DESCRIPTION_SUMMARY FIN_DESCR
                 , DES.DES_DESCRIPTION_LARGE FIN_LARGE_DESCR
                 , null ACC_NUMBER_CE
                 , to_date(procparam_0 || '0101', 'YYYYMMDD') IMF_TRANSACTION_DATE
                 , to_date(procparam_0 || '0101', 'YYYYMMDD') IMF_VALUE_DATE
                 , 'Report' IMF_DESCRIPTION
                 , TOT.ACS_DIVISION_ACCOUNT_ID
                 , (select ACD.ACC_NUMBER
                      from ACS_ACCOUNT ACD
                     where ACD.ACS_ACCOUNT_ID = TOT.ACS_DIVISION_ACCOUNT_ID) DIV_NUMBER
                 , (select DED.DES_DESCRIPTION_SUMMARY
                      from ACS_DESCRIPTION DED
                     where DED.ACS_ACCOUNT_ID = TOT.ACS_DIVISION_ACCOUNT_ID
                       and DED.PC_LANG_ID = vpc_lang_id) DIV_DESCR
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
                 , 0 IMF_EXCHANGE_RATE
                 , TOT.TOT_DEBIT_LC IMF_AMOUNT_LC_D
                 , TOT.TOT_CREDIT_LC IMF_AMOUNT_LC_C
                 , TOT.TOT_DEBIT_FC IMF_AMOUNT_FC_D
                 , TOT.TOT_CREDIT_FC IMF_AMOUNT_FC_C
                 , TOT.ACS_PERIOD_ID ACS_PERIOD_ID
                 , 'MAN' IMF_TYPE
                 , 0 ACS_AUXILIARY_ACCOUNT_ID
                 , null AUX_NUMBER
                 , null AUX_SHORT_DESCR
                 , null DIC_IMP_FREE1_ID
                 , null DIC_IMP_FREE2_ID
                 , null DIC_IMP_FREE3_ID
                 , null DIC_IMP_FREE4_ID
                 , null DIC_IMP_FREE5_ID
                 , null DOC_RECORD_ID
                 , null FAM_FIXED_ASSETS_ID
                 , null GCO_GOOD_ID
                 , null PAC_PERSON_ID
                 , null HRM_PERSON_ID
                 , null IMF_NUMBER
                 , null IMF_NUMBER2
                 , null IMF_NUMBER3
                 , null IMF_NUMBER4
                 , null IMF_NUMBER5
                 , null IMF_TEXT1
                 , null IMF_TEXT2
                 , null IMF_TEXT3
                 , null IMF_TEXT4
                 , null IMF_TEXT5
                 , 0 ACT_DOCUMENT_ID
                 , null DOC_NUMBER
                 , null DOC_DATE_DELIVERY
                 , 0 ACT_ACT_JOURNAL_ID
                 , 0 ACT_JOURNAL_ID
                 , null JOU_NUMBER
                 , null JOU_DESCRIPTION
                 , 'PROV' C_ETAT_JOURNAL
                 , TOT.C_TYPE_CUMUL
                 , ACC.ACC_DETAIL_PRINTING ACC_DETAIL_PRINTING
                 , 'OPB' C_TYPE_JOURNAL
                 , 0 PER_AMOUNT_D
                 , 0 PER_AMOUNT_C
                 , 0 ACB_BUDGET_ID
                 , 0 ACB_BUDGET_VERSION_ID
                 , 0 ACB_GLOBAL_BUDGET_ID
              from ACT_TOTAL_BY_PERIOD TOT
                 , ACS_FINANCIAL_ACCOUNT FIN
                 , ACS_PERIOD PER
                 , ACS_ACCOUNT ACC
                 , ACS_DESCRIPTION DES
                 , (select LIS_ID_1
                      from COM_LIST
                     where LIS_JOB_ID = to_number(procparam_4)
                       and LIS_CODE = 'ACT_TOTAL_BY_PERIOD_ID') LIS
             where TOT.ACT_TOTAL_BY_PERIOD_ID = LIS.LIS_ID_1
               and FIN.ACS_FINANCIAL_ACCOUNT_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID
               and ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
               and DES.ACS_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
               and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
               and DES.PC_LANG_ID = vpc_lang_id
               and PER.ACS_PERIOD_ID = TOT.ACS_PERIOD_ID
               and PER.C_TYPE_PERIOD = '1'
               and parameter_3 = '1'
               and parameter_12 = '1'
            union all
            select 'RPT_M' INFO
                 , 0 ACT_FINANCIAL_IMPUTATION_ID
                 , TOT.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
                 , ACC.ACC_NUMBER FIN_NUMBER
                 , DES.DES_DESCRIPTION_SUMMARY FIN_DESCR
                 , DES.DES_DESCRIPTION_LARGE FIN_LARGE_DESCR
                 , null ACC_NUMBER_CE
                 , to_date(procparam_0 || '0101', 'YYYYMMDD') IMF_TRANSACTION_DATE
                 , to_date(procparam_0 || '0101', 'YYYYMMDD') IMF_VALUE_DATE
                 , 'Report' IMF_DESCRIPTION
                 , TOT.ACS_DIVISION_ACCOUNT_ID
                 , (select ACD.ACC_NUMBER
                      from ACS_ACCOUNT ACD
                     where ACD.ACS_ACCOUNT_ID = TOT.ACS_DIVISION_ACCOUNT_ID) DIV_NUMBER
                 , (select DED.DES_DESCRIPTION_SUMMARY
                      from ACS_DESCRIPTION DED
                     where DED.ACS_ACCOUNT_ID = TOT.ACS_DIVISION_ACCOUNT_ID
                       and DED.PC_LANG_ID = vpc_lang_id) DIV_DESCR
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
                 , 0 IMF_EXCHANGE_RATE
                 , TOT.TOT_DEBIT_LC IMF_AMOUNT_LC_D
                 , TOT.TOT_CREDIT_LC IMF_AMOUNT_LC_C
                 , TOT.TOT_DEBIT_FC IMF_AMOUNT_FC_D
                 , TOT.TOT_CREDIT_FC IMF_AMOUNT_FC_C
                 , TOT.ACS_PERIOD_ID ACS_PERIOD_ID
                 , 'MAN' IMF_TYPE
                 , 0 ACS_AUXILIARY_ACCOUNT_ID
                 , null AUX_NUMBER
                 , null AUX_SHORT_DESCR
                 , null DIC_IMP_FREE1_ID
                 , null DIC_IMP_FREE2_ID
                 , null DIC_IMP_FREE3_ID
                 , null DIC_IMP_FREE4_ID
                 , null DIC_IMP_FREE5_ID
                 , null DOC_RECORD_ID
                 , null FAM_FIXED_ASSETS_ID
                 , null GCO_GOOD_ID
                 , null PAC_PERSON_ID
                 , null HRM_PERSON_ID
                 , null IMF_NUMBER
                 , null IMF_NUMBER2
                 , null IMF_NUMBER3
                 , null IMF_NUMBER4
                 , null IMF_NUMBER5
                 , null IMF_TEXT1
                 , null IMF_TEXT2
                 , null IMF_TEXT3
                 , null IMF_TEXT4
                 , null IMF_TEXT5
                 , 0 ACT_DOCUMENT_ID
                 , null DOC_NUMBER
                 , null DOC_DATE_DELIVERY
                 , 0 ACT_ACT_JOURNAL_ID
                 , 0 ACT_JOURNAL_ID
                 , null JOU_NUMBER
                 , null JOU_DESCRIPTION
                 , 'PROV' C_ETAT_JOURNAL
                 , TOT.C_TYPE_CUMUL
                 , ACC.ACC_DETAIL_PRINTING ACC_DETAIL_PRINTING
                 , 'OPB' C_TYPE_JOURNAL
                 , 0 PER_AMOUNT_D
                 , 0 PER_AMOUNT_C
                 , 0 ACB_BUDGET_ID
                 , 0 ACB_BUDGET_VERSION_ID
                 , 0 ACB_GLOBAL_BUDGET_ID
              from ACT_TOTAL_BY_PERIOD TOT
                 , ACS_FINANCIAL_ACCOUNT FIN
                 , ACS_PERIOD PER
                 , ACS_ACCOUNT ACC
                 , ACS_DESCRIPTION DES
                 , (select LIS_ID_1
                      from COM_LIST
                     where LIS_JOB_ID = to_number(procparam_4)
                       and LIS_CODE = 'ACT_TOTAL_BY_PERIOD_ID') LIS
             where TOT.ACT_TOTAL_BY_PERIOD_ID = LIS.LIS_ID_1
               and FIN.ACS_FINANCIAL_ACCOUNT_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID
               and ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
               and DES.ACS_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
               and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
               and PER.ACS_PERIOD_ID = TOT.ACS_PERIOD_ID
               and PER.C_TYPE_PERIOD = '1'
               and DES.PC_LANG_ID = vpc_lang_id
               and parameter_3 = '1'
               and parameter_12 = '1'
            union all
            select 'RPT_D' INFO
                 , 0 ACT_FINANCIAL_IMPUTATION_ID
                 , TOT.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
                 , ACC.ACC_NUMBER FIN_NUMBER
                 , DES.DES_DESCRIPTION_SUMMARY FIN_DESCR
                 , DES.DES_DESCRIPTION_LARGE FIN_LARGE_DESCR
                 , null ACC_NUMBER_CE
                 , to_date(procparam_0 || '0101', 'YYYYMMDD') IMF_TRANSACTION_DATE
                 , to_date(procparam_0 || '0101', 'YYYYMMDD') IMF_VALUE_DATE
                 , 'Report' IMF_DESCRIPTION
                 , TOT.ACS_DIVISION_ACCOUNT_ID
                 , (select ACD.ACC_NUMBER
                      from ACS_ACCOUNT ACD
                     where ACD.ACS_ACCOUNT_ID = TOT.ACS_DIVISION_ACCOUNT_ID) DIV_NUMBER
                 , (select DED.DES_DESCRIPTION_SUMMARY
                      from ACS_DESCRIPTION DED
                     where DED.ACS_ACCOUNT_ID = TOT.ACS_DIVISION_ACCOUNT_ID
                       and DED.PC_LANG_ID = vpc_lang_id) DIV_DESCR
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
                 , 0 IMF_EXCHANGE_RATE
                 , TOT.TOT_DEBIT_LC IMF_AMOUNT_LC_D
                 , TOT.TOT_CREDIT_LC IMF_AMOUNT_LC_C
                 , TOT.TOT_DEBIT_FC IMF_AMOUNT_FC_D
                 , TOT.TOT_CREDIT_FC IMF_AMOUNT_FC_C
                 , TOT.ACS_PERIOD_ID ACS_PERIOD_ID
                 , 'MAN' IMF_TYPE
                 , 0 ACS_AUXILIARY_ACCOUNT_ID
                 , null AUX_NUMBER
                 , null AUX_SHORT_DESCR
                 , null DIC_IMP_FREE1_ID
                 , null DIC_IMP_FREE2_ID
                 , null DIC_IMP_FREE3_ID
                 , null DIC_IMP_FREE4_ID
                 , null DIC_IMP_FREE5_ID
                 , null DOC_RECORD_ID
                 , null FAM_FIXED_ASSETS_ID
                 , null GCO_GOOD_ID
                 , null PAC_PERSON_ID
                 , null HRM_PERSON_ID
                 , null IMF_NUMBER
                 , null IMF_NUMBER2
                 , null IMF_NUMBER3
                 , null IMF_NUMBER4
                 , null IMF_NUMBER5
                 , null IMF_TEXT1
                 , null IMF_TEXT2
                 , null IMF_TEXT3
                 , null IMF_TEXT4
                 , null IMF_TEXT5
                 , 0 ACT_DOCUMENT_ID
                 , null DOC_NUMBER
                 , null DOC_DATE_DELIVERY
                 , 0 ACT_ACT_JOURNAL_ID
                 , 0 ACT_JOURNAL_ID
                 , null JOU_NUMBER
                 , null JOU_DESCRIPTION
                 , 'PROV' C_ETAT_JOURNAL
                 , TOT.C_TYPE_CUMUL
                 , ACC.ACC_DETAIL_PRINTING ACC_DETAIL_PRINTING
                 , 'OPB' C_TYPE_JOURNAL
                 , 0 PER_AMOUNT_D
                 , 0 PER_AMOUNT_C
                 , 0 ACB_BUDGET_ID
                 , 0 ACB_BUDGET_VERSION_ID
                 , 0 ACB_GLOBAL_BUDGET_ID
              from ACT_TOTAL_BY_PERIOD TOT
                 , ACS_FINANCIAL_ACCOUNT FIN
                 , ACS_PERIOD PER
                 , ACS_ACCOUNT ACC
                 , ACS_DESCRIPTION DES
                 , (select LIS_ID_1
                      from COM_LIST
                     where LIS_JOB_ID = to_number(procparam_4)
                       and LIS_CODE = 'ACT_TOTAL_BY_PERIOD_ID') LIS
             where TOT.ACT_TOTAL_BY_PERIOD_ID = LIS.LIS_ID_1
               and FIN.ACS_FINANCIAL_ACCOUNT_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID
               and ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
               and DES.ACS_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
               and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
               and DES.PC_LANG_ID = vpc_lang_id
               and PER.ACS_PERIOD_ID = TOT.ACS_PERIOD_ID
               and PER.C_TYPE_PERIOD = '1'
               and parameter_3 = '1'
               and parameter_17 = '1'
               and parameter_12 = '1'
            union all
            select 'BUDGET' INFO
                 , 0 ACT_FINANCIAL_IMPUTATION_ID
                 , GLO.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID
                 , ACC.ACC_NUMBER FIN_NUMBER
                 , DES.DES_DESCRIPTION_SUMMARY FIN_DESCR
                 , DES.DES_DESCRIPTION_LARGE FIN_LARGE_DESCR
                 , null ACC_NUMBER_CE
                 , to_date(procparam_0 || '0101', 'YYYYMMDD') IMF_TRANSACTION_DATE
                 , to_date(procparam_0 || '0101', 'YYYYMMDD') IMF_VALUE_DATE
                 , null IMF_DESCRIPTION
                 , GLO.ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
                 , (select ACD.ACC_NUMBER
                      from ACS_ACCOUNT ACD
                     where ACD.ACS_ACCOUNT_ID = GLO.ACS_DIVISION_ACCOUNT_ID) DIV_NUMBER
                 , (select DED.DES_DESCRIPTION_SUMMARY
                      from ACS_DESCRIPTION DED
                     where DED.ACS_ACCOUNT_ID = GLO.ACS_DIVISION_ACCOUNT_ID
                       and DED.PC_LANG_ID = vpc_lang_id) DIV_DESCR
                 , 0 ACS_TAX_CODE_ID
                 , null TAX_NUMBER
                 , GLO.ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID
                 , (select CUB.CURRENCY
                      from PCS.PC_CURR CUB
                         , ACS_FINANCIAL_CURRENCY CFB
                     where CFB.ACS_FINANCIAL_CURRENCY_ID = GLO.ACS_FINANCIAL_CURRENCY_ID
                       and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_MB
                 , 0 ACS_FINANCIAL_CURRENCY_ID
                 , null CURRENCY_ME
                 , 0 IMF_EXCHANGE_RATE
                 , 0 IMF_AMOUNT_LC_D
                 , 0 IMF_AMOUNT_LC_C
                 , 0 IMF_AMOUNT_FC_D
                 , 0 IMF_AMOUNT_FC_C
                 , PERB.ACS_PERIOD_ID ACS_PERIOD_ID
                 , 'MAN' IMF_TYPE
                 , 0 ACS_AUXILIARY_ACCOUNT_ID
                 , null AUX_NUMBER
                 , null AUX_SHORT_DESCR
                 , GLO.DIC_IMP_FREE1_ID
                 , GLO.DIC_IMP_FREE2_ID
                 , GLO.DIC_IMP_FREE3_ID
                 , GLO.DIC_IMP_FREE4_ID
                 , GLO.DIC_IMP_FREE5_ID
                 , GLO.DOC_RECORD_ID
                 , GLO.FAM_FIXED_ASSETS_ID
                 , GLO.GCO_GOOD_ID
                 , GLO.PAC_PERSON_ID
                 , GLO.HRM_PERSON_ID
                 , GLO.IMF_NUMBER
                 , GLO.IMF_NUMBER2
                 , GLO.IMF_NUMBER3
                 , GLO.IMF_NUMBER4
                 , GLO.IMF_NUMBER5
                 , GLO.IMF_TEXT1
                 , GLO.IMF_TEXT2
                 , GLO.IMF_TEXT3
                 , GLO.IMF_TEXT4
                 , GLO.IMF_TEXT5
                 , 0 ACT_DOCUMENT_ID
                 , null DOC_NUMBER
                 , null DOC_DATE_DELIVERY
                 , 0 ACT_ACT_JOURNAL_ID
                 , 0 ACT_JOURNAL_ID
                 , null JOU_NUMBER
                 , null JOU_DESCRIPTION
                 , null C_ETAT_JOURNAL
                 , null C_TYPE_CUMUL
                 , ACC.ACC_DETAIL_PRINTING ACC_DETAIL_PRINTING
                 , null C_TYPE_JOURNAL
                 , PERB.PER_AMOUNT_D PER_AMOUNT_D
                 , PERB.PER_AMOUNT_C PER_AMOUNT_C
                 , VER.ACB_BUDGET_ID ACB_BUDGET_ID
                 , VER.ACB_BUDGET_VERSION_ID ACB_BUDGET_VERSION_ID
                 , GLO.ACB_GLOBAL_BUDGET_ID ACB_GLOBAL_BUDGET_ID
              from ACB_GLOBAL_BUDGET GLO
                 , ACS_FINANCIAL_ACCOUNT FIN
                 , ACB_PERIOD_AMOUNT PERB
                 , ACS_PERIOD PER
                 , ACB_BUDGET_VERSION VER
                 , ACS_ACCOUNT ACC
                 , ACS_DESCRIPTION DES
                 , (select LIS_ID_1
                      from COM_LIST
                     where LIS_JOB_ID = to_number(procparam_4)
                       and LIS_CODE = 'ACB_GLOBAL_BUDGET_ID') LIS
             where GLO.ACB_GLOBAL_BUDGET_ID = LIS.LIS_ID_1
               and VER.ACB_BUDGET_VERSION_ID = GLO.ACB_BUDGET_VERSION_ID
               and PERB.ACB_GLOBAL_BUDGET_ID = GLO.ACB_GLOBAL_BUDGET_ID
               and PER.ACS_PERIOD_ID = PERB.ACS_PERIOD_ID
               and FIN.ACS_FINANCIAL_ACCOUNT_ID = GLO.ACS_FINANCIAL_ACCOUNT_ID
               and ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
               and DES.ACS_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
               and DES.PC_LANG_ID = vpc_lang_id
               and parameter_15 = '1'
               and PER.PER_START_DATE >= to_date(parameter_0, 'YYYYMMDD')
               and PER.PER_END_DATE <= to_date(parameter_1, 'YYYYMMDD')
            union all
            select 'VIDE' INFO
                 , null ACT_FINANCIAL_IMPUTATION_ID
                 , FIN.ACS_FINANCIAL_ACCOUNT_ID
                 , ACC.ACC_NUMBER FIN_NUMBER
                 , DES.DES_DESCRIPTION_SUMMARY FIN_DESCR
                 , DES.DES_DESCRIPTION_LARGE FIN_LARGE_DESCR
                 , null ACC_NUMBER_CE
                 , null IMF_TRANSACTION_DATE
                 , null IMF_VALUE_DATE
                 , null IMF_DESCRIPTION
                 , 0 ACS_DIVISION_ACCOUNT_ID
                 , null DIV_NUMBER
                 , null DIV_DESCR
                 , 0 ACS_TAX_CODE_ID
                 , null TAX_NUMBER
                 , null ACS_ACS_FINANCIAL_CURRENCY_ID
                 , null CURRENCY_MB
                 , null ACS_FINANCIAL_CURRENCY_ID
                 , (select max(CUB.CURRENCY)
                      from PCS.PC_CURR CUB
                         , ACS_FINANCIAL_CURRENCY CFB
                         , ACT_FINANCIAL_IMPUTATION IMP
                     where IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                       and CFB.ACS_FINANCIAL_CURRENCY_ID = IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
                       and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_ME
                 , 0 IMF_EXCHANGE_RATE
                 , 0 IMF_AMOUNT_LC_D
                 , 0 IMF_AMOUNT_LC_C
                 , 0 IMF_AMOUNT_FC_D
                 , 0 IMF_AMOUNT_FC_C
                 , 0 ACS_PERIOD_ID
                 , 'MAN' IMF_TYPE
                 , 0 ACS_AUXILIARY_ACCOUNT_ID
                 , null AUX_NUMBER
                 , null AUX_SHORT_DESCR
                 , null DIC_IMP_FREE1_ID
                 , null DIC_IMP_FREE2_ID
                 , null DIC_IMP_FREE3_ID
                 , null DIC_IMP_FREE4_ID
                 , null DIC_IMP_FREE5_ID
                 , null DOC_RECORD_ID
                 , null FAM_FIXED_ASSETS_ID
                 , null GCO_GOOD_ID
                 , null PAC_PERSON_ID
                 , null HRM_PERSON_ID
                 , null IMF_NUMBER
                 , null IMF_NUMBER2
                 , null IMF_NUMBER3
                 , null IMF_NUMBER4
                 , null IMF_NUMBER5
                 , null IMF_TEXT1
                 , null IMF_TEXT2
                 , null IMF_TEXT3
                 , null IMF_TEXT4
                 , null IMF_TEXT5
                 , 0 ACT_DOCUMENT_ID
                 , null DOC_NUMBER
                 , null DOC_DATE_DELIVERY
                 , 0 ACT_ACT_JOURNAL_ID
                 , 0 ACT_JOURNAL_ID
                 , null JOU_NUMBER
                 , null JOU_DESCRIPTION
                 , 'PROV' C_ETAT_JOURNAL
                 , null C_TYPE_CUMUL
                 , ACC.ACC_DETAIL_PRINTING ACC_DETAIL_PRINTING
                 , null C_TYPE_JOURNAL
                 , 0 PER_AMOUNT_D
                 , 0 PER_AMOUNT_C
                 , 0 ACB_BUDGET_ID
                 , 0 ACB_BUDGET_VERSION_ID
                 , 0 ACB_GLOBAL_BUDGET_ID
              from ACS_FINANCIAL_ACCOUNT FIN
                 , ACS_ACCOUNT ACC
                 , ACS_DESCRIPTION DES
                 , (select LIS_ID_1
                      from COM_LIST
                     where LIS_JOB_ID = to_number(procparam_4)
                       and LIS_CODE = 'ACS_FINANCIAL_ACCOUNT_ID') LIS
             where FIN.ACS_FINANCIAL_ACCOUNT_ID = LIS.LIS_ID_1
               and ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
               and ACC.ACS_ACCOUNT_ID = DES.ACS_ACCOUNT_ID
               and DES.PC_LANG_ID = vpc_lang_id
               and (     (parameter_16 = '1')
                    and FIN.ACS_FINANCIAL_ACCOUNT_ID not in(
                          select TOT.ACS_FINANCIAL_ACCOUNT_ID
                            from ACT_TOTAL_BY_PERIOD TOT
                               , ACS_PERIOD PER
                               , (select LIS_ID_1
                                    from COM_LIST
                                   where LIS_JOB_ID = to_number(procparam_4)
                                     and LIS_CODE = 'ACT_TOTAL_BY_PERIOD_ID') LIS
                           where TOT.ACT_TOTAL_BY_PERIOD_ID = LIS.LIS_ID_1
                             and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
                             and PER.ACS_PERIOD_ID = TOT.ACS_PERIOD_ID
                             and PER.C_TYPE_PERIOD = '1'
                             and parameter_3 = '1'
                             and parameter_12 = '1')
                   ) ) IMP_TOT
         , (select distinct FIN_NUMBER
                          , count(distinct ACS_FINANCIAL_CURRENCY_ID) CURRENCY_NO
                       from (select 'REEL' INFO
                                  , ACC.ACC_NUMBER FIN_NUMBER
                                  , IMP.ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID
                                  , (select SCA.C_TYPE_CUMUL
                                       from ACJ_SUB_SET_CAT SCA
                                      where SCA.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
                                        and SCA.C_SUB_SET = 'ACC') C_TYPE_CUMUL
                               from ACT_FINANCIAL_IMPUTATION IMP
                                  , ACS_FINANCIAL_ACCOUNT FIN
                                  , ACS_ACCOUNT ACC
                                  , ACT_JOURNAL JOU
                                  , ACT_DOCUMENT DOC
                                  , (select LIS_ID_1
                                       from COM_LIST
                                      where LIS_JOB_ID = to_number(procparam_4)
                                        and LIS_CODE = 'ACT_FINANCIAL_IMPUTATION_ID') LIS
                              where IMP.ACT_FINANCIAL_IMPUTATION_ID = LIS.LIS_ID_1
                                and FIN.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                                and FIN.ACS_FINANCIAL_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID
                                and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                                and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
                             union all
                             select 'REPORT' INFO
                                  , ACC.ACC_NUMBER FIN_NUMBER
                                  , TOT.ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID
                                  , TOT.C_TYPE_CUMUL
                               from ACT_TOTAL_BY_PERIOD TOT
                                  , ACS_FINANCIAL_ACCOUNT FIN
                                  , ACS_ACCOUNT ACC
                                  , (select LIS_ID_1
                                       from COM_LIST
                                      where LIS_JOB_ID = to_number(procparam_4)
                                        and LIS_CODE = 'ACT_TOTAL_BY_PERIOD_ID') LIS
                              where TOT.ACT_TOTAL_BY_PERIOD_ID = LIS.LIS_ID_1
                                and FIN.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                                and FIN.ACS_FINANCIAL_ACCOUNT_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID
                                and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
                             union all
                             select 'BUDGET' INFO
                                  , ACC.ACC_NUMBER FIN_NUMBER
                                  , GLO.ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID
                                  , null C_TYPE_CUMUL
                               from ACB_GLOBAL_BUDGET GLO
                                  , ACB_PERIOD_AMOUNT PERB
                                  , ACB_BUDGET_VERSION VER
                                  , ACS_ACCOUNT ACC
                                  , ACS_FINANCIAL_ACCOUNT FIN
                                  , (select LIS_ID_1
                                       from COM_LIST
                                      where LIS_JOB_ID = to_number(procparam_4)
                                        and LIS_CODE = 'ACB_GLOBAL_BUDGET_ID') LIS
                              where GLO.ACB_GLOBAL_BUDGET_ID = LIS.LIS_ID_1
                                and VER.ACB_BUDGET_VERSION_ID = GLO.ACB_BUDGET_VERSION_ID
                                and PERB.ACB_GLOBAL_BUDGET_ID = GLO.ACB_GLOBAL_BUDGET_ID
                                and FIN.ACS_FINANCIAL_ACCOUNT_ID = GLO.ACS_FINANCIAL_ACCOUNT_ID
                                and ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                                and parameter_15 = '1'
                             union all
                             select 'VIDE' INFO
                                  , ACC.ACC_NUMBER FIN_NUMBER
                                  , null ACS_FINANCIAL_CURRENCY_ID
                                  , null C_TYPE_CUMUL
                               from ACS_FINANCIAL_ACCOUNT FIN
                                  , ACS_ACCOUNT ACC
                                  , (select LIS_ID_1
                                       from COM_LIST
                                      where LIS_JOB_ID = to_number(procparam_4)
                                        and LIS_CODE = 'ACS_FINANCIAL_ACCOUNT_ID') LIS
                              where FIN.ACS_FINANCIAL_ACCOUNT_ID = LIS.LIS_ID_1
                                and ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                                and (        (parameter_16 = '0')
                                        and (    not exists(
                                                   select 1
                                                     from ACS_FINANCIAL_YEAR FYE
                                                        , ACS_PERIOD PER
                                                        , ACT_FINANCIAL_IMPUTATION IMP
                                                    where FYE.FYE_NO_EXERCICE = to_number(procparam_0)
                                                      and FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
                                                      and IMP.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                                                      and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                                                      and (    (    parameter_12 = 0
                                                                and PER.C_TYPE_PERIOD <> 1)
                                                           or parameter_12 = 1) )
                                             and not exists(
                                                   select 1
                                                     from ACS_FINANCIAL_YEAR FYE
                                                        , ACS_PERIOD PER
                                                        , ACT_TOTAL_BY_PERIOD TOT
                                                    where FYE.FYE_NO_EXERCICE = to_number(procparam_0)
                                                      and FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
                                                      and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                                                      and TOT.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                                                      and (    (    parameter_12 = 0
                                                                and PER.C_TYPE_PERIOD <> 1)
                                                           or parameter_12 = 1) )
                                            )
                                     or (parameter_16 = '1')
                                    ) ) IMP_TOT
                      where (    (    parameter_5 = '1'
                                  and C_TYPE_CUMUL = 'EXT')
                             or (    parameter_6 = '1'
                                 and C_TYPE_CUMUL = 'INT')
                             or (    parameter_7 = '1'
                                 and C_TYPE_CUMUL = 'PRE')
                             or (    parameter_8 = '1'
                                 and C_TYPE_CUMUL = 'ENG')
                             or (C_TYPE_CUMUL is null)
                            )
                   group by FIN_NUMBER) CYN
     where IMP_TOT.FIN_NUMBER = CYN.FIN_NUMBER
       and (    (     (parameter_11 is null)
                 and (     (IMP_TOT.FIN_NUMBER >= procparam_1)
                      and (IMP_TOT.FIN_NUMBER <= procparam_2) ) )
            or (     (parameter_11 is not null)
                and (ACS_FUNCTION.IsFinAccInClassif(IMP_TOT.ACS_FINANCIAL_ACCOUNT_ID, parameter_11) = '1') )
           )
       and (    (     (parameter_5 = '1')
                 and (C_TYPE_CUMUL = 'EXT') )
            or (     (parameter_6 = '1')
                and (C_TYPE_CUMUL = 'INT') )
            or (     (parameter_7 = '1')
                and (C_TYPE_CUMUL = 'PRE') )
            or (     (parameter_8 = '1')
                and (C_TYPE_CUMUL = 'ENG') )
            or (C_TYPE_CUMUL is null)
           )
       and (    (     (parameter_13 = '1')
                 and (IMP_TOT.ACS_TAX_CODE_ID is null)
                 and ( (IMP_TOT.IMF_TYPE) <> 'VAT') )
            or (parameter_13 = '0') );
end RPT_ACR_ACC_IMPUTATION_DETMCH1;
