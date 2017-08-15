--------------------------------------------------------
--  DDL for Package Body ASA_LIB_RECORD_TRF_UTL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_LIB_RECORD_TRF_UTL" 
/**
 * Fonctions utilitaire pour transfert de documents Xml de dossiers SAV.
 *
 * @version 1.0
 * @date 05/2012
 * @author spfister
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 *
 * Modifications:
 */
AS

function to_string(
  it_merge_context IN asa_typ_record_trf_def.T_MERGE_CONTEXT)
  return VARCHAR2
is
begin
  return '{'||
    'record_id='||to_char(it_merge_context.record_id)||
    ',record_events_id='||to_char(it_merge_context.record_events_id)||
    ',custom_partner_id='||to_char(it_merge_context.custom_partner_id)||
    ',update_mode='||case it_merge_context.update_mode
                      when fwk_i_typ_definition.INSERTING then 'Insert'
                       when fwk_i_typ_definition.UPDATING then 'Update'
                       when fwk_i_typ_definition.DELETING then 'Delete'
                       else 'UNKNOWN ('||to_char(it_merge_context.update_mode)||')'
                     end||
  '}';
end;

function to_string(
  it_pc_cntry_link IN asa_typ_record_trf_def.T_PC_CNTRY_LINK)
  return VARCHAR2
is
begin
  return '{' ||
    'cntid='||it_pc_cntry_link.cntid||
    ',pc_cntry_id='||it_pc_cntry_link.pc_cntry_id||
  '}';
end;

function to_string(
  it_pc_lang_link IN asa_typ_record_trf_def.T_PC_LANG_LINK)
  return VARCHAR2
is
begin
  return '{' ||
    'lanid='||it_pc_lang_link.lanid||
    ',pc_lang_id='||it_pc_lang_link.pc_lang_id||
  '}';
end;

function to_string(
  it_doc_record_link IN asa_typ_record_trf_def.T_DOC_RECORD_LINK)
  return VARCHAR2
is
begin
  return '{' ||
    'rco_title='||it_doc_record_link.rco_title||
    ',rco_number='||it_doc_record_link.rco_number||
    ',doc_record_id='||it_doc_record_link.doc_record_id||
  '}';
end;

function to_string(
  it_doc_gauge_link IN asa_typ_record_trf_def.T_DOC_GAUGE_LINK)
  return VARCHAR2
is
begin
  return '{' ||
    'c_admin_domain='||it_doc_gauge_link.c_admin_domain||
    ',c_gauge_type='||it_doc_gauge_link.c_gauge_type||
    ',gau_describe='||it_doc_gauge_link.gau_describe||
    ',doc_gauge_id='||it_doc_gauge_link.doc_gauge_id||
  '}';
end;

function to_string(
  it_pac_representative_link IN asa_typ_record_trf_def.T_PAC_REPRESENTATIVE_LINK)
  return VARCHAR2
is
begin
  return '{' ||
    'rep_descr='||it_pac_representative_link.rep_descr||
    ',pac_representative_id='||it_pac_representative_link.pac_representative_id||
  '}';
end;

function to_string(
  it_pac_person_link IN asa_typ_record_trf_def.T_PAC_PERSON_LINK)
  return VARCHAR2
is
begin
  return '{' ||
    'per_key1='||it_pac_person_link.per_key1||
    ',per_key2='||it_pac_person_link.per_key2||
    ',pac_person_id='||it_pac_person_link.pac_person_id||
  '}';
end;

function to_string(
  it_pac_address_link IN asa_typ_record_trf_def.T_PAC_ADDRESS_LINK)
  return VARCHAR2
is
begin
  return '{' ||
    'dic_address_type='||to_string(it_pac_address_link.dic_address_type)||
    ',per_key1='||it_pac_address_link.per_key1||
    ',per_key2='||it_pac_address_link.per_key2||
    ',pac_address_id='||it_pac_address_link.pac_address_id||
  '}';
end;

function to_string(
  it_asa_rep_type_link IN asa_typ_record_trf_def.T_ASA_REP_TYPE_LINK)
  return VARCHAR2
is
begin
  return '{' ||
    'ret_rep_type='||it_asa_rep_type_link.ret_rep_type||
    ',asa_rep_type_id='||it_asa_rep_type_link.asa_rep_type_id||
  '}';
end;

function to_string(
  it_gco_good_link IN asa_typ_record_trf_def.T_GCO_GOOD_LINK)
  return VARCHAR2
is
begin
  return '{' ||
    'goo_major_reference='||it_gco_good_link.goo_major_reference||
    ',gco_good_id='||it_gco_good_link.gco_good_id||
  '}';
end;

function to_string(
  it_currency_link IN asa_typ_record_trf_def.T_CURRENCY_LINK)
  return VARCHAR2
is
begin
  return '{' ||
    'currency='||it_currency_link.currency||
    ',acs_financial_currency_id='||it_currency_link.acs_financial_currency_id||
  '}';
end;

function to_string(
  it_fal_task_link IN asa_typ_record_trf_def.T_FAL_TASK_LINK)
  return VARCHAR2
is
begin
  return '{' ||
    'tas_ref='||it_fal_task_link.tas_ref||
    ',fal_task_id='||it_fal_task_link.fal_task_id||
  '}';
end;


function to_string(
  it_company IN asa_typ_record_trf_def.T_COMPANY_DEF)
  return VARCHAR2
is
begin
  return '{' ||
    'instance_name='||it_company.instance_name||
    ',schema_name='||it_company.schema_name||
    ',company_name='||it_company.company_name||
  '}';
