--------------------------------------------------------
--  DDL for Package Body HRM_XML_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_XML_FUNCTIONS" 
AS

  -- Liste des identifiants des GS à exporter
  TYPE ElementsRootType IS TABLE OF
    hrm_elements_root.hrm_elements_root_id%TYPE
    INDEX BY BINARY_INTEGER;
  -- Liste des identifiants des listes de contrôle à exporter
  TYPE ControlListType IS TABLE OF
    hrm_control_list.hrm_control_list_id%TYPE
    INDEX BY BINARY_INTEGER;

  /**
   * Variables locales d'enregistrements des identifiants
   * à utiliser pour la généreration de documents Xml
   */
  gtt_root_id ElementsRootType;
  gtt_list_id ControlListType;

  -- Constantes pour la génération d'une liste de GS
  gv_c_root_begin_sql CONSTANT VARCHAR2(28) := ' or hrm_elements_root_id in(';
  gv_c_root_end_sql CONSTANT VARCHAR2(2) := ')'||Chr(10);

  -- Constantes pour la génération d'une liste de listes de contrôle
  gv_c_list_begin_sql CONSTANT VARCHAR2(27) := ' or hrm_control_list_id in(';
  gv_c_list_end_sql CONSTANT VARCHAR2(2) := ')'||Chr(10);


--
-- Internal implementation
--

/**
 * Convertion d'un document Xml en texte, avec prologue.
 * @param XmlDoc  Document Xml original.
 * @return Un CLOB contenant le texte du document Xml, ainsi qu'un prologue
 *         complet correspondant à l'encodage de la base.
 */
function p_XmlToClob(
  XmlDoc IN XMLType)
  return CLOB
is
begin
  if (XmlDoc is not null) then
    return pc_jutils.get_XMLPrologDefault ||Chr(10)|| XmlDoc.getClobVal();
  end if;
  return null;
end;


--
-- Roots managment
--

procedure add_elements_root_id(Id IN hrm_elements_root.hrm_elements_root_id%TYPE)
is
begin
  gtt_root_id(gtt_root_id.COUNT+1) := Id;
end;

procedure clear_elements_root
is
begin
  gtt_root_id.DELETE;
end;

function count_elements_root return INTEGER
is
begin
  return gtt_root_id.COUNT;
end;


--
-- Lists managment
--

procedure add_control_list(Id IN hrm_control_list.hrm_control_list_id%TYPE)
is
begin
  gtt_list_id(gtt_list_id.COUNT+1) := Id;
end;

procedure clear_control_list
is
begin
  gtt_list_id.DELETE;
end;

function count_control_list return INTEGER
is
begin
  return gtt_list_id.COUNT;
end;


/************/
/** Payroll */
/************/

function get_elements_root_xml return CLob is
begin
  return p_XmlToClob(hrm_xml_functions.get_elements_root_XMLType);
end;
function get_elements_root_XMLType
  return XMLType
is
  lx_data XMLType;
  lv_members VARCHAR2(32767);
  lv_id VARCHAR2(32767);
