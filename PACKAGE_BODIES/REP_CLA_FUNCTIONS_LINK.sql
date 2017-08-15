--------------------------------------------------------
--  DDL for Package Body REP_CLA_FUNCTIONS_LINK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_CLA_FUNCTIONS_LINK" 
/**
 * Fonctions de génération de liaison pour document Xml.
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

function get_classification_link(
  Id IN classification.classification_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(CLASSIFICATION,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'CLA_UNIQUE_KEY' as TABLE_KEY,
        classification_id,
        cla_unique_key)
    ) into lx_data
  from classification
  where classification_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_classif_node_link(
  Id IN classif_node.classif_node_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(CLN_PARENT,
      XMLForest(
        'FUNCTION' as TABLE_TYPE,
        'REP_CLA_FUNCTIONS.GET_CLASSIF_NODE_ID' as FUNCTION_NAME),
      XMLElement(PARAMETERS,
        XMLElement(PARAMETER,
          XMLAttributes(1 as NUM, 'VARCHAR2' as type),
          cln_unique_key)
      )
    ) into lx_data
  from classif_node
  where classif_node_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_classif_tables_link(
  Id IN classif_tables.classif_tables_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(CLASSIF_TABLES,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'CLASSIFICATION_ID,CTA_TABLENAME' as TABLE_KEY,
        classif_tables_id,
        cta_tablename),
      rep_cla_functions_link.get_classification_link(classification_id)
    ) into lx_data
  from classif_tables
   where classif_tables_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

END REP_CLA_FUNCTIONS_LINK;
