--------------------------------------------------------
--  DDL for Package Body LTM_TRACK_LOG_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "LTM_TRACK_LOG_FUNCTIONS" 
/**
 * Package LTM_TRACK_LOG_FUNCTIONS
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
 * Spécialisation: Logistique (GCO, DOC)
 */
AS

function get_gco_good_xml(Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(GCO_GOOD,
      XMLAttributes(
        sys_context('userenv','current_schema') as "current_schema",
        sys_context('userenv','current_user') as "current_user",
        sys_context('userenv','terminal') as "terminal",
        sys_context('userenv','nls_date_format') as "nls_date_format"),
      ltm_xml_utils.genXML(CURSOR(
        select * from gco_good
        where gco_good_id = T.gco_good_id),
        ''),
      ltm_track_log_functions.get_gco_descriptions(id),
      ltm_track_log_functions.get_gco_good_attribute(id),
      ltm_track_log_functions.get_gco_service(id),
      ltm_track_log_functions.get_gco_pseudo_good(gco_good_id),
      ltm_track_log_functions.get_gco_product(gco_good_id),
      ltm_track_log_functions.get_gco_connected_goods(gco_good_id),
      ltm_track_log_functions.get_gco_characterizations(gco_good_id),
      ltm_track_log_functions.get_gco_free_code(gco_good_id),
      ltm_track_log_functions.get_gco_free_data(gco_good_id),
      ltm_track_log_functions.get_ptc_tariff(gco_good_id),
      ltm_track_pc_functions.get_com_image_files(gco_good_id,'GCO_GOOD'),
      ltm_track_pc_functions.get_com_vfields_record(gco_good_id,'GCO_GOOD'),
      ltm_track_pc_functions.get_com_vfields_value(gco_good_id,'GCO_GOOD'),
      ltm_track_log_functions.get_gco_compl_data_purchase(gco_good_id),
      ltm_track_log_functions.get_gco_compl_data_sale(gco_good_id),
      ltm_track_log_functions.get_gco_compl_data_stock(gco_good_id),
      ltm_track_log_functions.get_gco_compl_data_inventory(gco_good_id),
      ltm_track_log_functions.get_gco_compl_data_manufacture(gco_good_id),
      ltm_track_log_functions.get_gco_compl_data_ass(gco_good_id),
      ltm_track_log_functions.get_gco_compl_data_distrib(gco_good_id),
      ltm_track_log_functions.get_gco_vat_good(gco_good_id),
      ltm_track_log_functions.get_gco_imput_doc(gco_good_id),
      ltm_track_log_functions.get_gco_precious_mat(gco_good_id),
      ltm_track_log_functions.get_gco_compl_data_ext_asa(gco_good_id),
      ltm_track_log_functions.get_asa_counter_type_s_good(gco_good_id),
      ltm_track_log_functions.get_gco_coupled_good(gco_good_id),
      ltm_track_log_functions_link.get_gco_product_group_link(gco_product_group_id)
    ) into obj
  from gco_good T
  where gco_good_id = Id;
  return obj;

  exception
    when OTHERS then
      obj := COM_XmlErrorDetail(sqlerrm);
      select
        XMLElement(GCO_GOOD,
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

function get_gco_descriptions(Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(GCO_DESCRIPTION,
      ltm_xml_utils.genXML(CURSOR(
        select * from gco_description
        where gco_description_id = T.gco_description_id),
        ''),
      ltm_track_log_functions_link.get_gco_multimedia_link(gco_multimedia_element_id))
      order by a_datecre, pc_lang_id, c_description_type
    ) into obj
  from gco_description T
  where gco_good_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_good_attribute(Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select * from gco_good_attribute
      where gco_good_id = Id),
      'GCO_GOOD_ATTRIBUTE')
    into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_service(Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select * from gco_service
      where gco_good_id = Id),
      'GCO_SERVICE')
    into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_pseudo_good(Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select * from gco_pseudo_good
      where gco_good_id = Id),
      'GCO_PSEUDO_GOOD')
    into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_product(Id in gco_good.gco_good_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(GCO_PRODUCT,
      ltm_xml_utils.genXML(CURSOR(
        select * from gco_product
        where gco_good_id = T.gco_good_id),
        ''),
      ltm_track_log_functions_link.get_gco_dangerous_transp_link(gco_dangerous_transp_adr_id,'GCO_DANGEROUS_TRANSP_ADR'),
      ltm_track_log_functions_link.get_gco_dangerous_transp_link(gco_dangerous_transp_iata_id,'GCO_DANGEROUS_TRANSP_IATA'),
      ltm_track_log_functions_link.get_gco_dangerous_transp_link(gco_dangerous_transp_imdg_id,'GCO_DANGEROUS_TRANSP_IMDG'),
      ltm_track_pac_functions_link.get_pac_supplier_partner_link(pac_supplier_partner_id),
      ltm_track_log_functions_link.get_stm_stock_link(stm_stock_id),
      ltm_track_log_functions_link.get_stm_location_link(stm_location_id)
    ) into obj
  from gco_product T
  where gco_good_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_connected_goods(Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(GCO_CONNECTED_GOOD,
      ltm_xml_utils.genXML(CURSOR(
        select * from gco_connected_good
        where gco_connected_good_id = T.gco_connected_good_id),
        ''),
      ltm_track_log_functions_link.get_gco_good_link(gco_gco_good_id,'GCO_GCO_GOOD'))
      order by a_datecre, dic_connected_type_id
    ) into obj
  from gco_connected_good T
  where gco_good_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_characterizations(Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(GCO_CHARACTERIZATION,
      ltm_xml_utils.genXML(CURSOR(
        select * from gco_characterization
        where gco_characterization_id = T.gco_characterization_id),
        ''),
      ltm_track_log_functions.get_gco_characteristic_element(gco_characterization_id),
      ltm_track_log_functions.get_gco_desc_language(gco_characterization_id,2),
      ltm_track_log_functions_link.get_gco_quality_stat_flow_link(gco_quality_stat_flow_id),
      ltm_track_log_functions_link.get_gco_quality_status_link(gco_quality_status_id))
      order by a_datecre, c_charact_type
    ) into obj
  from gco_characterization T
  where gco_good_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_characteristic_element(Id IN gco_characterization.gco_characterization_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(GCO_CHARACTERISTIC_ELEMENT,
      ltm_xml_utils.genXML(CURSOR(
        select * from gco_characteristic_element
        where gco_characteristic_element_id = T.gco_characteristic_element_id),
        ''),
      ltm_track_log_functions.get_gco_desc_language(gco_characteristic_element_id,1))
      order by a_datecre, che_value
    ) into obj
  from gco_characteristic_element T
  where gco_characterization_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_desc_language(Id IN number, TableSource IN INTEGER)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  case TableSource
    when 1 then
      select
        XMLAgg(
          ltm_xml_utils.genXML(CURSOR(
            select * from gco_desc_language
            where gco_desc_language_id = T.gco_desc_language_id),
            'GCO_DESC_LANGUAGE')
          order by a_datecre, pc_lang_id, c_type_desc_lang
        ) into obj
      from gco_desc_language T
      where gco_characteristic_element_id = Id;
    when 2 then
      select
        XMLAgg(
          ltm_xml_utils.genXML(CURSOR(
            select * from gco_desc_language
            where gco_desc_language_id = T.gco_desc_language_id),
            'GCO_DESC_LANGUAGE')
          order by a_datecre, pc_lang_id, c_type_desc_lang
        ) into obj
      from gco_desc_language T
      where gco_characterization_id = Id;
  end case;
  return null;

  exception
    when OTHERS then return null;
end;

function get_gco_free_code(Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select * from gco_free_code
      where gco_good_id = Id),
      'GCO_FREE_CODE')
    into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_free_data(Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select * from gco_free_data
      where gco_good_id = Id),
      'GCO_FREE_DATA')
    into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_compl_data_purchase(Id in gco_good.gco_good_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(GCO_COMPL_DATA_PURCHASE,
      ltm_xml_utils.genXML(CURSOR(
        select * from gco_compl_data_purchase
        where gco_compl_data_purchase_id = T.gco_compl_data_purchase_id),
        ''),
      ltm_track_log_functions_link.get_stm_stock_link(stm_stock_id),
      ltm_track_log_functions_link.get_stm_location_link(stm_location_id),
      ltm_track_log_functions_link.get_gco_substitution_link(gco_substitution_list_id),
      ltm_track_log_functions_link.get_gco_quality_principle_link(gco_quality_principle_id),
      ltm_track_log_functions_link.get_gco_good_link(gco_gco_good_id,'GCO_GCO_GOOD'),
      ltm_track_pac_functions_link.get_pac_supplier_partner_link(pac_supplier_partner_id))
      order by a_datecre
    ) into obj
  from gco_compl_data_purchase T
  where gco_good_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_compl_data_sale(Id in gco_good.gco_good_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(GCO_COMPL_DATA_SALE,
      ltm_xml_utils.genXML(CURSOR(
        select * from gco_compl_data_sale
        where gco_compl_data_sale_id = T.gco_compl_data_sale_id),
        ''),
      ltm_track_log_functions_link.get_stm_stock_link(stm_stock_id),
      ltm_track_log_functions_link.get_stm_location_link(stm_location_id),
      ltm_track_log_functions_link.get_gco_substitution_link(gco_substitution_list_id),
      ltm_track_log_functions_link.get_gco_quality_principle_link(gco_quality_principle_id),
      ltm_track_log_functions.get_gco_packing_element(gco_compl_data_sale_id),
      ltm_track_pac_functions_link.get_pac_custom_partner_link(pac_custom_partner_id))
      order by a_datecre, pac_custom_partner_id, dic_complementary_data_id
    ) into obj
  from gco_compl_data_sale T
  where gco_good_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_packing_element(Id IN gco_compl_data_sale.gco_compl_data_sale_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(GCO_PACKING_ELEMENT,
      ltm_xml_utils.genXML(CURSOR(
        select * from gco_packing_element
        where gco_packing_element_id = T.gco_packing_element_id),
        ''),
      ltm_track_log_functions_link.get_gco_good_link(gco_good_id),
      ltm_track_log_functions_link.get_stm_location_link(stm_location_id),
      ltm_track_log_functions_link.get_stm_stock_link(stm_stock_id))
      order by a_datecre, gco_compl_data_sale_id
    ) into obj
  from gco_packing_element T
  where gco_compl_data_sale_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_compl_data_stock(Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(GCO_COMPL_DATA_STOCK,
      ltm_xml_utils.genXML(CURSOR(
        select * from gco_compl_data_stock
        where gco_compl_data_stock_id = T.gco_compl_data_stock_id),
        ''),
      ltm_track_log_functions_link.get_stm_stock_link(stm_stock_id),
      ltm_track_log_functions_link.get_stm_location_link(stm_location_id),
      ltm_track_log_functions_link.get_gco_substitution_link(gco_substitution_list_id),
      ltm_track_log_functions_link.get_gco_quality_principle_link(gco_quality_principle_id))
      order by a_datecre, dic_unit_of_measure_id, stm_stock_id
    ) into obj
  from gco_compl_data_stock T
  where gco_good_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_compl_data_inventory(Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(GCO_COMPL_DATA_INVENTORY,
      ltm_xml_utils.genXML(CURSOR(
        select * from gco_compl_data_inventory
        where gco_compl_data_inventory_id = T.gco_compl_data_inventory_id),
        ''),
      ltm_track_log_functions_link.get_stm_stock_link(stm_stock_id),
      ltm_track_log_functions_link.get_stm_location_link(stm_location_id),
      ltm_track_log_functions_link.get_gco_substitution_link(gco_substitution_list_id),
      ltm_track_log_functions_link.get_gco_quality_principle_link(gco_quality_principle_id))
      order by a_datecre, dic_unit_of_measure_id, stm_stock_id
    ) into obj
  from gco_compl_data_inventory T
  where gco_good_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_compl_data_manufacture(Id in gco_good.gco_good_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(GCO_COMPL_DATA_MANUFACTURE,
      ltm_xml_utils.genXML(CURSOR(
        select * from gco_compl_data_manufacture
        where gco_compl_data_manufacture_id = T.gco_compl_data_manufacture_id),
        ''),
      ltm_track_log_functions_link.get_stm_stock_link(stm_stock_id),
      ltm_track_log_functions_link.get_stm_location_link(stm_location_id),
      ltm_track_log_functions_link.get_gco_substitution_link(gco_substitution_list_id),
      ltm_track_log_functions_link.get_gco_quality_principle_link(gco_quality_principle_id),
      ltm_track_ind_functions_link.get_fal_schedule_plan_link(fal_schedule_plan_id),
      ltm_track_ind_functions_link.get_pps_nomenclature_link(pps_nomenclature_id),
      ltm_track_ind_functions_link.get_pps_range_link(pps_range_id))
      order by a_datecre, dic_unit_of_measure_id, stm_stock_id
    ) into obj
  from gco_compl_data_manufacture T
  where gco_good_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_compl_data_ass(Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(GCO_COMPL_DATA_ASS,
      ltm_xml_utils.genXML(CURSOR(
        select * from gco_compl_data_ass
        where gco_compl_data_ass_id = T.gco_compl_data_ass_id),
        ''),
      ltm_track_log_functions_link.get_gco_substitution_link(gco_substitution_list_id),
      ltm_track_log_functions_link.get_gco_quality_principle_link(gco_quality_principle_id),
      ltm_track_log_functions_link.get_stm_stock_link(stm_stock_id),
      ltm_track_log_functions_link.get_stm_location_link(stm_location_id),
      ltm_track_log_functions_link.get_asa_rep_type_link(asa_rep_type_id))
      order by a_datecre, dic_unit_of_measure_id, stm_stock_id
    ) into obj
  from gco_compl_data_ass T
  where gco_good_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_compl_data_distrib(Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(GCO_COMPL_DATA_DISTRIB,
      ltm_xml_utils.genXML(CURSOR(
        select * from gco_compl_data_distrib
        where gco_compl_data_distrib_id = T.gco_compl_data_distrib_id),
        ''),
      ltm_track_log_functions_link.get_stm_stock_link(stm_stock_id),
      ltm_track_log_functions_link.get_stm_location_link(stm_location_id),
      ltm_track_log_functions_link.get_gco_substitution_link(gco_substitution_list_id),
      ltm_track_log_functions_link.get_gco_quality_principle_link(gco_quality_principle_id),
      ltm_track_log_functions_link.get_gco_product_group_link(gco_product_group_id),
      ltm_track_log_functions_link.get_stm_distribution_unit_link(stm_distribution_unit_id))
      order by a_datecre, gco_product_group_id, stm_distribution_unit_id,
               dic_unit_of_measure_id, stm_stock_id
    ) into obj
  from gco_compl_data_distrib T
  where gco_good_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_vat_good (Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(GCO_VAT_GOOD,
      ltm_xml_utils.genXML(CURSOR(
        select * from gco_vat_good
        where gco_vat_good_id = T.gco_vat_good_id),
        ''))
      -- la fonction get_acs_vat_det_account_link génère un appel de fonction
      --rep_fin_functions_link.get_acs_vat_det_account_link(acs_vat_det_account_id)
      order by a_datecre, acs_vat_det_account_id
    ) into obj
  from gco_vat_good T
  where gco_good_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_imput_doc(Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(GCO_IMPUT_DOC,
      ltm_xml_utils.genXML(CURSOR(
        select * from gco_imput_doc
        where gco_imput_doc_id = T.gco_imput_doc_id),
        ''),
      ltm_track_fin_functions_link.get_acs_account_link(acs_financial_account_id,'ACS_FINANCIAL_ACCOUNT'),
      ltm_track_fin_functions_link.get_acs_account_link(acs_division_account_id,'ACS_DIVISION_ACCOUNT'),
      ltm_track_fin_functions_link.get_acs_account_link(acs_cda_account_id,'ACS_CDA_ACCOUNT'),
      ltm_track_fin_functions_link.get_acs_account_link(acs_cpn_account_id,'ACS_CPN_ACCOUNT'),
      ltm_track_fin_functions_link.get_acs_account_link(acs_pf_account_id,'ACS_PF_ACCOUNT'),
      ltm_track_fin_functions_link.get_acs_account_link(acs_pj_account_id,'ACS_PJ_ACCOUNT'))
      order by a_datecre, c_admin_domain
    ) into obj
  from gco_imput_doc T
  where gco_good_id = Id;
  return obj;

  exception
  when OTHERS then return null;
