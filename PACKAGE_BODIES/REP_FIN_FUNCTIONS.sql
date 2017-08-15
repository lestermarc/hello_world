--------------------------------------------------------
--  DDL for Package Body REP_FIN_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_FIN_FUNCTIONS" 
/**
 * Fonctions de génération de document Xml.
 * Spécialisation: Finance et comptabilité (AC...)
 *
 * Package REP_FIN_FUNCTIONS
 * @version 1.0
 * @date 02/2003
 * @author jsomers
 * @author spfister
 * @author pvogel
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
AS

  /**
   * Internal declarations
   */

  TYPE FreeIdCode_T IS TABLE OF VARCHAR2(25) INDEX BY BINARY_INTEGER;
  p_FreeIdCode FreeIdCode_T;


/**
 * Public declarations
 */

function get_acs_fin_acc_s_payment_id(
  description IN acs_description.des_description_summary%TYPE,
  lang IN pcs.pc_lang.lanid%TYPE,
  accnum IN acs_account.acc_number%TYPE)
  return acs_fin_acc_s_payment.acs_fin_acc_s_payment_id%TYPE
is
  ln_result acs_fin_acc_s_payment.acs_fin_acc_s_payment_id%TYPE;
begin
  if (description is not null and lang is not null) then
    select c.acs_fin_acc_s_payment_id
    into ln_result
    from
      acs_account a,
      acs_description b,
      acs_fin_acc_s_payment c,
      acs_payment_method d,
      pcs.pc_lang e
    where
      c.acs_financial_account_id = a.acs_account_id and
      a.acc_number = accnum and
      d.acs_payment_method_id = b.acs_payment_method_id and
      b.pc_lang_id  = e.pc_lang_id and
      e.lanid = lang and
      b.des_description_summary = description and
      d.c_method_category = '3' and
      d.acs_payment_method_id = c.acs_payment_method_id;
    return ln_result;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_vat_det_account_id(
  description IN acs_description.des_description_summary%TYPE,
  cntry IN pcs.pc_cntry.cntid%TYPE,
  lang IN pcs.pc_lang.lanid%TYPE)
  return acs_vat_det_account.acs_vat_det_account_id%TYPE
is
  ln_result acs_vat_det_account.acs_vat_det_account_id%TYPE;
begin
  if (description is not null and cntry is not null and lang is not null) then
    select a.acs_vat_det_account_id
    into ln_result
    from
      acs_vat_det_account a,
      acs_description b,
      pcs.pc_lang c,
      pcs.pc_cntry d
    where
      d.pc_cntry_id = a.pc_cntry_id and
      d.cntid = cntry and
      c.pc_lang_id = b.pc_lang_id and
      c.lanid = lang and
      b.acs_vat_det_account_id = a.acs_vat_det_account_id and
      b.des_description_summary like description;
    return ln_result;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_auxiliary_account_id(
  pac_id IN pac_third.pac_third_id%TYPE,
  lang IN pcs.pc_lang.lanid%TYPE,
  description IN acs_description.des_description_summary%TYPE,
  subset IN acs_sub_set.c_sub_set%TYPE,
  c_partner_category IN pac_supplier_partner.c_partner_category%TYPE,
  group_auxiliary_id IN acs_auxiliary_account.acs_auxiliary_account_id%TYPE,
  auxiliary_id IN acs_auxiliary_account.acs_auxiliary_account_id%TYPE)
  return acs_auxiliary_account.acs_auxiliary_account_id%TYPE
is
  ln_result acs_auxiliary_account.acs_auxiliary_account_id%TYPE := 0;
  ln_subsetid acs_sub_set.acs_sub_set_id%TYPE := null;
begin
  if (lang is not null or description is not null or subset is not null or
      c_partner_category is not null) then
    ln_result := auxiliary_id;
    select c.acs_sub_set_id
    into ln_subsetid
    from
      pcs.pc_lang a,
      acs_description b,
      acs_sub_set c
    where
      a.lanid = lang and
      b.pc_lang_id = a.pc_lang_id and
      b.des_description_summary like description and
      b.acs_sub_set_id = c.acs_sub_set_id and
      c.c_sub_set like subset;

    if (ln_subsetid is not null) then
      pac_partner_management.CreateAuxiliaryAccount(
          pac_id, ln_subsetid, c_partner_category, null, group_auxiliary_id, ln_result);
    end if;
    return ln_result;
  end if;
  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_sub_set_id(
  lang IN pcs.pc_lang.lanid%TYPE,
  description IN acs_description.des_description_summary%TYPE,
  subset IN acs_sub_set.c_sub_set%TYPE)
  return acs_sub_set.acs_sub_set_id%TYPE
is
  ln_result acs_sub_set.acs_sub_set_id%TYPE;
begin
  if (lang is not null and description is not null and subset is not null) then
    select c.acs_sub_set_id
    into ln_result
    from
      pcs.pc_lang a,
      acs_description b,
      acs_sub_set c
    where
      a.lanid = lang and
      b.pc_lang_id = a.pc_lang_id and
      b.des_description_summary like description and
      b.acs_sub_set_id = c.acs_sub_set_id and
      c.c_sub_set like subset;
    return ln_result;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;


--
-- Comptes
--

