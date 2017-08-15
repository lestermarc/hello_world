--------------------------------------------------------
--  DDL for Package Body DOC_MGT_ESTIMATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_MGT_ESTIMATE" 
is
  /**
  * Description
  *    Code métier de l'insertion d'une entête de devis
  */
  function insertESTIMATE(iotEstimate in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimate, 'DES_NUMBER') then
      DOC_PRC_ESTIMATE.InitEstimateNumber(iotEstimate);
    end if;

    -- Initialisation du code du devis
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimate, 'C_DOC_ESTIMATE_CODE') then
      DOC_PRC_ESTIMATE.InitEstimateCode(iotEstimate => iotEstimate);
    end if;

    -- Initialisation du status à "saisi"
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimate, 'C_DOC_ESTIMATE_STATUS', '00');
    -- Initialisation des données à partir du client
    DOC_PRC_ESTIMATE.InitCustomerData(iotEstimate);
    lResult  := FWK_I_DML_TABLE.CRUD(iotEstimate);

    -- Suppression du numéro du devis dans la table doc_free_number
    DOC_PRC_DOCUMENT.DeleteFreeNumber(FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotEstimate, 'DES_NUMBER'));

    -- retourne le rowid de l'enregistrement créé (obligatoire)
    return lResult;
  end insertESTIMATE;

  /**
  * Description
  *    Code métier de la modification d'une entête de devis
  */
  function updateESTIMATE(iotEstimate in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    lResult  := FWK_I_DML_TABLE.CRUD(iotEstimate);

    -- Si le flag de recalcul est modifié et vaut 1. /!\ Tourne en boucle si pas de contrôle "IsModified"
    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimate, 'DES_RECALC_AMOUNTS')
       and FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimate, 'DES_RECALC_AMOUNTS') = 1 then
      -- Relance de la ventilation du montant de la marge globale.
      DOC_PRC_ESTIMATE_ELEM_COST.applyGlobalMarginAmount(inDocEstimateId => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimate, 'DOC_ESTIMATE_ID') );
      -- Relance du calcul des montants du pied de devis.
      DOC_PRC_ESTIMATE_ELEM_COST.recalc_foot_pos(in_doc_estimate_id => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimate, 'DOC_ESTIMATE_ID') );
    end if;

    -- retourne le rowid de l'enregistrement créé (obligatoire)
    return lResult;
  end updateESTIMATE;

  /**
  * function deleteESTIMATE
  * Description
  *    Code métier de la suppression d'une entête de devis
  */
  function deleteESTIMATE(iotEstimate in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult     varchar2(40);
    lnCanDelete number(1);
    lvMsg       varchar2(4000);
    lvSafeCall  varchar2(1)    := '0';
  begin
    begin
      lvSafeCall  := iotEstimate.attribute_list('SAFE_CALL');
    exception
      when no_data_found then
        null;
    end;

    if lvSafeCall = '1' then
      -- Contrôle que tout soit réuni pour que l'on puisse supprimer le devis
      DOC_LIB_ESTIMATE.CanDeleteEstimate(iEstimateID   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimate, 'DOC_ESTIMATE_ID')
                                       , oCanDelete    => lnCanDelete
                                       , oMessage      => lvMsg
                                        );

      if lnCanDelete = 1 then
        -- Effacer données des tables enfants liées au devis
        DOC_PRC_ESTIMATE.DeleteEstimateChildren(iotEstimate);
        lResult  := FWK_I_DML_TABLE.CRUD(iotEstimate);
      else
        ra(lvMsg);
      end if;
    else
      ra('PCS - Delete estimate must be done with method DOC_I_PRC_ESTIMATE.DeleteEstimate(iEstimateID) !');
    end if;

    return null;
  end deleteESTIMATE;

  /**
  * function insertESTIMATE_POS
  * Description
  *    Code métier de l'insertion d'une position de devis
  */
  function insertESTIMATE_POS(iotEstimatePos in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- Init des données de la position
    DOC_PRC_ESTIMATE_POS.InitPosData(iotEstimatePos => iotEstimatePos);
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotEstimatePos);
    return lResult;
  end insertESTIMATE_POS;

  /**
  * function updateESTIMATE_POS
  * Description
  *    Code métier de la modification d'une position de devis
  */
  function updateESTIMATE_POS(iotEstimatePos in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- Init des données de la position
    DOC_PRC_ESTIMATE_POS.InitPosData(iotEstimatePos => iotEstimatePos);
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotEstimatePos);

    -- Si la valeur du flag "option" a changé, on mets le flag de recalcul du devis à 1 pour relancer la ventilation.
    if FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimatePos, 'DEP_OPTION') then
      DOC_PRC_ESTIMATE.UpdateEstimateFlag(inDocEstimateID => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimatePos, 'DOC_ESTIMATE_ID'), inValue => 1);
    end if;

    -- Si le flag de recalcul de la position est à  1 et qu'il est en cours de modification
    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimatePos, 'DEP_RECALC_AMOUNTS')
       and FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimatePos, 'DEP_RECALC_AMOUNTS') = 1 then
      -- Relance du calcul des montants de la position récapitulative.
      DOC_PRC_ESTIMATE_ELEM_COST.recalc_recap_pos(in_doc_estimate_pos_id => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimatePos, 'DOC_ESTIMATE_POS_ID') );
    end if;

    return lResult;
  end updateESTIMATE_POS;

  /**
  * function deleteESTIMATE_POS
  * Description
  *    Code métier de l'effacement d'une position de devis
  */
  function deleteESTIMATE_POS(iotEstimatePos in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    DOC_PRC_ESTIMATE_POS.DeletePosChildren(iEstimatePosID => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimatePos, 'DOC_ESTIMATE_POS_ID') );
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotEstimatePos);
    return lResult;
  end deleteESTIMATE_POS;

  /**
  * function insertESTIMATE_ELEMENT
  * Description
  *    Code métier de l'insertion d'un élément de devis
  */
  function insertESTIMATE_ELEMENT(iotEstimateElement in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- Init des données de l'élément
    DOC_PRC_ESTIMATE_POS.InitElementData(iotEstimateElement);
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotEstimateElement);
    return lResult;
  end insertESTIMATE_ELEMENT;

  /**
  * function updateESTIMATE_ELEMENT
  * Description
  *    Code métier de la modification d'un élément de devis
  */
  function updateESTIMATE_ELEMENT(iotEstimateElement in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- Init des données de l'élément
    DOC_PRC_ESTIMATE_POS.InitElementData(iotEstimateElement);
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotEstimateElement);
    return lResult;
  end updateESTIMATE_ELEMENT;

  /**
  * function deleteESTIMATE_ELEMENT
  * Description
  *    Code métier de l'effacement d'un élément de devis
  */
  function deleteESTIMATE_ELEMENT(iotEstimateElement in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    DOC_PRC_ESTIMATE_POS.DeleteElementChildren(iElementID => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimateElement, 'DOC_ESTIMATE_ELEMENT_ID') );
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotEstimateElement);
    return lResult;
  end deleteESTIMATE_ELEMENT;

  /**
  * Description
  *    Code métier de l'insertion d'un élément de coût de devis
  */
  function insertESTIMATE_ELEMENT_COST(iotEstimateElementCost in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- Mise à jour du champ DOC_ESTIMATE_ID
    DOC_PRC_ESTIMATE_ELEM_COST.ResolveEstimateId(iotEstimateElementCost);
    -- Mise à jour du status du devis
    DOC_PRC_ESTIMATE_ELEM_COST.UpdateEstimateStatus(iotEstimateElementCost);
    -- Init du prix
    DOC_PRC_ESTIMATE_ELEM_COST.InitPrice(iotEstimateElementCost);
    -- Recalcul des éléments de coût
    DOC_PRC_ESTIMATE_ELEM_COST.recalc_element_cost(iotEstimateElementCost);
    /***********************************
    ** execution of CRUD instruction
    ***********************************/
    lResult  := fwk_i_dml_table.CRUD(iotEstimateElementCost);

    /* Teste si besoin de lancer le recalcul de la position récapitulative. */
    if (DOC_PRC_ESTIMATE_ELEM_COST.isRecalcRecapPosNeeded(iotEstimateElementCost) ) then
      /* Mise à jour du flag de recalcul de la position récapitulative à 1. */
      DOC_PRC_ESTIMATE_POS.UpdatePositionFlag(inEstimateElementID   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimateElementCost, 'DOC_ESTIMATE_ELEMENT_ID')
                                            , inEstimatePosID       => null
                                            , inValue               => 1
                                             );
    end if;

    /* Teste si besoin de lancer le recalcul de la position de pied du devis. */
    if (DOC_PRC_ESTIMATE_ELEM_COST.isRecalcFootPosNeeded(iotEstimateElementCost) ) then
      -- Mise à jour du flag de recalcul du devis à 1.
      DOC_PRC_ESTIMATE.UpdateEstimateFlag(inDocEstimateID => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimateElementCost, 'DOC_ESTIMATE_ID'), inValue => 1);
    end if;

    return lResult;
  end insertESTIMATE_ELEMENT_COST;

  /**
  * Description
  *    Code métier de la modification d'un élément de coût de devis
  */
  function updateESTIMATE_ELEMENT_COST(iotEstimateElementCost in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- Mise à jour du status du devis
    DOC_PRC_ESTIMATE_ELEM_COST.UpdateEstimateStatus(iotEstimateElementCost);
    -- Init du prix
    DOC_PRC_ESTIMATE_ELEM_COST.InitPrice(iotEstimateElementCost);
    -- Recalcul des éléments de coût
    DOC_PRC_ESTIMATE_ELEM_COST.recalc_element_cost(iotEstimateElementCost);
    /***********************************
    ** execution of CRUD instruction
    ***********************************/
    lResult  := fwk_i_dml_table.CRUD(iotEstimateElementCost);

    -- Si la qté de la position a été modifiée, il faut recalculer les prix
    -- des opérations de devis liées à des opérations externe dans le mode Production (MRP)
    if     (FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateElementCost, 'DEC_QUANTITY') )
       and not FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateElementCost, 'DOC_ESTIMATE_POS_ID')
       and FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateElementCost, 'DOC_ESTIMATE_ELEMENT_ID') then
      DOC_PRC_ESTIMATE_ELEM_COST.RecalcPosMRPTasks(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimateElementCost, 'DOC_ESTIMATE_POS_ID') );
    end if;

    /* Teste si besoin de lancer le recalcul de la position récapitulative. */
    if (DOC_PRC_ESTIMATE_ELEM_COST.isRecalcRecapPosNeeded(iotEstimateElementCost) ) then
      /* Mise à jour du flag de recalcul de la position récapitulative à 1. */
      DOC_PRC_ESTIMATE_POS.UpdatePositionFlag(inEstimateElementID   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimateElementCost, 'DOC_ESTIMATE_ELEMENT_ID')
                                            , inEstimatePosID       => null
                                            , inValue               => 1
                                             );
    end if;

    /* Teste si besoin de lancer le recalcul de la position de pied du devis. */
    if (DOC_PRC_ESTIMATE_ELEM_COST.isRecalcFootPosNeeded(iotEstimateElementCost) ) then
      -- Mise à jour du flag de recalcul du devis à 1.
      DOC_PRC_ESTIMATE.UpdateEstimateFlag(inDocEstimateID => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimateElementCost, 'DOC_ESTIMATE_ID'), inValue => 1);
    end if;

    return lResult;
  end updateESTIMATE_ELEMENT_COST;

  /**
  * Description
  *    Code métier de l'effacement d'un élément de coût de devis
  */
  function deleteESTIMATE_ELEMENT_COST(iotEstimateElementCost in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- Mise à jour du status du devis
    DOC_PRC_ESTIMATE_ELEM_COST.UpdateEstimateStatus(iotEstimateElementCost);
    -- Recalcul des éléments de coût
    DOC_PRC_ESTIMATE_ELEM_COST.recalc_element_cost(iotEstimateElementCost);
    /***********************************
    ** execution of CRUD instruction
    ***********************************/
    lResult  := fwk_i_dml_table.CRUD(iotEstimateElementCost);

    /* Teste si besoin de lancer le recalcul de la position récapitulative. */
    if (DOC_PRC_ESTIMATE_ELEM_COST.isRecalcRecapPosNeeded(iotEstimateElementCost) ) then
      /* Mise à jour du flag de recalcul de la position récapitulative à 1. */
      DOC_PRC_ESTIMATE_POS.UpdatePositionFlag(inEstimateElementID   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimateElementCost, 'DOC_ESTIMATE_ELEMENT_ID')
                                            , inEstimatePosID       => null
                                            , inValue               => 1
                                             );
    end if;

    /* Teste si besoin de lancer le recalcul de la position de pied du devis. */
    if (DOC_PRC_ESTIMATE_ELEM_COST.isRecalcFootPosNeeded(iotEstimateElementCost) ) then
      -- Mise à jour du flag de recalcul du devis à 1.
      DOC_PRC_ESTIMATE.UpdateEstimateFlag(inDocEstimateID => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimateElementCost, 'DOC_ESTIMATE_ID'), inValue => 1);
    end if;

