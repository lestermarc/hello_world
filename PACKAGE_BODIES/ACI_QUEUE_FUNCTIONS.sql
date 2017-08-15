--------------------------------------------------------
--  DDL for Package Body ACI_QUEUE_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACI_QUEUE_FUNCTIONS" 
IS

  gt_reference_props rep_que_fct.T_REFERENCE_PROPERTIES;

  /**
  * function ExportAciDocument
  * Description
  *   Méthode pour exporter un ACI_DOCUMENT dans une autre société
  */
  function ExportAciDocument(aDocID in ACI_DOCUMENT.ACI_DOCUMENT_ID%type)
    return boolean
  is
    vXML        xmltype;
    vExport     integer                          default 0;
    vExported   boolean;
    vFailReason varchar2(3)                      default null;
    vComNameAct ACI_DOCUMENT.COM_NAME_ACT%type;
    vComNameDoc ACI_DOCUMENT.COM_NAME_DOC%type;
    vResult     boolean                          default true;
  begin
    begin
      -- Vérifier si la société source est differente de la société cible pour effectuer le transfert du document
      select COM_NAME_ACT
           , nvl(COM_NAME_DOC, PCS.PC_I_LIB_SESSION.GetComName)
        into vComNameAct
           , vComNameDoc
        from ACI_DOCUMENT
       where ACI_DOCUMENT_ID = aDocID;

      if     vComNameDoc is not null
         and vComNameAct is not null
         and vComNameDoc <> vComNameAct then
        vExport  := 1;
      else
        vExport  := 0;
      end if;
    exception
      when no_data_found then
        vExport      := 0;
        -- Code d'erreur 081 : Exportation xml, document non trouvé
        vFailReason  := '081';
    end;

    -- Effectuer l'envoi du document dans une autre société
    if vExport = 1 then
      -- Récuperer l'xml contenant notre document ACI_DOCUMENT
      vXML  := ACI_XML_FUNCTIONS.GenXml_ACI_DOCUMENT(aDocID);

      if vXML is not null then
        -- sauvegarde de l'xml dans la table du document ACI même
        update ACI_DOCUMENT
           set DOC_XML_DOC_DATE = sysdate
             , DOC_XML_DOCUMENT = vXML.GetClobVal()
         where ACI_DOCUMENT_ID = aDocID;

        -- Envoi de l'xml du document dans la queue correspondante
        vExported  := SendAciDocToQueue(vXML);

        -- Document exporté, màj du statut et de la date d'intégration
        if vExported then
          -- màj du statut
          update ACI_DOCUMENT_STATUS
             set C_ACI_FINANCIAL_LINK = '9'
           where ACI_DOCUMENT_ID = aDocID;

          -- màj de la date d'intégration
          update ACI_DOCUMENT
             set DOC_INTEGRATION_DATE = sysdate
               , C_INTERFACE_CONTROL = '1'
           where ACI_DOCUMENT_ID = aDocID;
        else
          -- L'envoi dans la queue n'a pas fonctionné
          -- Code d'erreur 083 : Erreur lors de l'exportation dans la queue de l'xml
          vFailReason  := '083';
        end if;
      else
        -- Code d'erreur 082 : Erreur lors de la création de l'xml
        vFailReason  := '082';
      end if;
    end if;

    -- Màj de l'ACI_DOCUMENT avec le code d'erreur
    if vFailReason is not null then
      vResult  := false;

      update ACI_DOCUMENT
         set C_FAIL_REASON = vFailReason
           , C_INTERFACE_CONTROL = '2'
       where ACI_DOCUMENT_ID = aDocID;
    end if;

    return vResult;
  end ExportAciDocument;

  /**
  * function SendAciDocToQueue
  * Description
  *   Envoi dans la queue oracle correspondante d'un xml contenant un ACI_DOCUMENT à exporter vers une autre société
  */
  function SendAciDocToQueue(aXml in XMLType)
    return boolean
  is
    lv_doc_number VARCHAR2(50);
    lv_queue_type VARCHAR2(10);
    lt_queuing_system pcs.pc_mgt_queue_sys.QUEUING_SYSTEM := pcs.pc_mgt_queue_sys.NONE_QUEUING;
  begin
    select 'ACI '||ExtractValue(aXml, gt_reference_props.xpath)
    into lv_doc_number
    from DUAL;

    if (gt_reference_props.queue_type is not null) then
      lt_queuing_system := pcs.pc_mgt_queue_sys.queuing(gt_reference_props.queue_type);
    else
      pcs.pc_mgt_queue_sys.resolve_reference(gt_reference_props.object_name, lv_queue_type, lt_queuing_system);
      gt_reference_props.queue_type := lv_queue_type;
    end if;
    case lt_queuing_system
      when pcs.pc_mgt_queue_sys.SOLVA_QUEUING then
        rep_que_fct.enqueue(gt_reference_props.queue_type, lv_doc_number, aXml);
        return TRUE;
      when pcs.pc_mgt_queue_sys.ADVANCED_QUEUING then
        rep_que_fct.use_enqueue(rep_que_fct.get_queue_name(gt_reference_props.object_name), lv_doc_number, aXml);
        return TRUE;
      else
        return FALSE;
    end case;

    exception
      when OTHERS then
        return false;
  end SendAciDocToQueue;


  procedure p_GetAciDocuments_SQ
  is
    lcv_QUEUE_TYPE CONSTANT VARCHAR(3) := 'ACI';
    lvCurrentSchema VARCHAR(32);
    lx_document XMLType;
    ln_released INTEGER;
    ln_document_id aci_document.aci_document_id%TYPE;
    ln_message_id pcs.pc_queue_message.pc_queue_message_id%TYPE;
    lt_ErrMsg CLOB;
  begin
    lvCurrentSchema := com_CurrentSchema;
    loop
      -- Prendre l'information dans la queue
      lx_document := rep_que_fct.dequeue_xml(lvCurrentSchema, lcv_QUEUE_TYPE, ln_message_id);
      exit when ln_message_id is null;

      -- Traiter le document xml réceptionné
      ln_document_id := aci_queue_functions.ReceiptAciDocument(lx_document, 1, lcv_QUEUE_TYPE, lt_ErrMsg);

      -- Retirer le document xml de la queue
      ln_released := rep_que_fct.release(lvCurrentSchema, lcv_QUEUE_TYPE, ln_message_id);
      commit;
      exit when lx_document is null;
    end loop;
  end;

  procedure p_GetAciDocuments_AQ
  is
    TYPE t_queue IS RECORD(
      consumer_name VARCHAR2(32),
      queue_name VARCHAR2(32)
    );
    TYPE tt_queues IS TABLE OF t_queue;
    ltt_queues tt_queues;
    lvCurrentSchema VARCHAR(32);
    lx_document XMLType;
    ln_released INTEGER;
    ln_document_id aci_document.aci_document_id%TYPE;
    lv_msgid RAW(16);
    lt_ErrMsg CLOB;
  begin
    -- utilisation d'une variable, car on a parfois des erreurs lorsque l'on
    -- utilise directement cette fonction COM_CURRENTSCHEMA dans une cmd sql
    lvCurrentSchema := Upper(com_CurrentSchema);

    -- Rechercher le nom de la queue oracle qui a comme référence ACI_DOCUMENT pour le schèma courant
    -- Utilisation d'un select... bulk collect into au lieu d'un curseur, car il peut y avoir
    -- plusieurs consomateurs pour une queue donnée et avec le curseur
    -- on peut de temps en temps obtenir l'erreur suivante :
    --  ORA-25228: timeout or end-of-fetch during message dequeue from PCS_Q.TEST_ACI_Q
    EXECUTE IMMEDIATE
      'select CONSUMER_NAME, ''PCS_Q.'' || QUEUE as QUEUE_NAME' ||
      ' from PCS_Q.AQ$ACI_QT' ||
      ' where MSG_STATE = ''READY'' and' ||
        ' Substr(Upper(QUEUE), 1, Instr(Upper(QUEUE), ''_ACI_Q'') - 1) = '''|| lvCurrentSchema ||''''||
      ' group by QUEUE, CONSUMER_NAME'
      BULK COLLECT INTO ltt_queues;

    if (ltt_queues is null or ltt_queues.COUNT = 0) then
      -- Sortie anticipée car aucune queue ne correspondant au critère
      return;
    end if;

    for cpt in ltt_queues.FIRST..ltt_queues.LAST loop
      if (ltt_queues(cpt).QUEUE_NAME is not null) and
         (ltt_queues(cpt).CONSUMER_NAME is not null) then
        loop
          -- Prendre l'information dans la queue
          lx_document := rep_que_fct.use_dequeue_xml(ltt_queues(cpt).CONSUMER_NAME, ltt_queues(cpt).QUEUE_NAME, lv_msgid);
          exit when lv_msgid is null;

          -- Traiter le document xml réceptionné
          ln_document_id := aci_queue_functions.ReceiptAciDocument(lx_document, 1, ltt_queues(cpt).QUEUE_NAME, lt_ErrMsg);

          -- Retirer le document xml de la queue
          ln_released := rep_que_fct.release(ltt_queues(cpt).CONSUMER_NAME, ltt_queues(cpt).QUEUE_NAME, lv_msgid);
          commit;
        end loop;
      end if;
    end loop;
  end;
  /**
  * procedure GetAciDocuments
  * Description
  *   Méthode pour récuper un xml contenant un ACI_DOCUMENT de la queue oracle
  */
  procedure GetAciDocuments
  is
  begin
    case pcs.pc_mgt_queue_sys.queuing('ACI')
      when pcs.pc_mgt_queue_sys.SOLVA_QUEUING then
        p_GetAciDocuments_SQ;
      when pcs.pc_mgt_queue_sys.ADVANCED_QUEUING then
        p_GetAciDocuments_AQ;
      else null;
    end case;

    exception
      when others then
        rollback;
        raise_application_error(-20000, 'ACI_QUEUE_FUNCTIONS.GetAciDocument catastrophic failure' || Chr(10) || sqlerrm);
  end;

  /**
  * function ReceiptAciDocument
  * Description
  *   Réception de l'xml et intégration des données (ACI_DOCUMENT) de celui-ci
  */
  function ReceiptAciDocument(aXML in xmltype, aLogErrors in integer, aQueueName in varchar2, aErrMsg out clob)
    return number
  is
    vScrDbOwner    varchar2(30)                                    default null;
    vDocumentID    ACI_DOCUMENT.ACI_DOCUMENT_ID%type               default null;
    vSavePoint     varchar2(2000)                                  := 'IMP_ACI_XML-' || to_char(sysdate, 'HH24MISS');
    vFinancialLink ACI_DOCUMENT_STATUS.C_ACI_FINANCIAL_LINK%type;
    vCompanyName   PCS.PC_COMP.COM_NAME%type                       default null;
  begin
    -- Recherche la société
    select extractvalue(aXML, '/ACI_DOCUMENT/COM_NAME_ACT')
      into vCompanyName
      from dual;

    if vCompanyName is null then
      aErrMsg       := 'PCS : COM_NAME_ACT is null';
      vDocumentID   := 0;
      vCompanyName  := null;
    else
      begin
        -- Vérifier si l'xml réceptionné concerne cette société
        select SCR.SCRDBOWNER
          into vScrDbOwner
          from PCS.PC_COMP COM
             , PCS.PC_SCRIP SCR
         where COM.COM_NAME = vCompanyName
           and COM.PC_SCRIP_ID = SCR.PC_SCRIP_ID;
      exception
        when no_data_found then
          aErrMsg      := null;
          vDocumentID  := null;
          vScrDbOwner  := null;
      end;

      -- Traitement de l'xml s'il concerne le schema courant
      --if vScrDbOwner = sys_context('USERENV', 'CURRENT_SCHEMA') then
      if vScrDbOwner = COM_CURRENTSCHEMA then
        -- Si on n'arrive pas à inserer les données dans toutes les tables
        -- il faut effacer toutes les insertions de ImportXml_ACI_DOCUMENT
        savepoint vSavePoint;

        -- Importation des données de l'xml
        begin
          vDocumentID  := nvl(ACI_XML_DOC_INTEGRATE.ImportXml_ACI_DOCUMENT(aXML), 0);
        exception
          when others then
            vDocumentID  := 0;
            aErrMsg      := sqlerrm;
            -- Si on n'arrive pas à inserer les données dans toutes les tables
            -- il faut effacer toutes les insertions de ImportXml_ACI_DOCUMENT
            rollback to savepoint vSavePoint;
        end;

        -- Si on n'a pas réussi à créer le document dans ACI_DOCUMENT
        -- Alors on envoi l'xml dans une table des erreurs d'importation
        if vDocumentID > 0 then
          -- Status entête interface finance
          select nvl(min(TYP.C_ACI_FINANCIAL_LINK), '3')
            into vFinancialLink
            from ACJ_JOB_TYPE_S_CATALOGUE JCA
               , ACJ_JOB_TYPE TYP
               , ACJ_CATALOGUE_DOCUMENT CAT
               , ACI_DOCUMENT DOC
           where DOC.ACI_DOCUMENT_ID = vDocumentID
             and CAT.CAT_KEY = DOC.CAT_KEY
             and TYP.TYP_KEY = DOC.TYP_KEY
             and JCA.ACJ_JOB_TYPE_ID = TYP.ACJ_JOB_TYPE_ID
             and JCA.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID;

          if vFinancialLink in('8', '9') then
            vFinancialLink  := '3';
          end if;

          insert into ACI_DOCUMENT_STATUS
                      (ACI_DOCUMENT_STATUS_ID
                     , ACI_DOCUMENT_ID
                     , C_ACI_FINANCIAL_LINK
                      )
            select ACI_ID_SEQ.nextval
                 , vDocumentID
                 , vFinancialLink
              from dual;
        end if;
      end if;
    end if;

    -- Si document = 0 cela veut dire qu'il y a eu une erreur et qu'il faut
    -- créer une entrée dans la table des erreurs d'import
    if     (aLogErrors = 1)
       and (vDocumentID = 0) then
      insert into ACI_IMPORT_ERROR
                  (ACI_IMPORT_ERROR_ID
                 , ACI_XML
                 , ACI_QUEUE
                 , ACI_ERR_MESSAGE
                 , ACI_CREATION_DATE
                 , C_ERROR_TYPE
                  )
        select INIT_ID_SEQ.nextval
             , aXML.GetClobVal()
             , aQueueName
             , aErrMsg
             , sysdate
             , '01'
          from dual;
    end if;

    return vDocumentID;
  end ReceiptAciDocument;

  /**
  * function ReceiptAciDocument
  * Description
  *   Réception de l'xml et intégration des données (ACI_DOCUMENT) de celui-ci
  *   en se basant sur un xml figuratn dans la table ACI_IMPORT_ERROR
  *   Cette méthode a été développée pour l'objet REP_REPL_ERROR_MGR_ACI
  */
  function ReceiptAciDocument(aXML in clob, aErrMsg out clob)
    return number
  is
    vDocumentID ACI_DOCUMENT.ACI_DOCUMENT_ID%type;
    vXML        xmltype;
  begin
    vXML         := xmltype.CreateXML(aXML);
    -- le nvl(..,1) c'est parce que cette méthode est appelée par l'objet REP_REPL_ERROR_MGR_ACI
    -- et que cet objet considère comme erreur l'id à null
    -- hors dans le cas présent, si l'id est null cela veut dire que le document n'était pas destiné a cette société
    vDocumentID  := nvl(ReceiptAciDocument(vXML, 0, null, aErrMsg), 1);
    commit;
    return vDocumentID;
  end ReceiptAciDocument;

BEGIN
  gt_reference_props.object_name := 'ACI_DOCUMENT';
  gt_reference_props.xpath := '/ACI_DOCUMENT/COM_NAME_ACT';
END ACI_QUEUE_FUNCTIONS;
