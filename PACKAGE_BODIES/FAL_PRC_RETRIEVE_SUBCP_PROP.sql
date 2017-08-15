--------------------------------------------------------
--  DDL for Package Body FAL_PRC_RETRIEVE_SUBCP_PROP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_RETRIEVE_SUBCP_PROP" 
is
  /**
  * procedure UpdateBatchRefCompl
  * Description : Mise à jour de la référence complète d'un lot de fabrication avec
  *               le numéro de document et celui de la position
  * @created ECA
  * @lastUpdate age 18.06.2012
  * @private
  * @param   iFalLotId : Lot de fabrication
  * @param   iDocPositionId : Position correspondantes
  */
  function UpdateBatchRefCompl(iFalLotId in number, iDocPositionId in number)
    return varchar2
  is
    lNewLotRefCompl varchar2(255);
    ltCRUD_DEF      FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Récupération de la valeur de la référence du lot en fonction de la position
    lNewLotRefCompl  := FAL_I_LIB_SUBCONTRACTP.getNewSubCoRefCompl(iPositionID => iDocPositionId);
    -- Mise à jour de la référence complète du lot
    FWK_I_MGT_ENTITY.new(FWK_TYP_FAL_ENTITY.gcfallot, ltCRUD_DEF, true, iFalLotId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'LOT_REFCOMPL', lNewLotRefCompl);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    -- Mise à jour de la description des réseaux
    FAL_NETWORK.UpdateBatchNetwDescr(iFalLotId);
    return lNewLotRefCompl;
  end UpdateBatchRefCompl;

  /**
  * procedure GetPropositionsTable
  * Description : Fonction pipelined, d'accès à la table de travail des propositions
  *               en cours de reprise
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iLPT_ORACLE_SESSION : Session
  */
  function GetPropositionsTable
    return TTabSelectedProp pipelined
  is
  begin
    if oTabSelectedProp.count > 0 then
      for i in oTabSelectedProp.first .. oTabSelectedProp.last loop
        pipe row(oTabSelectedProp(i) );
      end loop;
    end if;
  end GetPropositionsTable;

  /**
  * procedure GetPropositionFromTable
  * Description : Récupération d'une proposition dans la table temporaire de travail
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   iFallotPropTempId : proposition
  */
  function GetPropositionFromTable(iFalLotPropTempId in number)
    return FAL_PRC_RETRIEVE_MANUF_PROP.TPropositions
  is
  begin
    if oTabSelectedProp.count > 0 then
      for i in oTabSelectedProp.first .. oTabSelectedProp.last loop
        if oTabSelectedProp(i).FAL_LOT_PROP_TEMP_ID = iFalLotPropTempId then
          return oTabSelectedProp(i);
        end if;
      end loop;
    end if;
  end GetPropositionFromTable;

  /**
  * function GetSubcontractPOrder
  * Description : Recherche des ordres de fabrication pour la sous-traitance d'achat
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   iFalJobProgramId : Programme
  * @param   iPacSupplierPartnerId : Fournisseur
  * @param   iGcoGoodId : bien
  * @param   iDocRecordId : Dossier
  */
  function GetSubcontractPOrder(iFalJobProgramId in number, iPacSupplierPartnerId in number, iGcoGoodId in number, iDocRecordId in number)
    return number
  is
    lnOrderId number;
  begin
    -- Recherche d'un ordre correspondant
    lnOrderId  := FAL_LIB_SUBCONTRACTP.GetOrderId(iFalJobProgramId, iPacSupplierPartnerId, iGcoGoodId);

    -- Création si inexistant
    if lnOrderId is null then
      lnOrderId  :=
        FAL_ORDER_FUNCTIONS.CreateManufactureOrder(aFAL_JOB_PROGRAM_ID        => iFalJobProgramId
                                                 , aGCO_GOOD_ID               => iGcoGoodId
                                                 , aDOC_RECORD_ID             => iDocRecordId
                                                 , aC_FAB_TYPE                => '4'
                                                 , aPAC_SUPPLIER_PARTNER_ID   => iPacSupplierPartnerId
                                                  );
    end if;

    return lnOrderID;
  end GetSubContractPOrder;

  /**
  * function GetSUPODocGaugeID
  * Description : Récupération du gabarit pour la reprise des propositions de sous-traitance
  *               1) celui de la définition de proposition.
  * @created ECA
  * @lastUpdate SMA 14.02.2013
  * @public
  * @param   iCPrefixeProp : préfixe de proposition
  * @param   iCSupplyMode : Mode d'appro du bien sous-traité
  */
  function GetSUPODocGaugeID(iCPrefixeProp in varchar2, iCSupplyMode in varchar2)
    return number
  is
    lnDocGaugeId number;
  begin
    -- Recherche du gabarit de la définition de proposition
    lnDocGaugeId  := null;

    for tplPropDef in (select DOC_GAUGE_ID
                         from FAL_PROP_DEF
                        where C_PREFIX_PROP = iCPrefixeProp
                          and C_SUPPLY_MODE = iCSupplyMode
                          and DOC_I_LIB_SUBCONTRACTP.issupogauge(DOC_GAUGE_ID) = 1) loop
      lnDocGaugeId  := tplPropDef.DOC_GAUGE_ID;
      exit;
    end loop;

    return lnDocGaugeId;
  end GetSUPODocGaugeID;

  /**
  * procedure GenerateSUPODocument
  * Description : Génération d'un document de sous-traitance d'achat
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param  ioDocDocumentId : Document généré
  * @param  iDocGaugeId : Gabarit
  * @param  iPacSupplierPartnerId : Fournisseur
  * @param  iDocRecordId : Dossier
  */
  procedure GenerateSUPODocument(ioDocDocumentId in out number, iDocGaugeId in number, iPacSupplierPartnerId in number, iDocRecordId in number)
  is
  begin
    DOC_DOCUMENT_GENERATE.GenerateDocument(aNewDocumentID   => ioDocDocumentId
                                         , aMode            => '123'
                                         , aGaugeID         => iDocGaugeId
                                         , aThirdID         => iPacSupplierPartnerId
                                         , aRecordID        => iDocRecordId
                                         , aDocDate         => sysdate
                                          );
  end GenerateSUPODocument;

  /**
  * procedure GenerateSUPOPosition
  * Description : Génération d'une position de document de sous-traitance d'achat
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param  iDocDocumentId : Document
  * @param  iDocGaugeId : Gabarit
  * @param  iPacSupplierPartnerId : Fournisseur
  * @param  iDocRecordId : Dossier
  */
  procedure GenerateSUPOPosition(
    ioDocPositionId        in out number
  , iDocDocumentId         in     number
  , iGcoBilledGoodId       in     number
  , iGcoManufacturedGoodId in     number
  , iLotTotalQuantity      in     number
  , iDocRecordId           in     number
  , iBasisDelay            in     date
  , iInterDelay            in     date
  , iFinalDelay            in     date
  , iFalLotId              in     number
  )
  is
  begin
    Doc_Position_Generate.ResetPositionInfo(Doc_Position_Initialize.PositionInfo);
    Doc_Position_Initialize.PositionInfo.CLEAR_POSITION_INFO  := 0;
    Doc_Position_Initialize.PositionInfo.C_DOC_LOT_TYPE       := '001';
    Doc_Position_Initialize.PositionInfo.FAL_LOT_ID           := iFalLotId;
    DOC_POSITION_GENERATE.GeneratePosition(aPositionID               => ioDocPositionId
                                         , aDocumentID               => iDocDocumentId
                                         , aPosCreateMode            => '123'
                                         , aTypePos                  => '1'
                                         , aGoodID                   => iGcoBilledGoodId
                                         , aBasisQuantity            => iLotTotalQuantity
                                         , aRecordID                 => iDocRecordId
                                         , aGenerateDetail           => 1
                                         , aGenerateCPT              => 0
                                         , aGenerateDiscountCharge   => 1
                                         , aBasisDelay               => iBasisDelay
                                         , aInterDelay               => iInterDelay
                                         , aFinalDelay               => iFinalDelay
                                         , aManufacturedGoodID       => iGcoManufacturedGoodId
                                          );
    -- Planifie le délai de base de la CAST et la date de début planifié du lot en fonction du délai final,
    -- car, dans ce contexte, le lot n'est pas planifié par la méthode
    -- GeneratePosition -> GenerateDetail -> GenerateBatch -> CreateBatch -> PlanificationLotSubcontractP
    FAL_PRC_SUBCONTRACTP.UpdateSubcontractDelay(iStartDate => iFinalDelay, iFalLotId => iFalLotId, iUpdatedDelay => 'FINAL');
  end GenerateSUPOPosition;

  /**
  * procedure ReserveSubContractingPProp
  * Description : Réservation des propositions de Sous-traitance pour reprise éventuelle
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iGCO_GOOD_ID : Bien
  * @param   iGOOD_CATEGORY_WORDING_FROM : Catégorie de bien de
  * @param   iGOOD_CATEGORY_WORDING_TO  : Catégorie de bien à
  * @param   iDIC_GOOD_FAMILY_FROM : Famille de bien de
  * @param   iDIC_GOOD_FAMILY_TO : Famille de bien à
  * @param   iDIC_ACCOUNTABLE_GROUP_FROM : Groupe de resp. de
  * @param   iDIC_ACCOUNTABLE_GROUP_TO : Groupe de resp. à
  * @param   iDIC_GOOD_LINE_FROM : Ligne de produits de
  * @param   iDIC_GOOD_LINE_TO : Ligne de produits à
  * @param   iDIC_GOOD_GROUP_FROM : Groupe de produits de
  * @param   iDIC_GOOD_GROUP_TO : Groupe de produits à
  * @param   iDIC_GOOD_MODEL_FROM : Groupe de produits de
  * @param   iDIC_GOOD_MODEL_TO : Groupe de produits à
  * @param   iDIC_LOT_PROP_FREE : Code traitement
  * @param   iC_PREFIX_PROP : Préfixe
  * @param   iLOT_PLAN_BEGIN_DTE_MIN : Date debut plan min
  * @param   iLOT_PLAN_BEGIN_DTE_MAX : Date debut plan max
  * @param   iLOT_PLAN_END_DTE_MIN : Date fin plan min
  * @param   iLOT_PLAN_END_DTE_MAX Date fin plan max
  * @param   iDOC_RECORD_FROM : Dossier de
  * @param   iDOC_RECORD_TO : Dossier à
  * @param   iSTM_STOCK_ID : Stock
  * @param   iLPT_ORACLE_SESSION : Session Oracle
  * @param   iCFabType : Genre fabrication / Sous-traitance d'achat
  */
  procedure ReserveSubContractingpProp(
    iGCO_GOOD_ID                in number default null
  , iGOOD_CATEGORY_WORDING_FROM in number default null
  , iGOOD_CATEGORY_WORDING_TO   in number default null
  , iDIC_GOOD_FAMILY_FROM       in varchar2 default null
  , iDIC_GOOD_FAMILY_TO         in varchar2 default null
  , iDIC_ACCOUNTABLE_GROUP_FROM in varchar2 default null
  , iDIC_ACCOUNTABLE_GROUP_TO   in varchar2 default null
  , iDIC_GOOD_LINE_FROM         in varchar2 default null
  , iDIC_GOOD_LINE_TO           in varchar2 default null
  , iDIC_GOOD_GROUP_FROM        in varchar2 default null
  , iDIC_GOOD_GROUP_TO          in varchar2 default null
  , iDIC_GOOD_MODEL_FROM        in varchar2 default null
  , iDIC_GOOD_MODEL_TO          in varchar2 default null
  , iDIC_LOT_PROP_FREE          in varchar2 default null
  , iC_PREFIX_PROP              in varchar2 default null
  , iLOT_PLAN_BEGIN_DTE_MIN     in date default null
  , iLOT_PLAN_BEGIN_DTE_MAX     in date default null
  , iLOT_PLAN_END_DTE_MIN       in date default null
  , iLOT_PLAN_END_DTE_MAX       in date default null
  , iDOC_RECORD_FROM            in number default null
  , iDOC_RECORD_TO              in number default null
  , iSTM_STOCK_ID               in number default null
  , iLPT_ORACLE_SESSION         in varchar2 default null
  , iCFabType                   in varchar2 default null
  )
  is
  begin
    -- Réservation des propositions
    FAL_PRC_RETRIEVE_MANUF_PROP.ReserveManufacturingProp(iGCO_GOOD_ID
                                                       , iGOOD_CATEGORY_WORDING_FROM
                                                       , iGOOD_CATEGORY_WORDING_TO
                                                       , iDIC_GOOD_FAMILY_FROM
                                                       , iDIC_GOOD_FAMILY_TO
                                                       , iDIC_ACCOUNTABLE_GROUP_FROM
                                                       , iDIC_ACCOUNTABLE_GROUP_TO
                                                       , iDIC_GOOD_LINE_FROM
                                                       , iDIC_GOOD_LINE_TO
                                                       , iDIC_GOOD_GROUP_FROM
                                                       , iDIC_GOOD_GROUP_TO
                                                       , iDIC_GOOD_MODEL_FROM
                                                       , iDIC_GOOD_MODEL_TO
                                                       , iDIC_LOT_PROP_FREE
                                                       , iC_PREFIX_PROP
                                                       , iLOT_PLAN_BEGIN_DTE_MIN
                                                       , iLOT_PLAN_BEGIN_DTE_MAX
                                                       , iLOT_PLAN_END_DTE_MIN
                                                       , iLOT_PLAN_END_DTE_MAX
                                                       , iDOC_RECORD_FROM
                                                       , iDOC_RECORD_TO
                                                       , iSTM_STOCK_ID
                                                       , iLPT_ORACLE_SESSION
                                                       , iCFabType
                                                        );

    -- Champs propres au propositions de sous-traitance d'achat
    for tplPropTemp in (select LPT.FAL_LOT_PROP_TEMP_ID
                             , TAL.PAC_SUPPLIER_PARTNER_ID
                          from FAL_LOT_PROP_TEMP LPT
                             , FAL_TASK_LINK_PROP TAL
                         where LPT.LPT_ORACLE_SESSION = iLPT_ORACLE_SESSION
                           and LPT.C_FAB_TYPE = FAL_BATCH_FUNCTIONS.btSubcontract
                           and LPT.FAL_LOT_PROP_TEMP_ID = TAL.FAL_LOT_PROP_ID) loop
      update FAL_LOT_PROP_TEMP
         set PAC_SUPPLIER_PARTNER_ID = tplPropTemp.PAC_SUPPLIER_PARTNER_ID
       where FAL_LOT_PROP_TEMP_ID = tplPropTemp.FAL_LOT_PROP_TEMP_ID;
    end loop;
  end ReserveSubContractingpProp;

  /**
  * procedure RetrieveSubContractPProp
  * Description : Reprise des propositions de sous-traitance d'achat sélectionnées
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iLPT_ORACLE_SESSION : Session
  * @param   iCGenerateDocumentMode : Mode de génération des documents
  * @param   iCGeneratePositionMode : Mode des positions de documents
  * @param   iDocGenOrderFields : Liste de champs pour un ordre particulier de reprise des props
  */
  procedure RetrieveSubContractPProp(
    iLPT_ORACLE_SESSION    in varchar2
  , iCGenerateDocumentMode in varchar2 default 1
  , iCGeneratePositionMode in varchar2 default 1
  , iDocGenOrderFields     in varchar2 default null
  )
  is
    lvQrySelectProp           varchar2(2000);
    lvListOfProp              varchar2(32000);
    lblnFirstProp             boolean;
    ltMergedProposition       FAL_PRC_RETRIEVE_MANUF_PROP.TPropositions;
    lnFalJobProgramId         number;
    lnFalLotId                number;
    lnDocGaugeId              number;
    lnDocDocumentId           number;
    lnDocPositionId           number;
    ltGcoComplDataSubcontract GCO_COMPL_DATA_SUBCONTRACT%rowtype;
    ltmpErrorMsg              varchar2(4000);
    lvBatchRefCompl           FAL_LOT.LOT_REFCOMPL%type;
  begin
    -- Suppression des informations de progression :
    delete from COM_LIST_ID_TEMP
          where LID_CODE = FAL_PRC_FAL_PROP_COMMON.cstProgressInfoCode;

    -- Construction de la requète de sélection des propositions
    lvQrySelectProp  :=
      ' select LPT.FAL_LOT_PROP_TEMP_ID ' ||
      '      , GOO.DIC_GOOD_GROUP_ID ' ||
      '      , LPT.DIC_ACCOUNTABLE_GROUP_ID ' ||
      '      , LPT.DOC_RECORD_ID ' ||
      '      , GOO.GOO_MAJOR_REFERENCE ' ||
      '      , LPT.DIC_FAB_CONDITION_ID ' ||
      '      , LPT.DIC_FAMILY_ID ' ||
      '      , LPT.C_PRIORITY ' ||
      '      , LPT.STM_STOCK_ID ' ||
      '      , LPT.STM_STM_STOCK_ID ' ||
      '      , LPT.STM_LOCATION_ID ' ||
      '      , LPT.STM_STM_LOCATION_ID ' ||
      '      , LPT.GCO_GOOD_ID ' ||
      '      , LPT.LOT_ASKED_QTY ' ||
      '      , LPT.LOT_REJECT_PLAN_QTY ' ||
      '      , LPT.LOT_TOTAL_QTY ' ||
      '      , LPT.LOT_ORT_UPDATE_DELAY ' ||
      '      , LPT.LOT_PLAN_END_DTE ' ||
      '      , LPT.LOT_PLAN_BEGIN_DTE ' ||
      '      , LOT_TOLERANCE ' ||
      '      , LOT_CPT_CHANGE ' ||
      '      , LOT_SHORT_DESCR ' ||
      '      , LOT_PLAN_LEAD_TIME ' ||
      '      , FAL_SCHEDULE_PLAN_ID ' ||
      '      , null FAL_JOB_PROGRAM_ID ' ||
      '      , null FAL_ORDER_ID ' ||
      '      , LPT.PAC_SUPPLIER_PARTNER_ID ' ||
      '      , C_PREFIX_PROP ' ||
      '      , TAL.GCO_GOOD_ID ' ||
      '      , LPT.GCO_CHARACTERIZATION1_ID ' ||
      '      , LPT.GCO_CHARACTERIZATION2_ID ' ||
      '      , LPT.GCO_CHARACTERIZATION3_ID ' ||
      '      , LPT.GCO_CHARACTERIZATION4_ID ' ||
      '      , LPT.GCO_CHARACTERIZATION5_ID ' ||
      '      , LPT.FAD_CHARACTERIZATION_VALUE_1 ' ||
      '      , LPT.FAD_CHARACTERIZATION_VALUE_2 ' ||
      '      , LPT.FAD_CHARACTERIZATION_VALUE_3 ' ||
      '      , LPT.FAD_CHARACTERIZATION_VALUE_4 ' ||
      '      , LPT.FAD_CHARACTERIZATION_VALUE_5 ' ||
      '      , null GROUPFIELD ' ||
      '      , LPT.LOT_NUMBER ' ||
      '   from FAL_LOT_PROP_TEMP LPT ' ||
      '      , GCO_GOOD GOO ' ||
      '      , FAL_TASK_LINK_PROP TAL ' ||
      '  where LPT.FAD_SELECT = 1 ' ||
      '    and LPT.GCO_GOOD_ID = GOO.GCO_GOOD_ID ' ||
      '    and LPT.FAL_LOT_PROP_TEMP_ID = TAL.FAL_LOT_PROP_ID ' ||
      '    and LPT.LPT_ORACLE_SESSION = :LPT_ORACLE_SESSION ' ||
      ' order by LPT.FAD_SELECT ';

    -- Ordre de reprise particulier des propositions (origine = paramètre d'objet LOT_GEN_ORDER_FIELDS)
    if iDocGenOrderFields is not null then
      lvQrySelectProp  := lvQrySelectProp || ', ' || replace(iDocGenOrderFields, ';', ',');
    else
      lvQrySelectProp  := lvQrySelectProp || ', GOO_MAJOR_REFERENCE, STM_STOCK_ID';
    end if;

    -- Sélection des propositions à traiter
    execute immediate lvQrySelectProp
    bulk collect into oTabSelectedProp
                using iLPT_ORACLE_SESSION;

    if oTabSelectedProp.count > 0 then
      FAL_PRC_FAL_PROP_COMMON.PushInfoUser(PCS.PC_FUNCTIONS.TranslateWord('Nbre de propositions sélectionnées') || ' : ' || oTabSelectedProp.count);
      FAL_PRC_FAL_PROP_COMMON.PushInfoUser('');
      FAL_PRC_FAL_PROP_COMMON.PushInfoUser(PCS.PC_FUNCTIONS.TranslateWord('Génération des commandes d''achats sous-traitance') || '...');
      -- Recherche / Création du programme dédié à la sous-traitance
      lnFalJobProgramId  := FAL_LIB_PROGRAM.GetJobProgramId(FAL_LIB_SUBCONTRACTP.GetProgramNumber);

      if lnFalJobProgramId is null then
        lnFalJobProgramId  :=
              FAL_PROGRAM_FUNCTIONS.CreateSubContractProgram(FAL_LIB_SUBCONTRACTP.GetProgramNumber, PCS.PC_FUNCTIONS.TranslateWord('Sous-traitance d''achat') );
      end if;

      -- Génération d'un document par proposition
      if iCGenerateDocumentMode = cgdOneDocByProp then
        for i in oTabSelectedProp.first .. oTabSelectedProp.last loop
          -- Recherche gabarit
          lnDocGaugeId                            := GetSUPODocGaugeID(oTabSelectedProp(i).C_PREFIX_PROP, FAL_LIB_MRP_CALCULATION.csmSubcontractPurchasePdt);
          -- Génération du lot de fabrication.
          oTabSelectedProp(i).FAL_JOB_PROGRAM_ID  := lnFalJobProgramId;
          oTabSelectedProp(i).FAL_ORDER_ID        :=
            GetSubcontractPOrder(lnFalJobProgramId
                               , oTabSelectedProp(i).PAC_SUPPLIER_PARTNER_ID
                               , oTabSelectedProp(i).GCO_GOOD_ID
                               , oTabSelectedProp(i).DOC_RECORD_ID
                                );
          lnFalLotId                              :=
            FAL_PRC_RETRIEVE_MANUF_PROP.CreateBatchFromProp(oProposition             => oTabSelectedProp(i)
                                                          , iCFabType                => FAL_LIB_MRP_CALCULATION.csmSubcontractPurchasePdt
                                                          , icGeneratePositionMode   => icGeneratePositionMode
                                                          , iGcoGcoGoodId            => oTabSelectedProp(i).GCO_GCO_GOOD_ID
                                                           );
          lnDocDocumentId                         := null;
          -- Génération du document.
          GenerateSUPODocument(lnDocDocumentId, lnDocGaugeId, oTabSelectedProp(i).PAC_SUPPLIER_PARTNER_ID, oTabSelectedProp(i).DOC_RECORD_ID);
          lnDocPositionId                         := null;
          -- Génération de la position.
          GenerateSUPOPosition(lnDocPositionId
                             , lnDocDocumentId
                             , oTabSelectedProp(i).GCO_GCO_GOOD_ID
                             , oTabSelectedProp(i).GCO_GOOD_ID
                             , oTabSelectedProp(i).LOT_TOTAL_QTY
                             , oTabSelectedProp(i).DOC_RECORD_ID
                             , oTabSelectedProp(i).LOT_PLAN_BEGIN_DTE
                             , oTabSelectedProp(i).LOT_PLAN_END_DTE
                             , oTabSelectedProp(i).LOT_PLAN_END_DTE
                             , lnFalLotId
                              );
          -- Mise à jour du numéro de lot
          lvBatchRefCompl                         := UpdateBatchRefCompl(lnFalLotId, lnDocPositionId);
          -- Info de progression
          FAL_PRC_FAL_PROP_COMMON.PushInfoUser('   . ' || oTabSelectedProp(i).C_PREFIX_PROP || oTabSelectedProp(i).LOT_NUMBER || ' -> ' || lvBatchRefCompl);
          -- Finalisation du document.
          DOC_FINALIZE.FinalizeDocument(lnDocDocumentId, 1, 1, 1);
        end loop;
      -- Génération d'un document par fournisseur
      else
        -- Pour chaque fournisseur / Gabarit associé (peut être différent suivant POAST ou PDAST)
        for tplDocBySupplier in (select distinct PAC_SUPPLIER_PARTNER_ID
                                               , GetSUPODocGaugeID(C_PREFIX_PROP, FAL_LIB_MRP_CALCULATION.csmSubcontractPurchasePdt) DOC_GAUGE_ID
                                            from table(GetPropositionsTable) ) loop
          -- Génération du document
          lnDocDocumentId  := null;
          GenerateSUPODocument(lnDocDocumentId, tplDocBySupplier.DOC_GAUGE_ID, tplDocBySupplier.PAC_SUPPLIER_PARTNER_ID, null);

          -- Si une proposition = une position
          if iCGeneratePositionMode = cgpOnePosByProp then
            for tplPropToMerge in (select *
                                     from table(GetPropositionsTable)
                                    where PAC_SUPPLIER_PARTNER_ID = tplDocBySupplier.PAC_SUPPLIER_PARTNER_ID
                                      and GetSUPODocGaugeID(C_PREFIX_PROP, FAL_LIB_MRP_CALCULATION.csmSubcontractPurchasePdt) = tplDocBySupplier.DOC_GAUGE_ID) loop
              -- Génération du lot de fabrication.
              ltMergedProposition                     := GetPropositionFromTable(tplPropToMerge.FAL_LOT_PROP_TEMP_ID);
              ltMergedProposition.FAL_JOB_PROGRAM_ID  := lnFalJobProgramId;
              ltMergedProposition.FAL_ORDER_ID        :=
                      GetSubcontractPOrder(lnFalJobProgramId, tplPropToMerge.PAC_SUPPLIER_PARTNER_ID, tplPropToMerge.GCO_GOOD_ID, tplPropToMerge.DOC_RECORD_ID);
              lnFalLotId                              :=
                FAL_PRC_RETRIEVE_MANUF_PROP.CreateBatchFromProp(oProposition             => ltMergedProposition
                                                              , iCFabType                => FAL_LIB_MRP_CALCULATION.csmSubcontractPurchasePdt
                                                              , icGeneratePositionMode   => icGeneratePositionMode
                                                              , iGcoGcoGoodId            => ltMergedProposition.GCO_GCO_GOOD_ID
                                                               );
              -- Génération de la position
              lnDocPositionId                         := null;
              GenerateSUPOPosition(lnDocPositionId
                                 , lnDocDocumentId
                                 , ltMergedProposition.GCO_GCO_GOOD_ID
                                 , ltMergedProposition.GCO_GOOD_ID
                                 , ltMergedProposition.LOT_TOTAL_QTY
                                 , ltMergedProposition.DOC_RECORD_ID
                                 , ltMergedProposition.LOT_PLAN_BEGIN_DTE
                                 , ltMergedProposition.LOT_PLAN_END_DTE
                                 , ltMergedProposition.LOT_PLAN_END_DTE
                                 , lnFalLotId
                                  );
              -- Mise à jour du numéro de lot
              lvBatchRefCompl                         := UpdateBatchRefCompl(lnFalLotId, lnDocPositionId);
              -- Info de progression
              FAL_PRC_FAL_PROP_COMMON.PushInfoUser('   . ' || ltMergedProposition.C_PREFIX_PROP || ltMergedProposition.LOT_NUMBER || ' -> ' || lvBatchRefCompl);
            end loop;
          -- Sinon fusion des propositions
          else
            lblnFirstProp  := true;
            lvListOfProp   := null;

            -- fusion
            for tplPropToMerge in (select *
                                     from table(GetPropositionsTable)
                                    where PAC_SUPPLIER_PARTNER_ID = tplDocBySupplier.PAC_SUPPLIER_PARTNER_ID
                                      and GetSUPODocGaugeID(C_PREFIX_PROP, FAL_LIB_MRP_CALCULATION.csmSubcontractPurchasePdt) = tplDocBySupplier.DOC_GAUGE_ID) loop
              -- information de progression
              FAL_PRC_FAL_PROP_COMMON.PushInfoUser('   . ' ||
                                                   PCS.PC_FUNCTIONS.TranslateWord('Fusion proposition') ||
                                                   ' : ' ||
                                                   tplPropToMerge.C_PREFIX_PROP ||
                                                   tplPropToMerge.LOT_NUMBER
                                                  );

              -- Récupération de la première proposition
              if lblnFirstProp then
                ltMergedProposition  := GetPropositionFromTable(tplPropToMerge.FAL_LOT_PROP_TEMP_ID);
                lblnFirstProp        := false;
              -- ou fusion dans la première proposition
              else
                ltMergedProposition.LOT_ASKED_QTY         := nvl(ltMergedProposition.LOT_ASKED_QTY, 0) + nvl(tplPropToMerge.LOT_ASKED_QTY, 0);
                ltMergedProposition.LOT_REJECT_PLAN_QTY   := nvl(ltMergedProposition.LOT_REJECT_PLAN_QTY, 0) + nvl(tplPropToMerge.LOT_REJECT_PLAN_QTY, 0);
                ltMergedProposition.LOT_TOTAL_QTY         := nvl(ltMergedProposition.LOT_TOTAL_QTY, 0) + nvl(tplPropToMerge.LOT_TOTAL_QTY, 0);
                ltMergedProposition.LOT_ORT_UPDATE_DELAY  := 0;

                -- Fusion plus petit délai final
                if iCGeneratePositionMode = cgpMergeSmallestEndDelay then
                  if    ltMergedProposition.LOT_PLAN_END_DTE is null
                     or tplPropToMerge.LOT_PLAN_END_DTE < ltMergedProposition.LOT_PLAN_END_DTE then
                    ltMergedProposition.LOT_PLAN_END_DTE  := tplPropToMerge.LOT_PLAN_END_DTE;
                  end if;
                -- Fusion plus grand délai final
                elsif iCGeneratePositionMode = cgpMergeLargestEndDelay then
                  if    ltMergedProposition.LOT_PLAN_END_DTE is null
                     or tplPropToMerge.LOT_PLAN_END_DTE > ltMergedProposition.LOT_PLAN_END_DTE then
                    ltMergedProposition.LOT_PLAN_END_DTE  := tplPropToMerge.LOT_PLAN_END_DTE;
                  end if;
                end if;
              end if;

              -- Sauvegarde de la liste des propositions de la fusion
              lvListOfProp  := nvl(lvListOfProp, '0') || ',' || tplPropToMerge.FAL_LOT_PROP_TEMP_ID;
            end loop;

            -- Génération du lot de fabrication.
            if lvListOfProp is not null then
              ltMergedProposition.FAL_JOB_PROGRAM_ID  := lnFalJobProgramId;
              ltMergedProposition.FAL_ORDER_ID        :=
                GetSubcontractPOrder(lnFalJobProgramId
                                   , ltMergedProposition.PAC_SUPPLIER_PARTNER_ID
                                   , ltMergedProposition.GCO_GOOD_ID
                                   , ltMergedProposition.DOC_RECORD_ID
                                    );
              lnFalLotId                              :=
                FAL_PRC_RETRIEVE_MANUF_PROP.CreateBatchFromProp(oProposition             => ltMergedProposition
                                                              , iListOfPropID            => lvListOfProp
                                                              , iCFabType                => FAL_LIB_MRP_CALCULATION.csmSubcontractPurchasePdt
                                                              , icGeneratePositionMode   => icGeneratePositionMode
                                                              , iGcoGcoGoodId            => ltMergedProposition.GCO_GCO_GOOD_ID
                                                               );
              -- Génération de la position
              lnDocPositionId                         := null;
              GenerateSUPOPosition(lnDocPositionId
                                 , lnDocDocumentId
                                 , ltMergedProposition.GCO_GCO_GOOD_ID
                                 , ltMergedProposition.GCO_GOOD_ID
                                 , ltMergedProposition.LOT_TOTAL_QTY
                                 , ltMergedProposition.DOC_RECORD_ID
                                 , ltMergedProposition.LOT_PLAN_BEGIN_DTE
                                 , ltMergedProposition.LOT_PLAN_END_DTE
                                 , ltMergedProposition.LOT_PLAN_END_DTE
                                 , lnFalLotId
                                  );
              -- Mise à jour du numéro de lot
              lvBatchRefCompl                         := UpdateBatchRefCompl(lnFalLotId, lnDocPositionId);
              -- Info de progression
              FAL_PRC_FAL_PROP_COMMON.PushInfoUser('      . ' || PCS.PC_FUNCTIONS.TranslateWord('Position générée') || ' -> ' || lvBatchRefCompl);
            end if;
          end if;

          -- Finalisation du document.
          DOC_FINALIZE.FinalizeDocument(lnDocDocumentId, 1, 1, 1);
        end loop;
      end if;
    end if;
  end RetrieveSubContractPProp;

  /**
  * procedure GetGcoComplDataSubcPInfo
  * Description : Recherche d'infos complémentaires dans les données compl. de
  *               sous-traitance, liées à la condition de sous-traitance et au
  *               fournisseur
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iDateValidity : Date validité
  * @param   iGcoGoodId : bien sous-traité
  * @param   ioDicFabConditionId : Condition de fabrication
  * @param   ioPacSupplierPartnerID : Fournisseur
  * @param   ioGcoBindedServiceId : Service lié
  */
  procedure GetGcoComplDataSubcPInfo(
    iDateValidity          in     date
  , iGcoGoodId             in     number
  , ioDicFabConditionId    in out varchar2
  , ioPacSupplierPartnerID in out number
  , ioGcoBindedServiceId   in out number
  )
  is
  begin
    for tplComplData in (select   CSU.DIC_FAB_CONDITION_ID
                                , CSU.PAC_SUPPLIER_PARTNER_ID
                                , GCO_GCO_GOOD_ID
                             from GCO_COMPL_DATA_SUBCONTRACT CSU
                            where (    (    ioDicFabConditionId is null
                                        and CSU.PAC_SUPPLIER_PARTNER_ID = ioPacSupplierPartnerId)
                                   or (    nvl(ioPacSupplierPartnerId, 0) = 0
                                       and CSU.DIC_FAB_CONDITION_ID = ioDicFabConditionId)
                                  )
                              and nvl(CSU.CSU_VALIDITY_DATE, iDateValidity) <= iDateValidity
                              and CSU.GCO_GOOD_ID = iGcoGoodId
                         order by CSU.CSU_VALIDITY_DATE desc
                                , CSU.CSU_DEFAULT_SUBCONTRACTER asc) loop
      ioDicFabConditionId     := tplComplData.DIC_FAB_CONDITION_ID;
      ioPacSupplierPartnerID  := tplComplData.PAC_SUPPLIER_PARTNER_ID;
      ioGcoBindedServiceId    := tplComplData.GCO_GCO_GOOD_ID;
      exit;
    end loop;
  end GetGcoComplDataSubcPInfo;

  /**
  * procedure ControlGcoComplDataSubcp
  * Description : Fonction de contrôle des données complémentaires de sous traitance
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   ioReport : Rapport de contrôle
  * @param   iGoodControl : Contrôle produit
  * @param   iPropControl : Contrôle propositions
  * @param   iOnlySelectedProp : Seulement pour les biens des propositions sélectionnées
  * @param   iLptOracleSession : Session Oracle
  * @param   iUnFlagInvalidProp : Désélection des propositions invalides
  */
  procedure ControlGcoComplDataSubcp(
    ioReport           in out clob
  , iGoodControl       in     integer default 1
  , iPropControl       in     integer default 0
  , iOnlySelectedProp  in     integer default 0
  , iLptOracleSession  in     varchar2
  , iUnFlagInvalidProp in     integer default 0
  )
  is
    lvInexistantValidData varchar2(32000);
    lvInconsistantData    varchar2(32000);
    lvTmpError            varchar2(255);
    lbCanUpdateProp       integer;
  begin
    ioReport               := empty_clob;
    lvInexistantValidData  := null;
    lvInconsistantData     := null;

    -- Contrôle des propositions de sous-traitance, sélectionnées ou toutes
    if iPropControl = 1 then
      for TplPropositions in (select (LOP.C_PREFIX_PROP || ' ' || LOP.LOT_NUMBER) LOT_NUMBER
                                   , GOO.GOO_MAJOR_REFERENCE
                                   , LOP.FAL_LOT_PROP_TEMP_ID
                                   , GCO_LIB_COMPL_DATA.GetDefaultSubCComplDataID(LOP.GCO_GOOD_ID, LOP.PAC_SUPPLIER_PARTNER_ID, null, LOP.LOT_PLAN_BEGIN_DTE)
                                                                                                                                                    GCDSP_EXIST
                                from FAL_LOT_PROP_TEMP LOP
                                   , GCO_GOOD GOO
                               where LOP.LPT_ORACLE_SESSION = iLptOracleSession
                                 and LOP.GCO_GOOD_ID = GOO.GCO_GOOD_ID
                                 and LOP.FAD_SELECT = iOnlySelectedProp
                                 and LOP.C_FAB_TYPE = FAL_BATCH_FUNCTIONS.btSubcontract) loop
        LbCanUpdateProp  := 0;

        -- Pas de donnée complémentaire valide
        if TplPropositions.GCDSP_EXIST is null then
          lvInexistantValidData  :=
                             lvInexistantValidData || CO.cLineBreak ||
--             '   . ' ||
--             PCS.PC_FUNCTIONS.TranslateWord('Proposition') ||
--             ' : ' ||
--             TplPropositions.LOT_NUMBER ||
--             ' / ' ||
                                                                      PCS.PC_FUNCTIONS.TranslateWord('produit') || ' : ' || TplPropositions.GOO_MAJOR_REFERENCE;
          LbCanUpdateProp        := 1;
        -- Recherche incohérences
        else
          lvTmpError  := null;
          lvTmpError  := PPS_I_LIB_FUNCTIONS.checkSubcontractPComplData(TplPropositions.GCDSP_EXIST);

          if lvTmpError is not null then
            lvInconsistantData  :=
              lvInconsistantData ||
              CO.cLineBreak ||
--               '   . ' ||
--               PCS.PC_FUNCTIONS.TranslateWord('Proposition') ||
--               ' : ' ||
--               TplPropositions.LOT_NUMBER ||
--               ' / ' ||
              PCS.PC_FUNCTIONS.TranslateWord('produit') ||
              ' : ' ||
              TplPropositions.GOO_MAJOR_REFERENCE ||
              ' / ' ||
              PCS.PC_FUNCTIONS.TranslateWord('erreur') ||
              ' : ' ||
              lvTmpError;
            LbCanUpdateProp     := 1;
          end if;
        end if;

        if     LbCanUpdateProp = 1
           and iUnFlagInvalidProp = 1 then
          declare
            ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
          begin
            FWK_I_MGT_ENTITY.new(FWK_TYP_FAL_ENTITY.gcfallotproptemp, ltCRUD_DEF, true);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FAL_LOT_PROP_TEMP_ID', TplPropositions.FAL_LOT_PROP_TEMP_ID);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FAD_SELECT', 0);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_DATEMOD', sysdate);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_IDMOD', PCS.PC_I_LIB_SESSION.GetUserIni);
            FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
            FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
          end;
        end if;
      end loop;
    end if;

    -- Formattage rapport
    if lvInexistantValidData is not null then
      ioReport  :=
               PCS.PC_FUNCTIONS.TranslateWord('Aucune donnée complémentaire de sous-traitance trouvée pour la date du besoin') || ' : '
               || lvInexistantValidData;
    end if;

    if lvInconsistantData is not null then
      ioReport  :=
             ioReport || chr(10) || chr(13) || PCS.PC_FUNCTIONS.TranslateWord('Données complémentaires de sous-traitance erronées') || ' : '
             || lvInconsistantData;
    end if;
  end ControlGcoComplDataSubcp;
end;