begin
  if (gtt_root_id.COUNT = 0) then
    return null;
  end if;

  for cpt in gtt_root_id.FIRST..gtt_root_id.LAST loop
    lv_id := lv_id ||','|| to_char(gtt_root_id(cpt));
    if not((cpt Mod 250) > 0) and (cpt > 0) then
      lv_members := lv_members ||gv_c_root_begin_sql|| LTrim(lv_id, ',') ||gv_c_root_end_sql;
      lv_id := '';
    end if;
  end loop;
  if (lv_id is not null) then
    lv_members := lv_members ||gv_c_root_begin_sql|| LTrim(lv_id, ',') ||gv_c_root_end_sql;
  end if;
  if (lv_members is not null) then
    lv_members := Substr(lv_members, 5);
  end if;

  -- Extraction et concaténation dynamique de tous les GS désirés
  rep_lib_nls_parameters.SetNLSFormat;
  EXECUTE IMMEDIATE
      'select
        XMLElement(ROOTS,
          XMLAttributes(''2'' as version, to_char(sysdate,''yyyy/mm/dd'') as revision,
              pcs.PC_I_LIB_SESSION.GetUserIni2 as author),
          XMLComment(rep_utils.GetCreationContext),
          (select XMLAgg(Value(p))
           from TABLE(XMLSequence(Extract(
             (select XMLAgg(rep_hrm_functions.get_hrm_elements_root_xml(hrm_elements_root_id))
              from hrm_elements_root
              where '||lv_members||'),''/ROOTS/*'') )) p
          )
        )
      from dual'
      INTO lx_data;
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_data;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      for cpt in gtt_root_id.FIRST..gtt_root_id.LAST loop
        lv_id := lv_id ||','|| to_char(gtt_root_id(cpt));
      end loop;
      lv_id := 'mulipart ('|| LTrim(lv_id, ',') ||')';
      lx_data := com_XmlErrorDetail(sqlerrm);
      select
        XMLElement(ROOTS,
          XMLElement(HRM_ELEMENTS_ROOT,
          XMLAttributes(lv_id as ID),
          XMLComment(rep_utils.GetCreationContext),
          lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_elements_root_xml(Id IN hrm_elements_root.hrm_elements_root_id%TYPE)
  return CLob is
begin
  return p_XmlToClob(hrm_xml_functions.get_elements_root_XMLType(Id));
end;
function get_elements_root_XMLType(Id IN hrm_elements_root.hrm_elements_root_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  select
    XMLElement(ROOTS,
      XMLAttributes('2' as version, to_char(sysdate,'yyyy/mm/dd') as revision,
          pcs.PC_I_LIB_SESSION.GetUserIni2 as author),
      XMLComment(rep_utils.GetCreationContext),
     (select XMLAgg(Value(p))
      from TABLE(XMLSequence(Extract(rep_hrm_functions.get_hrm_elements_root_xml(Id), '/ROOTS/*') )) p
      )
    ) into lx_data
  from dual;
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_data;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      lx_data := com_XmlErrorDetail(sqlerrm);
      select
        XMLElement(ROOTS,
          XMLElement(HRM_ELEMENTS_ROOT,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;


/*****************/
/** Control List */
/*****************/

function get_control_list_xml return CLob is
begin
  return p_XmlToClob(hrm_xml_functions.get_control_list_XMLType);
end;
function get_control_list_XMLType return XMLType
is
  lx_data XMLType;
  lv_members VARCHAR2(32767);
  lv_id VARCHAR2(32767);
begin
  if (gtt_list_id.COUNT = 0) then
    return null;
  end if;

  for cpt in gtt_list_id.FIRST..gtt_list_id.LAST loop
    lv_id := lv_id ||','|| to_char(gtt_list_id(cpt));
    if not((cpt Mod 250) > 0) and (cpt > 0) then
      lv_members := lv_members ||gv_c_list_begin_sql|| LTrim(lv_id, ',') ||gv_c_list_end_sql;
      lv_id := '';
    end if;
  end loop;
  if (lv_id is not null) then
    lv_members := lv_members ||gv_c_list_begin_sql|| LTrim(lv_id, ',') ||gv_c_list_end_sql;
  end if;
  if (lv_members is not null) then
    lv_members := Substr(lv_members, 5);
  end if;

  rep_lib_nls_parameters.SetNLSFormat;
  EXECUTE IMMEDIATE
      'select
        XMLElement(LISTS,
          XMLAttributes(''2'' as version, to_char(sysdate,''yyyy/mm/dd'') as revision,
              pcs.PC_I_LIB_SESSION.GetUserIni2 as author),
          XMLComment(rep_utils.GetCreationContext),
          (select XMLAgg(Value(p))
           from TABLE(XMLSequence(Extract(
             (select XMLAgg(rep_hrm_functions.get_hrm_control_list_xml(hrm_control_list_id))
              from hrm_control_list
              where '||lv_members||'),''/LISTS/*'') )) p
          )
        )
      from dual'
      INTO lx_data;
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_data;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      for cpt in gtt_list_id.FIRST..gtt_list_id.LAST loop
        lv_id := lv_id ||','|| to_char(gtt_list_id(cpt));
      end loop;
      lv_id := 'mulipart ('|| LTrim(lv_id, ',') ||')';
      lx_data := com_XmlErrorDetail(sqlerrm);
      select
        XMLElement(LISTS,
          XMLElement(HRM_CONTROL_LIST,
          XMLAttributes(lv_id as ID),
          XMLComment(rep_utils.GetCreationContext),
          lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

function get_control_list_xml(Id IN hrm_control_list.hrm_control_list_id%TYPE)
  return CLob is
begin
  return p_XmlToClob(hrm_xml_functions.get_control_list_XMLType(Id));
end;
function get_control_list_XMLType(Id IN hrm_control_list.hrm_control_list_id%TYPE)
  return XMLType
is
  lx_data XMLType;
begin
  rep_lib_nls_parameters.SetNLSFormat;
  select
    XMLElement(LISTS,
      XMLAttributes('2' as version, to_char(sysdate,'yyyy/mm/dd') as revision,
          pcs.PC_I_LIB_SESSION.GetUserIni2 as author),
      XMLComment(rep_utils.GetCreationContext),
     (select XMLAgg(Value(p))
      from TABLE(XMLSequence(Extract(rep_hrm_functions.get_hrm_control_list_xml(Id), '/LISTS/*') )) p
      )
    ) into lx_data
  from dual;
  rep_lib_nls_parameters.ResetNLSFormat;
  return lx_data;

  exception
    when OTHERS then
      rep_lib_nls_parameters.ResetNLSFormat;
      lx_data := com_XmlErrorDetail(sqlerrm);
      select
        XMLElement(LISTS,
          XMLElement(HRM_CONTROL_LIST,
            XMLAttributes(Id as ID),
            XMLComment(rep_utils.GetCreationContext),
            lx_data
        )) into lx_data
      from dual;
      return lx_data;
end;

END HRM_XML_FUNCTIONS;
