--------------------------------------------------------
--  DDL for Procedure RPT_ACT_FIN_IMP_CUMUL_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_FIN_IMP_CUMUL_SUB" (
  aRefCursor        in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, procparam_3     in     varchar2
, procparam_5     in     varchar2
, procparam_6     in     varchar2
, procparam_7     in     varchar2
, procparam_8     in     varchar2
, parameter_0     in     varchar2
, parameter_2     in     varchar2
, parameter_3     in     varchar2
, parameter_4     in     varchar2
, parameter_5     in     varchar2
, parameter_6     in     varchar2
, parameter_9     in     varchar2
, procuser_lanid   in     PCS.PC_LANG.LANID%type
, pc_user_id        in     PCS.PC_USER.PC_USER_ID%type
)
/**
* description used for report ACR_ACC_IMPUTATION_COMPARE

* @author jliu 18 nov 2008
* @lastupdate VHA 26 JUNE 2013
* @public
* @param procparam_3    Division_ID (List) NULL = All  or ACS_DIVISION_ACCOUNT_ID list
* @param procparam_5 Date to (yyyyMMdd)
* @param procparam_6 Journal status = BRO : 1=Yes / 0=No
* @param procparam_7 Journal status = PROV : 1=Yes / 0=No
* @param procparam_8 Journal status = DEF : 1=Yes / 0=No
* @param parameter_0    ACS_FINANCIAL_ACCOUNT_ID
* @param parameter_2   Compare code : '0'=all / '1'=compared / '2'=not compared
* @param parameter_3    C_TYPE_CUMUL = 'INT' :  0=No / 1=Yes
* @param parameter_4  C_TYPE_CUMUL = 'EXT' :  0=No / 1=Yes
* @param parameter_5   C_TYPE_CUMUL = 'PRE' :  0=No / 1=Yes
* @param parameter_6   C_TYPE_CUMUL = 'ENG' :  0=No / 1=Yes
* @param parameter_9    Only transaction without VAT
*/
is
  vpc_lang_id PCS.PC_LANG.PC_LANG_ID%type := null;
  vpc_user_id PCS.PC_USER.PC_USER_ID%type := null;

