--------------------------------------------------------
--  DDL for Package Body LTM_TRACK_GAL_FUNCTIONS_LINK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "LTM_TRACK_GAL_FUNCTIONS_LINK" 
/**
 * Package LTM_TRACK_GAL_FUNCTIONS_LINK
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
 * Spécialisation: Gestion à l'affaire (GAL).
 */
AS

function get_gal_project_link(Id IN gal_project.gal_project_id%TYPE,
  FieldRef IN VARCHAR2 default 'GAL_PROJECT')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
   return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select gal_project_id, prj_code
      from gal_project
      where gal_project_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gal_task_link(Id IN gal_task.gal_task_id%TYPE,
  FieldRef IN VARCHAR2 default 'GAL_TASK')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(GAL_TASK,
      ltm_xml_utils.genXML(CURSOR(
        select gal_task_id, gal_project_id, tas_code
        from gal_task
        where gal_task_id = T.gal_task_id),
        ''),
      ltm_track_gal_functions_link.get_gal_project_link(gal_project_id)
    ) into obj
  from gal_task T
  where gal_task_id = Id;

  if (obj is not null and FieldRef != 'GAL_TASK') then
    return ltm_xml_utils.transform_root_ref('GAL_TASK', FieldRef, obj);
  end if;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gal_budget_link(Id IN gal_budget.gal_budget_id%TYPE,
  FieldRef IN VARCHAR2 default 'GAL_BUDGET')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(GAL_BUDGET,
      ltm_xml_utils.genXML(CURSOR(
        select gal_budget_id, gal_project_id, bdg_code
        from gal_budget
        where gal_budget_id = T.gal_budget_id),
        ''),
      ltm_track_gal_functions_link.get_gal_project_link(gal_project_id)
    ) into obj
  from gal_budget T
  where gal_budget_id = Id;

  if (obj is not null and FieldRef != 'GAL_BUDGET') then
    return ltm_xml_utils.transform_root_ref('GAL_BUDGET', FieldRef, obj);
  end if;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gal_task_link_link(Id IN gal_task_link.gal_task_link_id%TYPE,
  FieldRef IN VARCHAR2 default 'GAL_TASK_LINK')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(GAL_TASK_LINK,
      ltm_xml_utils.genXML(CURSOR(
        select gal_task_link_id, scs_step_number, gal_task_id
        from gal_task_link
        where gal_task_link_id = T.gal_task_link_id),
        ''),
      ltm_track_gal_functions_link.get_gal_task_link(gal_task_id)
    ) into obj
  from gal_task_link T
  where gal_task_link_id = Id;

  if (obj is not null and FieldRef != 'GAL_TASK_LINK') then
    return ltm_xml_utils.transform_root_ref('GAL_TASK_LINK', FieldRef, obj);
  end if;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gal_cost_center_link(Id IN gal_cost_center.gal_cost_center_id%TYPE,
  FieldRef IN VARCHAR2 default 'GAL_COST_CENTER')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select gal_cost_center_id, gcc_code
      from gal_cost_center
      where gal_cost_center_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

END LTM_TRACK_GAL_FUNCTIONS_LINK;
