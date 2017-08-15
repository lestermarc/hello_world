--------------------------------------------------------
--  DDL for Package Body REP_REFERENCE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_REFERENCE" 
/**
 * Package utilitaire contenant :
 *
 * - Générateur de document Xml des dépendances des champs et des tables
 *   utilisés par les packages de génération de document Xml de réplication.
 *
 * - Générateur de code plsql pour méthodes de génération de document Xml de
 *   réplication.
 *
 * - Générateur de code plsql pour triggers de publication de document Xml
 *   de réplication.
 *
 * @version 1.0
 * @date 08/2005
 * @author spfister
 *
 * Copyright 1997-2010 SolvAxisSA. Tous droits réservés.
 */
AS

  SUBTYPE T_SOURCE IS BINARY_INTEGER RANGE 1..2 NOT NULL;
  SOURCE_PACKAGE CONSTANT T_SOURCE := 1;
  SOURCE_TABLE CONSTANT T_SOURCE := 2;

  TYPE T_RELATION IS RECORD (
    owner VARCHAR2(30),
    theme VARCHAR2(3),
    link_function VARCHAR2(32767)
  );

  TAB CONSTANT VARCHAR2(2) := '  ';
  TAB2 CONSTANT VARCHAR2(4) := TAB||TAB;

  ERROR_TABLE_NULL CONSTANT BINARY_INTEGER := -20001; -- Table name cannot be null
  ERROR_TABLE_DOES_NOT_EXISTS CONSTANT BINARY_INTEGER := -20002; -- Table {TableName} does not exists
  ERROR_TABLE_TYPE_NULL CONSTANT BINARY_INTEGER := -20003; --Table type must be specified (AFTER, MAIN, BEFORE, etc.)
  ERROR_MAIN_NODE_NULL CONSTANT BINARY_INTEGER := -20004; --main node cannot be null for MAIN table type

  /**
   * Curseur des relations Oracle.
   */
  cursor csForeignkey(iv_table IN VARCHAR2, iv_field IN VARCHAR2) is
    select
      RK.OWNER,
      Substr(CRK.TABLE_NAME,1,3) THEME,
      'get_'||Lower(CRK.TABLE_NAME)||'_link('||
        Lower(CFK.COLUMN_NAME)||
        case when CFK.COLUMN_NAME != CRK.COLUMN_NAME then
          ','''||Substr(CFK.COLUMN_NAME,1,Instr(CFK.COLUMN_NAME,'_',-1)-1)||'''' end||
        ')' LINK_FUNCTION
    from SYS.ALL_CONS_COLUMNS CRK, SYS.ALL_CONSTRAINTS RK,
      SYS.USER_CONS_COLUMNS CFK, SYS.USER_CONSTRAINTS FK
    where FK.CONSTRAINT_TYPE = 'R' and FK.TABLE_NAME = iv_table and
      FK.CONSTRAINT_NAME = CFK.CONSTRAINT_NAME and
      CFK.COLUMN_NAME = iv_field and
      rk.constraint_name = fk.r_constraint_name and
      RK.OWNER = FK.R_OWNER and
      CRK.CONSTRAINT_NAME = RK.CONSTRAINT_NAME and CRK.OWNER = FK.R_OWNER;

  /**
   * Curseur des relations PCS.
   */
  cursor csPcsRelation(iv_table IN VARCHAR2, iv_field IN VARCHAR2) is
    select
      case (select ALINAME from PCS.PC_ALIAS
            where PC_ALIAS_ID = T.PC_ALIAS_ID)
        when 'PC_DBENV' then 'PCS'
        else COM_CurrentSchema
      end OWNER,
      Substr(T.TABNAME,1,3) THEME,
      'get_'||Lower(T.TABNAME)||'_link('||
        Lower(F.FKLFKNAME)||
        case when F.FKLFKNAME != F.FKLPKNAME then
          ','''||Substr(F.FKLFKNAME,1,Instr(F.FKLFKNAME,'_',-1)-1)||''''
        end||
        ')' LINK_FUNCTION
    from PCS.PC_TABLE T, PCS.PC_FKLUP F
    where F.FKLFKTABID = iv_table and F.FKLFKNAME = iv_field and
      F.FKL_DISABLED = 0 and F.PC_OBJECT_ID is null and
      T.PC_TABLE_ID = F.PC_TABLE_ID;


function pGetErrorMsg(
  it_source IN T_SOURCE,
  iv_name IN VARCHAR2)
  return VARCHAR2
is
begin
  return
    case it_source
      when SOURCE_PACKAGE then 'Package'
      when SOURCE_TABLE then 'Table'
    end||
    ' "'||COM_CurrentSchema||'"."'||iv_name||'" doest not exists';
end;


function pGenErrorXml(
  it_source IN T_SOURCE,
  iv_name IN VARCHAR2,
  iv_error IN VARCHAR2,
  iv_reference IN VARCHAR2 default null)
  return XMLType
is
  lx_result XMLType;
begin
  case it_source
    when SOURCE_PACKAGE then
      select
        XMLElement("package",
          XMLAttributes(iv_name as "name", iv_reference as "reference"),
          XMLElement("error", iv_error)
        ) into lx_result
      from dual;
    when SOURCE_TABLE then
      select
        XMLElement("table",
          XMLAttributes(iv_name as "name"),
          XMLElement("error", iv_error)
        ) into lx_result
      from dual;
  end case;
  return lx_result;
end;

function p_XmlToClob(ix_document IN XMLType) return CLOB is
begin
  if (ix_document is not null) then
    return pc_jutils.get_XMLPrologDefault ||Chr(10)|| ix_document.getCLOBVal();
  end if;
  return null;
end;


function get_PackageDependence_xml(
  iv_package IN VARCHAR2,
  iv_reference IN VARCHAR2 default null)
  return CLOB
is
begin
  return p_XmlToClob(rep_reference.get_PackageDependence_XMLType(iv_package, iv_reference));
end;

function get_PackageDependence_XMLType(
  iv_package IN VARCHAR2,
  iv_reference IN VARCHAR2 default null)
  return XMLType
is
  lv_source VARCHAR2(30) := Upper(iv_package);
  lx_result XMLType;
  ln_exists NUMBER;
begin
  if (iv_package is null) then
    return pGenErrorXml(SOURCE_PACKAGE, iv_package, 'Package name cannot be null', iv_reference);
  end if;

  -- Vérifie l'existance du package demandé
  select Count(*) into ln_exists from dual
  where Exists(select 1 from USER_OBJECTS
               where OBJECT_NAME = lv_source and OBJECT_TYPE = 'PACKAGE');
  if (ln_exists = 0) then
    return pGenErrorXml(SOURCE_PACKAGE, lv_source, pGetErrorMsg(SOURCE_PACKAGE, lv_source), iv_reference);
  end if;

  select
    XMLElement("package",
      XMLAttributes(lv_source as "name", iv_reference as "reference"),
      XMLAgg(rep_reference.get_TableDependence_XMLType(TABLE_NAME))
    ) into lx_result
  from V_REP_PKG_DEPENDENCIES
  where PACKAGE_NAME = lv_source;

  return lx_result;

  exception
    when OTHERS then
      return pGenErrorXml(SOURCE_PACKAGE, lv_source, dbms_utility.format_error_stack, iv_reference);
end;


function get_TableDependence_xml(
  iv_table IN VARCHAR2)
  return CLOB
is
begin
  return p_XmlToClob(rep_reference.get_TableDependence_XMLType(iv_table));
end;

function get_TableDependence_XMLType(
  iv_table IN VARCHAR2)
  return XMLType
is
  lv_source VARCHAR2(30) := Upper(iv_table);
  lx_result XMLType;
  ln_exists NUMBER;
begin
  if (iv_table is null) then
    return pGenErrorXml(SOURCE_TABLE, iv_table, 'Table name cannot be null');
  end if;

  -- Vérifie l'existance de la table demandée
  select Count(*) into ln_exists from dual
  where Exists(select 1 from USER_OBJECTS
               where OBJECT_NAME = lv_source and OBJECT_TYPE = 'TABLE');
  if (ln_exists = 0) then
    return pGenErrorXml(SOURCE_TABLE, lv_source, pGetErrorMsg(SOURCE_TABLE, lv_source));
  end if;

  select
    XMLElement("table",
      XMLAttributes(lv_source as "name"),
      XMLAgg(XMLElement("field",
        XMLAttributes(
          COLUMN_NAME as "name",
          DATA_TYPE as "data_type",
          NULLABLE as "nullable",
          USAGE as "usage",
          REPLICABLE as "replicable")
      ))
    ) into lx_result
  from V_REP_FIELD_INFO
  where MAIN = 'N' and TABLE_NAME = lv_source
  order by POSITION;

  return lx_result;

  exception
    when OTHERS then
      return pGenErrorXml(SOURCE_TABLE, lv_source, dbms_utility.format_error_stack);
end;


function p_get_Foreignkey(
  iv_table IN VARCHAR2,
  iv_field IN VARCHAR2,
  relation IN OUT NOCOPY T_RELATION)
  return BOOLEAN
is
  lb_result BOOLEAN;
begin
  open csForeignkey(iv_table, iv_field);
  fetch csForeignkey into relation;
  lb_result := csForeignkey%FOUND;
  close csForeignkey;
  return lb_result;
end;
function p_get_PcsRelation(
  iv_table IN VARCHAR2,
  iv_field IN VARCHAR2,
  relation IN OUT NOCOPY T_RELATION)
  return BOOLEAN
is
  lb_result BOOLEAN;
begin
  open csPcsRelation(iv_table, iv_field);
  fetch csPcsRelation into relation;
  lb_result := csPcsRelation%FOUND;
  close csPcsRelation;
  return lb_result;
end;

function p_get_functions_link(
  iv_table IN VARCHAR2,
  iv_field IN VARCHAR2)
  return VARCHAR2
is
  lt_relation T_RELATION;
begin
  if (not p_get_Foreignkey(iv_table, iv_field, lt_relation) and
      not p_get_PcsRelation(iv_table, iv_field, lt_relation)) then
    return 'rep_xxx_functions_link.get_xxx_link('||iv_field||')';
  end if;

  -- Prédiction du package link
  return case
    when (lt_relation.owner = 'PCS') then 'rep_pc_functions_link'
    when (lt_relation.theme in ('GCO','STM','DOC','PTC')) then 'rep_log_functions_link'
    when (lt_relation.theme in ('FAL','PPS')) then 'rep_ind_functions_link'
    when (lt_relation.theme in ('ACS','ACJ','ACT','FAM')) then 'rep_fin_functions_link'
    when (lt_relation.theme = 'PPS') then 'rep_ind_functions_link'
    -- other standard themes uses standard packages
    else 'rep_'||Lower(lt_relation.theme)||'_functions_link'
  end||'.'||lt_relation.link_function;
end;

procedure p_xml_function_generator(
  csTable IN SYS_REFCURSOR,
  step IN VARCHAR2,
  output_lines IN OUT NOCOPY dbms_sql.VARCHAR2A,
  output_pos IN OUT NOCOPY BINARY_INTEGER)
is
  rtField v_rep_field_info%ROWTYPE;
  str VARCHAR2(32767);
  prevField BOOLEAN := FALSE;
begin
  -- Ajustement de la position dans liste des valeurs
  output_pos := output_pos-1;

  -- Boucle sur le curseur pour générer la commandes de chaque champ de la table
  loop
    fetch csTable into rtField;
    exit when csTable%NOTFOUND;

    case rtField.usage
      when 'FIELD' then
        output_pos := output_pos+1;
        output_lines(output_pos) :=
          ','||case when not prevField then Chr(10)||step||'XMLForest(' end||Chr(10)||
          step||TAB||case
            when rtField.data_type!='DATE' then lower(rtField.column_name)
            else 'to_char('||lower(rtField.column_name)||') as '||rtField.column_name
          end;
        prevField := TRUE;

      when 'DICTIONARY' then
        output_pos := output_pos+1;
        output_lines(output_pos) :=
          case when prevField then ')' end||','||Chr(10)||
          step||'rep_pc_functions.get_dictionary('''||Substr(rtField.column_name,0, Length(rtField.column_name)-3)||''','||Lower(rtField.column_name)||')';
        prevField := FALSE;

      when 'DESCODE' then
        output_pos := output_pos+1;
        output_lines(output_pos) :=
          case when prevField then ')' end||','||Chr(10)||
          step||'rep_pc_functions.get_descodes('''||rtField.column_name||''','||Lower(rtField.column_name)||')';
        prevField := FALSE;

      when 'LINK' then
        output_pos := output_pos+1;
        output_lines(output_pos) :=
          case when prevField then ')' end||','||Chr(10)||
          step||p_get_functions_link(rtField.table_name, rtField.column_name);
        prevField := FALSE;

    end case;
  end loop;

  -- Ajout de la fermeture de parenthèse si le dernier champ est contenu dans un XMLForest
  if (prevField) then
    output_lines(output_pos) := output_lines(output_pos)||')';
  end if;

  -- Ajustement de la position dans liste des valeurs
  output_pos := output_pos+1;
end;

function p_get_table_key(iv_table IN VARCHAR2) return VARCHAR2
is
  lv_result VARCHAR2(32767);
begin
  -- Recherche des colonnes des contraintes uniques
  for tplCons in (
    select ','||B.COLUMN_NAME COLUMN_NAME
    from USER_CONS_COLUMNS B, USER_CONSTRAINTS A
    where
      A.TABLE_NAME = iv_table and A.CONSTRAINT_TYPE = 'U' and
      B.TABLE_NAME = A.TABLE_NAME and
      B.CONSTRAINT_NAME = A.CONSTRAINT_NAME
    order by B.CONSTRAINT_NAME, B.POSITION)
  loop
    lv_result := lv_result || tplCons.column_name;
  end loop;
  if (lv_result is not null) then
    return LTrim(lv_result, ',');
  end if;

  -- Recherche des colonnes des indexes uniques différents de la pk
  for tplInd in (
    select ','||B.COLUMN_NAME COLUMN_NAME
    from USER_IND_COLUMNS B, USER_INDEXES A
    where A.TABLE_NAME = iv_table and A.UNIQUENESS = 'UNIQUE' and A.INDEX_TYPE = 'NORMAL' and
      B.TABLE_NAME = A.TABLE_NAME and
      B.INDEX_NAME = A.INDEX_NAME and
      not Exists(select 1 from USER_CONSTRAINTS
                 where TABLE_NAME = A.TABLE_NAME and CONSTRAINT_NAME = A.INDEX_NAME)
    order by B.INDEX_NAME, B.COLUMN_POSITION)
  loop
    lv_result := lv_result || tplInd.column_name;
  end loop;
  if (lv_result is not null) then
    return LTrim(lv_result, ',');
  end if;

  -- Recherche des colonnes NOT NULL de la table
  for tplFld in (
    select ','||COLUMN_NAME COLUMN_NAME
    from (select TABLE_NAME, COLUMN_NAME, COLUMN_ID,
            case when Substr(COLUMN_NAME,1,2) = 'A_' then 1 else 0 end IS_AFIELD
          from USER_TAB_COLUMNS T
          where TABLE_NAME = iv_table and NULLABLE = 'N' and DATA_DEFAULT is null) t
    where IS_AFIELD = 0 and
      not Exists(select B.COLUMN_NAME
                 from USER_CONS_COLUMNS B, USER_CONSTRAINTS A
                 where A.TABLE_NAME = T.TABLE_NAME and A.CONSTRAINT_TYPE in ('P','R') and
                   B.TABLE_NAME = A.TABLE_NAME and
                   B.CONSTRAINT_NAME = A.CONSTRAINT_NAME and
                   B.COLUMN_NAME = T.COLUMN_NAME)
    order by COLUMN_ID)
  loop
    lv_result := lv_result || tplFld.column_name;
  end loop;
  if (lv_result is not null) then
    return LTrim(lv_result, ',');
  end if;

  -- Recherche les colonnes de la clé primaire
  for tplPk in (
    select ','||B.COLUMN_NAME COLUMN_NAME
    from USER_CONS_COLUMNS B, USER_CONSTRAINTS A
    where A.TABLE_NAME = IV_TABLE and A.CONSTRAINT_TYPE = 'P' and
      B.TABLE_NAME = A.TABLE_NAME and
      B.CONSTRAINT_NAME = A.CONSTRAINT_NAME)
  loop
    lv_result := lv_result || tplPk.column_name;
  end loop;
  if (lv_result is not null) then
    return LTrim(lv_result, ',');
  end if;

  -- Retourne null si toutes les recherches ont échouées.
  -- Normalement, ce cas ne devrait pas se produire
  return null;
end;

function p_validate_table(iv_table IN VARCHAR2) return VARCHAR2
is
  tmp BINARY_INTEGER;
  lv_result VARCHAR2(30);
begin
  -- Validation du nom de la table
  if (iv_table is null) then
    raise_application_error(ERROR_TABLE_NULL, 'Table name cannot be null');
  end if;

  -- validation de l'existance de la table
  select Count(*) into tmp from dual
  where Exists(select 1 from USER_TABLES
               where TABLE_NAME = Upper(iv_table));
  if (tmp = 0) then
    raise_application_error(ERROR_TABLE_DOES_NOT_EXISTS, 'Table '||Upper(iv_table)||' does not exists');
  end if;

  -- Recherche du champ principal de la table
  begin
    select Lower(COLUMN_NAME)
    into lv_result
    from V_REP_FIELD_INFO
    where TABLE_NAME = iv_table and MAIN = 'Y';

    exception
      -- Une table associative peut ne pas contenir de champ principal propre
      when NO_DATA_FOUND then
        null;
  end;
  return lv_result;
end;

function p_gen_virtual_fields_call(
  step IN VARCHAR2,
  iv_main_column IN VARCHAR2,
  iv_table_name IN VARCHAR2)
  return VARCHAR2
is
begin
  return
    step||'rep_pc_functions.get_com_vfields_record('||iv_main_column||','''||iv_table_name||'''),'||Chr(10)||
    step||'rep_pc_functions.get_com_vfields_value('||iv_main_column||','''||iv_table_name||''')'||Chr(10);
end;

function p_xml_function_generator(
  it_options IN T_XGEN_OPTIONS)
  return dbms_sql.VARCHAR2A
is
  indent VARCHAR2(32767);
  step VARCHAR2(32767);
  main_column VARCHAR2(30);
  is_main BOOLEAN := FALSE;
  is_link BOOLEAN := FALSE;
  csTable SYS_REFCURSOR;
  options T_XGEN_OPTIONS;
  output_lines dbms_sql.VARCHAR2A;
  output_pos BINARY_INTEGER := 0;
begin
  -- Validation de la table et recherche du champ principal, s'il existe
  main_column := p_validate_table(Upper(it_options.table_name));

  if (options.table_type is null) then
    raise_application_error(ERROR_TABLE_TYPE_NULL, 'Table type must be specified (AFTER, MAIN, BEFORE, etc.)');
  end if;

  options := it_options;
  options.table_type := Upper(options.table_type);
  options.table_name := Upper(options.table_name);
  case options.table_type
    when 'MAIN' then is_main := TRUE;
    when 'LINK' then is_link := TRUE;
    else null;
  end case;
  if (is_main) then
    if (options.main_node is null) then
      raise_application_error(ERROR_MAIN_NODE_NULL, 'Main node cannot be null for MAIN table type');
    end if;
    options.add_virtual_fields := TRUE;
    options.list_item := FALSE;
  end if;

  options.table_key := case
    when options.table_key is not null then Upper(options.table_key)
    else p_get_table_key(options.table_name)
  end;
  options.main_node := case
    when options.main_node is not null then Upper(options.main_node)
    else options.table_name
  end;

  indent := LPad(' ',options.increment);
  step := indent||TAB2||case when is_main then TAB end;

  output_lines(output_pos) :=
    'function get_'||Lower(options.table_name)||
      case options.table_type when 'MAIN' then '_xml' end||'('||Chr(10)||
      TAB||'Id IN '||Lower(options.table_name)||'.'||Lower(options.table_name)||'_id%TYPE)'||Chr(10)||
    TAB||'return XMLType'||Chr(10)||
    'is'||Chr(10)||
    TAB||'xmldata XMLType;'||Chr(10)||
    'begin'||Chr(10)||
    indent||'if (Id in (null,0)) then'||Chr(10)||
    indent||TAB||'return null;'||Chr(10)||
    indent||'end if;'||Chr(10)||Chr(10);
  output_pos := output_pos+1;

  -- Génération du début de la commande
  output_lines(output_pos) :=
    indent||'select'||Chr(10)||
    indent||TAB||case
      when is_main then
        'XMLElement('||options.main_node||','||Chr(10)||
        indent||TAB2||'XMLElement('||options.table_name||','||Chr(10)||
        step||'XMLAttributes('||Chr(10)||
          step||TAB||main_column||' as ID,'||Chr(10)||
          step||TAB||'pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),'||Chr(10)||
        step||'XMLComment(rep_utils.GetCreationContext)'
      when not options.list_item then
        'XMLElement('||options.main_node
      else
        'XMLAgg(XMLElement(LIST_ITEM'
    end||','||Chr(10)||
    step||'XMLForest('||Chr(10)||
      step||TAB||''''||options.table_type||''''||case when is_link then ' case when (IsMandatory != 0) then ''_MANDATORY''' end||' as TABLE_TYPE,'||Chr(10)||
      step||TAB||''''||options.table_key||''' as TABLE_KEY'||
      case when main_column is not null then ','||Chr(10)||step||TAB||main_column end||
    ')';
  output_pos := output_pos+1;

  -- Parse et génère la liste des champs
  open csTable for
    select * from v_rep_field_info
    where table_name = options.table_name and main = 'N'
    order by position;
  p_xml_function_generator(csTable, step, output_lines, output_pos);
  close csTable;

  -- Ajout de la gestion des champs virtuels commentés (pour ne pas oublier)
  output_lines(output_pos) :=
    case
      when options.add_virtual_fields then
        ','||Chr(10)||p_gen_virtual_fields_call(step, main_column, options.table_name)
      else
        Chr(10)
    end ||
    case when is_main then
      indent||TAB2||')'||Chr(10)
    end||
    indent||TAB||case when options.list_item then ') /* order by clause */ ' end||') into xmldata'||Chr(10)||
    indent||'from '||Lower(options.table_name)||Chr(10)||
    indent||'where '||Nvl(main_column,'(? '||p_get_table_key(options.table_name)||' ?)')||' = Id;';
  output_pos := output_pos+1;

  -- Ajout de la génération du tag principal pour les table enfants multi-valuées
  if (options.list_item) then
    output_lines(output_pos) := Chr(10)||
    indent||'-- Générer le tag principal uniquement s''il y a données'||Chr(10)||
    indent||'if (xmldata is not null) then'||Chr(10)||
    indent||TAB||'select'||Chr(10)||
    indent||TAB2||'XMLElement('||options.main_node||','||Chr(10)||
    indent||TAB2||TAB||'XMLComment('' TABLE_MAPPING>'||upper(Nvl(main_column,'(? '||p_get_table_key(options.table_name)||' ?)'))||'=PARENT_ID</TABLE_MAPPING ''),'||Chr(10)||
    indent||TAB2||TAB||'XMLElement(LIST, xmldata)'||Chr(10)||
    indent||TAB2||') into xmldata'||Chr(10)||
    indent||TAB||'from dual;'||Chr(10)||
    indent||TAB||'return xmldata;'||Chr(10)||
    indent||'end if;'||Chr(10)||Chr(10)||
    indent||'return null;'||Chr(10)||Chr(10);
  else
    output_lines(output_pos) := Chr(10)||case when is_main then Chr(10) end||
    indent||'return xmldata;'||Chr(10)||Chr(10);
  end if;
  output_pos := output_pos+1;
  if (options.list_item or not is_main) then
    output_lines(output_pos) :=
    indent||'exception'||Chr(10)||
    indent||TAB||'when NO_DATA_FOUND then return null;'||Chr(10);
    output_pos := output_pos+1;
  end if;

  -- Ajout de la gestion des exception pour la table principale
  if (is_main) then
    output_lines(output_pos) :=
    indent||'exception'||Chr(10)||
    indent||TAB||'when OTHERS then'||Chr(10)||
    indent||TAB2||'xmldata := XmlErrorDetail(sqlerrm);'||Chr(10)||
    indent||TAB2||'select'||Chr(10)||
    indent||TAB2||TAB||'XMLElement('||options.main_node||','||Chr(10)||
    indent||TAB2||TAB2||'XMLElement('||options.table_name||','||Chr(10)||
    indent||TAB2||TAB2||TAB||'XMLAttributes(Id as ID),'||Chr(10)||
    indent||TAB2||TAB2||TAB||'XMLComment(rep_utils.GetCreationContext),'||Chr(10)||
    indent||TAB2||TAB2||TAB||'xmldata'||Chr(10)||
    indent||TAB2||TAB||')) into xmldata'||Chr(10)||
    indent||TAB2||'from dual;'||Chr(10)||
    indent||TAB2||'return xmldata;'||Chr(10);
    output_pos := output_pos+1;
  end if;

  output_lines(output_pos) :=
    'end;'||Chr(10)||Chr(10);
  --output_pos := output_pos+1;

  return output_lines;

  exception
    when OTHERS then
      output_lines(output_pos) := sqlerrm||Chr(10);
      output_lines(output_pos+1) := dbms_utility.format_error_stack||Chr(10);
      output_lines(output_pos+2) := dbms_utility.format_error_backtrace||Chr(10);
      return output_lines;
