--------------------------------------------------------
--  DDL for Package Body DOC_LIB_SUBCONTRACTO
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_LIB_SUBCONTRACTO" 
is
  /**
  * Description
  *   Indique si le document demande le transfert des composants du stock sous-traitant en atelier
  *   1. position de type bien (exclu les positions outils)
  *   2. opération de sous-traitance lié
  *   3. initialisation de la quantité du mouvement demandé par le flux
  *   4. exclu les opérations de sous-traitance d'achat
  *   5. genre de mouvement spécifié sur la position (BRCST, BRST ou FFST)
  *   6. demande de mise à jour de l'opération par le genre de mouvement (en principe BRST et FFST)
  */
  function DoDocumentComponentsMvt(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    lDoDocumentComponentsMvt pls_integer;
  begin
    select count(*)
      into lDoDocumentComponentsMvt
      from dual
     where exists(select DOC_POSITION_ID
                    from DOC_POSITION
                   where DOC_DOCUMENT_ID = iDocumentId
                     and doPositiontComponentsMvt(DOC_POSITION_ID) = 1);

    return lDoDocumentComponentsMvt;
  end DoDocumentComponentsMvt;

  /**
  * Description
  *   Indique si la position demande le transfert des composants du stock sous-traitant en atelier
  *   1. position de type bien (exclu les positions outils)
  *   2. opération de sous-traitance lié
  *   3. initialisation de la quantité du mouvement demandé par le flux
  *   4. exclu les opérations de sous-traitance d'achat
  *   5. genre de mouvement spécifié sur la position (BRCST, BRST ou FFST)
  *   6. demande de mise à jour de l'opération par le genre de mouvement (en principe BRST et FFST)
  */
  function doPositiontComponentsMvt(iPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    lDoPositiontComponentsMvt pls_integer;
  begin
    select count(*)
      into lDoPositiontComponentsMvt
      from dual
     where exists(
             select POS.DOC_POSITION_ID
               from DOC_POSITION POS
                  , DOC_POSITION_DETAIL PDE
                  , STM_MOVEMENT_KIND MOK
              where POS.DOC_POSITION_ID = iPositionId
                and POS.C_GAUGE_TYPE_POS = '1'   -- position de type bien (exclu les positions outils)
                and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
                and PDE.FAL_SCHEDULE_STEP_ID is not null   -- opération de sous-traitance lié
                and (   PDE.PDE_MOVEMENT_QUANTITY > 0
                     or PDE.PDE_BALANCE_QUANTITY_PARENT > 0)   -- initialisation de la quantité du mouvement demandé par le flux
                and POS.FAL_LOT_ID is null   -- exclu les opérations de sous-traitance d'achat
                and MOK.STM_MOVEMENT_KIND_ID = POS.STM_MOVEMENT_KIND_ID   -- genre de mouvement spécifié sur la position (BRCST, BRST ou FFST)
                and nvl(MOK.MOK_UPDATE_OP, 0) = 1);   -- demande de mise à jour de l'opération (en principe BRST et FFST)

    return lDoPositiontComponentsMvt;
  end doPositiontComponentsMvt;

  /**
  * Description
  *   Retourne le gabarit à utiliser pour les commandes de sous-traitance opératoire.
  */
  function getOrderGaugeID
    return DOC_GAUGE.DOC_GAUGE_ID%type
  as
  begin
    /* Lecture de la config contenant le gabarit Commande sous-traitance */
    return FWK_I_LIB_ENTITY.getIdfromPk2('DOC_GAUGE', 'GAU_DESCRIBE', PCS.PC_CONFIG.GetConfig('DOC_SUBCONTRACTO_ORDER_GAUGE') );
  end getOrderGaugeID;

  /**
  * Description
  *   Retourne les id des gabarits pour un fournisseur et un type de gabarits
  */
  function GetSubContractGauge(
    iSubContracterId in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type default null
  , iGaugeTitle      in DOC_GAUGE_STRUCTURED.C_GAUGE_TITLE%type
  )
    return ID_TABLE_TYPE pipelined
  is
    lFlowId DOC_GAUGE_FLOW.DOC_GAUGE_FLOW_ID%type;
  begin
    lFlowId  := DOC_LIB_GAUGE.GetFlowID(iAdminDomain => cAdminDomainPurchase, iThirdID => iSubContracterId);

    -- retrieve the gauge in the default purchase flow which match with the gauge title
    for ltplGaugeID in (select GAD.DOC_GAUGE_ID
                          from DOC_GAUGE_FLOW_DOCUM GAD
                             , DOC_GAUGE_STRUCTURED GAS
                         where GAD.DOC_GAUGE_FLOW_ID = lFlowId
                           and GAS.DOC_GAUGE_ID = GAD.DOC_GAUGE_ID
                           and GAS.C_GAUGE_TITLE = iGaugeTitle
                           and IsSUOOGauge(GAD.DOC_GAUGE_ID) = 1) loop
      pipe row(ltplGaugeID.DOC_GAUGE_ID);
    end loop;
  end GetSubContractGauge;

  /**
  * Description
  *   Retourne la quantité totale commandée en unité de stockage pour l'opération
  *   externe via les CST.
  */
  function getOrderedQty(iExtTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return DOC_POSITION.POS_BASIS_QUANTITY_SU%type
  as
    lOrderedQty DOC_POSITION.POS_BASIS_QUANTITY_SU%type;
  begin
    select nvl(sum(POS_BASIS_QUANTITY_SU), 0)
      into lOrderedQty
      from table(FAL_I_LIB_TASK_LINK.getLinkedCSTDocsIDs(iExtTaskLinkID) ) cst
         , DOC_POSITION pos
     where pos.DOC_DOCUMENT_ID = cst.column_value
       and pos.C_GAUGE_TYPE_POS = '1';

    return lOrderedQty;
  end getOrderedQty;

  /**
  * function IsSUOOGauge
  * Description
  *   Renvoie 1 si le gabarit est une CST
  * @created fp 22.05.2012
  * @lastUpdate
  * @public
  * @param igaugeId : gabarit à tester
  * @return
  */
  function IsSUOOGauge(iGaugeId in DOC_GAUGE.DOC_GAUGE_ID%type)
    return number
  is
  begin
    if (getOrderGaugeID = iGaugeId) then
      return 1;
    else
      return 0;
    end if;
  end IsSUOOGauge;

  /**
  * Description
  *   return SUOO (CST in french) gauge id for a supplier
  */
  function GetSUOOGaugeId(iSubContracterId in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type default null)
    return ID_TABLE_TYPE pipelined
  is
  begin
    for tplGaugeId in (select *
                         from table(GetSubContractGauge(iSubContracterId => iSubContracterId, iGaugeTitle => '1') ) ) loop
      pipe row(tplGaugeId.column_value);
    end loop;
  end GetSUOOGaugeId;

  /**
  * Description
  *   Indique si les mouvements de stock des positions liées à des opérations
  *   de fabrication comportent des biens avec caractérisations
  */
  function IsSubCOComponentsWithChar(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    lCount pls_integer;
  begin
    select count(*)
      into lCount
      from DOC_POSITION POS
         , FAL_TASK_LINK TAL
         , FAL_LOT_MATERIAL_LINK LMA
         , GCO_CHARACTERIZATION CHA
     where POS.DOC_DOCUMENT_ID = iDocumentId
       and TAL.FAL_SCHEDULE_STEP_ID = POS.FAL_SCHEDULE_STEP_ID
       and LMA.FAL_LOT_ID = TAL.FAL_LOT_ID
       and LMA.LOM_TASK_SEQ = TAL.SCS_STEP_NUMBER
       and CHA.GCO_GOOD_ID = LMA.GCO_GOOD_ID
       and CHA.CHA_STOCK_MANAGEMENT = 1;

    return sign(lCount);
  end IsSubCOComponentsWithChar;

  /**
  * Description
  *   Indique s'il y a une rupture de stock (dans le stock STT) pour
  *     un ou plusieurs composants d'opérations liées
  */
  function IsBatchCptStkOutage(iPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    lResult number(1) := 0;
  begin
    for ltplDocGood in (select POS.DOC_DOCUMENT_ID
                             , LMA.GCO_GOOD_ID
                          from DOC_POSITION POS
                             , FAL_TASK_LINK TAL
                             , FAL_LOT_MATERIAL_LINK LMA
                             , FAL_LOT LOT
                         where POS.DOC_POSITION_ID = iPositionId
                           and TAL.FAL_SCHEDULE_STEP_ID = POS.FAL_SCHEDULE_STEP_ID
                           and LMA.FAL_LOT_ID = TAL.FAL_LOT_ID
                           and LOT.FAL_LOT_ID = LMA.FAL_LOT_ID
                           and LOT.LOT_TOTAL_QTY <> 0
                           and LMA.C_KIND_COM = 1   -- Genre de lien composant uniquement
                           and LMA.LOM_TASK_SEQ = TAL.SCS_STEP_NUMBER) loop
      if IsBatchCptStkOutage(iDocumentId => ltplDocGood.DOC_DOCUMENT_ID, iGoodId => ltplDocGood.GCO_GOOD_ID) = 1 then
        lResult  := 1;
      end if;
    end loop;

    return lResult;
  end IsBatchCptStkOutage;

  /**
  * Description
  *   Indique s'il y a une rupture de stock (dans le stock STT) pour
  *     un ou plusieurs composants d'opérations liées
  */
  function IsBatchCptStkOutage(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, iGoodId in DOC_POSITION.GCO_GOOD_ID%type default null)
    return number
  is
    lResult number(1) := 0;
  begin
    for ltplNeed in (select   LMA.GCO_GOOD_ID
                            , STM_I_LIB_STOCK.getSubCStockID(POS.PAC_THIRD_ID) STM_STOCK_ID
                            , sum(POS.POS_BASIS_QUANTITY_SU * LMA.LOM_UTIL_COEF / LMA.LOM_REF_QTY + LMA.LOM_ADJUSTED_QTY - LMA.LOM_ADJUSTED_QTY_RECEIPT)
                                                                                                                                                       QTY_NEED
                         from DOC_POSITION POS
                            , STM_MOVEMENT_KIND MOK
                            , FAL_TASK_LINK TAL
                            , FAL_LOT_MATERIAL_LINK LMA
                            , FAL_LOT LOT
                        where POS.DOC_DOCUMENT_ID = iDocumentId
                          and MOK.STM_MOVEMENT_KIND_ID = POS.STM_MOVEMENT_KIND_ID
                          and nvl(MOK.MOK_UPDATE_OP, 0) = 1
                          and TAL.FAL_SCHEDULE_STEP_ID = POS.FAL_SCHEDULE_STEP_ID
                          and LMA.FAL_LOT_ID = TAL.FAL_LOT_ID
                          and LOT.FAL_LOT_ID = LMA.FAL_LOT_ID
                          and LOT_TOTAL_QTY <> 0
                          and LMA.GCO_GOOD_ID = nvl(iGoodId, LMA.GCO_GOOD_ID)
                          and LMA.LOM_TASK_SEQ = TAL.SCS_STEP_NUMBER
                          and LMA.C_KIND_COM = 1   -- Genre de lien composant uniquement
                          and LMA.C_DISCHARGE_COM = 6   -- Mvts de stock pour la sous-traitance
                     group by LMA.GCO_GOOD_ID
                            , STM_I_LIB_STOCK.getSubCStockID(POS.PAC_THIRD_ID) ) loop
      declare
        lBalanceQuantity FAL_LOT_MATERIAL_LINK.LOM_REF_QTY%type   := ltplNeed.QTY_NEED;
      begin
        -- teste si la quantité disponible en stock sous-traitant suffit à couvrir le besoin
        lBalanceQuantity  := lBalanceQuantity - STM_I_LIB_STOCK_POSITION.getSumAvailableQty(iGoodID    => ltplNeed.GCO_GOOD_ID
                                                                                          , iStockID   => ltplNeed.STM_STOCK_ID);

        -- si quantité dispo pas suffisante, on regarde si le besoin est couvert par une attribution
        if lBalanceQuantity > 0 then
          -- contrôle attributions
          for ltplDetail in (select POS.DOC_POSITION_ID
                                  , LMA.FAL_LOT_MATERIAL_LINK_ID
                                  , POS.POS_BASIS_QUANTITY_SU * LMA.LOM_UTIL_COEF / LMA.LOM_REF_QTY + LMA.LOM_ADJUSTED_QTY - LMA.LOM_ADJUSTED_QTY_RECEIPT
                                                                                                                                                       QTY_NEED
                               from DOC_POSITION POS
                                  , STM_MOVEMENT_KIND MOK
                                  , FAL_TASK_LINK TAL
                                  , FAL_LOT_MATERIAL_LINK LMA
                                  , FAL_LOT LOT
                              where POS.DOC_DOCUMENT_ID = iDocumentId
                                and MOK.STM_MOVEMENT_KIND_ID = POS.STM_MOVEMENT_KIND_ID
                                and nvl(MOK.MOK_UPDATE_OP, 0) = 1
                                and TAL.FAL_SCHEDULE_STEP_ID = POS.FAL_SCHEDULE_STEP_ID
                                and LMA.FAL_LOT_ID = TAL.FAL_LOT_ID
                                and LOT.FAL_LOT_ID = LMA.FAL_LOT_ID
                                and LOT_TOTAL_QTY <> 0
                                and LMA.LOM_TASK_SEQ = TAL.SCS_STEP_NUMBER
                                and LMA.C_KIND_COM = 1   -- Genre de lien composant uniquement
                                and LMA.C_DISCHARGE_COM = 6   -- Mvts de stock pour la sous-traitance
                                and LMA.GCO_GOOD_ID = ltplNeed.GCO_GOOD_ID) loop
            declare
              -- recherche de la qté attribuée au composant
              lAttribQty FAL_LOT_MATERIAL_LINK.LOM_REF_QTY%type
                := FAL_COMPONENT_LINK_FUNCTIONS.SumOfComponentAttributions(aFAL_LOT_MATERIAL_LINK_ID   => ltplDetail.FAL_LOT_MATERIAL_LINK_ID
                                                                         , aSTM_STOCK_ID               => ltplNeed.STM_STOCK_ID
                                                                          );
            begin
              -- maj qté solde
              lBalanceQuantity  := lBalanceQuantity - least(ltplDetail.QTY_NEED, lAttribQty);
              exit when lBalanceQuantity <= 0;

              -- si reste solde et que le beoin n'est pas couvert alors MANCO
              if     lBalanceQuantity > 0
                 and ltplDetail.QTY_NEED - lAttribQty > 0 then
                lResult  := 1;
              end if;
            end;
          end loop;
        end if;
      end;
    end loop;

    return lResult;
  end IsBatchCptStkOutage;

  /**
  * Description
  *    Indique si les mouvements de sortie composants sous-traitance ont été générés
  */
  function DocMovementsGenerated(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    lCount pls_integer;
  begin
    for ltplPos in (select DOC_POSITION_ID
                      from DOC_POSITION
                     where DOC_DOCUMENT_ID = iDocumentId) loop
      -- Le sub query donne la liste des composant pour lesquels des mouvements entrée atelier on été fait par la position courante ou un de ses parents
      -- Ensuite le but est de regarder si on a au moins un composant dont les mouvements n'ont pas été faits
      -- Si tous les composants n'ont pas de mouvements manquants alors c'est OK
      select count(*)
        into lCount
        from (select LMA.FAL_LOT_MATERIAL_LINK_ID
                from DOC_POSITION POS
                   , FAL_TASK_LINK TAL
                   , FAL_LOT_MATERIAL_LINK LMA
               where POS.DOC_POSITION_ID = ltplPos.DOC_POSITION_ID
                 and TAL.FAL_SCHEDULE_STEP_ID = POS.FAL_SCHEDULE_STEP_ID
                 and LMA.FAL_LOT_ID = TAL.FAL_LOT_ID
                 and LMA.LOM_TASK_SEQ = TAL.SCS_STEP_NUMBER
                 and LMA.FAL_LOT_MATERIAL_LINK_ID not in(
                                                       select FAL_LOT_MATERIAL_LINK_ID
                                                         from FAL_FACTORY_IN
                                                        where DOC_DOCUMENT_ID in(select column_value
                                                                                   from table
                                                                                             (DOC_I_LIB_DOCUMENT.getPosDocParentIdList(ltplPos.DOC_POSITION_ID) ) ) ) );

      exit when lCount > 0;
    end loop;

    if lCount > 0 then
      return 0;
    else
      return 1;
    end if;
  end DocMovementsGenerated;

  /**
  * Description
  *   Retourne pour une oépration de sous-traitance, la quantité pour laquelle on a effectué les mouvements composants
  */
  function GetOperationMvtQty(iFalScheduleStepId in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return number
  is
    lMvtQty DOC_POSITION.POS_BASIS_QUANTITY_SU%type;
  begin
    select nvl(sum(POS.POS_BASIS_QUANTITY_SU), 0)
      into lMvtQty
      from DOC_POSITION POS
         , STM_MOVEMENT_KIND MOK
     where FAL_SCHEDULE_STEP_ID = iFalScheduleStepId
       and POS.POS_GENERATE_SUBCO_COMP_MVT = 1
       and POS.C_GAUGE_TYPE_POS = '1'
       and MOK.STM_MOVEMENT_KIND_ID = pos.STM_MOVEMENT_KIND_ID
       and nvl(MOK.MOK_UPDATE_OP, 0) = 1;

    return lMvtQty;
  end GetOperationMvtQty;

  /**
  * Description
  *   Retourne pour une oépration de sous-traitance, la quantité en CST (resp SUOO en anglais)
  */
  function GetOperationSUOOQty(iFalScheduleStepId in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return number
  is
    lSUOOQty DOC_POSITION.POS_BASIS_QUANTITY_SU%type;
  begin
    select nvl(sum(POS.POS_BASIS_QUANTITY_SU), 0)
      into lSUOOQty
      from DOC_POSITION POS
     where FAL_SCHEDULE_STEP_ID = iFalScheduleStepId
       and C_GAUGE_TYPE_POS = '1'
       and IsSUOOGauge(POS.DOC_GAUGE_ID) = 1;

    return lSUOOQty;
  end GetOperationSUOOQty;

  /**
  * Description
  *   Indique si une des position parent a déjà fait les mouvements de sortie composants
  */
  function IsMovementOnPosParent(iPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
  begin
    for tplParentPos in (select distinct POS_PARENT.DOC_POSITION_ID
                                       , POS_PARENT.POS_GENERATE_SUBCO_COMP_MVT
                                    from DOC_POSITION_DETAIL PDE
                                       , DOC_POSITION_DETAIL PDE_PARENT
                                       , DOC_POSITION POS_PARENT
                                   where PDE.DOC_POSITION_ID = iPositionId
                                     and PDE_PARENT.DOC_POSITION_DETAIL_ID = PDE.DOC_DOC_POSITION_DETAIL_ID
                                     and POS_PARENT.DOC_POSITION_ID = PDE_PARENT.DOC_POSITION_ID) loop
      if tplParentPos.POS_GENERATE_SUBCO_COMP_MVT = 0 then
        return IsMovementOnPosParent(tplParentPos.DOC_POSITION_ID);
      else
        return 1;
      end if;
    end loop;

    return 0;
  end IsMovementOnPosParent;

  /**
  * Description
  *   Vérifie si les lots associés aux positions du document sont lancés pour permettre la réception du lot.
  */
  procedure checkBatchesLaunch(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, oError out varchar2)
  is
    lvError varchar2(4000);
  begin
    lvError  := null;

    -- Traite chaque position lié à une opération de sous-traitance opératoire pour déterminer si la réception du lot
    -- peut être effectué. Le lot ne doit pas être planifié.
    for ltplPos in (select LOT.C_LOT_STATUS
                         , LOT.LOT_REFCOMPL
                      from DOC_POSITION POS
                         , STM_MOVEMENT_KIND MOK
                         , FAL_LOT LOT
                         , FAL_TASK_LINK TAL
                     where POS.DOC_DOCUMENT_ID = iDocumentID
                       and POS.C_GAUGE_TYPE_POS = '1'
                       and MOK.STM_MOVEMENT_KIND_ID = POS.STM_MOVEMENT_KIND_ID
                       and LOT.FAL_LOT_ID = TAL.FAL_LOT_ID
                       and TAL.FAL_SCHEDULE_STEP_ID = POS.FAL_SCHEDULE_STEP_ID
                       and POS.FAL_LOT_ID is null) loop
      -- Vérifie le statut du lot
      if ltplPos.C_LOT_STATUS = FAL_I_LIB_BATCH.cLotStatusPlanified then
        lvError  := PCS.PC_FUNCTIONS.TranslateWord('La réception du lot suivant est impossible (lot au statut planifié) : ');
        lvError  := lvError || ltplPos.LOT_REFCOMPL;
      end if;

      -- Quitte la boucle dés la première erreur.
      exit when lvError is not null;
    end loop;

    oError   := lvError;
  end checkBatchesLaunch;

  /**
  * Description
  *   Retourne la quantité en cours de confirmation pour une opération
  */
  function GetConfirmQty(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, iTaskLinkId in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return number
  is
    lMovementQty DOC_POSITION_DETAIL.PDE_MOVEMENT_QUANTITY%type;
  begin
    select max(PDE.PDE_MOVEMENT_QUANTITY)
      into lMovementQty
      from DOC_POSITION POS
         , DOC_POSITION_DETAIL PDE
         , STM_MOVEMENT_KIND MOK
     where POS.DOC_DOCUMENT_ID = iDocumentId
       and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
       and POS.C_GAUGE_TYPE_POS = '1'
       and POS.FAL_SCHEDULE_STEP_ID = iTaskLinkId
       and POS.FAL_LOT_ID is null
       and nvl(MOK.MOK_UPDATE_OP, 0) = 1
       and MOK.STM_MOVEMENT_KIND_ID = POS.STM_MOVEMENT_KIND_ID;

    return nvl(lMovementQty, 0);
  end GetConfirmQty;

  /**
  * Description
  *   Indique si le BST peut être confirmé. En effet, la confirmation d'un BST implique un suivi d'avancement.
  *   Celui-ci ne peut être fait que sur la première opération ou si la quantité réalisée (TAL_RELEASE_QTY)
  *   de l'opération principale précédente et supérieure ou égale à la quantité confirmée moins la quantité
  *   réalisée de l'opération courante.
  *   Confirmation possible avec Qté supplémentaire si la config FAL_PFG_ALLOW_INCREASE_QTY_MAN est à TRUE
  */
  function canConfirmBST(iDocumentID in doc_document.doc_document_id%type)
    return number
  as
    lPreviousTaskLink  FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type;
    lAvailableQty      number;
    lQty               number;
    lAskNeed           number                                           := 0;
    lCurrentTaskSupQty number                                           := 0;
    lGapQty            DOC_POSITION_DETAIL.PDE_MOVEMENT_QUANTITY%type;
  begin
    /* Pour chaque position de bien (C_GAUGE_TYPE_POS = 1) du document contenant l'ID de l'opération

       Remarque : On recherche la quantité supplémentaire (quantité soldée sur parent négative) sur le document courant et
       sur le document père si le flux de sous-traitance intégre un BCST. En effet, dans ce cas, Les informations de décharge partielle
       ou de dépassement de quantité sont aussi inscrite sur le détail de position père. Attention il ne faut utiliser les informations
       du document père uniquement si celui-ci n'a pas déjà mis à jour l'opération (le genre de mouvement l'indique).

       Les champs quantité soldé sur parent étant exprimé en unité de document, il indispensable de les convertir en unité de stockage.
       En effet, les quantités de l'opération sont toujours exprimé en unité de stockage.

     */
    for ltplPos in (select POS.FAL_SCHEDULE_STEP_ID
                         , PDE.PDE_MOVEMENT_QUANTITY
                         , PDE.PDE_BALANCE_QUANTITY_PARENT
                         , ACS_FUNCTION.RoundNear(PDE.PDE_BALANCE_QUANTITY_PARENT * POS.POS_CONVERT_FACTOR, 1 / power(10, GOO.GOO_NUMBER_OF_DECIMAL), 1)
                                                                                                                                              as PDE_GAP_QTY_SU
                         , (select nvl(min(ACS_FUNCTION.RoundNear(PDE_PARENT.PDE_BALANCE_QUANTITY_PARENT * POS_PARENT.POS_CONVERT_FACTOR
                                                                , 1 / power(10, GOO_PARENT.GOO_NUMBER_OF_DECIMAL)
                                                                , 1
                                                                 )
                                          )
                                     , 0
                                      )
                              from DOC_POSITION_DETAIL PDE_PARENT
                                 , DOC_POSITION POS_PARENT
                                 , GCO_GOOD GOO_PARENT
                                 , STM_MOVEMENT_KIND MOK_PARENT
                             where PDE_PARENT.DOC_POSITION_DETAIL_ID = PDE.DOC_DOC_POSITION_DETAIL_ID
                               and POS_PARENT.DOC_POSITION_ID = PDE_PARENT.DOC_POSITION_ID
                               and MOK_PARENT.STM_MOVEMENT_KIND_ID = POS_PARENT.STM_MOVEMENT_KIND_ID
                               and nvl(MOK_PARENT.MOK_UPDATE_OP, 0) = 0   -- Pas de mise à jour de l'opération sur le document père
                               and GOO_PARENT.GCO_GOOD_ID = POS_PARENT.GCO_GOOD_ID) as PDE_GAP_QTY_PARENT_SU
                      from DOC_POSITION POS
                         , DOC_POSITION_DETAIL PDE
                         , STM_MOVEMENT_KIND MOK
                         , GCO_GOOD GOO
                     where POS.DOC_DOCUMENT_ID = iDocumentID
                       and PDE.DOC_POSITION_ID = pos.DOC_POSITION_ID
                       and POS.C_GAUGE_TYPE_POS = '1'
                       and POS.FAL_SCHEDULE_STEP_ID is not null
                       and POS.FAL_LOT_ID is null
                       and nvl(MOK.MOK_UPDATE_OP, 0) = 1
                       and MOK.STM_MOVEMENT_KIND_ID = POS.STM_MOVEMENT_KIND_ID
                       and GOO.GCO_GOOD_ID = POS.GCO_GOOD_ID) loop
      /* Première opération principale ou indépendante, confirmation possible avec n'importe quelle quantité */
      if FAL_I_LIB_TASK_LINK.isFirstOp(iTaskLinkID => ltplPos.FAL_SCHEDULE_STEP_ID, iTypeOp => '14') = 1 then
        continue;
      end if;

      /* Recherche de l'opération principale précédente */
      lPreviousTaskLink  := FAL_I_LIB_TASK_LINK.getPreviousMainTaskID(iTaskLinkID => ltplPos.FAL_SCHEDULE_STEP_ID);

      /* Quantité supplémentaire déjà saisie sur l'opération */
      select nvl(sum(FLP_SUP_QTY), 0)
        into lCurrentTaskSupQty
        from FAL_LOT_PROGRESS
       where FAL_SCHEDULE_STEP_ID = ltplPos.FAL_SCHEDULE_STEP_ID;

      /* Quantité disponible sur l'opération =
            Qté réalisée op. précédente
          + Qté en cours de confirmation sur l'opération précédente (si l'op précédente est confirmée dans le même document, on ne voit pas encore son réalisé)
          - Qté réalisée sur l'op. courante + Qté suppl. déjà saisie sur l'op. courante. */
      lAvailableQty      :=
        FAL_I_LIB_TASK_LINK.getReleaseQty(iTaskLinkID => lPreviousTaskLink) +
        GetConfirmQty(iDocumentId => iDocumentID, iTaskLinkId => lPreviousTaskLink) -
        FAL_I_LIB_TASK_LINK.getReleaseQty(iTaskLinkID => ltplPos.FAL_SCHEDULE_STEP_ID) +
        lCurrentTaskSupQty;
      /* Quantité de la position à contrôler */
      lQty               := ltplPos.PDE_MOVEMENT_QUANTITY;

      /* Vérification uniquement si le flux a initialisé la quantité du mouvement. C'est en principe le cas sur les BCST et BST, mais pas
         sur la FST */
      if (lQty > 0) then
        /* Détermine la quantité supplémentaire. C'est la somme des quantités soldées du document courant et du document père. On utilise les
           informations du document père si celui-ci ne met pas à jour l'opération. Attention, une quatité négative représente un dépassement
           de quantité, alors qu'une quantité positive, représente une diminution de la quantité. Il faut donc prendre en compte que les
           quantité négative */
        if     (ltplPos.PDE_GAP_QTY_PARENT_SU < 0)
           and (ltplPos.PDE_GAP_QTY_SU < 0) then
          lGapQty  := ltplPos.PDE_GAP_QTY_PARENT_SU + ltplPos.PDE_GAP_QTY_SU;
        elsif(ltplPos.PDE_GAP_QTY_PARENT_SU < 0) then
          lGapQty  := ltplPos.PDE_GAP_QTY_PARENT_SU;
        elsif(ltplPos.PDE_GAP_QTY_SU < 0) then
          lGapQty  := ltplPos.PDE_GAP_QTY_SU;
        end if;

        /* Si Qté suppl. autorisée, il faut la déduire de la quantité à contrôler (PDE_BALANCE_QUANTITY_PARENT < 0 si on décharge une qté plus grande que le parent) */
        if     FAL_I_LIB_CONSTANT.gcCfgAllowIncreaseQtyMan
           and lGapQty < 0 then
          lQty      := lQty + lGapQty;
          lAskNeed  := 1;
        end if;

        /* Si Qté dispo < Qté position, confirmation impossible */
        if lAvailableQty < lQty then
          return 0;
        end if;
      end if;
    end loop;

    return 1 + lAskNeed;
  end canConfirmBST;

  /**
  * function GetCompDelivQty
  * Description
  *   Renvoi la qté d'un composant livré ou prochainement livré au sous-traitant CAST -> BLAST
  */
  function GetCompDelivQty(
    iFalLotMatLinkID in FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type
  , iLocationID      in STM_LOCATION.STM_LOCATION_ID%type default null
  , iProvQty         in number default 0
  )
    return number
  is
  begin
    return DOC_LIB_SUBCONTRACT.GetCompQty(iFalLotMatLinkID => iFalLotMatLinkID, iLocationID => iLocationID, iProvQty => iProvQty, iC_DOC_LINK_TYPE => '03');
  end GetCompDelivQty;

  /**
  * function GetCompReturnQty
  * Description
  *   Renvoi la qté d'un composant retourné ou prochainement retourné par le sous-traitant CAST -> BLRAST
  */
  function GetCompReturnQty(
    iFalLotMatLinkID in FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type
  , iLocationID      in STM_LOCATION.STM_LOCATION_ID%type default null
  , iProvQty         in number default 0
  )
    return number
  is
  begin
    return DOC_LIB_SUBCONTRACT.GetCompQty(iFalLotMatLinkID => iFalLotMatLinkID, iLocationID => iLocationID, iProvQty => iProvQty, iC_DOC_LINK_TYPE => '04');
  end GetCompReturnQty;

  /**
  * Description
  *   Retourne le gabarit utilisé lors de la génération des BLST - Livraison des composants de la sous-traitance opératoire.
  */
  function getDeliveryGaugeID
    return DOC_GAUGE.DOC_GAUGE_ID%type
  as
  begin
    /* Lecture de la config contenant le gabarit BLST */
    return FWK_I_LIB_ENTITY.getIdfromPk2('DOC_GAUGE', 'GAU_DESCRIBE', PCS.PC_CONFIG.GetConfig('DOC_SUBCONTRACTO_DELIV_GAUGE') );
  end getDeliveryGaugeID;

  /**
  * Description
  *   Retourne le gabarit utilisé lors de la génération des BLRST - Retour des composants de la sous-traitance opératoire.
  */
  function getReturnGaugeID
    return DOC_GAUGE.DOC_GAUGE_ID%type
  as
  begin
    /* Lecture de la config contenant le gabarit BLRST */
    return FWK_I_LIB_ENTITY.getIdfromPk2('DOC_GAUGE', 'GAU_DESCRIBE', PCS.PC_CONFIG.GetConfig('DOC_SUBCONTRACTO_RETURN_GAUGE') );
  end getReturnGaugeID;

  /**
  * Description
  *   Indique si le gabarit utilisé pour un document de transfert en sous-traitance opératoire.
  */
  function isDeliveryGauge(iGaugeId in DOC_GAUGE.DOC_GAUGE_ID%type)
    return number
  is
  begin
    if (getDeliveryGaugeID = iGaugeId) then
      return 1;
    else
      return 0;
    end if;
  end isDeliveryGauge;

  /**
  * Description
  *   Indique si le gabarit utilisé pour un document de retour de sous-traitance opératoire.
  */
  function isReturnGauge(iGaugeId in DOC_GAUGE.DOC_GAUGE_ID%type)
    return number
  is
  begin
    if (getReturnGaugeID = iGaugeId) then
      return 1;
    else
      return 0;
    end if;
  end isReturnGauge;

  /**
  * Description
  *    Retourne 1 si la position est "flagué" sous-traitance opératoire
  */
  function IsPositionSubcontractO(iPositionID in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    lIsPositionSubcontractO number;
  begin
    select sign(DOC_POSITION_ID)
      into lIsPositionSubcontractO
      from DOC_POSITION
     where DOC_POSITION_ID = iPositionID
       and C_GAUGE_TYPE_POS = 1
       and FAL_SCHEDULE_STEP_ID is not null
       and FAL_LOT_ID is null
       and nvl(C_DOC_LOT_TYPE, '000') <> '001';

    return lIsPositionSubcontractO;
  exception
    when no_data_found then
      return 0;
  end IsPositionSubcontractO;

  /**
  * Description
  *    return 1 if the document of Operations subcontracting type
  */
  function IsDocumentSubcontractO(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    return number
  is
    lResult number;
  begin
    -- Sql statement optimized for performances
    select count(*)
      into lResult
      from dual
     where exists(
             select DOC_POSITION_ID
               from DOC_POSITION
              where DOC_DOCUMENT_ID = iDocumentId
                and C_GAUGE_TYPE_POS = 1
                and FAL_SCHEDULE_STEP_ID is not null
                and FAL_LOT_ID is null
                and nvl(C_DOC_LOT_TYPE, '000') <> '001');

    return lResult;
  end IsDocumentSubcontractO;

  /**
   * Description
   *    Retourne 1 si la position appartient à une commande de sous-traitance opératoire.
  */
  function isSUOOPos(iPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    lResult number;
  begin
    select count('x')
      into lResult
      from dual
     where exists(
             select pos.DOC_POSITION_ID
               from DOC_POSITION pos
                  , DOC_GAUGE gau
                  , DOC_GAUGE_STRUCTURED gas
              where pos.DOC_POSITION_ID = iPositionId
                and gau.DOC_GAUGE_ID = pos.DOC_GAUGE_ID
                and gas.DOC_GAUGE_ID = gau.DOC_GAUGE_ID
                and pos.FAL_SCHEDULE_STEP_ID is not null
                and pos.FAL_LOT_ID is null
                and gas.C_GAUGE_TITLE = '1'
                and instr(gau.DIC_GAUGE_TYPE_DOC_ID, pcs.PC_CONFIG.GetConfig('DOC_GAUGE_OP_SUBCONTRACT') ) <> 0);

    return lResult;
  end isSUOOPos;
end DOC_LIB_SUBCONTRACTO;
