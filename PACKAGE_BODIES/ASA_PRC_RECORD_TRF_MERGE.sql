--------------------------------------------------------
--  DDL for Package Body ASA_PRC_RECORD_TRF_MERGE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_PRC_RECORD_TRF_MERGE" 
/**
 * Intégration de dossiers SAV transférés.
 *
 * @version 1.0
 * @date 05/2012
 * @author spfister
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
AS

  /** Collection de valeurs d'un dictionnaire. */
  TYPE tt_dictionary IS TABLE OF asa_typ_record_trf_def.T_DICTIONARY INDEX BY dico_description.dit_descr%TYPE;

  -- Nulls constants
  NULL_NUM CONSTANT NUMBER := 0;
  NULL_VA CONSTANT VARCHAR2(1) := '@';
  NULL_DATE CONSTANT DATE := to_date('01019999','DDMMYYYY');


--
-- internal methods
--

function to_string(
  itt_rowid IN asa_typ_record_trf_def.TT_ROWID)
  return VARCHAR2
is
  lv_result VARCHAR2(32767);
begin
  for cpt in itt_rowid.FIRST .. itt_rowid.LAST loop
    lv_result := lv_result ||','''|| itt_rowid(cpt) ||'''';
  end loop;
  return LTrim(lv_result,',');
end;

--function columns_value(
--  it_crud_def IN fwk_i_typ_definition.T_CRUD_DEF)
--  return VARCHAR2
--is
--  lv_result VARCHAR2(32767);
--  column fwk_i_typ_definition.T_COLUMN_DEF;
--begin
--  for cpt in it_crud_def.column_list.FIRST .. it_crud_def.column_list.LAST loop
--    column := it_crud_def.column_list(cpt);
--    lv_result := lv_result ||','||
--      fwk_i_lib_utils.to_string(column)||'='||
--      fwk_i_mgt_entity_data.GetColumnVarchar2(it_crud_def,column.name);
--  end loop;
--  return '['|| LTrim(lv_result,',') ||']';
--end;


function p_row_exists(
  it_ctx IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  it_crud_def IN fwk_i_typ_definition.T_CRUD_DEF,
  iv_where_clause IN VARCHAR2 default null)
  return ROWID
is
  lv_cmd VARCHAR2(32767);
  lv_result ROWID;
begin
  lv_cmd :=
    'select rowid'||
    ' from '||it_crud_def.entity_def.name||
    ' where ASA_RECORD_ID=:1'||
        NullIf(' and '||iv_where_clause,' and ');
  --dbms_output.put_line(lv_cmd);
  execute immediate
    lv_cmd
    into lv_result
    using in it_ctx.record_id;

  return lv_result;

  exception
    when NO_DATA_FOUND then
      return null;
end;


--
-- Internal dictionary methods
--

/**
 * Vérification de l'existance d'un code d'une doctionnaire.
 * @param iv_dictionary  Nom du dictionnaire.
 * @param iv_code  Code du dictionnaire.
 * @return TRUE si le code existe, sinon FALSE.
 */
function p_dic_exists(
  iv_dictionary IN VARCHAR2,
  iv_code IN VARCHAR2)
  return BOOLEAN
is
  ln_result INTEGER;
begin
  execute immediate
    'select Count(*) from DUAL'||
    ' where Exists(select 1 from '||iv_dictionary||
                 ' where '||iv_dictionary||'_ID = :1)'
    into ln_result
    using in iv_code;

  return ln_result = 1;
end;

/**
 * Insertion du code d'un dictionnaire.
 * @param iv_name  Nom du dictionnaire.
 * @param it_dictionary  Type record du dictionnaire.
 */
procedure p_insert_dic_code(
  iv_name IN VARCHAR2,
  it_dictionary IN asa_typ_record_trf_def.T_DICTIONARY)
is
  lv_fields VARCHAR2(32767);
  lv_params VARCHAR2(32767);
  lt_field asa_typ_record_trf_def.T_DICTIONARY_FIELD;
begin
  for cpt in it_dictionary.additional_fields.FIRST .. it_dictionary.additional_fields.LAST loop
    lt_field := it_dictionary.additional_fields(cpt);
    lv_fields := lv_fields || lt_field.name ||',';
    lv_params := lv_params ||''''|| lt_field.value ||''',';
  end loop;

  execute immediate
    'insert into '||iv_name||
    '('||iv_name||'_ID, '|| lv_fields ||'A_DATECRE, A_IDCRE)'||
    'values'||
    '(:1, '|| lv_params ||'Sysdate, pcs.PC_I_LIB_SESSION.GetUserIni)'
    using in it_dictionary.value;
end;

/**
 * Mise à jour des champs supplémentaires d'un dictionnaire.
 * @param iv_name  Nom du dictionnaire.
 * @param it_dictionary  Type record du dictionnaire.
 */
procedure p_update_dic_values(
  iv_name IN VARCHAR2,
  it_dictionary IN asa_typ_record_trf_def.T_DICTIONARY)
is
  lv_fields VARCHAR2(32767);
  lt_field asa_typ_record_trf_def.T_DICTIONARY_FIELD;
