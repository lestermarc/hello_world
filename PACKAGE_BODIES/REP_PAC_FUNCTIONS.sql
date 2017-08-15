--------------------------------------------------------
--  DDL for Package Body REP_PAC_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_PAC_FUNCTIONS" 
/**
 * Fonctions de génération de document Xml.
 * Spécialisation: Client, fournisseur, partenaire, etc. (PAC)
 *
 * @version 1.0
 * @date 05/2003
 * @author jsomers
 * @author spfister
 * @author pvogel
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
AS

  /**
   * Internal declarations
   */

  TYPE FreeIdCode_T IS TABLE OF VARCHAR2(25) INDEX BY BINARY_INTEGER;
  gt_FreeIdCode FreeIdCode_T;


--
-- Public declarations
--

function get_pac_address(
  Id IN pac_person.pac_person_id%TYPE)
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
        'PAC_PERSON_ID, DIC_ADDRESS_TYPE_ID' as TABLE_KEY,
        a.pac_address_id),
      rep_pc_functions_link.get_pc_cntry_link(a.pc_cntry_id),
      XMLForest(
        a.add_address1,
        a.add_zipcode,
        a.add_city,
        a.add_state,
        l.lanid,
        a.add_comment),
      rep_pc_functions.get_dictionary('DIC_ADDRESS_TYPE',a.dic_address_type_id),
      XMLForest(
        to_char(a.add_since) as ADD_SINCE,
        a.add_format,
        a.add_principal),
      rep_pc_functions.get_descodes('C_PARTNER_STATUS',a.c_partner_status),
      XMLForest(
        add_priority,
        add_care_of,
        add_po_box,
        add_po_box_nbr,
        add_county),
      rep_pac_functions.get_pac_address_communication(a.pac_address_id),
      rep_pc_functions.get_com_vfields_record(a.pac_address_id,'PAC_ADDRESS'),
      rep_pc_functions.get_com_vfields_value(a.pac_address_id,'PAC_ADDRESS')
    )) into lx_data
  from pcs.pc_lang l, pac_address a
  where a.pac_person_id = Id and l.pc_lang_id = a.pc_lang_id;

  if (lx_data is not null) then
    select
      XMLElement(PAC_ADDRESS,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pac_address_communication(
  Id IN pac_address.pac_address_id%TYPE)
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
        'PAC_PERSON_ID, PAC_ADDRESS_ID, DIC_COMMUNICATION_TYPE_ID' as TABLE_KEY,
        pac_communication_id),
      rep_pc_functions.get_dictionary('DIC_COMMUNICATION_TYPE',dic_communication_type_id),
      XMLForest(
        com_ext_number,
        com_int_number,
        com_area_code,
        com_comment,
        com_international_number)
    )) into lx_data
  from pac_communication
  where pac_address_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(PAC_COMMUNICATION,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pac_communication(
  Id IN pac_person.pac_person_id%TYPE)
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
        'PAC_PERSON_ID, PAC_ADDRESS_ID, DIC_COMMUNICATION_TYPE_ID' as TABLE_KEY,
        pac_communication_id),
      rep_pc_functions.get_dictionary('DIC_COMMUNICATION_TYPE',dic_communication_type_id),
      XMLForest(
        com_ext_number,
        com_int_number,
        com_area_code,
        com_comment,
        com_international_number)
    )) into lx_data
  from pac_communication
  where pac_person_id = Id and pac_address_id is null;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(PAC_COMMUNICATION,
        XMLAttributes(
          'PAC_ADDRESS_ID IS NULL' as "delete_constraint"),
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pac_person_association(
  Id IN pac_person.pac_person_id%TYPE)
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
        'PAC_PERSON_ID,PAC_PAC_PERSON_ID' as TABLE_KEY,
        pac_person_association_id),
      rep_pac_functions_link.get_pac_person_link(pac_pac_person_id,'PAC_PAC_PERSON',1,1),
      rep_pc_functions.get_dictionary('DIC_ASSOCIATION_TYPE',dic_association_type_id),
      XMLForest(
        pas_comment,
        pas_function),
      rep_pac_functions.get_pac_date_code(pac_person_association_id, rep_pac_functions.FREE_CODE_ASSOCIATION),
      rep_pac_functions.get_pac_char_code(pac_person_association_id, rep_pac_functions.FREE_CODE_ASSOCIATION),
      rep_pac_functions.get_pac_number_code(pac_person_association_id, rep_pac_functions.FREE_CODE_ASSOCIATION),
      rep_pac_functions.get_pac_boolean_code(pac_person_association_id, rep_pac_functions.FREE_CODE_ASSOCIATION),
      rep_pc_functions.get_descodes('C_PARTNER_STATUS',c_partner_status),
      XMLForest(
        pas_main_contact)
    )) into lx_data
  from pac_person_association
  where pac_person_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(PAC_PERSON_ASSOCIATION,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pac_person_association_xml(
  Id IN pac_person.pac_person_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(PAC_PERSON_ASSOCIATION,
      XMLAttributes(
        pac_person_id as ID,
        pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
      XMLComment(rep_utils.GetCreationContext),
      XMLForest(
        'MAIN' as TABLE_TYPE,
        'PAC_PERSON_ID,PAC_PAC_PERSON_ID,DIC_ASSOCIATION_TYPE_ID' as TABLE_KEY,
        pac_person_association_id,
        pas_comment,
        pas_function),
      rep_pac_functions_link.get_pac_person_link(pac_person_id,'PAC_PERSON',1,1),
      rep_pac_functions_link.get_pac_person_link(pac_pac_person_id,'PAC_PAC_PERSON',1,1),
      rep_pc_functions.get_dictionary('DIC_ASSOCIATION_TYPE',dic_association_type_id),
      rep_pc_functions.get_descodes('C_PARTNER_STATUS',c_partner_status),
      XMLForest(
        pas_main_contact)
    )) into lx_data
  from pac_person_association
  where pac_person_id = Id;
  if (lx_data is not null) then
    select XMLElement(PERSON_ASSOCIATIONS, lx_data)
    into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(PERSON_ASSOCIATIONS,
          XMLElement(PAC_PERSON_ASSOCIATION,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;


function get_pac_date_code(
  Id IN pac_person.pac_person_id%TYPE,
  idCode IN FREECODE_T)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  EXECUTE IMMEDIATE
    'select
      XMLAgg(XMLElement(LIST_ITEM,
        XMLForest(
          ''AFTER'' as TABLE_TYPE,
          '''||gt_FreeIdCode(idCode)||',DIC_DATE_CODE_TYP_ID'' as TABLE_KEY,
          to_char(dat_code) as DAT_CODE),
        rep_pc_functions.get_dictionary(''DIC_DATE_CODE_TYP'',dic_date_code_typ_id)
      ))
     from pac_date_code
     where '||gt_FreeIdCode(idCode)||' = :Id'
    INTO lx_data
    USING Id;
  if (lx_data is null) then
    return null;
  end if;

  select
    XMLElement(PAC_DATE_CODE,
      XMLElement(LIST, lx_data)
    ) into lx_data
  from dual;

  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pac_char_code(
  Id IN pac_person.pac_person_id%TYPE,
  idCode IN FREECODE_T)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  EXECUTE IMMEDIATE
    'select
      XMLAgg(XMLElement(LIST_ITEM,
        XMLForest(
          ''AFTER'' as TABLE_TYPE,
          '''||gt_FreeIdCode(idCode)||',DIC_CHAR_CODE_TYP_ID'' as TABLE_KEY,
          cha_code),
        rep_pc_functions.get_dictionary(''DIC_CHAR_CODE_TYP'',dic_char_code_typ_id)
      ))
     from pac_char_code
     where '||gt_FreeIdCode(idCode)||' = :Id'
    INTO lx_data
    USING Id;
  if (lx_data is null) then
    return null;
  end if;

  select
    XMLElement(PAC_CHAR_CODE,
      XMLElement(LIST, lx_data)
    ) into lx_data
  from dual;

  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pac_number_code(
  Id IN pac_person.pac_person_id%TYPE,
  idCode IN FREECODE_T)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  EXECUTE IMMEDIATE
    'select
      XMLAgg(XMLElement(LIST_ITEM,
        XMLForest(
          ''AFTER'' as TABLE_TYPE,
          '''||gt_FreeIdCode(idCode)||',DIC_NUMBER_CODE_TYP_ID'' as TABLE_KEY,
          num_code),
        rep_pc_functions.get_dictionary(''DIC_NUMBER_CODE_TYP'',dic_number_code_typ_id)
      ))
     from pac_number_code
     where '||gt_FreeIdCode(idCode)||' = :Id'
    INTO lx_data
    USING Id;
  if (lx_data is null) then
    return null;
  end if;

  select
    XMLElement(PAC_NUMBER_CODE,
      XMLElement(LIST, lx_data)
    ) into lx_data
  FROM dual;

  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pac_boolean_code(
  Id IN pac_person.pac_person_id%TYPE,
  idCode IN FREECODE_T)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  EXECUTE IMMEDIATE
    'select
      XMLAgg(XMLElement(LIST_ITEM,
        XMLForest(
          ''AFTER'' as TABLE_TYPE,
          '''||gt_FreeIdCode(idCode)||',DIC_BOOLEAN_CODE_TYP_ID'' as TABLE_KEY,
          boo_code),
        rep_pc_functions.get_dictionary(''DIC_BOOLEAN_CODE_TYP'',dic_boolean_code_typ_id)
      ))
     from pac_boolean_code
     where '||gt_FreeIdCode(idCode)||' = :Id'
    INTO lx_data
    USING Id;
  if (lx_data is null) then
    return null;
  end if;

  select
    XMLElement(PAC_BOOLEAN_CODE,
      XMLElement(LIST, lx_data)
    ) into lx_data
  from dual;

  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;


--
-- Third  functions
--

function get_pac_third(
  Id IN pac_third.pac_third_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

 select
    XMLElement(PAC_THIRD,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'PAC_THIRD_ID' as TABLE_KEY,
        'PAC_THIRD_ID=PAC_PERSON_ID' as TABLE_MAPPING,
        thi_no_tva,
        thi_no_intra),
      rep_pc_functions.get_dictionary('DIC_THIRD_ACTIVITY',dic_third_activity_id),
      rep_pc_functions.get_dictionary('DIC_THIRD_AREA',dic_third_area_id),
      XMLForest(
        thi_no_format,
        thi_no_siren,
        thi_no_siret,
        thi_web_key),
      rep_pac_functions_link.get_pac_person_link(pac_pac_person_id,'PAC_PAC_PERSON',1),
      rep_pc_functions.get_dictionary('DIC_CITI_CODE',dic_citi_code_id),
      rep_pc_functions.get_dictionary('DIC_JURIDICAL_STATUS',dic_juridical_status_id),
      XMLForest(
        thi_custom_number,
        thi_no_fid,
        thi_no_state,
        thi_no_ide),
      rep_pc_functions.get_com_vfields_record(pac_third_id,'PAC_THIRD'),
      rep_pc_functions.get_com_vfields_value(pac_third_id,'PAC_THIRD')
    ) into lx_data
  from pac_third
  where pac_third_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pac_third_publication(
  Id IN pac_third.pac_third_id%TYPE)
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
        'PAC_THIRD_ID' as TABLE_KEY,
        pac_third_publication_id),
      rep_pc_functions.GET_DICTIONARY('DIC_PUBLICATION_TYPE',dic_publication_type_id),
      XMLForest(
        to_char(pub_date) as PUB_DATE,
        pub_page,
        pub_number,
        pub_comment)
    )) into lx_data
  from pac_third_publication
  where pac_third_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(PAC_THIRD_PUBLICATION,
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
-- Customer  functions
--

function get_customer_group_id(
  Id IN pac_custom_partner.pac_custom_partner_id%TYPE,
  auxiliary_account_id IN acs_auxiliary_account.acs_auxiliary_account_id%TYPE)
  return pac_custom_partner.pac_custom_partner_id%TYPE
is
  ln_result pac_custom_partner.pac_custom_partner_id%TYPE;
begin
  select pac_custom_partner_id
  into ln_result
  from pac_custom_partner
  where c_partner_category = '2' and pac_custom_partner_id <> Id and
    acs_auxiliary_account_id = auxiliary_account_id;
  return ln_result;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pac_custom_partner(
  Id IN pac_custom_partner.pac_custom_partner_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(PAC_CUSTOM_PARTNER,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'PAC_CUSTOM_PARTNER_ID' as TABLE_KEY,
        'PAC_CUSTOM_PARTNER_ID=PAC_PERSON_ID' as TABLE_MAPPING),
      rep_pc_functions.get_dictionary('DIC_TYPE_SUBMISSION',dic_type_submission_id),
      rep_pc_functions.get_dictionary('DIC_STATISTIC_1',dic_statistic_1_id),
      rep_pc_functions.get_dictionary('DIC_TYPE_PARTNER',dic_type_partner_id),
      rep_pc_functions.get_dictionary('DIC_STATISTIC_2',dic_statistic_2_id),
      rep_pc_functions.get_dictionary('DIC_STATISTIC_3',dic_statistic_3_id),
      rep_pc_functions.get_dictionary('DIC_STATISTIC_4',dic_statistic_4_id),
      rep_pc_functions.get_dictionary('DIC_STATISTIC_5',dic_statistic_5_id),
      rep_pac_functions_link.get_pac_remainder_categ_link(pac_remainder_category_id),
      rep_pac_functions_link.get_pac_payment_condition_link(pac_payment_condition_id),
      rep_fin_functions_link.get_custom_aux_account_link(
         acs_auxiliary_account_id,
         pac_custom_partner_id,
         rep_pac_functions.get_customer_group_id(pac_custom_partner_id, acs_auxiliary_account_id)),
      rep_pc_functions.get_descodes('C_REMAINDER_LAUNCHING',c_remainder_launching),
      rep_pac_functions_link.get_pac_address_link(pac_address_id),
      XMLForest(
        cus_comment),
      rep_pc_functions.get_dictionary('DIC_TARIFF',dic_tariff_id),
      rep_fin_functions_link.get_acs_vat_det_account_link(acs_vat_det_account_id),
      rep_pc_functions.get_descodes('C_TARIFFICATION_MODE',c_tariffication_mode),
      rep_pc_functions.get_descodes('C_PARTNER_CATEGORY',c_partner_category),
      rep_pac_functions_link.get_pac_representative_link(pac_representative_id),
      rep_pac_functions_link.get_pac_sending_condition_link(pac_sending_condition_id),
      --PAC_CALENDAR_TYPE_ID
      rep_pc_functions.get_descodes('C_TYPE_EDI',c_type_edi),
      XMLForest(
        cus_free_zone1,
        cus_free_zone2,
        cus_free_zone3,
        cus_free_zone4,
        cus_free_zone5,
        to_char(cus_without_remind_date) as CUS_WITHOUT_REMIND_DATE),
      rep_pc_functions.get_dictionary('DIC_COMPLEMENTARY_DATA',dic_complementary_data_id),
      XMLForest(
        cus_sup_copy1,
        cus_sup_copy2,
        cus_sup_copy3,
        cus_sup_copy4,
        cus_sup_copy5),
      rep_fin_functions_link.get_acs_fin_acc_s_payment_link(acs_fin_acc_s_payment_id),
      rep_pc_functions.get_descodes('C_STATUS_SETTLEMENT',c_status_settlement),
      rep_pc_functions.get_descodes('C_PARTNER_STATUS',c_partner_status),
      XMLForest(
        cus_rate_for_value,
        cus_periodic_invoicing,
        cus_periodic_delivery),
      rep_pc_functions.get_descodes('C_RESERVATION_TYP',c_reservation_typ),
      rep_pc_functions.get_descodes('C_DELIVERY_TYP',c_delivery_typ),
      rep_pc_functions.get_descodes('C_BVR_GENERATION_METHOD',c_bvr_generation_method),
      XMLForest(
        cus_sup_copy6,
        cus_sup_copy7,
        cus_sup_copy8,
        cus_sup_copy9,
        cus_sup_copy10),
      rep_pc_functions.get_descodes('C_DOC_CREATION',c_doc_creation),
      XMLForest(
        cus_min_invoicing,
        cus_delivery_delay),
      rep_pc_functions.get_dictionary('DIC_DELIVERY_PERIOD',dic_delivery_period_id),
      rep_pc_functions.get_descodes('C_DOC_CREATION_INVOICE',c_doc_creation_invoice,'C_DOC_CREATION'),
      rep_pc_functions.get_dictionary('DIC_INVOICING_PERIOD',dic_invoicing_period_id),
      XMLForest(
        cus_min_invoicing_delay),
      rep_pc_functions.get_descodes('C_INCOTERMS',c_incoterms),
      rep_pc_functions.get_dictionary('DIC_PIC_GROUP',dic_pic_group_id),
      XMLForest(
        cus_data_export,
        cus_supplier_number,
        cus_ean_number),
      rep_log_functions_link.get_doc_gauge_link(doc_gauge_id),
      rep_log_functions_link.get_doc_gauge_link(doc_doc_gauge_id,'DOC_DOC_GAUGE',1,0),
      XMLForest(
        cus_payment_factor,
        cus_adapted_factor,
        to_char(cus_payment_factor_date) as CUS_PAYMENT_FACTOR_DATE,
        to_char(cus_adapted_factor_date) as CUS_ADAPTED_FACTOR_DATE),
      rep_pac_functions_link.get_pac_third_link(pac_pac_third_1_id,'PAC_PAC_THIRD_1'),
      rep_pac_functions_link.get_pac_third_link(pac_pac_third_2_id,'PAC_PAC_THIRD_2'),
      XMLForest(
        cus_incoterms_place),
      rep_pc_functions.get_dictionary('DIC_PTC_THIRD_GROUP',dic_ptc_third_group_id),
      rep_pac_functions.get_pac_custom_financial_ref(pac_custom_partner_id),
      rep_pac_functions.get_pac_custom_credit_limit(pac_custom_partner_id),
      rep_pc_functions.get_descodes('C_MATERIAL_MGNT_MODE',c_material_mgnt_mode),
      rep_pc_functions.get_descodes('C_THIRD_MATERIAL_RELATION_TYPE',c_third_material_relation_type),
      rep_pc_functions.get_descodes('C_WEIGHING_MGNT',c_weighing_mgnt),
      XMLForest(
        cus_adv_material_mgnt),
      rep_pc_functions.get_descodes('C_ADV_MATERIAL_MODE',c_adv_material_mode),
      XMLForest(
        cus_tariff_by_set,
        cus_no_rem_charge,
        cus_no_moratorium_interest),
      rep_pac_functions_link.get_pac_distrib_channel_link(pac_distribution_channel_id),
      rep_pac_functions_link.get_pac_sale_territory_link(pac_sale_territory_id),
      rep_pac_functions_link.get_pac_schedule_link(pac_schedule_id),
      rep_pc_functions.get_com_vfields_record(pac_custom_partner_id,'PAC_CUSTOM_PARTNER'),
      rep_pc_functions.get_com_vfields_value(pac_custom_partner_id,'PAC_CUSTOM_PARTNER')
      /*
      -- Les tables get_pac_xxx_code ne sont pas utilisées dans ce contexte,
      -- car seul le champ PAC_PERSON_ID est renseigné pour les clients et les
      -- fourniseurs. Ces tables sont prise en compte par la personne
      -- directement et uniquement!!
      rep_pac_functions.get_pac_date_code(pac_custom_partner_id,FREE_CODE_PERSON),
      rep_pac_functions.get_pac_char_code(pac_custom_partner_id,FREE_CODE_PERSON),
      rep_pac_functions.get_pac_number_code(pac_custom_partner_id,FREE_CODE_PERSON),
      rep_pac_functions.get_pac_boolean_code(pac_custom_partner_id,FREE_CODE_PERSON)
      */
      /*
      -- Ne doivent pas être répliqués car représente des données dynamiques
      STM_STOCK,
      CUS_METAL_ACCOUNT,
      COM_NAME
      */
    ) into lx_data
  from pac_custom_partner
  where pac_custom_partner_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pac_custom_financial_ref(
  Id IN pac_person.pac_person_id%TYPE)
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
        'PAC_CUSTOM_PARTNER_ID,C_TYPE_REFERENCE,FRE_ACCOUNT_NUMBER,FRE_ACCOUNT_CONTROL' as TABLE_KEY,
        pac_financial_reference_id),
      rep_pc_functions.get_descodes('C_TYPE_REFERENCE',c_type_reference),
      rep_pc_functions_link.get_pc_bank_link(pc_bank_id),
      rep_pac_functions_link.get_pac_address_link(pac_address_id),
      XMLForest(
        fre_comment,
        fre_account_control,
        fre_account_number,
        fre_default,
        fre_ref_control,
        to_char(fre_last_control) as FRE_LAST_CONTROL),
      rep_pc_functions_link.get_pc_cntry_link(pc_cntry_id),
      XMLForest(
        fre_estab,
        fre_position,
        fre_dom_name,
        fre_dom_city),
      rep_pc_functions.get_descodes('C_PARTNER_STATUS',c_partner_status),
      rep_pc_functions.get_descodes('C_CHARGES_MANAGEMENT',c_charges_management),
      XMLForest(
        fre_bank_sbvr,
        fre_sbvr_doc_start_pos,
        fre_sbvr_doc_length,
      --ACS_PAYMENT_METHOD_ID
        fre_swift),
      rep_fin_functions_link.get_acs_fin_curr_link(acs_financial_currency_id)
      -- Les huits champs ci-dessous sont dépendants de la société et ne doivent pas être répliqués.
--       REP_PC_FUNCTIONS.get_descodes('C_SEPA_STATUS',C_SEPA_STATUS),
--       REP_PC_FUNCTIONS.get_descodes('C_SEPA_RECURRENCE',C_SEPA_RECURRENCE),
--       REP_PC_FUNCTIONS.get_descodes('C_SEPA_MODE',C_SEPA_MODE),
--       XMLForest(
--         FRE_SEPA_LSV,
--         FRE_SEPA_NUMBER,
--         FRE_SEPA_OBJECT,
--         to_char(FRE_SEPA_SIGN_DATE) as FRE_SEPA_SIGN_DATE,
--         to_char(FRE_SEPA_LAST_DBT) as FRE_SEPA_LAST_DBT)
    )) into lx_data
  from pac_financial_reference
  where pac_custom_partner_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(PAC_FINANCIAL_REFERENCE,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pac_custom_credit_limit(
  Id IN pac_credit_limit.pac_custom_partner_id%TYPE)
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
        'PAC_CUSTOM_PARTNER_ID' as TABLE_KEY,
        pac_credit_limit_id),
      rep_pc_functions.get_descodes('C_VALID',c_valid),
      rep_pc_functions.get_descodes('C_LIMIT_TYPE',c_limit_type),
      XMLForest(
        cre_amount_limit,
        cre_comment),
      rep_fin_functions_link.get_acs_fin_curr_link(acs_financial_currency_id),
      XMLForest(
        to_char(cre_limit_date) as CRE_LIMIT_DATE)
    )) into lx_data
  from pac_credit_limit
  where pac_custom_partner_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(PAC_CREDIT_LIMIT,
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
-- Supplier  functions
--

function get_supplier_group_id(
  Id IN pac_supplier_partner.pac_supplier_partner_id%TYPE,
  auxiliary_account_id IN acs_auxiliary_account.acs_auxiliary_account_id%TYPE)
  return pac_supplier_partner.pac_supplier_partner_id%TYPE
is
  ln_result pac_supplier_partner.pac_supplier_partner_id%TYPE;
begin
  select pac_supplier_partner_id
  into ln_result
  from pac_supplier_partner
  where c_partner_category = '2' and pac_supplier_partner_id <> Id and
    acs_auxiliary_account_id = auxiliary_account_id;
  return ln_result;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pac_supplier_partner(
  Id IN pac_supplier_partner.pac_supplier_partner_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLElement(PAC_SUPPLIER_PARTNER,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'PAC_SUPPLIER_PARTNER_ID' as TABLE_KEY,
        'PAC_SUPPLIER_PARTNER_ID=PAC_PERSON_ID' as TABLE_MAPPING),
      rep_pc_functions.get_dictionary('DIC_TYPE_SUBMISSION',dic_type_submission_id),
      rep_pc_functions.get_dictionary('DIC_PRIORITY_PAYMENT',dic_priority_payment_id),
      rep_pc_functions.get_dictionary('DIC_CENTER_PAYMENT',dic_center_payment_id),
      rep_pc_functions.get_dictionary('DIC_LEVEL_PRIORITY',dic_level_priority_id),
      rep_pac_functions_link.get_pac_remainder_categ_link(pac_remainder_category_id),
      rep_pac_functions_link.get_pac_payment_condition_link(pac_payment_condition_id),
      XMLForest(
        cre_blocked,
        cre_remark),
      rep_fin_functions_link.get_supplier_aux_account_link(
         acs_auxiliary_account_id,
         pac_supplier_partner_id,
         rep_pac_functions.get_supplier_group_id(pac_supplier_partner_id, acs_auxiliary_account_id)),
      rep_pc_functions.get_descodes('C_REMAINDER_LAUNCHING',c_remainder_launching),
      rep_pac_functions_link.get_pac_address_link(pac_address_id),
      rep_pc_functions.get_dictionary('DIC_TARIFF',dic_tariff_id),
      rep_pc_functions.get_dictionary('DIC_TYPE_PARTNER_F',dic_type_partner_f_id),
      rep_pc_functions.get_dictionary('DIC_STATISTIC_F1',dic_statistic_f1_id),
      rep_pc_functions.get_dictionary('DIC_STATISTIC_F2',dic_statistic_f2_id),
      rep_pc_functions.get_dictionary('DIC_STATISTIC_F3',dic_statistic_f3_id),
      rep_pc_functions.get_dictionary('DIC_STATISTIC_F4',dic_statistic_f4_id),
      rep_pc_functions.get_dictionary('DIC_STATISTIC_F5',dic_statistic_f5_id),
      rep_fin_functions_link.get_acs_vat_det_account_link(acs_vat_det_account_id),
      rep_pc_functions.get_descodes('C_TARIFFICATION_MODE',c_tariffication_mode),
      rep_pc_functions.get_descodes('C_PARTNER_CATEGORY',c_partner_category),
      rep_pac_functions_link.get_pac_sending_condition_link(pac_sending_condition_id),
      --PAC_CALENDAR_TYPE_ID,
      rep_pc_functions.get_descodes('C_TYPE_EDI',c_type_edi),
      XMLForest(
        cre_free_zone1,
        cre_free_zone2,
        cre_free_zone3,
        cre_free_zone4,
        cre_free_zone5,
        to_char(cre_without_remind_date) as CRE_WITHOUT_REMIND_DATE),
      rep_pc_functions.get_dictionary('DIC_COMPLEMENTARY_DATA',dic_complementary_data_id),
      XMLForest(
        cre_sup_copy1,
        cre_sup_copy2,
        cre_sup_copy3,
        cre_sup_copy4,
        cre_sup_copy5),
      rep_fin_functions_link.get_acs_fin_acc_s_payment_link(acs_fin_acc_s_payment_id),
      rep_pc_functions.get_descodes('C_STATUS_SETTLEMENT',c_status_settlement),
      rep_pc_functions.get_descodes('C_PARTNER_STATUS',c_partner_status),
      XMLForest(
        cre_sup_copy6,
        cre_sup_copy7,
        cre_sup_copy8,
        cre_sup_copy9,
        cre_sup_copy10,
        cre_supply_delay),
      rep_pc_functions.get_dictionary('DIC_PIC_GROUP',dic_pic_group_id),
      rep_pc_functions.get_descodes('C_INCOTERMS',c_incoterms),
      XMLForest(
        cre_data_export,
        cre_customer_number,
        cre_ean_number,
        cre_payment_factor,
        cre_adapted_factor,
        to_char(cre_payment_factor_date) as CRE_PAYMENT_FACTOR_DATE,
        to_char(cre_adapted_factor_date) as CRE_ADAPTED_FACTOR_DATE,
        cre_manufacturer),
      rep_pc_functions.get_descodes('C_DELIVERY_TYP',c_delivery_typ),
      XMLForest(
        cre_incoterms_place),
      rep_pac_functions_link.get_pac_third_link(pac_pac_third_1_id,'PAC_PAC_THIRD_1'),
      rep_pac_functions_link.get_pac_third_link(pac_pac_third_2_id,'PAC_PAC_THIRD_2'),
      rep_pc_functions.get_dictionary('DIC_PTC_THIRD_GROUP',dic_ptc_third_group_id),
      rep_pac_functions.get_pac_supplier_financial_ref(pac_supplier_partner_id),
      rep_pac_functions.get_pac_supplier_credit_limit(pac_supplier_partner_id),
      rep_pc_functions.get_descodes('C_MATERIAL_MGNT_MODE',c_material_mgnt_mode),
      rep_pc_functions.get_descodes('C_THIRD_MATERIAL_RELATION_TYPE',c_third_material_relation_type),
      rep_pc_functions.get_descodes('C_WEIGHING_MGNT',c_weighing_mgnt),
      XMLForest(
        cre_adv_material_mgnt),
      rep_pc_functions.get_descodes('C_ADV_MATERIAL_MODE',c_adv_material_mode),
      rep_pc_functions.get_descodes('C_SUPPLIER_LITIG',c_supplier_litig),
      rep_pc_functions.get_descodes('C_DAS2_BREAKDOWN',c_das2_breakdown),
      XMLForest(
        cre_tariff_by_set),
      rep_pac_functions_link.get_pac_schedule_link(pac_schedule_id),
      rep_pc_functions.get_com_vfields_record(pac_supplier_partner_id,'PAC_SUPPLIER_PARTNER'),
      rep_pc_functions.get_com_vfields_value(pac_supplier_partner_id,'PAC_SUPPLIER_PARTNER')
      /*
      -- Les tables get_pac_xxx_code ne sont pas utilisées dans ce contexte,
      -- car seul le champ PAC_PERSON_ID est renseigné pour les clients et les
      -- fourniseurs. Ces tables sont prise en compte par la personne
      -- directement et uniquement!!
      rep_pac_functions.get_pac_date_code(pac_supplier_partner_id,FREE_CODE_PERSON),
      rep_pac_functions.get_pac_char_code(pac_supplier_partner_id,FREE_CODE_PERSON),
      rep_pac_functions.get_pac_number_code(pac_supplier_partner_id,FREE_CODE_PERSON),
      rep_pac_functions.get_pac_boolean_code(pac_supplier_partner_id,FREE_CODE_PERSON)
      */
      /*
      -- Ne doivent pas être répliqués car représente des données dynamiques
      STM_STOCK_ID,
      CRE_METAL_ACCOUNT,
      COM_NAME
      */
    ) into lx_data
  from pac_supplier_partner
  where pac_supplier_partner_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pac_supplier_financial_ref(
  Id IN pac_person.pac_person_id%TYPE)
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
        'PAC_SUPPLIER_PARTNER_ID,C_TYPE_REFERENCE,FRE_ACCOUNT_NUMBER' as TABLE_KEY,
        pac_financial_reference_id),
      rep_pc_functions.get_descodes('C_TYPE_REFERENCE',c_type_reference),
      rep_pc_functions_link.get_pc_bank_link(pc_bank_id),
      rep_pac_functions_link.get_pac_address_link(pac_address_id),
      XMLForest(
        fre_comment,
        fre_account_control,
        fre_account_number,
        fre_default,
        fre_ref_control,
        to_char(fre_last_control) as FRE_LAST_CONTROL),
      rep_pc_functions_link.get_pc_cntry_link(pc_cntry_id),
      XMLForest(
        fre_estab,
        fre_position,
        fre_dom_name,
        fre_dom_city),
      rep_pc_functions.get_descodes('C_PARTNER_STATUS',c_partner_status),
      rep_pc_functions.get_descodes('C_CHARGES_MANAGEMENT',c_charges_management),
      XMLForest(
        fre_bank_sbvr,
        fre_sbvr_doc_start_pos,
        fre_sbvr_doc_length,
      --ACS_PAYMENT_METHOD_ID
        fre_swift),
      rep_fin_functions_link.get_acs_fin_curr_link(acs_financial_currency_id)
    )) into lx_data
  from pac_financial_reference
  where pac_supplier_partner_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(PAC_FINANCIAL_REFERENCE,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pac_supplier_credit_limit(
  Id IN pac_credit_limit.pac_supplier_partner_id%TYPE)
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
        'ACS_FINANCIAL_CURRENCY_ID,C_VALID,CRE_LIMIT_DATE' as TABLE_KEY,
        pac_credit_limit_id),
      rep_pc_functions.get_descodes('C_VALID',c_valid),
      rep_pc_functions.get_descodes('C_LIMIT_TYPE',c_limit_type),
      XMLForest(
        cre_amount_limit,
        cre_comment),
      rep_fin_functions_link.get_acs_fin_curr_link(acs_financial_currency_id),
      XMLForest(
        to_char(cre_limit_date) as CRE_LIMIT_DATE)
    )) into lx_data
  from pac_credit_limit
  where pac_supplier_partner_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(PAC_CREDIT_LIMIT,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pac_person_xml(
  Id IN pac_person.pac_person_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(PERSONS,
      XMLElement(PAC_PERSON,
        XMLAttributes(
          pac_person_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'PER_KEY1,PER_KEY2' as TABLE_KEY,
          pac_person_id),
        rep_pc_functions.get_dictionary('DIC_PERSON_POLITNESS',dic_person_politness_id),
        XMLForest(
          per_name,
          per_forename,
          per_activity,
          per_comment,
          per_contact,
          per_key1,
          per_key2),
        rep_pc_functions.get_dictionary('DIC_FREE_CODE1',dic_free_code1_id),
        rep_pc_functions.get_dictionary('DIC_FREE_CODE2',dic_free_code2_id),
        rep_pc_functions.get_dictionary('DIC_FREE_CODE3',dic_free_code3_id),
        rep_pc_functions.get_dictionary('DIC_FREE_CODE4',dic_free_code4_id),
        rep_pc_functions.get_dictionary('DIC_FREE_CODE5',dic_free_code5_id),
        rep_pc_functions.get_dictionary('DIC_FREE_CODE6',dic_free_code6_id),
        rep_pc_functions.get_dictionary('DIC_FREE_CODE7',dic_free_code7_id),
        rep_pc_functions.get_dictionary('DIC_FREE_CODE8',dic_free_code8_id),
        rep_pc_functions.get_dictionary('DIC_FREE_CODE9',dic_free_code9_id),
        rep_pc_functions.get_dictionary('DIC_FREE_CODE10',dic_free_code10_id),
        rep_pc_functions.get_descodes('C_PARTNER_STATUS',c_partner_status),
        XMLForest(
          per_short_name),
        -- L'ordre des opérations est important !!
        -- Il faut impérativement traiter les communications en premier,
        -- car elles peuvent contenir des adresses
        rep_pac_functions.get_pac_communication(pac_person_id),
        rep_pac_functions.get_pac_address(pac_person_id),
        --
        rep_pac_functions.get_pac_third(pac_person_id),
        rep_pac_functions.get_pac_custom_partner(pac_person_id),
        rep_pac_functions.get_pac_supplier_partner(pac_person_id),
        rep_pac_functions.get_pac_date_code(pac_person_id, rep_pac_functions.FREE_CODE_PERSON),
        rep_pac_functions.get_pac_char_code(pac_person_id, rep_pac_functions.FREE_CODE_PERSON),
        rep_pac_functions.get_pac_number_code(pac_person_id, rep_pac_functions.FREE_CODE_PERSON),
        rep_pac_functions.get_pac_boolean_code(pac_person_id, rep_pac_functions.FREE_CODE_PERSON),
        rep_pc_functions.get_com_vfields_record(pac_person_id,'PAC_PERSON'),
        rep_pc_functions.get_com_vfields_value(pac_person_id,'PAC_PERSON')
      )
    ) into lx_data
  from pac_person
  where pac_person_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(PERSONS,
          XMLElement(PAC_PERSON,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;


--
-- Conditions de paiement
--

function get_pac_payment_condition_xml(
  Id IN pac_payment_condition.pac_payment_condition_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(PAYMENT_CONDITIONS,
      XMLElement(PAC_PAYMENT_CONDITION,
        XMLAttributes(
          pac_payment_condition_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'PCO_DESCR, C_PAYMENT_CONDITION_KIND' as TABLE_KEY,
          pac_payment_condition_id,
          pco_descr,
          0 as pco_default,
          0 as pco_default_pay,
          pco_only_amount_bill_book),
        rep_pc_functions_link.get_pc_appltxt_link(pc_appltxt_id),
        rep_pc_functions.get_dictionary('DIC_CONDITION_TYP',dic_condition_typ_id),
        rep_pc_functions.get_descodes('C_DIRECT_PAY',c_direct_pay),
        rep_pc_functions.get_descodes('C_INVOICE_EXPIRY_INPUT_TYPE',c_invoice_expiry_input_type),
        rep_pc_functions.get_descodes('C_PARTNER_STATUS',c_partner_status),
        rep_pc_functions.get_descodes('C_PAYMENT_CONDITION_KIND',c_payment_condition_kind),
        rep_pc_functions.get_descodes('C_VALID',c_valid),
        rep_pac_functions.get_pac_condition_detail(pac_payment_condition_id),
        rep_pc_functions.get_com_vfields_record(pac_payment_condition_id,'PAC_PAYMENT_CONDITION'),
        rep_pc_functions.get_com_vfields_value(pac_payment_condition_id,'PAC_PAYMENT_CONDITION')
      )
    ) into lx_data
  from pac_payment_condition
  where pac_payment_condition_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(PAYMENT_CONDITIONS,
          XMLElement(PAC_PAYMENT_CONDITION,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_pac_condition_detail(
  Id IN pac_payment_condition.pac_payment_condition_id%TYPE)
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
        'PAC_PAYMENT_CONDITION_ID,CDE_PART,CDE_ACCOUNT,C_TIME_UNIT,CDE_DAY,CDE_DISCOUNT_RATE' as TABLE_KEY,
        pac_condition_detail_id,
        cde_day,
        cde_part,
        cde_account,
        cde_discount_rate,
        cde_end_month
        cde_round_amount,
        cde_amount_lc),
      rep_pc_functions.get_descodes('C_CALC_METHOD',c_calc_method),
      rep_pc_functions.get_descodes('C_ROUND_TYPE',c_round_type),
      rep_pc_functions.get_descodes('C_INVOICE_EXPIRY_DOC_TYPE',c_invoice_expiry_doc_type),
      rep_pc_functions.get_descodes('C_TIME_UNIT',c_time_unit),
      rep_log_functions_link.get_gco_good_link(gco_good_id),
      rep_log_functions_link.get_doc_gauge_link(doc_gauge_id),
      rep_pac_functions_link.get_pac_payment_condition_link(pac_pac_payment_condition_id, 'PAC_PAC_PAYMENT_CONDITION')
      )
    ) into lx_data
  from pac_condition_detail
  where pac_payment_condition_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(PAC_CONDITION_DETAIL,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
  return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;


BEGIN
  gt_FreeIdCode(rep_pac_functions.FREE_CODE_PERSON) := 'PAC_PERSON_ID';
  gt_FreeIdCode(rep_pac_functions.FREE_CODE_CUSTOMER) := 'PAC_CUSTOM_PARTNER_ID';
  gt_FreeIdCode(rep_pac_functions.FREE_CODE_SUPPLIER) := 'PAC_SUPPLIER_PARTNER_ID';
  gt_FreeIdCode(rep_pac_functions.FREE_CODE_ASSOCIATION) := 'PAC_PERSON_ASSOCIATION_ID';
END REP_PAC_FUNCTIONS;
