--------------------------------------------------------
--  DDL for Package Body DWH_GENERATION_UTILS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DWH_GENERATION_UTILS" 
/**
 * Package permettant de faire différentes opération sur les données
 * des tables DWH_...
 *
 * @version 1.0
 * @date 27.03.2008
 * @author rforchelet
 * @author spfister
 *
 * Copyright 1997-2011 SolvAxis SA. Tous droits réservés.
 */
IS

procedure UpdateLastUsedConfig(
  in_config_id IN dwh_generation_config.dwh_generation_config_id%TYPE,
  in_lang IN pcs.pc_lang.lanid%TYPE)
is
  ln_last_config_id dwh_last_used_config.dwh_last_used_config_id%TYPE;
  ln_lang_id pcs.pc_lang.pc_lang_id%TYPE;
  ln_create_all BINARY_INTEGER;
  LCD_SYSDATE CONSTANT DATE := Sysdate;
begin
  begin
    select DWH_GENERATION_CONFIG_ID
    into ln_last_config_id
    from DWH_LAST_USED_CONFIG;
  exception
    when NO_DATA_FOUND then
      ln_last_config_id := -1.0;
  end;

  select PC_LANG_ID
  into ln_lang_id
  from PCS.PC_LANG
  where LANID = in_lang;

  if (ln_last_config_id = in_config_id) then
    update DWH_LAST_USED_CONFIG
    set PC_LANG_ID = ln_lang_id,
        LCO_STATE = 0;
  else
    -- Effacement de l'ancienne "last_used_config"
    delete DWH_CONFIG_S_DOMAINS
    where DWH_GENERATION_CONFIG_ID = ln_last_config_id;

    delete DWH_CONFIG_S_STAR
    where DWH_GENERATION_CONFIG_ID = ln_last_config_id;

    delete DWH_REPLACED_CMDS
    where DWH_GENERATION_CONFIG_ID = ln_last_config_id;

    delete DWH_LAST_USED_CONFIG;

    delete DWH_GENERATION_CONFIG
    where DWH_GENERATION_CONFIG_ID = ln_last_config_id;

    commit;

    -- Nouvel identifiant
    select pcs.init_id_seq.nextval
    into ln_last_config_id
    from DUAL;
    -- Insertion d'une nouvelle config (copie de celle en cours)
    insert into DWH_GENERATION_CONFIG (
      DWH_GENERATION_CONFIG_ID,
      GEC_CONFIG_LABEL,
      GEC_BEGINNING_DATE,
      GEC_END_DATE,
      A_DATECRE,
      A_IDCRE)
    (
      select
        ln_last_config_id,
        'LAST_USED_CONFIG',
        GEC_BEGINNING_DATE,
        GEC_END_DATE,
        LCD_SYSDATE,
        pcs.PC_I_LIB_SESSION.GetUserIni
      from DWH_GENERATION_CONFIG
      where DWH_GENERATION_CONFIG_ID = in_config_id
    );

    select Nvl(GEC_CREATE_ALL,0)
    into ln_create_all
    from DWH_GENERATION_CONFIG
    where DWH_GENERATION_CONFIG_ID = in_config_id;

    -- Mise à jour du lien sur les étoiles créées
    if (ln_create_all = 1) then
      insert into DWH_CONFIG_S_STAR (
        DWH_CONFIG_S_STAR_ID,
        DWH_GENERATION_CONFIG_ID,
        PC_DWH_STAR_ID,
        A_DATECRE,
        A_IDCRE)
      (
        select
          pcs.init_id_seq.NextVal,
          ln_last_config_id,
          PC_DWH_STAR_ID,
          LCD_SYSDATE,
          pcs.PC_I_LIB_SESSION.GetUserIni
        from PCS.PC_DWH_STAR
      );
    else
      insert into DWH_CONFIG_S_STAR (
        DWH_CONFIG_S_STAR_ID,
        DWH_GENERATION_CONFIG_ID,
        PC_DWH_STAR_ID,
        A_DATECRE,
        A_IDCRE)
      (
        select
          pcs.init_id_seq.NextVal,
          ln_last_config_id,
          PC_DWH_STAR_ID,
          LCD_SYSDATE,
          pcs.PC_I_LIB_SESSION.GetUserIni
        FROM (
          select PC_DWH_STAR_ID
          from DWH_CONFIG_S_STAR
          where DWH_GENERATION_CONFIG_ID = in_config_id
          union
          select STA.PC_DWH_STAR_ID
          from PCS.PC_DWH_STAR STA, DWH_CONFIG_S_DOMAINS CDO
          where CDO.DWH_GENERATION_CONFIG_ID = IN_CONFIG_ID and
            STA.PC_DWH_DOMAIN_ID = CDO.PC_DWH_DOMAIN_ID)
      );
    end if;

    commit;

    -- Mise à jour du lien sur les commandes remplacées
    insert into DWH_REPLACED_CMDS (
      DWH_REPLACED_CMDS_ID,
      DWH_PC_SQLST_ID_REPLACED,
      DWH_PC_SQLST_ID_REPLACING,
      DWH_GENERATION_CONFIG_ID,
      A_DATECRE,
      A_IDCRE)
    (
      select
        pcs.init_id_seq.nextval,
        DWH_PC_SQLST_ID_REPLACED,
        DWH_PC_SQLST_ID_REPLACING,
        ln_last_config_id,
        LCD_SYSDATE,
        pcs.PC_I_LIB_SESSION.GetUserIni
      from DWH_REPLACED_CMDS
      where DWH_GENERATION_CONFIG_ID = in_config_id
    );

    -- Mise à jour des infos dans LAST_USES_CONFIG
    insert into DWH_LAST_USED_CONFIG (
      DWH_LAST_USED_CONFIG_ID,
      DWH_GENERATION_CONFIG_ID,
      PC_LANG_ID,
      LCO_EXEC_DATE,
      A_DATECRE,
      A_IDCRE
    ) values (
      pcs.init_id_seq.nextval,
      ln_last_config_id,
      ln_lang_id,
      LCD_SYSDATE,
      LCD_SYSDATE,
      pcs.PC_I_LIB_SESSION.GetUserIni
    );
  end if;

  commit;
