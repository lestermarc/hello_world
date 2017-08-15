--------------------------------------------------------
--  DDL for Procedure RPT_ACT_EXPIRY_CUSTOMER
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_EXPIRY_CUSTOMER" (
  aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, procparam_0    in     varchar2
, procparam_1    in     varchar2
, procparam_2    in     varchar2
, procparam_3    in     varchar2
, procparam_4    in     varchar2
, procparam_5    in     varchar2
, procparam_6    in     number
, procparam_7    in     number
, procparam_8    in     varchar2
, parameter_1    in     varchar2
, parameter_2    in     varchar2
, parameter_3    in     varchar2
, parameter_4    in     varchar2
, parameter_5    in     varchar2
, parameter_6    in     varchar2
, parameter_9    in     varchar2
, parameter_10   in     varchar2
, parameter_11   in     varchar2
, procparam_9    in     varchar2
, procparam_10   in     varchar2
, procparam_11   in     varchar2
, PROCUSER_LANID in     pcs.pc_lang.lanid%type
, pc_user_id     in     PCS.PC_USER.PC_USER_ID%type
)
/**
* description used for report ACT_EXPIRY_CUSTOMER (Postes ouverts débiteurs)

* @author SDO 2003
* @lastupdate VHA 26 JUNE 2013
* @public
* @param procparam_0    Compte du ...        ACC_NUMBER (AUXILIARY_ACCOUNT)
* @param procparam_1    Compte au ...        ACC_NUMBER (AUXILIARY_ACCOUNT)
* @param procparam_2    DateRef...           Date à laquelle sont imprimée les P.O.
* @param procparam_3    Acs_sub_set_ID       ACS_SUB_SET_ID
* @param procparam_4    Division_ID (List)   # =  All  or ACS_DIVISION_ACCOUNT_ID list
* @param procparam_5    Collectiv_ID (List)  # = All or ID list
* @param procparam_6    Type de cours        1 : Cours du jour (par défaut)
                                             2 : Cours d'évaluation
                                             3 : Cours d'inventaire
                                             4 : Cours de bouclement
                                             5 : Cours de facturation
* @param procparam_7    Prise en compte de la date de l'échéance de l'escompte
* @param procparam_8    Paiement methode (List) ACS_PAYMENT_METHOD_ID # = All or ID list
* @param parameter_1    Only due
* @param parameter_2    Due date
* @param parameter_3    Totals type(C_TYPE_CUMUL)
* @param parameter_4    Totals type(C_TYPE_CUMUL)
* @param parameter_5    Totals type(C_TYPE_CUMUL)
* @param parameter_6    Totals type(C_TYPE_CUMUL)
* @param parameter_10   reevaluation
* @param parameter_11   Daybook
* @param procparam_9    Payment filter
* @param procparam_10    Not fully payed date
* @param procparam_11    Fully payed date
*/
is
  vpc_lang_id PCS.PC_LANG.PC_LANG_ID%type := null;
  vpc_user_id PCS.PC_USER.PC_USER_ID%type := null;
  vlstdivisions varchar2(4000);
