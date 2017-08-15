--------------------------------------------------------
--  DDL for Package Body COM_LIB_EBANKING_UTL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_LIB_EBANKING_UTL" 
/**
 * Package utilitaire pour la gestion des documents e-factures de document finance.
 *
 * @version 1.0
 * @date 09/2011
 * @author pyvoirol
 * @author spfister
 *
 * Copyright 1997-2011 SolvAxis SA. Tous droits réservés.
 */
AS

function GetDefAdressLang(
  in_ebanking_id IN com_ebanking.com_ebanking_id%TYPE)
  return VARCHAR2
is
  lv_result pcs.pc_lang.lanid%TYPE;
begin
  for tplAdrLanId in (
    select L.*
    from (
      select
        case Lower(LAN.LANID) when 'ge' then 'de' else lower(LAN.LANID) end LANID
      from
        PAC_ADDRESS ADR,
        PCS.PC_LANG LAN,
        PAC_EBPP_REFERENCE EBP,
        COM_EBANKING CEB
      where
        CEB.COM_EBANKING_ID = in_ebanking_id and
        CEB.PAC_EBPP_REFERENCE_ID = EBP.PAC_EBPP_REFERENCE_ID and
        ADR.PAC_PERSON_ID = PAC_CUSTOM_PARTNER_ID and
        LAN.PC_LANG_ID = ADR.PC_LANG_ID
      order by
        case when ADR.DIC_ADDRESS_TYPE_ID = 'Fac' then 0 else 1 end,
        ADR.ADD_PRINCIPAL
      ) L
    where rownum = 1
  ) loop
    lv_result := tplAdrlanId.LANID;
  end loop;

  if (lv_result is null) then
    lv_result := 'fr';
  end if;

  return lv_result;
end;

function GetDefAdressLangId(
  in_ebanking_id IN com_ebanking.com_ebanking_id%TYPE)
  return pcs.pc_lang.pc_lang_id%TYPE
is
  ln_result pcs.pc_lang.pc_lang_id%TYPE;
begin
  for tplAdrLanId in (
    select L.*
    from (
      select LAN.PC_LANG_ID
      from PAC_ADDRESS ADR, PCS.PC_LANG LAN, PAC_EBPP_REFERENCE EBP, COM_EBANKING CEB
      where CEB.COM_EBANKING_ID = in_ebanking_id and
        CEB.PAC_EBPP_REFERENCE_ID = EBP.PAC_EBPP_REFERENCE_ID and
        ADR.PAC_PERSON_ID = PAC_CUSTOM_PARTNER_ID and
        LAN.PC_LANG_ID = ADR.PC_LANG_ID
      order by
        case when ADR.DIC_ADDRESS_TYPE_ID = 'Fac' then 0 else 1 end,
        ADR.ADD_PRINCIPAL
      ) L
    where rownum = 1
  ) loop
    ln_result := tplAdrlanId.pc_lang_id;
  end loop;

  if (ln_result is null) then
    ln_result := 1;
  end if;

  return ln_result;
end;

function GetFormatedBvrNbr(
  iv_BVR_number IN VARCHAR2)
  return VARCHAR2
is
  lv_result VARCHAR2(30);
begin
  if (iv_BVR_number is null) then
    return null;
  end if;

  -- Formatage du n° de bvr au format 00-000000-0
  lv_result := Replace(iv_BVR_number, '-', '');
  lv_result :=
    Substr(lv_result, 1, 2) ||'-'||
    Substr(lv_result, 3, Length(lv_result)-3) ||'-'||
    Substr(lv_result, -1);

  return lv_result;
end;

function GetDeliveryDate(
  in_document_id IN NUMBER,
  iv_date_type IN VARCHAR2)
  return DATE
is
  ld_result DATE;
begin
  if (iv_date_type = 'ACT') then
    select DOC_DOCUMENT_DATE
    into ld_result
    from ACT_DOCUMENT
    where ACT_DOCUMENT_ID = in_document_id;
  elsif (iv_date_type = 'DOC') then
    select DMT_DATE_DOCUMENT
    into ld_result
    from DOC_DOCUMENT
    where DOC_DOCUMENT_ID = in_document_id;
  else
    ld_result := null;
  end if;

  return ld_result;

  exception
    when NO_DATA_FOUND then
    return null;
