--------------------------------------------------------
--  DDL for Package Body LTM_TRACK_LOG_FUNCTIONS_LINK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "LTM_TRACK_LOG_FUNCTIONS_LINK" 
/**
 * Package LTM_TRACK_LOG_FUNCTIONS_LINK
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
 * Spécialisation: Logistique, tarifs et stockage (GCO,PTC,STM)
 */
AS

function get_gco_multimedia_link(Id IN gco_multimedia_element.gco_multimedia_element_id%TYPE,
  FieldRef IN VARCHAR2 default 'GCO_MULTIMEDIA_ELEMENT')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select gco_multimedia_element_id, mme_multimedia_designation
      from gco_multimedia_element
      where gco_multimedia_element_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_dangerous_transp_link(Id IN gco_dangerous_transp.gco_dangerous_transp_id%TYPE,
  FieldRef IN VARCHAR2 default 'GCO_DANGEROUS_TRANSP')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select gco_dangerous_transp_id, gtd_reference, c_type_card
      from gco_dangerous_transp
      where gco_dangerous_transp_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_good_link(Id IN gco_good.gco_good_id%TYPE,
  FieldRef IN VARCHAR2 default 'GCO_GOOD')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select gco_good_id, goo_major_reference
      from gco_good
      where gco_good_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_substitution_link(Id IN gco_substitution_list.gco_substitution_list_id%TYPE,
  FieldRef IN VARCHAR2 default 'GCO_SUBSTITUTION_LIST')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select gco_substitution_list_id, sul_substitution_list_design,sul_from_date
      from gco_substitution_list
      where gco_substitution_list_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_quality_principle_link(Id IN gco_quality_principle.gco_quality_principle_id%TYPE,
  FieldRef IN VARCHAR2 default 'GCO_QUALITY_PRINCIPLE')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select gco_quality_principle_id, qpr_quality_principle_design
      from gco_quality_principle
      where gco_quality_principle_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_product_group_link(Id IN gco_product_group.gco_product_group_id%TYPE,
  FieldRef IN VARCHAR2 default 'GCO_PRODUCT_GROUP')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select gco_product_group_id, prg_name
      from gco_product_group
      where gco_product_group_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_alloy_link(Id IN gco_alloy.gco_alloy_id%TYPE,
  FieldRef IN VARCHAR2 default 'GCO_ALLOY')
  return XMLType
is
  obj XMLTYpe;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select gco_alloy_id, gal_alloy_ref
      from gco_alloy
      where gco_alloy_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_compl_data_manuf_link(Id IN gco_compl_data_manufacture.gco_compl_data_manufacture_id%TYPE,
  FieldRef IN VARCHAR2 default 'GCO_COMPL_DATA_MANUFACTURE')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(GCO_COMPL_DATA_MANUFACTURE,
      ltm_xml_utils.genXML(CURSOR(
        select gco_compl_data_manufacture_id, gco_good_id, dic_fab_condition_id
        from gco_compl_data_manufacture
        where gco_compl_data_manufacture_id = T.gco_compl_data_manufacture_id),
        ''),
      ltm_track_log_functions_link.get_gco_good_link(gco_good_id)
    ) into obj
  from gco_compl_data_manufacture T
  where gco_compl_data_manufacture_id = Id;

  if (obj is not null and FieldRef != 'GCO_COMPL_DATA_MANUFACTURE') then
    return ltm_xml_utils.transform_root_ref('GCO_COMPL_DATA_MANUFACTURE', FieldRef, obj);
  end if;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_quality_status_link(Id IN gco_quality_status.gco_quality_status_id%TYPE,
  FieldRef IN VARCHAR2 default 'GCO_QUALITY_STATUS')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select gco_quality_status_id, qst_reference
      from gco_quality_status
      where gco_quality_status_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end get_gco_quality_status_link;

function get_gco_quality_stat_flow_link(Id IN gco_quality_stat_flow.gco_quality_stat_flow_id%TYPE,
  FieldRef IN VARCHAR2 default 'GCO_QUALITY_STAT_FLOW')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select gco_quality_stat_flow_id, qsf_reference
      from gco_quality_stat_flow
      where gco_quality_stat_flow_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end get_gco_quality_stat_flow_link;

