--------------------------------------------------------
--  DDL for Package Body LTM_TRACK_PC_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "LTM_TRACK_PC_FUNCTIONS" 
/**
 * Package LTM_TRACK_PC_FUNCTIONS
 * @version 1.0
 * @date 05/2008
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

function get_com_image_files(Id IN com_image_files.imf_rec_id%TYPE,
  TabName IN com_image_files.imf_table%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(
      ltm_xml_utils.genXML(CURSOR(
         select * from com_image_files
         where com_image_files_id = T.com_image_files_id),
        'COM_IMAGE_FILES')
      order by imf_image_index, imf_sequence
    ) into obj
  from com_image_files T
  where imf_rec_id = Id and imf_table = TabName;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_com_vfields_record(Id IN com_vfields_record.vfi_rec_id%TYPE,
  TabName IN com_vfields_record.vfi_tabname%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(
      ltm_xml_utils.genXML(CURSOR(
        select * from com_vfields_record
        where com_vfields_record_id = T.com_vfields_record_id),
        'COM_VFIELDS_RECORD')
      order by a_datecre
    ) into obj
  from com_vfields_record T
  where vfi_rec_id = Id and vfi_tabname = TabName;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_com_vfields_value(Id in com_vfields_value.cvf_rec_id%TYPE,
  TabName in com_vfields_value.cvf_tabname%TYPE)
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    XMLAgg(
      ltm_xml_utils.genXML(CURSOR(
        select * from com_vfields_value
        where com_vfields_value_id = T.com_vfields_value_id),
        'COM_VFIELDS_VALUE')
      order by a_datecre, cvf_fldname
    ) into obj
  from com_vfields_value T
  where cvf_rec_id = Id and cvf_tabname = TabName;
  return obj;

  exception
    when OTHERS then return null;
end;


END LTM_TRACK_PC_FUNCTIONS;
