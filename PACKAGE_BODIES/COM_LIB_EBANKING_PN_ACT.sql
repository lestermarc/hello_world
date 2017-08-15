--------------------------------------------------------
--  DDL for Package Body COM_LIB_EBANKING_PN_ACT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_LIB_EBANKING_PN_ACT" 
/**
 * Générateur d'e-factures de document finance, spécialisé pour PayNet.
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

  gtDocPartnerId   ACT_PART_IMPUTATION.PAC_CUSTOM_PARTNER_ID%type;
  gtPartnerAdr     PAC_ADDRESS.ADD_ADDRESS1%type;
  gtDocFinRefId    ACT_PART_IMPUTATION.PAC_FINANCIAL_REFERENCE_ID%type;
  gtActiveDocument ACT_DOCUMENT%rowtype;
  gtActiveEbanking COM_EBANKING%rowtype;
  gtActiveExchange PCS.PC_EXCHANGE_SYSTEM%rowtype;

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

    select *
      into gtActiveExchange
      from PCS.PC_EXCHANGE_SYSTEM
     where PC_EXCHANGE_SYSTEM_ID = gtActiveEbanking.PC_EXCHANGE_SYSTEM_ID;

    select PIM.PAC_CUSTOM_PARTNER_ID
         , PIM.PAC_FINANCIAL_REFERENCE_ID
         , ADR.ADD_ADDRESS1
      into gtDocpartnerId
         , gtDocFinRefId
         , gtPartnerAdr
      from ACT_PART_IMPUTATION PIM, PAC_ADDRESS ADR, PAC_PERSON PER
     where PIM.ACT_DOCUMENT_ID = gtActiveDocument.ACT_DOCUMENT_ID
       and PER.PAC_PERSON_ID = PIM.PAC_CUSTOM_PARTNER_ID
       and ADR.PAC_PERSON_ID(+) = PER.PAC_PERSON_ID
       and ADD_PRINCIPAL(+) = 1;

  end InitIternals;

  /**
  * Fct principale de la génération XML de PN
  */
  function GetPN2003A_Ext(iActDocumentId in COM_EBANKING.ACT_DOCUMENT_ID%type)
    return xmltype
  is
  begin
    return COM_LIB_EBANKING_PN_ACT.GetPN2003A_Int(iActDocumentId);
  end GetPN2003A_Ext;

  function GetPN2003AClob_Ext(iActDocumentId in COM_EBANKING.ACT_DOCUMENT_ID%type)
    return clob
  is
  begin
    return COM_LIB_EBANKING_PN_ACT.GetPN2003A_Ext(iActDocumentId).GetClobVal();
  end GetPN2003AClob_Ext;

  function GetPN2003AClob_Int(iActDocumentId in COM_EBANKING.ACT_DOCUMENT_ID%type)
    return clob
  is
    lxmldata      xmltype;
    lclbdata      clob;
  begin
    lxmldata  := COM_LIB_EBANKING_PN_ACT.GetPN2003A_Int(iActDocumentId);
    if lxmldata is not null then
      lclbdata  := pc_jutils.get_XmlPrologDefault || chr(10) || lxmldata.GetClobVal();
