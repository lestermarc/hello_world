--------------------------------------------------------
--  DDL for Package Body LTM_TRACK_PC_FUNCTIONS_LINK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "LTM_TRACK_PC_FUNCTIONS_LINK" 
/**
 * Package LTM_TRACK_PC_FUNCTIONS_LINK
 * @version 1.0
 * @date 10/2006
 * @author rforchelet
 * @author spfister
 * @since Oracle 9.2
 *
 * Copyright 1997-2008 Pro-Concept SA. Tous droits réservés.
 *
 * Package contenant les fonctions de génération de document Xml pour des
 * liaisons sur des clés étrangères.
 * Spécialisation: Environnement (PC)
 */
AS

function get_pc_curr_link(Id IN pcs.pc_curr.pc_curr_id%TYPE,
  FieldRef IN VARCHAR2 default 'PC_CURR')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select pc_curr_id, currency
      from pcs.pc_curr
      where pc_curr_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pc_appltxt_link(Id IN pcs.pc_appltxt.pc_appltxt_id%TYPE,
  FieldRef IN VARCHAR2 default 'PC_APPLTXT')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select pc_appltxt_id, c_text_type, dic_pc_theme_id, aph_code
      from pcs.pc_appltxt
      where pc_appltxt_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pc_lang_link(Id IN pcs.pc_lang.pc_lang_id%TYPE,
  FieldRef IN VARCHAR2 default 'PC_LANG')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select pc_lang_id, lanid
      from pcs.pc_lang
      where pc_lang_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pc_cntry_link(Id IN pcs.pc_cntry.pc_cntry_id%TYPE,
  FieldRef IN VARCHAR2 default 'PC_CNTRY')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select pc_cntry_id, cntid
      from pcs.pc_cntry
      where pc_cntry_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pc_user_link(Id IN pcs.pc_user.pc_user_id%TYPE,
  FieldRef IN VARCHAR2 default 'PC_CNTRY')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select pc_user_id, use_name
      from pcs.pc_user
      where pc_user_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_pc_bank_link(Id IN pcs.pc_bank.pc_bank_id%TYPE,
  FieldRef IN VARCHAR2 default 'PC_BANK')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select pc_bank_id, ban_name1, ban_clear, ban_city
      from pcs.pc_bank
      where pc_bank_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

END LTM_TRACK_PC_FUNCTIONS_LINK;
