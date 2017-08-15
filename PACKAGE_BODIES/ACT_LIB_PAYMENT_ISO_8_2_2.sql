--------------------------------------------------------
--  DDL for Package Body ACT_LIB_PAYMENT_ISO_8_2_2
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_LIB_PAYMENT_ISO_8_2_2" 
/**
 * Génération du document Xml pour un paiment selon ISO 20022.
 * Spécialisation Suisse
 *
 * @date 03.2012
 * @author rhermann
 * @author spfister
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
IS
/* Fonction individualisée pour gérer correctement la recurrence*/

--
-- Public methods
--

function iso_payment_xml(
  id_execuction IN DATE)
  return XMLType
is
  lx_data XMLType;
begin
  -- Calcul de la somme totale du paiement et affectation de la méthode de paiement
  for cpt in act_typ_payment_iso.gttCreditors.FIRST .. act_typ_payment_iso.gttCreditors.LAST loop
    act_mgt_payment_iso.update_payment_type(act_typ_payment_iso.gttCreditors(cpt));
  end loop;

  -- Construction du document xml contenant l'en-tête, les lots incluant les transactions
  select
    XMLElement("Document",
      XMLAttributes(
        'http://www.w3.org/2001/XMLSchema-instance' as "xmlns:xsi",
        'urn:iso:std:iso:20022:tech:xsd:pain.008.002.02 pain.008.002.02.xsd' as "xsi:schemaLocation",
        'urn:iso:std:iso:20022:tech:xsd:pain.008.002.02' as "xmlns"),
      XMLElement("CstmrDrctDbtInitn",
                 group_header(
                 act_mgt_payment_iso.count_creditors,
                 act_mgt_payment_iso.total_amount_creditors),
                 payment_info(id_execuction)
      )
    ) into lx_data
  from DUAL;

  return lx_data;
end;


function group_header(
  in_transaction_count IN BINARY_INTEGER,
  in_transaction_sum IN act_typ_payment_iso.tAmount)
  return XMLType
is
  lx_data XMLType;
begin
  if (in_transaction_count is null) then
    act_mgt_payment_iso_exception.raise_exception(
      act_mgt_payment_iso_exception.EXCEPTION_MISSING_VALUE_NO,
      'The transactions count is missing');
  elsif (in_transaction_sum is null) then
    act_mgt_payment_iso_exception.raise_exception(
      act_mgt_payment_iso_exception.EXCEPTION_MISSING_VALUE_NO,
      'The transactions total is missing');
  end if;

  select
    XMLElement("GrpHdr",
      XMLElement("MsgId",
        Substr(to_char(T.NOW,'YYYY-MM-DD HH24:MI:SS')||' '||act_typ_payment_iso.gttCreditors(1).payment_label,1,35)
      ),
      XMLElement("CreDtTm", to_char(T.NOW,'YYYY-MM-DD"T"HH24:MI:SS')),
      XMLElement("NbOfTxs", in_transaction_count),
      XMLElement("CtrlSum", act_lib_payment_iso.format(in_transaction_sum)),
      XMLElement("InitgPty",
        XMLElement("Nm", act_lib_payment_iso.format(act_typ_payment_iso.gtDebtor.company_name))
      )
    ) into lx_data
  from (
    select Sysdate NOW
    from DUAL
  ) T;

  return lx_data;
end;