end;

procedure xml_function_generator(
  it_options IN T_XGEN_OPTIONS,
  iov_script IN OUT NOCOPY CLOB)
is
  output_lines dbms_sql.VARCHAR2A;
  len BINARY_INTEGER;
  pos BINARY_INTEGER := 0;
begin
  output_lines := p_xml_function_generator(it_options);
  for cpt in output_lines.FIRST .. output_lines.LAST loop
    len := Length(output_lines(cpt));
    dbms_lob.Write(iov_script, len, pos, output_lines(cpt));
    pos := pos + len;
  end loop;
end;

procedure xml_function_generator(
  it_options IN T_XGEN_OPTIONS)
is
  output_lines dbms_sql.VARCHAR2A;
begin
  output_lines := p_xml_function_generator(it_options);
  for cpt in output_lines.FIRST .. output_lines.LAST loop
    dbms_output.put(output_lines(cpt));
  end loop;

  -- Obligatoire sinon rien ne s'affiche dans le buffer d'output
  dbms_output.put_line('');

  exception
    when OTHERS then
      dbms_output.put_line(sqlerrm);
      dbms_output.put_line(dbms_utility.format_error_stack);
      dbms_output.put_line(dbms_utility.format_error_backtrace);
end;

procedure xml_function_generator(
  iv_table_name IN VARCHAR2,
  iv_main_node IN VARCHAR2,
  iv_table_key IN VARCHAR2,
  iv_table_type IN VARCHAR2 default 'AFTER',
  ib_list_item IN BOOLEAN default FALSE,
  in_increment IN INTEGER default 2,
  ib_use_mandatory BOOLEAN default FALSE,
  ib_add_virtual_fields BOOLEAN default TRUE)
