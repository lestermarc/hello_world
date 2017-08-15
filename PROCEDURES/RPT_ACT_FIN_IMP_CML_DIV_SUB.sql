--------------------------------------------------------
--  DDL for Procedure RPT_ACT_FIN_IMP_CML_DIV_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_FIN_IMP_CML_DIV_SUB" (
  aRefCursor  in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, PROCPARAM_5 in     varchar2
, PROCPARAM_6 in     varchar2
, PROCPARAM_7 in     varchar2
, PROCPARAM_8 in     varchar2
, PARAMETER_0 in     varchar2
, PARAMETER_1 in     varchar2
, PARAMETER_3 in     varchar2
, PARAMETER_4 in     varchar2
, PARAMETER_5 in     varchar2
, PARAMETER_6 in     varchar2
, PARAMETER_9 in     varchar2
)
/**
* description used for report ACR_ACC_IMPUTATION_COMPARE

* @author jliu 18 nov 2008
* @lastupdate VHA 15 August 2012
* @public
* @param PROCPARAM_5    Date to (yyyyMMdd)
* @param PROCPARAM_6    Journal status = BRO : 1=Yes / 0=No
* @param PROCPARAM_7    Journal status = PROV : 1=Yes / 0=No
* @param PROCPARAM_8    Journal status = DEF : 1=Yes / 0=No
* @param PARAMETER_0    ACS_FINANCIAL_ACCOUNT_ID
* @param PARAMETER_1    ACS_DIVISION_ACCOUNT_ID
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
SELECT
CAT.ACJ_CATALOGUE_DOCUMENT_ID,
ACC_S.ACS_FINANCIAL_CURRENCY_ID S_ACS_FINANCIAL_CURRENCY_ID,
CUR.FIN_LOCAL_CURRENCY,
JOU.C_TYPE_JOURNAL,
PCR.CURRENCY,
PCR2.CURRENCY CURRENCY_LC,
V_IMP.ACS_FINANCIAL_ACCOUNT_ID,
V_IMP.IMF_AMOUNT_LC_D,
V_IMP.IMF_AMOUNT_LC_C,
V_IMP.IMF_AMOUNT_FC_D,
V_IMP.IMF_AMOUNT_FC_C,
V_IMP.IMF_TRANSACTION_DATE,
V_IMP.IMF_COMPARE_DATE,
V_IMP.ACS_FINANCIAL_CURRENCY_ID V_ACS_FINANCIAL_CURRENCY_ID,
V_IMP.ACS_ACS_FINANCIAL_CURRENCY_ID,
V_IMP.ACT_JOURNAL_ID,
V_IMP.ACS_DIVISION_ACCOUNT_ID
FROM
    ACJ_CATALOGUE_DOCUMENT CAT,
    ACJ_SUB_SET_CAT SUB,
    ACS_FIN_ACCOUNT_S_FIN_CURR ACC_S,
    ACS_FINANCIAL_CURRENCY CUR,
    ACS_FINANCIAL_CURRENCY CUL,
    ACT_DOCUMENT DOC,
    ACT_JOURNAL JOU,
    PCS.PC_CURR PCR,
    PCS.PC_CURR PCR2,
    V_ACT_ACC_IMP_REPORT V_IMP
WHERE
V_IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID(+)
AND DOC.ACJ_CATALOGUE_DOCUMENT_ID = SUB.ACJ_CATALOGUE_DOCUMENT_ID(+)
AND DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID(+)
AND V_IMP.ACS_FINANCIAL_ACCOUNT_ID = ACC_S.ACS_FINANCIAL_ACCOUNT_ID(+)
AND V_IMP.ACS_FINANCIAL_CURRENCY_ID = ACC_S.ACS_FINANCIAL_CURRENCY_ID(+)
AND V_IMP.ACS_FINANCIAL_CURRENCY_ID = CUR.ACS_FINANCIAL_CURRENCY_ID
AND CUR.PC_CURR_ID = PCR.PC_CURR_ID(+)
AND V_IMP.ACS_ACS_FINANCIAL_CURRENCY_ID = CUL.ACS_FINANCIAL_CURRENCY_ID
AND CUL.PC_CURR_ID = PCR2.PC_CURR_ID
AND V_IMP.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID(+)
AND V_IMP.IMF_TRANSACTION_DATE <= TO_DATE(PROCPARAM_5,'yyyyMMdd')
AND DECODE(SUB.C_SUB_SET,NULL,1,'ACC',1,0)=1
AND DECODE(PARAMETER_9,'1',
          DECODE(V_IMP.IMF_TYPE,'VAT',0,DECODE(V_IMP.ACS_TAX_CODE_ID,NULL,1,0)),
          DECODE(V_IMP.IMF_TYPE,NULL,0,1))=1
AND ((PROCPARAM_6='1' AND V_IMP.C_ETAT_JOURNAL = 'BRO')
    OR (PROCPARAM_7='1' AND V_IMP.C_ETAT_JOURNAL = 'PROV')
    OR (PROCPARAM_8='1' AND V_IMP.C_ETAT_JOURNAL = 'DEF'))
AND DECODE(V_IMP.C_TYPE_CUMUL,'INT',DECODE(PARAMETER_3,'1',1,0),'EXT',DECODE(PARAMETER_4,'1',1,0),'PRE',DECODE(PARAMETER_5,'1',1,0),'ENG',DECODE(PARAMETER_6,'1',1,0),0)=1
AND DECODE(V_IMP.ACT_JOURNAL_ID,'NULL',0,DECODE(JOU.C_TYPE_JOURNAL,'OPB',0,1))=1
AND V_IMP.ACS_FINANCIAL_ACCOUNT_ID = TO_NUMBER(PARAMETER_0)
AND V_IMP.ACS_DIVISION_ACCOUNT_ID = TO_NUMBER(PARAMETER_1)
;
end RPT_ACT_FIN_IMP_CML_DIV_SUB;