end;

function to_string(
  it_company IN asa_typ_record_trf_def.T_SENDER_COMPANY)
  return VARCHAR2
is
begin
  return '{' ||
    'instance_name='||it_company.instance_name||
    ',schema_name='||it_company.schema_name||
    ',company_name='||it_company.company_name||
    ',recipient_key='||it_company.recipient_key||
  '}';
end;

function to_string(
  it_header_data IN asa_typ_record_trf_def.T_HEADER_DATA)
  return VARCHAR2
is
begin
  return '{' ||
    'source_company='||to_string(it_header_data.source_company)||
    ',are_number='||it_header_data.are_number||
    ',are_src_number='||it_header_data.are_src_number||
    ',asa_rep_type='||to_string(it_header_data.asa_rep_type)||
    ',doc_gauge='||to_string(it_header_data.doc_gauge)||
    ',c_asa_rep_type_kind='||it_header_data.c_asa_rep_type_kind||
    ',c_asa_rep_status='||it_header_data.c_asa_rep_status||
    ',are_datecre='||rep_utils.DateToReplicatorDate(it_header_data.are_datecre)||
    ',are_update_status='||rep_utils.DateToReplicatorDate(it_header_data.are_update_status)||
    ',are_print_status='||rep_utils.DateToReplicatorDate(it_header_data.are_print_status)||
    ',are_internal_remark='||it_header_data.are_internal_remark||
    ',are_req_date_text='||it_header_data.are_req_date_text||
    ',are_customer_remark='||it_header_data.are_customer_remark||
    ',are_additional_items='||it_header_data.are_additional_items||
    ',are_customs_value='||it_header_data.are_customs_value||
    ',doc_record='||to_string(it_header_data.doc_record)||
    ',pac_representative='||to_string(it_header_data.pac_representative)||
    ',acs_custom_fin_curr='||to_string(it_header_data.acs_custom_fin_curr)||
    ',customer_lang='||to_string(it_header_data.customer_lang)||
  '}';
end;

function to_string(
  it_description IN asa_typ_record_trf_def.T_DESCRIPTION)
  return VARCHAR2
is
begin
  return '{' ||
    'pc_lang='||to_string(it_description.pc_lang)||
    ',short_description='||it_description.short_description||
    ',long_description='||it_description.long_description||
    ',free_description='||it_description.free_description||
  '}';
end;
function to_string(
  itt_descriptions IN asa_typ_record_trf_def.TT_DESCRIPTIONS)
  return VARCHAR2
is
  lv_result VARCHAR2(32767);
begin
  if (itt_descriptions is null or itt_descriptions.COUNT = 0) then
    return null;
  end if;
  for cpt in itt_descriptions.FIRST .. itt_descriptions.LAST loop
    lv_result := lv_result ||','|| to_string(itt_descriptions(cpt));
  end loop;
  return '[' || LTrim(lv_result,',') || ']';
end;

function to_string(
  it_address IN asa_typ_record_trf_def.T_ADDRESS)
  return VARCHAR2
is
begin
  return '{' ||
    'are_address='||it_address.are_address||
    ',are_care_of='||it_address.are_care_of||
    ',are_contact='||it_address.are_contact||
    ',are_county='||it_address.are_county||
    ',are_format_city='||it_address.are_format_city||
    ',are_po_box_nbr='||it_address.are_po_box_nbr||
    ',are_po_box='||it_address.are_po_box||
    ',are_postcode='||it_address.are_postcode||
    ',are_state='||it_address.are_state||
    ',are_town='||it_address.are_town||
    ',pac_address='||to_string(it_address.pac_address)||
    ',pc_cntry='||to_string(it_address.pc_cntry)||
  '}';
end;
function to_string(
  it_address_e IN asa_typ_record_trf_def.T_ADDRESS_E)
  return VARCHAR2
is
begin
  return '{' ||
    'are_address='||it_address_e.are_address||
    ',are_care_of='||it_address_e.are_care_of||
    ',are_county='||it_address_e.are_county||
    ',are_format_city='||it_address_e.are_format_city||
    ',are_po_box='||it_address_e.are_po_box||
    ',are_po_box_nbr='||it_address_e.are_po_box_nbr||
    ',are_postcode='||it_address_e.are_postcode||
    ',are_state='||it_address_e.are_state||
    ',are_town='||it_address_e.are_town||
    ',pac_address='||to_string(it_address_e.pac_address)||
    ',pc_cntry='||to_string(it_address_e.pc_cntry)||
    ',pc_lang='||to_string(it_address_e.pc_lang)||
  '}';
end;

function to_string(
  it_addresses IN asa_typ_record_trf_def.T_ADDRESSES)
  return VARCHAR2
is
begin
  return '{' ||
    'sold_to='||to_string(it_addresses.sold_to)||
    ',delivered_to='||to_string(it_addresses.delivered_to)||
    ',invoiced_to='||to_string(it_addresses.invoiced_to)||
    ',agent='||to_string(it_addresses.agent)||
    ',retailer='||to_string(it_addresses.retailer)||
    ',final_customer='||to_string(it_addresses.final_customer)||
  '}';
end;

function to_string(
  it_product_to_repair IN asa_typ_record_trf_def.T_PRODUCT_TO_REPAIR)
  return VARCHAR2