--     DOC_PRC_ESTIMATE_ELEM_COST.recalc_element_cost(iotEstimateElementCost);
    return lResult;
  end deleteESTIMATE_ELEMENT_COST;

  /**
  * function insertESTIMATE_COMP
  * Description
  *    Code métier de l'insertion d'un composant
  */
  function insertESTIMATE_COMP(iotEstimateComp in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- Init des données du composant
    DOC_PRC_ESTIMATE_POS.InitCompData(iotEstimateComp => iotEstimateComp);
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotEstimateComp);
    return lResult;
  end insertESTIMATE_COMP;

  /**
  * function updateESTIMATE_COMP
  * Description
  *    Code métier de la modification d'un composant
  */
  function updateESTIMATE_COMP(iotEstimateComp in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- Init des données du composant
    DOC_PRC_ESTIMATE_POS.InitCompData(iotEstimateComp => iotEstimateComp);
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotEstimateComp);
    return lResult;
  end updateESTIMATE_COMP;

  /**
  * function deleteESTIMATE_COMP
  * Description
  *    Code métier de l'effacement d'un composant
  */
  function deleteESTIMATE_COMP(iotEstimateComp in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotEstimateComp);
    return lResult;
  end deleteESTIMATE_COMP;

  /**
  * function insertESTIMATE_TASK
  * Description
  *    Code métier de l'insertion d'un composant
  */
  function insertESTIMATE_TASK(iotEstimateTask in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- Init des données de l'opération
    DOC_PRC_ESTIMATE_POS.InitTaskData(iotEstimateTask => iotEstimateTask);
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotEstimateTask);
    return lResult;
  end insertESTIMATE_TASK;

  /**
  * function updateESTIMATE_TASK
  * Description
  *    Code métier de la modification d'un composant
  */
  function updateESTIMATE_TASK(iotEstimateTask in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- Init des données de l'opération
    DOC_PRC_ESTIMATE_POS.InitTaskData(iotEstimateTask => iotEstimateTask);
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotEstimateTask);
    return lResult;
  end updateESTIMATE_TASK;

  /**
  * function deleteESTIMATE_TASK
  * Description
  *    Code métier de l'effacement d'un composant
  */
  function deleteESTIMATE_TASK(iotEstimateTask in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotEstimateTask);
    return lResult;
  end deleteESTIMATE_TASK;
end DOC_MGT_ESTIMATE;
