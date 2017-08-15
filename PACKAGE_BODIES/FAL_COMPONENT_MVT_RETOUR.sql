--------------------------------------------------------
--  DDL for Package Body FAL_COMPONENT_MVT_RETOUR
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_COMPONENT_MVT_RETOUR" 
is
  /**
  * Description
  *    Ex�cution des mouvements de retour pr�par�s.
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
      -- Pr�paration de la liste des mouvements de stock
      FAL_STOCK_MOVEMENT_FUNCTIONS.InitPreparedStockMovement;
      -- MAJ des liens composants lot pseudo (FAL_LOT_MATERIAL_LINK)
      FAL_COMPONENT_FUNCTIONS.UpdateFalLotMatLinkafterOutput(aLOM_SESSION, ltplLot.FAL_LOT_ID, null, aContext);

      if aContext <> FAL_COMPONENT_LINK_FUNCTIONS.ctxtDerivativeReturn then
        -- Modification ou suppression des appairages d�pendant des entr�es atelier d�mont�es
        FAL_LOT_DETAIL_FUNCTIONS.UpdateAlignementOnMvtComponent(aLOM_SESSION);
        -- Mise � jour du lot de fabrication (qt� max r�ceptionnable)
        FAL_BATCH_FUNCTIONS.UpdateBatchQtyForReceipt(ltplLot.FAL_LOT_ID, -1);
        -- Mise � jour de l'ordre de fabrication
        FAL_ORDER_FUNCTIONS.UpdateOrder(0, ltplLot.FAL_LOT_ID);
        -- MAJ des entr�es atelier avec la quantit� retourn�e.
        FAL_COMPONENT_FUNCTIONS.UpdateFactoryEntries(aLOM_SESSION);
        -- Cr�ation des sorties atelier de type retour
        FAL_COMPONENT_FUNCTIONS.CreateAllFactoryMovements(aFAL_LOT_ID              => ltplLot.FAL_LOT_ID
                                                        , aDOC_DOCUMENT_ID         => aDOC_DOCUMENT_ID
                                                        , aFCL_SESSION             => aLOM_SESSION
                                                        , aPreparedStockMovement   => FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements
                                                        , aOUT_DATE                => aReturnDate
                                                        , aMovementKind            => FAL_STOCK_MOVEMENT_FUNCTIONS.mktRetourAtelierVersStock
                                                        , aC_OUT_ORIGINE           => '4'
                                                         );
        -- Cr�ation des sorties atelier de type D�chet
        FAL_COMPONENT_FUNCTIONS.CreateAllFactoryMovements(aFAL_LOT_ID              => ltplLot.FAL_LOT_ID
                                                        , aDOC_DOCUMENT_ID         => aDOC_DOCUMENT_ID
                                                        , aFCL_SESSION             => aLOM_SESSION
                                                        , aPreparedStockMovement   => FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements
                                                        , aOUT_DATE                => aReturnDate
                                                        , aMovementKind            => FAL_STOCK_MOVEMENT_FUNCTIONS.mktRetourAtelierVersDechet
                                                        , aC_OUT_ORIGINE           => '4'
                                                         );
      else
        -- Cr�ation des mouvements de r�ception des d�riv�s
        FAL_COMPONENT_FUNCTIONS.CreateFactoryMvtsOnRecept(aFalLotId                 => ltplLot.FAL_LOT_ID
                                                        , aSessionId                => aLOM_SESSION
                                                        , aDate                     => aReturnDate
                                                        , aPreparedStockMovements   => FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements
                                                         );
      end if;

      -- G�n�ration des mouvements de stock
      FAL_STOCK_MOVEMENT_FUNCTIONS.ApplyPreparedStockMovements(FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements
                                                             , aErrorCode
                                                             , aErrorMsg
                                                             , FAL_STOCK_MOVEMENT_FUNCTIONS.ctxDefault
                                                             , aiShutdownExceptions
                                                              );

      if aContext <> FAL_COMPONENT_LINK_FUNCTIONS.ctxtDerivativeReturn then
        -- Mise � jour des r�seaux
        FAL_NETWORK.MiseAJourReseaux(ltplLot.FAL_LOT_ID, FAL_NETWORK.ncRetourComposant, '');
        -- Mise � jour des Entr�es Atelier avec les positions de stock cr��es dans le stock Atelier par les mouvements de stock
        FAL_STOCK_MOVEMENT_FUNCTIONS.UpdFactEntriesWthAppliedStkMvt(FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements);
      end if;

      -- D�r�servation du lot de fabrication
      FAL_BATCH_RESERVATION.ReleaseReservedbatches(aLOM_SESSION);
      -- Purge des tables de travail
      FAL_LOT_MAT_LINK_TMP_FCT.PurgeAllTemporaryTable(aLOM_SESSION);
    end loop;
  end ApplyReturnMovements;

  /**
  * Description : G�n�ration des composants temporaires en pr�paration d'un retour
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
    -- G�n�ration des composants temporaires
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

    -- G�n�ration des liens de r�servation
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
