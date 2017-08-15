--------------------------------------------------------
--  DDL for Package Body DOC_SUBCONTRACT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_SUBCONTRACT" 
is
  /**
  * Description
  *   Recherche de la référence complète du lot de fabrication
  */
  function GetLotRefCompl(aPositionId in DOC_POSITION.DOC_POSITION_ID%type)
    return FAL_LOT.LOT_REFCOMPL%type
  is
    vResult FAL_LOT.LOT_REFCOMPL%type;
  begin
    begin
      select LOT.LOT_REFCOMPL
        into vResult
        from FAL_LOT LOT
           , DOC_POSITION_DETAIL DET
           , FAL_TASK_LINK TAL
       where DET.DOC_POSITION_ID = aPositionId
         and TAL.FAL_SCHEDULE_STEP_ID = DOC_LIB_SUBCONTRACT.getSubcontractOperation(DET.DOC_POSITION_ID)
         and LOT.FAL_LOT_ID = TAL.FAL_LOT_ID;
    exception
      when no_data_found then
        vResult  := '';
    end;

    return vResult;
  end GetLotRefCompl;

/*-----------------------------------------------------------------------------------*/
  procedure UpdatePosWithLotRefCompl(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
  begin
    update DOC_POSITION
       set POS_SHORT_DESCRIPTION = nvl(DOC_SUBCONTRACT.GETLOTREFCOMPL(DOC_POSITION_ID), POS_SHORT_DESCRIPTION)
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_DOCUMENT_ID = aDocumentId;
  end UpdatePosWithLotRefCompl;

  /**
  * Description
  *   Mise à jour des opérations liées aux positions du document. Mise à jour de la date de fin planifié sur l'opération
  *   et replanification du lot et mise à jour des réseaux.
  */
  procedure UpdateDocWithOpToPlan(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    cursor crPositionsWithOperation(cDocumentID number)
    is
      select POS.DOC_POSITION_ID
           , DOC_LIB_SUBCONTRACT.getSubcontractOperation(POS.DOC_POSITION_ID) FAL_SCHEDULE_STEP_ID
           , nvl(POS.POS_UPDATE_OP, 0) POS_UPDATE_OP
        from DOC_POSITION POS
           , DOC_GAUGE_POSITION GAP
           , DOC_GAUGE GAU
       where POS.DOC_DOCUMENT_ID = cDocumentID
         and nvl(POS.POS_UPDATE_OP, 0) > 0
         and POS.C_GAUGE_TYPE_POS <> '3'
         -- Exlue les positions Outils
         and GAU.DOC_GAUGE_ID = POS.DOC_GAUGE_ID
         and instr(PCS.PC_CONFIG.GetConfig('DOC_GAUGE_OP_SUBCONTRACT'), GAU.DIC_GAUGE_TYPE_DOC_ID) > 0
         and DOC_LIB_SUBCONTRACT.getSubcontractOperation(POS.DOC_POSITION_ID) is not null
         and POS.C_DOC_POS_STATUS in('01', '02', '03')
         and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
         and GAP.GAP_DELAY = 1;

    docPositionDetailID DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    docGaugeReceiptId   DOC_POSITION_DETAIL.DOC_GAUGE_RECEIPT_ID%type;
    posUpdateOp         DOC_POSITION.POS_UPDATE_OP%type;
  begin
    for tplPositionWithOperation in crPositionsWithOperation(aDocumentID) loop
      -- Recherche le détail de la position qui contient le plus grand délai pas encore soldé (quantité solde <> 0)
      select DOC_POSITION_DETAIL_ID
           , DOC_GAUGE_RECEIPT_ID
        into docPositionDetailID
           , docGaugeReceiptId
        from (select   PDE.DOC_POSITION_DETAIL_ID
                     , PDE.FAL_SCHEDULE_STEP_ID
                     , PDE.PDE_FINAL_DELAY
                     , PDE.DOC_GAUGE_RECEIPT_ID
                  from DOC_POSITION_DETAIL PDE
                 where PDE.DOC_POSITION_ID = tplPositionWithOperation.DOC_POSITION_ID
              order by PDE.PDE_FINAL_DELAY desc)
       where rownum = 1;

      posUpdateOp  := tplPositionWithOperation.POS_UPDATE_OP;

      if    posUpdateOp = 1   --Delai
         or posUpdateOp = 3 then   --Delai + montant
        -- Mise à jour de la date de fin planifié sur l'opération et replanification du lot et mise à jour des réseaux
        FAL_PRC_SUBCONTRACTO.updateCstDelay(docPositionDetailID);
      end if;

      if    posUpdateOp = 2   --montant
         or posUpdateOp = 3 then   --Delai + montant
        -- Mise à jour du prix unitaire en monnaie de base de l'opération selon le prix unitaire de la position
        FAL_SUIVI_OPERATION.UpdateOperationAmount(iDocPositionId => tplPositionWithOperation.DOC_POSITION_ID, iDocGaugeReceiptId => docGaugeReceiptId);
      end if;

      -- Vide le flag de mise à jour de l'opération sur la position.
      update DOC_POSITION
         set POS_UPDATE_OP = 0
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_POSITION_ID = tplPositionWithOperation.DOC_POSITION_ID
         and (    (POS_UPDATE_OP = 1)
              or (POS_UPDATE_OP = 3) );
    end loop;
  end UpdateDocWithOpToPlan;

  /**
  * Description
  *   Mise à jour des opérations liées à la position spécifiée. Mise à jour de la date de fin planifié sur l'opération
  *   et replanification du lot et mise à jour des réseaux.
  */
  procedure UpdatePosWithOpToPlan(aPositionID in DOC_POSITION.DOC_POSITION_ID%type)
  is
    aMessage varchar2(255);
  begin
    UpdatePosWithOpToPlan(aPositionID, 0, aMessage);
  end UpdatePosWithOpToPlan;

  /**
  * procedure UpdatePosWithOpToPlan
  * Description
  *   Mise à jour des opérations liées à la position spécifiée. Mise à jour de la date de fin planifié sur l'opération
  *   et replanification du lot et mise à jour des réseaux. Avec retour d'un message d'avertissement.
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aPositionID : ID de la position
  * @param   aDoWarning  : Doit on avertir l'utilisateur ou non.
  * @param   aMessage    : Message, d'erreur, info ou avertissement
  */
  procedure UpdatePosWithOpToPlan(aPositionID in DOC_POSITION.DOC_POSITION_ID%type, aDoWarning in integer, aMessage in out varchar2)
  is
    docPositionDetailID DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    falScheduleStepID   FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type;
    bStop               boolean;
    docGaugeReceiptId   DOC_POSITION_DETAIL.DOC_GAUGE_RECEIPT_ID%type;
    posUpdateOp         DOC_POSITION.POS_UPDATE_OP%type;
  begin
    bStop  := false;

    begin
      -- Vérifie si le type de gabarit figure dans la liste des gabarits de la config DOC_GAUGE_OP_SUBCONTRACT
      -- et recherche le détail de position qui possède le délai le plus long
      select DOC_LIB_SUBCONTRACT.getSubcontractOperation(POS.DOC_POSITION_ID)
           , nvl(POS.POS_UPDATE_OP, 0) POS_UPDATE_OP
        into falScheduleStepID
           , PosUpdateOP
        from DOC_POSITION POS
           , DOC_GAUGE_POSITION GAP
           , DOC_GAUGE GAU
       where POS.DOC_POSITION_ID = aPositionID
         and nvl(POS.POS_UPDATE_OP, 0) > 0
         and POS.C_GAUGE_TYPE_POS <> '3'
         -- Exlue les positions Outils
         and GAU.DOC_GAUGE_ID = POS.DOC_GAUGE_ID
         and instr(PCS.PC_CONFIG.GetConfig('DOC_GAUGE_OP_SUBCONTRACT'), GAU.DIC_GAUGE_TYPE_DOC_ID) > 0
         and DOC_LIB_SUBCONTRACT.getSubcontractOperation(POS.DOC_POSITION_ID) is not null
         and POS.C_DOC_POS_STATUS in('01', '02', '03')
         and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
         and GAP.GAP_DELAY = 1;
    exception
      when no_data_found then
        bStop  := true;
    end;

    if not bStop then
      -- Recherche le détail de la position qui contient le plus grand délai pas encore soldé (quantité solde <> 0)
      select DOC_POSITION_DETAIL_ID
           , FAL_SCHEDULE_STEP_ID
           , DOC_GAUGE_RECEIPT_ID
        into docPositionDetailID
           , falScheduleStepID
           , docGaugeReceiptId
        from (select   PDE.DOC_POSITION_DETAIL_ID
                     , DOC_LIB_SUBCONTRACT.getSubcontractOperation(PDE.DOC_POSITION_ID) FAL_SCHEDULE_STEP_ID
                     , PDE.PDE_FINAL_DELAY
                     , PDE.DOC_GAUGE_RECEIPT_ID
                  from DOC_POSITION_DETAIL PDE
                 where PDE.DOC_POSITION_ID = aPositionID
              order by PDE.PDE_FINAL_DELAY desc)
       where rownum = 1;

      if     (   posUpdateOp = 1   -- delai
              or posUpdateOp = 3)   --Delai + montant
         and falScheduleStepID is not null then
        -- Mise à jour de la date de fin planifié sur l'opération et replanification du lot et mise à jour des réseaux
        FAL_PRC_SUBCONTRACTO.updateCstDelay(docPositionDetailID, aDoWarning, aMessage);

        if     aDoWarning = 1
           and aMessage is not null then
          return;
        end if;
      end if;

      if    posUpdateOp = 2   -- montant
         or posUpdateOp = 3 then   --Delai + montant
        -- Mise à jour du prix unitaire en monnaie de base de l'opération selon le prix unitaire de la position
        FAL_SUIVI_OPERATION.UpdateOperationAmount(iDocPositionId => aPositionId, iDocGaugeReceiptId => docGaugeReceiptId);
      end if;

      -- Vide le flag de mise à jour de l'opération sur la position.
      update DOC_POSITION
         set POS_UPDATE_OP = 0
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_POSITION_ID = aPositionID
         and (    (POS_UPDATE_OP = 1)
              or (POS_UPDATE_OP = 3) );
    end if;
  end UpdatePosWithOpToPlan;

  /**
  * Description
  *   Recherche les informations pour la mise à jour l'opération liée à la position courante.
  */
  procedure GetInfoPosWithOp(
    iPositionID         in     DOC_POSITION.DOC_POSITION_ID%type
  , ioScheduleStepID    in out FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  , ioBalanceQuantitySU in out DOC_POSITION.POS_BALANCE_QUANTITY%type
  )
  is
  begin
    ioScheduleStepID     := null;
    ioBalanceQuantitySU  := null;

    for ltplPosDetail in (select nvl(pde.FAL_SCHEDULE_STEP_ID, pos.FAL_SCHEDULE_STEP_ID) FAL_SCHEDULE_STEP_ID
                               , pde.PDE_FINAL_QUANTITY_SU
                            from DOC_POSITION pos
                               , DOC_POSITION_DETAIL pde
                               , DOC_GAUGE_STRUCTURED gas
                           where pos.DOC_POSITION_ID = iPositionID
                             and pde.DOC_POSITION_ID = pos.DOC_POSITION_ID
                             and pos.C_GAUGE_TYPE_POS <> '3'   -- no tools position
                             and pos.C_DOC_POS_STATUS in('01', '02', '03')
                             and pos.STM_MOVEMENT_KIND_ID is null
                             and pos.FAL_SCHEDULE_STEP_ID is not null
                             and gas.C_GAUGE_TITLE = '1'   -- Purchase order
                             and gas.DOC_GAUGE_ID = pos.DOC_GAUGE_ID) loop
      ioScheduleStepID     := ltplPosDetail.FAL_SCHEDULE_STEP_ID;
      ioBalanceQuantitySU  := ltplPosDetail.PDE_FINAL_QUANTITY_SU;
    end loop;
  end GetInfoPosWithOP;
end DOC_SUBCONTRACT;
