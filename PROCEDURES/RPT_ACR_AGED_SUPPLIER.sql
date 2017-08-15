--------------------------------------------------------
--  DDL for Procedure RPT_ACR_AGED_SUPPLIER
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACR_AGED_SUPPLIER" (
  aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, procparam_0    in     varchar2
, procparam_1    in     varchar2
, procparam_2    in     varchar2
, procparam_3    in     varchar2
, procparam_4    in     varchar2
, procparam_5    in     varchar2
, procparam_6    in     number
, procparam_7    in     varchar2
, procuser_lanid in     PCS.PC_LANG.LANID%type
, pc_user_id     in     PCS.PC_USER.PC_USER_ID%type
)
/**
* description used for report ACR_AGED_SUPPLIER (Ech：|anciers fournisseurs)

* @author SDO 2003
* @lastUpdate VHA 26 JUNE 2013
* @public
* @param procparam_0    Acs_sub_set_ID       ACS_SUB_SET_ID
* @param procparam_1    Compte du ...        ACC_NUMBER (AUXILIARY_ACCOUNT)
* @param procparam_2    Compte au ...        ACC_NUMBER (AUXILIARY_ACCOUNT)
* @param procparam_3    Date r：|f：|rence       Date pour le calcul des escomptes et des r：|：|valuations
* @param procparam_4    Division_ID (List) NULL = All  or ACS_DIVISION_ACCOUNT_ID list
* @param procparam_5    Collectiv_ID (List)  '' = All sinon liste des ID
* @param procparam_6    Type de cours        1 : Cours du jour (par d：|faut)
                                            2 : Cours d'：|valuation
                                            3 : Cours d'inventaire
                                            4 : Cours de bouclement
                                            5 : Cours de facturation
* @param procparam_7    Currency_ID List)   '' = All sinon liste des ID   (ACS_FINANCIAL_CURRENCY_ID)
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

  if (ACS_FUNCTION.ExistDIVI = 1) then
  if (procparam_3 is null) then
    open aRefCursor for
      select PAR.PAR_DOCUMENT
           , PAR.PAR_BLOCKED_DOCUMENT
           , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
           , (select CUB.CURRENCY
                from PCS.PC_CURR CUB
                   , ACS_FINANCIAL_CURRENCY CFB
               where CFB.ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                 and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_MB
           , PAR.ACS_FINANCIAL_CURRENCY_ID
           , (select CUB.CURRENCY
                from PCS.PC_CURR CUB
                   , ACS_FINANCIAL_CURRENCY CFB
               where CFB.ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_FINANCIAL_CURRENCY_ID
                 and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_ME
           , DOC.DOC_NUMBER
           , CAT.C_TYPE_CATALOGUE
           , (select sub.c_type_cumul
                from acj_sub_set_cat sub
               where doc.acj_catalogue_document_id = sub.acj_catalogue_document_id
                 and sub.c_sub_set = 'PAY') C_TYPE_CUMUL
           , exp.ACT_EXPIRY_ID
           , exp.ACT_DOCUMENT_ID
           , exp.ACT_PART_IMPUTATION_ID
           , exp.C_STATUS_EXPIRY
           , exp.EXP_ADAPTED
           , to_char(exp.EXP_ADAPTED, 'YYYY-IW') WEEK_YEAR
           , to_char(exp.EXP_ADAPTED, 'YYYY-MM') MONTH_YEAR
           , to_char(exp.EXP_ADAPTED, 'YYYY') year
           , exp.EXP_CALCULATED
           , exp.EXP_AMOUNT_LC
           , exp.EXP_AMOUNT_FC
           , ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, sysdate, 1) DISCOUNT_LC
           , ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, sysdate, 0) DISCOUNT_FC
           , ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 1) DET_PAIED_LC
           , ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 0) DET_PAIED_FC
           , exp.EXP_AMOUNT_LC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 1) SOLDE_EXP_LC
           , exp.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 0) SOLDE_EXP_FC
           , ACT_CURRENCY_EVALUATION.GetConvertAmount(exp.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 0)
                                                    , PAR.ACS_FINANCIAL_CURRENCY_ID
                                                    , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                    , sysdate
                                                    , procparam_6
                                                     ) SOLDE_REEVAL_LC
           , exp.EXP_SLICE
           , ACT_FUNCTIONS.LastClaimsNumber(exp.ACT_EXPIRY_ID) LAST_CLAIMS_LEVEL
           , ACT_FUNCTIONS.LastClaimsDate(exp.ACT_EXPIRY_ID) LAST_CLAIMS_DATE
           , exp.ACS_FIN_ACC_S_PAYMENT_ID
           , PMM.ACS_PAYMENT_METHOD_ID
           , (select PME.C_METHOD_CATEGORY
                from ACS_PAYMENT_METHOD PME
               where PME.ACS_PAYMENT_METHOD_ID = PMM.ACS_PAYMENT_METHOD_ID) C_METHOD_CATEGORY
           , (select DE4.DES_DESCRIPTION_SUMMARY
                from ACS_DESCRIPTION DE4
               where DE4.ACS_PAYMENT_METHOD_ID = PMM.ACS_PAYMENT_METHOD_ID
                 and DE4.PC_LANG_ID = vpc_lang_id) PAYMENT_METHOD_DESCR
           , IMP.ACS_PERIOD_ID
           , IMP.IMF_TRANSACTION_DATE
           , IMP.IMF_VALUE_DATE
           , IMP.IMF_DESCRIPTION
           , IMP.ACS_FINANCIAL_ACCOUNT_ID
           , (select ACF.ACC_NUMBER
                from ACS_ACCOUNT ACF
               where ACF.ACS_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID) ACC_NUMBER_FIN
           , (select DE1.DES_DESCRIPTION_SUMMARY
                from ACS_DESCRIPTION DE1
               where DE1.ACS_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID
                 and DE1.PC_LANG_ID = vpc_lang_id) ACCOUNT_FIN_DESCR
           , JOU.JOU_NUMBER
           , EJO.C_ETAT_JOURNAL
           , IMP.IMF_ACS_DIVISION_ACCOUNT_ID
           , SUP.PAC_SUPPLIER_PARTNER_ID
           , SUP.ACS_AUXILIARY_ACCOUNT_ID
           , SUP.C_PARTNER_CATEGORY
           , ACC.ACC_NUMBER ACC_NUMBER_AUX
           , (select DE2.DES_DESCRIPTION_SUMMARY
                from ACS_DESCRIPTION DE2
               where DE2.ACS_ACCOUNT_ID = SUP.ACS_AUXILIARY_ACCOUNT_ID
                 and DE2.PC_LANG_ID = vpc_lang_id) ACCOUNT_AUX_DESCR
           , ACC.ACS_SUB_SET_ID
           , (select DE3.DES_DESCRIPTION_SUMMARY
                from ACS_DESCRIPTION DE3
               where DE3.ACS_SUB_SET_ID = ACC.ACS_SUB_SET_ID
                 and DE3.PC_LANG_ID = vpc_lang_id) SUB_SET_DESCR
           , AUX.C_TYPE_ACCOUNT
           , PER.PER_NAME
           , PER.PER_FORENAME
           , PER.PER_SHORT_NAME
           , PER.PER_ACTIVITY
           , PER.PER_KEY1
           , (select ADR.ADD_FORMAT
                from PAC_ADDRESS ADR
               where ADR.PAC_PERSON_ID = SUP.PAC_SUPPLIER_PARTNER_ID
                 and ADR.ADD_PRINCIPAL = '1') ADD_FORMAT
        from PAC_PERSON PER
           , ACS_AUXILIARY_ACCOUNT AUX
           , PAC_SUPPLIER_PARTNER SUP
           , ACS_FINANCIAL_ACCOUNT FIN
           , ACT_FINANCIAL_IMPUTATION IMP
           , ACT_ETAT_JOURNAL EJO
           , ACT_JOURNAL JOU
           , ACS_FIN_ACC_S_PAYMENT PMM
           , ACT_EXPIRY exp
           , ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_DOCUMENT DOC
           , ACT_PART_IMPUTATION PAR
           , ACS_ACCOUNT ACC
           , table(RPT_FUNCTIONS.TableAuthRptDivisions(vpc_user_id, procparam_4) ) AUT
      where  PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
         and CAT.C_TYPE_CATALOGUE <> '8'
         and   -- Transaction de relance
             PAR.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
         and EXP_CALC_NET + 0 = 1
         and ACT_EXPIRY_MANAGEMENT.IsExpiryOpenedAt(exp.ACT_EXPIRY_ID, sysdate) = 1
         and exp.ACS_FIN_ACC_S_PAYMENT_ID = PMM.ACS_FIN_ACC_S_PAYMENT_ID(+)
         and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
         and DOC.ACT_JOURNAL_ID = EJO.ACT_JOURNAL_ID
         and EJO.C_SUB_SET = 'PAY'
         and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
         and IMP.ACT_DET_PAYMENT_ID is null
         and IMP.ACS_AUXILIARY_ACCOUNT_ID is not null
         and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
         and exp.C_STATUS_EXPIRY = 0
         and FIN.FIN_COLLECTIVE = 1
         and ACC.ACC_NUMBER >= procparam_1
         and ACC.ACC_NUMBER <= procparam_2
         and (   ACC.ACS_SUB_SET_ID = procparam_0
              or procparam_0 is null)
         and IMP.IMF_ACS_DIVISION_ACCOUNT_ID is not null
         and AUT.column_value = IMP.IMF_ACS_DIVISION_ACCOUNT_ID
         and (   instr(',' || procparam_5 || ',', to_char(',' || FIN.ACS_FINANCIAL_ACCOUNT_ID || ',') ) > 0
              or procparam_5 is null)
         and (   instr(',' || procparam_7 || ',', to_char(',' || PAR.ACS_FINANCIAL_CURRENCY_ID || ',') ) > 0
              or procparam_7 is null)
         and PAR.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID
         and SUP.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
         and SUP.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID
         and SUP.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID;
  else
    open aRefCursor for
      select PAR.PAR_DOCUMENT
           , PAR.PAR_BLOCKED_DOCUMENT
           , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
           , (select CUB.CURRENCY
                from PCS.PC_CURR CUB
                   , ACS_FINANCIAL_CURRENCY CFB
               where CFB.ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                 and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_MB
           , PAR.ACS_FINANCIAL_CURRENCY_ID
           , (select CUB.CURRENCY
                from PCS.PC_CURR CUB
                   , ACS_FINANCIAL_CURRENCY CFB
               where CFB.ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_FINANCIAL_CURRENCY_ID
                 and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_ME
           , DOC.DOC_NUMBER
           , CAT.C_TYPE_CATALOGUE
           , (select sub.c_type_cumul
                from acj_sub_set_cat sub
               where doc.acj_catalogue_document_id = sub.acj_catalogue_document_id
                 and sub.c_sub_set = 'PAY') C_TYPE_CUMUL
           , exp.ACT_EXPIRY_ID
           , exp.ACT_DOCUMENT_ID
           , exp.ACT_PART_IMPUTATION_ID
           , exp.C_STATUS_EXPIRY
           , exp.EXP_ADAPTED
           , to_char(exp.EXP_ADAPTED, 'YYYY-IW') WEEK_YEAR
           , to_char(exp.EXP_ADAPTED, 'YYYY-MM') MONTH_YEAR
           , to_char(exp.EXP_ADAPTED, 'YYYY') year
           , exp.EXP_CALCULATED
           , exp.EXP_AMOUNT_LC
           , exp.EXP_AMOUNT_FC
           , ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, to_date(procparam_3, 'YYYYMMDD'), 1) DISCOUNT_LC
           , ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, to_date(procparam_3, 'YYYYMMDD'), 0) DISCOUNT_FC
           , ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(procparam_3, 'YYYYMMDD'), 1) DET_PAIED_LC
           , ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(procparam_3, 'YYYYMMDD'), 0) DET_PAIED_FC
           , exp.EXP_AMOUNT_LC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(procparam_3, 'YYYYMMDD'), 1) SOLDE_EXP_LC
           , exp.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(procparam_3, 'YYYYMMDD'), 0) SOLDE_EXP_FC
           , ACT_CURRENCY_EVALUATION.GetConvertAmount(exp.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(procparam_3, 'YYYYMMDD'), 0)
                                                    , PAR.ACS_FINANCIAL_CURRENCY_ID
                                                    , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                    , to_date(procparam_3, 'YYYYMMDD')
                                                    , procparam_6
                                                     ) SOLDE_REEVAL_LC
           , exp.EXP_SLICE
           , ACT_FUNCTIONS.LastClaimsNumber(exp.ACT_EXPIRY_ID) LAST_CLAIMS_LEVEL
           , ACT_FUNCTIONS.LastClaimsDate(exp.ACT_EXPIRY_ID) LAST_CLAIMS_DATE
           , exp.ACS_FIN_ACC_S_PAYMENT_ID
           , PMM.ACS_PAYMENT_METHOD_ID
           , (select PME.C_METHOD_CATEGORY
                from ACS_PAYMENT_METHOD PME
               where PME.ACS_PAYMENT_METHOD_ID = PMM.ACS_PAYMENT_METHOD_ID) C_METHOD_CATEGORY
           , (select DE4.DES_DESCRIPTION_SUMMARY
                from ACS_DESCRIPTION DE4
               where DE4.ACS_PAYMENT_METHOD_ID = PMM.ACS_PAYMENT_METHOD_ID
                 and DE4.PC_LANG_ID = vpc_lang_id) PAYMENT_METHOD_DESCR
           , IMP.ACS_PERIOD_ID
           , IMP.IMF_TRANSACTION_DATE
           , IMP.IMF_VALUE_DATE
           , IMP.IMF_DESCRIPTION
           , IMP.ACS_FINANCIAL_ACCOUNT_ID
           , (select ACF.ACC_NUMBER
                from ACS_ACCOUNT ACF
               where ACF.ACS_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID) ACC_NUMBER_FIN
           , (select DE1.DES_DESCRIPTION_SUMMARY
                from ACS_DESCRIPTION DE1
               where DE1.ACS_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID
                 and DE1.PC_LANG_ID = vpc_lang_id) ACCOUNT_FIN_DESCR
           , JOU.JOU_NUMBER
           , EJO.C_ETAT_JOURNAL
           , IMP.IMF_ACS_DIVISION_ACCOUNT_ID
           , SUP.PAC_SUPPLIER_PARTNER_ID
           , SUP.ACS_AUXILIARY_ACCOUNT_ID
           , SUP.C_PARTNER_CATEGORY
           , ACC.ACC_NUMBER ACC_NUMBER_AUX
           , (select DE2.DES_DESCRIPTION_SUMMARY
                from ACS_DESCRIPTION DE2
               where DE2.ACS_ACCOUNT_ID = SUP.ACS_AUXILIARY_ACCOUNT_ID
                 and DE2.PC_LANG_ID = vpc_lang_id) ACCOUNT_AUX_DESCR
           , ACC.ACS_SUB_SET_ID
           , (select DE3.DES_DESCRIPTION_SUMMARY
                from ACS_DESCRIPTION DE3
               where DE3.ACS_SUB_SET_ID = ACC.ACS_SUB_SET_ID
                 and DE3.PC_LANG_ID = vpc_lang_id) SUB_SET_DESCR
           , AUX.C_TYPE_ACCOUNT
           , PER.PER_NAME
           , PER.PER_FORENAME
           , PER.PER_SHORT_NAME
           , PER.PER_ACTIVITY
           , PER.PER_KEY1
           , (select ADR.ADD_FORMAT
                from PAC_ADDRESS ADR
               where ADR.PAC_PERSON_ID = SUP.PAC_SUPPLIER_PARTNER_ID
                 and ADR.ADD_PRINCIPAL = '1') ADD_FORMAT
        from PAC_PERSON PER
           , ACS_AUXILIARY_ACCOUNT AUX
           , PAC_SUPPLIER_PARTNER SUP
           , ACS_FINANCIAL_ACCOUNT FIN
           , ACT_FINANCIAL_IMPUTATION IMP
           , ACT_ETAT_JOURNAL EJO
           , ACT_JOURNAL JOU
           , ACS_FIN_ACC_S_PAYMENT PMM
           , ACT_EXPIRY exp
           , ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_DOCUMENT DOC
           , ACT_PART_IMPUTATION PAR
           , ACS_ACCOUNT ACC
           , table(RPT_FUNCTIONS.TableAuthRptDivisions(vpc_user_id, procparam_4) ) AUT
      where  PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
         and CAT.C_TYPE_CATALOGUE <> '8'
         and   -- Transaction de relance
             PAR.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
         and EXP_CALC_NET + 0 = 1
         and ACT_EXPIRY_MANAGEMENT.IsExpiryOpenedAt(exp.ACT_EXPIRY_ID, to_date(procparam_3, 'YYYYMMDD') ) = 1
         and exp.ACS_FIN_ACC_S_PAYMENT_ID = PMM.ACS_FIN_ACC_S_PAYMENT_ID(+)
         and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
         and DOC.ACT_JOURNAL_ID = EJO.ACT_JOURNAL_ID
         and EJO.C_SUB_SET = 'PAY'
         and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
         and IMP.ACT_DET_PAYMENT_ID is null
         and IMP.ACS_AUXILIARY_ACCOUNT_ID is not null
         and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
         and (   IMP.IMF_TRANSACTION_DATE <= to_date(procparam_3, 'YYYYMMDD')
              or procparam_3 is null)
         and FIN.FIN_COLLECTIVE = 1
         and ACC.ACC_NUMBER >= procparam_1
         and ACC.ACC_NUMBER <= procparam_2
         and (   ACC.ACS_SUB_SET_ID = procparam_0
              or procparam_0 is null)
         and IMP.IMF_ACS_DIVISION_ACCOUNT_ID is not null
         and AUT.column_value = IMP.IMF_ACS_DIVISION_ACCOUNT_ID
         and (   instr(',' || procparam_5 || ',', to_char(',' || FIN.ACS_FINANCIAL_ACCOUNT_ID || ',') ) > 0
              or procparam_5 is null)
         and (   instr(',' || procparam_7 || ',', to_char(',' || PAR.ACS_FINANCIAL_CURRENCY_ID || ',') ) > 0
              or procparam_7 is null)
         and PAR.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID
         and SUP.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
         and SUP.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID
         and SUP.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID;
  end if;
else -- if (ACS_FUNCTION.ExistDIVI = 0) = No divisions
  if (procparam_3 is null) then
    open aRefCursor for
      select PAR.PAR_DOCUMENT
           , PAR.PAR_BLOCKED_DOCUMENT
           , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
           , (select CUB.CURRENCY
                from PCS.PC_CURR CUB
                   , ACS_FINANCIAL_CURRENCY CFB
               where CFB.ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                 and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_MB
           , PAR.ACS_FINANCIAL_CURRENCY_ID
           , (select CUB.CURRENCY
                from PCS.PC_CURR CUB
                   , ACS_FINANCIAL_CURRENCY CFB
               where CFB.ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_FINANCIAL_CURRENCY_ID
                 and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_ME
           , DOC.DOC_NUMBER
           , CAT.C_TYPE_CATALOGUE
           , (select sub.c_type_cumul
                from acj_sub_set_cat sub
               where doc.acj_catalogue_document_id = sub.acj_catalogue_document_id
                 and sub.c_sub_set = 'PAY') C_TYPE_CUMUL
           , exp.ACT_EXPIRY_ID
           , exp.ACT_DOCUMENT_ID
           , exp.ACT_PART_IMPUTATION_ID
           , exp.C_STATUS_EXPIRY
           , exp.EXP_ADAPTED
           , to_char(exp.EXP_ADAPTED, 'YYYY-IW') WEEK_YEAR
           , to_char(exp.EXP_ADAPTED, 'YYYY-MM') MONTH_YEAR
           , to_char(exp.EXP_ADAPTED, 'YYYY') year
           , exp.EXP_CALCULATED
           , exp.EXP_AMOUNT_LC
           , exp.EXP_AMOUNT_FC
           , ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, sysdate, 1) DISCOUNT_LC
           , ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, sysdate, 0) DISCOUNT_FC
           , ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 1) DET_PAIED_LC
           , ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 0) DET_PAIED_FC
           , exp.EXP_AMOUNT_LC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 1) SOLDE_EXP_LC
           , exp.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 0) SOLDE_EXP_FC
           , ACT_CURRENCY_EVALUATION.GetConvertAmount(exp.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 0)
                                                    , PAR.ACS_FINANCIAL_CURRENCY_ID
                                                    , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                    , sysdate
                                                    , procparam_6
                                                     ) SOLDE_REEVAL_LC
           , exp.EXP_SLICE
           , ACT_FUNCTIONS.LastClaimsNumber(exp.ACT_EXPIRY_ID) LAST_CLAIMS_LEVEL
           , ACT_FUNCTIONS.LastClaimsDate(exp.ACT_EXPIRY_ID) LAST_CLAIMS_DATE
           , exp.ACS_FIN_ACC_S_PAYMENT_ID
           , PMM.ACS_PAYMENT_METHOD_ID
           , (select PME.C_METHOD_CATEGORY
                from ACS_PAYMENT_METHOD PME
               where PME.ACS_PAYMENT_METHOD_ID = PMM.ACS_PAYMENT_METHOD_ID) C_METHOD_CATEGORY
           , (select DE4.DES_DESCRIPTION_SUMMARY
                from ACS_DESCRIPTION DE4
               where DE4.ACS_PAYMENT_METHOD_ID = PMM.ACS_PAYMENT_METHOD_ID
                 and DE4.PC_LANG_ID = vpc_lang_id) PAYMENT_METHOD_DESCR
           , IMP.ACS_PERIOD_ID
           , IMP.IMF_TRANSACTION_DATE
           , IMP.IMF_VALUE_DATE
           , IMP.IMF_DESCRIPTION
           , IMP.ACS_FINANCIAL_ACCOUNT_ID
           , (select ACF.ACC_NUMBER
                from ACS_ACCOUNT ACF
               where ACF.ACS_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID) ACC_NUMBER_FIN
           , (select DE1.DES_DESCRIPTION_SUMMARY
                from ACS_DESCRIPTION DE1
               where DE1.ACS_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID
                 and DE1.PC_LANG_ID = vpc_lang_id) ACCOUNT_FIN_DESCR
           , JOU.JOU_NUMBER
           , EJO.C_ETAT_JOURNAL
           , IMP.IMF_ACS_DIVISION_ACCOUNT_ID
           , SUP.PAC_SUPPLIER_PARTNER_ID
           , SUP.ACS_AUXILIARY_ACCOUNT_ID
           , SUP.C_PARTNER_CATEGORY
           , ACC.ACC_NUMBER ACC_NUMBER_AUX
           , (select DE2.DES_DESCRIPTION_SUMMARY
                from ACS_DESCRIPTION DE2
               where DE2.ACS_ACCOUNT_ID = SUP.ACS_AUXILIARY_ACCOUNT_ID
                 and DE2.PC_LANG_ID = vpc_lang_id) ACCOUNT_AUX_DESCR
           , ACC.ACS_SUB_SET_ID
           , (select DE3.DES_DESCRIPTION_SUMMARY
                from ACS_DESCRIPTION DE3
               where DE3.ACS_SUB_SET_ID = ACC.ACS_SUB_SET_ID
                 and DE3.PC_LANG_ID = vpc_lang_id) SUB_SET_DESCR
           , AUX.C_TYPE_ACCOUNT
           , PER.PER_NAME
           , PER.PER_FORENAME
           , PER.PER_SHORT_NAME
           , PER.PER_ACTIVITY
           , PER.PER_KEY1
           , (select ADR.ADD_FORMAT
                from PAC_ADDRESS ADR
               where ADR.PAC_PERSON_ID = SUP.PAC_SUPPLIER_PARTNER_ID
                 and ADR.ADD_PRINCIPAL = '1') ADD_FORMAT
        from PAC_PERSON PER
           , ACS_AUXILIARY_ACCOUNT AUX
           , PAC_SUPPLIER_PARTNER SUP
           , ACS_FINANCIAL_ACCOUNT FIN
           , ACT_FINANCIAL_IMPUTATION IMP
           , ACT_ETAT_JOURNAL EJO
           , ACT_JOURNAL JOU
           , ACS_FIN_ACC_S_PAYMENT PMM
           , ACT_EXPIRY exp
           , ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_DOCUMENT DOC
           , ACT_PART_IMPUTATION PAR
           , ACS_ACCOUNT ACC
       --ACJ_SUB_SET_CAT            SUB
      where  PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
         and CAT.C_TYPE_CATALOGUE <> '8'
         and   -- Transaction de relance
             PAR.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
         and EXP_CALC_NET + 0 = 1
         and ACT_EXPIRY_MANAGEMENT.IsExpiryOpenedAt(exp.ACT_EXPIRY_ID, sysdate) = 1
         and exp.ACS_FIN_ACC_S_PAYMENT_ID = PMM.ACS_FIN_ACC_S_PAYMENT_ID(+)
         and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
         and DOC.ACT_JOURNAL_ID = EJO.ACT_JOURNAL_ID
         and EJO.C_SUB_SET = 'PAY'
         and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
         and IMP.ACT_DET_PAYMENT_ID is null
         and IMP.ACS_AUXILIARY_ACCOUNT_ID is not null
         and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
         and exp.C_STATUS_EXPIRY = 0
         and FIN.FIN_COLLECTIVE = 1
         and ACC.ACC_NUMBER >= procparam_1
         and ACC.ACC_NUMBER <= procparam_2
         and (   ACC.ACS_SUB_SET_ID = procparam_0
              or procparam_0 is null)
         and (   instr(',' || procparam_5 || ',', to_char(',' || FIN.ACS_FINANCIAL_ACCOUNT_ID || ',') ) > 0
              or procparam_5 is null)
         and (   instr(',' || procparam_7 || ',', to_char(',' || PAR.ACS_FINANCIAL_CURRENCY_ID || ',') ) > 0
              or procparam_7 is null)
         and PAR.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID
         and SUP.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
         and SUP.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID
         and SUP.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID;
  else
    open aRefCursor for
      select PAR.PAR_DOCUMENT
           , PAR.PAR_BLOCKED_DOCUMENT
           , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
           , (select CUB.CURRENCY
                from PCS.PC_CURR CUB
                   , ACS_FINANCIAL_CURRENCY CFB
               where CFB.ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                 and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_MB
           , PAR.ACS_FINANCIAL_CURRENCY_ID
           , (select CUB.CURRENCY
                from PCS.PC_CURR CUB
                   , ACS_FINANCIAL_CURRENCY CFB
               where CFB.ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_FINANCIAL_CURRENCY_ID
                 and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_ME
           , DOC.DOC_NUMBER
           , CAT.C_TYPE_CATALOGUE
           , (select sub.c_type_cumul
                from acj_sub_set_cat sub
               where doc.acj_catalogue_document_id = sub.acj_catalogue_document_id
                 and sub.c_sub_set = 'PAY') C_TYPE_CUMUL
           , exp.ACT_EXPIRY_ID
           , exp.ACT_DOCUMENT_ID
           , exp.ACT_PART_IMPUTATION_ID
           , exp.C_STATUS_EXPIRY
           , exp.EXP_ADAPTED
           , to_char(exp.EXP_ADAPTED, 'YYYY-IW') WEEK_YEAR
           , to_char(exp.EXP_ADAPTED, 'YYYY-MM') MONTH_YEAR
           , to_char(exp.EXP_ADAPTED, 'YYYY') year
           , exp.EXP_CALCULATED
           , exp.EXP_AMOUNT_LC
           , exp.EXP_AMOUNT_FC
           , ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, to_date(procparam_3, 'YYYYMMDD'), 1) DISCOUNT_LC
           , ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, to_date(procparam_3, 'YYYYMMDD'), 0) DISCOUNT_FC
           , ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(procparam_3, 'YYYYMMDD'), 1) DET_PAIED_LC
           , ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(procparam_3, 'YYYYMMDD'), 0) DET_PAIED_FC
           , exp.EXP_AMOUNT_LC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(procparam_3, 'YYYYMMDD'), 1) SOLDE_EXP_LC
           , exp.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(procparam_3, 'YYYYMMDD'), 0) SOLDE_EXP_FC
           , ACT_CURRENCY_EVALUATION.GetConvertAmount(exp.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(procparam_3, 'YYYYMMDD'), 0)
                                                    , PAR.ACS_FINANCIAL_CURRENCY_ID
                                                    , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                    , to_date(procparam_3, 'YYYYMMDD')
                                                    , procparam_6
                                                     ) SOLDE_REEVAL_LC
           , exp.EXP_SLICE
           , ACT_FUNCTIONS.LastClaimsNumber(exp.ACT_EXPIRY_ID) LAST_CLAIMS_LEVEL
           , ACT_FUNCTIONS.LastClaimsDate(exp.ACT_EXPIRY_ID) LAST_CLAIMS_DATE
           , exp.ACS_FIN_ACC_S_PAYMENT_ID
           , PMM.ACS_PAYMENT_METHOD_ID
           , (select PME.C_METHOD_CATEGORY
                from ACS_PAYMENT_METHOD PME
               where PME.ACS_PAYMENT_METHOD_ID = PMM.ACS_PAYMENT_METHOD_ID) C_METHOD_CATEGORY
           , (select DE4.DES_DESCRIPTION_SUMMARY
                from ACS_DESCRIPTION DE4
               where DE4.ACS_PAYMENT_METHOD_ID = PMM.ACS_PAYMENT_METHOD_ID
                 and DE4.PC_LANG_ID = vpc_lang_id) PAYMENT_METHOD_DESCR
           , IMP.ACS_PERIOD_ID
           , IMP.IMF_TRANSACTION_DATE
           , IMP.IMF_VALUE_DATE
           , IMP.IMF_DESCRIPTION
           , IMP.ACS_FINANCIAL_ACCOUNT_ID
           , (select ACF.ACC_NUMBER
                from ACS_ACCOUNT ACF
               where ACF.ACS_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID) ACC_NUMBER_FIN
           , (select DE1.DES_DESCRIPTION_SUMMARY
                from ACS_DESCRIPTION DE1
               where DE1.ACS_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID
                 and DE1.PC_LANG_ID = vpc_lang_id) ACCOUNT_FIN_DESCR
           , JOU.JOU_NUMBER
           , EJO.C_ETAT_JOURNAL
           , IMP.IMF_ACS_DIVISION_ACCOUNT_ID
           , SUP.PAC_SUPPLIER_PARTNER_ID
           , SUP.ACS_AUXILIARY_ACCOUNT_ID
           , SUP.C_PARTNER_CATEGORY
           , ACC.ACC_NUMBER ACC_NUMBER_AUX
           , (select DE2.DES_DESCRIPTION_SUMMARY
                from ACS_DESCRIPTION DE2
               where DE2.ACS_ACCOUNT_ID = SUP.ACS_AUXILIARY_ACCOUNT_ID
                 and DE2.PC_LANG_ID = vpc_lang_id) ACCOUNT_AUX_DESCR
           , ACC.ACS_SUB_SET_ID
           , (select DE3.DES_DESCRIPTION_SUMMARY
                from ACS_DESCRIPTION DE3
               where DE3.ACS_SUB_SET_ID = ACC.ACS_SUB_SET_ID
                 and DE3.PC_LANG_ID = vpc_lang_id) SUB_SET_DESCR
           , AUX.C_TYPE_ACCOUNT
           , PER.PER_NAME
           , PER.PER_FORENAME
           , PER.PER_SHORT_NAME
           , PER.PER_ACTIVITY
           , PER.PER_KEY1
           , (select ADR.ADD_FORMAT
                from PAC_ADDRESS ADR
               where ADR.PAC_PERSON_ID = SUP.PAC_SUPPLIER_PARTNER_ID
                 and ADR.ADD_PRINCIPAL = '1') ADD_FORMAT
        from PAC_PERSON PER
           , ACS_AUXILIARY_ACCOUNT AUX
           , PAC_SUPPLIER_PARTNER SUP
           , ACS_FINANCIAL_ACCOUNT FIN
           , ACT_FINANCIAL_IMPUTATION IMP
           , ACT_ETAT_JOURNAL EJO
           , ACT_JOURNAL JOU
           , ACS_FIN_ACC_S_PAYMENT PMM
           , ACT_EXPIRY exp
           , ACJ_CATALOGUE_DOCUMENT CAT
           , ACT_DOCUMENT DOC
           , ACT_PART_IMPUTATION PAR
           , ACS_ACCOUNT ACC
      where  PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
         and CAT.C_TYPE_CATALOGUE <> '8'
         and   -- Transaction de relance
             PAR.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
         and EXP_CALC_NET + 0 = 1
         and ACT_EXPIRY_MANAGEMENT.IsExpiryOpenedAt(exp.ACT_EXPIRY_ID, to_date(procparam_3, 'YYYYMMDD') ) = 1
         and exp.ACS_FIN_ACC_S_PAYMENT_ID = PMM.ACS_FIN_ACC_S_PAYMENT_ID(+)
         and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
         and DOC.ACT_JOURNAL_ID = EJO.ACT_JOURNAL_ID
         and EJO.C_SUB_SET = 'PAY'
         and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
         and IMP.ACT_DET_PAYMENT_ID is null
         and IMP.ACS_AUXILIARY_ACCOUNT_ID is not null
         and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
         and (   IMP.IMF_TRANSACTION_DATE <= to_date(procparam_3, 'YYYYMMDD')
              or procparam_3 is null)
         and FIN.FIN_COLLECTIVE = 1
         and ACC.ACC_NUMBER >= procparam_1
         and ACC.ACC_NUMBER <= procparam_2
         and (   ACC.ACS_SUB_SET_ID = procparam_0
              or procparam_0 is null)
         and (   instr(',' || procparam_5 || ',', to_char(',' || FIN.ACS_FINANCIAL_ACCOUNT_ID || ',') ) > 0
              or procparam_5 is null)
         and (   instr(',' || procparam_7 || ',', to_char(',' || PAR.ACS_FINANCIAL_CURRENCY_ID || ',') ) > 0
              or procparam_7 is null)
         and PAR.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID
         and SUP.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
         and SUP.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID
         and SUP.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID;
  end if;
  end if;
end RPT_ACR_AGED_SUPPLIER;
