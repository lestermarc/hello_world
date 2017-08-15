--------------------------------------------------------
--  DDL for Package Body REP_HRM_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_HRM_FUNCTIONS" 
/**
 * Fonctions de génération de document Xml.
 * Spécialisation: Ressources humaines (HRM)
 *
 * @version 1.0
 * @date 02/2003
 * @author spfister
 * @author pvogel
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
AS

function get_hrm_elements_id(
  elem_code IN hrm_elements.ele_code%TYPE)
  return hrm_elements.hrm_elements_id%TYPE
is
  ln_result hrm_elements.hrm_elements_id%TYPE;
begin
  select elemid
  into ln_result
  from v_hrm_elements_short
  where code = elem_code;
  return ln_result;

  exception
    --when no_data_found then return 0;
    when OTHERS then return 0;
end;

function get_hrm_elements_code(
  elem_code IN hrm_elements.ele_code%TYPE)
  return hrm_elements.ele_code%TYPE
is
  lv_result hrm_elements.ele_code%TYPE;
begin
  select code
  into lv_result
  from v_hrm_elements_short
  where code = elem_code;
  return lv_result;

  exception
    --when no_data_found then return null;
    when OTHERS then return null;
end;


--
-- Payroll
--

function get_hrm_elements_root_xml(
  Id IN hrm_elements_root.hrm_elements_root_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ROOTS,
      XMLElement(HRM_ELEMENTS_ROOT,
        XMLAttributes(
          hrm_elements_root_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'ELR_ROOT_NAME' as TABLE_KEY,
          hrm_elements_root_id,
          elr_root_code,
          elr_root_name,
          to_char(elr_from) as ELR_FROM,
          to_char(elr_to) as ELR_TO),
        rep_pc_functions.get_descodes('C_ROOT_TYPE',c_root_type),
        rep_pc_functions.get_descodes('C_ROOT_VARIANT',c_root_variant),
        XMLForest(
          elr_uses_sums,
          elr_uses_feedback,
          elr_uses_constent),
        rep_pc_functions.get_descodes('C_HRM_SAL_CONST_TYPE',c_hrm_sal_const_type),
        XMLForest(
--          0 as ELR_IS_ACTIVE,
          elr_is_certified,
          elr_round,
          elr_format,
          elr_sign,
          elr_default_value,
          elr_is_indiv,
          elr_reporting,
          elr_is_mandatory),
        rep_pc_functions.get_dictionary('DIC_GROUP1',dic_group1_id),
        rep_pc_functions.get_dictionary('DIC_GROUP2',dic_group2_id),
        rep_pc_functions.get_dictionary('DIC_GROUP3',dic_group3_id),
        rep_pc_functions.get_dictionary('DIC_GROUP4',dic_group4_id),
        XMLForest(
          elr_multi_currency),
          --ELR_CURRENCY), La monnaie est spécifiée par le champ ACS_FINANCIAL_CURRENCY_ID
        rep_hrm_functions_link.get_hrm_code_dic_link_value(hrm_code_dic_id,'HRM_CODE_DIC'),
        rep_hrm_functions_link.get_hrm_code_dic_link(hrm_code_dic_id),
        XMLForest(
          rep_hrm_functions.get_sums_used(hrm_elements_root_id) as ELR_SUMS_USED),
        rep_hrm_functions_link.get_hrm_elements_link(hrm_elements_id),
        XMLForest(
          elr_condition,
          elr_is_print),
          --ELR_BASE_AMOUNT, Ne doit plus être utilisé => hrm_elements_root_display
          --ELR_RATE, Ne doit plus être utilisé => hrm_elements_root_display
          --ELR_PER_RATE, Ne doit plus être utilisé => hrm_elements_root_display
        rep_fin_functions_link.get_acs_fin_curr_link(acs_financial_currency_id),
        XMLForest(
          elr_input_type,
          elr_is_base_cond,
          --ELR_BASE_COND_ID, Ne doit plus être utilisé
          elr_base_cond_code,
          elr_swap_dc,
          elr_is_break_inverse,
          elr_is_break,
          elr_use_ratio_group,
          elr_is_break_debit,
          elr_is_break_credit,
          elr_d_cgbase,
          elr_d_cg_shift_id,
          elr_d_is_break_div,
          elr_d_divbase,
          elr_c_cgbase,
          elr_c_cg_shift_id,
          elr_c_is_break_div,
          elr_c_divbase),
        rep_pc_functions.get_descodes('C_ROOT_FUNCTION',c_root_function),
        XMLForest(
          elr_root_rate,
          --ELR_SUM_AMOUNT, Ne doit plus être utilisé => hrm_elements_root_display
          elr_precision,
          elr_input_precision,
          elr_type,
          elr_is_budgeted,
          elr_is_visible),
        rep_hrm_functions.get_hrm_elements_root_descr(hrm_elements_root_id),
        rep_hrm_functions.get_hrm_elements_family(hrm_elements_root_id),
        rep_hrm_functions.get_hrm_elements_root_display(hrm_elements_root_id),
        rep_hrm_functions.get_hrm_break_structure(hrm_elements_id, rep_hrm_functions.BREAK_ELEMENT),
        rep_hrm_functions.get_hrm_control_elements(hrm_elements_root_id, rep_hrm_functions.CONTROL_ELEM_ROOT),
        rep_hrm_functions.get_hrm_salary_sheet_elements(hrm_elements_root_id),
        rep_pc_functions.get_com_vfields_record(hrm_elements_root_id,'HRM_ELEMENTS_ROOT'),
        rep_pc_functions.get_com_vfields_value(hrm_elements_root_id,'HRM_ELEMENTS_ROOT')
      )
    ) into lx_data
  from hrm_elements_root r
  where hrm_elements_root_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(ROOTS,
          XMLElement(HRM_ELEMENTS_ROOT,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_hrm_elements_root_descr(
  Id IN hrm_elements_root.hrm_elements_root_id%TYPE)
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
        'HRM_ELEMENTS_ROOT_ID,PC_LANG_ID' as TABLE_KEY,
        d.erd_lan_code,
        l.lanid,
        d.erd_descr,
        d.erd_subst_code,
        d.erd_comment)
    )) into lx_data
  from pcs.pc_lang l, hrm_elements_root_descr d
  where d.hrm_elements_root_id = Id and l.pc_lang_id = d.pc_lang_id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(HRM_ELEMENTS_ROOT_DESCR,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_hrm_elements_family(
  Id IN hrm_elements_root.hrm_elements_root_id%TYPE)
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
        'HRM_ELEMENTS_ROOT_ID,HRM_ELEMENTS_PREFIXES_ID,'||
          'HRM_ELEMENTS_SUFFIXES_ID' as TABLE_KEY),
      rep_hrm_functions_link.get_hrm_elements_prefixes_link(hrm_elements_prefixes_id),
      rep_hrm_functions_link.get_hrm_elements_suffixes_link(hrm_elements_suffixes_id),
      XMLForest(
        elf_expression,
        elf_sql),
      rep_hrm_functions_link.get_hrm_elements_link(hrm_elements_id),
      XMLForest(
        elf_is_reference,
        elf_priority),
      rep_hrm_functions_link.get_hrm_break_group_link(hrm_break_group_id),
      XMLForest(
        elf_agreg)
    ) order by elf_is_reference desc, hrm_elements_id ) into lx_data
  from hrm_elements_family
  where hrm_elements_root_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(HRM_ELEMENTS_FAMILY,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

/*function get_hrm_elements(Id in hrm_elements.hrm_elements_id%TYPE)
  return XMLType;
is
  lx_data XMLType;
  IsElem BINARY_INTEGER;
  IsConst BINARY_INTEGER;
begin
  if (Id is null) then
    return null;
  end if;

  -- Sélection du branchement entre variables et constantes
  select
    (select count(*) from dual
     where Exists(select 1 from HRM_ELEMENTS
                  where hrm_elements_id = Id)) is_elem,
    (select count(*) from dual
     where Exists(select 1 from HRM_CONSTANTS
                  where hrm_constants_id = Id)) is_const
    into IsElem, IsConst
  from dual;

  if (IsElem = 1) then
    select
      XMLElement(HRM_ELEMENTS
        XMLForest(
          'AFTER' as TABLE_TYPE,
          'ELE_CODE' as TABLE_KEY),
HRM_ELEMENTS;ELE_IS_SQL;NUMBER(1);N;FIELD;Y
HRM_ELEMENTS;ELE_EXPRESSION;VARCHAR2(1024);Y;FIELD;Y
HRM_ELEMENTS;ELE_CORRELATED_ID;NUMBER(12);Y;LINK;Y
HRM_ELEMENTS;ELE_REPORTING;NUMBER(1);N;FIELD;Y
HRM_ELEMENTS;ELE_MULTI_CURRENCY;NUMBER(1);N;FIELD;Y
HRM_ELEMENTS;ELE_SIGN;VARCHAR2(1);Y;FIELD;Y
HRM_ELEMENTS;ELE_IS_INDIV;NUMBER(1);Y;FIELD;Y
HRM_ELEMENTS;ELE_TYPE;NUMBER(1);Y;FIELD;Y
HRM_ELEMENTS;ELE_INPUT_MODE;VARCHAR2(4);Y;FIELD;Y
HRM_ELEMENTS;ELE_BREAK_INPUT_MODE;VARCHAR2(4);Y;FIELD;Y
HRM_ELEMENTS;ELE_USE_RATIO_GROUP;VARCHAR2(20);Y;FIELD;Y
HRM_ELEMENTS;ELE_IS_BASE_BREAK;NUMBER(1);Y;FIELD;Y
HRM_ELEMENTS;ELE_IS_BREAK_INVERSE;NUMBER(1);Y;FIELD;Y
HRM_ELEMENTS;ELE_IS_BREAK;NUMBER(1);N;FIELD;Y
HRM_ELEMENTS;ELE_SWAP_DC;NUMBER(1);N;FIELD;Y
HRM_ELEMENTS;ELE_IS_BREAK_DEBIT;NUMBER(1);N;FIELD;Y
HRM_ELEMENTS;ELE_IS_BREAK_CREDIT;NUMBER(1);N;FIELD;Y
HRM_ELEMENTS;ELE_D_CGBASE;VARCHAR2(30);Y;FIELD;Y
HRM_ELEMENTS;ELE_D_CG_SHIFT_ID;NUMBER(12);Y;LINK;Y
HRM_ELEMENTS;ELE_D_IS_BREAK_DIV;NUMBER(1);Y;FIELD;Y
HRM_ELEMENTS;ELE_D_DIVBASE;VARCHAR2(30);Y;FIELD;Y
HRM_ELEMENTS;ELE_D_DIV_SHIFT_ID;NUMBER(12);Y;LINK;Y
HRM_ELEMENTS;ELE_D_CPNBASE;VARCHAR2(30);Y;FIELD;Y
HRM_ELEMENTS;ELE_D_PFEMPL;NUMBER(1);Y;FIELD;Y
HRM_ELEMENTS;ELE_D_PFBASE;VARCHAR2(30);Y;FIELD;Y
HRM_ELEMENTS;ELE_D_PF_SHIFT_ID;NUMBER(12);Y;LINK;Y
HRM_ELEMENTS;ELE_D_PJEMPL;NUMBER(1);Y;FIELD;Y
HRM_ELEMENTS;ELE_D_PJBASE;VARCHAR2(30);Y;FIELD;Y
HRM_ELEMENTS;ELE_D_PJ_SHIFT_ID;NUMBER(12);Y;LINK;Y
HRM_ELEMENTS;ELE_D_CDAEMPL;NUMBER(1);Y;FIELD;Y
HRM_ELEMENTS;ELE_D_CDABASE;VARCHAR2(30);Y;FIELD;Y
HRM_ELEMENTS;ELE_D_CDA_SHIFT_ID;NUMBER(12);Y;LINK;Y
HRM_ELEMENTS;ELE_C_CGBASE;VARCHAR2(30);Y;FIELD;Y
HRM_ELEMENTS;ELE_C_CG_SHIFT_ID;NUMBER(12);Y;LINK;Y
HRM_ELEMENTS;ELE_C_IS_BREAK_DIV;NUMBER(1);Y;FIELD;Y
HRM_ELEMENTS;ELE_C_DIVBASE;VARCHAR2(30);Y;FIELD;Y
HRM_ELEMENTS;ELE_C_DIV_SHIFT_ID;NUMBER(12);Y;LINK;Y
HRM_ELEMENTS;ELE_C_CPNBASE;VARCHAR2(30);Y;FIELD;Y
HRM_ELEMENTS;ELE_C_PFEMPL;NUMBER(1);Y;FIELD;Y
HRM_ELEMENTS;ELE_C_PFBASE;VARCHAR2(30);Y;FIELD;Y
HRM_ELEMENTS;ELE_C_PF_SHIFT_ID;NUMBER(12);Y;LINK;Y
HRM_ELEMENTS;ELE_C_PJEMPL;NUMBER(1);Y;FIELD;Y
HRM_ELEMENTS;ELE_C_PJBASE;VARCHAR2(30);Y;FIELD;Y
HRM_ELEMENTS;ELE_C_PJ_SHIFT_ID;NUMBER(12);Y;LINK;Y
HRM_ELEMENTS;ELE_C_CDAEMPL;NUMBER(1);Y;FIELD;Y
HRM_ELEMENTS;ELE_C_CDABASE;VARCHAR2(30);Y;FIELD;Y
HRM_ELEMENTS;ACS_FINANCIAL_CURRENCY_ID;NUMBER(12);Y;LINK;Y
HRM_ELEMENTS;ELE_C_CDA_SHIFT_ID;NUMBER(12);Y;LINK;Y
HRM_ELEMENTS;DIC_GROUP2_ID;VARCHAR2(20);Y;DICTIONARY;Y
HRM_ELEMENTS;DIC_GROUP3_ID;VARCHAR2(20);Y;DICTIONARY;Y
HRM_ELEMENTS;DIC_GROUP1_ID;VARCHAR2(20);Y;DICTIONARY;Y
HRM_ELEMENTS;DIC_GROUP4_ID;VARCHAR2(20);Y;DICTIONARY;Y
HRM_ELEMENTS;ELE_DEFAULT_VALUE;VARCHAR2(255);Y;FIELD;Y
HRM_ELEMENTS;ELE_IS_BASE;NUMBER(1);N;FIELD;Y
HRM_ELEMENTS;ELE_IS_DLL;NUMBER(1);Y;FIELD;Y
HRM_ELEMENTS;ELE_IS_SQL_IN;NUMBER(1);Y;FIELD;Y
HRM_ELEMENTS;ELE_INPUT_PRECISION;NUMBER(1);Y;FIELD;Y
HRM_ELEMENTS;ELE_CODE;VARCHAR2(100);N;FIELD;Y
HRM_ELEMENTS;ELE_STAT_CODE;VARCHAR2(6);Y;FIELD;Y
HRM_ELEMENTS;ELE_PRECISION;NUMBER(10,5);Y;FIELD;Y
HRM_ELEMENTS;ELE_ROUND;NUMBER(1);Y;FIELD;Y
HRM_ELEMENTS;ELE_ALIAS_NAME;VARCHAR2(100);Y;FIELD;Y
HRM_ELEMENTS;ELE_SQL;VARCHAR2(1024);Y;FIELD;Y
HRM_ELEMENTS;ELE_VALID_FROM;DATE;N;FIELD;Y
HRM_ELEMENTS;ELE_VALID_TO;DATE;N;FIELD;Y
HRM_ELEMENTS;ELE_FORMAT;NUMBER(1);N;FIELD;Y
HRM_ELEMENTS;ELE_ACTIVE;NUMBER(1);N;FIELD;Y
HRM_ELEMENTS;ELE_VARIABLE;NUMBER(1);N;FIELD;Y

      ) into lx_data
    from hrm_elements
    where hrm_elements_id = Id;
    return lx_data;
  elsif (IsConst = 1) then
    select
      XMLElement(HRM_CONSTANTS
        XMLForest(
          'AFTER' as TABLE_TYPE,
          'CON_CODE' as TABLE_KEY),
      ) into lx_data
    from hrm_constants
    where hrm_constants_id = Id;
    return lx_data;
  else
    return null;
  end if;

  exception
    when NO_DATA_FOUND then return null;
end;*/

