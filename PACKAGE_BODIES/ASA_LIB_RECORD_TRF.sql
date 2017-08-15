--------------------------------------------------------
--  DDL for Package Body ASA_LIB_RECORD_TRF
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_LIB_RECORD_TRF" 
/**
 * Méthodes utilitaires pour la circulation de dossiers SAV.
 *
 * @version 1.0
 * @date 04/2012
 * @author spfister
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 *
 * Modifications:
 */
AS

function get_record_id(
  iv_number IN asa_record.are_number%TYPE,
  it_origin IN asa_typ_record_trf_def.T_ASA_TRF_ORIGIN)
  return asa_record.asa_record_id%TYPE
  RESULT_CACHE
is
  ln_result asa_record.asa_record_id%TYPE := 0.0;
begin
  case it_origin
    when asa_typ_record_trf_def.TRF_RECORD_NUMBER then
      -- une seul dossier peut exister pour ce numéro
      select ASA_RECORD_ID
      into ln_result
      from ASA_RECORD
      where ARE_NUMBER = iv_number;
    when asa_typ_record_trf_def.TRF_RECORD_SRC_NUMBER then
      -- recherche du dernier dossier créé pour ce numéro source
      -- une message 101 peut provoquer la création d'un nouveau
      -- dossier sur une destination, tout en conservant le dossier
      -- d'origine sur la source
      select Max(ASA_RECORD_ID)
      into ln_result
      from ASA_RECORD
      where ARE_SRC_NUMBER = iv_number;
    else
      null;
  end case;

  return ln_result;

  exception
    when NO_DATA_FOUND then
      return 0.0;
end;

function get_task_price(
  in_rep_type_id IN asa_rep_type.asa_rep_type_id%TYPE,
  in_good_to_repair_id IN asa_rep_type_good.gco_good_to_repair_id%TYPE,
  in_good_to_bill_id IN asa_rep_type_task.gco_bill_good_id%TYPE,
  in_task_id IN fal_task.fal_task_id%TYPE)
  return asa_rep_type_task.rtt_amount%TYPE
is
  ln_rep_type_good_id asa_rep_type_good.asa_rep_type_good_id%TYPE;
  ln_result asa_rep_type_task.rtt_amount%TYPE;
begin
  select Nvl(Max(ASA_REP_TYPE_GOOD_ID),0)
  into ln_rep_type_good_id
  from ASA_REP_TYPE_GOOD
  where ASA_REP_TYPE_ID = in_rep_type_id
    and GCO_GOOD_TO_REPAIR_ID = in_good_to_repair_id;

  if ln_rep_type_good_id = 0 then
    select Nvl(Max(ASA_REP_TYPE_GOOD_ID),0)
    into ln_rep_type_good_id
    from ASA_REP_TYPE_GOOD
    where ASA_REP_TYPE_ID = in_rep_type_id
      and GCO_GOOD_TO_REPAIR_ID is null;

    if ln_rep_type_good_id = 0 then
      -- sortie anticipée
      return null;
    end if;
  end if;

  select Max(RTT_SALE_AMOUNT)
  into ln_result
  from ASA_REP_TYPE_TASK
  where ASA_REP_TYPE_GOOD_ID = ln_rep_type_good_id
    and (FAL_TASK_ID = in_task_id or (FAL_TASK_ID is null and in_task_id is null))
    and (GCO_BILL_GOOD_ID = in_good_to_bill_id or (GCO_BILL_GOOD_ID is null and in_good_to_bill_id is null));
  return ln_result;
end;


