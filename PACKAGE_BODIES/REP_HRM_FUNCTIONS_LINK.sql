--------------------------------------------------------
--  DDL for Package Body REP_HRM_FUNCTIONS_LINK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_HRM_FUNCTIONS_LINK" 
/**
 * Fonctions de génération de liaison pour document Xml.
 * Spécialisation: Personnel et RH
 *
 * @version 1.0
 * @date 09/2004
 * @author spfister
 *
 * Copyright 1997-2011 SolvAxis SA. Tous droits réservés.
 */
AS

function get_hrm_person_link(
    Id IN hrm_person.hrm_person_id%TYPE,
  FieldRef IN VARCHAR2 default 'HRM_PERSON',
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
    XMLElement(HRM_PERSON,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'PER_FIRST_NAME,PER_LAST_NAME,PER_BIRTH_DATE,EMP_NUMBER' as TABLE_KEY,
        hrm_person_id,
        per_first_name,
        per_last_name,
        to_char(per_birth_date) as PER_BIRTH_DATE,
        emp_number)
    ) into lx_data
  from hrm_person
  where hrm_person_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'HRM_PERSON') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('HRM_PERSON', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('HRM_PERSON', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;


function get_hrm_elements_link(
  Id IN hrm_elements.hrm_elements_id%TYPE,
  FieldRef IN VARCHAR2 default 'HRM_ELEMENTS')
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(HRM_ELEMENTS,
      XMLForest(
        'FUNCTION' as TABLE_TYPE,
        'REP_HRM_FUNCTIONS.GET_HRM_ELEMENTS_ID' as FUNCTION_NAME,
        Id as HRM_ELEMENTS_ID),
      XMLElement(PARAMETERS,
        XMLElement(PARAMETER,
          XMLAttributes(1 as NUM,'VARCHAR' as TYPE),
          code)
      )) into lx_data
  from v_hrm_elements_short
  where elemid = Id;

  if (lx_data is not null) then
    if (FieldRef != 'HRM_ELEMENTS') then
      return rep_xml_function.transform_root_ref('HRM_ELEMENTS', FieldRef, lx_data);
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_ele_code_link(
  Id IN hrm_elements.hrm_elements_id%TYPE,
  FieldRef IN VARCHAR2 default 'HRM_ELEMENTS')
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(HRM_ELEMENTS,
      XMLForest(
        'FUNCTION' as TABLE_TYPE,
        'REP_HRM_FUNCTIONS.GET_HRM_ELEMENTS_CODE' as FUNCTION_NAME,
        Id as HRM_ELEMENTS_ID),
      XMLElement(PARAMETERS,
        XMLElement(PARAMETER,
          XMLAttributes(1 as NUM,'VARCHAR' as TYPE),
          code)
      )) into lx_data
  from v_hrm_elements_short
  where elemid = Id;

  if (lx_data is not null) then
    if (FieldRef != 'HRM_ELEMENTS') then
      return rep_xml_function.transform_root_ref('HRM_ELEMENTS', FieldRef, lx_data);
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;


function get_hrm_elements_prefixes_link(
  Id IN hrm_elements_prefixes.hrm_elements_prefixes_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  -- Identifiant est de type VARCHAR2
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(HRM_ELEMENTS_PREFIXES,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'HRM_ELEMENTS_PREFIXES_ID' as TABLE_KEY,
        hrm_elements_prefixes_id)
    ) into lx_data
  from hrm_elements_prefixes
  where hrm_elements_prefixes_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_hrm_elements_suffixes_link(
  Id IN hrm_elements_suffixes.hrm_elements_suffixes_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  -- Identifiant est de type VARCHAR2
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(HRM_ELEMENTS_SUFFIXES,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'HRM_ELEMENTS_SUFFIXES_ID' as TABLE_KEY,
        hrm_elements_suffixes_id)
    ) into lx_data
  from hrm_elements_suffixes
  where hrm_elements_suffixes_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_hrm_break_group_link(
  Id IN hrm_break_group.hrm_break_group_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(HRM_BREAK_GROUP,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'BRE_DESCRIPTION' as TABLE_KEY,
        hrm_break_group_id,
        bre_description)
    ) into lx_data
  from hrm_break_group
  where hrm_break_group_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;


function get_hrm_code_dic_link(
  Id IN hrm_code_dic.hrm_code_dic_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(HRM_CODE_DIC,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'DIC_DESCR' as TABLE_KEY,
        hrm_code_dic_id,
        dic_descr)
    ) into lx_data
  from hrm_code_dic
  where hrm_code_dic_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_hrm_code_dic_link_value(
  Id IN hrm_code_dic.hrm_code_dic_id%TYPE,
  FieldRef IN VARCHAR2 default 'HRM_CODE_DIC')
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  lx_data := rep_hrm_functions_link.get_hrm_code_dic_link(Id);
  if (lx_data is not null and FieldRef != 'HRM_CODE_DIC') then
    return rep_xml_function.transform_root_ref_table('HRM_CODE_DIC', FieldRef, lx_data);
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_hrm_control_list_link(
  Id IN hrm_control_list.hrm_control_list_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(HRM_CONTROL_LIST,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'COL_NAME' as TABLE_KEY,
        hrm_control_list_id,
        col_name)
    ) into lx_data
  from hrm_control_list
  where hrm_control_list_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_hrm_allocation_link(
  Id IN hrm_allocation.hrm_allocation_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(HRM_ALLOCATION,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'ALL_CODE' as TABLE_KEY,
        hrm_allocation_id,
        all_code)
    ) into lx_data
  from hrm_allocation
  where hrm_allocation_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_hrm_salary_sheet_link(
  Id IN hrm_salary_sheet.hrm_salary_sheet_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(HRM_SALARY_SHEET,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'SAL_CODE' as TABLE_KEY,
        hrm_salary_sheet_id,
        sal_code)
    ) into lx_data
  from hrm_salary_sheet
  where hrm_salary_sheet_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

END REP_HRM_FUNCTIONS_LINK;