function get_acs_description_account(
  Id IN acs_account.acs_account_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_ACCOUNT_ID,PC_LANG_ID' as TABLE_KEY,
        d.acs_description_id,
        l.lanid,
        d.des_description_summary,
        d.des_description_large,
        d.des_text)
    )) into lx_data
  from pcs.pc_lang l, acs_description d
  where d.acs_account_id = Id and l.pc_lang_id = d.pc_lang_id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACS_DESCRIPTION,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
  end if;

  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_vat_rate(
  Id IN acs_account.acs_account_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_TAX_CODE_ID,VAT_RATE,VAT_SINCE,VAT_TO' as TABLE_KEY,
        acs_vat_rate_id,
        vat_rate,
        to_char(vat_since) as VAT_SINCE,
        to_char(vat_to) as VAT_TO),
      rep_pc_functions.get_com_vfields_record(acs_vat_rate_id,'ACS_VAT_RATE'),
      rep_pc_functions.get_com_vfields_value(acs_vat_rate_id,'ACS_VAT_RATE')
    )) into lx_data
  from acs_vat_rate
  where acs_tax_code_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACS_VAT_RATE,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
  end if;

  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_tax_code(
  Id IN acs_account.acs_account_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(ACS_TAX_CODE,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_TAX_CODE_ID' as TABLE_KEY,
        'ACS_TAX_CODE_ID=ACS_ACCOUNT_ID' as TABLE_MAPPING,
        acs_tax_code_id,
        tax_rate,
        tax_rounded_amount,
        tax_liabled_rate),
      rep_pc_functions.get_descodes('C_TYPE_TAX',c_type_tax),
      rep_pc_functions.get_descodes('C_ROUND_TYPE',c_round_type),
      rep_pc_functions.get_descodes('C_ESTABLISHING_CALC_SHEET',c_establishing_calc_sheet),
      rep_pc_functions.get_dictionary('DIC_TYPE_SUBMISSION',dic_type_submission_id),
      rep_pc_functions.get_dictionary('DIC_TYPE_MOVEMENT',dic_type_movement_id),
      rep_pc_functions.get_dictionary('DIC_TYPE_VAT_GOOD',dic_type_vat_good_id),
      rep_pc_functions.get_dictionary('DIC_NO_POS_CALC_SHEET',dic_no_pos_calc_sheet_id),
      rep_pc_functions.get_dictionary('DIC_NO_POS_CALC_SHEET2',dic_no_pos_calc_sheet2_id,'DIC_NO_POS_CALC_SHEET'),
      rep_pc_functions.get_dictionary('DIC_NO_POS_CALC_SHEET3',dic_no_pos_calc_sheet3_id,'DIC_NO_POS_CALC_SHEET'),
      rep_fin_functions_link.get_acs_fin_account_link(acs_prea_account_id,'ACS_PREA_ACCOUNT'),
      rep_fin_functions_link.get_acs_fin_account_link(acs_prov_account_id,'ACS_PROV_ACCOUNT'),
      rep_fin_functions_link.get_acs_vat_det_account_link(acs_vat_det_account_id),
      rep_fin_functions_link.get_acs_tax_code_link(acs_tax_code1_id,'ACS_TAX_CODE1'),
      rep_fin_functions_link.get_acs_tax_code_link(acs_tax_code2_id,'ACS_TAX_CODE2'),
      rep_fin_functions.get_acs_vat_rate(acs_tax_code_id),
      rep_fin_functions_link.get_acs_fin_account_link(acs_nonded_account_id,'ACS_NONDED_ACCOUNT'),
      XMLForest(
        tax_deductible_rate),
      rep_pc_functions.get_descodes('C_ROUND_TYPE_DOC',c_round_type_doc,'C_ROUND_TYPE'),
      XMLForest(
        tax_rounded_amount_doc),
      rep_pc_functions.get_descodes('C_ROUND_TYPE_DOC_FOO',c_round_type_doc_foo,'C_ROUND_TYPE'),
      XMLForest(
        tax_rounded_amount_doc_foo),
      rep_pc_functions.get_com_vfields_record(acs_tax_code_id,'ACS_TAX_CODE'),
      rep_pc_functions.get_com_vfields_value(acs_tax_code_id,'ACS_TAX_CODE')
    ) into lx_data
  from acs_tax_code
  where acs_tax_code_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_fin_account_s_fin_curr(
  Id IN acs_account.acs_account_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_FINANCIAL_ACCOUNT_ID,ACS_FINANCIAL_CURRENCY_ID' as TABLE_KEY,
        fsc_default),
      rep_fin_functions_link.get_acs_fin_curr_link(acs_financial_currency_id,'ACS_FINANCIAL_CURRENCY',1)
    )) into lx_data
  from acs_fin_account_s_fin_curr
  where acs_financial_account_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACS_FIN_ACCOUNT_S_FIN_CURR,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_financial_account(
  Id IN acs_account.acs_account_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(ACS_FINANCIAL_ACCOUNT,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_FINANCIAL_ACCOUNT_ID' as TABLE_KEY,
        'ACS_FINANCIAL_ACCOUNT_ID=ACS_ACCOUNT_ID' as TABLE_MAPPING,
        acs_financial_account_id),
      rep_pc_functions.get_descodes('C_BALANCE_SHEET_PROFIT_LOSS',c_balance_sheet_profit_loss),
      rep_pc_functions.get_descodes('C_BALANCE_DISPLAY',c_balance_display),
      rep_pc_functions.get_descodes('C_DAS2_BREAKDOWN',c_das2_breakdown),
      rep_pc_functions.get_descodes('C_DEBIT_CREDIT',c_debit_credit),
      XMLForest(
        fin_collective,
        fin_etab_account,
        fin_vat_possible,
        fin_credit_limit,
        to_char(fin_expiration_limit) as FIN_EXPIRATION_LIMIT,
        fin_account_control,
        fin_liquidity,
        fin_portfolio),
      rep_pc_functions.get_dictionary('DIC_FIN_ACC_CODE_1',dic_fin_acc_code_1_id),
      rep_pc_functions.get_dictionary('DIC_FIN_ACC_CODE_2',dic_fin_acc_code_2_id),
      rep_pc_functions.get_dictionary('DIC_FIN_ACC_CODE_3',dic_fin_acc_code_3_id),
      rep_pc_functions.get_dictionary('DIC_FIN_ACC_CODE_4',dic_fin_acc_code_4_id),
      rep_pc_functions.get_dictionary('DIC_FIN_ACC_CODE_5',dic_fin_acc_code_5_id),
      rep_pc_functions.get_dictionary('DIC_FIN_ACC_CODE_6',dic_fin_acc_code_6_id),
      rep_pc_functions.get_dictionary('DIC_FIN_ACC_CODE_7',dic_fin_acc_code_7_id),
      rep_pc_functions.get_dictionary('DIC_FIN_ACC_CODE_8',dic_fin_acc_code_8_id),
      rep_pc_functions.get_dictionary('DIC_FIN_ACC_CODE_9',dic_fin_acc_code_9_id),
      rep_pc_functions.get_dictionary('DIC_FIN_ACC_CODE_10',dic_fin_acc_code_10_id),
      rep_pc_functions.get_dictionary('DIC_TYPE_LIMIT',dic_type_limit_id),
      rep_pc_functions.get_dictionary('DIC_TYPE_VAT_GOOD',dic_type_vat_good_id),
      rep_pc_functions_link.get_pc_bank_link(pc_bank_id),
      rep_fin_functions.get_acs_fin_account_s_fin_curr(acs_financial_account_id),
      rep_fin_functions_link.get_acs_cpn_account_link(acs_cpn_account_id, 'ACS_CPN_ACCOUNT'),
      rep_fin_functions_link.get_acs_tax_code_link(acs_def_vat_code_id,'ACS_DEF_VAT_CODE'),
      rep_fin_functions_link.get_acs_fin_curr_link(acs_limit_curr_id,'ACS_LIMIT_CURR'),
      rep_fin_functions.get_acs_interaction_financial(acs_financial_account_id),
      rep_fin_functions.get_acs_fin_mgm_interaction(acs_financial_account_id),
      rep_pc_functions.get_com_vfields_record(acs_financial_account_id,'ACS_FINANCIAL_ACCOUNT'),
      rep_pc_functions.get_com_vfields_value(acs_financial_account_id,'ACS_FINANCIAL_ACCOUNT')
    ) into lx_data
  from acs_financial_account
  where acs_financial_account_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_division_account(
  Id IN acs_account.acs_account_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(ACS_DIVISION_ACCOUNT,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_DIVISION_ACCOUNT_ID' as TABLE_KEY,
        'ACS_DIVISION_ACCOUNT_ID=ACS_ACCOUNT_ID' as TABLE_MAPPING,
        acs_division_account_id,
        div_default_account),
      rep_pc_functions.get_dictionary('DIC_DIV_ACC_CODE_1',dic_div_acc_code_1_id),
      rep_pc_functions.get_dictionary('DIC_DIV_ACC_CODE_2',dic_div_acc_code_2_id),
      rep_pc_functions.get_dictionary('DIC_DIV_ACC_CODE_3',dic_div_acc_code_3_id),
      rep_pc_functions.get_dictionary('DIC_DIV_ACC_CODE_4',dic_div_acc_code_4_id),
      rep_pc_functions.get_dictionary('DIC_DIV_ACC_CODE_5',dic_div_acc_code_5_id),
      rep_pc_functions.get_dictionary('DIC_DIV_ACC_CODE_6',dic_div_acc_code_6_id),
      rep_pc_functions.get_dictionary('DIC_DIV_ACC_CODE_7',dic_div_acc_code_7_id),
      rep_pc_functions.get_dictionary('DIC_DIV_ACC_CODE_8',dic_div_acc_code_8_id),
      rep_pc_functions.get_dictionary('DIC_DIV_ACC_CODE_9',dic_div_acc_code_9_id),
      rep_pc_functions.get_dictionary('DIC_DIV_ACC_CODE_10',dic_div_acc_code_10_id),
      rep_fin_functions.get_acs_interaction_division(acs_division_account_id),
      rep_pc_functions.get_com_vfields_record(acs_division_account_id,'ACS_DIVISION_ACCOUNT'),
      rep_pc_functions.get_com_vfields_value(acs_division_account_id,'ACS_DIVISION_ACCOUNT')
    ) into lx_data
  from acs_division_account
  where acs_division_account_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_interaction_division(
  Id IN acs_account.acs_account_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_DIVISION_ACCOUNT_ID' as TABLE_KEY,
        int_pair_default,
        to_char(int_valid_since) as INT_VALID_SINCE,
        to_char(int_valid_to) as INT_VALID_TO),
      rep_fin_functions_link.get_acs_fin_account_link(acs_financial_account_id,'ACS_FINANCIAL_ACCOUNT')
    )) into lx_data
  from acs_interaction
  where acs_division_account_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACS_INTERACTION,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_interaction_financial(
  Id IN acs_account.acs_account_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_FINANCIAL_ACCOUNT_ID' as TABLE_KEY,
        int_pair_default,
        to_char(int_valid_since) as INT_VALID_SINCE,
        to_char(int_valid_to) as INT_VALID_TO),
      rep_fin_functions_link.get_acs_div_account_link(acs_division_account_id,'ACS_DIVISION_ACCOUNT')
    )) into lx_data
  from acs_interaction
  where acs_financial_account_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACS_INTERACTION,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;


