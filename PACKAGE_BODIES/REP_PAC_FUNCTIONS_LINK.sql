--------------------------------------------------------
--  DDL for Package Body REP_PAC_FUNCTIONS_LINK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_PAC_FUNCTIONS_LINK" 
/**
 * Fonctions de génération de liaison pour document Xml.
 * Spécialisation: Client, fournisseur, partenaire, etc. (PAC)
 *
 * @version 1.0
 * @date 04/2004
 * @author jsomers
 * @author spfister
 * @author fperotto
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
AS

function get_pac_address_link(
  Id IN pac_address.pac_address_id%TYPE,
  FieldRef IN VARCHAR2 default 'PAC_ADDRESS',
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
    XMLElement(PAC_ADDRESS,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'PAC_PERSON_ID, DIC_ADDRESS_TYPE_ID' as TABLE_KEY,
        pac_address_id),
      rep_pac_functions_link.get_pac_person_link(pac_person_id),
      rep_pc_functions.get_dictionary('DIC_ADDRESS_TYPE',dic_address_type_id)
    ) into lx_data
  from pac_address
  where pac_address_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'PAC_ADDRESS') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('PAC_ADDRESS', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('PAC_ADDRESS', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pac_person_inherit_link(Id IN pac_person.pac_person_id%TYPE,
  FieldRef IN VARCHAR2,
  IsMandatory IN INTEGER default 0)
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
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'PER_KEY1,PER_KEY2' as TABLE_KEY,
        'PAC_PERSON_ID='||FieldRef||'_ID' as TABLE_MAPPING,
        'PAC_PERSON' as TABLE_REFERENCE,
        pac_person_id as INHERIT_ID,
        per_key1,
        per_key2)
    ) into lx_data
  from pac_person
  where pac_person_id = Id;

  if (lx_data is not null) then
    return rep_xml_function.transform_field_ref('INHERIT', FieldRef, lx_data);
  end if;
  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pac_person_link(
  Id IN pac_person.pac_person_id%TYPE,
  FieldRef IN VARCHAR2 default 'PAC_PERSON',
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
    XMLElement(PAC_PERSON,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'PER_KEY1,PER_KEY2' as TABLE_KEY,
        pac_person_id,
        per_key1,
        per_key2)
    ) into lx_data
  from pac_person
  where pac_person_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'PAC_PERSON') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('PAC_PERSON', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('PAC_PERSON', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pac_representative_link(
  Id IN pac_representative.pac_representative_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(PAC_REPRESENTATIVE,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'REP_DESCR' as TABLE_KEY,
        pac_representative_id,
        rep_descr)
    ) into lx_data
  from pac_representative
  where pac_representative_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pac_sending_condition_link(
  Id IN pac_sending_condition.pac_sending_condition_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(PAC_SENDING_CONDITION,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'SEN_KEY' as TABLE_KEY,
        pac_sending_condition_id,
        sen_key)
    ) into lx_data
  from pac_sending_condition
  where pac_sending_condition_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pac_payment_condition_link(
  Id IN pac_payment_condition.pac_payment_condition_id%TYPE,
  FieldRef IN VARCHAR2 default 'PAC_PAYMENT_CONDITION',
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
    XMLElement(PAC_PAYMENT_CONDITION,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'PCO_DESCR' as TABLE_KEY,
        pac_payment_condition_id,
        pco_descr)
    ) into lx_data
  from pac_payment_condition
  where pac_payment_condition_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'PAC_PAYMENT_CONDITION') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('PAC_PAYMENT_CONDITION', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('PAC_PAYMENT_CONDITION', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pac_remainder_categ_link(
  Id IN pac_remainder_category.pac_remainder_category_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(PAC_REMAINDER_CATEGORY,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'RCA_DESCR' as TABLE_KEY,
        pac_remainder_category_id,
        rca_descr)
    ) into lx_data
  from pac_remainder_category
  where pac_remainder_category_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;


function get_pac_fin_ref_link(
  Id IN pac_financial_reference.pac_financial_reference_id%TYPE,
  IsMandatory IN INTEGER default 0)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(PAC_FINANCIAL_REFERENCE,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'PAC_CUSTOM_PARTNER_ID,PAC_SUPPLIER_PARTNER_ID,C_TYPE_REFERENCE,'||
          'FRE_ACCOUNT_NUMBER,FRE_ACCOUNT_CONTROL' as TABLE_KEY,
        pac_financial_reference_id),
      rep_pac_functions_link.get_pac_custom_partner_link(pac_custom_partner_id),
      rep_pac_functions_link.get_pac_supplier_partner_link(pac_supplier_partner_id),
      rep_pc_functions.get_descodes('C_TYPE_REFERENCE', c_type_reference),
      XMLForest(
        fre_account_number,
        fre_account_control)
    ) into lx_data
  from pac_financial_reference
  where pac_financial_reference_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;


function get_pac_schedule_link(
  Id IN pac_schedule.pac_schedule_id%TYPE,
  IsMandatory IN INTEGER default 0)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(PAC_SCHEDULE,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'SCE_DESCR' as TABLE_KEY,
        pac_schedule_id,
        sce_descr)
    ) into lx_data
  from pac_schedule
  where pac_schedule_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pac_distrib_channel_link(
  Id IN pac_distribution_channel.pac_distribution_channel_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(PAC_DISTRIBUTION_CHANNEL,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'PDC_KEY' as TABLE_KEY,
        pac_distribution_channel_id,
        pdc_key)
    ) into lx_data
  from pac_distribution_channel
  where pac_distribution_channel_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pac_sale_territory_link(
  Id IN pac_sale_territory.pac_sale_territory_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(PAC_SALE_TERRITORY,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'STE_KEY' as TABLE_KEY,
        pac_sale_territory_id,
        ste_key)
    ) into lx_data
  from pac_sale_territory
  where pac_sale_territory_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;


--
-- Third  functions
--

function get_pac_third_link(
  Id IN pac_person.pac_person_id%TYPE,
  FieldRef IN VARCHAR2 default 'PAC_THIRD')
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(PAC_THIRD,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'PAC_THIRD_ID' as TABLE_KEY),
      rep_pac_functions_link.get_pac_person_inherit_link(pac_third_id,'PAC_THIRD')
    ) into lx_data
  from pac_third
  where pac_third_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'PAC_THIRD') then
      return rep_xml_function.transform_root_ref('PAC_THIRD', FieldRef, lx_data);
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;


--
-- Customer  functions
--

function get_pac_custom_partner_link(
  Id IN pac_custom_partner.pac_custom_partner_id%TYPE,
  FieldRef IN VARCHAR2 default 'PAC_CUSTOM_PARTNER')
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(PAC_CUSTOM_PARTNER,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'PAC_CUSTOM_PARTNER_ID' as TABLE_KEY,
        'PAC_CUSTOM_PARTNER_ID=PAC_PERSON_ID' as TABLE_MAPPING,
        'PAC_PERSON' as TABLE_REFERENCE),
      rep_pac_functions_link.get_pac_person_link(pac_person_id)
    ) into lx_data
  from pac_person
  where pac_person_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'PAC_CUSTOM_PARTNER') then
      return rep_xml_function.transform_root_ref('PAC_CUSTOM_PARTNER',FieldRef,lx_data);
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;


--
-- Supplier  functions
--

function get_pac_supplier_partner_link(
  Id IN pac_supplier_partner.pac_supplier_partner_id%TYPE,
  FieldRef IN VARCHAR2 default 'PAC_SUPPLIER_PARTNER')
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(PAC_SUPPLIER_PARTNER,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'PAC_SUPPLIER_PARTNER_ID' as TABLE_KEY,
        'PAC_SUPPLIER_PARTNER_ID=PAC_PERSON_ID' as TABLE_MAPPING,
        'PAC_PERSON' as TABLE_REFERENCE),
      rep_pac_functions_link.get_pac_person_link(pac_person_id)
    ) into lx_data
  from pac_person
  where pac_person_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'PAC_SUPPLIER_PARTNER') then
      return rep_xml_function.transform_root_ref('PAC_SUPPLIER_PARTNER',FieldRef,lx_data);
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pac_calendar_type_link(
  Id IN pac_calendar_type.pac_calendar_type_id%TYPE,
  FieldRef IN VARCHAR2 default 'PAC_CALENDAR_TYPE')
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(PAC_CALENDAR_TYPE,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'CAL_DESCR' as TABLE_KEY,
        PAC_CALENDAR_TYPE_ID,
        CAL_DESCR)
    ) into lx_data
  from PAC_CALENDAR_TYPE
  where PAC_CALENDAR_TYPE_ID = Id;

  if (lx_data is not null) then
    if (FieldRef != 'PAC_CALENDAR_TYPE') then
      return rep_xml_function.transform_root_ref('PAC_CALENDAR_TYPE', FieldRef, lx_data);
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

END REP_PAC_FUNCTIONS_LINK;
