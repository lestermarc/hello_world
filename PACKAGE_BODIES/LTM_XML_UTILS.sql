--------------------------------------------------------
--  DDL for Package Body LTM_XML_UTILS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "LTM_XML_UTILS" 
/**
 * Package LTM_XML_UTILS
 * @version 1.0
 * @date 02/2005
 * @author spfister
 *
 * Copyright 1997-2009 Sage Pro-Concept SA. Tous droits réservés.
 *
 * Package de génération de fragment Xml selon une commande sql dynamique.
 */
AS

  -- document xsl de transformation
  gx_root_ref XMLType;

  JAVA_CALL_UNCAUGHT_EXCEPTION EXCEPTION;
  pragma exception_init(JAVA_CALL_UNCAUGHT_EXCEPTION, -29532);


--
-- Public methods
--

function genXML(ctx IN dbms_xmlgen.ctxHandle,
  rowSetTagName IN VARCHAR2, rowTagName IN VARCHAR2 default null)
  return XMLType
is
  xmldata XMLType;
begin
  dbms_xmlgen.setRowSetTag(ctx, rowSetTagName);
  dbms_xmlgen.setRowTag(ctx, rowTagName);
  dbms_xmlgen.setConvertSpecialChars(ctx, TRUE);
  dbms_xmlgen.setCheckInvalidChars(ctx, TRUE);
  dbms_xmlgen.setPrettyPrinting(ctx, FALSE);
    -- DROP_NULLS | NULL_ATTR | EMPTY_TAG
  dbms_xmlgen.setNullHandling(ctx, dbms_xmlgen.DROP_NULLS);

  xmldata := dbms_xmlgen.getXMLType(ctx);

  if (dbms_xmlgen.GetNumRowsProcessed(ctx) = 0) then
    return null;
  end if;

  dbms_xmlgen.closeContext(ctx);
  return xmldata;

  exception
    when OTHERS then
      dbms_xmlgen.closeContext(ctx);
      raise;
end;

function genXML(sqlQuery IN VARCHAR2,
  rowSetTagName IN VARCHAR2, rowTagName IN VARCHAR2 default null)
  return XMLType
is
begin
  return ltm_xml_utils.genXML(
    dbms_xmlgen.newContext(sqlQuery), rowSetTagName, rowTagName);
end;
function genXML(sqlQuery IN SYS_REFCURSOR,
  rowSetTagName IN VARCHAR2, rowTagName IN VARCHAR2 default null)
  return XMLType
is
begin
  return ltm_xml_utils.genXML(
    dbms_xmlgen.newContext(sqlQuery), rowSetTagName, rowTagName);
end;


function genXMLQuery(ctx IN dbms_xmlquery.ctxType,
  rowSetTagName IN VARCHAR2, rowTagName IN VARCHAR2 default null)
  return XMLType
is
  xmldata XMLType;
begin
  dbms_xmlquery.setRowsetTag(ctx, rowSetTagName);
  dbms_xmlquery.setRowTag(ctx, rowTagName);
  dbms_xmlquery.setDateFormat(ctx, ltm_xml_utils.DEF_XML_DATE_FORMAT);
  dbms_xmlquery.setEncodingTag(ctx, ltm_xml_utils.DEF_XML_ENCODING_TAG);
  dbms_xmlquery.setRaiseException(ctx, true);
  dbms_xmlquery.setRaiseNoRowsException(ctx, true);
  dbms_xmlquery.propagateOriginalException(ctx, true);

  dbms_xmlquery.setRowIdAttrName(ctx, '');
  dbms_xmlquery.setRowIdAttrValue(ctx, '');

  xmldata := XMLType.CreateXML(dbms_xmlquery.getXML(ctx));
  dbms_xmlquery.closeContext(ctx);
  return xmldata;

  exception
    when JAVA_CALL_UNCAUGHT_EXCEPTION then
      if (Instr(sqlerrm, 'no data found') > 0) then
        -- ORA-29532: Java call terminated by uncaught Java exception:
        -- oracle.xml.sql.OracleXMLSQLNoRowsException: no data found
        return null;
      end if;
      raise;
    when OTHERS then
      dbms_xmlquery.closeContext(ctx);
      raise;
end;

function genXMLQuery(sqlQuery IN VARCHAR2,
  rowSetTagName IN VARCHAR2, rowTagName IN VARCHAR2 default null)
  return XMLType is
begin
  return ltm_xml_utils.genXMLQuery(
    dbms_xmlquery.newContext(sqlQuery), rowSetTagName, rowTagName);
end;
function genXMLQuery(sqlQuery IN CLOB,
  rowSetTagName IN VARCHAR2, rowTagName IN VARCHAR2 default null)
  return XMLType is
begin
  return ltm_xml_utils.genXMLQuery(
    dbms_xmlquery.newContext(sqlQuery), rowSetTagName, rowTagName);
end;


function transform_root_ref(FieldSrc IN VARCHAR2, FieldRef IN VARCHAR2,
  xmldata IN XMLType)
  return XMLType
is
begin
  if (FieldSrc is not null and FieldRef is not null and FieldSrc != FieldRef and
      xmldata is not null) then
    if (gx_root_ref is null) then
      gx_root_ref := XMLType(
        '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
          <xsl:param name="FieldSrc"/>
          <xsl:param name="FieldRef"/>'||
          -- Copy everything from the input document
          '<xsl:template match="@*|node()">
            <xsl:copy>
              <xsl:apply-templates select="@*|node()"/>
            </xsl:copy>
          </xsl:template>'||
          -- Rename the tag FieldSrc to FieldRef
          '<xsl:template match="*[name()=$FieldSrc]">
            <xsl:element name="{$FieldRef}">
              <xsl:copy-of select="node()|@*"/>
            </xsl:element>
          </xsl:template>
        </xsl:stylesheet>');
    end if;
    return xmldata.transform(gx_root_ref, 'FieldSrc="'''||FieldSrc||'''" FieldRef="'''||FieldRef||'''"');
  end if;
  return xmldata;

  exception
    when OTHERS then return null;
end;

/**
 * deprecated
 */
function GetErrorDetail(Message IN VARCHAR2) return XMLType is
begin
  return COM_XmlErrorDetail(Message);
end;

END LTM_XML_UTILS;