is
begin
  return '{' ||
    'gco_good='||to_string(it_product_to_repair.gco_good)||
    -- PRODUCT_CHARACTERISTICS
    ',characterizations='||to_string(it_product_to_repair.characterizations)||
    -- REFERENCES
    ',are_good_ref_1='||it_product_to_repair.are_good_ref_1||
    ',are_good_ref_2='||it_product_to_repair.are_good_ref_2||
    ',are_good_ref_3='||it_product_to_repair.are_good_ref_3||
    ',are_customer_ref='||it_product_to_repair.are_customer_ref||
    ',are_good_new_ref='||it_product_to_repair.are_good_new_ref||
    -- DESCRIPTIONS
    ',are_gco_short_descr='||it_product_to_repair.are_gco_short_descr||
    ',are_gco_long_descr='||it_product_to_repair.are_gco_long_descr||
    ',are_gco_free_descr='||it_product_to_repair.are_gco_free_descr||
  '}';
end;

function to_string(
  it_product_with_characts IN asa_typ_record_trf_def.T_PRODUCT_WITH_CHARACTS)
  return VARCHAR2
is
begin
  return '{' ||
    'gco_good='||to_string(it_product_with_characts.gco_good)||
    -- PRODUCT_CHARACTERISTICS
    ',characterizations='||to_string(it_product_with_characts.characterizations)||
  '}';
end;

function to_string(
  it_product_simple IN asa_typ_record_trf_def.T_PRODUCT_SIMPLE)
  return VARCHAR2
is
begin
  return '{' ||
    'gco_good='||to_string(it_product_simple.gco_good)||
  '}';
end;


function to_string(
  it_amounts IN asa_typ_record_trf_def.T_AMOUNTS)
  return VARCHAR2
is
begin
  return '{' ||
    -- CURRENCY
    'currency='||to_string(it_amounts.currency)||
    ',are_curr_base_price='||it_amounts.are_curr_base_price||
    ',are_curr_rate_euro='||it_amounts.are_curr_rate_euro||
    ',are_curr_rate_of_exch='||it_amounts.are_curr_rate_of_exch||
    ',are_euro_currency='||it_amounts.are_euro_currency||
    -- COST_PRICE
    ',are_cost_price_c='||it_amounts.are_cost_price_c||
    ',are_cost_price_t='||it_amounts.are_cost_price_t||
    ',are_cost_price_w='||it_amounts.are_cost_price_w||
    ',are_cost_price_s='||it_amounts.are_cost_price_s||
    -- SALE_PRICE
    ',are_sale_price_c='||it_amounts.are_sale_price_c||
    ',are_sale_price_s='||it_amounts.are_sale_price_s||
    ',are_sale_price_t_euro='||it_amounts.are_sale_price_t_euro||
    ',are_sale_price_t_mb='||it_amounts.are_sale_price_t_mb||
    ',are_sale_price_t_me='||it_amounts.are_sale_price_t_me||
    ',are_sale_price_w='||it_amounts.are_sale_price_w||
  '}';
end;

function to_string(
  it_warranty IN asa_typ_record_trf_def.T_WARRANTY)
  return VARCHAR2
is
begin
  return '{' ||
    'are_customer_error='||it_warranty.are_customer_error||
    ',are_begin_guaranty_date='||rep_utils.DateToReplicatorDate(it_warranty.are_begin_guaranty_date)||
    ',are_end_guaranty_date='||rep_utils.DateToReplicatorDate(it_warranty.are_end_guaranty_date)||
    ',are_det_sale_date='||rep_utils.DateToReplicatorDate(it_warranty.are_det_sale_date)||
    ',are_det_sale_date_text='||it_warranty.are_det_sale_date_text||
    ',are_fin_sale_date='||rep_utils.DateToReplicatorDate(it_warranty.are_fin_sale_date)||
    ',are_fin_sale_date_text='||it_warranty.are_fin_sale_date_text||
    ',are_generate_bill='||it_warranty.are_generate_bill||
    ',are_guaranty='||it_warranty.are_guaranty||
    ',are_guaranty_code='||it_warranty.are_guaranty_code||
    ',are_offered_code='||it_warranty.are_offered_code||
    ',are_rep_begin_guar_date='||rep_utils.DateToReplicatorDate(it_warranty.are_rep_begin_guar_date)||
    ',are_rep_end_guar_date='||rep_utils.DateToReplicatorDate(it_warranty.are_rep_end_guar_date)||
    ',are_rep_guar='||it_warranty.are_rep_guar||
    ',are_sale_date='||rep_utils.DateToReplicatorDate(it_warranty.are_sale_date)||
    ',are_sale_date_text='||it_warranty.are_sale_date_text||
    ',asa_guaranty_cards='||it_warranty.agc_number||
    ',c_asa_guaranty_unit='||it_warranty.c_asa_guaranty_unit||
    ',c_asa_rep_guar_unit='||it_warranty.c_asa_rep_guar_unit||
    ',dic_garanty_code='||to_string(it_warranty.dic_garanty_code)||
  '}';
end;

function to_string(
  it_diagnostic IN asa_typ_record_trf_def.T_DIAGNOSTIC)
  return VARCHAR2
is
begin
  return '{' ||
    'source_company='||to_string(it_diagnostic.source_company)||
    ',dia_sequence='||it_diagnostic.dia_sequence||
    ',c_asa_context='||it_diagnostic.c_asa_context||
    ',dic_diagnostics_type='||to_string(it_diagnostic.dic_diagnostics_type)||
    ',dic_operator='||to_string(it_diagnostic.dic_operator)||
    ',dia_diagnostics_text='||it_diagnostic.dia_diagnostics_text||
  '}';
end;
function to_string(
  itt_diagnostics IN asa_typ_record_trf_def.TT_DIAGNOSTICS)
  return VARCHAR2
