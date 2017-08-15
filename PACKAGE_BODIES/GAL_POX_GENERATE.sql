--------------------------------------------------------
--  DDL for Package Body GAL_POX_GENERATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_POX_GENERATE" 
is
  cSchedulePlanCode            FAL_SCHEDULE_PLAN.C_SCHEDULE_PLANNING%type;
  cSupplyMode                  GCO_PRODUCT.C_SUPPLY_MODE%type;
  vFabConditionID              GCO_COMPL_DATA_MANUFACTURE.DIC_FAB_CONDITION_ID%type;
  cQtySupplyRule               GCO_COMPL_DATA_MANUFACTURE.C_QTY_SUPPLY_RULE%type;
  vEconomicalQty               GCO_COMPL_DATA_MANUFACTURE.CMA_ECONOMICAL_QUANTITY%type;
  vModuloQty                   GCO_COMPL_DATA_MANUFACTURE.CMA_MODULO_QUANTITY%type;
  cEconomicalQtyCode           GCO_COMPL_DATA_MANUFACTURE.C_ECONOMIC_CODE%type;
  cTimeSupplyRule              GCO_COMPL_DATA_MANUFACTURE.C_TIME_SUPPLY_RULE%type;
  vFixedDelay                  GCO_COMPL_DATA_MANUFACTURE.CMA_FIXED_DELAY%type;
  vDecalage                    GCO_COMPL_DATA_MANUFACTURE.CMA_SHIFT%type;
  vSchedulePlanIDFromNomen     GCO_COMPL_DATA_MANUFACTURE.FAL_SCHEDULE_PLAN_ID%type;
  vSchedulePlanID              GCO_COMPL_DATA_MANUFACTURE.FAL_SCHEDULE_PLAN_ID%type;
  vNomenclatureID              GCO_COMPL_DATA_MANUFACTURE.PPS_NOMENCLATURE_ID%type;
  vMeasureUnitCode             GCO_COMPL_DATA_MANUFACTURE.DIC_UNIT_OF_MEASURE_ID%type;
  vDecimalNumber               GCO_COMPL_DATA_MANUFACTURE.CDA_NUMBER_OF_DECIMAL%type;
  vStandardLotQty              GCO_COMPL_DATA_MANUFACTURE.CMA_LOT_QUANTITY%type;
  vSupplyDelay                 GCO_COMPL_DATA_MANUFACTURE.CMA_MANUFACTURING_DELAY%type;
  vTrashPercent                GCO_COMPL_DATA_MANUFACTURE.CMA_PERCENT_TRASH%type;
  vTrashFixedQty               GCO_COMPL_DATA_MANUFACTURE.CMA_FIXED_QUANTITY_TRASH%type;
  vLossReferenceQty            GCO_COMPL_DATA_MANUFACTURE.CMA_QTY_REFERENCE_LOSS%type;
  vStockDestinationOfGCO_COMPL GCO_COMPL_DATA_MANUFACTURE.STM_STOCK_ID%type;
  vEmplaceDestOfGCO_COMPL      GCO_COMPL_DATA_MANUFACTURE.STM_LOCATION_ID%type;
  vDonneeComplementaireFabId   GCO_COMPL_DATA_MANUFACTURE.GCO_COMPL_DATA_MANUFACTURE_ID%type;   --PRD-A051005-62536 Modif Produit couplés
  vFixedDuration               GCO_COMPL_DATA_MANUFACTURE.CMA_FIX_DELAY%type;
  vSupplierID                  PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type;
  vConversionFactor            GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type;
  vControlDelay                GCO_COMPL_DATA_PURCHASE.CPU_CONTROL_DELAY%type;