function get_stm_stock_link(Id IN stm_stock.stm_stock_id%TYPE,
  FieldRef IN VARCHAR2 default 'STM_STOCK')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select stm_stock_id, sto_description
      from stm_stock
      where stm_stock_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_stm_location_link(Id IN stm_location.stm_location_ID%TYPE,
  FieldRef IN VARCHAR2 default 'STM_LOCATION')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select stm_location_id, loc_description
      from stm_location
      where stm_location_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_stm_distribution_unit_link(Id IN stm_distribution_unit.stm_distribution_unit_id%TYPE,
  FieldRef IN VARCHAR2 default 'STM_DISTRIBUTION_UNIT')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(STM_DISTRIBUTION_UNIT,
      ltm_xml_utils.genXML(CURSOR(
        select stm_distribution_unit_id, diu_name, stm_stock_id
        from stm_distribution_unit
        where stm_distribution_unit_id = T.stm_distribution_unit_id),
        ''),
      ltm_track_log_functions_link.get_stm_stock_link(stm_stock_id)
    ) into obj
  from stm_distribution_unit T
  where stm_distribution_unit_id = Id;

  if (obj is not null and FieldRef != 'STM_DISTRIBUTION_UNIT') then
    return ltm_xml_utils.transform_root_ref('STM_DISTRIBUTION_UNIT', FieldRef, obj);
  end if;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_stm_element_number_link(Id IN stm_element_number.stm_element_number_id%TYPE,
  FieldRef IN VARCHAR2 default 'STM_ELEMENT_NUMBER')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select stm_element_number_id, c_ele_num_status, c_element_type, sem_value
      from stm_element_number
      where stm_element_number_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_stm_movement_kind_link(Id IN stm_movement_kind.stm_movement_kind_id%TYPE,
  FieldRef IN VARCHAR2 default 'STM_MOVEMENT_KIND')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select stm_movement_kind_id, mok_abbreviation
      from stm_movement_kind
      where stm_movement_kind_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end get_stm_movement_kind_link;

function get_stm_stock_movement_link(Id IN stm_stock_movement.stm_stock_movement_id%TYPE,
  FieldRef IN VARCHAR2 default 'STM_STOCK_MOVEMENT')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select smo.stm_stock_movement_id
           , (select mok_abbreviation from stm_movement_kind where stm_movement_kind_id = smo.stm_movement_kind_id) mok_abbreviation
           , substr(smo.smo_wording, 1, 100) smo_wording
           , smo.smo_extourne_mvt
        from stm_stock_movement smo
       where smo.stm_stock_movement_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end get_stm_stock_movement_link;

