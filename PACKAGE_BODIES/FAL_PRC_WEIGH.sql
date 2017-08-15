--------------------------------------------------------
--  DDL for Package Body FAL_PRC_WEIGH
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_WEIGH" 
is
  /**
  * Description
  *    Cette procédure va créer pesée de correction en quantité pour la ligne
  *    d'inventaire reçue en paramètre.
  */
  procedure createQtyCorrWeigh4AlloyInvent(
    inFalPositionID  in FAL_LINE_INVENTORY.FAL_POSITION_ID%type
  , inGcoGoodID      in FAL_LINE_INVENTORY.GCO_GOOD_ID%type
  , inGcoAlloyID     in FAL_LINE_INVENTORY.GCO_ALLOY_ID%type
  , inDicOperatorID  in FAL_LINE_INVENTORY.DIC_OPERATOR_ID%type
  , idFliDateInvent  in FAL_LINE_INVENTORY.FLI_DATE_INVENT%type
  , inFliQtyCorrect  in FAL_LINE_INVENTORY.FLI_QTY_CORRECT%type
  , ivFaiCommentaire in FAL_ALLOY_INVENTORY.FAI_COMMENTAIRE%type
  )
  as
    ltCRUD_FalWeigh FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalWeigh, ltCRUD_FalWeigh, true);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'GCO_ALLOY_ID', inGcoAlloyID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'GCO_GOOD_ID', inGcoGoodID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'DIC_OPERATOR_ID', inDicOperatorID);
    FWK_I_MGT_ENTITY_DATA.setcolumnNull(ltCRUD_FalWeigh, 'FAL_LOT_ID');
    FWK_I_MGT_ENTITY_DATA.setcolumnNull(ltCRUD_FalWeigh, 'FAL_SCHEDULE_STEP_ID');
    FWK_I_MGT_ENTITY_DATA.setcolumnNull(ltCRUD_FalWeigh, 'DOC_POSITION_ID');
    FWK_I_MGT_ENTITY_DATA.setcolumnNull(ltCRUD_FalWeigh, 'DOC_DOCUMENT_ID');
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_IN', 0);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_WASTE', 0);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_INIT', 1);

    if inFliQtyCorrect > 0 then
      FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FAL_POSITION1_ID', inFalPositionID);
      FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_POSITION1_DESCR', FAL_LIB_POSITION.getDescription(inFalPositionID => inFalPositionID) );
      FWK_I_MGT_ENTITY_DATA.setcolumnNull(ltCRUD_FalWeigh, 'FAL_POSITION2_ID');
      FWK_I_MGT_ENTITY_DATA.setcolumnNull(ltCRUD_FalWeigh, 'FWE_POSITION2_DESCR');
    else
      FWK_I_MGT_ENTITY_DATA.setcolumnNull(ltCRUD_FalWeigh, 'FAL_POSITION1_ID');
      FWK_I_MGT_ENTITY_DATA.setcolumnNull(ltCRUD_FalWeigh, 'FWE_POSITION1_DESCR');
      FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FAL_POSITION2_ID', inFalPositionID);
      FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_POSITION2_DESCR', FAL_LIB_POSITION.getDescription(inFalPositionID => inFalPositionID) );
    end if;

    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_DATE', idFliDateInvent);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_WEIGHT', 0);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_WEIGHT_MAT', 0);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_PIECE_QTY', abs(inFliQtyCorrect) );
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_COMMENT', ivFaiCommentaire);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_WEEKDATE', DOC_DELAY_FUNCTIONS.DateToWeek(aDate => idFliDateInvent) );
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'GAL_ALLOY_REF', GCO_LIB_ALLOY.getAlloyRef(iAlloyId => inGcoAlloyID) );
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'GOO_MAJOR_REFERENCE', GCO_I_LIB_FUNCTIONS.getMajorReference(iGoodId => inGcoGoodID) );
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'GOO_SECONDARY_REFERENCE', GCO_I_LIB_FUNCTIONS.getSecondaryReference(inGcoGoodID => inGcoGoodID) );
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_FalWeigh);
    FWK_I_MGT_ENTITY.Release(ltCRUD_FalWeigh);
  end createQtyCorrWeigh4AlloyInvent;

  /**
  * Description
  *    Cette procédure va créer pesée de correction en poids pour la ligne
  *    d'inventaire reçue en paramètre.
  */
  procedure createCorrWeigh4AlloyInvent(
    inFalPositionID  in FAL_LINE_INVENTORY.FAL_POSITION_ID%type
  , inGcoGoodID      in FAL_LINE_INVENTORY.GCO_GOOD_ID%type
  , inGcoAlloyID     in FAL_LINE_INVENTORY.GCO_ALLOY_ID%type
  , inDicOperatorID  in FAL_LINE_INVENTORY.DIC_OPERATOR_ID%type
  , idFliDateInvent  in FAL_LINE_INVENTORY.FLI_DATE_INVENT%type
  , inFliCorrect     in FAL_LINE_INVENTORY.FLI_CORRECT%type
  , ivFaiCommentaire in FAL_ALLOY_INVENTORY.FAI_COMMENTAIRE%type
  )
  as
    ltCRUD_FalWeigh FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalWeigh, ltCRUD_FalWeigh, true);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'GCO_ALLOY_ID', inGcoAlloyID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'GCO_GOOD_ID', inGcoGoodID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'DIC_OPERATOR_ID', inDicOperatorID);
    FWK_I_MGT_ENTITY_DATA.setcolumnNull(ltCRUD_FalWeigh, 'FAL_LOT_ID');
    FWK_I_MGT_ENTITY_DATA.setcolumnNull(ltCRUD_FalWeigh, 'FAL_SCHEDULE_STEP_ID');
    FWK_I_MGT_ENTITY_DATA.setcolumnNull(ltCRUD_FalWeigh, 'DOC_POSITION_ID');
    FWK_I_MGT_ENTITY_DATA.setcolumnNull(ltCRUD_FalWeigh, 'DOC_DOCUMENT_ID');
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_IN', 0);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_WASTE', 0);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_INIT', 1);

    if inFliCorrect > 0 then
      FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FAL_POSITION1_ID', inFalPositionID);
      FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_POSITION1_DESCR', FAL_LIB_POSITION.getDescription(inFalPositionID => inFalPositionID) );
      FWK_I_MGT_ENTITY_DATA.setcolumnNull(ltCRUD_FalWeigh, 'FAL_POSITION2_ID');
      FWK_I_MGT_ENTITY_DATA.setcolumnNull(ltCRUD_FalWeigh, 'FWE_POSITION2_DESCR');
    else
      FWK_I_MGT_ENTITY_DATA.setcolumnNull(ltCRUD_FalWeigh, 'FAL_POSITION1_ID');
      FWK_I_MGT_ENTITY_DATA.setcolumnNull(ltCRUD_FalWeigh, 'FWE_POSITION1_DESCR');
      FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FAL_POSITION2_ID', inFalPositionID);
      FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_POSITION2_DESCR', FAL_LIB_POSITION.getDescription(inFalPositionID => inFalPositionID) );
    end if;

    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_DATE', idFliDateInvent);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_WEIGHT', abs(inFliCorrect) );
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_WEIGHT_MAT', abs(inFliCorrect) );
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_PIECE_QTY', 0);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_COMMENT', ivFaiCommentaire);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_WEEKDATE', DOC_DELAY_FUNCTIONS.DateToWeek(aDate => idFliDateInvent) );
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'GAL_ALLOY_REF', GCO_LIB_ALLOY.getAlloyRef(iAlloyId => inGcoAlloyID) );
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'GOO_MAJOR_REFERENCE', GCO_I_LIB_FUNCTIONS.getMajorReference(iGoodId => inGcoGoodID) );
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'GOO_SECONDARY_REFERENCE', GCO_I_LIB_FUNCTIONS.getSecondaryReference(inGcoGoodID => inGcoGoodID) );
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_FalWeigh);
    FWK_I_MGT_ENTITY.Release(ltCRUD_FalWeigh);
  end createCorrWeigh4AlloyInvent;

  /**
  * Description
  *    Supprime les pesées relatives au suivi d'avancement transmis en paramètre.
  */
  procedure deleteWeighByLotProgress(inFalLotProgressID in FAL_WEIGH.FAL_LOT_PROGRESS_ID%type)
  as
    ltCRUD_FalWeigh FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for ltplWeighToDelete in (select FAL_WEIGH_ID
                                from FAL_WEIGH
                               where FAL_LOT_PROGRESS_ID = inFalLotProgressID) loop
      FWK_I_MGT_ENTITY.new(iv_entity_name        => FWK_I_TYP_FAL_ENTITY.gcFalWeigh
                         , iot_crud_definition   => ltCRUD_FalWeigh
                         , ib_initialize         => false
                         , in_main_id            => ltplWeighToDelete.FAL_WEIGH_ID
                          );
      FWK_I_MGT_ENTITY.DeleteEntity(ltCRUD_FalWeigh);
      FWK_I_MGT_ENTITY.Release(ltCRUD_FalWeigh);
    end loop;
  end deleteWeighByLotProgress;

  /**
  * procedure checkWeighingDataIntegrity
  * Description : Vérification des données de pesée pour insertion
  *
  * @created ECA 20/07/2012
  * @lastUpdate
  * @private
  */
  procedure checkWeighingDataIntegrity(
    iGCO_ALLOY_ID              in     number default null
  , iGCO_GOOD_ID               in     number default null
  , iFAL_LOT_DETAIL_ID         in     number default null
  , iFAL_LOT_PROGRESS_ID       in     number default null
  , iFAL_SCALE_PAN_ID          in     number default null
  , iFAL_LOT_PROGRESS_FOG_ID   in     number default null
  , iDOC_RECORD_ID             in     number default null
  , iSTM_ELEMENT_NUMBER_ID     in     number default null
  , iSTM_ELEMENT_NUMBER2_ID    in     number default null
  , iSTM_ELEMENT_NUMBER3_ID    in     number default null
  , iFWE_WASTE                 in     integer default null
  , iFWE_TURNINGS              in     integer default null
  , iFWE_DATE                  in     date default null
  , iFWE_WEIGHT                in     number default null
  , iFWE_STONE_NUM             in     number default null
  , iFWE_COMMENT               in     varchar2 default null
  , iFWE_PIECE_QTY             in     number default null
  , iC_WEIGH_TYPE              in     varchar2 default null
  , iFWE_PAN_WEIGHT            in     number default null
  , ioFAL_POSITION1_ID         in out number
  , ioFAL_POSITION2_ID         in out number
  , ioDIC_OPERATOR_ID          in out varchar2
  , ioDOC_DOCUMENT_ID          in out number
  , ioDOC_POSITION_ID          in out number
  , ioFAL_SCHEDULE_STEP_ID     in out number
  , ioFAL_LOT_ID               in out number
  , ioFAL_LOT_MATERIAL_LINK_ID in out number
  , ioErrorMsg                 in out varchar2
  )
  is
    lvCWeighType varchar2(10);
    liGPM_WEIGHT integer;
  begin
    -- Vérification du type de pesée.
    begin
      select 1
        into lvCWeighType
        from dual
       where exists(select 1
                      from PCS.V_PC_DESCODES
                     where GCGNAME = 'C_WEIGH_TYPE'
                       and GCLCODE = iC_WEIGH_TYPE);
    exception
      when no_data_found then
        ioErrorMsg  := ioErrorMsg || PCS.PC_FUNCTIONS.TranslateWord('Type de pesée inconnu : ') || iC_WEIGH_TYPE;
    end;

    -- Poste Entrant et / ou sortant
    begin
      select FAL_POSITION_ID
        into ioFAL_POSITION1_ID
        from FAL_POSITION
       where FAL_POSITION_ID = ioFAL_POSITION1_ID;
    exception
      when others then
        null;
    end;

    begin
      select FAL_POSITION_ID
        into ioFAL_POSITION2_ID
        from FAL_POSITION
       where FAL_POSITION_ID = ioFAL_POSITION2_ID;
    exception
      when others then
        null;
    end;

    if     nvl(ioFAL_POSITION1_ID, 0) = 0
       and nvl(ioFAL_POSITION2_ID, 0) = 0 then
      ioErrorMsg  := ioErrorMsg || PCS.PC_FUNCTIONS.TranslateWord('Postes de la pesée non renseignés!');
    end if;

    -- Recherche Opérateur
    begin
      select DIC_OPERATOR_ID
        into ioDIC_OPERATOR_ID
        from DIC_OPERATOR
       where DIC_OPERATOR_ID = ioDIC_OPERATOR_ID;
    exception
      -- si non trouvé, initialisation par rapport au user
      when no_data_found then
        begin
          select DIC_OPERATOR_ID
            into ioDIC_OPERATOR_ID
            from DIC_OPERATOR
           where DIC_OPERATOR_ID = PCS.PC_I_LIB_SESSION.GetUserIni;
        exception
          when no_data_found then
            ioErrorMsg  := ioErrorMsg || PCS.PC_FUNCTIONS.TranslateWord('Opérateur inconnu : ') || ioDIC_OPERATOR_ID;
        end;
    end;

    -- Correspondance Alliage/produit (sauf pour alliage générique qui peut être pesé pour chaque produit)
    if iGCO_ALLOY_ID <> GCO_I_LIB_ALLOY.getGenericAlloy then
      begin
        select GPM_WEIGHT
          into liGPM_WEIGHT
          from GCO_PRECIOUS_MAT GPM
         where GPM.GCO_GOOD_ID = iGCO_GOOD_ID
           and GPM.GCO_ALLOY_ID = iGCO_ALLOY_ID;

        if nvl(liGPM_WEIGHT, 0) <> 1 then
          ioErrorMsg  := ioErrorMsg || PCS.PC_FUNCTIONS.TranslateWord('L''alliage n''est pas à peser : ') || iGCO_ALLOY_ID;
        end if;
      exception
        when no_data_found then
          ioErrorMsg  := ioErrorMsg || PCS.PC_FUNCTIONS.TranslateWord('Couple produit / alliage incorrect : ') || iGCO_GOOD_ID || '/' || iGCO_ALLOY_ID;
      end;
    end if;

    -- Données nécessaires à chaque type de peseés
    -- 1  Sortie Composant
    -- 2  Pesée opération
    if    iC_WEIGH_TYPE = '1'
       or iC_WEIGH_TYPE = '2' then
      begin
        select FAL_LOT_ID
             , FAL_SCHEDULE_STEP_ID
          into ioFAL_LOT_ID
             , ioFAL_SCHEDULE_STEP_ID
          from FAL_TASK_LINK
         where FAL_SCHEDULE_STEP_ID = ioFAL_SCHEDULE_STEP_ID;
      exception
        when no_data_found then
          ioErrorMsg  := ioErrorMsg || PCS.PC_FUNCTIONS.TranslateWord('Pesée opératoire, lot et operation incorrects.');
      end;
    -- 3  Mouvement matière
    elsif iC_WEIGH_TYPE = '3' then
      begin
        select DOC_DOCUMENT_ID
             , DOC_POSITION_ID
          into ioDOC_DOCUMENT_ID
             , ioDOC_POSITION_ID
          from DOC_POSITION
         where DOC_POSITION_ID = ioDOC_POSITION_ID;
      exception
        when no_data_found then
          ioErrorMsg  := ioErrorMsg || PCS.PC_FUNCTIONS.TranslateWord('Pesée de mouvement matière, document et position incorrects.');
      end;
    -- 4  Réception lot fabrication
    elsif iC_WEIGH_TYPE = '4' then
      begin
        select FAL_LOT_ID
          into ioFAL_LOT_ID
          from FAL_LOT
         where FAL_LOT_ID = ioFAL_LOT_ID;
      exception
        when no_data_found then
          ioErrorMsg  := ioErrorMsg || PCS.PC_FUNCTIONS.TranslateWord('Pesée réception fabrication, lot incorrects.');
      end;
    -- 6  Sortie de composants
    -- 7  Retour de composants
    -- 8  Remplacement de composants
    -- 9  Affectation de composants - lots vers stocks
    -- 10 Affectation de composants - stocks vers lots
    -- 11 Mouvement de dérivé
    elsif iC_WEIGH_TYPE in('6', '7', '8', '9', '10', '11') then
      begin
        select FAL_LOT_ID
             , FAL_LOT_MATERIAL_LINK_ID
          into ioFAL_LOT_ID
             , ioFAL_LOT_MATERIAL_LINK_ID
          from FAL_LOT_MATERIAL_LINK
         where FAL_LOT_MATERIAL_LINK_ID = ioFAL_LOT_MATERIAL_LINK_ID;
      exception
        when no_data_found then
          ioErrorMsg  := ioErrorMsg || PCS.PC_FUNCTIONS.TranslateWord('Pesée mouvement de composants, lot/composant incorrects.');
      end;
    end if;
  end checkWeighingDataIntegrity;

  /**
  * procedure InsertFalWeigh
  * Description : Procédure d'insertion de pesées
  *
  * @created eca 19.07/2012
  * @lastUpdate
  * @public
  */
  procedure InsertFalWeigh(
    iGcoAlloyID           in     number
  , iGcoGoodID            in     number
  , iDicOperatorID        in     varchar2
  , iFalLotId             in     number
  , iFalScheduleStepId    in     number
  , iDocPositionId        in     number
  , iDocDocumentId        in     number
  , iDocRecordId          in     number
  , iElementNum1          in     number
  , iElementNum2          in     number
  , iElementNum3          in     number
  , iFweIn                in     integer
  , iFweWaste             in     integer
  , iFweTurnings          in     integer
  , inFalPosition1ID      in     number
  , inFalPosition2ID      in     number
  , iFweDate              in     date
  , iFweWeight            in     number
  , iFweWeightMat         in     number
  , iFweStoneNum          in     number
  , iFweComment           in     varchar2
  , iFwePieceQty          in     number
  , iFweEntryWeight       in     number
  , iCWeighType           in     varchar2
  , iFalLotProgressId     in     number
  , iFalLotProgressFogId  in     number
  , iFalScalePanId        in     number
  , iPanWeight            in     number
  , iFalLotMaterialLinkId in     number
  , ioFalWeighId          in out number
  )
  is
    ltCRUD_FalWeigh FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalWeigh, ltCRUD_FalWeigh, true);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'GCO_ALLOY_ID', iGcoAlloyID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'GCO_GOOD_ID', iGcoGoodID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'DIC_OPERATOR_ID', iDicOperatorID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FAL_LOT_ID', iFalLotId);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FAL_SCHEDULE_STEP_ID', iFalScheduleStepId);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'DOC_POSITION_ID', iDocPositionId);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'DOC_DOCUMENT_ID', iDocDocumentId);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'DOC_RECORD_ID', iDocRecordId);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'STM_ELEMENT_NUMBER_ID', iElementNum1);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'STM_ELEMENT_NUMBER2_ID', iElementNum2);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'STM_ELEMENT_NUMBER3_ID', iElementNum3);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_IN', iFweIn);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_WASTE', nvl(iFweWaste, 0) );
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_TURNINGS', nvl(iFweTurnings, 0) );
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_INIT', 0);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FAL_POSITION1_ID', inFalPosition1ID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_POSITION1_DESCR', FAL_LIB_POSITION.getDescription(inFalPositionID => inFalPosition1ID) );
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FAL_POSITION2_ID', inFalPosition2ID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_POSITION2_DESCR', FAL_LIB_POSITION.getDescription(inFalPositionID => inFalPosition2ID) );
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_DATE', ifweDate);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_WEEKDATE', DOC_DELAY_FUNCTIONS.DateToWeek(aDate => ifweDate) );
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_WEIGHT', iFweWeight);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_WEIGHT_MAT', iFweWeightMat);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_STONE_NUM', iFweStoneNum);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_COMMENT', iFweComment);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'GAL_ALLOY_REF', GCO_LIB_ALLOY.getAlloyRef(iAlloyId => iGcoAlloyID) );
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'GOO_MAJOR_REFERENCE', GCO_I_LIB_FUNCTIONS.getMajorReference(iGoodId => iGcoGoodID) );
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'GOO_SECONDARY_REFERENCE', GCO_I_LIB_FUNCTIONS.getSecondaryReference(inGcoGoodID => iGcoGoodID) );
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_PIECE_QTY', iFwePieceQty);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_ENTRY_WEIGHT', iFweEntryWeight);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'LOT_REFCOMPL', FAL_TOOLS.Format_lot(iFalLotId) );
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh
                                  , 'DMT_NUMBER'
                                  , (case
                                       when nvl(iDocDocumentId, 0) <> 0 then DOC_LIB_DOCUMENT.GetDmtNumber(iDocDocumentId)
                                       else null
                                     end)
                                   );
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'C_WEIGH_TYPE', iCWeighType);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FAL_LOT_PROGRESS_ID', iFalLotProgressId);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FAL_LOT_PROGRESS_FOG_ID', iFalLotProgressFogId);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FAL_SCALE_PAN_ID', iFalScalePanId);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FWE_PAN_WEIGHT', iPanWeight);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalWeigh, 'FAL_LOT_MATERIAL_LINK_ID', iFalLotMaterialLinkId);
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_FalWeigh);
    ioFalWeighId  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCRUD_FalWeigh, 'FAL_WEIGH_ID');
    FWK_I_MGT_ENTITY.Release(ltCRUD_FalWeigh);
    FWK_I_MGT_ENTITY.Release(ltCRUD_FalWeigh);
  end InsertFalWeigh;

  /**
  * procedure CalcMatWeigh
  * Description : Calcul du poids matière
  *
  * @created eca 19.07/2012
  * @lastUpdate
  * @public
  */
  function CalcMatWeigh(
    iFWE_WEIGHT           in number
  , iFAL_SCHEDULE_STEP_ID in number
  , iWeighingWithStone    in integer
  , iGCO_GOOD_ID          in number
  , iFWE_PIECE_QTY        in number
  , iFAL_POSITION1_ID     in number
  , iFAL_POSITION2_ID     in number
  , iDoublePesee          in boolean
  , iDOC_POSITION_ID      in number
  , iC_WEIGH_TYPE         in varchar2
  , iFWE_WASTE            in integer
  , iFWE_TURNINGS         in integer
  , iFAL_LOT_ID           in number
  , iFWE_PAN_WEIGHT       in number
  )
    return number
  is
    lnFWE_WEIGHT_MAT number;
  begin
    -- Pas de prise en compte de la problématique de sertissage
    if PCS.PC_CONFIG.GETCONFIG('FAL_WEIGH_STONE') = '0' then
      lnFWE_WEIGHT_MAT  := iFWE_WEIGHT;
    -- Prise en compte de la problématique de sertissage
    else
      -- Pesée <> Opératoire
      if iFAL_SCHEDULE_STEP_ID is null then
        if    iWeighingWithStone = 1
           or nvl(iDOC_POSITION_ID, 0) <> 0
           or (    iC_WEIGH_TYPE = '4'
               and iFWE_WASTE <> 1
               and iFWE_TURNINGS <> 1) then
          lnFWE_WEIGHT_MAT  := iFWE_WEIGHT -(nvl(FAL_WEIGH_FUNCTION.GET_GCO_THEORICAL_STONE_WEIGHT(iGCO_GOOD_ID), 0) * nvl(iFWE_PIECE_QTY, 1) );
        else
          lnFWE_WEIGHT_MAT  := iFWE_WEIGHT;
        end if;
      -- Pesée opératoire
      else
        -- Pesée d'entrée
        if nvl(iFAL_POSITION1_ID, 0) <> 0 then
          if iDoublePesee then
            if trim(FAL_WEIGH_FUNCTION.GET_DIC_FREE_TASK_CODE(iFAL_SCHEDULE_STEP_ID) ) = 0 then
              lnFWE_WEIGHT_MAT  := iFWE_WEIGHT;
            else
              lnFWE_WEIGHT_MAT  := iFWE_WEIGHT -(nvl(FAL_WEIGH_FUNCTION.GET_GCO_THEORICAL_STONE_WEIGHT(iGCO_GOOD_ID), 0) * nvl(iFWE_PIECE_QTY, 1) );
            end if;
          else
            if trim(FAL_WEIGH_FUNCTION.GET_DIC_FREE_TASK_CODE(FAL_WEIGH_FUNCTION.GET_PREVIOUS_FAL_TASK_LINK_ID(iFAL_LOT_ID, iFAL_SCHEDULE_STEP_ID) ) ) = 0 then
              lnFWE_WEIGHT_MAT  := iFWE_WEIGHT;
            else
              lnFWE_WEIGHT_MAT  := iFWE_WEIGHT -(nvl(FAL_WEIGH_FUNCTION.GET_GCO_THEORICAL_STONE_WEIGHT(IGCO_GOOD_ID), 0) * nvl(iFWE_PIECE_QTY, 1) );
            end if;
          end if;
        -- Pesée de sortie
        elsif nvl(iFAL_POSITION2_ID, 0) <> 0 then
          if trim(FAL_WEIGH_FUNCTION.GET_DIC_FREE_TASK_CODE(iFAL_SCHEDULE_STEP_ID) ) = 0 then
            lnFWE_WEIGHT_MAT  := iFWE_WEIGHT;
          else
            lnFWE_WEIGHT_MAT  := iFWE_WEIGHT -(nvl(FAL_WEIGH_FUNCTION.GET_GCO_THEORICAL_STONE_WEIGHT(iGCO_GOOD_ID), 0) * nvl(iFWE_PIECE_QTY, 1) );
          end if;
        end if;
      end if;
    end if;

    -- Si un plateau ou un poids plateau a été saisi alors on doit le déduire du poids matière
    lnFWE_WEIGHT_MAT  := lnFWE_WEIGHT_MAT - nvl(iFWE_PAN_WEIGHT, 0);
    return nvl(lnFWE_WEIGHT_MAT, 0);
  end CalcMatWeigh;

  /**
  * procedure GenerateNonGenericFalWeigh
  * Description : Procédure de génération de pesées
  *
  * @created eca 19.07/2012
  * @lastUpdate
  * @public
  */
  procedure GenerateNonGenericFalWeigh(
    iGCO_ALLOY_ID             in     number default null
  , iGCO_GOOD_ID              in     number default null
  , iDOC_DOCUMENT_ID          in     number default null
  , iDOC_POSITION_ID          in     number default null
  , iFAL_SCHEDULE_STEP_ID     in     number default null
  , iFAL_LOT_ID               in     number default null
  , iFAL_LOT_DETAIL_ID        in     number default null
  , iDIC_OPERATOR_ID          in     varchar2 default null
  , iFAL_POSITION1_ID         in     number default null
  , iFAL_POSITION2_ID         in     number default null
  , iFAL_LOT_MATERIAL_LINK_ID in     number default null
  , iFAL_LOT_PROGRESS_FOG_ID  in     number default null
  , iDOC_RECORD_ID            in     number default null
  , iSTM_ELEMENT_NUMBER_ID    in     number default null
  , iSTM_ELEMENT_NUMBER2_ID   in     number default null
  , iSTM_ELEMENT_NUMBER3_ID   in     number default null
  , iFWE_WASTE                in     integer default null
  , iFWE_TURNINGS             in     integer default null
  , iFWE_DATE                 in     date default null
  , iFWE_WEIGHT               in     number default null
  , iFWE_STONE_NUM            in     number default null
  , iFWE_COMMENT              in     varchar2 default null
  , iFWE_PIECE_QTY            in     number default null
  , iC_WEIGH_TYPE             in     varchar2 default null
  , iFAL_LOT_PROGRESS_ID      in     number default null
  , iFAL_SCALE_PAN_ID         in     number default null
  , iFWE_PAN_WEIGHT           in     number default null
  , iWeighingWithStone        in     integer default null
  , ioExitWeighId             in out number
  , ioEntryWeighId            in out number
  , ioErrorMsg                in out varchar2
  )
  is
    lnFAL_POSITION1_ID         number;
    lnFAL_POSITION2_ID         number;
    lvDIC_OPERATOR_ID          varchar2(10);
    lnDOC_DOCUMENT_ID          number;
    lnDOC_POSITION_ID          number;
    lnFAL_SCHEDULE_STEP_ID     number;
    lnFAL_LOT_ID               number;
    lnFAL_LOT_MATERIAL_LINK_ID number;
    lnFWE_WEIGH_MAT            number;
  begin
    lnFAL_POSITION1_ID          := iFAL_POSITION1_ID;
    lnFAL_POSITION2_ID          := iFAL_POSITION2_ID;
    lvDIC_OPERATOR_ID           := iDIC_OPERATOR_ID;
    lnDOC_DOCUMENT_ID           := iDOC_DOCUMENT_ID;
    lnDOC_POSITION_ID           := iDOC_POSITION_ID;
    lnFAL_SCHEDULE_STEP_ID      := iFAL_SCHEDULE_STEP_ID;
    lnFAL_LOT_ID                := iFAL_LOT_ID;
    lnFAL_LOT_MATERIAL_LINK_ID  := iFAL_LOT_MATERIAL_LINK_ID;
    lnFWE_WEIGH_MAT             := 0;
    -- Vérification de l'intégrité des données
    checkWeighingDataIntegrity(iGCO_ALLOY_ID
                             , iGCO_GOOD_ID
                             , iFAL_LOT_DETAIL_ID
                             , iFAL_LOT_PROGRESS_ID
                             , iFAL_SCALE_PAN_ID
                             , iFAL_LOT_PROGRESS_FOG_ID
                             , iDOC_RECORD_ID
                             , iSTM_ELEMENT_NUMBER_ID
                             , iSTM_ELEMENT_NUMBER2_ID
                             , iSTM_ELEMENT_NUMBER3_ID
                             , iFWE_WASTE
                             , iFWE_TURNINGS
                             , iFWE_DATE
                             , iFWE_WEIGHT
                             , iFWE_STONE_NUM
                             , iFWE_COMMENT
                             , iFWE_PIECE_QTY
                             , iC_WEIGH_TYPE
                             , iFWE_PAN_WEIGHT
                             , lnFAL_POSITION1_ID
                             , lnFAL_POSITION2_ID
                             , lvDIC_OPERATOR_ID
                             , lnDOC_DOCUMENT_ID
                             , lnDOC_POSITION_ID
                             , lnFAL_SCHEDULE_STEP_ID
                             , lnFAL_LOT_ID
                             , lnFAL_LOT_MATERIAL_LINK_ID
                             , ioErrorMsg
                              );

    -- Si pas de problème d'intégrité détecté
    if ioErrorMsg is null then
      -- Pesée d'entrée
      if lnFAL_POSITION1_ID is not null then
        -- Gestion problématique de sertissage
        lnFWE_WEIGH_MAT  :=
          CalcMatWeigh(iFWE_WEIGHT
                     , lnFAL_SCHEDULE_STEP_ID
                     , iWeighingWithStone
                     , iGCO_GOOD_ID
                     , iFWE_PIECE_QTY
                     , lnFAL_POSITION1_ID
                     , null
                     , (   nvl(lnFAL_POSITION1_ID, 0) = 0
                        or nvl(lnFAL_POSITION2_ID, 0) = 0)
                     , lnDOC_POSITION_ID
                     , iC_WEIGH_TYPE
                     , iFWE_WASTE
                     , iFWE_TURNINGS
                     , iFAL_LOT_ID
                     , iFWE_PAN_WEIGHT
                      );
        -- Insert pesée d'entrée
        InsertFalWeigh(iGCO_ALLOY_ID
                     , iGCO_GOOD_ID
                     , lvDIC_OPERATOR_ID
                     , lnFAL_LOT_ID
                     , lnFAL_SCHEDULE_STEP_ID
                     , lnDOC_POSITION_ID
                     , lnDOC_DOCUMENT_ID
                     , iDOC_RECORD_ID
                     , iSTM_ELEMENT_NUMBER_ID
                     , iSTM_ELEMENT_NUMBER2_ID
                     , iSTM_ELEMENT_NUMBER3_ID
                     , 1
                     , iFWE_WASTE
                     , iFWE_TURNINGS
                     , lnFAL_POSITION1_ID
                     , null
                     , iFWE_DATE
                     , iFWE_WEIGHT
                     , lnFWE_WEIGH_MAT
                     , iFWE_STONE_NUM
                     , iFWE_COMMENT
                     , iFWE_PIECE_QTY
                     , null
                     , iC_WEIGH_TYPE
                     , iFAL_LOT_PROGRESS_ID
                     , iFAL_LOT_PROGRESS_FOG_ID
                     , iFAL_SCALE_PAN_ID
                     , iFWE_PAN_WEIGHT
                     , lnFAL_LOT_MATERIAL_LINK_ID
                     , ioEntryWeighId
                      );
      end if;

      -- Pesée de sortie
      if lnFAL_POSITION2_ID is not null then
        -- Gestion problématique de sertissage
        lnFWE_WEIGH_MAT  :=
          CalcMatWeigh(iFWE_WEIGHT
                     , lnFAL_SCHEDULE_STEP_ID
                     , iWeighingWithStone
                     , iGCO_GOOD_ID
                     , iFWE_PIECE_QTY
                     , null
                     , lnFAL_POSITION2_ID
                     , (   nvl(lnFAL_POSITION1_ID, 0) = 0
                        or nvl(lnFAL_POSITION2_ID, 0) = 0)
                     , lnDOC_POSITION_ID
                     , iC_WEIGH_TYPE
                     , iFWE_WASTE
                     , iFWE_TURNINGS
                     , iFAL_LOT_ID
                     , iFWE_PAN_WEIGHT
                      );
        -- Insert pesée de sortie
        InsertFalWeigh(iGCO_ALLOY_ID
                     , iGCO_GOOD_ID
                     , lvDIC_OPERATOR_ID
                     , lnFAL_LOT_ID
                     , lnFAL_SCHEDULE_STEP_ID
                     , lnDOC_POSITION_ID
                     , lnDOC_DOCUMENT_ID
                     , iDOC_RECORD_ID
                     , iSTM_ELEMENT_NUMBER_ID
                     , iSTM_ELEMENT_NUMBER2_ID
                     , iSTM_ELEMENT_NUMBER3_ID
                     , 0
                     , iFWE_WASTE
                     , iFWE_TURNINGS
                     , null
                     , lnFAL_POSITION2_ID
                     , iFWE_DATE
                     , iFWE_WEIGHT
                     , lnFWE_WEIGH_MAT
                     , iFWE_STONE_NUM
                     , iFWE_COMMENT
                     , iFWE_PIECE_QTY
                     , null
                     , iC_WEIGH_TYPE
                     , iFAL_LOT_PROGRESS_ID
                     , iFAL_LOT_PROGRESS_FOG_ID
                     , iFAL_SCALE_PAN_ID
                     , iFWE_PAN_WEIGHT
                     , lnFAL_LOT_MATERIAL_LINK_ID
                     , ioEntryWeighId
                      );
      end if;
    end if;
  end GenerateNonGenericFalWeigh;

  /**
  * procedure GenerateFalWeigh
  * Description : Procédure de génération de pesées
  *
  * @created eca 19.07/2012
  * @lastUpdate
  * @public
  */
  procedure GenerateFalWeigh(
    iGCO_ALLOY_ID             in     number default null
  , iGCO_GOOD_ID              in     number default null
  , iDOC_DOCUMENT_ID          in     number default null
  , iDOC_POSITION_ID          in     number default null
  , iFAL_SCHEDULE_STEP_ID     in     number default null
  , iFAL_LOT_ID               in     number default null
  , iFAL_LOT_DETAIL_ID        in     number default null
  , iDIC_OPERATOR_ID          in     varchar2 default null
  , iFAL_POSITION1_ID         in     number default null
  , iFAL_POSITION2_ID         in     number default null
  , iFAL_LOT_MATERIAL_LINK_ID in     number default null
  , iFAL_LOT_PROGRESS_FOG_ID  in     number default null
  , iDOC_RECORD_ID            in     number default null
  , iSTM_ELEMENT_NUMBER_ID    in     number default null
  , iSTM_ELEMENT_NUMBER2_ID   in     number default null
  , iSTM_ELEMENT_NUMBER3_ID   in     number default null
  , iFWE_WASTE                in     integer default null
  , iFWE_TURNINGS             in     integer default null
  , iFWE_DATE                 in     date default null
  , iFWE_WEIGHT               in     number default null
  , iFWE_STONE_NUM            in     number default null
  , iFWE_COMMENT              in     varchar2 default null
  , iFWE_PIECE_QTY            in     number default null
  , iC_WEIGH_TYPE             in     varchar2 default null
  , iFAL_LOT_PROGRESS_ID      in     number default null
  , iFAL_SCALE_PAN_ID         in     number default null
  , iFWE_PAN_WEIGHT           in     number default null
  , iWeighingWithStone        in     integer default null
  , ioExitWeighId             in out number
  , ioEntryWeighId            in out number
  , ioErrorMsg                in out varchar2
  )
  is
    lvErrorMsg varchar2(4000);
  begin
    -- Si pesée sur alliage générique
    if iGCO_ALLOY_ID = GCO_I_LIB_ALLOY.getGenericAlloy then
      for TplGoodAlloy in (select PMA.GCO_ALLOY_ID
                                , nvl(GPM_WEIGHT_DELIVER, 0) / (select sum(GPM_WEIGHT_DELIVER)
                                                                  from GCO_PRECIOUS_MAT
                                                                 where GCO_GOOD_ID = iGCO_GOOD_ID) WEIGHT_RATIO
                             from GCO_PRECIOUS_MAT PMA
                                , GCO_ALLOY LOY
                            where PMA.GCO_GOOD_ID = iGCO_GOOD_ID
                              and PMA.GCO_ALLOY_ID = LOY.GCO_ALLOY_ID
                              and PMA.GPM_WEIGHT = 1
                              and nvl(LOY.GAL_GENERIC, 0) = 0
                              and PMA.GPM_REAL_WEIGHT = 1) loop
        GenerateNonGenericFalWeigh(TplGoodAlloy.GCO_ALLOY_ID
                                 , iGCO_GOOD_ID
                                 , iDOC_DOCUMENT_ID
                                 , iDOC_POSITION_ID
                                 , iFAL_SCHEDULE_STEP_ID
                                 , iFAL_LOT_ID
                                 , iFAL_LOT_DETAIL_ID
                                 , iDIC_OPERATOR_ID
                                 , iFAL_POSITION1_ID
                                 , iFAL_POSITION2_ID
                                 , iFAL_LOT_MATERIAL_LINK_ID
                                 , iFAL_LOT_PROGRESS_FOG_ID
                                 , iDOC_RECORD_ID
                                 , iSTM_ELEMENT_NUMBER_ID
                                 , iSTM_ELEMENT_NUMBER2_ID
                                 , iSTM_ELEMENT_NUMBER3_ID
                                 , iFWE_WASTE
                                 , iFWE_TURNINGS
                                 , iFWE_DATE
                                 , iFWE_WEIGHT * TplGoodAlloy.WEIGHT_RATIO
                                 , iFWE_STONE_NUM
                                 , iFWE_COMMENT
                                 , iFWE_PIECE_QTY
                                 , iC_WEIGH_TYPE
                                 , iFAL_LOT_PROGRESS_ID
                                 , iFAL_SCALE_PAN_ID
                                 , iFWE_PAN_WEIGHT
                                 , iWeighingWithStone
                                 , ioExitWeighId
                                 , ioEntryWeighId
                                 , lvErrorMsg
                                  );
        ioErrorMsg  := ioErrorMsg || chr(13) || chr(10) || lvErrorMsg;
      end loop;

      ioExitWeighId   := null;
      ioEntryWeighId  := null;
    else
      GenerateNonGenericFalWeigh(iGCO_ALLOY_ID
                               , iGCO_GOOD_ID
                               , iDOC_DOCUMENT_ID
                               , iDOC_POSITION_ID
                               , iFAL_SCHEDULE_STEP_ID
                               , iFAL_LOT_ID
                               , iFAL_LOT_DETAIL_ID
                               , iDIC_OPERATOR_ID
                               , iFAL_POSITION1_ID
                               , iFAL_POSITION2_ID
                               , iFAL_LOT_MATERIAL_LINK_ID
                               , iFAL_LOT_PROGRESS_FOG_ID
                               , iDOC_RECORD_ID
                               , iSTM_ELEMENT_NUMBER_ID
                               , iSTM_ELEMENT_NUMBER2_ID
                               , iSTM_ELEMENT_NUMBER3_ID
                               , iFWE_WASTE
                               , iFWE_TURNINGS
                               , iFWE_DATE
                               , iFWE_WEIGHT
                               , iFWE_STONE_NUM
                               , iFWE_COMMENT
                               , iFWE_PIECE_QTY
                               , iC_WEIGH_TYPE
                               , iFAL_LOT_PROGRESS_ID
                               , iFAL_SCALE_PAN_ID
                               , iFWE_PAN_WEIGHT
                               , iWeighingWithStone
                               , ioExitWeighId
                               , ioEntryWeighId
                               , ioErrorMsg
                                );
    end if;
  exception
    when others then
      ioErrorMsg  := ioErrorMsg || chr(13) || chr(10) || DBMS_UTILITY.FORMAT_ERROR_STACK || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
  end GenerateFalWeigh;
end FAL_PRC_WEIGH;