is
  options T_XGEN_OPTIONS;
begin
  options.table_name := iv_table_name;
  options.main_node := iv_main_node;
  options.table_type := iv_table_type;
  options.table_key := iv_table_key;
  options.list_item := ib_list_item;
  options.increment := in_increment;
  options.use_mandatory := ib_use_mandatory;
  options.add_virtual_fields := ib_add_virtual_fields;
  rep_reference.xml_function_generator(options);
end;


procedure p_publish_trigger_generator(
  csTable IN SYS_REFCURSOR, step IN VARCHAR2,
  output_lines IN OUT NOCOPY dbms_sql.VARCHAR2A,
  output_pos IN OUT NOCOPY BINARY_INTEGER)
is
  rtField v_rep_field_info%ROWTYPE;
  firstField BOOLEAN := TRUE;
  prevField BOOLEAN := FALSE;
  datatype VARCHAR2(32767);
  npos BINARY_INTEGER;
begin
  -- Boucle sur le curseur pour générer la commandes de chaque champ de la table
  loop
    fetch csTable into rtField;
    exit when csTable%NOTFOUND;

    -- Extraction du nom du type uniquement
    datatype := rtField.data_type;
    npos := Instr(datatype, '(');
    if (npos > 0) then
      datatype := Substr(datatype, 1, npos-1);
    end if;

    -- Ajout du précédant opérateur si nécessaire
    if (prevField) then
      output_lines(output_pos) := output_lines(output_pos)||' or'||Chr(10);
    end if;
    if (not firstField) then
      output_pos := output_pos+1;
    end if;

    -- Traitement du champ
    if (datatype in ('VARCHAR2','NVARCHAR2','CHAR','NCHAR')) then
      prevField := TRUE;
      output_lines(output_pos) := step||case when not firstField then '   ' else 'if ' end||
        '(Nvl(:old.'||rtField.column_name||','' '') <> Nvl(:new.'||rtField.column_name||','' ''))';

    elsif (datatype in ('NUMBER','FLOAT')) then
      prevField := TRUE;
      output_lines(output_pos) := step||case when not firstField then '   ' else 'if ' end||
        '(Nvl(:old.'||rtField.column_name||',0) <> Nvl(:new.'||rtField.column_name||',0))';

    elsif (datatype in ('DATE')) then
      prevField := TRUE;
      output_lines(output_pos) := step||case when not firstField then '   ' else 'if ' end||
        '(Nvl(:old.'||rtField.column_name||',to_date(''01.01.1900'', ''DD-MM-YYYY'')) <> Nvl(:new.'||rtField.column_name||',to_date(''01.01.1900'', ''DD-MM-YYYY'')))';

    elsif (Substr(datatype, 1, 9) in ('TIMESTAMP', 'INTERVAL ')) then
      prevField := TRUE;
      output_lines(output_pos) := step||case when not firstField then '   ' else 'if ' end||
        '(Nvl(:old.'||rtField.column_name||',0) <> Nvl(:new.'||rtField.column_name||',0))';

    else
      prevField := FALSE;
      output_lines(output_pos) := step||TAB||
        '-- '||rtField.column_name||' cannot be used ('||datatype||')'||Chr(10);

    end if;
    firstField := FALSE;
  end loop;
  if (prevField) then
    output_lines(output_pos) := output_lines(output_pos)||' then'||Chr(10);
  else
    output_pos := output_pos+1;
    output_lines(output_pos) := step||'then'||Chr(10);
  end if;
  output_pos := output_pos+1;

