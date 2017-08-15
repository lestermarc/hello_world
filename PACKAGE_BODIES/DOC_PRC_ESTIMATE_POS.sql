--------------------------------------------------------
--  DDL for Package Body DOC_PRC_ESTIMATE_POS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_PRC_ESTIMATE_POS" 
is
  /**
  * procedure DeletePosChildren
  * Description
  *   Effacement en cascade des entités filles d'une position de devis
  */
  procedure DeletePosChildren(iEstimatePosID in DOC_ESTIMATE_POS.DOC_ESTIMATE_POS_ID%type)
  is
  begin
    -- Effacer les éléments liés à la position
    FWK_I_MGT_ENTITY.DeleteChildren(iv_child_name         => 'DOC_ESTIMATE_ELEMENT', iv_parent_key_name => 'DOC_ESTIMATE_POS_ID'
                                  , iv_parent_key_value   => iEstimatePosID);
    -- Effacer les éléments couts liés à la position
    FWK_I_MGT_ENTITY.DeleteChildren(iv_child_name         => 'DOC_ESTIMATE_ELEMENT_COST'
                                  , iv_parent_key_name    => 'DOC_ESTIMATE_POS_ID'
                                  , iv_parent_key_value   => iEstimatePosID
                                   );
  end DeletePosChildren;

  /**
  * procedure DeleteElementChildren
  * Description
  *   Effacement en cascade des entités filles d'un élément de devis
  */
  procedure DeleteElementChildren(iElementID in DOC_ESTIMATE_ELEMENT.DOC_ESTIMATE_ELEMENT_ID%type)
  is
  begin
    FWK_I_MGT_ENTITY.DeleteChildren(iv_child_name         => 'DOC_ESTIMATE_ELEMENT_COST'
                                  , iv_parent_key_name    => 'DOC_ESTIMATE_ELEMENT_ID'
                                  , iv_parent_key_value   => iElementID
                                   );
    FWK_I_MGT_ENTITY.DeleteChildren(iv_child_name => 'DOC_ESTIMATE_COMP', iv_parent_key_name => 'DOC_ESTIMATE_COMP_ID', iv_parent_key_value => iElementID);
    FWK_I_MGT_ENTITY.DeleteChildren(iv_child_name => 'DOC_ESTIMATE_TASK', iv_parent_key_name => 'DOC_ESTIMATE_TASK_ID', iv_parent_key_value => iElementID);
  end DeleteElementChildren;

  /**
  * procedure InitPosData
  * Description
  *   Initialisation des données de la position de devis (insert/update)
  */
  procedure InitPosData(iotEstimatePos in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lnEstimatePosID     DOC_ESTIMATE_POS.DOC_ESTIMATE_POS_ID%type;
    lnDEP_NUMBER        DOC_ESTIMATE_POS.DEP_NUMBER%type;
    lnEstimateID        DOC_ESTIMATE.DOC_ESTIMATE_ID%type;
    lnEstimateElementID DOC_ESTIMATE_ELEMENT.DOC_ESTIMATE_ELEMENT_ID%type;
    lnCustomerID        DOC_ESTIMATE.PAC_CUSTOM_PARTNER_ID%type;
    lnLangID            DOC_ESTIMATE.PC_LANG_ID%type;
    lnGoodId            DOC_ESTIMATE_POS.GCO_GOOD_ID%type;
    lnNewGoodId         DOC_ESTIMATE_POS.GCO_GOOD_ID%type;
    lnVirtualGoodID     DOC_ESTIMATE_POS.GCO_GOOD_ID%type;
    lnCurrencyID        DOC_ESTIMATE.ACS_FINANCIAL_CURRENCY_ID%type;
    lnStockId           DOC_ESTIMATE_POS.STM_STOCK_ID%type;
    lnLocationId        DOC_ESTIMATE_POS.STM_LOCATION_ID%type;
    lnNomenclatureId    DOC_ESTIMATE_POS.PPS_NOMENCLATURE_ID%type;
    lnQuantity          DOC_ESTIMATE_ELEMENT_COST.DEC_QUANTITY%type;
    lnRefQty            DOC_ESTIMATE_ELEMENT_COST.DEC_REF_QTY%type;
    lnConversionFactor  DOC_ESTIMATE_ELEMENT_COST.DEC_CONVERSION_FACTOR%type;
    lnUnitPrice         DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_SALE_PRICE%type;
    lvDicUnitOfMeasure  DOC_ESTIMATE_POS.DIC_UNIT_OF_MEASURE_ID%type;
    lvManagementMode    DOC_ESTIMATE_POS.C_MANAGEMENT_MODE%type;
    lvSchedulePlan      DOC_ESTIMATE_POS.C_SCHEDULE_PLANNING%type;
    lvSupplyMode        DOC_ESTIMATE_POS.C_SUPPLY_MODE%type;
    lvSupplyType        DOC_ESTIMATE_POS.C_SUPPLY_TYPE%type;
    lvCreateMode        DOC_ESTIMATE_POS.C_DOC_ESTIMATE_CREATE_MODE%type;
    lnGoodCategoryID    DOC_ESTIMATE_POS.GCO_GOOD_CATEGORY_ID%type;
    lnDeliveryDays      integer                                                default 0;
    lvReference         DOC_ESTIMATE_POS.DEP_REFERENCE%type;
    lvSecondaryRef      DOC_ESTIMATE_POS.DEP_SECONDARY_REFERENCE%type;
    lvShortDescr        DOC_ESTIMATE_POS.DEP_SHORT_DESCRIPTION%type;
    lvLongDescr         DOC_ESTIMATE_POS.DEP_LONG_DESCRIPTION%type;
    lvFreeDescr         DOC_ESTIMATE_POS.DEP_FREE_DESCRIPTION%type;
    ldDeliveryDate      date;
    lnCount             integer;
    ltElement           FWK_I_TYP_DEFINITION.t_crud_def;
    lvCDocEstimateCode  DOC_ESTIMATE.C_DOC_ESTIMATE_CODE%type;
    lbGenerateProduct   boolean;
  begin
    begin
      -- Vérifier si on est dans la màj suite à la création du bien
      if iotEstimatePos.attribute_list('GENERATE_PRODUCT') is not null then
        lbGenerateProduct  := true;
      else
        lbGenerateProduct  := false;
      end if;
    exception
      when no_data_found then
        lbGenerateProduct  := false;
    end;

    if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimatePos, 'DOC_ESTIMATE_ID') then
      lnEstimatePosID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimatePos, 'DOC_ESTIMATE_POS_ID');

      select DOC_ESTIMATE_ID
        into lnEstimateID
        from DOC_ESTIMATE_POS
       where DOC_ESTIMATE_POS_ID = lnEstimatePosID;
    else
      lnEstimateID     := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimatePos, 'DOC_ESTIMATE_ID');
      lnEstimatePosID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimatePos, 'DOC_ESTIMATE_POS_ID');
    end if;

    /* Récupération du mode de fonctionnement */
    select nvl(upper(C_DOC_ESTIMATE_CODE), 'PRP')
      into lvCDocEstimateCode
      from EV_DOC_ESTIMATE
     where DOC_ESTIMATE_ID = lnEstimateID;

    -- Rechercher les infos sur l'entête du devis
    select PAC_CUSTOM_PARTNER_ID
         , PC_LANG_ID
         , ACS_FINANCIAL_CURRENCY_ID
      into lnCustomerID
         , lnLangID
         , lnCurrencyID
      from DOC_ESTIMATE
     where DOC_ESTIMATE_ID = lnEstimateID;

    -- Init du n° de position si pas renseigné
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimatePos, 'DEP_NUMBER') then
      -- Incrémenter la séquence de 10
      lnDEP_NUMBER  := DOC_LIB_ESTIMATE_POS.GetPosNumber(lnEstimateID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'DEP_NUMBER', lnDEP_NUMBER);
    end if;

    -- Init du flag "Option" si pas renseigné
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimatePos, 'DEP_OPTION') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'DEP_OPTION', 0);
    end if;

    lnGoodId      := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimatePos, 'GCO_GOOD_ID');
    lvReference   := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotEstimatePos, 'DEP_REFERENCE');
    lvCreateMode  := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotEstimatePos, 'C_DOC_ESTIMATE_CREATE_MODE');

    if     not lbGenerateProduct
       and (   FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimatePos, 'GCO_GOOD_ID')
            or FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimatePos, 'DEP_REFERENCE') ) then
      -- recherche du code de gestion de la création des articles
      DOC_I_LIB_ESTIMATE_POS.GetCreateMode(lnGoodId, lvReference, lvCreateMode);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'C_DOC_ESTIMATE_CREATE_MODE', lvCreateMode);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'GCO_GOOD_ID', lnGoodId);
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotEstimatePos, 'PPS_NOMENCLATURE_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'DEP_REFERENCE', lvReference);

      if lvCreateMode = '00' then   --sans création
        -- suppression des composants
        for tplElement in (select DOC_ESTIMATE_ELEMENT_ID
                             from DOC_ESTIMATE_ELEMENT
                            where C_DOC_ESTIMATE_ELEMENT_TYPE = '01'
                              and DOC_ESTIMATE_POS_ID = lnEstimatePosID) loop
          FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimateElement, ltElement);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltElement, 'DOC_ESTIMATE_ELEMENT_ID', tplElement.DOC_ESTIMATE_ELEMENT_ID);
          -- Effacement de l'DOC_ESTIMATE_ELEMENT
          -- (DOC_ESTIMATE_ELEMENT_COST et DOC_ESTIMATE_COMP seront effacés par la surchage de l'effacement de DOC_ESTIMATE_ELEMENT)
          FWK_I_MGT_ENTITY.DeleteEntity(ltElement);
          FWK_I_MGT_ENTITY.Release(ltElement);
        end loop;

        -- Rechercher l'id du produit virtuel
        lnVirtualGoodID  := FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', PCS.PC_CONFIG.GetConfig('DOC_ESTIMATE_GOOD') );

        if     lnGoodId is not null
           and lvReference is not null
           and nvl(lnGoodId, 0) <> nvl(lnVirtualGoodID, 0) then
          -- suppression des tâches
          for tplElement in (select DOC_ESTIMATE_ELEMENT_ID
                               from DOC_ESTIMATE_ELEMENT
                              where C_DOC_ESTIMATE_ELEMENT_TYPE = '02'
                                and DOC_ESTIMATE_POS_ID = lnEstimatePosID) loop
            FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimateElement, ltElement);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltElement, 'DOC_ESTIMATE_ELEMENT_ID', tplElement.DOC_ESTIMATE_ELEMENT_ID);
            -- Effacement de l'DOC_ESTIMATE_ELEMENT
            -- (DOC_ESTIMATE_ELEMENT_COST et DOC_ESTIMATE_COMP seront effacés par la surchage de l'effacement de DOC_ESTIMATE_ELEMENT)
            FWK_I_MGT_ENTITY.DeleteEntity(ltElement);
            FWK_I_MGT_ENTITY.Release(ltElement);
          end loop;
        end if;
      end if;
    end if;

    -- Init des données liées au bien si celui-ci est renseigné
    if     not FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimatePos, 'GCO_GOOD_ID')
       and FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimatePos, 'GCO_GOOD_ID') then
      -- Rechercher les infos du bien
      DOC_LIB_ESTIMATE_POS.GetGoodInfo(iGoodID             => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimatePos, 'GCO_GOOD_ID')
                                     , iCustomerID         => lnCustomerID
                                     , iLangID             => lnLangID
                                     , iCurrencyID         => lnCurrencyID
                                     , oStockId            => lnStockId
                                     , oLocationId         => lnLocationId
                                     , oNomenclatureId     => lnNomenclatureId
                                     , oQuantity           => lnQuantity
                                     , oRefQty             => lnRefQty
                                     , oConversionFactor   => lnConversionFactor
                                     , oUnitPrice          => lnUnitPrice
                                     , oDeliveryDays       => lnDeliveryDays
                                     , oDicUnitOfMeasure   => lvDicUnitOfMeasure
                                     , oManagementMode     => lvManagementMode
                                     , oSchedulePlan       => lvSchedulePlan
                                     , oSupplyMode         => lvSupplyMode
                                     , oSupplyType         => lvSupplyType
                                     , oGoodCategoryID     => lnGoodCategoryID
                                     , oReference          => lvReference
                                     , oSecondaryRef       => lvSecondaryRef
                                     , oShortDescr         => lvShortDescr
                                     , oLongDescr          => lvLongDescr
                                     , oFreeDescr          => lvFreeDescr
                                      );

      -- id du stock
      if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimatePos, 'STM_STOCK_ID')
         or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimatePos, 'STM_STOCK_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'STM_STOCK_ID', lnStockId);
      end if;

      -- id de l'emplacement de stock
      if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimatePos, 'STM_LOCATION_ID')
         or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimatePos, 'STM_LOCATION_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'STM_LOCATION_ID', lnLocationId);
      end if;

      -- id de la nomenclature par défaut
      if     (lvCreateMode = '00')
         and (   FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimatePos, 'PPS_NOMENCLATURE_ID')
              or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimatePos, 'PPS_NOMENCLATURE_ID')
             ) then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'PPS_NOMENCLATURE_ID', lnNomenclatureId);
      end if;

      if lvCreateMode <> '00' then   -- pas de  création d'article
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotEstimatePos, 'PPS_NOMENCLATURE_ID');
      end if;

      -- Unité de mesure
      if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimatePos, 'DIC_UNIT_OF_MEASURE_ID')
         or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimatePos, 'DIC_UNIT_OF_MEASURE_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'DIC_UNIT_OF_MEASURE_ID', lvDicUnitOfMeasure);
      end if;

      -- Mode de gestion du bien
      if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimatePos, 'C_MANAGEMENT_MODE')
         or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimatePos, 'C_MANAGEMENT_MODE') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'C_MANAGEMENT_MODE', lvManagementMode);
      end if;

      -- Code planification
      if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimatePos, 'C_SCHEDULE_PLANNING')
         or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimatePos, 'C_SCHEDULE_PLANNING') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'C_SCHEDULE_PLANNING', lvManagementMode);
      end if;

      -- Mode d'approvisionnement du bien
      if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimatePos, 'C_SUPPLY_MODE')
         or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimatePos, 'C_SUPPLY_MODE') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'C_SUPPLY_MODE', lvSupplyMode);
      end if;

      -- Type d'approvisionnement du bien
      if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimatePos, 'C_SUPPLY_TYPE')
         or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimatePos, 'C_SUPPLY_TYPE') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'C_SUPPLY_TYPE', lvSupplyType);
      end if;

      -- id de la catégorie de bien
      if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimatePos, 'GCO_GOOD_CATEGORY_ID')
         or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimatePos, 'GCO_GOOD_CATEGORY_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'GCO_GOOD_CATEGORY_ID', lnGoodCategoryID);
      end if;

      -- Référence
      if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimatePos, 'DEP_REFERENCE')
         or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimatePos, 'DEP_REFERENCE') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'DEP_REFERENCE', lvReference);
      end if;

      -- Référence secondaire
      if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimatePos, 'DEP_SECONDARY_REFERENCE')
         or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimatePos, 'DEP_SECONDARY_REFERENCE') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'DEP_SECONDARY_REFERENCE', lvSecondaryRef);
      end if;

      -- Description courte
      if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimatePos, 'DEP_SHORT_DESCRIPTION')
         or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimatePos, 'DEP_SHORT_DESCRIPTION') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'DEP_SHORT_DESCRIPTION', lvShortDescr);
      end if;

      -- Description longue
      if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimatePos, 'DEP_LONG_DESCRIPTION')
         or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimatePos, 'DEP_LONG_DESCRIPTION') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'DEP_LONG_DESCRIPTION', lvLongDescr);
      end if;

      -- Description libre
      if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimatePos, 'DEP_FREE_DESCRIPTION')
         or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimatePos, 'DEP_FREE_DESCRIPTION') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'DEP_FREE_DESCRIPTION', lvFreeDescr);
      end if;
    end if;

    -- Mode d'approvisionnement du bien
    if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimatePos, 'C_SUPPLY_MODE')
       or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimatePos, 'C_SUPPLY_MODE') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'C_SUPPLY_MODE', '2');   -- produit fabriqué par défaut pour les composés
    end if;

    -- Type d'approvisionnement du bien
    if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimatePos, 'C_SUPPLY_TYPE')
       or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimatePos, 'C_SUPPLY_TYPE') then
      if lvCDocEstimateCode = 'MRP' then   -- OF
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'C_SUPPLY_TYPE', '1');   -- stock
      elsif lvCDocEstimateCode = 'PRP' then   -- Affaire
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'C_SUPPLY_TYPE', '2');   -- affaire
      end if;
    end if;

    -- Date de livraison
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimatePos, 'DEP_DELIVERY_DATE') then
      ldDeliveryDate  :=
                      DOC_DELAY_FUNCTIONS.GetShiftOpenDate(aDate          => trunc(sysdate), aCalcDays => lnDeliveryDays, aAdminDomain => '2'
                                                         , aThirdID       => lnCustomerID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'DEP_DELIVERY_DATE', ldDeliveryDate);
    end if;

    /* Pour les composés de produits de type b (création) */
    if FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotEstimatePos, 'C_DOC_ESTIMATE_CREATE_MODE') in('01', '02') then
      -- Mode d'approvisionnement
      /* seul le mode fabriqué (2) est autorisé */
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimatePos, 'C_SUPPLY_MODE') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'C_SUPPLY_MODE', '2');   -- fabriqué
      end if;

      -- Type d'approvisionnement
      /* Fonctionnement OF => type appro = stock, Fonctionnement Affaire => type appro = affaire */
      if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimatePos, 'C_SUPPLY_TYPE')
         or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimatePos, 'C_SUPPLY_TYPE') then
        if lvCDocEstimateCode = 'MRP' then   -- OF
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'C_SUPPLY_TYPE', '1');   -- stock
        elsif lvCDocEstimateCode = 'PRP' then   -- Affaire
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'C_SUPPLY_TYPE', '2');   -- affaire
        end if;
      end if;

      -- Stock et emplacement de stock
      /* Si le type d'approvisionnement = affaire */
      if FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotEstimatePos, 'C_SUPPLY_TYPE') = '2' then
        /* Initialisation du stock si null ou pas défini */
        if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimatePos, 'STM_STOCK_ID')
           or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimatePos, 'STM_STOCK_ID') then
          lnStockID  := STM_LIB_STOCK.GetDefaultProjectStock;
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'STM_STOCK_ID', lnStockID);
        end if;

        /* Initialisation de l'emplacement de stock si null ou pas défini */
        if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimatePos, 'STM_LOCATION_ID')
           or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimatePos, 'STM_LOCATION_ID') then
          lnLocationID  := STM_LIB_STOCK.GetDefaultProjectLocation(inDefaultProjectStockID => lnStockID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimatePos, 'STM_LOCATION_ID', lnLocationID);
        end if;
      end if;
    end if;
  end InitPosData;

  /**
  * procedure InitCompData
  * Description
  *   Initialisation des données d'un composant de devis (insert/update)
  */
  procedure InitCompData(iotEstimateComp in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lnElementID        DOC_ESTIMATE_ELEMENT.DOC_ESTIMATE_ELEMENT_ID%type;
    lnCustomerID       DOC_ESTIMATE.PAC_CUSTOM_PARTNER_ID%type;
    lnLangID           DOC_ESTIMATE.PC_LANG_ID%type;
    lnCurrencyID       DOC_ESTIMATE.ACS_FINANCIAL_CURRENCY_ID%type;
    lnStockId          DOC_ESTIMATE_POS.STM_STOCK_ID%type;
    lnLocationId       DOC_ESTIMATE_POS.STM_LOCATION_ID%type;
    lnNomenclatureId   DOC_ESTIMATE_POS.PPS_NOMENCLATURE_ID%type;
    lnQuantity         DOC_ESTIMATE_ELEMENT_COST.DEC_QUANTITY%type;
    lnRefQty           DOC_ESTIMATE_ELEMENT_COST.DEC_REF_QTY%type;
    lnConversionFactor DOC_ESTIMATE_ELEMENT_COST.DEC_CONVERSION_FACTOR%type;
    lnUnitPrice        DOC_ESTIMATE_ELEMENT_COST.DEC_UNIT_SALE_PRICE%type;
    lvDicUnitOfMeasure DOC_ESTIMATE_POS.DIC_UNIT_OF_MEASURE_ID%type;
    lvManagementMode   DOC_ESTIMATE_POS.C_MANAGEMENT_MODE%type;
    lvSchedulePlan     DOC_ESTIMATE_POS.C_SCHEDULE_PLANNING%type;
    lvSupplyMode       DOC_ESTIMATE_POS.C_SUPPLY_MODE%type;
    lvSupplyType       DOC_ESTIMATE_POS.C_SUPPLY_TYPE%type;
    lnGoodCategoryID   DOC_ESTIMATE_POS.GCO_GOOD_CATEGORY_ID%type;
    lnDeliveryDays     integer                                                default 0;
    lvReference        DOC_ESTIMATE_POS.DEP_REFERENCE%type;
    lvSecondaryRef     DOC_ESTIMATE_POS.DEP_SECONDARY_REFERENCE%type;
    lvShortDescr       DOC_ESTIMATE_POS.DEP_SHORT_DESCRIPTION%type;
    lvLongDescr        DOC_ESTIMATE_POS.DEP_LONG_DESCRIPTION%type;
    lvFreeDescr        DOC_ESTIMATE_POS.DEP_FREE_DESCRIPTION%type;
    ldDeliveryDate     date;
    lnGoodId           DOC_ESTIMATE_POS.GCO_GOOD_ID%type;
    lnNewGoodId        DOC_ESTIMATE_POS.GCO_GOOD_ID%type;
    lvCreateMode       DOC_ESTIMATE_POS.C_DOC_ESTIMATE_CREATE_MODE%type;
    lbGenerateProduct  boolean;
  begin
    begin
      -- Vérifier si on est dans la màj suite à la création du bien
      if iotEstimateComp.attribute_list('GENERATE_PRODUCT') is not null then
        lbGenerateProduct  := true;
      else
        lbGenerateProduct  := false;
      end if;
    exception
      when no_data_found then
        lbGenerateProduct  := false;
    end;

    lnElementID   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimateComp, 'DOC_ESTIMATE_COMP_ID');
    lnGoodId      := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimateComp, 'GCO_GOOD_ID');
    lvReference   := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotEstimateComp, 'ECP_REFERENCE');
    lvCreateMode  := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotEstimateComp, 'C_DOC_ESTIMATE_CREATE_MODE');

    if     not lbGenerateProduct
       and (   FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateComp, 'GCO_GOOD_ID')
            or FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateComp, 'ECP_REFERENCE') ) then
      -- recherche du code de gestion de la création des articles
      DOC_I_LIB_ESTIMATE_POS.GetCreateMode(lnGoodId, lvReference, lvCreateMode);
      --
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateComp, 'C_DOC_ESTIMATE_CREATE_MODE', lvCreateMode);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateComp, 'GCO_GOOD_ID', lnGoodId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateComp, 'ECP_REFERENCE', lvReference);
    end if;

    -- Init des données liées au bien si celui-ci est renseigné
    if     not FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateComp, 'GCO_GOOD_ID')
       and FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateComp, 'GCO_GOOD_ID') then
      -- Rechercher les infos sur l'entête du devis
      select DES.PAC_CUSTOM_PARTNER_ID
           , DES.PC_LANG_ID
           , DES.ACS_FINANCIAL_CURRENCY_ID
        into lnCustomerID
           , lnLangID
           , lnCurrencyID
        from DOC_ESTIMATE DES
           , DOC_ESTIMATE_POS DEP
           , DOC_ESTIMATE_ELEMENT DED
       where DED.DOC_ESTIMATE_ELEMENT_ID = lnElementID
         and DED.DOC_ESTIMATE_POS_ID = DEP.DOC_ESTIMATE_POS_ID
         and DEP.DOC_ESTIMATE_ID = DES.DOC_ESTIMATE_ID;

      -- Rechercher les infos du bien
      DOC_LIB_ESTIMATE_POS.GetGoodInfo(iGoodID             => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimateComp, 'GCO_GOOD_ID')
                                     , iCustomerID         => lnCustomerID
                                     , iLangID             => lnLangID
                                     , iCurrencyID         => lnCurrencyID
                                     , oStockId            => lnStockId
                                     , oLocationId         => lnLocationId
                                     , oNomenclatureId     => lnNomenclatureId
                                     , oQuantity           => lnQuantity
                                     , oRefQty             => lnRefQty
                                     , oConversionFactor   => lnConversionFactor
                                     , oUnitPrice          => lnUnitPrice
                                     , oDeliveryDays       => lnDeliveryDays
                                     , oDicUnitOfMeasure   => lvDicUnitOfMeasure
                                     , oManagementMode     => lvManagementMode
                                     , oSchedulePlan       => lvSchedulePlan
                                     , oSupplyMode         => lvSupplyMode
                                     , oSupplyType         => lvSupplyType
                                     , oGoodCategoryID     => lnGoodCategoryID
                                     , oReference          => lvReference
                                     , oSecondaryRef       => lvSecondaryRef
                                     , oShortDescr         => lvShortDescr
                                     , oLongDescr          => lvLongDescr
                                     , oFreeDescr          => lvFreeDescr
                                      );

      -- id du stock
      if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateComp, 'STM_STOCK_ID')
         or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateComp, 'STM_STOCK_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateComp, 'STM_STOCK_ID', lnStockId);
      end if;

      -- id de l'emplacement de stock
      if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateComp, 'STM_LOCATION_ID')
         or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateComp, 'STM_LOCATION_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateComp, 'STM_LOCATION_ID', lnLocationId);
      end if;

      -- Unité de mesure
      if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateComp, 'DIC_UNIT_OF_MEASURE_ID')
         or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateComp, 'DIC_UNIT_OF_MEASURE_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateComp, 'DIC_UNIT_OF_MEASURE_ID', lvDicUnitOfMeasure);
      end if;

      -- Mode de gestion du bien
      if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateComp, 'C_MANAGEMENT_MODE')
         or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateComp, 'C_MANAGEMENT_MODE') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateComp, 'C_MANAGEMENT_MODE', lvManagementMode);
      end if;

      -- Mode d'approvisionnement du bien
      if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateComp, 'C_SUPPLY_MODE')
         or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateComp, 'C_SUPPLY_MODE') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateComp, 'C_SUPPLY_MODE', lvSupplyMode);
      end if;

      -- Type d'approvisionnement du bien
      if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateComp, 'C_SUPPLY_TYPE')
         or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateComp, 'C_SUPPLY_TYPE') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateComp, 'C_SUPPLY_TYPE', lvSupplyType);
      end if;

      -- id de la catégorie de bien
      if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateComp, 'GCO_GOOD_CATEGORY_ID')
         or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateComp, 'GCO_GOOD_CATEGORY_ID') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateComp, 'GCO_GOOD_CATEGORY_ID', lnGoodCategoryID);
      end if;

      -- Référence
      if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateComp, 'ECP_REFERENCE')
         or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateComp, 'ECP_REFERENCE') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateComp, 'ECP_REFERENCE', lvReference);
      end if;

      -- Référence secondaire
      if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateComp, 'ECP_SECONDARY_REFERENCE')
         or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateComp, 'ECP_SECONDARY_REFERENCE') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateComp, 'ECP_SECONDARY_REFERENCE', lvSecondaryRef);
      end if;

      -- Description courte
      if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateComp, 'ECP_SHORT_DESCRIPTION')
         or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateComp, 'ECP_SHORT_DESCRIPTION') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateComp, 'ECP_SHORT_DESCRIPTION', lvShortDescr);
      end if;

      -- Description longue
      if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateComp, 'ECP_LONG_DESCRIPTION')
         or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateComp, 'ECP_LONG_DESCRIPTION') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateComp, 'ECP_LONG_DESCRIPTION', lvLongDescr);
      end if;

      -- Description libre
      if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateComp, 'ECP_FREE_DESCRIPTION')
         or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateComp, 'ECP_FREE_DESCRIPTION') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateComp, 'ECP_FREE_DESCRIPTION', lvFreeDescr);
      end if;
    end if;

    -- Mode d'approvisionnement du bien
    if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateComp, 'C_SUPPLY_MODE')
       or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateComp, 'C_SUPPLY_MODE') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateComp, 'C_SUPPLY_MODE', '1');   -- produit acheté par défaut pour les composants
    end if;

    /* Pour les composés de produits de type b (création) */
    if FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotEstimateComp, 'C_DOC_ESTIMATE_CREATE_MODE') in('01', '02') then
      -- Stock et emplacement de stock
      /* Si le type d'approvisionnement = affaire */
      if FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotEstimateComp, 'C_SUPPLY_TYPE') = '2' then
        /* Initialisation du stock si null ou pas défini */
        if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateComp, 'STM_STOCK_ID')
           or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateComp, 'STM_STOCK_ID') then
          lnStockID  := STM_LIB_STOCK.GetDefaultProjectStock;
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateComp, 'STM_STOCK_ID', lnStockID);
        end if;

        /* Initialisation de l'emplacement de stock si null ou pas défini */
        if    FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateComp, 'STM_LOCATION_ID')
           or not FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateComp, 'STM_LOCATION_ID') then
          lnLocationID  := STM_LIB_STOCK.GetDefaultProjectLocation(inDefaultProjectStockID => lnStockID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateComp, 'STM_LOCATION_ID', lnLocationID);
        end if;
      end if;
    end if;
  end InitCompData;

  /**
  * procedure InitTaskData
  * Description
  *   Initialisation des données d'une opération de devis (insert/update)
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotEstimateTask : DOC_ESTIMATE_TASK de type T_CRUD_DEF
  */
  procedure InitTaskData(iotEstimateTask in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lnTaskID          FAL_TASK.FAL_TASK_ID%type;
    lnListStepLinkID  DOC_ESTIMATE_TASK.FAL_LIST_STEP_LINK_ID%type;
    lnElementID       DOC_ESTIMATE_ELEMENT.DOC_ESTIMATE_ELEMENT_ID%type;
    lvEstimateCode    DOC_ESTIMATE.C_DOC_ESTIMATE_CODE%type;
    lvReference       DOC_ESTIMATE_TASK.DTK_REFERENCE%type;
    lvDescription     DOC_ESTIMATE_TASK.DTK_DESCRIPTION%type;
    lvTaskType        DOC_ESTIMATE_TASK.C_TASK_TYPE%type;
    lnAdjustingTime   DOC_ESTIMATE_TASK.DTK_ADJUSTING_TIME%type;
    lnQtyFixAdjusting DOC_ESTIMATE_TASK.DTK_QTY_FIX_ADJUSTING%type;
    lnWorkTime        DOC_ESTIMATE_TASK.DTK_WORK_TIME%type;
    lnQtyRefWork      DOC_ESTIMATE_TASK.DTK_QTY_REF_WORK%type;
    lnRate1           DOC_ESTIMATE_TASK.DTK_RATE1%type;
    lnRate2           DOC_ESTIMATE_TASK.DTK_RATE2%type;
    lnAmount          DOC_ESTIMATE_TASK.DTK_AMOUNT%type;
    lnQtyRefAmount    DOC_ESTIMATE_TASK.DTK_QTY_REF_AMOUNT%type;
    lnDivisorAmount   DOC_ESTIMATE_TASK.DTK_DIVISOR_AMOUNT%type;
  begin
    lnElementID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimateTask, 'DOC_ESTIMATE_TASK_ID');

    -- Init du flag "Mode de création" si pas renseigné
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateTask, 'C_DOC_ESTIMATE_CREATE_MODE') then
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateTask, 'FAL_TASK_ID') then
        -- Le bien n'est PAS renseigné, alors init du "Mode de création" à '01' - création
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateTask, 'C_DOC_ESTIMATE_CREATE_MODE', '01');
      else
        -- Le bien est renseigné, alors init du "Mode de création" à '00' - sans création
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateTask, 'C_DOC_ESTIMATE_CREATE_MODE', '00');
      end if;
    end if;

    -- Init des données liées à l'opération
    if     not FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateTask, 'FAL_TASK_ID')
       and FWK_I_MGT_ENTITY_DATA.IsModified(iotEstimateTask, 'FAL_TASK_ID') then
      lnTaskID          := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimateTask, 'FAL_TASK_ID');
      lnListStepLinkID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimateTask, 'FAL_LIST_STEP_LINK_ID');

      -- Rechercher le mode de gestion du devis
      select DES.C_DOC_ESTIMATE_CODE
        into lvEstimateCode
        from DOC_ESTIMATE DES
           , DOC_ESTIMATE_POS DEP
           , DOC_ESTIMATE_ELEMENT DED
       where DED.DOC_ESTIMATE_ELEMENT_ID = lnElementID
         and DED.DOC_ESTIMATE_POS_ID = DEP.DOC_ESTIMATE_POS_ID
         and DEP.DOC_ESTIMATE_ID = DES.DOC_ESTIMATE_ID;

      -- Rechercher les infos de l'opération
      DOC_LIB_ESTIMATE_POS.GetTaskInfo(iFalTaskId         => lnTaskID
                                     , iListStepLinkID    => lnListStepLinkID
                                     , iEstimateCode      => lvEstimateCode
                                     , oReference         => lvReference
                                     , oDescription       => lvDescription
                                     , oTaskType          => lvTaskType
                                     , oAdjustingTime     => lnAdjustingTime
                                     , oQtyFixAdjusting   => lnQtyFixAdjusting
                                     , oWorkTime          => lnWorkTime
                                     , oQtyRefWork        => lnQtyRefWork
                                     , oRate1             => lnRate1
                                     , oRate2             => lnRate2
                                     , oAmount            => lnAmount
                                     , oQtyRefAmount      => lnQtyRefAmount
                                     , oDivisorAmount     => lnDivisorAmount
                                      );

      -- Reference
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateTask, 'DTK_REFERENCE') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateTask, 'DTK_REFERENCE', lvReference);
      end if;

      -- Description
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateTask, 'DTK_DESCRIPTION') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateTask, 'DTK_DESCRIPTION', lvDescription);
      end if;

      -- Genre d'opération
      if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateTask, 'C_TASK_TYPE') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateTask, 'C_TASK_TYPE', lvTaskType);
      end if;

      if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateTask, 'DTK_ADJUSTING_TIME') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateTask, 'DTK_ADJUSTING_TIME', lnAdjustingTime);
      end if;

      if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateTask, 'DTK_QTY_FIX_ADJUSTING') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateTask, 'DTK_QTY_FIX_ADJUSTING', lnQtyFixAdjusting);
      end if;

      if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateTask, 'DTK_WORK_TIME') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateTask, 'DTK_WORK_TIME', lnWorkTime);
      end if;

      if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateTask, 'DTK_QTY_REF_WORK') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateTask, 'DTK_QTY_REF_WORK', lnQtyRefWork);
      end if;

      if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateTask, 'DTK_RATE1') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateTask, 'DTK_RATE1', lnRate1);
      end if;

      if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateTask, 'DTK_RATE2') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateTask, 'DTK_RATE2', lnRate2);
      end if;

      if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateTask, 'DTK_AMOUNT') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateTask, 'DTK_AMOUNT', lnAmount);
      end if;

      if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateTask, 'DTK_QTY_REF_AMOUNT') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateTask, 'DTK_QTY_REF_AMOUNT', lnQtyRefAmount);
      end if;

      if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateTask, 'DTK_DIVISOR_AMOUNT') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateTask, 'DTK_DIVISOR_AMOUNT', lnDivisorAmount);
      end if;
    end if;
  end InitTaskData;

  /**
  * procedure InitElementData
  * Description
  *   Initialisation des données d'un élément d'une position de devis (insert/update)
  */
  procedure InitElementData(iotEstimateElement in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lnEstimatePosID DOC_ESTIMATE_POS.DOC_ESTIMATE_POS_ID%type;
    lnDED_NUMBER    DOC_ESTIMATE_ELEMENT.DED_NUMBER%type;
  begin
    -- Init du n°  si pas renseigné
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimateElement, 'DED_NUMBER') then
      lnEstimatePosID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimateElement, 'DOC_ESTIMATE_POS_ID');
      -- Incrémenter la séquence de 10
      lnDED_NUMBER     :=
        DOC_LIB_ESTIMATE_POS.GetElementNumber(lnEstimatePosID
                                            , FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotEstimateElement
                                                                                    , 'C_DOC_ESTIMATE_ELEMENT_TYPE'
                                                                                     )
                                             );
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimateElement, 'DED_NUMBER', lnDED_NUMBER);
    end if;
  end InitElementData;

  /**
  * procedure DuplicateEstimatePos
  * Description
  *   Copie d'une position de devis
  */
  procedure DuplicateEstimatePos(
    inRefEstimateID    in     DOC_ESTIMATE.DOC_ESTIMATE_ID%type
  , inRefEstimatePosID in     DOC_ESTIMATE_POS.DOC_ESTIMATE_POS_ID%type
  , inRefGcoGoodID     in     DOC_ESTIMATE_POS.GCO_GOOD_ID%type
  , onNewEstimatePosID out    DOC_ESTIMATE.DOC_ESTIMATE_ID%type
  , inNewQuantity      in     DOC_ESTIMATE_ELEMENT_COST.DEC_QUANTITY%type
  , inDoSetOptionFlag  in     number default 1
  )
  is
    lnNewEstimatePosID     DOC_ESTIMATE_POS.DOC_ESTIMATE_POS_ID%type;
    lnNewEstimateElementId DOC_ESTIMATE_ELEMENT.DOC_ESTIMATE_ELEMENT_ID%type;
    ltEstimatePos          FWK_I_TYP_DEFINITION.t_crud_def;
    ltEstimateElement      FWK_I_TYP_DEFINITION.t_crud_def;
    lnDepNumber            DOC_ESTIMATE_POS.DEP_NUMBER%type;
    lnOldQuantity          DOC_ESTIMATE_ELEMENT_COST.DEC_QUANTITY%type;
  begin
    /* Récupération d'un ID pour la nouvelle position */
    lnNewEstimatePosID  := getNewId;
    FWK_I_MGT_ENTITY.new(iv_entity_name        => FWK_TYP_DOC_ENTITY.gcEvDocEstimatePos, iot_crud_definition => ltEstimatePos
                       , iv_primary_col        => 'DOC_ESTIMATE_POS_ID');
    FWK_I_MGT_ENTITY.prepareDuplicate(ltEstimatePos, true, inRefEstimatePosID);
    -- id principal
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltEstimatePos, 'DOC_ESTIMATE_POS_ID', lnNewEstimatePosID);
    -- id principal des éléments de coût
    FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltEstimatePos, 'DOC_ESTIMATE_ELEMENT_COST_ID');
    -- id du code budget généré
    FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltEstimatePos, 'GAL_BUDGET_ID');
    -- id de la tâche générée
    FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltEstimatePos, 'GAL_TASK_ID');
    -- id devis
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltEstimatePos, 'DOC_ESTIMATE_ID', inRefEstimateID);

    if inDoSetOptionFlag = 1 then
      -- "Une ligne copiée prend automatiquement le flag option" (cf document d'analyse, p.16)
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltEstimatePos, 'DEP_OPTION', 1);
    else
      -- Copie d'une position sans basculer le flag option à 1
      -- Il faut modifier la référence du bien à créer si on est en création de bien
      -- On va générer une nouvelle référence avec le suffixe <NEW1>
      if FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(ltEstimatePos, 'C_DOC_ESTIMATE_CREATE_MODE') in('01', '02') then
        declare
          lvNewRef  DOC_ESTIMATE_POS.DEP_REFERENCE%type;
          lnCounter integer                               := null;
          lvSuffix  varchar2(30);
          lnGoodID  GCO_GOOD.GCO_GOOD_ID%type;
        begin
          lvNewRef  := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(ltEstimatePos, 'DEP_REFERENCE');

          select max(GCO_GOOD_ID)
            into lnGoodID
            from GCO_GOOD
           where GOO_MAJOR_REFERENCE = lvNewRef;

          -- Rechercher une nouvelle réf. de bien
          while(lnGoodID is not null) loop
            lvSuffix   := '<NEW' || lnCounter || '>';
            lvNewRef   := substr(FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(ltEstimatePos, 'DEP_REFERENCE'), 1, 30 - length(lvSuffix) ) || lvSuffix;

            select max(GCO_GOOD_ID)
              into lnGoodID
              from GCO_GOOD
             where GOO_MAJOR_REFERENCE = lvNewRef;

            lnCounter  := nvl(lnCounter, 0) + 1;
          end loop;

          if lvNewRef <> FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(ltEstimatePos, 'DEP_REFERENCE') then
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltEstimatePos, 'DEP_REFERENCE', lvNewRef);
          end if;
        end;
      end if;
    end if;

    -- Numéro de position : Incrémenter la séquence de 10
    lnDepNumber         := DOC_LIB_ESTIMATE_POS.GetPosNumber(inRefEstimateID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltEstimatePos, 'DEP_NUMBER', lnDepNumber);
    /* Ancienne quantité */
    lnOldQuantity := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltEstimatePos, 'DEC_QUANTITY');

    /* Insertion de la nouvelle position */
    FWK_I_MGT_ENTITY.InsertEntity(ltEstimatePos);
    FWK_I_MGT_ENTITY.Release(ltEstimatePos);
    /* Mise à jour de la nouvelle position avec la nouvelle quantité pour relancer le recalcule. */
    FWK_I_MGT_ENTITY.new(iv_entity_name        => FWK_TYP_DOC_ENTITY.gcEvDocEstimatePos, iot_crud_definition => ltEstimatePos
                       , iv_primary_col        => 'DOC_ESTIMATE_POS_ID');
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltEstimatePos, 'DOC_ESTIMATE_POS_ID', lnNewEstimatePosID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltEstimatePos, 'DEC_QUANTITY', inNewQuantity);
    FWK_I_MGT_ENTITY.UpdateEntity(ltEstimatePos);
    FWK_I_MGT_ENTITY.Release(ltEstimatePos);
    onNewEstimatePosID  := lnNewEstimatePosID;

    -- Copie des éléments de coût type tâche
    for ltplEstimateTask in (select   DTK.DOC_ESTIMATE_TASK_ID
                                    , DTK.C_TASK_TYPE
                                    , nvl(DES.C_DOC_ESTIMATE_CODE, 'PRP') as C_DOC_ESTIMATE_CODE
                                 from EV_DOC_ESTIMATE_TASK DTK
                                    , EV_DOC_ESTIMATE DES
                                where DTK.DOC_ESTIMATE_POS_ID = inRefEstimatePosID
                                  and DTK.DOC_ESTIMATE_ID = DES.DOC_ESTIMATE_ID
                             order by DTK.DED_NUMBER asc) loop
      FWK_I_MGT_ENTITY.new(iv_entity_name        => FWK_TYP_DOC_ENTITY.gcEvDocEstimateTask
                         , iot_crud_definition   => ltEstimateElement
                         , iv_primary_col        => 'DOC_ESTIMATE_TASK_ID'
                          );
      FWK_I_MGT_ENTITY.prepareDuplicate(ltEstimateElement, true, ltplEstimateTask.DOC_ESTIMATE_TASK_ID);
      -- id principal des éléments de coût
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltEstimateElement, 'DOC_ESTIMATE_ELEMENT_COST_ID');
      -- id position de devis
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltEstimateElement, 'DOC_ESTIMATE_POS_ID', lnNewEstimatePosID);
      FWK_I_MGT_ENTITY.InsertEntity(ltEstimateElement);
      lnNewEstimateElementId  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltEstimateElement, 'DOC_ESTIMATE_TASK_ID');
      FWK_I_MGT_ENTITY.Release(ltEstimateElement);

      -- Il faut rechercher à nouveau le prix de revient unitaire des opérations si gestion production (MRP) et changement de quantité.
      if (ltplEstimateTask.C_DOC_ESTIMATE_CODE = 'MRP') and (lnOldQuantity <> lnNewEstimateElementId) then
        DOC_PRC_ESTIMATE_ELEM_COST.RecalcTask(lnNewEstimateElementId);
      end if;
    end loop;

    -- Copie des éléments de coût type composant
    for ltplEstimateComp in (select   DOC_ESTIMATE_COMP_ID
                                 from EV_DOC_ESTIMATE_COMP
                                where DOC_ESTIMATE_POS_ID = inRefEstimatePosID
                             order by DED_NUMBER) loop
      lnNewEstimateElementId  := getNewId;
      FWK_I_MGT_ENTITY.new(iv_entity_name        => FWK_TYP_DOC_ENTITY.gcEvDocEstimateComp
                         , iot_crud_definition   => ltEstimateElement
                         , iv_primary_col        => 'DOC_ESTIMATE_COMP_ID'
                          );
      FWK_I_MGT_ENTITY.prepareDuplicate(ltEstimateElement, true, ltplEstimateComp.DOC_ESTIMATE_COMP_ID);
      -- id principal des éléments de coût
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltEstimateElement, 'DOC_ESTIMATE_ELEMENT_COST_ID');
      -- id position devis
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltEstimateElement, 'DOC_ESTIMATE_POS_ID', lnNewEstimatePosID);
      -- Réinitialise les champs de création A_DATECRE et A_IDMOD
      FWK_I_MGT_ENTITY_DATA.SetColumnsCreation(ltEstimateElement, true);
      -- Supprime les valeurs des champs de modification A_DATEMOD et A_IDMOD
      FWK_I_MGT_ENTITY_DATA.SetColumnsModification(ltEstimateElement, false);
      FWK_I_MGT_ENTITY.InsertEntity(ltEstimateElement);
      FWK_I_MGT_ENTITY.Release(ltEstimateElement);
    end loop;
  end DuplicateEstimatePos;

  /**
  * procedure AddComponent
  * Description
  *   Ajout d'un composant à une position de devis
  */
  procedure AddComponent(
    iEstimatePosID  in     DOC_ESTIMATE_POS.DOC_ESTIMATE_POS_ID%type
  , iGoodID         in     DOC_ESTIMATE_COMP.GCO_GOOD_ID%type
  , iQuantity       in     DOC_ESTIMATE_ELEMENT_COST.DEC_QUANTITY%type
  , oEstimateCompID out    DOC_ESTIMATE_COMP.DOC_ESTIMATE_COMP_ID%type
  )
  is
    ltComp            FWK_I_TYP_DEFINITION.t_crud_def;
    lnDOC_ESTIMATE_ID DOC_ESTIMATE.DOC_ESTIMATE_ID%type;
  begin
    -- Rechercher l'id du devis
    select DOC_ESTIMATE_ID
      into lnDOC_ESTIMATE_ID
      from DOC_ESTIMATE_POS
     where DOC_ESTIMATE_POS_ID = iEstimatePosID;

    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcEvDocEstimateComp, ltComp);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'DOC_ESTIMATE_ID', lnDOC_ESTIMATE_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'DOC_ESTIMATE_POS_ID', iEstimatePosID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'C_DOC_ESTIMATE_ELEMENT_TYPE', '01');
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'GCO_GOOD_ID', iGoodID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'DEC_QUANTITY', iQuantity);
    FWK_I_MGT_ENTITY.InsertEntity(ltComp);
    oEstimateCompID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltComp, 'DOC_ESTIMATE_COMP_ID');
    FWK_I_MGT_ENTITY.Release(ltComp);
  end AddComponent;

  /**
  * procedure AddTask
  * Description
  *   Ajout d'une opération à une position de devis
  */
  procedure AddTask(
    iEstimatePosID  in     DOC_ESTIMATE_POS.DOC_ESTIMATE_POS_ID%type
  , iFalTaskID      in     DOC_ESTIMATE_TASK.FAL_TASK_ID%type
  , iListStepLinkID in     DOC_ESTIMATE_TASK.FAL_LIST_STEP_LINK_ID%type
  , oEstimateTaskID out    DOC_ESTIMATE_TASK.DOC_ESTIMATE_TASK_ID%type
  )
  is
    ltTask            FWK_I_TYP_DEFINITION.t_crud_def;
    lnDOC_ESTIMATE_ID DOC_ESTIMATE.DOC_ESTIMATE_ID%type;
  begin
    -- Rechercher l'id du devis
    select DOC_ESTIMATE_ID
      into lnDOC_ESTIMATE_ID
      from DOC_ESTIMATE_POS
     where DOC_ESTIMATE_POS_ID = iEstimatePosID;

    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcEvDocEstimateTask, ltTask);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'DOC_ESTIMATE_ID', lnDOC_ESTIMATE_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'DOC_ESTIMATE_POS_ID', iEstimatePosID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'C_DOC_ESTIMATE_ELEMENT_TYPE', '02');
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'FAL_TASK_ID', iFalTaskID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'FAL_LIST_STEP_LINK_ID', iListStepLinkID);
    FWK_I_MGT_ENTITY.InsertEntity(ltTask);
    oEstimateTaskID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltTask, 'DOC_ESTIMATE_TASK_ID');
    FWK_I_MGT_ENTITY.Release(ltTask);
  end AddTask;

  /**
  * Description
  *   Mise à jour du flag de recalcul des coûts pour le devis. Au moins un des deux IDs
  *   doit être renseigné.
  */
  procedure UpdatePositionFlag(
    inEstimateElementID in DOC_ESTIMATE_ELEMENT_COST.DOC_ESTIMATE_POS_ID%type default null
  , inEstimatePosID     in DOC_ESTIMATE_ELEMENT_COST.DOC_ESTIMATE_POS_ID%type default null
  , inValue             in DOC_ESTIMATE.DES_RECALC_AMOUNTS%type default 1
  )
  as
    ltCRUD_DEF      FWK_I_TYP_DEFINITION.t_crud_def;
    lnEstimatePosID DOC_ESTIMATE_POS.DOC_ESTIMATE_POS_ID%type;
  begin
    /* Si nulle, récupération de l'ID de la position récapitulative */
    if inEstimatePosID is null then
      select DOC_ESTIMATE_POS_ID
        into lnEstimatePosID
        from DOC_ESTIMATE_ELEMENT
       where DOC_ESTIMATE_ELEMENT_ID = inEstimateElementID;
    else
      lnEstimatePosID  := inEstimatePosID;
    end if;

    -- Récupération de l'entité de la position concernée
    FWK_I_MGT_ENTITY.new(iv_entity_name        => FWK_I_TYP_DOC_ENTITY.gcDocEstimatePos
                       , iot_crud_definition   => ltCRUD_DEF
                       , ib_initialize         => true
                       , in_main_id            => lnEstimatePosID
                       , in_schema_call        => fwk_i_typ_definition.SCHEMA_CURRENT
                        );
    -- Mise à jour du flag
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'DEP_RECALC_AMOUNTS', inValue);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end UpdatePositionFlag;

  /**
  * procedure pAddFieldList
  * Description
  *   Ajoute le champ à la liste
  */
  procedure pAddFieldList(ioFieldList in out varchar2, iField in varchar2, iErrorType in varchar2 default 'MANDATORY')
  is
  begin
    ioFieldList  := ioFieldList || iField || ';[' || iErrorType || '_COLOR]/';
  end pAddFieldList;

  /**
  * procedure pAddMessagedList
  * Description
  *   Ajoute le champ à la liste
  */
  procedure pAddMessageList(ioMessageList in out clob, iField in varchar2, iMessage in varchar2)
  is
  begin
    ioMessageList  := ioMessageList || '"' || PCS.PC_FUNCTIONS.GetColumnInformation(iField, 1) || '" - ' || iMessage || chr(10);
  end pAddMessageList;

  /**
  * procedure CtrlPos
  * Description
  *   Contrôle la saisie des positions du devis
  */
  procedure CtrlPos(iEstimatePosID in DOC_ESTIMATE_POS.DOC_ESTIMATE_POS_ID%type)
  is
    lvFieldList        varchar2(4000);
    lMessageList       clob;
    lnCount            integer;
    lvCDocEstimateCode DOC_ESTIMATE.C_DOC_ESTIMATE_CODE%type;
  begin
    DBMS_LOB.createtemporary(lob_loc => lMessageList, cache => true);

    for ltplPos in (select DOC_ESTIMATE_ID
                         , DOC_ESTIMATE_POS_ID
                         , GCO_GOOD_ID
                         , GCO_GOOD_CATEGORY_ID
                         , C_MANAGEMENT_MODE
                         , C_DOC_ESTIMATE_CREATE_MODE
                         , DIC_UNIT_OF_MEASURE_ID
                         , DEP_REFERENCE
                         , DEP_SECONDARY_REFERENCE
                         , DEP_SHORT_DESCRIPTION
                         , DEP_LONG_DESCRIPTION
                         , STM_STOCK_ID
                         , STM_LOCATION_ID
                         , C_SUPPLY_MODE
                         , C_SUPPLY_TYPE
                         , C_SCHEDULE_PLANNING
                         , DEC_QUANTITY
                         , DEC_REF_QTY
                         , PPS_NOMENCLATURE_ID
                      from EV_DOC_ESTIMATE_POS
                     where DOC_ESTIMATE_POS_ID = iEstimatePosID) loop
      lvFieldList  := null;

      --Traitement des erreurs
      if     (ltplPos.GCO_GOOD_CATEGORY_ID is null)
         and (ltplPos.C_DOC_ESTIMATE_CREATE_MODE in('01', '02') ) then
        pAddFieldList(lvFieldList, 'GCO_GOOD_CATEGORY_ID');
      end if;

      -- Le bien est obligatoire en copie
      if     (ltplPos.GCO_GOOD_ID is null)
         and (ltplPos.C_DOC_ESTIMATE_CREATE_MODE = '02') then
        pAddFieldList(lvFieldList, 'GCO_GOOD_ID');
      end if;

      if     (ltplPos.DEP_REFERENCE is null)
         and (ltplPos.C_DOC_ESTIMATE_CREATE_MODE in('01', '02') ) then
        pAddFieldList(lvFieldList, 'DEP_REFERENCE');
      end if;

      if ltplPos.DEC_QUANTITY is null then
        pAddFieldList(lvFieldList, 'DEC_QUANTITY');
      end if;

      -- La quantité de référence doit être supérieure à 0 et non nulle
      if nvl(ltplPos.DEC_REF_QTY, 0) <= 0 then
        pAddFieldList(lvFieldList, 'DEC_REF_QTY', 'ERROR');
        pAddMessageList(lMessageList, 'DEC_REF_QTY', PCS.PC_FUNCTIONS.TranslateWord('La quantité de référence doit être supérieure à 0 !') );
      end if;

      -- La description courte ou longue est obligatoire !
      if     ltplPos.DEP_SHORT_DESCRIPTION is null
         and ltplPos.DEP_LONG_DESCRIPTION is null then
        pAddFieldList(lvFieldList, 'DEP_SHORT_DESCRIPTION');
        pAddFieldList(lvFieldList, 'DEP_LONG_DESCRIPTION');
        pAddMessageList(lMessageList, 'DEP_SHORT_DESCRIPTION', PCS.PC_FUNCTIONS.TranslateWord('La description courte ou longue est obligatoire !') );
        pAddMessageList(lMessageList, 'DEP_LONG_DESCRIPTION', PCS.PC_FUNCTIONS.TranslateWord('La description courte ou longue est obligatoire !') );
      end if;

      -- La nomenclature est obligatoire :
      --   si Bien défini ET
      --      Pas de création de bien ET
      --      Bien possède au moins une nomenclature
      if     (ltplPos.PPS_NOMENCLATURE_ID is null)
         and (ltplPos.GCO_GOOD_ID is not null)
         and (ltplPos.C_DOC_ESTIMATE_CREATE_MODE = '00') then
        -- Vérifier si le bien possède au moins une nomenclature
        select count(*)
          into lnCount
          from PPS_NOMENCLATURE
         where GCO_GOOD_ID = ltplPos.GCO_GOOD_ID
           and C_TYPE_NOM in('1', '2', '5');

        if lnCount > 0 then
          pAddFieldList(lvFieldList, 'PPS_NOMENCLATURE_ID');
        end if;
      end if;

      -- Le type Code de Planification est obligatoire si la position
      -- possède des opérations et que l'on va créer ou copier le bien
      if     (ltplPos.C_SCHEDULE_PLANNING is null)
         and (ltplPos.C_DOC_ESTIMATE_CREATE_MODE in('01', '02') ) then
        select count(*)
          into lnCount
          from EV_DOC_ESTIMATE_TASK
         where DOC_ESTIMATE_POS_ID = ltplPos.DOC_ESTIMATE_POS_ID;

        if lnCount > 0 then
          pAddFieldList(lvFieldList, 'C_SCHEDULE_PLANNING');
        end if;
      end if;

      if ltplPos.C_DOC_ESTIMATE_CREATE_MODE = '01' then
        if ltplPos.C_MANAGEMENT_MODE is null then
          pAddFieldList(lvFieldList, 'C_MANAGEMENT_MODE');
        end if;

        if ltplPos.DIC_UNIT_OF_MEASURE_ID is null then
          pAddFieldList(lvFieldList, 'DIC_UNIT_OF_MEASURE_ID');
        end if;

        if ltplPos.STM_STOCK_ID is null then
          pAddFieldList(lvFieldList, 'STM_STOCK_ID');
        end if;

        if ltplPos.STM_LOCATION_ID is null then
          pAddFieldList(lvFieldList, 'STM_LOCATION_ID');
        end if;

        if ltplPos.C_SUPPLY_MODE is null then
          pAddFieldList(lvFieldList, 'C_SUPPLY_MODE');
        end if;

        if ltplPos.C_SUPPLY_TYPE is null then
          pAddFieldList(lvFieldList, 'C_SUPPLY_TYPE');
        end if;
      end if;

      /* Pour les composés de produits de type b (création), seul le mode fabriqué (2) est autorisé */
      if     ltplPos.C_DOC_ESTIMATE_CREATE_MODE in('01', '02')
         and ltplPos.C_SUPPLY_MODE <> '2' then
        pAddFieldList(lvFieldList, 'C_SUPPLY_MODE', 'ERROR');
        pAddMessageList(lMessageList
                      , 'C_SUPPLY_MODE'
                      , PCS.PC_FUNCTIONS.TranslateWord('Pour le produit de la position, seul le mode fabriqué(2) est autorisé !')
                       );
      end if;

      /* Pour les composés de produits de type b (création) : */
      if ltplPos.C_DOC_ESTIMATE_CREATE_MODE in('01', '02') then
        /* Récupération du mode de fonctionnement */
        select nvl(upper(C_DOC_ESTIMATE_CODE), 'PRP')
          into lvCDocEstimateCode
          from EV_DOC_ESTIMATE
         where DOC_ESTIMATE_ID = ltplPos.DOC_ESTIMATE_ID;

        if lvCDocEstimateCode = 'MRP' then   -- OF
          if ltplPos.C_SUPPLY_TYPE <> '1' then   -- stock
            pAddFieldList(lvFieldList, 'C_SUPPLY_TYPE', 'ERROR');
            pAddMessageList(lMessageList, 'C_SUPPLY_TYPE', PCS.PC_FUNCTIONS.TranslateWord('La valeur autorisée pour ce champ est "Stock" (1) !') );
          end if;
        elsif lvCDocEstimateCode = 'PRP' then   -- Affaire
          if ltplPos.C_SUPPLY_TYPE <> '2' then   -- affaire
            pAddFieldList(lvFieldList, 'C_SUPPLY_TYPE', 'ERROR');
            pAddMessageList(lMessageList, 'C_SUPPLY_TYPE', PCS.PC_FUNCTIONS.TranslateWord('La valeur autorisée pour ce champ est "Affaire" (2) !') );
          end if;
        end if;
      end if;

      -- Vérifier l'unicité de la référence du produit à créer
      if (ltplPos.C_DOC_ESTIMATE_CREATE_MODE in('01', '02') ) then
        declare
          lnGoodID GCO_GOOD.GCO_GOOD_ID%type;
        begin
          select max(GCO_GOOD_ID)
            into lnGoodID
            from GCO_GOOD
           where GOO_MAJOR_REFERENCE = ltplPos.DEP_REFERENCE;

          if lnGoodID is not null then
            pAddFieldList(lvFieldList, 'DEP_REFERENCE', 'WARNING');
            pAddMessageList(lMessageList
                          , 'DEP_REFERENCE'
                          , ltplPos.DEP_REFERENCE ||
                            ' - ' ||
                            PCS.PC_FUNCTIONS.TranslateWord('Le produit ne sera pas créé.') ||
                            ' ' ||
                            PCS.PC_FUNCTIONS.TranslateWord('Il existe déjà un produit avec cette référence !')
                           );
          end if;
        end;
      end if;

      --Insertion dans la table temporaire
      if lvFieldList is not null then
        InsertCtrlLog(ltplPos.DOC_ESTIMATE_POS_ID, 'DOC_ESTIMATE_POS', lvFieldList, lMessageList);
      end if;

      --Contrôle des composants de la position
      CtrlComp(ltplPos.DOC_ESTIMATE_POS_ID);
      --Contrôle des opérations de la position
      CtrlTask(ltplPos.DOC_ESTIMATE_POS_ID);
    end loop;

    DBMS_LOB.FreeTemporary(lMessageList);
  end CtrlPos;

  /**
  * procedure CtrlComp
  * Description
  *   Contrôle la saisie des composants
  */
  procedure CtrlComp(iEstimatePosID in DOC_ESTIMATE_POS.DOC_ESTIMATE_POS_ID%type)
  is
    lvFieldList  varchar2(4000);
    lMessageList clob;
  begin
    DBMS_LOB.createtemporary(lob_loc => lMessageList, cache => true);

    --Parcours des composants de la position
    for ltplComp in (select   DOC_ESTIMATE_COMP_ID
                            , GCO_GOOD_ID
                            , GCO_GOOD_CATEGORY_ID
                            , C_MANAGEMENT_MODE
                            , C_DOC_ESTIMATE_CREATE_MODE
                            , DIC_UNIT_OF_MEASURE_ID
                            , ECP_REFERENCE
                            , ECP_SECONDARY_REFERENCE
                            , ECP_SHORT_DESCRIPTION
                            , STM_STOCK_ID
                            , STM_LOCATION_ID
                            , C_SUPPLY_MODE
                            , C_SUPPLY_TYPE
                            , DEC_QUANTITY
                         from EV_DOC_ESTIMATE_COMP
                        where DOC_ESTIMATE_POS_ID = iEstimatePosID
                     order by DED_NUMBER) loop
      lvFieldList  := null;

      --Traitement des erreurs
      if     (ltplComp.GCO_GOOD_CATEGORY_ID is null)
         and (ltplComp.C_DOC_ESTIMATE_CREATE_MODE in('01', '02') ) then
        pAddFieldList(lvFieldList, 'GCO_GOOD_CATEGORY_ID');
      end if;

      -- Le bien est obligatoire en copie
      if     (ltplComp.GCO_GOOD_ID is null)
         and (ltplComp.C_DOC_ESTIMATE_CREATE_MODE = '02') then
        pAddFieldList(lvFieldList, 'GCO_GOOD_ID');
      end if;

      if ltplComp.ECP_REFERENCE is null then
        pAddFieldList(lvFieldList, 'ECP_REFERENCE');
      end if;

      if ltplComp.DEC_QUANTITY is null then
        pAddFieldList(lvFieldList, 'DEC_QUANTITY');
      end if;

      if ltplComp.C_DOC_ESTIMATE_CREATE_MODE = '01' then
        if ltplComp.C_MANAGEMENT_MODE is null then
          pAddFieldList(lvFieldList, 'C_MANAGEMENT_MODE');
        end if;

        if ltplComp.DIC_UNIT_OF_MEASURE_ID is null then
          pAddFieldList(lvFieldList, 'DIC_UNIT_OF_MEASURE_ID');
        end if;

        if ltplComp.ECP_SHORT_DESCRIPTION is null then
          pAddFieldList(lvFieldList, 'ECP_SHORT_DESCRIPTION');
        end if;

        if ltplComp.STM_STOCK_ID is null then
          pAddFieldList(lvFieldList, 'STM_STOCK_ID');
        end if;

        if ltplComp.STM_LOCATION_ID is null then
          pAddFieldList(lvFieldList, 'STM_LOCATION_ID');
        end if;

        if ltplComp.C_SUPPLY_MODE is null then
          pAddFieldList(lvFieldList, 'C_SUPPLY_MODE');
        end if;

        if ltplComp.C_SUPPLY_TYPE is null then
          pAddFieldList(lvFieldList, 'C_SUPPLY_TYPE');
        end if;
      end if;

      /* Pour les composants de produits de type b (création), seul le mode acheté est autorisé */
      if     ltplComp.C_DOC_ESTIMATE_CREATE_MODE in('01', '02')
         and ltplComp.C_SUPPLY_MODE <> '1' then
        pAddFieldList(lvFieldList, 'C_SUPPLY_MODE', 'ERROR');
        pAddMessageList(lMessageList, 'C_SUPPLY_MODE', PCS.PC_FUNCTIONS.TranslateWord('Pour ce composant, seul le mode acheté(1) est autorisé !') );
      end if;

      -- Vérifier l'unicité de la référence du produit à créer
      if (ltplComp.C_DOC_ESTIMATE_CREATE_MODE in('01', '02') ) then
        declare
          lnGoodID GCO_GOOD.GCO_GOOD_ID%type;
        begin
          select max(GCO_GOOD_ID)
            into lnGoodID
            from GCO_GOOD
           where GOO_MAJOR_REFERENCE = ltplComp.ECP_REFERENCE;

          if lnGoodID is not null then
            pAddFieldList(lvFieldList, 'ECP_REFERENCE', 'WARNING');
            pAddMessageList(lMessageList
                          , 'ECP_REFERENCE'
                          , ltplComp.ECP_REFERENCE ||
                            ' - ' ||
                            PCS.PC_FUNCTIONS.TranslateWord('Le produit ne sera pas créé.') ||
                            ' ' ||
                            PCS.PC_FUNCTIONS.TranslateWord('Il existe déjà un produit avec cette référence !')
                           );
          end if;
        end;
      end if;

      --Insertion dans la table temporaire
      if lvFieldList is not null then
        InsertCtrlLog(ltplComp.DOC_ESTIMATE_COMP_ID, 'DOC_ESTIMATE_COMP', lvFieldList, lMessageList);
      end if;
    end loop;

    DBMS_LOB.FreeTemporary(lMessageList);
  end CtrlComp;

  /**
  * procedure CtrlTask
  * Description
  *   Contrôle la saisie des opérations
  */
  procedure CtrlTask(iEstimatePosID in DOC_ESTIMATE_POS.DOC_ESTIMATE_POS_ID%type)
  is
    lvFieldList  varchar2(4000);
    lMessageList clob;
  begin
    --Parcours des opérations du devis
    for ltplTask in (select   DOC_ESTIMATE_TASK_ID
                            , FAL_TASK_ID
                            , C_TASK_TYPE
                            , DTK_REFERENCE
                            , DEC_QUANTITY
                            , C_DOC_ESTIMATE_CREATE_MODE
                            , DTK_DIVISOR_AMOUNT
                            , DTK_QTY_REF_AMOUNT
                         from EV_DOC_ESTIMATE_TASK
                        where DOC_ESTIMATE_POS_ID = iEstimatePosID
                     order by DED_NUMBER) loop
      lvFieldList  := null;
      DBMS_LOB.createtemporary(lob_loc => lMessageList, cache => true);

      /* Quantité obligatoire */
      if ltplTask.DEC_QUANTITY is null then
        pAddFieldList(lvFieldList, 'DEC_QUANTITY');
      end if;

      /* Tâche obligatoire */
      if ltplTask.FAL_TASK_ID is null then
        pAddFieldList(lvFieldList, 'FAL_TASK_ID');
      end if;

      /* Si la case diviseur est cochée, la Qté ref montant ne doit ni être nulle, ni être inférieur ou égale eà 0 */
      if     (ltplTask.DTK_DIVISOR_AMOUNT = 1)
         and (    (ltplTask.DTK_QTY_REF_AMOUNT is null)
              or (ltplTask.DTK_QTY_REF_AMOUNT <= 0) ) then
        pAddFieldList(lvFieldList, 'DTK_QTY_REF_AMOUNT', 'ERROR');
        pAddMessageList(lMessageList
                      , 'DTK_QTY_REF_AMOUNT'
                      , PCS.PC_FUNCTIONS.TranslateWord('Si la case "Diviseur" est sélectionnée,') ||
                        ' ' ||
                        PCS.PC_FUNCTIONS.TranslateWord('La "Qté ref. montant" doit être supérieure à 0')
                       );
      end if;

      /* Insertion dans la table temporaire */
      if lvFieldList is not null then
        InsertCtrlLog(ltplTask.DOC_ESTIMATE_TASK_ID, 'DOC_ESTIMATE_TASK', lvFieldList, lMessageList);
      end if;

      DBMS_LOB.FreeTemporary(lMessageList);
    end loop;
  exception
    when others then
      DBMS_LOB.FreeTemporary(lMessageList);
      raise;
  end CtrlTask;

  /**
  * procedure InsertCtrlLog
  * Description
  *   Insert les colonnes qui n'ont pas été saisi correctement dans une table temporaire
  */
  procedure InsertCtrlLog(
    iElementID   in COM_LIST_ID_TEMP.COM_LIST_ID_TEMP_ID%type
  , iElementType in COM_LIST_ID_TEMP.LID_CODE%type
  , iFieldList   in COM_LIST_ID_TEMP.LID_DESCRIPTION%type
  , iMessage     in COM_LIST_ID_TEMP.LID_CLOB%type
  )
  is
    lvMandatoryFields varchar2(4000) := null;
    lnMandatory       integer        := 0;
    lnError           integer        := 0;
    lnWarning         integer        := 0;
  begin
    for ltplField in (select FIELD_NAME
                        from (select substr(column_value, 0, instr(column_value, ';') - 1) FIELD_NAME
                                   , substr(column_value, instr(column_value, ';') + 1) ACTION_TYPE
                                from table(PCS.charListToTable(iFieldList, '/') ) ) LST
                       where LST.ACTION_TYPE = '[MANDATORY_COLOR]') loop
      lvMandatoryFields  := lvMandatoryFields || PCS.PC_FUNCTIONS.GetColumnInformation(ltplField.FIELD_NAME, 1) || chr(10);
      lnMandatory        := lnMandatory + 1;
    end loop;

    select count(*)
      into lnError
      from (select substr(column_value, 0, instr(column_value, ';') - 1) FIELD_NAME
                 , substr(column_value, instr(column_value, ';') + 1) ACTION_TYPE
              from table(PCS.charListToTable(iFieldList, '/') ) ) LST
     where LST.ACTION_TYPE = '[ERROR_COLOR]';

    select count(*)
      into lnWarning
      from (select substr(column_value, 0, instr(column_value, ';') - 1) FIELD_NAME
                 , substr(column_value, instr(column_value, ';') + 1) ACTION_TYPE
              from table(PCS.charListToTable(iFieldList, '/') ) ) LST
     where LST.ACTION_TYPE = '[WARNING_COLOR]';

    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
               , LID_DESCRIPTION
               , LID_FREE_MEMO_1
               , LID_FREE_NUMBER_1
               , LID_FREE_NUMBER_2
               , LID_FREE_NUMBER_3
               , LID_CLOB
                )
         values (iElementID
               , iElementType
               , iFieldList
               , lvMandatoryFields
               , lnMandatory
               , lnError
               , lnWarning
               , iMessage
                );
  end InsertCtrlLog;
end DOC_PRC_ESTIMATE_POS;
