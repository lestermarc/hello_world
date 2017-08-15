--------------------------------------------------------
--  DDL for Package Body REP_LOG_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_LOG_FUNCTIONS" 
/**
 * Fonctions de génération de document Xml.
 * Spécialisation: Logistique, tarifs et stockage (GCO,PTC,STM)
 *
 * @version 1.0
 * @date 02/2003
 * @author jsomers
 * @author spfister
 * @author fperotto
 * @author pvogel
 * @author ngomes
 * @author agentet
 *
 * Copyright 1997-2013 SolvAxis SA. Tous droits réservés.
 */
AS

--
-- GCO  functions
--

function get_gco_good_attribute(
  Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  cursor csFields(
    TableName IN VARCHAR2)
  is
    select
      case
        when is_date = 1 then 'to_char('||column_name||') as '||column_name
        when is_descode = 1 then 'rep_pc_functions.get_descodes_customer('''|| (select nvl(FLDCCODE, FLDCODE) from PCS.PC_FLDSC where FLDNAME = column_name and PC_OBJECT_ID is null) ||''', '||column_name||', '''||column_name||''')'
        when is_dictionary = 1 then 'rep_pc_functions.get_dictionary('''||Substr(column_name,1,Length(column_name)-3)||''','||column_name||')'
        else column_name
      end column_name,
      case
        when is_descode = 1 then 1
        when is_dictionary = 1 then 2
        else 0
      end order_field
    from (
      select
        column_name,
        case when Substr(column_name,1,2) != 'A_' then 0 else 1 end is_afield,
        case when data_type != 'DATE' then 0 else 1 end is_date,
        case when Substr(column_name,4,10) != '_DESCODES_' then 0 else 1 end is_descode,
        case when Substr(column_name,8,16) != '_ATTRIBUTE_FREE_' then 0 else 1 end is_dictionary
      from sys.user_tab_columns
      where table_name = TableName) a
    where is_afield = 0
    order by order_field;
  lx_data XMLType;
  lv_cmd VARCHAR2(32767);
  prevField BOOLEAN := FALSE;
begin
  if (Id is null) then
    return null;
  end if;

  -- Boucle sur le curseur pour générer la commandes de chaque champ de la table
  for tplFields in csFields('GCO_GOOD_ATTRIBUTE') loop
    case tplFields.order_field
      when 0 then
        lv_cmd := lv_cmd||
          ','||case when not prevField then 'XMLForest(' end||
          tplFields.column_name;
        prevField := TRUE;
      else
        lv_cmd := lv_cmd||
          case when prevField then ')' end||','||
          tplFields.column_name;
        prevField := FALSE;
    end case;
  end loop;
  -- Ajout de la fermeture de parenthèse si le dernier champ est contenu dans un XMLForest
  if (prevField) then
    lv_cmd := lv_cmd||')';
  end if;

  -- Exécution dynamique de la commande pour la liste des champs
  EXECUTE IMMEDIATE
    'select XMLConcat('|| LTrim(lv_cmd,',') ||')
     from gco_good_attribute
     where gco_good_id = :Id'
    INTO lx_data
    USING Id;

  -- Génération du fragment complet
  if (lx_data is not null) then
    select
      XMLElement(GCO_GOOD_ATTRIBUTE,
        XMLForest(
          'AFTER' as TABLE_TYPE,
          'GCO_GOOD_ID' as TABLE_KEY),
        lx_data
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_attribute_fields_xml(
  Id IN gco_good_category.gco_good_category_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(GCO_ATTRIBUTE_FIELDS,
      XMLAttributes(
        f.gco_attribute_fields_id as ID,
        pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
      XMLComment(rep_utils.GetCreationContext),
      XMLForest(
        'MAIN' as TABLE_TYPE,
        'DIC_TABSHEET_ATTRIBUTE_ID,PC_FLDSC_ID,ATF_SEQUENCE_NUMBER' as TABLE_KEY,
        --'DIC_TABSHEET_ATTRIBUTE' as TABLE_SUBSTITUTE,
        f.gco_attribute_fields_id),
      rep_pc_functions.get_dictionary('DIC_TABSHEET_ATTRIBUTE',f.dic_tabsheet_attribute_id),
      rep_pc_functions_link.get_pc_fldsc_link_descr(f.pc_fldsc_id),
      XMLForest(
        f.atf_mandatory,
        f.atf_alias,
        f.atf_active,
        f.atf_sequence_number)
    )) into lx_data
  from gco_attribute_fields f, gco_good_category c
  where c.gco_good_category_id = Id and
    -- Liaison avec les 20 champs du dictionnaire
    f.dic_tabsheet_attribute_id in
      (c.dic_tabsheet_attribute_1_id, c.dic_tabsheet_attribute_2_id,
       c.dic_tabsheet_attribute_3_id, c.dic_tabsheet_attribute_4_id,
       c.dic_tabsheet_attribute_5_id, c.dic_tabsheet_attribute_6_id,
       c.dic_tabsheet_attribute_7_id, c.dic_tabsheet_attribute_8_id,
       c.dic_tabsheet_attribute_9_id, c.dic_tabsheet_attribute_10_id,
       c.dic_tabsheet_attribute_11_id, c.dic_tabsheet_attribute_12_id,
       c.dic_tabsheet_attribute_13_id, c.dic_tabsheet_attribute_14_id,
       c.dic_tabsheet_attribute_15_id, c.dic_tabsheet_attribute_16_id,
       c.dic_tabsheet_attribute_17_id, c.dic_tabsheet_attribute_18_id,
       c.dic_tabsheet_attribute_19_id, c.dic_tabsheet_attribute_20_id);
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select XMLElement(ATTRIBUTE_FIELDS, lx_data)
    into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(ATTRIBUTE_FIELDS,
          XMLElement(GCO_ATTRIBUTE_FIELDS,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_dic_tabsheet_attribute(
  Id IN dic_tabsheet_attribute.dic_tabsheet_attribute_id%TYPE,
  DicName IN VARCHAR2)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null or DicName is null) then
    return null;
  end if;

  select
    XMLElement(DIC_TAB_SHEET,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'DIC_TABSHEET_ATTRIBUTE_ID' as TABLE_KEY),
      rep_pc_functions.get_dictionary('DIC_TABSHEET_ATTRIBUTE',Id)
    ) into lx_data
  from dual;

  if (lx_data is not null) then
    return rep_xml_function.transform_root_ref('DIC_TAB_SHEET', DicName, lx_data);
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_characterizations(
  Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_GOOD_ID,C_CHARACT_TYPE'||case when c_charact_type='2' then ',CHA_CHARACTERIZATION_DESIGN' end as TABLE_KEY,
        gco_characterization_id),
      rep_log_functions_link.get_gco_quality_stat_flow_link(gco_quality_stat_flow_id),
      rep_log_functions_link.get_gco_quality_status_link(gco_quality_status_id),
      rep_pc_functions.get_descodes('C_CHRONOLOGY_TYPE',c_chronology_type),
      rep_pc_functions.get_descodes('C_CHARACT_TYPE',c_charact_type),
      rep_pc_functions.get_descodes('C_UNIT_OF_TIME',c_unit_of_time),
      XMLForest(
        cha_characterization_design,
        cha_automatic_incrementation,
        cha_increment_ste,
        cha_last_used_increment,
        cha_lapsing_delay,
        cha_lapsing_marge,
        cha_minimum_value,
        cha_maximum_value,
        cha_number,
        cha_comment,
        cha_stock_management,
        cha_free_text_1, cha_free_text_2, cha_free_text_3, cha_free_text_4, cha_free_text_5,
        cha_prefixe,
        cha_quality_status_mgmt,
        cha_retest_delay,
        cha_retest_margin,
        cha_suffixe,
        cha_use_detail,
        cha_with_retest),
      rep_log_functions.get_gco_characteristic_element(gco_characterization_id),
      rep_log_functions.get_gco_desc_language(gco_characterization_id, rep_log_functions.DESC_CHARACTERIZATION)
    ) order by gco_characterization_id) into lx_data
  from gco_characterization
  where gco_good_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_CHARACTERIZATION,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_characteristic_element(
  Id IN gco_characterization.gco_characterization_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_CHARACTERIZATION_ID,CHE_VALUE' as TABLE_KEY,
        gco_characteristic_element_id,
        che_value,
        che_allocation,
        che_ean_code),
      rep_log_functions.get_gco_desc_language(gco_characteristic_element_id, rep_log_functions.DESC_CHARACTERISTIC_ELEMENT)
    )) into lx_data
  from gco_characteristic_element
  where gco_characterization_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_CHARACTERISTIC_ELEMENT,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_desc_language(
  Id IN NUMBER,
  Source IN INTEGER)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  case Source
    when rep_log_functions.DESC_CHARACTERISTIC_ELEMENT then
      select
        XMLAgg(XMLElement(LIST_ITEM,
          XMLForest(
            'AFTER' as TABLE_TYPE,
            'GCO_CHARACTERISTIC_ELEMENT_ID,PC_LANG_ID,C_TYPE_DESC_LANG' as TABLE_KEY,
            gco_desc_language_id),
          rep_pc_functions.get_descodes('C_TYPE_DESC_LANG',c_type_desc_lang),
          XMLForest(
            b.lanid,
            a.dla_description)
        )) into lx_data
      from pcs.pc_lang b, gco_desc_language a
      where gco_characteristic_element_id = Id and b.pc_lang_id = a.pc_lang_id;
    when rep_log_functions.DESC_CHARACTERIZATION then
      select
        XMLAgg(XMLElement(LIST_ITEM,
          XMLForest(
            'AFTER' as TABLE_TYPE,
            'GCO_CHARACTERIZATION_ID,PC_LANG_ID,C_TYPE_DESC_LANG' as TABLE_KEY,
            gco_desc_language_id),
          rep_pc_functions.get_descodes('C_TYPE_DESC_LANG',c_type_desc_lang),
          XMLForest(
            b.lanid,
            a.dla_description)
        )) into lx_data
      from pcs.pc_lang b, gco_desc_language a
      where gco_characterization_id = Id and b.pc_lang_id = a.pc_lang_id;
  end case;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_DESC_LANGUAGE,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_connected_goods(
  Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_GOOD_ID,GCO_GCO_GOOD_ID,DIC_CONNECTED_TYPE_ID' as TABLE_KEY,
        gco_connected_good_id),
      rep_log_functions_link.get_gco_good_link(gco_gco_good_id,'GCO_GCO_GOOD'),
      rep_pc_functions.get_dictionary('DIC_CONNECTED_TYPE', dic_connected_type_id),
      XMLForest(
        con_rem,
        con_util_coeff,
        con_default_selection)
    )) into lx_data
  from gco_connected_good
  where gco_good_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_CONNECTED_GOOD,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_coupled_goods(
  Id IN gco_compl_data_manufacture.gco_compl_data_manufacture_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_GOOD_ID,GCO_GCO_GOOD_ID,GCO_COMPL_DATA_MANUFACTURE_ID' as TABLE_KEY,
        gco_coupled_good_id),
      rep_log_functions_link.get_gco_good_link(gco_gco_good_id,'GCO_GCO_GOOD'),
      XMLForest(
        gcg_ref_quantity,
        gcg_quantity,
        gcg_include_good)
    )) into lx_data
  from gco_coupled_good
  where gco_compl_data_manufacture_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_COUPLED_GOOD,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_measurement_weights(
  Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_GOOD_ID,DIC_SHAPE_TYPE_ID' as TABLE_KEY,
        gco_measurement_weight_id),
      rep_pc_functions.get_dictionary('DIC_SHAPE_TYPE',dic_shape_type_id),
      XMLForest(
        mea_net_height,
        mea_net_length,
        mea_net_depth,
        mea_net_weight,
        mea_net_volume,
        mea_net_surface,
        mea_gross_height,
        mea_gross_length,
        mea_gross_depth,
        mea_gross_weight,
        mea_gross_volume,
        mea_gross_surface,
        mea_net_management),
        rep_pc_functions.get_com_vfields_record(gco_measurement_weight_id,'GCO_MEASUREMENT_WEIGHT'),
        rep_pc_functions.get_com_vfields_value(gco_measurement_weight_id,'GCO_MEASUREMENT_WEIGHT')
    )) into lx_data
  from gco_measurement_weight
  where gco_good_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_MEASUREMENT_WEIGHT,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_compl_data_ass(
  Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_GOOD_ID,ASA_REP_TYPE_ID' as TABLE_KEY,
        gco_compl_data_ass_id),
      rep_pc_functions.get_dictionary('DIC_UNIT_OF_MEASURE',dic_unit_of_measure_id),
      rep_log_functions_link.get_gco_substitution_link(gco_substitution_list_id),
      rep_log_functions_link.get_gco_quality_principle_link(gco_quality_principle_id),
      rep_log_functions_link.get_stm_stock_link(stm_stock_id),
      rep_log_functions_link.get_stm_location_link(stm_location_id),
      XMLForest(
        cda_complementary_reference,
        cda_secondary_reference,
        cda_complementary_ean_code,
        cda_short_description,
        cda_long_description,
        cda_free_description,
        cda_comment,
        cda_number_of_decimal,
        cda_conversion_factor,
        cas_with_guarantee,
        cas_guarantee_delay),
      rep_pc_functions.get_dictionary('DIC_COMPLEMENTARY_DATA',dic_complementary_data_id),
      XMLForest(
        cda_free_alpha_1, cda_free_alpha_2,
        cda_free_dec_1, cda_free_dec_2),
      rep_asa_functions_link.get_asa_rep_type_link(asa_rep_type_id),
      XMLForest(
        cas_default_repair),
      rep_pc_functions.get_descodes('C_ASA_GUARANTY_UNIT',c_asa_guaranty_unit),
      rep_pc_functions.get_dictionary('DIC_TARIFF',dic_tariff_id),
      XMLForest(
        cda_complementary_ucc14_code),
      rep_pc_functions.get_com_vfields_record(gco_compl_data_ass_id,'GCO_COMPL_DATA_ASS'),
      rep_pc_functions.get_com_vfields_value(gco_compl_data_ass_id,'GCO_COMPL_DATA_ASS')
    )) into lx_data
  from gco_compl_data_ass
  where gco_good_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_COMPL_DATA_ASS,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_compl_data_manufacture(
  Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_GOOD_ID,DIC_FAB_CONDITION_ID' as TABLE_KEY,
        gco_compl_data_manufacture_id),
      rep_pc_functions.get_descodes('C_QTY_SUPPLY_RULE',c_qty_supply_rule),
      rep_pc_functions.get_descodes('C_TIME_SUPPLY_RULE',c_time_supply_rule),
      rep_pc_functions.get_dictionary('DIC_UNIT_OF_MEASURE',dic_unit_of_measure_id),
      rep_log_functions_link.get_stm_stock_link(stm_stock_id),
      rep_log_functions_link.get_stm_location_link(stm_location_id),
      rep_log_functions_link.get_gco_substitution_link(gco_substitution_list_id),
      rep_log_functions_link.get_gco_quality_principle_link(gco_quality_principle_id),
      XMLForest(
        cda_complementary_reference,
        cda_secondary_reference,
        cda_complementary_ean_code,
        cda_short_description,
        cda_long_description,
        cda_free_description,
        cda_comment,
        cda_number_of_decimal,
        cda_conversion_factor,
        cma_automatic_generating_prop,
        cma_economical_quantity,
        cma_fixed_delay,
        cma_manufacturing_delay,
        cma_percent_trash,
        cma_fixed_quantity_trash,
        cma_percent_waste,
        cma_fixed_quantity_waste,
        cma_qty_reference_loss,
        cma_weigh,
        cma_weigh_mandatory),
      rep_ind_functions_link.get_fal_schedule_plan_link(fal_schedule_plan_id),
      xmlForest(
        cma_lot_quantity,
        cma_plan_number,
        cma_plan_version,
        cma_multimedia_plan),
      rep_ind_functions_link.get_pps_nomenclature_link(pps_nomenclature_id,'PPS_NOMENCLATURE'),
      rep_pc_functions.get_dictionary('DIC_FAB_CONDITION',dic_fab_condition_id),
      XMLForest(
        cma_default,
        cma_schedule_type),
      rep_pc_functions.get_dictionary('DIC_COMPLEMENTARY_DATA',dic_complementary_data_id),
      rep_ind_functions_link.get_pps_range_link(pps_range_id),
      XMLForest(
        cda_free_alpha_1, cda_free_alpha_2,
        cda_free_dec_1, cda_free_dec_2),
      rep_pc_functions.get_descodes('C_ECONOMIC_CODE',c_economic_code),
      XMLForest(
        cma_shift,
        cma_fix_delay,
        cma_auto_recept,
        cma_modulo_quantity,
        cda_complementary_ucc14_code,
        cma_security_delay),
      rep_log_functions.get_gco_coupled_goods(gco_compl_data_manufacture_id),
      rep_pc_functions.get_com_vfields_record(gco_compl_data_manufacture_id,'GCO_COMPL_DATA_MANUFACTURE'),
      rep_pc_functions.get_com_vfields_value(gco_compl_data_manufacture_id,'GCO_COMPL_DATA_MANUFACTURE')
    )) into lx_data
  from gco_compl_data_manufacture
  where gco_good_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_COMPL_DATA_MANUFACTURE,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_compl_data_purchase(
  Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_GOOD_ID,PAC_SUPPLIER_PARTNER_ID,CPU_DEFAULT_SUPPLIER,'||
          'DIC_COMPLEMENTARY_DATA_ID,GCO_GCO_GOOD_ID' as TABLE_KEY,
        gco_compl_data_purchase_id),
      rep_pc_functions.get_descodes('C_QTY_SUPPLY_RULE',c_qty_supply_rule),
      rep_pc_functions.get_descodes('C_TIME_SUPPLY_RULE',c_time_supply_rule),
      rep_pc_functions.get_dictionary('DIC_UNIT_OF_MEASURE',dic_unit_of_measure_id),
      rep_log_functions_link.get_stm_stock_link(stm_stock_id),
      rep_log_functions_link.get_stm_location_link(stm_location_id),
      rep_log_functions_link.get_gco_substitution_link(gco_substitution_list_id),
      rep_log_functions_link.get_gco_quality_principle_link(gco_quality_principle_id),
      XMLForest(
        cda_complementary_reference,
        cda_secondary_reference,
        cda_complementary_ean_code,
        cda_short_description,
        cda_long_description,
        cda_free_description,
        cda_comment,
        cda_number_of_decimal,
        cda_conversion_factor,
        cpu_automatic_generating_prop,
        cpu_supply_delay,
        cpu_economical_quantity,
        cpu_fixed_delay,
        cpu_supply_capacity,
        cpu_control_delay,
        cpu_percent_trash,
        cpu_fixed_quantity_trash,
        cpu_qty_reference_trash,
        cpu_default_supplier),
      rep_pc_functions.get_dictionary('DIC_COMPLEMENTARY_DATA',dic_complementary_data_id),
      XMLForest(
        cda_free_alpha_1, cda_free_alpha_2,
        cda_free_dec_1, cda_free_dec_2,
        cpu_security_delay),
      rep_pc_functions.get_descodes('C_ECONOMIC_CODE',c_economic_code),
      XMLForest(
        cpu_shift),
      rep_pc_functions.get_descodes('C_GAUGE_TYPE_POS',c_gauge_type_pos),
      XMLForest(
        cpu_gauge_type_pos_mandatory),
      rep_log_functions_link.get_gco_good_link(gco_gco_good_id,'GCO_GCO_GOOD'),
      XMLForest(
        cpu_modulo_quantity,
        cpu_precious_mat_value),
      rep_pac_functions_link.get_pac_supplier_partner_link(pac_supplier_partner_id),
      XMLForest(
        cda_complementary_ucc14_code,
        cpu_hibc_code,
        cpu_percent_sourcing,
        cpu_official_supplier,
        cpu_warranty_period),
      rep_pc_functions.get_descodes('C_ASA_GUARANTY_UNIT',c_asa_guaranty_unit),
      rep_pc_functions.get_com_vfields_record(gco_compl_data_purchase_id,'GCO_COMPL_DATA_PURCHASE'),
      rep_pc_functions.get_com_vfields_value(gco_compl_data_purchase_id,'GCO_COMPL_DATA_PURCHASE')
    )) into lx_data
  from gco_compl_data_purchase
  where gco_good_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_COMPL_DATA_PURCHASE,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_customs_elements(
  Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_GOOD_ID,PC_CNTRY_ID,C_CUSTOMS_ELEMENT_TYPE' as TABLE_KEY,
        gco_customs_element_id),
      rep_pc_functions_link.get_pc_cntry_link(pc_cntry_id),
      XMLForest(
        cus_custons_position,
        cus_transport_information),
      rep_pc_functions.get_dictionary('DIC_REPAYMENT_CODE',dic_repayment_code_id),
      rep_pc_functions.get_dictionary('DIC_SUBJUGATED_LICENCE',dic_subjugated_licence_id),
      XMLForest(
        cus_key_tariff,
        cus_licence_number,
        cus_rate_for_value),
      rep_pc_functions_link.get_pc_cntry_link(pc_origin_pc_cntry_id,'PC_ORIGIN_PC_CNTRY'),
      XMLForest(
        cus_conversion_factor),
      rep_pc_functions.get_dictionary('DIC_UNIT_OF_MEASURE',dic_unit_of_measure_id),
      rep_pc_functions.get_descodes('C_CUSTOMS_ELEMENT_TYPE',c_customs_element_type),
      XMLForest(
        cus_commission_rate,
        cus_charge_rate,
        cus_excise_rate),
      rep_pc_functions.get_com_vfields_record(gco_customs_element_id,'GCO_CUSTOMS_ELEMENT'),
      rep_pc_functions.get_com_vfields_value(gco_customs_element_id,'GCO_CUSTOMS_ELEMENT')
    )) into lx_data
  from gco_customs_element
  where gco_good_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_CUSTOMS_ELEMENT,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_materials(
  Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_GOOD_ID,DIC_MATERIAL_KIND_ID' as TABLE_KEY,
        gco_material_id),
      rep_pc_functions.get_dictionary('DIC_UNIT_OF_MEASURE',dic_unit_of_measure_id),
      XMLForest(
        mat_material_weight,
        mat_gem_number,
        mat_comment),
      rep_pc_functions.get_dictionary('DIC_MATERIAL_KIND',dic_material_kind_id),
      rep_pc_functions.get_com_vfields_record(gco_material_id,'GCO_MATERIAL'),
      rep_pc_functions.get_com_vfields_value(gco_material_id,'GCO_MATERIAL')
    )) into lx_data
  from gco_material
  where gco_good_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_MATERIAL,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_descriptions(
  Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_GOOD_ID,PC_LANG_ID,C_DESCRIPTION_TYPE' as TABLE_KEY,
        d.gco_description_id,
        l.lanid),
      rep_log_functions_link.get_gco_multimedia_link(d.gco_multimedia_element_id),
      rep_pc_functions.get_descodes('C_DESCRIPTION_TYPE',d.c_description_type),
      XMLForest(
        d.des_short_description,
        d.des_long_description,
        d.des_free_description)
    )) into lx_data
  from pcs.pc_lang l, gco_description d
  where d.gco_good_id = Id and l.pc_lang_id = d.pc_lang_id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_DESCRIPTION,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_vat_good(
  Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_GOOD_ID,ACS_VAT_DET_ACCOUNT_ID' as TABLE_KEY,
        gco_vat_good_id),
      rep_pc_functions.get_dictionary('DIC_TYPE_VAT_GOOD',dic_type_vat_good_id),
      rep_fin_functions_link.get_acs_vat_det_account_link(acs_vat_det_account_id)
    )) into lx_data
  from gco_vat_good
  where gco_good_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_VAT_GOOD,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_imput_doc(
  Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_GOOD_ID,C_ADMIN_DOMAIN' as TABLE_KEY,
        gco_imput_doc_id),
      rep_pc_functions.get_descodes('C_ADMIN_DOMAIN',c_admin_domain),
      rep_fin_functions_link.get_acs_account_link(acs_financial_account_id,'ACS_FINANCIAL_ACCOUNT'),
      rep_fin_functions_link.get_acs_account_link(acs_division_account_id,'ACS_DIVISION_ACCOUNT'),
      rep_fin_functions_link.get_acs_account_link(acs_cda_account_id,'ACS_CDA_ACCOUNT'),
      rep_fin_functions_link.get_acs_account_link(acs_cpn_account_id,'ACS_CPN_ACCOUNT'),
      rep_fin_functions_link.get_acs_account_link(acs_pf_account_id,'ACS_PF_ACCOUNT'),
      rep_fin_functions_link.get_acs_account_link(acs_pj_account_id,'ACS_PJ_ACCOUNT')
    )) into lx_data
  from gco_imput_doc
  where gco_good_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_IMPUT_DOC,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_free_code(
  Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_GOOD_ID,DIC_GCO_BOOLEAN_CODE_TYPE_ID,'||
          'DIC_GCO_CHAR_CODE_TYPE_ID,DIC_GCO_DATE_CODE_TYPE_ID,'||
          'DIC_GCO_NUMBER_CODE_TYPE_ID,DIC_GCO_MEMO_CODE_TYPE_ID,' ||
          'FCO_BOO_CODE,FCO_CHA_CODE,FCO_DAT_CODE,FCO_NUM_CODE,FCO_MEM_CODE' as TABLE_KEY,
        gco_free_code_id),
      rep_pc_functions.get_dictionary('DIC_GCO_BOOLEAN_CODE_TYPE',dic_gco_boolean_code_type_id),
      XMLForest(
        fco_boo_code),
      rep_pc_functions.get_dictionary('DIC_GCO_CHAR_CODE_TYPE',dic_gco_char_code_type_id),
      XMLForest(
        fco_cha_code),
      rep_pc_functions.get_dictionary('DIC_GCO_DATE_CODE_TYPE',dic_gco_date_code_type_id),
      XMLForest(
        to_char(fco_dat_code) as FCO_DAT_CODE),
      rep_pc_functions.get_dictionary('DIC_GCO_NUMBER_CODE_TYPE',dic_gco_number_code_type_id),
      XMLForest(
        fco_num_code),
      rep_pc_functions.get_dictionary('DIC_GCO_MEMO_CODE_TYPE',dic_gco_memo_code_type_id),
      XMLForest(
        fco_mem_code)
    )) into lx_data
  from gco_free_code
  where gco_good_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_FREE_CODE,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_packing_element(
  Id IN gco_compl_data_sale.gco_compl_data_sale_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_COMPL_DATA_SALE_ID,SHI_SEQ' as TABLE_KEY,
        gco_packing_element_id),
      XMLForest(
        shi_seq,
        shi_quota,
        shi_comment),
      rep_log_functions_link.get_gco_good_link(gco_good_id,'GCO_GOOD',1),
      rep_log_functions_link.get_stm_location_link(stm_location_id),
      rep_log_functions_link.get_stm_stock_link(stm_stock_id)
    )) into lx_data
  from gco_packing_element
  where gco_compl_data_sale_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_PACKING_ELEMENT,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_compl_data_sale(
  Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_GOOD_ID,PAC_CUSTOM_PARTNER_ID,DIC_COMPLEMENTARY_DATA_ID' as TABLE_KEY,
        gco_compl_data_sale_id),
      rep_pc_functions.get_dictionary('DIC_UNIT_OF_MEASURE',dic_unit_of_measure_id),
      rep_log_functions_link.get_stm_stock_link(stm_stock_id),
      rep_log_functions_link.get_stm_location_link(stm_location_id),
      rep_log_functions_link.get_gco_substitution_link(gco_substitution_list_id),
      rep_log_functions_link.get_gco_quality_principle_link(gco_quality_principle_id),
      rep_pc_functions.get_descodes('C_GAUGE_TYPE_POS',c_gauge_type_pos),
      XMLForest(
        cda_complementary_reference,
        cda_secondary_reference,
        cda_complementary_ean_code,
        cda_short_description,
        cda_long_description,
        cda_free_description,
        cda_comment,
        cda_number_of_decimal,
        cda_conversion_factor,
        csa_delivery_delay,
        csa_shipping_caution,
        csa_dispatching_delay,
        csa_qty_conditioning,
        csa_good_packed),
      rep_pc_functions.get_dictionary('DIC_COMPLEMENTARY_DATA',dic_complementary_data_id),
      XMLForest(
        cda_free_alpha_1, cda_free_alpha_2,
        cda_free_dec_1, cda_free_dec_2,
        csa_gauge_type_pos_mandatory,
        csa_stackable,
        csa_th_supply_delay),
      rep_pc_functions.get_dictionary('DIC_PACKING_TYPE',dic_packing_type_id),
      rep_log_functions.get_gco_packing_element(gco_compl_data_sale_id),
      rep_pac_functions_link.get_pac_custom_partner_link(pac_custom_partner_id),
      XMLForest(
        csa_scale_link,
        cda_complementary_ucc14_code,
        csa_hibc_code,
        csa_lapsing_marge),
      rep_pc_functions.get_com_vfields_record(gco_compl_data_sale_id,'GCO_COMPL_DATA_SALE'),
      rep_pc_functions.get_com_vfields_value(gco_compl_data_sale_id,'GCO_COMPL_DATA_SALE')
    )) into lx_data
  from gco_compl_data_sale
  where gco_good_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_COMPL_DATA_SALE,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_compl_data_stock(
  Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_GOOD_ID,STM_STOCK_ID' as TABLE_KEY,
        gco_compl_data_stock_id),
      rep_pc_functions.get_dictionary('DIC_UNIT_OF_MEASURE',dic_unit_of_measure_id),
      rep_log_functions_link.get_stm_stock_link(stm_stock_id),
      rep_log_functions_link.get_stm_location_link(stm_location_id),
      rep_log_functions_link.get_gco_substitution_link(gco_substitution_list_id),
      rep_log_functions_link.get_gco_quality_principle_link(gco_quality_principle_id),
      rep_pc_functions.get_dictionary('DIC_COMPLEMENTARY_DATA',dic_complementary_data_id),
      rep_pc_functions.get_dictionary('DIC_LUMINOSITY',DIC_LUMINOSITY_ID),
      rep_pc_functions.get_dictionary('DIC_RELATIVE_HUMIDITY',DIC_RELATIVE_HUMIDITY_ID),
      rep_pc_functions.get_dictionary('DIC_STORAGE_POSITION',DIC_STORAGE_POSITION_ID),
      rep_pc_functions.get_dictionary('DIC_TEMPERATURE',DIC_TEMPERATURE_ID),
      XMLForest(
        cda_comment,
        cda_complementary_ean_code,
        cda_complementary_reference,
        cda_complementary_ucc14_code,
        cda_conversion_factor,
        cda_free_alpha_1, cda_free_alpha_2,
        cda_free_dec_1, cda_free_dec_2,
        cda_free_description,
        cda_long_description,
        cda_number_of_decimal,
        cda_secondary_reference,
        cda_short_description,
        cst_check_storage_cond,
        cst_number_period,
        cst_obtaining_multiple,
        cst_period_value,
        cst_proprietor_stock,
        cst_quantity_max,
        cst_quantity_min,
        cst_quantity_obtaining_stock,
        cst_storing_caution,
        cst_transfert_delay,
        cst_trigger_point),
      rep_pc_functions.get_com_vfields_record(gco_compl_data_stock_id,'GCO_COMPL_DATA_STOCK'),
      rep_pc_functions.get_com_vfields_value(gco_compl_data_stock_id,'GCO_COMPL_DATA_STOCK')
    )) into lx_data
  from gco_compl_data_stock
  where gco_good_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_COMPL_DATA_STOCK,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_compl_data_inventory(
  Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_GOOD_ID,STM_STOCK_ID' as TABLE_KEY,
        gco_compl_data_inventory_id),
      rep_pc_functions.get_dictionary('DIC_UNIT_OF_MEASURE',dic_unit_of_measure_id),
      rep_log_functions_link.get_stm_stock_link(stm_stock_id),
      rep_log_functions_link.get_stm_location_link(stm_location_id),
      rep_log_functions_link.get_gco_substitution_link(gco_substitution_list_id),
      rep_log_functions_link.get_gco_quality_principle_link(gco_quality_principle_id),
      XMLForest(
        cda_complementary_reference,
        cda_secondary_reference,
        cda_complementary_ean_code,
        cda_short_description,
        cda_long_description,
        cda_free_description,
        cda_comment,
        cda_number_of_decimal,
        cda_conversion_factor,
        cda_free_alpha_1, cda_free_alpha_2,
        cda_free_dec_1, cda_free_dec_2,
        cin_turning_inventory_delay),
      rep_pc_functions.get_dictionary('DIC_COMPLEMENTARY_DATA',dic_complementary_data_id),
      XMLForest(
        cda_complementary_ucc14_code),
      rep_pc_functions.get_com_vfields_record(gco_compl_data_inventory_id,'GCO_COMPL_DATA_INVENTORY'),
      rep_pc_functions.get_com_vfields_value(gco_compl_data_inventory_id,'GCO_COMPL_DATA_INVENTORY')
    )) into lx_data
  from gco_compl_data_inventory
  where gco_good_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_COMPL_DATA_INVENTORY,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_compl_data_distrib(
  Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' asTABLE_TYPE,
        'GCO_GOOD_ID,GCO_PRODUCT_GROUP_ID,'||
          'STM_DISTRIBUTION_UNIT_ID,DIC_DISTRIB_COMPL_DATA_ID' as TABLE_KEY,
        gco_compl_data_distrib_id),
      rep_pc_functions.get_dictionary('DIC_UNIT_OF_MEASURE',dic_unit_of_measure_id),
      rep_log_functions_link.get_stm_stock_link(stm_stock_id),
      rep_log_functions_link.get_stm_location_link(stm_location_id),
      rep_log_functions_link.get_gco_substitution_link(gco_substitution_list_id),
      rep_log_functions_link.get_gco_quality_principle_link(gco_quality_principle_id),
      rep_log_functions_link.get_gco_product_group_link(gco_product_group_id),
      rep_log_functions_link.get_stm_distribution_unit_link(stm_distribution_unit_id, 'STM_DISTRIBUTION_UNIT', 1),
      XMLForest(
        cda_complementary_reference,
        cda_secondary_reference,
        cda_complementary_ean_code,
        cda_short_description,
        cda_long_description,
        cda_free_description,
        cda_comment,
        cda_number_of_decimal,
        cda_conversion_factor,
        cda_free_alpha_1, cda_free_alpha_2,
        cda_free_dec_1, cda_free_dec_2,
        cdi_blocked_from,
        cdi_blocked_to,
        cdi_stock_min,
        cdi_stock_max,
        cdi_economical_quantity,
        cdi_priority_code,
        cdi_cover_percent),
      rep_pc_functions.get_dictionary('DIC_DISTRIB_COMPL_DATA',dic_distrib_compl_data_id),
      rep_pc_functions.get_dictionary('DIC_COMPLEMENTARY_DATA',dic_complementary_data_id),
      rep_pc_functions.get_descodes('C_DRP_USE_COVER_PERCENT',c_drp_use_cover_percent),
      rep_pc_functions.get_descodes('C_DRP_RELIQUAT',c_drp_reliquat),
      rep_pc_functions.get_descodes('C_DRP_QTY_RULE',c_drp_qty_rule),
      rep_pc_functions.get_descodes('C_DRP_DOC_MODE',c_drp_doc_mode),
      XMLForest(
        cda_complementary_ucc14_code),
      rep_pc_functions.get_com_vfields_record(gco_compl_data_distrib_id,'GCO_COMPL_DATA_DISTRIB'),
      rep_pc_functions.get_com_vfields_value(gco_compl_data_distrib_id,'GCO_COMPL_DATA_DISTRIB')
    )) into lx_data
  from gco_compl_data_distrib
  where gco_good_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_COMPL_DATA_DISTRIB,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_free_data(
  Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_GOOD_ID' as TABLE_KEY,
        gco_free_data_id),
      rep_pc_functions.get_dictionary('DIC_FREE_TABLE_1',dic_free_table_1_id),
      rep_pc_functions.get_dictionary('DIC_FREE_TABLE_2',dic_free_table_2_id),
      rep_pc_functions.get_dictionary('DIC_FREE_TABLE_3',dic_free_table_3_id),
      rep_pc_functions.get_dictionary('DIC_FREE_TABLE_4',dic_free_table_4_id),
      rep_pc_functions.get_dictionary('DIC_FREE_TABLE_5',dic_free_table_5_id),
      XMLForest(
        data_alpha_court_1, data_alpha_court_2, data_alpha_court_3,
          data_alpha_court_4, data_alpha_court_5,
        data_alpha_long_1, data_alpha_long_2, data_alpha_long_3,
          data_alpha_long_4, data_alpha_long_5,
        data_integer_1, data_integer_2, data_integer_3,
          data_integer_4, data_integer_5,
        data_boolean_1, data_boolean_2, data_boolean_3,
          data_boolean_4, data_boolean_5,
        data_dec_1, data_dec_2, data_dec_3, data_dec_4, data_dec_5,
        data_unit_price_sale)
    )) into lx_data
  from gco_free_data
  where gco_good_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_FREE_DATA,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_product(
  Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(GCO_PRODUCT,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_GOOD_ID' as TABLE_KEY),
      rep_log_functions_link.get_gco_good_link(gco_gco_service_id,'GCO_GCO_SERVICE'),
      rep_log_functions_link.get_gco_good_link(gco2_gco_good_id,'GCO2_GCO_GOOD',1),
      rep_pc_functions.get_descodes('C_PRODUCT_TYPE',c_product_type),
      rep_pc_functions.get_descodes('C_SUPPLY_MODE',c_supply_mode),
      rep_pc_functions.get_descodes('C_PRODUCT_DELIVERY_TYP',c_product_delivery_typ),
      rep_log_functions_link.get_gco_dangerous_transp_link(gco_dangerous_transp_adr_id,'GCO_DANGEROUS_TRANSP_ADR'),
      rep_log_functions_link.get_gco_dangerous_transp_link(gco_dangerous_transp_iata_id,'GCO_DANGEROUS_TRANSP_IATA'),
      rep_log_functions_link.get_gco_dangerous_transp_link(gco_dangerous_transp_imdg_id,'GCO_DANGEROUS_TRANSP_IMDG'),
      rep_pc_functions.get_dictionary('DIC_UNIT_OF_MEASURE',dic_unit_of_measure_id),
      rep_pc_functions.get_dictionary('DIC_UNIT_OF_MEASURE1',dic_unit_of_measure1_id, 'DIC_UNIT_OF_MEASURE'),
      rep_pc_functions.get_dictionary('DIC_UNIT_OF_MEASURE2',dic_unit_of_measure2_id, 'DIC_UNIT_OF_MEASURE'),
      rep_pc_functions.get_dictionary('DIC_DEL_TYP_EXPLAIN',dic_del_typ_explain_id),
      XMLForest(
        pdt_stock_management,
        pdt_threshold_management,
        pdt_stock_obtain_management,
        pdt_calc_requirement_mngment,
        pdt_continuous_inventar,
        pdt_full_tracability,
        pdt_alternative_quantity_1, pdt_alternative_quantity_2, pdt_alternative_quantity_3,
        pdt_conversion_factor_1, pdt_conversion_factor_2, pdt_conversion_factor_3,
        pdt_pic,
        pdt_fact_stock,
        pdt_block_equi,
        pdt_guaranty_use,
        pdt_end_life,
        pdt_mark_nomenclature,
        pdt_mark_used,
        pdt_stock_alloc_batch,
        pdt_scale_link,
        pdt_full_tracability_coef,
        pdt_full_tracability_supply,
        pdt_full_tracability_rule,
        pdt_multi_sourcing,
        pdt_version_management),
      rep_pc_functions.get_descodes('C_SUPPLY_TYPE',c_supply_type),
      rep_pac_functions_link.get_pac_supplier_partner_link(pac_supplier_partner_id),
      rep_log_functions_link.get_stm_stock_link(stm_stock_id),
      rep_log_functions_link.get_stm_location_link(stm_location_id),
      rep_pc_functions.get_com_vfields_record(gco_good_id,'GCO_PRODUCT'),
      rep_pc_functions.get_com_vfields_value(gco_good_id,'GCO_PRODUCT')
    ) into lx_data
  from gco_product
  where gco_good_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_service(
  Id IN gco_service.gco_good_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(GCO_SERVICE,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_GOOD_ID' as TABLE_KEY),
      rep_pc_functions.get_com_vfields_record(gco_good_id,'GCO_SERVICE'),
      rep_pc_functions.get_com_vfields_value(gco_good_id,'GCO_SERVICE')
    ) into lx_data
  from gco_service
  where gco_good_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_pseudo_good(
  Id IN gco_pseudo_good.gco_good_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(GCO_PSEUDO_GOOD,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_GOOD_ID' as TABLE_KEY),
      rep_pc_functions.get_com_vfields_record(gco_good_id,'GCO_PSEUDO_GOOD'),
      rep_pc_functions.get_com_vfields_value(gco_good_id,'GCO_PSEUDO_GOOD')
    ) into lx_data
  from gco_pseudo_good
  where gco_good_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_reference_template(
  Id IN gco_reference_template.gco_reference_template_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(GCO_REFERENCE_TEMPLATE,
      XMLForest(
        'BEFORE' as TABLE_TYPE,
        'RTE_DESIGNATION' as TABLE_KEY,
        gco_reference_template_id,
        rte_designation,
        rte_description,
        rte_format)
    ) into lx_data
  from gco_reference_template
  where gco_reference_template_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_transfer_substs(
  Id IN gco_transfer_list.gco_transfer_list_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_TRANSFER_LIST_ID,XSU_ORIGINAL' as TABLE_KEY,
        gco_transfer_subst_id,
        xsu_original,
        xsu_replacement,
        xsu_is_default_value)
    )) into lx_data
  from gco_transfer_subst
  where gco_transfer_list_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_TRANSFER_SUBST,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_transfer_lists(
  Id IN gco_good_category.gco_good_category_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_GOOD_CATEGORY_ID,C_TRANSFER_TYPE,XLI_TABLE_NAME,'||
          'XLI_FIELD_NAME' TABLE_KEY,
        gco_transfer_list_id),
      rep_pc_functions.get_descodes('C_TRANSFER_TYPE', c_transfer_type),
      XMLForest(
        xli_table_name,
        xli_field_name,
        xli_field_contents,
        xli_field_type),
      rep_pc_functions.get_descodes('C_DEFAULT_REPL', c_default_repl),
      rep_pc_functions_link.get_pc_fldsc_link(pc_fldsc_id),
      rep_pc_functions_link.get_pc_table_link(pc_table_id),
      XMLForest(
        xli_field_length,
        xli_number_of_decimals,
        xli_substitution,
        xli_required),
      rep_log_functions.get_gco_transfer_substs(gco_transfer_list_id)
    )) into lx_data
  from gco_transfer_list
  where gco_good_category_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_TRANSFER_LIST,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_alloy_component(
  Id IN gco_alloy.gco_alloy_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_ALLOY_ID,DIC_BASIS_MATERIAL_ID' as TABLE_KEY,
        gco_alloy_component_id,
        gac_rate),
      rep_pc_functions.get_dictionary('DIC_BASIS_MATERIAL',dic_basis_material_id)
    )) into lx_data
  from gco_alloy_component
  where gco_alloy_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_ALLOY_COMPONENT,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_precious_rate_date(
  Id IN gco_alloy.gco_alloy_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_ALLOY_ID,DIC_BASIS_MATERIAL_ID,GPR_START_VALIDITY' as TABLE_KEY,
        gco_precious_rate_date_id),
      rep_pc_functions.get_dictionary('DIC_BASIS_MATERIAL',dic_basis_material_id),
      rep_pc_functions.get_dictionary('DIC_FREE_CODE1',dic_free_code1_id),
      rep_pc_functions.get_dictionary('DIC_COMPLEMENTARY_DATA',dic_complementary_data_id),
      rep_pc_functions.get_descodes('C_THIRD_MATERIAL_RELATION_TYPE', C_THIRD_MATERIAL_RELATION_TYPE),
      XMLForest(
        to_char(gpr_start_validity) as GPR_START_VALIDITY,
        gpr_base_cost, gpr_base2_cost, GPR_DESCRIPTION, GPR_REFERENCE, GPR_TABLE_MODE),
      rep_log_functions.get_gco_precious_rate(gco_precious_rate_date_id)
    )) into lx_data
  from gco_precious_rate_date
  where gco_alloy_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_PRECIOUS_RATE_DATE,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_precious_rate(
  Id IN gco_precious_rate_date.gco_precious_rate_date_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_PRECIOUS_RATE_DATE_ID,DIC_TYPE_RATE_ID' as TABLE_KEY,
        gco_precious_rate_id),
      rep_pc_functions.get_dictionary('DIC_TYPE_RATE',dic_type_rate_id),
      XMLForest(
        gpr_rate,
        gpr_comment,
        GPR_START_RANGE,
        GPR_END_RANGE)
    )) into lx_data
  from gco_precious_rate
  where gco_precious_rate_date_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_PRECIOUS_RATE,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_precious_mat(
  Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_GOOD_ID,GCO_ALLOY_ID' as TABLE_KEY),
      rep_log_functions_link.get_gco_alloy_link(gco_alloy_id),
      rep_pc_functions.get_dictionary('DIC_FREE_PMAT1',dic_free_pmat1_id),
      rep_pc_functions.get_dictionary('DIC_FREE_PMAT2',dic_free_pmat2_id),
      rep_pc_functions.get_dictionary('DIC_FREE_PMAT3',dic_free_pmat3_id),
      rep_pc_functions.get_dictionary('DIC_FREE_PMAT4',dic_free_pmat4_id),
      rep_pc_functions.get_dictionary('DIC_FREE_PMAT5',dic_free_pmat5_id),
      XMLForest(
        gpm_weight,
        gpm_real_weight,
        gpm_theorical_weight,
        gpm_weight_deliver,
        gpm_stone_number,
        gpm_weight_deliver_auto,
        gpm_loss_unit,
        gpm_loss_percent,
        -- Les champs suivants sont uniquement calculés
        --GPM_WEIGHT_DELIVER_VALUE
        --GPM_WEIGHT_INVEST
        --GPM_WEIGHT_INVEST_VALUE
        --GPM_WEIGHT_CHIP
        --GPM_WEIGHT_INVEST_TOTAL
        --GPM_WEIGHT_INVEST_TOTAL_VALUE
        --GPM_WEIGHT_CHIP_TOTAL
        --GPM_LOSS_TOTAL
        gpm_comment, gpm_comment2,
        gpm_free_number1, gpm_free_number2, gpm_free_number3, gpm_free_number4,
          gpm_free_number5),
      rep_pc_functions.get_com_vfields_record(gco_precious_mat_id,'GCO_PRECIOUS_MAT'),
      rep_pc_functions.get_com_vfields_value(gco_precious_mat_id,'GCO_PRECIOUS_MAT')
    )) into lx_data
  from gco_precious_mat
  where gco_good_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_PRECIOUS_MAT,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_product_group_xml(
  Id gco_product_group.gco_product_group_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(PRODUCT_GROUPS,
      XMLElement(GCO_PRODUCT_GROUP,
        XMLAttributes(
          gco_product_group_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'PRG_NAME' as TABLE_KEY,
          gco_product_group_id,
          prg_name,
          prg_description,
          prg_max_discount),
        rep_pc_functions.get_dictionary('DIC_GCO_LEVEL_A',dic_gco_level_a_id),
        rep_pc_functions.get_dictionary('DIC_GCO_LEVEL_B',dic_gco_level_b_id),
        rep_pc_functions.get_dictionary('DIC_GCO_LEVEL_C',dic_gco_level_c_id),
        rep_pc_functions.get_dictionary('DIC_GCO_LEVEL_D',dic_gco_level_d_id),
        rep_pc_functions.get_dictionary('DIC_GCO_LEVEL_E',dic_gco_level_e_id),
        rep_pc_functions.get_dictionary('DIC_GCO_MANAGER',dic_gco_manager_id),
        rep_pc_functions.get_dictionary('DIC_GCO_STICKER_FORMAT',dic_gco_sticker_format_id),
        rep_pc_functions.get_dictionary('DIC_GCO_STICKER_COLOR',dic_gco_sticker_color_id),
        rep_pc_functions.get_dictionary('DIC_GCO_STORAGE',dic_gco_storage_id),
        rep_pc_functions.get_dictionary('DIC_GCO_DOCUMENT',dic_gco_document_id),
        rep_log_functions_link.get_ptc_tariff_category_link(ptc_tariff_category_id),
        rep_pc_functions.get_dictionary('DIC_PRG_FREE_TABLE_1',dic_prg_free_table_1_id),
        rep_pc_functions.get_dictionary('DIC_PRG_FREE_TABLE_2',dic_prg_free_table_2_id),
        rep_pc_functions.get_dictionary('DIC_PRG_FREE_TABLE_3',dic_prg_free_table_3_id),
        rep_pc_functions.get_dictionary('DIC_PRG_FREE_TABLE_4',dic_prg_free_table_4_id),
        rep_pc_functions.get_dictionary('DIC_PRG_FREE_TABLE_5',dic_prg_free_table_5_id),
        XMLForest(
          prg_free_number_1, prg_free_number_2, prg_free_number_3, prg_free_number_4,
            prg_free_number_5,
          prg_free_alpha_1, prg_free_alpha_2, prg_free_alpha_3, prg_free_alpha_4,
            prg_free_alpha_5),
        rep_pc_functions.get_com_vfields_record(gco_product_group_id,'GCO_PRODUCT_GROUP'),
        rep_pc_functions.get_com_vfields_value(gco_product_group_id,'GCO_PRODUCT_GROUP')
      )
    ) into lx_data
  from gco_product_group
  where gco_product_group_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(PRODUCT_GROUPS,
          XMLElement(GCO_PRODUCT_GROUP,
             XMLAttributes(Id as ID),
             XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_gco_quality_status_xml(
  Id IN gco_quality_status.gco_quality_status_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(QUALITY_STATUS,
      XMLElement(GCO_QUALITY_STATUS,
        XMLAttributes(gco_quality_status_id as ID, pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'QST_REFERENCE' as TABLE_KEY,
          gco_quality_status_id),
        XMLForest(
          qst_reference,
          qst_description,
          qst_use_for_forecast,
          qst_use_for_link,
          qst_sequence_for_need,
          qst_negative_retest_status),
        rep_log_functions.get_quality_non_allowed_mvts(gco_quality_status_id),
        rep_pc_functions.get_com_vfields_record(gco_quality_status_id,'GCO_QUALITY_STATUS'),
        rep_pc_functions.get_com_vfields_value(gco_quality_status_id,'GCO_QUALITY_STATUS')
        )) into lx_data
  from gco_quality_status
  where gco_quality_status_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(QUALITY_STATUS,
          XMLElement(GCO_QUALITY_STATUS,
             XMLAttributes(Id as ID),
             XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end get_gco_quality_status_xml;

function get_gco_quality_stat_flow_xml(
  Id IN gco_quality_stat_flow.gco_quality_stat_flow_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(QUALITY_STATUS_FLOW,
      XMLElement(GCO_QUALITY_STAT_FLOW,
        XMLAttributes(gco_quality_stat_flow_id as ID, pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'QSF_REFERENCE' as TABLE_KEY,
          gco_quality_stat_flow_id),
        rep_log_functions_link.get_gco_quality_status_link(gco_quality_status_id),
        XMLForest(
          qsf_reference,
          qsf_description,
          qsf_default),
        rep_log_functions.get_gco_quality_stat_flow_det(gco_quality_stat_flow_id),
        rep_pc_functions.get_com_vfields_record(gco_quality_stat_flow_id,'GCO_QUALITY_STAT_FLOW'),
        rep_pc_functions.get_com_vfields_value(gco_quality_stat_flow_id,'GCO_QUALITY_STAT_FLOW')
        )) into lx_data
  from gco_quality_stat_flow
  where gco_quality_stat_flow_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(QUALITY_STATUS_FLOW,
          XMLElement(GCO_QUALITY_STAT_FLOW,
             XMLAttributes(Id as ID),
             XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end get_gco_quality_stat_flow_xml;

function get_gco_quality_stat_flow_det(
  Id IN gco_quality_stat_flow.gco_quality_stat_flow_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_QUALITY_STAT_FLOW_ID,GCO_QUALITY_STAT_FROM_ID,GCO_QUALITY_STAT_TO_ID' as TABLE_KEY,
        gco_quality_stat_flow_det_id),
      rep_log_functions_link.get_gco_quality_status_link(gco_quality_stat_from_id,'GCO_QUALITY_STAT_FROM', 1),
      rep_log_functions_link.get_gco_quality_status_link(gco_quality_stat_to_id,'GCO_QUALITY_STAT_TO', 1),
      XMLForest(
        qsf_proc_before_validation,
        qsf_proc_after_validation,
        qsf_delete_network_link,
        qsf_update_link),
      rep_pc_functions.get_com_vfields_record(gco_quality_stat_flow_det_id,'GCO_QUALITY_STAT_FLOW_DET'),
      rep_pc_functions.get_com_vfields_value(gco_quality_stat_flow_det_id,'GCO_QUALITY_STAT_FLOW_DET')
    )) into lx_data
  from GCO_QUALITY_STAT_FLOW_DET
  where GCO_QUALITY_STAT_FLOW_ID = Id;

  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_QUALITY_STAT_FLOW_DET,
      XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end get_gco_quality_stat_flow_det;

function get_stm_distribution_unit_xml(
  Id stm_distribution_unit.stm_distribution_unit_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(DISTRIBUTION_UNITS,
      XMLElement(STM_DISTRIBUTION_UNIT,
        XMLAttributes(
          stm_distribution_unit_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'DIU_NAME' as TABLE_KEY,
          stm_distribution_unit_id,
          diu_name,
          diu_description,
          diu_blocked_from,
          diu_blocked_to,
          diu_prepare_time,
          diu_level),
        rep_pc_functions.get_descodes('C_DRP_UNIT_TYPE',c_drp_unit_type),
        rep_pc_functions.get_dictionary('DIC_DISTRIB_COMPL_DATA',dic_distrib_compl_data_id),
        rep_pac_functions_link.get_pac_address_link(pac_address_id),
        rep_log_functions_link.get_stm_stock_link(stm_stock_id),
        rep_log_functions_link.get_stm_distribution_unit_link(stm_stm_distribution_unit_id, 'STM_STM_DISTRIBUTION_UNIT', 1),
        rep_pc_functions.get_com_vfields_record(stm_distribution_unit_id,'STM_DISTRIBUTION_UNIT'),
        rep_pc_functions.get_com_vfields_value(stm_distribution_unit_id,'STM_DISTRIBUTION_UNIT')
      )
    ) into lx_data
  from stm_distribution_unit
  where stm_distribution_unit_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(DISTRIBUTION_UNITS,
          XMLElement(STM_DISTRIBUTION_UNIT,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_gco_good_xml(
  Id IN gco_good.gco_good_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ARTICLES,
      XMLElement(GCO_GOOD,
        XMLAttributes(
          gco_good_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'GOO_MAJOR_REFERENCE' as TABLE_KEY,
          gco_good_id),
        rep_pc_functions.get_descodes('C_GOOD_STATUS',c_good_status),
        rep_log_functions_link.get_gco_substitution_link(gco_substitution_list_id),
        rep_pc_functions.get_dictionary('DIC_UNIT_OF_MEASURE',dic_unit_of_measure_id),
        rep_pc_functions.get_dictionary('DIC_ACCOUNTABLE_GROUP',dic_accountable_group_id),
        rep_log_functions_link.get_gco_multimedia_link(gco_multimedia_element_id),
        rep_log_functions_link.get_gco_good_category_link(gco_good_category_id),
        rep_pc_functions.get_dictionary('DIC_GOOD_LINE',dic_good_line_id),
        rep_pc_functions.get_dictionary('DIC_GOOD_FAMILY',dic_good_family_id),
        rep_pc_functions.get_dictionary('DIC_GOOD_MODEL', dic_good_model_id),
        rep_pc_functions.get_dictionary('DIC_GOOD_GROUP',dic_good_group_id),
        rep_pc_functions.get_descodes('C_MANAGEMENT_MODE', c_management_mode),
        XMLForest(
          goo_major_reference,
          goo_secondary_reference,
          goo_ean_code,
          goo_ccp_management,
          goo_number_of_decimal,
          gco_data_purchase,
          gco_data_sale,
          gco_data_stock,
          gco_data_inventory,
          gco_data_manufacture,
          gco_data_subcontract,
          gco_data_sav,
          gco_good_ole_object),
        rep_pc_functions.get_dictionary('DIC_PUR_TARIFF_STRUCT',dic_pur_tariff_struct_id),
        rep_pc_functions.get_dictionary('DIC_SALE_TARIFF_STRUCT',dic_sale_tariff_struct_id),
        rep_pc_functions.get_dictionary('DIC_TARIFF_SET_PURCHASE',dic_tariff_set_purchase_id),
        rep_pc_functions.get_dictionary('DIC_TARIFF_SET_SALE',dic_tariff_set_sale_id),
        rep_pc_functions.get_dictionary('DIC_COMMISSIONING', dic_commissioning_id),
        rep_pc_functions.get_descodes('C_GOO_WEB_STATUS',c_goo_web_status),
        rep_pc_functions.get_dictionary('DIC_GOO_WEB_CATEG1',dic_goo_web_categ1_id),
        rep_pc_functions.get_dictionary('DIC_GOO_WEB_CATEG2',dic_goo_web_categ2_id),
        rep_pc_functions.get_dictionary('DIC_GOO_WEB_CATEG3',dic_goo_web_categ3_id),
        rep_pc_functions.get_dictionary('DIC_GOO_WEB_CATEG4',dic_goo_web_categ4_id),
        XMLForest(
          goo_web_published,
          goo_web_alias,
          goo_web_picture_url,
          goo_web_attachement_url,
          goo_unspsc,
          to_char(goo_innovation_from) as GOO_INNOVATION_FROM,
          to_char(goo_innovation_to) as GOO_INNOVATION_TO,
          goo_std_percent_waste,
          goo_std_fixed_quantity_waste,
          goo_std_qty_reference_loss),
        rep_pc_functions.get_dictionary('DIC_GCO_STATISTIC_1',dic_gco_statistic_1_id),
        rep_pc_functions.get_dictionary('DIC_GCO_STATISTIC_2',dic_gco_statistic_2_id),
        rep_pc_functions.get_dictionary('DIC_GCO_STATISTIC_3',dic_gco_statistic_3_id),
        rep_pc_functions.get_dictionary('DIC_GCO_STATISTIC_4',dic_gco_statistic_4_id),
        rep_pc_functions.get_dictionary('DIC_GCO_STATISTIC_5',dic_gco_statistic_5_id),
        rep_pc_functions.get_dictionary('DIC_GCO_STATISTIC_6',dic_gco_statistic_6_id),
        rep_pc_functions.get_dictionary('DIC_GCO_STATISTIC_7',dic_gco_statistic_7_id),
        rep_pc_functions.get_dictionary('DIC_GCO_STATISTIC_8',dic_gco_statistic_8_id),
        rep_pc_functions.get_dictionary('DIC_GCO_STATISTIC_9',dic_gco_statistic_9_id),
        rep_pc_functions.get_dictionary('DIC_GCO_STATISTIC_10',dic_gco_statistic_10_id),
        XMLForest(
          goo_ean_code_auto_gen),
        rep_log_functions.get_gco_descriptions(gco_good_id),
        rep_log_functions.get_gco_good_attribute(gco_good_id),
        rep_log_functions.get_gco_service(gco_good_id),
        rep_log_functions.get_gco_pseudo_good(gco_good_id),
        rep_log_functions.get_gco_product(gco_good_id),
        rep_log_functions.get_gco_connected_goods(gco_good_id),
        rep_log_functions.get_gco_characterizations(gco_good_id),
        rep_log_functions.get_gco_free_code(gco_good_id),
        rep_log_functions.get_gco_free_data(gco_good_id),
        rep_log_functions.get_ptc_tariff(gco_good_id, dic_sale_tariff_struct_id, dic_pur_tariff_struct_id),
        rep_pc_functions.get_com_image_files(gco_good_id,'GCO_GOOD'),
        rep_pc_functions.get_com_vfields_record(gco_good_id,'GCO_GOOD'),
        rep_pc_functions.get_com_vfields_value(gco_good_id,'GCO_GOOD'),
        rep_log_functions.get_gco_compl_data_purchase(gco_good_id),
        rep_log_functions.get_gco_compl_data_sale(gco_good_id),
        rep_log_functions.get_gco_compl_data_stock(gco_good_id),
        rep_log_functions.get_gco_compl_data_inventory(gco_good_id),
        rep_log_functions.get_gco_compl_data_manufacture(gco_good_id),
        rep_log_functions.get_gco_compl_data_ass(gco_good_id),
        REP_LOG_FUNCTIONS.get_gco_compl_data_ext_asa(GCO_GOOD_ID),
        rep_log_functions.get_gco_compl_data_distrib(gco_good_id),
        REP_LOG_FUNCTIONS.get_gco_compl_data_subcontract(GCO_GOOD_ID),
        REP_LOG_FUNCTIONS.get_gco_equivalence_good(GCO_GOOD_ID),
        rep_log_functions.get_gco_vat_good(gco_good_id),
        rep_log_functions.get_gco_imput_doc(gco_good_id),
        rep_log_functions.get_gco_precious_mat(gco_good_id),
        rep_log_functions_link.get_gco_product_group_link(gco_product_group_id),
        XMLForest(
          goo_obsolete,
          goo_precious_mat),
        rep_pc_functions.get_dictionary('DIC_PTC_GOOD_GROUP',dic_ptc_good_group_id),
        XMLForest(
          goo_to_publish,
          goo_hibc_primary_code,
          goo_hibc_reference,
          goo_ean_ucc14_code),
        rep_pc_functions.get_dictionary('DIC_SET_TYPE',dic_set_type_id),
        rep_pc_functions.get_descodes('C_SERVICE_KIND',c_service_kind),
        rep_pc_functions.get_descodes('C_SERVICE_RENEWAL',c_service_renewal),
        rep_pc_functions.get_descodes('C_SERVICE_GOOD_LINK',c_service_good_link),
        rep_log_functions.get_gco_customs_elements(gco_good_id),
        rep_log_functions.get_gco_measurement_weights(gco_good_id),
        rep_log_functions.get_gco_materials(gco_good_id)
      )
    ) into lx_data
  from gco_good
  where gco_good_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(ARTICLES,
          XMLElement(GCO_GOOD,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_gco_good_category_xml(
  Id IN gco_good_category.gco_good_category_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(CATEGORIES,
      XMLElement(GCO_GOOD_CATEGORY,
        XMLAttributes(
          gco_good_category_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'GCO_CATEGORY_CODE' as TABLE_KEY,
          gco_good_category_id),
        rep_log_functions.get_gco_reference_template(gco_reference_template_id),
        rep_log_functions_link.get_GCO_QUALITY_STAT_FLOW_link(GCO_QUALITY_STAT_FLOW_ID),
        XMLForest(
          gco_good_category_wording,
          cat_guid,
          gco_category_code,
          cat_stk_possession_rate,
          cat_compl_achat,
          cat_compl_vente,
          cat_compl_sav,
          cat_compl_external_asa,
          cat_compl_stock,
          cat_compl_inv,
          cat_compl_fab,
          cat_compl_strait,
          cat_compl_distrib,
          CAT_COMPL_TOOL,
          cat_compl_service),
        rep_pc_functions.get_dictionary('DIC_CATEGORY_FREE_1',dic_category_free_1_id),
        rep_pc_functions.get_dictionary('DIC_CATEGORY_FREE_2',dic_category_free_2_id),
        XMLForest(
          cat_free_text_1, cat_free_text_2, cat_free_text_3, cat_free_text_4,
            cat_free_text_5,
          cat_free_number_1, cat_free_number_2, cat_free_number_3, cat_free_number_4,
            cat_free_number_5),
        rep_pc_functions.get_descodes('C_EAN_TYPE',c_ean_type),
        XMLForest(
          cat_ean_ctrl_function,
          cat_ean_gen_function),
        rep_pc_functions.get_dictionary('DIC_GOOD_EAN_CTRL',dic_good_ean_ctrl_id,'DIC_GOOD_EAN'),
        rep_pc_functions.get_dictionary('DIC_GOOD_EAN_GEN',dic_good_ean_gen_id,'DIC_GOOD_EAN'),
        rep_pc_functions.get_descodes('C_EAN_TYPE_PURCHASE',c_ean_type_purchase,'C_EAN_TYPE'),
        rep_pc_functions.get_dictionary('DIC_GOOD_EAN_CTRL_PUR',dic_good_ean_ctrl_pur_id,'DIC_GOOD_EAN'),
        rep_pc_functions.get_dictionary('DIC_GOOD_EAN_GEN_PUR',dic_good_ean_gen_pur_id,'DIC_GOOD_EAN'),
        rep_pc_functions.get_descodes('C_EAN_TYPE_SALE',c_ean_type_sale,'C_EAN_TYPE'),
        rep_pc_functions.get_dictionary('DIC_GOOD_EAN_CTRL_SALE',dic_good_ean_ctrl_sale_id,'DIC_GOOD_EAN'),
        rep_pc_functions.get_dictionary('DIC_GOOD_EAN_GEN_SALE',dic_good_ean_gen_sale_id,'DIC_GOOD_EAN'),
        rep_pc_functions.get_descodes('C_EAN_TYPE_ASA',c_ean_type_asa,'C_EAN_TYPE'),
        rep_pc_functions.get_dictionary('DIC_GOOD_EAN_CTRL_ASA',dic_good_ean_ctrl_asa_id,'DIC_GOOD_EAN'),
        rep_pc_functions.get_dictionary('DIC_GOOD_EAN_GEN_ASA',dic_good_ean_gen_asa_id,'DIC_GOOD_EAN'),
        rep_pc_functions.get_descodes('C_EAN_TYPE_STOCK',c_ean_type_stock,'C_EAN_TYPE'),
        rep_pc_functions.get_dictionary('DIC_GOOD_EAN_CTRL_STOCK',dic_good_ean_ctrl_stock_id,'DIC_GOOD_EAN'),
        rep_pc_functions.get_dictionary('DIC_GOOD_EAN_GEN_STOCK',dic_good_ean_gen_stock_id,'DIC_GOOD_EAN'),
        rep_pc_functions.get_descodes('C_EAN_TYPE_INV',c_ean_type_inv,'C_EAN_TYPE'),
        rep_pc_functions.get_dictionary('DIC_GOOD_EAN_CTRL_INV',dic_good_ean_ctrl_inv_id,'DIC_GOOD_EAN'),
        rep_pc_functions.get_dictionary('DIC_GOOD_EAN_GEN_INV',dic_good_ean_gen_inv_id,'DIC_GOOD_EAN'),
        rep_pc_functions.get_descodes('C_EAN_TYPE_FAL',c_ean_type_fal,'C_EAN_TYPE'),
        rep_pc_functions.get_dictionary('DIC_GOOD_EAN_CTRL_FAL',dic_good_ean_ctrl_fal_id,'DIC_GOOD_EAN'),
        rep_pc_functions.get_dictionary('DIC_GOOD_EAN_GEN_FAL',dic_good_ean_gen_fal_id,'DIC_GOOD_EAN'),
        rep_pc_functions.get_descodes('C_EAN_TYPE_SUBCONTRACT',c_ean_type_subcontract,'C_EAN_TYPE'),
        rep_pc_functions.get_dictionary('DIC_GOOD_EAN_CTRL_SCO',dic_good_ean_ctrl_sco_id,'DIC_GOOD_EAN'),
        rep_pc_functions.get_dictionary('DIC_GOOD_EAN_GEN_SCO',dic_good_ean_gen_sco_id,'DIC_GOOD_EAN'),
        rep_pc_functions.get_descodes('C_EAN_TYPE_DIU',c_ean_type_diu,'C_EAN_TYPE'),
        rep_pc_functions.get_dictionary('DIC_GOOD_EAN_CTRL_DIU',dic_good_ean_ctrl_diu_id,'DIC_GOOD_EAN'),
        rep_pc_functions.get_dictionary('DIC_GOOD_EAN_GEN_DIU',dic_good_ean_gen_diu_id,'DIC_GOOD_EAN'),
        --GCO_GOOD_NUMBERING_ID
        -- GCO_GCO_GOOD_NUMBERING_ID
        rep_log_functions.get_dic_tabsheet_attribute(dic_tabsheet_attribute_1_id,'DIC_TABSHEET_ATTRIBUTE_1'),
        rep_log_functions.get_dic_tabsheet_attribute(dic_tabsheet_attribute_2_id,'DIC_TABSHEET_ATTRIBUTE_2'),
        rep_log_functions.get_dic_tabsheet_attribute(dic_tabsheet_attribute_3_id,'DIC_TABSHEET_ATTRIBUTE_3'),
        rep_log_functions.get_dic_tabsheet_attribute(dic_tabsheet_attribute_4_id,'DIC_TABSHEET_ATTRIBUTE_4'),
        rep_log_functions.get_dic_tabsheet_attribute(dic_tabsheet_attribute_5_id,'DIC_TABSHEET_ATTRIBUTE_5'),
        rep_log_functions.get_dic_tabsheet_attribute(dic_tabsheet_attribute_6_id,'DIC_TABSHEET_ATTRIBUTE_6'),
        rep_log_functions.get_dic_tabsheet_attribute(dic_tabsheet_attribute_7_id,'DIC_TABSHEET_ATTRIBUTE_7'),
        rep_log_functions.get_dic_tabsheet_attribute(dic_tabsheet_attribute_8_id,'DIC_TABSHEET_ATTRIBUTE_8'),
        rep_log_functions.get_dic_tabsheet_attribute(dic_tabsheet_attribute_9_id,'DIC_TABSHEET_ATTRIBUTE_9'),
        rep_log_functions.get_dic_tabsheet_attribute(dic_tabsheet_attribute_10_id,'DIC_TABSHEET_ATTRIBUTE_10'),
        rep_log_functions.get_dic_tabsheet_attribute(dic_tabsheet_attribute_11_id,'DIC_TABSHEET_ATTRIBUTE_11'),
        rep_log_functions.get_dic_tabsheet_attribute(dic_tabsheet_attribute_12_id,'DIC_TABSHEET_ATTRIBUTE_12'),
        rep_log_functions.get_dic_tabsheet_attribute(dic_tabsheet_attribute_13_id,'DIC_TABSHEET_ATTRIBUTE_13'),
        rep_log_functions.get_dic_tabsheet_attribute(dic_tabsheet_attribute_14_id,'DIC_TABSHEET_ATTRIBUTE_14'),
        rep_log_functions.get_dic_tabsheet_attribute(dic_tabsheet_attribute_15_id,'DIC_TABSHEET_ATTRIBUTE_15'),
        rep_log_functions.get_dic_tabsheet_attribute(dic_tabsheet_attribute_16_id,'DIC_TABSHEET_ATTRIBUTE_16'),
        rep_log_functions.get_dic_tabsheet_attribute(dic_tabsheet_attribute_17_id,'DIC_TABSHEET_ATTRIBUTE_17'),
        rep_log_functions.get_dic_tabsheet_attribute(dic_tabsheet_attribute_18_id,'DIC_TABSHEET_ATTRIBUTE_18'),
        rep_log_functions.get_dic_tabsheet_attribute(dic_tabsheet_attribute_19_id,'DIC_TABSHEET_ATTRIBUTE_19'),
        rep_log_functions.get_dic_tabsheet_attribute(dic_tabsheet_attribute_20_id,'DIC_TABSHEET_ATTRIBUTE_20'),
        -- Les informations de la table gco_attribute_fields doivent être envoyées séparément
        -- au moyen de la méthode rep_functions.PublishAttributeFields
          --rep_log_functions.get_gco_attribute_fields(gco_good_category_id),
        XMLForest(
          cat_compl_attribute),
        rep_log_functions.get_gco_transfer_lists(gco_good_category_id),
        rep_pc_functions.get_descodes('C_REPLICATION_TYPE',c_replication_type),
        XMLForest(
          cat_autom_numbering,
          cat_dupl_charges,
          cat_dupl_compl_achat,
          cat_dupl_compl_attribute,
          cat_dupl_compl_distrib,
          cat_dupl_compl_external_asa,
          cat_dupl_compl_fab,
          cat_dupl_compl_inv,
          CAT_DUPL_COMPL_TOOL,
          cat_dupl_compl_sav,
          cat_dupl_compl_service,
          cat_dupl_compl_stock,
          cat_dupl_compl_strait,
          cat_dupl_compl_vente,
          CAT_DUPL_CORRELATION,
          cat_dupl_discount,
          cat_dupl_freedata,
          cat_dupl_nomencl,
          cat_dupl_prc,
          cat_dupl_precious_mat,
          cat_dupl_prf,
          cat_dupl_schedule_plan,
          cat_dupl_tariff,
          cat_dupl_tools,
          cat_dupl_virtual_fields,
          cat_dupl_coupled_goods,
          cat_dupl_certifications,
          cat_ean_asa_updatable,
          cat_ean_diu_updatable,
          cat_ean_fal_updatable,
          cat_ean_goo_updatable,
          cat_ean_inv_updatable,
          cat_ean_pur_updatable,
          cat_ean_sal_updatable,
          cat_ean_stk_updatable,
          cat_ean_sub_updatable,
          cat_ean_goo_ucc14,
          cat_ean_asa_ucc14,
          cat_ean_diu_ucc14,
          cat_ean_fal_ucc14,
          cat_ean_inv_ucc14,
          cat_ean_pur_ucc14,
          cat_ean_sal_ucc14,
          cat_ean_stk_ucc14,
          cat_ean_sub_ucc14,
          cat_hibc_management,
          cat_hibc_auto_gen,
          CAT_UNIT_MARGIN_RATE),
        -- les transformateur d'entrée et de sortie ne sont pas repris
        -- CAT_XSLT_FLAG_OUT,
        -- CAT_XSLT_OUT,
        -- CAT_XSLT_FLAG_IN,
        -- CAT_XSLT_IN,
        rep_log_functions.get_gco_good_category_descr(gco_good_category_id),
        rep_pc_functions.get_com_vfields_record(gco_good_category_id,'GCO_GOOD_CATEGORY'),
        rep_pc_functions.get_com_vfields_value(gco_good_category_id,'GCO_GOOD_CATEGORY')
      )
    ) into lx_data
  from gco_good_category
  where gco_good_category_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(CATEGORIES,
          XMLElement(GCO_GOOD_CATEGORY,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_gco_good_category_descr(
  Id IN gco_good_category.gco_good_category_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'GCO_GOOD_CATEGORY_ID,PC_LANG_ID' as TABLE_KEY,
        d.gco_good_category_descr_id,
        l.lanid,
        d.gcd_wording,
        d.gcd_free_description)
    )) into lx_data
  from pcs.pc_lang l, gco_good_category_descr d
  where d.gco_good_category_id = Id and l.pc_lang_id = d.pc_lang_id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(GCO_GOOD_CATEGORY_DESCR,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_gco_alloy_xml(
  Id IN gco_alloy.gco_alloy_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(ALLOYS,
      XMLElement(GCO_ALLOY,
        XMLAttributes(
          gco_alloy_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'GAL_ALLOY_REF' as TABLE_KEY,
          gco_alloy_id),
        rep_log_functions_link.get_gco_good_link(gco_good_id),
        rep_pc_functions.get_dictionary('DIC_UNIT_OF_MEASURE',dic_unit_of_measure_id),
        rep_pc_functions.get_dictionary('DIC_STONE_TYPE',dic_stone_type_id),
        rep_pc_functions.get_dictionary('DIC_FREE_ALLOY1',dic_free_alloy1_id),
        rep_pc_functions.get_dictionary('DIC_FREE_ALLOY2',dic_free_alloy2_id),
        rep_pc_functions.get_dictionary('DIC_FREE_ALLOY3',dic_free_alloy3_id),
        rep_pc_functions.get_dictionary('DIC_FREE_ALLOY4',dic_free_alloy4_id),
        rep_pc_functions.get_dictionary('DIC_FREE_ALLOY5',dic_free_alloy5_id),
        XMLForest(
          gal_alloy_ref,
          gal_alloy_descr,
          gal_stone,
          gal_convert_factor_gr,
          gal_comment1,
          gal_comment2,
          gal_free_number1, gal_free_number2, gal_free_number3, gal_free_number4,
            gal_free_number5,
          gal_free_text1, gal_free_text2, gal_free_text3, gal_free_text4,
            gal_free_text5),
        rep_log_functions.get_gco_alloy_component(gco_alloy_id),
        rep_log_functions.get_gco_precious_rate_date(gco_alloy_id),
        rep_pc_functions.get_com_vfields_record(gco_alloy_id,'GCO_ALLOY'),
        rep_pc_functions.get_com_vfields_value(gco_alloy_id,'GCO_ALLOY')
      )
    ) into lx_data
  from gco_alloy
  where gco_alloy_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(ALLOYS,
          XMLElement(GCO_ALLOY,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;


--
-- STM  functions
--

function get_stm_stock_xml(
  Id IN stm_stock.stm_stock_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(STOCKS,
      XMLElement(STM_STOCK,
        XMLAttributes(
          stm_stock_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'STO_DESCRIPTION' as TABLE_KEY,
          stm_stock_id),
        rep_fin_functions_link.get_acs_fin_account_link(acs_financial_account_id, 'ACS_FINANCIAL_ACCOUNT'),
        rep_fin_functions_link.get_acs_div_account_link(acs_division_account_id, 'ACS_DIVISION_ACCOUNT'),
        rep_fin_functions_link.get_acs_vat_det_account_link(acs_vat_det_account_id),
        rep_pac_functions_link.get_pac_third_link(pac_third_id, 'PAC_THIRD'),
        rep_pac_functions_link.get_pac_third_link(PAC_SUPPLIER_PARTNER_ID, 'PAC_SUPPLIER_PARTNER'),
        rep_pc_functions.get_dictionary('DIC_STO_FREE_CODE_1',dic_sto_free_code_1_id),
        rep_pc_functions.get_dictionary('DIC_STO_FREE_CODE_2',dic_sto_free_code_2_id),
        rep_pc_functions.get_dictionary('DIC_STO_FREE_CODE_3',dic_sto_free_code_3_id),
        rep_pc_functions.get_dictionary('DIC_STO_FREE_CODE_4',dic_sto_free_code_4_id),
        rep_pc_functions.get_dictionary('DIC_STO_FREE_CODE_5',dic_sto_free_code_5_id),
        rep_pc_functions.get_dictionary('DIC_STO_GROUP',DIC_STO_GROUP_ID),
        rep_pc_functions.get_descodes('C_ACCESS_METHOD', c_access_method),
        rep_pc_functions.get_descodes('C_STO_METAL_ACCOUNT_TYPE', c_sto_metal_account_type),
        rep_pc_functions.get_descodes('C_THIRD_MATERIAL_RELATION_TYPE', c_third_material_relation_type),
        XMLForest(
          sto_classification,
          sto_consumer_analyse_use,
          sto_costprice_reset,
          sto_default_metal_account,
          sto_description,
          sto_fixed_stock_position,
          sto_free_boolean_1, sto_free_boolean_2, sto_free_boolean_3, sto_free_boolean_4,
            sto_free_boolean_5,
          to_char(sto_free_date_1) as STO_FREE_DATE_1,
          to_char(sto_free_date_2) as STO_FREE_DATE_2,
          to_char(sto_free_date_3) as STO_FREE_DATE_3,
          to_char(sto_free_date_4) as STO_FREE_DATE_4,
          to_char(sto_free_date_5) as STO_FREE_DATE_5,
          sto_free_decimal_1, sto_free_decimal_2, sto_free_decimal_3, sto_free_decimal_4,
            sto_free_decimal_5,
          sto_free_description,
          sto_free_text_1, sto_free_text_2, sto_free_text_3, sto_free_text_4,
            sto_free_text_5,
          sto_metal_account,
          sto_need_calculation,
          sto_need_pic,
          sto_shop_use,
          sto_subcontract),
        rep_pc_functions.get_com_vfields_record(stm_stock_id,'STM_STOCK'),
        rep_pc_functions.get_com_vfields_value(stm_stock_id,'STM_STOCK')
      )
    ) into lx_data
  from stm_stock
  where stm_stock_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(STOCKS,
          XMLElement(STM_STOCK,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_stm_location_xml(
  Id IN stm_location.stm_location_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(STOCKS,
      XMLElement(STM_LOCATION,
        XMLAttributes(
          stm_location_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'STM_STOCK_ID,LOC_DESCRIPTION' as TABLE_KEY,
          stm_location_id),
        rep_log_functions_link.get_stm_stock_link(stm_stock_id),
        rep_fin_functions_link.get_acs_fin_account_link(acs_financial_account_id, 'ACS_FINANCIAL_ACCOUNT'),
        rep_fin_functions_link.get_acs_div_account_link(acs_division_account_id, 'ACS_DIVISION_ACCOUNT'),
        rep_pc_functions.get_dictionary('DIC_LOC_FREE_CODE_1',dic_loc_free_code_1_id),
        rep_pc_functions.get_dictionary('DIC_LOC_FREE_CODE_2',dic_loc_free_code_2_id),
        rep_pc_functions.get_dictionary('DIC_LOC_FREE_CODE_3',dic_loc_free_code_3_id),
        rep_pc_functions.get_dictionary('DIC_LOC_FREE_CODE_4',dic_loc_free_code_4_id),
        rep_pc_functions.get_dictionary('DIC_LOC_FREE_CODE_5',dic_loc_free_code_5_id),
        rep_pc_functions.get_dictionary('DIC_TEMPERATURE',DIC_TEMPERATURE_ID),
        rep_pc_functions.get_dictionary('DIC_RELATIVE_HUMIDITY',DIC_RELATIVE_HUMIDITY_ID),
        rep_pc_functions.get_dictionary('DIC_LUMINOSITY',DIC_LUMINOSITY_ID),
        rep_pc_functions.get_dictionary('DIC_STORAGE_POSITION',DIC_STORAGE_POSITION_ID),
        XMLForest(
          loc_check_storage_cond,
          loc_classification,
          loc_continuous_inventar,
          loc_description,
          loc_fixed_stock_position,
          loc_free_boolean_1, loc_free_boolean_2, loc_free_boolean_3, loc_free_boolean_4,
            loc_free_boolean_5,
          to_char(loc_free_date_1) as LOC_FREE_DATE_1,
          to_char(loc_free_date_2) as LOC_FREE_DATE_2,
          to_char(loc_free_date_3) as LOC_FREE_DATE_3,
          to_char(loc_free_date_4) as LOC_FREE_DATE_4,
          to_char(loc_free_date_5) as LOC_FREE_DATE_5,
          loc_free_decimal_1, loc_free_decimal_2, loc_free_decimal_3, loc_free_decimal_4,
            loc_free_decimal_5,
          loc_free_description,
          loc_free_text_1, loc_free_text_2, loc_free_text_3, loc_free_text_4,
            loc_free_text_5,
          loc_full_location,
          loc_location_management),
        rep_pc_functions.get_com_vfields_record(stm_location_id,'STM_LOCATION'),
        rep_pc_functions.get_com_vfields_value(stm_location_id,'STM_LOCATION')
      )
    ) into lx_data
  from stm_location
  where stm_location_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(STOCKS,
          XMLElement(STM_LOCATION,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_stm_movement_kind_xml(
  Id IN stm_movement_kind.stm_movement_kind_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(STOCK_MOVEMENTS,
      XMLElement(STM_MOVEMENT_KIND,
        XMLAttributes(
          stm_movement_kind_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'MOK_ABBREVIATION' as TABLE_KEY,
          stm_movement_kind_id),
        rep_log_functions_link.get_stm_stock_link(stm_stock_id),
        rep_log_functions_link.get_stm_movement_kind_link(stm_stm_movement_kind_id, 'STM_STM_MOVEMENT_KIND',1),
        rep_fin_functions_link.get_acs_fin_account_link(acs_financial_account_id, 'ACS_FINANCIAL_ACCOUNT'),
        rep_fin_functions_link.get_acs_div_account_link(acs_division_account_id, 'ACS_DIVISION_ACCOUNT'),
        rep_fin_functions_link.get_acj_job_type_s_cat_link(acj_job_type_s_catalogue_id),
        rep_pc_functions.get_dictionary('DIC_MOK_STATISTIC_1',dic_mok_statistic_1_id),
        rep_pc_functions.get_dictionary('DIC_MOK_STATISTIC_2',dic_mok_statistic_2_id),
        rep_pc_functions.get_dictionary('DIC_MOK_STATISTIC_3',dic_mok_statistic_3_id),
        rep_pc_functions.get_descodes('C_MOVEMENT_CODE', c_movement_code),
        rep_pc_functions.get_descodes('C_MOVEMENT_SORT', c_movement_sort),
        rep_pc_functions.get_descodes('C_MOVEMENT_TYPE', c_movement_type),
        XMLForest(
          mok_abbreviation,
          mok_anal_imputation,
          mok_boolean_1, mok_boolean_2, mok_boolean_3,
          mok_costprice_use,
          mok_financial_imputation,
          mok_guaranty_use,
          mok_numeric_1, mok_numeric_2, mok_numeric_3,
          mok_oblig_doc,
          mok_oblig_doc_ext,
          mok_oblig_lib,
          mok_oblig_part,
          mok_oblig_part_ext,
          mok_pic_use,
          mok_return,
          mok_standard_sign,
          mok_subcontract_update,
          mok_transfer_attrib,
          mok_update_op,
          mok_use_managed_data,
          mok_use_restocking,
          mok_verify_characterization,
          mok_visible_doc,
          mok_visible_doc_ext,
          mok_visible_lib,
          mok_visible_part,
          mok_visible_part_ext),
        rep_log_functions.get_stm_mok_managed_data(stm_movement_kind_id),
        rep_pc_functions.get_com_vfields_record(stm_movement_kind_id,'STM_MOVEMENT_KIND'),
        rep_pc_functions.get_com_vfields_value(stm_movement_kind_id,'STM_MOVEMENT_KIND')
      )
    ) into lx_data
  from stm_movement_kind
  where stm_movement_kind_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(STOCK_MOVEMENTS,
          XMLElement(STM_MOVEMENT_KIND,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_stm_mok_managed_data(
  Id IN stm_movement_kind.stm_movement_kind_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'STM_MOVEMENT_KIND_ID,C_DATA_TYP' as TABLE_KEY,
        stm_mok_managed_data_id),
      rep_pc_functions.get_descodes('C_DATA_TYP', c_data_typ),
      XMLForest(
        gma_mandatory)
    )) into lx_data
  from stm_mok_managed_data
  where stm_movement_kind_id = Id;

  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(STM_MOK_MANAGED_DATA,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;


function get_stm_stock_movement_xml(
  Id IN stm_stock_movement.stm_stock_movement_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(STOCK_MOVEMENTS,
      XMLElement(STM_STOCK_MOVEMENT,
        XMLAttributes(
          stm_stock_movement_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'GCO_GOOD_ID,STM_PERIOD_ID,STM_LOCATION_ID' as TABLE_KEY,
          stm_stock_movement_id),
        rep_log_functions_link.get_stm_movement_kind_link(stm_movement_kind_id),
        rep_log_functions_link.get_stm_exercise_link(stm_exercise_id),
        rep_log_functions_link.get_stm_period_link(stm_period_id),
        rep_log_functions_link.get_stm_stock_movement_link(stm_stm_stock_movement_id,'STM_STM_STOCK_MOVEMENT',1),
        rep_log_functions_link.get_stm_stock_movement_link(stm2_stm_stock_movement_id,'STM2_STM_STOCK_MOVEMENT',1),
        rep_log_functions_link.get_doc_record_link(doc_record_id),
        rep_log_functions_link.get_doc_position_detail_link(doc_position_detail_id),
        rep_log_functions_link.get_gco_good_link(gco_good_id),
        rep_log_functions_link.get_stm_stock_link(stm_stock_id),
        rep_log_functions_link.get_stm_location_link(stm_location_id),
        rep_pac_functions_link.get_pac_third_link(pac_third_id),
        rep_log_functions_link.get_stm_distribution_unit_link(stm_distribution_unit_id),
        rep_log_functions_link.get_stm_distribution_unit_link(stm_stm_distribution_unit_id,'STM_STM_DISTRIBUTION_UNIT',1),
        rep_log_functions_link.get_gco_characterization_link(gco_characterization_id),
        rep_log_functions_link.get_gco_characterization_link(gco_gco_characterization_id,'GCO_GCO_CHARACTERIZATION',1),
        rep_log_functions_link.get_gco_characterization_link(gco2_gco_characterization_id,'GCO2_GCO_CHARACTERIZATION',1),
        rep_log_functions_link.get_gco_characterization_link(gco3_gco_characterization_id,'GCO3_GCO_CHARACTERIZATION',1),
        rep_log_functions_link.get_gco_characterization_link(gco4_gco_characterization_id,'GCO4_GCO_CHARACTERIZATION',1),
        XMLForest(
          smo_characterization_value_1, smo_characterization_value_2, smo_characterization_value_3,
            smo_characterization_value_4, smo_characterization_value_5,
          to_char(smo_movement_date) as SMO_MOVEMENT_DATE,
          smo_wording,
          smo_external_document,
          smo_external_partner,
          smo_movement_quantity,
          smo_movement_price,
          smo_document_quantity,
          smo_document_price,
          smo_unit_price,
          smo_financial_charging,
          smo_update_prov,
          smo_extourne_mvt),
        rep_pc_functions.get_com_vfields_record(stm_stock_movement_id,'STM_STOCK_MOVEMENT'),
        rep_pc_functions.get_com_vfields_value(stm_stock_movement_id,'STM_STOCK_MOVEMENT')
      )
    ) into lx_data
  from stm_stock_movement
  where stm_stock_movement_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(STOCK_MOVEMENTS,
          XMLElement(STM_STOCK_MOVEMENT,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_stock_non_allowed_mvts(
  iStockID IN stm_non_allowed_movements.stm_stock_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (iStockID in (null,0)) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'STM_MOVEMENT_KIND_ID,STM_STOCK_ID' as TABLE_KEY,
        STM_NON_ALLOWED_MOVEMENTS_ID
               ),
        rep_log_functions_link.get_stm_movement_kind_link(STM_MOVEMENT_KIND_ID, 'STM_MOVEMENT_KIND',1)
    )) into lx_data
  from STM_NON_ALLOWED_MOVEMENTS
  where STM_STOCK_ID = iStockID;

  if (lx_data is not null) then
    select
      XMLElement(STM_NON_ALLOWED_MOVEMENTS,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end get_stock_non_allowed_mvts;

function get_quality_non_allowed_mvts(
  iQualityStatusID IN stm_non_allowed_movements.gco_quality_status_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (iQualityStatusID in (null,0)) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'STM_MOVEMENT_KIND_ID,GCO_QUALITY_STATUS_ID' as TABLE_KEY,
        STM_NON_ALLOWED_MOVEMENTS_ID
               ),
        rep_log_functions_link.get_stm_movement_kind_link(STM_MOVEMENT_KIND_ID, 'STM_MOVEMENT_KIND',1)
    )) into lx_data
  from STM_NON_ALLOWED_MOVEMENTS
  where GCO_QUALITY_STATUS_ID = iQualityStatusID;

  if (lx_data is not null) then
    select
      XMLElement(STM_NON_ALLOWED_MOVEMENTS,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end get_quality_non_allowed_mvts;

--
-- PTC  functions
--

function get_ptc_tariff_category_xml(
  Id IN ptc_tariff_category.ptc_tariff_category_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(TARIFF_CATEGORIES,
      XMLElement(PTC_TARIFF_CATEGORY,
        XMLAttributes(
          ptc_tariff_category_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'TCA_DESCRIPTION' as TABLE_KEY,
          ptc_tariff_category_id,
          tca_description),
        rep_pc_functions.get_dictionary('DIC_TARIFF',dic_tariff_id),
        rep_fin_functions_link.get_acs_fin_curr_link(acs_financial_currency_id,'ACS_FINANCIAL_CURRENCY',1),
        rep_pc_functions.get_descodes('C_TARIFF_CATEGORY_TYPE', c_tariff_category_type),
        rep_log_functions.get_ptc_tariff_category_detail(ptc_tariff_category_id),
        rep_pc_functions.get_com_vfields_record(ptc_tariff_category_id,'PTC_TARIFF_CATEGORY'),
        rep_pc_functions.get_com_vfields_value(ptc_tariff_category_id,'PTC_TARIFF_CATEGORY')
      )
    ) into lx_data
  from ptc_tariff_category
  where ptc_tariff_category_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(TARIFF_CATEGORIES,
          XMLElement(PTC_TARIFF_CATEGORY,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_ptc_tariff_category_detail(
  Id IN ptc_tariff_category.ptc_tariff_category_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'PTC_TARIFF_CATEGORY_ID,TCD_LEVEL' as TABLE_KEY,
        ptc_tariff_category_detail_id,
        tcd_level,
        tcd_tariff_from,
        tcd_tariff_to,
        tcd_calc_rate)
    )) into lx_data
  from ptc_tariff_category_detail a
  where a.ptc_tariff_category_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(PTC_TARIFF_CATEGORY_DETAIL,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_ptc_tariff(
  Id IN gco_good.gco_good_id%TYPE,
  sale_struct_id IN ptc_tariff.dic_sale_tariff_struct_id%TYPE,
  purch_struct_id IN ptc_tariff.dic_pur_tariff_struct_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (sale_struct_id is not null or purch_struct_id is not null) then
    select
      XMLAgg(XMLElement(LIST_ITEM,
        XMLForest(
          'AFTER' as TABLE_TYPE,
          -- Le champ PAC_THIRD_ID de la clé unique sert uniquement
          -- à ne pas "écraser" les tarifs spécifiques aux tiers.
          -- Il ne doit pas figurer dans la liste des champs, car il
          -- doit avoir la valeur "NULL".
          'DIC_PUR_TARIFF_STRUCT_ID,DIC_SALE_TARIFF_STRUCT_ID,PAC_THIRD_ID,DIC_TARIFF_ID,TRF_DESCR,'||
            'ACS_FINANCIAL_CURRENCY_ID,C_TARIFF_TYPE,'||
            'C_TARIFFICATION_MODE,TRF_STARTING_DATE,TRF_ENDING_DATE' as TABLE_KEY,
          ptc_tariff_id),
        rep_pc_functions.get_dictionary('DIC_TARIFF',dic_tariff_id),
        rep_fin_functions_link.get_acs_fin_curr_link(acs_financial_currency_id,'ACS_FINANCIAL_CURRENCY',1),
        rep_pc_functions.get_descodes('C_TARIFFICATION_MODE', c_tariffication_mode),
        rep_pc_functions.get_descodes('C_TARIFF_TYPE', c_tariff_type),
        rep_pc_functions.get_descodes('C_ROUND_TYPE', c_round_type),
        XMLForest(
          trf_descr,
          trf_round_amount,
          trf_unit,
          trf_sql_conditional,
          to_char(trf_starting_date) as TRF_STARTING_DATE,
          to_char(trf_ending_date) as TRF_ENDING_DATE),
        rep_pc_functions.get_dictionary('DIC_PUR_TARIFF_STRUCT',dic_pur_tariff_struct_id),
        rep_pc_functions.get_dictionary('DIC_SALE_TARIFF_STRUCT',dic_sale_tariff_struct_id),
        XMLForest(
          trf_net_tariff,
          trf_special_tariff),
        rep_log_functions.get_ptc_tariff_table(ptc_tariff_id),
        rep_pc_functions.get_com_vfields_record(ptc_tariff_id,'PTC_TARIFF'),
        rep_pc_functions.get_com_vfields_value(ptc_tariff_id,'PTC_TARIFF')
      )) into lx_data
    from ptc_tariff
    where gco_good_id is null and pac_third_id is null
      and (dic_sale_tariff_struct_id = sale_struct_id or
           dic_pur_tariff_struct_id = purch_struct_id);
  end if;
  if Id is not null then
    select XMLConcat(lx_data,
      XMLAgg(XMLElement(LIST_ITEM,
        XMLForest(
          'AFTER' as TABLE_TYPE,
          -- Le champ PAC_THIRD_ID de la clé unique sert uniquement
          -- à ne pas "écraser" les tarifs spécifiques aux tiers.
          -- Il ne doit pas figurer dans la liste des champs, car il
          -- doit avoir la valeur "NULL".
          'GCO_GOOD_ID,PAC_THIRD_ID,DIC_TARIFF_ID,TRF_DESCR,'||
            'ACS_FINANCIAL_CURRENCY_ID,C_TARIFF_TYPE,'||
            'C_TARIFFICATION_MODE,TRF_STARTING_DATE,TRF_ENDING_DATE' as TABLE_KEY,
          ptc_tariff_id),
        rep_pc_functions.get_dictionary('DIC_TARIFF',dic_tariff_id),
        rep_fin_functions_link.get_acs_fin_curr_link(acs_financial_currency_id,'ACS_FINANCIAL_CURRENCY',1),
        rep_pc_functions.get_descodes('C_TARIFFICATION_MODE', c_tariffication_mode),
        rep_pc_functions.get_descodes('C_TARIFF_TYPE', c_tariff_type),
        rep_pc_functions.get_descodes('C_ROUND_TYPE', c_round_type),
        XMLForest(
          trf_descr,
          trf_round_amount,
          trf_unit,
          trf_sql_conditional,
          to_char(trf_starting_date) as TRF_STARTING_DATE,
          to_char(trf_ending_date) as TRF_ENDING_DATE),
        rep_pc_functions.get_dictionary('DIC_PUR_TARIFF_STRUCT',dic_pur_tariff_struct_id),
        rep_pc_functions.get_dictionary('DIC_SALE_TARIFF_STRUCT',dic_sale_tariff_struct_id),
        XMLForest(
          trf_net_tariff,
          trf_special_tariff),
        rep_log_functions.get_ptc_tariff_table(ptc_tariff_id),
        rep_pc_functions.get_com_vfields_record(ptc_tariff_id,'PTC_TARIFF'),
        rep_pc_functions.get_com_vfields_value(ptc_tariff_id,'PTC_TARIFF')
      ))) into lx_data
    from ptc_tariff
    where gco_good_id = Id and pac_third_id is null;
  else
    return null;
  end if;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(PTC_TARIFF,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_ptc_tariff_table(
  Id IN ptc_tariff.ptc_tariff_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'PTC_TARIFF_ID,TTA_FROM_QUANTITY' as TABLE_KEY,
        ptc_tariff_table_id,
        tta_from_quantity,
        tta_to_quantity,
        tta_price),
        rep_pc_functions.get_com_vfields_record(ptc_tariff_table_id,'PTC_TARIFF_TABLE'),
        rep_pc_functions.get_com_vfields_value(ptc_tariff_table_id,'PTC_TARIFF_TABLE')
    )) into lx_data
  from ptc_tariff_table
  where ptc_tariff_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(PTC_TARIFF_TABLE,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;


--
-- DOC  functions
--

function get_doc_document_xml(
  Id IN doc_document.doc_document_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(DOCUMENTS,
      XMLElement(DOC_DOCUMENT,
        XMLAttributes(
          doc_document_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'DMT_NUMBER' as TABLE_KEY,
          doc_document_id,
          dmt_number),
        rep_log_functions_link.get_doc_gauge_link(doc_gauge_id),
        rep_log_functions_link.get_doc_record_link(doc_record_id),
        rep_pac_functions_link.get_pac_third_link(pac_third_id),
        rep_asa_functions_link.get_asa_record_link(asa_record_id),
        rep_log_functions_link.get_cml_position_link(cml_position_id),
        rep_fin_functions_link.get_act_document_link(act_document_id),
        rep_pac_functions_link.get_pac_representative_link(pac_representative_id),
        rep_pac_functions_link.get_pac_sending_condition_link(pac_sending_condition_id),
        rep_pac_functions_link.get_pac_payment_condition_link(pac_payment_condition_id),
        rep_pac_functions_link.get_pac_fin_ref_link(pac_financial_reference_id),
        rep_pc_functions_link.get_pc_lang_link(pc_lang_id),
        rep_pc_functions_link.get_pc_cntry_link(pc_cntry_id),
        rep_pc_functions_link.get_pc_cntry_link(pc__pc_cntry_id,'PC__PC_CNTRY',1),
        rep_pc_functions_link.get_pc_cntry_link(pc_2_pc_cntry_id,'PC_2_PC_CNTRY', 1),
        rep_pc_functions_link.get_pc_appltxt_link(pc_appltxt_id),
        rep_pc_functions_link.get_pc_appltxt_link(pc__pc_appltxt_id,'PC__PC_APPLTXT',1),
        rep_pc_functions_link.get_pc_appltxt_link(pc_2_pc_appltxt_id,'PC_2_PC_APPLTXT',1),
        rep_fin_functions_link.get_acs_fin_curr_link(acs_financial_currency_id),
        rep_fin_functions_link.get_acs_fin_curr_link(acs_acs_financial_currency_id,'ACS_ACS_FINANCIAL_CURRENCY'),
        rep_fin_functions_link.get_acs_vat_det_account_link(acs_vat_det_account_id),
        rep_fin_functions_link.get_acs_fin_acc_s_payment_link(acs_fin_acc_s_payment_id),
        rep_fin_functions_link.get_acs_fin_account_link(acs_financial_account_id,'ACS_FINANCIAL_ACCOUNT'),
        rep_fin_functions_link.get_acs_div_account_link(acs_division_account_id,'ACS_DIVISION_ACCOUNT'),
        rep_fin_functions_link.get_acs_cpn_account_link(acs_cpn_account_id,'ACS_CPN_ACCOUNT'),
        rep_fin_functions_link.get_acs_cda_account_link(acs_cda_account_id),
        rep_fin_functions_link.get_acs_pf_account_link(acs_pf_account_id),
        rep_fin_functions_link.get_acs_pj_account_link(acs_pj_account_id),
        rep_pac_functions_link.get_pac_address_link(pac_address_id,'PAC_ADDRESS',1),
        rep_pac_functions_link.get_pac_address_link(pac_pac_address_id,'PAC_PAC_ADDRESS',1),
        rep_pac_functions_link.get_pac_address_link(pac2_pac_address_id,'PAC2_PAC_ADDRESS',1),
        rep_pc_functions.get_dictionary('DIC_GAUGE_TYPE_DOC', dic_gauge_type_doc_id),
        rep_pc_functions.get_dictionary('DIC_TYPE_SUBMISSION', dic_type_submission_id),
        rep_pc_functions.get_dictionary('DIC_DOC_FREE_1', dic_doc_free_1_id),
        rep_pc_functions.get_dictionary('DIC_DOC_FREE_2', dic_doc_free_2_id),
        rep_pc_functions.get_dictionary('DIC_DIC_DOC_FREE_3', dic_dic_doc_free_3_id),
        rep_pc_functions.get_dictionary('DIC_DOC_FREE_3', dic_doc_free_3_id),
        rep_pc_functions.get_dictionary('DIC_POS_FREE_TABLE_1', dic_pos_free_table_1_id),
        rep_pc_functions.get_dictionary('DIC_POS_FREE_TABLE_2', dic_pos_free_table_2_id),
        rep_pc_functions.get_dictionary('DIC_POS_FREE_TABLE_3', dic_pos_free_table_3_id),
        rep_pc_functions.get_dictionary('DIC_GAUGE_FREE_CODE_1', dic_gauge_free_code_1_id),
        rep_pc_functions.get_dictionary('DIC_GAUGE_FREE_CODE_2', dic_gauge_free_code_2_id),
        rep_pc_functions.get_dictionary('DIC_GAUGE_FREE_CODE_3', dic_gauge_free_code_3_id),
        rep_pc_functions.get_dictionary('DIC_TARIFF', dic_tariff_id),
        rep_pc_functions.get_descodes('C_DOCUMENT_STATUS', c_document_status),
        rep_pc_functions.get_descodes('C_CONFIRM_FAIL_REASON', c_confirm_fail_reason),
        rep_pc_functions.get_descodes('C_CREDIT_LIMIT_CHECK', c_credit_limit_check),
        rep_pc_functions.get_descodes('C_INCOTERMS', c_incoterms),
        rep_pc_functions.get_descodes('C_DMT_DELIVERY_TYP', c_dmt_delivery_typ),
        rep_pc_functions.get_descodes('C_DOC_CREATE_MODE', c_doc_create_mode),
        XMLForest(
          dmt_exported,
          dmt_financial_charging,
          dmt_protected,
          dmt_commission_extracted,
          dmt_balanced,
          to_char(dmt_date_document) as DMT_DATE_DOCUMENT,
          to_char(dmt_date_partner_document) as DMT_DATE_PARTNER_DOCUMENT,
          to_char(dmt_date_value) as DMT_DATE_VALUE,
          to_char(dmt_date_delivery) as DMT_DATE_DELIVERY,
          dmt_decimal_1, dmt_decimal_2, dmt_decimal_3,
          dmt_gau_free_number1, dmt_gau_free_number2,
          dmt_address1, dmt_address2, dmt_address3,
          dmt_town1, dmt_town2, dmt_town3,
          dmt_state1, dmt_state2, dmt_state3,
          dmt_format_city1, dmt_format_city2, dmt_format_city3,
          dmt_text_1, dmt_text_2, dmt_text_3,
          dmt_gau_free_text_short,
          dmt_edi_exported,
          dmt_partner_number,
          dmt_doi_number,
          dmt_reference,
          dmt_partner_reference,
          doc_grp_key,
          dmt_title_text,
          dmt_heading_text,
          dmt_document_text,
          dmt_gau_free_text_long,
          dmt_incoterms_place,
          dmt_credit_limit_text,
          dmt_error_message),
        rep_log_functions.get_doc_position_xml(null, doc_document_id)
      )
    ) into lx_data
  from doc_document
  where doc_document_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_doc_position_xml(
  aPositionId IN doc_position.doc_position_id%TYPE,
  aDocumentId IN doc_document.doc_document_id%TYPE default null)
  return XMLType
is
  lx_data XMLType;
begin
  if (aPositionId is null or aDocumentId is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(DOC_POSITION,
      XMLAttributes(
        doc_position_id as ID,
        pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
      XMLComment(rep_utils.GetCreationContext),
      XMLForest(
        'MAIN' asTABLE_TYPE,
        'DOC_DOCUMENT_ID,POS_NUMBER' as TABLE_KEY,
        doc_position_id),
      rep_log_functions_link.get_doc_document_link(doc_document_id),
      XMLForest(
        pos_number),
      rep_log_functions_link.get_doc_position_link(doc_doc_position_id, 'DOC_DOC_POSITION', 1),
      rep_log_functions_link.get_doc_gauge_position_link(doc_gauge_position_id),
      rep_log_functions_link.get_gco_good_link(gco_good_id),
      rep_log_functions_link.get_stm_movement_kind_link(stm_movement_kind_id),
      rep_log_functions_link.get_stm_stock_link(stm_stock_id),
      rep_log_functions_link.get_stm_location_link(stm_location_id),
      rep_log_functions_link.get_stm_stock_link(stm_stm_stock_id,'STM_STM_STOCK',1),
      rep_log_functions_link.get_stm_location_link(stm_stm_location_id,'STM_STM_LOCATION',1),
      rep_log_functions_link.get_doc_gauge_link(doc_gauge_id),
      rep_log_functions_link.get_doc_record_link(doc_record_id),
      rep_log_functions_link.get_doc_record_link(doc_doc_record_id,'DOC_DOC_RECORD'),
      rep_pac_functions_link.get_pac_third_link(pac_third_id),
      rep_asa_functions_link.get_asa_record_link(asa_record_id),
      rep_asa_functions_link.get_asa_record_comp_link(asa_record_comp_id),
      rep_asa_functions_link.get_asa_record_task_link(asa_record_task_id),
      rep_log_functions_link.get_cml_position_link(cml_position_id),
      rep_log_functions_link.get_cml_events_link(cml_events_id),
      rep_pac_functions_link.get_pac_representative_link(pac_representative_id),
      rep_ind_functions_link.get_fal_supply_request_link(fal_supply_request_id),
      rep_pc_functions_link.get_pc_appltxt_link(pc_appltxt_id),
      rep_log_functions_link.get_doc_extract_comm_link(doc_extract_commission_id),
      rep_log_functions_link.get_cml_events_link(cml_events_id),
      rep_fin_functions_link.get_acs_tax_code_link(acs_tax_code_id,'ACS_TAX_CODE'),
      rep_fin_functions_link.get_acs_fin_account_link(acs_financial_account_id,'ACS_FINANCIAL_ACCOUNT'),
      rep_fin_functions_link.get_acs_div_account_link(acs_division_account_id,'ACS_DIVISION_ACCOUNT'),
      rep_fin_functions_link.get_acs_cpn_account_link(acs_cpn_account_id,'ACS_CPN_ACCOUNT'),
      rep_fin_functions_link.get_acs_cda_account_link(acs_cda_account_id),
      rep_fin_functions_link.get_acs_pf_account_link(acs_pf_account_id),
      rep_fin_functions_link.get_acs_pj_account_link(acs_pj_account_id),
      rep_pac_functions_link.get_pac_person_link(pac_person_id,'PAC_PERSON',1),
      rep_hrm_functions_link.get_hrm_person_link(hrm_person_id),
      rep_fin_functions_link.get_fam_fixed_assets_link(fam_fixed_assets_id),
      rep_pc_functions.get_dictionary('DIC_UNIT_OF_MEASURE', dic_unit_of_measure_id),
      rep_pc_functions.get_dictionary('DIC_POS_FREE_TABLE_1', dic_pos_free_table_1_id),
      rep_pc_functions.get_dictionary('DIC_POS_FREE_TABLE_2', dic_pos_free_table_2_id),
      rep_pc_functions.get_dictionary('DIC_POS_FREE_TABLE_3', dic_pos_free_table_3_id),
      rep_pc_functions.get_dictionary('DIC_DIC_UNIT_OF_MEASURE', dic_dic_unit_of_measure_id),
      rep_pc_functions.get_dictionary('DIC_IMP_FREE1', dic_imp_free1_id),
      rep_pc_functions.get_dictionary('DIC_IMP_FREE2', dic_imp_free2_id),
      rep_pc_functions.get_dictionary('DIC_IMP_FREE3', dic_imp_free3_id),
      rep_pc_functions.get_dictionary('DIC_IMP_FREE4', dic_imp_free4_id),
      rep_pc_functions.get_dictionary('DIC_IMP_FREE5', dic_imp_free5_id),
      rep_pc_functions.get_dictionary('DIC_TARIFF', dic_tariff_id),
      rep_pc_functions.get_descodes('C_GAUGE_TYPE_POS', c_gauge_type_pos),
      rep_pc_functions.get_descodes('C_DOC_POS_STATUS', c_doc_pos_status),
      rep_pc_functions.get_descodes('C_POS_DELIVERY_TYP', c_pos_delivery_typ),
      rep_pc_functions.get_descodes('C_FAM_TRANSACTION_TYP', c_fam_transaction_typ),
      rep_pc_functions.get_descodes('C_POS_CREATE_MODE', c_pos_create_mode),
      XMLForest(
        pos_generate_movement,
        pos_stock_outage,
        pos_nom_text,
        pos_include_tax_tariff,
        pos_net_tariff,
        pos_special_tariff,
        pos_FLAT_RATE,
        pos_balanced,
        pos_gen_cml_events,
        pos_cumulative_charge,
        pos_parent_charge,
        pos_update_tariff,
        pos_update_qty_price,
        pos_create_mat,
        pos_transfert_proprietor,
        pos_price_transfered,
        pos_basis_quantity,
        pos_intermediate_quantity,
        pos_final_quantity,
        pos_value_quantity,
        pos_balance_quantity,
        pos_balance_qty_value,
        pos_basis_quantity_su,
        pos_intermediate_quantity_su,
        pos_final_quantity_su,
        pos_net_weight,
        pos_gross_weight,
        pos_convert_factor,
        pos_convert_factor2,
        pos_util_coeff,
        pos_unit_cost_price,
        pos_ref_unit_value,
        pos_gross_unit_value,
        pos_gross_unit_value2,
        pos_gross_unit_value_incl,
        pos_gross_value,
        pos_gross_value_b,
        pos_gross_value_v,
        pos_gross_value_incl,
        pos_gross_value_incl_b,
        pos_gross_value_incl_v,
        pos_discount_unit_value,
        pos_discount_amount,
        pos_charge_amount,
        pos_vat_amount,
        pos_vat_base_amount,
        pos_vat_amount_v,
        pos_net_unit_value,
        pos_net_unit_value_incl,
        pos_net_value_excl,
        pos_net_value_excl_b,
        pos_net_value_excl_v,
        pos_net_value_incl,
        pos_net_value_incl_b,
        pos_net_value_incl_v,
        pos_tariff_unit,
        pos_tariff_initialized,
        to_char(pos_date_partner_document) as POS_DATE_PARTNER_DOCUMENT,
        to_char(pos_date_1) as POS_DATE_1,
        to_char(pos_date_2) as POS_DATE_2,
        to_char(pos_date_3) as POS_DATE_3,
        pos_text_1, pos_text_2, pos_text_3,
        pos_decimal_1, pos_decimal_2, pos_decimal_3,
        pos_imf_number_2, pos_imf_number_3, pos_imf_number_4, pos_imf_number_5),
      rep_log_functions.get_doc_position_detail_xml(null, doc_position_id)
    ) order by pos_number) into lx_data
  from doc_position
  where
    doc_position_id = Nvl(aPositionId, doc_position_id) and
    doc_document_id = Nvl(aDocumentId, doc_document_id);
  if (lx_data is not null) then
    select XMLElement(POSITIONS, lx_data)
    into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_doc_position_detail_xml(
  aPositionDetailId IN doc_position_detail.doc_position_detail_id%TYPE,
  aPositionId IN doc_position.doc_position_id%TYPE default null)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLAgg(XMLElement(DOC_POSITION_DETAIL,
      XMLAttributes(
        doc_position_detail_id as ID,
        pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
      XMLComment(rep_utils.GetCreationContext),
      XMLForest(
        'MAIN' as TABLE_TYPE,
        'DOC_POSITION_DETAIL_ID' as TABLE_KEY,
        doc_position_detail_id),
      rep_log_functions_link.get_doc_document_link(doc_document_id),
      rep_log_functions_link.get_doc_position_link(doc_position_id,'DOC_POSITION',1),
      rep_log_functions_link.get_doc_position_detail_link(doc_doc_position_detail_id,'DOC_DOC_POSITION_DETAIL_ID',1),
      rep_log_functions_link.get_doc_position_detail_link(doc2_doc_position_detail_id,'DOC2_DOC_POSITION_DETAIL_ID',1),
      rep_log_functions_link.get_gco_good_link(gco_good_id),
      rep_log_functions_link.get_stm_location_link(stm_location_id),
      rep_log_functions_link.get_stm_location_link(stm_stm_location_id,'STM_STM_LOCATION',1),
      rep_log_functions_link.get_doc_gauge_link(doc_gauge_id),
      rep_log_functions_link.get_doc_gauge_flow_link(doc_gauge_flow_id),
      rep_log_functions_link.get_doc_gauge_copy_link(doc_gauge_copy_id),
      rep_log_functions_link.get_doc_gauge_receipt_link(doc_gauge_receipt_id),
      rep_pac_functions_link.get_pac_third_link(pac_third_id),
      rep_ind_functions_link.get_fal_supply_request_link(fal_supply_request_id),
      rep_ind_functions_link.get_fal_network_link_link(fal_network_link_id),
      rep_ind_functions_link.get_fal_network_link_link(fal_schedule_step_id),
      rep_log_functions_link.get_gco_characterization_link(gco_characterization_id),
      rep_log_functions_link.get_gco_characterization_link(gco_gco_characterization_id,'GCO_GCO_CHARACTERIZATION',1),
      rep_log_functions_link.get_gco_characterization_link(gco2_gco_characterization_id,'GCO2_GCO_CHARACTERIZATION',1),
      rep_log_functions_link.get_gco_characterization_link(gco3_gco_characterization_id,'GCO3_GCO_CHARACTERIZATION',1),
      rep_log_functions_link.get_gco_characterization_link(gco4_gco_characterization_id,'GCO4_GCO_CHARACTERIZATION',1),
      rep_pc_functions.get_dictionary('DIC_PDE_FREE_TABLE_1',dic_pde_free_table_1_id),
      rep_pc_functions.get_dictionary('DIC_PDE_FREE_TABLE_2',dic_pde_free_table_2_id),
      rep_pc_functions.get_dictionary('DIC_PDE_FREE_TABLE_3',dic_pde_free_table_3_id),
      rep_pc_functions.get_dictionary('DIC_DELAY_UPDATE_TYPE',dic_delay_update_type_id),
      rep_pc_functions.get_descodes('C_PDE_CREATE_MODE',c_pde_create_mode),
      XMLForest(
        pde_generate_movement,
        pde_balance_parent,
        pde_transfert_proprietor,
        pde_basis_quantity,
        pde_intermediate_quantity,
        pde_final_quantity,
        pde_balance_quantity,
        pde_movement_quantity,
        pde_movement_value,
        pde_balance_quantity_parent,
        pde_decimal_1, pde_decimal_2, pde_decimal_3,
        pde_basis_quantity_su,
        pde_intermediate_quantity_su,
        pde_final_quantity_su,
        to_char(pde_basis_delay) as PDE_BASIS_DELAY,
        to_char(pde_intermediate_delay) as PDE_INTERMEDIATE_DELAY,
        to_char(pde_final_delay) as PDE_FINAL_DELAY,
        to_char(pde_date_1) as PDE_DATE_1,
        to_char(pde_date_2) as PDE_DATE_2,
        to_char(pde_date_3) as PDE_DATE_3,
        to_char(pde_sqm_accepted_delay) as PDE_SQM_ACCEPTED_DELAY,
        pde_basis_delay_w, pde_basis_delay_m,
        pde_intermediate_delay_w, pde_intermediate_delay_m,
        pde_final_delay_w, pde_final_delay_m,
        pde_characterization_value_1, pde_characterization_value_2, pde_characterization_value_3,
        pde_characterization_value_4, pde_characterization_value_5,
        pde_text_1, pde_text_2, pde_text_3,
        pde_delay_update_text,
        pde_piece,
        pde_set,
        pde_version,
        pde_chronological,
        pde_std_char_1, pde_std_char_2, pde_std_char_3, pde_std_char_4, pde_std_char_5)
    ) order by doc_position_detail_id) into lx_data
  from doc_position_detail
  where
    doc_position_detail_id = Nvl(aPositionDetailId, doc_position_detail_id) and
    doc_position_id = Nvl(aPositionId, doc_position_id);
  if (lx_data is not null) then
    select XMLElement(POSITION_DETAILS, lx_data)
    into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_doc_record_address(
  Id IN doc_record.doc_record_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'DOC_RECORD_ID, PAC_PERSON_ID, DIC_RCO_LINK_TYPE_ID' as TABLE_KEY,
        doc_record_address_id),
      rep_pac_functions_link.get_pac_person_link(pac_person_id,'PAC_PERSON',1),
      rep_pc_functions.get_dictionary('DIC_RCO_LINK_TYPE',dic_rco_link_type_id),
      XMLForest(
        rca_remark)
    )) into lx_data
  from doc_record_address
  where doc_record_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(DOC_RECORD_ADDRESS,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_doc_record_link(
  Id IN doc_record.doc_record_id%TYPE)
  return XMLType
is
  lx_data XMLType;
  lv_rco_type DOC_RECORD.C_RCO_TYPE%type;
  lv_gal_rco_categories constant varchar2(25) := '01,02,03,04,05,06,07,08'; -- Catégories de dossier pour la gestion des affaires (GAL).
begin
  if (Id is null) then
    return null;
  end if;
  -- Récupérer le type de dossier
  lv_rco_type := FWK_I_LIB_ENTITY.getvarchar2fieldfrompk(FWK_TYP_DOC_ENTITY.gcDocRecord, 'C_RCO_TYPE', Id);
  if instr(lv_gal_rco_categories, lv_rco_type) > 0 then
    select
      XMLAgg(XMLElement(LIST_ITEM,
        XMLForest(
          'AFTER' as TABLE_TYPE,
          'DOC_RECORD_FATHER_ID, DOC_RECORD_SON_ID, DOC_RECORD_CATEGORY_LINK_ID' as TABLE_KEY,
          doc_record_link_id),
        rep_log_functions_link.get_doc_record_inherit_link(doc_record_father_id, 'DOC_RECORD_FATHER'),
        rep_log_functions_link.get_doc_record_cat_lnk_link(doc_record_category_link_id),
        XMLForest(
          rcl_comment)
      )) into lx_data
     from doc_record_link
     where doc_record_son_id = Id;
  else
    select
      XMLAgg(XMLElement(LIST_ITEM,
        XMLForest(
          'AFTER' as TABLE_TYPE,
          'DOC_RECORD_FATHER_ID, DOC_RECORD_SON_ID, DOC_RECORD_CATEGORY_LINK_ID' as TABLE_KEY,
          doc_record_link_id),
        rep_log_functions_link.get_doc_record_inherit_link(doc_record_son_id, 'DOC_RECORD_SON'),
        rep_log_functions_link.get_doc_record_cat_lnk_link(doc_record_category_link_id),
        XMLForest(
          rcl_comment)
      )) into lx_data
     from doc_record_link
     where doc_record_father_id = Id;
  end if;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(DOC_RECORD_LINK,
      case
        when instr(lv_gal_rco_categories, lv_rco_type) > 0
           then XMLForest('DOC_RECORD_SON_ID=DOC_RECORD_ID' as TABLE_MAPPING)
        else XMLForest('DOC_RECORD_FATHER_ID=DOC_RECORD_ID' as TABLE_MAPPING)
      end,
      XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end get_doc_record_link;

function get_doc_record_xml(
  Id doc_record.doc_record_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(DOCUMENTS,
      XMLElement(DOC_RECORD,
        XMLAttributes(
          doc_record_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'RCO_TITLE' as TABLE_KEY,
          doc_record_id,
          rco_title),
        rep_pac_functions_link.get_pac_third_link(pac_third_id),
        rep_pc_functions.get_dictionary('DIC_ACCOUNTABLE_GROUP',dic_accountable_group_id),
        XMLForest(
          rco_description),
        rep_pc_functions.get_dictionary('DIC_RECORD1',dic_record1_id),
        rep_pc_functions.get_dictionary('DIC_RECORD2',dic_record2_id),
        rep_pc_functions.get_dictionary('DIC_RECORD3',dic_record3_id),
        rep_pc_functions.get_dictionary('DIC_RECORD4',dic_record4_id),
        rep_pc_functions.get_dictionary('DIC_RECORD5',dic_record5_id),
        rep_pc_functions.get_dictionary('DIC_RECORD6',dic_record6_id),
        rep_pc_functions.get_dictionary('DIC_RECORD7',dic_record7_id),
        rep_pc_functions.get_dictionary('DIC_RECORD8',dic_record8_id),
        rep_pc_functions.get_dictionary('DIC_RECORD9',dic_record9_id),
        rep_pc_functions.get_dictionary('DIC_RECORD10',dic_record10_id),
        XMLForest(
          rco_boolean1, rco_boolean2, rco_boolean3, rco_boolean4, rco_boolean5,
            rco_boolean6, rco_boolean7, rco_boolean8, rco_boolean9, rco_boolean10,
          rco_alpha_short1, rco_alpha_short2, rco_alpha_short3, rco_alpha_short4, rco_alpha_short5,
            rco_alpha_short6, rco_alpha_short7, rco_alpha_short8, rco_alpha_short9, rco_alpha_short10,
          rco_alpha_long1, rco_alpha_long2, rco_alpha_long3, rco_alpha_long4, rco_alpha_long5,
            rco_alpha_long6, rco_alpha_long7, rco_alpha_long8, rco_alpha_long9, rco_alpha_long10,
          to_char(rco_date1) as RCO_DATE1,
          to_char(rco_date2) as RCO_DATE2,
          to_char(rco_date3) as RCO_DATE3,
          to_char(rco_date4) as RCO_DATE4,
          to_char(rco_date5) as RCO_DATE5,
          to_char(rco_date6) as RCO_DATE6,
          to_char(rco_date7) as RCO_DATE7,
          to_char(rco_date8) as RCO_DATE8,
          to_char(rco_date9) as RCO_DATE9,
          to_char(rco_date10) as RCO_DATE10,
          rco_decimal1, rco_decimal2, rco_decimal3, rco_decimal4, rco_decimal5,
            rco_decimal6, rco_decimal7, rco_decimal8, rco_decimal9, rco_decimal10,
          rco_number),
        rep_pc_functions.get_dictionary('DIC_PERSON_POLITNESS',dic_person_politness_id),
        rep_pc_functions_link.get_pc_lang_link(pc_lang_id),
        rep_pc_functions_link.get_pc_cntry_link(pc_cntry_id),
        rep_pac_functions_link.get_pac_representative_link(pac_representative_id),
        XMLForest(
          rco_name,
          rco_forename,
          rco_activity,
          rco_zipcode,
          rco_phone,
          rco_fax,
          rco_add_format,
          rco_state,
          rco_address,
          rco_agreement_number),
        rep_pc_functions.get_descodes('C_RCO_STATUS',c_rco_status),
        rep_pc_functions.get_descodes('C_RCO_TYPE', c_rco_type),
        rep_log_functions_link.get_doc_record_category_link(doc_record_category_id),
        rep_log_functions_link.get_gco_good_link(rco_machine_good_id,'RCO_MACHINE_GOOD'),
        XMLForest(
          to_char(rco_supplier_warranty_end) as RCO_SUPPLIERS_WARRANTY_END,
          rco_machine_long_descr,
          rco_machine_free_descr,
          rco_machine_remark,
          rco_machine_comment,
          rco_supplier_serial_number,
          rco_sale_price,
          rco_cost_price,
          rco_estimate_price),
        rep_pc_functions.get_descodes('C_ASA_MACHINE_STATE',c_asa_machine_state),
        XMLForest(
          to_char(rco_starting_date) as RCO_STARTING_DATE,
          to_char(rco_ending_date) as RCO_ENDING_DATE,
          rco_dic_association_type),
        rep_fin_functions_link.get_acs_fin_account_link(acs_financial_account_id, 'ACS_FINANCIAL_ACCOUNT'),
        rep_fin_functions_link.get_acs_div_account_link(acs_division_account_id, 'ACS_DIVISION_ACCOUNT'),
        rep_fin_functions_link.get_acs_cpn_account_link(acs_cpn_account_id, 'ACS_CPN_ACCOUNT'),
        rep_fin_functions_link.get_acs_cda_account_link(acs_cda_account_id),
        rep_fin_functions_link.get_acs_pf_account_link(acs_pf_account_id),
        rep_fin_functions_link.get_acs_pj_account_link(acs_pj_account_id),
        rep_pc_functions.get_descodes('C_ASA_GUARANTY_UNIT',c_asa_guaranty_unit),
        XMLForest(
          rco_warranty_pc_appltxt_id,
          to_char(rco_supplier_warranty_start) as RCO_SUPPLIER_WARRANTY_START,
          rco_supplier_warranty_term,
          rco_warranty_text),
        rep_pc_functions.get_dictionary('DIC_RCO_MACHINE1',dic_rco_machine1_id),
        rep_pc_functions.get_dictionary('DIC_RCO_MACHINE2',dic_rco_machine2_id),
        rep_pc_functions.get_dictionary('DIC_RCO_MACHINE3',dic_rco_machine3_id),
        rep_pc_functions.get_dictionary('DIC_RCO_MACHINE4',dic_rco_machine4_id),
        rep_pc_functions.get_dictionary('DIC_RCO_MACHINE5',dic_rco_machine5_id),
        rep_pc_functions.get_dictionary('DIC_RCO_MACHINE6',dic_rco_machine6_id),
        rep_pc_functions.get_dictionary('DIC_RCO_MACHINE7',dic_rco_machine7_id),
        rep_pc_functions.get_dictionary('DIC_RCO_MACHINE8',dic_rco_machine8_id),
        rep_pc_functions.get_dictionary('DIC_RCO_MACHINE9',dic_rco_machine9_id),
        rep_pc_functions.get_dictionary('DIC_RCO_MACHINE10',dic_rco_machine10_id),
        XMLForest(
          rco_machine_boolean1, rco_machine_boolean2, rco_machine_boolean3, rco_machine_boolean4, rco_machine_boolean5,
            rco_machine_boolean6, rco_machine_boolean7, rco_machine_boolean8, rco_machine_boolean9, rco_machine_boolean10,
          rco_machine_alpha_short1, rco_machine_alpha_short2, rco_machine_alpha_short3, rco_machine_alpha_short4, rco_machine_alpha_short5,
            rco_machine_alpha_short6, rco_machine_alpha_short7, rco_machine_alpha_short8, rco_machine_alpha_short9, rco_machine_alpha_short10,
          rco_machine_alpha_long1, rco_machine_alpha_long2, rco_machine_alpha_long3, rco_machine_alpha_long4, rco_machine_alpha_long5,
            rco_machine_alpha_long6, rco_machine_alpha_long7, rco_machine_alpha_long8, rco_machine_alpha_long9, rco_machine_alpha_long10,
          to_char(rco_machine_date1) as RCO_MACHINE_DATE1,
          to_char(rco_machine_date2) as RCO_MACHINE_DATE2,
          to_char(rco_machine_date3) as RCO_MACHINE_DATE3,
          to_char(rco_machine_date4) as RCO_MACHINE_DATE4,
          to_char(rco_machine_date5) as RCO_MACHINE_DATE5,
          to_char(rco_machine_date6) as RCO_MACHINE_DATE6,
          to_char(rco_machine_date7) as RCO_MACHINE_DATE7,
          to_char(rco_machine_date8) as RCO_MACHINE_DATE8,
          to_char(rco_machine_date9) as RCO_MACHINE_DATE9,
          to_char(rco_machine_date10) as RCO_MACHINE_DATE10,
          rco_machine_decimal1, rco_machine_decimal2, rco_machine_decimal3, rco_machine_decimal4, rco_machine_decimal5,
            rco_machine_decimal6, rco_machine_decimal7, rco_machine_decimal8, rco_machine_decimal9, rco_machine_decimal10),
        rep_log_functions.get_doc_record_address(doc_record_id),
        rep_log_functions.get_doc_record_link(doc_record_id),
        rep_pc_functions.get_com_vfields_value(doc_record_id,'DOC_RECORD'),
        rep_pc_functions.get_com_vfields_record(doc_record_id,'DOC_RECORD')
      )
    ) into lx_data
  from doc_record
  where doc_record_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(DOCUMENTS,
          XMLElement(DOC_RECORD,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;


function get_doc_record_category_descr(
  Id IN doc_record_category.doc_record_category_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'DOC_RECORD_CATEGORY_ID, PC_LANG_ID' as TABLE_KEY,
        doc_record_category_descr_id,
        l.lanid,
        rcd_descr)
    )) into lx_data
  from pcs.pc_lang l, doc_record_category_descr d
  where d.doc_record_category_id = Id and l.pc_lang_id = d.pc_lang_id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(DOC_RECORD_CATEGORY_DESCR,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;


function get_doc_record_category_link(
  Id IN doc_record_category.doc_record_category_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'C_RCO_LINK_TYPE,C_RCO_LINK_CODE,DOC_RECORD_CAT_FATHER_ID,'||
          'DOC_RECORD_CAT_DAUGHTER_ID,DOC_RECORD_CAT_LINK_TYPE_ID' TABLE_KEY,
        doc_record_category_link_id,
        doc_record_cat_father_id),
      rep_pc_functions.get_descodes('C_RCO_LINK_TYPE', c_rco_link_type),
      rep_pc_functions.get_descodes('C_RCO_LINK_CODE', c_rco_link_code),
      rep_log_functions_link.get_rco_cat_inherit_link(doc_record_cat_daughter_id, 'DOC_RECORD_CAT_DAUGHTER'),
      rep_log_functions_link.get_rco_cat_lnk_type_link(doc_record_cat_link_type_id)
    )) into lx_data
  from doc_record_category_link
  where doc_record_cat_father_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(DOC_RECORD_CATEGORY_LINK,
        XMLForest(
          'DOC_RECORD_CAT_FATHER_ID=DOC_RECORD_CATEGORY_ID' as TABLE_MAPPING),
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;


function get_doc_record_category_xml(
  Id IN doc_record_category.doc_record_category_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(DOCUMENT_CATEGORIES,
      XMLElement(DOC_RECORD_CATEGORY,
        XMLAttributes(
          doc_record_category_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'RCY_KEY' as TABLE_KEY,
          doc_record_category_id),
        rep_pc_functions.get_descodes('C_RCO_STATUS',c_rco_status),
        rep_pc_functions.get_descodes('C_RCO_TYPE', c_rco_type),
        XMLForest(
          rcy_descr,
          rcy_key),
        rep_log_functions.get_doc_record_category_descr(doc_record_category_id),
        rep_log_functions.get_doc_record_category_link(doc_record_category_id),
        rep_pc_functions.get_com_vfields_record(doc_record_category_id,'DOC_RECORD_CATEGORY'),
        rep_pc_functions.get_com_vfields_value(doc_record_category_id,'DOC_RECORD_CATEGORY')
      )
    ) into lx_data
  from doc_record_category
  where doc_record_category_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(DOCUMENT_CATEGORIES,
          XMLElement(DOC_RECORD_CATEGORY,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;


function get_doc_rec_cat_lnk_type_descr(
  Id IN doc_record_cat_link_type.doc_record_cat_link_type_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'DOC_RECORD_CAT_LINK_TYPE_ID, PC_LANG_ID' as TABLE_KEY,
        doc_rec_cat_lnk_type_descr_id,
        l.lanid,
        rld_descr,
        rld_downward_semantic,
        rld_upward_semantic)
    )) into lx_data
  from pcs.pc_lang l, doc_rec_cat_lnk_type_descr d
  where d.doc_record_cat_link_type_id = Id and l.pc_lang_id = d.pc_lang_id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(DOC_REC_CAT_LNK_TYPE_DESCR,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;


function get_rco_cat_lnk_type_xml(
  Id doc_record_cat_link_type.doc_record_cat_link_type_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(DOC_CATEGORIES_TYPE_LINKS,
      XMLElement(DOC_RECORD_CAT_LINK_TYPE,
        XMLAttributes(
          doc_record_cat_link_type_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'RLT_DESCR' as TABLE_KEY,
          doc_record_cat_link_type_id,
          rlt_descr,
          rlt_downward_semantic,
          rlt_upward_semantic),
        rep_log_functions.get_doc_rec_cat_lnk_type_descr(doc_record_cat_link_type_id)
      )
    ) into lx_data
  from doc_record_cat_link_type
  where doc_record_cat_link_type_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(DOC_CATEGORIES_TYPE_LINKS,
          XMLElement(DOC_RECORD_CAT_LINK_TYPE,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_doc_gauge_signatory_xml(
  Id IN doc_gauge_signatory.doc_gauge_signatory_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(DOCUMENT_GAUGES,
      XMLElement(DOC_GAUGE_SIGNATORY,
        XMLAttributes(
          doc_gauge_signatory_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'GAG_NAME,GAG_FUNCTION' as TABLE_KEY,
          doc_gauge_signatory_id,
          gag_name,
          gag_function,
          gag_signature),
        rep_pc_functions.get_com_vfields_record(doc_gauge_signatory_id,'DOC_GAUGE_SIGNATORY'),
        rep_pc_functions.get_com_vfields_value(doc_gauge_signatory_id,'DOC_GAUGE_SIGNATORY')
      )
    ) into lx_data
  from doc_gauge_signatory
  where doc_gauge_signatory_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(DOCUMENT_GAUGES,
          XMLElement(DOC_GAUGE_SIGNATORY,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_doc_gauge_numbering_xml(
  Id IN doc_gauge_numbering.doc_gauge_numbering_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(DOCUMENT_GAUGES,
      XMLElement(DOC_GAUGE_NUMBERING,
        XMLAttributes(
          doc_gauge_numbering_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'GAN_DESCRIBE' as TABLE_KEY,
          doc_gauge_numbering_id,
          gan_addendum,
          gan_describe,
          gan_free_number,
          gan_increment,
          gan_last_number,
          gan_modify_number,
          gan_number,
          gan_prefix,
          gan_range_number,
          gan_suffix),
        rep_pc_functions.get_com_vfields_record(doc_gauge_numbering_id,'DOC_GAUGE_NUMBERING'),
        rep_pc_functions.get_com_vfields_value(doc_gauge_numbering_id,'DOC_GAUGE_NUMBERING')
      )
    ) into lx_data
  from doc_gauge_numbering
  where doc_gauge_numbering_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(DOCUMENT_GAUGES,
          XMLElement(DOC_GAUGE_NUMBERING,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_doc_gauge_xml(
  Id IN doc_gauge.doc_gauge_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(DOCUMENT_GAUGES,
      XMLElement(DOC_GAUGE,
        XMLAttributes(
          doc_gauge_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'C_ADMIN_DOMAIN,C_GAUGE_TYPE,GAU_DESCRIBE' as TABLE_KEY,
          doc_gauge_id),
        rep_log_functions_link.get_doc_gauge_numbering_link(doc_gauge_numbering_id),
        rep_log_functions_link.get_doc_gauge_signatory_link(doc_gauge_signatory_id, 'DOC_GAUGE_SIGNATORY', 1),
        rep_log_functions_link.get_doc_gauge_signatory_link(doc_doc_gauge_signatory_id, 'DOC_DOC_GAUGE_SIGNATORY', 1),
        rep_pac_functions_link.get_pac_third_link(pac_third_id),
        rep_pac_functions_link.get_pac_third_link(pac_third_delivery_id, 'PAC_THIRD_DELIVERY'),
        rep_pac_functions_link.get_pac_third_link(pac_third_aci_id, 'PAC_THIRD_ACI'),
        rep_pc_functions_link.get_pc_appltxt_link(pc_appltxt_id, 'PC_APPLTXT'),
        rep_pc_functions_link.get_pc_appltxt_link(pc__pc_appltxt_id, 'PC__PC_APPLTXT', 1),
        rep_pc_functions_link.get_pc_appltxt_link(pc_3_pc_appltxt_id, 'PC_3_PC_APPLTXT', 1),
        rep_pc_functions_link.get_pc_appltxt_link(pc_2_pc_appltxt_id, 'PC_2_PC_APPLTXT', 1),
        rep_pc_functions_link.get_pc_appltxt_link(pc_4_pc_appltxt_id, 'PC_4_PC_APPLTXT', 1),
        rep_pc_functions_link.get_pc_appltxt_link(pc_5_pc_appltxt_id, 'PC_5_PC_APPLTXT', 1),
        rep_pc_functions_link.get_pc_appltxt_link(pc_6_pc_appltxt_id, 'PC_6_PC_APPLTXT', 1),
        rep_pc_functions_link.get_pc_appltxt_link(pc_7_pc_appltxt_id, 'PC_7_PC_APPLTXT', 1),
        rep_pc_functions.get_descodes('C_ADMIN_DOMAIN',C_ADMIN_DOMAIN),
        rep_pc_functions.get_descodes('C_APPLI_COPY_SUPP',C_APPLI_COPY_SUPP),
        rep_pc_functions.get_descodes('C_DIRECTION_NUMBER',C_DIRECTION_NUMBER),
        rep_pc_functions.get_descodes('C_GAUGE_FORM_TYPE',C_GAUGE_FORM_TYPE),
        rep_pc_functions.get_descodes('C_GAUGE_RECORD_VERIFY',C_GAUGE_RECORD_VERIFY),
        rep_pc_functions.get_descodes('C_GAUGE_STATUS',C_GAUGE_STATUS),
        rep_pc_functions.get_descodes('C_GAUGE_TYPE',C_GAUGE_TYPE),
        rep_pc_functions.get_descodes('C_GAUGE_TYPE_COMMENT_VISIBLE', C_GAUGE_TYPE_COMMENT_VISIBLE),
        rep_pc_functions.get_descodes('C_GAU_AUTO_CREATE_RECORD',C_GAU_AUTO_CREATE_RECORD),
        rep_pc_functions.get_descodes('C_GAU_INCOTERMS',C_GAU_INCOTERMS),
        rep_pc_functions.get_descodes('C_GAU_THIRD_VAT',C_GAU_THIRD_VAT),
        rep_pc_functions.get_descodes('C_PACKING_TYPE',C_PACKING_TYPE),
        rep_pc_functions.get_dictionary('DIC_ADDRESS_TYPE',dic_address_type_id),
        rep_pc_functions.get_dictionary('DIC_ADDRESS_TYPE1',dic_address_type1_id, 'DIC_ADDRESS_TYPE'),
        rep_pc_functions.get_dictionary('DIC_ADDRESS_TYPE2',dic_address_type2_id, 'DIC_ADDRESS_TYPE'),
        rep_pc_functions.get_dictionary('DIC_GAUGE_CATEG',dic_gauge_categ_id),
        rep_pc_functions.get_dictionary('DIC_GAUGE_FREE_CODE_1', dic_gauge_free_code_1_id),
        rep_pc_functions.get_dictionary('DIC_GAUGE_FREE_CODE_2', dic_gauge_free_code_2_id),
        rep_pc_functions.get_dictionary('DIC_GAUGE_FREE_CODE_3', dic_gauge_free_code_3_id),
        rep_pc_functions.get_dictionary('DIC_GAUGE_GROUP',dic_gauge_group_id),
        rep_pc_functions.get_dictionary('DIC_GAUGE_TYPE_DOC',dic_gauge_type_doc_id),
        rep_pc_functions.get_dictionary('DIC_GAU_STATISTIC_1', dic_gau_statistic_1_id),
        rep_pc_functions.get_dictionary('DIC_GAU_STATISTIC_2', dic_gau_statistic_2_id),
        rep_pc_functions.get_dictionary('DIC_GAU_STATISTIC_3', dic_gau_statistic_3_id),
        rep_pc_functions.get_dictionary('DIC_TYPE_DOC_CUSTOM', dic_type_doc_custom_id),
        XMLForest(
          appli_copy_supp1, appli_copy_supp2, appli_copy_supp3, appli_copy_supp4,
            appli_copy_supp5, appli_copy_supp6, appli_copy_supp7, appli_copy_supp8,
            appli_copy_supp9, appli_copy_supp10,
          gau_addr1_comment_visible, gau_addr2_comment_visible, gau_addr3_comment_visible,
          gau_always_show_comment,
          gau_appltxt_3, gau_appltxt_4, gau_appltxt_5, gau_appltxt_6, gau_appltxt_7,
          gau_asa_record,
          gau_boolean_1, gau_boolean_2, gau_boolean_3,
          gau_cancel_status,
          gau_collate_copies,
          gau_collate_copies1, gau_collate_copies2, gau_collate_copies3, gau_collate_copies4,
            gau_collate_copies5, gau_collate_copies6, gau_collate_copies7, gau_collate_copies8,
            gau_collate_copies9, gau_collate_copies10,
          gau_collate_printed_reports,
          gau_confirm_cancel,
          gau_confirm_status,
          gau_copy_source_free_data,
          gau_describe,
          gau_display_seq1, gau_display_seq2, gau_display_seq3,
          gau_dossier,
          gau_edifact,
          gau_edit_bool,
          gau_edit_bool1, gau_edit_bool2, gau_edit_bool3, gau_edit_bool4, gau_edit_bool5,
            gau_edit_bool6, gau_edit_bool7, gau_edit_bool8, gau_edit_bool9, gau_edit_bool10,
          gau_edit_name,
          gau_edit_name1, gau_edit_name2, gau_edit_name3, gau_edit_name4, gau_edit_name5,
          gau_edit_name6, gau_edit_name7, gau_edit_name8, gau_edit_name9, gau_edit_name10,
          gau_edit_text,
          gau_edit_text1, gau_edit_text2, gau_edit_text3, gau_edit_text4, gau_edit_text5,
            gau_edit_text6, gau_edit_text7, gau_edit_text8, gau_edit_text9, gau_edit_text10,
          gau_expiry,
          gau_expiry_nbr,
          gau_free_bool1, gau_free_bool2,
          gau_free_data_use,
          to_char(gau_free_date1) as GAU_FREE_DATE1,
          to_char(gau_free_date2) as GAU_FREE_DATE2,
          gau_free_number1, gau_free_number2,
          gau_free_text_long,
          gau_free_text_short,
          gau_history,
          gau_incoterms,
          gau_init_dmt_date_document,
          gau_init_dmt_date_falling_due,
          gau_init_dmt_date_value,
          gau_logo,
          gau_numbering,
          gau_numeric_1, gau_numeric_2, gau_numeric_3,
          gau_par_collates_copies_1, gau_par_collates_copies_2, gau_par_collates_copies_3,
            gau_par_collates_copies_4, gau_par_collates_copies_5, gau_par_collates_copies_6,
            gau_par_collates_copies_7, gau_par_collates_copies_8, gau_par_collates_copies_9,
            gau_par_collates_copies_10, gau_par_collates_copies_11,
          gau_par_copy_sup_1, gau_par_copy_sup_2, gau_par_copy_sup_3, gau_par_copy_sup_4,
            gau_par_copy_sup_5, gau_par_copy_sup_6, gau_par_copy_sup_7, gau_par_copy_sup_8,
            gau_par_copy_sup_9, gau_par_copy_sup_10, gau_par_copy_sup_11,
          gau_par_edit_bool1, gau_par_edit_bool2, gau_par_edit_bool3, gau_par_edit_bool4,
            gau_par_edit_bool5, gau_par_edit_bool6, gau_par_edit_bool7, gau_par_edit_bool8,
            gau_par_edit_bool9, gau_par_edit_bool10, gau_par_edit_bool11,
          gau_par_edit_name_1, gau_par_edit_name_2, gau_par_edit_name_3, gau_par_edit_name_4,
            gau_par_edit_name_5, gau_par_edit_name_6, gau_par_edit_name_7, gau_par_edit_name_8,
            gau_par_edit_name_9, gau_par_edit_name_10, gau_par_edit_name_11,
          gau_par_edit_text_1, gau_par_edit_text_2, gau_par_edit_text_3, gau_par_edit_text_4,
            gau_par_edit_text_5, gau_par_edit_text_6, gau_par_edit_text_7, gau_par_edit_text_8,
            gau_par_edit_text_9, gau_par_edit_text_10, gau_par_edit_text_11,
          gau_qas_control,
          gau_ref_partner,
          gau_report_print_test,
          gau_report_print_test1, gau_report_print_test2, gau_report_print_test3, gau_report_print_test4,
          gau_report_print_test5, gau_report_print_test6, gau_report_print_test7, gau_report_print_test8,
          gau_report_print_test9, gau_report_print_test10,
          gau_second_adress,
          gau_show_forms_on_confirm,
          gau_show_forms_on_insert,
          gau_show_forms_on_update,
          gau_third_adress,
          gau_traveller,
          gau_use_managed_data,
          gauge_form_type1, gauge_form_type2, gauge_form_type3, gauge_form_type4,
          gauge_form_type5, gauge_form_type6, gauge_form_type7, gauge_form_type8,
          gauge_form_type9, gauge_form_type10),
        rep_log_functions.get_doc_gauge_structured(doc_gauge_id),
        rep_log_functions.get_doc_gauge_description(doc_gauge_id),
        rep_log_functions.get_doc_gauge_managed_data(doc_gauge_id),
        rep_log_functions.get_doc_gauge_create_proc(doc_gauge_id),
        rep_log_functions.get_doc_gauge_position(doc_gauge_id),
        rep_pc_functions.get_com_vfields_record(doc_gauge_id,'DOC_GAUGE'),
        rep_pc_functions.get_com_vfields_value(doc_gauge_id,'DOC_GAUGE')
      )
    ) into lx_data
  from doc_gauge
  where doc_gauge_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(DOCUMENT_GAUGES,
          XMLElement(DOC_GAUGE,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_doc_gauge_description(
  Id IN doc_gauge.doc_gauge_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'DOC_GAUGE_ID,PC_LANG_ID' as TABLE_KEY,
        doc_gauge_description_id,
        lan.lanid,
        gad.gad_describe,
        gad.gad_free_description)
    )) into lx_data
  from pcs.pc_lang lan, doc_gauge_description gad
  where gad.doc_gauge_id = Id and gad.pc_lang_id = lan.pc_lang_id;

  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(DOC_GAUGE_DESCRIPTION,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_doc_gauge_managed_data(
  Id IN doc_gauge.doc_gauge_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'DOC_GAUGE_ID,C_DATA_TYP' as TABLE_KEY,
        doc_gauge_managed_data_id),
      rep_pc_functions.get_descodes('C_DATA_TYP', c_data_typ),
      XMLForest(
        gma_mandatory)
    ) order by c_data_typ) into lx_data
  from doc_gauge_managed_data
  where doc_gauge_id = Id;

  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(DOC_GAUGE_MANAGED_DATA,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_doc_gauge_create_proc(
  Id IN doc_gauge.doc_gauge_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'DOC_GAUGE_ID,C_DOC_CREATE_MODE,C_POS_CREATE_MODE,C_PDE_CREATE_MODE' as TABLE_KEY,
        doc_gauge_create_proc_id),
      rep_pc_functions.get_descodes('C_DOC_CREATE_MODE', c_doc_create_mode),
      rep_pc_functions.get_descodes('C_POS_CREATE_MODE', c_pos_create_mode),
      rep_pc_functions.get_descodes('C_PDE_CREATE_MODE', c_pde_create_mode),
      rep_pc_functions.get_descodes('C_GROUP_CREATE_MODE', c_group_create_mode),
      XMLForest(
        gcp_init_procedure)
    )) into lx_data
  from doc_gauge_create_proc
  where doc_gauge_id = Id;

  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(DOC_GAUGE_CREATE_PROC,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_doc_gauge_structured(
  Id IN doc_gauge.doc_gauge_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(DOC_GAUGE_STRUCTURED,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'DOC_GAUGE_ID' as TABLE_KEY),
      rep_fin_functions_link.get_acj_job_type_s_cat_link(acj_job_type_s_catalogue_id),
      rep_fin_functions_link.get_acj_job_type_s_cat_link(acj_job_type_s_cat_pmt_id, 'ACJ_JOB_TYPE_S_CAT_PMT', 1),
      rep_fin_functions_link.get_acs_account_link(acs_financial_account_id,'ACS_FINANCIAL_ACCOUNT'),
      rep_fin_functions_link.get_acs_account_link(acs_division_account_id,'ACS_DIVISION_ACCOUNT'),
      rep_fin_functions_link.get_acs_fin_acc_s_payment_link(acs_fin_acc_s_payment_id),
      rep_pac_functions_link.get_pac_payment_condition_link(pac_payment_condition_id),
      rep_pc_functions.get_descodes('C_BUDGET_CALCULATION_MODE', c_budget_calculation_mode),
      rep_pc_functions.get_descodes('C_BUDGET_CONSUMPTION_TYPE', c_budget_consumption_type),
      rep_pc_functions.get_descodes('C_BUDGET_CONTROL',c_budget_control),
      rep_pc_functions.get_descodes('C_BVR_GENERATION_METHOD', c_bvr_generation_method),
      rep_pc_functions.get_descodes('C_CONTROLE_DATE_DOCUM',c_controle_date_docum),
      rep_pc_functions.get_descodes('C_CREDIT_LIMIT',c_credit_limit),
      rep_pc_functions.get_descodes('C_DOC_CREDITLIMIT_MODE',c_doc_creditlimit_mode),
      rep_pc_functions.get_descodes('C_DOC_JOURNAL_CALCULATION', c_doc_journal_calculation),
      rep_pc_functions.get_descodes('C_DOC_PRE_ENTRY',c_doc_pre_entry),
      rep_pc_functions.get_descodes('C_DOC_PRE_ENTRY_THIRD',c_doc_pre_entry_third),
      rep_pc_functions.get_descodes('C_GAUGE_TITLE',c_gauge_title),
      rep_pc_functions.get_descodes('C_PIC_FORECAST_CONTROL',c_pic_forecast_control),
      rep_pc_functions.get_descodes('C_PROJECT_CONSOLIDATION', c_project_consolidation),
      rep_pc_functions.get_descodes('C_ROUND_TYPE',c_round_type),
      rep_pc_functions.get_descodes('C_START_CONTROL_DATE',c_start_control_date),
      rep_pc_functions.get_descodes('C_TYPE_EDI',c_type_edi),
      rep_pc_functions.get_dictionary('DIC_DOC_JOURNAL_1', dic_doc_journal_1_id),
      rep_pc_functions.get_dictionary('DIC_DOC_JOURNAL_2', dic_doc_journal_2_id),
      rep_pc_functions.get_dictionary('DIC_DOC_JOURNAL_3', dic_doc_journal_3_id),
      rep_pc_functions.get_dictionary('DIC_DOC_JOURNAL_4', dic_doc_journal_4_id),
      rep_pc_functions.get_dictionary('DIC_DOC_JOURNAL_5', dic_doc_journal_5_id),
      rep_pc_functions.get_dictionary('DIC_GAU_NATURE_CODE', dic_gau_nature_code_id),
      rep_pc_functions.get_dictionary('DIC_PROJECT_CONSOL_1', dic_project_consol_1_id),
      rep_pc_functions.get_dictionary('DIC_TYPE_MOVEMENT', dic_type_movement_id),
      XMLForest(
        com_name_aci,
        gas_addendum,
        gas_addendum_numbering_id,
        gas_all_characterization,
        gas_anal_charge,
        gas_auth_balance_no_return,
        gas_auth_balance_return,
        gas_auto_attribution,
        gas_auto_mrp,
        gas_balance_status,
        gas_budget_control_status_01, gas_budget_control_status_02, gas_budget_control_status_03,
          gas_budget_control_status_04,
        gas_calcul_credit_limit,
        gas_calculate_commission,
        gas_cash_multiple_transaction,
        gas_cash_register,
        gas_change_acc_s_payment,
        gas_characterization,
        gas_charge,
        gas_check_invoice_expiry_link,
        gas_commission_management,
        gas_correlation,
        gas_cost,
        gas_cpn_account_modify,
        gas_credit_limit_status_01, gas_credit_limit_status_02, gas_credit_limit_status_03,
          gas_credit_limit_status_04,
        gas_differed_confirmation,
        gas_discount,
        gas_distribution_channel,
        gas_doc_journalizing,
        gas_doc_status_budget_control,
        gas_doc_status_credit_limit,
        gas_ebpp_reference,
        gas_edi_export_method,
        gas_financial_charge,
        gas_financial_ref,
        gas_first_no,
        gas_following_periods_nb,
        gas_form_cash_register,
        gas_good_third,
        gas_include_budget_control,
        gas_increment,
        gas_increment_nbr,
        gas_init_free_data,
        gas_installation_auto_gen,
        gas_installation_mgm,
        gas_installation_required,
        gas_invoice_expiry,
        gas_metal_account_mgm,
        gas_modify_numbering,
        gas_multisourcing_mgm,
        gas_pay_condition,
        gas_pcent,
        gas_pos_qty_decimal,
        gas_position__numbering,
        gas_position_cost,
        gas_position_cost_gauge,
        gas_previous_periods_nb,
        gas_proc_after_delete_pos,
        gas_proc_after_edit_pos,
        gas_proc_after_validate_pos,
        gas_proc_delete_pos,
        gas_proc_edit_pos,
        gas_proc_validate_pos,
        gas_record_imputation,
        gas_round_amount,
        gas_sale_territory,
        gas_sending_condition,
        gas_stored_proc_after_confirm,
        gas_stored_proc_after_delete,
        gas_stored_proc_after_edit,
        gas_stored_proc_after_validate,
        gas_stored_proc_confirm,
        gas_stored_proc_delete,
        gas_stored_proc_edit,
        gas_stored_proc_validate,
        gas_substitute,
        gas_taxe,
        gas_total_doc,
        gas_unit_price_decimal,
        gas_use_partner_date,
        gas_vat,
        gas_vat_det_account_visible,
        gas_visible_count,
        gas_weighing_mgm,
        gas_weight,
        gas_weight_mat)
    ) into lx_data
  from doc_gauge_structured
  where doc_gauge_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_doc_gauge_position(
  Id IN doc_gauge.doc_gauge_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'DOC_GAUGE_ID,GAP_DESIGNATION' as TABLE_KEY,
        doc_gauge_position_id),
      rep_log_functions_link.get_doc_doc_gap_link(doc_doc_gauge_position_id),
      rep_log_functions_link.get_gco_good_link(gco_good_id),
      rep_pc_functions_link.get_pc_appltxt_link(pc_appltxt_id),
      rep_log_functions_link.get_stm_stock_link(stm_stock_id),
      rep_log_functions_link.get_stm_location_link(stm_location_id),
      rep_log_functions_link.get_stm_movement_kind_link(stm_ma_movement_kind_id, 'STM_MA_MOVEMENT_KIND', 1),
      rep_log_functions_link.get_stm_movement_kind_link(stm_movement_kind_id, 'STM_MOVEMENT_KIND', 1),
      rep_pc_functions.get_descodes('C_GAUGE_INIT_PRICE_POS', c_gauge_init_price_pos),
      rep_pc_functions.get_descodes('C_GAUGE_SHOW_DELAY', c_gauge_show_delay),
      rep_pc_functions.get_descodes('C_GAUGE_TYPE_POS', c_gauge_type_pos),
      rep_pc_functions.get_descodes('C_ROUND_APPLICATION', c_round_application),
      rep_pc_functions.get_descodes('C_SQM_EVAL_TYPE', c_sqm_eval_type),
      rep_pc_functions.get_dictionary('DIC_TARIFF', dic_tariff_id),
      rep_pc_functions.get_dictionary('DIC_DELAY_UPDATE_TYPE', dic_delay_update_type_id),
      rep_pc_functions.get_dictionary('DIC_TYPE_MOVEMENT', dic_type_movement_id),
      XMLForest(
        gap_asa_task_imput,
        gap_bloc_access_value,
        gap_default,
        gap_delay,
        gap_delay_copy_prev_pos,
        gap_designation,
        gap_direct_remis,
        gap_forced_tariff,
        gap_gen_cml_events,
        gap_include_tax_tariff,
        gap_init_final_delay,
        gap_init_final_qty,
        gap_init_first_delay,
        gap_init_first_qty,
        gap_init_middle_delay,
        gap_init_middle_qty,
        gap_init_stock_place,
        gap_mrp,
        gap_mvt_utility,
        gap_pcent,
        gap_pos_delay,
        gap_sqm_show_dflt,
        gap_stock_access,
        gap_stock_mvt,
        gap_trans_access,
        gap_transfert_proprietor,
        gap_txt,
        gap_value,
        gap_value_quantity,
        gap_weight)
    ) order by doc_doc_gauge_position_id nulls first) into lx_data
  from doc_gauge_position
  where doc_gauge_id = Id;

  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(DOC_GAUGE_POSITION,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_doc_gauge_position_id(
  gauge_id IN doc_gauge.doc_gauge_id%TYPE,
  designation IN doc_gauge_position.gap_designation%TYPE)
  return doc_gauge_position.doc_gauge_position_id%TYPE
is
  ln_result doc_gauge_position.doc_gauge_position_id%TYPE;
begin
  if (gauge_id is not null and designation is not null) then
    select doc_gauge_position_id
    into ln_result
    from doc_gauge_position
    where doc_gauge_id = gauge_id and gap_designation = designation;
    return ln_result;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_doc_gauge_flow_xml(
  Id IN doc_gauge_flow.doc_gauge_flow_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(DOCUMENT_GAUGES,
      XMLElement(DOC_GAUGE_FLOW,
        XMLAttributes(
          doc_gauge_flow_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'PAC_THIRD_ID,C_ADMIN_DOMAIN,GAF_VERSION' as TABLE_KEY,
          doc_gauge_flow_id),
        rep_pac_functions_link.get_pac_third_link(pac_third_id),
        rep_log_functions_link.get_doc_gauge_flow_link(doc_gauge_flow_origin_id, 'DOC_GAUGE_FLOW_ORIGIN', 1),
        rep_pc_functions.get_descodes('C_ADMIN_DOMAIN', C_ADMIN_DOMAIN),
        rep_pc_functions.get_descodes('C_GAF_FLOW_STATUS', C_GAF_FLOW_STATUS),
        XMLForest(
          gaf_comment,
          gaf_describe,
          gaf_version),
        rep_log_functions.get_doc_gauge_flow_docum(doc_gauge_flow_id),
        rep_pc_functions.get_com_vfields_record(doc_gauge_flow_id,'DOC_GAUGE_FLOW'),
        rep_pc_functions.get_com_vfields_value(doc_gauge_flow_id,'DOC_GAUGE_FLOW')
      )
    ) into lx_data
  from doc_gauge_flow
  where doc_gauge_flow_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(DOCUMENT_GAUGES,
          XMLElement(DOC_GAUGE_FLOW,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_doc_gauge_flow_docum(
  Id IN doc_gauge_flow.doc_gauge_flow_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'DOC_GAUGE_FLOW_ID,DOC_GAUGE_ID' as TABLE_KEY,
        doc_gauge_flow_docum_id),
      rep_log_functions_link.get_doc_gauge_link(doc_gauge_id, 'DOC_GAUGE'),
      XMLForest(
        gad_origin_doc,
        gad_seq),
      rep_log_functions.get_doc_gauge_copy(doc_gauge_flow_docum_id),
      rep_log_functions.get_doc_gauge_receipt(doc_gauge_flow_docum_id)
    )) into lx_data
  from doc_gauge_flow_docum
  where doc_gauge_flow_id = Id;

  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(DOC_GAUGE_FLOW_DOCUM,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_doc_gauge_copy(
  Id IN doc_gauge_flow_docum.doc_gauge_flow_docum_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'DOC_GAUGE_FLOW_DOCUM_ID,DOC_DOC_GAUGE_ID' as TABLE_KEY,
        doc_gauge_copy_id),
      rep_log_functions_link.get_doc_gauge_link(doc_doc_gauge_id, 'DOC_DOC_GAUGE', 1),
      XMLForest(
        doc_gauge_flow_id,
        gac_bond,
        gac_doc_trsf_linked_files,
        gac_graph_position,
        gac_init_cost_price,
        gac_init_price_mvt,
        gac_init_qty_mvt,
        gac_part_copy,
        gac_transfert_charact,
        gac_transfert_descr,
        gac_transfert_free_data,
        gac_transfert_precious_mat,
        gac_transfert_price,
        gac_transfert_price_mvt,
        gac_transfert_quantity,
        gac_transfert_record,
        gac_transfert_remise_taxe,
        gac_transfert_represent,
        gac_transfert_stock,
        gac_trsf_linked_files),
      rep_log_functions.get_doc_gauge_receipt_s_axis(null, doc_gauge_copy_id)
    )) into lx_data
  from doc_gauge_copy
  where doc_gauge_flow_docum_id = Id;

  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(DOC_GAUGE_COPY,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_doc_gauge_receipt(
  Id IN doc_gauge_flow_docum.doc_gauge_flow_docum_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'DOC_GAUGE_FLOW_DOCUM_ID,DOC_DOC_GAUGE_ID' as TABLE_KEY,
        doc_gauge_receipt_id),
      rep_log_functions_link.get_doc_gauge_link(doc_doc_gauge_id, 'DOC_DOC_GAUGE', 1),
      XMLForest(
        doc_gauge_flow_id,
        gar_balance_parent,
        gar_doc_trsf_linked_files,
        gar_extourne_mvt,
        gar_good_changing,
        gar_graph_position,
        gar_init_cost_price,
        gar_init_delay_variation,
        gar_init_price_mvt,
        gar_init_price_variation,
        gar_init_qty_mvt,
        gar_init_qty_variation,
        gar_invert_amount,
        gar_part_discharge,
        gar_partner_changing,
        gar_quantity_exceed,
        gar_transfer_mvmt_swap,
        gar_transfert_descr,
        gar_transfert_free_data,
        gar_transfert_movement_date,
        gar_transfert_precious_mat,
        gar_transfert_price,
        gar_transfert_price_mvt,
        gar_transfert_quantity,
        gar_transfert_record,
        gar_transfert_remise_taxe,
        gar_transfert_represent,
        gar_transfert_stock,
        gar_transfert_vat_rate,
        gar_trsf_linked_files),
      rep_log_functions.get_doc_gauge_receipt_s_axis(doc_gauge_receipt_id, null)
    )) into lx_data
  from doc_gauge_receipt
  where doc_gauge_flow_docum_id = Id;

  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(DOC_GAUGE_RECEIPT,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_doc_gauge_receipt_s_axis(
  ReceiptId IN doc_gauge_receipt.doc_gauge_receipt_id%TYPE,
  CopyId IN doc_gauge_copy.doc_gauge_copy_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (ReceiptID is not null) then
    -- Décharge
    select
      XMLAgg(XMLElement(LIST_ITEM,
        XMLForest(
          'AFTER' as TABLE_TYPE,
          'DOC_GAUGE_RECEIPT_ID' as TABLE_KEY,
          doc_gauge_receipt_s_axis_id),
        rep_log_functions_link.get_sqm_axis_link(sqm_axis_id),
        XMLForest(
          gra_estimate_calculation)
      )) into lx_data
    from doc_gauge_receipt_s_axis
    where doc_gauge_receipt_id = ReceiptId;
  elsif (CopyId is not null) then
    -- Copie
    select
      XMLAgg(XMLElement(LIST_ITEM,
        XMLForest(
          'AFTER' as TABLE_TYPE,
          'DOC_GAUGE_COPY_ID' as TABLE_KEY,
          doc_gauge_receipt_s_axis_id),
        rep_log_functions_link.get_sqm_axis_link(sqm_axis_id),
        XMLForest(
          gra_estimate_calculation)
      )) into lx_data
    from doc_gauge_receipt_s_axis
    where doc_gauge_copy_id = CopyId;
  else
    return null;
  end if;

  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(DOC_GAUGE_RECEIPT_S_AXIS,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

  /**
   * fonction get_gco_compl_data_subcontract
   * Description
   *    Génération d'un fragment XML des données complémentaires de sous-traitance (GCO_COMPL_DATA_SUBCONTRACT)
   */
  function get_gco_compl_data_subcontract(Id in GCO_GOOD.GCO_GOOD_ID%type)
    return xmltype
  is
    lx_data xmltype;
  begin
    if (nvl(id, 0) = 0) then
      return null;
    end if;

    select XMLAgg
              (XMLElement(LIST_ITEM
                        , XMLForest('AFTER' as TABLE_TYPE
                                  , 'GCO_GOOD_ID,PAC_SUPPLIER_PARTNER_ID,CSU_DEFAULT_SUBCONTRACTER,DIC_COMPLEMENTARY_DATA_ID,CSU_VALIDITY_DATE' as TABLE_KEY
                                  , GCO_COMPL_DATA_SUBCONTRACT_ID
                                  , CDA_COMMENT
                                  , CDA_COMPLEMENTARY_EAN_CODE
                                  , CDA_COMPLEMENTARY_REFERENCE
                                  , CDA_COMPLEMENTARY_UCC14_CODE
                                  , CDA_CONVERSION_FACTOR
                                  , CDA_FREE_ALPHA_1
                                  , CDA_FREE_ALPHA_2
                                  , CDA_FREE_DEC_1
                                  , CDA_FREE_DEC_2
                                  , CDA_FREE_DESCRIPTION
                                  , CDA_LONG_DESCRIPTION
                                  , CDA_NUMBER_OF_DECIMAL
                                  , CDA_SECONDARY_REFERENCE
                                  , CDA_SHORT_DESCRIPTION
                                  , CSU_AMOUNT
                                  , CSU_AUTOMATIC_GENERATING_PROP
                                  , CSU_CONTROL_DELAY
                                  , CSU_DEFAULT_SUBCONTRACTER
                                  , CSU_ECONOMICAL_QUANTITY
                                  , CSU_FIXED_DELAY
                                  , CSU_FIXED_QUANTITY_TRASH
                                  , CSU_FIX_DELAY
                                  , CSU_HANDLING_CAUTION
                                  , CSU_HIBC_CODE
                                  , CSU_LOT_QUANTITY
                                  , CSU_MODULO_QUANTITY
                                  , CSU_PERCENT_TRASH
                                  , CSU_PLAN_NUMBER
                                  , CSU_PLAN_VERSION
                                  , CSU_QTY_REFERENCE_TRASH
                                  , CSU_SECURITY_DELAY
                                  , CSU_SHIFT
                                  , CSU_SUBCONTRACTING_DELAY
                                  , to_char(CSU_VALIDITY_DATE) as CSU_VALIDITY_DATE
                                  , CSU_WEIGH
                                  , CSU_WEIGH_MANDATORY
                                   )
                        , REP_PC_FUNCTIONS.get_descodes('C_DISCHARGE_COM', C_DISCHARGE_COM)
                        , REP_PC_FUNCTIONS.get_descodes('C_ECONOMIC_CODE', C_ECONOMIC_CODE)
                        , REP_PC_FUNCTIONS.get_descodes('C_GOOD_LITIG', C_GOOD_LITIG)
                        , REP_PC_FUNCTIONS.get_descodes('C_QTY_SUPPLY_RULE', C_QTY_SUPPLY_RULE)
                        , REP_PC_FUNCTIONS.get_descodes('C_TIME_SUPPLY_RULE', C_TIME_SUPPLY_RULE)
                        , REP_PC_FUNCTIONS.get_dictionary('DIC_COMPLEMENTARY_DATA', DIC_COMPLEMENTARY_DATA_ID)
                        , REP_PC_FUNCTIONS.get_dictionary('DIC_FAB_CONDITION', DIC_FAB_CONDITION_ID)
                        , REP_PC_FUNCTIONS.get_dictionary('DIC_UNIT_OF_MEASURE', DIC_UNIT_OF_MEASURE_ID)
                        , REP_IND_FUNCTIONS_LINK.get_pps_nomenclature_link(PPS_NOMENCLATURE_ID)
                        , REP_IND_FUNCTIONS_LINK.get_pps_operation_proc_link(PPS_OPERATION_PROCEDURE_ID)
                        , REP_LOG_FUNCTIONS_LINK.get_stm_location_link(STM_LOCATION_ID)
                        , REP_LOG_FUNCTIONS_LINK.get_stm_stock_link(STM_STOCK_ID)
                        , REP_LOG_FUNCTIONS_LINK.get_gco_good_link(GCO_GCO_GOOD_ID, 'GCO_GCO_GOOD', 1)
                        , REP_LOG_FUNCTIONS_LINK.get_gco_good_link(GCO_GOOD_ID)
                        , REP_LOG_FUNCTIONS_LINK.get_gco_quality_principle_link(GCO_QUALITY_PRINCIPLE_ID)
                        , REP_LOG_FUNCTIONS_LINK.get_gco_substitution_link(GCO_SUBSTITUTION_LIST_ID)
                        , REP_PAC_FUNCTIONS_LINK.get_pac_supplier_partner_link(PAC_SUPPLIER_PARTNER_ID)
                        , REP_PC_FUNCTIONS.get_com_vfields_record(GCO_COMPL_DATA_SUBCONTRACT_ID, 'GCO_COMPL_DATA_SUBCONTRACT')
                        , REP_PC_FUNCTIONS.get_com_vfields_value(GCO_COMPL_DATA_SUBCONTRACT_ID, 'GCO_COMPL_DATA_SUBCONTRACT')
                         )
              )
      into lx_data
      from GCO_COMPL_DATA_SUBCONTRACT
     where GCO_GOOD_ID = id;

    -- Générer le tag principal uniquement s'il y a données
    if (lx_data is not null) then
      select XMLElement(GCO_COMPL_DATA_SUBCONTRACT, XMLElement(list, lx_data) )
        into lx_data
        from dual;

      return lx_data;
    end if;

    return null;
  exception
    when no_data_found then
      return null;
  end get_gco_compl_data_subcontract;

  /**
   * fonction get_gco_equivalence_good
   * Description
   *    Génération d'un fragment XML des blocs d'équivalence (GCO_EQUIVALENCE_GOOD)
   */
  function get_gco_equivalence_good(id in GCO_GOOD.GCO_GOOD_ID%type)
    return xmltype
  is
    lx_data xmltype;
  begin
    if (nvl(id, 0) = 0) then
      return null;
    end if;

    select XMLAgg(XMLElement(LIST_ITEM
                           , XMLForest('AFTER' as TABLE_TYPE
                                     , 'GCO_GOOD_ID,GCO_GCO_GOOD_ID' as TABLE_KEY
                                     , GCO_EQUIVALENCE_GOOD_ID
                                     , to_char(GEG_BEGIN_DATE) as GEG_BEGIN_DATE
                                     , to_char(GEG_END_DATE) as GEG_END_DATE
                                      )
                           , REP_PC_FUNCTIONS.get_descodes('C_GEG_STATUS', C_GEG_STATUS)
                           , REP_LOG_FUNCTIONS_LINK.get_gco_product_link(GCO_GCO_GOOD_ID, 'GCO_GCO_GOOD')
                           , REP_PC_FUNCTIONS.get_com_vfields_record(GCO_EQUIVALENCE_GOOD_ID, 'GCO_EQUIVALENCE_GOOD')
                           , REP_PC_FUNCTIONS.get_com_vfields_value(GCO_EQUIVALENCE_GOOD_ID, 'GCO_EQUIVALENCE_GOOD')
                            ) order by GCO_GOOD_ID
                 )
      into lx_data
      from gco_equivalence_good
     where GCO_GOOD_ID = id;

    -- Générer le tag principal uniquement s'il y a données
    if (lx_data is not null) then
      select XMLElement(GCO_EQUIVALENCE_GOOD, XMLElement(list, lx_data) )
        into lx_data
        from dual;

      return lx_data;
    end if;

    return null;
  exception
    when no_data_found then
      return null;
  end get_gco_equivalence_good;

  /**
  * fonction get_gco_compl_data_ext_asa
  * Description
  *    Génération d'un fragment XML des données complémentaires de service après-vente externe (GCO_COMPL_DATA_EXTERNAL_ASA)
  */
  function get_gco_compl_data_ext_asa(id in GCO_COMPL_DATA_EXTERNAL_ASA.GCO_GOOD_ID%type)
    return xmltype
  is
    lx_data xmltype;
  begin
    if (nvl(id, 0) = 0) then
      return null;
    end if;

    select XMLAgg(XMLElement(LIST_ITEM
                           , XMLForest('AFTER' as TABLE_TYPE
                                     , 'GCO_GOOD_ID,DIC_COMPLEMENTARY_DATA_ID' as TABLE_KEY
                                     , GCO_COMPL_DATA_EXTERNAL_ASA_ID
                                     , CDA_COMPLEMENTARY_EAN_CODE
                                     , CDA_COMPLEMENTARY_REFERENCE
                                     , CDA_COMPLEMENTARY_UCC14_CODE
                                     , CDA_COMMENT
                                     , CDA_CONVERSION_FACTOR
                                     , CDA_FREE_ALPHA_1
                                     , CDA_FREE_ALPHA_2
                                     , CDA_FREE_DEC_1
                                     , CDA_FREE_DEC_2
                                     , CDA_FREE_DESCRIPTION
                                     , CEA_FREE_NUMBER1
                                     , CEA_FREE_NUMBER2
                                     , CEA_FREE_NUMBER3
                                     , CEA_FREE_NUMBER4
                                     , CEA_FREE_NUMBER5
                                     , CEA_FREE_TEXT1
                                     , CEA_FREE_TEXT2
                                     , CEA_FREE_TEXT3
                                     , CEA_FREE_TEXT4
                                     , CEA_FREE_TEXT5
                                     , CDA_LONG_DESCRIPTION
                                     , CEA_NEW_ITEMS_WARRANTY
                                     , CDA_NUMBER_OF_DECIMAL
                                     , CEA_OLD_ITEMS_WARRANTY
                                     , CDA_SECONDARY_REFERENCE
                                     , CDA_SHORT_DESCRIPTION
                                      )
                           , REP_PC_FUNCTIONS.get_descodes('C_ASA_NEW_GUARANTY_UNIT', C_ASA_NEW_GUARANTY_UNIT)
                           , REP_PC_FUNCTIONS.get_descodes('C_ASA_OLD_GUARANTY_UNIT', C_ASA_OLD_GUARANTY_UNIT)
                           , REP_PC_FUNCTIONS.get_dictionary('DIC_CEA_FREE_CODE1', DIC_CEA_FREE_CODE1_ID)
                           , REP_PC_FUNCTIONS.get_dictionary('DIC_CEA_FREE_CODE2', DIC_CEA_FREE_CODE2_ID)
                           , REP_PC_FUNCTIONS.get_dictionary('DIC_CEA_FREE_CODE3', DIC_CEA_FREE_CODE3_ID)
                           , REP_PC_FUNCTIONS.get_dictionary('DIC_CEA_FREE_CODE4', DIC_CEA_FREE_CODE4_ID)
                           , REP_PC_FUNCTIONS.get_dictionary('DIC_CEA_FREE_CODE5', DIC_CEA_FREE_CODE5_ID)
                           , REP_PC_FUNCTIONS.get_dictionary('DIC_COMPLEMENTARY_DATA', DIC_COMPLEMENTARY_DATA_ID)
                           , REP_PC_FUNCTIONS.get_dictionary('DIC_UNIT_OF_MEASURE', DIC_UNIT_OF_MEASURE_ID)
                           , REP_LOG_FUNCTIONS_LINK.get_doc_record_category_link(DOC_RECORD_CATEGORY_ID)
                           , REP_LOG_FUNCTIONS_LINK.get_gco_quality_principle_link(GCO_QUALITY_PRINCIPLE_ID)
                           , REP_LOG_FUNCTIONS_LINK.get_gco_substitution_link(GCO_SUBSTITUTION_LIST_ID)
                           , REP_PC_FUNCTIONS_LINK.get_pc_appltxt_link(CEA_NEW_PC_APPLTXT_ID, 'CEA_NEW_PC_APPLTXT')
                           , REP_PC_FUNCTIONS_LINK.get_pc_appltxt_link(CEA_OLD_PC_APPLTXT_ID, 'CEA_OLD_PC_APPLTXT')
                           , REP_LOG_FUNCTIONS_LINK.get_stm_location_link(STM_LOCATION_ID)
                           , REP_LOG_FUNCTIONS_LINK.get_stm_stock_link(STM_STOCK_ID)
                           , REP_LOG_FUNCTIONS.get_gco_service_plan(GCO_COMPL_DATA_EXTERNAL_ASA_ID)
                           , REP_PC_FUNCTIONS.get_com_vfields_record(GCO_COMPL_DATA_EXTERNAL_ASA_ID, 'GCO_COMPL_DATA_EXTERNAL_ASA')
                           , REP_PC_FUNCTIONS.get_com_vfields_value(GCO_COMPL_DATA_EXTERNAL_ASA_ID, 'GCO_COMPL_DATA_EXTERNAL_ASA')
                            ) order by GCO_COMPL_DATA_EXTERNAL_ASA_ID
                 )
      into lx_data
      from GCO_COMPL_DATA_EXTERNAL_ASA
     where GCO_GOOD_ID = id;

    -- Générer le tag principal uniquement s'il y a données
    if (lx_data is not null) then
      select XMLElement(GCO_COMPL_DATA_EXTERNAL_ASA, XMLElement(list, lx_data) )
        into lx_data
        from dual;

      return lx_data;
    end if;

    return null;
  exception
    when no_data_found then
      return null;
  end get_gco_compl_data_ext_asa;

  /**
  * fonction get_gco_service_plan
  * Description
  *    Génération d'un fragment XML des plans de service (GCO_SERVICE_PLAN)
  */
  function get_gco_service_plan(id in GCO_SERVICE_PLAN.GCO_COMPL_DATA_EXTERNAL_ASA_ID%type)
    return xmltype
  is
    lx_data xmltype;
  begin
    if (id in(null, 0) ) then
      return null;
    end if;

    select XMLAgg(XMLElement(LIST_ITEM
                           , XMLForest('AFTER' as TABLE_TYPE
                                     , 'GCO_COMPL_DATA_EXTERNAL_ASA_ID,SER_SEQ' as TABLE_KEY
                                     , GCO_SERVICE_PLAN_ID
                                     , SER_COMMENT
                                     , SER_CONVERSION_FACTOR
                                     , SER_COUNTER_STATE
                                     , SER_PERIODICITY
                                     , SER_SEQ
                                     , SER_WORK_TIME
                                      )
                           , REP_PC_FUNCTIONS.get_descodes('C_ASA_SERVICE_TYPE', C_ASA_SERVICE_TYPE)
                           , REP_PC_FUNCTIONS.get_descodes('C_SERVICE_PLAN_PERIODICITY', C_SERVICE_PLAN_PERIODICITY)
                           , REP_PC_FUNCTIONS.get_dictionary('DIC_SER_UNIT_OF_MEASURE', DIC_SER_UNIT_OF_MEASURE_ID)
                           , REP_PC_FUNCTIONS.get_dictionary('DIC_SERVICE_TYPE', DIC_SERVICE_TYPE_ID)
                           , REP_PC_FUNCTIONS.get_com_vfields_record(GCO_SERVICE_PLAN_ID, 'GCO_SERVICE_PLAN')
                           , REP_PC_FUNCTIONS.get_com_vfields_value(GCO_SERVICE_PLAN_ID, 'GCO_SERVICE_PLAN')
                            ) order by SER_SEQ
                 )
      into lx_data
      from GCO_SERVICE_PLAN
     where GCO_COMPL_DATA_EXTERNAL_ASA_ID = id;

    -- Générer le tag principal uniquement s'il y a données
    if (lx_data is not null) then
      select XMLElement(GCO_SERVICE_PLAN, XMLElement(list, lx_data) )
        into lx_data
        from dual;

      return lx_data;
    end if;

    return null;
  exception
    when no_data_found then
      return null;
  end get_gco_service_plan;
END REP_LOG_FUNCTIONS;
