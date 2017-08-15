--------------------------------------------------------
--  DDL for Procedure RPT_ACR_PAY_IMPUTATION_DET
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACR_PAY_IMPUTATION_DET" (
  aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, procparam_0    in     varchar2
, procparam_1    in     varchar2
, procparam_2    in     varchar2
, procparam_3    in     varchar2
, parameter_4    in     varchar2
, parameter_5    in     varchar2
, parameter_6    in     varchar2
, parameter_7    in     varchar2
, parameter_8    in     varchar2
, parameter_9    in     varchar2
, parameter_10   in     varchar2
, parameter_12   in     varchar2
, parameter_17   in     varchar2
, parameter_18   in     varchar2
, parameter_19   in     varchar2
, parameter_20   in     varchar2
, parameter_21   in     varchar2
, parameter_22   in     varchar2
, procuser_lanid in     PCS.PC_LANG.LANID%type
)
/**
* description used for report ACR_PAY_IMPUTATION_DET

* @author jliu 18 nov 2008
* @lastUpdate VHA 15 october 2013
* @public
* @param procparam_0: Account from
* @param procparam_1: Account to
* @param procparam_2: ACS_FINANCIAL_YEAR_ID
* @param procparam_3: Job ID (COM_LIST)
* @param parameter_4: IMF_TRANSACTION_DATE/DATE_TO/YEAR
* @param parameter_5: MF_TRANSACTION_DATE/DATE_TO/MONTH
* @param parameter_6: IMF_TRANSACTION_DATE/DATE_TO/DAY
* @param parameter_7: IC_ETAT_JOURNAL
* @param parameter_8: IC_ETAT_JOURNAL
* @param parameter_9: IC_ETAT_JOURNAL
* @param parameter_10: ACS_SUB_SET
* @param parameter_12: MATCHING
* @param parameter_17: Divisions (# = All  / null = selection (COM_LIST))
* @param parameter_18: C_TYPE_CUMUL
* @param parameter_19: C_TYPE_CUMUL
* @param parameter_20: C_TYPE_CUMUL
* @param parameter_21: C_TYPE_CUMUL
* @param parameter_22: ACS_FINANCIAL_ACCOUNT_ID (Collectiv_ID)
*/
is
  param5      varchar2(10);
  param6      varchar2(10);
  vpc_lang_id PCS.PC_LANG.PC_LANG_ID%type;
