--------------------------------------------------------
--  DDL for Package Body LTM_TRACK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "LTM_TRACK" 
/**
 * Package de génération de document XML pour les différentes entités supportées,
 * ainsi que l'enregistrement d'une version d'une entité par les methodes CHECKIN.
 *
 * @version 1.0
 * @date 02/2005
 * @author spfister
 * @author ireber
 * @author pyvoirol
 * @author rforchelet
 *
 * Copyright 1997-2010 SolvAxis SA. Tous droits réservés.
 */
AS

  -- package private global constants

  EN_COMMENT_REQUIRED CONSTANT NUMBER := -20100;
  EN_INVALID_SYSLOG_TYPE CONSTANT NUMBER := -20200;

  /**
   * Variable privée de context du schéma connecté.
   * L'initialisation ne doit pas être fait à l'initialisation du package,
   * car la fonction com_CurrentSchema peut ne pas aboutir à ce moment là.
   */
  gv_CurrentSchema VARCHAR2(30);

  /**
   * Curseur privé de recherche d'une entité.
   */
  cursor csEntity (Id IN ltm_entity_log.ltm_entity_log_id%TYPE) is
    select ELO_ENTITY
    from LTM_ENTITY_LOG
    where LTM_ENTITY_LOG_ID = Id;


/**
 * Convertion d'un document Xml en texte, avec prologue.
 * @param XmlDoc  Document Xml original.
 * @return Un CLob contenant le texte du document Xml, ainsi qu'un prologue
 *         complet correspondant à l'encodage de la base.
 */
function p_XmlToClob(XmlDoc IN XMLType) return CLob is
begin
  if (XmlDoc is not null) then
    return pc_jutils.get_XMLPrologDefault ||Chr(10)|| XmlDoc.getClobVal();
  end if;
  return null;
end;


/**
 * @deprecated
 */
function XML_ENCODING_DEF return VARCHAR2 is
begin
  return pc_jutils.get_XMLPrologDefault||Chr(10);
end;


function Article(Id IN gco_good.gco_good_id%TYPE) return CLob is
begin
  return p_XmlToClob(ltm_track.ArticleXMLType(Id));
end;
function ArticleXMLType(Id IN gco_good.gco_good_id%TYPE) return XMLType is
begin
  return ltm_track_log_functions.get_gco_good_xml(Id);
end;


function Dossier(Id IN doc_record.doc_record_id%TYPE) return CLob is
begin
  return p_XmlToClob(ltm_track.DossierXMLType(Id));
end;
function DossierXMLType(Id IN doc_record.doc_record_id%TYPE) return XMLType is
begin
  return ltm_track_log_functions.get_doc_record_xml(Id);
end;


function FalFactFloor(Id IN fal_factory_floor.fal_factory_floor_id%TYPE) return CLob is
begin
  return p_XmlToClob(ltm_track.FalFactFloorXMLType(Id));
end;
function FalFactFloorXMLType(Id IN fal_factory_floor.fal_factory_floor_id%TYPE) return XMLType is
begin
  return ltm_track_ind_functions.get_fal_fact_floor_xml(Id);
end;


function Personne(Id IN pac_person.pac_person_id%TYPE) return clob is
begin
  return p_XmlToClob(ltm_track.PersonneXMLType(Id));
end;
function PersonneXMLType(Id IN pac_person.pac_person_id%TYPE) return XMLType is
begin
  return ltm_track_pac_functions.get_pac_person_xml(Id);
end;


function Flux(Id IN doc_gauge_flow.doc_gauge_flow_id%TYPE) return CLob is
begin
  return p_XmlToClob(ltm_track.FluxXMLType(Id));
end;
function FluxXMLType(Id IN doc_gauge_flow.doc_gauge_flow_id%TYPE) return XMLType is
begin
  return ltm_track_log_functions.get_doc_gauge_flow_xml(Id);
end;


function HrmPerson(Id IN hrm_person.hrm_person_id%TYPE) return CLob is
begin
  return p_XmlToClob(ltm_track.HrmPersonXMLType(Id));