--************************************************************************************************************************--
--************************************************************************************************************************--
  procedure GetProductInfoLog(
    aGoodID                   GCO_GOOD.GCO_GOOD_ID%type
  , aSupplyMode               GCO_PRODUCT.C_SUPPLY_MODE%type
  , a_stm_stock_id_project    stm_stock.stm_stock_id%type
  , a_stm_location_id_project stm_stock.stm_stock_id%type
  , aSupplierID               PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  )
  is
    BlnIsProductWithMultiSourcing  number;
    xGCO_GCO_GOOD_ID               GCO_GOOD.GCO_GOOD_ID%type;
    xPAC_SUPPLIER_PARTNER_ID       PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type;
    xGCO_COMPL_DATA_PURCHASE_ID    GCO_COMPL_DATA_PURCHASE.GCO_COMPL_DATA_PURCHASE_ID%type;
    vC_QTY_SUPPLY_RULE             GCO_COMPL_DATA_MANUFACTURE.C_QTY_SUPPLY_RULE%type;
    vC_ECONOMIC_CODE               GCO_COMPL_DATA_MANUFACTURE.C_ECONOMIC_CODE%type;
    vC_TIME_SUPPLY_RULE            GCO_COMPL_DATA_MANUFACTURE.C_TIME_SUPPLY_RULE%type;
    vDIC_UNIT_OF_MEASURE_ID        GCO_COMPL_DATA_MANUFACTURE.DIC_UNIT_OF_MEASURE_ID%type;
    vCDA_NUMBER_OF_DECIMAL         GCO_COMPL_DATA_MANUFACTURE.CDA_NUMBER_OF_DECIMAL%type;
    vSTM_STOCK_ID                  GCO_COMPL_DATA_MANUFACTURE.STM_STOCK_ID%type;
    vSTM_LOCATION_ID               GCO_COMPL_DATA_MANUFACTURE.STM_LOCATION_ID%type;
    vGCO_COMPL_DATA_MANUFACTURE_ID GCO_COMPL_DATA_MANUFACTURE.GCO_COMPL_DATA_MANUFACTURE_ID%type;   --PRD-A051005-62536 Modif Produit couplés
    vCPU_ECONOMICAL_QUANTITY       GCO_COMPL_DATA_PURCHASE.CPU_ECONOMICAL_QUANTITY%type;
    vCPU_MODULO_QUANTITY           GCO_COMPL_DATA_PURCHASE.CPU_MODULO_QUANTITY%type;
    vCPU_FIXED_DELAY               GCO_COMPL_DATA_PURCHASE.CPU_FIXED_DELAY%type;
    vCPU_SHIFT                     GCO_COMPL_DATA_PURCHASE.CPU_SHIFT%type;
    vPAC_SUPPLIER_PARTNER_ID       GCO_COMPL_DATA_PURCHASE.PAC_SUPPLIER_PARTNER_ID%type;
    vCDA_CONVERSION_FACTOR         GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type;
    vCPU_SUPPLY_DELAY              GCO_COMPL_DATA_PURCHASE.CPU_SUPPLY_DELAY%type;
    vCPU_CONTROL_DELAY             GCO_COMPL_DATA_PURCHASE.CPU_CONTROL_DELAY%type;
    vCPU_PERCENT_TRASH             GCO_COMPL_DATA_PURCHASE.CPU_PERCENT_TRASH%type;
    vCPU_FIXED_QUANTITY_TRASH      GCO_COMPL_DATA_PURCHASE.CPU_FIXED_QUANTITY_TRASH%type;
    vCPU_QTY_REFERENCE_TRASH       GCO_COMPL_DATA_PURCHASE.CPU_QTY_REFERENCE_TRASH%type;
  begin
    begin
      --Gestion du MultiSourcing
      begin
        select nvl(PDT.PDT_MULTI_SOURCING, 0)
          into BlnIsProductWithMultiSourcing
          from GCO_PRODUCT PDT
         where PDT.GCO_GOOD_ID = aGoodId;
      exception
        when no_data_found then
          BlnIsProductWithMultiSourcing  := 0;
      end;

      xGCO_GCO_GOOD_ID              := 0;
      xPAC_SUPPLIER_PARTNER_ID      := 0;
      xGCO_COMPL_DATA_PURCHASE_ID   := 0;
      FAL_MSOURCING_FUNCTIONS.GetMultiSourcingDCA(aGoodId, 0, xGCO_GCO_GOOD_ID, xPAC_SUPPLIER_PARTNER_ID, xGCO_COMPL_DATA_PURCHASE_ID);

      -- Initialisation avec la donnée complémentaire achat par défaut du produit ...
      select C_QTY_SUPPLY_RULE
           , CPU_ECONOMICAL_QUANTITY
           , C_ECONOMIC_CODE
           , C_TIME_SUPPLY_RULE
           , CPU_MODULO_QUANTITY
           , CPU_FIXED_DELAY
           , CPU_SHIFT
           , PAC_SUPPLIER_PARTNER_ID
           , DIC_UNIT_OF_MEASURE_ID
           , CDA_NUMBER_OF_DECIMAL
           , CDA_CONVERSION_FACTOR
           , CPU_SUPPLY_DELAY
           , CPU_CONTROL_DELAY
           , CPU_PERCENT_TRASH
           , CPU_FIXED_QUANTITY_TRASH
           , CPU_QTY_REFERENCE_TRASH
           , STM_STOCK_ID
           , STM_LOCATION_ID
        into vC_QTY_SUPPLY_RULE
           , vCPU_ECONOMICAL_QUANTITY
           , vC_ECONOMIC_CODE
           , vC_TIME_SUPPLY_RULE
           , vCPU_MODULO_QUANTITY
           , vCPU_FIXED_DELAY
           , vCPU_SHIFT
           , vPAC_SUPPLIER_PARTNER_ID
           , vDIC_UNIT_OF_MEASURE_ID
           , vCDA_NUMBER_OF_DECIMAL
           , vCDA_CONVERSION_FACTOR
           , vCPU_SUPPLY_DELAY
           , vCPU_CONTROL_DELAY
           , vCPU_PERCENT_TRASH
           , vCPU_FIXED_QUANTITY_TRASH
           , vCPU_QTY_REFERENCE_TRASH
           , vSTM_STOCK_ID
           , vSTM_LOCATION_ID
        from (select   (case
                          when CPU_DEFAULT_SUPPLIER = 1 then 0
                          when PAC_SUPPLIER_PARTNER_ID = gal_pox_generate.GetDefaultSupplier then 1
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
                     , nvl(PAC_SUPPLIER_PARTNER_ID, gal_pox_generate.GetDefaultSupplier) PAC_SUPPLIER_PARTNER_ID
                     , DIC_UNIT_OF_MEASURE_ID
                     , CDA_NUMBER_OF_DECIMAL
                     , CDA_CONVERSION_FACTOR
                     , CPU_SUPPLY_DELAY
                     , CPU_CONTROL_DELAY
                     , CPU_PERCENT_TRASH
                     , CPU_FIXED_QUANTITY_TRASH
                     , CPU_QTY_REFERENCE_TRASH
                     , STM_STOCK_ID
                     , STM_LOCATION_ID
                  from GCO_COMPL_DATA_PURCHASE
                 where GCO_GOOD_ID = aGoodId
                   and (    (    aSupplierID <> 0
                             and PAC_SUPPLIER_PARTNER_ID = aSupplierID)
                        or (    aSupplierID = 0
                            and BlnIsProductWithMultiSourcing = 1
                            and xGCO_COMPL_DATA_PURCHASE_ID <> 0
                            and GCO_COMPL_DATA_PURCHASE_ID = xGCO_COMPL_DATA_PURCHASE_ID
                           )
                        or (    aSupplierID = 0
                            and BlnIsProductWithMultiSourcing = 1
                            and xGCO_COMPL_DATA_PURCHASE_ID = 0
                            and CPU_DEFAULT_SUPPLIER = 1)
                        or (    aSupplierID = 0
                            and BlnIsProductWithMultiSourcing = 0
                            and (   CPU_DEFAULT_SUPPLIER = 1
                                 or PAC_SUPPLIER_PARTNER_ID = gal_pox_generate.GetDefaultSupplier
                                 or PAC_SUPPLIER_PARTNER_ID is null)
                           )
                       )
              order by ORDER_FIELD)
       where rownum = 1;

      cSupplyMode                   := aSupplyMode;
      -- -- 01 -- Condition de fabrication
      vFabConditionID               := '';

      -- -- 02 -- Règle quantitative d'approvisionnement
      if     vC_QTY_SUPPLY_RULE = '2'
         and vCPU_ECONOMICAL_QUANTITY = 0 then
        cQtySupplyRule  := '1';
      else
        cQtySupplyRule  := vC_QTY_SUPPLY_RULE;
      end if;

      -- -- 03 -- Qté Economique
      vEconomicalQty                := vCPU_ECONOMICAL_QUANTITY;
      -- -- 04 -- Qté modulo
      vModuloQty                    := vCPU_MODULO_QUANTITY;
      -- -- 05 -- Code Qté Economique
      cEconomicalQtyCode            := vC_ECONOMIC_CODE;

      -- -- 06 -- Règle temporelle d'approvisionnement
      if     vC_TIME_SUPPLY_RULE = '2'
         and vCPU_FIXED_DELAY = 0 then
        cTimeSupplyRule  := '1';
      else
        cTimeSupplyRule  := vC_TIME_SUPPLY_RULE;
      end if;

      -- -- 07 -- Délai Fixe (Nb. Périodicité Fixe)
      vFixedDelay                   := vCPU_FIXED_DELAY;
      -- -- 08 -- Décalage
      vDecalage                     := vCPU_SHIFT;
      -- -- 09 -- Fournisseur
      vSupplierID                   := vPAC_SUPPLIER_PARTNER_ID;
      -- -- 10 -- Gamme opératoire
      vSchedulePlanID               := 0;
      -- -- 11 -- Code de planification
      cSchedulePlanCode             := '';
      -- -- 12 -- Nomenclature
      vNomenclatureID               := 0;
      -- -- 13 -- Code unité de mesure
      vMeasureUnitCode              := vDIC_UNIT_OF_MEASURE_ID;
      -- -- 14 -- Nombre de décimales du produit
      vDecimalNumber                := vCDA_NUMBER_OF_DECIMAL;
      -- -- 15 -- facteur de conversion
      vConversionFactor             := vCDA_CONVERSION_FACTOR;
      -- -- 16 -- Qté lot standard
      vStandardLotQty               := 0;
      -- -- 17 -- Durée d'approvisionnement
      vSupplyDelay                  := vCPU_SUPPLY_DELAY;

      if vSupplyDelay = 0 then
        begin
          select nvl(CRE_SUPPLY_DELAY, 0)
            into vSupplyDelay
            from PAC_SUPPLIER_PARTNER
           where PAC_SUPPLIER_PARTNER_ID = vSupplierID;
        exception
          when no_data_found then
            vSupplyDelay  := 0;
        end;
      end if;

      -- -- 18 -- Durée de controle
      vControlDelay                 := vCPU_CONTROL_DELAY;
      -- -- 19 -- Pourcentage de rebut
      vTrashPercent                 := vCPU_PERCENT_TRASH;
      -- -- 20 -- Qté fixe de rebut
      vTrashFixedQty                := vCPU_FIXED_QUANTITY_TRASH;
      -- -- 21 -- Quantité de référence perte
      vLossReferenceQty             := vCPU_QTY_REFERENCE_TRASH;
      -- -- 22 -- Gamme liée à la nomenclature
      vSchedulePlanIDFromNomen      := 0;
      vStockDestinationOfGCO_COMPL  := a_stm_stock_id_project;
      vEmplaceDestOfGCO_COMPL       := a_stm_location_id_project;
      -- PRD-A051005-62536 Modif Produit couplés
      --vCoupledCoefficient := 0;
      vDonneeComplementaireFabId    := 0;
      -- Durée fixe
      vFixedDuration                := 0;
    -- DCA pas trouvée
    -- Initialisation des valeurs par défaut pour un produit acheté
    exception
      when no_data_found then
        cSupplyMode                   := aSupplyMode;
        -- -- 01 -- Condition de fabrication
        vFabConditionID               := '';
        -- -- 02 -- Règle quantitative d'approvisionnement
        cQtySupplyRule                := '1';   -- Qté selon besoin
        -- -- 03 -- Qté Economique
        vEconomicalQty                := 0;
        -- -- 04 -- Qté Modulo
        vModuloQty                    := 0;
        -- -- 05 -- Code Qté Economique
        cEconomicalQtyCode            := '1';   -- Lot d'approvisionnement
        -- -- 06 -- Règle temporelle d'approvisionnement
        cTimeSupplyRule               := '1';   -- Délai selon besoin
        -- -- 07 -- Délai Fixe (Nb. Périodicité Fixe)
        vFixedDelay                   := 0;
        -- -- 08 -- Décalage
        vDecalage                     := 0;

        -- -- 09 -- Fournisseur
        if aSupplierID <> 0 then
          vSupplierID  := aSupplierID;
        else
          begin
            select nvl(PAC_PERSON_ID, 0)
              into vSupplierID
              from PAC_PERSON
                 , PAC_SUPPLIER_PARTNER
             where PAC_PERSON_ID = PAC_SUPPLIER_PARTNER_ID
               and PER_NAME = PCS.PC_CONFIG.GetConfig('FAL_DEFAULT_PURCHASE');
          exception
            when no_data_found then
              vSupplierID  := 0;
          end;

          if vSupplierID = 0 then
            begin
              select nvl(PAC_PERSON_ID, 0)
                into vSupplierID
                from (select   nvl(PAC_PERSON_ID, 0) PAC_PERSON_ID
                          from PAC_PERSON
                             , PAC_SUPPLIER_PARTNER
                         where PAC_PERSON_ID = PAC_SUPPLIER_PARTNER_ID
                      order by PER_NAME)
               where rownum = 1;
            exception
              when no_data_found then
                vSupplierId  := 0;
            end;
          end if;
        end if;

        -- -- 10 -- Gamme opératoire
        vSchedulePlanID               := 0;
        -- -- 11 -- Code de planificatiohn
        cSchedulePlanCode             := '1';   -- Selon produit
        -- -- 12 -- Nomenclature
        vNomenclatureID               := 0;

        begin
          select DIC_UNIT_OF_MEASURE_ID
            into vMeasureUnitCode
            from GCO_GOOD
           where GCO_GOOD_ID = aGoodId;
        exception
          when no_data_found then
            vMeasureUnitCode  := null;
        end;

        begin
          select GOO_NUMBER_OF_DECIMAL
            into vDecimalNumber
            from GCO_GOOD
           where GCO_GOOD_ID = aGoodId;
        exception
          when no_data_found then
            vDecimalNumber  := null;
        end;

        -- -- 15 -- facteur de conversion
        vConversionFactor             := 1;
        -- -- 16 -- Qté lot standard
        vStandardLotQty               := 0;

        -- -- 17 -- Durée d'approvisionnement
        begin
          select nvl(CRE_SUPPLY_DELAY, 0)
            into vSupplyDelay
            from PAC_SUPPLIER_PARTNER
           where PAC_SUPPLIER_PARTNER_ID = vSupplierID;
        exception
          when no_data_found then
            vSupplyDelay  := 0;
        end;

        -- -- 18 -- Durée de controle
        vControlDelay                 := 0;
        -- -- 19 -- pourcentage de rebut
        vTrashPercent                 := 0;
        -- -- 20 -- Qté fixe de rebut
        vTrashFixedQty                := 0;
        -- -- 21 -- Qté de référence de perte
        vLossReferenceQty             := 0;
        -- -- 22 -- Gamme liée à la nomenclature
        vSchedulePlanIDFromNomen      := 0;
        --recherche du Stock destination et Emplacement Destination
        vStockDestinationOfGCO_COMPL  := a_stm_stock_id_project;
        vEmplaceDestOfGCO_COMPL       := a_stm_location_id_project;
        -- PRD-A051005-62536 Modif Produit couplés
        --vCoupledCoefficient := 0;
        vDonneeComplementaireFabId    := 0;
        -- Durée fixe
        vFixedDuration                := 0;
    end;
  end GetProductInfoLog;

--************************************************************************************************************************--
--************************************************************************************************************************--
  procedure CreatePropApproLog(
    aGoodID                       GCO_GOOD.GCO_GOOD_ID%type
  , aNeedDate                     date
  , aQteDemande                   number
  , aDocRecordID                  DOC_RECORD.DOC_RECORD_ID%type
  , aSupplyMode                   GCO_PRODUCT.C_SUPPLY_MODE%type
  , a_stm_stock_id_project        STM_STOCK.stm_stock_id%type
  , a_stm_location_id_project     STM_STOCK.stm_stock_id%type
  , aSupplierID                   PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  , aSupplyRequestId              FAL_SUPPLY_REQUEST.FAL_SUPPLY_REQUEST_ID%type
  , ResPropDocID              out FAL_DOC_PROP.FAL_DOC_PROP_ID%type
  )
  is
    OutPropId        FAL_LOT_PROP.FAL_LOT_PROP_ID%type;
    vDocRecordID     DOC_RECORD.DOC_RECORD_ID%type;
    aCreatedSupplyID FAL_LOT_PROP.FAL_LOT_PROP_ID%type;
  begin
    vDocRecordID  := aDocRecordID;
    GetProductInfoLog(aGoodID, aSupplyMode, a_stm_stock_id_project, a_stm_location_id_project, aSupplierID);
    --Création de la proposition et planification arrière :
    FAL_NEEDCALCUL_PROCESSUS.Processus_CreatePropApproLog
      (OutPropId
     ,
       -- TcbParameters
       cSupplyMode
     , vSupplierID
     , vControlDelay
     , vSupplyDelay
     , vConversionFactor
     ,
       -- Fin de TcbParameters
       '1'   --aTypeProp --> C_PROP_TYPE 1=standard
     , null   --aNeedID
     , aGoodID
     , null   --aOriginStockID
     , null   --aOriginLocationID
     , a_stm_stock_id_project   --aTargetStockID --> Default Stock Affaire
     , a_stm_location_id_project   --aTargetLocationID --> Default Location Affaire
     , aNeedDate
     , aQteDemande
     , 0   --aQteRebutPlannifie
     , null   --aCharacterizations_ID1
     , null   --aCharacterizations_ID2
     , null   --aCharacterizations_ID3
     , null   --aCharacterizations_ID4
     , null   --aCharacterizations_ID5
     , null   --aCharacterizations_VA1
     , null   --aCharacterizations_VA2
     , null   --aCharacterizations_VA3
     , null   --aCharacterizations_VA4
     , null   --aCharacterizations_VA5
     , pcs.pc_functions.translateword('Calcul des besoins sur affaire')   -- aText
     , null   --aPlanDirecteurId
     , aSupplyRequestId   --0 --> aSupplyRequestID --> eviter la suppression de la pof (> attention relecture doc_record_id sur DA) -----> forcer création DA -> Oui dans CBA
     , 0   --bPlanifOnBeginDate > decallage backward
     , vDocRecordID
     , 0   --IsCallByNeedCalculation
     , null   --aFAL_PIC_LINE_ID
     , null   --aGOO_SECONDARY_REFERENCE
     , null   --aDES_SHORT_DESCR
      );

    if OutPropId is not null then
      ResPropDocID  := OutPropId;
      --Création de l'approvisionnement associé (réseau) :
      FAL_NETWORK_DOC.CreateReseauApproPropApproLog(OutPropId, aCreatedSupplyID);
    end if;
  end CreatePropApproLog;

--************************************************************************************************************************--
--************************************************************************************************************************--
  procedure UpdateStockProjectCsant(
    PropId                    fal_lot_prop.fal_lot_prop_id%type
  , aGsmNomPath               gal_project_supply_mode.gsm_nom_path%type default ' '
  , aTaskGoodId               gal_project_supply_mode.gal_task_good_id%type default 0
  , aPpsNomenHeaderId         gal_project_supply_mode.pps_nomenclature_header_id%type default 0
  , a_stm_stock_id_project    stm_stock.stm_stock_id%type
  , a_stm_location_id_project stm_stock.stm_stock_id%type
  )
  is   --Maj stock affaire sur les appros (composants) à l'affaire...
    v_level               number                                               := 0;
    v_cpt                 number                                               := 0;
    v_nom_level           number                                               := 0;
    v_good_id             GCO_GOOD.GCO_GOOD_ID%type;
    v_project_supply_mode GAL_PROJECT_SUPPLY_MODE.C_PROJECT_SUPPLY_MODE%type;
    v_stm_stock_id        stm_stock.stm_stock_id%type;
    v_stm_location_id     stm_stock.stm_stock_id%type;

    cursor C_GSM
    is
      select   GSM_NOM_LEVEL
             , GAL_PROJECT_SUPPLY_MODE.GCO_GOOD_ID
             , C_PROJECT_SUPPLY_MODE
          from GAL_PROJECT_SUPPLY_MODE
         where PPS_NOMENCLATURE_HEADER_ID = aPpsNomenHeaderId
           and GSM_NOM_PATH like trim(aGsmNomPath) || '%'
           and GAL_TASK_GOOD_ID = aTaskGoodId
      --AND NVL(GSM_ALLOW_UPDATE,1) = 1
      order by GAL_TASK_GOOD_ID
             , PPS_NOMENCLATURE_HEADER_ID
             , GSM_NOM_PATH;
  begin
    v_cpt  := 0;

    open C_GSM;

    loop
      fetch C_GSM
       into v_nom_level
          , v_good_id
          , v_project_supply_mode;

      exit when C_GSM%notfound;

      if v_cpt = 0 then
        v_level  := v_nom_level;
      else
        if v_nom_level = v_level + 1 then
          if v_project_supply_mode not in('1', '5') then   --Si <> Stock et <> non approvisionnée
            update FAL_LOT_MAT_LINK_PROP
               set STM_STOCK_ID = a_stm_stock_id_project
                 , STM_LOCATION_ID = a_stm_location_id_project
             where GCO_GOOD_ID = v_good_id
               and FAL_LOT_PROP_ID = PropId;
          end if;

          if v_project_supply_mode = '1' then   --Si Stock
            begin
              select STM_STOCK_ID
                   , STM_LOCATION_ID
                into v_stm_stock_id
                   , v_stm_location_id
                from GCO_PRODUCT
               where GCO_GOOD_ID = v_Good_Id;
            exception
              when no_data_found then
                v_stm_stock_id     := a_stm_stock_id_project;
                v_stm_location_id  := a_stm_location_id_project;
            end;

            update FAL_LOT_MAT_LINK_PROP
               set STM_STOCK_ID = v_stm_stock_id
                 , STM_LOCATION_ID = v_stm_location_id
             where GCO_GOOD_ID = v_good_id
               and FAL_LOT_PROP_ID = PropId;
          end if;

          if v_project_supply_mode = '5' then   --Suppression de la liste de composant si non approvisionné
            delete from FAL_LOT_MAT_LINK_PROP
                  where GCO_GOOD_ID = v_good_id
                    and FAL_LOT_PROP_ID = PropId;
          end if;
        end if;

        if v_nom_level <= v_level then
          exit;
        end if;
      end if;

      v_cpt  := v_cpt + 1;
    end loop;

    close C_GSM;
  end UpdateStockProjectCsant;

--************************************************************************************************************************--
--************************************************************************************************************************--
  procedure GetProductInfoFab(
    aGoodID                   GCO_GOOD.GCO_GOOD_ID%type
  , aSupplyMode               GCO_PRODUCT.C_SUPPLY_MODE%type
  , a_stm_stock_id_project    stm_stock.stm_stock_id%type
  , a_stm_location_id_project stm_stock.stm_stock_id%type
  , aPpsNomenID               PPS_NOMENCLATURE.pps_nomenclature_id%type
  )
  is
    vDIC_FAB_CONDITION_ID          GCO_COMPL_DATA_MANUFACTURE.DIC_FAB_CONDITION_ID%type;
    vC_QTY_SUPPLY_RULE             GCO_COMPL_DATA_MANUFACTURE.C_QTY_SUPPLY_RULE%type;
    vCMA_ECONOMICAL_QUANTITY       GCO_COMPL_DATA_MANUFACTURE.CMA_ECONOMICAL_QUANTITY%type;
    vCMA_MODULO_QUANTITY           GCO_COMPL_DATA_MANUFACTURE.CMA_MODULO_QUANTITY%type;
    vC_ECONOMIC_CODE               GCO_COMPL_DATA_MANUFACTURE.C_ECONOMIC_CODE%type;
    vC_TIME_SUPPLY_RULE            GCO_COMPL_DATA_MANUFACTURE.C_TIME_SUPPLY_RULE%type;
    vCMA_FIXED_DELAY               GCO_COMPL_DATA_MANUFACTURE.CMA_FIXED_DELAY%type;
    vCMA_SHIFT                     GCO_COMPL_DATA_MANUFACTURE.CMA_SHIFT%type;
    vFAL_SCHEDULE_PLAN_ID          GCO_COMPL_DATA_MANUFACTURE.FAL_SCHEDULE_PLAN_ID%type;
    vPPS_NOMENCLATURE_ID           GCO_COMPL_DATA_MANUFACTURE.PPS_NOMENCLATURE_ID%type;
    vDIC_UNIT_OF_MEASURE_ID        GCO_COMPL_DATA_MANUFACTURE.DIC_UNIT_OF_MEASURE_ID%type;
    vCDA_NUMBER_OF_DECIMAL         GCO_COMPL_DATA_MANUFACTURE.CDA_NUMBER_OF_DECIMAL%type;
    vCMA_LOT_QUANTITY              GCO_COMPL_DATA_MANUFACTURE.CMA_LOT_QUANTITY%type;
    vCMA_MANUFACTURING_DELAY       GCO_COMPL_DATA_MANUFACTURE.CMA_MANUFACTURING_DELAY%type;
    vCMA_PERCENT_TRASH             GCO_COMPL_DATA_MANUFACTURE.CMA_PERCENT_TRASH%type;
    vCMA_FIXED_QUANTITY_TRASH      GCO_COMPL_DATA_MANUFACTURE.CMA_FIXED_QUANTITY_TRASH%type;
    vCMA_QTY_REFERENCE_LOSS        GCO_COMPL_DATA_MANUFACTURE.CMA_QTY_REFERENCE_LOSS%type;
    vSTM_STOCK_ID                  GCO_COMPL_DATA_MANUFACTURE.STM_STOCK_ID%type;
    vSTM_LOCATION_ID               GCO_COMPL_DATA_MANUFACTURE.STM_LOCATION_ID%type;
    vGCO_COMPL_DATA_MANUFACTURE_ID GCO_COMPL_DATA_MANUFACTURE.GCO_COMPL_DATA_MANUFACTURE_ID%type;   --PRD-A051005-62536 Modif Produit couplés
    vCMA_FIX_DELAY                 GCO_COMPL_DATA_MANUFACTURE.CMA_FIX_DELAY%type;
  begin
    begin
      select DIC_FAB_CONDITION_ID
           , C_QTY_SUPPLY_RULE
           , CMA_ECONOMICAL_QUANTITY
           , CMA_MODULO_QUANTITY
           , C_ECONOMIC_CODE
           , C_TIME_SUPPLY_RULE
           , CMA_FIXED_DELAY
           , CMA_SHIFT
           , FAL_SCHEDULE_PLAN_ID
           , aPpsNomenID
           ,   --PPS_NOMENCLATURE_ID, --Parametre Gestion par affaire
             DIC_UNIT_OF_MEASURE_ID
           , CDA_NUMBER_OF_DECIMAL
           , CMA_LOT_QUANTITY
           , CMA_MANUFACTURING_DELAY
           , CMA_PERCENT_TRASH
           , CMA_FIXED_QUANTITY_TRASH
           , CMA_QTY_REFERENCE_LOSS
           , STM_STOCK_ID
           , STM_LOCATION_ID
           , GCO_COMPL_DATA_MANUFACTURE_ID
           ,   --PRD-A051005-62536 Modif Produit couplés
             CMA_FIX_DELAY
        into vDIC_FAB_CONDITION_ID
           , vC_QTY_SUPPLY_RULE
           , vCMA_ECONOMICAL_QUANTITY
           , vCMA_MODULO_QUANTITY
           , vC_ECONOMIC_CODE
           , vC_TIME_SUPPLY_RULE
           , vCMA_FIXED_DELAY
           , vCMA_SHIFT
           , vFAL_SCHEDULE_PLAN_ID
           , vPPS_NOMENCLATURE_ID
           , vDIC_UNIT_OF_MEASURE_ID
           , vCDA_NUMBER_OF_DECIMAL
           , vCMA_LOT_QUANTITY
           , vCMA_MANUFACTURING_DELAY
           , vCMA_PERCENT_TRASH
           , vCMA_FIXED_QUANTITY_TRASH
           , vCMA_QTY_REFERENCE_LOSS
           , vSTM_STOCK_ID
           , vSTM_LOCATION_ID
           , vGCO_COMPL_DATA_MANUFACTURE_ID
           ,   --PRD-A051005-62536 Modif Produit couplés
             vCMA_FIX_DELAY
        from GCO_COMPL_DATA_MANUFACTURE
       where GCO_GOOD_ID = aGoodId
         -- Condition par défaut (Calcul des besoins) ...
         and CMA_DEFAULT = 1;

      --La donnée complémentaire de fabrication (DCF) a été trouvée
      --bConditionFound := True;
      cSupplyMode                   := aSupplyMode;

      -- 01 -- Condition de fabrication
      if vDIC_FAB_CONDITION_ID is null then
        begin
          select DIC_FAB_CONDITION_ID
            into vFabConditionID
            from (select   DIC_FAB_CONDITION_ID
                      from DIC_FAB_CONDITION
                  order by A_DATECRE)
           where rownum = 1;
        exception
          when no_data_found then
            vFabConditionID  := null;
        end;
      else
        vFabConditionID  := vDIC_FAB_CONDITION_ID;
      end if;

      -- 02 -- Règle quantitative d'approvisionnement
      if     vC_QTY_SUPPLY_RULE = '2'
         and vCMA_ECONOMICAL_QUANTITY = 0 then
        cQtySupplyRule  := '1';
      else
        cQtySupplyRule  := vC_QTY_SUPPLY_RULE;
      end if;

      -- 03 -- Qté Economique
      vEconomicalQty                := vCMA_ECONOMICAL_QUANTITY;
      -- 04 -- Qté Modulo
      vModuloQty                    := vCMA_MODULO_QUANTITY;
      -- 05 -- Code Qté Economique
      cEconomicalQtyCode            := vC_ECONOMIC_CODE;

      -- 06 --  Règle temporelle d'approvisionnement
      if     vC_TIME_SUPPLY_RULE = '2'
         and vCMA_FIXED_DELAY = 0 then
        cTimeSupplyRule  := '1';
      else
        cTimeSupplyRule  := vC_TIME_SUPPLY_RULE;
      end if;

      -- 07 -- Délai Fixe (Nb. Périodicité Fixe)
      vFixedDelay                   := vCMA_FIXED_DELAY;
      -- 08 -- Décalage
      vDecalage                     := vCMA_SHIFT;
      -- 09 -- Fournisseur
      vSupplierID                   := 0;
      -- 10 -- Gamme opératoire
      vSchedulePlanID               := vFAL_SCHEDULE_PLAN_ID;

      -- 11 -- Code de planification
      begin
        select nvl(C_SCHEDULE_PLANNING, 1)
          into cSchedulePlanCode
          from FAL_SCHEDULE_PLAN
         where FAL_SCHEDULE_PLAN_ID = vFAL_SCHEDULE_PLAN_ID;
      exception
        when no_data_found then
          cSchedulePlanCode  := 1;
      end;

      --Select NVL(FAL_fctCalculDesBesoins.GetSchedulePlanCode(vFAL_SCHEDULE_PLAN_ID),1) into cSchedulePlanCode from dual;
      --'1' = Selon produit par défaut ...

      -- 12 -- Nomenclature
      vNomenclatureID               := vPPS_NOMENCLATURE_ID;
      -- 13 -- Code unité de mesure
      vMeasureUnitCode              := vDIC_UNIT_OF_MEASURE_ID;
      -- 14 -- Nombre de décimales du produit
      vDecimalNumber                := vCDA_NUMBER_OF_DECIMAL;
      -- 15 -- facteur de conversion
      vConversionFactor             := 1;
      -- 16 -- Qté lot standard
      vStandardLotQty               := vCMA_LOT_QUANTITY;
      -- 17 -- Durée d'approvisionnement
      vSupplyDelay                  := vCMA_MANUFACTURING_DELAY;
      -- 18 -- Durée de controle
      vControlDelay                 := 0;
      -- 19 -- Pourcentage de rebut
      vTrashPercent                 := vCMA_PERCENT_TRASH;
      -- 20 -- Quantité fixe de rebut
      vTrashFixedQty                := vCMA_FIXED_QUANTITY_TRASH;
      -- 21 -- Quantité de référence perte
      vLossReferenceQty             := vCMA_QTY_REFERENCE_LOSS;

      -- 22 -- gamme liée à la nomenclature
      if vPPS_NOMENCLATURE_ID = 0 then
        vSchedulePlanIDFromNomen  := 0;
      else
        begin
          select FAL_SCHEDULE_PLAN_ID
            into vSchedulePlanIDFromNomen
            from PPS_NOMENCLATURE
           where PPS_NOMENCLATURE_ID = vPPS_NOMENCLATURE_ID;
        exception
          when no_data_found then
            vSchedulePlanIDFromNomen  := 0;
        end;
      end if;

      --recherche du Stock destination et Emplacement Destination
      --    GetStockEtEmplacementStartWithParamsFirstAndGoodAfter(FieldByName('STM_STOCK_ID').AsCurrency,
      --      FieldByName('STM_LOCATION_ID').AsCurrency, aGoodId, calcSTM_STOCK_ID, calcSTM_LOCATION_ID);
      vStockDestinationOfGCO_COMPL  := a_stm_stock_id_project;
      vEmplaceDestOfGCO_COMPL       := a_stm_location_id_project;
      --PRD-A051005-62536 Modif Produit couplés
      --vCoupledCoefficient := 0;
      vDonneeComplementaireFabId    := 0;
      --Durée fixe
      vFixedDuration                := vCMA_FIX_DELAY;
    exception
      when no_data_found then
        --DCF pas trouvée
        -- Initialisation des valeurs par défaut pour un produit fabriqué

        --bConditionFound := False;
        cSupplyMode                   := aSupplyMode;

        -- 01 -- Condition de fabrication
        begin
          select DIC_FAB_CONDITION_ID
            into vFabConditionID
            from (select   DIC_FAB_CONDITION_ID
                      from DIC_FAB_CONDITION
                  order by A_DATECRE)
           where rownum = 1;
        exception
          when no_data_found then
            vFabConditionID  := null;
        end;

        -- 02 -- Règle quantitative d'approvisionnement
        cQtySupplyRule                := '1';   --Qté selon besoin
        -- 03 -- Qté Economique
        vEconomicalQty                := 0;
        -- 04 -- Qté Modulo
        vModuloQty                    := 0;
        -- 05 -- Code Qté Economique
        cEconomicalQtyCode            := '1';   --Lot d'approvisionnement
        -- 06 -- Règle temporelle d'approvisionnement
        cTimeSupplyRule               := '1';   --Délai selon besoin
        -- 07 -- Délai Fixe (Nb. Périodicité Fixe)
        vFixedDelay                   := 0;
        -- 08 -- Décalage
        vDecalage                     := 0;
        -- 09 -- Fournisseur
        vSupplierID                   := 0;
        -- 10 -- Gamme opératoire
        vSchedulePlanID               := 0;
        -- 11 -- Code de planification
        cSchedulePlanCode             := '1';   --Selon produit
        -- 12 -- Nomenclature
        vNomenclatureID               := aPpsNomenID;

        --vNomenclatureID := 0;

        -- 13 -- Code unité de mesure

        -- 14 -- Nombre de décimales du produit
          --    if aProductLevelItem <> nil then begin
          --      DecimalNumber := aProductLevelItem.aNumberOfDecimal;
          --      MeasureUnitCode := aProductLevelItem.aDIC_UNIT_OF_MEASURE_ID;
          --    end
          --    else begin
          --      vMeasureUnitCode := GetGoodMeasureUnit(aGoodId);
          --      vDecimalNumber := GetGoo_Number_Of_Decimal(aGoodId);
           --    end;
        begin
          select DIC_UNIT_OF_MEASURE_ID
            into vMeasureUnitCode
            from GCO_GOOD
           where GCO_GOOD_ID = aGoodId;
        exception
          when no_data_found then
            vMeasureUnitCode  := null;
        end;

        begin
          select GOO_NUMBER_OF_DECIMAL
            into vDecimalNumber
            from GCO_GOOD
           where GCO_GOOD_ID = aGoodId;
        exception
          when no_data_found then
            vDecimalNumber  := null;
        end;

        -- 15 -- facteur de conversion
        vConversionFactor             := 1;
        -- 16 -- Qté lot standard
        vStandardLotQty               := 1;
        -- 17 -- Durée d'approvisionnement
        vSupplyDelay                  := 0;
        -- 18 -- Durée de controle
        vControlDelay                 := 0;
        -- 19 -- Pourcentage de rebut
        vTrashPercent                 := 0;
        -- 20 -- Quantité fixe de rebut
        vTrashFixedQty                := 0;
        -- 21 -- Quantité de référence perte
        vLossReferenceQty             := 0;
        -- 22 -- gamme liée à la nomenclature
        vSchedulePlanIDFromNomen      := 0;
        --recherche du Stock destination et Emplacement Destination
        --GetStockEtEmplacementStartWithParamsFirstAndGoodAfter(0, 0, aGoodId, calcSTM_STOCK_ID, calcSTM_LOCATION_ID);
        vStockDestinationOfGCO_COMPL  := a_stm_stock_id_project;
        vEmplaceDestOfGCO_COMPL       := a_stm_location_id_project;
        --PRD-A051005-62536 Modif Produit couplés
        --vCoupledCoefficient := 0;
        vDonneeComplementaireFabId    := 0;
        --Durée Fixe
        vFixedDuration                := 0;
    end;
  end GetProductInfoFab;

--**********************************************************************************************************--
--**********************************************************************************************************--
  --Création de la proposition
  procedure CreatePropApproFab(
    aGoodID                       GCO_GOOD.GCO_GOOD_ID%type
  , aNeedDate                     date
  , aQteDemande                   number
  , aDocRecordID                  DOC_RECORD.DOC_RECORD_ID%type
  , aSupplyMode                   GCO_PRODUCT.C_SUPPLY_MODE%type
  , a_stm_stock_id_project        STM_STOCK.stm_stock_id%type
  , a_stm_location_id_project     STM_STOCK.stm_stock_id%type
  , aPpsNomenID                   PPS_NOMENCLATURE.pps_nomenclature_id%type
  , aGsmNomPath                   gal_project_supply_mode.gsm_nom_path%type default ' '
  , aTaskGoodId                   gal_project_supply_mode.gal_task_good_id%type default 0
  , aPpsNomenHeaderId             gal_project_supply_mode.pps_nomenclature_header_id%type default 0
  , aSupplyRequestId              FAL_SUPPLY_REQUEST.FAL_SUPPLY_REQUEST_ID%type
  , ResPropID                 out FAL_LOT_PROP.FAL_LOT_PROP_ID%type
  )
  is
    OutPropId            FAL_LOT_PROP.FAL_LOT_PROP_ID%type;
    --v_stm_stock_id_project stm_stock.stm_stock_id%type;
      --v_stm_location_id_project stm_stock.stm_stock_id%type;
    --aTypeProp varchar2(100);
    --aNeedID FAL_LOT_PROP.FAL_LOT_PROP_ID%type;
    aStockConsoID        STM_STOCk.STM_STOCk_ID%type;
    vDocRecordID         DOC_RECORD.DOC_RECORD_ID%type;
    aPrmCBSelectedStocks varchar2(4000);
    aCreatedSupplyID     FAL_LOT_PROP.FAL_LOT_PROP_ID%type;
  begin
      /*
      --Determine stock Affaire
      BEGIN
        select stm_stock_id into v_stm_stock_id_project
        from stm_stock where sto_description = (select PCS.PC_CONFIG.GETCONFIG('GCO_DefltSTOCK_PROJECT') from dual);
      EXCEPTION WHEN NO_DATA_FOUND THEN
        v_stm_stock_id_project := null;
      END;

    BEGIN
        select LOC.STM_LOCATION_ID into v_stm_location_id_project
        from STM_LOCATION LOC where LOC.LOC_description = (select PCS.PC_CONFIG.GETCONFIG('GCO_DefltLOCATION_PROJECT') from dual)
      and  LOC.STM_STOCK_ID  = v_stm_stock_id_project ;
      EXCEPTION WHEN NO_DATA_FOUND THEN
        v_stm_location_id_project := null;
      END;
    */

    /*
      --Info Produit
      BEGIN
      SELECT C_SUPPLY_MODE
      INTO cSupplyMode
      FROM GCO_PRODUCT
      WHERE GCO_GOOD_ID = aGoodId

    EXCEPTION WHEN NO_DATA_FOUND THEN
      cSupplyMode := null;
    END;
    */
    vDocRecordID  := aDocRecordID;
    GetProductInfoFab(aGoodID, aSupplyMode, a_stm_stock_id_project, a_stm_location_id_project, aPpsNomenID);
    -- Création proposition de fabrication
     -- produit fabriqué ou sous-traitance d'achat
      FAL_PRC_FAL_LOT_PROP.CreateFalLotProp(ioFalLotPropID           => OutPropID
                                          , ioDocRecordID            => vDocRecordID
                                          , ioStockConsoID           => aStockConsoID
                                          , ioFalNetworkSupplyId     => aCreatedSupplyID
                                          , iCSupplyMode             => aSupplyMode
                                          , icSchedulePlanCode       => cSchedulePlanCode
                                          , iDicFabConditionID       => vFabConditionID
                                          , iFalSchedulePlanID       => vSchedulePlanID
                                          , iFalSchedPlanIDFromNom   => vSchedulePlanIDFromNomen
                                          , iCTypeProp               =>  '1'   --aTypeProp --> C_PROP_TYPE 1=standard
                                          , iFalNetworkNeedID        => null
                                          , iGcoGoodID               => aGoodID
                                          , iOriginStockID           => null
                                          , iOriginLocationID        => null
                                          , iTargetStockID           => a_stm_stock_id_project
                                          , iTargetLocationID        => a_stm_location_id_project
                                          , iNeedDate                => aNeedDate
                                          , iAskedQty                => aQteDemande
                                          , iPlannedTrashQty         => 0
                                          , iCharacterizations_ID1   => null
                                          , iCharacterizations_ID2   => null
                                          , iCharacterizations_ID3   => null
                                          , iCharacterizations_ID4   => null
                                          , iCharacterizations_ID5   => null
                                          , iCharacterizations_VA1   => null
                                          , iCharacterizations_VA2   => null
                                          , iCharacterizations_VA3   => null
                                          , iCharacterizations_VA4   => null
                                          , iCharacterizations_VA5   => null
                                          , iCalculByStock           => 0
                                          , iText                    => pcs.pc_functions.translateword('Calcul des besoins sur affaire')
                                          , iSupplyRequestID         => aSupplyRequestId    --> eviter la suppression de la pof (> attention relecture doc_record_id sur DA) -----> forcer création DA -> Oui dans CBA
                                          , iIsCallByNeedCalculation => 0
                                          , iDOC_RECORD_ID           => aDocRecordID
                                           );
    if OutPropID is not null then
      ResPropID             := OutPropID;
      -- Génération des opération de proposition
      FAL_CALCUL_BESOIN.CreateAllPropOpOfGamme(iFAL_LOT_PROP_ID        => OutPropID
                                             , iFAL_SCHEDULE_PLAN_ID   => vSchedulePlanID
                                             , iQTE                    => aQteDemande
                                             , iC_SCHEDULE_PLANNING    => cSchedulePlanCode
                                              );
      GAL_FUNCTIONS.Planification_Lot_Prop(OutPropID, aNeedDate, 0, 0, 0);
      aPrmCBSelectedStocks  := null;

      for Cur in (select STM_STOCK_ID
                    from STM_STOCK
                   where C_ACCESS_METHOD = 'PUBLIC'
                     and STO_NEED_CALCULATION = 1) loop
        if aPrmCBSelectedStocks is null then
          aPrmCBSelectedStocks  := Cur.STM_STOCK_ID;
        else
          aPrmCBSelectedStocks  := aPrmCBSelectedStocks || ', ' || Cur.STM_STOCK_ID;
        end if;
      end loop;

      -- Génération proposition de fabrication
      FAL_PRC_FAL_LOT_MAT_LINK_PROP.CreateFalLotMatLinkProp(iCreatedPropID           => OutPropID
                                                          , iCBStandardLotQty        => aQteDemande
                                                          , iCBNomenclatureID        => vNomenclatureID
                                                          , iCBcSchedulePlanCode     => cSchedulePlanCode
                                                          , iCBSchedulePlanIDOfNom   => vSchedulePlanIDFromNomen
                                                          , iCBNomenclatureID2       => vNomenclatureID
                                                          , iCalculByStock           => 0
                                                          , iContext                 => 0
                                                          , iCBSelectedStocks        => aPrmCBSelectedStocks
                                                          , iCMA_FIX_DELAY           => vFixedDuration
                                                           );

      update FAL_LOT_PROP
         set LOT_CPT_CHANGE = 1
       where FAL_LOT_PROP_ID = OutPropID;

      --Maj stock affaire sur les appros (composants) à l'affaire...
      UpdateStockProjectCsant(OutPropID, aGsmNomPath, aTaskGoodId, aPpsNomenHeaderId, a_stm_stock_id_project, a_stm_location_id_project);
      FAL_NETWORK_DOC.CreateReseauApproPropApproFab(OutPropID, aCreatedSupplyID, null);
      FAL_NETWORK_DOC.CreateReseaubesoinPropApproFab(OutPropID);
    end if;
  end CreatePropApproFab;

  /**
  * procedure GetDefaultSupplier
  * Description : Fonction de recherche du supplier en cascade
  * @created ECA
  * @lastUpdate
  * @private
  */
  function GetDefaultSupplier
    return number
  is
    cursor Cur_Supplier_Partner
    is
      select   PAC_PERSON_ID
          from PAC_PERSON
             , PAC_SUPPLIER_PARTNER
         where PAC_PERSON_ID = PAC_SUPPLIER_PARTNER_ID
      order by PER_NAME;

    aPAC_SUPPLIER_PARTNER_ID number;
  begin
    select PER.PAC_PERSON_ID
      into aPAC_SUPPLIER_PARTNER_ID
      from PAC_PERSON PER
         , PAC_SUPPLIER_PARTNER SUP
     where PER.PAC_PERSON_ID = SUP.PAC_SUPPLIER_PARTNER_ID
       and PER.PER_NAME = PCS.PC_CONFIG.GetConfig('FAL_DEFAULT_PURCHASE');

    return aPAC_SUPPLIER_PARTNER_ID;
  exception
    when no_data_found then
      begin
        open Cur_Supplier_Partner;

        fetch Cur_Supplier_Partner
         into aPAC_SUPPLIER_PARTNER_ID;

        close Cur_Supplier_Partner;

        return aPAC_SUPPLIER_PARTNER_ID;
      exception
        when others then
          return null;
      end;
  end GetDefaultSupplier;
/* Appel des procedrue FAL : Liste des paramètres
--**********************************************************************************************************--
--**********************************************************************************************************--
  --Génération des opérations de la gamme
  procedure CreateAllPropOpOfGamme (
      out_error                 IN OUT VARCHAR2
  )
  IS
  BEGIN
    FAL_CALCUL_BESOIN.CreateAllPropOpOfGamme(
                            PrmFAL_LOT_PROP_ID FAL_LOT_PROP.FAL_LOT_PROP_ID%TYPE,
                            PrmFAL_SCHEDULE_PLAN_ID FAL_SCHEDULE_PLAn.FAL_SCHEDULE_PLAN_ID%TYPE,
                            PrmQTE NUMBER,
                            PrmC_SCHEDULE_PLANNING FAL_SCHEDULE_PLAN.C_SCHEDULE_PLANNING%TYPE
              );
  END CreateAllPropOpOfGamme;
*/

/*
--**********************************************************************************************************--
--**********************************************************************************************************--
  procedure Planification_Lot_Prop (
      out_error                 IN OUT VARCHAR2
  )
  IS
  BEGIN
    FAL_PLANIF.Planification_Lot_Prop(
                             PrmFAL_LOT_PROP_ID        number
                           , DatePlanification         date
                           , SelonDateDebut            integer
                           , MAJReqLiensComposantsProp integer
                           , MAJ_Reseaux_Requise       integer)
  END Planification_Lot_Prop;
*/

/*
--**********************************************************************************************************--
--**********************************************************************************************************--
  --Génération des composants
  procedure StartGphGenePropComp (
      out_error                 IN OUT VARCHAR2
  )
  IS
  BEGIN
    FAL_PRC_FAL_LOT_MAT_LINK_PROP.CreateFalLotMatLinkProp
  ( aCreatedPropID            ID_TYPE
    , aPrmCBStandardLotQty      Currency
    , aPrmCBNomenclatureID      ID_TYPE
    , aPrmCBcSchedulePlanCode   number
    , aPrmCBSchedulePlanIDOfNom ID_TYPE
    , aPrmCBNomenclatureID2     ID_TYPE
    , aPrmaCalculByStock        integer --here
    , context                   integer
    , aPrmCBSelectedStocks      varchar
    , aCMA_FIX_DELAY            integer
    )
  END StartGphGenePropComp;
*/

/*
--**********************************************************************************************************--
--**********************************************************************************************************--
  --Création réseau appro (Produit terminé)
  procedure CreateReseauApproPropApproFab (
      out_error                 IN OUT VARCHAR2
  )
  IS
  BEGIN
    FAL_NETWORK_DOC.CreateReseauApproPropApproFab(FalLotPropID TTypeID
                                                 ,aCreatedSupplyID OUT TTypeID
                               ,aTOTQteCouple NUMBER -- PRD-A051005-62536 Modif Produit couplés
  END CreateReseauApproPropApproFab;
*/

/*
--**********************************************************************************************************--
--**********************************************************************************************************--
  --Création réseau besoin (Composants de la prop)
  procedure CreateReseaubesoinPropApproFab (
      out_warning               IN OUT VARCHAR2
  )
  IS
  BEGIN
    NULL;
  END CreateReseaubesoinPropApproFab;
*/

/******************** Appel des procedrue FAL : Liste des paramètres **************************************--

  procedure Processus_CreatePropApproLog()
  IS
  BEGIN

  FAL_NEEDCALCUL_PROCESSUS.Processus_CreatePropApproLog(
    aPropID                out FAL_DOC_PROP.FAL_DOC_PROP_ID%type
  ,
    -- TcbParameters
    cSupplyMode                GCO_PRODUCT.C_SUPPLY_MODE%type
  , SupplierID                 PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  , ControlDelay               integer
  , SupplyDelay                integer
  , ConversionFactor           number
  ,
    -- Fin de TcbParameters
    aTypeProp                  varchar
  , aNeedID                    FAL_NETWORK_NEED.FAL_NETWORK_NEED_ID%type
  , aGoodID                    GCO_GOOD.GCO_GOOD_ID%type
  , aOriginStockID             STM_STOCK.STM_STOCK_ID%type
  , aOriginLocationID          STM_LOCATION.STM_LOCATION_ID%type
  , aTargetStockID             STM_STOCK.STM_STOCK_ID%type
  , aTargetLocationID          STM_LOCATION.STM_LOCATION_ID%type
  , aNeedDate                  date
  , aQteDemande                number
  , aQteRebutPlannifie         number
  , aCharacterizations_ID1     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharacterizations_ID2     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharacterizations_ID3     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharacterizations_ID4     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharacterizations_ID5     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharacterizations_VA1     FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_1%type
  , aCharacterizations_VA2     FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_2%type
  , aCharacterizations_VA3     FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_3%type
  , aCharacterizations_VA4     FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_4%type
  , aCharacterizations_VA5     FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_5%type
  , aText                      varchar
  , aPlanDirecteurId           FAL_PIC.FAL_PIC_ID%type
  , aSupplyRequestID           FAL_SUPPLY_REQUEST.FAL_SUPPLY_REQUEST_ID%type
  , bPlanifOnBeginDate         integer
  , aDOC_RECORD_ID             DOC_RECORD.DOC_RECORD_ID%Type
  , IsCallByNeedCalculation    INTEGER default 0
  , aFAL_PIC_LINE_ID           NUMBER Default null
  , aGOO_SECONDARY_REFERENCE   VARCHAR2 Default null
  , aDES_SHORT_DESCR           VARCHAR2 Default null
  );

  END;
*/

/*
  procedure CreateReseauApproPropApproLog
  is
  begin
    FAL_NETWORK_DOC.CreateReseauApproPropApproLog(FalDocPropID TTypeID
                                                , aCreatedSupplyID OUT TTypeID)
  end;
*/
end gal_pox_generate;
