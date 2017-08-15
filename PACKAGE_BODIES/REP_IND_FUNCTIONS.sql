--------------------------------------------------------
--  DDL for Package Body REP_IND_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_IND_FUNCTIONS" 
/**
 * Fonctions de génération de document Xml.
 * Spécialisation: Industrie et fabrication (PPS et FAL)
 *
 * @version 1.0
 * @date 02/2003
 * @author jsomers
 * @author spfister
 * @author pvogel
 * @author ngomes
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
AS

--
-- PPS  functions
--

function get_pps_bom(
  Id IN pps_nomenclature.pps_nomenclature_id%TYPE)
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
        'PPS_NOMENCLATURE_ID,COM_SEQ,C_TYPE_COM,C_DISCHARGE_COM,'||
          'C_KIND_COM,GCO_GOOD_ID,PPS_PPS_NOMENCLATURE_ID' as TABLE_KEY,
        pps_nom_bond_id),
      rep_log_functions_link.get_gco_good_link_category(gco_good_id),
      rep_pc_functions.get_descodes('C_REMPLACEMENT_NOM', c_remplacement_nom),
      rep_pc_functions.get_descodes('C_TYPE_COM',c_type_com),
      rep_pc_functions.get_descodes('C_DISCHARGE_COM', c_discharge_com),
      rep_pc_functions.get_descodes('C_KIND_COM', c_kind_com),
      XMLForest(
        com_seq,
        com_text,
        com_res_text,
        com_res_num,
        com_val,
        com_substitut,
        com_pos,
        com_util_coeff,
        com_pdir_coeff,
        com_rec_pcent,
        com_interval,
        to_char(com_beg_valid) as COM_BEG_VALID,
        to_char(com_end_valid) as COM_END_VALID,
        com_remplacement,
        com_mark_topo,
        com_nom_version,
        com_increase_cost),
      REP_IND_FUNCTIONS_LINK.get_fal_list_step_link_link(FAL_SCHEDULE_STEP_ID, 'FAL_SCHEDULE_STEP', 1),
      rep_ind_functions_link.get_pps_nomenclature_link(pps_pps_nomenclature_id,'PPS_PPS_NOMENCLATURE',1),
      XMLForest(
        com_ref_qty,
        com_percent_waste,
        com_fixed_quantity_waste,
        com_qty_reference_loss),
      rep_log_functions_link.get_stm_stock_link(stm_stock_id),
      rep_log_functions_link.get_stm_location_link(stm_location_id),
      rep_pc_functions.get_com_vfields_record(pps_nom_bond_id,'PPS_NOM_BOND'),
      rep_pc_functions.get_com_vfields_value(pps_nom_bond_id,'PPS_NOM_BOND')
    )) into lx_data
  from pps_nom_bond
  where pps_nomenclature_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(PPS_NOM_BOND,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pps_nomenclature_xml(
  Id IN pps_nomenclature.pps_nomenclature_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(BOM,
      XMLElement(PPS_NOMENCLATURE,
        XMLAttributes(
          pps_nomenclature_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'C_TYPE_NOM,GCO_GOOD_ID,NOM_VERSION' as TABLE_KEY,
          pps_nomenclature_id),
        rep_log_functions_link.get_gco_good_link_category(gco_good_id),
        rep_pc_functions.get_descodes('C_TYPE_NOM',c_type_nom),
        XMLForest(
          nom_text,
          nom_ref_qty,
          nom_qty_free1,
          nom_version),
        rep_pc_functions.get_descodes('C_REMPLACEMENT_NOM', c_remplacement_nom),
        XMLForest(
          to_char(nom_beg_valid) as NOM_BEG_VALID,
          nom_default),
        rep_ind_functions.get_pps_bom(pps_nomenclature_id),
        rep_log_functions_link.get_doc_record_link(doc_record_id),
        REP_IND_FUNCTIONS_LINK.get_fal_schedule_plan_link(FAL_SCHEDULE_PLAN_ID),
        REP_IND_FUNCTIONS.get_pps_mark_bond(PPS_NOMENCLATURE_ID),
        rep_pc_functions.get_com_vfields_record(pps_nomenclature_id,'PPS_NOMENCLATURE'),
        rep_pc_functions.get_com_vfields_value(pps_nomenclature_id,'PPS_NOMENCLATURE')
      )
    ) into lx_data
  from pps_nomenclature
  where pps_nomenclature_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(BOM,
          XMLElement(PPS_NOMENCLATURE,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

  /**
   * fonction get_pps_mark_bond
   * Description
   *    Génération d'un fragment XML des repères topologiques (PPS_MARK_BOND)
   */
  function get_pps_mark_bond(id in PPS_MARK_BOND.PPS_NOMENCLATURE_ID%type)
    return xmltype
  is
    lx_data xmltype;
  begin
    if (nvl(id, 0) = 0) then
      return null;
    end if;

    select XMLAgg(XMLElement(LIST_ITEM
                           , XMLForest('AFTER' as TABLE_TYPE
                                     , 'PPS_NOMENCLATURE_ID,PMB_PREFIX,PMB_NUMBER,PMB_SUFFIX' as TABLE_KEY
                                     , PPS_MARK_BOND_ID
                                     , PMB_PREFIX
                                     , PMB_NUMBER
                                     , PMB_SUFFIX
                                     , PMB_MARK_TOPO
                                      )
                           , REP_IND_FUNCTIONS_LINK.get_fal_list_step_link_link(FAL_SCHEDULE_STEP_ID, 'FAL_SCHEDULE_STEP', 1)
                           , REP_LOG_FUNCTIONS_LINK.get_gco_good_link(GCO_GOOD_ID)
                           , REP_IND_FUNCTIONS_LINK.get_pps_nom_bond_link(PPS_NOM_BOND_ID)
                           , REP_PC_FUNCTIONS.get_com_vfields_record(PPS_MARK_BOND_ID, 'PPS_MARK_BOND')
                           , REP_PC_FUNCTIONS.get_com_vfields_value(PPS_MARK_BOND_ID, 'PPS_MARK_BOND')
                            ) order by PPS_MARK_BOND_ID
                 )
      into lx_data
      from PPS_MARK_BOND
     where PPS_NOMENCLATURE_ID = id;

    -- Générer le tag principal uniquement s'il y a données
    if (lx_data is not null) then
      select XMLElement(PPS_MARK_BOND, XMLElement(list, lx_data) )
        into lx_data
        from dual;

      return lx_data;
    end if;

    return null;
  exception
    when no_data_found then
      return null;
  end get_pps_mark_bond;

