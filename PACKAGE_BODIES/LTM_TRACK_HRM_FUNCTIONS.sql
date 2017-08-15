--------------------------------------------------------
--  DDL for Package Body LTM_TRACK_HRM_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "LTM_TRACK_HRM_FUNCTIONS" 
/**
 * Package LTM_TRACK_HRM_FUNCTIONS
 * @version 1.0
 * @date 01/2006
 * @author rhermann
 * @author ireber
 * @author spfister
 * @since Oracle 9.2
 *
 * Copyright 1997-2008 Pro-Concept SA. Tous droits réservés.
 *
 * Package contenant les fonctions de génération de document Xml pour le
 * suivi do modifications.
 * Spécialisation: Ressources humaines (HRM)
 */
AS

--
-- PERSON
--

function get_hrm_person_xml(Id IN hrm_person.hrm_person_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(HRM_PERSON,
      XMLAttributes(
        sys_context('userenv', 'current_schema') as "CURRENT_SCHEMA",
        sys_context('userenv', 'current_user') as "CURRENT_USER",
        sys_context('userenv', 'terminal') as "TERMINAL",
        sys_context('userenv', 'nls_date_format') as "NLS_DATE_FORMAT"),
      ltm_xml_utils.genXML(CURSOR(
        select * from hrm_person
        where hrm_person_id = T.hrm_person_id),
        ''),
      ltm_track_pc_functions.get_com_vfields_record(hrm_person_id, 'HRM_PERSON'),
      ltm_track_pc_functions.get_com_vfields_value(hrm_person_id, 'HRM_PERSON'),
      ltm_track_hrm_functions.get_hrm_training_history(hrm_person_id),
      ltm_track_hrm_functions.get_hrm_subscription(hrm_person_id),
      ltm_track_hrm_functions.get_hrm_related_to(hrm_person_id),
      ltm_track_hrm_functions.get_hrm_person_job(hrm_person_id),
      ltm_track_hrm_functions.get_hrm_person_experience(hrm_person_id),
      ltm_track_hrm_functions.get_hrm_occupation_history(hrm_person_id),
      ltm_track_hrm_functions.get_hrm_lang(hrm_person_id),
      ltm_track_hrm_functions.get_hrm_in_out(hrm_person_id),
      ltm_track_hrm_functions.get_hrm_financial_ref(hrm_person_id),
      ltm_track_hrm_functions.get_hrm_employee_wk_permit(hrm_person_id),
      ltm_track_hrm_functions.get_hrm_employee_break(hrm_person_id),
      ltm_track_hrm_functions.get_hrm_compl_data_france(hrm_person_id),
      ltm_track_hrm_functions.get_hrm_competence_link(hrm_person_id)
    ) into obj
  from hrm_person T
  where hrm_person_id = Id;
  return obj;

  exception
    when OTHERS then
      obj := COM_XmlErrorDetail(sqlerrm);
      select
        XMLElement(HRM_PERSON,
          XMLAttributes(
            Id as ID,
            sys_context('userenv', 'current_schema') as "CURRENT_SCHEMA",
            sys_context('userenv', 'current_user') as "CURRENT_USER",
            sys_context('userenv', 'terminal') as "TERMINAL",
            sys_context('userenv', 'nls_date_format') as "NLS_DATE_FORMAT"),
          obj
        ) into obj
      from dual;
      return obj;
end;

function get_hrm_employee_wk_permit(Id IN hrm_person.hrm_person_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(HRM_EMPLOYEE_WK_PERMIT,
      ltm_xml_utils.genXML(CURSOR(
        select * from hrm_employee_wk_permit
        where wop_number_id = T.wop_number_id),
        ''),
      ltm_track_pc_functions.get_com_vfields_record(wop_number_id, 'HRM_EMPLOYEE_WK_PERMIT'),
      ltm_track_pc_functions.get_com_vfields_value(wop_number_id, 'HRM_EMPLOYEE_WK_PERMIT'))
      order by a_datecre
    ) into obj
  from hrm_employee_wk_permit T
  where hrm_person_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_hrm_subscription(Id IN hrm_person.hrm_person_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(HRM_SUBSCRIPTION,
      ltm_xml_utils.genXML(CURSOR(
        select * from hrm_subscription
        where hrm_subscription_id = T.hrm_subscription_id),
        ''),
      ltm_track_pc_functions.get_com_vfields_record(hrm_subscription_id, 'HRM_SUBSCRIPTION'),
      ltm_track_pc_functions.get_com_vfields_value(hrm_subscription_id, 'HRM_SUBSCRIPTION'),
      ltm_track_hrm_functions_link.get_hrm_training_link(hrm_training_id),
      ltm_track_hrm_functions_link.get_hrm_session_link(hrm_session_id))
      order by hrm_subscription_id
    ) into obj
  from hrm_subscription T
  where hrm_person_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_hrm_training_history(Id IN hrm_person.hrm_person_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(HRM_TRAINING_HISTORY,
      ltm_xml_utils.genXML(CURSOR(
        select * from hrm_training_history
        where hrm_training_history_id = T.hrm_training_history_id),
        ''),
      ltm_track_pc_functions.get_com_vfields_record(hrm_training_history_id, 'HRM_TRAINING_HISTORY'),
      ltm_track_pc_functions.get_com_vfields_value(hrm_training_history_id, 'HRM_TRAINING_HISTORY'))
      order by hrm_training_history_id
    ) into obj
  from hrm_training_history T
  where hrm_person_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_hrm_compl_data_france(Id IN hrm_person.hrm_person_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(
      ltm_xml_utils.genXML(CURSOR(
        select * from hrm_compl_data_france
        where hrm_person_id = T.hrm_person_id),
        'HRM_COMPL_DATA_FRANCE')
      order by a_datecre
    ) into obj
  from hrm_compl_data_france T
  where hrm_person_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_hrm_lang(Id IN hrm_person.hrm_person_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(HRM_LANG,
      ltm_xml_utils.genXML(CURSOR(
        select * from hrm_lang
        where hrm_lang_id = T.hrm_lang_id),
        ''),
      ltm_track_pc_functions_link.get_pc_lang_link(pc_lang_id),
      ltm_track_pc_functions.get_com_vfields_record(hrm_lang_id, 'HRM_LANG'),
      ltm_track_pc_functions.get_com_vfields_value(hrm_lang_id, 'HRM_LANG'))
      order by a_datecre
    ) into obj
  from hrm_lang T
  where hrm_person_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_hrm_person_experience(Id IN hrm_person.hrm_person_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(HRM_PERSON_EXPERIENCE,
      ltm_xml_utils.genXML(CURSOR(
        select * from hrm_person_experience
        where hrm_person_experience_id = T.hrm_person_experience_id),
        ''),
      ltm_track_pc_functions.get_com_vfields_record(hrm_person_experience_id, 'HRM_PERSON_EXPERIENCE'),
      ltm_track_pc_functions.get_com_vfields_value(hrm_person_experience_id, 'HRM_PERSON_EXPERIENCE'))
      order by a_datecre
    ) into obj
  from hrm_person_experience T
  where hrm_person_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_hrm_occupation_history(Id IN hrm_person.hrm_person_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(HRM_OCCUPATION_HISTORY,
      ltm_xml_utils.genXML(CURSOR(
        select * from hrm_occupation_history
        where hrm_occupation_history_id = T.hrm_occupation_history_id),
        ''),
      ltm_track_pc_functions.get_com_vfields_record(hrm_occupation_history_id, 'HRM_OCCUPATION_HISTORY'),
      ltm_track_pc_functions.get_com_vfields_value(hrm_occupation_history_id, 'HRM_OCCUPATION_HISTORY'),
      ltm_track_hrm_functions_link.get_hrm_occupation_descr_link(hrm_occupation_id))
      order by a_datecre
    ) into obj
  from hrm_occupation_history T
  where hrm_person_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_hrm_person_job(Id IN hrm_person.hrm_person_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(HRM_PERSON_JOB,
      ltm_xml_utils.genXML(CURSOR(
        select * from hrm_person_job
        where hrm_person_job_id = T.hrm_person_job_id),
        ''),
      ltm_track_pc_functions.get_com_vfields_record(hrm_person_job_id, 'HRM_PERSON_JOB'),
      ltm_track_pc_functions.get_com_vfields_value(hrm_person_job_id, 'HRM_PERSON_JOB'),
      ltm_track_hrm_functions_link.get_hrm_job_link(hrm_job_id))
      order by hrm_person_job_id
    ) into obj
  from hrm_person_job T
  where hrm_person_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_hrm_employee_break(Id IN hrm_person.hrm_person_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(HRM_EMPLOYEE_BREAK,
      ltm_xml_utils.genXML(CURSOR(
        select * from hrm_employee_break
        where hrm_employee_break_id = T.hrm_employee_break_id),
        ''),
      ltm_track_pc_functions.get_com_vfields_record(hrm_employee_break_id, 'HRM_EMPLOYEE_BREAK'),
      ltm_track_pc_functions.get_com_vfields_value(hrm_employee_break_id, 'HRM_EMPLOYEE_BREAK'))
      order by a_datecre
    ) into obj
  from hrm_employee_break T
  where hrm_employee_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_hrm_related_to(Id IN hrm_person.hrm_person_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(HRM_RELATED_TO,
      ltm_xml_utils.genXML(CURSOR(
        select * from hrm_related_to
        where hrm_related_to_id = T.hrm_related_to_id),
        ''),
     (select
        XMLAgg(XMLElement(HRM_RELATED_ALLOCATION,
          ltm_xml_utils.genXML(CURSOR(
            select * from hrm_related_allocation
            where hrm_related_allocation_id= T2.hrm_related_allocation_id),
            ''),
          ltm_track_pc_functions.get_com_vfields_record(hrm_related_allocation_id, 'HRM_RELATED_ALLOCATION'),
          ltm_track_pc_functions.get_com_vfields_value(hrm_related_allocation_id, 'HRM_RELATED_ALLOCATION'))
        order by a_datecre)
      from hrm_related_allocation T2
      where T2.hrm_related_to_id = T.hrm_related_to_id),
      ltm_track_pc_functions.get_com_vfields_record(hrm_related_to_id, 'HRM_RELATED_TO'),
      ltm_track_pc_functions.get_com_vfields_value(hrm_related_to_id, 'HRM_RELATED_TO'))
      order by a_datecre
    ) into obj
  from hrm_related_to T
  where hrm_employee_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_hrm_financial_ref(Id IN hrm_person.hrm_person_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(HRM_FINANCIAL_REF,
      ltm_xml_utils.genXML(CURSOR(
        select * from hrm_financial_ref
        where hrm_financial_ref_id = T.hrm_financial_ref_id),
        ''),
      ltm_track_pc_functions.get_com_vfields_record(hrm_financial_ref_id, 'HRM_FINANCIAL_REF'),
      ltm_track_pc_functions.get_com_vfields_value(hrm_financial_ref_id, 'HRM_FINANCIAL_REF'),
      ltm_track_fin_functions_link.get_acs_fin_curr_link(acs_financial_currency_id, 'PC_CURR'),
      ltm_track_pc_functions_link.get_pc_bank_link(pc_bank_id))
      order by a_datecre
    ) into obj
  from hrm_financial_ref T
  where hrm_employee_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_hrm_competence_link(Id IN hrm_person.hrm_person_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(HRM_COMPETENCE_LINK,
      ltm_xml_utils.genXML(CURSOR(
        select * from hrm_competence_link
        where hrm_competence_link_id = T.hrm_competence_link_id),
        ''),
      ltm_track_pc_functions.get_com_vfields_record(hrm_competence_link_id, 'HRM_COMPETENCE_LINK'),
      ltm_track_pc_functions.get_com_vfields_value(hrm_competence_link_id, 'HRM_COMPETENCE_LINK'),
      ltm_track_hrm_functions_link.get_hrm_competence_link(hrm_competence_id))
      order by a_datecre
    ) into obj
  from hrm_competence_link T
  where hrm_person_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_hrm_in_out(Id IN hrm_person.hrm_person_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(HRM_IN_OUT,
      ltm_xml_utils.genXML(CURSOR(
        select * from hrm_in_out
        where hrm_in_out_id = T.hrm_in_out_id),
        ''),
     (select
        XMLAgg(XMLElement(HRM_CONTRACT,
          ltm_xml_utils.genXML(CURSOR(
            select * from hrm_contract
            where hrm_contract_id = T2.hrm_contract_id),
            ''),
          ltm_track_pc_functions.get_com_vfields_record(hrm_contract_id, 'HRM_CONTRACT'),
          ltm_track_pc_functions.get_com_vfields_value(hrm_contract_id, 'HRM_CONTRACT'))
        order by a_datecre)
      from hrm_contract T2
      where T2.hrm_in_out_id = T.hrm_in_out_id),
      ltm_track_pc_functions.get_com_vfields_record(hrm_in_out_id, 'HRM_IN_OUT'),
      ltm_track_pc_functions.get_com_vfields_value(hrm_in_out_id, 'HRM_IN_OUT'))
      order by a_datecre
    ) into obj
  from hrm_in_out T
  where hrm_employee_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;


--
-- JOB
--

function get_hrm_job_xml(Id IN hrm_job.hrm_job_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(HRM_JOB,
      XMLAttributes(
        sys_context('userenv', 'current_schema') as "CURRENT_SCHEMA",
        sys_context('userenv', 'current_user') as "CURRENT_USER",
        sys_context('userenv', 'terminal') as "TERMINAL",
        sys_context('userenv', 'nls_date_format') as "NLS_DATE_FORMAT"),
      ltm_xml_utils.genXML(CURSOR(
        select * from hrm_job
        where hrm_job_id = T.hrm_job_id),
        ''),
      ltm_track_pc_functions.get_com_vfields_record(hrm_job_id, 'hrm_job'),
      ltm_track_pc_functions.get_com_vfields_value(hrm_job_id, 'hrm_job'),
     (select
        XMLAgg(XMLElement(HRM_COMPETENCE_LINK,
          ltm_xml_utils.genXML(CURSOR(
            select * from hrm_competence_link
            where hrm_competence_link_id = T2.hrm_competence_link_id),
            ''),
          ltm_track_hrm_functions_link.get_hrm_competence_link(hrm_competence_id))
        order by a_datecre)
      from hrm_competence_link T2
      where T2.hrm_job_id = T.hrm_job_id)
    ) into obj
  from hrm_job T
  where hrm_job_id = Id;
  return obj;

  exception
    when OTHERS then
      obj := COM_XmlErrorDetail(sqlerrm);
      select
        XMLElement(HRM_JOB,
          XMLAttributes(
            Id as ID,
            sys_context('userenv', 'current_schema') as "CURRENT_SCHEMA",
            sys_context('userenv', 'current_user') as "CURRENT_USER",
            sys_context('userenv', 'terminal') as "TERMINAL",
            sys_context('userenv', 'nls_date_format') as "NLS_DATE_FORMAT"),
          obj
        ) into obj
      from dual;
      return obj;
end;


--
-- DIVISION
--

function get_hrm_division_xml(Id IN hrm_division.hrm_division_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(HRM_DIVISION,
      XMLAttributes(
        sys_context('userenv', 'current_schema') as "CURRENT_SCHEMA",
        sys_context('userenv', 'current_user') as "CURRENT_USER",
        sys_context('userenv', 'terminal') as "TERMINAL",
        sys_context('userenv', 'nls_date_format') as "NLS_DATE_FORMAT"),
      ltm_xml_utils.genXML(CURSOR(
        select * from hrm_division
        where hrm_division_id = T.hrm_division_id),
        ''),
      ltm_track_pc_functions.get_com_vfields_record(hrm_division_id, 'hrm_division'),
      ltm_track_pc_functions.get_com_vfields_value(hrm_division_id, 'hrm_division')
    ) into obj
  from hrm_division T
  where hrm_division_id = Id;
  return obj;

  exception
    when OTHERS then
      obj := COM_XmlErrorDetail(sqlerrm);
      select
        XMLElement(HRM_DIVISION,
          XMLAttributes(
            Id as ID,
            sys_context('userenv', 'current_schema') as "CURRENT_SCHEMA",
            sys_context('userenv', 'current_user') as "CURRENT_USER",
            sys_context('userenv', 'terminal') as "TERMINAL",
            sys_context('userenv', 'nls_date_format') as "NLS_DATE_FORMAT"),
          obj
        ) into obj
      from dual;
      return obj;
end;

--
-- PAYROLL
--

function get_hrm_elements_root_xml(Id IN hrm_elements_root.hrm_elements_root_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(HRM_ELEMENTS_ROOT,
      XMLAttributes(
        sys_context('userenv', 'current_schema') as "CURRENT_SCHEMA",
        sys_context('userenv', 'current_user') as "CURRENT_USER",
        sys_context('userenv', 'terminal') as "TERMINAL",
        sys_context('userenv', 'nls_date_format') as "NLS_DATE_FORMAT"),
      ltm_xml_utils.genXML(CURSOR(
        select * from hrm_elements_root
        where hrm_elements_root_id = T.hrm_elements_root_id),
        ''),
      ltm_track_pc_functions.get_com_vfields_record(hrm_elements_root_id, 'HRM_ELEMENTS_ROOT'),
      ltm_track_pc_functions.get_com_vfields_value(hrm_elements_root_id, 'HRM_ELEMENTS_ROOT'),
      ltm_track_hrm_functions.get_hrm_elements_root_descr(hrm_elements_root_id),
      ltm_track_hrm_functions.get_hrm_elements_family(hrm_elements_root_id),
      ltm_track_hrm_functions.get_hrm_elements_root_display(hrm_elements_root_id),
      case c_root_variant
        when 'Base' then ltm_track_hrm_functions.get_hrm_formulas_structure(hrm_elements_root_id)
      end
    ) into obj
  from hrm_elements_root T
  where hrm_elements_root_id = Id;
  return obj;

  exception
    when OTHERS then
      obj := COM_XmlErrorDetail(sqlerrm);
      select
        XMLElement(HRM_ELEMENTS_ROOT,
          XMLAttributes(
            Id as ID,
            sys_context('userenv', 'current_schema') as "CURRENT_SCHEMA",
            sys_context('userenv', 'current_user') as "CURRENT_USER",
            sys_context('userenv', 'terminal') as "TERMINAL",
            sys_context('userenv', 'nls_date_format') as "NLS_DATE_FORMAT"),
          obj
        ) into obj
      from dual;
      return obj;
end;

function get_hrm_elements_root_descr(Id IN hrm_elements_root.hrm_elements_root_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(
      ltm_xml_utils.genXML(CURSOR(
        select * from hrm_elements_root_descr
        where hrm_elements_root_id = T.hrm_elements_root_id
          and pc_lang_id = T.pc_lang_id),
        'HRM_ELEMENTS_ROOT_DESCR')
      order by hrm_elements_root_id, pc_lang_id
    ) into obj
  from hrm_elements_root_descr T
  where hrm_elements_root_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_hrm_elements_root_display(Id IN hrm_elements_root.hrm_elements_root_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(
      ltm_xml_utils.genXML(CURSOR(
        select * from hrm_elements_root_display
        where hrm_elements_root_id = T.hrm_elements_root_id
          and c_column_type = T.c_column_type),
        'HRM_ELEMENTS_ROOT_DISPLAY')
      order by a_datecre
    ) into obj
  from hrm_elements_root_display T
  where hrm_elements_root_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_hrm_elements_family(Id IN hrm_elements_root.hrm_elements_root_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(
      ltm_xml_utils.genXML(CURSOR(
        select * from hrm_elements_family
        where hrm_elements_root_id = T.hrm_elements_root_id
          and hrm_elements_prefixes_id = T.hrm_elements_prefixes_id
          and hrm_elements_suffixes_id = T.hrm_elements_suffixes_id),
        'HRM_ELEMENTS_FAMILY')
      order by hrm_elements_prefixes_id, hrm_elements_suffixes_id, hrm_elements_id
    ) into obj
  from hrm_elements_family T
  where hrm_elements_root_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_hrm_formulas_structure(Id IN hrm_elements_root.hrm_elements_root_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select elr_root_code||' '||elr_root_name erd_descr
      from hrm_elements_root r, hrm_elements_family fr,
           hrm_formulas_structure fs, hrm_elements_family fm
      where (r.c_root_type = 'Input' or r.c_root_variant IN ('Base','Formula')) and
        r.hrm_elements_root_id = fr.hrm_elements_root_id and
        fr.elf_is_reference = 1 and
        fr.hrm_elements_id = fs.related_id and
        fs.related_id <> fs.main_id and
        fs.relation_type = 0 and
        fs.main_id = fm.hrm_elements_id and
        fm.elf_is_reference = 1 and
        fm.hrm_elements_root_id = Id
      order by elr_root_code),
      'HRM_FORMULAS_STRUCTURE')
    into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

END LTM_TRACK_HRM_FUNCTIONS;
