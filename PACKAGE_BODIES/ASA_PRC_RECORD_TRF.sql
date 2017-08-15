--------------------------------------------------------
--  DDL for Package Body ASA_PRC_RECORD_TRF
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_PRC_RECORD_TRF" 
/**
 * Gestion de la circulation de dossiers SAV.
 *
 * @version 1.0
 * @date 04/2012
 * @author spfister
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
AS

  TYPE tt_archive_list IS TABLE OF asa_record_msg_arch%ROWTYPE;

--
-- Internal methods
--

/**
 * Mise à jour des statuts du dossier à la réception d'un document.
 * @param in_record_id  Identifiant du dossier.
 * @param it_envelope Informations de l'envoi
 * @throws EXCEPTION_RECALL_RECORD
 */
procedure p_update_status_receive(
  in_record_id IN asa_record.asa_record_id%TYPE,
  it_envelope IN asa_typ_record_trf_def.T_ENVELOPE)
is
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
begin
  fwk_i_mgt_entity.New(
    iv_entity_name => fwk_i_typ_asa_entity.gcAsaRecord,
    iot_crud_definition => lt_crud_def,
    ib_initialize => TRUE,
    in_main_id => in_record_id);

  case it_envelope.message.message_type
    when asa_typ_record_trf_def.TRF_MSG_TYPE_SEND then
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_LOCALLY_OWNED', 1);

    when asa_typ_record_trf_def.TRF_MSG_TYPE_RESPONSE then
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_ASA_TRF_RECALL_FROM_SRC', asa_typ_record_trf_def.TRF_RECALL_NONE);
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_ASA_TRF_RECALL_ON_DST', asa_typ_record_trf_def.TRF_RECALL_NONE);
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_LOCALLY_OWNED', 1);
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_RECALLER', 0);
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_TRF_COMPLETED', 1);

    when asa_typ_record_trf_def.TRF_MSG_TYPE_SEND_LOOP then
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_LOCALLY_OWNED', 1);
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_ASA_TRF_LOOP_STATUS', asa_typ_record_trf_def.TRF_LOOP_END);

    when asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL then
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_ASA_TRF_RECALL_FROM_SRC', asa_typ_record_trf_def.TRF_RECALL_REQUEST);
      if (not fwk_i_mgt_entity_data.IsNull(lt_crud_def, 'ARE_DST_SCHEMA_NAME') and
          not fwk_i_mgt_entity_data.GetColumnBoolean(lt_crud_def, 'ARE_RECALLER')) then
        fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_ASA_TRF_RECALL_ON_DST', asa_typ_record_trf_def.TRF_RECALL_REQUEST);
      end if;
      if (it_envelope.comment is not null) then
        fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_TRF_RECALL_COMMENT', it_envelope.comment);
      end if;

    when asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL_ACCEPTED then
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_ASA_TRF_RECALL_ON_DST', asa_typ_record_trf_def.TRF_RECALL_APPROVED);
      if (not fwk_i_mgt_entity_data.IsNull(lt_crud_def, 'ARE_SRC_NUMBER') and
          not fwk_i_mgt_entity_data.GetColumnBoolean(lt_crud_def, 'ARE_RECALLER')) then
        fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_ASA_TRF_RECALL_FROM_SRC', asa_typ_record_trf_def.TRF_RECALL_APPROVED);
      else
        fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_LOCALLY_OWNED', 1);
      end if;
      if (it_envelope.comment is not null) then
        fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_TRF_RECALL_COMMENT', it_envelope.comment);
      end if;

    when asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL_REFUSED then
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_ASA_TRF_RECALL_FROM_SRC', asa_typ_record_trf_def.TRF_RECALL_NONE);
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_ASA_TRF_RECALL_ON_DST', asa_typ_record_trf_def.TRF_RECALL_NONE);
      if (it_envelope.comment is not null) then
        fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_TRF_RECALL_COMMENT', it_envelope.comment);
      end if;

    when asa_typ_record_trf_def.TRF_MSG_TYPE_CALLBACK then
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_ASA_TRF_RECALL_FROM_SRC', asa_typ_record_trf_def.TRF_RECALL_NONE);
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_ASA_TRF_RECALL_ON_DST', asa_typ_record_trf_def.TRF_RECALL_NONE);
      if (fwk_i_mgt_entity_data.IsNull(lt_crud_def, 'ARE_DST_SCHEMA_NAME')) then
        fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_LOCALLY_OWNED', 1);
      end if;

    when asa_typ_record_trf_def.TRF_MSG_TYPE_NOTIFY_CHANGES then
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_LOCALLY_OWNED', 1);

    else
      null;
  end case;

  -- mise à jour uniquement si des colonnes ont été modifiées
  if (lt_crud_def.column_list.COUNT > 0) then
    fwk_i_mgt_entity.UpdateEntity(lt_crud_def);
  end if;

  fwk_i_mgt_entity.Release(lt_crud_def);

  exception
    when OTHERS then
      fwk_i_mgt_exception.raise_exception(
        in_error_code => asa_typ_record_trf_def.EXCEPTION_RECALL_RECORD_NO,
        iv_message => 'Error on recall after sales record'||Chr(10)||sqlerrm,
        iv_stack_trace => dbms_utility.format_error_backtrace);
end;

/**
 * Mise à jour des statuts du dossier à l'envoi d'un document.
 * @param in_record_id  Identifiant du dossier.
 * @parma it_msg_type  Type du message.
 */
procedure p_update_status_send(
  in_record_id IN asa_record.asa_record_id%TYPE,
  it_msg_type IN asa_typ_record_trf_def.T_ASA_TRF_MSG_TYPE)
