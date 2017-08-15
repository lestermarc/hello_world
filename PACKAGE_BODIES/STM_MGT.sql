--------------------------------------------------------
--  DDL for Package Body STM_MGT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_MGT" 
is
  /**
  * Description
  *    Code métier de l'insertion d'un mouvement de stock
  */
  function insertSTOCK_MOVEMENT(iot_crud_definition in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
    lError  varchar2(255);
  begin
    -- Frost stock management flag
    FWK_I_MGT_ENTITY_DATA.setcolumn(iot_crud_definition
                                  , 'SMO_STOCK_MANAGEMENT'
                                  , GCO_LIB_FUNCTIONS.getStockManagement(FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id).GCO_GOOD_ID)
                                   );
    -- Init default values
    STM_PRC_MOVEMENT.InitDefaultValues(FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id) );
    -- Characterization denormalization
    GCO_LIB_CHARACTERIZATION.ClassifyCharacterizations(FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id).GCO_CHARACTERIZATION_ID
                                                     , FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id).GCO_GCO_CHARACTERIZATION_ID
                                                     , FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id).GCO2_GCO_CHARACTERIZATION_ID
                                                     , FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id).GCO3_GCO_CHARACTERIZATION_ID
                                                     , FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id).GCO4_GCO_CHARACTERIZATION_ID
                                                     , FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id).SMO_CHARACTERIZATION_VALUE_1
                                                     , FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id).SMO_CHARACTERIZATION_VALUE_2
                                                     , FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id).SMO_CHARACTERIZATION_VALUE_3
                                                     , FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id).SMO_CHARACTERIZATION_VALUE_4
                                                     , FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id).SMO_CHARACTERIZATION_VALUE_5
                                                     , FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id).SMO_PIECE
                                                     , FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id).SMO_SET
                                                     , FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id).SMO_VERSION
                                                     , FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id).SMO_CHRONOLOGICAL
                                                     , FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id).SMO_STD_CHAR_1
                                                     , FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id).SMO_STD_CHAR_2
                                                     , FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id).SMO_STD_CHAR_3
                                                     , FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id).SMO_STD_CHAR_4
                                                     , FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id).SMO_STD_CHAR_5
                                                      );

    -- Contrôle que si le bien est en inventaire on autorise le mouvement
    lError := STM_I_LIB_MOVEMENT.TestGoodStatus(FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id) );

    if lError is not null then
      ra(aMessage => lError, aErrNo => -20900);
    end if;

    -- Storage conditions control
    lError   := STM_LIB_MOVEMENT.VerifyStorageConditions(FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id) );

    if lError is not null then
      ra(aMessage => lError, aErrNo => -20900);
    end if;

    -- Quality status control
    lError   := STM_LIB_MOVEMENT.VerifyQualityStatus(FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id) );

    if lError is not null then
      ra(aMessage => lError, aErrNo => -20900);
    end if;

    -- Outage control
    if STM_LIB_MOVEMENT.IsOutdatedMvt(FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id) ) = 1 then
      ra(aMessage => PCS.PC_FUNCTIONS.TranslateWord('Produit périmé'), aErrNo => -20900);
    end if;

    -- Retest control
    if STM_LIB_MOVEMENT.IsRetestNeeded(FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id) ) = 1 then
      ra(aMessage => PCS.PC_FUNCTIONS.TranslateWord('Ré-analyse à effectuer'), aErrNo => -20900);
    end if;

    -- Permanent inventory (=> accounts initialisation)
    ACS_LIB_LOGISTIC_FINANCIAL.generatePermanentInventory(FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id) );
    -- Attributions transfert, check if attribution transfer, initialisation of   STM_PRC_MOVEMENT.gAttribTransfertMode  := True;
    FAL_PRC_REPORT_ATTRIB.CheckTransferAttributions(FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id) );
    -- Stock position update
    STM_PRC_STOCK_POSITION.updatePosition(FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id) );
    -- WAC update (PRCS)
    STM_PRC_COSTPRICE.updateWAC(FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id) );
    -- CCP update (PRC)
    STM_PRC_COSTPRICE.updateCCP(FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id) );
    -- Supply political control
    FAL_PRC_DRP.CtrlDrpPolicies(FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id) );
    -- Init original values
    STM_PRC_MOVEMENT.InitOriginalValues(FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id) );
    -- Initialisation de l'id du lot
    STM_PRC_MOVEMENT.InitLotId(FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id) );
    /***********************************
    ** Inserting record in table
    ***********************************/
    lResult  := fwk_i_dml_table.CRUD(iot_crud_definition);
    -- Attributions transfert
    FAL_PRC_REPORT_ATTRIB.TransferAttributions(FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id) );
    -- Update KLS buffer
    STM_PRC_KLS.manageBuffer(FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id) );
    -- Update PIC buffer
    DOC_PRC_MOVEMENT.InsertPicBuffer(FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id) );
    -- Update garanty cards
    DOC_PRC_MOVEMENT.InsertGuarantyCards(FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id) );
    -- update stock evolutions
    STM_PRC_STOCK_EVOLUTION.updateEvolutions(FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id) );
    -- update restocking alerts
    STM_PRC_TRESHOLD.TestStockExercise(FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id) );
    -- update transfert link in first movement
    STM_PRC_MOVEMENT.UpdateTransfertLink(FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id) );
    -- Cycle de vie : Création d'un événement pour un mouvement de stock
    STM_PRC_ELEMENT_NUMBER.CreateEventMovement(FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id) );
    return lResult;
  end insertSTOCK_MOVEMENT;

  /**
  * Description
  *    Code métier de la mise à jour d'un mouvement de stock
  */
  function updateSTOCK_MOVEMENT(iot_crud_definition in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult     varchar2(40);
    lOldConfirm number(1);
  begin
    -- Mécanisme de reconsidération d'un mouvement
    select nvl(A_CONFIRM, 0)
      into loldConfirm
      from STM_STOCK_MOVEMENT
     where STM_STOCK_MOVEMENT_ID = FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id).STM_STOCK_MOVEMENT_ID;

    if nvl(FWK_TYP_STM_ENTITY.gttStockMovement(iot_crud_definition.entity_id).A_CONFIRM, 0) <> lOldConfirm then
      if loldConfirm is null then
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(iot_crud_definition, 'A_CONFIRM');
      else
        FWK_I_MGT_ENTITY_DATA.SetColumn(iot_crud_definition, 'A_CONFIRM', loldConfirm);
      end if;

      /***********************************
      ** reapply insert methods
      ***********************************/
      lResult  := insertSTOCK_MOVEMENT(iot_crud_definition);
    else
      /***********************************
      ** Update record in table
      ***********************************/
      lResult  := fwk_i_dml_table.CRUD(iot_crud_definition);
    end if;

    return lResult;
  end updateSTOCK_MOVEMENT;

  /**
  * Description
  *    Code métier de l'insertion d'un détail de caractérisation
  */
  function insertELEMENT_NUMBER(iot_crud_definition in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- Initialisation du statut qualité
    if     GCO_I_LIB_CHARACTERIZATION.charUseQualityStatus
                             (STM_LIB_ELEMENT_NUMBER.GetCharFromElementType(FWK_TYP_STM_ENTITY.gttElementNumber(iot_crud_definition.entity_id).GCO_GOOD_ID
                                                                          , FWK_TYP_STM_ENTITY.gttElementNumber(iot_crud_definition.entity_id).C_ELEMENT_TYPE
                                                                           )
                             ) = 1
       and FWK_I_MGT_ENTITY_DATA.IsNull(iot_crud_definition, 'GCO_QUALITY_STATUS_ID') then
      FWK_I_MGT_ENTITY_DATA.setcolumn
                                    (iot_crud_definition
                                   , 'GCO_QUALITY_STATUS_ID'
                                   , GCO_I_LIB_QUALITY_STATUS.GetReceiptStatus(FWK_TYP_STM_ENTITY.gttElementNumber(iot_crud_definition.entity_id).GCO_GOOD_ID)
                                    );
    end if;

    -- Gestion de la replication : Ajouter l'élément à la table SHP_TO_PUBLISH
    STM_PRC_ELEMENT_NUMBER.PublishElementNumber(iot_crud_definition);
    /***********************************
    ** execution of CRUD instruction
    ***********************************/
    lResult  := fwk_i_dml_table.CRUD(iot_crud_definition);
    -- Exécuter la procédure indiv conternue dans la config STM_ELE_NUM_AFTER_DELETE
    STM_PRC_ELEMENT_NUMBER.AfterCreateDetail(FWK_TYP_STM_ENTITY.gttElementNumber(iot_crud_definition.entity_id).STM_ELEMENT_NUMBER_ID);
    -- retourne le rowid de l'enregistrement créé (obligatoire)
    return lResult;
  end insertELEMENT_NUMBER;

  /**
  * Description
  *    Code métier de la mise à jour d'un détail de caractérisation
  */
  function updateELEMENT_NUMBER(iot_crud_definition in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- Maj du champ ancien status
    if FWK_I_MGT_ENTITY_DATA.IsModified(iot_crud_definition, 'C_ELE_NUM_STATUS') and not FWK_I_MGT_ENTITY_DATA.IsModified(iot_crud_definition, 'C_OLD_ELE_NUM_STATUS') then
      STM_PRC_ELEMENT_NUMBER.UpdateOldStatus(iot_crud_definition);
    end if;

    lResult  := FWK_I_DML_TABLE.CRUD(iot_crud_definition);
    -- Gestion de la replication : Ajouter l'élément à la table SHP_TO_PUBLISH
    STM_PRC_ELEMENT_NUMBER.PublishElementNumber(iot_crud_definition);
    return lResult;
  end updateELEMENT_NUMBER;

  /**
  * Description
  *    Code métier de la suppression d'un détail de caractérisation
  */
  function deleteELEMENT_NUMBER(iot_crud_definition in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- Suppression des positions de stock du détail de caractérisation supprimé
    STM_PRC_ELEMENT_NUMBER.DeleteStockPosition(iot_crud_definition);
    -- Suppression des événments du détail de caractérisation
    FWK_I_MGT_ENTITY.DeleteChildren(iv_child_name         => 'STM_ELEMENT_NUMBER_EVENT'
                                  , iv_parent_key_name    => 'STM_ELEMENT_NUMBER_ID'
                                  , iv_parent_key_value   => FWK_TYP_STM_ENTITY.gttElementNumber(iot_crud_definition.entity_id).STM_ELEMENT_NUMBER_ID
                                   );
    lResult  := FWK_I_DML_TABLE.CRUD(iot_crud_definition);
    return lResult;
  end deleteELEMENT_NUMBER;

  /**
  * function insertELEMENT_NUMBER_EVENT
  * Description
  *    Code métier de l'insertion d'un événement d'un détail de caractérisation
  */
  function insertELEMENT_NUMBER_EVENT(iot_crud_definition in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- Initialisation de la date de l'événement si pas renseignée
    if FWK_I_MGT_ENTITY_DATA.IsNull(iot_crud_definition, 'ENE_DATE') then
      FWK_I_MGT_ENTITY_DATA.setcolumn(iot_crud_definition, 'ENE_DATE', sysdate);
    end if;

    lResult  := fwk_i_dml_table.CRUD(iot_crud_definition);
    -- retourne le rowid de l'enregistrement créé (obligatoire)
    return lResult;
  end insertELEMENT_NUMBER_EVENT;
end STM_MGT;
