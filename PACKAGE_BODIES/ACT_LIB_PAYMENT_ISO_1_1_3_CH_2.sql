--------------------------------------------------------
--  DDL for Package Body ACT_LIB_PAYMENT_ISO_1_1_3_CH_2
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_LIB_PAYMENT_ISO_1_1_3_CH_2" 
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
        'http://www.six-interbank-clearing.com/de/pain.001.001.03.ch.02.xsd' as "xmlns",
        'http://www.w3.org/2001/XMLSchema-instance' as "xmlns:xsi",
        'http://www.six-interbank-clearing.com/de/pain.001.001.03.ch.02.xsd  pain.001.001.03.ch.02.xsd' as "xsi:schemaLocation"),
      XMLElement("CstmrCdtTrfInitn",
        act_lib_payment_iso_1_1_3_ch_2.group_header(
          act_mgt_payment_iso.count_creditors,
          act_mgt_payment_iso.total_amount_creditors),
        act_lib_payment_iso_1_1_3_ch_2.payment_info(id_execuction)
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
        XMLElement("Nm", act_lib_payment_iso.format(act_typ_payment_iso.gtDebtor.company_name)),
        XMLElement("CtctDtls",
          XMLElement("Nm", 'ProConcept'),
          XMLElement("Othr", pcs.pc_erp_version.Patchset)
        )
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
      XMLElement("PmtMtd", 'TRF'),
      -- Batch booking
      XMLElement("BtchBookg", 'true'),
      case
        when (act_typ_payment_iso.gtDebtor.bank_country <> 'CH') then
          XMLConcat(
            XMLElement("NbOfTxs", Count(*)),
            XMLElement("CtrlSum", Sum(T.AMOUNT_TO_PAY))
          )
      end,
      -- SEPA recommandé au niveau B et pour le code confidentialité qui n'est pas indiqué au niveau C
      case
        when (T.PAYMENT_TYPE = 'CH SEPA' or
              (T.PAYMENT_TYPE not in ('CH BVR','CH CCP') and act_typ_payment_iso.gtDebtor.c_method_category = '0')) then
          XMLElement("PmtTpInf",
            case
              when (T.PAYMENT_TYPE = 'CH SEPA') then
                XMLElement("SvcLvl",
                  XMLElement("Cd", 'SEPA')
                )
            end,
            -- En cas de paiement des salaires, code confidentialité
            case
              when (act_typ_payment_iso.gtDebtor.c_method_category = '0') then
                XMLElement("CtgyPurp",
                  XMLElement("Cd", 'SALA')
                )
            end
          )
      end,
      -- Date d'exécution
      XMLElement("ReqdExctnDt", to_char(id_execuction,'YYYY-MM-DD')),
      -- Coordonnées du payeur, l'adresse ne doit pas être envoyée pour la CH
      XMLElement("Dbtr",
        XMLElement("Nm", act_typ_payment_iso.gtDebtor.company_name),
        case
          when (act_typ_payment_iso.gtDebtor.bank_country <> 'CH') then
            XMLElement("PstlAdr",
              XMLElement("StrtNm", act_typ_payment_iso.gtDebtor.company_address),
              XMLElement("PstCd", act_typ_payment_iso.gtDebtor.company_zip),
              XMLElement("TwnNm", act_typ_payment_iso.gtDebtor.company_city),
              XMLElement("Ctry", act_typ_payment_iso.gtDebtor.company_country)
            )
        end
      ),
      -- Compte du payeur - IBAN obligatoire
      XMLElement("DbtrAcct",
        XMLElement("Id",
          XMLElement("IBAN", act_typ_payment_iso.gtDebtor.account_number)
        )
      ),
      -- Compte du payeur - BIC obligatoire
      XMLElement("DbtrAgt",
        XMLElement("FinInstnId",
          XMLElement("BIC", act_typ_payment_iso.gtDebtor.swift_number)
        )
      ),
      act_lib_payment_iso_1_1_3_ch_2.transactions(T.CURRENCY, T.PAYMENT_TYPE)
    )) into lx_data
  from TABLE(act_mgt_payment_iso.creditor_list) T
  group by T.CURRENCY, T.PAYMENT_TYPE, PAYMENT_LABEL;

  return lx_data;
end;

