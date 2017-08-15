--------------------------------------------------------
--  DDL for Procedure RPT_ACT_AGED_BALANCE_CUST_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_AGED_BALANCE_CUST_SUB" (
  aRefCursor  in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, PARAMETER_1   in     varchar2
, PARAMETER_2   in     varchar2
, PARAMETER_3   in     varchar2
, PARAMETER_4   in     varchar2
, PARAMETER_5   in     varchar2
, PARAMETER_6   in     varchar2
, PARAMETER_11  in     varchar2
, PROCPARAM_0   in     varchar2
, PROCPARAM_1   in     varchar2
, PROCPARAM_2   in     varchar2
, PROCPARAM_3   in     varchar2
, PROCPARAM_4   in     varchar2
, PROCPARAM_5   in     varchar2
, PROCPARAM_6   in     number
, PROCPARAM_7   in     number
, PROCUSER_LANID in  pcs.pc_lang.lanid%type
)
/**
* description used for report ACT_AGED_BALANCE_CUST (Ech??━|anciers fournisseurs)

* @author SDO 2003
* @lastupdate 12 Feb 2009
* @public
* @param PARAMETER_1    Only expired : 0=No / 1=Yes
* @param PARAMETER_2    Date expired : YYYYMMDD
* @param PARAMETER_3    C_TYPE_CUMUL = INT : 0=No / 1=Yes
* @param PARAMETER_4    C_TYPE_CUMUL = EXT : 0=No / 1=Yes
* @param PARAMETER_5    C_TYPE_CUMUL = PRE : 0=No / 1=Yes
* @param PARAMETER_6    C_TYPE_CUMUL = ENG : 0=No / 1=Yes
* @param PARAMETER_11   Only summary : 0=No / 1=Yes
* @param PROCPARAM_0    Compte du ...        ACC_NUMBER (AUXILIARY_ACCOUNT)
* @param PROCPARAM_1    Compte au ...        ACC_NUMBER (AUXILIARY_ACCOUNT)
* @param PROCPARAM_2    DATE
* @param PROCPARAM_3    SUBSET ID      Date pour le calcul des escomptes et des r??━|??━|valuations
* @param PROCPARAM_4    Division_ID (List)   '' = All sinon liste des ID
* @param PROCPARAM_5    Collectiv_ID (List)  '' = All sinon liste des ID
* @param PROCPARAM_6    Type de cours        1 : Cours du jour (par d??━|faut)
                                             2 : Cours d'??━|valuation
                                             3 : Cours d'inventaire
                                             4 : Cours de bouclement
                                             5 : Cours de facturation
* @param PROCPARAM_7    Currency_ID List)   '' = All sinon liste des ID   (ACS_FINANCIAL_CURRENCY_ID)
*/
is




begin




  open aRefCursor for
  SELECT
  PAR_DOCUMENT,
  ACS_ACS_FINANCIAL_CURRENCY_ID,
  CURRENCY_MB,
  ACS_FINANCIAL_CURRENCY_ID,
  CURRENCY_ME,
  DOC_NUMBER,
  C_TYPE_CATALOGUE,
  C_TYPE_CUMUL,
  ACT_EXPIRY_ID,
  ACT_DOCUMENT_ID,
  ACT_PART_IMPUTATION_ID,
  C_STATUS_EXPIRY,
  EXP_ADAPTED,
  EXP_CALCULATED,
  DAYS,
  EXP_AMOUNT_LC,
  EXP_AMOUNT_FC,
  DISCOUNT_LC,
  DISCOUNT_FC,
  DET_PAIED_LC,
  DET_PAIED_FC,
  SOLDE_EXP_LC,
  SOLDE_EXP_FC,
  SOLDE_REEVAL_LC,
  EXP_SLICE,
  ACS_FIN_ACC_S_PAYMENT_ID,
  LAST_CLAIMS_LEVEL,
  LAST_CLAIMS_DATE,
  PCO_DESCR_EXP,
  ACS_PERIOD_ID,
  IMF_TRANSACTION_DATE,
  IMF_VALUE_DATE,
  IMF_DESCRIPTION,
  ACS_FINANCIAL_ACCOUNT_ID,
  ACC_NUMBER_FIN,
  ACCOUNT_FIN_DESCR,
  JOU_NUMBER,
  C_ETAT_JOURNAL,
  IMF_ACS_DIVISION_ACCOUNT_ID,
  ACC_NUMBER_DIV,
  ACCOUNT_DIV_DESCR,
  PAC_CUSTOM_PARTNER_ID,
  ACS_AUXILIARY_ACCOUNT_ID,
  C_PARTNER_CATEGORY,
  PCO_DESCR_CUS,
  ACC_NUMBER_AUX,
  ACCOUNT_AUX_DESCR,
  ACCOUNT_AUX_LARGE_DESCR,
  ACS_SUB_SET_ID,
  SUB_SET_DESCR,
  C_TYPE_ACCOUNT,
  PER_NAME,
  PER_FORENAME,
  PER_SHORT_NAME,
  PER_ACTIVITY,
  PER_KEY1,
  ADD_FORMAT,
  ACS_PAYMENT_METHOD_DESCR_CUST,
  ACS_PAYMENT_METHOD_DESCR_EXP
  FROM
  ACT_AGED_BALANCE_CUST_TEMP;


end RPT_ACT_AGED_BALANCE_CUST_SUB;
