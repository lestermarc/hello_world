--------------------------------------------------------
--  DDL for Package Body ASA_PRC_RECORD_TRF_ADM
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_PRC_RECORD_TRF_ADM" 
/**
 * Administration de la circulation de dossiers SAV.
 *
 * @version 1.0
 * @date 04/2012
 * @author spfister
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
AS

  TYPE T_DISPATCH IS RECORD (
    prefix VARCHAR2(3),
    recipient asa_typ_record_trf_def.T_COMPANY_DEF
  );

  -- constantes
  gcv_QUEUE_TYPE CONSTANT VARCHAR2(6) := 'ASATRF';
  gcv_XPATH CONSTANT VARCHAR2(48) := '/AFTER_SALES_FILE/ENVELOPE/MESSAGE_NUMBER/text()';
  gcv_NULL_VA CONSTANT VARCHAR2(1) := '@';

/**
 * Convertion d'un document Xml en texte, avec prologue.
 * @param ix_document  Document Xml original.
 * @return le CLOB du document Xml avec prologue correspondant à l'encodage de la base.
 */
function p_XmlToClob(ix_document IN XMLType) return CLob is
begin
  if (ix_document is not null) then
    return pc_jutils.get_XMLPrologDefault ||Chr(10)|| ix_document.getClobVal();
  end if;

  return null;
end;

/**
 * Mise à jour des informations de l'expéditeur d'une entité.
 * @param iot_crud_def  T_CRUD_DEF.
 * @param iv_prefix  Préfix des champs.
 */
procedure p_update_record_sender(
  iot_crud_def IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF,
  it_dispatch IN T_DISPATCH)
is
  lv_field VARCHAR2(32);
begin
  lv_field := it_dispatch.prefix||'_SRC_INSTANCE_NAME';
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_dispatch.recipient.instance_name,
    fwk_i_mgt_entity_data.IsNull(iot_crud_def,lv_field));

  lv_field := it_dispatch.prefix||'_SRC_SCHEMA_NAME';
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_dispatch.recipient.schema_name,
    fwk_i_mgt_entity_data.IsNull(iot_crud_def,lv_field));

  lv_field := it_dispatch.prefix||'_SRC_COM_NAME';
  fwk_i_mgt_entity_data.SetColumn(iot_crud_def, lv_field, it_dispatch.recipient.company_name,
    fwk_i_mgt_entity_data.IsNull(iot_crud_def,lv_field));

  if (iot_crud_def.column_list.COUNT > 0) then
    fwk_i_mgt_entity.UpdateEntity(iot_crud_def);
  end if;
end;

/**
 * Envoi d'un dossier dans le système de queuing.
 * @param in_record_id  Identifiant du dossier.
 * @param ix_document  Document Xml du dossier SAV.
 * @return l'identifiant du message du système de queuing.
 */
function p_enqueue(
  in_record_id IN asa_record.asa_record_id%TYPE,
  ix_document IN XMLType)
  return NUMBER
is
  ln_result NUMBER;
begin
  rep_que_fct.enqueue(
    gcv_QUEUE_TYPE,
    rep_xml_function.extract_value(ix_document, gcv_XPATH),
    ix_document,
    ln_result);
  asa_prc_record_trf_adm.archive_message(
    in_record_id => in_record_id,
    in_message_id => ln_result,
    it_msg_direction => asa_typ_record_trf_def.TRF_MSG_SEND,
    ix_document => ix_document);
  return ln_result;
end;

/**
 * Réception d'un dossier depuis le système de queuing.
 * @param ox_document  Document Xml du dossier SAV.
 * @return l'identifiant du message du système de queuing.
 */
function p_dequeue(
  ox_document OUT NOCOPY XMLType)
  return NUMBER
is
  ln_result NUMBER;
begin
  ox_document := rep_que_fct.dequeue_xml(
    iv_recipient_name => COM_CurrentSchema,
    iv_queue_type => gcv_QUEUE_TYPE,
    on_message_id => ln_result);

  return ln_result;
end;

