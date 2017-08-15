--------------------------------------------------------
--  DDL for Procedure RPT_ACR_FIN_IMP_CUMUL_REC
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACR_FIN_IMP_CUMUL_REC" (
  aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, date_to        in     varchar2
, parameter_0    in     number
, parameter_7    in     varchar2
, parameter_8    in     varchar2
, parameter_9    in     varchar2
, parameter_12   in     varchar2
, parameter_17   in     varchar2
, parameter_18   in     varchar2
, parameter_19   in     varchar2
, parameter_20   in     varchar2
, parameter_21   in     varchar2
, procparam_10   in     varchar2
, procuser_lanid in     PCS.PC_LANG.LANID%type
)
is
/**
* description used for report ACR_REC_IMPUTATION_DET

*author JLI  Dec.2007
*lastUpdate VHA 15 october 2013
*public
 @param date_to0                 IMF_TRANSACTION_DATE
 @param parameter_00             ACS_AUXILIARY_ACCOUNT_ID
 @param parameter_07             C_ETAT_JOURNAL
 @param parameter_08             C_ETAT_JOURNAL
 @param parameter_09             C_ETAT_JOURNAL
 @param parameter_012            MATCHING
 @param parameter_17             Divisions (# = All  / null = selection (COM_LIST))
 @param parameter_18             C_TYPE_CUMUL
 @param parameter_19             C_TYPE_CUMUL
 @param parameter_20             C_TYPE_CUMUL
 @param parameter_21             C_TYPE_CUMUL
 @param procparam_10            Job ID (COM_LIST)
*/
  vpc_lang_id PCS.PC_LANG.PC_LANG_ID%type := null;
begin
  if (procuser_lanid is not null) then
      PCS.PC_I_LIB_SESSION.setLanId(procuser_lanid);
      vpc_lang_id  := PCS.PC_I_LIB_SESSION.getUserlangId;
  end if;

  if (ACS_FUNCTION.ExistDIVI = 1) then
  open aRefCursor for
    select CAT.C_TYPE_CATALOGUE
         , FIN.FIN_COLLECTIVE
         , CUR.FIN_LOCAL_CURRENCY
         , PCR.CURRENCY
         , PCR2.CURRENCY CURRENCY_LC
         , V_IMP.IMF_AMOUNT_LC_D
         , V_IMP.IMF_AMOUNT_LC_C
         , V_IMP.IMF_AMOUNT_FC_D
         , V_IMP.IMF_AMOUNT_FC_C
         , V_IMP.IMF_TRANSACTION_DATE
         , V_IMP.ACS_FINANCIAL_CURRENCY_ID
         , V_IMP.ACS_AUXILIARY_ACCOUNT_ID
         , V_IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
         , V_IMP.C_ETAT_JOURNAL
         , V_IMP.ACT_FINANCIAL_IMPUTATION_ID
         , PRD.C_TYPE_PERIOD
      from ACJ_CATALOGUE_DOCUMENT CAT
         , ACS_AUX_ACCOUNT_S_FIN_CURR AUX
         , ACS_FINANCIAL_ACCOUNT FIN
         , ACS_FINANCIAL_CURRENCY CUR
         , ACS_FINANCIAL_CURRENCY CUL
         , ACT_DOCUMENT DOC
         , PCS.PC_CURR PCR
         , PCS.PC_CURR PCR2
         , V_ACT_REC_IMP_REPORT V_IMP
         , ACS_PERIOD PRD
         , ACS_AUX_ACCOUNT_S_FIN_CURR AUX_S
         , (select LIS_ID_1
              from COM_LIST
             where LIS_JOB_ID = to_number(procparam_10)
               and LIS_CODE = 'ACS_DIVISION_ACCOUNT_ID') LIS
     where V_IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID(+)
       and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID(+)
       and V_IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID(+)
       and V_IMP.ACS_FINANCIAL_CURRENCY_ID = CUR.ACS_FINANCIAL_CURRENCY_ID(+)
       and CUR.PC_CURR_ID = PCR.PC_CURR_ID(+)
       and V_IMP.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID(+)
       and V_IMP.ACS_FINANCIAL_ACCOUNT_ID = AUX.ACS_FINANCIAL_CURRENCY_ID(+)
       and V_IMP.ACS_ACS_FINANCIAL_CURRENCY_ID = CUL.ACS_FINANCIAL_CURRENCY_ID(+)
       and CUL.PC_CURR_ID = PCR2.PC_CURR_ID
       and FIN.FIN_COLLECTIVE = 1
       and V_IMP.ACS_PERIOD_ID = PRD.ACS_PERIOD_ID
       and AUX_S.ACS_AUXILIARY_ACCOUNT_ID = V_IMP.ACS_AUXILIARY_ACCOUNT_ID
       and AUX_S.ACS_FINANCIAL_CURRENCY_ID = V_IMP.ACS_FINANCIAL_CURRENCY_ID
       and V_IMP.IMF_TRANSACTION_DATE <= to_date(date_to, 'yyyyMMdd')
       and V_IMP.ACS_DIVISION_ACCOUNT_ID is not null
       and V_IMP.ACS_DIVISION_ACCOUNT_ID = LIS.LIS_ID_1
       and (    (    parameter_7 = '1'
                 and V_IMP.C_ETAT_JOURNAL = 'BRO')
            or (    parameter_8 = '1'
                and V_IMP.C_ETAT_JOURNAL = 'PROV')
            or (    parameter_9 = '1'
                and V_IMP.C_ETAT_JOURNAL = 'DEF')
           )
       and (    (    parameter_18 = '1'
                 and V_IMP.C_TYPE_CUMUL = 'EXT')
            or (    parameter_19 = '1'
                and V_IMP.C_TYPE_CUMUL = 'INT')
            or (    parameter_20 = '1'
                and V_IMP.C_TYPE_CUMUL = 'PRE')
            or (    parameter_21 = '1'
                and V_IMP.C_TYPE_CUMUL = 'ENG')
           )
       and (    (parameter_12 = '1')
            or (     (parameter_12 <> '1')
                and (CAT.C_TYPE_CATALOGUE is null) )
            or (     (parameter_12 <> '1')
                and not(CAT.C_TYPE_CATALOGUE is null)
                and CAT.C_TYPE_CATALOGUE <> '9')
           )
       and V_IMP.ACS_AUXILIARY_ACCOUNT_ID = parameter_0;
