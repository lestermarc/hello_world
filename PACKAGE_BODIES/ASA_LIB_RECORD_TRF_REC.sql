--------------------------------------------------------
--  DDL for Package Body ASA_LIB_RECORD_TRF_REC
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_LIB_RECORD_TRF_REC" 
/**
 * Fonctions de chargement pour documents Xml de dossiers SAV.
 *
 * @version 1.0
 * @date 04/2012
 * @author spfister
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
AS

  TYPE tt_sorted_list IS TABLE OF asa_typ_record_trf_def.T_PRODUCT_CHARACTERISTIC INDEX BY VARCHAR2(12);

--
-- Identifier resolutions
--

procedure resolve_link(
  iot_header IN OUT NOCOPY asa_typ_record_trf_def.T_HEADER)
is
  cpt BINARY_INTEGER;
  npos BINARY_INTEGER;
begin
  -- HEADER_DATA
  if iot_header.header_data.asa_rep_type.ret_rep_type is not null and
     iot_header.header_data.asa_rep_type.asa_rep_type_id is null then
    begin
      select ASA_REP_TYPE_ID
        into iot_header.header_data.asa_rep_type.asa_rep_type_id
        from ASA_REP_TYPE
       where RET_REP_TYPE = iot_header.header_data.asa_rep_type.ret_rep_type;
    exception
      when NO_DATA_FOUND then
        fwk_i_mgt_exception.raise_exception(
          in_error_code => asa_typ_record_trf_def.EXCEPTION_RESOLVE_LINK_NO,
          iv_message =>
            'Cannot find repair type with '||
              '{RET_REP_TYPE='''||iot_header.header_data.asa_rep_type.ret_rep_type||''''||
            '}',
          iv_stack_trace => fwk_i_lib_trace.call_stack,
          iv_cause => 'resolve_link',
          it_exception_type => fwk_i_mgt_exception.FATAL);
    end;
  end if;

  if (iot_header.header_data.doc_gauge.c_admin_domain is not null and
      iot_header.header_data.doc_gauge.c_gauge_type is not null and
      iot_header.header_data.doc_gauge.gau_describe is not null) and
     iot_header.header_data.doc_gauge.doc_gauge_id is null then
    begin
      select DOC_GAUGE_ID
        into iot_header.header_data.doc_gauge.doc_gauge_id
        from DOC_GAUGE
       where C_ADMIN_DOMAIN = iot_header.header_data.doc_gauge.c_admin_domain and
             C_GAUGE_TYPE = iot_header.header_data.doc_gauge.c_gauge_type and
             GAU_DESCRIBE = iot_header.header_data.doc_gauge.gau_describe;
    exception
      when NO_DATA_FOUND then
        fwk_i_mgt_exception.raise_exception(
          in_error_code => asa_typ_record_trf_def.EXCEPTION_RESOLVE_LINK_NO,
          iv_message =>
            'Cannot find document template with '||
              '{C_ADMIN_DOMAIN='''||iot_header.header_data.doc_gauge.c_admin_domain||''''||
              ',C_GAUGE_TYPE='''||iot_header.header_data.doc_gauge.c_gauge_type||''''||
              ',GAU_DESCRIBE='''||iot_header.header_data.doc_gauge.gau_describe||''''||
            '}',
          iv_stack_trace => fwk_i_lib_trace.call_stack,
          iv_cause => 'resolve_link',
          it_exception_type => fwk_i_mgt_exception.FATAL);
    end;
  end if;

  if (iot_header.header_data.doc_record.rco_title is not null and
      iot_header.header_data.doc_record.rco_number is not null) and
     iot_header.header_data.doc_record.doc_record_id is null then
    begin
      select DOC_RECORD_ID
        into iot_header.header_data.doc_record.doc_record_id
        from DOC_RECORD
       where RCO_TITLE = iot_header.header_data.doc_record.rco_title and
             RCO_NUMBER = iot_header.header_data.doc_record.rco_number;
      exception
        when NO_DATA_FOUND then
          iot_header.header_data.doc_record.doc_record_id := 0.0;
    end;
  end if;

  if iot_header.header_data.pac_representative.rep_descr is not null and
     iot_header.header_data.pac_representative.pac_representative_id is null then
    begin
      select PAC_REPRESENTATIVE_ID
        into iot_header.header_data.pac_representative.pac_representative_id
        from PAC_REPRESENTATIVE
        where REP_DESCR = iot_header.header_data.pac_representative.rep_descr;
      exception
        when NO_DATA_FOUND then
          iot_header.header_data.pac_representative.pac_representative_id := 0.0;
    end;
  end if;

    if iot_header.header_data.acs_custom_fin_curr.currency is not null and
       iot_header.header_data.acs_custom_fin_curr.acs_financial_currency_id is null then
    begin
      select ACS_FINANCIAL_CURRENCY_ID
        into iot_header.header_data.acs_custom_fin_curr.acs_financial_currency_id
        from ACS_FINANCIAL_CURRENCY FC, PCS.PC_CURR C
        where C.CURRENCY = iot_header.header_data.acs_custom_fin_curr.currency
          and FC.PC_CURR_ID = C.PC_CURR_ID;
      exception
        when NO_DATA_FOUND then
          iot_header.header_data.acs_custom_fin_curr.acs_financial_currency_id := 0.0;
    end;
  end if;

  cpt := iot_header.internal_descriptions.COUNT;
  if (cpt > 0) then
    loop
      cpt := cpt-1;
      asa_lib_record_trf_rec.resolve_link(iot_header.internal_descriptions(cpt).pc_lang);
      if (iot_header.internal_descriptions(cpt).pc_lang.pc_lang_id = 0.0) then
        iot_header.internal_descriptions.DELETE(cpt);
      end if;
      exit when cpt <= 0;
    end loop;
    -- reassign
    cpt := iot_header.internal_descriptions.FIRST;
    npos := 0;
    while (cpt is not null) loop
      if (cpt > npos) then
        iot_header.internal_descriptions(npos) := iot_header.internal_descriptions(cpt);
        iot_header.internal_descriptions.DELETE(cpt);
      end if;
      npos := npos +1;
      cpt := iot_header.internal_descriptions.NEXT(cpt);
    end loop;
  end if;
  cpt := iot_header.external_descriptions.COUNT;
  if (cpt > 0) then
    loop
      cpt := cpt-1;
      asa_lib_record_trf_rec.resolve_link(iot_header.external_descriptions(cpt).pc_lang);
      if (iot_header.external_descriptions(cpt).pc_lang.pc_lang_id = 0.0) then
        iot_header.external_descriptions.DELETE(cpt);
      end if;
      exit when cpt <= 0;
    end loop;
    -- reassign
    cpt := iot_header.external_descriptions.FIRST;
    npos := 0;
    while (cpt is not null) loop
      if (cpt > npos) then
        iot_header.external_descriptions(npos) := iot_header.external_descriptions(cpt);
        iot_header.external_descriptions.DELETE(cpt);
      end if;
      npos := npos +1;
      cpt := iot_header.external_descriptions.NEXT(cpt);
    end loop;
  end if;

  asa_lib_record_trf_rec.resolve_link(iot_header.addresses.sold_to.pac_address);
  asa_lib_record_trf_rec.resolve_link(iot_header.addresses.sold_to.pc_cntry);

  asa_lib_record_trf_rec.resolve_link(iot_header.addresses.delivered_to.pac_address);
  asa_lib_record_trf_rec.resolve_link(iot_header.addresses.delivered_to.pc_cntry);

--   asa_lib_record_trf_rec.resolve_link(iot_header.addresses.invoiced_to.pac_address);
--   asa_lib_record_trf_rec.resolve_link(iot_header.addresses.invoiced_to.pc_cntry);

--   asa_lib_record_trf_rec.resolve_link(iot_header.addresses.agent.pac_address);
--   if (iot_header.addresses.agent.pac_address.pac_address_id != 0.0) then
--     asa_lib_record_trf_rec.resolve_link(iot_header.addresses.agent.pc_cntry);
--     asa_lib_record_trf_rec.resolve_link(iot_header.addresses.agent.pc_lang);
--   else
--     iot_header.addresses.agent := null;
--   end if;

--   asa_lib_record_trf_rec.resolve_link(iot_header.addresses.retailer.pac_address);
--   if (iot_header.addresses.retailer.pac_address.pac_address_id != 0.0) then
--     asa_lib_record_trf_rec.resolve_link(iot_header.addresses.retailer.pc_cntry);
--     asa_lib_record_trf_rec.resolve_link(iot_header.addresses.retailer.pc_lang);
--   else
--     iot_header.addresses.retailer := null;
--   end if;

--   asa_lib_record_trf_rec.resolve_link(iot_header.addresses.final_customer.pac_address);
--   if (iot_header.addresses.final_customer.pac_address.pac_address_id != 0.0) then
--     asa_lib_record_trf_rec.resolve_link(iot_header.addresses.final_customer.pc_cntry);
--     asa_lib_record_trf_rec.resolve_link(iot_header.addresses.final_customer.pc_lang);
--   else
--     iot_header.addresses.final_customer := null;
--   end if;

  asa_lib_record_trf_rec.resolve_link(iot_header.product_to_repair.gco_good);
  if (iot_header.product_to_repair.gco_good.gco_good_id is not null) then
    asa_lib_record_trf_rec.resolve_link(
      iot_header.product_to_repair.characterizations,
      iot_header.product_to_repair.gco_good.gco_good_id);
  end if;

  asa_lib_record_trf_rec.resolve_link(iot_header.repaired_product.gco_good);
  if (iot_header.repaired_product.gco_good.gco_good_id is not null) then
    asa_lib_record_trf_rec.resolve_link(
      iot_header.repaired_product.characterizations,
      iot_header.repaired_product.gco_good.gco_good_id);
  end if;

  asa_lib_record_trf_rec.resolve_link(iot_header.product_for_exchange.gco_good);
  if (iot_header.product_for_exchange.gco_good.gco_good_id is not null) then
    asa_lib_record_trf_rec.resolve_link(
      iot_header.product_for_exchange.characterizations,
      iot_header.product_for_exchange.gco_good.gco_good_id);
  end if;

  asa_lib_record_trf_rec.resolve_link(iot_header.product_for_invoice.gco_good);

  asa_lib_record_trf_rec.resolve_link(iot_header.product_for_estimate_invoice.gco_good);

  asa_lib_record_trf_rec.resolve_link(iot_header.amounts.dic_tariff.descriptions);
  asa_lib_record_trf_rec.resolve_link(iot_header.amounts.dic_tariff2.descriptions);

  asa_lib_record_trf_rec.resolve_link(iot_header.warranty.dic_garanty_code.descriptions);

  cpt := iot_header.diagnostics.COUNT;
  if (cpt > 0) then
    loop
      cpt := cpt-1;
      asa_lib_record_trf_rec.resolve_link(iot_header.diagnostics(cpt).dic_diagnostics_type.descriptions);
      asa_lib_record_trf_rec.resolve_link(iot_header.diagnostics(cpt).dic_operator.descriptions);
      exit when cpt <= 0;
    end loop;
  end if;

  cpt := iot_header.document_texts.COUNT;
  if (cpt > 0) then
    loop
      cpt := cpt-1;
      asa_lib_record_trf_rec.resolve_link(iot_header.document_texts(cpt).pc_appltxt);
      if (iot_header.document_texts(cpt).pc_appltxt.pc_appltxt_id = 0.0) then
        iot_header.document_texts.DELETE(cpt);
      end if;
      exit when cpt <= 0;
    end loop;
    -- reassign
    cpt := iot_header.document_texts.FIRST;
    npos := 0;
    while (cpt is not null) loop
      if (cpt > npos) then
        iot_header.document_texts(npos) := iot_header.document_texts(cpt);
        iot_header.document_texts.DELETE(cpt);
      end if;
      npos := npos +1;
      cpt := iot_header.document_texts.NEXT(cpt);
    end loop;
  end if;

  cpt := iot_header.free_codes.boolean_codes.COUNT;
  if (cpt > 0) then
    loop
      cpt := cpt-1;
      asa_lib_record_trf_rec.resolve_link(iot_header.free_codes.boolean_codes(cpt).dic_asa_boolean_code_type.descriptions);
      exit when cpt <= 0;
    end loop;
  end if;
  cpt := iot_header.free_codes.number_codes.COUNT;
  if (cpt > 0) then
    loop
      cpt := cpt-1;
      asa_lib_record_trf_rec.resolve_link(iot_header.free_codes.number_codes(cpt).dic_asa_number_code_type.descriptions);
      exit when cpt <= 0;
    end loop;
  end if;
  cpt := iot_header.free_codes.memo_codes.COUNT;
  if (cpt > 0) then
    loop
      cpt := cpt-1;
      asa_lib_record_trf_rec.resolve_link(iot_header.free_codes.memo_codes(cpt).dic_asa_memo_code_type.descriptions);
      exit when cpt <= 0;
    end loop;
  end if;
  cpt := iot_header.free_codes.date_codes.COUNT;
  if (cpt > 0) then
    loop
      cpt := cpt-1;
      asa_lib_record_trf_rec.resolve_link(iot_header.free_codes.date_codes(cpt).dic_asa_date_code_type.descriptions);
      exit when cpt <= 0;
    end loop;
  end if;
  cpt := iot_header.free_codes.char_codes.COUNT;
  if (cpt > 0) then
    loop
      cpt := cpt-1;
      asa_lib_record_trf_rec.resolve_link(iot_header.free_codes.char_codes(cpt).dic_asa_char_code_type.descriptions);
      exit when cpt <= 0;
    end loop;
  end if;

  asa_lib_record_trf_rec.resolve_link(iot_header.free_data.free_data_01.dic_asa_rec_free.descriptions);
  asa_lib_record_trf_rec.resolve_link(iot_header.free_data.free_data_02.dic_asa_rec_free.descriptions);
  asa_lib_record_trf_rec.resolve_link(iot_header.free_data.free_data_03.dic_asa_rec_free.descriptions);
  asa_lib_record_trf_rec.resolve_link(iot_header.free_data.free_data_04.dic_asa_rec_free.descriptions);
  asa_lib_record_trf_rec.resolve_link(iot_header.free_data.free_data_05.dic_asa_rec_free.descriptions);
end;

procedure resolve_link(
  iott_components IN OUT NOCOPY asa_typ_record_trf_def.TT_COMPONENTS)
is
begin
  if (iott_components.COUNT > 0) then
    for cpt in iott_components.FIRST .. iott_components.LAST loop
      asa_lib_record_trf_rec.resolve_link(iott_components(cpt));
    end loop;
  end if;
end;
procedure resolve_link(
  iot_component IN OUT NOCOPY asa_typ_record_trf_def.T_COMPONENT)
is
begin
  asa_lib_record_trf_rec.resolve_link(iot_component.gco_good);

  asa_lib_record_trf_rec.resolve_link(iot_component.dic_asa_option.descriptions);
  asa_lib_record_trf_rec.resolve_link(iot_component.dic_garanty_code.descriptions);

  asa_lib_record_trf_rec.resolve_link(iot_component.free_data.free_data_01.dic_asa_free_dico_comp.descriptions);
  asa_lib_record_trf_rec.resolve_link(iot_component.free_data.free_data_02.dic_asa_free_dico_comp.descriptions);

  --if (iot_component.product_characteristics.COUNT > 0) then
  --  asa_lib_record_trf_rec.resolve_link(iot_component.product_characteristics, iot_component.gco_good.gco_good_id);
  --end if;
end;

procedure p_validate_element_number(
  iott_characterizations IN OUT NOCOPY asa_typ_record_trf_def.TT_PRODUCT_CHARACTERISTICS,
  in_good_id IN gco_good.gco_good_id%TYPE)
is
  ln_charact_1_id gco_characterization.gco_characterization_id%TYPE;
  ln_charact_2_id gco_characterization.gco_characterization_id%TYPE;
  ln_charact_3_id gco_characterization.gco_characterization_id%TYPE;
  ln_charact_4_id gco_characterization.gco_characterization_id%TYPE;
  ln_charact_5_id gco_characterization.gco_characterization_id%TYPE;
  lv_charact_1_value asa_record_comp.arc_char1_value%TYPE;
  lv_charact_2_value asa_record_comp.arc_char1_value%TYPE;
  lv_charact_3_value asa_record_comp.arc_char1_value%TYPE;
  lv_charact_4_value asa_record_comp.arc_char1_value%TYPE;
  lv_charact_5_value asa_record_comp.arc_char1_value%TYPE;
  ln_element_1_id NUMBER;
  ln_element_2_id NUMBER;
  ln_element_3_id NUMBER;
  ln_quality_status_id  STM_ELEMENT_NUMBER.GCO_QUALITY_STATUS_ID%type;
begin
  if iott_characterizations.count > 0 then
    for cpt in iott_characterizations.FIRST .. iott_characterizations.LAST loop
      case cpt
        when 0 then
          ln_charact_1_id := iott_characterizations(cpt).gco_characterization_id;
          lv_charact_1_value := iott_characterizations(cpt).value;
        when 1 then
          ln_charact_2_id := iott_characterizations(cpt).gco_characterization_id;
          lv_charact_2_value := iott_characterizations(cpt).value;
        when 2 then
          ln_charact_3_id := iott_characterizations(cpt).gco_characterization_id;
          lv_charact_3_value := iott_characterizations(cpt).value;
        when 3 then
          ln_charact_4_id := iott_characterizations(cpt).gco_characterization_id;
          lv_charact_4_value := iott_characterizations(cpt).value;
        when 4 then
          ln_charact_5_id := iott_characterizations(cpt).gco_characterization_id;
          lv_charact_5_value := iott_characterizations(cpt).value;
        else
          null;
      end case;
    end loop;
  end if;

  STM_I_PRC_STOCK_POSITION.GetElementNumber(
    iGoodId => in_good_id,
    iUpdateMode => 'I',
    iMovementSort => 'SOR', -- 'ENT'
    iCharacterizationId => ln_charact_1_id,
    iCharacterization2Id => ln_charact_2_id,
    iCharacterization3Id => ln_charact_3_id,
    iCharacterization4Id => ln_charact_4_id,
    iCharacterization5Id => ln_charact_5_id,
    iCharacterizationValue1 => lv_charact_1_value,
    iCharacterizationValue2 => lv_charact_2_value,
    iCharacterizationValue3 => lv_charact_3_value,
    iCharacterizationValue4 => lv_charact_4_value,
    iCharacterizationValue5 => lv_charact_5_value,
    iVerifyChar => 1, -- 0
    iElementStatus => null,
    ioElementNumberId1 => ln_element_1_id,
    ioElementNumberId2 => ln_element_2_id,
    ioElementNumberId3 => ln_element_3_id,
    ioQualityStatusId => ln_quality_status_id
    );
end;

procedure resolve_link(
  iott_characterizations IN OUT NOCOPY asa_typ_record_trf_def.TT_PRODUCT_CHARACTERISTICS,
  in_good_id IN gco_good.gco_good_id%TYPE)
is
  lt_characterization asa_typ_record_trf_def.T_PRODUCT_CHARACTERISTIC;
  ltt_list TT_SORTED_LIST;
  lt_item VARCHAR2(12);
begin
  if (iott_characterizations.COUNT = 0) then
    -- sortie anticipée car aucune caractérisation
    return;
  end if;

  -- validation des caractérisations
  for cpt in iott_characterizations.FIRST .. iott_characterizations.LAST loop
    lt_characterization := iott_characterizations(cpt);
    -- résolution de gco_characterization_id
    asa_lib_record_trf_rec.resolve_link(lt_characterization, in_good_id);
    if (lt_characterization.gco_characterization_id is not null) then
      -- tri des éléments en les plaçants dans un dictionnaire
      ltt_list(lt_characterization.gco_characterization_id) := lt_characterization;
    end if;
  end loop;
  -- vide la liste originale et copie la nouvelle liste triée des éléments résolus
  iott_characterizations.DELETE;
  lt_item := ltt_list.FIRST;
  if (lt_item is not null) then
    loop
      iott_characterizations(iott_characterizations.COUNT) := ltt_list(lt_item);
      lt_item := ltt_list.NEXT(lt_item);
      exit when lt_item is null;
    end loop;
  end if;

  -- validation (et mise à jour) des valeurs de caractérisations
  p_validate_element_number(iott_characterizations, in_good_id);
end;

procedure resolve_link(
  iot_characterization IN OUT NOCOPY asa_typ_record_trf_def.T_PRODUCT_CHARACTERISTIC,
  in_good_id IN gco_good.gco_good_id%TYPE)
is
begin
  select GCO_CHARACTERIZATION_ID
    into iot_characterization.gco_characterization_id
    from GCO_CHARACTERIZATION
   where GCO_GOOD_ID = in_good_id and
         C_CHARACT_TYPE = iot_characterization.characterization_type;

  exception
    when NO_DATA_FOUND then
      null;
    when TOO_MANY_ROWS then
      fwk_i_mgt_exception.raise_exception(
        in_error_code => asa_typ_record_trf_def.EXCEPTION_RESOLVE_LINK_NO,
        iv_message =>
          'Too many caracterizations found with '||
            '{C_CHARACT_TYPE='''|| iot_characterization.characterization_type||''''||
            ',GCO_GOOD_ID='||to_char(in_good_id)||
          '}',
        iv_stack_trace => fwk_i_lib_trace.call_stack,
        iv_cause => 'resolve_link',
        it_exception_type => fwk_i_mgt_exception.FATAL);
end;

procedure resolve_link(
  iott_operations IN OUT NOCOPY asa_typ_record_trf_def.TT_OPERATIONS)
is
begin
  if (iott_operations.COUNT > 0) then
    for cpt in iott_operations.FIRST .. iott_operations.LAST loop
      asa_lib_record_trf_rec.resolve_link(iott_operations(cpt));
    end loop;
  end if;
end;
procedure resolve_link(
  iot_operation IN OUT NOCOPY asa_typ_record_trf_def.T_OPERATION)
is
begin
  if iot_operation.fal_task.tas_ref is not null and
     iot_operation.fal_task.fal_task_id is null then
    begin
      select FAL_TASK_ID
        into iot_operation.fal_task.fal_task_id
        from FAL_TASK
       where TAS_REF = iot_operation.fal_task.tas_ref;
    exception
      when NO_DATA_FOUND then
        fwk_i_mgt_exception.raise_exception(
          in_error_code => asa_typ_record_trf_def.EXCEPTION_RESOLVE_LINK_NO,
          iv_message =>
            'Cannot find task with '||
              '{TAS_REF='''||iot_operation.fal_task.tas_ref||''''||
            '}',
          iv_stack_trace => fwk_i_lib_trace.call_stack,
          iv_cause => 'resolve_link',
          it_exception_type => fwk_i_mgt_exception.FATAL);
    end;
  end if;

  --asa_lib_record_trf_rec.resolve_link(iot_operation.pac_person);
  iot_operation.pac_person.pac_person_id := 0.0;

  asa_lib_record_trf_rec.resolve_link(iot_operation.gco_good_to_repair);
  asa_lib_record_trf_rec.resolve_link(iot_operation.gco_good_to_bill);

  asa_lib_record_trf_rec.resolve_link(iot_operation.dic_asa_option.descriptions);
  asa_lib_record_trf_rec.resolve_link(iot_operation.dic_garanty_code.descriptions);
  asa_lib_record_trf_rec.resolve_link(iot_operation.dic_operator.descriptions);

  asa_lib_record_trf_rec.resolve_link(iot_operation.free_data.free_data_01.dic_asa_free_dico_task.descriptions);
  asa_lib_record_trf_rec.resolve_link(iot_operation.free_data.free_data_02.dic_asa_free_dico_task.descriptions);
end;

procedure resolve_link(
  iott_descriptions IN OUT NOCOPY asa_typ_record_trf_def.TT_DICTIONARY_DESCRIPTIONS)
is
  cpt BINARY_INTEGER;
  npos BINARY_INTEGER;
begin
  cpt := iott_descriptions.COUNT;
  if (cpt > 0) then
    loop
      cpt := cpt-1;
      asa_lib_record_trf_rec.resolve_link(iott_descriptions(cpt).pc_lang);
      if (iott_descriptions(cpt).pc_lang.pc_lang_id = 0.0) then
        iott_descriptions.DELETE(cpt);
      end if;
      exit when cpt <= 0;
    end loop;
    -- reassign
    cpt := iott_descriptions.FIRST;
    npos := 0;
    while (cpt is not null) loop
      if (cpt > npos) then
        iott_descriptions(npos) := iott_descriptions(cpt);
        iott_descriptions.DELETE(cpt);
      end if;
      npos := npos +1;
      cpt := iott_descriptions.NEXT(cpt);
    end loop;
  end if;
end;

procedure resolve_link(
  iot_pc_lang IN OUT NOCOPY asa_typ_record_trf_def.T_PC_LANG_LINK)
is
begin
  if iot_pc_lang.lanid is not null and
     iot_pc_lang.pc_lang_id is null then
    select PC_LANG_ID
      into iot_pc_lang.pc_lang_id
      from PCS.PC_LANG
     where LANID = iot_pc_lang.lanid;
  end if;

  exception
    when NO_DATA_FOUND then
      iot_pc_lang.pc_lang_id := 0.0;
end;

procedure resolve_link(
  iot_pc_cntry IN OUT NOCOPY asa_typ_record_trf_def.T_PC_CNTRY_LINK)
is
begin
  if iot_pc_cntry.cntid is not null and
     iot_pc_cntry.pc_cntry_id is null then
    select PC_CNTRY_ID
      into iot_pc_cntry.pc_cntry_id
      from PCS.PC_CNTRY
     where CNTID = iot_pc_cntry.cntid;
  end if;

  exception
    when NO_DATA_FOUND then
      iot_pc_cntry.pc_cntry_id := 0.0;
end;

procedure resolve_link(
  iot_pc_appltxt_link IN OUT NOCOPY asa_typ_record_trf_def.T_PC_APPLTXT_LINK)
is
begin
  if (iot_pc_appltxt_link.c_text_type is not null and
      iot_pc_appltxt_link.dic_pc_theme.value is not null and
      iot_pc_appltxt_link.aph_code is not null) and
     iot_pc_appltxt_link.pc_appltxt_id is null then
    select PC_APPLTXT_ID
      into iot_pc_appltxt_link.pc_appltxt_id
      from PCS.PC_APPLTXT
     where C_TEXT_TYPE = iot_pc_appltxt_link.c_text_type and
           DIC_PC_THEME_ID = iot_pc_appltxt_link.dic_pc_theme.value and
           APH_CODE = iot_pc_appltxt_link.aph_code;
  end if;

  exception
    when NO_DATA_FOUND then
      iot_pc_appltxt_link.pc_appltxt_id := 0.0;
end;

procedure resolve_link(
  iot_pac_person IN OUT NOCOPY asa_typ_record_trf_def.T_PAC_PERSON_LINK)
is
begin
  if (iot_pac_person.pac_person_id is null) then
    if (iot_pac_person.per_key1 is not null and
        iot_pac_person.per_key2 is not null) then
      select PAC_PERSON_ID
        into iot_pac_person.pac_person_id
        from PAC_PERSON
       where PER_KEY1 = iot_pac_person.per_key1 and
             PER_KEY2 = iot_pac_person.per_key2;
    elsif (iot_pac_person.per_key1 is not null) then
      select PAC_PERSON_ID
        into iot_pac_person.pac_person_id
        from PAC_PERSON
       where PER_KEY1 = iot_pac_person.per_key1;
    end if;
  end if;

  exception
    when NO_DATA_FOUND then
      iot_pac_person.pac_person_id := 0.0;
end;

procedure resolve_link(
  iot_pac_address IN OUT NOCOPY asa_typ_record_trf_def.T_PAC_ADDRESS_LINK)
is
  ltplAddress SYS_REFCURSOR := null;
  ln_address_id pac_address.pac_address_id%TYPE;
begin
  if (iot_pac_address.pac_address_id is null) then
    if (iot_pac_address.dic_address_type.value is not null and
        iot_pac_address.per_key1 is not null and
        iot_pac_address.per_key2 is not null) then
      open ltplAddress for
        select A.PAC_ADDRESS_ID
          from PAC_PERSON P, PAC_ADDRESS A
         where A.DIC_ADDRESS_TYPE_ID = iot_pac_address.dic_address_type.value
           and P.PER_KEY1 = iot_pac_address.per_key1
           and P.PER_KEY2 = iot_pac_address.per_key2
           and A.PAC_PERSON_ID = P.PAC_PERSON_ID
        order by A.ADD_PRINCIPAL desc, A.PAC_ADDRESS_ID;
    elsif (iot_pac_address.dic_address_type.value is not null and
           iot_pac_address.per_key1 is not null) then
      open ltplAddress for
        select A.PAC_ADDRESS_ID
          from PAC_PERSON P, PAC_ADDRESS A
         where A.DIC_ADDRESS_TYPE_ID = iot_pac_address.dic_address_type.value
           and P.PER_KEY1 = iot_pac_address.per_key1
           and A.PAC_PERSON_ID = P.PAC_PERSON_ID
        order by A.ADD_PRINCIPAL desc, A.PAC_ADDRESS_ID;
    end if;
  end if;

  if (ltplAddress%ISOPEN) then
    fetch ltplAddress into ln_address_id;
    if (ltplAddress%FOUND) then
      iot_pac_address.pac_address_id := ln_address_id;
    end if;
    close ltplAddress;
  end if;

  if (iot_pac_address.pac_address_id is null) then
    iot_pac_address.pac_address_id := 0.0;
  end if;

  exception
    when NO_DATA_FOUND then
      iot_pac_address.pac_address_id := 0.0;
      if (ltplAddress%ISOPEN) then
        close ltplAddress;
      end if;
end;

procedure resolve_link(
  iot_gco_good IN OUT NOCOPY asa_typ_record_trf_def.T_GCO_GOOD_LINK)
is
begin
  if iot_gco_good.goo_major_reference is not null and
     iot_gco_good.gco_good_id is null then
    select GCO_GOOD_ID
      into iot_gco_good.gco_good_id
      from GCO_GOOD
     where GOO_MAJOR_REFERENCE = iot_gco_good.goo_major_reference;
  end if;

  exception
    when NO_DATA_FOUND then
      fwk_i_mgt_exception.raise_exception(
        in_error_code => asa_typ_record_trf_def.EXCEPTION_RESOLVE_LINK_NO,
        iv_message =>
          'Cannot find product with '||
            '{GOO_MAJOR_REFERENCE='''||iot_gco_good.goo_major_reference||''''||
          '}',
        iv_stack_trace => fwk_i_lib_trace.call_stack,
        iv_cause => 'resolve_link',
        it_exception_type => fwk_i_mgt_exception.FATAL);
end;

--procedure resolve_link(
--  iot_currency_link IN OUT NOCOPY asa_typ_record_trf_def.T_CURRENCY_LINK)
--is
--begin
--  if iot_currency_link.currency is not null and
--     iot_currency_link.acs_financial_currency_id is null then
--    select ACS_FINANCIAL_CURRENCY_ID
--      into iot_currency_link.acs_financial_currency_id
--      from ACS_FINANCIAL_CURRENCY
--     where PC_CURR_ID = (select PC_CURR_ID from PCS.PC_CURR
--                         where CURRENCY = iot_currency_link.currency);
--  end if;
--
--  exception
--    when NO_DATA_FOUND then
--      fwk_i_mgt_exception.raise_exception(
--        in_error_code => asa_typ_record_trf_def.EXCEPTION_RESOLVE_LINK_NO,
--        iv_message =>
--          'Cannot find financial curreny with '||
--            '{CURRENCY='''||iot_currency_link.currency||''''||
--          '}',
--        iv_stack_trace => fwk_i_lib_trace.call_stack,
--        iv_cause => 'resolve_link',
--        it_exception_type => fwk_i_mgt_exception.FATAL);
--end;


--
-- Record type loading
--

procedure load_asa_record_trf(
  ix_document IN XMLType,
  iot_after_sales_file IN OUT NOCOPY asa_typ_record_trf_def.T_AFTER_SALES_FILE)
is
  lx_sub XMLType;
  lb_header BOOLEAN := FALSE;
  lb_components BOOLEAN := FALSE;
  lb_operations BOOLEAN := FALSE;
begin
  rep_lib_nls_parameters.SetNLSFormat;

  asa_lib_record_trf_rec.load_envelope(
    ix_document.extract('AFTER_SALES_FILE/ENVELOPE'),
    iot_after_sales_file.envelope
  );

  lx_sub := ix_document.extract('AFTER_SALES_FILE/HEADER');
  if (lx_sub is not null) then
    lb_header := TRUE;
    asa_lib_record_trf_rec.load_header(lx_sub, iot_after_sales_file.header);
  end if;

  lx_sub := ix_document.extract('AFTER_SALES_FILE/COMPONENTS');
  if (lx_sub is not null) then
    lb_components := TRUE;
    asa_lib_record_trf_rec.load_components(lx_sub, iot_after_sales_file.components);
  end if;

  lx_sub := ix_document.extract('AFTER_SALES_FILE/OPERATIONS');
  if (lx_sub is not null) then
    lb_operations := TRUE;
    asa_lib_record_trf_rec.load_operations(lx_sub, iot_after_sales_file.operations);
  end if;

  if (lb_header) then
    asa_lib_record_trf_rec.resolve_link(iot_after_sales_file.header);
  end if;
  if (lb_components) then
    asa_lib_record_trf_rec.resolve_link(iot_after_sales_file.components);
  end if;
  if (lb_operations) then
    asa_lib_record_trf_rec.resolve_link(iot_after_sales_file.operations);
  end if;

  rep_lib_nls_parameters.ResetNLSFormat;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;

procedure load_envelope(
  ix_document IN XMLType,
  iot_envelope IN OUT NOCOPY asa_typ_record_trf_def.T_ENVELOPE,
  ib_fragment IN BOOLEAN DEFAULT TRUE)
is
  lx_sub XMLType;
begin
  if (ib_fragment) then
    lx_sub := ix_document.extract('ENVELOPE/*');
  else
    lx_sub := ix_document.extract('/AFTER_SALES_FILE/ENVELOPE/*');
  end if;
  select
    ExtractValue(lx_sub,'MESSAGE_TYPE'),
    ExtractValue(lx_sub,'MESSAGE_NUMBER'),
    ExtractValue(lx_sub,'ARE_NUMBER'),
    ExtractValue(lx_sub,'ARE_NUMBER_MATCHING_MODE'),
    ExtractValue(lx_sub,'MESSAGE_DATE'),
    ExtractValue(lx_sub,'COMMENT'),
    ExtractValue(lx_sub,'ORIGINAL_MESSAGE/MESSAGE_TYPE'),
    ExtractValue(lx_sub,'ORIGINAL_MESSAGE/MESSAGE_NUMBER'),
    ExtractValue(lx_sub,'ORIGINAL_MESSAGE/ARE_NUMBER'),
    ExtractValue(lx_sub,'ORIGINAL_MESSAGE/MESSAGE_DATE'),
    ExtractValue(lx_sub,'FROM/INSTANCE_NAME'),
    ExtractValue(lx_sub,'FROM/SCHEMA_NAME'),
    ExtractValue(lx_sub,'FROM/COMPANY_NAME'),
    ExtractValue(lx_sub,'FROM/RECIPIENT_PER_KEY1'),
    ExtractValue(lx_sub,'TO/INSTANCE_NAME'),
    ExtractValue(lx_sub,'TO/SCHEMA_NAME'),
    ExtractValue(lx_sub,'TO/COMPANY_NAME')
  into
    iot_envelope.message.message_type,
    iot_envelope.message.message_number,
    iot_envelope.message.are_number,
    iot_envelope.message.are_number_matching_mode,
    iot_envelope.message.message_date,
    iot_envelope.comment,
    iot_envelope.original_message.message_type,
    iot_envelope.original_message.message_number,
    iot_envelope.original_message.are_number,
    iot_envelope.original_message.message_date,
    iot_envelope.sender.instance_name,
    iot_envelope.sender.schema_name,
    iot_envelope.sender.company_name,
    iot_envelope.sender.recipient_key,
    iot_envelope.recipient.instance_name,
    iot_envelope.recipient.schema_name,
    iot_envelope.recipient.company_name
  from DUAL;
end;

procedure load_header(
  ix_fragment IN XMLType,
  iot_header IN OUT NOCOPY asa_typ_record_trf_def.T_HEADER)
is
  lx_sub XMLType;
  lt_boolean_code asa_typ_record_trf_def.T_BOOLEAN_CODE;
  lt_number_code asa_typ_record_trf_def.T_NUMBER_CODE;
  lt_memo_code asa_typ_record_trf_def.T_MEMO_CODE;
  lt_date_code asa_typ_record_trf_def.T_DATE_CODE;
  lt_char_code asa_typ_record_trf_def.T_CHAR_CODE;
begin
  -- HEADER_DATA
  lx_sub := ix_fragment.extract('HEADER/*');
  select
    ExtractValue(lx_sub,'HEADER_DATA/SOURCE_COMPANY/INSTANCE_NAME'),
    ExtractValue(lx_sub,'HEADER_DATA/SOURCE_COMPANY/SCHEMA_NAME'),
    ExtractValue(lx_sub,'HEADER_DATA/SOURCE_COMPANY/COMPANY_NAME'),
    ExtractValue(lx_sub,'HEADER_DATA/ARE_NUMBER'),
    ExtractValue(lx_sub,'HEADER_DATA/ARE_SRC_NUMBER'),
    ExtractValue(lx_sub,'HEADER_DATA/RET_REP_TYPE'),
    ExtractValue(lx_sub,'HEADER_DATA/DOC_GAUGE/C_ADMIN_DOMAIN'),
    ExtractValue(lx_sub,'HEADER_DATA/DOC_GAUGE/C_GAUGE_TYPE'),
    ExtractValue(lx_sub,'HEADER_DATA/DOC_GAUGE/GAU_DESCRIBE'),
    ExtractValue(lx_sub,'HEADER_DATA/C_ASA_REP_TYPE_KIND'),
    ExtractValue(lx_sub,'HEADER_DATA/C_ASA_REP_STATUS'),
    rep_utils.ReplicatorDateToDate(ExtractValue(lx_sub,'HEADER_DATA/ARE_DATECRE')),
    rep_utils.ReplicatorDateToDate(ExtractValue(lx_sub,'HEADER_DATA/ARE_UPDATE_STATUS')),
    rep_utils.ReplicatorDateToDate(ExtractValue(lx_sub,'HEADER_DATA/ARE_PRINT_STATUS')),
    ExtractValue(lx_sub,'HEADER_DATA/ARE_INTERNAL_REMARK'),
    ExtractValue(lx_sub,'HEADER_DATA/ARE_REQ_DATE_TEXT'),
    ExtractValue(lx_sub,'HEADER_DATA/ARE_CUSTOMER_REMARK'),
    ExtractValue(lx_sub,'HEADER_DATA/ARE_ADDITIONAL_ITEMS'),
    ExtractValue(lx_sub,'HEADER_DATA/ARE_CUSTOMS_VALUE'),
    ExtractValue(lx_sub,'HEADER_DATA/DOC_RECORD/RCO_TITLE'),
    ExtractValue(lx_sub,'HEADER_DATA/DOC_RECORD/RCO_NUMBER'),
    ExtractValue(lx_sub,'HEADER_DATA/REP_DESCR'),
    ExtractValue(lx_sub,'HEADER_DATA/ACS_CUSTOM_FIN_CURR/CURRENCY'),
    ExtractValue(lx_sub,'PRODUCT_TO_REPAIR/GOO_MAJOR_REFERENCE'),
    ExtractValue(lx_sub,'PRODUCT_TO_REPAIR/REFERENCES/ARE_GOOD_REF_1'),
    ExtractValue(lx_sub,'PRODUCT_TO_REPAIR/REFERENCES/ARE_GOOD_REF_2'),
    ExtractValue(lx_sub,'PRODUCT_TO_REPAIR/REFERENCES/ARE_GOOD_REF_3'),
    ExtractValue(lx_sub,'PRODUCT_TO_REPAIR/REFERENCES/ARE_CUSTOMER_REF'),
    ExtractValue(lx_sub,'PRODUCT_TO_REPAIR/REFERENCES/ARE_GOOD_NEW_REF'),
    ExtractValue(lx_sub,'PRODUCT_TO_REPAIR/DESCRIPTIONS/ARE_GCO_SHORT_DESCR'),
    ExtractValue(lx_sub,'PRODUCT_TO_REPAIR/DESCRIPTIONS/ARE_GCO_LONG_DESCR'),
    ExtractValue(lx_sub,'PRODUCT_TO_REPAIR/DESCRIPTIONS/ARE_GCO_FREE_DESCR'),
    ExtractValue(lx_sub,'REPAIRED_PRODUCT/GOO_MAJOR_REFERENCE'),
    ExtractValue(lx_sub,'PRODUCT_FOR_EXCHANGE/GOO_MAJOR_REFERENCE'),
    ExtractValue(lx_sub,'PRODUCT_FOR_INVOICE/GOO_MAJOR_REFERENCE'),
    ExtractValue(lx_sub,'PRODUCT_FOR_ESTIMATE_INVOICE/GOO_MAJOR_REFERENCE'),
    ExtractValue(lx_sub,'AMOUNTS/CURRENCY/CURRENCY'),
    ExtractValue(lx_sub,'AMOUNTS/CURRENCY/ARE_CURR_BASE_PRICE'),
    ExtractValue(lx_sub,'AMOUNTS/CURRENCY/ARE_CURR_RATE_EURO'),
    ExtractValue(lx_sub,'AMOUNTS/CURRENCY/ARE_CURR_RATE_OF_EXCH'),
    ExtractValue(lx_sub,'AMOUNTS/CURRENCY/ARE_EURO_CURRENCY'),
    ExtractValue(lx_sub,'AMOUNTS/COST_PRICE/ARE_COST_PRICE_C'),
    ExtractValue(lx_sub,'AMOUNTS/COST_PRICE/ARE_COST_PRICE_T'),
    ExtractValue(lx_sub,'AMOUNTS/COST_PRICE/ARE_COST_PRICE_W'),
    ExtractValue(lx_sub,'AMOUNTS/COST_PRICE/ARE_COST_PRICE_S'),
    ExtractValue(lx_sub,'AMOUNTS/SALE_PRICE/ARE_SALE_PRICE_C'),
    ExtractValue(lx_sub,'AMOUNTS/SALE_PRICE/ARE_SALE_PRICE_S'),
    ExtractValue(lx_sub,'AMOUNTS/SALE_PRICE/ARE_SALE_PRICE_T_EURO'),
    ExtractValue(lx_sub,'AMOUNTS/SALE_PRICE/ARE_SALE_PRICE_T_MB'),
    ExtractValue(lx_sub,'AMOUNTS/SALE_PRICE/ARE_SALE_PRICE_T_ME'),
    ExtractValue(lx_sub,'AMOUNTS/SALE_PRICE/ARE_SALE_PRICE_W'),
    ExtractValue(lx_sub,'AMOUNTS/DIC_TARIFF/VALUE'),
    ExtractValue(lx_sub,'AMOUNTS/DIC_TARIFF2/VALUE'),
    ExtractValue(lx_sub,'WARRANTY/ARE_CUSTOMER_ERROR'),
    rep_utils.ReplicatorDateToDate(ExtractValue(lx_sub,'WARRANTY/ARE_BEGIN_GUARANTY_DATE')),
    rep_utils.ReplicatorDateToDate(ExtractValue(lx_sub,'WARRANTY/ARE_END_GUARANTY_DATE')),
    rep_utils.ReplicatorDateToDate(ExtractValue(lx_sub,'WARRANTY/ARE_DET_SALE_DATE')),
    ExtractValue(lx_sub,'WARRANTY/ARE_DET_SALE_DATE_TEXT'),
    rep_utils.ReplicatorDateToDate(ExtractValue(lx_sub,'WARRANTY/ARE_FIN_SALE_DATE')),
    ExtractValue(lx_sub,'WARRANTY/ARE_FIN_SALE_DATE_TEXT'),
    ExtractValue(lx_sub,'WARRANTY/ARE_GENERATE_BILL'),
    ExtractValue(lx_sub,'WARRANTY/ARE_GUARANTY'),
    ExtractValue(lx_sub,'WARRANTY/ARE_GUARANTY_CODE'),
    ExtractValue(lx_sub,'WARRANTY/ARE_OFFERED_CODE'),
    rep_utils.ReplicatorDateToDate(ExtractValue(lx_sub,'WARRANTY/ARE_REP_BEGIN_GUAR_DATE')),
    rep_utils.ReplicatorDateToDate(ExtractValue(lx_sub,'WARRANTY/ARE_REP_END_GUAR_DATE')),
    ExtractValue(lx_sub,'WARRANTY/ARE_REP_GUAR'),
    rep_utils.ReplicatorDateToDate(ExtractValue(lx_sub,'WARRANTY/ARE_SALE_DATE')),
    ExtractValue(lx_sub,'WARRANTY/ARE_SALE_DATE_TEXT'),
    ExtractValue(lx_sub,'WARRANTY/AGC_NUMBER'),
    ExtractValue(lx_sub,'WARRANTY/C_ASA_GUARANTY_UNIT'),
    ExtractValue(lx_sub,'WARRANTY/C_ASA_REP_GUAR_UNIT'),
    ExtractValue(lx_sub,'WARRANTY/DIC_GARANTY_CODE/VALUE'),
    rep_utils.ReplicatorDateToDate(ExtractValue(lx_sub,'DELAYS/ARE_DATE_REG_REP')),
    rep_utils.ReplicatorDateToDate(ExtractValue(lx_sub,'DELAYS/ARE_REQ_DATE_C')),
    rep_utils.ReplicatorDateToDate(ExtractValue(lx_sub,'DELAYS/ARE_CONF_DATE_C')),
    rep_utils.ReplicatorDateToDate(ExtractValue(lx_sub,'DELAYS/ARE_UPD_DATE_C')),
    rep_utils.ReplicatorDateToDate(ExtractValue(lx_sub,'DELAYS/ARE_REQ_DATE_S')),
    rep_utils.ReplicatorDateToDate(ExtractValue(lx_sub,'DELAYS/ARE_CONF_DATE_S')),
    rep_utils.ReplicatorDateToDate(ExtractValue(lx_sub,'DELAYS/ARE_UPD_DATE_S')),
    rep_utils.ReplicatorDateToDate(ExtractValue(lx_sub,'DELAYS/ARE_DATE_END_CTRL')),
    rep_utils.ReplicatorDateToDate(ExtractValue(lx_sub,'DELAYS/ARE_DATE_END_REP')),
    rep_utils.ReplicatorDateToDate(ExtractValue(lx_sub,'DELAYS/ARE_DATE_END_SENDING')),
    rep_utils.ReplicatorDateToDate(ExtractValue(lx_sub,'DELAYS/ARE_DATE_START_EXP')),
    rep_utils.ReplicatorDateToDate(ExtractValue(lx_sub,'DELAYS/ARE_DATE_START_REP')),
    ExtractValue(lx_sub,'DELAYS/ARE_NB_DAYS'),
    ExtractValue(lx_sub,'DELAYS/ARE_NB_DAYS_CTRL'),
    ExtractValue(lx_sub,'DELAYS/ARE_NB_DAYS_EXP'),
    ExtractValue(lx_sub,'DELAYS/ARE_NB_DAYS_SENDING'),
    ExtractValue(lx_sub,'DELAYS/ARE_NB_DAYS_WAIT'),
    ExtractValue(lx_sub,'DELAYS/ARE_NB_DAYS_WAIT_COMP'),
    ExtractValue(lx_sub,'DELAYS/ARE_NB_DAYS_WAIT_MAX')
  into
    iot_header.header_data.source_company.instance_name,
    iot_header.header_data.source_company.schema_name,
    iot_header.header_data.source_company.company_name,
    iot_header.header_data.are_number,
    iot_header.header_data.are_src_number,
    iot_header.header_data.asa_rep_type.ret_rep_type,
    iot_header.header_data.doc_gauge.c_admin_domain,
    iot_header.header_data.doc_gauge.c_gauge_type,
    iot_header.header_data.doc_gauge.gau_describe,
    iot_header.header_data.c_asa_rep_type_kind,
    iot_header.header_data.c_asa_rep_status,
    iot_header.header_data.are_datecre,
    iot_header.header_data.are_update_status,
    iot_header.header_data.are_print_status,
    iot_header.header_data.are_internal_remark,
    iot_header.header_data.are_req_date_text,
    iot_header.header_data.are_customer_remark,
    iot_header.header_data.are_additional_items,
    iot_header.header_data.are_customs_value,
    iot_header.header_data.doc_record.rco_title,
    iot_header.header_data.doc_record.rco_number,
    iot_header.header_data.pac_representative.rep_descr,
    iot_header.header_data.acs_custom_fin_curr.currency,
    iot_header.product_to_repair.gco_good.goo_major_reference,
    iot_header.product_to_repair.are_good_ref_1,
    iot_header.product_to_repair.are_good_ref_2,
    iot_header.product_to_repair.are_good_ref_3,
    iot_header.product_to_repair.are_customer_ref,
    iot_header.product_to_repair.are_good_new_ref,
    iot_header.product_to_repair.are_gco_short_descr,
    iot_header.product_to_repair.are_gco_long_descr,
    iot_header.product_to_repair.are_gco_free_descr,
    iot_header.repaired_product.gco_good.goo_major_reference,
    iot_header.product_for_exchange.gco_good.goo_major_reference,
    iot_header.product_for_invoice.gco_good.goo_major_reference,
    iot_header.product_for_estimate_invoice.gco_good.goo_major_reference,
    iot_header.amounts.currency.currency,
    iot_header.amounts.are_curr_base_price,
    iot_header.amounts.are_curr_rate_euro,
    iot_header.amounts.are_curr_rate_of_exch,
    iot_header.amounts.are_euro_currency,
    iot_header.amounts.are_cost_price_c,
    iot_header.amounts.are_cost_price_t,
    iot_header.amounts.are_cost_price_w,
    iot_header.amounts.are_cost_price_s,
    iot_header.amounts.are_sale_price_c,
    iot_header.amounts.are_sale_price_s,
    iot_header.amounts.are_sale_price_t_euro,
    iot_header.amounts.are_sale_price_t_mb,
    iot_header.amounts.are_sale_price_t_me,
    iot_header.amounts.are_sale_price_w,
    iot_header.amounts.dic_tariff.value,
    iot_header.amounts.dic_tariff2.value,
    iot_header.warranty.are_customer_error,
    iot_header.warranty.are_begin_guaranty_date,
    iot_header.warranty.are_end_guaranty_date,
    iot_header.warranty.are_det_sale_date,
    iot_header.warranty.are_det_sale_date_text,
    iot_header.warranty.are_fin_sale_date,
    iot_header.warranty.are_fin_sale_date_text,
    iot_header.warranty.are_generate_bill,
    iot_header.warranty.are_guaranty,
    iot_header.warranty.are_guaranty_code,
    iot_header.warranty.are_offered_code,
    iot_header.warranty.are_rep_begin_guar_date,
    iot_header.warranty.are_rep_end_guar_date,
    iot_header.warranty.are_rep_guar,
    iot_header.warranty.are_sale_date,
    iot_header.warranty.are_sale_date_text,
    iot_header.warranty.agc_number,
    iot_header.warranty.c_asa_guaranty_unit,
    iot_header.warranty.c_asa_rep_guar_unit,
    iot_header.warranty.dic_garanty_code.value,
    iot_header.delays.are_date_reg_rep,
    iot_header.delays.are_req_date_c,
    iot_header.delays.are_conf_date_c,
    iot_header.delays.are_upd_date_c,
    iot_header.delays.are_req_date_s,
    iot_header.delays.are_conf_date_s,
    iot_header.delays.are_upd_date_s,
    iot_header.delays.are_date_end_ctrl,
    iot_header.delays.are_date_end_rep,
    iot_header.delays.are_date_end_sending,
    iot_header.delays.are_date_start_exp,
    iot_header.delays.are_date_start_rep,
    iot_header.delays.are_nb_days,
    iot_header.delays.are_nb_days_ctrl,
    iot_header.delays.are_nb_days_exp,
    iot_header.delays.are_nb_days_sending,
    iot_header.delays.are_nb_days_wait,
    iot_header.delays.are_nb_days_wait_comp,
    iot_header.delays.are_nb_days_wait_max
  from DUAL;

  if (iot_header.warranty.dic_garanty_code.value is not null) then
    asa_lib_record_trf_rec.load_dictionary(
      ix_fragment.extract('HEADER/WARRANTY/DIC_GARANTY_CODE/*'),
      iot_header.warranty.dic_garanty_code);
  end if;

  asa_lib_record_trf_rec.load_characterizations(
    ix_fragment.extract('HEADER/PRODUCT_TO_REPAIR/PRODUCT_CHARACTERISTICS'),
    iot_header.product_to_repair.characterizations);
  asa_lib_record_trf_rec.load_characterizations(
    ix_fragment.extract('HEADER/REPAIRED_PRODUCT/PRODUCT_CHARACTERISTICS'),
    iot_header.repaired_product.characterizations);
  asa_lib_record_trf_rec.load_characterizations(
    ix_fragment.extract('HEADER/PRODUCT_FOR_EXCHANGE/PRODUCT_CHARACTERISTICS'),
    iot_header.product_for_exchange.characterizations);

  lx_sub := ix_fragment.extract('HEADER/DESCRIPTIONS/INTERNAL_DESCRIPTIONS');
  if (lx_sub is not null) then
    asa_lib_record_trf_rec.load_descriptions(lx_sub, '1', iot_header.internal_descriptions);
  end if;
  lx_sub := ix_fragment.extract('HEADER/DESCRIPTIONS/EXTERNAL_DESCRIPTIONS');
  if (lx_sub is not null) then
    asa_lib_record_trf_rec.load_descriptions(lx_sub, '2', iot_header.external_descriptions);
  end if;

  lx_sub := ix_fragment.extract('HEADER/ADDRESSES/*');
  asa_lib_record_trf_rec.load_address(lx_sub.extract('SOLD_TO/*'), iot_header.addresses.sold_to);
  asa_lib_record_trf_rec.load_address(lx_sub.extract('DELIVERED_TO/*'), iot_header.addresses.delivered_to);
  asa_lib_record_trf_rec.load_address(lx_sub.extract('INVOICED_TO/*'), iot_header.addresses.invoiced_to);
  asa_lib_record_trf_rec.load_address(lx_sub.extract('AGENT/*'), iot_header.addresses.agent);
  asa_lib_record_trf_rec.load_address(lx_sub.extract('RETAILER/*'), iot_header.addresses.retailer);
  asa_lib_record_trf_rec.load_address(lx_sub.extract('FINAL_CUSTOMER/*'), iot_header.addresses.final_customer);

  lx_sub := ix_fragment.extract('HEADER/DIAGNOSTICS');
  if (lx_sub is not null) then
    asa_lib_record_trf_rec.load_diagnostics(lx_sub, iot_header.diagnostics);
  end if;

  lx_sub := ix_fragment.extract('HEADER/DOCUMENT_TEXTS');
  if (lx_sub is not null) then
    asa_lib_record_trf_rec.load_document_texts(lx_sub, iot_header.document_texts);
  end if;

  lx_sub := ix_fragment.extract('HEADER/FREE_CODES');
  if (lx_sub is not null) then
    -- BOOLEAN
    if (lx_sub.existsNode('FREE_CODES/BOOLEAN_CODES') != 0) then
      for tpl in (
        select
          ExtractValue(COLUMN_VALUE,'BOOLEAN_CODE/DIC_CODE_TYPE/VALUE') DIC_VALUE,
          ExtractValue(COLUMN_VALUE,'BOOLEAN_CODE/VALUE') VALUE,
          Extract(COLUMN_VALUE,'BOOLEAN_CODE/DIC_CODE_TYPE') XML_DIC
        from
          XMLTable('FREE_CODES/BOOLEAN_CODES/BOOLEAN_CODE' passing lx_sub) T
      ) loop
        lt_boolean_code.dic_asa_boolean_code_type.value := tpl.DIC_VALUE;
        lt_boolean_code.fco_boo_code := tpl.VALUE;
        iot_header.free_codes.boolean_codes(iot_header.free_codes.boolean_codes.COUNT) := lt_boolean_code;
        asa_lib_record_trf_rec.load_dictionary(
          tpl.XML_DIC.extract('DIC_CODE_TYPE/*'),
          lt_boolean_code.dic_asa_boolean_code_type);
      end loop;
    end if;
    -- NUMBER
    if (lx_sub.existsNode('FREE_CODES/NUMBER_CODES') != 0) then
      for tpl in (
        select
          ExtractValue(COLUMN_VALUE,'NUMBER_CODE/DIC_CODE_TYPE/VALUE') DIC_VALUE,
          ExtractValue(COLUMN_VALUE,'NUMBER_CODE/VALUE') VALUE,
          Extract(COLUMN_VALUE,'NUMBER_CODE/DIC_CODE_TYPE') XML_DIC
        from
          XMLTable('FREE_CODES/NUMBER_CODES/NUMBER_CODE' passing lx_sub) T
      ) loop
        lt_number_code.dic_asa_number_code_type.value := tpl.DIC_VALUE;
        lt_number_code.fco_num_code := tpl.VALUE;
        iot_header.free_codes.number_codes(iot_header.free_codes.number_codes.COUNT) := lt_number_code;
        asa_lib_record_trf_rec.load_dictionary(
          tpl.XML_DIC.extract('DIC_CODE_TYPE/*'),
          lt_number_code.dic_asa_number_code_type);
      end loop;
    end if;
    -- MEMO
    if (lx_sub.existsNode('FREE_CODES/MEMO_CODES') != 0) then
      for tpl in (
        select
          ExtractValue(COLUMN_VALUE,'MEMO_CODE/DIC_CODE_TYPE/VALUE') DIC_VALUE,
          ExtractValue(COLUMN_VALUE,'MEMO_CODE/VALUE') VALUE,
          Extract(COLUMN_VALUE,'MEMO_CODE/DIC_CODE_TYPE') XML_DIC
        from
          XMLTable('FREE_CODES/MEMO_CODES/MEMO_CODE' passing lx_sub) T
      ) loop
        lt_memo_code.dic_asa_memo_code_type.value := tpl.DIC_VALUE;
        lt_memo_code.fco_mem_code := tpl.VALUE;
        iot_header.free_codes.memo_codes(iot_header.free_codes.memo_codes.COUNT) := lt_memo_code;
        asa_lib_record_trf_rec.load_dictionary(
          tpl.XML_DIC.extract('DIC_CODE_TYPE/*'),
          lt_memo_code.dic_asa_memo_code_type);
      end loop;
    end if;
    -- DATE
    if (lx_sub.existsNode('FREE_CODES/DATE_CODES') != 0) then
      for tpl in (
        select
          ExtractValue(COLUMN_VALUE,'DATE_CODE/DIC_CODE_TYPE/VALUE') DIC_VALUE,
          rep_utils.ReplicatorDateToDate(ExtractValue(COLUMN_VALUE,'DATE_CODE/VALUE')) VALUE,
          Extract(COLUMN_VALUE,'DATE_CODE/DIC_CODE_TYPE') XML_DIC
        from
          XMLTable('FREE_CODES/DATE_CODES/DATE_CODE' passing lx_sub) T
      ) loop
        lt_date_code.dic_asa_date_code_type.value := tpl.DIC_VALUE;
        lt_date_code.fco_dat_code := tpl.VALUE;
        iot_header.free_codes.date_codes(iot_header.free_codes.date_codes.COUNT) := lt_date_code;
        asa_lib_record_trf_rec.load_dictionary(
          tpl.XML_DIC.extract('DIC_CODE_TYPE/*'),
          lt_date_code.dic_asa_date_code_type);
      end loop;
    end if;
    -- CHAR
    if (lx_sub.existsNode('FREE_CODES/CHAR_CODES') != 0) then
      for tpl in (
        select
          ExtractValue(COLUMN_VALUE,'CHAR_CODE/DIC_CODE_TYPE/VALUE') DIC_VALUE,
          ExtractValue(COLUMN_VALUE,'CHAR_CODE/VALUE') VALUE,
          Extract(COLUMN_VALUE,'CHAR_CODE/DIC_CODE_TYPE') XML_DIC
        from
          XMLTable('FREE_CODES/CHAR_CODES/CHAR_CODE' passing lx_sub) T
      ) loop
        lt_char_code.dic_asa_char_code_type.value := tpl.DIC_VALUE;
        lt_char_code.fco_cha_code := tpl.VALUE;
        iot_header.free_codes.char_codes(iot_header.free_codes.char_codes.COUNT) := lt_char_code;
        asa_lib_record_trf_rec.load_dictionary(
          tpl.XML_DIC.extract('DIC_CODE_TYPE/*'),
          lt_char_code.dic_asa_char_code_type);
      end loop;
    end if;
  end if;

  lx_sub := ix_fragment.extract('HEADER/FREE_DATA');
  if (lx_sub is not null) then
    asa_lib_record_trf_rec.load_free_data(
      lx_sub.extract('FREE_DATA/FREE_DATA_01/*'),
      iot_header.free_data.free_data_01);
    asa_lib_record_trf_rec.load_free_data(
      lx_sub.extract('FREE_DATA/FREE_DATA_02/*'),
      iot_header.free_data.free_data_02);
    asa_lib_record_trf_rec.load_free_data(
      lx_sub.extract('FREE_DATA/FREE_DATA_03/*'),
      iot_header.free_data.free_data_03);
    asa_lib_record_trf_rec.load_free_data(
      lx_sub.extract('FREE_DATA/FREE_DATA_04/*'),
      iot_header.free_data.free_data_04);
    asa_lib_record_trf_rec.load_free_data(
      lx_sub.extract('FREE_DATA/FREE_DATA_05/*'),
      iot_header.free_data.free_data_05);
  end if;

  lx_sub := ix_fragment.extract('HEADER/VIRTUAL_FIELDS');
  if (lx_sub is not null) then
    asa_lib_record_trf_rec.load_virtual_fields(
      lx_sub.extract('VIRTUAL_FIELDS'),
      iot_header.virtual_fields);
  end if;
end;

procedure load_components(
  ix_fragment IN XMLType,
  iott_components IN OUT NOCOPY asa_typ_record_trf_def.TT_COMPONENTS)
is
  lt_component asa_typ_record_trf_def.T_COMPONENT;
begin
  for tpl in (
    select
      COLUMN_VALUE COMPONENT
    from
      XMLTable('COMPONENTS/COMPONENT' passing ix_fragment) T
  ) loop
    asa_lib_record_trf_rec.load_component(tpl.COMPONENT, lt_component);
    iott_components(iott_components.COUNT) := lt_component;
    lt_component := null;
  end loop;
end;

procedure load_component(
  ix_fragment IN XMLType,
  iot_component IN OUT NOCOPY asa_typ_record_trf_def.T_COMPONENT)
is
  lx_sub XMLType;
begin
  lx_sub := ix_fragment.extract('COMPONENT/*');
  select
    ExtractValue(lx_sub,'SOURCE_COMPANY/INSTANCE_NAME'),
    ExtractValue(lx_sub,'SOURCE_COMPANY/SCHEMA_NAME'),
    ExtractValue(lx_sub,'SOURCE_COMPANY/COMPANY_NAME'),
    ExtractValue(lx_sub,'OWNED_BY/SCHEMA_NAME'),
    ExtractValue(lx_sub,'OWNED_BY/COMPANY_NAME'),
    ExtractValue(lx_sub,'COMPONENT_DATA/ARC_POSITION'),
    ExtractValue(lx_sub,'COMPONENT_DATA/ARC_CDMVT'),
    ExtractValue(lx_sub,'COMPONENT_DATA/C_ASA_GEN_DOC_POS'),
    ExtractValue(lx_sub,'OPTION/ARC_OPTIONAL'),
    ExtractValue(lx_sub,'OPTION/C_ASA_ACCEPT_OPTION'),
    ExtractValue(lx_sub,'OPTION/DIC_ASA_OPTION/VALUE'),
    ExtractValue(lx_sub,'WARRANTY/DIC_GARANTY_CODE/VALUE'),
    ExtractValue(lx_sub,'WARRANTY/ARC_GUARANTY_CODE'),
    ExtractValue(lx_sub,'PRODUCT/GOO_MAJOR_REFERENCE'),
    ExtractValue(lx_sub,'PRODUCT/ARC_QUANTITY'),
    ExtractValue(lx_sub,'DESCRIPTIONS/ARC_DESCR'),
    ExtractValue(lx_sub,'DESCRIPTIONS/ARC_DESCR2'),
    ExtractValue(lx_sub,'DESCRIPTIONS/ARC_DESCR3'),
    ExtractValue(lx_sub,'AMOUNTS/COST_PRICE/ARC_COST_PRICE'),
    ExtractValue(lx_sub,'AMOUNTS/SALE_PRICE/ARC_SALE_PRICE'),
    ExtractValue(lx_sub,'AMOUNTS/SALE_PRICE/ARC_SALE_PRICE_ME'),
    ExtractValue(lx_sub,'AMOUNTS/SALE_PRICE/ARC_SALE_PRICE_EURO'),
    ExtractValue(lx_sub,'AMOUNTS/SALE_PRICE/ARC_SALE_PRICE2'),
    ExtractValue(lx_sub,'AMOUNTS/SALE_PRICE/ARC_SALE_PRICE2_ME'),
    ExtractValue(lx_sub,'AMOUNTS/SALE_PRICE/ARC_SALE_PRICE2_EURO')
  into
    iot_component.source_company.instance_name,
    iot_component.source_company.schema_name,
    iot_component.source_company.company_name,
    iot_component.owned_by.schema_name,
    iot_component.owned_by.company_name,
    iot_component.arc_position,
    iot_component.arc_cdmvt,
    iot_component.c_asa_gen_doc_pos,
    iot_component.arc_optional,
    iot_component.c_asa_accept_option,
    iot_component.dic_asa_option.value,
    iot_component.dic_garanty_code.value,
    iot_component.arc_guaranty_code,
    iot_component.gco_good.goo_major_reference,
    iot_component.arc_quantity,
    iot_component.arc_descr,
    iot_component.arc_descr2,
    iot_component.arc_descr3,
    iot_component.arc_cost_price,
    iot_component.arc_sale_price,
    iot_component.arc_sale_price_me,
    iot_component.arc_sale_price_euro,
    iot_component.arc_sale_price2,
    iot_component.arc_sale_price2_me,
    iot_component.arc_sale_price2_euro
  from DUAL;

  if (iot_component.dic_asa_option.value is not null) then
    asa_lib_record_trf_rec.load_dictionary(
      ix_fragment.extract('COMPONENT/OPTION/DIC_ASA_OPTION/*'),
      iot_component.dic_asa_option);
  end if;
  if (iot_component.dic_garanty_code.value is not null) then
    asa_lib_record_trf_rec.load_dictionary(
      ix_fragment.extract('COMPONENT/WARRANTY/DIC_GARANTY_CODE/*'),
      iot_component.dic_garanty_code);
  end if;

  --asa_lib_record_trf_rec.load_characterizations(
  --  ix_fragment.extract('COMPONENT/PRODUCT_CHARACTERISTICS'),
  --  iot_component.characterizations);

  lx_sub := ix_fragment.extract('COMPONENT/FREE_DATA');
  if (lx_sub is not null) then
    asa_lib_record_trf_rec.load_component_free_data(
      lx_sub.extract('FREE_DATA/FREE_DATA_01/*'),
      iot_component.free_data.free_data_01);
    asa_lib_record_trf_rec.load_component_free_data(
      lx_sub.extract('FREE_DATA/FREE_DATA_02/*'),
      iot_component.free_data.free_data_02);
    asa_lib_record_trf_rec.load_component_free_data(
      lx_sub.extract('FREE_DATA/FREE_DATA_03/*'),
      iot_component.free_data.free_data_03);
    asa_lib_record_trf_rec.load_component_free_data(
      lx_sub.extract('FREE_DATA/FREE_DATA_04/*'),
      iot_component.free_data.free_data_04);
    asa_lib_record_trf_rec.load_component_free_data(
      lx_sub.extract('FREE_DATA/FREE_DATA_05/*'),
      iot_component.free_data.free_data_05);
  end if;

  lx_sub := ix_fragment.extract('COMPONENT/VIRTUAL_FIELDS');
  if (lx_sub is not null) then
    asa_lib_record_trf_rec.load_virtual_fields(
      lx_sub.extract('VIRTUAL_FIELDS'),
      iot_component.virtual_fields);
  end if ;
end;

procedure load_operations(
  ix_fragment IN XMLType,
  iott_operations IN OUT NOCOPY asa_typ_record_trf_def.TT_OPERATIONS)
is
  lt_operation asa_typ_record_trf_def.T_OPERATION;
begin
  for tpl in (
    select
      COLUMN_VALUE OPERATION
    from
      XMLTable('OPERATIONS/OPERATION' passing ix_fragment) T
  ) loop
    asa_lib_record_trf_rec.load_operation(tpl.OPERATION, lt_operation);
    iott_operations(iott_operations.COUNT) := lt_operation;
    lt_operation := null;
  end loop;
end;

procedure load_operation(
  ix_fragment IN XMLType,
  iot_operation IN OUT NOCOPY asa_typ_record_trf_def.T_OPERATION)
is
  lx_sub XMLType;
begin
  lx_sub := ix_fragment.extract('OPERATION/*');
  select
    ExtractValue(lx_sub,'SOURCE_COMPANY/INSTANCE_NAME'),
    ExtractValue(lx_sub,'SOURCE_COMPANY/SCHEMA_NAME'),
    ExtractValue(lx_sub,'SOURCE_COMPANY/COMPANY_NAME'),
    ExtractValue(lx_sub,'OWNED_BY/SCHEMA_NAME'),
    ExtractValue(lx_sub,'OWNED_BY/COMPANY_NAME'),
    ExtractValue(lx_sub,'OPERATION_DATA/RET_POSITION'),
    ExtractValue(lx_sub,'OPERATION_DATA/C_ASA_GEN_DOC_POS'),
    ExtractValue(lx_sub,'OPTION/RET_OPTIONAL'),
    ExtractValue(lx_sub,'OPTION/C_ASA_ACCEPT_OPTION'),
    ExtractValue(lx_sub,'OPTION/DIC_ASA_OPTION/VALUE'),
    ExtractValue(lx_sub,'WARRANTY/RET_GUARANTY_CODE'),
    ExtractValue(lx_sub,'WARRANTY/DIC_GARANTY_CODE/VALUE'),
    ExtractValue(lx_sub,'TASK/TAS_REF'),
    ExtractValue(lx_sub,'TASK/DIC_OPERATOR/VALUE'),
    ExtractValue(lx_sub,'TASK/RET_EXTERNAL'),
    rep_utils.ReplicatorDateToDate(ExtractValue(lx_sub,'TASK/RET_BEGIN_DATE')),
    ExtractValue(lx_sub,'TASK/RET_DURATION'),
    rep_utils.ReplicatorDateToDate(ExtractValue(lx_sub,'TASK/RET_END_DATE')),
    ExtractValue(lx_sub,'TASK/RET_FINISHED'),
    ExtractValue(lx_sub,'TASK/RET_TIME'),
    ExtractValue(lx_sub,'TASK/RET_TIME_USED'),
    ExtractValue(lx_sub,'TASK/RET_WORK_RATE'),
    ExtractValue(lx_sub,'TASK/PER_KEY/PER_KEY1'),
    ExtractValue(lx_sub,'TASK/PER_KEY/PER_KEY2'),
    ExtractValue(lx_sub,'TASK/PRODUCT/GOO_MAJOR_REFERENCE_TO_REPAIR'),
    ExtractValue(lx_sub,'TASK/PRODUCT/GOO_MAJOR_REFERENCE_TO_BILL'),
    ExtractValue(lx_sub,'DESCRIPTIONS/RET_DESCR'),
    ExtractValue(lx_sub,'DESCRIPTIONS/RET_DESCR2'),
    ExtractValue(lx_sub,'DESCRIPTIONS/RET_DESCR3'),
    ExtractValue(lx_sub,'AMOUNTS/TASK_PRICE/RET_AMOUNT'),
    ExtractValue(lx_sub,'AMOUNTS/TASK_PRICE/RET_AMOUNT_EURO'),
    ExtractValue(lx_sub,'AMOUNTS/TASK_PRICE/RET_AMOUNT_ME'),
    ExtractValue(lx_sub,'AMOUNTS/COST_PRICE/RET_COST_PRICE'),
    ExtractValue(lx_sub,'AMOUNTS/SALE_PRICE/RET_SALE_AMOUNT'),
    ExtractValue(lx_sub,'AMOUNTS/SALE_PRICE/RET_SALE_AMOUNT_EURO'),
    ExtractValue(lx_sub,'AMOUNTS/SALE_PRICE/RET_SALE_AMOUNT_ME'),
    ExtractValue(lx_sub,'AMOUNTS/SALE_PRICE/RET_SALE_AMOUNT2'),
    ExtractValue(lx_sub,'AMOUNTS/SALE_PRICE/RET_SALE_AMOUNT2_EURO'),
    ExtractValue(lx_sub,'AMOUNTS/SALE_PRICE/RET_SALE_AMOUNT2_ME')
  into
    iot_operation.source_company.instance_name,
    iot_operation.source_company.schema_name,
    iot_operation.source_company.company_name,
    iot_operation.owned_by.schema_name,
    iot_operation.owned_by.company_name,
    iot_operation.ret_position,
    iot_operation.c_asa_gen_doc_pos,
    iot_operation.ret_optional,
    iot_operation.c_asa_accept_option,
    iot_operation.dic_asa_option.value,
    iot_operation.ret_guaranty_code,
    iot_operation.dic_garanty_code.value,
    iot_operation.fal_task.tas_ref,
    iot_operation.dic_operator.value,
    iot_operation.ret_external,
    iot_operation.ret_begin_date,
    iot_operation.ret_duration,
    iot_operation.ret_end_date,
    iot_operation.ret_finished,
    iot_operation.ret_time,
    iot_operation.ret_time_used,
    iot_operation.ret_work_rate,
    iot_operation.pac_person.per_key1,
    iot_operation.pac_person.per_key2,
    iot_operation.gco_good_to_repair.goo_major_reference,
    iot_operation.gco_good_to_bill.goo_major_reference,
    iot_operation.ret_descr,
    iot_operation.ret_descr2,
    iot_operation.ret_descr3,
    iot_operation.ret_amount,
    iot_operation.ret_amount_euro,
    iot_operation.ret_amount_me,
    iot_operation.ret_cost_price,
    iot_operation.ret_sale_amount,
    iot_operation.ret_sale_amount_euro,
    iot_operation.ret_sale_amount_me,
    iot_operation.ret_sale_amount2,
    iot_operation.ret_sale_amount2_euro,
    iot_operation.ret_sale_amount2_me
  from DUAL;

  -- chargement des descriptions du dictionnaire
  if (iot_operation.dic_asa_option.value is not null) then
    asa_lib_record_trf_rec.load_dictionary(
      ix_fragment.extract('OPERATION/OPTION/DIC_ASA_OPTION/*'),
      iot_operation.dic_asa_option);
  end if;

  if (iot_operation.dic_garanty_code.value is not null) then
    asa_lib_record_trf_rec.load_dictionary(
      ix_fragment.extract('OPERATION/WARRANTY/DIC_GARANTY_CODE/*'),
      iot_operation.dic_garanty_code);
  end if;

  if (iot_operation.dic_operator.value is not null) then
    asa_lib_record_trf_rec.load_dictionary(
      ix_fragment.extract('OPERATION/TASK/DIC_OPERATOR/*'),
      iot_operation.dic_operator);
  end if;

  lx_sub := ix_fragment.extract('OPERATION/FREE_DATA');
  if (lx_sub is not null) then
    asa_lib_record_trf_rec.load_operation_free_data(
      lx_sub.extract('FREE_DATA/FREE_DATA_01/*'),
      iot_operation.free_data.free_data_01);
    asa_lib_record_trf_rec.load_operation_free_data(
      lx_sub.extract('FREE_DATA/FREE_DATA_02/*'),
      iot_operation.free_data.free_data_02);
    asa_lib_record_trf_rec.load_operation_free_data(
      lx_sub.extract('FREE_DATA/FREE_DATA_03/*'),
      iot_operation.free_data.free_data_03);
    asa_lib_record_trf_rec.load_operation_free_data(
      lx_sub.extract('FREE_DATA/FREE_DATA_04/*'),
      iot_operation.free_data.free_data_04);
    asa_lib_record_trf_rec.load_operation_free_data(
      lx_sub.extract('FREE_DATA/FREE_DATA_05/*'),
      iot_operation.free_data.free_data_05);
  end if;

  lx_sub := ix_fragment.extract('OPERATION/VIRTUAL_FIELDS');
  if (lx_sub is not null) then
    asa_lib_record_trf_rec.load_virtual_fields(
      lx_sub.extract('VIRTUAL_FIELDS'),
      iot_operation.virtual_fields);
  end if;
end;

procedure load_virtual_fields(
  ix_fragment IN XMLType,
  iot_vfields IN OUT NOCOPY asa_typ_record_trf_def.T_VIRTUAL_FIELDS)
is
  lv_col_name fwk_i_typ_definition.DEF_NAME;
begin
  for tpl in (
    select
      T.COLUMN_VALUE.getRootElement() COL_NAME,
      ExtractValue(T.COLUMN_VALUE,'.') COL_VALUE
    from
      XMLTable('*/*' passing ix_fragment) T
  ) loop
    lv_col_name := tpl.COL_NAME;
    if (Substr(lv_col_name,1,4)='VFI_') then
      case Substr(lv_col_name,5,Instr(lv_col_name,'_',-1)-5)
        when 'DESCODES' then
          iot_vfields.descodes(lv_col_name) := tpl.COL_VALUE;
        when 'BOOLEAN' then
          iot_vfields.booleans(lv_col_name) := tpl.COL_VALUE;
        when 'FLOAT' then
          iot_vfields.floats(lv_col_name) := tpl.COL_VALUE;
        when 'CHAR' then
          iot_vfields.chars(lv_col_name) := tpl.COL_VALUE;
        when 'MEMO' then
          iot_vfields.memos(lv_col_name) := tpl.COL_VALUE;
        when 'INTEGER' then
          iot_vfields.integers(lv_col_name) := tpl.COL_VALUE;
        when 'DATE' then
          iot_vfields.dates(lv_col_name) := rep_utils.ReplicatorDateToDate(tpl.COL_VALUE);
        else
          null;
      end case;
    end if;
  end loop;