function get_acs_fin_mgm_interaction(
  Id IN acs_account.acs_account_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_FINANCIAL_ACCOUNT_ID,ACS_CPN_ACCOUNT_ID' as TABLE_KEY,
        fmi_default,
        to_char(fmi_valid_since) as FMI_VALID_SINCE,
        to_char(fmi_valid_to) as FMI_VALID_TO),
      rep_fin_functions_link.get_acs_cpn_account_link(acs_cpn_account_id,'ACS_CPN_ACCOUNT')
    )) into lx_data
  from acs_fin_mgm_interaction
  where acs_financial_account_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACS_FIN_MGM_INTERACTION,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_qty_unit_cpn_account(
  Id IN acs_account.acs_account_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_QTY_UNIT_ID' as TABLE_KEY,
        acs_qty_s_cpn_acount_id,
        qta_quantity,
        qta_amount,
        to_char(qta_from) as QTA_FROM,
        to_char(qta_to) as QTA_TO,
        qta_default),
      rep_pc_functions.get_descodes('C_AUTHORIZATION_TYPE',c_authorization_type),
      rep_fin_functions_link.get_acs_cpn_account_link(acs_cpn_account_id, 'ACS_CPN_ACCOUNT')
    )) into lx_data
  from acs_qty_s_cpn_acount
  where acs_qty_unit_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACS_QTY_S_CPN_ACOUNT,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_interaction_cpn(
  Id IN acs_account.acs_account_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_CPN_ACCOUNT_ID, ACS_CDA_ACCOUNT_ID, ACS_PF_ACCOUNT_ID, ACS_PJ_ACCOUNT_ID' as TABLE_KEY,
        mgm_default,
        to_char(mgm_valid_since) as MGM_VALID_SINCE,
        to_char(mgm_valid_to) as MGM_VALID_TO),
      rep_fin_functions_link.get_acs_cda_account_link(acs_cda_account_id),
      rep_fin_functions_link.get_acs_pf_account_link(acs_pf_account_id),
      rep_fin_functions_link.get_acs_pj_account_link(acs_pj_account_id)
    )) into lx_data
  from acs_mgm_interaction
  where acs_cpn_account_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACS_MGM_INTERACTION,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_interaction_cda(
  Id IN acs_account.acs_account_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_CPN_ACCOUNT_ID, ACS_CDA_ACCOUNT_ID, ACS_PF_ACCOUNT_ID, ACS_PJ_ACCOUNT_ID' as TABLE_KEY,
        mgm_default,
        to_char(mgm_valid_since) as MGM_VALID_SINCE,
        to_char(mgm_valid_to) as MGM_VALID_TO),
      rep_fin_functions_link.get_acs_cpn_account_link(acs_cpn_account_id, 'ACS_CPN_ACCOUNT'),
      rep_fin_functions_link.get_acs_cda_account_link(acs_cda_account_id)
    )) into lx_data
  from acs_mgm_interaction
  where acs_cda_account_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACS_MGM_INTERACTION,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_interaction_pf(
  Id IN acs_account.acs_account_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_CPN_ACCOUNT_ID, ACS_CDA_ACCOUNT_ID, ACS_PF_ACCOUNT_ID, ACS_PJ_ACCOUNT_ID' as TABLE_KEY,
        mgm_default,
        to_char(mgm_valid_since) as MGM_VALID_SINCE,
        to_char(mgm_valid_to) as MGM_VALID_TO),
      rep_fin_functions_link.get_acs_cpn_account_link(acs_cpn_account_id, 'ACS_CPN_ACCOUNT'),
      rep_fin_functions_link.get_acs_pf_account_link(acs_pf_account_id)
    )) into lx_data
  from acs_mgm_interaction
  where acs_pf_account_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACS_MGM_INTERACTION,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_interaction_pj(
  Id IN acs_account.acs_account_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_CPN_ACCOUNT_ID, ACS_CDA_ACCOUNT_ID, ACS_PF_ACCOUNT_ID, ACS_PJ_ACCOUNT_ID' as TABLE_KEY,
        mgm_default,
        to_char(mgm_valid_since) as MGM_VALID_SINCE,
        to_char(mgm_valid_to) as MGM_VALID_TO),
      rep_fin_functions_link.get_acs_cpn_account_link(acs_cpn_account_id, 'ACS_CPN_ACCOUNT'),
      rep_fin_functions_link.get_acs_pj_account_link(acs_pj_account_id)
    )) into lx_data
  from acs_mgm_interaction
  where acs_pj_account_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACS_MGM_INTERACTION,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_cpn_account_currency(
  Id IN acs_account.acs_account_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_CPN_ACCOUNT_ID,ACS_FINANCIAL_CURRENCY_ID' as TABLE_KEY),
      rep_fin_functions_link.get_acs_fin_curr_link(acs_financial_currency_id,'ACS_FINANCIAL_CURRENCY',1)
    )) into lx_data
  from acs_cpn_account_currency
  where acs_cpn_account_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACS_CPN_ACCOUNT_CURRENCY,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_cpn_variance(
  Id IN acs_cpn_account.acs_cpn_account_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(ACS_CPN_VARIANCE,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_CPN_VARIANCE_ID' as TABLE_KEY,
        'ACS_CPN_ACCOUNT_ID=ACS_CPN_VARIANCE_ID' as TABLE_MAPPING,
        acs_cpn_variance_id),
      rep_fin_functions_link.get_acs_cpn_account_link(acs_cpn_credit_value_id, 'ACS_CPN_CREDIT_VALUE'),
      rep_fin_functions_link.get_acs_cpn_account_link(acs_cpn_credit_qty_id, 'ACS_CPN_CREDIT_QTY'),
      rep_fin_functions_link.get_acs_cpn_account_link(acs_cpn_debit_value_id, 'ACS_CPN_DEBIT_VALUE'),
      rep_fin_functions_link.get_acs_cpn_account_link(acs_cpn_debit_qty_id, 'ACS_CPN_DEBIT_QTY')
    ) into lx_data
  from acs_cpn_variance
  where acs_cpn_variance_id = Id
    and (acs_cpn_credit_value_id is not null or
         acs_cpn_credit_qty_id is not null or
         acs_cpn_debit_value_id is not null or
         acs_cpn_debit_qty_id is not null);
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_cpn_account(
  Id IN acs_account.acs_account_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(ACS_CPN_ACCOUNT,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_CPN_ACCOUNT_ID' as TABLE_KEY,
        'ACS_CPN_ACCOUNT_ID=ACS_ACCOUNT_ID' as TABLE_MAPPING,
        acs_cpn_account_id,
        mgm_rate1, mgm_rate2, mgm_rate3, mgm_rate4, mgm_rate5,
        mgm_rate6, mgm_rate7, mgm_rate8, mgm_rate9,mgm_rate10,
        mgm_amount1, mgm_amount2, mgm_amount3, mgm_amount4, mgm_amount5,
        mgm_amount6, mgm_amount7, mgm_amount8, mgm_amount9, mgm_amount10),
      rep_pc_functions.get_descodes('C_CDA_IMPUTATION',c_cda_imputation),
      rep_pc_functions.get_descodes('C_PF_IMPUTATION',c_pf_imputation),
      rep_pc_functions.get_descodes('C_PJ_IMPUTATION',c_pj_imputation),
      rep_pc_functions.get_descodes('C_EXPENSE_RECEIPT',c_expense_receipt),
      rep_pc_functions.get_dictionary('DIC_CPN_FREECODE1',dic_cpn_freecode1_id),
      rep_pc_functions.get_dictionary('DIC_CPN_FREECODE2',dic_cpn_freecode2_id),
      rep_pc_functions.get_dictionary('DIC_CPN_FREECODE3',dic_cpn_freecode3_id),
      rep_pc_functions.get_dictionary('DIC_CPN_FREECODE4',dic_cpn_freecode4_id),
      rep_pc_functions.get_dictionary('DIC_CPN_FREECODE5',dic_cpn_freecode5_id),
      rep_pc_functions.get_dictionary('DIC_CPN_FREECODE6',dic_cpn_freecode6_id),
      rep_pc_functions.get_dictionary('DIC_CPN_FREECODE7',dic_cpn_freecode7_id),
      rep_pc_functions.get_dictionary('DIC_CPN_FREECODE8',dic_cpn_freecode8_id),
      rep_pc_functions.get_dictionary('DIC_CPN_FREECODE9',dic_cpn_freecode9_id),
      rep_pc_functions.get_dictionary('DIC_CPN_FREECODE10',dic_cpn_freecode10_id),
      rep_hrm_functions_link.get_hrm_person_link(hrm_employee_id,'HRM_EMPLOYEE'),
      rep_fin_functions.get_acs_cpn_account_currency(acs_cpn_account_id),
      rep_fin_functions.get_acs_cpn_variance(acs_cpn_account_id),
      rep_fin_functions.get_acs_interaction_cpn(acs_cpn_account_id),
      rep_pc_functions.get_com_vfields_record(acs_cpn_account_id,'ACS_CPN_ACCOUNT'),
      rep_pc_functions.get_com_vfields_value(acs_cpn_account_id,'ACS_CPN_ACCOUNT')
    ) into lx_data
  from acs_cpn_account
  where acs_cpn_account_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_cda_account(
  Id IN acs_account.acs_account_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(ACS_CDA_ACCOUNT,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_CDA_ACCOUNT_ID' as TABLE_KEY,
        'ACS_CDA_ACCOUNT_ID=ACS_ACCOUNT_ID' as TABLE_MAPPING,
        acs_cda_account_id,
        mgm_rate1, mgm_rate2, mgm_rate3, mgm_rate4, mgm_rate5,
        mgm_rate6, mgm_rate7, mgm_rate8, mgm_rate9, mgm_rate10,
        mgm_amount1, mgm_amount2, mgm_amount3, mgm_amount4, mgm_amount5,
        mgm_amount6, mgm_amount7, mgm_amount8, mgm_amount9, mgm_amount10),
      rep_pc_functions.get_descodes('C_CENTER_TYPE',c_center_type),
      rep_pc_functions.get_dictionary('DIC_CDA_FREECODE1',dic_cda_freecode1_id),
      rep_pc_functions.get_dictionary('DIC_CDA_FREECODE2',dic_cda_freecode2_id),
      rep_pc_functions.get_dictionary('DIC_CDA_FREECODE3',dic_cda_freecode3_id),
      rep_pc_functions.get_dictionary('DIC_CDA_FREECODE4',dic_cda_freecode4_id),
      rep_pc_functions.get_dictionary('DIC_CDA_FREECODE5',dic_cda_freecode5_id),
      rep_pc_functions.get_dictionary('DIC_CDA_FREECODE6',dic_cda_freecode6_id),
      rep_pc_functions.get_dictionary('DIC_CDA_FREECODE7',dic_cda_freecode7_id),
      rep_pc_functions.get_dictionary('DIC_CDA_FREECODE8',dic_cda_freecode8_id),
      rep_pc_functions.get_dictionary('DIC_CDA_FREECODE9',dic_cda_freecode9_id),
      rep_pc_functions.get_dictionary('DIC_CDA_FREECODE10',dic_cda_freecode10_id),
      rep_hrm_functions_link.get_hrm_person_link(hrm_employee_id,'HRM_EMPLOYEE'),
      rep_fin_functions.get_acs_interaction_cda(acs_cda_account_id),
      rep_pc_functions.get_com_vfields_record(acs_cda_account_id,'ACS_CDA_ACCOUNT'),
      rep_pc_functions.get_com_vfields_value(acs_cda_account_id,'ACS_CDA_ACCOUNT')
    ) into lx_data
  from acs_cda_account
  where acs_cda_account_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_pf_account(
  Id IN acs_account.acs_account_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(ACS_PF_ACCOUNT,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_PF_ACCOUNT_ID' as TABLE_KEY,
        'ACS_PF_ACCOUNT_ID=ACS_ACCOUNT_ID' as TABLE_MAPPING,
        acs_pf_account_id,
        mgm_rate1, mgm_rate2, mgm_rate3, mgm_rate4, mgm_rate5,
        mgm_rate6, mgm_rate7, mgm_rate8, mgm_rate9, mgm_rate10,
        mgm_amount1, mgm_amount2, mgm_amount3, mgm_amount4, mgm_amount5,
        mgm_amount6, mgm_amount7, mgm_amount8, mgm_amount9, mgm_amount10),
      rep_pc_functions.get_dictionary('DIC_PF_FREECODE1',dic_pf_freecode1_id),
      rep_pc_functions.get_dictionary('DIC_PF_FREECODE2',dic_pf_freecode2_id),
      rep_pc_functions.get_dictionary('DIC_PF_FREECODE3',dic_pf_freecode3_id),
      rep_pc_functions.get_dictionary('DIC_PF_FREECODE4',dic_pf_freecode4_id),
      rep_pc_functions.get_dictionary('DIC_PF_FREECODE5',dic_pf_freecode5_id),
      rep_pc_functions.get_dictionary('DIC_PF_FREECODE6',dic_pf_freecode6_id),
      rep_pc_functions.get_dictionary('DIC_PF_FREECODE7',dic_pf_freecode7_id),
      rep_pc_functions.get_dictionary('DIC_PF_FREECODE8',dic_pf_freecode8_id),
      rep_pc_functions.get_dictionary('DIC_PF_FREECODE9',dic_pf_freecode9_id),
      rep_pc_functions.get_dictionary('DIC_PF_FREECODE10',dic_pf_freecode10_id),
      rep_hrm_functions_link.get_hrm_person_link(hrm_employee_id,'HRM_EMPLOYEE'),
      rep_fin_functions.get_acs_interaction_pf(acs_pf_account_id),
      rep_pc_functions.get_com_vfields_record(acs_pf_account_id,'ACS_PF_ACCOUNT'),
      rep_pc_functions.get_com_vfields_value(acs_pf_account_id,'ACS_PF_ACCOUNT')
    ) into lx_data
  from acs_pf_account
  where acs_pf_account_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_pj_account(
  Id IN acs_account.acs_account_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(ACS_PJ_ACCOUNT,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_PJ_ACCOUNT_ID' as TABLE_KEY,
        'ACS_PJ_ACCOUNT_ID=ACS_ACCOUNT_ID' as TABLE_MAPPING,
        acs_pj_account_id,
        mgm_transfer,
        mgm_rate1, mgm_rate2, mgm_rate3, mgm_rate4, mgm_rate5,
        mgm_rate6, mgm_rate7, mgm_rate8, mgm_rate9, mgm_rate10,
        mgm_amount1, mgm_amount2, mgm_amount3, mgm_amount4, mgm_amount5,
        mgm_amount6, mgm_amount7, mgm_amount8, mgm_amount9, mgm_amount10),
      rep_pc_functions.get_dictionary('DIC_PJ_FREECODE1',dic_pj_freecode1_id),
      rep_pc_functions.get_dictionary('DIC_PJ_FREECODE2',dic_pj_freecode2_id),
      rep_pc_functions.get_dictionary('DIC_PJ_FREECODE3',dic_pj_freecode3_id),
      rep_pc_functions.get_dictionary('DIC_PJ_FREECODE4',dic_pj_freecode4_id),
      rep_pc_functions.get_dictionary('DIC_PJ_FREECODE5',dic_pj_freecode5_id),
      rep_pc_functions.get_dictionary('DIC_PJ_FREECODE6',dic_pj_freecode6_id),
      rep_pc_functions.get_dictionary('DIC_PJ_FREECODE7',dic_pj_freecode7_id),
      rep_pc_functions.get_dictionary('DIC_PJ_FREECODE8',dic_pj_freecode8_id),
      rep_pc_functions.get_dictionary('DIC_PJ_FREECODE9',dic_pj_freecode9_id),
      rep_pc_functions.get_dictionary('DIC_PJ_FREECODE10',dic_pj_freecode10_id),
      rep_pac_functions_link.get_pac_person_link(pac_person_id,'PAC_PERSON',0),
      rep_hrm_functions_link.get_hrm_person_link(hrm_employee_id,'HRM_EMPLOYEE'),
      rep_fin_functions.get_acs_interaction_pj(acs_pj_account_id),
      rep_pc_functions.get_com_vfields_record(acs_pj_account_id,'ACS_PJ_ACCOUNT'),
      rep_pc_functions.get_com_vfields_value(acs_pj_account_id,'ACS_PJ_ACCOUNT')
    ) into lx_data
  from acs_pj_account
  where acs_pj_account_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_qty_unit(
  Id IN acs_account.acs_account_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(ACS_QTY_UNIT,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_QTY_UNIT_ID' as TABLE_KEY,
        'ACS_QTY_UNIT_ID=ACS_ACCOUNT_ID' as TABLE_MAPPING,
        acs_qty_unit_id,
        qty_quantity,
        qty_amount),
      rep_fin_functions.get_acs_qty_unit_cpn_account(acs_qty_unit_id),
      rep_hrm_functions_link.get_hrm_person_link(hrm_person_id),
      rep_pc_functions.get_com_vfields_record(acs_qty_unit_id,'ACS_QTY_UNIT'),
      rep_pc_functions.get_com_vfields_value(acs_qty_unit_id,'ACS_QTY_UNIT')
    ) into lx_data
  from acs_qty_unit
  where acs_qty_unit_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_account_xml(
  Id IN acs_account.acs_account_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ACCOUNTS,
      XMLElement(ACS_ACCOUNT,
        XMLAttributes(
          acs_account_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'ACC_NUMBER,ACS_SUB_SET_ID,C_VALID' as TABLE_KEY,
          acs_account_id),
        rep_fin_functions_link.get_acs_sub_set_link(acs_sub_set_id),
        rep_pc_functions.get_descodes('C_VALID',c_valid),
        XMLForest(
          acc_number,
          acc_detail_printing,
          acc_blocked,
          acc_interest,
          acc_transaction,
          acc_budget,
          to_char(acc_valid_since) as ACC_VALID_SINCE,
          to_char(acc_valid_to) as ACC_VALID_TO),
        rep_pac_functions_link.get_pac_person_link(pac_person_id,'PAC_PERSON',0),
        rep_fin_functions.get_acs_description_account(acs_account_id),
        rep_fin_functions_link.get_acs_sub_account_link(acs_account_id),
        rep_fin_functions.get_acs_tax_code(acs_account_id),
        -- L'ordre des comptes analytiques ci-dessous ne doit pas changer
        -- car la création du CPN a lieu en premier. Il ne faut pas qu'un autre compte aille chercher un CPN qui n'existe
        rep_fin_functions.get_acs_cpn_account(acs_account_id),
        rep_fin_functions.get_acs_cda_account(acs_account_id),
        rep_fin_functions.get_acs_pf_account(acs_account_id),
        rep_fin_functions.get_acs_pj_account(acs_account_id),
        rep_fin_functions.get_acs_qty_unit(acs_account_id),
        rep_fin_functions.get_acs_financial_account(acs_account_id),
        rep_fin_functions.get_acs_division_account(acs_account_id),
        rep_pc_functions.get_com_vfields_record(acs_account_id,'ACS_ACCOUNT'),
        rep_pc_functions.get_com_vfields_value(acs_account_id,'ACS_ACCOUNT')
      )
    ) into lx_data
  from acs_account
  where acs_account_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(ACCOUNTS,
          XMLElement(ACS_ACCOUNT,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;


--
-- Méthodes de réévaluation
--

function get_acs_evaluation_method_xml(
  Id IN acs_evaluation_method.acs_evaluation_method_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(EVALUATION_METHODS,
      XMLElement(ACS_EVALUATION_METHOD,
        XMLAttributes(
          acs_evaluation_method_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'EVA_DESCR' as TABLE_KEY,
          acs_evaluation_method_id,
          eva_descr,
          eva_comment,
          eva_imf_description),
        rep_pc_functions.get_descodes('C_EVALUATION_METHOD',c_evaluation_method),
        rep_pc_functions.get_descodes('C_DOC_GENERATION',c_doc_generation),
        rep_pc_functions.get_descodes('C_RATE_TYP',c_rate_typ),
        rep_fin_functions.get_acs_evaluation_cumul(acs_evaluation_method_id),
        rep_fin_functions.get_acs_evaluation_account(acs_evaluation_method_id),
        rep_pc_functions.get_com_vfields_record(acs_evaluation_method_id,'ACS_EVALUATION_METHOD'),
        rep_pc_functions.get_com_vfields_value(acs_evaluation_method_id,'ACS_EVALUATION_METHOD')
      )
    ) into lx_data
  from acs_evaluation_method
  where acs_evaluation_method_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(EVALUATION_METHODS,
          XMLElement(ACS_EVALUATION_METHOD,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_acs_evaluation_cumul(
  Id IN acs_evaluation_method.acs_evaluation_method_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_EVALUATION_METHOD_ID' as TABLE_KEY,
        acs_evaluation_cumul_id),
      rep_pc_functions.get_descodes('C_TYPE_CUMUL',c_type_cumul)
    )) into lx_data
  from acs_evaluation_cumul
  where acs_evaluation_method_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACS_EVALUATION_CUMUL,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_evaluation_account(
  Id IN acs_evaluation_method.acs_evaluation_method_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_EVALUATION_METHOD_ID' as TABLE_KEY),
      rep_fin_functions_link.get_acs_fin_curr_link(acs_financial_currency_id),
      rep_fin_functions_link.get_acs_account_link(acs_financial_account_id,'ACS_FINANCIAL_ACCOUNT'),
      rep_fin_functions_link.get_acs_account_link(acs_division_account_id ,'ACS_DIVISION_ACCOUNT'),
      rep_fin_functions_link.get_acs_account_link(acs_fin_acc_id,'ACS_FINANCIAL_ACCOUNT','ACS_FIN_ACC'),
      rep_fin_functions_link.get_acs_account_link(acs_div_acc_id,'ACS_DIVISION_ACCOUNT','ACS_DIV_ACC'),
      rep_fin_functions_link.get_acs_account_link(acs_fin_gain_id,'ACS_FINANCIAL_ACCOUNT','ACS_FIN_GAIN'),
      rep_fin_functions_link.get_acs_account_link(acs_div_gain_id,'ACS_DIVISION_ACCOUNT','ACS_DIV_GAIN'),
      rep_fin_functions_link.get_acs_account_link(acs_cpn_gain_id,'ACS_CPN_ACCOUNT','ACS_CPN_GAIN'),
      rep_fin_functions_link.get_acs_account_link(acs_cda_gain_id,'ACS_CDA_ACCOUNT','ACS_CDA_GAIN'),
      rep_fin_functions_link.get_acs_account_link(acs_pf_gain_id ,'ACS_PF_ACCOUNT','ACS_PF_GAIN'),
      rep_fin_functions_link.get_acs_account_link(acs_pj_gain_id ,'ACS_PJ_ACCOUNT','ACS_PJ_GAIN'),
      rep_fin_functions_link.get_acs_account_link(acs_fin_loss_id,'ACS_FINANCIAL_ACCOUNT','ACS_FIN_LOSS'),
      rep_fin_functions_link.get_acs_account_link(acs_div_loss_id,'ACS_DIVISION_ACCOUNT','ACS_DIV_LOSS'),
      rep_fin_functions_link.get_acs_account_link(acs_cpn_loss_id,'ACS_CPN_ACCOUNT','ACS_CPN_LOSS'),
      rep_fin_functions_link.get_acs_account_link(acs_cda_loss_id,'ACS_CDA_ACCOUNT','ACS_CDA_LOSS'),
      rep_fin_functions_link.get_acs_account_link(acs_pf_loss_id ,'ACS_PF_ACCOUNT','ACS_PF_LOSS'),
      rep_fin_functions_link.get_acs_account_link(acs_pj_loss_id ,'ACS_PJ_ACCOUNT','ACS_PJ_LOSS'),
      rep_fin_functions_link.get_acs_account_link(acs_cpn_loss_debt_id,'ACS_CPN_ACCOUNT','ACS_CPN_LOSS_DEBT'),
      rep_fin_functions_link.get_acs_account_link(acs_cda_loss_debt_id,'ACS_CDA_ACCOUNT','ACS_CDA_LOSS_DEBT'),
      rep_fin_functions_link.get_acs_account_link(acs_pf_loss_debt_id ,'ACS_PF_ACCOUNT','ACS_PF_LOSS_DEBT'),
      rep_fin_functions_link.get_acs_account_link(acs_pj_loss_debt_id ,'ACS_PJ_ACCOUNT','ACS_PJ_LOSS_DEBT'),
      rep_fin_functions_link.get_acs_account_link(acs_cpn_gain_debt_id,'ACS_CPN_ACCOUNT','ACS_CPN_GAIN_DEBT'),
      rep_fin_functions_link.get_acs_account_link(acs_cda_gain_debt_id,'ACS_CDA_ACCOUNT','ACS_CDA_GAIN_DEBT'),
      rep_fin_functions_link.get_acs_account_link(acs_pf_gain_debt_id ,'ACS_PF_ACCOUNT','ACS_PF_GAIN_DEBT'),
      rep_fin_functions_link.get_acs_account_link(acs_pj_gain_debt_id ,'ACS_PJ_ACCOUNT','ACS_PJ_GAIN_DEBT'),
      rep_fin_functions_link.get_acs_account_link(acs_acc_loss_debt_id,'ACS_FINANCIAL_ACCOUNT','ACS_ACC_LOSS_DEBT'),
      rep_fin_functions_link.get_acs_account_link(acs_div_loss_debt_id,'ACS_DIVISION_ACCOUNT','ACS_DIV_LOSS_DEBT'),
      rep_fin_functions_link.get_acs_account_link(acs_acc_gain_debt_id,'ACS_FINANCIAL_ACCOUNT','ACS_ACC_GAIN_DEBT'),
      rep_fin_functions_link.get_acs_account_link(acs_div_gain_debt_id,'ACS_DIVISION_ACCOUNT','ACS_DIV_GAIN_DEBT')
    )) into lx_data
  from acs_evaluation_account
  where acs_evaluation_method_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACS_EVALUATION_ACCOUNT,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;


--
-- Catégories d'intérêt
--

function get_acs_interest_categ_xml(
  Id IN acs_interest_categ.acs_interest_categ_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(INTEREST_CATEGS,
      XMLElement(ACS_INTEREST_CATEG,
        XMLAttributes(
          acs_interest_categ_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'ICA_DESCRIPTION' as TABLE_KEY,
          acs_interest_categ_id,
          ica_description),
        rep_fin_functions.get_acs_interest_elem(acs_interest_categ_id),
        rep_fin_functions.get_acs_adv_tax_elem(acs_interest_categ_id),
        rep_pc_functions.get_com_vfields_record(acs_interest_categ_id,'ACS_INTEREST_CATEG'),
        rep_pc_functions.get_com_vfields_value(acs_interest_categ_id,'ACS_INTEREST_CATEG')
      )
    ) into lx_data
  from acs_interest_categ
  where acs_interest_categ_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(INTEREST_CATEGS,
          XMLElement(ACS_INTEREST_CATEG,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_acs_interest_elem(
  Id IN acs_interest_categ.acs_interest_categ_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_INTEREST_CATEG_ID,C_INT_RATE_TYPE,IEL_VALID_FROM' as TABLE_KEY,
        acs_interest_elem_id,
        iel_applied_rate,
        iel_max_amount,
        iel_over_amount_rate,
        to_char(iel_valid_from) as IEL_VALID_FROM),
      rep_pc_functions.get_descodes('C_INT_RATE_TYPE',c_int_rate_type)
    )) into lx_data
  from acs_interest_elem
  where acs_interest_categ_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACS_INTEREST_ELEM,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_adv_tax_elem(
  Id IN acs_interest_categ.acs_interest_categ_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_INTEREST_CATEG_ID,ATE_VALID_FROM' as TABLE_KEY,
        acs_adv_tax_elem_id,
        ate_adv_tax_rate,
        ate_adv_tax_exemption,
        to_char(ate_valid_from) as ATE_VALID_FROM)
    )) into lx_data
  from acs_adv_tax_elem
  where acs_interest_categ_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACS_ADV_TAX_ELEM,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;


--
-- Méthodes de calcul des intérêts
--

function get_acs_int_calc_method_xml(
  Id IN acs_int_calc_method.acs_int_calc_method_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(CALC_METHODS,
      XMLElement(ACS_INT_CALC_METHOD,
        XMLAttributes(
          acs_int_calc_method_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'ICM_DESCRIPTION' as TABLE_KEY,
          acs_int_calc_method_id,
          icm_description,
          icm_comment,
          icm_assets_int_lbl,
          icm_liabil_int_lbl,
          icm_round_amount),
        rep_fin_functions_link.get_acs_default_account_link(acs_interest_acc_id,'ACS_INTEREST_ACC'),
        rep_fin_functions_link.get_acs_default_account_link(acs_assets_int_acc_id,'ACS_ASSETS_INT_ACC'),
        rep_fin_functions_link.get_acs_default_account_link(acs_liabil_int_acc_id,'ACS_LIABIL_INT_ACC'),
        rep_fin_functions_link.get_acs_default_account_link(acs_adv_tax_acc_id,'ACS_ADV_TAX_ACC'),
        rep_pc_functions.get_descodes('C_METHOD',c_method),
        rep_pc_functions.get_descodes('C_INT_DOC_GENERATION',c_int_doc_generation),
        rep_pc_functions.get_descodes('C_ROUND_TYPE',c_round_type),
        rep_fin_functions.get_acs_calc_cumul(acs_int_calc_method_id),
        rep_pc_functions.get_com_vfields_record(acs_int_calc_method_id,'ACS_INT_CALC_METHOD'),
        rep_pc_functions.get_com_vfields_value(acs_int_calc_method_id,'ACS_INT_CALC_METHOD')
      )
    ) into lx_data
  from acs_int_calc_method
  where acs_int_calc_method_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(CALC_METHODS,
          XMLElement(ACS_INT_CALC_METHOD,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_acs_method_elem(
  Id IN acs_int_calc_method.acs_int_calc_method_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_INTEREST_CATEG_ID,ACS_FINANCIAL_ACCOUNT_ID,ACS_DIVISION_ACCOUNT_ID' as TABLE_KEY,
        acs_method_elem_id,
        mel_adv_tax_subject,
        mel_adv_tax_exemption),
      rep_fin_functions_link.get_acs_interest_categ_link(acs_interest_categ_id),
      rep_fin_functions_link.get_acs_account_link(acs_financial_account_id,'ACS_FINANCIAL_ACCOUNT'),
      rep_fin_functions_link.get_acs_account_link(acs_division_account_id ,'ACS_DIVISION_ACCOUNT'),
      rep_fin_functions_link.get_acs_default_account_link(acs_interest_acc_id,'ACS_INTEREST_ACC'),
      rep_fin_functions_link.get_acs_default_account_link(acs_assets_int_acc_id,'ACS_ASSETS_INT_ACC'),
      rep_fin_functions_link.get_acs_default_account_link(acs_liabil_int_acc_id,'ACS_LIABIL_INT_ACC'),
      rep_fin_functions_link.get_acs_default_account_link(acs_adv_tax_acc_id,'ACS_ADV_TAX_ACC')
    )) into lx_data
  from acs_method_elem
  where acs_int_calc_method_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACS_METHOD_ELEM,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_calc_cumul(
  Id IN acs_int_calc_method.acs_int_calc_method_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACS_INT_CALC_METHOD_ID, C_TYPE_CUMUL' as TABLE_KEY,
        acs_calc_cumul_type_id),
      rep_pc_functions.get_descodes('C_TYPE_CUMUL',c_type_cumul)
    )) into lx_data
  from acs_calc_cumul_type
  where acs_int_calc_method_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACS_CALC_CUMUL_TYPE,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;


