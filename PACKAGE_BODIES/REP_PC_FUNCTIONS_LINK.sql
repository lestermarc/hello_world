--------------------------------------------------------
--  DDL for Package Body REP_PC_FUNCTIONS_LINK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_PC_FUNCTIONS_LINK" 
/**
 * Fonctions de génération de liaison pour document Xml.
 * Spécialisation: Environnement, dictionnaires et éléments communs (PCS)
 *
 * @version 1.0
 * @date 05/2003
 * @author jsomers
 * @author spfister
 * @author fperotto
 * @author ngomes
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
AS

function get_pc_curr_link(
  Id IN pcs.pc_curr.pc_curr_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(PC_CURR,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'CURRENCY' as TABLE_KEY,
        pc_curr_id,
        currency)
    ) into lx_data
  from pcs.pc_curr
  where pc_curr_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pc_fldsc_link(
  Id IN pcs.pc_fldsc.pc_fldsc_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XmlElement(PC_FLDSC,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'FLDNAME' as TABLE_KEY,
        pc_fldsc_id,
        fldname)
    ) into lx_data
  from pcs.pc_fldsc
  where pc_fldsc_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pc_fldsc_link_descr(
  Id IN pcs.pc_fldsc.pc_fldsc_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XmlElement(PC_FLDSC,
      XMLForest(
        'LINK_AFTER' as TABLE_TYPE,
        'FLDNAME' as TABLE_KEY,
        pc_fldsc_id,
        fldname),
      rep_pc_functions.get_pc_fdico(pc_fldsc_id)
    ) into lx_data
  from pcs.pc_fldsc
  where pc_fldsc_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pc_table_link(
  Id IN pcs.pc_table.pc_table_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(PC_TABLE,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'TABNAME' as TABLE_KEY,
        pc_table_id,
        tabname)
    ) into lx_data
  from pcs.pc_table
  where pc_table_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pc_cntry_link(
  Id IN pcs.pc_cntry.pc_cntry_id%TYPE,
  FieldRef IN VARCHAR2 default 'PC_CNTRY',
  ForceReference IN INTEGER default 0,
  IsMandatory IN INTEGER default 0)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(PC_CNTRY,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'CNTID' as TABLE_KEY,
        pc_cntry_id,
        cntid)
    ) into lx_data
  from pcs.pc_cntry
  where pc_cntry_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'PC_CNTRY') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('PC_CNTRY', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('PC_CNTRY', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pc_lang_link(
  Id IN pcs.pc_lang.pc_lang_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(PC_LANG,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'LANID' as TABLE_KEY,
        pc_lang_id,
        lanid)
    ) into lx_data
  from pcs.pc_lang
  where pc_lang_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pc_bank_link(
  Id IN pcs.pc_bank.pc_bank_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(PC_BANK,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'BAN_KEY' as TABLE_KEY,
        pc_bank_id,
        ban_key)
    ) into lx_data
  from pcs.pc_bank
  where pc_bank_id = Id;
  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pc_appltxt_link(
  Id IN pcs.pc_appltxt.pc_appltxt_id%TYPE,
  FieldRef IN VARCHAR2 default 'PC_APPLTXT',
  ForceReference IN INTEGER default 0,
  IsMandatory IN INTEGER default 0)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(PC_APPLTXT,
      XMLForest(
        'LINK'||case when (IsMandatory != 0) then '_MANDATORY' end as TABLE_TYPE,
        'C_TEXT_TYPE,DIC_PC_THEME_ID,APH_CODE' as TABLE_KEY,
        pc_appltxt_id),
      rep_pc_functions.get_descodes('C_TEXT_TYPE', c_text_type),
      XMLElement(DIC_PC_THEME,
        -- Lien sur le dictionnaire uniquement, car il appartient à l'environnement
        XMLForest(
          'PCS.DIC_PC_THEME' as TABLE_REFERENCE,
          'LINK' as TABLE_TYPE,
          'DIC_PC_THEME_ID' as TABLE_KEY,
          dic_pc_theme_id)
      ),
      XMLForest(
        aph_code)
    ) into lx_data
  from pcs.pc_appltxt
  where pc_appltxt_id = Id;

  if (lx_data is not null) then
    if (FieldRef != 'PC_APPLTXT') then
      if (ForceReference = 0) then
        return rep_xml_function.transform_root_ref('PC_APPLTXT', FieldRef, lx_data);
      else
        return rep_xml_function.transform_root_ref_table('PC_APPLTXT', FieldRef, lx_data);
      end if;
    end if;
    return lx_data;
  end if;

  return null;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pc_user_link(
  Id IN pcs.pc_user.pc_user_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(PC_USER,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'USE_NAME' as TABLE_KEY,
        pc_user_id,
        use_name
      ))
    into lx_data
  from pcs.pc_user
  where pc_user_id = Id;

  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pc_report_link(
  Id IN pcs.pc_report.pc_report_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(PC_REPORT,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'REP_REPNAME' as TABLE_KEY,
        pc_report_id,
        rep_repname
      ))
    into lx_data
  from pcs.pc_report
  where pc_report_id = Id;

  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

function get_pc_object_link(
  Id IN pcs.pc_object.pc_object_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  if (Id in (null,0)) then
    return null;
  end if;

  select
    XMLElement(PC_OBJECT,
      XMLForest(
        'LINK' as TABLE_TYPE,
        'OBJ_NAME' as TABLE_KEY,
        pc_object_id,
        obj_name
      ))
    into lx_data
  from pcs.pc_object
  where pc_object_id = Id;

  return lx_data;

  exception
    when NO_DATA_FOUND then return null;
end;

END REP_PC_FUNCTIONS_LINK;
