--------------------------------------------------------
--  DDL for Package Body LTM_TRACK_PAC_FUNCTIONS_LINK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "LTM_TRACK_PAC_FUNCTIONS_LINK" 
/**
 * Package LTM_TRACK_IND_FUNCTIONS_LINK
 * @version 1.0
 * @date 10/2006
 * @author rforchelet
 * @author spfister
 * @since Oracle 9.2
 *
 * Copyright 1997-2008 Pro-Concept SA. Tous droits réservés.
 *
 * Package contenant les fonctions de génération de document Xml pour des
 * liaisons sur des clés étrangères.
 * Spécialisation: Partenaire (PAC)
 */
AS

function get_pac_person_link(Id IN pac_person.pac_person_id%TYPE,
  FieldRef IN VARCHAR2 default 'PAC_PERSON')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select pac_person_id, per_key1, per_key2, per_name
      from pac_person
      where pac_person_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pac_supplier_partner_link(Id IN pac_supplier_partner.pac_supplier_partner_id%TYPE,
  FieldRef IN VARCHAR2 default 'PAC_SUPPLIER_PARTNER')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select sp.pac_supplier_partner_id, p.per_key1, p.per_key2, p.per_name
      from pac_person p, pac_supplier_partner sp
      where sp.pac_supplier_partner_id = Id and p.pac_person_id = sp.pac_supplier_partner_id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pac_custom_partner_link(Id IN pac_custom_partner.pac_custom_partner_id%TYPE,
  FieldRef IN VARCHAR2 default 'PAC_CUSTOM_PARTNER')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select cp.pac_custom_partner_id, p.per_key1, p.per_key2, p.per_name
      from pac_person p, pac_custom_partner cp
      where cp.pac_custom_partner_id = Id and p.pac_person_id = cp.pac_custom_partner_id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pac_third_link(Id IN pac_third.pac_third_id%TYPE,
  FieldRef IN VARCHAR2 default 'PAC_THIRD')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select t.pac_third_id, p.per_key1, p.per_key2, p.per_name
      from pac_person p, pac_third t
      where t.pac_third_id = Id and p.pac_person_id = t.pac_third_id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pac_representative_link(Id IN pac_representative.pac_representative_id%TYPE,
  FieldRef IN VARCHAR2 default 'PAC_REPRESENTATIVE')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select pac_representative_id, rep_descr
      from pac_representative
      where pac_representative_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pac_department_link(Id IN pac_department.pac_department_id%TYPE,
  FieldRef IN VARCHAR2 default 'PAC_DEPARTMENT')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select pac_department_id, dep_key
      from pac_department
      where pac_department_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pac_address_link(Id IN pac_address.pac_address_id%TYPE,
  FieldRef IN VARCHAR2 default 'PAC_ADDRESS')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(PAC_ADDRESS,
      ltm_xml_utils.genXML(CURSOR(
        select pac_address_id, pac_person_id, dic_address_type_id,
           add_address1, add_zipcode, add_city, add_state, pc_cntry_id
        from pac_address
        where pac_address_id = T.pac_address_id),
        ''),
      ltm_track_pac_functions_link.get_pac_person_link(pac_person_id),
      ltm_track_pc_functions_link.get_pc_cntry_link(pc_cntry_id)
    ) into obj
  from pac_address T
  where pac_address_id = Id;

  if (obj is not null and FieldRef != 'PAC_ADDRESS') then
    return ltm_xml_utils.transform_root_ref('PAC_ADDRESS', FieldRef, obj);
  end if;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pac_remainder_cat_link(Id IN pac_remainder_category.pac_remainder_category_id%TYPE,
  FieldRef IN VARCHAR2 default 'PAC_REMAINDER_CATEGORY')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select pac_remainder_category_id, rca_default, c_valid, rca_descr
      from pac_remainder_category
      where pac_remainder_category_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pac_payment_condition_link(Id IN pac_payment_condition.pac_payment_condition_id%TYPE,
  FieldRef IN VARCHAR2 default 'PAC_PAYMENT_CONDITION')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select pac_payment_condition_id, pco_default, c_valid, pco_descr
      from pac_payment_condition
      where pac_payment_condition_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pac_sending_condition_link(Id IN pac_sending_condition.pac_sending_condition_id%TYPE,
  FieldRef IN VARCHAR2 default 'PAC_SENDING_CONDITION')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select pac_sending_condition_id, sen_key, c_condition_mode
      from pac_sending_condition
      where pac_sending_condition_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pac_calendar_type_link(Id IN pac_calendar_type.pac_calendar_type_id%TYPE,
  FieldRef IN VARCHAR2 default 'PAC_CALENDAR_TYPE')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select pac_calendar_type_id, cal_descr, cal_default, c_partner_status
      from pac_calendar_type
      where pac_calendar_type_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pac_distrib_channel_link(Id IN pac_distribution_channel.pac_distribution_channel_id%TYPE,
  FieldRef IN VARCHAR2 default 'PAC_DISTRIBUTION_CHANNEL')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select pac_distribution_channel_id, pdc_key
      from pac_distribution_channel
      where pac_distribution_channel_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pac_sale_territory_link(Id IN pac_sale_territory.pac_sale_territory_id%TYPE,
  FieldRef IN VARCHAR2 default 'PAC_SALE_TERRITORY')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select pac_sale_territory_id, ste_key
      from pac_sale_territory
      where pac_sale_territory_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pac_schedule_link(Id IN pac_schedule.pac_schedule_id%TYPE,
  FieldRef IN VARCHAR2 default 'PAC_SCHEDULE')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select pac_schedule_id, sce_descr
      from pac_schedule
      where pac_schedule_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pac_pers_association_link(Id IN pac_person_association.pac_person_association_id%TYPE,
  FieldRef IN VARCHAR2 default 'PAC_PERSON_ASSOCIATION')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(PAC_PERSON_ASSOCIATION,
      ltm_xml_utils.genXML(CURSOR(
        select pac_person_association_id, pac_person_id, pac_pac_person_id, dic_association_type_id
        from pac_person_association
        where pac_person_association_id = T.pac_person_association_id),
        ''),
      ltm_track_pac_functions_link.get_pac_person_link(pac_person_id),
      ltm_track_pac_functions_link.get_pac_person_link(pac_pac_person_id, 'PAC_PAC_PERSON_ID')
    ) into obj
  from pac_person_association T
  where pac_person_association_id = Id;

  if (obj is not null and FieldRef != 'PAC_PERSON_ASSOCIATION') then
    return ltm_xml_utils.transform_root_ref('PAC_PERSON_ASSOCIATION', FieldRef, obj);
  end if;
  return obj;

  exception
    when OTHERS then return null;
end;

END LTM_TRACK_PAC_FUNCTIONS_LINK;
