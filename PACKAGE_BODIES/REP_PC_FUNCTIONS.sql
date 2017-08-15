--------------------------------------------------------
--  DDL for Package Body REP_PC_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_PC_FUNCTIONS" 
/**
 * Fonctions de génération de document Xml.
 * Spécialisation: Environnement, dictionnaires et éléments communs (PCS)
 *
 * @version 1.0
 * @date 05/2003
 * @author jsomers
 * @author spfister
 * @author ngomes
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
AS

--
-- Internal déclarations
--

function pIsDescodesCustomer(
  DescodeName IN VARCHAR2,
  DescodeCode IN VARCHAR2)
  return BOOLEAN
is
  lb_result INTEGER;
begin
  select Count(*)
  into lb_result
  from dual
  where Exists(select 1 from COM_CPY_CODES C, COM_CPY_CODES_VALUE V
               where C.CPC_NAME = DescodeName and V.CPV_NAME = DescodeCode and
                 V.COM_CPY_CODES_ID = C.COM_CPY_CODES_ID);
  return lb_result = 1;
end;


--
-- Public implementation
--

function get_pc_fdico(
  Id IN pcs.pc_fldsc.pc_fldsc_id%TYPE)
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
        'PC_FLDSC_ID,PC_LANG_ID' as TABLE_KEY,
        l.lanid,
        fd.fdilabel,
        fd.fdiheader,
        fd.fdihint)
    )) into lx_data
  from pcs.pc_lang l, pcs.pc_fdico fd
  where fd.pc_fldsc_id = Id and l.pc_lang_id = fd.pc_lang_id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(PC_FDICO,
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
-- Descodes functions
--

function get_descodes(
  DescodeName IN VARCHAR2,
  DescodeCode IN VARCHAR2,
  DescodeRef IN VARCHAR2)
  return XMLType
is
  lx_data XMLType;
begin
  if (DescodeName is null or DescodeCode is null) then
    return null;
  end if;
  if (DescodeRef is null) then
    raise_application_error(-20040, 'Argument DescodeRef cannot be null');
  end if;

  lx_data := rep_pc_functions.get_descodes(DescodeRef,DescodeCode);
  if (lx_data is not null) then
    select
      XMLConcat(
        XMLForest(
          'DESCODES_LINK' as TABLE_TYPE),
        lx_data
      ) into lx_data
    from dual;

    EXECUTE IMMEDIATE
      'select XMLElement('||DescodeName||',:lx_data) from dual'
      INTO lx_data
      USING lx_data;

    return lx_data;
  end if;

  return null;
end;
function get_descodes(
  DescodeName IN VARCHAR2,
  DescodeCode IN VARCHAR2)
  return XMLType
is
  lx_data XMLType;
begin
  if (DescodeName is null or DescodeCode is null) then
    return null;
  end if;

  -- Détection de l'origine de la valeur du descode.
  -- Si la valeur est définie dans les descodes customer, il faut retourner le
  -- fragment descodes_customer correspondant, sinon une exception sera levée.
  if (pIsDescodesCustomer(DescodeName, DescodeCode)) then
    return rep_pc_functions.get_descodes_customer(DescodeName, DescodeCode);
  end if;

  select
    XMLAgg(XMLElement(DESCRIPTIONS_ITEM,
      XMLForest(
        lanid,
        Trim(gcdtext1) as TEXT1,
        Trim(gcdtext2) as TEXT2,
        Trim(gcdtext3) as TEXT3,
        gcdcode)
    ) order by lanid ) into lx_data
  from pcs.v_pc_descodes
  where gcgname = DescodeName and gclcode = DescodeCode;

  if (lx_data is null) then
    raise_application_error(-20010, 'no data found for '||DescodeName||' to '||DescodeCode);
  end if;

  select
    XMLConcat(
      XMLForest(
        'DESCODES' as TABLE_TYPE,
        DescodeCode as GCLCODE),
      XMLElement(DESCRIPTIONS, lx_data)
    ) into lx_data
  from dual;

  EXECUTE IMMEDIATE
    'select XMLElement('||DescodeName||',:lx_data) from dual'
    INTO lx_data
    USING lx_data;

  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_descodes_customer(
  DescodeName IN VARCHAR2,
  DescodeCode IN VARCHAR2,
  DescodeRef IN VARCHAR2)
  return XMLType
is
  lx_data XMLType;
begin
  if (DescodeName is null or DescodeCode is null) then
    return null;
  end if;
  if (DescodeRef is null) then
    raise_application_error(-20050, 'Argument DescodeRef cannot be null');
  end if;

  lx_data := rep_pc_functions.get_descodes_customer(DescodeRef,DescodeCode);
  if (lx_data is not null) then
    select
      XMLConcat(
        XMLForest(
          'DESCODES_CUSTOMER_LINK' as TABLE_TYPE),
        lx_data
      ) into lx_data
    from dual;

    EXECUTE IMMEDIATE
      'select XMLElement('||DescodeName||',:lx_data) from dual'
      INTO lx_data
      USING lx_data;

    return lx_data;
  end if;

  return null;
end;
function get_descodes_customer(
  DescodeName IN VARCHAR2,
  DescodeCode IN VARCHAR2)
  return XMLType
is
  lx_data XMLType;
begin
  if (DescodeName is null or DescodeCode is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(DESCRIPTIONS_ITEM,
      XMLForest(
        lanid,
        Trim(cpd_text1) as TEXT1,
        Trim(cpd_text2) as TEXT2,
        Trim(cpd_text3) as TEXT3,
        cpd_code)
    ) order by lanid ) into lx_data
  from v_com_cpy_codes
  where cpc_name = DescodeName and cpv_name = DescodeCode;

  if (lx_data is null) then
    raise_application_error(-20020, 'no data found for '||DescodeName||' to '||DescodeCode);
  end if;

  select
    XMLConcat(
      XMLForest(
        'DESCODES_CUSTOMER' as TABLE_TYPE,
        DescodeCode as CPV_NAME),
      XMLElement(DESCRIPTIONS, lx_data)
    ) into lx_data
  from dual;

  EXECUTE IMMEDIATE
    'select XMLElement('||DescodeName||',:lx_data) from dual'
    INTO lx_data
    USING lx_data;

  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;


--
-- Dictionnaries functions
--

function get_dictionary(
  DicName IN VARCHAR2,
  DicValue IN VARCHAR2,
  DicRef IN VARCHAR2,
  IsMandatory IN INTEGER default 0)
  return XMLType
is
  lx_data XMLType;
begin
  if (DicName is null or DicValue is null) then
    return null;
  end if;
  if (DicRef is null) then
    raise_application_error(-20060, 'Argument DicRef cannot be null');
  end if;

  lx_data := rep_pc_functions.get_dictionary(DicRef, DicValue);
  if (lx_data is not null) then
    select
      XMLConcat(
        XMLForest(
          'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
          DicRef||'_ID' as TABLE_KEY),
        lx_data
      ) into lx_data
    from dual;

    EXECUTE IMMEDIATE
      'select XMLElement('||DicName||',:lx_data) from dual'
      INTO lx_data
      USING lx_data;

    return lx_data;
  end if;

  return null;
end;
function get_dictionary(
  DicName IN VARCHAR2,
  DicValue IN VARCHAR2)
  return XMLType
is
  cursor csDicoField(
    DicoName IN VARCHAR2)
  is
    select column_name
    from (
      select
        column_name,
        case when Substr(column_name,1,2) != 'A_' then 0 else 1 end is_afield,
        DicoName||'_ID' pk_field
      from sys.user_tab_columns
      where table_name = DicoName) a
    where is_afield = 0 and column_name <> pk_field;
  ltt_col_names rep_utils.colname_list_t;
  lx_data XMLType;
  lx_descr XMLType;
  lv_cmd VARCHAR2(32767);
  lv_num VARCHAR2(3);
begin
  if (DicName is null or DicValue is null) then
    return null;
  end if;

  -- Colonnes du dictionnaire
  open csDicoField(Upper(DicName));
  fetch csDicoField bulk collect into ltt_col_names;
  close csDicoField;

  -- Un dictionnaire est toujours au moins constitué de l'id et d'une valeur
  -- descriptive de l'id. Donc, la liste des champs ne devrait jamais être vide.
  if (ltt_col_names.COUNT = 0) then
    raise_application_error(-20030, 'Dictionary '|| Upper(DicName) ||' does not exists');
  end if;

  lv_num := '';
  for cpt in ltt_col_names.FIRST..ltt_col_names.LAST loop
    if (cpt > 1) then
      lv_num := to_char(cpt);
    end if;
    lv_cmd := lv_cmd||','||
      'case when '||ltt_col_names(cpt)||' is not null then
         XMLConcat(
           XMLElement(FIELDNAME'||lv_num||', '''||ltt_col_names(cpt)||'''),
           XMLElement(FIELDVALUE'||lv_num||', '||ltt_col_names(cpt)||')
         )
       end';
  end loop;

  EXECUTE IMMEDIATE
    'select XMLConcat('|| LTrim(lv_cmd,',') ||')
     from '||DicName||'
     where '||DicName||'_id = :DicValue'
    INTO lx_data
    USING DicValue;

  select
    XMLAgg(XMLElement(DESCRIPTIONS_ITEM,
      XMLForest(
        l.lanid,
        Trim(d.dit_descr) as DESCR,
        Trim(d.dit_descr2) as DESCR2)
    ) order by lanid ) into lx_descr
  from pcs.pc_lang l, dico_description d
  where d.dit_table = DicName and d.dit_code = DicValue and l.pc_lang_id = d.pc_lang_id;

  select
    XMLConcat(
      XMLForest(
        'DICTIONARY' as TABLE_TYPE,
        DicValue as VALUE),
      lx_data,
      case when lx_descr is not null then XMLElement(DESCRIPTIONS, lx_descr) end
    ) into lx_data
  from dual;

  EXECUTE IMMEDIATE
    'select XMLElement('||DicName||',:lx_data) from dual'
    INTO lx_data
    USING lx_data;

  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;


--
-- Common functions
--

function get_com_image_files(
  Id IN com_image_files.imf_rec_id%TYPE,
  TableName IN com_image_files.imf_table%TYPE)
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
        'IMF_TABLE,IMF_REC_ID,IMF_IMAGE_INDEX,IMF_SEQUENCE' as TABLE_KEY,
        COM_IMAGE_FILES_ID,
        IMF_TABLE,
        IMF_IMAGE_INDEX,
        IMF_SEQUENCE,
        IMF_COM_IMAGE_PATH,
        IMF_CABINET,
        IMF_DRAWER,
        IMF_FOLDER,
        IMF_FILE,
        IMF_DESCR,
        IMF_STORED_IN,
        IMF_KEY01, IMF_KEY02, IMF_KEY03, IMF_KEY04, IMF_KEY05, IMF_KEY06,
        IMF_KEY07, IMF_KEY08, IMF_KEY09, IMF_KEY10, IMF_KEY11, IMF_KEY12,
        IMF_KEY13, IMF_KEY14, IMF_KEY15,
        IMF_PATHFILE,
        IMF_LINKED_FILE),
      rep_pc_functions.get_dictionary('DIC_IMAGE_TYPE',DIC_IMAGE_TYPE_ID)
    )) into lx_data
  from COM_IMAGE_FILES
  where IMF_REC_ID = Id and IMF_TABLE = TableName;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(COM_IMAGE_FILES,
        XMLForest(
          'IMF_REC_ID='||TableName||'_ID' as TABLE_MAPPING),
        XMLElement(LIST, lx_data)
      ) into lx_data
    from DUAL;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;


function get_com_vfields_record(
  Id IN com_vfields_record.vfi_rec_id%TYPE,
  TableName IN com_vfields_record.vfi_tabname%TYPE)
  return XMLType
is
  cursor csFields(
    TableName IN VARCHAR2,
    TableNameRef IN VARCHAR2)
  is
    select
      case
        when fields.is_date = 1 then
          'to_char('||fields.column_name||') as '||fields.column_name
        when vfields.is_descode = 1 then
          'rep_pc_functions.get_descodes('''||fields.column_name||''','||fields.column_name||','''||vfields.descode||''')'
        when vfields.is_descode_customer = 1 then
          'rep_pc_functions.get_descodes_customer('''||fields.column_name||''','||fields.column_name||','''||vfields.descode||''')'
        else
          fields.column_name
      end column_name,
      case
        when vfields.is_descode = 1 then 1
        when vfields.is_descode_customer = 1 then 1
        else 0
      end order_field
    from
      -- Liste des champs virtuels pcs avec liaison sur un descode ou
      -- un descode customer
     (select v.fldname vfield, Nvl(f.fldcode,f.fldccode) descode,
        case when f.fldcode is not null then 1 else 0 end is_descode,
        case when f.fldccode is not null then 1 else 0 end is_descode_customer
      from pcs.pc_fldsc v, pcs.pc_fldsc f
      where
        f.pc_table_id = (select pc_table_id from pcs.pc_table where tabname = TableNameRef) and
        f.fldvirtualfield = 1 and (f.fldcode is not null or f.fldccode is not null) and
        v.pc_fldsc_id = f.pc_vfield_value_id
      ) vfields,
      -- Liste des champs de la table
     (select
        column_name,
        case when Substr(column_name,1,2) != 'A_' then 0 else 1 end is_afield,
        case when data_type != 'DATE' then 0 else 1 end is_date
      from sys.user_tab_columns
      where table_name = TableName) fields
    where fields.is_afield = 0 and fields.column_name != 'VFI_REC_ID' and
      vfields.vfield(+) = fields.column_name;
  lx_data XMLType;
  lv_cmd VARCHAR2(32767);
  lb_prev_field BOOLEAN := FALSE;
begin
  if (Id is null) then
    return null;
  end if;

  for tplFields in csFields('COM_VFIELDS_RECORD', TableName) loop
    case tplFields.order_field
      when 0 then
        lv_cmd := lv_cmd||
          ','||case when not lb_prev_field then 'XMLForest(' end||
          tplFields.column_name;
        lb_prev_field := TRUE;
      else
        lv_cmd := lv_cmd||
          case when lb_prev_field then ')' end||','||
          tplFields.column_name;
        lb_prev_field := FALSE;
    end case;
  end loop;
  -- Ajout de la fermeture de parenthèse si le dernier champ est contenu dans un XMLForest
  if (lb_prev_field) then
    lv_cmd := lv_cmd||')';
  end if;

  -- Exécution dynamique de la commande pour la liste des champs
  EXECUTE IMMEDIATE
    'select XMLConcat('|| LTrim(lv_cmd, ',') ||')
     from com_vfields_record
     where vfi_rec_id = :Id and vfi_tabname = :TableName'
    INTO lx_data
    USING Id, TableName;

  -- Génération du fragment complet
  if (lx_data is not null) then
    select
      XMLElement(COM_VFIELDS_RECORD,
        XMLForest(
          'AFTER' as TABLE_TYPE,
          'VFI_TABNAME,VFI_REC_ID' as TABLE_KEY,
          'VFI_REC_ID='||TableName||'_ID' as TABLE_MAPPING),
        lx_data
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_com_vfields_value(
  Id IN com_vfields_value.cvf_rec_id%TYPE,
  TableName IN com_vfields_value.cvf_tabname%TYPE)
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
        'CVF_TABNAME,CVF_FLDNAME,CVF_REC_ID' as TABLE_KEY,
        com_vfields_value_id,
        --cvf_rec_id, pas besoin de mettre le champ principal grâce au TABLE_MAPPING
        cvf_tabname,
        cvf_fldname,
        cvf_type,
        cvf_bool,
        cvf_char,
        to_char(cvf_date) as CVF_DATE,
        cvf_num,
        cvf_memo)
    )) into lx_data
  from com_vfields_value
  where cvf_rec_id = Id and cvf_tabname = TableName;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(COM_VFIELDS_VALUE,
        XMLForest(
          'CVF_REC_ID='||TableName||'_ID' as TABLE_MAPPING),
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

END REP_PC_FUNCTIONS;