end;

function get_gco_precious_mat(Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(GCO_PRECIOUS_MAT,
      ltm_xml_utils.genXML(CURSOR(
        select * from gco_precious_mat
        where gco_precious_mat_id = T.gco_precious_mat_id),
        ''),
      ltm_track_log_functions_link.get_gco_alloy_link(gco_alloy_id))
      order by a_datecre, gco_alloy_id
    ) into obj
  from gco_precious_mat T
  where gco_good_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;


function get_gco_compl_data_ext_asa(Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(GCO_COMPL_DATA_EXTERNAL_ASA,
      ltm_xml_utils.genXML(CURSOR(
        select * from gco_compl_data_external_asa
        where gco_compl_data_external_asa_id = T.gco_compl_data_external_asa_id),
        ''),
      ltm_track_log_functions.get_gco_service_plan(gco_compl_data_external_asa_id),
      ltm_track_log_functions.get_gco_comp_asa_ext_s_hrm_job(gco_compl_data_external_asa_id),
      ltm_track_log_functions_link.get_doc_record_category_link(doc_record_category_id),
      ltm_track_pc_functions_link.get_pc_appltxt_link(cea_new_pc_appltxt_id),
      ltm_track_pc_functions_link.get_pc_appltxt_link(cea_old_pc_appltxt_id),
      ltm_track_log_functions_link.get_stm_stock_link(stm_stock_id),
      ltm_track_log_functions_link.get_stm_location_link(stm_location_id),
      ltm_track_log_functions_link.get_gco_substitution_link(gco_substitution_list_id),
      ltm_track_log_functions_link.get_gco_quality_principle_link(gco_quality_principle_id))
      order by a_datecre
    ) into obj
  from gco_compl_data_external_asa T
  where gco_good_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;


