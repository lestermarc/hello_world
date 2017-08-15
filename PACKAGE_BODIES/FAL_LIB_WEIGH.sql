--------------------------------------------------------
--  DDL for Package Body FAL_LIB_WEIGH
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_WEIGH" 
is
  /**
  * Description
  *     Cette fonction retourne la somme des pesées d'entrée (poids) de l'alliage
  *     et du bien sur le poste de date supérieur à date de.
  */
  function getSumWeighInByPosAndDate(
    inFalPositionID in FAL_WEIGH.FAL_POSITION1_ID%type
  , inGcoGoodID     in FAL_WEIGH.GCO_GOOD_ID%type
  , inGcoAlloyID    in FAL_WEIGH.GCO_ALLOY_ID%type
  , idDateFrom      in FAL_WEIGH.FWE_DATE%type
  )
    return FAL_WEIGH.FWE_WEIGHT_MAT%type
  as
    lnSumWeigh FAL_WEIGH.FWE_WEIGHT_MAT%type;
  begin
    select nvl(sum(FWE_WEIGHT_MAT), 0)
      into lnSumWeigh
      from FAL_WEIGH
     where FWE_IN = 1
       and FWE_INIT = 0
       and FAL_POSITION1_ID = inFalPositionID
       and (   nvl(inGcoGoodID, 0) = 0
            or nvl(GCO_GOOD_ID, 0) = nvl(inGcoGoodID, 0) )
       and GCO_ALLOY_ID = inGcoAlloyID
       and FWE_DATE > nvl(idDateFrom, to_date('01.01.1800', 'DD.MM.YYYY') );

    return lnSumWeigh;
  exception
    when no_data_found then
      return 0;
  end getSumWeighInByPosAndDate;

  /**
  * Description
  *     Cette fonction retourne la somme des pesées de sortie (poids) de l'alliage
  *     et du bien sur le poste de date supérieur à date de.
  */
  function getSumWeighOutByPosAndDate(
    inFalPositionID in FAL_WEIGH.FAL_POSITION2_ID%type
  , inGcoGoodID     in FAL_WEIGH.GCO_GOOD_ID%type
  , inGcoAlloyID    in FAL_WEIGH.GCO_ALLOY_ID%type
  , idDateFrom      in FAL_WEIGH.FWE_DATE%type
  )
    return FAL_WEIGH.FWE_WEIGHT_MAT%type
  as
    lnSumWeigh FAL_WEIGH.FWE_WEIGHT_MAT%type;
  begin
    select nvl(sum(FWE_WEIGHT_MAT), 0)
      into lnSumWeigh
      from FAL_WEIGH
     where FWE_IN = 0
       and FWE_INIT = 0
       and FAL_POSITION2_ID = inFalPositionID
       and (   nvl(inGcoGoodID, 0) = 0
            or nvl(GCO_GOOD_ID, 0) = nvl(inGcoGoodID, 0) )
       and GCO_ALLOY_ID = inGcoAlloyID
       and FWE_DATE > nvl(idDateFrom, to_date('01.01.1800', 'DD.MM.YYYY') );

    return lnSumWeigh;
  exception
    when no_data_found then
      return 0;
  end getSumWeighOutByPosAndDate;

  /**
  * Description
  *     Cette fonction retourne la somme des pesées d'entrée (qté) de l'alliage
  *     et du bien sur le poste de date supérieur à date de.
  */
  function getSumQtyInByPosAndDate(
    inFalPositionID in FAL_WEIGH.FAL_POSITION1_ID%type
  , inGcoGoodID     in FAL_WEIGH.GCO_GOOD_ID%type
  , inGcoAlloyID    in FAL_WEIGH.GCO_ALLOY_ID%type
  , idDateFrom      in FAL_WEIGH.FWE_DATE%type
  )
    return FAL_WEIGH.FWE_PIECE_QTY%type
  as
    lnSumQty FAL_WEIGH.FWE_WEIGHT_MAT%type;
  begin
    select nvl(sum(FWE_PIECE_QTY), 0)
      into lnSumQty
      from FAL_WEIGH
     where FWE_IN = 1
       and FWE_INIT = 0
       and FAL_POSITION1_ID = inFalPositionID
       and nvl(GCO_GOOD_ID, 0) = nvl(inGcoGoodID, 0)
       and GCO_ALLOY_ID = inGcoAlloyID
       and FWE_DATE > nvl(idDateFrom, to_date('01.01.1800', 'DD.MM.YYYY') );

    return lnSumQty;
  exception
    when no_data_found then
      return 0;
  end getSumQtyInByPosAndDate;

  /**
  * Description
  *     Cette fonction retourne la somme des pesées de sortie (qté) de l'alliage
  *     et du bien sur le poste de date supérieur à date de.
  */
  function getSumQtyOutByPosAndDate(
    inFalPositionID in FAL_WEIGH.FAL_POSITION2_ID%type
  , inGcoGoodID     in FAL_WEIGH.GCO_GOOD_ID%type
  , inGcoAlloyID    in FAL_WEIGH.GCO_ALLOY_ID%type
  , idDateFrom      in FAL_WEIGH.FWE_DATE%type
  )
    return FAL_WEIGH.FWE_PIECE_QTY%type
  as
    lnSumQty FAL_WEIGH.FWE_WEIGHT_MAT%type;
  begin
    select nvl(sum(FWE_PIECE_QTY), 0)
      into lnSumQty
      from FAL_WEIGH
     where FWE_IN = 0
       and FWE_INIT = 0
       and FAL_POSITION2_ID = inFalPositionID
       and nvl(GCO_GOOD_ID, 0) = nvl(inGcoGoodID, 0)
       and GCO_ALLOY_ID = inGcoAlloyID
       and FWE_DATE > nvl(idDateFrom, to_date('01.01.1800', 'DD.MM.YYYY') );

    return lnSumQty;
  exception
    when no_data_found then
      return 0;
  end getSumQtyOutByPosAndDate;

  /**
  * Description
  *     Cette fonction retourne la somme des pesées(poids) pour le lot de fabrication
  *     de type "Retour de composants", "Remplacement de composants" ou "Affectation
  *     de composants - lots vers stocks" dont le stock du poste entrant est l'Atelier et le
  *     stock du poste sortant un autre stock.
  */
  function getSumWeightFacFloorOutByLot(inFalLotID in FAL_WEIGH.FAL_LOT_ID%type)
    return FAL_WEIGH.FWE_WEIGHT_MAT%type
  as
    lnSumWeighMat FAL_WEIGH.FWE_WEIGHT_MAT%type;
  begin
    select nvl(sum(fwe.FWE_WEIGHT_MAT), 0)
      into lnSumWeighMat
      from FAL_WEIGH fwe
         , FAL_POSITION spo_in
         , STM_STOCK sto_in
     where spo_in.FAL_POSITION_ID = fwe.FAL_POSITION1_ID
       and sto_in.STM_STOCK_ID = spo_in.STM_STOCK_ID
       and sto_in.STM_STOCK_ID <> FAL_TOOLS.GetConfig_StockID(ConfigWord => 'PPS_DefltSTOCK_FLOOR')   /* Poste entrant = autre stock que atelier */
       and fwe.FAL_LOT_ID = inFalLotID
       and fwe.C_WEIGH_TYPE in('7', '8', '9');   /* Retour de composants, Remplacement de composants, Affectation de composants - lots vers stocks */

    return lnSumWeighMat;
  exception
    when no_data_found then
      return 0;
  end getSumWeightFacFloorOutByLot;

  /**
  * Description
  *     Cette fonction retourne la somme des pesées(poids) pour le lot de fabrication
  *     de type "Sortie de composants", "Remplacement de composants" ou "Affectation
  *     de composants - lots vers stocks" dont le stock du poste entrant est l'Atelier
  *     ou l'atelier du poste entrant est un atelier d'une opération du lot, et le poste
  *     sortant un stock
  */
  function getSumWeightFacFloorInByLot(inFalLotID in FAL_WEIGH.FAL_LOT_ID%type)
    return FAL_WEIGH.FWE_WEIGHT_MAT%type
  as
    lnSumWeighMat FAL_WEIGH.FWE_WEIGHT_MAT%type;
  begin
    select nvl(sum(fwe.FWE_WEIGHT_MAT), 0)
      into lnSumWeighMat
      from FAL_WEIGH fwe
     where fwe.FAL_LOT_ID = inFalLotID
       and fwe.C_WEIGH_TYPE in('1', '6', '8', '9')
       and (    (fwe.FAL_POSITION1_ID =
                                     FAL_LIB_POSITION.getPositionIDByStockID(inStmStockID   => FAL_TOOLS.GetConfig_StockID(ConfigWord   => 'PPS_DefltSTOCK_FLOOR') )
                )
            or (fwe.FAL_POSITION1_ID in(select FPO.FAL_POSITION_ID
                                          from FAL_POSITION FPO
                                             , FAL_TASK_LINK TAL
                                         where TAL.FAL_LOT_ID = inFalLotID
                                           and TAL.FAL_FACTORY_FLOOR_ID = FPO.FAL_FACTORY_FLOOR_ID) )
           );

    return lnSumWeighMat;
  exception
    when no_data_found then
      return 0;
  end getSumWeightFacFloorInByLot;

  /**
  * Description
  *     Cette fonction retourne la somme des poids en sortie par matière fine pour
  *     un composant.
  *     Retourne les pesées de l'alliage hors copeaux de type "Retour de composants" (7),
  *     "Affectation de composants - lots vers stock" (9), "Remplacement de composants" (8) si poste
  *     sortant = Atelier, "Pesée opération" (2) si config FAL_WEIGH_RECEPT = 0 et "Réception lot fabrication" (4)
  *     si config FAL_WEIGH_RECEPT = 1
  */
  function getSumWeightOutCptByAlloy(
    inGcoAlloyID  in FAL_WEIGH.GCO_ALLOY_ID%type
  , inGcoGoodID   in FAL_LOT_MATERIAL_LINK.GCO_GOOD_ID%type
  , inPercent     in GCO_ALLOY_COMPONENT.GAC_RATE%type
  , inFalLotID    in FAL_LOT.FAL_LOT_ID%type
  , inLomUtilCoef in FAL_LOT_MATERIAL_LINK.LOM_UTIL_COEF%type
  )
    return FAL_WEIGH.FWE_WEIGHT_MAT%type
  as
    lnSumWeightOutCptByAlloy FAL_WEIGH.FWE_WEIGHT_MAT%type;
    liFalWeighRecept         integer;
    lnMatFineRaportee        number;
  begin
    /* Test si le lot est avec pesée en réception : Configuration + Donnée complémentaire
    de fabrication */
    liFalWeighRecept  := FAL_LIB_BATCH.BatchWithReceptWeighing(inFalLotId);

    /* Calcul du pourcentage de matière fine du cpt au sein du produit terminé */
    begin
      lnMatFineRaportee  :=
        100 *
        ( (inLomUtilCoef * GCO_I_LIB_PRECIOUS_MAT.getWeightDeliver(inGcoGoodID => inGcoGoodID, inGcoAlloyID => inGcoAlloyID) *(inPercent * 0.01) ) /
         (FAL_LIB_LOT_MATERIAL_LINK.getSumBasisMatInGood(inFalLotID => inFalLotID, inGcoAlloyID => inGcoAlloyID, inPercent => inPercent)
         )
        );
    exception
      when zero_divide then
        lnMatFineRaportee  := 0;
    end;

    select nvl(sum(case
                     when liFalWeighRecept = 0
                     and C_WEIGH_TYPE = '2' then(nvl(FWE_WEIGHT_MAT, 0) * lnMatFineRaportee)
                     when liFalWeighRecept = 1
                     and C_WEIGH_TYPE = '4' then(nvl(FWE_WEIGHT_MAT, 0) * lnMatFineRaportee)
                     else nvl(FWE_WEIGHT_MAT, 0)
                   end
                  )
             , 0
              )
      into lnSumWeightOutCptByAlloy
      from FAL_WEIGH
     where GCO_ALLOY_ID = inGcoAlloyID
       and FAL_LOT_ID = inFalLotId
       and GCO_GOOD_ID = inGcoGoodId