is
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
begin
  fwk_i_mgt_entity.New(
    iv_entity_name => fwk_i_typ_asa_entity.gcAsaRecord,
    iot_crud_definition => lt_crud_def,
    ib_initialize => FALSE,
    in_main_id => in_record_id);

  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_ASA_TRF_RECALL_ON_DST', asa_typ_record_trf_def.TRF_RECALL_NONE);

  case it_msg_type
    when asa_typ_record_trf_def.TRF_MSG_TYPE_SEND then
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_LOCALLY_OWNED', 0);

    when asa_typ_record_trf_def.TRF_MSG_TYPE_CALLBACK then
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_LOCALLY_OWNED', 0);

    when asa_typ_record_trf_def.TRF_MSG_TYPE_RESPONSE then
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_LOCALLY_OWNED', 0);
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_TRF_COMPLETED', 1);

    when asa_typ_record_trf_def.TRF_MSG_TYPE_SEND_LOOP then
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_LOCALLY_OWNED', 0);
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_ASA_TRF_LOOP_STATUS', asa_typ_record_trf_def.TRF_LOOP_BEGIN);

    when asa_typ_record_trf_def.TRF_MSG_TYPE_NOTIFY_CHANGES then
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_LOCALLY_OWNED', 0);

    else
      null;
  end case;

  fwk_i_mgt_entity.UpdateEntity(lt_crud_def);
  fwk_i_mgt_entity.Release(lt_crud_def);
end;

/**
 * Envoi le document Xml d'un dossier SAV.
 * @param in_record_id  Identifiant du dossier.
 * @parma it_msg_type  Type du message.
 * @param it_msg_recipient  Direction d'envoi du message.
 * @return le status d'envoi du document.
 */
function p_send_record(
  in_record_id IN asa_record.asa_record_id%TYPE,
  it_msg_type IN asa_typ_record_trf_def.T_ASA_TRF_MSG_TYPE,
  it_msg_recipient IN asa_typ_record_trf_def.T_ASA_TRF_MSG_RECIPIENT default asa_typ_record_trf_def.TRF_RECIPIENT_DST)
  return BOOLEAN
is
  ln_message_id NUMBER;
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
begin
  -- pour la plupart des messages à envoyer, il faut s'assurer que
  -- le dossier a déjà été envoyé.
  if (it_msg_type in (asa_typ_record_trf_def.TRF_MSG_TYPE_RESPONSE,
                      asa_typ_record_trf_def.TRF_MSG_TYPE_CALLBACK,
                      asa_typ_record_trf_def.TRF_MSG_TYPE_SEND_LOOP,
                      asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL,
                      asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL_ACCEPTED,
                      asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL_REFUSED,
                      asa_typ_record_trf_def.TRF_MSG_TYPE_STATE,
                      asa_typ_record_trf_def.TRF_MSG_TYPE_STATUS_CHANGED,
                      asa_typ_record_trf_def.TRF_MSG_TYPE_NOTIFY_CHANGES)) then
    -- est-ce que le dossier a déjà été envoyé
    -- ou
    -- est-ce que le dossier est issu d'un transfert
    if (asa_lib_record_trf.is_record_received(in_record_id) = 0 and
        asa_lib_record_trf.is_record_sended(in_record_id) = 0) then
      -- en cas d'échec, pas d'envoi et pas de message ni d'erreur
      return FALSE;
    end if;
  end if;

  -- envoi différend pour les mises à jour
  if (it_msg_type in (asa_typ_record_trf_def.TRF_MSG_TYPE_STATE,
                      asa_typ_record_trf_def.TRF_MSG_TYPE_STATUS_CHANGED,
                      asa_typ_record_trf_def.TRF_MSG_TYPE_NOTIFY_CHANGES)) then
    asa_prc_record_trf_adm.send_record_notify_updates(
      in_record_id => in_record_id,
      it_msg_type => it_msg_type,
      it_msg_recipient => it_msg_recipient);
  else
    ln_message_id := asa_prc_record_trf_adm.send_record(
      in_record_id => in_record_id,
      it_msg_type => it_msg_type);
  end if;

  -- le renvoi de dossier ou l'envoi d'une mise à jour de doit pas modifier
  -- le dossier, sauf pour les notifications de changement
  if (it_msg_type not in (asa_typ_record_trf_def.TRF_MSG_TYPE_STATE,
                          asa_typ_record_trf_def.TRF_MSG_TYPE_STATUS_CHANGED)) then
    -- mise à jour des statuts du dossier
    p_update_status_send(in_record_id, it_msg_type);
  end if;

  asa_prc_record_trf.update_archived_msg_arrived;

  return TRUE;
end;


--
-- public methods
--

