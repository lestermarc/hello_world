--------------------------------------------------------
--  DDL for Package Body ACT_MGT_PAYMENT_ISO
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_MGT_PAYMENT_ISO" 
/**
 * Administration des paiements selon ISO 20022.
 *
 * @date 03.2012
 * @author rhermann
 * @author spfister
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
IS

  /** Variable globale pour l'initialisation du débiteur */
  gn_fin_acc_payment_id acs_fin_acc_s_payment.acs_fin_acc_s_payment_id%TYPE := null;


/**
 * Convertion d'un document Xml en texte, avec prologue.
 * @param ix_document  Document Xml original.
 * @return Un CLob contenant le texte du document Xml, ainsi qu'un prologue
 *         complet correspondant à l'encodage de la base.
 */
function p_XmlToClob(ix_document IN XMLType) return CLob is
begin
  if (ix_document is not null) then
    return /*pc_jutils.get_XMLPrologDefault ||Chr(10)|| */ix_document.getClobVal();
  end if;

  return null;
end;


/**
 * Initialisation des données du donneur d'ordre.
 * @param in_fin_acc_payment_id Identifiant pour la méthode de paiement.
 */
procedure p_initialize_debtor(
  in_fin_acc_payment_id IN acs_fin_acc_s_payment.acs_fin_acc_s_payment_id%TYPE)
is
begin
  select
    Nvl(C.COM_SOCIALNAME,C.COM_DESCR) company_name,
    C.COM_ADR company_address,
    C.COM_ZIP company_zip,
    C.COM_CITY company_city,
    CN2.CNTID company_country,
    F.FIN_ETAB_ACCOUNT account_number,
    Substr(F.FIN_ETAB_ACCOUNT,1,2) bank_country,
    Replace(Nvl(F.FIN_BIC_NUMBER,B.BAN_SWIFT),' ') swift_number,
    M.C_TYPE_SUPPORT,
    M.C_METHOD_CATEGORY,
    Nvl(M.PME_PARTNER_GROUP,0) partner_group,
    pme_sbvr
  into act_typ_payment_iso.gtDebtor
  from
    PCS.PC_CNTRY CN2,
    PCS.PC_COMP C,
    ACS_PAYMENT_METHOD M,
    PCS.PC_CNTRY CN,
    PCS.PC_BANK B,
    ACS_FINANCIAL_ACCOUNT F,
    ACS_FIN_ACC_S_PAYMENT P
  where
    P.ACS_FIN_ACC_S_PAYMENT_ID = in_fin_acc_payment_id and
    F.ACS_FINANCIAL_ACCOUNT_ID = P.ACS_FINANCIAL_ACCOUNT_ID and
    B.PC_BANK_ID(+) = F.PC_BANK_ID and
    CN.PC_CNTRY_ID(+) = B.PC_CNTRY_ID and
    M.ACS_PAYMENT_METHOD_ID = P.ACS_PAYMENT_METHOD_ID and
    C.PC_COMP_ID = pcs.PC_I_LIB_SESSION.GetCompanyId and
    CN2.PC_CNTRY_ID = C.PC_CNTRY_ID;

  if (act_typ_payment_iso.gtDebtor.swift_number is null) then
    act_mgt_payment_iso_exception.raise_exception(
      act_mgt_payment_iso_exception.EXCEPTION_SWIFT_NO,
      'Le BIC est obligatoire pour le compte du donneur d''ordre');
  end if;
end;

/**
 * Mise à jour des informations des banques si pas fournies
 */
procedure p_prepare_creditors
is
  lt_creditor act_typ_payment_iso.tCreditor;
  l_swift pac_financial_reference.fre_swift%type;
  l_cntid pcs.pc_cntry.cntid%type;