end;


procedure load_descriptions(
  ix_fragment IN XMLType,
  iv_description_type IN VARCHAR2,
  iott_descriptions IN OUT NOCOPY asa_typ_record_trf_def.TT_DESCRIPTIONS)
is
  lt_description asa_typ_record_trf_def.T_DESCRIPTION;
begin
  case iv_description_type
    when '1' then
      for tpl in (
        select
          ExtractValue(COLUMN_VALUE,'INTERNAL_DESCRIPTION/LANID') LANID,
          ExtractValue(COLUMN_VALUE,'INTERNAL_DESCRIPTION/SHORT_DESCRIPTION') SHORT_DESCRIPTION,
          ExtractValue(COLUMN_VALUE,'INTERNAL_DESCRIPTION/LONG_DESCRIPTION') LONG_DESCRIPTION,
          ExtractValue(COLUMN_VALUE,'INTERNAL_DESCRIPTION/FREE_DESCRIPTION') FREE_DESCRIPTION
        from
          XMLTable('INTERNAL_DESCRIPTIONS/INTERNAL_DESCRIPTION' passing ix_fragment) T
      ) loop
        lt_description.pc_lang.lanid := tpl.LANID;
        lt_description.short_description := tpl.SHORT_DESCRIPTION;
        lt_description.long_description := tpl.LONG_DESCRIPTION;
        lt_description.free_description := tpl.FREE_DESCRIPTION;

        iott_descriptions(iott_descriptions.COUNT) := lt_description;
      end loop;
    when '2' then
      for tpl in (
        select
          ExtractValue(COLUMN_VALUE,'EXTERNAL_DESCRIPTION/LANID') LANID,
          ExtractValue(COLUMN_VALUE,'EXTERNAL_DESCRIPTION/SHORT_DESCRIPTION') SHORT_DESCRIPTION,
          ExtractValue(COLUMN_VALUE,'EXTERNAL_DESCRIPTION/LONG_DESCRIPTION') LONG_DESCRIPTION,
          ExtractValue(COLUMN_VALUE,'EXTERNAL_DESCRIPTION/FREE_DESCRIPTION') FREE_DESCRIPTION
        from
          XMLTable('EXTERNAL_DESCRIPTIONS/EXTERNAL_DESCRIPTION' passing ix_fragment) T
      ) loop
        lt_description.pc_lang.lanid := tpl.LANID;
        lt_description.short_description := tpl.SHORT_DESCRIPTION;
        lt_description.long_description := tpl.LONG_DESCRIPTION;
        lt_description.free_description := tpl.FREE_DESCRIPTION;

        iott_descriptions(iott_descriptions.COUNT) := lt_description;
      end loop;
  end case;