function payment_info(
  id_execuction IN DATE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLAgg(XMLElement("PmtInf",
      XMLElement("PmtInfId",
        Substr(T.CURRENCY||' '||T.PAYMENT_TYPE||' '||T.PAYMENT_LABEL,1,35)
      ),
      XMLElement("PmtMtd", 'DD'),
      -- Batch booking
      XMLElement("BtchBookg", 'true'),
      case
        when (act_typ_payment_iso.gtDebtor.bank_country <> 'CH') then
          XMLConcat(
            XMLElement("NbOfTxs", Count(*)),
            XMLElement("CtrlSum", Sum(T.AMOUNT_TO_PAY))
          )
      end,
          XMLElement("PmtTpInf",
                XMLElement("SvcLvl",
                  XMLElement("Cd", 'SEPA')
                ),
            XMLElement("LclInstrm",
                xmlelement("Cd",t.mandate_mode)
            ),
            xmlelement("SeqTp",t.mandate_recurrent)
          ),

      -- Date d'exécution
      /* #modif date d'exécution = selon échéance en version 2 */
      XMLElement("ReqdColltnDt", to_char(id_execuction,'YYYY-MM-DD')),
      -- Coordonnées du payeur, l'adresse ne doit pas être envoyée pour la CH
      XMLElement("Cdtr",
        XMLElement("Nm", ACT_LIB_PAYMENT_ISO.format(act_typ_payment_iso.gtDebtor.company_name)),
        case
          when (act_typ_payment_iso.gtDebtor.bank_country <> 'CH') then
            XMLElement("PstlAdr",
              XMLElement("Ctry", ACT_LIB_PAYMENT_ISO.format(act_typ_payment_iso.gtDebtor.company_country)),
              XMLElement("AdrLine", ACT_LIB_PAYMENT_ISO.format(act_typ_payment_iso.gtDebtor.company_address)),
              XMLElement("AdrLine", ACT_LIB_PAYMENT_ISO.format(act_typ_payment_iso.gtDebtor.company_zip||' '||act_typ_payment_iso.gtDebtor.company_city))
            )
        end
      ),
      -- Compte du payeur - IBAN obligatoire
      XMLElement("CdtrAcct",
        XMLElement("Id",
          XMLElement("IBAN", act_typ_payment_iso.gtDebtor.account_number)
        )
      ),
      -- Compte du payeur - BIC obligatoire
      XMLElement("CdtrAgt",
        XMLElement("FinInstnId",
          XMLElement("BIC", act_typ_payment_iso.gtDebtor.swift_number)
        )
      ),
      XMLELEMENT("ChrgBr",'SLEV'),
      XMLElement("CdtrSchmeId",
        XMLElement("Id",
            XMLElement("PrvtId",
                XmlElement("Othr",
                    XmlElement("Id",act_typ_payment_iso.gtDebtor.pme_sbvr),
                    XmlElement("SchmeNm",
                        XmlElement("Prtry",'SEPA')
                    )
                )
            )
        )
     ),
      transactions(T.CURRENCY, T.PAYMENT_TYPE, T.PAYMENT_LABEL)
    )) into lx_data
  from TABLE(act_mgt_payment_iso.creditor_list) T
  group by T.CURRENCY, T.PAYMENT_TYPE,T.PAYMENT_LABEL,t.mandate_mode,t.mandate_recurrent ;

  return lx_data;
end;

function transactions(
  iv_currency IN VARCHAR2,
  iv_payment_type IN VARCHAR2,
	iv_payment_label in VARCHAR2)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLAgg(XMLElement("DrctDbtTxInf",
      XMLElement("PmtId",
        XMLElement("InstrId", Nvl(to_char(T.TRANSACTION_ID,'FM9999999999999990'),'instr'||to_char(ROWNUM))),
        XMLElement("EndToEndId", Nvl(to_char(T.TRANSACTION_ID,'FM9999999999999990'),'instr'||to_char(ROWNUM)))
      ),
      /* #modif. Attention, uniquement en EUR */
      XmlElement("InstdAmt",
        XmlAttributes('EUR' as "Ccy"),
        T.AMOUNT_TO_PAY),
      --XmlElement("ChrgBr",'SLEV'),
      XmlElement("DrctDbtTx",
        XmlElement("MndtRltdInf",
            XmlElement("MndtId",t.mandate_id),
            XmlElement("DtOfSgntr",to_char(t.mandate_signature,'YYYY-MM-DD'))
        )
      ),
      -- Pour les paiements bancaires, ajout de la banque
      case
        when (T.C_TYPE_REFERENCE = '1' and T.BANK_NAME is not null) or
             (T.C_TYPE_REFERENCE = '5' and T.SWIFT_NUMBER is not null) then
          XMLElement("DbtrAgt",
            XMLElement("FinInstnId",
               XMLElement("BIC", Replace(T.SWIFT_NUMBER,' '))
            )
          )
      end,
      -- Coordonnées du débiteur
      XMLElement("Dbtr",
        XMLElement("Nm", T.CREDITOR_NAME),
        XMLElement("PstlAdr",
          XMLForest(
            T.CREDITOR_COUNTRY as "Ctry",
            ExtractLine(T.CREDITOR_ADDRESS, 1) as "AdrLine",
            T.CREDITOR_ZIP ||' '||T.CREDITOR_CITY as "AdrLine"
          )
        )
      ),
      -- Indication du compte du débiteur
      XMLElement("DbtrAcct",
        XMLElement("Id",
          case
            when (T.C_TYPE_REFERENCE = '5') then
              XMLElement("IBAN", T.ACCOUNT_NUMBER)
            else
              XMLElement("Othr",
                XMLElement("Id", T.ACCOUNT_NUMBER)
              )
          end
        )
      ),
      case
        when (T.PAYMENT_TYPE = 'CH BVR' or T.TRANSACTION_COMMENT is not null) then
          -- Indication des informations de remises au créancier
          XMLElement("RmtInf",
            case
              when (T.PAYMENT_TYPE = 'CH BVR') then
                XMLElement("Strd",
                  XMLElement("CdtrRefInf",
                    case
                      when (T.REFERENCE_BVR is not null or T.TRANSACTION_COMMENT is not null) then
                        XMLElement("Ref", Nvl(T.REFERENCE_BVR, T.TRANSACTION_COMMENT))
                    end
                  ),
                  XMLElement("AddtlRmtInf", T.REFERENCE_BVR)
                )
              else
                XMLElement("Ustrd",
                  case
                    when (Length(T.TRANSACTION_COMMENT) > 140) then
                      Substr(T.TRANSACTION_COMMENT, 1, 137) ||'...'
                    else
                      T.TRANSACTION_COMMENT
                  end
                )
            end
          )
      end
    )) into lx_data
  from TABLE(act_mgt_payment_iso.creditor_list) T
  where T.CURRENCY = iv_currency and T.PAYMENT_TYPE = iv_payment_type
	AND T.PAYMENT_LABEL = iv_payment_label;

  return lx_data;
end;

END ACT_LIB_PAYMENT_ISO_8_2_2;