end;
function HrmPersonXMLType(Id IN hrm_person.hrm_person_id%TYPE) return XMLType is
begin
  return ltm_track_hrm_functions.get_hrm_person_xml(Id);
end;


function HrmDivision(Id IN hrm_division.hrm_division_id%TYPE) return CLob is
begin
  return p_XmlToClob(ltm_track.HrmDivisionXMLtype(Id));
end;
function HrmDivisionXMLtype(Id IN hrm_division.hrm_division_id%TYPE) return XMLtype is
begin
  return ltm_track_hrm_functions.get_hrm_division_xml(Id);
end;


function HrmJob(Id IN hrm_job.hrm_job_id%TYPE) return CLob is
begin
  return p_XmlToClob(ltm_track.HrmJobXMLType(Id));
end;
function HrmJobXMLType(Id IN hrm_job.hrm_job_id%TYPE) return XMLType is
begin
  return ltm_track_hrm_functions.get_hrm_job_xml(Id);
end;


function ElementsRoot(Id IN hrm_elements_root.hrm_elements_root_id%TYPE) return CLob is
begin
  return p_XmlToClob(ltm_track.ElementsRootXMLType(Id));
end;
function ElementsRootXMLType(Id IN hrm_elements_root.hrm_elements_root_id%TYPE) return XMLType is
begin
  return ltm_track_hrm_functions.get_hrm_elements_root_xml(Id);
end;


function Get_New_Entity_Xml(
  Id IN NUMBER, SysLogType IN ltm_entity_log.c_ltm_sys_log%TYPE)
  return CLob is
begin
  return p_XmlToClob(ltm_track.Get_New_Entity_XMLType(Id, SysLogType));
end;

function Get_New_Entity_XMLType(
  Id IN NUMBER, SysLogType IN ltm_entity_log.c_ltm_sys_log%TYPE)
  return XMLType
is
  lx_result XMLType;
  lv_date_fmt pcs.pc_lib_nls_parameters.NLS_NAME;
  lv_timestamp_fmt pcs.pc_lib_nls_parameters.NLS_NAME;
begin
  if (SysLogType not in ('01','02','03','04','05','06','07','08','09')) then
    raise_application_error(EN_INVALID_SYSLOG_TYPE,
      Nvl(SysLogType,'<null>')||' is an invalid or unknown log type');
  end if;

  lv_date_fmt := pcs.pc_lib_nls_parameters.SetDateFormat(ltm_track_utils.GetDefaultDateFormat);
  lv_timestamp_fmt := pcs.pc_lib_nls_parameters.SetTimestampFormat(ltm_track_utils.GetDefaultDateFormat);

  begin
    lx_result := case SysLogType
      when '01' then ltm_track.ArticleXMLType(Id)
      when '02' then ltm_track.HrmPersonXMLType(Id)
      when '03' then ltm_track.HrmDivisionXMLType(Id)
      when '04' then ltm_track.HrmJobXMLType(Id)
      when '05' then ltm_track.DossierXMLType(Id)
      when '06' then ltm_track.PersonneXMLType(Id)
      when '07' then ltm_track.FluxXMLType(Id)
      when '08' then ltm_track.ElementsRootXMLType(Id)
      when '09' then ltm_track.FalFactFloorXMLType(Id)
    end;

    exception
      when OTHERS then
        raise_application_error(-20010,
          'Error during entity '||pcs.pc_functions.GetDescodeDescr('C_LTM_SYS_LOG', SysLogType)||' generation for '||to_char(Id)||Chr(10)||
          sqlerrm||Chr(10)||dbms_utility.format_error_stack);
  end;

  if (lv_date_fmt is not null) then
    lv_date_fmt := pcs.pc_lib_nls_parameters.SetDateFormat(lv_date_fmt);
  end if;
  if (lv_timestamp_fmt is not null) then
    lv_timestamp_fmt := pcs.pc_lib_nls_parameters.SetTimestampFormat(lv_timestamp_fmt);
  end if;

  return lx_result;