end;

procedure load_address(
  ix_fragment IN XMLType,
  iot_address IN OUT NOCOPY asa_typ_record_trf_def.T_ADDRESS)
is
begin
  select
    ExtractValue(ix_fragment,'ARE_ADDRESS'),
    ExtractValue(ix_fragment,'ARE_CARE_OF'),
    ExtractValue(ix_fragment,'ARE_CONTACT'),
    ExtractValue(ix_fragment,'ARE_COUNTY'),
    ExtractValue(ix_fragment,'ARE_FORMAT_CITY'),
    ExtractValue(ix_fragment,'ARE_PO_BOX_NBR'),
    ExtractValue(ix_fragment,'ARE_PO_BOX'),
    ExtractValue(ix_fragment,'ARE_POSTCODE'),
    ExtractValue(ix_fragment,'ARE_STATE'),
    ExtractValue(ix_fragment,'ARE_TOWN'),
    ExtractValue(ix_fragment,'ADDRESS/DIC_ADDRESS_TYPE/VALUE'),
    ExtractValue(ix_fragment,'ADDRESS/PER_KEY1'),
    ExtractValue(ix_fragment,'ADDRESS/PER_KEY2'),
    ExtractValue(ix_fragment,'CNTID')
  into
    iot_address.are_address,
    iot_address.are_care_of,
    iot_address.are_contact,
    iot_address.are_county,
    iot_address.are_format_city,
    iot_address.are_po_box_nbr,
    iot_address.are_po_box,
    iot_address.are_postcode,
    iot_address.are_state,
    iot_address.are_town,
    iot_address.pac_address.dic_address_type.value,
    iot_address.pac_address.per_key1,
    iot_address.pac_address.per_key2,
    iot_address.pc_cntry.cntid
  from DUAL;

  if (iot_address.pac_address.dic_address_type.value is not null) then
    asa_lib_record_trf_rec.load_dictionary(
      ix_fragment.extract('ADDRESS/DIC_ADDRESS_TYPE/*'),
      iot_address.pac_address.dic_address_type);
  end if;