function transfer_record(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return BOOLEAN
is
begin
  -- mise à jour des informations de l'expéditeur
  asa_prc_record_trf_adm.update_record_sender(
    in_record_id => in_record_id);
  -- mise à jour des informations du destinataire
  asa_prc_record_trf_adm.update_record_recipient(
    in_record_id => in_record_id);

  -- envoi du dossier
  return p_send_record(in_record_id, asa_typ_record_trf_def.TRF_MSG_TYPE_SEND);
end;

function return_record(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return BOOLEAN
is
begin
  return p_send_record(in_record_id, asa_typ_record_trf_def.TRF_MSG_TYPE_RESPONSE);
end;

function transfer_loop_record(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return BOOLEAN
is
begin
  return p_send_record(in_record_id, asa_typ_record_trf_def.TRF_MSG_TYPE_SEND_LOOP);
end;

function callback_record(
  in_record_id IN asa_record.asa_record_id%TYPE,
  iv_explanation IN VARCHAR2)
  return BOOLEAN
is
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
begin
  fwk_i_mgt_entity.New(
    iv_entity_name => fwk_i_typ_asa_entity.gcAsaRecord,
    iot_crud_definition => lt_crud_def,
    ib_initialize => TRUE,
    in_main_id => in_record_id);

  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_RECALLER', 0);

  -- mise à jour du commentaire de fin du rappel
  if (iv_explanation is not null) then
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_TRF_RECALL_COMMENT',
      asa_prc_record_trf_extension.format_explanation(in_record_id, iv_explanation) ||Chr(10)||
      fwk_i_mgt_entity_data.GetColumnVARCHAR2(lt_crud_def, 'ARE_TRF_RECALL_COMMENT')
    );
  end if;

  fwk_i_mgt_entity.UpdateEntity(lt_crud_def);
  fwk_i_mgt_entity.Release(lt_crud_def);

  return p_send_record(in_record_id, asa_typ_record_trf_def.TRF_MSG_TYPE_CALLBACK);
end;

procedure recall_record(
  in_record_id IN asa_record.asa_record_id%TYPE,
  iv_reason IN VARCHAR2)
is
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
begin
  fwk_i_lib_utils.check_argument('IV_REASON', iv_reason);

  -- mise à jour des statuts du dossier
  fwk_i_mgt_entity.New(
    iv_entity_name => fwk_i_typ_asa_entity.gcAsaRecord,
    iot_crud_definition => lt_crud_def,
    ib_initialize => TRUE,
    in_main_id => in_record_id);

  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_ASA_TRF_RECALL_ON_DST', asa_typ_record_trf_def.TRF_RECALL_REQUEST);
  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_RECALLER', 1);
  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_TRF_RECALL_COMMENT',
    asa_prc_record_trf_extension.format_explanation(in_record_id, iv_reason) ||Chr(10)||
    fwk_i_mgt_entity_data.GetColumnVARCHAR2(lt_crud_def, 'ARE_TRF_RECALL_COMMENT')
  );

  fwk_i_mgt_entity.UpdateEntity(lt_crud_def);
  fwk_i_mgt_entity.Release(lt_crud_def);

  -- envoi de la demande de rappel
  asa_prc_record_trf_adm.send_record_recall_action(
    in_record_id => in_record_id,
    it_msg_type => asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL);

  asa_prc_record_trf.update_archived_msg_arrived;
end;

procedure p_internal_recall_response(
  in_record_id IN asa_record.asa_record_id%TYPE,
  it_msg_type IN asa_typ_record_trf_def.T_ASA_TRF_MSG_TYPE,
  iv_explanation IN VARCHAR2,
  ib_update_state IN BOOLEAN)
is
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
begin
  -- mise à jour des statuts du dossier
  fwk_i_mgt_entity.New(
    iv_entity_name => fwk_i_typ_asa_entity.gcAsaRecord,
    iot_crud_definition => lt_crud_def,
    ib_initialize => TRUE,
    in_main_id => in_record_id);

  if (ib_update_state) then
    case it_msg_type
      when asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL_ACCEPTED then
        fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_ASA_TRF_RECALL_FROM_SRC', asa_typ_record_trf_def.TRF_RECALL_APPROVED);
        fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_LOCALLY_OWNED', 0);

      when asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL_REFUSED then
        fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_ASA_TRF_RECALL_FROM_SRC', asa_typ_record_trf_def.TRF_RECALL_NONE);

    end case;
  end if;

  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARE_TRF_RECALL_COMMENT',
    asa_prc_record_trf_extension.format_explanation(in_record_id, iv_explanation) ||Chr(10)||
    fwk_i_mgt_entity_data.GetColumnVARCHAR2(lt_crud_def, 'ARE_TRF_RECALL_COMMENT')
  );

  fwk_i_mgt_entity.UpdateEntity(lt_crud_def);
  fwk_i_mgt_entity.Release(lt_crud_def);

  -- envoi de la réponse
  asa_prc_record_trf_adm.send_record_recall_action(
    in_record_id => in_record_id,
    it_msg_type => it_msg_type);

  asa_prc_record_trf.update_archived_msg_arrived;
end;

procedure recall_record_response(
  in_record_id IN asa_record.asa_record_id%TYPE,
  it_msg_type IN asa_typ_record_trf_def.T_ASA_TRF_MSG_TYPE,
  iv_explanation IN VARCHAR2)
is
begin
  if (it_msg_type not in (asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL_ACCEPTED,
                          asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL_REFUSED)) then
    fwk_i_mgt_exception.raise_exception(
      in_error_code => fwk_i_typ_definition.EXCEPTION_INVALID_ARGUMENT_NO,
      iv_message => 'IT_MSG_TYPE was out of the range of valid values ('||it_msg_type||').',
      iv_stack_trace => dbms_utility.format_error_backtrace);
  elsif (it_msg_type = asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL_REFUSED) then
    fwk_i_lib_utils.check_argument('IV_EXPLANATION', iv_explanation);
  end if;

  p_internal_recall_response(in_record_id, it_msg_type, iv_explanation, TRUE);
end;


function p_send_state(
  in_record_id IN asa_record.asa_record_id%TYPE,
  it_msg_type IN asa_typ_record_trf_def.T_ASA_TRF_MSG_TYPE,
  it_recipient_src in asa_typ_record_trf_def.T_ASA_TRF_MSG_RECIPIENT,
  it_recipient_dst in asa_typ_record_trf_def.T_ASA_TRF_MSG_RECIPIENT)
  return BOOLEAN
