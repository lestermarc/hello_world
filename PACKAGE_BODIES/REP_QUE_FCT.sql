--------------------------------------------------------
--  DDL for Package Body REP_QUE_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_QUE_FCT" 
/**
 * Procedures et fonctions de base pour la réplication de documents
 * inter sociétés par SolvaQueuing ou AdvancedQueueing.
 *
 * @version 1.2
 * @date 05/2003
 * @author spfister
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
IS

--
-- Internal declarations
--

  TYPE t_xml_entity IS RECORD(
    id NUMBER(12),
    entity VARCHAR2(32)
  );
  TYPE tt_entity_list IS TABLE OF T_XML_ENTITY INDEX BY BINARY_INTEGER;

  gv_CurrentSchema VARCHAR2(32);
  gcv_QUEUE_OWNER CONSTANT VARCHAR2(5) := 'PCS_Q';
  ERROR_EMPTY_QUEUE_MSG CONSTANT VARCHAR2(36) := 'the QUEUE "'||gcv_QUEUE_OWNER||'"."?" does not exist';
  ERROR_EMPTY_RECIPIENT_MSG CONSTANT VARCHAR2(50) := 'cannot dequeue because CONSUMER_NAME not specified';

  cursor csQueueName(ref_code IN VARCHAR2) is
    select QUE_CODE
    from PCS.PC_QUEUE
    where QUE_REFERENCE = ref_code;

  -- internal cursor for reference publishing
  cursor csPublish(
    iv_name IN rep_to_publish.rpt_basic_object_name%TYPE)
  is
    select RPT_ID
    from REP_TO_PUBLISH
    where RPT_BASIC_OBJECT_NAME = iv_name;

  -- Translated from DBMS_AQ
  DBMS_AQ_BROWSE        CONSTANT BINARY_INTEGER := 1;
  DBMS_AQ_LOCKED        CONSTANT BINARY_INTEGER := 2;
  DBMS_AQ_REMOVE        CONSTANT BINARY_INTEGER := 3;
  DBMS_AQ_REMOVE_NODATA CONSTANT BINARY_INTEGER := 4;


/**
 * Ajout du nom du schéma propriétaire des queues à queue_name.
 * @param queue_name  Nom de la queue.
 * @return  Le nom de la queue préfixé du nom du schéma propriétaire.
 */
function p_AddQueueOwner(
  queue_name IN VARCHAR2)
  return VARCHAR2
  DETERMINISTIC
is
begin
  if (queue_name is not null) and
     (Upper(Substr(queue_name, 1, Length(gcv_QUEUE_OWNER)+1)) != gcv_QUEUE_OWNER||'.') then
    return gcv_QUEUE_OWNER||'.'||queue_name;
  end if;
  return queue_name;
end;

/**
 * Cette fonction sert à initialiser la variable locale gv_CurrentSchema
 * pour des raisons de performances.
 * L'appel de la procédure ne doit pas être fait à l'initialisation du package,
 * car la fonction com_CurrentSchema ne peut pas aboutir à ce moment là.
 */
function p_GetCurrentSchema
  return VARCHAR2
is
begin
  if (gv_CurrentSchema is null) then
    gv_CurrentSchema := com_CurrentSchema;
  end if;
  return gv_CurrentSchema;
end;


procedure p_validate(queue_name IN VARCHAR2) is
begin
  if (queue_name is null) then
    raise_application_error(ERROR_EMPTY_QUEUE, Replace(ERROR_EMPTY_QUEUE_MSG,'?',queue_name));
  end if;
end;
procedure p_validate(queue_name IN VARCHAR2, recipient_name IN VARCHAR2) is
begin
  if (recipient_name is null) then
    raise_application_error(ERROR_EMPTY_RECIPIENT, ERROR_EMPTY_RECIPIENT_MSG);
  end if;
  p_validate(queue_name);
end;


procedure p_dequeue_SQ(
  iv_recipient_name IN VARCHAR2,
  it_options IN pcs.pc_mgt_queue.T_DEQUEUE_OPTIONS,
  ox_message OUT NOCOPY XMLType,
  on_message_id OUT NOCOPY NUMBER)
