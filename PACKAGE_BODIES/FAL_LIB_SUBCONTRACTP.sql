--------------------------------------------------------
--  DDL for Package Body FAL_LIB_SUBCONTRACTP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_SUBCONTRACTP" 
is
  /**
  * function GetSubcontractPStock
  * Description : Renvoie le Stock sous-traitant de la DCST par défaut d'un produit
  *               donné.
  * @created ECA
  * @lastUpdate
  * @private
  */
  function GetSubcontractPStock(iGcoGoodId in number)
    return number
  is
    lnSSTSTockID number;
  begin
    select max(STO.STM_STOCK_ID)
      into lnSSTSTockID
      from GCO_COMPL_DATA_SUBCONTRACT CDS
         , STM_STOCK STO
     where CDS.GCO_GOOD_ID = iGcoGoodId
       and CDS.CSU_DEFAULT_SUBCONTRACTER = 1
       and CDS.PAC_SUPPLIER_PARTNER_ID = STO.PAC_SUPPLIER_PARTNER_ID
       and STO.STO_SUBCONTRACT = 1;

    return lnSSTSTockID;
  exception
    when others then
      return null;
  end GetSubcontractPStock;

  /**
  * Description
  *    get the order number relative to subcontracting purchase
  */
  function GetProgramNumber
    return number
  is
  begin
    return nvl(cast(PCS.PC_CONFIG.getConfig('FAL_SUBCONTRACTP_PGM_NUMBER') as number), 0);
  end GetProgramNumber;

  /**
  * Description
  *   Retourne une nouvelle description de lot pour une position de document.
  */
  function getNewSubCoRefCompl(iPositionID in DOC_POSITION.DOC_POSITION_ID%type)
    return varchar2
  as
    lNewLotRefCompl varchar2(255);
  begin
    if iPositionID is not null then
      select DOC.DMT_NUMBER || '/' || POS.POS_NUMBER
        into lNewLotRefCompl
        from DOC_DOCUMENT doc
           , DOC_POSITION pos
       where pos.DOC_DOCUMENT_ID = doc.DOC_DOCUMENT_ID
         and pos.DOC_POSITION_ID = iPositionID;
    else
      lNewLotRefCompl  := 'UNDEFINED';
    end if;

    return lNewLotRefCompl;
  end getNewSubCoRefCompl;

  /**
  * Description
  *   return order identifier for a new subcontracting purchase manufacturing order
  */
  function GetOrderId(
    iJobProgramId in FAL_JOB_PROGRAM.FAL_JOB_PROGRAM_ID%type
  , iSupplierId   in FAL_ORDER.PAC_SUPPLIER_PARTNER_ID%type
  , iGoodId       in FAL_ORDER.GCO_GOOD_ID%type
  )
    return FAL_ORDER.FAL_ORDER_ID%type
  is
    lResult FAL_ORDER.FAL_ORDER_ID%type;
  begin
    select FAL_ORDER_ID
      into lResult
      from FAL_ORDER
     where FAL_JOB_PROGRAM_ID = iJobProgramId
       and PAC_SUPPLIER_PARTNER_ID = iSupplierId
       and GCO_GOOD_ID = iGoodId
       and C_FAB_TYPE = FAL_BATCH_FUNCTIONS.btSubcontract;

    return lResult;
  exception
    when no_data_found then
      return null;
  end GetOrderId;

  /**
  * function GetSchedulePlanId
  * Description
  *   return the schedule plan dedicated to subcontracting purchase
  * @created fp 12.01.2011
  * @lastUpdate
  * @public
  * @param
  * @return
  */
  function GetSchedulePlanId
    return FAL_SCHEDULE_PLAN.FAL_SCHEDULE_PLAN_ID%type
  is
    lResult FAL_SCHEDULE_PLAN.FAL_SCHEDULE_PLAN_ID%type;
  begin
    select FAL_SCHEDULE_PLAN_ID
      into lResult
      from FAL_SCHEDULE_PLAN
     where SCH_GENERIC_SUBCONTRACT = 1;

    return lResult;
  exception
    when no_data_found then
      ra(PCS.PC_FUNCTIONS.TranslateWord('PCS - Pas de gamme opératoire définie pour la sous-traitance!') );
    when too_many_rows then
      ra(PCS.PC_FUNCTIONS.TranslateWord('PCS - Plusieurs gammes opératoires définies pour la sous-traitance. Il n''en faut qu''une!') );
  end GetSchedulePlanId;

  /**
  * Description
  *    Control if batch can be updated
  */
  function ControlBatchBeforeUpdate(iLotId in FAL_LOT.FAL_LOT_ID%type)
    return varchar2
  is
  begin
    if     not FAL_LIB_BATCH.IsBatchPlanified(iLotid)
       and not FAL_LIB_BATCH.IsBatchLaunched(iLotid) then
      return PCS.PC_FUNCTIONS.TranslateWord('Un ordre de fabrication sous-traitance doit être au status "Planifié" ou "Lancé" pour être modifié.');
    else
      return null;
    end if;
  end ControlBatchBeforeUpdate;

  /**
  * Description
  *    Control if batch can be deleted
  * @created fp 26.01.2011
  * @lastUpdate
  * @public
  * @param iLotId
  * @return Error text if control fails
  */
  function ControlBatchBeforeDelete(iLotId in FAL_LOT.FAL_LOT_ID%type)
    return varchar2
  is
  begin
    if     not FAL_LIB_BATCH.IsBatchPlanified(iLotid)
       and not FAL_LIB_BATCH.IsBatchLaunched(iLotid) then
      return PCS.PC_FUNCTIONS.TranslateWord('Un ordre de fabrication sous-traitance doit être au status "Planifié" ou "Lancé" pour être supprimé.');
    else
      return null;
    end if;
  end;

  /**
  * Function GetStockSubcontractP
  * Description : Fonction qui renvoie le stock sous-traitant lié au produit terminé
  *               d'un composant de lot de fabrication ou de proposition
  * @created eca 02.02.2011
  * @lastUpdate
  * @public
  * @param iFalLotId : Lot de fabrication
  * @param iFalLotPropId : Proposition de fabrication
  * @return STM_STOCK_ID
  */
  function GetStockSubcontractP(iFalLotId in number default null, iFalLotPropId in number default null)
    return number
  is
    lnStmStockId number;
  begin
    if iFalLotId is not null then
      select max(STO.STM_STOCK_ID)
        into lnStmStockId
        from FAL_TASK_LINK TAL
           , STM_STOCK STO
       where TAL.FAL_LOT_ID = iFalLotId
         and TAL.PAC_SUPPLIER_PARTNER_ID = STO.PAC_SUPPLIER_PARTNER_ID
         and STO.STO_SUBCONTRACT = 1;
    else
      select max(STO.STM_STOCK_ID)
        into lnStmStockId
        from FAL_TASK_LINK_PROP TAL
           , STM_STOCK STO
       where TAL.FAL_LOT_PROP_ID = iFalLotPropId
         and TAL.PAC_SUPPLIER_PARTNER_ID = STO.PAC_SUPPLIER_PARTNER_ID
         and STO.STO_SUBCONTRACT = 1;
    end if;

    return lnStmStockId;
  exception
    when others then
      return null;
  end GetStockSubcontractP;

  /**
  * Function GetBatchCompoStockSubcontractP
  * Description : Fonction qui renvoie le stock sous-traitant de l'opération lié au composant d'OF ou de proposition
  * @created CLG 11.05.2012
  * @lastUpdate
  * @public
  * @param iFalLotMatLinkId     : Id du composant du lot de fabrication
  * @param iFalLotMatLinkPropId : Id du composant de la proposition
  * @return STM_STOCK_ID
  */
  function GetBatchCompoStockSubcontractP(iFalLotMatLinkId in number default null, iFalLotMatLinkPropId in number default null)
    return number
  is
    lnStmStockId number;
  begin
    if iFalLotMatLinkId is not null then
      select max(STO.STM_STOCK_ID)
        into lnStmStockId
        from STM_STOCK STO
       where STO.PAC_SUPPLIER_PARTNER_ID =
                          (select PAC_SUPPLIER_PARTNER_ID
                             from FAL_TASK_LINK OPE
                                , FAL_LOT_MATERIAL_LINK CPT
                            where OPE.FAL_LOT_ID = CPT.FAL_LOT_ID
                              and OPE.SCS_STEP_NUMBER = CPT.LOM_TASK_SEQ
                              and CPT.FAL_LOT_MATERIAL_LINK_ID = iFalLotMatLinkId)
         and STO.STO_SUBCONTRACT = 1;
    else
      select max(STO.STM_STOCK_ID)
        into lnStmStockId
        from STM_STOCK STO
       where STO.PAC_SUPPLIER_PARTNER_ID =
               (select OPE.PAC_SUPPLIER_PARTNER_ID
                  from FAL_TASK_LINK_PROP OPE
                     , FAL_LOT_MAT_LINK_PROP CPT
                 where OPE.FAL_LOT_PROP_ID = CPT.FAL_LOT_PROP_ID
                   and OPE.SCS_STEP_NUMBER = CPT.LOM_TASK_SEQ
                   and CPT.FAL_LOT_MAT_LINK_PROP_ID = iFalLotMatLinkPropId)
         and STO.STO_SUBCONTRACT = 1;
    end if;

    return lnStmStockId;
  exception
    when others then
      return null;
  end GetBatchCompoStockSubcontractP;

  /**
  * Function CheckSubcontractPNeedExists
  * Description : Fonction qui recherche si pour un produit, il existe des besoins
  *               de fabrication pour de la sous-traitance d'achat.
  * @created eca 03.02.2011
  * @lastUpdate
  * @public
  * @param iGcoGoodId : Produit
  * @return integer
  */
  function CheckSubcontractPNeedExists(iGcoGoodId in number)
    return integer
  is
    NbNeed integer;
  begin
    select count(*)
      into NbNeed
      from FAL_NETWORK_NEED FNN
         , FAL_LOT LOT
         , FAL_LOT_PROP LOP
     where FNN.GCO_GOOD_ID = iGcoGoodId
       and FNN.FAL_LOT_ID = LOT.FAL_LOT_ID(+)
       and FNN.FAL_LOT_PROP_ID = LOP.FAL_LOT_PROP_ID(+)
       and (   LOT.C_FAB_TYPE = '4'
            or LOP.C_FAB_TYPE = '4'
            or (    nvl(FNN.FAL_LOT_ID, FNN.FAL_LOT_PROP_ID) is not null
                and FAL_LIB_SUBCONTRACTO.getStockSubcontractO(FNN.GCO_GOOD_ID, FNN.FAL_LOT_ID, FNN.FAL_LOT_PROP_ID) is not null
               )
           )
       and FNN.FAN_FREE_QTY > 0;

    return NbNeed;
  end CheckSubcontractPNeedExists;

  /**
  * procedure IsNeedForSubcontractP
  * Description : Recherche si un besoin est destiné à la fabrication d'un appro
  *               sous-traité, et retourne le stock sous-traitant associé
  * @created ECA
  * @lastUpdate
  * @public
  * @param iFalNetworkNeedId : Réseau Besoin.
  * @param ioNeedForSubContract : Besoin pour de la sous-traitance d'achat
  * @param ioStmStockId : Stock sous-traitant associé au produit du besoin
  */
  procedure IsNeedForSubcontractP(iFalNetworkNeedId in number, ioNeedForSubContract in out integer, ioStmStockId in out number)
  is
    lvCFabType     varchar2(10);
    lnPTGoodId     number;
    lnFalLotId     number;
    lnFalLotPropId number;
    lnCptGoodId    number;
  begin
    ioNeedForSubContract  := 0;
    ioStmStockId          := null;

    select nvl(LOT.C_FAB_TYPE, LOP.C_FAB_TYPE)
         , nvl(LOT.GCO_GOOD_ID, LOP.GCO_GOOD_ID)
         , FNN.FAL_LOT_ID
         , FNN.FAL_LOT_PROP_ID
         , FNN.GCO_GOOD_ID
      into lvCFabType
         , lnPTGoodId
         , lnFalLotId
         , lnFalLotPropId
         , lnCptGoodId
      from FAL_NETWORK_NEED FNN
         , FAL_LOT LOT
         , FAL_LOT_PROP LOP
     where FNN.FAL_LOT_ID = LOT.FAL_LOT_ID(+)
       and FNN.FAL_LOT_PROP_ID = LOP.FAL_LOT_PROP_ID(+)
       and FNN.FAL_NETWORK_NEED_ID = iFalNetworkNeedId;

    if lvCFabType = FAL_LIB_MRP_CALCULATION.csmSubcontractPurchasePdt then
      /* OF ou prop de type sous-traitance, recherche du stock sous-traitant du produit */
      ioNeedForSubContract  := 1;
      ioStmStockId          := GetStockSubcontractP(lnFalLotId, lnFalLotPropId);
    elsif nvl(lnFalLotId, lnFalLotPropId) is not null then
      ioStmStockId  := FAL_LIB_SUBCONTRACTO.getStockSubcontractO(lnCptGoodId, lnFalLotId, lnFalLotPropId);

      /* Composant d'OF ou de prop liée à une opération de sous-traitance */
      if ioStmStockId is not null then
        ioNeedForSubContract  := 1;
      end if;
    end if;
  exception
    when others then
      begin
        ioNeedForSubContract  := 0;
        ioStmStockId          := null;
      end;
  end IsNeedForSubcontractP;

  /**
  * Description
  *   Check component stock, return 1 if it's enough quantity in subcontracter stock
  */
  function HasPositionMissingParts(iPositionId in DOC_POSITION.DOC_POSITION_ID%type default null)
    return number
  is
    lAttribQty           FAL_NETWORK_NEED.FAN_BALANCE_QTY%type;
    lBadAttribQty        FAL_NETWORK_NEED.FAN_BALANCE_QTY%type;
    lBalanceQty          FAL_LOT_MATERIAL_LINK.LOM_FULL_REQ_QTY%type;
    lAvailableQty        STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type;
    lAllowedAvailableQty STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type;
    lDocID               DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
  begin
    -- Recherche du document de la position
    lDocID  := FWK_I_LIB_ENTITY.getNumberFieldFromPk('DOC_POSITION', 'DOC_DOCUMENT_ID', iPositionId);

    -- Si au moins un document parent a effectué la réception du lot, il n'y a pas lieu d'avoir du manco.
    if DOC_I_LIB_SUBCONTRACT.isDocumentFathersBatchReceipt(iDocumentID => lDocID) = 1 then
      return 0;
    end if;

    -- Liste des biens du lot lié à la position
    for ltplPosGood in (select   LOM.GCO_GOOD_ID
                               , DOC_DOCUMENT_ID
                            from DOC_POSITION POS
                               , FAL_LOT_MATERIAL_LINK LOM
                               , GCO_PRODUCT PDT
                           where POS.DOC_POSITION_ID = iPositionId
                             and LOM.FAL_LOT_ID = POS.FAL_LOT_ID
                             and LOM.C_KIND_COM = '1'
                             and LOM.C_TYPE_COM = '1'
                             and POS.C_DOC_POS_STATUS = '01'
                             and PDT.GCO_GOOD_ID = LOM.GCO_GOOD_ID
                             and PDT.PDT_STOCK_MANAGEMENT = 1
                        group by LOM.GCO_GOOD_ID
                               , DOC_DOCUMENT_ID) loop
      -- curseur sur les besoins en composants par bien mais sur tout le document (si un composant est lié à 2 positions du document, on cumule les quantités)
      for ltplComponentNeed in (select   LOM.GCO_GOOD_ID
                                       , STM_I_LIB_STOCK.getSubCStockID(POS.PAC_THIRD_ID) STM_STT_STOCK_ID
                                       , sum(LOM_FULL_REQ_QTY) LOM_GLOBAL_FULL_REQ_QTY
                                       , sum(POS_BASIS_QUANTITY_SU * LOM_UTIL_COEF / LOM_REF_QTY + LOM_ADJUSTED_QTY - LOM_ADJUSTED_QTY_RECEIPT)
                                                                                                                                               LOM_FULL_REQ_QTY
                                    from DOC_POSITION POS
                                       , FAL_LOT_MATERIAL_LINK LOM
                                       , GCO_PRODUCT PDT
                                   where POS.DOC_DOCUMENT_ID = ltplPosGood.DOC_DOCUMENT_ID
                                     and LOM.GCO_GOOD_ID = ltplPosGood.GCO_GOOD_ID
                                     and LOM.FAL_LOT_ID = POS.FAL_LOT_ID
                                     and LOM.C_KIND_COM = '1'
                                     and LOM.C_TYPE_COM = '1'
                                     and PDT.GCO_GOOD_ID = LOM.GCO_GOOD_ID
                                     and PDT.PDT_STOCK_MANAGEMENT = 1
                                group by LOM.GCO_GOOD_ID
                                       , STM_I_LIB_STOCK.getSubCStockID(POS.PAC_THIRD_ID) ) loop
        lBalanceQty           := ltplComponentNeed.LOM_FULL_REQ_QTY;

        --DBMS_OUTPUT.PUT_LINE('Besoin ' || GCO_I_LIB_FUNCTIONS.getMajorReference(ltplComponentNeed.GCO_GOOD_ID) || ' Qté : ' || lBalanceQty);

        -- recherche de la quantité attribuée
        select nvl(sum(FLN_QTY), 0) FLN_QTY
          into lAttribQty
          from DOC_POSITION POS
             , FAL_LOT_MATERIAL_LINK LMA
             , FAL_NETWORK_NEED NNE
             , FAL_NETWORK_LINK NLI
             , STM_STOCK_POSITION SPO
         where POS.DOC_DOCUMENT_ID = ltplPosGood.DOC_DOCUMENT_ID
           and LMA.GCO_GOOD_ID = ltplComponentNeed.GCO_GOOD_ID
           and LMA.FAL_LOT_ID = POS.FAL_LOT_ID
           and LMA.C_KIND_COM = '1'
           and LMA.C_TYPE_COM = '1'
           and NNE.FAL_LOT_MATERIAL_LINK_ID = LMA.FAL_LOT_MATERIAL_LINK_ID
           and NLI.FAL_NETWORK_NEED_ID = NNE.FAL_NETWORK_NEED_ID
           and SPO.STM_STOCK_POSITION_ID = NLI.STM_STOCK_POSITION_ID
           and SPO.STM_STOCK_ID = ltplComponentNeed.STM_STT_STOCK_ID;

        --DBMS_OUTPUT.PUT_LINE('Attribué STT ' || GCO_I_LIB_FUNCTIONS.getMajorReference(ltplComponentNeed.GCO_GOOD_ID) || ' Qté : ' || lAttribQty);
        -- On soustrait la qté attribuée de la qté solde
        lBalanceQty           := lBalanceQty - lAttribQty;

        -- recherche de la quantité attribuée sur autre stock que STT
        select nvl(sum(FLN_QTY), 0) FLN_QTY
          into lBadAttribQty
          from DOC_POSITION POS
             , FAL_LOT_MATERIAL_LINK LMA
             , FAL_NETWORK_NEED NNE
             , FAL_NETWORK_LINK NLI
             , STM_STOCK_POSITION SPO
         where POS.DOC_DOCUMENT_ID = ltplPosGood.DOC_DOCUMENT_ID
           and LMA.GCO_GOOD_ID = ltplComponentNeed.GCO_GOOD_ID
           and LMA.FAL_LOT_ID = POS.FAL_LOT_ID
           and LMA.C_KIND_COM = '1'
           and LMA.C_TYPE_COM = '1'
           and NNE.FAL_LOT_MATERIAL_LINK_ID = LMA.FAL_LOT_MATERIAL_LINK_ID
           and NLI.FAL_NETWORK_NEED_ID = NNE.FAL_NETWORK_NEED_ID
           and SPO.STM_STOCK_POSITION_ID = NLI.STM_STOCK_POSITION_ID
           and SPO.STM_STOCK_ID <> ltplComponentNeed.STM_STT_STOCK_ID;

        -- Calcul de la quantité solde globale non attribuée
        lAllowedAvailableQty  := ltplComponentNeed.LOM_GLOBAL_FULL_REQ_QTY - lAttribQty - lBadAttribQty;

        --DBMS_OUTPUT.PUT_LINE('Consommable ' || GCO_I_LIB_FUNCTIONS.getMajorReference(ltplComponentNeed.GCO_GOOD_ID) || ' Solde non attrib : ' || lAllowedAvailableQty);

        -- Si la quantité solde dépasse la quantité solde globale non attribuée, c'est que les attributions sur autres stocks que STT
        -- empêchent la réception du ou des lots
        -- On a un manco
        if lBalanceQty > lAllowedAvailableQty then
          --DBMS_OUTPUT.PUT_LINE('Manco ' || GCO_I_LIB_FUNCTIONS.getMajorReference(ltplComponentNeed.GCO_GOOD_ID) || 'Attrib stock <> STT : ' || lBadAttribQty);
          return 1;
        end if;

        -- Si il reste un solde après soustraction de la qté attribuée, on regarde si il  y a assez de disponible
        -- en stock STT
        if lBalanceQty > 0 then
          lAvailableQty  :=
             greatest(STM_I_LIB_STOCK_POSITION.getSumAvailableQty(iGoodID => ltplComponentNeed.GCO_GOOD_ID, iStockID => ltplComponentNeed.STM_STT_STOCK_ID), 0);
          --DBMS_OUTPUT.PUT_LINE('Dispo STT ' || GCO_I_LIB_FUNCTIONS.getMajorReference(ltplComponentNeed.GCO_GOOD_ID) || ' Qté : ' || lAvailableQty);
          lBalanceQty    := lBalanceQty - lAvailableQty;

          -- si la qté dispo ne couvre pas les besoin alors on a un manco
          if lBalanceQty > 0 then
            --DBMS_OUTPUT.PUT_LINE('Manco ' || GCO_I_LIB_FUNCTIONS.getMajorReference(ltplComponentNeed.GCO_GOOD_ID) || ' Qté : ' || lBalanceQty);
            return 1;
          end if;
        end if;
      end loop;
    end loop;

    return 0;
  end HasPositionMissingParts;

  /**
  * procedure GetBatchOriginDocument
  * Description : Recherche du document de type CAST, à l'origine d'un lot de fabrication
  *
  * @created eca 11.04.2011
  * @lastUpdate SMA 14.02.2013
  * @public
  * @param   iFalLotId : lot de fabrication
  * @param   ioDocDocumentId : Document
  * @param   ioDocPositionId : Position
  */
  procedure GetBatchOriginDocument(iFalLotId in number, ioDocDocumentId in out number, ioDocPositionId in out number)
  is
    lnDocGaugeId number;
    lFlowId      number;
  begin
    ioDocDocumentId  := null;
    ioDocPositionId  := null;

    for tplOriginDoc in (select DOC.DOC_DOCUMENT_ID
                              , POS.DOC_POSITION_ID
                           from DOC_POSITION POS
                              , DOC_DOCUMENT DOC
                              , table(DOC_LIB_SUBCONTRACTP.GetSUPOGaugeId(DOC.PAC_THIRD_ID) ) DocGauge
                          where POS.FAL_LOT_ID = iFalLotId
                            and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
                            and DOC.DOC_GAUGE_ID = DocGauge.column_value) loop
      ioDocDocumentId  := tplOriginDoc.DOC_DOCUMENT_ID;
      ioDocPositionId  := tplOriginDoc.DOC_POSITION_ID;
      exit;
    end loop;
  end GetBatchOriginDocument;

  /**
  * procedure GetBatchOrigindocInfo
  * Description : Recherche d'informations complémentaires au lot ou à la prop
  *               de sous-traitance
  *
  * @created eca 11.04.2011
  * @lastUpdate SMA 14.02.2013
  * @public
  * @param   iFalLotId : lot de sous-traitance
  * @param   iFalLotPropId : Proposition de sous-traitance
  * @param   ioPacThirdId : Tier associé
  * @param   ioStatus : Statut du document associé
  * @param   ioThirdName : Nom du tier
  * @param   ioThirdShortName : Nom court du tier
  * @param   ioDicPdeFreeTable1Id : Dictionnaire détail position libre 1
  * @param   ioDicPdeFreeTable2Id : Dictionnaire détail position libre 2
  * @param   ioDicPdeFreeTable3Id : Dictionnaire détail position libre 3
  * @param   ioFinalDelay : Délai final
  * @param   ioIntermediateDelay : Délai intermédiaire
  */
  procedure GetBatchOriginDocInfo(
    iFalLotId            in     number default null
  , iFalLotPropId        in     number default null
  , ioPacThirdId         in out number
  , ioStatus             in out varchar2
  , ioThirdName          in out varchar2
  , ioThirdShortName     in out varchar2
  , ioDicPdeFreeTable1Id in out varchar2
  , ioDicPdeFreeTable2Id in out varchar2
  , ioDicPdeFreeTable3Id in out varchar2
  , ioFinalDelay         in out date
  , ioIntermediateDelay  in out date
  )
  is
  begin
    if nvl(iFalLotId, 0) <> 0 then
      for tplOriginDoc in (select DOC.PAC_THIRD_ID
                                , PCS.PC_FUNCTIONS.GetDescodeDescr('C_DOC_POS_STATUS', C_DOC_POS_STATUS) C_DOC_POS_STATUS
                                , PER.PER_NAME
                                , PER.PER_SHORT_NAME
                                , DPD.DIC_PDE_FREE_TABLE_1_ID
                                , DPD.DIC_PDE_FREE_TABLE_2_ID
                                , DPD.DIC_PDE_FREE_TABLE_3_ID
                                , DPD.PDE_INTERMEDIATE_DELAY
                                , DPD.PDE_FINAL_DELAY
                             from DOC_POSITION POS
                                , DOC_DOCUMENT DOC
                                , PAC_PERSON PER
                                , DOC_POSITION_DETAIL DPD
                                , table(DOC_LIB_SUBCONTRACTP.GetSUPOGaugeId(DOC.PAC_THIRD_ID) ) DocGauge
                            where POS.FAL_LOT_ID = iFalLotId
                              and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
                              and POS.DOC_POSITION_ID = DPD.DOC_POSITION_ID
                              and DOC.DOC_GAUGE_ID = DocGauge.column_value
                              and DOC.PAC_THIRD_ID = PER.PAC_PERSON_ID) loop
        ioPacThirdId          := tplOriginDoc.PAC_THIRD_ID;
        ioThirdName           := TplOriginDoc.PER_NAME;
        ioThirdShortName      := TplOriginDoc.PER_SHORT_NAME;
        ioStatus              := TplOriginDoc.C_DOC_POS_STATUS;
        ioDicPdeFreeTable1Id  := TplOriginDoc.DIC_PDE_FREE_TABLE_1_ID;
        ioDicPdeFreeTable2Id  := TplOriginDoc.DIC_PDE_FREE_TABLE_2_ID;
        ioDicPdeFreeTable3Id  := TplOriginDoc.DIC_PDE_FREE_TABLE_3_ID;
        ioFinalDelay          := TplOriginDoc.PDE_FINAL_DELAY;
        ioIntermediateDelay   := TplOriginDoc.PDE_INTERMEDIATE_DELAY;
        exit;
      end loop;
    elsif nvl(iFalLotPropId, 0) <> 0 then
      -- Type de fabrication
      for TplPropTask in (select TAL.PAC_SUPPLIER_PARTNER_ID
                               , PER.PER_NAME
                               , PER.PER_SHORT_NAME
                            from FAL_LOT_PROP LOT
                               , FAL_TASK_LINK_PROP TAL
                               , PAC_PERSON PER
                           where LOT.FAL_LOT_PROP_ID = iFalLotPropId
                             and LOT.FAL_LOT_PROP_ID = TAL.FAL_LOT_PROP_ID
                             and TAL.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID) loop
        ioPacThirdId          := TplPropTask.PAC_SUPPLIER_PARTNER_ID;
        ioThirdName           := TplPropTask.PER_NAME;
        ioThirdShortName      := TplPropTask.PER_SHORT_NAME;
        ioStatus              := '';
        ioDicPdeFreeTable1Id  := '';
        ioDicPdeFreeTable2Id  := '';
        ioDicPdeFreeTable3Id  := '';
        ioFinalDelay          := null;
        ioIntermediateDelay   := null;
        exit;
      end loop;
    end if;
  end GetBatchOrigindocInfo;

  /**
  * function GetDefaultComplDataInfo
  * Description :
  *   Retreive default subcontracting complementary data information
  * @created VJE
  * @lastUpdate
  * @public
  * @param   iDateValidity : Validity date
  * @param   iGcoGoodID : Subcontracted good
  * @param   ioDicFabConditionID : Subcontracting condition
  * @param   ioPacSupplierPartnerID : default subcontractor
  * @return  Default subcontracting complementary data id found
  */
  function GetDefaultComplDataInfo(iDateValidity in date, iGcoGoodID in number, ioDicFabConditionID in out varchar2, ioPacSupplierPartnerID in out number)
    return number
  is
    lnCompDataID GCO_COMPL_DATA_SUBCONTRACT.GCO_COMPL_DATA_SUBCONTRACT_ID%type;
  begin
    for tplComplData in (select   CSU.DIC_FAB_CONDITION_ID
                                , CSU.PAC_SUPPLIER_PARTNER_ID
                                , CSU.GCO_GCO_GOOD_ID
                                , CSU.GCO_COMPL_DATA_SUBCONTRACT_ID
                             from GCO_COMPL_DATA_SUBCONTRACT CSU
                            where nvl(CSU.CSU_VALIDITY_DATE, iDateValidity) <= iDateValidity
                              and CSU.GCO_GOOD_ID = iGcoGoodID
                         order by CSU.CSU_DEFAULT_SUBCONTRACTER desc
                                , CSU.CSU_VALIDITY_DATE desc) loop
      if    (nvl(ioPacSupplierPartnerId, tplComplData.PAC_SUPPLIER_PARTNER_ID) = tplComplData.PAC_SUPPLIER_PARTNER_ID)
         or (nvl(ioDicFabConditionID, tplComplData.DIC_FAB_CONDITION_ID) = tplComplData.DIC_FAB_CONDITION_ID) then
        ioDicFabConditionID     := tplComplData.DIC_FAB_CONDITION_ID;
        ioPacSupplierPartnerID  := tplComplData.PAC_SUPPLIER_PARTNER_ID;
        lnCompDataID            := tplComplData.GCO_COMPL_DATA_SUBCONTRACT_ID;
        exit;
      end if;
    end loop;

    return lnCompDataID;
  end GetDefaultComplDataInfo;
end FAL_LIB_SUBCONTRACTP;