is
  lb_send_src BOOLEAN := FALSE;
  lb_send_dst BOOLEAN := FALSE;
begin
  if (asa_prc_record_trf_extension.control_transfert(in_record_id) > 0) then
    -- la propagation des changements du dossier doit se faire
    -- dans toutes les directions disponibles
    if (it_recipient_src != asa_typ_record_trf_def.TRF_RECIPIENT_NONE and
        asa_lib_record_trf.can_reply(in_record_id) = 1) then
      lb_send_src := p_send_record(in_record_id, it_msg_type, it_recipient_src);
    end if;
    if (it_recipient_dst != asa_typ_record_trf_def.TRF_RECIPIENT_NONE and
        asa_lib_record_trf.can_forward(in_record_id) = 1) then
      lb_send_dst := p_send_record(in_record_id, it_msg_type, it_recipient_dst);
    end if;
  end if;
  return lb_send_src or lb_send_dst;
end;

function send_record_state(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return BOOLEAN
is
begin
  -- la propagation des changements du dossier doit se faire
  -- dans toutes les directions disponibles
  return p_send_state(in_record_id,
    asa_typ_record_trf_def.TRF_MSG_TYPE_STATE,
    asa_typ_record_trf_def.TRF_RECIPIENT_SRC, asa_typ_record_trf_def.TRF_RECIPIENT_DST);
--
--   if (asa_prc_record_trf_extension.control_transfert(in_record_id) > 0) then
--     -- la propagation des changements du dossier doit se faire
--     -- dans toutes les directions disponibles
--     if (asa_lib_record_trf.can_reply(in_record_id) = 1) then
--       p_send_record(in_record_id, asa_typ_record_trf_def.TRF_MSG_TYPE_STATE, asa_typ_record_trf_def.TRF_RECIPIENT_SRC);
--     end if;
--     if (asa_lib_record_trf.can_forward(in_record_id) = 1) then
--       p_send_record(in_record_id, asa_typ_record_trf_def.TRF_MSG_TYPE_STATE, asa_typ_record_trf_def.TRF_RECIPIENT_DST);
--     end if;
--   end if;
end;

function send_record_status_changed(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return BOOLEAN
is
begin
  -- la propagation des changements du dossier doit se faire
  -- dans toutes les directions disponibles
  return p_send_state(in_record_id,
    asa_typ_record_trf_def.TRF_MSG_TYPE_STATUS_CHANGED,
    asa_typ_record_trf_def.TRF_RECIPIENT_SRC, asa_typ_record_trf_def.TRF_RECIPIENT_DST);
--
--   if (asa_prc_record_trf_extension.control_transfert(in_record_id) > 0) then
--     -- la propagation des changements du dossier doit se faire
--     -- dans toutes les directions disponibles
--     if (asa_lib_record_trf.can_reply(in_record_id) = 1) then
--       p_send_record(in_record_id, asa_typ_record_trf_def.TRF_MSG_TYPE_STATUS_CHANGED, asa_typ_record_trf_def.TRF_RECIPIENT_SRC);
--     end if;
--     if (asa_lib_record_trf.can_forward(in_record_id) = 1) then
--       p_send_record(in_record_id, asa_typ_record_trf_def.TRF_MSG_TYPE_STATUS_CHANGED, asa_typ_record_trf_def.TRF_RECIPIENT_DST);
--     end if;
--   end if;
end;

function send_record_notify_changes(
  in_record_id IN asa_record.asa_record_id%TYPE,
  it_msg_recipient IN asa_typ_record_trf_def.T_ASA_TRF_MSG_RECIPIENT)
  return BOOLEAN
is
begin
  if (asa_prc_record_trf_extension.control_transfert(in_record_id) > 0) then
    return p_send_record(in_record_id, asa_typ_record_trf_def.TRF_MSG_TYPE_NOTIFY_CHANGES, it_msg_recipient);
  end if;
  return FALSE;
end;


procedure receive_records
is
  PRAGMA AUTONOMOUS_TRANSACTION;
  ln_msg_id NUMBER;
  lx_document XMLType;
  ln_record_id asa_record.asa_record_id%TYPE;
  lt_exception fwk_i_mgt_exception.T_EXCEPTION;
begin
  loop
    -- dequeue
    ln_msg_id := asa_prc_record_trf_adm.receive_record(
      ox_document => lx_document);
    exit when ln_msg_id is null;

    begin
      -- import
      asa_prc_record_trf.receive_record(
        ix_document => lx_document,
        on_record_id => ln_record_id);

      exception
        when asa_typ_record_trf_def.EXCEPTION_RECORD_COMPLETED then
          null;
        when OTHERS then
          lt_exception.message := sqlerrm;
          lt_exception.error_code := sqlcode;
          lt_exception.stack_trace := fwk_i_lib_trace.call_stack;
          lt_exception.cause := 'receive_records';
          lt_exception.exception_type := fwk_i_mgt_exception.FATAL;
          rollback;
          asa_prc_record_trf_adm.log_import_error(
            iv_error => fwk_i_mgt_exception.to_string(lt_exception),
            ix_document => lx_document);
    end;
    asa_prc_record_trf_adm.release_record(
      in_message_id => ln_msg_id);
    commit;
  end loop;

  asa_prc_record_trf.update_archived_msg_arrived;
end;


procedure p_auto_forward(
  it_envelope IN asa_typ_record_trf_def.T_ENVELOPE,
  in_record_id IN asa_record.asa_record_id%TYPE)
is
  ln_tmp NUMBER;
  lb_tmp BOOLEAN;
  lv_msg_type asa_typ_record_trf_def.T_ASA_TRF_MSG_TYPE := asa_typ_record_trf_def.TRF_MSG_TYPE_NONE;
  lt_msg_recipient asa_typ_record_trf_def.T_ASA_TRF_MSG_RECIPIENT := asa_typ_record_trf_def.TRF_RECIPIENT_NONE;
begin
  lt_msg_recipient := asa_lib_record_trf.get_recall_binding(
    iv_number => it_envelope.message.are_number);
  if (lt_msg_recipient = asa_typ_record_trf_def.TRF_RECIPIENT_NONE) then
    -- sortie anticipée, pas d'envoi automatique
    return;
  end if;


  -- détection du type de message
  lv_msg_type := it_envelope.message.message_type;

  if (lv_msg_type = asa_typ_record_trf_def.TRF_MSG_TYPE_CALLBACK) then
    -- envoi l'état courant du dossier local
    ln_tmp := asa_prc_record_trf_adm.send_record(
      in_record_id => in_record_id,
      it_msg_type => lv_msg_type);

  elsif (lv_msg_type = asa_typ_record_trf_def.TRF_MSG_TYPE_STATE) then
    lb_tmp := p_send_state(in_record_id,
      asa_typ_record_trf_def.TRF_MSG_TYPE_STATE,
      -- société source
      case it_envelope.message.are_number_matching_mode
        when asa_typ_record_trf_def.TRF_RECIPIENT_SRC then asa_typ_record_trf_def.TRF_RECIPIENT_SRC
        else asa_typ_record_trf_def.TRF_RECIPIENT_NONE
      end,
      -- société destination
      case it_envelope.message.are_number_matching_mode
        when asa_typ_record_trf_def.TRF_RECIPIENT_DST then asa_typ_record_trf_def.TRF_RECIPIENT_DST
        else asa_typ_record_trf_def.TRF_RECIPIENT_NONE
      end
    );

  elsif (lv_msg_type = asa_typ_record_trf_def.TRF_MSG_TYPE_STATUS_CHANGED) then
    lb_tmp := p_send_state(in_record_id,
      asa_typ_record_trf_def.TRF_MSG_TYPE_STATUS_CHANGED,
      -- société source
      case it_envelope.message.are_number_matching_mode
        when asa_typ_record_trf_def.TRF_RECIPIENT_SRC then asa_typ_record_trf_def.TRF_RECIPIENT_SRC
        else asa_typ_record_trf_def.TRF_RECIPIENT_NONE
      end,
      -- société destination
      case it_envelope.message.are_number_matching_mode
        when asa_typ_record_trf_def.TRF_RECIPIENT_DST then asa_typ_record_trf_def.TRF_RECIPIENT_DST
        else asa_typ_record_trf_def.TRF_RECIPIENT_NONE
      end
    );

  elsif (lv_msg_type = asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL) then
    -- envoi du document à faire suivre
    ln_tmp := asa_prc_record_trf_adm.send_document(
      in_record_id,
      -- génération du document Xml à faire suivre
      asa_lib_record_trf_xml.get_asa_record_switch_xml(
        it_msg_type => lv_msg_type,
        it_msg_recipient => asa_typ_record_trf_def.TRF_RECIPIENT_SRC,
        it_original => it_envelope)
    );

  elsif (lv_msg_type in (asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL_ACCEPTED,
                         asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL_REFUSED)) then
    -- envoi du document à faire suivre
    ln_tmp := asa_prc_record_trf_adm.send_document(
      in_record_id,
      -- génération du document Xml à faire suivre
      asa_lib_record_trf_xml.get_asa_record_switch_xml(
        it_msg_type => lv_msg_type,
        it_msg_recipient => asa_typ_record_trf_def.TRF_RECIPIENT_DST,
        it_original => it_envelope)
    );
  end if;
end;

procedure receive_record(
  ix_document IN XMLType,
  on_record_id OUT asa_record.asa_record_id%TYPE)
is
  lt_envelope asa_typ_record_trf_def.T_ENVELOPE;
  lv_msg_type asa_typ_record_trf_def.T_ASA_TRF_MSG_TYPE := asa_typ_record_trf_def.TRF_MSG_TYPE_NONE;
  lt_original_message asa_typ_record_trf_def.T_MESSAGE;
begin
  -- chargement de l'enveloppe
  asa_lib_record_trf_rec.load_envelope(
    ix_document => ix_document,
    iot_envelope => lt_envelope,
    ib_fragment => FALSE);

  -- détection du type de message
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
        ix_document => ix_document,
        it_origin => asa_lib_record_trf.decode_origin(lt_envelope.message.are_number_matching_mode))) then
      raise asa_typ_record_trf_def.EXCEPTION_RECORD_COMPLETED;
    end if;
  end if;

  -- exécution du traitement correspondant au type de message
  if (lv_msg_type in (asa_typ_record_trf_def.TRF_MSG_TYPE_SEND,
                      asa_typ_record_trf_def.TRF_MSG_TYPE_RESPONSE,
                      asa_typ_record_trf_def.TRF_MSG_TYPE_CALLBACK,
                      asa_typ_record_trf_def.TRF_MSG_TYPE_SEND_LOOP,
                      asa_typ_record_trf_def.TRF_MSG_TYPE_NOTIFY_CHANGES)) then
    asa_prc_record_trf_adm.import_record(
      ix_document => ix_document,
      on_record_id => on_record_id);
    p_update_status_receive(on_record_id, lt_envelope);

  elsif (lv_msg_type in (asa_typ_record_trf_def.TRF_MSG_TYPE_STATE,
                         asa_typ_record_trf_def.TRF_MSG_TYPE_STATUS_CHANGED)) then
    asa_prc_record_trf_adm.import_record(
      ix_document => ix_document,
      on_record_id => on_record_id);

  elsif (lv_msg_type = asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL) then
    on_record_id := asa_lib_record_trf.get_record_id(
      iv_number => lt_envelope.message.are_number,
      it_origin => asa_typ_record_trf_def.TRF_RECORD_SRC_NUMBER);
    if (asa_lib_record_trf.get_recall_status(on_record_id) = asa_typ_record_trf_def.TRF_RECALL_NONE) then
      p_update_status_receive(on_record_id, lt_envelope);
      asa_prc_record_trf_adm.archive_message(
        in_record_id => on_record_id,
        it_msg_direction => asa_typ_record_trf_def.TRF_MSG_RECEIVE,
        ix_document => ix_document);
    else
      --
      p_internal_recall_response(
        on_record_id, asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL_REFUSED,
        -- concaténation du commentaire de la demande de rappel
        -- avec la réponse automatique
        Replace(pcs.pc_functions.TranslateWord('Rappel rejeté par <DST> à cause d''une demande de rappel en cours'), '<DST>', '"'||pcs.PC_I_LIB_SESSION.GetComName||'"') ||
        case when (lt_envelope.comment is not null) then Chr(10)||lt_envelope.comment end,
        FALSE);
    end if;

  elsif (lv_msg_type in (asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL_ACCEPTED,
                         asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL_REFUSED)) then
    on_record_id := asa_lib_record_trf.get_record_id(
      iv_number => lt_envelope.message.are_number,
      it_origin => asa_typ_record_trf_def.TRF_RECORD_NUMBER);
    p_update_status_receive(on_record_id, lt_envelope);
    asa_prc_record_trf_adm.archive_message(
      in_record_id => on_record_id,
      it_msg_direction => asa_typ_record_trf_def.TRF_MSG_RECEIVE,
      ix_document => ix_document);

  elsif (lv_msg_type = asa_typ_record_trf_def.TRF_MSG_TYPE_TREATED) then
    lt_original_message := lt_envelope.original_message;
    case
      when lt_original_message.message_type in (asa_typ_record_trf_def.TRF_MSG_TYPE_SEND,
                                                asa_typ_record_trf_def.TRF_MSG_TYPE_SEND_LOOP) then
        on_record_id := asa_lib_record_trf.get_record_id(
          iv_number => lt_original_message.are_number,
          it_origin => asa_typ_record_trf_def.TRF_RECORD_NUMBER);
      when (lt_original_message.message_type = asa_typ_record_trf_def.TRF_MSG_TYPE_RESPONSE) then
        on_record_id := asa_lib_record_trf.get_record_id(
          iv_number => lt_original_message.are_number,
          it_origin => asa_typ_record_trf_def.TRF_RECORD_SRC_NUMBER);
    end case;
    asa_prc_record_trf_adm.archive_message(
      in_record_id => on_record_id,
      it_msg_direction => asa_typ_record_trf_def.TRF_MSG_RECEIVE,
      ix_document => ix_document);

  end if;

  -- sortie si le document n'est pas un message technique ou un retour
  if (lv_msg_type in (asa_typ_record_trf_def.TRF_MSG_TYPE_SEND,
                      asa_typ_record_trf_def.TRF_MSG_TYPE_SEND_LOOP,
                      asa_typ_record_trf_def.TRF_MSG_TYPE_RESPONSE,
                      asa_typ_record_trf_def.TRF_MSG_TYPE_NOTIFY_CHANGES,
                      asa_typ_record_trf_def.TRF_MSG_TYPE_TREATED)) then
    return;
  end if;

  -- gestion du transfert automatique
  p_auto_forward(lt_envelope, on_record_id);
