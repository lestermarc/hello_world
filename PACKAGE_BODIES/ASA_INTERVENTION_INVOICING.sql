--------------------------------------------------------
--  DDL for Package Body ASA_INTERVENTION_INVOICING
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_INTERVENTION_INVOICING" 
is
/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * function GetExtractParamsInfo
  * Description
  *    Extraction des données relatives aux filtres pour la génération
  *      des propositions à facturer
  */
  function GetExtractParamsInfo(aParams in clob)
    return TExtractParamsInfo
  is
    vParamsInfo TExtractParamsInfo;
    vXML        xmltype;
  begin
    vXML  := xmltype.CreateXML(aParams);

    select extractvalue(vXML, '//AIJ_PROFILE_NAME') AIJ_PROFILE_NAME
         , extractvalue(vXML, '//AIJ_MISSION_TYPE_FROM') AIJ_MISSION_TYPE_FROM
         , extractvalue(vXML, '//AIJ_MISSION_TYPE_TO') AIJ_MISSION_TYPE_TO
         , extractvalue(vXML, '//AIJ_MISSION_FROM') AIJ_MISSION_FROM
         , extractvalue(vXML, '//AIJ_MISSION_TO') AIJ_MISSION_TO
         , extractvalue(vXML, '//AIJ_CUSTOM_FROM') AIJ_CUSTOM_FROM
         , extractvalue(vXML, '//AIJ_CUSTOM_TO') AIJ_CUSTOM_TO
         , extractvalue(vXML, '//AIJ_INTERVENTION_FROM') AIJ_INTERVENTION_FROM
         , extractvalue(vXML, '//AIJ_INTERVENTION_TO') AIJ_INTERVENTION_TO
         , to_number(extractvalue(vXML, '//AIJ_INVOICE_GAUGE_ID') ) AIJ_INVOICE_GAUGE_ID
         , to_number(extractvalue(vXML, '//AIJ_CREDIT_NOTE_GAUGE_ID') ) AIJ_CREDIT_NOTE_GAUGE_ID
         , to_number(extractvalue(vXML, '//AIJ_GEN_MIS_COMMENT_POS') ) AIJ_GEN_MIS_COMMENT_POS
         , to_number(extractvalue(vXML, '//AIJ_GEN_ITR_COMMENT_POS') ) AIJ_GEN_ITR_COMMENT_POS
         , to_number(extractvalue(vXML, '//AIJ_AUTO_PRINT') ) AIJ_AUTO_PRINT
         , to_number(extractvalue(vXML, '//AIJ_AUTO_CONFIRM') ) AIJ_AUTO_CONFIRM
         , to_date(extractvalue(vXML, '//AIJ_EXTRACTION_DATE'), 'DD.MM.YYYY') AIJ_EXTRACTION_DATE
         , to_date(extractvalue(vXML, '//AIJ_DOCUMENT_DATE'), 'DD.MM.YYYY') AIJ_DOCUMENT_DATE
         , to_date(extractvalue(vXML, '//AIJ_DATE_VALUE'), 'DD.MM.YYYY') AIJ_DATE_VALUE
         , to_date(extractvalue(vXML, '//AIJ_DATE_DELIVERY'), 'DD.MM.YYYY') AIJ_DATE_DELIVERY
         , to_date(extractvalue(vXML, '//AIJ_DATE_FROM'), 'DD.MM.YYYY') AIJ_DATE_FROM
         , to_date(extractvalue(vXML, '//AIJ_DATE_TO'), 'DD.MM.YYYY') AIJ_DATE_TO
         , PCS.PC_FUNCTIONS.XmlExtractClobValue(vXML, '//AIJ_USER_SQL_SQLCODE') AIJ_USER_SQL_SQLCODE
      into vParamsInfo
      from dual;

    return vParamsInfo;
  end GetExtractParamsInfo;