/*
VARCHAR2(size [BYTE | CHAR])
  Variable-length character string having maximum length size bytes or characters. Maximum size is 4000 bytes or characters, and minimum is 1 byte or 1 character. You must specify size for VARCHAR2.
  BYTE indicates that the column will have byte length semantics; CHAR indicates that the column will have character semantics.

NVARCHAR2(size)
  Variable-length Unicode character string having maximum length size characters. The number of bytes can be up to two times size for AL16UTF16 encoding and three times size for UTF8 encoding. Maximum size is determined by the national character set definition, with an upper limit of 4000 bytes. You must specify size for NVARCHAR2.

NUMBER[(precision [, scale]])
  Number having precision p and scale s. The precision p can range from 1 to 38. The scale s can range from -84 to 127.

LONG
  Character data of variable length up to 2 gigabytes, or 231 -1 bytes. Provided for backward compatibility.

DATE
  Valid date range from January 1, 4712 BC to December 31, 9999 AD. The default format is determined explicitly by the NLS_DATE_FORMAT parameter or implicitly by the NLS_TERRITORY parameter. The size is fixed at 7 bytes. This datatype contains the datetime fields YEAR, MONTH, DAY, HOUR, MINUTE, and SECOND. It does not have fractional seconds or a time zone.

BINARY_FLOAT
  32-bit floating point number. This datatype requires 5 bytes, including the length byte.

BINARY_DOUBLE
  64-bit floating point number. This datatype requires 9 bytes, including the length byte.

TIMESTAMP [(fractional_seconds)]
  Year, month, and day values of date, as well as hour, minute, and second values of time, where fractional_seconds_precision is the number of digits in the fractional part of the SECOND datetime field. Accepted values of fractional_seconds_precision are 0 to 9. The default is 6. The default format is determined explicitly by the NLS_DATE_FORMAT parameter or implicitly by the NLS_TERRITORY parameter. The sizes varies from 7 to 11 bytes, depending on the precision. This datatype contains the datetime fields YEAR, MONTH, DAY, HOUR, MINUTE, and SECOND. It contains fractional seconds but does not have a time zone.

TIMESTAMP [(fractional_seconds)] WITH TIME ZONE
  All values of TIMESTAMP as well as time zone displacement value, where fractional_seconds_precision is the number of digits in the fractional part of the SECOND datetime field. Accepted values are 0 to 9. The default is 6. The default format is determined explicitly by the NLS_DATE_FORMAT parameter or implicitly by the NLS_TERRITORY parameter. The size is fixed at 13 bytes. This datatype contains the datetime fields YEAR, MONTH, DAY, HOUR, MINUTE, SECOND, TIMEZONE_HOUR, and TIMEZONE_MINUTE. It has fractional seconds and an explicit time zone.

TIMESTAMP [(fractional_seconds)] WITH LOCAL TIME ZONE
  All values of TIMESTAMP WITH TIME ZONE, with the following exceptions:
      * Data is normalized to the database time zone when it is stored in the database.
      * When the data is retrieved, users see the data in the session time zone.
  The default format is determined explicitly by the NLS_DATE_FORMAT parameter or implicitly by the NLS_TERRITORY parameter. The sizes varies from 7 to 11 bytes, depending on the precision.

INTERVAL YEAR [(year_precision)] TO MONTH
Stor  es a period of time in years and months, where year_precision is the number of digits in the YEAR datetime field. Accepted values are 0 to 9. The default is 2. The size is fixed at 5 bytes.

INTERVAL DAY [(day_precision)] TO SECOND [(fractional_seconds)]
  Stores a period of time in days, hours, minutes, and seconds, where
      * day_precision is the maximum number of digits in the DAY datetime field. Accepted values are 0 to 9. The default is 2.
      * fractional_seconds_precision is the number of digits in the fractional part of the SECOND field. Accepted values are 0 to 9. The default is 6.
  The size is fixed at 11 bytes.

RAW(size)
  Raw binary data of length size bytes. Maximum size is 2000 bytes. You must specify size for a RAW value.

LONG RAW
  Raw binary data of variable length up to 2 gigabytes.

ROWID
  Base 64 string representing the unique address of a row in its table. This datatype is primarily for values returned by the ROWID pseudocolumn.

UROWID [(size)]
  Base 64 string representing the logical address of a row of an index-organized table. The optional size is the size of a column of type UROWID. The maximum size and default is 4000 bytes.

CHAR [(size [BYTE | CHAR])]
  Fixed-length character data of length size bytes. Maximum size is 2000 bytes or characters. Default and minimum size is 1 byte.
  BYTE and CHAR have the same semantics as for VARCHAR2.

NCHAR[(size)]
  Fixed-length character data of length size characters. The number of bytes can be up to two times size for AL16UTF16 encoding and three times size for UTF8 encoding. Maximum size is determined by the national character set definition, with an upper limit of 2000 bytes. Default and minimum size is 1 character.

CLOB
  A character large object containing single-byte or multibyte characters. Both fixed-width and variable-width character sets are supported, both using the database character set. Maximum size is (4 gigabytes - 1) * (database block size).

NCLOB
  A character large object containing Unicode characters. Both fixed-width and variable-width character sets are supported, both using the database national character set. Maximum size is (4 gigabytes - 1) * (database block size). Stores national character set data.

BLOB
  A binary large object. Maximum size is (4 gigabytes - 1) * (database block size).

BFILE
  Contains a locator to a large binary file stored outside the database. Enables byte stream I/O access to external LOBs residing on the database server. Maximum size is 4 gigabytes.
*/
end;

