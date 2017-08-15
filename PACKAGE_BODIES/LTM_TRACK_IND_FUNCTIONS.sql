--------------------------------------------------------
--  DDL for Package Body LTM_TRACK_IND_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "LTM_TRACK_IND_FUNCTIONS" 
/**
 * Package LTM_TRACK_IND_FUNCTIONS
 * @version 1.0
 * @date 01/2008
 * @author ecassis
 * @author spfister
 * @since Oracle 9.2
 *
 * Copyright 1997-2008 Pro-Concept SA. Tous droits réservés.
 *
 * Package contenant les fonctions de génération de document Xml pour le
 * suivi do modifications.
 * Spécialisation: Industrie (FAL, PPS)
 */
AS

function get_fal_fact_floor_xml(Id IN fal_factory_floor.fal_factory_floor_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(FAL_FACTORY_FLOOR,
      XMLAttributes(
        sys_context('userenv', 'current_schema') as "current_schema",
        sys_context('userenv', 'current_user') as "current_user",
        sys_context('userenv', 'terminal') as "terminal",
        sys_context('userenv', 'nls_date_format') as "nls_date_format"),
      ltm_xml_utils.genXML(CURSOR(
        select * from fal_factory_floor
        where fal_factory_floor_id = T.fal_factory_floor_id),
        ''),
      ltm_track_ind_functions.get_fal_fact_floor_rates(fal_factory_floor_id),
      ltm_track_ind_functions.get_fal_fact_floor_parameters(fal_factory_floor_id),
      ltm_track_ind_functions.get_fal_fact_floor_accounts(fal_factory_floor_id),
      ltm_track_ind_functions.get_fal_fact_floor_machines(fal_factory_floor_id),
      ltm_track_ind_functions.get_fal_fact_floor_employees(fal_factory_floor_id),
      ltm_track_pac_functions_link.get_pac_schedule_link(pac_schedule_id),
      ltm_track_pac_functions_link.get_pac_calendar_type_link(pac_calendar_type_id),
      ltm_track_fin_functions_link.get_acs_account_link(acs_cda_account_id, 'ACS_CDA_ACCOUNT'),
      ltm_track_hrm_functions_link.get_hrm_person_link(hrm_person_id),
      ltm_track_gal_functions_link.get_gal_cost_center_link(gal_cost_center_id),
      ltm_track_ind_functions_link.get_fal_fact_floor_link(fal_fal_factory_floor_id,'FAL_FAL_FACTORY_FLOOR'),
      ltm_track_ind_functions_link.get_fal_fact_floor_link(fal_grp_factory_floor_id,'FAL_GRP_FACTORY_FLOOR')
    ) into obj
  from fal_factory_floor T
  where fal_factory_floor_id = Id;
  return obj;

  exception
    when OTHERS then
      obj := COM_XmlErrorDetail(sqlerrm);
      select
        XMLElement(FAL_FACTORY_FLOOR,
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

function get_fal_fact_floor_rates(Id IN fal_factory_rate.fal_factory_floor_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(FAL_FACTORY_RATE,
      ltm_xml_utils.genXML(CURSOR(
        select * from fal_factory_rate
        where fal_factory_rate_id = T.fal_factory_rate_id),
        ''),
      ltm_track_ind_functions.get_fal_fact_floor_rate_decomp(fal_factory_rate_id))
      order by a_datecre
    ) into obj
  from fal_factory_rate T
  where fal_factory_floor_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_fal_fact_floor_rate_decomp(Id IN fal_fact_rate_decomp.fal_factory_rate_id%TYPE)
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
        select * from fal_fact_rate_decomp
        where fal_fact_rate_decomp_id = T.fal_fact_rate_decomp_id),
        'FAL_FACT_RATE_DECOMP')
      order by a_datecre
    ) into obj
  from fal_fact_rate_decomp T
  where fal_factory_rate_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_fal_fact_floor_parameters(Id IN fal_factory_parameter.fal_factory_floor_id%TYPE)
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
        select * from fal_factory_parameter
        where fal_factory_parameter_id = T.fal_factory_parameter_id),
        'FAL_FACTORY_PARAMETER')
      order by a_datecre
    ) into obj
  from fal_factory_parameter T
  where fal_factory_floor_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_fal_fact_floor_accounts(Id IN fal_factory_account.fal_factory_floor_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(FAL_FACTORY_ACCOUNT,
      ltm_xml_utils.genXML(CURSOR(
        select * from fal_factory_account
        where fal_factory_account_id = T.fal_factory_account_id),
        ''),
      ltm_track_fin_functions_link.get_acs_account_link(acs_financial_account_id, 'ACS_FINANCIAL_ACCOUNT'),
      ltm_track_fin_functions_link.get_acs_account_link(acs_division_account_id, 'ACS_DIVISION_ACCOUNT'),
      ltm_track_fin_functions_link.get_acs_account_link(acs_cpn_account_id, 'ACS_CPN_ACCOUNT'),
      ltm_track_fin_functions_link.get_acs_account_link(acs_cda_account_id, 'ACS_CDA_ACCOUNT'),
      ltm_track_fin_functions_link.get_acs_account_link(acs_pf_account_id, 'ACS_PF_ACCOUNT'),
      ltm_track_fin_functions_link.get_acs_account_link(acs_pj_account_id, 'ACS_PJ_ACCOUNT'),
      ltm_track_fin_functions_link.get_acs_account_link(acs_qty_unit_id, 'ACS_QTY_UNIT'),
      ltm_track_log_functions_link.get_doc_record_link(doc_record_id))
      order by a_datecre
    ) into obj
  from fal_factory_account T
  where fal_factory_floor_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_fal_fact_floor_machines(Id IN fal_factory_floor.fal_fal_factory_floor_id%TYPE)
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
        select * from fal_factory_floor
        where fal_factory_floor_id = T.fal_factory_floor_id),
        'FAL_FACTORY_FLOOR')
      order by a_datecre
    ) into obj
  from fal_factory_floor T
  where fal_fal_factory_floor_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_fal_fact_floor_employees(Id IN fal_factory_floor.fal_grp_factory_floor_id%TYPE)
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
        select * from fal_factory_floor
        where fal_factory_floor_id = T.fal_factory_floor_Id),
        'FAL_FACTORY_FLOOR')
      order by a_datecre
    ) into obj
  from fal_factory_floor T
  where fal_grp_factory_floor_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

  /**
  * Description
  *   retourne la gamme opératoire
  */
  function get_fal_schedule_plan_xml(Id in FAL_SCHEDULE_PLAN.FAL_SCHEDULE_PLAN_ID%type)
    return xmltype
  is
    obj xmltype;
  begin
    if (Id is null) then
      return null;
    end if;

    select XMLElement(FAL_SCHEDULE_PLAN
                    , XMLAttributes(sys_context('userenv', 'current_schema') as "current_schema"
                                  , sys_context('userenv', 'current_user') as "current_user"
                                  , sys_context('userenv', 'terminal') as "terminal"
                                  , sys_context('userenv', 'nls_date_format') as "nls_date_format"
                                   )
                    , LTM_XML_UTILS.genXML(cursor(select *
                                                    from FAL_SCHEDULE_PLAN
                                                   where FAL_SCHEDULE_PLAN_ID = T.FAL_SCHEDULE_PLAN_ID), '')
                    , LTM_TRACK_IND_FUNCTIONS.get_fal_list_step_link(T.FAL_SCHEDULE_PLAN_ID)
                     )
      into obj
      from FAL_SCHEDULE_PLAN T
     where FAL_SCHEDULE_PLAN_ID = Id;

    return obj;
  exception
    when others then
      obj  := COM_XmlErrorDetail(sqlerrm);

      select XMLElement(FAL_SCHEDULE_PLAN
                      , XMLAttributes(Id as id
                                    , sys_context('userenv', 'current_schema') as "CURRENT_SCHEMA"
                                    , sys_context('userenv', 'current_user') as "CURRENT_USER"
                                    , sys_context('userenv', 'terminal') as "TERMINAL"
                                    , sys_context('userenv', 'nls_date_format') as "NLS_DATE_FORMAT"
                                     )
                      , obj
                       )
        into obj
        from dual;

      return obj;
  end get_fal_schedule_plan_xml;

  /**
  * Description
  *   retourne l'opération d'une gamme opératoire
  */
  function get_fal_list_step_link(Id in FAL_SCHEDULE_PLAN.FAL_SCHEDULE_PLAN_ID%type)
    return xmltype
  is
    obj xmltype;
  begin
    if (Id is null) then
      return null;
    end if;

    select XMLAgg
             (XMLElement(FAL_LIST_STEP_LINK
                       , LTM_XML_UTILS.genXML(cursor(select *
                                                       from FAL_LIST_STEP_LINK
                                                      where FAL_LIST_STEP_LINK_ID = T.FAL_LIST_STEP_LINK_ID), '')
                       , LTM_TRACK_PAC_FUNCTIONS_LINK.get_pac_supplier_partner_link(PAC_SUPPLIER_PARTNER_ID
                                                                                  , 'PAC_SUPPLIER_PARTNER'
                                                                                   )
                       , LTM_TRACK_IND_FUNCTIONS_LINK.get_pps_op_proc_link(PPS_OPERATION_PROCEDURE_ID
                                                                         , 'PPS_OPERATION_PROCEDURE'
                                                                          )
                       , LTM_TRACK_IND_FUNCTIONS_LINK.get_pps_op_proc_link(PPS_PPS_OPERATION_PROCEDURE_ID
                                                                         , 'PPS_PPS_OPERATION_PROCEDURE'
                                                                          )
                       , LTM_TRACK_IND_FUNCTIONS_LINK.get_fal_factory_floor_link(FAL_FACTORY_FLOOR_ID
                                                                               , 'FAL_FACTORY_FLOOR'
                                                                                )
                       , LTM_TRACK_IND_FUNCTIONS_LINK.get_fal_task_link(FAL_TASK_ID, 'FAL_TASK')
                       , LTM_TRACK_IND_FUNCTIONS_LINK.get_pps_tools_link(PPS_TOOLS1_ID, 'PPS_TOOLS1')
                       , LTM_TRACK_IND_FUNCTIONS_LINK.get_pps_tools_link(PPS_TOOLS2_ID, 'PPS_TOOLS2')
                       , LTM_TRACK_IND_FUNCTIONS_LINK.get_pps_tools_link(PPS_TOOLS3_ID, 'PPS_TOOLS3')
                       , LTM_TRACK_IND_FUNCTIONS_LINK.get_pps_tools_link(PPS_TOOLS4_ID, 'PPS_TOOLS4')
                       , LTM_TRACK_IND_FUNCTIONS_LINK.get_pps_tools_link(PPS_TOOLS5_ID, 'PPS_TOOLS5')
                       , LTM_TRACK_IND_FUNCTIONS_LINK.get_pps_tools_link(PPS_TOOLS6_ID, 'PPS_TOOLS6')
                       , LTM_TRACK_IND_FUNCTIONS_LINK.get_pps_tools_link(PPS_TOOLS7_ID, 'PPS_TOOLS7')
                       , LTM_TRACK_IND_FUNCTIONS_LINK.get_pps_tools_link(PPS_TOOLS8_ID, 'PPS_TOOLS8')
                       , LTM_TRACK_IND_FUNCTIONS_LINK.get_pps_tools_link(PPS_TOOLS9_ID, 'PPS_TOOLS9')
                       , LTM_TRACK_IND_FUNCTIONS_LINK.get_pps_tools_link(PPS_TOOLS10_ID, 'PPS_TOOLS10')
                       , LTM_TRACK_IND_FUNCTIONS_LINK.get_pps_tools_link(PPS_TOOLS11_ID, 'PPS_TOOLS11')
                       , LTM_TRACK_IND_FUNCTIONS_LINK.get_pps_tools_link(PPS_TOOLS12_ID, 'PPS_TOOLS12')
                       , LTM_TRACK_IND_FUNCTIONS_LINK.get_pps_tools_link(PPS_TOOLS13_ID, 'PPS_TOOLS13')
                       , LTM_TRACK_IND_FUNCTIONS_LINK.get_pps_tools_link(PPS_TOOLS14_ID, 'PPS_TOOLS14')
                       , LTM_TRACK_IND_FUNCTIONS_LINK.get_pps_tools_link(PPS_TOOLS15_ID, 'PPS_TOOLS15')
                       , LTM_TRACK_IND_FUNCTIONS_LINK.get_fal_factory_floor_link(FAL_FAL_FACTORY_FLOOR_ID
                                                                               , 'FAL_FAL_FACTORY_FLOOR'
                                                                                )
                       , LTM_TRACK_LOG_FUNCTIONS_LINK.get_gco_good_link(GCO_GCO_GOOD_ID, 'GCO_GCO_GOOD')
                        ) order by SCS_STEP_NUMBER
             )
      into obj
      from FAL_LIST_STEP_LINK T
     where FAL_SCHEDULE_PLAN_ID = Id;

    return obj;
  exception
    when others then
      return null;
  end get_fal_list_step_link;

  /**
  * Description
  *   retourne l'opération d'un lot de fabrication
  */
  function get_fal_task_link(Id in FAL_LOT.FAL_LOT_ID%type)
    return xmltype
  is
    obj xmltype;
  begin
    if (Id is null) then
      return null;
    end if;

    select XMLAgg
             (XMLElement(FAL_TASK_LINK
                       , LTM_XML_UTILS.genXML(cursor(select *
                                                       from FAL_TASK_LINK
                                                      where FAL_SCHEDULE_STEP_ID = T.FAL_SCHEDULE_STEP_ID), '')
--                    , LTM_TRACK_IND_FUNCTIONS_LINK.get_fal_lot_link(FAL_LOT_ID, 'FAL_LOT')
              ,          LTM_TRACK_LOG_FUNCTIONS_LINK.get_doc_document_link(DOC_DOCUMENT_ID, 'DOC_DOCUMENT')
                       , LTM_TRACK_PAC_FUNCTIONS_LINK.get_pac_supplier_partner_link(PAC_SUPPLIER_PARTNER_ID
                                                                                  , 'PAC_SUPPLIER_PARTNER'
                                                                                   )
                        ) order by SCS_STEP_NUMBER
             )
      into obj
      from FAL_TASK_LINK T
     where FAL_LOT_ID = Id;

    return obj;
  exception
    when others then
      return null;
  end get_fal_task_link;

  /**
  * Description
  *   retourne la nomenclature
  */
  function get_pps_nomenclature_xml(Id in PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type)
    return xmltype
  is
    obj xmltype;
  begin
    if (Id is null) then
      return null;
    end if;

    select XMLElement(PPS_NOMENCLATURE
                    , XMLAttributes(sys_context('userenv', 'current_schema') as "current_schema"
                                  , sys_context('userenv', 'current_user') as "current_user"
                                  , sys_context('userenv', 'terminal') as "terminal"
                                  , sys_context('userenv', 'nls_date_format') as "nls_date_format"
                                   )
                    , LTM_XML_UTILS.genXML(cursor(select *
                                                    from PPS_NOMENCLATURE
                                                   where PPS_NOMENCLATURE_ID = T.PPS_NOMENCLATURE_ID), '')
                    , LTM_TRACK_LOG_FUNCTIONS_LINK.get_gco_good_link(GCO_GOOD_ID, 'GCO_GOOD')
                    , LTM_TRACK_LOG_FUNCTIONS_LINK.get_doc_record_link(DOC_RECORD_ID, 'DOC_RECORD')
                    , LTM_TRACK_LOG_FUNCTIONS_LINK.get_doc_record_link(DOC_DOC_RECORD_ID, 'DOC_DOC_RECORD')
                    , LTM_TRACK_IND_FUNCTIONS_LINK.get_fal_schedule_plan_link(FAL_SCHEDULE_PLAN_ID, 'FAL_SCHEDULE_PLAN')
                    , LTM_TRACK_IND_FUNCTIONS.get_pps_nom_bond(T.PPS_NOMENCLATURE_ID)
                     )
      into obj
      from PPS_NOMENCLATURE T
     where PPS_NOMENCLATURE_ID = Id;

    return obj;
  exception
    when others then
      obj  := COM_XmlErrorDetail(sqlerrm);

      select XMLElement(PPS_NOMENCLATURE
                      , XMLAttributes(Id as id
                                    , sys_context('userenv', 'current_schema') as "CURRENT_SCHEMA"
                                    , sys_context('userenv', 'current_user') as "CURRENT_USER"
                                    , sys_context('userenv', 'terminal') as "TERMINAL"
                                    , sys_context('userenv', 'nls_date_format') as "NLS_DATE_FORMAT"
                                     )
                      , obj
                       )
        into obj
        from dual;

      return obj;
  end get_pps_nomenclature_xml;

  /**
  * Description
  *   retourne un composant de la nomenclature
  */
  function get_pps_nom_bond(Id in PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type)
    return xmltype
  is
    obj xmltype;
  begin
    if (Id is null) then
      return null;
    end if;

    select XMLAgg
              (XMLElement(PPS_NOM_BOND
                        , LTM_XML_UTILS.genXML(cursor(select *
                                                        from PPS_NOM_BOND
                                                       where PPS_NOM_BOND_ID = T.PPS_NOM_BOND_ID), '')
                        , LTM_TRACK_LOG_FUNCTIONS_LINK.get_stm_stock_link(STM_STOCK_ID, 'STM_STOCK')
                        , LTM_TRACK_LOG_FUNCTIONS_LINK.get_stm_location_link(STM_LOCATION_ID, 'STM_LOCATION')
                        , LTM_TRACK_IND_FUNCTIONS_LINK.get_fal_task_link_link(FAL_SCHEDULE_STEP_ID, 'FAL_TASK_LINK')
                        , LTM_TRACK_LOG_FUNCTIONS_LINK.get_gco_good_link(GCO_GOOD_ID, 'GCO_GOOD')
                        , LTM_TRACK_IND_FUNCTIONS_LINK.get_pps_nomenclature_link(PPS_PPS_NOMENCLATURE_ID
                                                                               , 'PPS_PPS_NOMENCLATURE'
                                                                                )
                         ) order by GCO_GOOD_ID
              , COM_SEQ
              )
      into obj
      from PPS_NOM_BOND T
     where PPS_NOMENCLATURE_ID = Id;

    return obj;
  exception
    when others then
      return null;
  end get_pps_nom_bond;

  /**
  * Description
  *   retourne la nomenclature d'un bien
  */
  function get_pps_nomenclature(inID in GCO_GOOD.GCO_GOOD_ID%type)
    return xmltype
  is
    obj xmltype;
  begin
    if (inID is null) then
      return null;
    end if;

    select XMLAgg
              (XMLElement(PPS_NOMENCLATURE
                        , LTM_XML_UTILS.genXML(cursor(select *
                                                        from PPS_NOMENCLATURE
                                                       where PPS_NOMENCLATURE_ID = T.PPS_NOMENCLATURE_ID), '')
                        , LTM_TRACK_LOG_FUNCTIONS_LINK.get_gco_good_link(GCO_GOOD_ID, 'GCO_GOOD')
                        , LTM_TRACK_LOG_FUNCTIONS_LINK.get_doc_record_link(DOC_RECORD_ID, 'DOC_RECORD')
                        , LTM_TRACK_LOG_FUNCTIONS_LINK.get_doc_record_link(DOC_DOC_RECORD_ID, 'DOC_DOC_RECORD')
                        , LTM_TRACK_IND_FUNCTIONS_LINK.get_fal_schedule_plan_link(FAL_SCHEDULE_PLAN_ID
                                                                                , 'FAL_SCHEDULE_PLAN'
                                                                                 )
                        , LTM_TRACK_IND_FUNCTIONS.get_pps_nom_bond(T.PPS_NOMENCLATURE_ID)
                         ) order by C_TYPE_NOM
              , GCO_GOOD_ID
              , NOM_VERSION
              , DOC_RECORD_ID
              )
      into obj
      from PPS_NOMENCLATURE T
     where GCO_GOOD_ID = inID;

    return obj;
  exception
    when others then
      return null;
  end get_pps_nomenclature;

  /**
  * Description
  *   retourne toutes les nomenclatures du bien
  */
  function get_pps_good_nomenclature_xml(inID in GCO_GOOD.GCO_GOOD_ID%type)
    return xmltype
  is
    obj xmltype;
  begin
    if (inID is null) then
      return null;
    end if;

    select XMLElement(PPS_GOOD_NOMENCLATURE
                    , XMLAttributes(sys_context('userenv', 'current_schema') as "current_schema"
                                  , sys_context('userenv', 'current_user') as "current_user"
                                  , sys_context('userenv', 'terminal') as "terminal"
                                  , sys_context('userenv', 'nls_date_format') as "nls_date_format"
                                   )
                    , LTM_TRACK_LOG_FUNCTIONS_LINK.get_gco_good_link(GCO_GOOD_ID, 'GCO_GOOD')
                    , LTM_TRACK_IND_FUNCTIONS.get_pps_nomenclature(T.GCO_GOOD_ID)
                     )
      into obj
      from GCO_GOOD T
     where GCO_GOOD_ID = inID;

    return obj;
  exception
    when others then
      obj  := COM_XmlErrorDetail(sqlerrm);

      select XMLElement(PPS_GOOD_NOMENCLATURE
                      , XMLAttributes(inID as id
                                    , sys_context('userenv', 'current_schema') as "CURRENT_SCHEMA"
                                    , sys_context('userenv', 'current_user') as "CURRENT_USER"
                                    , sys_context('userenv', 'terminal') as "TERMINAL"
                                    , sys_context('userenv', 'nls_date_format') as "NLS_DATE_FORMAT"
                                     )
                      , obj
                       )
        into obj
        from dual;

      return obj;
  end get_pps_good_nomenclature_xml;
END LTM_TRACK_IND_FUNCTIONS;
