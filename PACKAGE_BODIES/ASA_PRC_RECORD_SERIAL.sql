--------------------------------------------------------
--  DDL for Package Body ASA_PRC_RECORD_SERIAL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_PRC_RECORD_SERIAL" 
is
  /**
  * Procedure ClearGaugeList
  * Description
  *   Effacement de la liste des gabarits des documents à générer
  */
  procedure ClearGaugeList
  is
  begin
    delete from COM_LIST_ID_TEMP
          where LID_CODE = gcGaugeTmpCode;

    delete from COM_LIST_ID_TEMP
          where LID_CODE = gcFalJobProgramTmpCode;
  end ClearGaugeList;

  /**
  * procedure AddGaugeToList
  * Description
  *   Ajout d'un gabarit et de ses options à la liste des documents à générer
  *    lors du changement de statut du dossier SAV
  */
  procedure AddGaugeToList(
    iGaugeID          in DOC_GAUGE.DOC_GAUGE_ID%type
  , iGaugeType        in varchar2
  , iGenerateDocument in integer
  , iPriceType        in integer
  , iDateDocument     in date
  , iDateValue        in date
  , iDateDelivery     in date
  , iPrintDocument    in integer
  , iPrintOptions     in clob
  )
  is
    ltComListTmp FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListTmp, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_CODE', gcGaugeTmpCode);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_ID_1', iGaugeID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_CHAR_1', iGaugeType);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_SELECTION', iGenerateDocument);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_NUMBER_1', iPriceType);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_DATE_1', iDateDocument);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_DATE_2', iDateValue);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_DATE_3', iDateDelivery);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_NUMBER_2', iPrintDocument);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_CLOB', iPrintOptions);
    FWK_I_MGT_ENTITY.InsertEntity(ltComListTmp);
    FWK_I_MGT_ENTITY.Release(ltComListTmp);
  end AddGaugeToList;

  /**
  * procedure AddFalJobProgram
  * Description
  *   Ajout des infos pour la génération de l'OF
  *    lors du changement de statut du dossier SAV
  */
  procedure AddFalJobProgram(iGenerateOF in integer, iLaunchOF in integer, iPlanBeginDate in date, iFalJobProgramId in FAL_JOB_PROGRAM.FAL_JOB_PROGRAM_ID%type)
  is
    ltComListTmp FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListTmp, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_CODE', gcFalJobProgramTmpCode);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_SELECTION', iGenerateOF);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_NUMBER_1', iLaunchOF);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_DATE_1', iPlanBeginDate);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_ID_1', iFalJobProgramId);
    FWK_I_MGT_ENTITY.InsertEntity(ltComListTmp);
    FWK_I_MGT_ENTITY.Release(ltComListTmp);
  end AddFalJobProgram;

  /**
  * procedure CreateResultLog
  * Description
  *   Ajout d'une entrée dans la table temp indiquant le résultat du traitement
  *    lors du changement de statut du dossier SAV
  */
  procedure CreateResultLog(iAsaRecordID in ASA_RECORD.ASA_RECORD_ID%type, iSuccessfull in integer, iErrorMsg in varchar2)
  is
    ltComListTmp FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListTmp, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_CODE', gcResultTmpCode);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_ID_1', iAsaRecordID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_SELECTION', iSuccessfull);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_MEMO_1', iErrorMsg);
    FWK_I_MGT_ENTITY.InsertEntity(ltComListTmp);
    FWK_I_MGT_ENTITY.Release(ltComListTmp);
  end CreateResultLog;

  /**
  * procedure CreateDocumentLink
  * Description
  *   Ajout d'une entrée dans la table temp pour le lien entre les documents créés et leur dossier SAV
  */
  procedure CreateDocumentLink(iAsaRecordID in ASA_RECORD.ASA_RECORD_ID%type, iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    ltComListTmp FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListTmp, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_CODE', gcDocumentTmpCode);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_ID_1', iAsaRecordID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_ID_2', iDocumentID);
    FWK_I_MGT_ENTITY.InsertEntity(ltComListTmp);
    FWK_I_MGT_ENTITY.Release(ltComListTmp);
  end CreateDocumentLink;

  /**
  * procedure CreatePrintJobLog
  * Description
  *   Ajout d'une entrée dans la table temp pour le job d'impression créé
  */
  procedure CreatePrintJobLog(iPrintJobID in DOC_PRINT_JOB.DOC_PRINT_JOB_ID%type)
  is
    ltComListTmp FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListTmp, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_CODE', gcPrintJobTmpCode);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_ID_1', iPrintJobID);
    FWK_I_MGT_ENTITY.InsertEntity(ltComListTmp);
    FWK_I_MGT_ENTITY.Release(ltComListTmp);
  end CreatePrintJobLog;

  /**
  * procedure ClearLogs
  * Description
  *   Effacement des logs de traitement
  */
  procedure ClearLogs
  is
  begin
    delete from COM_LIST_ID_TEMP
          where LID_CODE = gcDocumentTmpCode;

    delete from COM_LIST_ID_TEMP
          where LID_CODE = gcPrintJobTmpCode;

    delete from COM_LIST_ID_TEMP
          where LID_CODE = gcResultTmpCode;
  end ClearLogs;

  /*
  * Description
  *   Recherche les infos gabarit pour le document à créer
  */
  procedure pGetGaugeInfo(
    iTypeGauge        in     varchar2
  , iPriceType        in     integer default 1
  , oGaugeID          out    DOC_GAUGE.DOC_GAUGE_ID%type
  , oGenerateDocument out    integer
  , oDateDocument     out    date
  , oDateValue        out    date
  , oDateDelivery     out    date
  , oPrintDocument    out    integer
  , oPrintOptions     out    clob
  )
  is
  begin
    select LID_ID_1
         , LID_SELECTION
         , LID_FREE_DATE_1
         , LID_FREE_DATE_2
         , LID_FREE_DATE_3
         , LID_FREE_NUMBER_2
         , LID_CLOB
      into oGaugeID
         , oGenerateDocument
         , oDateDocument
         , oDateValue
         , oDateDelivery
         , oPrintDocument
         , oPrintOptions
      from COM_LIST_ID_TEMP
     where LID_CODE = gcGaugeTmpCode
       and LID_FREE_CHAR_1 = iTypeGauge
       and nvl(LID_FREE_NUMBER_1, 1) = iPriceType;
  exception
    when no_data_found then
      oGaugeID  := null;
  end pGetGaugeInfo;

  /*
  * Description
  *   Génération d'un document
  */
  procedure pGenerateDocument(iAsaRecordId in ASA_RECORD.ASA_RECORD_ID%type, iTypeGauge in varchar2, iSelectPrice in varchar2 default null)
  is
    lGaugeID          DOC_GAUGE.DOC_GAUGE_ID%type;
    lGenerateDocument integer;
    lDateDocument     date;
    lDateValue        date;
    lDateDelivery     date;
    lPrintDocument    integer;
    lPrintOptions     clob;
    lvErrorMsg        varchar2(32000);
    lDocumentID       DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    -- Récuperer les infos du document à générer
    pGetGaugeInfo(iTypeGauge          => iTypeGauge
                , iPriceType          => to_char(nvl(iSelectPrice, 1) )
                , oGaugeID            => lGaugeID
                , oGenerateDocument   => lGenerateDocument
                , oDateDocument       => lDateDocument
                , oDateValue          => lDateValue
                , oDateDelivery       => lDateDelivery
                , oPrintDocument      => lPrintDocument
                , oPrintOptions       => lPrintOptions
                 );

    -- Si on est en mode de prix "2" - Et que la config correspondante n'est pas initialisée
    --  On recherche le gabarit avec le mode de prix "1"
    if     (lGaugeID is null)
       and (iSelectPrice = '2') then
      pGetGaugeInfo(iTypeGauge          => iTypeGauge
                  , iPriceType          => 1
                  , oGaugeID            => lGaugeID
                  , oGenerateDocument   => lGenerateDocument
                  , oDateDocument       => lDateDocument
                  , oDateValue          => lDateValue
                  , oDateDelivery       => lDateDelivery
                  , oPrintDocument      => lPrintDocument
                  , oPrintOptions       => lPrintOptions
                   );
    end if;

    if     (lGaugeID is not null)
       and (lGenerateDocument = 1) then
      -- Création du document
      ASA_RECORD_GENERATE_DOC.GenerateDocuments(aASA_RECORD_ID       => iAsaRecordId
                                              , aTypeGauge           => iTypeGauge
                                              , aDOC_GAUGE_ID        => lGaugeID
                                              , aDMT_DATE_DOCUMENT   => lDateDocument
                                              , aDMT_DATE_VALUE      => lDateValue
                                              , aDMT_DATE_DELIVERY   => lDateDelivery
                                              , aAutoNum             => 0
                                              , aGroupedByThird      => 0
                                              , aError               => lvErrorMsg
                                               );

      -- Rechercher l'id du document généré
      select max(COM_LIST_ID_TEMP_ID)
        into lDocumentID
        from COM_LIST_ID_TEMP
       where LID_CODE = 'DOC_DOCUMENT_ID';

      -- Création d'un lien entre le dossier SAV et le document créé
      if lDocumentID is not null then
        CreateDocumentLink(iAsaRecordID => iAsaRecordId, iDocumentID => lDocumentID);
      end if;

      --
      if lvErrorMsg is not null then
        FWK_I_MGT_EXCEPTION.raise_exception(in_error_code    => -20800
                                          , iv_message       => lvErrorMsg
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'GenerateDoc'
                                           );
      end if;
    end if;
  end pGenerateDocument;

  /*
  * Description
  *   Génération des documents
  */
  procedure GenerateDocuments(
    iAsaRecordId       in ASA_RECORD.ASA_RECORD_ID%type
  , iAsaRecordEventsId in ASA_RECORD_EVENTS.ASA_RECORD_EVENTS_ID%type
  , iStatus            in ASA_RECORD.C_ASA_REP_STATUS%type
  )
  is
    -- Données du dossier SAV
    lArePriceDevisMB   ASA_RECORD.ARE_PRICE_DEVIS_MB%type;
    lCAsaRepTypeKind   ASA_RECORD.C_ASA_REP_TYPE_KIND%type;
    lAreGenerateBill   ASA_RECORD.ARE_GENERATE_BILL%type;
    lAreLposCompTask   ASA_RECORD.ARE_LPOS_COMP_TASK%type;
    lSelectPrice       ASA_RECORD.C_ASA_SELECT_PRICE%type;
    lDocumentID        DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    -- Donnée de l'évenement
    lAsaRecordEventsId ASA_RECORD_EVENTS.ASA_RECORD_EVENTS_ID%type;
    lnCountConfig      number;
    -- gtyOffer     -> offre client
    lbGtyOffer         boolean;
    -- gtyOfferBill -> Facture relative au frais d'établissement du devis
    lbGtyOfferBill     boolean;
    -- gtyCmdC      -> Commande Client
    lbGtyCmdC          boolean;
    -- gtyCmdS      -> Commande Fournisseur
    lbGtyCmdS          boolean;
    -- gtyBill      -> Facture Client
    lbGtyBill          boolean;
    -- gtyNC        -> Notes de crédit
    lbGtyNC            boolean;
    -- gtyBuLiv     -> Bulletin de livraison
    lbGtyBuLiv         boolean;
    -- gtyAttrib    -> document attribution
    lbGtyAttrib        boolean;
  begin
    -- Récupération des données du dossier SAV
    begin
      select ARE_PRICE_DEVIS_MB
           , C_ASA_REP_TYPE_KIND
           , ARE_GENERATE_BILL
           , ARE_LPOS_COMP_TASK
           , C_ASA_SELECT_PRICE
        into lArePriceDevisMB
           , lCAsaRepTypeKind
           , lAreGenerateBill
           , lAreLposCompTask
           , lSelectPrice
        from ASA_RECORD
       where ASA_RECORD_ID = iAsaRecordId;
    exception
      when no_data_found then
        lArePriceDevisMB  := null;
        lCAsaRepTypeKind  := null;
        lAreGenerateBill  := null;
        lAreLposCompTask  := null;
        lSelectPrice      := null;
    end;

    -- Définir en fonction d'une config le traitement
    lbGtyOffer      := ASA_I_LIB_RECORD.isStatusInConfigOrDefault(iStatus, 'ASA_DEFAULT_OFFER_GAUGE_NAME');
    lbGtyOfferBill  := ASA_I_LIB_RECORD.isStatusInConfigOrDefault(iStatus, 'ASA_DEFAULT_OFFER_BILL_GAUGE');
    lbGtyCmdC       := ASA_I_LIB_RECORD.isStatusInConfigOrDefault(iStatus, 'ASA_DEFAULT_CMDC_GAUGE_NAME');
    lbGtyCmdS       := ASA_I_LIB_RECORD.isStatusInConfigOrDefault(iStatus, 'ASA_DEFAULT_CMDS_GAUGE_NAME');
    lbGtyBill       := ASA_I_LIB_RECORD.isStatusInConfigOrDefault(iStatus, 'ASA_DEFAULT_BILL_GAUGE_NAME');
    lbGtyNC         := ASA_I_LIB_RECORD.isStatusInConfigOrDefault(iStatus, 'ASA_DEFAULT_NC_GAUGE_NAME');
    lbGtyAttrib     := ASA_I_LIB_RECORD.isStatusInConfigOrDefault(iStatus, 'ASA_DEFAULT_ATTRIB_GAUGE_NAME');

    -- Si il s'agit d'un facturation pour une offre refusée, on contrôle
    -- si le montant à facturer est supérieur à 0}
    if     lbGtyOfferBill
       and lArePriceDevisMB > 0 then
      pGenerateDocument(iAsaRecordId => iAsaRecordId, iTypeGauge => 'gtyOfferBill');
    end if;

    -- Si le document à générer est un document d'attribution mais que l'on ne gère pas les attributions sur les composants
    -- ou que le dossier de réparation n'est pas de type réparation alors on ne génère pas de document }
    if lbGtyAttrib then
      if not(   lCAsaRepTypeKind <> '3'
             or PCS.PC_CONFIG.GetConfig('ASA_COMPONENT_ATTRIB') = 'False') then
        pGenerateDocument(iAsaRecordId => iAsaRecordId, iTypeGauge => 'gtyAttrib');
      end if;
    end if;

    -- Si le document à générer est une facture et si la réparation active a le code
    -- de génération de facture désactivé (ARE_GENERATE_BILL), alors le type de
    -- document à générer est un bulletin de livraison}
    if     lbGtyBill
       and lAreGenerateBill = 0
       and PCS.PC_CONFIG.GetConfig('ASA_DEFAULT_BULIV_GAUGE_NAME') is not null then
      if lAreLposCompTask = 1 then
        --Contrôle qu'il n'y pas d'option acceptées qui ne sont pas sous garantie
        select count(*)
          into lnCountConfig
          from (select asa_record_id
                  from asa_record_comp
                 where asa_record_id = iAsaRecordId
                   and asa_record_events_id = iAsaRecordEventsId
                   and arc_optional = 1
                   and C_ASA_ACCEPT_OPTION = '2'
                   and arc_guaranty_code = 0
                union
                select asa_record_id
                  from asa_record_task
                 where asa_record_id = iAsaRecordId
                   and asa_record_events_id = iAsaRecordEventsId
                   and ret_optional = 1
                   and C_ASA_ACCEPT_OPTION = '2'
                   and ret_guaranty_code = 0);

        if lnCountConfig = 0 then
          -- si il n'y a pas de facture (garantie) -> génération d'un bulletin de livraison
          lbGtyBuLiv  := true;
          lbGtyBill   := false;
        end if;
      else
        --si il n'y a pas de facture (garantie) -> génération d'un bulletin de livraison
        lbGtyBuLiv  := true;
        lbGtyBill   := false;
      end if;
    end if;

    if lbGtyOffer then
      pGenerateDocument(iAsaRecordId => iAsaRecordId, iTypeGauge => 'gtyOffer', iSelectPrice => lSelectPrice);
    end if;

    if lbGtyBill then
      pGenerateDocument(iAsaRecordId => iAsaRecordId, iTypeGauge => 'gtyBill', iSelectPrice => lSelectPrice);
    end if;

    if lbGtyBuLiv then
      pGenerateDocument(iAsaRecordId => iAsaRecordId, iTypeGauge => 'gtyBuLiv');
    end if;

    if lbGtyCmdC then
      pGenerateDocument(iAsaRecordId => iAsaRecordId, iTypeGauge => 'gtyCmdC', iSelectPrice => lSelectPrice);
    end if;

    if lbGtyCmdS then
      pGenerateDocument(iAsaRecordId => iAsaRecordId, iTypeGauge => 'gtyCmdS');
    end if;

    if lbGtyNC then
      pGenerateDocument(iAsaRecordId => iAsaRecordId, iTypeGauge => 'gtyNC');
    end if;
  end GenerateDocuments;

  /*
  * Description
  *   Génération de l'OF
  */
  procedure GenerateOF(iAsaRecordId in ASA_RECORD.ASA_RECORD_ID%type, iStatus in ASA_RECORD_EVENTS.C_ASA_REP_STATUS%type)
  is
    lGenerateOF      integer;
    lLaunchOF        integer;
    lPlanBeginDate   date;
    lFalJobProgramId FAL_JOB_PROGRAM.FAL_JOB_PROGRAM_ID%type;
  begin
    -- vérifier si l'on doit générer un OF
    begin
      select LID_SELECTION
           , LID_FREE_NUMBER_1
           , LID_FREE_DATE_1
           , LID_ID_1
        into lGenerateOF
           , lLaunchOF
           , lPlanBeginDate
           , lFalJobProgramId
        from COM_LIST_ID_TEMP
       where LID_CODE = gcFalJobProgramTmpCode;
    exception
      when no_data_found then
        lGenerateOF  := 0;
    end;

    if lGenerateOF = 1 then
      -- Génération de l'OF
      ASA_PRC_RECORD_EVENTS.GenerateOF(iAsaRecordId       => iAsaRecordId
                                     , iStatus            => iStatus
                                     , iLaunchOF          => lLaunchOF
                                     , iPlanBeginDate     => lPlanBeginDate
                                     , iFalJobProgramId   => lFalJobProgramId
                                      );
    end if;
  end GenerateOF;

  /**
  * procedure UpdateRecordStatus
  * Description
  *   Màj du statut du dossier SAV
  */
  procedure UpdateRecordStatus(
    iAsaRecordId in     ASA_RECORD.ASA_RECORD_ID%type
  , iNewStatus   in     ASA_RECORD_EVENTS.C_ASA_REP_STATUS%type
  , oSuccessfull out    integer
  , oErrorMsg    out    varchar2
  )
  is
    ltRecord       FWK_I_TYP_DEFINITION.t_crud_def;
    ltRecordEvents FWK_I_TYP_DEFINITION.t_crud_def;
    lnProtected    ASA_RECORD.ARE_PROTECTED%type;
    lEventID       ASA_RECORD_EVENTS.ASA_RECORD_EVENTS_ID%type;
  begin
    select max(nvl(ARE_PROTECTED, 0) )
      into lnProtected
      from ASA_RECORD
     where ASA_RECORD_ID = iAsaRecordId;

    if lnProtected = 0 then
      begin
        -- Création de l'entité ASA_RECORD_EVENTS
        FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordEvents, ltRecordEvents, true);
        -- Init de l'id du dossier SAV
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordEvents, 'ASA_RECORD_ID', iAsaRecordId);
        -- Init du status
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordEvents, 'C_ASA_REP_STATUS', iNewStatus);
        FWK_I_MGT_ENTITY.InsertEntity(ltRecordEvents);
        lEventID      := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltRecordEvents, 'ASA_RECORD_EVENTS_ID');
        FWK_I_MGT_ENTITY.Release(ltRecordEvents);
        --
        -- Génération documents
        GenerateDocuments(iAsaRecordId => iAsaRecordId, iAsaRecordEventsId => lEventID, iStatus => iNewStatus);
        -- Génération OF
        GenerateOF(iAsaRecordId => iAsaRecordId, iStatus => iNewStatus);
        -- Finalisation du dossier SAV déclenche les procédure externes BeforeValidate, AfterValidate
        ASA_PRC_RECORD.FinalizeRecord(iAsaRecordId);
        -- Traitement terminé avec succès
        oSuccessfull  := 1;
        oErrorMsg     := null;
      exception
        when others then
          oSuccessfull  := 0;
          oErrorMsg     := sqlerrm || co.cLineBreak || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
      end;
    else
      oSuccessfull  := 0;
      oErrorMsg     := PCS.PC_FUNCTIONS.TranslateWord('Ce dossier est en attente de réception d''un lot de fabrication !');
    end if;
  end UpdateRecordStatus;

  /**
  * procedure GetGeneratedDocs
  * Description
  *   Renvoi les documents qui ont été générés pour un dossier SAV
  *     lors du processus de changement de statut du dossier SAV
  */
  function GetGeneratedDocs(iAsaRecordID in ASA_RECORD.ASA_RECORD_ID%type)
    return varchar2
  is
    lvDocs varchar2(4000);
  begin
    -- Balayer la liste des documents créés
    for ltplDocs in (select   DMT.DMT_NUMBER
                         from DOC_DOCUMENT DMT
                            , COM_LIST_ID_TEMP LID
                        where LID.LID_CODE = gcDocumentTmpCode
                          and LID.LID_ID_1 = iAsaRecordID
                          and LID.LID_ID_2 = DMT.DOC_DOCUMENT_ID
                     order by LID.COM_LIST_ID_TEMP_ID asc) loop
      if lvDocs is null then
        lvDocs  := ltplDocs.DMT_NUMBER;
      else
        lvDocs  := lvDocs || ' , ' || ltplDocs.DMT_NUMBER;
      end if;
    end loop;

    return lvDocs;
  end GetGeneratedDocs;

  /**
  * procedure CreatePrintJobs
  * Description
  *   Création des jobs d'impression pour imprimer les document créés
  *     lors du processus de changement de statut du dossier SAV
  */
  procedure CreatePrintJobs(oJobCreated out integer)
  is
    lGaugeID      DOC_GAUGE.DOC_GAUGE_ID%type;
    lPrintJobID   DOC_PRINT_JOB.DOC_PRINT_JOB_ID%type;
    lDocumentList clob;
    lvJobName     DOC_PRINT_JOB.PJO_NAME%type;
  begin
    lGaugeID     := 0;
    oJobCreated  := 0;

    -- Création d'un job d'impression par gabarit
    for ltplGauge in (select   GAU.GAU_DESCRIBE
                             , GAU.DOC_GAUGE_ID
                             , LID_GAU.LID_CLOB as PRINT_OPTIONS
                          from DOC_GAUGE GAU
                             , COM_LIST_ID_TEMP LID_GAU
                             , (select   DMT.DOC_GAUGE_ID
                                    from DOC_DOCUMENT DMT
                                       , COM_LIST_ID_TEMP LID_DMT
                                   where LID_DMT.LID_CODE = gcDocumentTmpCode
                                     and DMT.DOC_DOCUMENT_ID = LID_DMT.LID_ID_2
                                group by DMT.DOC_GAUGE_ID) DMT_GAU
                         where LID_GAU.LID_CODE = gcGaugeTmpCode
                           and DMT_GAU.DOC_GAUGE_ID = LID_GAU.LID_ID_1
                           and GAU.DOC_GAUGE_ID = DMT_GAU.DOC_GAUGE_ID
                           and LID_GAU.LID_FREE_NUMBER_2 = 1
                      order by GAU.GAU_DESCRIBE asc) loop
      lDocumentList  := null;

      -- Liste des documents créés à imprimer
      for ltplDocs in (select   DMT.DOC_DOCUMENT_ID
                           from DOC_DOCUMENT DMT
                              , COM_LIST_ID_TEMP LID_DMT
                          where LID_DMT.LID_CODE = gcDocumentTmpCode
                            and DMT.DOC_DOCUMENT_ID = LID_DMT.LID_ID_2
                            and DMT.DOC_GAUGE_ID = ltplGauge.DOC_GAUGE_ID
                       order by DMT.DMT_NUMBER asc) loop
        if lDocumentList is null then
          lDocumentList  := to_char(ltplDocs.DOC_DOCUMENT_ID);
        else
          lDocumentList  := lDocumentList || ',' || to_char(ltplDocs.DOC_DOCUMENT_ID);
        end if;
      end loop;

      if lDocumentList is not null then
        -- Nom du job d'impression
        lvJobName    :=
          PCS.PC_I_LIB_SESSION.GetUserIni ||
          ' - ' ||
          PCS.PC_FUNCTIONS.TranslateWord('Dossier SAV') ||
          ' - ' ||
          ltplGauge.GAU_DESCRIBE ||
          ' - ' ||
          to_char(sysdate, 'DD.MM.YYYY HH24:MI:SS');
        -- La longueur max du nom du job est de 100 caractères
        lvJobName    := substr(lvJobName, 1, 100);
        lPrintJobID  := null;
        -- Création du job d'impression
        DOC_BATCH_PRINT.CreatePrintJob(oPrintJobID     => lPrintJobID
                                     , iJobName        => lvJobName
                                     , iDocumentList   => lDocumentList
                                     , iPrintOptions   => ltplGauge.PRINT_OPTIONS
                                      );

        -- Ajout d'un log pour le job d'impression créé
        if lPrintJobID is not null then
          CreatePrintJobLog(iPrintJobID => lPrintJobID);
          oJobCreated  := 1;
        end if;
      end if;
    end loop;
  end CreatePrintJobs;
end ASA_PRC_RECORD_SERIAL;
