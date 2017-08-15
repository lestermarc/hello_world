--------------------------------------------------------
--  DDL for Package Body REP_IND_FUNCTIONS_LINK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_IND_FUNCTIONS_LINK" 
/**
 * Fonctions de génération de liaison pour document Xml.
 * Spécialisation: Industrie et fabrication (PPS et FAL)
 *
 * @version 1.0
 * @date 02/2003
 * @author jsomers
 * @author spfister
 * @author ngomes
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
as
--
-- FAL  functions
--
  function get_fal_schedule_plan_link(id in fal_schedule_plan.fal_schedule_plan_id%type)
    return xmltype
  is
    lx_data xmltype;
  begin
    if (id in(null, 0) ) then
      return null;
    end if;

    select XMLElement(FAL_SCHEDULE_PLAN, XMLForest('LINK' as TABLE_TYPE, 'SCH_REF' as TABLE_KEY, fal_schedule_plan_id, sch_ref) )
      into lx_data
      from fal_schedule_plan
     where fal_schedule_plan_id = id;

    return lx_data;
  exception
    when no_data_found then
      return null;
  end;

  /**
  * Description
  *    Fonction de recherche du lien d'une opération de gammes opératoire.
  */
  function get_fal_list_step_link_link(
    id             in FAL_LIST_STEP_LINK.FAL_SCHEDULE_STEP_ID%type
  , FieldRef       in varchar2 default 'FAL_LIST_STEP_LINK'
  , ForceReference in integer default 0
  )
    return xmltype
  is
    lxData xmltype;
  begin
    if (nvl(id, 0) = 0 ) then
      return null;
    end if;

    select XMLElement(evalname(upper(FieldRef) )
                    , case ForceReference
                        when 1 then XMLElement(TABLE_REFERENCE, 'FAL_LIST_STEP_LINK')
                      end
                    , XMLElement(TABLE_TYPE, 'LINK')
                    , XMLElement(TABLE_KEY, 'FAL_SCHEDULE_PLAN_ID,SCS_STEP_NUMBER')
                    , XMLElement(FAL_SCHEDULE_STEP_ID, FAL_SCHEDULE_STEP_ID)
                    , XMLElement(SCS_STEP_NUMBER, SCS_STEP_NUMBER)
                    , REP_IND_FUNCTIONS_LINK.get_fal_schedule_plan_link(FAL_SCHEDULE_PLAN_ID)
                     )
      into lxData
      from FAL_LIST_STEP_LINK
     where FAL_SCHEDULE_STEP_ID = id;

    return lxData;
  exception
    when no_data_found then
      return null;
  end get_fal_list_step_link_link;

  function get_fal_supply_request_link(
    id             in fal_supply_request.fal_supply_request_id%type
  , FieldRef       in varchar2 default 'FAL_SUPPLY_REQUEST'
  , ForceReference in integer default 0
  , IsMandatory    in integer default 0
  )
    return xmltype
  is
    lx_data xmltype;
  begin
    if (id in(null, 0) ) then
      return null;
    end if;

    select XMLElement(FAL_SUPPLY_REQUEST
                    , XMLForest('LINK' || case
                                  when(IsMandatory != 0) then '_MANDATORY'
                                end as TABLE_TYPE
                              , 'FSR_NUMBER' as TABLE_KEY
                              , fal_supply_request_id
                              , fsr_number
                               )
                     )
      into lx_data
      from fal_supply_request
     where fal_supply_request_id = id;

    if (lx_data is not null) then
      if (FieldRef != 'FAL_SUPPLY_REQUEST') then
        if (ForceReference = 0) then
          return rep_xml_function.transform_root_ref('FAL_SUPPLY_REQUEST', FieldRef, lx_data);
        else
          return rep_xml_function.transform_root_ref_table('FAL_SUPPLY_REQUEST', FieldRef, lx_data);
        end if;
      end if;

      return lx_data;
    end if;

    return null;
  exception
    when no_data_found then
      return null;
  end;

  function get_fal_factory_floor_link(
    id             in fal_factory_floor.fal_factory_floor_id%type
  , FieldRef       in varchar2 default 'FAL_FACTORY_FLOOR'
  , ForceReference in integer default 0
  , IsMandatory    in integer default 0
  )
    return xmltype
  is
    lx_data xmltype;
  begin
    if (id in(null, 0) ) then
      return null;
    end if;

    select XMLElement(FAL_FACTORY_FLOOR
                    , XMLForest('LINK' || case
                                  when(IsMandatory != 0) then '_MANDATORY'
                                end as TABLE_TYPE
                              , 'FAC_REFERENCE' as TABLE_KEY
                              , fal_factory_floor_id
                              , fac_reference
                               )
                     )
      into lx_data
      from fal_factory_floor
     where fal_factory_floor_id = id;

    if (lx_data is not null) then
      if (FieldRef != 'FAL_FACTORY_FLOOR') then
        if (ForceReference = 0) then
          return rep_xml_function.transform_root_ref('FAL_FACTORY_FLOOR', FieldRef, lx_data);
        else
          return rep_xml_function.transform_root_ref_table('FAL_FACTORY_FLOOR', FieldRef, lx_data);
        end if;
      end if;

      return lx_data;
    end if;

    return null;
  exception
    when no_data_found then
      return null;
  end;

  function get_fal_network_link_link(
    id             in fal_network_link.fal_network_link_id%type
  , FieldRef       in varchar2 default 'FAL_NETWORK_LINK'
  , ForceReference in integer default 0
  , IsMandatory    in integer default 0
  )
    return xmltype
  is
    lx_data xmltype;
  begin
    if (id in(null, 0) ) then
      return null;
    end if;

    select XMLElement(FAL_NETWORK_LINK
                    , XMLForest('LINK' || case
                                  when(IsMandatory != 0) then '_MANDATORY'
                                end as TABLE_TYPE, 'FAL_NETWORK_LINK_ID' as TABLE_KEY, fal_network_link_id)
                     )
      into lx_data
      from fal_network_link
     where fal_network_link_id = id;

    if (lx_data is not null) then
      if (FieldRef != 'FAL_NETWORK_LINK') then
        if (ForceReference = 0) then
          return rep_xml_function.transform_root_ref('FAL_NETWORK_LINK', FieldRef, lx_data);
        else
          return rep_xml_function.transform_root_ref_table('FAL_NETWORK_LINK', FieldRef, lx_data);
        end if;
      end if;

      return lx_data;
    end if;

    return null;
  exception
    when no_data_found then
      return null;
  end;

  function get_fal_task_link_link(
    id             in fal_task_link.fal_schedule_step_id%type
  , FieldRef       in varchar2 default 'FAL_TASK_LINK'
  , ForceReference in integer default 0
  , IsMandatory    in integer default 0
  )
    return xmltype
  is
    lx_data xmltype;
  begin
    if (id in(null, 0) ) then
      return null;
    end if;

    select XMLElement(FAL_TASK_LINK
                    , XMLForest('LINK' || case
                                  when(IsMandatory != 0) then '_MANDATORY'
                                end as TABLE_TYPE, 'FAL_SCHEDULE_STEP_ID' as TABLE_KEY, fal_schedule_step_id)
                     )
      into lx_data
      from fal_task_link
     where fal_schedule_step_id = id;

    if (lx_data is not null) then
      if (FieldRef != 'FAL_TASK_LINK') then
        if (ForceReference = 0) then
          return rep_xml_function.transform_root_ref('FAL_TASK_LINK', FieldRef, lx_data);
        else
          return rep_xml_function.transform_root_ref_table('FAL_TASK_LINK', FieldRef, lx_data);
        end if;
      end if;

      return lx_data;
    end if;

    return null;
  exception
    when no_data_found then
      return null;
  end;

  function get_fal_task_link(
    id             in fal_task.fal_task_id%type
  , FieldRef       in varchar2 default 'FAL_TASK'
  , ForceReference in integer default 0
  , IsMandatory    in integer default 0
  )
    return xmltype
  is
    lx_data xmltype;
  begin
    if (id in(null, 0) ) then
      return null;
    end if;

    select XMLElement(FAL_TASK, XMLForest('LINK' || case
                                            when(IsMandatory != 0) then '_MANDATORY'
                                          end as TABLE_TYPE, 'TAS_REF' as TABLE_KEY, fal_task_id, tas_ref) )
      into lx_data
      from fal_task
     where fal_task_id = id;

    if (lx_data is not null) then
      if (FieldRef != 'FAL_TASK') then
        if (ForceReference = 0) then
          return rep_xml_function.transform_root_ref('FAL_TASK', FieldRef, lx_data);
        else
          return rep_xml_function.transform_root_ref_table('FAL_TASK', FieldRef, lx_data);
        end if;
      end if;

      return lx_data;
    end if;

    return null;
  exception
    when no_data_found then
      return null;
  end;

