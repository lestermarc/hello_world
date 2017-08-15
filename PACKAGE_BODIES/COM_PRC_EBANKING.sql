--------------------------------------------------------
--  DDL for Package Body COM_PRC_EBANKING
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_PRC_EBANKING" 
/**
 * Package de gestion pour e-banking.
 *
 * @version 1.0
 * @date 2004
 * @author mbartolacci
 * @author ngomes
 * @author dsaadé
 * @author skalayci
 * @author spfister
 * @author agentet
 *
 * Copyright 1997-2011 SolvAxis SA. Tous droits réservés.
 */
as
  function CanSend(in_ebanking_id in com_ebanking.com_ebanking_id%type)
    return boolean
  is
    lv_error         varchar2(32767);
    lv_status        varchar2(32767);
    ln_actDocumentId com_ebanking.act_document_id%type;
  begin
    select B.C_CEB_EBANKING_STATUS
         , case E.C_ECS_VALIDATION
             when '01' then case
                             when B.ACI_DOCUMENT_ID is null then '400'
                           end
             when '02' then case
                             when B.ACT_DOCUMENT_ID is null then '401'
                           end
           end
         , B.ACT_DOCUMENT_ID
      into lv_status
         , lv_error
         , ln_actDocumentId
      from PCS.PC_EXCHANGE_SYSTEM E
         , COM_EBANKING B
     where B.COM_EBANKING_ID = in_ebanking_id
       and B.C_CEB_EBANKING_STATUS = '003'
       and E.PC_EXCHANGE_SYSTEM_ID = B.PC_EXCHANGE_SYSTEM_ID;

    if (lv_error is not null) then
      com_prc_ebanking_det.InsertEBPPDetail(in_ebanking_id, lv_status, lv_error);
      return false;
    elsif com_lib_ebanking.isDocumentMatched(ln_actDocumentId) then
      com_prc_ebanking_det.InsertEBPPDetail(in_ebanking_id, lv_status, '306');
    end if;

    return true;
  exception
    when no_data_found then
      return false;
  end;

  function p_LoadComEbanking(in_ebanking_id in com_ebanking.com_ebanking_id%type)
    return com_ebanking%rowtype
  is
    tplEBanking com_ebanking%rowtype;
  begin
    select ceb.*
      into tplEBanking
      from com_ebanking ceb
     where ceb.com_ebanking_id = in_ebanking_id;

    return tplEBanking;
  exception
    when no_data_found then
      return null;
  end;

  procedure control_data(iv_RowId in varchar2)
  is
    ln_ebanking_id com_ebanking.com_ebanking_id%type;
  begin
    select COM_EBANKING_ID
      into ln_ebanking_id
      from COM_EBANKING
     where rowid = iv_RowId;

    com_prc_ebanking.control_data(ln_ebanking_id);
  end;

  procedure control_data(in_ebanking_id in com_ebanking.com_ebanking_id%type)
  is
    tplEBanking        com_ebanking%rowtype;
    lb_next            boolean                := true;
    ln_BSP_compatible  number(1);
    lv_billPresentment varchar2(10);
  begin
    tplEbanking  := p_LoadComEbanking(in_ebanking_id);

    if (    tplEbanking.COM_EBANKING_ID is not null
        and tplEbanking.C_CEB_EBANKING_STATUS in('000', '001') ) then
      -- (1) référence EBPP active ?
      if (tplEbanking.PAC_EBPP_REFERENCE_ID is null) then
        if (tplEbanking.C_CEB_DOCUMENT_ORIGIN = '03') then
          aci_isag.aci_ebpp_one_doc(tplEbanking.ACT_DOCUMENT_ID, tplEbanking.ACI_DOCUMENT_ID, tplEbanking.COM_EBANKING_ID, 'CTRL');
          tplEbanking  := p_LoadComEbanking(in_ebanking_id);
          lb_next      := tplEbanking.PAC_EBPP_REFERENCE_ID is not null;
        else
          lb_next  := false;
          com_prc_ebanking_det.InsertEBPPDetail(in_ebanking_id       => tplEbanking.COM_EBANKING_ID
                                              , iv_ebanking_status   => '000'
                                              , iv_ebanking_error    => '307'
                                              , iv_comment           => 'Contrôler les données de la fiche client'
                                               );
        end if;
      elsif(com_lib_ebanking.isEbppReferenceActive(tplEbanking.PAC_EBPP_REFERENCE_ID) ) then
        lb_next  := true;
      else
        com_prc_ebanking_det.InsertEBPPDetail(in_ebanking_id       => tplEbanking.COM_EBANKING_ID
                                            , iv_ebanking_status   => '000'
                                            , iv_ebanking_error    => '305'
                                            , iv_comment           => 'Contrôler les données de la fiche client'
                                             );
        lb_next  := false;
      end if;

      if (lb_next) then
        -- (2) système d'échange de données actif ?
        if (tplEbanking.PC_EXCHANGE_SYSTEM_ID is null) then
          if (tplEbanking.C_CEB_DOCUMENT_ORIGIN = '03') then
            aci_isag.aci_ebpp_one_doc(tplEbanking.ACT_DOCUMENT_ID, tplEbanking.ACI_DOCUMENT_ID, tplEbanking.COM_EBANKING_ID, 'CTRL');
            tplEbanking  := p_LoadComEbanking(in_ebanking_id);
            lb_next      := tplEbanking.PC_EXCHANGE_SYSTEM_ID is not null;
          else
            lb_next  := false;
            com_prc_ebanking_det.InsertEBPPDetail(in_ebanking_id       => tplEbanking.COM_EBANKING_ID
                                                , iv_ebanking_status   => '000'
                                                , iv_ebanking_error    => '308'
                                                , iv_comment           => 'Contrôler les données de la fiche client'
                                                 );
          end if;
        elsif(com_lib_ebanking.isExchangeSystemActive(tplEbanking.PC_EXCHANGE_SYSTEM_ID) ) then
          lb_next  := true;
        else
          lb_next  := false;
          com_prc_ebanking_det.InsertEBPPDetail(in_ebanking_id       => tplEbanking.COM_EBANKING_ID
                                              , iv_ebanking_status   => '000'
                                              , iv_ebanking_error    => '304'
                                              , iv_comment           => 'Contrôler les données de la fiche client'
                                               );
        end if;
      end if;

      if (lb_next) then
        -- (3) référence ebpp et système d'échange de données sont-ils liés au même prestataire ?
        select count(CEB.COM_EBANKING_ID)
          into ln_BSP_compatible
          from COM_EBANKING CEB
             , PAC_EBPP_REFERENCE EBP
             , PCS.PC_EXCHANGE_SYSTEM ECS
         where CEB.COM_EBANKING_ID = tplEbanking.COM_EBANKING_ID
           and CEB.PAC_EBPP_REFERENCE_ID = EBP.PAC_EBPP_REFERENCE_ID
           and CEB.PC_EXCHANGE_SYSTEM_ID = ECS.PC_EXCHANGE_SYSTEM_ID
           and ECS.C_ECS_BSP = EBP.C_EBPP_BSP;

        lb_next  := true;

        if (ln_BSP_compatible = 0) then
          com_prc_ebanking_det.InsertEBPPDetail(in_ebanking_id => tplEbanking.COM_EBANKING_ID, iv_ebanking_status => '000', iv_ebanking_error => '309');
          lb_next  := false;
        end if;
      end if;

      if (lb_next) then
        -- (4) le fichier PDF est-il nécessaire et présent ?
        --     PDF nécessaire dans le cas "mode de présentation = 01 = Avec Bill presentment, PDF intégré dans le XML
        select ecs.c_ecs_bill_presentment
          into lv_billPresentment
          from PCS.PC_EXCHANGE_SYSTEM ECS
         where ECS.PC_EXCHANGE_SYSTEM_ID = tplEbanking.pc_exchange_system_id;

        if     ((tplEbanking.CEB_PDF_FILE is null) or (DBMS_LOB.getLength(tplEbanking.CEB_PDF_FILE) = 0))
           and (lv_billPresentment = '01') then
          lb_next  := false;
          com_prc_ebanking_det.InsertEBPPDetail(in_ebanking_id => tplEbanking.COM_EBANKING_ID, iv_ebanking_status => '000', iv_ebanking_error => '200');
        end if;
      end if;

      if (lb_next) then
        -- tous les contrôles sont OK
        com_prc_ebanking_det.InsertEBPPDetail(in_ebanking_id => tplEbanking.COM_EBANKING_ID, iv_ebanking_status => '002');
      end if;
    end if;
  end control_data;

  procedure GenerateXmlDocument(in_ebanking_id in com_ebanking.com_ebanking_id%type, ot_xml out nocopy clob)
  is
    ln_document_id number;
    lv_origine     com_ebanking.c_ceb_document_origin%type;
    lv_provider    pcs.pc_exchange_system.c_ecs_bsp%type;
    lv_version     pcs.pc_exchange_system.c_ecs_version%type;
  begin
    begin
      select CEB.C_CEB_DOCUMENT_ORIGIN
           , case CEB.C_CEB_DOCUMENT_ORIGIN
               when '01' then CEB.DOC_DOCUMENT_ID   -- Logistique ERP
               when '02' then CEB.ACT_DOCUMENT_ID   -- Finance interne
               when '03' then CEB.ACT_DOCUMENT_ID   -- Finance externe
             end DOCUMENT_ID
           , ECS.C_ECS_BSP
           , ECS.C_ECS_VERSION
        into lv_origine
           , ln_document_id
           , lv_provider
           , lv_version
        from COM_EBANKING CEB
           , PCS.PC_EXCHANGE_SYSTEM ECS
       where CEB.COM_EBANKING_ID = in_ebanking_id
         and CEB.C_CEB_EBANKING_STATUS = '003'
         and ECS.PC_EXCHANGE_SYSTEM_ID = CEB.PC_EXCHANGE_SYSTEM_ID;
    exception
      when no_data_found then
        return;
    end;

    case lv_provider
      when '00' then
        -- YellowBill
        if (lv_version = '001') then
          case lv_origine
            when '01' then   -- Logistique ERP
              doc_xml_functions.GenDocXmlExchSystem(ln_document_id, ot_xml);
            when '02' then   -- Finance interne
              ot_xml  := com_lib_ebanking_act_yb.GetYB12_Int_xml(ln_document_id);
            when '03' then   -- Finance externe
              ot_xml  := com_lib_ebanking_act_yb.GetYB12_Ext_xml(ln_document_id);
            else
              raise_application_error(-20000, '"' || lv_origine || '" is not a supported origine document type');
          end case;
        else
          raise_application_error(-20000, '"' || lv_version || '" is not a supported YellowBill version');
        end if;
      when '01' then
        -- PayNet
        case lv_origine
          when '01' then   -- Logistique ERP
            doc_xml_functions.GenDocXmlExchSystem(ln_document_id, ot_xml);
          when '02' then   -- Finance interne
            ot_xml  := com_lib_ebanking_act_pn.GetPN2003A_Int_xml(ln_document_id);
          when '03' then   -- Finance externe
            ot_xml  := com_lib_ebanking_act_pn.GetPN2003A_Ext_xml(ln_document_id);
          else
            raise_application_error(-20000, '"' || lv_origine || '" is not a supported origine document type');
        end case;
      else
        raise_application_error(-20000, '"' || lv_provider || '" is not a valid provider');
    end case;
  end;

  procedure StorePDFDocInEBPP(in_document_id in doc_document.doc_document_id%type)
  is
    lv_repname     pcs.pc_report.rep_repname%type;
    lv_dmt_number  doc_document.dmt_number%type;
    ln_ebanking_id com_ebanking.com_ebanking_id%type;
    lv_printServer pcs.pc_exchange_system.ecs_key%type;
  begin
    -- PrintServer / sélection de la queue d'impression / règle de gestion
    -- 1. queue d'impression de type PRINT99 (type de queue SolvaQueuing dédié au PDF pour e-facture)
    -- 2. queue d'impression de type PRTSRV (valeur par défaut si aucune queue PRINT99 n'existe)
    begin
      select ecs.ecs_key
        into lv_printServer
        from pcs.pc_exchange_system ecs
       where ecs.pc_comp_id = pcs.PC_I_LIB_SESSION.getcompanyid
         and ecs.c_queue_type = 'PRINT99';
    exception
      when no_data_found then
        lv_printServer  := null;
    end;

    select REP.REP_REPNAME
         , DMT.DMT_NUMBER
         , CEB.COM_EBANKING_ID
      into lv_repname
         , lv_dmt_number
         , ln_ebanking_id
      from PCS.PC_EXCHANGE_SYSTEM ECS
         , PCS.PC_REPORT REP
         , DOC_FILING_MODE DFM
         , DOC_DOCUMENT DMT
         , COM_EBANKING CEB
     where CEB.DOC_DOCUMENT_ID = in_document_id
       and DMT.DOC_DOCUMENT_ID = CEB.DOC_DOCUMENT_ID
       and DFM.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
       and ECS.PC_EXCHANGE_SYSTEM_ID = CEB.PC_EXCHANGE_SYSTEM_ID
       and DFM.C_ECS_BSP = ECS.C_ECS_BSP
       and REP.PC_REPORT_ID = DFM.PC_REPORT_ID;

    com_report_functions.SendReportToPrintQueue(aReport                  => lv_repname
                                              , aOutputMode              => 'STORE_IN_DB'
                                              , aConfigContext           => 'DOC'
                                              , aExportFormat            => 'PDF'
                                              , aClause                  => 'PARAMETER_0=' || lv_dmt_number
                                              , aStoreTable              => 'COM_EBANKING'
                                              , aStoreField              => 'CEB_PDF_FILE'
                                              , aStoreFieldType          => 'BLOB'
                                              , aStoreKeyField           => 'COM_EBANKING_ID'
                                              , aStoreKeyValue           => to_char(ln_ebanking_id)
                                              , aStoreKeyFieldType       => 'NUMBER'
                                              , aProcToCall              => 'com_prc_ebanking.control_data'
                                              , iv_exchange_system_key   => lv_printServer
                                               );
  exception
    when no_data_found then
      null;
  end StorePDFDocInEBPP;

  procedure updateEBANKING(in_KEY_EBANKING_ID in com_ebanking.com_ebanking_id%type, iv_CEB_EBANKING_RECEIPT in com_ebanking.c_ceb_ebanking_receipt%type)
  is
  begin
    update COM_EBANKING
       set C_CEB_EBANKING_RECEIPT = iv_CEB_EBANKING_RECEIPT
     where COM_EBANKING_ID = in_KEY_EBANKING_ID;
  end;

  /**
  * Description
  *    Cette fonction va mettre à jour le statut d'envoi du document e-facture
  *    dans la table COM_EBANKING.
  */
  procedure updateEFactureStatus(inComEbankingID in COM_EBANKING.COM_EBANKING_ID%type, ivCCebEbankingStatus in COM_EBANKING.C_CEB_EBANKING_STATUS%type)
  is
  begin
    update COM_EBANKING
       set C_CEB_EBANKING_STATUS = ivCCebEbankingStatus
     where COM_EBANKING_ID = inComEbankingID;
  end updateEFactureStatus;

  /**
  * Description
  *    Cette fonction recherche le document (logistique, comptable ou interface
  *    comptable) e-finance dans la table COM_EBANKING. Retourne 1 si le document
  *    est trouvé, sinon 0.
  */
  function docExists(inDocumentID in number)
    return number
  as
    lnExists number default 0;
  begin
    select count(*)
      into lnExists
      from dual
     where exists(select 1
                    from COM_EBANKING
                   where DOC_DOCUMENT_ID = inDocumentID)
        or exists(select 1
                    from COM_EBANKING
                   where ACI_DOCUMENT_ID = inDocumentID)
        or exists(select 1
                    from COM_EBANKING
                   where ACT_DOCUMENT_ID = inDocumentID);

    return lnExists;
  end;

  /**
  * Description
  *    Suppression d'un document e-facture.
  */
  procedure deleteEBanking(iEBankingId in COM_EBANKING.COM_EBANKING_ID%type)
  as
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_COM_ENTITY.gcComEbanking, ltCRUD_DEF, true, iEBankingId);
    FWK_I_MGT_ENTITY.DeleteEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end deleteEBanking;
end COM_PRC_EBANKING;