end;

procedure load_address(
  ix_fragment IN XMLType,
  iot_address IN OUT NOCOPY asa_typ_record_trf_def.T_ADDRESS_E)
is
begin
  select
    ExtractValue(ix_fragment,'ARE_ADDRESS'),
    ExtractValue(ix_fragment,'ARE_CARE_OF'),
    ExtractValue(ix_fragment,'ARE_COUNTY'),
    ExtractValue(ix_fragment,'ARE_FORMAT_CITY'),
    ExtractValue(ix_fragment,'ARE_PO_BOX'),
    ExtractValue(ix_fragment,'ARE_PO_BOX_NBR'),
    ExtractValue(ix_fragment,'ARE_POSTCODE'),
    ExtractValue(ix_fragment,'ARE_STATE'),
    ExtractValue(ix_fragment,'ARE_TOWN'),
    ExtractValue(ix_fragment,'ADDRESS/DIC_ADDRESS_TYPE/VALUE'),
    ExtractValue(ix_fragment,'ADDRESS/PER_KEY1'),
    ExtractValue(ix_fragment,'ADDRESS/PER_KEY2'),
    ExtractValue(ix_fragment,'CNTID'),
    ExtractValue(ix_fragment,'LANID')
  into
    iot_address.are_address,
    iot_address.are_care_of,
    iot_address.are_county,
    iot_address.are_format_city,
    iot_address.are_po_box,
    iot_address.are_po_box_nbr,
    iot_address.are_postcode,
    iot_address.are_state,
    iot_address.are_town,
    iot_address.pac_address.dic_address_type.value,
    iot_address.pac_address.per_key1,
    iot_address.pac_address.per_key2,
    iot_address.pc_cntry.cntid,
    iot_address.pc_lang.lanid
  from DUAL;

  if (iot_address.pac_address.dic_address_type.value is not null) then
    asa_lib_record_trf_rec.load_dictionary(
      ix_fragment.extract('ADDRESS/DIC_ADDRESS_TYPE/*'),
      iot_address.pac_address.dic_address_type);
  end if;
