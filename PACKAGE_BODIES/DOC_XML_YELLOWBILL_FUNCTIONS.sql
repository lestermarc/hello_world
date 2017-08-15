--------------------------------------------------------
--  DDL for Package Body DOC_XML_YELLOWBILL_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_XML_YELLOWBILL_FUNCTIONS" 
/**
 * Générateur d'e-factures de document logistique, spécialisé pour PayNet.
 *
 * @version 1.1
 * @date 03/2007
 * @author ngomes
 * @author spfister
 *
 */
is
  /**
  * function GetYB12
  * Description
  *   Création d'un xml pour le format YELLOWBILL 1.2   -> YB12
  */
  function GetYB12_Clob(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return clob
  is
    vXml_DeliveryInfo    xmltype;
    vXml_Bill            xmltype;
    vXml_PaymentData     xmltype;
    vXml_BillPresentment xmltype;
    vXml_Appendix        xmltype;
    vClob                clob;
    tplInfo              crGetYB12Info%rowtype;
  begin
    open crGetYB12Info(aDocumentID);

    fetch crGetYB12Info
     into tplInfo;

    close crGetYB12Info;

    if tplInfo.DOC_DOCUMENT_ID is not null then
      -- Création du noeud xml : /Envelope/Body/DeliveryInfo
      vXml_DeliveryInfo     := GetYB12_DeliveryInfo(tplInfo);
      -- Création du noeud xml : /Envelope/Body/Bill
      vXml_Bill             := GetYB12_Bill(tplInfo);
      -- Création du noeud xml : /Envelope/Body/PaymentData
      vXml_PaymentData      := GetYB12_PaymentData(tplInfo);
      -- Création du noeud xml : /Envelope/Body/BillPresentment
      vXml_BillPresentment  := GetYB12_BillPresentment(tplInfo);
      -- Création du noeud xml : /Envelope/Body/Appendix
      vXml_Appendix         := GetYB12_Appendix(tplInfo);

      select XMLElement("Envelope"
                      , XMLAttributes('http://www.w3.org/2001/XMLSchema-instance' as "xmlns:xsi"
                                    , 'ybInvoice_V1.2.xsd' as "xsi:noNamespaceSchemaLocation"
                                    , 'NULL_VALUE_TO_REPLACE' as "type"
                                     )
                      , XMLElement("Header"
                                 , XMLElement("From", tplInfo.ECS_ISSUING_NAME)
                                 , XMLElement("To", 'IPECeBILLServer')
                                 , XMLElement("UseCase", 'CreateybInvoice')
                                 , XMLElement("SessionID", '1')
                                 , XMLElement("Version", '1.2')
                                 , XMLElement("Status", '0')
                                  )
                      , XMLElement("Body", vXml_DeliveryInfo, vXml_Bill, vXml_PaymentData, vXml_BillPresentment, vXml_Appendix)
                       ).GetClobVal()
        into vClob
        from dual;

      -- Il n'est pas possible d'avoir un attribut sans valeur
      -- C'est pourquoi on a créé l'attribut obligatoire "type" avec une valeur
      -- bidon pour que celui-ci soit présent et ensuite on vide la valeur
      -- Ne pas mettre le prologue / défaut...YB demande un enconding en UTF
      select '<?xml version="1.0" encoding="UTF-8"?>' || chr(10) || replace(vClob, 'NULL_VALUE_TO_REPLACE', '')
        into vClob
        from dual;
    end if;

    return vClob;
  exception
    when others then
      return null;
  end GetYB12_Clob;

  /**
  * function GetYB12
  * Description
  *   Création d'un xml pour le format YELLOWBILL 1.2   -> YB12
  */
  function GetYB12_XMLType(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return xmltype
  is
  begin
    return xmltype(GetYB12_Clob(aDocumentID) );
  end GetYB12_XMLType;

  /**
  * function GetFormatedBvrNbr
  * Description
  *   Formatage du n° de bvr au format 00-000000-0
  */
  function GetFormatedBvrNbr(aBvrNbr in varchar2)
    return varchar2
  is
    vBvrNbr varchar2(30);
  begin
    -- Formatage du n° de bvr au format 00-000000-0
    select substr(BVR, 1, 2) || '-' || substr(BVR, 3, length(BVR) - 3) || '-' || substr(BVR, length(BVR), 1)
      into vBvrNbr
      from (select replace(aBvrNbr, '-', '') BVR
              from dual);

    return vBvrNbr;
  end GetFormatedBvrNbr;

  /**
  * function GetYB12_DeliveryInfo
  * Description
  *   Création d'un noeud xml pour le YB1.2
  *   Noeud : /Envelope/Body/DeliveryInfo
  */
  function GetYB12_DeliveryInfo(aInfo in crGetYB12Info%rowtype)
    return xmltype
  is
    vXml xmltype;
  begin
    select XMLElement("DeliveryInfo"
                    , XMLElement("BillerID", aInfo.ECS_ACCOUNT)
                    , XMLForest(null as "DeliveryID")
                    , XMLElement("DeliveryDate", aInfo.DMT_DATE_DOCUMENT_FORMATED)
                    , XMLElement("TransactionID", aInfo.CEB_TRANSACTION_ID)
                     )
      into vXml
      from dual;

    return vXml;
  exception
    when others then
      return null;
  end GetYB12_DeliveryInfo;

  /**
  * function GetYB12_Bill
  * Description
  *   Création d'un noeud xml pour le YB1.2
  *   Noeud : /Envelope/Body/Bill
  */
  function GetYB12_Bill(aInfo in crGetYB12Info%rowtype)
    return xmltype
  is
    vXml                xmltype;
    vXml_Bill_Header    xmltype;
    vXml_Bill_LineItems xmltype;
    vXml_Bill_Summary   xmltype;
  begin
    -- Création du noeud xml : /Envelope/Body/Bill/Header
    vXml_Bill_Header     := GetYB12_Bill_Header(aInfo);
    -- Création du noeud xml : /Envelope/Body/Bill/LineItems
    vXml_Bill_LineItems  := GetYB12_Bill_LineItems(aInfo);
    -- Création du noeud xml : /Envelope/Body/Bill/Summary
    vXml_Bill_Summary    := GetYB12_Bill_Summary(aInfo);

    select XMLForest(XMLConcat(vXml_Bill_Header, vXml_Bill_LineItems, vXml_Bill_Summary) as "Bill")
      into vXml
      from dual;

    return vXml;
  exception
    when others then
      return null;
  end GetYB12_Bill;

  /**
  * function GetYB12_Bill_Header
  * Description
  *   Création d'un noeud xml pour le YB1.2
  *   Noeud : /Envelope/Body/Bill/Header
  */
  function GetYB12_Bill_Header(aInfo in crGetYB12Info%rowtype)
    return xmltype
  is
    vXml xmltype;
  begin
    select XMLElement
             ("Header"
            , XMLForest(case
                          when aInfo.C_GAUGE_TITLE in('8', '30') then 'BILL'
                          when aInfo.C_GAUGE_TITLE = '9' then 'CREDITADVICE'
                          else ''
                        end as "DocumentType"
                      , null as "DocumentSubType"
                      , aInfo.DMT_NUMBER as "DocumentID"
                       )
            , XMLElement("DocumentReference"
                       , XMLElement("ReferencePosition", '10')
                       , XMLElement("ReferenceType", aInfo.DMT_PARTNER_REFERENCE)
                       , XMLElement("ReferenceValue", 'YOUR_REFERENCE')
                        )
            , XMLElement("DocumentReference"
                       , XMLElement("ReferencePosition", '20')
                       , XMLElement("ReferenceType", aInfo.DMT_REFERENCE)
                       , XMLElement("ReferenceValue", 'OUR_REFERENCE')
                        )
            , XMLElement("DocumentDate", aInfo.DMT_DATE_DOCUMENT_FORMATED)
            , XMLElement("SenderParty"
                       , XMLElement("CustomerID", aInfo.ECS_ACCOUNT)
                       , XMLForest(XMLForest(aInfo.ECS_ISSUING_NAME as "CompanyName"
                                           , null as "CompanyDivision"
                                           , null as "Title"
                                           , null as "FamilyName"
                                           , null as "GivenName"
                                           , aInfo.ECS_ADDRESS as "Address1"
                                           , null as "Address2"
                                           , null as "POBox"
                                           , aInfo.ECS_ZIPCODE as "ZIP"
                                           , aInfo.ECS_CITY as "City"
                                           , aInfo.ECS_CNTID as "Country"
                                           , null as "Email"
                                           , null as "Contact1"
                                           , null as "Contact2"
                                            ) as "Address"
                                  )
                       , XMLElement("TaxID", aInfo.COM_VATNO)
                       , XMLElement("OnlineID", XMLElement("NetworkID", '[yellowbill]'), XMLElement("ID", aInfo.ECS_ACCOUNT), XMLForest(null as "SubID") )
                       , XMLForest(null as "AdditionReference")
                        )
            , XMLElement("ReceiverParty"
                       , XMLElement("CustomerID", aInfo.EBP_ACCOUNT)
                       , XMLForest(XMLForest(aInfo.DMT_NAME3 as "CompanyName"
                                           , null as "CompanyDivision"
                                           , null as "Title"
                                           , null as "FamilyName"
                                           , null as "GivenName"
                                           , aInfo.DMT_ADDRESS3 as "Address1"
                                           , null as "Address2"
                                           , null as "POBox"
                                           , aInfo.DMT_POSTCODE3 as "ZIP"
                                           , aInfo.DMT_TOWN3 as "City"
                                           , aInfo.DMT_CNTRY3 as "Country"
                                           , null as "Email"
                                           , null as "Contact1"
                                           , null as "Contact2"
                                            ) as "Address"
                                  )
                       , XMLElement("TaxID", aInfo.THI_NO_TVA)
                       , XMLElement("OnlineID", XMLElement("NetworkID", '[yellowbill]'), XMLElement("ID", aInfo.EBP_ACCOUNT), XMLForest(null as "SubID") )
                       , XMLForest(null as "AdditionReference")
                        )
            , XMLForest(null as "DeliveryPlace"
                      , aInfo.PAD_PAYMENT_DATE_FORMATED as "PaymentDueDate"
                      , XMLForest(aInfo.DMT_DATE_DELIVERY_FORMATED as "StartDateAchievement", aInfo.DMT_DATE_DELIVERY_FORMATED as "EndDateAchievement") as "AchievementDate"
                      , aInfo.CURRENCY as "Currency"
                       )
            , XMLElement("AccountAssignment", null)
            , XMLForest(aInfo.LANID as "Language")
            , XMLForest
                (XMLConcat( (select XMLElement("ESR"
                                             , XMLForest(GetFormatedBvrNbr(aInfo.FRE_ACCOUNT_NUMBER) as "ESRCustomerNumber"
                                                       , aInfo.PAD_BVR_REFERENCE_NUM as "ESRReferenceNumber"
                                                        )
                                              )
                               from dual
                              where aInfo.C_TYPE_REFERENCE = '3')
                         , (select XMLElement("IPI"
                                            , XMLForest(aInfo.FRE_ACCOUNT_NUMBER as "IBAN"
                                                      , null as "IPIPurpose"
                                                      , case
                                                          when aInfo.C_CHARGES_MANAGEMENT = '0' then 'ORDERINGCUSTOMER'
                                                          when aInfo.C_CHARGES_MANAGEMENT = '1' then 'BENEFICIARY'
                                                          when aInfo.C_CHARGES_MANAGEMENT = '2' then 'SHARED'
                                                        end as "IPIExpensesType"
                                                      , 0 as "IPIFormCode"
                                                       )
                                             )
                              from dual
                             where aInfo.C_TYPE_REFERENCE = '5')
                          ) as "PaymentInformation"
                )
            , XMLForest(null as "FreeText")
             )
      into vXml
      from dual;

    return vXml;
  exception
    when others then
      return null;
  end GetYB12_Bill_Header;

  /**
  * function GetYB12_Bill_LineItems
  * Description
  *   Création d'un noeud xml pour le YB1.2
  *   Noeud : /Envelope/Body/Bill/LineItems
  */
  function GetYB12_Bill_LineItems(aInfo in crGetYB12Info%rowtype)
    return xmltype
  is
    vXml    xmltype;
    vXmlPos xmltype;
    vXmlFch xmltype;
  begin
    -- Liste des positions
    select XMLAgg(XMLElement("LineItem"
                           , XMLForest('NORMAL' as "LineItemType"
                                     , POS_NUMBER as "LineItemID"
                                     , null as "ProductGroup"
                                     , null as "ProductSubGroup"
                                     , null as "AchievementDate"
                                     , POS_SHORT_DESCRIPTION as "ProductDescription"
                                     , POS_REFERENCE as "ProductID"
                                     , POS_FINAL_QUANTITY as "Quantity"
                                     , UME_UOM_CODE as "QuantityDescription"
                                     , 1 as "PriceUnit"
                                     , POS_NET_UNIT_VALUE_INCL as "PriceInclusiveTax"
                                     , POS_NET_UNIT_VALUE as "PriceExclusiveTax"
                                     , XMLForest(XMLForest(POS_VAT_RATE as "Rate"
                                                         , POS_VAT_AMOUNT as "Amount"
                                                         , POS_NET_VALUE_EXCL as "BaseAmountExclusiveTax"
                                                         , POS_NET_VALUE_INCL as "BaseAmountInclusiveTax"
                                                          ) as "TaxDetail"
                                               , POS_VAT_AMOUNT as "TotalTax"
                                                ) as "Tax"
                                     , POS_NET_VALUE_INCL as "AmountInclusiveTax"
                                     , POS_NET_VALUE_EXCL as "AmountExclusiveTax"
                                      )
                           , XMLElement("AccountAssignment", null)
                           , XMLForest(null as "AllowanceAndCharge", null as "FreeText")
                            )
                 )
      into vXmlPos
      from (select   POS.POS_NUMBER
                   , nvl(POS.POS_SHORT_DESCRIPTION, '-') POS_SHORT_DESCRIPTION
                   , POS.POS_REFERENCE
                   , nvl(POS.POS_FINAL_QUANTITY, 1) POS_FINAL_QUANTITY
                   , nvl(POS.POS_NET_UNIT_VALUE_INCL, 0) POS_NET_UNIT_VALUE_INCL
                   , nvl(POS.POS_NET_UNIT_VALUE, 0) POS_NET_UNIT_VALUE
                   , nvl(POS.POS_VAT_RATE, 0) POS_VAT_RATE
                   , nvl(POS.POS_VAT_AMOUNT, 0) POS_VAT_AMOUNT
                   , nvl(POS.POS_NET_VALUE_EXCL, 0) POS_NET_VALUE_EXCL
                   , nvl(POS.POS_NET_VALUE_INCL, 0) POS_NET_VALUE_INCL
                   , nvl(UME.UME_UOM_CODE, 'C62') UME_UOM_CODE
                from DOC_POSITION POS
                   , DIC_UNIT_OF_MEASURE UME
               where POS.DOC_DOCUMENT_ID = aInfo.DOC_DOCUMENT_ID
                 and POS.C_GAUGE_TYPE_POS in('1', '2', '3', '5', '7', '8', '10', '21')
                 and POS.DIC_UNIT_OF_MEASURE_ID = UME.DIC_UNIT_OF_MEASURE_ID(+)
            union
            select   POS.POS_NUMBER
                   , nvl(POS.POS_SHORT_DESCRIPTION, '-') POS_SHORT_DESCRIPTION
                   , POS.POS_REFERENCE
                   , nvl(POS.POS_FINAL_QUANTITY, 1) POS_FINAL_QUANTITY
                   , sum(POS_CPT.POS_NET_UNIT_VALUE_INCL) POS_NET_UNIT_VALUE_INCL
                   , sum(POS_CPT.POS_NET_UNIT_VALUE) POS_NET_UNIT_VALUE
                   , sum(POS_CPT.POS_VAT_RATE) POS_VAT_RATE
                   , sum(POS_CPT.POS_VAT_AMOUNT) POS_VAT_AMOUNT
                   , sum(POS_CPT.POS_NET_VALUE_EXCL) POS_NET_VALUE_EXCL
                   , sum(POS_CPT.POS_NET_VALUE_INCL) POS_NET_VALUE_INCL
                   , nvl(UME.UME_UOM_CODE, 'C62') UME_UOM_CODE
                from DOC_POSITION POS
                   , DIC_UNIT_OF_MEASURE UME
                   , DOC_POSITION POS_CPT
               where POS.DOC_DOCUMENT_ID = aInfo.DOC_DOCUMENT_ID
                 and POS.C_GAUGE_TYPE_POS = '9'
                 and POS.DIC_UNIT_OF_MEASURE_ID = UME.DIC_UNIT_OF_MEASURE_ID(+)
                 and POS.DOC_POSITION_ID = POS_CPT.DOC_DOC_POSITION_ID
            group by POS.POS_NUMBER
                   , POS.POS_SHORT_DESCRIPTION
                   , POS.POS_REFERENCE
                   , POS.POS_FINAL_QUANTITY
                   , UME.UME_UOM_CODE
            union
            select   POS.POS_NUMBER
                   , 'Text' POS_SHORT_DESCRIPTION
                   , POS.POS_BODY_TEXT POS_REFERENCE
                   , 1 POS_FINAL_QUANTITY
                   , 0 POS_NET_UNIT_VALUE_INCL
                   , 0 POS_NET_UNIT_VALUE
                   , 0 POS_VAT_RATE
                   , 0 POS_VAT_AMOUNT
                   , 0 POS_NET_VALUE_EXCL
                   , 0 POS_NET_VALUE_INCL
                   , 'C62' UME_UOM_CODE
                from DOC_POSITION POS
               where POS.DOC_DOCUMENT_ID = aInfo.DOC_DOCUMENT_ID
                 and POS.C_GAUGE_TYPE_POS = '4'
            order by POS_NUMBER asc);

    --
    -- Liste des Remises/Taxes/Frais de pied
    select XMLAgg(XMLElement("LineItem"
                           , XMLForest('GLOBALALLOWANCEANDCHARGE' as "LineItemType"
                                     , FCH.C_FINANCIAL_CHARGE || '-' || FCH.DOC_FOOT_CHARGE_ID as "LineItemID"
                                     , null as "ProductGroup"
                                     , null as "ProductSubGroup"
                                     , null as "AchievementDate"
                                     , FCH.FCH_DESCRIPTION as "ProductDescription"
                                     , null as "ProductID"
                                     , 1 as "Quantity"
                                     , 'C62' as "QuantityDescription"
                                     , 1 as "PriceUnit"
                                     , FCH.FCH_INCL_AMOUNT as "PriceInclusiveTax"
                                     , FCH.FCH_EXCL_AMOUNT as "PriceExclusiveTax"
                                     , XMLForest(XMLForest(FCH.FCH_VAT_RATE as "Rate"
                                                         , FCH.FCH_VAT_AMOUNT as "Amount"
                                                         , FCH.FCH_INCL_AMOUNT as "BaseAmountExclusiveTax"
                                                         , FCH.FCH_EXCL_AMOUNT as "BaseAmountInclusiveTax"
                                                          ) as "TaxDetail"
                                               , FCH.FCH_VAT_TOTAL_AMOUNT as "TotalTax"
                                                ) as "Tax"
                                     , FCH.FCH_INCL_AMOUNT as "AmountInclusiveTax"
                                     , FCH.FCH_EXCL_AMOUNT as "AmountExclusiveTax"
                                      )
                           , XMLElement("AccountAssignment", null)
                           , XMLForest(XMLForest(FCH.FCH_FIXED_AMOUNT as "BaseAmount", FCH.FCH_RATE as "Rate") as "AllowanceAndCharge", null as "FreeText")
                            )
                 )
      into vXmlFch
      from (select   C_FINANCIAL_CHARGE
                   , DOC_FOOT_CHARGE_ID
                   , FCH_DESCRIPTION
                   , FCH_INCL_AMOUNT * decode(C_FINANCIAL_CHARGE, '02', -1, 1) FCH_INCL_AMOUNT
                   , FCH_EXCL_AMOUNT * decode(C_FINANCIAL_CHARGE, '02', -1, 1) FCH_EXCL_AMOUNT
                   , FCH_VAT_RATE * decode(C_FINANCIAL_CHARGE, '02', -1, 1) FCH_VAT_RATE
                   , FCH_VAT_AMOUNT * decode(C_FINANCIAL_CHARGE, '02', -1, 1) FCH_VAT_AMOUNT
                   , FCH_VAT_TOTAL_AMOUNT * decode(C_FINANCIAL_CHARGE, '02', -1, 1) FCH_VAT_TOTAL_AMOUNT
                   , FCH_FIXED_AMOUNT * decode(C_FINANCIAL_CHARGE, '02', -1, 1) FCH_FIXED_AMOUNT
                   , FCH_RATE
                from DOC_FOOT_CHARGE
               where DOC_FOOT_ID = aInfo.DOC_DOCUMENT_ID
            order by C_FINANCIAL_CHARGE
                   , DOC_FOOT_CHARGE_ID) FCH;

    select XMLForest(XMLConcat(vXmlPos, vXmlFch) as "LineItems")
      into vXml
      from dual;

    return vXml;
  exception
    when others then
      return null;
  end GetYB12_Bill_LineItems;

  /**
  * function GetYB12_Bill_Summary
  * Description
  *   Création d'un noeud xml pour le YB1.2
  *   Noeud : /Envelope/Body/Bill/Summary
  */
  function GetYB12_Bill_Summary(aInfo in crGetYB12Info%rowtype)
    return xmltype
  is
    vXml xmltype;
  begin
    select XMLElement("Summary"
                    , XMLElement("Tax"
                               , (select   XMLAgg(XMLElement("TaxDetail"
                                                           , XMLForest(VDA.VDA_VAT_RATE as "Rate"
                                                                     , sum(VDA.VDA_VAT_AMOUNT) as "Amount"
                                                                     , sum(VDA.VDA_NET_AMOUNT_EXCL) as "BaseAmountExclusiveTax"
                                                                     , sum(VDA.VDA_VAT_AMOUNT) + sum(VDA.VDA_NET_AMOUNT_EXCL) as "BaseAmountInclusiveTax"
                                                                      )
                                                            )
                                                 )
                                      from DOC_VAT_DET_ACCOUNT VDA
                                     where VDA.DOC_FOOT_ID = aInfo.DOC_DOCUMENT_ID
                                  group by VDA.VDA_VAT_RATE)
                               , XMLElement("TotalTax", aInfo.FOO_TOTAL_VAT_AMOUNT)
                                )
                    , (select XMLAgg(XMLForest(XMLForest(trunc(PAD.PAD_PAYMENT_DATE) - trunc(aInfo.DMT_DATE_VALUE) as "Days"
                                                       , case
                                                           when nvl(PAD.PAD_DATE_AMOUNT, 0) = 0 then 0
                                                           else ACS_FUNCTION.RoundNear(PAD.PAD_DISCOUNT_AMOUNT / PAD.PAD_DATE_AMOUNT, 0.01)
                                                         end as "Rate"
                                                        ) as "Discount"
                                              )
                                    )
                         from DOC_PAYMENT_DATE PAD
                        where PAD.DOC_FOOT_ID = aInfo.DOC_DOCUMENT_ID)
                    , XMLElement("TotalAmountExclusiveTax", aInfo.FOO_DOCUMENT_TOTAL_AMOUNT - aInfo.FOO_TOTAL_VAT_AMOUNT)
                    , XMLElement("TotalAmountInclusiveTax", aInfo.FOO_DOCUMENT_TOTAL_AMOUNT)
                    , XMLForest(null as "Rounding")
                    , XMLForest(null as "FreeText")
                     )
      into vXml
      from dual;

    return vXml;
  exception
    when others then
      return null;
  end GetYB12_Bill_Summary;

  /**
  * function GetYB12_PaymentData
  * Description
  *   Création d'un noeud xml pour le YB1.2
  *   Noeud : /Envelope/Body/PaymentData
  */
  function GetYB12_PaymentData(aInfo in crGetYB12Info%rowtype)
    return xmltype
  is
    vXml xmltype;
  begin
    select XMLElement("PaymentData"
                    , XMLElement("PaymentType"
                               , case
                                   when aInfo.C_TYPE_SUPPORT in('50', '51', '56') then 'DD'
                                   when aInfo.C_GAUGE_TITLE in('8', '30') then 'ESR'
                                   when aInfo.C_GAUGE_TITLE = '9' then 'CREDIT'
                                   else 'OTHER'
                                 end
                                )
                    , XMLForest(GetFormatedBvrNbr(aInfo.PME_SBVR) as "ESRCustomerNr")
                    , XMLElement("EBillAccountID", aInfo.EBP_ACCOUNT)
                    , XMLElement("BillLanguage", aInfo.LANID)
                    , XMLForest(aInfo.PAD_BVR_REFERENCE_NUM as "ESRReferenceNr")
                    , XMLElement("PaymentDueDate", aInfo.PAD_PAYMENT_DATE_FORMATED)
                    , XMLElement("TotalAmount", aInfo.FOO_DOCUMENT_TOTAL_AMOUNT * case
                                    when aInfo.C_GAUGE_TITLE = '9' then -1
                                    else 1
                                  end)
                    , XMLElement("fixAmount", case
                                   when aInfo.C_BVR_GENERATION_METHOD = '02' then 'Yes'
                                   else 'No'
                                 end)
                    , XMLElement("Currency", aInfo.CURRENCY)
                     )
      into vXml
      from dual;

    return vXml;
  exception
    when others then
      return null;
  end GetYB12_PaymentData;

  /**
  * function GetYB12_BillPresentment
  * Description
  *   Création d'un noeud xml pour le YB1.2
  *   Noeud : /Envelope/Body/BillPresentment
  */
  function GetYB12_BillPresentment(aInfo in crGetYB12Info%rowtype)
    return xmltype
  is
    vXml xmltype;
  begin
    select XMLElement("BillPresentment"
                    , XMLElement("URLBillDetails", null)
                    , XMLElement("BillDetailsType"
                               , case
                                   when aInfo.C_ECS_BILL_PRESENTMENT = '00' then 'PDF'
                                   when aInfo.C_ECS_BILL_PRESENTMENT = '01' then 'PDFAppendix'
                                   when aInfo.C_ECS_BILL_PRESENTMENT = '02' then 'PDFSystem'
                                   when aInfo.C_ECS_BILL_PRESENTMENT = '03' then 'URL'
                                 end
                                )
                    , XMLElement("BillDetails", null)
                     )
      into vXml
      from dual;

    return vXml;
  exception
    when others then
      return null;
  end GetYB12_BillPresentment;

  /**
  * function GetYB12_Appendix
  * Description
  *   Création d'un noeud xml pour le YB1.2
  *   Noeud : /Envelope/Body/Appendix
  */
  function GetYB12_Appendix(aInfo in crGetYB12Info%rowtype)
    return xmltype
  is
    vXml xmltype;
  begin
    -- Si le mode de présentation est
    -- 01 : Avec Bill Presentment, PDF intégré dans le XML
    if aInfo.C_ECS_BILL_PRESENTMENT = '01' then
      select XMLForest(XMLElement("Document", XMLAttributes('x-application/pdfappendix' as "MimeType"), PCS.PC_ENCODING_FUNCTIONS.EncodeBase64(CEB_PDF_FILE) ) as "Appendix"
                      )
        into vXml
        from COM_EBANKING
       where DOC_DOCUMENT_ID = aInfo.DOC_DOCUMENT_ID;
    end if;

    return vXml;
  exception
    when others then
      return null;
  end GetYB12_Appendix;

  function GetDeliveryDate(in_document_id in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return date
  is
    ld_document date;
  begin
    select DMT_DATE_DOCUMENT
      into ld_document
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = in_document_id;

    return ld_document;
  exception
    when no_data_found then
      return null;
  end;
end DOC_XML_YELLOWBILL_FUNCTIONS;