end;

procedure UpdateExecTime(id_execution_time IN DATE) is
begin
  UPDATE DWH_LAST_USED_CONFIG
  SET LCO_EXEC_TIME = id_execution_time;
end;

procedure AddNewError(
  iv_error_info IN CLOB,
  in_command_id IN pcs.pc_sqlst.pc_sqlst_id%TYPE,
  in_config_id IN dwh_generation_config.dwh_generation_config_id%TYPE,
  in_level IN INTEGER) is
begin
  -- Ajout de l'erreur dans la table de log
  insert /*+ APPEND */ into DWH_GENERATION_ERROR_LOG (
    DWH_GENERATION_ERROR_LOG_ID,
    DWH_GENERATION_CONFIG_ID,
    PC_SQLST_ID,
    GEL_ERR_COMMAND,
    A_DATECRE,
    A_IDCRE
  ) values (
    pcs.init_id_seq.nextval,
    in_config_id,
    case when in_command_id > 0 then in_command_id else null end,
    iv_error_info,
    Sysdate,
    pcs.PC_I_LIB_SESSION.GetUserIni
  );

  -- Mise à jour du niveau d'erreur sur la dernière config utilisée
  update DWH_LAST_USED_CONFIG
  set LCO_STATE = in_level;

  commit;
end;

procedure ClearErrors is
begin
  EXECUTE IMMEDIATE
    'truncate table DWH_GENERATION_ERROR_LOG drop storage';
  -- commit n'est pas nécessaire pour une opération truncate
end;

procedure InsertOrphans(
  in_pk_fact IN NUMBER,
  iv_facts_table IN VARCHAR2,
  iv_dimension IN VARCHAR2,
  iv_star IN VARCHAR2) is
begin
  insert /* +APPEND */ into DWH_ORPHANS_LOG (
    DWH_ORPHANS_LOG_ID,
    ORL_STAR,
    ORL_FACT,
    ORL_DIMENSION,
    ORL_ORPHAN_PK,
    A_DATECRE,
    A_IDCRE
  ) values (
    pcs.init_id_seq.NextVal,
    iv_star,
    iv_facts_table,
    iv_dimension,
    in_pk_fact,
    Sysdate,
    pcs.PC_I_LIB_SESSION.GetUserIni
  );

  commit;
end;

