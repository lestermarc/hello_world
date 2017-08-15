--------------------------------------------------------
--  DDL for Package Body CML_INVOICING_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "CML_INVOICING_FUNCTIONS" 
is
  /**
  * procedure GenerateInvoicing
  * Description
  *    Génération des factures des contrats de maintenance à partir du job
  */
  procedure GenerateInvoicing(aJobID in number)
  is
    cursor crInvDocument
    is
      select   INP_REGROUP_ID
             , min(CML_INVOICING_PROCESS_ID) CML_INVOICING_PROCESS_ID
             , sum(nvl(INP_AMOUNT, 0) ) INP_TOTAL_AMOUNT
             , max(PAC_CUSTOM_PARTNER_ID) PAC_CUSTOM_PARTNER_ID
             , max(PAC_PAYMENT_CONDITION_ID) PAC_PAYMENT_CONDITION_ID
             , max(ACS_FINANCIAL_CURRENCY_ID) ACS_FINANCIAL_CURRENCY_ID
          from CML_INVOICING_PROCESS
         where CML_INVOICING_JOB_ID = aJobID
           and INP_SELECTION = 1
           and DOC_POSITION_ID is null
      group by INP_REGROUP_ID
      order by INP_REGROUP_ID;

    tplInvDocument   crInvDocument%rowtype;
    vClob            clob;
    vExtractParams   CML_INVOICING_PREPARATION.TExtractParamsInfo;
    vGaugeID         DOC_GAUGE.DOC_GAUGE_ID%type;
    vDOC_ID          DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    vDocType         varchar2(30);
    vErrorMsg        varchar2(4000);
    blnGenDoc        boolean;
    vLinkedEvents    integer;
    vEventsCount     integer;
    lPositionProtect number;
  begin
    -- Déprotéger les positions appartenant à des propositions qui n'ont pas été sélectionnées
    for tplUnselectPos in (select distinct CML_POSITION_ID
                                      from CML_INVOICING_PROCESS
                                     where CML_INVOICING_JOB_ID = aJobID
                                       and INP_SELECTION = 0
                                       and DOC_POSITION_ID is null
                                       and CML_POSITION_ID not in(select distinct CML_POSITION_ID
                                                                             from CML_INVOICING_PROCESS
                                                                            where CML_INVOICING_JOB_ID = aJobID
                                                                              and INP_SELECTION = 1) ) loop
      -- Déprotéction de la position
      CML_CONTRACT_FUNCTIONS.PositionProtect_AutoTrans(iPositionId   => tplUnselectPos.CML_POSITION_ID
                                                     , iProtect      => 0
                                                     , iSessionId    => DBMS_SESSION.unique_session_id
                                                     , iShowError    => 0
                                                     , oUpdated      => lPositionProtect
                                                      );
    end loop;

    -- Effacer les propositions qui n'ont pas été sélectionnées
    delete      CML_INVOICING_PROCESS
          where CML_INVOICING_JOB_ID = aJobID
            and INP_SELECTION = 0
            and DOC_POSITION_ID is null;

    -- Récupérer les paramètres de l'extraction du job
    select INJ_EXTRACT_PARAMS
      into vClob
      from CML_INVOICING_JOB
     where CML_INVOICING_JOB_ID = aJobID;

    vExtractParams  := CML_INVOICING_PREPARATION.GetExtractParamsInfo(vClob);

    open crInvDocument;

    fetch crInvDocument
     into tplInvDocument;

    while crInvDocument%found loop
      blnGenDoc  := true;

      -- Si le montant à facturer est inférieur à 0 -> Note de crédit
      -- Sinon -> Facture
      if tplInvDocument.INP_TOTAL_AMOUNT < 0 then
        vGaugeID  := vExtractParams.INJ_CREDIT_NOTE_GAUGE_ID;
        vDocType  := 'CREDIT_NOTE';
      else
        vGaugeID  := vExtractParams.INJ_INVOICE_GAUGE_ID;
        vDocType  := 'INVOICE';

        -- Montant minimum de facturation est dépassé
        -- Ne pas tenir compte du montant min si facture finale  OU
        --   Il y a des evenements de type 5 à facturer et ont se trouve dans une période de fact. obligatoire
        if     (nvl(vExtractParams.INJ_MIN_INVOICE_AMOUNT, 0) <> 0)
           and (nvl(vExtractParams.INJ_MIN_INVOICE_AMOUNT, 0) > tplInvDocument.INP_TOTAL_AMOUNT)
           and (nvl(vExtractParams.INJ_LAST_INVOICE, 0) = 0) then
          -- Vérifier s'il y a des événements de type 5 dont le mois de la date
          -- d'extraction correspond au mois de facturation d'un code 300
          select count(INP.CML_EVENTS_ID)
            into vEventsCount
            from CML_INVOICING_PROCESS INP
               , CML_EVENTS CEV
           where INP.CML_INVOICING_JOB_ID = aJobID
             and INP.INP_REGROUP_ID = tplInvDocument.INP_REGROUP_ID
             and INP.CML_EVENTS_ID = CEV.CML_EVENTS_ID
             and CEV.C_CML_EVENT_TYPE = '5'
             and CEV.CML_POS_SERV_DET_HISTORY_ID is not null;

          -- Montants min dépassé ET
          -- pas d'evenements de type 5 à facturer qui ont effectué un
          -- renouvellement des avoirs
          -- Alors ne pas facturer
          if (vEventsCount = 0) then
            blnGenDoc  := false;

            -- Màj des propositions en indiquant qu'elles n'ont pas respecté le
            -- montant minimum
            update CML_INVOICING_PROCESS
               set A_RECSTATUS = -100
             where CML_INVOICING_JOB_ID = aJobID
               and INP_REGROUP_ID = tplInvDocument.INP_REGROUP_ID;
          end if;
        end if;
      end if;

      vDOC_ID    := null;

      -- Montant minimum de facturation respecté
      if blnGenDoc then
        -- Init spécial des dates
        if    (vExtractParams.INJ_DOCUMENT_DATE <> vExtractParams.INJ_DATE_DELIVERY)
           or (vExtractParams.INJ_DOCUMENT_DATE <> vExtractParams.INJ_DATE_VALUE) then
          DOC_DOCUMENT_GENERATE.ResetDocumentInfo(DOC_DOCUMENT_INITIALIZE.DocumentInfo);
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.CLEAR_DOCUMENT_INFO    := 0;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_DELIVERY  := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_DELIVERY      := vExtractParams.INJ_DATE_DELIVERY;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_DATE_VALUE     := 1;
          DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_DATE_VALUE         := vExtractParams.INJ_DATE_VALUE;
        end if;

        -- Création du document
        DOC_DOCUMENT_GENERATE.GenerateDocument(aNewDocumentID   => vDOC_ID
                                             , aGaugeID         => vGaugeID
                                             , aMode            => '165'
                                             , aSrcDocumentID   => tplInvDocument.CML_INVOICING_PROCESS_ID
                                             , aDocDate         => vExtractParams.INJ_DOCUMENT_DATE
                                              );

        -- Liste des positions à créer
        for tplProcess in crProcess(aJobID, tplInvDocument.INP_REGROUP_ID, vDOC_ID, vDocType, vExtractParams.INJ_EXTRACTION_DATE) loop
          -- FACTURATION : Forfaits
          if tplProcess.C_INVOICING_PROCESS_TYPE = 'FIXEDPRICE' then
            GenFixedPricePositions(tplProcess);
          -- FACTURATION : Dépôts
          elsif tplProcess.C_INVOICING_PROCESS_TYPE = 'DEPOSIT' then
            GenDepositPenalityPositions(tplProcess);
          -- FACTURATION : Pénalités
          elsif tplProcess.C_INVOICING_PROCESS_TYPE = 'PENALITY' then
            GenDepositPenalityPositions(tplProcess);
          -- FACTURATION : Evénements
          elsif tplProcess.C_INVOICING_PROCESS_TYPE = 'EVENTS' then
            -- FACTURATION : Evénements prestation type <> '5'
            if tplProcess.C_CML_EVENT_TYPE <> '5' then
              GenOtherEventsPositions(tplProcess);
            else
              -- Vérifier s'il y a des événements liés
              select count(CML_INVOICING_PROCESS_ID)
                into vLinkedEvents
                from CML_INVOICING_PROCESS
               where CML_INVOICING_JOB_ID = aJobID
                 and INP_REGROUP_ID = tplProcess.INP_REGROUP_ID
                 and CML_CML_EVENTS_ID = tplProcess.CML_EVENTS_ID;

              -- FACTURATION : Evénements prestation type '5' avec événement lié
              if vLinkedEvents > 0 then
                GenLinkedEventsPositions(tplProcess);
              else
                -- FACTURATION : Evénements prestation type '5' sans événement lié
                GenUnLinkedEventsPositions(tplProcess);
              end if;
            end if;
          end if;
        end loop;

        -- Màj les derniers élements du document (statut, montants, etc.)
        DOC_FINALIZE.FinalizeDocument(vDOC_ID, 1, 1, 1);
        commit;
      end if;

      -- Document à créer suivant
      fetch crInvDocument
       into tplInvDocument;
    end loop;

    close crInvDocument;

    -- Statut du job de facturation -> En cours de facturation
    update CML_INVOICING_JOB
       set C_CML_INVOICING_JOB_STATUS = '2'
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where CML_INVOICING_JOB_ID = aJobID;
  end GenerateInvoicing;

  /**
  * procedure GenUnLinkedEventsPositions
  * Description
  *    Génération des positions (DOC_POSITION) à partir des propositions
  *      de type événement '5'(Excédents de consom.)
  *      mais qui n'ont pas d'événement lié
  */
  procedure GenUnLinkedEventsPositions(aProcess in crProcess%rowtype)
  is
    cursor crPriceStruct(cServiceDetailID in CML_POSITION_SERVICE_DETAIL.CML_POSITION_SERVICE_DETAIL_ID%type)
    is
      select   GCO_GOOD_ID
             , PST_WEIGHT
          from CML_PRICE_STRUCTURE
         where CML_POSITION_SERVICE_DETAIL_ID = cServiceDetailID
      order by CML_PRICE_STRUCTURE_ID;

    cursor crDescr
    is
      select DES.DES_SHORT_DESCRIPTION
           , CPS.CPS_LONG_DESCRIPTION
           , CPS.CPS_FREE_DESCRIPTION
           , RCO.RCO_MACHINE_FREE_DESCR
           , RCO.DOC_RECORD_ID
        from CML_EVENTS CEV
           , CML_POSITION_SERVICE CPS
           , CML_POSITION_SERVICE_DETAIL CPD
           , CML_POSITION_MACHINE CPM
           , CML_POSITION_MACHINE_DETAIL CMD
           , DOC_RECORD RCO
           , GCO_DESCRIPTION DES
       where CEV.CML_EVENTS_ID = aProcess.CML_EVENTS_ID
         and CEV.CML_POSITION_SERVICE_DETAIL_ID = CPD.CML_POSITION_SERVICE_DETAIL_ID
         and CPD.CML_POSITION_SERVICE_ID = CPS.CML_POSITION_SERVICE_ID
         and CEV.CML_POSITION_MACHINE_DETAIL_ID = CMD.CML_POSITION_MACHINE_DETAIL_ID(+)
         and CMD.CML_POSITION_MACHINE_ID = CPM.CML_POSITION_MACHINE_ID(+)
         and CPM.DOC_RCO_MACHINE_ID = RCO.DOC_RECORD_ID(+)
         and CEV.GCO_GOOD_ID = DES.GCO_GOOD_ID(+)
         and DES.PC_LANG_ID = aProcess.PC_LANG_ID
         and DES.C_DESCRIPTION_TYPE(+) = '01';

    tplPriceStruct crPriceStruct%rowtype;
    tplDescr       crDescr%rowtype;
    vPOS_ID        DOC_POSITION.DOC_POSITION_ID%type;
    vPOS_CPT_ID    DOC_POSITION.DOC_POSITION_ID%type;
    vDET_ID        DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    vDetailInfo    DOC_DETAIL_INITIALIZE.TDetailInfo;
    vQty           DOC_POSITION.POS_BASIS_QUANTITY%type;
    vUtilCoeff     DOC_POSITION.POS_UTIL_COEFF%type;
    vSumPstWeight  CML_PRICE_STRUCTURE.PST_WEIGHT%type;
  begin
    open crDescr;

    fetch crDescr
     into tplDescr;

    close crDescr;

    open crPriceStruct(aProcess.CML_POSITION_SERVICE_DETAIL_ID);

    fetch crPriceStruct
     into tplPriceStruct;

    -- Structure de ventilation = OUI
    if crPriceStruct%found then
      -- Init de certaines données de la position
      vPOS_ID                                                         := null;
      DOC_POSITION_GENERATE.ResetPositionInfo(DOC_POSITION_INITIALIZE.PositionInfo);
      DOC_POSITION_INITIALIZE.PositionInfo.CLEAR_POSITION_INFO        := 0;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_CML_POSITION_ID        := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.CML_POSITION_ID            := aProcess.CML_POSITION_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_CML_EVENTS_ID          := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.CML_EVENTS_ID              := aProcess.CML_EVENTS_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_SHORT_DESCRIPTION  := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_SHORT_DESCRIPTION      := tplDescr.DES_SHORT_DESCRIPTION;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_LONG_DESCRIPTION   := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_LONG_DESCRIPTION       := tplDescr.CPS_LONG_DESCRIPTION;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_FREE_DESCRIPTION   := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_FREE_DESCRIPTION       := tplDescr.CPS_FREE_DESCRIPTION;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BODY_TEXT          := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_BODY_TEXT              := tplDescr.RCO_MACHINE_FREE_DESCR;
      -- Création de la position
      DOC_POSITION_GENERATE.GeneratePosition(aPositionID       => vPOS_ID
                                           , aDocumentID       => aProcess.DOC_DOCUMENT_ID
                                           , aPosCreateMode    => '165'
                                           , aTypePos          => '9'
                                           , aGoodID           => aProcess.CEV_GCO_GOOD_ID
                                           , aRecordID         => aProcess.DOC_RECORD_ID
                                           , aBasisQuantity    => aProcess.INP_INVOICING_QTY
                                           , aGoodPrice        => 0
                                           , aGenerateDetail   => 1
                                            );
      -- Màj de la proposition avec le n° de document et la position générés
      UpdateInvProcess(aProcess.CML_INVOICING_PROCESS_ID, aProcess.DOC_DOCUMENT_ID, vPOS_ID);

      if vPOS_ID is not null then
        -- Somme des pondération de la structure de ventilation
        select   sum(PST_WEIGHT)
            into vSumPstWeight
            from CML_PRICE_STRUCTURE
           where CML_POSITION_SERVICE_DETAIL_ID = aProcess.CML_POSITION_SERVICE_DETAIL_ID
        order by CML_PRICE_STRUCTURE_ID;

        while crPriceStruct%found loop
          -- Init de certaines données de la position
          vPOS_CPT_ID                                               := null;
          DOC_POSITION_GENERATE.ResetPositionInfo(DOC_POSITION_INITIALIZE.PositionInfo);
          DOC_POSITION_INITIALIZE.PositionInfo.CLEAR_POSITION_INFO  := 0;
          DOC_POSITION_INITIALIZE.PositionInfo.USE_CML_POSITION_ID  := 1;
          DOC_POSITION_INITIALIZE.PositionInfo.CML_POSITION_ID      := aProcess.CML_POSITION_ID;
          DOC_POSITION_INITIALIZE.PositionInfo.USE_CML_EVENTS_ID    := 1;
          DOC_POSITION_INITIALIZE.PositionInfo.CML_EVENTS_ID        := aProcess.CML_EVENTS_ID;
          -- Coefficient d'utilisation du composant
          vUtilCoeff                                                := tplPriceStruct.PST_WEIGHT / vSumPstWeight;
          vQty                                                      := vUtilCoeff * aProcess.INP_INVOICING_QTY;
          DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_UTIL_COEFF   := 1;
          DOC_POSITION_INITIALIZE.PositionInfo.POS_UTIL_COEFF       := vUtilCoeff;
          -- Création de la position
          DOC_POSITION_GENERATE.GeneratePosition(aPositionID       => vPOS_CPT_ID
                                               , aDocumentID       => aProcess.DOC_DOCUMENT_ID
                                               , aPosCreateMode    => '165'
                                               , aTypePos          => '91'
                                               , aPTPositionID     => vPOS_ID
                                               , aGoodID           => tplPriceStruct.GCO_GOOD_ID
                                               , aRecordID         => aProcess.DOC_RECORD_ID
                                               , aBasisQuantity    => vQty
                                               , aGoodPrice        => aProcess.CEV_UNIT_SALE_PRICE
                                               , aGenerateDetail   => 1
                                                );
          -- Màj de CML_GEN_DOC avec la nouvelle position crée
          CML_CONTRACT_GENERATE_DOC.UpdateCML_GEN_DOC(aCML_POSITION_ID             => aProcess.CML_POSITION_ID
                                                    , aCML_EVENTS_ID               => aProcess.CML_EVENTS_ID
                                                    , aDOC_POSITION_ID             => vPOS_CPT_ID
                                                    , aDateDoc                     => aProcess.DMT_DATE_DOCUMENT
                                                    , aExtractionType              => aProcess.CGD_EXTRACTION_TYPE
                                                    , aValue                       => (aProcess.CEV_UNIT_SALE_PRICE * vQty)
                                                    , aACS_FINANCIAL_CURRENCY_ID   => aProcess.ACS_FINANCIAL_CURRENCY_ID
                                                    , aDateDe                      => null
                                                    , aDateA                       => null
                                                    , FMultiply                    => aProcess.CGD_MULTIPLY
                                                    , FNewIndiceDate               => aProcess.INP_INDICE_V_DATE
                                                    , FNewIndiceVariable           => aProcess.INP_INDICE_VARIABLE
                                                     );

          fetch crPriceStruct
           into tplPriceStruct;
        end loop;
      end if;
    else
      -- Structure de ventilation = NON
      -- Init de certaines données de la position
      vPOS_ID                                                         := null;
      DOC_POSITION_GENERATE.ResetPositionInfo(DOC_POSITION_INITIALIZE.PositionInfo);
      DOC_POSITION_INITIALIZE.PositionInfo.CLEAR_POSITION_INFO        := 0;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_CML_POSITION_ID        := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.CML_POSITION_ID            := aProcess.CML_POSITION_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_CML_EVENTS_ID          := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.CML_EVENTS_ID              := aProcess.CML_EVENTS_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_SHORT_DESCRIPTION  := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_SHORT_DESCRIPTION      := tplDescr.DES_SHORT_DESCRIPTION;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_LONG_DESCRIPTION   := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_LONG_DESCRIPTION       := tplDescr.CPS_LONG_DESCRIPTION;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_FREE_DESCRIPTION   := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_FREE_DESCRIPTION       := tplDescr.CPS_FREE_DESCRIPTION;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BODY_TEXT          := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_BODY_TEXT              := tplDescr.RCO_MACHINE_FREE_DESCR;
      -- Création de la position
      DOC_POSITION_GENERATE.GeneratePosition(aPositionID       => vPOS_ID
                                           , aDocumentID       => aProcess.DOC_DOCUMENT_ID
                                           , aPosCreateMode    => '165'
                                           , aTypePos          => '1'
                                           , aGoodID           => aProcess.CEV_GCO_GOOD_ID
                                           , aRecordID         => aProcess.DOC_RECORD_ID
                                           , aBasisQuantity    => aProcess.INP_INVOICING_QTY
                                           , aGoodPrice        => aProcess.CEV_UNIT_SALE_PRICE
                                           , aUnitCostPrice    => aProcess.CEV_UNIT_COST_PRICE
                                           , aGenerateDetail   => 0
                                            );
      -- Màj de la proposition avec le n° de document et la position générés
      UpdateInvProcess(aProcess.CML_INVOICING_PROCESS_ID, aProcess.DOC_DOCUMENT_ID, vPOS_ID);
      -- Màj de CML_GEN_DOC avec la nouvelle position crée
      CML_CONTRACT_GENERATE_DOC.UpdateCML_GEN_DOC(aCML_POSITION_ID             => aProcess.CML_POSITION_ID
                                                , aCML_EVENTS_ID               => aProcess.CML_EVENTS_ID
                                                , aDOC_POSITION_ID             => vPOS_ID
                                                , aDateDoc                     => aProcess.DMT_DATE_DOCUMENT
                                                , aExtractionType              => aProcess.CGD_EXTRACTION_TYPE
                                                , aValue                       => (aProcess.CEV_UNIT_SALE_PRICE * aProcess.INP_INVOICING_QTY)
                                                , aACS_FINANCIAL_CURRENCY_ID   => aProcess.ACS_FINANCIAL_CURRENCY_ID
                                                , aDateDe                      => null
                                                , aDateA                       => null
                                                , FMultiply                    => aProcess.CGD_MULTIPLY
                                                , FNewIndiceDate               => aProcess.INP_INDICE_V_DATE
                                                , FNewIndiceVariable           => aProcess.INP_INDICE_VARIABLE
                                                 );
      -- Init de certaines données de la position
      vDET_ID                                                         := null;
      -- Effacement données
      DOC_DETAIL_INITIALIZE.DetailsInfo(1)                            := vDetailInfo;
      DOC_DETAIL_INITIALIZE.DetailsInfo(1).CLEAR_DETAIL_INFO          := 0;
      DOC_DETAIL_INITIALIZE.DetailsInfo(1).USE_CML_EVENTS_ID          := 1;
      DOC_DETAIL_INITIALIZE.DetailsInfo(1).CML_EVENTS_ID              := aProcess.CML_EVENTS_ID;
      DOC_DETAIL_INITIALIZE.DetailsInfo(1).USE_DOC_RECORD_ID          := 1;
      DOC_DETAIL_INITIALIZE.DetailsInfo(1).DOC_RECORD_ID              := tplDescr.DOC_RECORD_ID;
      -- Création du détail
      DOC_DETAIL_GENERATE.GenerateDetail(aDetailID => vDET_ID, aPositionID => vPOS_ID, aPdeCreateMode => '165', aQuantity => aProcess.INP_INVOICING_QTY);
    end if;

    -- Màj de l'événement qui vient d'être facturé
    update CML_EVENTS
       set DOC_POSITION_ID = vPOS_ID
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where CML_EVENTS_ID = aProcess.CML_EVENTS_ID;

    close crPriceStruct;
  end GenUnLinkedEventsPositions;

  /**
  * procedure GenLinkedEventsPositions
  * Description
  *    Génération des positions (DOC_POSITION) à partir des propositions
  *      de type événement '5'(Excédents de consom.) qui ont un événement lié
  */
  procedure GenLinkedEventsPositions(aProcess in crProcess%rowtype)
  is
    cursor crPriceStruct(cServiceDetailID in CML_POSITION_SERVICE_DETAIL.CML_POSITION_SERVICE_DETAIL_ID%type)
    is
      select   GCO_GOOD_ID
             , PST_WEIGHT
          from CML_PRICE_STRUCTURE
         where CML_POSITION_SERVICE_DETAIL_ID = cServiceDetailID
      order by CML_PRICE_STRUCTURE_ID;

    cursor crLinkedEvents(cInvoicingJobID in number, cRegroupID in number, cEventID in number)
    is
      select   INP.CML_INVOICING_PROCESS_ID
             , INP.CML_POSITION_ID
             , INP.CML_EVENTS_ID
             , INP.INP_INVOICING_QTY
             , INP.INP_AMOUNT
             , CPM.DOC_RCO_MACHINE_ID
          from CML_INVOICING_PROCESS INP
             , CML_EVENTS CEV
             , CML_POSITION_MACHINE CPM
             , CML_POSITION_MACHINE_DETAIL CMD
         where INP.CML_INVOICING_JOB_ID = cInvoicingJobID
           and INP.INP_REGROUP_ID = cRegroupID
           and INP.C_INVOICING_PROCESS_TYPE = 'EVENTS'
           and INP.CML_CML_EVENTS_ID = cEventID
           and INP.CML_EVENTS_ID = CEV.CML_EVENTS_ID
           and CEV.CML_POSITION_MACHINE_DETAIL_ID = CMD.CML_POSITION_MACHINE_DETAIL_ID
           and CMD.CML_POSITION_MACHINE_ID = CPM.CML_POSITION_MACHINE_ID
      order by INP.INP_ORDER_BY;

    cursor crDescr
    is
      select DES.DES_SHORT_DESCRIPTION
           , CPS.CPS_LONG_DESCRIPTION
           , CPS.CPS_FREE_DESCRIPTION
           , RCO.RCO_MACHINE_FREE_DESCR
           , RCO.DOC_RECORD_ID
           , CPD.CML_POSITION_SERVICE_DETAIL_ID
        from CML_EVENTS CEV
           , CML_POSITION_SERVICE CPS
           , CML_POSITION_SERVICE_DETAIL CPD
           , CML_POSITION_MACHINE CPM
           , CML_POSITION_MACHINE_DETAIL CMD
           , DOC_RECORD RCO
           , GCO_DESCRIPTION DES
       where CEV.CML_EVENTS_ID = aProcess.CML_EVENTS_ID
         and CEV.CML_POSITION_SERVICE_DETAIL_ID = CPD.CML_POSITION_SERVICE_DETAIL_ID
         and CPD.CML_POSITION_SERVICE_ID = CPS.CML_POSITION_SERVICE_ID
         and CEV.CML_POSITION_MACHINE_DETAIL_ID = CMD.CML_POSITION_MACHINE_DETAIL_ID(+)
         and CMD.CML_POSITION_MACHINE_ID = CPM.CML_POSITION_MACHINE_ID(+)
         and CPM.DOC_RCO_MACHINE_ID = RCO.DOC_RECORD_ID(+)
         and CEV.GCO_GOOD_ID = DES.GCO_GOOD_ID(+)
         and DES.PC_LANG_ID = aProcess.PC_LANG_ID
         and DES.C_DESCRIPTION_TYPE(+) = '01';

    tplPriceStruct  crPriceStruct%rowtype;
    tplLinkedEvents crLinkedEvents%rowtype;
    tplDescr        crDescr%rowtype;
    --
    vQty            DOC_POSITION.POS_BASIS_QUANTITY%type;
    vUtilCoeff      DOC_POSITION.POS_UTIL_COEFF%type;
    vSumPstWeight   CML_PRICE_STRUCTURE.PST_WEIGHT%type;
    vPOS_ID         DOC_POSITION.DOC_POSITION_ID%type;
    vPOS_CPT_ID     DOC_POSITION.DOC_POSITION_ID%type;
    vDET_ID         DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    vDetailInfo     DOC_DETAIL_INITIALIZE.TDetailInfo;
  begin
    open crDescr;

    fetch crDescr
     into tplDescr;

    close crDescr;

    open crPriceStruct(aProcess.CML_POSITION_SERVICE_DETAIL_ID);

    fetch crPriceStruct
     into tplPriceStruct;

    -- Structure de ventilation = OUI
    if crPriceStruct%found then
      -- Init données position
      vPOS_ID                                                         := null;
      DOC_POSITION_GENERATE.ResetPositionInfo(DOC_POSITION_INITIALIZE.PositionInfo);
      DOC_POSITION_INITIALIZE.PositionInfo.CLEAR_POSITION_INFO        := 0;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_CML_POSITION_ID        := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.CML_POSITION_ID            := aProcess.CML_POSITION_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_CML_EVENTS_ID          := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.CML_EVENTS_ID              := aProcess.CML_EVENTS_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_SHORT_DESCRIPTION  := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_SHORT_DESCRIPTION      := tplDescr.DES_SHORT_DESCRIPTION;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_LONG_DESCRIPTION   := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_LONG_DESCRIPTION       := tplDescr.CPS_LONG_DESCRIPTION;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_FREE_DESCRIPTION   := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_FREE_DESCRIPTION       := tplDescr.CPS_FREE_DESCRIPTION;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BODY_TEXT          := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_BODY_TEXT              := tplDescr.RCO_MACHINE_FREE_DESCR;
      -- Création de la position
      DOC_POSITION_GENERATE.GeneratePosition(aPositionID       => vPOS_ID
                                           , aDocumentID       => aProcess.DOC_DOCUMENT_ID
                                           , aPosCreateMode    => '165'
                                           , aTypePos          => '9'
                                           , aGoodID           => aProcess.INP_GCO_GOOD_ID
                                           , aRecordID         => aProcess.DOC_RECORD_ID
                                           , aBasisQuantity    => aProcess.INP_INVOICING_QTY
                                           , aGoodPrice        => 0
                                           , aGenerateDetail   => 0
                                            );
      -- Màj de la proposition avec le n° de document et la position générés
      UpdateInvProcess(aProcess.CML_INVOICING_PROCESS_ID, aProcess.DOC_DOCUMENT_ID, vPOS_ID);

      open crLinkedEvents(aProcess.CML_INVOICING_JOB_ID, aProcess.INP_REGROUP_ID, aProcess.CML_EVENTS_ID);

      fetch crLinkedEvents
       into tplLinkedEvents;

      -- Création d'un détail pour chaque événement lié
      while crLinkedEvents%found loop
        -- Init de certaines données de la position
        vDET_ID                                                 := null;
        -- Effacement données
        DOC_DETAIL_INITIALIZE.DetailsInfo(1)                    := vDetailInfo;
        DOC_DETAIL_INITIALIZE.DetailsInfo(1).CLEAR_DETAIL_INFO  := 0;
        DOC_DETAIL_INITIALIZE.DetailsInfo(1).USE_CML_EVENTS_ID  := 1;
        DOC_DETAIL_INITIALIZE.DetailsInfo(1).CML_EVENTS_ID      := tplLinkedEvents.CML_EVENTS_ID;
        DOC_DETAIL_INITIALIZE.DetailsInfo(1).USE_DOC_RECORD_ID  := 1;
        DOC_DETAIL_INITIALIZE.DetailsInfo(1).DOC_RECORD_ID      := tplLinkedEvents.DOC_RCO_MACHINE_ID;
        -- Création du détail
        DOC_DETAIL_GENERATE.GenerateDetail(aDetailID        => vDET_ID
                                         , aPositionID      => vPOS_ID
                                         , aPdeCreateMode   => '165'
                                         , aQuantity        => tplLinkedEvents.INP_INVOICING_QTY
                                          );

        -- Màj de l'événement qui vient d'être facturé
        update CML_EVENTS
           set DOC_POSITION_ID = vPOS_ID
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where CML_EVENTS_ID = tplLinkedEvents.CML_EVENTS_ID;

        fetch crLinkedEvents
         into tplLinkedEvents;
      end loop;

      close crLinkedEvents;

      -- Somme des pondération de la structure de ventilation
      select sum(PST_WEIGHT)
        into vSumPstWeight
        from CML_PRICE_STRUCTURE
       where CML_POSITION_SERVICE_DETAIL_ID = aProcess.CML_POSITION_SERVICE_DETAIL_ID;

      while crPriceStruct%found loop
        -- Coeff d'utilisation de la position CPT
        vUtilCoeff                                                     := tplPriceStruct.PST_WEIGHT / vSumPstWeight;
        vQty                                                           := vUtilCoeff * aProcess.INP_INVOICING_QTY;
        -- Init de certaines données de la position
        vPOS_CPT_ID                                                    := null;
        DOC_POSITION_GENERATE.ResetPositionInfo(DOC_POSITION_INITIALIZE.PositionInfo);
        DOC_POSITION_INITIALIZE.PositionInfo.CLEAR_POSITION_INFO       := 0;
        DOC_POSITION_INITIALIZE.PositionInfo.USE_CML_POSITION_ID       := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.CML_POSITION_ID           := aProcess.CML_POSITION_ID;
        DOC_POSITION_INITIALIZE.PositionInfo.USE_CML_EVENTS_ID         := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.CML_EVENTS_ID             := aProcess.CML_EVENTS_ID;
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_LONG_DESCRIPTION  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_LONG_DESCRIPTION      := tplDescr.CPS_LONG_DESCRIPTION;
        -- Coefficient d'utilisation du composant
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_UTIL_COEFF        := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_UTIL_COEFF            := vUtilCoeff;
        -- Création de la position
        DOC_POSITION_GENERATE.GeneratePosition(aPositionID       => vPOS_CPT_ID
                                             , aDocumentID       => aProcess.DOC_DOCUMENT_ID
                                             , aPosCreateMode    => '165'
                                             , aTypePos          => '91'
                                             , aPTPositionID     => vPOS_ID
                                             , aGoodID           => tplPriceStruct.GCO_GOOD_ID
                                             , aRecordID         => aProcess.DOC_RECORD_ID
                                             , aBasisQuantity    => vQty
                                             , aGoodPrice        => aProcess.CEV_UNIT_SALE_PRICE
                                             , aGenerateDetail   => 1
                                              );
        -- Màj de CML_GEN_DOC avec la nouvelle position crée
        CML_CONTRACT_GENERATE_DOC.UpdateCML_GEN_DOC(aCML_POSITION_ID             => aProcess.CML_POSITION_ID
                                                  , aCML_EVENTS_ID               => aProcess.CML_EVENTS_ID
                                                  , aDOC_POSITION_ID             => vPOS_CPT_ID
                                                  , aDateDoc                     => aProcess.DMT_DATE_DOCUMENT
                                                  , aExtractionType              => aProcess.CGD_EXTRACTION_TYPE
                                                  , aValue                       => (aProcess.CEV_UNIT_SALE_PRICE * vQty)
                                                  , aACS_FINANCIAL_CURRENCY_ID   => aProcess.ACS_FINANCIAL_CURRENCY_ID
                                                  , aDateDe                      => null
                                                  , aDateA                       => null
                                                  , FMultiply                    => aProcess.CGD_MULTIPLY
                                                  , FNewIndiceDate               => aProcess.INP_INDICE_V_DATE
                                                  , FNewIndiceVariable           => aProcess.INP_INDICE_VARIABLE
                                                   );

        fetch crPriceStruct
         into tplPriceStruct;
      end loop;
    else
      -- Init données position
      vPOS_ID                                                         := null;
      DOC_POSITION_GENERATE.ResetPositionInfo(DOC_POSITION_INITIALIZE.PositionInfo);
      DOC_POSITION_INITIALIZE.PositionInfo.CLEAR_POSITION_INFO        := 0;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_CML_POSITION_ID        := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.CML_POSITION_ID            := aProcess.CML_POSITION_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_CML_EVENTS_ID          := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.CML_EVENTS_ID              := aProcess.CML_EVENTS_ID;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_SHORT_DESCRIPTION  := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_SHORT_DESCRIPTION      := tplDescr.DES_SHORT_DESCRIPTION;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_LONG_DESCRIPTION   := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_LONG_DESCRIPTION       := tplDescr.CPS_LONG_DESCRIPTION;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_FREE_DESCRIPTION   := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_FREE_DESCRIPTION       := tplDescr.CPS_FREE_DESCRIPTION;
      DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BODY_TEXT          := 1;
      DOC_POSITION_INITIALIZE.PositionInfo.POS_BODY_TEXT              := tplDescr.RCO_MACHINE_FREE_DESCR;
      -- Structure de ventilation = NON
        -- Création de la position
      DOC_POSITION_GENERATE.GeneratePosition(aPositionID       => vPOS_ID
                                           , aDocumentID       => aProcess.DOC_DOCUMENT_ID
                                           , aPosCreateMode    => '165'
                                           , aTypePos          => '1'
                                           , aGoodID           => aProcess.INP_GCO_GOOD_ID
                                           , aRecordID         => aProcess.DOC_RECORD_ID
                                           , aBasisQuantity    => aProcess.INP_INVOICING_QTY
                                           , aGoodPrice        => aProcess.CEV_UNIT_SALE_PRICE
                                           , aGenerateDetail   => 0
                                            );
      -- Màj de la proposition avec le n° de document et la position générés
      UpdateInvProcess(aProcess.CML_INVOICING_PROCESS_ID, aProcess.DOC_DOCUMENT_ID, vPOS_ID);
      -- Màj de CML_GEN_DOC avec la nouvelle position crée
      CML_CONTRACT_GENERATE_DOC.UpdateCML_GEN_DOC(aCML_POSITION_ID             => aProcess.CML_POSITION_ID
                                                , aCML_EVENTS_ID               => aProcess.CML_EVENTS_ID
                                                , aDOC_POSITION_ID             => vPOS_ID
                                                , aDateDoc                     => aProcess.DMT_DATE_DOCUMENT
                                                , aExtractionType              => aProcess.CGD_EXTRACTION_TYPE
                                                , aValue                       => (aProcess.INP_INVOICING_QTY * aProcess.CEV_UNIT_SALE_PRICE)
                                                , aACS_FINANCIAL_CURRENCY_ID   => aProcess.ACS_FINANCIAL_CURRENCY_ID
                                                , aDateDe                      => null
                                                , aDateA                       => null
                                                , FMultiply                    => aProcess.CGD_MULTIPLY
                                                , FNewIndiceDate               => aProcess.INP_INDICE_V_DATE
                                                , FNewIndiceVariable           => aProcess.INP_INDICE_VARIABLE
                                                 );

      open crLinkedEvents(aProcess.CML_INVOICING_JOB_ID, aProcess.INP_REGROUP_ID, aProcess.CML_EVENTS_ID);

      fetch crLinkedEvents
       into tplLinkedEvents;

      -- Création d'un détail pour chaque événement lié
      while crLinkedEvents%found loop
        -- Init de certaines données de la position
        vDET_ID                                                 := null;
        -- Effacement données
        DOC_DETAIL_INITIALIZE.DetailsInfo(1)                    := vDetailInfo;
        DOC_DETAIL_INITIALIZE.DetailsInfo(1).CLEAR_DETAIL_INFO  := 0;
        DOC_DETAIL_INITIALIZE.DetailsInfo(1).USE_CML_EVENTS_ID  := 1;
        DOC_DETAIL_INITIALIZE.DetailsInfo(1).CML_EVENTS_ID      := tplLinkedEvents.CML_EVENTS_ID;
        DOC_DETAIL_INITIALIZE.DetailsInfo(1).USE_DOC_RECORD_ID  := 1;
        DOC_DETAIL_INITIALIZE.DetailsInfo(1).DOC_RECORD_ID      := tplLinkedEvents.DOC_RCO_MACHINE_ID;
        -- Création du détail
        DOC_DETAIL_GENERATE.GenerateDetail(aDetailID        => vDET_ID
                                         , aPositionID      => vPOS_ID
                                         , aPdeCreateMode   => '165'
                                         , aQuantity        => tplLinkedEvents.INP_INVOICING_QTY
                                          );

        -- Màj de l'événement qui vient d'être facturé
        update CML_EVENTS
           set DOC_POSITION_ID = vPOS_ID
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where CML_EVENTS_ID = tplLinkedEvents.CML_EVENTS_ID;

        fetch crLinkedEvents
         into tplLinkedEvents;
      end loop;

      close crLinkedEvents;
    end if;

    close crPriceStruct;
  end GenLinkedEventsPositions;

  /**
  * procedure GenOtherEventsPositions
  * Description
  *    Génération des positions (DOC_POSITION) à partir des propositions
  *      de type événement <> type '5'
  */
  procedure GenOtherEventsPositions(aProcess in crProcess%rowtype)
  is
    vPOS_ID     DOC_POSITION.DOC_POSITION_ID%type;
    vDET_ID     DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    vDetailInfo DOC_DETAIL_INITIALIZE.TDetailInfo;
  begin
    vPOS_ID                                                        := null;
    DOC_POSITION_GENERATE.ResetPositionInfo(DOC_POSITION_INITIALIZE.PositionInfo);
    DOC_POSITION_INITIALIZE.PositionInfo.CLEAR_POSITION_INFO       := 0;
    DOC_POSITION_INITIALIZE.PositionInfo.USE_CML_POSITION_ID       := 1;
    DOC_POSITION_INITIALIZE.PositionInfo.CML_POSITION_ID           := aProcess.CML_POSITION_ID;
    DOC_POSITION_INITIALIZE.PositionInfo.USE_CML_EVENTS_ID         := 1;
    DOC_POSITION_INITIALIZE.PositionInfo.CML_EVENTS_ID             := aProcess.CML_EVENTS_ID;
    DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_FREE_DESCRIPTION  := 1;
    DOC_POSITION_INITIALIZE.PositionInfo.POS_FREE_DESCRIPTION      := aProcess.CEV_TEXT;
    -- Création de la position
    DOC_POSITION_GENERATE.GeneratePosition(aPositionID       => vPOS_ID
                                         , aDocumentID       => aProcess.DOC_DOCUMENT_ID
                                         , aPosCreateMode    => '165'
                                         , aTypePos          => '1'
                                         , aGoodID           => aProcess.CEV_GCO_GOOD_ID
                                         , aRecordID         => aProcess.DOC_RECORD_ID
                                         , aBasisQuantity    => aProcess.INP_INVOICING_QTY
                                         , aGoodPrice        => aProcess.CEV_UNIT_SALE_PRICE
                                         , aGenerateDetail   => 0
                                          );
    -- Màj de la proposition avec le n° de document et la position générés
    UpdateInvProcess(aProcess.CML_INVOICING_PROCESS_ID, aProcess.DOC_DOCUMENT_ID, vPOS_ID);
    -- Màj de CML_GEN_DOC avec la nouvelle position crée
    CML_CONTRACT_GENERATE_DOC.UpdateCML_GEN_DOC(aCML_POSITION_ID             => aProcess.CML_POSITION_ID
                                              , aCML_EVENTS_ID               => aProcess.CML_EVENTS_ID
                                              , aDOC_POSITION_ID             => vPOS_ID
                                              , aDateDoc                     => aProcess.DMT_DATE_DOCUMENT
                                              , aExtractionType              => aProcess.CGD_EXTRACTION_TYPE
                                              , aValue                       => aProcess.INP_AMOUNT
                                              , aACS_FINANCIAL_CURRENCY_ID   => aProcess.ACS_FINANCIAL_CURRENCY_ID
                                              , aDateDe                      => null
                                              , aDateA                       => null
                                              , FMultiply                    => aProcess.CGD_MULTIPLY
                                              , FNewIndiceDate               => aProcess.INP_INDICE_V_DATE
                                              , FNewIndiceVariable           => aProcess.INP_INDICE_VARIABLE
                                               );
    -- Init de certaines données de la position
    vDET_ID                                                        := null;
    -- Effacement données
    DOC_DETAIL_INITIALIZE.DetailsInfo(1)                           := vDetailInfo;
    DOC_DETAIL_INITIALIZE.DetailsInfo(1).CLEAR_DETAIL_INFO         := 0;
    DOC_DETAIL_INITIALIZE.DetailsInfo(1).USE_CML_EVENTS_ID         := 1;
    DOC_DETAIL_INITIALIZE.DetailsInfo(1).CML_EVENTS_ID             := aProcess.CML_EVENTS_ID;
    -- Création du détail
    DOC_DETAIL_GENERATE.GenerateDetail(aDetailID => vDET_ID, aPositionID => vPOS_ID, aPdeCreateMode => '165', aQuantity => aProcess.INP_INVOICING_QTY);

    -- Màj du Montant facturé supplémentaire
    if aProcess.C_CML_EVENT_TYPE in('1', '2') then
      -- Màj du Montant facturé supplémentaire
      -- Si événement de type 1, 2 :
      --   Montant  supplémentaire position = Montant supplémentaire position + Montant événement
      update CML_POSITION
         set CPO_POSITION_ADDED_AMOUNT = nvl(CPO_POSITION_ADDED_AMOUNT, 0) + aProcess.INP_AMOUNT_BASIS
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where CML_POSITION_ID = aProcess.CML_POSITION_ID;
    elsif aProcess.C_CML_EVENT_TYPE = '3' then
      -- Màj du Montant facturé supplémentaire
      -- Si événement de type 3 :
      --   Montant supplémentaire position = Montant supplémentaire position - Montant événement
      --   Le montant dans l'extraction est déjà négatif pour le type 3
      update CML_POSITION
         set CPO_POSITION_ADDED_AMOUNT = nvl(CPO_POSITION_ADDED_AMOUNT, 0) -(aProcess.INP_AMOUNT_BASIS * -1)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where CML_POSITION_ID = aProcess.CML_POSITION_ID;
    -- Màj Perte position
    elsif aProcess.C_CML_EVENT_TYPE = '4' then
      -- Si événement de type 4 :
      --   Perte position = Perte position + Montant événement
      update CML_POSITION
         set CPO_POSITION_LOSS = nvl(CPO_POSITION_LOSS, 0) +(aProcess.INP_AMOUNT_BASIS * -1)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where CML_POSITION_ID = aProcess.CML_POSITION_ID;
    end if;
  end GenOtherEventsPositions;

  /**
  * procedure GenFixedPricePositions
  * Description
  *    Génération des positions (DOC_POSITION) à partir des propositions forfait
  */
  procedure GenFixedPricePositions(aProcess in crProcess%rowtype)
  is
    cursor crPriceStruct(cPosID in CML_POSITION.CML_POSITION_ID%type, cStructCode in CML_PRICE_STRUCTURE.C_CML_STRUCTURE_CODE%type)
    is
      select   CPS.GCO_GOOD_ID
             , CPS.PST_WEIGHT
          from CML_PRICE_STRUCTURE CPS
         where CPS.CML_POSITION_ID = cPosID
           and CPS.C_CML_STRUCTURE_CODE = cStructCode
      order by CPS.CML_PRICE_STRUCTURE_ID;

    tplPriceStruct crPriceStruct%rowtype;
    vQty           DOC_POSITION.POS_BASIS_QUANTITY%type;
    vSumPstWeight  CML_PRICE_STRUCTURE.PST_WEIGHT%type;
    vUtilCoeff     DOC_POSITION.POS_UTIL_COEFF%type;
    vSumPosAmount  CML_POSITION.CPO_POSITION_AMOUNT%type;
    vPOS_ID        DOC_POSITION.DOC_POSITION_ID%type;
    vPOS_CPT_ID    DOC_POSITION.DOC_POSITION_ID%type;
    lv_StructCode  CML_PRICE_STRUCTURE.C_CML_STRUCTURE_CODE%type;
  begin
    -- Si facturation dans la période initiale de contrat :
    --  utiliser la structure de pondération du prix de la période initiale
    if (aProcess.INP_BEGIN_PERIOD_DATE <= aProcess.CPO_END_CONTRACT_DATE) then
      lv_StructCode  := 'INI';
    else
      -- Si facturation dans la période de prolongation de contrat :
      --  utiliser la structure de pondération du prix de la période de prolongation
      lv_StructCode  := 'EXT';
    end if;

    open crPriceStruct(aProcess.CML_POSITION_ID, lv_StructCode);

    fetch crPriceStruct
     into tplPriceStruct;

    -- Init données position
    vPOS_ID                                                        := null;
    DOC_POSITION_GENERATE.ResetPositionInfo(DOC_POSITION_INITIALIZE.PositionInfo);
    DOC_POSITION_INITIALIZE.PositionInfo.CLEAR_POSITION_INFO       := 0;
    DOC_POSITION_INITIALIZE.PositionInfo.USE_CML_POSITION_ID       := 1;
    DOC_POSITION_INITIALIZE.PositionInfo.CML_POSITION_ID           := aProcess.CML_POSITION_ID;
    DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_FREE_DESCRIPTION  := 1;
    DOC_POSITION_INITIALIZE.PositionInfo.POS_FREE_DESCRIPTION      := aProcess.CPO_BILL_TEXT;
    DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_BODY_TEXT         := 1;
    DOC_POSITION_INITIALIZE.PositionInfo.POS_BODY_TEXT             := aProcess.INP_PERIOD_DATE_TEXT;

    -- Structure de ventilation = OUI
    if crPriceStruct%found then
      -- Création de la position
      DOC_POSITION_GENERATE.GeneratePosition(aPositionID       => vPOS_ID
                                           , aDocumentID       => aProcess.DOC_DOCUMENT_ID
                                           , aPosCreateMode    => '165'
                                           , aTypePos          => '9'
                                           , aGoodID           => aProcess.INP_GCO_GOOD_ID
                                           , aRecordID         => aProcess.DOC_RECORD_ID
                                           , aBasisQuantity    => 1
                                           , aGoodPrice        => 0
                                           , aGenerateDetail   => 1
                                            );
      -- Màj de la proposition avec le n° de document et la position générés
      UpdateInvProcess(aProcess.CML_INVOICING_PROCESS_ID, aProcess.DOC_DOCUMENT_ID, vPOS_ID);
      -- Insertion dans la table de sauvegarde de l'état de la position cml avant la facturation
      CreateCmlPosBack(aProcess.CML_POSITION_ID);

      -- Somme des pondération de la structure de ventilation
      select sum(CPS.PST_WEIGHT)
        into vSumPstWeight
        from CML_PRICE_STRUCTURE CPS
       where CPS.CML_POSITION_ID = aProcess.CML_POSITION_ID
         and CPS.C_CML_STRUCTURE_CODE = lv_StructCode;

      while crPriceStruct%found loop
        -- Coeff d'utilisation de la position CPT
        vUtilCoeff                                                     := tplPriceStruct.PST_WEIGHT / vSumPstWeight;
        vQty                                                           := vUtilCoeff * aProcess.INP_INVOICING_QTY;
        -- Init de certaines données de la position
        vPOS_CPT_ID                                                    := null;
        DOC_POSITION_GENERATE.ResetPositionInfo(DOC_POSITION_INITIALIZE.PositionInfo);
        DOC_POSITION_INITIALIZE.PositionInfo.CLEAR_POSITION_INFO       := 0;
        DOC_POSITION_INITIALIZE.PositionInfo.USE_CML_POSITION_ID       := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.CML_POSITION_ID           := aProcess.CML_POSITION_ID;
        DOC_POSITION_INITIALIZE.PositionInfo.USE_CML_EVENTS_ID         := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.CML_EVENTS_ID             := aProcess.CML_EVENTS_ID;
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_LONG_DESCRIPTION  := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_FREE_DESCRIPTION  := 1;

        begin
          select CPS.CPS_LONG_DESCRIPTION
               , CPS.CPS_FREE_DESCRIPTION
            into DOC_POSITION_INITIALIZE.PositionInfo.POS_LONG_DESCRIPTION
               , DOC_POSITION_INITIALIZE.PositionInfo.POS_FREE_DESCRIPTION
            from CML_POSITION_SERVICE CPS
               , CML_POSITION_SERVICE_DETAIL CPD
               , CML_EVENTS CEV
           where CPS.CML_POSITION_ID = aProcess.CML_POSITION_ID
             and CEV.CML_EVENTS_ID = aProcess.CML_EVENTS_ID
             and CPS.CML_POSITION_SERVICE_ID = CPD.CML_POSITION_SERVICE_ID
             and CEV.CML_POSITION_SERVICE_DETAIL_ID = CPD.CML_POSITION_SERVICE_DETAIL_ID;
        exception
          when no_data_found then
            DOC_POSITION_INITIALIZE.PositionInfo.POS_LONG_DESCRIPTION  := '';
            DOC_POSITION_INITIALIZE.PositionInfo.POS_FREE_DESCRIPTION  := '';
        end;

        -- Coefficient d'utilisation du composant
        DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_UTIL_COEFF        := 1;
        DOC_POSITION_INITIALIZE.PositionInfo.POS_UTIL_COEFF            := vUtilCoeff;
        -- Création de la position
        DOC_POSITION_GENERATE.GeneratePosition(aPositionID       => vPOS_CPT_ID
                                             , aDocumentID       => aProcess.DOC_DOCUMENT_ID
                                             , aPosCreateMode    => '165'
                                             , aTypePos          => '91'
                                             , aPTPositionID     => vPOS_ID
                                             , aGoodID           => tplPriceStruct.GCO_GOOD_ID
                                             , aRecordID         => aProcess.DOC_RECORD_ID
                                             , aBasisQuantity    => vQty
                                             , aGoodPrice        => aProcess.INP_AMOUNT
                                             , aGenerateDetail   => 1
                                              );
        -- Màj de CML_GEN_DOC avec la nouvelle position crée
        CML_CONTRACT_GENERATE_DOC.UpdateCML_GEN_DOC(aCML_POSITION_ID             => aProcess.CML_POSITION_ID
                                                  , aCML_EVENTS_ID               => aProcess.CML_EVENTS_ID
                                                  , aDOC_POSITION_ID             => vPOS_CPT_ID
                                                  , aDateDoc                     => aProcess.DMT_DATE_DOCUMENT
                                                  , aExtractionType              => aProcess.CGD_EXTRACTION_TYPE
                                                  , aValue                       => (aProcess.INP_AMOUNT * vQty)
                                                  , aACS_FINANCIAL_CURRENCY_ID   => aProcess.ACS_FINANCIAL_CURRENCY_ID
                                                  , aDateDe                      => aProcess.INP_BEGIN_PERIOD_DATE
                                                  , aDateA                       => aProcess.INP_END_PERIOD_DATE
                                                  , FMultiply                    => aProcess.CGD_MULTIPLY
                                                  , FNewIndiceDate               => aProcess.INP_INDICE_V_DATE
                                                  , FNewIndiceVariable           => aProcess.INP_INDICE_VARIABLE
                                                   );

        fetch crPriceStruct
         into tplPriceStruct;
      end loop;

      -- somme des montants brut HT des positions CPT
      select sum(POS_GROSS_VALUE) * aProcess.CGD_MULTIPLY
        into vSumPosAmount
        from DOC_POSITION
       where DOC_DOC_POSITION_ID = vPOS_ID;
    else
      -- Structure de ventilation = NON

      -- Insertion dans la table de sauvegarde de l'état de la position cml avant la facturation
      CreateCmlPosBack(aProcess.CML_POSITION_ID);
      -- Création de la position
      DOC_POSITION_GENERATE.GeneratePosition(aPositionID       => vPOS_ID
                                           , aDocumentID       => aProcess.DOC_DOCUMENT_ID
                                           , aPosCreateMode    => '165'
                                           , aTypePos          => '1'
                                           , aGoodID           => aProcess.INP_GCO_GOOD_ID
                                           , aRecordID         => aProcess.DOC_RECORD_ID
                                           , aBasisQuantity    => 1
                                           , aGoodPrice        => aProcess.INP_AMOUNT
                                           , aGenerateDetail   => 1
                                            );
      -- Màj de la proposition avec le n° de document et la position générés
      UpdateInvProcess(aProcess.CML_INVOICING_PROCESS_ID, aProcess.DOC_DOCUMENT_ID, vPOS_ID);
      -- Màj de CML_GEN_DOC avec la nouvelle position crée
      CML_CONTRACT_GENERATE_DOC.UpdateCML_GEN_DOC(aCML_POSITION_ID             => aProcess.CML_POSITION_ID
                                                , aCML_EVENTS_ID               => aProcess.CML_EVENTS_ID
                                                , aDOC_POSITION_ID             => vPOS_ID
                                                , aDateDoc                     => aProcess.DMT_DATE_DOCUMENT
                                                , aExtractionType              => aProcess.CGD_EXTRACTION_TYPE
                                                , aValue                       => aProcess.INP_AMOUNT
                                                , aACS_FINANCIAL_CURRENCY_ID   => aProcess.ACS_FINANCIAL_CURRENCY_ID
                                                , aDateDe                      => aProcess.INP_BEGIN_PERIOD_DATE
                                                , aDateA                       => aProcess.INP_END_PERIOD_DATE
                                                , FMultiply                    => aProcess.CGD_MULTIPLY
                                                , FNewIndiceDate               => aProcess.INP_INDICE_V_DATE
                                                , FNewIndiceVariable           => aProcess.INP_INDICE_VARIABLE
                                                 );
      vSumPosAmount  := aProcess.INP_AMOUNT * aProcess.CGD_MULTIPLY;
    end if;

    close crPriceStruct;

    -- Màj montant facturé de la position
    update CML_POSITION
       set CPO_POSITION_AMOUNT = nvl(CPO_POSITION_AMOUNT, 0) + vSumPosAmount
         , CPO_LAST_PERIOD_BEGIN = aProcess.INP_BEGIN_PERIOD_DATE
         , CPO_LAST_PERIOD_END = aProcess.INP_END_PERIOD_DATE
         , CPO_NEXT_DATE = nvl(aProcess.INP_NEXT_DATE, CPO_NEXT_DATE)
         , C_CML_POS_STATUS = case
                               when aProcess.INP_POS_EXPIRED = 1 then '04'
                               else C_CML_POS_STATUS
                             end
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where CML_POSITION_ID = aProcess.CML_POSITION_ID;
  end GenFixedPricePositions;

  /**
  * procedure GenDepositPenalityPositions
  * Description
  *    Génération des positions (DOC_POSITION) à partir des propositions
  *      dépôt ou pénalité
  */
  procedure GenDepositPenalityPositions(aProcess in crProcess%rowtype)
  is
    vPOS_ID DOC_POSITION.DOC_POSITION_ID%type   default null;
  begin
    DOC_POSITION_GENERATE.ResetPositionInfo(DOC_POSITION_INITIALIZE.PositionInfo);
    DOC_POSITION_INITIALIZE.PositionInfo.CLEAR_POSITION_INFO       := 0;
    DOC_POSITION_INITIALIZE.PositionInfo.USE_CML_POSITION_ID       := 1;
    DOC_POSITION_INITIALIZE.PositionInfo.CML_POSITION_ID           := aProcess.CML_POSITION_ID;
    DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_FREE_DESCRIPTION  := 1;

    if aProcess.C_INVOICING_PROCESS_TYPE = 'DEPOSIT' then
      DOC_POSITION_INITIALIZE.PositionInfo.POS_FREE_DESCRIPTION  := aProcess.CPO_DEPOT_TEXT;
    else
      DOC_POSITION_INITIALIZE.PositionInfo.POS_FREE_DESCRIPTION  := aProcess.CPO_PENALITY_TEXT;
    end if;

    -- Création de la position
    DOC_POSITION_GENERATE.GeneratePosition(aPositionID       => vPOS_ID
                                         , aDocumentID       => aProcess.DOC_DOCUMENT_ID
                                         , aPosCreateMode    => '165'
                                         , aTypePos          => '1'
                                         , aGoodID           => aProcess.INP_GCO_GOOD_ID
                                         , aRecordID         => aProcess.DOC_RECORD_ID
                                         , aBasisQuantity    => 1
                                         , aGoodPrice        => aProcess.INP_AMOUNT
                                         , aGenerateDetail   => 1
                                          );
    -- Màj de la proposition avec le n° de document et la position générés
    UpdateInvProcess(aProcess.CML_INVOICING_PROCESS_ID, aProcess.DOC_DOCUMENT_ID, vPOS_ID);
    -- Màj de CML_GEN_DOC avec la nouvelle position crée
    CML_CONTRACT_GENERATE_DOC.UpdateCML_GEN_DOC(aCML_POSITION_ID             => aProcess.CML_POSITION_ID
                                              , aCML_EVENTS_ID               => null
                                              , aDOC_POSITION_ID             => vPOS_ID
                                              , aDateDoc                     => aProcess.DMT_DATE_DOCUMENT
                                              , aExtractionType              => aProcess.CGD_EXTRACTION_TYPE
                                              , aValue                       => aProcess.INP_AMOUNT
                                              , aACS_FINANCIAL_CURRENCY_ID   => aProcess.ACS_FINANCIAL_CURRENCY_ID
                                              , aDateDe                      => null
                                              , aDateA                       => null
                                              , FMultiply                    => aProcess.CGD_MULTIPLY
                                              , FNewIndiceDate               => aProcess.INP_INDICE_V_DATE
                                              , FNewIndiceVariable           => aProcess.INP_INDICE_VARIABLE
                                               );

    -- Màj date facture dépôt demandé et code de facturation dépôt (si facturation dépôt)
    -- Màj date facture pénalité et code facturation dépôt (si facturation pénalité)
    if aProcess.DOCUMENT_TYPE = 'INVOICE' then
      -- Màj date facture dépôt demandé et code de facturation dépôt (si facturation dépôt)
      if aProcess.C_INVOICING_PROCESS_TYPE = 'DEPOSIT' then
        update CML_POSITION
           set CPO_DEPOT_BILL_DATE = aProcess.DMT_DATE_DOCUMENT
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where CML_POSITION_ID = aProcess.CML_POSITION_ID;
      else
        -- Màj date facture pénalité et code facturation dépôt (si facturation pénalité)
        update CML_POSITION
           set CPO_PENALITY_BILL_DATE = aProcess.DMT_DATE_DOCUMENT
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where CML_POSITION_ID = aProcess.CML_POSITION_ID;
      end if;
    -- Màj date note de crédit dépôt et code note crédit dépôt (si note de crédit dépôt)
    elsif     (aProcess.DOCUMENT_TYPE = 'CREDIT_NOTE')
          and (aProcess.C_INVOICING_PROCESS_TYPE = 'DEPOSIT') then
      update CML_POSITION
         set CPO_DEPOT_CN_DATE = aProcess.DMT_DATE_DOCUMENT
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where CML_POSITION_ID = aProcess.CML_POSITION_ID;
    end if;
  end GenDepositPenalityPositions;

  /**
  * procedure UpdateInvProcess
  * Description
  *    Màj de la proposition avec le n° de document et la position générés
  */
  procedure UpdateInvProcess(aInvProcessID in number, aDocumentID in number, aPositionID in number)
  is
  begin
    update CML_INVOICING_PROCESS
       set DOC_DOCUMENT_ID = aDocumentID
         , DOC_POSITION_ID = aPositionID
         , A_RECSTATUS = null
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where CML_INVOICING_PROCESS_ID = aInvProcessID;
  end UpdateInvProcess;

  function CompleteInvoicingJob(aJobID in number)
    return number
  is
    ErrorCode varchar2(3);
    ErrorText varchar2(32000);
    vResult   number(1)       default 1;
  begin
    for tplDoc in (select distinct DMT.DOC_DOCUMENT_ID
                              from DOC_DOCUMENT DMT
                                 , CML_INVOICING_PROCESS INP
                             where INP.CML_INVOICING_JOB_ID = aJobID
                               and INP.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
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
      update CML_POSITION
         set CPO_PROTECTED = 0
           , CML_INVOICING_JOB_ID = null
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where CML_POSITION_ID in(select distinct CML_POSITION_ID
                                           from CML_INVOICING_PROCESS
                                          where CML_INVOICING_JOB_ID = aJobID);

      -- Terminer le travail
      update CML_INVOICING_JOB
         set C_CML_INVOICING_JOB_STATUS = '3'
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where CML_INVOICING_JOB_ID = aJobID;
    end if;

    return vResult;
  end CompleteInvoicingJob;

  procedure CreateCmlPosBack(aPositionID in CML_POSITION.CML_POSITION_ID%type)
  is
  begin
    delete from CML_POSITION_BACK
          where CML_POSITION_ID = aPositionID;

    insert into CML_POSITION_BACK
                (CML_POSITION_ID
               , CML_DOCUMENT_ID
               , CPO_SEQUENCE
               , ACS_FINANCIAL_CURRENCY_ID
               , DOC_RECORD_ID
               , PAC_REPRESENTATIVE_ID
               , C_CML_POS_STATUS
               , C_CML_POS_TYPE
               , C_CML_POS_TREATMENT
               , C_CML_RENT_TYPE
               , C_CML_MAINT_TYPE
               , CPO_PRORATA
               , CPO_INDICE
               , CPO_POS_GOOD_ID
               , CPO_SALE_PRICE
               , CPO_COST_PRICE
               , CPO_RENT_PRICE
               , CPO_RENT_COST_PRICE
               , CPO_MAINT_PRICE
               , CPO_MAINT_COST_PRICE
               , CPO_RENT_AMOUNT
               , CPO_MAINT_AMOUNT
               , CPO_RENT_LOSS
               , CPO_MAINT_LOSS
               , CPO_RENT_ADDED_AMOUNT
               , CPO_MAIN_ADDED_AMOUNT
               , CPO_CONCLUSION_DATE
               , CPO_BEGIN_SERVICE_DATE
               , CPO_BEGIN_CONTRACT_DATE
               , CPO_CONTRACT_MONTHES
               , CPO_END_CONTRACT_DATE
               , CPO_EXTENDED_MONTHES
               , CPO_END_EXTENDED_DATE
               , CPO_RESILIATION_DATE
               , CPO_SUSPENSION_DATE
               , CPO_EFFECTIV_END_DATE
               , CPO_FIRST_RENT_DATE
               , CPO_FIRST_MAINT_DATE
               , CPO_LAST_RENT_DATE
               , CPO_LAST_MAINT_DATE
               , CPO_NEXT_DATE
               , CPO_LAST_PERIOD_BEGIN
               , CPO_LAST_PERIOD_END
               , CPO_DEPOT_GOOD_ID
               , CPO_DEPOT_AMOUNT
               , CPO_DEPOT_TEXT
               , CPO_DEPOT_BILL_DATE
               , CPO_DEPOT_BILL_GEN
               , CPO_DEPOT_CN_DATE
               , CPO_DEPOT_CN_GEN
               , CPO_PENALITY_GOOD_ID
               , CPO_PENALITY_AMOUNT
               , CPO_PENALITY_TEXT
               , CPO_PENALITY_BILL_DATE
               , CPO_PENALITY_BILL_GEN
               , CPO_BILL_TEXT
               , DIC_POS_FREE_TABLE_1_ID
               , DIC_POS_FREE_TABLE_2_ID
               , DIC_POS_FREE_TABLE_3_ID
               , CPO_DECIMAL_1
               , CPO_DECIMAL_2
               , CPO_DECIMAL_3
               , CPO_TEXT_1
               , CPO_TEXT_2
               , CPO_TEXT_3
               , CPO_NUMERIC_1
               , CPO_NUMERIC_2
               , CPO_NUMERIC_3
               , CPO_NUMERIC_4
               , CPO_NUMERIC_5
               , CPO_FREE_TEXT_1
               , CPO_FREE_TEXT_2
               , CPO_FREE_TEXT_3
               , CPO_FREE_TEXT_4
               , CPO_FREE_TEXT_5
               , DIC_CML_PDE_FREE1_ID
               , DIC_CML_PDE_FREE2_ID
               , DIC_CML_PDE_FREE3_ID
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , C_CML_TIME_UNIT
               , CPO_MULTIYEAR
               , CPO_PROV_BEGIN_DATE
               , CPO_PROV_END_DATE
               , CPO_PROV_AMOUNT
               , DIC_TARIFF_ID
               , C_CML_POS_INDICE_V_VALID
               , CPO_INDICE_V_DATE
               , CPO_INDICE_VARIABLE
               , DOC_PROV_DOCUMENT_ID
               , CPO_DESCRIPTION
               , CPO_PROC_BEFORE_VALIDATE
               , CPO_PROC_AFTER_VALIDATE
               , CPO_PROC_BEFORE_EDIT
               , CPO_PROC_AFTER_EDIT
               , CPO_PROC_BEFORE_DELETE
               , CPO_PROC_AFTER_DELETE
               , CPO_PROC_BEFORE_ACTIVATE
               , CPO_PROC_AFTER_ACTIVATE
               , CPO_PROC_BEFORE_HOLD
               , CPO_PROC_AFTER_HOLD
               , CPO_PROC_BEFORE_REACTIVATE
               , CPO_PROC_AFTER_REACTIVATE
               , CPO_PROC_BEFORE_CANCEL
               , CPO_PROC_AFTER_CANCEL
               , CPO_PROC_BEFORE_END
               , CPO_PROC_AFTER_END
               , CPO_POSITION_PRICE
               , CPO_POSITION_COST_PRICE
               , CPO_POSITION_AMOUNT
               , CPO_POSITION_ADDED_AMOUNT
               , CPO_POSITION_LOSS
               , CPO_FIRST_POSITION_DATE
               , CPO_LAST_POSITION_DATE
               , CPO_EXTENSION_TIME
               , CPO_EXTENSION_PERIOD_NB
               , CML_CML_POSITION_ID
               , DIC_COMPLEMENTARY_DATA_ID
               , CPO_INIT_DAY_POSTPONE
               , CPO_PC_USER_ID
               , DIC_CML_RESILIATION_DEMAND_ID
               , DIC_CML_RESILIATION_REASON_ID
               , DIC_CML_SUSPENSION_REASON_ID
               , CPO_EXT_PERIOD_NB_DONE
               , CPO_INIT_PERIOD_PRICE
               , CPO_EXTEND_PERIOD_PRICE
               , DIC_CML_INVOICE_REGROUPING_ID
               , C_CML_INVOICE_UNIT
               , CPO_PROC_BEFORE_EXTEND
               , CPO_PROC_AFTER_EXTEND
               , A_RECLEVEL
               , A_RECSTATUS
               , A_CONFIRM
               , CPO_PROTECTED
               , CML_INVOICING_JOB_ID
               , CPO_EFFECTIV_MONTHES
               , CPO_SESSION_ID
                )
      select CML_POSITION_ID
           , CML_DOCUMENT_ID
           , CPO_SEQUENCE
           , ACS_FINANCIAL_CURRENCY_ID
           , DOC_RECORD_ID
           , PAC_REPRESENTATIVE_ID
           , C_CML_POS_STATUS
           , C_CML_POS_TYPE
           , C_CML_POS_TREATMENT
           , C_CML_RENT_TYPE
           , C_CML_MAINT_TYPE
           , CPO_PRORATA
           , CPO_INDICE
           , CPO_POS_GOOD_ID
           , CPO_SALE_PRICE
           , CPO_COST_PRICE
           , CPO_RENT_PRICE
           , CPO_RENT_COST_PRICE
           , CPO_MAINT_PRICE
           , CPO_MAINT_COST_PRICE
           , CPO_RENT_AMOUNT
           , CPO_MAINT_AMOUNT
           , CPO_RENT_LOSS
           , CPO_MAINT_LOSS
           , CPO_RENT_ADDED_AMOUNT
           , CPO_MAIN_ADDED_AMOUNT
           , CPO_CONCLUSION_DATE
           , CPO_BEGIN_SERVICE_DATE
           , CPO_BEGIN_CONTRACT_DATE
           , CPO_CONTRACT_MONTHES
           , CPO_END_CONTRACT_DATE
           , CPO_EXTENDED_MONTHES
           , CPO_END_EXTENDED_DATE
           , CPO_RESILIATION_DATE
           , CPO_SUSPENSION_DATE
           , CPO_EFFECTIV_END_DATE
           , CPO_FIRST_RENT_DATE
           , CPO_FIRST_MAINT_DATE
           , CPO_LAST_RENT_DATE
           , CPO_LAST_MAINT_DATE
           , CPO_NEXT_DATE
           , CPO_LAST_PERIOD_BEGIN
           , CPO_LAST_PERIOD_END
           , CPO_DEPOT_GOOD_ID
           , CPO_DEPOT_AMOUNT
           , CPO_DEPOT_TEXT
           , CPO_DEPOT_BILL_DATE
           , CPO_DEPOT_BILL_GEN
           , CPO_DEPOT_CN_DATE
           , CPO_DEPOT_CN_GEN
           , CPO_PENALITY_GOOD_ID
           , CPO_PENALITY_AMOUNT
           , CPO_PENALITY_TEXT
           , CPO_PENALITY_BILL_DATE
           , CPO_PENALITY_BILL_GEN
           , CPO_BILL_TEXT
           , DIC_POS_FREE_TABLE_1_ID
           , DIC_POS_FREE_TABLE_2_ID
           , DIC_POS_FREE_TABLE_3_ID
           , CPO_DECIMAL_1
           , CPO_DECIMAL_2
           , CPO_DECIMAL_3
           , CPO_TEXT_1
           , CPO_TEXT_2
           , CPO_TEXT_3
           , CPO_NUMERIC_1
           , CPO_NUMERIC_2
           , CPO_NUMERIC_3
           , CPO_NUMERIC_4
           , CPO_NUMERIC_5
           , CPO_FREE_TEXT_1
           , CPO_FREE_TEXT_2
           , CPO_FREE_TEXT_3
           , CPO_FREE_TEXT_4
           , CPO_FREE_TEXT_5
           , DIC_CML_PDE_FREE1_ID
           , DIC_CML_PDE_FREE2_ID
           , DIC_CML_PDE_FREE3_ID
           , A_DATECRE
           , A_DATEMOD
           , A_IDCRE
           , A_IDMOD
           , C_CML_TIME_UNIT
           , CPO_MULTIYEAR
           , CPO_PROV_BEGIN_DATE
           , CPO_PROV_END_DATE
           , CPO_PROV_AMOUNT
           , DIC_TARIFF_ID
           , C_CML_POS_INDICE_V_VALID
           , CPO_INDICE_V_DATE
           , CPO_INDICE_VARIABLE
           , DOC_PROV_DOCUMENT_ID
           , CPO_DESCRIPTION
           , CPO_PROC_BEFORE_VALIDATE
           , CPO_PROC_AFTER_VALIDATE
           , CPO_PROC_BEFORE_EDIT
           , CPO_PROC_AFTER_EDIT
           , CPO_PROC_BEFORE_DELETE
           , CPO_PROC_AFTER_DELETE
           , CPO_PROC_BEFORE_ACTIVATE
           , CPO_PROC_AFTER_ACTIVATE
           , CPO_PROC_BEFORE_HOLD
           , CPO_PROC_AFTER_HOLD
           , CPO_PROC_BEFORE_REACTIVATE
           , CPO_PROC_AFTER_REACTIVATE
           , CPO_PROC_BEFORE_CANCEL
           , CPO_PROC_AFTER_CANCEL
           , CPO_PROC_BEFORE_END
           , CPO_PROC_AFTER_END
           , CPO_POSITION_PRICE
           , CPO_POSITION_COST_PRICE
           , CPO_POSITION_AMOUNT
           , CPO_POSITION_ADDED_AMOUNT
           , CPO_POSITION_LOSS
           , CPO_FIRST_POSITION_DATE
           , CPO_LAST_POSITION_DATE
           , CPO_EXTENSION_TIME
           , CPO_EXTENSION_PERIOD_NB
           , CML_CML_POSITION_ID
           , DIC_COMPLEMENTARY_DATA_ID
           , CPO_INIT_DAY_POSTPONE
           , CPO_PC_USER_ID
           , DIC_CML_RESILIATION_DEMAND_ID
           , DIC_CML_RESILIATION_REASON_ID
           , DIC_CML_SUSPENSION_REASON_ID
           , CPO_EXT_PERIOD_NB_DONE
           , CPO_INIT_PERIOD_PRICE
           , CPO_EXTEND_PERIOD_PRICE
           , DIC_CML_INVOICE_REGROUPING_ID
           , C_CML_INVOICE_UNIT
           , CPO_PROC_BEFORE_EXTEND
           , CPO_PROC_AFTER_EXTEND
           , A_RECLEVEL
           , A_RECSTATUS
           , A_CONFIRM
           , CPO_PROTECTED
           , CML_INVOICING_JOB_ID
           , CPO_EFFECTIV_MONTHES
           , CPO_SESSION_ID
        from CML_POSITION
       where CML_POSITION_ID = aPositionID;
  end CreateCmlPosBack;
end CML_INVOICING_FUNCTIONS;
