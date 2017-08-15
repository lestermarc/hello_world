--------------------------------------------------------
--  DDL for Package Body LTM_TRACK_IND_FUNCTIONS_LINK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "LTM_TRACK_IND_FUNCTIONS_LINK" 
/**
 * Package LTM_TRACK_IND_FUNCTIONS_LINK
 * @version 1.0
 * @date 10/2006
 * @author rforchelet
 * @author ecassis
 * @author spfister
 * @since Oracle 9.2
 *
 * Copyright 1997-2008 Pro-Concept SA. Tous droits réservés.
 *
 * Package contenant les fonctions de génération de document Xml pour des
 * liaisons sur des clés étrangères.
 * Spécialisation: Industrie (FAL, PPS)
 */
AS

function get_fal_schedule_plan_link(Id IN fal_schedule_plan.fal_schedule_plan_id%TYPE,
  FieldRef IN VARCHAR2 default 'FAL_SCHEDULE_PLAN')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select fal_schedule_plan_id, sch_ref
      from fal_schedule_plan
      where fal_schedule_plan_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_fal_fact_floor_link(Id IN fal_factory_floor.fal_factory_floor_id%TYPE,
  FieldRef IN VARCHAR2 default 'FAL_FACTORY_FLOOR')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select fal_factory_floor_id, fac_reference
      from fal_factory_floor
      where fal_factory_floor_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pps_nomenclature_link(Id IN pps_nomenclature.pps_nomenclature_id%TYPE,
  FieldRef IN VARCHAR2 default 'PPS_NOMENCLATURE')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(PPS_NOMENCLATURE,
      ltm_xml_utils.genXML(CURSOR(
        select pps_nomenclature_id, c_type_nom, nom_version, gco_good_id
        from pps_nomenclature
        where pps_nomenclature_id = T.pps_nomenclature_id),
        ''),
      ltm_track_log_functions_link.get_gco_good_link(gco_good_id)
    ) into obj
  from pps_nomenclature T
  where pps_nomenclature_id = Id;

  if (obj is not null and FieldRef != 'PPS_NOMENCLATURE') then
    return ltm_xml_utils.transform_root_ref('PPS_NOMENCLATURE', FieldRef, obj);
  end if;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pps_range_link(Id IN pps_range.pps_range_id%TYPE,
  FieldRef IN VARCHAR2 default 'PPS_RANGE')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select pps_range_id, ran_reference
      from pps_range
      where pps_range_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

  /**
  * Description
  *   retourne l'opération du lot de fabrication
  */
  function get_fal_task_link_link(
    Id       in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  , FieldRef in varchar2 default 'FAL_TASK_LINK'
  )
    return xmltype
  is
    obj xmltype;
  begin
    if (Id is null) then
      return null;
    end if;

    select LTM_XML_UTILS.genXML(cursor(select FAL_SCHEDULE_STEP_ID
                                            , SCS_STEP_NUMBER
                                            , C_OPERATION_TYPE
                                            , C_TASK_TYPE
                                            , SCS_SHORT_DESCR
                                         from FAL_TASK_LINK
                                        where FAL_SCHEDULE_STEP_ID = Id
                                      )
                              , FieldRef
                               )
      into obj
      from dual;

    return obj;
  exception
    when others then
      return null;
  end get_fal_task_link_link;

  /**
  * Description
  *   retourne l'atelier
  */
  function get_fal_factory_floor_link(
    Id       in FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type
  , FieldRef in varchar2 default 'FAL_FACTORY_FLOOR'
  )
    return xmltype
  is
    obj xmltype;
  begin
    if (Id is null) then
      return null;
    end if;

    select LTM_XML_UTILS.genXML(cursor(select FAL_FACTORY_FLOOR_ID
                                            , FAC_REFERENCE
                                         from FAL_FACTORY_FLOOR
                                        where FAL_FACTORY_FLOOR_ID = Id), FieldRef)
      into obj
      from dual;

    return obj;
  exception
    when others then
      return null;
  end get_fal_factory_floor_link;

  /**
  * Description
  *   retourne l'opération standard
  */
  function get_fal_task_link(Id in FAL_TASK.FAL_TASK_ID%type, FieldRef in varchar2 default 'FAL_TASK')
    return xmltype
  is
    obj xmltype;
  begin
    if (Id is null) then
      return null;
    end if;

    select LTM_XML_UTILS.genXML(cursor(select FAL_TASK_ID
                                            , TAS_REF
                                         from FAL_TASK
                                        where FAL_TASK_ID = Id), FieldRef)
      into obj
      from dual;

    return obj;
  exception
    when others then
      return null;
  end get_fal_task_link;

  /**
  * Description
  *   retourne la procédure opératoire
  */
  function get_pps_op_proc_link(
    Id       in PPS_OPERATION_PROCEDURE.PPS_OPERATION_PROCEDURE_ID%type
  , FieldRef in varchar2 default 'PPS_OPERATION_PROCEDURE'
  )
    return xmltype
  is
    obj xmltype;
  begin
    if (Id is null) then
      return null;
    end if;

    select LTM_XML_UTILS.genXML(cursor(select PPS_OPERATION_PROCEDURE_ID
                                            , OPP_REFERENCE
                                            , OPP_DESCRIBE
                                            , DIC_OP_PROC_DOMAIN_ID
                                         from PPS_OPERATION_PROCEDURE
                                        where PPS_OPERATION_PROCEDURE_ID = Id
                                      )
                              , FieldRef
                               )
      into obj
      from dual;

    return obj;
  exception
    when others then
      return null;
  end get_pps_op_proc_link;

  /**
  * Description
  *   retourne l'outil
  */
  function get_pps_tools_link(Id in PPS_TOOLS.GCO_GOOD_ID%type, FieldRef in varchar2 default 'PPS_TOOLS')
    return xmltype
  is
    obj xmltype;
  begin
    if (Id is null) then
      return null;
    end if;

    select LTM_XML_UTILS.genXML(cursor(select TLS.GCO_GOOD_ID
                                            , (select GOO.GOO_MAJOR_REFERENCE
                                                 from GCO_GOOD GOO
                                                where GOO.GCO_GOOD_ID = TLS.GCO_GOOD_ID) GOO_MAJOR_REFERENCE
                                         from PPS_TOOLS TLS
                                        where TLS.GCO_GOOD_ID = Id
                                      )
                              , FieldRef
                               )
      into obj
      from dual;

    return obj;
  exception
    when others then
      return null;
  end get_pps_tools_link;

END LTM_TRACK_IND_FUNCTIONS_LINK;