begin
  if (procuser_lanid is not null) then
          PCS.PC_I_LIB_SESSION.setLanId(procuser_lanid);
          vpc_lang_id  := PCS.PC_I_LIB_SESSION.GetUserLangId;
  end if;

  if     (procparam_0 is not null)
     and (length(trim(procparam_0) ) > 0) then
    ACR_FUNCTIONS.ACC_NUMBER1  := procparam_0;
  else
    ACR_FUNCTIONS.ACC_NUMBER1  := ' ';
  end if;

  if     (procparam_1 is not null)
     and (length(trim(procparam_1) ) > 0) then
    ACR_FUNCTIONS.ACC_NUMBER2  := procparam_1;
  end if;

  if     (procparam_2 is not null)
     and (length(trim(procparam_2) ) > 0) then
    ACR_FUNCTIONS.FIN_YEAR_ID  := procparam_2;
  end if;

  if ACS_FUNCTION.GetFirstDivision is not null then
    ACR_FUNCTIONS.EXIST_DIVISION  := 1;
  else
    ACR_FUNCTIONS.EXIST_DIVISION  := 0;
  end if;

  if length(parameter_5) = 1 then
    param5  := '0' || parameter_5;
  else
    param5  := parameter_5;
  end if;

  if length(parameter_6) = 1 then
    param6  := '0' || parameter_6;
  else
    param6  := parameter_6;
  end if;

  if (ACS_FUNCTION.ExistDIVI = 1) then
  open aRefCursor for
    select CAT.C_TYPE_CATALOGUE
         , ACC.FIN_COLLECTIVE
         , (select FIN.ACC_NUMBER
              from ACS_ACCOUNT FIN
             where FIN.ACS_ACCOUNT_ID = V_IMP.ACS_FINANCIAL_ACCOUNT_ID) FIN_COLLECTIVE2
         , V_IMP.ACS_FINANCIAL_ACCOUNT_ID
         , CRC.PC_CURR_ID
         , CRC2.PC_CURR_ID
         , SUB.ACS_SUB_SET_ID
         , SUB.C_SUB_SET
         , PAY.ACT_DET_PAYMENT_ID
         , PAY.DET_PAIED_LC
         , PAY.DET_PAIED_FC
         , PAY.DET_CHARGES_LC
         , PAY.DET_CHARGES_FC
         , PAY.DET_DISCOUNT_LC
         , PAY.DET_DISCOUNT_FC
         , PAY.DET_DEDUCTION_LC
         , PAY.DET_DEDUCTION_FC
         , DOC.DOC_NUMBER
         , DOC.ACT_DOCUMENT_ID
         , IMP.ACT_PART_IMPUTATION_ID
         , IMP.PAR_DOCUMENT
         , IMP.DOC_DATE_DELIVERY
         , PER.PER_NAME
         , PER.PER_FORENAME
         , PER.PER_ACTIVITY
         , CUR.PC_CURR_ID
         , CUR.CURRENCY
         , CUR2.PC_CURR_ID
         , CUR2.CURRENCY
         , LAN.LANID
         , V_AUX.C_TYPE_ACCOUNT
         , V_AUX.ACC_NUMBER
         , V_AUX.DES_DESCRIPTION_SUMMARY
         , V_AUX.DES_DESCRIPTION_LARGE
         , V_IMP.ACT_FINANCIAL_IMPUTATION_ID
         , V_IMP.IMF_DESCRIPTION
         , V_IMP.IMF_AMOUNT_LC_D
         , V_IMP.IMF_AMOUNT_LC_C
         , V_IMP.IMF_EXCHANGE_RATE
         , V_IMP.IMF_AMOUNT_FC_D
         , V_IMP.IMF_AMOUNT_FC_C
         , V_IMP.IMF_VALUE_DATE
         , V_IMP.IMF_TRANSACTION_DATE
         , V_IMP.ACS_FINANCIAL_CURRENCY_ID
         , V_IMP.ACS_AUXILIARY_ACCOUNT_ID
         , V_IMP.ACT_DET_PAYMENT_ID
         , V_IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
         , V_IMP.ACT_PART_IMPUTATION_ID
         , V_IMP.ACS_DIVISION_ACCOUNT_ID
         , V_IMP.DIV_NUMBER
         , V_IMP.JOU_NUMBER
         , V_IMP.C_ETAT_JOURNAL
         , V_IMP.C_TYPE_CUMUL
         , V_IMP.MATCHING
         , PRD.C_TYPE_PERIOD
         , CNY.CURRENCY_NO
         , decode(nvl(IMP.ACT_PART_IMPUTATION_ID, 0)
                , 0, decode(nvl(IMP.ACT_DOCUMENT_ID, 0), 0, 0, 1)
                , decode(ACT_FUNCTIONS.GetAmountOfPartImputation(IMP.ACT_PART_IMPUTATION_ID, 1) -
                         ACT_FUNCTIONS.GetTotalAmountOfPartImputation(IMP.ACT_PART_IMPUTATION_ID, 1)
                       , 0, 1
                       , 0
                        )
                 ) ctrl_pmt_doc
         , ACS_FUNCTION.GetAuxAccOwnerName(V_IMP.ACS_AUXILIARY_ACCOUNT_ID) G1_PER_NAME
         , ACS_FUNCTION.GetPer_short_Name(V_IMP.ACS_AUXILIARY_ACCOUNT_ID) G1_PER_SHORT_NAME
      from ACJ_CATALOGUE_DOCUMENT CAT
         , ACS_FINANCIAL_ACCOUNT ACC
         , ACS_FINANCIAL_CURRENCY CRC
         , ACS_FINANCIAL_CURRENCY CRC2
         , ACS_SUB_SET SUB
         , ACT_DET_PAYMENT PAY
         , ACT_DOCUMENT DOC
         , ACT_PART_IMPUTATION IMP
         , ACT_JOB JOB
         , PAC_PERSON PER
         , PCS.PC_CURR CUR
         , PCS.PC_CURR CUR2
         , PCS.PC_LANG LAN
         , V_ACS_AUXILIARY_ACCOUNT V_AUX
         , V_ACT_PAY_IMP_REPORT V_IMP
         , ACS_PERIOD PRD
         , (select distinct ACC_NUMBER
                          , count(distinct ACS_FINANCIAL_CURRENCY_ID) CURRENCY_NO
                       from V_ACT_PAY_IMP_REPORT V_IMP
                      where ACS_FINANCIAL_CURRENCY_ID <> ACS_ACS_FINANCIAL_CURRENCY_ID
                        and (    (    parameter_18 = '1'
                                  and V_IMP.C_TYPE_CUMUL = 'EXT')
                             or (    parameter_19 = '1'
                                 and V_IMP.C_TYPE_CUMUL = 'INT')
                             or (    parameter_20 = '1'
                                 and V_IMP.C_TYPE_CUMUL = 'PRE')
                             or (    parameter_21 = '1'
                                 and V_IMP.C_TYPE_CUMUL = 'ENG')
                            )
                   group by ACC_NUMBER) CNY
         , (select LIS_ID_1
              from COM_LIST
             where LIS_JOB_ID = to_number(procparam_3)
               and LIS_CODE = 'ACS_DIVISION_ACCOUNT_ID') LIS
     where V_AUX.ACS_AUXILIARY_ACCOUNT_ID = V_IMP.ACS_AUXILIARY_ACCOUNT_ID
       and V_AUX.ACC_NUMBER = CNY.ACC_NUMBER(+)
       and V_AUX.PC_LANG_ID = LAN.PC_LANG_ID
       and V_AUX.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
       and V_IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID(+)
       and V_IMP.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_FINANCIAL_ACCOUNT_ID
       and V_IMP.ACS_FINANCIAL_CURRENCY_ID = CRC.ACS_FINANCIAL_CURRENCY_ID
       and V_IMP.ACS_ACS_FINANCIAL_CURRENCY_ID = CRC2.ACS_FINANCIAL_CURRENCY_ID
       and V_IMP.ACT_DET_PAYMENT_ID = PAY.ACT_DET_PAYMENT_ID(+)
       and V_IMP.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID(+)
       and DOC.ACT_JOB_ID = JOB.ACT_JOB_ID(+)
       and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID(+)
       and CRC.PC_CURR_ID = CUR.PC_CURR_ID(+)
       and CRC2.PC_CURR_ID = CUR2.PC_CURR_ID(+)
       and IMP.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID(+)
       and V_IMP.ACS_PERIOD_ID = PRD.ACS_PERIOD_ID
       and (    (    parameter_7 = '1'
                 and V_IMP.C_ETAT_JOURNAL = 'BRO')
            or (    parameter_8 = '1'
                and V_IMP.C_ETAT_JOURNAL = 'PROV')
            or (    parameter_9 = '1'
                and V_IMP.C_ETAT_JOURNAL = 'DEF')
           )
       and (   parameter_22 = '#'
            or instr(',' || parameter_22 || ',', ',' || ACC.ACS_FINANCIAL_ACCOUNT_ID || ',') > 0)
       and (    (    parameter_18 = '1'
                 and V_IMP.C_TYPE_CUMUL = 'EXT')
            or (    parameter_19 = '1'
                and V_IMP.C_TYPE_CUMUL = 'INT')
            or (    parameter_20 = '1'
                and V_IMP.C_TYPE_CUMUL = 'PRE')
            or (    parameter_21 = '1'
                and V_IMP.C_TYPE_CUMUL = 'ENG')
           )
       and LAN.PC_LANG_ID = vpc_lang_id
       and ACC.FIN_COLLECTIVE = 1
       and V_IMP.IMF_TRANSACTION_DATE <= to_date(parameter_4 || param5 || param6, 'yyyyMMdd')
       and decode(parameter_10, 0, SUB.C_SUB_SET, SUB.ACS_SUB_SET_ID) = decode(parameter_10, 0, 'PAY', parameter_10)
       and (   parameter_12 = '1'
            or not(    parameter_12 = '0'
                   and V_IMP.MATCHING = 1) )
       and V_IMP.ACS_DIVISION_ACCOUNT_ID is not null
       and V_IMP.ACS_DIVISION_ACCOUNT_ID = LIS.LIS_ID_1;