function get_gco_service_plan(Id IN gco_compl_data_external_asa.gco_compl_data_external_asa_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(GCO_SERVICE_PLAN,
      ltm_xml_utils.genXML(CURSOR(
        select * from gco_service_plan
        where gco_service_plan_id = T.gco_service_plan_id),
        ''),
      ltm_track_log_functions_link.get_asa_count_type_s_good_link(asa_counter_type_s_good_id))
      order by a_datecre
    ) into obj
  from gco_service_plan T
  where gco_compl_data_external_asa_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;


function get_gco_comp_asa_ext_s_hrm_job(Id IN gco_compl_data_external_asa.gco_compl_data_external_asa_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(GCO_COMPL_ASA_EXT_S_HRM_JOB,
      ltm_xml_utils.genXML(CURSOR(
        select * from gco_compl_asa_ext_s_hrm_job
        where gco_compl_data_external_asa_id = T.gco_compl_data_external_asa_id
          and hrm_job_id = T.hrm_job_id),
        ''),
      ltm_track_hrm_functions_link.get_hrm_job_link(hrm_job_id))
      order by a_datecre
    ) into obj
  from gco_compl_asa_ext_s_hrm_job T
  where gco_compl_data_external_asa_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;


function get_gco_coupled_good(Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(GCO_COUPLED_GOOD,
      ltm_xml_utils.genXML(CURSOR(
        select * from gco_coupled_good
        where gco_coupled_good_id = T.gco_coupled_good_id),
        ''),
      ltm_track_log_functions_link.get_gco_good_link(gco_gco_good_id,'GCO_GCO_GOOD'),
      ltm_track_log_functions_link.get_gco_compl_data_manuf_link(gco_compl_data_manufacture_id))
      order by a_datecre
    ) into obj
  from gco_coupled_good T
  where gco_good_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_gco_quality_status_xml(Id IN gco_quality_status.gco_quality_status_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(GCO_QUALITY_STATUS,
      XMLAttributes(
        sys_context('userenv','current_schema') as "current_schema",
        sys_context('userenv','current_user') as "current_user",
        sys_context('userenv','terminal') as "terminal",
        sys_context('userenv','nls_date_format') as "nls_date_format"),
      ltm_xml_utils.genXML(CURSOR(
        select * from gco_quality_status
        where gco_quality_status_id = T.gco_quality_status_id),
        ''),
      ltm_track_log_functions.get_stm_non_allowed_mvts(T.gco_quality_status_id),
      ltm_track_log_functions.get_gco_quality_stat_descr(T.gco_quality_status_id),
      ltm_track_pc_functions.get_com_vfields_record(T.gco_quality_status_id,'GCO_QUALITY_STATUS'),
      ltm_track_pc_functions.get_com_vfields_value(T.gco_quality_status_id,'GCO_QUALITY_STATUS')
    ) into obj
  from gco_quality_status T
  where gco_quality_status_id = Id;
  return obj;

  exception
    when OTHERS then
      obj := COM_XmlErrorDetail(sqlerrm);
      select
        XMLElement(GCO_QUALITY_STATUS,
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
end get_gco_quality_status_xml;

function get_gco_quality_stat_flow_xml(Id IN gco_quality_status.gco_quality_status_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(GCO_QUALITY_STAT_FLOW,
      XMLAttributes(
        sys_context('userenv','current_schema') as "current_schema",
        sys_context('userenv','current_user') as "current_user",
        sys_context('userenv','terminal') as "terminal",
        sys_context('userenv','nls_date_format') as "nls_date_format"),
      ltm_xml_utils.genXML(CURSOR(
        select * from gco_quality_stat_flow
        where gco_quality_stat_flow_id = T.gco_quality_stat_flow_id),
        ''),
      ltm_track_log_functions_link.get_gco_quality_status_link(gco_quality_status_id),
      ltm_track_log_functions.get_gco_quality_stat_flow_det(gco_quality_stat_flow_id),
      ltm_track_pc_functions.get_com_vfields_record(T.gco_quality_stat_flow_id,'GCO_QUALITY_STAT_FLOW'),
      ltm_track_pc_functions.get_com_vfields_value(T.gco_quality_stat_flow_id,'GCO_QUALITY_STAT_FLOW')
    ) into obj
  from gco_quality_stat_flow T
  where gco_quality_stat_flow_id = Id;
  return obj;

  exception
    when OTHERS then
      obj := COM_XmlErrorDetail(sqlerrm);
      select
        XMLElement(GCO_QUALITY_STAT_FLOW,
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
end get_gco_quality_stat_flow_xml;

function get_gco_quality_stat_flow(Id IN gco_quality_stat_flow.gco_quality_status_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(GCO_QUALITY_STAT_FLOW,
      ltm_xml_utils.genXML(CURSOR(
        select * from gco_quality_stat_flow
        where gco_quality_stat_flow_id = T.gco_quality_stat_flow_id),
        ''),
      ltm_track_log_functions_link.get_gco_quality_status_link(gco_quality_status_id),
      ltm_track_log_functions.get_gco_quality_stat_flow_det(gco_quality_stat_flow_id))
      order by a_datecre, qsf_reference
    ) into obj
  from gco_quality_stat_flow T
  where gco_quality_status_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end get_gco_quality_stat_flow;

function get_gco_quality_stat_flow_det(Id IN gco_quality_stat_flow.gco_quality_stat_flow_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(GCO_QUALITY_STAT_FLOW_DET,
      ltm_xml_utils.genXML(CURSOR(
        select * from gco_quality_stat_flow_det
        where gco_quality_stat_flow_det_id = T.gco_quality_stat_flow_det_id),
        ''),
      ltm_track_log_functions_link.get_gco_quality_status_link(gco_quality_stat_from_id, 'GCO_QUALITY_STAT_FROM'),
      ltm_track_log_functions_link.get_gco_quality_status_link(gco_quality_stat_to_id, 'GCO_QUALITY_STAT_TO'))
      order by a_datecre
    ) into obj
  from gco_quality_stat_flow_det T
  where gco_quality_stat_flow_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end get_gco_quality_stat_flow_det;

function get_gco_quality_stat_descr(id in GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type)
  return xmltype
is
  obj xmltype;
begin
  if (id is null) then
    return null;
  end if;

  select XMLAgg(LTM_XML_UTILS.genXML(cursor(select *
                                              from GCO_QUALITY_STAT_DESCR
                                             where GCO_QUALITY_STAT_DESCR_ID = T.GCO_QUALITY_STAT_DESCR_ID), 'GCO_QUALITY_STAT_DESCR')
                                          order by T.A_DATECRE, T.PC_LANG_ID
               )
    into obj
    from GCO_QUALITY_STAT_DESCR T
   where GCO_QUALITY_STATUS_ID = id;

  return obj;
exception
  when others then
    return null;
end;

--
-- STM
--

function get_stm_element_number_xml(Id IN stm_element_number.stm_element_number_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(STM_ELEMENT_NUMBER,
      XMLAttributes(
        sys_context('userenv', 'current_schema') as "current_schema",
        sys_context('userenv', 'current_user') as "current_user",
        sys_context('userenv', 'terminal') as "terminal",
        sys_context('userenv', 'nls_date_format') as "nls_date_format"),
      ltm_xml_utils.genXML(CURSOR(
        select * from stm_element_number
        where stm_element_number_id = T.stm_element_number_id),
        ''),
      ltm_track_log_functions.get_stm_element_number_event(stm_element_number_id),
      ltm_track_log_functions_link.get_gco_good_link(gco_good_id),
      ltm_track_pac_functions_link.get_pac_supplier_partner_link(pac_supplier_partner_id),
      ltm_track_log_functions_link.get_gco_quality_status_link(gco_quality_status_id),
      ltm_track_pc_functions.get_com_vfields_record(T.stm_element_number_id,'STM_ELEMENT_NUMBER'),
      ltm_track_pc_functions.get_com_vfields_value(T.stm_element_number_id,'STM_ELEMENT_NUMBER')
    ) into obj
  from stm_element_number T
  where stm_element_number_id = Id;
  return obj;

  exception
    when OTHERS then
      obj := COM_XmlErrorDetail(sqlerrm);
      select
        XMLElement(STM_ELEMENT_NUMBER,
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
end get_stm_element_number_xml;

function get_stm_ele_number_event_xml(Id IN stm_element_number_event.stm_element_number_event_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(STM_ELEMENT_NUMBER_EVENT,
      XMLAttributes(
        sys_context('userenv', 'current_schema') as "current_schema",
        sys_context('userenv', 'current_user') as "current_user",
        sys_context('userenv', 'terminal') as "terminal",
        sys_context('userenv', 'nls_date_format') as "nls_date_format"),
      ltm_xml_utils.genXML(CURSOR(
        select * from stm_element_number_event
        where stm_element_number_event_id = T.stm_element_number_event_id),
        ''),
      ltm_track_log_functions_link.get_gco_quality_status_link(gco_quality_status_id),
      ltm_track_log_functions_link.get_stm_element_number_link(stm_element_number_id),
      ltm_track_log_functions_link.get_stm_stock_movement_link(stm_stock_movement_id),
      ltm_track_pc_functions.get_com_vfields_record(T.stm_element_number_event_id,'STM_ELEMENT_NUMBER_EVENT'),
      ltm_track_pc_functions.get_com_vfields_value(T.stm_element_number_event_id,'STM_ELEMENT_NUMBER_EVENT')
    ) into obj
  from stm_element_number_event T
  where stm_element_number_event_id = Id;
  return obj;

  exception
    when OTHERS then
      obj := COM_XmlErrorDetail(sqlerrm);
      select
        XMLElement(STM_ELEMENT_NUMBER_EVENT,
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
end get_stm_ele_number_event_xml;

function get_stm_element_number_event(Id IN stm_element_number.stm_element_number_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(STM_ELEMENT_NUMBER_EVENT,
      ltm_xml_utils.genXML(CURSOR(
        select * from stm_element_number_event
        where stm_element_number_event_id = T.stm_element_number_event_id),
        ''),
      ltm_track_log_functions_link.get_gco_quality_status_link(gco_quality_status_id),
      ltm_track_log_functions_link.get_stm_stock_movement_link(stm_stock_movement_id))
      order by a_datecre
    ) into obj
  from stm_element_number_event T
  where stm_element_number_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end get_stm_element_number_event;

function get_stm_location_xml(Id IN stm_location.stm_location_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(STM_LOCATION,
      XMLAttributes(
        sys_context('userenv', 'current_schema') as "current_schema",
        sys_context('userenv', 'current_user') as "current_user",
        sys_context('userenv', 'terminal') as "terminal",
        sys_context('userenv', 'nls_date_format') as "nls_date_format"),
      ltm_xml_utils.genXML(CURSOR(
        select * from stm_location
        where stm_location_id = T.stm_location_id),
        ''),
      ltm_track_log_functions_link.get_stm_stock_link(stm_stock_id),
      ltm_track_fin_functions_link.get_acs_account_link(acs_financial_account_id, 'ACS_FINANCIAL_ACCOUNT'),
      ltm_track_fin_functions_link.get_acs_account_link(acs_division_account_id, 'ACS_DIVISION_ACCOUNT'),
      ltm_track_pc_functions.get_com_vfields_record(T.stm_location_id,'STM_LOCATION'),
      ltm_track_pc_functions.get_com_vfields_value(T.stm_location_id,'STM_LOCATION')
    ) into obj
  from stm_location T
  where stm_location_id = Id;
  return obj;

  exception
    when OTHERS then
      obj := COM_XmlErrorDetail(sqlerrm);
      select
        XMLElement(STM_LOCATION,
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
end get_stm_location_xml;

function get_stm_non_allowed_mvts(Id IN gco_quality_status.gco_quality_status_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(STM_NON_ALLOWED_MOVEMENTS,
      ltm_xml_utils.genXML(CURSOR(
        select * from stm_non_allowed_movements
        where stm_non_allowed_movements_id = T.stm_non_allowed_movements_id),
        ''),
      ltm_track_log_functions_link.get_stm_stock_link(stm_stock_id),
      ltm_track_log_functions_link.get_stm_movement_kind_link(stm_movement_kind_id),
      ltm_track_log_functions_link.get_gco_quality_status_link(gco_quality_status_id))
    ) into obj
  from stm_non_allowed_movements T
  where gco_quality_status_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end get_stm_non_allowed_mvts;

function get_asa_counter_type_s_good(Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(ASA_COUNTER_TYPE_S_GOOD,
      ltm_xml_utils.genXML(CURSOR(
        select * from asa_counter_type_s_good
        where asa_counter_type_s_good_id = T.asa_counter_type_s_good_id),
        ''),
      ltm_track_log_functions_link.get_asa_counter_type_link(asa_counter_type_id),
      ltm_track_pc_functions_link.get_pc_appltxt_link(ctg_pc_appltxt_id))
      order by a_datecre
    ) into obj
  from asa_counter_type_s_good T
  where gco_good_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;


--
-- PTC
--

function get_ptc_tariff(Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(PTC_TARIFF,
      ltm_xml_utils.genXML(CURSOR(
        select * from ptc_tariff
        where ptc_tariff_id = T.ptc_tariff_id),
        ''),
      ltm_track_fin_functions_link.get_acs_fin_curr_link(acs_financial_currency_id),
      ltm_track_log_functions.get_ptc_tariff_table(ptc_tariff_id))
      order by a_datecre, dic_tariff_id, pac_third_id, trf_descr, acs_financial_currency_id,
               c_tariff_type, c_tariffication_mode, dic_pur_tariff_struct_id,
               dic_sale_tariff_struct_id, trf_starting_date, trf_ending_date
    ) into obj
  from ptc_tariff T
  where gco_good_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_ptc_tariff_table(Id IN ptc_tariff.ptc_tariff_id%TYPE)
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
        select * from ptc_tariff_table
        where ptc_tariff_table_id = T.ptc_tariff_table_id),
        'PTC_TARIFF_TABLE')
      order by a_datecre, tta_from_quantity, tta_to_quantity, tta_price
    ) into obj
  from ptc_tariff_table T
  where ptc_tariff_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;


--
-- DOC
--

function get_doc_record_xml(Id IN doc_record.doc_record_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(DOC_RECORD,
      XMLAttributes(
        sys_context('userenv', 'current_schema') as "current_schema",
        sys_context('userenv', 'current_user') as "current_user",
        sys_context('userenv', 'terminal') as "terminal",
        sys_context('userenv', 'nls_date_format') as "nls_date_format"),
      ltm_xml_utils.genXML(CURSOR(
        select * from doc_record
        where doc_record_id = T.doc_record_id),
        ''),
      ltm_track_pc_functions_link.get_pc_lang_link(pc_lang_id),
      ltm_track_pc_functions_link.get_pc_cntry_link(pc_cntry_id),
      ltm_track_pac_functions_link.get_pac_third_link(pac_third_id),
      ltm_track_pac_functions_link.get_pac_representative_link(pac_representative_id),
      ltm_track_log_functions_link.get_doc_record_category_link(doc_record_category_id),
      ltm_track_log_functions_link.get_stm_element_number_link(stm_element_number_id),
      ltm_track_pc_functions_link.get_pc_user_link(pc_user_id),
      ltm_track_gal_functions_link.get_gal_task_link(gal_task_id),
      ltm_track_gal_functions_link.get_gal_project_link(gal_project_id),
      ltm_track_gal_functions_link.get_gal_budget_link(gal_budget_id),
      ltm_track_gal_functions_link.get_gal_task_link_link(gal_task_link_id),
      ltm_track_log_functions_link.get_doc_position_link(doc_purchase_position_id, 'DOC_PURCHASE_POSITION'),
      ltm_track_fin_functions_link.get_acs_account_link(acs_financial_account_id, 'ACS_FINANCIAL_ACCOUNT'),
      ltm_track_fin_functions_link.get_acs_account_link(acs_division_account_id, 'ACS_DIVISION_ACCOUNT'),
      ltm_track_fin_functions_link.get_acs_account_link(acs_cpn_account_id, 'ACS_CPN_ACCOUNT'),
      ltm_track_fin_functions_link.get_acs_account_link(acs_cda_account_id, 'ACS_CDA_ACCOUNT'),
      ltm_track_fin_functions_link.get_acs_account_link(acs_pf_account_id, 'ACS_PF_ACCOUNT'),
      ltm_track_fin_functions_link.get_acs_account_link(acs_pj_account_id, 'ACS_PJ_ACCOUNT'),
      ltm_track_log_functions_link.get_gco_good_link(rco_machine_good_id, 'RCO_MACHINE_GOOD'),
      ltm_track_pc_functions_link.get_pc_appltxt_link(rco_warranty_pc_appltxt_id, 'RCO_WARRANTY_PC_APPLTXT'),
      ltm_track_log_functions.get_doc_record_address(doc_record_id),
      ltm_track_log_functions.get_doc_record_link(doc_record_id),
      ltm_track_log_functions.get_asa_installation_movement(doc_record_id),
      ltm_track_pc_functions.get_com_vfields_record(T.doc_record_id,'DOC_RECORD'),
      ltm_track_pc_functions.get_com_vfields_value(T.doc_record_id,'DOC_RECORD')
    ) into obj
  from doc_record T
  where doc_record_id = Id;
  return obj;

  exception
    when OTHERS then
      obj := COM_XmlErrorDetail(sqlerrm);
      select
        XMLElement(DOC_RECORD,
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

function get_doc_record_address(Id IN doc_record.doc_record_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(DOC_RECORD_ADDRESS,
      ltm_xml_utils.genXML(CURSOR(
        select * from doc_record_address
        where doc_record_address_id = T.doc_record_address_id),
        ''),
      ltm_track_pac_functions_link.get_pac_person_link(pac_person_id))
      order by a_datecre
    ) into obj
  from doc_record_address T
  where doc_record_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_doc_record_link(Id IN doc_record.doc_record_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(DOC_RECORD_LINK,
      ltm_xml_utils.genXML(CURSOR(
        select * from doc_record_link
        where doc_record_link_id = T.doc_record_link_id),
        ''),
      ltm_track_log_functions_link.get_doc_record_cat_lnk_link(doc_record_category_link_id),
      ltm_track_log_functions_link.get_doc_record_link(doc_record_son_id, 'DOC_RECORD_SON'))
      order by a_datecre
    ) into obj
  from doc_record_link T
  where doc_record_father_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_asa_installation_movement(Id IN doc_record.doc_record_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(ASA_INSTALLATION_MOVEMENT,
      ltm_xml_utils.genXML(CURSOR(
        select * from asa_installation_movement
        where asa_installation_movement_id = T.asa_installation_movement_id),
        ''),
      ltm_track_pac_functions_link.get_pac_custom_partner_link(pac_custom_partner_id),
      ltm_track_pac_functions_link.get_pac_department_link(pac_department_id),
      ltm_track_pac_functions_link.get_pac_address_link(pac_address_id),
      ltm_track_pc_functions_link.get_pc_appltxt_link(pc_appltxt_id),
      ltm_track_log_functions_link.get_asa_mission_link(asa_mission_id))
      order by a_datecre
    ) into obj
  from asa_installation_movement T
  where doc_record_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;


function get_doc_gauge_flow_xml(Id IN doc_gauge_flow.doc_gauge_flow_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(DOC_GAUGE_FLOW,
      XMLAttributes(
        sys_context('userenv', 'current_schema') as "current_schema",
        sys_context('userenv', 'current_user') as "current_user",
        sys_context('userenv', 'terminal') as "terminal",
        sys_context('userenv', 'nls_date_format') as "nls_date_format"),
      ltm_xml_utils.genXML(CURSOR(
        select * from doc_gauge_flow
        where doc_gauge_flow_id = T.doc_gauge_flow_id),
        ''),
      ltm_track_pac_functions_link.get_pac_third_link(pac_third_id),
      ltm_track_log_functions_link.get_gco_good_link(gco_good_id),
      ltm_track_log_functions.get_doc_gauge_flow_docum(doc_gauge_flow_id),
      ltm_track_pc_functions.get_com_vfields_record(T.doc_gauge_flow_id,'DOC_GAUGE_FLOW'),
      ltm_track_pc_functions.get_com_vfields_value(T.doc_gauge_flow_id,'DOC_GAUGE_FLOW')
    ) into obj
  from doc_gauge_flow T
  where doc_gauge_flow_id = Id;
  return obj;

  exception
    when OTHERS then
      obj := COM_XmlErrorDetail(sqlerrm);
      select
        XMLElement(DOC_GAUGE_FLOW,
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

function get_doc_gauge_flow_docum(Id IN doc_gauge_flow_docum.doc_gauge_flow_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(DOC_GAUGE_FLOW_DOCUM,
      ltm_xml_utils.genXML(CURSOR(
        select * from doc_gauge_flow_docum
        where doc_gauge_flow_id = T.doc_gauge_flow_id),
        ''),
      ltm_track_log_functions_link.get_doc_gauge_link(doc_gauge_id),
      ltm_track_log_functions.get_doc_gauge_receipt(doc_gauge_flow_docum_id),
      ltm_track_log_functions.get_doc_gauge_copy(doc_gauge_flow_docum_id))
      order by a_datecre
    ) into obj
  from doc_gauge_flow_docum T
  where doc_gauge_flow_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_doc_gauge_receipt(Id IN doc_gauge_receipt.doc_gauge_flow_docum_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(DOC_GAUGE_RECEIPT,
      ltm_xml_utils.genXML(CURSOR(
        select * from doc_gauge_receipt
        where doc_gauge_flow_docum_id = T.doc_gauge_flow_docum_id),
        ''),
      ltm_track_log_functions_link.get_doc_gauge_link(doc_doc_gauge_id, 'DOC_DOC_GAUGE'))
      order by a_datecre
    ) into obj
  from doc_gauge_receipt T
  where doc_gauge_flow_docum_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_doc_gauge_copy(Id IN doc_gauge_copy.doc_gauge_flow_docum_id%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(DOC_GAUGE_COPY,
      ltm_xml_utils.genXML(CURSOR(
        select * from doc_gauge_copy
        where doc_gauge_flow_docum_id = T.doc_gauge_flow_docum_id),
        ''),
      ltm_track_log_functions_link.get_doc_gauge_link(doc_doc_gauge_id, 'DOC_DOC_GAUGE'))
      order by a_datecre
    ) into obj
  from doc_gauge_copy T
  where doc_gauge_flow_docum_id = Id;
  return obj;


  exception
    when OTHERS then return null;
end;

END LTM_TRACK_LOG_FUNCTIONS;