function p_table_descr(
  iv_table_name IN VARCHAR2)
  return VARCHAR2
is
  lv_result VARCHAR2(32767);
begin
  select
    Nvl(
      (select TDE_DESCR from PCS.PC_TABLE_DESCR
       where PC_TABLE_ID = T.PC_TABLE_ID and
         PC_LANG_ID = (select PC_LANG_ID from PCS.PC_LANG
                       where LANID = 'EN')),
      TABDESCR
    )
  into lv_result
  from PCS.PC_TABLE T
  where TABNAME = iv_table_name;
  return lv_result;
end;

function p_publish_trigger_generator(
  it_options IN T_GEN_OPTIONS)
  return dbms_sql.VARCHAR2A
is
  main_column VARCHAR2(30);
  is_global_call BOOLEAN;
  csTable SYS_REFCURSOR;
  options T_GEN_OPTIONS;
  output_lines dbms_sql.VARCHAR2A;
  output_pos BINARY_INTEGER := 0;
begin
  -- Validation de la table et recherche du champ principal, s'il existe
  main_column := p_validate_table(Upper(it_options.table_name));

  options := it_options;
  options.table_name := Upper(options.table_name);
  options.trigger_name := case
    when options.trigger_name is not null then Upper(options.trigger_name)
    else options.table_name||'_AIU_REPLICATE'
  end;
  is_global_call := options.function_call = 'PublishRecord';
  options.function_call :=
    case when is_global_call then 'ln_result := ' end||
    'rep_functions.'||Lower(options.function_call)||'('||
      ':new.{'||Upper(main_column)||'}, '||
      case when is_global_call then ''''||options.table_name||'''' else 'ln_result' end||
    ')';

  if (options.script_comment) then
  output_lines(output_pos) :=
    '/**'||Chr(10)||
    '* Trigger '||options.trigger_name||Chr(10)||
    '*/'||Chr(10);
  output_pos := output_pos+1;
  end if;
  -- Génération du début de la commande
  output_lines(output_pos) :=
    'CREATE OR REPLACE TRIGGER '||options.trigger_name||Chr(10)||
    TAB||'after insert or update'||Chr(10)||
    TAB||'on '||options.table_name||Chr(10)||
    TAB||'referencing old as old new as new'||Chr(10)||
    TAB||'for each row'||Chr(10)||
    '/**'||Chr(10)||
    ' * Replication for table "'||p_table_descr(options.table_name)||'"'||Chr(10)||
    ' * @author '||Lower(Nvl(pcs.PC_I_LIB_SESSION.getusername,user))||Chr(10)||
    ' * @date '||to_char(sysdate,'mm/yyyy')||Chr(10)||
    ' * Modifications:'||Chr(10)||
    ' */'||Chr(10)||
    'declare'||Chr(10)||TAB||'ln_result INTEGER;'||Chr(10)||
    'begin'||Chr(10);
  output_pos := output_pos+1;

  output_lines(output_pos) :=
    TAB||'if (rep_lib_replicate.can_trigger_replicate(''REP_'||Substr(options.table_name,1,Instr(options.table_name,'_')-1)||'_TRIGGERS'') = 1) then'||Chr(10);
  output_pos := output_pos+1;

  if (options.test_values) then
    -- Parse et génère la liste des champs
    open csTable for
      select * from v_rep_field_info
      where table_name = options.table_name and main = 'N'
      order by case when usage = 'LINK' then 0 end, position;
    p_publish_trigger_generator(csTable, TAB2, output_lines, output_pos);
    close csTable;
    output_lines(output_pos) :=
      TAB2||TAB||options.function_call||';'||Chr(10)||
      TAB2||'end if;'||Chr(10);
  else
    -- Génère uniquement l'appel de publication
    output_lines(output_pos) :=
      TAB2||options.function_call||';'||Chr(10);
  end if;
  output_pos := output_pos+1;

  output_lines(output_pos) :=
    TAB||'end if;'||Chr(10);
  output_pos := output_pos+1;

  -- Génération la fin de la commande
  output_lines(output_pos) :=
    'end '||options.trigger_name||';'||Chr(10);
  --output_pos := output_pos+1;

  return output_lines;

  exception
    when OTHERS then
      output_lines(output_pos) := sqlerrm||Chr(10);
      output_lines(output_pos+1) := dbms_utility.format_error_stack||Chr(10);
      output_lines(output_pos+2) := dbms_utility.format_error_backtrace||Chr(10);
      return output_lines;
