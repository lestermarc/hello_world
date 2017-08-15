--------------------------------------------------------
--  DDL for Package Body FAL_LIB_BATCH
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_BATCH" 
is
  lcCoupledGood constant varchar2(255) := PCS.PC_CONFIG.GetConfig('FAL_COUPLED_GOOD');

  /**
  * Description
  *    get the order of a lot
  */
  function getOrderId(iLotId in FAL_LOT.FAL_LOT_ID%type)
    return FAL_ORDER.FAL_ORDER_ID%type
  as
  begin
    return FWK_I_LIB_ENTITY.getNumberFieldFromPk(iv_entity_name => 'FAL_LOT', iv_column_name => 'FAL_ORDER_ID', it_pk_value => iLotId);
  end getOrderId;

  /**
  * Description
  *    get the job program of a lot
  */
  function getJobProgramId(iLotId in FAL_LOT.FAL_LOT_ID%type)
    return FAL_ORDER.FAL_ORDER_ID%type
  is
    lResult FAL_ORDER.FAL_ORDER_ID%type;
  begin
    select ODR.FAL_JOB_PROGRAM_ID
      into lResult
      from FAL_LOT LOT
         , FAL_ORDER ODR
     where LOT.FAL_LOT_ID = iLotId
       and ODR.FAL_ORDER_ID = LOT.FAL_ORDER_ID;

    return lResult;
  end getJobProgramId;

  /**
  * Description
  *   return true if couple exists
  */
  function ExistsDetails(iLotId in FAL_LOT.FAL_LOT_ID%type)
    return boolean
  is
    lCount pls_integer;
  begin
    select count(*)
      into lCount
      from FAL_LOT_DETAIL
     where FAL_LOT_ID = iLotId;

    return(lCount > 0);
  end ExistsDetails;

  /**
  * function GetBatchTuple
  * Description
  *   Return tuple of FAL_LOT for requested batch
  * @created fp 19.01.2011
  * @lastUpdate
  * @public
  * @param iLotId
  * @return see description
  */
  function GetBatchTuple(iLotId in FAL_LOT.FAL_LOT_ID%type)
    return FAL_LOT%rowtype
  is
    lResult FAL_LOT%rowtype;
  begin
    select *
      into lResult
      from FAL_LOT
     where FAL_LOT_ID = iLotId;

    return lResult;
  exception
    when no_data_found then
      return null;
  end GetBatchTuple;

  /**
  * Description
  *   return le status du lot
  */
  function getBatchStatus(iLotId in FAL_LOT.FAL_LOT_ID%type)
    return FAL_LOT.C_LOT_STATUS%type
  is
  begin
    return FWK_I_LIB_ENTITY.getVarchar2FieldFromPk(iv_entity_name => 'FAL_LOT', iv_column_name => 'C_LOT_STATUS', it_pk_value => iLotId);
  end;

  /**
  * Description
  *   return 1 if the status of the job is "Planified"
  */
  function IsBatchPlanified(iLotId in FAL_LOT.FAL_LOT_ID%type)
    return boolean
  is
  begin
    return GetBatchTuple(iLotId).C_LOT_STATUS = cLotStatusPlanified;
  end IsBatchPlanified;

  function IsBatchPlanified_Autonomus(iLotId in FAL_LOT.FAL_LOT_ID%type)
    return boolean
  is
    pragma autonomous_transaction;
  begin
    return GetBatchTuple(iLotId).C_LOT_STATUS = cLotStatusPlanified;
  end IsBatchPlanified_Autonomus;

  /**
  * Description
  *   return 1 if the status of the job is "Planified"
  */
  function IsBatchLaunched(iLotId in FAL_LOT.FAL_LOT_ID%type)
    return boolean
  is
  begin
    return GetBatchTuple(iLotId).C_LOT_STATUS = cLotStatusLaunched;
  end IsBatchLaunched;

  /**
  * Description
  *    Retourne l'ID du lot en fonction de la référence complète du lot
  */
  function getLotID(iLotRefCompl in FAL_LOT.LOT_REFCOMPL%type)
    return FAL_LOT.FAL_LOT_ID%type
  as
  begin
    return getLotIDByRefCompl(ivLotRefcompl => iLotRefCompl);
  end getLotID;

  /**
  * Description
  *    Retourne l'ID du produit terminé du lot de fabrication
  */
  function getGcoGoodID(inFalLotID in FAL_LOT.FAL_LOT_ID%type)
    return FAL_LOT.GCO_GOOD_ID%type
  as
  begin
    return FWK_I_LIB_ENTITY.getNumberFieldFromPk(iv_entity_name => 'FAL_LOT', iv_column_name => 'GCO_GOOD_ID', it_pk_value => inFalLotID);
  end getGcoGoodID;

  /**
  * Description
  *    Cette function retourne l'ID de la dernière opération du lot de fabrication
  *    transmis en paramètre
  */
  function getLastTaskLink(inFalLotID in FAL_LOT.FAL_LOT_ID%type)
    return FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  as
    lnFalTaskID FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type;
  begin
    select FAL_SCHEDULE_STEP_ID
      into lnFalTaskID
      from FAL_TASK_LINK
     where FAL_LOT_ID = inFalLotID
       and SCS_STEP_NUMBER = (select max(SCS_STEP_NUMBER)
                                from FAL_TASK_LINK
                               where FAL_LOT_ID = inFalLotID);

    return lnFalTaskID;
  exception
    when no_data_found then
      return null;
  end getLastTaskLink;

  /**
  * Description
  *    Retourne l'ID du lot de fabrication en fonction se sa référence complémentaire
  */
  function getLotIDByRefCompl(ivLotRefcompl in FAL_LOT.LOT_REFCOMPL%type)
    return FAL_LOT.FAL_LOT_ID%type
  as
    lnFalLotID FAL_LOT.FAL_LOT_ID%type;
  begin
    select FAL_LOT_ID
      into lnFalLotID
      from FAL_LOT
     where upper(LOT_REFCOMPL) = upper(ivLotRefcompl);

    return lnFalLotID;
  exception
    when no_data_found then
      return null;
  end getLotIDByRefCompl;

  /**
  * Description
  *    Cette function le poids réceptionné pour le lot de fabrication transmis en
  *    paramètre
  */
  function getReleasedWeight(inFalLotID in FAL_LOT.FAL_LOT_ID%type)
    return FAL_WEIGH.FWE_WEIGHT_MAT%type
  as
    lnReleasedWeight FAL_WEIGH.FWE_WEIGHT_MAT%type;
  begin
    if GCO_I_LIB_PRECIOUS_MAT.doesManagePreciousMat(inGcoGoodID => getGcoGoodID(inFalLotID => inFalLotID) ) = 1 then
      if BatchWithReceptWeighing(iLotID => inFalLotID) = 1 then
        /* Somme des pesées de sortie du lot de type "Réception lot fabrication" (4) et code rebut = 0 */
        lnReleasedWeight  := FAL_LIB_WEIGH.getSumWeightMatOut(inFalLotID => inFalLotID, inFweWaste => 0, inCWeighType => 4, inFweIn => 1);
      else
        /* Somme des pesées de sortie de type "Pesée opération" (2) de la dernière opération du lot et code rebut = 0 */
        lnReleasedWeight  := FAL_LIB_WEIGH.getSumWeightMatOut(inFalTaskLinkID   => getLastTaskLink(inFalLotID => inFalLotID), inFweWaste => 0
                                                            , inCWeighType      => 2);
      end if;

      return lnReleasedWeight;
    else
      return 0;
    end if;
  end getReleasedWeight;

  /**
  * Description
  *    Cette function le poids rebut réceptionné pour le lot de fabrication
  *    transmis en paramètre
  */
  function getWasteReleasedWeight(inFalLotID in FAL_LOT.FAL_LOT_ID%type)
    return FAL_WEIGH.FWE_WEIGHT_MAT%type
  as
    lnWasteReleasedWeight FAL_WEIGH.FWE_WEIGHT_MAT%type;
  begin
    if GCO_I_LIB_PRECIOUS_MAT.doesManagePreciousMat(inGcoGoodID => getGcoGoodID(inFalLotID => inFalLotID) ) = 1 then
      if BatchWithReceptWeighing(iLotID => inFalLotID) = 1 then
        /* Somme des pesées de sortie de type "Réception lot fabrication" et code rebut = 1 */
        lnWasteReleasedWeight  := FAL_LIB_WEIGH.getSumWeightMatOut(inFalLotID => inFalLotID, inFweWaste => 1, inCWeighType => 4);
      else
        /* Somme des pesées de sortie de type "Pesée opération" de la dernière opération du lot et code rebut = 1 */
        lnWasteReleasedWeight  :=
                             FAL_LIB_WEIGH.getSumWeightMatOut(inFalTaskLinkID   => getLastTaskLink(inFalLotID => inFalLotID), inFweWaste => 1
                                                            , inCWeighType      => 2);
      end if;

      return lnWasteReleasedWeight;
    else
      return 0;
    end if;
  end getWasteReleasedWeight;

  /**
  * function getTurningsWeight
  * Description
  *    Cette function le poids de copeaux pour un lot de fabrication
  * @created age 30.03.2012
  * @lastUpdate
  * @public
  * @param inFalLotID : Lot de fabrication
  * @return : Poids rebut réceptionné
  */
  function getTurningsWeight(inFalLotID in FAL_LOT.FAL_LOT_ID%type)
    return FAL_WEIGH.FWE_WEIGHT_MAT%type
  is
    lnTurningsWeight number;
  begin
    select FAL_I_LIB_WEIGH.getSumWeightMatOut(inFalLotID           => FAL_LOT_ID
                                            , inFalTaskLinkID      => null
                                            , inFalLotProgressID   => null
                                            , inGcoAlloyID         => null
                                            , inFweWaste           => 0
                                            , inFweTurnings        => 1
                                            , inCWeighType         => null
                                            , inFweIn              => 0
                                             )
      into lnTurningsWeight
      from FAL_LOT
     where FAL_LOT_ID = inFalLotId;

    return lnTurningsWeight;
  exception
    when no_data_found then
      return 0;
  end getTurningsWeight;

  /**
  * Description
  *    Cette function le poids réceptionnable pour le lot de fabrication
  *    transmis en paramètre
  */
  function getReleasableWeight(inFalLotID in FAL_LOT.FAL_LOT_ID%type)
    return FAL_WEIGH.FWE_WEIGHT_MAT%type
  as
    lnReleasableWeight FAL_WEIGH.FWE_WEIGHT_MAT%type;
  begin
    if GCO_I_LIB_PRECIOUS_MAT.doesManagePreciousMat(inGcoGoodID => getGcoGoodID(inFalLotID => inFalLotID) ) = 1 then
      lnReleasableWeight  :=
        FAL_LIB_WEIGH.getSumWeightFacFloorInByLot(inFalLotID => inFalLotID)   /* Matière en entrée du lot */
                                                                           -
        FAL_LIB_WEIGH.getSumWeightFacFloorOutByLot(inFalLotID => inFalLotID)   /* Matière en sortie du lot autre que réception */
                                                                            -
        getReleasedWeight(inFalLotID => inFalLotID)   /* Matière réceptionnée */
                                                   -
        getWasteReleasedWeight(inFalLotID => inFalLotID)   /* Matière réceptionnée rebut */
                                                        -
        getTurningsWeight(inFalLotID => inFalLotID);   /* Matière Sortie copeaux */
      return lnReleasableWeight;
    else
      return 0;
    end if;
  end getReleasableWeight;

  /**
  * Description
  *    Retourne 1 si le produit terminé du lot de fabrication transmis en paramètre
  *    contient au moins un alliage de type pierre.
  */
  function doesFPContainsStoneAlloy(inFalLotID in FAL_LOT.FAL_LOT_ID%type)
    return number
  as
  begin
    return GCO_LIB_PRECIOUS_MAT.doesContainsStoneAlloy(inGcoGoodID => getGcoGoodID(inFalLotID => inFalLotID) );
  end doesFPContainsStoneAlloy;

  /**
  * Description
  *    Retourne 1 si le produit terminé du lot de fabrication transmis en paramètre
  *    contient au moins un alliage avec pesée réelle.
  */
  function doesFPContainsRealWeighedAlloy(inFalLotID in FAL_LOT.FAL_LOT_ID%type)
    return number
  as
  begin
    return GCO_LIB_PRECIOUS_MAT.doesContainsRealWeighedAlloy(inGcoGoodID => getGcoGoodID(inFalLotID => inFalLotID) );
  end doesFPContainsRealWeighedAlloy;

  /**
  * Description
  *    Retourne 1 si le produit terminé du lot de fabrication transmis en paramètre
  *    gère de la matière précieuses.
  */
  function doesFPManagePreciousMat(inFalLotID in FAL_LOT.FAL_LOT_ID%type)
    return number
  as
  begin
    return GCO_LIB_PRECIOUS_MAT.doesManagePreciousMat(inGcoGoodID => getGcoGoodID(inFalLotID => inFalLotID) );
  end;

  /**
  * Description
  *    Retourne 1 si une pesée doit être faite pour le lot transmis en paramètre
  */
  function isWeighingNeeded(iLotID in FAL_WEIGH.FAL_LOT_ID%type, iQuantity in number)
    return number
  is
    lnQtyWeighed   FAL_WEIGH.FWE_PIECE_QTY%type;
    lnCountReceipt number;
  begin
    /* Pour chaque alliage du produit fabriqué, contrôle que les pesées soient faites. */
    for ltplAlloyToWeigh in GCO_I_LIB_PRECIOUS_MAT.gcurGoodAlloysToWeigh(inGcoGoodID => getGcoGoodID(inFalLotID => iLotID) ) loop
      /* Somme des pièces pesées pour l'alliage courant */
      lnQtyWeighed  :=
        FAL_LIB_WEIGH.getSumPieceQtyOut(inFalLotID      => iLotId
                                      , inGcoAlloyID    => ltplAlloyToWeigh.GCO_ALLOY_ID
                                      , inFweTurnings   => 0
                                      , inCWeighType    => 4
                                      , inFweIn         => 1
                                       );

      /* Compte la quantité déjà réceptionnée (PF + rebut) et la quantité en cours de réception */
      select LOT_RELEASED_QTY + LOT_REJECT_RELEASED_QTY + iQuantity
        into lnCountReceipt
        from FAL_LOT
       where FAL_LOT_ID = iLotId;

      /* Si la somme des pièces pesées pour l'alliage courant est insuffisante */
      if lnQtyWeighed < lnCountReceipt then
        return 1;
      end if;
    end loop;

    return 0;
  end isWeighingNeeded;

  /**
   * Description
   *    Est-ce que le produit fini possède une caractéristique numéro de pièce ?
   */
  function isPieceChar(iLotID in FAL_LOT.FAL_LOT_ID%type)
    return number
  as
  begin
    return GCO_I_LIB_CHARACTERIZATION.IsPieceChar(iGoodID => getGcoGoodID(inFalLotID => iLotID) );
  end isPieceChar;

  /**
   * Description
   *    Est-ce que le produit fini contient au moins un composant avec une
   *    caractéristique numéro de pièce ?
   */
  function hasFPCptPieceChar(iLotID in FAL_LOT.FAL_LOT_ID%type)
    return number
  as
  begin
    for ltplCptGoodID in (select GCO_GOOD_ID
                            from FAL_LOT_MATERIAL_LINK
                           where FAL_LOT_ID = iLotID
                             and C_KIND_COM = 1) loop
      if GCO_I_LIB_CHARACTERIZATION.IsPieceChar(iGoodID => ltplCptGoodID.GCO_GOOD_ID) = 1 then
        return 1;
      end if;
    end loop;

    return 0;
  end hasFPCptPieceChar;

   /**
  * Description
  *   Est-ce que le produit fini possède une caractéristique de type lot ?
  *   (Est-il géré par lot ?)
  */
  function isLotChar(iLotID in FAL_LOT.FAL_LOT_ID%type)
    return number
  is
  begin
    return GCO_I_LIB_CHARACTERIZATION.IsLotChar(iGoodID => getGcoGoodID(inFalLotID => iLotID) );
  end isLotChar;

  /**
  * Description
  *    Est-ce que le produit fini contient au moins un composant avec une
  *    caractéristique lot ?
  */
  function hasFPCptLotChar(iLotID in FAL_LOT.FAL_LOT_ID%type)
    return number
  is
  begin
    for ltplCptGoodID in (select GCO_GOOD_ID
                            from FAL_LOT_MATERIAL_LINK
                           where FAL_LOT_ID = iLotID
                             and C_KIND_COM = 1) loop
      if GCO_I_LIB_CHARACTERIZATION.IsLotChar(iGoodID => ltplCptGoodID.GCO_GOOD_ID) = 1 then
        return 1;
      end if;
    end loop;

    return 0;
  end hasFPCptLotChar;

  /**
   * Description
   *   Est-ce que le produit fini possède une caractéristique de type Version ?
   *   (Est-il géré par version ?)
   */
  function isVersionChar(iLotID in FAL_LOT.FAL_LOT_ID%type)
    return number
  is
  begin
    return GCO_I_LIB_CHARACTERIZATION.IsVersionChar(iGoodID => getGcoGoodID(inFalLotID => iLotID) );
  end isVersionChar;

  /**
  * Description
  *    Est-ce que le produit fini contient au moins un composant avec une
  *    caractéristique Version ?
  */
  function hasFPCptVersionChar(iLotID in FAL_LOT.FAL_LOT_ID%type)
    return number
  is
  begin
    for ltplCptGoodID in (select GCO_GOOD_ID
                            from FAL_LOT_MATERIAL_LINK
                           where FAL_LOT_ID = iLotID
                             and C_KIND_COM = 1) loop
      if GCO_I_LIB_CHARACTERIZATION.IsVersionChar(iGoodID => ltplCptGoodID.GCO_GOOD_ID) = 1 then
        return 1;
      end if;
    end loop;

    return 0;
  end hasFPCptVersionChar;

     /**
  * function isChronoChar
  * Description
  *   Est-ce que le produit fini possède une caractéristique de type Chronology ?
  *   (Est-il géré en numéro de série ?)
  * @created aga 21.10.2013
  * @lastUpdate
  * @public
  * @param iLotID : ID du lot de fabrication
  * @return : 1 si le produit fini est géré en Chronology
  */
  function isChronoChar(iLotID in FAL_LOT.FAL_LOT_ID%type)
    return number
  is
  begin
    return GCO_I_LIB_CHARACTERIZATION.IsChronoChar(iGoodID => getGcoGoodID(inFalLotID => iLotID) );
  end isChronoChar;

  /**
  * function hasFPCptChronoChar
  * Description
  *    Est-ce que le produit fini contient au moins un composant avec une
  *    caractéristique Chronology ?
  * @created aga 21.10.2013
  * @lastUpdate
  * @public
  * @param iLotID : ID du lot de fabrication
  * @return : 1 si le produit fini contient au moins un composant géré en Chronology
  */
  function hasFPCptChronoChar(iLotID in FAL_LOT.FAL_LOT_ID%type)
    return number
  is
  begin
    for ltplCptGoodID in (select GCO_GOOD_ID
                            from FAL_LOT_MATERIAL_LINK
                           where FAL_LOT_ID = iLotID
                             and C_KIND_COM = 1) loop
      if GCO_I_LIB_CHARACTERIZATION.IsChronoChar(iGoodID => ltplCptGoodID.GCO_GOOD_ID) = 1 then
        return 1;
      end if;
    end loop;

    return 0;
  end hasFPCptChronoChar;

  /**
   * function BatchWithReceptWeighing
   * Description
   *    Retourne 1 si le lot est géré avec pesée de matières précieuse en réception
   */
  function BatchWithReceptWeighing(iLotID in FAL_WEIGH.FAL_LOT_ID%type)
    return integer
  is
    liReceptWeighing integer;
  begin
    select GCO_I_LIB_CDA_MANUFACTURE.isProductAskWeigh(iGoodId => GCO_GOOD_ID, iDicFabConditionId => DIC_FAB_CONDITION_ID)
      into liReceptWeighing
      from FAL_LOT
     where FAL_LOT_ID = iLotID;

    return liReceptWeighing;
  exception
    when others then
      return 0;
  end BatchWithReceptWeighing;

  /**
   * Description
   *    Retourne le type de fabrication (C_FAB_TYPE) du lot ou de la proposition de lot selon son ID
   */
  function getCFabType(iLotID in FAL_LOT.FAL_LOT_ID%type default null, iLotPropID in FAL_LOT_PROP.FAL_LOT_PROP_ID%type default null)
    return FAL_LOT.C_FAB_TYPE%type
  as
  begin
    if iLotID is not null then
      return nvl(FWK_I_LIB_ENTITY.getVarchar2FieldFromPk(iv_entity_name => 'FAL_LOT', iv_column_name => 'C_FAB_TYPE', it_pk_value => iLotID), 0);
    else
      return nvl(FWK_I_LIB_ENTITY.getVarchar2FieldFromPk(iv_entity_name => 'FAL_LOT_PROP', iv_column_name => 'C_FAB_TYPE', it_pk_value => iLotPropID), 0);
    end if;
  end getCFabType;

  /**
  * Description : Récupération de la référence complète du lot de fabrication
  */
  function GetLOT_REFCOMPL(iLotID FAL_LOT.FAL_LOT_ID%type)
    return FAL_LOT.LOT_REFCOMPL%type
  is
  begin
    return FWK_I_LIB_ENTITY.getVarchar2FieldFromPk(iv_entity_name => 'FAL_LOT', iv_column_name => 'LOT_REFCOMPL', it_pk_value => iLotID);
  end GetLOT_REFCOMPL;

  /**
  * Description
  *    Retourne la Qté réceptionée du lot de fabrication
  */
  function getReleasedQty(iLotID FAL_LOT.FAL_LOT_ID%type)
    return FAL_LOT.LOT_RELEASED_QTY%type
  is
  begin
    return nvl(FWK_I_LIB_ENTITY.getNumberFieldFromPk(iv_entity_name => 'FAL_LOT', iv_column_name => 'LOT_RELEASED_QTY', it_pk_value => iLotID), 0);
  end getReleasedQty;

  /**
  * Description
  *    Retourne 1 si le lot comprend au moins 1 tâche externe (C_TASK_TYPE = 2)
  */
  function hasExternalTask(iLotID in FAL_LOT.FAL_LOT_ID%type)
    return number
  as
    lHasExternalTask number;
  begin
    select sign(count(FAL_SCHEDULE_STEP_ID) )
      into lHasExternalTask
      from FAL_TASK_LINK tal
     where C_TASK_TYPE = '2'
       and FAL_LOT_ID = iLotID;

    return lHasExternalTask;
  exception
    when no_data_found then
      return 0;
  end hasExternalTask;

  /**
  * Description
  *    Retourne 1 si le lot comprend au moins 1 Composant lié à une tâche externe (C_TASK_TYPE = 2)
  */
  function hasCptLinkedExternalTask(iLotID in FAL_LOT.FAL_LOT_ID%type)
    return number
  as
    lHasCptLinkedExternalTask number;
  begin
    select sign(count(lom.LOM_TASK_SEQ) )
      into lHasCptLinkedExternalTask
      from FAL_LOT_MATERIAL_LINK lom
         , FAL_TASK_LINK tal
     where lom.LOM_TASK_SEQ = tal.SCS_STEP_NUMBER
       and lom.FAL_LOT_ID = tal.FAL_LOT_ID
       and tal.C_TASK_TYPE = '2'
       and lom.FAL_LOT_ID = iLotID;

    return lHasCptLinkedExternalTask;
  exception
    when no_data_found then
      return 0;
  end hasCptLinkedExternalTask;

  /**
  * Description
  *    Retourne 1 si le lot contient au moins une opération externe dont la/les CST liée(s) à/ont des positions
  *    de type bien (C_DOC_GAUGE_POS = '1') liées au opérations externes du lot non liquidées (C_DOC_POS_STATUS <> '04').
  */
  function hasUnbalancedCstPos(iLotID in FAL_LOT.FAL_LOT_ID%type)
    return number
  as
    lExists number;
  begin
    select count(*)
      into lExists
      from dual
     where exists(select column_value
                    from table(getUnbalancedCstPosIDs(iLotID => iLotID) ) );

    return lExists;
  end hasUnbalancedCstPos;

  /**
  * Description
  *    Retourne la liste des ID des positions de CST et de ses descendants de type bien liées au opérations externes du lot non liquidées ou annulées.
  *    jusqu'à la position provoquant les mouvements (y.c.).
  */
  function getUnbalancedCstPosIDs(iLotID in FAL_LOT.FAL_LOT_ID%type)
    return ID_TABLE_TYPE pipelined deterministic
  as
  begin
    /* Pour chaque position de CST non liquidée de chaque opération externe du lot */
    for ltplCstPosIDs in (select distinct pos.DOC_POSITION_ID
                                     from table(FAL_LIB_SUBCONTRACTO.getExternalTaskIDs(iLotID => iLotID) ) extTask
                                        , table(FAL_I_LIB_TASK_LINK.getLinkedCSTDocsIDs(iExtTaskLinkID     => extTask.column_value
                                                                                      , iIncludeChild      => 1
                                                                                      , iUntilMvtDoneSTO   => 1
                                                                                       )
                                               ) cst
                                        , DOC_POSITION pos
                                    where pos.DOC_DOCUMENT_ID = cst.column_value
                                      and pos.C_GAUGE_TYPE_POS = '1'   --Bien
                                      and pos.C_DOC_POS_STATUS not in('04', '05')   --Non liquidées ou annulées
                                      and pos.FAL_SCHEDULE_STEP_ID = extTask.column_value) loop
      /* Prendre tous les descendant jusqu'à la position provoquant les mouvements */
      pipe row(ltplCstPosIDs.DOC_POSITION_ID);
    end loop;
  exception
    when NO_DATA_NEEDED then
      return;
  end getUnbalancedCstPosIDs;

  /**
  * Description
  *    Retourne la liste des numéro positions de CST de type bien liées au opérations externes du lot non liquidées.
  *    Format du numéro de position : [DNT_NUMBER]/[POS_NUMBER]. Les numéros de positions sont séparés par iSeparator.
  *    Longeur max. de 4000 bytes.
  */
  function getUnbalancedCstPosNumbers(iLotID in FAL_LOT.FAL_LOT_ID%type, iSeparator in varchar2 default '\')
    return varchar2
  is
    lDocPosNumberList varchar2(32767);
  begin
    for ltplDocPosNumbers in (select doc.DMT_NUMBER
                                   , pos.POS_NUMBER
                                from DOC_DOCUMENT doc
                                   , DOC_POSITION pos
                                   , table(getUnbalancedCstPosIDs(iLotID => iLotID) ) CstPos
                               where doc.DOC_DOCUMENT_ID = pos.DOC_DOCUMENT_ID
                                 and pos.DOC_POSITION_ID = CstPos.column_value) loop
      if lDocPosNumberList is not null then
        lDocPosNumberList  := lDocPosNumberList || ' ' || iSeparator || ' ';
      end if;

      lDocPosNumberList  := lDocPosNumberList || ltplDocPosNumbers.DMT_NUMBER || '/' || ltplDocPosNumbers.POS_NUMBER;
    end loop;

    -- Limite technique Oracle de 4000 bytes pour les chaines de caractères dans les commandes SQL.
    return substrb(lDocPosNumberList, 1, 4000);
  end getUnbalancedCstPosNumbers;

  /**
  * Description
  *    Retourne 1 si le lot est soldé
  */
  function isBatchBalanced(iLotID in FAL_LOT.FAL_LOT_ID%type)
    return number
  as
    lBalanced number := 0;
  begin
    if getBatchStatus(iLotID) = FAL_BATCH_FUNCTIONS.bsBalanced then
      lBalanced  := 1;
    end if;

    return lBalanced;
  end isBatchBalanced;

  /**
  * Description
  *    Retourne 1 si le lot gère ses détails (caractérisations gérées sur stock ou produit couplé, hors SAV)
  */
  function useDetails(iLotID in FAL_LOT.FAL_LOT_ID%type)
    return pls_integer
  as
    lUseDetails pls_integer;
  begin
    select count(*)
      into lUseDetails
      from dual
     where exists(
             select GCO_GOOD_ID
               from FAL_LOT
              where FAL_LOT_ID = iLotID
                and nvl(C_FAB_TYPE, 0) <> FAL_BATCH_FUNCTIONS.btAfterSales
                and (   GCO_I_LIB_CHARACTERIZATION.NbCharInStock(GCO_GOOD_ID) > 0
                     or lcCoupledGood = '1') );

    return lUseDetails;
  end useDetails;

  /**
  * Description
  *   Initialisation de la date de péremption
  */
  function InitExpiryDate(iCharId GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type, iLotId in number default null)
    return varchar2
  is
    function GetExternalExpiryDate(iLotId in number, iGoodID in number)
      return varchar2
    is
      lResult varchar2(8);
    begin
      execute immediate 'select ' || FAL_I_LIB_CONSTANT.gcCfgInitExpiryDateProc || '(:LOTID, :IGOODID) from dual'
                   into lResult
                  using iLotId, iGoodId;

      return lResult;
    exception
      when others then
        ra
          (PCS.PC_FUNCTIONS.TranslateWord
                              ('FALPCS - Erreur lors de l''exécution de la procedure individualisée renseignée dans la configuration FAL_INIT_EXPIRY_DATE_PROC.')
          );
    end GetExternalExpiryDate;
  begin
    case FAL_I_LIB_CONSTANT.gcCfgInitExpiryDate
      when 0 then   -- Initialisation standard : date du jour + marge de péremption
        return to_char(trunc(sysdate) + nvl(FWK_I_LIB_ENTITY.getNumberFieldFromPk('GCO_CHARACTERIZATION', 'CHA_LAPSING_DELAY', iCharId), 0), 'YYYYMMDD');
      when 1 then   -- pas d'initialisation
        return null;
      when 2 then   -- Date de péremption la plus petites des composants
        -- Pas encore géré
        return null;
      when 3 then   -- Initialisation selon procedure indiv.
        return GetExternalExpiryDate(FWK_I_LIB_ENTITY.getNumberFieldFromPk('GCO_CHARACTERIZATION', 'GCO_GOOD_ID', iCharId), iLotId);
    end case;
  end InitExpiryDate;

  /**
  * Description
  *   Table function that return a list of active orders that have the good/version
  *   for finished products in progress
  */
  function GetFPVersionInProgress(iGoodId in FAL_LOT.GCO_GOOD_ID%type, iVersion in FAL_LOT_DETAIL.FAD_VERSION%type)
    return ID_TABLE_TYPE
  is
    lResult ID_TABLE_TYPE;
  begin
    select LOT.FAL_LOT_ID
      bulk collect into lResult
      from FAL_LOT LOT left outer join FAL_LOT_DETAIL FAD on (FAD.FAL_LOT_ID = LOT.FAL_LOT_ID and (FAD.FAD_VERSION = iVersion or iVersion is null or FAD.FAD_VERSION is null))
     where LOT.GCO_GOOD_ID = iGoodId
       and C_LOT_STATUS in (FAL_LIB_CONSTANT.gcBatchStatusPlanned, FAL_LIB_CONSTANT.gcBatchStatusLaunched)
       and LOT_MAX_RELEASABLE_QTY > 0;

    return lResult;
  end GetFPVersionInProgress;

  /**
  * Description
  *   Return 1 if there is active orders that have the good/version
  *   for finished products in progress
  */
  function IsFPVersionInProgress(iGoodId in FAL_LOT.GCO_GOOD_ID%type, iVersion in FAL_LOT_DETAIL.FAD_VERSION%type)
    return number
  is
    lResult pls_integer;
  begin
    select sign(count(*) )
      into lResult
      from table(FAL_LIB_BATCH.GetFPVersionInProgress(iGoodId, iVersion) );

    return lResult;
  end IsFPVersionInProgress;

  /**
  * Description
  *   Table function that return a list of active orders that have the good/version
  *   for finished products in progress
  */
  function GetCptVersionInProgress(iGoodId in FAL_LOT_MATERIAL_LINK.GCO_GOOD_ID%type, iVersion in FAL_FACTORY_IN.IN_VERSION%type)
    return ID_TABLE_TYPE
  is
    lResult ID_TABLE_TYPE;
  begin
    select LOM.FAL_LOT_MATERIAL_LINK_ID
      bulk collect into lResult
      from FAL_LOT LOT, FAL_LOT_MATERIAL_LINK LOM, FAL_FACTORY_IN FIN
     where LOM.GCO_GOOD_ID = iGoodId
       and (FIN.IN_VERSION = iVersion or iVersion is null)
       and LOM.FAL_LOT_ID = LOT.FAL_LOT_ID
       and FIN.FAL_LOT_MATERIAL_LINK_ID = LOM.FAL_LOT_MATERIAL_LINK_ID
       and LOT.C_LOT_STATUS = FAL_LIB_CONSTANT.gcBatchStatusLaunched
       and IN_BALANCE > 0;

    return lResult;
  end GetCptVersionInProgress;

  /**
  * Description
  *   Return 1 if there is active orders that have the good/version
  *   for finished products in progress
  */
  function IsCptVersionInProgress(iGoodId in FAL_LOT_MATERIAL_LINK.GCO_GOOD_ID%type, iVersion in FAL_FACTORY_IN.IN_VERSION%type)
    return number
  is
    lResult pls_integer;
  begin
    select sign(count(*) )
      into lResult
      from table(FAL_LIB_BATCH.GetCptVersionInProgress(iGoodId, iVersion) );

    return lResult;
  end IsCptVersionInProgress;

end FAL_LIB_BATCH;
