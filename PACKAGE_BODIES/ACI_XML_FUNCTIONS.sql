--------------------------------------------------------
--  DDL for Package Body ACI_XML_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACI_XML_FUNCTIONS" 
as
  /**
  * function GenXml_ACI_DOCUMENT
  * Description
  *   Méthode pour récuperer toutes les infos de la table ACI_DOCUMENT et ses table enfant associées en XML.
  */
  function GenXml_ACI_DOCUMENT(aDocID in ACI_DOCUMENT.ACI_DOCUMENT_ID%type)
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLElement(ACI_DOCUMENT
                    , XMLForest(ACI_DOCUMENT_ID
                              , ACC_NUMBER
                              , C_FAIL_REASON
                              , C_INTERFACE_CONTROL
                              , C_INTERFACE_ORIGIN
                              , C_STATUS_DOCUMENT
                              , C_CURR_RATE_COVER_TYPE
                              , CAT_KEY
                              , CAT_KEY_PMT
                              , COM_NAME_ACT
                              , COM_NAME_DOC
                              , CURRENCY
                              , DIC_ACT_DOC_FREE_CODE1_ID
                              , DIC_ACT_DOC_FREE_CODE2_ID
                              , DIC_ACT_DOC_FREE_CODE3_ID
                              , DIC_ACT_DOC_FREE_CODE4_ID
                              , DIC_ACT_DOC_FREE_CODE5_ID
                              , DIC_DOC_DESTINATION_ID
                              , DIC_DOC_SOURCE_ID
                              , DOC_CCP_TAX
                              , DOC_CHARGES_LC
                              , DOC_COMMENT
                              , REP_UTILS.DateToReplicatorDate(DOC_DOCUMENT_DATE) as DOC_DOCUMENT_DATE
                              , DOC_DOCUMENT_ID
                              , REP_UTILS.DateToReplicatorDate(DOC_EFFECTIVE_DATE) as DOC_EFFECTIVE_DATE
                              , REP_UTILS.DateToReplicatorDate(DOC_ESTABL_DATE) as DOC_ESTABL_DATE
                              , REP_UTILS.DateToReplicatorDate(DOC_EXECUTIVE_DATE) as DOC_EXECUTIVE_DATE
                              , REP_UTILS.DateToReplicatorDate(DOC_FREE_DATE1) as DOC_FREE_DATE1
                              , REP_UTILS.DateToReplicatorDate(DOC_FREE_DATE2) as DOC_FREE_DATE2
                              , REP_UTILS.DateToReplicatorDate(DOC_FREE_DATE3) as DOC_FREE_DATE3
                              , REP_UTILS.DateToReplicatorDate(DOC_FREE_DATE4) as DOC_FREE_DATE4
                              , REP_UTILS.DateToReplicatorDate(DOC_FREE_DATE5) as DOC_FREE_DATE5
                              , DOC_FREE_MEMO1
                              , DOC_FREE_MEMO2
                              , DOC_FREE_MEMO3
                              , DOC_FREE_MEMO4
                              , DOC_FREE_MEMO5
                              , DOC_FREE_NUMBER1
                              , DOC_FREE_NUMBER2
                              , DOC_FREE_NUMBER3
                              , DOC_FREE_NUMBER4
                              , DOC_FREE_NUMBER5
                              , DOC_FREE_TEXT1
                              , DOC_FREE_TEXT2
                              , DOC_FREE_TEXT3
                              , DOC_FREE_TEXT4
                              , DOC_FREE_TEXT5
                              , DOC_GRP_KEY
                              , REP_UTILS.DateToReplicatorDate(DOC_INTEGRATION_DATE) as DOC_INTEGRATION_DATE
                              , DOC_NUMBER
                              , DOC_ORDER_NO
                              , DOC_PAID_AMOUNT_EUR
                              , DOC_PAID_AMOUNT_FC
                              , DOC_PAID_AMOUNT_LC
                              , DOC_TOTAL_AMOUNT_DC
                              , DOC_TOTAL_AMOUNT_EUR
                              , REP_UTILS.DateToReplicatorDate(sysdate) as DOC_XML_DOC_DATE
                              , FYE_NO_EXERCICE
                              , TYP_KEY
                              , VAT_CURRENCY
                              , STM_STOCK_MOVEMENT_ID
                               )
                    , ACI_XML_FUNCTIONS.Get_ACI_DET_PAYMENT(ACI_DOCUMENT_ID, null)
                    , ACI_XML_FUNCTIONS.Get_ACI_FINANCIAL_IMPUTATION(ACI_DOCUMENT_ID, null)
                    , ACI_XML_FUNCTIONS.Get_ACI_MGM_IMPUTATION(ACI_DOCUMENT_ID, null)
                    , ACI_XML_FUNCTIONS.Get_ACI_PART_IMPUTATION(ACI_DOCUMENT_ID)
                    , ACI_XML_FUNCTIONS.Get_ACI_REMINDER_TEXT(ACI_DOCUMENT_ID, null)
                     )
      into xmldata
      from ACI_DOCUMENT
     where ACI_DOCUMENT_ID = aDocID;

    return xmldata;
  exception
    when others then
      raise;
  end GenXml_ACI_DOCUMENT;

  /**
  * function Get_ACI_PART_IMPUTATION
  * Description
  *   Méthode pour récuperer toutes les infos sous forme XML de la table ACI_PART_IMPUTATION
  *   liées à l'id ACI_DOCUMENT_ID
  */
  function Get_ACI_PART_IMPUTATION(aDocID in ACI_DOCUMENT.ACI_DOCUMENT_ID%type)
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLElement
             (ACI_PART_IMPUTATION
            , (select XMLAgg
                        (XMLElement
                              (LIST_ITEM
                             , XMLForest(ACI_PART_IMPUTATION_ID
                                       , CURRENCY1
                                       , CURRENCY2
                                       , DES_DESCRIPTION_SUMMARY
                                       , DIC_BLOCKED_REASON_ID
                                       , DIC_CENTER_PAYMENT_ID
                                       , DIC_LEVEL_PRIORITY_ID
                                       , DIC_PRIORITY_PAYMENT_ID
                                       , REP_UTILS.DateToReplicatorDate(DOC_DATE_DELIVERY) as DOC_DATE_DELIVERY
                                       , FRE_ACCOUNT_NUMBER
                                       , PAR_BASE_PRICE
                                       , PAR_BLOCKED_DOCUMENT
                                       , PAR_CHARGES_FC
                                       , PAR_CHARGES_LC
                                       , PAR_COMMENT
                                       , PAR_DOCUMENT
                                       , PAR_EXCHANGE_RATE
                                       , PAR_PAIED_FC
                                       , PAR_PAIED_LC
                                       , PAR_REF_BVR
                                       , REP_UTILS.DateToReplicatorDate(PAR_REMIND_DATE) as PAR_REMIND_DATE
                                       , REP_UTILS.DateToReplicatorDate(PAR_REMIND_PRINTDATE) as PAR_REMIND_PRINTDATE
                                       , PCO_DESCR
                                       , PER_CUST_KEY1
                                       , PER_CUST_KEY2
                                       , PER_SUPP_KEY1
                                       , PER_SUPP_KEY2
                                        )
                             , ACI_XML_FUNCTIONS.Get_ACI_DET_PAYMENT(null, ACI_PART_IMPUTATION_ID)
                             , ACI_XML_FUNCTIONS.Get_ACI_EXPIRY(ACI_PART_IMPUTATION_ID)
                             , ACI_XML_FUNCTIONS.Get_ACI_FINANCIAL_IMPUTATION(null, ACI_PART_IMPUTATION_ID)
                             , ACI_XML_FUNCTIONS.Get_ACI_REMINDER(ACI_PART_IMPUTATION_ID)
                             , ACI_XML_FUNCTIONS.Get_ACI_REMINDER_TEXT(null, ACI_PART_IMPUTATION_ID)
                              )
                        )
                 from ACI_PART_IMPUTATION
                where ACI_DOCUMENT_ID = aDocID)
             )
      into xmldata
      from dual;

    return xmldata;
  exception
    when others then
      raise;
  end Get_ACI_PART_IMPUTATION;

  /**
  * function Get_ACI_FINANCIAL_IMPUTATION
  * Description
  *   Méthode pour récuperer toutes les infos sous forme XML de la table ACI_FINANCIAL_IMPUTATION
  *   liées à l'id ACI_DOCUMENT_ID ou ACI_PART_IMPUTATION_ID
  */
  function Get_ACI_FINANCIAL_IMPUTATION(
    aDocID  in ACI_DOCUMENT.ACI_DOCUMENT_ID%type
  , aPartID in ACI_PART_IMPUTATION.ACI_PART_IMPUTATION_ID%type
  )
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLElement
             (ACI_FINANCIAL_IMPUTATION
            , (select XMLAgg
                        (XMLElement
                              (LIST_ITEM
                             , XMLForest(ACI_FINANCIAL_IMPUTATION_ID
                                       , ACC_NUMBER
                                       , AUX_NUMBER
                                       , C_FAM_TRANSACTION_TYP
                                       , C_GENRE_TRANSACTION
                                       , CURRENCY1
                                       , CURRENCY2
                                       , DET_BASE_PRICE
                                       , DIC_IMP_FREE1_ID
                                       , DIC_IMP_FREE2_ID
                                       , DIC_IMP_FREE3_ID
                                       , DIC_IMP_FREE4_ID
                                       , DIC_IMP_FREE5_ID
                                       , DIV_NUMBER
                                       , EMP_NUMBER
                                       , FIX_NUMBER
                                       , GOO_MAJOR_REFERENCE
                                       , IMF_AMOUNT_EUR_C
                                       , IMF_AMOUNT_EUR_D
                                       , IMF_AMOUNT_FC_C
                                       , IMF_AMOUNT_FC_D
                                       , IMF_AMOUNT_LC_C
                                       , IMF_AMOUNT_LC_D
                                       , IMF_BASE_PRICE
                                       , REP_UTILS.DateToReplicatorDate(IMF_COMPARE_DATE) as IMF_COMPARE_DATE
                                       , IMF_COMPARE_TEXT
                                       , IMF_COMPARE_USE_INI
                                       , REP_UTILS.DateToReplicatorDate(IMF_CONTROL_DATE) as IMF_CONTROL_DATE
                                       , IMF_CONTROL_FLAG
                                       , IMF_CONTROL_TEXT
                                       , IMF_CONTROL_USE_INI
                                       , IMF_DESCRIPTION
                                       , IMF_EXCHANGE_RATE
                                       , IMF_GENRE
                                       , IMF_NUMBER
                                       , IMF_NUMBER2
                                       , IMF_NUMBER3
                                       , IMF_NUMBER4
                                       , IMF_NUMBER5
                                       , IMF_PRIMARY
                                       , IMF_TEXT1
                                       , IMF_TEXT2
                                       , IMF_TEXT3
                                       , IMF_TEXT4
                                       , IMF_TEXT5
                                       , REP_UTILS.DateToReplicatorDate(IMF_TRANSACTION_DATE) as IMF_TRANSACTION_DATE
                                       , IMF_TYPE
                                       , REP_UTILS.DateToReplicatorDate(IMF_VALUE_DATE) as IMF_VALUE_DATE
                                       , PER_KEY1
                                       , PER_KEY2
                                       , PER_NO_PERIOD
                                       , RCO_NUMBER
                                       , RCO_TITLE
                                       , TAX_EXCHANGE_RATE
                                       , TAX_INCLUDED_EXCLUDED
                                       , TAX_LIABLED_AMOUNT
                                       , TAX_LIABLED_RATE
                                       , TAX_NUMBER
                                       , TAX_RATE
                                       , TAX_REDUCTION
                                       , TAX_VAT_AMOUNT_EUR
                                       , TAX_VAT_AMOUNT_FC
                                       , TAX_VAT_AMOUNT_LC
                                       , TAX_VAT_AMOUNT_VC
                                        )
                             , ACI_XML_FUNCTIONS.Get_ACI_MGM_IMPUTATION(null, ACI_FINANCIAL_IMPUTATION_ID)
                              )
                        )
                 from ACI_FINANCIAL_IMPUTATION
                where (    aDocID is not null
                       and ACI_DOCUMENT_ID = aDocID
                       and ACI_PART_IMPUTATION_ID is null)
                   or (    aPartID is not null
                       and ACI_PART_IMPUTATION_ID = aPartID) )
             )
      into xmldata
      from dual;

    return xmldata;
  exception
    when others then
      raise;
  end Get_ACI_FINANCIAL_IMPUTATION;

  /**
  * function Get_ACI_DET_PAYMENT
  * Description
  *   Méthode pour récuperer toutes les infos sous forme XML de la table ACI_DET_PAYMENT
  *   liées à l'id ACI_DOCUMENT_ID ou ACI_PART_IMPUTATION_ID
  */
  function Get_ACI_DET_PAYMENT(
    aDocID  in ACI_DOCUMENT.ACI_DOCUMENT_ID%type
  , aPartID in ACI_PART_IMPUTATION.ACI_PART_IMPUTATION_ID%type
  )
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLElement(ACI_DET_PAYMENT
                    , (select XMLAgg(XMLElement(LIST_ITEM
                                              , XMLForest(ACI_DET_PAYMENT_ID
                                                        , C_FAM_TRANSACTION_TYP
                                                        , CAT_KEY_DET
                                                        , DET_CHARGES_EUR
                                                        , DET_CHARGES_FC
                                                        , DET_CHARGES_LC
                                                        , DET_CONTROL_FLAG
                                                        , DET_DEDUCTION_EUR
                                                        , DET_DEDUCTION_FC
                                                        , DET_DEDUCTION_LC
                                                        , DET_DIFF_EXCHANGE
                                                        , DET_DISCOUNT_EUR
                                                        , DET_DISCOUNT_FC
                                                        , DET_DISCOUNT_LC
                                                        , DET_LETTRAGE_NO
                                                        , DET_PAIED_EUR
                                                        , DET_PAIED_FC
                                                        , DET_PAIED_LC
                                                        , DET_SEQ_NUMBER
                                                        , DET_TRANSACTION_TYPE
                                                        , DIC_IMP_FREE1_ID
                                                        , DIC_IMP_FREE2_ID
                                                        , DIC_IMP_FREE3_ID
                                                        , DIC_IMP_FREE4_ID
                                                        , DIC_IMP_FREE5_ID
                                                        , EMP_NUMBER
                                                        , FIX_NUMBER
                                                        , GOO_MAJOR_REFERENCE
                                                        , IMF_NUMBER
                                                        , IMF_NUMBER2
                                                        , IMF_NUMBER3
                                                        , IMF_NUMBER4
                                                        , IMF_NUMBER5
                                                        , IMF_TEXT1
                                                        , IMF_TEXT2
                                                        , IMF_TEXT3
                                                        , IMF_TEXT4
                                                        , IMF_TEXT5
                                                        , PAR_DOCUMENT
                                                        , PER_KEY1
                                                        , PER_KEY2
                                                        , RCO_NUMBER
                                                        , RCO_TITLE
                                                        , CURRENCY1
                                                         )
                                               )
                                    )
                         from ACI_DET_PAYMENT
                        where (    aDocID is not null
                               and ACI_DOCUMENT_ID = aDocID
                               and ACI_PART_IMPUTATION_ID is null)
                           or (    aPartID is not null
                               and ACI_PART_IMPUTATION_ID = aPartID) )
                     )
      into xmldata
      from dual;

    return xmldata;
  exception
    when others then
      raise;
  end Get_ACI_DET_PAYMENT;

  /**
  * function Get_ACI_MGM_IMPUTATION
  * Description
  *   Méthode pour récuperer toutes les infos sous forme XML de la table ACI_MGM_IMPUTATION
  *   liées à l'id ACI_DOCUMENT_ID ou ACI_FINANCIAL_IMPUTATION_ID
  */
  function Get_ACI_MGM_IMPUTATION(
    aDocID in ACI_DOCUMENT.ACI_DOCUMENT_ID%type
  , aFinID in ACI_FINANCIAL_IMPUTATION.ACI_FINANCIAL_IMPUTATION_ID%type
  )
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLElement
             (ACI_MGM_IMPUTATION
            , (select XMLAgg
                        (XMLElement
                             (LIST_ITEM
                            , (XMLForest(ACI_MGM_IMPUTATION_ID
                                       , C_FAM_TRANSACTION_TYP
                                       , CDA_NUMBER
                                       , CPN_NUMBER
                                       , CURRENCY1
                                       , CURRENCY2
                                       , DIC_IMP_FREE1_ID
                                       , DIC_IMP_FREE2_ID
                                       , DIC_IMP_FREE3_ID
                                       , DIC_IMP_FREE4_ID
                                       , DIC_IMP_FREE5_ID
                                       , EMP_NUMBER
                                       , FIX_NUMBER
                                       , GOO_MAJOR_REFERENCE
                                       , IMM_AMOUNT_EUR_C
                                       , IMM_AMOUNT_EUR_D
                                       , IMM_AMOUNT_FC_C
                                       , IMM_AMOUNT_FC_D
                                       , IMM_AMOUNT_LC_C
                                       , IMM_AMOUNT_LC_D
                                       , IMM_BASE_PRICE
                                       , IMM_CONTROL_FLAG
                                       , IMM_DESCRIPTION
                                       , IMM_EXCHANGE_RATE
                                       , IMM_GENRE
                                       , IMM_NUMBER
                                       , IMM_NUMBER2
                                       , IMM_NUMBER3
                                       , IMM_NUMBER4
                                       , IMM_NUMBER5
                                       , IMM_PRIMARY
                                       , IMM_QUANTITY_C
                                       , IMM_QUANTITY_D
                                       , IMM_TEXT1
                                       , IMM_TEXT2
                                       , IMM_TEXT3
                                       , IMM_TEXT4
                                       , IMM_TEXT5
                                       , REP_UTILS.DateToReplicatorDate(IMM_TRANSACTION_DATE) as IMM_TRANSACTION_DATE
                                       , IMM_TYPE
                                       , REP_UTILS.DateToReplicatorDate(IMM_VALUE_DATE) as IMM_VALUE_DATE
                                       , PER_KEY1
                                       , PER_KEY2
                                       , PER_NO_PERIOD
                                       , PF_NUMBER
                                       , PJ_NUMBER
                                       , RCO_NUMBER
                                       , RCO_TITLE
                                       , QTY_NUMBER
                                        )
                              )
                             )
                        )
                 from ACI_MGM_IMPUTATION
                where (    aDocID is not null
                       and ACI_DOCUMENT_ID = aDocID
                       and ACI_FINANCIAL_IMPUTATION_ID is null)
                   or (    aFinID is not null
                       and ACI_FINANCIAL_IMPUTATION_ID = aFinID) )
             )
      into xmldata
      from dual;

    return xmldata;
  exception
    when others then
      raise;
  end Get_ACI_MGM_IMPUTATION;

  /**
  * function Get_ACI_EXPIRY
  * Description
  *   Méthode pour récuperer toutes les infos sous forme XML de la table ACI_EXPIRY
  *   liées à l'id ACI_PART_IMPUTATION_ID
  */
  function Get_ACI_EXPIRY(aPartID in ACI_PART_IMPUTATION.ACI_PART_IMPUTATION_ID%type)
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLElement
             (ACI_EXPIRY
            , (select XMLAgg
                          (XMLElement(LIST_ITEM
                                    , XMLForest(ACI_EXPIRY_ID
                                              , C_STATUS_EXPIRY
                                              , REP_UTILS.DateToReplicatorDate(EXP_ADAPTED) as EXP_ADAPTED
                                              , EXP_AMOUNT_EUR
                                              , EXP_AMOUNT_FC
                                              , EXP_AMOUNT_LC
                                              , EXP_AMOUNT_PROV_EUR
                                              , EXP_AMOUNT_PROV_FC
                                              , EXP_AMOUNT_PROV_LC
                                              , EXP_BVR_CODE
                                              , EXP_CALC_NET
                                              , REP_UTILS.DateToReplicatorDate(EXP_CALCULATED) as EXP_CALCULATED
                                              , REP_UTILS.DateToReplicatorDate(EXP_DATE_PMT_TOT) as EXP_DATE_PMT_TOT
                                              , EXP_DISCOUNT_EUR
                                              , EXP_DISCOUNT_FC
                                              , EXP_DISCOUNT_LC
                                              , EXP_POURCENT
                                              , EXP_REF_BVR
                                              , EXP_SLICE
                                               )
                                     )
                          )
                 from ACI_EXPIRY
                where ACI_PART_IMPUTATION_ID = aPartID)
             )
      into xmldata
      from dual;

    return xmldata;
  exception
    when others then
      raise;
  end Get_ACI_EXPIRY;

  /**
  * function Get_ACI_REMINDER
  * Description
  *   Méthode pour récuperer toutes les infos sous forme XML de la table ACI_REMINDER
  *   liées à l'id ACI_PART_IMPUTATION_ID
  */
  function Get_ACI_REMINDER(aPartID in ACI_PART_IMPUTATION.ACI_PART_IMPUTATION_ID%type)
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLElement(ACI_REMINDER
                    , (select XMLAgg(XMLElement(LIST_ITEM
                                              , XMLForest(ACI_REMINDER_ID
                                                        , CURRENCY1
                                                        , CURRENCY2
                                                        , PAR_DOCUMENT
                                                        , REM_COVER_AMOUNT_FC
                                                        , REM_COVER_AMOUNT_LC
                                                        , REM_NUMBER
                                                        , REM_PAYABLE_AMOUNT_EUR
                                                        , REM_PAYABLE_AMOUNT_FC
                                                        , REM_PAYABLE_AMOUNT_LC
                                                        , REM_SEQ_NUMBER
                                                         )
                                               )
                                    )
                         from ACI_REMINDER
                        where ACI_PART_IMPUTATION_ID = aPartID)
                     )
      into xmldata
      from dual;

    return xmldata;
  exception
    when others then
      raise;
  end Get_ACI_REMINDER;

  /**
  * function Get_ACI_REMINDER_TEXT
  * Description
  *   Méthode pour récuperer toutes les infos sous forme XML de la table ACI_REMINDER_TEXT
  *   liées à l'id ACI_DOCUMENT_ID ou ACI_PART_IMPUTATION_ID
  */
  function Get_ACI_REMINDER_TEXT(
    aDocID  in ACI_DOCUMENT.ACI_DOCUMENT_ID%type
  , aPartID in ACI_PART_IMPUTATION.ACI_PART_IMPUTATION_ID%type
  )
    return xmltype
  is
    xmldata xmltype;
  begin
    select XMLElement(ACI_REMINDER_TEXT
                    , (select XMLAgg(XMLElement(LIST_ITEM, XMLForest(ACI_REMINDER_TEXT_ID, C_TEXT_TYPE, REM_TEXT) ) )
                         from ACI_REMINDER_TEXT
                        where (    aDocID is not null
                               and ACI_DOCUMENT_ID = aDocID
                               and ACI_PART_IMPUTATION_ID is null)
                           or (    aPartID is not null
                               and ACI_PART_IMPUTATION_ID = aPartID) )
                     )
      into xmldata
      from dual;

    return xmldata;
  exception
    when others then
      raise;
  end Get_ACI_REMINDER_TEXT;
end ACI_XML_FUNCTIONS;