begin
  if (it_dictionary.additional_fields.COUNT = 0) then
    -- sorite anticipée, car aucun champs supplémentaires à mettre à jour
    return;
  end if;

  for cpt in it_dictionary.additional_fields.FIRST .. it_dictionary.additional_fields.LAST loop
    lt_field := it_dictionary.additional_fields(cpt);
    lv_fields := lv_fields ||
      lt_field.name ||'='''|| lt_field.value ||''',';
  end loop;

  execute immediate
    'update '||iv_name||
    ' set '|| lv_fields ||
          'A_DATECRE=Sysdate,'||
          'A_IDCRE=pcs.PC_I_LIB_SESSION.GetUserIni'||
    ' where '||iv_name||'_ID = :1'
    using in it_dictionary.value;
end;

/**
 * Mise à jour des descriptions d'un dictionnaire.
 * @param iv_name  Nom du dictionnaire.
 * @param it_dictionary  Type record du dictionnaire.
 */
procedure p_merge_dic_descriptions(
  iv_name IN VARCHAR2,
  it_dictionary IN asa_typ_record_trf_def.T_DICTIONARY)
is
  lv_cmd VARCHAR2(32767);
begin
  if (it_dictionary.descriptions.COUNT = 0) then
    -- sortie anticipée car aucune description à mettre à jour
    return;
  end if;

  lv_cmd :=
    'merge into DICO_DESCRIPTION D'||Chr(10)||
    'using (select :1 AS DIT_TABLE, :2 AS DIT_CODE, pc_lang_id,'||
                  ':3 AS DIT_DESCR,'||
                  'Sysdate AS NOW, pcs.PC_I_LIB_SESSION.GetUserIni AS USERINI'||
           ' from PCS.PC_LANG'||
           ' where LANID = :4) S'||Chr(10)||
    'on (D.DIT_TABLE = S.DIT_TABLE and D.DIT_CODE = S.DIT_CODE and D.PC_LANG_ID = S.PC_LANG_ID)'||Chr(10)||
    'when matched then'||
      ' update set D.DIT_DESCR = Nvl(S.DIT_DESCR, S.DIT_CODE),'||
                  'D.A_DATEMOD = S.NOW, D.A_IDMOD = S.USERINI'||
      ' where ((D.DIT_DESCR != S.DIT_DESCR and S.DIT_DESCR is not null) or D.DIT_DESCR is null)'||Chr(10)||
    'when not matched then'||
      ' insert (D.DIT_TABLE, D.DIT_CODE, D.PC_LANG_ID,'||
               'D.DIT_DESCR,'||
               'D.A_DATECRE, D.A_IDCRE)'||
      ' values (S.DIT_TABLE, S.DIT_CODE, S.PC_LANG_ID,'||
               'Nvl(S.DIT_DESCR, S.DIT_CODE),'||
               'S.NOW, S.USERINI)';
  for cpt in it_dictionary.descriptions.FIRST .. it_dictionary.descriptions.LAST loop
    execute immediate
      lv_cmd
      using in iv_name,
            in it_dictionary.value,
            in it_dictionary.descriptions(cpt).value,
            in it_dictionary.descriptions(cpt).pc_lang.lanid;
  end loop;
end;


--
-- Internal entity initialization
--

function p_init_merge(
  it_ctx IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  iv_where_clause IN VARCHAR2 default null)
  return fwk_i_typ_definition.UPDATE_MODE
is
  lv_rowid ROWID;
  lt_result fwk_i_typ_definition.UPDATE_MODE := fwk_i_typ_definition.UPDATE_NONE;
begin
  lv_rowid := p_row_exists(it_ctx, iot_crud_def, iv_where_clause);
  if (lv_rowid is not null) then
    lt_result := fwk_i_typ_definition.UPDATING;
    fwk_i_mgt_entity.Load(iot_crud_def, lv_rowid);
    iot_crud_def.row_id := lv_rowid;
  else
    lt_result := fwk_i_typ_definition.INSERTING;
    fwk_i_mgt_entity.Init(iot_crud_def, TRUE);
    fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ASA_RECORD_ID', it_ctx.record_id);
  end if;
  return lt_result;
end;


function p_init_merge_description(
  it_ctx IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_description IN asa_typ_record_trf_def.T_DESCRIPTION,
  iv_description_type IN VARCHAR2)
  return fwk_i_typ_definition.UPDATE_MODE
is
  lt_result fwk_i_typ_definition.UPDATE_MODE := fwk_i_typ_definition.UPDATE_NONE;
begin
  lt_result := p_init_merge(it_ctx, iot_crud_def,
    'C_ASA_DESCRIPTION_TYPE='''||iv_description_type||''''||
    ' and PC_LANG_ID='||it_description.pc_lang.pc_lang_id
  );
  if (lt_result = fwk_i_typ_definition.INSERTING) then
    fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'C_ASA_DESCRIPTION_TYPE', iv_description_type);
  end if;
  return lt_result;
end;

function p_init_merge_diagnostic(
  it_ctx IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_diagnostic IN asa_typ_record_trf_def.T_DIAGNOSTIC)
  return fwk_i_typ_definition.UPDATE_MODE
is
begin
  return p_init_merge(it_ctx, iot_crud_def,
    'DIC_DIAGNOSTICS_TYPE_ID='''||it_diagnostic.dic_diagnostics_type.value||''''||
    ' and DIA_SEQUENCE='||it_diagnostic.dia_sequence||
    ' and C_ASA_CONTEXT='''||it_diagnostic.c_asa_context||''''
  );
end;

function p_init_merge_document_text(
  it_ctx IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_document_text IN asa_typ_record_trf_def.T_DOCUMENT_TEXT)
  return fwk_i_typ_definition.UPDATE_MODE
is
begin
  return p_init_merge(it_ctx, iot_crud_def,
    'C_ASA_TEXT_TYPE='''||it_document_text.c_asa_text_type||''''||
    ' and C_ASA_GAUGE_TYPE='''||it_document_text.c_asa_gauge_type||''''
  );
end;
function p_init_merge_free_code_bool(
  it_ctx IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_free_code IN asa_typ_record_trf_def.T_BOOLEAN_CODE)
  return fwk_i_typ_definition.UPDATE_MODE
is
begin
  return p_init_merge(it_ctx, iot_crud_def,
    'DIC_ASA_BOOLEAN_CODE_TYPE_ID='''||it_free_code.dic_asa_boolean_code_type.value||''''||
    ' and FCO_BOO_CODE='||it_free_code.fco_boo_code
  );
end;
function p_init_merge_free_code_number(
  it_ctx IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_free_code IN asa_typ_record_trf_def.T_NUMBER_CODE)
  return fwk_i_typ_definition.UPDATE_MODE
is
begin
  return p_init_merge(it_ctx, iot_crud_def,
    'DIC_ASA_NUMBER_CODE_TYPE_ID='''||it_free_code.dic_asa_number_code_type.value||''''||
    ' and FCO_NUM_CODE='||it_free_code.fco_num_code
  );
end;
function p_init_merge_free_code_memo(
  it_ctx IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_free_code IN asa_typ_record_trf_def.T_MEMO_CODE)
  return fwk_i_typ_definition.UPDATE_MODE
is
begin
  return p_init_merge(it_ctx, iot_crud_def,
    'DIC_ASA_MEMO_CODE_TYPE_ID='''||it_free_code.dic_asa_memo_code_type.value||''''||
    ' and FCO_MEM_CODE='''||it_free_code.fco_mem_code||''''
  );
end;
function p_init_merge_free_code_date(
  it_ctx IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_free_code IN asa_typ_record_trf_def.T_DATE_CODE)
  return fwk_i_typ_definition.UPDATE_MODE
is
begin
  return p_init_merge(it_ctx, iot_crud_def,
    'DIC_ASA_DATE_CODE_TYPE_ID='''||it_free_code.dic_asa_date_code_type.value||''''||
    ' and FCO_DAT_CODE=rep_utils.ReplicatorDateToDate('''||rep_utils.DateToReplicatorDate(it_free_code.fco_dat_code)||''')'
  );
end;
function p_init_merge_free_code_char(
  it_ctx IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_free_code IN asa_typ_record_trf_def.T_CHAR_CODE)
  return fwk_i_typ_definition.UPDATE_MODE
is
begin
  return p_init_merge(it_ctx, iot_crud_def,
    'DIC_ASA_CHAR_CODE_TYPE_ID='''||it_free_code.dic_asa_char_code_type.value||''''||
    ' and FCO_CHA_CODE='''||it_free_code.fco_cha_code||''''
  );
end;

function p_init_merge_vfields(
  in_id IN NUMBER,
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  iv_table_name IN VARCHAR2)
  return fwk_i_typ_definition.UPDATE_MODE
is
  lv_rowid ROWID;
  lt_result fwk_i_typ_definition.UPDATE_MODE := fwk_i_typ_definition.UPDATE_NONE;
begin
  begin
    select rowid
    into lv_rowid
    from COM_VFIELDS_RECORD
    where VFI_TABNAME = iv_table_name and VFI_REC_ID = in_id;

    exception
      when NO_DATA_FOUND then
        null;
  end;
  if (lv_rowid is not null) then
    lt_result := fwk_i_typ_definition.UPDATING;
    fwk_i_mgt_entity.Load(iot_crud_def, lv_rowid);
    iot_crud_def.row_id := lv_rowid;
  else
    lt_result := fwk_i_typ_definition.INSERTING;
    fwk_i_mgt_entity.Init(iot_crud_def, TRUE);
    fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'VFI_TABNAME', iv_table_name);
    fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'VFI_REC_ID', in_id);
  end if;
  return lt_result;
end;

function p_init_merge_component(
  it_ctx IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_component IN asa_typ_record_trf_def.T_COMPONENT)
  return fwk_i_typ_definition.UPDATE_MODE
is
  lt_result fwk_i_typ_definition.UPDATE_MODE := fwk_i_typ_definition.UPDATE_NONE;
begin
  lt_result := p_init_merge(it_ctx, iot_crud_def,
    'ASA_RECORD_EVENTS_ID='||it_ctx.record_events_id||
    ' and ARC_POSITION='||it_component.arc_position
  );
  if (lt_result = fwk_i_typ_definition.INSERTING) then
    fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ASA_RECORD_EVENTS_ID', it_ctx.record_events_id);
  end if;
  return lt_result;
end;

function p_init_merge_operation(
  it_ctx IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_operation IN asa_typ_record_trf_def.T_OPERATION)
  return fwk_i_typ_definition.UPDATE_MODE
is
  lt_result fwk_i_typ_definition.UPDATE_MODE := fwk_i_typ_definition.UPDATE_NONE;
begin
  lt_result := p_init_merge(it_ctx, iot_crud_def,
    'ASA_RECORD_EVENTS_ID='||it_ctx.record_events_id||
    ' and RET_POSITION='||it_operation.ret_position
  );
  if (lt_result = fwk_i_typ_definition.INSERTING) then
    fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ASA_RECORD_EVENTS_ID', it_ctx.record_events_id);
  end if;
  return lt_result;
end;


--
-- internal entity values loading
--

procedure p_load_header_data(
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_header_data IN asa_typ_record_trf_def.T_HEADER_DATA,
  it_msg_type IN asa_typ_record_trf_def.T_ASA_TRF_MSG_TYPE)
is
begin
  if (it_msg_type in (asa_typ_record_trf_def.TRF_MSG_TYPE_SEND,
                      asa_typ_record_trf_def.TRF_MSG_TYPE_SEND_LOOP)) then
    fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_SRC_INSTANCE_NAME', it_header_data.source_company.instance_name,
      Nvl(it_header_data.source_company.instance_name,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def,'ARE_SRC_INSTANCE_NAME'),NULL_VA));
    fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_SRC_SCHEMA_NAME', it_header_data.source_company.schema_name,
      Nvl(it_header_data.source_company.schema_name,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_SRC_SCHEMA_NAME'),NULL_VA));
    fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_SRC_COM_NAME', it_header_data.source_company.company_name,
      Nvl(it_header_data.source_company.company_name,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_SRC_COM_NAME'),NULL_VA));

    fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_SRC_NUMBER', it_header_data.are_number,
      Nvl(it_header_data.are_number,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_SRC_NUMBER'),NULL_VA));
  end if;
  --fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_NUMBER', it_header_data.are_number,
  --  Nvl(it_header_data.are_number,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_NUMBER'),NULL_VA));
  --fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_SRC_NUMBER', it_header_data.are_src_number,
  --  Nvl(it_header_data.are_src_number,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_SRC_NUMBER'),NULL_VA));

  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ASA_REP_TYPE_ID', it_header_data.asa_rep_type.asa_rep_type_id,
    Nvl(it_header_data.asa_rep_type.asa_rep_type_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ASA_REP_TYPE_ID'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'DOC_GAUGE_ID', it_header_data.doc_gauge.doc_gauge_id,
    Nvl(it_header_data.doc_gauge.doc_gauge_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'DOC_GAUGE_ID'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'C_ASA_REP_TYPE_KIND', it_header_data.c_asa_rep_type_kind,
    Nvl(it_header_data.c_asa_rep_type_kind,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'C_ASA_REP_TYPE_KIND'),NULL_VA));
  --fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'C_ASA_REP_STATUS', it_header_data.c_asa_rep_status,
  --  Nvl(it_header_data.c_asa_rep_status,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'C_ASA_REP_STATUS'),NULL_VA));
  --fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_DATECRE', it_header_data.are_datecre,
  --  Nvl(it_header_data.are_datecre,NULL_DATE) != Nvl(fwk_i_mgt_entity_data.GetColumnDate(iot_crud_def, 'ARE_DATECRE'),NULL_DATE));
  --fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_UPDATE_STATUS', it_header_data.are_update_status,
  --  Nvl(it_header_data.are_update_status,NULL_DATE) != Nvl(fwk_i_mgt_entity_data.GetColumnDate(iot_crud_def, 'ARE_UPDATE_STATUS'),NULL_DATE));
  --fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_PRINT_STATUS', it_header_data.are_print_status,
  --  Nvl(it_header_data.are_print_status,NULL_DATE) != Nvl(fwk_i_mgt_entity_data.GetColumnDate(iot_crud_def, 'ARE_PRINT_STATUS'),NULL_DATE));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_INTERNAL_REMARK', it_header_data.are_internal_remark,
    Nvl(it_header_data.are_internal_remark,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_INTERNAL_REMARK'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_REQ_DATE_TEXT', it_header_data.are_req_date_text,
    Nvl(it_header_data.are_req_date_text,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_REQ_DATE_TEXT'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_CUSTOMER_REMARK', it_header_data.are_customer_remark,
    Nvl(it_header_data.are_customer_remark,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_CUSTOMER_REMARK'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_ADDITIONAL_ITEMS', it_header_data.are_additional_items,
    Nvl(it_header_data.are_additional_items,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_ADDITIONAL_ITEMS'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_CUSTOMS_VALUE', it_header_data.are_customs_value,
    Nvl(it_header_data.are_customs_value,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_CUSTOMS_VALUE'),NULL_NUM));
  if (it_header_data.doc_record.doc_record_id != 0.0) then
    fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'DOC_RECORD_ID', it_header_data.doc_record.doc_record_id,
      Nvl(it_header_data.doc_record.doc_record_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'DOC_RECORD_ID'),NULL_NUM));
  end if;
  if (it_header_data.pac_representative.pac_representative_id != 0.0) then
    fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'PAC_REPRESENTATIVE_ID', it_header_data.pac_representative.pac_representative_id,
      Nvl(it_header_data.pac_representative.pac_representative_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'PAC_REPRESENTATIVE_ID'),NULL_NUM));
  end if;
  if (it_header_data.acs_custom_fin_curr.acs_financial_currency_id != 0.0) then
    fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ACS_CUSTOM_FIN_CURR_ID', it_header_data.acs_custom_fin_curr.acs_financial_currency_id,
      Nvl(it_header_data.acs_custom_fin_curr.acs_financial_currency_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ACS_CUSTOM_FIN_CURR_ID'),NULL_NUM));
  end if;
end;

procedure p_load_header_address(
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_address IN asa_typ_record_trf_def.T_ADDRESS,
  iv_num IN VARCHAR2)
is
  lv_field fwk_i_typ_definition.DEF_NAME;
begin
  lv_field := 'ARE_ADDRESS'||iv_num;
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_address.are_address,
    Nvl(it_address.are_address,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, lv_field),NULL_VA));
  lv_field := 'ARE_CARE_OF'||iv_num;
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_address.are_care_of,
    Nvl(it_address.are_care_of,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, lv_field),NULL_VA));
  lv_field := 'ARE_CONTACT'||iv_num;
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_address.are_contact,
    Nvl(it_address.are_contact,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, lv_field),NULL_VA));
  lv_field := 'ARE_COUNTY'||iv_num;
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_address.are_county,
    Nvl(it_address.are_county,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, lv_field),NULL_VA));
  lv_field := 'ARE_FORMAT_CITY'||iv_num;
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_address.are_format_city,
    Nvl(it_address.are_format_city,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, lv_field),NULL_VA));
  lv_field := 'ARE_PO_BOX_NBR'||iv_num;
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_address.are_po_box_nbr,
    Nvl(it_address.are_po_box_nbr,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, lv_field),NULL_NUM));
  lv_field := 'ARE_PO_BOX'||iv_num;
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_address.are_po_box,
    Nvl(it_address.are_po_box,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, lv_field),NULL_VA));
  lv_field := 'ARE_POSTCODE'||iv_num;
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_address.are_postcode,
    Nvl(it_address.are_postcode,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, lv_field),NULL_VA));
  lv_field := 'ARE_STATE'||iv_num;
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_address.are_state,
    Nvl(it_address.are_state,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, lv_field),NULL_VA));
  lv_field := 'ARE_TOWN'||iv_num;
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_address.are_town,
    Nvl(it_address.are_town,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, lv_field),NULL_VA));
  lv_field := 'PAC_ASA_ADDR'||iv_num||'_ID';
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_address.pac_address.pac_address_id,
    Nvl(it_address.pac_address.pac_address_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, lv_field),NULL_NUM));
  lv_field := 'PC_ASA_CNTRY'||iv_num||'_ID';
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_address.pc_cntry.pc_cntry_id,
    Nvl(it_address.pc_cntry.pc_cntry_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, lv_field),NULL_NUM));
end;
--procedure p_load_header_address_agent(
--  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
--  it_address IN asa_typ_record_trf_def.T_ADDRESS_E)
--is
--begin
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_ADDRESS_AGENT', it_address.are_address,
--    Nvl(it_address.are_address,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_ADDRESS_AGENT'),NULL_VA));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_CARE_OF_AGENT', it_address.are_care_of,
--    Nvl(it_address.are_care_of,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_CARE_OF_AGENT'),NULL_VA));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_COUNTY_AGENT', it_address.are_county,
--    Nvl(it_address.are_county,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_COUNTY_AGENT'),NULL_VA));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_FORMAT_CITY_AGENT', it_address.are_format_city,
--    Nvl(it_address.are_format_city,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_FORMAT_CITY_AGENT'),NULL_VA));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_PO_BOX_AGENT', it_address.are_po_box,
--    Nvl(it_address.are_po_box,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_PO_BOX_AGENT'),NULL_VA));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_PO_BOX_NBR_AGENT', it_address.are_po_box_nbr,
--    Nvl(it_address.are_po_box_nbr,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_PO_BOX_NBR_AGENT'),NULL_NUM));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_POSTCODE_AGENT', it_address.are_postcode,
--    Nvl(it_address.are_postcode,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_POSTCODE_AGENT'),NULL_VA));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_STATE_AGENT', it_address.are_state,
--    Nvl(it_address.are_state,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_STATE_AGENT'),NULL_VA));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_TOWN_AGENT', it_address.are_town,
--    Nvl(it_address.are_town,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_TOWN_AGENT'),NULL_VA));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'PAC_ASA_AGENT_ADDR_ID', it_address.pac_address.pac_address_id,
--    Nvl(it_address.pac_address.pac_address_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'PAC_ASA_AGENT_ADDR_ID'),NULL_NUM));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'PC_ASA_AGENT_CNTRY_ID', it_address.pc_cntry.pc_cntry_id,
--    Nvl(it_address.pc_cntry.pc_cntry_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'PC_ASA_AGENT_CNTRY_ID'),NULL_NUM));
--  if (it_address.pc_lang.pc_lang_id != 0.0) then
--    fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'PC_ASA_AGENT_LANG_ID', it_address.pc_lang.pc_lang_id,
--      Nvl(it_address.pc_lang.pc_lang_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'PC_ASA_AGENT_LANG_ID'),NULL_NUM));
--  end if;
--end;
--procedure p_load_header_address_retailer(
--  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
--  it_address IN asa_typ_record_trf_def.T_ADDRESS_E)
--is
--begin
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_ADDRESS_DISTRIB', it_address.are_address,
--    Nvl(it_address.are_address,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_ADDRESS_DISTRIB'),NULL_VA));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_CARE_OF_DET', it_address.are_care_of,
--    Nvl(it_address.are_care_of,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_CARE_OF_DET'),NULL_VA));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_COUNTY_DET', it_address.are_county,
--    Nvl(it_address.are_county,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_COUNTY_DET'),NULL_VA));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_FORMAT_CITY_DISTRIB', it_address.are_format_city,
--    Nvl(it_address.are_format_city,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_FORMAT_CITY_DISTRIB'),NULL_VA));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_PO_BOX_DET', it_address.are_po_box,
--    Nvl(it_address.are_po_box,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_PO_BOX_DET'),NULL_VA));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_PO_BOX_NBR_DET', it_address.are_po_box_nbr,
--    Nvl(it_address.are_po_box_nbr,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_PO_BOX_NBR_DET'),NULL_NUM));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_POSTCODE_DISTRIB', it_address.are_postcode,
--    Nvl(it_address.are_postcode,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_POSTCODE_DISTRIB'),NULL_VA));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_STATE_DISTRIB', it_address.are_state,
--    Nvl(it_address.are_state,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_STATE_DISTRIB'),NULL_VA));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_TOWN_DISTRIB', it_address.are_town,
--    Nvl(it_address.are_town,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_TOWN_DISTRIB'),NULL_VA));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'PAC_ASA_DISTRIB_ADDR_ID', it_address.pac_address.pac_address_id,
--    Nvl(it_address.pac_address.pac_address_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'PAC_ASA_DISTRIB_ADDR_ID'),NULL_NUM));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'PC_ASA_DISTRIB_CNTRY_ID', it_address.pc_cntry.pc_cntry_id,
--    Nvl(it_address.pc_cntry.pc_cntry_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'PC_ASA_DISTRIB_CNTRY_ID'),NULL_NUM));
--  if (it_address.pc_lang.pc_lang_id != 0.0) then
--    fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'PC_ASA_DISTRIB_LANG_ID', it_address.pc_lang.pc_lang_id,
--      Nvl(it_address.pc_lang.pc_lang_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'PC_ASA_DISTRIB_LANG_ID'),NULL_NUM));
--  end if;
--end;
--procedure p_load_header_address_customer(
--  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
--  it_address IN asa_typ_record_trf_def.T_ADDRESS_E)
--is
--begin
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_ADDRESS_FIN_CUST', it_address.are_address,
--    Nvl(it_address.are_address,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_ADDRESS_FIN_CUST'),NULL_VA));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_CARE_OF_CUST', it_address.are_care_of,
--    Nvl(it_address.are_care_of,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_CARE_OF_CUST'),NULL_VA));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_COUNTY_CUST', it_address.are_county,
--    Nvl(it_address.are_county,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_COUNTY_CUST'),NULL_VA));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_FORMAT_CITY_FIN_CUST', it_address.are_format_city,
--    Nvl(it_address.are_format_city,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_FORMAT_CITY_FIN_CUST'),NULL_VA));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_PO_BOX_CUST', it_address.are_po_box,
--    Nvl(it_address.are_po_box,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_PO_BOX_CUST'),NULL_VA));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_PO_BOX_NBR_CUST', it_address.are_po_box_nbr,
--    Nvl(it_address.are_po_box_nbr,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_PO_BOX_NBR_CUST'),NULL_NUM));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_POSTCODE_FIN_CUST', it_address.are_postcode,
--    Nvl(it_address.are_postcode,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_POSTCODE_FIN_CUST'),NULL_VA));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_STATE_FIN_CUST', it_address.are_state,
--    Nvl(it_address.are_state,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_STATE_FIN_CUST'),NULL_VA));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_TOWN_FIN_CUST', it_address.are_town,
--    Nvl(it_address.are_town,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_TOWN_FIN_CUST'),NULL_VA));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'PAC_ASA_FIN_CUST_ADDR_ID', it_address.pac_address.pac_address_id,
--    Nvl(it_address.pac_address.pac_address_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'PAC_ASA_FIN_CUST_ADDR_ID'),NULL_NUM));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'PC_ASA_FIN_CUST_CNTRY_ID', it_address.pc_cntry.pc_cntry_id,
--    Nvl(it_address.pc_cntry.pc_cntry_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'PC_ASA_FIN_CUST_CNTRY_ID'),NULL_NUM));
--  if (it_address.pc_lang.pc_lang_id != 0.0) then
--    fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'PC_ASA_FIN_CUST_LANG_ID', it_address.pc_lang.pc_lang_id,
--      Nvl(it_address.pc_lang.pc_lang_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'PC_ASA_FIN_CUST_LANG_ID'),NULL_NUM));
--  end if;
--end;

procedure p_load_characterizations(
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  itt_characterizations IN asa_typ_record_trf_def.TT_PRODUCT_CHARACTERISTICS,
  iv_prefix_id IN VARCHAR2,
  iv_prefix_value IN VARCHAR2)
is
  lt_characteristic asa_typ_record_trf_def.T_PRODUCT_CHARACTERISTIC;
  ln_step INTEGER := 1;
  lv_field fwk_i_typ_definition.DEF_NAME;
begin
  if (itt_characterizations.COUNT = 0) then
    -- sortie anticipée car aucun caractérisation
    return;
  end if;

  for cpt in itt_characterizations.FIRST .. itt_characterizations.LAST loop
    lt_characteristic := itt_characterizations(cpt);
    -- champ identifiant de la caractérisation
    lv_field := iv_prefix_id||to_char(ln_step)||'_ID';
    fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, lt_characteristic.gco_characterization_id,
      Nvl(lt_characteristic.gco_characterization_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, lv_field),NULL_NUM));
    -- champs valeur de caractérisation
    lv_field := iv_prefix_value||to_char(ln_step)||'_VALUE';
    fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, lt_characteristic.value,
      Nvl(lt_characteristic.value,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, lv_field),NULL_VA));
    ln_step := ln_step + 1;
  end loop;
end;

procedure p_load_product_to_repair(
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_product_to_repair IN asa_typ_record_trf_def.T_PRODUCT_TO_REPAIR)
is
begin
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'GCO_ASA_TO_REPAIR_ID', it_product_to_repair.gco_good.gco_good_id,
    Nvl(it_product_to_repair.gco_good.gco_good_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'GCO_ASA_TO_REPAIR_ID'),NULL_NUM));

  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_GOOD_REF_1', it_product_to_repair.are_good_ref_1,
    Nvl(it_product_to_repair.are_good_ref_1,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_GOOD_REF_1'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_GOOD_REF_2', it_product_to_repair.are_good_ref_2,
    Nvl(it_product_to_repair.are_good_ref_2,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_GOOD_REF_2'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_GOOD_REF_3', it_product_to_repair.are_good_ref_3,
    Nvl(it_product_to_repair.are_good_ref_3,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_GOOD_REF_3'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_CUSTOMER_REF', it_product_to_repair.are_customer_ref,
    Nvl(it_product_to_repair.are_customer_ref,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_CUSTOMER_REF'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_GOOD_NEW_REF', it_product_to_repair.are_good_new_ref,
    Nvl(it_product_to_repair.are_good_new_ref,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_GOOD_NEW_REF'),NULL_VA));

  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_GCO_SHORT_DESCR', it_product_to_repair.are_gco_short_descr,
    Nvl(it_product_to_repair.are_gco_short_descr,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_GCO_SHORT_DESCR'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_GCO_LONG_DESCR', it_product_to_repair.are_gco_long_descr,
    Nvl(it_product_to_repair.are_gco_long_descr,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_GCO_LONG_DESCR'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_GCO_FREE_DESCR', it_product_to_repair.are_gco_free_descr,
    Nvl(it_product_to_repair.are_gco_free_descr,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_GCO_FREE_DESCR'),NULL_VA));

  p_load_characterizations(iot_crud_def, it_product_to_repair.characterizations, 'GCO_CHAR', 'ARE_CHAR');
end;

procedure p_load_repaired_product(
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_repaired_product IN asa_typ_record_trf_def.T_PRODUCT_WITH_CHARACTS)
is
begin
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'GCO_NEW_GOOD_ID', it_repaired_product.gco_good.gco_good_id,
    Nvl(it_repaired_product.gco_good.gco_good_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'GCO_NEW_GOOD_ID'),NULL_NUM));

  p_load_characterizations(iot_crud_def, it_repaired_product.characterizations, 'GCO_NEW_CHAR', 'ARE_NEW_CHAR');
end;

procedure p_load_product_for_exchange(
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_product_for_exchange IN asa_typ_record_trf_def.T_PRODUCT_WITH_CHARACTS)
is
begin
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'GCO_ASA_EXCHANGE_ID', it_product_for_exchange.gco_good.gco_good_id,
    Nvl(it_product_for_exchange.gco_good.gco_good_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'GCO_ASA_EXCHANGE_ID'),NULL_NUM));

  p_load_characterizations(iot_crud_def, it_product_for_exchange.characterizations, 'GCO_EXCH_CHAR', 'ARE_EXCH_CHAR');
end;


--procedure p_load_amounts(
--  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
--  it_amounts IN asa_typ_record_trf_def.T_AMOUNTS)
--is
--begin
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ACS_FINANCIAL_CURRENCY_ID', it_amounts.currency.acs_financial_currency_id,
--    Nvl(it_amounts.currency.acs_financial_currency_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ACS_FINANCIAL_CURRENCY_ID'),NULL_NUM));
--
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_CURR_BASE_PRICE', it_amounts.are_curr_base_price,
--    Nvl(it_amounts.are_curr_base_price,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_CURR_BASE_PRICE'),NULL_NUM));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_CURR_RATE_EURO', it_amounts.are_curr_rate_euro,
--    Nvl(it_amounts.are_curr_rate_euro,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_CURR_RATE_EURO'),NULL_NUM));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_CURR_RATE_OF_EXCH', it_amounts.are_curr_rate_of_exch,
--    Nvl(it_amounts.are_curr_rate_of_exch,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_CURR_RATE_OF_EXCH'),NULL_NUM));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_EURO_CURRENCY', it_amounts.are_euro_currency,
--    Nvl(it_amounts.are_euro_currency,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_EURO_CURRENCY'),NULL_NUM));
--
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_COST_PRICE_C', it_amounts.are_cost_price_c,
--    Nvl(it_amounts.are_cost_price_c,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_COST_PRICE_C'),NULL_NUM));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_COST_PRICE_T', it_amounts.are_cost_price_t,
--    Nvl(it_amounts.are_cost_price_t,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_COST_PRICE_T'),NULL_NUM));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_COST_PRICE_W', it_amounts.are_cost_price_w,
--    Nvl(it_amounts.are_cost_price_w,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_COST_PRICE_W'),NULL_NUM));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_COST_PRICE_S', it_amounts.are_cost_price_s,
--    Nvl(it_amounts.are_cost_price_s,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_COST_PRICE_S'),NULL_NUM));
--
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_SALE_PRICE_C', it_amounts.are_sale_price_c,
--    Nvl(it_amounts.are_sale_price_c,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_SALE_PRICE_C'),NULL_NUM));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_SALE_PRICE_S', it_amounts.are_sale_price_s,
--    Nvl(it_amounts.are_sale_price_s,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_SALE_PRICE_S'),NULL_NUM));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_SALE_PRICE_T_EURO', it_amounts.are_sale_price_t_euro,
--    Nvl(it_amounts.are_sale_price_t_euro,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_SALE_PRICE_T_EURO'),NULL_NUM));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_SALE_PRICE_T_MB', it_amounts.are_sale_price_t_mb,
--    Nvl(it_amounts.are_sale_price_t_mb,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_SALE_PRICE_T_MB'),NULL_NUM));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_SALE_PRICE_T_ME', it_amounts.are_sale_price_t_me,
--    Nvl(it_amounts.are_sale_price_t_me,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_SALE_PRICE_T_ME'),NULL_NUM));
--  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_SALE_PRICE_W', it_amounts.are_sale_price_w,
--    Nvl(it_amounts.are_sale_price_w,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_SALE_PRICE_W'),NULL_NUM));
--end;

procedure p_load_warranty(
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_warranty IN asa_typ_record_trf_def.T_WARRANTY)
is
begin
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_CUSTOMER_ERROR', it_warranty.are_customer_error,
    Nvl(it_warranty.are_customer_error,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_CUSTOMER_ERROR'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_BEGIN_GUARANTY_DATE', it_warranty.are_begin_guaranty_date,
    Nvl(it_warranty.are_begin_guaranty_date,NULL_DATE) != Nvl(fwk_i_mgt_entity_data.GetColumnDate(iot_crud_def, 'ARE_BEGIN_GUARANTY_DATE'),NULL_DATE));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_END_GUARANTY_DATE', it_warranty.are_end_guaranty_date,
    Nvl(it_warranty.are_end_guaranty_date,NULL_DATE) != Nvl(fwk_i_mgt_entity_data.GetColumnDate(iot_crud_def, 'ARE_END_GUARANTY_DATE'),NULL_DATE));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_DET_SALE_DATE', it_warranty.are_det_sale_date,
    Nvl(it_warranty.are_det_sale_date,NULL_DATE) != Nvl(fwk_i_mgt_entity_data.GetColumnDate(iot_crud_def, 'ARE_DET_SALE_DATE'),NULL_DATE));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_DET_SALE_DATE_TEXT', it_warranty.are_det_sale_date_text,
    Nvl(it_warranty.are_det_sale_date_text,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_DET_SALE_DATE_TEXT'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_FIN_SALE_DATE', it_warranty.are_fin_sale_date,
    Nvl(it_warranty.are_fin_sale_date,NULL_DATE) != Nvl(fwk_i_mgt_entity_data.GetColumnDate(iot_crud_def, 'ARE_FIN_SALE_DATE'),NULL_DATE));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_FIN_SALE_DATE_TEXT', it_warranty.are_fin_sale_date_text,
    Nvl(it_warranty.are_fin_sale_date_text,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_FIN_SALE_DATE_TEXT'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_GENERATE_BILL', it_warranty.are_generate_bill,
    Nvl(it_warranty.are_generate_bill,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_GENERATE_BILL'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_GUARANTY', it_warranty.are_guaranty,
    Nvl(it_warranty.are_guaranty,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_GUARANTY'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_GUARANTY_CODE', it_warranty.are_guaranty_code,
    Nvl(it_warranty.are_guaranty_code,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_GUARANTY_CODE'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_OFFERED_CODE', it_warranty.are_offered_code,
    Nvl(it_warranty.are_offered_code,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_OFFERED_CODE'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_REP_BEGIN_GUAR_DATE', it_warranty.are_rep_begin_guar_date,
    Nvl(it_warranty.are_rep_begin_guar_date,NULL_DATE) != Nvl(fwk_i_mgt_entity_data.GetColumnDate(iot_crud_def, 'ARE_REP_BEGIN_GUAR_DATE'),NULL_DATE));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_REP_END_GUAR_DATE', it_warranty.are_rep_end_guar_date,
    Nvl(it_warranty.are_rep_end_guar_date,NULL_DATE) != Nvl(fwk_i_mgt_entity_data.GetColumnDate(iot_crud_def, 'ARE_REP_END_GUAR_DATE'),NULL_DATE));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_REP_GUAR', it_warranty.are_rep_guar,
    Nvl(it_warranty.are_rep_guar,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_REP_GUAR'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_SALE_DATE', it_warranty.are_sale_date,
    Nvl(it_warranty.are_sale_date,NULL_DATE) != Nvl(fwk_i_mgt_entity_data.GetColumnDate(iot_crud_def, 'ARE_SALE_DATE'),NULL_DATE));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_SALE_DATE_TEXT', it_warranty.are_sale_date_text,
    Nvl(it_warranty.are_sale_date_text,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARE_SALE_DATE_TEXT'),NULL_VA));
  -- numéro de la carte de garantie pas repris
  --fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'AGC_NUMBER', it_warranty.agc_number,
  --  Nvl(it_warranty.agc_number,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'AGC_NUMBER'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'C_ASA_GUARANTY_UNIT', it_warranty.c_asa_guaranty_unit,
    Nvl(it_warranty.c_asa_guaranty_unit,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'C_ASA_GUARANTY_UNIT'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'C_ASA_REP_GUAR_UNIT', it_warranty.c_asa_rep_guar_unit,
    Nvl(it_warranty.c_asa_rep_guar_unit,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'C_ASA_REP_GUAR_UNIT'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'DIC_GARANTY_CODE_ID', it_warranty.dic_garanty_code.value,
    Nvl(it_warranty.dic_garanty_code.value,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'DIC_GARANTY_CODE_ID'),NULL_VA));
end;

procedure p_load_delay(
  it_ctx IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_delays IN asa_typ_record_trf_def.T_DELAYS)
is
  ltDelayHistory fwk_i_typ_definition.T_CRUD_DEF;
begin
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_DATE_REG_REP', it_delays.are_date_reg_rep,
    Nvl(it_delays.are_date_reg_rep,NULL_DATE) != Nvl(fwk_i_mgt_entity_data.GetColumnDate(iot_crud_def, 'ARE_DATE_REG_REP'),NULL_DATE));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_REQ_DATE_C', it_delays.are_req_date_c,
    Nvl(it_delays.are_req_date_c,NULL_DATE) != Nvl(fwk_i_mgt_entity_data.GetColumnDate(iot_crud_def, 'ARE_REQ_DATE_C'),NULL_DATE));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_CONF_DATE_C', it_delays.are_conf_date_c,
    Nvl(it_delays.are_conf_date_c,NULL_DATE) != Nvl(fwk_i_mgt_entity_data.GetColumnDate(iot_crud_def, 'ARE_CONF_DATE_C'),NULL_DATE));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_UPD_DATE_C', it_delays.are_upd_date_c,
    Nvl(it_delays.are_upd_date_c,NULL_DATE) != Nvl(fwk_i_mgt_entity_data.GetColumnDate(iot_crud_def, 'ARE_UPD_DATE_C'),NULL_DATE));

  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_REQ_DATE_S', it_delays.are_req_date_s,
    Nvl(it_delays.are_req_date_s,NULL_DATE) != Nvl(fwk_i_mgt_entity_data.GetColumnDate(iot_crud_def, 'ARE_REQ_DATE_S'),NULL_DATE));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_CONF_DATE_S', it_delays.are_conf_date_s,
    Nvl(it_delays.are_conf_date_s,NULL_DATE) != Nvl(fwk_i_mgt_entity_data.GetColumnDate(iot_crud_def, 'ARE_CONF_DATE_S'),NULL_DATE));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_UPD_DATE_S', it_delays.are_upd_date_s,
    Nvl(it_delays.are_upd_date_s,NULL_DATE) != Nvl(fwk_i_mgt_entity_data.GetColumnDate(iot_crud_def, 'ARE_UPD_DATE_S'),NULL_DATE));

  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_DATE_END_CTRL', it_delays.are_date_end_ctrl,
    Nvl(it_delays.are_date_end_ctrl,NULL_DATE) != Nvl(fwk_i_mgt_entity_data.GetColumnDate(iot_crud_def, 'ARE_DATE_END_CTRL'),NULL_DATE));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_DATE_END_REP', it_delays.are_date_end_rep,
    Nvl(it_delays.are_date_end_rep,NULL_DATE) != Nvl(fwk_i_mgt_entity_data.GetColumnDate(iot_crud_def, 'ARE_DATE_END_REP'),NULL_DATE));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_DATE_END_SENDING', it_delays.are_date_end_sending,
    Nvl(it_delays.are_date_end_sending,NULL_DATE) != Nvl(fwk_i_mgt_entity_data.GetColumnDate(iot_crud_def, 'ARE_DATE_END_SENDING'),NULL_DATE));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_DATE_START_EXP', it_delays.are_date_start_exp,
    Nvl(it_delays.are_date_start_exp,NULL_DATE) != Nvl(fwk_i_mgt_entity_data.GetColumnDate(iot_crud_def, 'ARE_DATE_START_EXP'),NULL_DATE));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_DATE_START_REP', it_delays.are_date_start_rep,
    Nvl(it_delays.are_date_start_rep,NULL_DATE) != Nvl(fwk_i_mgt_entity_data.GetColumnDate(iot_crud_def, 'ARE_DATE_START_REP'),NULL_DATE));

  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_NB_DAYS', it_delays.are_nb_days,
    Nvl(it_delays.are_nb_days,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_NB_DAYS'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_NB_DAYS_CTRL', it_delays.are_nb_days_ctrl,
    Nvl(it_delays.are_nb_days_ctrl,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_NB_DAYS_CTRL'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_NB_DAYS_EXP', it_delays.are_nb_days_exp,
    Nvl(it_delays.are_nb_days_exp,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_NB_DAYS_EXP'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_NB_DAYS_SENDING', it_delays.are_nb_days_sending,
    Nvl(it_delays.are_nb_days_sending,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_NB_DAYS_SENDING'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_NB_DAYS_WAIT', it_delays.are_nb_days_wait,
    Nvl(it_delays.are_nb_days_wait,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_NB_DAYS_WAIT'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_NB_DAYS_WAIT_COMP', it_delays.are_nb_days_wait_comp,
    Nvl(it_delays.are_nb_days_wait_comp,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_NB_DAYS_WAIT_COMP'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARE_NB_DAYS_WAIT_MAX', it_delays.are_nb_days_wait_max,
    Nvl(it_delays.are_nb_days_wait_max,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARE_NB_DAYS_WAIT_MAX'),NULL_NUM));

  -- dans le cas d'une mise à jour du dossier uniquement,
  -- vérification qu'un délai ou un nombre de jours à changé
  -- et enregistrer les données actuelles dans l'historique
  -- l'enregistrement doit impérativement est fait _avant_
  -- la mise à jour du dossier
  if (it_ctx.update_mode = fwk_i_typ_definition.UPDATING) and
      (fwk_i_mgt_entity_data.IsModified(iot_crud_def, 'ARE_DATE_REG_REP') or
       fwk_i_mgt_entity_data.IsModified(iot_crud_def, 'ARE_REQ_DATE_C') or
       fwk_i_mgt_entity_data.IsModified(iot_crud_def, 'ARE_CONF_DATE_C') or
       fwk_i_mgt_entity_data.IsModified(iot_crud_def, 'ARE_UPD_DATE_C') or
       fwk_i_mgt_entity_data.IsModified(iot_crud_def, 'ARE_REQ_DATE_S') or
       fwk_i_mgt_entity_data.IsModified(iot_crud_def, 'ARE_CONF_DATE_S') or
       fwk_i_mgt_entity_data.IsModified(iot_crud_def, 'ARE_UPD_DATE_S') or
       fwk_i_mgt_entity_data.IsModified(iot_crud_def, 'ARE_DATE_END_CTRL') or
       fwk_i_mgt_entity_data.IsModified(iot_crud_def, 'ARE_DATE_END_REP') or
       fwk_i_mgt_entity_data.IsModified(iot_crud_def, 'ARE_DATE_END_SENDING') or
       fwk_i_mgt_entity_data.IsModified(iot_crud_def, 'ARE_DATE_START_EXP') or
       fwk_i_mgt_entity_data.IsModified(iot_crud_def, 'ARE_DATE_START_REP') or
       fwk_i_mgt_entity_data.IsModified(iot_crud_def, 'ARE_NB_DAYS') or
       fwk_i_mgt_entity_data.IsModified(iot_crud_def, 'ARE_NB_DAYS_CTRL') or
       fwk_i_mgt_entity_data.IsModified(iot_crud_def, 'ARE_NB_DAYS_EXP') or
       fwk_i_mgt_entity_data.IsModified(iot_crud_def, 'ARE_NB_DAYS_SENDING') or
       fwk_i_mgt_entity_data.IsModified(iot_crud_def, 'ARE_NB_DAYS_WAIT') or
       fwk_i_mgt_entity_data.IsModified(iot_crud_def, 'ARE_NB_DAYS_WAIT_COMP') or
       fwk_i_mgt_entity_data.IsModified(iot_crud_def, 'ARE_NB_DAYS_WAIT_MAX')) then
    -- création d'un historique des délais actuels, donc avant mise à jour de ASA_RECORD.
    fwk_i_mgt_entity.New(
      iv_entity_name => fwk_i_typ_asa_entity.gcAsaDelayHistory,
      iot_crud_definition => ltDelayHistory,
      ib_initialize => TRUE);
    fwk_i_mgt_entity_data.SetColumn(ltDelayHistory, 'ASA_RECORD_ID', it_ctx.record_id);
    -- transfert des informations
    asa_prc_record_delay.InitDelayHistory(iotDelayHistory => ltDelayHistory);
    -- création de l'enregistrement historique
    fwk_i_mgt_entity.InsertEntity(ltDelayHistory);
    fwk_i_mgt_entity.Release(ltDelayHistory);
  end if;
end;

procedure p_load_description(
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_description IN asa_typ_record_trf_def.T_DESCRIPTION)
is
begin
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'PC_LANG_ID', it_description.pc_lang.pc_lang_id,
    Nvl(it_description.pc_lang.pc_lang_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'PC_LANG_ID'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARD_SHORT_DESCRIPTION', it_description.short_description,
    Nvl(it_description.short_description,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARD_SHORT_DESCRIPTION'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARD_LONG_DESCRIPTION', it_description.long_description,
    Nvl(it_description.long_description,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARD_LONG_DESCRIPTION'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARD_FREE_DESCRIPTION', it_description.free_description,
    Nvl(it_description.free_description,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARD_FREE_DESCRIPTION'),NULL_VA));
end;

procedure p_load_diagnostic(
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_diagnostic IN asa_typ_record_trf_def.T_DIAGNOSTIC)
is
begin
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'DIA_SRC_INSTANCE_NAME', it_diagnostic.source_company.instance_name,
    Nvl(it_diagnostic.source_company.instance_name,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'DIA_SRC_INSTANCE_NAME'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'DIA_SRC_SCHEMA_NAME', it_diagnostic.source_company.schema_name,
    Nvl(it_diagnostic.source_company.schema_name,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'DIA_SRC_SCHEMA_NAME'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'DIA_SRC_COM_NAME', it_diagnostic.source_company.company_name,
    Nvl(it_diagnostic.source_company.company_name,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'DIA_SRC_COM_NAME'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'DIA_SEQUENCE', it_diagnostic.dia_sequence,
    Nvl(it_diagnostic.dia_sequence,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'DIA_SEQUENCE'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'DIC_DIAGNOSTICS_TYPE_ID', it_diagnostic.dic_diagnostics_type.value,
    Nvl(it_diagnostic.dic_diagnostics_type.value,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'DIC_DIAGNOSTICS_TYPE_ID'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'C_ASA_CONTEXT', it_diagnostic.c_asa_context,
    Nvl(it_diagnostic.c_asa_context,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'C_ASA_CONTEXT'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'DIC_OPERATOR_ID', it_diagnostic.dic_operator.value,
    Nvl(it_diagnostic.dic_operator.value,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'DIC_OPERATOR_ID'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'DIA_DIAGNOSTICS_TEXT', it_diagnostic.dia_diagnostics_text,
    Nvl(it_diagnostic.dia_diagnostics_text,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'DIA_DIAGNOSTICS_TEXT'),NULL_VA));
end;

procedure p_load_record_doc_text(
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_document_text IN asa_typ_record_trf_def.T_DOCUMENT_TEXT)
is
begin
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'PC_APPLTXT_ID', it_document_text.pc_appltxt.pc_appltxt_id,
    Nvl(it_document_text.pc_appltxt.pc_appltxt_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'PC_APPLTXT_ID'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'C_ASA_TEXT_TYPE', it_document_text.c_asa_text_type,
    Nvl(it_document_text.c_asa_text_type,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'C_ASA_TEXT_TYPE'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'C_ASA_GAUGE_TYPE', it_document_text.c_asa_gauge_type,
    Nvl(it_document_text.c_asa_gauge_type,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'C_ASA_GAUGE_TYPE'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ATE_TEXT', it_document_text.ate_text,
    Nvl(it_document_text.ate_text,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ATE_TEXT'),NULL_VA));
end;

procedure p_load_free_code_boolean(
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_free_code IN asa_typ_record_trf_def.T_BOOLEAN_CODE)
is
begin
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'DIC_ASA_BOOLEAN_CODE_TYPE_ID', it_free_code.dic_asa_boolean_code_type.value,
    Nvl(it_free_code.dic_asa_boolean_code_type.value,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'DIC_ASA_BOOLEAN_CODE_TYPE_ID'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'FCO_BOO_CODE', it_free_code.fco_boo_code,
    Nvl(it_free_code.fco_boo_code,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'FCO_BOO_CODE'),NULL_NUM));
end;
procedure p_load_free_code_number(
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_free_code IN asa_typ_record_trf_def.T_NUMBER_CODE)
is
begin
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'DIC_ASA_NUMBER_CODE_TYPE_ID', it_free_code.dic_asa_number_code_type.value,
    Nvl(it_free_code.dic_asa_number_code_type.value,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'DIC_ASA_NUMBER_CODE_TYPE_ID'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'FCO_NUM_CODE', it_free_code.fco_num_code,
    Nvl(it_free_code.fco_num_code,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'FCO_NUM_CODE'),NULL_NUM));
end;
procedure p_load_free_code_memo(
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_free_code IN asa_typ_record_trf_def.T_MEMO_CODE)
is
begin
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'DIC_ASA_MEMO_CODE_TYPE_ID', it_free_code.dic_asa_memo_code_type.value,
    Nvl(it_free_code.dic_asa_memo_code_type.value,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'DIC_ASA_MEMO_CODE_TYPE_ID'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'FCO_MEM_CODE', it_free_code.fco_mem_code,
    Nvl(it_free_code.fco_mem_code,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'FCO_MEM_CODE'),NULL_VA));
end;
procedure p_load_free_code_date(
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_free_code IN asa_typ_record_trf_def.T_DATE_CODE)
is
begin
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'DIC_ASA_DATE_CODE_TYPE_ID', it_free_code.dic_asa_date_code_type.value,
    Nvl(it_free_code.dic_asa_date_code_type.value,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'DIC_ASA_DATE_CODE_TYPE_ID'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'FCO_DAT_CODE', it_free_code.fco_dat_code,
    Nvl(it_free_code.fco_dat_code,NULL_DATE) != Nvl(fwk_i_mgt_entity_data.GetColumnDate(iot_crud_def, 'FCO_DAT_CODE'),NULL_DATE));
end;
procedure p_load_free_code_char(
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_free_code IN asa_typ_record_trf_def.T_CHAR_CODE)
is
begin
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'DIC_ASA_CHAR_CODE_TYPE_ID', it_free_code.dic_asa_char_code_type.value,
    Nvl(it_free_code.dic_asa_char_code_type.value,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'DIC_ASA_CHAR_CODE_TYPE_ID'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'FCO_CHA_CODE', it_free_code.fco_cha_code,
    Nvl(it_free_code.fco_cha_code,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'FCO_CHA_CODE'),NULL_VA));
end;

procedure p_load_record_free_data(
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_free_data IN asa_typ_record_trf_def.T_RECORD_FREE_DATA_DEF,
  iv_num IN VARCHAR2)
is
  lv_field fwk_i_typ_definition.DEF_NAME;
begin
  lv_field := 'ARD_ALPHA_SHORT_'||iv_num;
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_free_data.ard_alpha_short,
    Nvl(it_free_data.ard_alpha_short,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, lv_field),NULL_VA));
  lv_field := 'ARD_ALPHA_LONG_'||iv_num;
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_free_data.ard_alpha_long,
    Nvl(it_free_data.ard_alpha_long,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, lv_field),NULL_VA));
  lv_field := 'ARD_INTEGER_'||iv_num;
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_free_data.ard_integer,
    Nvl(it_free_data.ard_integer,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, lv_field),NULL_NUM));
  lv_field := 'ARD_DECIMAL_'||iv_num;
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_free_data.ard_decimal,
    Nvl(it_free_data.ard_decimal,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, lv_field),NULL_NUM));
  lv_field := 'ARD_BOOLEAN_'||iv_num;
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_free_data.ard_boolean,
    Nvl(it_free_data.ard_boolean,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, lv_field),NULL_NUM));
  lv_field := 'DIC_ASA_REC_FREE'||iv_num||'_ID';
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_free_data.dic_asa_rec_free.value,
    Nvl(it_free_data.dic_asa_rec_free.value,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, lv_field),NULL_VA));
end;

procedure p_load_vfields(
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  itt_booleans IN asa_typ_record_trf_def.TT_VFIELD_BOOLEANS,
  itt_memos IN asa_typ_record_trf_def.TT_VFIELD_MEMOS,
  itt_chars IN asa_typ_record_trf_def.TT_VFIELD_CHARS,
  itt_dates IN asa_typ_record_trf_def.TT_VFIELD_DATES,
  itt_integers IN asa_typ_record_trf_def.TT_VFIELD_INTEGERS,
  itt_floats IN asa_typ_record_trf_def.TT_VFIELD_FLOATS,
  itt_descodes IN asa_typ_record_trf_def.TT_VFIELD_DESCODES)
is
  lv_field fwk_i_typ_definition.DEF_NAME;
  ltt_fields fwk_i_typ_definition.TT_BOOL_DICTIONARY;
begin
  -- mise à jour bouléens
  if (itt_booleans.COUNT > 0) then
    lv_field := itt_booleans.FIRST;
    loop
      fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, itt_booleans(lv_field),
        Nvl(itt_booleans(lv_field),NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, lv_field),NULL_NUM));
      ltt_fields(lv_field) := TRUE;
      lv_field := itt_booleans.NEXT(lv_field);
      exit when lv_field is null;
    end loop;
  end if;
  -- mise à jour mémos
  if (itt_memos.COUNT > 0) then
    lv_field := itt_memos.FIRST;
    loop
      fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, itt_memos(lv_field),
        Nvl(itt_memos(lv_field),NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, lv_field),NULL_VA));
      ltt_fields(lv_field) := TRUE;
      lv_field := itt_memos.NEXT(lv_field);
      exit when lv_field is null;
    end loop;
  end if;
  -- mise à jour caractères
  if (itt_chars.COUNT > 0) then
    lv_field := itt_chars.FIRST;
    loop
      fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, itt_chars(lv_field),
        Nvl(itt_chars(lv_field),NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, lv_field),NULL_VA));
      ltt_fields(lv_field) := TRUE;
      lv_field := itt_chars.NEXT(lv_field);
      exit when lv_field is null;
    end loop;
  end if;
  -- mise à jour dates
  if (itt_dates.COUNT > 0) then
    lv_field := itt_dates.FIRST;
    loop
      fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, itt_dates(lv_field),
        Nvl(itt_dates(lv_field),NULL_DATE) != Nvl(fwk_i_mgt_entity_data.GetColumnDate(iot_crud_def, lv_field),NULL_DATE));
      ltt_fields(lv_field) := TRUE;
      lv_field := itt_dates.NEXT(lv_field);
      exit when lv_field is null;
    end loop;
  end if;
  -- mise à jour entiers
  if (itt_integers.COUNT > 0) then
    lv_field := itt_integers.FIRST;
    loop
      fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, itt_integers(lv_field),
        Nvl(itt_integers(lv_field),NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, lv_field),NULL_NUM));
      ltt_fields(lv_field) := TRUE;
      lv_field := itt_integers.NEXT(lv_field);
      exit when lv_field is null;
    end loop;
  end if;
  -- mise à jour nombres
  if (itt_floats.COUNT > 0) then
    lv_field := itt_floats.FIRST;
    loop
      fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, itt_floats(lv_field),
        Nvl(itt_floats(lv_field),NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, lv_field),NULL_NUM));
      ltt_fields(lv_field) := TRUE;
      lv_field := itt_floats.NEXT(lv_field);
      exit when lv_field is null;
    end loop;
  end if;
  -- mise à jour descodes
  if (itt_descodes.COUNT > 0) then
    lv_field := itt_descodes.FIRST;
    loop
      fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, itt_descodes(lv_field),
        Nvl(itt_descodes(lv_field),NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, lv_field),NULL_VA));
      ltt_fields(lv_field) := TRUE;
      lv_field := itt_descodes.NEXT(lv_field);
      exit when lv_field is null;
    end loop;
  end if;

  -- recherche des autres champs à mettre à nul
  for tpl in (
    select COLUMN_NAME--, DATA_TYPE
    from (
      select case when Substr(COLUMN_NAME,1,2)='A_' then 1 else 0 end IS_AFIELD,
             rep_utils.IsTypeReplicable(data_type) IS_REPLICABLE,
             COLUMN_NAME--, DATA_TYPE
      from SYS.USER_TAB_COLUMNS
      where TABLE_NAME = 'COM_VFIELDS_RECORD') a
    where IS_AFIELD = 0 and IS_REPLICABLE = 1 and
      COLUMN_NAME not in ('COM_VFIELDS_RECORD_ID','VFI_REC_ID','VFI_TABNAME')
    order by 1
  ) loop
    if (not ltt_fields.EXISTS(tpl.COLUMN_NAME)) then
      fwk_i_mgt_entity_data.SetColumnNull(iot_crud_def, tpl.COLUMN_NAME,
        not fwk_i_mgt_entity_data.IsNull(iot_crud_def, tpl.COLUMN_NAME));
    end if;
  end loop;
end;

procedure p_load_free_data_comp(
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_free_data IN asa_typ_record_trf_def.T_COMPONENT_FREE_DATA_DIC_DEF,
  iv_num IN VARCHAR2)
is
  lv_field fwk_i_typ_definition.DEF_NAME;
begin
  lv_field := 'ARC_FREE_NUM'||iv_num;
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_free_data.arc_free_num,
    Nvl(it_free_data.arc_free_num,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, lv_field),NULL_NUM));
  lv_field := 'ARC_FREE_CHAR'||iv_num;
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_free_data.arc_free_char,
    Nvl(it_free_data.arc_free_char,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, lv_field),NULL_VA));
  lv_field := 'DIC_ASA_FREE_DICO_COMP'||iv_num||'_ID';
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_free_data.dic_asa_free_dico_comp.value,
    Nvl(it_free_data.dic_asa_free_dico_comp.value,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, lv_field),NULL_VA));
end;
procedure p_load_free_data_comp(
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_free_data IN asa_typ_record_trf_def.T_COMPONENT_FREE_DATA_DEF,
  iv_num IN VARCHAR2)
is
  lv_field fwk_i_typ_definition.DEF_NAME;
begin
  lv_field := 'ARC_FREE_NUM'||iv_num;
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_free_data.arc_free_num,
    Nvl(it_free_data.arc_free_num,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, lv_field),NULL_NUM));
  lv_field := 'ARC_FREE_CHAR'||iv_num;
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_free_data.arc_free_char,
    Nvl(it_free_data.arc_free_char,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, lv_field),NULL_VA));
end;

--procedure p_load_product_characteristic(
--  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
--  itt_product_characteristics IN asa_typ_record_trf_def.TT_PRODUCT_CHARACTERISTICS)
--is
--  ln_count INTEGER;
--  ln_pos INTEGER := 1;
--  lt_product_characteristic asa_typ_record_trf_def.T_PRODUCT_CHARACTERISTIC;
--  lv_field fwk_i_typ_definition.DEF_NAME;
--begin
--  ln_count := itt_product_characteristics.COUNT;
--  -- mise à jour des caractérisation
--  if (ln_count > 0) then
--    for cpt in itt_product_characteristics.FIRST .. itt_product_characteristics.LAST loop
--      lt_product_characteristic := itt_product_characteristics(cpt);
--      lv_field := 'GCO_CHAR'||to_char(ln_pos)||'_ID';
--      fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, lt_product_characteristic.gco_characterization_id,
--        Nvl(lt_product_characteristic.gco_characterization_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, lv_field),NULL_NUM));
--      lv_field := 'ARC_CHAR'||to_char(ln_pos)||'_VALUE';
--      fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, lt_product_characteristic.value,
--        Nvl(lt_product_characteristic.value,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, lv_field),NULL_VA));
--      ln_pos := ln_pos + 1;
--    end loop;
--  end if;
--  if (ln_count < 6) then
--    -- mise à nul des autres champs
--    loop
--      lv_field := 'GCO_CHAR'||to_char(ln_pos)||'_ID';
--      fwk_i_mgt_entity_data.SetColumnNull(iot_crud_def, lv_field,
--        not fwk_i_mgt_entity_data.IsNull(iot_crud_def, lv_field));
--      lv_field := 'ARC_CHAR'||to_char(ln_pos)||'_VALUE';
--      fwk_i_mgt_entity_data.SetColumnNull(iot_crud_def, lv_field,
--        not fwk_i_mgt_entity_data.IsNull(iot_crud_def, lv_field));
--      ln_pos := ln_pos + 1;
--      exit when ln_pos >= 6;
--    end loop;
--  end if;
--end;

procedure p_load_component(
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_component IN asa_typ_record_trf_def.T_COMPONENT)
is
begin
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARC_SRC_INSTANCE_NAME', it_component.source_company.instance_name,
    Nvl(it_component.source_company.instance_name,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARC_SRC_INSTANCE_NAME'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARC_SRC_SCHEMA_NAME', it_component.source_company.schema_name,
    Nvl(it_component.source_company.schema_name,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARC_SRC_SCHEMA_NAME'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARC_SRC_COM_NAME', it_component.source_company.company_name,
    Nvl(it_component.source_company.company_name,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARC_SRC_COM_NAME'),NULL_VA));

  --COMPONENT_DATA
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARC_POSITION', it_component.arc_position,
    Nvl(it_component.arc_position,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARC_POSITION'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'C_ASA_GEN_DOC_POS', it_component.c_asa_gen_doc_pos,
    Nvl(it_component.c_asa_gen_doc_pos,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'C_ASA_GEN_DOC_POS'),NULL_VA));

  if (it_component.owned_by.schema_name is not null) then
    if (it_component.owned_by.schema_name != COM_CurrentSchema) then
      -- la mise à jour ne doit pas être conditionnée, car la méthode de
      -- surcharge modifie la valeur en fonction de l'article lié
      fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARC_CDMVT', 0);
      fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARC_OWNED_BY_SCHEMA_NAME', it_component.owned_by.schema_name,
        Nvl(it_component.owned_by.schema_name,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARC_OWNED_BY_SCHEMA_NAME'),NULL_VA));
      fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARC_OWNED_BY_COM_NAME', it_component.owned_by.company_name,
        Nvl(it_component.owned_by.company_name,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARC_OWNED_BY_COM_NAME'),NULL_VA));
    else
      fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARC_OWNED_BY_SCHEMA_NAME', it_component.owned_by.schema_name,
        COM_CurrentSchema != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARC_OWNED_BY_SCHEMA_NAME'),NULL_VA));
      fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARC_OWNED_BY_COM_NAME', it_component.owned_by.company_name,
        COM_CurrentSchema != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARC_OWNED_BY_COM_NAME'),NULL_VA));
    end if;
  elsif (fwk_i_mgt_entity_data.IsNull(iot_crud_def, 'STM_COMP_STOCK_MVT_ID')) then
    -- la mise à jour ne doit pas être conditionnée, car la méthode de
    -- surcharge modifie la valeur en fonction de l'article lié
    fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARC_CDMVT', 0);
    fwk_i_mgt_entity_data.SetColumnNull(iot_crud_def, 'ARC_OWNED_BY_SCHEMA_NAME');
    fwk_i_mgt_entity_data.SetColumnNull(iot_crud_def, 'ARC_OWNED_BY_COM_NAME');
  end if;

  --OPTION
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARC_OPTIONAL', it_component.arc_optional,
    Nvl(it_component.arc_optional,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARC_OPTIONAL'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'C_ASA_ACCEPT_OPTION', it_component.c_asa_accept_option,
    Nvl(it_component.c_asa_accept_option,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'C_ASA_ACCEPT_OPTION'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'DIC_ASA_OPTION_ID', it_component.dic_asa_option.value,
    Nvl(it_component.dic_asa_option.value,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'DIC_ASA_OPTION_ID'),NULL_VA));

  --WARRANTY
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'DIC_GARANTY_CODE_ID', it_component.dic_garanty_code.value,
    Nvl(it_component.dic_garanty_code.value,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'DIC_GARANTY_CODE_ID'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARC_GUARANTY_CODE', it_component.arc_guaranty_code,
    Nvl(it_component.arc_guaranty_code,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARC_GUARANTY_CODE'),NULL_NUM));

  --PRODUCT
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'GCO_COMPONENT_ID', it_component.gco_good.gco_good_id,
    Nvl(it_component.gco_good.gco_good_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'GCO_COMPONENT_ID'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARC_QUANTITY', it_component.arc_quantity,
    Nvl(it_component.arc_quantity,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARC_QUANTITY'),NULL_NUM));

  --p_load_product_characteristic(iot_crud_def, it_component.product_characteristics);

  --DESCRIPTIONS
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARC_DESCR', it_component.arc_descr,
    Nvl(it_component.arc_descr,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARC_DESCR'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARC_DESCR2', it_component.arc_descr2,
    Nvl(it_component.arc_descr2,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARC_DESCR2'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARC_DESCR3', it_component.arc_descr3,
    Nvl(it_component.arc_descr3,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'ARC_DESCR3'),NULL_VA));

  --AMOUNTS
  --fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARC_COST_PRICE', it_component.arc_cost_price,
  --  Nvl(it_component.arc_cost_price,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARC_COST_PRICE'),NULL_NUM));
  --fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARC_SALE_PRICE', it_component.arc_sale_price,
  --  Nvl(it_component.arc_sale_price,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARC_SALE_PRICE'),NULL_NUM));
  --fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARC_SALE_PRICE_ME', it_component.arc_sale_price_me,
  --  Nvl(it_component.arc_sale_price_me,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARC_SALE_PRICE_ME'),NULL_NUM));
  --fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARC_SALE_PRICE_EURO', it_component.arc_sale_price_euro,
  --  Nvl(it_component.arc_sale_price_euro,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARC_SALE_PRICE_EURO'),NULL_NUM));
  --fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARC_SALE_PRICE2', it_component.arc_sale_price2,
  --  Nvl(it_component.arc_sale_price2,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARC_SALE_PRICE2'),NULL_NUM));
  --fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARC_SALE_PRICE2_ME', it_component.arc_sale_price2_me,
  --  Nvl(it_component.arc_sale_price2_me,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARC_SALE_PRICE2_ME'),NULL_NUM));
  --fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'ARC_SALE_PRICE2_EURO', it_component.arc_sale_price2_euro,
  --  Nvl(it_component.arc_sale_price2_euro,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'ARC_SALE_PRICE2_EURO'),NULL_NUM));

  --FREE_DATA
  p_load_free_data_comp(iot_crud_def, it_component.free_data.free_data_01, '1');
  p_load_free_data_comp(iot_crud_def, it_component.free_data.free_data_02, '2');
  p_load_free_data_comp(iot_crud_def, it_component.free_data.free_data_03, '3');
  p_load_free_data_comp(iot_crud_def, it_component.free_data.free_data_04, '4');
  p_load_free_data_comp(iot_crud_def, it_component.free_data.free_data_05, '5');
end;

procedure p_load_characterization(
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  in_good_id IN gco_good.gco_good_id%TYPE)
is
  ln_pos BINARY_INTEGER := 1;
begin
  for tpl in (
    select GCO_CHARACTERIZATION_ID
    from GCO_CHARACTERIZATION
    where GCO_GOOD_ID = in_good_id
    order by GCO_CHARACTERIZATION_ID
  ) loop
    fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'GCO_CHAR'||to_char(ln_pos)||'_ID', tpl.GCO_CHARACTERIZATION_ID);
    ln_pos := ln_pos +1;
  end loop;
end;

procedure p_load_operation_free_data(
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_free_data IN asa_typ_record_trf_def.T_OPERATION_FREE_DATA_DIC_DEF,
  iv_num IN VARCHAR2)
is
  lv_field fwk_i_typ_definition.DEF_NAME;
begin
  lv_field := 'RET_FREE_NUM'||iv_num;
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_free_data.ret_free_num,
    Nvl(it_free_data.ret_free_num,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, lv_field),NULL_NUM));
  lv_field := 'RET_FREE_CHAR'||iv_num;
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_free_data.ret_free_char,
    Nvl(it_free_data.ret_free_char,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, lv_field),NULL_VA));
  lv_field := 'DIC_ASA_FREE_DICO_TASK'||iv_num||'_ID';
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_free_data.dic_asa_free_dico_task.value,
    Nvl(it_free_data.dic_asa_free_dico_task.value,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, lv_field),NULL_VA));
end;
procedure p_load_operation_free_data(
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_free_data IN asa_typ_record_trf_def.T_OPERATION_FREE_DATA_DEF,
  iv_num IN VARCHAR2)
is
  lv_field fwk_i_typ_definition.DEF_NAME;
begin
  lv_field := 'RET_FREE_NUM'||iv_num;
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_free_data.ret_free_num,
    Nvl(it_free_data.ret_free_num,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, lv_field),NULL_NUM));
  lv_field := 'RET_FREE_CHAR'||iv_num;
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_free_data.ret_free_char,
    Nvl(it_free_data.ret_free_char,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, lv_field),NULL_VA));
end;

procedure p_load_operation(
  it_ctx IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_operation IN asa_typ_record_trf_def.T_OPERATION,
  it_update_mode fwk_i_typ_definition.UPDATE_MODE
  )
is
  ln_task_price asa_rep_type_task.rtt_amount%TYPE;
begin
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_SRC_INSTANCE_NAME', it_operation.source_company.instance_name,
    Nvl(it_operation.source_company.instance_name,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'RET_SRC_INSTANCE_NAME'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_SRC_SCHEMA_NAME', it_operation.source_company.schema_name,
    Nvl(it_operation.source_company.schema_name,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'RET_SRC_SCHEMA_NAME'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_SRC_COM_NAME', it_operation.source_company.company_name,
    Nvl(it_operation.source_company.company_name,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'RET_SRC_COM_NAME'),NULL_VA));

  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_OWNED_BY_SCHEMA_NAME', it_operation.owned_by.schema_name,
    Nvl(it_operation.owned_by.schema_name,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'RET_OWNED_BY_SCHEMA_NAME'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_OWNED_BY_COM_NAME', it_operation.owned_by.company_name,
    Nvl(it_operation.owned_by.company_name,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'RET_OWNED_BY_COM_NAME'),NULL_VA));

  --OPERATION_DATA
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_POSITION', it_operation.ret_position,
    Nvl(it_operation.ret_position,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'RET_POSITION'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'C_ASA_GEN_DOC_POS', it_operation.c_asa_gen_doc_pos,
    Nvl(it_operation.c_asa_gen_doc_pos,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'C_ASA_GEN_DOC_POS'),NULL_VA));

  --OPTION
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_OPTIONAL', it_operation.ret_optional,
    Nvl(it_operation.ret_optional,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'RET_OPTIONAL'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'C_ASA_ACCEPT_OPTION', it_operation.c_asa_accept_option,
    Nvl(it_operation.c_asa_accept_option,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'C_ASA_ACCEPT_OPTION'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'DIC_ASA_OPTION_ID', it_operation.dic_asa_option.value,
    Nvl(it_operation.dic_asa_option.value,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'DIC_ASA_OPTION_ID'),NULL_VA));

  --WARRANTY
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_GUARANTY_CODE', it_operation.ret_guaranty_code,
    Nvl(it_operation.ret_guaranty_code,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'RET_GUARANTY_CODE'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'DIC_GARANTY_CODE_ID', it_operation.dic_garanty_code.value,
    Nvl(it_operation.dic_garanty_code.value,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'DIC_GARANTY_CODE_ID'),NULL_VA));

  --TASK
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'FAL_TASK_ID', it_operation.fal_task.fal_task_id,
    Nvl(it_operation.fal_task.fal_task_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'FAL_TASK_ID'),NULL_NUM));

  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'DIC_OPERATOR_ID', it_operation.dic_operator.value,
    Nvl(it_operation.dic_operator.value,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'DIC_OPERATOR_ID'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_EXTERNAL', it_operation.ret_external,
    Nvl(it_operation.ret_external,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'RET_EXTERNAL'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_BEGIN_DATE', it_operation.ret_begin_date,
    Nvl(it_operation.ret_begin_date,NULL_DATE) != Nvl(fwk_i_mgt_entity_data.GetColumnDate(iot_crud_def, 'RET_BEGIN_DATE'),NULL_DATE));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_DURATION', it_operation.ret_duration,
    Nvl(it_operation.ret_duration,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'RET_DURATION'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_END_DATE', it_operation.ret_end_date,
    Nvl(it_operation.ret_end_date,NULL_DATE) != Nvl(fwk_i_mgt_entity_data.GetColumnDate(iot_crud_def, 'RET_END_DATE'),NULL_DATE));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_FINISHED', it_operation.ret_finished,
    Nvl(it_operation.ret_finished,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'RET_FINISHED'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_TIME', it_operation.ret_time,
    Nvl(it_operation.ret_time,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'RET_TIME'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_TIME_USED', it_operation.ret_time_used,
    Nvl(it_operation.ret_time_used,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'RET_TIME_USED'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_WORK_RATE', it_operation.ret_work_rate,
    Nvl(it_operation.ret_work_rate,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'RET_WORK_RATE'),NULL_NUM));

  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'PAC_SUPPLIER_PARTNER_ID', it_operation.pac_person.pac_person_id,
    Nvl(it_operation.pac_person.pac_person_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'PAC_SUPPLIER_PARTNER_ID'),NULL_NUM));

  --PRODUCT
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'GCO_ASA_TO_REPAIR_ID', it_operation.gco_good_to_repair.gco_good_id,
    Nvl(it_operation.gco_good_to_repair.gco_good_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'GCO_ASA_TO_REPAIR_ID'),NULL_NUM));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'GCO_BILL_GOOD_ID', it_operation.gco_good_to_bill.gco_good_id,
    Nvl(it_operation.gco_good_to_bill.gco_good_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'GCO_BILL_GOOD_ID'),NULL_NUM));

  --DESCRIPTIONS
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_DESCR', it_operation.ret_descr,
    Nvl(it_operation.ret_descr,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'RET_DESCR'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_DESCR2', it_operation.ret_descr2,
    Nvl(it_operation.ret_descr2,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'RET_DESCR2'),NULL_VA));
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_DESCR3', it_operation.ret_descr3,
    Nvl(it_operation.ret_descr3,NULL_VA) != Nvl(fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_def, 'RET_DESCR3'),NULL_VA));

  --AMOUNTS
  --Calculate sale amount only on inserting
  if it_update_mode = fwk_i_typ_definition.inserting then
    select asa_prc_record_trf_extension.get_task_price(ASA_REP_TYPE_ID, GCO_ASA_TO_REPAIR_ID,
               it_operation.gco_good_to_bill.gco_good_id,
               it_operation.fal_task.fal_task_id)
    into ln_task_price
    from ASA_RECORD
    where ASA_RECORD_ID = it_ctx.record_id;
    fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_SALE_AMOUNT', ln_task_price);
  end if;

  --  Nvl(it_operation.ret_amount,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'RET_AMOUNT'),NULL_NUM));
  --fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_AMOUNT_EURO', it_operation.ret_amount_euro,
  --  Nvl(it_operation.ret_amount_euro,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'RET_AMOUNT_EURO'),NULL_NUM));
  --fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_AMOUNT_ME', it_operation.ret_amount_me,
  --  Nvl(it_operation.ret_amount_me,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'RET_AMOUNT_ME'),NULL_NUM));
  --fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_COST_PRICE', it_operation.ret_cost_price,
  --  Nvl(it_operation.ret_cost_price,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'RET_COST_PRICE'),NULL_NUM));
  --fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_SALE_AMOUNT', it_operation.ret_sale_amount,
  --  Nvl(it_operation.ret_sale_amount,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'RET_SALE_AMOUNT'),NULL_NUM));
  --fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_SALE_AMOUNT_EURO', it_operation.ret_sale_amount_euro,
  --  Nvl(it_operation.ret_sale_amount_euro,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'RET_SALE_AMOUNT_EURO'),NULL_NUM));
  --fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_SALE_AMOUNT_ME', it_operation.ret_sale_amount_me,
  --  Nvl(it_operation.ret_sale_amount_me,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'RET_SALE_AMOUNT_ME'),NULL_NUM));
  --fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_SALE_AMOUNT2', it_operation.ret_sale_amount2,
  --  Nvl(it_operation.ret_sale_amount2,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'RET_SALE_AMOUNT2'),NULL_NUM));
  --fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_SALE_AMOUNT2_EURO', it_operation.ret_sale_amount2_euro,
  --  Nvl(it_operation.ret_sale_amount2_euro,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'RET_SALE_AMOUNT2_EURO'),NULL_NUM));
  --fwk_i_mgt_entity_data.SetColumn(iot_crud_def, 'RET_SALE_AMOUNT2_ME', it_operation.ret_sale_amount2_me,
  --  Nvl(it_operation.ret_sale_amount2_me,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_def, 'RET_SALE_AMOUNT2_ME'),NULL_NUM));

  --FREE_DATA
  p_load_operation_free_data(iot_crud_def, it_operation.free_data.free_data_01, '1');
  p_load_operation_free_data(iot_crud_def, it_operation.free_data.free_data_02, '2');
  p_load_operation_free_data(iot_crud_def, it_operation.free_data.free_data_03, '3');
  p_load_operation_free_data(iot_crud_def, it_operation.free_data.free_data_04, '4');
  p_load_operation_free_data(iot_crud_def, it_operation.free_data.free_data_05, '5');
end;


--
-- Entity removing
--

procedure p_delete_rows(
  it_ctx IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  itt_merged IN asa_typ_record_trf_def.TT_ROWID,
  iv_where_clause IN VARCHAR2 default null)
is
  lv_cmd VARCHAR2(32767);
  ltt_remove asa_typ_record_trf_def.TT_ROWID;
begin
  lv_cmd :=
    'select rowid'||
    ' from '||iot_crud_def.entity_def.name||
    ' where ASA_RECORD_ID=:1'||
        case when (itt_merged.COUNT > 0) then' and rowid not in ('||to_string(itt_merged)||')' end ||
        NullIf(' and '||iv_where_clause,' and ');
  ---dbms_output.put_line(lv_cmd);
  -- collect des enregistrements "en trop"
  execute immediate
    lv_cmd
    bulk collect into ltt_remove
    using in it_ctx.record_id;

  -- suppression des enregistrements
  if (ltt_remove is not null and ltt_remove.COUNT > 0) then
    fwk_i_mgt_entity.Clear(iot_crud_def);
    for cpt in ltt_remove.FIRST .. ltt_remove.LAST loop
      iot_crud_def.row_id := ltt_remove(cpt);
      fwk_i_mgt_entity.DeleteEntity(iot_crud_def);
    end loop;
    fwk_i_mgt_entity.Clear(iot_crud_def);
  end if;
end;

procedure p_delete_descriptions(
  it_ctx IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  itt_merged IN asa_typ_record_trf_def.TT_ROWID,
  iv_description_type IN VARCHAR2)
is
begin
  p_delete_rows(it_ctx, iot_crud_def, itt_merged,
    'C_ASA_DESCRIPTION_TYPE='''||iv_description_type||''''
  );
end;

procedure p_delete_diagnostics(
  it_ctx IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  itt_merged IN asa_typ_record_trf_def.TT_ROWID)
is
begin
  p_delete_rows(it_ctx, iot_crud_def, itt_merged);
    -- dans le cas de la synchronisation des diagnostiques doivent pouvoir
    -- être supprimés, même s'ils n'appartiennent pas à la société locale.
    -- Ce qui n'est pas possible depuis l'interface utilisateur.
    --'DIA_SRC_SCHEMA_NAME=COM_CurrentSchema');
end;

procedure p_delete_vfields(
  in_id IN NUMBER,
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  iv_table_name IN VARCHAR2,
  itt_merged IN asa_typ_record_trf_def.TT_ROWID)
is
  lv_cmd VARCHAR2(32767);
  ltt_remove asa_typ_record_trf_def.TT_ROWID;
begin
  lv_cmd :=
    'select rowid'||
    ' from '||iot_crud_def.entity_def.name||
    ' where VFI_TABNAME=:1 and VFI_REC_ID=:2'||
        case when (itt_merged.COUNT > 0) then ' and rowid not in ('||to_string(itt_merged)||')' end;
  --dbms_output.put_line(lv_cmd);
  -- collect des enregistrements "en trop"
  execute immediate
    lv_cmd
    bulk collect into ltt_remove
    using in iv_table_name,
          in in_id;

  -- suppression des enregistrements
  if (ltt_remove is not null and ltt_remove.COUNT > 0) then
    fwk_i_mgt_entity.Clear(iot_crud_def);
    for cpt in ltt_remove.FIRST .. ltt_remove.LAST loop
      iot_crud_def.row_id := ltt_remove(cpt);
      fwk_i_mgt_entity.DeleteEntity(iot_crud_def);
    end loop;
    fwk_i_mgt_entity.Clear(iot_crud_def);
  end if;
end;

procedure p_delete_components(
  it_ctx IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  itt_merged IN asa_typ_record_trf_def.TT_ROWID)
is
begin
  p_delete_rows(it_ctx, iot_crud_def, itt_merged,
    'ASA_RECORD_EVENTS_ID='||it_ctx.record_events_id||
--    ' and (ARC_OWNED_BY_SCHEMA_NAME is null or ARC_OWNED_BY_SCHEMA_NAME=COM_CurrentSchema)'||
    ' and STM_COMP_STOCK_MVT_ID is null');
end;

procedure p_delete_operations(
  it_ctx IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  itt_merged IN asa_typ_record_trf_def.TT_ROWID)
is
begin
  p_delete_rows(it_ctx, iot_crud_def, itt_merged,
    'ASA_RECORD_EVENTS_ID='||it_ctx.record_events_id||
--    ' and (RET_OWNED_BY_SCHEMA_NAME is null or RET_OWNED_BY_SCHEMA_NAME=COM_CurrentSchema)'||
    ' and RET_FINISHED = 0 and Nvl(RET_TIME_USED,0) = 0');
end;


--
-- Entity merge preparation
--

procedure p_prepare_merge(
  iot_ctx IN OUT NOCOPY asa_typ_record_trf_def.T_MERGE_CONTEXT,
  iot_after_sales_file IN OUT NOCOPY asa_typ_record_trf_def.T_AFTER_SALES_FILE)
is
  lb_use_comp asa_rep_type.ret_use_comp%TYPE;
  lb_use_task asa_rep_type.ret_use_task%TYPE;
  lt_sold_to asa_typ_record_trf_def.T_ADDRESS;
  lt_delivered_to asa_typ_record_trf_def.T_ADDRESS;
  lt_invoiced_to asa_typ_record_trf_def.T_ADDRESS;
begin
  if (iot_ctx.update_mode = fwk_i_typ_definition.INSERTING) then
    iot_ctx.record_id := init_id_seq.NextVal;
  end if;

  -- détection de la mise à jour des composants et des opérations
  if (iot_after_sales_file.header.header_data.asa_rep_type.asa_rep_type_id is not null) then
    select RET_USE_COMP, RET_USE_TASK
    into lb_use_comp, lb_use_task
    from ASA_REP_TYPE
    where ASA_REP_TYPE_ID = iot_after_sales_file.header.header_data.asa_rep_type.asa_rep_type_id;
    iot_ctx.use_component := case lb_use_comp when 1 then TRUE else FALSE end;
    iot_ctx.use_operation := case lb_use_task when 1 then TRUE else FALSE end;
  else
    iot_ctx.use_component := FALSE;
    iot_ctx.use_operation := FALSE;
  end if;

  -- identifiant du demandeur
  iot_ctx.custom_partner_id := asa_lib_record_trf.get_customer(
    it_sender => iot_after_sales_file.envelope.sender);

  if (iot_ctx.update_mode = fwk_i_typ_definition.INSERTING) then
    -- remplissage des adresses
    for tplAddress in (
      select ADR.PAC_ADDRESS_ID
           , ADR.DIC_ADDRESS_TYPE_ID
           , ADR.ADD_ADDRESS1
           , ADR.ADD_ZIPCODE
           , ADR.ADD_CITY
           , ADR.ADD_STATE
           , ADR.ADD_CARE_OF
           , ADR.ADD_PO_BOX
           , ADR.ADD_PO_BOX_NBR
           , ADR.ADD_COUNTY
           , ADR.PC_CNTRY_ID
           , ADR.PC_LANG_ID
           , MAIN.ROWNB
      from
        (
          select G.ROWNB, A.PAC_ADDRESS_ID
          from (
            select 1 ROWNB, DIC_ADDRESS_TYPE_ID from DOC_GAUGE
            where DOC_GAUGE_ID = iot_after_sales_file.header.header_data.doc_gauge.doc_gauge_id
            union all
            select 2 ROWNB, DIC_ADDRESS_TYPE1_ID from DOC_GAUGE
            where DOC_GAUGE_ID = iot_after_sales_file.header.header_data.doc_gauge.doc_gauge_id
            union all
            select 3 ROWNB, DIC_ADDRESS_TYPE2_ID from DOC_GAUGE
            where DOC_GAUGE_ID = iot_after_sales_file.header.header_data.doc_gauge.doc_gauge_id) G,
            PAC_ADDRESS A
          where A.PAC_PERSON_ID = iot_ctx.custom_partner_id
            and A.DIC_ADDRESS_TYPE_ID = G.DIC_ADDRESS_TYPE_ID
        ) MAIN,
        PAC_ADDRESS ADR
      where
        ADR.PAC_ADDRESS_ID = Coalesce(MAIN.PAC_ADDRESS_ID,
                                     (select PAC_ADDRESS_ID from PAC_ADDRESS
                                      where PAC_PERSON_ID = iot_ctx.custom_partner_id
                                        and ADD_PRINCIPAL = 1))
      order by MAIN.ROWNB
    ) loop
      case tplAddress.ROWNB
        when 1 then
          iot_after_sales_file.header.header_data.customer_lang.pc_lang_id := tplAddress.PC_LANG_ID;
          lt_sold_to.are_address := tplAddress.ADD_ADDRESS1;
          lt_sold_to.are_care_of := tplAddress.ADD_CARE_OF;
          lt_sold_to.are_county := tplAddress.ADD_COUNTY;
          lt_sold_to.are_format_city :=
            pac_partner_management.FormatingAddress(
              tplAddress.ADD_ZIPCODE, tplAddress.ADD_CITY, tplAddress.ADD_STATE,
              tplAddress.ADD_COUNTY, tplAddress.PC_CNTRY_ID
            );
          lt_sold_to.are_po_box_nbr := tplAddress.ADD_PO_BOX_NBR;
          lt_sold_to.are_po_box := tplAddress.ADD_PO_BOX;
          lt_sold_to.are_postcode := tplAddress.ADD_ZIPCODE;
          lt_sold_to.are_state := tplAddress.ADD_STATE;
          lt_sold_to.are_town := tplAddress.ADD_CITY;
          lt_sold_to.pac_address.pac_address_id := tplAddress.PAC_ADDRESS_ID;
          lt_sold_to.pc_cntry.pc_cntry_id := tplAddress.PC_CNTRY_ID;
        when 2 then
          lt_delivered_to.are_address := tplAddress.ADD_ADDRESS1;
          lt_delivered_to.are_care_of := tplAddress.ADD_CARE_OF;
          lt_delivered_to.are_county := tplAddress.ADD_COUNTY;
          lt_delivered_to.are_format_city :=
            pac_partner_management.FormatingAddress(
              tplAddress.ADD_ZIPCODE, tplAddress.ADD_CITY, tplAddress.ADD_STATE,
              tplAddress.ADD_COUNTY, tplAddress.PC_CNTRY_ID
            );
          lt_delivered_to.are_po_box_nbr := tplAddress.ADD_PO_BOX_NBR;
          lt_delivered_to.are_po_box := tplAddress.ADD_PO_BOX;
          lt_delivered_to.are_postcode := tplAddress.ADD_ZIPCODE;
          lt_delivered_to.are_state := tplAddress.ADD_STATE;
          lt_delivered_to.are_town := tplAddress.ADD_CITY;
          lt_delivered_to.pac_address.pac_address_id := tplAddress.PAC_ADDRESS_ID;
          lt_delivered_to.pc_cntry.pc_cntry_id := tplAddress.PC_CNTRY_ID;
        when 3 then
          lt_invoiced_to.are_address := tplAddress.ADD_ADDRESS1;
          lt_invoiced_to.are_care_of := tplAddress.ADD_CARE_OF;
          lt_invoiced_to.are_county := tplAddress.ADD_COUNTY;
          lt_invoiced_to.are_format_city :=
            pac_partner_management.FormatingAddress(
              tplAddress.ADD_ZIPCODE, tplAddress.ADD_CITY, tplAddress.ADD_STATE,
              tplAddress.ADD_COUNTY, tplAddress.PC_CNTRY_ID);
          lt_invoiced_to.are_po_box_nbr := tplAddress.ADD_PO_BOX_NBR;
          lt_invoiced_to.are_po_box := tplAddress.ADD_PO_BOX;
          lt_invoiced_to.are_postcode := tplAddress.ADD_ZIPCODE;
          lt_invoiced_to.are_state := tplAddress.ADD_STATE;
          lt_invoiced_to.are_town := tplAddress.ADD_CITY;
          lt_invoiced_to.pac_address.pac_address_id := tplAddress.PAC_ADDRESS_ID;
          lt_invoiced_to.pc_cntry.pc_cntry_id := tplAddress.PC_CNTRY_ID;
        else
          null;
      end case;
    end loop;
    iot_after_sales_file.header.addresses.sold_to := lt_sold_to;
    iot_after_sales_file.header.addresses.delivered_to := lt_delivered_to;
    iot_after_sales_file.header.addresses.invoiced_to := lt_invoiced_to;
  end if;
end;

--
-- Entity execution
--

function p_execute_entity(
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_update_mode IN fwk_i_typ_definition.UPDATE_MODE)
  return ROWID
is
begin
  if (iot_crud_def.column_list.COUNT > 0) then
    --dbms_output.put_line('entity '||iot_crud_def.entity_def.name||' columns='||columns_value(iot_crud_def));
    case it_update_mode
      when fwk_i_typ_definition.INSERTING then
        fwk_i_mgt_entity.InsertEntity(iot_crud_def);
      when fwk_i_typ_definition.UPDATING then
        fwk_i_mgt_entity.UpdateEntity(iot_crud_def);
    end case;
  end if;
  return iot_crud_def.row_id;
end;


--
-- Public methods
--

procedure prepare_merge_after_sales_file(
  iot_ctx IN OUT NOCOPY asa_typ_record_trf_def.T_MERGE_CONTEXT,
  it_after_sales_file IN asa_typ_record_trf_def.T_AFTER_SALES_FILE)
is
begin
  if (it_after_sales_file.envelope.message.message_type in (asa_typ_record_trf_def.TRF_MSG_TYPE_SEND,
                                                            asa_typ_record_trf_def.TRF_MSG_TYPE_SEND_LOOP)) then
    -- forcer le mode création lorsqu'un dossier est envoyé ou réouvert (boucle)
    iot_ctx.record_id := 0.0;
  else
    iot_ctx.record_id := asa_lib_record_trf.get_record_id(
      iv_number => it_after_sales_file.envelope.message.are_number,
      it_origin => asa_lib_record_trf.decode_origin(it_after_sales_file.envelope.message.are_number_matching_mode));
  end if;

  if (iot_ctx.record_id <> 0.0) then
    iot_ctx.update_mode := fwk_i_typ_definition.UPDATING;
    -- statut de réouverture du dossier
    select C_ASA_TRF_LOOP_STATUS
    into iot_ctx.loop_status
    from ASA_RECORD
    where ASA_RECORD_ID = iot_ctx.record_id;
  else
    iot_ctx.update_mode := fwk_i_typ_definition.INSERTING;
  end if;
end;

procedure merge_after_sales_file(
  iot_ctx IN OUT NOCOPY asa_typ_record_trf_def.T_MERGE_CONTEXT,
  iot_after_sales_file IN OUT NOCOPY asa_typ_record_trf_def.T_AFTER_SALES_FILE)
is
begin
  p_prepare_merge(iot_ctx, iot_after_sales_file);

  -- exécution de la méthode individualisée
  asa_prc_record_trf_extension.Execute(
    it_context => iot_ctx,
    iot_after_sales_file => iot_after_sales_file);

  -- intégration du dossier
  asa_prc_record_trf_merge.mergeRECORD(iot_ctx, iot_after_sales_file);

  -- mise à jour des composants et des opérations uniquement
  -- si le dossier n'a pas été réouvert (boucle)
  if (iot_ctx.loop_status = asa_typ_record_trf_def.TRF_LOOP_NONE) then
    -- intégration des composants
    if (iot_ctx.use_component) then
      asa_prc_record_trf_merge.mergeRECORD_COMP(iot_ctx, iot_after_sales_file);
    end if;
    -- intégration des opérations
    if (iot_ctx.use_operation) then
      asa_prc_record_trf_merge.mergeRECORD_TASK(iot_ctx, iot_after_sales_file);
    end if;
    -- Finalisation du dossier SAV
    --    déclenche les procédure externes BeforeValidate, AfterValidate
    asa_prc_record.FinalizeRecord(iot_ctx.record_id);
  end if;
end;


procedure mergeRECORD(
  iot_ctx IN OUT NOCOPY asa_typ_record_trf_def.T_MERGE_CONTEXT,
  it_after_sales_file IN asa_typ_record_trf_def.T_AFTER_SALES_FILE)
is
  lt_header asa_typ_record_trf_def.T_HEADER;
  lt_result asa_record.asa_record_id%TYPE;
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  ln_ORG_REP_TYPE_ID asa_rep_type.asa_rep_type_id%TYPE;
  lv_rowid ROWID;
begin
  lt_header := it_after_sales_file.header;
  fwk_i_mgt_entity.New(
    iv_entity_name => fwk_i_typ_asa_entity.gcAsaRecord,
    iot_crud_definition => lt_crud_def);

  case iot_ctx.update_mode
    when fwk_i_typ_definition.UPDATING then
      fwk_i_mgt_entity.Load(lt_crud_def, iot_ctx.record_id);
      -- sauvegarde de la valeur originelle
      ln_ORG_REP_TYPE_ID := fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'ASA_REP_TYPE_ID');
    when fwk_i_typ_definition.INSERTING then
      fwk_i_mgt_entity.Init(lt_crud_def, TRUE);
      -- sauvegarde de la valeur originelle
      ln_ORG_REP_TYPE_ID := fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'ASA_REP_TYPE_ID');
      -- spécification de la valeur de l'identifiant
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ASA_RECORD_ID', iot_ctx.record_id);
      -- le client, l'émetteur du transfert, est mis à jour
      -- uniquement à la création du dossier SAV
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_CUSTOM_PARTNER_ID', iot_ctx.custom_partner_id);
      -- forcer les deux champs ARE_USE_COMP et ARE_USE_TASK à FALSE pour éviter
      -- que la méthode de surcharge de l'entité ASA_RECORD créé automatiquement
      -- des enregistrements dans les tables ASA_RECORD_COMP et ASA_RECORD_TASK.
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_USE_COMP', FALSE);
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_USE_TASK', FALSE);
  end case;

  -- mise à jour uniquement si le dossier n'a pas été réouvert (boucle)
  if (iot_ctx.loop_status = asa_typ_record_trf_def.TRF_LOOP_NONE) then
    p_load_header_data(lt_crud_def, lt_header.header_data, it_after_sales_file.envelope.message.message_type);

    -- traitement des adresses uniquement à la création du dossier
    if (iot_ctx.update_mode = fwk_i_typ_definition.INSERTING) then
      -- Les adresses à utiliser ont été calculée par la méthode p_prepare_merge
      p_load_header_address(lt_crud_def, lt_header.addresses.sold_to, '1');
      p_load_header_address(lt_crud_def, lt_header.addresses.delivered_to, '2');
      p_load_header_address(lt_crud_def, lt_header.addresses.invoiced_to, '3');
      -- spécification de la langue du client à utiliser
      if (lt_header.header_data.customer_lang.pc_lang_id is not null) then
        fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PC_ASA_CUST_LANG_ID', lt_header.header_data.customer_lang.pc_lang_id,
          Nvl(lt_header.header_data.customer_lang.pc_lang_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'PC_ASA_CUST_LANG_ID'),NULL_NUM));
      end if;
      --p_load_header_address_agent(lt_crud_def, lt_header.addresses.agent);
      --p_load_header_address_retailer(lt_crud_def, lt_header.addresses.retailer);
      --p_load_header_address_customer(lt_crud_def, lt_header.addresses.final_customer);
    end if;

    p_load_product_to_repair(lt_crud_def, lt_header.product_to_repair);
    p_load_repaired_product(lt_crud_def, lt_header.repaired_product);
    p_load_product_for_exchange(lt_crud_def, lt_header.product_for_exchange);

    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'GCO_BILL_GOOD_ID', lt_header.product_for_invoice.gco_good.gco_good_id,
      Nvl(lt_header.product_for_invoice.gco_good.gco_good_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'GCO_BILL_GOOD_ID'),NULL_NUM));

    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'GCO_DEVIS_BILL_GOOD_ID', lt_header.product_for_estimate_invoice.gco_good.gco_good_id,
      Nvl(lt_header.product_for_estimate_invoice.gco_good.gco_good_id,NULL_NUM) != Nvl(fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'GCO_DEVIS_BILL_GOOD_ID'),NULL_NUM));

    -- les montants ne sont pas repris
    --p_load_amounts(lt_crud_def, lt_header.amounts);

    p_load_warranty(lt_crud_def, lt_header.warranty);
  end if;

  if (it_after_sales_file.envelope.comment is not null) then
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_TRF_RECALL_COMMENT', it_after_sales_file.envelope.comment);
  end if;

  -- chargement des délais dans tous les cas, car ils peuvent avoir été changés
  p_load_delay(iot_ctx, lt_crud_def, lt_header.delays);

  -- mise à jour de l'entité (si nécessaire)
  lv_rowid := p_execute_entity(lt_crud_def, iot_ctx.update_mode);

  -- chargement de l'entité avec les données actuelle de la table,
  -- car elles peuvent avoir changées après intégration de l'entité
  fwk_i_mgt_entity.Clear(lt_crud_def);
  fwk_i_mgt_entity.Load(lt_crud_def, lv_rowid);

  iot_ctx.record_events_id := fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'ASA_RECORD_EVENTS_ID');

  if (ln_ORG_REP_TYPE_ID is null and iot_ctx.update_mode = fwk_i_typ_definition.UPDATING) or
     (iot_ctx.update_mode = fwk_i_typ_definition.INSERTING) then
    -- mise à null des codes tarifs pour qu'ils soient recalculés
    -- selon la configuration de la société locale
    fwk_i_mgt_entity_data.SetColumnNull(lt_crud_def, 'DIC_TARIFF_ID');
    fwk_i_mgt_entity_data.SetColumnNull(lt_crud_def, 'DIC_TARIFF2_ID');
    fwk_i_mgt_entity_data.SetColumnDefault(lt_crud_def, 'C_ASA_SELECT_PRICE');
    -- mise à jour des données supplémentaires
    asa_prc_record.InitRecordRepType(lt_crud_def);
    -- mise à jour de l'entité
    lv_rowid := p_execute_entity(lt_crud_def, fwk_i_typ_definition.UPDATING);
  end if;

  -- libération de l'entité
  fwk_i_mgt_entity.Release(lt_crud_def);

  --dbms_output.put_line('merge_context='||asa_lib_record_trf_utl.to_string(iot_ctx));

  -- mise à jour uniquement si le dossier n'a pas été réouvert (boucle)
  if (iot_ctx.loop_status = asa_typ_record_trf_def.TRF_LOOP_NONE) then
    -- intégration des autres données
    asa_prc_record_trf_merge.mergeRECORD_DESCR(iot_ctx, lt_header.internal_descriptions, '1');
    asa_prc_record_trf_merge.mergeRECORD_DESCR(iot_ctx, lt_header.internal_descriptions, '2');

    asa_prc_record_trf_merge.mergeDIAGNOSTICS(iot_ctx, lt_header.diagnostics);

    asa_prc_record_trf_merge.mergeRECORD_DOC_TEXT(iot_ctx, lt_header.document_texts);

    asa_prc_record_trf_merge.mergeFREE_CODES(iot_ctx, lt_header.free_codes);

    asa_prc_record_trf_merge.mergeFREE_DATA(iot_ctx, lt_header.free_data);

    asa_prc_record_trf_merge.mergeVIRTUAL_FIELDS(iot_ctx.record_id, 'ASA_RECORD', lt_header.virtual_fields);
  end if;
end;


procedure mergeRECORD_DESCR(
  it_ctx IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  itt_descriptions IN asa_typ_record_trf_def.TT_DESCRIPTIONS,
  iv_description_type IN VARCHAR2)
is
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  ltt_merged asa_typ_record_trf_def.TT_ROWID;
  lt_update_mode fwk_i_typ_definition.UPDATE_MODE := fwk_i_typ_definition.UPDATE_NONE;
  lt_description asa_typ_record_trf_def.T_DESCRIPTION;
begin
  fwk_i_mgt_entity.New(
    iv_entity_name => fwk_i_typ_asa_entity.gcAsaRecordDescr,
    iot_crud_definition => lt_crud_def,
    iv_primary_col => 'ASA_RECORD_ID');

  -- traitement des enregistrements ajouter/modifier
  if (itt_descriptions.COUNT > 0) then
    for cpt in itt_descriptions.FIRST .. itt_descriptions.LAST loop
      lt_description := itt_descriptions(cpt);
      -- ne pas traiter les descriptions pour les langues inconnues
      if (lt_description.pc_lang.pc_lang_id != 0.0) then
        -- le chargement de l'entité doit être fait avant le chargement des valeurs
        lt_update_mode := p_init_merge_description(it_ctx, lt_crud_def, lt_description, iv_description_type);
        -- chargement des valeurs
        p_load_description(lt_crud_def, lt_description);
        -- mise à jour de l'entité si nécessaire
        -- collecte du rowid de l'enregistrement traité
        ltt_merged(ltt_merged.COUNT) := p_execute_entity(lt_crud_def, lt_update_mode);
        -- initialisation de l'entité
        fwk_i_mgt_entity.Clear(lt_crud_def);
      end if;
    end loop;
  end if;

  -- traitement des enregistrements à supprimer
  p_delete_descriptions(it_ctx, lt_crud_def, ltt_merged, iv_description_type);

  fwk_i_mgt_entity.Release(lt_crud_def);
end;


procedure mergeDIAGNOSTICS(
  it_ctx IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  itt_diagnostics IN asa_typ_record_trf_def.TT_DIAGNOSTICS)
is
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  ltt_merged asa_typ_record_trf_def.TT_ROWID;
  lt_update_mode fwk_i_typ_definition.UPDATE_MODE := fwk_i_typ_definition.UPDATE_NONE;
  lt_diagnostic asa_typ_record_trf_def.T_DIAGNOSTIC;
  ln_id NUMBER;
begin
  fwk_i_mgt_entity.New(
    iv_entity_name => fwk_i_typ_asa_entity.gcAsaDiagnostics,
    iot_crud_definition => lt_crud_def);

  -- traitement des enregistrements ajouter/modifier
  if (itt_diagnostics.COUNT > 0) then
    for cpt in itt_diagnostics.FIRST .. itt_diagnostics.LAST loop
      lt_diagnostic := itt_diagnostics(cpt);
      -- le chargement de l'entité doit être fait avant le chargement des valeurs
      lt_update_mode := p_init_merge_diagnostic(it_ctx, lt_crud_def, lt_diagnostic);
      -- chargement des valeurs
      p_load_diagnostic(lt_crud_def, lt_diagnostic);
      -- mise à jour de l'entité
      -- collecte du rowid de l'enregistrement traité
      ltt_merged(ltt_merged.COUNT) := p_execute_entity(lt_crud_def, lt_update_mode);
      ln_id := fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'ASA_DIAGNOSTICS_ID');
      -- initialisation de l'entité
      fwk_i_mgt_entity.Clear(lt_crud_def);

      -- intégration des champs virtuels
      asa_prc_record_trf_merge.mergeVIRTUAL_FIELDS(ln_id, 'ASA_DIAGNOSTICS', lt_diagnostic.virtual_fields);
    end loop;
  end if;

  -- traitement des enregistrements à supprimer
  p_delete_diagnostics(it_ctx, lt_crud_def, ltt_merged);

  fwk_i_mgt_entity.Release(lt_crud_def);
end;


procedure mergeRECORD_DOC_TEXT(
  it_ctx IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  itt_document_texts IN asa_typ_record_trf_def.TT_DOCUMENT_TEXTS)
is
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  ltt_merged asa_typ_record_trf_def.TT_ROWID;
  lt_update_mode fwk_i_typ_definition.UPDATE_MODE := fwk_i_typ_definition.UPDATE_NONE;
begin
  fwk_i_mgt_entity.New(
    iv_entity_name => fwk_i_typ_asa_entity.gcAsaRecordDocText,
    iot_crud_definition => lt_crud_def);

  -- traitement des enregistrements ajouter/modifier
  if (itt_document_texts.COUNT > 0) then
    for cpt in itt_document_texts.FIRST .. itt_document_texts.LAST loop
      -- le chargement de l'entité doit être fait avant le chargement des valeurs
      lt_update_mode := p_init_merge_document_text(it_ctx, lt_crud_def, itt_document_texts(cpt));
      -- chargement des valeurs
      p_load_record_doc_text(lt_crud_def, itt_document_texts(cpt));
      -- mise à jour de l'entité si nécessaire
      -- collecte du rowid de l'enregistrement traité
      ltt_merged(ltt_merged.COUNT) := p_execute_entity(lt_crud_def, lt_update_mode);
      -- initialisation de l'entité
      fwk_i_mgt_entity.Clear(lt_crud_def);
    end loop;
  end if;

  -- traitement des enregistrements à supprimer
  p_delete_rows(it_ctx, lt_crud_def, ltt_merged);

  fwk_i_mgt_entity.Release(lt_crud_def);
end;


procedure mergeFREE_CODES(
  it_ctx IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  it_free_codes IN asa_typ_record_trf_def.T_RECORD_FREE_CODES)
is
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  ltt_merged asa_typ_record_trf_def.TT_ROWID;
  lt_update_mode fwk_i_typ_definition.UPDATE_MODE := fwk_i_typ_definition.UPDATE_NONE;
begin
  fwk_i_mgt_entity.New(
    iv_entity_name => fwk_i_typ_asa_entity.gcAsaFreeCode,
    iot_crud_definition => lt_crud_def);

  -- traitement des enregistrements ajouter/modifier
  if (it_free_codes.boolean_codes.COUNT > 0) then
    for cpt in it_free_codes.boolean_codes.FIRST .. it_free_codes.boolean_codes.LAST loop
      -- le chargement de l'entité doit être fait avant le chargement des valeurs
      lt_update_mode := p_init_merge_free_code_bool(it_ctx, lt_crud_def, it_free_codes.boolean_codes(cpt));
      -- chargement des valeurs
      p_load_free_code_boolean(lt_crud_def, it_free_codes.boolean_codes(cpt));
      -- mise à jour de l'entité
      -- collecte du rowid de l'enregistrement traité
      ltt_merged(ltt_merged.COUNT) := p_execute_entity(lt_crud_def, lt_update_mode);
      -- initialisation de l'entité
      fwk_i_mgt_entity.Clear(lt_crud_def);
    end loop;
  end if;
  if (it_free_codes.number_codes.COUNT > 0) then
    for cpt in it_free_codes.number_codes.FIRST .. it_free_codes.number_codes.LAST loop
      -- le chargement de l'entité doit être fait avant le chargement des valeurs
      lt_update_mode := p_init_merge_free_code_number(it_ctx, lt_crud_def, it_free_codes.number_codes(cpt));
      -- chargement des valeurs
      p_load_free_code_number(lt_crud_def, it_free_codes.number_codes(cpt));
      -- mise à jour de l'entité
      -- collecte du rowid de l'enregistrement traité
      ltt_merged(ltt_merged.COUNT) := p_execute_entity(lt_crud_def, lt_update_mode);
      -- initialisation de l'entité
      fwk_i_mgt_entity.Clear(lt_crud_def);
    end loop;
  end if;
  if (it_free_codes.memo_codes.COUNT > 0) then
    for cpt in it_free_codes.memo_codes.FIRST .. it_free_codes.memo_codes.LAST loop
      -- le chargement de l'entité doit être fait avant le chargement des valeurs
      lt_update_mode := p_init_merge_free_code_memo(it_ctx, lt_crud_def, it_free_codes.memo_codes(cpt));
      -- chargement des valeurs
      p_load_free_code_memo(lt_crud_def, it_free_codes.memo_codes(cpt));
      -- mise à jour de l'entité
      -- collecte du rowid de l'enregistrement traité
      ltt_merged(ltt_merged.COUNT) := p_execute_entity(lt_crud_def, lt_update_mode);
      -- initialisation de l'entité
      fwk_i_mgt_entity.Clear(lt_crud_def);
    end loop;
  end if;
  if (it_free_codes.date_codes.COUNT > 0) then
    for cpt in it_free_codes.date_codes.FIRST .. it_free_codes.date_codes.LAST loop
      -- le chargement de l'entité doit être fait avant le chargement des valeurs
      lt_update_mode := p_init_merge_free_code_date(it_ctx, lt_crud_def, it_free_codes.date_codes(cpt));
      -- chargement des valeurs
      p_load_free_code_date(lt_crud_def, it_free_codes.date_codes(cpt));
      -- mise à jour de l'entité
      -- collecte du rowid de l'enregistrement traité
      ltt_merged(ltt_merged.COUNT) := p_execute_entity(lt_crud_def, lt_update_mode);
      -- initialisation de l'entité
      fwk_i_mgt_entity.Clear(lt_crud_def);
    end loop;
  end if;
  if (it_free_codes.char_codes.COUNT > 0) then
    for cpt in it_free_codes.char_codes.FIRST .. it_free_codes.char_codes.LAST loop
      -- le chargement de l'entité doit être fait avant le chargement des valeurs
      lt_update_mode := p_init_merge_free_code_char(it_ctx, lt_crud_def, it_free_codes.char_codes(cpt));
      -- chargement des valeurs
      p_load_free_code_char(lt_crud_def, it_free_codes.char_codes(cpt));
      -- mise à jour de l'entité
      -- collecte du rowid de l'enregistrement traité
      ltt_merged(ltt_merged.COUNT) := p_execute_entity(lt_crud_def, lt_update_mode);
      -- initialisation de l'entité
      fwk_i_mgt_entity.Clear(lt_crud_def);
    end loop;
  end if;

  -- traitement des enregistrements à supprimer
  p_delete_rows(it_ctx, lt_crud_def, ltt_merged);

  fwk_i_mgt_entity.Release(lt_crud_def);
end;


procedure mergeFREE_DATA(
  it_ctx IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  it_record_free_data IN asa_typ_record_trf_def.T_RECORD_FREE_DATA)
is
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  ltt_merged asa_typ_record_trf_def.TT_ROWID;
  lt_update_mode fwk_i_typ_definition.UPDATE_MODE := fwk_i_typ_definition.UPDATE_NONE;
begin
  fwk_i_mgt_entity.New(
    iv_entity_name => fwk_i_typ_asa_entity.gcAsaFreeData,
    iot_crud_definition => lt_crud_def);

  -- le chargement de l'entité doit être fait avant le chargement des valeurs
  lt_update_mode := p_init_merge(it_ctx, lt_crud_def);
  -- chargement des valeurs
  p_load_record_free_data(lt_crud_def, it_record_free_data.free_data_01, '1');
  p_load_record_free_data(lt_crud_def, it_record_free_data.free_data_02, '2');
  p_load_record_free_data(lt_crud_def, it_record_free_data.free_data_03, '3');
  p_load_record_free_data(lt_crud_def, it_record_free_data.free_data_04, '4');
  p_load_record_free_data(lt_crud_def, it_record_free_data.free_data_05, '5');
  -- mise à jour de l'entité
  -- collecte du rowid de l'enregistrement traité
  ltt_merged(ltt_merged.COUNT) := p_execute_entity(lt_crud_def, lt_update_mode);
  -- initialisation de l'entité
  fwk_i_mgt_entity.Clear(lt_crud_def);

  -- traitement des enregistrements à supprimer
  p_delete_rows(it_ctx, lt_crud_def, ltt_merged);

  fwk_i_mgt_entity.Release(lt_crud_def);
end;


procedure mergeVIRTUAL_FIELDS(
  in_id IN NUMBER,
  iv_table_name IN VARCHAR2,
  it_virtual_fields IN asa_typ_record_trf_def.T_VIRTUAL_FIELDS)
is
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  ltt_merged asa_typ_record_trf_def.TT_ROWID;
  lt_update_mode fwk_i_typ_definition.UPDATE_MODE := fwk_i_typ_definition.UPDATE_NONE;
begin
  fwk_i_mgt_entity.New(
    iv_entity_name => fwk_typ_com_entity.gcComVFieldsRecord,
    iot_crud_definition => lt_crud_def);

  -- le chargement de l'entité doit être fait avant le chargement des valeurs
  lt_update_mode := p_init_merge_vfields(in_id, lt_crud_def, iv_table_name);
  -- chargement des valeurs
  p_load_vfields(lt_crud_def,
    it_virtual_fields.booleans,
    it_virtual_fields.memos,
    it_virtual_fields.chars,
    it_virtual_fields.dates,
    it_virtual_fields.integers,
    it_virtual_fields.floats,
    it_virtual_fields.descodes);
  -- mise à jour de l'entité
  -- collecte du rowid de l'enregistrement traité
  ltt_merged(ltt_merged.COUNT) := p_execute_entity(lt_crud_def, lt_update_mode);
  -- initialisation de l'entité
  fwk_i_mgt_entity.Clear(lt_crud_def);

  -- traitement des enregistrements à supprimer
  p_delete_vfields(in_id, lt_crud_def, iv_table_name, ltt_merged);

  fwk_i_mgt_entity.Release(lt_crud_def);
end;


procedure mergeRECORD_COMP(
  it_ctx IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  it_after_sales_file IN asa_typ_record_trf_def.T_AFTER_SALES_FILE)
is
  ltt_components asa_typ_record_trf_def.TT_COMPONENTS;
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  ltt_merged asa_typ_record_trf_def.TT_ROWID;
  lt_update_mode fwk_i_typ_definition.UPDATE_MODE := fwk_i_typ_definition.UPDATE_NONE;
  lt_component asa_typ_record_trf_def.T_COMPONENT;
  ln_id NUMBER;
begin
  ltt_components := it_after_sales_file.components;
  fwk_i_mgt_entity.New(
    iv_entity_name => fwk_i_typ_asa_entity.gcAsaRecordComp,
    iot_crud_definition => lt_crud_def);

  if (ltt_components.COUNT > 0) then
    for cpt in ltt_components.FIRST .. ltt_components.LAST loop
      lt_component := ltt_components(cpt);
      -- le chargement de l'entité doit être fait avant le chargement des valeurs
      lt_update_mode := p_init_merge_component(it_ctx, lt_crud_def, lt_component);
      -- chargement des valeurs
      p_load_component(lt_crud_def, lt_component);
      if (lt_update_mode = fwk_i_typ_definition.INSERTING) then
        p_load_characterization(lt_crud_def, fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'GCO_COMPONENT_ID'));
      end if;
      -- mise à jour de l'entité
      -- collecte du rowid de l'enregistrement traité
      ltt_merged(ltt_merged.COUNT) := p_execute_entity(lt_crud_def, lt_update_mode);
      ln_id := fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'ASA_RECORD_COMP_ID');
      -- initialisation de l'entité
      fwk_i_mgt_entity.Clear(lt_crud_def);

      -- intégration des champs virtuels
      asa_prc_record_trf_merge.mergeVIRTUAL_FIELDS(ln_id, 'ASA_RECORD_COMP', lt_component.virtual_fields);
    end loop;
  end if;

  -- traitement des enregistrements à supprimer
  p_delete_components(it_ctx, lt_crud_def, ltt_merged);

  fwk_i_mgt_entity.Release(lt_crud_def);
end;


procedure mergeRECORD_TASK(
  it_ctx IN asa_typ_record_trf_def.T_MERGE_CONTEXT,
  it_after_sales_file IN asa_typ_record_trf_def.T_AFTER_SALES_FILE)
is
  ltt_operations asa_typ_record_trf_def.TT_OPERATIONS;
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  ltt_merged asa_typ_record_trf_def.TT_ROWID;
  lt_update_mode fwk_i_typ_definition.UPDATE_MODE := fwk_i_typ_definition.UPDATE_NONE;
  lt_operation asa_typ_record_trf_def.T_OPERATION;
  ln_id NUMBER;
begin
  ltt_operations := it_after_sales_file.operations;
  fwk_i_mgt_entity.New(
    iv_entity_name => fwk_i_typ_asa_entity.gcAsaRecordTask,
    iot_crud_definition => lt_crud_def);

  if (ltt_operations.COUNT > 0) then
    for cpt in ltt_operations.FIRST .. ltt_operations.LAST loop
      lt_operation := ltt_operations(cpt);
      -- le chargement de l'entité doit être fait avant le chargement des valeurs
      lt_update_mode := p_init_merge_operation(it_ctx, lt_crud_def, lt_operation);
      -- chargement des valeurs
      p_load_operation(it_ctx, lt_crud_def, lt_operation, lt_update_mode);
      -- mise à jour de l'entité
      -- collecte du rowid de l'enregistrement traité
      ltt_merged(ltt_merged.COUNT) := p_execute_entity(lt_crud_def, lt_update_mode);
      ln_id := fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'ASA_RECORD_TASK_ID');
      -- initialisation de l'entité
      fwk_i_mgt_entity.Clear(lt_crud_def);

      -- intégration des champs virtuels
      asa_prc_record_trf_merge.mergeVIRTUAL_FIELDS(ln_id, 'ASA_RECORD_TASK', lt_operation.virtual_fields);
    end loop;
  end if;

  -- traitement des enregistrements à supprimer
  p_delete_operations(it_ctx, lt_crud_def, ltt_merged);

  fwk_i_mgt_entity.Release(lt_crud_def);
end;


procedure update_dictionary(
  iv_name IN VARCHAR2,
  it_dictionary IN asa_typ_record_trf_def.T_DICTIONARY,
  in_update_additional_fields IN INTEGER default 0,
  in_update_descriptions IN INTEGER default 0)
is
  lv_name VARCHAR2(32);
  lb_dic_exists BOOLEAN;
begin
  -- validation du nom du dictionnaire
  lv_name := fwk_i_lib_utils.check_def_name(iv_name);

  -- vérification de l'existance de la valeur
  lb_dic_exists := p_dic_exists(lv_name, it_dictionary.value);

  if (not lb_dic_exists) then
    -- création de la valeur du dictionnaire
    p_insert_dic_code(lv_name, it_dictionary);
  elsif (in_update_additional_fields = 1) then
    -- mise à jour des autres champs demandés
    p_update_dic_values(lv_name, it_dictionary);
  end if;

  if (not lb_dic_exists or in_update_descriptions = 1) then
    -- mise à jour des descriptions
    p_merge_dic_descriptions(lv_name, it_dictionary);
  end if;
end;

END ASA_PRC_RECORD_TRF_MERGE;
