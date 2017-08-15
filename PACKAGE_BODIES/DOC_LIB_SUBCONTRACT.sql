--------------------------------------------------------
--  DDL for Package Body DOC_LIB_SUBCONTRACT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_LIB_SUBCONTRACT" 
is
  function DoPositionComponentsMvt(iPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    lCount pls_integer;
  begin
    select count(*)
      into lCount
      from DOC_POSITION POS
     where POS.DOC_POSITION_ID = iPositionId
       and POS.C_GAUGE_TYPE_POS = '1'
       and (   POS.C_DOC_LOT_TYPE = '001'
            or POS.FAL_SCHEDULE_STEP_ID is not null);

    return sign(lCount);
  end DoPositionComponentsMvt;

  /**
  * Description
  *   Indique si le document génère des mouvements de composants sous-traitance
  */
  function DoDocumentComponentsMvt(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    lCount pls_integer;
  begin
    select count(*)
      into lCount
      from DOC_POSITION POS
     where POS.DOC_DOCUMENT_ID = iDocumentId
       and POS.C_GAUGE_TYPE_POS = '1'
       and (   POS.C_DOC_LOT_TYPE = '001'
            or POS.FAL_SCHEDULE_STEP_ID is not null);

    return sign(lCount);
  end DoDocumentComponentsMvt;

  /**
  * Description
  *   Indique si le document génère des mouvements de transfert en atelier
  */
  function DoDocumentFactoryTransferMvt(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    lCount pls_integer;
  begin
    select count(*)
      into lCount
      from DOC_POSITION POS
         , STM_MOVEMENT_KIND MOK
         , DOC_DOCUMENT DMT
     where POS.DOC_DOCUMENT_ID = iDocumentId
       and POS.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID
       and MOK.MOK_BATCH_RECEIPT = 1
       and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
       and C_DOCUMENT_STATUS <= '2';

    return sign(lCount);
  end DoDocumentFactoryTransferMvt;

  /**
  * Description
  *   Renvoi 1 si le gabarit provoque des réceptions d'OF sous-traitance
  */
  function IsGaugeSubcontractBatchReceipt(iGaugeID in DOC_GAUGE.DOC_GAUGE_ID%type)
    return number
  is
    lnResult number(1);
  begin
    select nvl(max(1), 0)
      into lnResult
      from DOC_GAUGE_STRUCTURED GAS
         , DOC_GAUGE_POSITION GAP
         , STM_MOVEMENT_KIND MOK
     where GAS.DOC_GAUGE_ID = iGaugeID
       and GAP.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
       and GAP.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID
       and MOK.MOK_BATCH_RECEIPT = 1;

    return lnResult;
  end IsGaugeSubcontractBatchReceipt;

  /**
  * Description
  *   Retourne 1 si le document provoque des réceptions d'OF sous-traitance
  */
  function isDocumentBatchReceipt(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  as
    lIsDocumentBatchReceipt number;
  begin
    select sign(count(pos.DOC_POSITION_ID) )
      into lIsDocumentBatchReceipt
      from DOC_POSITION pos
         , DOC_GAUGE_POSITION gap
         , STM_MOVEMENT_KIND mok
     where pos.DOC_DOCUMENT_ID = iDocumentID
       and pos.DOC_GAUGE_POSITION_ID = gap.DOC_GAUGE_POSITION_ID
       and gap.STM_MOVEMENT_KIND_ID = mok.STM_MOVEMENT_KIND_ID
       and mok.MOK_BATCH_RECEIPT = 1;

    return lIsDocumentBatchReceipt;
  end isDocumentBatchReceipt;

  /**
  * Description
  *   Retourne 1 si un des pèrs du document provoque des réceptions d'OF sous-traitance
  */
  function isDocumentFathersBatchReceipt(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  as
  begin
    for ltplFathersdocs in (select *
                              from table(DOC_I_LIB_DOCUMENT.getDocParentIdList(iChildDocumentID => iDocumentID, iIncludeSelf => 0) ) ) loop
      if IsDocumentBatchReceipt(ltplFathersdocs.column_value) = 1 then
        return 1;
      end if;
    end loop;

    return 0;
  end isDocumentFathersBatchReceipt;

  /**
  * function GetCompQty
  * Description
  *   Renvoi la qté d'un composant livré ou prochainement livré au sous traitant ou retourné ou prochainement par la sous-traitant.
  */
  function GetCompQty(
    iFalLotMatLinkID in FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type
  , iLocationID      in STM_LOCATION.STM_LOCATION_ID%type default null
  , iProvQty         in number default 0
  , iC_DOC_LINK_TYPE in DOC_LINK.C_DOC_LINK_TYPE%type
  )
    return number
  is
    lnQty number default 0;
  begin
    select nvl(sum(PDE.PDE_FINAL_QUANTITY), 0)
      into lnQty
      from DOC_LINK LNK
         , DOC_POSITION_DETAIL PDE
         , DOC_POSITION POS
     where LNK.C_DOC_LINK_TYPE = iC_DOC_LINK_TYPE
       and LNK.FAL_LOT_MATERIAL_LINK_ID = iFalLotMatLinkID
       and PDE.DOC_POSITION_DETAIL_ID = LNK.DOC_PDE_TARGET_ID
       and (   PDE.STM_LOCATION_ID = iLocationID
            or iLocationID is null)
       and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
       and (    (    iProvQty = 1
                 and POS.C_DOC_POS_STATUS = '01')
            or (    iProvQty = 0
                and POS.C_DOC_POS_STATUS in('02', '03', '04') ) );

    return lnQty;
  end GetCompQty;

  /**
  * function AllowDischarge
  * Description
  *   Indique si le détail courant peut-être déchargé
  * @created vje 12.09.2012
  * @lastUpdate
  * @public
  * @param iDetailID : détail de position à contrôler
  * @param iHoldQty  : quantité saisie
  * @return
  */
  function AllowDischarge(iDetailID in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type, iHoldQty in DOC_POSITION.POS_BALANCE_QUANTITY%type)
    return number
  is
    lnResult                 number(1);
    lnLotID                  FAL_LOT.FAL_LOT_ID%type;
    lnPDELotID               FAL_LOT.FAL_LOT_ID%type;
    lnTaskLinkID             FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type;
    lvCDocLotType            DOC_POSITION.C_DOC_LOT_TYPE%type;
    lvCGaugeTypePos          DOC_GAUGE_POSITION.C_GAUGE_TYPE_POS%type;
    lnCST                    number(1);
    lnCAST                   number(1);
    lvCFabType               FAL_LOT.C_FAB_TYPE%type;
    lvCLotStatus             FAL_LOT.C_LOT_STATUS%type;
    lvStepNumber             FAL_TASK_LINK.SCS_STEP_NUMBER%type;
    lnSubcontractQty         FAL_TASK_LINK.TAL_SUBCONTRACT_QTY%type;
    lnDueQty                 FAL_TASK_LINK.TAL_DUE_QTY%type;
    lnReleaseQty             FAL_TASK_LINK.TAL_RELEASE_QTY%type;
    lnPreviousScheduleStepID FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type;
    lnPreviousPlanQty        FAL_TASK_LINK.TAL_PLAN_QTY%type;
    lnPreviousDueQty         FAL_TASK_LINK.TAL_DUE_QTY%type;
    lnPreviousReleaseQty     FAL_TASK_LINK.TAL_RELEASE_QTY%type;
    lnNewSubcontractQty      FAL_TASK_LINK.TAL_SUBCONTRACT_QTY%type;
    lnAvaliableQtyMax        FAL_TASK_LINK.TAL_AVALAIBLE_QTY%type;
    lnNewAvaliableQty        FAL_TASK_LINK.TAL_AVALAIBLE_QTY%type;
  begin
    lnResult  := 1;

    if iDetailID is not null then
      select PDE.FAL_LOT_ID PDE_FAL_LOT_ID
           , PDE.FAL_SCHEDULE_STEP_ID FAL_TASK_LINK_ID
           , POS.C_DOC_LOT_TYPE
           , POS.C_GAUGE_TYPE_POS
           , DOC_LIB_SUBCONTRACTO.IsSUOOGauge(PDE.DOC_GAUGE_ID) IS_CST
           , DOC_LIB_SUBCONTRACTP.IsSUPOGauge(PDE.DOC_GAUGE_ID) IS_CAST
           , nvl(LOT_CAST.C_FAB_TYPE, LOT_CST.C_FAB_TYPE) C_FAB_TYPE
           , nvl(LOT_CAST.C_LOT_STATUS, LOT_CST.C_LOT_STATUS) C_LOT_STATUS
           , nvl(LOT_CAST.FAL_LOT_ID, LOT_CST.FAL_LOT_ID) FAL_LOT_ID
           , TAL.SCS_STEP_NUMBER
           , nvl(TAL.TAL_SUBCONTRACT_QTY, 0)
           , nvl(TAL.TAL_DUE_QTY, 0)
           , nvl(TAL.TAL_RELEASE_QTY, 0)
        into lnPDELotID
           , lnTaskLinkID
           , lvCDocLotType
           , lvCGaugeTypePos
           , lnCST
           , lnCAST
           , lvCFabType
           , lvCLotStatus
           , lnLotID
           , lvStepNumber
           , lnSubcontractQty
           , lnDueQty
           , lnReleaseQty
        from DOC_POSITION POS
           , DOC_POSITION_DETAIL PDE
           , FAL_LOT LOT_CAST
           , FAL_LOT LOT_CST
           , FAL_TASK_LINK TAL
       where PDE.DOC_POSITION_DETAIL_ID = iDetailID
         and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
         and LOT_CAST.FAL_LOT_ID(+) = PDE.FAL_LOT_ID
         and TAL.FAL_SCHEDULE_STEP_ID(+) = PDE.FAL_SCHEDULE_STEP_ID
         and LOT_CST.FAL_LOT_ID(+) = TAL.FAL_LOT_ID;

      -- Détermine si le détail courant respect les conditions de décharge.
      --
      -- Conditions d'interdiction de décharge d'un détail de position spécifié
      --
      --    1. Le lot est planifié
      --    2. En sous-traitance operatoire (CST), la quantité réceptionnée est > que la quantité réalisée de l'opération précédente - la
      --       quantité réalisée de l'opération externe. En d'autres termes, il faut que le suivi opératoire soit correctement effectué
      --       sur les opérations précédentes pour autoriser la décharge de la CST. Principe qui était valable avant la mise à place de
      --       la possibilité de créer des CST sur des lots planifié.
      --
      if (    lnCAST = 1
          and lvCDocLotType = '001'
          and lnLotID is not null
          and lvCFabType = FAL_BATCH_FUNCTIONS.btSubcontract
          and lvCLotStatus = FAL_I_LIB_BATCH.cLotStatusPlanified
         ) then
        lnResult  := 0;
      elsif(    lnCST = 1
            and lvCGaugeTypePos = '1'
            and lnLotID is not null
            and lnTaskLinkID is not null) then
        if (lvCLotStatus = FAL_I_LIB_BATCH.cLotStatusPlanified) then
          -- Interdit la décharge si le lot est planifié
          lnResult  := 0;
        else
          -- Recherche les informations nécessaires au contrôle de l'opération courante, en se basant sur l'opération interne précédente.
          begin
            select TAL.FAL_SCHEDULE_STEP_ID
                 , nvl(TAL.TAL_PLAN_QTY, 0)
                 , nvl(TAL.TAL_DUE_QTY, 0)
                 , nvl(TAL.TAL_RELEASE_QTY, 0)
              into lnPreviousScheduleStepID
                 , lnPreviousPlanQty
                 , lnPreviousDueQty
                 , lnPreviousReleaseQty
              from FAL_TASK_LINK TAL
             where TAL.FAL_LOT_ID = lnLotID
               and TAL.C_OPERATION_TYPE = 1
               and TAL.SCS_STEP_NUMBER = (select max(SCS_STEP_NUMBER)
                                            from FAL_TASK_LINK
                                           where FAL_LOT_ID = lnLotID
                                             and C_OPERATION_TYPE = 1
                                             and SCS_STEP_NUMBER < lvStepNumber);
          exception
            when no_data_found then
              lnPreviousScheduleStepID  := null;
              lnPreviousPlanQty         := null;
              lnPreviousDueQty          := null;
              lnPreviousReleaseQty      := null;
          end;

          -- Interdit la décharge si la quantité saisie (réceptionnée) est > que la quantité réalisée
          -- de l'opération précédente - la quantité réalisée de l'opération externe.
          if     lnPreviousScheduleStepID is not null
             and (nvl(iHoldQty, 0) > lnPreviousReleaseQty - lnReleaseQty) then
            lnResult  := 0;
          end if;
        end if;
      end if;
    end if;

    return lnResult;
  end AllowDischarge;

  /**
  * Description
  *   return position's subcontract operation
  */
  function getSubcontractOperation(iPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return DOC_POSITION.FAL_SCHEDULE_STEP_ID%type
  is
    lResult DOC_POSITION.FAL_SCHEDULE_STEP_ID%type;
  begin
    -- retrieve the subcontract operation linked to the position. For subcontracting purchase/operative purpose
    select nvl(POS.FAL_SCHEDULE_STEP_ID, nvl( (select max(PDE.FAL_SCHEDULE_STEP_ID)
                                                 from DOC_POSITION_DETAIL PDE
                                                where PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID), (select max(FTL.FAL_SCHEDULE_STEP_ID)
                                                                                                     from FAL_TASK_LINK FTL
                                                                                                    where FTL.FAL_LOT_ID = POS.FAL_LOT_ID) ) )
                                                                                                                                           FAL_SCHEDULE_STEP_ID
      into lResult
      from DOC_POSITION POS
     where POS.DOC_POSITION_ID = iPositionId;

    return lResult;
  end getSubcontractOperation;

  /**
  * Description
  *   Return les id des documents d'origine du document fourni
  */
  function GetBatchOriginDocument(iDocDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return ID_TABLE_TYPE pipelined
  is
    lcDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    lcPositionId DOC_POSITION.DOC_POSITION_ID%type;
  begin
    for ltplPositionLot in (select FAL_LOT_ID
                                 , FAL_SCHEDULE_STEP_ID
                              from DOC_POSITION
                             where DOC_DOCUMENT_ID = iDocDocumentId) loop
      if (DOC_LIB_SUBCONTRACTP.IsDocumentSubcontractP(iDocDocumentId) = 1) then
        FAL_I_LIB_SUBCONTRACTP.GetBatchOriginDocument(ltplPositionLot.FAL_LOT_ID, lcDocumentId, lcPositionId);
      else
        FAL_I_LIB_SUBCONTRACTO.GetBatchOriginDocument(ltplPositionLot.FAL_SCHEDULE_STEP_ID, lcDocumentId, lcPositionId);
      end if;

      pipe row(lcDocumentId);
    end loop;
  end GetBatchOriginDocument;

  /**
  * Description
  *   Return l'id de la position d'origine de la position fourni
  */
  function GetBatchOriginPosition(iDocPositionId DOC_POSITION.DOC_POSITION_ID%type)
    return DOC_POSITION.DOC_POSITION_ID%type
  is
    lcLotId          FAL_LOT.FAL_LOT_ID%type;
    lcScheduleStepId DOC_POSITION.FAL_SCHEDULE_STEP_ID%type;
    lcDocumentId     DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    lcPositionId     DOC_POSITION.DOC_POSITION_ID%type;
  begin
    -- Récupération du lot
    begin
      select FAL_LOT_ID
           , FAL_SCHEDULE_STEP_ID
        into lcLotId
           , lcScheduleStepId
        from DOC_POSITION
       where DOC_POSITION_ID = iDocPositionId
         and rownum = 1;
    exception
      when no_data_found then
        lcLotId           := null;
        lcScheduleStepId  := null;
    end;

    if (DOC_LIB_SUBCONTRACTP.IsPositionSubcontractP(iDocPositionId) = 1) then
      FAL_I_LIB_SUBCONTRACTP.GetBatchOriginDocument(lcLotId, lcDocumentId, lcPositionId);
    else
      FAL_I_LIB_SUBCONTRACTO.GetBatchOriginDocument(lcScheduleStepId, lcDocumentId, lcPositionId);
    end if;

    return lcPositionId;
  end GetBatchOriginPosition;

  /**
  * Description
  *    Retourne le Produit fabriqué de la position
  */
  function getManufacturedGoodId(iPositionID in DOC_POSITION.DOC_POSITION_ID%type)
    return DOC_POSITION.GCO_MANUFACTURED_GOOD_ID%type
  as
    lManufacturedGoodId DOC_POSITION.GCO_MANUFACTURED_GOOD_ID%type;
    lTasklinkID         DOC_POSITION.FAL_SCHEDULE_STEP_ID%type;
    lLotID              DOC_POSITION.FAL_LOT_ID%type;
  begin
    if DOC_LIB_SUBCONTRACTO.IsPositionSubcontractO(iPositionID => iPositionID) = 1 then
      /* Si sous-traitance opératoire (STO), récupération du lot depuis l'opération de la position */
      lTasklinkID  := FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_POSITION', 'FAL_SCHEDULE_STEP_ID', iPositionID);
      lLotID       := FAL_I_LIB_TASK_LINK.getFalLotID(inFalTaskLinkID => lTasklinkID);
    else
      /* Sinon Sous-traitance achat (STA), récupération du lot de la position */
      lLotID  := FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_POSITION', 'FAL_LOT_ID', iPositionID);
    end if;

    /* Récupération du produit fabriqué depuis le lot */
    lManufacturedGoodId  :=
                    FWK_I_LIB_ENTITY.getNumberFieldFromPk('FAL_ORDER', 'GCO_GOOD_ID', FWK_I_LIB_ENTITY.getNumberFieldFromPk('FAL_LOT', 'FAL_ORDER_ID', lLotID) );
    return lManufacturedGoodId;
  end getManufacturedGoodId;

  /**
  * Description
  *    Retourne 1 si la position est flaguée sous-traitance achat ou opératoire
  */
  function isPositionSubcontract(iPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  as
  begin
    if    (DOC_LIB_SUBCONTRACTP.IsPositionSubcontractP(iPositionID => iPositionID) = 1)
       or (DOC_LIB_SUBCONTRACTO.IsPositionSubcontractO(iPositionID => iPositionID) = 1) then
      return 1;
    end if;

    return 0;
  end isPositionSubcontract;

  /**
  * Description
  *    Retourne 1 si la décharge doit afficher le flag 'Rebut PT' dans les positions déchargeables, c.-à-d. lorsqu'il
  *    s'agit d'un document avec des positions provoquant un suivi d'avancement (le flag permet de saisir du suivi en
  *    PT si sélectionné). Valable pour la sous-traitance opératoire ET la sous-traitance achat.
  */
  function isDischargeFlagPTRebutVisible(iDocList in varchar2, iTargetGaugeId in DOC_GAUGE_STRUCTURED.DOC_GAUGE_ID%type)
    return number
  as
    lVisible number;
  begin
    select count(*)
      into lVisible
      from dual
     where exists(
             select pos.DOC_POSITION_ID
               from table(idListToTable(iDocList) ) doc
                  , DOC_POSITION pos
                  , DOC_GAUGE_POSITION gap_src
                  , DOC_GAUGE_POSITION gap_dst
                  , STM_MOVEMENT_KIND mok_src
                  , STM_MOVEMENT_KIND mok_dst
              where pos.DOC_DOCUMENT_ID = doc.column_value
                and gap_src.DOC_GAUGE_POSITION_ID = pos.DOC_GAUGE_POSITION_ID
                and gap_dst.C_GAUGE_TYPE_POS = gap_src.C_GAUGE_TYPE_POS
                and gap_dst.GAP_DESIGNATION = gap_src.GAP_DESIGNATION
                and gap_dst.DOC_GAUGE_ID = iTargetGaugeId
                and mok_src.STM_MOVEMENT_KIND_ID(+) = gap_src.STM_MOVEMENT_KIND_ID
                and mok_dst.STM_MOVEMENT_KIND_ID = gap_dst.STM_MOVEMENT_KIND_ID
                and (   pos.FAL_LOT_ID is not null
                     or pos.FAL_SCHEDULE_STEP_ID is not null)
                and nvl(mok_src.MOK_UPDATE_OP, 0) = 0
                and nvl(mok_dst.MOK_UPDATE_OP, 0) = 1);

    return lVisible;
  end isDischargeFlagPTRebutVisible;

  /**
  * Description
  *    Retourne 1 si la décharge doit afficher le flag 'Rebut CPT' dans les positions déchargeables, c.-à-d. lorsqu'il s'agit
  *    d'un document avec des positions provoquant un suivi d'avancement (le flag permet de saisir du suivi en CPT si sélectionné).
  *    Valable uniquement pour la sous-traitance opératoire. La fonction retourne 0 pour la sous-traitance achat.
  */
  function isDischargeFlagCPTRebutVisible(iDocList in varchar2, iTargetGaugeId in DOC_GAUGE_STRUCTURED.DOC_GAUGE_ID%type)
    return number
  as
    lVisible number;
  begin
    select count(*)
      into lVisible
      from dual
     where exists(
             select pos.DOC_POSITION_ID
               from table(idListToTable(iDocList) ) doc
                  , DOC_POSITION pos
                  , DOC_GAUGE_POSITION gap_src
                  , DOC_GAUGE_POSITION gap_dst
                  , STM_MOVEMENT_KIND mok_src
                  , STM_MOVEMENT_KIND mok_dst
              where pos.DOC_DOCUMENT_ID = doc.column_value
                and gap_src.DOC_GAUGE_POSITION_ID = pos.DOC_GAUGE_POSITION_ID
                and gap_dst.C_GAUGE_TYPE_POS = gap_src.C_GAUGE_TYPE_POS
                and gap_dst.GAP_DESIGNATION = gap_src.GAP_DESIGNATION
                and gap_dst.DOC_GAUGE_ID = iTargetGaugeId
                and mok_src.STM_MOVEMENT_KIND_ID(+) = gap_src.STM_MOVEMENT_KIND_ID
                and mok_dst.STM_MOVEMENT_KIND_ID = gap_dst.STM_MOVEMENT_KIND_ID
                and pos.FAL_SCHEDULE_STEP_ID is not null
                and nvl(mok_src.MOK_UPDATE_OP, 0) = 0
                and nvl(mok_dst.MOK_UPDATE_OP, 0) = 1
                and nvl(gap_dst.C_DOC_LOT_TYPE, '0') <> '001');

    return lVisible;
  end isDischargeFlagCPTRebutVisible;
end DOC_LIB_SUBCONTRACT;
