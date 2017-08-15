--------------------------------------------------------
--  DDL for Package Body FAL_PRC_DRP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_DRP" 
is
  /**
  * procedure CtrlDrpPolicies
  * Description
  *   Controles des règles DRP
  * @created fp 27.05.2009
  * @lastUpdate
  * @public
  * @param iotMovementRecord tuple du mouvement
  */
  procedure CtrlDrpPolicies(iotMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement)
  is
    lUseRestocking integer;
    lMovementSort  varchar2(10);
    lDiuId         number;
    lDiuReapproId  number;
    lDicCDD        varchar2(10);
    lDocumentId    number;
  begin
    -- recherche d'informations concernant les genres de mouvements
    select C_MOVEMENT_SORT
         , MOK_USE_RESTOCKING
      into lMovementSort
         , lUseRestocking
      from STM_MOVEMENT_KIND
     where STM_MOVEMENT_KIND_ID = iotMovementRecord.STM_MOVEMENT_KIND_ID;

    if (lUseRestocking = 1) then
      begin
        select DIU.STM_DISTRIBUTION_UNIT_ID
             , DIU.STM_STM_DISTRIBUTION_UNIT_ID
             , DIU.DIC_DISTRIB_COMPL_DATA_ID
          into lDiuId
             , lDiuReapproId
             , lDicCDD
          from STM_DISTRIBUTION_UNIT DIU
         where DIU.STM_STOCK_ID = iotMovementRecord.STM_STOCK_ID
           and DIU.C_DRP_UNIT_TYPE <> '0';
      exception
        when no_data_found then
          begin
            lDiuId         := null;
            lDiuReapproId  := null;
            lDicCDD        := null;
          end;
      end;

      iotMovementRecord.SMO_USE_RESTOCKING            := 1;
      iotMovementRecord.STM_DISTRIBUTION_UNIT_ID      := lDiuId;
      iotMovementRecord.STM_STM_DISTRIBUTION_UNIT_ID  := lDiuReapproId;

      if (lDiuId is not null) then
        if lMovementSort = 'SOR' then
          -- Mouvement de sortie
          FAL_DRP_FUNCTIONS.CtrlRegleApproSortie(iotMovementRecord.GCO_GOOD_ID
                                               , lDiuId   -- Unité Distribution
                                               , lDiuReapproId   -- Unité Distribution Reappro
                                               , lDicCDD   -- Dic Distrib Compl Data
                                               , iotMovementRecord.STM_STOCK_MOVEMENT_ID
                                               , iotMovementRecord.GCO_CHARACTERIZATION_ID
                                               , iotMovementRecord.GCO_GCO_CHARACTERIZATION_ID
                                               , iotMovementRecord.GCO2_GCO_CHARACTERIZATION_ID
                                               , iotMovementRecord.GCO3_GCO_CHARACTERIZATION_ID
                                               , iotMovementRecord.GCO4_GCO_CHARACTERIZATION_ID
                                               , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_1
                                               , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_2
                                               , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_3
                                               , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_4
                                               , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_5
                                               , iotMovementRecord.DOC_RECORD_ID
                                               , iotMovementRecord.SMO_MOVEMENT_QUANTITY
                                               , iotMovementRecord.SMO_MOVEMENT_DATE
                                                );
        else
          -- Mouvement d'entrée

          -- Retrouver le document
          select DOC_DOCUMENT_ID
            into lDocumentId
            from DOC_POSITION_DETAIL
           where DOC_POSITION_DETAIL_ID = iotMovementRecord.DOC_POSITION_DETAIL_ID;

          FAL_DRP_FUNCTIONS.CtrlRegleApproEntree(iotMovementRecord.GCO_GOOD_ID
                                               , lDiuId   -- Unité Distribution
                                               , lDiuReapproId   -- Unité Distribution Reappro
                                               , lDicCDD   -- Dic Distrib Compl Data
                                               , iotMovementRecord.GCO_CHARACTERIZATION_ID
                                               , iotMovementRecord.GCO_GCO_CHARACTERIZATION_ID
                                               , iotMovementRecord.GCO2_GCO_CHARACTERIZATION_ID
                                               , iotMovementRecord.GCO3_GCO_CHARACTERIZATION_ID
                                               , iotMovementRecord.GCO4_GCO_CHARACTERIZATION_ID
                                               , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_1
                                               , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_2
                                               , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_3
                                               , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_4
                                               , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_5
                                               , lDocumentId
                                               , iotMovementRecord.SMO_MOVEMENT_QUANTITY
                                                );
        end if;
      end if;
    end if;
  end CtrlDrpPolicies;

  /**
  * Description
  *     WRAPPER: Insertion d'une demande de réapprovisionnement (FAL_DOC_PROP)
  */
  procedure InsertMovementRequest(
    iGoodId                in     FAL_DOC_PROP.GCO_GOOD_ID%type
  , iStockMovementId       in     FAL_DOC_PROP.STM_STOCK_MOVEMENT_ID%type
  , iDiuId                 in     STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type
  , iDicDistribComplData   in     GCO_COMPL_DATA_DISTRIB.DIC_DISTRIB_COMPL_DATA_ID%type
  , iQuantity              in     FAL_DOC_PROP.FDP_BASIS_QTY%type
  , iBasisDelay            in     FAL_DOC_PROP.FDP_BASIS_DELAY%type
  , iDocRecordId           in     STM_STOCK_MOVEMENT.doc_record_id%type
  , iGcoChar1              in     FAL_DOC_PROP.GCO_CHARACTERIZATION1_ID%type
  , iGcoChar2              in     FAL_DOC_PROP.GCO_CHARACTERIZATION2_ID%type
  , iGcoChar3              in     FAL_DOC_PROP.GCO_CHARACTERIZATION3_ID%type
  , iGcoChar4              in     FAL_DOC_PROP.GCO_CHARACTERIZATION4_ID%type
  , iGcoChar5              in     FAL_DOC_PROP.GCO_CHARACTERIZATION5_ID%type
  , iFdpChar1              in     FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_1%type
  , iFdpChar2              in     FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_2%type
  , iFdpChar3              in     FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_3%type
  , iFdpChar4              in     FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_4%type
  , iFdpChar5              in     FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_5%type
  , oResult                out    integer
  , iFAL_SUPPLY_REQUEST_ID in     FAL_DOC_PROP.FAL_SUPPLY_REQUEST_ID%type default null
  )
  is
    lbRes boolean;
  begin
    lbRes  := false;
    lbRes  :=
      InsertMovementRequest(iGoodId
                          , iStockMovementId
                          , iDiuId
                          , iDicDistribComplData
                          , iQuantity
                          , iBasisDelay
                          , iDocRecordId
                          , iGcoChar1
                          , iGcoChar2
                          , iGcoChar3
                          , iGcoChar4
                          , iGcoChar5
                          , iFdpChar1
                          , iFdpChar2
                          , iFdpChar3
                          , iFdpChar4
                          , iFdpChar5
                          , iFAL_SUPPLY_REQUEST_ID
                           );

    if lbRes then
      oResult  := 1;
    else
      oResult  := 0;
    end if;
  end InsertMovementRequest;

  /**
  * Description
  *     Insertion d'une demande de réapprovisionnement (FAL_DOC_PROP)
  */
  function InsertMovementRequest(
    iGoodId                in FAL_DOC_PROP.GCO_GOOD_ID%type
  , iStockMovementId       in FAL_DOC_PROP.STM_STOCK_MOVEMENT_ID%type
  , iDiuId                 in STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type
  , iDicDistribComplData   in GCO_COMPL_DATA_DISTRIB.DIC_DISTRIB_COMPL_DATA_ID%type
  , iQuantity              in FAL_DOC_PROP.FDP_BASIS_QTY%type
  , iBasisDelay            in FAL_DOC_PROP.FDP_BASIS_DELAY%type
  , iDocRecordId           in STM_STOCK_MOVEMENT.doc_record_id%type
  , iGcoChar1              in FAL_DOC_PROP.GCO_CHARACTERIZATION1_ID%type
  , iGcoChar2              in FAL_DOC_PROP.GCO_CHARACTERIZATION2_ID%type
  , iGcoChar3              in FAL_DOC_PROP.GCO_CHARACTERIZATION3_ID%type
  , iGcoChar4              in FAL_DOC_PROP.GCO_CHARACTERIZATION4_ID%type
  , iGcoChar5              in FAL_DOC_PROP.GCO_CHARACTERIZATION5_ID%type
  , iFdpChar1              in FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_1%type
  , iFdpChar2              in FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_2%type
  , iFdpChar3              in FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_3%type
  , iFdpChar4              in FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_4%type
  , iFdpChar5              in FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_5%type
  , iFAL_SUPPLY_REQUEST_ID in FAL_DOC_PROP.FAL_SUPPLY_REQUEST_ID%type default null
  )
    return boolean
  is
    lPacSupplierPartnerId     FAL_DOC_PROP.PAC_SUPPLIER_PARTNER_ID%type;
    lCPrefixProp              FAL_DOC_PROP.C_PREFIX_PROP%type;
    lFalSupplyRequestId       FAL_DOC_PROP.FAL_SUPPLY_REQUEST_ID%type;
    lFalPicId                 FAL_DOC_PROP.FAL_PIC_ID%type;
    lFdpTexte                 FAL_DOC_PROP.FDP_TEXTE%type;
    lDocGaugeId               FAL_PROP_DEF.DOC_GAUGE_ID%type;
    lFdpNumber                FAL_PROP_DEF.FPR_METER%type;
    lSupplyMode               GCO_PRODUCT.C_SUPPLY_MODE%type;
    lDesShortDescription      GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type;
    lGooSecondaryReference    GCO_GOOD.GOO_SECONDARY_REFERENCE%type;
    lStmStockId               STM_DISTRIBUTION_UNIT.STM_STOCK_ID%type;
    lStmStmStockId            STM_DISTRIBUTION_UNIT.STM_STOCK_ID%type;
    lStmLocationId            STM_LOCATION.STM_LOCATION_ID%type;
    lStmStmLocationId         STM_LOCATION.STM_LOCATION_ID%type;
    lStmStmDistributionUnitId STM_DISTRIBUTION_UNIT.STM_STM_DISTRIBUTION_UNIT_ID%type;
    lDicUnitOfMeasure         GCO_GOOD.DIC_UNIT_OF_MEASURE_ID%type;
    lConvertFactor            GCO_COMPL_DATA_DISTRIB.CDA_CONVERSION_FACTOR%type;
    lNumberOfDecimal          GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
    lStockMin                 GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MIN%type;
    lStockMax                 GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MAX%type;
    lBlockedFrom              GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_FROM%type;
    lBlockedTo                GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_TO%type;
    lCoverPercent             GCO_COMPL_DATA_DISTRIB.CDI_COVER_PERCENT%type;
    lPriority                 GCO_COMPL_DATA_DISTRIB.CDI_PRIORITY_CODE%type;
    lUseCoverPercent          GCO_COMPL_DATA_DISTRIB.C_DRP_USE_COVER_PERCENT%type;
    lQuantityRule             GCO_COMPL_DATA_DISTRIB.C_DRP_QTY_RULE%type;
    lDocMode                  GCO_COMPL_DATA_DISTRIB.C_DRP_DOC_MODE%type;
    lReliquat                 GCO_COMPL_DATA_DISTRIB.C_DRP_RELIQUAT%type;
    lResult                   number;
    lEconQuantity             GCO_COMPL_DATA_DISTRIB.CDI_ECONOMICAL_QUANTITY%type;
    lDocRecordId              STM_STOCK_MOVEMENT.DOC_RECORD_ID%type;
    lGcoChar1                 FAL_DOC_PROP.GCO_CHARACTERIZATION1_ID%type;
    lGcoChar2                 FAL_DOC_PROP.GCO_CHARACTERIZATION2_ID%type;
    lGcoChar3                 FAL_DOC_PROP.GCO_CHARACTERIZATION3_ID%type;
    lGcoChar4                 FAL_DOC_PROP.GCO_CHARACTERIZATION4_ID%type;
    lGcoChar5                 FAL_DOC_PROP.GCO_CHARACTERIZATION5_ID%type;
    lFdpChar1                 FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_1%type;
    lFdpChar2                 FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_2%type;
    lFdpChar3                 FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_3%type;
    lFdpChar4                 FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_4%type;
    lFdpChar5                 FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_5%type;
    lBasisDelay               FAL_DOC_PROP.FDP_BASIS_DELAY%type;
    lDelay                    FAL_DOC_PROP.FDP_BASIS_DELAY%type;
    lFalPropDefId             FAL_PROP_DEF.FAL_PROP_DEF_ID%type;
    lFalDocPropId             FAL_DOC_PROP.FAL_DOC_PROP_ID%type;
    lDummyId                  FAL_DOC_PROP.FAL_DOC_PROP_ID%type;
  begin
    /* Set Default Values*/
    lPacSupplierPartnerId  := null;
    lCPrefixProp           := 'DRA';
    lFalSupplyRequestId    := iFAL_SUPPLY_REQUEST_ID;
    lFalPicId              := null;
    lFdpTexte              := null;
    /* Get Delivery Plan Values */
    lDelay                 := FAL_LIB_DRP.GetIntermediateDelay(iDiuId);

    /* Get STM_DISTRIBUTION_UNIT Values */
    begin
      select stm_stock_id
           , stm_stm_distribution_unit_id
        into lStmStockId
           , lStmStmDistributionUnitId
        from stm_distribution_unit
       where stm_distribution_unit_id = iDiuId;
    exception
      when no_data_found then
        begin
          lStmStockId                := null;
          lStmStmDistributionUnitId  := null;
        end;
    end;

    if (lStmStmDistributionUnitId is not null) then
      begin
        select stm_stock_id
          into lStmStmStockId
          from stm_distribution_unit
         where stm_distribution_unit_id = lStmStmDistributionUnitId;
      exception
        when no_data_found then
          lStmStmStockId  := null;
      end;
    else
      lStmStmStockId  := null;
    end if;

    /* Get GCO_GOOD Values */
    begin
      select goo_secondary_reference
        into lGooSecondaryReference
        from gco_good
       where gco_good_id = iGoodId;
    exception
      when no_data_found then
        lGooSecondaryReference  := null;
    end;

    /* Get GCO_PRODUCT Values */
    begin
      select c_supply_mode
        into lSupplyMode
        from gco_product
       where gco_good_id = iGoodId;
    exception
      when no_data_found then
        lSupplyMode  := null;
    end;

    /* Get GCO_DESCRIPTION Values */
    begin
      select des_short_description
        into lDesShortDescription
        from gco_description
       where gco_good_id = iGoodId
         and c_description_type = '01'
         and pc_lang_id = pcs.PC_I_LIB_SESSION.getuserlangid;
    exception
      when no_data_found then
        lDesShortDescription  := null;
    end;

    /* Get GCO_COMPL_DATA_DISTRIB Values*/
    gco_functions.GetComplDataDistrib(iGoodId
                                    , iDiuId
                                    , iDicDistribComplData
                                    , lResult
                                    , lDicUnitOfMeasure
                                    , lConvertFactor
                                    , lNumberOfDecimal
                                    , lStockMin
                                    , lStockMax
                                    , lEconQuantity
                                    , lBlockedFrom
                                    , lBlockedTo
                                    , lCoverPercent
                                    , lUseCoverPercent
                                    , lPriority
                                    , lQuantityRule
                                    , lDocMode
                                    , lReliquat
                                     );

    if (lResult <= 0) then
      return false;
    end if;

    /* Get FAL Values */
    begin
      select DOC_GAUGE_ID
           , FPR_METER
           , FAL_PROP_DEF_ID
        into lDocGaugeId
           , lFdpNumber
           , lFalPropDefId
        from fal_prop_def
       where c_prop_type = 5
         and c_supply_mode = lSupplyMode;
    exception
      when no_data_found then
        begin
          lDocGaugeId    := null;
          lFdpNumber     := null;
          lFalPropDefId  := null;
        end;
    end;

    /* If FAL Value found, Increment Meter and store back */
    if (lFalPropDefId is not null) then
      lFdpNumber  := lFdpNumber + 1;

      update fal_prop_def
         set FPR_METER = lFdpNumber
       where fal_prop_def_id = lFalPropDefId;
    end if;

    /* Get STM_LOCATION Values */
    begin
      select   stm_location_id
          into lStmLocationId
          from stm_location
         where stm_stock_id = lStmStockId
           and rownum = 1
      order by loc_classification;
    exception
      when no_data_found then
        lStmLocationId  := null;
    end;

    if (lStmLocationId is not null) then
      begin
        select   stm_location_id
            into lStmStmLocationId
            from stm_location
           where stm_stock_id = lStmStmStockId
             and rownum = 1
        order by loc_classification;
      exception
        when no_data_found then
          lStmStmLocationId  := null;
      end;
    else
      lStmStmLocationId  := null;
    end if;

    /* Get STM_STOCK_MOVEMENT Values */
    /* If no iStockMovementId present, get Characterization and Values from Stock Movement */
    if     (iStockMovementId is not null)
       and (iStockMovementId != 0) then
      begin
        select doc_record_id
             , gco_characterization_id
             , gco_gco_characterization_id
             , gco2_gco_characterization_id
             , gco3_gco_characterization_id
             , gco4_gco_characterization_id
             , smo_characterization_value_1
             , smo_characterization_value_2
             , smo_characterization_value_3
             , smo_characterization_value_4
             , smo_characterization_value_5
             , SMO_MOVEMENT_DATE
          into lDocRecordId
             , lGcoChar1
             , lGcoChar2
             , lGcoChar3
             , lGcoChar4
             , lGcoChar5
             , lFdpChar1
             , lFdpChar2
             , lFdpChar3
             , lFdpChar4
             , lFdpChar5
             , lBasisDelay
          from stm_stock_movement
         where stm_stock_movement_id = iStockMovementId;
      exception
        when no_data_found then
          begin
            -- prendre les valueurs passées par paramètre
            lDocRecordId  := iDocRecordId;
            lGcoChar1     := iGcoChar1;
            lGcoChar2     := iGcoChar2;
            lGcoChar3     := iGcoChar3;
            lGcoChar4     := iGcoChar4;
            lGcoChar5     := iGcoChar5;
            lFdpChar1     := iFdpChar1;
            lFdpChar2     := iFdpChar2;
            lFdpChar3     := iFdpChar3;
            lFdpChar4     := iFdpChar4;
            lFdpChar5     := iFdpChar5;
            lBasisDelay   := iBasisDelay;
          end;
      end;
    else
      begin
        lDocRecordId  := iDocRecordId;
        lGcoChar1     := iGcoChar1;
        lGcoChar2     := iGcoChar2;
        lGcoChar3     := iGcoChar3;
        lGcoChar4     := iGcoChar4;
        lGcoChar5     := iGcoChar5;
        lFdpChar1     := iFdpChar1;
        lFdpChar2     := iFdpChar2;
        lFdpChar3     := iFdpChar3;
        lFdpChar4     := iFdpChar4;
        lFdpChar5     := iFdpChar5;
        lBasisDelay   := iBasisDelay;
      end;
    end if;

    /* Update FAL_DOC_PROP */
    lFalDocPropId          := GetNewID;

    insert into FAL_DOC_PROP
                (FAL_DOC_PROP_ID
               , A_DATECRE
               , A_IDCRE
               , GCO_CHARACTERIZATION1_ID
               , GCO_CHARACTERIZATION2_ID
               , GCO_CHARACTERIZATION3_ID
               , GCO_CHARACTERIZATION4_ID
               , GCO_CHARACTERIZATION5_ID
               , STM_STOCK_ID
               , STM_STM_STOCK_ID
               , PAC_SUPPLIER_PARTNER_ID
               , DOC_GAUGE_ID
               , DOC_RECORD_ID
               , C_PREFIX_PROP
               , GCO_GOOD_ID
               , STM_LOCATION_ID
               , STM_STM_LOCATION_ID
               , FDP_CHARACTERIZATION_VALUE_1
               , FDP_CHARACTERIZATION_VALUE_2
               , FDP_CHARACTERIZATION_VALUE_3
               , FDP_CHARACTERIZATION_VALUE_4
               , FDP_CHARACTERIZATION_VALUE_5
               , FDP_BASIS_QTY
               , FDP_INTERMEDIATE_QTY
               , FDP_FINAL_QTY
               , FDP_BASIS_DELAY
               , FDP_INTERMEDIATE_DELAY
               , FDP_FINAL_DELAY
               , FDP_NUMBER
               , FDP_SECOND_REF
               , FDP_PSHORT_DESCR
               , FAL_SUPPLY_REQUEST_ID
               , FDP_TEXTE
               , FDP_CONVERT_FACTOR
               , FAL_PIC_ID
               , C_DRP_QTY_RULE
               , STM_DISTRIBUTION_UNIT_ID
               , STM_STM_DISTRIBUTION_UNIT_ID
               , STM_STOCK_MOVEMENT_ID
               , FDP_DRP_BALANCE_QUANTITY
                )
         values (lFalDocPropId
               , sysdate
               , pcs.PC_I_LIB_SESSION.getuserini
               , lGcoChar1
               , lGcoChar2
               , lGcoChar3
               , lGcoChar4
               , lGcoChar5
               , lStmStmStockId   -- OLD: lStmStockId
               , lStmStockId   -- OLD: lStmStmStockId
               , lPacSupplierPartnerId
               , lDocGaugeId
               , lDocRecordId
               , lCPrefixProp
               , iGoodId
               , lStmStmLocationId   -- OLD: lStmLocationId,
               , lStmLocationId   -- OLD: lStmStmLocationId
               , lFdpChar1
               , lFdpChar2
               , lFdpChar3
               , lFdpChar4
               , lFdpChar5
               , iQuantity
               , iQuantity
               , iQuantity
               , lBasisDelay   -- Basis Delay: Stock Movement Date or Parameter Delay
               , lDelay   -- Intermediate Delay: Next Delivery in Delivery Plan or Today
               , lDelay   -- Final Delay = Intermediate Delay
               , lFdpNumber
               , lGooSecondaryReference
               , lDesShortDescription
               , lFalSupplyRequestId
               , lFdpTexte
               , lConvertFactor
               , lFalPicId
               , decode(iFAL_SUPPLY_REQUEST_ID, null, lQuantityRule, '1')
               , iDiuId
               , lStmStmDistributionUnitId
               , iStockMovementId
               , iQuantity
                );

    -- After successful insertion (creation) of a DRA
    FAL_NETWORK_DOC.CreateReseauApproPropApproLog(lFalDocPropId, lDummyId);
    FAL_NETWORK_DOC.CreateReseauBesoinPropApproLog(lFalDocPropId, lDummyId);
    return true;
  end InsertMovementRequest;

  /**
  * Description
  *     Création DRA
  */
  procedure EvtsGenDRA(iStockMovementId in STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type, iDIU in STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type)
  is
    lQStock                  number;
    lgetstockavailable       number;
    lGetStockProvisoryOutput number;
    lBesoins                 number                                                default 0;
    lAppro                   number                                                default 0;
    lQtyReappro              number;
    lGcoGoodId               STM_STOCK_MOVEMENT.GCO_GOOD_ID%type;
    lStmLocationId           STM_STOCK_MOVEMENT.STM_LOCATION_ID%type;
    lStmStockId              STM_STOCK_MOVEMENT.STM_STOCK_ID%type;
    lSmoMovementQuantity     STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type;
    lDocRecordId             STM_STOCK_MOVEMENT.DOC_RECORD_ID%type                 default null;
    lGcoChar1                FAL_DOC_PROP.GCO_CHARACTERIZATION1_ID%type            default null;
    lGcoChar2                FAL_DOC_PROP.GCO_CHARACTERIZATION2_ID%type            default null;
    lGcoChar3                FAL_DOC_PROP.GCO_CHARACTERIZATION3_ID%type            default null;
    lGcoChar4                FAL_DOC_PROP.GCO_CHARACTERIZATION4_ID%type            default null;
    lGcoChar5                FAL_DOC_PROP.GCO_CHARACTERIZATION5_ID%type            default null;
    lFdpChar1                FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_1%type        default null;
    lFdpChar2                FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_2%type        default null;
    lFdpChar3                FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_3%type        default null;
    lFdpChar4                FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_4%type        default null;
    lFdpChar5                FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_5%type        default null;
    lInsertMovementRequest   boolean;
    lDicUnitOfMeasure        GCO_GOOD.DIC_UNIT_OF_MEASURE_ID%type;
    lConvertFactor           GCO_COMPL_DATA_DISTRIB.CDA_CONVERSION_FACTOR%type;
    lNumberOfDecimal         GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
    lStockMin                GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MIN%type;
    lStockMax                GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MAX%type;
    lBlockedFrom             GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_FROM%type;
    lBlockedTo               GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_TO%type;
    lCoverPercent            GCO_COMPL_DATA_DISTRIB.CDI_COVER_PERCENT%type;
    lUseCoverPercent         GCO_COMPL_DATA_DISTRIB.C_DRP_USE_COVER_PERCENT%type;
    lPriority                GCO_COMPL_DATA_DISTRIB.CDI_PRIORITY_CODE%type;
    lQuantityRule            GCO_COMPL_DATA_DISTRIB.C_DRP_QTY_RULE%type;
    lDocMode                 GCO_COMPL_DATA_DISTRIB.C_DRP_DOC_MODE%type;
    lReliquat                GCO_COMPL_DATA_DISTRIB.C_DRP_RELIQUAT%type;
    lResult                  number;
    lEconQuantity            GCO_COMPL_DATA_DISTRIB.CDI_ECONOMICAL_QUANTITY%type;
    lCharactType             GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
  begin
    if     (iStockMovementId is not null)
       and (iStockMovementId != 0) then
      begin
        -- lQStock = AvailableQuantity - ProvisoryOutput - Besoins + Appro
        begin
          select GCO_GOOD_ID
               , STM_LOCATION_ID
               , STM_STOCK_ID
               , SMO_MOVEMENT_QUANTITY
            into lGcoGoodId
               , lStmLocationId
               , lStmStockId
               , lSmoMovementQuantity
            from stm_stock_movement
           where stm_stock_movement_id = iStockMovementId;
        exception
          when no_data_found then
            return;
        end;

        -- Get Characterization Type of Good
        begin
          select C_CHARACT_TYPE
            into lCharactType
            from GCO_CHARACTERIZATION
           where GCO_GOOD_ID = lGcoGoodId;
        exception
          when no_data_found then
            lCharactType  := null;
        end;

        gco_functions.GetComplDataDistrib(lGcoGoodId
                                        , iDiu
                                        , null   ---- iDicDistribComplData
                                        , lResult
                                        , lDicUnitOfMeasure
                                        , lConvertFactor
                                        , lNumberOfDecimal
                                        , lStockMin
                                        , lStockMax
                                        , lEconQuantity
                                        , lBlockedFrom
                                        , lBlockedTo
                                        , lCoverPercent
                                        , lUseCoverPercent
                                        , lPriority
                                        , lQuantityRule
                                        , lDocMode
                                        , lReliquat
                                         );
        lQStock                 := 0;
        lQtyReappro             := 0;

        if (    (lCharactType = '1')
            or (lCharactType = '2') ) then   -- With Characterization
          FAL_LIB_DRP.GetStockPrvOutAndAvlQ(lGcoGoodId, iStockMovementId, lGetStockProvisoryOutput, lgetstockavailable);   -- Procedure with Characterization
          lBesoins  := FAL_LIB_DRP.CalcSumBesoins(lGcoGoodId, iStockMovementId);   -- Function with Characterization
          lAppro    := FAL_LIB_DRP.CalcSumAppro(lGcoGoodId, iStockMovementId);   -- Function with Characterization
          lQStock   := lgetstockavailable - lGetStockProvisoryOutput - lBesoins + lAppro;
        elsif(    (lCharactType is null)
              or (lCharactType = '3')
              or (lCharactType = '4')
              or (lCharactType = '5') ) then   -- Without Characterization
          lgetstockavailable        := FAL_LIB_DRP.GetStockAvailable(lGcoGoodId, lStmStockId, lStmLocationId);
          lGetStockProvisoryOutput  := FAL_LIB_DRP.GetStockProvisoryOutput(lGcoGoodId, lStmStockId, lStmLocationId);   -- Function without Characterization
          lBesoins                  := FAL_LIB_DRP.CalcSumBesoins(lGcoGoodId, lStmLocationId, lStmStockId);   -- Function without Characterization
          lAppro                    := FAL_LIB_DRP.CalcSumAppro(lGcoGoodId, lStmLocationId, lStmStockId);   -- Function without Characterization
          lQStock                   := lgetstockavailable - lGetStockProvisoryOutput - lBesoins + lAppro;
        end if;

        if (lStockMax is not null) then
          if (trunc( (lQStock + lSmoMovementQuantity) / lConvertFactor, lNumberOfDecimal) > lQStock) then
            lQtyReappro  := (lStockMax * lConvertFactor) - lQStock;
          else
            lQtyReappro  := lSmoMovementQuantity;
          end if;
        end if;

        lQtyReappro             := trunc(lQtyReappro / lConvertFactor, lNumberOfDecimal) * lConvertFactor;
        lInsertMovementRequest  :=
          InsertMovementRequest(lGcoGoodId
                              , iStockMovementId
                              , iDiu
                              , null   ---- iDicDistribComplData
                              , lQtyReappro
                              , null
                              , lDocRecordId
                              , lGcoChar1
                              , lGcoChar2
                              , lGcoChar3
                              , lGcoChar4
                              , lGcoChar5
                              , lFdpChar1
                              , lFdpChar2
                              , lFdpChar3
                              , lFdpChar4
                              , lFdpChar5
                               );
      end;
    else
      begin
        EvtsGenDRAStockMini;
      end;
    end if;
  end EvtsGenDRA;

  procedure EvtsMajDRA(
    iDRA      in FAL_DOC_PROP.FAL_DOC_PROP_ID%type
  , iType     in varchar2
  , iQte      in number
  , iReliquat in GCO_COMPL_DATA_DISTRIB.C_DRP_RELIQUAT%type
  , iDoc      in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  )
  is
    lBalanceQuantity FAL_DOC_PROP.FDP_DRP_BALANCE_QUANTITY%type;
    lStockMovementId FAL_DOC_PROP.STM_STOCK_MOVEMENT_ID%type;
    lFdpNumber       FAL_DOC_PROP.FDP_NUMBER%type;
    lFalDocPropNew   FAL_DOC_PROP%rowtype;
    lFalDocPropOld   FAL_DOC_PROP%rowtype;
    lDrpBalanced     FAL_DOC_PROP.FDP_DRP_BALANCED%type;
  begin
    if (iType = 'DELETE') then
      EvtsSupprDRA(iDRA, iType, iQte, iDoc);
      return;
    else
      begin
        FAL_LIB_DRP.GetDrpValues(iDRA, lBalanceQuantity, lStockMovementId, lFdpNumber, lDrpBalanced);

        if    (lBalanceQuantity - iQte = 0)
           or lDrpBalanced = 1 then
          EvtsSupprDRA(iDRA, iType, iQte, iDoc);
          return;
        end if;

        if (iReliquat != '1') then
          EvtsSupprDRA(iDRA, iType, iQte, iDoc);
          return;
        end if;

        InsertDrpHistory(iDRA, iType, iQte, lBalanceQuantity, lStockMovementId, iDoc, lFdpNumber, lDrpBalanced);

        select *
          into lFalDocPropOld
          from FAL_DOC_PROP
         where FAL_DOC_PROP_ID = iDRA;

        update FAL_DOC_PROP
           set FDP_DRP_BALANCE_QUANTITY = lBalanceQuantity - iQte
             , FDP_BASIS_QTY = nvl(FDP_BASIS_QTY - iQte, lBalanceQuantity - iQte)
             , FDP_INTERMEDIATE_QTY = nvl(FDP_INTERMEDIATE_QTY - iQte, lBalanceQuantity - iQte)
             , FDP_FINAL_QTY = nvl(FDP_FINAL_QTY - iQte, lBalanceQuantity - iQte)
         where FAL_DOC_PROP_ID = iDRA;

        select *
          into lFalDocPropNew
          from FAL_DOC_PROP
         where FAL_DOC_PROP_ID = iDRA;

        FAL_NETWORK_DOC.ReseauBesoinPropositionMAJ_DRA(lFalDocPropNew, lFalDocPropOld);
        FAL_NETWORK_DOC.ReseauApproPropositionMAJ_DRA(lFalDocPropNew, lFalDocPropOld);
      end;
    end if;
  end EvtsMajDRA;

  procedure EvtsSupprDRA(iDRA in FAL_DOC_PROP.FAL_DOC_PROP_ID%type, iType in varchar, iQte in number, iDoc in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    lBalanceQuantity FAL_DOC_PROP.FDP_DRP_BALANCE_QUANTITY%type;
    lStockMovementId FAL_DOC_PROP.STM_STOCK_MOVEMENT_ID%type;
    lFdpNumber       FAL_DOC_PROP.FDP_NUMBER%type;
    lDoc_Id          DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    lDIU_List        varchar(20000);
    lFalDocPropId    FAL_DOC_PROP.FAL_DOC_PROP_ID%type;
    lDrpBalanced     FAL_DOC_PROP.FDP_DRP_BALANCED%type;

    cursor lcurFalDocSuppression
    is
      select FAL_DOC_PROP_ID
        from FAL_DOC_PROP
       where C_DRP_QTY_RULE = 2;
  begin
    if     (iDRA is not null)
       and (iDRA != 0) then
      begin
        if (iType = 'DELETE') then
          lDoc_Id  := null;
        else
          lDoc_Id  := iDoc;
        end if;

        FAL_LIB_DRP.GetDrpValues(iDRA, lBalanceQuantity, lStockMovementId, lFdpNumber, lDrpBalanced);
        InsertDrpHistory(iDRA, iType, iQte, lBalanceQuantity, lStockMovementId, lDoc_Id, lFdpNumber, lDrpBalanced);
        /* Suppression de la DRA */
        FAL_PRC_FAL_DOC_PROP.DeleteOneDOCProposition(iDRA, 1, 0, 0);
--        delete from FAL_DOC_PROP
--              where FAL_DOC_PROP_ID = iDRA;
      end;
    else
      begin   /* Suppression de toutes les DRA */
        open lcurFalDocSuppression;

        fetch lcurFalDocSuppression
         into lFalDocPropId;

        while lcurFalDocSuppression%found loop
          FAL_PRC_FAL_DOC_PROP.DeleteOneDOCProposition(lFalDocPropId, 1, 0, 0);

          fetch lcurFalDocSuppression
           into lFalDocPropId;
        end loop;
--        delete from FAL_DOC_PROP
--              where C_DRP_QTY_RULE = 2;
      end;
    end if;
  end EvtsSupprDRA;

  procedure DeleteOneDRA(iDRA in FAL_DOC_PROP.FAL_DOC_PROP_ID%type, iQte in STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type)
  is
    lBalanceQuantity FAL_DOC_PROP.FDP_DRP_BALANCE_QUANTITY%type;
    lStockMovementId FAL_DOC_PROP.STM_STOCK_MOVEMENT_ID%type;
    lFdpNumber       FAL_DOC_PROP.FDP_NUMBER%type;
    lDrpBalanced     FAL_DOC_PROP.FDP_DRP_BALANCED%type;
  begin
    if     (iDRA is not null)
       and (iDRA != 0) then
      begin
        FAL_LIB_DRP.GetDrpValues(iDRA, lBalanceQuantity, lStockMovementId, lFdpNumber, lDrpBalanced);
        InsertDrpHistory(iDRA, 'DELETE', iQte, lBalanceQuantity, lStockMovementId, null, lFdpNumber);
        /* Suppression de la DRA */
        FAL_PRC_FAL_DOC_PROP.DeleteOneDOCProposition(iDRA, 1, 0, 0);
      end;
    end if;
  end DeleteOneDRA;

  procedure EvtsGenDRAStockMini
  is
    cursor lcurDistribUnitList
    is
      select SDU.STM_STOCK_ID
           , SDU.STM_DISTRIBUTION_UNIT_ID
           , SDU.DIC_DISTRIB_COMPL_DATA_ID
           , (select STM_LOCATION_ID
                from STM_LOCATION LOC
               where SDU.STM_STOCK_ID = LOC.STM_STOCK_ID
                 and LOC_CLASSIFICATION = (select min(LOC_CLASSIFICATION)
                                             from STM_LOCATION loc1
                                            where LOC1.STM_STOCK_ID = LOC.STM_STOCK_ID) ) STM_LOCATION_ID
        from STM_DISTRIBUTION_UNIT SDU
       where SDU.DIU_LEVEL > 0;

    ltplDistribUnit        lcurDistribUnitList%rowtype;

    cursor lcurProductList(
      iDiuId              GCO_COMPL_DATA_DISTRIB.STM_DISTRIBUTION_UNIT_ID%type
    , iComplDataDistribId GCO_COMPL_DATA_DISTRIB.DIC_DISTRIB_COMPL_DATA_ID%type
    )
    is
      select PRD.*
        from GCO_PRODUCT PRD
           , GCO_COMPL_DATA_DISTRIB CDD
       where nvl(CDD.STM_DISTRIBUTION_UNIT_ID, 0) = nvl(iDiuId, 0)
         and (   CDD.DIC_DISTRIB_COMPL_DATA_ID = iComplDataDistribId
              or (    CDD.DIC_DISTRIB_COMPL_DATA_ID is null
                  and iComplDataDistribId is null) )
         and CDD.GCO_GOOD_ID = PRD.GCO_GOOD_ID
         and CDD.C_DRP_QTY_RULE = 2
         and PRD.PDT_STOCK_MANAGEMENT = 1
         and PRD.PDT_CALC_REQUIREMENT_MNGMENT = 1
      union
      select PRD.*
        from GCO_GOOD GOO
           , GCO_PRODUCT PRD
           , GCO_COMPL_DATA_DISTRIB CDD
       where nvl(CDD.STM_DISTRIBUTION_UNIT_ID, 0) = nvl(iDiuId, 0)
         and (   CDD.DIC_DISTRIB_COMPL_DATA_ID = iComplDataDistribId
              or (    CDD.DIC_DISTRIB_COMPL_DATA_ID is null
                  and iComplDataDistribId is null) )
         and CDD.C_DRP_QTY_RULE = 2
         and GOO.GCO_GOOD_ID = PRD.GCO_GOOD_ID
         and GOO.GCO_PRODUCT_GROUP_ID = CDD.GCO_PRODUCT_GROUP_ID
         and CDD.GCO_PRODUCT_GROUP_ID is not null
         and PRD.GCO_GOOD_ID in(
               select PRD.GCO_GOOD_ID
                 from GCO_PRODUCT PRD
                    , GCO_COMPL_DATA_DISTRIB CDD
                where nvl(CDD.STM_DISTRIBUTION_UNIT_ID, 0) = nvl(iDiuId, 0)
                  and (   CDD.DIC_DISTRIB_COMPL_DATA_ID = iComplDataDistribId
                       or (    CDD.DIC_DISTRIB_COMPL_DATA_ID is null
                           and iComplDataDistribId is null) )
                  and CDD.GCO_GOOD_ID = PRD.GCO_GOOD_ID
                  and CDD.GCO_PRODUCT_GROUP_ID is null
                  and CDD.C_DRP_QTY_RULE = 0
                  and PRD.PDT_STOCK_MANAGEMENT = 1
                  and PRD.PDT_CALC_REQUIREMENT_MNGMENT = 1);

    ltplProduct            lcurProductList%rowtype;
    lStockAvailable        number;
    lStockProvisory        number;
    lQStock                number;
    lQStockMini            number;
    lLocationId            STM_STOCK_MOVEMENT.STM_LOCATION_ID%type;
    lInsertMovementRequest boolean;
    lDicUnitOfMeasure      GCO_GOOD.DIC_UNIT_OF_MEASURE_ID%type;
    lConvertFactor         GCO_COMPL_DATA_DISTRIB.CDA_CONVERSION_FACTOR%type;
    lNumberOfDecimal       GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
    lStockMin              GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MIN%type;
    lStockMax              GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MAX%type;
    lBlockedFrom           GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_FROM%type;
    lBlockedTo             GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_TO%type;
    lCoverPercent          GCO_COMPL_DATA_DISTRIB.CDI_COVER_PERCENT%type;
    lUseCoverPercent       GCO_COMPL_DATA_DISTRIB.C_DRP_USE_COVER_PERCENT%type;
    lPriority              GCO_COMPL_DATA_DISTRIB.CDI_PRIORITY_CODE%type;
    lQuantityRule          GCO_COMPL_DATA_DISTRIB.C_DRP_QTY_RULE%type;
    lDocMode               GCO_COMPL_DATA_DISTRIB.C_DRP_DOC_MODE%type;
    lReliquat              GCO_COMPL_DATA_DISTRIB.C_DRP_RELIQUAT%type;
    lResult                number;
    lEconQuantity          GCO_COMPL_DATA_DISTRIB.CDI_ECONOMICAL_QUANTITY%type;
    lQtyReappro            number;
    lModulo                number;
    lDIU_List              varchar(20000);
  begin
    open lcurDistribUnitList;

    fetch lcurDistribUnitList
     into ltplDistribUnit;

    while lcurDistribUnitList%found loop
      open lcurProductList(ltplDistribUnit.STM_DISTRIBUTION_UNIT_ID, ltplDistribUnit.DIC_DISTRIB_COMPL_DATA_ID);

      fetch lcurProductList
       into ltplProduct;

      while lcurProductList%found loop
        begin
          select nvl(sum(SPO.SPO_AVAILABLE_QUANTITY), 0)
               , nvl(sum(SPO.SPO_PROVISORY_INPUT), 0)
            into lStockAvailable
               , lStockProvisory
            from STM_STOCK_POSITION SPO
               , STM_ELEMENT_NUMBER SEM
           where SPO.STM_STOCK_ID = ltplDistribUnit.STM_STOCK_ID
             and SPO.GCO_GOOD_ID = ltplProduct.GCO_GOOD_ID
             and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = SEM.STM_ELEMENT_NUMBER_ID(+)
             and STM_I_LIB_MOVEMENT.VerifyForecastStockPosCond(iGoodId            => SPO.GCO_GOOD_ID
                                                             , iPiece             => SPO.SPO_PIECE
                                                             , iSet               => SPO.SPO_SET
                                                             , iVersion           => SPO.SPO_VERSION
                                                             , iChronological     => SPO.SPO_CHRONOLOGICAL
                                                             , iQualityStatusId   => SEM.GCO_QUALITY_STATUS_ID
                                                              ) is not null;
        exception
          when no_data_found then
            begin
              lStockAvailable  := 0;
              lStockProvisory  := 0;
            end;
        end;

        GCO_FUNCTIONS.GetComplDataDistrib(ltplProduct.GCO_GOOD_ID
                                        , ltplDistribUnit.STM_DISTRIBUTION_UNIT_ID
                                        , ltplDistribUnit.DIC_DISTRIB_COMPL_DATA_ID
                                        , lResult
                                        , lDicUnitOfMeasure
                                        , lConvertFactor
                                        , lNumberOfDecimal
                                        , lStockMin
                                        , lStockMax
                                        , lEconQuantity
                                        , lBlockedFrom
                                        , lBlockedTo
                                        , lCoverPercent
                                        , lUseCoverPercent
                                        , lPriority
                                        , lQuantityRule
                                        , lDocMode
                                        , lReliquat
                                         );

        if (lResult > 0) then
          lQStock      :=
            lStockAvailable +
            lStockProvisory -
            FAL_LIB_DRP.CalcSumBesoins(ltplProduct.GCO_GOOD_ID, ltplDistribUnit.STM_LOCATION_ID, ltplDistribUnit.STM_STOCK_ID) +
            FAL_LIB_DRP.CalcSumAppro(ltplProduct.GCO_GOOD_ID, ltplDistribUnit.STM_LOCATION_ID, ltplDistribUnit.STM_STOCK_ID);
          lQStockMini  := (lQStock / lConvertFactor) - nvl(lStockMin, 0);

          if (lQStockMini < 0) then
            lQtyReappro             := trunc( ( ( (nvl(lStockMax, nvl(lStockMin, 0) ) ) * lConvertFactor) - lQStock) / lConvertFactor, lNumberOfDecimal);

            if (lStockMax is null) then
              lModulo  := mod(lQtyReappro, nvl(lEconQuantity, 1) );

              if (lModulo > 0) then
                lQtyReappro  := lQtyReappro + 1;
              end if;
            end if;

            lQtyReappro             := trunc(lQtyReappro / nvl(lEconQuantity, 1), lNumberOfDecimal) * nvl(lEconQuantity, 1);
            lQtyReappro             := lQtyReappro * lConvertFactor;
            lInsertMovementRequest  :=
              InsertMovementRequest(ltplProduct.GCO_GOOD_ID
                                  , null
                                  , ltplDistribUnit.STM_DISTRIBUTION_UNIT_ID
                                  , ltplDistribUnit.DIC_DISTRIB_COMPL_DATA_ID
                                  , lQtyReappro
                                  , trunc(sysdate)   -- Base delay is today for stock min
                                  , null
                                  , null
                                  , null
                                  , null
                                  , null
                                  , null
                                  , null
                                  , null
                                  , null
                                  , null
                                  , null
                                   );
          end if;
        end if;

        fetch lcurProductList
         into ltplProduct;
      end loop;

      close lcurProductList;

      fetch lcurDistribUnitList
       into ltplDistribUnit;
    end loop;

    close lcurDistribUnitList;
  end EvtsGenDRAStockMini;

  procedure InsertDrpHistory(
    iDRA             in FAL_DOC_PROP.FAL_DOC_PROP_ID%type
  , iType            in varchar
  , iQte             in number
  , iBalanceQuantity in FAL_DOC_PROP.FDP_DRP_BALANCE_QUANTITY%type
  , iStockMovementId in FAL_DOC_PROP.STM_STOCK_MOVEMENT_ID%type
  , iDoc             in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , iFdpNumber       in FAL_DOC_PROP.FDP_NUMBER%type
  , iDrpBalanced     in FAL_DOC_PROP.FDP_DRP_BALANCED%type default 0
  )
  is
    lQtyDelivered STM_DELIVERY_HISTORY.SDH_DELIVERED_QUANTITY%type;
    lQtyExtourned STM_DELIVERY_HISTORY.SDH_EXTOURNED_QUANTITY%type;
    lQtyBalanced  STM_DELIVERY_HISTORY.SDH_BALANCED_QUANTITY%type;
  begin
    if (iType = 'DELIVERY') then
      lQtyDelivered  := iQte;
    else
      lQtyDelivered  := 0;
    end if;

    if (iType = 'EXTOURNE') then
      lQtyExtourned  := iQte;
    else
      lQtyExtourned  := 0;
    end if;

    if iDrpBalanced = 1 then
      lQtyBalanced  := iBalanceQuantity - iQte;
    else
      lQtyBalanced  := 0;
    end if;

    insert into STM_DELIVERY_HISTORY
                (STM_DELIVERY_HISTORY_ID
               , A_DATECRE
               , A_IDCRE
               , C_DRP_HISTORY_CODE
               , DOC_DOCUMENT_ID
               , DOC_POSITION_DETAIL_ID   -- (DEPRECATED!)
               , SDH_BALANCED_QUANTITY
               , SDH_BASIS_QUANTITY
               , SDH_DELIVERED_QUANTITY
               , SDH_EXTOURNED_QUANTITY
               , SDH_PROP_NUMBER
               , STM_STOCK_MOVEMENT_ID
                )
         values (GetNewId   -- STM_DELIVERY_HISTORY_ID
               , sysdate
               , pcs.PC_I_LIB_SESSION.getuserini
               , iType   -- C_DRP_HISTORY_CODE
               , iDoc   -- DOC_DOCUMENT_ID
               , null   -- DOC_POSITION_DETAIL_ID (DEPRECATED!)
               , lQtyBalanced   -- SDH_BALANCED_QUANTITY
               , iBalanceQuantity   -- SDH_BASIS_QUANTITY
               , lQtyDelivered   -- SDH_DELIVERED_QUANTITY
               , lQtyExtourned   -- SDH_EXTOURNED_QUANTITY
               , iFdpNumber   -- SDH_PROP_NUMBER
               , iStockMovementId   -- STM_STOCK_MOVEMENT_ID
                );
  end InsertDrpHistory;

  procedure CtrlRegleApproSortie(
    iotMovementRecord    in out FWK_TYP_STM_ENTITY.tStockMovement
  , iDistributionUnit    in     STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type
  , iReapproUnit         in     STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type
  , iDicDistribComplData in     GCO_COMPL_DATA_DISTRIB.DIC_DISTRIB_COMPL_DATA_ID%type
  )
  is
    lResult               number;
    lDicUnitOfMeasure     GCO_GOOD.DIC_UNIT_OF_MEASURE_ID%type;
    lConvertFactor        GCO_COMPL_DATA_DISTRIB.CDA_CONVERSION_FACTOR%type;
    lNumberOfDecimal      GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
    lStockMin             GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MIN%type;
    lStockMax             GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MAX%type;
    lEconQuantity         GCO_COMPL_DATA_DISTRIB.CDI_ECONOMICAL_QUANTITY%type;
    lCDDBlockedFrom       GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_FROM%type;
    lCDDBlockedTo         GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_TO%type;
    lDIUBlockedFrom       STM_DISTRIBUTION_UNIT.DIU_BLOCKED_FROM%type;
    lDIUBlockedTo         STM_DISTRIBUTION_UNIT.DIU_BLOCKED_TO%type;
    lPrepareTime          STM_DISTRIBUTION_UNIT.DIU_PREPARE_TIME%type;
    lCoverPerCent         GCO_COMPL_DATA_DISTRIB.CDI_COVER_PERCENT%type;
    lPriority             GCO_COMPL_DATA_DISTRIB.CDI_PRIORITY_CODE%type;
    lUseCoverPercent      GCO_COMPL_DATA_DISTRIB.C_DRP_USE_COVER_PERCENT%type;
    lQuantityRule         GCO_COMPL_DATA_DISTRIB.C_DRP_QTY_RULE%type;
    lDocMode              GCO_COMPL_DATA_DISTRIB.C_DRP_DOC_MODE%type;
    lReliquat             GCO_COMPL_DATA_DISTRIB.C_DRP_RELIQUAT%type;
    lBlocked              boolean;
    lComplDataFound       boolean;
    lInsert               boolean;
    lLocationId           STM_STOCK_MOVEMENT.STM_LOCATION_ID%type;
    lStockId              STM_STOCK_MOVEMENT.STM_STOCK_ID%type;
    lQteStock             number;
    lStockAvailable       number;
    lStockProvisoryOutput number;
    lBesoins              number                                                 default 0;
    lAppro                number                                                 default 0;
    lQteReappro           number;
    lCharId1              STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
    lCharId2              STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
    lCharId3              STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
    lCharId4              STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
    lCharId5              STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
    lChar1                STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    lChar2                STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    lChar3                STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    lChar4                STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    lChar5                STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
  begin
    GCO_FUNCTIONS.GetComplDataDistrib(iotMovementRecord.GCO_GOOD_ID
                                    , iDistributionUnit
                                    , iDicDistribComplData
                                    , lResult
                                    , lDicUnitOfMeasure
                                    , lConvertFactor
                                    , lNumberOfDecimal
                                    , lStockMin
                                    , lStockMax
                                    , lEconQuantity
                                    , lCDDBlockedFrom
                                    , lCDDBlockedTo
                                    , lCoverPerCent
                                    , lUseCoverPercent
                                    , lPriority
                                    , lQuantityRule
                                    , lDocMode
                                    , lReliquat
                                     );
    lComplDataFound  := lResult > 0;

    if lComplDataFound then
      -- Valeurs CDD trouvées
      if lQuantityRule = '1' then
        -- Selon qté vendue
        lBlocked  := false;

        -- Tester si réappro autorisé pour cet produit aujourd'hui
        if    lCDDBlockedFrom is not null
           or lCDDBlockedTo is not null then
          if trunc(sysdate) between nvl(trunc(lCDDBlockedFrom), trunc(sysdate) ) and nvl(trunc(lCDDBlockedTo), trunc(sysdate) ) then
            lBlocked  := true;
          end if;
        end if;

        -- Tester si réappro autorisé pour cette DIU aujourd'hui
        if     iDistributionUnit is not null
           and not lBlocked then
          FAL_LIB_DRP.GetDiuBlocked(iDistributionUnit, lDIUBlockedFrom, lDIUBlockedTo, lPrepareTime);

          if    lDIUBlockedFrom is not null
             or lDIUBlockedTo is not null then
            if trunc(sysdate) between nvl(trunc(lDIUBlockedFrom), trunc(sysdate) ) and nvl(trunc(lDIUBlockedTo), trunc(sysdate) ) then
              lBlocked  := true;
            end if;
          end if;
        end if;

        -- Tester si réappro autorisé pour ce code aujourd'hui
        if     iDicDistribComplData is not null
           and not lBlocked then
          FAL_LIB_DRP.GetCodeBlocked(iDicDistribComplData, lDIUBlockedFrom, lDIUBlockedTo, lPrepareTime);

          if    lDIUBlockedFrom is not null
             or lDIUBlockedTo is not null then
            if trunc(sysdate) between nvl(trunc(lDIUBlockedFrom), trunc(sysdate) ) and nvl(trunc(lDIUBlockedTo), trunc(sysdate) ) then
              lBlocked  := true;
            end if;
          end if;
        end if;

        if not lBlocked then
          lStockAvailable        := FAL_LIB_DRP.GetStockAvailable(iotMovementRecord.GCO_GOOD_ID, lStockId, lLocationId);
          lStockProvisoryOutput  := FAL_LIB_DRP.GetStockProvisoryOutput(iotMovementRecord.GCO_GOOD_ID, lStockId, lLocationId);
          lQteStock              := lStockAvailable - lStockProvisoryOutput - lBesoins + lAppro;

          if ( (lQteStock + iotMovementRecord.SMO_MOVEMENT_QUANTITY) > lStockMax) then
            lQteReappro  := nvl(lStockMax, 0) - lQteStock;
          else
            lQteReappro  := iotMovementRecord.SMO_MOVEMENT_QUANTITY;
          end if;

          -- ne passer que les caractéristiques de type 1 et 2
          -- test id1
          if FAL_LIB_DRP.CheckCaracterization1or2(iotMovementRecord.GCO_GOOD_ID, iotMovementRecord.GCO_CHARACTERIZATION_ID) then
            lCharId1  := iotMovementRecord.GCO_CHARACTERIZATION_ID;
            lChar1    := iotMovementRecord.SMO_CHARACTERIZATION_VALUE_1;
          else
            lCharId1  := null;
            lChar1    := null;
          end if;

          -- test id2
          if FAL_LIB_DRP.CheckCaracterization1or2(iotMovementRecord.GCO_GOOD_ID, iotMovementRecord.GCO_GCO_CHARACTERIZATION_ID) then
            lCharId2  := iotMovementRecord.GCO_GCO_CHARACTERIZATION_ID;
            lChar2    := iotMovementRecord.SMO_CHARACTERIZATION_VALUE_2;
          else
            lCharId2  := null;
            lChar2    := null;
          end if;

          -- test id3
          if FAL_LIB_DRP.CheckCaracterization1or2(iotMovementRecord.GCO_GOOD_ID, iotMovementRecord.GCO2_GCO_CHARACTERIZATION_ID) then
            lCharId3  := iotMovementRecord.GCO2_GCO_CHARACTERIZATION_ID;
            lChar3    := iotMovementRecord.SMO_CHARACTERIZATION_VALUE_3;
          else
            lCharId3  := null;
            lChar3    := null;
          end if;

          -- test id4
          if FAL_LIB_DRP.CheckCaracterization1or2(iotMovementRecord.GCO_GOOD_ID, iotMovementRecord.GCO3_GCO_CHARACTERIZATION_ID) then
            lCharId4  := iotMovementRecord.GCO3_GCO_CHARACTERIZATION_ID;
            lChar4    := iotMovementRecord.SMO_CHARACTERIZATION_VALUE_4;
          else
            lCharId4  := null;
            lChar4    := null;
          end if;

          -- test id1
          if FAL_LIB_DRP.CheckCaracterization1or2(iotMovementRecord.GCO_GOOD_ID, iotMovementRecord.GCO4_GCO_CHARACTERIZATION_ID) then
            lCharId5  := iotMovementRecord.GCO4_GCO_CHARACTERIZATION_ID;
            lChar5    := iotMovementRecord.SMO_CHARACTERIZATION_VALUE_5;
          else
            lCharId5  := null;
            lChar5    := null;
          end if;

          lInsert                :=
            InsertMovementRequest(iotMovementRecord.GCO_GOOD_ID
                                , iotMovementRecord.STM_STOCK_MOVEMENT_ID
                                , iDistributionUnit
                                , iDicDistribComplData
                                , lQteReappro
                                , iotMovementRecord.SMO_MOVEMENT_DATE
                                , iotMovementRecord.DOC_RECORD_ID
                                , iotMovementRecord.GCO_CHARACTERIZATION_ID
                                , iotMovementRecord.GCO_GCO_CHARACTERIZATION_ID
                                , iotMovementRecord.GCO2_GCO_CHARACTERIZATION_ID
                                , iotMovementRecord.GCO3_GCO_CHARACTERIZATION_ID
                                , iotMovementRecord.GCO4_GCO_CHARACTERIZATION_ID
                                , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_1
                                , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_2
                                , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_3
                                , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_4
                                , iotMovementRecord.SMO_CHARACTERIZATION_VALUE_5
                                 );
        end if;
      end if;
    end if;
  end CtrlRegleApproSortie;

  procedure CtrlRegleApproEntree(
    iotMovementRecord    in out FWK_TYP_STM_ENTITY.tStockMovement
  , iDistributionUnit    in     STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type
  , iReapproUnit         in     STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type
  , iDicDistribComplData in     GCO_COMPL_DATA_DISTRIB.DIC_DISTRIB_COMPL_DATA_ID%type
  , iDocId               in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  )
  is
    lDocPropId        FAL_DOC_PROP.FAL_DOC_PROP_ID%type;
    lComplDataFound   boolean;
    lResult           number;
    lDicUnitOfMeasure GCO_GOOD.DIC_UNIT_OF_MEASURE_ID%type;
    lConvertFactor    GCO_COMPL_DATA_DISTRIB.CDA_CONVERSION_FACTOR%type;
    lNumberOfDecimal  GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
    lStockMin         GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MIN%type;
    lStockMax         GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MAX%type;
    lEconQuantity     GCO_COMPL_DATA_DISTRIB.CDI_ECONOMICAL_QUANTITY%type;
    lCDDBlockedFrom   GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_FROM%type;
    lCDDBlockedTo     GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_TO%type;
    lDIUBlockedFrom   STM_DISTRIBUTION_UNIT.DIU_BLOCKED_FROM%type;
    lDIUBlockedTo     STM_DISTRIBUTION_UNIT.DIU_BLOCKED_TO%type;
    lPrepareTime      STM_DISTRIBUTION_UNIT.DIU_PREPARE_TIME%type;
    lCoverPerCent     GCO_COMPL_DATA_DISTRIB.CDI_COVER_PERCENT%type;
    lPriority         GCO_COMPL_DATA_DISTRIB.CDI_PRIORITY_CODE%type;
    lUseCoverPercent  GCO_COMPL_DATA_DISTRIB.C_DRP_USE_COVER_PERCENT%type;
    lQuantityRule     GCO_COMPL_DATA_DISTRIB.C_DRP_QTY_RULE%type;
    lDocMode          GCO_COMPL_DATA_DISTRIB.C_DRP_DOC_MODE%type;
    lReliquat         GCO_COMPL_DATA_DISTRIB.C_DRP_RELIQUAT%type;
  begin
    lComplDataFound  := false;
    GCO_FUNCTIONS.GetComplDataDistrib(iotMovementRecord.GCO_GOOD_ID
                                    , iDistributionUnit
                                    , iDicDistribComplData
                                    , lResult
                                    , lDicUnitOfMeasure
                                    , lConvertFactor
                                    , lNumberOfDecimal
                                    , lStockMin
                                    , lStockMax
                                    , lEconQuantity
                                    , lCDDBlockedFrom
                                    , lCDDBlockedTo
                                    , lCoverPerCent
                                    , lUseCoverPercent
                                    , lPriority
                                    , lQuantityRule
                                    , lDocMode
                                    , lReliquat
                                     );
    lComplDataFound  := lResult > 0;

    if lComplDataFound then
      begin
        select FAL_DOC_PROP_ID
          into lDocPropId
          from FAL_DOC_PROP
         where GCO_GOOD_ID = iotMovementRecord.GCO_GOOD_ID
           and STM_DISTRIBUTION_UNIT_ID = iDistributionUnit
           and STM_STM_DISTRIBUTION_UNIT_ID = iReapproUnit
           and GCO_CHARACTERIZATION1_ID = iotMovementRecord.GCO_CHARACTERIZATION_ID
           and GCO_CHARACTERIZATION2_ID = iotMovementRecord.GCO_GCO_CHARACTERIZATION_ID
           and GCO_CHARACTERIZATION3_ID = iotMovementRecord.GCO2_GCO_CHARACTERIZATION_ID
           and GCO_CHARACTERIZATION4_ID = iotMovementRecord.GCO3_GCO_CHARACTERIZATION_ID
           and GCO_CHARACTERIZATION5_ID = iotMovementRecord.GCO4_GCO_CHARACTERIZATION_ID
           and FDP_CHARACTERIZATION_VALUE_1 = iotMovementRecord.SMO_CHARACTERIZATION_VALUE_1
           and FDP_CHARACTERIZATION_VALUE_2 = iotMovementRecord.SMO_CHARACTERIZATION_VALUE_2
           and FDP_CHARACTERIZATION_VALUE_3 = iotMovementRecord.SMO_CHARACTERIZATION_VALUE_3
           and FDP_CHARACTERIZATION_VALUE_4 = iotMovementRecord.SMO_CHARACTERIZATION_VALUE_4
           and FDP_CHARACTERIZATION_VALUE_5 = iotMovementRecord.SMO_CHARACTERIZATION_VALUE_5
           and C_DRP_QTY_RULE = '1';
      exception
        when no_data_found then
          begin
            lDocPropId  := null;
          end;
      end;

      if lDocPropId is not null then
        EvtsMajDRA(lDocPropId, 'EXTOURNE', iotMovementRecord.SMO_MOVEMENT_QUANTITY, lReliquat, iDocId);
      end if;
    end if;
  end CtrlRegleApproEntree;
end FAL_PRC_DRP;