/**
 * Libération d'un message du système de queuing.
 * @param in_message_id  Iidentifiant du message du système de queuing.
 */
procedure p_release(
  in_message_id IN NUMBER)
is
  ln_tmp INTEGER;
begin
  pcs.pc_prc_queue.trace_operation(
    iv_queue_trace => '401',
    iv_info => 'Release message',
    in_message_id => in_message_id,
    iv_que_dst => COM_CurrentSchema,
    iv_queue_type => gcv_QUEUE_TYPE);

  ln_tmp := rep_que_fct.release(
    iv_recipient_name => COM_CurrentSchema,
    iv_queue_type => gcv_QUEUE_TYPE,
    in_message_id => in_message_id);
end;


--
-- Public methods
--

procedure update_record_sender(
  in_record_id IN asa_record.asa_record_id%TYPE)
is
  lt_dispatch T_DISPATCH;
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
begin
  select
    sys_context('USERENV', 'INSTANCE_NAME'),
    COM_CurrentSchema,
    (select CURRENT_VALUE
       from PCS.V_PC_SESSION_INFO
      where PARAMETER = 'COMPANY')
  into
    lt_dispatch.recipient.instance_name,
    lt_dispatch.recipient.schema_name,
    lt_dispatch.recipient.company_name
  from DUAL;

  -- mise à jour du dossier
  begin
    fwk_i_mgt_entity.New(
      iv_entity_name => fwk_i_typ_asa_entity.gcAsaRecord,
      iot_crud_definition => lt_crud_def,
      ib_initialize => TRUE,
      in_main_id => in_record_id);

    lt_dispatch.prefix := 'ARE';
    p_update_record_sender(lt_crud_def, lt_dispatch);

    fwk_i_mgt_entity.Release(lt_crud_def);

    exception
      when NO_DATA_FOUND then
        -- sortie anticipée car le dossier n'existe pas
        return;
  end;

  -- mise à jour des composants
  fwk_i_mgt_entity.New(
    iv_entity_name => fwk_i_typ_asa_entity.gcAsaRecordComp,
    iot_crud_definition => lt_crud_def);
  lt_dispatch.prefix := 'ARC';
  for tpl in (
    select C.ROWID
      from ASA_RECORD_COMP C, ASA_RECORD R
     where R.ASA_RECORD_ID = in_record_id
       and C.ASA_RECORD_ID = R.ASA_RECORD_ID
       and C.ASA_RECORD_EVENTS_ID = R.ASA_RECORD_EVENTS_ID
  ) loop
    fwk_i_mgt_entity.Load(lt_crud_def, tpl.ROWID);
    p_update_record_sender(lt_crud_def, lt_dispatch);
    fwk_i_mgt_entity.Clear(lt_crud_def);
  end loop;
  fwk_i_mgt_entity.Release(lt_crud_def);

  -- mise à jour des opérations
  fwk_i_mgt_entity.New(
    iv_entity_name => fwk_i_typ_asa_entity.gcAsaRecordTask,
    iot_crud_definition => lt_crud_def);
  lt_dispatch.prefix := 'RET';
  for tpl in (
    select T.ROWID
      from ASA_RECORD_TASK T, ASA_RECORD R
     where R.ASA_RECORD_ID = in_record_id
       and T.ASA_RECORD_ID = R.ASA_RECORD_ID
       and T.ASA_RECORD_EVENTS_ID = R.ASA_RECORD_EVENTS_ID
  ) loop
    fwk_i_mgt_entity.Load(lt_crud_def, tpl.ROWID);
    p_update_record_sender(lt_crud_def, lt_dispatch);
    fwk_i_mgt_entity.Clear(lt_crud_def);
  end loop;
  fwk_i_mgt_entity.Release(lt_crud_def);

  -- mise à jour des diagnostiques
  fwk_i_mgt_entity.New(
    iv_entity_name => fwk_i_typ_asa_entity.gcAsaDiagnostics,
    iot_crud_definition => lt_crud_def);
  lt_dispatch.prefix := 'DIA';
  for tpl in (
    select ROWID
      from ASA_DIAGNOSTICS
     where ASA_RECORD_ID = in_record_id
  ) loop
    fwk_i_mgt_entity.Load(lt_crud_def, tpl.ROWID);
    p_update_record_sender(lt_crud_def, lt_dispatch);
    fwk_i_mgt_entity.Clear(lt_crud_def);
  end loop;
  fwk_i_mgt_entity.Release(lt_crud_def);
