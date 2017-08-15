--------------------------------------------------------
--  DDL for Package Body COM_LIB_EBANKING_YB_ACT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_LIB_EBANKING_YB_ACT" 
/**
 * Générateur d'e-factures de document finance, spécialisé pour YellowBill.
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
  gtActiveDocument ACT_DOCUMENT%rowtype;
  gtActiveEbanking COM_EBANKING%rowtype;

  procedure InitIternals(iActDocumentId in COM_EBANKING.ACT_DOCUMENT_ID%type)
  is
  begin
    select *
      into gtActiveDocument
      from ACT_DOCUMENT
     where ACT_DOCUMENT_ID = iActDocumentId;

    select *
      into gtActiveEbanking
      from COM_EBANKING
     where ACT_DOCUMENT_ID = iActDocumentId;

  end InitIternals;

  /**
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
  *   Retour de la langeu de l'adresse de facturation / adresse par défaut
  */
  function GetDefAdressLang
    return varchar2
  is
    lvLanId PCS.PC_LANG.LANID%type;
  begin
    for tplAdrLanId in (select L.*
                          from (select   case lower(LAN.LANID)
                                           when 'ge' then 'de'
                                           else lower(LAN.LANID)
                                         end LANID
                                    from PAC_ADDRESS ADR
                                       , PCS.PC_LANG LAN
                                       , PAC_EBPP_REFERENCE
                                   where PAC_EBPP_REFERENCE_ID = gtActiveEbanking.PAC_EBPP_REFERENCE_ID
                                     and ADR.PAC_PERSON_ID = PAC_CUSTOM_PARTNER_ID
                                     and LAN.PC_LANG_ID = ADR.PC_LANG_ID
                                order by case
                                           when ADR.DIC_ADDRESS_TYPE_ID = 'Fac' then 0
                                           else 1
                                         end
                                       , ADR.ADD_PRINCIPAL) L
                         where rownum = 1) loop
      lvLanId  := tplAdrlanId.LANID;
    end loop;

    if lvLanId is null then
      lvLanId  := 'fr';
    end if;

    return lvLanId;
  end GetDefAdressLang;



  /**
  * Fct principale de la génération XML de YB
  */
  function GetYB12Clob_Ext(iActDocumentId in COM_EBANKING.ACT_DOCUMENT_ID%type)
    return clob
  is
  begin
    return GetYB12_Ext(iActDocumentId).GetClobVal();
  end;

  function GetYB12_Ext(iActDocumentId in COM_EBANKING.ACT_DOCUMENT_ID%type)
    return xmltype
  is
  begin
    return GetYB12_Int(iActDocumentId);
  end GetYB12_Ext;

  function GetYB12Clob_Int(iActDocumentId in COM_EBANKING.ACT_DOCUMENT_ID%type)
    return clob
  is
    lxmldata   xmltype;
  begin
    lxmldata  :=  COM_LIB_EBANKING_YB_ACT.GetYB12_Int(iActDocumentId);
    if lxmldata is not null then
      return pc_jutils.get_XmlPrologDefault || chr(10) || replace(lxmldata.GetClobVal(), 'NULL_VALUE_TO_REPLACE', '');
    else
      return null;
    end if;
  end;

  function GetYB12_Int(iActDocumentId in COM_EBANKING.ACT_DOCUMENT_ID%type)
    return xmltype
  is
    lxmldata        xmltype;
  begin
    begin
      InitIternals(iActDocumentId);
      select XMLElement("Envelope"
                      , XMLAttributes('http://www.w3.org/2001/XMLSchema-instance' as "xmlns:xsi"
                                    , 'ybInvoice_V1.2.xsd' as "xsi:noNamespaceSchemaLocation"
                                    , 'NULL_VALUE_TO_REPLACE' as "type"
                                     )
                      , XMLElement("Header"
                                 , XMLElement("From",
                                              (select ECS_ISSUING_NAME from PCS.PC_EXCHANGE_SYSTEM where PC_EXCHANGE_SYSTEM_ID = gtActiveEbanking.PC_EXCHANGE_SYSTEM_ID))
                                 , XMLElement("To", 'IPECeBILLServer')
                                 , XMLElement("UseCase", 'CreateybInvoice')
                                 , XMLElement("SessionID", '1')
                                 , XMLElement("Version", '1.2')
                                 , XMLElement("Status", '0')
                                  )
                      , XMLElement("Body"
                                  , GetDeliveryInfo
--                                  , case (select C_EBPP_RELATION from PAC_EPBB_REFERENCE where PAC_EBPP_REFERENCE_ID = gtActiveEbanking.PAC_EBPP_REFERENCE_ID)
--                                    when '00' then --B2B
--                                      GetBill
--                                    end
                                  , GetPaymentData
                                  , GetBillPresentment
                                  , GetAppendix)
                       )
        into lxmldata
        from dual;

      return lxmldata;
    exception
      when others then
        return null;
    end;
  end GetYB12_Int;

  /**
  *   Noeud : /Envelope/Body/DeliveryInfo
  */
  function GetDeliveryInfo
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLElement("DeliveryInfo"
                    , XMLElement("BillerID",
                                 (select ECS_ACCOUNT from PCS.PC_EXCHANGE_SYSTEM where PC_EXCHANGE_SYSTEM_ID = gtActiveEbanking.PC_EXCHANGE_SYSTEM_ID))
                    , XMLForest(null as "DeliveryID")
                    , XMLElement("DeliveryDate", (to_char(gtActiveDocument.DOC_DOCUMENT_DATE, 'YYYY-MM-DD')))
                    , XMLElement("TransactionID", gtActiveEbanking.CEB_TRANSACTION_ID)
                     )
      into lxmldata
      from dual;

    return lxmldata;
  end GetDeliveryInfo;

  /**
  *   Noeud : /Envelope/Body/PaymentData
  */
  function GetPaymentData
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLElement("PaymentData"
                    , XMLElement("PaymentType",
                                  case
                                    when PME.C_TYPE_SUPPORT in('50', '51', '56') then 'DD'
                                  else
                                    case (select C_TYPE_CATALOGUE from ACJ_CATALOGUE_DOCUMENT where ACJ_CATALOGUE_DOCUMENT_ID = gtActiveDocument.ACJ_CATALOGUE_DOCUMENT_ID)
                                      when '2' then 'ESR'
                                      when '6' then 'CREDIT'
                                      else 'OTHER'
                                    end
                                  end)
                    , XMLForest(GetFormatedBvrNbr(PME.PME_SBVR) as "ESRCustomerNr")
                    , XMLElement("EBillAccountID"
                               , (select EBP_ACCOUNT
                                    from PAC_EBPP_REFERENCE
                                   where PAC_EBPP_REFERENCE_ID = gtActiveEbanking.PAC_EBPP_REFERENCE_ID)
                                )
                    , XMLElement("BillLanguage",(GetDefAdressLang) )
                    , XMLForest(EXP.EXP_REF_BVR as "ESRReferenceNr")
                    , XMLElement("PaymentDueDate", to_char(exp.EXP_CALCULATED, 'YYYY-MM-DD') )
                    , XMLElement("TotalAmount",
                                  case
                                    when (select C_TYPE_CATALOGUE from ACJ_CATALOGUE_DOCUMENT where ACJ_CATALOGUE_DOCUMENT_ID = gtActiveDocument.ACJ_CATALOGUE_DOCUMENT_ID) not in ('6') then
                                      gtActiveDocument.DOC_TOTAL_AMOUNT_DC
                                    else
                                      gtActiveDocument.DOC_TOTAL_AMOUNT_DC * (-1)
                                  end
                      )
                    , XMLElement("fixAmount", 'No')
                    , XMLElement("Currency"
                               , (select CUR.CURRENCY
                                    from PCS.PC_CURR CUR
                                   where exists(
                                           select 1
                                             from ACS_FINANCIAL_CURRENCY FIN
                                            where FIN.ACS_FINANCIAL_CURRENCY_ID =
                                                                              gtActiveDocument.ACS_FINANCIAL_CURRENCY_ID
                                              and CUR.PC_CURR_ID = FIN.PC_CURR_ID) )
                                )
                     )
      into lxmldata
      from ACS_PAYMENT_METHOD PME
         , ACS_FIN_ACC_S_PAYMENT FAS
         , ACT_EXPIRY EXP
     where EXP.ACT_DOCUMENT_ID = gtActiveDocument.ACT_DOCUMENT_ID
       and EXP.EXP_CALC_NET = 1
       and FAS.ACS_FIN_ACC_S_PAYMENT_ID(+) = gtActiveDocument.ACS_FIN_ACC_S_PAYMENT_ID
       and PME.ACS_PAYMENT_METHOD_ID(+) = FAS.ACS_PAYMENT_METHOD_ID;

    return lxmldata;
  end GetPaymentData;

  /**
  *   Noeud : /Envelope/Body/BillPresentment
  */
  function GetBillPresentment
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLElement("BillPresentment"
                    , XMLForest(null as "URLBillDetails")
                    , XMLElement("BillDetailsType"
                               , case (select C_ECS_BILL_PRESENTMENT from PCS.PC_EXCHANGE_SYSTEM where PC_EXCHANGE_SYSTEM_ID = gtActiveEbanking.PC_EXCHANGE_SYSTEM_ID)
                                   when '00' then 'PDF'
                                   when '01' then 'PDFAppendix'
                                   when '02' then 'PDFSystem'
                                   when '03' then 'URL'
                                 end
                                )
                    , XMLElement("BillDetails", null)
                     )
      into lxmldata
      from dual;

    return lxmldata;
  end GetBillPresentment;

  /**
  *   Noeud : /Envelope/Body/Appendix
  */
  function GetAppendix
    return xmltype
  is
    lxmldata xmltype;
    lvPresentment  PCS.PC_EXCHANGE_SYSTEM.C_ECS_BILL_PRESENTMENT%type;
  begin
    select max(C_ECS_BILL_PRESENTMENT)
    into lvPresentment
    from PCS.PC_EXCHANGE_SYSTEM
    where PC_EXCHANGE_SYSTEM_ID = gtActiveEbanking.PC_EXCHANGE_SYSTEM_ID;
    -- Si le mode de présentation est
    -- 01 : Avec Bill Presentment, PDF intégré dans le XML
    if lvPresentment = '01' then
      select XMLForest(XMLElement("Document"
                                , XMLAttributes('x-application/pdfappendix' as "MimeType")
                                , PCS.PC_ENCODING_FUNCTIONS.EncodeBase64(gtActiveEbanking.CEB_PDF_FILE)
                                 ) as "Appendix"
                      )
        into lxmldata
        from dual;
    end if;

    return lxmldata;
  end GetAppendix;

  function GetDeliveryDate(
    in_document_id in COM_EBANKING.ACT_DOCUMENT_ID%type)
    return DATE
  is
    ld_document DATE;
  begin
    select DOC_DOCUMENT_DATE
      into ld_document
      from ACT_DOCUMENT
     where ACT_DOCUMENT_ID = in_document_id;
    return ld_document;

    exception
      when NO_DATA_FOUND then
        return null;
  end;

END COM_LIB_EBANKING_YB_ACT;