is
  lv_result VARCHAR2(32767);
begin
  if (itt_diagnostics is null or itt_diagnostics.COUNT = 0) then
    return null;
  end if;
  for cpt in itt_diagnostics.FIRST .. itt_diagnostics.LAST loop
    lv_result := lv_result ||','|| to_string(itt_diagnostics(cpt));
  end loop;
  return '[' || LTrim(lv_result,',') || ']';
end;

function to_string(
  it_dictionary in asa_typ_record_trf_def.T_DICTIONARY)
  return VARCHAR2
is
begin
  return '{' ||
    'value='||it_dictionary.value||
    ',descriptions'||to_string(it_dictionary.descriptions)||
    ',additional_fields'||to_string(it_dictionary.additional_fields)||
  '}';
end;

function to_string(
  it_dictionary_description in asa_typ_record_trf_def.T_DICTIONARY_DESCRIPTION)
  return VARCHAR2
is
begin
  return '{' ||
    'pc_lang='||to_string(it_dictionary_description.pc_lang)||
    ',value='||it_dictionary_description.value||
  '}';
end;
function to_string(
  itt_dictionary_descriptions in asa_typ_record_trf_def.TT_DICTIONARY_DESCRIPTIONS)
  return VARCHAR2
is
  lv_result VARCHAR2(32767);
begin
  if (itt_dictionary_descriptions is null or itt_dictionary_descriptions.COUNT = 0) then
    return null;
  end if;
  for cpt in itt_dictionary_descriptions.FIRST .. itt_dictionary_descriptions.LAST loop
    lv_result := lv_result ||','|| to_string(itt_dictionary_descriptions(cpt));
  end loop;
  return '[' || LTrim(lv_result,',') || ']';
end;

function to_string(
  it_dictionary_field in asa_typ_record_trf_def.T_DICTIONARY_FIELD)
  return VARCHAR2
is
begin
  return '{' ||
    'name='||it_dictionary_field.name||
    ',value='||it_dictionary_field.value||
  '}';
end;
function to_string(
  itt_dictionary_fields in asa_typ_record_trf_def.TT_DICTIONARY_FIELDS)
  return VARCHAR2
is
  lv_result VARCHAR2(32767);
begin
  if (itt_dictionary_fields is null or itt_dictionary_fields.COUNT = 0) then
    return null;
  end if;
  for cpt in itt_dictionary_fields.FIRST .. itt_dictionary_fields.LAST loop
    lv_result := lv_result ||','|| to_string(itt_dictionary_fields(cpt));
  end loop;
  return '[' || LTrim(lv_result,',') || ']';
end;


function to_string(
  it_pc_appltxt_link IN asa_typ_record_trf_def.T_PC_APPLTXT_LINK)
  return VARCHAR2
is
begin
  return '{' ||
    'c_text_type='||it_pc_appltxt_link.c_text_type||
    ',dic_pc_theme='||to_string(it_pc_appltxt_link.dic_pc_theme)||
    ',aph_code='||it_pc_appltxt_link.aph_code||
  '}';
end;

function to_string(
  it_document_text IN asa_typ_record_trf_def.T_DOCUMENT_TEXT)
  return VARCHAR2
is
begin
  return '{' ||
    'pc_appltxt='||to_string(it_document_text.pc_appltxt)||
    ',c_asa_text_type='||it_document_text.c_asa_text_type||
    ',c_asa_gauge_type='||it_document_text.c_asa_gauge_type||
    ',ate_text='||it_document_text.ate_text||
  '}';
end;
function to_string(
  itt_document_texts IN asa_typ_record_trf_def.TT_DOCUMENT_TEXTS)
  return VARCHAR2
is
  lv_result VARCHAR2(32767);
begin
  if (itt_document_texts is null or itt_document_texts.COUNT = 0) then
    return null;
  end if;
  for cpt in itt_document_texts.FIRST .. itt_document_texts.LAST loop
    lv_result := lv_result ||','|| to_string(itt_document_texts(cpt));
  end loop;
  return '[' || LTrim(lv_result,',') || ']';
end;

function to_string(
  it_boolean_code IN asa_typ_record_trf_def.T_BOOLEAN_CODE)
  return VARCHAR2
is
begin
  return '{' ||
    'dic_asa_boolean_code_type='||to_string(it_boolean_code.dic_asa_boolean_code_type)||
    ',fco_boo_code='||it_boolean_code.fco_boo_code||
  '}';
end;
function to_string(
  itt_boolean_codes IN asa_typ_record_trf_def.TT_BOOLEAN_CODES)
  return VARCHAR2
is
  lv_result VARCHAR2(32767);
begin
  if (itt_boolean_codes is null or itt_boolean_codes.COUNT = 0) then
    return null;
  end if;
  for cpt in itt_boolean_codes.FIRST .. itt_boolean_codes.LAST loop
    lv_result := lv_result ||','|| to_string(itt_boolean_codes(cpt));
  end loop;
  return '[' || LTrim(lv_result,',') || ']';
end;

function to_string(
  it_number_code IN asa_typ_record_trf_def.T_NUMBER_CODE)
  return VARCHAR2
is
begin
  return '{' ||
    'dic_asa_number_code_type='||to_string(it_number_code.dic_asa_number_code_type)||
    ',fco_num_code='||it_number_code.fco_num_code||
  '}';
end;
function to_string(
  itt_number_codes IN asa_typ_record_trf_def.TT_NUMBER_CODES)
  return VARCHAR2