end;

procedure update_record_recipient(
  in_record_id IN asa_record.asa_record_id%TYPE)
is
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  ln_supplier_partner_id pac_supplier_partner.pac_supplier_partner_id%TYPE;
  lt_sender asa_typ_record_trf_def.T_COMPANY_DEF;
begin
  fwk_i_mgt_entity.New(
    iv_entity_name => fwk_i_typ_asa_entity.gcAsaRecord,
    iot_crud_definition => lt_crud_def,
    ib_initialize => TRUE,
    in_main_id => in_record_id);

  ln_supplier_partner_id := fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'PAC_SUPPLIER_PARTNER_ID');
  select
    ATD_INSTANCE_NAME,
    ATD_SCHEMA_NAME,
    ATD_COM_NAME
  into
    lt_sender.instance_name,
    lt_sender.schema_name,
    lt_sender.company_name
  from ASA_RECORD_TRF_DEST
  where PAC_SUPPLIER_PARTNER_ID = ln_supplier_partner_id;

  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_DST_INSTANCE_NAME', lt_sender.instance_name,
    fwk_i_mgt_entity_data.IsNull(lt_crud_def,'ARE_DST_INSTANCE_NAME'));

  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_DST_SCHEMA_NAME', lt_sender.schema_name,
    fwk_i_mgt_entity_data.IsNull(lt_crud_def,'ARE_DST_SCHEMA_NAME'));

  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_DST_COM_NAME', lt_sender.company_name,
    fwk_i_mgt_entity_data.IsNull(lt_crud_def,'ARE_DST_COM_NAME'));

  fwk_i_mgt_entity.UpdateEntity(lt_crud_def);

  fwk_i_mgt_entity.Release(lt_crud_def);

  exception
    when NO_DATA_FOUND then
      fwk_i_mgt_exception.raise_exception(
        in_error_code => fwk_i_typ_definition.EXCEPTION_INVALID_ARGUMENT_NO,
        iv_message => 'invalid configuration, no recipient',
        iv_stack_trace => dbms_utility.format_error_backtrace);
end;

function send_record(
  in_record_id IN asa_record.asa_record_id%TYPE,
  it_msg_type IN asa_typ_record_trf_def.T_ASA_TRF_MSG_TYPE)
  return NUMBER
is
  lx_document XMLType;
begin
  fwk_i_lib_utils.check_argument('ASA_RECORD_ID', in_record_id);
  fwk_i_lib_utils.check_argument('IT_MSG_TYPE', it_msg_type);

  lx_document := asa_lib_record_trf_xml.get_asa_record_trf_xml(
    in_record_id => in_record_id,
    it_msg_type => it_msg_type,
    it_msg_recipient => asa_typ_record_trf_def.TRF_RECIPIENT_DST);
  return p_enqueue(in_record_id, lx_document);
end;

procedure send_record_confirmation(
  in_record_id IN asa_record.asa_record_id%TYPE,
  it_original IN asa_typ_record_trf_def.T_AFTER_SALES_FILE)
is
  ln_message_id NUMBER;
  lx_document XMLType;
  lv_org_msg_type asa_typ_record_trf_def.T_ASA_TRF_MSG_TYPE := asa_typ_record_trf_def.TRF_MSG_TYPE_NONE;