end;

procedure load_diagnostics(
  ix_fragment IN XMLType,
  iott_diagnostics IN OUT NOCOPY asa_typ_record_trf_def.TT_DIAGNOSTICS)
is
  lt_diagnostic asa_typ_record_trf_def.T_DIAGNOSTIC;
begin
  for tpl in (
    select
      COLUMN_VALUE DIAGNOSTIC
    from
      XMLTable('DIAGNOSTICS/DIAGNOSTIC' passing ix_fragment) T
  ) loop
    asa_lib_record_trf_rec.load_diagnostic(tpl.DIAGNOSTIC, lt_diagnostic);
    iott_diagnostics(iott_diagnostics.COUNT) := lt_diagnostic;
    lt_diagnostic := null;
  end loop;
end;

procedure load_diagnostic(
  ix_fragment IN XMLType,
  iot_diagnostic IN OUT NOCOPY asa_typ_record_trf_def.T_DIAGNOSTIC)
is
  lx_sub XMLType;
begin
  lx_sub := ix_fragment.extract('DIAGNOSTIC/*');
  select
    ExtractValue(lx_sub,'SOURCE_COMPANY/INSTANCE_NAME') INSTANCE_NAME,
    ExtractValue(lx_sub,'SOURCE_COMPANY/SCHEMA_NAME') SCHEMA_NAME,
    ExtractValue(lx_sub,'SOURCE_COMPANY/COMPANY_NAME') COMPANY_NAME,
    ExtractValue(lx_sub,'DIA_SEQUENCE') DIA_SEQUENCE,
    ExtractValue(lx_sub,'C_ASA_CONTEXT') C_ASA_CONTEXT,
    ExtractValue(lx_sub,'DIC_DIAGNOSTICS_TYPE/VALUE') DIC_DIAGNOSTICS_TYPE_ID,
    ExtractValue(lx_sub,'DIC_OPERATOR/VALUE') DIC_OPERATOR_ID,
    ExtractValue(lx_sub,'DIA_DIAGNOSTICS_TEXT') DIA_DIAGNOSTICS_TEXT
  into
    iot_diagnostic.source_company.instance_name,
    iot_diagnostic.source_company.schema_name,
    iot_diagnostic.source_company.company_name,
    iot_diagnostic.dia_sequence,
    iot_diagnostic.c_asa_context,
    iot_diagnostic.dic_diagnostics_type.value,
    iot_diagnostic.dic_operator.value,
    iot_diagnostic.dia_diagnostics_text
  from DUAL;

  if (iot_diagnostic.dic_diagnostics_type.value is not null) then
    asa_lib_record_trf_rec.load_dictionary(
      ix_fragment.extract('DIAGNOSTIC/DIC_DIAGNOSTICS_TYPE/*'),
      iot_diagnostic.dic_diagnostics_type);
  end if;

  if (iot_diagnostic.dic_operator.value is not null) then
    asa_lib_record_trf_rec.load_dictionary(
      ix_fragment.extract('DIAGNOSTIC/DIC_OPERATOR/*'),
      iot_diagnostic.dic_operator);
  end if;

  lx_sub := ix_fragment.extract('DIAGNOSTIC/VIRTUAL_FIELDS');
  if (lx_sub is not null) then
    asa_lib_record_trf_rec.load_virtual_fields(
      lx_sub.extract('VIRTUAL_FIELDS'),
      iot_diagnostic.virtual_fields);
  end if ;