end;

function receive_record_error(
  it_document IN CLOB,
  ov_message OUT NOCOPY VARCHAR2)
  return INTEGER
is
  lx_document XMLType;
  ln_record_id asa_record.asa_record_id%TYPE;
begin
  lx_document := XMLType(it_document);

  asa_prc_record_trf.receive_record(
    ix_document => lx_document,
    on_record_id => ln_record_id);

  commit;
  return 1;

  exception
    when asa_typ_record_trf_def.EXCEPTION_RECORD_COMPLETED then
      rollback;
      return 1;
    when OTHERS then
      ov_message := sqlerrm;
      rollback;
      return 0;
end;


procedure MessageTransfertFlow(
  in_record_id IN asa_record.asa_record_id%TYPE,
  ov_warning_message OUT NOCOPY VARCHAR2)
is
  ln_exists NUMBER;
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  lv_StatusFrom asa_record.c_asa_rep_status%TYPE;
  lv_StatusTo asa_record.c_asa_rep_status%TYPE;
  ln_LastRecordId asa_record_events.asa_record_events_id%TYPE;
  lv_MsgType asa_record_msg_src_flow.c_asa_trf_msg_type%TYPE;
  lv_MsgRecipient asa_record_msg_src_flow.c_asa_trf_msg_recipient%TYPE;
  lv_proc_before VARCHAR2(32767);
  lv_proc_after VARCHAR2(32767);
  lt_exception fwk_i_mgt_exception.T_EXCEPTION;
  lv_savepoint fwk_i_typ_definition.UNIQUE_DATA;
  lb_xml_sended BOOLEAN;
