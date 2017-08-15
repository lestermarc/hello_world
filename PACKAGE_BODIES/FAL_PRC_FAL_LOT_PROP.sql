--------------------------------------------------------
--  DDL for Package Body FAL_PRC_FAL_LOT_PROP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_FAL_LOT_PROP" 
is
  -- Configurations
  cfgFAL_TOLERANCE    varchar2(255) := PCS.PC_CONFIG.GetConfig('FAL_TOLERANCE');
  cfgFAL_COUPLED_GOOD varchar2(255) := PCS.PC_CONFIG.GetConfig('FAL_COUPLED_GOOD');

  /**
  * procedure UpdatePropCounters
  * Description : Mise à jour des compteurs des numéros de propositions
  * @created ECA
  * @lastUpdate
  * @private
  * @param
  */
  procedure UpdatePropCounters
  is
  begin
    -- Propositions de fabrication

    -- C_PROP_TYPE = 1 et   C_SUPPLY_MODE = 2
    if not FAL_PRC_FAL_PROP_COMMON.PropositionExists('FAL_LOT_PROP', '1', '2') then
      FAL_PRC_FAL_PROP_COMMON.UpdatePropDefinition('1', '2');
    end if;

    -- C_PROP_TYPE = 2 et   C_SUPPLY_MODE = 2
    if not FAL_PRC_FAL_PROP_COMMON.PropositionExists('FAL_LOT_PROP', '2', '2') then
      FAL_PRC_FAL_PROP_COMMON.UpdatePropDefinition('2', '2');
    end if;

    -- C_PROP_TYPE = 1  C_SUPPLY_MODE = 4
    if not FAL_PRC_FAL_PROP_COMMON.PropositionExists('FAL_LOT_PROP', '1', '4') then
      FAL_PRC_FAL_PROP_COMMON.UpdatePropDefinition('1', '4');
    end if;

    -- C_PROP_TYPE = 3  C_SUPPLY_MODE = 2
    if not FAL_PRC_FAL_PROP_COMMON.PropositionExists('FAL_LOT_PROP', '3', '2') then
      FAL_PRC_FAL_PROP_COMMON.UpdatePropDefinition('3', '2');
    end if;

    -- C_PROP_TYPE = 3  C_SUPPLY_MODE = 4
    if not FAL_PRC_FAL_PROP_COMMON.PropositionExists('FAL_LOT_PROP', '3', '4') then
      FAL_PRC_FAL_PROP_COMMON.UpdatePropDefinition('3', '4');
    end if;
  end UpdatePropCounters;

  /**
  * procedure DeleteFAL_LOT_PROP
  * Description : Suppression des propositions d'appro fabrication qui ne sont
  *               ni demandes d'appro, ni issues du pic.
  * @created ECA
  * @lastUpdate
  * @private
  * @param   iGCO_GOOD_ID : Produit (Si null, pour tous)
  * @param   iListOfStockId : Liste des stock du CB (pour restriction de la suppression)
  * @param   iDeletePropMode : Mode suppresion proposition
  * @param   iDeleteRequestMode : Mode suppression demande d'appro
  * @param   iUpdateRequestvalueMode : Mode Mise à jour demande d'appro
  * @param   iPropOrigin : Origine de la proposition
  * @param   iDeleteWithDate : Suppression proposition plan directeur postérieur à
  * @param   iDate : Date pour suppression à partir de
  */
  procedure DeleteFAL_LOT_PROP(
    iGCO_GOOD_ID            in number
  , iListOfStockId          in varchar2 default null
  , iDeletePropMode         in integer default 0
  , iDeleteRequestMode      in integer default 0
  , iUpdateRequestvalueMode in integer default 0
  , iPropOrigin             in integer default 0
  , iDeleteWithdate         in integer default 0
  , iDate                   in date default null
  )
  is
    type T_TABLE_ID is table of number;

    T_FAL_LOT_PROP_ID T_TABLE_ID;
    vQuery            varchar2(2000);
  begin
    -- Propositions standards
    if iPropOrigin = FAL_PRC_FAL_PROP_COMMON.STD_PROP then
      vQuery  := ' select FAL_LOT_PROP_ID ' || '   from FAL_LOT_PROP ' || '  where FAL_PIC_ID IS NULL ' || '    and FAL_SUPPLY_REQUEST_ID IS NULL ';
    -- Propositions issues des demandes d'appro
    elsif iPropOrigin = FAL_PRC_FAL_PROP_COMMON.REQUEST_PROP then
      vQuery  := ' select FAL_LOT_PROP_ID ' || '   from FAL_LOT_PROP ' || '  where FAL_PIC_ID IS NULL ' || '    and FAL_SUPPLY_REQUEST_ID IS NOT NULL ';
    -- Propositions de fabrication issues du plan directeur
    elsif iPropOrigin = FAL_PRC_FAL_PROP_COMMON.PDF_PROP then
      vQuery  :=
        ' select FAL_LOT_PROP_ID ' ||
        '   from FAL_LOT_PROP ' ||
        '  where FAL_SUPPLY_REQUEST_ID is null ' ||
        '    and FAL_PIC_ID is not null ' ||
        '    and (:DeleteWithdate = 0 ' ||
        '          or (:DeleteWithdate = 1 and LOT_PLAN_BEGIN_DTE > :iDATE)) ';
    -- Propositions d'achat issues du calcul des besoins
    elsif iPropOrigin = FAL_PRC_FAL_PROP_COMMON.POAST_PROP then
      vQuery  :=
        ' select FAL_LOT_PROP_ID ' ||
        '   from FAL_LOT_PROP ' ||
        '  where FAL_SUPPLY_REQUEST_ID is null ' ||
        '    and FAL_PIC_ID is null ' ||
        '    and C_FAB_TYPE = ''4'' ';
    -- Propositions d'achat issues du plan directeur
    elsif iPropOrigin = FAL_PRC_FAL_PROP_COMMON.PDAST_PROP then
      vQuery  :=
        ' select FAL_LOT_PROP_ID ' ||
        '   from FAL_LOT_PROP ' ||
        '  where FAL_SUPPLY_REQUEST_ID is null ' ||
        '    and FAL_PIC_ID is not null ' ||
        '    and C_FAB_TYPE = ''4'' ' ||
        '    and (:DeleteWithdate = 0 ' ||
        '          or (:DeleteWithdate = 1 and LOT_PLAN_BEGIN_DTE > :iDATE)) ';
    -- Propositions issues des demandes d'appro, ou achat plan directeur
    elsif    iPropOrigin = FAL_PRC_FAL_PROP_COMMON.DRA_PROP
          or iPropOrigin = FAL_PRC_FAL_PROP_COMMON.PDA_PROP then
      return;
    end if;

    -- Restriction produit
    if nvl(iGCO_GOOD_ID, 0) <> 0 then
      vQuery  := vQuery || '    AND GCO_GOOD_ID = ' || iGCO_GOOD_ID;
    end if;

    -- Restriction Stocks destination
    if    nvl(iListOfStockId, '') <> ''
       or nvl(iListOfStockId, '') is not null then
      -- Stocks du CB
      vQuery  := vQuery || '    AND STM_STOCK_ID in (' || iListOfStockId || ')';
    end if;

    vQuery  := vQuery || '    FOR UPDATE OF FAL_LOT_PROP_ID';

    -- Sélection des propositions
    if    iPropOrigin = FAL_PRC_FAL_PROP_COMMON.PDF_PROP
       or iPropOrigin = FAL_PRC_FAL_PROP_COMMON.PDAST_PROP then
      execute immediate vQuery
      bulk collect into T_FAL_LOT_PROP_ID
                  using iDeleteWithDate, iDeleteWithDate, iDate;
    else
      execute immediate vQuery
      bulk collect into T_FAL_LOT_PROP_ID;
    end if;

    -- Suppression des propositions sélectionnées
    if T_FAL_LOT_PROP_ID.count > 0 then
      for i in T_FAL_LOT_PROP_ID.first .. T_FAL_LOT_PROP_ID.last loop
        DeleteOneFABProposition(T_FAL_LOT_PROP_ID(i), iDeletePropMode, iDeleteRequestMode, iUpdateRequestValueMode);
      end loop;
    end if;
  end DeleteFAL_LOT_PROP;

  /**
  * procedure DeleteOneFABProposition
  * Description : Suppression d'une proposition fabrication
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aPropID : proposition à supprimer
  * @param   aDeleteProp : Suppression ou non de la proposition
  * @param   aDeleteRequest : Suppression ou non de la demande d'approvisionnement
  * @param   aUpdateRequestValue : modification du status de la demande d'approvisionnement
  */
  procedure DeleteOneFABProposition(aPropID in number, aDeleteProp in integer, aDeleteRequest in integer, aUpdateRequestValue in integer)
  is
    aSupply    FAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID%type;
    aNeed      FAL_NETWORK_NEED.FAL_NETWORK_NEED_ID%type;
    aRequestID number;

    -- Lecture des FAL_NETWORK_NEED associés à la proposition de besoins donnée
    cursor GetNeedFromComponentPropFU(aComponentPropositionID in number)
    is
      select     FAL_NETWORK_NEED_ID
            from FAL_NETWORK_NEED
           where FAL_LOT_MAT_LINK_PROP_ID = aComponentPropositionID
      for update;

    -- Lecture de toutes les propositions de besoins Composants
    cursor GetComponentPropositions(aLotPropositionID in number)
    is
      select FAL_LOT_MAT_LINK_PROP_ID
        from FAL_LOT_MAT_LINK_PROP
       where FAL_LOT_PROP_ID = aLotPropositionID;

    -- Lecture des FAL_NETWORK_SUPPLY associés à la proposition d'appro LOT donnée
    cursor GetSupplyFromLOTPropositionFU(aLotPropositionID in number)
    is
      select     FAL_NETWORK_SUPPLY_ID
            from FAL_NETWORK_SUPPLY
           where FAL_LOT_PROP_ID = aLotPropositionID
      for update;

    -- Lecture des FAL_NETWORK_NEED associés à la proposition d'appro LOT donnée
    cursor GetNeedFromLOTPropositionFU(aLotPropositionID in number)
    is
      select     FAL_NETWORK_NEED_ID
            from FAL_NETWORK_NEED
           where FAL_LOT_PROP_ID = aLotPropositionID
      for update;
  begin
    -- Parcourir les FAL_NETWOK_SUPPLY associés à la proposition courante
    open GetSupplyFromLOTPropositionFU(aPropID);

    loop
      fetch GetSupplyFromLOTPropositionFU
       into aSupply;

      -- S'assurer qu'il y a un record
      exit when GetSupplyFromLOTPropositionFU%notfound;
      -- Suppression Attributions Appro-Stock
      FAL_NETWORK.Attribution_Suppr_ApproStock(aSupply);
      -- Suppression Attributions Appro-Besoin
      FAL_NETWORK.Attribution_Suppr_ApproBesoin(aSupply);

      -- Suppression du FAL_NETWORK_SUPPLY courant
      delete      FAL_NETWORK_SUPPLY
            where current of GetSupplyFromLOTPropositionFU;
    end loop;

    -- Refermer le curseur sur FAL_NETWORK_SUPPLY
    close GetSupplyFromLOTPropositionFU;

    -- Parcourir les FAL_NETWORK_NEED associés à la proposition courante
    open GetNeedFromLOTPropositionFU(aPropID);

    loop
      fetch GetNeedFromLOTPropositionFU
       into aNeed;

      -- S'assurer qu'il y a un record
      exit when GetNeedFromLOTPropositionFU%notfound;
      -- Suppression Attributions Besoin-Stock
      FAL_NETWORK.Attribution_Suppr_BesoinStock(aNeed);
      -- Suppression Attributions Besoin-Appro
      FAL_NETWORK.Attribution_Suppr_BesoinAppro(aNeed);

      -- Suppression du FAL_NETWORK_NEED courant
      delete      FAL_NETWORK_NEED
            where current of GetNeedFromLOTPropositionFU;
    end loop;

    -- Refermer le curseur sur FAL_NETWORK_NEED
    close GetNeedFromLOTPropositionFU;

    -- Parcourir toutes les propositions de besoins de FAL_LOT_MAT_LINK_PROP
    for aComponentProposition in GetComponentPropositions(aPropID) loop
      -- Parcourir les FAL_NETWORK_NEED associés à la proposition courante
      open GetNeedFromComponentPropFU(aComponentProposition.FAL_LOT_MAT_LINK_PROP_ID);

      loop
        fetch GetNeedFromComponentPropFU
         into aNeed;

        -- S'assurer qu'il y a un record
        exit when GetNeedFromComponentPropFU%notfound;
        -- Suppression Attribution Besoin Appro ...
        FAL_NETWORK.Attribution_Suppr_BesoinAppro(aNeed);

        -- Suppression du FAL_NETWORK_NEED courant
        delete      FAL_NETWORK_NEED
              where current of GetNeedFromComponentPropFU;
      end loop;

      -- Refermer le curseur sur FAL_NETWORK_NEED
      close GetNeedFromComponentPropFU;
    end loop;

    -- Détruire les composants de la proposition
    delete from FAL_LOT_MAT_LINK_PROP
          where FAL_LOT_PROP_ID = aPropID;

    -- Détruire les opérations de la proposition
    delete from FAL_TASK_LINK_PROP
          where FAL_LOT_PROP_ID = aPropID;

    -- Si la destruction de la demande éventuellement associée est demandée, récupérer l'ID de la demande associée
    aRequestID  := null;

    if    (aDeleteRequest = FAL_PRC_FAL_PROP_COMMON.DELETE_REQUEST)
       or (nvl(aUpdateRequestvalue, 0) <> FAL_PRC_FAL_PROP_COMMON.NO_UPDATE_REQUEST) then
      -- Récupérer l'ID de la demande
      select max(FAL_SUPPLY_REQUEST_ID)
        into aRequestID
        from FAL_LOT_PROP
       where FAL_LOT_PROP_ID = aPropID;
    end if;

    -- Destruction de la proposition de fabrication si souhaité
    if aDeleteProp = FAL_PRC_FAL_PROP_COMMON.DELETE_PROP then
      delete from FAL_LOT_PROP
            where FAL_LOT_PROP_ID = aPropID;

      delete from FAL_LOT_PROP_TEMP
            where FAL_LOT_PROP_TEMP_ID = aPropID;
    end if;

    -- Si la modif de la demande éventuellement associée est demandée la modifier
    if nvl(aUpdateRequestvalue, 0) <> FAL_PRC_FAL_PROP_COMMON.NO_UPDATE_REQUEST then
      -- Updater la Request
      update FAL_SUPPLY_REQUEST
         set C_REQUEST_STATUS = aUpdateRequestvalue
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_LOT_PROP_ID = aPropID
          or (FAL_SUPPLY_REQUEST_ID = nvl(aRequestId, 0) );
    end if;

    -- Si la destruction de la demande éventuellement associée est demandée la détruire
    if aDeleteRequest = FAL_PRC_FAL_PROP_COMMON.DELETE_REQUEST then
      -- Détruire la Request
      delete from FAL_SUPPLY_REQUEST
            where FAL_LOT_PROP_ID = aPropID
               or (FAL_SUPPLY_REQUEST_ID = nvl(aRequestId, 0) );
    end if;

    -- Suppression également de la proposition de la table temporaire
    delete from fal_lot_prop_temp
          where fal_lot_prop_temp_id = aPropid;
  end DeleteOneFABProposition;

  /**
  * procedure : CreateFalLotProp
  * Description : Création de proposition d'approvisionnement de fabrication
  *
  * @created
  * @lastUpdate ECA
  * @public
  * @param   ioFalLotPropID : ID proposition
  * @param   ioDocRecordID : Dossier
  * @param   ioStockConsoID : Stock consommation
  * @param   ioFalNetworkSupplyId : réseau appro créé
  * @param   iCSupplyMode : Mode d'approvisionnement
  * @param   icSchedulePlanCode : Code planification
  * @param   iDicFabConditionID : Condition de fabrication
  * @param   iFalSchedulePlanID : Gamme
  * @param   iFalSchedPlanIDFromNom : Gamme liées à la nomenclature
  * @param   iCTypeProp : Type de proposition
  * @param   iFalNetworkNeedID : besoin
  * @param   iGcoGoodID : Bien
  * @param   iOriginStockID : Stock origine
  * @param   iOriginLocationID : Emplacement origine
  * @param   iTargetStockID : Stock Destination
  * @param   iTargetLocationID : Emplacement Destination
  * @param   iNeedDate : Date besoin
  * @param   iAskedQty : Qté demandée
  * @param   iPlannedTrashQty : Qté rebut
  * @param   iCharacterizations_ID1...ID2 : ID caractérisations
  * @param   iCharacterizations_VA1...VA5 : Valeurs de caractérisations
  * @param   iCalculByStock : Calcul par stock
  * @param   iText : Description
  * @param   iSupplyRequestID : Dmeande d'approvisionnement
  * @param   iIsCallByNeedCalculation : Context d'exécution
  * @param   iDOC_RECORD_ID : Dossier
  * @param   iFAL_PIC_LINE_ID : Ligne de PIC
  * @param   iGOO_SECONDARY_REFERENCE : ref. secondaire
  * @param   iGOO_SHORT_DESCRIPTION Description courte
  * @param   iDIC_ACCOUNTABLE_GROUP_ID : Groupe de resp.
  * @param   iGCO_GOOD_CATEGORY_ID : Catégorie de bien
  * @param   iSecurityDelay : Délais de sécurité
  * @param   iCreateTaskList : Création de la gamme opératoire
  * @param   iExecPlanning : Planification de la proposition
  * @param   iCreateComponent : Génération des composants
  * @param   iCreateCoupledGood : Génération des produits couplés
  * @param   iCreateNetwork : Génération des réseaux sous-jacents
  * @param   iForwardPlanning : Plannification Avant
  * @param   iCBSelectedStocks : Liste des stock sélectionnés
  * @param   iPpsNomenclatureId : Nomenclature
  * @param   iStandardLotQty : Qté lot standard
  * @param   iFixedDuration : Durée fixe
  * @param   iGcoComplDataManufID : Donnée complémentaire de fabrication
  )
  */
  procedure CreateFalLotProp(
    ioFalLotPropID            in out number
  , ioDocRecordID             in out number
  , ioStockConsoID            in out number
  , ioFalNetworkSupplyId      in out number
  , iCSupplyMode              in     varchar2
  , icSchedulePlanCode        in     varchar2
  , iDicFabConditionID        in     varchar2
  , iFalSchedulePlanID        in     number
  , iFalSchedPlanIDFromNom    in     number
  , iCTypeProp                in     varchar2
  , iFalNetworkNeedID         in     number
  , iGcoGoodID                in     number
  , iOriginStockID            in     number
  , iOriginLocationID         in     number
  , iTargetStockID            in     number
  , iTargetLocationID         in     number
  , iNeedDate                 in     date
  , iAskedQty                 in     number
  , iPlannedTrashQty          in     number
  , iCharacterizations_ID1    in     number
  , iCharacterizations_ID2    in     number
  , iCharacterizations_ID3    in     number
  , iCharacterizations_ID4    in     number
  , iCharacterizations_ID5    in     number
  , iCharacterizations_VA1    in     varchar2
  , iCharacterizations_VA2    in     varchar2
  , iCharacterizations_VA3    in     varchar2
  , iCharacterizations_VA4    in     varchar2
  , iCharacterizations_VA5    in     varchar2
  , iCalculByStock            in     integer
  , iText                     in     varchar2
  , iSupplyRequestID          in     number
  , iIsCallByNeedCalculation  in     integer default 0
  , iDOC_RECORD_ID            in     number default null
  , iFAL_PIC_LINE_ID          in     number default null
  , iGOO_SECONDARY_REFERENCE  in     varchar2 default null
  , iGOO_SHORT_DESCRIPTION    in     varchar2 default null
  , iDIC_ACCOUNTABLE_GROUP_ID in     varchar2 default null
  , iGCO_GOOD_CATEGORY_ID     in     number default null
  , iSecurityDelay            in     integer default 0
  , iCreateTaskList           in     integer default 0
  , iExecPlanning             in     integer default 0
  , iCreateComponent          in     integer default 0
  , iCreateCoupledGood        in     integer default 0
  , iCreateNetwork            in     integer default 0
  , iForwardPlanning          in     integer default 0
  , iCBSelectedStocks         in     varchar2 default null
  , iPpsNomenclatureId        in     number default null
  , iStandardLotQty           in     number default 1
  , iFixedDuration            in     integer default 0
  , iGcoComplDataManufID      in     number default null
  )
  is
    lvGoodShortDescription   GCo_DESCRIPTION.DES_SHORT_DESCRIPTION%type;
    lvGoodSecondaryReference GCo_GOOD.GOO_SECONDARY_REFERENCE%type;
    lvDicAccountableGroupID  DIC_ACCOUNTABLE_GROUP.DIC_ACCOUNTABLE_GROUP_ID%type;
    lnGCO_GOOD_CATEGORY_ID   GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_ID%type;
    ltFalPropDef             FAL_PROP_DEF%rowtype;
    ldPlanEndDate            date;
    lnFalPicLineID           FAL_PIC_LINE.FAL_PIC_LINE_ID%type;
    lnFAL_PIC_ID             FAL_PIC.FAL_PIC_ID%type;
    lnTotalQuantity          number;
    lnTotQteCouple           number;
    lvCFabType               varchar2(10);
    lnGcoComplDataManufID    number;
  begin
    lnTotQteCouple          := 0;

    -- Réservation de l'ID
    ioFalLotPropID := GetNewId;

    -- Récupérer les informations Proposition de définition ...
    ltFalPropDef            := FAL_PRC_FAL_PROP_COMMON.GetPropositionDefinition(iCTypeProp, iCSupplyMode);

    -- Fabrication standard ou  sous-traitance
    if iCSupplyMode = '4' then
      lvCFabType  := '4';
    else
      lvCFabType  := '0';
    end if;

    -- Incrémenter le numéro de proposition ...
    ltFalPropDef.FPR_METER  := nvl(ltFalPropDef.FPR_METER, 0) + 1;
    -- Déterminer la quantité
    lnTotalQuantity         := nvl(iAskedQty, 0) + nvl(iPlannedTrashQty, 0);
    lnFalPicLineID          := FAL_TOOLS.NIFZ(iFAL_PIC_LINE_ID);

    if iIsCallByNeedCalculation = 1 then
      lvGoodSecondaryReference  := iGOO_SECONDARY_REFERENCE;
      lvGoodShortDescription    := iGOO_SHORT_DESCRIPTION;
      lvDicAccountableGroupID   := iDIC_ACCOUNTABLE_GROUP_ID;
      lnGCO_GOOD_CATEGORY_ID    := FAL_TOOLS.NIFZ(iGCO_GOOD_CATEGORY_ID);
      ioDocRecordID             := FAL_TOOLS.NIFZ(iDOC_RECORD_ID);
    else
      -- Récupérer la référence secondaire et description courte du produit ...
      lvGoodSecondaryReference  := FAL_TOOLS.GetGOO_SECONDARY_REFERENCE(iGcoGoodID);
      lvGoodShortDescription    := FAL_TOOLS.GetGOO_SHORT_DESCRIPTION(iGcoGoodID);

      -- Récupérer le groupe de responsable du produit ...
      select DIC_ACCOUNTABLE_GROUP_ID
           , GCO_GOOD_CATEGORY_ID
        into lvDicAccountableGroupID
           , lnGCO_GOOD_CATEGORY_ID
        from GCO_GOOD
       where GCO_GOOD_ID = iGcoGoodID;

      -- Déterminer le dossier ...
      if nvl(iFalNetworkNeedID, 0) = 0 then
        if nvl(iSupplyRequestID, 0) = 0 then
          null;
        else
          select DOC_RECORD_ID
            into ioDocRecordID
            from FAL_SUPPLY_REQUEST
           where FAL_SUPPLY_REQUEST_ID = iSupplyRequestID;
        end if;
      else
        select DOC_RECORD_ID
          into ioDocRecordID
          from FAL_NETWORK_NEED
         where FAL_NETWORK_NEED_ID = iFalNetworkNeedID;
      end if;

      --Déterminer le FAL_PIC_LINE
      lnFalPicLineID            := nvl(lnFalPicLineID, FAL_TOOLS.GetPicLineByNeed(iFalNetworkNeedId) );
    end if;

    -- Déterminer le délai Final
    if (nvl(to_number(cfgFAL_TOLERANCE), 0) + iSecurityDelay) > 0 then
      ldPlanEndDate  :=
        FAL_SCHEDULE_FUNCTIONS.getdecalageBackwarddate(null
                                                     , null
                                                     , null
                                                     , null
                                                     , null
                                                     , FAL_SCHEDULE_FUNCTIONS.getdefaultcalendar
                                                     , iNeedDate
                                                     , nvl(to_number(cfgFAL_TOLERANCE), 0) + iSecurityDelay
                                                      );
    else
      ldPlanEndDate  := iNeedDate;
    end if;

    -- Déterminer le FAL_PIC_ID
    if nvl(lnFalPicLineID, 0) > 0 then
      begin
        select FAL_PIC_ID
          into lnFAL_PIC_ID
          from FAL_PIC_LINE
         where FAL_PIC_LINE_ID = lnFalPicLineID;
      exception
        when no_data_found then
          lnFalPicLineID := null;
          lnFAL_PIC_ID  := null;
      end;
    else
      lnFAL_PIC_ID  := null;
    end if;

    -- Déterminer le stock conso
    if nvl(iCalculByStock, 0) = 1 then
      ioStockConsoID  := iTargetStockID;
    else
      ioStockConsoID  := 0;
    end if;

    insert into FAL_LOT_PROP
                (FAL_LOT_PROP_ID
               , LOT_PROP_CHANGE
               , C_PREFIX_PROP
               , LOT_NUMBER
               , C_SCHEDULE_PLANNING
               , DIC_FAB_CONDITION_ID
               , LOT_ASKED_QTY
               , LOT_REJECT_PLAN_QTY
               , LOT_TOTAL_QTY
               , LOT_PLAN_BEGIN_DTE
               , LOT_PLAN_END_DTE
               , GCO_GOOD_ID
               , DIC_ACCOUNTABLE_GROUP_ID
               , GCO_GOOD_CATEGORY_ID
               , LOT_SECOND_REF
               , LOT_PSHORT_DESCR
               , DOC_RECORD_ID
               , FAL_PIC_LINE_ID
               , STM_STOCK_ID
               , STM_LOCATION_ID
               , STM_STM_STOCK_ID
               , GCO_CHARACTERIZATION1_ID
               , GCO_CHARACTERIZATION2_ID
               , GCO_CHARACTERIZATION3_ID
               , GCO_CHARACTERIZATION4_ID
               , GCO_CHARACTERIZATION5_ID
               , FAD_CHARACTERIZATION_VALUE_1
               , FAD_CHARACTERIZATION_VALUE_2
               , FAD_CHARACTERIZATION_VALUE_3
               , FAD_CHARACTERIZATION_VALUE_4
               , FAD_CHARACTERIZATION_VALUE_5
               , LOT_SHORT_DESCR
               , FAL_SUPPLY_REQUEST_ID
               , FAL_SCHEDULE_PLAN_ID
               , FAL_FAL_SCHEDULE_PLAN_ID
               , FAL_PIC_ID
               , A_DATECRE
               , A_IDCRE
               , C_FAB_TYPE
                )
         values (ioFalLotPropID
               , 0
               , ltFalPropDef.C_PREFIX_PROP
               , ltFalPropDef.FPR_METER
               , icSchedulePlanCode
               , iDicFabConditionID
               , iAskedQty
               , iPlannedTrashQty
               , lnTotalQuantity
               , ldPlanEndDate
               , ldPlanEndDate
               , iGcoGoodID
               , lvDicAccountableGroupID
               , LnGCO_GOOD_CATEGORY_ID
               , lvGoodSecondaryReference
               , lvGoodShortDescription
               , FAL_TOOLS.NIFZ(ioDocRecordID)
               , FAL_TOOLS.NIFZ(lnFalPicLineID)
               , FAL_TOOLS.NIFZ(iTargetStockID)
               , FAL_TOOLS.NIFZ(iTargetLocationID)
               , FAL_TOOLS.NIFZ(ioStockConsoID)
               , FAL_TOOLS.NIFZ(iCharacterizations_ID1)
               , FAL_TOOLS.NIFZ(iCharacterizations_ID2)
               , FAL_TOOLS.NIFZ(iCharacterizations_ID3)
               , FAL_TOOLS.NIFZ(iCharacterizations_ID4)
               , FAL_TOOLS.NIFZ(iCharacterizations_ID5)
               , FAL_TOOLS.OnNoZeroOrNullSetWithValue(iCharacterizations_ID1, iCharacterizations_VA1)
               , FAL_TOOLS.OnNoZeroOrNullSetWithValue(iCharacterizations_ID2, iCharacterizations_VA2)
               , FAL_TOOLS.OnNoZeroOrNullSetWithValue(iCharacterizations_ID3, iCharacterizations_VA3)
               , FAL_TOOLS.OnNoZeroOrNullSetWithValue(iCharacterizations_ID4, iCharacterizations_VA4)
               , FAL_TOOLS.OnNoZeroOrNullSetWithValue(iCharacterizations_ID5, iCharacterizations_VA5)
               , iText
               , FAL_TOOLS.NIFZ(iSupplyRequestID)
               , FAL_TOOLS.NIFZ(iFalSchedulePlanID)
               , FAL_TOOLS.NIFZ(iFalSchedPlanIDFromNom)
               , FAL_TOOLS.NIFZ(lnFAL_PIC_ID)
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , lvCFabType
                );

    -- Incrémenter le compteur ...
    FAL_PRC_FAL_PROP_COMMON.UpdatePropDefinition(iFalPropDefID => ltFalPropDef.FAL_PROP_DEF_ID, iFprMeter => nvl(ltFalPropDef.FPR_METER, 0) + 1);

    -- Création de la gamme opératoire
    if     iCreateTaskList = 1
       and nvl(iFalSchedulePlanID, 0) <> 0 then
      FAL_CALCUL_BESOIN.CreateAllPropOpOfGamme(iFAL_LOT_PROP_ID        => ioFalLotPropId
                                             , iFAL_SCHEDULE_PLAN_ID   => iFalSchedulePlanID
                                             , iQte                    => lnTotalQuantity
                                             , iC_SCHEDULE_PLANNING    => iCSchedulePlanCode
                                              );

      -- Dans le cadre de la sous-traitance d'achat, certaines données opératoires proviennent directement de la fiche produit
      if lvCFabType = '4' then
        FAL_OPERATION_FUNCTIONS.UpdateSubcPurchaseOperation(iFalLotPropId                => ioFalLotPropID
                                                          , iGcoComplDataSubContractID   => iGcoComplDataManufID
                                                          , iTotalQty                    => lnTotalQuantity
                                                           );
      end if;
    end if;

    -- Planification de la proposition
    if iExecPlanning = 1 then
      -- Planification arrière ou avant (Propositions pour stock minimum)
      FAL_PLANIF.Planification_Lot_Prop(PrmFAL_LOT_PROP_ID          => ioFalLotPropId
                                      , DatePlanification           => ldPlanEndDate
                                      , SelonDateDebut              => iForwardPlanning
                                      , MAJReqLiensComposantsProp   => 0
                                      , MAJ_Reseaux_Requise         => 0
                                       );
    end if;

    -- Génération de la nomenclature de composants
    if     iCreateComponent = 1
       and nvl(iPpsNomenclatureId, 0) <> 0 then
      FAL_PRC_FAL_LOT_MAT_LINK_PROP.CreateFalLotMatLinkProp(iCreatedPropID           => ioFalLotPropId
                                                          , iCBStandardLotQty        => iStandardLotQty
                                                          , iCBNomenclatureID        => iPpsNomenclatureID
                                                          , iCBcSchedulePlanCode     => iCSchedulePlanCode
                                                          , iCBSchedulePlanIDOfNom   => iFalSchedPlanIDFromNom
                                                          , iCBNomenclatureID2       => iPpsNomenclatureID
                                                          , iCalculByStock           => iCalculByStock
                                                          , iContext                 => case iCTypeProp
                                                              when '3' then FAL_PRC_FAL_LOT_MAT_LINK_PROP.context_PDP
                                                              else FAL_PRC_FAL_LOT_MAT_LINK_PROP.context_CB
                                                            end
                                                          , iCBSelectedStocks        => iCBSelectedStocks
                                                          , iCMA_FIX_DELAY           => iFixedDuration
                                                           );
    end if;

    -- Génération des produits couplés
    if     iCreateCoupledGood = 1
       and cfgFAL_COUPLED_GOOD = '1' then
      FAL_COUPLED_GOOD.CreateApproForCoupledGood(PrmGCO_COMPL_DATA_MANUFACTURE   => iGcoComplDataManufID
                                               , prmCreatedPropID                => ioFalLotPropId
                                               , PrmQteDemande                   => iAskedQty
                                               , OutTOTQteCouple                 => lnTotQteCouple
                                                );
    end if;

    -- Génération des réseaux sous-jacents
    if iCreateNetwork = 1 then
      -- Réseau Appro
      FAL_NETWORK_DOC.CreateReseauApproPropApproFab(FalLotPropID => ioFalLotPropId, aCreatedSupplyID => ioFalNetworkSupplyId, aTOTQteCouple => lnTotQteCouple);
      -- Réseaux besoins
      FAL_NETWORK_DOC.CreateReseaubesoinPropApproFab(FalLotPropID => ioFalLotPropId);
    end if;
  end CreateFalLotProp;
end FAL_PRC_FAL_LOT_PROP;
