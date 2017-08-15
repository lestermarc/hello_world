--------------------------------------------------------
--  DDL for Package Body LTM_TRACK_PAC_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "LTM_TRACK_PAC_FUNCTIONS" 
/**
 * Package LTM_TRACK_PAC_FUNCTIONS
 * @version 1.0
 * @date 10/2006
 * @author rforchelet
 * @author spfister
 * @since Oracle 9.2
 *
 * Copyright 1997-2008 Pro-Concept SA. Tous droits réservés.
 *
 * Package contenant les fonctions de génération de document Xml pour le
 * suivi do modifications.
 * Spécialisation: Partenaire (PAC)
 */
AS

function get_pac_person_xml(Id IN pac_person.pac_person_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(PAC_PERSON,
      XMLAttributes(
        sys_context('userenv', 'current_schema') as "current_schema",
        sys_context('userenv', 'current_user') as "current_user",
        sys_context('userenv', 'terminal') as "terminal",
        sys_context('userenv', 'nls_date_format') as "nls_date_format"),
      ltm_xml_utils.genXML(CURSOR(
        select * from pac_person
        where pac_person_id = T.pac_person_id),
        ''),
      ltm_track_pac_functions.get_pac_address(pac_person_id),
      ltm_track_pac_functions.get_pac_person_association(pac_person_id),
      ltm_track_pac_functions.get_pac_third(pac_person_id),
      ltm_track_pac_functions.get_pac_communication(pac_person_id),
      ltm_track_pac_functions.get_pac_custom_partner(pac_person_id),
      ltm_track_pac_functions.get_pac_supplier_partner(pac_person_id),
      ltm_track_pac_functions.get_pac_boolean_code(pac_person_id),
      ltm_track_pac_functions.get_pac_department(pac_person_id)
    ) into obj
  from pac_person T
  where pac_person_id = Id;
  return obj;

  exception
    when OTHERS then
      obj := COM_XmlErrorDetail(sqlerrm);
      select
        XMLElement(PAC_PERSON,
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

function get_pac_address(Id IN pac_person.pac_person_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(PAC_ADDRESS,
      ltm_xml_utils.genXML(CURSOR(
        select * from pac_address
        where pac_address_id = T.pac_address_id),
        ''),
      ltm_track_pc_functions_link.get_pc_cntry_link(pc_cntry_id),
      ltm_track_pc_functions_link.get_pc_lang_link(pc_lang_id))
      order by a_datecre
    ) into obj
  from pac_address T
  where pac_person_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pac_person_association(Id IN pac_person.pac_person_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(PAC_PERSON_ASSOCIATION,
      ltm_xml_utils.genXML(CURSOR(
        select * from pac_person_association
        where pac_person_association_id = T.pac_person_association_id),
        ''),
      ltm_track_pac_functions_link.get_pac_person_link(pac_pac_person_id, 'PAC_PAC_PERSON'))
      order by a_datecre
    ) into obj
  from pac_person_association T
  where pac_person_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pac_third(Id IN pac_person.pac_person_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(PAC_THIRD,
      ltm_xml_utils.genXML(CURSOR(
        select * from pac_third
        where pac_third_id = T.pac_third_id),
        ''),
      ltm_track_pac_functions_link.get_pac_person_link(pac_pac_person_id, 'PAC_PAC_PERSON'))
      order by a_datecre
    ) into obj
  from pac_third T
  where pac_third_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pac_communication(Id IN pac_person.pac_person_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(PAC_COMMUNICATION,
      ltm_xml_utils.genXML(CURSOR(
        select * from pac_communication
        where pac_communication_id = T.pac_communication_id),
        ''),
      ltm_track_pac_functions_link.get_pac_address_link(pac_address_id))
      order by a_datecre
    ) into obj
  from pac_communication T
  where pac_person_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pac_custom_partner(Id IN pac_person.pac_person_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(PAC_CUSTOM_PARTNER,
      ltm_xml_utils.genXML(CURSOR(
        select * from pac_custom_partner
        where pac_custom_partner_id = T.pac_custom_partner_id),
        ''),
      ltm_track_pac_functions_link.get_pac_remainder_cat_link(pac_remainder_category_id),
      ltm_track_pac_functions_link.get_pac_payment_condition_link(pac_payment_condition_id),
      ltm_track_fin_functions_link.get_acs_account_link(acs_auxiliary_account_id, 'ACS_AUXILIARY_ACCOUNT'),
      ltm_track_pac_functions_link.get_pac_address_link(pac_address_id),
      ltm_track_fin_functions_link.get_acs_vat_det_account_link(acs_vat_det_account_id),
      ltm_track_pac_functions_link.get_pac_representative_link(pac_representative_id),
      ltm_track_pac_functions_link.get_pac_sending_condition_link(pac_sending_condition_id),
      ltm_track_pac_functions_link.get_pac_calendar_type_link(pac_calendar_type_id),
      ltm_track_fin_functions_link.get_acs_fin_acc_s_payment_link(acs_fin_acc_s_payment_id),
      ltm_track_log_functions_link.get_doc_gauge_link(doc_gauge_id),
      ltm_track_log_functions_link.get_doc_gauge_link(doc_gauge_id, 'DOC_DOC_GAUGE_ID'),
      ltm_track_pac_functions_link.get_pac_third_link(pac_pac_third_1_id, 'PAC_PAC_THIRD_1'),
      ltm_track_pac_functions_link.get_pac_third_link(pac_pac_third_2_id, 'PAC_PAC_THIRD_2'),
      ltm_track_pc_functions_link.get_pc_appltxt_link(pc_appltxt_id),
      ltm_track_pc_functions_link.get_pc_appltxt_link(pc__pc_appltxt_id, 'PC__PC_APPLTXT'),
      ltm_track_pc_functions_link.get_pc_appltxt_link(pc_2_pc_appltxt_id, 'PC_2_PC_APPLTXT'),
      ltm_track_pc_functions_link.get_pc_appltxt_link(pc_3_pc_appltxt_id, 'PC_3_PC_APPLTXT'),
      ltm_track_pc_functions_link.get_pc_appltxt_link(pc_4_pc_appltxt_id, 'PC_4_PC_APPLTXT'),
      ltm_track_log_functions_link.get_stm_stock_link(stm_stock_id),
      ltm_track_pac_functions_link.get_pac_distrib_channel_link(pac_distribution_channel_id),
      ltm_track_pac_functions_link.get_pac_sale_territory_link(pac_sale_territory_id))
      order by a_datecre
    ) into obj
  from pac_custom_partner T
  where pac_custom_partner_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pac_supplier_partner(Id IN pac_person.pac_person_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(PAC_SUPPLIER_PARTNER,
      ltm_xml_utils.genXML(CURSOR(
        select * from pac_supplier_partner
        where pac_supplier_partner_id = T.pac_supplier_partner_id),
        ''),
      ltm_track_pac_functions_link.get_pac_remainder_cat_link(pac_remainder_category_id),
      ltm_track_pac_functions_link.get_pac_payment_condition_link(pac_payment_condition_id),
      ltm_track_fin_functions_link.get_acs_account_link(acs_auxiliary_account_id, 'ACS_AUXILIARY_ACCOUNT'),
      ltm_track_pac_functions_link.get_pac_address_link(pac_address_id),
      ltm_track_fin_functions_link.get_acs_vat_det_account_link(acs_vat_det_account_id),
      ltm_track_pac_functions_link.get_pac_sending_condition_link(pac_sending_condition_id),
      ltm_track_pac_functions_link.get_pac_calendar_type_link(pac_calendar_type_id),
      ltm_track_fin_functions_link.get_acs_fin_acc_s_payment_link(acs_fin_acc_s_payment_id),
      ltm_track_pac_functions_link.get_pac_third_link(pac_pac_third_1_id, 'PAC_PAC_THIRD_1'),
      ltm_track_pac_functions_link.get_pac_third_link(pac_pac_third_2_id, 'PAC_PAC_THIRD_2'),
      ltm_track_pc_functions_link.get_pc_appltxt_link(pc_appltxt_id),
      ltm_track_pc_functions_link.get_pc_appltxt_link(pc__pc_appltxt_id, 'PC__PC_APPLTXT'),
      ltm_track_pc_functions_link.get_pc_appltxt_link(pc_2_pc_appltxt_id, 'PC_2_PC_APPLTXT'),
      ltm_track_pc_functions_link.get_pc_appltxt_link(pc_3_pc_appltxt_id, 'PC_3_PC_APPLTXT'),
      ltm_track_pc_functions_link.get_pc_appltxt_link(pc_4_pc_appltxt_id, 'PC_4_PC_APPLTXT'),
      ltm_track_log_functions_link.get_stm_stock_link(stm_stock_id))
      order by a_datecre
    ) into obj
  from pac_supplier_partner T
  where pac_supplier_partner_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pac_boolean_code(Id IN pac_person.pac_person_id%TYPE)
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
        select * from pac_boolean_code
        where pac_person_id = T.pac_person_id),
        'PAC_BOOLEAN_CODE')
      order by a_datecre
    ) into obj
  from pac_boolean_code T
  where pac_person_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pac_char_code(Id IN pac_person.pac_person_id%TYPE)
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
        select * from pac_char_code
        where pac_person_id = T.pac_person_id),
        'PAC_CHAR_CODE')
      order by a_datecre
    ) into obj
  from pac_char_code T
  where pac_person_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pac_number_code(Id IN pac_person.pac_person_id%TYPE)
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
        select * from pac_number_code
        where pac_person_id = T.pac_person_id),
        'PAC_NUMBER_CODE')
      order by a_datecre
    ) into obj
  from pac_number_code T
  where pac_person_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pac_date_code(Id IN pac_person.pac_person_id%TYPE)
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
        select * from pac_date_code
        where pac_person_id = T.pac_person_id),
        'PAC_DATE_CODE')
      order by a_datecre
    ) into obj
  from pac_date_code T
  where pac_person_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pac_department(Id IN pac_person.pac_person_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(PAC_DEPARTMENT,
      ltm_xml_utils.genXML(CURSOR(
        select * from pac_department
        where pac_department_id = T.pac_department_id),
        ''),
      ltm_track_pac_functions_link.get_pac_address_link(pac_address_id),
      ltm_track_pac_functions_link.get_pac_schedule_link(pac_schedule_id))
      order by a_datecre
    ) into obj
  from pac_department T
  where pac_person_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

END LTM_TRACK_PAC_FUNCTIONS;
