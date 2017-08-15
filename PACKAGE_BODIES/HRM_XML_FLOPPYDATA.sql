--------------------------------------------------------
--  DDL for Package Body HRM_XML_FLOPPYDATA
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_XML_FLOPPYDATA" 
IS

  /**
   * Fonctions interne récursive de génération du texte de document Xml depuis
   * les données flexibles d'une personne.
   *
   * Cette fonction doit être remplacée par une version qui utilise le package
   * dmbs_xmldom qui est plus efficace et plus simple à utiliser.
   * De plus, les curseurs peuvent être remplacé par un seul du genre:
   *    SELECT
   *      case xml_type
   *        when 1 then 'ELEMENT'
   *        when 2 then 'ATTRIBUTE'
   *      end NodeType,
   *      xml_tag, xml_value
   *    FROM hrm_person_xml
   *    where hrm_person_id = :hrm_person_id
   *    START WITH xml_parent_id is null
   *    CONNECT BY PRIOR xml_seq_id = xml_parent_id
   *
   * Le premier noeud parent est toujours 0 (zéro).
   * @param PersonId  Identifiant de la personne.
   * @param ParentId  Identifiant du noeud parent.
   * @return le texte formaté du document Xml.
   */
  function p_genFloppyData(
    PersonId IN hrm_person.hrm_person_id%TYPE,
    ParentId IN hrm_person_xml.xml_parent_id%TYPE default 0)
    return CLOB
  is
    -- Curseur des attributs d'un noeud
    cursor csAttributes(PersonId IN hrm_person.hrm_person_id%TYPE,
                        ParentId IN hrm_person_xml.xml_parent_id%TYPE) is
      SELECT xml_tag||'="'||xml_value||'"' XML_ATTRIBUTE
      FROM hrm_person_xml
      WHERE xml_type = 2 and hrm_person_id = PersonId and nvl(xml_parent_id,0) = ParentId;
    rtAttr csAttributes%ROWTYPE;
    -- Curseur des noeuds enfants
    cursor csChildNodes(PersonId IN hrm_person.hrm_person_id%TYPE,
                        ParentId IN hrm_person_xml.xml_parent_id%TYPE) is
      SELECT
        xml_seq_id NODE,
        xml_tag XML_TAG,
        xml_value XML_VALUE
      FROM hrm_person_xml
      WHERE xml_type = 1 and hrm_person_id = PersonId and nvl(xml_parent_id,0) = ParentId;
    rtChild csChildNodes%ROWTYPE;
    -- Variables locales
    strResult VARCHAR2(32767);
  begin
    -- Recherche des attributs du noeud parent.
    if (ParentId > 0) then
      open csAttributes(PersonId, ParentId);
      loop
        fetch csAttributes into rtAttr;
        exit when csAttributes%NOTFOUND;
        strResult := strResult ||' '|| rtAttr.XML_ATTRIBUTE;
      end loop;
      close csAttributes;

      -- Ferme le tag parent
      strResult := strResult ||'>';
    end if;

    -- Recherche des noeuds enfants
    open csChildNodes(PersonId, ParentId);
    loop
      fetch csChildNodes into rtChild;
      exit when csChildNodes%NOTFOUND;
      -- Tag de début avec ses attributs et ses enfants
      strResult := strResult ||'<'|| rtChild.XML_TAG || p_genFloppyData(PersonId, rtChild.Node);
      -- Valeur du tag
      if rtChild.XML_VALUE is not null then
        strResult := strResult || dbms_xmlgen.convert(rtChild.XML_VALUE);
      end if;
      -- Tag de fin
      strResult := strResult ||'</'|| rtChild.XML_TAG ||'>';
    end loop;
    close csChildNodes;

    return strResult;
  end;

  function p_genXmlFloppyData(
    PersonId IN hrm_person.hrm_person_id%TYPE)
    return CLOB
  is
    xFloppyData XMLType;
    result CLOB;
    xDocument dbms_xmldom.DOMDocument;
  begin
    xFloppyData := XMLType.CreateXml(p_genFloppyData(PersonId));
    begin
      xDocument := dbms_xmldom.newDOMDocument(xFloppyData);
      dbms_xmldom.writetoclob(xDocument, result);
      dbms_xmldom.freedocument(xDocument);
    exception
      when others then
        return null;
    end;
    return result;
  end;

  function getPersonFloppyData_XMLType(
    PersonId IN hrm_person.hrm_person_id%TYPE)
    return XMLType
  is
  begin
    return XMLType.CreateXml(p_genXmlFloppyData(PersonId));
  end;

  function getPersonFloppyData(
    PersonId IN hrm_person.hrm_person_id%TYPE)
    return CLOB
  is
  begin
    return p_genXmlFloppyData(PersonId);
  end;


END HRM_XML_FLOPPYDATA;