is
  lv_result VARCHAR2(32767);
begin
  if (itt_number_codes is null or itt_number_codes.COUNT = 0) then
    return null;
  end if;
  for cpt in itt_number_codes.FIRST .. itt_number_codes.LAST loop
    lv_result := lv_result ||','|| to_string(itt_number_codes(cpt));
  end loop;
  return '[' || LTrim(lv_result,',') || ']';
end;

function to_string(
  it_memo_code IN asa_typ_record_trf_def.T_MEMO_CODE)
  return VARCHAR2
is
begin
  return '{' ||
    'dic_asa_memo_code_type='||to_string(it_memo_code.dic_asa_memo_code_type)||
    ',fco_mem_code='||it_memo_code.fco_mem_code||
  '}';
end;
function to_string(
  itt_memo_codes IN asa_typ_record_trf_def.TT_MEMO_CODES)
  return VARCHAR2
is
  lv_result VARCHAR2(32767);
begin
  if (itt_memo_codes is null or itt_memo_codes.COUNT = 0) then
    return null;
  end if;
  for cpt in itt_memo_codes.FIRST .. itt_memo_codes.LAST loop
    lv_result := lv_result ||','|| to_string(itt_memo_codes(cpt));
  end loop;
  return '[' || LTrim(lv_result,',') || ']';
end;

function to_string(
  it_date_code IN asa_typ_record_trf_def.T_DATE_CODE)
  return VARCHAR2
is
begin
  return '{' ||
    'dic_asa_date_code_type='||to_string(it_date_code.dic_asa_date_code_type)||
    ',fco_dat_code='||rep_utils.DateToReplicatorDate(it_date_code.fco_dat_code)||
  '}';
end;
function to_string(
  itt_date_codes IN asa_typ_record_trf_def.TT_DATE_CODES)
  return VARCHAR2
is
  lv_result VARCHAR2(32767);
begin
  if (itt_date_codes is null or itt_date_codes.COUNT = 0) then
    return null;
  end if;
  for cpt in itt_date_codes.FIRST .. itt_date_codes.LAST loop
    lv_result := lv_result ||','|| to_string(itt_date_codes(cpt));
  end loop;
  return '[' || LTrim(lv_result,',') || ']';
end;

function to_string(
  it_char_code IN asa_typ_record_trf_def.T_CHAR_CODE)
  return VARCHAR2
is
begin
  return '{' ||
    'dic_asa_char_code_type='||to_string(it_char_code.dic_asa_char_code_type)||
    ',fco_cha_code='||it_char_code.fco_cha_code||
  '}';
end;
function to_string(
  itt_char_codes IN asa_typ_record_trf_def.TT_CHAR_CODES)
  return VARCHAR2
is
  lv_result VARCHAR2(32767);
begin
  if (itt_char_codes is null or itt_char_codes.COUNT = 0) then
    return null;
  end if;
  for cpt in itt_char_codes.FIRST .. itt_char_codes.LAST loop
    lv_result := lv_result ||','|| to_string(itt_char_codes(cpt));
  end loop;
  return '[' || LTrim(lv_result,',') || ']';
end;

function to_string(
  it_record_free_codes IN asa_typ_record_trf_def.T_RECORD_FREE_CODES)
  return VARCHAR2
is
begin
  return '{' ||
    'boolean_codes='||to_string(it_record_free_codes.boolean_codes)||
    ',number_codes='||to_string(it_record_free_codes.number_codes)||
    ',memo_codes='||to_string(it_record_free_codes.memo_codes)||
    ',date_codes='||to_string(it_record_free_codes.date_codes)||
    ',char_codes='||to_string(it_record_free_codes.char_codes)||
  '}';
end;

function to_string(
  it_record_free_data_def IN asa_typ_record_trf_def.T_RECORD_FREE_DATA_DEF)
  return VARCHAR2
is
begin
  return '{' ||
    'ard_alpha_short='||it_record_free_data_def.ard_alpha_short||
    ',ard_alpha_long='||it_record_free_data_def.ard_alpha_long||
    ',ard_integer='||it_record_free_data_def.ard_integer||
    ',ard_decimal='||it_record_free_data_def.ard_decimal||
    ',ard_boolean='||it_record_free_data_def.ard_boolean||
    ',dic_asa_rec_free='||to_string(it_record_free_data_def.dic_asa_rec_free)||
  '}';
end;

function to_string(
  it_record_free_data IN asa_typ_record_trf_def.T_RECORD_FREE_DATA)
  return VARCHAR2
is
begin
  return '{' ||
    'free_data_01='||to_string(it_record_free_data.free_data_01)||
    ',free_data_02='||to_string(it_record_free_data.free_data_02)||
    ',free_data_03='||to_string(it_record_free_data.free_data_03)||
    ',free_data_04='||to_string(it_record_free_data.free_data_04)||
    ',free_data_05='||to_string(it_record_free_data.free_data_05)||
  '}';
end;

function to_string(
  itt_vfields IN asa_typ_record_trf_def.TT_VFIELD_BOOLEANS)
  return VARCHAR2
is
  field VARCHAR2(32);
  lv_result VARCHAR2(32767);
begin
  if (itt_vfields.COUNT = 0) then
    return null;
  end if;
  field := itt_vfields.FIRST;
  loop
    lv_result := lv_result ||','|| field ||'='|| itt_vfields(field);
    field := itt_vfields.NEXT(field);
    exit when field is null;
  end loop;
  return '[' || LTrim(lv_result,',') || ']';
