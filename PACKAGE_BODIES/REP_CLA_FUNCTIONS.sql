--------------------------------------------------------
--  DDL for Package Body REP_CLA_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_CLA_FUNCTIONS" 
/**
 * Fonctions de génération de document Xml.
 * Spécialisation: Classification (CLA)
 *
 * @version 1.0
 * @date 09/2008
 * @author fperotto
 * @author spfister
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
AS

function get_classif_node_id(
  aKey IN classif_node.cln_unique_key%TYPE)
  return classif_node.classif_node_id%TYPE
is
  ln_result classif_node.classif_node_id%TYPE;
begin
  select classif_node_id
  into ln_result
  from classif_node
  where cln_unique_key = aKey;
  return ln_result;

  exception
    when NO_DATA_FOUND then return null;
end;


--
-- Classification
--

function get_classification_xml(
  Id IN classification.classification_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(CLASSIFICATIONS,
      XMLElement(CLASSIFICATION,
        XMLAttributes(
          classification_id as ID,
          pcs.pc_erp_version.Patchset as PATCHSET_NUMBER),
        XMLComment(rep_utils.GetCreationContext),
        XMLForest(
          'MAIN' as TABLE_TYPE,
          'CLA_UNIQUE_KEY' as TABLE_KEY,
          classification_id),
        rep_pc_functions_link.get_pc_object_link(pc_object_id),
        rep_pc_functions.get_descodes('C_CLASSIF_TYPE', c_classif_type),
        XMLForest(
          cla_unique_key,
          cla_key,
          cla_tablename,
          cla_descr,
          cla_multiple_leaves_instances,
          cla_multiple_nodes_instances,
          cla_level_display,
          cla_multi_tables,
          cla_translated,
          cla_uses_code,
          cla_code_format,
          cla_modified_classif,
          cla_flat_classif),
        rep_cla_functions.get_classif_tables(classification_id),
        rep_cla_functions.get_classif_level(classification_id),
        rep_cla_functions.get_classif_node(classification_id, 0.0)
      )
    ) into lx_data
  from classification
  where classification_id = Id;

  return lx_data;

  exception
    when OTHERS then
      lx_data := XmlErrorDetail(sqlerrm);
      select
        XMLElement(CLASSIFICATIONS,
          XMLElement(CLASSIFICATION,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_classif_tables(
  Id IN classification.classification_id%TYPE)
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
        'CLASSIFICATION_ID,CTA_TABLENAME' as TABLE_KEY,
        classif_tables_id,
        cta_tablename),
      rep_cla_functions.get_classif_sql_display(classif_tables_id)
    )) into lx_data
  from classif_tables
  where classification_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(CLASSIF_TABLES,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_classif_sql_display(
  Id IN classif_tables.classif_tables_id%TYPE)
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
        'CLASSIF_TABLES_ID' as TABLE_KEY,
        classif_sql_display_id,
        sql_display_code,
        sql)
     )) into lx_data
  from classif_sql_display
  where classif_tables_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(CLASSIF_SQL_DISPLAY,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_classif_level(
  Id IN classification.classification_id%TYPE)
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
        'CLASSIFICATION_ID,CLE_LEVEL' as TABLE_KEY,
        classif_level_id,
        cle_level,
        cle_sql_command_node,
        cle_sql_command_leaf)
    )) into lx_data
  from classif_level
  where classification_id = Id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(CLASSIF_LEVEL,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_classif_node(
  Id IN classification.classification_id%TYPE,
  aParentId IN classif_node.classif_node_id%TYPE
)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id is null or aParentId is null) then
    return null;
  end if;

  select
    XMLAgg(XMLElement(LIST_ITEM,
      XMLForest(
        'AFTER' as TABLE_TYPE,
        'CLN_UNIQUE_KEY' as TABLE_KEY,
        classif_node_id),
      rep_cla_functions_link.get_classif_node_link(cln_parent_id),
      XMLForest(
        cln_unique_key,
        cln_link_type,
        cln_code,
        cln_sqlauto,
        cln_free_char_1,
        cln_free_boolean_1,
        cln_free_number_1,
        cln_name),
      rep_cla_functions.get_classif_node_descr(classif_node_id),
      rep_cla_functions.get_classif_node(classification_id, classif_node_id)
    ) order by classif_node_id) into lx_data
  from classif_node
  where classification_id = Id and cln_parent_id = aParentId;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(CLASSIF_NODE,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_classif_node_descr(
  Id IN classif_node.classif_node_id%TYPE)
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
        'CLASSIF_NODE_ID,PC_LANG_ID' as TABLE_KEY,
        l.lanid,
        d.des_descr)
    )) into lx_data
  from pcs.pc_lang l, classif_node_descr d
  where classif_node_id = Id and l.pc_lang_id = d.pc_lang_id;
  -- Générer le tag principal uniquement s'il y a données
  if (lx_data is not null) then
    select
      XMLElement(CLASSIF_NODE_DESCR,
        XMLElement(LIST, lx_data)
      ) into lx_data
    from dual;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

END REP_CLA_FUNCTIONS;