--
-- PPS  functions
--
  function get_pps_range_link(id in pps_range.pps_range_id%type)
    return xmltype
  is
    lx_data xmltype;
  begin
    if (id in(null, 0) ) then
      return null;
    end if;

    select XMLElement(PPS_RANGE, XMLForest('LINK' as TABLE_TYPE, 'RAN_REFERENCE' as TABLE_KEY, pps_range_id, ran_reference) )
      into lx_data
      from pps_range
     where pps_range_id = id;

    return lx_data;
  exception
    when no_data_found then
      return null;
  end;

  function get_pps_nomenclature_link(
    id             in pps_nomenclature.pps_nomenclature_id%type
  , FieldRef       in varchar2 default 'PPS_NOMENCLATURE'
  , ForceReference in integer default 0
  )
    return xmltype
  is
    lx_data xmltype;
  begin
    if (id in(null, 0) ) then
      return null;
    end if;

    select XMLElement(PPS_NOMENCLATURE
                    , XMLForest('LINK' as TABLE_TYPE, 'C_TYPE_NOM,GCO_GOOD_ID,NOM_VERSION' as TABLE_KEY, pps_nomenclature_id)
                    , rep_log_functions_link.get_gco_good_link(gco_good_id)
                    , rep_pc_functions.get_descodes('C_TYPE_NOM', c_type_nom)
                    , XMLForest(nom_version)
                     )
      into lx_data
      from pps_nomenclature
     where pps_nomenclature_id = id;

    if (lx_data is not null) then
      if (FieldRef != 'PPS_NOMENCLATURE') then
        if (ForceReference = 0) then
          return rep_xml_function.transform_root_ref('PPS_NOMENCLATURE', FieldRef, lx_data);
        else
          return rep_xml_function.transform_root_ref_table('PPS_NOMENCLATURE', FieldRef, lx_data);
        end if;
      end if;

      return lx_data;
    end if;

    return null;
  exception
    when no_data_found then
      return null;
  end;

  /**
  * Description
  *    Fonction de recherche du lien d'un composant de nomenclature
  */
  function get_pps_nom_bond_link(
    id             in PPS_NOM_BOND.PPS_NOM_BOND_ID%type
  , FieldRef       in varchar2 default 'PPS_NOM_BOND'
  , ForceReference in integer default 0
  )
    return xmltype
  is
    lxData xmltype;
  begin
    if (nvl(id, 0) = 0 ) then
      return null;
    end if;

    select XMLElement(evalname(upper(FieldRef) )
                    , case ForceReference
                        when 1 then XMLElement(TABLE_REFERENCE, 'PPS_NOM_BOND')
                      end
                    , XMLElement(TABLE_TYPE, 'LINK')
                    , XMLElement(TABLE_KEY, 'PPS_NOMENCLATURE_ID,COM_SEQ,C_TYPE_COM,C_DISCHARGE_COM,C_KIND_COM,GCO_GOOD_ID,PPS_PPS_NOMENCLATURE_ID')
                    , XMLElement(COM_SEQ, COM_SEQ)
                    , XMLElement(C_TYPE_COM, C_TYPE_COM)
                    , XMLElement(C_DISCHARGE_COM, C_DISCHARGE_COM)
                    , XMLElement(C_KIND_COM, C_KIND_COM)
                    , REP_LOG_FUNCTIONS_LINK.get_gco_good_link(GCO_GOOD_ID)
                    , REP_IND_FUNCTIONS_LINK.get_pps_nomenclature_link(PPS_PPS_NOMENCLATURE_ID, 'PPS_PPS_NOMENCLATURE_ID',1)
                     )
      into lxData
      from PPS_NOM_BOND
     where PPS_NOM_BOND_ID = id;

    return lxData;
  exception
    when no_data_found then
      return null;
  end get_pps_nom_bond_link;

  function get_pps_operation_proc_link(
    id             in pps_operation_procedure.pps_operation_procedure_id%type
  , FieldRef       in varchar2 default 'PPS_OPERATION_PROCEDURE'
  , ForceReference in integer default 0
  , IsMandatory    in integer default 0
  )
    return xmltype
  is
    lx_data xmltype;
  begin
    if (id in(null, 0) ) then
      return null;
    end if;

    select XMLElement(PPS_OPERATION_PROCEDURE
                    , XMLForest('LINK' || case
                                  when(IsMandatory != 0) then '_MANDATORY'
                                end as TABLE_TYPE
                              , 'PPS_OPERATION_PROCEDURE_ID' as TABLE_KEY
                              , pps_operation_procedure_id
                               )
                     )
      into lx_data
      from pps_operation_procedure
     where pps_operation_procedure_id = id;

    if (lx_data is not null) then
      if (FieldRef != 'PPS_OPERATION_PROCEDURE') then
        if (ForceReference = 0) then
          return rep_xml_function.transform_root_ref('PPS_OPERATION_PROCEDURE', FieldRef, lx_data);
        else
          return rep_xml_function.transform_root_ref_table('PPS_OPERATION_PROCEDURE', FieldRef, lx_data);
        end if;
      end if;

      return lx_data;
    end if;

    return null;
  exception
    when no_data_found then
      return null;
  end;

  function get_pps_tools_link(id in pps_tools.gco_good_id%type, FieldRef in varchar2 default 'PPS_TOOLS')
    return xmltype
  is
    lx_data xmltype;
  begin
    if (id in(null, 0) ) then
      return null;
    end if;

    select XMLElement(PPS_TOOLS
                    , XMLForest('LINK' as TABLE_TYPE, 'GCO_GOOD_ID' as TABLE_KEY, 'GCO_GOOD_ID=GCO_GOOD_ID' as TABLE_MAPPING, 'GCO_GOOD' as TABLE_REFERENCE)
                    , rep_log_functions_link.get_gco_good_link(gco_good_id)
                     )
      into lx_data
      from pps_tools
     where gco_good_id = id;

    if (lx_data is not null) then
      if (FieldRef != 'PPS_TOOLS') then
        return rep_xml_function.transform_root_ref('PPS_TOOLS', FieldRef, lx_data);
      end if;

      return lx_data;
    end if;

    return null;
  exception
    when no_data_found then
      return null;
  end;
end REP_IND_FUNCTIONS_LINK;
