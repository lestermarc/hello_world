--------------------------------------------------------
--  DDL for Package Body ASA_LIB_RECORD_TRF_XML
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_LIB_RECORD_TRF_XML" 
/**
 * Fonctions de génération de document Xml pour
 * la circulation de dossiers SAV.
 *
 * @version 1.0
 * @date 04/2012
 * @author spfister
 */
AS


function get_lanid(
  in_lang_id IN pcs.pc_lang.pc_lang_id%TYPE)
  return pcs.pc_lang.lanid%TYPE
  RESULT_CACHE
is
  lv_result pcs.pc_lang.lanid%TYPE;
begin
  select LANID
  into lv_result
  from pcs.pc_lang
  where PC_LANG_ID = in_lang_id;
  return lv_result;
end;

function get_cntid(
  in_cntry_id IN pcs.pc_cntry.pc_cntry_id%TYPE)
  return pcs.pc_cntry.cntid%TYPE
  RESULT_CACHE
is
  lv_result pcs.pc_cntry.cntid%TYPE;
begin
  select CNTID
  into lv_result
  from PCS.PC_CNTRY
  where PC_CNTRY_ID = in_cntry_id;
  return lv_result;
end;

function get_characteristic_type(
  in_characterization_id in gco_characterization.gco_characterization_id%TYPE)
  return VARCHAR2
  RESULT_CACHE
is
  lv_result VARCHAR(32767);
begin
  select asa_lib_record_trf.decode_characteristic_type(C_CHARACT_TYPE)
  into lv_result
  from GCO_CHARACTERIZATION
  where GCO_CHARACTERIZATION_ID = in_characterization_id;

  return lv_result;

  exception
    when NO_DATA_FOUND then
      return null;
end;