begin
  fwk_i_lib_utils.check_argument('ASA_RECORD_ID', in_record_id);

  lv_org_msg_type := it_original.envelope.message.message_type;
  lx_document := asa_lib_record_trf_xml.get_asa_record_switch_xml(
    it_msg_type => asa_typ_record_trf_def.TRF_MSG_TYPE_TREATED,
    it_msg_recipient =>
      case
        when (lv_org_msg_type in (asa_typ_record_trf_def.TRF_MSG_TYPE_SEND,
                                  asa_typ_record_trf_def.TRF_MSG_TYPE_SEND_LOOP)) then
          asa_typ_record_trf_def.TRF_RECIPIENT_SRC
        when (lv_org_msg_type = asa_typ_record_trf_def.TRF_MSG_TYPE_RESPONSE) then
          asa_typ_record_trf_def.TRF_RECIPIENT_DST
      end,
    it_original => it_original.envelope);
  ln_message_id := p_enqueue(in_record_id, lx_document);
end;

procedure send_record_recall_action(
  in_record_id IN asa_record.asa_record_id%TYPE,
  it_msg_type IN asa_typ_record_trf_def.T_ASA_TRF_MSG_TYPE)
is
  lx_document XMLType;
  ln_message_id NUMBER;
begin
  fwk_i_lib_utils.check_argument('ASA_RECORD_ID', in_record_id);
  fwk_i_lib_utils.check_argument('IT_MSG_TYPE', it_msg_type);

  lx_document := asa_lib_record_trf_xml.get_asa_record_recall_xml(
    in_record_id => in_record_id,
    it_msg_type => it_msg_type);
  ln_message_id := p_enqueue(in_record_id, lx_document);
end;


procedure send_record_notify_updates(
  in_record_id IN asa_record.asa_record_id%TYPE,
  it_msg_type IN asa_typ_record_trf_def.T_ASA_TRF_MSG_TYPE,
  it_msg_recipient IN asa_typ_record_trf_def.T_ASA_TRF_MSG_RECIPIENT)
is
  lx_document XMLType;
  ln_message_id NUMBER;
begin
  fwk_i_lib_utils.check_argument('ASA_RECORD_ID', in_record_id);
  fwk_i_lib_utils.check_argument('IT_MSG_TYPE', it_msg_type);
  if (it_msg_recipient = asa_typ_record_trf_def.TRF_RECIPIENT_NONE) then
    fwk_i_mgt_exception.raise_exception(
      in_error_code => fwk_i_typ_definition.EXCEPTION_INVALID_ARGUMENT_NO,
      iv_message => 'Argument null encountered: '||'IT_MSG_RECIPIENT',
      iv_stack_trace => dbms_utility.format_error_backtrace);
  end if;
  if (it_msg_type not in (asa_typ_record_trf_def.TRF_MSG_TYPE_STATE,
                          asa_typ_record_trf_def.TRF_MSG_TYPE_STATUS_CHANGED,
                          asa_typ_record_trf_def.TRF_MSG_TYPE_NOTIFY_CHANGES)) then
    fwk_i_mgt_exception.raise_exception(
      in_error_code => fwk_i_typ_definition.EXCEPTION_INVALID_ARGUMENT_NO,
      iv_message => 'IT_MSG_TYPE was out of the range of valid values ('||it_msg_type||').',
      iv_stack_trace => dbms_utility.format_error_backtrace);
  end if;

  lx_document := asa_lib_record_trf_xml.get_asa_record_trf_xml(
    in_record_id => in_record_id,
    it_msg_type => it_msg_type,
    it_msg_recipient => it_msg_recipient);
  ln_message_id := p_enqueue(in_record_id, lx_document);
end;

procedure send_record_again(
  in_record_id IN asa_record.asa_record_id%TYPE)
is
  lv_msg_direction VARCHAR2(10);
  lt_msg_org CLOB;
  lx_document XMLType;
  lt_envelope asa_typ_record_trf_def.T_ENVELOPE;
  lx_msg_details XMLType;
  ln_message_id NUMBER;