end;

procedure load_document_texts(
  ix_fragment IN XMLType,
  iott_document_texts IN OUT NOCOPY asa_typ_record_trf_def.TT_DOCUMENT_TEXTS)
is
  lt_document_text asa_typ_record_trf_def.T_DOCUMENT_TEXT;
begin
  for tpl in (
    select
      COLUMN_VALUE DOCUMENT_TEXT
    from
      XMLTable('DOCUMENT_TEXTS/DOCUMENT_TEXT' passing ix_fragment) T
  ) loop
    asa_lib_record_trf_rec.load_document_text(tpl.DOCUMENT_TEXT, lt_document_text);
    iott_document_texts(iott_document_texts.COUNT) := lt_document_text;
    lt_document_text := null;
  end loop;
end;

procedure load_document_text(
  ix_fragment IN XMLType,
  iot_document_text IN OUT NOCOPY asa_typ_record_trf_def.T_DOCUMENT_TEXT)
is
  lx_sub XMLType;
begin
  lx_sub := ix_fragment.extract('DOCUMENT_TEXT/*');
  select
    ExtractValue(lx_sub,'PC_APPLTXT/C_TEXT_TYPE') C_TEXT_TYPE,
    ExtractValue(lx_sub,'PC_APPLTXT/DIC_PC_THEME/VALUE') DIC_PC_THEME_ID,
    ExtractValue(lx_sub,'PC_APPLTXT/APH_CODE') APH_CODE,
    ExtractValue(lx_sub,'C_ASA_TEXT_TYPE') C_ASA_TEXT_TYPE,
    ExtractValue(lx_sub,'C_ASA_GAUGE_TYPE') C_ASA_GAUGE_TYPE,
    ExtractValue(lx_sub,'ATE_TEXT') ATE_TEXT
  into
    iot_document_text.pc_appltxt.c_text_type,
    iot_document_text.pc_appltxt.dic_pc_theme.value,
    iot_document_text.pc_appltxt.aph_code,
    iot_document_text.c_asa_text_type,
    iot_document_text.c_asa_gauge_type,
    iot_document_text.ate_text
  from DUAL;
