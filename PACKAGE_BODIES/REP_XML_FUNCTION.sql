--------------------------------------------------------
--  DDL for Package Body REP_XML_FUNCTION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_XML_FUNCTION" 
/**
 * Package utilitaire de transformation de document Xml.
 *
 * @version 1.0
 * @date 04/2005
 * @author spfister
 *
 * Copyright 1997-2013 SolvAxis SA. Tous droits réservés.
 */
AS


  /** Transformateur utilisé par la méthode transform_field_ref */
  gx_field_ref XMLType;
  /** Transformateur utilisé par les méthodes transform_root_ref et transform_root_ref_table */
  gx_root_ref XMLType;


--
-- Private methods
--

function p_get_xsl_field_ref
  return XMLType
is
begin
  if (gx_field_ref is null) then
    gx_field_ref := XMLType(
      '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">' ||
        '<xsl:param name="FieldSrc"/>' ||
        '<xsl:param name="FieldRef"/>' ||
        -- Copy everything from the input document
        '<xsl:template match="@*|node()">' ||
          '<xsl:copy><xsl:apply-templates select="@*|node()"/></xsl:copy>' ||
        '</xsl:template>' ||
        -- Rename the tag FieldSrc by FieldRef
        '<xsl:template match="*[name()=$FieldSrc]">' ||
          '<xsl:element name="{$FieldRef}">' ||
            '<xsl:apply-templates select="@*|node()"/>' ||
          '</xsl:element>' ||
        '</xsl:template>' ||
        -- Rename the tag FieldSrc||'_ID' by FieldRef||'_ID'
        '<xsl:template match="*[name()=concat($FieldSrc,''_ID'')]">' ||
          '<xsl:element name="{concat($FieldRef,''_ID'')}">' ||
            '<xsl:value-of select="."/>' ||
          '</xsl:element>' ||
        '</xsl:template>' ||
      '</xsl:stylesheet>'
    );
  end if;
  return gx_field_ref;
end;

function p_get_xsl_root_ref
  return XMLType
is
begin
  if (gx_root_ref is null) then
    gx_root_ref := XMLType(
      '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">' ||
        '<xsl:param name="FieldSrc"/>' ||
        '<xsl:param name="FieldRef"/>' ||
        '<xsl:param name="SetRef"/>' ||
        -- Copy everything from the input document
        '<xsl:template match="@*|node()">' ||
          '<xsl:copy><xsl:apply-templates select="@*|node()"/></xsl:copy>' ||
        '</xsl:template>' ||
        -- Rename the tag FieldSrc by FieldRef
        '<xsl:template match="*[name()=$FieldSrc]">' ||
          '<xsl:element name="{$FieldRef}">' ||
            -- Add the tag TABLE_REFERENCE as needed
            '<xsl:if test="$SetRef=1">' ||
              '<xsl:element name="TABLE_REFERENCE">' ||
                '<xsl:value-of select="$FieldSrc"/>' ||
              '</xsl:element>' ||
            '</xsl:if>' ||
            -- Copy all childs tag
            '<xsl:copy-of select="node()|@*"/>' ||
          '</xsl:element>' ||
        '</xsl:template>' ||
      '</xsl:stylesheet>'
    );
  end if;
  return gx_root_ref;
end;

function p_get_xsl_params(
  iv_field_src IN VARCHAR2,
  iv_field_ref IN VARCHAR2,
  SetRef IN INTEGER default null)
  return VARCHAR2
is
begin
  return 'FieldSrc="'''||iv_field_src||'''" FieldRef="'''||iv_field_ref||'''"'||
    case when SetRef is not null then ' SetRef="'''||to_char(SetRef)||'''"' end;
end;



function transform_field_ref(
  iv_field_src IN VARCHAR2,
  iv_field_ref IN VARCHAR2,
  ix_document IN XMLType)
  return XMLType
is
begin
  if (iv_field_src is not null and iv_field_ref is not null and
      iv_field_src != iv_field_ref and ix_document is not null) then
    return ix_document.transform(p_get_xsl_field_ref, p_get_xsl_params(iv_field_src, iv_field_ref));
  end if;

  return ix_document;
end;


function transform_root_ref(
  iv_field_src IN VARCHAR2,
  iv_field_ref IN VARCHAR2,
  ix_document IN XMLType)
  return XMLType
is
begin
  if (iv_field_src is not null and iv_field_ref is not null and
      iv_field_src != iv_field_ref and ix_document is not null) then
    return ix_document.transform(p_get_xsl_root_ref, p_get_xsl_params(iv_field_src, iv_field_ref, 0));
  end if;

  return ix_document;
end;

function transform_root_ref_table(
  iv_field_src IN VARCHAR2,
  iv_field_ref IN VARCHAR2,
  ix_document IN XMLType)
  return XMLType
is
begin
  if (iv_field_src is not null and iv_field_ref is not null and
      iv_field_src != iv_field_ref and ix_document is not null) then
    return ix_document.transform(p_get_xsl_root_ref, p_get_xsl_params(iv_field_src, iv_field_ref, 1));
  end if;

  return ix_document;
end;


function extract_value(
  ix_document IN XMLType,
  iv_xpath IN VARCHAR2)
  return VARCHAR2
is
  lv_result VARCHAR2(4000);
begin
  if (ix_document is not null and iv_xpath is not null) then
    select Extract(ix_document, iv_xpath).getStringVal() into lv_result
    from dual;
    return lv_result;
  end if;

  return null;
end;

END REP_XML_FUNCTION;