end;
function to_string(
  itt_vfields IN asa_typ_record_trf_def.TT_VFIELD_MEMOS)
  return VARCHAR2
is
  field VARCHAR2(32);
  lv_result VARCHAR2(32767);
begin
  if (itt_vfields.COUNT = 0) then
    return null;
  end if;
  field := itt_vfields.FIRST;
  loop
    lv_result := lv_result ||','|| field ||'='|| itt_vfields(field);
    field := itt_vfields.NEXT(field);
    exit when field is null;
  end loop;
  return '[' || LTrim(lv_result,',') || ']';
end;
function to_string(
  itt_vfields IN asa_typ_record_trf_def.TT_VFIELD_CHARS)
  return VARCHAR2
is
  field VARCHAR2(32);
  lv_result VARCHAR2(32767);
begin
  if (itt_vfields.COUNT = 0) then
    return null;
  end if;
  field := itt_vfields.FIRST;
  loop
    lv_result := lv_result ||','|| field ||'='|| itt_vfields(field);
    field := itt_vfields.NEXT(field);
    exit when field is null;
  end loop;
  return '[' || LTrim(lv_result,',') || ']';
end;
function to_string(
  itt_vfields IN asa_typ_record_trf_def.TT_VFIELD_DATES)
  return VARCHAR2
is
  field VARCHAR2(32);
  lv_result VARCHAR2(32767);
begin
  if (itt_vfields.COUNT = 0) then
    return null;
  end if;
  field := itt_vfields.FIRST;
  loop
    lv_result := lv_result ||','|| field ||'='|| rep_utils.DateToReplicatorDate(itt_vfields(field));
    field := itt_vfields.NEXT(field);
    exit when field is null;
  end loop;
  return '[' || LTrim(lv_result,',') || ']';
end;
function to_string(
  itt_vfields IN asa_typ_record_trf_def.TT_VFIELD_INTEGERS)
  return VARCHAR2
is
  field VARCHAR2(32);
  lv_result VARCHAR2(32767);
begin
  if (itt_vfields.COUNT = 0) then
    return null;
  end if;
  field := itt_vfields.FIRST;
  loop
    lv_result := lv_result ||','|| field ||'='|| itt_vfields(field);
    field := itt_vfields.NEXT(field);
    exit when field is null;
  end loop;
  return '[' || LTrim(lv_result,',') || ']';
end;
function to_string(
  itt_vfields IN asa_typ_record_trf_def.TT_VFIELD_FLOATS)
  return VARCHAR2
is
  field VARCHAR2(32);
  lv_result VARCHAR2(32767);
begin
  if (itt_vfields.COUNT = 0) then
    return null;
  end if;
  field := itt_vfields.FIRST;
  loop
    lv_result := lv_result ||','|| field ||'='|| itt_vfields(field);
    field := itt_vfields.NEXT(field);
    exit when field is null;
  end loop;
  return '[' || LTrim(lv_result,',') || ']';
end;
function to_string(
  itt_vfields IN asa_typ_record_trf_def.TT_VFIELD_DESCODES)
  return VARCHAR2
is
  field VARCHAR2(32);
  lv_result VARCHAR2(32767);
begin
  if (itt_vfields.COUNT = 0) then
    return null;
  end if;
  field := itt_vfields.FIRST;
  loop
    lv_result := lv_result ||','|| field ||'='|| itt_vfields(field);
    field := itt_vfields.NEXT(field);
    exit when field is null;
  end loop;
  return '[' || LTrim(lv_result,',') || ']';
end;

function to_string(
  it_virtual_fields IN asa_typ_record_trf_def.T_VIRTUAL_FIELDS)
  return VARCHAR2
is
  lv_result VARCHAR2(32767);
begin
  return '{' ||
    'booleans='||to_string(it_virtual_fields.booleans)||
    ',memos='||to_string(it_virtual_fields.memos)||
    ',chars='||to_string(it_virtual_fields.chars)||
    ',dates='||to_string(it_virtual_fields.dates)||
    ',integers='||to_string(it_virtual_fields.integers)||
    ',floats='||to_string(it_virtual_fields.floats)||
    ',descodes='||to_string(it_virtual_fields.descodes)||
  '}';
end;

function to_string(
  it_header IN asa_typ_record_trf_def.T_HEADER)
  return VARCHAR2
is
begin
  return '{' ||
    'header_data='||to_string(it_header.header_data)||
    ',internal_descriptions='||to_string(it_header.internal_descriptions)||
    ',external_descriptions='||to_string(it_header.external_descriptions)||
    ',addresses='||to_string(it_header.addresses)||
    ',product_to_repair='||to_string(it_header.product_to_repair)||
    ',repaired_product='||to_string(it_header.repaired_product)||
    ',product_for_exchange='||to_string(it_header.product_for_exchange)||
    ',product_for_invoice='||to_string(it_header.product_for_invoice)||
    ',product_for_estimate_invoice='||to_string(it_header.product_for_estimate_invoice)||
    ',amounts='||to_string(it_header.amounts)||
    ',warranty='||to_string(it_header.warranty)||
    ',diagnostics='||to_string(it_header.diagnostics)||
    ',document_texts='||to_string(it_header.document_texts)||
    ',free_codes='||to_string(it_header.free_codes)||
    ',free_data='||to_string(it_header.free_data)||
    ',virtual_fields='||to_string(it_header.virtual_fields)||
  '}';
end;

function to_string(
  it_owned_by IN asa_typ_record_trf_def.T_OWNED_BY)
  return VARCHAR2