--
-- Catalogues de transaction
--

function get_acj_catalogue_doc_xml(
  Id IN acj_catalogue_document.acj_catalogue_document_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(CATALOGUE_DOCUMENTS,
      XMLElement(ACJ_CATALOGUE_DOCUMENT,
        XMLAttributes(
          acj_catalogue_document_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'CAT_KEY' as TABLE_KEY,
          acj_catalogue_document_id,
          cat_description,
          cat_fin_transaction,
          cat_com_transaction,
          cat_cae_transaction,
          cat_ext_vat,
          cat_ext_vat_discount,
          cat_key,
          cat_ext_transaction,
          cat_doc_show,
          cat_part_show,
          cat_report,
          cat_cover_information,
          cat_imp_information,
          cat_mgm_simplified,
          cat_free_data,
          cat_link,
          cat_services_input,
          cat_discount_prop,
          cat_part_lett_discount,
          cat_part_lett_diff_exchange,
          cat_auto_lettring,
          cat_stored_proc_b_delete,
          cat_stored_proc_a_delete,
          cat_stored_proc_b_edit,
          cat_stored_proc_a_edit,
          cat_stored_proc_b_validate,
          cat_stored_proc_a_validate,
          cat_enforced_account,
          cat_auto_part_lett,
          cat_blocked_doc,
          cat_expense_receipt),
        rep_pc_functions.get_descodes('C_TYPE_CATALOGUE',c_type_catalogue),
        rep_pc_functions.get_descodes('C_TYPE_PERIOD',c_type_period),
        rep_pc_functions.get_descodes('C_REMINDER_METHOD',c_reminder_method),
        rep_pc_functions.get_descodes('C_ADMIN_DOMAIN',c_admin_domain),
        rep_pc_functions.get_descodes('C_PROJECT_CONSOLIDATION',c_project_consolidation),
        rep_pc_functions.get_descodes('C_MATCHING_TOLERANCE',c_matching_tolerance),
        rep_pc_functions.get_dictionary('DIC_EXTERNAL_PROCESS',dic_external_process_id),
        rep_pc_functions.get_dictionary('DIC_TYPE_MOVEMENT',dic_type_movement_id),
        rep_pc_functions.get_dictionary('DIC_OPERATION_TYP',dic_operation_typ_id),
        rep_pc_functions.get_dictionary('DIC_ACJ_CAT_FREE_COD1',dic_acj_cat_free_cod1_id),
        rep_pc_functions.get_dictionary('DIC_ACJ_CAT_FREE_COD2',dic_acj_cat_free_cod2_id),
        rep_pc_functions.get_dictionary('DIC_ACJ_CAT_FREE_COD3',dic_acj_cat_free_cod3_id),
        rep_pc_functions.get_dictionary('DIC_ACJ_CAT_FREE_COD4',dic_acj_cat_free_cod4_id),
        rep_pc_functions.get_dictionary('DIC_ACJ_CAT_FREE_COD5',dic_acj_cat_free_cod5_id),
        rep_pc_functions.get_dictionary('DIC_ACJ_CAT_FREE_COD6',dic_acj_cat_free_cod6_id),
        rep_pc_functions.get_dictionary('DIC_ACJ_CAT_FREE_COD7',dic_acj_cat_free_cod7_id),
        rep_pc_functions.get_dictionary('DIC_ACJ_CAT_FREE_COD8',dic_acj_cat_free_cod8_id),
        rep_pc_functions.get_dictionary('DIC_ACJ_CAT_FREE_COD9',dic_acj_cat_free_cod9_id),
        rep_pc_functions.get_dictionary('DIC_ACJ_CAT_FREE_COD10',dic_acj_cat_free_cod10_id),
        rep_pc_functions.get_dictionary('DIC_PROJECT_CONSOL_1',dic_project_consol_1_id),
        rep_pc_functions.get_dictionary('DIC_BLOCKED_REASON',dic_blocked_reason_id),
        rep_fin_functions_link.get_acs_fin_acc_s_payment_link(acs_fin_acc_s_payment_id),
        rep_fin_functions_link.get_acs_fin_account_link(acs_financial_account_id, 'ACS_FINANCIAL_ACCOUNT'),
        rep_fin_functions_link.get_acj_description_type_link(acj_description_type_id),
        rep_pac_functions_link.get_pac_payment_condition_link(pac_payment_condition_id),
        rep_fin_functions.get_acj_sub_set_cat(acj_catalogue_document_id),
        rep_fin_functions.get_acj_imp_managed_data(acj_catalogue_document_id),
        rep_fin_functions.get_acj_flow(acj_catalogue_document_id),
        rep_fin_functions.get_acj_job_type_s_catalogue(acj_catalogue_document_id, null),
        rep_fin_functions.get_acj_number_application(acj_catalogue_document_id),
        rep_fin_functions.get_acj_free_data(acj_catalogue_document_id),
        rep_fin_functions.get_acj_traduction(acj_catalogue_document_id, rep_fin_functions.FREE_CODE_CATALOGUE_DOCUMENT),
        rep_pc_functions.get_com_vfields_record(acj_catalogue_document_id,'ACJ_CATALOGUE_DOCUMENT'),
        rep_pc_functions.get_com_vfields_value(acj_catalogue_document_id,'ACJ_CATALOGUE_DOCUMENT')
      )
    ) into lx_data
  from acj_catalogue_document
  where acj_catalogue_document_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(CATALOGUE_DOCUMENTS,
          XMLElement(ACJ_CATALOGUE_DOCUMENT,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_acj_sub_set_cat(
  Id IN acj_catalogue_document.acj_catalogue_document_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACJ_CATALOGUE_DOCUMENT_ID, C_TYPE_CUMUL, C_METHOD_CUMUL, C_SUB_SET' as TABLE_KEY,
        acj_sub_set_cat_id,
        acj_catalogue_document_id,
        sub_defered,
        sub_doc_number_ctrl,
        sub_cpn_choice),
      rep_pc_functions.get_descodes('C_TYPE_CUMUL', c_type_cumul),
      rep_pc_functions.get_descodes('C_METHOD_CUMUL', c_method_cumul),
      rep_pc_functions.get_descodes('C_SUB_SET', c_sub_set)
      )
    )
   into lx_data
  from acj_sub_set_cat
  where acj_catalogue_document_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACJ_SUB_SET_CAT,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acj_imp_managed_data(
  Id IN acj_catalogue_document.acj_catalogue_document_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACJ_CATALOGUE_DOCUMENT_ID,C_DATA_TYP' as TABLE_KEY,
        acj_imp_managed_data_id,
        mda_mandatory,
        mda_mandatory_primary),
      rep_pc_functions.get_descodes('C_DATA_TYP', c_data_typ)
    )) into lx_data
  from acj_imp_managed_data
  where acj_catalogue_document_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACJ_IMP_MANAGED_DATA,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;