begin
  if ((procuser_lanid is not null) and (pc_user_id is not null)) then
    PCS.PC_LIB_SESSION.setLanUserId(iLanId    => procuser_lanid
                                  , iPcUserId => pc_user_id
                                  , iPcCompId => null
                                  , iConliId  => null);
      vpc_lang_id  := PCS.PC_I_LIB_SESSION.getUserlangId;
      vpc_user_id  := PCS.PC_I_LIB_SESSION.getUserId;
  end if;

  if (procparam_4 = '#') then
    vlstdivisions := null;
  else
    vlstdivisions := procparam_4;
  end if;

  if (ACS_FUNCTION.ExistDIVI = 1) then
    if (procparam_2 is null) then
      open aRefCursor for
        select PAR.PAR_DOCUMENT
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
             , SUB.C_TYPE_CUMUL
             , EPY.ACT_EXPIRY_ID
             , EPY.ACT_DOCUMENT_ID
             , EPY.ACT_PART_IMPUTATION_ID
             , EPY.C_STATUS_EXPIRY
             , case
                 when(procparam_7 = 1)
                 and (ACT_FUNCTIONS.DiscountAmountAfter(EPY.ACT_DOCUMENT_ID, EPY.EXP_SLICE, sysdate, 1) <> 0) then ACT_FUNCTIONS.DiscountDateAfter
                                                                                                                                           (EPY.ACT_DOCUMENT_ID
                                                                                                                                          , EPY.EXP_SLICE
                                                                                                                                          , sysdate
                                                                                                                                           )
                 else EPY.EXP_ADAPTED
               end EXP_ADAPTED
             , EPY.EXP_CALCULATED
             , EPY.EXP_AMOUNT_LC
             , EPY.EXP_AMOUNT_FC
             , ACT_FUNCTIONS.DiscountAmountAfter(EPY.ACT_DOCUMENT_ID, EPY.EXP_SLICE, sysdate, 1) DISCOUNT_LC
             , ACT_FUNCTIONS.DiscountAmountAfter(EPY.ACT_DOCUMENT_ID, EPY.EXP_SLICE, sysdate, 0) DISCOUNT_FC
             , ACT_FUNCTIONS.TotalPaymentAt(EPY.ACT_EXPIRY_ID, sysdate, 1) DET_PAIED_LC
             , ACT_FUNCTIONS.TotalPaymentAt(EPY.ACT_EXPIRY_ID, sysdate, 0) DET_PAIED_FC
             , EPY.EXP_AMOUNT_LC - ACT_FUNCTIONS.TotalPaymentAt(EPY.ACT_EXPIRY_ID, sysdate, 1) SOLDE_EXP_LC
             , EPY.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(EPY.ACT_EXPIRY_ID, sysdate, 0) SOLDE_EXP_FC
             , ACT_CURRENCY_EVALUATION.GetConvertAmount(EPY.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(EPY.ACT_EXPIRY_ID, sysdate, 0)
                                                      , PAR.ACS_FINANCIAL_CURRENCY_ID
                                                      , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                      , sysdate
                                                      , procparam_6
                                                       ) SOLDE_REEVAL_LC
             , EPY.EXP_SLICE
             , EPY.ACS_FIN_ACC_S_PAYMENT_ID
             , ACT_FUNCTIONS.LastClaimsNumber(EPY.ACT_EXPIRY_ID) LAST_CLAIMS_LEVEL
             , ACT_FUNCTIONS.LastClaimsDate(EPY.ACT_EXPIRY_ID) LAST_CLAIMS_DATE
             , CO2.PCO_DESCR PCO_DESCR_EXP
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
             , IMP.DIC_IMP_FREE1_ID
             , IMP.DIC_IMP_FREE2_ID
             , IMP.DIC_IMP_FREE3_ID
             , IMP.DIC_IMP_FREE4_ID
             , IMP.DIC_IMP_FREE5_ID
             , IMP.IMF_NUMBER
             , IMP.IMF_NUMBER2
             , IMP.IMF_NUMBER3
             , IMP.IMF_NUMBER4
             , IMP.IMF_NUMBER5
             , IMP.IMF_TEXT1
             , IMP.IMF_TEXT2
             , IMP.IMF_TEXT3
             , IMP.IMF_TEXT4
             , IMP.IMF_TEXT5
             , JOU.JOU_NUMBER
             , EJO.C_ETAT_JOURNAL
             , IMP.IMF_ACS_DIVISION_ACCOUNT_ID
             , (select ACD.ACC_NUMBER
                  from ACS_ACCOUNT ACD
                 where ACD.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID) ACC_NUMBER_DIV
             , (select DE2.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE2
                 where DE2.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID
                   and DE2.PC_LANG_ID = vpc_lang_id) ACCOUNT_DIV_DESCR
             , CUS.PAC_CUSTOM_PARTNER_ID
             , CUS.ACS_AUXILIARY_ACCOUNT_ID
             , CUS.C_PARTNER_CATEGORY
             , CO1.PCO_DESCR PCO_DESCR_CUS
             , ACC.ACC_NUMBER ACC_NUMBER_AUX
             , (select DE3.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE3
                 where DE3.ACS_ACCOUNT_ID = CUS.ACS_AUXILIARY_ACCOUNT_ID
                   and DE3.PC_LANG_ID = vpc_lang_id) ACCOUNT_AUX_DESCR
             , (select DE4.DES_DESCRIPTION_LARGE
                  from ACS_DESCRIPTION DE4
                 where DE4.ACS_ACCOUNT_ID = CUS.ACS_AUXILIARY_ACCOUNT_ID
                   and DE4.PC_LANG_ID = vpc_lang_id) ACCOUNT_AUX_LARGE_DESCR
             , ACC.ACS_SUB_SET_ID
             , (select DE5.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE5
                 where DE5.ACS_SUB_SET_ID = ACC.ACS_SUB_SET_ID
                   and DE5.PC_LANG_ID = vpc_lang_id) SUB_SET_DESCR
             , AUX.C_TYPE_ACCOUNT
             , PER.PER_NAME
             , PER.PER_FORENAME
             , PER.PER_SHORT_NAME
             , PER.PER_ACTIVITY
             , PER.PER_KEY1
             , (select ADR.ADD_FORMAT
                  from PAC_ADDRESS ADR
                 where ADR.PAC_PERSON_ID = CUS.PAC_CUSTOM_PARTNER_ID
                   and ADR.ADD_PRINCIPAL = '1') ADD_FORMAT
             , (select DE6.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE6
                 where DE6.ACS_PAYMENT_METHOD_ID = PFC.ACS_PAYMENT_METHOD_ID
                   and DE6.PC_LANG_ID = vpc_lang_id) ACS_PAYMENT_METHOD_DESCR_CUST
             , (select DE7.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE7
                 where DE7.ACS_PAYMENT_METHOD_ID = PFE.ACS_PAYMENT_METHOD_ID
                   and DE7.PC_LANG_ID = vpc_lang_id) ACS_PAYMENT_METHOD_DESCR_EXP
          from ACS_PAYMENT_METHOD PAE
             , ACS_FIN_ACC_S_PAYMENT PFE
             , ACS_PAYMENT_METHOD PAC
             , ACS_FIN_ACC_S_PAYMENT PFC
             , PAC_PAYMENT_CONDITION CO2
             , PAC_PAYMENT_CONDITION CO1
             , PAC_PERSON PER
             , ACS_AUXILIARY_ACCOUNT AUX
             , PAC_CUSTOM_PARTNER CUS
             , ACS_FINANCIAL_ACCOUNT FIN
             , ACT_FINANCIAL_IMPUTATION IMP
             , ACT_ETAT_JOURNAL EJO
             , ACT_JOURNAL JOU
             , ACT_EXPIRY EPY
             , ACJ_CATALOGUE_DOCUMENT CAT
             , ACT_DOCUMENT DOC
             , ACT_PART_IMPUTATION PAR
             , ACS_ACCOUNT ACC
             , ACJ_SUB_SET_CAT SUB
             , table(RPT_FUNCTIONS.TableAuthRptDivisions(vpc_user_id, vlstdivisions) ) AUT
         where PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
           and CAT.C_TYPE_CATALOGUE <> '8'
           and   -- Transaction de relance
               PAR.ACT_PART_IMPUTATION_ID = EPY.ACT_PART_IMPUTATION_ID
           and EXP_CALC_NET + 0 = 1
           and ACT_EXPIRY_MANAGEMENT.IsExpiryOpenedAt(EPY.ACT_EXPIRY_ID, sysdate) = 1
           and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
           and DOC.ACT_JOURNAL_ID = EJO.ACT_JOURNAL_ID
           and EJO.C_SUB_SET = 'REC'
           and EPY.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
           and IMP.ACT_DET_PAYMENT_ID is null
           and IMP.ACS_AUXILIARY_ACCOUNT_ID is not null
           and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and EPY.C_STATUS_EXPIRY = 0
           and FIN.FIN_COLLECTIVE = 1
           and ACC.ACC_NUMBER >= procparam_0
           and ACC.ACC_NUMBER <= procparam_1
           and (   ACC.ACS_SUB_SET_ID = procparam_3
                or procparam_3 is null)
           and AUT.COLUMN_VALUE = IMP.IMF_ACS_DIVISION_ACCOUNT_ID
           and (   instr(',' || procparam_5 || ',', to_char(',' || FIN.ACS_FINANCIAL_ACCOUNT_ID || ',') ) > 0
                or procparam_5 = '#')
           and (   instr(',' || procparam_8 || ',', to_char(',' || PFE.ACS_PAYMENT_METHOD_ID || ',') ) > 0
                or procparam_8 = '#')
           and PAR.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
           and CUS.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and CUS.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID
           and CUS.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
           and CUS.PAC_PAYMENT_CONDITION_ID = CO1.PAC_PAYMENT_CONDITION_ID
           and PAR.PAC_PAYMENT_CONDITION_ID = CO2.PAC_PAYMENT_CONDITION_ID(+)
           and CUS.ACS_FIN_ACC_S_PAYMENT_ID = PFC.ACS_FIN_ACC_S_PAYMENT_ID(+)
           and PFC.ACS_PAYMENT_METHOD_ID = PAC.ACS_PAYMENT_METHOD_ID(+)
           and EPY.ACS_FIN_ACC_S_PAYMENT_ID = PFE.ACS_FIN_ACC_S_PAYMENT_ID(+)
           and PFE.ACS_PAYMENT_METHOD_ID = PAE.ACS_PAYMENT_METHOD_ID(+)
           and doc.ACJ_CATALOGUE_DOCUMENT_ID = SUB.ACJ_CATALOGUE_DOCUMENT_ID
           and SUB.C_SUB_SET = 'REC'
           and (    (    parameter_3 = '1'
                     and SUB.C_TYPE_CUMUL = 'INT')
                or (    parameter_4 = '1'
                    and SUB.C_TYPE_CUMUL = 'EXT')
                or (    parameter_5 = '1'
                    and SUB.C_TYPE_CUMUL = 'PRE')
                or (    parameter_6 = '1'
                    and SUB.C_TYPE_CUMUL = 'ENG')
               )
           and (   parameter_11 = '1'
                or (    parameter_11 = '0'
                    and EJO.C_ETAT_JOURNAL <> 'BRO') )
           and (   parameter_1 = '0'
                or (    parameter_1 = '1'
                    and decode(procparam_7
                             , 1, decode(ACT_FUNCTIONS.DiscountAmountAfter(EPY.ACT_DOCUMENT_ID, EPY.EXP_SLICE, sysdate, 1)
                                       , 0, EPY.EXP_ADAPTED
                                       , ACT_FUNCTIONS.DiscountDateAfter(EPY.ACT_DOCUMENT_ID, EPY.EXP_SLICE, sysdate)
                                        )
                             , EPY.EXP_ADAPTED
                              ) <= to_date(parameter_2, 'yyyyMMdd')
                   )
               )
           and (    (procparam_9 = '0')
                or (     (procparam_9 = '1')
                    and (    (     (PAR.ACS_ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_FINANCIAL_CURRENCY_ID)
                              and (ACT_FUNCTIONS.TOTALPAYMENTAT(EPY.ACT_EXPIRY_ID, to_date(procparam_10, 'yyyyMMdd'), 1) <> EPY.EXP_AMOUNT_LC)
                             )
                         or (     (PAR.ACS_ACS_FINANCIAL_CURRENCY_ID <> PAR.ACS_FINANCIAL_CURRENCY_ID)
                             and (ACT_FUNCTIONS.TOTALPAYMENTAT(EPY.ACT_EXPIRY_ID, to_date(procparam_10, 'yyyyMMdd'), 0) <> EPY.EXP_AMOUNT_FC)
                            )
                        )
                   )
                or (     (procparam_9 = '2')
                    and (    (     (PAR.ACS_ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_FINANCIAL_CURRENCY_ID)
                              and (ACT_FUNCTIONS.TOTALPAYMENTAT(EPY.ACT_EXPIRY_ID, to_date(procparam_11, 'yyyyMMdd'), 1) = EPY.EXP_AMOUNT_LC)
                             )
                         or (     (PAR.ACS_ACS_FINANCIAL_CURRENCY_ID <> PAR.ACS_FINANCIAL_CURRENCY_ID)
                             and (ACT_FUNCTIONS.TOTALPAYMENTAT(EPY.ACT_EXPIRY_ID, to_date(procparam_11, 'yyyyMMdd'), 0) = EPY.EXP_AMOUNT_FC)
                            )
                        )
                   )
               );
    else
      if     (procparam_2 is not null)
         and (length(trim(procparam_2) ) > 0) then
        ACT_FUNCTIONS.ANALYSE_DATE  := to_date(procparam_2, 'YYYYMMDD');
      end if;

      if     (procparam_0 is not null)
         and (length(trim(procparam_0) ) > 0) then
        ACT_FUNCTIONS.ANALYSE_AUXILIARY1  := procparam_0;
      else
        ACT_FUNCTIONS.ANALYSE_AUXILIARY1  := ' ';
      end if;

      if     (procparam_1 is not null)
         and (length(trim(procparam_1) ) > 0) then
        ACT_FUNCTIONS.ANALYSE_AUXILIARY2  := procparam_1;
      else
        ACT_FUNCTIONS.ANALYSE_AUXILIARY2  := ' ';
      end if;

      if     (parameter_11 is not null)
         and (length(trim(parameter_11) ) > 0) then
        if parameter_11 = '1' then
          ACT_FUNCTIONS.BRO  := 1;
        else
          ACT_FUNCTIONS.BRO  := 0;
        end if;
      end if;

      if     (procparam_6 is not null)
         and (length(trim(procparam_6) ) > 0) then
        begin
          ACT_CURRENCY_EVALUATION.RATE_TYPE  := to_number(procparam_6);
        exception
          when invalid_number then
            ACT_CURRENCY_EVALUATION.RATE_TYPE  := 1;   -- Cours du jour
        end;
      end if;

      open aRefCursor for
        select PAR.PAR_DOCUMENT
             , V.ACS_ACS_FINANCIAL_CURRENCY_ID
             , V.CURRENCY2 CURRENCY_MB
             , V.ACS_FINANCIAL_CURRENCY_ID
             , V.CURRENCY1 CURRENCY_ME
             , DOC.DOC_NUMBER
             , CAT.C_TYPE_CATALOGUE
             , V.C_TYPE_CUMUL
             , exp.ACT_EXPIRY_ID
             , V.ACT_DOCUMENT_ID
             , V.ACT_PART_IMPUTATION_ID
             , V.C_STATUS_EXPIRY
             , V.EXP_ADAPTED
             , V.EXP_CALCULATED
             , V.EXP_AMOUNT_LC
             , V.EXP_AMOUNT_FC
             , V.EXP_DISCOUNT_LC DISCOUNT_LC
             , V.EXP_DISCOUNT_FC DISCOUNT_FC
             , V.DET_PAIED_LC
             , V.DET_PAIED_FC
             , V.EXP_AMOUNT_LC - V.DET_PAIED_LC SOLDE_EXP_LC
             , V.EXP_AMOUNT_FC - V.DET_PAIED_FC SOLDE_EXP_FC
             , ACT_CURRENCY_EVALUATION.GetConvertAmount(V.EXP_AMOUNT_FC - V.DET_PAIED_FC
                                                      , PAR.ACS_FINANCIAL_CURRENCY_ID
                                                      , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                      , to_date(procparam_2, 'YYYYMMDD')
                                                      , procparam_6
                                                       ) SOLDE_REEVAL_LC
             , V.EXP_SLICE
             , V.ACS_FIN_ACC_S_PAYMENT_ID
             , V.LAST_CLAIMS_LEVEL
             , V.LAST_CLAIMS_DATE
             , PCO_EXP.PCO_DESCR PCO_DESCR_EXP
             , V.ACS_PERIOD_ID
             , V.IMF_TRANSACTION_DATE
             , V.IMF_VALUE_DATE
             , V.IMF_DESCRIPTION
             , V.ACS_FINANCIAL_ACCOUNT_ID
             , (select ACF.ACC_NUMBER
                  from ACS_ACCOUNT ACF
                 where ACF.ACS_ACCOUNT_ID = V.ACS_FINANCIAL_ACCOUNT_ID) ACC_NUMBER_FIN
             , (select DE1.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE1
                 where DE1.ACS_ACCOUNT_ID = V.ACS_FINANCIAL_ACCOUNT_ID
                   and DE1.PC_LANG_ID = vpc_lang_id) ACCOUNT_FIN_DESCR
             , JOU.JOU_NUMBER
             , V.C_ETAT_JOURNAL
             , V.ACS_DIVISION_ACCOUNT_ID IMF_ACS_DIVISION_ACCOUNT_ID
             , (select ACD.ACC_NUMBER
                  from ACS_ACCOUNT ACD
                 where ACD.ACS_ACCOUNT_ID = V.ACS_DIVISION_ACCOUNT_ID) ACC_NUMBER_DIV
             , (select DE2.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE2
                 where DE2.ACS_ACCOUNT_ID = V.ACS_DIVISION_ACCOUNT_ID
                   and DE2.PC_LANG_ID = vpc_lang_id) ACCOUNT_DIV_DESCR
             , V.PAC_CUSTOM_PARTNER_ID
             , V.ACS_AUXILIARY_ACCOUNT_ID
             , PCO.PCO_DESCR PCO_DESCR_CUS
             , ACC.ACC_NUMBER ACC_NUMBER_AUX
             , (select DE3.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE3
                 where DE3.ACS_ACCOUNT_ID = V.ACS_AUXILIARY_ACCOUNT_ID
                   and DE3.PC_LANG_ID = vpc_lang_id) ACCOUNT_AUX_DESCR
             , (select DE4.DES_DESCRIPTION_LARGE
                  from ACS_DESCRIPTION DE4
                 where DE4.ACS_ACCOUNT_ID = V.ACS_AUXILIARY_ACCOUNT_ID
                   and DE4.PC_LANG_ID = vpc_lang_id) ACCOUNT_AUX_LARGE_DESCR
             , V.ACS_SUB_SET_ID
             , (select DE5.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE5
                 where DE5.ACS_SUB_SET_ID = V.ACS_SUB_SET_ID
                   and DE5.PC_LANG_ID = vpc_lang_id) SUB_SET_DESCR
             , AUX.C_TYPE_ACCOUNT
             , PER.PER_NAME
             , PER.PER_FORENAME
             , PER.PER_SHORT_NAME
             , PER.PER_ACTIVITY
             , PER.PER_KEY1
             , (select ADR.ADD_FORMAT
                  from PAC_ADDRESS ADR
                 where ADR.PAC_PERSON_ID = V.PAC_CUSTOM_PARTNER_ID
                   and ADR.ADD_PRINCIPAL = '1') ADD_FORMAT
             , (select DE6.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE6
                 where DE6.ACS_PAYMENT_METHOD_ID = PFC.ACS_PAYMENT_METHOD_ID
                   and DE6.PC_LANG_ID = vpc_lang_id) ACS_PAYMENT_METHOD_DESCR_CUST
             , (select DE7.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE7
                 where DE7.ACS_PAYMENT_METHOD_ID = PFE.ACS_PAYMENT_METHOD_ID
                   and DE7.PC_LANG_ID = vpc_lang_id) ACS_PAYMENT_METHOD_DESCR_EXP
          from V_ACT_EXPIRY_CUST V
             , ACT_EXPIRY exp
             , ACT_DOCUMENT DOC
             , ACT_JOURNAL JOU
             , ACT_PART_IMPUTATION PAR
             , PAC_PAYMENT_CONDITION PCO_EXP
             , PAC_CUSTOM_PARTNER CUS
             , PAC_PERSON PER
             , PAC_PAYMENT_CONDITION PCO
             , ACS_AUXILIARY_ACCOUNT AUX
             , ACS_ACCOUNT ACC
             , ACS_SUB_SET SUB
             , ACJ_CATALOGUE_DOCUMENT CAT
             , ACS_FIN_ACC_S_PAYMENT PFE
             , ACS_FIN_ACC_S_PAYMENT PFC
             , table(RPT_FUNCTIONS.TableAuthRptDivisions(vpc_user_id, vlstdivisions) ) AUT
         where V.ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
           and V.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
           and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
           and V.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
           and PAR.PAC_PAYMENT_CONDITION_ID = PCO_EXP.PAC_PAYMENT_CONDITION_ID(+)
           and V.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
           and CUS.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
           and CUS.PAC_PAYMENT_CONDITION_ID = PCO.PAC_PAYMENT_CONDITION_ID(+)
           and V.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID
           and AUX.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
           and V.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
           and V.ACS_FIN_ACC_S_PAYMENT_ID = PFE.ACS_FIN_ACC_S_PAYMENT_ID(+)
           and CUS.ACS_FIN_ACC_S_PAYMENT_ID = PFC.ACS_FIN_ACC_S_PAYMENT_ID(+)
