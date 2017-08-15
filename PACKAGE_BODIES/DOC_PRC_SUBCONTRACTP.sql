--------------------------------------------------------
--  DDL for Package Body DOC_PRC_SUBCONTRACTP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_PRC_SUBCONTRACTP" 
is
    /**
  * procedure GenDeliveryCompDocs
  * Description
  *   Création des docs de livraison des composants au sous-traitant (BLST)
  */
  procedure GenDeliveryCompDocs(iSession in varchar2)
  is
  begin
    DOC_I_PRC_SUBCONTRACT.GenCompDocuments(iSession => iSession, iTransfertMode => 'DELIVERY', iSubContractPurchase => 1);
  end GenDeliveryCompDocs;

  /**
  * procedure GenReturnCompDocs
  * Description
  *   Création des docs de retour des composants du sous-traitant (BLRST)
  */
  procedure GenReturnCompDocs(iSession in varchar2, iReturnLocationID in number default null, iTrashLocationID in number default null)
  is
  begin
    DOC_I_PRC_SUBCONTRACT.GenCompDocuments(iSession               => iSession
                                         , iTransfertMode         => 'RETURN'
                                         , iSubContractPurchase   => 1
                                         , iReturnLocationId      => iReturnLocationId
                                         , iTrashLocationId       => iTrashLocationId
                                          );
  end GenReturnCompDocs;

  /**
  * procedure UpdateSUPOBasisDelay
  * Description
  *   Modification du délai de base avec recalcul des délais intermédiaire/final
  *     du détail de position de la CAST lié au lot de fabrication
  */
  procedure UpdateSUPOBasisDelay(iFalLotID in FAL_LOT.FAL_LOT_ID%type, iNewDelay in date)
  is
  begin
    DOC_PRC_SUBCONTRACT.UpdatePOSDelay(iFalLotID => iFalLotID, iNewDelay => iNewDelay, iUpdatedDelay => 'BASIS');
  end UpdateSUPOBasisDelay;

  /**
  * procedure UpdateSUPOFinalDelay
  * Description
  *   Modification du délai final avec recalcul des délais intermédiaire/base
  *     du détail de position de la CAST lié au lot de fabrication
  */
  procedure UpdateSUPOFinalDelay(iFalLotID in FAL_LOT.FAL_LOT_ID%type, iNewDelay in date)
  is
  begin
    DOC_PRC_SUBCONTRACT.UpdatePOSDelay(iFalLotID => iFalLotID, iNewDelay => iNewDelay, iUpdatedDelay => 'FINAL');
  end UpdateSUPOFinalDelay;

  /**
  * procedure UpdateOperationLink
  * Description
  *   Mise à jour de la position courante avec le lien sur l'opération du lot à réceptionner.
  *   Cela permet la création du suivi d'opération.
  *   Cela indique également que la position courante est en cours de réception. }
  */
  procedure UpdateOperationLink(iPositionId in DOC_POSITION.DOC_POSITION_ID%type, iOperationId in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
  is
    ltPosition           FWK_I_TYP_DEFINITION.t_crud_def;
    ltDetail             FWK_I_TYP_DEFINITION.t_crud_def;
    lnPositionDetailId   DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    lnManufacturedGoodID DOC_POSITION.GCO_MANUFACTURED_GOOD_ID%type;
  begin
    select max(DOC_POSITION_DETAIL_ID)
      into lnPositionDetailId
      from DOC_POSITION_DETAIL
     where DOC_POSITION_ID = iPositionId;

    -- Recherche le produit fabriqué
    select max(LOT.GCO_GOOD_ID)
      into lnManufacturedGoodID
      from FAL_LOT LOT
         , FAL_TASK_LINK TAL
     where TAL.FAL_SCHEDULE_STEP_ID = iOperationID
       and TAL.FAL_LOT_ID = LOT.FAL_LOT_ID;

    if lnPositionDetailId is not null then
      -- Mise à jour de l'opération du lot de fabrication associé à la position
      FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocPosition, ltPosition);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltPosition, 'DOC_POSITION_ID', iPositionId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltPosition, 'FAL_SCHEDULE_STEP_ID', iOperationId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltPosition, 'GCO_MANUFACTURED_GOOD_ID', lnManufacturedGoodID);
      FWK_I_MGT_ENTITY.UpdateEntity(ltPosition);
      FWK_I_MGT_ENTITY.Release(ltPosition);
      -- Mise à jour de l'opération du lot de fabrication associé au détail de position.
      FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocPositionDetail, ltDetail);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltDetail, 'DOC_POSITION_DETAIL_ID', lnPositionDetailId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltDetail, 'FAL_SCHEDULE_STEP_ID', iOperationId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltDetail, 'GCO_MANUFACTURED_GOOD_ID', lnManufacturedGoodID);
      FWK_I_MGT_ENTITY.UpdateEntity(ltDetail);
      FWK_I_MGT_ENTITY.Release(ltDetail);
    end if;
  end;
end DOC_PRC_SUBCONTRACTP;