function get_hrm_elements_root_display(
  Id IN hrm_elements_root.hrm_elements_root_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  -- Jointure gauche pour retourner toutes les colonnes,
  -- même si elles n'existent pas pour le GS
  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'HRM_ELEMENTS_ROOT_ID,C_COLUMN_TYPE' as TABLE_KEY),
      rep_pc_functions.get_descodes('C_COLUMN_TYPE',v.gclcode),
      XMLForest(
        eld_condition)
    )order by v.gclcode) into lx_data
  from
    hrm_elements_root_display rd,
    (select gclcode from pcs.pc_gclst
     where pc_gcgrp_id = (select pc_gcgrp_id from pcs.pc_gcgrp
                          where gcgname = 'C_COLUMN_TYPE')
     ) v
  where rd.hrm_elements_root_id(+) = Id and
    rd.c_column_type(+) = v.gclcode;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(HRM_ELEMENTS_ROOT_DISPLAY,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_hrm_break_structure(
  Id IN NUMBER,
  Source IN INTEGER)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  case source
    when rep_hrm_functions.BREAK_STRUCTURE then
      select
        XMLAgg(XMLElement(LIST_ITEM,
          XMLForest(
            'AFTER' as TABLE_TYPE,
            'HRM_ALLOCATION_ID, BRE_ITEM_ID' as TABLE_KEY,
            hrm_break_structure_id),
          rep_hrm_functions_link.get_hrm_allocation_link(hrm_allocation_id),
          rep_hrm_functions_link.get_hrm_elements_link(bre_item_id, 'BRE_ITEM'),
          rep_hrm_functions_link.get_ele_code_link(bre_item_id, 'BRE_ITEM_NAME')
        )) into lx_data
      from hrm_break_structure bs
      where hrm_break_structure_id = Id;
      -- Générer le tag principal uniquement s'il y a données
      if (lx_data is not null) then
        select
          XMLElement(HRM_BREAK_STRUCTURE,
            XMLElement(LIST, lx_data)
          ) into lx_data
        from dual;
        return lx_data;
      end if;
    when rep_hrm_functions.BREAK_ELEMENT then
      select
        XMLElement(HRM_BREAK_STRUCTURE,
          XMLForest(
            'AFTER' as TABLE_TYPE,
            'HRM_ALLOCATION_ID, BRE_ITEM_ID' as TABLE_KEY,
            hrm_break_structure_id),
          rep_hrm_functions_link.get_hrm_allocation_link(hrm_allocation_id),
          rep_hrm_functions_link.get_hrm_elements_link(bre_item_id, 'BRE_ITEM'),
          rep_hrm_functions_link.get_ele_code_link(bre_item_id, 'BRE_ITEM_NAME')
        ) into lx_data
      from (
        select Max(hrm_break_structure_id) hrm_break_structure_id, hrm_allocation_id, bre_item_id
        from hrm_break_structure
        where bre_item_id = id
        group by hrm_allocation_id, bre_item_id) bs;
      return lx_data;
  end case;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_hrm_salary_sheet_elements(
  Id IN hrm_elements_root.hrm_elements_root_id%TYPE)
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
        'HRM_SALARY_SHEET_ID, HRM_ELEMENTS_ID' as TABLE_KEY),
      rep_hrm_functions_link.get_hrm_salary_sheet_link(hrm_salary_sheet_id),
      rep_hrm_functions_link.get_hrm_elements_link(hrm_elements_id)
    )) into lx_data
  from hrm_salary_sheet_elements
  where hrm_elements_id in
    (select hrm_elements_id from hrm_elements_family
     where hrm_elements_root_id = Id);
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(HRM_SALARY_SHEET_ELEMENTS,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_sums_used(
  Id IN hrm_elements_root.hrm_elements_root_id%TYPE)
  return VARCHAR2
is
  cursor csUsedBase(
    RootId IN NUMBER)
  is
    select e.ele_code
    from hrm_elements e, hrm_formulas_structure fs, hrm_elements_family f
    where
      f.hrm_elements_root_id = RootId and f.elf_is_reference = 1 and
      fs.related_id = f.hrm_elements_id and
      e.hrm_elements_id = (select hrm_elements_id from hrm_elements_root
                           where c_root_variant = 'Base' and hrm_elements_id = fs.main_id);
  lv_result VARCHAR2(4000);
begin
  lv_result := '';
  for tplUsedSums in csUsedBase(Id) loop
    lv_result := lv_result ||','|| tplUsedSums.ele_code;
  end loop;

  return LTrim(lv_result, ',');
end;


--
-- Control list
--

function get_hrm_control_list_xml(
  Id IN hrm_control_list.hrm_control_list_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(LISTS,
      XMLElement(HRM_CONTROL_LIST,
        XMLAttributes(
          hrm_control_list_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'COL_NAME' as TABLE_KEY,
          hrm_control_list_id,
          col_name,
          col_descr,
          col_isstandard),
        rep_pc_functions.get_descodes('C_CONTROL_LIST_TYPE',c_control_list_type),
        rep_hrm_functions.get_hrm_control_elements(hrm_control_list_id, rep_hrm_functions.CONTROL_ELEM_LIST),
        rep_pc_functions.get_com_vfields_record(hrm_control_list_id,'HRM_CONTROL_LIST'),
        rep_pc_functions.get_com_vfields_value(hrm_control_list_id,'HRM_CONTROL_LIST')
      )
    ) into lx_data
  from hrm_control_list
  where hrm_control_list_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(LISTS,
          XMLElement(HRM_CONTROL_LIST,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_hrm_control_elements(
  Id IN NUMBER,
  Source IN INTEGER)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  case Source
    when rep_hrm_functions.CONTROL_ELEM_LIST then
      select
        XMLAgg(XMLElement(LIST_ITEM,
          XMLForest(
            'AFTER' as TABLE_TYPE,
            'HRM_CONTROL_LIST_ID,HRM_CONTROL_ELEMENTS_ID' as TABLE_KEY),
          rep_hrm_functions_link.get_hrm_elements_link(hrm_control_elements_id, 'HRM_CONTROL_ELEMENTS'),
          rep_hrm_functions.get_hrm_control_elements_descr(hrm_control_elem_id),
          XMLForest(
            coe_code,
            coe_box,
            --coe_use_history, N'est pas utilisé !!
            coe_inverse)
        ) order by coe_box ) into lx_data
      from hrm_control_elements
      where hrm_control_list_id = Id;
    when rep_hrm_functions.CONTROL_ELEM_ROOT then
      select
        XMLAgg(XMLElement(LIST_ITEM,
          XMLForest(
            'AFTER' as TABLE_TYPE,
            'HRM_CONTROL_LIST_ID,HRM_CONTROL_ELEMENTS_ID' as TABLE_KEY),
          rep_hrm_functions_link.get_hrm_control_list_link(hrm_control_list_id),
          rep_hrm_functions_link.get_hrm_elements_link(hrm_control_elements_id, 'HRM_CONTROL_ELEMENTS'),
          rep_hrm_functions.get_hrm_control_elements_descr(hrm_control_elem_id),
          XMLForest(
            coe_code,
            coe_box,
            coe_use_history,
            coe_inverse)
        ) order by coe_box ) into lx_data
      from hrm_control_elements
      where hrm_control_elements_id in (
        select hrm_elements_id from hrm_elements_family
        where hrm_elements_root_id = Id);
  end case;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(HRM_CONTROL_ELEMENTS,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_hrm_control_elements_descr(
  Id IN hrm_control_elements.hrm_control_elem_id%TYPE)
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
        'HRM_CONTROL_ELEM_ID,PC_LANG_ID' as TABLE_KEY,
        l.lanid,
        d.hed_descr)
    )) into lx_data
  from pcs.pc_lang l, hrm_control_elements_descr d
  where d.hrm_control_elem_id = Id and l.pc_lang_id = d.pc_lang_id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(HRM_CONTROL_ELEMENTS_DESCR,
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
-- Breakdown
--

function get_hrm_allocation_xml(
  Id hrm_allocation.hrm_allocation_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ALLOCATIONS,
      XMLElement(HRM_ALLOCATION,
        XMLAttributes(
          hrm_allocation_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'ALL_CODE' as TABLE_KEY,
          hrm_allocation_id),
        rep_pc_functions.get_dictionary('DIC_ALLOCATION_TYPE',dic_allocation_type_id),
        XMLForest(
          all_code,
          all_descr),
        rep_pc_functions.get_com_vfields_record(hrm_allocation_id,'HRM_ALLOCATION'),
        rep_pc_functions.get_com_vfields_value(hrm_allocation_id,'HRM_ALLOCATION')
      )
    ) into lx_data
  from hrm_allocation
  where hrm_allocation_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(ALLOCATIONS,
          XMLElement(HRM_ALLOCATION,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

END REP_HRM_FUNCTIONS;