/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * procedure GenerateInvoicingPropositions
  * Description
  *    Génération des propositions pour la facturation des interventions
  */
  procedure GenerateInvoicingPropositions(aInvoicingJobID in ASA_INVOICING_JOB.ASA_INVOICING_JOB_ID%type, aParams in clob)
  is
    nPositions   number(5);
    vParamsInfo  TExtractParamsInfo;
    vSQL_Command varchar2(32000);
  begin
    vParamsInfo  := GetExtractParamsInfo(aParams);
    -- Effacement des propositions pour la facturation des contrats
    DeleteInvoicingPropositions(aInvoicingJobID);

    -- Effacement des données de la table utilisée pour le cmd sql filtre de l'utilisateur
    delete from COM_LIST_ID_TEMP_CD;

    -- Tenir compte de la cmd sql de l'utilisateur
    if vParamsInfo.AIJ_USER_SQL_SQLCODE is null then
      insert into COM_LIST_ID_TEMP_CD
                  (COM_LIST_ID_TEMP_CD_ID
                  )
        select ASA_INTERVENTION_DETAIL_ID
          from ASA_INTERVENTION_DETAIL;
    else
      vSQL_Command  :=
        'insert into COM_LIST_ID_TEMP_CD (COM_LIST_ID_TEMP_CD_ID) ' ||
        ' select distinct ASA_INTERVENTION_DETAIL_ID from (' ||
        vParamsInfo.AIJ_USER_SQL_SQLCODE ||
        ' ) ';

      execute immediate vSQL_Command;
    end if;

    -- Insertion des interventions (détail) correspondant aux filtres de sélection
    -- dans la table des propositions de facturation
    insert into ASA_INVOICING_PROCESS
                (ASA_INVOICING_PROCESS_ID
               , ASA_INVOICING_JOB_ID
               , ASA_INTERVENTION_DETAIL_ID
               , ASA_INTERVENTION_ID
               , ASA_MISSION_ID
               , ASA_MISSION_TYPE_ID
               , DOC_GAUGE_ID
               , AIP_SELECTION
               , PAC_CUSTOM_PARTNER_ID
               , PAC_CUSTOM_PARTNER_ACI_ID
               , ACS_FINANCIAL_CURRENCY_ID
               , PAC_PAYMENT_CONDITION_ID
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval
           , aInvoicingJobID
           , AID.ASA_INTERVENTION_DETAIL_ID
           , ITR.ASA_INTERVENTION_ID
           , MIS.ASA_MISSION_ID
           , MIT.ASA_MISSION_TYPE_ID
           , case
               when nvl(vParamsInfo.AIJ_INVOICE_GAUGE_ID, 0) = 0 then MIT.MIT_INVOICE_GAUGE_ID
               else vParamsInfo.AIJ_INVOICE_GAUGE_ID
             end
           , 1
           , MIS.PAC_CUSTOM_PARTNER_ID
           , CUS_ACI.PAC_CUSTOM_PARTNER_ID   -- Voir cascade dans le where
           , MIS.ACS_FINANCIAL_CURRENCY_ID
           , MIS.PAC_PAYMENT_CONDITION_ID
           , sysdate
           , pcs.PC_I_LIB_SESSION.GetUserIni
        from ASA_INTERVENTION_DETAIL AID
           , COM_LIST_ID_TEMP_CD LCD
           , ASA_INTERVENTION ITR
           , ASA_MISSION MIS
           , ASA_MISSION_TYPE MIT
           , PAC_PERSON PER
           , PAC_CUSTOM_PARTNER CUS_CCO
           , PAC_CUSTOM_PARTNER CUS_MIS
           , PAC_CUSTOM_PARTNER CUS_ACI
           , CML_DOCUMENT CCO
           , CML_POSITION CPO
       where AID.ASA_INTERVENTION_ID = ITR.ASA_INTERVENTION_ID
         and AID.ASA_INTERVENTION_DETAIL_ID = LCD.COM_LIST_ID_TEMP_CD_ID
         and ITR.ASA_MISSION_ID = MIS.ASA_MISSION_ID
         and MIS.ASA_MISSION_TYPE_ID = MIT.ASA_MISSION_TYPE_ID
         and MIS.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
         -- Mission clôturée
         and MIS.C_ASA_MIS_STATUS = '02'
         -- Intervention clôturée
         and ITR.C_ASA_ITR_STATUS = '02'
         -- Détail d'intervention facturable
         and nvl(AID.AID_INVOICING_QTY, 0) > 0
         -- Filtre sur les types de mission
         and MIT.MIT_CODE between nvl(vParamsInfo.AIJ_MISSION_TYPE_FROM, lpad(' ', 30, chr(1) ) )
                              and nvl(vParamsInfo.AIJ_MISSION_TYPE_TO, lpad(' ', 30, chr(255) ) )
         -- Filtre sur les clients
         and PER.PER_NAME between nvl(vParamsInfo.AIJ_CUSTOM_FROM, lpad(' ', 60, chr(1) ) ) and nvl(vParamsInfo.AIJ_CUSTOM_TO, lpad(' ', 60, chr(255) ) )
         -- Filtre sur les missions
         and MIS.MIS_NUMBER between nvl(vParamsInfo.AIJ_MISSION_FROM, lpad(' ', 30, chr(1) ) ) and nvl(vParamsInfo.AIJ_MISSION_TO, lpad(' ', 30, chr(255) ) )
         -- Filtre sur les interventions
         and ITR.ITR_NUMBER between nvl(vParamsInfo.AIJ_INTERVENTION_FROM, 0) and nvl(vParamsInfo.AIJ_INTERVENTION_TO, 99999999999999)
         -- Filtre sur la date d'intervention
         and ITR.ITR_START_DATE between nvl(vParamsInfo.AIJ_DATE_FROM, ITR.ITR_START_DATE) and nvl(vParamsInfo.AIJ_DATE_TO, ITR.ITR_START_DATE)
         -- Filtre sur les missions non protégées
         and MIS.MIS_PROTECTED = 0
         -- Missions facturables (si non-facturables MIS_NON_BILLABLE = 1 )
         and nvl(MIS.MIS_NON_BILLABLE, 0) = 0
         and CCO.CML_DOCUMENT_ID(+) = CPO.CML_DOCUMENT_ID
         and CPO.CML_POSITION_ID(+) = MIS.CML_POSITION_ID
         and CUS_CCO.PAC_CUSTOM_PARTNER_ID(+) = CCO.PAC_CUSTOM_PARTNER_ID
         -- Client Actif en Logistique
         and CUS_MIS.PAC_CUSTOM_PARTNER_ID = MIS.PAC_CUSTOM_PARTNER_ID
         and CUS_MIS.C_PARTNER_STATUS = '1'
         -- Client de facturation (selon cascade DEVERP-21485)
         and CUS_ACI.PAC_CUSTOM_PARTNER_ID =
               case
                 -- Partenaire de facturation de la mission
               when MIS.PAC_CUSTOM_PARTNER_ACI_ID is not null then MIS.PAC_CUSTOM_PARTNER_ACI_ID
                 -- Si la mission est liée à une position de contrat
                 --  1. Partenaire facturation du contrat
                 --  2. Partenaire facturation lié au partenaire du contrat
                 --  3. Partenaire du contrat
               when MIS.CML_POSITION_ID is not null then coalesce(CCO.PAC_CUSTOM_PARTNER_ACI_ID, CUS_CCO.PAC_PAC_THIRD_1_ID, CCO.PAC_CUSTOM_PARTNER_ID)
                 -- Si la mission N'EST PAS liée à une position de contrat
                 --  1. Partenaire facturation lié au partenaire de la mission
                 --  2. Partenaire de la mission
               else coalesce(CUS_MIS.PAC_PAC_THIRD_1_ID, MIS.PAC_CUSTOM_PARTNER_ID)
               end
         and CUS_ACI.C_PARTNER_STATUS = '1';

    -- Protection des missions
    for tplMis in (select   ASA_MISSION_ID
                       from ASA_INVOICING_PROCESS
                      where ASA_INVOICING_JOB_ID = aInvoicingJobID
                   order by ASA_MISSION_ID) loop
      ASA_MISSION_FUNCTIONS.ProtectMission(tplMis.ASA_MISSION_ID, 1, aInvoicingJobID);
    end loop;
  end GenerateInvoicingPropositions;

/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * Description
  *    Effacement des propositions pour la facturation des interventions
  */
  procedure DeleteInvoicingPropositions(aInvoicingJobID in number)
  is
  begin
    -- Déprotection des positions qui ont été extraites
    for tplMis in (select distinct ASA_MISSION_ID
                              from (select ASA_MISSION_ID
                                      from ASA_INVOICING_PROCESS
                                     where ASA_INVOICING_JOB_ID = aInvoicingJobID
                                    union all
                                    select ASA_MISSION_ID
                                      from ASA_MISSION
                                     where ASA_INVOICING_JOB_ID = aInvoicingJobID) ) loop
      ASA_MISSION_FUNCTIONS.ProtectMission(tplMis.ASA_MISSION_ID, 0);
    end loop;

    -- Effacement des données dans la table d'extraction
    delete from ASA_INVOICING_PROCESS
          where ASA_INVOICING_JOB_ID = aInvoicingJobID
            and DOC_POSITION_ID is null;
  end DeleteInvoicingPropositions;

/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * procedure JobUnprotectUnusedPos
  * Description
  *    Déprotéger les positions qui ne figurent plus dans le job de facturation
  */
  procedure JobUnprotectUnusedPos(aJobID in number)
  is
  begin
    -- Déprotection des positions qui ont été extraites
    for tplMis in (select ASA_MISSION_ID
                     from ASA_MISSION
                    where MIS_PROTECTED = 1
                      and ASA_INVOICING_JOB_ID = aJobID
                      and ASA_MISSION_ID not in(select distinct ASA_MISSION_ID
                                                           from ASA_INVOICING_PROCESS
                                                          where ASA_INVOICING_JOB_ID = aJobID) ) loop
      ASA_MISSION_FUNCTIONS.ProtectMission(tplMis.ASA_MISSION_ID, 0);
    end loop;
  end JobUnprotectUnusedPos;

/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * Description
  *    Intitialisation des codes de regroupement
  */
  procedure PrepareRegroup(aInvoicingJobID in ASA_INVOICING_JOB.ASA_INVOICING_JOB_ID%type, aSQLCommand in clob)
  is
    type TInvProcessList is ref cursor;   -- define weak REF CURSOR type

    crInvProcessList          TInvProcessList;
    vASA_INVOICING_PROCESS_ID ASA_INVOICING_PROCESS.ASA_INVOICING_PROCESS_ID%type;
    vAIP_REGROUP_01           ASA_INVOICING_PROCESS.AIP_REGROUP_01%type;
    vAIP_REGROUP_02           ASA_INVOICING_PROCESS.AIP_REGROUP_02%type;
    vAIP_REGROUP_03           ASA_INVOICING_PROCESS.AIP_REGROUP_03%type;
    vAIP_REGROUP_04           ASA_INVOICING_PROCESS.AIP_REGROUP_04%type;
    vAIP_REGROUP_05           ASA_INVOICING_PROCESS.AIP_REGROUP_05%type;
    vAIP_REGROUP_06           ASA_INVOICING_PROCESS.AIP_REGROUP_06%type;
    vAIP_REGROUP_07           ASA_INVOICING_PROCESS.AIP_REGROUP_07%type;
    vAIP_REGROUP_08           ASA_INVOICING_PROCESS.AIP_REGROUP_08%type;
    vAIP_REGROUP_09           ASA_INVOICING_PROCESS.AIP_REGROUP_09%type;
    vAIP_REGROUP_10           ASA_INVOICING_PROCESS.AIP_REGROUP_10%type;
    vSQL                      varchar2(32000);
    vRegroupID                ASA_INVOICING_PROCESS.AIP_REGROUP_ID%type;
  begin
    update ASA_INVOICING_PROCESS
       set AIP_SELECTION = 0
         , AIP_REGROUP_ID = null
         , AIP_ORDER_ID = null
         , AIP_REGROUP_01 = null
         , AIP_REGROUP_02 = null
         , AIP_REGROUP_03 = null
         , AIP_REGROUP_04 = null
         , AIP_REGROUP_05 = null
         , AIP_REGROUP_06 = null
         , AIP_REGROUP_07 = null
         , AIP_REGROUP_08 = null
         , AIP_REGROUP_09 = null
         , AIP_REGROUP_10 = null
     where ASA_INVOICING_JOB_ID = aInvoicingJobID;

    vSQL  :=
      'select ASA_INVOICING_PROCESS_ID ' ||
      ', AIP_REGROUP_01 ' ||
      ', AIP_REGROUP_02 ' ||
      ', AIP_REGROUP_03 ' ||
      ', AIP_REGROUP_04 ' ||
      ', AIP_REGROUP_05 ' ||
      ', AIP_REGROUP_06 ' ||
      ', AIP_REGROUP_07 ' ||
      ', AIP_REGROUP_08 ' ||
      ', AIP_REGROUP_09 ' ||
      ', AIP_REGROUP_10 ' ||
      ' from ( ' ||
      aSQLCommand ||
      ')';

    /* Balayer la liste des documents créés et inserer dans la table de l'impression */
    open crInvProcessList for vSQL;

    loop
      fetch crInvProcessList
       into vASA_INVOICING_PROCESS_ID
          , vAIP_REGROUP_01
          , vAIP_REGROUP_02
          , vAIP_REGROUP_03
          , vAIP_REGROUP_04
          , vAIP_REGROUP_05
          , vAIP_REGROUP_06
          , vAIP_REGROUP_07
          , vAIP_REGROUP_08
          , vAIP_REGROUP_09
          , vAIP_REGROUP_10;

      exit when crInvProcessList%notfound;

      update ASA_INVOICING_PROCESS
         set AIP_SELECTION = 1
           , AIP_REGROUP_01 = vAIP_REGROUP_01
           , AIP_REGROUP_02 = vAIP_REGROUP_02
           , AIP_REGROUP_03 = vAIP_REGROUP_03
           , AIP_REGROUP_04 = vAIP_REGROUP_04
           , AIP_REGROUP_05 = vAIP_REGROUP_05
           , AIP_REGROUP_06 = vAIP_REGROUP_06
           , AIP_REGROUP_07 = vAIP_REGROUP_07
           , AIP_REGROUP_08 = vAIP_REGROUP_08
           , AIP_REGROUP_09 = vAIP_REGROUP_09
           , AIP_REGROUP_10 = vAIP_REGROUP_10
           , AIP_ORDER_ID = INIT_ID_SEQ.nextval
       where ASA_INVOICING_PROCESS_ID = vASA_INVOICING_PROCESS_ID;
    end loop;

    for tplProcess in (select   AIP_REGROUP_01
                              , AIP_REGROUP_02
                              , AIP_REGROUP_03
                              , AIP_REGROUP_04
                              , AIP_REGROUP_05
                              , AIP_REGROUP_06
                              , AIP_REGROUP_07
                              , AIP_REGROUP_08
                              , AIP_REGROUP_09
                              , AIP_REGROUP_10
                           from ASA_INVOICING_PROCESS
                          where ASA_INVOICING_JOB_ID = aInvoicingJobID
                            and AIP_SELECTION = 1
                       group by AIP_REGROUP_01
                              , AIP_REGROUP_02
                              , AIP_REGROUP_03
                              , AIP_REGROUP_04
                              , AIP_REGROUP_05
                              , AIP_REGROUP_06
                              , AIP_REGROUP_07
                              , AIP_REGROUP_08
                              , AIP_REGROUP_09
                              , AIP_REGROUP_10
                       order by AIP_REGROUP_01
                              , AIP_REGROUP_02
                              , AIP_REGROUP_03
                              , AIP_REGROUP_04
                              , AIP_REGROUP_05
                              , AIP_REGROUP_06
                              , AIP_REGROUP_07
                              , AIP_REGROUP_08
                              , AIP_REGROUP_09
                              , AIP_REGROUP_10) loop
      select init_id_seq.nextval
        into vRegroupID
        from dual;

      update ASA_INVOICING_PROCESS
         set AIP_REGROUP_ID = vRegroupID
       where ASA_INVOICING_JOB_ID = aInvoicingJobID
         and AIP_SELECTION = 1
         and nvl(AIP_REGROUP_01, 'NULL') = nvl(tplProcess.AIP_REGROUP_01, 'NULL')
         and nvl(AIP_REGROUP_02, 'NULL') = nvl(tplProcess.AIP_REGROUP_02, 'NULL')
         and nvl(AIP_REGROUP_03, 'NULL') = nvl(tplProcess.AIP_REGROUP_03, 'NULL')
         and nvl(AIP_REGROUP_04, 'NULL') = nvl(tplProcess.AIP_REGROUP_04, 'NULL')
         and nvl(AIP_REGROUP_05, 'NULL') = nvl(tplProcess.AIP_REGROUP_05, 'NULL')
         and nvl(AIP_REGROUP_06, 'NULL') = nvl(tplProcess.AIP_REGROUP_06, 'NULL')
         and nvl(AIP_REGROUP_07, 'NULL') = nvl(tplProcess.AIP_REGROUP_07, 'NULL')
         and nvl(AIP_REGROUP_08, 'NULL') = nvl(tplProcess.AIP_REGROUP_08, 'NULL')
         and nvl(AIP_REGROUP_09, 'NULL') = nvl(tplProcess.AIP_REGROUP_09, 'NULL')
         and nvl(AIP_REGROUP_10, 'NULL') = nvl(tplProcess.AIP_REGROUP_10, 'NULL');
    end loop;
  end PrepareRegroup;

/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * Description
  *    Génération des factures
  */
  procedure GenerateInvoices(aInvoicingJobID in ASA_INVOICING_JOB.ASA_INVOICING_JOB_ID%type)
  is
    cursor crInvDocument
    is
      select   AIP_REGROUP_ID
             , min(ASA_INVOICING_PROCESS_ID) ASA_INVOICING_PROCESS_ID
             , max(DOC_GAUGE_ID) DOC_GAUGE_ID
          from ASA_INVOICING_PROCESS
         where ASA_INVOICING_JOB_ID = aInvoicingJobID
           and AIP_SELECTION = 1
           --Ceci pour empêcher la génération de document qui ont déjà été généré
           --On aurait très pu également tester le doc_document_id : and ASA_INVOICING_PROCESS.DOC_DOCUMENT_ID is null
           and ASA_INVOICING_PROCESS.doc_position_id is null
      group by AIP_REGROUP_ID
      order by AIP_REGROUP_ID;

    tplInvDocument crInvDocument%rowtype;
    vParamsInfo    TExtractParamsInfo;
    vClob          clob;
    vDocumentID    DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    vPositionID    DOC_POSITION.DOC_POSITION_ID%type;
    vNewMission    ASA_MISSION.ASA_MISSION_ID%type;
    vNewInterv     ASA_INTERVENTION.ASA_INTERVENTION_ID%type;
    vErrorMsg      varchar2(4000);
    vErrorCode     varchar2(30);
    vErrorText     varchar2(500);
  begin
    -- Déprotéger les missions appartenant à des propositions qui n'ont pas été sélectionnées
    for tplUnselectMis in (select distinct ASA_MISSION_ID
                                      from ASA_INVOICING_PROCESS
                                     where ASA_INVOICING_JOB_ID = aInvoicingJobID
                                       and AIP_SELECTION = 0
                                       and ASA_MISSION_ID not in(select distinct ASA_MISSION_ID
                                                                            from ASA_INVOICING_PROCESS
                                                                           where ASA_INVOICING_JOB_ID = aInvoicingJobID
                                                                             and AIP_SELECTION = 1) ) loop
      -- Déprotection de la mission
      ASA_MISSION_FUNCTIONS.ProtectMission(tplUnselectMis.ASA_MISSION_ID, 0);
    end loop;

    -- Effacer les propositions qui n'ont pas été sélectionnées
    delete      ASA_INVOICING_PROCESS
          where ASA_INVOICING_JOB_ID = aInvoicingJobID
            and AIP_SELECTION = 0;

    -- Récupérer les paramètres de l'extraction du job
    select AIJ_EXTRACT_PARAMS
      into vClob
      from ASA_INVOICING_JOB
     where ASA_INVOICING_JOB_ID = aInvoicingJobID;

    vParamsInfo  := GetExtractParamsInfo(vClob);

    open crInvDocument;

    fetch crInvDocument
     into tplInvDocument;

    while crInvDocument%found loop
      -- Création du document
      vDocumentID  := null;

      -- Init spécial des dates
      if    (vParamsInfo.AIJ_DOCUMENT_DATE <> vParamsInfo.AIJ_DATE_DELIVERY)
         or (vParamsInfo.AIJ_DOCUMENT_DATE <> vParamsInfo.AIJ_DATE_VALUE) then
        DOC_DOCUMENT_GENERATE.ResetDocumentInfo(Doc_Document_Initialize.DocumentInfo);
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.CLEAR_DOCUMENT_INFO    := 0;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_VALUE     := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_VALUE         := vParamsInfo.AIJ_DATE_VALUE;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_DELIVERY  := 1;
        DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_DELIVERY      := vParamsInfo.AIJ_DATE_DELIVERY;
      end if;

      -- Création du document
      DOC_DOCUMENT_GENERATE.GenerateDocument(aNewDocumentID   => vDocumentID
                                           , aMode            => '155'
                                           , aGaugeID         => tplInvDocument.DOC_GAUGE_ID
                                           , aDocDate         => vParamsInfo.AIJ_DOCUMENT_DATE
                                           , aSrcDocumentID   => tplInvDocument.ASA_INVOICING_PROCESS_ID
                                            );
      -- Initialisation des variables pour les positions commentaire
      vNewMission  := 0;
      vNewInterv   := 0;

      for cr_Position in (select   *
                              from ASA_INVOICING_PROCESS
                             where ASA_INVOICING_JOB_ID = aInvoicingJobID
                               and AIP_REGROUP_ID = tplInvDocument.AIP_REGROUP_ID
                          order by AIP_ORDER_ID) loop
        -- Génération d'une position commentaire à chaque nouvelle mission (selon flag)
        if     (vParamsInfo.AIJ_GEN_MIS_COMMENT_POS = 1)
           and (cr_Position.ASA_MISSION_ID <> vNewMission) then
          vPositionID  := null;
          GenerateInvoicePos(vPositionID, vDocumentID, '4', cr_Position.ASA_INTERVENTION_DETAIL_ID, cr_Position.ASA_MISSION_ID);
          vNewMission  := cr_Position.ASA_MISSION_ID;
        end if;

        -- Génération d'une position commentaire à chaque nouvelle intervention (selon flag)
        if     (vParamsInfo.AIJ_GEN_ITR_COMMENT_POS = 1)
           and (cr_Position.ASA_INTERVENTION_ID <> vNewInterv) then
          vPositionID  := null;
          GenerateInvoicePos(vPositionID, vDocumentID, '4', cr_Position.ASA_INTERVENTION_DETAIL_ID, cr_Position.ASA_INTERVENTION_ID);
          vNewInterv   := cr_Position.ASA_INTERVENTION_ID;
        end if;

        -- Pour chaque enregistrement de la table, générer une position de document
        vPositionID  := null;
        GenerateInvoicePos(vPositionID, vDocumentID, '1', cr_Position.ASA_INTERVENTION_DETAIL_ID, null);
        -- Màj de la proposition avec le n° de document et la position générés
        UpdateInvProcess(cr_Position.ASA_INVOICING_PROCESS_ID, vDocumentID, vPositionID);
      end loop;

      -- Màj des derniers élements du document (statut, montants, etc.)
      DOC_FINALIZE.FinalizeDocument(vDocumentID, 1, 1, 1);

      -- Confirmation automatique du document selon flag
      if (vParamsInfo.AIJ_AUTO_CONFIRM = 1) then
        DOC_DOCUMENT_FUNCTIONS.ConfirmDocument(aDocumentId => vDocumentID, aErrorCode => vErrorCode, aErrorText => vErrorText, aUserConfirmation => 1);
      end if;

      commit;
      -- Mise à jour de l'ID de document de facturation sur les interventions facturés
      UpdateIntervDoc(aInvoicingJobID);

      -- Document à créer suivant
      fetch crInvDocument
       into tplInvDocument;
    end loop;

    -- Génération des travaux d'impression pour les documents à imprimer selon flag
    if (vParamsInfo.AIJ_AUTO_PRINT = 1) then
      GeneratePrintJob(aInvoicingJobID);
    end if;

    -- Statut du job de facturation -> En cours de facturation
    update ASA_INVOICING_JOB
       set C_ASA_INVOICING_JOB_STATUS = '2'
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where ASA_INVOICING_JOB_ID = aInvoicingJobID;
  end GenerateInvoices;

/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * Description
  *   Procédure de génération des positions de facture des interventions
  */
  procedure GenerateInvoicePos(
    aPositionID   in out DOC_POSITION.DOC_POSITION_ID%type
  , aDocumentID   in     DOC_POSITION.DOC_DOCUMENT_ID%type
  , aGgeTypPos    in     DOC_POSITION.C_GAUGE_TYPE_POS%type
  , aIntervDetID  in     ASA_INTERVENTION_DETAIL.ASA_INTERVENTION_DETAIL_ID%type
  , aTextOriginID in     ASA_MISSION.ASA_MISSION_ID%type
  )
  is
    vGoodId       GCO_GOOD.GCO_GOOD_ID%type;
    vDetailId     DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    vPosNumber    DOC_POSITION.POS_NUMBER%type;
    vStockID      DOC_POSITION.STM_STOCK_ID%type;
    vLocationId   DOC_POSITION.STM_LOCATION_ID%type;
    tmpGaugeType  DOC_GAUGE.C_GAUGE_TYPE%type;
    tmpAutoAttrib DOC_GAUGE_STRUCTURED.GAS_AUTO_ATTRIBUTION%type;
    aPosBodyText  DOC_POSITION.POS_BODY_TEXT%type;

    cursor crIntervInfo(IntervDetID ASA_INTERVENTION_DETAIL.ASA_INTERVENTION_DETAIL_ID%type)
    is
      select nvl(GCO_GOOD_ID, GCO_SERVICE_ID) GCO_GOOD_ID
           , AID_INVOICING_QTY
           , AID_RETURN_STOCK_ID
           , AID_RETURN_LOCATION_ID
           , AID_UNIT_PRICE
           , AID_COST_PRICE
           , AID_CHAR1_VALUE
           , AID_CHAR2_VALUE
           , AID_CHAR3_VALUE
           , AID_CHAR4_VALUE
           , AID_CHAR5_VALUE
           , AID_SHORT_DESCR
           , AID_LONG_DESCR
           , AID_FREE_DESCR
        from ASA_INTERVENTION_DETAIL
       where ASA_INTERVENTION_DETAIL_ID = IntervDetID;

    tplIntervInfo crIntervInfo%rowtype;
  begin
    open crIntervInfo(aIntervDetID);

    fetch crIntervInfo
     into tplIntervInfo;

    -- Texte de la position pour les positions de type texte
    if aGgeTypPos = '4' then
      select DESCRIPTION
        into aPosBodyText
        from (select MIS_DESCRIPTION DESCRIPTION
                from ASA_MISSION
               where ASA_MISSION_ID = aTextOriginID
              union
              select ITR_DESCRIPTION1 DESCRIPTION
                from ASA_INTERVENTION
               where ASA_INTERVENTION_ID = aTextOriginID);
    else
      aPosBodyText  := '';
    end if;

    -- Initialisation des données de la position que l'on va créer
    DOC_POSITION_GENERATE.ResetPositionInfo(DOC_POSITION_INITIALIZE.PositionInfo);
    DOC_POSITION_INITIALIZE.PositionInfo.CLEAR_POSITION_INFO             := 0;
    DOC_POSITION_INITIALIZE.PositionInfo.USE_ASA_INTERVENTION_DETAIL_ID  := 1;
    DOC_POSITION_INITIALIZE.PositionInfo.ASA_INTERVENTION_DETAIL_ID      := aIntervDetID;
    DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_SHORT_DESCRIPTION       := 1;
    DOC_POSITION_INITIALIZE.PositionInfo.POS_SHORT_DESCRIPTION           := tplIntervInfo.AID_SHORT_DESCR;
    DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_LONG_DESCRIPTION        := 1;
    DOC_POSITION_INITIALIZE.PositionInfo.POS_LONG_DESCRIPTION            := tplIntervInfo.AID_LONG_DESCR;
    DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_FREE_DESCRIPTION        := 1;
    DOC_POSITION_INITIALIZE.PositionInfo.POS_FREE_DESCRIPTION            := tplIntervInfo.AID_FREE_DESCR;
    -- Création de la position
    DOC_POSITION_GENERATE.GeneratePosition(aPositionID       => aPositionId
                                         , aDocumentID       => aDocumentId
                                         , aPosCreateMode    => '155'
                                         , aTypePos          => aGgeTypPos
                                         , aPosBodyText      => aPosBodyText
                                         , aGoodID           => tplIntervInfo.GCO_GOOD_ID
                                         , aBasisQuantity    => tplIntervInfo.AID_INVOICING_QTY
                                         , aStockID          => tplIntervInfo.AID_RETURN_STOCK_ID
                                         , aLocationID       => tplIntervInfo.AID_RETURN_LOCATION_ID
                                         , aUnitCostPrice    => tplIntervInfo.AID_COST_PRICE
                                         , aGoodPrice        => tplIntervInfo.AID_UNIT_PRICE
                                         , aCharactValue_1   => tplIntervInfo.AID_CHAR1_VALUE
                                         , aCharactValue_2   => tplIntervInfo.AID_CHAR2_VALUE
                                         , aCharactValue_3   => tplIntervInfo.AID_CHAR3_VALUE
                                         , aCharactValue_4   => tplIntervInfo.AID_CHAR4_VALUE
                                         , aCharactValue_5   => tplIntervInfo.AID_CHAR5_VALUE
                                          );

    close crIntervInfo;
  end GenerateInvoicePos;

/*--------------------------------------------------------------------------------------------------------------------*/
/**
* Description
*    Mise à jour de l'ID de document de facturation sur les interventions facturés
*/
  procedure UpdateIntervDoc(aInvoicingJobID in ASA_INVOICING_JOB.ASA_INVOICING_JOB_ID%type)
  is
    vCount number;
  begin
    for crInterv in (select distinct DOC.DOC_DOCUMENT_ID
                                   , AID.ASA_INTERVENTION_ID
                                from DOC_DOCUMENT DOC
                                   , DOC_POSITION POS
                                   , ASA_INTERVENTION_DETAIL AID
                               where DOC.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                                 and POS.ASA_INTERVENTION_DETAIL_ID = AID.ASA_INTERVENTION_DETAIL_ID
                                 and AID.ASA_INTERVENTION_ID in(select ASA_INTERVENTION_ID
                                                                  from ASA_INVOICING_PROCESS
                                                                 where ASA_INVOICING_JOB_ID = aInvoicingJobID) ) loop
      update ASA_INTERVENTION
         set DOC_DOCUMENT_ID = crInterv.DOC_DOCUMENT_ID
           , C_ASA_ITR_STATUS = '05'   -- facturée
       where ASA_INTERVENTION_ID = crInterv.ASA_INTERVENTION_ID;
    end loop;

    -- Si toutes les interventions de la mission sont facturées, le statut de la mission passe également à "facturée"
    for crMission in (select distinct ASA_MISSION_ID
                                 from ASA_INVOICING_PROCESS
                                where ASA_INVOICING_JOB_ID = aInvoicingJobID) loop
      select count(*)
        into vCount
        from ASA_INTERVENTION
       where ASA_MISSION_ID = crMission.ASA_MISSION_ID
         and C_ASA_ITR_STATUS <> '05';

      if (vCount = 0) then
        update ASA_MISSION
           set C_ASA_MIS_STATUS = '05'
         where ASA_MISSION_ID = crMission.ASA_MISSION_ID;
      end if;
    end loop;
  end UpdateIntervDoc;

/*--------------------------------------------------------------------------------------------------------------------*/
/**
* Description
*    Génération du travail d'impression des documents facturés
*/
  procedure GeneratePrintJob(aInvoicingJobID in ASA_INVOICING_JOB.ASA_INVOICING_JOB_ID%type)
  is
    cursor crGauge
    is
      select distinct DOC.DOC_GAUGE_ID
                    , GAU.GAU_EDIT_NAME
                    , GAU.GAU_EDIT_NAME1
                    , GAU.GAU_EDIT_NAME2
                    , GAU.GAU_EDIT_NAME3
                    , GAU.GAU_EDIT_NAME4
                    , GAU.GAU_EDIT_NAME5
                    , GAU.GAU_EDIT_NAME6
                    , GAU.GAU_EDIT_NAME7
                    , GAU.GAU_EDIT_NAME8
                    , GAU.GAU_EDIT_NAME9
                    , GAU.GAU_EDIT_NAME10
                    , GAU.GAU_EDIT_TEXT
                    , GAU.GAU_EDIT_TEXT1
                    , GAU.GAU_EDIT_TEXT2
                    , GAU.GAU_EDIT_TEXT3
                    , GAU.GAU_EDIT_TEXT4
                    , GAU.GAU_EDIT_TEXT5
                    , GAU.GAU_EDIT_TEXT6
                    , GAU.GAU_EDIT_TEXT7
                    , GAU.GAU_EDIT_TEXT8
                    , GAU.GAU_EDIT_TEXT9
                    , GAU.GAU_EDIT_TEXT10
                    , GAU.GAU_EDIT_BOOL
                    , GAU.GAU_EDIT_BOOL1
                    , GAU.GAU_EDIT_BOOL2
                    , GAU.GAU_EDIT_BOOL3
                    , GAU.GAU_EDIT_BOOL4
                    , GAU.GAU_EDIT_BOOL5
                    , GAU.GAU_EDIT_BOOL6
                    , GAU.GAU_EDIT_BOOL7
                    , GAU.GAU_EDIT_BOOL8
                    , GAU.GAU_EDIT_BOOL9
                    , GAU.GAU_EDIT_BOOL10
                    , GAU.C_GAUGE_FORM_TYPE
                    , GAU.GAUGE_FORM_TYPE1
                    , GAU.GAUGE_FORM_TYPE2
                    , GAU.GAUGE_FORM_TYPE3
                    , GAU.GAUGE_FORM_TYPE4
                    , GAU.GAUGE_FORM_TYPE5
                    , GAU.GAUGE_FORM_TYPE6
                    , GAU.GAUGE_FORM_TYPE7
                    , GAU.GAUGE_FORM_TYPE8
                    , GAU.GAUGE_FORM_TYPE9
                    , GAU.GAUGE_FORM_TYPE10
                    , GAU.C_APPLI_COPY_SUPP
                    , GAU.APPLI_COPY_SUPP1
                    , GAU.APPLI_COPY_SUPP2
                    , GAU.APPLI_COPY_SUPP3
                    , GAU.APPLI_COPY_SUPP4
                    , GAU.APPLI_COPY_SUPP5
                    , GAU.APPLI_COPY_SUPP6
                    , GAU.APPLI_COPY_SUPP7
                    , GAU.APPLI_COPY_SUPP8
                    , GAU.APPLI_COPY_SUPP9
                    , GAU.APPLI_COPY_SUPP10
                    , GAU.GAU_COLLATE_COPIES
                    , GAU.GAU_COLLATE_COPIES1
                    , GAU.GAU_COLLATE_COPIES2
                    , GAU.GAU_COLLATE_COPIES3
                    , GAU.GAU_COLLATE_COPIES4
                    , GAU.GAU_COLLATE_COPIES5
                    , GAU.GAU_COLLATE_COPIES6
                    , GAU.GAU_COLLATE_COPIES7
                    , GAU.GAU_COLLATE_COPIES8
                    , GAU.GAU_COLLATE_COPIES9
                    , GAU.GAU_COLLATE_COPIES10
                    , GAU.GAU_REPORT_PRINT_TEST
                    , GAU.GAU_REPORT_PRINT_TEST1
                    , GAU.GAU_REPORT_PRINT_TEST2
                    , GAU.GAU_REPORT_PRINT_TEST3
                    , GAU.GAU_REPORT_PRINT_TEST4
                    , GAU.GAU_REPORT_PRINT_TEST5
                    , GAU.GAU_REPORT_PRINT_TEST6
                    , GAU.GAU_REPORT_PRINT_TEST7
                    , GAU.GAU_REPORT_PRINT_TEST8
                    , GAU.GAU_REPORT_PRINT_TEST9
                    , GAU.GAU_REPORT_PRINT_TEST10
                 from DOC_DOCUMENT DOC
                    , DOC_POSITION POS
                    , ASA_INVOICING_PROCESS AIP
                    , DOC_GAUGE GAU
                where POS.ASA_INTERVENTION_DETAIL_ID is not null
                  and POS.ASA_INTERVENTION_DETAIL_ID = AIP.ASA_INTERVENTION_DETAIL_ID
                  and DOC.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                  and DOC.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                  and AIP.ASA_INVOICING_JOB_ID = aInvoicingJobID
             order by DOC.DOC_GAUGE_ID;

    tplGauge    crGauge%rowtype;
    vPrintJobId DOC_PRINT_JOB.DOC_PRINT_JOB_ID%type;
  begin
    open crGauge;

    fetch crGauge
     into tplGauge;

    while crGauge%found loop
      vPrintJobId  := null;
      -- Création d'un travail d'impression par gabarit document
      DOC_BATCH_PRINT.CreateJob(aPrintJobId        => vPrintJobId
                              , aName              => PCS.PC_I_LIB_SESSION.GetUserIni || ' - ' || to_char(sysdate, 'dd.mm.yyyy hh24:mi:ss')
                              , aComment           => PCS.PC_PUBLIC.TranslateWord('Création depuis la facturation des interventions (SAV externe)')
                              , aSql               => ''
                              , aExecuted          => 0
                              , aNextExecution     => null
                              , aDiffPrinting      => 0
                              , aDiffExtraction    => 0
                              , aGroupedPrinting   => 1
                              , aUpdatePrinting    => 1
                              , aEditName0         => tplGauge.GAU_EDIT_NAME
                              , aPrinterName0      => ''   --tplGauge.PJO_PRinTER_NAME0%type
                              , aPrinterTray0      => ''   --tplGauge.PJO_PRinTER_TRAY0%type
                              , aCollateCopies0    => tplGauge.GAU_COLLATE_COPIES
                              , aCopies0           => ''   --tplGauge.PJO_COPIES0%type
                              , aSql0              => tplGauge.GAU_REPORT_PRINT_TEST
                              , aEditName1         => tplGauge.GAU_EDIT_NAME1
                              , aPrinterName1      => ''   --tplGauge.GAU_PRinTER_NAME1
                              , aPrinterTray1      => ''   --tplGauge.GAU_PRinTER_TRAY1
                              , aCollateCopies1    => tplGauge.GAU_COLLATE_COPIES1
                              , aCopies1           => ''   --tplGauge.GAU_COPIES1
                              , aSql1              => tplGauge.GAU_REPORT_PRINT_TEST1
                              , aEditName2         => tplGauge.GAU_EDIT_NAME2
                              , aPrinterName2      => ''   --tplGauge.GAU_PRinTER_NAME2
                              , aPrinterTray2      => ''   --tplGauge.GAU_PRinTER_TRAY2
                              , aCollateCopies2    => tplGauge.GAU_COLLATE_COPIES2
                              , aCopies2           => ''   --tplGauge.GAU_COPIES2
                              , aSql2              => tplGauge.GAU_REPORT_PRINT_TEST2
                              , aEditName3         => tplGauge.GAU_EDIT_NAME3
                              , aPrinterName3      => ''   --tplGauge.GAU_PRinTER_NAME3
                              , aPrinterTray3      => ''   --tplGauge.GAU_PRinTER_TRAY3
                              , aCollateCopies3    => tplGauge.GAU_COLLATE_COPIES3
                              , aCopies3           => ''   --tplGauge.GAU_COPIES3
                              , aSql3              => tplGauge.GAU_REPORT_PRINT_TEST3
                              , aEditName4         => tplGauge.GAU_EDIT_NAME4
                              , aPrinterName4      => ''   --tplGauge.GAU_PRinTER_NAME4
                              , aPrinterTray4      => ''   --tplGauge.GAU_PRinTER_TRAY4
                              , aCollateCopies4    => tplGauge.GAU_COLLATE_COPIES4
                              , aCopies4           => ''   --tplGauge.GAU_COPIES4
                              , aSql4              => tplGauge.GAU_REPORT_PRINT_TEST4
                              , aEditName5         => tplGauge.GAU_EDIT_NAME5
                              , aPrinterName5      => ''   --tplGauge.GAU_PRinTER_NAME5
                              , aPrinterTray5      => ''   --tplGauge.GAU_PRinTER_TRAY5
                              , aCollateCopies5    => tplGauge.GAU_COLLATE_COPIES5
                              , aCopies5           => ''   --tplGauge.GAU_COPIES5
                              , aSql5              => tplGauge.GAU_REPORT_PRINT_TEST5
                              , aEditName6         => tplGauge.GAU_EDIT_NAME6
                              , aPrinterName6      => ''   --tplGauge.GAU_PRinTER_NAME6
                              , aPrinterTray6      => ''   --tplGauge.GAU_PRinTER_TRAY6
                              , aCollateCopies6    => tplGauge.GAU_COLLATE_COPIES6
                              , aCopies6           => ''   --tplGauge.GAU_COPIES6
                              , aSql6              => tplGauge.GAU_REPORT_PRINT_TEST6
                              , aEditName7         => tplGauge.GAU_EDIT_NAME7
                              , aPrinterName7      => ''   --tplGauge.GAU_PRinTER_NAME7
                              , aPrinterTray7      => ''   --tplGauge.GAU_PRinTER_TRAY7
                              , aCollateCopies7    => tplGauge.GAU_COLLATE_COPIES7
                              , aCopies7           => ''   --tplGauge.GAU_COPIES7
                              , aSql7              => tplGauge.GAU_REPORT_PRINT_TEST7
                              , aEditName8         => tplGauge.GAU_EDIT_NAME8
                              , aPrinterName8      => ''   --tplGauge.GAU_PRinTER_NAME8
                              , aPrinterTray8      => ''   --tplGauge.GAU_PRinTER_TRAY8
                              , aCollateCopies8    => tplGauge.GAU_COLLATE_COPIES8
                              , aCopies8           => ''   --tplGauge.GAU_COPIES8
                              , aSql8              => tplGauge.GAU_REPORT_PRINT_TEST8
                              , aEditName9         => tplGauge.GAU_EDIT_NAME9
                              , aPrinterName9      => ''   --tplGauge.GAU_PRinTER_NAME9
                              , aPrinterTray9      => ''   --tplGauge.GAU_PRinTER_TRAY9
                              , aCollateCopies9    => tplGauge.GAU_COLLATE_COPIES9
                              , aCopies9           => ''   --tplGauge.GAU_COPIES9
                              , aSql9              => tplGauge.GAU_REPORT_PRINT_TEST9
                              , aEditName10        => tplGauge.GAU_EDIT_NAME10
                              , aPrinterName10     => ''   --tplGauge.GAU_PRinTER_NAME10
                              , aPrinterTray10     => ''   --tplGauge.GAU_PRinTER_TRAY10
                              , aCollateCopies10   => tplGauge.GAU_COLLATE_COPIES10
                              , aCopies10          => ''   --tplGauge.GAU_COPIES10
                              , aSql10             => tplGauge.GAU_REPORT_PRINT_TEST10
                               );

      -- Récupération des ID de tous les documents à imprimer
      for tplDoc in (select distinct DOC.DOC_DOCUMENT_ID
                                from DOC_DOCUMENT DOC
                                   , DOC_POSITION POS
                                   , ASA_INVOICING_PROCESS AIP
                               where POS.ASA_INTERVENTION_DETAIL_ID = AIP.ASA_INTERVENTION_DETAIL_ID
                                 and DOC.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                                 and AIP.ASA_INVOICING_JOB_ID = aInvoicingJobID
                                 and DOC.DOC_GAUGE_ID = tplGauge.DOC_GAUGE_ID
                            order by DOC.DOC_DOCUMENT_ID) loop
        DOC_BATCH_PRINT.InsertDocIntoJobDetail(paPrintJobId => vPrintJobId, paDocId => tplDoc.DOC_DOCUMENT_ID, aSqlControl => 1);
      end loop;

      -- Gabarit suivant
      fetch crGauge
       into tplGauge;
    end loop;
  end GeneratePrintJob;

/*--------------------------------------------------------------------------------------------------------------------*/
    /**
  * procedure UpdateInvProcess
  * Description
  *    Màj de la proposition avec le n° de document et position générés
  */
  procedure UpdateInvProcess(aInvProcessID in number, aDocumentID in number, aPositionID in number)
  is
  begin
    update ASA_INVOICING_PROCESS
       set DOC_DOCUMENT_ID = aDocumentID
         , DOC_POSITION_ID = aPositionID
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where ASA_INVOICING_PROCESS_ID = aInvProcessID;
  end UpdateInvProcess;

/*--------------------------------------------------------------------------------------------------------------------*/
/*
  * Description
  *    Terminer le travail de facturation
*/
  function CompleteInvoicingJob(aJobID in number)
    return number
  is
    ErrorCode varchar2(3);
    ErrorText varchar2(32000);
    vResult   number(1)       default 1;
  begin
    for tplDoc in (select distinct DMT.DOC_DOCUMENT_ID
                              from DOC_DOCUMENT DMT
                                 , ASA_INVOICING_PROCESS AIP
                             where AIP.ASA_INVOICING_JOB_ID = aJobID
                               and AIP.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                               and DMT.C_DOCUMENT_STATUS = '01') loop
      begin
        ErrorCode  := null;
        ErrorText  := null;
        DOC_DOCUMENT_FUNCTIONS.ConfirmDocument(tplDoc.DOC_DOCUMENT_ID, ErrorCode, ErrorText, 1);
        commit;

        -- Màj la table contenant le résultat de la décharge en indiquant que ce document a été confirmé
        if    ErrorCode is not null
           or ErrorText is not null then
          vResult  := 0;
        end if;
      exception
        when others then
          vResult  := 0;
      end;
    end loop;

    -- Terminer le travail de facturation si l'on a pu confirmer tous les docs
    if vResult = 1 then
      -- Déprotéger les positions
      for tplPos in (select distinct ASA_MISSION_ID
                                from ASA_INVOICING_PROCESS
                               where ASA_INVOICING_JOB_ID = aJobID) loop
        -- Déprotéction de la position
        ASA_MISSION_FUNCTIONS.ProtectMission(tplPos.ASA_MISSION_ID, 0);
      end loop;

      -- Terminer le travail
      update ASA_INVOICING_JOB
         set C_ASA_INVOICING_JOB_STATUS = '3'
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where ASA_INVOICING_JOB_ID = aJobID;
    end if;

    return vResult;
  end CompleteInvoicingJob;
end ASA_INTERVENTION_INVOICING;