end;

function GetLineItems_ACT(
  in_document_id IN act_document.act_document_id%TYPE)
  return TT_ITEM_ACT
  PIPELINED
is
  ln_roundAmount act_det_tax.tax_vat_amount_lc%TYPE;
  lt_item_act COM_LIB_EBANKING_UTL.T_ITEM_ACT;
  ln_cpt BINARY_INTEGER := 0;
  ln_acsTaxCodeId acs_tax_code.acs_tax_code_id%TYPE;
  ln_detPaiedLc act_det_payment.det_paied_lc%type;
  lv_currency pcs.pc_curr.currency%type;
begin

  /* récupération du code TVA attribué à l'imputation
     contenant le montant d'arrondi du document transmis par ISE
     La valeur est stockée dans la variable globale (com_variable) FTX_ISE_VAT_CODE_4_ROUNDING */
  select Nvl(Max(TAX.ACS_TAX_CODE_ID),0) ACS_TAX_CODE_ID
  into ln_acsTaxCodeId
  from ACS_TAX_CODE TAX, ACS_ACCOUNT ACC
  where ACC.ACC_NUMBER = com_var.GetCharacter('FTX_ISE_VAT_CODE_4_ROUNDING',1) and
    ACC.ACS_ACCOUNT_ID = TAX.ACS_TAX_CODE_ID;

  /* récupération du montant d'arrondi
     attention : 1 seule ligne devrait être liée au code TVA trouvé précédemment */
  select Nvl(Sum(TAX.TAX_LIABLED_AMOUNT*-1),0) TAX_VAT_AMOUNT_LC
  into ln_roundAmount
  from ACT_DOCUMENT DOC, ACT_FINANCIAL_IMPUTATION FIN, ACT_DET_TAX TAX
  where DOC.ACT_DOCUMENT_ID = in_document_id and
    DOC.ACT_DOCUMENT_ID = FIN.ACT_DOCUMENT_ID and
    FIN.ACT_FINANCIAL_IMPUTATION_ID = TAX.ACT_FINANCIAL_IMPUTATION_ID and
    FIN.ACS_TAX_CODE_ID = ln_acsTaxCodeId;

  /* Récupération des détails TVA servant de base
     à la création des lignes du document e-facture */
  for tpl_actDetTax in (
    select
      DOC.ACT_DOCUMENT_ID,
      FIN.ACS_TAX_CODE_ID,
      TAX.TAX_INCLUDED_EXCLUDED,
      TAX.TAX_RATE,
      TAX.TAX_LIABLED_RATE,
      CUR.CURRENCY,
      Sum(TAX.TAX_LIABLED_AMOUNT*-1) TAX_LIABLED_AMOUNT,
      Sum(TAX.TAX_TOT_VAT_AMOUNT_LC*-1) TAX_TOT_VAT_AMOUNT_LC,
      Sum(TAX.TAX_VAT_AMOUNT_LC*-1) TAX_VAT_AMOUNT_LC
    from
      ACT_DOCUMENT DOC,
      ACT_FINANCIAL_IMPUTATION FIN,
      ACS_FINANCIAL_CURRENCY FCU,
      ACT_DET_TAX TAX,
      PCS.PC_CURR CUR
    where
      DOC.ACT_DOCUMENT_ID = FIN.ACT_DOCUMENT_ID and
      FIN.ACT_FINANCIAL_IMPUTATION_ID = TAX.ACT_FINANCIAL_IMPUTATION_ID and
      FIN.ACS_TAX_CODE_ID <> ln_acsTaxCodeId and
      DOC.ACT_DOCUMENT_ID = in_document_id and
      DOC.ACS_FINANCIAL_CURRENCY_ID = FCU.ACS_FINANCIAL_CURRENCY_ID and
      FCU.PC_CURR_ID = CUR.PC_CURR_ID
    group by
      DOC.ACT_DOCUMENT_ID,
      FIN.ACS_TAX_CODE_ID,
      TAX.TAX_INCLUDED_EXCLUDED,
      TAX.TAX_RATE,
      TAX.TAX_LIABLED_RATE,
      CUR.CURRENCY
    order by
      TAX_VAT_AMOUNT_LC
  ) loop
    ln_cpt := ln_cpt + 1;
    if (ln_cpt = 1) then
      tpl_actDetTax.TAX_LIABLED_AMOUNT := tpl_actDetTax.TAX_LIABLED_AMOUNT + ln_roundAmount;
    end if;

    lv_currency:= tpl_actDetTax.CURRENCY;

    lt_item_act.pos_number := ln_cpt * 10;
    lt_item_act.act_document_id := tpl_actDetTax.ACT_DOCUMENT_ID;
    lt_item_act.acs_tax_code_id := tpl_actDetTax.ACS_TAX_CODE_ID;
    lt_item_act.tax_rate := tpl_actDetTax.TAX_RATE;
    lt_item_act.tax_liabled_rate := tpl_actDetTax.TAX_LIABLED_RATE;
    lt_item_act.tax_tot_vat_amount_lc := tpl_actDetTax.TAX_TOT_VAT_AMOUNT_LC;
    lt_item_act.tax_vat_amount_lc := tpl_actDetTax.TAX_VAT_AMOUNT_LC;
    lt_item_act.tax_included_excluded := tpl_actDetTax.TAX_INCLUDED_EXCLUDED;
    lt_item_act.tax_liabled_amount := tpl_actDetTax.TAX_LIABLED_AMOUNT;
    lt_item_act.currency := lv_currency;


    PIPE ROW(lt_item_act);
  end loop;

  /* récupération du montant lettré */
  select ise.det_paied_lc
    into ln_detPaiedLc
    from v_act_expiry_isag ise
   where ise.act_document_id  = in_document_id
     and ise.exp_calc_net = 1;

  /* ajout d'une position contenant le montant lettré */
  if abs(ln_detPaiedLc) > 0 then
   ln_cpt := ln_cpt + 1;
   lt_item_act.pos_number := ln_cpt * 10;
   lt_item_act.act_document_id := in_document_id;
   lt_item_act.acs_tax_code_id := ln_acsTaxCodeid;
   lt_item_act.tax_rate := 0;
   lt_item_act.tax_liabled_rate := 100;
   lt_item_act.tax_tot_vat_amount_lc := 0;
   lt_item_act.tax_vat_amount_lc := 0;
   lt_item_act.tax_included_excluded := 'E';
   lt_item_act.tax_liabled_amount := -ln_detPaiedLC;
   lt_item_act.currency := lv_currency;
   PIPE ROW(lt_item_act);
  end if;

  return;

  exception
    when NO_DATA_NEEDED then
      return;
end;

function GetSummary_ACT(
  in_document_id IN act_document.act_document_id%TYPE)
  return TT_ITEM_ACT
  PIPELINED
is
  lt_item_act T_ITEM_ACT;
begin
  select
    Sum(SUMM.TAX_VAT_AMOUNT_LC) TAX_VAT_AMOUNT_LC,
    Sum(SUMM.TAX_LIABLED_AMOUNT) TAX_LIABLED_AMOUNT
  into
    lt_item_act.tax_vat_amount_lc,
    lt_item_act.tax_liabled_amount
  from
    TABLE(com_lib_ebanking_utl.getLineItems_ACT(in_document_id)) SUMM;

  PIPE ROW(lt_item_act);
  return;

  exception
    when NO_DATA_NEEDED then
      return;
end;

function FormatNumber(
  in_number IN NUMBER,
  in_decimals IN INTEGER)
  return VARCHAR2
is
begin
  return to_char(in_number, 'FM999999999999999990.'|| LPad('0', in_decimals, '0'));

  exception
    when OTHERS then
      return '#ERROR formatting number';
end;

END COM_LIB_EBANKING_UTL;