end;

function get_acj_flow(
  Id IN acj_catalogue_document.acj_catalogue_document_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACJ_CATALOGUE_DOCUMENT_ID,ACJ_CAT_DOCUMENT2_ID' as TABLE_KEY,
        acj_flow_id,
        flo_partial_receipt,
        flo_part_grp_def),
      rep_fin_functions_link.get_acj_catalogue_doc_link(acj_cat_document2_id, 'ACJ_CAT_DOCUMENT2', 1)
      )
    ) into lx_data
  from acj_flow
  where acj_catalogue_document_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACJ_FLOW,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acj_job_type_s_catalogue(
  pCatalogueDocId IN acj_catalogue_document.acj_catalogue_document_id%TYPE,
  pJobTypeId IN acj_job_type.acj_job_type_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (pJobTypeId is not null) then
    -- Un modèle de travail est renseigné
    select
      XMLAgg(XMLElement(LIST_ITEM,
        XMLForest(
          'AFTER' as TABLE_TYPE,
          'ACJ_JOB_TYPE_ID,ACJ_CATALOGUE_DOCUMENT_ID' as TABLE_KEY,
          acj_job_type_s_catalogue_id,
          jca_default,
          jca_available,
          jca_copy_possible,
          jca_ext_possible
          ),
        rep_fin_functions_link.get_acj_catalogue_doc_link(acj_catalogue_document_id)
        )
      ) into lx_data
    from acj_job_type_s_catalogue
    where acj_job_type_id = pJobTypeId;
  elsif (pCatalogueDocId is not null) then
    -- Un catalogue est renseigné
    select
      XMLAgg(XMLElement(LIST_ITEM,
        XMLForest(
          'AFTER' as TABLE_TYPE,
          'ACJ_JOB_TYPE_ID,ACJ_CATALOGUE_DOCUMENT_ID' as TABLE_KEY,
          acj_job_type_s_catalogue_id,
          jca_default,
          jca_available,
          jca_copy_possible,
          jca_ext_possible
          ),
        rep_fin_functions_link.get_acj_job_type_link(acj_job_type_id)
        )
      ) into lx_data
    from acj_job_type_s_catalogue
    where acj_catalogue_document_id = pCatalogueDocId;
  else
    return null;
  end if;

  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACJ_JOB_TYPE_S_CATALOGUE,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acj_number_application(
  Id IN acj_catalogue_document.acj_catalogue_document_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACJ_CATALOGUE_DOCUMENT_ID,ACJ_NUMBER_METHOD_ID,ACS_FINANCIAL_YEAR_ID' as TABLE_KEY,
        acj_number_application_id,
        acj_catalogue_document_id),
      rep_fin_functions_link.get_acj_number_method_link(acj_number_method_id),
      rep_fin_functions_link.get_acs_financial_year_link(acs_financial_year_id)
    )) into lx_data
  from acj_number_application
  where acj_catalogue_document_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACJ_NUMBER_APPLICATION,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acj_free_data(
  Id IN acj_catalogue_document.acj_catalogue_document_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACJ_CATALOGUE_DOCUMENT_ID,DIC_FREE_DATA_WORDING_ID' as TABLE_KEY,
        acj_free_data_id,
        acj_catalogue_document_id,
        fda_date,
        fda_boolean,
        fda_number,
        fda_char,
        fda_memo),
      rep_pc_functions.get_dictionary('DIC_FREE_DATA_WORDING',dic_free_data_wording_id)
    )) into lx_data
  from acj_free_data
  where acj_catalogue_document_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACJ_FREE_DATA,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acj_traduction(
  Id IN acj_catalogue_document.acj_catalogue_document_id%TYPE,
  idCode IN FREECODE_T)
  return XMLType