--
-- FAL  functions
--

function get_fal_supply_request_xml(
  Id IN fal_supply_request.fal_supply_request_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(SUPPLY_REQUESTS,
      XMLElement(FAL_SUPPLY_REQUEST,
        XMLAttributes(
          fal_supply_request_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'FAL_SUPPLY_REQUEST_ID' as TABLE_KEY,
          fal_supply_request_id),
        rep_log_functions_link.get_doc_record_link(doc_record_id),
        rep_log_functions_link.get_gco_good_link(gco_good_id),
        rep_pac_functions_link.get_pac_supplier_partner_link(pac_supplier_partner_id),
        rep_pc_functions.get_descodes('C_REQUEST_STATUS', c_request_status),
        rep_pc_functions.get_dictionary('DIC_FAB_CONDITION', dic_fab_condition_id),
        rep_pc_functions.get_dictionary('DIC_POS_FREE_TABLE_1', dic_pos_free_table_1_id),
        rep_pc_functions.get_dictionary('DIC_POS_FREE_TABLE_2', dic_pos_free_table_2_id),
        rep_pc_functions.get_dictionary('DIC_POS_FREE_TABLE_3', dic_pos_free_table_3_id),
        XMLForest(
          fsr_asked_qty,
          fsr_reject_plan_qty,
          fsr_total_qty,
          to_char(fsr_basis_delay) as FSR_BASIS_DELAY,
          to_char(fsr_intermediate_delay) as FSR_INTERMEDIATE_DELAY,
          to_char(fsr_delay) as FSR_DELAY,
          to_char(fsr_date) as FSR_DATE,
          to_char(fsr_refusal_date) as FSR_REFUSAL_DATE,
          to_char(fsr_validate_date) as FSR_VALIDATE_DATE,
          fsr_number,
          fsr_reference,
          fsr_short_descr,
          fsr_texte),
        rep_log_functions_link.get_stm_stock_link(stm_stock_id),
        rep_log_functions_link.get_stm_location_link(stm_location_id),
        rep_pc_functions.get_com_vfields_record(fal_supply_request_id,'FAL_SUPPLY_REQUEST'),
        rep_pc_functions.get_com_vfields_value(fal_supply_request_id,'FAL_SUPPLY_REQUEST')
      )
    ) into lx_data
  from fal_supply_request
  where fal_supply_request_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(SUPPLY_REQUESTS,
          XMLElement(FAL_SUPPLY_REQUEST,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_fal_schedule_plan_xml(
  Id IN fal_schedule_plan.fal_schedule_plan_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(SCHEDULE_PLANS,
      XMLElement(FAL_SCHEDULE_PLAN,
        XMLAttributes(
          fal_schedule_plan_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'SCH_REF' as TABLE_KEY,
          fal_schedule_plan_id),
        rep_pc_functions.get_descodes('C_SCHEDULE_PLANNING', c_schedule_planning),
        XMLForest(
          sch_ref,
          sch_short_descr,
          sch_long_descr,
          sch_free_descr),
        rep_ind_functions.get_fal_list_step_link(fal_schedule_plan_id),
        rep_pc_functions.get_com_vfields_record(fal_schedule_plan_id,'FAL_SCHEDULE_PLAN'),
        rep_pc_functions.get_com_vfields_value(fal_schedule_plan_id,'FAL_SCHEDULE_PLAN')
      )
    ) into lx_data
  from fal_schedule_plan
  where fal_schedule_plan_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(SCHEDULE_PLANS,
          XMLElement(FAL_SCHEDULE_PLAN,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_fal_list_step_link(
  Id IN fal_schedule_plan.fal_schedule_plan_id%TYPE)
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
        'FAL_SCHEDULE_PLAN_ID,SCS_STEP_NUMBER' as TABLE_KEY,
        --'FAL_LIST_STEP_LINK_ID=FAL_SCHEDULE_STEP_ID' as TABLE_MAPPING,
        fal_list_step_link_id),
      rep_ind_functions_link.get_fal_factory_floor_link(fal_factory_floor_id),
      rep_ind_functions_link.get_fal_factory_floor_link(fal_fal_factory_floor_id, 'FAL_FAL_FACTORY_FLOOR', 1),
      rep_ind_functions_link.get_fal_task_link(fal_task_id),
      rep_log_functions_link.get_gco_good_link(gco_gco_good_id, 'GCO_GCO_GOOD', 1),
      rep_pac_functions_link.get_pac_supplier_partner_link(pac_supplier_partner_id),
      rep_ind_functions_link.get_pps_operation_proc_link(pps_operation_procedure_id),
      rep_ind_functions_link.get_pps_operation_proc_link(pps_pps_operation_procedure_id, 'PPS_PPS_OPERATION_PROCEDURE', 1),
      rep_ind_functions_link.get_pps_tools_link(pps_tools1_id, 'PPS_TOOLS1'),
      rep_ind_functions_link.get_pps_tools_link(pps_tools2_id, 'PPS_TOOLS2'),
      rep_ind_functions_link.get_pps_tools_link(pps_tools3_id, 'PPS_TOOLS3'),
      rep_ind_functions_link.get_pps_tools_link(pps_tools4_id, 'PPS_TOOLS4'),
      rep_ind_functions_link.get_pps_tools_link(pps_tools5_id, 'PPS_TOOLS5'),
      rep_ind_functions_link.get_pps_tools_link(pps_tools6_id, 'PPS_TOOLS6'),
      rep_ind_functions_link.get_pps_tools_link(pps_tools7_id, 'PPS_TOOLS7'),
      rep_ind_functions_link.get_pps_tools_link(pps_tools8_id, 'PPS_TOOLS8'),
      rep_ind_functions_link.get_pps_tools_link(pps_tools9_id, 'PPS_TOOLS9'),
      rep_ind_functions_link.get_pps_tools_link(pps_tools10_id, 'PPS_TOOLS10'),
      rep_ind_functions_link.get_pps_tools_link(pps_tools11_id, 'PPS_TOOLS11'),
      rep_ind_functions_link.get_pps_tools_link(pps_tools12_id, 'PPS_TOOLS12'),
      rep_ind_functions_link.get_pps_tools_link(pps_tools13_id, 'PPS_TOOLS13'),
      rep_ind_functions_link.get_pps_tools_link(pps_tools14_id, 'PPS_TOOLS14'),
      rep_ind_functions_link.get_pps_tools_link(pps_tools15_id, 'PPS_TOOLS15'),
      rep_pc_functions.get_descodes('C_OPERATION_TYPE', c_operation_type),
      rep_pc_functions.get_descodes('C_RELATION_TYPE', c_relation_type),
      rep_pc_functions.get_descodes('C_TASK_IMPUTATION', c_task_imputation),
      rep_pc_functions.get_descodes('C_TASK_TYPE', c_task_type),
      rep_pc_functions.get_dictionary('DIC_FREE_TASK_CODE', dic_free_task_code_id),
      rep_pc_functions.get_dictionary('DIC_FREE_TASK_CODE2', dic_free_task_code2_id),
      rep_pc_functions.get_dictionary('DIC_FREE_TASK_CODE3', dic_free_task_code3_id),
      rep_pc_functions.get_dictionary('DIC_FREE_TASK_CODE4', dic_free_task_code4_id),
      rep_pc_functions.get_dictionary('DIC_FREE_TASK_CODE5', dic_free_task_code5_id),
      rep_pc_functions.get_dictionary('DIC_FREE_TASK_CODE6', dic_free_task_code6_id),
      rep_pc_functions.get_dictionary('DIC_FREE_TASK_CODE7', dic_free_task_code7_id),
      rep_pc_functions.get_dictionary('DIC_FREE_TASK_CODE8', dic_free_task_code8_id),
      rep_pc_functions.get_dictionary('DIC_FREE_TASK_CODE9', dic_free_task_code9_id),
      rep_pc_functions.get_dictionary('DIC_UNIT_OF_MEASURE', dic_unit_of_measure_id),
      XMLForest(
        --fal_schedule_step_id, -- ne doit pas être présent dans l'XML !
        scs_adjusting_floor,
        scs_adjusting_operator,
        scs_adjusting_rate,
        scs_adjusting_time,
        scs_amount,
        scs_conversion_factor,
        scs_delay,
        scs_divisor_amount,
        scs_free_descr,
        scs_free_num1,
        scs_free_num2,
        scs_free_num3,
        scs_free_num4,
        scs_long_descr,
        scs_num_adjust_operator,
        scs_num_floor,
        scs_num_work_operator,
        scs_percent_adjust_oper,
        scs_percent_work_oper,
        scs_plan_prop,
        scs_plan_rate,
        scs_qty_fix_adjusting,
        scs_qty_ref_amount,
        scs_qty_ref_work,
        scs_qty_ref2_work,
        scs_short_descr,
        scs_step_number,
        scs_transfert_time,
        scs_weigh,
        scs_weigh_mandatory,
        scs_work_floor,
        scs_work_operator,
        scs_work_rate,
        scs_work_time),
      rep_ind_functions.get_fal_list_step_use(fal_schedule_step_id)
    )) into lx_data
  from fal_list_step_link
  where fal_schedule_plan_id = Id;

  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(FAL_LIST_STEP_LINK,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_fal_list_step_use(
  Id IN fal_list_step_link.fal_schedule_step_id%TYPE)
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
        'FAL_SCHEDULE_STEP_ID,FAL_FACTORY_FLOOR_ID' as TABLE_KEY,
        fal_list_step_use_id,
        lsu_work_time,
        lsu_qty_ref_work,
        lsu_priority,
        lsu_except_mach),
      rep_ind_functions_link.get_fal_factory_floor_link(fal_factory_floor_id, IsMandatory => 1)
    )) into lx_data
  from fal_list_step_use
  where fal_schedule_step_id = Id;

  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(FAL_LIST_STEP_USE,
        XMLElement(TABLE_MAPPING, 'FAL_SCHEDULE_STEP_ID=FAL_LIST_STEP_LINK_ID'),
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_ind_fal_task_xml(
  Id IN fal_task.fal_task_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(TASKS,
      XMLElement(FAL_TASK,
        XMLAttributes(
          FAL_TASK_ID as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'TAS_REF' as TABLE_KEY,
          FAL_TASK_ID),
        rep_ind_functions_link.get_fal_factory_floor_link(FAL_FACTORY_FLOOR_ID),
        rep_ind_functions_link.get_fal_factory_floor_link(FAL_FAL_FACTORY_FLOOR_ID, 'FAL_FAL_FACTORY_FLOOR'),
        rep_pac_functions_link.get_pac_supplier_partner_link(PAC_SUPPLIER_PARTNER_ID),
        rep_log_functions_link.get_gco_good_link(gco_gco_good_id, 'GCO_GCO_GOOD', 1),
        --, PPS_OPERATION_PROCEDURE_ID
        --, PPS_PPS_OPERATION_PROCEDURE_ID
        rep_pc_functions.get_descodes('C_TASK_TYPE', C_TASK_TYPE),
        XMLForest(
          TAS_REF,
          TAS_SHORT_DESCR,
          TAS_LONG_DESCR,
          TAS_FREE_DESCR),
        rep_pc_functions.get_descodes('C_TASK_IMPUTATION', C_TASK_IMPUTATION),
        rep_pc_functions.get_descodes('C_SCHEDULE_PLANNING', C_SCHEDULE_PLANNING),
        rep_pc_functions.get_dictionary('DIC_UNIT_OF_MEASURE', DIC_UNIT_OF_MEASURE_ID),
        rep_pc_functions.get_dictionary('DIC_FREE_TASK_CODE', DIC_FREE_TASK_CODE_ID),
        rep_pc_functions.get_dictionary('DIC_FREE_TASK_CODE2', DIC_FREE_TASK_CODE2_ID),
        rep_pc_functions.get_dictionary('DIC_FREE_TASK_CODE3', DIC_FREE_TASK_CODE3_ID),
        rep_pc_functions.get_dictionary('DIC_FREE_TASK_CODE4', DIC_FREE_TASK_CODE4_ID),
        rep_pc_functions.get_dictionary('DIC_FREE_TASK_CODE5', DIC_FREE_TASK_CODE5_ID),
        rep_pc_functions.get_dictionary('DIC_FREE_TASK_CODE6', DIC_FREE_TASK_CODE6_ID),
        rep_pc_functions.get_dictionary('DIC_FREE_TASK_CODE7', DIC_FREE_TASK_CODE7_ID),
        rep_pc_functions.get_dictionary('DIC_FREE_TASK_CODE8', DIC_FREE_TASK_CODE8_ID),
        rep_pc_functions.get_dictionary('DIC_FREE_TASK_CODE9', DIC_FREE_TASK_CODE9_ID),
        XMLForest(
          TAS_ADJUSTING_RATE,
          TAS_WORK_RATE,
          TAS_NUM_FLOOR,
          TAS_ADJUSTING_FLOOR,
          TAS_ADJUSTING_OPERATOR,
          TAS_NUM_ADJUST_OPERATOR,
          TAS_PERCENT_ADJUST_OPER,
          TAS_WORK_FLOOR,
          TAS_WORK_OPERATOR,
          TAS_NUM_WORK_OPERATOR,
          TAS_PERCENT_WORK_OPER,
          TAS_CONVERSION_FACTOR,
          TAS_FREE_NUM1,
          TAS_FREE_NUM2,
          TAS_FREE_NUM3,
          TAS_FREE_NUM4,
          TAS_TRANSFERT_TIME,
          TAS_AMOUNT,
          TAS_QTY_REF_AMOUNT,
          TAS_DIVISOR_AMOUNT,
          TAS_PLAN_RATE,
          TAS_PLAN_PROP),
        rep_log_functions_link.get_gco_good_link(PPS_TOOLS1_ID, 'PPS_TOOLS1', 1),
        rep_log_functions_link.get_gco_good_link(PPS_TOOLS2_ID, 'PPS_TOOLS2', 1),
        rep_log_functions_link.get_gco_good_link(PPS_TOOLS3_ID, 'PPS_TOOLS3', 1),
        rep_log_functions_link.get_gco_good_link(PPS_TOOLS4_ID, 'PPS_TOOLS4', 1),
        rep_log_functions_link.get_gco_good_link(PPS_TOOLS5_ID, 'PPS_TOOLS5', 1),
        rep_log_functions_link.get_gco_good_link(PPS_TOOLS6_ID, 'PPS_TOOLS6', 1),
        rep_log_functions_link.get_gco_good_link(PPS_TOOLS7_ID, 'PPS_TOOLS7', 1),
        rep_log_functions_link.get_gco_good_link(PPS_TOOLS8_ID, 'PPS_TOOLS8', 1),
        rep_log_functions_link.get_gco_good_link(PPS_TOOLS9_ID, 'PPS_TOOLS9', 1),
        rep_log_functions_link.get_gco_good_link(PPS_TOOLS10_ID, 'PPS_TOOLS10', 1),
        rep_log_functions_link.get_gco_good_link(PPS_TOOLS11_ID, 'PPS_TOOLS11', 1),
        rep_log_functions_link.get_gco_good_link(PPS_TOOLS12_ID, 'PPS_TOOLS12', 1),
        rep_log_functions_link.get_gco_good_link(PPS_TOOLS13_ID, 'PPS_TOOLS13', 1),
        rep_log_functions_link.get_gco_good_link(PPS_TOOLS14_ID, 'PPS_TOOLS14', 1),
        rep_log_functions_link.get_gco_good_link(PPS_TOOLS15_ID, 'PPS_TOOLS15', 1),
        XMLForest(
          TAS_WEIGH,
          TAS_WEIGH_MANDATORY,
          TAS_AJUSTING_RATE),
        rep_pc_functions.get_com_vfields_record(FAL_TASK_ID, 'FAL_TASK'),
        rep_pc_functions.get_com_vfields_value(FAL_TASK_ID, 'FAL_TASK')
      )
    ) into lx_data
  from FAL_TASK
  where FAL_TASK_ID = id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(TASKS,
          XMLElement(FAL_TASK,
            XMLAttributes(id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from DUAL;
      return lx_data;
end;

function get_ind_fal_factory_floor_xml(
  Id IN fal_factory_floor.fal_factory_floor_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (id in (null, 0)) then
    return null;
  end if;

  select
    XMLElement(FACTORY_FLOORS,
      XMLElement(FAL_FACTORY_FLOOR,
        XMLAttributes(
          FAL_FACTORY_FLOOR_ID as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'FAC_REFERENCE' as TABLE_KEY,
          FAL_FACTORY_FLOOR_ID),
        rep_pac_functions_link.get_pac_calendar_type_link(PAC_CALENDAR_TYPE_ID),
        XMLForest(
          FAC_REFERENCE,
          FAC_DESCRIBE,
          FAC_RESOURCE_NUMBER),
        rep_pc_functions.get_descodes('C_TEAM', C_TEAM),
        XMLForest(
          FAC_PIC),
        rep_ind_functions_link.get_fal_factory_floor_link(FAL_FAL_FACTORY_FLOOR_ID, 'FAL_FAL_FACTORY_FLOOR'),
        XMLForest(
          FAC_IS_MACHINE,
          FAC_INFINITE_FLOOR),
        rep_pc_functions.get_dictionary('DIC_FLOOR_FREE_CODE', DIC_FLOOR_FREE_CODE_ID),
        rep_pc_functions.get_dictionary('DIC_FLOOR_FREE_CODE2', DIC_FLOOR_FREE_CODE2_ID),
        rep_pc_functions.get_dictionary('DIC_FLOOR_FREE_CODE3', DIC_FLOOR_FREE_CODE3_ID),
        rep_pc_functions.get_dictionary('DIC_FLOOR_FREE_CODE4', DIC_FLOOR_FREE_CODE4_ID),
        rep_pc_functions.get_dictionary('DIC_FLOOR_FREE_CODE5', DIC_FLOOR_FREE_CODE5_ID),
        rep_pc_functions.get_dictionary('DIC_FLOOR_FREE_CODE6', DIC_FLOOR_FREE_CODE6_ID),
        rep_pc_functions.get_dictionary('DIC_FLOOR_FREE_CODE7', DIC_FLOOR_FREE_CODE7_ID),
        rep_pc_functions.get_dictionary('DIC_FLOOR_FREE_CODE8', DIC_FLOOR_FREE_CODE8_ID),
        rep_pc_functions.get_dictionary('DIC_FLOOR_FREE_CODE9', DIC_FLOOR_FREE_CODE9_ID),
        rep_pc_functions.get_dictionary('DIC_FLOOR_FREE_CODE10', DIC_FLOOR_FREE_CODE10_ID),
        XMLForest(
          FAC_ALPHA01, FAC_ALPHA02, FAC_ALPHA03, FAC_ALPHA04, FAC_ALPHA05,
            FAC_ALPHA06, FAC_ALPHA07, FAC_ALPHA08, FAC_ALPHA09, FAC_ALPHA10,
          FAC_UPDATE_LMU,
          FAC_OUT_OF_ORDER,
          FAC_IS_OPERATOR,
          FAC_PIECES_DAY_CAP,
          FAC_PIECES_HOUR_CAP,
          FAC_IS_PERSON,
          FAC_IS_BLOCK),
        rep_fin_functions_link.get_acs_cda_account_link(ACS_CDA_ACCOUNT_ID),
        --GAL_COST_CENTER_ID
        --HRM_PERSON_ID
        --PAC_SCHEDULE_ID
        --FAL_GRP_FACTORY_FLOOR_ID
        rep_fin_functions_link.get_fam_fixed_assets_link(FAM_FIXED_ASSETS_ID),
        rep_ind_functions.get_fal_factory_rate(FAL_FACTORY_FLOOR_ID),
        rep_ind_functions.get_fal_factory_account(FAL_FACTORY_FLOOR_ID),
        rep_pc_functions.get_com_vfields_record(FAL_FACTORY_FLOOR_ID, 'FAL_FACTORY_FLOOR'),
        rep_pc_functions.get_com_vfields_value(FAL_FACTORY_FLOOR_ID, 'FAL_FACTORY_FLOOR')
      )
    ) into lx_data
  from FAL_FACTORY_FLOOR
  where FAL_FACTORY_FLOOR_ID = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(FACTORY_FLOORS,
          XMLElement(FAL_FACTORY_FLOOR,
            XMLAttributes(id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_fal_factory_rate(
  Id IN fal_factory_floor.fal_factory_floor_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'FAL_FACTORY_FLOOR_ID,FFR_VALIDITY_DATE' as TABLE_KEY,
        FAL_FACTORY_RATE_ID,
        rep_utils.DateToReplicatorDate(FFR_VALIDITY_DATE) as FFR_VALIDITY_DATE,
        FFR_RATE1, FFR_RATE2, FFR_RATE3, FFR_RATE4, FFR_RATE5,
        FFR_USED_IN_PRECALC_FIN)
    )) into lx_data
  from FAL_FACTORY_RATE
  where FAL_FACTORY_FLOOR_ID = Id;

  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(FAL_FACTORY_RATE,
        XMLElement(list, lx_data)
      )into lx_data
    from DUAL;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_fal_factory_account(
  id in fal_factory_floor.fal_factory_floor_id%type)
  return XMLType
is
  lx_data XMLType;
begin
  if (id is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'FAL_FACTORY_FLOOR_ID,C_FAL_ENTRY_SIGN,C_FAL_ENTRY_TYPE' as TABLE_KEY,
        FAL_FACTORY_ACCOUNT_ID),
      rep_pc_functions.get_descodes('C_FAL_ENTRY_TYPE', C_FAL_ENTRY_TYPE),
      rep_pc_functions.get_descodes('C_FAL_ENTRY_SIGN', C_FAL_ENTRY_SIGN),
      rep_log_functions_link.get_doc_record_link(DOC_RECORD_ID),
      rep_fin_functions_link.get_acs_cda_account_link(ACS_CDA_ACCOUNT_ID),
      rep_fin_functions_link.get_acs_fin_account_link(ACS_FINANCIAL_ACCOUNT_ID),
      rep_fin_functions_link.get_acs_div_account_link(ACS_DIVISION_ACCOUNT_ID),
      rep_fin_functions_link.get_acs_cpn_account_link(ACS_CPN_ACCOUNT_ID),
      rep_fin_functions_link.get_acs_pf_account_link(ACS_PF_ACCOUNT_ID),
      rep_fin_functions_link.get_acs_pj_account_link(ACS_PJ_ACCOUNT_ID),
      rep_fin_functions_link.get_acs_qty_unit_link(ACS_QTY_UNIT_ID)
      --GAL_COST_CENTER_ID
    )) into lx_data
  from FAL_FACTORY_ACCOUNT
  where FAL_FACTORY_FLOOR_ID = Id;

  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(FAL_FACTORY_ACCOUNT,
        XMLElement(list, lx_data)
      )into lx_data
    from DUAL;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

END REP_IND_FUNCTIONS;
