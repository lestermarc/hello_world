--------------------------------------------------------
--  DDL for Package Body REP_LOG_FUNCTIONS_LINK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_LOG_FUNCTIONS_LINK" 
/**
 * Fonctions de génération de liaison pour document Xml.
 * Spécialisation: Logistique, tarifs et stockage (GCO,PTC,STM)
 *
 * @version 1.0
 * @date 02/2003
 * @author jsomers
 * @author spfister
 * @author fperotto
 * @author ngomes
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
AS

--
-- GCO  functions
--

function get_gco_dangerous_transp_link(
  Id IN gco_dangerous_transp.gco_dangerous_transp_id%TYPE,
  FieldRef IN VARCHAR2 default 'GCO_DANGEROUS_TRANSP')
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(GCO_DANGEROUS_TRANSP,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'GTD_REFERENCE,C_TYPE_CARD' as TABLE_KEY,
        'GCO_DANGEROUS_TRANSP' as TABLE_REFERENCE,
        gco_dangerous_transp_id,
        gtd_reference),
      rep_pc_functions.get_descodes('C_TYPE_CARD',c_type_card)
    ) into lx_data
  from gco_dangerous_transp
  where gco_dangerous_transp_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'GCO_DANGEROUS_TRANSP') then
      return rep_xml_function.transform_root_ref('GCO_DANGEROUS_TRANSP', FieldRef, lx_data);
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_quality_principle_link(
  Id IN gco_quality_principle.gco_quality_principle_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(GCO_QUALITY_PRINCIPLE,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'QPR_QUALITY_PRINCIPLE_DESIGN' as TABLE_KEY,
        gco_quality_principle_id,
        qpr_quality_principle_design)
    ) into lx_data
  from gco_quality_principle
  where gco_quality_principle_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_good_category_link(
  Id IN gco_good_category.gco_good_category_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(GCO_GOOD_CATEGORY,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'GCO_CATEGORY_CODE' as TABLE_KEY,
        gco_good_category_id,
        gco_category_code)
    ) into lx_data
  from gco_good_category
  where gco_good_category_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_good_link(
  Id IN gco_good.gco_good_id%TYPE,
  FieldRef IN VARCHAR2 default 'GCO_GOOD',
  ForceReference IN INTEGER default 0)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(GCO_GOOD,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'GOO_MAJOR_REFERENCE' as TABLE_KEY,
        gco_good_id,
        goo_major_reference)
    ) into lx_data
  from gco_good
  where gco_good_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'GCO_GOOD') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('GCO_GOOD', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('GCO_GOOD', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

  /**
  * Description
  *    Fonction de recherche du lien d'un produit,
  */
  function get_gco_product_link(
    id             in GCO_PRODUCT.GCO_GOOD_ID%type
  , FieldRef       in varchar2 default 'GCO_PRODUCT'
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
                        when 1 then XMLElement(TABLE_REFERENCE, 'GCO_PRODUCT')
                      end
                    , XMLElement(TABLE_TYPE, 'LINK')
                    , XMLElement(TABLE_KEY, 'GCO_GOOD_ID')
                    , XMLElement(GCO_GOOD_ID, GCO_GOOD_ID)
                    , REP_LOG_FUNCTIONS_LINK.get_gco_good_link(GCO_GOOD_ID)
                     )
      into lxData
      from GCO_PRODUCT
     where GCO_GOOD_ID = id;

    return lxData;
  exception
    when no_data_found then
      return null;
  end get_gco_product_link;