begin
  for cpt in act_typ_payment_iso.gttCreditors.FIRST .. act_typ_payment_iso.gttCreditors.LAST loop
    lt_creditor := act_typ_payment_iso.gttCreditors(cpt);

    -- mise à jour du pays si la valeur en clair n'a pas été fournie
    if (lt_creditor.creditor_country is null) then
      begin
        select CNTID
        into lt_creditor.creditor_country
        from PCS.PC_CNTRY
        where PC_CNTRY_ID = lt_creditor.pc_cntry_id;
        exception
          when NO_DATA_FOUND then
            act_mgt_payment_iso_exception.raise_exception(
              act_mgt_payment_iso_exception.EXCEPTION_BAD_VALUE_NO,
              'Country '||Nvl(to_char(lt_creditor.pc_cntry_id),'null')||' not found for '||lt_creditor.creditor_name);
      end;
    end if;

    -- mise à jour des données bancaires si celles-ci n'ont pas été données en clair
    if (lt_creditor.bank_name is null and lt_creditor.pc_bank_id is not null) then
      begin
        select
          ban_name1,
          ban_clear,
          ban_zip,
          ban_adr,
          ban_city,
          ban_state,
          cntid,
          ban_swift
        into
          lt_creditor.bank_name,
          lt_creditor.bank_clearing,
          lt_creditor.bank_zip,
          lt_creditor.bank_address,
          lt_creditor.bank_city,
          lt_creditor.bank_state,
          l_cntid,
          l_swift
        from
          pcs.pc_bank b, pcs.pc_cntry c
        where
          B.PC_BANK_ID = lt_creditor.pc_bank_id and
          C.PC_CNTRY_ID = B.PC_CNTRY_ID;
        exception
          when NO_DATA_FOUND then
            act_mgt_payment_iso_exception.raise_exception(
              act_mgt_payment_iso_exception.EXCEPTION_BAD_VALUE_NO,
              'Bank '||Nvl(to_char(lt_creditor.pc_bank_id),'null')||' not found for '||lt_creditor.creditor_name);
      end;
    end if;

    if (lt_creditor.swift_number is null) then
      lt_creditor.swift_number := l_swift;
    end if;

    if (lt_creditor.bank_country is null) then
      lt_creditor.bank_country := l_cntid;
    end if;

    -- formatage ASCII des textes
    lt_creditor.creditor_name := act_lib_payment_iso.format(lt_creditor.creditor_name);
    lt_creditor.creditor_address := act_lib_payment_iso.format(lt_creditor.creditor_address);
    lt_creditor.creditor_city := act_lib_payment_iso.format(lt_creditor.creditor_city);
    lt_creditor.creditor_state := act_lib_payment_iso.format(lt_creditor.creditor_state);
    lt_creditor.bank_name := act_lib_payment_iso.format(lt_creditor.bank_name);
    lt_creditor.bank_address := act_lib_payment_iso.format(lt_creditor.bank_address);
    lt_creditor.bank_city := act_lib_payment_iso.format(lt_creditor.bank_city);
    lt_creditor.bank_state := act_lib_payment_iso.format(lt_creditor.bank_state);
    lt_creditor.transaction_comment := act_lib_payment_iso.format(lt_creditor.transaction_comment);
    lt_creditor.payment_label := act_lib_payment_iso.format(lt_creditor.payment_label);

    -- réaffectation du créancier
    act_typ_payment_iso.gttCreditors(cpt) := lt_creditor;
  end loop;
end;


--
-- Public mehtods
--

procedure clear_creditors
is
begin
  act_typ_payment_iso.gttCreditors.DELETE;
end;

procedure add_creditor(it_creditor IN act_typ_payment_iso.tCreditor)
is
  ltCreditor act_typ_payment_iso.tCreditor;
begin
  ltCreditor := it_creditor;
  if (ltCreditor.c_type_reference = '5') then
    ltCreditor.bank_country := Substr(ltCreditor.account_number,1,2);
  end if;
  act_typ_payment_iso.gttCreditors.EXTEND(1);
  act_typ_payment_iso.gttCreditors(act_typ_payment_iso.gttCreditors.COUNT):= ltCreditor;
end;

function count_creditors
  return INTEGER
is
  ln_result INTEGER;
begin
  select Count(*)
  into ln_result
  from TABLE(act_mgt_payment_iso.creditor_list);

  return ln_result;
end;

function total_amount_creditors
  return act_typ_payment_iso.tAmount
is
  ln_result act_typ_payment_iso.tAmount;
begin
  select Sum(amount_to_pay)
  into ln_result
  from TABLE(act_mgt_payment_iso.creditor_list);

  return ln_result;
end;

procedure update_payment_type(
  iot_creditor IN OUT NOCOPY act_typ_payment_iso.tCreditor)
is
  vCreditorBankSEPA INTEGER;