function get_asa_rep_type_link(Id IN asa_rep_type.asa_rep_type_id%TYPE,
  FieldRef IN VARCHAR2 default 'ASA_REP_TYPE')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select asa_rep_type_id, ret_rep_type
      from asa_rep_type
      where asa_rep_type_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_asa_count_type_s_good_link(Id IN asa_counter_type_s_good.asa_counter_type_s_good_id%TYPE,
  FieldRef IN VARCHAR2 default 'ASA_COUNTER_TYPE_S_GOOD')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(ASA_COUNTER_TYPE_S_GOOD,
      ltm_xml_utils.genXML(CURSOR(
        select asa_counter_type_s_good_id, asa_counter_type_id, ctg_pc_appltxt_id, gco_good_id
        from asa_counter_type_s_good
        where asa_counter_type_s_good_id = T.asa_counter_type_s_good_id),
        ''),
      ltm_track_log_functions_link.get_asa_counter_type_link(asa_counter_type_id),
      ltm_track_log_functions_link.get_gco_good_link(gco_good_id),
      ltm_track_pc_functions_link.get_pc_appltxt_link(ctg_pc_appltxt_id)
    ) into obj
  from asa_counter_type_s_good T
  where asa_counter_type_s_good_id = Id;

  if (obj is not null and FieldRef != 'ASA_COUNTER_TYPE_S_GOOD') then
    return ltm_xml_utils.transform_root_ref('ASA_COUNTER_TYPE_S_GOOD', FieldRef, obj);
  end if;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_asa_counter_type_link(Id IN asa_counter_type.asa_counter_type_id%TYPE,
  FieldRef IN VARCHAR2 default 'ASA_COUNTER_TYPE')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select asa_counter_type_id, dic_asa_unit_of_measure_id, ctt_descr, ctt_key
      from asa_counter_type
      where asa_counter_type_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_asa_mission_link(Id IN asa_mission.asa_mission_id%TYPE,
  FieldRef IN VARCHAR2 default 'ASA_MISSION')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select asa_mission_id, mis_number
      from asa_mission
      where asa_mission_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_doc_document_link(Id IN doc_document.doc_document_id%TYPE,
  FieldRef IN VARCHAR2 default 'DOC_DOCUMENT')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select doc_document_id, dmt_number
      from doc_document
      where doc_document_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_doc_position_link(Id IN doc_position.doc_position_id%TYPE,
  FieldRef IN VARCHAR2 default 'DOC_POSITION')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(DOC_POSITION,
      ltm_xml_utils.genXML(CURSOR(
        select doc_position_id
        from doc_position
        where doc_position_id = T.doc_position_id),
        ''),
      ltm_track_log_functions_link.get_doc_document_link(doc_document_id)
    ) into obj
  from doc_position T
  where doc_position_id = Id;

  if (obj is not null and FieldRef != 'DOC_POSITION') then
    return ltm_xml_utils.transform_root_ref('DOC_POSITION', FieldRef, obj);
  end if;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_doc_record_link(Id IN doc_record.doc_record_id%TYPE,
  FieldRef IN VARCHAR2 default 'DOC_RECORD')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select doc_record_id, rco_title
      from doc_record
      where doc_record_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_doc_record_category_link(Id IN doc_record_category.doc_record_category_id%TYPE,
  FieldRef IN VARCHAR2 default 'DOC_RECORD_CATEGORY')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select doc_record_category_id, rcy_key
      from doc_record_category
      where doc_record_category_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_doc_record_cat_lnk_link(Id IN doc_record_category_link.doc_record_category_link_id%TYPE,
  FieldRef IN VARCHAR2 default 'DOC_RECORD_CATEGORY_LINK')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(DOC_RECORD_CATEGORY_LINK,
      ltm_xml_utils.genXML(CURSOR(
        select doc_record_category_link_id
        from doc_record_category_link
        where doc_record_category_link_id = T.doc_record_category_link_id),
        ''),
      ltm_track_log_functions_link.get_doc_record_category_link(doc_record_cat_father_id, 'DOC_RECORD_CAT_FATHER'),
      ltm_track_log_functions_link.get_doc_record_category_link(doc_record_cat_daughter_id, 'DOC_RECORD_CAT_DAUGHTER'),
      ltm_track_log_functions_link.get_doc_rec_cat_lnk_type_link(doc_record_cat_link_type_id)
    ) into obj
  from doc_record_category_link T
  where doc_record_category_link_id = Id;

  if (obj is not null and FieldRef != 'DOC_RECORD_CATEGORY_LINK') then
    return ltm_xml_utils.transform_root_ref('DOC_RECORD_CATEGORY_LINK', FieldRef, obj);
  end if;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_doc_rec_cat_lnk_type_link(Id IN doc_record_cat_link_type.doc_record_cat_link_type_id%TYPE,
  FieldRef IN VARCHAR2 default 'DOC_RECORD_CAT_LINK_TYPE')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select doc_record_cat_link_type_id, rlt_descr, rlt_downward_semantic, rlt_upward_semantic
      from doc_record_cat_link_type
      where doc_record_cat_link_type_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_doc_gauge_link(Id IN doc_gauge.doc_gauge_id%TYPE,
  FieldRef IN VARCHAR2 default 'DOC_GAUGE')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select doc_gauge_id, c_admin_domain, c_gauge_type, gau_describe
      from doc_gauge
      where doc_gauge_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

END LTM_TRACK_LOG_FUNCTIONS_LINK;
