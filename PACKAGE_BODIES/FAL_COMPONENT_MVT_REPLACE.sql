--------------------------------------------------------
--  DDL for Package Body FAL_COMPONENT_MVT_REPLACE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_COMPONENT_MVT_REPLACE" 
is
  /**
  * procedure : ComponentAndLinkGenForReplace
  * Description : G�n�ration des composants temporaires ainsi que des
  *               liens de r�servation pour le remplacement de composants.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param      aFAL_LOT_ID                Lot de fabrication concern�
  * @param      aFAL_LOT_MATERIAL_LINK_ID  Composant � retourner
  * @param      aFCL_SESSION_ID            Session oracle
  * @param      aContext                   Context (6 = remplacement de composants)
  * @param      aDoBatchReservation : Indique si la proc�dure doit r�server le lot.
  *             (Modif interdite pour tous les autres users)
  * @param      aDoDeleteWorkTable : Indique si les tables temporaires utilis�es pour
  *             la pr�paration des mouvements sont nettoy�es en de�but de proc (c-a-d purge des enregistrements
  *             de session et purge des enregistrement de la session en cours)
  */
  procedure ComponentAndLinkGenForReplace(
    aFAL_LOT_ID               number
  , aFAL_LOT_MATERIAL_LINK_ID number
  , aFCL_SESSION_ID           varchar2
  , aContext                  integer default 6
  , aDoBatchReservation       integer default 0
  , aDoDeleteWorkTable        integer default 0
  )
  is
    aBatchReservationError varchar2(255);
  begin
    -- R�servation du lot de fabrication
    if aDoBatchReservation = 1 then
      FAL_BATCH_RESERVATION.PurgeInactiveBatchReservation;
      FAL_BATCH_RESERVATION.ReleaseReservedbatches(aFCL_SESSION_ID);
      FAL_BATCH_RESERVATION.BatchReservation(aFAL_LOT_ID, aFCL_SESSION_ID, aBatchReservationError);

      if trim(aBatchReservationError) <> '' then
        raise_application_error(-20010, aBatchReservationError);
      end if;
    end if;

    -- Purge des tables de travail
    if aDoDeleteWorkTable = 1 then
      FAL_LOT_MAT_LINK_TMP_FUNCTIONS.PurgeAllTemporaryTable(aFCL_SESSION_ID);
    end if;

    -- G�n�ration du composant temporaire � remplacer
    FAL_LOT_MAT_LINK_TMP_FUNCTIONS.CreateComponents(aFalLotId               => aFAL_LOT_ID
                                                  , aFalLotMaterialLinkId   => aFAL_LOT_MATERIAL_LINK_ID
                                                  , aSessionId              => aFCL_SESSION_ID
                                                  , aContext                => aContext
                                                   );
  end ComponentAndLinkGenForReplace;

  /**
  * procedure : ApplyReplacementMovements
  * Description : Ex�cution des mouvements de remplacement pr�par�s.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param      aFAL_LOT_ID : Lot de fabrication
  * @param      aFAL_LOT_MATERIAL_LINK_ID : ID du composant remplac�.
  * @param      aLOM_SESSION : Session oracle
  * @param      aReplacementDate : Date du remplacement
  * @return     aErrorCode : Code retour d'erreur
  * @return     aErrorMsg : Message d'erreur
  * @param      aiShutDownExceptions : indique si l'on fait le raise depuis le PL
  *
  */
  procedure ApplyReplacementMovements(
    aFAL_LOT_ID               in     number
  , aFAL_LOT_MATERIAL_LINK_ID in     number
  , aLOM_SESSION              in     varchar2
  , aReplacementDate          in     date
  , aErrorCode                in out varchar2
  , aErrorMsg                 in out varchar2
  , aiShutdownExceptions             integer default 0
  )
  is
  begin
    -- Pr�paration de la liste des mouvements de stock
    FAL_STOCK_MOVEMENT_FUNCTIONS.InitPreparedStockMovement;
    -- MAJ des liens composants lot pseudo, selon les qt� retour et d�chets
    FAL_COMPONENT_FUNCTIONS.UpdateFalLotMatLinkafterOutput(aLOM_SESSION
                                                         , aFAL_LOT_ID
                                                         , aFAL_LOT_MATERIAL_LINK_ID
                                                         , FAL_COMPONENT_LINK_FUNCTIONS.ctxtComponentReplacingOut
                                                          );
    -- Modification ou suppression des appairages d�pendant des entr�es atelier d�mont�es
    FAL_LOT_DETAIL_FUNCTIONS.UpdateAlignementOnMvtComponent(aLOM_SESSION);
    -- MAJ du lot pseudo
    FAL_BATCH_FUNCTIONS.UpdateBatchQtyForReceipt(aFAL_LOT_ID, -1);
    -- MAJ de l'ordre selon le lot en cours
    FAL_ORDER_FUNCTIONS.UpdateOrder(0, aFAL_LOT_ID);
    -- MAJ des entr�es atelier avec la quantit� sortie de composants
    FAL_COMPONENT_FUNCTIONS.UpdateFactoryEntries(aLOM_SESSION);
        -- Cr�ation des sorties atelier de type retour (Composant remplac�)
        FAL_COMPONENT_FUNCTIONS.CreateAllFactoryMovements(aFAL_LOT_ID              => aFAL_LOT_ID
                                                        , aFCL_SESSION             => aLOM_SESSION
                                                        , aPreparedStockMovement   => FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements
                                                        , aOUT_DATE                => aReplacementDate
                                                        , aMovementKind            => FAL_STOCK_MOVEMENT_FUNCTIONS.mktRetourAtelierVersStock
                                                        , aC_OUT_ORIGINE           => '5'
                                                         );
        -- Cr�ation des sorties atelier de type D�chet (Composant remplac�)
        FAL_COMPONENT_FUNCTIONS.CreateAllFactoryMovements(aFAL_LOT_ID              => aFAL_LOT_ID
                                                        , aFCL_SESSION             => aLOM_SESSION
                                                        , aPreparedStockMovement   => FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements
                                                        , aOUT_DATE                => aReplacementDate
                                                        , aMovementKind            => FAL_STOCK_MOVEMENT_FUNCTIONS.mktRetourAtelierVersDechet
                                                        , aC_OUT_ORIGINE           => '5'
                                                         );
    -- Cr�ations des entr�es en atelier pour le lot (Composant de remplacement)
    FAL_COMPONENT_FUNCTIONS.CreateAllFactoryMovements(aFAL_LOT_ID              => aFAL_LOT_ID
                                                    , aFCL_SESSION             => aLOM_SESSION
                                                    , aPreparedStockMovement   => FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements
                                                    , aOUT_DATE                => aReplacementDate
                                                    , aMovementKind            => FAL_STOCK_MOVEMENT_FUNCTIONS.mktSortieStockVersAtelier
                                                    , aC_IN_ORIGINE            => '3'   -- origine remplacement
                                                     );
    -- G�n�ration des mouvements de stock
    FAL_STOCK_MOVEMENT_FUNCTIONS.ApplyPreparedStockMovements(FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements
                                                           , aErrorCode
                                                           , aErrorMsg
                                                           , FAL_STOCK_MOVEMENT_FUNCTIONS.ctxDefault
                                                           , aiShutdownExceptions
                                                            );
    -- Mise � jour des r�seaux
    FAL_NETWORK.MiseAJourReseaux(aFAL_LOT_ID, FAL_NETWORK.ncRemplacementComposant, '');
    -- Mise � jour des Entr�es Atelier avec les positions de stock cr��es dans le stock Atelier par les mouvements de stock
    FAL_STOCK_MOVEMENT_FUNCTIONS.UpdFactEntriesWthAppliedStkMvt(FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements);
    -- D�r�servation du lot de fabrication
    FAL_BATCH_RESERVATION.ReleaseReservedbatches(aLOM_SESSION);
    -- Purge des tables de travail
    FAL_LOT_MAT_LINK_TMP_FCT.PurgeAllTemporaryTable(aLOM_SESSION);
  end;

  /**
  * procedure : GetHoldedQty
  * Description : R�cup�ration des qt�s total "� remplacer" et "de remplacement".
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param      aLOM_SESSION : Session oracle
  * @param      aFAL_LOT_MAT_LINK_TMP_ID : Composants temporaire
  * @return     aQtyToreplace : Qt� � remplacer
  * @return     aQtyForReplace : Qt� de remplacement
  */
  procedure GetHoldedQty(aLOM_SESSION in varchar2, aFAL_LOT_MATERIAL_LINK_ID in number, aQtyToreplace in out number, aQtyForReplace in out number)
  is
  begin
    select nvl(QTYTOREPLACE.QTY, 0)
         , nvl(QTYFORREPLACE.QTY, 0)
      into aQtyToreplace
         , aQtyForReplace
      from (select sum(nvl(FCL1.FCL_RETURN_QTY, 0) + nvl(FCL1.FCL_TRASH_QTY, 0)) QTY
              from FAL_COMPONENT_LINK FCL1
                 , FAL_LOT_MAT_LINK_TMP LOM1
             where FCL1.FCL_SESSION = aLOM_SESSION
               and FCL1.FAL_FACTORY_IN_ID is not null
               and FCL1.FAL_LOT_MAT_LINK_TMP_ID = LOM1.FAL_LOT_MAT_LINK_TMP_ID
               and LOM1.FAL_LOT_MATERIAL_LINK_ID = aFAL_LOT_MATERIAL_LINK_ID) QTYTOREPLACE
         , (select sum(nvl(FCL2.FCL_HOLD_QTY, 0) ) QTY
              from FAL_COMPONENT_LINK FCL2
                 , FAL_LOT_MAT_LINK_TMP LOM2
             where FCL2.FCL_SESSION = aLOM_SESSION
               and FCL2.FAL_FACTORY_IN_ID is null
               and FCL2.FAL_LOT_MAT_LINK_TMP_ID = LOM2.FAL_LOT_MAT_LINK_TMP_ID
               and LOM2.FAL_LOT_MATERIAL_LINK_ID = aFAL_LOT_MATERIAL_LINK_ID) QTYFORREPLACE;
  exception
    when no_data_found then
      begin
        aQtyToreplace   := 0;
        aQtyForReplace  := 0;
      end;
  end;
end;