procedure UpdateOrphans is
begin
  update DWH_ORPHANS_LOG ORL
  set ORL_DOMAIN = (select DOM_DOMAIN_LABEL
                    from PCS.PC_DWH_DOMAIN
                    where PC_DWH_DOMAIN_ID = (select PC_DWH_DOMAIN_ID
                                              from PCS.PC_DWH_STAR
                                              where STA_STAR_LABEL = ORL.ORL_STAR));

  commit;
end;

procedure ClearOrphans is
begin
  EXECUTE IMMEDIATE
    'truncate table DWH_ORPHANS_LOG drop storage';
  -- commit n'est pas nécessaire pour une opération truncate
end;


procedure SendEmail(
  in_error_level IN INTEGER,
  iv_message IN CLOB,
  ib_only_translation IN BOOLEAN,
  iv_company_name IN VARCHAR2)
is
  cursor crRecipients(in_condition IN INTEGER) is
    select MAI_EMAIL
    from DWH_MAILING_GENERATION_INFO
    where MAI_ALWAYS_SENT >= in_condition and
      DWH_ACTIV_CONFIGURATION_ID = (select DWH_ACTIV_CONFIGURATION_ID from DWH_ACTIV_CONFIGURATION);

  lv_recipients VARCHAR2(32767);
  lv_error_msg VARCHAR2(32767);
  lv_error_code VARCHAR2(32767);
  ln_mail_id NUMBER;
  LCD_SYSDATE CONSTANT DATE := Sysdate;
  vBody          long;
begin
  -- Get recipients
  for tplRecipients in crRecipients(case in_error_level when 0 then 1 else 0 end) loop
    lv_recipients := lv_recipients ||','|| tplRecipients.MAI_EMAIL;
  end loop;

  -- Send mail
  if (lv_recipients is not null) then
    -- For debug purpose only
    --dbms_java.set_output(5000);
    eml_sender.SetDebug(FALSE);

    vBody :=
      'Generation ending on '||to_char(LCD_SYSDATE,'FMday dd month')||' at '||to_char(LCD_SYSDATE,'hh24:mi:ss')||
      Chr(10)||'  '||
      case when iv_company_name is not null
        then 'BI model '||user||' based on company '||iv_company_name
      end ||
      case when ib_only_translation is not null then
        case when ib_only_translation
          then Chr(10)||'  with only translated layer'
          else Chr(10)||'  with whole model'
        end
      end ||
      Chr(10)||
      case when iv_message is not null then 'State :'||Chr(10)||iv_message end;

    -- Creates e-mail and stores it in default e-mail object
    lv_error_code := eml_sender.CreateMail(
      aErrorMessages  => lv_error_msg,
      aSender         => '"BI Generator" <no_reply@ProConceptERP.com>',
      aReplyTo        => '"no reply" <no_reply@ProConceptERP.com>',
      aRecipients     => LTrim(lv_recipients, ','),
--      aCcRecipients   => '',
      aNotification   => 0,
      aPriority       => eml_sender.cPRIOTITY_HIGH_LEVEL,
      aCustomHeaders  => 'X-Mailer: PCS mailer',
      aSubject        => 'BI automatic generation information',
      aBodyPlain      => vBody,
      aSendMode       => eml_sender.cSENDMODE_IMMEDIATE_FORCED,
      aDateToSend     => LCD_SYSDATE,
      aTimeZoneOffset => SessionTimezone,   --'02:00'
      aBackupMode     => eml_sender.cBACKUP_DATABASE);

    -- Sends the e-mail contained in default e-mail object (in fact stores it in a queue)
    lv_error_code := lv_error_code || eml_sender.Send(
        aErrorMessages => lv_error_msg,
        aMailID => ln_mail_id);
  end if;
end;

procedure GroupsBIKey(
  in_items_group_id IN dwh_items_group.dwh_items_group_id%TYPE,
  in_bi_key_value IN dwh_items_group.igr_bi_key_value%TYPE) is
begin
  update DWH_ITEMS_GROUP
  set IGR_BI_KEY_VALUE = in_bi_key_value
  where DWH_ITEMS_GROUP_ID = in_items_group_id;

  commit;
end;

procedure ClearBIKey is
begin
  update DWH_ITEMS_GROUP
  set IGR_BI_KEY_VALUE = -1;

  commit;
end;