end;

procedure load_free_data(
  ix_fragment IN XMLType,
  iot_free_data IN OUT NOCOPY asa_typ_record_trf_def.T_RECORD_FREE_DATA_DEF)
is
begin
  select
    ExtractValue(ix_fragment,'ARD_ALPHA_SHORT'),
    ExtractValue(ix_fragment,'ARD_ALPHA_LONG'),
    ExtractValue(ix_fragment,'ARD_INTEGER'),
    ExtractValue(ix_fragment,'ARD_DECIMAL'),
    ExtractValue(ix_fragment,'ARD_BOOLEAN'),
    ExtractValue(ix_fragment,'DIC_ASA_REC_FREE/VALUE')
  into
    iot_free_data.ard_alpha_short,
    iot_free_data.ard_alpha_long,
    iot_free_data.ard_integer,
    iot_free_data.ard_decimal,
    iot_free_data.ard_boolean,
    iot_free_data.dic_asa_rec_free.value
  from DUAL;

  if (iot_free_data.dic_asa_rec_free.value is not null) then
    asa_lib_record_trf_rec.load_dictionary(
      ix_fragment.extract('DIC_ASA_REC_FREE/*'),
      iot_free_data.dic_asa_rec_free);
  end if;
end;

procedure load_component_free_data(
  ix_fragment IN XMLType,
  iot_free_data IN OUT NOCOPY asa_typ_record_trf_def.T_COMPONENT_FREE_DATA_DIC_DEF)
