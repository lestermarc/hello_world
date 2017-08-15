--------------------------------------------------------
--  DDL for Package Body COM_LIB_EBANKING_ACT_PN
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_LIB_EBANKING_ACT_PN" 
/**
 * Gestion des documents e-factures de document finance.
 * Spécialisation : PayNet.
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

function GetPN2003A_Ext_XMLType(
  in_document_id IN com_ebanking.act_document_id%TYPE)
  return XMLTYPE
is
begin
  return com_lib_ebanking_act_pn.GetPN2003A_Int_XMLType(in_document_id);
end;

function GetPN2003A_Ext_xml(
  in_document_id IN com_ebanking.act_document_id%TYPE)
  return CLOB
is
begin
  return COM_LIB_EBANKING_ACT_PN.GetPN2003A_int_xml(in_document_id);
end;

function GetPN2003A_Int_xml(
  in_document_id IN com_ebanking.act_document_id%TYPE)
  return CLOB
is
  lxmldata XMLType;
  lclbdata CLOB;
begin
  lxmldata := com_lib_ebanking_act_pn.GetPN2003A_Int_XMLType(in_document_id);
  if (lxmldata is not null) then
    lclbdata  := '<!DOCTYPE XML-FSCM-INVOICE-2003A SYSTEM "XML-FSCM-INVOICE-2003A.DTD">' || lxmldata.GetClobVal();

    -- Remplacer la balise Confirmation-Flag selon les normes PayNet
    lclbdata := Replace(lclbdata, '<Confirmation-Flag></Confirmation-Flag>', '<Confirmation-Flag/>');
    -- Remplacer les entités &pos (apostrophe) qui ne sont pas comprises par le parser de FTX / Paynet
    lclbdata := Replace(lclbdata, '&'||'apos;', '''');
  end if;
  return lclbdata;
end;

function GetPN2003A_Int_XMLType(
  in_document_id IN com_ebanking.act_document_id%TYPE)
  return XMLType
is
  lxmldata XMLType;
begin

  /*  attention : le tag IC-RECEIVER doit avoir la valeur 41010106799303734 (Six-paynet), ne pas modifier cette valeur */

  select
    XMLElement("XML-FSCM-INVOICE-2003A",
      XMLElement("INTERCHANGE",
        XMLElement("IC-SENDER",
          XMLElement("Pid", ECS.ECS_ACCOUNT)
        ),
        XMLElement("IC-RECEIVER",
          XMLElement("Pid", '41010106799303734')
        ),
        XMLElement("IC-Ref", CEB.CEB_TRANSACTION_ID)
      ),
      XMLElement("INVOICE",
        XMLAttributes(
          case (CAT.C_TYPE_CATALOGUE)
            when '6' then 'EGS'
            else 'EFD'
          end as "Type"),
        com_lib_ebanking_act_pn_xml.GetInvoice(in_document_id)
      )
    ) into lxmldata
  from
    COM_EBANKING CEB,
    ACT_DOCUMENT DOC,
    ACJ_CATALOGUE_DOCUMENT CAT,
    PCS.PC_EXCHANGE_SYSTEM ECS
  where
    CEB.ACT_DOCUMENT_ID = in_document_id and
    CEB.PC_EXCHANGE_SYSTEM_ID = ECS.PC_EXCHANGE_SYSTEM_ID and
    CEB.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID and
    DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID;

  return lxmldata;

  exception
    when OTHERS then
      return null;
end;

END COM_LIB_EBANKING_ACT_PN;
