--------------------------------------------------------
--  DDL for Package Body FAL_COMPONENT_MVT_SORTIE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_COMPONENT_MVT_SORTIE" 
is
  /**
  * Description :
  *   Exécution des mouvements de sortie préparés.
  */
  procedure ApplyOutputMovements(
    aFAL_LOT_ID          in     number default null
  , aDOC_DOCUMENT_ID     in     number default null
  , aDOC_POSITION_ID            number default null
  , aLOM_SESSION         in     varchar2
  , aOutPutDate          in     date
  , aErrorCode           in out varchar2
  , aErrorMsg            in out varchar2
  , aiShutDownExceptions        integer default 0
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
      FAL_COMPONENT_FUNCTIONS.UpdateFalLotMatLinkafterOutput(aLOM_SESSION, ltplLot.FAL_LOT_ID, null, FAL_COMPONENT_LINK_FUNCTIONS.ctxtComponentOutput);
      -- Mise à jour du lot de fabrication (qté max réceptionnable)
      FAL_BATCH_FUNCTIONS.UpdateBatchQtyForReceipt(ltplLot.FAL_LOT_ID, -1);
      -- Mise à jour de l'ordre de fabrication
      FAL_ORDER_FUNCTIONS.UpdateOrder(0, ltplLot.FAL_LOT_ID);
      -- Créations des entrées atelier pour le lot
      FAL_COMPONENT_FUNCTIONS.CreateAllFactoryMovements(aFAL_LOT_ID              => ltplLot.FAL_LOT_ID
                                                      , aDOC_DOCUMENT_ID         => aDOC_DOCUMENT_ID
                                                      , aFCL_SESSION             => aLOM_SESSION
                                                      , aPreparedStockMovement   => FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements
                                                      , aOUT_DATE                => aOutputDate
                                                      , aMovementKind            => FAL_STOCK_MOVEMENT_FUNCTIONS.mktSortieStockVersAtelier
                                                      , aC_IN_ORIGINE            => '2'
                                                       );
      -- Génération des mouvements de stock
      FAL_STOCK_MOVEMENT_FUNCTIONS.ApplyPreparedStockMovements(FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements
                                                             , aErrorCode
                                                             , aErrorMsg
                                                             , FAL_STOCK_MOVEMENT_FUNCTIONS.ctxDefault
                                                             , aiShutDownExceptions
                                                              );
      -- Mise à jour des réseaux
      FAL_NETWORK.MiseAJourReseaux(ltplLot.FAL_LOT_ID, FAL_NETWORK.ncSortieComposant, '');
      -- Mise à jour des Entrées Atelier avec les positions de stock créées dans le stock Atelier par les mouvements de stock
      FAL_STOCK_MOVEMENT_FUNCTIONS.UpdFactEntriesWthAppliedStkMvt(FAL_STOCK_MOVEMENT_FUNCTIONS.LocPreparedStockMovements);
      -- Purge des tables de travail
      FAL_LOT_MAT_LINK_TMP_FCT.PurgeAllTemporaryTable(aLOM_SESSION);
    end loop;
  end;

  /**
  * Description : Génération des composants temporaires ainsi que des
  *               liens de réservation pour la sortie de composants.
  */
  procedure ComponentAndLinkGenForOutput(
    aFAL_LOT_ID                number default null
  , aDOC_DOCUMENT_ID           number default null
  , aDOC_POSITION_ID           number default null
  , aFCL_SESSION_ID            varchar2
  , aOpSeqFrom                 number default 0
  , aOpSeqTo                   number default 0
  , aComponentWithNeed         integer
  , aBalanceNeed               integer
  , aContext                   number default 0
  , aComponentSeqFrom          number default null
  , aComponentSeqTo            number default null
  , aCaseReleaseCode           integer default 0
  , aDoBatchReservation        integer default 0
  , aDoDeleteWorkTable         integer default 0
  , aUseRemainNeedQty          integer default 0
  , aDisplayAllComponentsDispo integer default 0
  , aUseOnlyReservedQtySTT     integer default 0
  )
  is
    EnrCFAL_LOT_MATERIAL_LINK FAL_LOT_MATERIAL_LINK%rowtype;
    IsCP4_STOCK_MANAGEMENT    number;
    aStepNumber               number;
    aStepNumberNextOpe        number;
    aBalanceQuantity          FAL_TASK_LINK.TAL_DUE_QTY%type;
    aBatchReservationError    varchar2(255);
  begin
    -- Réservation du lot de fabrication
    if aDoBatchReservation = 1 then
      FAL_BATCH_RESERVATION.PurgeInactiveBatchReservation;
      FAL_BATCH_RESERVATION.ReleaseReservedbatches(aFCL_SESSION_ID);

      if nvl(aFAL_LOT_ID, 0) = 0 then
        FAL_BATCH_RESERVATION.BatchReservation(aFAL_LOT_ID, aFCL_SESSION_ID, aBatchReservationError);
      elsif nvl(aDOC_DOCUMENT_ID, 0) = 0 then
        FAL_BATCH_RESERVATION.BatchReservationSubcO(aDOC_DOCUMENT_ID      => aDOC_DOCUMENT_ID
                                                  , aLT1_ORACLE_SESSION   => aFCL_SESSION_ID
                                                  , aErrorMsg             => aBatchReservationError
                                                   );
      elsif nvl(aDOC_POSITION_ID, 0) = 0 then
        FAL_BATCH_RESERVATION.BatchReservationSubcO(aDOC_POSITION_ID      => aDOC_POSITION_ID
                                                  , aLT1_ORACLE_SESSION   => aFCL_SESSION_ID
                                                  , aErrorMsg             => aBatchReservationError
                                                   );
      end if;

      if trim(aBatchReservationError) <> '' then
        raise_application_error(-20010, aBatchReservationError);
      end if;
    end if;

    -- Purge des tables de travail
    if aDoDeleteWorkTable = 1 then
      FAL_LOT_MAT_LINK_TMP_FUNCTIONS.PurgeAllTemporaryTable(aFCL_SESSION_ID);
    end if;

    -- Récupération séquence et qté solde opération
    begin
      select SCS_STEP_NUMBER
           , TAL_DUE_QTY
        into aStepNumber
           , aBalanceQuantity
        from FAL_TASK_LINK
       where FAL_LOT_ID = aFAL_LOT_ID
         and SCS_STEP_NUMBER = aOpSeqFrom;
    exception
      when no_data_found then
        begin
          aStepNumber       := null;
          aBalanceQuantity  := null;
        end;
    end;

    -- Récupération Séquence Opération principale suivante
    aStepNumberNextOpe  := FAL_LIB_TASK_LINK.getNextMainTaskSeq(iLotID => aFAL_LOT_ID, iCurrentTaskSeq => aOpSeqFrom);
    -- Génération des composants temporaires
    FAL_LOT_MAT_LINK_TMP_FUNCTIONS.CreateComponents(aFalLotId                    => aFAL_LOT_ID
                                                  , aDocumentId                  => aDOC_DOCUMENT_ID
                                                  , aPositionId                  => aDOC_POSITION_ID
                                                  , aSessionId                   => aFCL_SESSION_ID
                                                  , aContext                     => aContext
                                                  , aOpSeqFrom                   => aOpSeqFrom
                                                  , aOpSeqTo                     => aOpSeqTo
                                                  , aComponentWithNeed           => aComponentWithNeed
                                                  , aBalanceNeed                 => aBalanceNeed
                                                  , aComponentSeqFrom            => aComponentSeqFrom
                                                  , aComponentSeqTo              => aComponentSeqTo
                                                  , aStepNumber                  => aStepNumber
                                                  , aStepNumberNextOp            => aStepNumberNextOpe
                                                  , aBalanceQty                  => aBalanceQuantity
                                                  , aCaseReleaseCode             => aCaseReleaseCode
                                                  , aDisplayAllComponentsDispo   => aDisplayAllComponentsDispo
                                                   );
    -- Génération des liens de réservation pour tous les composants (Param aFAL_LOT_MAT_LINK_TMP_ID = null)
    FAL_COMPONENT_LINK_FCT.GlobalComponentLinkGeneration(aFAL_LOT_MAT_LINK_TMP_ID   => null
                                                       , aFAL_LOT_ID                => aFAL_LOT_ID
                                                       , aDOC_DOCUMENT_ID           => aDOC_DOCUMENT_ID
                                                       , aDOC_POSITION_ID           => aDOC_POSITION_ID
                                                       , aLOM_SESSION               => aFCL_SESSION_ID
                                                       , aContext                   => aContext
                                                       , aBalanceNeed               => aBalanceNeed
                                                       , aUseRemainNeedQty          => aUseRemainNeedQty
                                                       , aUseOnlyReservedQtySTT     => aUseOnlyReservedQtySTT
                                                        );
  end;

  /**
  *  Description : Fonction qui indique suivant le contexte, si la sortie de composant
  *                doit être faite ou non
  *                Conditions de sortie des composants :
  *                  1) Le composant est de type actif
  *                  2) Si la sortie a lieu au Suivi, la séquence opératoire est <> 0 ou NULL
  *                  3) La sortie a lieu au Mouvement composants
  *                     OU (La Sortie a lieu au Suivi) ET (Le type de décharge = 3 (ou 5) OU (Type décharge = 4 ET l'opération est soldée))
  *                  4) On prend uniquement les compo avec besoin et (donc) la quantité besoin CPT <> 0
  *                     OU on prend tous les composants
  */
  function MustDoOutput(
    aOpSeqFrom            number
  , aOpSeqTo              number
  , aComponentWithNeed    integer
  , aStepNumber           number
  , aStepNumberNextOpe    number
  , aBalanceQty           FAL_TASK_LINK.TAL_DUE_QTY%type
  , aContext              number default 0
  , aC_DISCHARGE_COM      FAL_LOT_MATERIAL_LINK.C_DISCHARGE_COM%type
  , aC_TYPE_COM           FAL_LOT_MATERIAL_LINK.C_TYPE_COM%type
  , aLOM_NEED_QTY         FAL_LOT_MATERIAL_LINK.LOM_NEED_QTY%type
  , aLOM_STOCK_MANAGEMENT FAL_LOT_MATERIAL_LINK.LOM_STOCK_MANAGEMENT%type
  , aC_KIND_COM           FAL_LOT_MATERIAL_LINK.C_KIND_COM%type
  , aLOM_TASK_SEQ         FAL_LOT_MATERIAL_LINK.LOM_TASK_SEQ%type
  )
    return integer
  is
    Autorisation integer;
    nOpSeqFrom   number;
    nOpSeqTo     number;
  begin
    Autorisation  := 0;

    if aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtProductionAdvance then
      if    aC_DISCHARGE_COM = '3'
         or aC_DISCHARGE_COM = '5' then
        nOpSeqFrom  := aStepNumber;
      elsif aC_DISCHARGE_COM = '4' then
        nOpSeqFrom  := aStepNumberNextOpe;
      end if;

      nOpSeqTo  := nOpSeqFrom;
    else
      nOpSeqFrom  := aOpSeqFrom;
      nOpSeqTo    := aOpSeqTo;
    end if;

    if     aC_TYPE_COM = '1'
       and aLOM_STOCK_MANAGEMENT = 1
       and aC_KIND_COM = '1'
       and (    (    aLOM_NEED_QTY <> 0
                 and aComponentWithNeed = 1)
            or aComponentWithNeed = 0)
       and not(    aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtProductionAdvance
               and nvl(nOpSeqFrom, 0) = 0)
       and (    ( (   aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtComponentOutput
                   or aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtSubContractPTransfer) )
            or (    aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtSubContractOTransfer
                and aC_DISCHARGE_COM = '6')
            or (    aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtProductionAdvance
                and (    (   aC_DISCHARGE_COM = '3'
                          or aC_DISCHARGE_COM = '5')
                     or (    aC_DISCHARGE_COM = '4'
                         and aBalanceQty = 0) )
               )
           ) then
      -- Si on a un intervalle de séquences
      if (    nOpSeqFrom <> 0
          and nopSeqTo <> 0) then
        if (    nOpSeqFrom <= nvl(aLOM_TASK_SEQ, 0)
            and nvl(aLOM_TASK_SEQ, 0) <= nOpSeqTo) then
          Autorisation  := 1;
        end if;
      -- Si on a la borne inf des séquences
      elsif nOpSeqFrom <> 0 then
        if nOpSeqFrom <= nvl(aLOM_TASK_SEQ, 0) then
          Autorisation  := 1;
        end if;
      -- Si on a la borne sup des séquences
      elsif nOpSeqTo <> 0 then
        if nvl(aLOM_TASK_SEQ, 0) <= nOpSeqTo then
          Autorisation  := 1;
        end if;
      -- Si on a aucune borne de séquences
      else
        Autorisation  := 1;
      end if;
    end if;

    return Autorisation;
  end;
end;