function GetUserGroups(
  iv_user_name IN pcs.pc_user.use_name%TYPE,
  iv_company_name IN pcs.pc_comp.com_name%TYPE)
  return VARCHAR2
is
  cursor crGroups(in_user_name IN pcs.pc_user.use_name%TYPE,
                  in_com_name IN pcs.pc_comp.com_name%TYPE) is
    select GRP.USE_NAME
    from
      PCS.PC_USER GRP,
      PCS.PC_USER_GROUP G,
      PCS.PC_USER USE,
      PCS.PC_USER_COMP C,
      PCS.PC_COMP COM,
      PCS.PC_SCRIP SCR
    where
      GRP.USE_GROUP = 1 and
      GRP.USE_BI_USABLE = 1 and
      GRP.PC_USER_ID = G.USE_GROUP_ID and
      USE.USE_NAME = in_user_name and
      USE.PC_USER_ID = G.PC_USER_ID and
      GRP.PC_USER_ID = C.PC_USER_ID and
      COM.PC_COMP_ID = C.PC_COMP_ID and
      COM.COM_NAME = in_com_name and
      COM.PC_SCRIP_ID = SCR.PC_SCRIP_ID;
  lv_result VARCHAR2(32767);
begin
  for tplGroups in crGroups(iv_user_name, iv_company_name) loop
    lv_result := lv_result||', '||tplGroups.USE_NAME;
  end loop;
  return LTrim(lv_result, ', ');
end;


/** @deprecated */
function GetAllDictionarCodes
  return DICO_DEFINITION_LIST_T
  PIPELINED
is
begin
  for tplCodes in (
    select * from TABLE(dwh_generation_utils.GetAllDictionaryCodes)
  ) loop
    PIPE ROW(tplCodes);
  end loop;
  DBMS_OUTPUT.PUT_LINE('DWH_GENERATION_UTILS.GetAllDictionarCodes is deprecated');

  return;

  exception
    when NO_DATA_NEEDED then
      DBMS_OUTPUT.PUT_LINE('DWH_GENERATION_UTILS.GetAllDictionarCodes is deprecated');
      return;
end;
function GetAllDictionaryCodes
  return DICO_DEFINITION_LIST_T
  PIPELINED
is
  lt_dico DICO_DEFINITION_T;
  lcur_dico SYS_REFCURSOR;
  lv_cmd VARCHAR2(32767);
  ln_count BINARY_INTEGER := 0;
  ltt_cmd_list dbms_sql.VARCHAR2A;
  LCN_MAX_LEN_CMD CONSTANT BINARY_INTEGER := 32627;
begin
  select ' union all select '''||table_name||''' DICO_NAME, to_char('||table_name||'_ID) DICO_VALUE from '||table_name
  bulk collect into ltt_cmd_list
  from USER_TABLES
  where TABLE_NAME like 'DIC_%' and TABLE_NAME != 'DICO_DESCRIPTION';
  for cpt in 1 .. ltt_cmd_list.COUNT loop
    lv_cmd := lv_cmd || ltt_cmd_list(cpt);
    if (Length(lv_cmd) >= LCN_MAX_LEN_CMD) then
      begin
        OPEN lcur_dico FOR LTrim(lv_cmd, ' union all ');
        loop
          FETCH lcur_dico into lt_dico;
          EXIT WHEN lcur_dico%NOTFOUND;

          PIPE ROW(lt_dico);
        end loop;
      exception
        when PCS_BI.dwh_lib_exception.INVALID_INDENTIFIER then
          null;
      end;
      lv_cmd := null;
      CLOSE lcur_dico;
    end if;
  end loop;
  if (lv_cmd <> '') then
    begin
      OPEN lcur_dico for LTrim(lv_cmd, ' union all ');
      loop
        FETCH lcur_dico into lt_dico;
        EXIT WHEN lcur_dico%NOTFOUND;

        PIPE ROW(lt_dico);
      end loop;
    exception
      when PCS_BI.dwh_lib_exception.INVALID_INDENTIFIER then
        null;
      end;
    CLOSE lcur_dico;
  end if;
  return;

  exception
    when NO_DATA_NEEDED then
      if lcur_dico%ISOPEN then
        CLOSE lcur_dico;
      end if;
      return;
end;

END DWH_GENERATION_UTILS;
