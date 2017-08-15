--------------------------------------------------------
--  DDL for Package Body REP_LIB_UTILS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_LIB_UTILS" 
/**
 * Package utilitaires pour la réplication.
 *
 * @version 1.0
 * @date 02/2013
 * @author spfister
 *
 * Copyright 1997-2013 SolvAxis SA. Tous droits réservés.
 */
AS

  gv_CreationContext VARCHAR2(32767);

/**
 * Cette fonction sert à initialiser la variable locale gv_CreationContext
 * pour des raisons de performances.
 * L'appel de la méthode ne doit pas être fait à l'initialisation du package,
 * car la fonction COM_CurrentSchema peut ne pas aboutir à ce moment là.
 */
function GetCreationContext
  return VARCHAR2
is
begin
  if (gv_CreationContext is null) then
    gv_CreationContext :=
        ' by user '|| User ||
        ' from '|| sys_context('USERENV', 'HOST') ||
        ' on database '|| sys_context('USERENV', 'DB_UNIQUE_NAME') ||
        ' (instance '|| sys_context('USERENV', 'INSTANCE_NAME')||')' ||
        ' with module '|| sys_context('USERENV', 'MODULE') ||
        ' on schema '|| COM_CurrentSchema;
  end if;
  return 'generated at '|| to_char(SysTimestamp,'YYYY/MM/DD HH24:MI:SS.FF4')|| gv_CreationContext;
end;


function p_decode_tag(
  iv_tag IN VARCHAR2,
  on_type OUT BINARY_INTEGER)
  return VARCHAR2
is
begin
  on_type := 0;
  if (Substr(iv_tag,1,2) = 'C_') then
    return iv_tag||'/GCLCODE';
  elsif (Substr(iv_tag,1,4) = 'DIC_') then
    return Substr(iv_tag,1,Length(iv_tag)-3)||'/VALUE';
  elsif (Substr(iv_tag,-3) = '_ID') then
    on_type := 1;
    return Substr(iv_tag,1,Length(iv_tag)-3);
  else
    return iv_tag;
  end if;
end;

function p_extract_value(
  ix_document IN XMLTYPE)
  return VARCHAR2
is
  CV_BASE_XPATH CONSTANT VARCHAR2(10) := '*[1]';
  lv_key VARCHAR2(32767);
  ln_type BINARY_INTEGER;
  lv_result VARCHAR2(32767);
  lx_sub XMLType;
  lt_name_list fwk_i_typ_definition.TT_DATA_LIST;
  ln_count BINARY_INTEGER;
  lv_sep VARCHAR2(1);
begin
  -- extraction de la clé logique
  select ExtractValue(ix_document,CV_BASE_XPATH||'/TABLE_KEY')
  into lv_key
  from DUAL;
  -- sortie anticipée si aucune information
  if (lv_key is null) then
    return null;
  end if;
  -- détection du séparateur
  if (Instr(lv_key,',') > 0) then
    lv_sep := ',';
  elsif (Instr(lv_key,';') > 0) then
    lv_sep := ';';
  end if;
  -- extraction d'une valeur simple de la clé logique
  if (lv_sep is null) then
    lv_key := p_decode_tag(lv_key, ln_type);
    if (ln_type = 0) then
      select ExtractValue(ix_document, CV_BASE_XPATH||'/'||lv_key||'/text()')
      into lv_result
      from DUAL;
    else
      select Extract(ix_document, CV_BASE_XPATH||'/'||lv_key)
      into lx_sub
      from DUAL;
      lv_result := p_extract_value(lx_sub);
    end if;
    return Coalesce(lv_result,pcs.pc_functions.TranslateWord('<Vide>'));
  end if;
  -- chargement de la liste pour extraire les valeurs composants la clé
  fwk_i_lib_utils.comma_to_table(lv_key, lt_name_list, ln_count, lv_sep);
  for cpt in 1..ln_count loop
    lv_key := p_decode_tag(lt_name_list(cpt), ln_type);
    if (ln_type = 0) then
      select ExtractValue(ix_document, CV_BASE_XPATH||'/'||lv_key||'/text()')
      into lv_key
      from DUAL;
    else
      select Extract(ix_document, CV_BASE_XPATH||'/'||lv_key)
      into lx_sub
      from DUAL;
      lv_key := p_extract_value(lx_sub);
    end if;
    lv_result := lv_result || Coalesce(lv_key,pcs.pc_functions.TranslateWord('<Vide>')) || lv_sep;
  end loop;
  return RTrim(lv_result,lv_sep);
end;

function extract_entity_def(
  it_document IN CLOB)
  return VARCHAR2
is
begin
  if (it_document is not null and dbms_lob.getLength(it_document) > 0) then
    return rep_lib_utils.extract_entity_def(XMLType(it_document));
  end if;
  return null;
end;
function extract_entity_def(
  ix_document IN XMLType)
  return VARCHAR2
is
  lx_sub XMLType;
begin
  select Extract(ix_document, '/*[1]/*[1]')
  into lx_sub
  from dual;
  return p_extract_value(lx_sub);
end;

/**
 * Convertion d'un document Xml en texte, avec prologue.
 * @param ix_document  Document Xml original.
 * @return Un CLob contenant le texte du document Xml, ainsi qu'un prologue
 *         complet correspondant à l'encodage de la base.
 */
function XmlToClob(ix_document IN XMLType) return CLob is
begin
  if (ix_document is not null) then
    return pc_jutils.get_XMLPrologDefault ||Chr(10)|| ix_document.getClobVal();
  end if;

  return null;
end XmlToClob;


END REP_LIB_UTILS;