is
begin
  return '{' ||
    'schema_name='||it_owned_by.schema_name||
    ',company_name='||it_owned_by.company_name||
  '}';
end;

function to_string(
  it_product_characteristic IN asa_typ_record_trf_def.T_PRODUCT_CHARACTERISTIC)
  return VARCHAR2
is
begin
  return '{' ||
    'characterization_type='||it_product_characteristic.characterization_type||
    ',value='||it_product_characteristic.value||
  '}';
end;
function to_string(
  itt_product_characteristics IN asa_typ_record_trf_def.TT_PRODUCT_CHARACTERISTICS)
  return VARCHAR2
is
  lv_result VARCHAR2(32767);
begin
  if (itt_product_characteristics is null or itt_product_characteristics.COUNT = 0) then
    return null;
  end if ;
  for cpt in itt_product_characteristics.FIRST .. itt_product_characteristics.LAST loop
    lv_result := lv_result ||','|| to_string(itt_product_characteristics(cpt));
  end loop;
  return '[' || LTrim(lv_result,',') || ']';
end;

function to_string(
  it_component_free_data_dic_def IN asa_typ_record_trf_def.T_COMPONENT_FREE_DATA_DIC_DEF)
  return VARCHAR2
is
begin
  return '{' ||
    'arc_free_num='||it_component_free_data_dic_def.arc_free_num||
    ',arc_free_char='||it_component_free_data_dic_def.arc_free_char||
    ',dic_asa_free_dico_comp='||to_string(it_component_free_data_dic_def.dic_asa_free_dico_comp)||
  '}';
end;
function to_string(
  it_component_free_data_def IN asa_typ_record_trf_def.T_COMPONENT_FREE_DATA_DEF)
  return VARCHAR2
is
begin
  return '{' ||
    'arc_free_num='||it_component_free_data_def.arc_free_num||
    ',arc_free_char='||it_component_free_data_def.arc_free_char||
  '}';
end;
function to_string(
  it_component_free_data IN asa_typ_record_trf_def.T_COMPONENT_FREE_DATA)
  return VARCHAR2
is
begin
  return '{' ||
    'free_data_01='||to_string(it_component_free_data.free_data_01)||
    ',free_data_02='||to_string(it_component_free_data.free_data_02)||
    ',free_data_03='||to_string(it_component_free_data.free_data_03)||
    ',free_data_04='||to_string(it_component_free_data.free_data_04)||
    ',free_data_05='||to_string(it_component_free_data.free_data_05)||
  '}';
end;

function to_string(
  it_component IN asa_typ_record_trf_def.T_COMPONENT)
  return VARCHAR2
is
begin
  return '{' ||
    'source_company='||to_string(it_component.source_company)||
    ',owned_by='||to_string(it_component.owned_by)||
    -- COMPONENT_DATA
    ',arc_position='||it_component.arc_position||
    ',arc_cdmvt='||it_component.arc_cdmvt||
    ',c_asa_gen_doc_pos='||it_component.c_asa_gen_doc_pos||
    --OPTION
    ',arc_optional='||it_component.arc_optional||
    ',c_asa_accept_option='||it_component.c_asa_accept_option||
    ',dic_asa_option='||to_string(it_component.dic_asa_option)||
    --WARRANTY
    ',dic_garanty_code='||to_string(it_component.dic_garanty_code)||
    ',arc_guaranty_code='||it_component.arc_guaranty_code||
    --PRODUCT
    ',gco_good='||to_string(it_component.gco_good)||
    ',arc_quantity='||it_component.arc_quantity||
    ',characterizations='||to_string(it_component.characterizations)||
    --DESCRIPTIONS
    ',arc_descr='||it_component.arc_descr||
    ',arc_descr2='||it_component.arc_descr2||
    ',arc_descr3='||it_component.arc_descr3||
    --AMOUNTS
    ',arc_cost_price='||it_component.arc_cost_price||
    ',arc_sale_price='||it_component.arc_sale_price||
    ',arc_sale_price_me='||it_component.arc_sale_price_me||
    ',arc_sale_price_euro='||it_component.arc_sale_price_euro||
    ',arc_sale_price2='||it_component.arc_sale_price2||
    ',arc_sale_price2_me='||it_component.arc_sale_price2_me||
    ',arc_sale_price2_euro='||it_component.arc_sale_price2_euro||
    --
    ',free_data='||to_string(it_component.free_data)||
    ',virtual_fields='||to_string(it_component.virtual_fields)||
  '}';
end;
function to_string(
  itt_components IN asa_typ_record_trf_def.TT_COMPONENTS)
  return VARCHAR2
is
  lv_result VARCHAR2(32767);
begin
  if (itt_components is null or itt_components.COUNT = 0) then
    return null;
  end if ;
  for cpt in itt_components.FIRST .. itt_components.LAST loop
    lv_result := lv_result ||','|| to_string(itt_components(cpt));
  end loop;
  return '[' || LTrim(lv_result,',') || ']';
end;

function to_string(
  it_operation_free_data_dic_def IN asa_typ_record_trf_def.T_OPERATION_FREE_DATA_DIC_DEF)
  return VARCHAR2
is
begin
  return '{' ||
    'ret_free_num='||it_operation_free_data_dic_def.ret_free_num||
    ',ret_free_char='||it_operation_free_data_dic_def.ret_free_char||
    ',dic_asa_free_dico_task='||to_string(it_operation_free_data_dic_def.dic_asa_free_dico_task)||
  '}';
end;
function to_string(
  it_operation_free_data_def IN asa_typ_record_trf_def.T_OPERATION_FREE_DATA_DEF)
  return VARCHAR2