begin
  begin
    select C_ASA_TRF_MSG_DIRECTION, ARM_MESSAGE_PAYLOAD
    into lv_msg_direction, lt_msg_org
    from ASA_RECORD_MSG_ARCH
    where ASA_RECORD_MSG_ARCH_ID = (select Max(ASA_RECORD_MSG_ARCH_ID)
                                    from ASA_RECORD_MSG_ARCH
                                    where ASA_RECORD_ID = in_record_id);
    exception
      when NO_DATA_FOUND then
        fwk_i_mgt_exception.raise_exception(
          in_error_code => asa_typ_record_trf_def.EXCEPTION_RESEND_RECORD_NO,
          iv_message => 'There was no message sent',
          iv_stack_trace => dbms_utility.format_error_backtrace);
        return;
  end;
  if (lv_msg_direction != '01') then
    fwk_i_mgt_exception.raise_exception(
      in_error_code => asa_typ_record_trf_def.EXCEPTION_RESEND_RECORD_NO,
      iv_message => 'Only sent message can be sent again, the last one is received',
      iv_stack_trace => dbms_utility.format_error_backtrace);
    return;
  end if;

  lx_document := XMLType(lt_msg_org);

  -- décodage des informations de l'enveloppe
  asa_lib_record_trf_rec.load_envelope(
    ix_document => lx_document,
    iot_envelope => lt_envelope,
    ib_fragment => FALSE);

  -- génération des informations de détails
  lx_msg_details := asa_lib_record_trf_xml.get_message_details(
    in_record_id,
    lt_envelope.message.message_type,
    lt_envelope.message.are_number_matching_mode,
    lt_envelope.message.are_number);

  -- remplacement des tags contenant une date
  select
    updateXML(lx_document,
      '/AFTER_SALES_FILE/ENVELOPE/MESSAGE_NUMBER/text()', ExtractValue(lx_msg_details,'MESSAGE_NUMBER'),
      '/AFTER_SALES_FILE/ENVELOPE/MESSAGE_DATE/text()', ExtractValue(lx_msg_details,'MESSAGE_DATE')
    ) into lx_document
  from DUAL;

  ln_message_id := p_enqueue(in_record_id, lx_document);
end;


function send_document(
  in_record_id IN asa_record.asa_record_id%TYPE,
  ix_document IN XMLType)
  return NUMBER
is
begin
  return p_enqueue(in_record_id, ix_document);
end;


function receive_record(
  ox_document OUT NOCOPY XMLType)
  return NUMBER
is
  ln_result NUMBER;
  lv_msg_type asa_typ_record_trf_def.T_ASA_TRF_MSG_TYPE := asa_typ_record_trf_def.TRF_MSG_TYPE_NONE;
  lt_envelope asa_typ_record_trf_def.T_ENVELOPE;
begin
  ox_document := null;

  -- il est nécessaire de faire une boucle pour la réception des messages car
  -- certains types de messages sont automatiquement envoyés sans traitement
  <<RECALL_DEQUEUE>>

  ln_result := p_dequeue(ox_document);
  if (ln_result is null) then
    -- sortie anticipée s'il n'y a aucun document à traiter
    return null;
  end if;

  -- décodage des informations du message
  asa_lib_record_trf_rec.load_envelope(
    ix_document => ox_document,
    iot_envelope => lt_envelope,
    ib_fragment => FALSE);

  -- type du message
  lv_msg_type := lt_envelope.message.message_type;

  -- les messages de confirmation de traitement ne doivent pas être écartés car
  -- dans le cas du retour du dossier à la société source, une confirmation est
  -- retournée à la société de destination pour confirmer l'intégration dans la
  -- société source et ce message doit être traité par la société de destination
  -- alors que le dosser est bloqué pour transfert.
  if (lv_msg_type != asa_typ_record_trf_def.TRF_MSG_TYPE_TREATED) then
    -- le document ne doit pas être traité car le transfert du dossier est terminé
    if (asa_prc_record_trf_adm.archive_when_record_completed(
        iv_number => lt_envelope.message.are_number,
        ix_document => ox_document,
        it_origin => asa_lib_record_trf.decode_origin(lt_envelope.message.are_number_matching_mode))) then
      -- libération du message
      asa_prc_record_trf_adm.release_record(
        in_message_id => ln_result);
      commit;
      -- dequeue next
      goto RECALL_DEQUEUE;
    end if;
  end if;

  return ln_result;
