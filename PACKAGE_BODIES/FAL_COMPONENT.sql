--------------------------------------------------------
--  DDL for Package Body FAL_COMPONENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_COMPONENT" 
is
  -- Donne la sommes des Qtés attribuées sur stock de besoins du produit pour une liste de Pofs Sélectionnées.
  function GetAttrStkOfPdtForSelectedPof(
    PrmListFAL_LOT_PROP_ID varchar   -- Liste des propositions, ce paramètres est toujours vide sauf si l'appel est amené par le reprise des propositions
  , PrmGCO_GOOD_ID         GCO_GOOD.GCO_GOOD_ID%type
  , PrmNeedDate            date
  )
    return FAL_NETWORK_NEED.FAN_FREE_QTY%type
  is
    LocSource_Cursor integer;
    Ignore           integer;
    CurSomme         number;
    BuffSql          varchar2(2000);
  begin
    BuffSql           :=
      ' SELECT NVL(SUM(FAN.FAN_STK_QTY),0) ' ||
      '   FROM FAL_NETWORK_NEED FAN ' ||
      '  WHERE  FAN.FAL_LOT_PROP_ID IN (' ||
      PrmListFAL_LOT_PROP_ID ||
      ')' ||
      '    AND FAN.GCO_GOOD_ID    = ' ||
      PrmGCO_GOOD_ID ||
      '    and STM_I_LIB_MOVEMENT.VerifyForecastStockPosCond(
              iGoodId            => FAN.GCO_GOOD_ID
            , iPiece             => FAN.FAN_PIECE
            , iSet               => FAN.FAN_SET
            , iVersion           => FAN.FAN_VERSION
            , iChronological     => FAN.FAN_CHRONOLOGICAL
            , iQualityStatusId   => GCO_I_LIB_QUALITY_STATUS.GetReceiptStatus(FAN.GCO_GOOD_ID)
            , iDateRequest       => to_date(''' ||
      to_char(PrmNeedDate, 'YYYYMMDD') ||
      ''' , ''YYYYMMDD'')' ||
      ') is not null';
    LocSource_Cursor  := DBMS_SQL.open_cursor;
    DBMS_SQL.Parse(LocSource_Cursor, BuffSql, DBMS_SQL.V7);
    DBMS_SQL.Define_column(LocSource_Cursor, 1, CurSomme);
    Ignore            := DBMS_SQL.execute(LocSource_cursor);
    CurSomme          := 0;

    if DBMS_SQL.fetch_rows(Locsource_cursor) > 0 then
      DBMS_SQL.column_value(LocSource_Cursor, 1, CurSomme);
    end if;

    DBMS_SQL.close_cursor(Locsource_cursor);
    return CurSomme;
  exception
    when others then
      if DBMS_SQL.IS_OPEN(Locsource_cursor) then
        DBMS_SQL.close_cursor(Locsource_cursor);
      end if;

      raise;
  end;

-- Calcul de l'alerte
  function AlerteOnGco_GOOD(
    PrmGCO_GOOD_ID         GCO_GOOD.GCO_GOOD_ID%type
  , PrmBesoinTotale        number
  , PrmListFAL_LOT_PROP_ID varchar   -- Liste des propositions, ce paramètres est toujours vide sauf si l'appel est amené par le reprise des propositions
  , PrmNeedDate            date
  )
    return boolean
  is
    NoChz            boolean;
    FullTracability  boolean;
    LocSource_Cursor integer;
    Ignore           integer;
    CurSomme         number;
    BuffSql          varchar2(2000);
  begin
    -- Détermination si le composant a des caractérisations
    NoChz             := FAL_TOOLS.IsCmpWithChz(PrmGCO_GOOD_ID);
    -- Détermination si le composant est en traçabilité totale
    FullTracability   := FAL_TOOLS.IsFullTracability(PrmGCO_GOOD_ID);
    BuffSql           :=
      ' SELECT nvl(Sum(SPO.SPO_AVAILABLE_QUANTITY),0) FROM STM_STOCK_POSITION SPO, V_STM_STOCK_LOCATION LOC WHERE ' ||
      ' LOC.STM_LOCATION_ID = SPO.STM_LOCATION_ID and ' ||
      ' GCO_GOOD_ID =  ' ||
      PrmGCO_GOOD_ID ||
      ' and ' ||
      ' C_ACCESS_METHOD <> ''PRIVATE'' and' ||
      ' STM_I_LIB_MOVEMENT.VerifyForecastStockPosCond(
              iGoodId            => SPO.GCO_GOOD_ID
            , iPiece             => SPO.SPO_PIECE
            , iSet               => SPO.SPO_SET
            , iVersion           => SPO.SPO_VERSION
            , iChronological     => SPO.SPO_CHRONOLOGICAL
            , iQualityStatusId   => GCO_I_LIB_QUALITY_STATUS.GetReceiptStatus(SPO.GCO_GOOD_ID)
            , iDateRequest       =>  to_date(''' ||
      to_char(prmNeedDate, 'YYYYMMDD') ||
      ''' , ''YYYYMMDD'')' ||
      ' ) is not null';

    -- Si existance de caractérisations
    if not NoChz then
      if not FullTracability then
        -- Si pas en traçabilité totale
        BuffSql  := BuffSql || ' AND SPO.SPO_AVAILABLE_QUANTITY > 0';
      else
        -- Si en traçabilité totale
        BuffSql  := BuffSql || ' AND SPO.SPO_AVAILABLE_QUANTITY >= ' || PrmbesoinTotale;
      end if;
    end if;

    LocSource_Cursor  := DBMS_SQL.open_cursor;
    DBMS_SQL.Parse(LocSource_Cursor, BuffSql, DBMS_SQL.V7);
    DBMS_SQL.Define_column(LocSource_Cursor, 1, CurSomme);
    Ignore            := DBMS_SQL.execute(LocSource_cursor);
    CurSomme          := 0;

    if DBMS_SQL.fetch_rows(Locsource_cursor) > 0 then
      DBMS_SQL.column_value(LocSource_Cursor, 1, CurSomme);
    end if;

    DBMS_SQL.close_cursor(Locsource_cursor);

    if CurSomme < PrmbesoinTotale then
      -- Pas assez en disponible
      if    FullTracability
         or PrmListFAL_LOT_PROP_ID is null then
        return true;
      else
        -- On va alors regarder s'il existe de la couverture par attribution sur stock
        -- pour les besoins des propositions regroupées
        if CurSomme + GetAttrStkOfPdtForSelectedPof(PrmListFAL_LOT_PROP_ID, PrmGCO_GOOD_ID, PrmNeedDate) < PrmbesoinTotale then
          -- Il y alerte car pas assez même avec les attributions sur stock
          return true;
        else
          -- Pas d'alerte: le stock et les attributions sur stocks couvrent la Qté Besoin Totale
          return false;
        end if;
      end if;
    else
      -- Pas d'alerte: le stock couvre la Qté Besoin Totale
      return false;   -- Pas d'alerte
    end if;

    return CurSomme < PrmbesoinTotale;
  exception
    when others then
      if DBMS_SQL.IS_OPEN(Locsource_cursor) then
        DBMS_SQL.close_cursor(Locsource_cursor);
      end if;

      raise;
  end;

  function DoRemplacement(
    aCRemplacementNom    PPS_NOM_BOND.C_REMPLACEMENT_NOM%type
  , aGcoGoodId           GCO_GOOD.GCO_GOOD_ID%type
  , aEndValidDate        PPS_NOM_BOND.COM_END_VALID%type
  , aTotalRequirementQty FAL_LOT_MATERIAL_LINK.LOM_FULL_REQ_QTY%type
  , aLotBeginDate        FAL_LOT.LOT_PLAN_BEGIN_DTE%type
  , aListOfPropositionId varchar   -- Liste des propositions, ce paramètres est toujours vide sauf si l'appel est amené par le reprise des propositions
  )
    return boolean
  is
  begin
    if    (    aCRemplacementNom = '1'
           and nvl(aLotBeginDate, sysdate) >= aEndValidDate)
       or (    aCRemplacementNom = '2'
           and AlerteOnGco_GOOD(aGcoGoodId, aTotalRequirementQty, aListOfPropositionId, aLotBeginDate) ) then
      return true;
    end if;

    return false;
  end;

