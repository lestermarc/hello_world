--------------------------------------------------------
--  DDL for Package Body COM_LIB_ECM
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_LIB_ECM" 
/**
 * Méthodes pour gestion électronique de documents.
 *
 * @version 1.0
 * @date 11/2012
 * @author mdesboeufs
 * @author skalayci
 * @author spfister
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
IS

--
-- private methods
--

  gcvDW_INTEGRATION CONSTANT VARCHAR2(16) := 'Integration.aspx';
  gcvDW_DEFAULT CONSTANT VARCHAR2(12) := 'Default.aspx';
  gcv_DM_FLD_ERP_TABLE CONSTANT VARCHAR2(9) := 'ERP_TABLE';
  gcv_DM_FLD_ERP_ID CONSTANT VARCHAR2(6) := 'ERP_ID';
  gvlocal VARCHAR2(10) := '5749565055';
  gcnS INTEGER;
  gcnM INTEGER;
  gcnA INTEGER;


/**
 * Information de login pour Docuware ncodé en base 64 à partir du login username;password
 */
function p_get_dw_login(
  it_param IN com_lib_ecm_param.T_PARAMETER)
  return VARCHAR2
is
begin
  return
    com_lib_ecm.encode64_dw(
      'User='||it_param.name ||
      '\n'||
      'Pwd='||it_param.value
    );
end;

function get_local(pos INTEGER) return VARCHAR2
is
begin
  return Substr(gvlocal,pos,pos)||Substr(gvlocal,pos*3,pos)||Substr(gvlocal,pos*5,pos);
end;

procedure validate_local
is
begin
  gcnS := to_number(get_local(1));
  gcnM := to_number(Substr(gvlocal,2,1)||to_char(gcnS));
  gcnA := to_number(Substr(gvlocal,4,1)||Substr(gvlocal,2,1)||to_char(gcnS));
end;


function p_get_login_info
  return com_lib_ecm_param.T_PARAMETER
is
  lt_result com_lib_ecm_param.T_PARAMETER;
begin
  select USE_CMS_USERNAME, pc_i_lib_crypto.decryptPcs(USE_CMS_PASSWORD, gcnS, gcnM, gcnA)
  into lt_result.name, lt_result.value
  from PCS.PC_USER
  where USE_NAME = pcs.PC_I_LIB_SESSION.GetUserName;
  return lt_result;
end;

--
-- Public methods
--

function encode64_dw(
  iv_value IN VARCHAR2)
  return VARCHAR2
is
begin
  -- replacement des caractères non autorisés dans une URL
  return Translate(pcs.pc_lib_cryptoadm_sys.Encode64(iv_value),'*/'||Chr(13)||Chr(10),'-_');
end;

function get_dw_url(
  iv_table IN pcs.pc_table.tabname%TYPE,
  iv_field IN pcs.pc_fldsc.fldname%TYPE,
  in_record_id IN NUMBER)
  return VARCHAR2
is
  lv_url VARCHAR2(32767);
  lv_sep VARCHAR2(10);
  lv_proc_validate VARCHAR2(32767);
  lv_params VARCHAR2(32767);
  ln_pos INTEGER;
begin
  if (gvlocal is not null) then validate_local;
    gvlocal := null;
  end if;

  -- vide la liste des paramètres
  com_lib_ecm_param.Delete;

  -- Url d'appel du client web
  lv_url := pcs.pc_config.GetTableConfig(iv_table, 'COM_DW_URL');
  if (Substr(lv_url, -1) != '/') then
    -- ajout du séparateur d'url
    lv_url := lv_url || '/';
  end if;
  lv_url := lv_url || gcvDW_INTEGRATION;

  -- page de l'intégration à appeler
  com_lib_ecm_param.Set(
    'i',
    pcs.pc_config.GetTableConfig(iv_table, 'COM_DW_URL_INTEGRATION_NAME')
  );
  -- paramètre de connexion (base64)
  com_lib_ecm_param.Set(
    'lc',
    p_get_dw_login(p_get_login_info)
  );
  -- boite de dialogue
  com_lib_ecm_param.Set(
    'sed',
    pcs.pc_config.GetTableConfig(iv_table, 'COM_DW_URL_SEARCH_DIALOG_GUID')
  );
  -- requête (base64)
  com_lib_ecm_param.Set(
    case when com_lib_ecm_param.IsNull('sed') then 'q' else 'dv' end,
    com_lib_ecm.encode64_dw(com_lib_ecm.get_dw_url_params(iv_table, iv_field, in_record_id))
  );
  -- liste de résultat et visionneuse
  com_lib_ecm_param.Set(
    'p',
    case when com_lib_ecm_param.IsNull('sed') then 'RLV' else 'SRLV' end
  );

  -- méthode individualisée pour le traitement de l'URL
  lv_proc_validate := pcs.pc_config.GetTableConfig(iv_table, 'COM_DW_URL_PROC_VALIDATE');
  if (lv_proc_validate is not null) then
    execute immediate
      'begin '||
        lv_proc_validate||'(:1,:2,:3,:4);'||
      'end;'
      using in iv_table,
            in iv_field,
            in in_record_id,
            in out lv_url;
  end if;

  for tplParams in (
    select NAME, VALUE
    from TABLE(com_lib_ecm_param.List)
  ) loop
    if (tplParams.Value is not null) then
      lv_params := lv_params ||'&'|| tplParams.Name ||'='|| tplParams.Value;
    end if;
  end loop;

  return lv_url ||'?'|| Substr(lv_params,2);