begin
  -- Recherche si le pays de la banque du créditeur est membre du SEPA
  select count(cntid)
    into vCreditorBankSEPA
    from pcs.pc_cntry
   where cnt_sepa_member = 1
     and cntid = iot_creditor.bank_country;

  if iot_creditor.mandate_mode is not null then
    if iot_creditor.mandate_last_dbt is null and iot_creditor.mandate_recurrent = 'RCUR' then
       iot_creditor.payment_type := iot_creditor.mandate_mode||' FRST ';
       iot_creditor.mandate_recurrent :='FRST';
    else
       iot_creditor.payment_type := iot_creditor.mandate_mode||' '||iot_creditor.mandate_recurrent;
    end if;
  elsif iot_creditor.currency in ('CHF','EUR') and iot_creditor.c_type_reference = '3' and iot_creditor.reference_bvr is not null then
    iot_creditor.payment_type := 'CH BVR';
  elsif iot_creditor.currency in ('CHF','EUR') and iot_creditor.c_type_reference = '2' then
    iot_creditor.payment_type := 'CH CCP';
  elsif iot_creditor.currency in ('CHF','EUR') and iot_creditor.c_type_reference in ('1','5') and iot_creditor.bank_country = 'CH'and
        act_typ_payment_iso.gtDebtor.bank_country = 'CH' then
    iot_creditor.payment_type := 'CH BANK CHF EUR';
  elsif iot_creditor.currency not in ('CHF','EUR') and iot_creditor.c_type_reference in ('1','5') and iot_creditor.bank_country = 'CH' then
    iot_creditor.payment_type := 'CH BANK OTHER';
  elsif iot_creditor.currency = 'EUR' and iot_creditor.c_type_reference ='5' and Nvl(iot_creditor.c_charges_management,'2') = '2' and
        iot_creditor.swift_number is not null and
        vCreditorBankSEPA > 0 then
    iot_creditor.payment_type := 'CH SEPA';
  -- Pour le SEPA, limitation à l'euro et aux pays membres
  elsif iot_creditor.currency not in ('CHF','EUR') and iot_creditor.bank_country <> 'CH' and act_typ_payment_iso.gtDebtor.bank_country = 'CH' then
    iot_creditor.payment_type := 'CH INTL';
  else
    iot_creditor.payment_type := 'OTHER';
  end if;
end;

procedure init_debtor(
  in_fin_acc_payment_id in acs_fin_acc_s_payment.acs_fin_acc_s_payment_id%TYPE)
is
begin
  if (in_fin_acc_payment_id is null) then
    act_typ_payment_iso.gtDebtor := null;
  elsif (gn_fin_acc_payment_id is null or gn_fin_acc_payment_id != in_fin_acc_payment_id) then
    gn_fin_acc_payment_id := in_fin_acc_payment_id;
    p_initialize_debtor(gn_fin_acc_payment_id);
  end if;
end;

function debtor
  return act_typ_payment_iso.tDebtor
is
begin
  return act_typ_payment_iso.gtDebtor;
end;

/* Préparation des créanciers à payer */
function internal_creditor_list
  return act_typ_payment_iso.ttCreditors
  PIPELINED
is
begin
  for tpl in act_typ_payment_iso.gttCreditors.FIRST .. act_typ_payment_iso.gttCreditors.LAST loop
    PIPE ROW(act_typ_payment_iso.gttCreditors(tpl));
  end loop;
  return;

  exception
    when NO_DATA_NEEDED then
      return;
end;

function creditor_list
  return act_typ_payment_iso.ttCreditors
  PIPELINED
is
  lnPos Integer;
  lcMaxLength constant Integer := 140;
begin
   if (act_typ_payment_iso.gtDebtor.partner_group = 1) then
    for tpl in (
      select
        creditor_name,
        creditor_address,
        creditor_zip,
        creditor_city,
        creditor_state,
        creditor_country,
        pc_cntry_id,
        eco_code,
        pc_bank_id,
        bank_name,
        bank_clearing,
        bank_zip,
        bank_address,
        bank_city,
        bank_state,
        bank_country,
        account_number,
        c_type_reference,
        c_charges_management,
        swift_number,
        -- listagg(transaction_comment,',') within group(order by transaction_comment) as transaction_comment, --exception dès plus que 4000
        -- cast(wmsys.wm_concat(transaction_comment) as VARCHAR2(140)) as transaction_comment, --lcMaxLength -- obsolète en 12c
        cast(XMLAGG(XMLELEMENT(E,transaction_comment||',')).EXTRACT('//text()') as VARCHAR2(140)) as transaction_comment,
        Min(transaction_id) transaction_id,
        reference_bvr,
        Sum(amount_to_pay) amount_to_pay,
        currency,
        payment_label,
        payment_type,
        mandate_id,
        mandate_signature,
        mandate_recurrent,
        mandate_mode,
        mandate_last_dbt
      from TABLE(act_mgt_payment_iso.internal_creditor_list())
      group by
        creditor_name,
        creditor_address,
        creditor_zip,
        creditor_city,
        creditor_state,
        creditor_country,
        pc_cntry_id,
        eco_code,
        pc_bank_id,
        bank_name,
        bank_clearing,
        bank_zip,
        bank_address,
        bank_city,
        bank_state,
        bank_country,
        account_number,
        c_type_reference,
        c_charges_management,
        swift_number ,
        reference_bvr,
        currency,
        payment_label,
        payment_type,
        mandate_id,
        mandate_signature,
        mandate_recurrent,
        mandate_mode,
        mandate_last_dbt
    ) loop
      if length(tpl.transaction_comment) = lcMaxLength then
        -- Le commentaire doit être lisible: raccourcir à lcMaxLength (fait dans la commande sql)
        --   et supprimer le dernier élément tronqué (soit ce qui est à partir de (et y compris) la dernière virgule)
        lnPos := InStr(tpl.transaction_comment, ',', -1) -1;--Dernière virgule supprimée
        if lnPos > 0 then
          tpl.transaction_comment := SubStr(tpl.transaction_comment, 1, lnPos);
        end if;
      end if;

      PIPE ROW(tpl);
    end loop;
  else
    for tpl in act_typ_payment_iso.gttCreditors.FIRST .. act_typ_payment_iso.gttCreditors.LAST loop
      PIPE ROW(act_typ_payment_iso.gttCreditors(tpl));
    end loop;
  end if;

  return;

  exception
    when NO_DATA_NEEDED then
      return;