end;


procedure publish_trigger_generator(
  it_options IN T_GEN_OPTIONS,
  iov_script IN OUT NOCOPY CLOB)
is
  output_lines dbms_sql.VARCHAR2A;
  len BINARY_INTEGER;
  pos BINARY_INTEGER := 1;
begin
  output_lines := p_publish_trigger_generator(it_options);
  for cpt in output_lines.FIRST .. output_lines.LAST loop
    len := Length(output_lines(cpt));
    dbms_lob.Write(iov_script, len, pos, output_lines(cpt));
    pos := pos + len;
  end loop;
end;

procedure publish_trigger_generator(
  it_options IN T_GEN_OPTIONS)
is
  output_lines dbms_sql.VARCHAR2A;
begin
  output_lines := p_publish_trigger_generator(it_options);
  for cpt in output_lines.FIRST .. output_lines.LAST loop
    dbms_output.put(output_lines(cpt));
  end loop;

  -- Obligatoire sinon rien ne s'affiche dans le buffer d'output
  dbms_output.put_line('');

  exception
    when OTHERS then
      dbms_output.put_line(sqlerrm);
      dbms_output.put_line(dbms_utility.format_error_stack);
      dbms_output.put_line(dbms_utility.format_error_backtrace);
end;

procedure publish_trigger_generator(
  iv_table_name VARCHAR2,
  ib_test_values BOOLEAN default TRUE,
  iv_trigger_name VARCHAR2 default null,
  ib_script_comment BOOLEAN default TRUE,
  iv_function_call VARCHAR2 default 'PublishRecord')
is
  it_options T_GEN_OPTIONS;
begin
  it_options.table_name := iv_table_name;
  it_options.test_values := ib_test_values;
  it_options.trigger_name := iv_trigger_name;
  it_options.function_call := iv_function_call;
  it_options.script_comment := ib_script_comment;
  rep_reference.publish_trigger_generator(it_options);
end;


END REP_REFERENCE;
