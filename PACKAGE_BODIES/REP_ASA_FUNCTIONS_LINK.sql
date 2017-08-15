--------------------------------------------------------
--  DDL for Package Body REP_ASA_FUNCTIONS_LINK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_ASA_FUNCTIONS_LINK" 
/**
 * Fonctions de génération de liaison pour document Xml.
 * Spécialisation: Réparations (ASA)
 *
 * @version 1.0
 * @date 02/2003
 * @author jsomers
 * @author spfister
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
AS

function get_asa_rep_type_link(
  Id IN asa_rep_type.asa_rep_type_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ASA_REP_TYPE,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'RET_REP_TYPE' as TABLE_KEY,
        asa_rep_type_id,
        ret_rep_type)
    ) into lx_data
  from asa_rep_type
  where asa_rep_type_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_asa_record_link(
  Id IN ASA_RECORD.ASA_RECORD_ID%TYPE,
  FieldRef IN VARCHAR2 default 'ASA_RECORD',
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
    XMLElement(ASA_RECORD,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'ARE_NUMBER' as TABLE_KEY,
        asa_record_id,
        are_number)
    ) into lx_data
  from asa_record
  where asa_record_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'ASA_RECORD') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('ASA_RECORD', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('ASA_RECORD', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_asa_record_events_link(
  Id IN ASA_RECORD_EVENTS.ASA_RECORD_EVENTS_ID%TYPE,
  FieldRef IN VARCHAR2 default 'ASA_RECORD_EVENTS',
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
    XMLElement(ASA_RECORD_EVENTS,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'ASA_RECORD_ID,RRE_SEQ' as TABLE_KEY,
        asa_record_events_id),
      rep_asa_functions_link.get_asa_record_link(asa_record_id),
      XMLForest(
        rre_seq)
    ) into lx_data
  from asa_record_events
  where asa_record_events_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'ASA_RECORD_EVENTS') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('ASA_RECORD_EVENTS', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('ASA_RECORD_EVENTS', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_asa_record_comp_link(
  Id IN ASA_RECORD_COMP.ASA_RECORD_COMP_ID%TYPE,
  FieldRef IN VARCHAR2 default 'ASA_RECORD_COMP',
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
    XMLElement(ASA_RECORD_COMP,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'ASA_RECORD_ID,ASA_RECORD_EVENTS_ID,ARC_POSITION' as TABLE_KEY,
        asa_record_comp_id),
      rep_asa_functions_link.get_asa_record_link(asa_record_id),
      rep_asa_functions_link.get_asa_record_events_link(asa_record_events_id),
      XMLForest(
        arc_position)
    ) into lx_data
  from asa_record_comp
  where asa_record_comp_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'ASA_RECORD_COMP') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('ASA_RECORD_COMP', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('ASA_RECORD_COMP', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_asa_record_task_link(
  Id IN ASA_RECORD_TASK.ASA_RECORD_TASK_ID%TYPE,
  FieldRef IN VARCHAR2 default 'ASA_RECORD_TASK',
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
    XMLElement(ASA_RECORD_TASK,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'ASA_RECORD_ID,ASA_RECORD_EVENTS_ID,RET_POSITION' as TABLE_KEY,
        asa_record_task_id),
      rep_asa_functions_link.get_asa_record_link(asa_record_id),
      rep_asa_functions_link.get_asa_record_events_link(asa_record_events_id),
      XMLForest(
        ret_position)
    ) into lx_data
  from asa_record_task
  where asa_record_task_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'ASA_RECORD_TASK') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('ASA_RECORD_TASK', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('ASA_RECORD_TASK', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

END REP_ASA_FUNCTIONS_LINK;