end;

procedure release_record(
  in_message_id IN NUMBER)
is
begin
  p_release(in_message_id);
end;


procedure import_record(
  ix_document IN XMLType,
  on_record_id OUT asa_record.asa_record_id%TYPE)
is
  lt_ctx asa_typ_record_trf_def.T_MERGE_CONTEXT;
  lt_after_sales_file asa_typ_record_trf_def.T_AFTER_SALES_FILE;
begin
  -- chargement de la structure RECORD
  lt_after_sales_file := asa_prc_record_trf_adm.load_asa_record(
    ix_document => ix_document);

  -- préparation de l'importation
  asa_prc_record_trf_merge.prepare_merge_after_sales_file(
    iot_ctx => lt_ctx,
    it_after_sales_file => lt_after_sales_file);

  -- exécution de la procédure avant importation
  asa_prc_record_trf_extension.execute_before_import(
    it_context => lt_ctx,
    it_after_sales_file => lt_after_sales_file);

  -- importation
  asa_prc_record_trf_merge.merge_after_sales_file(
    iot_ctx => lt_ctx,
    iot_after_sales_file => lt_after_sales_file);

  -- conserver la trace du message reçu
  asa_prc_record_trf_adm.archive_message(
    in_record_id => lt_ctx.record_id,
    it_msg_direction => asa_typ_record_trf_def.TRF_MSG_RECEIVE,
    ix_document => ix_document);

  -- exécution de la procédure après importation
  asa_prc_record_trf_extension.execute_after_import(
    it_context => lt_ctx,
    it_after_sales_file => lt_after_sales_file);

  -- sending confirmation of the success of the import only
  -- for messages type SEND and RESPONSE
  if (lt_after_sales_file.envelope.message.message_type in (asa_typ_record_trf_def.TRF_MSG_TYPE_SEND,
                                                            asa_typ_record_trf_def.TRF_MSG_TYPE_SEND_LOOP,
                                                            asa_typ_record_trf_def.TRF_MSG_TYPE_RESPONSE)) then
    asa_prc_record_trf_adm.send_record_confirmation(
      in_record_id => lt_ctx.record_id,
      it_original => lt_after_sales_file);
  end if;

  on_record_id := lt_ctx.record_id;

  exception
    when OTHERS then
      fwk_i_mgt_exception.raise_exception(
        in_error_code => asa_typ_record_trf_def.EXCEPTION_IMPORT_RECORD_NO,
        iv_message => 'Error on importing after sales record'||Chr(10)||sqlerrm,
        iv_stack_trace => dbms_utility.format_error_backtrace);
end;


function archive_when_record_completed(
  iv_number IN asa_record.are_number%TYPE,
  ix_document IN XMLType,
  it_origin IN asa_typ_record_trf_def.T_ASA_TRF_ORIGIN)
  return BOOLEAN
is
  ln_record_id asa_record.asa_record_id%TYPE;
begin
  ln_record_id := asa_lib_record_trf.get_record_id(
    iv_number => iv_number,
    it_origin => it_origin);
  -- si le transfert de ce dossier est terminé,
  -- il faut enregistrer une information sur le message envoyé
  -- et passer au prochain message à recevoir
  if (ln_record_id > 0.0 and asa_lib_record_trf.is_record_completed(ln_record_id) = 1) then
    asa_prc_record_trf_adm.archive_message(
      in_record_id => ln_record_id,
      it_msg_direction => asa_typ_record_trf_def.TRF_MSG_SEND,
      ix_document => ix_document,
      iv_comment => pcs.pc_functions.TranslateWord('Ce message n''a pas été traité car le transfert du dossier est terminé'));
    return TRUE;
  end if;

  return FALSE;
end;


function load_asa_record(
  ix_document IN XMLType)
  return asa_typ_record_trf_def.T_AFTER_SALES_FILE
is
  lt_result asa_typ_record_trf_def.T_AFTER_SALES_FILE;
