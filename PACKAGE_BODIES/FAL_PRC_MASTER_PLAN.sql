--------------------------------------------------------
--  DDL for Package Body FAL_PRC_MASTER_PLAN
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_MASTER_PLAN" 
is
  gcFalTitlePlanDir   constant varchar2(10) := PCS.PC_Config.GetConfig('FAL_TITLE_PLAN_DIR');
  gcDefaultStockID    constant number       := FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_NETWORK');
  gcDefaultLocationID constant number       := FAL_TOOLS.GetConfig_LocationID('PPS_DefltLOCATION_NETWORK', gcDefaultStockID);

/*-----------------------------------------------------------------------------------
                        Calcul des Niveaux des Produits PDP
-----------------------------------------------------------------------------------*/
  procedure ProcessPMPLevel(GcoGoodID number, N number)
  is
  begin
    insert into FAL_PDP_LEVEL
                (FAL_PDP_LEVEL_ID
               , GCO_GOOD_ID
               , FPD_LEVEL
               , A_DATECRE
               , A_IDCRE
                )
         values (GetNewId
               , GcoGoodID
               , N
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end ProcessPMPLevel;

  procedure CalcPMPLevels(iFalPicID number)
  is
    cursor CUR_FAL_PDP_LEVEL1(N number)
    is
      select GCO_GOOD_ID
        from FAL_PDP_LEVEL
       where FPD_LEVEL = N;

    -- Sélection de la nomenclature dans la donnée complémentaire
    -- de la condition de fabrication du PIC
    cursor lcrComplDataManufacture1(GcoGoodID number, iFalPicID number)
    is
      select PPS_NOMENCLATURE_ID
        from GCO_COMPL_DATA_MANUFACTURE GCDM
           , FAL_PIC FP
       where GCO_GOOD_ID = GcoGoodID
         and FAL_PIC_ID = iFalPicID
         and GCDM.DIC_FAB_CONDITION_ID = FP.DIC_FAB_CONDITION_ID;

    -- Sélection de la nomenclature dans la donnée complémentaire
    -- de fabrication par défaut du produit
    cursor lcrComplDataManufacture2(GcoGoodID number)
    is
      select PPS_NOMENCLATURE_ID
        from GCO_COMPL_DATA_MANUFACTURE
       where GCO_GOOD_ID = GcoGoodID
         and CMA_DEFAULT = 1;

    -- Sélection de la nomenclature par défaut du produit
    cursor lcrNomenclature(GcoGoodID number)
    is
      select PPS_NOMENCLATURE_ID
        from PPS_NOMENCLATURE
       where GCO_GOOD_ID = GcoGoodID
         and (   C_TYPE_NOM = '2'
              or C_TYPE_NOM = '3'
              or C_TYPE_NOM = '4')
         and NOM_DEFAULT = 1;

    -- Pour la nomenclature trouvée, sélection des composants
    cursor lcrNomBond(PpsNomenclatureID number)
    is
      select PNB.GCO_GOOD_ID
        from PPS_NOM_BOND PNB
           , GCO_PRODUCT GP
           , GCO_GOOD GG
       where PPS_NOMENCLATURE_ID = PpsNomenclatureID
         and PNB.GCO_GOOD_ID = GP.GCO_GOOD_ID
         and PNB.GCO_GOOD_ID = GG.GCO_GOOD_ID
         and C_TYPE_COM = 1
         and (   C_KIND_COM = '1'
              or C_KIND_COM = '3')
         and COM_PDIR_COEFF > 0
         and (   PDT_STOCK_MANAGEMENT = 1
              or C_KIND_COM = 3)
         and (   C_PRODUCT_TYPE = '1'
              or C_PRODUCT_TYPE = '3')
         and C_GOOD_STATUS = GCO_I_LIB_CONSTANT.gcGoodStatusActive;

    cursor lcrPMPLevel2(ProductID number)
    is
      select FAL_PDP_LEVEL_ID
        from FAL_PDP_LEVEL
       where GCO_GOOD_ID = ProductID
         and FPD_LEVEL <> 0;

    -- Déclaration des variables
    N                 number;
    CountFalPDPLevel  number;
    GcoGoodID         number;
    PpsNomenclatureID number;
    ProductID         number;
    FalPDPLevelID     number;
  begin
    -- Effacement enregistrements de la table des niveaux PDP
    delete from FAL_PDP_LEVEL;

    N  := 0;

    -- Pour chaque produit lié au PIC, création "Niveaux Produit PDP"
    insert into FAL_PDP_LEVEL
                (FAL_PDP_LEVEL_ID
               , GCO_GOOD_ID
               , FPD_LEVEL
               , A_DATECRE
               , A_IDCRE
                )
      select   GetNewId
             , GCO_GOOD_ID
             , 0
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from FAL_PIC_LINE
         where FAL_PIC_ID = iFalPicID
      group by GCO_GOOD_ID;

    select count(1)
      into CountFalPDPLevel
      from FAL_PDP_LEVEL
     where FPD_LEVEL = N;

    while CountFalPDPLevel <> 0 loop
      -- Calcul Niveau PDP --2--
      -- Pour chaque produit de Niveau = N
      open CUR_FAL_PDP_LEVEL1(N);

      N  := N + 1;

      loop
        fetch CUR_FAL_PDP_LEVEL1
         into GcoGoodID;

        exit when CUR_FAL_PDP_LEVEL1%notfound;

        -- Sélection de la nomenclature dans la donnée complémentaire
        -- de la condition de fabrication du PIC
        open lcrComplDataManufacture1(GcoGoodID, iFalPicID);

        fetch lcrComplDataManufacture1
         into PpsNomenclatureID;

        if lcrComplDataManufacture1%notfound then
          PpsNomenclatureID  := null;
        end if;

        close lcrComplDataManufacture1;

        -- Calcul Niveau PDP --3--
        if PpsNomenclatureID is null then
          -- Sélection de la Nomenclature dans la donnée complémentaire
          -- de fabrication par défaut du produit
          open lcrComplDataManufacture2(GcoGoodID);

          fetch lcrComplDataManufacture2
           into PpsNomenclatureID;

          if lcrComplDataManufacture2%notfound then
            PpsNomenclatureID  := null;
          end if;

          close lcrComplDataManufacture2;
        end if;

        -- Calcul Niveau PDP --4--
        if PpsNomenclatureID is null then
          -- Sélection de la nomenclature par défaut du produit
          open lcrNomenclature(GcoGoodID);

          fetch lcrNomenclature
           into PpsNomenclatureID;

          if lcrNomenclature%notfound then
            PpsNomenclatureID  := null;
          end if;

          close lcrNomenclature;
        end if;

        -- Calcul Niveau PDP --5--
        if PpsNomenclatureID is not null then
          -- Pour la nomenclature trouvée, sélection des composants
          open lcrNomBond(PpsNomenclatureID);

          loop
            fetch lcrNomBond
             into ProductID;

            exit when lcrNomBond%notfound;

                -- Calcul Niveau PDP --6--
            -- Pour chaque produit trouvé, si le produit est dans la table FAL_PDP_LEVEL,
            -- on met à jour le niveau, sinon, on le crée dans cette même table avec le niveau N
            open lcrPMPLevel2(ProductID);

            fetch lcrPMPLevel2
             into FalPDPLevelID;

            if lcrPMPLevel2%notfound then
              -- Calcul Niveau PDP --7--
              ProcessPMPLevel(ProductID, N);
            else
              -- Calcul Niveau PDP --8--
              update FAL_PDP_LEVEL
                 set FPD_LEVEL = N
                   , A_DATEMOD = sysdate
                   , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
               where FAL_PDP_LEVEL_ID = FalPDPLevelID;
            end if;

            close lcrPMPLevel2;
          end loop;

          close lcrNomBond;
        end if;
      end loop;

      close CUR_FAL_PDP_LEVEL1;

      select count(1)
        into CountFalPDPLevel
        from FAL_PDP_LEVEL
       where FPD_LEVEL = N;
    end loop;   -- du while
  end;

  /**
  * procedure : PrefixProp_PropositionNumber
  * Description : Renvoie le Prefixe proposition, le N° proposition et le Gabarit document en fonction du Type de
  *               proposition et du Mode d'approvisionnement -- Incrémente FAL_PROP_DEF -> FPR_METER de 1
  *
  * @created
  * @lastUpdate CLG
  * @public
  * @param   iSupplyMode      Mode d'approvisionnement
  * @out     ioCPrefixProp    Préfixe de proposition
  * @out     ioLotNumber      Numéro de proposition
  * @out     ioDocGaugeId     Gabarit document
  *
  */
  procedure PrefixProp_PropositionNumber(
    iSupplyMode   in     GCO_PRODUCT.C_SUPPLY_MODE%type
  , ioCPrefixProp in out FAL_LOT_PROP.C_PREFIX_PROP%type
  , ioLotNumber   in out FAL_LOT_PROP.LOT_NUMBER%type
  , ioDocGaugeId  in out number
  )
  is
    -- Préfixe proposition et N° proposition
    cursor lcrPropDef
    is
      select C_PREFIX_PROP
           , nvl(FPR_METER, 0) + 1
           , DOC_GAUGE_ID
        from FAL_PROP_DEF
       where C_PROP_TYPE = '3'   -- type plan directeur
         and C_SUPPLY_MODE = iSupplyMode;
  begin
    open lcrPropDef;

    fetch lcrPropDef
     into ioCPrefixProp
        , ioLotNumber
        , ioDocGaugeId;

    close lcrPropDef;

    -- Incrémentation de FPR_METER de FAL_PROP_DEF
    update FAL_PROP_DEF
       set FPR_METER = FPR_METER + 1
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where C_PROP_TYPE = '3'   -- type plan directeur
       and C_SUPPLY_MODE = iSupplyMode;
  end;

  /**
  * procedure : CreationPropLogPDP
  * Description : Création de proposition d'achat pour le plan directeur
  *
  * @created
  * @lastUpdate ECA
  * @public
  * @param   iFalPicID           plan directeur
  * @param   iGcoGoodID          produit
  * @param   iStockDest          Stock destination
  * @param   iLocationDest       Emplacement destination
  * @param   iQtePDP             Quantité PDP
  * @param   iQteRebutPlanifie   Quantité rebut planifié
  * @param   iBesoin             Réseau Besoin
  * @param   iDateBesoin         Date besoin
  * @param   iPDPParam           Paramètres PDP du produit
  * @param   iPrmFAL_PIC_LINE_ID Ligne de pic
  *
  */
  function CreatePMPPurchaseProp(
    iFalPicID           in number
  , iGcoGoodID          in number
  , iStockDest          in number
  , iLocationDest       in number
  , iQtePDP             in number
  , iQteRebutPlanifie   in number
  , iBesoin             in number
  , iDateBesoin         in date
  , iPDPParam           in FAL_I_LIB_MRP_CALCULATION.TMrpProductParam
  , iPrmFAL_PIC_LINE_ID in number
  )
    return number
  is
    lnresult           number;
    lvCPrefixProp      FAL_LOT_PROP.C_PREFIX_PROP%type;
    liFDPNumber        FAL_LOT_PROP.LOT_NUMBER%type;
    lnDocGaugeID       number;
    lvFDPSecondRef     FAL_LOT_PROP.LOT_SECOND_REF%type;
    lvFDPPshortDescr   FAL_LOT_PROP.LOT_PSHORT_DESCR%type;
    lvRefPrinc         GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    lvDescrFree        GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type;
    lvDescrLong        GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type;
    ldFpdIntermedDelay FAL_DOC_PROP.FDP_INTERMEDIATE_DELAY%type;
    ldFpdBasisDelay    FAL_DOC_PROP.FDP_BASIS_DELAY%type;
    lnThirdAciID       number;
    lnThirdDeliveryID  number;
    lnThirdTariffID    number;
    liFalDocProp       FAL_DOC_PROP%rowtype;
  begin
    lnresult                                   := GetNewId;
    -- Rechecher Prefixe proposition, N° proposition et Gabarit document
    -- en fonction du Type de proposition et du Mode d'approvisionnement
    -- Incrémente FAL_PROP_DEF -> FPR_METER de 1
    PrefixProp_PropositionNumber(iPDPParam.cSupplyMode, lvCPrefixProp, liFDPNumber, lnDocGaugeID);

    -- Recherche référence, description du produit
    if iGcoGoodID is not null then
      FAL_TOOLS.GetMajorSecShortFreeLong(iGcoGoodID, lvRefPrinc, lvFDPSecondRef, lvFDPPshortDescr, lvDescrFree, lvDescrLong);
    else
      lvFDPSecondRef    := null;
      lvFDPPshortDescr  := null;
    end if;

    -- Calcul du délai intermédiaire à partir de la date besoin
    ldFpdIntermedDelay                         :=
      FAL_SCHEDULE_FUNCTIONS.GetDecalage(aCalendarID   => FAL_SCHEDULE_FUNCTIONS.GetSupplierCalendar(null)
                                       , aFromDate     => iDateBesoin
                                       , aDecalage     => round(iPDPParam.ControlDelay)
                                       , aForward      => 0
                                        );
    -- Calcul du délai de base à partir du délai intermédiaire
    ldFpdBasisDelay                            :=
      FAL_SCHEDULE_FUNCTIONS.GetDecalage(aPAC_SUPPLIER_PARTNER_ID   => iPDPParam.SupplierID
                                       , aCalendarID                => FAL_SCHEDULE_FUNCTIONS.GetSupplierCalendar(iPDPParam.SupplierID)
                                       , aFromDate                  => ldFpdIntermedDelay
                                       , aDecalage                  => round(iPDPParam.SupplyDelay)
                                       , aForward                   => 0
                                        );
    -- Recherche des partenaires du tiers
    DOC_DOCUMENT_FUNCTIONS.GetThirdPartners(aThirdID           => iPDPParam.SupplierID
                                          , aGaugeID           => lnDocGaugeID
                                          , aAdminDomain       => '1'
                                          , aThirdAciID        => lnThirdAciID
                                          , aThirdDeliveryID   => lnThirdDeliveryID
                                          , aThirdTariffID     => lnThirdTariffID
                                           );
    liFalDocProp.FAL_DOC_PROP_ID               := lnresult;
    liFalDocProp.C_PREFIX_PROP                 := lvCPrefixProp;
    liFalDocProp.FDP_NUMBER                    := liFDPNumber;
    liFalDocProp.FAL_PIC_ID                    := iFalPicID;
    liFalDocProp.FAL_PIC_LINE_ID               := nvl(iPrmFAL_PIC_LINE_ID, FAL_TOOLS.GetPicLineByNeed(iBesoin) );
    liFalDocProp.FDP_TEXTE                     := null;
    liFalDocProp.DOC_GAUGE_ID                  := lnDocGaugeID;
    liFalDocProp.PAC_SUPPLIER_PARTNER_ID       := iPDPParam.SupplierID;
    liFalDocProp.PAC_THIRD_ACI_ID              := lnThirdAciID;
    liFalDocProp.PAC_THIRD_DELIVERY_ID         := lnThirdDeliveryID;
    liFalDocProp.PAC_THIRD_TARIFF_ID           := lnThirdTariffID;
    liFalDocProp.GCO_GOOD_ID                   := iGcoGoodID;
    liFalDocProp.FDP_SECOND_REF                := lvFDPSecondRef;
    liFalDocProp.FDP_PSHORT_DESCR              := lvFDPPshortDescr;
    liFalDocProp.FDP_CONVERT_FACTOR            := iPDPParam.ConversionFactor;
    liFalDocProp.FDP_BASIS_QTY                 := iQtePDP;
    liFalDocProp.FDP_INTERMEDIATE_QTY          := iQteRebutPlanifie;
    liFalDocProp.FDP_FINAL_QTY                 := nvl(iQtePDP, 0) + nvl(iQteRebutPlanifie, 0);
    liFalDocProp.FDP_FINAL_DELAY               := iDateBesoin;
    liFalDocProp.FDP_INTERMEDIATE_DELAY        := ldFpdIntermedDelay;
    liFalDocProp.FDP_BASIS_DELAY               := ldFpdBasisDelay;
    liFalDocProp.DOC_RECORD_ID                 := null;
    liFalDocProp.STM_STOCK_ID                  := null;
    liFalDocProp.STM_LOCATION_ID               := null;
    liFalDocProp.STM_STM_STOCK_ID              := iStockDest;
    liFalDocProp.STM_STM_LOCATION_ID           := iLocationDest;
    liFalDocProp.GCO_CHARACTERIZATION1_ID      := null;
    liFalDocProp.GCO_CHARACTERIZATION2_ID      := null;
    liFalDocProp.GCO_CHARACTERIZATION3_ID      := null;
    liFalDocProp.GCO_CHARACTERIZATION4_ID      := null;
    liFalDocProp.GCO_CHARACTERIZATION5_ID      := null;
    liFalDocProp.FDP_CHARACTERIZATION_VALUE_1  := null;
    liFalDocProp.FDP_CHARACTERIZATION_VALUE_2  := null;
    liFalDocProp.FDP_CHARACTERIZATION_VALUE_3  := null;
    liFalDocProp.FDP_CHARACTERIZATION_VALUE_4  := null;
    liFalDocProp.FDP_CHARACTERIZATION_VALUE_5  := null;
    liFalDocProp.FAL_SUPPLY_REQUEST_ID         := null;
    liFalDocProp.A_DATECRE                     := sysdate;
    liFalDocProp.A_IDCRE                       := PCS.PC_I_LIB_SESSION.GetUserIni;
    FAL_NEEDCALCUL_PROCESSUS.InsertFalDocProp(liFalDocProp);
    return lnresult;
  end CreatePMPPurchaseProp;

/*-----------------------------------------------------------------------------------
                                    Calcul PDP Comment
-----------------------------------------------------------------------------------*/
  procedure CalcPMPComment(
    iListOfStock       varchar2
  , PDPParam           FAL_I_LIB_MRP_CALCULATION.TMrpProductParam
  , GcoGoodID          number
  , QtePDP             number
  , QteRebutPlanifie   number
  , Besoin             number
  , DateBesoin         date
  , iFalPicID          number
  , QteaAttribuerStock number
  , aFalPicLineId      number default null
  )
  is
    nFalLotPropId       number;
    nFalDocPropId       number;
    nDocRecordId        number;
    nStockConsoId       number;
    nFalNetworkSupplyId number;
    NonUtilise          number;
  begin
    if    (PDPParam.cSupplyMode = '2')
       or (PDPParam.cSupplyMode = '4') then   -- Calcul PDP Comment --1--
      -- produit fabriqué ou sous-traitance d'achat
      FAL_PRC_FAL_LOT_PROP.CreateFalLotProp(ioFalLotPropID           => nFalLotPropId
                                          , ioDocRecordID            => nDocRecordId
                                          , ioStockConsoID           => nStockConsoId
                                          , ioFalNetworkSupplyId     => nFalNetworkSupplyId
                                          , iCSupplyMode             => PDPParam.cSupplyMode
                                          , icSchedulePlanCode       => PDPParam.cSchedulePlanCode
                                          , iDicFabConditionID       => PDPParam.FabConditionID
                                          , iFalSchedulePlanID       => PDPParam.SchedulePlanID
                                          , iFalSchedPlanIDFromNom   => PDPParam.SchedulePlanIDFromNom
                                          , iCTypeProp               => '3'   -- type plan directeur
                                          , iFalNetworkNeedID        => Besoin
                                          , iGcoGoodID               => GcoGoodID
                                          , iOriginStockID           => null
                                          , iOriginLocationID        => null
                                          , iTargetStockID           => PDPParam.StockId
                                          , iTargetLocationID        => PDPParam.LocationId
                                          , iNeedDate                => DateBesoin
                                          , iAskedQty                => QtePDP
                                          , iPlannedTrashQty         => QteRebutPlanifie
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
                                          , iText                    => null
                                          , iSupplyRequestID         => 0
                                          , iFAL_PIC_LINE_ID         => aFalPicLineId
                                          , iSecurityDelay           => PDPParam.SecurityDelay
                                          , iCreateTaskList          => 1
                                          , iExecPlanning            => 1
                                          , iCreateComponent         => 1
                                          , iCreateNetwork           => 1
                                          , iCBSelectedStocks        => iListOfStock
                                          , iPpsNomenclatureId       => PDPParam.NomenclatureID
                                          , iStandardLotQty          => PDPParam.StandardLotQty
                                          , iFixedDuration           => PDPParam.FixedDuration
                                          , iGcoComplDataManufID     => PDPParam.AdditionalDataId
                                           );
    else   -- Mode d'approvisionnement <> 2
      -- Processus Création proposition appro logistique PDP (P2)
      nFalDocPropId  :=
        CreatePMPPurchaseProp(iFalPicID
                            , GcoGoodID
                            , PDPParam.StockId
                            , PDPParam.LocationId
                            , QtePDP
                            , QteRebutPlanifie
                            , Besoin
                            , DateBesoin
                            , PDPParam
                            , aFalPicLineId
                             );
      -- Processus Création réseaux appro. proposition appro. logistique (P3)
      FAL_NETWORK_DOC.CreateReseauApproPropApproLog(nFalDocPropId, NonUtilise);

      select FAL_NETWORK_SUPPLY_ID
        into nFalNetworkSupplyId
        from FAL_NETWORK_SUPPLY
       where FAL_DOC_PROP_ID = nFalDocPropId;
    end if;

    if nvl(QteaAttribuerStock, 0) <> 0 then
      FAL_NETWORK.CreateAttribApproStock(nFalNetworkSupplyId, PDPParam.LocationId, QteaAttribuerStock);
    end if;
  end CalcPMPComment;

/*-----------------------------------------------------------------------------------
                                    Calcul PDP Combien
-----------------------------------------------------------------------------------*/

  -- Test si aValue est un multiple de Divisor
  -- renvoie 1 si oui, 0 si non
  function isMultiple(aValue number, Divisor number)
    return number
  is
    -- Déclaration des variables
    result number;
  begin
    result  := aValue / Divisor - trunc(aValue / Divisor);

    if result = 0 then
      result  := 1;
    else
      result  := 0;
    end if;

    return result;
  end isMultiple;

  procedure CalcPMPQuantity(
    GcoGoodID    number   -- Produit
  , NeedQty      number   -- Qté besoin
  , Besoin       number   -- Besoin
  , DateBesoin   date   -- Date besoin
  , PDPParam     FAL_I_LIB_MRP_CALCULATION.TMrpProductParam   -- Paramètres PDP du produit
  , iFalPicID    number   -- PIC origine
  , PICWithOpen  FAL_PIC.PIC_WITH_OPEN%type
  , iListOfStock varchar2
  )
  is
    QteBesoin     number;
    QteRebut      number;
    X             number;
    RL            number;
    NBeforeLoop   number;
    N             number;
    aLocalNeedQty number;
  begin
    -- Conversion des quantités en unité d'approvisionnement
    QteBesoin  := round(nvl(NeedQty, 0) / FAL_TOOLS.NVLA(PDPParam.ConversionFactor, 1), PDPParam.DecimalNumber);
    QteRebut   :=
      FAL_TOOLS.ArrondiSuperieur(nvl(QteBesoin, 0) * PDPParam.TrashPercent / 100 +
                                 FAL_TOOLS.RoundSuccInt( (QteBesoin / FAL_TOOLS.NVLA(PDPParam.LossReferenceQty, 1) ) ) * PDPParam.TrashFixedQty
                               , GcoGoodId
                                );
    QteRebut   := nvl(QteRebut, 0);

    -- Qté selon besoin
    if    (PicWithOpen = 0)
       or (PDPParam.cQtySupplyRule = '1') then
      CalcPMPComment(iListOfStock
                   , PDPParam   -- Paramètres PDP du produit
                   , GcoGoodID   -- Produit
                   , QteBesoin   -- Quantité PDP
                   , QteRebut   -- Quantité rebut planifié
                   , Besoin   -- Besoin
                   , DateBesoin   -- Date besoin
                   , iFalPicID   -- PIC origine
                   , 0
                    );
    else
      -- Qté économique
      if PDPParam.cQtySupplyRule = '2' then
        -- Lot d'approvisionnement
        if PDPParam.cEconomicalQtyCode = '1' then
          if isMultiple(QteBesoin + QteRebut, PDPParam.EconomicalQty) = 0 then
            X          := FAL_TOOLS.RoundSuccInt( (QteBesoin + QteRebut) / FAL_TOOLS.NVLA(PDPParam.EconomicalQty, 1) ) * PDPParam.EconomicalQty;
            QteRebut   :=
              FAL_TOOLS.ArrondiSuperieur( (X * PDPParam.TrashPercent / 100) +
                                         (FAL_TOOLS.RoundSuccInt(X / FAL_TOOLS.NVLA(PDPParam.LossReferenceQty, 1) ) * PDPParam.TrashFixedQty
                                         )
                                       , GcoGoodId
                                        );
            QteRebut   := nvl(QteRebut, 0);
            QteBesoin  := X - QteRebut;
          end if;

          CalcPMPComment(iListOfStock
                       , PDPParam   -- Paramètres PDP du produit
                       , GcoGoodID   -- Produit
                       , QteBesoin   -- Quantité PDP
                       , QteRebut   -- Quantité rebut planifié
                       , Besoin   -- Besoin
                       , DateBesoin   -- Date besoin
                       , iFalPicID   -- PIC origine
                       , 0
                        );
        end if;

        -- Qté minimale d'approvisionnement
        if PDPParam.cEconomicalQtyCode = '2' then
          if (nvl(QteBesoin, 0) + nvl(QteRebut, 0) ) < PDPParam.EconomicalQty then
            X          := PDPParam.EconomicalQty;
            QteRebut   :=
              FAL_TOOLS.ArrondiSuperieur( (X * PDPParam.TrashPercent / 100) +
                                         (FAL_TOOLS.RoundSuccInt(X / FAL_TOOLS.NVLA(PDPParam.LossReferenceQty, 1) ) * PDPParam.TrashFixedQty
                                         )
                                       , GcoGoodId
                                        );
            QteRebut   := nvl(QteRebut, 0);
            QteBesoin  := X - QteRebut;
          end if;

          CalcPMPComment(iListOfStock
                       , PDPParam   -- Paramètres PDP du produit
                       , GcoGoodID   -- Produit
                       , QteBesoin   -- Quantité PDP
                       , QteRebut   -- Quantité rebut planifié
                       , Besoin   -- Besoin
                       , DateBesoin   -- Date besoin
                       , iFalPicID   -- PIC origine
                       , 0
                        );
        end if;

        -- Lot multiple
        if    PDPParam.cEconomicalQtyCode = '3'
           or PDPParam.cEconomicalQtyCode = '4' then
          RL           :=
            FAL_TOOLS.ArrondiSuperieur( (PDPParam.EconomicalQty * PDPParam.TrashPercent / 100) +
                                       (FAL_TOOLS.roundSuccInt(PDPParam.EconomicalQty / FAL_TOOLS.nvlA(PDPParam.LossReferenceQty, 1) ) * PDPParam.TrashFixedQty
                                       )
                                     , GcoGoodId
                                      );

          if PDPParam.cEconomicalQtyCode = '3' then
            N  := trunc(QteBesoin / FAL_TOOLS.nvla(PDPParam.EconomicalQty, 1) );
          end if;

          if PDPParam.cEconomicalQtyCode = '4' then
            if FAL_TOOLS.FRAC(QteBesoin / fal_tools.nvla(PDPParam.EconomicalQty, 1) ) > 0 then
              N  := trunc(QteBesoin / fal_tools.nvla(PDPParam.EconomicalQty, 1) ) + 1;
            else
              N  := QteBesoin / fal_tools.nvla(PDPParam.EconomicalQty, 1);
            end if;
          end if;

          NbeforeLoop  := N;

          while N > 0 loop
            CalcPMPComment(iListOfStock
                         , PDPParam   -- Paramètres PDP du produit
                         , GcoGoodID   -- Produit
                         , PDPParam.EconomicalQty   -- Quantité PDP
                         , RL   -- Quantité rebut planifié
                         , Besoin   -- Besoin
                         , DateBesoin   -- Date besoin
                         , iFalPicID   -- PIC origine
                         , 0
                          );
            N  := N - 1;
          end loop;

          -- ce qui suit est en fait la branche toute à gauche dans le graph
          if     (PDPParam.cEconomicalQtyCode = '3')
             and (QteBesoin -(NbeforeLoop * PDPParam.EconomicalQty) > 0) then
            aLocalNeedQty  := QteBesoin -(NbeforeLoop * PDPParam.EconomicalQty);
            QteRebut       :=
              FAL_TOOLS.ArrondiSuperieur( (aLocalNeedQty * PDPParam.TrashPercent / 100) +
                                         (FAL_TOOLS.RoundSuccInt(aLocalNeedQty / fal_tools.nvla(PDPParam.LossReferenceQty, 1) ) * PDPParam.TrashFixedQty
                                         )
                                       , GcoGoodId
                                        );
            QteRebut       := nvl(QteRebut, 0);
            CalcPMPComment(iListOfStock
                         , PDPParam   -- Paramètres PDP du produit
                         , GcoGoodID   -- Produit
                         , aLocalNeedQty   -- Quantité PDP
                         , QteRebut   -- Quantité rebut planifié
                         , Besoin   -- Besoin
                         , DateBesoin   -- Date besoin
                         , iFalPicID   -- PIC origine
                         , 0
                          );
          end if;
        end if;
      end if;
    end if;
  end CalcPMPQuantity;

  procedure DeleteNeedOnGoodAndPicLine(iFalPicID FAL_PIC.FAL_PIC_ID%type)
  is
    aFAL_NETWORK_NEED_ID FAL_NETWORK_NEED.FAL_NETWORK_NEED_ID%type;

    -- Need de produits et du PIC
    cursor CNeedOfGoodAndPic
    is
      select FAL_NETWORK_NEED_ID
        from FAL_NETWORK_NEED
       where FAL_LOT_PROP_ID is null
         and FAL_LOT_ID is null
         and DOC_POSITION_ID is null
         and FAL_PIC_LINE_ID is not null;
  begin
    open CNeedOfGoodAndPic;

    loop
      fetch CNeedOfGoodAndPic
       into aFAL_NETWORK_NEED_ID;

      exit when CNeedOfGoodAndPic%notfound;
      -- On supprime d'abord les éventuelles attribs
      FAL_NETWORK.Attribution_Suppr_BesoinAppro(aFAL_NETWORK_NEED_ID);
      FAL_NETWORK.Attribution_Suppr_BesoinStock(aFAL_NETWORK_NEED_ID);

      -- Suppression du Need...
      delete from FAL_NETWORK_NEED
            where FAL_NETWORK_NEED_ID = aFAL_NETWORK_NEED_ID;
    end loop;

    close CNeedOfGoodAndPic;
  end DeleteNeedOnGoodAndPicLine;

  /**
   * function GetPrevExistingSupply
   * Description : retourne une table d'Id d'appros type plan directeur
   */
  function GetPrevExistingSupply
    return ID_TABLE_TYPE pipelined deterministic
  is
  begin
    if TabExistingSupply.count > 0 then
      for i in TabExistingSupply.first .. TabExistingSupply.last loop
        pipe row(TabExistingSupply(i) );
      end loop;
    end if;
  end;

  procedure CalcPMP2(iFalPicID number, CallFromCBstandard boolean, iListOfStock varchar2)
  is
    -- Chaque produit de la table des niveaux où N = 0
    cursor lcrMasterPlanProductLevel0
    is
      select   FPL.GCO_GOOD_ID
             , PROD.C_SUPPLY_MODE
             , PROD.STM_STOCK_ID
             , PROD.STM_LOCATION_ID
             , PIC.DIC_FAB_CONDITION_ID
             , (select count(*)
                  from FAL_PDP_LEVEL
                 where GCO_GOOD_ID = FPL.GCO_GOOD_ID) GOOD_IN_LEVEL
          from FAL_PDP_LEVEL FPL
             , GCO_PRODUCT PROD
             , (select DIC_FAB_CONDITION_ID
                  from FAL_PIC
                 where FAL_PIC_ID = iFalPicID) PIC
         where FPD_LEVEL = 0
           and FPL.GCO_GOOD_ID = PROD.GCO_GOOD_ID
      order by GCO_GOOD_ID;

    -- Sélection des lignes de PIC
    cursor lcrPicLine(GcoGoodID number)
    is
      select   FAL_PIC_LINE_ID
             , nvl(PIL_PDP_QTY, 0) PIL_PDP_QTY
             , case to_number(PCS.PC_Config.GetConfig('FAL_PIC_WEEK_MONTH') )
                 when 1 then to_date(lpad(PCS.PC_Config.GetConfig('FAL_PIC_DATE_BEGIN'), 2, '0') || '/' || to_char(PIL_DATE, 'MM/YYYY'), 'DD/MM/YYYY')
                 else PIL_DATE - to_number(PCS.PC_Config.GetConfig('DOC_DELAY_WEEKSTART') ) + to_number(PCS.PC_Config.GetConfig('FAL_PIC_DATEW_BEGIN') )
               end REQUIREMENT_DATE
          from FAL_PIC_LINE FPL
             , FAL_PIC FP
         where FPL.FAL_PIC_ID = FP.FAL_PIC_ID
           and FP.FAL_PIC_ID = iFalPicID
           and GCO_GOOD_ID = GcoGoodID
           and PIL_DATE >= PIC_VALID_BEGIN_DATE
           and PIL_DATE <= PIC_VALID_END_DATE
           and PIL_PDP_QTY > 0
      order by PIL_DATE asc;

    -- Les produits de la table des niveaux où
    -- N > 0 pris dans l'ordre des niveaux croissant
    cursor lcrMasterPlanProductLevelN
    is
      select   FPL.GCO_GOOD_ID
             , PROD.C_SUPPLY_MODE
             , PIC.DIC_FAB_CONDITION_ID
             , PIC.PIC_WITH_OPEN
          from FAL_PDP_LEVEL FPL
             , GCO_PRODUCT PROD
             , (select DIC_FAB_CONDITION_ID
                     , nvl(PIC_WITH_OPEN, 0) PIC_WITH_OPEN
                  from FAL_PIC
                 where FAL_PIC_ID = iFalPicID) PIC
         where FPD_LEVEL > 0
           and FPL.GCO_GOOD_ID = PROD.GCO_GOOD_ID
      order by FPD_LEVEL
             , GCO_GOOD_ID;

    -- Sélection des besoins de type PDP
    cursor lcrRequirements(GcoGoodID number)
    is
      select   NEED1.FAL_NETWORK_NEED_ID
             , NEED1.FAN_FREE_QTY
             , NEED1.FAN_BEG_PLAN
             , NEED1.FAN_BALANCE_QTY
             , NEED1.FAL_LOT_PROP_ID
          from FAL_NETWORK_NEED NEED1
             , STM_STOCK STK1
         where GCO_GOOD_ID = GcoGoodID
           and NEED1.STM_STOCK_ID = STK1.STM_STOCK_ID
           and STO_NEED_PIC = 1
           and C_GAUGE_TITLE = gcFalTitlePlanDir
      order by FAN_BEG_PLAN
             , FAL_LOT_PROP_ID;

    PDPParam           FAL_I_LIB_MRP_CALCULATION.TMrpProductParam;
    QtePDP             number;
    TOT                number;
    TotProp            number;
    N                  number;
    QteRebut           number;
    RL                 number;
    Y                  number;
    aLocalNeedQty      number;
    QteaAttribuerStock number;
    aStockID           STM_STOCK.STM_STOCK_ID%type;
    aLocationID        STM_LOCATION.STM_LOCATION_ID%type;
    lAvailable         STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type;
    lStockMini         GCO_COMPL_DATA_STOCK.CST_QUANTITY_MIN%type;
    lST                STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type;
    lSumProcurementQty FAL_NETWORK_SUPPLY.FAN_FREE_QTY%type;
    lSumFreeQty        FAL_NETWORK_NEED.FAN_FREE_QTY%type;
  begin
    -- Chaque produit de la table des niveaux où N = 0
    for ltplMasterPlanProductLevel0 in lcrMasterPlanProductLevel0 loop
      -- Initialisation des paramètres PDP du produit
      PDPParam  :=
        FAL_I_LIB_MRP_CALCULATION.GetProductParameters(iGcoGoodId           => ltplMasterPlanProductLevel0.GCO_GOOD_ID
                                                     , iCSupplyMode         => ltplMasterPlanProductLevel0.C_SUPPLY_MODE
                                                     , iDicFabConditionId   => ltplMasterPlanProductLevel0.DIC_FAB_CONDITION_ID
                                                      );

      -- Si le produit est au moins 2 fois dans la table des niveau
      if ltplMasterPlanProductLevel0.GOOD_IN_LEVEL > 1 then
        -- Déterminer le STOCK et l'EMPLACEMENT à stocker dans les réseaux
        aStockID     := ltplMasterPlanProductLevel0.STM_STOCK_ID;
        aLocationID  := ltplMasterPlanProductLevel0.STM_LOCATION_ID;
        FAL_NETWORK.SetDefaultStockAndLocation(aStockID, aLocationID, gcDefaultStockID, gcDefaultLocationID);

        -- Créer un besoin pour chaque ligne de PIC du produit dans la période en cours (résolution de JPA pour les Problèmes EMS)
        insert into FAL_NETWORK_NEED
                    (FAL_NETWORK_NEED_ID
                   , FAL_PIC_LINE_ID
                   , GCO_GOOD_ID
                   , FAN_BEG_PLAN
                   , FAN_END_PLAN
                   , STM_STOCK_ID
                   , STM_LOCATION_ID
                   , C_GAUGE_TITLE
                   , FAN_PREV_QTY
                   , FAN_BALANCE_QTY
                   , FAN_FREE_QTY
                   , FAN_DESCRIPTION
                   , FAN_STK_QTY
                   , A_DATECRE
                   , A_IDCRE
                    )
          select GetNewId
               , FAL_PIC_LINE_ID
               , GCO_GOOD_ID
               , PIL_DATE
               , PIL_DATE
               , aStockID
               , aLocationID
               , gcFalTitlePlanDir
               , PIL_PREV_QTY - PIL_ORDER_QTY
               , PIL_PREV_QTY - PIL_ORDER_QTY
               , PIL_PREV_QTY - PIL_ORDER_QTY
               , FP.PIC_REFERENCE
               , 0
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
            from FAL_PIC_LINE FPL
               , FAL_PIC FP
           where FPL.FAL_PIC_ID = FP.FAL_PIC_ID
             and FP.FAL_PIC_ID = iFalPicID
             and GCO_GOOD_ID = ltplMasterPlanProductLevel0.GCO_GOOD_ID
             and PIL_DATE >= PIC_VALID_BEGIN_DATE
             and PIL_DATE <= PIC_VALID_END_DATE
             and nvl(PIL_PREV_QTY, 0) - nvl(PIL_ORDER_QTY, 0) > 0;
      else
        -- Le produit n'est pas deux fois dans la table des niveaux.
        -- Sélection des lignes de PIC
        for ltplPicLine in lcrPicLine(ltplMasterPlanProductLevel0.GCO_GOOD_ID) loop
          -- Conversion des quantités en unité d'approvisionnement
          QtePDP    := round(ltplPicLine.PIL_PDP_QTY / fal_tools.NVLA(PDPParam.ConversionFactor, 1), PDPParam.DecimalNumber);
          QteRebut  :=
            FAL_TOOLS.ArrondiSuperieur(FAL_TOOLS.CalcTotalTrashQuantity(aAskedQty            => QtePDP
                                                                      , aTrashPercent        => PDPParam.TrashPercent
                                                                      , aTrashFixedQty       => PDPParam.TrashFixedQty
                                                                      , aTrashReferenceQty   => PDPParam.LossReferenceQty
                                                                       )
                                     , ltplMasterPlanProductLevel0.GCO_GOOD_ID
                                      );

          if    (PDPParam.cEconomicalQtyCode = 3)
             or (PDPParam.cEconomicalQtyCode = 4) then
            -- Calcul de RL
            Y   := FAL_TOOLS.RoundSuccInt(PDPParam.EconomicalQty / fal_tools.nvla(PDPParam.LossReferenceQty, 1) );
            RL  :=
              FAL_TOOLS.ArrondiSuperieur( (PDPParam.EconomicalQty * PDPParam.TrashPercent / 100) +(Y * PDPParam.TrashFixedQty)
                                       , ltplMasterPlanProductLevel0.GCO_GOOD_ID
                                        );

            if PDPParam.cEconomicalQtyCode = '3' then
              N  := trunc(QtePDP / fal_tools.nvla(PDPParam.EconomicalQty, 1) );
            end if;

            if PDPParam.cEconomicalQtyCode = '4' then
              if FAL_TOOLS.FRAC(QtePDP / fal_tools.nvla(PDPParam.EconomicalQty, 1) ) > 0 then
                N  := trunc(nvl(QtePDP, 0) / fal_tools.nvla(PDPParam.EconomicalQty, 1) ) + 1;
              else
                N  := nvl(QtePDP, 0) / fal_tools.nvla(PDPParam.EconomicalQty, 1);
              end if;
            end if;

            if (QtePDP -(N * PDPParam.EconomicalQty) ) > 0 then
              if PDPParam.cEconomicalQtyCode = 3 then
                -- Lot multiple (Analyse JPA = N > 0 NON)
                aLocalNeedQty       := QtePDP -(N * PDPParam.EconomicalQty);

                if PDPParam.ModuloQty <> 0 then
                  aLocalNeedQty  := FAL_TOOLS.ArrondiSupSelonModulo(aLocalNeedQty, PDPParam.ModuloQty);
                end if;

                -- Déterminet la Qté Rebut
                QteRebut            :=
                  FAL_TOOLS.ArrondiSuperieur(FAL_TOOLS.CalcTotalTrashQuantity(aAskedQty            => aLocalNeedQty
                                                                            , aTrashPercent        => PDPParam.TrashPercent
                                                                            , aTrashFixedQty       => PDPParam.TrashFixedQty
                                                                            , aTrashReferenceQty   => PDPParam.LossReferenceQty
                                                                             )
                                           , ltplMasterPlanProductLevel0.GCO_GOOD_ID
                                            );
                QteaAttribuerStock  := 0;
                CalcPMPComment(iListOfStock
                             , PDPParam   -- Paramètres PDP du produit
                             , ltplMasterPlanProductLevel0.GCO_GOOD_ID   -- Produit
                             , aLocalNeedQty   -- Quantité PDP
                             , QteRebut   -- Quantité rebut planifié
                             , null   -- Besoin
                             , ltplPicLine.REQUIREMENT_DATE
                             , iFalPicID   -- PIC origine
                             , QteaAttribuerStock
                             , ltplPicLine.FAL_PIC_LINE_ID
                              );
              else
                QteaAttribuerStock  := 0;
                -- PDPParam.cEconomicalQtyCode = 4
                -- Lot multiple arrondi (Par rapport à Code Qté économiqe = 3, on fait
                -- un COMMENT de plus avec QtéDemandé = QtéEconomique)
                CalcPMPComment(iListOfStock
                             , PDPParam   -- Paramètres PDP du produit
                             , ltplMasterPlanProductLevel0.GCO_GOOD_ID
                             , PDPParam.EconomicalQty   -- Quantité PDP
                             , RL   -- Quantité rebut planifié
                             , null   -- Besoin
                             , ltplPicLine.REQUIREMENT_DATE
                             , iFalPicID   -- PIC origine
                             , QteaAttribuerStock
                             , ltplPicLine.FAL_PIC_LINE_ID
                              );
              end if;
            end if;

            loop
              exit when N <= 0;
              QteaAttribuerStock  := 0;
              CalcPMPComment(iListOfStock
                           , PDPParam   -- Paramètres PDP du produit
                           , ltplMasterPlanProductLevel0.GCO_GOOD_ID   -- Produit
                           , PDPParam.EconomicalQty   -- Quantité PDP
                           , RL   -- Quantité rebut planifié
                           , null   -- Besoin
                           , ltplPicLine.REQUIREMENT_DATE
                           , iFalPicID   -- PIC origine
                           , QteaAttribuerStock
                           , ltplPicLine.FAL_PIC_LINE_ID
                            );
              N                   := N - 1;
            end loop;
          else
            QteaAttribuerStock  := 0;
            CalcPMPComment(iListOfStock
                         , PDPParam   -- Paramètres PDP du produit
                         , ltplMasterPlanProductLevel0.GCO_GOOD_ID   -- Produit
                         , QtePDP   -- Quantité PDP
                         , nvl(QteRebut, 0)   -- Quantité rebut planifié
                         , null   -- Besoin
                         , ltplPicLine.REQUIREMENT_DATE
                         , iFalPicID   -- PIC origine
                         , QteaAttribuerStock
                         , ltplPicLine.FAL_PIC_LINE_ID
                          );
          end if;
        end loop;
      end if;   -- Fin de Le produit n'est pas deux fois dans la table des niveaux.
    end loop;

    if not CallFromCBstandard then
      -- Pour chaque produit de la table des niveaux où
      -- N > 0 pris dans l'ordre des niveaux croissant
      for ltplMasterPlanProductLevelN in lcrMasterPlanProductLevelN loop
        TabExistingSupply  := null;

        select FAL_NETWORK_SUPPLY_ID
        bulk collect into TabExistingSupply
          from FAL_NETWORK_SUPPLY
         where GCO_GOOD_ID = ltplMasterPlanProductLevelN.GCO_GOOD_ID
           and C_GAUGE_TITLE = gcFalTitlePlanDir;

        -- Initialisation des paramètres PDP du produit
        PDPParam           :=
          FAL_I_LIB_MRP_CALCULATION.GetProductParameters(iGcoGoodId           => ltplMasterPlanProductLevelN.GCO_GOOD_ID
                                                       , iCSupplyMode         => ltplMasterPlanProductLevelN.C_SUPPLY_MODE
                                                       , iDicFabConditionId   => ltplMasterPlanProductLevelN.DIC_FAB_CONDITION_ID
                                                        );
        TotProp            := 0;

        for ltplRequirements in lcrRequirements(ltplMasterPlanProductLevelN.GCO_GOOD_ID) loop
          -- Sélection des positions de stock pour le produit sur les stocks PDP
          -- et somme des qtéDisponible + QtéEntréeProvisoire (= ST)
          -- et prise en compte des critères FDA
          case ltplMasterPlanProductLevelN.PIC_WITH_OPEN
            when 1 then
              select nvl(sum(nvl(SPO_AVAILABLE_QUANTITY, 0) + nvl(SPO_PROVISORY_INPUT, 0) ), 0)
                into lAvailable
                from STM_STOCK_POSITION SSP
                   , STM_STOCK SS
               where SSP.GCO_GOOD_ID = ltplMasterPlanProductLevelN.GCO_GOOD_ID
                 and STM_I_LIB_MOVEMENT.VerifyForecastStockCond(SSP.STM_STOCK_POSITION_ID, ltplRequirements.FAN_BEG_PLAN) = 1
                 and SSP.STM_STOCK_ID = SS.STM_STOCK_ID
                 and STO_NEED_PIC = 1;

              select nvl(sum(CST_QUANTITY_MIN), 0)
                into lStockMini
                from GCO_COMPL_DATA_STOCK GCDS
                   , STM_STOCK SS
               where GCO_GOOD_ID = ltplMasterPlanProductLevelN.GCO_GOOD_ID
                 and CST_QUANTITY_MIN > 0
                 and GCDS.STM_STOCK_ID = SS.STM_STOCK_ID
                 and STO_NEED_PIC = 1;

              lST  := lAvailable - lStockMini;
            else
              lST  := 0;
          end case;

          -- Pour chaque besoin sélectionnné
          if ltplMasterPlanProductLevelN.PIC_WITH_OPEN = 1 then
        /* Somme des appros libres précédent le besoin pour le produit sur les stocks PDP */
            select nvl(sum(nvl(FAN_FREE_QTY, 0) + nvl(FAN_STK_QTY, 0) ), 0)
              into lSumProcurementQty
              from FAL_NETWORK_SUPPLY FNS
                 , STM_STOCK SS
             where GCO_GOOD_ID = ltplMasterPlanProductLevelN.GCO_GOOD_ID
               and FNS.STM_STOCK_ID = SS.STM_STOCK_ID
               and STO_NEED_PIC = 1
               and trunc(FAN_END_PLAN) <= trunc(ltplRequirements.FAN_BEG_PLAN)
               and FAL_NETWORK_SUPPLY_ID not in(select column_value
                                                  from table(GetPrevExistingSupply) );

            /* Somme des besoins libres précédent le besoin pour le produit sur les stocks PDP */
            select nvl(sum(NEED.FAN_FREE_QTY), 0)
              into lSumFreeQty
              from FAL_NETWORK_NEED NEED
                 , STM_STOCK STK2
             where GCO_GOOD_ID = ltplMasterPlanProductLevelN.GCO_GOOD_ID
               and NEED.STM_STOCK_ID = STK2.STM_STOCK_ID
               and STO_NEED_PIC = 1
               and FAN_FREE_QTY > 0
               and (    (trunc(FAN_BEG_PLAN) < trunc(ltplRequirements.FAN_BEG_PLAN) )
                    or (    trunc(FAN_BEG_PLAN) = trunc(ltplRequirements.FAN_BEG_PLAN)
                        and FAL_LOT_PROP_ID < ltplRequirements.FAL_LOT_PROP_ID)
                   );

            TOT  := (nvl(lST, 0) + lSumProcurementQty)   -- total appro
                                                      -(lSumFreeQty + ltplRequirements.FAN_FREE_QTY);   -- total besoins

            if TOT < 0 then
              TotProp  := TotProp +(TOT * -1);
              CalcPMPQuantity(ltplMasterPlanProductLevelN.GCO_GOOD_ID   -- Produit
                            , -TOT   -- Qté besoin
                            , ltplRequirements.FAL_NETWORK_NEED_ID
                            , ltplRequirements.FAN_BEG_PLAN
                            , PDPParam   -- Paramètres PDP du produit
                            , iFalPicID   -- PIC origine
                            , ltplMasterPlanProductLevelN.PIC_WITH_OPEN   -- PDP avec en cours
                            , iListOfStock
                             );
            end if;
          else
            CalcPMPQuantity(ltplMasterPlanProductLevelN.GCO_GOOD_ID   -- Produit
                          , ltplRequirements.FAN_BALANCE_QTY
                          , ltplRequirements.FAL_NETWORK_NEED_ID
                          , ltplRequirements.FAN_BEG_PLAN
                          , PDPParam   -- Paramètres PDP du produit
                          , iFalPicID   -- PIC origine
                          , ltplMasterPlanProductLevelN.PIC_WITH_OPEN   -- PDP avec en cours
                          , iListOfStock
                           );
          end if;
        end loop;
      end loop;
    end if;   -- Fin de if NOT CallFromCBstandard
  end CalcPMP2;

-- Procédure de calcul plan directeur, appelée depuis le calcul des besoins standard
  procedure CalcPMP2_2(iFalPicID number, iListOfStock varchar2)
  is
  begin
    UpdateOrdersActiveMasterPlan;
    -- Supprimer les besoins exprimés pour ce PIC
    DeleteNeedOnGoodAndPicLine(iFalPicID);
    -- TRUE: Appelé depuis le CB Standard.
    CalcPMP2(iFalPicID, true, iListOfStock);
  end CalcPMP2_2;

/*-----------------------------------------------------------------------------------
                              Calcul Plan Directeur
-----------------------------------------------------------------------------------*/
  procedure CalcPMP1(iFalPicID number)
  is
    vListOfStock varchar2(32000);
  begin
    if upper(PCS.PC_Config.GetConfig('FAL_PIC_DELETE_PDX') ) = 'TRUE' then
      FAL_PRC_FAL_PROP_COMMON.DeletePropositions(iDeletePropMode           => FAL_PRC_FAL_PROP_COMMON.DELETE_PROP
                                               , iDeleteRequestMode        => FAL_PRC_FAL_PROP_COMMON.NO_DELETE_REQUEST
                                               , iUpdateRequestvalueMode   => FAL_PRC_FAL_PROP_COMMON.NO_UPDATE_REQUEST
                                               , iPropOrigin               => FAL_PRC_FAL_PROP_COMMON.PDA_PROP
                                                );
      FAL_PRC_FAL_PROP_COMMON.DeletePropositions(iDeletePropMode           => FAL_PRC_FAL_PROP_COMMON.DELETE_PROP
                                               , iDeleteRequestMode        => FAL_PRC_FAL_PROP_COMMON.NO_DELETE_REQUEST
                                               , iUpdateRequestvalueMode   => FAL_PRC_FAL_PROP_COMMON.NO_UPDATE_REQUEST
                                               , iPropOrigin               => FAL_PRC_FAL_PROP_COMMON.PDF_PROP
                                                );
    end if;

    -- Le calcul d'un Plan Directeur supprime les PDP déjà créés (donc les PDP qui
    -- peuvent provenir d'un autre Plan Directeur. On met donc à 0 le champ
    -- PDP calculé de tous les autres Plans Directeur
    update FAL_PIC
       set PIC_PDP_CALCUL = 0
         , PIC_DATE_CALCUL = null
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni;

    -- Mise à jour du PIC
    update FAL_PIC
       set PIC_PDP_CALCUL = 1
         , PIC_DATE_CALCUL = sysdate
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_PIC_ID = iFalPicID;

    CalcPMPLevels(iFalPicID);

    for ltplStock in (select STM_STOCK_ID
                        from STM_STOCK
                       where STO_NEED_PIC = 1) loop
      vListOfStock  := vListOfStock || ltplStock.STM_STOCK_ID || ',';
    end loop;

    vListOfStock  := substr(vListOfStock, 1, length(vListOfStock) - 1);
    /* FALSE: Pas appelé depuis le CB Standard. La procedure CalcPMP1 est appelée depuis l'inetrface de gestion des plans directeurs */
    CalcPMP2(iFalPicID, false, vListOfStock);
  end CalcPMP1;

--------------------------------------------------------------------------------------------
-- Initialisation de la quantité de prévision -
--------------------------------------------------------------------------------------------
  function Init_Quantite(Produit_ID number, Representant number, Client FAL_PIC_LINE.PIL_GROUP_OR_THIRD%type, Pil_Date date, StoredProc_ID number)
    return number
  is
    result        number;
    NomStoredProc FAL_PIC_INIT_QTY.PIQ_STORED_PROC%type;
    vQuery        varchar2(32000);
    aVersion      integer;
  begin
    result  := 0;

    select max(PIQ_STORED_PROC)
      into NomStoredProc
      from FAL_PIC_INIT_QTY
     where FAL_PIC_INIT_QTY_ID = StoredProc_ID;

    if NomStoredProc is not null then
      vQuery  :=
        ' declare ' ||
        '   nQty number; ' ||
        ' begin ' ||
        NomStoredProc ||
        '(:Produit_ID, :Representant, :Client, :Pil_Date, nQty); ' ||
        '   :result := nQty; ' ||
        ' end;';

      execute immediate vQuery
                  using Produit_ID, nvl(Representant, 0), nvl(Client, '0'), Pil_Date, out result;
    end if;

    return result;
  end;

  function PartnerIsAGroup(Partner FAL_PIC_LINE.PIL_GROUP_OR_THIRD%type)
    return number
  is
    isGroup number;
  begin
    select count(1)
      into isGroup
      from dual
     where exists(select 1
                    from DIC_PIC_GROUP
                   where DIC_PIC_GROUP_ID = Partner);

    return isGroup;
  end PartnerIsAGroup;

--------------------------------------------------------------------------------------------
--  Fonction qui renvoie l'ID de la procédure stockée d'initialisation (FAL_PIC_INIT_QTY_ID)
--  Renvoie NULL si Initialisation Prevision (PIC_INIT_PREV) n'est pas actif
--------------------------------------------------------------------------------------------
  function SelectStoredProc(PicId number)
    return FAL_PIC.FAL_PIC_INIT_QTY_ID%type
  is
    -- Déclaration des curseurs
    cursor CUR_FAL_PIC(PicId number)
    is
      select PIC_INIT_PREV
           , FAL_PIC_INIT_QTY_ID
        from FAL_PIC
       where FAL_PIC_ID = PicId;

    -- Déclaration des variables
    result      FAL_PIC.FAL_PIC_INIT_QTY_ID%type;
    PicInitPrev FAL_PIC.PIC_INIT_PREV%type;
  begin
    result  := null;

    open CUR_FAL_PIC(PicId);

    fetch CUR_FAL_PIC
     into PicInitPrev
        , result;

    close CUR_FAL_PIC;

    if PicInitPrev = 0 then
      result  := null;
    end if;

    return result;
  end;

--------------------------------------------------------------------------------------------
--  Duplication des FAL_PIC_LINE. Lors de la duplication d'un PIC, on duplique les
--  FAL_PIC_LINE liés à ce PIC. On crée donc un nouvel enregistrement pour chaque
-- ligne avec FAL_PIC_ID = new PIC ID et PIL_ACTIF = 0
--------------------------------------------------------------------------------------------
  procedure DuplicatePicLine(Old_Pic_ID number, New_Pic_ID number, Copie_Prev number)
  is
    -- Déclaration des curseurs
    cursor CUR_PIC_LINE(Pic_ID number)
    is
      select PIL_STRUCTURE
           , PAC_REPRESENTATIVE_ID
           , PIL_GROUP_OR_THIRD
           , GCO_GCO_GOOD_ID
           , GCO_GOOD_ID
           , PIL_DATE
           , PIL_COEFF
           , PIL_PREV_QTY
           , PIL_ORDER_QTY
           , PIL_REAL_QTY
           , PIL_REVISION_QTY
           , PIL_PDP_QTY
           , PIL_REAL_VALUE
           , PIL_UNIT_VALUE
           , PIL_ALLKEY
           , PIL_CUSTOM_PARTNER
        from FAL_PIC_LINE
       where FAL_PIC_ID = Pic_ID;

    -- Déclaration des variables
    structure      FAL_PIC_LINE.PIL_STRUCTURE%type;
    Representant   FAL_PIC_LINE.PAC_REPRESENTATIVE_ID%type;
    Client         FAL_PIC_LINE.PIL_GROUP_OR_THIRD%type;
    ProduitPT      FAL_PIC_LINE.GCO_GCO_GOOD_ID%type;
    Produit        FAL_PIC_LINE.GCO_GOOD_ID%type;
    DateLigne      FAL_PIC_LINE.PIL_DATE%type;
    Coeff          FAL_PIC_LINE.PIL_COEFF%type;
    QtePrevue      FAL_PIC_LINE.PIL_PREV_QTY%type;
    QteCommande    FAL_PIC_LINE.PIL_ORDER_QTY%type;
    QteRealises    FAL_PIC_LINE.PIL_REAL_QTY%type;
    QteRevision    FAL_PIC_LINE.PIL_REVISION_QTY%type;
    QtePDP         FAL_PIC_LINE.PIL_PDP_QTY%type;
    ValeurRealisee FAL_PIC_LINE.PIL_REAL_VALUE%type;
    ValeurUnitaire FAL_PIC_LINE.PIL_UNIT_VALUE%type;
    IndexLigne     FAL_PIC_LINE.PIL_ALLKEY%type;
    DescrClient    FAL_PIC_LINE.PIL_CUSTOM_PARTNER%type;
    StoredProcId   FAL_PIC.FAL_PIC_INIT_QTY_ID%type;
  begin
    StoredProcId  := SelectStoredProc(Old_Pic_ID);

    open CUR_PIC_LINE(Old_Pic_ID);

    loop
      fetch CUR_PIC_LINE
       into structure
          , Representant
          , Client
          , ProduitPT
          , Produit
          , DateLigne
          , Coeff
          , QtePrevue
          , QteCommande
          , QteRealises
          , QteRevision
          , QtePDP
          , ValeurRealisee
          , ValeurUnitaire
          , IndexLigne
          , DescrClient;

      exit when CUR_PIC_LINE%notfound;

      if Copie_Prev = 0 then
        if StoredProcId is null then
          QtePrevue  := 0;
        else
          QtePrevue  := Init_Quantite(Produit, Representant, Client, DateLigne, StoredProcId);
        end if;
      end if;

      insert into FAL_PIC_LINE
                  (FAL_PIC_LINE_ID
                 , FAL_PIC_ID
                 , PIL_ACTIF
                 , PIL_STRUCTURE
                 , PAC_REPRESENTATIVE_ID
                 , PIL_GROUP_OR_THIRD
                 , GCO_GCO_GOOD_ID
                 , GCO_GOOD_ID
                 , PIL_DATE
                 , PIL_COEFF
                 , PIL_PREV_QTY
                 , PIL_ORDER_QTY
                 , PIL_REAL_QTY
                 , PIL_REVISION_QTY
                 , PIL_PDP_QTY
                 , PIL_REAL_VALUE
                 , PIL_UNIT_VALUE
                 , PIL_ALLKEY
                 , PIL_CUSTOM_PARTNER
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 ,   -- FAL_PIC_LINE_ID,
                   New_Pic_ID
                 ,   -- FAL_PIC_ID,
                   0
                 ,   -- PIL_ACTIF,
                   structure
                 ,   -- PIL_STRUCTURE,
                   Representant
                 ,   -- PAC_REPRESENTATIVE_ID,
                   Client
                 ,   -- PIL_GROUP_OR_THIRD,
                   ProduitPT
                 ,   -- GCO_GCO_GOOD_ID,
                   Produit
                 ,   -- GCO_GOOD_ID,
                   DateLigne
                 ,   -- PIL_DATE,
                   Coeff
                 ,   -- PIL_COEFF,
                   QtePrevue
                 ,   -- PIL_PREV_QTY,
                   QteCommande
                 ,   -- PIL_ORDER_QTY,
                   QteRealises
                 ,   -- PIL_REAL_QTY,
                   QteRevision
                 ,   -- PIL_REVISION_QTY,
                   QtePDP
                 ,   -- PIL_PDP_QTY,
                   ValeurRealisee
                 ,   -- PIL_REAL_VALUE,
                   ValeurUnitaire
                 ,   -- PIL_UNIT_VALUE,
                   IndexLigne
                 ,   -- PIL_ALLKEY,
                   DescrClient
                 ,   -- PIL_CUSTOM_PARTNER,
                   sysdate
                 ,   -- A_DATECRE,
                   PCS.PC_I_LIB_SESSION.GetUserIni
                  );   -- A_IDCRE
    end loop;

    close CUR_PIC_LINE;
  end DuplicatePicLine;

--------------------------------------------------------------------------------------------
-- Fonction qui vérifie si des FAL_PIC_LINE existe déjà pour les valeurs en cours
--------------------------------------------------------------------------------------------
  function NouvelleEntree(Pic_ID number, Representant number, Client FAL_PIC_LINE.PIL_GROUP_OR_THIRD%type, Produit_PT number, Produit_ID number)
    return boolean
  is
    -- Déclaration des variables
    NbreEnreg number;
    result    boolean;
  begin
    select count(1)
      into NbreEnreg
      from FAL_PIC_LINE
     where FAL_PIC_ID = Pic_ID
       and (    (    PAC_REPRESENTATIVE_ID is null
                 and Representant is null)
            or (PAC_REPRESENTATIVE_ID = Representant) )
       and (    (    PIL_GROUP_OR_THIRD is null
                 and Client is null)
            or (PIL_GROUP_OR_THIRD = Client) )
       and (    (    GCO_GCO_GOOD_ID is null
                 and Produit_PT is null)
            or (GCO_GCO_GOOD_ID = Produit_PT) )
       and GCO_GOOD_ID = Produit_ID;

    if NbreEnreg = 0 then
      result  := true;
    else
      result  := false;
    end if;

    return result;
  end;

--------------------------------------------------------------------------------------------
-- Fonction qui retourne la date de début d'un PC
--------------------------------------------------------------------------------------------
  function DateDebutPC(Pic_ID number)
    return date
  is
    -- Déclaration des curseurs
    cursor CUR_FAL_PIC(Pic_ID number)
    is
      select PIC_BEGIN_DATE
        from FAL_PIC
       where FAL_PIC_ID = Pic_ID;

    -- Déclaration des variables
    PicBeginDate date;
  begin
    open CUR_FAL_PIC(Pic_ID);

    fetch CUR_FAL_PIC
     into PicBeginDate;

    close CUR_FAL_PIC;

    return PicBeginDate;
  end;

--------------------------------------------------------------------------------------------
-- Fonction qui met à jour le coefficient d'un produit dans les FAL_PIC_LINE
--------------------------------------------------------------------------------------------
  procedure MiseAJourCoefficient(
    Pic_ID       number
  , Representant number
  , Client       FAL_PIC_LINE.PIL_GROUP_OR_THIRD%type
  , Produit_PT   number
  , Produit_ID   number
  , Coefficient  number
  )
  is
  begin
    update FAL_PIC_LINE
       set PIL_COEFF = Coefficient
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_PIC_ID = Pic_ID
       and (    (    PAC_REPRESENTATIVE_ID is null
                 and Representant is null)
            or (PAC_REPRESENTATIVE_ID = Representant) )
       and (    (    PIL_GROUP_OR_THIRD is null
                 and Client is null)
            or (PIL_GROUP_OR_THIRD = Client) )
       and (    (    GCO_GCO_GOOD_ID is null
                 and Produit_PT is null)
            or (GCO_GCO_GOOD_ID = Produit_PT) )
       and GCO_GOOD_ID = Produit_ID;
  end;

--------------------------------------------------------------------------------------------
--  Création des nouveaux enregistrements dans FAL_PIC_LINE
--------------------------------------------------------------------------------------------
  procedure Generation_Lignes_PIC_Proc(
    Pic_ID          number
  , Revision        number
  , Representant    number
  , Client          FAL_PIC_LINE.PIL_GROUP_OR_THIRD%type
  , Produit_PT      number
  , Produit_ID      number
  , Coefficient     number
  , Date_Ligne      date
  , Quantite        number
  , Valeur_Unitaire number
  , PIC_Status      FAL_PIC.C_PIC_STATUS%type
  , structure       FAL_PIC.C_PIC_STRUCTURE%type
  , NomClient       FAL_PIC_LINE.PIL_CUSTOM_PARTNER%type
  )
  is
    -- Déclaration des variables
    Quantite_Prevue  number;
    Quantite_Revisee number;
    Quantite_Solde   number;
    Actif            integer;
  begin
    if Revision = 1 then
      Quantite_Prevue   := 0;
      Quantite_Revisee  := Quantite;
      Quantite_Solde    := 0;
    else
      Quantite_Prevue   := Quantite;
      Quantite_Revisee  := 0;
      Quantite_Solde    := Quantite;
    end if;

    if Pic_Status = '1' then
      Actif  := 0;
    else
      Actif  := 1;
    end if;

    insert into FAL_PIC_LINE
                (FAL_PIC_LINE_ID
               , FAL_PIC_ID
               , PIL_ACTIF
               , PIL_STRUCTURE
               , PAC_REPRESENTATIVE_ID
               , PIL_GROUP_OR_THIRD
               , GCO_GCO_GOOD_ID
               , GCO_GOOD_ID
               , PIL_DATE
               , PIL_COEFF
               , PIL_PREV_QTY
               , PIL_ORDER_QTY
               , PIL_REAL_QTY
               , PIL_REVISION_QTY
               , PIL_PDP_QTY
               , PIL_REAL_VALUE
               , PIL_UNIT_VALUE
               , PIL_ALLKEY
               , PIL_CUSTOM_PARTNER
               , A_DATECRE
               , A_IDCRE
                )
         values (GetNewId
               ,   -- FAL_PIC_LINE_ID
                 Pic_ID
               ,   -- FAL_PIC_ID
                 Actif
               ,   -- PIL_ACTIF
                 structure
               ,   -- PIL-STRUCTURE
                 Representant
               ,   -- PAC_REPRESENTATIVE_ID
                 Client
               ,   -- PIL_GROUP_OR_THIRD
                 Produit_PT
               ,   -- GCO_GCO_GOOD_ID
                 Produit_ID
               ,   -- GCO_GOOD_ID
                 Date_Ligne
               ,   -- PIL_DATE
                 Coefficient
               ,   -- PIL_COEFF
                 Quantite_Prevue
               ,   -- PIL_PREV_QTY
                 0
               ,   -- PIL_ORDER_QTY
                 0
               ,   -- PIL_REAL_QTY
                 Quantite_Revisee
               ,   -- PIL_REVISION_QTY
                 0
               ,   -- PIL_PDP_QTY
                 0
               ,   -- PIL_REAL_VALUE
                 Valeur_Unitaire
               ,   -- PIL_UNIT_VALUE
                 '0'
               ,   -- PIL_ALLKEY,
                 NomClient
               ,   -- PIL_CUSTOM_PARTNER
                 sysdate
               ,   -- A_DATECRE
                 PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                );
  end;

/*-----------------------------------------------------------------------
     Initialisation de la valeur unitaire
------------------------------------------------------------------------*/
  function GetUnitValue(
    PacCustomPartnerId       FAL_PIC_LINE.PIL_GROUP_OR_THIRD%type
  , GcoGoodId                number
  , PicValueCostprice        FAL_PIC.PIC_VALUE_COSTPRICE%type
  , DicTariffId              FAL_PIC.DIC_TARIFF_ID%type
  , DicFixedCostpriceDescrId FAL_PIC.DIC_FIXED_COSTPRICE_DESCR_ID%type
  , PilDate                  date
  )
    return FAL_PIC_LINE.PIL_UNIT_VALUE%type
  is
    cursor CUR_PTC_FIXED_COSTPRICE(GcoGoodId number, DicFixedCostpriceDescrId FAL_PIC.DIC_FIXED_COSTPRICE_DESCR_ID%type)
    is
      select CPR_PRICE
        from PTC_FIXED_COSTPRICE
       where GCO_GOOD_ID = GcoGoodId
         and DIC_FIXED_COSTPRICE_DESCR_ID = DicFixedCostpriceDescrId
         and C_COSTPRICE_STATUS = 'ACT'
         and trunc(sysdate) between nvl(trunc(FCP_START_DATE), to_date('01.01.1900', 'DD.MM.YYYY') )
                                and nvl(trunc(FCP_END_DATE), to_date('31.12.2999', 'DD.MM.YYYY') );

    cursor CUR_RECENT_FIXED_COSTPRICE(GcoGoodId number, DicFixedCostpriceDescrId FAL_PIC.DIC_FIXED_COSTPRICE_DESCR_ID%type)
    is
      select CPR_PRICE
        from PTC_FIXED_COSTPRICE
       where GCO_GOOD_ID = GcoGoodId
         and DIC_FIXED_COSTPRICE_DESCR_ID = DicFixedCostpriceDescrId
         and C_COSTPRICE_STATUS = 'ACT'
         and CPR_DEFAULT = 1;

    cursor CUR_BASIS_CURRENCY
    is
      select ACS_FINANCIAL_CURRENCY_ID
        from ACS_FINANCIAL_CURRENCY
       where FIN_LOCAL_CURRENCY = 1;

    CurPtcFixedCostprice    CUR_PTC_FIXED_COSTPRICE%rowtype;
    CurRecentFixedCostprice CUR_RECENT_FIXED_COSTPRICE%rowtype;
    result                  FAL_PIC_LINE.PIL_UNIT_VALUE%type;
    CurBasisCurrency        CUR_BASIS_CURRENCY%rowtype;
    aGoodUnitPrice          DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    aDiscountRate           DOC_INTERFACE_POSITION.DOP_DISCOUNT_RATE%type;
    aGoodGrossPrice         DOC_POSITION.POS_GROSS_VALUE%type;
    aNetPriceHt             DOC_POSITION.POS_NET_VALUE_EXCL%type;
    aNetPriceTTC            DOC_POSITION.POS_NET_VALUE_INCL%type;
    nPacCustomPartnerId     number;
  begin
    result  := 0;

    if PicValueCostprice = 1 then
      -- On prend l'enregistrement pour lequel FCP_START_DATE < SYSDATE < FCP_END_DATE
      open CUR_PTC_FIXED_COSTPRICE(GcoGoodId, DicFixedCostpriceDescrId);

      fetch CUR_PTC_FIXED_COSTPRICE
       into CurPtcFixedCostprice;

      if CUR_PTC_FIXED_COSTPRICE%found then
        result  := CurPtcFixedCostprice.CPR_PRICE;
      else
        -- si non trouvé, on prend celui par défaut
        open CUR_RECENT_FIXED_COSTPRICE(GcoGoodId, DicFixedCostpriceDescrId);

        fetch CUR_RECENT_FIXED_COSTPRICE
         into CurRecentFixedCostprice;

        if CUR_RECENT_FIXED_COSTPRICE%found then
          result  := CurRecentFixedCostprice.CPR_PRICE;
        end if;

        close CUR_RECENT_FIXED_COSTPRICE;
      end if;

      close CUR_PTC_FIXED_COSTPRICE;
    else
      -- Recherche prix tarifaire
      open CUR_BASIS_CURRENCY;

      fetch CUR_BASIS_CURRENCY
       into CurBasisCurrency;

      close CUR_BASIS_CURRENCY;

      if PartnerIsAGroup(PacCustomPartnerId) = 1 then
        nPacCustomPartnerId  := null;
      else
        nPacCustomPartnerId  := PacCustomPartnerId;
      end if;

      PTC_FIND_TARIFF.GetTariffConverted(GcoGoodId
                                       ,   --Bien
                                         1
                                       ,   --Qty
                                         nPacCustomPartnerId
                                       ,   --Tiers
                                         null
                                       ,   --Dossier
                                         null
                                       ,   --Gabarit document
                                         CurBasisCurrency.ACS_FINANCIAL_CURRENCY_ID
                                       ,   --Monnaie du Document
                                         'A_FACTURER'
                                       ,   --Type de tariffication du partenaire
                                         null
                                       ,   --Mode de tariffication du partenaire
                                         DicTariffId
                                       ,   --Tarif
                                         PilDate
                                       ,   -- date de référence pour la recherche du cours logistique
                                         aGoodUnitPrice
                                       ,   --Prix unitaire du bien
                                         aDiscountRate
                                       ,   --Taux rabais
                                         aGoodGrossPrice
                                       ,   --Prix brut du bien
                                         aNetPriceHt
                                       ,   --Valeur nette HT
                                         aNetPriceTTC
                                        );   --Valeur nette TTC
      result  := aGoodUnitPrice;
    end if;

    return result;
  end;

--------------------------------------------------------------------------------------------
-- Boucle de PIC_BEGIN_DATE à PIC_END_DATE
--------------------------------------------------------------------------------------------
  procedure Generation_Lignes_PIC_3(
    Pic_ID                   number
  , Revision                 number
  , Representant             number
  , Client                   FAL_PIC_LINE.PIL_GROUP_OR_THIRD%type
  , Produit_PT               number
  , Produit_ID               number
  , Coefficient              number
  , Valeur_Unitaire          number
  , PIC_Status               FAL_PIC.C_PIC_STATUS%type
  , structure                FAL_PIC.C_PIC_STRUCTURE%type
  , NomClient                FAL_PIC_LINE.PIL_CUSTOM_PARTNER%type
  , Init_Prev                integer
  , Begin_Date               date
  , End_Date                 date
  , StoredProc_ID            number
  , PicValueCostprice        FAL_PIC.PIC_VALUE_COSTPRICE%type
  , DicTariffId              FAL_PIC.DIC_TARIFF_ID%type
  , DicFixedCostpriceDescrId FAL_PIC.DIC_FIXED_COSTPRICE_DESCR_ID%type
  )
  is
    -- Déclaration des variables
    Date_Ligne date;
    Quantite   number;
    UnitValue  number;
  begin
    -- En révision, si les FAL_PIC_LINE à créer concernent un nouveau client ou un nouveau produit ou ...
    -- on crée les FAL_PIC_LINE depuis la date de début du plan commercial (FAL_PIC -> PIC_BEGIN_DATE)
    if     Revision = 1
       and NouvelleEntree(Pic_ID, Representant, Client, Produit_PT, Produit_ID) then
      Date_Ligne  := DateDebutPC(Pic_ID);
    else
      Date_Ligne  := Begin_Date;
    end if;

    while Date_Ligne < End_Date loop   -- Génération 2 Ligne de PIC PC --7--
      if PCS.PC_Config.GetConfig('FAL_PIC_UNIT_VALUE_DATE') = 'True' then
        UnitValue  := GetUnitValue(Client, Produit_ID, PicValueCostprice, DicTariffId, DicFixedCostpriceDescrId, Date_Ligne);
      else
        UnitValue  := Valeur_Unitaire;
      end if;

      if Init_Prev = 1 then   -- Génération 2 Ligne de PIC PC --8--
        Quantite  := Init_Quantite(Produit_ID, Representant, Client, Date_Ligne, StoredProc_ID);
      else
        Quantite  := 0;
      end if;

      Generation_Lignes_PIC_Proc(Pic_ID
                               , Revision
                               , Representant
                               , Client
                               , Produit_PT
                               , Produit_ID
                               , Coefficient
                               , Date_Ligne
                               , Quantite
                               , nvl(UnitValue, 0)
                               , PIC_Status
                               , structure
                               , NomClient
                                );

      if to_number(PCS.PC_Config.GetConfig('FAL_PIC_WEEK_MONTH') ) = 1 then
        Date_Ligne  := add_months(Date_Ligne, 1);
      else
        Date_Ligne  := Date_Ligne + 7;
      end if;
    end loop;

    if Revision = 1 then
      MiseAJourCoefficient(Pic_ID, Representant, Client, Produit_PT, Produit_ID, Coefficient);
      -- On crée des FAL_PIC_LINE pour un mois supplémentaire afin de détecter les éléments non mis à jour
      -- et les supprimer à la fin de la révision. Voir la procédure Suppr_Pic_Line.
      Generation_Lignes_PIC_Proc(Pic_ID
                               , Revision
                               , Representant
                               , Client
                               , Produit_PT
                               , Produit_ID
                               , Coefficient
                               , Date_Ligne
                               , 0
                               , Valeur_Unitaire
                               , PIC_Status
                               , structure
                               , NomClient
                                );
    end if;
  end;

  procedure Generation_Lignes_PIC_2Bis(
    Pic_ID                   number
  , Revision                 number
  , PacRepresentativeId      number
  , PacCustomPartnerId       FAL_PIC_LINE.PIL_GROUP_OR_THIRD%type
  , GcoGoodId                number
  , PicByProduct             FAL_PIC.PIC_BY_PRODUCT%type
  , PicValueCostprice        FAL_PIC.PIC_VALUE_COSTPRICE%type
  , DicTariffId              FAL_PIC.DIC_TARIFF_ID%type
  , DicFixedCostpriceDescrId FAL_PIC.DIC_FIXED_COSTPRICE_DESCR_ID%type
  , Init_Prev                integer
  , Begin_Date               date
  , End_Date                 date
  , StoredProc_ID            number
  , PIC_Status               FAL_PIC.C_PIC_STATUS%type
  , structure                FAL_PIC.C_PIC_STRUCTURE%type
  , CustomPartnerName        PAC_PERSON.PER_NAME%type
  )
  is
    cursor CUR_ACTIVE_COMPONENT(GcoGoodId number)
    is
      select PNB.GCO_GOOD_ID
           , COM_PDIR_COEFF
        from PPS_NOM_BOND PNB
           , PPS_NOMENCLATURE PN
       where PN.PPS_NOMENCLATURE_ID = PNB.PPS_NOMENCLATURE_ID
         and PN.GCO_GOOD_ID = GcoGoodId
         and C_KIND_COM = 1
         and C_TYPE_COM = 1
         and COM_PDIR_COEFF > 0
         and C_TYPE_NOM = 2
         and NOM_DEFAULT = 1;

    CurActiveComponent       CUR_ACTIVE_COMPONENT%rowtype;
    HasDefaultProductNomencl boolean;
    UnitValue                FAL_PIC_LINE.PIL_UNIT_VALUE%type;
  begin
    HasDefaultProductNomencl  := false;

    if PicByProduct = 0 then
      open CUR_ACTIVE_COMPONENT(GcoGoodId);

      loop
        fetch CUR_ACTIVE_COMPONENT
         into CurActiveComponent;

        exit when CUR_ACTIVE_COMPONENT%notfound;
        HasDefaultProductNomencl  := true;

        if PCS.PC_Config.GetConfig('FAL_PIC_UNIT_VALUE_DATE') = 'False' then
          UnitValue  := GetUnitValue(PacCustomPartnerId, CurActiveComponent.GCO_GOOD_ID, PicValueCostprice, DicTariffId, DicFixedCostpriceDescrId, sysdate);
        end if;

        Generation_Lignes_PIC_3(Pic_ID
                              , Revision
                              , PacRepresentativeId
                              , PacCustomPartnerId
                              , GcoGoodId
                              ,   -- Produit_PT
                                CurActiveComponent.GCO_GOOD_ID
                              ,   -- Produit_ID
                                CurActiveComponent.COM_PDIR_COEFF
                              ,   -- Coefficient
                                UnitValue
                              , PIC_Status
                              , structure
                              , CustomPartnerName
                              , Init_Prev
                              , Begin_Date
                              , End_Date
                              , StoredProc_ID
                              , PicValueCostprice
                              , DicTariffId
                              , DicFixedCostpriceDescrId
                               );
      end loop;

      close CUR_ACTIVE_COMPONENT;
    end if;

    -- Structure par produit OU le produit n'a pas de nomenclature de production par défaut
    if    (PicByProduct = 1)
       or (    PicByProduct = 0
           and not HasDefaultProductNomencl) then
      if PCS.PC_Config.GetConfig('FAL_PIC_UNIT_VALUE_DATE') = 'False' then
        UnitValue  := GetUnitValue(PacCustomPartnerId, GcoGoodId, PicValueCostprice, DicTariffId, DicFixedCostpriceDescrId, sysdate);
      end if;

      Generation_Lignes_PIC_3(Pic_ID
                            , Revision
                            , PacRepresentativeId
                            , PacCustomPartnerId
                            , null
                            ,   -- Produit_PT
                              GcoGoodId
                            ,   -- Produit_ID
                              null
                            ,   -- Coefficient
                              UnitValue
                            , PIC_Status
                            , structure
                            , CustomPartnerName
                            , Init_Prev
                            , Begin_Date
                            , End_Date
                            , StoredProc_ID
                            , PicValueCostprice
                            , DicTariffId
                            , DicFixedCostpriceDescrId
                             );
    end if;
  end;

/*-----------------------------------------------------------------------------------------
  Pour chaque produit géré sur PIC, on appel la procédure Génération_Lignes_PIC_2bis
-----------------------------------------------------------------------------------------*/
  procedure Generation_Lignes_PIC_2(
    Pic_ID                   number
  , Revision                 number
  , PacRepresentativeId      number
  , PacCustomPartnerId       FAL_PIC_LINE.PIL_GROUP_OR_THIRD%type
  , PicByProduct             FAL_PIC.PIC_BY_PRODUCT%type
  , PicValueCostprice        FAL_PIC.PIC_VALUE_COSTPRICE%type
  , DicTariffId              FAL_PIC.DIC_TARIFF_ID%type
  , DicFixedCostpriceDescrId FAL_PIC.DIC_FIXED_COSTPRICE_DESCR_ID%type
  , Init_Prev                integer
  , Begin_Date               date
  , End_Date                 date
  , StoredProc_ID            number
  , PIC_Status               FAL_PIC.C_PIC_STATUS%type
  , structure                FAL_PIC.C_PIC_STRUCTURE%type
  , CustomPartnerName        PAC_PERSON.PER_NAME%type
  )
  is
    cursor CUR_GCO_GOOD
    is
      select GCO_GOOD_ID
        from GCO_PRODUCT
       where PDT_PIC = 1;

    CurGcoGood CUR_GCO_GOOD%rowtype;
  begin
    open CUR_GCO_GOOD;

    loop
      fetch CUR_GCO_GOOD
       into CurGcoGood;

      exit when CUR_GCO_GOOD%notfound;
      Generation_Lignes_PIC_2Bis(Pic_ID
                               , Revision
                               , PacRepresentativeId
                               , PacCustomPartnerId
                               , CurGcoGood.GCO_GOOD_ID
                               , PicByProduct
                               , PicValueCostprice
                               , DicTariffId
                               , DicFixedCostpriceDescrId
                               , Init_Prev
                               , Begin_Date
                               , End_Date
                               , StoredProc_ID
                               , PIC_Status
                               , structure
                               , CustomPartnerName
                                );
    end loop;

    close CUR_GCO_GOOD;
  end;

/*-----------------------------------------------------------------------------------------
 Initialisation des Représentants et Clients en fonction de type de structure :
 (On ne prend en compte que les représentants de type Groupe, actif logistique et finance)
  - Representant/Client/Produit -> Boucle sur tous les Clients de tous les Représentants
  - Représentant/Produit        -> Client = NULL (0), Boucle sur représentant
  - Client/Produits             -> Representant = NULL (0), Boucle sur Client
  - Client/Produits liés        -> Les clients liés au produit dans les données complémentaires de vente du produit
  - Produit                     -> Representant = NULL (0), Client = NULL (0)
-----------------------------------------------------------------------------------------*/
  procedure Generation_Lignes_PIC_1(
    Pic_ID                   number
  , Revision                 number
  , structure                FAL_PIC.C_PIC_STRUCTURE%type
  , PicByProduct             FAL_PIC.PIC_BY_PRODUCT%type
  , PicValueCostprice        FAL_PIC.PIC_VALUE_COSTPRICE%type
  , DicTariffId              FAL_PIC.DIC_TARIFF_ID%type
  , DicFixedCostpriceDescrId FAL_PIC.DIC_FIXED_COSTPRICE_DESCR_ID%type
  , Init_Prev                integer
  , Begin_Date               date
  , End_Date                 date
  , StoredProc_ID            number
  , PIC_Status               FAL_PIC.C_PIC_STATUS%type
  )
  is
    -- Déclaration des curseurs
    cursor CUR_PAC_REPRESENTATIVE
    is
      select PR.PAC_REPRESENTATIVE_ID
           , PAC_CUSTOM_PARTNER_ID
           , PER_NAME
        from PAC_REPRESENTATIVE PR
           , PAC_CUSTOM_PARTNER PCP
           , PAC_PERSON PP
       where PR.PAC_REPRESENTATIVE_ID = PCP.PAC_REPRESENTATIVE_ID
         and PAC_CUSTOM_PARTNER_ID = PAC_PERSON_ID;

    cursor CUR_PAC_REPRESENTATIVE_2
    is
      select PAC_REPRESENTATIVE_ID
        from PAC_REPRESENTATIVE
       where REP_GROUP = 1
         and C_PARTNER_STATUS = 1;

    cursor CUR_PAC_CUSTOM_PARTNER
    is
      select PAC_CUSTOM_PARTNER_ID
           , PER_NAME
        from PAC_CUSTOM_PARTNER
           , PAC_PERSON
       where PAC_CUSTOM_PARTNER_ID = PAC_PERSON_ID
         and DIC_PIC_GROUP_ID is null;

    cursor CUR_DIC_PIC_GROUP
    is
      select DIC_PIC_GROUP_ID
           , DIC_DESCR
        from DIC_PIC_GROUP;

    cursor CUR_CLIENT_PROD_LIES
    is
      select PAC_CUSTOM_PARTNER_ID
           , PER_NAME
           , GP.GCO_GOOD_ID
        from GCO_PRODUCT GP
           , GCO_COMPL_DATA_SALE GCDS
           , PAC_PERSON PP
       where GP.GCO_GOOD_ID = GCDS.GCO_GOOD_ID
         and PAC_CUSTOM_PARTNER_ID = PAC_PERSON_ID
         and PDT_PIC = 1;

    -- Déclaration des curseurs
    CurPacRepresentative  CUR_PAC_REPRESENTATIVE%rowtype;
    CurPacRepresentative2 CUR_PAC_REPRESENTATIVE_2%rowtype;
    CurPacCustomPartner   CUR_PAC_CUSTOM_PARTNER%rowtype;
    CurDicPicGroup        CUR_DIC_PIC_GROUP%rowtype;
    CurClientProdLies     CUR_CLIENT_PROD_LIES%rowtype;
  begin
    if structure = '1' then   -- Génération 1 Ligne de PIC PC --1--
                              -- Structure par Représentant/Client/Produit
      -- Pour chaque représentant de type Groupe, actif logistique et finance
      open CUR_PAC_REPRESENTATIVE;

      loop
        fetch CUR_PAC_REPRESENTATIVE
         into CurPacRepresentative;

        exit when CUR_PAC_REPRESENTATIVE%notfound;
        Generation_Lignes_PIC_2(Pic_ID
                              , Revision
                              , CurPacRepresentative.PAC_REPRESENTATIVE_ID
                              , CurPacRepresentative.PAC_CUSTOM_PARTNER_ID
                              , PicByProduct
                              , PicValueCostprice
                              , DicTariffId
                              , DicFixedCostpriceDescrId
                              , Init_Prev
                              , Begin_Date
                              , End_Date
                              , StoredProc_ID
                              , PIC_Status
                              , structure
                              , CurPacRepresentative.PER_NAME
                               );
      end loop;

      close CUR_PAC_REPRESENTATIVE;
    elsif structure = '2' then   -- Structure par Représentant/Produit
      -- Pour chaque représentant de type Groupe, actif logistique et finance
      open CUR_PAC_REPRESENTATIVE_2;

      loop
        fetch CUR_PAC_REPRESENTATIVE_2
         into CurPacRepresentative2;

        exit when CUR_PAC_REPRESENTATIVE_2%notfound;
        Generation_Lignes_PIC_2(Pic_ID
                              , Revision
                              , CurPacRepresentative2.PAC_REPRESENTATIVE_ID
                              , null
                              ,   -- Client
                                PicByProduct
                              , PicValueCostprice
                              , DicTariffId
                              , DicFixedCostpriceDescrId
                              , Init_Prev
                              , Begin_Date
                              , End_Date
                              , StoredProc_ID
                              , PIC_Status
                              , structure
                              , null
                               );   -- Nom client
      end loop;

      close CUR_PAC_REPRESENTATIVE_2;
    elsif structure = '3' then   -- Structure par Client/Produit
      -- Pour chaque client
      open CUR_PAC_CUSTOM_PARTNER;

      loop
        fetch CUR_PAC_CUSTOM_PARTNER
         into CurPacCustomPartner;

        exit when CUR_PAC_CUSTOM_PARTNER%notfound;
        Generation_Lignes_PIC_2(Pic_ID
                              , Revision
                              , null
                              , CurPacCustomPartner.PAC_CUSTOM_PARTNER_ID
                              , PicByProduct
                              , PicValueCostprice
                              , DicTariffId
                              , DicFixedCostpriceDescrId
                              , Init_Prev
                              , Begin_Date
                              , End_Date
                              , StoredProc_ID
                              , PIC_Status
                              , structure
                              , CurPacCustomPartner.PER_NAME
                               );
      end loop;

      close CUR_PAC_CUSTOM_PARTNER;

      -- Pour chaque valeur de DIC_PIC_GROUP
      open CUR_DIC_PIC_GROUP;

      loop
        fetch CUR_DIC_PIC_GROUP
         into CurDicPicGroup;

        exit when CUR_DIC_PIC_GROUP%notfound;
        Generation_Lignes_PIC_2(Pic_ID
                              , Revision
                              , null
                              , CurDicPicGroup.DIC_PIC_GROUP_ID
                              , PicByProduct
                              , PicValueCostprice
                              , DicTariffId
                              , DicFixedCostpriceDescrId
                              , Init_Prev
                              , Begin_Date
                              , End_Date
                              , StoredProc_ID
                              , PIC_Status
                              , structure
                              , CurDicPicGroup.DIC_DESCR
                               );
      end loop;

      close CUR_DIC_PIC_GROUP;
    elsif structure = '4' then   -- Structure par Client Produits liés
      open CUR_CLIENT_PROD_LIES;

      loop
        fetch CUR_CLIENT_PROD_LIES
         into CurClientProdLies;

        exit when CUR_CLIENT_PROD_LIES%notfound;
        Generation_Lignes_PIC_2Bis(Pic_ID
                                 , Revision
                                 , null
                                 , CurClientProdLies.PAC_CUSTOM_PARTNER_ID
                                 , CurClientProdLies.GCO_GOOD_ID
                                 , PicByProduct
                                 , PicValueCostprice
                                 , DicTariffId
                                 , DicFixedCostpriceDescrId
                                 , Init_Prev
                                 , Begin_Date
                                 , End_Date
                                 , StoredProc_ID
                                 , PIC_Status
                                 , structure
                                 , CurClientProdLies.PER_NAME
                                  );
      end loop;

      close CUR_CLIENT_PROD_LIES;
    else   -- Structure par produit (5)
      Generation_Lignes_PIC_2(Pic_ID
                            , Revision
                            , null
                            , null
                            , PicByProduct
                            , PicValueCostprice
                            , DicTariffId
                            , DicFixedCostpriceDescrId
                            , Init_Prev
                            , Begin_Date
                            , End_Date
                            , StoredProc_ID
                            , PIC_Status
                            , structure
                            , null
                             );
    end if;
  end;

  function RechercheGroupe(PacThirdID FAL_PIC_LINE.PIL_GROUP_OR_THIRD%type)
    return FAL_PIC_LINE.PIL_GROUP_OR_THIRD%type
  is
    -- Déclaration des curseurs
    cursor CUR_PAC_CUSTOM_PARTNER(PacThirdID FAL_PIC_LINE.PIL_GROUP_OR_THIRD%type)
    is
      select DIC_PIC_GROUP_ID
        from PAC_CUSTOM_PARTNER
       where PAC_CUSTOM_PARTNER_ID = PacThirdID;

    -- Déclaration des variables
    result FAL_PIC_LINE.PIL_GROUP_OR_THIRD%type;
  begin
    open CUR_PAC_CUSTOM_PARTNER(PacThirdID);

    fetch CUR_PAC_CUSTOM_PARTNER
     into result;

    if    CUR_PAC_CUSTOM_PARTNER%notfound
       or (result is null) then
      result  := PacThirdID;
    end if;

    close CUR_PAC_CUSTOM_PARTNER;

    return result;
  end;

  procedure MiseAJourRealise
  is
    -- Déclaration des curseurs
    cursor CUR_DOC_PIC_RELEASE_BUFF
    is
      select DOC_PIC_RELEASE_BUFFER_ID
           , GCO_GOOD_ID
           , GCO_GCO_GOOD_ID
           , PAC_THIRD_ID
           , PAC_REPRESENTATIVE_ID
           , PRB_DATE
           , PRB_QUANTITY
           , PRB_VALUE
        from DOC_PIC_RELEASE_BUFFER;

    cursor CUR_FAL_PIC_LINE(GcoGoodID number, GcoGcoGoodId number, PrbDate date)
    is
      select PIL_STRUCTURE
        from FAL_PIC_LINE
       where (   GCO_GOOD_ID = GcoGoodID
              or GCO_GOOD_ID = GcoGcoGoodId)
         and PIL_DATE = PrbDate
         and PIL_ACTIF = 1;

    -- Déclaration des variables
    DocPicRealeaseBuffID DOC_PIC_RELEASE_BUFFER.DOC_PIC_RELEASE_BUFFER_ID%type;
    GcoGoodID            number;
    GcoGcoGoodId         number;
    PacThirdID           FAL_PIC_LINE.PIL_GROUP_OR_THIRD%type;
    PacRepresentativeID  number;
    PrbDate              date;
    PrbQuantity          DOC_PIC_RELEASE_BUFFER.PRB_QUANTITY%type;
    PrbValue             DOC_PIC_RELEASE_BUFFER.PRB_VALUE%type;
    PilStructure         FAL_PIC_LINE.PIL_STRUCTURE%type;
    PilGroupOrThird      FAL_PIC_LINE.PIL_GROUP_OR_THIRD%type;
    outYear              number;
    outWeek              number;
  begin
    open CUR_DOC_PIC_RELEASE_BUFF;

    loop
      fetch CUR_DOC_PIC_RELEASE_BUFF
       into DocPicRealeaseBuffID
          , GcoGoodID
          , GcoGcoGoodId
          , PacThirdID
          , PacRepresentativeID
          , PrbDate
          , PrbQuantity
          , PrbValue;

      exit when CUR_DOC_PIC_RELEASE_BUFF%notfound;

      if to_number(PCS.PC_Config.GetConfig('FAL_PIC_WEEK_MONTH') ) = 1 then
          -- On travaille en Mois
        -- Dans les FAL_PIC_LINE, PIL_DATE est toujours le premier jour du mois.
          -- On met donc PrbDate au premier jour du mois
        PrbDate  := trunc(PrbDate, 'MM');
      else
        -- On travaille en Semaine
        -- PrbDate est le premier jour de la semaine
        DOC_DELAY_FUNCTIONS.DateToWeekNumber(PrbDate, to_number(PCS.PC_Config.GetConfig('DOC_DELAY_WEEKSTART') ), outYear, outWeek);
        PrbDate  := DOC_DELAY_FUNCTIONS.WeekNumberToDate(outYear, outWeek, 1, to_number(PCS.PC_Config.GetConfig('DOC_DELAY_WEEKSTART') ) );
      end if;

      open CUR_FAL_PIC_LINE(GcoGoodID, GcoGcoGoodId, PrbDate);

      fetch CUR_FAL_PIC_LINE
       into PilStructure;

      if CUR_FAL_PIC_LINE%found then
        if PilStructure = '1' then   -- Représentant/Client/Produit/Date
          update FAL_PIC_LINE
             set PIL_REAL_QTY = nvl(PIL_REAL_QTY, 0) + nvl(PrbQuantity, 0)
               , PIL_REAL_VALUE = nvl(PIL_REAL_VALUE, 0) + nvl(PrbValue, 0)
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where PIL_ACTIF = 1
             and (   GCO_GOOD_ID = GcoGoodID
                  or GCO_GOOD_ID = GcoGcoGoodId)
             and rownum = 1
             and PIL_DATE = PrbDate
             and PIL_GROUP_OR_THIRD = PacThirdID
             and PAC_REPRESENTATIVE_ID = PacRepresentativeID;
        else
          if PilStructure = '2' then   -- Représentant/Produit/Date
            update FAL_PIC_LINE
               set PIL_REAL_QTY = nvl(PIL_REAL_QTY, 0) + nvl(PrbQuantity, 0)
                 , PIL_REAL_VALUE = nvl(PIL_REAL_VALUE, 0) + nvl(PrbValue, 0)
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where PIL_ACTIF = 1
               and (   GCO_GOOD_ID = GcoGoodID
                    or GCO_GOOD_ID = GcoGcoGoodId)
               and rownum = 1
               and PIL_DATE = PrbDate
               and PAC_REPRESENTATIVE_ID = PacRepresentativeID;
          else
            if PilStructure = '3' then   -- Client/Produit/Date
              PilGroupOrThird  := RechercheGroupe(PacThirdID);

              update FAL_PIC_LINE
                 set PIL_REAL_QTY = nvl(PIL_REAL_QTY, 0) + nvl(PrbQuantity, 0)
                   , PIL_REAL_VALUE = nvl(PIL_REAL_VALUE, 0) + nvl(PrbValue, 0)
                   , A_DATEMOD = sysdate
                   , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
               where PIL_ACTIF = 1
                 and (   GCO_GOOD_ID = GcoGoodID
                      or GCO_GOOD_ID = GcoGcoGoodId)
                 and rownum = 1
                 and PIL_DATE = PrbDate
                 and PIL_GROUP_OR_THIRD = PilGroupOrThird;
            else
              if PilStructure = '4' then   -- Client/Produit Lié/Date
                update FAL_PIC_LINE
                   set PIL_REAL_QTY = nvl(PIL_REAL_QTY, 0) + nvl(PrbQuantity, 0)
                     , PIL_REAL_VALUE = nvl(PIL_REAL_VALUE, 0) + nvl(PrbValue, 0)
                     , A_DATEMOD = sysdate
                     , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                 where PIL_ACTIF = 1
                   and (   GCO_GOOD_ID = GcoGoodID
                        or GCO_GOOD_ID = GcoGcoGoodId)
                   and rownum = 1
                   and PIL_DATE = PrbDate
                   and PIL_GROUP_OR_THIRD = PacThirdID;
              else
                if PilStructure = '5' then   -- Produit/Date
                  update FAL_PIC_LINE
                     set PIL_REAL_QTY = nvl(PIL_REAL_QTY, 0) + nvl(PrbQuantity, 0)
                       , PIL_REAL_VALUE = nvl(PIL_REAL_VALUE, 0) + nvl(PrbValue, 0)
                       , A_DATEMOD = sysdate
                       , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                   where PIL_ACTIF = 1
                     and (   GCO_GOOD_ID = GcoGoodID
                          or GCO_GOOD_ID = GcoGcoGoodId)
                     and rownum = 1
                     and PIL_DATE = PrbDate;
                end if;   -- Structure = 5
              end if;   -- Structure = 4
            end if;   -- Structure = 3
          end if;   -- Structure = 2
        end if;   -- Structure = 1
      end if;

      close CUR_FAL_PIC_LINE;

      -- Suppression de l'enregistrement traité du buffer
      delete      DOC_PIC_RELEASE_BUFFER
            where DOC_PIC_RELEASE_BUFFER_ID = DocPicRealeaseBuffID;
    end loop;

    close CUR_DOC_PIC_RELEASE_BUFF;
  end;

  /**
   * procedure ProcessusMajQteCmdPicLine
   * Description : Processus MAJ Qté Cmd Ligne de PIC, MAJ des qté en commande sur
   *               les lignes de PIC.
   *
   * @param   PrmGCO_GOOD_ID : Produit
   * @param   PrmFAN_END_PLAN : Date fin planifiée besoin
   * @param   PrmPAC_THIRD_ID : Tiers
   * @param   PrmPAC_REPRESENTATIVE_ID : représentant
   * @param   PrmPDE_BALANCE_QUANTITY : Qté solde position
   * @param   prmDIC_PIC_GROUP_ID : = PIL_GROUP_OR_THIRD
   */
  procedure ProcessusMajQteCmdPicLine(
    PrmGCO_GOOD_ID           GCO_GOOD.GCO_GOOD_ID%type
  , PrmFAN_END_PLAN          date
  , PrmPAC_THIRD_ID          PAC_THIRD.PAC_THIRD_ID%type
  , PrmPAC_REPRESENTATIVE_ID PAC_REPRESENTATIVE.PAC_REPRESENTATIVE_ID%type
  , PrmPDE_BALANCE_QUANTITY  DOC_POSITION_DETAIL.PDE_BALANCE_QUANTITY%type
  , prmDIC_PIC_GROUP_ID      DIC_PIC_GROUP.DIC_PIC_GROUP_ID%type
  )
  is
    BUffPIL_STRUCTURE FAL_PIC_LINE.PIL_STRUCTURE%type;
    GcoGcoGoodId      GCO_GOOD.GCO_GOOD_ID%type;
    PilDate           date;
    outYear           number;
    outWeek           number;

    cursor CurFAL_PIC_LINE
    is
      select PIL_STRUCTURE
        from fal_pic_line
       where pil_actif = 1
         and (   Gco_good_id = PrmGCO_GOOD_ID
              or Gco_good_id = GcoGcoGoodId)
         and PIL_DATE = PilDate;

    cursor CurGCO_PRODUCT
    is
      select GCO2_GCO_GOOD_ID
        from gco_product
       where GCO_GOOD_ID = PrmGCO_GOOD_ID;
  begin
    if to_number(PCS.PC_Config.GetConfig('FAL_PIC_WEEK_MONTH') ) = 1 then
      -- On travaille en Mois
      -- Dans les FAL_PIC_LINE, PIL_DATE est toujours le premier jour du mois.
      PilDate  := trunc(PrmFAN_END_PLAN, 'MM');
    else
      -- On travaille en Semaine -> premier jour de la semaine
      DOC_DELAY_FUNCTIONS.DateToWeekNumber(PrmFAN_END_PLAN, to_number(PCS.PC_Config.GetConfig('DOC_DELAY_WEEKSTART') ), outYear, outWeek);
      PilDate  := DOC_DELAY_FUNCTIONS.WeekNumberToDate(outYear, outWeek, 1, to_number(PCS.PC_Config.GetConfig('DOC_DELAY_WEEKSTART') ) );
    end if;

    open CurGCO_PRODUCT;

    fetch CurGCO_PRODUCT
     into GcoGcoGoodId;

    close CurGCO_PRODUCT;

    open CurFAL_PIC_LINE;

    fetch CurFAL_PIC_LINE
     into BUffPIL_STRUCTURE;

    close CurFAL_PIC_LINE;

    if BuffPIL_STRUCTURE = 1 then
      update FAL_PIC_LINE
         set PIL_ORDER_QTY = PIL_ORDER_QTY + nvl(PrmPDE_BALANCE_QUANTITY, 0)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where PIL_GROUP_OR_THIRD = to_char(PrmPAC_THIRD_ID)
         and PAC_REPRESENTATIVE_ID = PrmPAC_REPRESENTATIVE_ID
         and PIL_ACTIF = 1
         and (   Gco_good_id = PrmGCO_GOOD_ID
              or GCO_GOOD_ID = GcoGcoGoodId)
         and rownum = 1
         and PIL_DATE = PilDate;
    end if;

    if BuffPIL_STRUCTURE = 2 then
      update FAL_PIC_LINE
         set PIL_ORDER_QTY = PIL_ORDER_QTY + nvl(PrmPDE_BALANCE_QUANTITY, 0)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where PIL_GROUP_OR_THIRD is null
         and PAC_REPRESENTATIVE_ID = PrmPAC_REPRESENTATIVE_ID
         and PIL_ACTIF = 1
         and (   Gco_good_id = PrmGCO_GOOD_ID
              or Gco_good_id = GcoGcoGoodId)
         and rownum = 1
         and PIL_DATE = PilDate;
    end if;

    if BuffPIL_STRUCTURE = 3 then
      if prmDIC_PIC_GROUP_ID is null then
        update FAL_PIC_LINE
           set PIL_ORDER_QTY = PIL_ORDER_QTY + nvl(PrmPDE_BALANCE_QUANTITY, 0)
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where PIL_GROUP_OR_THIRD = to_char(PrmPAC_THIRD_ID)
           and PAC_REPRESENTATIVE_ID is null
           and PIL_ACTIF = 1
           and (   Gco_good_id = PrmGCO_GOOD_ID
                or GCO_GOOD_ID = GcoGcoGoodId)
           and rownum = 1
           and PIL_DATE = PilDate;
      end if;

      if prmDIC_PIC_GROUP_ID is not null then
        update FAL_PIC_LINE
           set PIL_ORDER_QTY = PIL_ORDER_QTY + nvl(PrmPDE_BALANCE_QUANTITY, 0)
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where PIL_GROUP_OR_THIRD = PrmDIC_PIC_GROUP_ID
           and PAC_REPRESENTATIVE_ID is null
           and PIL_ACTIF = 1
           and (   Gco_good_id = PrmGCO_GOOD_ID
                or GCO_GOOD_ID = GcoGcoGoodId)
           and rownum = 1
           and PIL_DATE = PilDate;
      end if;
    end if;

    if BuffPIL_STRUCTURE = 4 then
      update FAL_PIC_LINE
         set PIL_ORDER_QTY = PIL_ORDER_QTY + nvl(PrmPDE_BALANCE_QUANTITY, 0)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where PIL_GROUP_OR_THIRD = to_char(PrmPAC_THIRD_ID)
         and PAC_REPRESENTATIVE_ID is null
         and PIL_ACTIF = 1
         and (   Gco_good_id = PrmGCO_GOOD_ID
              or GCO_GOOD_ID = GcoGcoGoodId)
         and rownum = 1
         and PIL_DATE = PilDate;
    end if;

    if BuffPIL_STRUCTURE = 5 then
      update FAL_PIC_LINE
         set PIL_ORDER_QTY = PIL_ORDER_QTY + nvl(PrmPDE_BALANCE_QUANTITY, 0)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where PIL_GROUP_OR_THIRD is null
         and PAC_REPRESENTATIVE_ID is null
         and PIL_ACTIF = 1
         and (   Gco_good_id = PrmGCO_GOOD_ID
              or GCO_GOOD_ID = GcoGcoGoodId)
         and rownum = 1
         and PIL_DATE = PilDate;
    end if;
  end;

/*--------------------------------------------------------------------------
 Check des tables FAL_PIC_FORMULA et FAL_PIC_INIT_QTY.
 Si une des formules du PDP (STOCK, PDP, PDP2) n'est pas trouvé,
 elle est ajoutée dans la table FAL_PIC_FORMULA. Si aucun
 n'enregistrement n'est trouvé dans FAL_PIC_INIT_QTY, on met celui
 par défaut du package FAL_PIC_QTY. Procédure exécutée au lancement du module
--------------------------------------------------------------------------*/
  procedure CheckTableFormuleEtInitQty(aDisplayComponent varchar2 default 'VCI')
  is
  begin
    insert into FAL_PIC_INIT_QTY
                (FAL_PIC_INIT_QTY_ID
               , PIQ_REFERENCE
               , PIQ_DESCRIPTION
               , PIQ_STORED_PROC
               , A_DATECRE
               , A_IDCRE
                )
      select GetNewId
           , 'Init Qty N-1'
           , 'Init Qty N-1'
           , 'FAL_PIC_QTY.INIT_QTY'
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        from dual
       where not exists(select 1
                          from FAL_PIC_INIT_QTY);

    -- Recherche d'une formule de stock et ajout dans la table s'il n'y en a pas
    insert into FAL_PIC_FORMULA
                (FAL_PIC_FORMULA_ID
               , FOR_NAME
               , FOR_DESCRIPTION
               , FOR_DISPLAY_COMPONENT
               , A_DATECRE
               , A_IDCRE
                )
      select GetNewId
           , 'STOCK'
           , '[STOCK(-1)] - [BALANCE] - [NEED] + [PDP2] +  [SUPPLY]'
           , aDisplayComponent
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        from dual
       where not exists(select 1
                          from FAL_PIC_FORMULA
                         where FOR_NAME = 'STOCK'
                           and FOR_DISPLAY_COMPONENT = aDisplayComponent);

    -- Recherche d'une formule de PDP et ajout dans la table s'il n'y en a pas
    insert into FAL_PIC_FORMULA
                (FAL_PIC_FORMULA_ID
               , FOR_NAME
               , FOR_DESCRIPTION
               , FOR_DISPLAY_COMPONENT
               , A_DATECRE
               , A_IDCRE
                )
      select GetNewId
           , 'PDP'
           , case aDisplayComponent
               when 'ASPO' then 'IF ( ( [STOCK(-1)] + [SUPPLY] - [BALANCE] - [NEED] ) < 0 ,' ||
                                ' ( ROUNDUP ( ( ( [BALANCE] + [NEED] - [STOCK(-1)] - [SUPPLY] ) +' ||
                                ' ( [STOCK_COVER] * ( [BALANCE(1)] + [NEED(1)] ) ) ) / ( IF ( [ECO_LOT] > 0 ,' ||
                                ' [ECO_LOT] , 1 ) ) , 0 ) ) * ( IF ( [ECO_LOT] > 0 , [ECO_LOT] , 1 ) ) , 0 )'
               when 'VCI' then 'IF ( ( [STOCK(-1)] + [SUPPLY] - [BALANCE] - [NEED] ) < 0 ;' ||
                               ' ( ROUNDUP ( ( ( [BALANCE] + [NEED] - [STOCK(-1)] - [SUPPLY] ) +' ||
                               ' ( [STOCK_COVER] * ( [BALANCE(1)] + [NEED(1)] ) ) ) / ( IF ( [ECO_LOT] > 0 ;' ||
                               ' [ECO_LOT] ; 1 ) ) ; 0 ) ) * ( IF ( [ECO_LOT] > 0 ; [ECO_LOT] ; 1 ) ) ; 0 )'
               else 'CHOOSE( ST( [STOCK(-1)] + [SUPPLY] - [BALANCE] - [NEED];0) ;' ||
                    '0 ; ( ROUND ((([BALANCE] + [NEED] - [STOCK(-1)] - [SUPPLY])' ||
                    ' + (STOCKCOVER * ([BALANCE(1)] + [NEED(1)]))) / (CHOOSE ( LT(ECOLOT;0);' ||
                    ' 1 ; ECOLOT) ) ) ) * ( CHOOSE ( LT(ECOLOT;0); 1 ; ECOLOT ) ))'
             end
           , aDisplayComponent
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        from dual
       where not exists(select 1
                          from FAL_PIC_FORMULA
                         where FOR_NAME = 'PDP'
                           and FOR_DISPLAY_COMPONENT = aDisplayComponent);

    -- Recherche d'une formule de PDP2 et ajout dans la table s'il n'y en a pas
    insert into FAL_PIC_FORMULA
                (FAL_PIC_FORMULA_ID
               , FOR_NAME
               , FOR_DESCRIPTION
               , FOR_DISPLAY_COMPONENT
               , A_DATECRE
               , A_IDCRE
                )
      select GetNewId
           , 'PDP2'
           , '[PDP] + [DIF]'
           , aDisplayComponent
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        from dual
       where not exists(select 1
                          from FAL_PIC_FORMULA
                         where FOR_NAME = 'PDP2'
                           and FOR_DISPLAY_COMPONENT = aDisplayComponent);

    -- Recherche d'une formule de Solde Prévisions et ajout dans la table s'il n'y en a pas
    insert into FAL_PIC_FORMULA
                (FAL_PIC_FORMULA_ID
               , FOR_NAME
               , FOR_DESCRIPTION
               , FOR_DISPLAY_COMPONENT
               , A_DATECRE
               , A_IDCRE
                )
      select GetNewId
           , 'BALANCE'
           , case aDisplayComponent
               when 'ASPO' then 'IF([PREV] - [NEED] - [REAL] < 0, 0, [PREV] - [NEED] - [REAL])'
               when 'VCI' then 'IF([PREV] - [NEED] - [REAL] < 0; 0; [PREV] - [NEED] - [REAL])'
               else 'CHOOSE(LT([PREV] - [NEED] - [REAL];0); 0; [PREV] - [NEED] - [REAL])'
             end
           , aDisplayComponent
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        from dual
       where not exists(select 1
                          from FAL_PIC_FORMULA
                         where FOR_NAME = 'BALANCE'
                           and FOR_DISPLAY_COMPONENT = aDisplayComponent);
  end CheckTableFormuleEtInitQty;

  /**
   *  procedure Suppr_Pic_Line
   *  Description : Procédure exécutée à la fin de la révision du PIC. Suppression de toutes
   *                les lignes de PIC de l'ensemble Représentant/Client/Produit/Sous-Produit
   *                qui a une date max inférieure à la date de fin de révision.
   *                (= suppression des Fal_Pic_Line pour un produit qui n'est plus géré sur
   *                PIC ou un client qui n'a plus de produit lié ou ...)
   *
   *  @param   FalPicId : ID du plan directeur
   *  @param   Datefin : Date fin PIC
   */
  procedure deletePicLines(FalPicId number, DateFin date)
  is
    -- Déclaration des curseurs
    cursor CUR_FAL_PIC_LINE1(FalPicId number)
    is
      select   PAC_REPRESENTATIVE_ID
             , PIL_GROUP_OR_THIRD
             , GCO_GOOD_ID
             , GCO_GCO_GOOD_ID
          from FAL_PIC_LINE
         where FAL_PIC_ID = FalPicId
      group by PAC_REPRESENTATIVE_ID
             , PIL_GROUP_OR_THIRD
             , GCO_GOOD_ID
             , GCO_GCO_GOOD_ID;

    -- Déclaration des variables
    PacRepresentativeId number;
    PilGroupOrThird     FAL_PIC_LINE.PIL_GROUP_OR_THIRD%type;
    GcoGoodId           number;
    GcoGcoGoodId        number;
    MaxPilDate          date;
    DateFinale          date;
  begin
    open CUR_FAL_PIC_LINE1(FalPicId);

    loop
      fetch CUR_FAL_PIC_LINE1
       into PacRepresentativeId
          , PilGroupOrThird
          , GcoGoodId
          , GcoGcoGoodId;

      exit when CUR_FAL_PIC_LINE1%notfound;

      select max(PIL_DATE)
        into MaxPilDate
        from FAL_PIC_LINE
       where FAL_PIC_ID = FalPicId
         and (    (    PAC_REPRESENTATIVE_ID is null
                   and PacRepresentativeId is null)
              or (PAC_REPRESENTATIVE_ID = PacRepresentativeId) )
         and (    (    PIL_GROUP_OR_THIRD is null
                   and PilGroupOrThird is null)
              or (PIL_GROUP_OR_THIRD = PilGroupOrThird) )
         and (    (    GCO_GCO_GOOD_ID is null
                   and GcoGcoGoodId is null)
              or (GCO_GCO_GOOD_ID = GcoGcoGoodId) )
         and GCO_GOOD_ID = GcoGoodId;

      if to_number(PCS.PC_Config.GetConfig('FAL_PIC_WEEK_MONTH') ) = 1 then
        DateFinale  := add_months(DateFin, 1);
      else
        DateFinale  := DateFin + 7;
      end if;

      if MaxPilDate < DateFinale then
        update fal_doc_prop
           set fal_pic_line_id = null
         where fal_pic_line_id in(
                 select fal_pic_line_id
                   from FAL_PIC_LINE
                  where FAL_PIC_ID = FalPicId
                    and (    (    PAC_REPRESENTATIVE_ID is null
                              and PacRepresentativeId is null)
                         or (PAC_REPRESENTATIVE_ID = PacRepresentativeId) )
                    and (    (    PIL_GROUP_OR_THIRD is null
                              and PilGroupOrThird is null)
                         or (PIL_GROUP_OR_THIRD = PilGroupOrThird) )
                    and (    (    GCO_GCO_GOOD_ID is null
                              and GcoGcoGoodId is null)
                         or (GCO_GCO_GOOD_ID = GcoGcoGoodId) )
                    and GCO_GOOD_ID = GcoGoodId);

        update fal_lot_prop
           set fal_pic_line_id = null
         where fal_pic_line_id in(
                 select fal_pic_line_id
                   from FAL_PIC_LINE
                  where FAL_PIC_ID = FalPicId
                    and (    (    PAC_REPRESENTATIVE_ID is null
                              and PacRepresentativeId is null)
                         or (PAC_REPRESENTATIVE_ID = PacRepresentativeId) )
                    and (    (    PIL_GROUP_OR_THIRD is null
                              and PilGroupOrThird is null)
                         or (PIL_GROUP_OR_THIRD = PilGroupOrThird) )
                    and (    (    GCO_GCO_GOOD_ID is null
                              and GcoGcoGoodId is null)
                         or (GCO_GCO_GOOD_ID = GcoGcoGoodId) )
                    and GCO_GOOD_ID = GcoGoodId);

        update fal_lot_prop_temp
           set fal_pic_line_id = null
         where fal_pic_line_id in(
                 select fal_pic_line_id
                   from FAL_PIC_LINE
                  where FAL_PIC_ID = FalPicId
                    and (    (    PAC_REPRESENTATIVE_ID is null
                              and PacRepresentativeId is null)
                         or (PAC_REPRESENTATIVE_ID = PacRepresentativeId) )
                    and (    (    PIL_GROUP_OR_THIRD is null
                              and PilGroupOrThird is null)
                         or (PIL_GROUP_OR_THIRD = PilGroupOrThird) )
                    and (    (    GCO_GCO_GOOD_ID is null
                              and GcoGcoGoodId is null)
                         or (GCO_GCO_GOOD_ID = GcoGcoGoodId) )
                    and GCO_GOOD_ID = GcoGoodId);

        update fal_network_need
           set fal_pic_line_id = null
         where fal_pic_line_id in(
                 select fal_pic_line_id
                   from FAL_PIC_LINE
                  where FAL_PIC_ID = FalPicId
                    and (    (    PAC_REPRESENTATIVE_ID is null
                              and PacRepresentativeId is null)
                         or (PAC_REPRESENTATIVE_ID = PacRepresentativeId) )
                    and (    (    PIL_GROUP_OR_THIRD is null
                              and PilGroupOrThird is null)
                         or (PIL_GROUP_OR_THIRD = PilGroupOrThird) )
                    and (    (    GCO_GCO_GOOD_ID is null
                              and GcoGcoGoodId is null)
                         or (GCO_GCO_GOOD_ID = GcoGcoGoodId) )
                    and GCO_GOOD_ID = GcoGoodId);

        update fal_network_supply
           set fal_pic_line_id = null
         where fal_pic_line_id in(
                 select fal_pic_line_id
                   from FAL_PIC_LINE
                  where FAL_PIC_ID = FalPicId
                    and (    (    PAC_REPRESENTATIVE_ID is null
                              and PacRepresentativeId is null)
                         or (PAC_REPRESENTATIVE_ID = PacRepresentativeId) )
                    and (    (    PIL_GROUP_OR_THIRD is null
                              and PilGroupOrThird is null)
                         or (PIL_GROUP_OR_THIRD = PilGroupOrThird) )
                    and (    (    GCO_GCO_GOOD_ID is null
                              and GcoGcoGoodId is null)
                         or (GCO_GCO_GOOD_ID = GcoGcoGoodId) )
                    and GCO_GOOD_ID = GcoGoodId);

        delete      FAL_PIC_LINE_TEMP
              where FAL_PIC_ID = FalPicId
                and (    (    PAC_REPRESENTATIVE_ID is null
                          and PacRepresentativeId is null)
                     or (PAC_REPRESENTATIVE_ID = PacRepresentativeId) )
                and (    (    PIL_GROUP_OR_THIRD is null
                          and PilGroupOrThird is null)
                     or (PIL_GROUP_OR_THIRD = PilGroupOrThird) )
                and (    (    GCO_GCO_GOOD_ID is null
                          and GcoGcoGoodId is null)
                     or (GCO_GCO_GOOD_ID = GcoGcoGoodId) )
                and GCO_GOOD_ID = GcoGoodId;

        delete      FAL_PIC_LINE_HIST
              where fal_pic_line_id in(
                      select fal_pic_line_id
                        from FAL_PIC_LINE
                       where FAL_PIC_ID = FalPicId
                         and (    (    PAC_REPRESENTATIVE_ID is null
                                   and PacRepresentativeId is null)
                              or (PAC_REPRESENTATIVE_ID = PacRepresentativeId) )
                         and (    (    PIL_GROUP_OR_THIRD is null
                                   and PilGroupOrThird is null)
                              or (PIL_GROUP_OR_THIRD = PilGroupOrThird) )
                         and (    (    GCO_GCO_GOOD_ID is null
                                   and GcoGcoGoodId is null)
                              or (GCO_GCO_GOOD_ID = GcoGcoGoodId) )
                         and GCO_GOOD_ID = GcoGoodId);

        delete      FAL_PIC_LINE
              where FAL_PIC_ID = FalPicId
                and (    (    PAC_REPRESENTATIVE_ID is null
                          and PacRepresentativeId is null)
                     or (PAC_REPRESENTATIVE_ID = PacRepresentativeId) )
                and (    (    PIL_GROUP_OR_THIRD is null
                          and PilGroupOrThird is null)
                     or (PIL_GROUP_OR_THIRD = PilGroupOrThird) )
                and (    (    GCO_GCO_GOOD_ID is null
                          and GcoGcoGoodId is null)
                     or (GCO_GCO_GOOD_ID = GcoGcoGoodId) )
                and GCO_GOOD_ID = GcoGoodId;
      end if;
    end loop;

    close CUR_FAL_PIC_LINE1;

    -- Suppression du dernier mois des FAL_PIC_LINE qui a été créé lors de la révision pour déterminer
    -- les éléments non mis à jour afin de les supprimer.
    if to_number(PCS.PC_Config.GetConfig('FAL_PIC_WEEK_MONTH') ) = 1 then
      delete      FAL_PIC_LINE
            where FAL_PIC_ID = FalPicId
              and PIL_DATE = add_months(DateFin, 1);
    else
      delete      FAL_PIC_LINE
            where FAL_PIC_ID = FalPicId
              and PIL_DATE = DateFin + 7;
    end if;
  end deletePicLines;

  function Calcul_Appro(GoodId number, DateDebut date, PivotDate FAL_PIC.PIC_PIVOT_DATE%type)
    return number
  is
    -- Déclaration des variables
    result  number;
    DateFin date;
    Appro1  number;
  begin
    result  := 0;

    if to_number(PCS.PC_Config.GetConfig('FAL_PIC_WEEK_MONTH') ) = 1 then
      DateFin  := add_months(DateDebut, PCS.PC_Config.GetConfig('FAL_PIC_PERIOD_NUMBER') );
    else
      DateFin  := DateDebut +(7 * PCS.PC_Config.GetConfig('FAL_PIC_PERIOD_NUMBER') );
    end if;

    if    (PivotDate is null)
       or (     (PivotDate is not null)
           and (PivotDate > DateFin) ) then
      -- Avant la date pivot ou pas de date pivot : on prend toutes les appros
      select sum(FAN_BALANCE_QTY)
        into result
        from FAL_NETWORK_SUPPLY FNS
           , STM_STOCK SS
       where GCO_GOOD_ID = GoodId
         and trunc(FAN_END_PLAN) >= DateDebut
         and trunc(FAN_END_PLAN) < DateFin
         and FNS.STM_STOCK_ID = SS.STM_STOCK_ID
         and STO_NEED_PIC = 1
         and FNS.FAL_DOC_PROP_ID is null
         and FNS.FAL_LOT_PROP_ID is null;
    elsif PivotDate <= DateDebut then
      -- Après la date pivot : on prend toutes les appros sauf celles de positions
      -- types 7 et 8
      select sum(FAN_BALANCE_QTY)
        into result
        from FAL_NETWORK_SUPPLY FNS
           , STM_STOCK SS
       where GCO_GOOD_ID = GoodId
         and trunc(FAN_END_PLAN) >= DateDebut
         and trunc(FAN_END_PLAN) < DateFin
         and not exists(select DOC_POSITION_ID
                          from DOC_POSITION
                         where DOC_POSITION_ID = FNS.DOC_POSITION_ID
                           and C_GAUGE_TYPE_POS in('7', '8') )
         and FNS.STM_STOCK_ID = SS.STM_STOCK_ID
         and STO_NEED_PIC = 1
         and FNS.FAL_DOC_PROP_ID is null
         and FNS.FAL_LOT_PROP_ID is null;
    else   --Date pivot comprise entre date début et date fin
      -- on prend toutes les appros entre la date début et la date pivot...
      select sum(FAN_BALANCE_QTY)
        into result
        from FAL_NETWORK_SUPPLY FNS
           , STM_STOCK SS
       where GCO_GOOD_ID = GoodId
         and trunc(FAN_END_PLAN) >= DateDebut
         and trunc(FAN_END_PLAN) < PivotDate
         and FNS.STM_STOCK_ID = SS.STM_STOCK_ID
         and STO_NEED_PIC = 1
         and FNS.FAL_DOC_PROP_ID is null
         and FNS.FAL_LOT_PROP_ID is null;

      -- ... + les appros qui ne sont pas de type 7 ou 8 entre
      -- la date pivot et la date fin
      select sum(FAN_BALANCE_QTY)
        into Appro1
        from FAL_NETWORK_SUPPLY FNS
           , STM_STOCK SS
       where GCO_GOOD_ID = GoodId
         and trunc(FAN_END_PLAN) >= PivotDate
         and trunc(FAN_END_PLAN) < DateFin
         and not exists(select DOC_POSITION_ID
                          from DOC_POSITION
                         where DOC_POSITION_ID = FNS.DOC_POSITION_ID
                           and C_GAUGE_TYPE_POS in('7', '8') )
         and FNS.STM_STOCK_ID = SS.STM_STOCK_ID
         and STO_NEED_PIC = 1
         and FNS.FAL_DOC_PROP_ID is null
         and FNS.FAL_LOT_PROP_ID is null;

      result  := nvl(result, 0) + nvl(Appro1, 0);
    end if;

    return nvl(result, 0);
  end;

  procedure MajValorisation(
    FalPicId                 number
  , PicValueCostprice        FAL_PIC.PIC_VALUE_COSTPRICE%type
  , DicTariffId              FAL_PIC.DIC_TARIFF_ID%type
  , DicFixedCostpriceDescrId FAL_PIC.DIC_FIXED_COSTPRICE_DESCR_ID%type
  )
  is
    cursor CUR_FAL_PIC_LINE(FalPicId number)
    is
      select distinct GCO_GOOD_ID
                    , PIL_GROUP_OR_THIRD
                 from FAL_PIC_LINE
                where FAL_PIC_ID = FalPicId;

    cursor CUR_FAL_PIC_LINE2(FalPicId number)
    is
      select FAL_PIC_LINE_ID
           , GCO_GOOD_ID
           , PIL_GROUP_OR_THIRD
           , PIL_DATE
        from FAL_PIC_LINE
       where FAL_PIC_ID = FalPicId;

    CurFalPicLine  CUR_FAL_PIC_LINE%rowtype;
    CurFalPicLine2 CUR_FAL_PIC_LINE2%rowtype;
    UnitValue      FAL_PIC_LINE.PIL_UNIT_VALUE%type;
  begin
    if PCS.PC_Config.GetConfig('FAL_PIC_UNIT_VALUE_DATE') = 'False' then
      open CUR_FAL_PIC_LINE(FalPicId);

      loop
        fetch CUR_FAL_PIC_LINE
         into CurFalPicLine;

        exit when CUR_FAL_PIC_LINE%notfound;
        UnitValue  :=
                    GetUnitValue(CurFalPicLine.PIL_GROUP_OR_THIRD, CurFalPicLine.GCO_GOOD_ID, PicValueCostprice, DicTariffId, DicFixedCostpriceDescrId, sysdate);

        update FAL_PIC_LINE
           set PIL_UNIT_VALUE = UnitValue
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where FAL_PIC_ID = FalPicId
           and GCO_GOOD_ID = CurFalPicLine.GCO_GOOD_ID
           and nvl(PIL_GROUP_OR_THIRD, 0) = nvl(CurFalPicLine.PIL_GROUP_OR_THIRD, 0);
      end loop;

      close CUR_FAL_PIC_LINE;
    else
      open CUR_FAL_PIC_LINE2(FalPicId);

      loop
        fetch CUR_FAL_PIC_LINE2
         into CurFalPicLine2;

        exit when CUR_FAL_PIC_LINE2%notfound;
        UnitValue  :=
          GetUnitValue(CurFalPicLine2.PIL_GROUP_OR_THIRD
                     , CurFalPicLine2.GCO_GOOD_ID
                     , PicValueCostprice
                     , DicTariffId
                     , DicFixedCostpriceDescrId
                     , CurFalPicLine2.PIL_DATE
                      );

        update FAL_PIC_LINE
           set PIL_UNIT_VALUE = UnitValue
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where FAL_PIC_LINE_ID = CurFalPicLine2.FAL_PIC_LINE_ID;
      end loop;

      close CUR_FAL_PIC_LINE2;
    end if;
  end;

  procedure UpdateOrdersActiveMasterPlan
  is
    -- Déclaration des curseurs
    cursor CUR_PIVOT_DATE
    is
      select   PIC_PIVOT_DATE
          from FAL_PIC
         where C_PIC_STATUS <> '1'
      order by PIC_END_DATE desc;

    -- Le lien sur GP.GCO2_GCO_GOOD_ID sert à aller chercher les besoins du
    -- produit PIC lié s'il existe.
    -- Dans l'union on va chercher les détails position des BL non confirmés
    cursor CUR_FAL_NETWORK_NEED(PivotDate FAL_PIC.PIC_PIVOT_DATE%type)
    is
      select distinct fnn.fal_network_need_id table_id
                    , fnn.fan_beg_plan delay_date
                    , fnn.pac_third_id
                    , fnn.pac_representative_id
                    , fnn.fan_balance_qty balance_qty
                    , fpl.gco_good_id
                 from fal_network_need fnn
                    , fal_pic_line fpl
                    , gco_product gp
                where fnn.doc_position_detail_id is not null
                  and fpl.pil_actif = 1
                  and fpl.gco_good_id = gp.gco2_gco_good_id(+)
                  and fnn.gco_good_id = nvl(gp.gco_good_id, fpl.gco_good_id)
                  and fnn.fan_beg_plan is not null
                  and (select nvl(sto.sto_need_pic, 0)
                         from stm_stock sto
                        where sto.stm_stock_id = fnn.stm_stock_id) = 1
                  and (select nvl(dgs.gas_update_pic_order_qty, 0)
                         from doc_gauge_structured dgs
                        where dgs.doc_gauge_id = fnn.doc_gauge_id) = 1
                  and (    (PivotDate is null)
                       or (    PivotDate is not null
                           and fnn.fan_beg_plan < PivotDate) )
      union
      select distinct dpd1.doc_position_detail_id table_id
                    , dd1.dmt_date_value
                    , dpd1.pac_third_id
                    , dp1.pac_representative_id
                    , dpd1.pde_balance_quantity balance_qty
                    , fpl1.gco_good_id
                 from doc_position_detail dpd1
                    , doc_position dp1
                    , doc_document dd1
                    , fal_pic_line fpl1
                    , gco_product gp1
                where dpd1.doc_position_id = dp1.doc_position_id
                  and dp1.doc_document_id = dd1.doc_document_id
                  and dp1.c_doc_pos_status = '01'
                  and nvl(pde_balance_quantity, 0) > 0
                  and fpl1.gco_good_id = gp1.gco2_gco_good_id(+)
                  and dpd1.gco_good_id = nvl(gp1.gco_good_id, fpl1.gco_good_id)
                  and fpl1.pil_actif = 1
                  and dp1.c_gauge_type_pos in('1', '2', '3', '71', '81', '91', '101')
                  and dd1.dmt_date_value is not null
                  and (select nvl(sto1.sto_need_pic, 0)
                         from stm_stock sto1
                        where sto1.stm_stock_id = dp1.stm_stock_id) = 1
                  and (select nvl(dgs1.gas_update_pic_order_qty, 0)
                         from doc_gauge_structured dgs1
                        where dgs1.doc_gauge_id = dd1.doc_gauge_id) = 1
                  and (    (PivotDate is null)
                       or (    PivotDate is not null
                           and dd1.dmt_date_value < PivotDate) );

    cursor CUR_PAC_CUSTOM_PARTNER(PacThirdId FAL_NETWORK_NEED.PAC_THIRD_ID%type)
    is
      select DIC_PIC_GROUP_ID
        from PAC_CUSTOM_PARTNER
       where PAC_CUSTOM_PARTNER_ID = PacThirdId;

    DicPicGroupId  PAC_CUSTOM_PARTNER.DIC_PIC_GROUP_ID%type;
    BuffSQL        varchar2(2000);
    Cursor_Handle  integer;
    Execute_Cursor integer;
    PivotDate      FAL_PIC.PIC_PIVOT_DATE%type;
  begin
    PivotDate  := null;

    open CUR_PIVOT_DATE;

    fetch CUR_PIVOT_DATE
     into PivotDate;

    close CUR_PIVOT_DATE;

    -- Mise à 0 de tous les Qté commandes clients des PIC actifs
    update FAL_PIC_LINE
       set PIL_ORDER_QTY = 0
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where PIL_ACTIF = 1;

    if trim(PCS.PC_Config.GetConfig('FAL_PIC_PROC_UPDATE_ORDERS') ) is null then
      -- Sélection des produits des PIC actifs
      for CurFalNetworkNeed in CUR_FAL_NETWORK_NEED(PivotDate) loop
        if CurFalNetworkNeed.PAC_THIRD_ID is null then
          DicPicGroupId  := null;
        else
          open CUR_PAC_CUSTOM_PARTNER(CurFalNetworkNeed.PAC_THIRD_ID);

          fetch CUR_PAC_CUSTOM_PARTNER
           into DicPicGroupId;

          if CUR_PAC_CUSTOM_PARTNER%notfound then
            DicPicGroupId  := null;
          end if;

          close CUR_PAC_CUSTOM_PARTNER;
        end if;

        ProcessusMajQteCmdPicLine(CurFalNetworkNeed.GCO_GOOD_ID
                                , CurFalNetworkNeed.DELAY_DATE
                                , CurFalNetworkNeed.PAC_THIRD_ID
                                , CurFalNetworkNeed.PAC_REPRESENTATIVE_ID
                                , CurFalNetworkNeed.BALANCE_QTY
                                , DicPicGroupId
                                 );
      end loop;
    else
      -- Exécution de la procédure individualisée de mise à jour commandes clients
      -- définie dans la config FAL_PIC_PROC_UPDATE_ORDERS
      BuffSql         := ' BEGIN ';
      BuffSql         := BuffSql || PCS.PC_Config.GetConfig('FAL_PIC_PROC_UPDATE_ORDERS') || ';';
      BuffSql         := BuffSql || ' END;';
      Cursor_Handle   := DBMS_SQL.OPEN_CURSOR;
      DBMS_SQL.PARSE(Cursor_Handle, BuffSql, DBMS_SQL.V7);
      Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);
      DBMS_SQL.CLOSE_CURSOR(Cursor_Handle);
    end if;
  end;

  procedure Valid_Revision(FalPicId number)
  is
    CPicStatus FAL_PIC.C_PIC_STATUS%type;
  begin
    select C_PIC_STATUS
      into CPicStatus
      from FAL_PIC
     where FAL_PIC_ID = FalPicId;

    -- On ne valide la révision que si ça n'a pas déjà été
    -- (le CB peut aussi valider la révision et il y avait un problème quand
    -- on cliquait ensuite sur "Valider révision" dans pe Plan Dir. = perte de dates)
    if CPicStatus = 3 then
      -- Sauvegarde des prévisions modifiées dans la table d'historique
      insert into FAL_PIC_LINE_HIST
                  (FAL_PIC_LINE_HIST_ID
                 , FAL_PIC_LINE_ID
                 , PIL_PREV_QTY
                 , A_DATECRE
                 , A_IDCRE
                  )
        select GetNewId
             , FAL_PIC_LINE_ID
             , PIL_REVISION_QTY
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from FAL_PIC_LINE FPL
         where FAL_PIC_ID = FalPicId
           and (    (PIL_PREV_QTY <> PIL_REVISION_QTY)
                or (     (PIL_REVISION_QTY <> 0)
                    and not exists(select FAL_PIC_LINE_HIST_ID
                                     from FAL_PIC_LINE_HIST
                                    where FAL_PIC_LINE_ID = FPL.FAL_PIC_LINE_ID) ) );

      -- processus MAJ validation révision PIC
      -- Valider Révision PC --2--
      update FAL_PIC
         set PIC_VALID_BEGIN_DATE = PIC_AUDIT_BEGIN_DATE
           , PIC_VALID_END_DATE = PIC_AUDIT_END_DATE
           , C_PIC_STATUS = '2'
           , PIC_PDP_CALCUL = 0
           , PIC_AUDIT_BEGIN_DATE = null
           , PIC_AUDIT_END_DATE = null
           , PIC_DATE_CALCUL = null
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_PIC_ID = FalPicId;

      -- Valider Révision PC --3--
      update FAL_PIC_LINE
         set PIL_PREV_QTY_TEMP = PIL_PREV_QTY
           , PIL_PREV_QTY = PIL_REVISION_QTY
           , PIL_REVISION_QTY = 0
           , PIL_DIF_VALID_QTY = PIL_DIF_REVISION_QTY
           , PIL_DIF_REVISION_QTY = null
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_PIC_ID = FalPicId
         and PIL_DATE >= (select PIC_VALID_BEGIN_DATE
                            from FAL_PIC
                           where FAL_PIC_ID = FalPicId);
    end if;
  end;

  procedure PrepareFalPicLineToDisplay(UserCode number)
  is
    cursor Cur_Fal_Pic_Line_Temp
    is
      select   *
          from FAL_PIC_LINE_TEMP
         where PIT_USER_CODE = UserCode
      order by PAC_REPRESENTATIVE_ID
             , PIL_CUSTOM_PARTNER
             , PIL_GROUP_OR_THIRD
             , GCO_GCO_GOOD_ID
             , GCO_GOOD_ID
             , PIL_DATE;

    MonthNumber   integer;
    CurrentRecord number;
    DateMax       FAL_PIC_LINE.PIL_DATE%type;
  begin
    MonthNumber  := 1;

    select max(PIL_DATE)
      into DateMax
      from FAL_PIC_LINE_TEMP
     where PIT_USER_CODE = UserCode;

    for CurFalPicLineTemp in Cur_Fal_Pic_Line_Temp loop
      if (MonthNumber = 1) then
        CurrentRecord  := CurFalPicLineTemp.FAL_PIC_LINE_ID;
      else
        update FAL_PIC_LINE_TEMP
           set PIL_PREV_QTY = PIL_PREV_QTY + CurFalPicLineTemp.PIL_PREV_QTY
             , PIL_REVISION_QTY = PIL_REVISION_QTY + CurFalPicLineTemp.PIL_REVISION_QTY
             , PIL_DIF_VALID_QTY = PIL_DIF_VALID_QTY + CurFalPicLineTemp.PIL_DIF_VALID_QTY
             , PIL_DIF_REVISION_QTY = PIL_DIF_REVISION_QTY + CurFalPicLineTemp.PIL_DIF_REVISION_QTY
             , PIL_REAL_QTY = PIL_REAL_QTY + CurFalPicLineTemp.PIL_REAL_QTY
             , PIL_ORDER_QTY = PIL_ORDER_QTY + CurFalPicLineTemp.PIL_ORDER_QTY
             , PIL_PREV_QTY_TEMP = PIL_PREV_QTY_TEMP + CurFalPicLineTemp.PIL_PREV_QTY_TEMP
             , PIT_NUMBER_OF_MONTHS = MonthNumber
         where FAL_PIC_LINE_ID = CurrentRecord
           and PIT_USER_CODE = UserCode;

        update FAL_PIC_LINE_TEMP
           set PIT_OBSOLETE = 1
         where FAL_PIC_LINE_ID = CurFalPicLineTemp.FAL_PIC_LINE_ID
           and PIT_USER_CODE = UserCode;
      end if;

      if    (MonthNumber >= PCS.PC_Config.GetConfig('FAL_PIC_PERIOD_NUMBER') )
         or (trunc(CurFalPicLineTemp.PIL_DATE) = trunc(DateMax) ) then
        MonthNumber  := 1;
      else
        MonthNumber  := MonthNumber + 1;
      end if;
    end loop;

    delete from FAL_PIC_LINE_TEMP
          where PIT_USER_CODE = UserCode
            and PIT_OBSOLETE = 1;
  end;

  procedure UpdateFalPicLine(
    FalPicLineID          number
  , ModifPDP              number
  , InRevision            number
  , PrevToDispatch        FAL_PIC_LINE.PIL_PREV_QTY%type
  , RevisionToDispatch    FAL_PIC_LINE.PIL_REVISION_QTY%type
  , PdpToDispatch         FAL_PIC_LINE.PIL_PDP_QTY%type
  , DifValidToDispatch    FAL_PIC_LINE.PIL_DIF_VALID_QTY%type
  , DifRevisionToDispatch FAL_PIC_LINE.PIL_DIF_REVISION_QTY%type
  )
  is
  begin
    if InRevision = 0 then
      -- Les modifications viennent de la préparation
      if ModifPDP = 0 then
        -- Les modifications viennent d'un clic sur bouton PC
        update FAL_PIC_LINE
           set PIL_PREV_QTY = PrevToDispatch
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where FAL_PIC_LINE_ID = FalPicLineID;
      else
        -- Les modifications viennent d'un clic sur bouton PDP
        update FAL_PIC_LINE
           set PIL_PREV_QTY = PrevToDispatch
             , PIL_DIF_VALID_QTY = DifValidToDispatch
             , PIL_PDP_QTY = PdpToDispatch
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where FAL_PIC_LINE_ID = FalPicLineID;
      end if;
    else
      -- Les modifications viennent d'une révision
      if ModifPDP = 0 then
        -- Les modifications viennent d'un clic sur bouton PC
        update FAL_PIC_LINE
           set PIL_REVISION_QTY = RevisionToDispatch
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where FAL_PIC_LINE_ID = FalPicLineID;
      else
        -- Les modifications viennent d'un clic sur bouton PDP
        update FAL_PIC_LINE
           set PIL_REVISION_QTY = RevisionToDispatch
             , PIL_DIF_REVISION_QTY = DifRevisionToDispatch
             , PIL_PDP_QTY = PdpToDispatch
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where FAL_PIC_LINE_ID = FalPicLineID;
      end if;
    end if;
  end;

  procedure DispatchFalPicLineTemp(UserCode number, ModifPDP number, InRevision number)
  is
    cursor Cur_Fal_Pic_Line_Temp
    is
      select   *
          from FAL_PIC_LINE_TEMP
         where PIT_USER_CODE = UserCode
      order by PAC_REPRESENTATIVE_ID
             , PIL_CUSTOM_PARTNER
             , PIL_GROUP_OR_THIRD
             , GCO_GCO_GOOD_ID
             , GCO_GOOD_ID
             , PIL_DATE;

    cursor Cur_Fal_Pic_Line(
      FalPicId            number
    , PilDate             FAL_PIC_LINE.PIL_DATE%type
    , PacRepresentativeId number
    , PilCustomPartner    FAL_PIC_LINE.PIL_CUSTOM_PARTNER%type
    , PilGroupOrThird     FAL_PIC_LINE.PIL_GROUP_OR_THIRD%type
    , GcoGcoGoodId        number
    , GcoGoodId           number
    )
    is
      select   FAL_PIC_LINE_ID
          from FAL_PIC_LINE
         where FAL_PIC_ID = FalPicId
           and PIL_DATE >= PilDate
           and nvl(PAC_REPRESENTATIVE_ID, 0) = nvl(PacRepresentativeId, 0)
           and nvl(PIL_CUSTOM_PARTNER, 0) = nvl(PilCustomPartner, 0)
           and nvl(PIL_GROUP_OR_THIRD, 0) = nvl(PilGroupOrThird, 0)
           and nvl(GCO_GCO_GOOD_ID, 0) = nvl(GcoGcoGoodId, 0)
           and GCO_GOOD_ID = GcoGoodId
      order by PIL_DATE;

    CurFalPicLine         Cur_Fal_Pic_Line%rowtype;
    PrevToDispatch        FAL_PIC_LINE.PIL_PREV_QTY%type;
    RevisionToDispatch    FAL_PIC_LINE.PIL_REVISION_QTY%type;
    PdpToDispatch         FAL_PIC_LINE.PIL_PDP_QTY%type;
    DifValidToDispatch    FAL_PIC_LINE.PIL_DIF_VALID_QTY%type;
    DifRevisionToDispatch FAL_PIC_LINE.PIL_DIF_REVISION_QTY%type;
    NumberOfMonths        integer;
  begin
    for CurFalPicLineTemp in Cur_Fal_Pic_Line_Temp loop
      NumberOfMonths  := CurFalPicLineTemp.PIT_NUMBER_OF_MONTHS;

      if NumberOfMonths = 1 then
        PrevToDispatch         := 0;
        RevisionToDispatch     := 0;
        PdpToDispatch          := 0;
        DifValidToDispatch     := 0;
        DifRevisionToDispatch  := 0;
      else
        PrevToDispatch         := round(CurFalPicLineTemp.PIL_PREV_QTY / NumberOfMonths);
        RevisionToDispatch     := round(CurFalPicLineTemp.PIL_REVISION_QTY / NumberOfMonths);
        PdpToDispatch          := round(CurFalPicLineTemp.PIL_PDP_QTY / NumberOfMonths);
        DifValidToDispatch     := round(CurFalPicLineTemp.PIL_DIF_VALID_QTY / NumberOfMonths);
        DifRevisionToDispatch  := round(CurFalPicLineTemp.PIL_DIF_REVISION_QTY / NumberOfMonths);
      end if;

      open Cur_Fal_Pic_Line(CurFalPicLineTemp.FAL_PIC_ID
                          , CurFalPicLineTemp.PIL_DATE
                          , CurFalPicLineTemp.PAC_REPRESENTATIVE_ID
                          , CurFalPicLineTemp.PIL_CUSTOM_PARTNER
                          , CurFalPicLineTemp.PIL_GROUP_OR_THIRD
                          , CurFalPicLineTemp.GCO_GCO_GOOD_ID
                          , CurFalPicLineTemp.GCO_GOOD_ID
                           );

      loop
        fetch Cur_Fal_Pic_Line
         into CurFalPicLine;

        exit when Cur_Fal_Pic_Line%notfound
              or (NumberOfMonths = 1);
        UpdateFalPicLine(CurFalPicLine.FAL_PIC_LINE_ID
                       , ModifPDP
                       , InRevision
                       , PrevToDispatch
                       , RevisionToDispatch
                       , PdpToDispatch
                       , DifValidToDispatch
                       , DifRevisionToDispatch
                        );
        NumberOfMonths  := NumberOfMonths - 1;
      end loop;

      close Cur_Fal_Pic_Line;

      UpdateFalPicLine(CurFalPicLine.FAL_PIC_LINE_ID
                     , ModifPDP
                     , InRevision
                     , CurFalPicLineTemp.PIL_PREV_QTY -(PrevToDispatch *(CurFalPicLineTemp.PIT_NUMBER_OF_MONTHS - 1) )
                     , CurFalPicLineTemp.PIL_REVISION_QTY -(RevisionToDispatch *(CurFalPicLineTemp.PIT_NUMBER_OF_MONTHS - 1) )
                     , CurFalPicLineTemp.PIL_PDP_QTY -(PdpToDispatch *(CurFalPicLineTemp.PIT_NUMBER_OF_MONTHS - 1) )
                     , CurFalPicLineTemp.PIL_DIF_VALID_QTY -(DifValidToDispatch *(CurFalPicLineTemp.PIT_NUMBER_OF_MONTHS - 1) )
                     , CurFalPicLineTemp.PIL_DIF_REVISION_QTY -(DifRevisionToDispatch *(CurFalPicLineTemp.PIT_NUMBER_OF_MONTHS - 1) )
                      );
    end loop;
  end;

  /**
   * procedure DeleteFalPicLineTemp
   * Description :
   * @author ECA
   * @version 26.05.2008
   * @param   aPIT_SESSION : Session oracle
   */
  procedure DeleteFalPicLineTemp(aPIT_SESSION varchar2)
  is
    cursor crOracleSession
    is
      select distinct PIT_SESSION
                 from FAL_PIC_LINE_TEMP;
  begin
    delete from FAL_PIC_LINE_TEMP
          where PIT_SESSION = aPIT_SESSION;

    for tplOracleSession in crOracleSession loop
      if COM_FUNCTIONS.Is_Session_Alive(tplOracleSession.PIT_SESSION) = 0 then
        delete from FAL_PIC_LINE_TEMP
              where PIT_SESSION = tplOracleSession.PIT_SESSION;
      end if;
    end loop;
  end;

  procedure DeleteFalPicLineToDisplay(iUserCode in FAL_PIC_LINE_TEMP.PIT_USER_CODE%type)
  as
  begin
    delete from FAL_PIC_LINE_TEMP
          where PIT_USER_CODE = iUserCode;
  end DeleteFalPicLineToDisplay;
end FAL_PRC_MASTER_PLAN;
