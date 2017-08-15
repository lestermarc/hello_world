--------------------------------------------------------
--  DDL for Package Body FAL_COMPONENT_LINK_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_COMPONENT_LINK_FUNCTIONS" 
is
  cInitLotRefCompl         constant boolean      := PCS.PC_CONFIG.GetBooleanConfig('FAL_INIT_LOTREFCOMPL');
  cInitLotRefCompl2        constant varchar2(50) := PCS.PC_CONFIG.GetConfig('FAL_INIT_LOTREFCOMPL2');
  cUseLocationSelectLaunch constant boolean      := PCS.PC_CONFIG.GetBooleanConfig('FAL_USE_LOCATION_SELECT_LAUNCH');
  cLocationSelectLaunch    constant integer      := to_number(PCS.PC_CONFIG.GetConfig('FAL_LOCATION_SELECT_LAUNCH') );
  cPairingCaract           constant varchar2(10) := PCS.PC_CONFIG.GetConfig('FAL_PAIRING_CHARACT') || ',3';
  cAutoInitCharCpt         constant varchar2(10) := PCS.PC_CONFIG.GetConfig('FAL_AUTO_INIT_CHARAC_COMP');
  cWorkshopStockId         constant number       := FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_FLOOR');
  cWorkshopLocationId      constant number   := FAL_TOOLS.GetConfig_LocationID('PPS_DefltLOCATION_FLOOR', FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_FLOOR') );

  /**
  * proc�dure SumOfComponentAttributions
  * Description : Somme des quantit�s attribu�es pour le composant
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aFAL_LOT_MATERIAL_LINK_ID      Composant
  * @param   aSTM_STOCK_ID                  Stock
  */
  function SumOfComponentAttributions(
    aFAL_LOT_MATERIAL_LINK_ID in FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type
  , aSTM_STOCK_ID             in STM_STOCK.STM_STOCK_ID%type default null
  , aSTM_LOCATION_ID          in STM_LOCATION.STM_LOCATION_ID%type default null
  )
    return FAL_NETWORK_LINK.FLN_QTY%type
  is
  begin
    /* Pas besoin de transaction autonome pour cette fonction mais il faut la conserver dans ce packages en raison des diff�rents appels */
    return FAL_COMPONENT_LINK_FCT.SumOfComponentAttributions(aFAL_LOT_MATERIAL_LINK_ID, aSTM_STOCK_ID, aSTM_LOCATION_ID);
  end;

  /**
  * proc�dure CreateCompoLinkFalFactoryIn
  * Description : Cr�e un lien entre un composant de lot et une entr�e atelier destin� au retour de composants.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSessionId             ID unique de Session Oracle
  * @param   aFalLotMatLinkTmpId    ID du composant temporaire de lot
  * @param   aFalfactoryInId        ID de l'entr�e atelier
  * @param   aTrashQty              Qt� d�chet
  * @param   aReturnQty             Qt� retour
  * @param   aHoldQty               Qt� Saisie
  */
  procedure CreateCompoLinkFalFactoryIn(
    aSessionId          in FAL_COMPONENT_LINK.FCL_SESSION%type
  , aFalLotMatLinkTmpId in FAL_LOT_MAT_LINK_TMP.FAL_LOT_MAT_LINK_TMP_ID%type
  , aFalFactoryInId     in FAL_FACTORY_IN.FAL_FACTORY_IN_ID%type
  , aTrashQty           in number default 0
  , aReturnQty          in number default 0
  , aHoldQty            in number default 0
  , iLocationId         in number default null
  )
  is
    pragma autonomous_transaction;
  begin
    FAL_COMPONENT_LINK_FCT.CreateCompoLinkFalFactoryIn(aSessionId            => aSessionId
                                                     , aFalLotMatLinkTmpId   => aFalLotMatLinkTmpId
                                                     , aFalFactoryInId       => aFalFactoryInId
                                                     , aTrashQty             => aTrashQty
                                                     , aReturnQty            => aReturnQty
                                                     , aHoldQty              => aHoldQty
                                                     , iLocationId           => iLocationId
                                                      );
    commit;
  end CreateCompoLinkFalFactoryIn;

  /**
  * proc�dure CreateCompoLinkStockAvalaible
  * Description
  *   Cr�e une r�servation entre un composant de lot et une position de stock
  *   (la r�servation sur le stock se fait par trigger sur la table FAL_COMPONENT_LINK)
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aSessionId             ID unique de Session Oracle
  * @param   aFalLotMatLinkTmpId    ID du composant temporaire de lot
  * @param   aStmStockPositionId    ID de la position de stock
  * @param   aHoldQty                   Quantit� � r�serv�
  */
  procedure CreateCompoLinkStockAvalaible(
    aSessionId          in FAL_COMPONENT_LINK.FCL_SESSION%type
  , aFalLotMatLinkTmpId in FAL_LOT_MAT_LINK_TMP.FAL_LOT_MAT_LINK_TMP_ID%type
  , aStmStockPositionId in STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type
  , aHoldQty            in FAL_COMPONENT_LINK.FCL_HOLD_QTY%type default 0
  , aTrashQty           in FAL_COMPONENT_LINK.FCL_TRASH_QTY%type default 0
  , aReturnQty          in FAL_COMPONENT_LINK.FCL_RETURN_QTY%type default 0
  , aContext            in number default FAL_LIB_CONSTANT.ctxNull
  )
  is
    pragma autonomous_transaction;
  begin
    FAL_COMPONENT_LINK_FCT.CreateCompoLinkStockAvalaible(aSessionId            => aSessionId
                                                       , aFalLotMatLinkTmpId   => aFalLotMatLinkTmpId
                                                       , aStmStockPositionId   => aStmStockPositionId
                                                       , aHoldQty              => aHoldQty
                                                       , aTrashQty             => aTrashQty
                                                       , aReturnQty            => aReturnQty
                                                       , aContext              => aContext
                                                        );
    commit;
  end;

  /**
  * proc�dure CreateCompoLinkForDerived
  * Description
  *   Cr�e une r�servation entre un composant de lot type "d�riv�" et un emplacement de stock
  * @created CLE
  * @lastUpdate
  * @public
  * @param   iFalLotMatLinkTmpId        Id du composant temporaire de lot
  * @param   iQty                       Quantit� du lien composant
  * @param   iStmStockId                Id du stock
  * @param   aStmLocationId             Id de l'emplacement de stock
  * @param   iCharacVal1 � iCharacVal1  Valeurs de caract�risation du composant
  */
  procedure CreateCompoLinkForDerived(
    iFalLotMatLinkTmpId in     number
  , iGcoGoodId          in     number
  , iFalComponentLinkId in     number default null
  , iQty                in     number
  , iStmStockId         in     number
  , iStmLocationId      in     number
  , iCharacVal1         in     FAL_COMPONENT_LINK.FCL_CHARACTERIZATION_VALUE_1%type
  , iCharacVal2         in     FAL_COMPONENT_LINK.FCL_CHARACTERIZATION_VALUE_1%type
  , iCharacVal3         in     FAL_COMPONENT_LINK.FCL_CHARACTERIZATION_VALUE_1%type
  , iCharacVal4         in     FAL_COMPONENT_LINK.FCL_CHARACTERIZATION_VALUE_1%type
  , iCharacVal5         in     FAL_COMPONENT_LINK.FCL_CHARACTERIZATION_VALUE_1%type
  , iCheckValues        in     integer
  , ioResultMessage     in out varchar2
  )
  is
    pragma autonomous_transaction;
  begin
    FAL_COMPONENT_LINK_FCT.CreateCompoLinkForDerived(iFalLotMatLinkTmpId   => iFalLotMatLinkTmpId
                                                   , iGcoGoodId            => iGcoGoodId
                                                   , iFalComponentLinkId   => iFalComponentLinkId
                                                   , iQty                  => iQty
                                                   , iStmStockId           => iStmStockId
                                                   , iStmLocationId        => iStmLocationId
                                                   , iCharacVal1           => iCharacVal1
                                                   , iCharacVal2           => iCharacVal2
                                                   , iCharacVal3           => iCharacVal3
                                                   , iCharacVal4           => iCharacVal4
                                                   , iCharacVal5           => iCharacVal5
                                                   , iCheckValues          => iCheckValues
                                                   , ioResultMessage       => ioResultMessage
                                                    );
    commit;
  end;

  /**
  * proc�dure CreateCompoLinkFromAttribution
  * Description
  *   Report (depuis les attributions) des r�servations de stock entre un composant de lot
  *   et les positions de stock dans la table de "dispo composant" (FAL_COMPONENT_LINK)
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aSessionId             ID unique de Session Oracle
  * @param   aFalLotMaterialLinkId  ID du composant de lot
  * @param   aFalLotMatLinkTmpID    ID Du composant temporaire
  * @param   aHoldedQty             Quantit� r�ellement saisie
  * @param   aC_CHRONOLOGY_TYPE     Type de chronologie
  * @param   aIS_FULL_TRACABILITY   produit en tracabilit� compl�te
  * @param   aSTM_LOCATION_ID       Emplacement (pour une saisie manuelle)
  * @param   aHoldQty             Quantit� � saisir
  * @param   aForceWithStmLocation  Forcer l'emplaceent de saisie
  */
  procedure CreateCompoLinkFromAttribution(
    aSessionId            in     FAL_COMPONENT_LINK.FCL_SESSION%type
  , aFalLotMaterialLinkId in     FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type default null
  , aFalLotMatLinkTmpID   in     FAL_LOT_MAT_LINK_TMP.FAL_LOT_MAT_LINK_TMP_ID%type default null
  , aHoldedQty            in out number
  , aC_CHRONOLOGY_TYPE    in     varchar2
  , aIS_FULL_TRACABILITY  in     integer
  , aSTM_LOCATION_ID      in     number
  , aHoldQty              in     FAL_COMPONENT_LINK.FCL_HOLD_QTY%type
  , aTrashQty             in     FAL_COMPONENT_LINK.FCL_TRASH_QTY%type
  , aReturnQty            in     FAL_COMPONENT_LINK.FCL_RETURN_QTY%type
  , aForceWithStmLocation in     integer
  , aContext              in     number
  )
  is
    pragma autonomous_transaction;
  begin
    FAL_COMPONENT_LINK_FCT.CreateCompoLinkFromAttribution(aSessionId              => aSessionId
                                                        , aFalLotMaterialLinkId   => aFalLotMaterialLinkId
                                                        , aFalLotMatLinkTmpID     => aFalLotMatLinkTmpID
                                                        , aHoldedQty              => aHoldedQty
                                                        , aC_CHRONOLOGY_TYPE      => aC_CHRONOLOGY_TYPE
                                                        , aIS_FULL_TRACABILITY    => aIS_FULL_TRACABILITY
                                                        , aSTM_LOCATION_ID        => aSTM_LOCATION_ID
                                                        , aHoldQty                => aHoldQty
                                                        , aTrashQty               => aTrashQty
                                                        , aReturnQty              => aReturnQty
                                                        , aForceWithStmLocation   => aForceWithStmLocation
                                                        , aContext                => aContext
                                                         );
    commit;
  end;

  /**
  * proc�dure CompoLinkModifyQuantity
  * Description
  *   Modifie une r�servation entre un composant de lot et une position de stock
  *     - Si la quantit� est � 0, supprime le lien de r�servation
  *     - Si le lien de r�servation n'existe pas, cr�ation de l'enregistrement
  *       (dans la table FAL_COMPONENT_LINK)
  *   (la r�servation sur le stock se fait par trigger sur la table FAL_COMPONENT_LINK)
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aSessionId             ID unique de Session Oracle
  * @param   aFalComponentLinkId    ID du lien de r�servation (table FAL_COMPONENT_LINK)
  * @param   aContext               Context
  * @param   aFalLotMatLinkTmpId    ID du composant de lot temporaire
  * @param   aStmStockPositionId    ID de la position de stock
  * @param   aFalFactoryInId        Entr�e atelier
  * @param   aHoldQty               Quantit� saisie
  * @param   aTrashQty              Quantit� d�chet (retour de composant)
  * @param   aReturnQty             Quantit� retour (retour de composant)
  */
  procedure CompoLinkModifyQuantity(
    aSessionId          in FAL_COMPONENT_LINK.FCL_SESSION%type
  , aFalComponentLinkId in FAL_COMPONENT_LINK.FAL_COMPONENT_LINK_ID%type default null
  , aContext            in integer
  , aFalLotMatLinkTmpId in FAL_LOT_MAT_LINK_TMP.FAL_LOT_MAT_LINK_TMP_ID%type default null
  , aStmStockPositionId in STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type default null
  , aFalFactoryInId     in FAL_FACTORY_IN.FAL_FACTORY_IN_ID%type default null
  , aHoldQty            in FAL_COMPONENT_LINK.FCL_HOLD_QTY%type default 0
  , aTrashQty           in FAL_COMPONENT_LINK.FCL_TRASH_QTY%type default 0
  , aReturnQty          in FAL_COMPONENT_LINK.FCL_RETURN_QTY%type default 0
  , iLocationId         in number default null
  , iTrashLocationId    in number default null
  )
  is
    pragma autonomous_transaction;
  begin
    FAL_COMPONENT_LINK_FCT.CompoLinkModifyQuantity(aSessionId            => aSessionId
                                                 , aFalComponentLinkId   => aFalComponentLinkId
                                                 , aContext              => aContext
                                                 , aFalLotMatLinkTmpId   => aFalLotMatLinkTmpId
                                                 , aStmStockPositionId   => aStmStockPositionId
                                                 , aFalFactoryInId       => aFalFactoryInId
                                                 , aHoldQty              => aHoldQty
                                                 , aTrashQty             => aTrashQty
                                                 , aReturnQty            => aReturnQty
                                                 , iLocationId           => iLocationId
                                                 , iTrashLocationId      => iTrashLocationId
                                                  );
    commit;
  end;

  /**
  * proc�dure PurgeComponentLinkTable
  * Description
  *   Suppression des enregistrements de la table FAL_COMPONENT_LINK dont la
  *   session Oracle n'est plus valide
  *   (La suppression remet � jour par trigger les r�servation de stock provisoires)
  * @created CLE
  * @lastUpdate
  * @public
  */
  procedure PurgeComponentLinkTable
  is
    pragma autonomous_transaction;
  begin
    FAL_COMPONENT_LINK_FCT.PurgeComponentLinkTable;
    commit;
  end;

  /**
  * proc�dure PurgeComponentLinkTable
  * Description
  *   Suppression des enregistrements de la table FAL_COMPONENT_LINK pour une
  *   session Oracle donn�e en param�tre
  *   (La suppression remet � jour par trigger les r�servation de stock provisoires)
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aSessionId             ID unique de Session Oracle
  */
  procedure PurgeComponentLinkTable(aSessionId FAL_COMPONENT_LINK.FCL_SESSION%type)
  is
    pragma autonomous_transaction;
  begin
    FAL_COMPONENT_LINK_FCT.PurgeComponentLinkTable(aSessionId);
    commit;
  end;

  /**
  * proc�dure PurgeComponentLink
  * Description
  *   Suppression des enregistrements de la table FAL_COMPONENT_LINK pour un lot donn�
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aFalLotId     Id du lot
  */
  procedure PurgeComponentLink(aFalLotId FAL_LOT.FAL_LOT_ID%type)
  is
    pragma autonomous_transaction;
  begin
    FAL_COMPONENT_LINK_FCT.PurgeComponentLink(aFalLotId);
    commit;
  end;

  /**
  * proc�dure PurgeComponentLink
  * Description
  *   Suppression des enregistrements de la table FAL_COMPONENT_LINK pour un composant donn�.
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aFalLotMatLinkTmpId     Composant temporaire.
  */
  procedure PurgeComponentLink(aFalLotMatLinkTmpId number, aSessionId varchar2)
  is
    pragma autonomous_transaction;
  begin
    FAL_COMPONENT_LINK_FCT.PurgeComponentLink(aFalLotMatLinkTmpId, aSessionId);
    commit;
  end;

  /**
  * procedure : DeleteComponentLinkReleaseCode5
  * Description : Suppression des r�servations pour les composants de type
  *      code d�charge = 5 (dispo au lancement) ou 6 (mvts de stock pour la sous-traitance). On en tient compte pour la
  *      simulation mais on ne sort pas les composants au lancement.
  *
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aSessionId    Session Oracle
  * @param   aFalLotId     Lot � mettre � jour (tous les lots1 s�lectionn�s si ce param�tre est null)
  */
  procedure DeleteCompoLinkReleaseCode5(aSessionId varchar2, aFalLotId FAL_LOT.FAL_LOT_ID%type default null)
  is
    pragma autonomous_transaction;
  begin
    FAL_COMPONENT_LINK_FCT.DeleteCompoLinkReleaseCode5(aSessionId, aFalLotId);
    commit;
  end;

  /**
  * procedure : DeleteComponentLinkReleaseCode234
  * Description : Suppression des r�servations pour les composants de type
  *      code d�charge = 2,3,4 . On en tient compte pour la
  *      simulation afin d'afficher l'info de disponibilit� � l'utilisateur
  *      mais on ne sort pas les composants au lancement.
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSessionId    Session Oracle
  * @param   aFalLotId     Lot � mettre � jour (tous les lots1 s�lectionn�s si ce param�tre est null)
  */
  procedure DeleteCompoLinkReleaseCode234(aSessionId varchar2, aFalLotId FAL_LOT.FAL_LOT_ID%type default null)
  is
    pragma autonomous_transaction;
  begin
    FAL_COMPONENT_LINK_FCT.DeleteCompoLinkReleaseCode234(aSessionId, aFalLotId);
    commit;
  end;

  /**
  * proc�dure DeleteComponentLink
  * Description Suppression d'un lien composant temporaire
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aFalComponentLinkId    ID du lien de r�servation (table FAL_COMPONENT_LINK)
  */
  procedure DeleteComponentLink(aFalComponentLinkId in FAL_COMPONENT_LINK.FAL_COMPONENT_LINK_ID%type)
  is
    pragma autonomous_transaction;
  begin
    FAL_COMPONENT_LINK_FCT.DeleteComponentLink(aFalComponentLinkId);
    commit;
  end;
end FAL_COMPONENT_LINK_FUNCTIONS;