begin
  if (ix_document is null) then
    fwk_i_mgt_exception.raise_exception(
      in_error_code => fwk_i_typ_definition.EXCEPTION_INVALID_ARGUMENT_NO,
      iv_message => 'Argument null encountered: '||'ix_document',
      iv_stack_trace => dbms_utility.format_error_backtrace);
  end if;

  asa_lib_record_trf_rec.load_asa_record_trf(
    ix_document => ix_document,
    iot_after_sales_file => lt_result);
  return lt_result;
end;


procedure log_import_error(
  iv_error in VARCHAR2,
  ix_document IN XMLType,
  iv_error_type IN VARCHAR2 default '00')
is
  PRAGMA AUTONOMOUS_TRANSACTION;
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
begin
  fwk_i_mgt_entity.New(
    iv_entity_name => fwk_i_typ_asa_entity.gcAsaTrfImportError,
    iot_crud_definition => lt_crud_def,
    ib_initialize => TRUE);

  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'TIE_XML', p_XmlToClob(ix_document));
  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'TIE_ERR_MESSAGE', iv_error);
  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_ERROR_TYPE', iv_error_type);

  fwk_i_mgt_entity.InsertEntity(lt_crud_def);
  fwk_i_mgt_entity.Release(lt_crud_def);

  commit;

  exception
    when OTHERS then
      rollback;
      raise;
end;

procedure archive_message(
  in_record_id IN asa_record.asa_record_id%TYPE,
  it_msg_direction IN asa_typ_record_trf_def.T_ASA_TRF_MSG_DIRECTION,
  ix_document IN XMLType,
  iv_comment IN VARCHAR2 default null)
is
begin
  asa_prc_record_trf_adm.archive_message(
    in_record_id => in_record_id,
    in_message_id => null,
    it_msg_direction => it_msg_direction,
    ix_document => ix_document,
    iv_comment => iv_comment);
end;
procedure archive_message(
  in_record_id IN asa_record.asa_record_id%TYPE,
  in_message_id IN NUMBER,
  it_msg_direction IN asa_typ_record_trf_def.T_ASA_TRF_MSG_DIRECTION,
  ix_document IN XMLType,
  iv_comment IN VARCHAR2 default null)
is
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  lt_envelope asa_typ_record_trf_def.T_ENVELOPE;
begin
  asa_lib_record_trf_rec.load_envelope(
    ix_document => ix_document,
    iot_envelope => lt_envelope,
    ib_fragment => FALSE);

  fwk_i_mgt_entity.New(
    iv_entity_name => fwk_i_typ_asa_entity.gcAsaRecordMsgArch,
    iot_crud_definition => lt_crud_def,
    ib_initialize => TRUE);

  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ASA_RECORD_ID', in_record_id);
  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARM_MESSAGE_NUMBER', lt_envelope.message.message_number);
  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARM_MESSAGE_PAYLOAD', p_XmlToClob(ix_document));
  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_ASA_TRF_MSG_TYPE', lt_envelope.message.message_type);
  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_ASA_TRF_MSG_DIRECTION', it_msg_direction);
  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARM_SRC_SCHEMA_NAME', lt_envelope.sender.schema_name);
  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARM_SRC_INSTANCE_NAME', lt_envelope.sender.instance_name);
  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARM_DST_SCHEMA_NAME', lt_envelope.recipient.schema_name,
    lt_envelope.recipient.schema_name is not null);
  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARM_DST_INSTANCE_NAME', lt_envelope.recipient.instance_name,
    lt_envelope.recipient.instance_name is not null);
  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PC_QUEUE_MESSAGE_ID', in_message_id,
    in_message_id is not null and in_message_id > 0.0);
  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARM_COMMENT', iv_comment,
    RTrim(iv_comment,' '||Chr(13)||Chr(10)) is not null);

  fwk_i_mgt_entity.InsertEntity(lt_crud_def);
  fwk_i_mgt_entity.Release(lt_crud_def);
end;

END ASA_PRC_RECORD_TRF_ADM;