is
  lx_data XMLType;
  vTblId ID_TABLE_TYPE := ID_TABLE_TYPE();
begin
  if (Id is null) then
    return null;
  end if;

  EXECUTE IMMEDIATE
    'select acj_traduction_id
     from acj_traduction
     where '|| p_FreeIdCode(idCode) ||'= :Id'
  BULK COLLECT INTO vTblId
  USING Id;
  if (SQL%ROWCOUNT = 0) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        p_FreeIdCode(idCode) ||', PC_LANG_ID' as TABLE_KEY,
        t.tra_text,
        l.lanid)
    )) into lx_data
  from pcs.pc_lang l, acj_traduction t
  where t.acj_traduction_id IN (select column_value from table(vTblId)) and
    l.pc_lang_id = t.pc_lang_id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACJ_TRADUCTION,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;


--
-- Modèles de travaux
--

function get_acj_job_type_xml(
  Id IN acj_job_type.acj_job_type_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(JOB_TYPES,
      XMLElement(ACJ_JOB_TYPE,
        XMLAttributes(
          acj_job_type_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'TYP_KEY' as TABLE_KEY,
          acj_job_type_id,
          typ_description,
          typ_supplier_permanent,
          typ_key,
          typ_aci_detail,
          typ_restrict_period,
          typ_available,
          typ_zero_document,
          typ_zero_position,
          typ_debit_credit_group,
          typ_report,
          typ_aci_doc_update,
          typ_journalize_accounting,
          typ_init_job_descr,
          typ_clo_per_acc,
          typ_stored_proc_todo,
          typ_stored_proc_pend,
          typ_stored_proc_fint,
          typ_stored_proc_term,
          typ_stored_proc_def,
          typ_export_path,
          typ_export_filename,
          typ_export_com_name,
          typ_export_journal_code),
        rep_pc_functions.get_descodes('C_JOB_STATE',C_JOB_STATE),
        rep_pc_functions.get_descodes('C_VALID',C_VALID),
        rep_pc_functions.get_descodes('C_ACI_GROUP_TYPE',C_ACI_GROUP_TYPE),
        rep_pc_functions.get_descodes('C_ACI_CADENCE',C_ACI_CADENCE),
        rep_pc_functions.get_descodes('C_ACI_FINANCIAL_LINK',C_ACI_FINANCIAL_LINK),
        rep_pc_functions.get_descodes('C_TYP_EXPORT_FORMAT',C_TYP_EXPORT_FORMAT),
        rep_pc_functions.get_descodes('C_TYP_EXPORT_PER_KEY',C_TYP_EXPORT_PER_KEY),
        rep_pc_functions.get_dictionary('DIC_ACJ_TYP_FREE_COD1',DIC_ACJ_TYP_FREE_COD1_ID),
        rep_pc_functions.get_dictionary('DIC_ACJ_TYP_FREE_COD2',DIC_ACJ_TYP_FREE_COD2_ID),
        rep_pc_functions.get_dictionary('DIC_ACJ_TYP_FREE_COD3',DIC_ACJ_TYP_FREE_COD3_ID),
        rep_pc_functions.get_dictionary('DIC_ACJ_TYP_FREE_COD4',DIC_ACJ_TYP_FREE_COD4_ID),
        rep_pc_functions.get_dictionary('DIC_ACJ_TYP_FREE_COD5',DIC_ACJ_TYP_FREE_COD5_ID),
        rep_pc_functions.get_dictionary('DIC_ACJ_TYP_FREE_COD6',DIC_ACJ_TYP_FREE_COD6_ID),
        rep_pc_functions.get_dictionary('DIC_ACJ_TYP_FREE_COD7',DIC_ACJ_TYP_FREE_COD7_ID),
        rep_pc_functions.get_dictionary('DIC_ACJ_TYP_FREE_COD8',DIC_ACJ_TYP_FREE_COD8_ID),
        rep_pc_functions.get_dictionary('DIC_ACJ_TYP_FREE_COD9',DIC_ACJ_TYP_FREE_COD9_ID),
        rep_pc_functions.get_dictionary('DIC_ACJ_TYP_FREE_COD10',DIC_ACJ_TYP_FREE_COD10_ID),
        rep_pc_functions.get_dictionary('DIC_JOURNAL_TYPE',DIC_JOURNAL_TYPE_ID),
        rep_pc_functions_link.get_pc_user_link(pc_user_id),
        rep_fin_functions.get_acj_autorized_job_type(acj_job_type_id),
        rep_fin_functions.get_acj_job_type_s_catalogue(null, acj_job_type_id),
        rep_fin_functions.get_acj_event(acj_job_type_id),
        rep_fin_functions.get_acj_traduction(acj_job_type_id, rep_fin_functions.FREE_CODE_JOB_TYPE),
        rep_fin_functions.get_acj_job_type_s_fin_acc(acj_job_type_id),
        rep_fin_functions.get_acj_job_type_s_fin_div(acj_job_type_id),
        rep_pc_functions.get_com_vfields_record(acj_job_type_id,'ACJ_JOB_TYPE'),
        rep_pc_functions.get_com_vfields_value(acj_job_type_id,'ACJ_JOB_TYPE')
      )
    ) into lx_data
  from acj_job_type
  where acj_job_type_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(JOB_TYPES,
          XMLElement(ACJ_JOB_TYPE,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_acj_autorized_job_type(
  Id IN acj_job_type.acj_job_type_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACJ_JOB_TYPE_ID,PC_USER_ID' as TABLE_KEY,
        aut_def_authorized,
        aut_clo_per_acc,
        aut_create,
        aut_modify,
        aut_delete,
        aut_serie_period_job_create),
      rep_pc_functions_link.get_pc_user_link(pc_user_id)
    )) into lx_data
  from acj_autorized_job_type
  where acj_job_type_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACJ_AUTORIZED_JOB_TYPE,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acj_job_type_s_fin_acc(
  Id IN acj_job_type.acj_job_type_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACJ_JOB_TYPE_ID, ACS_FINANCIAL_ACCOUNT_ID' as TABLE_KEY,
        acj_job_type_s_fin_acc_id),
      rep_fin_functions_link.get_acs_account_link(acs_financial_account_id,'ACS_FINANCIAL_ACCOUNT')
    )) into lx_data
  from acj_job_type_s_fin_acc
  where acj_job_type_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACJ_JOB_TYPE_S_FIN_ACC,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acj_job_type_s_fin_div(
  Id IN acj_job_type.acj_job_type_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACJ_JOB_TYPE_ID, ACS_DIVISION_ACCOUNT_ID' as TABLE_KEY,
        acj_job_type_s_fin_div_id),
      rep_fin_functions_link.get_acs_account_link(acs_division_account_id,'ACS_DIVISION_ACCOUNT')
    )) into lx_data
  from acj_job_type_s_fin_div
  where acj_job_type_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACJ_JOB_TYPE_S_FIN_DIV,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;