else     -- if (ACS_FUNCTION.ExistDIVI = 0) = No divisions
  open aRefCursor for
    select CAT.C_TYPE_CATALOGUE
         , ACC.FIN_COLLECTIVE
         , (select FIN.ACC_NUMBER
              from ACS_ACCOUNT FIN
             where FIN.ACS_ACCOUNT_ID = V_IMP.ACS_FINANCIAL_ACCOUNT_ID) FIN_COLLECTIVE2
         , V_IMP.ACS_FINANCIAL_ACCOUNT_ID
         , CRC.PC_CURR_ID
         , CRC2.PC_CURR_ID
         , SUB.ACS_SUB_SET_ID
         , SUB.C_SUB_SET
         , PAY.ACT_DET_PAYMENT_ID
         , PAY.DET_PAIED_LC
         , PAY.DET_PAIED_FC
         , PAY.DET_CHARGES_LC
         , PAY.DET_CHARGES_FC
         , PAY.DET_DISCOUNT_LC
         , PAY.DET_DISCOUNT_FC
         , PAY.DET_DEDUCTION_LC
         , PAY.DET_DEDUCTION_FC
         , DOC.DOC_NUMBER
         , DOC.ACT_DOCUMENT_ID
         , IMP.ACT_PART_IMPUTATION_ID
         , IMP.PAR_DOCUMENT
         , IMP.DOC_DATE_DELIVERY
         , PER.PER_NAME
         , PER.PER_FORENAME
         , PER.PER_ACTIVITY
         , CUR.PC_CURR_ID
         , CUR.CURRENCY
         , CUR2.PC_CURR_ID
         , CUR2.CURRENCY
         , LAN.LANID
         , V_AUX.C_TYPE_ACCOUNT
         , V_AUX.ACC_NUMBER
         , V_AUX.DES_DESCRIPTION_SUMMARY
         , V_AUX.DES_DESCRIPTION_LARGE
         , V_IMP.ACT_FINANCIAL_IMPUTATION_ID
         , V_IMP.IMF_DESCRIPTION
         , V_IMP.IMF_AMOUNT_LC_D
         , V_IMP.IMF_AMOUNT_LC_C
         , V_IMP.IMF_EXCHANGE_RATE
         , V_IMP.IMF_AMOUNT_FC_D
         , V_IMP.IMF_AMOUNT_FC_C
         , V_IMP.IMF_VALUE_DATE
         , V_IMP.IMF_TRANSACTION_DATE
         , V_IMP.ACS_FINANCIAL_CURRENCY_ID
         , V_IMP.ACS_AUXILIARY_ACCOUNT_ID
         , V_IMP.ACT_DET_PAYMENT_ID
         , V_IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
         , V_IMP.ACT_PART_IMPUTATION_ID
         , V_IMP.ACS_DIVISION_ACCOUNT_ID
         , V_IMP.DIV_NUMBER
         , V_IMP.JOU_NUMBER
         , V_IMP.C_ETAT_JOURNAL
         , V_IMP.C_TYPE_CUMUL
         , V_IMP.MATCHING
         , PRD.C_TYPE_PERIOD
         , CNY.CURRENCY_NO
         , decode(nvl(IMP.ACT_PART_IMPUTATION_ID, 0)
                , 0, decode(nvl(IMP.ACT_DOCUMENT_ID, 0), 0, 0, 1)
                , decode(ACT_FUNCTIONS.GetAmountOfPartImputation(IMP.ACT_PART_IMPUTATION_ID, 1) -
                         ACT_FUNCTIONS.GetTotalAmountOfPartImputation(IMP.ACT_PART_IMPUTATION_ID, 1)
                       , 0, 1
                       , 0
                        )
                 ) ctrl_pmt_doc
         , ACS_FUNCTION.GetAuxAccOwnerName(V_IMP.ACS_AUXILIARY_ACCOUNT_ID) G1_PER_NAME
         , ACS_FUNCTION.GetPer_short_Name(V_IMP.ACS_AUXILIARY_ACCOUNT_ID) G1_PER_SHORT_NAME
      from ACJ_CATALOGUE_DOCUMENT CAT
         , ACS_FINANCIAL_ACCOUNT ACC
         , ACS_FINANCIAL_CURRENCY CRC
         , ACS_FINANCIAL_CURRENCY CRC2
         , ACS_SUB_SET SUB
         , ACT_DET_PAYMENT PAY
         , ACT_DOCUMENT DOC
         , ACT_PART_IMPUTATION IMP
         , ACT_JOB JOB
         , PAC_PERSON PER
         , PCS.PC_CURR CUR
         , PCS.PC_CURR CUR2
         , PCS.PC_LANG LAN
         , V_ACS_AUXILIARY_ACCOUNT V_AUX
         , V_ACT_PAY_IMP_REPORT V_IMP
         , ACS_PERIOD PRD
         , (select distinct ACC_NUMBER
                          , count(distinct ACS_FINANCIAL_CURRENCY_ID) CURRENCY_NO
                       from V_ACT_PAY_IMP_REPORT V_IMP
                      where ACS_FINANCIAL_CURRENCY_ID <> ACS_ACS_FINANCIAL_CURRENCY_ID
                        and (    (    parameter_18 = '1'
                                  and V_IMP.C_TYPE_CUMUL = 'EXT')
                             or (    parameter_19 = '1'
                                 and V_IMP.C_TYPE_CUMUL = 'INT')
                             or (    parameter_20 = '1'
                                 and V_IMP.C_TYPE_CUMUL = 'PRE')
                             or (    parameter_21 = '1'
                                 and V_IMP.C_TYPE_CUMUL = 'ENG')
                            )
                   group by ACC_NUMBER) CNY
     where V_AUX.ACS_AUXILIARY_ACCOUNT_ID = V_IMP.ACS_AUXILIARY_ACCOUNT_ID
       and V_AUX.ACC_NUMBER = CNY.ACC_NUMBER(+)
       and V_AUX.PC_LANG_ID = LAN.PC_LANG_ID
       and V_AUX.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
       and V_IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID(+)
       and V_IMP.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_FINANCIAL_ACCOUNT_ID
       and V_IMP.ACS_FINANCIAL_CURRENCY_ID = CRC.ACS_FINANCIAL_CURRENCY_ID
       and V_IMP.ACS_ACS_FINANCIAL_CURRENCY_ID = CRC2.ACS_FINANCIAL_CURRENCY_ID
       and V_IMP.ACT_DET_PAYMENT_ID = PAY.ACT_DET_PAYMENT_ID(+)
       and V_IMP.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID(+)
       and DOC.ACT_JOB_ID = JOB.ACT_JOB_ID(+)
       and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID(+)
       and CRC.PC_CURR_ID = CUR.PC_CURR_ID(+)
       and CRC2.PC_CURR_ID = CUR2.PC_CURR_ID(+)
       and IMP.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID(+)
       and V_IMP.ACS_PERIOD_ID = PRD.ACS_PERIOD_ID
       and (    (    parameter_7 = '1'
                 and V_IMP.C_ETAT_JOURNAL = 'BRO')
            or (    parameter_8 = '1'
                and V_IMP.C_ETAT_JOURNAL = 'PROV')
            or (    parameter_9 = '1'
                and V_IMP.C_ETAT_JOURNAL = 'DEF')
           )
       and (   parameter_22 = '#'
            or instr(',' || parameter_22 || ',', ',' || ACC.ACS_FINANCIAL_ACCOUNT_ID || ',') > 0)
       and (    (    parameter_18 = '1'
                 and V_IMP.C_TYPE_CUMUL = 'EXT')
            or (    parameter_19 = '1'
                and V_IMP.C_TYPE_CUMUL = 'INT')
            or (    parameter_20 = '1'
                and V_IMP.C_TYPE_CUMUL = 'PRE')
            or (    parameter_21 = '1'
                and V_IMP.C_TYPE_CUMUL = 'ENG')
           )
       and LAN.PC_LANG_ID = vpc_lang_id
       and ACC.FIN_COLLECTIVE = 1
       and V_IMP.IMF_TRANSACTION_DATE <= to_date(parameter_4 || param5 || param6, 'yyyyMMdd')
       and decode(parameter_10, 0, SUB.C_SUB_SET, SUB.ACS_SUB_SET_ID) = decode(parameter_10, 0, 'PAY', parameter_10)
       and (   parameter_12 = '1'
            or not(    parameter_12 = '0'
                   and V_IMP.MATCHING = 1) );
end if;
end RPT_ACR_PAY_IMPUTATION_DET;
