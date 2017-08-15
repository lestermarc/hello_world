--------------------------------------------------------
--  DDL for Package Body ACI_MGT_XML_IMPORT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACI_MGT_XML_IMPORT" 
/**
 * Traitement des importations ACI-XML
 *
 * @date 04.2013
 * @author gpasche
 * @author spfister
 *
 * Copyright 1997-2013 SolvAxis SA. Tous droits réservés.
 */
is
  type tt_id is table of pcs.pc_aci_xml_import.pc_aci_xml_import_id%type;

  procedure import_documents
  is
    ltt_id TT_ID;
  begin
    select PC_ACI_XML_IMPORT_ID
    bulk collect into ltt_id
      from PCS.PC_ACI_XML_IMPORT
     where PC_COMP_ID = pcs.pc_init_session.getcompanyid
       and C_ACI_XML_IMPORT = pcs.pc_mgt_aci_XML_IMPORT.STATUS_TO_IMPORT;

    if (    ltt_id is not null
        and ltt_id.count > 0) then
      for cpt in ltt_id.first .. ltt_id.last loop
        aci_mgt_xml_import.import_document(ltt_id(cpt) );
      end loop;
    end if;
  end;

  procedure import_document(in_aci_xml_import_id in number)
  is
    pragma autonomous_transaction;
    lb_continue boolean;
  begin
    lb_continue  := aci_prc_xml_import.execute_proc_before_import(in_aci_xml_import_id);

    if (lb_continue) then
      lb_continue  := aci_prc_xml_import.execute_import(in_aci_xml_import_id);
    end if;

    if (lb_continue) then
      aci_prc_xml_import.execute_proc_after_import(in_aci_xml_import_id);
    end if;

    commit;
  exception
    when others then
      rollback;
  end;
end ACI_MGT_XML_IMPORT;