--
-- Tâches des modèles de travaux
--

function get_acj_event(
  Id IN acj_job_type.acj_job_type_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACJ_JOB_TYPE_ID,C_TYPE_EVENT' as TABLE_KEY,
        acj_event_id,
        eve_nosequence,
        eve_description,
        eve_vat_method,
        eve_rec_pay_tot_display,
        eve_acc_tot_display,
        eve_acc_budget_display,
        eve_procedure,
        eve_default_fin_ref,
        eve_mgm_ctrl_deb_cre,
        eve_val_date_by_doc_date,
        eve_chk_value_date,
        eve_default_value,
        eve_remainder_calc_days,
        eve_mgm_record,
        eve_man_document_date,
        eve_offsets_entry_d_c,
        eve_multi_users,
        eve_balance_disp),
      rep_pc_functions.get_descodes('C_TYPE_EVENT',C_TYPE_EVENT),
      rep_pc_functions.get_descodes('C_TYPE_SUPPORT',C_TYPE_SUPPORT),
      rep_pc_functions.get_descodes('C_BASIS_CALC_DAYS',C_BASIS_CALC_DAYS),
      rep_fin_functions_link.get_acs_account_link(acs_financial_account_id, 'ACS_FINANCIAL_ACCOUNT'),
      rep_fin_functions_link.get_acs_fin_curr_link(acs_financial_currency_id),
      rep_pc_functions_link.get_pc_report_link(pc_report_id),
      rep_fin_functions.get_acj_autorized_event(acj_event_id),
      rep_fin_functions.get_acj_partner_exception(acj_event_id),
      rep_fin_functions.get_acj_expiry_exception(acj_event_id),
      rep_fin_functions.get_acj_event_s_reminder(acj_event_id),
      rep_fin_functions.get_acj_sql_command(acj_event_id),
      rep_pc_functions.get_com_vfields_record(acj_job_type_id,'ACJ_EVENT'),
      rep_pc_functions.get_com_vfields_value(acj_job_type_id,'ACJ_EVENT')
    )) into lx_data
  from acj_event
  where acj_job_type_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACJ_EVENT,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acj_autorized_event(
  Id IN acj_event.acj_event_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACJ_EVENT_ID, PC_USER_ID' as TABLE_KEY),
      rep_pc_functions_link.get_pc_user_link(pc_user_id)
    )) into lx_data
  from acj_autorized_event
  where acj_event_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACJ_AUTORIZED_EVENT,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acj_partner_exception(
  Id IN acj_event.acj_event_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACJ_EVENT_ID, ACJ_CATALOGUE_DOCUMENT_ID' as TABLE_KEY),
      rep_fin_functions_link.get_acj_catalogue_doc_link(acj_catalogue_document_id)
    )) into lx_data
  from acj_partner_exception
  where acj_event_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACJ_PARTNER_EXCEPTION,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acj_expiry_exception(
  Id IN acj_event.acj_event_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACJ_EVENT_ID, ACJ_CATALOGUE_DOCUMENT_ID' as TABLE_KEY),
      rep_fin_functions_link.get_acj_catalogue_doc_link(acj_catalogue_document_id)
    )) into lx_data
  from acj_expiry_exception
  where acj_event_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACJ_EXPIRY_EXCEPTION,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acj_event_s_reminder(
  Id IN acj_event.acj_event_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACJ_EVENT_ID, PAC_REMAINDER_CATEGORY_ID' as TABLE_KEY),
      rep_pac_functions_link.get_pac_remainder_categ_link(pac_remainder_category_id)
    )) into lx_data
  from acj_event_s_reminder
  where acj_event_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACJ_EVENT_S_REMINDER,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acj_sql_command(
  Id IN acj_event.acj_event_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'ACJ_EVENT_ID' as TABLE_KEY,
        acj_sql_command_id,
        sql_description,
        sql_instruction)
    )) into lx_data
  from acj_sql_command
  where acj_event_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(ACJ_SQL_COMMAND,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;


BEGIN
  p_FreeIdCode(rep_fin_functions.FREE_CODE_CATALOGUE_DOCUMENT) := 'ACJ_CATALOGUE_DOCUMENT_ID';
  p_FreeIdCode(rep_fin_functions.FREE_CODE_JOB_TYPE) := 'ACJ_JOB_TYPE_ID';
END REP_FIN_FUNCTIONS;
