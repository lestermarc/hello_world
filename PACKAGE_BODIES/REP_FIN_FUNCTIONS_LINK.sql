--------------------------------------------------------
--  DDL for Package Body REP_FIN_FUNCTIONS_LINK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_FIN_FUNCTIONS_LINK" 
/**
 * Fonctions de génération de liaison pour document Xml.
 * Spécialisation: Finance et comptabilité (AC...)
 *
 * @version 1.0
 * @date 02/2003
 * @author jsomers
 * @author spfister
 * @author fperotto
 * @author skalayci
 * @author vjeanfavre
 * @author pvogel
 * @author ngomes
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
AS

  -- Package body global variables
  gcv_REP_LANID CONSTANT pcs.pc_lang.lanid%TYPE := 'FR';
  gn_rep_pc_lang_id pcs.pc_lang.pc_lang_id%TYPE;


function get_acs_account_inherit_link(
  Id IN acs_account.acs_account_id%TYPE,
  FieldRef IN VARCHAR2)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(INHERIT,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'ACC_NUMBER,ACS_SUB_SET_ID,C_VALID' as TABLE_KEY,
        'ACS_ACCOUNT_ID='||FieldRef||'_ID' as TABLE_MAPPING,
        'ACS_ACCOUNT' as TABLE_REFERENCE,
        acs_account_id as INHERIT_ID,
        acc_number),
      rep_fin_functions_link.get_acs_sub_set_link(acs_sub_set_id),
      rep_pc_functions.get_descodes('C_VALID',c_valid)
    ) into lx_data
  from acs_account
  where acs_account_id = Id;

  if (lx_data is not null) then
    return rep_xml_function.transform_field_ref('INHERIT', FieldRef, lx_data);
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_cpn_account_link(
  Id IN acs_account.acs_account_id%TYPE,
  FieldRef IN VARCHAR2 default 'ACS_CPN_ACCOUNT')
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ACS_CPN_ACCOUNT,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'ACS_CPN_ACCOUNT_ID' as TABLE_KEY),
      rep_fin_functions_link.get_acs_account_inherit_link(acs_cpn_account_id, 'ACS_CPN_ACCOUNT')
    ) into lx_data
  from acs_cpn_account
  where acs_cpn_account_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'ACS_CPN_ACCOUNT') then
      return rep_xml_function.transform_root_ref('ACS_CPN_ACCOUNT', FieldRef, lx_data);
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_cda_account_link(
  Id IN acs_account.acs_account_id%TYPE,
  FieldRef IN VARCHAR2 default 'ACS_CDA_ACCOUNT')
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ACS_CDA_ACCOUNT,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'ACS_CDA_ACCOUNT_ID' as TABLE_KEY),
      rep_fin_functions_link.get_acs_account_inherit_link(acs_cda_account_id, 'ACS_CDA_ACCOUNT')
    ) into lx_data
  from acs_cda_account
  where acs_cda_account_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'ACS_CDA_ACCOUNT') then
      return rep_xml_function.transform_root_ref('ACS_CDA_ACCOUNT',FieldRef,lx_data);
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_pf_account_link(
  Id IN acs_account.acs_account_id%TYPE,
  FieldRef IN VARCHAR2 default 'ACS_PF_ACCOUNT')
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ACS_PF_ACCOUNT,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'ACS_PF_ACCOUNT_ID' as TABLE_KEY),
      rep_fin_functions_link.get_acs_account_inherit_link(acs_pf_account_id,'ACS_PF_ACCOUNT')
    ) into lx_data
  from acs_pf_account
  where acs_pf_account_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'ACS_PF_ACCOUNT') then
      return rep_xml_function.transform_root_ref('ACS_PF_ACCOUNT',FieldRef,lx_data);
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_pj_account_link(
  Id IN acs_account.acs_account_id%TYPE,
  FieldRef IN VARCHAR2 default 'ACS_PJ_ACCOUNT')
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ACS_PJ_ACCOUNT,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'ACS_PJ_ACCOUNT_ID' as TABLE_KEY),
      rep_fin_functions_link.get_acs_account_inherit_link(acs_pj_account_id,'ACS_PJ_ACCOUNT')
    ) into lx_data
  from acs_pj_account
  where acs_pj_account_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'ACS_PJ_ACCOUNT') then
      return rep_xml_function.transform_root_ref('ACS_PJ_ACCOUNT',FieldRef,lx_data);
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_fin_account_link(
  Id IN acs_account.acs_account_id%TYPE,
  FieldRef IN VARCHAR2 default 'ACS_FINANCIAL_ACCOUNT')
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ACS_FINANCIAL_ACCOUNT,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'ACS_FINANCIAL_ACCOUNT_ID' as TABLE_KEY),
      rep_fin_functions_link.get_acs_account_inherit_link(acs_financial_account_id,'ACS_FINANCIAL_ACCOUNT')
    ) into lx_data
  from acs_financial_account
  where acs_financial_account_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'ACS_FINANCIAL_ACCOUNT') then
      return rep_xml_function.transform_root_ref('ACS_FINANCIAL_ACCOUNT', FieldRef, lx_data);
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_div_account_link(
  Id IN acs_account.acs_account_id%TYPE,
  FieldRef IN VARCHAR2 default 'ACS_DIVISION_ACCOUNT')
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ACS_DIVISION_ACCOUNT,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'ACS_DIVISION_ACCOUNT_ID' as TABLE_KEY),
      rep_fin_functions_link.get_acs_account_inherit_link(acs_division_account_id,'ACS_DIVISION_ACCOUNT')
    ) into lx_data
  from acs_division_account
  where acs_division_account_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'ACS_DIVISION_ACCOUNT') then
      return rep_xml_function.transform_root_ref('ACS_DIVISION_ACCOUNT', FieldRef, lx_data);
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_sub_account_link(
  Id IN acs_account.acs_account_id%TYPE,
  FieldRef IN VARCHAR2 default 'ACS_SUB_ACCOUNT')
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ACS_SUB_ACCOUNT,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'ACS_ACCOUNT_ID' as TABLE_KEY),
      rep_fin_functions_link.get_acs_account_inherit_link(acs_sub_account_id,'ACS_SUB_ACCOUNT')
    ) into lx_data
  from acs_account
  where acs_account_id = Id and acs_sub_account_id is not null;

  if (lx_data is not null) then
    if (FieldRef != 'ACS_SUB_ACCOUNT') then
      return rep_xml_function.transform_root_ref('ACS_SUB_ACCOUNT',FieldRef,lx_data);
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_fin_curr_link(
  Id IN acs_financial_currency.acs_financial_currency_id%TYPE,
  FieldRef IN VARCHAR2 default 'ACS_FINANCIAL_CURRENCY',
  IsMandatory IN INTEGER default 0)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ACS_FINANCIAL_CURRENCY,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'PC_CURR_ID' as TABLE_KEY,
        acs_financial_currency_id),
      rep_pc_functions_link.get_pc_curr_link(pc_curr_id)
    ) into lx_data
  from acs_financial_currency
  where acs_financial_currency_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'ACS_FINANCIAL_CURRENCY') then
      return rep_xml_function.transform_root_ref_table('ACS_FINANCIAL_CURRENCY', FieldRef, lx_data);
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_limit_curr_link(
  Id IN acs_financial_currency.acs_financial_currency_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ACS_LIMI_CURR,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'ACS_FINANCIAL_CURRENCY_ID' as TABLE_KEY),
      rep_fin_functions_link.get_acs_fin_curr_link(Id)
    ) into lx_data
  from dual;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_fin_acc_s_payment_link(
  Id IN acs_fin_acc_s_payment.acs_fin_acc_s_payment_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ACS_FIN_ACC_S_PAYMENT,
      XMLForest(
        'FUNCTION' as TABLE_TYPE,
        'REP_FIN_FUNCTIONS.GET_ACS_FIN_ACC_S_PAYMENT_ID' as FUNCTION_NAME),
      XMLElement(PARAMETERS,
        XMLElement(PARAMETER,
          XMLAttributes(1 as NUM,'VARCHAR' as TYPE),
          des.des_description_summary),
        XMLElement(PARAMETER,
          XMLAttributes(2 as NUM,'VARCHAR' as TYPE),
          gcv_REP_LANID),
        XMLElement(PARAMETER,
          XMLAttributes(3 as NUM,'VARCHAR' as TYPE),
          acc.acc_number)
    )) into lx_data
  from
    acs_account acc,
    acs_description des,
    acs_payment_method apm,
    acs_fin_acc_s_payment afa
  where
    afa.acs_fin_acc_s_payment_id = Id and
    acc.acs_account_id = afa.acs_financial_account_id and
    apm.acs_payment_method_id = afa.acs_payment_method_id and
    apm.c_method_category = '3' and
    des.acs_payment_method_id = apm.acs_payment_method_id and
    des.pc_lang_id = gn_rep_pc_lang_id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_vat_det_account_link(
  Id IN acs_vat_det_account.acs_vat_det_account_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ACS_VAT_DET_ACCOUNT,
      XMLForest(
        'FUNCTION' as TABLE_TYPE,
        'REP_FIN_FUNCTIONS.GET_ACS_VAT_DET_ACCOUNT_ID' as FUNCTION_NAME),
      XMLElement(PARAMETERS,
        XMLElement(PARAMETER,
          XMLAttributes(1 as NUM,'VARCHAR' as TYPE),
          b.des_description_summary),
        XMLElement(PARAMETER,
          XMLAttributes(2 as NUM,'VARCHAR' as TYPE),
          c.cntid),
        XMLElement(PARAMETER,
          XMLAttributes(3 as NUM,'VARCHAR' as TYPE),
          gcv_REP_LANID)
    )) into lx_data
  from
    acs_description b,
    pcs.pc_cntry c,
    acs_vat_det_account a
  where
    a.acs_vat_det_account_id = Id and
    b.acs_vat_det_account_id = a.acs_vat_det_account_id and
    b.pc_lang_id = gn_rep_pc_lang_id and
    c.pc_cntry_id = a.pc_cntry_id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_custom_aux_account_link(
  aux_id IN acs_auxiliary_account.acs_auxiliary_account_id%TYPE,
  pac_id IN pac_custom_partner.pac_custom_partner_id%TYPE,
  pac_group_id IN pac_custom_partner.pac_custom_partner_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (aux_id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ACS_AUXILIARY_ACCOUNT,
      XMLForest(
        'FUNCTION' as TABLE_TYPE,
        'REP_FIN_FUNCTIONS.GET_ACS_AUXILIARY_ACCOUNT_ID' as FUNCTION_NAME),
      XMLElement(PARAMETERS,
        XMLElement(PARAMETER,
          XMLAttributes(1 as NUM,'NUMBER' as TYPE),
         'PAC_PERSON_ID'),
        XMLElement(PARAMETER,
          XMLAttributes(2 as NUM,'VARCHAR' as TYPE),
          gcv_REP_LANID),
        XMLElement(PARAMETER,
          XMLAttributes(3 as NUM,'VARCHAR' as TYPE),
          c.des_description_summary),
        XMLElement(PARAMETER,
          XMLAttributes(4 as NUM,'VARCHAR' as TYPE),
          d.c_sub_set),
        XMLElement(PARAMETER,
          XMLAttributes(5 as NUM,'VARCHAR' as TYPE),
          (select c_partner_category from pac_custom_partner
           where pac_custom_partner_id = pac_id)),
        XMLElement(PARAMETER,
          XMLAttributes(6 as NUM,'LINK' as TYPE, 'ACS_AUXILIARY_ACCOUNT_ID' as NAME),
          case when pac_group_id is not null then
            XMLForest(
              'PAC_CUSTOM_PARTNER' as TABLE_NAME,
              'PAC_CUSTOM_PARTNER_ID' as TABLE_KEY)
          end,
          case when pac_group_id is not null then
            rep_pac_functions_link.get_pac_person_link(pac_group_id, 'PAC_CUSTOM_PARTNER', 1)
          end
        ),
        XMLElement(PARAMETER,
          XMLAttributes(7 as NUM,'LINK' as TYPE, 'ACS_AUXILIARY_ACCOUNT_ID' as NAME),
          XMLForest(
            'PAC_CUSTOM_PARTNER' as TABLE_NAME,
            'PAC_CUSTOM_PARTNER_ID' as TABLE_KEY))
    )) into lx_data
  from
    acs_sub_set d,
    acs_description c,
    acs_account b,
    acs_auxiliary_account a
  where
    a.acs_auxiliary_account_id = aux_id and
    b.acs_account_id = a.acs_auxiliary_account_id and
    c.acs_sub_set_id = b.acs_sub_set_id and
    c.pc_lang_id = gn_rep_pc_lang_id and
    d.acs_sub_set_id = b.acs_sub_set_id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_supplier_aux_account_link(
  aux_id IN acs_auxiliary_account.acs_auxiliary_account_id%TYPE,
  pac_id IN pac_supplier_partner.pac_supplier_partner_id%TYPE,
  pac_group_id IN pac_supplier_partner.pac_supplier_partner_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (aux_id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ACS_AUXILIARY_ACCOUNT,
      XMLForest(
        'FUNCTION' as TABLE_TYPE,
        'REP_FIN_FUNCTIONS.GET_ACS_AUXILIARY_ACCOUNT_ID' as FUNCTION_NAME),
      XMLElement(PARAMETERS,
        XMLElement(PARAMETER,
          XMLAttributes(1 as NUM,'NUMBER' as TYPE),
         'PAC_PERSON_ID'),
        XMLElement(PARAMETER,
          XMLAttributes(2 as NUM,'VARCHAR' as TYPE),
          gcv_REP_LANID),
        XMLElement(PARAMETER,
          XMLAttributes(3 as NUM,'VARCHAR' as TYPE),
          c.des_description_summary),
        XMLElement(PARAMETER,
          XMLAttributes(4 as NUM,'VARCHAR' as TYPE),
          d.c_sub_set),
        XMLElement(PARAMETER,
          XMLAttributes(5 as NUM,'VARCHAR' as TYPE),
          (select c_partner_category from pac_supplier_partner
           where pac_supplier_partner_id = pac_id)),
        XMLElement(PARAMETER,
          XMLAttributes(6 as NUM,'LINK' as TYPE, 'ACS_AUXILIARY_ACCOUNT_ID' as NAME),
          case when pac_group_id is not null then
            XMLForest(
              'PAC_SUPPLIER_PARTNER' as TABLE_NAME,
              'PAC_SUPPLIER_PARTNER_ID' as TABLE_KEY)
          end,
          case when pac_group_id is not null then
            rep_pac_functions_link.get_pac_person_link(pac_group_id, 'PAC_SUPPLIER_PARTNER', 1)
          end
        ),
        XMLElement(PARAMETER,
          XMLAttributes(7 as NUM,'LINK' as TYPE, 'ACS_AUXILIARY_ACCOUNT_ID' as NAME),
          XMLForest(
            'PAC_SUPPLIER_PARTNER' as TABLE_NAME,
            'PAC_SUPPLIER_PARTNER_ID' as TABLE_KEY))
    )) into lx_data
  from
    acs_sub_set d,
    acs_description c,
    acs_account b,
    acs_auxiliary_account a
  where
    a.acs_auxiliary_account_id = aux_id and
    b.acs_account_id = a.acs_auxiliary_account_id and
    c.acs_sub_set_id = b.acs_sub_set_id and
    c.pc_lang_id = gn_rep_pc_lang_id and
    d.acs_sub_set_id = b.acs_sub_set_id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_sub_set_link(
  Id IN acs_sub_set.acs_sub_set_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ACS_SUB_SET,
      XMLForest(
        'FUNCTION' as TABLE_TYPE,
        'REP_FIN_FUNCTIONS.GET_ACS_SUB_SET_ID' as FUNCTION_NAME),
      XMLElement(PARAMETERS,
        XMLElement(PARAMETER,
          XMLAttributes(1 as NUM,'VARCHAR' as TYPE),
          gcv_REP_LANID),
        XMLElement(PARAMETER,
          XMLAttributes(2 as NUM,'VARCHAR' as TYPE),
          des_description_summary),
        XMLElement(PARAMETER,
          XMLAttributes(3 as NUM,'VARCHAR' as TYPE),
          (select c_sub_set from acs_sub_set
           where acs_sub_set_id = Id)))
    ) into lx_data
  from acs_description
  where acs_sub_set_id = Id and pc_lang_id = gn_rep_pc_lang_id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_account_link(
  Id IN acs_account.acs_account_id%TYPE,
  FieldRef IN VARCHAR2,
  FieldName IN VARCHAR2)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ACCOUNT,
      XMLForest(
        'LINK' as TABLE_TYPE,
        FieldRef||'_ID' as TABLE_KEY,
        FieldRef||'_ID=ACS_ACCOUNT_ID' as TABLE_MAPPING,
        'ACS_ACCOUNT' as TABLE_REFERENCE),
      XMLElement(ACS_ACCOUNT,
        XMLForest(
          'LINK' as TABLE_TYPE,
          'ACC_NUMBER,ACS_SUB_SET_ID,C_VALID' as TABLE_KEY,
          acs_account_id,
          acc_number),
        rep_fin_functions_link.get_acs_sub_set_link(acs_sub_set_id),
        rep_pc_functions.get_descodes('C_VALID',c_valid)
      )
    ) into lx_data
  from acs_account
  where acs_account_id = Id;

  if (lx_data is not null) then
    return rep_xml_function.transform_root_ref('ACCOUNT', FieldName, lx_data);
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_account_link(
  Id IN acs_account.acs_account_id%TYPE,
  FieldRef IN VARCHAR2)
  return XMLType
is
begin
  if (Id in (null,0)) then
    return rep_fin_functions_link.get_acs_account_link(Id,FieldRef,FieldRef);
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_tax_code_link(
  Id IN acs_account.acs_account_id%TYPE,
  FieldRef IN VARCHAR2 default 'ACS_TAX_CODE')
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ACS_TAX_CODE,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'ACS_TAX_CODE_ID' as TABLE_KEY),
      rep_fin_functions_link.get_acs_account_inherit_link(acs_tax_code_id,'ACS_TAX_CODE')
    ) into lx_data
  from acs_tax_code
  where acs_tax_code_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'ACS_TAX_CODE') then
      return rep_xml_function.transform_root_ref('ACS_TAX_CODE', FieldRef, lx_data);
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_default_account_link(
  Id IN acs_default_account.acs_default_account_id%TYPE,
  FieldRef IN VARCHAR2)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(DEF_ACCOUNT,
      XMLForest(
        'LINK' as TABLE_TYPE,
        FieldRef||'_ID' as TABLE_KEY,
        FieldRef||'_ID=ACS_DEFAULT_ACCOUNT_ID' as TABLE_MAPPING,
        'ACS_DEFAULT_ACCOUNT' as TABLE_REFERENCE),
      XMLElement(ACS_DEFAULT_ACCOUNT,
        XMLForest(
          'LINK' as TABLE_TYPE,
          'C_ADMIN_DOMAIN, C_DEFAULT_ELEMENT_TYPE, DEF_DESCR' as TABLE_KEY,
          acs_default_account_id,
          def_descr),
        rep_pc_functions.get_descodes('C_ADMIN_DOMAIN',c_admin_domain),
        rep_pc_functions.get_descodes('C_DEFAULT_ELEMENT_TYPE',c_default_element_type))
    ) into lx_data
  from acs_default_account
  where acs_default_account_id = Id;

  if (lx_data is not null) then
    return rep_xml_function.transform_root_ref('DEF_ACCOUNT', FieldRef, lx_data);
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_interest_categ_link(
  Id IN acs_interest_categ.acs_interest_categ_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ACS_INTEREST_CATEG,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'ICA_DESCRIPTION' as TABLE_KEY,
        acs_interest_categ_id,
        ica_description)
    ) into lx_data
  from acs_interest_categ
  where acs_interest_categ_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;


--
-- Gestion des documents
--

function get_act_document_link(
  Id IN act_document.act_document_id%TYPE,
  FieldRef IN VARCHAR2 default 'ACT_DOCUMENT',
  ForceReference IN INTEGER default 0,
  IsMandatory IN INTEGER default 0)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ACT_DOCUMENT,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'ACT_DOCUMENT_ID' as TABLE_KEY,
        act_document_id)
    ) into lx_data
  from act_document
  where act_document_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'ACT_DOCUMENT') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('ACT_DOCUMENT', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('ACT_DOCUMENT', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;


--
-- Gestion des immobilisations
--

function get_fam_fixed_assets_link(
  Id IN fam_fixed_assets.fam_fixed_assets_id%TYPE,
  FieldRef IN VARCHAR2 default 'FAM_FIXED_ASSETS',
  ForceReference IN INTEGER default 0,
  IsMandatory IN INTEGER default 0)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(FAM_FIXED_ASSETS,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'FIX_NUMBER' as TABLE_KEY,
        fam_fixed_assets_id,
        fix_number)
    ) into lx_data
  from fam_fixed_assets
  where fam_fixed_assets_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'FAM_FIXED_ASSETS') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('FAM_FIXED_ASSETS', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('FAM_FIXED_ASSETS', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;


--
-- Gestion des types de description
--

function get_acj_description_type_link(
  Id IN acj_description_type.acj_description_type_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ACJ_DESCRIPTION_TYPE,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'DES_DESCR' as TABLE_KEY,
        acj_description_type_id,
        des_descr)
    ) into lx_data
  from acj_description_type
  where acj_description_type_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;


--
-- Gestion des catalogues de document
--

function get_acj_catalogue_doc_link(
  Id IN acj_catalogue_document.acj_catalogue_document_id%TYPE,
  FieldRef IN VARCHAR2 default 'ACJ_CATALOGUE_DOCUMENT',
  ForceReference IN INTEGER default 0,
  IsMandatory IN INTEGER default 0)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ACJ_CATALOGUE_DOCUMENT,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'CAT_KEY' as TABLE_KEY,
        acj_catalogue_document_id,
        cat_key)
    ) into lx_data
  from acj_catalogue_document
  where acj_catalogue_document_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'ACJ_CATALOGUE_DOCUMENT') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('ACJ_CATALOGUE_DOCUMENT', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('ACJ_CATALOGUE_DOCUMENT', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acj_job_type_link(
  Id IN acj_job_type.acj_job_type_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ACJ_JOB_TYPE,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'TYP_KEY' as TABLE_KEY,
        acj_job_type_id,
        typ_key)
    ) into lx_data
  from acj_job_type
  where acj_job_type_id = Id;

  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acj_number_method_link(
  Id IN acj_number_method.acj_number_method_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ACJ_NUMBER_METHOD,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'DNM_KEY' as TABLE_KEY,
        acj_number_method_id,
        dnm_key)
    ) into lx_data
  from acj_number_method
  where acj_number_method_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acj_job_type_s_cat_link(
  Id IN acj_job_type_s_catalogue.acj_job_type_s_catalogue_id%TYPE,
  FieldRef IN VARCHAR2 default 'ACJ_JOB_TYPE_S_CATALOGUE',
  ForceReference IN INTEGER default 0)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ACJ_JOB_TYPE_S_CATALOGUE,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'ACJ_JOB_TYPE_ID,ACJ_CATALOGUE_DOCUMENT_ID' as TABLE_KEY,
        acj_job_type_s_catalogue_id),
        rep_fin_functions_link.get_acj_job_type_link(acj_job_type_id),
        rep_fin_functions_link.get_acj_catalogue_doc_link(acj_catalogue_document_id)
    ) into lx_data
  from acj_job_type_s_catalogue
  where acj_job_type_s_catalogue_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'ACJ_JOB_TYPE_S_CATALOGUE') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('ACJ_JOB_TYPE_S_CATALOGUE', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('ACJ_JOB_TYPE_S_CATALOGUE', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_acs_financial_year_link(
  Id IN acs_financial_year.acs_financial_year_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ACS_FINANCIAL_YEAR,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'FYE_NO_EXERCICE' as TABLE_KEY,
        acs_financial_year_id,
        fye_no_exercice)
    ) into lx_data
  from acs_financial_year
  where acs_financial_year_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

procedure set_replication_language is
begin
  select pc_lang_id into gn_rep_pc_lang_id
  from pcs.pc_lang
  where lanid = gcv_REP_LANID;

  exception
    when NO_DATA_FOUND then
      gn_rep_pc_lang_id := 1.0;
end;

function get_acs_qty_unit_link(
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
        'LINK' as TABLE_TYPE,
        'ACS_QTY_UNIT_ID' as TABLE_KEY),
      rep_fin_functions_link.get_acs_account_inherit_link(ACS_QTY_UNIT_ID,'ACS_QTY_UNIT')
    ) into lx_data
  from ACS_QTY_UNIT
  where ACS_QTY_UNIT_ID = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;


BEGIN
  set_replication_language;
END REP_FIN_FUNCTIONS_LINK;