function transactions(
  iv_currency IN VARCHAR2,
  iv_payment_type IN VARCHAR2)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLAgg(XMLElement("CdtTrfTxInf",
      XMLElement("PmtId",
        XMLElement("InstrId", Nvl(to_char(T.TRANSACTION_ID,'FM9999999999999990'),'instr'||to_char(ROWNUM))),
        XMLElement("EndToEndId", Nvl(to_char(T.TRANSACTION_ID,'FM9999999999999990'),'instr'||to_char(ROWNUM)))
      ),
      -- Indication du tag uniquement si rempli
      case
        when (T.PAYMENT_TYPE in ('CH BVR','CH CCP') or act_typ_payment_iso.gtDebtor.c_method_category = '0') then
          XMLElement("PmtTpInf",
            -- Indication du mode de paiement pour la poste
            case T.PAYMENT_TYPE
              when 'CH BVR' then
                XMLElement("LclInstrm",
                  XMLElement("Prtry", 'CH01')
                )
              when 'CH CCP' then
                XMLElement("LclInstrm",
                  XMLElement("Prtry", 'CH02')
                )
            end,
            -- En cas de paiement des salaires, code confidentialité
            case
              when (act_typ_payment_iso.gtDebtor.c_method_category = '0') then
                XMLElement("CtgyPurp",
                  XMLElement("Cd", 'SALA')
                )
            end
          )
      end,
      XMLElement("Amt",
        XMLElement("InstdAmt",
          XMLAttributes(T.CURRENCY as "Ccy"),
          T.AMOUNT_TO_PAY)
      ),
      -- Les charges pour les virements SEPA ne peuvent pas figurer au niveau C
      case
        when (T.PAYMENT_TYPE <> 'CH SEPA' and T.C_CHARGES_MANAGEMENT is not null) then
          XMLElement("ChrgBr",
            case T.C_CHARGES_MANAGEMENT
              when '0' then 'DEBT'
              when '1' then 'CRED'
              when '2' then 'SHAR'
            end
          )
      end,
      -- Pour les paiements bancaires, ajout de la banque
      case
        when (T.C_TYPE_REFERENCE = '1' and T.BANK_NAME is not null) or
             (T.C_TYPE_REFERENCE = '5' and T.SWIFT_NUMBER is not null) then
          XMLElement("CdtrAgt",
            XMLElement("FinInstnId",
              case
                -- Pour les étrangers et lorsque le clearing n'est pas renseigné, utilisation du BIC
                when (T.BANK_CLEARING is null or T.BANK_COUNTRY <> 'CH') and T.SWIFT_NUMBER is not null then
                  XMLElement("BIC", Replace(T.SWIFT_NUMBER,' '))
                -- Pour les Suisses qui ont un clearing, utilisation de celui-ci
                when (T.BANK_CLEARING is not null and T.BANK_COUNTRY = 'CH') then
                  XMLElement("ClrSysMmbId",
                    XMLElement("ClrSysId",
                      XMLElement("Cd", 'CHBCC')
                    ),
                    XMLElement("MmbId", T.BANK_CLEARING)
                  )
                when (T.BANK_NAME is not null) then
                  -- Dans les autres cas, renseignement des coordonnées de la banque
                  XMLConcat(
                    XMLElement("Nm", T.BANK_NAME),
                    case
                      when (T.BANK_COUNTRY is not null) then
                        XMLElement("PstlAdr",
                          XMLForest(
                            T.BANK_ADDRESS as "StrtNm",
                            T.BANK_ZIP as "PstCd",
                            T.BANK_CITY as "TwnNm"
                          ),
                          XMLElement("Ctry", T.BANK_COUNTRY)
                        )
                    end
                  )
              end
            )
          )
      end,
      -- Coordonnées du créancier
      XMLElement("Cdtr",
        XMLElement("Nm", T.CREDITOR_NAME),
        XMLElement("PstlAdr",
          XMLForest(
            ExtractLine(T.CREDITOR_ADDRESS, 1) as "StrtNm",
            T.CREDITOR_ZIP as "PstCd",
            T.CREDITOR_CITY as "TwnNm"
          ),
          XMLElement("Ctry", T.CREDITOR_COUNTRY)
        )
      ),
      -- Indication du compte du créancier
      XMLElement("CdtrAcct",
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
  where T.CURRENCY = iv_currency and T.PAYMENT_TYPE = iv_payment_type;

  return lx_data;
end;

END ACT_LIB_PAYMENT_ISO_1_1_3_CH_2;