is
begin
  select
    ExtractValue(ix_fragment,'ARC_FREE_NUM'),
    ExtractValue(ix_fragment,'ARC_FREE_CHAR'),
    ExtractValue(ix_fragment,'DIC_ASA_FREE_DICO_COMP/VALUE')
  into
    iot_free_data.arc_free_num,
    iot_free_data.arc_free_char,
    iot_free_data.dic_asa_free_dico_comp.value
  from DUAL;

  if (iot_free_data.dic_asa_free_dico_comp.value is not null) then
    asa_lib_record_trf_rec.load_dictionary(
      ix_fragment.extract('DIC_ASA_FREE_DICO_COMP/*'),
      iot_free_data.dic_asa_free_dico_comp);
  end if;
end;
procedure load_component_free_data(
  ix_fragment IN XMLType,
  iot_free_data IN OUT NOCOPY asa_typ_record_trf_def.T_COMPONENT_FREE_DATA_DEF)
is
begin
  select
    ExtractValue(ix_fragment,'ARC_FREE_NUM'),
    ExtractValue(ix_fragment,'ARC_FREE_CHAR')
  into
    iot_free_data.arc_free_num,
    iot_free_data.arc_free_char
  from DUAL;
end;

procedure load_operation_free_data(
  ix_fragment IN XMLType,
  iot_free_data IN OUT NOCOPY asa_typ_record_trf_def.T_OPERATION_FREE_DATA_DIC_DEF)
is
begin
  select
    ExtractValue(ix_fragment,'RET_FREE_NUM'),
    ExtractValue(ix_fragment,'RET_FREE_CHAR'),
    ExtractValue(ix_fragment,'DIC_ASA_FREE_DICO_TASK/VALUE')
  into
    iot_free_data.ret_free_num,
    iot_free_data.ret_free_char,
    iot_free_data.dic_asa_free_dico_task.value
  from DUAL;

  if (iot_free_data.dic_asa_free_dico_task.value is not null) then
    asa_lib_record_trf_rec.load_dictionary(
      ix_fragment.extract('DIC_ASA_FREE_DICO_TASK/*'),
      iot_free_data.dic_asa_free_dico_task);
  end if;
end;
procedure load_operation_free_data(
  ix_fragment IN XMLType,
  iot_free_data IN OUT NOCOPY asa_typ_record_trf_def.T_OPERATION_FREE_DATA_DEF)
is
begin
  select
    ExtractValue(ix_fragment,'RET_FREE_NUM'),
    ExtractValue(ix_fragment,'RET_FREE_CHAR')
  into
    iot_free_data.ret_free_num,
    iot_free_data.ret_free_char
  from DUAL;
end;

procedure load_dictionary(
  ix_fragment IN XMLType,
  iot_dictionary IN OUT NOCOPY asa_typ_record_trf_def.T_DICTIONARY)
is
begin
  load_dictionary_descriptions(
    ix_fragment.extract('DESCRIPTIONS'),
    iot_dictionary.descriptions);
  load_dictionary_fields(
    ix_fragment.extract('ADDITIONAL_FIELDS'),
    iot_dictionary.additional_fields);
end;

procedure load_dictionary_descriptions(
  ix_fragment IN XMLType,
  iott_descriptions IN OUT NOCOPY asa_typ_record_trf_def.TT_DICTIONARY_DESCRIPTIONS)
is
  lt_descr asa_typ_record_trf_def.T_DICTIONARY_DESCRIPTION;
begin
  if (ix_fragment is null) then
    return;
  end if;

  for tpl in (
    select
      ExtractValue(COLUMN_VALUE,'DESCRIPTION/@LANID') LANID,
      ExtractValue(COLUMN_VALUE,'DESCRIPTION') VALUE
    from
      XMLTable('DESCRIPTIONS/DESCRIPTION' passing ix_fragment)
  ) loop
    lt_descr.pc_lang.lanid := tpl.LANID;
    lt_descr.value := tpl.VALUE;
    iott_descriptions(iott_descriptions.COUNT) := lt_descr;
  end loop;
end;

procedure load_dictionary_fields(
  ix_fragment IN XMLType,
  iott_fields IN OUT NOCOPY asa_typ_record_trf_def.TT_DICTIONARY_FIELDS)
is
begin
  if (ix_fragment is null) then
    return;
  end if;

  select
    ExtractValue(COLUMN_VALUE,'ADDITIONAL_FIELD/@NAME') NAME,
    ExtractValue(COLUMN_VALUE,'ADDITIONAL_FIELD') VALUE
    bulk collect into iott_fields
  from
    XMLTable('ADDITIONAL_FIELDS/ADDITIONAL_FIELD' passing ix_fragment) T;
end;

procedure load_characterizations(
  ix_fragment IN XMLType,
  iott_characterizations IN OUT NOCOPY asa_typ_record_trf_def.TT_PRODUCT_CHARACTERISTICS)
is
begin
  if (ix_fragment is null) then
    return;
  end if;

  select
    asa_lib_record_trf.decode_characteristic_text(ExtractValue(COLUMN_VALUE,'PRODUCT_CHARACTERISTIC/@type')) CHARACTERIZATION_TYPE,
    ExtractValue(COLUMN_VALUE,'PRODUCT_CHARACTERISTIC') VALUE,
    null gco_characterization_id
    bulk collect into iott_characterizations
  from
    XMLTable('PRODUCT_CHARACTERISTICS/PRODUCT_CHARACTERISTIC' passing ix_fragment) T;
end;

END ASA_LIB_RECORD_TRF_REC;
 /*FMT(226) ERROR:
Input line 1310 (near output line 1253), col 19
(S41) Expecting:    )    ,    .    @   AS  CONNECT  CROSS  FOR  FULL
GROUP  HAVING  identifier  INNER  INTERSECT  JOIN  LEFT  MINUS
NATURAL  ORDER  PARTITION  RIGHT  SAMPLE  START  SUBPARTITION  UNION
VERSIONS  WHERE
*/
/*FMT(226) END UNFORMATTED */
