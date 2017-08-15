--------------------------------------------------------
--  DDL for Package Body DOC_PRC_ESTIMATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_PRC_ESTIMATE" 
is
  /**
  * Description
  *   Initialise le numéro de devis avec le numéroteur indiqué dans la config DOC_ESTIMATE_GAUGE_NUMBERING
  */
  procedure InitEstimateNumber(iotEstimate in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lGaugeNumberingId DOC_GAUGE_NUMBERING.DOC_GAUGE_NUMBERING_ID%type
                              := FWK_I_LIB_ENTITY.getIdfromPk2('DOC_GAUGE_NUMBERING', 'GAN_DESCRIBE', PCS.PC_CONFIG.GetConfig('DOC_ESTIMATE_GAUGE_NUMBERING') );
    lEstimateNumber   DOC_ESTIMATE.DES_NUMBER%type;
  begin
    DOC_DOCUMENT_FUNCTIONS.GetDocumentNumber(null, lGaugeNumberingId, lEstimateNumber);
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimate, 'DES_NUMBER', lEstimateNumber);
  end InitEstimateNumber;

  /**
  * Description
  *   Initialise le code du devis selon la configuration objet. Initialise à 'PRP' si la configuration objet
  *   retourne null.
  */
  procedure InitEstimateCode(iotEstimate in out nocopy fwk_i_typ_definition.t_crud_def)
  is
  begin
    FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimate, 'C_DOC_ESTIMATE_CODE', nvl(PCS.PC_I_LIB_SESSION.GetObjectParam('MODE'), 'PRP') );
  end InitEstimateCode;

  /**
  * Description
  *   Initialise les données découlant du tiers n'ayant pas été déjà données
  */
  procedure InitCustomerData(iotEstimate in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lCustomerId PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimate, 'PAC_CUSTOM_PARTNER_ID');
  begin
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimate, 'PC_LANG_ID') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimate, 'PC_LANG_ID', PAC_EVENT_MANAGEMENT.GetCascadeLangId(null, lCustomerId) );
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsNull(iotEstimate, 'ACS_FINANCIAL_CURRENCY_ID') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotEstimate
                                    , 'ACS_FINANCIAL_CURRENCY_ID'
                                    , DOC_DOCUMENT_FUNCTIONS.GetAdminDomainCurrencyId(DOC_LIB_DOCUMENT.cAdminDomainSale, lCustomerId)
                                     );
    end if;
  end InitCustomerData;

  /**
  * Description
  *   Supprime les données enfant de DOC_ESTIMATE
  */
  procedure DeleteEstimateChildren(iotEstimate in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lEstimateId DOC_ESTIMATE.DOC_ESTIMATE_ID%type   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotEstimate, 'DOC_ESTIMATE_ID');
  begin
    -- Effacer les positions liées au devis
    FWK_I_MGT_ENTITY.DeleteChildren(iv_child_name => 'DOC_ESTIMATE_POS', iv_parent_key_name => 'DOC_ESTIMATE_ID', iv_parent_key_value => lEstimateId);
    -- Effacer les éléments couts liés au devis
    FWK_I_MGT_ENTITY.DeleteChildren(iv_child_name => 'DOC_ESTIMATE_ELEMENT_COST', iv_parent_key_name => 'DOC_ESTIMATE_ID', iv_parent_key_value => lEstimateId);
  end DeleteEstimateChildren;

  /**
  * procedure GenerateOffer
  * Description
  *   Création de l'offre liée au devis
  */
  procedure GenerateOffer(iEstimateID in DOC_ESTIMATE.DOC_ESTIMATE_ID%type, oDocumentID out DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    lnDOC_ID     DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    lnPOS_ID     DOC_POSITION.DOC_POSITION_ID%type;
    lnGaugeID    DOC_GAUGE.DOC_GAUGE_ID%type;
    lnOption     DOC_ESTIMATE_POS.DEP_OPTION%type    default 0;
    lnPosCount   integer                             default 0;
    lvCreateMode varchar2(10);
    lMessage     varchar2(4000);
  begin
    lnDOC_ID      := null;
    lvCreateMode  := '126';

    -- Recherche le gabarit du document à créer qui est spécifié sur le devis
    select DOC_GAUGE_OFFER_ID
      into lnGaugeID
      from DOC_ESTIMATE
     where DOC_ESTIMATE_ID = iEstimateID;

    -- Création du document si gabarit renseigné
    if lnGaugeID is not null then
      -- Effacer les données de la variable
      DOC_DOCUMENT_GENERATE.ResetDocumentInfo(DOC_DOCUMENT_INITIALIZE.DocumentInfo);
      -- La variable ne doit pas être réinitialisée dans la méthode de création
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.CLEAR_DOCUMENT_INFO  := 0;
      -- Monnaie du document
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_ESTIMATE_ID      := iEstimateID;

      if PCS.PC_CONFIG.GetConfig('DOC_ESTIMATE_CREATE_GOOD') = '1' then
        -- création des articles à partir du devis (produit fini et composants), nomenclature et gammes opératoires
        GenerateProducts(iEstimateID, lMessage);

        if lMessage is not null then
          fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                            , iv_message       => lMessage
                                            , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                            , iv_cause         => 'GenerateProducts'
                                             );
        end if;
      end if;

      -- Création de l'offre ou commande
      DOC_DOCUMENT_GENERATE.GenerateDocument(aNewDocumentID => lnDOC_ID, aGaugeID => lnGaugeID, aMode => lvCreateMode);

      -- Liste des positions de devis à créer
      for ltplPos in (select   DEP.DOC_ESTIMATE_POS_ID
                             , DEP.DEP_DELIVERY_DATE
                             , DEP.DEP_OPTION
                             , DEP.GCO_GOOD_ID
                          from DOC_ESTIMATE_POS DEP
                             , DOC_ESTIMATE_ELEMENT_COST dec
                         where DEP.DOC_ESTIMATE_ID = iEstimateID
                           and DEP.DOC_ESTIMATE_POS_ID = dec.DOC_ESTIMATE_POS_ID
                      order by nvl(DEP.DEP_OPTION, 0) asc
                             , DEP.DEP_NUMBER) loop
        -- Positions "Option" = oui
        -- Une position de type recap est crée lorsqu'il y a eu au moins une position
        -- non option et lorsque l'ont bascule de Option = non à Option = oui
        if (ltplPos.DEP_OPTION <> lnOption) then
          lnOption  := ltplPos.DEP_OPTION;

          -- Création d'une ligne de récap pour les positions "Option" = non
          if lnPosCount > 0 then
            lnPOS_ID  := null;
            DOC_POSITION_GENERATE.GeneratePosition(aPositionID      => lnPOS_ID
                                                 , aDocumentID      => lnDOC_ID
                                                 , aPosCreateMode   => lvCreateMode
                                                 , aTypePos         => '6'
                                                 , aPosBodyText     => PCS.PC_FUNCTIONS.TranslateWord('Total des positions')
                                                  );
          end if;
        end if;

        lnPOS_ID    := null;
        DOC_POSITION_GENERATE.GeneratePosition(aPositionID      => lnPOS_ID
                                             , aDocumentID      => lnDOC_ID
                                             , aPosCreateMode   => lvCreateMode
                                             , aTypePos         => '1'
                                             , aSrcPositionID   => ltplPos.DOC_ESTIMATE_POS_ID
                                             , aBasisDelay      => ltplPos.DEP_DELIVERY_DATE
                                              );
        -- Nbr de positions crées
        lnPosCount  := lnPosCount + 1;
      end loop;

      -- S'il y a des options, générer une position recap des options
      if (lnOption = 1) then
        lnPOS_ID  := null;
        DOC_POSITION_GENERATE.GeneratePosition(aPositionID      => lnPOS_ID
                                             , aDocumentID      => lnDOC_ID
                                             , aPosCreateMode   => lvCreateMode
                                             , aTypePos         => '6'
                                             , aPosBodyText     => PCS.PC_FUNCTIONS.TranslateWord('Total des options')
                                              );
      end if;

      DOC_FINALIZE.FinalizeDocument(aDocumentId => lnDOC_ID);
      oDocumentID                                               := lnDOC_ID;
      --Mise à jour du status du devis
      UpdateStatus(iEstimateId, '04');
    else
      RA(PCS.PC_FUNCTIONS.TranslateWord('Le gabarit "Offre client" n''est pas défini sur le devis !') );
    end if;
  end GenerateOffer;

  /**
  * procedure GenerateOrder
  * Description
  *   Création de la commande liée au devis
  */
  procedure GenerateOrder(iEstimateID in DOC_ESTIMATE.DOC_ESTIMATE_ID%type, oDocumentID out DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    lnDOC_ID     DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    lnPOS_ID     DOC_POSITION.DOC_POSITION_ID%type;
    lnGaugeID    DOC_GAUGE.DOC_GAUGE_ID%type;
    lvCreateMode varchar2(10);
    lMessage     varchar2(4000);
  begin
    lnDOC_ID      := null;
    lvCreateMode  := '127';

    -- Recherche le gabarit du document à créer qui est spécifié sur le devis
    select DOC_GAUGE_ORDER_ID
      into lnGaugeID
      from DOC_ESTIMATE
     where DOC_ESTIMATE_ID = iEstimateID;

    -- Création du document si gabarit renseigné
    if lnGaugeID is not null then
      -- Effacer les données de la variable
      DOC_DOCUMENT_GENERATE.ResetDocumentInfo(DOC_DOCUMENT_INITIALIZE.DocumentInfo);
      -- La variable ne doit pas être réinitialisée dans la méthode de création
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.CLEAR_DOCUMENT_INFO  := 0;
      -- Monnaie du document
      DOC_DOCUMENT_INITIALIZE.DocumentInfo.DOC_ESTIMATE_ID      := iEstimateID;

      if PCS.PC_CONFIG.GetConfig('DOC_ESTIMATE_CREATE_GOOD') = '3' then
        -- création des articles à partir du devis (produit fini et composants), nomenclature et gammes opératoires
        GenerateProducts(iEstimateID, lMessage);

        if lMessage is not null then
          fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                            , iv_message       => lMessage
                                            , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                            , iv_cause         => 'GenerateProducts'
                                             );
        end if;
      end if;

      -- Création de l'offre ou commande
      DOC_DOCUMENT_GENERATE.GenerateDocument(aNewDocumentID => lnDOC_ID, aGaugeID => lnGaugeID, aMode => lvCreateMode);

      -- Liste des positions de devis à créer
      for ltplPos in (select   DEP.DOC_ESTIMATE_POS_ID
                             , DEP.DEP_DELIVERY_DATE
                             , DEP.DEP_OPTION
                          from DOC_ESTIMATE_POS DEP
                             , DOC_ESTIMATE_ELEMENT_COST dec
                         where DEP.DOC_ESTIMATE_ID = iEstimateID
                           and DEP.DOC_ESTIMATE_POS_ID = dec.DOC_ESTIMATE_POS_ID
                           and nvl(DEP.DEP_OPTION, 0) = 0
                      order by DEP.DEP_NUMBER) loop
        lnPOS_ID  := null;
        DOC_POSITION_GENERATE.GeneratePosition(aPositionID      => lnPOS_ID
                                             , aDocumentID      => lnDOC_ID
                                             , aPosCreateMode   => lvCreateMode
                                             , aTypePos         => '1'
                                             , aSrcPositionID   => ltplPos.DOC_ESTIMATE_POS_ID
                                             , aBasisDelay      => ltplPos.DEP_DELIVERY_DATE
                                              );
      end loop;

      DOC_FINALIZE.FinalizeDocument(aDocumentId => lnDOC_ID);
      oDocumentID                                               := lnDOC_ID;
      --Mise à jour du status du devis
      UpdateStatus(iEstimateId, '05');
    else
      RA(PCS.PC_FUNCTIONS.TranslateWord('Le gabarit "Commande client" n''est pas défini sur le devis !') );
    end if;
  end GenerateOrder;

  /**
  * procedure GenerateProducts
  * Description
  *   Création des produits du devis
  */
  procedure GenerateProducts(iEstimateID in DOC_ESTIMATE.DOC_ESTIMATE_ID%type, oError out varchar2)
  is
    ltPos  FWK_I_TYP_DEFINITION.t_crud_def;
    ltComp FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    oError  := null;

    -- Balayer tous les produits à créer
    -- On créé d'abord tous les produits des composants et ensuite ceux des positions
    --   pour que l'on puisse générer les nomenclatures correctement
    for lptlGood in (select   VPOS.DOC_ESTIMATE_POS_ID
                            , VPOS.C_DOC_ESTIMATE_CREATE_MODE
                            , null DOC_ESTIMATE_COMP_ID
                            , VPOS.GCO_GOOD_ID
                            , VPOS.C_MANAGEMENT_MODE
                            , VPOS.DEP_REFERENCE MAJOR_REFERENCE
                            , VPOS.DEP_SECONDARY_REFERENCE SECONDARY_REFERENCE
                            , substrb(VPOS.DEP_SHORT_DESCRIPTION, 1, 30) SHORT_DESCRIPTION
                            , VPOS.DEP_LONG_DESCRIPTION LONG_DESCRIPTION
                            , VPOS.DEP_FREE_DESCRIPTION FREE_DESCRIPTION
                            , VPOS.STM_STOCK_ID
                            , VPOS.STM_LOCATION_ID
                            , VPOS.C_SUPPLY_MODE
                            , VPOS.C_SUPPLY_TYPE
                            , VPOS.DIC_UNIT_OF_MEASURE_ID
                            , VPOS.GCO_GOOD_CATEGORY_ID
                            , VPOS.DEC_COST_PRICE
                            , VPOS.DEC_SALE_PRICE
                            , 1 ORDER_FIELD
                         from EV_DOC_ESTIMATE_POS VPOS
                        where VPOS.DOC_ESTIMATE_ID = iEstimateID
                          and VPOS.C_DOC_ESTIMATE_CREATE_MODE in('01', '02')
                          and VPOS.DEP_OPTION = 0
                     union
                     select   VCOMP.DOC_ESTIMATE_POS_ID
                            , VCOMP.C_DOC_ESTIMATE_CREATE_MODE
                            , VCOMP.DOC_ESTIMATE_COMP_ID
                            , VCOMP.GCO_GOOD_ID
                            , VCOMP.C_MANAGEMENT_MODE
                            , VCOMP.ECP_REFERENCE MAJOR_REFERENCE
                            , VCOMP.ECP_SECONDARY_REFERENCE SECONDARY_REFERENCE
                            , VCOMP.ECP_SHORT_DESCRIPTION SHORT_DESCRIPTION
                            , VCOMP.ECP_LONG_DESCRIPTION LONG_DESCRIPTION
                            , VCOMP.ECP_FREE_DESCRIPTION FREE_DESCRIPTION
                            , VCOMP.STM_STOCK_ID
                            , VCOMP.STM_LOCATION_ID
                            , VCOMP.C_SUPPLY_MODE
                            , VCOMP.C_SUPPLY_TYPE
                            , VCOMP.DIC_UNIT_OF_MEASURE_ID
                            , VCOMP.GCO_GOOD_CATEGORY_ID
                            , VCOMP.DEC_COST_PRICE
                            , VCOMP.DEC_SALE_PRICE
                            , 0 ORDER_FIELD
                         from EV_DOC_ESTIMATE_COMP VCOMP
                            , EV_DOC_ESTIMATE_POS VPOS
                        where VPOS.DOC_ESTIMATE_ID = iEstimateID
                          and VCOMP.DOC_ESTIMATE_POS_ID = VPOS.DOC_ESTIMATE_POS_ID
                          and VPOS.DEP_OPTION = 0
                          and VCOMP.C_DOC_ESTIMATE_CREATE_MODE in('01', '02')
                     order by ORDER_FIELD asc) loop
      declare
        lnFixedCostPriceID PTC_FIXED_COSTPRICE.PTC_FIXED_COSTPRICE_ID%type;
        lnTariffID         PTC_TARIFF.PTC_TARIFF_ID%type;
        lnGoodID           GCO_GOOD.GCO_GOOD_ID%type;
        lvRef              GCO_GOOD.GOO_MAJOR_REFERENCE%type;
        lvNewRef           GCO_GOOD.GOO_MAJOR_REFERENCE%type;
        lnNomenclatureID   PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type;
        lnSchedulePlanId   FAL_SCHEDULE_PLAN.FAL_SCHEDULE_PLAN_ID%type;
        lnCdaManufID       GCO_COMPL_DATA_MANUFACTURE.GCO_COMPL_DATA_MANUFACTURE_ID%type;
      begin
        if lptlGood.GCO_GOOD_ID is not null then
          select GOO_MAJOR_REFERENCE
            into lvRef
            from GCO_GOOD
           where GCO_GOOD_ID = lptlGood.GCO_GOOD_ID;
        elsif lptlGood.MAJOR_REFERENCE is not null then
          select nvl(max(GCO_GOOD_ID), 0)
            into lnGoodID
            from GCO_GOOD
           where GOO_MAJOR_REFERENCE = lptlGood.MAJOR_REFERENCE;

          if lnGoodId > 0 then
            lvRef  := lptlGood.MAJOR_REFERENCE;
          end if;
        end if;

        -- Création du produit
        if lptlGood.C_DOC_ESTIMATE_CREATE_MODE = '01' then
          -- position devis ET position composant
          if    lvRef is null
             or (lvRef <> lptlGood.MAJOR_REFERENCE) then
            lnGoodId  :=
              GCO_I_PRC_GOOD.CreateProduct(lptlGood.MAJOR_REFERENCE
                                         , lptlGood.SECONDARY_REFERENCE
                                         , lptlGood.SHORT_DESCRIPTION
                                         , lptlGood.LONG_DESCRIPTION
                                         , lptlGood.FREE_DESCRIPTION
                                         , '2'   -- actif
                                         , lptlGood.DIC_UNIT_OF_MEASURE_ID
                                         , lptlGood.GCO_GOOD_CATEGORY_ID
                                         , lptlGood.C_MANAGEMENT_MODE
                                         , 0   -- nombre de décimales
                                         , lptlGood.C_SUPPLY_MODE
                                         , lptlGood.C_SUPPLY_TYPE
                                         , lptlGood.STM_STOCK_ID
                                         , lptlGood.STM_LOCATION_ID
                                          );

            -- Mode de gestion = Prix de revient fixe
            if lptlGood.C_MANAGEMENT_MODE = '3' then
              PTC_PRC_PRICE.createFIXED_COST_PRICE(ionPTC_FIXED_COSTPRICE_ID        => lnFixedCostPriceID
                                                 , inGCO_GOOD_ID                    => lnGoodId
                                                 , ivDIC_FIXED_COSTPRICE_DESCR_ID   => PCS.PC_CONFIG.GetConfig('PTC_DEFAULT_FIXED_COSTPRICE')
                                                 , ivCPR_DESCR                      => PCS.PC_FUNCTIONS.TranslateWord('Devis - Génération automatique')
                                                 , inCPR_PRICE                      => lptlGood.DEC_COST_PRICE
                                                 , ivC_COSTPRICE_STATUS             => 'ACT'
                                                 , inCPR_DEFAULT                    => 1
                                                  );
            end if;

            -- Création d'un tarif de vente
            PTC_I_PRC_PRICE.createSaleTariff(ionPTC_TARIFF_ID   => lnTariffID
                                           , inGCO_GOOD_ID      => lnGoodId
                                           , inDIC_TARIFF_ID    => PCS.PC_CONFIG.GetConfig('DOC_ESTIMATE_DIC_TARIFF')
                                           , inTRF_DESCR        => PCS.PC_FUNCTIONS.TranslateWord('Créé par la gestion des devis')
                                           , inC_ROUND_TYPE     => '0'
                                           , inUniquePrice      => lptlGood.DEC_SALE_PRICE
                                            );
          end if;
        else
          -- copie du produit

          -- position devis ET position composant
          if    lvRef is null
             or (lvRef <> lptlGood.MAJOR_REFERENCE) then
            GCO_PRC_GOOD.DuplicateProduct(iSourceGoodID       => lptlGood.GCO_GOOD_ID
                                        , iNewGoodID          => lnGoodId
                                        , iNewMajorRef        => lptlGood.MAJOR_REFERENCE
                                        , iNewSecRef          => lptlGood.SECONDARY_REFERENCE
                                        , iNewShortDescr      => lptlGood.SHORT_DESCRIPTION
                                        , iNewLongDescr       => lptlGood.LONG_DESCRIPTION
                                        , iNewFreeDescr       => lptlGood.FREE_DESCRIPTION
                                        , iDuplManufacture    => 0
                                        , iDuplNomenclature   => 0
                                         );
            GCO_GOOD_NUMBERING_FUNCTIONS.GetNumber(lnGoodId, 'GCO_GOOD_CATEGORY', lvNewRef);

            if lvNewRef is null then
              lvNewRef  := lptlGood.MAJOR_REFERENCE;
            end if;

            GCO_I_PRC_GOOD.UpdateProduct(lnGoodId
                                       , lvNewRef
                                       , lptlGood.SECONDARY_REFERENCE
                                       , lptlGood.SHORT_DESCRIPTION
                                       , lptlGood.LONG_DESCRIPTION
                                       , lptlGood.FREE_DESCRIPTION
                                       , GCO_I_LIB_CONSTANT.gcGoodStatusActive
                                       , lptlGood.DIC_UNIT_OF_MEASURE_ID
                                       , lptlGood.GCO_GOOD_CATEGORY_ID
                                       , lptlGood.C_MANAGEMENT_MODE
                                       , lptlGood.C_SUPPLY_MODE
                                       , lptlGood.C_SUPPLY_TYPE
                                       , lptlGood.STM_STOCK_ID
                                       , lptlGood.STM_LOCATION_ID
                                        );

            -- Mode de gestion = Prix de revient fixe
            if lptlGood.C_MANAGEMENT_MODE = '3' then
              PTC_PRC_PRICE.createFIXED_COST_PRICE(ionPTC_FIXED_COSTPRICE_ID        => lnFixedCostPriceID
                                                 , inGCO_GOOD_ID                    => lnGoodId
                                                 , ivDIC_FIXED_COSTPRICE_DESCR_ID   => PCS.PC_CONFIG.GetConfig('PTC_DEFAULT_FIXED_COSTPRICE')
                                                 , ivCPR_DESCR                      => PCS.PC_FUNCTIONS.TranslateWord('Devis - Génération automatique')
                                                 , inCPR_PRICE                      => lptlGood.DEC_COST_PRICE
                                                 , ivC_COSTPRICE_STATUS             => 'ACT'
                                                 , inCPR_DEFAULT                    => 1
                                                  );
            end if;

            -- Création d'un tarif de vente
            PTC_I_PRC_PRICE.createSaleTariff(ionPTC_TARIFF_ID   => lnTariffID
                                           , inGCO_GOOD_ID      => lnGoodId
                                           , inDIC_TARIFF_ID    => PCS.PC_CONFIG.GetConfig('DOC_ESTIMATE_DIC_TARIFF')
                                           , inTRF_DESCR        => PCS.PC_FUNCTIONS.TranslateWord('Créé par la gestion des devis')
                                           , inC_ROUND_TYPE     => '0'
                                           , inUniquePrice      => lptlGood.DEC_SALE_PRICE
                                            );
          end if;
        end if;

        -- Effectue la mise à jour de la nouvelle référence du nouveau produit
        if lnGoodId is not null then
          select GOO_MAJOR_REFERENCE
            into lvRef
            from GCO_GOOD
           where GCO_GOOD_ID = lnGoodId;

          if lptlGood.DOC_ESTIMATE_COMP_ID is not null then
            --Traitement du composant
            FWK_I_MGT_ENTITY.new(FWK_I_TYP_DOC_ENTITY.gcDocEstimateComp, ltComp, false);
            ltComp.attribute_list('GENERATE_PRODUCT')  := '1';
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'DOC_ESTIMATE_COMP_ID', lptlGood.DOC_ESTIMATE_COMP_ID);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'GCO_NEW_GOOD_ID', lnGoodId);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'ECP_REFERENCE', lvRef);
            FWK_I_MGT_ENTITY.UpdateEntity(ltComp);
            FWK_I_MGT_ENTITY.Release(ltComp);
          else
            -- Traitement de la position
            FWK_I_MGT_ENTITY.new(FWK_I_TYP_DOC_ENTITY.gcDocEstimatePos, ltPos, false);
            ltPos.attribute_list('GENERATE_PRODUCT')  := '1';
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltPos, 'DOC_ESTIMATE_POS_ID', lptlGood.DOC_ESTIMATE_POS_ID);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltPos, 'GCO_NEW_GOOD_ID', lnGoodId);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltPos, 'DEP_REFERENCE', lvRef);
            FWK_I_MGT_ENTITY.UpdateEntity(ltPos);
            FWK_I_MGT_ENTITY.Release(ltPos);
          end if;
        end if;

        -- La création de la nomenclature se fait uniquement pour les biens des positions
        --   pas pour les composants
        if     (lnGoodID is not null)
           and (lptlGood.DOC_ESTIMATE_COMP_ID is null) then
          -- Création de la nomenclature
          lnNomenclatureID  := GenerateNomenclature(iEstimatePosID => lptlGood.DOC_ESTIMATE_POS_ID, iGoodID => lnGoodId);
          -- Création de la gamme opératoire
          lnSchedulePlanId  := GenerateSchedulePlan(iEstimatePosID => lptlGood.DOC_ESTIMATE_POS_ID);

          -- Création de la donnée compl. de fabrication sur le produit avec la gamme opératoire
          if (lnSchedulePlanId is not null) then
            lnCdaManufID  := GCO_PRC_CDA_MANUFACTURE.CreateCdaManufacture(iGoodID => lnGoodID, iSchedulePlanID => lnSchedulePlanId);
          end if;
        end if;
      end;
    end loop;
  exception
    when others then
      oError  := sqlerrm || co.cLineBreak || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
  end GenerateProducts;

  /**
  * Description
  *    Création des nomenclature des produits du devis
  */
  function GenerateNomenclature(iEstimatePosID in DOC_ESTIMATE_POS.DOC_ESTIMATE_POS_ID%type, iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    lnNomenclatureID PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type;
    lnNomBondId      PPS_NOM_BOND.PPS_NOM_BOND_ID%type           := null;
    lnGoodId         PPS_NOMENCLATURE.GCO_GOOD_ID%type;
    lnPosRefQty      EV_DOC_ESTIMATE_POS.DEC_REF_QTY%type;
  begin
    if PPS_I_LIB_FUNCTIONS.GetDefaultNomenclature(iGoodId => iGoodId, iTypNom => '2') is null then
      -- Récupération de la quantité de référence de la position pour utiliser comme qté réf. de la nomenclature
      select DEC_REF_QTY
        into lnPosRefQty
        from EV_DOC_ESTIMATE_POS
       where DOC_ESTIMATE_POS_ID = iEstimatePosID;

      if lnPosRefQty = 0 then
        lnPosRefQty  := 1;
      end if;

      -- Création de la nomenclature
      lnNomenclatureID  := PPS_I_PRC_NOMENCLATURE.CreateNomenclature(iGoodID => iGoodID, iTypeNom => '2', iRefQty => lnPosRefQty);

      -- Ajout des composants
      for lptlNomBond in (select   GOO.GCO_GOOD_ID
                                 , (ECP.DEC_QUANTITY / lnPosRefQty) as COM_UTIL_COEFF
                                 , ECP.DED_NUMBER
                              from EV_DOC_ESTIMATE_COMP ECP
                                 , GCO_GOOD GOO
                             where ECP.DOC_ESTIMATE_POS_ID = iEstimatePosID
                               and ECP.ECP_REFERENCE = GOO.GOO_MAJOR_REFERENCE
                          order by ECP.DED_NUMBER) loop
        lnNomBondId  :=
          PPS_I_PRC_NOMENCLATURE.CreateNomBond(iNomenclatureID   => lnNomenclatureID
                                             , iGoodID           => lptlNomBond.GCO_GOOD_ID
                                             , iUtilCoeff        => lptlNomBond.COM_UTIL_COEFF
                                              );
      end loop;
    end if;

    return lnNomenclatureID;
  end GenerateNomenclature;

  /**
  * Description
  *    Création des gammes opératoires
  */
  function GenerateSchedulePlan(iEstimatePosID in DOC_ESTIMATE_POS.DOC_ESTIMATE_POS_ID%type)
    return number
  is
    lnSchedulePlanId  FAL_SCHEDULE_PLAN.FAL_SCHEDULE_PLAN_ID%type     := null;
    lnFalListStepLink FAL_LIST_STEP_LINK.FAL_LIST_STEP_LINK_ID%type;
    lnGoodID          GCO_GOOD.GCO_GOOD_ID%type;
  begin
    for lptlSchedulePlan in (select   VPOS.DOC_ESTIMATE_ELEMENT_ID
                                    , VPOS.DOC_ESTIMATE_POS_ID
                                    , VPOS.C_SCHEDULE_PLANNING
                                    , VPOS.DEP_REFERENCE
                                    , VPOS.DEP_SHORT_DESCRIPTION
                                    , VPOS.DEP_LONG_DESCRIPTION
                                    , VPOS.C_DOC_ESTIMATE_CREATE_MODE
                                 from EV_DOC_ESTIMATE_POS VPOS
                                where VPOS.DOC_ESTIMATE_POS_ID = iEstimatePosID
                                  and VPOS.C_DOC_ESTIMATE_CREATE_MODE in('01', '02')
                                  and VPOS.DEP_OPTION = 0
                                  and exists(   -- il existe des opérations à créer
                                             select VTASK.DOC_ESTIMATE_ELEMENT_ID
                                               from EV_DOC_ESTIMATE_TASK VTASK
                                              where VTASK.DOC_ESTIMATE_POS_ID = VPOS.DOC_ESTIMATE_POS_ID)
                             order by VPOS.DEP_NUMBER) loop
      lnSchedulePlanId  :=
                  FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name   => 'FAL_SCHEDULE_PLAN', iv_column_name => 'SCH_REF'
                                              , iv_value         => lptlSchedulePlan.DEP_REFERENCE);
      lnGoodID          :=
               FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name   => 'GCO_GOOD', iv_column_name => 'GOO_MAJOR_REFERENCE'
                                           , iv_value         => lptlSchedulePlan.DEP_REFERENCE);

      if lnSchedulePlanId is null then
        -- Création de l'opération de fabrication
        --
        lnSchedulePlanId  :=
          FAL_I_PRC_SCHEDULE_PLAN.CreateSchedulePlan(lptlSchedulePlan.C_SCHEDULE_PLANNING
                                                   , lptlSchedulePlan.DEP_REFERENCE
                                                   , lptlSchedulePlan.DEP_SHORT_DESCRIPTION
                                                   , lptlSchedulePlan.DEP_LONG_DESCRIPTION
                                                    );

        for lptlListStepLink in (select   TSK.DOC_ESTIMATE_ELEMENT_ID
                                        , TAS.FAL_TASK_ID
                                        , TAS.C_TASK_TYPE
                                        , DTK_ADJUSTING_TIME
                                        , DTK_QTY_FIX_ADJUSTING
                                        , DTK_WORK_TIME
                                        , DTK_QTY_REF_WORK
                                        , DTK_AMOUNT
                                        , DTK_QTY_REF_AMOUNT
                                        , DTK_DIVISOR_AMOUNT
                                     from EV_DOC_ESTIMATE_TASK TSK
                                        , FAL_TASK TAS
                                    where TSK.DOC_ESTIMATE_POS_ID = lptlSchedulePlan.DOC_ESTIMATE_POS_ID
                                      and TSK.FAL_TASK_ID = TAS.FAL_TASK_ID
                                 order by TSK.DED_NUMBER) loop
          lnFalListStepLink  :=
            FAL_I_PRC_SCHEDULE_PLAN.CreateListStepLink(lnSchedulePlanId
                                                     , lptlListStepLink.FAL_TASK_ID
                                                     , lptlListStepLink.C_TASK_TYPE
                                                     , lptlListStepLink.DTK_ADJUSTING_TIME
                                                     , lptlListStepLink.DTK_QTY_FIX_ADJUSTING
                                                     , lptlListStepLink.DTK_WORK_TIME
                                                     , lptlListStepLink.DTK_QTY_REF_WORK
                                                     , lptlListStepLink.DTK_AMOUNT
                                                     , lptlListStepLink.DTK_QTY_REF_AMOUNT
                                                     , lptlListStepLink.DTK_DIVISOR_AMOUNT
                                                      );

          if lnFalListStepLink is not null then
            -- Màj du lien de la tâche
            UpdateListStepLinkID(iEstimateTaskID => lptlListStepLink.DOC_ESTIMATE_ELEMENT_ID, iListStepLinkID => lnFalListStepLink);
          end if;
        end loop;
      end if;
    end loop;

    return lnSchedulePlanId;
  end GenerateSchedulePlan;

   /**
  * procedure GenerateProject
  * Description
  *   Création d'une affaire GAL_PROJECT selon un devis
  * @created AGA
  * @lastUpdate
  * @public
  * @param iEstimateID : ID du devis
  */
  procedure GenerateProject(iEstimateID in DOC_ESTIMATE.DOC_ESTIMATE_ID%type, oProjectID out GAL_PROJECT.GAL_PROJECT_ID%type, oError out varchar2)
  is
    lGAL_TASK_GOOD_ID   GAL_TASK_GOOD.GAL_TASK_GOOD_ID%type;
    lGAL_TASK_ID        GAL_TASK.GAL_TASK_ID%type;
    lnDF_GAL_TASK_ID    GAL_TASK.GAL_TASK_ID%type;
    lGAL_TASK_LINK_ID   GAL_TASK_LINK.GAL_TASK_LINK_ID%type;
    lGAL_TASK_LOT_ID    GAL_TASK_LOT.GAL_TASK_LOT_ID%type;
    lGAL_BUDGET_LINE_ID GAL_BUDGET_LINE.GAL_BUDGET_LINE_ID%type;
    lnGoodId            DOC_ESTIMATE_POS.GCO_GOOD_ID%type;
    lMessage            varchar2(4000);
  begin
    oError      := null;
    oProjectId  := null;

    -- Position du devis type A :
    --   Mode de création du bien : 00 (sans création)
    --   Bien défini sur la position de devis
    --   Composants : Non
    --   Opérations : Non
    for lptlEstimatePos in (select   VPOS.GAL_TASK_ID
                                   , VPOS.GCO_GOOD_ID
                                   , VPOS.DEP_SHORT_DESCRIPTION
                                   , VPOS.DEP_COMMENT
                                   , VPOS.DEC_QUANTITY
                                   , VPOS.DEC_COST_PRICE
                                   , NOM.PPS_NOMENCLATURE_ID
                                   , GCA.GAL_COST_CENTER_ID
                                   , TAS.GAL_BUDGET_ID
                                   , TAS.GAL_PROJECT_ID
                                from EV_DOC_ESTIMATE_POS VPOS
                                   , PPS_NOMENCLATURE NOM
                                   , GCO_GOOD GOO
                                   , GCO_GOOD_CATEGORY GCA
                                   , GAL_TASK TAS
                               where VPOS.DOC_ESTIMATE_ID = iEstimateID
                                 and VPOS.C_DOC_ESTIMATE_CREATE_MODE = '00'
                                 and VPOS.DEP_OPTION = 0
                                 and GOO.GOO_MAJOR_REFERENCE <> PCS.PC_CONFIG.GetConfig('DOC_ESTIMATE_GOOD')
                                 and VPOS.GAL_TASK_ID is not null
                                 and GOO.GCO_GOOD_ID = VPOS.GCO_GOOD_ID
                                 and GCA.GCO_GOOD_CATEGORY_ID = GOO.GCO_GOOD_CATEGORY_ID
                                 and TAS.GAL_TASK_ID = VPOS.GAL_TASK_ID
                                 and VPOS.PPS_NOMENCLATURE_ID = NOM.PPS_NOMENCLATURE_ID(+)
                            order by VPOS.DEP_NUMBER) loop
      if oProjectid is null then
        oProjectID  := lptlEstimatePos.GAL_PROJECT_ID;
      end if;

      -- Création d'une tâche d'appro avec le bien + nomenclature
      lGAL_TASK_GOOD_ID  :=
        GAL_I_PRC_PROJECT.CreateTASK_GOOD(iGAL_TASK_ID           => lptlEstimatePos.GAL_TASK_ID
                                        , iGCO_GOOD_ID           => lptlEstimatePos.GCO_GOOD_ID
                                        , iPPS_NOMENCLATURE_ID   => lptlEstimatePos.PPS_NOMENCLATURE_ID
                                        , iGML_QUANTITY          => lptlEstimatePos.DEC_QUANTITY
                                        , iGML_DESCRIPTION       => lptlEstimatePos.DEP_SHORT_DESCRIPTION
                                        , iGML_COMMENT           => lptlEstimatePos.DEP_COMMENT
                                         );

      if     lptlEstimatePos.GAL_BUDGET_ID is not null
         and lptlEstimatePos.GAL_COST_CENTER_ID is not null then
        -- ajout ligne de budget
        lGAL_BUDGET_LINE_ID  :=
          GAL_I_PRC_PROJECT.CreateOrUpdateBUDGET_LINE(lptlEstimatePos.GAL_BUDGET_ID
                                                    , lptlEstimatePos.GAL_COST_CENTER_ID
                                                    , lptlEstimatePos.DEC_QUANTITY
                                                    , lptlEstimatePos.DEC_COST_PRICE
                                                     );
      end if;
    end loop;

    -- Position du devis type B :
    --   Mode de création du bien : 01 (Création) ou 02 (Création par copie)
    --   Bien défini sur la position de devis
    --   Composants : Oui
    --   Opérations : Oui
    for lptlEstimatePos in (select   VPOS.GAL_TASK_ID
                                   , VPOS.GCO_GOOD_ID
                                   , VPOS.DEP_REFERENCE
                                   , VPOS.DEP_SHORT_DESCRIPTION
                                   , VPOS.DEP_COMMENT
                                   , VPOS.DEC_QUANTITY
                                   , VPOS.DEC_COST_PRICE
                                   , VPOS.DOC_ESTIMATE_POS_ID
                                   , VPOS.DEP_DELIVERY_DATE
                                   , TAS.GAL_PROJECT_ID
                                   , TAS.GAL_BUDGET_ID
                                   , GCA.GAL_COST_CENTER_ID
                                from EV_DOC_ESTIMATE_POS VPOS
                                   , GCO_GOOD GOO
                                   , GCO_GOOD_CATEGORY GCA
                                   , GAL_TASK TAS
                               where VPOS.DOC_ESTIMATE_ID = iEstimateID
                                 and VPOS.C_DOC_ESTIMATE_CREATE_MODE <> '00'
                                 and VPOS.DEP_OPTION = 0
                                 and VPOS.GCO_GOOD_ID is not null
                                 and VPOS.GAL_TASK_ID is not null
                                 and GOO.GCO_GOOD_ID = VPOS.GCO_GOOD_ID
                                 and GCA.GCO_GOOD_CATEGORY_ID = GOO.GCO_GOOD_CATEGORY_ID
                                 and TAS.GAL_TASK_ID = VPOS.GAL_TASK_ID
                            order by VPOS.DEP_NUMBER) loop
      if oProjectid is null then
        oProjectID  := lptlEstimatePos.GAL_PROJECT_ID;
      end if;

      -- Création d'un dossier de fabrication (DF)
      lnDF_GAL_TASK_ID   :=
        GAL_I_PRC_PROJECT.CreateTASK_DF(iGAL_FATHER_TASK_ID   => lptlEstimatePos.GAL_TASK_ID
                                      , iTAS_QUANTITY         => lptlEstimatePos.DEC_QUANTITY
                                      , iTAS_START_DATE       => null
                                      , iTAS_END_DATE         => lptlEstimatePos.DEP_DELIVERY_DATE
                                      , iTAS_DESCRIPTION      => lptlEstimatePos.DEP_SHORT_DESCRIPTION
                                      , iTAS_COMMENT          => lptlEstimatePos.DEP_COMMENT
                                       );
      -- Création du composé
      lnGoodID           :=
                 FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name   => 'GCO_GOOD', iv_column_name => 'GOO_MAJOR_REFERENCE'
                                             , iv_value         => lptlEstimatePos.DEP_REFERENCE);
      lGAL_TASK_LOT_ID   :=
                     GAL_I_PRC_PROJECT.CreateTASK_LOT(iGAL_TASK_ID    => lnDF_GAL_TASK_ID, iGCO_GOOD_ID => lnGoodId
                                                    , iGTL_QUANTITY   => lptlEstimatePos.DEC_QUANTITY);
      lGAL_TASK_GOOD_ID  :=
        GAL_I_PRC_PROJECT.CreateTASK_GOOD(iGAL_TASK_ID           => lptlEstimatePos.GAL_TASK_ID
                                        , iGCO_GOOD_ID           => lnGoodID
                                        , iPPS_NOMENCLATURE_ID   => PPS_I_LIB_FUNCTIONS.GetDefaultNomenclature(iGoodId => lnGoodId, iTypNom => '2')
                                        , iGML_QUANTITY          => lptlEstimatePos.DEC_QUANTITY
                                        , iGML_DESCRIPTION       => lptlEstimatePos.DEP_SHORT_DESCRIPTION
                                        , iGML_COMMENT           => lptlEstimatePos.DEP_COMMENT
                                         );

      -- Création des composants du DF
      for lptlEstimatePosComp in (select   VCOMP.GCO_GOOD_ID
                                         , VCOMP.ECP_SHORT_DESCRIPTION
                                         , VCOMP.ECP_LONG_DESCRIPTION
                                         , VCOMP.DEC_QUANTITY
                                         , VCOMP.ECP_REFERENCE
                                         , GCA.GAL_COST_CENTER_ID
                                         , VCOMP.DEC_COST_PRICE
                                      from EV_DOC_ESTIMATE_COMP VCOMP
                                         , GCO_GOOD GOO
                                         , GCO_GOOD_CATEGORY GCA
                                     where VCOMP.DOC_ESTIMATE_POS_ID = lptlEstimatePos.DOC_ESTIMATE_POS_ID
                                       and GOO.GCO_GOOD_ID = VCOMP.GCO_GOOD_ID
                                       and GOO.GOO_MAJOR_REFERENCE <> PCS.PC_CONFIG.GetConfig('DOC_ESTIMATE_GOOD')
                                       and GCA.GCO_GOOD_CATEGORY_ID = GOO.GCO_GOOD_CATEGORY_ID
                                  order by VCOMP.DED_NUMBER) loop
        lnGoodID           :=
            FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name   => 'GCO_GOOD', iv_column_name => 'GOO_MAJOR_REFERENCE'
                                        , iv_value         => lptlEstimatePosComp.ECP_REFERENCE);
        lGAL_TASK_GOOD_ID  :=
          GAL_I_PRC_PROJECT.CreateTASK_GOOD(iGAL_TASK_ID           => lnDF_GAL_TASK_ID
                                          , iGCO_GOOD_ID           => lnGoodID
                                          , iPPS_NOMENCLATURE_ID   => null
                                          , iGML_QUANTITY          => lptlEstimatePosComp.DEC_QUANTITY
                                          , iGML_DESCRIPTION       => lptlEstimatePosComp.ECP_SHORT_DESCRIPTION
                                          , iGML_COMMENT           => lptlEstimatePosComp.ECP_LONG_DESCRIPTION
                                           );

        if     lptlEstimatePos.GAL_BUDGET_ID is not null
           and lptlEstimatePosComp.GAL_COST_CENTER_ID is not null then
          -- ajout ligne de budget
          lGAL_BUDGET_LINE_ID  :=
            GAL_I_PRC_PROJECT.CreateOrUpdateBUDGET_LINE(lptlEstimatePos.GAL_BUDGET_ID
                                                      , lptlEstimatePosComp.GAL_COST_CENTER_ID
                                                      , lptlEstimatePosComp.DEC_QUANTITY
                                                      , lptlEstimatePosComp.DEC_COST_PRICE
                                                       );
        end if;
      end loop;

      -- Création des opérations du DF
      for lptlEstimatePosTask in (select   VTASK.FAL_TASK_ID
                                         , TAS.TAS_REF
                                         , TAS.C_TASK_TYPE
                                         , VTASK.DED_NUMBER
                                         , VTASK.DEC_COST_PRICE
                                         , VTASK.DEC_QUANTITY
                                         , TAS.FAL_FACTORY_FLOOR_ID
                                         , TAS.FAL_FAL_FACTORY_FLOOR_ID
                                         , FFL.GAL_COST_CENTER_ID
                                      from EV_DOC_ESTIMATE_TASK VTASK
                                         , FAL_TASK TAS
                                         , FAL_FACTORY_FLOOR FFL
                                     where VTASK.DOC_ESTIMATE_POS_ID = lptlEstimatePos.DOC_ESTIMATE_POS_ID
                                       and VTASK.FAL_TASK_ID is not null
                                       and TAS.FAL_TASK_ID = VTASK.FAL_TASK_ID
                                       and FFL.FAL_FACTORY_FLOOR_ID = TAS.FAL_FACTORY_FLOOR_ID
                                  order by VTASK.DED_NUMBER) loop
        lGAL_TASK_LINK_ID  :=
          GAL_I_PRC_PROJECT.CreateTASK_LINK(iGAL_TASK_ID                => lnDF_GAL_TASK_ID
                                          , iFAL_TASK_ID                => lptlEstimatePosTask.FAL_TASK_ID
                                          , iFAL_FACTORY_FLOOR_ID       => lptlEstimatePosTask.FAL_FACTORY_FLOOR_ID
                                          , iFAL_FAL_FACTORY_FLOOR_ID   => lptlEstimatePosTask.FAL_FAL_FACTORY_FLOOR_ID
                                          , iSCS_SHORT_DESCR            => lptlEstimatePosTask.TAS_REF
                                          , iC_TASK_TYPE                => lptlEstimatePosTask.C_TASK_TYPE
                                          , iC_RELATION_TYPE            => null
                                          , iTAL_DUE_TSK                => lptlEstimatePosTask.DEC_QUANTITY
                                           );

        if     lptlEstimatePos.GAL_BUDGET_ID is not null
           and lptlEstimatePosTask.GAL_COST_CENTER_ID is not null then
          -- ajout ligne de budget
          lGAL_BUDGET_LINE_ID  :=
            GAL_I_PRC_PROJECT.CreateOrUpdateBUDGET_LINE(lptlEstimatePos.GAL_BUDGET_ID
                                                      , lptlEstimatePosTask.GAL_COST_CENTER_ID
                                                      , lptlEstimatePosTask.DEC_QUANTITY
                                                      , lptlEstimatePosTask.DEC_COST_PRICE
                                                       );
        end if;
      end loop;
    end loop;

    -- Position du devis type C :
    --   Mode de création du bien : 00 (sans création)
    --   Bien n'est pas défini sur la position de devis
    --   Composants : Non
    --   Opérations : Oui
    --  lien sur tâche
    for lptlEstimatePos in (select   VPOS.GAL_TASK_ID
                                   , VPOS.GAL_BUDGET_ID
                                   , VPOS.DOC_ESTIMATE_POS_ID
                                   , nvl(TAS.GAL_PROJECT_ID, BUD.GAL_PROJECT_ID) GAL_PROJECT_ID
                                from EV_DOC_ESTIMATE_POS VPOS
                                   , GAL_TASK TAS
                                   , GAL_BUDGET BUD
                                   , GCO_GOOD GOO
                               where VPOS.DOC_ESTIMATE_ID = iEstimateID
                                 and VPOS.DEP_OPTION = 0
                                 and GOO.GCO_GOOD_ID = VPOS.GCO_GOOD_ID
                                 and GOO.GOO_MAJOR_REFERENCE = PCS.PC_CONFIG.GetConfig('DOC_ESTIMATE_GOOD')
                                 and VPOS.C_DOC_ESTIMATE_CREATE_MODE = '00'
                                 and VPOS.GAL_TASK_ID = TAS.GAL_TASK_ID(+)
                                 and VPOS.GAL_BUDGET_ID = BUD.GAL_BUDGET_ID(+)
                            order by VPOS.DEP_NUMBER) loop
      if oProjectid is null then
        oProjectID  := lptlEstimatePos.GAL_PROJECT_ID;
      end if;

      if lptlEstimatePos.GAL_TASK_ID is not null then
        -- Création des opérations
        for lptlEstimatePosTask in (select   VTASK.FAL_TASK_ID
                                           , TAS.TAS_REF
                                           , TAS.C_TASK_TYPE
                                           , VTASK.DED_NUMBER
                                           , VTASK.DEC_QUANTITY
                                           , VTASK.DEC_COST_PRICE
                                           , GTA.GAL_BUDGET_ID
                                           , TAS.FAL_FACTORY_FLOOR_ID
                                           , TAS.FAL_FAL_FACTORY_FLOOR_ID
                                           , FFL.GAL_COST_CENTER_ID
                                        from EV_DOC_ESTIMATE_TASK VTASK
                                           , GAL_TASK GTA
                                           , FAL_TASK TAS
                                           , FAL_FACTORY_FLOOR FFL
                                       where VTASK.DOC_ESTIMATE_POS_ID = lptlEstimatePos.DOC_ESTIMATE_POS_ID
                                         and VTASK.FAL_TASK_ID is not null
                                         and GTA.GAL_TASK_ID = lptlEstimatePos.GAL_TASK_ID
                                         and TAS.FAL_TASK_ID = VTASK.FAL_TASK_ID
                                         and FFL.FAL_FACTORY_FLOOR_ID = TAS.FAL_FACTORY_FLOOR_ID
                                    order by VTASK.DED_NUMBER) loop
          if     lptlEstimatePos.GAL_TASK_ID is not null
             and lptlEstimatePosTask.FAL_TASK_ID is not null then
            lGAL_TASK_LINK_ID  :=
              GAL_I_PRC_PROJECT.CreateTASK_LINK(iGAL_TASK_ID                => lptlEstimatePos.GAL_TASK_ID
                                              , iFAL_TASK_ID                => lptlEstimatePosTask.FAL_TASK_ID
                                              , iFAL_FACTORY_FLOOR_ID       => lptlEstimatePosTask.FAL_FACTORY_FLOOR_ID
                                              , iFAL_FAL_FACTORY_FLOOR_ID   => lptlEstimatePosTask.FAL_FAL_FACTORY_FLOOR_ID
                                              , iSCS_SHORT_DESCR            => lptlEstimatePosTask.TAS_REF
                                              , iC_TASK_TYPE                => lptlEstimatePosTask.C_TASK_TYPE
                                              , iC_RELATION_TYPE            => null
                                              , iTAL_DUE_TSK                => lptlEstimatePosTask.DEC_QUANTITY
                                               );
          end if;

          if     lptlEstimatePosTask.GAL_BUDGET_ID is not null
             and lptlEstimatePosTask.GAL_COST_CENTER_ID is not null then
            -- ajout ligne de budget
            lGAL_BUDGET_LINE_ID  :=
              GAL_I_PRC_PROJECT.CreateOrUpdateBUDGET_LINE(lptlEstimatePosTask.GAL_BUDGET_ID
                                                        , lptlEstimatePosTask.GAL_COST_CENTER_ID
                                                        , lptlEstimatePosTask.DEC_QUANTITY
                                                        , lptlEstimatePosTask.DEC_COST_PRICE
                                                         );
          end if;
        end loop;
      end if;

      -- mise à jour en-tête affaire et effacement des tâches et budgets non utilisés
      if lptlEstimatePos.GAL_BUDGET_ID is not null then
        -- Création des lignes de budget selon position devis
        for lptlEstimatePosTask in (select   VTASK.DEC_COST_PRICE
                                           , VTASK.DEC_QUANTITY
                                           , VCCE.GAL_COST_CENTER_ID
                                        from EV_DOC_ESTIMATE_TASK VTASK
                                           , GAL_COST_CENTER VCCE
                                           , FAL_TASK TAS
                                           , FAL_FACTORY_FLOOR FFL
                                       where VTASK.DOC_ESTIMATE_POS_ID = lptlEstimatePos.DOC_ESTIMATE_POS_ID
                                         and TAS.FAL_TASK_ID = VTASK.FAL_TASK_ID
                                         and FFL.FAL_FACTORY_FLOOR_ID = TAS.FAL_FACTORY_FLOOR_ID
                                         and VCCE.GAL_COST_CENTER_ID = FFL.GAL_COST_CENTER_ID
                                         and VCCE.GAL_COST_CENTER_ID is not null
                                    order by VTASK.DED_NUMBER) loop
          if     lptlEstimatePos.GAL_BUDGET_ID is not null
             and lptlEstimatePosTask.GAL_COST_CENTER_ID is not null then
            -- ajout ligne de budget
            lGAL_BUDGET_LINE_ID  :=
              GAL_I_PRC_PROJECT.CreateOrUpdateBUDGET_LINE(lptlEstimatePos.GAL_BUDGET_ID
                                                        , lptlEstimatePosTask.GAL_COST_CENTER_ID
                                                        , lptlEstimatePosTask.DEC_QUANTITY
                                                        , lptlEstimatePosTask.DEC_COST_PRICE
                                                         );
          end if;
        end loop;
      end if;
    end loop;

    if oProjectId is not null then
      for lptlEstimate in (select VEST.PAC_CUSTOM_PARTNER_ID
                                , nvl(VEST.DEC_SALE_PRICE_CORR, VEST.DEC_SALE_PRICE) DEC_SALE_PRICE
                                , VPOS.DEP_DELIVERY_DATE
                             from EV_DOC_ESTIMATE VEST
                                , (select   max(DEP_DELIVERY_DATE) DEP_DELIVERY_DATE
                                          , DOC_ESTIMATE_ID
                                       from EV_DOC_ESTIMATE_POS VPOS
                                   group by DOC_ESTIMATE_ID) VPOS
                            where VEST.DOC_ESTIMATE_ID = iEstimateID
                              and VEST.DOC_ESTIMATE_ID = VPOS.DOC_ESTIMATE_ID) loop
        update GAL_PROJECT
           set PAC_CUSTOM_PARTNER_ID = lptlEstimate.PAC_CUSTOM_PARTNER_ID
             , PRJ_SALE_PRICE = lptlEstimate.DEC_SALE_PRICE
             , PRJ_CUSTOMER_DELIVERY_DATE = lptlEstimate.DEP_DELIVERY_DATE
         where GAL_PROJECT_ID = oProjectId;
      end loop;

      for lptlTask in (select     level ROW_LEVEL
                                , TAS.GAL_TASK_ID
                             from GAL_TASK TAS
                            where TAS.GAL_PROJECT_ID = oProjectId
                       connect by prior TAS.GAL_TASK_ID = TAS.GAL_FATHER_TASK_ID
                       start with TAS.GAL_FATHER_TASK_ID is null
                         order by ROW_LEVEL desc) loop
        delete from GAL_TASK TAS
              where GAL_TASK_ID = lptlTask.GAL_TASK_ID
                and GAL_FATHER_TASK_ID is null
                and not exists(select GAL_TASK_ID
                                 from GAL_TASK TAS_F
                                where TAS_F.GAL_FATHER_TASK_ID = TAS.GAL_TASK_ID)
                and not exists(select GAL_TASK_ID
                                 from EV_DOC_ESTIMATE_POS VPOS
                                where DOC_ESTIMATE_ID = iEstimateID
                                  and VPOS.GAL_TASK_ID = TAS.GAL_TASK_ID);
      end loop;

      for lptlBudget in (select     level ROW_LEVEL
                                  , BDG.GAL_BUDGET_ID
                               from GAL_BUDGET BDG
                              where BDG.GAL_PROJECT_ID = oProjectId
                         connect by prior BDG.GAL_BUDGET_ID = BDG.GAL_FATHER_BUDGET_ID
                         start with BDG.GAL_FATHER_BUDGET_ID is null
                           order by ROW_LEVEL desc) loop
        delete from GAL_BUDGET BUD
              where GAL_BUDGET_ID = lptlBudget.GAL_BUDGET_ID
                and not exists(select GAL_BUDGET_ID
                                 from GAL_BUDGET BUD_F
                                where BUD_F.GAL_FATHER_BUDGET_ID = BUD.GAL_BUDGET_ID)
                and not exists(select GAL_BUDGET_ID
                                 from EV_DOC_ESTIMATE_POS VPOS
                                where DOC_ESTIMATE_ID = iEstimateID
                                  and VPOS.GAL_BUDGET_ID = BUD.GAL_BUDGET_ID)
                and not exists(select GAL_TASK_ID
                                 from GAL_TASK TAS
                                where TAS.GAL_BUDGET_ID = BUD.GAL_BUDGET_ID);
      end loop;
    end if;
  exception
    when others then
      oError  := sqlerrm || co.cLineBreak || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
  end GenerateProject;

  /**
  * procedure UpdateTaskID
  * Description
  *   Màj du champ FAL_TASK_ID sur l'élément de l'opération passée en param
  */
  procedure UpdateListStepLinkID(
    iEstimateTaskID in DOC_ESTIMATE_TASK.DOC_ESTIMATE_TASK_ID%type
  , iListStepLinkID in DOC_ESTIMATE_TASK.FAL_LIST_STEP_LINK_ID%type
  )
  is
    ltTask FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Création de l'entité DOC_ESTIMATE_TASK
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimateTask, ltTask);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'DOC_ESTIMATE_TASK_ID', iEstimateTaskID);
    -- Init de l'id du bien crée
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltTask, 'FAL_LIST_STEP_LINK_ID', iListStepLinkID);
    FWK_I_MGT_ENTITY.UpdateEntity(ltTask);
    FWK_I_MGT_ENTITY.Release(ltTask);
  end UpdateListStepLinkID;

  /**
  * procedure UpdateStatus
  * Description
  *   Màj du statut du devis
  */
  procedure UpdateStatus(iEstimateID in DOC_ESTIMATE.DOC_ESTIMATE_ID%type, iNewStatus in DOC_ESTIMATE.C_DOC_ESTIMATE_STATUS%type)
  is
    ltEstimate FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Création de l'entité DOC_ESTIMATE
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimate, ltEstimate);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltEstimate, 'DOC_ESTIMATE_ID', iEstimateID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltEstimate, 'C_DOC_ESTIMATE_STATUS', iNewStatus);
    FWK_I_MGT_ENTITY.UpdateEntity(ltEstimate);
    FWK_I_MGT_ENTITY.Release(ltEstimate);
  end UpdateStatus;

  /**
  * Description
  *   Suppression d'un devis
  */
  procedure DeleteEstimate(iEstimateID in DOC_ESTIMATE.DOC_ESTIMATE_ID%type)
  is
  begin
    if DOC_LIB_ESTIMATE.ExistsEstimateDocuments(iEstimateId) then
      -- Devis au statut annulé
      UpdateStatus(iEstimateId, '02');
    else
      declare
        ltEstimate FWK_I_TYP_DEFINITION.t_crud_def;
      begin
        FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimate, ltEstimate);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltEstimate, 'DOC_ESTIMATE_ID', iEstimateID);
        ltEstimate.attribute_list('SAFE_CALL')  := '1';
        FWK_I_MGT_ENTITY.DeleteEntity(ltEstimate);
        FWK_I_MGT_ENTITY.Release(ltEstimate);
      end;
    end if;
  end DeleteEstimate;

  /**
  * procedure AcceptEstimate
  * Description
  *   Accepter un devis
  * @created fp 27.12.2011
  * @lastUpdate
  * @public
  * @param
  */
  procedure AcceptEstimate(iEstimateID in DOC_ESTIMATE.DOC_ESTIMATE_ID%type)
  is
    lMessage varchar2(4000);
  begin
    if PCS.PC_CONFIG.GetConfig('DOC_ESTIMATE_CREATE_GOOD') = '2' then
      -- création des articles à partir du devis (produit fini et composants), nomenclature et gammes opératoires
      GenerateProducts(iEstimateID, lMessage);

      if lMessage is not null then
        fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                          , iv_message       => lMessage
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'GenerateProducts'
                                           );
      end if;
    end if;

    -- Devis au statut accepté
    UpdateStatus(iEstimateId, '06');
  end AcceptEstimate;

  /**
  * procedure RefuseEstimate
  * Description
  *   Refuser un devis
  * @created fp 27.12.2011
  * @lastUpdate
  * @public
  * @param
  */
  procedure RefuseEstimate(iEstimateID in DOC_ESTIMATE.DOC_ESTIMATE_ID%type)
  is
  begin
    -- Devis au statut refusé
    UpdateStatus(iEstimateId, '02');
  end RefuseEstimate;

  /**
  * Description
  *   Copie d'un devis
  */
  procedure DuplicateEstimate(
    iRefEstimateID in     DOC_ESTIMATE.DOC_ESTIMATE_ID%type
  , iNewNumber     in     DOC_ESTIMATE.DES_NUMBER%type default null
  , oNewEstimateID out    DOC_ESTIMATE.DOC_ESTIMATE_ID%type
  )
  is
    ltEstimate            FWK_I_TYP_DEFINITION.t_crud_def;
    ltEstimatePos         FWK_I_TYP_DEFINITION.t_crud_def;
    ltEstimateElement     FWK_I_TYP_DEFINITION.t_crud_def;
    lNewEstimatePosId     DOC_ESTIMATE_POS.DOC_ESTIMATE_POS_ID%type;
    lNewEstimateElementId DOC_ESTIMATE_ELEMENT.DOC_ESTIMATE_ELEMENT_ID%type;
  begin
    oNewEstimateID  := getNewId;

    -- Copie de l'entête de devis
    for ltplEstimate in (select DOC_ESTIMATE_ID
                              , PAC_CUSTOM_PARTNER_ID
                           from EV_DOC_ESTIMATE
                          where DOC_ESTIMATE_ID = iRefEstimateID) loop
      FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_TYP_DOC_ENTITY.gcEvDocEstimate, iot_crud_definition => ltEstimate, iv_primary_col => 'DOC_ESTIMATE_ID');
      FWK_I_MGT_ENTITY.prepareDuplicate(ltEstimate, true, iRefEstimateID);
      -- id principal
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltEstimate, 'DOC_ESTIMATE_ID', oNewEstimateID);
      -- id principal
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltEstimate, 'DOC_ESTIMATE_FOOT_ID', oNewEstimateID);
      -- id principal des éléments de coût
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltEstimate, 'DOC_ESTIMATE_ELEMENT_COST_ID');
      -- Relit l'id du gabarit de l'offre
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltEstimate
                                    , 'DOC_GAUGE_OFFER_ID'
                                    , FWK_I_LIB_ENTITY.getIdfromPk2('DOC_GAUGE', 'GAU_DESCRIBE', PCS.PC_CONFIG.GetConfig('DOC_ESTIMATE_GAUGE_OFFER') )
                                     );
      -- Relit l'id du gabarit de la commande client
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltEstimate
                                    , 'DOC_GAUGE_ORDER_ID'
                                    , FWK_I_LIB_ENTITY.getIdfromPk2('DOC_GAUGE', 'GAU_DESCRIBE', PCS.PC_CONFIG.GetConfig('DOC_ESTIMATE_GAUGE_ORDER') )
                                     );
      -- id du projet généré
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltEstimate, 'GAL_PROJECT_ID');
      -- statut "saisi"
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltEstimate, 'C_DOC_ESTIMATE_STATUS', '00');
      -- numéros de devis
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltEstimate, 'DES_NUMBER', iNewNumber);
      -- Réinitialise les champs de création A_DATECRE et A_IDMOD
      --FWK_I_MGT_ENTITY_DATA.SetColumnsCreation(ltEstimate, true);
      -- Supprime les valeurs des champs de modification A_DATEMOD et A_IDMOD
      --FWK_I_MGT_ENTITY_DATA.SetColumnsModification(ltEstimate, false);
      FWK_I_MGT_ENTITY.InsertEntity(ltEstimate);
      FWK_I_MGT_ENTITY.Release(ltEstimate);
    end loop;

    -- Copie des positions de devis
    for ltplEstimatePos in (select   DOC_ESTIMATE_POS_ID
                                   , DEC_QUANTITY
                                   , GCO_GOOD_ID
                                from EV_DOC_ESTIMATE_POS
                               where DOC_ESTIMATE_ID = iRefEstimateID
                            order by DEP_NUMBER) loop
      /* Copie de la position et des ses éventuels composants */
      DOC_PRC_ESTIMATE_POS.DuplicateEstimatePos(inRefEstimateID      => oNewEstimateID
                                              , inRefEstimatePosID   => ltplEstimatePos.DOC_ESTIMATE_POS_ID
                                              , inRefGcoGoodID       => ltplEstimatePos.GCO_GOOD_ID
                                              , onNewEstimatePosID   => lNewEstimatePosId
                                              , inNewQuantity        => ltplEstimatePos.DEC_QUANTITY
                                              , inDoSetOptionFlag    => 0
                                               );
    end loop;
  end DuplicateEstimate;

  /**
  * Description
  *    Mise à jour du flag de recalcul des coûts pour le devis
  */
  procedure UpdateEstimateFlag(inDocEstimateID in DOC_ESTIMATE_ELEMENT_COST.DOC_ESTIMATE_ID%type, inValue in DOC_ESTIMATE.DES_RECALC_AMOUNTS%type)
  as
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Récupération de l'entité du devis concerné
    FWK_I_MGT_ENTITY.new(iv_entity_name        => FWK_I_TYP_DOC_ENTITY.gcDocEstimate
                       , iot_crud_definition   => ltCRUD_DEF
                       , ib_initialize         => true
                       , in_main_id            => inDocEstimateID
                       , in_schema_call        => fwk_i_typ_definition.SCHEMA_CURRENT
                        );
    -- Mise à jour du flag
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'DES_RECALC_AMOUNTS', inValue);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end UpdateEstimateFlag;

  /**
  * procedure EstimateHasError
  * Description
  *   Contrôle sides erreurs sont présentes dans la saisie des positions du devis
  */
  procedure EstimateHasError(oPosHasError out integer, oCompHasError out integer, oTaskHasError out integer)
  is
  begin
    select nvl(sum(LID_FREE_NUMBER_1 + LID_FREE_NUMBER_2), 0)
      into oPosHasError
      from COM_LIST_ID_TEMP
     where LID_CODE = 'DOC_ESTIMATE_POS';

    select nvl(sum(LID_FREE_NUMBER_1 + LID_FREE_NUMBER_2), 0)
      into oCompHasError
      from COM_LIST_ID_TEMP
     where LID_CODE = 'DOC_ESTIMATE_COMP';

    select nvl(sum(LID_FREE_NUMBER_1 + LID_FREE_NUMBER_2), 0)
      into oTaskHasError
      from COM_LIST_ID_TEMP
     where LID_CODE = 'DOC_ESTIMATE_TASK';
  end EstimateHasError;

  /**
  * procedure GetEstimateError
  * Description
  *   Contrôle si des erreurs ou données manquantes dans la saisie des positions du devis
  */
  procedure GetEstimateError(oPos out integer, oComp out integer, oTask out integer)
  is
  begin
    select nvl(sum(LID_FREE_NUMBER_1 + LID_FREE_NUMBER_2), 0)
      into oPos
      from COM_LIST_ID_TEMP
     where LID_CODE = 'DOC_ESTIMATE_POS';

    select nvl(sum(LID_FREE_NUMBER_1 + LID_FREE_NUMBER_2), 0)
      into oComp
      from COM_LIST_ID_TEMP
     where LID_CODE = 'DOC_ESTIMATE_COMP';

    select nvl(sum(LID_FREE_NUMBER_1 + LID_FREE_NUMBER_2), 0)
      into oTask
      from COM_LIST_ID_TEMP
     where LID_CODE = 'DOC_ESTIMATE_TASK';
  end GetEstimateError;

  /**
  * procedure GetEstimateWarning
  * Description
  *   Contrôle si des avertissements sont présents dans la saisie des positions du devis
  */
  procedure GetEstimateWarning(oPos out integer, oComp out integer, oTask out integer)
  is
  begin
    select nvl(sum(LID_FREE_NUMBER_3), 0)
      into oPos
      from COM_LIST_ID_TEMP
     where LID_CODE = 'DOC_ESTIMATE_POS';

    select nvl(sum(LID_FREE_NUMBER_3), 0)
      into oComp
      from COM_LIST_ID_TEMP
     where LID_CODE = 'DOC_ESTIMATE_COMP';

    select nvl(sum(LID_FREE_NUMBER_3), 0)
      into oTask
      from COM_LIST_ID_TEMP
     where LID_CODE = 'DOC_ESTIMATE_TASK';
  end GetEstimateWarning;

  /**
  * procedure ClearErrorsLog
  * Description
  *   Vide la table du log des erreurs
  */
  procedure ClearErrorsLog
  is
  begin
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'DOC_ESTIMATE_POS'
             or LID_CODE = 'DOC_ESTIMATE_COMP'
             or LID_CODE = 'DOC_ESTIMATE_TASK';
  end ClearErrorsLog;

  /**
  * procedure CtrEstimate
  * Description
  *   Lance les processus de contrôles des positions
  */
  procedure CtrEstimate(iEstimateID in DOC_ESTIMATE.DOC_ESTIMATE_ID%type)
  is
  begin
    --  Vide la table du log des erreurs
    ClearErrorsLog;

    -- Parcours des positions du devis
    for ltplPos in (select   DOC_ESTIMATE_POS_ID
                        from EV_DOC_ESTIMATE_POS
                       where DOC_ESTIMATE_ID = iEstimateID
                         and DEP_OPTION = 0
                    order by DEP_NUMBER) loop
      DOC_PRC_ESTIMATE_POS.CtrlPos(iEstimatePosID => ltplPos.DOC_ESTIMATE_POS_ID);
    end loop;
  end CtrEstimate;

  /**
  * procedure AutoLinkToGalTask
  * Description
  *   Lien automatique du devis sur l'affaire
  * Condition
  *  une seule tâche d'approvisionnement -> attacher automatiquement toute les position de devis défini avec un bien (DOC_ESTIMATE_POS.GCO_GOOD_ID <> null)
   * une seule tâche de MO -> attacher automatiquement toute les positions de devis défini avec un bien (DOC_ESTIMATE_POS.GCO_GOOD_ID = null)
  * @created AGA 17.01.2012
  * @lastUpdate
  * @public
  * @param iEstimatePosID : ID de la position de devis
  * @param iTaskID  : ID de la tâche d'affaire
  * @param oMessage : message d'erreur si le lien avec une tâche d'affaire est impossible,
  *                       et NULL si le lien est autorisée
  */
  procedure AutoLinkToProjectTask(iEstimateID in DOC_ESTIMATE.DOC_ESTIMATE_ID%type, iProjectID in GAL_PROJECT.GAL_PROJECT_ID%type, oMessage out varchar2)
  is
    lCountGalTaskAppro number;
    lCountGalTaskLabor number;
    lCountGalBudget    number;
    lApproGAL_TASK_ID  DOC_ESTIMATE_POS.GAL_TASK_ID%type;
    lLaborGAL_TASK_ID  DOC_ESTIMATE_POS.GAL_TASK_ID%type;
    lGAL_BUDGET_ID     DOC_ESTIMATE_POS.GAL_BUDGET_ID%type;
    lMessage           varchar2(1000);
    ltCRUD_DEF         FWK_I_TYP_DEFINITION.t_crud_def;
    lnVirtualGoodID    GCO_GOOD.GCO_GOOD_ID%type;

    procedure SetMessage(iMess in varchar2)
    is
    begin
      if lMessage is null then
        lMessage  := iMess;
      else
        lMessage  := lMessage || chr(13) || iMess;
      end if;
    end;
  begin
    -- Rechercher l'id du produit virtuel
    lnVirtualGoodID  := nvl(FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', PCS.PC_CONFIG.GetConfig('DOC_ESTIMATE_GOOD') ), 0);

    select count(*)
         , max(GAL_TASK_ID)
      into lCountGalTaskAppro
         , lApproGAL_TASK_ID
      from GAL_TASK TAS
         , GAL_TASK_CATEGORY TCA
     where TAS.GAL_PROJECT_ID = iProjectId
       and TAS.GAL_TASK_CATEGORY_ID = TCA.GAL_TASK_CATEGORY_ID
       and TCA.C_TCA_TASK_TYPE = '1';

    select count(*)
         , max(GAL_TASK_ID)
      into lCountGalTaskLabor
         , lLaborGAL_TASK_ID
      from GAL_TASK TAS
         , GAL_TASK_CATEGORY TCA
     where TAS.GAL_PROJECT_ID = iProjectId
       and TAS.GAL_TASK_CATEGORY_ID = TCA.GAL_TASK_CATEGORY_ID
       and TCA.C_TCA_TASK_TYPE = '2';

    select count(*)
         , max(GAL_BUDGET_ID)
      into lCountGalBudget
         , lGAL_BUDGET_ID
      from GAL_BUDGET BUD
     where BUD.GAL_PROJECT_ID = iProjectId
       and BUD.GAL_FATHER_BUDGET_ID is null
       and BUD.C_BDG_STATE = '10';

    if     lCountGalTaskAppro <> 1
       and lCountGalTaskLabor <> 1
       and lCountGalBudget <> 1 then
      SetMessage('Automatic link not possible for this project' || '[CHECK]');
    end if;

    -- Type main d'oeuvre
    if    (lCountGalTaskLabor = 1)
       or (lCountGalBudget = 1) then
      -- Position du devis type C -> lien sur tâche ou lien sur budget
      for lptlEstimatePos in (select   VPOS.DOC_ESTIMATE_POS_ID
                                  from EV_DOC_ESTIMATE_POS VPOS
                                     , EV_DOC_ESTIMATE_TASK VTASK
                                 where VPOS.DOC_ESTIMATE_ID = iEstimateID
                                   and VPOS.DOC_ESTIMATE_POS_ID = VTASK.DOC_ESTIMATE_POS_ID
                                   and VPOS.C_DOC_ESTIMATE_CREATE_MODE = '00'
                                   and nvl(VPOS.GCO_GOOD_ID, lnVirtualGoodID) = lnVirtualGoodID
                                   and VPOS.GAL_TASK_ID is null
                                   and VTASK.FAL_TASK_ID is not null
                                   and VPOS.DEP_OPTION = 0
                              group by VPOS.DOC_ESTIMATE_POS_ID) loop
        FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimatePos, ltCRUD_DEF);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_ESTIMATE_POS_ID', lptlEstimatePos.DOC_ESTIMATE_POS_ID);

        -- Lien sur tâche de type main d'oeuvre
        if (lCountGalTaskLabor = 1) then
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GAL_TASK_ID', lLaborGAL_TASK_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltCRUD_DEF, 'GAL_BUDGET_ID');
        else
          -- Lien sur budget
          FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltCRUD_DEF, 'GAL_TASK_ID');
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GAL_BUDGET_ID', lGAL_BUDGET_ID);
        end if;

        FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
        FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      end loop;
    else
      SetMessage('Automatic link not possible for Labor task' || '[CHECK]');
      SetMessage('Automatic link not possible for Budget' || '[CHECK]');
    end if;

    -- Tâche de type Appro
    if (lCountGalTaskAppro = 1) then
      -- Position du devis type A et B
      for lptlEstimatePos in (select   VPOS.DOC_ESTIMATE_POS_ID
                                  from EV_DOC_ESTIMATE_POS VPOS
                                 where VPOS.DOC_ESTIMATE_ID = iEstimateID
                                   and VPOS.DEP_OPTION = 0
                                   and VPOS.GAL_TASK_ID is null
                                   and VPOS.GAL_BUDGET_ID is null
                                   and VPOS.DOC_ESTIMATE_POS_ID not in(
                                         select   POS.DOC_ESTIMATE_POS_ID
                                             from EV_DOC_ESTIMATE_POS POS
                                                , EV_DOC_ESTIMATE_TASK TSK
                                            where POS.DOC_ESTIMATE_ID = iEstimateID
                                              and POS.DOC_ESTIMATE_POS_ID = TSK.DOC_ESTIMATE_TASK_ID
                                              and POS.C_DOC_ESTIMATE_CREATE_MODE = '00'
                                              and nvl(POS.GCO_GOOD_ID, lnVirtualGoodID) = lnVirtualGoodID
                                         group by POS.DOC_ESTIMATE_POS_ID)
                              order by VPOS.DEP_NUMBER) loop
        FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimatePos, ltCRUD_DEF);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_ESTIMATE_POS_ID', lptlEstimatePos.DOC_ESTIMATE_POS_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GAL_TASK_ID', lApproGAL_TASK_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltCRUD_DEF, 'GAL_BUDGET_ID');
        FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
        FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      end loop;
    else
      SetMessage('Automatic link not possible for Procurement task' || '[CHECK]');
    end if;

    oMessage         := lMessage;
  end AutoLinkToProjectTask;

  /**
  * procedure UpdateLinkProject
  * Description
  *   Màj du lien affaire sur l'entete du devis
  */
  procedure UpdateLinkProject(iEstimateID in DOC_ESTIMATE.DOC_ESTIMATE_ID%type, iProjectID in GAL_PROJECT.GAL_PROJECT_ID%type)
  is
    ltEstimate FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocEstimate, ltEstimate);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltEstimate, 'DOC_ESTIMATE_ID', iEstimateID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltEstimate, 'GAL_PROJECT_ID', iProjectID);
    FWK_I_MGT_ENTITY.UpdateEntity(ltEstimate);
    FWK_I_MGT_ENTITY.Release(ltEstimate);
  end UpdateLinkProject;
end DOC_PRC_ESTIMATE;