--Selection formula from crystal
           and (   ACC.ACS_SUB_SET_ID = procparam_3
                or procparam_3 is null)
           and (   parameter_1 = '0'
                or (    parameter_1 = '1'
                    and decode(procparam_7
                             , 1, decode(ACT_FUNCTIONS.DiscountAmountAfter(v.ACT_DOCUMENT_ID, v.EXP_SLICE, to_date(procparam_2, 'YYYYMMDD'), 1)
                                       , 0, v.EXP_ADAPTED
                                       , ACT_FUNCTIONS.DiscountDateAfter(v.ACT_DOCUMENT_ID, v.EXP_SLICE, to_date(procparam_2, 'YYYYMMDD') )
                                        )
                             , v.EXP_ADAPTED
                              ) <= to_date(parameter_2, 'yyyyMMdd')
                   )
               )
           and (    (    parameter_3 = '1'
                     and substr(ACT_FUNCTIONS.GETCUMULTYP(DOC.ACJ_CATALOGUE_DOCUMENT_ID, nvl2(exp.EXP_PAC_SUPPLIER_PARTNER_ID, 'PAY', 'REC') ), 1, 3) = 'INT'
                    )
                or (    parameter_4 = '1'
                    and substr(ACT_FUNCTIONS.GETCUMULTYP(DOC.ACJ_CATALOGUE_DOCUMENT_ID, nvl2(exp.EXP_PAC_SUPPLIER_PARTNER_ID, 'PAY', 'REC') ), 1, 3) = 'EXT'
                   )
                or (    parameter_5 = '1'
                    and substr(ACT_FUNCTIONS.GETCUMULTYP(DOC.ACJ_CATALOGUE_DOCUMENT_ID, nvl2(exp.EXP_PAC_SUPPLIER_PARTNER_ID, 'PAY', 'REC') ), 1, 3) = 'PRE'
                   )
                or (    parameter_6 = '1'
                    and substr(ACT_FUNCTIONS.GETCUMULTYP(DOC.ACJ_CATALOGUE_DOCUMENT_ID, nvl2(exp.EXP_PAC_SUPPLIER_PARTNER_ID, 'PAY', 'REC') ), 1, 3) = 'ENG'
                   )
               )
           and AUT.COLUMN_VALUE = V.ACS_DIVISION_ACCOUNT_ID
           and (   instr(',' || procparam_5 || ',', to_char(',' || V.ACS_FINANCIAL_ACCOUNT_ID || ',') ) > 0
                or procparam_5 = '#')
           and (   instr(',' || procparam_8 || ',', to_char(',' || PFE.ACS_PAYMENT_METHOD_ID || ',') ) > 0
                or procparam_8 = '#')
           and (    (procparam_9 = '0')
                or (     (procparam_9 = '1')
                    and (    (     (V.ACS_ACS_FINANCIAL_CURRENCY_ID = V.ACS_FINANCIAL_CURRENCY_ID)
                              and (ACT_FUNCTIONS.TOTALPAYMENTAT(V.ACT_EXPIRY_ID, to_date(procparam_10, 'yyyyMMdd'), 1) <> V.EXP_AMOUNT_LC)
                             )
                         or (     (V.ACS_ACS_FINANCIAL_CURRENCY_ID <> V.ACS_FINANCIAL_CURRENCY_ID)
                             and (ACT_FUNCTIONS.TOTALPAYMENTAT(V.ACT_EXPIRY_ID, to_date(procparam_10, 'yyyyMMdd'), 0) <> V.EXP_AMOUNT_FC)
                            )
                        )
                   )
                or (     (procparam_9 = '2')
                    and (    (     (V.ACS_ACS_FINANCIAL_CURRENCY_ID = V.ACS_FINANCIAL_CURRENCY_ID)
                              and (ACT_FUNCTIONS.TOTALPAYMENTAT(V.ACT_EXPIRY_ID, to_date(procparam_11, 'yyyyMMdd'), 1) = V.EXP_AMOUNT_LC)
                             )
                         or (     (V.ACS_ACS_FINANCIAL_CURRENCY_ID <> V.ACS_FINANCIAL_CURRENCY_ID)
                             and (ACT_FUNCTIONS.TOTALPAYMENTAT(V.ACT_EXPIRY_ID, to_date(procparam_11, 'yyyyMMdd'), 0) = V.EXP_AMOUNT_FC)
                            )
                        )
                   )
               );
    end if;
  else
    if (procparam_2 is null) then
      open aRefCursor for
        select PAR.PAR_DOCUMENT
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
             , SUB.C_TYPE_CUMUL
             , EPY.ACT_EXPIRY_ID
             , EPY.ACT_DOCUMENT_ID
             , EPY.ACT_PART_IMPUTATION_ID
             , EPY.C_STATUS_EXPIRY
             , case
                 when(procparam_7 = 1)
                 and (ACT_FUNCTIONS.DiscountAmountAfter(EPY.ACT_DOCUMENT_ID, EPY.EXP_SLICE, sysdate, 1) <> 0) then ACT_FUNCTIONS.DiscountDateAfter
                                                                                                                                           (EPY.ACT_DOCUMENT_ID
                                                                                                                                          , EPY.EXP_SLICE
                                                                                                                                          , sysdate
                                                                                                                                           )
                 else EPY.EXP_ADAPTED
               end EXP_ADAPTED
             , EPY.EXP_CALCULATED
             , EPY.EXP_AMOUNT_LC
             , EPY.EXP_AMOUNT_FC
             , ACT_FUNCTIONS.DiscountAmountAfter(EPY.ACT_DOCUMENT_ID, EPY.EXP_SLICE, sysdate, 1) DISCOUNT_LC
             , ACT_FUNCTIONS.DiscountAmountAfter(EPY.ACT_DOCUMENT_ID, EPY.EXP_SLICE, sysdate, 0) DISCOUNT_FC
             , ACT_FUNCTIONS.TotalPaymentAt(EPY.ACT_EXPIRY_ID, sysdate, 1) DET_PAIED_LC
             , ACT_FUNCTIONS.TotalPaymentAt(EPY.ACT_EXPIRY_ID, sysdate, 0) DET_PAIED_FC
             , EPY.EXP_AMOUNT_LC - ACT_FUNCTIONS.TotalPaymentAt(EPY.ACT_EXPIRY_ID, sysdate, 1) SOLDE_EXP_LC
             , EPY.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(EPY.ACT_EXPIRY_ID, sysdate, 0) SOLDE_EXP_FC
             , ACT_CURRENCY_EVALUATION.GetConvertAmount(EPY.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(EPY.ACT_EXPIRY_ID, sysdate, 0)
                                                      , PAR.ACS_FINANCIAL_CURRENCY_ID
                                                      , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                      , sysdate
                                                      , procparam_6
                                                       ) SOLDE_REEVAL_LC
             , EPY.EXP_SLICE
             , EPY.ACS_FIN_ACC_S_PAYMENT_ID
             , ACT_FUNCTIONS.LastClaimsNumber(EPY.ACT_EXPIRY_ID) LAST_CLAIMS_LEVEL
             , ACT_FUNCTIONS.LastClaimsDate(EPY.ACT_EXPIRY_ID) LAST_CLAIMS_DATE
             , CO2.PCO_DESCR PCO_DESCR_EXP
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
             , IMP.DIC_IMP_FREE1_ID
             , IMP.DIC_IMP_FREE2_ID
             , IMP.DIC_IMP_FREE3_ID
             , IMP.DIC_IMP_FREE4_ID
             , IMP.DIC_IMP_FREE5_ID
             , IMP.IMF_NUMBER
             , IMP.IMF_NUMBER2
             , IMP.IMF_NUMBER3
             , IMP.IMF_NUMBER4
             , IMP.IMF_NUMBER5
             , IMP.IMF_TEXT1
             , IMP.IMF_TEXT2
             , IMP.IMF_TEXT3
             , IMP.IMF_TEXT4
             , IMP.IMF_TEXT5
             , JOU.JOU_NUMBER
             , EJO.C_ETAT_JOURNAL
             , IMP.IMF_ACS_DIVISION_ACCOUNT_ID
             , (select ACD.ACC_NUMBER
                  from ACS_ACCOUNT ACD
                 where ACD.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID) ACC_NUMBER_DIV
             , (select DE2.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE2
                 where DE2.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID
                   and DE2.PC_LANG_ID = vpc_lang_id) ACCOUNT_DIV_DESCR
             , CUS.PAC_CUSTOM_PARTNER_ID
             , CUS.ACS_AUXILIARY_ACCOUNT_ID
             , CUS.C_PARTNER_CATEGORY
             , CO1.PCO_DESCR PCO_DESCR_CUS
             , ACC.ACC_NUMBER ACC_NUMBER_AUX
             , (select DE3.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE3
                 where DE3.ACS_ACCOUNT_ID = CUS.ACS_AUXILIARY_ACCOUNT_ID
                   and DE3.PC_LANG_ID = vpc_lang_id) ACCOUNT_AUX_DESCR
             , (select DE4.DES_DESCRIPTION_LARGE
                  from ACS_DESCRIPTION DE4
                 where DE4.ACS_ACCOUNT_ID = CUS.ACS_AUXILIARY_ACCOUNT_ID
                   and DE4.PC_LANG_ID = vpc_lang_id) ACCOUNT_AUX_LARGE_DESCR
             , ACC.ACS_SUB_SET_ID
             , (select DE5.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE5
                 where DE5.ACS_SUB_SET_ID = ACC.ACS_SUB_SET_ID
                   and DE5.PC_LANG_ID = vpc_lang_id) SUB_SET_DESCR
             , AUX.C_TYPE_ACCOUNT
             , PER.PER_NAME
             , PER.PER_FORENAME
             , PER.PER_SHORT_NAME
             , PER.PER_ACTIVITY
             , PER.PER_KEY1
             , (select ADR.ADD_FORMAT
                  from PAC_ADDRESS ADR
                 where ADR.PAC_PERSON_ID = CUS.PAC_CUSTOM_PARTNER_ID
                   and ADR.ADD_PRINCIPAL = '1') ADD_FORMAT
             , (select DE6.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE6
                 where DE6.ACS_PAYMENT_METHOD_ID = PFC.ACS_PAYMENT_METHOD_ID
                   and DE6.PC_LANG_ID = vpc_lang_id) ACS_PAYMENT_METHOD_DESCR_CUST
             , (select DE7.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE7
                 where DE7.ACS_PAYMENT_METHOD_ID = PFE.ACS_PAYMENT_METHOD_ID
                   and DE7.PC_LANG_ID = vpc_lang_id) ACS_PAYMENT_METHOD_DESCR_EXP
          from ACS_PAYMENT_METHOD PAE
             , ACS_FIN_ACC_S_PAYMENT PFE
             , ACS_PAYMENT_METHOD PAC
             , ACS_FIN_ACC_S_PAYMENT PFC
             , PAC_PAYMENT_CONDITION CO2
             , PAC_PAYMENT_CONDITION CO1
             , PAC_PERSON PER
             , ACS_AUXILIARY_ACCOUNT AUX
             , PAC_CUSTOM_PARTNER CUS
             , ACS_FINANCIAL_ACCOUNT FIN
             , ACT_FINANCIAL_IMPUTATION IMP
             , ACT_ETAT_JOURNAL EJO
             , ACT_JOURNAL JOU
             , ACT_EXPIRY EPY
             , ACJ_CATALOGUE_DOCUMENT CAT
             , ACT_DOCUMENT DOC
             , ACT_PART_IMPUTATION PAR
             , ACS_ACCOUNT ACC
             , ACJ_SUB_SET_CAT SUB
         where PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
           and CAT.C_TYPE_CATALOGUE <> '8'
           and   -- Transaction de relance
               PAR.ACT_PART_IMPUTATION_ID = EPY.ACT_PART_IMPUTATION_ID
           and EXP_CALC_NET + 0 = 1
           and ACT_EXPIRY_MANAGEMENT.IsExpiryOpenedAt(EPY.ACT_EXPIRY_ID, sysdate) = 1
           and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
           and DOC.ACT_JOURNAL_ID = EJO.ACT_JOURNAL_ID
           and EJO.C_SUB_SET = 'REC'
           and EPY.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
           and IMP.ACT_DET_PAYMENT_ID is null
           and IMP.ACS_AUXILIARY_ACCOUNT_ID is not null
           and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and EPY.C_STATUS_EXPIRY = 0
           and FIN.FIN_COLLECTIVE = 1
           and ACC.ACC_NUMBER >= procparam_0
           and ACC.ACC_NUMBER <= procparam_1
           and (   ACC.ACS_SUB_SET_ID = procparam_3
                or procparam_3 is null)
           and (   instr(',' || procparam_5 || ',', to_char(',' || FIN.ACS_FINANCIAL_ACCOUNT_ID || ',') ) > 0
                or procparam_5 = '#')
           and (   instr(',' || procparam_8 || ',', to_char(',' || PFE.ACS_PAYMENT_METHOD_ID || ',') ) > 0
                or procparam_8 = '#')
           and PAR.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
           and CUS.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and CUS.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID
           and CUS.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
           and CUS.PAC_PAYMENT_CONDITION_ID = CO1.PAC_PAYMENT_CONDITION_ID
           and PAR.PAC_PAYMENT_CONDITION_ID = CO2.PAC_PAYMENT_CONDITION_ID(+)
           and CUS.ACS_FIN_ACC_S_PAYMENT_ID = PFC.ACS_FIN_ACC_S_PAYMENT_ID(+)
           and PFC.ACS_PAYMENT_METHOD_ID = PAC.ACS_PAYMENT_METHOD_ID(+)
           and EPY.ACS_FIN_ACC_S_PAYMENT_ID = PFE.ACS_FIN_ACC_S_PAYMENT_ID(+)
           and PFE.ACS_PAYMENT_METHOD_ID = PAE.ACS_PAYMENT_METHOD_ID(+)
           and doc.ACJ_CATALOGUE_DOCUMENT_ID = SUB.ACJ_CATALOGUE_DOCUMENT_ID
           and SUB.C_SUB_SET = 'REC'
           and (    (    parameter_3 = '1'
                     and SUB.C_TYPE_CUMUL = 'INT')
                or (    parameter_4 = '1'
                    and SUB.C_TYPE_CUMUL = 'EXT')
                or (    parameter_5 = '1'
                    and SUB.C_TYPE_CUMUL = 'PRE')
                or (    parameter_6 = '1'
                    and SUB.C_TYPE_CUMUL = 'ENG')
               )
           and (   parameter_11 = '1'
                or (    parameter_11 = '0'
                    and EJO.C_ETAT_JOURNAL <> 'BRO') )
           and (   parameter_1 = '0'
                or (    parameter_1 = '1'
                    and decode(procparam_7
                             , 1, decode(ACT_FUNCTIONS.DiscountAmountAfter(EPY.ACT_DOCUMENT_ID, EPY.EXP_SLICE, sysdate, 1)
                                       , 0, EPY.EXP_ADAPTED
                                       , ACT_FUNCTIONS.DiscountDateAfter(EPY.ACT_DOCUMENT_ID, EPY.EXP_SLICE, sysdate)
                                        )
                             , EPY.EXP_ADAPTED
                              ) <= to_date(parameter_2, 'yyyyMMdd')
                   )
               )
           and (    (procparam_9 = '0')
                or (     (procparam_9 = '1')
                    and (    (     (PAR.ACS_ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_FINANCIAL_CURRENCY_ID)
                              and (ACT_FUNCTIONS.TOTALPAYMENTAT(EPY.ACT_EXPIRY_ID, to_date(procparam_10, 'yyyyMMdd'), 1) <> EPY.EXP_AMOUNT_LC)
                             )
                         or (     (PAR.ACS_ACS_FINANCIAL_CURRENCY_ID <> PAR.ACS_FINANCIAL_CURRENCY_ID)
                             and (ACT_FUNCTIONS.TOTALPAYMENTAT(EPY.ACT_EXPIRY_ID, to_date(procparam_10, 'yyyyMMdd'), 0) <> EPY.EXP_AMOUNT_FC)
                            )
                        )
                   )
                or (     (procparam_9 = '2')
                    and (    (     (PAR.ACS_ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_FINANCIAL_CURRENCY_ID)
                              and (ACT_FUNCTIONS.TOTALPAYMENTAT(EPY.ACT_EXPIRY_ID, to_date(procparam_11, 'yyyyMMdd'), 1) = EPY.EXP_AMOUNT_LC)
                             )
                         or (     (PAR.ACS_ACS_FINANCIAL_CURRENCY_ID <> PAR.ACS_FINANCIAL_CURRENCY_ID)
                             and (ACT_FUNCTIONS.TOTALPAYMENTAT(EPY.ACT_EXPIRY_ID, to_date(procparam_11, 'yyyyMMdd'), 0) = EPY.EXP_AMOUNT_FC)
                            )
                        )
                   )
               );
    else
      if     (procparam_2 is not null)
         and (length(trim(procparam_2) ) > 0) then
        ACT_FUNCTIONS.ANALYSE_DATE  := to_date(procparam_2, 'YYYYMMDD');
      end if;

      if     (procparam_0 is not null)
         and (length(trim(procparam_0) ) > 0) then
        ACT_FUNCTIONS.ANALYSE_AUXILIARY1  := procparam_0;
      else
        ACT_FUNCTIONS.ANALYSE_AUXILIARY1  := ' ';
      end if;

      if     (procparam_1 is not null)
         and (length(trim(procparam_1) ) > 0) then
        ACT_FUNCTIONS.ANALYSE_AUXILIARY2  := procparam_1;
      else
        ACT_FUNCTIONS.ANALYSE_AUXILIARY2  := ' ';
      end if;

      if     (parameter_11 is not null)
         and (length(trim(parameter_11) ) > 0) then
        if parameter_11 = '1' then
          ACT_FUNCTIONS.BRO  := 1;
        else
          ACT_FUNCTIONS.BRO  := 0;
        end if;
      end if;

      if     (procparam_6 is not null)
         and (length(trim(procparam_6) ) > 0) then
        begin
          ACT_CURRENCY_EVALUATION.RATE_TYPE  := to_number(procparam_6);
        exception
          when invalid_number then
            ACT_CURRENCY_EVALUATION.RATE_TYPE  := 1;   -- Cours du jour
        end;
      end if;

      open aRefCursor for
        select PAR.PAR_DOCUMENT
             , V.ACS_ACS_FINANCIAL_CURRENCY_ID
             , V.CURRENCY2 CURRENCY_MB
             , V.ACS_FINANCIAL_CURRENCY_ID
             , V.CURRENCY1 CURRENCY_ME
             , DOC.DOC_NUMBER
             , CAT.C_TYPE_CATALOGUE
             , V.C_TYPE_CUMUL
             , exp.ACT_EXPIRY_ID
             , V.ACT_DOCUMENT_ID
             , V.ACT_PART_IMPUTATION_ID
             , V.C_STATUS_EXPIRY
             , V.EXP_ADAPTED
             , V.EXP_CALCULATED
             , V.EXP_AMOUNT_LC
             , V.EXP_AMOUNT_FC
             , V.EXP_DISCOUNT_LC DISCOUNT_LC
             , V.EXP_DISCOUNT_FC DISCOUNT_FC
             , V.DET_PAIED_LC
             , V.DET_PAIED_FC
             , V.EXP_AMOUNT_LC - V.DET_PAIED_LC SOLDE_EXP_LC
             , V.EXP_AMOUNT_FC - V.DET_PAIED_FC SOLDE_EXP_FC
             , ACT_CURRENCY_EVALUATION.GetConvertAmount(V.EXP_AMOUNT_FC - V.DET_PAIED_FC
                                                      , PAR.ACS_FINANCIAL_CURRENCY_ID
                                                      , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                      , to_date(procparam_2, 'YYYYMMDD')
                                                      , procparam_6
                                                       ) SOLDE_REEVAL_LC
             , V.EXP_SLICE
             , V.ACS_FIN_ACC_S_PAYMENT_ID
             , V.LAST_CLAIMS_LEVEL
             , V.LAST_CLAIMS_DATE
             , PCO_EXP.PCO_DESCR PCO_DESCR_EXP
             , V.ACS_PERIOD_ID
             , V.IMF_TRANSACTION_DATE
             , V.IMF_VALUE_DATE
             , V.IMF_DESCRIPTION
             , V.ACS_FINANCIAL_ACCOUNT_ID
             , (select ACF.ACC_NUMBER
                  from ACS_ACCOUNT ACF
                 where ACF.ACS_ACCOUNT_ID = V.ACS_FINANCIAL_ACCOUNT_ID) ACC_NUMBER_FIN
             , (select DE1.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE1
                 where DE1.ACS_ACCOUNT_ID = V.ACS_FINANCIAL_ACCOUNT_ID
                   and DE1.PC_LANG_ID = vpc_lang_id) ACCOUNT_FIN_DESCR
             , JOU.JOU_NUMBER
             , V.C_ETAT_JOURNAL
             , V.ACS_DIVISION_ACCOUNT_ID IMF_ACS_DIVISION_ACCOUNT_ID
             , (select ACD.ACC_NUMBER
                  from ACS_ACCOUNT ACD
                 where ACD.ACS_ACCOUNT_ID = V.ACS_DIVISION_ACCOUNT_ID) ACC_NUMBER_DIV
             , (select DE2.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE2
                 where DE2.ACS_ACCOUNT_ID = V.ACS_DIVISION_ACCOUNT_ID
                   and DE2.PC_LANG_ID = vpc_lang_id) ACCOUNT_DIV_DESCR
             , V.PAC_CUSTOM_PARTNER_ID
             , V.ACS_AUXILIARY_ACCOUNT_ID
             , PCO.PCO_DESCR PCO_DESCR_CUS
             , ACC.ACC_NUMBER ACC_NUMBER_AUX
             , (select DE3.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE3
                 where DE3.ACS_ACCOUNT_ID = V.ACS_AUXILIARY_ACCOUNT_ID
                   and DE3.PC_LANG_ID = vpc_lang_id) ACCOUNT_AUX_DESCR
             , (select DE4.DES_DESCRIPTION_LARGE
                  from ACS_DESCRIPTION DE4
                 where DE4.ACS_ACCOUNT_ID = V.ACS_AUXILIARY_ACCOUNT_ID
                   and DE4.PC_LANG_ID = vpc_lang_id) ACCOUNT_AUX_LARGE_DESCR
             , V.ACS_SUB_SET_ID
             , (select DE5.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE5
                 where DE5.ACS_SUB_SET_ID = V.ACS_SUB_SET_ID
                   and DE5.PC_LANG_ID = vpc_lang_id) SUB_SET_DESCR
             , AUX.C_TYPE_ACCOUNT
             , PER.PER_NAME
             , PER.PER_FORENAME
             , PER.PER_SHORT_NAME
             , PER.PER_ACTIVITY
             , PER.PER_KEY1
             , (select ADR.ADD_FORMAT
                  from PAC_ADDRESS ADR
                 where ADR.PAC_PERSON_ID = V.PAC_CUSTOM_PARTNER_ID
                   and ADR.ADD_PRINCIPAL = '1') ADD_FORMAT
             , (select DE6.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE6
                 where DE6.ACS_PAYMENT_METHOD_ID = PFC.ACS_PAYMENT_METHOD_ID
                   and DE6.PC_LANG_ID = vpc_lang_id) ACS_PAYMENT_METHOD_DESCR_CUST
             , (select DE7.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE7
                 where DE7.ACS_PAYMENT_METHOD_ID = PFE.ACS_PAYMENT_METHOD_ID
                   and DE7.PC_LANG_ID = vpc_lang_id) ACS_PAYMENT_METHOD_DESCR_EXP
          from V_ACT_EXPIRY_CUST V
             , ACT_EXPIRY exp
             , ACT_DOCUMENT DOC
             , ACT_JOURNAL JOU
             , ACT_PART_IMPUTATION PAR
             , PAC_PAYMENT_CONDITION PCO_EXP
             , PAC_CUSTOM_PARTNER CUS
             , PAC_PERSON PER
             , PAC_PAYMENT_CONDITION PCO
             , ACS_AUXILIARY_ACCOUNT AUX
             , ACS_ACCOUNT ACC
             , ACS_SUB_SET SUB
             , ACJ_CATALOGUE_DOCUMENT CAT
             , ACS_FIN_ACC_S_PAYMENT PFE
             , ACS_FIN_ACC_S_PAYMENT PFC
         where V.ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
           and V.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
           and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
           and V.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
           and PAR.PAC_PAYMENT_CONDITION_ID = PCO_EXP.PAC_PAYMENT_CONDITION_ID(+)
           and V.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
           and CUS.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
           and CUS.PAC_PAYMENT_CONDITION_ID = PCO.PAC_PAYMENT_CONDITION_ID(+)
           and V.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID
           and AUX.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
           and V.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
           and V.ACS_FIN_ACC_S_PAYMENT_ID = PFE.ACS_FIN_ACC_S_PAYMENT_ID(+)
           and CUS.ACS_FIN_ACC_S_PAYMENT_ID = PFC.ACS_FIN_ACC_S_PAYMENT_ID(+)