begin
  ov_warning_message := null;

  -- vérification si une des deux conditions est remplie :
  --   o le fournisseur est renseigné comme destinataire
  --   o le client est renseigné comme source
  select Count(*)
  into ln_exists
  from DUAL
  where Exists(select 1 from ASA_RECORD_TRF_DEST D, ASA_RECORD R
               where R.ASA_RECORD_ID = in_record_id and
                 D.PAC_SUPPLIER_PARTNER_ID = R.PAC_SUPPLIER_PARTNER_ID)
        or
        Exists(select 1 from ASA_RECORD_TRF_SRC D, ASA_RECORD R
               where R.ASA_RECORD_ID = in_record_id and
                 D.PAC_CUSTOM_PARTNER_ID = R.PAC_CUSTOM_PARTNER_ID);
  if (ln_exists = 0) then
    return;
  end if;

  -- récupérer les deux derniers enregistrement des événements du dossier courant
  begin
    select STATUS_FROM
         , STATUS_TO
         , ASA_RECORD_EVENTS_ID
      into lv_StatusFrom
         , lv_StatusTo
         , ln_LastRecordId
      from (select lag(C_ASA_REP_STATUS) over(partition by ASA_RECORD_ID order by rre_seq) STATUS_FROM
                 , last_value(C_ASA_REP_STATUS) over(partition by ASA_RECORD_ID) STATUS_TO
                 , RRE.ASA_RECORD_EVENTS_ID
              from ASA_RECORD_EVENTS RRE
             where RRE.ASA_RECORD_ID = in_record_id
          order by RRE.RRE_SEQ desc)
     where rownum = 1;

    exception
      -- sortie anticipé si aucun événement
      when NO_DATA_FOUND then
        return;
  end;

  -- les valeurs des deux status sont obligatoires pour pouvoir continuer
  if (lv_StatusFrom is null or lv_StatusTo is null) then
    return;
  end if ;

  begin
    -- récupérer les informations de l'étape du flux correspondant aux statuts
    select C_ASA_TRF_MSG_TYPE
         , C_ASA_TRF_MSG_RECIPIENT
         , ASF_BEFORE_TRF_STORED_PROC
         , ASF_AFTER_TRF_STORED_PROC
      into lv_MsgType
         , lv_MsgRecipient
         , lv_proc_before
         , lv_proc_after
      from ASA_RECORD_MSG_SRC_FLOW
     where C_ASA_REP_STATUS_FROM = lv_StatusFrom
       and C_ASA_REP_STATUS_TO = lv_StatusTo;

    exception
      -- sotie anticipée si aucune action configurée
      when NO_DATA_FOUND then
        return;
  end;

  -- traitement particulier pour les mise à jour intermédiaire
  if (lv_MsgType = asa_typ_record_trf_def.TRF_MSG_TYPE_NOTIFY_CHANGES and
      lv_MsgRecipient is not null) then
    if (lv_MsgRecipient = asa_typ_record_trf_def.TRF_RECIPIENT_SRC and
        asa_lib_record_trf.can_reply(in_record_id) = 1) then
      -- l'action est prévue pour la source et
      -- le dossier peut être envoyé à un expéditeur
      null;
    elsif (lv_MsgRecipient = asa_typ_record_trf_def.TRF_RECIPIENT_DST and
           asa_lib_record_trf.can_forward(in_record_id) = 1) then
      -- l'action est prévue pour la destination et
      -- le dossier peut être envoyé à un destinataire
      null;
    else
      -- sortie anticipée, car aucun destinataire n'est prévu
      return;
    end if;
  end if;

  if (lv_proc_before is not null) then
    -- exécution de la procédure avant envoi
    execute immediate
      'BEGIN '||
        lv_proc_before||'(:in_record_id); ' ||
      'END;'
      using in in_record_id;
  end if;

  -- branchement pour la procédure d'envoi du dossier à exécuter
  lb_xml_sended := FALSE;
  case lv_MsgType

    -- Envoi du dossier
    when asa_typ_record_trf_def.TRF_MSG_TYPE_SEND then
      lb_xml_sended := asa_prc_record_trf.transfer_record(in_record_id);

    -- Envoi du dossier en retour, signifie la fin du traitement
    when asa_typ_record_trf_def.TRF_MSG_TYPE_RESPONSE then
      lb_xml_sended := asa_prc_record_trf.return_record(in_record_id);

    --when '003' then -- Rappel terminé

    -- Renvoi du dossier
    when asa_typ_record_trf_def.TRF_MSG_TYPE_SEND_LOOP then
      lb_xml_sended := asa_prc_record_trf.transfer_loop_record(in_record_id);

    -- Envoi de l'état du dossier
    when asa_typ_record_trf_def.TRF_MSG_TYPE_STATE then
      lb_xml_sended := asa_prc_record_trf.send_record_state(in_record_id);

    -- Envoi de l'état du dossier après un changement de statut
    when asa_typ_record_trf_def.TRF_MSG_TYPE_STATUS_CHANGED then
      lb_xml_sended := asa_prc_record_trf.send_record_status_changed(in_record_id);

    -- Envoi de l'état du dossier après un changement de statut
    -- et donne la main sur le dossier
    when asa_typ_record_trf_def.TRF_MSG_TYPE_NOTIFY_CHANGES then
      lb_xml_sended := asa_prc_record_trf.send_record_notify_changes(in_record_id, lv_MsgRecipient);

    --when '200' then -- Rappel
    --when '201' then -- Rappel accepté
    --when '202' then -- Rappel refusé
  end case;

  -- mise à jour des status du dossier
  if (lb_xml_sended) then
    fwk_i_mgt_entity.New(
      iv_entity_name => fwk_i_typ_asa_entity.gcAsaRecordEvents,
      iot_crud_definition => lt_crud_def,
      ib_initialize => FALSE,
      in_main_id => ln_LastRecordId);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'RRE_IS_EVENT_DELETABLE', 0);
    fwk_i_mgt_entity.UpdateEntity(lt_crud_def);
    fwk_i_mgt_entity.Release(lt_crud_def);
  end if;

  if (lv_proc_after is not null) then
    -- exécution de la procédure après envoi
    begin
      -- génération d'un point de récupération pour annulation
      -- partielle éventuelle de la transaction
      lv_savepoint := fwk_i_mgt_transaction.savepoint;

      execute immediate
        'BEGIN '||
          lv_proc_after ||'(:in_record_id) ;' ||
        'END;'
        using in in_record_id;

      exception
        -- en cas d'exception, le processus ne peut plus être interrompu,
        -- le document à déjà été envoyé.
        -- la seule chose possible de faire est de récupérer le message
        -- complet de l'exception et de le retourner à l'appelant
        when OTHERS then
          lt_exception.message := sqlerrm;
          lt_exception.error_code := sqlcode;
          lt_exception.stack_trace := fwk_i_lib_trace.call_stack;
          lt_exception.cause := 'receive_records';
          lt_exception.exception_type := fwk_i_mgt_exception.FATAL;
          fwk_i_mgt_transaction.rollback_savepoint(lv_savepoint);
          ov_warning_message := fwk_i_mgt_exception.to_string(lt_exception);
    end;
  end if;
