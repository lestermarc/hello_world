--------------------------------------------------------
--  DDL for Package Body DOC_MGT_EV_ESTIMATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_MGT_EV_ESTIMATE" 
is
  /**
  * function insertEV_ESTIMATE
  * Description
  *    Code métier de l'insertion dans la vue d'un devis
  */
  function insertEV_ESTIMATE(iotEvEstimate in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    ltEstimate FWK_I_TYP_DEFINITION.t_crud_def;
    ltCost     FWK_I_TYP_DEFINITION.t_crud_def;
    lResult    varchar2(40);
  begin
    -- Création de l'entité DOC_ESTIMATE
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimate, ltEstimate, true);
    -- Appliquer les valeurs des champs de la vue à l'entité DOC_ESTIMATE
    DOC_PRC_EV_ESTIMATE.ApplyEstimateChanges(iotEv => iotEvEstimate, iotEstimate => ltEstimate);
    -- Insertion des entités DOC_ESTIMATE et DOC_ESTIMATE_ELEMENT_COST
    FWK_I_MGT_ENTITY.InsertEntity(ltEstimate);
    -- Récuperer l'id du devis créé
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotEvEstimate
                                  , 'DOC_ESTIMATE_ID'
                                  , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltEstimate, 'DOC_ESTIMATE_ID')
                                   );
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotEvEstimate
                                  , 'DOC_ESTIMATE_FOOT_ID'
                                  , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltEstimate, 'DOC_ESTIMATE_ID')
                                   );
    --
    -- Création de l'entité DOC_ESTIMATE_ELEMENT_COST
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimateElementCost, ltCost, true);
    -- Appliquer les valeurs des champs de la vue à l'entité DOC_ESTIMATE_ELEMENT_COST
    DOC_PRC_EV_ESTIMATE.ApplyCostChanges(iotEv => iotEvEstimate, iotCost => ltCost);
    FWK_I_MGT_ENTITY.InsertEntity(ltCost);
    --
    -- Renvoyer DOC_ESTIMATE_ID
    lResult  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltEstimate, 'DOC_ESTIMATE_ID');
    FWK_I_MGT_ENTITY.Release(ltEstimate);
    FWK_I_MGT_ENTITY.Release(ltCost);
    return lResult;
  end insertEV_ESTIMATE;

  /**
  * function updateEV_ESTIMATE
  * Description
  *    Code métier de la modification dans la vue d'un devis
  */
  function updateEV_ESTIMATE(iotEvEstimate in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    ltEstimate     FWK_I_TYP_DEFINITION.t_crud_def;
    ltCost         FWK_I_TYP_DEFINITION.t_crud_def;
    lResult        varchar2(40);
    lElementCostId DOC_ESTIMATE_ELEMENT_COST.DOC_ESTIMATE_ELEMENT_COST_ID%type;
    lEstimateId    DOC_ESTIMATE.DOC_ESTIMATE_ID%type
                                             := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEvEstimate, 'DOC_ESTIMATE_ID');
  begin
    -- Création des entités DOC_ESTIMATE et DOC_ESTIMATE_ELEMENT_COST
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimate, ltEstimate);
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimateElementCost, ltCost);

    -- Recherche de l'id de l'élément de coût
    select DOC_ESTIMATE_ELEMENT_COST_ID
      into lElementCostId
      from DOC_ESTIMATE_ELEMENT_COST
     where DOC_ESTIMATE_FOOT_ID = lEstimateId;

    FWK_I_MGT_ENTITY_DATA.setcolumn(iotEvEstimate, 'DOC_ESTIMATE_ELEMENT_COST_ID', lElementCostId);
    -- Appliquer les valeurs des champs de la vue à l'entité DOC_ESTIMATE
    DOC_PRC_EV_ESTIMATE.ApplyEstimateChanges(iotEv => iotEvEstimate, iotEstimate => ltEstimate);
    -- Appliquer les valeurs des champs de la vue à l'entité DOC_ESTIMATE_ELEMENT_COST
    DOC_PRC_EV_ESTIMATE.ApplyCostChanges(iotEv => iotEvEstimate, iotCost => ltCost);
    -- Insertion des entités DOC_ESTIMATE et DOC_ESTIMATE_ELEMENT_COST
    FWK_I_MGT_ENTITY.UpdateEntity(ltEstimate);

    -- Màj de l'élément de cout seulement s'il y a eu des changements
    if DOC_LIB_ESTIMATE_ELEM_COST.IsElementCostModified(ltCost) then
      FWK_I_MGT_ENTITY.UpdateEntity(ltCost);
    end if;

    -- Renvoyer DOC_ESTIMATE_ID
    lResult  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltEstimate, 'DOC_ESTIMATE_ID');
    FWK_I_MGT_ENTITY.Release(ltEstimate);
    FWK_I_MGT_ENTITY.Release(ltCost);
    return lResult;
  end updateEV_ESTIMATE;

  /**
  * function deleteEV_ESTIMATE
  * Description
  *    Code métier de l'effacement dans la vue d'un devis
  */
  function deleteEV_ESTIMATE(iotEvEstimate in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    ltEstimate FWK_I_TYP_DEFINITION.t_crud_def;
    lResult    varchar2(40);
  begin
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimate, ltEstimate);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltEstimate
                                  , 'DOC_ESTIMATE_ID'
                                  , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEvEstimate, 'DOC_ESTIMATE_ID')
                                   );
    -- Effacement de l'DOC_ESTIMATE
    -- (DOC_ESTIMATE_ELEMENT_COST sera effacé par la surchage de l'effacement de DOC_ESTIMATE)
    FWK_I_MGT_ENTITY.DeleteEntity(ltEstimate);
    FWK_I_MGT_ENTITY.Release(ltEstimate);
    return lResult;
  end deleteEV_ESTIMATE;

  /**
  * function insertEV_ESTIMATE_POS
  * Description
  *    Code métier de l'insertion dans la vue d'une position de devis
  */
  function insertEV_ESTIMATE_POS(iotEvEstimatePos in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    ltPos   FWK_I_TYP_DEFINITION.t_crud_def;
    ltCost  FWK_I_TYP_DEFINITION.t_crud_def;
    lResult varchar2(40);
  begin
    -- Création de l'entité DOC_ESTIMATE_POS
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimatePos, ltPos, true);
    -- Appliquer les valeurs des champs de la vue à l'entité DOC_ESTIMATE_POS
    DOC_PRC_EV_ESTIMATE.ApplyPosChanges(iotEv => iotEvEstimatePos, iotPos => ltPos);
    -- Insertion des entités DOC_ESTIMATE_POS et DOC_ESTIMATE_ELEMENT_COST
    FWK_I_MGT_ENTITY.InsertEntity(ltPos);
    -- Récuperer l'id de la position crée
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotEvEstimatePos
                                  , 'DOC_ESTIMATE_POS_ID'
                                  , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltPos, 'DOC_ESTIMATE_POS_ID')
                                   );
    --
    -- Création de l'entité DOC_ESTIMATE_ELEMENT_COST
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimateElementCost, ltCost, true);
    -- Appliquer les valeurs des champs de la vue à l'entité DOC_ESTIMATE_ELEMENT_COST
    DOC_PRC_EV_ESTIMATE.ApplyCostChanges(iotEv => iotEvEstimatePos, iotCost => ltCost);
    FWK_I_MGT_ENTITY.InsertEntity(ltCost);
    --
    -- Renvoyer DOC_ESTIMATE_POS_ID
    lResult  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltPos, 'DOC_ESTIMATE_POS_ID');
    FWK_I_MGT_ENTITY.Release(ltPos);
    FWK_I_MGT_ENTITY.Release(ltCost);
    return lResult;
  end insertEV_ESTIMATE_POS;

  /**
  * function updateEV_ESTIMATE_POS
  * Description
  *    Code métier de l'insertion dans la vue d'une position de devis
  */
  function updateEV_ESTIMATE_POS(iotEvEstimatePos in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    ltPos          FWK_I_TYP_DEFINITION.t_crud_def;
    ltCost         FWK_I_TYP_DEFINITION.t_crud_def;
    lResult        varchar2(40);
    lElementCostId DOC_ESTIMATE_ELEMENT_COST.DOC_ESTIMATE_ELEMENT_COST_ID%type;
    lPosId         DOC_ESTIMATE_POS.DOC_ESTIMATE_POS_ID%type
                                      := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEvEstimatePos, 'DOC_ESTIMATE_POS_ID');
  begin
    -- Création des entités DOC_ESTIMATE_POS et DOC_ESTIMATE_ELEMENT_COST
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimatePos, ltPos);
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimateElementCost, ltCost);

    -- Recherche de l'id de l'élément de coût
    select DOC_ESTIMATE_ELEMENT_COST_ID
      into lElementCostId
      from DOC_ESTIMATE_ELEMENT_COST
     where DOC_ESTIMATE_POS_ID = lPosId;

    FWK_I_MGT_ENTITY_DATA.setcolumn(iotEvEstimatePos, 'DOC_ESTIMATE_ELEMENT_COST_ID', lElementCostId);
    -- Appliquer les valeurs des champs de la vue à l'entité DOC_ESTIMATE_POS
    DOC_PRC_EV_ESTIMATE.ApplyPosChanges(iotEv => iotEvEstimatePos, iotPos => ltPos);
    -- Appliquer les valeurs des champs de la vue à l'entité DOC_ESTIMATE_ELEMENT_COST
    DOC_PRC_EV_ESTIMATE.ApplyCostChanges(iotEv => iotEvEstimatePos, iotCost => ltCost);
    -- Insertion des entités DOC_ESTIMATE_POS et DOC_ESTIMATE_ELEMENT_COST
    FWK_I_MGT_ENTITY.UpdateEntity(ltPos);

    -- Màj de l'élément de cout seulement s'il y a eu des changements
    if DOC_LIB_ESTIMATE_ELEM_COST.IsElementCostModified(ltCost) then
      FWK_I_MGT_ENTITY.UpdateEntity(ltCost);
    end if;

    -- Renvoyer DOC_ESTIMATE_POS_ID
    lResult  := lPosId;
    FWK_I_MGT_ENTITY.Release(ltPos);
    FWK_I_MGT_ENTITY.Release(ltCost);
    return lResult;
  end updateEV_ESTIMATE_POS;

  /**
  * function deleteEV_ESTIMATE_POS
  * Description
  *    Code métier de l'effacement dans la vue d'une position de devis
  */
  function deleteEV_ESTIMATE_POS(iotEvEstimatePos in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    ltPos   FWK_I_TYP_DEFINITION.t_crud_def;
    lResult varchar2(40);
  begin
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimatePos, ltPos);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltPos
                                  , 'DOC_ESTIMATE_POS_ID'
                                  , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEvEstimatePos, 'DOC_ESTIMATE_POS_ID')
                                   );
    -- Effacement de l'DOC_ESTIMATE_POS
    -- (DOC_ESTIMATE_ELEMENT_COST sera effacé par la surchage de l'effacement de DOC_ESTIMATE_POS)
    FWK_I_MGT_ENTITY.DeleteEntity(ltPos);
    FWK_I_MGT_ENTITY.Release(ltPos);
    return lResult;
  end deleteEV_ESTIMATE_POS;

  /**
  * function insertEV_ESTIMATE_COMP
  * Description
  *    Code métier de l'insertion dans la vue d'un composant de devis
  */
  function insertEV_ESTIMATE_COMP(iotEvEstimateComp in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    ltElement FWK_I_TYP_DEFINITION.t_crud_def;
    ltComp    FWK_I_TYP_DEFINITION.t_crud_def;
    ltCost    FWK_I_TYP_DEFINITION.t_crud_def;
    lResult   varchar2(40);
  begin
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotEvEstimateComp, 'DOC_ESTIMATE_COMP_ID') then
      if not FWK_I_MGT_ENTITY_DATA.IsNull(iotEvEstimateComp, 'DOC_ESTIMATE_ELEMENT_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEvEstimateComp
                                      , 'DOC_ESTIMATE_COMP_ID'
                                      , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEvEstimateComp
                                                                            , 'DOC_ESTIMATE_ELEMENT_ID'
                                                                             )
                                       );
      else
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEvEstimateComp, 'DOC_ESTIMATE_COMP_ID', INIT_ID_SEQ.nextval);
      end if;
    end if;

    -- Assigner l'id du composant
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotEvEstimateComp
                                  , 'DOC_ESTIMATE_ELEMENT_ID'
                                  , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEvEstimateComp, 'DOC_ESTIMATE_COMP_ID')
                                   );
    -- Assigner l'id du composant
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotEvEstimateComp
                                  , 'DOC_ESTIMATE_ELEMENT_COST_ID'
                                  , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEvEstimateComp
                                                                        , 'DOC_ESTIMATE_ELEMENT_COST_ID'
                                                                         )
                                   );
    -- Création de l'entité DOC_ESTIMATE_ELEMENT
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimateElement, ltElement);
    -- Appliquer les valeurs des champs de la vue à l'entité DOC_ESTIMATE_ELEMENT
    DOC_PRC_EV_ESTIMATE.ApplyElementChanges(iotEv => iotEvEstimateComp, iotElement => ltElement);
    -- Insertion de l'entité DOC_ESTIMATE_ELEMENT
    FWK_I_MGT_ENTITY.InsertEntity(ltElement);
    --
    -- Création de l'entité DOC_ESTIMATE_COMP
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimateComp, ltComp);
    -- Appliquer les valeurs des champs de la vue à l'entité DOC_ESTIMATE_COMP
    DOC_PRC_EV_ESTIMATE.ApplyCompChanges(iotEv => iotEvEstimateComp, iotComp => ltComp);
    -- Insertion de l'entité DOC_ESTIMATE_COMP
    FWK_I_MGT_ENTITY.InsertEntity(ltComp);
    --
    -- Création de l'entité DOC_ESTIMATE_ELEMENT_COST
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimateElementCost, ltCost);
    -- Appliquer les valeurs des champs de la vue à l'entité DOC_ESTIMATE_ELEMENT_COST
    DOC_PRC_EV_ESTIMATE.ApplyCostChanges(iotEv => iotEvEstimateComp, iotCost => ltCost);
    -- Insertion de l'entité DOC_ESTIMATE_ELEMENT_COST
    FWK_I_MGT_ENTITY.InsertEntity(ltCost);
    --
    -- Renvoyer DOC_ESTIMATE_COMP_ID
    lResult  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltComp, 'DOC_ESTIMATE_COMP_ID');
    FWK_I_MGT_ENTITY.Release(ltElement);
    FWK_I_MGT_ENTITY.Release(ltComp);
    FWK_I_MGT_ENTITY.Release(ltCost);
    return lResult;
  end insertEV_ESTIMATE_COMP;

  /**
  * function updateEV_ESTIMATE_COMP
  * Description
  *    Code métier de la modification dans la vue d'un composant de devis
  */
  function updateEV_ESTIMATE_COMP(iotEvEstimateComp in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    ltElement      FWK_I_TYP_DEFINITION.t_crud_def;
    ltComp         FWK_I_TYP_DEFINITION.t_crud_def;
    ltCost         FWK_I_TYP_DEFINITION.t_crud_def;
    lResult        varchar2(40);
    lElementCostId DOC_ESTIMATE_ELEMENT_COST.DOC_ESTIMATE_ELEMENT_COST_ID%type;
    lElementId     DOC_ESTIMATE_ELEMENT.DOC_ESTIMATE_ELEMENT_ID%type
                                    := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEvEstimateComp, 'DOC_ESTIMATE_COMP_ID');
  begin
    -- Assigner l'id du composant
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotEvEstimateComp, 'DOC_ESTIMATE_ELEMENT_ID', lElementId);
    -- Création des entités DOC_ESTIMATE_ELEMENT, DOC_ESTIMATE_COMP et DOC_ESTIMATE_ELEMENT_COST
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimateElement, ltElement);
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimateComp, ltComp);
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimateElementCost, ltCost);
    -- Assignation de l'ID de l'élément
    FWK_I_MGT_ENTITY_DATA.setcolumn(iotEvEstimateComp, 'DOC_ESTIMATE_ELEMENT_ID', lElementId);

    -- recherche de l'id de l'élément de coût
    select DOC_ESTIMATE_ELEMENT_COST_ID
      into lElementCostId
      from DOC_ESTIMATE_ELEMENT_COST
     where DOC_ESTIMATE_ELEMENT_ID = lElementId;

    -- Assignation de l'ID de l'élément de coût
    FWK_I_MGT_ENTITY_DATA.setcolumn(iotEvEstimateComp, 'DOC_ESTIMATE_ELEMENT_COST_ID', lElementCostId);
    -- Appliquer les valeurs des champs de la vue à l'entité DOC_ESTIMATE_ELEMENT
    DOC_PRC_EV_ESTIMATE.ApplyElementChanges(iotEv => iotEvEstimateComp, iotElement => ltElement);
    -- Appliquer les valeurs des champs de la vue à l'entité DOC_ESTIMATE_COMP
    DOC_PRC_EV_ESTIMATE.ApplyCompChanges(iotEv => iotEvEstimateComp, iotComp => ltComp);
    -- Appliquer les valeurs des champs de la vue à l'entité DOC_ESTIMATE_ELEMENT_COST
    DOC_PRC_EV_ESTIMATE.ApplyCostChanges(iotEv => iotEvEstimateComp, iotCost => ltCost);
    -- Insertion des entités DOC_ESTIMATE_ELEMENT, DOC_ESTIMATE_COMP et DOC_ESTIMATE_ELEMENT_COST
    FWK_I_MGT_ENTITY.UpdateEntity(ltElement);
    FWK_I_MGT_ENTITY.UpdateEntity(ltComp);

    -- Màj de l'élément de cout seulement s'il y a eu des changements
    if DOC_LIB_ESTIMATE_ELEM_COST.IsElementCostModified(ltCost) then
      FWK_I_MGT_ENTITY.UpdateEntity(ltCost);
    end if;

    -- Renvoyer DOC_ESTIMATE_ELEMENT_ID
    lResult  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltComp, 'DOC_ESTIMATE_COMP_ID');
    FWK_I_MGT_ENTITY.Release(ltElement);
    FWK_I_MGT_ENTITY.Release(ltComp);
    FWK_I_MGT_ENTITY.Release(ltCost);
    return lResult;
  end updateEV_ESTIMATE_COMP;

  /**
  * function deleteEV_ESTIMATE_COMP
  * Description
  *    Code métier de l'effacement dans la vue d'un composant de devis
  */
  function deleteEV_ESTIMATE_COMP(iotEvEstimateComp in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    ltElement FWK_I_TYP_DEFINITION.t_crud_def;
    lResult   varchar2(40);
  begin
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimateElement, ltElement);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltElement
                                  , 'DOC_ESTIMATE_ELEMENT_ID'
                                  , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEvEstimateComp, 'DOC_ESTIMATE_COMP_ID')
                                   );
    -- Effacement de l'DOC_ESTIMATE_ELEMENT
    -- (DOC_ESTIMATE_ELEMENT_COST et DOC_ESTIMATE_COMP seront effacés par la surchage de l'effacement de DOC_ESTIMATE_ELEMENT)
    FWK_I_MGT_ENTITY.DeleteEntity(ltElement);
    FWK_I_MGT_ENTITY.Release(ltElement);
    return lResult;
  end deleteEV_ESTIMATE_COMP;

  /**
  * function insertEV_ESTIMATE_TASK
  * Description
  *    Code métier de l'insertion dans la vue d'une opération de devis
  */
  function insertEV_ESTIMATE_TASK(iotEvEstimateTask in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    ltElement FWK_I_TYP_DEFINITION.t_crud_def;
    ltTask    FWK_I_TYP_DEFINITION.t_crud_def;
    ltCost    FWK_I_TYP_DEFINITION.t_crud_def;
    lResult   varchar2(40);
  begin
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotEvEstimateTask, 'DOC_ESTIMATE_TASK_ID') then
      if not FWK_I_MGT_ENTITY_DATA.IsNull(iotEvEstimateTask, 'DOC_ESTIMATE_ELEMENT_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEvEstimateTask
                                      , 'DOC_ESTIMATE_TASK_ID'
                                      , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEvEstimateTask
                                                                            , 'DOC_ESTIMATE_ELEMENT_ID'
                                                                             )
                                       );
      else
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEvEstimateTask, 'DOC_ESTIMATE_TASK_ID', INIT_ID_SEQ.nextval);
      end if;
    end if;

    -- Assigner l'id de l'opération
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotEvEstimateTask
                                  , 'DOC_ESTIMATE_ELEMENT_ID'
                                  , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEvEstimateTask, 'DOC_ESTIMATE_TASK_ID')
                                   );
    -- Création de l'entité DOC_ESTIMATE_ELEMENT
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimateElement, ltElement);
    -- Appliquer les valeurs des champs de la vue à l'entité DOC_ESTIMATE_ELEMENT
    DOC_PRC_EV_ESTIMATE.ApplyElementChanges(iotEv => iotEvEstimateTask, iotElement => ltElement);
    -- Insertion de l'entité DOC_ESTIMATE_ELEMENT
    FWK_I_MGT_ENTITY.InsertEntity(ltElement);
    --
    -- Création de l'entité DOC_ESTIMATE_TASK
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimateTask, ltTask);
    -- Appliquer les valeurs des champs de la vue à l'entité DOC_ESTIMATE_Task
    DOC_PRC_EV_ESTIMATE.ApplyTaskChanges(iotEv => iotEvEstimateTask, iotTask => ltTask);
    -- Insertion de l'entité DOC_ESTIMATE_TASK
    FWK_I_MGT_ENTITY.InsertEntity(ltTask);
    --
    -- Création de l'entité DOC_ESTIMATE_ELEMENT_COST
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimateElementCost, ltCost);
    -- Appliquer les valeurs des champs de la vue à l'entité DOC_ESTIMATE_ELEMENT_COST
    DOC_PRC_EV_ESTIMATE.ApplyCostChanges(iotEv => iotEvEstimateTask, iotCost => ltCost);
    -- Insertion de l'entité DOC_ESTIMATE_ELEMENT_COST
    FWK_I_MGT_ENTITY.InsertEntity(ltCost);
    --
    -- Renvoyer DOC_ESTIMATE_TASK_ID
    lResult  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltTask, 'DOC_ESTIMATE_TASK_ID');
    FWK_I_MGT_ENTITY.Release(ltElement);
    FWK_I_MGT_ENTITY.Release(ltTask);
    FWK_I_MGT_ENTITY.Release(ltCost);
    return lResult;
  end insertEV_ESTIMATE_TASK;

  /**
  * function updateEV_ESTIMATE_TASK
  * Description
  *    Code métier de la modification dans la vue d'une opération de devis
  */
  function updateEV_ESTIMATE_TASK(iotEvEstimateTask in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    ltElement      FWK_I_TYP_DEFINITION.t_crud_def;
    ltTask         FWK_I_TYP_DEFINITION.t_crud_def;
    ltCost         FWK_I_TYP_DEFINITION.t_crud_def;
    lResult        varchar2(40);
    lElementCostId DOC_ESTIMATE_ELEMENT_COST.DOC_ESTIMATE_ELEMENT_COST_ID%type;
    lElementId     DOC_ESTIMATE_ELEMENT.DOC_ESTIMATE_ELEMENT_ID%type
                                    := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEvEstimateTask, 'DOC_ESTIMATE_TASK_ID');
  begin
    -- Assigner l'id du composant
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotEvEstimateTask, 'DOC_ESTIMATE_ELEMENT_ID', lElementId);
    -- Création des entités DOC_ESTIMATE_ELEMENT, DOC_ESTIMATE_TASK et DOC_ESTIMATE_ELEMENT_COST
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimateElement, ltElement);
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimateTask, ltTask);
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimateElementCost, ltCost);
    -- Assignation de l'ID de l'élément
    FWK_I_MGT_ENTITY_DATA.setcolumn(iotEvEstimateTask, 'DOC_ESTIMATE_ELEMENT_ID', lElementId);

    -- recherche de l'id de l'élément de coût
    select DOC_ESTIMATE_ELEMENT_COST_ID
      into lElementCostId
      from DOC_ESTIMATE_ELEMENT_COST
     where DOC_ESTIMATE_ELEMENT_ID = lElementId;

    -- Assignation de l'ID de l'élément
    FWK_I_MGT_ENTITY_DATA.setcolumn(iotEvEstimateTask, 'DOC_ESTIMATE_ELEMENT_COST_ID', lElementCostId);
    -- Appliquer les valeurs des champs de la vue à l'entité DOC_ESTIMATE_ELEMENT
    DOC_PRC_EV_ESTIMATE.ApplyElementChanges(iotEv => iotEvEstimateTask, iotElement => ltElement);
    -- Appliquer les valeurs des champs de la vue à l'entité DOC_ESTIMATE_TASK
    DOC_PRC_EV_ESTIMATE.ApplyTaskChanges(iotEv => iotEvEstimateTask, iotTask => ltTask);
    -- Appliquer les valeurs des champs de la vue à l'entité DOC_ESTIMATE_ELEMENT_COST
    DOC_PRC_EV_ESTIMATE.ApplyCostChanges(iotEv => iotEvEstimateTask, iotCost => ltCost);
    -- Insertion des entités DOC_ESTIMATE_ELEMENT, DOC_ESTIMATE_TASK et DOC_ESTIMATE_ELEMENT_COST
    FWK_I_MGT_ENTITY.UpdateEntity(ltElement);
    FWK_I_MGT_ENTITY.UpdateEntity(ltTask);

    -- Màj de l'élément de cout seulement s'il y a eu des changements
    if DOC_LIB_ESTIMATE_ELEM_COST.IsElementCostModified(ltCost) then
      FWK_I_MGT_ENTITY.UpdateEntity(ltCost);
    end if;

    -- Renvoyer DOC_ESTIMATE_ELEMENT_ID
    lResult  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltTask, 'DOC_ESTIMATE_TASK_ID');
    FWK_I_MGT_ENTITY.Release(ltElement);
    FWK_I_MGT_ENTITY.Release(ltTask);
    FWK_I_MGT_ENTITY.Release(ltCost);
    return lResult;
  end updateEV_ESTIMATE_TASK;

  /**
  * function deleteEV_ESTIMATE_TASK
  * Description
  *    Code métier de l'effacement dans la vue d'une opération de devis
  */
  function deleteEV_ESTIMATE_TASK(iotEvEstimateTask in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    ltElement FWK_I_TYP_DEFINITION.t_crud_def;
    lResult   varchar2(40);
  begin
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimateElement, ltElement);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltElement
                                  , 'DOC_ESTIMATE_ELEMENT_ID'
                                  , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEvEstimateTask, 'DOC_ESTIMATE_TASK_ID')
                                   );
    -- Effacement de l'DOC_ESTIMATE_ELEMENT
    -- (DOC_ESTIMATE_ELEMENT_COST et DOC_ESTIMATE_TASK seront effacés par la surchage de l'effacement de DOC_ESTIMATE_ELEMENT)
    FWK_I_MGT_ENTITY.DeleteEntity(ltElement);
    FWK_I_MGT_ENTITY.Release(ltElement);
    return lResult;
  end deleteEV_ESTIMATE_TASK;
end DOC_MGT_EV_ESTIMATE;
