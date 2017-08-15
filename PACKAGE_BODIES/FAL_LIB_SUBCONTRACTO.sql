--------------------------------------------------------
--  DDL for Package Body FAL_LIB_SUBCONTRACTO
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_SUBCONTRACTO" 
is
  /**
  * procedure CheckConfirmBST
  * Description
  *   Test que les documents de transfer de stock ans l'atelier sont confirm�
  *
  * @param   iLotId         Id du lot
  * @param   ioListNoCheckDocId      list des identifiant des document non valid�s
  */
  procedure CheckConfirmBST(iLotId fal_lot.fal_lot_id%type, ioListNoCheckDocNr in out varchar2)
  is
  begin
    for tplCheckConfirmBST in (select DOC.DMT_NUMBER
                                 from DOC_DOCUMENT DOC
                                    , DOC_POSITION POS
                                    , STM_MOVEMENT_KIND MOV
                                where
                                      -- position li� � des op�rations externes du lot
                                      POS.FAL_SCHEDULE_STEP_ID in(select FAL_SCHEDULE_STEP_ID
                                                                    from FAL_TASK_LINK TAL
                                                                   where TAL.FAL_LOT_ID = iLotId
                                                                     and TAL.C_TASK_TYPE = '2')
                                  and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
                                  -- document n'a pas �t� confirm�
                                  and DOC.C_DOCUMENT_STATUS = '01'
                                  and POS.STM_MOVEMENT_KIND_ID = MOV.STM_MOVEMENT_KIND_ID
                                  -- le mouvement  est li� � un transfert de stock stock sous-traitant -> stock atelier
                                  and MOV.MOK_BATCH_RECEIPT = 1) loop
      if ioListNoCheckDocNr is null then
        ioListNoCheckDocNr  := tplCheckConfirmBST.DMT_NUMBER;
      else
        ioListNoCheckDocNr  := ioListNoCheckDocNr || ',' || tplCheckConfirmBST.DMT_NUMBER;
      end if;
    end loop;
  end CheckConfirmBST;

  /**
  * Description
  *   Test si il existe des commandes au sous-traitant pour un lot ou pour une seule op�ration externe
  */
  procedure CheckExistsCST(
    iJobProgramId             fal_job_program.fal_job_program_id%type default null
  , iOrderId                  fal_order.fal_order_id%type default null
  , iLotId                    fal_lot.fal_lot_id%type default null
  , iOperId                   FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type default null
  , ioListNoCheckDocNr in out varchar2
  )
  is
    lnSUOOGaugeId number;
  begin
    -- Lecture de la config contenant le gabarit Commande sous-traitance
    lnSUOOGaugeId  := DOC_LIB_SUBCONTRACTO.getOrderGaugeID;

    if iJobProgramId is not null then
      for tplCheckExistsCST in (select   DOC.DMT_NUMBER
                                       , POS.POS_NUMBER
                                    from DOC_DOCUMENT DOC
                                       , DOC_POSITION POS
                                   where POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
                                     and DOC.DOC_GAUGE_ID = lnSUOOGaugeId
                                     -- position li� � des op�rations externes du lot
                                     and exists(
                                           select FAL_SCHEDULE_STEP_ID
                                             from FAL_TASK_LINK TAL
                                                , FAL_LOT LOT
                                            where TAL.FAL_LOT_ID = LOT.FAL_LOT_ID
                                              and LOT.FAL_JOB_PROGRAM_ID = iJobProgramId
                                              and TAL.FAL_SCHEDULE_STEP_ID = POS.FAL_SCHEDULE_STEP_ID)
                                order by DOC.DMT_NUMBER) loop
        if ioListNoCheckDocNr is null then
          ioListNoCheckDocNr  := tplCheckExistsCST.DMT_NUMBER || ' - ' || tplCheckExistsCST.POS_NUMBER;
        else
          ioListNoCheckDocNr  := ioListNoCheckDocNr || chr(13) || tplCheckExistsCST.DMT_NUMBER || ' - ' || tplCheckExistsCST.POS_NUMBER;
        end if;
      end loop;
    elsif iOrderId is not null then
      for tplCheckExistsCST in (select   DOC.DMT_NUMBER
                                       , POS.POS_NUMBER
                                    from DOC_DOCUMENT DOC
                                       , DOC_POSITION POS
                                   where POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
                                     and DOC.DOC_GAUGE_ID = lnSUOOGaugeId
                                     -- position li� � des op�rations externes du lot
                                     and exists(
                                           select FAL_SCHEDULE_STEP_ID
                                             from FAL_TASK_LINK TAL
                                                , FAL_LOT LOT
                                            where TAL.FAL_LOT_ID = LOT.FAL_LOT_ID
                                              and LOT.FAL_ORDER_ID = iOrderId
                                              and TAL.FAL_SCHEDULE_STEP_ID = POS.FAL_SCHEDULE_STEP_ID)
                                order by DOC.DMT_NUMBER) loop
        if ioListNoCheckDocNr is null then
          ioListNoCheckDocNr  := tplCheckExistsCST.DMT_NUMBER || ' - ' || tplCheckExistsCST.POS_NUMBER;
        else
          ioListNoCheckDocNr  := ioListNoCheckDocNr || chr(13) || tplCheckExistsCST.DMT_NUMBER || ' - ' || tplCheckExistsCST.POS_NUMBER;
        end if;
      end loop;
    elsif iLotId is not null then
      for tplCheckExistsCST in (select   DOC.DMT_NUMBER
                                       , POS.POS_NUMBER
                                    from DOC_DOCUMENT DOC
                                       , DOC_POSITION POS
                                   where POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
                                     and DOC.DOC_GAUGE_ID = lnSUOOGaugeId
                                     -- position li� � des op�rations externes du lot
                                     and exists(select FAL_SCHEDULE_STEP_ID
                                                  from FAL_TASK_LINK TAL
                                                 where TAL.FAL_LOT_ID = iLotId
                                                   and TAL.FAL_SCHEDULE_STEP_ID = POS.FAL_SCHEDULE_STEP_ID)
                                order by DOC.DMT_NUMBER) loop
        if ioListNoCheckDocNr is null then
          ioListNoCheckDocNr  := tplCheckExistsCST.DMT_NUMBER || ' - ' || tplCheckExistsCST.POS_NUMBER;
        else
          ioListNoCheckDocNr  := ioListNoCheckDocNr || chr(13) || tplCheckExistsCST.DMT_NUMBER || ' - ' || tplCheckExistsCST.POS_NUMBER;
        end if;
      end loop;
    elsif iOperId is not null then
      for tplCheckExistsCST in (select   DOC.DMT_NUMBER
                                       , POS.POS_NUMBER
                                    from DOC_DOCUMENT DOC
                                       , DOC_POSITION POS
                                   where POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
                                     and DOC.DOC_GAUGE_ID = lnSUOOGaugeId
                                     and POS.FAL_SCHEDULE_STEP_ID = iOperId
                                order by DOC.DMT_NUMBER) loop
        if ioListNoCheckDocNr is null then
          ioListNoCheckDocNr  := tplCheckExistsCST.DMT_NUMBER || ' - ' || tplCheckExistsCST.POS_NUMBER;
        else
          ioListNoCheckDocNr  := ioListNoCheckDocNr || chr(13) || tplCheckExistsCST.DMT_NUMBER || ' - ' || tplCheckExistsCST.POS_NUMBER;
        end if;
      end loop;
    end if;
  end CheckExistsCST;

  /**
  * Description
  *    Retourne l'ID de la t�che externe li�e au composant de lot.
  */
  function getCptLinkedExtTaskID(
    iCptGoodID in GCO_GOOD.GCO_GOOD_ID%type
  , iLotID     in FAL_LOT_MATERIAL_LINK.FAL_LOT_ID%type default null
  , iLotPropID in FAL_LOT_MAT_LINK_PROP.FAL_LOT_PROP_ID%type default null
  )
    return FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  as
    lTaskLinkID FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type;
  begin
    if iLotID is not null then
      select tal.FAL_SCHEDULE_STEP_ID
        into lTaskLinkID
        from FAL_LOT_MATERIAL_LINK lom
           , FAL_TASK_LINK tal
       where lom.FAL_LOT_ID = iLotID
         and lom.GCO_GOOD_ID = iCptGoodID
         and lom.FAL_LOT_ID = tal.FAL_LOT_ID
         and lom.LOM_TASK_SEQ = tal.SCS_STEP_NUMBER
         and tal.C_TASK_TYPE = '2';
    elsif iLotPropID is not null then
      select tal.FAL_TASK_LINK_PROP_ID
        into lTaskLinkID
        from FAL_LOT_MAT_LINK_PROP lom
           , FAL_TASK_LINK_PROP tal
       where lom.FAL_LOT_PROP_ID = iLotPropID
         and lom.GCO_GOOD_ID = iCptGoodID
         and lom.FAL_LOT_PROP_ID = tal.FAL_LOT_PROP_ID
         and lom.LOM_TASK_SEQ = tal.SCS_STEP_NUMBER
         and tal.C_TASK_TYPE = '2';
    else
      ra('PCS - iLotID or iLotPropID are mandatory to call function FAL_LIB_SUBCONTRACTO.getCptLinkedExtTaskID');
    end if;

    return lTaskLinkID;
  exception
    when no_data_found then
      return null;
  end getCptLinkedExtTaskID;

  /**
  * Description
  *    Retourne l'ID du stock sous-traitant li� � l'op�ration externe du composant
  *    du lot ou de la proposition de lot.
  */
  function getStockSubcontractO(
    iCptGoodID in GCO_GOOD.GCO_GOOD_ID%type
  , iLotID     in FAL_LOT_MATERIAL_LINK.FAL_LOT_ID%type default null
  , iLotPropID in FAL_LOT_MAT_LINK_PROP.FAL_LOT_PROP_ID%type default null
  )
    return STM_STOCK.STM_STOCK_ID%type deterministic
  as
    lStockSubcontractO STM_STOCK.STM_STOCK_ID%type;
    lTaskLinkID        FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type;
  begin
    /* R�cup�ration de l'ID de l'op�ration externe li�e au composant */
    lTaskLinkID  := getCptLinkedExtTaskID(iCptGoodID => iCptGoodID, iLotID => iLotID, iLotPropID => iLotPropID);

    if iLotID is not null then
      select STM_I_LIB_STOCK.getSubCStockID(iSupplierId => PAC_SUPPLIER_PARTNER_ID)
        into lStockSubcontractO
        from FAL_TASK_LINK
       where FAL_SCHEDULE_STEP_ID = lTaskLinkID;
    elsif iLotPropID is not null then
      select STM_I_LIB_STOCK.getSubCStockID(iSupplierId => PAC_SUPPLIER_PARTNER_ID)
        into lStockSubcontractO
        from FAL_TASK_LINK_PROP
       where FAL_TASK_LINK_PROP_ID = lTaskLinkID;
    else
      ra('PCS - iLotID or iLotPropID are mandatory to call function FAL_LIB_SUBCONTRACTO.GetStockSubcontractO');
    end if;

    return lStockSubcontractO;
  exception
    when no_data_found then
      return null;
  end getStockSubcontractO;

  /**
  * Description
  *    Retourne la description du stock sous-traitant li� � l'op�ration externe
  *    du composant du lot ou de la proposition de lot.
  */
  function getStockSubcontractODescr(
    iCptGoodID in GCO_GOOD.GCO_GOOD_ID%type
  , iLotID     in FAL_LOT_MATERIAL_LINK.FAL_LOT_ID%type default null
  , iLotPropID in FAL_LOT_MAT_LINK_PROP.FAL_LOT_PROP_ID%type default null
  )
    return STM_STOCK.STO_DESCRIPTION%type
  as
  begin
    return STM_I_LIB_STOCK.getStockDescr(iStockID => getStockSubcontractO(iCptGoodID => iCptGoodID, iLotID => iLotID, iLotPropID => iLotPropID) );
  end getStockSubcontractODescr;

  /**
  * Description
  *    Retourne l'ID de l'emplacement de stock du sous-traitant li� � l'op�ration
  *    externe du composant du lot ou de la proposition de lot.
  */
  function getLocationSubContractO(
    iCptGoodID in GCO_GOOD.GCO_GOOD_ID%type
  , iLotID     in FAL_LOT_MATERIAL_LINK.FAL_LOT_ID%type default null
  , iLotPropID in FAL_LOT_MAT_LINK_PROP.FAL_LOT_PROP_ID%type default null
  , iStockID   in STM_STOCK.STM_STOCK_ID%type default null
  )
    return STM_LOCATION.STM_LOCATION_ID%type
  as
    lStockID STM_STOCK.STM_STOCK_ID%type;
  begin
    /* D�finition de l'ID du stock */
    if IStockID is null then
      lStockID  := getStockSubcontractO(iCptGoodID => iCptGoodID, iLotID => iLotID, iLotPropID => iLotPropID);
    else
      lStockID  := IStockID;
    end if;

    return STM_I_LIB_STOCK.getDefaultLocation(iStockId => lStockID);
  end getLocationSubContractO;

  /**
  * Description
  *    Retourne la description de l'emplacement de stock du sous-traitant li� �
  *    l'op�ration externe du composant du lot ou de la proposition de lot.
  */
  function getLocationSubContractODescr(
    iCptGoodID in GCO_GOOD.GCO_GOOD_ID%type
  , iLotID     in FAL_LOT_MATERIAL_LINK.FAL_LOT_ID%type default null
  , iLotPropID in FAL_LOT_MAT_LINK_PROP.FAL_LOT_PROP_ID%type default null
  , iStockID   in STM_STOCK.STM_STOCK_ID%type default null
  )
    return STM_STOCK.STO_DESCRIPTION%type
  as
  begin
    return STM_I_LIB_STOCK.getLocationDescr(iLocationID   => getLocationSubContractO(iCptGoodID   => iCptGoodID
                                                                                   , iLotID       => iLotID
                                                                                   , iLotPropID   => iLotPropID
                                                                                   , iStockID     => iStockID
                                                                                    )
                                           );
  end getLocationSubContractODescr;

  /**
  * Description
  *    Retourne la quantit� consomm�e, c-�-d. la quantit� de composants d�j� sous-trait�s.
  *    = Quantit� des BST d�j� r�ceptionn�s. Cette quantit� doit se trouver en stcok
  *    atelier => Somme des entr�es ateliers pour ce cpt et ce lot.)
  */
  function getStockSubCOConsumedQty(
    iCptGoodID in GCO_GOOD.GCO_GOOD_ID%type
  , iLotID     in FAL_LOT_MATERIAL_LINK.FAL_LOT_Id%type default null
  , iLotPropID in FAL_LOT_MAT_LINK_PROP.FAL_LOT_PROP_ID%type default null
  )
    return FAL_FACTORY_IN.IN_IN_QTE%type
  as
    lStockSubCOConsumedQty FAL_FACTORY_IN.IN_IN_QTE%type;
  begin
    if iLotID is not null then
      select nvl(sum(IN_IN_QTE), 0)   --> IN_IN_QTE ou IN_BALANCE ??
        into lStockSubCOConsumedQty
        from FAL_FACTORY_IN
       where FAL_LOT_ID = iLotID
         and GCO_GOOD_ID = iCptGoodID;
    else
      lStockSubCOConsumedQty  := 0;
    end if;

    return lStockSubCOConsumedQty;
  end getStockSubCOConsumedQty;

  /**
  * Description
  *    Retourne la quantit� attribu�e sur le stock sous-traitant pour le besoin
  *    du bien du composant de lot ou de proposition de lot.
  */
  function getStockSubCOAttribQty(
    iCptGoodID in GCO_GOOD.GCO_GOOD_ID%type
  , iLotID     in FAL_LOT_MATERIAL_LINK.FAL_LOT_Id%type default null
  , iLotPropID in FAL_LOT_MAT_LINK_PROP.FAL_LOT_PROP_ID%type default null
  , iStockID   in STM_STOCK.STM_STOCK_ID%type default null
  )
    return FAL_NETWORK_LINK.FLN_QTY%type
  as
    lStockID STM_STOCK.STM_STOCK_ID%type;
  begin
    /* D�finition de l'ID du stock */
    if IStockID is null then
      lStockID  := getStockSubcontractO(iCptGoodID => iCptGoodID, iLotID => iLotID, iLotPropID => iLotPropID);
    else
      lStockID  := IStockID;
    end if;

    return FAL_LIB_ATTRIB.getStockAttribQtyByCptGoodNeed(iStockID => lStockID, iCptGoodID => iCptGoodID, iLotID => iLotID, iLotPropID => iLotPropID);
  end getStockSubCOAttribQty;

  /**
  * Description
  *    Retourne la quantit� disponible sur le stock sous-traitant pour le bien
  *    du composant de lot ou de proposition de lot. Possibilit� de restreindre
  *    la somme sur les charact�risations.
  */
  function getStockSubCOAvailableQty(
    iCptGoodID              in GCO_GOOD.GCO_GOOD_ID%type
  , iCharacterizationID1    in STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type default null
  , iCharacterizationID2    in STM_STOCK_POSITION.GCO_GCO_CHARACTERIZATION_ID%type default null
  , iCharacterizationID3    in STM_STOCK_POSITION.GCO2_GCO_CHARACTERIZATION_ID%type default null
  , iCharacterizationID4    in STM_STOCK_POSITION.GCO3_GCO_CHARACTERIZATION_ID%type default null
  , iCharacterizationID5    in STM_STOCK_POSITION.GCO4_GCO_CHARACTERIZATION_ID%type default null
  , iCharacterizationValue1 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type default null
  , iCharacterizationValue2 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type default null
  , iCharacterizationValue3 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type default null
  , iCharacterizationValue4 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type default null
  , iCharacterizationValue5 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type default null
  , iLotID                  in FAL_LOT_MATERIAL_LINK.FAL_LOT_Id%type default null
  , iLotPropID              in FAL_LOT_MAT_LINK_PROP.FAL_LOT_PROP_ID%type default null
  )
    return STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type
  as
    lStockID    STM_STOCK.STM_STOCK_ID%type;
    lLocationID STM_LOCATION.STM_LOCATION_ID%type;
  begin
    /* Recherche de l'ID du stock sous-traitant et de son emplacement */
    lStockID     := getStockSubcontractO(iCptGoodID => iCptGoodID, iLotID => iLotID, iLotPropID => iLotPropID);
    lLocationID  := getLocationSubContractO(iCptGoodID => iCptGoodID, iLotID => iLotID, iLotPropID => iLotPropID, iStockID => lStockID);
    return STM_I_LIB_STOCK_POSITION.getSumAvailableQty(iGoodID                   => iCptGoodID
                                                     , iStockID                  => lStockID
                                                     , iLocationID               => lLocationID
                                                     , iCharacterizationID1      => iCharacterizationID1
                                                     , iCharacterizationID2      => iCharacterizationID2
                                                     , iCharacterizationID3      => iCharacterizationID3
                                                     , iCharacterizationID4      => iCharacterizationID4
                                                     , iCharacterizationID5      => iCharacterizationID5
                                                     , iCharacterizationValue1   => iCharacterizationValue1
                                                     , iCharacterizationValue2   => iCharacterizationValue2
                                                     , iCharacterizationValue3   => iCharacterizationValue3
                                                     , iCharacterizationValue4   => iCharacterizationValue4
                                                     , iCharacterizationValue5   => iCharacterizationValue5
                                                      );
  end getStockSubCOAvailableQty;

  /**
  * Description
  *    Retourne la quantit� disponible sur le stock sous-traitant pour le bien
  *    du composant de lot ou de proposition de lot. Possibilit� de restreindre
  *    la somme sur les charact�risations.
  */
  function getStockSubCOStockQty(
    iCptGoodID              in GCO_GOOD.GCO_GOOD_ID%type
  , iCharacterizationID1    in STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type default null
  , iCharacterizationID2    in STM_STOCK_POSITION.GCO_GCO_CHARACTERIZATION_ID%type default null
  , iCharacterizationID3    in STM_STOCK_POSITION.GCO2_GCO_CHARACTERIZATION_ID%type default null
  , iCharacterizationID4    in STM_STOCK_POSITION.GCO3_GCO_CHARACTERIZATION_ID%type default null
  , iCharacterizationID5    in STM_STOCK_POSITION.GCO4_GCO_CHARACTERIZATION_ID%type default null
  , iCharacterizationValue1 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type default null
  , iCharacterizationValue2 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type default null
  , iCharacterizationValue3 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type default null
  , iCharacterizationValue4 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type default null
  , iCharacterizationValue5 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type default null
  , iLotID                  in FAL_LOT_MATERIAL_LINK.FAL_LOT_Id%type default null
  , iLotPropID              in FAL_LOT_MAT_LINK_PROP.FAL_LOT_PROP_ID%type default null
  )
    return STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type
  as
    lStockID    STM_STOCK.STM_STOCK_ID%type;
    lLocationID STM_LOCATION.STM_LOCATION_ID%type;
  begin
    /* Recherche de l'ID du stock sous-traitant et de son emplacement */
    lStockID     := getStockSubcontractO(iCptGoodID => iCptGoodID, iLotID => iLotID, iLotPropID => iLotPropID);
    lLocationID  := getLocationSubContractO(iCptGoodID => iCptGoodID, iLotID => iLotID, iLotPropID => iLotPropID, iStockID => lStockID);
    return STM_I_LIB_STOCK_POSITION.getSumStockQty(iGoodID                   => iCptGoodID
                                                 , iStockID                  => lStockID
                                                 , iLocationID               => lLocationID
                                                 , iCharacterizationID1      => iCharacterizationID1
                                                 , iCharacterizationID2      => iCharacterizationID2
                                                 , iCharacterizationID3      => iCharacterizationID3
                                                 , iCharacterizationID4      => iCharacterizationID4
                                                 , iCharacterizationID5      => iCharacterizationID5
                                                 , iCharacterizationValue1   => iCharacterizationValue1
                                                 , iCharacterizationValue2   => iCharacterizationValue2
                                                 , iCharacterizationValue3   => iCharacterizationValue3
                                                 , iCharacterizationValue4   => iCharacterizationValue4
                                                 , iCharacterizationValue5   => iCharacterizationValue5
                                                  );
  end getStockSubCOStockQty;

  /**
  * Description
  *    Retourne les IDs des op�rations externes (C_TASK_TYPE = 2) du lot
  */
  function getExternalTaskIDs(iLotID in FAL_LOT.FAL_LOT_ID%type)
    return ID_TABLE_TYPE pipelined deterministic
  as
  begin
    for ltplTaskLinkID in (select   tal.FAL_SCHEDULE_STEP_ID
                               from FAL_TASK_LINK tal
                              where tal.FAL_LOT_ID = iLotID
                                and tal.C_TASK_TYPE = '2'
                           order by tal.SCS_STEP_NUMBER) loop
      pipe row(ltplTaskLinkID.FAL_SCHEDULE_STEP_ID);
    end loop;
  exception
    when NO_DATA_NEEDED then
      return;
  end getExternalTaskIDs;

  /**
  * Description
  *    Retourne 1 si au moins un des suivis r�alis�s apr�s le suivi transmis en param�tre � �t� r�alis�
  *    par un document de sous-traitance.
  */
  function hasFolowingTrackFromStoDmt(iLotID in FAL_LOT_PROGRESS.FAL_LOT_ID%type, iLotProgressID in FAL_LOT_PROGRESS.FAL_LOT_PROGRESS_ID%type)
    return number
  as
    hasFolowingTrackFromStoDmt number;
  begin
    select sign(count(flpIDs.column_value) )
      into hasFolowingTrackFromStoDmt
      from table(FAL_LIB_LOT_PROGRESS.getFollowingProcessTrackings(iLotID => iLotID, iLotProgressID => iLotProgressID) ) flpIDs
         , FAL_LOT_PROGRESS flp
         , DOC_POSITION_DETAIL pde
         , DOC_POSITION pos
         , STM_MOVEMENT_KIND mok
         , FAL_TASK_LINK tal
     where flp.FAL_LOT_PROGRESS_ID = flpIDs.column_value
       and pde.FAL_SCHEDULE_STEP_ID = flp.FAL_SCHEDULE_STEP_ID
       and tal.FAL_SCHEDULE_STEP_ID = flp.FAL_SCHEDULE_STEP_ID
       and pos.DOC_POSITION_ID = pde.DOC_POSITION_ID
       and mok.STM_MOVEMENT_KIND_ID = pos.STM_MOVEMENT_KIND_ID
       and tal.C_TASK_TYPE = '2'
       and mok.MOK_UPDATE_OP = 1;

    return hasFolowingTrackFromStoDmt;
  exception
    when no_data_found then
      return 0;
  end hasFolowingTrackFromStoDmt;

  /**
  * Description
  *   Retourne la quantit� non encore trait�e pour une op�ration
  *   Selon que les mouvements de stock ont �t�s effectu�s
  */
  function GetOperationBalanceQty(iFalScheduleStepId in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return number
  is
    lSUOOQty FAL_TASK_LINK.TAL_PLAN_QTY%type           := DOC_I_LIB_SUBCONTRACTO.GetOperationSUOOQty(iFalScheduleStepId);
    lMvtQty  DOC_POSITION.POS_BASIS_QUANTITY_SU%type   := DOC_I_LIB_SUBCONTRACTO.GetOperationMvtQty(iFalScheduleStepId);
  begin
    -- retourne pas moins de 0, cela signifie qu'on a fait une d�charge avec d�passement de qt�
    return greatest(lSUOOQty - lMvtQty, 0);
  end GetOperationBalanceQty;

  /**
  * Description
  *   Retourne le montant de l'op�ration ( null si rien trouv�)
  */
  function GetOperationPrice(iFalScheduleStepId in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type, iQuantity DOC_POSITION.POS_BASIS_QUANTITY%type)
    return number
  is
    lResult    FAL_TASK_LINK.SCS_AMOUNT%type;
    lScsAmount FAL_TASK_LINK.SCS_AMOUNT%type;
    lnQtyRef   FAL_TASK_LINK.SCS_QTY_REF_AMOUNT%type;   -- La qt� r�f montant
    lnDivisor  FAL_TASK_LINK.SCS_DIVISOR_AMOUNT%type;   -- Diviseur
  begin
    select nvl(SCS_AMOUNT, 0) SCS_AMOUNT
         , SCS_QTY_REF_AMOUNT
         , SCS_DIVISOR_AMOUNT
      into lScsAmount
         , lnQtyRef
         , lnDivisor
      from FAL_TASK_LINK
     where FAL_SCHEDULE_STEP_ID = iFalScheduleStepId;

    -- Si on a trouv� qqch
    if (lScsAmount <> 0) then
      if lnDivisor = 1 then
        lResult  := (iQuantity / lnQtyRef) * lScsAmount;
      else
        lResult  := lnQtyRef * lScsAmount * iQuantity;
      end if;
    end if;

    return lResult;
  end GetOperationPrice;

  /**
  * procedure GetBatchOriginDocument
  * Description : Recherche du document d'origine de type CST, g�n�rer depuis l'op�ration externe sp�cifi�
  */
  procedure GetBatchOriginDocument(iFalTaskLinkId in number, ioDocDocumentId in out number, ioDocPositionId in out number)
  is
  begin
    ioDocDocumentId  := null;
    ioDocPositionId  := null;

    for tplOriginDoc in (select DOC.DOC_DOCUMENT_ID
                              , POS.DOC_POSITION_ID
                           from DOC_POSITION POS
                              , DOC_DOCUMENT DOC
                              , table(DOC_LIB_SUBCONTRACTO.GetSUOOGaugeId(DOC.PAC_THIRD_ID) ) DocGauge
                          where POS.FAL_LOT_ID is null
                            and POS.FAL_SCHEDULE_STEP_ID = iFalTaskLinkId
                            and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
                            and DOC.DOC_GAUGE_ID = DocGauge.column_value) loop
      ioDocDocumentId  := tplOriginDoc.DOC_DOCUMENT_ID;
      ioDocPositionId  := tplOriginDoc.DOC_POSITION_ID;
      exit;
    end loop;
  end GetBatchOriginDocument;

  /**
  * Description
  *     Retourne la commande SQL pacourant les op�rations plac�es en amont ou en aval entre l'op�ration � confirmer
  *     et l'�ventuelle prochaine autre op�ration confirm�e. Ne retourne rien si aucune autre op�ration n'est confirm�e
  *     en amont/aval
  */
  function getSqlTasks(iIsBatch boolean, iBackwardSearch boolean)
    return varchar2
  is
    lvSql varchar2(32000);
  begin
    -- Parcours des op�rations plac�es entre une prochaine op�ration externe confirm�e et l'op�ration � confirmer.
    -- Recherche en amont ou en aval selon iBackwardSearch.
    lvSql  :=
      'select FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID ' ||
      '     , FAL_TASK_LINK.SCS_STEP_NUMBER ' ||
      '     , nvl(FAL_TASK_LINK.TAL_TASK_MANUF_TIME, 0) ' ||
      '     , FAL_TASK_LINK.C_RELATION_TYPE ' ||
      '     , FAL_TASK_LINK.FAL_FACTORY_FLOOR_ID ' ||
      '     , FAL_TASK_LINK.SCS_OPEN_TIME_MACHINE ' ||
      '     , FAL_TASK_LINK.TAL_TSK_AD_BALANCE ' ||
      '     , FAL_TASK_LINK.TAL_TSK_W_BALANCE ' ||
      '     , FAL_FACTORY_FLOOR.FAC_DAY_CAPACITY ' ||
      '     , nvl(FAL_TASK_LINK.SCS_TRANSFERT_TIME, 0) ' ||
      '     , nvl(FAL_TASK_LINK.TAL_NUM_UNITS_ALLOCATED, 1) ' ||
      '     , nvl(FAL_TASK_LINK.SCS_DELAY, 0) ' ||
      '     , FAL_TASK_LINK.TAL_END_PLAN_DATE ' ||
      '     , FAL_TASK_LINK.TAL_BEGIN_PLAN_DATE ' ||
      '  from FAL_TASK_LINK ' ||
      '     , FAL_FACTORY_FLOOR ' ||
      ' where FAL_TASK_LINK.FAL_FACTORY_FLOOR_ID = FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID ' ||
      '   and FAL_TASK_LINK.FAL_LOT_ID = :iBatchId ';

    if iBackwardSearch then
      lvSql  :=
        lvSql ||
        '   and FAL_TASK_LINK.SCS_STEP_NUMBER < :iSequence ' ||
        '   and FAL_TASK_LINK.SCS_STEP_NUMBER > ' ||
        '         (select nvl(max(SCS_STEP_NUMBER), 1000000000) ' ||
        '            from FAL_TASK_LINK ' ||
        '           where FAL_LOT_ID = :iBatchId ' ||
        '             and C_TASK_TYPE = ''2'' ' ||
        '             and SCS_STEP_NUMBER < :iSequence ' ||
        '             and TAL_CONFIRM_DATE is not null ' ||
        '             and (    (nvl(TAL_DUE_QTY, 0) > 0) ' ||
        '                  or (nvl(TAL_SUBCONTRACT_QTY, 0) > 0) ) ) ' ||
        ' order by FAL_TASK_LINK.SCS_STEP_NUMBER desc ';
    else
      lvSql  :=
        lvSql ||
        '   and FAL_TASK_LINK.SCS_STEP_NUMBER > :iSequence ' ||
        '   and FAL_TASK_LINK.SCS_STEP_NUMBER < ' ||
        '         (select nvl(min(SCS_STEP_NUMBER), 0) ' ||
        '            from FAL_TASK_LINK ' ||
        '           where FAL_LOT_ID = :iBatchId ' ||
        '             and C_TASK_TYPE = ''2'' ' ||
        '             and SCS_STEP_NUMBER > :iSequence ' ||
        '             and TAL_CONFIRM_DATE is not null ' ||
        '             and (    (nvl(TAL_DUE_QTY, 0) > 0) ' ||
        '                  or (nvl(TAL_SUBCONTRACT_QTY, 0) > 0) ) ) ' ||
        ' order by FAL_TASK_LINK.SCS_STEP_NUMBER asc ';
    end if;

    if not iIsBatch then
      lvSql  := replace(lvSql, 'FAL_SCHEDULE_STEP_ID', 'FAL_TASK_LINK_PROP_ID');
      lvSql  := replace(lvSql, 'FAL_TASK_LINK', 'FAL_TASK_LINK_PROP');
      lvSql  := replace(lvSql, 'FAL_LOT_ID', 'FAL_LOT_PROP_ID');
    end if;

    return lvSql;
  end getSqlTasks;

  /**
  * Description
  *     Retourne la dur�e de l'op�ration de lot transmise en param�tre. Dans le cadre de la sous-traitance op�ratoire,
  *     on admet que si sa gamme est planifi�e 'selon produit', sa dur�e est �gale � la valeur du champ 'planification'
  *     (TAL_PLAN_RATE). Sinon, sa dur�e et �gale � la valeur du champ TAL_TASK_MANUF_TIME.
  */
  function getTaskDuration(iScheduleStepId in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return number
  as
    lDuration number;
  begin
    select case lot.C_SCHEDULE_PLANNING
             when '1' then TAL_PLAN_RATE
             else TAL_TASK_MANUF_TIME
           end
      into lDuration
      from FAL_TASK_LINK tal
         , FAL_LOT lot
     where lot.FAL_LOT_ID = tal.FAL_LOT_ID
       and tal.FAL_SCHEDULE_STEP_ID = iScheduleStepId;

    return lDuration;
  end getTaskDuration;
end FAL_LIB_SUBCONTRACTO;