function get_gco_good_link_category(
  Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(GCO_GOOD,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'GOO_MAJOR_REFERENCE' as TABLE_KEY,
        gco_good_id,
        goo_major_reference),
      rep_log_functions_link.get_gco_good_category_link(gco_good_category_id)
    ) into lx_data
  from gco_good
  where gco_good_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_multimedia_link(
  Id IN gco_multimedia_element.gco_multimedia_element_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(GCO_MULTIMEDIA_ELEMENT,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'MME_MULTIMEDIA_DESIGNATION' as TABLE_KEY,
        gco_multimedia_element_id,
        mme_multimedia_designation)
    ) into lx_data
  from gco_multimedia_element
  where gco_multimedia_element_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_substitution_link(
  Id IN gco_substitution_list.gco_substitution_list_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(GCO_SUBSTITUTION_LIST,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'SUL_SUBSTITUTION_LIST_DESIGN, SUL_FROM_DATE' as TABLE_KEY,
        gco_substitution_list_id,
        sul_substitution_list_design,
        to_char(sul_from_date) as SUL_FROM_DATE)
    ) into lx_data
  from gco_substitution_list
  where gco_substitution_list_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_alloy_link(
  Id IN gco_alloy.gco_alloy_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(GCO_ALLOY,
      XMLForest(
        'LINK_MANDATORY' as TABLE_TYPE,
        'GAL_ALLOY_REF' as TABLE_KEY,
        gco_alloy_id,
        gal_alloy_ref)
    ) into lx_data
  from gco_alloy
  where gco_alloy_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_product_group_link(
  Id gco_product_group.gco_product_group_id%TYPE,
  IsMandatory IN INTEGER default 0)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(GCO_PRODUCT_GROUP,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'PRG_NAME' as TABLE_KEY,
        gco_product_group_id,
        prg_name)
    ) into lx_data
  from gco_product_group
  where gco_product_group_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_characterization_link(
  Id IN gco_characterization.gco_characterization_id%TYPE,
  FieldRef IN VARCHAR2 default 'GCO_CHARACTERIZATION',
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
    XMLElement(GCO_CHARACTERIZATION,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'GCO_GOOD_ID,C_CHARACT_TYPE,CHA_CHARACTERIZATION_DESIGN' as TABLE_KEY,
        gco_characterization_id),
      rep_log_functions_link.get_gco_good_link(gco_good_id),
      rep_pc_functions.get_descodes('C_CHARACT_TYPE', c_charact_type),
      XMLForest(
        cha_characterization_design)
    ) into lx_data
  from gco_characterization
  where gco_characterization_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'GCO_CHARACTERIZATION') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('GCO_CHARACTERIZATION', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('GCO_CHARACTERIZATION', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_quality_status_link(
  Id IN gco_quality_status.gco_quality_status_id%TYPE,
  FieldRef IN VARCHAR2 default 'GCO_QUALITY_STATUS',
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
    XMLElement(GCO_QUALITY_STATUS,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'QST_REFERENCE' as TABLE_KEY,
        GCO_QUALITY_STATUS_ID,
        QST_REFERENCE)
    ) into lx_data
  from GCO_QUALITY_STATUS
  where GCO_QUALITY_STATUS_ID = Id;

  if (lx_data is not null) then
    if (FieldRef != 'GCO_QUALITY_STATUS') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('GCO_QUALITY_STATUS', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('GCO_QUALITY_STATUS', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end get_gco_quality_status_link;

/**
 * Fonction de recherche du lien d'un statut qualité
 * @param Id  Identifiant du statut qualité
 * @param FieldRef  Nom du champs servant de lien
 * @param ForceReference  Force l'ajout du tag TABLE_REFERENCE = GCO_QUALITY_STAT_FLOW
 * @param IsMandatory  Spécification du lien obligatoire
 * @return  XMLType
 */
function get_gco_quality_stat_flow_link(
  Id IN gco_quality_stat_flow.gco_quality_stat_flow_id%TYPE,
  FieldRef IN VARCHAR2 default 'GCO_QUALITY_STAT_FLOW',
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
    XMLElement(GCO_QUALITY_STAT_FLOW,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'QSF_REFERENCE' as TABLE_KEY,
        GCO_QUALITY_STAT_FLOW_ID,
        QSF_REFERENCE)
    ) into lx_data
  from GCO_QUALITY_STAT_FLOW
  where GCO_QUALITY_STAT_FLOW_ID = Id;

  if (lx_data is not null) then
    if (FieldRef != 'GCO_QUALITY_STAT_FLOW') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('GCO_QUALITY_STAT_FLOW', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('GCO_QUALITY_STAT_FLOW', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end get_gco_quality_stat_flow_link;

--
-- STM  functions
--

function get_stm_stock_link(
  Id IN stm_stock.stm_stock_id%TYPE,
  FieldRef IN VARCHAR2 default 'STM_STOCK',
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
    XMLElement(STM_STOCK,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'STO_DESCRIPTION' as TABLE_KEY,
        stm_stock_id,
        sto_description)
    ) into lx_data
  from stm_stock
  where stm_stock_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'STM_STOCK') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('STM_STOCK', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('STM_STOCK', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_stm_location_link(
  Id IN stm_location.stm_location_id%TYPE,
  FieldRef IN VARCHAR2 default 'STM_LOCATION',
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
    XMLElement(STM_LOCATION,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'STM_STOCK_ID,LOC_DESCRIPTION' as TABLE_KEY,
        stm_location_id),
      rep_log_functions_link.get_stm_stock_link(stm_stock_id),
      XMLForest(
        loc_description)
    ) into lx_data
  from stm_location
  where stm_location_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'STM_LOCATION') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('STM_LOCATION', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('STM_LOCATION', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_stm_distribution_unit_link(
  Id IN stm_distribution_unit.stm_distribution_unit_id%TYPE,
  FieldRef IN VARCHAR2 default 'STM_DISTRIBUTION_UNIT',
  ForceReference IN INTEGER default 0)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(STM_DISTRIBUTION_UNIT,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'DIU_NAME' as TABLE_KEY,
        stm_distribution_unit_id,
        diu_name)
    ) into lx_data
  from stm_distribution_unit
  where stm_distribution_unit_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'STM_DISTRIBUTION_UNIT') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('STM_DISTRIBUTION_UNIT', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('STM_DISTRIBUTION_UNIT', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_stm_movement_kind_link(
  Id IN stm_movement_kind.stm_movement_kind_id%TYPE,
  FieldRef IN VARCHAR2 default 'STM_MOVEMENT_KIND',
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
    XMLElement(STM_MOVEMENT_KIND,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'MOK_ABBREVIATION' as TABLE_KEY,
        stm_movement_kind_id,
        mok_abbreviation)
    ) into lx_data
  from stm_movement_kind
  where stm_movement_kind_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'STM_MOVEMENT_KIND') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('STM_MOVEMENT_KIND', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('STM_MOVEMENT_KIND', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_stm_exercise_link(
  Id IN stm_exercise.stm_exercise_id%TYPE,
  IsMandatory IN INTEGER default 0)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(STM_EXERCISE,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'EXE_STARTING_EXERCISE,EXE_ENDING_EXERCISE' as TABLE_KEY,
        stm_exercise_id,
        to_char(exe_starting_exercise) as EXE_STARTING_EXERCISE,
        to_char(exe_ending_exercise) as EXE_ENDING_EXERCISE)
    ) into lx_data
  from stm_exercise
  where stm_exercise_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_stm_period_link(
  Id IN STM_PERIOD.STM_PERIOD_ID%TYPE,
  IsMandatory IN INTEGER default 0)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(STM_PERIOD,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'STM_EXERCISE_ID,PER_STARTING_PERIOD,PER_ENDING_PERIOD' as TABLE_KEY,
        stm_period_id),
      rep_log_functions_link.get_stm_exercise_link(stm_exercise_id),
      XMLForest(
        to_char(per_starting_period) as PER_STARTING_PERIOD,
        to_char(per_ending_period) as PER_ENDING_PERIOD)
    ) into lx_data
  from stm_period
  where stm_period_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_stm_stock_movement_link(
  Id IN stm_stock_movement.stm_stock_movement_id%TYPE,
  FieldRef IN VARCHAR2 default 'STM_STOCK_MOVEMENT',
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
    XMLElement(STM_STOCK_MOVEMENT,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'GCO_GOOD_ID,STM_PERIOD_ID,STM_STOCK_ID,STM_MOVEMENT_KIND_ID' as TABLE_KEY,
        stm_stock_movement_id),
      rep_log_functions_link.get_gco_good_link(gco_good_id),
      rep_log_functions_link.get_stm_period_link(stm_period_id),
      rep_log_functions_link.get_stm_stock_link(stm_stock_id),
      rep_log_functions_link.get_stm_movement_kind_link(stm_movement_kind_id)
    ) into lx_data
  from stm_stock_movement
  where stm_stock_movement_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'STM_STOCK_MOVEMENT') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('STM_STOCK_MOVEMENT', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('STM_STOCK_MOVEMENT', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;


--
-- PTC  functions
--

function get_ptc_tariff_category_link(
  Id IN ptc_tariff_category.ptc_tariff_category_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(PTC_TARIFF_CATEGORY,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'TCA_DESCRIPTION' as TABLE_KEY,
        ptc_tariff_category_id,
        tca_description)
    ) into lx_data
  from ptc_tariff_category
  where ptc_tariff_category_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;


--
-- DOC  functions
--

function get_doc_doc_gap_link(
  Id IN doc_gauge_position.doc_gauge_position_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(DOC_DOC_GAUGE_POSITION,
      XMLForest(
        'FUNCTION' as TABLE_TYPE,
        'REP_LOG_FUNCTIONS.GET_DOC_GAUGE_POSITION_ID' as FUNCTION_NAME),
      XMLElement(PARAMETERS,
        XMLElement(PARAMETER,
          XMLAttributes(1 as NUM,'NUMBER' as TYPE),
          doc_gauge_id),
        XMLElement(PARAMETER,
          XMLAttributes(2 as NUM,'VARCHAR' as TYPE),
          gap_designation)
    )) into lx_data
  from doc_gauge_position
  where doc_gauge_position_id = Id;
  return lx_data;

  exception
    when others then return null;
end;

function get_doc_gauge_position_link(
  Id IN doc_gauge_position.doc_gauge_position_id%TYPE,
  FieldRef IN VARCHAR2 default 'DOC_GAUGE_POSITION',
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
    XMLElement(DOC_GAUGE_POSITION,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'DOC_GAUGE_ID,GAP_DESIGNATION' as TABLE_KEY,
        doc_gauge_position_id),
      rep_log_functions_link.get_doc_gauge_link(doc_gauge_id),
      XMLForest(
        gap_designation)
    ) into lx_data
  from doc_gauge_position
  where doc_gauge_position_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'DOC_GAUGE_POSITION') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('DOC_GAUGE_POSITION', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('DOC_GAUGE_POSITION', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_doc_record_link(
  Id IN doc_record.doc_record_id%TYPE,
  FieldRef IN VARCHAR2 default 'DOC_RECORD',
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
    XMLElement(DOC_RECORD,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'RCO_TITLE' as TABLE_KEY,
        doc_record_id,
        rco_title)
    ) into lx_data
  from doc_record
  where doc_record_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'DOC_RECORD') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('DOC_RECORD', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('DOC_RECORD', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_doc_position_detail_link(
  Id IN doc_position_detail.doc_position_detail_id%TYPE,
  FieldRef IN VARCHAR2 default 'DOC_POSITION_DETAIL',
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
    XMLElement(DOC_POSITION_DETAIL,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'DOC_POSITION_ID,DOC_DOCUMENT_ID' as TABLE_KEY,
        doc_position_detail_id),
      rep_log_functions_link.get_doc_position_link(doc_position_id, 'DOC_POSITION', 1),
      rep_log_functions_link.get_doc_document_link(doc_document_id, 'DOC_DOCUMENT', 1)
    ) into lx_data
  from doc_position_detail
  where doc_position_detail_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'DOC_POSITION_DETAIL') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('DOC_POSITION_DETAIL', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('DOC_POSITION_DETAIL', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_doc_position_link(
  Id IN doc_position.doc_position_id%TYPE,
  FieldRef IN VARCHAR2 default 'DOC_POSITION',
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
    XMLElement(DOC_POSITION,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'DOC_DOCUMENT_ID,POS_NUMBER' as TABLE_KEY,
        doc_position_id),
      rep_log_functions_link.get_doc_document_link(doc_document_id, 'DOC_DOCUMENT', 1),
      XMLForest(
        pos_number)
    ) into lx_data
  from doc_position
  where doc_position_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'DOC_POSITION') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('DOC_POSITION', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('DOC_POSITION', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_doc_document_link(
  Id IN doc_document.doc_document_id%TYPE,
  FieldRef IN VARCHAR2 default 'DOC_DOCUMENT',
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
    XMLElement(DOC_DOCUMENT,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'DMT_NUMBER' as TABLE_KEY,
        doc_document_id,
        dmt_number)
   )  into lx_data
  from doc_document
  where doc_document_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'DOC_DOCUMENT') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('DOC_DOCUMENT', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('DOC_DOCUMENT', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_doc_gauge_link(
  Id IN doc_gauge.doc_gauge_id%TYPE,
  FieldRef IN VARCHAR2 default 'DOC_GAUGE',
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
    XMLElement(DOC_GAUGE,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'C_ADMIN_DOMAIN,C_GAUGE_TYPE,GAU_DESCRIBE' as TABLE_KEY,
        doc_gauge_id),
      rep_pc_functions.get_descodes('C_ADMIN_DOMAIN', c_admin_domain),
      rep_pc_functions.get_descodes('C_GAUGE_TYPE', c_gauge_type),
      XMLForest(
        gau_describe)
    ) into lx_data
  from doc_gauge
  where doc_gauge_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'DOC_GAUGE') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('DOC_GAUGE', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('DOC_GAUGE', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_doc_gauge_tablemaping_link(
  Id IN doc_gauge.doc_gauge_id%TYPE,
  FieldRef IN VARCHAR2 default 'DOC_GAUGE')
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(DOC_GAUGE,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'DOC_GAUGE_ID' as TABLE_KEY,
        'DOC_GAUGE_ID=DOC_GAUGE_ID' as TABLE_MAPPING,
        'DOC_GAUGE' as TABLE_REFERENCE),
      rep_log_functions_link.get_doc_gauge_link(doc_gauge_id,'DOC_GAUGE',0)
    ) into lx_data
  from doc_gauge
  where doc_gauge_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'DOC_GAUGE') then
      return rep_xml_function.transform_root_ref('DOC_GAUGE', FieldRef, lx_data);
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_doc_gauge_flow_link(
  Id IN doc_gauge_flow.doc_gauge_flow_id%TYPE,
  FieldRef IN VARCHAR2 default 'DOC_GAUGE_FLOW',
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
    XMLElement(DOC_GAUGE_FLOW,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'PAC_THIRD_ID,C_ADMIN_DOMAIN,GAF_VERSION' as TABLE_KEY,
        doc_gauge_flow_id),
      rep_pac_functions_link.get_pac_third_link(pac_third_id),
      rep_pc_functions.get_descodes('C_ADMIN_DOMAIN', c_admin_domain),
      XMLForest(
        gaf_version)
    ) into lx_data
  from doc_gauge_flow
  where doc_gauge_flow_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'DOC_GAUGE_FLOW') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('DOC_GAUGE_FLOW', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('DOC_GAUGE_FLOW', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_doc_gauge_copy_link(
  Id IN doc_gauge_copy.doc_gauge_copy_id%TYPE,
  FieldRef IN VARCHAR2 default 'DOC_GAUGE_COPY',
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
    XMLElement(DOC_GAUGE_COPY,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'DOC_GAUGE_COPY_ID' as TABLE_KEY,
        doc_gauge_copy_id)
    ) into lx_data
  from doc_gauge_copy
  where doc_gauge_copy_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'DOC_GAUGE_COPY') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('DOC_GAUGE_COPY', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('DOC_GAUGE_COPY', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_doc_gauge_receipt_link(
  Id IN doc_gauge_receipt.doc_gauge_receipt_id%TYPE,
  FieldRef IN VARCHAR2 default 'DOC_GAUGE_RECEIPT',
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
    XMLElement(DOC_GAUGE_RECEIPT,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'DOC_GAUGE_RECEIPT_ID' as TABLE_KEY,
        doc_gauge_receipt_id)
    ) into lx_data
  from doc_gauge_receipt
  where doc_gauge_receipt_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'DOC_GAUGE_RECEIPT') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('DOC_GAUGE_RECEIPT', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('DOC_GAUGE_RECEIPT', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_doc_gauge_signatory_link(
  Id IN doc_gauge_signatory.doc_gauge_signatory_id%TYPE,
  FieldRef IN VARCHAR2 default 'DOC_GAUGE_SIGNATORY',
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
    XMLElement(DOC_GAUGE_SIGNATORY,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'GAG_NAME,GAG_FUNCTION' as TABLE_KEY,
        doc_gauge_signatory_id,
        gag_name,
        gag_function)
    ) into lx_data
  from doc_gauge_signatory
  where doc_gauge_signatory_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'DOC_GAUGE_SIGNATORY') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('DOC_GAUGE_SIGNATORY', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('DOC_GAUGE_SIGNATORY', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_doc_gauge_numbering_link(
  Id IN doc_gauge_numbering.doc_gauge_numbering_id%TYPE,
  IsMandatory IN INTEGER default 0)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(DOC_GAUGE_NUMBERING,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'GAN_DESCRIBE' as TABLE_KEY,
        doc_gauge_numbering_id,
        gan_describe)
    ) into lx_data
  from doc_gauge_numbering
  where doc_gauge_numbering_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_doc_extract_comm_link(
  Id IN doc_extract_commission.doc_extract_commission_id%TYPE,
  FieldRef IN VARCHAR2 default 'DOC_EXTRACT_COMMISSION',
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
    XMLElement(DOC_EXTRACT_COMMISSION,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'DOC_EXTRACT_COMMISSION_ID' as TABLE_KEY,
        doc_extract_commission_id)
    ) into lx_data
  from doc_extract_commission
  where doc_extract_commission_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'DOC_EXTRACT_COMMISSION') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('DOC_EXTRACT_COMMISSION', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('DOC_EXTRACT_COMMISSION', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;


function get_doc_record_category_link(
  Id IN doc_record_category.doc_record_category_id%TYPE,
  FieldRef IN VARCHAR2 default 'DOC_RECORD_CATEGORY',
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
    XMLElement(DOC_RECORD_CATEGORY,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'RCY_KEY' as TABLE_KEY,
        doc_record_category_id,
        rcy_key)
    ) into lx_data
  from doc_record_category
  where doc_record_category_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'DOC_RECORD_CATEGORY') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('DOC_RECORD_CATEGORY', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('DOC_RECORD_CATEGORY', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_rco_cat_lnk_type_link(
  Id IN doc_record_cat_link_type.doc_record_cat_link_type_id%TYPE,
  FieldRef IN VARCHAR2 default 'DOC_RECORD_CAT_LINK_TYPE',
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
    XMLElement(DOC_RECORD_CAT_LINK_TYPE,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'RLT_DESCR' as TABLE_KEY,
        doc_record_cat_link_type_id,
        rlt_descr)
    ) into lx_data
  from doc_record_cat_link_type
  where doc_record_cat_link_type_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'DOC_RECORD_CAT_LINK_TYPE') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('DOC_RECORD_CAT_LINK_TYPE', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('DOC_RECORD_CAT_LINK_TYPE', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;


function get_doc_record_cat_lnk_link(
  Id IN doc_record_category_link.doc_record_category_link_id%TYPE,
  FieldRef IN VARCHAR2 default 'DOC_RECORD_CATEGORY_LINK',
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
    XMLElement(DOC_RECORD_CATEGORY_LINK,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'C_RCO_LINK_TYPE, C_RCO_LINK_CODE, DOC_RECORD_CAT_FATHER_ID,'||
          'DOC_RECORD_CAT_DAUGHTER_ID, DOC_RECORD_CAT_LINK_TYPE_ID' as TABLE_KEY,
        doc_record_category_link_id),
      rep_pc_functions.get_descodes('C_RCO_LINK_TYPE', c_rco_link_type),
      rep_pc_functions.get_descodes('C_RCO_LINK_CODE', c_rco_link_code),
      rep_log_functions_link.get_rco_cat_inherit_link(doc_record_cat_father_id, 'DOC_RECORD_CAT_FATHER'),
      rep_log_functions_link.get_rco_cat_inherit_link(doc_record_cat_daughter_id, 'DOC_RECORD_CAT_DAUGHTER'),
      rep_log_functions_link.get_rco_cat_lnk_type_link(doc_record_cat_link_type_id)
    ) into lx_data
  from doc_record_category_link
  where doc_record_category_link_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'DOC_RECORD_CATEGORY_LINK') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('DOC_RECORD_CATEGORY_LINK', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('DOC_RECORD_CATEGORY_LINK', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_doc_record_inherit_link(
  Id IN doc_record.doc_record_id%TYPE,
  FieldRef IN VARCHAR2)
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
        'LINK' as TABLE_TYPE,
        'RCO_TITLE' as TABLE_KEY,
        'DOC_RECORD_ID='||FieldRef||'_ID' as TABLE_MAPPING,
        'DOC_RECORD' as TABLE_REFERENCE,
        doc_record_id as INHERIT_ID,
        rco_title)
    ) into lx_data
  from doc_record
  where doc_record_id = Id;

  if (lx_data is not null) then
    return rep_xml_function.transform_field_ref('INHERIT', FieldRef, lx_data);
  else
    return null;
  end if;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_rco_cat_inherit_link(
  Id IN doc_record_category.doc_record_category_id%TYPE,
  FieldRef IN VARCHAR2)
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
        'LINK' as TABLE_TYPE,
        'RCY_KEY' as TABLE_KEY,
        'DOC_RECORD_CATEGORY_ID='||FieldRef||'_ID' as TABLE_MAPPING,
        'DOC_RECORD_CATEGORY' as TABLE_REFERENCE,
        doc_record_category_id as INHERIT_ID,
        rcy_key)
    ) into lx_data
  from doc_record_category
  where doc_record_category_id = Id;

  if (lx_data is not null) then
    return rep_xml_function.transform_field_ref('INHERIT', FieldRef, lx_data);
  else
    return null;
  end if;

  exception
    when NO_DATA_FOUND then return null;
end;


--
-- CML  functions
--

function get_cml_document_link(
  Id IN cml_document.cml_document_id%TYPE,
  FieldRef IN VARCHAR2 default 'CML_DOCUMENT',
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
    XMLElement(CML_DOCUMENT,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'CCO_NUMBER' as TABLE_KEY,
        cml_document_id,
        cco_number)
    ) into lx_data
  from cml_document
  where cml_document_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'CML_DOCUMENT') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('CML_DOCUMENT', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('CML_DOCUMENT', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_cml_position_link(
  Id IN cml_position.cml_position_id%TYPE,
  FieldRef IN VARCHAR2 default 'CML_POSITION',
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
    XMLElement(CML_POSITION,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'CML_DOCUMENT_ID,CPO_SEQUENCE' as TABLE_KEY,
        cml_position_id),
      rep_log_functions_link.get_cml_document_link(cml_document_id),
      XMLForest(
        cpo_sequence)
    ) into lx_data
  from cml_position
  where cml_position_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'CML_POSITION') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('CML_POSITION', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('CML_POSITION', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_cml_events_link(
  Id IN cml_events.cml_events_id%TYPE,
  FieldRef IN VARCHAR2 default 'CML_EVENTS',
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
    XMLElement(CML_EVENTS,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'CML_POSITION_ID,CEV_SEQUENCE' as TABLE_KEY,
        cml_events_id),
      rep_log_functions_link.get_cml_position_link(cml_position_id),
      XMLForest(
        cev_sequence)
    ) into lx_data
  from cml_events
  where cml_events_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'CML_EVENTS') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('CML_EVENTS', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('CML_EVENTS', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_sqm_axis_link(
  Id IN sqm_axis.sqm_axis_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(SQM_AXIS,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'SAX_DESCRIPTION' as TABLE_KEY,
        sqm_axis_id,
        sax_description)
    ) into lx_data
  from sqm_axis
  where sqm_axis_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

END REP_LOG_FUNCTIONS_LINK;
