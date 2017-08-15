--------------------------------------------------------
--  DDL for Package Body ACI_PRC_XML_IMPORT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACI_PRC_XML_IMPORT" 
/**
 * Exécution des importations ACI-XML
 *
 * @date 04.2013
 * @author gpasche
 * @author spfister
 *
 * Copyright 1997-2013 SolvAxis SA. Tous droits réservés.
 */
is
/**
 * Insertion de l'aci_document_status pour déclencher l'intégration ACI
 */
  procedure p_insert_aci_document_status(in_aci_document_id in number)
  is
    lv_financial_link varchar2(10);
  begin
    -- Status entête interface finance
    select nvl(min(TYP.C_ACI_FINANCIAL_LINK), '3')
      into lv_financial_link
      from ACJ_JOB_TYPE_S_CATALOGUE JCA
         , ACJ_JOB_TYPE TYP
         , ACJ_CATALOGUE_DOCUMENT CAT
         , ACI_DOCUMENT DOC
     where DOC.ACI_DOCUMENT_ID = in_aci_document_id
       and CAT.CAT_KEY = DOC.CAT_KEY
       and TYP.TYP_KEY = DOC.TYP_KEY
       and JCA.ACJ_JOB_TYPE_ID = TYP.ACJ_JOB_TYPE_ID
       and JCA.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID;

    if (lv_financial_link in('8', '9') ) then
      lv_financial_link  := '3';
    end if;

    insert into ACI_DOCUMENT_STATUS
                (ACI_DOCUMENT_STATUS_ID
               , ACI_DOCUMENT_ID
               , C_ACI_FINANCIAL_LINK
                )
         values (aci_id_seq.nextval
               , in_aci_document_id
               , lv_financial_link
                );
  end;

/**
 * Exécution d'une pl pour PC_ACI_XML_IMPORT
 */
  function p_execute_proc_indiv(iv_proc in varchar2, in_axi_xml_import_id in number, io_error out nocopy varchar2)
    return boolean
  is
    ln_result number;
  begin
    execute immediate 'BEGIN' || chr(10) || ':1 := ' || iv_proc || '(:2, :3);' || chr(10) || 'END;'
                using out ln_result,   -- :1
                                    in in_axi_xml_import_id,   -- :2
                                                            out io_error;   -- :3

    return case
      when(ln_result = 1) then true
      else false
    end;
  exception
    when others then
      io_error  := 'Error on executing ' || iv_proc || ' - ' || sqlerrm || chr(10) || DBMS_UTILITY.format_error_stack;
      return false;
  end;

  function execute_proc_before_import(in_aci_xml_import_id in number)
    return boolean
  is
    lv_proc   varchar2(64);
    lv_error  varchar2(32767);
    lb_result boolean         := true;
  begin
    lv_proc  := pcs.pc_config.GetConfig('ACI_XML_IMPORT_PROC_BEFORE_IMP');

    if (lv_proc is not null) then
      lb_result  := p_execute_proc_indiv(lv_proc, in_aci_xml_import_id, lv_error);
    end if;

    if (not lb_result) then
      pcs.pc_mgt_aci_xml_import.update_import_status(in_aci_xml_import_id, pcs.pc_mgt_aci_xml_import.STATUS_IMPORT_ERROR, lv_error);
    end if;

    return lb_result;
  end;

  procedure execute_proc_after_import(in_aci_xml_import_id in number)
  is
    lv_proc   varchar2(64);
    lv_error  varchar2(32767);
    lb_result boolean         := true;
  begin
    lv_proc  := pcs.pc_config.GetConfig('ACI_XML_IMPORT_PROC_AFTER_IMP');

    if (lv_proc is not null) then
      lb_result  := p_execute_proc_indiv(lv_proc, in_aci_xml_import_id, lv_error);
    end if;

    if (not lb_result) then
      pcs.pc_mgt_aci_xml_import.update_import_status(in_aci_xml_import_id, pcs.pc_mgt_aci_xml_import.STATUS_AFTER_IMPORT_ERROR, lv_error);
    end if;
  end;

  function execute_import(in_aci_xml_import_id in number)
    return boolean
  is
    ln_aci_document_id aci_document_status.aci_document_status_id%type;
  begin
    ln_aci_document_id  := aci_xml_doc_integrate.importxml_aci_document(aci_lib_xml_import.get_aci_xml(in_aci_xml_import_id) );

    if (ln_aci_document_id is not null) then
      pcs.pc_mgt_aci_xml_import.update_aci_document_id(in_aci_xml_import_id, ln_aci_document_id);
      p_insert_aci_document_status(ln_aci_document_id);
      pcs.pc_mgt_aci_xml_import.update_import_status(in_aci_xml_import_id, pcs.pc_mgt_aci_xml_import.STATUS_IMPORT_DONE);
      return true;
    else
      pcs.pc_mgt_aci_xml_import.update_import_status(in_aci_xml_import_id, pcs.pc_mgt_aci_xml_import.STATUS_IMPORT_ERROR, 'Erreur d''intégration ACI-XML');
      return false;
    end if;
  exception
    when others then
      pcs.pc_mgt_aci_xml_import.update_import_status(in_aci_xml_import_id
                                                   , pcs.pc_mgt_aci_xml_import.STATUS_IMPORT_ERROR
                                                   , 'Error on importation - ' || sqlerrm || chr(10) || DBMS_UTILITY.format_error_stack
                                                    );
      return false;
  end;
end ACI_PRC_XML_IMPORT;
