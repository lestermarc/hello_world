--------------------------------------------------------
--  DDL for Package Body FAL_LIB_LOT_PROGRESS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_LOT_PROGRESS" 
is
  /**
  * Description
  *    Retourne l'ID de l'Opération de lot du suivi d'avancement transmis en
  *    paramètre.
  */
  function getFalTaskLinkID(inFalLotProgressID in FAL_LOT_PROGRESS.FAL_LOT_PROGRESS_ID%type)
    return FAL_LOT_PROGRESS.FAL_SCHEDULE_STEP_ID%type
  as
    lnFalTaskLinkID FAL_LOT_PROGRESS.FAL_SCHEDULE_STEP_ID%type;
  begin
    select FAL_SCHEDULE_STEP_ID
      into lnFalTaskLinkID
      from FAL_LOT_PROGRESS
     where FAL_LOT_PROGRESS_ID = inFalLotProgressID;

    return lnFalTaskLinkID;
  exception
    when no_data_found then
      return null;
  end getFalTaskLinkID;

  /**
  * Description
  *    Retourne la somme des quantités des suivis d'avancement (Qté réalisée + Qté
  *    Rebut PT) non extournés pour l'opération de lot transmise en paramètre.
  */
  function getSumQtyByTaskLink(inFalTaskLinkID in FAL_LOT_PROGRESS.FAL_SCHEDULE_STEP_ID%type)
    return number
  as
    lnSumQtyByTaskLink number;
  begin
    select sum(nvl(FLP_PRODUCT_QTY, 0) ) + sum(nvl(FLP_PT_REJECT_QTY, 0) )
      into lnSumQtyByTaskLink
      from FAL_LOT_PROGRESS
     where FAL_SCHEDULE_STEP_ID = inFalTaskLinkID
       and FLP_REVERSAL = 0;

    return nvl(lnSumQtyByTaskLink, 0);
  exception
    when no_data_found then
      return 0;
  end getSumQtyByTaskLink;

  /**
  * function isWeighingNeeded
  * Description
  *    Retourne 1 si une pesée doit être faite pour le suivi d'avancement transmis
  *    en paramètre. Le suivi doit être posté auparavant pour être pris en compte.
  */
  function isWeighingNeeded(
    inFalLotProgressID    in FAL_LOT_PROGRESS.FAL_LOT_PROGRESS_ID%type default null
  , inFalTaskLinkID       in FAL_LOT_PROGRESS.FAL_SCHEDULE_STEP_ID%type default null
  , inFalLotProgressFogId in FAL_LOT_PROGRESS_FOG.FAL_LOT_PROGRESS_FOG_ID%type default null
  , inPFG_PRODUCT_QTY     in FAL_LOT_PROGRESS_FOG.PFG_PRODUCT_QTY%type default null
  , inPFG_PT_REJECT_QTY   in FAL_LOT_PROGRESS_FOG.PFG_PT_REFECT_QTY%type default null
  )
    return number
  as
    lnFalTaskLinkID FAL_LOT_PROGRESS.FAL_SCHEDULE_STEP_ID%type;
    lnQtyToWeigh    number;
    lnQtyWeighed    FAL_WEIGH.FWE_PIECE_QTY%type;
  begin
    /* Récupération de l'ID de l'opération de lot du suivi d'avancement si pas transmis */
    if inFalTaskLinkID is null then
      lnFalTaskLinkID  := getFalTaskLinkID(inFalLotProgressID => inFalLotProgressID);
    else
      lnFalTaskLinkID  := inFalTaskLinkID;
    end if;

    /* Vérification pesées liées à un suivi d'avancement */
    if nvl(inFalLotProgressFogId, 0) <> 0 then
      lnQtyToWeigh  := nvl(inPFG_PRODUCT_QTY, 0) + nvl(inPFG_PT_REJECT_QTY, 0);
    else
      /* Somme des pièces terminées selon suivi d'avancement (terminées + rebut) */
      lnQtyToWeigh  := getSumQtyByTaskLink(inFalTaskLinkID => lnFalTaskLinkID) + nvl(inPFG_PRODUCT_QTY, 0) + nvl(inPFG_PT_REJECT_QTY, 0);
    end if;

    /* Pour chaque alliage du produit fabriqué, contrôle que les pesées soient faites. */
    for ltplAlloyToWeigh in
      GCO_I_LIB_PRECIOUS_MAT.gcurGoodAlloysToWeigh
                                   (inGcoGoodID   => FAL_LIB_BATCH.getGcoGoodID
                                                                               (inFalLotID   => FAL_LIB_TASK_LINK.getFalLotID
                                                                                                                             (inFalTaskLinkID   => lnFalTaskLinkID) ) ) loop
      /* Somme des pièces pesées pour l'alliage courant */
      lnQtyWeighed  :=
        FAL_LIB_WEIGH.getSumPieceQtyOut(inFalTaskLinkID         => lnFalTaskLinkID
                                      , inFalLotProgressFogId   => inFalLotProgressFogId
                                      , inGcoAlloyID            => ltplAlloyToWeigh.GCO_ALLOY_ID
                                      , inFweTurnings           => 0
                                      , inCWeighType            => 2
                                       );

      /* Si la somme des pièces pesées pour l'alliage courant est insuffisante */
      if lnQtyWeighed < lnQtyToWeigh then
        return 1;
      end if;
    end loop;

    return 0;
  end isWeighingNeeded;

   /**
  * Description
  *     Retourne la somme des quantités pesées en sortie de type opération
  */
  function getSumPieceQtyOutTypeOper(inFalTaskLinkID in FAL_WEIGH.FAL_SCHEDULE_STEP_ID%type, inFalLotProgressID in FAL_WEIGH.FAL_LOT_PROGRESS_ID%type)
    return FAL_WEIGH.FWE_PIECE_QTY%type
  as
    lnSumPieceQtyOut FAL_WEIGH.FWE_WEIGHT_MAT%type   := 0;
  begin
    /* Si des pesées sont prévues sur l'opération */
    if FAL_LIB_TASK_LINK.isWeighingManaged(inFalTaskLinkID => inFalTaskLinkID) = 1 then
      lnSumPieceQtyOut  :=
        FAL_LIB_WEIGH.getSumPieceQtyOut(inFalTaskLinkID      => inFalTaskLinkID
                                      , inFalLotProgressID   => inFalLotProgressID
                                      , inFweWaste           => 0
                                      , inFweTurnings        => 0
                                      , inCWeighType         => 2
                                       );
    end if;

    return lnSumPieceQtyOut;
  end getSumPieceQtyOutTypeOper;

  /**
  * Description
  *     Retourne la somme des poids matières pesés en sortie de type opération
  */
  function getSumWeightMatOutTypeOper(inFalTaskLinkID in FAL_WEIGH.FAL_SCHEDULE_STEP_ID%type, inFalLotProgressID in FAL_WEIGH.FAL_LOT_PROGRESS_ID%type)
    return FAL_WEIGH.FWE_WEIGHT_MAT%type
  as
    lnSumWeightMatOutTypeOper FAL_WEIGH.FWE_WEIGHT_MAT%type   := 0;
  begin
    /* Si des pesées sont prévues sur l'opération */
    if FAL_LIB_TASK_LINK.isWeighingManaged(inFalTaskLinkID => inFalTaskLinkID) = 1 then
      lnSumWeightMatOutTypeOper  :=
        FAL_LIB_WEIGH.getSumWeightMatOut(inFalTaskLinkID      => inFalTaskLinkID
                                       , inFalLotProgressID   => inFalLotProgressID
                                       , inFweWaste           => 0
                                       , inFweTurnings        => 0
                                       , inCWeighType         => 2
                                        );
    end if;

    return lnSumWeightMatOutTypeOper;
  end getSumWeightMatOutTypeOper;

  /**
  * Description
  *     Retourne la somme des poids copeaux pesés en sortie de type opération
  */
  function getSumWeightChipOutTypeOper(inFalTaskLinkID in FAL_WEIGH.FAL_SCHEDULE_STEP_ID%type, inFalLotProgressID in FAL_WEIGH.FAL_LOT_PROGRESS_ID%type)
    return FAL_WEIGH.FWE_WEIGHT_MAT%type
  as
    lnSumWeightMatOutTypeOper FAL_WEIGH.FWE_WEIGHT_MAT%type   := 0;
  begin
    /* Si des pesées sont prévues sur l'opération */
    if FAL_LIB_TASK_LINK.isWeighingManaged(inFalTaskLinkID => inFalTaskLinkID) = 1 then
      /* Si la récupération de copeaux est prévue sur l'opération (hors mouvements de dérivé) */
      if FAL_LIB_TASK_LINK.hasWeighing(inFalTaskLinkID => inFalTaskLinkID) = 1 then
        lnSumWeightMatOutTypeOper  :=
          FAL_LIB_WEIGH.getSumWeightMatOut(inFalTaskLinkID      => inFalTaskLinkID
                                         , inFalLotProgressID   => inFalLotProgressID
                                         , inFweWaste           => 0
                                         , inFweTurnings        => 1
                                         , inCWeighType         => 2
                                          );
      end if;
    end if;

    return lnSumWeightMatOutTypeOper;
  end getSumWeightChipOutTypeOper;

  /**
  * Description
  *     Retourne la somme des poids pierres pesés en sortie de type opération
  */
  function getSumWeightStoneOutTypeOper(inFalTaskLinkID in FAL_WEIGH.FAL_SCHEDULE_STEP_ID%type, inFalLotProgressID in FAL_WEIGH.FAL_LOT_PROGRESS_ID%type)
    return FAL_WEIGH.FWE_WEIGHT_MAT%type
  as
    lnSumWeightStoneOutTypeOper FAL_WEIGH.FWE_WEIGHT_MAT%type   := 0;
  begin
    /* Si des pesées sont prévues sur l'opération */
    if FAL_LIB_TASK_LINK.isWeighingManaged(inFalTaskLinkID => inFalTaskLinkID) = 1 then
      /* Si le produit terminé possède un alliage de type pierre */
      if FAL_LIB_BATCH.doesFPContainsStoneAlloy(inFalLotID => FAL_LIB_TASK_LINK.getFalLotID(inFalTaskLinkID => inFalTaskLinkID) ) = 1 then
        lnSumWeightStoneOutTypeOper  :=
          FAL_LIB_WEIGH.getSumWeightStoneOutTypeOper(inFalTaskLinkID      => inFalTaskLinkID
                                                   , inFalLotProgressID   => inFalLotProgressID
                                                   , inFweWaste           => 0
                                                   , inFweTurnings        => 0
                                                    );
      end if;
    end if;

    return lnSumWeightStoneOutTypeOper;
  end getSumWeightStoneOutTypeOper;

  /**
  * Description
  *     Retourne les IDs des suivis d'avancement du lot réalisé après celui transmis en paramètre.
  */
  function getFollowingProcessTrackings(iLotID in FAL_LOT_PROGRESS.FAL_LOT_ID%type, iLotProgressID in FAL_LOT_PROGRESS.FAL_LOT_PROGRESS_ID%type)
    return ID_TABLE_TYPE pipelined deterministic
  as
  begin
    for ltplProcessTrackingID in (select FAL_LOT_PROGRESS_ID
                                    from FAL_LOT_PROGRESS
                                   where FAL_LOT_ID = iLotID
                                     and FAL_LOT_PROGRESS_ID >= iLotProgressID) loop
      pipe row(ltplProcessTrackingID.FAL_LOT_PROGRESS_ID);
    end loop;
  exception
    when NO_DATA_NEEDED then
      return;
  end getFollowingProcessTrackings;

  /**
  * Description
  *    Returns 1 if a process tracking has already been carried out on the batch task.
  */
  function existsProgressTrack(iScheduleStepId in FAL_LOT_PROGRESS.FAL_SCHEDULE_STEP_ID%type)
    return integer
  as
    lExists integer;
  begin
    select count('x')
      into lExists
      from dual
     where exists(select 'x'
                    from FAL_LOT_PROGRESS
                   where FAL_SCHEDULE_STEP_ID = iScheduleStepId);

    return lExists;
  end existsProgressTrack;
end FAL_LIB_LOT_PROGRESS;