begin
  if ((procuser_lanid is not null) and (procuser_lanid is not null)) then
    PCS.PC_LIB_SESSION.setLanUserId(iLanId    => procuser_lanid
                                  , iPcUserId => pc_user_id
                                  , iPcCompId => null
                                  , iConliId  => null);
      vpc_lang_id  := PCS.PC_I_LIB_SESSION.getUserlangId;
      vpc_user_id  := PCS.PC_I_LIB_SESSION.getUserId;
  end if;

  if (ACS_FUNCTION.ExistDIVI = 1) then
  open aRefCursor for
    select CAT.ACJ_CATALOGUE_DOCUMENT_ID
         , ACC_S.ACS_FINANCIAL_CURRENCY_ID S_ACS_FINANCIAL_CURRENCY_ID
         , CUR.FIN_LOCAL_CURRENCY
         , JOU.C_TYPE_JOURNAL
         , PCR.CURRENCY
         , PCR2.CURRENCY CURRENCY_LC
         , V_IMP.ACS_FINANCIAL_ACCOUNT_ID
         , V_IMP.IMF_AMOUNT_LC_D
         , V_IMP.IMF_AMOUNT_LC_C
         , V_IMP.IMF_AMOUNT_FC_D
         , V_IMP.IMF_AMOUNT_FC_C
         , V_IMP.IMF_TRANSACTION_DATE
         , V_IMP.IMF_COMPARE_DATE
         , V_IMP.ACS_FINANCIAL_CURRENCY_ID V_ACS_FINANCIAL_CURRENCY_ID
         , V_IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
         , V_IMP.ACT_JOURNAL_ID
         , PRD.C_TYPE_PERIOD
      from ACJ_CATALOGUE_DOCUMENT CAT
         , ACJ_SUB_SET_CAT SUB
         , ACS_FIN_ACCOUNT_S_FIN_CURR ACC_S
         , ACS_FINANCIAL_CURRENCY CUR
         , ACS_FINANCIAL_CURRENCY CUL
         , ACT_DOCUMENT DOC
         , ACT_JOURNAL JOU
         , PCS.PC_CURR PCR
         , PCS.PC_CURR PCR2
         , V_ACT_ACC_IMP_REPORT V_IMP
         , ACS_PERIOD PRD
         , table(RPT_FUNCTIONS.TableAuthRptDivisions(vpc_user_id, procparam_3) ) AUT
     where V_IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID(+)
       and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SUB.ACJ_CATALOGUE_DOCUMENT_ID(+)
       and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID(+)
       and V_IMP.ACS_FINANCIAL_ACCOUNT_ID = ACC_S.ACS_FINANCIAL_ACCOUNT_ID(+)
       and V_IMP.ACS_FINANCIAL_CURRENCY_ID = ACC_S.ACS_FINANCIAL_CURRENCY_ID(+)
       and V_IMP.ACS_FINANCIAL_CURRENCY_ID = CUR.ACS_FINANCIAL_CURRENCY_ID
       and CUR.PC_CURR_ID = PCR.PC_CURR_ID(+)
       and V_IMP.ACS_ACS_FINANCIAL_CURRENCY_ID = CUL.ACS_FINANCIAL_CURRENCY_ID
       and CUL.PC_CURR_ID = PCR2.PC_CURR_ID
       and V_IMP.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID(+)
       and V_IMP.ACS_PERIOD_ID = PRD.ACS_PERIOD_ID
       and V_IMP.IMF_TRANSACTION_DATE <= to_date(procparam_5, 'yyyyMMdd')
       and decode(SUB.C_SUB_SET, null, 1, 'ACC', 1, 0) = 1
       and decode(parameter_9, '1', decode(V_IMP.IMF_TYPE, 'VAT', 0, decode(V_IMP.ACS_TAX_CODE_ID, null, 1, 0) ), decode(V_IMP.IMF_TYPE, null, 0, 1) ) = 1
       and (    (    procparam_6 = '1'
                 and V_IMP.C_ETAT_JOURNAL = 'BRO')
            or (    procparam_7 = '1'
                and V_IMP.C_ETAT_JOURNAL = 'PROV')
            or (    procparam_8 = '1'
                and V_IMP.C_ETAT_JOURNAL = 'DEF')
           )
       and decode(parameter_2, '0', 1, '1', decode(V_IMP.IMF_COMPARE_DATE, null, 0, 1), '2', decode(V_IMP.IMF_COMPARE_DATE, null, 1, 0), 0) = 1
       and decode(V_IMP.C_TYPE_CUMUL
                , 'INT', decode(parameter_3, '1', 1, 0)
                , 'EXT', decode(parameter_4, '1', 1, 0)
                , 'PRE', decode(parameter_5, '1', 1, 0)
                , 'ENG', decode(parameter_6, '1', 1, 0)
                , 0
                 ) = 1
       and decode(V_IMP.ACT_JOURNAL_ID, 'NULL', 0, decode(JOU.C_TYPE_JOURNAL, 'OPB', 0, 1) ) = 1
       and V_IMP.ACS_FINANCIAL_ACCOUNT_ID = to_number(parameter_0)
       and V_IMP.ACS_DIVISION_ACCOUNT_ID is not null
       and AUT.column_value = V_IMP.ACS_DIVISION_ACCOUNT_ID;