--       and FWE_TURNINGS = 0
       and FWE_IN = 0
       and (    (C_WEIGH_TYPE = '7')
            or (C_WEIGH_TYPE = '9')
            or (C_WEIGH_TYPE = '11')
            or (    C_WEIGH_TYPE = '8'
                and FAL_POSITION2_ID =
                                     FAL_LIB_POSITION.getPositionIDByStockID(inStmStockID   => FAL_TOOLS.GetConfig_StockID(ConfigWord   => 'PPS_DefltSTOCK_FLOOR') )
               )
            or (    liFalWeighRecept = 1
                and C_WEIGH_TYPE = '4')
            or (    liFalWeighRecept = 0
                and C_WEIGH_TYPE = '2'
                and FAL_SCHEDULE_STEP_ID = FAL_LIB_BATCH.getLastTaskLink(inFalLotID => inFalLotID) )
           );

    return(lnSumWeightOutCptByAlloy * inPercent * 0.01);
  exception
    when no_data_found then
      return 0;
  end getSumWeightOutCptByAlloy;

  /**
  * Description
  *     Cette fonction retourne la somme des poids en entrée par matière fine pour
  *     un composant.
  *     Retourne les pesées de l'alliage hors copeaux de type "Sortie Composant" (1), "Sortie de composants" (6)
  *     "Affectation de composants - stock vers lots" (10) et "Remplacement de composants" (8) si poste
  *     entrant = Atelier ou Poste correspondant à une opération du lot
  */
  function getSumWeightInCptByAlloy(
    inGcoAlloyID         in FAL_WEIGH.GCO_ALLOY_ID%type
  , inPercent            in GCO_ALLOY_COMPONENT.GAC_RATE%type
  , inFalLotMaterialLink in FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type default null
  )
    return FAL_WEIGH.FWE_WEIGHT_MAT%type
  as
    lnSumWeightInCptByAlloy FAL_WEIGH.FWE_WEIGHT_MAT%type;
  begin
    select nvl(sum(FWE_WEIGHT_MAT), 0)
      into lnSumWeightInCptByAlloy
      from FAL_WEIGH
     where GCO_ALLOY_ID = inGcoAlloyID
       and (   nvl(inFalLotMaterialLink, 0) = 0
            or FAL_LOT_MATERIAL_LINK_ID = inFalLotMaterialLink)
       and FWE_TURNINGS = 0
       and FWE_IN = 1
       and (    (C_WEIGH_TYPE in('1', '6', '10') )
            or (    C_WEIGH_TYPE = '8'
                and (   FAL_POSITION1_ID =
                                     FAL_LIB_POSITION.getPositionIDByStockID(inStmStockID   => FAL_TOOLS.GetConfig_StockID(ConfigWord   => 'PPS_DefltSTOCK_FLOOR') )
                     or FAL_POSITION1_ID in(
                          select FPO.FAL_POSITION_ID
                            from FAL_LOT_MATERIAL_LINK FLM
                               , FAL_TASK_LINK TAL
                               , FAL_POSITION FPO
                           where FLM.FAL_LOT_MATERIAL_LINK_ID = inFalLotMaterialLink
                             and FLM.FAL_LOT_ID = TAL.FAL_LOT_ID
                             and TAL.FAL_FACTORY_FLOOR_ID = FPO.FAL_FACTORY_FLOOR_ID)
                    )
               )
           );

    return(lnSumWeightInCptByAlloy * inPercent * 0.01);
  exception
    when no_data_found then
      return 0;
  end getSumWeightInCptByAlloy;

  /**
  * Description
  *     Retourne la somme des quantités pesées non nulles en sortie pour le lot,
  *     l'opération ou l'avancement selon le premier ID non null. Alliage, Rebut,
  *     Copeaux et type selon paramètre.
  */
  function getSumPieceQtyOut(
    inFalLotID            in FAL_WEIGH.FAL_LOT_ID%type default null
  , inFalTaskLinkID       in FAL_WEIGH.FAL_SCHEDULE_STEP_ID%type default null
  , inFalLotProgressID    in FAL_WEIGH.FAL_LOT_PROGRESS_ID%type default null
  , inFalLotProgressFogId in FAL_WEIGH.FAL_LOT_PROGRESS_FOG_ID%type default null
  , inGcoAlloyID          in FAL_WEIGH.GCO_ALLOY_ID%type default null
  , inFweWaste            in FAL_WEIGH.FWE_WASTE%type default null
  , inFweTurnings         in FAL_WEIGH.FWE_TURNINGS%type default null
  , inCWeighType          in FAL_WEIGH.C_WEIGH_TYPE%type default null
  , inFweIn               in FAL_WEIGH.FWE_IN%type default null
  )
    return FAL_WEIGH.FWE_PIECE_QTY%type
  as
    lnSumPieceQtyOut FAL_WEIGH.FWE_PIECE_QTY%type;
  begin
    if nvl(inFalLotProgressFogID, 0) <> 0 then
      select nvl(sum(FWE_PIECE_QTY), 0)
        into lnSumPieceQtyOut
        from FAL_WEIGH
       where FAL_LOT_PROGRESS_FOG_ID = inFalLotProgressFogID
         and (   GCO_ALLOY_ID = inGcoAlloyID
              or nvl(inGcoAlloyID, 0) = 0)
         and (   FWE_WASTE = inFweWaste
              or inFweWaste is null)
         and (   FWE_TURNINGS = inFweTurnings
              or inFweTurnings is null)
         and (   C_WEIGH_TYPE = inCWeighType
              or inCWeighType is null)
         and FWE_IN = nvl(inFweIn, 0)
         and FWE_WEIGHT_MAT is not null;   -- Pesée possible pour X pièces sans poids
    elsif nvl(inFalLotProgressID, 0) <> 0 then
      select nvl(sum(FWE_PIECE_QTY), 0)
        into lnSumPieceQtyOut
        from FAL_WEIGH
       where FAL_LOT_PROGRESS_ID = inFalLotProgressID
         and (   GCO_ALLOY_ID = inGcoAlloyID
              or nvl(inGcoAlloyID, 0) = 0)
         and (   FWE_WASTE = inFweWaste
              or inFweWaste is null)
         and (   FWE_TURNINGS = inFweTurnings
              or inFweTurnings is null)
         and (   C_WEIGH_TYPE = inCWeighType
              or inCWeighType is null)
         and FWE_IN = nvl(inFweIn, 0)
         and FWE_WEIGHT_MAT is not null;   -- Pesée possible pour X pièces sans poids
    elsif nvl(inFalTaskLinkID, 0) <> 0 then
      select nvl(sum(FWE_PIECE_QTY), 0)
        into lnSumPieceQtyOut
        from FAL_WEIGH
       where FAL_SCHEDULE_STEP_ID = inFalTaskLinkID
         and (   GCO_ALLOY_ID = inGcoAlloyID
              or nvl(inGcoAlloyID, 0) = 0)
         and (   FWE_WASTE = inFweWaste
              or inFweWaste is null)
         and (   FWE_TURNINGS = inFweTurnings
              or inFweTurnings is null)
         and (   C_WEIGH_TYPE = inCWeighType
              or inCWeighType is null)
         and FWE_IN = nvl(inFweIn, 0)
         and FWE_WEIGHT_MAT is not null;   -- Pesée possible pour X pièces sans poids
    elsif nvl(inFalLotID, 0) <> 0 then
      select nvl(sum(FWE_PIECE_QTY), 0)
        into lnSumPieceQtyOut
        from FAL_WEIGH
       where FAL_LOT_ID = inFalLotID
         and (   GCO_ALLOY_ID = inGcoAlloyID
              or nvl(inGcoAlloyID, 0) = 0)
         and (   FWE_WASTE = inFweWaste
              or inFweWaste is null)
         and (   FWE_TURNINGS = inFweTurnings
              or inFweTurnings is null)
         and (   C_WEIGH_TYPE = inCWeighType
              or inCWeighType is null)
         and FWE_IN = nvl(inFweIn, 0)
         and FWE_WEIGHT_MAT is not null;   -- Pesée possible pour X pièces sans poids
    end if;

    return lnSumPieceQtyOut;
  exception
    when no_data_found then
      return 0;
  end getSumPieceQtyOut;

  /**
  * Description
  *     Retourne la somme des poids matières pesés en sortie de type opération par
  *     opération de lot ou suivi d'avancement. Alliage, Rebut et copeaux selon paramètre.
  */
  function getSumWeightMatOut(
    inFalLotID         in FAL_WEIGH.FAL_LOT_ID%type default null
  , inFalTaskLinkID    in FAL_WEIGH.FAL_SCHEDULE_STEP_ID%type default null
  , inFalLotProgressID in FAL_WEIGH.FAL_LOT_PROGRESS_ID%type default null
  , inGcoAlloyID       in FAL_WEIGH.GCO_ALLOY_ID%type default null
  , inFweWaste         in FAL_WEIGH.FWE_WASTE%type default null
  , inFweTurnings      in FAL_WEIGH.FWE_TURNINGS%type default null
  , inCWeighType       in FAL_WEIGH.C_WEIGH_TYPE%type default null
  , inFweIn            in FAL_WEIGH.FWE_IN%type default null
  )
    return FAL_WEIGH.FWE_WEIGHT_MAT%type
  as
    lnSumWeightMatOut FAL_WEIGH.FWE_WEIGHT_MAT%type;
  begin
    if nvl(inFalLotProgressID, 0) <> 0 then
      select nvl(sum(FWE_WEIGHT_MAT), 0)
        into lnSumWeightMatOut
        from FAL_WEIGH
       where FAL_LOT_PROGRESS_ID = inFalLotProgressID
         and (   GCO_ALLOY_ID = inGcoAlloyID
              or nvl(inGcoAlloyID, 0) = 0)
         and (   FWE_WASTE = inFweWaste
              or inFweWaste is null)
         and (   FWE_TURNINGS = inFweTurnings
              or inFweTurnings is null)
         and (   C_WEIGH_TYPE = inCWeighType
              or inCWeighType is null)
         and FWE_IN = nvl(inFweIn, 0);
    elsif nvl(inFalTaskLinkID, 0) <> 0 then
      select nvl(sum(FWE_WEIGHT_MAT), 0)
        into lnSumWeightMatOut
        from FAL_WEIGH
       where FAL_SCHEDULE_STEP_ID = inFalTaskLinkID
         and (   GCO_ALLOY_ID = inGcoAlloyID
              or nvl(inGcoAlloyID, 0) = 0)
         and (   FWE_WASTE = inFweWaste
              or inFweWaste is null)
         and (   FWE_TURNINGS = inFweTurnings
              or inFweTurnings is null)
         and (   C_WEIGH_TYPE = inCWeighType
              or inCWeighType is null)
         and FWE_IN = nvl(inFweIn, 0);
    elsif nvl(inFalLotID, 0) <> 0 then
      select nvl(sum(FWE_WEIGHT_MAT), 0)
        into lnSumWeightMatOut
        from FAL_WEIGH
       where FAL_LOT_ID = inFalLotID
         and (   GCO_ALLOY_ID = inGcoAlloyID
              or nvl(inGcoAlloyID, 0) = 0)
         and (   FWE_WASTE = inFweWaste
              or inFweWaste is null)
         and (   FWE_TURNINGS = inFweTurnings
              or inFweTurnings is null)
         and (   C_WEIGH_TYPE = inCWeighType
              or inCWeighType is null)
         and FWE_IN = nvl(inFweIn, 0);
    end if;

    return lnSumWeightMatOut;
  exception
    when no_data_found then
      return 0;
  end getSumWeightMatOut;

  /**
  * Description
  *     Retourne la somme des poids pierres pesés en sortie de type opération.
  *     Opération de lot, suivi d'avancement, Rebut et copeaux selon paramètre.
  */
  function getSumWeightStoneOutTypeOper(
    inFalTaskLinkID    in FAL_WEIGH.FAL_SCHEDULE_STEP_ID%type default null
  , inFalLotProgressID in FAL_WEIGH.FAL_LOT_PROGRESS_ID%type default null
  , inFweWaste         in FAL_WEIGH.FWE_WASTE%type default null
  , inFweTurnings      in FAL_WEIGH.FWE_TURNINGS%type default null
  )
    return FAL_WEIGH.FWE_WEIGHT_MAT%type
  as
    lnSumWeightStoneOutTypeOper FAL_WEIGH.FWE_WEIGHT_MAT%type;
  begin
    if inFalLotProgressID is not null then
      select nvl(sum(FWE_WEIGHT), 0) - nvl(sum(FWE_WEIGHT_MAT), 0)
        into lnSumWeightStoneOutTypeOper
        from FAL_WEIGH
       where FAL_LOT_PROGRESS_ID = inFalLotProgressID
         and (   FWE_WASTE = inFweWaste
              or inFweWaste is null)
         and (   FWE_TURNINGS = inFweTurnings
              or inFweTurnings is null)
         and C_WEIGH_TYPE = '2'   -- Pesée opération
         and FWE_IN = 0;
    else
      select nvl(sum(FWE_WEIGHT), 0) - nvl(sum(FWE_WEIGHT_MAT), 0)
        into lnSumWeightStoneOutTypeOper
        from FAL_WEIGH
       where FAL_SCHEDULE_STEP_ID = inFalTaskLinkID
         and (   FWE_WASTE = inFweWaste
              or inFweWaste is null)
         and (   FWE_TURNINGS = inFweTurnings
              or inFweTurnings is null)
         and C_WEIGH_TYPE = '2'   -- Pesée opération
         and FWE_IN = 0;
    end if;

    return lnSumWeightStoneOutTypeOper;
  exception
    when no_data_found then
      return 0;
  end getSumWeightStoneOutTypeOper;

  /**
  * Description
  *   Cette fonction retourne 1 si les pesées matières précieuses sont saisies
  *   pour chaques alliages du produit
  */
  function isWeighNoExist(iLotID in FAL_WEIGH.FAL_POSITION2_ID%type, iGoodID in FAL_WEIGH.GCO_GOOD_ID%type, iQuantity in number)
    return number
  is
    lnCountWeigh   number;
    lnCountReceipt number;
    lnMissingWeigh number(1) := 0;
  begin
    -- Contrôle si les données de pesée matières précieuses sont déjà saisies
    for tplAlloy in (select GPM.GCO_ALLOY_ID
                       from GCO_PRECIOUS_MAT GPM
                      where GPM.GCO_GOOD_ID = iGoodId) loop
      -- Compre le nombre de pesé effectué pour chaques alliages
      select nvl(sum(FWE_PIECE_QTY), 0)
        into lnCountWeigh
        from FAL_WEIGH
       where FAL_LOT_ID = iLotId
         and GCO_ALLOY_ID = tplAlloy.GCO_ALLOY_ID
         and C_WEIGH_TYPE = 4
         and FWE_WEIGHT is not null;

      -- Compte le nombre déjà réceptionné (PF + rebut) et la quantité en cours de réception
      select LOT_RELEASED_QTY + LOT_REJECT_RELEASED_QTY + iQuantity
        into lnCountReceipt
        from FAL_LOT
       where FAL_LOT_ID = iLotId;

      if lnCountWeigh < lnCountReceipt then
        lnMissingWeigh  := 1;
      end if;
    end loop;

    return lnMissingWeigh;
  end isWeighNoExist;

  /**
  * function GetFirstOpPosWithWeighing
  * Description
  *   Recherche la première opération non terminée avec pesée matière précieuse
  *
  * @created eca 05.2012
  * @lastUpdate
  * @public
  * @param iLotID      : Id du lot
  * @return ID poste
  */
  function GetFirstOpPosWithWeighing(iFalLotId in FAL_LOT.FAL_LOT_ID%type)
    return integer
  is
    lnFalTaskId number;
  begin
    select max(POS.FAL_POSITION_ID)
      into lnFalTaskId
      from FAL_LOT LOT
         , FAL_TASK_LINK TAL
         , FAL_POSITION POS
     where LOT.FAL_LOT_ID = iFalLotId
       and LOT.FAL_LOT_ID = TAL.FAL_LOT_ID
       and TAL.FAL_FACTORY_FLOOR_ID = POS.FAL_FACTORY_FLOOR_ID
       and (   TAL.SCS_WEIGH_MANDATORY = 1
            or TAL.SCS_WEIGH = 1)
       and TAL.TAL_DUE_QTY > 0
       and TAL.SCS_STEP_NUMBER =
             (select min(TAL2.SCS_STEP_NUMBER)
                from FAL_LOT LOT2
                   , FAL_TASK_LINK TAL2
               where LOT2.FAL_LOT_ID = iFalLotId
                 and LOT2.FAL_LOT_ID = TAL2.FAL_LOT_ID
                 and (   TAL2.SCS_WEIGH_MANDATORY = 1
                      or TAL2.SCS_WEIGH = 1)
                 and TAL2.TAL_DUE_QTY > 0);

    return lnFalTaskId;
  exception
    when no_data_found then
      return null;
  end GetFirstOpPosWithWeighing;

  /**
  * function GetLastOpPosWithWeighing
  * Description
  *   Recherche la Dernière opération avec pesée matière précieuse
  *
  * @created eca 05.2012
  * @lastUpdate
  * @public
  * @param iLotID      : Id du lot
  * @return ID poste
  */
  function GetLastOpPosWithWeighing(iFalLotId in FAL_LOT.FAL_LOT_ID%type)
    return integer
  is
    lnFalTaskId number;
  begin
    select max(POS.FAL_POSITION_ID)
      into lnFalTaskId
      from FAL_LOT LOT
         , FAL_TASK_LINK TAL
         , FAL_POSITION POS
     where LOT.FAL_LOT_ID = iFalLotId
       and LOT.FAL_LOT_ID = TAL.FAL_LOT_ID
       and TAL.FAL_FACTORY_FLOOR_ID = POS.FAL_FACTORY_FLOOR_ID
       and (   TAL.SCS_WEIGH_MANDATORY = 1
            or TAL.SCS_WEIGH = 1)
       and TAL.SCS_STEP_NUMBER =
                              (select max(TAL2.SCS_STEP_NUMBER)
                                 from FAL_LOT LOT2
                                    , FAL_TASK_LINK TAL2
                                where LOT2.FAL_LOT_ID = iFalLotId
                                  and LOT2.FAL_LOT_ID = TAL2.FAL_LOT_ID
                                  and (   TAL2.SCS_WEIGH_MANDATORY = 1
                                       or TAL2.SCS_WEIGH = 1) );

    return lnFalTaskId;
  exception
    when no_data_found then
      return null;
  end GetLastOpPosWithWeighing;

  /**
  * procedure GetMaterialMvtParameters
  * Description
  *   Recherche Des paramètres de pesée pour un mouvement de matière
  *
  * @created eca 05.2012
  * @lastUpdate vje 28.09.2012
  * @public
  * @param  iDocPositionId        : Position
  * @param  iDicOperator          : Operateur
  * @param  iCWeightype           : Type de la pesée
  * @param  iFalLotMaterialLinkID : Composant (cas de pesées de mouvements de composants)
  * @return ioDocDocumentId       : Document
  * @return ioEntryPosition       : Poste entrant
  * @return ioExitPosition        : Poste sortant
  */
  procedure GetMaterialMvtParameters(
    iDocPositionId        in     number
  , iDicOperator          in     varchar2
  , iCWeightype           in     varchar2
  , iFalLotMaterialLinkID in     number
  , ioDocDocumentId       in out number
  , ioEntryPosition       in out number
  , ioExitPosition        in out number
  )
  is
    lvGoodMvtSort        varchar2(10);
    lnGoodTr             number;
    lvClotType           varchar2(10);
    lnbatchStockDest     number;
    lnbatchStockConso    number;
    lnBatchLocationConso number;
    lndocThird           number;
    lnAdminDomain        varchar2(10);
    lnIndivEntryPosition number;
    lnIndivExitPosition  number;
    lnPosStockId         number;
    lnPosStockTrId       number;
  begin
    ioEntryPosition       := null;
    ioExitPosition        := null;
    lnIndivEntryPosition  := null;
    lnIndivExitPosition   := null;

    -- Récupération Informations du document de la position
    begin
      select POS.DOC_DOCUMENT_ID
           , MOK.C_MOVEMENT_SORT
           , MOK.STM_STM_MOVEMENT_KIND_ID
           , GPO.C_DOC_LOT_TYPE
           , LOT.STM_STOCK_ID
           , DOC.PAC_THIRD_ID
           , GAU.C_ADMIN_DOMAIN
           , POS.STM_STOCK_ID
           , POS.STM_STM_STOCK_ID
        into ioDocDocumentId
           , lvGoodMvtSort
           , lnGoodTr
           , lvClotType
           , lnbatchStockDest
           , lndocThird
           , lnAdminDomain
           , lnPosStockId
           , lnPosStockTrId
        from DOC_DOCUMENT DOC
           , DOC_POSITION POS
           , DOC_GAUGE GAU
           , DOC_GAUGE_POSITION GPO
           , STM_MOVEMENT_KIND MOK
           , FAL_LOT LOT
       where POS.DOC_POSITION_ID = iDocPositionid
         and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
         and POS.DOC_GAUGE_POSITION_ID = GPO.DOC_GAUGE_POSITION_ID
         and DOC.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and GPO.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID(+)
         and POS.FAL_LOT_ID = LOT.FAL_LOT_ID(+);
    exception
      when no_data_found then
        begin
          ioDocDocumentId  := null;
          ioEntryPosition  := null;
          ioExitPosition   := null;
          return;
        end;
    end;

    -- Initialisation du poste entrant via configuration
    lnIndivEntryPosition  :=
      GetIndivPositionByConfig(iCfgName                => 'FAL_WEIGH_INIT_ENTRY_POSITION'
                             , iDOC_DOCUMENT_ID        => ioDocDocumentId
                             , iDOC_POSITION_ID        => iDocPositionId
                             , iFWE_DIC_OPERATOR_ID    => iDicOperator
                             , iCWeightype             => iCWeightype
                             , iFalLotMaterialLinkID   => iFalLotMaterialLinkID
                              );
    -- Initialisation du poste sortant via configuration
    lnIndivExitPosition   :=
      GetIndivPositionByConfig(iCfgName                => 'FAL_WEIGH_INIT_EXIT_POSITION'
                             , iDOC_DOCUMENT_ID        => ioDocDocumentId
                             , iDOC_POSITION_ID        => iDocPositionId
                             , iFWE_DIC_OPERATOR_ID    => iDicOperator
                             , iCWeightype             => iCWeightype
                             , iFalLotMaterialLinkID   => iFalLotMaterialLinkID
                              );

    -- Exécution standard
    if    lnIndivEntryPosition is null
       or lnIndivExitPosition is null then
      -- Si Lot de sous-traitance :
      if lvClotType = '001' then
        -- Recherche du stock sous-traitant
        STM_LIB_STOCK.getSubCStockAndLocation(lnDocThird, lnBatchStockConso, lnBatchLocationConso);

        -- Mouvement d'entrée
        if lvGoodMvtSort = 'ENT' then
          ioEntryPosition  := FAL_I_LIB_POSITION.getPositionIDByStockID(lnbatchStockDest);
          ioExitPosition   := FAL_I_LIB_POSITION.getPositionIDByStockID(lnbatchStockConso);
        -- Mouvement de sortie
        elsif lvGoodMvtSort = 'SOR' then
          ioEntryPosition  := FAL_I_LIB_POSITION.getPositionIDByStockID(lnbatchStockConso);
          ioExitPosition   := FAL_I_LIB_POSITION.getPositionIDByStockID(lnbatchStockDest);
        end if;
      -- Sinon
      else
        -- Si mouvement de transfert
        if lnGoodTr <> 0 then
          ioEntryPosition  := FAL_I_LIB_POSITION.getPositionIDByStockID(lnPosStockTrId);
          ioExitPosition   := FAL_I_LIB_POSITION.getPositionIDByStockID(lnPosStockId);
        -- Si mouvement d'entrée
        elsif lvGoodMvtSort = 'ENT' then
          ioEntryPosition  := FAL_I_LIB_POSITION.getPositionIDByStockID(lnPosStockId);
        -- Si mouvement de sortie
        elsif lvGoodMvtSort = 'SOR' then
          ioExitPosition  := FAL_I_LIB_POSITION.getPositionIDByStockID(lnPosStockId);
        -- Pas de mouvement -> fonction du domaine
        else
          -- Domaine achat
          if lnAdminDomain = 1 then
            ioEntryPosition  := FAL_I_LIB_POSITION.getPositionIDByStockID(lnPosStockId);
          -- Domaine vente
          elsif lnAdminDomain = 2 then
            ioExitPosition  := FAL_I_LIB_POSITION.getPositionIDByStockID(lnPosStockId);
          -- Stock
          elsif lnAdminDomain = 3 then
            ioEntryPosition  := FAL_I_LIB_POSITION.getPositionIDByStockID(lnPosStockTrId);
            ioExitPosition   := FAL_I_LIB_POSITION.getPositionIDByStockID(lnPosStockId);
          end if;
        end if;
      end if;
    end if;

    ioEntryPosition       := nvl(lnIndivEntryPosition, ioEntryPosition);
    ioExitPosition        := nvl(lnIndivExitPosition, ioExitPosition);
  end GetMaterialMvtParameters;

  /**
  * function GetIndivPositionByConfig
  * Description
  *   Récupération post entrants et sortants par configuration
  *
  * @created eca 05.2012
  * @lastUpdate vje 28.09.2012
  * @public
  * @param   iCfgName : nom de la configuration utilisée
  * @param   iFAL_LOT_ID : lot
  * @param   iFAL_SCHEDULE_STEP_ID : opération
  * @param   iFAL_LOT_PROGRESS_ID : suivi d'avancement
  * @param   iDOC_DOCUMENT_ID : document
  * @param   iDOC_POSITION_ID : position
  * @param   iFWE_DIC_OPERATOR_ID : opérateur
  * @param   iCWeightype           : Type de la pesée
  * @param   iFalLotMaterialLinkID : Composant (cas de pesées de mouvements de composants)
  * @return ID de poste de pesée
  */
  function GetIndivPositionByConfig(
    iCfgName              in varchar2
  , iFAL_LOT_ID           in number default null
  , iFAL_SCHEDULE_STEP_ID in number default null
  , iFAL_LOT_PROGRESS_ID  in number default null
  , iDOC_DOCUMENT_ID      in number default null
  , iDOC_POSITION_ID      in number default null
  , iFWE_DIC_OPERATOR_ID  in varchar2 default null
  , iCWeightype           in varchar2 default null
  , iFalLotMaterialLinkID in number default null
  )
    return number
  is
    lvCfgValue       varchar2(2000);
    lvQuery          varchar2(4000);
    lnResultPosition number;
  begin
    -- Récupération du Nom de la proc stockée
    lvCfgValue        := trim(PCS.PC_CONFIG.getConfig(iCfgName) );
    lnResultPosition  := null;

    if     lvCfgValue is not null
       and upper(lvCfgValue) <> 'NULL' then
      lvQuery  :=
        ' begin ' ||
        lvCfgValue ||
        '(:aFAL_LOT_ID ' ||
        ' ,:aFAL_SCHEDULE_STEP_ID ' ||
        ' ,:aFAL_LOT_PROGRESS_ID ' ||
        ' ,:aDOC_DOCUMENT_ID ' ||
        ' ,:aDOC_POSITION_ID ' ||
        ' ,:aFWE_DIC_OPERATOR_ID ' ||
        ' ,:aC_WEIGH_TYPE ' ||
        ' ,:aFAL_LOT_MATERIAL_LINK_ID ' ||
        ' ,:aResultPosition); ' ||
        'end;';

      execute immediate lvQuery
                  using in     iFAL_LOT_ID
                      , in     iFAL_SCHEDULE_STEP_ID
                      , in     iFAL_LOT_PROGRESS_ID
                      , in     iDOC_DOCUMENT_ID
                      , in     iDOC_POSITION_ID
                      , in     iFWE_DIC_OPERATOR_ID
                      , in     iCWeightype
                      , in     iFalLotMaterialLinkID
                      , in out lnResultPosition;

      -- Si le résultat est <> null, on vérifie qu'il s'agit bien d'un poste MP
      if nvl(lnResultPosition, 0) <> 0 then
        begin
          select FAL_POSITION_ID
            into lnResultPosition
            from FAL_POSITION
           where FAL_POSITION_ID = lnResultPosition;
        exception
          when no_data_found then
            lnResultPosition  := null;
        end;
      end if;
    end if;

    return lnResultPosition;
  end GetIndivPositionByConfig;

  /**
  * function IsPositionWithMvtOnSSTStock
  * Description
  *   Teste si la position effectue un mouvement du type donné, vers ou depuis
  *   un stock sous-traitant
  *
  * @created eca 05.2012
  * @lastUpdate
  * @public
  * @param   iDocPositionId : Position
  * @param   iCMovementSort : Genre de mouvements
  * @return ID 1/0
  */
  function IsPositionWithMvtOnSSTStock(iDocPositionId in number, iCMovementSort in varchar2)
    return integer
  is
    lcPrincipMvtsort            varchar2(10);
    liPrincStockIsSST           integer;
    liSecondStockIsSST          integer;
    IsPositionWithMvtOnSSTStock integer;
  begin
    IsPositionWithMvtOnSSTStock  := 0;

    select MOK.C_MOVEMENT_SORT
         , STO1.STO_SUBCONTRACT STO1_SUBC
         , STO2.STO_SUBCONTRACT STO2_SUBC
      into lcPrincipMvtsort
         , liPrincStockIsSST
         , liSecondStockIsSST
      from DOC_POSITION POS
         , STM_MOVEMENT_KIND MOK
         , STM_STOCK STO1
         , STM_STOCK STO2
     where POS.DOC_POSITION_ID = iDocPositionId
       and POS.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID
       and POS.STM_STOCK_ID = STO1.STM_STOCK_ID
       and POS.STM_STM_STOCK_ID = STO2.STM_STOCK_ID(+);

    -- Recherche de mouvements d'entrée sur le stock sous-traitant
    if    (    iCMovementSort = 'ENT'
           and (    (    lcPrincipMvtsort = 'ENT'
                     and liPrincStockIsSST = 1)
                or (    lcPrincipMvtsort = 'SOR'
                    and liSecondStockIsSST = 1) ) )
       or (    iCMovementSort = 'SOR'
           and (    (    lcPrincipMvtsort = 'SOR'
                     and liPrincStockIsSST = 1)
                or (    lcPrincipMvtsort = 'ENT'
                    and liSecondStockIsSST = 1) ) ) then
      IsPositionWithMvtOnSSTStock  := 1;
    end if;

    return IsPositionWithMvtOnSSTStock;
  exception
    when no_data_found then
      return 0;
  end IsPositionWithMvtOnSSTStock;
end FAL_LIB_WEIGH;