function get_asa_record_recall_xml(
  in_record_id IN asa_record.asa_record_id%TYPE,
  it_msg_type IN asa_typ_record_trf_def.T_ASA_TRF_MSG_TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (it_msg_type not in (asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL,
                          asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL_ACCEPTED,
                          asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL_REFUSED)) then
    fwk_i_mgt_exception.raise_exception(
      in_error_code => fwk_i_typ_definition.EXCEPTION_INVALID_ARGUMENT_NO,
      iv_message => 'IT_MSG_TYPE was out of the range of valid values ('||it_msg_type||').',
      iv_stack_trace => dbms_utility.format_error_backtrace);
  end if;

  rep_lib_nls_parameters.SetNLSFormat;

  select
    XMLElement("AFTER_SALES_FILE",
      XMLElement("ENVELOPE",
        case it_msg_type
          when asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL then
            asa_lib_record_trf_xml.get_message_details(ASA_RECORD_ID, it_msg_type, asa_typ_record_trf_def.TRF_RECIPIENT_SRC, ARE_NUMBER)
          else
            asa_lib_record_trf_xml.get_message_details(ASA_RECORD_ID, it_msg_type, asa_typ_record_trf_def.TRF_RECIPIENT_DST, ARE_SRC_NUMBER)
        end,
        case when it_msg_type in (asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL,
                                  asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL_ACCEPTED,
                                  asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL_REFUSED) then
          XMLElement("COMMENT", ARE_TRF_RECALL_COMMENT)
        end,
        asa_lib_record_trf_xml.get_sender(ASA_RECORD_ID),
        case
          when it_msg_type in (asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL_ACCEPTED,
                               asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL_REFUSED) then
            asa_lib_record_trf_xml.get_recipient(ASA_RECORD_ID, asa_typ_record_trf_def.TRF_RECIPIENT_SRC)
          else
            asa_lib_record_trf_xml.get_recipient(ASA_RECORD_ID, asa_typ_record_trf_def.TRF_RECIPIENT_DST)
        end
      )
    ) into lx_data
  from ASA_RECORD
  where ASA_RECORD_ID = in_record_id;

  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_data;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;

function get_asa_record_switch_xml(
  it_msg_type IN asa_typ_record_trf_def.T_ASA_TRF_MSG_TYPE,
  it_msg_recipient IN asa_typ_record_trf_def.T_ASA_TRF_MSG_RECIPIENT,
  it_original IN asa_typ_record_trf_def.T_ENVELOPE)
  return XMLType
is
  lx_data XMLType;
  ln_record_id asa_record.asa_record_id%TYPE;
begin
  rep_lib_nls_parameters.SetNLSFormat;

  ln_record_id := case it_msg_recipient
    when asa_typ_record_trf_def.TRF_RECIPIENT_DST then
      asa_lib_record_trf.get_record_id(
        iv_number => it_original.message.are_number,
        it_origin => asa_typ_record_trf_def.TRF_RECORD_NUMBER)
    when asa_typ_record_trf_def.TRF_RECIPIENT_SRC then
      asa_lib_record_trf.get_record_id(
        iv_number => it_original.message.are_number,
        it_origin => asa_typ_record_trf_def.TRF_RECORD_SRC_NUMBER)
  end;

  select
    XMLElement("AFTER_SALES_FILE",
      XMLElement("ENVELOPE",
        case it_msg_recipient
          when asa_typ_record_trf_def.TRF_RECIPIENT_DST then
            asa_lib_record_trf_xml.get_message_details(ASA_RECORD_ID, it_msg_type, it_msg_recipient, ARE_NUMBER)
          when asa_typ_record_trf_def.TRF_RECIPIENT_SRC then
            asa_lib_record_trf_xml.get_message_details(ASA_RECORD_ID, it_msg_type, it_msg_recipient, ARE_SRC_NUMBER)
        end,
        XMLElement("ORIGINAL_MESSAGE",
          XMLElement("MESSAGE_TYPE", it_original.message.message_type),
          XMLElement("MESSAGE_NUMBER", it_original.message.message_number),
          XMLElement("ARE_NUMBER", it_original.message.are_number),
          XMLElement("MESSAGE_DATE", it_original.message.message_date)
        ),
        asa_lib_record_trf_xml.get_sender(ASA_RECORD_ID),
        asa_lib_record_trf_xml.get_recipient(ASA_RECORD_ID, it_msg_recipient)
      )
    ) into lx_data
  from ASA_RECORD
  where ASA_RECORD_ID = ln_record_id;

  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_data;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;


function get_asa_record_trf_xml(
  in_record_id IN asa_record.asa_record_id%TYPE,
  it_msg_type IN asa_typ_record_trf_def.T_ASA_TRF_MSG_TYPE,
  it_msg_recipient IN asa_typ_record_trf_def.T_ASA_TRF_MSG_RECIPIENT)
  return XMLType
is
  lx_data XMLType;
begin
  if (it_msg_type not in (asa_typ_record_trf_def.TRF_MSG_TYPE_SEND,
                          asa_typ_record_trf_def.TRF_MSG_TYPE_RESPONSE,
                          asa_typ_record_trf_def.TRF_MSG_TYPE_CALLBACK,
                          asa_typ_record_trf_def.TRF_MSG_TYPE_SEND_LOOP,
                          asa_typ_record_trf_def.TRF_MSG_TYPE_STATE,
                          asa_typ_record_trf_def.TRF_MSG_TYPE_STATUS_CHANGED,
                          asa_typ_record_trf_def.TRF_MSG_TYPE_NOTIFY_CHANGES)) then
    fwk_i_mgt_exception.raise_exception(
      in_error_code => fwk_i_typ_definition.EXCEPTION_INVALID_ARGUMENT_NO,
      iv_message => 'IT_MSG_TYPE was out of the range of valid values ('||it_msg_type||').',
      iv_stack_trace => dbms_utility.format_error_backtrace);
  end if;

  rep_lib_nls_parameters.SetNLSFormat;

  select
    XMLElement("AFTER_SALES_FILE",
      XMLElement("ENVELOPE",
        case
          when (it_msg_type in (asa_typ_record_trf_def.TRF_MSG_TYPE_SEND,
                                asa_typ_record_trf_def.TRF_MSG_TYPE_CALLBACK,
                                asa_typ_record_trf_def.TRF_MSG_TYPE_SEND_LOOP)) then
            asa_lib_record_trf_xml.get_message_details(ASA_RECORD_ID, it_msg_type, it_msg_recipient, ARE_NUMBER)

          when (it_msg_type in (asa_typ_record_trf_def.TRF_MSG_TYPE_STATE,
                                asa_typ_record_trf_def.TRF_MSG_TYPE_STATUS_CHANGED,
                                asa_typ_record_trf_def.TRF_MSG_TYPE_NOTIFY_CHANGES)) then
            asa_lib_record_trf_xml.get_message_details(ASA_RECORD_ID, it_msg_type, it_msg_recipient,
              case it_msg_recipient
                when asa_typ_record_trf_def.TRF_RECIPIENT_DST then ARE_NUMBER
                when asa_typ_record_trf_def.TRF_RECIPIENT_SRC then ARE_SRC_NUMBER
              end)

          when (it_msg_type = asa_typ_record_trf_def.TRF_MSG_TYPE_RESPONSE) then
            asa_lib_record_trf_xml.get_message_details(ASA_RECORD_ID, it_msg_type, asa_typ_record_trf_def.TRF_RECIPIENT_SRC, ARE_SRC_NUMBER)

          else
            asa_lib_record_trf_xml.get_message_details(ASA_RECORD_ID, it_msg_type, it_msg_recipient, ARE_SRC_NUMBER)
        end,
        case
          when (it_msg_type = asa_typ_record_trf_def.TRF_MSG_TYPE_CALLBACK) then
            XMLElement("COMMENT", ARE_TRF_RECALL_COMMENT)
        end,
        asa_lib_record_trf_xml.get_sender(ASA_RECORD_ID),
        case
          when (it_msg_type in (asa_typ_record_trf_def.TRF_MSG_TYPE_SEND,
                                asa_typ_record_trf_def.TRF_MSG_TYPE_CALLBACK,
                                asa_typ_record_trf_def.TRF_MSG_TYPE_SEND_LOOP)) then
            asa_lib_record_trf_xml.get_recipient(ASA_RECORD_ID, asa_typ_record_trf_def.TRF_RECIPIENT_DST)

          when (it_msg_type = asa_typ_record_trf_def.TRF_MSG_TYPE_RESPONSE) then
            asa_lib_record_trf_xml.get_recipient(ASA_RECORD_ID, asa_typ_record_trf_def.TRF_RECIPIENT_SRC)

          when (it_msg_type in (asa_typ_record_trf_def.TRF_MSG_TYPE_STATE,
                                asa_typ_record_trf_def.TRF_MSG_TYPE_STATUS_CHANGED,
                                asa_typ_record_trf_def.TRF_MSG_TYPE_NOTIFY_CHANGES)) then
            asa_lib_record_trf_xml.get_recipient(ASA_RECORD_ID, it_msg_recipient)
        end
      ),
      asa_lib_record_trf_xml.get_header(ASA_RECORD_ID, it_msg_recipient),
      asa_lib_record_trf_xml.get_components(ASA_RECORD_ID),
      asa_lib_record_trf_xml.get_operations(ASA_RECORD_ID)
    ) into lx_data
  from ASA_RECORD
  where ASA_RECORD_ID = in_record_id;

  rep_lib_nls_parameters.ResetNLSFormat;

  return lx_data;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      raise;
end;

function get_message_details(
  in_record_id IN asa_record.asa_record_id%TYPE,
  it_msg_type IN asa_typ_record_trf_def.T_ASA_TRF_MSG_TYPE,
  it_msg_recipient IN asa_typ_record_trf_def.T_ASA_TRF_MSG_RECIPIENT,
  iv_record_number IN VARCHAR2)
  return XMLType
is
  lx_data XMLType;
  lcd_NOW CONSTANT TIMESTAMP := SysTimestamp;
begin
  select
    XMLConcat(
      XMLElement("MESSAGE_TYPE", it_msg_type),
      XMLElement("LOOP_STATUS", C_ASA_TRF_LOOP_STATUS),
      XMLElement("MESSAGE_NUMBER", ARE_NUMBER||'-'||to_char(lcd_NOW,'YYYYMMDDHH24MISSFF')),
      XMLElement("ARE_NUMBER", iv_record_number),
      XMLElement("ARE_NUMBER_MATCHING_MODE", it_msg_recipient),
      XMLElement("MESSAGE_DATE", to_char(lcd_NOW,'YYYY-MM-DD"T"HH24:MI:SS.FF4'))
    ) into lx_data
  from ASA_RECORD
  where ASA_RECORD_ID = in_record_id;
  return lx_data;
end;

function get_sender(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLElement("FROM",
      XMLElement("INSTANCE_NAME", sys_context('USERENV', 'INSTANCE_NAME')),
      XMLElement("SCHEMA_NAME", COM_CurrentSchema),
      XMLElement("COMPANY_NAME",
        (select CURRENT_VALUE from PCS.V_PC_SESSION_INFO
         where PARAMETER = 'COMPANY')
      ),
      XMLForest(
        (select PER_KEY1 from PAC_PERSON
         where PAC_PERSON_ID = (select PAC_SUPPLIER_PARTNER_ID from ASA_RECORD
                                where ASA_RECORD_ID = in_record_id)
        ) as RECIPIENT_PER_KEY1
      )
    ) into lx_data
  from DUAL;

  return lx_data;
end;

function get_recipient(
  in_record_id IN asa_record.asa_record_id%TYPE,
  it_msg_recipient IN asa_typ_record_trf_def.T_ASA_TRF_MSG_RECIPIENT)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLElement("TO",
      case it_msg_recipient
        when asa_typ_record_trf_def.TRF_RECIPIENT_DST then
          XMLForest(
            ARE_DST_INSTANCE_NAME as "INSTANCE_NAME",
            ARE_DST_SCHEMA_NAME as "SCHEMA_NAME",
            ARE_DST_COM_NAME as "COMPANY_NAME"
          )
        when asa_typ_record_trf_def.TRF_RECIPIENT_SRC then
          XMLForest(
            ARE_SRC_INSTANCE_NAME as "INSTANCE_NAME",
            ARE_SRC_SCHEMA_NAME as "SCHEMA_NAME",
            ARE_SRC_COM_NAME as "COMPANY_NAME"
          )
      end
    ) into lx_data
  from ASA_RECORD
  where ASA_RECORD_ID = in_record_id;

  return lx_data;
  -- ne pas traiter l'exception NO_DATA_FOUND
  -- les informations de transfert sont obligatoires !
end;

function get_header(
  in_record_id IN asa_record.asa_record_id%TYPE,
  it_msg_recipient IN asa_typ_record_trf_def.T_ASA_TRF_MSG_RECIPIENT)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLElement("HEADER",
      XMLElement("HEADER_DATA",
        XMLForest(
          case
            when it_msg_recipient in (asa_typ_record_trf_def.TRF_RECIPIENT_NONE,
                                      asa_typ_record_trf_def.TRF_RECIPIENT_SRC) then
                -- utiliser les informations de la source
                XMLForest(
                  ARE_SRC_INSTANCE_NAME as "INSTANCE_NAME",
                  ARE_SRC_SCHEMA_NAME as "SCHEMA_NAME",
                  ARE_SRC_COM_NAME as "COMPANY_NAME"
                )
            -- envoi du document à un destinataire
            when (it_msg_recipient = asa_typ_record_trf_def.TRF_RECIPIENT_DST) and
                  -- si le dossier SAV peut être retourné à une source, cela veut
                  -- dire que les informations de la source sont "local", et qu'il
                  -- ne faut donc par utiliser les informations de la table
                 (asa_lib_record_trf.can_reply(ASA_RECORD_ID)=1) then
              XMLForest(
                sys_context('USERENV', 'INSTANCE_NAME') as "INSTANCE_NAME",
                COM_CurrentSchema as "SCHEMA_NAME",
                (select CURRENT_VALUE
                   from PCS.V_PC_SESSION_INFO
                  where PARAMETER = 'COMPANY')  as "COMPANY_NAME"
              )
            -- sinon, les informations de la tables sont correctes
            else
              XMLForest(
                ARE_SRC_INSTANCE_NAME as "INSTANCE_NAME",
                ARE_SRC_SCHEMA_NAME as "SCHEMA_NAME",
                ARE_SRC_COM_NAME as "COMPANY_NAME"
              )
          end as "SOURCE_COMPANY"
        ),
        XMLElement("ARE_NUMBER", ARE_NUMBER),
        XMLElement("ARE_SRC_NUMBER", ARE_SRC_NUMBER),
        asa_lib_record_trf_xml.get_asa_rep_type_link(ASA_REP_TYPE_ID),
        asa_lib_record_trf_xml.get_doc_gauge_link(DOC_GAUGE_ID),
        XMLElement("C_ASA_REP_TYPE_KIND", C_ASA_REP_TYPE_KIND),
        XMLElement("C_ASA_REP_STATUS", C_ASA_REP_STATUS),
        XMLElement("ARE_DATECRE", rep_utils.DateToReplicatorDate(ARE_DATECRE)),
        XMLElement("ARE_UPDATE_STATUS", rep_utils.DateToReplicatorDate(ARE_UPDATE_STATUS)),
        XMLElement("ARE_PRINT_STATUS", rep_utils.DateToReplicatorDate(ARE_PRINT_STATUS)),
        XMLElement("ARE_INTERNAL_REMARK", ARE_INTERNAL_REMARK),
        XMLElement("ARE_REQ_DATE_TEXT", ARE_REQ_DATE_TEXT),
        XMLElement("ARE_CUSTOMER_REMARK", ARE_CUSTOMER_REMARK),
        XMLElement("ARE_ADDITIONAL_ITEMS", ARE_ADDITIONAL_ITEMS),
        XMLElement("ARE_CUSTOMS_VALUE", ARE_CUSTOMS_VALUE),
        asa_lib_record_trf_xml.get_doc_record_link(DOC_RECORD_ID),
        asa_lib_record_trf_xml.get_pac_representative_link(PAC_REPRESENTATIVE_ID),
        XMLElement("ACS_CUSTOM_FIN_CURR",
          asa_lib_record_trf_xml.get_financial_currency_link(R.ACS_CUSTOM_FIN_CURR_ID)
        )
      ),
      asa_lib_record_trf_xml.get_descriptions(ASA_RECORD_ID),
      XMLElement("ADDRESSES",
        XMLElement("SOLD_TO",
          XMLElement("ARE_ADDRESS", ARE_ADDRESS1),
          XMLElement("ARE_CARE_OF", ARE_CARE_OF1),
          XMLElement("ARE_CONTACT", ARE_CONTACT1),
          XMLElement("ARE_COUNTY", ARE_COUNTY1),
          XMLElement("ARE_FORMAT_CITY", ARE_FORMAT_CITY1),
          XMLElement("ARE_PO_BOX_NBR", ARE_PO_BOX_NBR1),
          XMLElement("ARE_PO_BOX", ARE_PO_BOX1),
          XMLElement("ARE_POSTCODE", ARE_POSTCODE1),
          XMLElement("ARE_STATE", ARE_STATE1),
          XMLElement("ARE_TOWN", ARE_TOWN1),
          asa_lib_record_trf_xml.get_pac_address_link(PAC_ASA_ADDR1_ID),
          XMLElement("CNTID", asa_lib_record_trf_xml.get_cntid(PC_ASA_CNTRY1_ID))
        ),
        XMLElement("DELIVERED_TO",
          XMLElement("ARE_ADDRESS", ARE_ADDRESS2),
          XMLElement("ARE_CARE_OF", ARE_CARE_OF2),
          XMLElement("ARE_CONTACT", ARE_CONTACT2),
          XMLElement("ARE_COUNTY", ARE_COUNTY2),
          XMLElement("ARE_FORMAT_CITY", ARE_FORMAT_CITY2),
          XMLElement("ARE_PO_BOX_NBR", ARE_PO_BOX_NBR2),
          XMLElement("ARE_PO_BOX", ARE_PO_BOX2),
          XMLElement("ARE_POSTCODE", ARE_POSTCODE2),
          XMLElement("ARE_STATE", ARE_STATE2),
          XMLElement("ARE_TOWN", ARE_TOWN2),
          asa_lib_record_trf_xml.get_pac_address_link(PAC_ASA_ADDR2_ID),
          XMLElement("CNTID", asa_lib_record_trf_xml.get_cntid(PC_ASA_CNTRY2_ID))
        ),
        XMLElement("INVOICED_TO",
          XMLElement("ARE_ADDRESS", ARE_ADDRESS3),
          XMLElement("ARE_CARE_OF", ARE_CARE_OF3),
          XMLElement("ARE_CONTACT", ARE_CONTACT3),
          XMLElement("ARE_COUNTY", ARE_COUNTY3),
          XMLElement("ARE_FORMAT_CITY", ARE_FORMAT_CITY3),
          XMLElement("ARE_PO_BOX_NBR", ARE_PO_BOX_NBR3),
          XMLElement("ARE_PO_BOX", ARE_PO_BOX3),
          XMLElement("ARE_POSTCODE", ARE_POSTCODE3),
          XMLElement("ARE_STATE", ARE_STATE3),
          XMLElement("ARE_TOWN", ARE_TOWN3),
          asa_lib_record_trf_xml.get_pac_address_link(PAC_ASA_ADDR3_ID),
          XMLElement("CNTID", asa_lib_record_trf_xml.get_cntid(PC_ASA_CNTRY3_ID))
        ),
        XMLElement("AGENT",
          XMLElement("ARE_ADDRESS", ARE_ADDRESS_AGENT),
          XMLElement("ARE_CARE_OF", ARE_CARE_OF_AGENT),
          XMLElement("ARE_COUNTY", ARE_COUNTY_AGENT),
          XMLElement("ARE_FORMAT_CITY", ARE_FORMAT_CITY_AGENT),
          XMLElement("ARE_PO_BOX", ARE_PO_BOX_AGENT),
          XMLElement("ARE_PO_BOX_NBR", ARE_PO_BOX_NBR_AGENT),
          XMLElement("ARE_POSTCODE", ARE_POSTCODE_AGENT),
          XMLElement("ARE_STATE", ARE_STATE_AGENT),
          XMLElement("ARE_TOWN", ARE_TOWN_AGENT),
          asa_lib_record_trf_xml.get_pac_address_link(PAC_ASA_AGENT_ADDR_ID),
          XMLElement("CNTID", asa_lib_record_trf_xml.get_cntid(PC_ASA_AGENT_CNTRY_ID)),
          XMLElement("LANID", asa_lib_record_trf_xml.get_lanid(PC_ASA_AGENT_LANG_ID))
        ),
        XMLElement("RETAILER",
          XMLElement("ARE_ADDRESS", ARE_ADDRESS_DISTRIB),
          XMLElement("ARE_CARE_OF", ARE_CARE_OF_DET),
          XMLElement("ARE_COUNTY", ARE_COUNTY_DET),
          XMLElement("ARE_FORMAT_CITY", ARE_FORMAT_CITY_DISTRIB),
          XMLElement("ARE_PO_BOX", ARE_PO_BOX_DET),
          XMLElement("ARE_PO_BOX_NBR", ARE_PO_BOX_NBR_DET),
          XMLElement("ARE_POSTCODE", ARE_POSTCODE_DISTRIB),
          XMLElement("ARE_STATE", ARE_STATE_DISTRIB),
          XMLElement("ARE_TOWN", ARE_TOWN_DISTRIB),
          asa_lib_record_trf_xml.get_pac_address_link(PAC_ASA_DISTRIB_ADDR_ID),
          XMLElement("CNTID", asa_lib_record_trf_xml.get_cntid(PC_ASA_DISTRIB_CNTRY_ID)),
          XMLElement("LANID", asa_lib_record_trf_xml.get_lanid(PC_ASA_DISTRIB_LANG_ID))
        ),
        XMLElement("FINAL_CUSTOMER",
          XMLElement("ARE_ADDRESS", ARE_ADDRESS_FIN_CUST),
          XMLElement("ARE_CARE_OF", ARE_CARE_OF_CUST),
          XMLElement("ARE_COUNTY", ARE_COUNTY_CUST),
          XMLElement("ARE_FORMAT_CITY", ARE_FORMAT_CITY_FIN_CUST),
          XMLElement("ARE_PO_BOX", ARE_PO_BOX_CUST),
          XMLElement("ARE_PO_BOX_NBR", ARE_PO_BOX_NBR_CUST),
          XMLElement("ARE_POSTCODE", ARE_POSTCODE_FIN_CUST),
          XMLElement("ARE_STATE", ARE_STATE_FIN_CUST),
          XMLElement("ARE_TOWN", ARE_TOWN_FIN_CUST),
          asa_lib_record_trf_xml.get_pac_address_link(PAC_ASA_FIN_CUST_ADDR_ID),
          XMLElement("CNTID", asa_lib_record_trf_xml.get_cntid(PC_ASA_FIN_CUST_CNTRY_ID)),
          XMLElement("LANID", asa_lib_record_trf_xml.get_lanid(PC_ASA_FIN_CUST_LANG_ID))
        )
      ),
      XMLElement("PRODUCT_TO_REPAIR",
        XMLElement("GOO_MAJOR_REFERENCE",
          (select GOO_MAJOR_REFERENCE
             from GCO_GOOD
            where GCO_GOOD_ID = R.GCO_ASA_TO_REPAIR_ID)
        ),
        XMLForest(
          XMLConcat(
            case when GCO_CHAR1_ID is not null then
              XMLElement("PRODUCT_CHARACTERISTIC",
                XMLAttributes(asa_lib_record_trf_xml.get_characteristic_type(GCO_CHAR1_ID) as "type"),
                ARE_CHAR1_VALUE
              )
            end,
            case when GCO_CHAR2_ID is not null then
              XMLElement("PRODUCT_CHARACTERISTIC",
                XMLAttributes(asa_lib_record_trf_xml.get_characteristic_type(GCO_CHAR2_ID) as "type"),
                ARE_CHAR2_VALUE
              )
            end,
            case when GCO_CHAR3_ID is not null then
              XMLElement("PRODUCT_CHARACTERISTIC",
                XMLAttributes(asa_lib_record_trf_xml.get_characteristic_type(GCO_CHAR3_ID) as "type"),
                ARE_CHAR3_VALUE
              )
            end,
            case when GCO_CHAR4_ID is not null then
              XMLElement("PRODUCT_CHARACTERISTIC",
                XMLAttributes(asa_lib_record_trf_xml.get_characteristic_type(GCO_CHAR4_ID) as "type"),
                ARE_CHAR4_VALUE
              )
            end,
            case when GCO_CHAR5_ID is not null then
              XMLElement("PRODUCT_CHARACTERISTIC",
                XMLAttributes(asa_lib_record_trf_xml.get_characteristic_type(GCO_CHAR5_ID) as "type"),
                ARE_CHAR5_VALUE
              )
            end
          ) as "PRODUCT_CHARACTERISTICS"
        ),
        XMLElement("REFERENCES",
          XMLElement("ARE_GOOD_REF_1", ARE_GOOD_REF_1),
          XMLElement("ARE_GOOD_REF_2", ARE_GOOD_REF_2),
          XMLElement("ARE_GOOD_REF_3", ARE_GOOD_REF_3),
          XMLElement("ARE_CUSTOMER_REF", ARE_CUSTOMER_REF),
          XMLElement("ARE_GOOD_NEW_REF", ARE_GOOD_NEW_REF)
        ),
        XMLElement("DESCRIPTIONS",
          XMLElement("ARE_GCO_SHORT_DESCR", ARE_GCO_SHORT_DESCR),
          XMLElement("ARE_GCO_LONG_DESCR", ARE_GCO_LONG_DESCR),
          XMLElement("ARE_GCO_FREE_DESCR", ARE_GCO_FREE_DESCR)
        )
      ),
      XMLElement("REPAIRED_PRODUCT",
        XMLElement("GOO_MAJOR_REFERENCE",
          (select GOO_MAJOR_REFERENCE
             from GCO_GOOD
            where GCO_GOOD_ID = R.GCO_NEW_GOOD_ID)
        ),
        XMLForest(
          XMLConcat(
            case when GCO_NEW_CHAR1_ID is not null then
              XMLElement("PRODUCT_CHARACTERISTIC",
                XMLAttributes(asa_lib_record_trf_xml.get_characteristic_type(GCO_NEW_CHAR1_ID) as "type"),
                ARE_NEW_CHAR1_VALUE
              )
            end,
            case when GCO_NEW_CHAR2_ID is not null then
              XMLElement("PRODUCT_CHARACTERISTIC",
                XMLAttributes(asa_lib_record_trf_xml.get_characteristic_type(GCO_NEW_CHAR2_ID) as "type"),
                ARE_NEW_CHAR2_VALUE
              )
            end,
            case when GCO_NEW_CHAR3_ID is not null then
              XMLElement("PRODUCT_CHARACTERISTIC",
                XMLAttributes(asa_lib_record_trf_xml.get_characteristic_type(GCO_NEW_CHAR3_ID) as "type"),
                ARE_NEW_CHAR3_VALUE
              )
            end,
            case when GCO_NEW_CHAR4_ID is not null then
              XMLElement("PRODUCT_CHARACTERISTIC",
                XMLAttributes(asa_lib_record_trf_xml.get_characteristic_type(GCO_NEW_CHAR4_ID) as "type"),
                ARE_NEW_CHAR4_VALUE
              )
            end,
            case when GCO_NEW_CHAR5_ID is not null then
              XMLElement("PRODUCT_CHARACTERISTIC",
                XMLAttributes(asa_lib_record_trf_xml.get_characteristic_type(GCO_NEW_CHAR5_ID) as "type"),
                ARE_NEW_CHAR5_VALUE
              )
            end
          ) as "PRODUCT_CHARACTERISTICS"
        )
      ),
      XMLElement("PRODUCT_FOR_EXCHANGE",
        XMLElement("GOO_MAJOR_REFERENCE",
          (select GOO_MAJOR_REFERENCE
             from GCO_GOOD
            where GCO_GOOD_ID = R.GCO_ASA_EXCHANGE_ID)
        ),
        XMLForest(
          XMLConcat(
            case when GCO_EXCH_CHAR1_ID is not null then
              XMLElement("PRODUCT_CHARACTERISTIC",
                XMLAttributes(asa_lib_record_trf_xml.get_characteristic_type(GCO_EXCH_CHAR1_ID) as "type"),
                ARE_EXCH_CHAR1_VALUE
              )
            end,
            case when GCO_CHAR2_ID is not null then
              XMLElement("PRODUCT_CHARACTERISTIC",
                XMLAttributes(asa_lib_record_trf_xml.get_characteristic_type(GCO_EXCH_CHAR2_ID) as "type"),
                ARE_EXCH_CHAR2_VALUE
              )
            end,
            case when GCO_CHAR3_ID is not null then
              XMLElement("PRODUCT_CHARACTERISTIC",
                XMLAttributes(asa_lib_record_trf_xml.get_characteristic_type(GCO_EXCH_CHAR3_ID) as "type"),
                ARE_EXCH_CHAR3_VALUE
              )
            end,
            case when GCO_CHAR4_ID is not null then
              XMLElement("PRODUCT_CHARACTERISTIC",
                XMLAttributes(asa_lib_record_trf_xml.get_characteristic_type(GCO_EXCH_CHAR4_ID) as "type"),
                ARE_EXCH_CHAR4_VALUE
              )
            end,
            case when GCO_CHAR5_ID is not null then
              XMLElement("PRODUCT_CHARACTERISTIC",
                XMLAttributes(asa_lib_record_trf_xml.get_characteristic_type(GCO_EXCH_CHAR5_ID) as "type"),
                ARE_EXCH_CHAR5_VALUE
              )
            end
          ) as "PRODUCT_CHARACTERISTICS"
        )
      ),
      XMLElement("PRODUCT_FOR_INVOICE",
        XMLElement("GOO_MAJOR_REFERENCE",
          (select GOO_MAJOR_REFERENCE
             from GCO_GOOD
            where GCO_GOOD_ID = R.GCO_BILL_GOOD_ID)
        )
      ),
      XMLElement("PRODUCT_FOR_ESTIMATE_INVOICE",
        XMLElement("GOO_MAJOR_REFERENCE",
          (select GOO_MAJOR_REFERENCE
             from GCO_GOOD
            where GCO_GOOD_ID = R.GCO_DEVIS_BILL_GOOD_ID)
        )
      ),
      XMLElement("AMOUNTS",
        XMLElement("CURRENCY",
          asa_lib_record_trf_xml.get_financial_currency_link(R.ACS_FINANCIAL_CURRENCY_ID),
          XMLElement("ARE_CURR_BASE_PRICE", ARE_CURR_BASE_PRICE),
          XMLElement("ARE_CURR_RATE_EURO", ARE_CURR_RATE_EURO),
          XMLElement("ARE_CURR_RATE_OF_EXCH", ARE_CURR_RATE_OF_EXCH),
          XMLElement("ARE_EURO_CURRENCY", ARE_EURO_CURRENCY)
        ),
        XMLElement("COST_PRICE",
          XMLElement("ARE_COST_PRICE_C", ARE_COST_PRICE_C),
          XMLElement("ARE_COST_PRICE_T", ARE_COST_PRICE_T),
          XMLElement("ARE_COST_PRICE_W", ARE_COST_PRICE_W),
          XMLElement("ARE_COST_PRICE_S", ARE_COST_PRICE_S)
        ),
        XMLElement("SALE_PRICE",
          XMLElement("ARE_SALE_PRICE_C", ARE_SALE_PRICE_C),
          XMLElement("ARE_SALE_PRICE_S", ARE_SALE_PRICE_S),
          XMLElement("ARE_SALE_PRICE_T_EURO", ARE_SALE_PRICE_T_EURO),
          XMLElement("ARE_SALE_PRICE_T_MB", ARE_SALE_PRICE_T_MB),
          XMLElement("ARE_SALE_PRICE_T_ME", ARE_SALE_PRICE_T_ME),
          XMLElement("ARE_SALE_PRICE_W", ARE_SALE_PRICE_W)
        ),
        asa_lib_record_trf_xml.get_dictionary('DIC_TARIFF', DIC_TARIFF_ID),
        asa_lib_record_trf_xml.get_dictionary('DIC_TARIFF2', DIC_TARIFF2_ID, 1, 'DIC_TARIFF')
      ),
      XMLElement("WARRANTY",
        XMLElement("ARE_CUSTOMER_ERROR", ARE_CUSTOMER_ERROR),
        XMLElement("ARE_BEGIN_GUARANTY_DATE", rep_utils.DateToReplicatorDate(ARE_BEGIN_GUARANTY_DATE)),
        XMLElement("ARE_END_GUARANTY_DATE", rep_utils.DateToReplicatorDate(ARE_END_GUARANTY_DATE)),
        XMLElement("ARE_DET_SALE_DATE", rep_utils.DateToReplicatorDate(ARE_DET_SALE_DATE)),
        XMLElement("ARE_DET_SALE_DATE_TEXT", ARE_DET_SALE_DATE_TEXT),
        XMLElement("ARE_FIN_SALE_DATE", rep_utils.DateToReplicatorDate(ARE_FIN_SALE_DATE)),
        XMLElement("ARE_FIN_SALE_DATE_TEXT", ARE_FIN_SALE_DATE_TEXT),
        XMLElement("ARE_GENERATE_BILL", ARE_GENERATE_BILL),
        XMLElement("ARE_GUARANTY", ARE_GUARANTY),
        XMLElement("ARE_GUARANTY_CODE", ARE_GUARANTY_CODE),
        XMLElement("ARE_OFFERED_CODE", ARE_OFFERED_CODE),
        XMLElement("ARE_REP_BEGIN_GUAR_DATE", rep_utils.DateToReplicatorDate(ARE_REP_BEGIN_GUAR_DATE)),
        XMLElement("ARE_REP_END_GUAR_DATE", rep_utils.DateToReplicatorDate(ARE_REP_END_GUAR_DATE)),
        XMLElement("ARE_REP_GUAR", ARE_REP_GUAR),
        XMLElement("ARE_SALE_DATE", rep_utils.DateToReplicatorDate(ARE_SALE_DATE)),
        XMLElement("ARE_SALE_DATE_TEXT", ARE_SALE_DATE_TEXT),
        XMLElement("AGC_NUMBER",
          (select AGC_NUMBER
             from ASA_GUARANTY_CARDS
            where ASA_GUARANTY_CARDS_ID = R.ASA_GUARANTY_CARDS_ID)
        ),
        XMLElement("C_ASA_GUARANTY_UNIT", C_ASA_GUARANTY_UNIT),
        XMLElement("C_ASA_REP_GUAR_UNIT", C_ASA_REP_GUAR_UNIT),
        asa_lib_record_trf_xml.get_dictionary('DIC_GARANTY_CODE', DIC_GARANTY_CODE_ID)
      ),
      XMLElement("DELAYS",
        XMLElement("ARE_DATE_REG_REP", rep_utils.DateToReplicatorDate(ARE_DATE_REG_REP)),
        XMLForest(
          rep_utils.DateToReplicatorDate(ARE_REQ_DATE_C) as "ARE_REQ_DATE_C",
          rep_utils.DateToReplicatorDate(ARE_CONF_DATE_C) as "ARE_CONF_DATE_C",
          rep_utils.DateToReplicatorDate(ARE_UPD_DATE_C) as "ARE_UPD_DATE_C",
          rep_utils.DateToReplicatorDate(ARE_REQ_DATE_S) as "ARE_REQ_DATE_S",
          rep_utils.DateToReplicatorDate(ARE_CONF_DATE_S) as "ARE_CONF_DATE_S",
          rep_utils.DateToReplicatorDate(ARE_UPD_DATE_S) as "ARE_UPD_DATE_S",
          rep_utils.DateToReplicatorDate(ARE_DATE_END_CTRL) as "ARE_DATE_END_CTRL",
          rep_utils.DateToReplicatorDate(ARE_DATE_END_REP) as "ARE_DATE_END_REP",
          rep_utils.DateToReplicatorDate(ARE_DATE_END_SENDING) as "ARE_DATE_END_SENDING",
          rep_utils.DateToReplicatorDate(ARE_DATE_START_EXP) as "ARE_DATE_START_EXP",
          rep_utils.DateToReplicatorDate(ARE_DATE_START_REP) as "ARE_DATE_START_REP",
          ARE_NB_DAYS,
          ARE_NB_DAYS_CTRL,
          ARE_NB_DAYS_EXP,
          ARE_NB_DAYS_SENDING,
          ARE_NB_DAYS_WAIT,
          ARE_NB_DAYS_WAIT_COMP,
          ARE_NB_DAYS_WAIT_MAX
        )
      ),
      asa_lib_record_trf_xml.get_diagnostics(ASA_RECORD_ID),
      asa_lib_record_trf_xml.get_document_texts(ASA_RECORD_ID),
      asa_lib_record_trf_xml.get_free_codes(ASA_RECORD_ID),
      asa_lib_record_trf_xml.get_free_data(ASA_RECORD_ID),
      asa_lib_record_trf_xml.get_com_virtual_fields(ASA_RECORD_ID,'ASA_RECORD')
    ) into lx_data
  from ASA_RECORD R
  where ASA_RECORD_ID = in_record_id;
  return lx_data;

  exception
    when NO_DATA_FOUND then
      return null;
end;

function get_components(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLAgg(XMLElement("COMPONENT",
      XMLForest(
        XMLForest(
          ARC_SRC_INSTANCE_NAME as "INSTANCE_NAME",
          ARC_SRC_SCHEMA_NAME as "SCHEMA_NAME",
          ARC_SRC_COM_NAME as "COMPANY_NAME"
        ) as "SOURCE_COMPANY"
      ),
      XMLForest(
        XMLForest(
          ARC_OWNED_BY_SCHEMA_NAME as "SCHEMA_NAME",
          ARC_OWNED_BY_COM_NAME as "COMPANY_NAME"
        ) as "OWNED_BY"
      ),
      XMLElement("COMPONENT_DATA",
        XMLElement("ARC_POSITION", ARC_POSITION),
        XMLElement("ARC_CDMVT", ARC_CDMVT),
        XMLElement("C_ASA_GEN_DOC_POS", C_ASA_GEN_DOC_POS)
      ),
      XMLElement("OPTION",
        XMLElement("ARC_OPTIONAL", ARC_OPTIONAL),
        XMLElement("C_ASA_ACCEPT_OPTION", C_ASA_ACCEPT_OPTION),
        asa_lib_record_trf_xml.get_dictionary('DIC_ASA_OPTION', DIC_ASA_OPTION_ID)
      ),
      XMLElement("WARRANTY",
        asa_lib_record_trf_xml.get_dictionary('DIC_GARANTY_CODE', DIC_GARANTY_CODE_ID),
        XMLElement("ARC_GUARANTY_CODE", ARC_GUARANTY_CODE)
      ),
      XMLElement("PRODUCT",
        XMLElement("GOO_MAJOR_REFERENCE",
          (select GOO_MAJOR_REFERENCE
             from GCO_GOOD
            where GCO_GOOD_ID = R.GCO_COMPONENT_ID)
        ),
        XMLElement("ARC_QUANTITY", ARC_QUANTITY),
        XMLForest(
          XMLConcat(
            case when GCO_CHAR1_ID is not null then
              XMLElement("PRODUCT_CHARACTERISTIC",
                XMLAttributes(asa_lib_record_trf_xml.get_characteristic_type(GCO_CHAR1_ID) as "type"),
                ARC_CHAR1_VALUE
              )
            end,
            case when GCO_CHAR2_ID is not null then
              XMLElement("PRODUCT_CHARACTERISTIC",
                XMLAttributes(asa_lib_record_trf_xml.get_characteristic_type(GCO_CHAR2_ID) as "type"),
                ARC_CHAR2_VALUE
              )
            end,
            case when GCO_CHAR3_ID is not null then
              XMLElement("PRODUCT_CHARACTERISTIC",
                XMLAttributes(asa_lib_record_trf_xml.get_characteristic_type(GCO_CHAR3_ID) as "type"),
                ARC_CHAR3_VALUE
              )
            end,
            case when GCO_CHAR4_ID is not null then
              XMLElement("PRODUCT_CHARACTERISTIC",
                XMLAttributes(asa_lib_record_trf_xml.get_characteristic_type(GCO_CHAR4_ID) as "type"),
                ARC_CHAR4_VALUE
              )
            end,
            case when GCO_CHAR5_ID is not null then
              XMLElement("PRODUCT_CHARACTERISTIC",
                XMLAttributes(asa_lib_record_trf_xml.get_characteristic_type(GCO_CHAR5_ID) as "type"),
                ARC_CHAR5_VALUE
              )
            end
          ) as "PRODUCT_CHARACTERISTICS"
        )
      ),
      XMLElement("DESCRIPTIONS",
        XMLElement("ARC_DESCR", ARC_DESCR),
        XMLElement("ARC_DESCR2", ARC_DESCR2),
        XMLElement("ARC_DESCR3", ARC_DESCR3)
      ),
      XMLElement("AMOUNTS",
        XMLElement("COST_PRICE",
          XMLElement("ARC_COST_PRICE", ARC_COST_PRICE)
        ),
        XMLElement("SALE_PRICE",
          XMLElement("ARC_SALE_PRICE", ARC_SALE_PRICE),
          XMLElement("ARC_SALE_PRICE_ME", ARC_SALE_PRICE_ME),
          XMLElement("ARC_SALE_PRICE_EURO", ARC_SALE_PRICE_EURO),
          XMLElement("ARC_SALE_PRICE2", ARC_SALE_PRICE2),
          XMLElement("ARC_SALE_PRICE2_ME", ARC_SALE_PRICE2_ME),
          XMLElement("ARC_SALE_PRICE2_EURO", ARC_SALE_PRICE2_EURO)
        )
      ),
      XMLForest(
        XMLConcat(
          XMLForest(
            XMLForest(
              ARC_FREE_NUM1 as "ARC_FREE_NUM",
              ARC_FREE_CHAR1 as "ARC_FREE_CHAR",
              asa_lib_record_trf_xml.get_dictionary_def('DIC_ASA_FREE_DICO_COMP1',DIC_ASA_FREE_DICO_COMP1_ID) as "DIC_ASA_FREE_DICO_COMP"
            ) as "FREE_DATA_01"
          ),
          XMLForest(
            XMLForest(
              ARC_FREE_NUM2 as "ARC_FREE_NUM",
              ARC_FREE_CHAR2 as "ARC_FREE_CHAR",
              asa_lib_record_trf_xml.get_dictionary_def('DIC_ASA_FREE_DICO_COMP2',DIC_ASA_FREE_DICO_COMP2_ID) as "DIC_ASA_FREE_DICO_COMP"
            ) as "FREE_DATA_02"
          ),
          XMLForest(
            XMLForest(
              ARC_FREE_NUM3 as "ARC_FREE_NUM",
              ARC_FREE_CHAR3 as "ARC_FREE_CHAR"
            ) as "FREE_DATA_03"
          ),
          XMLForest(
            XMLForest(
              ARC_FREE_NUM4 as "ARC_FREE_NUM",
              ARC_FREE_CHAR4 as "ARC_FREE_CHAR"
            ) as "FREE_DATA_04"
          ),
          XMLForest(
            XMLForest(
              ARC_FREE_NUM5 as "ARC_FREE_NUM",
              ARC_FREE_CHAR5 as "ARC_FREE_CHAR"
            ) as "FREE_DATA_05"
          )
        ) as "FREE_DATA"
      ),
      asa_lib_record_trf_xml.get_com_virtual_fields(ASA_RECORD_COMP_ID,'ASA_RECORD_COMP')
    ) order by ARC_POSITION) into lx_data
  from (
    select RC.*
    from ASA_RECORD_COMP RC, ASA_RECORD R
    where R.ASA_RECORD_ID = in_record_id and
      R.ASA_RECORD_ID = RC.ASA_RECORD_ID and
      RC.ASA_RECORD_EVENTS_ID = R.ASA_RECORD_EVENTS_ID
  ) R;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select XMLElement("COMPONENTS", lx_data)
    into lx_data
    from DUAL;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then
      return null;
end;

function get_operations(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLAgg(XMLElement("OPERATION",
      XMLForest(
        XMLForest(
          RET_SRC_INSTANCE_NAME as "INSTANCE_NAME",
          RET_SRC_SCHEMA_NAME as "SCHEMA_NAME",
          RET_SRC_COM_NAME as "COMPANY_NAME"
        ) as "SOURCE_COMPANY"
      ),
      XMLForest(
        XMLForest(
          RET_OWNED_BY_SCHEMA_NAME as "SCHEMA_NAME",
          RET_OWNED_BY_COM_NAME as "COMPANY_NAME"
        ) as "OWNED_BY"
      ),
      XMLElement("OPERATION_DATA",
        XMLElement("RET_POSITION", RET_POSITION),
        XMLElement("C_ASA_GEN_DOC_POS", C_ASA_GEN_DOC_POS)
      ),
      XMLElement("OPTION",
        XMLElement("RET_OPTIONAL", RET_OPTIONAL),
        XMLElement("C_ASA_ACCEPT_OPTION", C_ASA_ACCEPT_OPTION),
        asa_lib_record_trf_xml.get_dictionary('DIC_ASA_OPTION', DIC_ASA_OPTION_ID)
      ),
      XMLElement("WARRANTY",
        XMLElement("RET_GUARANTY_CODE", RET_GUARANTY_CODE),
        asa_lib_record_trf_xml.get_dictionary('DIC_GARANTY_CODE', DIC_GARANTY_CODE_ID)
      ),
      XMLElement("TASK",
        XMLElement("TAS_REF",
          (select TAS_REF
             from FAL_TASK
            where FAL_TASK_ID = R.FAL_TASK_ID)
        ),
        asa_lib_record_trf_xml.get_dictionary('DIC_OPERATOR', DIC_OPERATOR_ID),
        XMLForest(
          RET_EXTERNAL
        ),
        XMLElement("RET_BEGIN_DATE", rep_utils.DateToReplicatorDate(RET_BEGIN_DATE)),
        XMLElement("RET_DURATION", RET_DURATION),
        XMLElement("RET_END_DATE", rep_utils.DateToReplicatorDate(RET_END_DATE)),
        XMLElement("RET_FINISHED", RET_FINISHED),
        XMLElement("RET_TIME", RET_TIME),
        XMLElement("RET_TIME_USED", RET_TIME_USED),
        XMLElement("RET_WORK_RATE", RET_WORK_RATE),
        asa_lib_record_trf_xml.get_pac_person_link(PAC_SUPPLIER_PARTNER_ID),
        XMLForest(
          XMLForest(
            (select GOO_MAJOR_REFERENCE
               from GCO_GOOD
              where GCO_GOOD_ID = R.GCO_ASA_TO_REPAIR_ID) as "GOO_MAJOR_REFERENCE_TO_REPAIR",
            (select GOO_MAJOR_REFERENCE
               from GCO_GOOD
              where GCO_GOOD_ID = R.GCO_BILL_GOOD_ID) as "GOO_MAJOR_REFERENCE_TO_BILL"
          ) as "PRODUCT"
        )
      ),
      XMLElement("DESCRIPTIONS",
        XMLElement("RET_DESCR", RET_DESCR),
        XMLElement("RET_DESCR2", RET_DESCR2),
        XMLElement("RET_DESCR3", RET_DESCR3)
      ),
      XMLElement("AMOUNTS",
        XMLElement("TASK_PRICE",
          XMLElement("RET_AMOUNT", RET_AMOUNT),
          XMLElement("RET_AMOUNT_EURO", RET_AMOUNT_EURO),
          XMLElement("RET_AMOUNT_ME", RET_AMOUNT_ME)
        ),
        XMLElement("COST_PRICE",
          XMLElement("RET_COST_PRICE", RET_COST_PRICE)
        ),
        XMLElement("SALE_PRICE",
          XMLElement("RET_SALE_AMOUNT", RET_SALE_AMOUNT),
          XMLElement("RET_SALE_AMOUNT_EURO", RET_SALE_AMOUNT_EURO),
          XMLElement("RET_SALE_AMOUNT_ME", RET_SALE_AMOUNT_ME),
          XMLElement("RET_SALE_AMOUNT2", RET_SALE_AMOUNT2),
          XMLElement("RET_SALE_AMOUNT2_EURO", RET_SALE_AMOUNT2_EURO),
          XMLElement("RET_SALE_AMOUNT2_ME", RET_SALE_AMOUNT2_ME)
        )
      ),
      XMLForest(
        XMLConcat(
          XMLForest(
            XMLForest(
              RET_FREE_NUM1 as "RET_FREE_NUM",
              RET_FREE_CHAR1 as "RET_FREE_CHAR",
              asa_lib_record_trf_xml.get_dictionary_def('DIC_ASA_FREE_DICO_TASK1',DIC_ASA_FREE_DICO_TASK1_ID) as "DIC_ASA_FREE_DICO_TASK"
            ) as "FREE_DATA_01"
          ),
          XMLForest(
            XMLForest(
              RET_FREE_NUM2 as "RET_FREE_NUM",
              RET_FREE_CHAR2 as "RET_FREE_CHAR",
              asa_lib_record_trf_xml.get_dictionary_def('DIC_ASA_FREE_DICO_TASK2',DIC_ASA_FREE_DICO_TASK2_ID) as "DIC_ASA_FREE_DICO_TASK"
            ) "FREE_DATA_02"
          ),
          XMLForest(
            XMLForest(
              RET_FREE_NUM3 as "RET_FREE_NUM",
              RET_FREE_CHAR3 as "RET_FREE_CHAR"
            ) as "FREE_DATA_03"
          ),
          XMLForest(
            XMLForest(
              RET_FREE_NUM4 as "RET_FREE_NUM",
              RET_FREE_CHAR4 as "RET_FREE_CHAR"
            ) as "FREE_DATA_04"
          ),
          XMLForest(
            XMLForest(
              RET_FREE_NUM5 as "RET_FREE_NUM",
              RET_FREE_CHAR5 as "RET_FREE_CHAR"
            ) as "FREE_DATA_05"
          )
        ) as "FREE_DATA"
      ),
      asa_lib_record_trf_xml.get_com_virtual_fields(ASA_RECORD_TASK_ID,'ASA_RECORD_TASK')
    )order by RET_POSITION) into lx_data
  from (
    select RT.*
    from ASA_RECORD_TASK RT, ASA_RECORD R
    where R.ASA_RECORD_ID = in_record_id and
      RT.ASA_RECORD_ID = R.ASA_RECORD_ID and
      RT.ASA_RECORD_EVENTS_ID = R.ASA_RECORD_EVENTS_ID
  ) R;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select XMLElement("OPERATIONS", lx_data)
    into lx_data
    from DUAL;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then
      return null;
end;


function get_description(
  in_record_id IN asa_record.asa_record_id%TYPE,
  iv_description_type IN VARCHAR2)
  return XMLType
is
  lx_data XMLType;
  lv_name VARCHAR2(32767);
begin
  lv_name := case iv_description_type when '1' then 'INTERNAL_DESCRIPTION' when '2' then 'EXTERNAL_DESCRIPTION' end;
  select
    XMLForest(
      XMLAgg(XMLElement(EVALNAME lv_name,
        XMLForest(
          asa_lib_record_trf_xml.get_lanid(PC_LANG_ID) as "LANID",
          ARD_SHORT_DESCRIPTION as "SHORT_DESCRIPTION",
          ARD_LONG_DESCRIPTION as "LONG_DESCRIPTION",
          ARD_FREE_DESCRIPTION as "FREE_DESCRIPTION"
        )
      )) as EVALNAME lv_name||'S'
    ) into lx_data
  from ASA_RECORD_DESCR
  where ASA_RECORD_ID = in_record_id and C_ASA_DESCRIPTION_TYPE = iv_description_type;
  return lx_data;

  exception
    when NO_DATA_FOUND then
      return null;
end;

function get_descriptions(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLForest(
      XMLConcat(
        asa_lib_record_trf_xml.get_description(in_record_id, '1'),
        asa_lib_record_trf_xml.get_description(in_record_id, '2')
      ) as "DESCRIPTIONS"
    ) into lx_data
  from DUAL;
  return lx_data;
end;

function get_diagnostics(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLForest(
      XMLAgg(XMLElement("DIAGNOSTIC",
        XMLForest(
          XMLForest(
            DIA_SRC_INSTANCE_NAME as "INSTANCE_NAME",
            DIA_SRC_SCHEMA_NAME as "SCHEMA_NAME",
            DIA_SRC_COM_NAME as "COMPANY_NAME"
          ) as "SOURCE_COMPANY"
        ),
        XMLElement("DIA_SEQUENCE", DIA_SEQUENCE),
        asa_lib_record_trf_xml.get_dictionary('DIC_DIAGNOSTICS_TYPE', DIC_DIAGNOSTICS_TYPE_ID),
        XMLForest(
          C_ASA_CONTEXT,
          DIA_DIAGNOSTICS_TEXT
        ),
        asa_lib_record_trf_xml.get_dictionary('DIC_OPERATOR', DIC_OPERATOR_ID),
        asa_lib_record_trf_xml.get_com_virtual_fields(ASA_DIAGNOSTICS_ID,'ASA_DIAGNOSTICS')
      ) order by DIC_DIAGNOSTICS_TYPE_ID, DIA_SEQUENCE) as "DIAGNOSTICS"
    ) into lx_data
  from ASA_DIAGNOSTICS
  where ASA_RECORD_ID = in_record_id;
  return lx_data;

  exception
    when NO_DATA_FOUND then
      return null;
end;


function get_document_texts(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLForest(
      XMLAgg(XMLElement("DOCUMENT_TEXT",
        asa_lib_record_trf_xml.get_pc_appltxt_link(PC_APPLTXT_ID),
        XMLForest(
          C_ASA_TEXT_TYPE,
          C_ASA_GAUGE_TYPE,
          ATE_TEXT
        )
      ) order by C_ASA_TEXT_TYPE, C_ASA_GAUGE_TYPE) as "DOCUMENT_TEXTS"
    ) into lx_data
  from ASA_RECORD_DOC_TEXT
  where ASA_RECORD_ID = in_record_id;
  return lx_data;

  exception
    when NO_DATA_FOUND then
      return null;
end;

function get_free_codes_boolean(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLForest(
      XMLAgg(XMLForest(
        XMLForest(
          asa_lib_record_trf_xml.get_dictionary_def('DIC_ASA_BOOLEAN_CODE_TYPE',DIC_ASA_BOOLEAN_CODE_TYPE_ID) as "DIC_CODE_TYPE",
          FCO_BOO_CODE as "VALUE"
        ) as "BOOLEAN_CODE"
      )) as "BOOLEAN_CODES"
    ) into lx_data
  from ASA_FREE_CODE
  where ASA_RECORD_ID = in_record_id and
    DIC_ASA_BOOLEAN_CODE_TYPE_ID is not null;
  return lx_data;

  exception
    when NO_DATA_FOUND then
      return null;
end;

function get_free_codes_number(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLForest(
      XMLAgg(XMLForest(
        XMLForest(
          asa_lib_record_trf_xml.get_dictionary_def('DIC_ASA_NUMBER_CODE_TYPE',DIC_ASA_NUMBER_CODE_TYPE_ID) as "DIC_CODE_TYPE",
          FCO_NUM_CODE as "VALUE"
        ) as "NUMBER_CODE"
      )) as "NUMBER_CODES"
    )  into lx_data
  from ASA_FREE_CODE
  where ASA_RECORD_ID = in_record_id and
    DIC_ASA_NUMBER_CODE_TYPE_ID is not null;
  return lx_data;

  exception
    when NO_DATA_FOUND then
      return null;
end;

function get_free_codes_memo(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLForest(
      XMLAgg(XMLForest(
        XMLForest(
          asa_lib_record_trf_xml.get_dictionary_def('DIC_ASA_MEMO_CODE_TYPE',DIC_ASA_MEMO_CODE_TYPE_ID) as "DIC_CODE_TYPE",
          FCO_MEM_CODE as "VALUE"
        ) as "MEMO_CODE"
      )) as "MEMO_CODES"
    ) into lx_data
  from ASA_FREE_CODE
  where ASA_RECORD_ID = in_record_id and
    DIC_ASA_MEMO_CODE_TYPE_ID is not null;
  return lx_data;

  exception
    when NO_DATA_FOUND then
      return null;
end;

function get_free_codes_date(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLForest(
      XMLAgg(XMLForest(
        XMLForest(
          asa_lib_record_trf_xml.get_dictionary_def('DIC_ASA_DATE_CODE_TYPE',DIC_ASA_DATE_CODE_TYPE_ID) as "DIC_CODE_TYPE",
          rep_utils.DateToReplicatorDate(FCO_DAT_CODE) as "VALUE"
        ) as "DATE_CODE"
      )) as "DATE_CODES"
    ) into lx_data
  from ASA_FREE_CODE
  where ASA_RECORD_ID = in_record_id and
    DIC_ASA_DATE_CODE_TYPE_ID is not null;
  return lx_data;

  exception
    when NO_DATA_FOUND then
      return null;
end;

function get_free_codes_char(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLForest(
      XMLAgg(XMLForest(
        XMLForest(
          asa_lib_record_trf_xml.get_dictionary_def('DIC_ASA_CHAR_CODE_TYPE',DIC_ASA_CHAR_CODE_TYPE_ID) as "DIC_CODE_TYPE",
          FCO_CHA_CODE as "VALUE"
        ) as "CHAR_CODE"
      )) as "CHAR_CODES"
    ) into lx_data
  from ASA_FREE_CODE
  where ASA_RECORD_ID = in_record_id and
    DIC_ASA_CHAR_CODE_TYPE_ID is not null;
  return lx_data;

  exception
    when NO_DATA_FOUND then
      return null;
end;

function get_free_codes(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLForest(
      XMLConcat(
        asa_lib_record_trf_xml.get_free_codes_boolean(in_record_id),
        asa_lib_record_trf_xml.get_free_codes_number(in_record_id),
        asa_lib_record_trf_xml.get_free_codes_memo(in_record_id),
        asa_lib_record_trf_xml.get_free_codes_date(in_record_id),
        asa_lib_record_trf_xml.get_free_codes_char(in_record_id)
      ) as "FREE_CODES"
    ) into lx_data
  from DUAL;
  return lx_data;
end;

function get_free_data(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLForest(
      XMLConcat(
        XMLForest(
          XMLForest(
            ARD_ALPHA_SHORT_1 as "ARD_ALPHA_SHORT",
            ARD_ALPHA_LONG_1 as "ARD_ALPHA_LONG",
            ARD_INTEGER_1 as "ARD_INTEGER",
            ARD_DECIMAL_1 as "ARD_DECIMAL",
            ARD_BOOLEAN_1 as "ARD_BOOLEAN",
            asa_lib_record_trf_xml.get_dictionary_def('DIC_ASA_REC_FREE1',DIC_ASA_REC_FREE1_ID) as "DIC_ASA_REC_FREE"
          ) as "FREE_DATA_01"
        ),
        XMLForest(
          XMLForest(
            ARD_ALPHA_SHORT_2 as "ARD_ALPHA_SHORT",
            ARD_ALPHA_LONG_2 as "ARD_ALPHA_LONG",
            ARD_INTEGER_2 as "ARD_INTEGER",
            ARD_DECIMAL_2 as "ARD_DECIMAL",
            ARD_BOOLEAN_2 as "ARD_BOOLEAN",
            asa_lib_record_trf_xml.get_dictionary_def('DIC_ASA_REC_FREE2',DIC_ASA_REC_FREE2_ID) as "DIC_ASA_REC_FREE"
          ) as "FREE_DATA_02"
        ),
        XMLForest(
          XMLForest(
            ARD_ALPHA_SHORT_3 as "ARD_ALPHA_SHORT",
            ARD_ALPHA_LONG_3 as "ARD_ALPHA_LONG",
            ARD_INTEGER_3 as "ARD_INTEGER",
            ARD_DECIMAL_3 as "ARD_DECIMAL",
            ARD_BOOLEAN_3 as "ARD_BOOLEAN",
            asa_lib_record_trf_xml.get_dictionary_def('DIC_ASA_REC_FREE3',DIC_ASA_REC_FREE3_ID) as "DIC_ASA_REC_FREE"
          ) as "FREE_DATA_03"
        ),
        XMLForest(
          XMLForest(
            ARD_ALPHA_SHORT_4 as "ARD_ALPHA_SHORT",
            ARD_ALPHA_LONG_4 as "ARD_ALPHA_LONG",
            ARD_INTEGER_4 as "ARD_INTEGER",
            ARD_DECIMAL_4 as "ARD_DECIMAL",
            ARD_BOOLEAN_4 as "ARD_BOOLEAN",
            asa_lib_record_trf_xml.get_dictionary_def('DIC_ASA_REC_FREE4',DIC_ASA_REC_FREE4_ID) as "DIC_ASA_REC_FREE"
          ) as "FREE_DATA_04"
        ),
        XMLForest(
          XMLForest(
            ARD_ALPHA_SHORT_5 as "ARD_ALPHA_SHORT",
            ARD_ALPHA_LONG_5 as "ARD_ALPHA_LONG",
            ARD_INTEGER_5 as "ARD_INTEGER",
            ARD_DECIMAL_5 as "ARD_DECIMAL",
            ARD_BOOLEAN_5 as "ARD_BOOLEAN",
            asa_lib_record_trf_xml.get_dictionary_def('DIC_ASA_REC_FREE5',DIC_ASA_REC_FREE5_ID) as "DIC_ASA_REC_FREE"
          ) as "FREE_DATA_05"
        )
      ) as FREE_DATA
    ) into lx_data
  from ASA_FREE_DATA
  where ASA_RECORD_ID = in_record_id;
  return lx_data;

  exception
    when NO_DATA_FOUND then
      return null;
end;


function get_dictionary(
  iv_dictionary IN dico_description.dit_table%TYPE,
  iv_code IN dico_description.dit_code%TYPE,
  in_complete IN INTEGER default 1,
  iv_dictionary_ref IN dico_description.dit_table%TYPE default null)
  return XMLType
is
  lx_data XMLType;
begin
  -- sortie anticipée si le nom ou la valeur du dictionnaire est nul
  if (iv_dictionary is null or iv_code is null) then
    return null;
  end if;

  select
    XMLElement(EVALNAME iv_dictionary,
      asa_lib_record_trf_xml.get_dictionary_def(Nvl(iv_dictionary_ref,iv_dictionary), iv_code, in_complete)
    ) into lx_data
  from DUAL;

  return lx_data;
end;

function get_dictionary_def(
  iv_dictionary IN dico_description.dit_table%TYPE,
  iv_code IN dico_description.dit_code%TYPE,
  in_complete IN INTEGER default 1)
  return XMLType
is
  lx_data XMLType;
begin
  -- sortie anticipée si le nom ou la valeur du dictionnaire est nul
  if (iv_dictionary is null or iv_code is null) then
    return null;
  end if;

  select
    XMLConcat(
      XMLElement("VALUE", iv_code),
      case when (in_complete >= 1) then
        XMLConcat(
          asa_lib_record_trf_xml.get_dictionary_field(iv_dictionary, iv_code),
          asa_lib_record_trf_xml.get_dictionary_descr(iv_dictionary, iv_code)
        )
      end
    ) into lx_data
  from DUAL;

  return lx_data;
end;

function get_dictionary_field(
  iv_dictionary IN dico_description.dit_table%TYPE,
  iv_code IN dico_description.dit_code%TYPE)
  return XMLType
is
  lv_cmd VARCHAR2(32767);
  lx_data XMLType;
begin
  for tpl in (
    select
      'case when '||COLUMN_NAME||' is not null then'||
         ' XMLElement("ADDITIONAL_FIELD",'||
           'XMLAttributes('''|| COLUMN_NAME ||''' as "NAME"),'||
           COLUMN_NAME||
         ')'||
       ' end' CMD
    from (
      select
        COLUMN_NAME,
        case when Substr(COLUMN_NAME,1,2) != 'A_' then 0 else 1 end IS_AFIELD,
        iv_dictionary||'_ID' PK_FIELD
      from USER_TAB_COLUMNS
      where TABLE_NAME = iv_dictionary)
    where IS_AFIELD = 0 and COLUMN_NAME <> PK_FIELD
  ) loop
    lv_cmd := lv_cmd ||','|| tpl.CMD;
  end loop;

  if (lv_cmd is null) then
    return null;
  end if;

  execute immediate
    'select XMLConcat('|| LTrim(lv_cmd,',') ||')'||
    ' from '||iv_dictionary||
    ' where '||iv_dictionary||'_ID = :1'
    into lx_data
    using in iv_code;

  if (lx_data is not null) then
    select XMLElement("ADDITIONAL_FIELDS", lx_data)
    into lx_data
    from DUAL;
    return lx_data;
  end if;
  return null;

  exception
    when NO_DATA_FOUND then
      return null;
end;

function get_dictionary_descr(
  iv_dictionary IN dico_description.dit_table%TYPE,
  iv_code IN dico_description.dit_code%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  select
    XMLAgg(XMLElement("DESCRIPTION",
      XMLAttributes(L.LANID as "LANID"),
      D.DIT_DESCR
    )) into lx_data
  from
    PCS.PC_LANG L, DICO_DESCRIPTION D
  where
    D.DIT_TABLE = iv_dictionary and D.DIT_CODE = iv_code and
    L.PC_LANG_ID = D.PC_LANG_ID;

  if (lx_data is not null) then
    select XMLElement("DESCRIPTIONS", lx_data)
    into lx_data
    from DUAL;
    return lx_data;
  end if;
  return null;

  exception
    when NO_DATA_FOUND then
      return null;
end;

function get_pc_appltxt_link(
  in_appltxt_id IN pcs.pc_appltxt.pc_appltxt_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (in_appltxt_id in (null,0)) then
    return null;
  end if;

  select
    XMLElement("PC_APPLTXT",
      asa_lib_record_trf_xml.get_dictionary('DIC_PC_THEME',DIC_PC_THEME_ID,0),
      XMLForest(
        C_TEXT_TYPE,
        APH_CODE
      )
    ) into lx_data
  from PCS.PC_APPLTXT
  where PC_APPLTXT_ID = in_appltxt_id;
  return lx_data;

  exception
    when NO_DATA_FOUND then
      return null;
end;

function get_pac_person_link(
  in_person_id IN pac_person.pac_person_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (in_person_id in (null,0)) then
    return null;
  end if;

  select
    XMLElement("PER_KEY",
      XMLForest(
        PER_KEY1,
        PER_KEY2
      )
    ) into lx_data
  from PAC_PERSON
  where PAC_PERSON_ID = in_person_id;
  return lx_data;

  exception
    when NO_DATA_FOUND then
      return null;
end;

function get_pac_address_link(
  in_address_id IN pac_address.pac_address_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (in_address_id in (null,0)) then
    return null;
  end if;

  select
    XMLElement("ADDRESS",
      asa_lib_record_trf_xml.get_dictionary('DIC_ADDRESS_TYPE',DIC_ADDRESS_TYPE_ID,0),
      XMLForest(
        PER_KEY1,
        PER_KEY2
      )
    ) into lx_data
  from PAC_ADDRESS A, PAC_PERSON P
  where A.PAC_ADDRESS_ID = in_address_id
    and P.PAC_PERSON_ID = A.PAC_PERSON_ID;
  return lx_data;

  exception
    when NO_DATA_FOUND then
      return null;
end;

function get_doc_record_link(
  in_record_id IN doc_record.doc_record_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (in_record_id in (null,0)) then
    return null;
  end if;

  select
    XMLElement("DOC_RECORD",
      XMLForest(
        RCO_TITLE,
        RCO_NUMBER
      )
    ) into lx_data
  from DOC_RECORD
  where DOC_RECORD_ID = in_record_id;
  return lx_data;

  exception
    when NO_DATA_FOUND then
      return null;
end;

function get_asa_rep_type_link(
  in_rep_type_id IN asa_rep_type.asa_rep_type_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (in_rep_type_id in (null,0)) then
    return null;
  end if;

  select XMLElement("RET_REP_TYPE", RET_REP_TYPE)
  into lx_data
  from ASA_REP_TYPE
  where ASA_REP_TYPE_ID = in_rep_type_id;
  return lx_data;

  exception
    when NO_DATA_FOUND then
      return null;
end;

function get_doc_gauge_link(
  in_gauge_id IN doc_gauge.doc_gauge_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (in_gauge_id in (null,0)) then
    return null;
  end if;

  select
    XMLElement("DOC_GAUGE",
      XMLForest(
        C_ADMIN_DOMAIN,
        C_GAUGE_TYPE,
        GAU_DESCRIBE
      )
    ) into lx_data
  from DOC_GAUGE
  where DOC_GAUGE_ID = in_gauge_id;
  return lx_data;

  exception
    when NO_DATA_FOUND then
      return null;
end;

function get_pac_representative_link(
  in_representative_id in pac_representative.pac_representative_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (in_representative_id in (null,0)) then
    return null;
  end if;

  select XMLElement("REP_DESCR", REP_DESCR)
  into lx_data
  from PAC_REPRESENTATIVE
  where PAC_REPRESENTATIVE_ID = in_representative_id;
  return lx_data;

  exception
    when NO_DATA_FOUND then
      return null;
end;

function get_financial_currency_link(
  in_financial_currency_id in acs_financial_currency.acs_financial_currency_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (in_financial_currency_id in (null,0)) then
    return null;
  end if;

  select XMLElement("CURRENCY", currency)
  into lx_data
  from PCS.PC_CURR C, ACS_FINANCIAL_CURRENCY FC
  where ACS_FINANCIAL_CURRENCY_ID = in_financial_currency_id and C.PC_CURR_ID = FC.PC_CURR_ID;
  return lx_data;

  exception
    when NO_DATA_FOUND then
      return null;
end;


function get_com_virtual_fields(
  in_id IN NUMBER,
  iv_table_name IN com_vfields_record.vfi_tabname%TYPE)
  return XMLType
is
  cursor csFields(
    iv_table_name IN VARCHAR2)
  is
    select
      case
        when FIELDS.IS_DATE = 1 then
          'rep_utils.DateToReplicatorDate('||FIELDS.COLUMN_NAME||') as '||FIELDS.COLUMN_NAME
        else
          FIELDS.COLUMN_NAME
      end COLUMN_NAME
    from
      -- Liste des champs virtuels pcs avec liaison sur un descode ou
      -- un descode customer
     (select V.FLDNAME VFIELD
      from PCS.PC_FLDSC V, PCS.PC_FLDSC F
      where
        F.PC_TABLE_ID = (select PC_TABLE_ID from PCS.PC_TABLE where TABNAME = iv_table_name) and
        F.FLDVIRTUALFIELD = 1 and (F.FLDCODE is not null or F.FLDCCODE is not null) and
        V.PC_FLDSC_ID = F.PC_VFIELD_VALUE_ID
      ) VFIELDS,
      -- Liste des champs de la table
     (select
        COLUMN_NAME,
        case when Substr(COLUMN_NAME,1,2) != 'A_' then 0 else 1 end IS_AFIELD,
        case when DATA_TYPE != 'DATE' then 0 else 1 end is_date
      from SYS.USER_TAB_COLUMNS
      where TABLE_NAME = 'COM_VFIELDS_RECORD') FIELDS
    where FIELDS.IS_AFIELD = 0 and FIELDS.COLUMN_NAME != 'VFI_REC_ID' and
      VFIELDS.VFIELD(+) = FIELDS.COLUMN_NAME;
  lx_data XMLType;
  lv_cmd VARCHAR2(32767);
begin
  for tplFields in csFields(iv_table_name) loop
    lv_cmd := lv_cmd ||','|| tplFields.column_name;
  end loop;

  -- Exécution dynamique de la commande pour la liste des champs
  execute immediate
    'select XMLForest('|| LTrim(lv_cmd,',') ||')'||
    ' from COM_VFIELDS_RECORD'||
    ' where VFI_REC_ID = :1 and VFI_TABNAME = :2'
    into lx_data
    using in in_id, -- :1
          in iv_table_name; -- :2

  -- Génération du fragment complet
  if (lx_data is not null) then
    select XMLElement("VIRTUAL_FIELDS", lx_data)
    into lx_data
    from DUAL;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then
      return null;
end;

END ASA_LIB_RECORD_TRF_XML;