end;

--
-- Génération du document xml
--

function iso_payment(
  id_execution IN act_document.doc_executive_date%TYPE,
  in_fin_acc_payment_id in acs_fin_acc_s_payment.acs_fin_acc_s_payment_id%TYPE default null,
  it_creditors IN act_typ_payment_iso.ttCreditors default null)
  return CLOB
is
begin
  return p_XmlToClob(
    act_mgt_payment_iso.iso_payment_xml(id_execution, in_fin_acc_payment_id, it_creditors)
  );
end;
function iso_payment_xml(
  id_execution IN act_document.doc_executive_date%TYPE,
  in_fin_acc_payment_id IN acs_fin_acc_s_payment.acs_fin_acc_s_payment_id%TYPE default null,
  it_creditors IN act_typ_payment_iso.ttCreditors default null)
  return XMLType
is
  lx_document XMLType;
  lv_cmd VARCHAR2(32767);
begin
  if (it_creditors is not null and it_creditors.COUNT > 0) then
    for cpt in it_creditors.FIRST .. it_creditors.LAST loop
      act_mgt_payment_iso.add_creditor(it_creditors(cpt));
    end loop;
  end if;

  -- initialisation des données du débiteur (si pas déjà fait)
  act_mgt_payment_iso.init_debtor(in_fin_acc_payment_id);

  -- préparation des données des créanciers
  p_prepare_creditors;

  begin
    select
      Nvl(M.PME_IND_FILE_PROC,
          case M.C_ISO20022_VERSION
            when '001' then 'result := act_lib_payment_iso_1_1_3_ch_2.iso_payment_xml(execution_date);'
            when '002' then 'result := act_lib_payment_iso_1_1_2.iso_payment_xml(execution_date);'
            when '003' then 'result := act_lib_payment_iso_1_2_3.iso_payment_xml(execution_date);'
            when '004' then 'result := act_lib_payment_iso_1_3_3_de.iso_payment_xml(execution_date);'
            when '005' then 'result := act_lib_payment_iso_1_1_3.iso_payment_xml(execution_date);'
            when '200' then 'result := act_lib_payment_iso_8_1_2_ch_1.iso_payment_xml(execution_date);'
            when '210' then 'result := act_lib_payment_iso_8_2_2.iso_payment_xml(execution_date);'
          end)
    into lv_cmd
    from ACS_PAYMENT_METHOD M, ACS_FIN_ACC_S_PAYMENT A
    where
      A.ACS_FIN_ACC_S_PAYMENT_ID = gn_fin_acc_payment_id and
      M.ACS_PAYMENT_METHOD_ID = A.ACS_PAYMENT_METHOD_ID;

    exception
      when NO_DATA_FOUND then
        act_mgt_payment_iso_exception.raise_exception(
          act_mgt_payment_iso_exception.EXCEPTION_GENERAL_NO,
          'Authorized payment method '||Nvl(to_char(gn_fin_acc_payment_id),'null')||' not found');
  end;

  if (lv_cmd is null) then
    act_mgt_payment_iso_exception.raise_exception(
      act_mgt_payment_iso_exception.EXCEPTION_GENERAL_NO,
      'The statement to execute is null');
  end if;

  EXECUTE IMMEDIATE
    act_lib_payment_iso.BuildCommand(lv_cmd)
    USING IN in_fin_acc_payment_id, -- :1
          IN id_execution, -- :2
          OUT lx_document; -- :3

  return lx_document;
end;

END ACT_MGT_PAYMENT_ISO;