else -- if (ACS_FUNCTION.ExistDIVI = 0) = No divisions
  open aRefCursor for
    select CAT.C_TYPE_CATALOGUE
         , FIN.FIN_COLLECTIVE
         , CUR.FIN_LOCAL_CURRENCY
         , PCR.CURRENCY
         , PCR2.CURRENCY CURRENCY_LC
         , V_IMP.IMF_AMOUNT_LC_D
         , V_IMP.IMF_AMOUNT_LC_C
         , V_IMP.IMF_AMOUNT_FC_D
         , V_IMP.IMF_AMOUNT_FC_C
         , V_IMP.IMF_TRANSACTION_DATE
         , V_IMP.ACS_FINANCIAL_CURRENCY_ID
         , V_IMP.ACS_AUXILIARY_ACCOUNT_ID
         , V_IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
         , V_IMP.C_ETAT_JOURNAL
         , V_IMP.ACT_FINANCIAL_IMPUTATION_ID
         , PRD.C_TYPE_PERIOD
      from ACJ_CATALOGUE_DOCUMENT CAT
         , ACS_AUX_ACCOUNT_S_FIN_CURR AUX
         , ACS_FINANCIAL_ACCOUNT FIN
         , ACS_FINANCIAL_CURRENCY CUR
         , ACS_FINANCIAL_CURRENCY CUL
         , ACT_DOCUMENT DOC
         , PCS.PC_CURR PCR
         , PCS.PC_CURR PCR2
         , V_ACT_REC_IMP_REPORT V_IMP
         , ACS_PERIOD PRD
         , ACS_AUX_ACCOUNT_S_FIN_CURR AUX_S
     where V_IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID(+)
       and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID(+)
       and V_IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID(+)
       and V_IMP.ACS_FINANCIAL_CURRENCY_ID = CUR.ACS_FINANCIAL_CURRENCY_ID(+)
       and CUR.PC_CURR_ID = PCR.PC_CURR_ID(+)
       and V_IMP.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID(+)
       and V_IMP.ACS_FINANCIAL_ACCOUNT_ID = AUX.ACS_FINANCIAL_CURRENCY_ID(+)
       and V_IMP.ACS_ACS_FINANCIAL_CURRENCY_ID = CUL.ACS_FINANCIAL_CURRENCY_ID(+)
       and CUL.PC_CURR_ID = PCR2.PC_CURR_ID
       and FIN.FIN_COLLECTIVE = 1
       and V_IMP.ACS_PERIOD_ID = PRD.ACS_PERIOD_ID
       and AUX_S.ACS_AUXILIARY_ACCOUNT_ID = V_IMP.ACS_AUXILIARY_ACCOUNT_ID
       and AUX_S.ACS_FINANCIAL_CURRENCY_ID = V_IMP.ACS_FINANCIAL_CURRENCY_ID
       and V_IMP.IMF_TRANSACTION_DATE <= to_date(date_to, 'yyyyMMdd')
       and (    (    parameter_7 = '1'
                 and V_IMP.C_ETAT_JOURNAL = 'BRO')
            or (    parameter_8 = '1'
                and V_IMP.C_ETAT_JOURNAL = 'PROV')
            or (    parameter_9 = '1'
                and V_IMP.C_ETAT_JOURNAL = 'DEF')
           )
       and (    (    parameter_18 = '1'
                 and V_IMP.C_TYPE_CUMUL = 'EXT')
            or (    parameter_19 = '1'
                and V_IMP.C_TYPE_CUMUL = 'INT')
            or (    parameter_20 = '1'
                and V_IMP.C_TYPE_CUMUL = 'PRE')
            or (    parameter_21 = '1'
                and V_IMP.C_TYPE_CUMUL = 'ENG')
           )
       and (    (parameter_12 = '1')
            or (     (parameter_12 <> '1')
                and (CAT.C_TYPE_CATALOGUE is null) )
            or (     (parameter_12 <> '1')
                and not(CAT.C_TYPE_CATALOGUE is null)
                and CAT.C_TYPE_CATALOGUE <> '9')
           )
       and V_IMP.ACS_AUXILIARY_ACCOUNT_ID = parameter_0;
end if;
end RPT_ACR_FIN_IMP_CUMUL_REC;
