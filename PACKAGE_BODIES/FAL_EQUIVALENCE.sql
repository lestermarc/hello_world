--------------------------------------------------------
--  DDL for Package Body FAL_EQUIVALENCE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_EQUIVALENCE" 
is
  -- Renvoie aValue arrondi à la valeur suppérieure au nombre de décimales aDecimalNumber
  function ArrondiSup(aValue number, aDecimalNumber number)
    return number
  is
    result number;
  begin
    -- Valeur * (10 exposant NbreDecimale) (Ex : 12,241 et DecimalNumber = 2 -> 1224,1)
    result  := aValue * power(10, aDecimalNumber);

    -- S'il reste une partie entière, on incrémente de 1 (arrondi sup)
    if (result - floor(result) ) > 0 then
      result  := trunc(result) + 1;
    end if;

    result  := result / power(10, aDecimalNumber);
    return result;
  end;

  function GetUnitValueFromConsultHist(PacSupplierPartnerId number, PacThirdTariffId number, GcoGoodId number, GcoGcoGoodId number, Pac2SupplierPartnerId number)
    return FAL_DOC_CONSULT.FDC_GROSS_UNIT_VALUE%type
  is
    cursor CUR_UNIT_VALUE
    is
      select   FDC_GROSS_UNIT_VALUE
          from FAL_DOC_CONSULT_HIST
         where PAC_SUPPLIER_PARTNER_ID = PacSupplierPartnerId
           and PAC_THIRD_TARIFF_ID = PacThirdTariffId
           and GCO_GOOD_ID = GcoGoodId
           and GCO2_GOOD_ID = GcoGcoGoodId
           and PAC2_SUPPLIER_PARTNER_ID = Pac2SupplierPartnerId
      order by A_DATECRE desc;

    CurUnitValue CUR_UNIT_VALUE%rowtype;
  begin
    open CUR_UNIT_VALUE;

    fetch CUR_UNIT_VALUE
     into CurUnitValue;

    if CUR_UNIT_VALUE%found then
      return CurUnitValue.FDC_GROSS_UNIT_VALUE;
    else
      return 0;
    end if;

    close CUR_UNIT_VALUE;
  end;

  procedure GetUnitValueConsult(
    aGcoGcoGoodId                 number
  , aGcoGoodId                    number
  , aPacSupplierPartnerId         number
  , aPacThirdTariffId             number
  , aFdcBasisQuantity             number
  , aDate                         date
  , aAcsFinancialCurrId           number
  , aPac2SupplierPartnerId        number
  , aUnitValueConsult      in out number
  )
  is
    vNet                number;
    vSpecial            number;
    vDic_Tariff         PAC_SUPPLIER_PARTNER.DIC_TARIFF_ID%type   := null;
    vRoundType          PTC_TARIFF.C_ROUND_TYPE%type;
    vRoundAmount        PTC_TARIFF.TRF_ROUND_AMOUNT%type;
    vAcsFinancialCurrId number;
    lFlatRate           number;
    lTariffUnit         number;
  begin
    vAcsFinancialCurrId  := aAcsFinancialCurrId;

    if FAL_TOOLS.NIFZ(aGcoGcoGoodId) is null then
      aUnitValueConsult  :=
        GCO_I_LIB_PRICE.GetGoodPrice(iGoodId              => aGcoGoodId
                                   , iTypePrice           => '1'   -- aTypePrice (1 = tarif d'achat)
                                   , iThirdId             => aPacThirdTariffId
                                   , iRecordId            => null   -- aRecordId
                                   , iFalScheduleStepId   => null   -- aFalScheduleStepId
                                   , ioDicTariff          => vDic_Tariff
                                   , iQuantity            => aFdcBasisQuantity   -- aQuantity
                                   , iDateRef             => sysdate   --aDate                 -- aDateRef
                                   , ioRoundType          => vRoundType
                                   , ioRoundAmount        => vRoundAmount
                                   , ioCurrencyId         => vAcsFinancialCurrId
                                   , oNet                 => vNet
                                   , oSpecial             => vSpecial
                                   , oFlatRate            => lFlatRate
                                   , oTariffUnit          => lTariffUnit
                                    );
    else
      aUnitValueConsult  := GetUnitValueFromConsultHist(aPacSupplierPartnerId, aPacThirdTariffId, aGcoGoodId, aGcoGcoGoodId, aPac2SupplierPartnerId);
    end if;
  end;

  function GetUnitValueConsult(
    aGcoGcoGoodId          number
  , aGcoGoodId             number
  , aPacSupplierPartnerId  number
  , aPacThirdTariffId      number
  , aFdcBasisQuantity      number
  , aDate                  date
  , aAcsFinancialCurrId    number
  , aPac2SupplierPartnerId number
  )
    return number
  is
    vUnitValueConsult number;
  begin
    GetUnitValueConsult(aGcoGcoGoodId
                      , aGcoGoodId
                      , aPacSupplierPartnerId
                      , aPacThirdTariffId
                      , aFdcBasisQuantity
                      , aDate
                      , aAcsFinancialCurrId
                      , aPac2SupplierPartnerId
                      , vUnitValueConsult
                       );
    return vUnitValueConsult;
  end;

  /* Processus de création des consultations */
  procedure Process_Creation_Consultations(
    aFalDocPropId          number   -- Proposition
  , aPacSupplierPartnerId  number   -- Fournisseur
  , aPacThirdAciId         number   -- Tiers facturation
  , aPacThirdDeliveryId    number   -- Tiers livraison
  , aPacThirdTariffId      number   -- Tiers tarification
  , aPac2SupplierPartnerId number   -- Fabricant
  , aGcoGoodId             number   -- Produit
  , aGcoGcoGoodId          number   -- Produit équivalent
  , aCdaComplementaryRef   GCO_COMPL_DATA_PURCHASE.CDA_COMPLEMENTARY_REFERENCE%type   -- Référence complémentaire
  , aCdaShortDescription   GCO_COMPL_DATA_PURCHASE.CDA_SHORT_DESCRIPTION%type   -- Description courte produit
  , aFdpText               FAL_DOC_PROP.FDP_TEXTE%type   -- Description courte
  , aCdaConversionFactor   GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type   -- Facteur de conversion
  , aDicUnitOfMeasureId    GCO_COMPL_DATA_PURCHASE.DIC_UNIT_OF_MEASURE_ID%type   -- Unité d'achat
  , aCdaNumberOfDecimal    GCO_COMPL_DATA_PURCHASE.CDA_NUMBER_OF_DECIMAL%type   -- Nombre de décimale gérée
  , aFdpBasisQty           FAL_DOC_PROP.FDP_BASIS_QTY%type   -- Qté de base
  , aFdpConvertFactor      FAL_DOC_PROP.FDP_CONVERT_FACTOR%type   -- Facteur de conversion
  , aFdpFinalDelay         FAL_DOC_PROP.FDP_FINAL_DELAY%type   -- Délai final
  , aDocRecordId           number
  , aDocGaugeId            number
  , aStmStockId            number
  , aStmLocationId         number
  , aGcoCharac1            number
  , aGcoCharac2            number
  , aGcoCharac3            number
  , aGcoCharac4            number
  , aGcoCharac5            number
  , aFadCharac1            FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_1%type
  , aFadCharac2            FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_2%type
  , aFadCharac3            FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_3%type
  , aFadCharac4            FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_4%type
  , aFadCharac5            FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_5%type
  , aFdcCompteur           number
  , aCpu_Percent_Sourcing  GCO_COMPL_DATA_PURCHASE.CPU_PERCENT_SOURCING%type
  , aFDC_NEGOTIATION       integer
  )
  is
    cursor CUR_GCO_GOOD(aGcoGoodId number)
    is
      select DIC_UNIT_OF_MEASURE_ID
           , GOO_NUMBER_OF_DECIMAL
        from GCO_GOOD
       where GCO_GOOD_ID = aGcoGoodId;

    FdcBasisQuantity           FAL_DOC_CONSULT.FDC_BASIS_QUANTITY%type;
    tplGcoGood                 CUR_GCO_GOOD%rowtype;
    Fdc2BasisQuantity          FAL_DOC_CONSULT.FDC2_BASIS_QUANTITY%type;
    FdcGrossUnitValue          FAL_DOC_CONSULT.FDC_GROSS_UNIT_VALUE%type;
    FdcGrossValueBasisCurrency FAL_DOC_CONSULT.FDC_GROSS_VALUE_BASIS_CURRENCY%type;
    FdcTariffUnitValue         FAL_DOC_CONSULT.FDC_TARIFF_UNIT_VALUE%type;
    vDic_Tariff                PAC_SUPPLIER_PARTNER.DIC_TARIFF_ID%type               := null;
    vRoundType                 PTC_TARIFF.C_ROUND_TYPE%type;
    vRoundAmount               PTC_TARIFF.TRF_ROUND_AMOUNT%type;
    vAcsFinancialCurrId        number;
    vNet                       number;
    vSpecial                   number;
    lFlatRate                  number;
    lTariffUnit                number;
  begin
    -- Calcul de la Qté de base unité achat
    FdcBasisQuantity     := ArrondiSup(nvl(aFdpBasisQty, 0) * nvl(aFdpConvertFactor, 0) / nvl(aCdaConversionFactor, 1), nvl(aCdaNumberOfDecimal, 0) );

    -- Récupération de l'unité de gestion et du nombre de décimal gestion
    open CUR_GCO_GOOD(aGcoGoodId);

    fetch CUR_GCO_GOOD
     into tplGcoGood;

    close CUR_GCO_GOOD;

    -- Calcul de la Qté de base unité gestion
    Fdc2BasisQuantity    := ArrondiSup(nvl(aFdpBasisQty, 0) * nvl(aFdpConvertFactor, 0), nvl(tplGcoGood.GOO_NUMBER_OF_DECIMAL, 0) );
    vAcsFinancialCurrId  := DOC_DOCUMENT_FUNCTIONS.GetThirdCurrencyID(aDocGaugeId, aPacThirdAciId);

    -- Valeur unitaire
    if aFDC_NEGOTIATION = 0 then
      FdcGrossUnitValue  :=
        GetUnitValueConsult(aGcoGcoGoodId
                          , aGcoGoodId
                          , aPacSupplierPartnerId
                          , aPacThirdTariffId
                          , FdcBasisQuantity
                          , sysdate
                          , vAcsFinancialCurrId
                          , aPac2SupplierPartnerId
                           );
    else
      FdcGrossUnitValue  := 0;
    end if;

    -- Tarif unitaire Mon Fournisseur du produit equivalent
    begin
      if FAL_TOOLS.NIFZ(aGcoGcoGoodId) is not null then
        FdcTariffUnitValue  :=
          GCO_I_LIB_PRICE.GetGoodPrice(iGoodId              => aGcoGcoGoodId
                                     , iTypePrice           => '1'   -- aTypePrice (1 = tarif d'achat)
                                     , iThirdId             => aPacThirdTariffId
                                     , iRecordId            => null   -- aRecordId
                                     , iFalScheduleStepId   => null   -- aFalScheduleStepId
                                     , ioDicTariff          => vDic_Tariff
                                     , iQuantity            => FdcBasisQuantity   -- aQuantity
                                     , iDateRef             => sysdate   -- aDateRef
                                     , ioRoundType          => vRoundType
                                     , ioRoundAmount        => vRoundAmount
                                     , ioCurrencyId         => vAcsFinancialCurrId
                                     , oNet                 => vNet
                                     , oSpecial             => vSpecial
                                     , oFlatRate            => lFlatRate
                                     , oTariffUnit          => lTariffUnit
                                      );
      else
        FdcTariffUnitValue  :=
          GCO_I_LIB_PRICE.GetGoodPrice(iGoodId              => aGcoGoodId
                                     , iTypePrice           => '1'   -- aTypePrice (1 = tarif d'achat)
                                     , iThirdId             => aPacThirdTariffId
                                     , iRecordId            => null   -- aRecordId
                                     , iFalScheduleStepId   => null   -- aFalScheduleStepId
                                     , ioDicTariff          => vDic_Tariff
                                     , iQuantity            => FdcBasisQuantity   -- aQuantity
                                     , iDateRef             => sysdate   -- aDateRef
                                     , ioRoundType          => vRoundType
                                     , ioRoundAmount        => vRoundAmount
                                     , ioCurrencyId         => vAcsFinancialCurrId
                                     , oNet                 => vNet
                                     , oSpecial             => vSpecial
                                     , oFlatRate            => lFlatRate
                                     , oTariffUnit          => lTariffUnit
                                      );
      end if;
    exception
      when no_data_found then
        FdcTariffUnitValue  := 0;
    end;

    Calcul_Valeur_en_Monnaie_Base(FdcBasisQuantity * FdcGrossUnitValue, vAcsFinancialCurrId, FdcGrossValueBasisCurrency, null);

    insert into FAL_DOC_CONSULT
                (FAL_DOC_CONSULT_ID
               , FDC_NUMBER
               , FAL_DOC_PROP_ID
               , FDC_PRINT
               , FDC_PRINT_DATE
               , PAC_SUPPLIER_PARTNER_ID
               , PAC_THIRD_ACI_ID
               , PAC_THIRD_DELIVERY_ID
               , PAC_THIRD_TARIFF_ID
               , PAC2_SUPPLIER_PARTNER_ID
               , GCO_GOOD_ID
               , GCO2_GOOD_ID
               , FDC_SECOND_REF
               , FDC_PSHORT_DESCR
               , FDC_TEXT
               , FDC_CONVERT_FACTOR
               , DIC_UNIT_OF_MEASURE_ID
               , FDC_NUMBER_OF_DECIMAL
               , FDC_BASIS_QUANTITY
               , FDC_BASIS_QUANTITY_P
               , DIC_DIC_UNIT_OF_MEASURE_ID
               , FDC2_NUMBER_OF_DECIMAL
               , FDC2_BASIS_QUANTITY
               , FDC2_BASIS_QUANTITY_P
               , FDC_FINAL_DELAY
               , FDC_FINAL_DELAY_P
               , ACS_FINANCIAL_CURRENCY_ID
               , DOC_RECORD_ID
               , DOC_GAUGE_ID
               , STM_STOCK_ID
               , STM_LOCATION_ID
               , GCO_CHARACTERIZATION1_ID
               , GCO_CHARACTERIZATION2_ID
               , GCO_CHARACTERIZATION3_ID
               , GCO_CHARACTERIZATION4_ID
               , GCO_CHARACTERIZATION5_ID
               , FDC_CHARACTERIZATION_VALUE_1
               , FDC_CHARACTERIZATION_VALUE_2
               , FDC_CHARACTERIZATION_VALUE_3
               , FDC_CHARACTERIZATION_VALUE_4
               , FDC_CHARACTERIZATION_VALUE_5
               , FDC_BASIS_CURRENCY
               , FDC_GROSS_UNIT_VALUE
               , FDC_GROSS_VALUE
               , FDC_GROSS_VALUE_BASIS_CURRENCY
               , FDC_MSOURCING_OLD
               , FDC_MSOURCING_NEW
               , FDC_NEGOTIATION
               , FDC_TARIFF_UNIT_VALUE
               , A_IDCRE
               , A_DATECRE
                )
         values (GetNewId   -- FAL_DOC_CONSULT_ID,
               , aFdcCompteur   -- FDC_NUMBER,
               , aFalDocPropId   -- FAL_DOC_PROP_ID,
               , 0   -- FDC_PRINT,
               , null   -- FDC_PRINT_DATE,
               , aPacSupplierPartnerId   -- PAC_SUPPLIER_PARTNER_ID,
               , aPacThirdAciId   -- PAC_THIRD_ACI_ID,
               , aPacThirdDeliveryId   -- PAC_THIRD_DELIVERY_ID,
               , aPacThirdTariffId   -- PAC_THIRD_TARIFF_ID,
               , aPac2SupplierPartnerId   -- PAC2_SUPPLIER_PARTNER_ID,
               , aGcoGoodId   -- GCO_GOOD_ID,
               , aGcoGcoGoodId   -- GCO2_GOOD_ID,
               , aCdaComplementaryRef   -- FDC_SECOND_REF,
               , aCdaShortDescription   -- FDC_PSHORT_DESCR,
               , aFdpText   -- FDC_TEXT,
               , aCdaConversionFactor   -- FDC_CONVERT_FACTOR,
               , aDicUnitOfMeasureId   -- DIC_UNIT_OF_MEASURE_ID,
               , aCdaNumberOfDecimal   -- FDC_NUMBER_OF_DECIMAL,
               , FdcBasisQuantity   -- FDC_BASIS_QUANTITY,
               , FdcBasisQuantity   -- FDC_BASIS_QUANTITY_P,
               , tplGcoGood.DIC_UNIT_OF_MEASURE_ID   -- DIC_DIC_UNIT_OF_MEASURE_ID,
               , tplGcoGood.GOO_NUMBER_OF_DECIMAL   -- FDC2_NUMBER_OF_DECIMAL,
               , Fdc2BasisQuantity   -- FDC2_BASIS_QUANTITY,
               , Fdc2BasisQuantity   -- FDC2_BASIS_QUANTITY_P,
               , aFdpFinalDelay   -- FDC_FINAL_DELAY,
               , aFdpFinalDelay   -- FDC_FINAL_DELAY_P,
               , vAcsFinancialCurrId   -- ACS_FINANCIAL_CURRENCY_ID,
               , aDocRecordId   -- DOC_RECORD_ID,
               , aDocGaugeId   -- DOC_GAUGE_ID,
               , aStmStockId   -- STM_STOCK_ID,
               , aStmLocationId   -- STM_LOCATION_ID,
               , aGcoCharac1   -- GCO_CHARACTERIZATION1_ID,
               , aGcoCharac2   -- GCO_CHARACTERIZATION2_ID,
               , aGcoCharac3   -- GCO_CHARACTERIZATION3_ID,
               , aGcoCharac4   -- GCO_CHARACTERIZATION4_ID,
               , aGcoCharac5   -- GCO_CHARACTERIZATION5_ID,
               , aFadCharac1   -- FDC_CHARACTERIZATION_VALUE_1,
               , aFadCharac2   -- FDC_CHARACTERIZATION_VALUE_2,
               , aFadCharac3   -- FDC_CHARACTERIZATION_VALUE_3,
               , aFadCharac4   -- FDC_CHARACTERIZATION_VALUE_4,
               , aFadCharac5   -- FDC_CHARACTERIZATION_VALUE_5,
               , ACS_FUNCTION.GetLocalCurrencyName   -- FDC_BASIS_CURRENCY,
               , FdcGrossUnitValue   -- FDC_GROSS_UNIT_VALUE,
               , FdcBasisQuantity * FdcGrossUnitValue   -- FDC_GROSS_VALUE
               , FdcGrossValueBasisCurrency   -- FDC_GROSS_VALUE_BASIS_CURRENCY
               , aCpu_Percent_Sourcing   -- CPU_PERCENT_SOURCING
               , 0
               , aFDC_NEGOTIATION
               , FdcTariffUnitValue   -- FDC_TARIFF_UNIT_VALUE
               , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE,
               , sysdate   -- A_DATECRE)
                );
  end;

  procedure Generation_Consultations(UserSessionId varchar2, SelectCreatedPOA integer default 0, FDC_NEGOTIATION integer default 0)
  is
    -- propositions document sélectionnées
    cursor CUR_PROP_SELECTED
    is
      select FAL_DOC_PROP_ID   -- Proposition
           , GCO_GOOD_ID   -- Produit
           , FDP_TEXTE   -- Description courte
           , FDP_BASIS_QTY   -- Qté de base
           , FDP_CONVERT_FACTOR
           , FDP_FINAL_DELAY   -- Délai final
           , DOC_RECORD_ID
           , DOC_GAUGE_ID
           , STM_STOCK_ID
           , STM_LOCATION_ID
           , PAC_SUPPLIER_PARTNER_ID   -- Fournisseur
           , PAC_THIRD_ACI_ID
           , PAC_THIRD_DELIVERY_ID
           , PAC_THIRD_TARIFF_ID
           , GCO_CHARACTERIZATION1_ID
           , GCO_CHARACTERIZATION2_ID
           , GCO_CHARACTERIZATION3_ID
           , GCO_CHARACTERIZATION4_ID
           , GCO_CHARACTERIZATION5_ID
           , FDP_CHARACTERIZATION_VALUE_1
           , FDP_CHARACTERIZATION_VALUE_2
           , FDP_CHARACTERIZATION_VALUE_3
           , FDP_CHARACTERIZATION_VALUE_4
           , FDP_CHARACTERIZATION_VALUE_5
        from FAL_DOC_PROP
       where FDP_SELECT = 1
         and FDP_ORACLE_SESSION = UserSessionId
         and FDP_CONSULT = 0;

    -- Données complémentaires d'achat du produit
    cursor CUR_GCO_COMPL_DATA_PURCHASE(GcoGoodId number)
    is
      select PAC_SUPPLIER_PARTNER_ID   -- Fournisseur
           , PAC_PAC_SUPPLIER_PARTNER_ID   -- Fabricant
           , GCO_GCO_GOOD_ID   -- Produit équivalent
           , CDA_COMPLEMENTARY_REFERENCE   -- Référence complémentaire
           , CDA_SHORT_DESCRIPTION   -- Description courte produit
           , CDA_CONVERSION_FACTOR   -- Facteur de conversion
           , DIC_UNIT_OF_MEASURE_ID   -- Unité d'achat
           , CDA_NUMBER_OF_DECIMAL   -- Nombre de décimale gérée
           , CPU_PERCENT_SOURCING   -- Pourcentage multi-Sourcing
        from GCO_COMPL_DATA_PURCHASE
       where GCO_GOOD_ID = GcoGoodId
         and PAC_SUPPLIER_PARTNER_ID is not null;

    cursor CUR_GCO_GOOD(GcoGoodId number)
    is
      select GOO_SECONDARY_REFERENCE
           , DES_SHORT_DESCRIPTION
           , DIC_UNIT_OF_MEASURE_ID
           , GOO_NUMBER_OF_DECIMAL
        from GCO_GOOD GG
           , GCO_DESCRIPTION GD
       where GG.GCO_GOOD_ID = GcoGoodId
         and GG.GCO_GOOD_ID = GD.GCO_GOOD_ID
         and GD.C_DESCRIPTION_TYPE = '01'
         and GD.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetCompLangID;

    FalDocProd          CUR_PROP_SELECTED%rowtype;
    GcoComplDataPuchase CUR_GCO_COMPL_DATA_PURCHASE%rowtype;
    FdcCompteur         number;
    HasConsultCreated   boolean;
    CurGcoGood          CUR_GCO_GOOD%rowtype;
    vThirdAciID         PAC_THIRD.PAC_THIRD_ID%type;
    vThirdDeliveryID    PAC_THIRD.PAC_THIRD_ID%type;
    vThirdTariffID      PAC_THIRD.PAC_THIRD_ID%type;
  begin
    -- Initialisation du compteur
    select max(to_number(FDC_NUMBER) )
      into FdcCompteur
      from FAL_DOC_CONSULT;

    FdcCompteur  := nvl(FdcCompteur, 0) + 1;

    -- Pour chaque proposition document sélectionné
    open CUR_PROP_SELECTED;

    loop
      fetch CUR_PROP_SELECTED
       into FalDocProd;

      exit when CUR_PROP_SELECTED%notfound;
      HasConsultCreated  := false;

      -- Pour chaque Donnée complémentaire d'achat du produit
      open CUR_GCO_COMPL_DATA_PURCHASE(FalDocProd.GCO_GOOD_ID);

      loop
        fetch CUR_GCO_COMPL_DATA_PURCHASE
         into GcoComplDataPuchase;

        exit when CUR_GCO_COMPL_DATA_PURCHASE%notfound;

        if FalDocProd.PAC_SUPPLIER_PARTNER_ID = GcoComplDataPuchase.PAC_SUPPLIER_PARTNER_ID then
          HasConsultCreated  := true;
        end if;

        -- Recherche des partenaires du tiers
        DOC_DOCUMENT_FUNCTIONS.GetThirdPartners(aThirdID           => GcoComplDataPuchase.PAC_SUPPLIER_PARTNER_ID
                                              , aGaugeID           => FalDocProd.DOC_GAUGE_ID
                                              , aAdminDomain       => '1'
                                              , aThirdAciID        => vThirdAciID
                                              , aThirdDeliveryID   => vThirdDeliveryID
                                              , aThirdTariffID     => vThirdTariffID
                                               );
        Process_Creation_Consultations(FalDocProd.FAL_DOC_PROP_ID   -- Proposition
                                     , GcoComplDataPuchase.PAC_SUPPLIER_PARTNER_ID   -- Fournisseur
                                     , vThirdAciID   -- Tiers facturation
                                     , vThirdDeliveryID   -- Tiers livraison
                                     , vThirdTariffID   -- Tiers tarification
                                     , GcoComplDataPuchase.PAC_PAC_SUPPLIER_PARTNER_ID   -- Fabricant
                                     , FalDocProd.GCO_GOOD_ID   -- Produit
                                     , GcoComplDataPuchase.GCO_GCO_GOOD_ID   -- Produit équivalent
                                     , GcoComplDataPuchase.CDA_COMPLEMENTARY_REFERENCE   -- Référence complémentaire
                                     , GcoComplDataPuchase.CDA_SHORT_DESCRIPTION   -- Description courte produit
                                     , FalDocProd.FDP_TEXTE   -- Description courte
                                     , GcoComplDataPuchase.CDA_CONVERSION_FACTOR   -- Facteur de conversion
                                     , GcoComplDataPuchase.DIC_UNIT_OF_MEASURE_ID   -- Unité d'achat
                                     , GcoComplDataPuchase.CDA_NUMBER_OF_DECIMAL   -- Nombre de décimale gérée
                                     , FalDocProd.FDP_BASIS_QTY   -- Qté de base
                                     , FalDocProd.FDP_CONVERT_FACTOR
                                     , FalDocProd.FDP_FINAL_DELAY   -- Délai final
                                     , FalDocProd.DOC_RECORD_ID
                                     , FalDocProd.DOC_GAUGE_ID
                                     , FalDocProd.STM_STOCK_ID
                                     , FalDocProd.STM_LOCATION_ID
                                     , FalDocProd.GCO_CHARACTERIZATION1_ID
                                     , FalDocProd.GCO_CHARACTERIZATION2_ID
                                     , FalDocProd.GCO_CHARACTERIZATION3_ID
                                     , FalDocProd.GCO_CHARACTERIZATION4_ID
                                     , FalDocProd.GCO_CHARACTERIZATION5_ID
                                     , FalDocProd.FDP_CHARACTERIZATION_VALUE_1
                                     , FalDocProd.FDP_CHARACTERIZATION_VALUE_2
                                     , FalDocProd.FDP_CHARACTERIZATION_VALUE_3
                                     , FalDocProd.FDP_CHARACTERIZATION_VALUE_4
                                     , FalDocProd.FDP_CHARACTERIZATION_VALUE_5
                                     , FdcCompteur
                                     , GcoComplDataPuchase.CPU_PERCENT_SOURCING
                                     , FDC_NEGOTIATION
                                      );
        FdcCompteur  := FdcCompteur + 1;
      end loop;

      close CUR_GCO_COMPL_DATA_PURCHASE;

      -- Si aucune consultation n'a été créée pour la POA (le produit n'a pas de données complémentaires),
      -- on en crée une avec les données de base et le fournisseur de la POA.
      if not HasConsultCreated then
        open CUR_GCO_GOOD(FalDocProd.GCO_GOOD_ID);

        fetch CUR_GCO_GOOD
         into CurGcoGood;

        if CUR_GCO_GOOD%found then
          Process_Creation_Consultations(FalDocProd.FAL_DOC_PROP_ID   -- Proposition
                                       , FalDocProd.PAC_SUPPLIER_PARTNER_ID   -- Fournisseur
                                       , FalDocProd.PAC_THIRD_ACI_ID   -- Tiers facturation
                                       , FalDocProd.PAC_THIRD_DELIVERY_ID   -- Tiers livraison
                                       , FalDocProd.PAC_THIRD_TARIFF_ID   -- Tiers tarification
                                       , null   -- Fabricant
                                       , FalDocProd.GCO_GOOD_ID   -- Produit
                                       , null   -- Produit équivalent
                                       , CurGcoGood.GOO_SECONDARY_REFERENCE   -- Référence complémentaire
                                       , CurGcoGood.DES_SHORT_DESCRIPTION   -- Description courte produit
                                       , FalDocProd.FDP_TEXTE   -- Description courte
                                       , 1   -- Facteur de conversion
                                       , CurGcoGood.DIC_UNIT_OF_MEASURE_ID   -- Unité d'achat
                                       , CurGcoGood.GOO_NUMBER_OF_DECIMAL   -- Nombre de décimale gérée
                                       , FalDocProd.FDP_BASIS_QTY   -- Qté de base
                                       , FalDocProd.FDP_CONVERT_FACTOR
                                       , FalDocProd.FDP_FINAL_DELAY   -- Délai final
                                       , FalDocProd.DOC_RECORD_ID
                                       , FalDocProd.DOC_GAUGE_ID
                                       , FalDocProd.STM_STOCK_ID
                                       , FalDocProd.STM_LOCATION_ID
                                       , FalDocProd.GCO_CHARACTERIZATION1_ID
                                       , FalDocProd.GCO_CHARACTERIZATION2_ID
                                       , FalDocProd.GCO_CHARACTERIZATION3_ID
                                       , FalDocProd.GCO_CHARACTERIZATION4_ID
                                       , FalDocProd.GCO_CHARACTERIZATION5_ID
                                       , FalDocProd.FDP_CHARACTERIZATION_VALUE_1
                                       , FalDocProd.FDP_CHARACTERIZATION_VALUE_2
                                       , FalDocProd.FDP_CHARACTERIZATION_VALUE_3
                                       , FalDocProd.FDP_CHARACTERIZATION_VALUE_4
                                       , FalDocProd.FDP_CHARACTERIZATION_VALUE_5
                                       , FdcCompteur
                                       , 0
                                       , FDC_NEGOTIATION
                                        );
          FdcCompteur  := FdcCompteur + 1;
        end if;

        close CUR_GCO_GOOD;
      end if;

      -- Mise à jour de la consultation de la proposition
      update FAL_DOC_PROP
         set FDP_CONSULT = 1
           , FDP_DATE_CONSULT = sysdate
           , FDP_SELECT = SelectCreatedPOA
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_DOC_PROP_ID = FalDocProd.FAL_DOC_PROP_ID;
    end loop;

    close CUR_PROP_SELECTED;
  end;

  procedure Copie_Prop_Appro_Logistique(
    UserSessionId          varchar2
  , iFalDocProdId          number
  , QteDeBase              FAL_DOC_PROP.FDP_BASIS_QTY%type
  , QteIntermedaire        FAL_DOC_PROP.FDP_INTERMEDIATE_QTY%type
  , aCreatePropId   in out number
  )
  is
  begin
    aCreatePropId := GetNewId;

    insert into FAL_DOC_PROP
                (FAL_DOC_PROP_ID
               , C_PREFIX_PROP
               , FDP_NUMBER
               , FDP_TEXTE
               , DOC_GAUGE_ID
               , PAC_SUPPLIER_PARTNER_ID
               , PAC_THIRD_ACI_ID
               , PAC_THIRD_DELIVERY_ID
               , PAC_THIRD_TARIFF_ID
               , GCO_GOOD_ID
               , FDP_SECOND_REF
               , FDP_PSHORT_DESCR
               , FDP_CONVERT_FACTOR
               , FDP_BASIS_QTY
               , FDP_INTERMEDIATE_QTY
               , FDP_FINAL_QTY
               , FDP_FINAL_DELAY
               , FDP_INTERMEDIATE_DELAY
               , FDP_BASIS_DELAY
               , DOC_RECORD_ID
               , STM_STOCK_ID
               , STM_LOCATION_ID
               , STM_STM_STOCK_ID
               , STM_STM_LOCATION_ID
               , GCO_CHARACTERIZATION1_ID
               , GCO_CHARACTERIZATION2_ID
               , GCO_CHARACTERIZATION3_ID
               , GCO_CHARACTERIZATION4_ID
               , GCO_CHARACTERIZATION5_ID
               , FDP_CHARACTERIZATION_VALUE_1
               , FDP_CHARACTERIZATION_VALUE_2
               , FDP_CHARACTERIZATION_VALUE_3
               , FDP_CHARACTERIZATION_VALUE_4
               , FDP_CHARACTERIZATION_VALUE_5
               , FDP_SELECT
               , FDP_ORACLE_SESSION
               , A_IDCRE
               , A_DATECRE
                )
      select aCreatePropId
           , C_PREFIX_PROP
           , (select nvl(max(to_number(FDP_NUMBER) ), 0) + 1
                from FAL_DOC_PROP
               where C_PREFIX_PROP = FDP.C_PREFIX_PROP)
           , null
           , DOC_GAUGE_ID
           , PAC_SUPPLIER_PARTNER_ID
           , PAC_THIRD_ACI_ID
           , PAC_THIRD_DELIVERY_ID
           , PAC_THIRD_TARIFF_ID
           , GCO_GOOD_ID
           , FDP_SECOND_REF
           , FDP_PSHORT_DESCR
           , FDP_CONVERT_FACTOR
           , QteDeBase
           , QteIntermedaire
           , QteDeBase + QteIntermedaire
           , FDP_FINAL_DELAY
           , FDP_INTERMEDIATE_DELAY
           , FDP_BASIS_DELAY
           , DOC_RECORD_ID
           , STM_STOCK_ID
           , STM_LOCATION_ID
           , STM_STM_STOCK_ID
           , STM_STM_LOCATION_ID
           , GCO_CHARACTERIZATION1_ID
           , GCO_CHARACTERIZATION2_ID
           , GCO_CHARACTERIZATION3_ID
           , GCO_CHARACTERIZATION4_ID
           , GCO_CHARACTERIZATION5_ID
           , FDP_CHARACTERIZATION_VALUE_1
           , FDP_CHARACTERIZATION_VALUE_2
           , FDP_CHARACTERIZATION_VALUE_3
           , FDP_CHARACTERIZATION_VALUE_4
           , FDP_CHARACTERIZATION_VALUE_5
           , 1
           , UserSessionId
           , PCS.PC_I_LIB_SESSION.GetUserIni
           , sysdate
        from FAL_DOC_PROP FDP
       where FAL_DOC_PROP_ID = iFalDocProdId;
  end;

  procedure Regroupement_POA(UserSessionId varchar2)
  is
    cursor crSelectedProducts
    is
      select   GCO_GOOD_ID
             , sum(FDP_BASIS_QTY) BASIS_QTY
             , sum(FDP_INTERMEDIATE_QTY) INTERMEDIATE_QTY
          from FAL_DOC_PROP
         where FDP_SELECT = 1
           and FDP_ORACLE_SESSION = UserSessionId
      group by GCO_GOOD_ID;

    -- Sélection de la proposition dont le délai commande est le plus petit
    cursor CUR_GROUPE_PROP(GcoGoodId number)
    is
      select   FAL_DOC_PROP_ID
          from FAL_DOC_PROP
         where GCO_GOOD_ID = GcoGoodId
           and FDP_SELECT = 1
           and FDP_ORACLE_SESSION = UserSessionId
      order by FDP_FINAL_DELAY;

    cursor CUR_FAL_NETWORK(FalDocPropId number)
    is
      select FNL.FAL_NETWORK_NEED_ID   -- Besoin
           , FNL.STM_LOCATION_ID   -- Emplacement
           , FNL.FLN_QTY   -- Qté
           , FNL.FLN_NEED_DELAY   -- Délai besoin
        from FAL_NETWORK_LINK FNL
           , FAL_NETWORK_SUPPLY FNS
       where FNL.FAL_NETWORK_SUPPLY_ID = FNS.FAL_NETWORK_SUPPLY_ID
         and FNS.FAL_DOC_PROP_ID = FalDocPropId;

    FalDocPropId      number;
    CurFalNetwork     CUR_FAL_NETWORK%rowtype;
    IdReseauAppro     number;
    AttributionsPOA   TAttributionsPOA;
    CompteurAttribPOA integer;
    iAttribPOA        integer;
    aCreatePropId     number;
    aCreatedAppro     number;
  begin
    for tplSelectedProduct in crSelectedProducts loop
      -- la première proposition est celle dont le délai commande est le plus petit
      open CUR_GROUPE_PROP(tplSelectedProduct.GCO_GOOD_ID);

      fetch CUR_GROUPE_PROP
       into FalDocPropId;

      if CUR_GROUPE_PROP%found then
        Copie_Prop_Appro_Logistique(UserSessionId, FalDocPropId, tplSelectedProduct.BASIS_QTY, tplSelectedProduct.INTERMEDIATE_QTY, aCreatePropId);
        -- Création réseaux appro logistique
        -- et on récupère l'id de l'appro crée.
        FAL_NETWORK_DOC.CreateReseauApproPropApproLog(aCreatePropId, aCreatedAppro);
      end if;

      -- Pour chaque proposition du groupe
      loop
        CompteurAttribPOA  := 0;
        exit when CUR_GROUPE_PROP%notfound;

        -- Pour chaque Attribution de la proposition
        open CUR_FAL_NETWORK(FalDocPropId);

        loop
          fetch CUR_FAL_NETWORK
           into CurFalNetwork;

          exit when CUR_FAL_NETWORK%notfound;
          -- Enregistrement dans une table temporaire
          CompteurAttribPOA                               := CompteurAttribPOA + 1;
          AttributionsPOA(CompteurAttribPOA).Besoin       := CurFalNetwork.FAL_NETWORK_NEED_ID;
          AttributionsPOA(CompteurAttribPOA).Emplacement  := CurFalNetwork.STM_LOCATION_ID;
          AttributionsPOA(CompteurAttribPOA).Qte          := CurFalNetwork.FLN_QTY;
          AttributionsPOA(CompteurAttribPOA).DelaiBesoin  := CurFalNetwork.FLN_NEED_DELAY;
        end loop;

        close CUR_FAL_NETWORK;

        -- Suppression de la Proposition document
        -- ET éventuelle demande d'appro
        FAL_PRC_FAL_DOC_PROP.DeleteOneDOCProposition(FalDocPropId
                                                   , FAL_PRC_FAL_PROP_COMMON.DELETE_PROP
                                                   , FAL_PRC_FAL_PROP_COMMON.NO_DELETE_REQUEST
                                                   , FAL_PRC_FAL_PROP_COMMON.UPDATE_REQUEST_COMMANDEE
                                                    );

        -- Pour chaque enregistrement de la table AttributionsPOA
        for iAttribPOA in 1 .. CompteurAttribPOA loop
          if AttributionsPOA(iAttribPOA).Besoin is null then
            -- Création ATTRIBUTION Appro Stock
            FAl_NETWORK.CreateAttribApproStock(ACreatedAppro, AttributionsPOA(iAttribPOA).Emplacement, AttributionsPOA(iAttribPOA).Qte);
          else
            -- Création ATTRIBUTION Besoin/Appro ou Appro/Besoin
            FAl_NETWORK.CreateAttribBesoinAppro(AttributionsPOA(iAttribPOA).Besoin, ACreatedAppro, AttributionsPOA(iAttribPOA).Qte);
          end if;
        end loop;

        fetch CUR_GROUPE_PROP
         into FalDocPropId;
      end loop;

      close CUR_GROUPE_PROP;
    end loop;
  end;

  procedure Archivage_Consultation(aFAL_DOC_CONSULT_ID in number, aFAL_DOC_CONSULT_HIST_ID in out number)
  is
    cursor CUR_FAL_DOC_CONSULT
    is
      select *
        from FAL_DOC_CONSULT
       where FAL_DOC_CONSULT_ID = aFAL_DOC_CONSULT_ID;

    cursor CUR_DOCUMENT
    is
      select DOC_DOCUMENT_ID
        from DOC_POSITION_DETAIL DPD
           , FAL_DOC_CONS_POSI_TEMP FDCPT
       where FDCPT.DOC_POSITION_DETAIL_ID = DPD.DOC_POSITION_DETAIL_ID
         and FAL_DOC_CONSULT_ID = aFAL_DOC_CONSULT_ID;

    FdchCompteur     FAL_DOC_PROP.C_PREFIX_PROP%type;
    EnrFalDocConsult CUR_FAL_DOC_CONSULT%rowtype;
    DocDocumentId    number;
  begin
    aFAL_DOC_CONSULT_HIST_ID  := 0;

    -- Initialisation du compteur
    select max(to_number(FDC_NUMBER) )
      into FdchCompteur
      from FAL_DOC_CONSULT_HIST;

    FdchCompteur              := nvl(FdchCompteur, 0) + 1;
    DocDocumentId             := null;

    open CUR_DOCUMENT;

    fetch CUR_DOCUMENT
     into DocDocumentId;

    close CUR_DOCUMENT;

    open CUR_FAL_DOC_CONSULT;

    fetch CUR_FAL_DOC_CONSULT
     into EnrFalDocConsult;

    if CUR_FAL_DOC_CONSULT%found then
      aFAL_DOC_CONSULT_HIST_ID  := GetNewId;

      insert into FAL_DOC_CONSULT_HIST
                  (FAL_DOC_CONSULT_HIST_ID
                 , FDC_NUMBER
                 , DIC_UNIT_OF_MEASURE_ID
                 , DIC_DIC_UNIT_OF_MEASURE_ID
                 , STM_LOCATION_ID
                 , STM_STOCK_ID
                 , GCO_CHARACTERIZATION1_ID
                 , GCO_CHARACTERIZATION2_ID
                 , GCO_CHARACTERIZATION3_ID
                 , GCO_CHARACTERIZATION4_ID
                 , GCO_CHARACTERIZATION5_ID
                 , DOC_RECORD_ID
                 , DOC_GAUGE_ID
                 , GCO_GOOD_ID
                 , GCO2_GOOD_ID
                 , PAC_SUPPLIER_PARTNER_ID
                 , PAC_THIRD_ACI_ID
                 , PAC_THIRD_DELIVERY_ID
                 , PAC_THIRD_TARIFF_ID
                 , PAC2_SUPPLIER_PARTNER_ID
                 , ACS_FINANCIAL_CURRENCY_ID
                 , A_RECLEVEL
                 , A_RECSTATUS
                 , A_CONFIRM
                 , FDC_PRINT
                 , FDC_PRINT_DATE
                 , FDC_SECOND_REF
                 , FDC_PSHORT_DESCR
                 , FDC_TEXT
                 , FDC_BASIS_QUANTITY
                 , FDC_BASIS_QUANTITY_P
                 , FDC_NUMBER_OF_DECIMAL
                 , FDC_CONVERT_FACTOR
                 , FDC2_BASIS_QUANTITY
                 , FDC2_BASIS_QUANTITY_P
                 , FDC2_NUMBER_OF_DECIMAL
                 , FDC_FINAL_DELAY
                 , FDC_FINAL_DELAY_P
                 , FDC_GROSS_UNIT_VALUE
                 , FDC_GROSS_VALUE
                 , FDC_CHARACTERIZATION_VALUE_1
                 , FDC_CHARACTERIZATION_VALUE_2
                 , FDC_CHARACTERIZATION_VALUE_3
                 , FDC_CHARACTERIZATION_VALUE_4
                 , FDC_CHARACTERIZATION_VALUE_5
                 , FDC_SELECT
                 , FDC_GROSS_VALUE_BASIS_CURRENCY
                 , FDC_BASIS_CURRENCY
                 , FDC_PARTNER_REFERENCE
                 , FDC_PARTNER_NUMBER
                 , FDC_DATE_PARTNER_DOCUMENT
                 , DOC_DOCUMENT_ID
                 , FDC_MSOURCING_NEW
                 , FDC_MSOURCING_OLD
                 , FDC_NEGOTIATION
                 , FDC_TARIFF_UNIT_VALUE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (aFAL_DOC_CONSULT_HIST_ID   -- FAL_DOC_CONSULT_HIST_ID,
                 , FdchCompteur   -- FDC_NUMBER
                 , EnrFalDocConsult.DIC_UNIT_OF_MEASURE_ID
                 , EnrFalDocConsult.DIC_DIC_UNIT_OF_MEASURE_ID
                 , EnrFalDocConsult.STM_LOCATION_ID
                 , EnrFalDocConsult.STM_STOCK_ID
                 , EnrFalDocConsult.GCO_CHARACTERIZATION1_ID
                 , EnrFalDocConsult.GCO_CHARACTERIZATION2_ID
                 , EnrFalDocConsult.GCO_CHARACTERIZATION3_ID
                 , EnrFalDocConsult.GCO_CHARACTERIZATION4_ID
                 , EnrFalDocConsult.GCO_CHARACTERIZATION5_ID
                 , EnrFalDocConsult.DOC_RECORD_ID
                 , EnrFalDocConsult.DOC_GAUGE_ID
                 , EnrFalDocConsult.GCO_GOOD_ID
                 , EnrFalDocConsult.GCO2_GOOD_ID
                 , EnrFalDocConsult.PAC_SUPPLIER_PARTNER_ID
                 , EnrFalDocConsult.PAC_THIRD_ACI_ID
                 , EnrFalDocConsult.PAC_THIRD_DELIVERY_ID
                 , EnrFalDocConsult.PAC_THIRD_TARIFF_ID
                 , EnrFalDocConsult.PAC2_SUPPLIER_PARTNER_ID
                 , EnrFalDocConsult.ACS_FINANCIAL_CURRENCY_ID
                 , EnrFalDocConsult.A_RECLEVEL
                 , EnrFalDocConsult.A_RECSTATUS
                 , EnrFalDocConsult.A_CONFIRM
                 , EnrFalDocConsult.FDC_PRINT
                 , EnrFalDocConsult.FDC_PRINT_DATE
                 , EnrFalDocConsult.FDC_SECOND_REF
                 , EnrFalDocConsult.FDC_PSHORT_DESCR
                 , EnrFalDocConsult.FDC_TEXT
                 , EnrFalDocConsult.FDC_BASIS_QUANTITY
                 , EnrFalDocConsult.FDC_BASIS_QUANTITY_P
                 , EnrFalDocConsult.FDC_NUMBER_OF_DECIMAL
                 , EnrFalDocConsult.FDC_CONVERT_FACTOR
                 , EnrFalDocConsult.FDC2_BASIS_QUANTITY
                 , EnrFalDocConsult.FDC2_BASIS_QUANTITY_P
                 , EnrFalDocConsult.FDC2_NUMBER_OF_DECIMAL
                 , EnrFalDocConsult.FDC_FINAL_DELAY
                 , EnrFalDocConsult.FDC_FINAL_DELAY_P
                 , EnrFalDocConsult.FDC_GROSS_UNIT_VALUE
                 , EnrFalDocConsult.FDC_GROSS_VALUE
                 , EnrFalDocConsult.FDC_CHARACTERIZATION_VALUE_1
                 , EnrFalDocConsult.FDC_CHARACTERIZATION_VALUE_2
                 , EnrFalDocConsult.FDC_CHARACTERIZATION_VALUE_3
                 , EnrFalDocConsult.FDC_CHARACTERIZATION_VALUE_4
                 , EnrFalDocConsult.FDC_CHARACTERIZATION_VALUE_5
                 , EnrFalDocConsult.FDC_SELECT
                 , EnrFalDocConsult.FDC_GROSS_VALUE_BASIS_CURRENCY
                 , EnrFalDocConsult.FDC_BASIS_CURRENCY
                 , EnrFalDocConsult.FDC_PARTNER_REFERENCE
                 , EnrFalDocConsult.FDC_PARTNER_NUMBER
                 , EnrFalDocConsult.FDC_DATE_PARTNER_DOCUMENT
                 , DocDocumentId
                 , EnrFalDocConsult.FDC_MSOURCING_NEW
                 , EnrFalDocConsult.FDC_MSOURCING_OLD
                 , EnrFalDocConsult.FDC_NEGOTIATION
                 , EnrFalDocConsult.FDC_TARIFF_UNIT_VALUE
                 , sysdate   -- A_DATECRE
                 , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                  );

      -- Suppression de la consultation archivée
      delete from fal_doc_consult
            where fal_doc_consult_id = EnrFalDocConsult.FAL_DOC_CONSULT_ID;
    end if;

    close CUR_FAL_DOC_CONSULT;
  exception
    when others then
      begin
        close CUR_FAL_DOC_CONSULT;

        aFAL_DOC_CONSULT_HIST_ID  := 0;
      end;
  end;

  procedure Effacement_Consultations(aFAL_DOC_PROP_ID number)
  is
    cursor CurFAL_DOC_CONSULT
    is
      select     *
            from FAL_DOC_CONSULT
           where FAL_DOC_PROP_ID = aFAL_DOC_PROP_ID
      for update;

    EnrFAL_DOC_CONSULT   FAL_DOC_CONSULT%rowtype;
    aFalDocConsultHistId number;
  begin
    open CurFAL_DOC_CONSULT;

    loop
      fetch CurFAL_DOC_CONSULT
       into EnrFAL_DOC_CONSULT;

      exit when CurFAL_DOC_CONSULT%notfound;

      --Avant l'effacement il faut archiver les consultations qui sont:
      --Sélectionnées OU ayant eu une réponse
      if    (EnrFAL_DOC_CONSULT.FDC_SELECT = 1)
         or (    EnrFAL_DOC_CONSULT.FDC_FINAL_DELAY_P is not null
             and EnrFAL_DOC_CONSULT.FDC_BASIS_QUANTITY_P is not null) then
        Archivage_Consultation(EnrFAL_DOC_CONSULT.FAL_DOC_CONSULT_ID, aFalDocConsultHistId);
      end if;

      delete      FAL_DOC_CONSULT
            where current of CurFAL_DOC_CONSULT;
    end loop;

    close CurFAL_DOC_CONSULT;
  end;

  procedure Calcul_Valeur_en_Monnaie_Base(
    Valeur              FAL_DOC_CONSULT.FDC_GROSS_VALUE%type
  , Monnaie             FAL_DOC_CONSULT.ACS_FINANCIAL_CURRENCY_ID%type
  , ValeurResult in out FAL_DOC_CONSULT.FDC_GROSS_VALUE%type
  , prmDate             date default sysdate
  )
  is
  begin
    ValeurResult  := ACS_FUNCTION.ConvertAmountForView(Valeur, Monnaie, ACS_FUNCTION.GetLocalCurrencyId, nvl(prmDate, sysdate), 0, 0, 0, 1);
  end;

  function fctCalcul_Valeur_en_Mon_Base(Valeur FAL_DOC_CONSULT.FDC_GROSS_VALUE%type, Monnaie FAL_DOC_CONSULT.ACS_FINANCIAL_CURRENCY_ID%type)
    return FAL_DOC_CONSULT.FDC_GROSS_VALUE%type
  is
    aResult FAL_DOC_CONSULT.FDC_GROSS_VALUE%type;
  begin
    Calcul_Valeur_en_Monnaie_Base(Valeur, Monnaie, aResult);
    return aResult;
  exception
    when others then
      return 0;
  end;

  procedure MiseAJourReseauPT(aFAL_DOC_PROP_ID number)
  is
    type TFAL_NETWORK_LINK is record(
      FAL_NETWORK_LINK_ID   FAL_NETWORK_LINK.FAL_NETWORK_LINK_ID%type
    , FAL_NETWORK_NEED_ID   FAL_NETWORK_LINK.FAL_NETWORK_NEED_ID%type
    , STM_LOCATION_ID       FAL_NETWORK_LINK.STM_LOCATION_ID%type
    , STM_STOCK_POSITION_ID FAL_NETWORK_LINK.STM_STOCK_POSITION_ID%type
    , FLN_QTY               FAL_NETWORK_LINK.FLN_QTY%type
    , FLN_NEED_DELAY        FAL_NETWORK_LINK.FLN_NEED_DELAY%type
    );

    cursor CurFAL_NETWORK_LINK(PrmFAL_NETWORK_SUPPLY_ID number)
    is
      select FAL_NETWORK_LINK_ID
           , FAL_NETWORK_NEED_ID
           , STM_LOCATION_ID
           , STM_STOCK_POSITION_ID
           , FLN_QTY
           , FLN_NEED_DELAY
        from FAL_NETWORK_LINK
       where FAL_NETWORK_SUPPLY_ID = PrmFAL_NETWORK_SUPPLY_ID;

    EnrFAL_NETWORK_LINK       TFAL_NETWORK_LINK;

    -- Suppression de la clause WHERE avec UserSession.On ne travaille pas ici avec un
    -- UserSession (il n'est pas créé dans la table FAL_DOC_CONS_POSI_TEMP)
    cursor CurFAL_DOC_CONS_POSI_TEMP
    is
      select        FDCPT.*
               from FAL_DOC_CONS_POSI_TEMP FDCPT
                  , FAL_DOC_CONSULT FDC
              where FDCPT.FAL_DOC_CONSULT_ID = FDC.FAL_DOC_CONSULT_ID
                and FAL_DOC_PROP_ID = aFAL_DOC_PROP_ID
           order by FDCPT.FDC_FINAL_DELAY_P
      for update of FDCPT.FAL_DOC_CONS_POSI_TEMP_ID;

    EnrFAL_DOC_CONS_POSI_TEMP FAL_DOC_CONS_POSI_TEMP%rowtype;

    cursor CurFAL_NETWORK_LINK_TEMP(LocUserSession number)
    is
      select        *
               from FAL_NETWORK_LINK_TEMP
              where FAL_NETWORK_LINK_TEMP_ID = LocUserSession
           order by FLN_NEED_DELAY
      for update of FAL_NETWORK_LINK_TEMP_ID;

    EnrFAL_NETWORK_LINK_TEMP  FAL_NETWORK_LINK_TEMP%rowtype;
    aFAL_NETWORK_SUPPLY_ID    number;
    QP                        FAL_DOC_CONS_POSI_TEMP.FDC_BASIS_QUANTITY_P%type;
    A                         FAl_NETWORK_LINK_TEMP.FLN_QTY%type;
    F                         integer;
    Id_reseauxApprocree       number;
    aUserSession              number;
  begin
    aUserSession  := GetNewId;

    select FAL_NETWORK_SUPPLY_ID
      into aFAL_NETWORK_SUPPLY_ID
      from FAL_NETWORK_SUPPLY
     where FAL_DOC_PROP_ID = aFAL_DOC_PROP_ID;

    -- pour chaque attribution de la proposition à reprendre
    open CurFAL_NETWORK_LINK(aFAL_NETWORK_SUPPLY_ID);

    loop
      fetch CurFAL_NETWORK_LINK
       into EnrFAL_NETWORK_LINK;

      exit when CurFAL_NETWORK_LINK%notfound;

      -- enregistrement dans la table temporaire
      insert into FAL_NETWORK_LINK_TEMP
                  (FAL_NETWORK_LINK_TEMP_ID   -- UserCode en fait
                 , FAL_NETWORK_LINK_ID
                 , FAL_NETWORK_NEED_ID
                 , STM_LOCATION_ID
                 , STM_STOCK_POSITION_ID
                 , FLN_QTY
                 , FLN_NEED_DELAY
                  )
           values (aUserSession
                 , EnrFAL_NETWORK_LINK.FAL_NETWORK_LINK_ID
                 , EnrFAL_NETWORK_LINK.FAL_NETWORK_NEED_ID
                 , EnrFAL_NETWORK_LINK.STM_LOCATION_ID
                 , EnrFAL_NETWORK_LINK.STM_STOCK_POSITION_ID
                 , EnrFAL_NETWORK_LINK.FLN_QTY
                 , EnrFAL_NETWORK_LINK.FLN_NEED_DELAY
                  );
    end loop;

    close CurFAL_NETWORK_LINK;

    -- Suppression Attributions Appro-Stock ---------------------------------------------------
    FAL_NETWORK.Attribution_Suppr_ApproStock(aFAL_NETWORK_SUPPLY_ID);
    -- Suppression Attributions Appro-Besoin --------------------------------------------------
    FAL_NETWORK.Attribution_Suppr_ApproBesoin(aFAL_NETWORK_SUPPLY_ID);

    -- Pour chaque enreg de la table temporaire FAL_DOC_CONS_TEMP
    open CurFAL_DOC_CONS_POSI_TEMP;

    loop
      fetch CurFAL_DOC_CONS_POSI_TEMP
       into EnrFAL_DOC_CONS_POSI_TEMP;

      exit when CurFAL_DOC_CONS_POSI_TEMP%notfound;
      QP  := nvl(EnrFAL_DOC_CONS_POSI_TEMP.FDC_BASIS_QUANTITY_P, 0);

      -- POur chaque enreg de la table FAL_NETWORK_LINK_TEMP
      open CurFAL_NETWORK_LINK_TEMP(aUserSession);

      loop
        fetch CurFAL_NETWORK_LINK_TEMP
         into EnrFAL_NETWORK_LINK_TEMP;

        exit when CurFAL_NETWORK_LINK_TEMP%notfound;

        if QP > EnrFAL_NETWORK_LINK_TEMP.FLN_QTY then
          A  := EnrFAL_NETWORK_LINK_TEMP.FLN_QTY;
          F  := 1;
        end if;

        if QP = EnrFAL_NETWORK_LINK_TEMP.FLN_QTY then
          A  := EnrFAL_NETWORK_LINK_TEMP.FLN_QTY;
          F  := 2;
        end if;

        if QP < EnrFAL_NETWORK_LINK_TEMP.FLN_QTY then
          A  := QP;
          F  := 3;
        end if;

        -- Récupérer l'ID du réseau
        select FAL_NETWORK_SUPPLY_ID
          into Id_reseauxApprocree
          from FAL_NETWORK_SUPPLY
         where DOC_POSITION_DETAIL_ID = EnrFAL_DOC_CONS_POSI_TEMP.DOC_POSITION_DETAIL_ID;

        if enrFAL_NETWORK_LINK_TEMP.FAL_NETWORK_NEED_ID is null then
          --Que se passe t-il si ici la location est NULLE (Peut-elle l'être ?)
          FAl_NETWORK.CreateAttribApproStockPOA(Id_reseauxApprocree, EnrFAL_NETWORK_LINK_TEMP.STM_LOCATION_ID, A);
        else
          FAl_NETWORK.CreateAttribBesoinApproPOA(EnrFAL_NETWORK_LINK_TEMP.FAL_NETWORK_NEED_ID, Id_reseauxApprocree, A);
        end if;

        if F = 3 then
          update FAL_NETWORK_LINK_TEMP
             set FLN_QTY = FLN_QTY - A
           where current of CurFAL_NETWORK_LINK_TEMP;

          exit;
        end if;

        if F = 2 then
          delete      FAL_NETWORK_LINK_TEMP
                where current of CurFAL_NETWORK_LINK_TEMP;

          exit;
        end if;

        if F = 1 then
          QP  := QP - EnrFAL_NETWORK_LINK_TEMP.FLN_QTY;

          update FAL_DOC_CONS_POSI_TEMP
             set FDC_BASIS_QUANTITY_P = QP
           where current of CurFAL_DOC_CONS_POSI_TEMP;

          delete      FAL_NETWORK_LINK_TEMP
                where current of CurFAL_NETWORK_LINK_TEMP;
        end if;
      end loop;

      close CurFAL_NETWORK_LINK_TEMP;
    end loop;

    close CurFAL_DOC_CONS_POSI_TEMP;

    -- Detruire les enregs de la table temporaire (Par sécurité, il ne doit plus y en avoir)
    delete      FAL_NETWORK_LINK_TEMP
          where FAL_NETWORK_LINK_TEMP_ID = aUserSession;
  end;

/**
* procedure DeleteSelectFAL_DOC_PROP
* Description : Suppression des POA en fin de génération des consultations dans un contexte de négociation
*
* @author ECA
* @lastUpdate
* @public
* @param aFDP_ORACLE_SESSION :  Session Oracle
*/
  procedure DeleteSelectedFAL_DOC_PROP(aFDP_ORACLE_SESSION varchar2)
  is
    cursor CUR_FAL_DOC_PROP_FOR_DELETE
    is
      select FAL_DOC_PROP_ID
        from FAL_DOC_PROP
       where FDP_ORACLE_SESSION = aFDP_ORACLE_SESSION
         and FDP_SELECT = 1;

    CurFalDocPropForDelete CUR_FAL_DOC_PROP_FOR_DELETE%rowtype;
  begin
    for CurFalDocPropForDelete in CUR_FAL_DOC_PROP_FOR_DELETE loop
      -- Suppression de la référence à la consultation afin d'éviter son effacement en même temps que la proposition
      update FAL_DOC_CONSULT
         set FAL_DOC_PROP_ID = null
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_DOC_PROP_ID = CurFalDocPropForDelete.FAL_DOC_PROP_ID;

      -- Suppression de la Proposition
      FAL_PRC_FAL_DOC_PROP.DeleteOneDOCProposition(CurFalDocPropForDelete.FAL_DOC_PROP_ID, 1, 0, 0);
    end loop;
  end DeleteSelectedFAL_DOC_PROP;

/**
* procedure GetNegoSupplier
* Description : Renvoie les noms des fournisseurs négo de l'année précédente
*
* @author ECA
* @lastUpdate
* @public
* @param
*/
  function GetNegoSupplier(aGCO_GOOD_ID number, aGCO2_GOOD_ID number)
    return varchar2
  is
    cursor CUR_NEGO_SUPPLIER
    is
      select (PER_NAME || ' ' || PER_FORENAME) SUPPLIER_N1
        from FAL_DOC_CONSULT_HIST FDC_N1
           , PAC_PERSON PER
       where FDC_N1.FDC_NEGOTIATION = 1
         and FDC_N1.GCO_GOOD_ID = aGCO_GOOD_ID
         and FDC_N1.GCO2_GOOD_ID = aGCO2_GOOD_ID
         and FDC_N1.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID
         and to_number(to_char(FDC_N1.A_DATECRE, 'YYYY') ) = to_number(to_char(sysdate, 'YYYY') - 1);

    CurNegoSupplier CUR_NEGO_SUPPLIER%rowtype;
    aSuppliersDescr varchar2(4000);
  begin
    for CurNegoSupplier in CUR_NEGO_SUPPLIER loop
      aSuppliersDescr  := aSuppliersDescr || ' - ' || CurNegoSupplier.SUPPLIER_N1;
    end loop;

    aSuppliersDescr  := substr(aSuppliersDescr, 2, length(aSuppliersDescr) );
    return aSuppliersDescr;
  exception
    when others then
      return '';
  end GetNegoSupplier;
end;