--       lclbdata  := '<!DOCTYPE XML-FSCM-INVOICE-2003A SYSTEM "XML-FSCM-INVOICE-2003A.DTD">' || lxmldata.GetClobVal();

      -- Remplacer la balise Confirmation-Flag selon les normes PayNet
      select replace(lclbdata, '<Confirmation-Flag></Confirmation-Flag>', '<Confirmation-Flag/>')
        into lclbdata
        from dual;
    end if;
    return lclbdata;
  end GetPN2003AClob_Int;

  function GetPN2003A_Int(iActDocumentId in COM_EBANKING.ACT_DOCUMENT_ID%type)
    return xmltype
  is
    lxmldata xmltype;
  begin
    begin
      InitIternals(iActDocumentId);

      select XMLElement("XML-FSCM-INVOICE-2003A"
                      , XMLElement("INTERCHANGE"
                                 , XMLElement("IC-SENDER", XMLElement("Pid", gtActiveExchange.ECS_ACCOUNT) )
                                 , XMLElement("IC-RECEIVER", XMLElement("Pid", '41010106799303734') )
                                 , XMLElement("IC-Ref", gtActiveEbanking.CEB_TRANSACTION_ID)
                                  )
                      , XMLElement("INVOICE"
                                 , XMLAttributes(case (select C_TYPE_CATALOGUE
                                                         from ACJ_CATALOGUE_DOCUMENT
                                                        where ACJ_CATALOGUE_DOCUMENT_ID =
                                                                              gtActiveDocument.ACJ_CATALOGUE_DOCUMENT_ID)
                                                   when '6' then 'EGS'
                                                   else 'EFD'
                                                 end as "Type"
                                                )
                                 , GetInvoice
                                  )
                       )
        into lxmldata
        from dual;

      return lxmldata;
    exception
      when others then
        return null;
    end;
  end GetPN2003A_Int;

  /**
  *   Noeud : /XML-FSCM-INVOICE-2003A/INVOICE/
  */
  function GetInvoice
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLConcat(GetHeader, GetLineItem, GetSummary)
      into lxmldata
      from dual;

    return lxmldata;
  end GetInvoice;

  /**
  *   Noeud : /XML-FSCM-INVOICE-2003A/INVOICE/HEADER
  */
  function GetHeader
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLElement
             ("HEADER"
            , XMLElement("FUNCTION-FLAGS", XMLElement("Confirmation-Flag") )
            , XMLElement("MESSAGE-REFERENCE"
                        , XMLElement("REFERENCE-DATE"
                                    , XMLElement("Reference-No", gtActiveDocument.DOC_NUMBER)
                                    , XMLElement("Date"
                                                , XMLAttributes('CCYYMMDD' as "Format")
                                                , to_char(trunc(sysdate), 'YYYYMMDD')
                                                )
                                    )
                        )
            , XMLElement("PRINT-DATE"
                       , XMLElement("Date"
                                  , XMLAttributes('CCYYMMDD' as "Format")
                                  , (to_char(gtActiveDocument.DOC_DOCUMENT_DATE, 'YYYY-MM-DD') )
                                   )
                        )
            , XMLElement("DELIVERY-DATE"
                       , XMLElement("Date"
                                  , XMLAttributes('CCYYMMDD' as "Format")
                                  , (to_char(gtActiveDocument.DOC_DOCUMENT_DATE, 'YYYY-MM-DD') )
                                   )
                        )
            , XMLElement("REFERENCE"
                       , XMLElement("INVOICE-REFERENCE"
                                  , XMLElement("REFERENCE-DATE"
                                             , XMLElement("Reference-No", gtActiveDocument.DOC_NUMBER)
                                             , XMLElement("Date"
                                                        , XMLAttributes('CCYYMMDD' as "Format")
                                                        , (to_char(gtActiveDocument.DOC_DOCUMENT_DATE, 'YYYY-MM-DD') )
                                                         )
                                              )
                                   )
                       , XMLElement("OTHER-REFERENCE"
                                  , XMLAttributes('ACL' as "Type")
                                  , XMLElement("REFERENCE-DATE"
                                             , XMLElement("Reference-No", gtActiveDocument.DOC_NUMBER)
                                             , XMLElement("Date"
                                                        , XMLAttributes('CCYYMMDD' as "Format")
                                                        , (to_char(gtActiveDocument.DOC_DOCUMENT_DATE, 'YYYY-MM-DD') )
                                                         )
                                              )
                                   )
--                       , vXml_OtherReference
                        )
            , XMLElement("BILLER"
                       , XMLElement("Tax-No", (select COM_VATNO from PCS.PC_COMP where PC_COMP_ID = PCS.PC_INIT_SESSION.GetCompanyId) )
                       , XMLElement("Doc-Reference" , XMLAttributes('ESR-NEU' as "Type") , (select EXP_REF_BVR from ACT_EXPIRY where ACT_DOCUMENT_ID = gtActiveDocument.ACT_DOCUMENT_ID and EXP_CALC_NET = 1))
                       , XMLElement("PARTY-ID", XMLElement("Pid", gtActiveExchange.ECS_ACCOUNT) )
                       , XMLElement("NAME-ADDRESS"
                                  , XMLAttributes('COM' as "Format")
                                  , XMLForest(XMLForest(substr(gtActiveExchange.ECS_ISSUING_NAME,(0 * 35) + 1, 35) as "Line-35"
                                                      , substr(gtActiveExchange.ECS_ISSUING_NAME,(1 * 35) + 1, 35) as "Line-35"
                                                      , substr(gtActiveExchange.ECS_ISSUING_NAME,(2 * 35) + 1, 35) as "Line-35"
                                                      , substr(gtActiveExchange.ECS_ISSUING_NAME,(3 * 35) + 1, 35) as "Line-35"
                                                      , substr(gtActiveExchange.ECS_ISSUING_NAME,(4 * 35) + 1, 35) as "Line-35"
                                                      ) as "NAME"
                                             )
                                  , XMLForest(XMLForest(substr(gtActiveExchange.ECS_ADDRESS,(0 * 35) + 1, 35) as "Line-35"
                                                      , substr(gtActiveExchange.ECS_ADDRESS,(1 * 35) + 1, 35) as "Line-35"
                                                      , substr(gtActiveExchange.ECS_ADDRESS,(2 * 35) + 1, 35) as "Line-35"
                                                      , substr(gtActiveExchange.ECS_ADDRESS,(3 * 35) + 1, 35) as "Line-35"
                                                      , substr(gtActiveExchange.ECS_ADDRESS,(4 * 35) + 1, 35) as "Line-35"
                                                       ) as "STREET"
                                             )
                                  , XMLForest(gtActiveExchange.ECS_CITY as "City"
                                            , gtActiveExchange.ECS_ZIPCODE as "Zip"
                                            , (select CNTID from PCS.PC_CNTRY where PC_CNTRY_ID(+) = gtActiveExchange.PC_CNTRY_ID) as "Country"
                                             )
                                   )
                         , XMLElement("BANK-INFO"
                                    , XMLElement("Acct-No"
                                               , case
                                                   when PME.C_TYPE_SUPPORT = '35' then PME.PME_SBVR
                                                   when PME.C_TYPE_SUPPORT in('50', '51', '56') then (select FRE.FRE_ACCOUNT_NUMBER
                                                                                                      from PAC_FINANCIAL_REFERENCE FRE
                                                                                                       where FRE.PAC_FINANCIAL_REFERENCE_ID(+) =  gtDocFinRefId)
                                                  end
                                                 )
                                    , XMLElement("BankId"
                                               , XMLAttributes('BCNr-int' as "Type", 'CH' as "Country")
                                               , case
                                                   when PME.C_TYPE_SUPPORT = '35' then '001996'
                                                   when PME.C_TYPE_SUPPORT in('50', '51', '56') then (select case FRE.C_TYPE_REFERENCE
                                                                                                               when '1' then BAN.BAN_CLEAR
                                                                                                               when '5' then BAN.BAN_SWIFT
                                                                                                             end BANK
                                                                                                       from PAC_FINANCIAL_REFERENCE FRE
                                                                                                          , PCS.PC_BANK BAN
                                                                                                       where FRE.PAC_FINANCIAL_REFERENCE_ID(+) =  gtDocFinRefId
                                                                                                         and BAN.PC_BANK_ID(+) = FRE.PC_BANK_ID
                                                                                                      )
                                                end
                                                )
                                       )
                           )
            , XMLElement("PAYER"
                       , XMLElement("Tax-No", (select THI_NO_TVA
                                                 from PAC_THIRD THI
                                                where THI.PAC_THIRD_ID = gtDocPartnerId) )
                       , XMLElement("PARTY-ID"
                                  , XMLElement("Pid"
                                             , (select EBP_ACCOUNT
                                                  from PAC_EBPP_REFERENCE
                                                 where PAC_EBPP_REFERENCE_ID = gtActiveEbanking.PAC_EBPP_REFERENCE_ID)
                                              )
                                   )
                       , XMLElement("NAME-ADDRESS"
                                  , XMLAttributes('COM' as "Format")
                                  , XMLForest(XMLForest( (select substr(PER_NAME,(0 * 35) + 1, 35)
                                                            from PAC_PERSON
                                                           where PAC_PERSON_ID = gtDocPartnerId) as "Line-35"
                                                      , (select substr(PER_NAME,(1 * 35) + 1, 35)
                                                           from PAC_PERSON
                                                          where PAC_PERSON_ID = gtDocPartnerId) as "Line-35"
                                                       ) as "NAME"
                                             )
                                  , XMLForest(XMLForest(substr(gtPartnerAdr,(0 * 35) + 1, 35) as "Line-35"
                                                      , substr(gtPartnerAdr,(1 * 35) + 1, 35) as "Line-35"
                                                      , substr(gtPartnerAdr,(2 * 35) + 1, 35) as "Line-35"
                                                      , substr(gtPartnerAdr,(3 * 35) + 1, 35) as "Line-35"
                                                      , substr(gtPartnerAdr,(4 * 35) + 1, 35) as "Line-35"
                                                      , substr(gtPartnerAdr,(5 * 35) + 1, 35) as "Line-35"
                                                      , substr(gtPartnerAdr,(6 * 35) + 1, 35) as "Line-35"
                                                      , substr(gtPartnerAdr,(7 * 35) + 1, 35) as "Line-35"
                                                       ) as "STREET"
                                             )
                                  , XMLForest( (select substr(max(ADD_CITY), 1, 35)
                                                  from PAC_ADDRESS
                                                 where PAC_PERSON_ID = gtDocPartnerId
                                                   and ADD_PRINCIPAL = 1) as "City"
                                            , (select substr(max(ADD_ZIPCODE), 1, 9)
                                                 from PAC_ADDRESS
                                                where PAC_PERSON_ID = gtDocPartnerId
                                                  and ADD_PRINCIPAL = 1) as "Zip"
                                            , (select nvl(max(CNTID),'CH')
                                                 from PCS.PC_CNTRY cnt, PAC_ADDRESS ADR
                                                 where PAC_PERSON_ID = gtDocPartnerId
                                                   and ADD_PRINCIPAL = 1
                                                   and CNT.PC_CNTRY_ID = ADR.PC_CNTRY_ID) as "Country"
                                             )
                                   )
                        )
             )
      into lxmldata
      from ACS_FIN_ACC_S_PAYMENT FAS
         , ACS_PAYMENT_METHOD PME
     where FAS.ACS_FIN_ACC_S_PAYMENT_ID(+) = gtActiveDocument.ACS_FIN_ACC_S_PAYMENT_ID
       and PME.ACS_PAYMENT_METHOD_ID(+) = FAS.ACS_PAYMENT_METHOD_ID;

    return lxmldata;
  end GetHeader;

  /**
  *   Noeud  /XML-FSCM-INVOICE-2003A/INVOICE/LINEITEM
  */
  function GetLineItem
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLElement ("LINE-ITEM"
                     , XMLAttributes(gtActiveDocument.DOC_NUMBER as "Line-Number")
                       )
      into lxmldata
      from dual;

    return lxmldata;
  end GetLineItem;

  /**
  *   Noeud  /XML-FSCM-INVOICE-2003A/INVOICE/SUMMARY
  */
  function GetSummary
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLElement
             ("SUMMARY"
            , XMLElement
                ("INVOICE-AMOUNT"
               , XMLAttributes('25' as "Print-Status")
               , XMLElement
                     ("Amount"
                    , XMLAttributes( (select CUR.CURRENCY
                                        from PCS.PC_CURR CUR
                                       where exists(
                                               select 1
                                                 from ACS_FINANCIAL_CURRENCY FIN
                                                where FIN.ACS_FINANCIAL_CURRENCY_ID =
                                                                              gtActiveDocument.ACS_FINANCIAL_CURRENCY_ID
                                                  and CUR.PC_CURR_ID = FIN.PC_CURR_ID) ) as "Currency"
                                   )
                    , gtActiveDocument.DOC_TOTAL_AMOUNT_DC
                     )
                )
            , XMLElement
                ("PAYMENT-TERMS"
               , XMLElement
                           ("BASIC"
                          , XMLAttributes(case (select PME.C_TYPE_SUPPORT
                                                  from ACS_PAYMENT_METHOD PME
                                                     , ACS_FIN_ACC_S_PAYMENT FAS
                                                 where FAS.ACS_FIN_ACC_S_PAYMENT_ID(+) =
                                                                               gtActiveDocument.ACS_FIN_ACC_S_PAYMENT_ID
                                                   and PME.ACS_PAYMENT_METHOD_ID(+) = FAS.ACS_PAYMENT_METHOD_ID)
                                            when('50') then 'NPY'
                                            when('51') then 'NPY'
                                            when('56') then 'NPY'
                                            else case (select C_BVR_GENERATION_METHOD
                                                         from PAC_CUSTOM_PARTNER
                                                        where PAC_CUSTOM_PARTNER_ID = gtDocpartnerId)
                                            when '02' then 'ESP'
                                            when '03' then 'ESR'
                                          end
                                          end as "Payment-Type"
                                        , '1' as "Terms-Type"
                                         )
                          , XMLElement("TERMS"
                                     , XMLElement("Date"
                                                , (select to_char(EXP_CALCULATED, 'YYYY-MM-DD')
                                                     from ACT_EXPIRY
                                                    where ACT_DOCUMENT_ID = gtActiveDocument.ACT_DOCUMENT_ID
                                                      and EXP_CALC_NET = 1)
                                                 )
                                      )
                           )
                )
            , GetContainer
             )
      into lxmldata
      from dual;

    return lxmldata;
  exception
    when others then
      return null;
  end GetSummary;

  /**
  *   Noeud  /XML-FSCM-INVOICE-2003A/INVOICE/SUMMARY/Back-Pack-Container
  */
  function GetContainer
    return xmltype
  is
    lxmldata xmltype;
  begin
    --PCS.PC_ENCODING_FUNCTIONS.EncodeBase64(CEB_PDF_FILE)
    -- Si le mode de présentation est
    -- 01 : Avec Bill Presentment, PDF intégré dans le XML
    if gtActiveExchange.C_ECS_BILL_PRESENTMENT = '01' then
      select XMLForest
               (case
                  when gtActiveEbanking.CEB_PDF_FILE is not null then
                    PCS.PC_ENCODING_FUNCTIONS.EncodeBase64(gtActiveEbanking.CEB_PDF_FILE)
                  else null
                end as "Back-Pack-Container"
               )
        into lxmldata
        from dual;
    end if;

    return lxmldata;
  end GetContainer;

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

END COM_LIB_EBANKING_PN_ACT;
