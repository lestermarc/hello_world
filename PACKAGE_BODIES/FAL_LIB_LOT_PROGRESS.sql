--------------------------------------------------------
--  DDL for Package Body FAL_LIB_LOT_PROGRESS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_LOT_PROGRESS" 
is
  /**
  * Description
  *    Retourne l'ID de l'Op�ration de lot du suivi d'avancement transmis en
  *    param�tre.
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
  *    Retourne la somme des quantit�s des suivis d'avancement (Qt� r�alis�e + Qt�
  *    Rebut PT) non extourn�s pour l'op�ration de lot transmise en param�tre.
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
  *    Retourne 1 si une pes�e doit �tre faite pour le suivi d'avancement transmis
  *    en param�tre. Le suivi doit �tre post� auparavant pour �tre pris en compte.
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
    /* R�cup�ration de l'ID de l'op�ration de lot du suivi d'avancement si pas transmis */
    if inFalTaskLinkID is null then
      lnFalTaskLinkID  := getFalTaskLinkID(inFalLotProgressID => inFalLotProgressID);
    else
      lnFalTaskLinkID  := inFalTaskLinkID;
    end if;

    /* V�rification pes�es li�es � un suivi d'avancement */
    if nvl(inFalLotProgressFogId, 0) <> 0 then
      lnQtyToWeigh  := nvl(inPFG_PRODUCT_QTY, 0) + nvl(inPFG_PT_REJECT_QTY, 0);
    else
      /* Somme des pi�ces termin�es selon suivi d'avancement (termin�es + rebut) */
      lnQtyToWeigh  := getSumQtyByTaskLink(inFalTaskLinkID => lnFalTaskLinkID) + nvl(inPFG_PRODUCT_QTY, 0) + nvl(inPFG_PT_REJECT_QTY, 0);
    end if;

    /* Pour chaque alliage du produit fabriqu�, contr�le que les pes�es soient faites. */
    for ltplAlloyToWeigh in
      GCO_I_LIB_PRECIOUS_MAT.gcurGoodAlloysToWeigh
                                   (inGcoGoodID   => FAL_LIB_BATCH.getGcoGoodID
                                                                               (inFalLotID   => FAL_LIB_TASK_LINK.getFalLotID
                                                                                                                             (inFalTaskLinkID   => lnFalTaskLinkID) ) ) loop
      /* Somme des pi�ces pes�es pour l'alliage courant */
      lnQtyWeighed  :=
        FAL_LIB_WEIGH.getSumPieceQtyOut(inFalTaskLinkID         => lnFalTaskLinkID
                                      , inFalLotProgressFogId   => inFalLotProgressFogId
                                      , inGcoAlloyID            => ltplAlloyToWeigh.GCO_ALLOY_ID
                                      , inFweTurnings           => 0
                                      , inCWeighType            => 2
                                       );

      /* Si la somme des pi�ces pes�es pour l'alliage courant est insuffisante */
      if lnQtyWeighed < lnQtyToWeigh then
        return 1;
      end if;
    end loop;

    return 0;
  end isWeighingNeeded;

   /**
  * Description
  *     Retourne la somme des quantit�s pes�es en sortie de type op�ration
  */
  function getSumPieceQtyOutTypeOper(inFalTaskLinkID in FAL_WEIGH.FAL_SCHEDULE_STEP_ID%type, inFalLotProgressID in FAL_WEIGH.FAL_LOT_PROGRESS_ID%type)
    return FAL_WEIGH.FWE_PIECE_QTY%type
  as
    lnSumPieceQtyOut FAL_WEIGH.FWE_WEIGHT_MAT%type   := 0;
  begin
    /* Si des pes�es sont pr�vues sur l'op�ration */
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
  *     Retourne la somme des poids mati�res pes�s en sortie de type op�ration
  */
  function getSumWeightMatOutTypeOper(inFalTaskLinkID in FAL_WEIGH.FAL_SCHEDULE_STEP_ID%type, inFalLotProgressID in FAL_WEIGH.FAL_LOT_PROGRESS_ID%type)
    return FAL_WEIGH.FWE_WEIGHT_MAT%type
  as
    lnSumWeightMatOutTypeOper FAL_WEIGH.FWE_WEIGHT_MAT%type   := 0;
  begin
    /* Si des pes�es sont pr�vues sur l'op�ration */
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
  *     Retourne la somme des poids copeaux pes�s en sortie de type op�ration
  */
  function getSumWeightChipOutTypeOper(inFalTaskLinkID in FAL_WEIGH.FAL_SCHEDULE_STEP_ID%type, inFalLotProgressID in FAL_WEIGH.FAL_LOT_PROGRESS_ID%type)
    return FAL_WEIGH.FWE_WEIGHT_MAT%type
  as
    lnSumWeightMatOutTypeOper FAL_WEIGH.FWE_WEIGHT_MAT%type   := 0;
  begin
    /* Si des pes�es sont pr�vues sur l'op�ration */
    if FAL_LIB_TASK_LINK.isWeighingManaged(inFalTaskLinkID => inFalTaskLinkID) = 1 then
      /* Si la r�cup�ration de copeaux est pr�vue sur l'op�ration (hors mouvements de d�riv�) */
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
  *     Retourne la somme des poids pierres pes�s en sortie de type op�ration
  */
  function getSumWeightStoneOutTypeOper(inFalTaskLinkID in FAL_WEIGH.FAL_SCHEDULE_STEP_ID%type, inFalLotProgressID in FAL_WEIGH.FAL_LOT_PROGRESS_ID%type)
    return FAL_WEIGH.FWE_WEIGHT_MAT%type
  as
    lnSumWeightStoneOutTypeOper FAL_WEIGH.FWE_WEIGHT_MAT%type   := 0;
  begin
    /* Si des pes�es sont pr�vues sur l'op�ration */
    if FAL_LIB_TASK_LINK.isWeighingManaged(inFalTaskLinkID => inFalTaskLinkID) = 1 then
      /* Si le produit termin� poss�de un alliage de type pierre */
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
  *     Retourne les IDs des suivis d'avancement du lot r�alis� apr�s celui transmis en param�tre.
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