end;


procedure update_archived_msg_arrived
is
  PRAGMA AUTONOMOUS_TRANSACTION;
  ltt_archive_list TT_ARCHIVE_LIST;
  lt_archive asa_record_msg_arch%ROWTYPE;
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  ltplQueueTrace SYS_REFCURSOR;
  ln_arrived NUMBER;
begin
  -- collect les éléments à traiter
  select *
  bulk collect into ltt_archive_list
  from ASA_RECORD_MSG_ARCH
  where (ARM_MSG_ON_DESTINATION is null or ARM_MSG_ON_DESTINATION = 0) and
    C_ASA_TRF_MSG_DIRECTION = '01'; -- envoyé
  if (ltt_archive_list is null or ltt_archive_list.COUNT = 0) then
    return;
  end if;

  fwk_i_mgt_entity.New(
    iv_entity_name => fwk_i_typ_asa_entity.gcAsaRecordMsgArch,
    iot_crud_definition => lt_crud_def);

  for cpt in ltt_archive_list.FIRST .. ltt_archive_list.LAST loop
    lt_archive := ltt_archive_list(cpt);
    -- utilisation d'un curseur pour éviter la gestion
    -- des exceptions NO_DATA_FOUND et TOO_MANY_ROWS
    open ltplQueueTrace for
      select decode(C_QUEUE_TRACE,'300',1,0) MSG_ARRIVED
        from PCS.PC_QUEUE_TRACE
       where C_QUEUE_TRACE IN ('300','301') -- transmission [failure] into inbox
         and PC_QUEUE_MESSAGE_ID = lt_archive.PC_QUEUE_MESSAGE_ID
      order by C_QUEUE_TRACE;
    fetch ltplQueueTrace into ln_arrived;
    if (ltplQueueTrace%FOUND) then
      fwk_i_mgt_entity.Load(lt_crud_def, lt_archive.ASA_RECORD_MSG_ARCH_ID);
      begin
        fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ARM_MSG_ON_DESTINATION', ln_arrived);
        fwk_i_mgt_entity.UpdateEntity(lt_crud_def);
        commit;

        exception
          when OTHERS then
            rollback;
      end;
      fwk_i_mgt_entity.Clear(lt_crud_def);
    end if;
    close ltplQueueTrace;
  end loop;

  fwk_i_mgt_entity.Release(lt_crud_def);
