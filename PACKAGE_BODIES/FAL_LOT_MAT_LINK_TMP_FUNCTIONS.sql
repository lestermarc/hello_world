--------------------------------------------------------
--  DDL for Package Body FAL_LOT_MAT_LINK_TMP_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LOT_MAT_LINK_TMP_FUNCTIONS" 
is
  /**
  * procedure : ExistsTmpComponents
  * Description : Indique l'existance ou non de composants FAL_LOT_MAT_LINK_TMP
  *               pour la session en cours
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param     aLOM_SESSION    Session oracle
  */
  procedure ExistsTmpComponents(aLOM_SESSION FAL_LOT_MAT_LINK_TMP.LOM_SESSION%type, aNbComponents in out integer)
  is
  begin
    select count(*)
      into aNbComponents
      from FAL_LOT_MAT_LINK_TMP
     where LOM_SESSION = aLOM_SESSION;
  exception
    when others then
      aNbComponents  := 0;
  end;

  /**
  * function : ExistsTmpComponents
  * Description : Indique l'existance ou non de composants FAL_LOT_MAT_LINK_TMP
  *               pour la session en cours et le lot passé en paramètre
  *
  * @created CLG
  * @lastUpdate
  * @public
  * @param   aFalLotId              ID de lot
  * @param   aSessionId             ID unique de Session Oracle
  */
  function ExistsTmpComponents(aFalLotId fal_lot.fal_lot_id%type, aSessionId fal_lot_mat_link_tmp.lom_session%type)
    return boolean
  is
    cntCompo number;
  begin
    select count(*)
      into cntCompo
      from FAL_LOT_MAT_LINK_TMP
     where FAL_LOT_ID = aFalLotId
       and LOM_SESSION = aSessionId;

    return(nvl(cntCompo, 0) > 0);
  exception
    when others then
      return false;
  end;

  /**
  * Description
  *   Création des composants par duplication des composants d'un lot donné
  */
  procedure CreateComponents(
    aFalLotId                  in FAL_LOT.FAL_LOT_ID%type default null
  , aDocumentId                in DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null
  , aPositionId                in DOC_POSITION.DOC_POSITION_ID%type default null
  , aFalLotMaterialLinkId      in FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type default null
  , aSessionId                 in FAL_LOT_MAT_LINK_TMP.LOM_SESSION%type default null
  , aContext                   in integer default 0
  , aOpSeqFrom                 in number default null
  , aOpSeqTo                   in number default null
  , aComponentWithNeed         in integer default null
  , aBalanceNeed               in integer default null
  , aComponentSeqFrom          in number default null
  , aComponentSeqTo            in number default null
  , aStepNumber                in number default null
  , aStepNumberNextOp          in number default null
  , aBalanceQty                in FAL_TASK_LINK.TAL_DUE_QTY%type default null
  , aCaseReleaseCode           in integer default 0
  , aGcoGoodId                 in number default null
  , aFalJobProgramId           in number default null
  , aCPriority                 in number default null
  , aDocRecordId               in number default null
  , aPriorityDate              in date default null
  , aReceptionQty              in number default null
  , aQtyToSwitch               in number default 0
  , ReceptionType              in integer default 1   --FAL_BATCH_FUNCTIONS.rtFinishedProduct
  , aDisplayAllComponentsDispo in integer default 0
  , aQtySup                    in number default 0
  , iStmStmStockId             in number default 0
  , iStmStmLocationId          in number default 0
  )
  is
    pragma autonomous_transaction;
  begin
    FAL_LOT_MAT_LINK_TMP_FCT.CreateComponents(aFalLotId                    => aFalLotId
                                            , aDocumentId                  => aDocumentId
                                            , aPositionId                  => aPositionId
                                            , aFalLotMaterialLinkId        => aFalLotMaterialLinkId
                                            , aSessionId                   => aSessionId
                                            , aContext                     => aContext
                                            , aOpSeqFrom                   => aOpSeqFrom
                                            , aOpSeqTo                     => aOpSeqTo
                                            , aComponentWithNeed           => aComponentWithNeed
                                            , aBalanceNeed                 => aBalanceNeed
                                            , aComponentSeqFrom            => aComponentSeqFrom
                                            , aComponentSeqTo              => aComponentSeqTo
                                            , aStepNumber                  => aStepNumber
                                            , aStepNumberNextOp            => aStepNumberNextOp
                                            , aBalanceQty                  => aBalanceQty
                                            , aCaseReleaseCode             => aCaseReleaseCode
                                            , aGcoGoodId                   => aGcoGoodId
                                            , aFalJobProgramId             => aFalJobProgramId
                                            , aCPriority                   => aCPriority
                                            , aDocRecordId                 => aDocRecordId
                                            , aPriorityDate                => aPriorityDate
                                            , aReceptionQty                => aReceptionQty
                                            , aQtyToSwitch                 => aQtyToSwitch
                                            , ReceptionType                => ReceptionType
                                            , aDisplayAllComponentsDispo   => aDisplayAllComponentsDispo
                                            , aQtySup                      => aQtySup
                                            , iStmStmStockId               => iStmStmStockId
                                            , iStmStmLocationId            => iStmStmLocationId
                                             );
    commit;
  end;

  /**
  * procédure PurgeLotMatLinkTmpTable
  * Description
  *   Suppression des enregistrements de la table FAL_LOT_MAT_LINK_TMP dont la
  *   session Oracle n'est plus valide
  * @created CLE
  * @lastUpdate
  * @public
  */
  procedure PurgeLotMatLinkTmpTable
  is
    pragma autonomous_transaction;
  begin
    FAL_LOT_MAT_LINK_TMP_FCT.PurgeLotMatLinkTmpTable;
    commit;
  end;

  /**
  * procédure PurgeLotMatLinkTmpTable
  * Description
  *   Suppression des enregistrements de la table FAL_LOT_MAT_LINK_TMP pour une
  *   session Oracle donnée en paramètre
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aSessionId             ID unique de Session Oracle
  */
  procedure PurgeLotMatLinkTmpTable(aSessionId FAL_COMPONENT_LINK.FCL_SESSION%type)
  is
    pragma autonomous_transaction;
  begin
    FAL_LOT_MAT_LINK_TMP_FCT.PurgeLotMatLinkTmpTable(aSessionId);
    commit;
  end;

  /**
  * procédure PurgeAllTemporaryTable
  * Description
  *   Suppression des enregistrements de la table FAL_LOT_MAT_LINK_TMP et
  *   FAL_COMPONENT_LINK  pour une session Oracle donnée en paramètre, ainsi
  *   que pour les éventuelles session invalides.
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aSessionId             ID unique de Session Oracle
  */
  procedure PurgeAllTemporaryTable(aSessionId FAL_COMPONENT_LINK.FCL_SESSION%type)
  is
    pragma autonomous_transaction;
  begin
    FAL_LOT_MAT_LINK_TMP_FCT.PurgeAllTemporaryTable(aSessionId);
    commit;
  end;

  /**
  * procédure PurgeTemporaryTable
  * Description
  *   Suppression des enregistrements de la table FAL_LOT_MAT_LINK_TMP et
  *   FAL_COMPONENT_LINK  pour un lot donné. Dans une transaction autonome
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aFalLotId    Id du lot
  */
  procedure PurgeTemporaryTable(aFalLotId FAL_LOT.FAL_LOT_ID%type)
  is
    pragma autonomous_transaction;
  begin
    FAL_LOT_MAT_LINK_TMP_FCT.PurgeTemporaryTable(aFalLotId);
    commit;
  end;

  /**
  * procédure UpdateMaxReceiptQty
  * Description
  *   Mise à jour de la quantité max réceptionnable d'un composant.
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aSessionId             Id unique de Session Oracle
  * @param   FalLotMatLinkTmpId     Id du composant
  * @param   aUpdateBatch           Défini si on met à jour également le lot
  */
  procedure UpdateMaxReceiptQty(
    aSessionId         varchar2
  , FalLotMatLinkTmpId FAL_LOT_MAT_LINK_TMP.FAL_LOT_MAT_LINK_TMP_ID%type default null
  , aUpdateBatch       integer default 0
  )
  is
    pragma autonomous_transaction;
  begin
    FAL_LOT_MAT_LINK_TMP_FCT.UpdateMaxReceiptQty(aSessionId, FalLotMatLinkTmpId, aUpdateBatch);
    commit;
  end;

  /**
  * procédure UpdateLomAdjustedQty
  * Description
  *   Mise à jour de la qté sup inf d'un composant temporaire
  *
  * @created ECA
  * @lastUpdate
  * @publics
  * @param   aLomadjustedQty nouvelle qté sup / Inf
  * @param   aLomFullReqQty Qté besoin totale
  * @param   aLomNeedQty Qté Besoin CPT
  * @param   aLomUtilCoef Coef utilisation
  * @param   aLomBomReqQty Qté besoin
  */
  procedure UpdateLomAdjustedQty(
    FalLotMatLinkTmpId in number
  , aLomAdjustedQty    in number
  , aLomFullReqQty     in number
  , aLomNeedQty        in number
  , aLomUtilCoef       in number
  , aLomBomReqQty      in number
  )
  is
    pragma autonomous_transaction;
  begin
    FAL_LOT_MAT_LINK_TMP_FCT.UpdateLomAdjustedQty(FalLotMatLinkTmpId   => FalLotMatLinkTmpId
                                                , aLomAdjustedQty      => aLomAdjustedQty
                                                , aLomFullReqQty       => aLomFullReqQty
                                                , aLomNeedQty          => aLomNeedQty
                                                , aLomUtilCoef         => aLomUtilCoef
                                                , aLomBomReqQty        => aLomBomReqQty
                                                 );
    commit;
  end;

  /**
  * procedure UpdateLomCommentary
  * Description
  *   Mise à jour du code motif et du commentaire, destiné à être portés sur les
  *   entrées et sorties atelier
  *
  * @created ECA
  * @lastUpdate
  * @publics
  * @param   aFalLotMatLinkTmpId     Composant
  * @param   aApplyToAll             Appliquer à tous les composants de la session
  * @param   aSessionId              Session Oracle
  * @param   aDIC_COMPONENT_MVT_ID   Code Motif
  * @param   aCommentary             Commentaire
  */
  procedure UpdateLomCommentary(
    aSessionId            in varchar2
  , aFalLotMatLinkTmpId   in number default null
  , aApplyToAll           in integer default 0
  , aDIC_COMPONENT_MVT_ID in varchar2 default ''
  , aCommentary           in varchar2 default ''
  )
  is
    pragma autonomous_transaction;
  begin
    FAL_LOT_MAT_LINK_TMP_FCT.UpdateLomCommentary(aSessionId              => aSessionId
                                               , aFalLotMatLinkTmpId     => aFalLotMatLinkTmpId
                                               , aApplyToAll             => aApplyToAll
                                               , aDIC_COMPONENT_MVT_ID   => aDIC_COMPONENT_MVT_ID
                                               , aCommentary             => aCommentary
                                                );
    commit;
  end;
end;
