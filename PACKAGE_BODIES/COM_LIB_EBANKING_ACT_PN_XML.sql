--------------------------------------------------------
--  DDL for Package Body COM_LIB_EBANKING_ACT_PN_XML
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_LIB_EBANKING_ACT_PN_XML" 
/**
 * Générateur de document Xml pour e-factures de document finance.
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

/**
 *   Noeud : /XML-FSCM-INVOICE-2003A/INVOICE/
 */
function GetInvoice(
  in_document_id IN act_document.act_document_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLConcat(
      com_lib_ebanking_act_pn_xml.GetHeader(in_document_id),
      com_lib_ebanking_act_pn_xml.GetLineItem(in_document_id),
      com_lib_ebanking_act_pn_xml.GetSummary(in_document_id)
    )into lx_data
  from dual;

  return lx_data;
end;

function getPayer(
  in_document_id IN act_document.act_document_id%TYPE)
  return XMLType
is
  lx_data XMLType;
  tpl_ebp pac_ebpp_reference%ROWTYPE;
begin
  select ebp.*
    into tpl_ebp
    from pac_ebpp_reference ebp
       , com_ebanking ceb
   where ceb.act_document_id = in_document_id
     and ceb.pac_ebpp_reference_id = ebp.pac_ebpp_reference_id;

  if (tpl_ebp.ebp_own_reference = 1) then
    select
      XMLElement("PAYER",
        XMLElement("PARTY-ID",
          XMLElement("Pid", V.EBP_ACCOUNT)
        ),
        XMLElement("NAME-ADDRESS",
          XMLAttributes('COM' as "Format"),
          XMLForest(
            XMLForest(
              Substr(V.PER_NAME,(0 * 35) + 1, 35) as "Line-35",
              Substr(V.PER_NAME,(1 * 35) + 1, 35) as "Line-35"
            ) as "NAME"
          ),
          XMLForest(
            XMLForest(
              Substr(V.ADD_ADDRESS1,(0 * 35) + 1, 35) as "Line-35",
              Substr(V.ADD_ADDRESS1,(1 * 35) + 1, 35) as "Line-35",
              Substr(V.ADD_ADDRESS1,(2 * 35) + 1, 35) as "Line-35",
              Substr(V.ADD_ADDRESS1,(3 * 35) + 1, 35) as "Line-35",
              Substr(V.ADD_ADDRESS1,(4 * 35) + 1, 35) as "Line-35",
              Substr(V.ADD_ADDRESS1,(5 * 35) + 1, 35) as "Line-35",
              Substr(V.ADD_ADDRESS1,(6 * 35) + 1, 35) as "Line-35",
              Substr(V.ADD_ADDRESS1,(7 * 35) + 1, 35) as "Line-35"
            ) as "STREET"
          ),
          XMLForest(
            Substr(V.ADD_CITY, 1, 35) as "City",
            Substr(V.ADD_ZIPCODE, 1, 9) as "Zip",
            Nvl(V.CNTID, 'CH') as "Country"
          )
        )
      ) into lx_data
    from (
      select
        PER.PER_NAME, PER_FORENAME, EBP.EBP_ACCOUNT, THI.THI_NO_TVA, ADDR.*, CNT.CNTID
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
      ) v
    where rownum = 1;
  else
    select
      XMLElement("PAYER",
        XMLElement("PARTY-ID",
          XMLElement("Pid", V.EBP_ACCOUNT)
        ),
        XMLElement("NAME-ADDRESS",
          XMLAttributes('COM' as "Format"),
          XMLForest(
            XMLForest(
              Substr(V.PER_NAME,(0 * 35) + 1, 35) as "Line-35",
              Substr(V.PER_NAME,(1 * 35) + 1, 35) as "Line-35"
            ) as "NAME"
          ),
          XMLForest(
            XMLForest(
              Substr(V.ADD_ADDRESS1,(0 * 35) + 1, 35) as "Line-35",
              Substr(V.ADD_ADDRESS1,(1 * 35) + 1, 35) as "Line-35",
              Substr(V.ADD_ADDRESS1,(2 * 35) + 1, 35) as "Line-35",
              Substr(V.ADD_ADDRESS1,(3 * 35) + 1, 35) as "Line-35",
              Substr(V.ADD_ADDRESS1,(4 * 35) + 1, 35) as "Line-35",
              Substr(V.ADD_ADDRESS1,(5 * 35) + 1, 35) as "Line-35",
              Substr(V.ADD_ADDRESS1,(6 * 35) + 1, 35) as "Line-35",
              Substr(V.ADD_ADDRESS1,(7 * 35) + 1, 35) as "Line-35"
            ) as "STREET"
          ),
          XMLForest(
            Substr(V.ADD_CITY, 1, 35) as "City",
            Substr(V.ADD_ZIPCODE, 1, 9) as "Zip",
            Nvl(V.CNTID, 'CH') as "Country"
          )
        )
      ) into lx_data
    from (
      select
        PER.PER_NAME, PER_FORENAME, EBP2.EBP_ACCOUNT, THI.THI_NO_TVA, ADDR.*, CNT.CNTID
      from
        COM_EBANKING CEB,
        PAC_EBPP_REFERENCE EBP1,
        PAC_EBPP_REFERENCE EBP2,
        PAC_CUSTOM_PARTNER CUS,
        PAC_ADDRESS ADDR,
        PAC_PERSON PER,
        PAC_THIRD THI,
        PCS.PC_CNTRY CNT
      where
        CEB.ACT_DOCUMENT_ID = in_document_id and
        CEB.PAC_EBPP_REFERENCE_ID = EBP1.PAC_EBPP_REFERENCE_ID and
        EBP1.PAC_PAC_EBPP_REFERENCE_ID = EBP2.PAC_EBPP_REFERENCE_ID and
        EBP2.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID and
        CUS.PAC_CUSTOM_PARTNER_ID = ADDR.PAC_PERSON_ID and
        CUS.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID and
        PER.PAC_PERSON_ID = THI.PAC_THIRD_ID and
        ADDR.PC_CNTRY_ID = CNT.PC_CNTRY_ID
      order by
        case when ADDR.DIC_ADDRESS_TYPE_ID = 'Fac' then 0 else 1 end,
        ADDR.ADD_PRINCIPAL
      ) v
    where rownum = 1;
  end if;

  return lx_data;
end;

function getBiller(
  in_document_id IN act_document.act_document_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLElement("BILLER",
      XMLElement("Tax-No", COM.COM_VATNO),
      XMLElement("Doc-Reference",
        XMLAttributes('ESR-NEU' as "Type"),
        EXP.EXP_REF_BVR
      ),
      XMLElement("PARTY-ID",
        XMLElement("Pid", ECS.ECS_ACCOUNT)
      ),
      XMLElement("NAME-ADDRESS",
        XMLAttributes('COM' as "Format"),
        XMLForest(
          XMLForest(
            Substr(ECS.ECS_ISSUING_NAME,(0 * 35) + 1, 35) as "Line-35",
            Substr(ECS.ECS_ISSUING_NAME,(1 * 35) + 1, 35) as "Line-35",
            Substr(ECS.ECS_ISSUING_NAME,(2 * 35) + 1, 35) as "Line-35",
            Substr(ECS.ECS_ISSUING_NAME,(3 * 35) + 1, 35) as "Line-35",
            Substr(ECS.ECS_ISSUING_NAME,(4 * 35) + 1, 35) as "Line-35"
          ) as "NAME"
        ),
        XMLForest(
          XMLForest(
            Substr(ECS.ECS_ADDRESS,(0 * 35) + 1, 35) as "Line-35",
            Substr(ECS.ECS_ADDRESS,(1 * 35) + 1, 35) as "Line-35",
            Substr(ECS.ECS_ADDRESS,(2 * 35) + 1, 35) as "Line-35",
            Substr(ECS.ECS_ADDRESS,(3 * 35) + 1, 35) as "Line-35",
            Substr(ECS.ECS_ADDRESS,(4 * 35) + 1, 35) as "Line-35"
          ) as "STREET"
        ),
        XMLForest(
          ECS.ECS_CITY as "City",
          ECS.ECS_ZIPCODE as "Zip",
          CNT.CNTID as "Country"
        )
      ),
      XMLElement("BANK-INFO",
        XMLElement("Acct-No",
          case
            when PME.C_TYPE_SUPPORT = '35' then PME.PME_SBVR
            when PME.C_TYPE_SUPPORT in ('50', '51', '56') then FRE.FRE_ACCOUNT_NUMBER
          end
        ),
        XMLElement("BankId",
          XMLAttributes(
            'BCNr-nat' as "Type",
            'CH' as "Country"
          ),
          case
           -- BVR pour la poste
            when PME.C_TYPE_SUPPORT = '35' and PME.PME_BANK_SBVR is null then '001996'
           -- BVR pour la banque (BVRB)
            when PME.C_TYPE_SUPPORT = '35' and PME.PME_BANK_SBVR is not null then ban2.ban_clear
           -- Banque
            when PME.C_TYPE_SUPPORT in ('50', '51', '56') then
              case
                when FRE.C_TYPE_REFERENCE = '1' then BAN1.BAN_CLEAR
                when FRE.C_TYPE_REFERENCE = '5' then BAN1.BAN_SWIFT
              end
          end
        )
      )
    ) into lx_data
  from
    ACT_DOCUMENT DOC,
    ACT_PART_IMPUTATION PAR,
    COM_EBANKING CEB,
    ACS_FIN_ACC_S_PAYMENT FAS,
    ACS_PAYMENT_METHOD PME,
    ACT_EXPIRY EXP,
    PAC_FINANCIAL_REFERENCE FRE,
    acs_financial_account fin,
    PCS.PC_EXCHANGE_SYSTEM ECS,
    pcs.pc_cntry cnt,
    pcs.pc_comp com,
    pcs.pc_bank ban1,
    pcs.pc_bank ban2
  where
    ceb.act_document_id = in_document_id and
    ceb.act_document_id = doc.act_document_id and
    doc.act_document_id = par.act_document_id and
    par.pac_financial_reference_id = fre.pac_financial_reference_id(+) and
    fre.pc_bank_id = ban1.pc_bank_id(+) and
    doc.act_document_id = exp.act_document_id and
    exp.exp_calc_net = 1 and
    exp.acs_fin_acc_s_payment_id = fas.acs_fin_acc_s_payment_id(+) and
    fas.acs_payment_method_id = pme.acs_payment_method_id(+) and
    fas.acs_financial_account_id = fin.acs_financial_account_id (+) and
    fin.pc_bank_id = ban2.pc_bank_id (+) and
    -- société
    com.pc_comp_id = pcs.PC_I_LIB_SESSION.getcompanyid and
    -- système d'échange de données
    ceb.pc_exchange_system_id = ecs.pc_exchange_system_id and
    ecs.pc_cntry_id = cnt.pc_cntry_id(+);

  return lx_data;
end;

function getDeliveryParty(
  in_document_id IN act_document.act_document_id%TYPE)
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

  if (tpl_ebp.ebp_own_reference = 0) then
    select
      XMLElement("DELIVERY-PARTY",
        XMLElement("NAME-ADDRESS",
          XMLAttributes('COM' as "Format"),
          XMLForest(
            XMLForest(
              Substr(V.PER_NAME,(0 * 35) + 1, 35) as "Line-35",
              Substr(V.PER_NAME,(1 * 35) + 1, 35) as "Line-35"
            ) as "NAME"
          ),
          XMLForest(
            XMLForest(
              Substr(V.add_address1,(0 * 35) + 1, 35) as "Line-35",
              Substr(V.add_address1,(1 * 35) + 1, 35) as "Line-35",
              Substr(V.add_address1,(2 * 35) + 1, 35) as "Line-35",
              Substr(V.add_address1,(3 * 35) + 1, 35) as "Line-35",
              Substr(V.add_address1,(4 * 35) + 1, 35) as "Line-35",
              Substr(V.add_address1,(5 * 35) + 1, 35) as "Line-35",
              Substr(V.add_address1,(6 * 35) + 1, 35) as "Line-35",
              Substr(V.add_address1,(7 * 35) + 1, 35) as "Line-35"
            ) as "STREET"
          ),
          XMLForest(
            Substr(V.ADD_CITY, 1, 35) as "City",
            Substr(V.ADD_ZIPCODE, 1, 9) as "Zip",
            Nvl(V.CNTID, 'CH') as "Country"
          )
        )
      ) into lx_data
    from (
      select
        PER.PER_NAME, PER_FORENAME, EBP.EBP_ACCOUNT, THI.THI_NO_TVA, ADDR.*, CNT.CNTID
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
  end if;

  return lx_data;
end;

/**
 *   Noeud : /XML-FSCM-INVOICE-2003A/INVOICE/HEADER
 */
function GetHeader(
  in_document_id IN act_document.act_document_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLElement("HEADER",
      XMLElement("FUNCTION-FLAGS",
        XMLElement("Confirmation-Flag")
      ),
      XMLElement("MESSAGE-REFERENCE",
        XMLElement("REFERENCE-DATE",
          XMLElement("Reference-No", PAR.PAR_DOCUMENT),
          XMLElement("Date",
            XMLAttributes('CCYYMMDD' as "Format"),
            to_char(trunc(sysdate), 'YYYYMMDD')
          )
        )
      ),
      XMLElement("PRINT-DATE",
        XMLElement("Date",
          XMLAttributes('CCYYMMDD' as "Format"),
          to_char(doc.DOC_DOCUMENT_DATE, 'YYYYMMDD')
        )
      ),
      XMLElement("DELIVERY-DATE",
        XMLElement("Date",
          XMLAttributes('CCYYMMDD' as "Format"),
          to_char(doc.DOC_DOCUMENT_DATE, 'YYYYMMDD')
        )
      ),
      XMLElement("REFERENCE",
        XMLElement("INVOICE-REFERENCE",
          XMLElement("REFERENCE-DATE",
            XMLElement("Reference-No", PAR.PAR_DOCUMENT),
            XMLElement("Date",
              XMLAttributes('CCYYMMDD' as "Format"),
              to_char(doc.DOC_DOCUMENT_DATE, 'YYYYMMDD')
            )
          )
        ),
        com_lib_ebanking_act_pn_xml.GetIncludeContainer(in_document_id),
        XMLElement("OTHER-REFERENCE",
          XMLAttributes('ACL' as "Type"),
          XMLElement("REFERENCE-DATE",
            XMLElement("Reference-No", DOC.DOC_NUMBER),
            XMLElement("Date",
              XMLAttributes('CCYYMMDD' as "Format"),
              to_char(doc.DOC_DOCUMENT_DATE, 'YYYYMMDD')
            )
          )
        )
      ),
      com_lib_ebanking_act_pn_xml.getBiller(in_document_id),
      com_lib_ebanking_act_pn_xml.getPayer(in_document_id),
      com_lib_ebanking_act_pn_xml.getDeliveryParty(in_document_id)
    ) into lx_data
  from
    ACT_DOCUMENT DOC,
    ACT_PART_IMPUTATION PAR
  where
    DOC.ACT_DOCUMENT_ID = in_document_id and
    PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID;

  return lx_data;
end;

/**
*   Noeud  /XML-FSCM-INVOICE-2003A/INVOICE/LINEITEM
*/
function GetLineItem(
  in_document_id IN act_document.act_document_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLAgg(XMLElement("LINE-ITEM",
      XMLAttributes(item.POS_NUMBER as "Line-Number"),
      XMLElement("ITEM-ID",
        XMLElement("Item-Id",
          XMLAttributes('SA' as "Type"),
          Substr(pcs.pc_functions.TranslateWord(
            'FTX_ISE_PRODUCT_DESCR',
            com_lib_ebanking_utl.GetDefAdressLangId(CEB.COM_EBANKING_ID)), (0*35) + 1, 35)
        )
      ),
      XMLElement("ITEM-DESCRIPTION",
        XMLElement("Item-Type-Code", 1011),
        XMLForest(
          Substr(pcs.pc_functions.TranslateWord(
            'FTX_ISE_PRODUCT_DESCR',
            com_lib_ebanking_utl.GetDefAdressLangId(CEB.COM_EBANKING_ID)), (0*35) + 1, 35) as "Line-35",
          Substr(pcs.pc_functions.TranslateWord(
            'FTX_ISE_PRODUCT_DESCR',
            com_lib_ebanking_utl.GetDefAdressLangId(CEB.COM_EBANKING_ID)), (1*35) + 1, 35) as "Line-35",
          Substr(pcs.pc_functions.TranslateWord(
            'FTX_ISE_PRODUCT_DESCR',
            com_lib_ebanking_utl.GetDefAdressLangId(CEB.COM_EBANKING_ID)), (2*35) + 1, 35) as "Line-35",
          Substr(pcs.pc_functions.TranslateWord(
            'FTX_ISE_PRODUCT_DESCR',
            com_lib_ebanking_utl.GetDefAdressLangId(CEB.COM_EBANKING_ID)), (3*35) + 1, 35) as "Line-35",
          Substr(pcs.pc_functions.TranslateWord(
            'FTX_ISE_PRODUCT_DESCR',
            com_lib_ebanking_utl.GetDefAdressLangId(CEB.COM_EBANKING_ID)), (4*35) + 1, 35) as "Line-35",
          Substr(pcs.pc_functions.TranslateWord(
            'FTX_ISE_PRODUCT_DESCR',
            com_lib_ebanking_utl.GetDefAdressLangId(CEB.COM_EBANKING_ID)), (5*35) + 1, 35) as "Line-35",
          Substr(pcs.pc_functions.TranslateWord(
            'FTX_ISE_PRODUCT_DESCR',
            com_lib_ebanking_utl.GetDefAdressLangId(CEB.COM_EBANKING_ID)), (6*35) + 1, 35) as "Line-35",
          Substr(pcs.pc_functions.TranslateWord(
            'FTX_ISE_PRODUCT_DESCR',
            com_lib_ebanking_utl.GetDefAdressLangId(CEB.COM_EBANKING_ID)), (7*35) + 1, 35) as "Line-35"
        )
      ),
      XMLElement("Quantity",
        XMLAttributes('47' as "Type", 'EA' as "Units"),
        1
      ),
      XMLElement("ITEM-AMOUNT",
        XMLAttributes('38' as "Type"),
        XMLElement("Amount",
          XMLAttributes(ITEM.CURRENCY as "Currency"),
          ITEM.TAX_LIABLED_AMOUNT + ITEM.TAX_VAT_AMOUNT_LC
        )
      ),
      XMLElement("ITEM-AMOUNT",
        XMLAttributes('66' as "Type"),
        XMLElement("Amount",
          XMLAttributes(ITEM.CURRENCY as "Currency"),
          ITEM.TAX_LIABLED_AMOUNT + ITEM.TAX_VAT_AMOUNT_LC
        )
      ),
      XMLElement("TAX",
        XMLElement("Rate",
          XMLAttributes('S' as "Category"),
          ITEM.TAX_RATE
        ),
        XMLElement("Amount",
          XMLAttributes(ITEM.CURRENCY as "Currency"),
          to_char (ITEM.TAX_VAT_AMOUNT_LC,'FM999999990.00')
        )
      )
    )) into lx_data
  from
    TABLE(com_lib_ebanking_utl.GetLineItems_ACT(in_document_id)) ITEM,
    COM_EBANKING CEB
  where
    CEB.ACT_DOCUMENT_ID = in_document_id;

  return lx_data;
end;

function GetTax(
  in_document_id IN act_document.act_document_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLAgg(XMLElement("TAX",
      XMLElement("TAX-BASIS",
        XMLElement("Amount",
          XMLAttributes(item.CURRENCY as "Currency"),
          ITEM.TAX_LIABLED_AMOUNT
        )
      ),
      XMLElement("Rate",
        XMLAttributes('S' as "Category"),
        ITEM.TAX_RATE
      ),
      XMLElement("Amount",
        XMLAttributes(item.CURRENCY as "Currency"),
        to_char (ITEM.TAX_VAT_AMOUNT_LC,'FM999999990.00')
      )
    )) into lx_data
  from
    TABLE(com_lib_ebanking_utl.GetLineItems_act(in_document_id)) ITEM;

  return lx_data;

  exception
    when OTHERS then
      return null;
end;

/**
*   Noeud  /XML-FSCM-INVOICE-2003A/INVOICE/SUMMARY
*
*   note : le tag DEPOSIT-AMOUNT (montant payé d'avance) n'est pas pris en compte
*          par PAYNET
*
*          lorsqu'un montant est payé d'avance, il faut ajouter une position (line-item) négative
*/
function GetSummary(
  in_document_id IN act_document.act_document_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLElement("SUMMARY",
      XMLElement("INVOICE-AMOUNT",
        XMLAttributes('25' as "Print-Status"),
        XMLElement("Amount",
          XMLAttributes(CUR.CURRENCY as "Currency"),
          SUMM.TAX_LIABLED_AMOUNT + SUMM.TAX_VAT_AMOUNT_LC
        )
      ),
      XMLElement("VAT-AMOUNT",
        XMLAttributes('25' as "Print-Status"),
        XMLElement("Amount",
          XMLAttributes(cur.CURRENCY as "Currency"),
          SUMM.TAX_VAT_AMOUNT_LC
        )
      ),
      com_lib_ebanking_act_pn_xml.getTax(in_document_id),
      XMLElement("PAYMENT-TERMS",
        XMLElement("BASIC",
          XMLAttributes(
            case
              when (PME.C_TYPE_SUPPORT in ('50','51','56')) then 'NPY'
              else
                case
                  when cus.C_BVR_GENERATION_METHOD = '02' then 'ESP'
                  when cus.C_BVR_GENERATION_METHOD = '03' then 'ESR'
                end
            end as "Payment-Type",
            '1' as "Terms-Type"
          ),
          XMLElement("TERMS",
            XMLElement("Date",
              XMLAttributes('CCYYMMDD' as "Format"),
              to_char(ise.EXP_CALCULATED, 'YYYYMMDD')
            )
          )
        )
      ),
      com_lib_ebanking_act_pn_xml.GetContainer(in_document_id)
    ) into lx_data
  from
    ACT_DOCUMENT DOC,
    ACS_PAYMENT_METHOD PME,
    PAC_CUSTOM_PARTNER CUS,
    ACS_FIN_ACC_S_PAYMENT FAS,
    V_ACT_EXPIRY_ISAG ISE,
    ACS_FINANCIAL_CURRENCY FCU,
    TABLE(com_lib_ebanking_utl.GetSummary_ACT(in_document_id)) SUMM,
    PCS.PC_CURR CUR
  where
    DOC.ACT_DOCUMENT_ID = in_document_id and
    ISE.ACS_FIN_ACC_S_PAYMENT_ID = FAS.ACS_FIN_ACC_S_PAYMENT_ID(+) and
    FAS.ACS_PAYMENT_METHOD_ID = PME.ACS_PAYMENT_METHOD_ID(+) and
    DOC.ACS_FINANCIAL_CURRENCY_ID = FCU.ACS_FINANCIAL_CURRENCY_ID and
    FCU.PC_CURR_ID = CUR.PC_CURR_ID and
    DOC.ACT_DOCUMENT_ID = ISE.ACT_DOCUMENT_ID and
    ISE.EXP_CALC_NET = 1 and
    ISE.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID;

  return lx_data;

  exception
    when OTHERS then
      return null;
end;


/**
*   Noeud  /XML-FSCM-INVOICE-2003A/INVOICE/HEADER/REFERENCE/Back-Pack
*/
function GetIncludeContainer(
  in_document_id IN act_document.act_document_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  -- Si le mode de présentation est
  -- 01 : Avec Bill Presentment, PDF intégré dans le XML
  select
    case when (ECS.C_ECS_BILL_PRESENTMENT = '01' and CEB.CEB_PDF_FILE is not null)
      then XMLElement("Back-Pack")
    end
    into lx_data
  from
    PCS.PC_EXCHANGE_SYSTEM ECS,
    COM_EBANKING CEB
  where
    CEB.ACT_DOCUMENT_ID = in_document_id and
    ECS.PC_EXCHANGE_SYSTEM_ID = CEB.PC_EXCHANGE_SYSTEM_ID;

  return lx_data;
end;

/**
*   Noeud  /XML-FSCM-INVOICE-2003A/INVOICE/SUMMARY/Back-Pack-Container
*/
function GetContainer(
  in_document_id IN act_document.act_document_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  -- Si le mode de présentation est
  -- 01 : Avec Bill Presentment, PDF intégré dans le XML
  select
    XMLForest(
      case when (ECS.C_ECS_BILL_PRESENTMENT = '01' and CEB.CEB_PDF_FILE is not null)
        then pcs.pc_encoding_functions.EncodeBase64(CEB.CEB_PDF_FILE)
        else null
      end as "Back-Pack-Container"
    ) into lx_data
  from
    COM_EBANKING CEB,
    PCS.PC_EXCHANGE_SYSTEM ECS
  where
    CEB.ACT_DOCUMENT_ID = in_document_id and
    CEB.PC_EXCHANGE_SYSTEM_ID = ECS.PC_EXCHANGE_SYSTEM_ID;

  return lx_data;
end;

END COM_LIB_EBANKING_ACT_PN_XML;
