--------------------------------------------------------
--  DDL for Package Body FAL_COMPONENT_MVT_RETOUR
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_COMPONENT_MVT_RETOUR" 
is
  /**
  * Description
  *    Exécution des mouvements de retour préparés.
  */
  procedure ApplyReturnMovements(
    aFAL_LOT_ID          in     number default null
  , aDOC_DOCUMENT_ID     in     number default null
  , aDOC_POSITION_ID     in     number default null
  , aLOM_SESSION         in     varchar2
  , aContext             in     integer default FAL_COMPONENT_LINK_FUNCTIONS.ctxtComponentReturn
  , aReturnDate          in     date
  , aErrorCode           in out varchar2
  , aErrorMsg            in out varchar2
  , aiShutDownExceptions in     integer default 0
  )
  is
  begin
    for ltplLot in (select distinct TAL.FAL_LOT_ID
                                  , POS.DOC_DOCUMENT_ID
                               from DOC_POSITION POS
                                  , FAL_TASK_LINK TAL
                              where POS.DOC_DOCUMENT_ID = aDOC_DOCUMENT_ID
                                and TAL.FAL_SCHEDULE_STEP_ID = POS.FAL_SCHEDULE_STEP_ID
                    union
                    select distinct TAL.FAL_LOT_ID
                                  , POS.DOC_DOCUMENT_ID
                               from DOC_POSITION POS
                                  , FAL_TASK_LINK TAL
                              where POS.DOC_POSITION_ID = aDOC_POSITION_ID
                                and TAL.FAL_SCHEDULE_STEP_ID = POS.FAL_SCHEDULE_STEP_ID
                    union
                    select FAL_LOT_ID
                         , null DOC_DOCUMENT_ID
                      from FAL_LOT
                     where FAL_LOT_ID = aFAL_LOT_ID) loop
      -- Préparation de la liste des mouvements de stock
      FAL_STOCK_MOVEMENT_FUNCTIONS.InitPreparedStockMovement;
      -- MAJ des liens composants lot pseudo (FAL_LOT_MATERIAL_LINK)
      FAL_COMPONENT_FUNCTIONS.UpdateFalLotMatLinkafterOutput(aLOM_SESSION, ltplLot.FAL_LOT_ID, null, aContext);

      if aContext <> FAL_COMPONENT_LINK_FUNCTIONS.ctxtDerivativeReturn then
        -- Modification ou suppression des appairages dépendant des entrées atelier démontées
        FAL_LOT_DETAIL_FUNCTIONS.UpdateAlignementOnMvtComponent(aLOM_SESSION);
        -- Mise à jour du lot de fabrication (qté max réceptionnable)
        FAL_BATCH_FUNCTIONS.UpdateBatchQtyForReceipt(ltplLot.FAL_LOT_ID, -1);
        -- Mise à jour de l'ordre de fabrication
        FAL_ORDER_FUNCTIONS.UpdateOrder(0, ltplLot.FAL_LOT_ID);
        -- MAJ des entrées atelier avec la quantité retournée.
        FAL_COMPONENT_FUNCTIONS.UpdateFactoryEntries(aLOM_SESSION);
        -- Création des sorties atelier de type retour
        FAL_COMPONENT_FUNCTIONS.CreateAllFactoryMovements(aFAL_LOT_ID              => ltplLot.FAL_LOT_ID
                                                        , aDOC_DOCUMENT_ID         => aDOC_DOCUMENT_ID
                                                        , aFCL_SESSION             => aLOM_SESSION
                                                        , aPreparedStockMovement   => FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements
                                                        , aOUT_DATE                => aReturnDate
                                                        , aMovementKind            => FAL_STOCK_MOVEMENT_FUNCTIONS.mktRetourAtelierVersStock
                                                        , aC_OUT_ORIGINE           => '4'
                                                         );
        -- Création des sorties atelier de type Déchet
        FAL_COMPONENT_FUNCTIONS.CreateAllFactoryMovements(aFAL_LOT_ID              => ltplLot.FAL_LOT_ID
                                                        , aDOC_DOCUMENT_ID         => aDOC_DOCUMENT_ID
                                                        , aFCL_SESSION             => aLOM_SESSION
                                                        , aPreparedStockMovement   => FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements
                                                        , aOUT_DATE                => aReturnDate
                                                        , aMovementKind            => FAL_STOCK_MOVEMENT_FUNCTIONS.mktRetourAtelierVersDechet
                                                        , aC_OUT_ORIGINE           => '4'
                                                         );
      else
        -- Création des mouvements de réception des dérivés
        FAL_COMPONENT_FUNCTIONS.CreateFactoryMvtsOnRecept(aFalLotId                 => ltplLot.FAL_LOT_ID
                                                        , aSessionId                => aLOM_SESSION
                                                        , aDate                     => aReturnDate
                                                        , aPreparedStockMovements   => FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements
                                                         );
      end if;

      -- Génération des mouvements de stock
      FAL_STOCK_MOVEMENT_FUNCTIONS.ApplyPreparedStockMovements(FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements
                                                             , aErrorCode
                                                             , aErrorMsg
                                                             , FAL_STOCK_MOVEMENT_FUNCTIONS.ctxDefault
                                                             , aiShutdownExceptions
                                                              );

      if aContext <> FAL_COMPONENT_LINK_FUNCTIONS.ctxtDerivativeReturn then
        -- Mise à jour des réseaux
        FAL_NETWORK.MiseAJourReseaux(ltplLot.FAL_LOT_ID, FAL_NETWORK.ncRetourComposant, '');
        -- Mise à jour des Entrées Atelier avec les positions de stock créées dans le stock Atelier par les mouvements de stock
        FAL_STOCK_MOVEMENT_FUNCTIONS.UpdFactEntriesWthAppliedStkMvt(FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements);
      end if;

      -- Déréservation du lot de fabrication
      FAL_BATCH_RESERVATION.ReleaseReservedbatches(aLOM_SESSION);
      -- Purge des tables de travail
      FAL_LOT_MAT_LINK_TMP_FCT.PurgeAllTemporaryTable(aLOM_SESSION);
    end loop;
  end ApplyReturnMovements;

  /**
  * Description : Génération des composants temporaires en préparation d'un retour
  *               de composants
  */
  procedure ComponentGenForReturn(
    aFAL_LOT_ID       FAL_LOT.FAL_LOT_ID%type default null
  , aDOC_DOCUMENT_ID  number default null
  , aDOC_POSITION_ID  number default null
  , aFCL_SESSION_ID   varchar2
  , aContext          integer default 9
  , aOpSeqFrom        integer default null
  , aOpSeqTo          integer default null
  , aComponentSeqFrom number default null
  , aComponentSeqTo   number default null
  , aReturnQty        number default 0
  , aTrashqty         number default 0
  , aReceptionQty     number default 0
  , iLocationId       number default null
  , iTrashLocationId  number default null
  )
  is
  begin
    -- Génération des composants temporaires
    FAL_LOT_MAT_LINK_TMP_FUNCTIONS.CreateComponents(aFalLotId           => aFAL_LOT_ID
                                                  , aDocumentId         => aDOC_DOCUMENT_ID
                                                  , aPositionId         => aDOC_POSITION_ID
                                                  , aSessionId          => aFCL_SESSION_ID
                                                  , aContext            => aContext
                                                  , aOpSeqFrom          => aOpSeqFrom
                                                  , aOpSeqTo            => aOpSeqTo
                                                  , aComponentSeqFrom   => aComponentSeqFrom
                                                  , aComponentSeqTo     => aComponentSeqTo
                                                  , aReceptionQty       => aReceptionQty
                                                   );

    -- Génération des liens de réservation
    if    (nvl(aReturnQty, 0) <> 0)
       or (nvl(aTrashQty, 0) <> 0)
       or (nvl(aReceptionQty, 0) <> 0)
       or (aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtSubContractPReturn)
       or (aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtSubContractOReturn) then
      FAL_COMPONENT_LINK_FCT.GlobalComponentLinkGeneration(aFAL_LOT_MAT_LINK_TMP_ID   => null
                                                         , aFAL_LOT_ID                => aFAL_LOT_ID
                                                         , aDOC_DOCUMENT_ID           => aDOC_DOCUMENT_ID
                                                         , aDOC_POSITION_ID           => aDOC_POSITION_ID
                                                         , aLOM_SESSION               => aFCL_SESSION_ID
                                                         , aContext                   => aContext
                                                         , aTrashQty                  => aTrashQty
                                                         , aReturnQty                 => aReturnQty
                                                         , iLocationId                => iLocationId
                                                         , iTrashLocationId           => iTrashLocationId
                                                          );
    end if;
  end;
end;
