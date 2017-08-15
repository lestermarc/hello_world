--------------------------------------------------------
--  DDL for Package Body DOC_LIB_ESTIMATE_POS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_LIB_ESTIMATE_POS" 
is
  /**
  * procedure GetGoodInfo
  * Description
  *   Recherche les informations du bien
  */
  procedure GetGoodInfo(
    iGoodID           in     GCO_GOOD.GCO_GOOD_ID%type
  , iCustomerID       in     DOC_ESTIMATE.PAC_CUSTOM_PARTNER_ID%type
  , iLangID           in     DOC_ESTIMATE.PC_LANG_ID%type
  , iCurrencyID       in     DOC_ESTIMATE.ACS_FINANCIAL_CURRENCY_ID%type
  , oStockId          out    DOC_ESTIMATE_POS.STM_STOCK_ID%type
  , oLocationId       out    DOC_ESTIMATE_POS.STM_LOCATION_ID%type
  , oNomenclatureId   out    DOC_ESTIMATE_POS.PPS_NOMENCLATURE_ID%type
  , oQuantity         out    DOC_ESTIMATE_ELEMENT_COST.DEC_QUANTITY%type
  , oRefQty           out    DOC_ESTIMATE_ELEMENT_COST.DEC_REF_QTY%type
  , oConversionFactor out    DOC_ESTIMATE_ELEMENT_COST.DEC_CONVERSION_FACTOR%type
  , oUnitPrice        out    DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_SALE_PRICE%type
  , oDeliveryDays     out    integer
  , oDicUnitOfMeasure out    DOC_ESTIMATE_POS.DIC_UNIT_OF_MEASURE_ID%type
  , oManagementMode   out    DOC_ESTIMATE_POS.C_MANAGEMENT_MODE%type
  , oSchedulePlan     out    DOC_ESTIMATE_POS.C_SCHEDULE_PLANNING%type
  , oSupplyMode       out    DOC_ESTIMATE_POS.C_SUPPLY_MODE%type
  , oSupplyType       out    DOC_ESTIMATE_POS.C_SUPPLY_TYPE%type
  , oGoodCategoryID   out    DOC_ESTIMATE_POS.GCO_GOOD_CATEGORY_ID%type
  , oReference        out    DOC_ESTIMATE_POS.DEP_REFERENCE%type
  , oSecondaryRef     out    DOC_ESTIMATE_POS.DEP_SECONDARY_REFERENCE%type
  , oShortDescr       out    DOC_ESTIMATE_POS.DEP_SHORT_DESCRIPTION%type
  , oLongDescr        out    DOC_ESTIMATE_POS.DEP_LONG_DESCRIPTION%type
  , oFreeDescr        out    DOC_ESTIMATE_POS.DEP_FREE_DESCRIPTION%type
  )
  is
    lnComplDataID      GCO_COMPL_DATA_SALE.GCO_COMPL_DATA_SALE_ID%type;
    lvFreeDescription  GCO_COMPL_DATA_SALE.CDA_FREE_DESCRIPTION%type;
    lvEanCode          GCO_COMPL_DATA_SALE.CDA_COMPLEMENTARY_EAN_CODE%type;
    lvEanUCC14Code     GCO_COMPL_DATA_SALE.CDA_COMPLEMENTARY_UCC14_CODE%type;
    lvHIBCPrimaryCode  GCO_COMPL_DATA_SALE.CSA_HIBC_CODE%type;
    lvDicUnitOfMeasure GCO_COMPL_DATA_SALE.DIC_UNIT_OF_MEASURE_ID%type;
    lnConvertFactor    GCO_COMPL_DATA_SALE.CDA_CONVERSION_FACTOR%type;
    lnNumberOfDecimal  GCO_COMPL_DATA_SALE.CDA_NUMBER_OF_DECIMAL%type;
    lvSqlIndiv         clob;
  begin
    -- La quantité de référence est initialisée par défaut à 1 dans le devis simplifié
    oRefQty := 1;
    oConversionFactor := 1;

    -- Recherche l'id des données compl. de vente
    lnComplDataID    := GCO_LIB_COMPL_DATA.GetComplDataSaleId(iGoodID => iGoodID, iThirdID => iCustomerID);

    if lnComplDataID = -1 then
      lnComplDataID  := null;
    end if;

    begin
      -- Mode de gestion du bien et catégorie du bien
      select SPA.C_SCHEDULE_PLANNING
        into oSchedulePlan
        from GCO_GOOD GOO
           , GCO_COMPL_DATA_MANUFACTURE CMA
           , FAL_SCHEDULE_PLAN SPA
       where GOO.GCO_GOOD_ID = iGoodID
         and GOO.GCO_GOOD_ID = CMA.GCO_GOOD_ID
         and CMA.CMA_DEFAULT = 1
         and SPA.FAL_SCHEDULE_PLAN_ID = CMA.FAL_SCHEDULE_PLAN_ID;
    exception
      when no_data_found then
        oSchedulePlan  := null;
    end;

    -- Données compl de vente du bien
    GCO_LIB_COMPL_DATA.GetComplementaryData(iGoodID               => iGoodID
                                          , iAdminDomain          => '2'
                                          , iThirdID              => iCustomerID
                                          , iLangID               => iLangID
                                          , iOperationID          => null
                                          , iTransProprietor      => null
                                          , iComplDataID          => lnComplDataID
                                          , oStockId              => oStockId
                                          , oLocationId           => oLocationId
                                          , oReference            => oReference
                                          , oSecondaryReference   => oSecondaryRef
                                          , oShortDescription     => oShortDescr
                                          , oLongDescription      => oLongDescr
                                          , oFreeDescription      => oFreeDescr
                                          , oEanCode              => lvEanCode
                                          , oEanUCC14Code         => lvEanUCC14Code
                                          , oHIBCPrimaryCode      => lvHIBCPrimaryCode
                                          , oDicUnitOfMeasure     => oDicUnitOfMeasure
                                          , oConvertFactor        => lnConvertFactor
                                          , oNumberOfDecimal      => lnNumberOfDecimal
                                          , oQuantity             => oQuantity
                                           );
    -- description courte
    lvSqlIndiv       := PCS.PC_FUNCTIONS.GetSql('DOC_ESTIMATE_POS', 'GET_POS_DESCRIPTION', 'GET_POS_SHORT_DESCRIPTION');

    -- Executer la méthode indiv si définie
    if PCS.PC_LIB_SQL.IsSqlEmpty(lvSqlIndiv) = 0 then
      oShortDescr  := GetIndivGoodShortDescr(iGoodID         => iGoodID, iLangId => iLangId, iThirdID => iCustomerID, iSql => lvSqlIndiv
                                           , iDefaultDescr   => oShortDescr);
    end if;

    -- description longue
    lvSqlIndiv       := PCS.PC_FUNCTIONS.GetSql('DOC_ESTIMATE_POS', 'GET_POS_DESCRIPTION', 'GET_POS_LONG_DESCRIPTION');

    -- Executer la méthode indiv si définie
    if PCS.PC_LIB_SQL.IsSqlEmpty(lvSqlIndiv) = 0 then
      oLongDescr  := GetIndivGoodLongDescr(iGoodID => iGoodID, iLangId => iLangId, iThirdID => iCustomerID, iSql => lvSqlIndiv, iDefaultDescr => oLongDescr);
    end if;

    -- description libre
    lvSqlIndiv       := PCS.PC_FUNCTIONS.GetSql('DOC_ESTIMATE_POS', 'GET_POS_DESCRIPTION', 'GET_POS_FREE_DESCRIPTION');

    -- Executer la méthode indiv si définie
    if PCS.PC_LIB_SQL.IsSqlEmpty(lvSqlIndiv) = 0 then
      oFreeDescr  := GetIndivGoodFreeDescr(iGoodID => iGoodID, iLangId => iLangId, iThirdID => iCustomerID, iSql => lvSqlIndiv, iDefaultDescr => oFreeDescr);
    end if;

    -- Mode de gestion du bien et catégorie du bien
    select GOO.C_MANAGEMENT_MODE
         , GOO.GCO_GOOD_CATEGORY_ID
         , PDT.C_SUPPLY_MODE
         , PDT.C_SUPPLY_TYPE
      into oManagementMode
         , oGoodCategoryID
         , oSupplyMode
         , oSupplyType
      from GCO_GOOD GOO
         , GCO_PRODUCT PDT
     where GOO.GCO_GOOD_ID = iGoodID
       and GOO.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+);

    -- Rechercher le délai de livraison sur la donnée compl. de vente + sur le client
    if lnComplDataID is not null then
      select nvl(CSA_TH_SUPPLY_DELAY, 0) + nvl(CSA_DISPATCHING_DELAY, 0) + nvl(nvl(CSA.CSA_DELIVERY_DELAY, CUS.CUS_DELIVERY_DELAY), 0)
        into oDeliveryDays
        from GCO_COMPL_DATA_SALE CSA
           , PAC_CUSTOM_PARTNER CUS
       where CSA.GCO_COMPL_DATA_SALE_ID = lnComplDataID
         and CUS.PAC_CUSTOM_PARTNER_ID = iCustomerID;
    else
      -- Rechercher le délai de livraison sur les données du client
      select nvl(max(CUS.CUS_DELIVERY_DELAY), 0)
        into oDeliveryDays
        from PAC_CUSTOM_PARTNER CUS
       where CUS.PAC_CUSTOM_PARTNER_ID = iCustomerID;
    end if;

    -- Prix de revient selon mode de gestion du produit
    oUnitPrice       :=
      GCO_LIB_PRICE.GetGoodPriceForView(iGoodId              => iGoodID
                                      , iTypePrice           => '9'
                                      , iThirdId             => iCustomerID
                                      , iRecordId            => null
                                      , iFalScheduleStepId   => null
                                      , ilDicTariff          => null
                                      , iQuantity            => oQuantity
                                      , iDateRef             => trunc(sysdate)
                                      , ioCurrencyId         => iCurrencyID
                                      , iDicTariff2          => null
                                       );
    oNomenclatureId  := PPS_I_LIB_FUNCTIONS.GetDefaultNomenclature(iGoodId, '2');   -- fabrication

    if oNomenclatureId is null then
      oNomenclatureId  := PPS_I_LIB_FUNCTIONS.GetDefaultNomenclature(iGoodId, '1');   -- vente
    end if;

    if oNomenclatureId is null then
      oNomenclatureId  := PPS_I_LIB_FUNCTIONS.GetDefaultNomenclature(iGoodId, '5');   -- étude
    end if;
  end GetGoodInfo;

  /**
  * procedure GetGoodInfo
  * Description
  *   Recherche les informations du bien
  */
  procedure GetGoodInfo(
    iGoodID           in     GCO_GOOD.GCO_GOOD_ID%type
  , iCustomerID       in     DOC_ESTIMATE.PAC_CUSTOM_PARTNER_ID%type
  , iLangID           in     DOC_ESTIMATE.PC_LANG_ID%type
  , iCurrencyID       in     DOC_ESTIMATE.ACS_FINANCIAL_CURRENCY_ID%type
  , oStockId          out    DOC_ESTIMATE_POS.STM_STOCK_ID%type
  , oLocationId       out    DOC_ESTIMATE_POS.STM_LOCATION_ID%type
  , oNomenclatureId   out    DOC_ESTIMATE_POS.PPS_NOMENCLATURE_ID%type
  , oQuantity         out    DOC_ESTIMATE_ELEMENT_COST.DEC_QUANTITY%type
  , oRefQty           out    DOC_ESTIMATE_ELEMENT_COST.DEC_REF_QTY%type
  , oConversionFactor out    DOC_ESTIMATE_ELEMENT_COST.DEC_CONVERSION_FACTOR%type
  , oUnitPrice        out    DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_SALE_PRICE%type
  , oDeliveryDate     out    DOC_ESTIMATE_POS.DEP_DELIVERY_DATE%type
  , oDicUnitOfMeasure out    DOC_ESTIMATE_POS.DIC_UNIT_OF_MEASURE_ID%type
  , oManagementMode   out    DOC_ESTIMATE_POS.C_MANAGEMENT_MODE%type
  , oSchedulePlan     out    DOC_ESTIMATE_POS.C_SCHEDULE_PLANNING%type
  , oSupplyMode       out    DOC_ESTIMATE_POS.C_SUPPLY_MODE%type
  , oSupplyType       out    DOC_ESTIMATE_POS.C_SUPPLY_TYPE%type
  , oGoodCategoryID   out    DOC_ESTIMATE_POS.GCO_GOOD_CATEGORY_ID%type
  , oReference        out    DOC_ESTIMATE_POS.DEP_REFERENCE%type
  , oSecondaryRef     out    DOC_ESTIMATE_POS.DEP_SECONDARY_REFERENCE%type
  , oShortDescr       out    DOC_ESTIMATE_POS.DEP_SHORT_DESCRIPTION%type
  , oLongDescr        out    DOC_ESTIMATE_POS.DEP_LONG_DESCRIPTION%type
  , oFreeDescr        out    DOC_ESTIMATE_POS.DEP_FREE_DESCRIPTION%type
  )
  is
    lnDeliveryDays integer;
  begin
    GetGoodInfo(iGoodID             => iGoodID
              , iCustomerID         => iCustomerID
              , iLangID             => iLangID
              , iCurrencyID         => iCurrencyID
              , oStockId            => oStockId
              , oLocationId         => oLocationId
              , oNomenclatureId     => oNomenclatureId
              , oQuantity           => oQuantity
              , oRefQty             => oRefQty
              , oConversionFactor   => oConversionFactor
              , oUnitPrice          => oUnitPrice
              , oDeliveryDays       => lnDeliveryDays
              , oDicUnitOfMeasure   => oDicUnitOfMeasure
              , oManagementMode     => oManagementMode
              , oSchedulePlan       => oSchedulePlan
              , oSupplyMode         => oSupplyMode
              , oSupplyType         => oSupplyType
              , oGoodCategoryID     => oGoodCategoryID
              , oReference          => oReference
              , oSecondaryRef       => oSecondaryRef
              , oShortDescr         => oShortDescr
              , oLongDescr          => oLongDescr
              , oFreeDescr          => oFreeDescr
               );
    oDeliveryDate  := DOC_DELAY_FUNCTIONS.GetShiftOpenDate(aDate => trunc(sysdate), aCalcDays => lnDeliveryDays, aAdminDomain => '2', aThirdID => iCustomerID);
  end GetGoodInfo;

  /**
  * Description
  *    Recherche le prix revient d'un bien selon son mode de gestion
  */
  function GetGoodCostPrice(iGoodID in GCO_GOOD.GCO_GOOD_ID%type, iThirdID in PAC_THIRD.PAC_THIRD_ID%type, iDateRef in date)
    return number
  is
  begin
    return GCO_LIB_PRICE.GetCostPriceWithManagementMode(iGCO_GOOD_ID => iGoodID, iPAC_THIRD_ID => iThirdID, iManagementMode => null, iDateRef => iDateRef);
  end GetGoodCostPrice;

  /**
  * procedure GetTaskInfo
  * Description
  *   Recherche les informations de l'opération
  */
  procedure GetTaskInfo(
    iFalTaskID       in     DOC_ESTIMATE_TASK.FAL_TASK_ID%type
  , iListStepLinkID  in     DOC_ESTIMATE_TASK.FAL_LIST_STEP_LINK_ID%type
  , iEstimateCode    in     DOC_ESTIMATE.C_DOC_ESTIMATE_CODE%type
  , oReference       out    DOC_ESTIMATE_TASK.DTK_REFERENCE%type
  , oDescription     out    DOC_ESTIMATE_TASK.DTK_DESCRIPTION%type
  , oTaskType        out    DOC_ESTIMATE_TASK.C_TASK_TYPE%type
  , oAdjustingTime   out    DOC_ESTIMATE_TASK.DTK_ADJUSTING_TIME%type
  , oQtyFixAdjusting out    DOC_ESTIMATE_TASK.DTK_QTY_FIX_ADJUSTING%type
  , oWorkTime        out    DOC_ESTIMATE_TASK.DTK_WORK_TIME%type
  , oQtyRefWork      out    DOC_ESTIMATE_TASK.DTK_QTY_REF_WORK%type
  , oRate1           out    DOC_ESTIMATE_TASK.DTK_RATE1%type
  , oRate2           out    DOC_ESTIMATE_TASK.DTK_RATE2%type
  , oAmount          out    DOC_ESTIMATE_TASK.DTK_AMOUNT%type
  , oQtyRefAmount    out    DOC_ESTIMATE_TASK.DTK_QTY_REF_AMOUNT%type
  , oDivisorAmount   out    DOC_ESTIMATE_TASK.DTK_DIVISOR_AMOUNT%type
  )
  is
    lnFactoryFloorID FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type;
    lnRate3          FAL_FACTORY_RATE.FFR_RATE3%type;
    lnRate4          FAL_FACTORY_RATE.FFR_RATE4%type;
    lnRate5          FAL_FACTORY_RATE.FFR_RATE5%type;
  begin
    oAdjustingTime    := 0;
    oQtyFixAdjusting  := 0;
    oWorkTime         := 0;
    oQtyRefWork       := 1;
    oRate1            := 0;
    oRate2            := 0;
    oAmount           := 0;
    oQtyRefAmount     := 1;
    oDivisorAmount    := 1;

    -- Mode Gestion à l'affaire (PRP)
    if nvl(iEstimateCode, 'PRP') = 'PRP' then
      oWorkTime    := 1;
      oQtyRefWork  := 1;
    end if;

    -- Informations de l'opération
    select TAS_REF
         , TAS_LONG_DESCR
         , C_TASK_TYPE
         , FAL_FACTORY_FLOOR_ID
      into oReference
         , oDescription
         , oTaskType
         , lnFactoryFloorID
      from FAL_TASK
     where FAL_TASK_ID = iFalTaskID;

    -- Mode production (MRP)
    -- Rechercher les infos de l'atelier et de la gamme opératoire
    if nvl(iEstimateCode, 'PRP') = 'MRP' then
      -- Rechercher le taux machine et le taux opérateur si l'atelier est spécifié
      if lnFactoryFloorID is not null then
        FAL_FACT_FLOOR.GetDateRateValues(aFAL_FACTORY_FLOOR_ID   => lnFactoryFloorID
                                       , aValidityDate           => trunc(sysdate)
                                       , aFFR_RATE1              => oRate1
                                       , aFFR_RATE2              => oRate2
                                       , aFFR_RATE3              => lnRate3
                                       , aFFR_RATE4              => lnRate4
                                       , aFFR_RATE5              => lnRate5
                                        );
      end if;

      -- Si le lien de l'opération dans une gamme opératoire est spécifié
      --  Rechercher les infos :
      --   "Temps de réglage", "Qté fixe de réglage", "Temps de travail" et "Qté réf de travail"
      if iListStepLinkID is not null then
        begin
          select SCS_ADJUSTING_TIME
               , SCS_QTY_FIX_ADJUSTING
               , SCS_WORK_TIME
               , SCS_QTY_REF_WORK
               , nvl(SCS_AMOUNT, 0)
               , nvl(SCS_QTY_REF_AMOUNT, 1)
               , nvl(SCS_DIVISOR_AMOUNT, 1)
            into oAdjustingTime
               , oQtyFixAdjusting
               , oWorkTime
               , oQtyRefWork
               , oAmount
               , oQtyRefAmount
               , oDivisorAmount
            from FAL_LIST_STEP_LINK
           where FAL_LIST_STEP_LINK_ID = iListStepLinkID;
        exception
          when no_data_found then
            oAdjustingTime    := 0;
            oQtyFixAdjusting  := 0;
            oWorkTime         := 0;
            oQtyRefWork       := 1;
            oAmount           := 0;
            oQtyRefAmount     := 1;
            oDivisorAmount    := 1;
        end;
      end if;
    end if;
  end GetTaskInfo;

    /**
  * procedure GetCreateMode
  * Description
  *   Mise à jour du mode de gestion des article de la position du devis
  * @created AGA 27.01.2012
  * @lastUpdate
  * @public
  * @param  ioGoodId : Id du bien de la position de devis
  * @param  ioReference : Référence de la position de devis
  * @param  ioCreateMode : Mode de création du bien de la position de devis
  */
  procedure GetCreateMode(
    ioGoodID     in out DOC_ESTIMATE_POS.GCO_GOOD_ID%type
  , ioReference  in out DOC_ESTIMATE_POS.DEP_REFERENCE%type
  , ioCreateMode in out DOC_ESTIMATE_POS.C_DOC_ESTIMATE_CREATE_MODE%type
  )
  is
    lnNewGoodId     DOC_ESTIMATE_POS.GCO_GOOD_ID%type;
    lnVirtualGoodID GCO_GOOD.GCO_GOOD_ID%type;
  begin
    if     ioGoodId is null
       and ioReference is null then
      ioCreateMode  := '00';   -- opérations
    elsif     ioGoodId is null
          and ioReference is not null then
      select nvl(max(GCO_GOOD_ID), 0)
        into lnNewGoodId
        from GCO_GOOD
       where GOO_MAJOR_REFERENCE = ioReference;

      if lnNewGoodId = 0 then
        ioCreateMode  := '01';   -- création nouvel article
      else
        ioGoodId      := lnNewGoodId;
        ioCreateMode  := '00';   -- utilisation article existant
      end if;
    elsif     ioGoodId is not null
          and ioReference is null then
      if nvl(ioCreateMode, '99') <> '00' then
        select GOO_MAJOR_REFERENCE
          into ioReference
          from GCO_GOOD
         where GCO_GOOD_ID = ioGoodId;

        ioCreateMode  := '00';   -- utilisation article existant
      else
        ioGoodId  := null;   -- opérations
      end if;
    elsif     ioGoodId is not null
          and ioReference is not null then
      select nvl(max(GCO_GOOD_ID), 0)
        into lnNewGoodId
        from GCO_GOOD
       where GOO_MAJOR_REFERENCE = ioReference;

      -- Rechercher l'id du produit virtuel
      lnVirtualGoodID  := nvl(FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', PCS.PC_CONFIG.GetConfig('DOC_ESTIMATE_GOOD') ), 0);

      if ioGoodID = lnVirtualGoodID then
        ioCreateMode  := '00';   -- utilisation article existant (produit virtuel)
      elsif ioGoodId <> lnNewGoodId then
        if lnNewGoodId = 0 then
          ioCreateMode  := '02';   -- copie article
        else
          ioGoodId      := lnNewGoodId;
          ioCreateMode  := '00';   -- utilisation article existant
        end if;
      elsif ioGoodId = lnNewGoodId then
        ioCreateMode  := '00';   -- utilisation article existant
      end if;
    end if;
  end GetCreateMode;

  /**
  * procedure GetPosNumber
  * Description
  *   Recherche le prochain numéro de position
  */
  function GetPosNumber(iEstimateID in DOC_ESTIMATE.DOC_ESTIMATE_ID%type)
    return number
  is
    lnDEP_NUMBER DOC_ESTIMATE_POS.DEP_NUMBER%type;
  begin
    -- Incrémenter la séquence de 10
    select nvl(max(DEP_NUMBER), 0) + 10
      into lnDEP_NUMBER
      from DOC_ESTIMATE_POS
     where DOC_ESTIMATE_ID = iEstimateID;

    return lnDEP_NUMBER;
  end GetPosNumber;

  /**
  * function GetElementNumber
  * Description
  *   Recherche le prochain numéro d'élément
  */
  function GetElementNumber(
    iEstimatePosID       in DOC_ESTIMATE_POS.DOC_ESTIMATE_POS_ID%type
  , iEstimateElementType in DOC_ESTIMATE_ELEMENT.C_DOC_ESTIMATE_ELEMENT_TYPE%type default null
  )
    return number
  is
    lnDED_NUMBER DOC_ESTIMATE_ELEMENT.DED_NUMBER%type;
  begin
    -- Incrémenter la séquence de 10
    if iEstimateElementType is null then
      select nvl(max(DED_NUMBER), 0) + 10
      into lnDED_NUMBER
      from DOC_ESTIMATE_ELEMENT
      where DOC_ESTIMATE_POS_ID = iEstimatePosID;
    else
      select nvl(max(DED_NUMBER), 0) + 10
      into lnDED_NUMBER
      from DOC_ESTIMATE_ELEMENT
      where DOC_ESTIMATE_POS_ID = iEstimatePosID and C_DOC_ESTIMATE_ELEMENT_TYPE = iEstimateElementType;
    end if;

    return lnDED_NUMBER;
  end GetElementNumber;

  /**
  * function InternalGetPosPrice
  * Description
  *   Méthode interne pour la recherche le prix de la position
  *     cette méthode appel une eventuelle indiv définie par l'utilisateur
  *     dans la commande sql DOC_ESTIMATE_POS/GET_POS_PRICE/GET_POS_PRICE
  */
  function InternalGetPosPrice(iGoodID in GCO_GOOD.GCO_GOOD_ID%type, iThirdID in PAC_THIRD.PAC_THIRD_ID%type, iDateRef in date, iQuantity in number)
    return number
  is
    lnPrice    DOC_ESTIMATE_ELEMENT_COST.DEC_COST_PRICE%type;
    lvSqlIndiv clob;
  begin
    lvSqlIndiv  := PCS.PC_FUNCTIONS.GetSql('DOC_ESTIMATE_POS', 'GET_POS_PRICE', 'GET_POS_PRICE');

    -- Executer la méthode indiv si définie
    if PCS.PC_LIB_SQL.IsSqlEmpty(lvSqlIndiv) = 0 then
      lnPrice  := GetIndivPosPrice(iGoodID => iGoodID, iThirdID => iThirdID, iDateRef => iDateRef, iQuantity => iQuantity, iSql => lvSqlIndiv);
    else
      lnPrice  := GetPosPrice(iGoodID => iGoodID, iThirdID => iThirdID, iDateRef => iDateRef, iQuantity => iQuantity);
    end if;

    return lnPrice;
  end InternalGetPosPrice;

  /**
  * function GetIndivPosPrice
  * Description
  *   Recherche le prix de la position avec la commande sql indiv
  */
  function GetIndivPosPrice(
    iGoodID   in GCO_GOOD.GCO_GOOD_ID%type
  , iThirdID  in PAC_THIRD.PAC_THIRD_ID%type
  , iDateRef  in date
  , iQuantity in number
  , iSql      in clob
  )
    return number
  is
    lnPrice DOC_ESTIMATE_ELEMENT_COST.DEC_COST_PRICE%type;
    lvSql   clob;
  begin
    lvSql  := upper(replace(iSql, '[COMPANY_OWNER' || '].', '') );
    lvSql  := replace(lvSql, '[CO' || '].', '');
    lvSql  := replace(lvSql, ':GCO_GOOD_ID', iGoodID);

    if iThirdID is null then
      lvSql  := replace(lvSql, ':PAC_THIRD_ID', 'null');
    else
      lvSql  := replace(lvSql, ':PAC_THIRD_ID', iThirdID);
    end if;

    if iDateRef is null then
      lvSql  := replace(lvSql, ':DATE_REF', 'null');
    else
      lvSql  := replace(lvSql, ':DATE_REF', 'to_date(''' || to_char(iDateRef, 'DD.MM.YYYY') || ''', ''DD.MM.YYYY'')');
    end if;

    if iQuantity is null then
      lvSql  := replace(lvSql, ':QUANTITY', 'null');
    else
      lvSql  := replace(lvSql, ':QUANTITY', iQuantity);
    end if;

    execute immediate lvSql
                 into lnPrice;

    return lnPrice;
  end GetIndivPosPrice;

  /**
  * function GetPosPrice
  * Description
  *   Recherche le prix de la position
  */
  function GetPosPrice(iGoodID in GCO_GOOD.GCO_GOOD_ID%type, iThirdID in PAC_THIRD.PAC_THIRD_ID%type, iDateRef in date, iQuantity in number)
    return number
  is
  begin
    return GetGoodCostPrice(iGoodID => iGoodID, iThirdID => iThirdID, iDateRef => iDateRef);
  end GetPosPrice;

  /**
  * function InternalGetCompPrice
  * Description
  *   Méthode interne pour la recherche le prix du composant
  *     cette méthode appel une eventuelle indiv définie par l'utilisateur
  *     dans la commande sql DOC_ESTIMATE_POS/GET_POS_PRICE/GET_POS_PRICE
  */
  function InternalGetCompPrice(iGoodID in GCO_GOOD.GCO_GOOD_ID%type, iThirdID in PAC_THIRD.PAC_THIRD_ID%type, iDateRef in date, iQuantity in number)
    return number
  is
    lnPrice    DOC_ESTIMATE_ELEMENT_COST.DEC_COST_PRICE%type;
    lvSqlIndiv clob;
  begin
    lvSqlIndiv  := PCS.PC_FUNCTIONS.GetSql('DOC_ESTIMATE_COMP', 'GET_COMP_PRICE', 'GET_COMP_PRICE');

    -- Executer la méthode indiv si définie
    if PCS.PC_LIB_SQL.IsSqlEmpty(lvSqlIndiv) = 0 then
      lnPrice  := GetIndivCompPrice(iGoodID => iGoodID, iThirdID => iThirdID, iDateRef => iDateRef, iQuantity => iQuantity, iSql => lvSqlIndiv);
    else
      lnPrice  := GetCompPrice(iGoodID => iGoodID, iThirdID => iThirdID, iDateRef => iDateRef, iQuantity => iQuantity);
    end if;

    return lnPrice;
  end InternalGetCompPrice;

  /**
  * function GetIndivCompPrice
  * Description
  *   Recherche le prix du composant avec la commande sql indiv
  */
  function GetIndivCompPrice(
    iGoodID   in GCO_GOOD.GCO_GOOD_ID%type
  , iThirdID  in PAC_THIRD.PAC_THIRD_ID%type
  , iDateRef  in date
  , iQuantity in number
  , iSql      in clob
  )
    return number
  is
    lnPrice DOC_ESTIMATE_ELEMENT_COST.DEC_COST_PRICE%type;
    lvSql   clob;
  begin
    lvSql  := upper(replace(iSql, '[COMPANY_OWNER' || '].', '') );
    lvSql  := replace(lvSql, '[CO' || '].', '');
    lvSql  := replace(lvSql, ':GCO_GOOD_ID', iGoodID);

    if iThirdID is null then
      lvSql  := replace(lvSql, ':PAC_THIRD_ID', 'null');
    else
      lvSql  := replace(lvSql, ':PAC_THIRD_ID', iThirdID);
    end if;

    if iDateRef is null then
      lvSql  := replace(lvSql, ':DATE_REF', 'null');
    else
      lvSql  := replace(lvSql, ':DATE_REF', 'to_date(''' || to_char(iDateRef, 'DD.MM.YYYY') || ''', ''DD.MM.YYYY'')');
    end if;

    if iQuantity is null then
      lvSql  := replace(lvSql, ':QUANTITY', 'null');
    else
      lvSql  := replace(lvSql, ':QUANTITY', iQuantity);
    end if;

    execute immediate lvSql
                 into lnPrice;

    return lnPrice;
  end GetIndivCompPrice;

  /**
  * function GetCompPrice
  * Description
  *   Recherche le prix du composant
  */
  function GetCompPrice(iGoodID in GCO_GOOD.GCO_GOOD_ID%type, iThirdID in PAC_THIRD.PAC_THIRD_ID%type, iDateRef in date, iQuantity in number)
    return number
  is
  begin
    return GetGoodCostPrice(iGoodID => iGoodID, iThirdID => iThirdID, iDateRef => iDateRef);
  end GetCompPrice;

  /**
  * function InternalGetTaskPrice
  * Description
  *   Méthode interne pour la recherche le prix de l'opération
  *     cette méthode appel une eventuelle indiv définie par l'utilisateur
  *     dans la commande sql DOC_ESTIMATE_TASK/GET_TASK_PRICE/GET_TASK_PRICE
  */
  function InternalGetTaskPrice(
    iTaskID          in FAL_TASK.FAL_TASK_ID%type
  , iThirdID         in PAC_THIRD.PAC_THIRD_ID%type
  , iEstimateCode    in DOC_ESTIMATE.C_DOC_ESTIMATE_CODE%type
  , iDateRef         in date
  , iQuantity        in number
  , iAdjustingTime   in DOC_ESTIMATE_TASK.DTK_ADJUSTING_TIME%type
  , iQtyFixAdjusting in DOC_ESTIMATE_TASK.DTK_QTY_FIX_ADJUSTING%type
  , iWorkTime        in DOC_ESTIMATE_TASK.DTK_WORK_TIME%type
  , iQtyRefWork      in DOC_ESTIMATE_TASK.DTK_QTY_REF_WORK%type
  , iRate1           in DOC_ESTIMATE_TASK.DTK_RATE1%type
  , iRate2           in DOC_ESTIMATE_TASK.DTK_RATE2%type
  , iAmount          in DOC_ESTIMATE_TASK.DTK_AMOUNT%type
  , iQtyRefAMount    in DOC_ESTIMATE_TASK.DTK_QTY_REF_AMOUNT%type
  , iDivisorAmount   in DOC_ESTIMATE_TASK.DTK_DIVISOR_AMOUNT%type
  )
    return number
  is
    lnPrice    DOC_ESTIMATE_ELEMENT_COST.DEC_COST_PRICE%type;
    lvSqlIndiv clob;
  begin
    lvSqlIndiv  := PCS.PC_FUNCTIONS.GetSql('DOC_ESTIMATE_TASK', 'GET_TASK_PRICE', 'GET_TASK_PRICE');

    -- Executer la méthode indiv si définie
    if PCS.PC_LIB_SQL.IsSqlEmpty(lvSqlIndiv) = 0 then
      lnPrice  :=
        GetIndivTaskPrice(iTaskID            => iTaskID
                        , iThirdID           => iThirdID
                        , iEstimateCode      => iEstimateCode
                        , iDateRef           => iDateRef
                        , iQuantity          => iQuantity
                        , iAdjustingTime     => iAdjustingTime
                        , iQtyFixAdjusting   => iQtyFixAdjusting
                        , iWorkTime          => iWorkTime
                        , iQtyRefWork        => iQtyRefWork
                        , iRate1             => iRate1
                        , iRate2             => iRate2
                        , iSql               => lvSqlIndiv
                        , iAmount            => iAmount
                        , iQtyRefAMount      => iQtyRefAMount
                        , iDivisorAmount     => iDivisorAmount
                         );
    else
      lnPrice  :=
        GetTaskPrice(iTaskID            => iTaskID
                   , iThirdID           => iThirdID
                   , iEstimateCode      => iEstimateCode
                   , iDateRef           => iDateRef
                   , iQuantity          => iQuantity
                   , iAdjustingTime     => iAdjustingTime
                   , iQtyFixAdjusting   => iQtyFixAdjusting
                   , iWorkTime          => iWorkTime
                   , iQtyRefWork        => iQtyRefWork
                   , iRate1             => iRate1
                   , iRate2             => iRate2
                   , iAmount            => iAmount
                   , iQtyRefAMount      => iQtyRefAMount
                   , iDivisorAmount     => iDivisorAmount
                    );
    end if;

    return lnPrice;
  end InternalGetTaskPrice;

  /**
  * function GetIndivTaskPrice
  * Description
  *   Recherche le prix de l'opération avec la commande sql indiv
  */
  function GetIndivTaskPrice(
    iTaskID          in FAL_TASK.FAL_TASK_ID%type
  , iThirdID         in PAC_THIRD.PAC_THIRD_ID%type
  , iEstimateCode    in DOC_ESTIMATE.C_DOC_ESTIMATE_CODE%type
  , iDateRef         in date
  , iQuantity        in number
  , iAdjustingTime   in DOC_ESTIMATE_TASK.DTK_ADJUSTING_TIME%type
  , iQtyFixAdjusting in DOC_ESTIMATE_TASK.DTK_QTY_FIX_ADJUSTING%type
  , iWorkTime        in DOC_ESTIMATE_TASK.DTK_WORK_TIME%type
  , iQtyRefWork      in DOC_ESTIMATE_TASK.DTK_QTY_REF_WORK%type
  , iRate1           in DOC_ESTIMATE_TASK.DTK_RATE1%type
  , iRate2           in DOC_ESTIMATE_TASK.DTK_RATE2%type
  , iSql             in clob
  , iAmount          in DOC_ESTIMATE_TASK.DTK_AMOUNT%type
  , iQtyRefAMount    in DOC_ESTIMATE_TASK.DTK_QTY_REF_AMOUNT%type
  , iDivisorAmount   in DOC_ESTIMATE_TASK.DTK_DIVISOR_AMOUNT%type
  )
    return number
  is
    lnPrice DOC_ESTIMATE_ELEMENT_COST.DEC_COST_PRICE%type;
    lvSql   clob;
  begin
    lvSql  := upper(replace(iSql, '[COMPANY_OWNER' || '].', '') );
    lvSql  := replace(lvSql, '[CO' || '].', '');
    lvSql  := replace(lvSql, ':FAL_TASK_ID', iTaskID);

    if iThirdID is null then
      lvSql  := replace(lvSql, ':PAC_THIRD_ID', 'null');
    else
      lvSql  := replace(lvSql, ':PAC_THIRD_ID', iThirdID);
    end if;

    if iEstimateCode is null then
      lvSql  := replace(lvSql, ':C_DOC_ESTIMATE_CODE', 'null');
    else
      lvSql  := replace(lvSql, ':C_DOC_ESTIMATE_CODE', '''' || iEstimateCode || '''');
    end if;

    if iDateRef is null then
      lvSql  := replace(lvSql, ':DATE_REF', 'null');
    else
      lvSql  := replace(lvSql, ':DATE_REF', 'to_date(''' || to_char(iDateRef, 'DD.MM.YYYY') || ''', ''DD.MM.YYYY'')');
    end if;

    if iQuantity is null then
      lvSql  := replace(lvSql, ':QUANTITY', 'null');
    else
      lvSql  := replace(lvSql, ':QUANTITY', iQuantity);
    end if;

    if iAdjustingTime is null then
      lvSql  := replace(lvSql, ':ADJUSTING_TIME', 'null');
    else
      lvSql  := replace(lvSql, ':ADJUSTING_TIME', iAdjustingTime);
    end if;

    if iQtyFixAdjusting is null then
      lvSql  := replace(lvSql, ':QTY_FIX_ADJUSTING', 'null');
    else
      lvSql  := replace(lvSql, ':QTY_FIX_ADJUSTING', iQtyFixAdjusting);
    end if;

    if iWorkTime is null then
      lvSql  := replace(lvSql, ':WORK_TIME', 'null');
    else
      lvSql  := replace(lvSql, ':WORK_TIME', iWorkTime);
    end if;

    if iQtyRefWork is null then
      lvSql  := replace(lvSql, ':QTY_REF_WORK', 'null');
    else
      lvSql  := replace(lvSql, ':QTY_REF_WORK', iQtyRefWork);
    end if;

    if iRate1 is null then
      lvSql  := replace(lvSql, ':RATE1', 'null');
    else
      lvSql  := replace(lvSql, ':RATE1', iRate1);
    end if;

    if iRate2 is null then
      lvSql  := replace(lvSql, ':RATE2', 'null');
    else
      lvSql  := replace(lvSql, ':RATE2', iRate2);
    end if;

    if iAmount is null then
      lvSql  := replace(lvSql, ':AMOUNT', 'null');
    else
      lvSql  := replace(lvSql, ':AMOUNT', iAmount);
    end if;

    if iQtyRefAmount is null then
      lvSql  := replace(lvSql, ':QTY_REF_AMOUNT', 'null');
    else
      lvSql  := replace(lvSql, ':QTY_REF_AMOUNT', iQtyRefAmount);
    end if;

    if iDivisorAmount is null then
      lvSql  := replace(lvSql, ':DIVISOR_AMOUNT', 'null');
    else
      lvSql  := replace(lvSql, ':DIVISOR_AMOUNT', iDivisorAmount);
    end if;

    execute immediate lvSql
                 into lnPrice;

    return lnPrice;
  end GetIndivTaskPrice;

  /**
  * function GetTaskPrice
  * Description
  *   Recherche le prix de l'opération
  */
  function GetTaskPrice(
    iTaskID          in FAL_TASK.FAL_TASK_ID%type
  , iThirdID         in PAC_THIRD.PAC_THIRD_ID%type
  , iEstimateCode    in DOC_ESTIMATE.C_DOC_ESTIMATE_CODE%type
  , iDateRef         in date
  , iQuantity        in number
  , iAdjustingTime   in DOC_ESTIMATE_TASK.DTK_ADJUSTING_TIME%type
  , iQtyFixAdjusting in DOC_ESTIMATE_TASK.DTK_QTY_FIX_ADJUSTING%type
  , iWorkTime        in DOC_ESTIMATE_TASK.DTK_WORK_TIME%type
  , iQtyRefWork      in DOC_ESTIMATE_TASK.DTK_QTY_REF_WORK%type
  , iRate1           in DOC_ESTIMATE_TASK.DTK_RATE1%type
  , iRate2           in DOC_ESTIMATE_TASK.DTK_RATE2%type
  , iAmount          in DOC_ESTIMATE_TASK.DTK_AMOUNT%type
  , iQtyRefAMount    in DOC_ESTIMATE_TASK.DTK_QTY_REF_AMOUNT%type
  , iDivisorAmount   in DOC_ESTIMATE_TASK.DTK_DIVISOR_AMOUNT%type
  )
    return number
  is
    lnPrice           DOC_ESTIMATE_ELEMENT_COST.DEC_COST_PRICE%type;
    lvTaskType        FAL_TASK.C_TASK_TYPE%type;
    lnSupplierID      PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type;
    lnConnectedGoodID GCO_GOOD.GCO_GOOD_ID%type;
    lnAdjusting       number;
    lnWork            number;
    lnRates           number;   -- Attention à la précision de cette variable ! Ne pas prendre le type de la colonne de la table.
    lnTaskAmount      number;
  begin
    lnPrice  := 0;

    if (nvl(iEstimateCode, 'PRP') = 'PRP') then
      -- Mode gestion PRP = Gestion à l'affaire
      -- Récupère le prix sur la nature analytique de la ressource de la tâche
      begin
        select GAL_PROJECT_SPENDING.GET_HOURLY_RATE_FROM_NAT_ANA(FAC.GAL_COST_CENTER_ID, iDateRef)
          into lnPrice
          from FAL_TASK TAS
             , FAL_FACTORY_FLOOR FAC
         where TAS.FAL_TASK_ID = iTaskID
           and FAC.FAL_FACTORY_FLOOR_ID = TAS.FAL_FACTORY_FLOOR_ID;
      exception
        when no_data_found then
          lnPrice  := null;
      end;
    end if;

    if (nvl(iEstimateCode, 'PRP') = 'MRP') then
      -- Mode de gestion MRP = Production
      -- Rechercher le type de l'opération
      select C_TASK_TYPE
           , PAC_SUPPLIER_PARTNER_ID
           , GCO_GCO_GOOD_ID
        into lvTaskType
           , lnSupplierID
           , lnConnectedGoodID
        from FAL_TASK
       where FAL_TASK_ID = iTaskID;

      -- Opération de type 1 : Interne
      if lvTaskType = '1' then
        -- Réglage
        if nvl(iQtyFixAdjusting, 0) > 1 then
          lnAdjusting  := nvl(iAdjustingTime, 0) * ceil(greatest( (iQuantity / nvl(iQtyFixAdjusting, 1) ), 1) );
        else
          lnAdjusting  := nvl(iAdjustingTime, 0);
        end if;

        -- Travail
        begin
          lnWork  := nvl( (iQuantity / nvl(iQtyRefWork, 0) ) * nvl(iWorkTime, 0), 0);
        exception
          when zero_divide then
            lnWork  := 0;
        end;

        -- Taux : taux machine (taux 1) + taux horaire (taux 2)
        lnRates  :=(nvl(iRate1, 0) + nvl(iRate2, 0) );

        -- Si les unités de temps sont en minute
        if upper(PCS.PC_CONFIG.GetConfig('PPS_WORK_UNIT') ) = 'M' then
          lnRates  := lnRates / 60;
        end if;

        -- Prix unitaire
        begin
          lnPrice  := ( (lnAdjusting + lnWork) * lnRates) / iQuantity;
        exception
          when zero_divide then
            lnPrice  := 0;
        end;
      else
        -- Opération de type 2 : Externe
        if     (lnConnectedGoodID is not null)
           and (lnSupplierID is not null) then
          -- Rechercher le tarif d'achat unitaire
          lnPrice  :=
            GCO_LIB_PRICE.GetGoodPriceForView(iGoodId              => lnConnectedGoodID
                                            , iTypePrice           => '1'
                                            , iThirdId             => lnSupplierID
                                            , iRecordId            => null
                                            , iFalScheduleStepId   => null
                                            , ilDicTariff          => null
                                            , iQuantity            => iQuantity
                                            , iDateRef             => iDateRef
                                            , ioCurrencyId         => ACS_FUNCTION.GetLocalCurrencyId
                                            , iDicTariff2          => null
                                             );
        end if;
      end if;

      /* Calcul du montant de l'opéraiton pour une quantité de 1 */
      if nvl(iDivisorAmount, 1) = 1 then
        begin
          lnTaskAmount  := iAmount *(1 / iQtyRefAmount);
        exception
          when zero_divide then
            lnTaskAmount  := 0;
        end;
      else
        lnTaskAmount  := iAmount *(1 * iQtyRefAmount);
      end if;

      /* Ajout du montant unitaire au prix de revient unitaire calculé */
      lnPrice  := lnPrice + lnTaskAmount;
    end if;

    return lnPrice;
  end GetTaskPrice;

  /**
  * function InternalGetPosMarginRate
  * Description
  *   Méthode interne pour la recherche de la marge unitaire de la position
  *     cette méthode appel une eventuelle indiv définie par l'utilisateur
  *     dans la commande sql DOC_ESTIMATE_POS/GET_POS_MARGIN/GET_POS_MARGIN
  */
  function InternalGetPosMarginRate(
    iGoodID       in GCO_GOOD.GCO_GOOD_ID%type
  , iThirdID      in PAC_THIRD.PAC_THIRD_ID%type
  , iEstimateCode in DOC_ESTIMATE.C_DOC_ESTIMATE_CODE%type
  , iDateRef      in date
  , iQuantity     in number
  )
    return number
  is
    lnMarginRate DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_MARGIN_RATE%type;
    lvSqlIndiv   clob;
  begin
    lvSqlIndiv  := PCS.PC_FUNCTIONS.GetSql('DOC_ESTIMATE_POS', 'GET_POS_MARGIN', 'GET_POS_MARGIN');

    -- Executer la méthode indiv si définie
    if PCS.PC_LIB_SQL.IsSqlEmpty(lvSqlIndiv) = 0 then
      lnMarginRate  :=
        GetIndivGoodMarginRate(iGoodID         => iGoodID
                             , iThirdID        => iThirdID
                             , iEstimateCode   => iEstimateCode
                             , iDateRef        => iDateRef
                             , iQuantity       => iQuantity
                             , iSql            => lvSqlIndiv
                              );
    else
      lnMarginRate  :=
                      GetGoodMarginRate(iGoodID         => iGoodID, iThirdID => iThirdID, iEstimateCode => iEstimateCode, iDateRef => iDateRef
                                      , iQuantity       => iQuantity);
    end if;

    return lnMarginRate;
  end InternalGetPosMarginRate;

  /**
  * function GetIndivGoodMarginRate
  * Description
  *   Recherche la marge unitaire de la position avec la commande sql indiv
  */
  function GetIndivGoodMarginRate(
    iGoodID       in GCO_GOOD.GCO_GOOD_ID%type
  , iThirdID      in PAC_THIRD.PAC_THIRD_ID%type
  , iEstimateCode in DOC_ESTIMATE.C_DOC_ESTIMATE_CODE%type
  , iDateRef      in date
  , iQuantity     in number
  , iSql          in clob
  )
    return number
  is
    lnMarginRate DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_MARGIN_RATE%type;
    lvSql        clob;
  begin
    lvSql  := upper(replace(iSql, '[COMPANY_OWNER' || '].', '') );
    lvSql  := replace(lvSql, '[CO' || '].', '');
    lvSql  := replace(lvSql, ':GCO_GOOD_ID', iGoodID);

    if iThirdID is null then
      lvSql  := replace(lvSql, ':PAC_THIRD_ID', 'null');
    else
      lvSql  := replace(lvSql, ':PAC_THIRD_ID', iThirdID);
    end if;

    if iEstimateCode is null then
      lvSql  := replace(lvSql, ':C_DOC_ESTIMATE_CODE', 'null');
    else
      lvSql  := replace(lvSql, ':C_DOC_ESTIMATE_CODE', '''' || iEstimateCode || '''');
    end if;

    if iDateRef is null then
      lvSql  := replace(lvSql, ':DATE_REF', 'null');
    else
      lvSql  := replace(lvSql, ':DATE_REF', 'to_date(''' || to_char(iDateRef, 'DD.MM.YYYY') || ''', ''DD.MM.YYYY'')');
    end if;

    if iQuantity is null then
      lvSql  := replace(lvSql, ':QUANTITY', 'null');
    else
      lvSql  := replace(lvSql, ':QUANTITY', iQuantity);
    end if;

    execute immediate lvSql
                 into lnMarginRate;

    return lnMarginRate;
  end GetIndivGoodMarginRate;

  /**
  * function InternalGetCompMarginRate
  * Description
  *   Méthode interne pour la recherche de la marge unitaire du composant
  *     cette méthode appel une eventuelle indiv définie par l'utilisateur
  *     dans la commande sql DOC_ESTIMATE_COMP/GET_COMP_MARGIN/GET_COMP_MARGIN
  */
  function InternalGetCompMarginRate(
    iGoodID       in GCO_GOOD.GCO_GOOD_ID%type
  , iThirdID      in PAC_THIRD.PAC_THIRD_ID%type
  , iEstimateCode in DOC_ESTIMATE.C_DOC_ESTIMATE_CODE%type
  , iDateRef      in date
  , iQuantity     in number
  )
    return number
  is
    lnMarginRate DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_MARGIN_RATE%type;
    lvSqlIndiv   clob;
  begin
    lvSqlIndiv  := PCS.PC_FUNCTIONS.GetSql('DOC_ESTIMATE_COMP', 'GET_COMP_MARGIN', 'GET_COMP_MARGIN');

    -- Executer la méthode indiv si définie
    if PCS.PC_LIB_SQL.IsSqlEmpty(lvSqlIndiv) = 0 then
      lnMarginRate  :=
        GetIndivGoodMarginRate(iGoodID         => iGoodID
                             , iThirdID        => iThirdID
                             , iEstimateCode   => iEstimateCode
                             , iDateRef        => iDateRef
                             , iQuantity       => iQuantity
                             , iSql            => lvSqlIndiv
                              );
    else
      lnMarginRate  :=
                      GetGoodMarginRate(iGoodID         => iGoodID, iThirdID => iThirdID, iEstimateCode => iEstimateCode, iDateRef => iDateRef
                                      , iQuantity       => iQuantity);
    end if;

    return lnMarginRate;
  end InternalGetCompMarginRate;

  /**
  * function GetGoodMarginRate
  * Description
  *   Recherche la marge unitaire du bien
  */
  function GetGoodMarginRate(
    iGoodID       in GCO_GOOD.GCO_GOOD_ID%type
  , iThirdID      in PAC_THIRD.PAC_THIRD_ID%type
  , iEstimateCode in DOC_ESTIMATE.C_DOC_ESTIMATE_CODE%type
  , iDateRef      in date
  , iQuantity     in number
  )
    return number
  is
    lnMarginRate DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_MARGIN_RATE%type;
  begin
    if (nvl(iEstimateCode, 'PRP') = 'PRP') then
      -- Mode gestion à l'affaire
      -- Récupère la marge de la nature analytique de la catégorie de bien si la catégorie de bien n'a pas de marge spécifiée.
      begin
        select nvl(CAT.CAT_UNIT_MARGIN_RATE, (select GCC.GCC_UNIT_MARGIN_RATE
                                                from GAL_COST_CENTER GCC
                                               where GCC.GAL_COST_CENTER_ID = CAT.GAL_COST_CENTER_ID) )
          into lnMarginRate
          from GCO_GOOD GOO
             , GCO_GOOD_CATEGORY CAT
         where GOO.GCO_GOOD_ID = iGoodID
           and CAT.GCO_GOOD_CATEGORY_ID = GOO.GCO_GOOD_CATEGORY_ID;
      exception
        when no_data_found then
          lnMarginRate  := null;
      end;

      return lnMarginRate;
    else
      -- Mode gestion de production
      -- Récupère la de la catégorie de bien
      begin
        select nvl(CAT.CAT_UNIT_MARGIN_RATE, 0)
          into lnMarginRate
          from GCO_GOOD GOO
             , GCO_GOOD_CATEGORY CAT
         where GOO.GCO_GOOD_ID = iGoodID
           and CAT.GCO_GOOD_CATEGORY_ID = GOO.GCO_GOOD_CATEGORY_ID;
      exception
        when no_data_found then
          lnMarginRate  := null;
      end;

      -- Mode gestion de production
      return lnMarginRate;
    end if;
  end GetGoodMarginRate;

  /**
  * function InternalGetTaskMarginRate
  * Description
  *   Méthode interne pour la recherche de la marge unitaire de l'opération
  *     cette méthode appel une eventuelle indiv définie par l'utilisateur
  *     dans la commande sql DOC_ESTIMATE_TASK/GET_TASK_MARGIN/GET_TASK_MARGIN
  */
  function InternalGetTaskMarginRate(
    iTaskID       in FAL_TASK.FAL_TASK_ID%type
  , iThirdID      in PAC_THIRD.PAC_THIRD_ID%type
  , iEstimateCode in DOC_ESTIMATE.C_DOC_ESTIMATE_CODE%type
  , iDateRef      in date
  , iQuantity     in number
  )
    return number
  is
    lnMarginRate DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_MARGIN_RATE%type;
    lvSqlIndiv   clob;
  begin
    lvSqlIndiv  := PCS.PC_FUNCTIONS.GetSql('DOC_ESTIMATE_TASK', 'GET_TASK_MARGIN', 'GET_TASK_MARGIN');

    -- Executer la méthode indiv si définie
    if PCS.PC_LIB_SQL.IsSqlEmpty(lvSqlIndiv) = 0 then
      lnMarginRate  :=
        GetIndivTaskMarginRate(iTaskID         => iTaskID
                             , iThirdID        => iThirdID
                             , iEstimateCode   => iEstimateCode
                             , iDateRef        => iDateRef
                             , iQuantity       => iQuantity
                             , iSql            => lvSqlIndiv
                              );
    else
      lnMarginRate  :=
                      GetTaskMarginRate(iTaskID         => iTaskID, iThirdID => iThirdID, iEstimateCode => iEstimateCode, iDateRef => iDateRef
                                      , iQuantity       => iQuantity);
    end if;

    return lnMarginRate;
  end InternalGetTaskMarginRate;

  /**
  * function GetIndivTaskMarginRate
  * Description
  *   Recherche la marge unitaire de l'opération avec la commande sql indiv
  */
  function GetIndivTaskMarginRate(
    iTaskID       in FAL_TASK.FAL_TASK_ID%type
  , iThirdID      in PAC_THIRD.PAC_THIRD_ID%type
  , iEstimateCode in DOC_ESTIMATE.C_DOC_ESTIMATE_CODE%type
  , iDateRef      in date
  , iQuantity     in number
  , iSql          in clob
  )
    return number
  is
    lnMarginRate DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_MARGIN_RATE%type;
    lvSql        clob;
  begin
    lvSql  := upper(replace(iSql, '[COMPANY_OWNER' || '].', '') );
    lvSql  := replace(lvSql, '[CO' || '].', '');
    lvSql  := replace(lvSql, ':FAL_TASK_ID', iTaskID);

    if iThirdID is null then
      lvSql  := replace(lvSql, ':PAC_THIRD_ID', 'null');
    else
      lvSql  := replace(lvSql, ':PAC_THIRD_ID', iThirdID);
    end if;

    if iEstimateCode is null then
      lvSql  := replace(lvSql, ':C_DOC_ESTIMATE_CODE', 'null');
    else
      lvSql  := replace(lvSql, ':C_DOC_ESTIMATE_CODE', '''' || iEstimateCode || '''');
    end if;

    if iDateRef is null then
      lvSql  := replace(lvSql, ':DATE_REF', 'null');
    else
      lvSql  := replace(lvSql, ':DATE_REF', 'to_date(''' || to_char(iDateRef, 'DD.MM.YYYY') || ''', ''DD.MM.YYYY'')');
    end if;

    if iQuantity is null then
      lvSql  := replace(lvSql, ':QUANTITY', 'null');
    else
      lvSql  := replace(lvSql, ':QUANTITY', iQuantity);
    end if;

    execute immediate lvSql
                 into lnMarginRate;

    return lnMarginRate;
  end GetIndivTaskMarginRate;

  /**
  * function GetTaskMarginRate
  * Description
  *   Recherche la marge unitaire de l'opération
  */
  function GetTaskMarginRate(
    iTaskID       in FAL_TASK.FAL_TASK_ID%type
  , iThirdID      in PAC_THIRD.PAC_THIRD_ID%type
  , iEstimateCode in DOC_ESTIMATE.C_DOC_ESTIMATE_CODE%type
  , iDateRef      in date
  , iQuantity     in number
  )
    return number
  is
    lnMarginRate DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_MARGIN_RATE%type;
  begin
    if (nvl(iEstimateCode, 'PRP') = 'PRP') then
      -- Mode gestion à l'affaire
      -- Récupère la marge de la nature analytique de la ressource de la tâche si la ressource n'a pas de marge spécifiée.
      begin
        select nvl(FAC.FAC_UNIT_MARGIN_RATE, (select GCC.GCC_UNIT_MARGIN_RATE
                                                from GAL_COST_CENTER GCC
                                               where GCC.GAL_COST_CENTER_ID = FAC.GAL_COST_CENTER_ID) )
          into lnMarginRate
          from FAL_TASK TAS
             , FAL_FACTORY_FLOOR FAC
         where TAS.FAL_TASK_ID = iTaskID
           and FAC.FAL_FACTORY_FLOOR_ID = TAS.FAL_FACTORY_FLOOR_ID;
      exception
        when no_data_found then
          lnMarginRate  := null;
      end;

      return lnMarginRate;
    else
      -- Mode gestion de production
      -- Récupère la marge de la ressource de la tâche
      begin
        select nvl(FAC.FAC_UNIT_MARGIN_RATE, 0)
          into lnMarginRate
          from FAL_TASK TAS
             , FAL_FACTORY_FLOOR FAC
         where TAS.FAL_TASK_ID = iTaskID
           and FAC.FAL_FACTORY_FLOOR_ID = TAS.FAL_FACTORY_FLOOR_ID;
      exception
        when no_data_found then
          lnMarginRate  := null;
      end;

      return lnMarginRate;
    end if;
  end GetTaskMarginRate;

  /**
   * function GetIndivGoodShortDescr
   * Description
   *   Recherche la description courte du bien
   * @created VJE 27.01.2012
   * @lastUpdate
   * @public
   * @param iGoodID       : id du bien
   * @param iLangId      : id de la langue
   * @param iThirdID  : id du tiers
   * @param iSql          : cmd sql indiv à executer
   * @Return Description courte
   */
  function GetIndivGoodShortDescr(
    iGoodID       in GCO_GOOD.GCO_GOOD_ID%type
  , iLangid       in PCS.PC_LANG.PC_LANG_ID%type
  , iThirdID      in PAC_THIRD.PAC_THIRD_ID%type
  , iSql          in clob
  , iDefaultDescr    GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type
  )
    return GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type
  is
    lvShortDescr DOC_ESTIMATE_POS.DEP_SHORT_DESCRIPTION%type;
    lvSql        clob;
  begin
    lvSql  := upper(replace(iSql, '[COMPANY_OWNER' || '].', '') );
    lvSql  := replace(lvSql, '[CO' || '].', '');
    lvSql  := replace(lvSql, ':GCO_GOOD_ID', iGoodId);
    lvSql  := replace(lvSql, ':PC_LANG_ID', iLangId);
    lvSql  := replace(lvSql, ':SHORT_DESCR', '''' || replace(iDefaultDescr, '''', '''''') || '''');

    if iThirdID is null then
      lvSql  := replace(lvSql, ':PAC_THIRD_ID', 'null');
    else
      lvSql  := replace(lvSql, ':PAC_THIRD_ID', iThirdID);
    end if;

    execute immediate lvSql
                 into lvShortDescr;

    return lvShortDescr;
  end GetIndivGoodShortDescr;

     /**
  * function GetIndivGoodLongDescr
  * Description
  *   Recherche la description longue du bien
  * @created VJE 27.01.2012
  * @lastUpdate
  * @public
  * @param iGoodID       : id du bien
  * @param iLangId      : id de la langue
  * @param iThirdID  : id du tiers
  * @param iSql          : cmd sql indiv à executer
  * @Return Description longue
  */
  function GetIndivGoodLongDescr(
    iGoodID       in GCO_GOOD.GCO_GOOD_ID%type
  , iLangid       in PCS.PC_LANG.PC_LANG_ID%type
  , iThirdID      in PAC_THIRD.PAC_THIRD_ID%type
  , iSql          in clob
  , iDefaultDescr    GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type
  )
    return GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type
  is
    lvLongDescr DOC_ESTIMATE_POS.DEP_LONG_DESCRIPTION%type;
    lvSql       clob;
  begin
    lvSql  := upper(replace(iSql, '[COMPANY_OWNER' || '].', '') );
    lvSql  := replace(lvSql, '[CO' || '].', '');
    lvSql  := replace(lvSql, ':GCO_GOOD_ID', iGoodId);
    lvSql  := replace(lvSql, ':PC_LANG_ID', iLangId);
    lvSql  := replace(lvSql, ':LONG_DESCR', '''' || replace(iDefaultDescr, '''', '''''') || '''');

    if iThirdID is null then
      lvSql  := replace(lvSql, ':PAC_THIRD_ID', 'null');
    else
      lvSql  := replace(lvSql, ':PAC_THIRD_ID', iThirdID);
    end if;

    execute immediate lvSql
                 into lvLongDescr;

    return lvLongDescr;
  end GetIndivGoodLongDescr;

     /**
  * function GetIndivGoodFreeDescr
  * Description
  *   Recherche la description Freeue du bien
  * @created VJE 27.01.2012
  * @lastUpdate
  * @public
  * @param iGoodID       : id du bien
  * @param iLangId      : id de la langue
  * @param iThirdID  : id du tiers
  * @param iSql          : cmd sql indiv à executer
  * @Return Description libre
  */
  function GetIndivGoodFreeDescr(
    iGoodID       in GCO_GOOD.GCO_GOOD_ID%type
  , iLangid       in PCS.PC_LANG.PC_LANG_ID%type
  , iThirdID      in PAC_THIRD.PAC_THIRD_ID%type
  , iSql          in clob
  , iDefaultDescr    GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type
  )
    return GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type
  is
    lvFreeDescr DOC_ESTIMATE_POS.DEP_FREE_DESCRIPTION%type;
    lvSql       clob;
  begin
    lvSql  := upper(replace(iSql, '[COMPANY_OWNER' || '].', '') );
    lvSql  := replace(lvSql, '[CO' || '].', '');
    lvSql  := replace(lvSql, ':GCO_GOOD_ID', iGoodId);
    lvSql  := replace(lvSql, ':PC_LANG_ID', iLangId);
    lvSql  := replace(lvSql, ':FREE_DESCR', '''' || replace(iDefaultDescr, '''', '''''') || '''');

    if iThirdID is null then
      lvSql  := replace(lvSql, ':PAC_THIRD_ID', 'null');
    else
      lvSql  := replace(lvSql, ':PAC_THIRD_ID', iThirdID);
    end if;

    execute immediate lvSql
                 into lvFreeDescr;

    return lvFreeDescr;
  end GetIndivGoodFreeDescr;
end DOC_LIB_ESTIMATE_POS;