end;


function CheckIn(Id IN ltm_entity_log.elo_rec_id%TYPE,
  SysLogType IN ltm_entity_log.c_ltm_sys_log%TYPE)
  return INTEGER is
begin
  return ltm_track.CheckIn(Id, SysLogType, '', pcs.PC_I_LIB_SESSION.getuserini, 1);
end;
function CheckIn(Id IN ltm_entity_log.elo_rec_id%TYPE,
  SysLogType IN ltm_entity_log.c_ltm_sys_log%TYPE,
  Commentary IN ltm_entity_log.elo_info%TYPE)
  return INTEGER is
begin
  return ltm_track.CheckIn(Id, SysLogType, Commentary, pcs.PC_I_LIB_SESSION.getuserini, 1);
end;
function CheckIn(Id IN ltm_entity_log.elo_rec_id%TYPE,
  SysLogType IN ltm_entity_log.c_ltm_sys_log%TYPE,
  Commentary IN ltm_entity_log.elo_info%TYPE,
  Author IN ltm_entity_log.elo_author%TYPE)
  return INTEGER is
begin
  return ltm_track.CheckIn(Id, SysLogType, Commentary, pcs.PC_I_LIB_SESSION.getuserini, 1);
end;
function CheckIn(Id IN ltm_entity_log.elo_rec_id%TYPE,
  SysLogType IN ltm_entity_log.c_ltm_sys_log%TYPE,
  Commentary IN ltm_entity_log.elo_info%TYPE,
  Author IN ltm_entity_log.elo_author%TYPE,
  CheckConfig IN INTEGER)
  return INTEGER
is
  ln_result INTEGER := 0;
  ln_require_comment pcs.pc_sys_log.slo_require_comment%TYPE;
  lx_entity XMLType;
begin
  begin
    if (Commentary is null and CheckConfig <> 0) then
      if (gv_CurrentSchema is null) then
        gv_CurrentSchema := COM_CurrentSchema;
      end if;

      select L.SLO_REQUIRE_COMMENT
      into ln_require_comment
      from PCS.PC_SCRIP S, PCS.PC_COMP C, PCS.PC_SYS_LOG L
      where L.C_LTM_SYS_LOG = SysLogType and
        L.PC_COMP_ID = C.PC_COMP_ID and
        S.PC_SCRIP_ID = C.PC_SCRIP_ID and
        S.SCRDBOWNER = gv_CurrentSchema;
      if (ln_require_comment <> 0) then
        raise EX_COMMENT_REQUIRED;
      end if;
    end if;

    lx_entity := ltm_track.Get_New_Entity_XMLType(Id, SysLogType);
    insert into LTM_ENTITY_LOG (
      LTM_ENTITY_LOG_ID, C_LTM_SYS_LOG, ELO_INFO,
      ELO_ENTITY,
      ELO_AUTHOR, ELO_REC_ID
    ) values (
      init_id_seq.nextval, SysLogType, Commentary,
      lx_entity,
      Author, Id
    );

    ln_result := 1;

    exception
      when EX_COMMENT_REQUIRED then
        raise_application_error(EN_COMMENT_REQUIRED, 'Comment is required');
      when OTHERS then
        raise_application_error(-20000,
          'Error during entity '||pcs.pc_functions.GetDescodeDescr('C_LTM_SYS_LOG', SysLogType)||' checkin for '||to_char(Id)||Chr(10)||
          sqlerrm||Chr(10)||dbms_utility.format_error_stack);
  end;

  return ln_result;
end;

function Get_Histo_Entity_Xml(Id IN ltm_entity_log.ltm_entity_log_id%TYPE)
  return CLob
is
  lx_result XMLType;
begin
  open csEntity(Id);
  fetch csEntity into lx_result;
  close csEntity;
  return p_XmlToClob(lx_result);

  exception
    when OTHERS then
      return null;
end;

END LTM_TRACK;