end;

procedure auto_accept_recall_request
is
  ltt_id asa_typ_record_trf_def.TT_ID;
  ln_id asa_record.asa_record_id%TYPE;
begin
  -- sélection des dossiers avec demande de rappel
  select ASA_RECORD_ID
  bulk collect into ltt_id
  from ASA_RECORD
  where C_ASA_TRF_RECALL_FROM_SRC = asa_typ_record_trf_def.TRF_RECALL_REQUEST and
        ARE_DST_SCHEMA_NAME is null;

  if (ltt_id is not null and ltt_id.COUNT > 0) then
    for cpt in ltt_id.FIRST .. ltt_id.LAST loop
      ln_id := ltt_id(cpt);
      -- si le dossier n'est pas verrouillé
      if (asa_prc_record_trf_lock.is_locked(ln_id) = 0) then
        begin
          -- verrouiller le dossier
          asa_prc_record_trf_lock.protect(ln_id);
          -- acceptation automatique du rappel
          asa_prc_record_trf.recall_record_response(
            in_record_id => ln_id,
            it_msg_type => asa_typ_record_trf_def.TRF_MSG_TYPE_RECALL_ACCEPTED,
            iv_explanation => 'automatic acceptance');
          -- libérer le dossier
          asa_prc_record_trf_lock.unprotect(ln_id);
        exception
          when OTHERS then
            -- en cas d'exception, il faut libérer le dossier et
            -- passer au dossier suivant.
            -- Il devra être traité au prochain passage
            asa_prc_record_trf_lock.unprotect(ln_id);
        end;
      end if;
    end loop;
  end if;
end;

END ASA_PRC_RECORD_TRF;
