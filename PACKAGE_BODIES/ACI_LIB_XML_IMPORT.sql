--------------------------------------------------------
--  DDL for Package Body ACI_LIB_XML_IMPORT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACI_LIB_XML_IMPORT" 
/**
 * Importations ACI-XML
 *
 * @date 04.2013
 * @author gpasche
 * @author spfister
 *
 * Copyright 1997-2013 SolvAxis SA. Tous droits réservés.
 */
is
  function get_aci_xml(in_pc_aci_xml_import_id in number)
    return xmltype
  is
    lv_result clob;
  begin
    select AXI_XML
      into lv_result
      from PCS.PC_ACI_XML_IMPORT
     where PC_ACI_XML_IMPORT_ID = in_pc_aci_xml_import_id;

    return xmltype(lv_result);
  end;
end ACI_LIB_XML_IMPORT;