else -- if (ACS_FUNCTION.ExistDIVI = 0) = No divisions
  open aRefCursor for
    select CAT.ACJ_CATALOGUE_DOCUMENT_ID
         , ACC_S.ACS_FINANCIAL_CURRENCY_ID S_ACS_FINANCIAL_CURRENCY_ID
         , CUR.FIN_LOCAL_CURRENCY
         , JOU.C_TYPE_JOURNAL
         , PCR.CURRENCY
         , PCR2.CURRENCY CURRENCY_LC
         , V_IMP.ACS_FINANCIAL_ACCOUNT_ID
         , V_IMP.IMF_AMOUNT_LC_D
         , V_IMP.IMF_AMOUNT_LC_C
         , V_IMP.IMF_AMOUNT_FC_D
         , V_IMP.IMF_AMOUNT_FC_C
         , V_IMP.IMF_TRANSACTION_DATE
         , V_IMP.IMF_COMPARE_DATE
         , V_IMP.ACS_FINANCIAL_CURRENCY_ID V_ACS_FINANCIAL_CURRENCY_ID
         , V_IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
         , V_IMP.ACT_JOURNAL_ID
         , PRD.C_TYPE_PERIOD
      from ACJ_CATALOGUE_DOCUMENT CAT
         , ACJ_SUB_SET_CAT SUB
         , ACS_FIN_ACCOUNT_S_FIN_CURR ACC_S
         , ACS_FINANCIAL_CURRENCY CUR
         , ACS_FINANCIAL_CURRENCY CUL
         , ACT_DOCUMENT DOC
         , ACT_JOURNAL JOU
         , PCS.PC_CURR PCR
         , PCS.PC_CURR PCR2
         , V_ACT_ACC_IMP_REPORT V_IMP
         , ACS_PERIOD PRD
     where V_IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID(+)
       and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SUB.ACJ_CATALOGUE_DOCUMENT_ID(+)
       and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID(+)
       and V_IMP.ACS_FINANCIAL_ACCOUNT_ID = ACC_S.ACS_FINANCIAL_ACCOUNT_ID(+)
       and V_IMP.ACS_FINANCIAL_CURRENCY_ID = ACC_S.ACS_FINANCIAL_CURRENCY_ID(+)
       and V_IMP.ACS_FINANCIAL_CURRENCY_ID = CUR.ACS_FINANCIAL_CURRENCY_ID
       and CUR.PC_CURR_ID = PCR.PC_CURR_ID(+)
       and V_IMP.ACS_ACS_FINANCIAL_CURRENCY_ID = CUL.ACS_FINANCIAL_CURRENCY_ID
       and CUL.PC_CURR_ID = PCR2.PC_CURR_ID
       and V_IMP.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID(+)
       and V_IMP.ACS_PERIOD_ID = PRD.ACS_PERIOD_ID
       and V_IMP.IMF_TRANSACTION_DATE <= to_date(procparam_5, 'yyyyMMdd')
       and decode(SUB.C_SUB_SET, null, 1, 'ACC', 1, 0) = 1
       and decode(parameter_9, '1', decode(V_IMP.IMF_TYPE, 'VAT', 0, decode(V_IMP.ACS_TAX_CODE_ID, null, 1, 0) ), decode(V_IMP.IMF_TYPE, null, 0, 1) ) = 1
       and (    (    procparam_6 = '1'
                 and V_IMP.C_ETAT_JOURNAL = 'BRO')
            or (    procparam_7 = '1'
                and V_IMP.C_ETAT_JOURNAL = 'PROV')
            or (    procparam_8 = '1'
                and V_IMP.C_ETAT_JOURNAL = 'DEF')
           )
       and decode(parameter_2, '0', 1, '1', decode(V_IMP.IMF_COMPARE_DATE, null, 0, 1), '2', decode(V_IMP.IMF_COMPARE_DATE, null, 1, 0), 0) = 1
       and decode(V_IMP.C_TYPE_CUMUL
                , 'INT', decode(parameter_3, '1', 1, 0)
                , 'EXT', decode(parameter_4, '1', 1, 0)
                , 'PRE', decode(parameter_5, '1', 1, 0)
                , 'ENG', decode(parameter_6, '1', 1, 0)
                , 0
                 ) = 1
       and decode(V_IMP.ACT_JOURNAL_ID, 'NULL', 0, decode(JOU.C_TYPE_JOURNAL, 'OPB', 0, 1) ) = 1
       and V_IMP.ACS_FINANCIAL_ACCOUNT_ID = to_number(parameter_0);
end if;
end RPT_ACT_FIN_IMP_CUMUL_SUB;