-- établit la nécéssité, la possibilité et traite le cas échéant la substitution du composant.
  function GetSubstituteGoodId(aGcoGoodId GCO_GOOD.GCO_GOOD_ID%type)
    return GCO_GOOD.GCO_GOOD_ID%type
  is
    Consommation boolean;
    SubstGoodId  GCO_GOOD.GCO_GOOD_ID%type;

    cursor crSubstitutionGood
    is
      select   GS.GCO_GOOD_ID
          from GCO_SUBSTITUTE GS
             , GCO_GOOD GG
             , GCO_SUBSTITUTION_LIST GSL
         where GG.GCO_GOOD_ID = aGcoGoodId
           and GG.GCO_SUBSTITUTION_LIST_ID = GSL.GCO_SUBSTITUTION_LIST_ID
           and GSL.GCO_SUBSTITUTION_LIST_ID = GS.GCO_SUBSTITUTION_LIST_ID
           and nvl(GSL.SUL_FROM_DATE, sysdate) <= sysdate
           and nvl(GSL.SUL_UNTIL_DATE, sysdate) >= sysdate
      order by SUB_POSITION asc;
  begin
    -- Existance d'une liste de substitution valide
    -- Récupérer un potentiel bien de substitution
    SubstGoodId  := null;

    open crSubstitutionGood;

    fetch crSubstitutionGood
     into SubstGoodId;

    close crSubstitutionGood;

    return SubstGoodId;
  end;

  function GetTotalRequirementQty(
    aLotTotalQty                  FAL_LOT.LOT_TOTAL_QTY%type
  , aCTypeCom                     FAL_LOT_MATERIAL_LINK.C_TYPE_COM%type
  , aCKindCom                     FAL_LOT_MATERIAL_LINK.C_KIND_COM%type
  , aUtilCoeff                    FAL_LOT_MATERIAL_LINK.LOM_UTIL_COEF%type
  , aComUtilCoef                  FAL_LOT_MATERIAL_LINK.LOM_UTIL_COEF%type
  , aNomRefQty                    FAL_LOT_MATERIAL_LINK.LOM_REF_QTY%type
  , aNomOriginRefQty              FAL_LOT_MATERIAL_LINK.LOM_REF_QTY%type
  , aGcoGoodId                    FAL_LOT.GCO_GOOD_ID%type
  , aComPercentWaste              PPS_NOM_BOND.COM_PERCENT_WASTE%type
  , aComFixedQuantityWaste        PPS_NOM_BOND.COM_FIXED_QUANTITY_WASTE%type
  , aComQtyReferenceLoss          PPS_NOM_BOND.COM_QTY_REFERENCE_LOSS%type
  , aLOM_UTIL_COEF         in out FAL_LOT_MATERIAL_LINK.LOM_UTIL_COEF%type
  , aLOM_BOM_REQ_QTY       in out FAL_LOT_MATERIAL_LINK.LOM_BOM_REQ_QTY%type
  , aLOM_ADJUSTED_QTY      in out FAL_LOT_MATERIAL_LINK.LOM_ADJUSTED_QTY%type
  , aPdtStockManagement    in out GCO_PRODUCT.PDT_STOCK_MANAGEMENT%type
  )
    return FAL_LOT_MATERIAL_LINK.LOM_FULL_REQ_QTY%type
  is
    cursor crProduct
    is
      select nvl(PDT_STOCK_MANAGEMENT, 0) PDT_STOCK_MANAGEMENT
           , nvl(GOO_NUMBER_OF_DECIMAL, 0) GOO_NUMBER_OF_DECIMAL
        from GCO_GOOD GG
           , GCO_PRODUCT GP
       where GG.GCO_GOOD_ID = aGcoGoodId
         and GG.GCO_GOOD_ID = GP.GCO_GOOD_ID;

    tplProduct crProduct%rowtype;
  begin
    open crProduct;

    fetch crProduct
     into tplProduct;

    aPdtStockManagement  := tplProduct.PDT_STOCK_MANAGEMENT;

    close crProduct;

    aLOM_UTIL_COEF       := nvl(aUtilCoeff * aComUtilCoef / aNomRefQty * aNomOriginRefQty, 0);

    if    aCTypeCom = '5'
       or aCKindCom = '3' then
      aLOM_BOM_REQ_QTY     := 0;
      aLOM_ADJUSTED_QTY    := 0;
      aPdtStockManagement  := 0;
    else
      aLOM_BOM_REQ_QTY  := FAL_TOOLS.ArrondiSuperieur( (aLotTotalQty * aLOM_UTIL_COEF / aNomOriginRefQty), aGcoGoodId);

      if aPdtStockManagement = 1 then
        aLOM_ADJUSTED_QTY  :=
          FAL_TOOLS.ArrondiSuperieur(FAL_TOOLS.CalcTotalTrashQuantity(aLOM_BOM_REQ_QTY, 0, aComPercentWaste, aComFixedQuantityWaste, aComQtyReferenceLoss)
                                   , null
                                   , tplProduct.GOO_NUMBER_OF_DECIMAL
                                    );
      else
        aLOM_ADJUSTED_QTY  := 0;
      end if;
    end if;

    return aLOM_BOM_REQ_QTY + aLOM_ADJUSTED_QTY;
  end;

  function GetTotalRequirementQty(
    aLotTotalQty           FAL_LOT.LOT_TOTAL_QTY%type
  , aCTypeCom              FAL_LOT_MATERIAL_LINK.C_TYPE_COM%type
  , aCKindCom              FAL_LOT_MATERIAL_LINK.C_KIND_COM%type
  , aUtilCoeff             FAL_LOT_MATERIAL_LINK.LOM_UTIL_COEF%type
  , aComUtilCoef           FAL_LOT_MATERIAL_LINK.LOM_UTIL_COEF%type
  , aNomRefQty             FAL_LOT_MATERIAL_LINK.LOM_REF_QTY%type
  , aNomOriginRefQty       FAL_LOT_MATERIAL_LINK.LOM_REF_QTY%type
  , aGcoGoodId             FAL_LOT.GCO_GOOD_ID%type
  , aComPercentWaste       PPS_NOM_BOND.COM_PERCENT_WASTE%type
  , aComFixedQuantityWaste PPS_NOM_BOND.COM_FIXED_QUANTITY_WASTE%type
  , aComQtyReferenceLoss   PPS_NOM_BOND.COM_QTY_REFERENCE_LOSS%type
  )
    return FAL_LOT_MATERIAL_LINK.LOM_FULL_REQ_QTY%type
  is
    nLOM_UTIL_COEF      FAL_LOT_MATERIAL_LINK.LOM_UTIL_COEF%type;
    nLOM_BOM_REQ_QTY    FAL_LOT_MATERIAL_LINK.LOM_BOM_REQ_QTY%type;
    nLOM_ADJUSTED_QTY   FAL_LOT_MATERIAL_LINK.LOM_ADJUSTED_QTY%type;
    nPdtStockManagement GCO_PRODUCT.PDT_STOCK_MANAGEMENT%type;
  begin
    return GetTotalRequirementQty(aLotTotalQty             => aLotTotalQty
                                , aCTypeCom                => aCTypeCom
                                , aCKindCom                => aCKindCom
                                , aUtilCoeff               => aUtilCoeff
                                , aComUtilCoef             => aComUtilCoef
                                , aNomRefQty               => aNomRefQty
                                , aNomOriginRefQty         => aNomOriginRefQty
                                , aGcoGoodId               => aGcoGoodId
                                , aComPercentWaste         => aComPercentWaste
                                , aComFixedQuantityWaste   => aComFixedQuantityWaste
                                , aComQtyReferenceLoss     => aComQtyReferenceLoss
                                , aLOM_UTIL_COEF           => nLOM_UTIL_COEF
                                , aLOM_BOM_REQ_QTY         => nLOM_BOM_REQ_QTY
                                , aLOM_ADJUSTED_QTY        => nLOM_ADJUSTED_QTY
                                , aPdtStockManagement      => nPdtStockManagement
                                 );
  end;

  procedure CreateComponent(
    aFalLotId              FAL_LOT.FAL_LOT_ID%type
  , aLotTotalQty           FAL_LOT.LOT_TOTAL_QTY%type
  , aLotInprodQty          FAL_LOT.LOT_INPROD_QTY%type
  , aCmaLotQuantity        GCO_COMPL_DATA_MANUFACTURE.CMA_LOT_QUANTITY%type
  , aCmaFixDelay           GCO_COMPL_DATA_MANUFACTURE.CMA_FIX_DELAY%type
  , aGcoGoodId             FAL_LOT.GCO_GOOD_ID%type
  , aUtilCoeff             FAL_LOT_MATERIAL_LINK.LOM_UTIL_COEF%type
  , aComUtilCoef           FAL_LOT_MATERIAL_LINK.LOM_UTIL_COEF%type
  , aNomRefQty             FAL_LOT_MATERIAL_LINK.LOM_REF_QTY%type
  , aNomOriginRefQty       FAL_LOT_MATERIAL_LINK.LOM_REF_QTY%type
  , aComInterval           FAL_LOT_MATERIAL_LINK.LOM_INTERVAL%type
  , aCKindCom              FAL_LOT_MATERIAL_LINK.C_KIND_COM%type
  , aCTypeCom              FAL_LOT_MATERIAL_LINK.C_TYPE_COM%type
  , aComPercentWaste       PPS_NOM_BOND.COM_PERCENT_WASTE%type
  , aComFixedQuantityWaste PPS_NOM_BOND.COM_FIXED_QUANTITY_WASTE%type
  , aComQtyReferenceLoss   PPS_NOM_BOND.COM_QTY_REFERENCE_LOSS%type
  , aNomLocationId         STM_LOCATION.STM_LOCATION_ID%type
  , aNomStockId            STM_STOCK.STM_STOCK_ID%type
  , aLocationId            STM_LOCATION.STM_LOCATION_ID%type
  , aStockId               STM_STOCK.STM_STOCK_ID%type
  , aProductLocationId     STM_LOCATION.STM_LOCATION_ID%type
  , aProductStockId        STM_STOCK.STM_STOCK_ID%type
  , aComSubstitut          FAL_LOT_MATERIAL_LINK.LOM_SUBSTITUT%type
  , aCDischargeCom         FAL_LOT_MATERIAL_LINK.C_DISCHARGE_COM%type
  , aComMarkTopo           FAL_LOT_MATERIAL_LINK.LOM_MARK_TOPO%type
  , aComText               FAL_LOT_MATERIAL_LINK.LOM_TEXT%type
  , aComIncreaseCost       FAL_LOT_MATERIAL_LINK.LOM_INCREASE_COST%type
  , aComPos                FAL_LOT_MATERIAL_LINK.LOM_POS%type
  , aComResNum             FAL_LOT_MATERIAL_LINK.LOM_FRE_NUM%type
  , aComResText            FAL_LOT_MATERIAL_LINK.LOM_FREE_TEXT%type
  , aScsStepNumberOrigin   FAL_TASK_LINK.SCS_STEP_NUMBER%type
  , aScsStepNumber         FAL_TASK_LINK.SCS_STEP_NUMBER%type
  , aNoComponent           integer default 0
  , aComWeighing           FAL_LOT_MATERIAL_LINK.LOM_WEIGHING%type
  , aComWeighingMandatory  FAL_LOT_MATERIAL_LINK.LOM_WEIGHING_MANDATORY%type
  )
  is
    MajorReference      GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    SecondaryReference  GCO_GOOD.GOO_SECONDARY_REFERENCE%type;
    ShortDescription    GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type;
    FreeDescription     GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type;
    LongDescription     GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type;
    nLOM_SEQ            FAL_LOT_MATERIAL_LINK.LOM_SEQ%type;
    nC_KIND_COM         FAL_LOT_MATERIAL_LINK.C_KIND_COM%type;
    nLOM_UTIL_COEF      FAL_LOT_MATERIAL_LINK.LOM_UTIL_COEF%type;
    nLOM_BOM_REQ_QTY    FAL_LOT_MATERIAL_LINK.LOM_BOM_REQ_QTY%type;
    nLOM_INTERVAL       FAL_LOT_MATERIAL_LINK.LOM_INTERVAL%type;
    nLOM_ADJUSTED_QTY   FAL_LOT_MATERIAL_LINK.LOM_ADJUSTED_QTY%type;
    nLOM_FULL_REQ_QTY   FAL_LOT_MATERIAL_LINK.LOM_FULL_REQ_QTY%type;
    nLOM_AVAILABLE_QTY  FAL_LOT_MATERIAL_LINK.LOM_AVAILABLE_QTY%type;
    nLOM_NEED_QTY       FAL_LOT_MATERIAL_LINK.LOM_NEED_QTY%type;
    nSTM_STOCK_ID       FAL_LOT_MATERIAL_LINK.STM_STOCK_ID%type;
    nSTM_LOCATION_ID    FAL_LOT_MATERIAL_LINK.STM_LOCATION_ID%type;
    nPdtStockManagement GCO_PRODUCT.PDT_STOCK_MANAGEMENT%type;
  begin
    select nvl(max(LOM_SEQ), 0) + PCS.PC_CONFIG.GetConfig('FAL_COMPONENT_NUMBERING')
      into nLOM_SEQ
      from FAL_LOT_MATERIAL_LINK
     where FAL_LOT_ID = aFalLotId;

    if aNoComponent = 0 then
      FAL_TOOLS.GetMajorSecShortFreeLong(aGcoGoodId, MajorReference, SecondaryReference, ShortDescription, FreeDescription, LongDescription);

      if aCmaFixDelay = 1 then
        nLOM_INTERVAL  := aComInterval;
      else
        nLOM_INTERVAL  := (aLotTotalQty / FAL_TOOLS.nvla(aCmaLotQuantity, 1) ) * aComInterval;
      end if;

      nC_KIND_COM        := aCKindCom;
      nLOM_FULL_REQ_QTY  :=
        GetTotalRequirementQty(aLotTotalQty             => aLotTotalQty
                             , aCTypeCom                => aCTypeCom
                             , aCKindCom                => nC_KIND_COM
                             , aUtilCoeff               => aUtilCoeff
                             , aComUtilCoef             => aComUtilCoef
                             , aNomRefQty               => aNomRefQty
                             , aNomOriginRefQty         => aNomOriginRefQty
                             , aGcoGoodId               => aGcoGoodId
                             , aComPercentWaste         => aComPercentWaste
                             , aComFixedQuantityWaste   => aComFixedQuantityWaste
                             , aComQtyReferenceLoss     => aComQtyReferenceLoss
                             , aLOM_UTIL_COEF           => nLOM_UTIL_COEF
                             , aLOM_BOM_REQ_QTY         => nLOM_BOM_REQ_QTY
                             , aLOM_ADJUSTED_QTY        => nLOM_ADJUSTED_QTY
                             , aPdtStockManagement      => nPdtStockManagement
                              );

      if nC_KIND_COM in('3', '4', '5') then
        nLOM_AVAILABLE_QTY  := 0;
        nSTM_STOCK_ID       := null;
        nSTM_LOCATION_ID    := null;
      else
        if     nC_KIND_COM = '1'
           and nPdtStockManagement <> 1 then
          nLOM_AVAILABLE_QTY  := nLOM_BOM_REQ_QTY + nLOM_ADJUSTED_QTY;
        else
          nLOM_AVAILABLE_QTY  := 0;
        end if;

        if     nC_KIND_COM = '1'
           and nPdtStockManagement = 1 then
          nLOM_NEED_QTY  := nLOM_BOM_REQ_QTY + nLOM_ADJUSTED_QTY;
        else
          nLOM_NEED_QTY  := 0;
        end if;

        if nPdtStockManagement = 1 then
          nSTM_STOCK_ID     := null;
          nSTM_LOCATION_ID  := null;

          if    (aNomLocationId is not null)
             or (aNomStockId is not null) then
            nSTM_STOCK_ID     := aNomStockId;
            nSTM_LOCATION_ID  := aNomLocationId;
          elsif    (aLocationId is not null)
                or (aStockId is not null) then
            nSTM_STOCK_ID     := aStockId;
            nSTM_LOCATION_ID  := aLocationId;
          elsif    (aProductLocationId is not null)
                or (aProductStockId is not null) then
            nSTM_STOCK_ID     := aProductStockId;
            nSTM_LOCATION_ID  := aProductLocationId;
          end if;

          if nSTM_STOCK_ID is null then
            nSTM_STOCK_ID  := FAL_TOOLS.GetConfig_StockID('GCO_DefltSTOCK');
          end if;

          if nSTM_LOCATION_ID is null then
            nSTM_LOCATION_ID  := FAL_TOOLS.GetMinClassifLocationOfStock(nSTM_STOCK_ID);
          end if;
        else
          nSTM_STOCK_ID     := FAL_TOOLS.GetDefaultStock;
          nSTM_LOCATION_ID  := null;
        end if;
      end if;
    else
      if aNoComponent = 2 then
        FAL_TOOLS.GetMajorSecShortFreeLong(aGcoGoodId, MajorReference, SecondaryReference, ShortDescription, FreeDescription, LongDescription);
      else
        SecondaryReference  := PCS.PC_FUNCTIONS.TranslateWord('Sans composant');
        ShortDescription    := PCS.PC_FUNCTIONS.TranslateWord('Sans composant');
        FreeDescription     := PCS.PC_FUNCTIONS.TranslateWord('Sans composant');
        LongDescription     := PCS.PC_FUNCTIONS.TranslateWord('Sans composant');
        nC_KIND_COM         := '5';
      end if;

      nLOM_UTIL_COEF       := 0;
      nLOM_BOM_REQ_QTY     := 0;
      nLOM_INTERVAL        := 0;
      nLOM_ADJUSTED_QTY    := 0;
      nLOM_FULL_REQ_QTY    := 0;
      nLOM_AVAILABLE_QTY   := 0;
      nLOM_NEED_QTY        := 0;
      nSTM_STOCK_ID        := null;
      nSTM_LOCATION_ID     := null;
      nPdtStockManagement  := 0;
    end if;

    insert into FAL_LOT_MATERIAL_LINK
                (FAL_LOT_MATERIAL_LINK_ID
               , LOM_SEQ
               , C_TYPE_COM
               , C_KIND_COM
               , LOM_SUBSTITUT
               , C_DISCHARGE_COM
               , FAL_LOT_ID
               , GCO_GOOD_ID
               , C_CHRONOLOGY_TYPE
               , LOM_CONSUMPTION_QTY
               , LOM_REJECTED_QTY
               , LOM_BACK_QTY
               , LOM_PT_REJECT_QTY
               , LOM_CPT_TRASH_QTY
               , LOM_CPT_RECOVER_QTY
               , LOM_CPT_REJECT_QTY
               , LOM_EXIT_RECEIPT
               , LOM_MAX_FACT_QTY
               , LOM_ADJUSTED_QTY_RECEIPT
               , LOM_MARK_TOPO
               , LOM_TEXT
               , LOM_INCREASE_COST
               , LOM_UTIL_COEF
               , LOM_REF_QTY
               , LOM_BOM_REQ_QTY
               , LOM_POS
               , LOM_PRICE
               , LOM_INTERVAL
               , LOM_MISSING
               , LOM_STOCK_MANAGEMENT
               , LOM_SHORT_DESCR
               , LOM_FREE_DECR
               , LOM_LONG_DESCR
               , LOM_SECONDARY_REF
               , LOM_FRE_NUM
               , LOM_FREE_TEXT
               , LOM_TASK_SEQ
               , LOM_ADJUSTED_QTY
               , LOM_FULL_REQ_QTY
               , LOM_AVAILABLE_QTY
               , LOM_NEED_QTY
               , LOM_MAX_RECEIPT_QTY
               , STM_STOCK_ID
               , STM_LOCATION_ID
               , LOM_PERCENT_WASTE
               , LOM_FIXED_QUANTITY_WASTE
               , LOM_QTY_REFERENCE_LOSS
               , LOM_WEIGHING
               , LOM_WEIGHING_MANDATORY
               , A_DATECRE
               , A_IDCRE
                )
         values (GetNewId
               , nLOM_SEQ
               , aCTypeCom
               , nC_KIND_COM
               , aComSubstitut
               , aCDischargeCom
               , aFalLotId
               , aGcoGoodId
               , (select C_CHRONOLOGY_TYPE
                    from GCO_CHARACTERIZATION
                   where GCO_GOOD_ID = aGcoGoodId
                     and C_CHARACT_TYPE = '5')
               , 0
               , 0
               , 0
               , 0
               , 0
               , 0
               , 0
               , 0
               , 0
               , 0
               , aComMarkTopo
               , aComText
               , aComIncreaseCost
               , nLOM_UTIL_COEF
               , aNomOriginRefQty
               , nLOM_BOM_REQ_QTY
               , aComPos
               , GCO_FUNCTIONS.GetCostPriceWithManagementMode(aGcoGoodId)
               , nLOM_INTERVAL
               , 0
               , nvl(nPdtStockManagement, 0)
               , ShortDescription
               , FreeDescription
               , LongDescription
               , SecondaryReference
               , aComResNum
               , aComResText
               , nvl(aScsStepNumberOrigin, aScsStepNumber)
               , nLOM_ADJUSTED_QTY
               , nLOM_FULL_REQ_QTY
               , nLOM_AVAILABLE_QTY
               , nvl(nLOM_NEED_QTY, 0)
               , 0   -- LOM_MAX_RECEIPT_QTY
               , nSTM_STOCK_ID
               , nSTM_LOCATION_ID
               , aComPercentWaste
               , aComFixedQuantityWaste
               , aComQtyReferenceLoss
               , aComWeighing
               , aComWeighingMandatory
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end;

  -- procedure de génération des composants
  procedure GenerateComponents(
    aFalLotId            FAL_LOT.FAL_LOT_ID%type
  , aInRecursifMode      integer default 0
  , aReplacementMode     integer default 0
  , aGcoGoodId           GCO_GOOD.GCO_GOOD_ID%type
  , aPpsNomenclatureId   PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type default null
  , aUtilCoeff           FAL_LOT_MATERIAL_LINK.LOM_UTIL_COEF%type default 1
  , aListOfPropositionId varchar2
        default null   -- Liste des propositions, ce paramètres est toujours vide sauf si l'appel est amené par le reprise des propositions
  , aLotTotalQty         FAL_LOT.LOT_TOTAL_QTY%type
  , aStockId             FAL_LOT.STM_STOCK_ID%type
  , aLocationId          FAL_LOT.STM_LOCATION_ID%type
  , aLotBeginDate        FAL_LOT.LOT_PLAN_BEGIN_DTE%type
  , aNomOriginRefQty     number default null
  , aScsStepNumberOrigin number default null
  , aLotInprodQty        FAL_LOT.LOT_INPROD_QTY%type
  , aCmaFixDelay         GCO_COMPL_DATA_MANUFACTURE.CMA_FIX_DELAY%type
  , aCmaLotQuantity      GCO_COMPL_DATA_MANUFACTURE.CMA_LOT_QUANTITY%type
  , iCFabType            FAL_LOT.C_FAB_TYPE%type
  , iC_DISCHARGE_COM     GCO_COMPL_DATA_SUBCONTRACT.C_DISCHARGE_COM%type
  )
  is
    cursor crComponent
    is
      select   PNB.PPS_NOM_BOND_ID
             , PNB.C_TYPE_COM
             , PNB.C_KIND_COM
             , PNB.GCO_GOOD_ID
             , PNB.STM_STOCK_ID
             , PNB.STM_LOCATION_ID
             , (select STM_STOCK_ID
                  from GCO_PRODUCT
                 where GCO_GOOD_ID = PNB.GCO_GOOD_ID) PRODUCT_STOCK_ID
             , (select STM_LOCATION_ID
                  from GCO_PRODUCT
                 where GCO_GOOD_ID = PNB.GCO_GOOD_ID) PRODUCT_LOCATION_ID
             , PN.C_TYPE_NOM
             , PN.NOM_REF_QTY
             , nvl(PNB.COM_SUBSTITUT, 0) COM_SUBSTITUT
             -- Pour un OF de sous-traitance, le code de décharge doit être '2' ou '5'. On force à '2' si c'est une autre valeur que 5 .
      ,        case iCFabType
                 when FAL_BATCH_FUNCTIONS.btSubcontract then case
                                                              when iC_DISCHARGE_COM is not null then iC_DISCHARGE_COM
                                                              when PNB.C_DISCHARGE_COM = '5' then '5'
                                                              else '2'
                                                            end
                 else PNB.C_DISCHARGE_COM
               end C_DISCHARGE_COM
             , PNB.COM_MARK_TOPO
             , PNB.COM_TEXT
             , nvl(PNB.COM_INCREASE_COST, 1) COM_INCREASE_COST
             , PNB.COM_UTIL_COEFF
             , PNB.COM_POS
             , nvl(PNB.COM_INTERVAL, 0) COM_INTERVAL
             , PNB.COM_RES_NUM
             , PNB.COM_RES_TEXT
             , nvl(PNB.COM_PERCENT_WASTE, 0) COM_PERCENT_WASTE
             , nvl(PNB.COM_FIXED_QUANTITY_WASTE, 0) COM_FIXED_QUANTITY_WASTE
             , nvl(PNB.COM_QTY_REFERENCE_LOSS, 0) COM_QTY_REFERENCE_LOSS
             , PNB.COM_REMPLACEMENT
             , PNB.C_REMPLACEMENT_NOM
             , PNB.COM_END_VALID
             , PNB.COM_WEIGHING
             , PNB.COM_WEIGHING_MANDATORY
             , (select TAL.SCS_STEP_NUMBER
                  from FAL_TASK_LINK TAL
                     , FAL_LIST_STEP_LINK LSL
                 where LSL.FAL_SCHEDULE_STEP_ID = PNB.FAL_SCHEDULE_STEP_ID
                   and TAL.FAL_LOT_ID = aFalLotId
                   and TAL.TAL_SEQ_ORIGIN = LSL.SCS_STEP_NUMBER) SCS_STEP_NUMBER
             , nvl(PNB.PPS_PPS_NOMENCLATURE_ID, (select PPS_NOMENCLATURE_ID
                                                   from PPS_NOMENCLATURE
                                                  where GCO_GOOD_ID = PNB.GCO_GOOD_ID
                                                    and C_TYPE_NOM = 2
                                                    and NOM_DEFAULT = 1) ) PPS_PPS_NOMENCLATURE_ID
             , (select nvl(PDT_BLOCK_EQUI, 0)
                  from GCO_PRODUCT
                 where GCO_GOOD_ID = PNB.GCO_GOOD_ID) HAS_EQUIVALENT
          from PPS_NOMENCLATURE PN
             , PPS_NOM_BOND PNB
         where PNB.PPS_NOMENCLATURE_ID = PN.PPS_NOMENCLATURE_ID
           and (   PNB.C_TYPE_COM = '1'
                or (     (   PNB.C_KIND_COM = '5'
                          or PNB.C_KIND_COM = '4')
                    and PCS.PC_CONFIG.GetConfig('PPS_TYPE_COM') = 'True') )
           and (    (    nvl(aPpsNomenclatureId, 0) <> 0
                     and PN.PPS_NOMENCLATURE_ID = aPpsNomenclatureId)
                or (    nvl(aPpsNomenclatureId, 0) = 0
                    and aInRecursifMode = 1
                    and PN.GCO_GOOD_ID = aGcoGoodId
                    and PN.NOM_DEFAULT = 1
                    and (    (    aReplacementMode = 1
                              and C_TYPE_NOM = '6')
                         or (    aReplacementMode = 0
                             and C_TYPE_NOM = '2') )
                   )
               )
      order by PNB.COM_SEQ;

    EquivalentGoodId    GCO_GOOD.GCO_GOOD_ID%type;
    ComponentsCount     integer;
    SubstituteGoodId    GCO_GOOD.GCO_GOOD_ID%type;
    TotalRequirementQty number;
  begin
    -- Si on n'est pas en mode récursif et que la nomenclature n'est pas définie,
    -- on ne fait rien. Seul un composant de type texte "sans composant" sera créé.
    if not(     (aInRecursifMode = 0)
           and (nvl(aPpsNomenclatureId, 0) = 0) ) then
      for tplComponent in crComponent loop
        if    (tplComponent.C_KIND_COM = '5')
           or (tplComponent.C_KIND_COM = '4') then   -- Type texte
          CreateComponent(aFalLotId                => aFalLotId
                        , aLotTotalQty             => aLotTotalQty
                        , aLotInprodQty            => aLotInprodQty
                        , aCmaLotQuantity          => aCmaLotQuantity
                        , aCmaFixDelay             => aCmaFixDelay
                        , aGcoGoodId               => tplComponent.GCO_GOOD_ID
                        , aUtilCoeff               => aUtilCoeff
                        , aComUtilCoef             => tplComponent.COM_UTIL_COEFF
                        , aNomRefQty               => tplComponent.NOM_REF_QTY
                        , aNomOriginRefQty         => nvl(aNomOriginRefQty, tplComponent.NOM_REF_QTY)
                        , aComInterval             => tplComponent.COM_INTERVAL
                        , aCKindCom                => tplComponent.C_KIND_COM
                        , aCTypeCom                => tplComponent.C_TYPE_COM
                        , aComPercentWaste         => tplComponent.COM_PERCENT_WASTE
                        , aComFixedQuantityWaste   => tplComponent.COM_FIXED_QUANTITY_WASTE
                        , aComQtyReferenceLoss     => tplComponent.COM_QTY_REFERENCE_LOSS
                        , aNomLocationId           => tplComponent.STM_LOCATION_ID
                        , aNomStockId              => tplComponent.STM_STOCK_ID
                        , aLocationId              => aLocationId
                        , aStockId                 => aStockId
                        , aProductLocationId       => tplComponent.PRODUCT_LOCATION_ID
                        , aProductStockId          => tplComponent.PRODUCT_STOCK_ID
                        , aComSubstitut            => tplComponent.COM_SUBSTITUT
                        , aCDischargeCom           => tplComponent.C_DISCHARGE_COM
                        , aComMarkTopo             => tplComponent.COM_MARK_TOPO
                        , aComText                 => tplComponent.COM_TEXT
                        , aComIncreaseCost         => tplComponent.COM_INCREASE_COST
                        , aComPos                  => tplComponent.COM_POS
                        , aComResNum               => tplComponent.COM_RES_NUM
                        , aComResText              => tplComponent.COM_RES_TEXT
                        , aScsStepNumberOrigin     => case aInRecursifMode
                            when 1 then aScsStepNumberOrigin
                            else tplComponent.SCS_STEP_NUMBER
                          end
                        , aScsStepNumber           => tplComponent.SCS_STEP_NUMBER
                        , aComWeighing             => tplComponent.COM_WEIGHING
                        , aComWeighingMandatory    => tplComponent.COM_WEIGHING_MANDATORY
                         );
        else
          if tplComponent.C_KIND_COM = '3' then   -- Pseudo
            CreateComponent(aFalLotId                => aFalLotId
                          , aLotTotalQty             => aLotTotalQty
                          , aLotInprodQty            => aLotInprodQty
                          , aCmaLotQuantity          => aCmaLotQuantity
                          , aCmaFixDelay             => aCmaFixDelay
                          , aGcoGoodId               => tplComponent.GCO_GOOD_ID
                          , aUtilCoeff               => aUtilCoeff
                          , aComUtilCoef             => tplComponent.COM_UTIL_COEFF
                          , aNomRefQty               => tplComponent.NOM_REF_QTY
                          , aNomOriginRefQty         => nvl(aNomOriginRefQty, tplComponent.NOM_REF_QTY)
                          , aComInterval             => tplComponent.COM_INTERVAL
                          , aCKindCom                => tplComponent.C_KIND_COM
                          , aCTypeCom                => tplComponent.C_TYPE_COM
                          , aComPercentWaste         => tplComponent.COM_PERCENT_WASTE
                          , aComFixedQuantityWaste   => tplComponent.COM_FIXED_QUANTITY_WASTE
                          , aComQtyReferenceLoss     => tplComponent.COM_QTY_REFERENCE_LOSS
                          , aNomLocationId           => tplComponent.STM_LOCATION_ID
                          , aNomStockId              => tplComponent.STM_STOCK_ID
                          , aLocationId              => aLocationId
                          , aStockId                 => aStockId
                          , aProductLocationId       => tplComponent.PRODUCT_LOCATION_ID
                          , aProductStockId          => tplComponent.PRODUCT_STOCK_ID
                          , aComSubstitut            => tplComponent.COM_SUBSTITUT
                          , aCDischargeCom           => tplComponent.C_DISCHARGE_COM
                          , aComMarkTopo             => tplComponent.COM_MARK_TOPO
                          , aComText                 => tplComponent.COM_TEXT
                          , aComIncreaseCost         => tplComponent.COM_INCREASE_COST
                          , aComPos                  => tplComponent.COM_POS
                          , aComResNum               => tplComponent.COM_RES_NUM
                          , aComResText              => tplComponent.COM_RES_TEXT
                          , aScsStepNumberOrigin     => case aInRecursifMode
                              when 1 then aScsStepNumberOrigin
                              else tplComponent.SCS_STEP_NUMBER
                            end
                          , aScsStepNumber           => tplComponent.SCS_STEP_NUMBER
                          , aComWeighing             => tplComponent.COM_WEIGHING
                          , aComWeighingMandatory    => tplComponent.COM_WEIGHING_MANDATORY
                           );

            if nvl(tplComponent.PPS_PPS_NOMENCLATURE_ID, 0) <> 0 then
              GenerateComponents(aFalLotId              => aFalLotId
                               , aInRecursifMode        => 1
                               , aReplacementMode       => 0
                               , aGcoGoodId             => tplComponent.GCO_GOOD_ID
                               , aPpsNomenclatureId     => tplComponent.PPS_PPS_NOMENCLATURE_ID
                               , aUtilCoeff             => aUtilCoeff * tplComponent.COM_UTIL_COEFF / tplComponent.NOM_REF_QTY
                               , aListOfPropositionId   => aListOfPropositionId
                               , aLotTotalQty           => aLotTotalQty
                               , aStockId               => aStockId
                               , aLocationId            => aLocationId
                               , aLotBeginDate          => aLotBeginDate
                               , aNomOriginRefQty       => nvl(aNomOriginRefQty, tplComponent.NOM_REF_QTY)
                               , aScsStepNumberOrigin   => case aInRecursifMode
                                   when 1 then aScsStepNumberOrigin
                                   else tplComponent.SCS_STEP_NUMBER
                                 end
                               , aLotInprodQty          => aLotInprodQty
                               , aCmaFixDelay           => aCmaFixDelay
                               , aCmaLotQuantity        => aCmaLotQuantity
                               , iCFabType              => iCFabType
                               , iC_DISCHARGE_COM       => iC_DISCHARGE_COM
                                );
            end if;
          else
            if tplComponent.C_KIND_COM in('1', '2') then   -- B1 Si Genre <> Pseudo
              EquivalentGoodId     := null;

              /* Si FAL_BLOC = 1 et produit avec Bloc Equiv alors :
                 le composant générique est remplacé dans le lot de fabrication par le composant du bloc
                 ayant le stock FIFO le plus vieux. Si aucun composant du bloc n'a de stock alors prise en
                 compte du produit fabricant de la donnée complémentaire par défaut du produit générique. */
              if     PCS.PC_CONFIG.GetConfig('FAL_BLOC') = '1'
                 and tplComponent.HAS_EQUIVALENT = 1 then
                EquivalentGoodId  := GCO_FUNCTIONS.GetEquivalentPropComponent(tplComponent.GCO_GOOD_ID);

                if nvl(EquivalentGoodId, 0) = 0 then
                  EquivalentGoodId  := null;
                end if;
              end if;

              TotalRequirementQty  :=
                GetTotalRequirementQty(aLotTotalQty             => aLotTotalQty
                                     , aCTypeCom                => tplComponent.C_TYPE_COM
                                     , aCKindCom                => tplComponent.C_KIND_COM
                                     , aUtilCoeff               => aUtilCoeff
                                     , aComUtilCoef             => tplComponent.COM_UTIL_COEFF
                                     , aNomRefQty               => tplComponent.NOM_REF_QTY
                                     , aNomOriginRefQty         => nvl(aNomOriginRefQty, tplComponent.NOM_REF_QTY)
                                     , aGcoGoodId               => tplComponent.GCO_GOOD_ID
                                     , aComPercentWaste         => tplComponent.COM_PERCENT_WASTE
                                     , aComFixedQuantityWaste   => tplComponent.COM_FIXED_QUANTITY_WASTE
                                     , aComQtyReferenceLoss     => tplComponent.COM_QTY_REFERENCE_LOSS
                                      );

              -- Recherche s'il y a remplacement sur stock ou date
              if     (tplComponent.COM_REMPLACEMENT = 1)
                 and DoRemplacement(aCRemplacementNom      => tplComponent.C_REMPLACEMENT_NOM
                                  , aGcoGoodId             => nvl(EquivalentGoodId, tplComponent.GCO_GOOD_ID)
                                  , aEndValidDate          => tplComponent.COM_END_VALID
                                  , aTotalRequirementQty   => TotalRequirementQty
                                  , aListOfPropositionId   => aListOfPropositionId
                                  , aLotBeginDate          => aLotBeginDate
                                   ) then
                GenerateComponents(aFalLotId              => aFalLotId
                                 , aInRecursifMode        => 1
                                 , aReplacementMode       => 1
                                 , aGcoGoodId             => tplComponent.GCO_GOOD_ID
                                 , aPpsNomenclatureId     => null
                                 , aUtilCoeff             => aUtilCoeff * tplComponent.COM_UTIL_COEFF / tplComponent.NOM_REF_QTY
                                 , aListOfPropositionId   => aListOfPropositionId
                                 , aLotTotalQty           => aLotTotalQty
                                 , aStockId               => aStockId
                                 , aLocationId            => aLocationId
                                 , aLotBeginDate          => aLotBeginDate
                                 , aNomOriginRefQty       => nvl(aNomOriginRefQty, tplComponent.NOM_REF_QTY)
                                 , aScsStepNumberOrigin   => case aInRecursifMode
                                     when 1 then aScsStepNumberOrigin
                                     else tplComponent.SCS_STEP_NUMBER
                                   end
                                 , aLotInprodQty          => aLotInprodQty
                                 , aCmaFixDelay           => aCmaFixDelay
                                 , aCmaLotQuantity        => aCmaLotQuantity
                                 , iCFabType              => iCFabType
                                 , iC_DISCHARGE_COM       => iC_DISCHARGE_COM
                                  );
              else
                SubstituteGoodId  := null;

                if     PCS.PC_CONFIG.GetBooleanConfig('FAL_SUBST_CREA')
                   and (tplComponent.COM_SUBSTITUT = 1)
                   and AlerteOnGco_GOOD(nvl(EquivalentGoodId, tplComponent.GCO_GOOD_ID), TotalRequirementQty, aListOfPropositionId, aLotBeginDate) then
                  SubstituteGoodId  := GetSubstituteGoodId(nvl(EquivalentGoodId, tplComponent.GCO_GOOD_ID) );
                end if;

                CreateComponent(aFalLotId                => aFalLotId
                              , aLotTotalQty             => aLotTotalQty
                              , aLotInprodQty            => aLotInprodQty
                              , aCmaLotQuantity          => aCmaLotQuantity
                              , aCmaFixDelay             => aCmaFixDelay
                              , aGcoGoodId               => nvl(SubstituteGoodId, nvl(EquivalentGoodId, tplComponent.GCO_GOOD_ID) )
                              , aUtilCoeff               => aUtilCoeff
                              , aComUtilCoef             => tplComponent.COM_UTIL_COEFF
                              , aNomRefQty               => tplComponent.NOM_REF_QTY
                              , aNomOriginRefQty         => nvl(aNomOriginRefQty, tplComponent.NOM_REF_QTY)
                              , aComInterval             => tplComponent.COM_INTERVAL
                              , aCKindCom                => tplComponent.C_KIND_COM
                              , aCTypeCom                => tplComponent.C_TYPE_COM
                              , aComPercentWaste         => tplComponent.COM_PERCENT_WASTE
                              , aComFixedQuantityWaste   => tplComponent.COM_FIXED_QUANTITY_WASTE
                              , aComQtyReferenceLoss     => tplComponent.COM_QTY_REFERENCE_LOSS
                              , aNomLocationId           => tplComponent.STM_LOCATION_ID
                              , aNomStockId              => tplComponent.STM_STOCK_ID
                              , aLocationId              => aLocationId
                              , aStockId                 => aStockId
                              , aProductLocationId       => tplComponent.PRODUCT_LOCATION_ID
                              , aProductStockId          => tplComponent.PRODUCT_STOCK_ID
                              , aComSubstitut            => case SubstituteGoodId
                                  when null then tplComponent.COM_SUBSTITUT
                                  else 0
                                end
                              , aCDischargeCom           => tplComponent.C_DISCHARGE_COM
                              , aComMarkTopo             => tplComponent.COM_MARK_TOPO
                              , aComText                 => tplComponent.COM_TEXT
                              , aComIncreaseCost         => tplComponent.COM_INCREASE_COST
                              , aComPos                  => tplComponent.COM_POS
                              , aComResNum               => tplComponent.COM_RES_NUM
                              , aComResText              => tplComponent.COM_RES_TEXT
                              , aScsStepNumberOrigin     => case aInRecursifMode
                                  when 1 then aScsStepNumberOrigin
                                  else tplComponent.SCS_STEP_NUMBER
                                end
                              , aScsStepNumber           => tplComponent.SCS_STEP_NUMBER
                              , aComWeighing             => tplComponent.COM_WEIGHING
                              , aComWeighingMandatory    => tplComponent.COM_WEIGHING_MANDATORY
                               );
              end if;
            end if;
          end if;
        end if;
      end loop;
    end if;

    if aInRecursifMode = 0 then
      select count(*)
        into ComponentsCount
        from FAL_LOT_MATERIAL_LINK
       where FAL_LOT_ID = aFalLotId;

      if ComponentsCount = 0 then
        -- Création d'une ligne "Sans composant"
        CreateComponent(aFalLotId                => aFalLotId
                      , aLotTotalQty             => 0
                      , aLotInprodQty            => 0
                      , aCmaLotQuantity          => 0
                      , aCmaFixDelay             => 0
                      , aGcoGoodId               => null
                      , aUtilCoeff               => 0
                      , aComUtilCoef             => 0
                      , aNomRefQty               => 0
                      , aNomOriginRefQty         => 0
                      , aComInterval             => 0
                      , aCKindCom                => '1'
                      , aCTypeCom                => '3'
                      , aComPercentWaste         => 0
                      , aComFixedQuantityWaste   => 0
                      , aComQtyReferenceLoss     => 0
                      , aNomLocationId           => null
                      , aNomStockId              => null
                      , aLocationId              => null
                      , aStockId                 => null
                      , aProductLocationId       => null
                      , aProductStockId          => null
                      , aComSubstitut            => 0
                      , aCDischargeCom           => '2'
                      , aComMarkTopo             => null
                      , aComText                 => null
                      , aComIncreaseCost         => 1
                      , aComPos                  => null
                      , aComResNum               => null
                      , aComResText              => null
                      , aScsStepNumberOrigin     => null
                      , aScsStepNumber           => null
                      , aNoComponent             => 1
                      , aComWeighing             => 0
                      , aComWeighingMandatory    => 0
                       );
      end if;
    end if;
  end;

  /* Description
  *   Génération des composants d'un lot de fabrication
  */
  procedure GenerateComponents(
    iFalLotId          in FAL_LOT.FAL_LOT_ID%type
  , iPpsNomenclatureId in FAL_LOT.PPS_NOMENCLATURE_ID%type
  , iDicFabConditionId in FAL_LOT.DIC_FAB_CONDITION_ID%type
  , iStockId           in FAL_LOT.STM_STM_STOCK_ID%type
  , iLocationId        in FAL_LOT.STM_STM_LOCATION_ID%type
  )
  is
    cursor crBatch
    is
      select FL.LOT_PLAN_BEGIN_DTE
           , FL.LOT_TOTAL_QTY
           , FL.LOT_INPROD_QTY
           , FL.GCO_GOOD_ID
           , nvl(CMA.CMA_FIX_DELAY, 0) CMA_FIX_DELAY
           , nvl(CMA.CMA_LOT_QUANTITY, 0) CMA_LOT_QUANTITY
           , nvl(C_FAB_TYPE, '0') C_FAB_TYPE
        from FAL_LOT FL
           , GCO_COMPL_DATA_MANUFACTURE CMA
       where FAL_LOT_ID = iFalLotId
         and FL.GCO_GOOD_ID = CMA.GCO_GOOD_ID(+)
         and CMA.DIC_FAB_CONDITION_ID = iDicFabConditionId;

    tplBatch crBatch%rowtype;
  begin
    open crBatch;

    fetch crBatch
     into tplBatch;

    close crBatch;

    GenerateComponents(aFalLotId              => iFalLotId
                     , aGcoGoodId             => tplBatch.GCO_GOOD_ID
                     , aPpsNomenclatureId     => iPpsNomenclatureId
                     , aListOfPropositionId   => null
                     , aLotTotalQty           => tplBatch.LOT_TOTAL_QTY
                     , aStockId               => iStockId
                     , aLocationId            => iLocationId
                     , aLotBeginDate          => tplBatch.LOT_PLAN_BEGIN_DTE
                     , aLotInprodQty          => tplBatch.LOT_INPROD_QTY
                     , aCmaFixDelay           => tplBatch.CMA_FIX_DELAY
                     , aCmaLotQuantity        => tplBatch.CMA_LOT_QUANTITY
                     , iCFabType              => tplBatch.C_FAB_TYPE
                     , iC_DISCHARGE_COM       => null
                      );
  end;

  procedure GenerateComponents(
    aFalLotId            FAL_LOT.FAL_LOT_ID%type
  , aListOfPropositionId varchar2 default null
  , aC_DISCHARGE_COM     GCO_COMPL_DATA_SUBCONTRACT.C_DISCHARGE_COM%type default null
  )
  is
    cursor crBatch
    is
      select FL.LOT_PLAN_BEGIN_DTE
           , FL.LOT_TOTAL_QTY
           , FL.LOT_INPROD_QTY
           , FL.STM_STM_STOCK_ID
           , FL.STM_STM_LOCATION_ID
           , FL.GCO_GOOD_ID
           , FL.PPS_NOMENCLATURE_ID
           , nvl(CMA.CMA_FIX_DELAY, 0) CMA_FIX_DELAY
           , nvl(CMA.CMA_LOT_QUANTITY, 0) CMA_LOT_QUANTITY
           , nvl(C_FAB_TYPE, '0') C_FAB_TYPE
        from FAL_LOT FL
           , GCO_COMPL_DATA_MANUFACTURE CMA
       where FAL_LOT_ID = aFalLotId
         and FL.GCO_GOOD_ID = CMA.GCO_GOOD_ID(+)
         and FL.DIC_FAB_CONDITION_ID = CMA.DIC_FAB_CONDITION_ID(+);

    tplBatch crBatch%rowtype;
  begin
    open crBatch;

    fetch crBatch
     into tplBatch;

    close crBatch;

    GenerateComponents(aFalLotId              => aFalLotId
                     , aGcoGoodId             => tplBatch.GCO_GOOD_ID
                     , aPpsNomenclatureId     => tplBatch.PPS_NOMENCLATURE_ID
                     , aListOfPropositionId   => aListOfPropositionId
                     , aLotTotalQty           => tplBatch.LOT_TOTAL_QTY
                     , aStockId               => tplBatch.STM_STM_STOCK_ID
                     , aLocationId            => tplBatch.STM_STM_LOCATION_ID
                     , aLotBeginDate          => tplBatch.LOT_PLAN_BEGIN_DTE
                     , aLotInprodQty          => tplBatch.LOT_INPROD_QTY
                     , aCmaFixDelay           => tplBatch.CMA_FIX_DELAY
                     , aCmaLotQuantity        => tplBatch.CMA_LOT_QUANTITY
                     , iCFabType              => tplBatch.C_FAB_TYPE
                     , iC_DISCHARGE_COM       => aC_DISCHARGE_COM
                      );
  end;

  /***
  * Fonction : ComponentsRegenerationForOneLot
  *
  * Description : Regénération des composants pour un lot de fabrication donné
  */
  procedure CompRegenerationForOneLot(
    aFAL_LOT_ID          in     FAL_LOT.FAL_LOT_ID%type
  , aPPS_NOMENCLATURE_ID in     PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  , aErrorMsg            in out varchar2
  )
  is
    aSTM_STM_STOCK_ID    FAL_LOT.STM_STM_STOCK_ID%type;
    aSTM_STM_LOCATION_ID FAL_LOT.STM_STM_LOCATION_ID%type;
    aLOT_PLAN_END_DTE    FAL_LOT.LOT_PLAN_END_DTE%type;
  begin
    aErrorMsg  := '';
    -- Suppression Attribution Besoin Stock + Besoin appro + Suppression du need correspondant.
    FAL_NETWORK.ReseauBesoinFAL_SupprAll(aFAL_LOT_ID);

    -- Suppression des composants existants
    delete from FAL_LOT_MATERIAL_LINK
          where FAL_LOT_ID = aFAL_LOT_ID;

    -- Récupération informations sur le lot à modifier
    select STM_STM_STOCK_ID
         , STM_STM_LOCATION_ID
         , LOT_PLAN_END_DTE
      into aSTM_STM_STOCK_ID
         , aSTM_STM_LOCATION_ID
         , aLOT_PLAN_END_DTE
      from FAL_LOT
     where FAL_LOT_ID = aFAL_LOT_ID;

    -- Changement du Flag Composants modifiés manuellements
    update FAL_LOT
       set LOT_UPDATED_COMPONENTS = 0
     where FAL_LOT_ID = aFAL_LOT_ID;

    -- Re-génération des composants
    GenerateComponents(aFAL_LOT_ID);
    -- Planification des composants
    FAL_PLANIF.MAJ_LiensComposantsLot(aFAL_LOT_ID, aLOT_PLAN_END_DTE);
    -- Re-génération des réseaux.
    FAL_NETWORK.ReseauBesoinFAL_SupprOld(aFAL_LOT_ID);
    FAL_NETWORK.ReseauBesoinFAL_MAJ(aFAL_LOT_ID, aSTM_STM_STOCK_ID, aSTM_STM_LOCATION_ID, 1, 1);
    FAL_NETWORK.ReseauBesoinFAL_Creation(aFAL_LOT_ID, aSTM_STM_STOCK_ID, aSTM_STM_LOCATION_ID);
  exception
    when others then
      aErrorMsg  := sqlcode || ' - ' || sqlerrm;
  end CompRegenerationForOneLot;

  /**
  * procedure UpdateComponentsOnUpdateBatch
  * Description
  *   Mise à jour des composants d'un lot après modification du lot
  * @author CLE
  * @param   aFalLotId          Id du lot
  * @param PreviousLotTotalQty  Qté totale du lot avant la modification du lot
  * @lastUpdate
  * @public
  */
  procedure UpdateComponentsOnUpdateBatch(aFalLotId FAL_LOT.FAL_LOT_ID%type, PreviousLotTotalQty FAL_LOT.LOT_TOTAL_QTY%type)
  is
    cursor crComponents
    is
      select     FAL_LOT_MATERIAL_LINK_ID
               , nvl(FLML.LOM_INTERVAL, 0) LOM_INTERVAL
               , FLML.LOM_NEED_DATE
               , nvl(FLML.LOM_MAX_RECEIPT_QTY, 0) LOM_MAX_RECEIPT_QTY
               , nvl(FLML.LOM_CONSUMPTION_QTY, 0) LOM_CONSUMPTION_QTY
               , FLML.C_TYPE_COM
               , FLML.C_KIND_COM
               , FLML.LOM_FULL_REQ_QTY
               , FLML.LOM_STOCK_MANAGEMENT
               , nvl(FLML.LOM_UTIL_COEF, 0) LOM_UTIL_COEF
               , nvl(FLML.LOM_ADJUSTED_QTY, 0) LOM_ADJUSTED_QTY
               , nvl(FLML.LOM_ADJUSTED_QTY_RECEIPT, 0) LOM_ADJUSTED_QTY_RECEIPT
               , nvl(FLML.LOM_REJECTED_QTY, 0) LOM_REJECTED_QTY
               , nvl(FLML.LOM_BACK_QTY, 0) LOM_BACK_QTY
               , nvl(FLML.LOM_PT_REJECT_QTY, 0) LOM_PT_REJECT_QTY
               , nvl(FLML.LOM_CPT_TRASH_QTY, 0) LOM_CPT_TRASH_QTY
               , nvl(FLML.LOM_CPT_RECOVER_QTY, 0) LOM_CPT_RECOVER_QTY
               , nvl(FLML.LOM_CPT_REJECT_QTY, 0) LOM_CPT_REJECT_QTY
               , nvl(FLML.LOM_EXIT_RECEIPT, 0) LOM_EXIT_RECEIPT
               , nvl(FLML.LOM_REF_QTY, 0) LOM_REF_QTY
               , FLML.GCO_GOOD_ID
               , FL.C_LOT_STATUS
               , FL.LOT_TOTAL_QTY
               , FL.C_SCHEDULE_PLANNING
               , FL.FAL_SCHEDULE_PLAN_ID
               , FL.FAL_FAL_SCHEDULE_PLAN_ID
               , FL.LOT_PLAN_BEGIN_DTE
               , FL.LOT_PLAN_END_DTE
               , FL.LOT_INPROD_QTY
               , FL.GCO_GOOD_ID LOT_GOOD_ID
               , (select nvl(CMA_FIX_DELAY, 0)
                    from GCO_COMPL_DATA_MANUFACTURE
                   where GCO_GOOD_ID = FL.GCO_GOOD_ID
                     and DIC_FAB_CONDITION_ID = FL.DIC_FAB_CONDITION_ID) CMA_FIX_DELAY
               , (select TAL_BEGIN_PLAN_DATE
                    from FAL_TASK_LINK
                   where FAL_LOT_ID = FL.FAL_LOT_ID
                     and SCS_STEP_NUMBER = FLML.LOM_TASK_SEQ) TAL_BEGIN_PLAN_DATE
            from FAL_LOT_MATERIAL_LINK FLML
               , FAL_LOT FL
           where FL.FAL_LOT_ID = FLML.FAL_LOT_ID
             and FL.FAL_LOT_ID = aFalLotId
      for update;

    newLOM_INTERVAL        FAL_LOT_MATERIAL_LINK.LOM_INTERVAL%type;
    newLOM_NEED_DATE       FAL_LOT_MATERIAL_LINK.LOM_NEED_DATE%type;
    newLOM_MAX_RECEIPT_QTY FAL_LOT_MATERIAL_LINK.LOM_MAX_RECEIPT_QTY%type;
    newLOM_CONSUMPTION_QTY FAL_LOT_MATERIAL_LINK.LOM_CONSUMPTION_QTY%type;
  begin
    for tplComponent in crComponents loop
      newLOM_INTERVAL         := tplComponent.LOM_INTERVAL;
      newLOM_NEED_DATE        := tplComponent.LOM_NEED_DATE;
      newLOM_MAX_RECEIPT_QTY  := tplComponent.LOM_MAX_RECEIPT_QTY;
      newLOM_CONSUMPTION_QTY  := tplComponent.LOM_CONSUMPTION_QTY;

      -- Si Texte, pseudo, fournit par le sous-traitant, ou dérivé
      if    (tplComponent.C_KIND_COM = '4')
         or (tplComponent.C_KIND_COM = '5')
         or (tplComponent.C_KIND_COM = '3')
         or (     (tplComponent.C_TYPE_COM = '1')
             and (tplComponent.C_KIND_COM = '2') ) then
        newLOM_INTERVAL         := 0;
        newLOM_NEED_DATE        := null;
        newLOM_MAX_RECEIPT_QTY  := 0;
      end if;

      if     (tplComponent.C_TYPE_COM = '1')
         and (tplComponent.C_KIND_COM = '1') then
        -- Calcul du décalage
        if tplComponent.CMA_FIX_DELAY = 0 then
          if nvl(PreviousLotTotalQty, 0) = 0 then
            newLOM_INTERVAL  :=(tplComponent.LOT_TOTAL_QTY * newLOM_INTERVAL);
          else
            newLOM_INTERVAL  := (tplComponent.LOT_TOTAL_QTY * newLOM_INTERVAL) / PreviousLotTotalQty;
          end if;
        end if;

        -- Calcul de la date besoin
        -- Plannification selon Produit ou gamme absente
        if    (tplComponent.C_SCHEDULE_PLANNING = '1')
           or tplComponent.FAL_SCHEDULE_PLAN_ID is null then
          if nvl(newLOM_INTERVAL, 0) = 0 then
            newLOM_NEED_DATE  := tplComponent.LOT_PLAN_BEGIN_DTE;
          else
            FAL_PLANIF.GetCalendarDateFromInterval(Decalage       => newLOM_INTERVAL
                                                 , PrmStartDate   => tplComponent.LOT_PLAN_BEGIN_DTE
                                                 , EndDate        => tplComponent.LOT_PLAN_END_DTE
                                                 , ResultDate     => newLOM_NEED_DATE
                                                  );
          end if;
        -- Plannification selon Opérations et gamme présente
        else
          newLOM_NEED_DATE  := nvl(tplComponent.TAL_BEGIN_PLAN_DATE, tplComponent.LOT_PLAN_BEGIN_DTE);
        end if;

        -- Calcul de la Quantité Max Réceptionnable
        newLOM_MAX_RECEIPT_QTY  :=
          FAL_COMPONENT_FUNCTIONS.getMaxReceptQty(aGCO_GOOD_ID                => tplComponent.LOT_GOOD_ID
                                                , aLOT_INPROD_QTY             => tplComponent.LOT_INPROD_QTY
                                                , aLOM_ADJUSTED_QTY           => tplComponent.LOM_ADJUSTED_QTY
                                                , aLOM_CONSUMPTION_QTY        => tplComponent.LOM_CONSUMPTION_QTY
                                                , aLOM_REF_QTY                => tplComponent.LOM_REF_QTY
                                                , aLOM_UTIL_COEF              => tplComponent.LOM_UTIL_COEF
                                                , aLOM_ADJUSTED_QTY_RECEIPT   => tplComponent.LOM_ADJUSTED_QTY_RECEIPT
                                                , aLOM_BACK_QTY               => tplComponent.LOM_BACK_QTY
                                                , aLOM_CPT_RECOVER_QTY        => tplComponent.LOM_CPT_RECOVER_QTY
                                                , aLOM_CPT_REJECT_QTY         => tplComponent.LOM_CPT_REJECT_QTY
                                                , aLOM_CPT_TRASH_QTY          => tplComponent.LOM_CPT_TRASH_QTY
                                                , aLOM_EXIT_RECEIPT           => tplComponent.LOM_EXIT_RECEIPT
                                                , aLOM_PT_REJECT_QTY          => tplComponent.LOM_PT_REJECT_QTY
                                                , aLOM_REJECTED_QTY           => tplComponent.LOM_REJECTED_QTY
                                                , aLOM_STOCK_MANAGEMENT       => tplComponent.LOM_STOCK_MANAGEMENT
                                                 );
      end if;

      if     (tplComponent.LOM_STOCK_MANAGEMENT <> 1)
         and (tplComponent.C_LOT_STATUS = '2') then
        newLOM_CONSUMPTION_QTY  := tplComponent.LOM_FULL_REQ_QTY;
      end if;

      update FAL_LOT_MATERIAL_LINK
         set LOM_INTERVAL = newLOM_INTERVAL
           , LOM_NEED_DATE = newLOM_NEED_DATE
           , LOM_MAX_RECEIPT_QTY = newLOM_MAX_RECEIPT_QTY
           , LOM_CONSUMPTION_QTY = newLOM_CONSUMPTION_QTY
       where FAL_LOT_MATERIAL_LINK_ID = tplComponent.FAL_LOT_MATERIAL_LINK_ID;
    end loop;
  end;

  /**
  * procedure DeleteLomTaskSeqLinks
  * Description
  *   Suppression des liens opération/composant
  * @author JCH
  * @created 06.10.2008
  * @lastUpdate
  * @public
  * @param aFalLotId       : Id du lot
  * @param aDeleteAllLinks : Indique si l'on doit supprimer tous les liens avec
  *                          les opérations ou seulement ceux dont l'opération
  *                          n'existe plus.
  */
  procedure DeleteLomTaskSeqLinks(aFalLotId in FAL_LOT.FAL_LOT_ID%type, aDeleteAllLinks in integer default 0)
  is
    cDischargeCom constant varchar2(1) := PCS.PC_CONFIG.GetConfig('PPS_DISCHARGE_COM');
  begin
    -- Les séquences opérations des composants sont mis à null pour supprimer le lien
    -- Si le code décharge est un code lié au lien opération, il est mis à jour
    -- selon la config PPS_DISCHARGE_COM pour autant que la valeur de la config
    -- ne soit pas un code lié au lien opération.
    update FAL_LOT_MATERIAL_LINK LOM
       set LOM.LOM_TASK_SEQ = null
         , LOM.C_DISCHARGE_COM =
                         case
                           when LOM.C_DISCHARGE_COM in('3', '4', '5') then case
                                                                            when cDischargeCom in('3', '4', '5') then '2'
                                                                            else cDischargeCom
                                                                          end
                           else LOM.C_DISCHARGE_COM
                         end
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where LOM.LOM_TASK_SEQ is not null
       and (   aDeleteAllLinks = 1
            or LOM.LOM_TASK_SEQ not in(select TAL.SCS_STEP_NUMBER
                                         from FAL_TASK_LINK TAL
                                        where TAL.FAL_LOT_ID = LOM.FAL_LOT_ID) )
       and LOM.FAL_LOT_ID = aFalLotId;
  end DeleteLomTaskSeqLinks;

   /**
   * procedure UpdateComptsOnSchedPlanChange
   * Description
   *   Mise à jour des composants d'un lot après changement de la gamme
   *   (suppression des liens opération/composant)
  */
  procedure UpdateComptsOnSchedPlanChange(aFalLotId FAL_LOT.FAL_LOT_ID%type)
  is
  begin
    -- Toutes les liens opération/composant sont supprimés
    DeleteLomTaskSeqLinks(aFalLotId => aFalLotId, aDeleteAllLinks => 1);
  end UpdateComptsOnSchedPlanChange;

  /**
   * procedure UpdateComptsAfterDelTaskLink
   * Description
   *   Mise à jour des composants d'un lot après changement de la gamme
   *   (suppression des liens opération/composant)
   */
  procedure UpdateComptsAfterDelTaskLink(aFalLotId FAL_LOT.FAL_LOT_ID%type)
  is
  begin
    -- Les liens opération/composant dont l'opération correspondante n'existe
    -- plus sont supprimés.
    DeleteLomTaskSeqLinks(aFalLotId => aFalLotId, aDeleteAllLinks => 0);
  end UpdateComptsAfterDelTaskLink;

  /**
  * procedure UpdateBatchComponentsOnError
  * Description
  *   Mise à jour des composants sur erreur à l'insertion d'un nouveau lot
  * @author CLE
  * @param   aFalLotId   Id du lot
  * @lastUpdate
  * @public
  */
  procedure UpdateBatchComponentsOnError(aFalLotId FAL_LOT.FAL_LOT_ID%type)
  is
    cursor crComponents
    is
      select     FAL_LOT_MATERIAL_LINK_ID
               , LOM_NEED_QTY
               , nvl(LOM_CONSUMPTION_QTY, 0) LOM_CONSUMPTION_QTY
               , C_TYPE_COM
               , C_KIND_COM
               , nvl(LOM_FULL_REQ_QTY, 0) LOM_FULL_REQ_QTY
               , LOM_STOCK_MANAGEMENT
               , nvl(LOM_ADJUSTED_QTY, 0) LOM_ADJUSTED_QTY
               , nvl(LOM_REJECTED_QTY, 0) LOM_REJECTED_QTY
               , nvl(LOM_BACK_QTY, 0) LOM_BACK_QTY
            from FAL_LOT_MATERIAL_LINK
           where FAL_LOT_ID = aFalLotId
      for update;

    newLOM_NEED_QTY FAL_LOT_MATERIAL_LINK.LOM_NEED_QTY%type;
  begin
    for tplComponent in crComponents loop
      newLOM_NEED_QTY  := tplComponent.LOM_NEED_QTY;

      -- Si Texte fournit par le sous traitant, pseudo, ou dérivé Actif
      if    (tplComponent.C_KIND_COM = '4')
         or (tplComponent.C_KIND_COM = '5')
         or (tplComponent.C_KIND_COM = '3')
         or (     (tplComponent.C_TYPE_COM = '1')
             and (tplComponent.C_KIND_COM = '2') )
         or (tplComponent.LOM_STOCK_MANAGEMENT <> 1) then
        newLOM_NEED_QTY  := 0;
      elsif     (tplComponent.C_TYPE_COM = '1')
            and (tplComponent.C_KIND_COM = '1') then
        if tplComponent.LOM_ADJUSTED_QTY < 0 then
          newLOM_NEED_QTY  := tplComponent.LOM_FULL_REQ_QTY + tplComponent.LOM_REJECTED_QTY + tplComponent.LOM_BACK_QTY - tplComponent.LOM_CONSUMPTION_QTY;
        else
          newLOM_NEED_QTY  :=
            tplComponent.LOM_FULL_REQ_QTY +
            greatest(tplComponent.LOM_REJECTED_QTY - tplComponent.LOM_ADJUSTED_QTY, 0) +
            tplComponent.LOM_BACK_QTY -
            tplComponent.LOM_CONSUMPTION_QTY;
        end if;
      end if;

      update FAL_LOT_MATERIAL_LINK
         set LOM_CONSUMPTION_QTY = 0
           , LOM_MAX_RECEIPT_QTY = 0
           , LOM_NEED_QTY = newLOM_NEED_QTY
       where FAL_LOT_MATERIAL_LINK_ID = tplComponent.FAL_LOT_MATERIAL_LINK_ID;
    end loop;
  end;

/**
  * procedure UpdateBatchComponents
  * Description
  *   Mise à jour des composants sur modification qté du lot
  * @author CLE
  * @param   aFalLotId               Id du lot
  * @param   aFalLotMaterialLinkId   Id du composant à mettre à jour (tous les composants si null)
  * @param   aNewLotTotalQty         Quantité totale du lot
  * @param   UpdateBatchAssembly     Mise à jour d'un lot d'assemblage ou non
  * @lastUpdate
  * @public
  */
  procedure UpdateBatchComponents(
    aFalLotId             FAL_LOT.FAL_LOT_ID%type default null
  , aFalLotMaterialLinkId FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type default null
  , aNewLotTotalQty       FAL_LOT.LOT_TOTAL_QTY%type
  , UpdateBatchAssembly   integer default 0
  )
  is
    cursor crComponents
    is
      select     LOM_NEED_QTY
               , LOM_FULL_REQ_QTY
               , LOM_ADJUSTED_QTY
               , LOM_AVAILABLE_QTY
               , C_KIND_COM
               , LOM_STOCK_MANAGEMENT
               , FLML.GCO_GOOD_ID
               , nvl(LOM_REJECTED_QTY, 0) LOM_REJECTED_QTY
               , nvl(LOM_BACK_QTY, 0) LOM_BACK_QTY
               , nvl(LOM_CONSUMPTION_QTY, 0) LOM_CONSUMPTION_QTY
               , nvl(LOM_UTIL_COEF, 0) LOM_UTIL_COEF
               , nvl(LOM_REF_QTY, 1) LOM_REF_QTY
               , FL.C_LOT_STATUS
               , FL.PPS_NOMENCLATURE_ID
               , FAL_LOT_MATERIAL_LINK_ID
               , LOM_QTY_REFERENCE_LOSS
               , LOM_FIXED_QUANTITY_WASTE
               , LOM_PERCENT_WASTE
            from FAL_LOT_MATERIAL_LINK FLML
               , FAL_LOT FL
           where FL.FAL_LOT_ID = FLML.FAL_LOT_ID
             and (    (    aFalLotMaterialLinkId is null
                       and FL.FAL_LOT_ID = aFalLotId)
                  or (FAL_LOT_MATERIAL_LINK_ID = aFalLotMaterialLinkId) )
             and FLML.C_TYPE_COM = '1'
      for update;

    newLOM_BOM_REQ_QTY   FAL_LOT_MATERIAL_LINK.LOM_BOM_REQ_QTY%type;
    newLOM_ADJUSTED_QTY  FAL_LOT_MATERIAL_LINK.LOM_ADJUSTED_QTY%type;
    newLOM_FULL_REQ_QTY  FAL_LOT_MATERIAL_LINK.LOM_FULL_REQ_QTY%type;
    newLOM_AVAILABLE_QTY FAL_LOT_MATERIAL_LINK.LOM_AVAILABLE_QTY%type;
    newLOM_NEED_QTY      FAL_LOT_MATERIAL_LINK.LOM_NEED_QTY%type;
    PercentWaste         GCO_GOOD.GOO_STD_PERCENT_WASTE%type;
    QtyRefLoss           GCo_GOOD.GOO_STD_QTY_REFERENCE_LOSS%type;
    FixedQtyWaste        GCO_GOOD.GOO_STD_FIXED_QUANTITY_WASTE%type;
  begin
    for tplComponent in crComponents loop
      newLOM_ADJUSTED_QTY   := tplComponent.LOM_ADJUSTED_QTY;
      newLOM_AVAILABLE_QTY  := tplComponent.LOM_AVAILABLE_QTY;
      newLOM_NEED_QTY       := tplComponent.LOM_NEED_QTY;

      -- Qte besoin no
      if tplComponent.C_KIND_COM <> '3' then
        newLOM_BOM_REQ_QTY  := FAL_TOOLS.ArrondiSuperieur(aNewLotTotalQty * tplComponent.LOM_UTIL_COEF / tplComponent.LOM_REF_QTY, tplComponent.GCO_GOOD_ID);
      else
        newLOM_BOM_REQ_QTY  := 0;
      end if;

      if     tplComponent.LOM_STOCK_MANAGEMENT = 1
         and (   tplComponent.C_LOT_STATUS = '1'
              or UpdateBatchAssembly = 1) then
        /*
        FAL_PRECALC_TOOLS.GetWasteQtiesFromNomenclature(tplComponent.PPS_NOMENCLATURE_ID
                                                      , aFalLotId
                                                      , tplComponent.GCO_GOOD_ID
                                                      , PercentWaste
                                                      , QtyRefLoss
                                                      , FixedQtyWaste
                                                       );

        newLOM_ADJUSTED_QTY  := FAL_TOOLS.CalcTotalTrashQuantity(newLOM_BOM_REQ_QTY
          , 0
          , PercentWaste
          , FixedQtyWaste
          , QtyRefLoss);
        */
        newLOM_ADJUSTED_QTY  :=
          FAL_TOOLS.CalcTotalTrashQuantity(newLOM_BOM_REQ_QTY
                                         , 0
                                         , tplComponent.LOM_PERCENT_WASTE
                                         , tplComponent.LOM_FIXED_QUANTITY_WASTE
                                         , tplComponent.LOM_QTY_REFERENCE_LOSS
                                          );
        newLOM_ADJUSTED_QTY  := FAL_TOOLS.ArrondiSuperieur(newLOM_ADJUSTED_QTY, tplComponent.GCO_GOOD_ID);
      end if;

      -- Qte besoin total
      newLOM_FULL_REQ_QTY   := newLOM_BOM_REQ_QTY + newLOM_ADJUSTED_QTY;

      -- Qte dispo1
      if tplComponent.LOM_STOCK_MANAGEMENT <> 1 then
        newLOM_AVAILABLE_QTY  := newLOM_FULL_REQ_QTY;
      end if;

      -- Besoin CPT
      if     (tplComponent.C_KIND_COM = '1')
         and (tplComponent.LOM_STOCK_MANAGEMENT = 1) then
        if newLOM_ADJUSTED_QTY < 0 then
          newLOM_NEED_QTY  := newLOM_FULL_REQ_QTY + tplComponent.LOM_REJECTED_QTY + tplComponent.LOM_BACK_QTY - tplComponent.LOM_CONSUMPTION_QTY;
        else
          newLOM_NEED_QTY  :=
            newLOM_FULL_REQ_QTY + greatest(tplComponent.LOM_REJECTED_QTY - newLOM_ADJUSTED_QTY, 0) + tplComponent.LOM_BACK_QTY
            - tplComponent.LOM_CONSUMPTION_QTY;
        end if;
      end if;

      update FAL_LOT_MATERIAL_LINK
         set LOM_BOM_REQ_QTY = newLOM_BOM_REQ_QTY
           , LOM_ADJUSTED_QTY = newLOM_ADJUSTED_QTY
           , LOM_FULL_REQ_QTY = newLOM_FULL_REQ_QTY
           , LOM_AVAILABLE_QTY = newLOM_AVAILABLE_QTY
           , LOM_NEED_QTY = newLOM_NEED_QTY
       where FAL_LOT_MATERIAL_LINK_ID = tplComponent.FAL_LOT_MATERIAL_LINK_ID;
    end loop;
  end;

/**
  * procedure SetComponentGoodId
  * Description
  *   Mise à jour d'un composant de lot suite à la modification du good_id
  * @author CLE
  * @param   aGcoGoodId              Id du bien
  * @param   aFalLotMaterialLinkId   Id du composant à mettre à jour
  * @param   aNewLotTotalQty         Quantité totale du lot
  * @param   UpdateBatchAssembly     Mise à jour d'un lot d'assemblage ou non
  * @lastUpdate
  * @public
  */
  procedure SetComponentGoodId(
    aGcoGoodId            GCO_GOOD.GCO_GOOD_ID%type
  , aFalLotMaterialLinkId FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type
  , aLotTotalQty          FAL_LOT.LOT_TOTAL_QTY%type
  , UpdateBatchAssembly   integer default 0
  )
  is
    cursor cur_Good
    is
      select GOO.GOO_NUMBER_OF_DECIMAL
           , GOO.GOO_MAJOR_REFERENCE
           , GOO.GOO_SECONDARY_REFERENCE
           , nvl(nvl(DES_1.DES_SHORT_DESCRIPTION, DES_2.DES_SHORT_DESCRIPTION), nvl(DES_3.DES_SHORT_DESCRIPTION, DES_4.DES_SHORT_DESCRIPTION) )
                                                                                                                                          DES_SHORT_DESCRIPTION
           , nvl(nvl(DES_1.DES_LONG_DESCRIPTION, DES_2.DES_LONG_DESCRIPTION), nvl(DES_3.DES_LONG_DESCRIPTION, DES_4.DES_LONG_DESCRIPTION) )
                                                                                                                                           DES_LONG_DESCRIPTION
           , nvl(nvl(DES_1.DES_FREE_DESCRIPTION, DES_2.DES_FREE_DESCRIPTION), nvl(DES_3.DES_FREE_DESCRIPTION, DES_4.DES_FREE_DESCRIPTION) )
                                                                                                                                           DES_FREE_DESCRIPTION
           , PDT_STOCK_MANAGEMENT
           , STM_STOCK_ID
           , STM_LOCATION_ID
           , (select C_CHRONOLOGY_TYPE
                from GCO_CHARACTERIZATION
               where GCO_GOOD_ID = GOO.GCO_GOOD_ID
                 and C_CHARACT_TYPE = '5') C_CHRONOLOGY_TYPE
           , GCO_FUNCTIONS.GetCostPriceWithManagementMode(GOO.GCO_GOOD_ID) GOOD_PRICE
        from GCO_GOOD GOO
           , GCO_PRODUCT GP
           , GCO_DESCRIPTION DES_1
           , GCO_DESCRIPTION DES_2
           , GCO_DESCRIPTION DES_3
           , GCO_DESCRIPTION DES_4
       where GOO.GCO_GOOD_ID = aGcoGoodId
         and GOO.GCO_GOOD_ID = GP.GCO_GOOD_ID
         and DES_1.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
         and DES_1.C_DESCRIPTION_TYPE(+) = '05'
         and DES_1.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.GetUserLangId
         and DES_2.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
         and DES_2.C_DESCRIPTION_TYPE(+) = '01'
         and DES_2.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.GetUserLangId
         and DES_3.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
         and DES_3.C_DESCRIPTION_TYPE(+) = '05'
         and DES_3.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.GetCompLangId
         and DES_4.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
         and DES_4.C_DESCRIPTION_TYPE(+) = '01'
         and DES_4.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.GetCompLangId;

    curGood cur_Good%rowtype;
  begin
    if nvl(aGcoGoodId, 0) = 0 then
      update FAL_LOT_MATERIAL_LINK
         set LOM_SECONDARY_REF = null
           , LOM_SHORT_DESCR = null
           , LOM_LONG_DESCR = null
           , LOM_FREE_DECR = null
           , LOM_STOCK_MANAGEMENT = 0
           , LOM_UTIL_COEF = case C_KIND_COM
                              when '5' then 0
                              when '4' then 0
                              when '3' then 0
                              else 1
                            end
           , C_DISCHARGE_COM = 1
           , LOM_NEED_QTY = 0
           , LOM_FULL_REQ_QTY = 0
           , LOM_ADJUSTED_QTY = 0
           , STM_STOCK_ID = null
           , STM_LOCATION_ID = null
           , LOM_AVAILABLE_QTY = 0
           , LOM_MISSING = 0
           , C_CHRONOLOGY_TYPE = 0
           , LOM_PRICE = 0
       where FAL_LOT_MATERIAL_LINK_ID = aFalLotMaterialLinkId;
    else
      open cur_Good;

      fetch cur_Good
       into curGood;

      if cur_Good%found then
        update FAL_LOT_MATERIAL_LINK
           set LOM_SECONDARY_REF = curGood.GOO_SECONDARY_REFERENCE
             , LOM_SHORT_DESCR = curGood.DES_SHORT_DESCRIPTION
             , LOM_LONG_DESCR = curGood.DES_LONG_DESCRIPTION
             , LOM_FREE_DECR = curGood.DES_FREE_DESCRIPTION
             , LOM_STOCK_MANAGEMENT = curGood.PDT_STOCK_MANAGEMENT
             , C_CHRONOLOGY_TYPE = curGood.C_CHRONOLOGY_TYPE
             , LOM_ADJUSTED_QTY = 0
             , LOM_PRICE = curGood.GOOD_PRICE
             , STM_STOCK_ID = curGood.STM_STOCK_ID
             , STM_LOCATION_ID = curGood.STM_LOCATION_ID
             , LOM_UTIL_COEF = round(LOM_UTIL_COEF, curGood.GOO_NUMBER_OF_DECIMAL)
         where FAL_LOT_MATERIAL_LINK_ID = aFalLotMaterialLinkId;

        UpdateBatchComponents(aFalLotMaterialLinkId => aFalLotMaterialLinkId, aNewLotTotalQty => aLotTotalQty, UpdateBatchAssembly => UpdateBatchAssembly);
      end if;

      close cur_Good;
    end if;
  end;
end;