function is_record_sended(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return INTEGER
  RESULT_CACHE
is
  ln_result INTEGER;
begin
  select Count(*)
  into ln_result
  from DUAL
  where Exists(select 1 from ASA_RECORD_MSG_ARCH
               where ASA_RECORD_ID = in_record_id and
                C_ASA_TRF_MSG_TYPE = asa_typ_record_trf_def.TRF_MSG_TYPE_SEND and
                C_ASA_TRF_MSG_DIRECTION = '01');
  return ln_result;
end;

function is_record_received(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return INTEGER
  RESULT_CACHE
is
  ln_result INTEGER;
begin
  select Count(*)
  into ln_result
  from DUAL
  where
    Exists(select 1 from ASA_RECORD
           where ASA_RECORD_ID = in_record_id and ARE_SRC_NUMBER is not null)
    or
    Exists(select 1 from ASA_RECORD_MSG_ARCH
           where ASA_RECORD_ID = in_record_id and
            C_ASA_TRF_MSG_TYPE = asa_typ_record_trf_def.TRF_MSG_TYPE_SEND and
            C_ASA_TRF_MSG_DIRECTION = '02');
  return ln_result;
end;


function is_record_completed(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return INTEGER
  RESULT_CACHE
is
  ln_result INTEGER;
begin
  select ARE_TRF_COMPLETED
  into ln_result
  from ASA_RECORD
  where ASA_RECORD_ID = in_record_id;

  return ln_result;

  exception
    when NO_DATA_FOUND then
      return 0;
end;

function can_reply(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return INTEGER
  RESULT_CACHE
is
  ln_result INTEGER;
begin
  select Count(*)
  into ln_result
  from DUAL
  where Exists(select 1 from ASA_RECORD R
               where ASA_RECORD_ID = in_record_id and
                 Exists(select 1 from ASA_RECORD_TRF_SRC
                        where PAC_CUSTOM_PARTNER_ID=R.PAC_CUSTOM_PARTNER_ID
                          and ATS_SCHEMA_NAME = R.ARE_SRC_SCHEMA_NAME));
  return ln_result;
end;

function can_forward(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return INTEGER
  RESULT_CACHE
is
  ln_result INTEGER;
begin
  if (asa_lib_record_trf.is_record_sended(in_record_id) = 1) then
    select Count(*)
    into ln_result
    from DUAL
    where Exists(select 1 from ASA_RECORD R
                 where ASA_RECORD_ID = in_record_id and
                   Exists(select 1 from ASA_RECORD_TRF_DEST
                          where PAC_SUPPLIER_PARTNER_ID=R.PAC_SUPPLIER_PARTNER_ID));
    return ln_result;
  end if;
  return 0;
end;


function get_recall_binding(
  iv_number IN asa_record.are_number%TYPE)
  return asa_typ_record_trf_def.T_ASA_TRF_MSG_RECIPIENT
is
  ln_ok INTEGER;
begin
  -- detection du forward
  select Count(*)
  into ln_ok
  from DUAL
  where Exists(
    select 1 from ASA_RECORD
    where ARE_DST_SCHEMA_NAME is not null and ARE_SRC_NUMBER = iv_number and
          C_ASA_TRF_RECALL_FROM_SRC = C_ASA_TRF_RECALL_ON_DST);
  if (ln_ok = 1) then
    return asa_typ_record_trf_def.TRF_RECIPIENT_DST;
  end if;

  -- detection du reply
  select Count(*)
  into ln_ok
  from DUAL
  where Exists(
    select 1 from ASA_RECORD
    where ARE_DST_SCHEMA_NAME is not null and ARE_NUMBER = iv_number and
          C_ASA_TRF_RECALL_FROM_SRC = C_ASA_TRF_RECALL_ON_DST and
          -- vérifier que la source ne soit pas l'instance locale
          ARE_SRC_INSTANCE_NAME != sys_context('USERENV', 'INSTANCE_NAME') and
          ARE_SRC_SCHEMA_NAME != COM_CurrentSchema);
  if (ln_ok = 1) then
    return asa_typ_record_trf_def.TRF_RECIPIENT_SRC;
  end if;

  -- ne doit pas être transféré
  return asa_typ_record_trf_def.TRF_RECIPIENT_NONE;
end;


function get_recall_status(
  in_record_id IN asa_record.asa_record_id%TYPE)
  return asa_typ_record_trf_def.T_ASA_TRF_RECALL_ACTION
is
  lv_recall_on_dst asa_record.c_asa_trf_recall_on_dst%TYPE;
  lv_recall_from_src asa_record.c_asa_trf_recall_from_src%TYPE;
begin
  select C_ASA_TRF_RECALL_ON_DST, C_ASA_TRF_RECALL_FROM_SRC
  into lv_recall_on_dst, lv_recall_from_src
  from ASA_RECORD
  where ASA_RECORD_ID = in_record_id;

  if (lv_recall_on_dst != asa_typ_record_trf_def.TRF_RECALL_NONE) then
    return lv_recall_on_dst;
  end if;
  if (lv_recall_from_src != asa_typ_record_trf_def.TRF_RECALL_NONE) then
    return lv_recall_from_src;
  end if;
  return asa_typ_record_trf_def.TRF_RECALL_NONE;
end;


procedure get_RECORD_OBJECT_ACL(
  iv_username IN asa_record_object_acl.aoa_connected_username%TYPE,
  iv_company IN asa_record_object_acl.aoa_com_name%TYPE,
  ov_object_name OUT asa_record_object_acl.aoa_object_name%TYPE,
  ov_object_cmd OUT asa_record_object_acl.aoa_object_command%TYPE,
  ov_object_param OUT asa_record_object_acl.aoa_object_params%TYPE,
  ov_object_user OUT asa_record_object_acl.aoa_username%TYPE,
  ov_object_pwd OUT asa_record_object_acl.aoa_password%TYPE,
  ov_object_inipath OUT asa_record_object_acl.aoa_inifile_path%TYPE)
is
begin
  -- #1 : Par Utilisateur connecté et société
  begin
    select AOA_OBJECT_NAME
         , AOA_OBJECT_COMMAND
         , AOA_OBJECT_PARAMS
         , AOA_USERNAME
         , AOA_PASSWORD
         , AOA_INIFILE_PATH
      into ov_object_name
         , ov_object_cmd
         , ov_object_param
         , ov_object_user
         , ov_object_pwd
         , ov_object_inipath
      from ASA_RECORD_OBJECT_ACL
     where AOA_CONNECTED_USERNAME = iv_username
       and AOA_COM_NAME = iv_company;
    return;

    exception
      when NO_DATA_FOUND then null;
  end;

  -- #2 : Groupes de l'utilisateur connecté et société
  --      Le premier groupe correspondant aux critères est retourné.
  for tplGroup in (
    select  AOA_OBJECT_NAME
          , AOA_OBJECT_COMMAND
          , AOA_OBJECT_PARAMS
          , AOA_USERNAME
          , AOA_PASSWORD
          , AOA_INIFILE_PATH
       from ASA_RECORD_OBJECT_ACL
          , PCS.PC_USER USR
          , PCS.PC_USER UGR
          , PCS.PC_USER_GROUP GRP
      where AOA_COM_NAME = iv_company
        and USR.USE_NAME = iv_username
        and GRP.PC_USER_ID = USR.PC_USER_ID
        and UGR.PC_USER_ID = GRP.USE_GROUP_ID
        and AOA_CONNECTED_USERNAME = UGR.USE_NAME
   order by UGR.USE_NAME
  ) loop
    ov_object_name     := tplGroup.AOA_OBJECT_NAME;
    ov_object_cmd      := tplGroup.AOA_OBJECT_COMMAND;
    ov_object_param    := tplGroup.AOA_OBJECT_PARAMS;
    ov_object_user     := tplGroup.AOA_USERNAME;
    ov_object_pwd      := tplGroup.AOA_PASSWORD;
    ov_object_inipath  := tplGroup.AOA_INIFILE_PATH;
    return;
  end loop;

  --Step 3 : Uniquement Société -> Valable quel que soit le l'utilisateur
  begin
    select AOA_OBJECT_NAME
         , AOA_OBJECT_COMMAND
         , AOA_OBJECT_PARAMS
         , AOA_USERNAME
         , AOA_PASSWORD
         , AOA_INIFILE_PATH
      into ov_object_name
         , ov_object_cmd
         , ov_object_param
         , ov_object_user
         , ov_object_pwd
         , ov_object_inipath
      from ASA_RECORD_OBJECT_ACL
     where AOA_CONNECTED_USERNAME is null
       and AOA_COM_NAME = iv_company;
    return;

    exception
      when NO_DATA_FOUND then null;
  end;

  -- #4 : Le profil général -> Valable pour toute société et pour tout utilisateur
  begin
    select AOA_OBJECT_NAME
         , AOA_OBJECT_COMMAND
         , AOA_OBJECT_PARAMS
         , AOA_USERNAME
         , AOA_PASSWORD
         , AOA_INIFILE_PATH
      into ov_object_name
         , ov_object_cmd
         , ov_object_param
         , ov_object_user
         , ov_object_pwd
         , ov_object_inipath
      from ASA_RECORD_OBJECT_ACL
     where AOA_CONNECTED_USERNAME is null
       and AOA_COM_NAME is null;
    return;

    exception
      when NO_DATA_FOUND then null;
  end;
end;

function get_customer(
  it_sender IN asa_typ_record_trf_def.T_SENDER_COMPANY)
  return pac_custom_partner.pac_custom_partner_id%TYPE
is
begin
  return asa_lib_record_trf.get_customer(it_sender.schema_name, it_sender.recipient_key);
end;
function get_customer(
  iv_sender_schema IN VARCHAR2,
  iv_recipient_key IN VARCHAR2)
  return pac_custom_partner.pac_custom_partner_id%TYPE
  RESULT_CACHE
is
  ln_result pac_custom_partner.pac_custom_partner_id%TYPE;
begin
  if (iv_recipient_key is not null) then
    begin
      select PAC_CUSTOM_PARTNER_ID
      into ln_result
      from ASA_RECORD_TRF_SRC
      where ATS_SCHEMA_NAME = iv_sender_schema and ATS_PER_KEY1_ON_SOURCE = iv_recipient_key;
      return ln_result;
    exception
      when NO_DATA_FOUND then
        null;
    end;
  end if;

  select PAC_CUSTOM_PARTNER_ID
  into ln_result
  from ASA_RECORD_TRF_SRC
  where ATS_SCHEMA_NAME = iv_sender_schema and ATS_PER_KEY1_ON_SOURCE is null;

  return ln_result;

  exception
    when NO_DATA_FOUND then
      return null;
end;

function decode_origin(
  it_msg_recipient IN asa_typ_record_trf_def.T_ASA_TRF_MSG_RECIPIENT)
  return asa_typ_record_trf_def.T_ASA_TRF_ORIGIN
is
begin
  return case it_msg_recipient
    -- le message revient à la société émettrice
    -- donc il faut utilise le champ ARE_NUMBER
    when asa_typ_record_trf_def.TRF_RECIPIENT_SRC then asa_typ_record_trf_def.TRF_RECORD_NUMBER
    -- le message arrive à la société destinatrice
    -- donc il faut utiliser le champ ARE_SRC_NUMBER
    when asa_typ_record_trf_def.TRF_RECIPIENT_DST then asa_typ_record_trf_def.TRF_RECORD_SRC_NUMBER
  end;
end;

function decode_characteristic_type(
  iv_charact_type IN VARCHAR2)
  return VARCHAR2
is
begin
  return case iv_charact_type
    when 1 then 'version'
    when 2 then 'characteristics'
    when 3 then 'part'
    when 4 then 'batch'
    when 5 then 'chronological'
    else null
  end;
end;
function decode_characteristic_text(
  iv_charact_text IN VARCHAR2)
  return VARCHAR2
is
begin
  return case iv_charact_text
    when 'version' then 1
    when 'characteristics' then 2
    when 'part' then 3
    when 'batch' then 4
    when 'chronological' then 5
    else null
  end;
end;

procedure get_trf_infos(
  in_RecordId IN asa_record.asa_record_id%TYPE,
  on_IsTrfRecord OUT NOCOPY NUMBER,
  on_ShowBand OUT NOCOPY NUMBER,
  ov_BandText OUT NOCOPY VARCHAR2,
  ov_BandIconName OUT NOCOPY VARCHAR2)
is
  ln_IsTrfRecord NUMBER;
  lv_bandText VARCHAR2(32767);
  lv_BandIconName VARCHAR2(32767);
begin
  -- initialisation des paramètres de retour
  on_IsTrfRecord := 0;
  on_ShowBand := 0;
  ov_BandText := '';
  ov_BandIconNAme := '';

  begin
    select
      decode(ARE_DST_COM_NAME, null, 0, 1) +
      decode(NullIf(ARE_SRC_SCHEMA_NAME, pcs.PC_I_LIB_SESSION.GetCompanyOwner), null, 0, 1) +
      (select Count(*) from DUAL
        where Exists(select 1 from ASA_RECORD_TRF_DEST
                     where PAC_SUPPLIER_PARTNER_ID = REC.PAC_SUPPLIER_PARTNER_ID))
      as IS_TRF_RECORD,
      case when ARE_SRC_SCHEMA_NAME is not null and
               (ARE_SRC_SCHEMA_NAME <> pcs.PC_I_LIB_SESSION.GetCompanyOwner) then
        pcs.pc_functions.TranslateWord('Reçu de') ||' "'|| ARE_SRC_COM_NAME ||'"'||
        case when ARE_DST_COM_NAME is not null then ' / ' end
      end ||
      case when ARE_DST_COM_NAME is not null then
        pcs.pc_functions.TranslateWord('Transmis à') ||' "'|| ARE_DST_COM_NAME ||'"'
      end ||
      case when ARE_TRF_COMPLETED = 1 then
        ' / '|| pcs.pc_functions.TranslateWord('Transfert terminé')
      end ||
      case C_ASA_TRF_LOOP_STATUS
        when '01' then ' / '|| pcs.pc_functions.TranslateWord('Dossier réouvert')
        when '02' then ' / '|| pcs.pc_functions.TranslateWord('Dossier refermé')
      end ||
      case when ARE_LOCALLY_OWNED = 0 and ARE_TRF_COMPLETED = 0 then
        ' / '|| pcs.pc_functions.TranslateWord('Modifications locales interdites')
      end ||
      case C_ASA_TRF_RECALL_ON_DST
        when '01' then
          ' / '|| Replace(pcs.pc_functions.TranslateWord('Rappel de dossier demandé à  <DST>'), '<DST>', '"'||ARE_DST_COM_NAME||'"')
        when '02' then
          ' / '|| Replace(pcs.pc_functions.TranslateWord('Rappel de dossier demandé à  <DST> accepté'), '<DST>', '"'||ARE_DST_COM_NAME||'"')
      end ||
      case C_ASA_TRF_RECALL_FROM_SRC
        when '01' then
          ' / '|| Replace(pcs.pc_functions.TranslateWord('Rappel de dossier demandé par <SRC> '), '<SRC>', '"'||ARE_SRC_COM_NAME||'"')
        when '02' then
          ' / '|| Replace(pcs.pc_functions.TranslateWord('Rappel de dossier demandé par <SRC> accepté'), '<SRC>', '"'||ARE_SRC_COM_NAME||'"')
      end
      as BAND_TEXT,
      'ABOUT_BLUE' as ICON_NAME
    into ln_IsTrfRecord, lv_BandText, lv_BandIconName
    from ASA_RECORD REC
    where ASA_RECORD_ID = in_RecordId;
  exception
    when NO_DATA_FOUND then
      ln_IsTrfRecord := 0;
  end;

  -- initialisation des valeurs de retour avec les données du dossier si celui-ci
  -- est un dossier de transfert et que l'on gère la circulation des dossiers
  if (ln_IsTrfRecord > 0) then
    on_IsTrfRecord := 1;
    on_ShowBand := 1;
    ov_BandText := lv_BandText;
    ov_BandIconNAme := lv_BandIconName;
  end if;
end get_Trf_Infos;

END ASA_LIB_RECORD_TRF;
