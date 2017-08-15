--------------------------------------------------------
--  DDL for Package Body ACR_PRC_EDO_XML
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACR_PRC_EDO_XML" 
is
  /**
  * Description :
  *   Construction du document XML
  */
  procedure GenerateXML(iACR_EDO_ID in ACR_EDO.ACR_EDO_ID%type, oXml out ACR_EDO.EDO_XML%type)
  is
  begin
    oXml  := acr_lib_edo_xml.GetEdoFinXML(iACR_EDO_ID);
  end GenerateXML;

  /**
  * Description :
  *   Retourne le document XSD de validation
  */
  function GetXsdSchema
    return ACR_EDO.EDO_XML%type
  is
    vResult ACR_EDO.EDO_XML%type;
  begin
    select XSD_SCHEMA
      into vResult
      from PCS.PC_XSD_SCHEMA
     where XSD_NAME = 'XSD_ACR_EDO';

    return vResult;
  end GetXsdSchema;
end ACR_PRC_EDO_XML;
