--------------------------------------------------------
--  DDL for Package Body COM_LIB_EBANKING_ACT_YB_XML
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_LIB_EBANKING_ACT_YB_XML" 
/**
 * Gestion des documents e-factures de document finance.
 * Spécialisation : YellowBill.
 *
 * @version 1.0
 * @date 04/2011
 * @author pyvoirol
 * @author skalayci
 * @author spfister
 *
 * Copyright 1997-2011 SolvAxis SA. Tous droits réservés.
 */
IS


 /**
 * Noeud : /Envelope/Body/DeliveryInfo
 */
function GetDeliveryInfo(
  in_document_id IN com_ebanking.act_document_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLElement("DeliveryInfo",
      XMLElement("BillerID",
        (select ECS_ACCOUNT from PCS.PC_EXCHANGE_SYSTEM
         where PC_EXCHANGE_SYSTEM_ID = CEB.PC_EXCHANGE_SYSTEM_ID)
      ),
      XMLForest(null as "DeliveryID"), -- ??????
      XMLElement("DeliveryDate", to_char(DOC.DOC_DOCUMENT_DATE, 'YYYY-MM-DD')),
      XMLElement("TransactionID", CEB.CEB_TRANSACTION_ID)
    ) into lx_data
  from
    ACT_DOCUMENT DOC,
    COM_EBANKING CEB
  where
    CEB.ACT_DOCUMENT_ID = in_document_id and
    DOC.ACT_DOCUMENT_ID = CEB.ACT_DOCUMENT_ID;

  return lx_data;
end;

 /**
 * Noeud : /Envelope/Body/BillPresentment
 */
function GetBillPresentment(
  in_document_id IN com_ebanking.act_document_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLElement("BillPresentment",
      XMLElement("URLBillDetails", null),
      XMLElement("BillDetailsType",
        case (select C_ECS_BILL_PRESENTMENT from PCS.PC_EXCHANGE_SYSTEM
              where PC_EXCHANGE_SYSTEM_ID = CEB.PC_EXCHANGE_SYSTEM_ID)
          when '00' then 'PDF'
          when '01' then 'PDFAppendix'
          when '02' then 'PDFSystem'
          when '03' then 'URL'
        end
      ),
      XMLElement("BillDetails", null)
    ) into lx_data
  from
    COM_EBANKING CEB
  where
    CEB.ACT_DOCUMENT_ID = in_document_id;

  return lx_data;
end;

 /**
 * Noeud : /Envelope/Body/PaymentData
 */
function GetPaymentData(
  in_document_id IN com_ebanking.act_document_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLElement("PaymentData",
      XMLElement("PaymentType",
        case
          when PME.C_TYPE_SUPPORT in ('50', '51', '56') then 'DD'
          else
            case (select C_TYPE_CATALOGUE from ACJ_CATALOGUE_DOCUMENT
                  where ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID)
              when '2' then 'ESR'
              when '6' then 'CREDIT'
              else 'OTHER'
            end
        end
      ),
      XMLForest(com_lib_ebanking_utl.GetFormatedBvrNbr(PME.PME_SBVR) as "ESRCustomerNr"),
      XMLElement("EBillAccountID",
        (select EBP_ACCOUNT from PAC_EBPP_REFERENCE
         where PAC_EBPP_REFERENCE_ID = CEB.PAC_EBPP_REFERENCE_ID)
      ),
      XMLElement("BillLanguage", com_lib_ebanking_utl.GetDefAdressLang(CEB.COM_EBANKING_ID)),
      XMLForest(ISE.EXP_REF_BVR as "ESRReferenceNr"),
      XMLElement("PaymentDueDate", to_char(ISE.EXP_CALCULATED, 'YYYY-MM-DD')),
      XMLElement("TotalAmount",
        case
          when ISE.C_TYPE_CATALOGUE in ('2','5','6') then
            com_lib_ebanking_utl.formatNumber(ISE.EXP_AMOUNT_LC - ISE.DET_PAIED_LC, 2)
        end
      ),
      XMLElement("fixAmount", 'No'),
      XMLElement("Currency",
        (select CUR.CURRENCY from PCS.PC_CURR CUR
         where Exists(select 1 from ACS_FINANCIAL_CURRENCY FIN
                      where FIN.ACS_FINANCIAL_CURRENCY_ID = DOC.ACS_FINANCIAL_CURRENCY_ID and
                        FIN.PC_CURR_ID = CUR.PC_CURR_ID))
      )
    ) into lx_data
  from
    ACS_PAYMENT_METHOD PME,
    ACS_FIN_ACC_S_PAYMENT FAS,
    V_ACT_EXPIRY_ISAG ISE,
    ACT_EXPIRY EXP,
    ACT_DOCUMENT DOC,
    COM_EBANKING CEB
  where
    DOC.ACT_DOCUMENT_ID = in_document_id and
    DOC.ACT_DOCUMENT_ID = CEB.ACT_DOCUMENT_ID and
    DOC.ACT_DOCUMENT_ID = ISE.ACT_DOCUMENT_ID and
    ISE.EXP_CALC_NET = 1 and
    EXP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID and
    EXP.EXP_CALC_NET = 1 and
    EXP.ACS_FIN_ACC_S_PAYMENT_ID = FAS.ACS_FIN_ACC_S_PAYMENT_ID(+) and
    FAS.ACS_PAYMENT_METHOD_ID = PME.ACS_PAYMENT_METHOD_ID(+);

  return lx_data;
end;

 /**
 * Noeud : /Envelope/Body/Appendix
 */
function GetAppendix(
  in_document_id IN com_ebanking.act_document_id%TYPE)
  return XMLType
is
  lx_data XMLType;
  lv_presentment pcs.pc_exchange_system.c_ecs_bill_presentment%TYPE;
begin
  select Max(C_ECS_BILL_PRESENTMENT)
  into lv_presentment
  from PCS.PC_EXCHANGE_SYSTEM ECS, COM_EBANKING CEB
  where CEB.ACT_DOCUMENT_ID = in_document_id and
    CEB.PC_EXCHANGE_SYSTEM_ID = ECS.PC_EXCHANGE_SYSTEM_ID;

  -- Si le mode de présentation est
  -- 01 : Avec Bill Presentment, PDF intégré dans le XML
  if (lv_presentment = '01') then
    select
      XMLForest(
        XMLElement("Document",
          XMLAttributes('x-application/pdfappendix' as "MimeType"),
          pcs.pc_encoding_functions.EncodeBase64(CEB.CEB_PDF_FILE)
        ) as "Appendix"
      ) into lx_data
    from COM_EBANKING CEB
    where CEB.ACT_DOCUMENT_ID = in_document_id;
  end if;

  return lx_data;
end;

function getYB12ext_receiverParty(
  in_document_id IN com_ebanking.act_document_id%TYPE)
  return XMLType
is
  lx_data XMLType;
  tpl_ebp pac_ebpp_reference%ROWTYPE;
begin
  select EBP.*
  into tpl_ebp
  from PAC_EBPP_REFERENCE EBP, COM_EBANKING CEB
  where CEB.ACT_DOCUMENT_ID = in_document_id and
    CEB.PAC_EBPP_REFERENCE_ID = EBP.PAC_EBPP_REFERENCE_ID;

  if (tpl_ebp.ebp_own_reference = 1) then
    select
      XMLElement("ReceiverParty",
        XMLElement("CustomerID", V.EBP_ACCOUNT),
        XMLForest(
          XMLForest(
            v.per_name as "CompanyName",
            null as "CompanyDivision",
            null as "Title",
            null as "FamilyName",
            null as "GivenName",
            V.ADD_FORMAT as "Address1",
            null as "Address2",
            null as "POBox",
            V.ADD_ZIPCODE as "ZIP",
            V.ADD_CITY as "City",
            V.CNTID as "Country",
            null as "Email",
            null as "Contact1",
            null as "Contact2"
          ) as "Address"
        ),
        XMLElement("TaxID", V.THI_NO_TVA),
        XMLElement("OnlineID",
          XMLElement("NetworkID", '[yellowbill]'),
          XMLElement("ID", V.EBP_ACCOUNT),
          XMLForest(null as "SubID")
        ),
        XMLForest(null as "AdditionReference") -- ?????
      ) into lx_data
    from (
      select PER.PER_NAME, PER_FORENAME, EBP.EBP_ACCOUNT, THI.THI_NO_TVA, ADDR.*, CNT.CNTID
      from
        COM_EBANKING CEB,
        PAC_EBPP_REFERENCE EBP,
        PAC_CUSTOM_PARTNER CUS,
        PAC_ADDRESS ADDR,
        PAC_PERSON PER,
        PAC_THIRD THI,
        PCS.PC_CNTRY CNT
      where
        CEB.ACT_DOCUMENT_ID = in_document_id and
        CEB.PAC_EBPP_REFERENCE_ID = EBP.PAC_EBPP_REFERENCE_ID and
        EBP.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID and
        CUS.PAC_CUSTOM_PARTNER_ID = ADDR.PAC_PERSON_ID and
        CUS.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID and
        PER.PAC_PERSON_ID = THI.PAC_THIRD_ID and
        ADDR.PC_CNTRY_ID = CNT.PC_CNTRY_ID
      order by
        case when ADDR.DIC_ADDRESS_TYPE_ID = 'Fac' then 0 else 1 end,
        ADDR.ADD_PRINCIPAL
      ) V
    where rownum = 1;
  else
    select
      XMLElement("ReceiverParty",
        XMLElement("CustomerID", V.EBP_ACCOUNT),
        XMLForest(
          XMLForest(
            V.PER_NAME as "CompanyName",
            null as "CompanyDivision",
            null as "Title",
            null as "FamilyName",
            null as "GivenName",
            V.ADD_FORMAT as "Address1",
            null as "Address2",
            null as "POBox",
            V.ADD_ZIPCODE as "ZIP",
            V.ADD_CITY as "City",
            null as "Country",
            null as "Email",
            null as "Contact1",
            null as "Contact2"
          ) as "Address"
        ),
        XMLElement("TaxID", V.THI_NO_TVA),
        XMLElement("OnlineID",
          XMLElement("NetworkID", '[yellowbill]'),
          XMLElement("ID", V.EBP_ACCOUNT),
          XMLForest(null as "SubID")
        ),
        XMLForest(null as "AdditionReference")
      ) into lx_data
    from (
      select PER.PER_NAME, PER_FORENAME, EBP2.EBP_ACCOUNT, THI.THI_NO_TVA, ADDR.*
      from
        COM_EBANKING CEB,
        PAC_EBPP_REFERENCE EBP1,
        PAC_EBPP_REFERENCE EBP2,
        PAC_CUSTOM_PARTNER CUS,
        PAC_ADDRESS ADDR,
        PAC_PERSON PER,
        PAC_THIRD THI
      where
        CEB.ACT_DOCUMENT_ID = in_document_id and
        CEB.PAC_EBPP_REFERENCE_ID = EBP1.PAC_EBPP_REFERENCE_ID and
        EBP1.PAC_PAC_EBPP_REFERENCE_ID = EBP2.PAC_EBPP_REFERENCE_ID and
        EBP2.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID and
        CUS.PAC_CUSTOM_PARTNER_ID = ADDR.PAC_PERSON_ID and
        CUS.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID and
        PER.PAC_PERSON_ID = THI.PAC_THIRD_ID
      order by
        case when ADDR.DIC_ADDRESS_TYPE_ID = 'Fac' then 0 else 1 end,
        ADDR.ADD_PRINCIPAL
      ) V
    where rownum = 1;
  end if;

  return lx_data;

  exception
    when OTHERS then
      return null;
end;

function getYB12ext_DeliveryPlace(
  in_document_id IN com_ebanking.act_document_id%TYPE)
  return XMLType
is
  lx_data XMLType;
  tpl_ebp pac_ebpp_reference%ROWTYPE;
begin
  select EBP.*
  into tpl_ebp
  from PAC_EBPP_REFERENCE EBP, COM_EBANKING CEB
  where CEB.ACT_DOCUMENT_ID = in_document_id;

  if (tpl_ebp.ebp_own_reference = 0) then
    select
      XMLElement("DeliveryPlace",
        XMLForest(
          XMLForest(
            V.PER_NAME as "CompanyName",
            null as "CompanyDivision",
            null as "Title",
            null as "FamilyName",
            null as "GivenName",
            V.ADD_FORMAT as "Address1",
            null as "Address2",
            null as "POBox",
            V.ADD_ZIPCODE as "ZIP",
            V.ADD_CITY as "City",
            null as "Country",
            null as "Email",
            null as "Contact1",
            null as "Contact2"
          ) as "Address"
        ),
        XMLForest(null as "AdditionReference") -- ?????
      ) into lx_data
    from (
      select PER.PER_NAME, PER_FORENAME, EBP.EBP_ACCOUNT, THI.THI_NO_TVA, ADDR.*
      from
        COM_EBANKING CEB,
        PAC_EBPP_REFERENCE EBP,
        PAC_CUSTOM_PARTNER CUS,
        PAC_ADDRESS ADDR,
        PAC_PERSON PER,
        PAC_THIRD THI
      where
        CEB.ACT_DOCUMENT_ID = in_document_id and
        CEB.PAC_EBPP_REFERENCE_ID = EBP.PAC_EBPP_REFERENCE_ID and
        EBP.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID and
        CUS.PAC_CUSTOM_PARTNER_ID = ADDR.PAC_PERSON_ID and
        CUS.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID and
        PER.PAC_PERSON_ID = THI.PAC_THIRD_ID
      order by
        case when ADDR.DIC_ADDRESS_TYPE_ID = 'Fac' then 0 else 1 end,
        ADDR.ADD_PRINCIPAL
      ) V
    where rownum = 1;
  end if;

  return lx_data;

  exception
    when OTHERS then
      return null;
end;


 /**
 * function GetYB12ext_Bill_Header
 * Description
 * Création d'un noeud xml pour le YB1.2
 * Noeud :
 */
function GetYB12ext_Bill_Header(
  in_document_id IN com_ebanking.act_document_id%TYPE)
  return XMLType
is
 lx_data XMLType;
begin
  select
    XMLElement("Header",
      XMLForest(
        case
          when CAT.C_TYPE_CATALOGUE in('2') then 'BILL'
          when CAT.C_TYPE_CATALOGUE in('5', '6')then 'CREDITADVICE'
          else ''
        end as "DocumentType",
        null as "DocumentSubType",
        PAR.PAR_DOCUMENT as "DocumentID" -- numéro de document ISE
      ),
      XMLElement("DocumentReference",
        XMLElement("ReferencePosition", '001'),
        XMLElement("ReferenceType", 'erp_invoice_number'),
        XMLElement("ReferenceValue", DOC.DOC_NUMBER) -- numéro de document ERP
      ),
      XMLElement("DocumentDate", to_char(DOC.DOC_DOCUMENT_DATE, 'YYYY-MM-DD')),
      XMLElement("SenderParty",
        XMLElement("CustomerID", ECS.ECS_ACCOUNT),
        XMLForest(
          XMLForest(
            ECS.ECS_ISSUING_NAME as "CompanyName",
            null as "CompanyDivision",
            null as "Title",
            null as "FamilyName",
            null as "GivenName",
            ECS.ECS_ADDRESS as "Address1",
            null as "Address2",
            null as "POBox",
            ECS.ECS_ZIPCODE as "ZIP",
            ECS.ECS_CITY as "City",
            CNT.CNTID as "Country",
            null as "Email",
            null as "Contact1",
            null as "Contact2"
          ) as "Address"
        ),
        XMLElement("TaxID", COM.COM_VATNO),
        XMLElement("OnlineID",
          XMLElement("NetworkID", '[yellowbill]'),
          XMLElement("ID", ECS.ECS_ACCOUNT),
          XMLForest(null as "SubID")
        ),
        XMLForest(null as "AdditionalReference")
      ),
      com_lib_ebanking_act_yb_xml.getYB12ext_ReceiverParty(in_document_id),
      com_lib_ebanking_act_yb_xml.getYB12ext_DeliveryPlace(in_document_id),
      XMLForest(
        to_char(exp.EXP_CALCULATED, 'YYYY-MM-DD') as "PaymentDueDate",
        CURR.CURRENCY as "Currency"
      ),
      XMLElement("AccountAssignment", null),
      XMLElement("Language", com_lib_ebanking_utl.GetDefAdressLang(CEB.COM_EBANKING_ID)),
      XMLElement("PaymentInformation",
        XMLElement("ESR",
          XMLForest(
            com_lib_ebanking_utl.GetFormatedBvrNbr(PME.PME_SBVR) as "ESRCustomerNumber",
            EXP.EXP_REF_BVR as "ESRReferenceNumber"
          )
        )
      )
    ) into lx_data
  from
    ACT_DOCUMENT DOC,
    ACJ_CATALOGUE_DOCUMENT CAT,
    ACS_FINANCIAL_CURRENCY FCU,
    ACS_PAYMENT_METHOD PME,
    ACS_FIN_ACC_S_PAYMENT FAS,
    ACT_PART_IMPUTATION PAR,
    ACT_EXPIRY EXP,
    COM_EBANKING CEB,
    PAC_EBPP_REFERENCE EBP,
    PCS.PC_EXCHANGE_SYSTEM ECS,
    PCS.PC_CNTRY CNT,
    PCS.PC_COMP COM,
    PCS.PC_CURR CURR
  where
    DOC.ACT_DOCUMENT_ID = PAR.ACT_DOCUMENT_ID and
    DOC.ACS_FINANCIAL_CURRENCY_ID = FCU.ACS_FINANCIAL_CURRENCY_ID and
    DOC.ACT_DOCUMENT_ID = EXP.ACT_DOCUMENT_ID and
    EXP.EXP_CALC_NET = 1 and
    FCU.PC_CURR_ID = CURR.PC_CURR_ID and
    DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID and
    DOC.ACT_DOCUMENT_ID = in_document_id and
    DOC.ACT_DOCUMENT_ID = CEB.ACT_DOCUMENT_ID and
    CEB.PC_EXCHANGE_SYSTEM_ID = ECS.PC_EXCHANGE_SYSTEM_ID and
    CEB.PAC_EBPP_REFERENCE_ID = EBP.PAC_EBPP_REFERENCE_ID and
    COM.PC_COMP_ID = pcs.PC_I_LIB_SESSION.GetCompanyId and
    ECS.PC_CNTRY_ID = CNT.PC_CNTRY_ID(+) and
    EXP.ACS_FIN_ACC_S_PAYMENT_ID = FAS.ACS_FIN_ACC_S_PAYMENT_ID(+) and
    FAS.ACS_PAYMENT_METHOD_ID = PME.ACS_PAYMENT_METHOD_ID(+);

  return lx_data;

  exception
    when others then
      return null;
end;

 /**
 * function GetYB12Ext_Bill_LineItems
 * Description
 * Création d'un noeud xml pour le YB1.2
 * Noeud :
 */
function GetYB12Ext_Bill_LineItems(
  in_document_id IN com_ebanking.act_document_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLElement("LineItems",
      XMLAGG(XMLElement("LineItem",
        XMLForest(
          'NORMAL' as "LineItemType",
          ITEM.POS_NUMBER as "LineItemID",
          null as "ProductGroup",
          null as "ProductSubGroup",
          null as "AchievementDate",
          Substr(pcs.pc_functions.TranslateWord(
            'FTX_ISE_PRODUCT_DESCR',
            com_lib_ebanking_utl.GetDefAdressLangId(CEB.COM_EBANKING_ID)), 1, 255) "ProductDescription",
          1 as "Quantity",
          'C62' as "QuantityDescription",
          1 as "PriceUnit",
          XMLForest(
            XMLForest(
              com_lib_ebanking_utl.FormatNumber(ITEM.TAX_RATE,2) as "Rate",
              com_lib_ebanking_utl.formatNumber(ITEM.TAX_VAT_AMOUNT_LC,2) as "Amount",
              com_lib_ebanking_utl.formatNumber(ITEM.TAX_LIABLED_AMOUNT,2) as "BaseAmountExclusiveTax",
              com_lib_ebanking_utl.formatNumber(ITEM.TAX_LIABLED_AMOUNT + ITEM.TAX_VAT_AMOUNT_LC,2) as "BaseAmountInclusiveTax"
            ) as "TaxDetail",
            com_lib_ebanking_utl.formatNumber(ITEM.TAX_VAT_AMOUNT_LC,2) as "TotalTax"
          ) as "Tax",
          com_lib_ebanking_utl.formatNumber(ITEM.TAX_LIABLED_AMOUNT + ITEM.TAX_VAT_AMOUNT_LC,2) as "AmountInclusiveTax",
          com_lib_ebanking_utl.formatNumber(ITEM.TAX_LIABLED_AMOUNT,2) as "AmountExclusiveTax"
        ),
        XMLElement("AccountAssignment", null),
        XMLForest(
          null as "AllowanceAndCharge",
          null as "FreeText"
        )
      ))
    ) into lx_data
  from
    COM_EBANKING CEB,
    TABLE(com_lib_ebanking_utl.GetLineItems_ACT(in_document_id)) ITEM
  where
    CEB.ACT_DOCUMENT_ID = in_document_id;

  return lx_data;

end;

 /**
 * function GetYB12_Bill_Summary
 * Description
 * Création d'un noeud xml pour le YB1.2
 * Noeud : /Envelope/Body/Bill/Summary
 */
function GetYB12Ext_Bill_Summary(
  in_document_id IN com_ebanking.act_document_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLElement("Summary",
      XMLElement("Tax",
        (select
          XMLAgg(XMLElement("TaxDetail",
            XMLForest(
              com_lib_ebanking_utl.FormatNumber(ITEM.TAX_RATE, 2) as "Rate",
              com_lib_ebanking_utl.FormatNumber(ITEM.TAX_VAT_AMOUNT_LC, 2) as "Amount",
              com_lib_ebanking_utl.FormatNumber(ITEM.TAX_LIABLED_AMOUNT, 2) as "BaseAmountExclusiveTax",
              com_lib_ebanking_utl.FormatNumber(ITEM.TAX_LIABLED_AMOUNT + ITEM.TAX_VAT_AMOUNT_LC, 2) as "BaseAmountInclusiveTax"
            )
          ))
        from TABLE(com_lib_ebanking_utl.GetLineItems_ACT(in_document_id)) ITEM),
        XMLElement("TotalTax", com_lib_ebanking_utl.FormatNumber(SUMM.TAX_VAT_AMOUNT_LC, 2))
      ),
      XMLElement("TotalAmountExclusiveTax", com_lib_ebanking_utl.FormatNumber(SUMM.TAX_LIABLED_AMOUNT, 2)),
      XMLElement("TotalAmountInclusiveTax", com_lib_ebanking_utl.FormatNumber(SUMM.TAX_LIABLED_AMOUNT + SUMM.TAX_VAT_AMOUNT_LC, 2)),
      XMLElement("TotalAmountDue", com_lib_ebanking_utl.FormatNumber(ISE.EXP_AMOUNT_LC - ISE.DET_PAIED_LC, 2))
    ) into lx_data
  from
    V_ACT_EXPIRY_ISAG ISE,
    TABLE(com_lib_ebanking_utl.GetSummary_ACT(in_document_id)) SUMM
  where
    ISE.ACT_DOCUMENT_ID = in_document_id and
    ISE.EXP_CALC_NET = 1;

  return lx_data;

  exception
    when others then
      return null;
end;


 /**
 * function GetYB12_Bill
 * Description
 * Création d'un noeud xml pour le YB1.2
 * Noeud : /Envelope/Body/Bill
 */
function GetYB12Ext_Bill(
  in_document_id IN com_ebanking.act_document_id%TYPE)
  return xmltype
is
  lx_data xmltype;
begin
  select
    XMLElement("Bill",
      com_lib_ebanking_act_yb_xml.GetYB12Ext_Bill_Header(in_document_id),
      com_lib_ebanking_act_yb_xml.GetYB12Ext_Bill_LineItems(in_document_id),
      com_lib_ebanking_act_yb_xml.GetYB12Ext_Bill_Summary(in_document_id)
    )into lx_data
  from dual;

  return lx_data;

end;

END COM_LIB_EBANKING_ACT_YB_XML;
