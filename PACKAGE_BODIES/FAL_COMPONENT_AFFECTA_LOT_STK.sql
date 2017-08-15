--------------------------------------------------------
--  DDL for Package Body FAL_COMPONENT_AFFECTA_LOT_STK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_COMPONENT_AFFECTA_LOT_STK" 
is
  /**
  * procedure : ComponentGenForAllocation
  * Description : Génération des composants temporaires ainsi que des
  *               liens de réservation pour l'affectation de composants.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param      aGCO_GOOD_ID : Composant
  * @param      aFCL_SESSION_ID : Session oracle
  * @param      aFAL_JOB_PROGRAM_ID : Programme de fabrication
  * @param      aC_PRIORITY : Priorité des lots de fabrication
  * @param      aPriorityDate : Date de priorité
  */
  procedure ComponentGenForAllocation(
    aGCO_GOOD_ID           number
  , aFCL_SESSION_ID        varchar2
  , aFAL_JOB_PROGRAM_ID    number default null
  , aC_PRIORITY            varchar2 default null
  , aPriorityDate          date default null
  , aReturnLocationID   in number default null
  )
  is
  begin
    -- Génération des composants temporaires
    FAL_LOT_MAT_LINK_TMP_FUNCTIONS.CreateComponents(aSessionId          => aFCL_SESSION_ID
                                                  , aContext            => FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchToStockAllocation
                                                  , aGcoGoodId          => aGCO_GOOD_ID
                                                  , aFalJobProgramId    => aFAL_JOB_PROGRAM_ID
                                                  , aCPriority          => aC_PRIORITY
                                                  , aPriorityDate       => aPriorityDate
                                                  , iStmStmStockId      => STM_I_LIB_STOCK.GetStockId(aReturnLocationId)
                                                  , iStmStmLocationId   => aReturnLocationID
                                                   );
  end ComponentGenForAllocation;

  /**
  * procedure : DoComponentAllocation
  * Description : Validation de l'affectation des composants de lots vers stock
  *
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aFCL_SESSION_ID : Session oracle
  * @param   aAllocationDate : DateAffectation
  * @return  aErrorCode : Retour code erreur
  * @return  aErrorMsg : Message d'erreur
  * @param   aReturnLocationID : ID de l'emplacement pour le reotur des composants.
  * @param   aiShutDownExceptions : indique si l'on fait le raise depuis le PL
  */
  procedure DoComponentAllocation(
    aFCL_SESSION_ID      in     varchar2
  , aAllocationDate      in     date
  , aErrorCode           in out varchar2
  , aErrorMsg            in out varchar2
  , aReturnLocationID    in     number default null
  , aiShutDownExceptions        integer default 0
  )
  is
    lSupplierId            STM_STOCK.PAC_SUPPLIER_PARTNER_ID%type;

    cursor CUR_COMPONENT_TO_ALLOCATE
    is
      select distinct LOM.FAL_LOT_MATERIAL_LINK_ID
                    , LOM.FAL_LOT_ID
                 from FAL_LOT_MAT_LINK_TMP LOM
                    , FAL_COMPONENT_LINK FCL
                    , FAL_TASK_LINK TAL
                where LOM.LOM_SESSION = aFCL_SESSION_ID
                  and LOM.FAL_LOT_MAT_LINK_TMP_ID = FCL.FAL_LOT_MAT_LINK_TMP_ID
                  and LOM.LOM_TASK_SEQ = TAL.SCS_STEP_NUMBER(+)
                  and LOM.FAL_LOT_ID = TAL.FAL_LOT_ID(+)
                  and (   lSupplierId is null
                       or lSupplierId = TAL.PAC_SUPPLIER_PARTNER_ID)
             order by LOM.FAL_LOT_ID
                    , LOM.FAL_LOT_MATERIAL_LINK_ID;

    CurComponentToAllocate CUR_COMPONENT_TO_ALLOCATE%rowtype;
  begin
    lSupplierId  := STM_I_LIB_STOCK.getSubCPartnerID(STM_I_LIB_STOCK.GetStockId(iLocationId => aReturnLocationID) );
    -- Préparation de la liste des mouvements de stock
    FAL_STOCK_MOVEMENT_FUNCTIONS.InitPreparedStockMovement;
    -- MAJ des entrées atelier avec la quantité retournée.
    FAL_COMPONENT_FUNCTIONS.UpdateFactoryEntries(aFCL_SESSION_ID);
    -- Modification ou suppression des appairages dépendant des entrées atelier démontées
    FAL_LOT_DETAIL_FUNCTIONS.UpdateAlignementOnMvtComponent(aFCL_SESSION_ID);

    -- Parcours des composants à affecter
    for CurComponentToAllocate in CUR_COMPONENT_TO_ALLOCATE loop
      -- Mise à jour du composant du lot de fabrication
      FAL_COMPONENT_FUNCTIONS.UpdateFalLotMatLinkafterOutput(aFCL_SESSION_ID
                                                           , CurComponentToAllocate.FAL_LOT_ID
                                                           , CurComponentToAllocate.FAL_LOT_MATERIAL_LINK_ID
                                                           , FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchToStockAllocation
                                                            );
      -- Mise à jour du lot de fabrication (qté max réceptionnable)
      FAL_BATCH_FUNCTIONS.UpdateBatchQtyForReceipt(CurComponentToAllocate.FAL_LOT_ID, -1);
      -- Mise à jour de l'ordre de fabrication
      FAL_ORDER_FUNCTIONS.UpdateOrder(0, CurComponentToAllocate.FAL_LOT_ID);
      -- Création des sortie de stocks conso vers le stock atelier
      FAL_COMPONENT_FUNCTIONS.CreateAllFactoryMovements(aFAL_LOT_ID                 => CurComponentToAllocate.FAL_LOT_ID
                                                      , aFCL_SESSION                => aFCL_SESSION_ID
                                                      , aPreparedStockMovement      => FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements
                                                      , aOUT_DATE                   => aAllocationDate
                                                      , aMovementKind               => FAL_STOCK_MOVEMENT_FUNCTIONS.mktRetourAtelierVersStock
                                                      , aC_OUT_ORIGINE              => '6'
                                                      , aFAL_LOT_MATERIAL_LINK_ID   => CurComponentToAllocate.FAL_LOT_MATERIAL_LINK_ID
                                                       );
      -- Mise à jour des réseaux
      FAL_NETWORK.MiseAJourReseaux(CurComponentToAllocate.FAL_LOT_ID, FAL_NETWORK.ncAffectationComposantLotStock, '');
    end loop;

    -- Génération des mouvements de stock
    FAL_STOCK_MOVEMENT_FUNCTIONS.ApplyPreparedStockMovements(FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements
                                                           , aErrorCode
                                                           , aErrorMsg
                                                           , FAL_STOCK_MOVEMENT_FUNCTIONS.ctxDefault
                                                           , aiShutDownExceptions
                                                            );
    -- Mise à jour des entrées atelier avec les positions de stock créées dans le stock Atelier par les mouvements de stock
    FAL_STOCK_MOVEMENT_FUNCTIONS.UpdFactEntriesWthAppliedStkMvt(FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements);
  exception
    when others then
      raise;
  end DoComponentAllocation;

  /**
  * procedure : GetAffectedQty
  * Description : Récupération de la somme des qtés affectées
  *
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aFCL_SESSION_ID : Session oracle
  * @param   aSTM_LOCATION_ID
  */
  procedure GetAffectedQty(aFCL_SESSION_ID in varchar2, aSTM_LOCATION_ID in number default null, aAffectedQty in out number)
  is
  begin
    select sum(nvl(FCL_RETURN_QTY, 0) )
      into aAffectedQty
      from FAL_COMPONENT_LINK
     where FCL_SESSION = aFCL_SESSION_ID
       and (   nvl(aSTM_LOCATION_ID, 0) = 0
            or STM_LOCATION_ID = aSTM_LOCATION_ID);
  exception
    when others then
      aAffectedQty  := 0;
  end;
end;