--Selection formula from crystal
           and (   ACC.ACS_SUB_SET_ID = procparam_3
                or procparam_3 is null)
           and (   parameter_1 = '0'
                or (    parameter_1 = '1'
                    and decode(procparam_7
                             , 1, decode(ACT_FUNCTIONS.DiscountAmountAfter(v.ACT_DOCUMENT_ID, v.EXP_SLICE, to_date(procparam_2, 'YYYYMMDD'), 1)
                                       , 0, v.EXP_ADAPTED
                                       , ACT_FUNCTIONS.DiscountDateAfter(v.ACT_DOCUMENT_ID, v.EXP_SLICE, to_date(procparam_2, 'YYYYMMDD') )
                                        )
                             , v.EXP_ADAPTED
                              ) <= to_date(parameter_2, 'yyyyMMdd')
                   )
               )
           and (    (    parameter_3 = '1'
                     and substr(ACT_FUNCTIONS.GETCUMULTYP(DOC.ACJ_CATALOGUE_DOCUMENT_ID, nvl2(exp.EXP_PAC_SUPPLIER_PARTNER_ID, 'PAY', 'REC') ), 1, 3) = 'INT'
                    )
                or (    parameter_4 = '1'
                    and substr(ACT_FUNCTIONS.GETCUMULTYP(DOC.ACJ_CATALOGUE_DOCUMENT_ID, nvl2(exp.EXP_PAC_SUPPLIER_PARTNER_ID, 'PAY', 'REC') ), 1, 3) = 'EXT'
                   )
                or (    parameter_5 = '1'
                    and substr(ACT_FUNCTIONS.GETCUMULTYP(DOC.ACJ_CATALOGUE_DOCUMENT_ID, nvl2(exp.EXP_PAC_SUPPLIER_PARTNER_ID, 'PAY', 'REC') ), 1, 3) = 'PRE'
                   )
                or (    parameter_6 = '1'
                    and substr(ACT_FUNCTIONS.GETCUMULTYP(DOC.ACJ_CATALOGUE_DOCUMENT_ID, nvl2(exp.EXP_PAC_SUPPLIER_PARTNER_ID, 'PAY', 'REC') ), 1, 3) = 'ENG'
                   )
               )
           and (   instr(',' || procparam_5 || ',', to_char(',' || V.ACS_FINANCIAL_ACCOUNT_ID || ',') ) > 0
                or procparam_5 = '#')
           and (   instr(',' || procparam_8 || ',', to_char(',' || PFE.ACS_PAYMENT_METHOD_ID || ',') ) > 0
                or procparam_8 = '#')
           and (    (procparam_9 = '0')
                or (     (procparam_9 = '1')
                    and (    (     (V.ACS_ACS_FINANCIAL_CURRENCY_ID = V.ACS_FINANCIAL_CURRENCY_ID)
                              and (ACT_FUNCTIONS.TOTALPAYMENTAT(V.ACT_EXPIRY_ID, to_date(procparam_10, 'yyyyMMdd'), 1) <> V.EXP_AMOUNT_LC)
                             )
                         or (     (V.ACS_ACS_FINANCIAL_CURRENCY_ID <> V.ACS_FINANCIAL_CURRENCY_ID)
                             and (ACT_FUNCTIONS.TOTALPAYMENTAT(V.ACT_EXPIRY_ID, to_date(procparam_10, 'yyyyMMdd'), 0) <> V.EXP_AMOUNT_FC)
                            )
                        )
                   )
                or (     (procparam_9 = '2')
                    and (    (     (V.ACS_ACS_FINANCIAL_CURRENCY_ID = V.ACS_FINANCIAL_CURRENCY_ID)
                              and (ACT_FUNCTIONS.TOTALPAYMENTAT(V.ACT_EXPIRY_ID, to_date(procparam_11, 'yyyyMMdd'), 1) = V.EXP_AMOUNT_LC)
                             )
                         or (     (V.ACS_ACS_FINANCIAL_CURRENCY_ID <> V.ACS_FINANCIAL_CURRENCY_ID)
                             and (ACT_FUNCTIONS.TOTALPAYMENTAT(V.ACT_EXPIRY_ID, to_date(procparam_11, 'yyyyMMdd'), 0) = V.EXP_AMOUNT_FC)
                            )
                        )
                   )
               );
    end if;
  end if;
end RPT_ACT_EXPIRY_CUSTOMER;