is
begin
  return '{' ||
    'ret_free_num='||it_operation_free_data_def.ret_free_num||
    ',ret_free_char='||it_operation_free_data_def.ret_free_char||
  '}';
end;
function to_string(
  it_operation_free_data IN asa_typ_record_trf_def.T_OPERATION_FREE_DATA)
  return VARCHAR2
is
begin
  return '{' ||
    'free_data_01='||to_string(it_operation_free_data.free_data_01)||
    ',free_data_02='||to_string(it_operation_free_data.free_data_02)||
    ',free_data_03='||to_string(it_operation_free_data.free_data_03)||
    ',free_data_04='||to_string(it_operation_free_data.free_data_04)||
    ',free_data_05='||to_string(it_operation_free_data.free_data_05)||
  '}';
end;

function to_string(
  it_operation IN asa_typ_record_trf_def.T_OPERATION)
  return VARCHAR2
is
begin
  return '{' ||
    'source_company='||to_string(it_operation.source_company)||
    ',owned_by='||to_string(it_operation.owned_by)||
    -- OPERATION_DATA
    ',ret_position='||it_operation.ret_position||
    ',c_asa_gen_doc_pos='||it_operation.c_asa_gen_doc_pos||
    -- OPTION
    ',ret_optional='||it_operation.ret_optional||
    ',c_asa_accept_option='||it_operation.c_asa_accept_option||
    ',dic_asa_option='||to_string(it_operation.dic_asa_option)||
    -- WARRANTY
    ',ret_guaranty_code='||it_operation.ret_guaranty_code||
    ',dic_garanty_code='||to_string(it_operation.dic_garanty_code)||
    -- TASK
    ',fal_task='||to_string(it_operation.fal_task)||
    ',dic_operator='||to_string(it_operation.dic_operator)||
    ',ret_external='||it_operation.ret_external||
    ',ret_begin_date='||rep_utils.DateToReplicatorDate(it_operation.ret_begin_date)||
    ',ret_duration='||it_operation.ret_duration||
    ',ret_end_date='||rep_utils.DateToReplicatorDate(it_operation.ret_end_date)||
    ',ret_finished='||it_operation.ret_finished||
    ',ret_time='||it_operation.ret_time||
    ',ret_time_used='||it_operation.ret_time_used||
    ',ret_work_rate='||it_operation.ret_work_rate||
    ',pac_person='||to_string(it_operation.pac_person)||
    -- PRODUCT
    ',gco_good_to_repair='||to_string(it_operation.gco_good_to_repair)||
    ',gco_good_to_bill='||to_string(it_operation.gco_good_to_bill)||
    -- DESCRIPTIONS
    ',ret_descr='||it_operation.ret_descr||
    ',ret_descr2='||it_operation.ret_descr2||
    ',ret_descr3='||it_operation.ret_descr3||
    -- AMOUNTS
    ',ret_amount='||it_operation.ret_amount||
    ',ret_amount_euro='||it_operation.ret_amount_euro||
    ',ret_amount_me='||it_operation.ret_amount_me||
    ',ret_cost_price='||it_operation.ret_cost_price||
    ',ret_sale_amount='||it_operation.ret_sale_amount||
    ',ret_sale_amount_euro='||it_operation.ret_sale_amount_euro||
    ',ret_sale_amount_me='||it_operation.ret_sale_amount_me||
    ',ret_sale_amount2='||it_operation.ret_sale_amount2||
    ',ret_sale_amount2_euro='||it_operation.ret_sale_amount2_euro||
    ',ret_sale_amount2_me='||it_operation.ret_sale_amount2_me||
    --
    ',free_data='||to_string(it_operation.free_data)||
    ',virtual_fields='||to_string(it_operation.virtual_fields)||
  '}';
end;
function to_string(
  itt_operations IN asa_typ_record_trf_def.TT_OPERATIONS)
  return VARCHAR2
is
  lv_result VARCHAR2(32767);
begin
  if (itt_operations is null or itt_operations.COUNT = 0) then
    return null;
  end if ;
  for cpt in itt_operations.FIRST .. itt_operations.LAST loop
    lv_result := lv_result ||','|| to_string(itt_operations(cpt));
  end loop;
  return '[' || LTrim(lv_result,',') || ']';
end;


function to_string(
  it_message IN asa_typ_record_trf_def.T_MESSAGE)
  return VARCHAR2
is
begin
  return '{' ||
    'message_type='||it_message.message_type||
    ',message_number='||it_message.message_number||
    ',are_number='||it_message.are_number||
    ',message_date='||it_message.message_date||
  '}';
end;

function to_string(
  it_envelope IN asa_typ_record_trf_def.T_ENVELOPE)
  return VARCHAR2
is
begin
  return '{' ||
    'message='||to_string(it_envelope.message)||
    ',original_message='||to_string(it_envelope.original_message)||
    ',comment='||it_envelope.comment||
    ',sender='||to_string(it_envelope.sender)||
    ',recipient='||to_string(it_envelope.recipient)||
  '}';
end;


function to_string(
  it_after_sales_file IN asa_typ_record_trf_def.T_AFTER_SALES_FILE)
  return VARCHAR2
is
begin
  return '{' ||
     'envelope='||to_string(it_after_sales_file.envelope)||
     ',header='||to_string(it_after_sales_file.header)||
     ',components='||to_string(it_after_sales_file.components)||
     ',operations='||to_string(it_after_sales_file.operations)||
  '}';
end;

END ASA_LIB_RECORD_TRF_UTL;