end;

function get_dw_url_params(
  iv_table IN pcs.pc_table.tabname%TYPE,
  iv_field IN pcs.pc_fldsc.fldname%TYPE,
  in_record_id IN NUMBER)
  return VARCHAR2
is
  lv_func VARCHAR2(32767);
  lv_result VARCHAR2(32767);
begin
  -- fonction individualisée de recherche des paramètres
  lv_func := pcs.pc_config.GetTableConfig(iv_table, 'COM_DW_URL_PARAM_FUNCTION');
  if (lv_func is not null) then
    execute immediate
      'begin '||
        ':retval := '|| lv_func ||'(:iv_table, :iv_field, :in_record_id);'||
      'end;'
      using out lv_result, -- base64!!
            in iv_table,
            in iv_field,
            in in_record_id;
    return lv_result;
  end if;

  return
    '['||gcv_DM_FLD_ERP_TABLE||']="'|| iv_table ||'" AND '||
    '['||gcv_DM_FLD_ERP_ID||']="'|| to_char(in_record_id) ||'"';
end;

function get_dw_url_search(
    iv_table IN pcs.pc_table.tabname%TYPE,
    iv_field IN pcs.pc_fldsc.fldname%TYPE,
    in_record_id IN NUMBER)
    return VARCHAR2
is
  lv_url VARCHAR2(32767);
begin
    -- Url d'appel du client web
  lv_url := pcs.pc_config.GetTableConfig(iv_table, 'COM_DW_URL');
  if (Substr(lv_url, -1) != '/') then
    -- ajout du séparateur d'url
    lv_url := lv_url || '/';
  end if;
  lv_url := lv_url || gcvDW_DEFAULT;

  return lv_url;
end;

function get_dw_active_import_folder(
    iv_table IN pcs.pc_table.tabname%TYPE,
    in_record_id IN NUMBER)
    return VARCHAR2
is
  lv_RootFolder VARCHAR2(32767);
  lv_TableFolder VARCHAR2(32767);
  lv_Result VARCHAR2(32767);
begin
  --Répertoire racine propre à tous les transferts
  lv_RootFolder := pcs.pc_config.GetConfig('COM_DW_ACTIVE_IMPORT_FOLDER');
  if lv_RootFolder is not null then
    if (Substr(lv_RootFolder, -1) != '\') then
      -- ajout du séparateur
      lv_RootFolder := lv_RootFolder || '\';
    end if;

    --Répertoire défini pour l'entité / Table
    lv_TableFolder := COM_LIB_ECM.get_dw_entity_name(iv_table,in_record_id);
    if (Substr(lv_TableFolder, -1) != '\') then
      -- ajout du séparateur
      lv_TableFolder := lv_TableFolder || '\';
    end if;

    lv_Result :=  lv_RootFolder || lv_TableFolder;
  end if;
  return lv_Result;
end;

function get_dw_entity_name(
  iv_table IN pcs.pc_table.tabname%TYPE,
  in_record_id IN NUMBER)
  return VARCHAR2
is
  lv_func VARCHAR2(32767);
  lv_result VARCHAR2(32767);
begin
  lv_result :=  iv_table;
  -- fonction individualisée pour le remplissage des métadonnées
  lv_func := pcs.pc_config.GetTableConfig(iv_table, 'COM_DW_ENTITY_FOLDER');
  if (lv_func is not null) then
    execute immediate
      'begin '||
        ':retval := '|| lv_func ||'(:iv_table, :in_record_id);'||
      'end;'
      using out lv_result,
            in iv_table,
            in in_record_id;
  end if;
  return lv_result;
end;

function get_dw_metadata(
  iv_table IN pcs.pc_table.tabname%TYPE,
  in_record_id IN NUMBER)
  return VARCHAR2
is
  lv_func VARCHAR2(32767);
  lv_result VARCHAR2(32767);
begin
  -- fonction individualisée pour le remplissage des métadonnées
  lv_func := pcs.pc_config.GetTableConfig(iv_table, 'COM_DW_INDEXING_FILE_FUNCTION');
  if (lv_func is not null) then
    execute immediate
      'begin '||
        ':retval := '|| lv_func ||'(:iv_table, :in_record_id);'||
      'end;'
      using out lv_result, -- base64!!
            in iv_table,
            in in_record_id;
    return lv_result;
  end if;

  -- l'ordre des champs est défini par le fichier de configuration de ActiveImport
  return
    '"001"'|| -- constante obligatoire
    ',"'|| iv_table ||'"'|| -- ERP_TABLE
    ',"'|| to_char(in_record_id) ||'"'|| -- ERP_ID
    ',"'|| pcs.PC_I_LIB_SESSION.GetUserIni ||'"'|| -- ERP_USER_ABBREVIATION
    ',"'|| pcs.PC_I_LIB_SESSION.GetUserName ||'"'|| -- ERP_USERNAME
    ',"0"'; -- ERP_AUTOINDEX_DONE
end;



BEGIN
  gvlocal := Chr(Substr(gvlocal,1,2))||Chr(Substr(gvlocal,3,2))||Chr(Substr(gvlocal,5,2))||Chr(Substr(gvlocal,7,2))||Chr(Substr(gvlocal,9,2));
END COM_LIB_ECM;
