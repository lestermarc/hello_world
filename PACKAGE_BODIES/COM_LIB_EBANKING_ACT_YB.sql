--------------------------------------------------------
--  DDL for Package Body COM_LIB_EBANKING_ACT_YB
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_LIB_EBANKING_ACT_YB" 
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
function GetYB12_Ext_xml(
  in_document_id IN com_ebanking.act_document_id%TYPE)
  return CLOB
is
  lx_data XMLType;
begin
 lx_data := com_lib_ebanking_act_yb.GetYB12_Ext_XMLType(in_document_id);
  if (lx_data is not null) then
    return '<?xml version="1.0" encoding="UTF-8"?>' ||Chr(10)|| Replace(lx_data.GetClobVal(), 'NULL_VALUE_TO_REPLACE', '');
  end if;
  return null;
end;

function GetYB12_Int_xml(
  in_document_id IN com_ebanking.act_document_id%TYPE)
  return CLOB
is
  lx_data XMLType;
begin
  lx_data := com_lib_ebanking_act_yb.GetYB12_Int_XMLType(in_document_id);
  if (lx_data is not null) then
    return '<?xml version="1.0" encoding="UTF-8"?>' ||Chr(10)|| Replace(lx_data.GetClobVal(), 'NULL_VALUE_TO_REPLACE', '');
  end if;
  return null;
end;

function GetYB12_Ext_XMLType(in_document_id IN com_ebanking.act_document_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLElement("Envelope",
      XMLAttributes(
        'http://www.w3.org/2001/XMLSchema-instance' as "xmlns:xsi",
        'ybInvoice_V1.2.xsd' as "xsi:noNamespaceSchemaLocation",
        'NULL_VALUE_TO_REPLACE' as "type"
      ),
      XMLElement("Header",
        XMLElement("From",
          (select ECS_ISSUING_NAME from PCS.PC_EXCHANGE_SYSTEM
           where PC_EXCHANGE_SYSTEM_ID = CEB.PC_EXCHANGE_SYSTEM_ID)
        ),
        XMLElement("To", 'IPECeBILLServer'),
        XMLElement("UseCase", 'CreateybInvoice'),
        XMLElement("SessionID", '1'),
        XMLElement("Version", '1.2'),
        XMLElement("Status", '0')
      ),
      XMLElement("Body",
        com_lib_ebanking_act_yb_xml.GetDeliveryInfo(in_document_id),
        com_lib_ebanking_act_yb_xml.GetYB12Ext_bill(in_document_id),
        com_lib_ebanking_act_yb_xml.GetPaymentData(in_document_id),-- à corriger en fonction du solde du document (lettrage partiel)
        com_lib_ebanking_act_yb_xml.GetBillPresentment(in_document_id),
        com_lib_ebanking_act_yb_xml.GetAppendix(in_document_id)
      )
    ) into lx_data
  from COM_EBANKING CEB
  where CEB.ACT_DOCUMENT_ID = in_document_id;

  return lx_data;

  exception
    when OTHERS then
      return null;
end;

function GetYB12_Int_XMLType(
  in_document_id IN com_ebanking.act_document_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLElement("Envelope",
      XMLAttributes(
        'http://www.w3.org/2001/XMLSchema-instance' as "xmlns:xsi",
        'ybInvoice_V1.2.xsd' as "xsi:noNamespaceSchemaLocation",
        'NULL_VALUE_TO_REPLACE' as "type"
      ),
      XMLElement("Header",
        XMLElement("From",
          (select ECS_ISSUING_NAME from PCS.PC_EXCHANGE_SYSTEM
           where PC_EXCHANGE_SYSTEM_ID = CEB.PC_EXCHANGE_SYSTEM_ID)
        ),
        XMLElement("To", 'IPECeBILLServer'),
        XMLElement("UseCase", 'CreateybInvoice'),
        XMLElement("SessionID", '1'),
        XMLElement("Version", '1.2'),
        XMLElement("Status", '0')
      ),
      XMLElement("Body",
        com_lib_ebanking_act_yb_xml.GetDeliveryInfo(in_document_id),
        com_lib_ebanking_act_yb_xml.GetPaymentData(in_document_id),
        com_lib_ebanking_act_yb_xml.GetBillPresentment(in_document_id),
        com_lib_ebanking_act_yb_xml.GetAppendix(in_document_id)
      )
    ) into lx_data
  from COM_EBANKING CEB
  where CEB.ACT_DOCUMENT_ID = in_document_id;

  return lx_data;

  exception
    when OTHERS then
      return null;
end;

END COM_LIB_EBANKING_ACT_YB;
