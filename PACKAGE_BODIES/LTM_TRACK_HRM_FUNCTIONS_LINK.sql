--------------------------------------------------------
--  DDL for Package Body LTM_TRACK_HRM_FUNCTIONS_LINK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "LTM_TRACK_HRM_FUNCTIONS_LINK" 
/**
 * Package LTM_TRACK_HRM_FUNCTIONS_LINK
 * @version 1.0
 * @date 10/2006
 * @author rhermann
 * @author ireber
 * @author spfister
 * @since Oracle 9.2
 *
 * Copyright 1997-2008 Pro-Concept SA. Tous droits réservés.
 *
 * Package contenant les fonctions de génération de document Xml pour des
 * liaisons sur des clés étrangères.
 * Spécialisation: Resources humaines (HRM)
 */
AS

function get_hrm_competence_link(Id IN hrm_competence.hrm_competence_id%TYPE,
  FieldRef in VARCHAR2 default 'HRM_COMPETENCE')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select hrm_competence_id, com_code, com_export_code, dic_competence_type_id,
        dic_competence_category_id, dic_competence_family_id
      from hrm_competence
      where hrm_competence_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_hrm_job_link(Id IN hrm_job.hrm_job_id%TYPE,
  FieldRef IN VARCHAR2 default 'HRM_JOB')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select hrm_job_id, job_code, dic_department_id, job_title, job_descr
      from hrm_job
      where hrm_job_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_hrm_person_link(Id IN hrm_person.hrm_person_id%TYPE,
  FieldRef IN VARCHAR2 default 'HRM_PERSON')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select hrm_person_id, per_last_name, per_first_name, emp_number
      from hrm_person
      where hrm_person_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_hrm_occupation_descr_link(Id IN hrm_occupation.hrm_occupation_id%TYPE,
  FieldRef IN VARCHAR2 default 'HRM_OCCUPATION_DESCR')
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
        select o.hrm_occupation_id, l.lanid, o.occ_code, d.ocd_title
        from pcs.pc_lang l, hrm_occupation_descr d, hrm_occupation o
        where o.hrm_occupation_id = T.hrm_occupation_id and
          d.hrm_occupation_id = o.hrm_occupation_id and
          l.pc_lang_id = T.pc_lang_id and
          d.pc_lang_id = l.pc_lang_id),
        FieldRef)
      order by a_datecre
    ) into obj
  from hrm_occupation_descr T
  where hrm_occupation_id = Id;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_hrm_training_link(Id IN hrm_training.hrm_training_id%TYPE,
  FieldRef IN VARCHAR2 default 'HRM_TRAINING')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select hrm_training_id, tra_code, tra_title, tra_description
      from hrm_training
      where hrm_training_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

function get_hrm_session_link(Id IN hrm_session.hrm_session_id%TYPE,
  FieldRef IN VARCHAR2 default 'HRM_SESSION')
  return XMLType
is
  obj XMLType;
begin
  if (Id is null) then
    return null;
  end if;

  select
    ltm_xml_utils.genXML(CURSOR(
      select hrm_session_id, ses_begin_date, ses_end_date, ses_location
      from hrm_session
      where hrm_session_id = Id),
      FieldRef
    ) into obj
  from dual;
  return obj;

  exception
    when OTHERS then return null;
end;

END LTM_TRACK_HRM_FUNCTIONS_LINK;
