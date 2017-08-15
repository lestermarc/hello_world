--------------------------------------------------------
--  DDL for Package Body FAL_LIB_MRP_CALCULATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_MRP_CALCULATION" 
is
  -- ID unique de la session utilisé dans toutes les procédures de (dé)réservation
  cSessionId constant FAL_CB_COMP_LEVEL.CCL_SESSION_ID%type   := DBMS_SESSION.unique_session_id;

  /**
  * procedure GetStockAndLocation
  * Description : Renvoie les stocks et emplacements d'un produit
  * @created ECA
  * @lastUpdate
  * @public
  */
  procedure GetStockAndLocation(
    iDefltSTM_STOCK_ID    in     number
  , iDefltSTM_LOCATION_ID in     number
  , iGCO_GOOD_ID          in     number
  , ioSTM_STOCK_ID        in out number
  , ioSTM_LOCATION_ID     in out number
  )
  is
    lnSTM_LOCATION_ID number;
  begin
    -- Stock
    if nvl(iDefltSTM_STOCK_ID, 0) = 0 then
      GCO_LIB_FUNCTIONS.GetGoodStockLocation(iGCO_GOOD_ID, ioSTM_STOCK_ID, lnSTM_LOCATION_ID);
    else
      ioSTM_STOCK_ID  := iDefltSTM_STOCK_ID;
    end if;

    -- Emplacement
    if nvl(iDefltSTM_LOCATION_ID, 0) = 0 then
      if nvl(iDefltSTM_STOCK_ID, 0) <> 0 then
        ioSTM_LOCATION_ID  := FAL_TOOLS.GetMinusLocClaOnStock(iDefltSTM_STOCK_ID);
      else
        ioSTM_LOCATION_ID  := lnSTM_LOCATION_ID;
      end if;
    else
      ioSTM_LOCATION_ID  := iDefltSTM_LOCATION_ID;
    end if;
  end GetStockAndLocation;

  /**
  * procedure GetNomSchedulePlan
  * Description : Renvoie la gamme liée à la nomenclature
  * @created ECA
  * @lastUpdate
  * @private
  */
  function GetNomSchedulePlan(iPpsNomenclatureId in number)
    return number
  is
    lnFAL_SCHEDULE_PLAN_ID number;
  begin
    select FAL_SCHEDULE_PLAN_ID
      into lnFAL_SCHEDULE_PLAN_ID
      from PPS_NOMENCLATURE
     where PPS_NOMENCLATURE_ID = iPpsNomenclatureId;

    return lnFAL_SCHEDULE_PLAN_ID;
  exception
    when others then
      return null;
  end GetNomSchedulePlan;

  /**
  * procedure GetProductParameters
  * Description : Recherche des paramètres CB d'un produit
  * @created ECA
  * @lastUpdate
  * @public
  * @param iGcoGoodId : Bien
  * @param iCSupplyMode : Mode d'approvisionnement
  * @param iDicFabConditionID : Condition de fabrication
  * @param iPacSupplierPartnerID : Fournisseur
  * @param ioFounded : Donnée complémentaire déterminée
  * @param ioCSupplyMode : Mode d'approvisionnement (out)
  * @param ioDicFabConditionId : Condition de fabrication (out)
  * @param ioEconomicalQuantity : Quantité économique
  * @param ioModuloQuantity : Quantité modulo
  * @param ioCEconomicCode : Coce qté économique
  * @param ioCmaFixedDelay : durée délai fixe
  * @param ioCmaShift : Décalage
  * @param ioPacSupplierPartnerId : fournisseur
  * @param ioFalSchedulePlanId : gamme
  * @param ioCSchedulePlanCode : Code planification
  * @param ioPPSNomenclatureID : nomenclature
  * @param ioDicMeasureUnitCode : Unité de mesure
  * @param ioNumberOfDecimal : Nbre de décimales
  * @param ioConversionFactor : Facteur de conversion
  * @param ioStandardLotQty : Qté lot standard
  * @param ioSupplyDelay : Délai d'approvisionnement
  * @param ioControlDelay : Délai de contrôle
  * @param ioTrashPercent : %age de rebut
  * @param ioTrashFixedQty : Qté fixe de rebut
  * @param ioLossReferenceQty : Qté de référence perte
  * @param ioFixedDuration : mode durée fixe
  * @param ioSecurityDelay : Délai de sécurité
  * @param ioCQtySupplyRule : Règle quantitative d'appro
  * @param ioCTimeSupplyRule : Règle temporelle d'appro
  * @param ioSchedPlanIDFromNom : Gamme liée à la nomenclature
  * @param ioDestSTM_STOCK_ID : Stcok destination
  * @param ioDestSTM_LOCATION_ID : Emplacement destination
  * @param ioCoupledCoefficient : Coef produit couplé
  * @param ioDonneeComplementaire : ID Donnée complémentaire fabrication, achat, sous-traitance...
  * @param iDateRef : Date référence
  */
  procedure GetProductParameters(
    iGcoGoodId             in     number
  , iCSupplyMode           in     varchar2
  , iDicFabConditionID     in     varchar2
  , iPacSupplierPartnerID  in     number
  , ioFounded              in out integer
  , ioCSupplyMode          in out varchar2
  , ioDicFabConditionId    in out varchar2
  , ioEconomicalQuantity   in out number
  , ioModuloQuantity       in out number
  , ioCEconomicCode        in out varchar2
  , ioCmaFixedDelay        in out integer
  , ioCmaShift             in out integer
  , ioPacSupplierPartnerId in out number
  , ioFalSchedulePlanId    in out number
  , ioCSchedulePlanCode    in out varchar2
  , ioPPSNomenclatureID    in out number
  , ioDicMeasureUnitCode   in out varchar2
  , ioNumberOfDecimal      in out integer
  , ioConversionFactor     in out number
  , ioStandardLotQty       in out number
  , ioSupplyDelay          in out integer
  , ioControlDelay         in out integer
  , ioTrashPercent         in out number
  , ioTrashFixedQty        in out number
  , ioLossReferenceQty     in out number
  , ioFixedDuration        in out integer
  , ioSecurityDelay        in out integer
  , ioCQtySupplyRule       in out varchar2
  , ioCTimeSupplyRule      in out varchar2
  , ioSchedPlanIDFromNom   in out number
  , ioDestSTM_STOCK_ID     in out number
  , ioDestSTM_LOCATION_ID  in out number
  , ioCoupledCoefficient   in out number
  , ioDonneeComplementaire in out number
  , iDateRef               in     date default null
  )
  is
    -- Sélection des données complémentaires de fabrication
    cursor crComplDataManufacture
    is
      select CMA.*
           , FSP.C_SCHEDULE_PLANNING
        from GCO_COMPL_DATA_MANUFACTURE CMA
           , FAL_SCHEDULE_PLAN FSP
       where GCO_GOOD_ID = iGcoGoodId
         and CMA.FAL_SCHEDULE_PLAN_ID = FSP.FAL_SCHEDULE_PLAN_ID(+)
         and (    (    iDicFabConditionID is null
                   and CMA_DEFAULT = 1)
              or (    iDicFabConditionID is not null
                  and nvl(DIC_FAB_CONDITION_ID, iDicFabConditionID) = iDicFabConditionID)
             );

    -- Sélection des données complémentaires d'achat
    cursor CrComplDataPurchase(aMultisourcing integer, aGcoComplDataId number)
    is
      select   (case
                  when CPU_DEFAULT_SUPPLIER = 1 then 0
                  when PAC_SUPPLIER_PARTNER_ID = FAL_TOOLS.GetDefaultSupplier then 1
                  when PAC_SUPPLIER_PARTNER_ID is null then 2
                  else 3
                end
               ) ORDER_FIELD
             , C_QTY_SUPPLY_RULE
             , CPU_ECONOMICAL_QUANTITY
             , C_ECONOMIC_CODE
             , C_TIME_SUPPLY_RULE
             , CPU_MODULO_QUANTITY
             , CPU_FIXED_DELAY
             , CPU_SHIFT
             , nvl(PAC_SUPPLIER_PARTNER_ID, FAL_TOOLS.GetDefaultSupplier) PAC_SUPPLIER_PARTNER_ID
             , DIC_UNIT_OF_MEASURE_ID
             , CDA_NUMBER_OF_DECIMAL
             , CDA_CONVERSION_FACTOR
             , nvl(CPU_SUPPLY_DELAY, FAL_TOOLS.GetProcurementDelay(nvl(PAC_SUPPLIER_PARTNER_ID, FAL_TOOLS.GetDefaultSupplier) ) ) CPU_SUPPLY_DELAY
             , CPU_CONTROL_DELAY
             , CPU_PERCENT_TRASH
             , CPU_FIXED_QUANTITY_TRASH
             , CPU_QTY_REFERENCE_TRASH
             , STM_STOCK_ID
             , STM_LOCATION_ID
             , CPU_SECURITY_DELAY
             , GCO_COMPL_DATA_PURCHASE_ID
          from GCO_COMPL_DATA_PURCHASE
         where GCO_GOOD_ID = iGcoGoodId
           and (    (    nvl(iPacSupplierPartnerId, 0) <> 0
                     and PAC_SUPPLIER_PARTNER_ID = iPacSupplierPartnerId)
                or (    nvl(iPacSupplierPartnerId, 0) = 0
                    and (    (    aMultisourcing = 0
                              and (   CPU_DEFAULT_SUPPLIER = 1
                                   or PAC_SUPPLIER_PARTNER_ID = FAL_TOOLS.GetDefaultSupplier
                                   or PAC_SUPPLIER_PARTNER_ID is null)
                             )
                         or (    aMultisourcing = 1
                             and (    (    nvl(aGcoComplDataId, 0) = 0
                                       and CPU_DEFAULT_SUPPLIER = 1)
                                  or (    nvl(aGcoComplDataId, 0) <> 0
                                      and GCO_COMPL_DATA_PURCHASE_ID = aGcoComplDataId)
                                 )
                            )
                        )
                   )
               )
      order by ORDER_FIELD;

    -- Sélection des données complémentaires de sous-traitance
    cursor crComplDataSubcontract(iDateReference date)
    is
      select   *
          from GCO_COMPL_DATA_SUBCONTRACT
         where GCO_GOOD_ID = iGcoGoodId
           and (   nvl(iPacSupplierPartnerId, 0) = 0
                or (    nvl(iPacSupplierPartnerId, 0) <> 0
                    and PAC_SUPPLIER_PARTNER_ID = iPacSupplierPartnerId) )
           and (   iDicFabConditionId is null
                or DIC_FAB_CONDITION_ID = iDicFabConditionId)
           and nvl(CSU_VALIDITY_DATE, trunc(iDateReference) ) <= trunc(iDateReference)
      order by CSU_DEFAULT_SUBCONTRACTER desc
             , CSU_VALIDITY_DATE desc
             , PAC_SUPPLIER_PARTNER_ID nulls last;

    liMultisourcingPdt        integer;
    lnGcoCompldataPurchaseId  number;
    lnGCO_GCO_GOOD_ID         number;
    lnPAC_SUPPLIER_PARTNER_ID number;
    ldDateReference           date;
  begin
    iofounded  := 0;

    -- Produit fabriqué
    if iCSupplyMode = csmManufacturedPdt then
      for tplCompldataManufacture in crComplDataManufacture loop
        -- La donnée complémentaire a pu être déterminée
        iofounded               := 1;
        ioCSupplyMode           := iCSupplyMode;
        ioDicFabConditionId     := tplCompldataManufacture.DIC_FAB_CONDITION_ID;
        ioEconomicalQuantity    := tplCompldataManufacture.CMA_ECONOMICAL_QUANTITY;
        ioModuloQuantity        := tplCompldataManufacture.CMA_MODULO_QUANTITY;
        ioCEconomicCode         := nvl(tplCompldataManufacture.C_ECONOMIC_CODE, '1');
        ioCmaFixedDelay         := tplCompldataManufacture.CMA_FIXED_DELAY;
        ioCmaShift              := tplCompldataManufacture.CMA_SHIFT;
        ioPacSupplierPartnerId  := 0;
        ioFalSchedulePlanId     := tplCompldataManufacture.FAL_SCHEDULE_PLAN_ID;
        ioCSchedulePlanCode     := nvl(tplCompldataManufacture.C_SCHEDULE_PLANNING, '1');
        ioPPSNomenclatureID     := tplCompldataManufacture.PPS_NOMENCLATURE_ID;
        ioDicMeasureUnitCode    := tplCompldataManufacture.DIC_UNIT_OF_MEASURE_ID;
        ioNumberOfDecimal       := tplCompldataManufacture.CDA_NUMBER_OF_DECIMAL;
        ioConversionFactor      := 1;
        ioStandardLotQty        := tplCompldataManufacture.CMA_LOT_QUANTITY;
        ioSupplyDelay           := tplCompldataManufacture.CMA_MANUFACTURING_DELAY;
        ioControlDelay          := 0;
        ioTrashPercent          := tplCompldataManufacture.CMA_PERCENT_TRASH;
        ioTrashFixedQty         := tplCompldataManufacture.CMA_FIXED_QUANTITY_TRASH;
        ioLossReferenceQty      := tplCompldataManufacture.CMA_QTY_REFERENCE_LOSS;
        ioFixedDuration         := tplCompldataManufacture.CMA_FIX_DELAY;
        ioSecurityDelay         := tplCompldataManufacture.CMA_SECURITY_DELAY;

        if     tplCompldataManufacture.C_QTY_SUPPLY_RULE = '2'
           and nvl(tplCompldataManufacture.CMA_ECONOMICAL_QUANTITY, 0) = 0 then
          ioCQtySupplyRule  := '1';
        else
          ioCQtySupplyRule  := tplCompldataManufacture.C_QTY_SUPPLY_RULE;
        end if;

        if     tplCompldataManufacture.C_TIME_SUPPLY_RULE = '2'
           and nvl(tplCompldataManufacture.CMA_FIXED_DELAY, 0) = 0 then
          ioCTimeSupplyRule  := '1';
        else
          ioCTimeSupplyRule  := tplCompldataManufacture.C_TIME_SUPPLY_RULE;
        end if;

        if ioPPSNomenclatureID is null then
          ioSchedPlanIDFromNom  := 0;
        else
          ioSchedPlanIDFromNom  := GetNomSchedulePlan(ioPPSNomenclatureID);
        end if;

        GetStockAndLocation(tplCompldataManufacture.STM_STOCK_ID, tplCompldataManufacture.STM_LOCATION_ID, iGcoGoodId, ioDestSTM_STOCK_ID
                          , ioDestSTM_LOCATION_ID);

        if PCS.PC_CONFIG.GetConfig('FAL_COUPLED_GOOD') = '1' then
          ioCoupledCoefficient  := FAL_COUPLED_GOOD.GetSumQteByRefOfCoupledDC(tplCompldataManufacture.GCO_COMPL_DATA_MANUFACTURE_ID);
        else
          ioCoupledCoefficient  := 0;
        end if;

        ioDonneeComplementaire  := tplCompldataManufacture.GCO_COMPL_DATA_MANUFACTURE_ID;
        exit;
      end loop;

      -- Données complémentaire de fabrication non trouvée, initialisation avec les valeurs par défaut
      if ioFounded = 0 then
        ioCSupplyMode           := iCSupplyMode;
        ioDicFabConditionID     := '';
        ioCQtySupplyRule        := '1';
        ioEconomicalQuantity    := 0;
        ioModuloQuantity        := 0;
        ioCEconomicCode         := '1';
        ioCTimeSupplyRule       := '1';
        ioCmaFixedDelay         := 0;
        ioCmaShift              := 0;
        ioPacSupplierPartnerID  := 0;
        ioFalSchedulePlanID     := 0;
        ioCSchedulePlanCode     := '1';
        ioPPSNomenclatureID     := 0;
        ioDicMeasureUnitCode    := FAL_TOOLS.GetGoodMeasureUnit(iGcoGoodId);
        ioNumberOfDecimal       := FAL_TOOLS.GetGoo_Number_Of_Decimal(iGcoGoodId);
        ioConversionFactor      := 1;
        ioStandardLotQty        := 1;
        ioSupplyDelay           := 0;
        ioControlDelay          := 0;
        ioTrashPercent          := 0;
        ioTrashFixedQty         := 0;
        ioLossReferenceQty      := 0;
        ioSchedPlanIDFromNom    := 0;
        GetStockAndLocation(0, 0, iGcoGoodId, ioDestSTM_STOCK_ID, ioDestSTM_LOCATION_ID);
        ioCoupledCoefficient    := 0;
        ioFixedDuration         := 0;
        ioSecurityDelay         := 0;
        ioDonneeComplementaire  := 0;
        return;
      end if;
    -- Produit Acheté
    elsif iCSupplyMode = csmPurchasedPdt then
      -- recherches liées au Multisourcing
      if nvl(iPacSupplierPartnerId, 0) = 0 then
        liMultisourcingPdt  := FAL_MSOURCING_FUNCTIONS.IsProductWithMultiSourcing(iGcoGoodId);
      else
        liMultisourcingPdt  := 0;
      end if;

      if liMultisourcingPdt = 1 then
        FAL_MSOURCING_FUNCTIONS.GetMultiSourcingDCA(iGcoGoodId, 0, lnGCO_GCO_GOOD_ID, lnPAC_SUPPLIER_PARTNER_ID, lnGcoComplDataPurchaseId);
      else
        lnGcoCompldataPurchaseId  := 0;
      end if;

      for tplCompldataPurchase in crComplDataPurchase(liMultiSourcingPdt, lnGcoCompldataPurchaseId) loop
        ioFounded               := 1;
        ioCSupplyMode           := iCSupplyMode;
        ioDicFabConditionID     := '';
        ioCmaFixedDelay         := tplCompldataPurchase.CPU_FIXED_DELAY;
        ioCmaShift              := tplCompldataPurchase.CPU_SHIFT;
        ioPacSupplierPartnerID  := tplCompldataPurchase.PAC_SUPPLIER_PARTNER_ID;
        ioFalSchedulePlanID     := 0;
        ioCSchedulePlanCode     := '';
        ioPPSNomenclatureID     := 0;
        ioDicMeasureUnitCode    := tplCompldataPurchase.DIC_UNIT_OF_MEASURE_ID;
        ioNumberOfDecimal       := tplCompldataPurchase.CDA_NUMBER_OF_DECIMAL;
        ioConversionFactor      := tplCompldataPurchase.CDA_CONVERSION_FACTOR;
        ioStandardLotQty        := 0;
        ioSupplyDelay           := tplCompldataPurchase.CPU_SUPPLY_DELAY;
        ioControlDelay          := tplCompldataPurchase.CPU_CONTROL_DELAY;
        ioTrashPercent          := tplCompldataPurchase.CPU_PERCENT_TRASH;
        ioTrashFixedQty         := tplCompldataPurchase.CPU_FIXED_QUANTITY_TRASH;
        ioLossReferenceQty      := tplCompldataPurchase.CPU_QTY_REFERENCE_TRASH;
        ioSchedPlanIDFromNom    := 0;

        if ioSupplyDelay = 0 then
          ioSupplyDelay  := FAL_TOOLS.GetProcurementDelay(ioPacSupplierPartnerId);
        end if;

        if     tplCompldataPurchase.C_QTY_SUPPLY_RULE = '2'
           and nvl(tplCompldataPurchase.CPU_ECONOMICAL_QUANTITY, 0) = 0 then
          ioCQtySupplyRule  := '1';
        else
          ioCQtySupplyRule  := tplCompldataPurchase.C_QTY_SUPPLY_RULE;
        end if;

        ioEconomicalQuantity    := tplCompldataPurchase.CPU_ECONOMICAL_QUANTITY;
        ioModuloQuantity        := tplCompldataPurchase.CPU_MODULO_QUANTITY;
        iocEconomicCode         := tplCompldataPurchase.C_ECONOMIC_CODE;

        if     tplCompldataPurchase.C_TIME_SUPPLY_RULE = '2'
           and nvl(tplCompldataPurchase.CPU_FIXED_DELAY, 0) = 0 then
          ioCTimeSupplyRule  := '1';
        else
          ioCTimeSupplyRule  := tplCompldataPurchase.C_TIME_SUPPLY_RULE;
        end if;

        GetStockAndLocation(tplCompldataPurchase.STM_STOCK_ID, tplCompldataPurchase.STM_LOCATION_ID, iGcoGoodId, ioDestSTM_STOCK_ID, ioDestSTM_LOCATION_ID);
        ioCoupledCoefficient    := 0;
        ioFixedDuration         := 0;
        ioSecurityDelay         := tplCompldataPurchase.CPU_SECURITY_DELAY;
        ioDonneeComplementaire  := tplCompldataPurchase.GCO_COMPL_DATA_PURCHASE_ID;
        exit;
      end loop;

      -- Données complémentaire d'achat non trouvée, initialisation avec les valeurs par défaut
      if ioFounded = 0 then
        ioCSupplyMode           := iCSupplyMode;
        ioDicFabConditionID     := '';
        iocQtySupplyRule        := '1';
        ioEconomicalQuantity    := 0;
        ioModuloQuantity        := 0;
        ioCEconomicCode         := '1';
        ioCTimeSupplyRule       := '1';
        ioCmaFixedDelay         := 0;
        ioCmaShift              := 0;
        ioFalSchedulePlanID     := 0;
        ioCSchedulePlanCode     := '1';
        ioPPSNomenclatureID     := 0;
        ioDicMeasureUnitCode    := FAL_TOOLS.GetGoodMeasureUnit(iGcoGoodId);
        ioNumberOfDecimal       := FAL_TOOLS.GetGoo_Number_Of_Decimal(iGcoGoodId);
        ioConversionFactor      := 1;
        ioStandardLotQty        := 0;
        ioControlDelay          := 0;
        ioTrashPercent          := 0;
        ioTrashFixedQty         := 0;
        ioLossReferenceQty      := 0;
        ioSchedPlanIDFromNom    := 0;
        GetStockAndLocation(0, 0, iGcoGoodId, ioDestSTM_STOCK_ID, ioDestSTM_LOCATION_ID);
        ioCoupledCoefficient    := 0;
        ioDonneeComplementaire  := 0;
        ioFixedDuration         := 0;
        ioSecurityDelay         := 0;

        if iPacSupplierPartnerId <> 0 then
          ioPacSupplierPartnerId  := iPacSupplierPartnerId;
        else
          ioPacSupplierPartnerId  := FAL_TOOLS.GetDefaultSupplier;
        end if;

        ioSupplyDelay           := FAL_TOOLS.GetProcurementDelay(ioPacSupplierPartnerId);
        return;
      end if;
    -- Données complémentaires de sous-traitance
    elsif    (iCSupplyMode = csmSubcontractPurchasePdt)
          or (iCSupplyMode = csmTaskAssemblededPdt) then
      ldDateReference  := nvl(iDateRef, sysdate);

      for tplCompldataSubContract in crComplDataSubcontract(ldDateReference) loop
        ioFounded               := 1;
        ioCSupplyMode           := iCSupplyMode;
        ioDicFabConditionID     := tplCompldataSubContract.DIC_FAB_CONDITION_ID;
        ioEconomicalQuantity    := tplCompldataSubContract.CSU_ECONOMICAL_QUANTITY;
        ioModuloQuantity        := tplCompldataSubContract.CSU_MODULO_QUANTITY;
        ioCEconomicCode         := tplCompldataSubContract.C_ECONOMIC_CODE;
        ioCmaFixedDelay         := tplCompldataSubContract.CSU_FIXED_DELAY;
        ioCmaShift              := tplCompldataSubContract.CSU_SHIFT;
        ioPacSupplierPartnerID  := nvl(tplCompldataSubContract.PAC_SUPPLIER_PARTNER_ID, FAL_TOOLS.GetDefaultSubcontract);
        ioFalSchedulePlanID     := FAL_LIB_SUBCONTRACTP.GetSchedulePlanId;
        ioCSchedulePlanCode     := '2';
        ioPPSNomenclatureID     := tplCompldataSubContract.PPS_NOMENCLATURE_ID;
        ioDicMeasureUnitCode    := tplCompldataSubContract.DIC_UNIT_OF_MEASURE_ID;
        ioNumberOfDecimal       := tplCompldataSubContract.CDA_NUMBER_OF_DECIMAL;
        ioConversionFactor      := tplCompldataSubContract.CDA_CONVERSION_FACTOR;
        ioStandardLotQty        := 0;
        ioSupplyDelay           := tplCompldataSubContract.CSU_SUBCONTRACTING_DELAY;
        ioControlDelay          := tplCompldataSubContract.CSU_CONTROL_DELAY;
        ioTrashPercent          := tplCompldataSubContract.CSU_PERCENT_TRASH;
        ioTrashFixedQty         := tplCompldataSubContract.CSU_FIXED_QUANTITY_TRASH;
        ioLossReferenceQty      := tplCompldataSubContract.CSU_QTY_REFERENCE_TRASH;
        ioCoupledCoefficient    := 0;
        ioFixedDuration         := 0;
        ioSecurityDelay         := tplCompldataSubContract.CSU_SECURITY_DELAY;

        if     tplCompldataSubContract.C_QTY_SUPPLY_RULE = '2'
           and nvl(tplCompldataSubContract.CSU_ECONOMICAL_QUANTITY, 0) = 0 then
          ioCQtySupplyRule  := '1';
        else
          ioCQtySupplyRule  := tplCompldataSubContract.C_QTY_SUPPLY_RULE;
        end if;

        if     tplCompldataSubContract.C_TIME_SUPPLY_RULE = '2'
           and nvl(tplCompldataSubContract.CSU_FIXED_DELAY, 0) = 0 then
          ioCTimeSupplyRule  := '1';
        else
          ioCTimeSupplyRule  := tplCompldataSubContract.C_TIME_SUPPLY_RULE;
        end if;

        GetStockAndLocation(tplCompldataSubContract.STM_STOCK_ID, tplCompldataSubContract.STM_LOCATION_ID, iGcoGoodId, ioDestSTM_STOCK_ID
                          , ioDestSTM_LOCATION_ID);

        if ioPPSNomenclatureID is null then
          ioSchedPlanIDFromNom  := 0;
        else
          ioSchedPlanIDFromNom  := GetNomSchedulePlan(ioPPSNomenclatureID);
        end if;

        ioDonneeComplementaire  := tplCompldataSubContract.GCO_COMPL_DATA_SUBCONTRACT_ID;
        exit;
      end loop;

      -- Données complémentaire de sous-traitance non trouvée, initialisation avec les valeurs par défaut
      if ioFounded = 0 then
        ioCSupplyMode           := iCSupplyMode;
        ioDicFabConditionID     := '';
        ioCQtySupplyRule        := '1';
        ioEconomicalQuantity    := 0;
        ioModuloQuantity        := 0;
        ioCEconomicCode         := '1';
        ioCTimeSupplyRule       := '1';
        ioCmaFixedDelay         := 0;
        ioCmaShift              := 0;
        ioPacSupplierPartnerID  := FAL_TOOLS.GetDefaultSubcontract;
        ioFalSchedulePlanID     := FAL_LIB_SUBCONTRACTP.GetSchedulePlanId;
        ioCSchedulePlanCode     := '2';
        ioPPSNomenclatureID     := 0;
        ioDicMeasureUnitCode    := FAL_TOOLS.GetGoodMeasureUnit(iGcoGoodId);
        ioNumberOfDecimal       := FAL_TOOLS.GetGoo_Number_Of_Decimal(iGcoGoodId);
        ioConversionFactor      := 1;
        ioStandardLotQty        := 0;
        ioControlDelay          := 0;
        ioTrashPercent          := 0;
        ioTrashFixedQty         := 0;
        ioLossReferenceQty      := 0;
        ioSchedPlanIDFromNom    := 0;
        ioCoupledCoefficient    := 0;
        ioFixedDuration         := 0;
        ioSupplyDelay           := FAL_TOOLS.GetProcurementDelay(ioPacSupplierPartnerId);
        GetStockAndLocation(0, 0, iGcoGoodId, ioDestSTM_STOCK_ID, ioDestSTM_LOCATION_ID);
        ioDonneeComplementaire  := 0;
        return;
      end if;
    end if;
  end GetProductParameters;

  function GetProductParameters(
    iGcoGoodId            in number
  , iCSupplyMode          in varchar2
  , iDicFabConditionId    in varchar2 default null
  , iPacSupplierPartnerId in number default null
  , iDateRef              in date default null
  )
    return TMrpProductParam
  is
    result TMrpProductParam;
  begin
    result.cSupplyMode    := iCSupplyMode;
    FAL_LIB_MRP_CALCULATION.GetProductParameters(iGcoGoodId               => iGcoGoodId
                                               , iCSupplyMode             => iCSupplyMode
                                               , iDicFabConditionID       => iDicFabConditionId
                                               , iPacSupplierPartnerID    => iPacSupplierPartnerId
                                               , ioFounded                => result.Founded
                                               , ioCSupplyMode            => result.cSupplyMode
                                               , ioDicFabConditionId      => result.FabConditionId
                                               , ioEconomicalQuantity     => result.EconomicalQty
                                               , ioModuloQuantity         => result.ModuloQty
                                               , ioCEconomicCode          => result.cEconomicalQtyCode
                                               , ioCmaFixedDelay          => result.FixedDelay
                                               , ioCmaShift               => result.Shift
                                               , ioPacSupplierPartnerId   => result.SupplierId
                                               , ioFalSchedulePlanId      => result.SchedulePlanId
                                               , ioCSchedulePlanCode      => result.cSchedulePlanCode
                                               , ioPPSNomenclatureID      => result.NomenclatureId
                                               , ioDicMeasureUnitCode     => result.MeasureUnitCode
                                               , ioNumberOfDecimal        => result.DecimalNumber
                                               , ioConversionFactor       => result.ConversionFactor
                                               , ioStandardLotQty         => result.StandardLotQty
                                               , ioSupplyDelay            => result.SupplyDelay
                                               , ioControlDelay           => result.ControlDelay
                                               , ioTrashPercent           => result.TrashPercent
                                               , ioTrashFixedQty          => result.TrashFixedQty
                                               , ioLossReferenceQty       => result.LossReferenceQty
                                               , ioFixedDuration          => result.FixedDuration
                                               , ioSecurityDelay          => result.SecurityDelay
                                               , ioCQtySupplyRule         => result.cQtySupplyRule
                                               , ioCTimeSupplyRule        => result.cTimeSupplyRule
                                               , ioSchedPlanIDFromNom     => result.SchedulePlanIDFromNom
                                               , ioDestSTM_STOCK_ID       => result.StockId
                                               , ioDestSTM_LOCATION_ID    => result.LocationId
                                               , ioCoupledCoefficient     => result.CoupledCoefficient
                                               , ioDonneeComplementaire   => result.AdditionalDataId
                                               , iDateRef                 => iDateRef
                                                );
    result.EconomicalQty  := nvl(result.EconomicalQty, 0);
    result.TrashPercent   := nvl(result.TrashPercent, 0);
    result.TrashFixedQty  := nvl(result.TrashFixedQty, 0);
    return result;
  end;

  /**
  * procedure GetSubContractPComplData
  * Description : Recherche de la données complémentaire
  * @created ECA
  * @lastUpdate
  * @public
  * @param iGcoGoodId : Bien
  * @param iDicFabConditionID : Condition de fabrication
  * @param iPacSupplierPartnerID : Fournisseur
  * @param ioFounded : Trouvée
  * @param ioDonneeComplementaire : ID Donnée complémentaire fabrication, achat, sous-traitance...
  * @param iDateRef : Date référence
  */
  procedure GetSubContractPComplData(
    iGcoGoodId             in     number
  , iDicFabConditionID     in     varchar2
  , iPacSupplierPartnerID  in     number
  , ioFounded              in out integer
  , ioDonneeComplementaire in out number
  , iDateRef               in     date default null
  )
  is
    lvCSupplyMode          varchar2(10);
    lvDicFabConditionId    varchar2(10);
    lnEconomicalQuantity   number;
    lnModuloQuantity       number;
    lvCEconomicCode        varchar2(10);
    liCmaFixedDelay        integer;
    liCmaShift             integer;
    lnPacSupplierPartnerId number;
    lnFalSchedulePlanId    number;
    lvCSchedulePlanCode    varchar2(10);
    lnPPSNomenclatureID    number;
    lvDicMeasureUnitCode   varchar2(10);
    liNumberOfDecimal      integer;
    lnConversionFactor     number;
    lnStandardLotQty       number;
    liSupplyDelay          integer;
    liControlDelay         integer;
    lnTrashPercent         number;
    lnTrashFixedQty        number;
    lnLossReferenceQty     number;
    liFixedDuration        integer;
    liSecurityDelay        integer;
    lvCQtySupplyRule       varchar2(10);
    lvCTimeSupplyRule      varchar2(10);
    lnSchedPlanIDFromNom   number;
    lnDestSTM_STOCK_ID     number;
    lnDestSTM_LOCATION_ID  number;
    lnCoupledCoefficient   number;
    lnDonneeComplementaire number;
  begin
    GetProductParameters(iGcoGoodId
                       , '4'
                       , iDicFabConditionID
                       , iPacSupplierPartnerID
                       , ioFounded
                       , lvCSupplyMode
                       , lvDicFabConditionId
                       , lnEconomicalQuantity
                       , lnModuloQuantity
                       , lvCEconomicCode
                       , liCmaFixedDelay
                       , liCmaShift
                       , lnPacSupplierPartnerId
                       , lnFalSchedulePlanId
                       , lvCSchedulePlanCode
                       , lnPPSNomenclatureID
                       , lvDicMeasureUnitCode
                       , liNumberOfDecimal
                       , lnConversionFactor
                       , lnStandardLotQty
                       , liSupplyDelay
                       , liControlDelay
                       , lnTrashPercent
                       , lnTrashFixedQty
                       , lnLossReferenceQty
                       , liFixedDuration
                       , liSecurityDelay
                       , lvCQtySupplyRule
                       , lvCTimeSupplyRule
                       , lnSchedPlanIDFromNom
                       , lnDestSTM_STOCK_ID
                       , lnDestSTM_LOCATION_ID
                       , lnCoupledCoefficient
                       , ioDonneeComplementaire
                       , iDateRef
                        );
  end GetSubContractPComplData;

  /**
  * procedure CheckDefaultFabCond
  * Description : Recherche de la condition par défaut
  */
  procedure CheckDefaultFabCond(iGcoGoodId in number, iCSupplyMode in varchar2, ioFounded in out integer, iDateRef in date default null)
  is
    lvCSupplyMode          varchar2(10);
    lvDicFabConditionId    varchar2(10);
    lnEconomicalQuantity   number;
    lnModuloQuantity       number;
    lvCEconomicCode        varchar2(10);
    liCmaFixedDelay        integer;
    liCmaShift             integer;
    lnPacSupplierPartnerId number;
    lnFalSchedulePlanId    number;
    lvCSchedulePlanCode    varchar2(10);
    lnPPSNomenclatureID    number;
    lvDicMeasureUnitCode   varchar2(10);
    liNumberOfDecimal      integer;
    lnConversionFactor     number;
    lnStandardLotQty       number;
    liSupplyDelay          integer;
    liControlDelay         integer;
    lnTrashPercent         number;
    lnTrashFixedQty        number;
    lnLossReferenceQty     number;
    liFixedDuration        integer;
    liSecurityDelay        integer;
    lvCQtySupplyRule       varchar2(10);
    lvCTimeSupplyRule      varchar2(10);
    lnSchedPlanIDFromNom   number;
    lnDestSTM_STOCK_ID     number;
    lnDestSTM_LOCATION_ID  number;
    lnCoupledCoefficient   number;
    lnDonneeComplementaire number;
  begin
    GetProductParameters(iGcoGoodId
                       , iCSupplyMode
                       , ''
                       , 0
                       , ioFounded
                       , lvCSupplyMode
                       , lvDicFabConditionId
                       , lnEconomicalQuantity
                       , lnModuloQuantity
                       , lvCEconomicCode
                       , liCmaFixedDelay
                       , liCmaShift
                       , lnPacSupplierPartnerId
                       , lnFalSchedulePlanId
                       , lvCSchedulePlanCode
                       , lnPPSNomenclatureID
                       , lvDicMeasureUnitCode
                       , liNumberOfDecimal
                       , lnConversionFactor
                       , lnStandardLotQty
                       , liSupplyDelay
                       , liControlDelay
                       , lnTrashPercent
                       , lnTrashFixedQty
                       , lnLossReferenceQty
                       , liFixedDuration
                       , liSecurityDelay
                       , lvCQtySupplyRule
                       , lvCTimeSupplyRule
                       , lnSchedPlanIDFromNom
                       , lnDestSTM_STOCK_ID
                       , lnDestSTM_LOCATION_ID
                       , lnCoupledCoefficient
                       , lnDonneeComplementaire
                       , iDateRef
                        );
  end CheckDefaultFabCond;

  /**
  * function GetSubContractPComplData
  * Description : Recherche de la données complémentaire
  * @created ECA
  * @lastUpdate
  * @public
  * @param iGcoGoodId : Bien
  * @param iDicFabConditionID : Condition de fabrication
  * @param iPacSupplierPartnerID : Fournisseur
  * @param iDateRef : Date référence
  */
  function GetSubContractPComplData(iGcoGoodId in number, iDicFabConditionID in varchar2, iPacSupplierPartnerID in number, iDateRef in date default null)
    return number
  is
    liFounded             integer;
    lnGcoCompldataSubcpID number;
  begin
    GetSubContractPComplData(iGcoGoodId, iDicFabConditionID, iPacSupplierPartnerID, liFounded, lnGcoComplDataSubcpId, iDateRef);

    if liFounded = 1 then
      return lnGcoComplDataSubcpId;
    else
      return null;
    end if;
  end GetSubContractPComplData;

  /**
  * function DelObsoleteRecMRPLevelTable
  * Description : Suppression des enregistrements obsolètes de la table des niveaux complémentaires
  * @created CLG
  * @lastUpdate
  * @public
  */
  procedure DelObsoleteRecMRPLevelTable
  is
    pragma autonomous_transaction;

    cursor crOracleSession
    is
      select distinct CCL_SESSION_ID
                 from FAL_CB_COMP_LEVEL;
  begin
    for tplOracleSession in crOracleSession loop
      if COM_FUNCTIONS.Is_Session_Alive(tplOracleSession.CCL_SESSION_ID) = 0 then
        delete from FAL_CB_COMP_LEVEL
              where CCL_SESSION_ID = tplOracleSession.CCL_SESSION_ID;
      end if;
    end loop;

    commit;
  end;

  /**
  * procedure : DelReservedRecMRPLevelTable
  * Description : Suppression de toutes les réservations faites pour la session en cours
  *
  * @created CLG
  * @lastUpdate
  * @public
  * @param   iSessionId    Session Oracle qui a fait la réservation
  */
  procedure DelReservedRecMRPLevelTable(iSessionId in FAL_CB_COMP_LEVEL.CCL_SESSION_ID%type default null)
  is
    pragma autonomous_transaction;
  begin
    delete from FAL_CB_COMP_LEVEL
          where CCL_SESSION_ID = nvl(iSessionId, cSessionId);

    commit;
    DelObsoleteRecMRPLevelTable;
  end;

  /**
  * procedure : CheckProductBaseData
  * Description : Contrôle des données de base des produits
  */
  procedure CheckProductBaseData(iCheckCondition in integer default 1)
  is
    lnCount      integer;
    lnFounded    integer;
    lnSupplierId number;
  begin
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_PRD_CHK';

    -- nombre de produits
    select count(*)
      into lnCount
      from FAL_PROD_LEVEL;

    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
               , LID_FREE_CHAR_1
               , LID_FREE_CHAR_2
                )
         values (init_temp_id_seq.nextval
               , 'FAL_PRD_CHK'
               , 'FAL_PRD_LEVEL_CNT'
               , lnCount
                );

    -- vérification de la condition de fabrication
    for ltplProduct in (select GOO.GCO_GOOD_ID
                             , GOO.GOO_MAJOR_REFERENCE
                             , GOO.GOO_SECONDARY_REFERENCE
                             , PDT.C_SUPPLY_MODE
                          from GCO_GOOD GOO
                             , GCO_PRODUCT PDT
                             , FAL_PROD_LEVEL LEV
                         where GOO.GCO_GOOD_ID = PDT.GCO_GOOD_ID
                           and GOO.GCO_GOOD_ID = LEV.GCO_GOOD_ID) loop
      if (iCheckCondition = 1) then
        CheckDefaultFabCond(iGcoGoodId => ltplProduct.GCO_GOOD_ID, iCSupplyMode => ltplProduct.C_SUPPLY_MODE, ioFounded => lnFounded);

        -- produits sans condition de fabrication par défaut
        if lnFounded = 0 then
          insert into COM_LIST_ID_TEMP
                      (COM_LIST_ID_TEMP_ID
                     , LID_CODE
                     , LID_FREE_CHAR_1
                     , LID_FREE_CHAR_2
                      )
               values (init_temp_id_seq.nextval
                     , 'FAL_PRD_CHK'
                     , 'NO_DEFAULT_COND_CHK'
                     , ltplProduct.GOO_MAJOR_REFERENCE || ' ' || ltplProduct.GOO_SECONDARY_REFERENCE
                      );
        end if;
      end if;

      -- produits avec plusieurs conditions de fabrication par défaut
      select count(1)
        into lnCount
        from GCO_COMPL_DATA_MANUFACTURE
       where GCO_GOOD_ID = ltplProduct.GCO_GOOD_ID
         and CMA_DEFAULT = 1;

      if lnCount > 1 then
        insert into COM_LIST_ID_TEMP
                    (COM_LIST_ID_TEMP_ID
                   , LID_CODE
                   , LID_FREE_CHAR_1
                   , LID_FREE_CHAR_2
                    )
             values (init_temp_id_seq.nextval
                   , 'FAL_PRD_CHK'
                   , 'MANY_DEFAULT_COND_CHK'
                   , ltplProduct.GOO_MAJOR_REFERENCE || ' ' || ltplProduct.GOO_SECONDARY_REFERENCE
                    );
      end if;
    end loop;

    -- vérification du fournisseur par défaut
    select max(PAC_PERSON_ID)
      into lnSupplierId
      from PAC_PERSON PER
         , PAC_SUPPLIER_PARTNER SUP
     where PER.PAC_PERSON_ID = SUP.PAC_SUPPLIER_PARTNER_ID
       and PER.PER_NAME = PCS.PC_CONFIG.GETCONFIG('FAL_DEFAULT_PURCHASE');

    lnFounded  := 0;

    if lnSupplierId > 0 then
      lnFounded  := 1;
    end if;

    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
               , LID_FREE_CHAR_1
               , LID_FREE_CHAR_2
                )
         values (init_temp_id_seq.nextval
               , 'FAL_PRD_CHK'
               , 'DEFAULT_SUPPLIER_CHK'
               , lnFounded
                );

    -- produits avec "délai fixe" et "traçabilité complète"
    for ltplProduct in (select GOO.GOO_MAJOR_REFERENCE
                             , GOO.GOO_SECONDARY_REFERENCE
                          from GCO_GOOD GOO
                             , GCO_PRODUCT PDT
                         where GOO.GCO_GOOD_ID = PDT.GCO_GOOD_ID
                           and PDT.PDT_FULL_TRACABILITY = 1
                           and (   exists(select 1
                                            from GCO_COMPL_DATA_MANUFACTURE COMP
                                           where COMP.GCO_GOOD_ID = PDT.GCO_GOOD_ID
                                             and COMP.C_TIME_SUPPLY_RULE = '2')
                                or exists(select 1
                                            from GCO_COMPL_DATA_PURCHASE COMP
                                           where COMP.GCO_GOOD_ID = PDT.GCO_GOOD_ID
                                             and COMP.C_TIME_SUPPLY_RULE = '2')
                                or exists(select 1
                                            from GCO_COMPL_DATA_SUBCONTRACT COMP
                                           where COMP.GCO_GOOD_ID = PDT.GCO_GOOD_ID
                                             and COMP.C_TIME_SUPPLY_RULE = '2')
                               ) ) loop
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                 , LID_FREE_CHAR_1
                 , LID_FREE_CHAR_2
                  )
           values (init_temp_id_seq.nextval
                 , 'FAL_PRD_CHK'
                 , 'FIXED_DELAY_AND_TRACABILITY_CHK'
                 , ltplProduct.GOO_MAJOR_REFERENCE || ' ' || ltplProduct.GOO_SECONDARY_REFERENCE
                  );
    end loop;

    -- produits cochés CB pour lesquels le mode d'appro est <> 1,2,4
    for ltplProduct in (select GOO.GOO_MAJOR_REFERENCE
                             , GOO.GOO_SECONDARY_REFERENCE
                          from GCO_GOOD GOO
                             , GCO_PRODUCT PDT
                         where GOO.GCO_GOOD_ID = PDT.GCO_GOOD_ID
                           and PDT.C_SUPPLY_MODE not in('1', '2', '4')
                           and nvl(PDT.PDT_CALC_REQUIREMENT_MNGMENT, 0) = 1) loop
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                 , LID_FREE_CHAR_1
                 , LID_FREE_CHAR_2
                  )
           values (init_temp_id_seq.nextval
                 , 'FAL_PRD_CHK'
                 , 'SUPPLY_MODE_CHK'
                 , ltplProduct.GOO_MAJOR_REFERENCE || ' ' || ltplProduct.GOO_SECONDARY_REFERENCE
                  );
    end loop;

    -- biens qui ne sont ni des produits, ni des services, ni des peudo-biens ni des outils
    for ltplProduct in (select GOO.GOO_MAJOR_REFERENCE
                             , GOO.GOO_SECONDARY_REFERENCE
                          from GCO_GOOD GOO
                         where not exists(select 1
                                            from GCO_PRODUCT PDT
                                           where PDT.GCO_GOOD_ID = GOO.GCO_GOOD_ID)
                           and not exists(select 1
                                            from GCO_SERVICE SER
                                           where SER.GCO_GOOD_ID = GOO.GCO_GOOD_ID)
                           and not exists(select 1
                                            from GCO_PSEUDO_GOOD PSG
                                           where PSG.GCO_GOOD_ID = GOO.GCO_GOOD_ID)
                           and not exists(select 1
                                            from PPS_TOOLS PPS
                                           where PPS.GCO_GOOD_ID = GOO.GCO_GOOD_ID) ) loop
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                 , LID_FREE_CHAR_1
                 , LID_FREE_CHAR_2
                  )
           values (init_temp_id_seq.nextval
                 , 'FAL_PRD_CHK'
                 , 'GOOD_TYPE_CHK'
                 , ltplProduct.GOO_MAJOR_REFERENCE || ' ' || ltplProduct.GOO_SECONDARY_REFERENCE
                  );
    end loop;
  end;
end;