is
begin
  pcs.pc_mgt_queue.dequeue(
    iv_dst => iv_recipient_name,
    it_options => it_options,
    ox_payload => ox_message,
    on_message_id => on_message_id);

  if (it_options.dequeue_mode != pcs.pc_typ_queue_def.DEQUEUE_LOCKED) then
    -- Commit doit être fait juste après dequetage pour éviter
    -- qu'un autre ne puisse prendre le même message.
    commit;

    rep_que_fct.add_recieved(ox_message);
  end if;
end;


/** @deprecated since Proconcept ERP 10.02 */
procedure p_USE_DEQUEUE(recipient_name IN VARCHAR2, queue_name IN VARCHAR2,
  dequeue_mode IN BINARY_INTEGER,
  xmlMessage OUT NOCOPY XMLType, msg_id IN OUT NOCOPY RAW)
is
begin
  -- Validation des informations de la source
  p_validate(queue_name, recipient_name);

  EXECUTE IMMEDIATE
    'DECLARE '||
      'dequeue_opt sys.dbms_aq.DEQUEUE_OPTIONS_T;'||
      'message_prop sys.dbms_aq.MESSAGE_PROPERTIES_T;'||
    Chr(10)||'BEGIN'||Chr(10)||
      -- propriété de dequeue
      'dequeue_opt.navigation := sys.dbms_aq.FIRST_MESSAGE;'||
      'dequeue_opt.wait := sys.dbms_aq.NO_WAIT;'||
      'dequeue_opt.dequeue_mode := :1;'||
      'dequeue_opt.consumer_name := '''|| recipient_name ||''';'||
      'dequeue_opt.msgid := :2;'||
      -- propriété du message
      'message_prop.priority := 0;'||
      -- dequeue du message
      'sys.dbms_aq.dequeue('||
        'queue_name => '''|| p_AddQueueOwner(queue_name) ||''','||
        'dequeue_options => dequeue_opt,'||
        'message_properties => message_prop,'||
        'payload => :3,'||
        'msgid => :4);'||
    Chr(10)||'END;'
    USING IN dequeue_mode,
          IN msg_id,
          OUT xmlMessage,
          OUT msg_id;

  if (dequeue_mode not in (DBMS_AQ_LOCKED, DBMS_AQ_BROWSE)) then
    -- Commit doit être fait juste après dequetage pour éviter
    -- qu'un autre ne puisse prendre le même message.
    commit;

    if (dequeue_mode != DBMS_AQ_REMOVE_NODATA) then
      rep_que_fct.add_recieved(xmlMessage);
    end if;
  end if;

  exception
    when ex.NO_MESSAGE or ex.NO_MESSAGES then
      null;
end;

function dequeue(
  iv_recipient_name IN VARCHAR2,
  iv_queue_type IN VARCHAR2,
  on_message_id OUT NOCOPY NUMBER)
  return CLOB
is
  lx_document XMLType;
begin
  lx_document := rep_que_fct.dequeue_xml(iv_recipient_name, iv_queue_type, on_message_id);
  if (lx_document is not null) then
    return lx_document.getClobVal();
  end if;
  return null;
end;
function dequeue_xml(
  iv_recipient_name IN VARCHAR2,
  iv_queue_type IN VARCHAR2,
  on_message_id OUT NOCOPY NUMBER)
  return XMLType
is
  lt_options pcs.pc_mgt_queue.T_DEQUEUE_OPTIONS;
  lx_message XMLType;
begin
  lt_options.queue_type := iv_queue_type;
  lt_options.dequeue_mode := pcs.pc_typ_queue_def.DEQUEUE_LOCKED;
  p_dequeue_SQ(iv_recipient_name, lt_options, lx_message, on_message_id);
  return lx_message;
end;

function dequeue(
  iv_queue_type IN VARCHAR2,
  on_message_id OUT NOCOPY NUMBER)
  return CLOB
is
begin
  return rep_que_fct.dequeue(p_GetCurrentSchema, iv_queue_type, on_message_id);
end;
function dequeue_xml(
  iv_queue_type IN VARCHAR2,
  on_message_id OUT NOCOPY NUMBER)
  return XMLType
is
begin
  return rep_que_fct.dequeue_xml(p_GetCurrentSchema, iv_queue_type, on_message_id);
end;

/** @deprecated since Proconcept ERP 10.02 */
function USE_DEQUEUE(recipient_name IN VARCHAR2, queue_name IN VARCHAR2)
  return CLOB
is
  xmlMessage XMLType;
begin
  xmlMessage := rep_que_fct.use_dequeue_xml(recipient_name, queue_name);
  if (xmlMessage is not null) then
    -- Convertion du document Xml en CLob
    return xmlMessage.getClobVal();
  end if;
  return null;
end;
/** @deprecated since Proconcept ERP 10.02 */
function USE_DEQUEUE_XML(recipient_name IN VARCHAR2, queue_name IN VARCHAR2)
  return XMLType
is
  xmlMessage XMLType;
  msg_id RAW(16);
begin
  p_USE_DEQUEUE(recipient_name, queue_name, DBMS_AQ_REMOVE, xmlMessage, msg_id);
  return xmlMessage;
end;
/** @deprecated since Proconcept ERP 10.02 */
function USE_DEQUEUE(recipient_name IN VARCHAR2, queue_name IN VARCHAR2, msg_id OUT NOCOPY RAW)
  return CLOB
is
  xmlMessage XMLType;
begin
  xmlMessage := rep_que_fct.use_dequeue_xml(recipient_name, queue_name, msg_id);
  if (xmlMessage is not null) then
    -- Convertion du document Xml en CLob
    return xmlMessage.getClobVal();
  end if;
  return null;
end;
/** @deprecated since Proconcept ERP 10.02 */
function USE_DEQUEUE_XML(recipient_name IN VARCHAR2, queue_name IN VARCHAR2, msg_id OUT NOCOPY RAW)
  return XMLType
is
  xmlMessage XMLType;
begin
  p_USE_DEQUEUE(recipient_name, queue_name, DBMS_AQ_LOCKED, xmlMessage, msg_id);
  return xmlMessage;
end;

function release(
  iv_recipient_name IN VARCHAR2,
  iv_queue_type IN VARCHAR2,
  in_message_id IN NUMBER)
  return INTEGER
is
  lt_options pcs.pc_mgt_queue.T_DEQUEUE_OPTIONS;
  lx_document XMLType;
  ln_message_id NUMBER;
begin
  lt_options.queue_type := iv_queue_type;
  lt_options.dequeue_mode := pcs.pc_typ_queue_def.DEQUEUE_REMOVE;
  lt_options.message_id := in_message_id;
  p_dequeue_SQ(iv_recipient_name, lt_options, lx_document, ln_message_id);
  return 1;
end;

/** @deprecated since Proconcept ERP 10.02 */
function RELEASE(recipient_name IN VARCHAR2, queue_name IN VARCHAR2, msg_id IN RAW)
  return INTEGER
is
  xmlMessage XMLType;
  message_handle RAW(16);
begin
  message_handle := msg_id;
  -- Utilisation du mode sys.dbms_aq.REMOVE au lieu de sys.dbms_aq.REMOVE_NODATA
  -- pour s'assurer de conserver une trace dans la table de réception.
  -- Voir la méthode p_USE_DEQUEUE pour plus de détails sur le fonctionnement
  p_USE_DEQUEUE(recipient_name, queue_name, DBMS_AQ_REMOVE, xmlMessage, message_handle);
  return 1;
end;


procedure p_enqueue_SQ(
  iv_schema_name IN VARCHAR2,
  iv_queue_type IN VARCHAR2,
  iv_correlation IN VARCHAR2,
  ix_message IN XMLType,
  on_message_id OUT NUMBER)
is
begin
  if (iv_schema_name is null) then
    pcs.pc_mgt_queue.enqueue(
      iv_src => p_GetCurrentSchema,
      iv_queue_type => iv_queue_type,
      iv_correlation => iv_correlation,
      ix_payload => ix_message,
      on_message_id => on_message_id);
  else
    pcs.pc_mgt_queue.enqueue_local(
      iv_dst => iv_schema_name,
      iv_queue_type => iv_queue_type,
      iv_correlation => iv_correlation,
      ix_payload => ix_message,
      on_message_id => on_message_id);
  end if;

  commit;

  rep_que_fct.add_published(ix_message);

  exception
    when pcs.pc_mgt_queue_exception.NO_SUITABLE_PROPAG then
      null;
end;

/** @deprecated since Proconcept ERP 10.02 */
procedure p_USE_ENQUEUE(schema_name IN VARCHAR2, queue_name IN VARCHAR2,
  correlation IN VARCHAR2, xmlMessage IN XMLType)
is
  strQueueName VARCHAR2(32767);
begin
  strQueueName := case when schema_name is not null then schema_name||'_' end || queue_name;
  p_validate(strQueueName);

  EXECUTE IMMEDIATE
    'DECLARE '||
      'enqueue_opt sys.dbms_aq.ENQUEUE_OPTIONS_T;'||
      'message_prop sys.dbms_aq.MESSAGE_PROPERTIES_T;'||
      'msg_id RAW(16);'||
    Chr(10)||'BEGIN' ||Chr(10)||
      -- propriété d'enqueue
      'message_prop.priority := 0;'||
      'message_prop.delay := sys.dbms_aq.NO_DELAY;'||
      'message_prop.expiration := sys.dbms_aq.NEVER;'||
      -- Code libre pouvant être spécifié lors du dequeue
      'message_prop.correlation := '''||Substr(correlation,1,128)||''';'||
      -- strQueueName spécifie le nom de l'agent à utiliser pour envoyer le message.
      -- S'il n'est pas spécifié (null), il faut laisser l'AQ calculer automatiquement
      -- les destinataires en fonction des abonnés (subscriber) enregistrés, sinon
      -- la valeur doit représenter la queue de destination
      case when schema_name is not null then
        'message_prop.recipient_list(0) := sys.aq$_agent('''||strQueueName||''',null,null);'
      end||
      'sys.dbms_aq.enqueue('||
        'queue_name => '''||p_AddQueueOwner(strQueueName)||''','||
        'enqueue_options => enqueue_opt,'||
        'message_properties => message_prop,'||
        'payload => :1,'||
        'msgid => msg_id);'||
    Chr(10)||'END;'
    USING IN xmlMessage;

  commit;

  rep_que_fct.add_published(xmlMessage);

  exception
    when ex.NO_RECIPIENTS then
      null;
end;


procedure enqueue(
  iv_schema_name IN VARCHAR2,
  iv_queue_type IN VARCHAR2,
  iv_correlation IN VARCHAR2,
  it_message IN CLOB)
is
  ln_message_id NUMBER;
begin
  rep_que_fct.enqueue(iv_schema_name, iv_queue_type, iv_correlation, it_message, ln_message_id);
end;
procedure enqueue(
  iv_schema_name IN VARCHAR2,
  iv_queue_type IN VARCHAR2,
  iv_correlation IN VARCHAR2,
  it_message IN CLOB,
  on_message_id OUT NUMBER)
is
begin
  rep_que_fct.enqueue(iv_schema_name, iv_queue_type, iv_correlation, XMLType.CreateXml(it_message), on_message_id);
end;

procedure enqueue(
  iv_schema_name IN VARCHAR2,
  iv_queue_type IN VARCHAR2,
  iv_correlation IN VARCHAR2,
  ix_message IN XMLType)
is
  ln_message_id NUMBER;
begin
  rep_que_fct.enqueue(iv_schema_name, iv_queue_type, iv_correlation, ix_message, ln_message_id);
end;
procedure enqueue(
  iv_schema_name IN VARCHAR2,
  iv_queue_type IN VARCHAR2,
  iv_correlation IN VARCHAR2,
  ix_message IN XMLType,
  on_message_id OUT NUMBER)
is
begin
  p_enqueue_SQ(iv_schema_name, iv_queue_type, iv_correlation, ix_message, on_message_id);
end;

procedure enqueue(
  iv_queue_type IN VARCHAR2,
  iv_correlation IN VARCHAR2,
  ix_message IN XMLType)
is
  ln_message_id NUMBER;
begin
  rep_que_fct.enqueue(null, iv_queue_type, iv_correlation, ix_message, ln_message_id);
end;
procedure enqueue(
  iv_queue_type IN VARCHAR2,
  iv_correlation IN VARCHAR2,
  ix_message IN XMLType,
  on_message_id OUT NUMBER)
is
begin
  p_enqueue_SQ(null, iv_queue_type, iv_correlation, ix_message, on_message_id);
end;


/** @deprecated since Proconcept ERP 10.02 */
procedure USE_ENQUEUE(schema_name IN VARCHAR2,
  queue_code IN VARCHAR2, correlation IN VARCHAR2,
  clobMessage IN CLOB) is
begin
  p_USE_ENQUEUE(schema_name, queue_code, correlation,
      XMLType.CreateXml(clobMessage));
end;
/** @deprecated since Proconcept ERP 10.02 */
procedure USE_ENQUEUE(schema_name IN VARCHAR2,
  queue_code IN VARCHAR2, correlation IN VARCHAR2,
  xmlMessage IN XMLType) is
begin
  p_USE_ENQUEUE(schema_name, queue_code, correlation, xmlMessage);
end;
/** @deprecated since Proconcept ERP 10.02 */
procedure USE_ENQUEUE(queue_name IN VARCHAR2,
  correlation IN VARCHAR2, xmlMessage IN XMLType) is
begin
  p_USE_ENQUEUE(null, queue_name, correlation, xmlMessage);
end;


procedure raise_xml_factoring_error(
  in_main_id IN NUMBER,
  iv_error IN VARCHAR2)
is
begin
  pcs.pc_mgt_queue_exception.raise_exception(
    pcs.pc_mgt_queue_exception.XML_FACTORING_ERROR_NO,
    'Error during xml factoring'||
    case when in_main_id is not null and in_main_id > 0 then ' ('||to_char(in_main_id)||')' end||
    case when iv_error is not null then Chr(10)||iv_error end);
end;


function load_publishable(
  iv_name IN rep_to_publish.rpt_basic_object_name%TYPE,
  itt_publishable IN OUT NOCOPY rep_que_fct.TT_PUBLISHABLE_LIST)
  return INTEGER
is
begin
  itt_publishable.DELETE;
  open csPublish(iv_name);
  fetch csPublish bulk collect into itt_publishable;
  close csPublish;
  return itt_publishable.COUNT;
end;

procedure enqueue_publishable(
  in_id IN NUMBER,
  iot_props IN OUT NOCOPY T_REFERENCE_PROPERTIES,
  ix_document IN XMLType,
  iv_correlation IN VARCHAR2 default null)
is
  lv_queue_type VARCHAR2(10);
  lt_queuing_system pcs.pc_mgt_queue_sys.QUEUING_SYSTEM := pcs.pc_mgt_queue_sys.NONE_QUEUING;
begin
  -- mise à jour du type de queue et détection du système de queuing
  if (iot_props.queue_type is not null) then
    lt_queuing_system := pcs.pc_mgt_queue_sys.queuing(iot_props.queue_type);
  else
    pcs.pc_mgt_queue_sys.resolve_reference(iot_props.object_name, lv_queue_type, lt_queuing_system);
    iot_props.queue_type := lv_queue_type;
  end if;

  -- système de queuing à utiliser
  case lt_queuing_system
    when pcs.pc_mgt_queue_sys.SOLVA_QUEUING then
      rep_que_fct.enqueue(
        iot_props.queue_type,
        iv_correlation||rep_xml_function.extract_value(ix_document, iot_props.xpath),
        ix_document);
    when pcs.pc_mgt_queue_sys.ADVANCED_QUEUING then
      rep_que_fct.use_enqueue(
        rep_que_fct.get_queue_name(iot_props.object_name),
        iv_correlation||rep_xml_function.extract_value(ix_document, iot_props.xpath),
        ix_document);
    else
      pcs.pc_mgt_queue_exception.raise_exception(
        pcs.pc_mgt_queue_exception.NO_QUEUING_SYSTEM_NO,
        'no queuing system ready');
  end case;

  -- suppression des éléments en attente
  rep_que_fct.remove_published(in_id, iot_props.object_name);

  exception
    when OTHERS then
      if (sqlcode not in (pcs.pc_mgt_queue_exception.NO_QUEUING_SYSTEM_NO, pcs.pc_mgt_queue_exception.NO_SUITABLE_PROPAG_NO)) then
        rep_que_fct.raise_xml_factoring_error(in_id, sqlerrm);
      end if;
      raise;
end;


procedure remove_published(
  Id IN rep_to_publish.rpt_id%TYPE,
  RefObject IN rep_to_publish.rpt_basic_object_name%TYPE) is
begin
  delete REP_TO_PUBLISH
  where RPT_ID = Id and RPT_BASIC_OBJECT_NAME = RefObject;

  exception
    when OTHERS then null;
end;

/** deprecated since Proconcept ERP 10.02 */
function GET_QUEUE_NAME(RefObject IN rep_to_publish.rpt_basic_object_name%TYPE)
  return VARCHAR2
is
  strQCode pcs.pc_queue.que_code%TYPE := '';
begin
  open csQueueName(RefObject);
  fetch csQueueName into strQCode;
  close csQueueName;

  if (strQCode is not null) then
    return p_AddQueueOwner(p_GetCurrentSchema||'_'||strQCode);
  end if;

  return null;

  exception
    when OTHERS then return null;
end;


procedure p_add_published(
  itt_entity IN TT_ENTITY_LIST)
is
  pragma autonomous_transaction;
begin
  if (itt_entity is not null and itt_entity.COUNT > 0) then
    for cpt in itt_entity.FIRST..itt_entity.LAST loop
      if (itt_entity(cpt).Entity is not null and itt_entity(cpt).Id is not null) then
        -- Seul la dernière action de l'entité est conservée.
        merge into REP_PUBLISHED P
        using (select itt_entity(cpt).Entity AS ENTITY_NAME,
                      itt_entity(cpt).Id AS ENTITY_ID
               from DUAL) S
        on (P.RPP_ENTITY = S.ENTITY_NAME and P.RPP_ID = S.ENTITY_ID)
        when matched then
          update set P.RPP_DATE = Sysdate,
                     P.RPP_USER = pcs.PC_I_LIB_SESSION.GetUserIni
        when not matched then
          insert (P.RPP_ENTITY, P.RPP_ID,
                  P.RPP_DATE, P.RPP_USER)
          values (S.ENTITY_NAME, S.ENTITY_ID,
                  Sysdate, pcs.PC_I_LIB_SESSION.GetUserIni);
      end if;
    end loop;
  end if;

  commit;
end;

procedure ADD_PUBLISHED(
  in_main_id IN rep_published.rpp_id%TYPE,
  iv_entity IN rep_published.rpp_entity%TYPE)
is
  ltt_entity TT_ENTITY_LIST;
begin
  ltt_entity(0).Id := in_main_id;
  ltt_entity(0).Entity := iv_entity;
  p_add_published(ltt_entity);
end;
procedure ADD_PUBLISHED(
  ix_document IN XMLType)
is
  ltt_entity TT_ENTITY_LIST;
begin
  -- Chargement des informations dans la collection
  select
    ExtractValue(VALUE(T), '/*/@ID') Id,
    VALUE(T).getRootElement() as entity
    bulk collect into ltt_entity
  from
    TABLE(XMLSequence(Extract(ix_document,'/*/*'))) T;

  p_add_published(ltt_entity);
end;


procedure p_add_recieved(
  itt_entity IN TT_ENTITY_LIST)
is
  pragma autonomous_transaction;
begin
  for cpt in itt_entity.FIRST..itt_entity.LAST loop
    if (itt_entity(cpt).Entity is not null and itt_entity(cpt).Id is not null) then
      -- Seul la dernière action de l'entité est conservée.
      merge into REP_RECEIVED P
      using (select itt_entity(cpt).Entity AS ENTITY_NAME,
                    itt_entity(cpt).Id AS ENTITY_ID
             from DUAL) S
      on (P.RPR_ENTITY = S.ENTITY_NAME and P.RPR_ID = S.ENTITY_ID)
      when matched then
        update set P.RPR_DATE = Sysdate,
                   P.RPR_USER = pcs.PC_I_LIB_SESSION.GetUserIni
      when not matched then
        insert (P.RPR_ENTITY, P.RPR_ID,
                P.RPR_DATE, P.RPR_USER)
        values (S.ENTITY_NAME, S.ENTITY_ID,
                Sysdate, pcs.PC_I_LIB_SESSION.GetUserIni);
    end if;
  end loop;
  commit;
end;

procedure ADD_RECIEVED(
  in_main_id IN rep_received.rpr_id%TYPE,
  iv_entity IN rep_received.rpr_entity%TYPE)
is
  ltt_entity TT_ENTITY_LIST;
begin
  ltt_entity(0).Id := in_main_id;
  ltt_entity(0).Entity := iv_entity;
  p_add_recieved(ltt_entity);
end;
procedure ADD_RECIEVED(
  ix_document IN XMLType)
is
  ltt_entity TT_ENTITY_LIST;
begin
  -- Chargement des informations dans la collection
  select
    ExtractValue(Value(T), '/*/@ID') as id,
    VALUE(T).getRootElement() as entity
    bulk collect into ltt_entity
  from
    TABLE(XMLSequence(Extract(ix_document,'/*/*'))) T;

  p_add_recieved(ltt_entity);
end;


END REP_QUE_FCT;
