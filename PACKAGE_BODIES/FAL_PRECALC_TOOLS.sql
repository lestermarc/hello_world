--------------------------------------------------------
--  DDL for Package Body FAL_PRECALC_TOOLS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRECALC_TOOLS" 
is
  /**
  * procedure GetStockAndLocation
  * Description: Procédure de recherche en cascade des stock et emplacement des composants
  *
  * @author  ECA
  * @version 30.01.08
  * @private
  *
  * @param   aPdtStockManagement : Gestion de stock
  * @param   aNomStockId : Stock Composants de nomenclature
  * @param   aNomLocationId : Emplacement Composants de nomenclature
  * @param   aProductStockId  : Stock du bien
  * @param   aProductLocationId : Emplacement du bien
  * @param   aBatchConsoStockId : Stock conso lot
  * @param   aBatchConsoLocationId : Emplacement de conso lot
  * @param   aResultStockId : Stock résultat
  * @param   aResultLocationId : Emplacement résultat
  */
  procedure GetStockAndLocation(
    aPdtStockManagement   in     integer
  , aNomStockId           in     number
  , aNomLocationId        in     number
  , aProductStockId       in     number
  , aProductLocationId    in     number
  , aBatchConsoStockId    in     number
  , aBatchConsoLocationId in     number
  , aResultStockId        in out number
  , aResultLocationId     in out number
  )
  is
  begin
    if aPdtStockManagement = 1 then
      aResultStockId     := null;
      aResultLocationId  := null;

      if    (aNomLocationId is not null)
         or (aNomStockId is not null) then
        aResultStockId     := aNomStockId;
        aResultLocationId  := aNomLocationId;
      elsif    (aBatchConsoLocationId is not null)
            or (aBatchConsoStockId is not null) then
        aResultStockId     := aBatchConsoStockId;
        aResultLocationId  := aBatchConsoLocationId;
      elsif    (aProductLocationId is not null)
            or (aProductStockId is not null) then
        aResultStockId     := aProductStockId;
        aResultLocationId  := aProductLocationId;
      end if;

      if aResultStockId is null then
        aResultStockId  := FAL_TOOLS.GetConfig_StockID('GCO_DefltSTOCK');
      end if;

      if aResultLocationId is null then
        aResultLocationId  := FAL_TOOLS.GetMinClassifLocationOfStock(aResultStockId);
      end if;
    else
      aResultStockId     := FAL_TOOLS.GetDefaultStock;
      aResultLocationId  := null;
    end if;
  end GetStockAndLocation;

  /**
  * Procedure InsertPseudoCostElements
  * Description
  *   Génération des éléments de coûts matière pour les composants pseudo.
  *
  * @author  Emmanuel Cassis
  * @version 15.11.2004
  * @public
  *
  */
  procedure InsertPseudoCostElements(aFAL_ADV_CALC_GOOD_ID number, aSessionID varchar2, aPTC_FIXED_COSTPRICE_ID number)
  is
    cursor crPseudoGood
    is
      select   CAG.GCO_GOOD_ID
             , CAG.GCO_CPT_GOOD_ID
             , CAG.C_SUPPLY_MODE
             , CAG.C_MANAGEMENT_MODE
             , CAG.CAG_INCREASE_COST
             , CAG.CAG_PRECIOUS_MAT
             , CAG.CAG_MP_INCREASE_COST
             , CAG.CAG_REJECT_PERCENT
             , CAG.CAG_REJECT_FIX_QTY
             , CAG.CAG_REJECT_REF_QTY
             , CAG.CAG_SCRAP_PERCENT
             , CAG.CAG_SCRAP_FIX_QTY
             , CAG.CAG_SCRAP_REF_QTY
             , CAG.CAG_NOM_COEF
             , CAG.CAG_NOM_REF_QTY
             , CAG.CAG_STANDARD_QTY
             , CAG.CAG_QUANTITY
             , CAG.CAG_PRICE
             , CAG.FAL_ADV_CALC_GOOD_ID
             , CAG.C_KIND_COM
             , CAG.CAG_SEQ
             , CAG.STM_STOCK_ID
             , CAG.STM_LOCATION_ID
          from FAL_ADV_CALC_GOOD CAG
         where CAG.CAG_SESSION_ID = aSessionID
           and CAG.FAL_PARENT_ADV_CALC_GOOD_ID = aFAL_ADV_CALC_GOOD_ID
           and CAG.GCO_CPT_GOOD_ID is not null
      order by CAG.CAG_SEQ;

    vC_SUPPLY_MODE         varchar2(10);
    vC_MANAGEMENT_MODE     varchar2(10);
    aPTC_USED_COMPONENT_ID number;
    aPDT_STOCK_ID          number;
    aPDT_LOCATION_ID       number;
    aNewID                 number;
    nPUC_SEQ               integer;
    nPDT_STOCK_MANAGEMENT  integer;
    aCOMPO_STOCK_ID        number;
    aCOMPO_LOCATION_ID     number;
  begin
    for tplPseudoGood in crPseudoGood loop
      -- Insertion du composant
      if    tplPseudoGood.C_SUPPLY_MODE is null
         or tplPseudoGood.C_MANAGEMENT_MODE is null then
        begin
          select PDT.C_SUPPLY_MODE
               , GCO.C_MANAGEMENT_MODE
               , nvl(PDT.PDT_STOCK_MANAGEMENT, 0)
               , PDT.STM_STOCK_ID
               , PDT.STM_LOCATION_ID
            into vC_SUPPLY_MODE
               , vC_MANAGEMENT_MODE
               , nPDT_STOCK_MANAGEMENT
               , aPDT_STOCK_ID
               , aPDT_LOCATION_ID
            from GCO_GOOD GCO
               , GCO_PRODUCT PDT
           where GCO.GCO_GOOD_ID = tplPseudoGood.GCO_CPT_GOOD_ID
             and GCO.GCO_GOOD_ID = PDT.GCO_GOOD_ID;
        exception
          when others then
            begin
              vC_SUPPLY_MODE         := null;
              vC_MANAGEMENT_MODE     := null;
              nPDT_STOCK_MANAGEMENT  := null;
              aPDT_STOCK_ID          := null;
              aPDT_LOCATION_ID       := null;
            end;
        end;
      end if;

      -- Cascade de recherche des stocks
      GetStockAndLocation(aPdtStockManagement     => nPDT_STOCK_MANAGEMENT
                        , aNomStockId             => tplPseudoGood.STM_STOCK_ID
                        , aNomLocationId          => tplPseudoGood.STM_LOCATION_ID
                        , aProductStockId         => aPDT_STOCK_ID
                        , aProductLocationId      => aPDT_LOCATION_ID
                        , aBatchConsoStockId      => null
                        , aBatchConsoLocationId   => null
                        , aResultStockId          => aCOMPO_STOCK_ID
                        , aResultLocationId       => aCOMPO_LOCATION_ID
                         );

      -- Renumérotation identique à l'of
      select nvl(max(PUC_SEQ), 0) + PCS.PC_CONFIG.GetConfig('FAL_COMPONENT_NUMBERING')
        into nPUC_SEQ
        from PTC_USED_COMPONENT
       where PTC_FIXED_COSTPRICE_ID = aPTC_FIXED_COSTPRICE_ID;

      insert into PTC_USED_COMPONENT
                  (PTC_USED_COMPONENT_ID
                 , PTC_FIXED_COSTPRICE_ID
                 , GCO_GOOD_ID
                 , GCO_GCO_GOOD_ID
                 , C_SUPPLY_MODE
                 , C_MANAGEMENT_MODE
                 , PUC_INCREASE_COST
                 , PUC_PRECIOUS_MAT
                 , PUC_MP_INCREASE_COST
                 , PUC_REJECT_PERCENT
                 , PUC_REJECT_FIX_QTY
                 , PUC_REJECT_REF_QTY
                 , PUC_SCRAP_PERCENT
                 , PUC_SCRAP_FIX_QTY
                 , PUC_SCRAP_REF_QTY
                 , PUC_UTIL_COEFF
                 , PUC_NOM_REF_QTY
                 , PUC_STANDARD_QTY
                 , PUC_CALCUL_QTY
                 , PUC_PRICE
                 , C_KIND_COM
                 , PUC_NUMBER_OF_DECIMAL
                 , PUC_SEQ
                 , STM_STOCK_ID
                 , STM_LOCATION_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 , aPTC_FIXED_COSTPRICE_ID
                 , null
                 , tplPseudoGood.GCO_CPT_GOOD_ID
                 , nvl(tplPseudoGood.C_SUPPLY_MODE, vC_SUPPLY_MODE)
                 , nvl(tplPseudoGood.C_MANAGEMENT_MODE, vC_MANAGEMENT_MODE)
                 , tplPseudoGood.CAG_INCREASE_COST
                 , tplPseudoGood.CAG_PRECIOUS_MAT
                 , tplPseudoGood.CAG_MP_INCREASE_COST
                 , tplPseudoGood.CAG_REJECT_PERCENT
                 , tplPseudoGood.CAG_REJECT_FIX_QTY
                 , tplPseudoGood.CAG_REJECT_REF_QTY
                 , tplPseudoGood.CAG_SCRAP_PERCENT
                 , tplPseudoGood.CAG_SCRAP_FIX_QTY
                 , tplPseudoGood.CAG_SCRAP_REF_QTY
                 , tplPseudoGood.CAG_NOM_COEF
                 , tplPseudoGood.CAG_NOM_REF_QTY
                 , tplPseudoGood.CAG_STANDARD_QTY
                 , tplPseudoGood.CAG_QUANTITY
                 , tplPseudoGood.CAG_PRICE
                 , tplPseudoGood.C_KIND_COM
                 , FAL_TOOLS.GetGoo_Number_Of_Decimal(tplPseudoGood.GCO_CPT_GOOD_ID)
                 , nPUC_SEQ
                 , aCOMPO_STOCK_ID
                 , aCOMPO_LOCATION_ID
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GETUSERINI
                  )
        returning PTC_USED_COMPONENT_ID
             into aPTC_USED_COMPONENT_ID;

      -- Si composant non pseudo
      if tplPseudoGood.C_KIND_COM <> '3' then
        -- Insertion des éléments de couts de type Matière
        -- (Incluant le travail, dans le cas de composants étant fabriqué)
        aNewID  := GetNewId;

        insert into PTC_ELEMENT_COST
                    (PTC_ELEMENT_COST_ID
                   , PTC_FIXED_COSTPRICE_ID
                   , PTC_USED_COMPONENT_ID
                   , C_COST_ELEMENT_TYPE
                   , ELC_AMOUNT
                   , A_DATECRE
                   , A_IDCRE
                    )
          select   aNewID
                 , aPTC_FIXED_COSTPRICE_ID
                 , aPTC_USED_COMPONENT_ID
                 , 'MAT'
                 , sum(CAV_VALUE)
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GETUSERINI
              from FAL_ADV_CALC_STRUCT_VAL
             where C_COST_ELEMENT_TYPE in('MAT', 'TMA', 'TMO', 'SST')
               and FAL_ADV_CALC_GOOD_ID in(select     FAL_ADV_CALC_GOOD_ID
                                                 from FAL_ADV_CALC_GOOD CAV
                                                where GCO_CPT_GOOD_ID is not null
                                           start with FAL_ADV_CALC_GOOD_ID = tplPseudoGood.FAL_ADV_CALC_GOOD_ID
                                           connect by prior FAL_ADV_CALC_GOOD_ID = FAL_PARENT_ADV_CALC_GOOD_ID)
          group by aNewID
                 , aPTC_FIXED_COSTPRICE_ID
                 , aPTC_USED_COMPONENT_ID
                 , 'MAT'
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GETUSERINI;
      -- Si Composant pseudo, on descends sa nomenclature jusqu'au bout afin d'y intégrer ses propres composants, sous
      -- l'élément de coûts matière.
      else
        InsertPseudoCostElements(tplPseudoGood.FAL_ADV_CALC_GOOD_ID, aSessionID, aPTC_FIXED_COSTPRICE_ID);
      end if;
    end loop;
  end InsertPseudoCostElements;

  /**
  * Procedure GetProductionSection
  * Description
  *   Renvoie la valeur de la section d'un atelier (Regroiupement par section dans l'impression pré-calculation
  *
  * @author  Emmanuel Cassis
  * @version 15.11.2004
  * @public
  *
  */
  function GetProductionSection(aFAL_FACTORY_FLOOR_ID FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type)
    return varchar2
  is
    vSection                     varchar2(30);
    cfgFAL_PRECALC_PRINT_SECTION varchar2(50);
  begin
    cfgFAL_PRECALC_PRINT_SECTION  := PCS.PC_CONFIG.GetConfig('FAL_PRECALC_PRINT_SECTION');

    if aFAL_FACTORY_FLOOR_ID is null then
      vSection  := PCS.PC_FUNCTIONS.TranslateWord('Sous-traitance');
    else
      select decode(cfgFAL_PRECALC_PRINT_SECTION
                  , 'DIC_FLOOR_FREE_CODE_ID', FAC.DIC_FLOOR_FREE_CODE_ID
                  , 'DIC_FLOOR_FREE_CODE2_ID', FAC.DIC_FLOOR_FREE_CODE2_ID
                  , 'DIC_FLOOR_FREE_CODE3_ID', FAC.DIC_FLOOR_FREE_CODE3_ID
                  , 'DIC_FLOOR_FREE_CODE4_ID', FAC.DIC_FLOOR_FREE_CODE4_ID
                  , 'DIC_FLOOR_FREE_CODE5_ID', FAC.DIC_FLOOR_FREE_CODE5_ID
                  , 'DIC_FLOOR_FREE_CODE6_ID', FAC.DIC_FLOOR_FREE_CODE6_ID
                  , 'DIC_FLOOR_FREE_CODE7_ID', FAC.DIC_FLOOR_FREE_CODE7_ID
                  , 'DIC_FLOOR_FREE_CODE8_ID', FAC.DIC_FLOOR_FREE_CODE8_ID
                  , 'DIC_FLOOR_FREE_CODE9_ID', FAC.DIC_FLOOR_FREE_CODE9_ID
                  , 'DIC_FLOOR_FREE_CODE10_ID', FAC.DIC_FLOOR_FREE_CODE10_ID
                  , FAC.DIC_FLOOR_FREE_CODE_ID
                   ) A_SECTION
        into vSection
        from FAL_FACTORY_FLOOR FAC
       where FAC.FAL_FACTORY_FLOOR_ID = aFAL_FACTORY_FLOOR_ID;
    end if;

    return nvl(vSection, PCS.PC_FUNCTIONS.TranslateWord('Section non-définie!') );
  exception
    when no_data_found then
      return PCS.PC_FUNCTIONS.TranslateWord('Section non-définie!');
  end GetProductionSection;

  /**
  * Procedure GetUnderHeadingMatRate
  * Description
  *   Renvoie le taux par sous rubrique matière
  *
  * @author  Emmanuel Cassis
  * @version 16.07.2004
  * @public
  *
  */
  function GetUnderHeadingMatRate(aGCO_GOOD_ID GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    aDIC_MATERIAL_ID        varchar2(255);
    aDicoTableName          varchar2(50);
    aDicoIDFieldName        varchar2(50);
    aDicoWordingFieldName   varchar2(50);
    aOwningTable            varchar2(50);
    aOwningTableIDFieldName varchar2(50);
    BuffSQL                 varchar2(2000);
    Cursor_Handle           integer;
    Execute_Cursor          integer;
    nTSR_RATE               FAL_RATE_DIC_MAT.TSR_RATE%type;
  begin
    aDIC_MATERIAL_ID  := '';
    aDIC_MATERIAL_ID  := PCS.PC_CONFIG.GetConfig('PPS_DIC_MAT');

    -- Récupération valeur de la config
    if not(aDIC_MATERIAL_ID) is null then
      -- Vérification validité de la valeur de la config
      if aDIC_MATERIAL_ID = 'DIC_GOOD_LINE' then
        aDicoTableName           := 'DIC_GOOD_LINE';
        aDicoIDFieldName         := 'DIC_GOOD_LINE_ID';
        aDicoWordingFieldName    := 'DIC_GOOD_LINE_WORDING';
        aOwningTable             := 'GCO_GOOD';
        aOwningTableIDFieldName  := 'GCO_GOOD_ID';
      elsif aDIC_MATERIAL_ID = 'DIC_GOOD_FAMILY' then
        aDicoTableName           := 'DIC_GOOD_FAMILY';
        aDicoIDFieldName         := 'DIC_GOOD_FAMILY_ID';
        aDicoWordingFieldName    := 'DIC_GOOD_FAMILY_WORDING';
        aOwningTable             := 'GCO_GOOD';
        aOwningTableIDFieldName  := 'GCO_GOOD_ID';
      elsif aDIC_MATERIAL_ID = 'DIC_GOOD_MODEL' then
        aDicoTableName           := 'DIC_GOOD_MODEL';
        aDicoIDFieldName         := 'DIC_GOOD_MODEL_ID';
        aDicoWordingFieldName    := 'DIC_GOOD_MODEL_WORDING';
        aOwningTable             := 'GCO_GOOD';
        aOwningTableIDFieldName  := 'GCO_GOOD_ID';
      elsif aDIC_MATERIAL_ID = 'DIC_GOOD_GROUP' then
        aDicoTableName           := 'DIC_GOOD_GROUP';
        aDicoIDFieldName         := 'DIC_GOOD_GROUP_ID';
        aDicoWordingFieldName    := 'DIC_GOOD_GROUP_WORDING';
        aOwningTable             := 'GCO_GOOD';
        aOwningTableIDFieldName  := 'GCO_GOOD_ID';
      elsif aDIC_MATERIAL_ID = 'DIC_FREE_TABLE_1' then
        aDicoTableName           := 'DIC_FREE_TABLE_1';
        aDicoIDFieldName         := 'DIC_FREE_TABLE_1_ID';
        aDicoWordingFieldName    := 'DIC_FREE_TABLE_1_WORDING';
        aOwningTable             := 'GCO_FREE_DATA';
        aOwningTableIDFieldName  := 'GCO_GOOD_ID';
      elsif aDIC_MATERIAL_ID = 'DIC_FREE_TABLE_2' then
        aDicoTableName           := 'DIC_FREE_TABLE_2';
        aDicoIDFieldName         := 'DIC_FREE_TABLE_2_ID';
        aDicoWordingFieldName    := 'DIC_FREE_TABLE_2_WORDING';
        aOwningTable             := 'GCO_FREE_DATA';
        aOwningTableIDFieldName  := 'GCO_GOOD_ID';
      elsif aDIC_MATERIAL_ID = 'DIC_FREE_TABLE_3' then
        aDicoTableName           := 'DIC_FREE_TABLE_3';
        aDicoIDFieldName         := 'DIC_FREE_TABLE_3_ID';
        aDicoWordingFieldName    := 'DIC_FREE_TABLE_3_WORDING';
        aOwningTable             := 'GCO_FREE_DATA';
        aOwningTableIDFieldName  := 'GCO_GOOD_ID';
      elsif aDIC_MATERIAL_ID = 'DIC_FREE_TABLE_4' then
        aDicoTableName           := 'DIC_FREE_TABLE_4';
        aDicoIDFieldName         := 'DIC_FREE_TABLE_4_ID';
        aDicoWordingFieldName    := 'DIC_FREE_TABLE_4_WORDING';
        aOwningTable             := 'GCO_FREE_DATA';
        aOwningTableIDFieldName  := 'GCO_GOOD_ID';
      elsif aDIC_MATERIAL_ID = 'DIC_FREE_TABLE_5' then
        aDicoTableName           := 'DIC_FREE_TABLE_5';
        aDicoIDFieldName         := 'DIC_FREE_TABLE_5_ID';
        aDicoWordingFieldName    := 'DIC_FREE_TABLE_5_WORDING';
        aOwningTable             := 'GCO_FREE_DATA';
        aOwningTableIDFieldName  := 'GCO_GOOD_ID';
      end if;

      -- Recherche du taux
      begin
        BuffSQL         :=
          ' SELECT TSR.TSR_RATE           ' ||
          '   FROM FAL_RATE_DIC_MAT TSR,  ' ||
          aOwningTable ||
          ' OWN  ' ||
          '  WHERE OWN.' ||
          aOwningTableIDFieldName ||
          ' = ' ||
          aGCO_GOOD_ID ||
          '    AND OWN.' ||
          aDicoIDFieldName ||
          ' = TSR.TSR_PPS_DIC_WORK ';
        Cursor_Handle   := DBMS_SQL.open_cursor;
        DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.V7);
        DBMS_SQL.Define_column(Cursor_Handle, 1, nTSR_RATE);
        Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);

        loop
          if DBMS_SQL.fetch_rows(Cursor_Handle) > 0 then
            DBMS_SQL.column_value(Cursor_Handle, 1, nTSR_RATE);
          else
            exit;
          end if;
        end loop;

        DBMS_SQL.close_cursor(Cursor_Handle);
        return nTSR_RATE;
      exception
        when others then
          return 0;
      end;
    else
      return 0;
    end if;
  end GetUnderHeadingMatRate;

  /**
  * Procedure GetUnderHeadingWorkRate
  * Description
  *   Renvoie le taux par sous rubrique matière
  *
  * @author  Emmanuel Cassis
  * @version 16.07.2004
  * @public
  *
  */
  function GetUnderHeadingWorkRate(aFAL_SCHEDULE_STEP_ID FAL_LIST_STEP_LINK.FAL_SCHEDULE_STEP_ID%type)
    return number
  is
    aDIC_WORK_ID            varchar2(255);
    aDicoTableName          varchar2(50);
    aDicoIDFieldName        varchar2(50);
    aDicoWordingFieldName   varchar2(50);
    aOwningTable            varchar2(50);
    aOwningTableIDFieldName varchar2(50);
    BuffSQL                 varchar2(2000);
    Cursor_Handle           integer;
    Execute_Cursor          integer;
    nTXR_RATE               FAL_RATE_DIC_WORK.TXR_RATE%type;
  begin
    aDIC_WORK_ID  := '';
    aDIC_WORK_ID  := PCS.PC_CONFIG.GetConfig('PPS_DIC_WORK');

    -- Récupération valeur de la config
    if not(aDIC_WORK_ID) is null then
      if aDIC_WORK_ID = 'DIC_FREE_TASK_CODE' then
        aDicoTableName           := 'DIC_FREE_TASK_CODE';
        aDicoIDFieldName         := 'DIC_FREE_TASK_CODE_ID';
        aDicoWordingFieldName    := 'GT1_DESCRIBE';
        aOwningTable             := 'FAL_LIST_STEP_LINK';
        aOwningTableIDFieldName  := 'FAL_SCHEDULE_STEP_ID';
      elsif aDIC_WORK_ID = 'DIC_FREE_TASK_CODE2' then
        aDicoTableName           := 'DIC_FREE_TASK_CODE2';
        aDicoIDFieldName         := 'DIC_FREE_TASK_CODE2_ID';
        aDicoWordingFieldName    := 'GT2_DESCRIBE';
        aOwningTable             := 'FAL_LIST_STEP_LINK';
        aOwningTableIDFieldName  := 'FAL_SCHEDULE_STEP_ID';
      end if;

      -- Recherche du taux
      begin
        BuffSQL         :=
          ' SELECT TXR.TXR_RATE            ' ||
          '   FROM FAL_RATE_DIC_WORK TXR,  ' ||
          aOwningTable ||
          ' OWN   ' ||
          '  WHERE OWN.' ||
          aOwningTableIDFieldName ||
          ' = ' ||
          aFAL_SCHEDULE_STEP_ID ||
          '    AND OWN.' ||
          aDicoIDFieldName ||
          ' = TXR.TXR_PPS_DIC_WORK ';
        Cursor_Handle   := DBMS_SQL.open_cursor;
        DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.V7);
        DBMS_SQL.Define_column(Cursor_Handle, 1, nTXR_RATE);
        Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);

        loop
          if DBMS_SQL.fetch_rows(Cursor_Handle) > 0 then
            DBMS_SQL.column_value(Cursor_Handle, 1, nTXR_RATE);
          else
            exit;
          end if;
        end loop;

        DBMS_SQL.close_cursor(Cursor_Handle);
        return nTXR_RATE;
      exception
        when others then
          return 0;
      end;
    else
      return 0;
    end if;
  end GetUnderHeadingWorkRate;

  /**
  * procedure GetWasteQtiesFromNomenclature
  * Description
  *   Récupération des infos sur les déchets à partir de la nomenclature
  *
  * @author  DJE
  * @version
  * @public
  * @param   PrmPPS_NOMENCLATURE_ID : Nomenclature
  * @param   PrmFAL_LOT_ID          : Lot de fabrication
  * @param   PrmGCO_GOOD_ID         : Produit
  * @param   outPercentWaste        : %age déchet
  * @param   outQtyRefLoss          : Qté référence perte
  * @param   outFixedQtyWaste       : Qté fixe déchet
  */
  procedure GetWasteQtiesFromNomenclature(
    PrmPPS_NOMENCLATURE_ID     PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  , PrmFAL_LOT_ID              FAL_LOT.FAL_LOT_ID%type
  , PrmGCO_GOOD_ID             GCO_GOOD.GCO_GOOD_ID%type
  ,
    -- Valeurs retournées
    outPercentWaste        out GCO_GOOD.GOO_STD_PERCENT_WASTE%type
  , outQtyRefLoss          out GCo_GOOD.GOO_STD_QTY_REFERENCE_LOSS%type
  , outFixedQtyWaste       out GCO_GOOD.GOO_STD_FIXED_QUANTITY_WASTE%type
  )
  is
    aPPS_NOMENCLATURE_ID PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type;

    cursor C_PPS_NOM_BOND
    is
      select   COM_PERCENT_WASTE
             , COM_QTY_REFERENCE_LOSS
             , COM_FIXED_QUANTITY_WASTE
          from PPS_NOM_BOND
         where PPS_NOMENCLATURE_ID = aPPS_NOMENCLATURE_ID
           and GCO_GOOD_ID = PrmGCO_GOOD_ID
      order by COM_SEQ;

    -- Récupère l'ID de la nimenclature du lot donné
    function GetNomIDFromLot
      return PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
    is
      cursor C1
      is
        select PPS_NOMENCLATURE_ID
          from FAL_LOT
         where FAL_LOT_ID = PrmFAL_LOT_ID;

      aPPS_NOMENCLATURE_ID PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type;
    begin
      aPPS_NOMENCLATURE_ID  := null;

      open C1;

      fetch C1
       into aPPS_NOMENCLATURE_ID;

      close C1;

      return aPPS_NOMENCLATURE_ID;
    end;

    -- Récupère les valeurs recherchées depuis le produit
    procedure GetWasteQtiesFromGood
    is
      cursor C1
      is
        select GOO_STD_PERCENT_WASTE
             , GOO_STD_QTY_REFERENCE_LOSS
             , GOO_STD_FIXED_QUANTITY_WASTE
          from GCO_GOOD
         where GCO_GOOD_ID = PrmGCO_GOOD_ID;
    begin
      open C1;

      fetch C1
       into outPercentWaste
          , outQtyRefLoss
          , outFixedQtyWaste;

      close C1;
    end;
  begin
    -- Si l'ID de la nomenclature est renseigné
    if nvl(PrmPPS_NOMENCLATURE_ID, 0) <> 0 then
      aPPS_NOMENCLATURE_ID  := PrmPPS_NOMENCLATURE_ID;
    else
      -- Si l'ID du lot est renseigné
      if nvl(PrmFAL_LOT_ID, 0) <> 0 then
        aPPS_NOMENCLATURE_ID  := GetNomIDFromLot;
      else
        aPPS_NOMENCLATURE_ID  := null;
      end if;
    end if;

    -- Si l'ID de la nomenclature a été déterminé
    if nvl(aPPS_NOMENCLATURE_ID, 0) <> 0 then
      -- Récupération des données sur la nomenclature
      open C_PPS_NOM_BOND;

      fetch C_PPS_NOM_BOND
       into outPercentWaste
          , outQtyRefLoss
          , outFixedQtyWaste;

      if C_PPS_NOM_BOND%notfound then
        -- Si non trouvé alors récupération des données sur le bien
        GetWasteQtiesFromGood;
      end if;

      close C_PPS_NOM_BOND;
    else
      -- Récupération des données sur le bien
      GetWasteQtiesFromGood;
    end if;

    -- Dernières vérifications

    -- Note: Dans la version Delphi les valeurs étaient initiées avec 0
    --       NULL pourrait alors entrainer des éffets de bords
    outPercentWaste   := nvl(outPercentWaste, 0);
    outQtyRefLoss     := nvl(outQtyRefLoss, 0);
    outFixedQtyWaste  := nvl(outFixedQtyWaste, 0);
  -- Fin des vérifications
  end;

  /**
  * fonction GetQuotedPrice
  * Description
  *   Renvoie le cours d'une matière de base ou d'un alliage pour une unité
  *     La cascade de recherche est la suivante :
  *     Recherche par rapport Au code libre, puis Code donnée complémentaire, puis sans code.
  */
  function GetQuotedPrice(
    aGCO_ALLOY_ID              in     GCO_ALLOY.GCO_ALLOY_ID%type
  , aDIC_BASIS_MATERIAL_ID     in     DIC_BASIS_MATERIAL.DIC_BASIS_MATERIAL_ID%type
  , aGPR_START_VALIDITY        in     GCO_PRECIOUS_RATE_DATE.GPR_START_VALIDITY%type
  , aDIC_TYPE_RATE_ID          in     GCO_PRECIOUS_RATE.DIC_TYPE_RATE_ID%type
  , aFounded                   in out boolean
  , aDIC_FREE_CODE1_ID         in     DIC_FREE_CODE1.DIC_FREE_CODE1_ID%type default null
  , aDIC_COMPLEMENTARY_DATA_ID        DIC_COMPLEMENTARY_DATA.DIC_COMPLEMENTARY_DATA_ID%type default null
  )
    return number
  is
    cursor CUR_GCO_ALLOY_RATE
    is
      -- Sélection "Cours" et "Cours pour" de l'alliage.
      select nvl(GPR.GPR_RATE, 0) GPR_RATE
           , nvl(GPRD.GPR_BASE2_COST, 0) GPR_BASE2_COST
        from GCO_PRECIOUS_RATE GPR
           , GCO_PRECIOUS_RATE_DATE GPRD
       where GPR.GCO_PRECIOUS_RATE_DATE_ID = GPRD.GCO_PRECIOUS_RATE_DATE_ID
         and GPRD.GPR_TABLE_MODE = 0
         and GPR.DIC_TYPE_RATE_ID = aDIC_TYPE_RATE_ID
         and GPRD.GCO_ALLOY_ID = aGCO_ALLOY_ID
         and (    (    aDIC_FREE_CODE1_ID is null
                   and aDIC_COMPLEMENTARY_DATA_ID is null
                   and GPRD.DIC_FREE_CODE1_ID is null
                   and GPRD.DIC_COMPLEMENTARY_DATA_ID is null
                  )
              or (    aDIC_FREE_CODE1_ID is null
                  and aDIC_COMPLEMENTARY_DATA_ID is not null
                  and GPRD.DIC_COMPLEMENTARY_DATA_ID = aDIC_COMPLEMENTARY_DATA_ID)
              or (    aDIC_FREE_CODE1_ID is not null
                  and aDIC_COMPLEMENTARY_DATA_ID is null
                  and GPRD.DIC_FREE_CODE1_ID = aDIC_FREE_CODE1_ID)
              or (    aDIC_FREE_CODE1_ID is not null
                  and aDIC_COMPLEMENTARY_DATA_ID is not null
                  and GPRD.DIC_FREE_CODE1_ID = aDIC_FREE_CODE1_ID)
             )
         and GPR_START_VALIDITY =
               (select max(GPRD2.GPR_START_VALIDITY)
                  from GCO_PRECIOUS_RATE_DATE GPRD2
                     , GCO_PRECIOUS_RATE GPR2
                 where GPR2.GCO_PRECIOUS_RATE_DATE_ID = GPRD2.GCO_PRECIOUS_RATE_DATE_ID
                   and GPRD2.GPR_TABLE_MODE = 0
                   and GPRD2.GCO_ALLOY_ID = aGCO_ALLOY_ID
                   and GPR2.DIC_TYPE_RATE_ID = aDIC_TYPE_RATE_ID
                   and GPRD2.GPR_START_VALIDITY <= aGPR_START_VALIDITY
                   and (    (    aDIC_FREE_CODE1_ID is null
                             and aDIC_COMPLEMENTARY_DATA_ID is null
                             and GPRD2.DIC_FREE_CODE1_ID is null
                             and GPRD2.DIC_COMPLEMENTARY_DATA_ID is null
                            )
                        or (    aDIC_FREE_CODE1_ID is null
                            and aDIC_COMPLEMENTARY_DATA_ID is not null
                            and GPRD2.DIC_COMPLEMENTARY_DATA_ID = aDIC_COMPLEMENTARY_DATA_ID
                           )
                        or (    aDIC_FREE_CODE1_ID is not null
                            and aDIC_COMPLEMENTARY_DATA_ID is null
                            and GPRD2.DIC_FREE_CODE1_ID = aDIC_FREE_CODE1_ID)
                        or (    aDIC_FREE_CODE1_ID is not null
                            and aDIC_COMPLEMENTARY_DATA_ID is not null
                            and GPRD2.DIC_FREE_CODE1_ID = aDIC_FREE_CODE1_ID)
                       ) );

    cursor CUR_BASIS_MATERIAL_RATE
    is
      -- Sélection "Cours" et "Cours pour" de la matière de base.
      select nvl(GPR.GPR_RATE, 0) GPR_RATE
           , nvl(GPRD.GPR_BASE_COST, 0) GPR_BASE_COST
        from GCO_PRECIOUS_RATE GPR
           , GCO_PRECIOUS_RATE_DATE GPRD
       where GPR.GCO_PRECIOUS_RATE_DATE_ID = GPRD.GCO_PRECIOUS_RATE_DATE_ID
         and GPRD.GPR_TABLE_MODE = 0
         and GPR.DIC_TYPE_RATE_ID = aDIC_TYPE_RATE_ID
         and GPRD.DIC_BASIS_MATERIAL_ID = aDIC_BASIS_MATERIAL_ID
         and (    (    aDIC_FREE_CODE1_ID is null
                   and aDIC_COMPLEMENTARY_DATA_ID is null
                   and GPRD.DIC_FREE_CODE1_ID is null
                   and GPRD.DIC_COMPLEMENTARY_DATA_ID is null
                  )
              or (    aDIC_FREE_CODE1_ID is null
                  and aDIC_COMPLEMENTARY_DATA_ID is not null
                  and GPRD.DIC_COMPLEMENTARY_DATA_ID = aDIC_COMPLEMENTARY_DATA_ID)
              or (    aDIC_FREE_CODE1_ID is not null
                  and aDIC_COMPLEMENTARY_DATA_ID is null
                  and GPRD.DIC_FREE_CODE1_ID = aDIC_FREE_CODE1_ID)
              or (    aDIC_FREE_CODE1_ID is not null
                  and aDIC_COMPLEMENTARY_DATA_ID is not null
                  and GPRD.DIC_FREE_CODE1_ID = aDIC_FREE_CODE1_ID)
             )
         and GPR_START_VALIDITY =
               (select max(GPRD2.GPR_START_VALIDITY)
                  from GCO_PRECIOUS_RATE_DATE GPRD2
                     , GCO_PRECIOUS_RATE GPR2
                 where GPR2.GCO_PRECIOUS_RATE_DATE_ID = GPRD2.GCO_PRECIOUS_RATE_DATE_ID
                   and GPRD2.GPR_TABLE_MODE = 0
                   and GPRD2.DIC_BASIS_MATERIAL_ID = aDIC_BASIS_MATERIAL_ID
                   and GPR2.DIC_TYPE_RATE_ID = aDIC_TYPE_RATE_ID
                   and GPRD2.GPR_START_VALIDITY <= aGPR_START_VALIDITY
                   and (    (    aDIC_FREE_CODE1_ID is null
                             and aDIC_COMPLEMENTARY_DATA_ID is null
                             and GPRD2.DIC_FREE_CODE1_ID is null
                             and GPRD2.DIC_COMPLEMENTARY_DATA_ID is null
                            )
                        or (    aDIC_FREE_CODE1_ID is null
                            and aDIC_COMPLEMENTARY_DATA_ID is not null
                            and GPRD2.DIC_COMPLEMENTARY_DATA_ID = aDIC_COMPLEMENTARY_DATA_ID
                           )
                        or (    aDIC_FREE_CODE1_ID is not null
                            and aDIC_COMPLEMENTARY_DATA_ID is null
                            and GPRD2.DIC_FREE_CODE1_ID = aDIC_FREE_CODE1_ID)
                        or (    aDIC_FREE_CODE1_ID is not null
                            and aDIC_COMPLEMENTARY_DATA_ID is not null
                            and GPRD2.DIC_FREE_CODE1_ID = aDIC_FREE_CODE1_ID)
                       ) );

    CurGcoAlloyRate      CUR_GCO_ALLOY_RATE%rowtype;
    CurBasisMaterialRate CUR_BASIS_MATERIAL_RATE%rowtype;
    nCoursUnitaire       number;
  begin
    nCoursUnitaire  := 0;
    aFounded        := false;

    -- Recherche du cours pour une unité pour un alliage
    if aGCO_ALLOY_ID is not null then
      open CUR_GCO_ALLOY_RATE;

      fetch CUR_GCO_ALLOY_RATE
       into CurGcoAlloyRate;

      aFounded  := CUR_GCO_ALLOY_RATE%found;

      if     aFounded
         and CurGcoAlloyRate.GPR_BASE2_COST <> 0 then
        nCoursUnitaire  :=(CurGcoAlloyRate.GPR_RATE / CurGcoAlloyRate.GPR_BASE2_COST);
      end if;

      close CUR_GCO_ALLOY_RATE;
    -- Recherche du cours pour une unité pour une matière précieuse
    elsif aDIC_BASIS_MATERIAL_ID is not null then
      open CUR_BASIS_MATERIAL_RATE;

      fetch CUR_BASIS_MATERIAL_RATE
       into CurBasisMaterialRate;

      aFounded  := CUR_BASIS_MATERIAL_RATE%found;

      if     aFounded
         and CurBasisMaterialRate.GPR_BASE_COST <> 0 then
        nCoursUnitaire  :=(CurBasisMaterialRate.GPR_RATE / CurBasisMaterialRate.GPR_BASE_COST);
      end if;

      close CUR_BASIS_MATERIAL_RATE;
    else
      aFounded  := false;
    end if;

    -- Si le cours n'a pas été trouvé alors qu'on le recherchait avait Code libre, on fait la recherche sans code libre
    if     aDIC_FREE_CODE1_ID is not null
       and aFounded = false then
      nCoursUnitaire  :=
                      GetQuotedPrice(aGCO_ALLOY_ID, aDIC_BASIS_MATERIAL_ID, aGPR_START_VALIDITY, aDIC_TYPE_RATE_ID, aFounded, null, aDIC_COMPLEMENTARY_DATA_ID);
    -- Si le cours n'a pas été trouvé alors qu'on le recherchait avait Code donnée complémentaire, on fait la recherche sans code code donnée complémentaire
    elsif     aDIC_FREE_CODE1_ID is null
          and aDIC_COMPLEMENTARY_DATA_ID is not null
          and aFounded = false then
      nCoursUnitaire  := GetQuotedPrice(aGCO_ALLOY_ID, aDIC_BASIS_MATERIAL_ID, aGPR_START_VALIDITY, aDIC_TYPE_RATE_ID, aFounded, null, null);
    end if;

    return nCoursUnitaire;
  end GetQuotedPrice;

  /**
  * Procedure LoadProductListStruct
  * Description
  *   Enregistrement table provisoire produit (Liste pré-calculation, Grph evts : Génération structure
  *
  * @author  Emmanuel Cassis
  * @version 16.07.2004
  * @public
  *
  */
  procedure LoadProductListStruct(
    aGCO_GOOD_ID                  GCO_GOOD.GCO_GOOD_ID%type
  , aGCO_GCO_GOOD_ID              GCO_GOOD.GCO_GOOD_ID%type
  , aFAL_STRUCT_CALC_ID           FAL_STRUCT_CALC.FAL_STRUCT_CALC_ID%type
  , aFPG_LEVEL                    FAL_PRECALC_GOOD.FPG_LEVEL%type
  , aFPG_NOM_COEF                 FAL_PRECALC_GOOD.FPG_NOM_COEF%type
  , aFPG_QUANTITY                 FAL_PRECALC_GOOD.FPG_QUANTITY%type
  , aFPG_SESSION_ID               FAL_PRECALC_GOOD.FPG_SESSION_ID%type
  , aIncludeMaterialDicoRate      integer
  , aInMaterialCalculation        integer
  , aMaterialCost                 FAL_PRECALC_GOOD.FPG_TOTAL%type
  , aDIC_FAB_CONDITION_ID         DIC_FAB_CONDITION.DIC_FAB_CONDITION_ID%type
  , aFPG_CALCULATION_STRUCTURE    FAL_PRECALC_GOOD.FPG_CALCULATION_STRUCTURE%type
  , aFPG_MAT_RATE                 FAL_PRECALC_GOOD.FPG_MAT_RATE%type
  , aFPG_WORK_RATE                FAL_PRECALC_GOOD.FPG_WORK_RATE%type
  , aFPG_STD_QTY                  FAL_PRECALC_GOOD.FPG_STD_QTY%type
  , aFPG_FREE_QTY                 FAL_PRECALC_GOOD.FPG_FREE_QTY%type
  , aFPG_STD_AND_FREE_QTY         FAL_PRECALC_GOOD.FPG_STD_AND_FREE_QTY%type
  , aFPG_MANAGEMENT_MODE          FAL_PRECALC_GOOD.FPG_MANAGEMENT_MODE%type
  , aFPG_PRCS                     FAL_PRECALC_GOOD.FPG_PRCS%type
  , aDIC_CALC_COSTPRICE_DESCR_ID  FAL_PRECALC_GOOD.DIC_CALC_COSTPRICE_DESCR_ID%type
  , aDIC_FIXED_COSTPRICE_DESCR_ID FAL_PRECALC_GOOD.DIC_FIXED_COSTPRICE_DESCR_ID%type
  , aFPG_PURCHASE_TARIFF          FAL_PRECALC_GOOD.FPG_PURCHASE_TARIFF%type
  , aFPG_DERIVED_LINK             FAL_PRECALC_GOOD.FPG_DERIVED_LINK%type
  , aFPG_WASTE                    FAL_PRECALC_GOOD.FPG_WASTE%type
  , aFPG_REJECT                   FAL_PRECALC_GOOD.FPG_REJECT%type
  , aDoUpdate                     integer
  , aFPG_CALC_BY_CATEGORY         FAL_PRECALC_GOOD.FPG_CALC_BY_CATEGORY%type
  , aFPG_STD_QTY_FOR_CPT          FAL_PRECALC_GOOD.FPG_STD_QTY_FOR_CPT%type
  )
  is
    vPT_MAJOR_REF            GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    vPT_SECONDARY_REF        GCO_GOOD.GOO_SECONDARY_REFERENCE%type;
    vCPT_MAJOR_REF           GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    vCPT_SECONDARY_REF       GCO_GOOD.GOO_SECONDARY_REFERENCE%type;
    nFPG_FIXED_COST          FAL_PRECALC_GOOD.FPG_FIXED_COST%type;
    nFPG_TOTAL               FAL_PRECALC_GOOD.FPG_TOTAL%type;
    nFPG_UNDERHEADING_MARGIN FAL_PRECALC_GOOD.FPG_UNDERHEADING_MARGIN%type;
    nFPG_WORK_MARGIN         FAL_PRECALC_GOOD.FPG_WORK_MARGIN%type;
    nFPG_MATERIAL_MARGIN     FAL_PRECALC_GOOD.FPG_MATERIAL_MARGIN%type;
    nFPG_MW_MARGIN           FAL_PRECALC_GOOD.FPG_MW_MARGIN%type;
    nFPG_TOTAL_WITH_MARGIN   FAL_PRECALC_GOOD.FPG_TOTAL_WITH_MARGIN%type;
    nTSR_RATE                FAL_RATE_DIC_MAT.TSR_RATE%type;
  begin
    -- Initialisation variables
    vPT_MAJOR_REF             := '';
    vPT_SECONDARY_REF         := '';
    vCPT_MAJOR_REF            := '';
    vCPT_SECONDARY_REF        := '';
    nFPG_FIXED_COST           := 0;
    nFPG_TOTAL                := 0;
    nFPG_UNDERHEADING_MARGIN  := 0;
    nFPG_WORK_MARGIN          := 0;
    nFPG_MATERIAL_MARGIN      := 0;
    nFPG_MW_MARGIN            := 0;
    nFPG_TOTAL_WITH_MARGIN    := 0;

    -- Coef. nomenclature,quantité et montant fixe
    if aFPG_LEVEL = 0 then
      begin
        select nvl(sum(MFS_PRICE), 0)
          into nFPG_FIXED_COST
          from FAL_FIX_STRUCT
         where FAL_STRUCT_CALC_ID = aFAL_STRUCT_CALC_ID;
      exception
        when no_data_found then
          nFPG_FIXED_COST  := 0;
      end;
    end if;

    -- Total 1
    if aInMaterialCalculation = 1 then
      nFPG_TOTAL  := aMaterialCost;
    end if;

    -- Prise en compte des taux par sous-rubrique matière
    if aIncludeMaterialDicoRate = 1 then
      nTSR_RATE  := GetUnderHeadingMatRate(aGCO_GCO_GOOD_ID);

      if nTSR_RATE <> 0 then
        nFPG_UNDERHEADING_MARGIN  := (nFPG_TOTAL * nTSR_RATE) / 100;
      end if;
    end if;

    if aInMaterialCalculation = 1 then
      -- Calcul Marge matière
      begin
        select nvl(sum( (TXS_RATE / 100) *(nFPG_TOTAL + nFPG_UNDERHEADING_MARGIN) ), 0)
          into nFPG_MATERIAL_MARGIN
          from FAL_RATE_STRUCT
         where FAL_STRUCT_CALC_ID = aFAL_STRUCT_CALC_ID
           and C_CLASS_RATE = '1';
      exception
        when no_data_found then
          nFPG_MATERIAL_MARGIN  := 0;
      end;

      -- Calcul marge matière + Travail
      begin
        select nvl(sum( (TXS_RATE / 100) *(nFPG_TOTAL + nFPG_UNDERHEADING_MARGIN) ), 0)
          into nFPG_MW_MARGIN
          from FAL_RATE_STRUCT
         where FAL_STRUCT_CALC_ID = aFAL_STRUCT_CALC_ID
           and C_CLASS_RATE = '3';
      exception
        when no_data_found then
          nFPG_MW_MARGIN  := 0;
      end;

      -- Total marge inclue
      nFPG_TOTAL_WITH_MARGIN  := nFPG_TOTAL + nFPG_UNDERHEADING_MARGIN + nFPG_WORK_MARGIN + nFPG_MATERIAL_MARGIN + nFPG_MW_MARGIN + nFPG_FIXED_COST;
    end if;

    -- Références produits PT
    select GOO_MAJOR_REFERENCE
         , GOO_SECONDARY_REFERENCE
      into vPT_MAJOR_REF
         , vPT_SECONDARY_REF
      from GCO_GOOD
     where GCO_GOOD_ID = aGCO_GOOD_ID;

    -- Références produits CPT
    select GOO_MAJOR_REFERENCE
         , GOO_SECONDARY_REFERENCE
      into vCPT_MAJOR_REF
         , vCPT_SECONDARY_REF
      from GCO_GOOD
     where GCO_GOOD_ID = aGCO_GCO_GOOD_ID;

    -- Insertion dans la table produits
    if aDoUpdate <> 1 then
      insert into FAL_PRECALC_GOOD
                  (FAL_PRECALC_GOOD_ID
                 , GCO_GOOD_ID
                 , GCO_GCO_GOOD_ID
                 , FPG_PT_MAJOR_REF
                 , FPG_PT_SECONDARY_REF
                 , FPG_CPT_MAJOR_REF
                 , FPG_CPT_SECONDARY_REF
                 , FPG_LEVEL
                 , FPG_NOM_COEF
                 , FPG_QUANTITY
                 , FPG_TOTAL
                 , FPG_UNDERHEADING_MARGIN
                 , FPG_WORK_MARGIN
                 , FPG_MATERIAL_MARGIN
                 , FPG_MW_MARGIN
                 , FPG_FIXED_COST
                 , FPG_TOTAL_WITH_MARGIN
                 , FPG_SESSION_ID
                 , DIC_FAB_CONDITION_ID
                 , FPG_CALCULATION_STRUCTURE
                 , FPG_MAT_RATE
                 , FPG_WORK_RATE
                 , FPG_STD_QTY
                 , FPG_FREE_QTY
                 , FPG_STD_AND_FREE_QTY
                 , FPG_MANAGEMENT_MODE
                 , FPG_PRCS
                 , DIC_CALC_COSTPRICE_DESCR_ID
                 , DIC_FIXED_COSTPRICE_DESCR_ID
                 , FPG_PURCHASE_TARIFF
                 , FPG_DERIVED_LINK
                 , FPG_WASTE
                 , FPG_REJECT
                 , FPG_CALC_BY_CATEGORY
                 , FPG_STD_QTY_FOR_CPT
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 , aGCO_GOOD_ID
                 , aGCO_GCO_GOOD_ID
                 , vPT_MAJOR_REF
                 , vPT_SECONDARY_REF
                 , vCPT_MAJOR_REF
                 , vCPT_SECONDARY_REF
                 , aFPG_LEVEL
                 , aFPG_NOM_COEF
                 , aFPG_QUANTITY
                 , nFPG_TOTAL
                 , nFPG_UNDERHEADING_MARGIN
                 , nFPG_WORK_MARGIN
                 , nFPG_MATERIAL_MARGIN
                 , nFPG_MW_MARGIN
                 , nFPG_FIXED_COST
                 , nFPG_TOTAL_WITH_MARGIN
                 , aFPG_SESSION_ID
                 , aDIC_FAB_CONDITION_ID
                 , aFPG_CALCULATION_STRUCTURE
                 , aFPG_MAT_RATE
                 , aFPG_WORK_RATE
                 , aFPG_STD_QTY
                 , aFPG_FREE_QTY
                 , aFPG_STD_AND_FREE_QTY
                 , aFPG_MANAGEMENT_MODE
                 , aFPG_PRCS
                 , aDIC_CALC_COSTPRICE_DESCR_ID
                 , aDIC_FIXED_COSTPRICE_DESCR_ID
                 , aFPG_PURCHASE_TARIFF
                 , aFPG_DERIVED_LINK
                 , aFPG_WASTE
                 , aFPG_REJECT
                 , aFPG_CALC_BY_CATEGORY
                 , aFPG_STD_QTY_FOR_CPT
                 , sysdate
                 , PCS.PC_PUBLIC.GetUserIni
                  );
    else
      update FAL_PRECALC_GOOD
         set FPG_TOTAL = nFPG_TOTAL
           , FPG_UNDERHEADING_MARGIN = nFPG_UNDERHEADING_MARGIN
           , FPG_MATERIAL_MARGIN = nFPG_MATERIAL_MARGIN
           , FPG_MW_MARGIN = nFPG_MW_MARGIN
           , FPG_TOTAL_WITH_MARGIN = nFPG_TOTAL_WITH_MARGIN
       where GCO_GOOD_ID = aGCO_GOOD_ID
         and GCO_GCO_GOOD_ID = aGCO_GOOD_ID;
    end if;
  exception
    when others then
      raise;
  end LoadproductListStruct;

  -- Suppression eventuelle d'enregistrement persistants dans les tables temporaires
  procedure ScanAndDeleteObsoleteList(aSESSION_ID varchar2)
  is
    cursor crOracleSession
    is
      select FPG_SESSION_ID
        from FAL_PRECALC_GOOD
      union
      select FPC_SESSION_ID
        from FAL_PRECALC_PROD_COST
      union
      select FPT_SESSION_ID
        from FAL_PRECALC_PROD_TIME;
  begin
    if aSESSION_ID is null then
      for tplOracleSession in crOracleSession loop
        if COM_FUNCTIONS.Is_Session_Alive(tplOracleSession.FPG_SESSION_ID) = 0 then
          -- Suppression sessions obsolètes dans la table FAL_PRECALC_GOOD (Produits)
          delete from FAL_PRECALC_GOOD
                where FPG_SESSION_ID = tplOracleSession.FPG_SESSION_ID;

          -- Suppression sessions obsolètes dans la table FAL_PRECALC_PROD_COST (Coûts de production)
          delete from FAL_PRECALC_PROD_COST
                where FPC_SESSION_ID = tplOracleSession.FPG_SESSION_ID;

          -- Suppression sessions obsolètes dans la table FAL_PRECALC_PROD_TIME (Temps de production)
          delete from FAL_PRECALC_PROD_TIME
                where FPT_SESSION_ID = tplOracleSession.FPG_SESSION_ID;
        end if;
      end loop;
    else
      -- Suppression FPG_SESSION = aSESSION_ID
      delete from FAL_PRECALC_GOOD
            where FPG_SESSION_ID = aSESSION_ID;

      -- Suppression FPC_SESSION = aSESSION_ID
      delete from FAL_PRECALC_PROD_COST
            where FPC_SESSION_ID = aSESSION_ID;

      -- Suppression FPT_SESSION = aSESSION_ID
      delete from FAL_PRECALC_PROD_TIME
            where FPT_SESSION_ID = aSESSION_ID;
    end if;
  end;

  /**
  * Procedure LoadProductionCost
  * Description
  *   Enregistrement table provisoire coûts de production
  *
  * @author  Emmanuel Cassis
  * @version 16.07.2004
  * @public
  *
  */
  procedure LoadProductionCosts(
    aGCO_GOOD_ID          GCO_GOOD.GCO_GOOD_ID%type
  , aFAL_SCHEDULE_STEP_ID FAL_LIST_STEP_LINK.FAL_SCHEDULE_STEP_ID%type
  , aFAL_STRUCT_CALC_ID   FAL_STRUCT_CALC.FAL_STRUCT_CALC_ID%type
  , aMachineCost          number
  , aManPowerCost         number
  , aIncludeWorkDicoRate  integer
  , aFPC_SESSION_ID       FAL_PRECALC_PROD_COST.FPC_SESSION_ID%type
  )
  is
    nFAL_FACTORY_FLOOR_ID    FAL_FACTORY_FLOOR.FAL_FACTORY_FLOOR_ID%type;
    nPAC_SUPPLIER_PARTNER_ID PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type;
    vFPC_TASK_REF            FAL_PRECALC_PROD_COST.FPC_TASK_REF%type;
    vFPC_TSK_DESCR           FAL_PRECALC_PROD_COST.FPC_TSK_DESCR%type;
    vFPC_SECTION             FAL_PRECALC_PROD_COST.FPC_SECTION%type;
    nFPC_UNDERHEADING_MARGIN FAL_PRECALC_PROD_COST.FPC_UNDERHEADING_MARGIN%type;
    nFPC_WORK_MARGIN         FAL_PRECALC_PROD_COST.FPC_WORK_MARGIN%type;
    nFPC_MATERIAL_MARGIN     FAL_PRECALC_PROD_COST.FPC_MATERIAL_MARGIN%type;
    nFPC_MW_MARGIN           FAL_PRECALC_PROD_COST.FPC_MW_MARGIN%type;
    nFPC_FIXED_COST          FAL_PRECALC_PROD_COST.FPC_FIXED_COST%type;
    nFPC_TOTAL               FAL_PRECALC_PROD_COST.FPC_TOTAL%type;
    nFPC_TOTAL_WITH_MARGIN   FAL_PRECALC_PROD_COST.FPC_TOTAL_WITH_MARGIN%type;
    nTXR_RATE                FAL_RATE_DIC_WORK.TXR_RATE%type;
    nGCO_GOOD_ID             GCO_GOOD.GCO_GOOD_ID%type;
    nFAL_PRECALC_GOOD_ID     FAL_PRECALC_GOOD.FAL_PRECALC_GOOD_ID%type;
  begin
    -- intialisation des variables
    nFAL_FACTORY_FLOOR_ID     := null;
    nPAC_SUPPLIER_PARTNER_ID  := null;
    nGCO_GOOD_ID              := null;
    vFPC_TASK_REF             := '';
    vFPC_TSK_DESCR            := '';
    vFPC_SECTION              := '';
    nFPC_UNDERHEADING_MARGIN  := 0;
    nFPC_WORK_MARGIN          := 0;
    nFPC_MATERIAL_MARGIN      := 0;
    nFPC_MW_MARGIN            := 0;
    nFPC_FIXED_COST           := 0;
    nFPC_TOTAL                := 0;
    nFPC_TOTAL_WITH_MARGIN    := 0;

    -- ID Dernière ligne produit
    select max(FAL_PRECALC_GOOD_ID)
      into nFAL_PRECALC_GOOD_ID
      from FAL_PRECALC_GOOD
     where FPG_SESSION_ID = aFPC_SESSION_ID;

    -- ID Produit terminé
    begin
      select GCO_GOOD_ID
        into nGCO_GOOD_ID
        from FAL_PRECALC_GOOD
       where FAL_PRECALC_GOOD_ID = (select max(FAL_PRECALC_GOOD_ID)
                                      from FAL_PRECALC_GOOD
                                     where FPG_SESSION_ID = aFPC_SESSION_ID
                                       and FPG_LEVEL = 0);
    exception
      when others then
        nGCO_GOOD_ID  := null;
    end;

    -- Opération, désignation, atelier, fournisseur, section
    begin
      select TAS.TAS_REF
           , SCS.SCS_SHORT_DESCR
           , SCS.FAL_FACTORY_FLOOR_ID
           , SCS.PAC_SUPPLIER_PARTNER_ID
           , FAL_PRECALC_TOOLS.GetProductionSection(SCS.FAL_FACTORY_FLOOR_ID)
        into vFPC_TASK_REF
           , vFPC_TSK_DESCR
           , nFAL_FACTORY_FLOOR_ID
           , nPAC_SUPPLIER_PARTNER_ID
           , vFPC_SECTION
        from FAL_LIST_STEP_LINK SCS
           , FAL_TASK TAS
           , FAL_FACTORY_FLOOR FAC
       where SCS.FAL_TASK_ID = TAS.FAL_TASK_ID
         and SCS.FAL_FACTORY_FLOOR_ID = FAC.FAL_FACTORY_FLOOR_ID(+)
         and SCS.FAL_SCHEDULE_STEP_ID = aFAL_SCHEDULE_STEP_ID;
    exception
      when no_data_found then
        null;
    end;

    -- Total
    nFPC_TOTAL                :=(aMachineCost + aManPowerCost);

    -- Taux par sous rubrique travail
    if aIncludeWorkDicoRate = 1 then
      nTXR_RATE  := GetUnderHeadingWorkRate(aFAL_SCHEDULE_STEP_ID);

      if nTXR_RATE <> 0 then
        nFPC_UNDERHEADING_MARGIN  := (nFPC_TOTAL * nTXR_RATE) / 100;
      end if;
    end if;

    -- Marge travail
    begin
      select sum( (TXS_RATE / 100) *(nFPC_TOTAL + nFPC_UNDERHEADING_MARGIN) )
        into nFPC_WORK_MARGIN
        from FAL_RATE_STRUCT TXS
       where TXS.FAL_STRUCT_CALC_ID = aFAL_STRUCT_CALC_ID
         and TXS.C_CLASS_RATE = '2';
    exception
      when no_data_found then
        nFPC_WORK_MARGIN  := 0;
    end;

    -- Marge matière + travail
    begin
      select sum( (TXS_RATE / 100) *(nFPC_TOTAL + nFPC_UNDERHEADING_MARGIN) )
        into nFPC_MW_MARGIN
        from FAL_RATE_STRUCT TXS
       where TXS.FAL_STRUCT_CALC_ID = aFAL_STRUCT_CALC_ID
         and TXS.C_CLASS_RATE = '3';
    exception
      when no_data_found then
        nFPC_WORK_MARGIN  := 0;
    end;

    -- Total marge incluse
    nFPC_TOTAL_WITH_MARGIN    := nFPC_TOTAL + nFPC_UNDERHEADING_MARGIN + nFPC_WORK_MARGIN + nFPC_MATERIAL_MARGIN + nFPC_MW_MARGIN + nFPC_FIXED_COST;

    -- Enregistrement table provisoire cout de production
    insert into FAL_PRECALC_PROD_COST
                (FAL_PRECALC_PROD_COST_ID
               , FAL_PRECALC_GOOD_ID
               , GCO_GOOD_ID
               , GCO_GCO_GOOD_ID
               , FAL_FACTORY_FLOOR_ID
               , PAC_SUPPLIER_PARTNER_ID
               , FPC_TASK_REF
               , FPC_TSK_DESCR
               , FPC_SECTION
               , FPC_MACHINE_COST
               , FPC_WORK_COST
               , FPC_TOTAL
               , FPC_UNDERHEADING_MARGIN
               , FPC_WORK_MARGIN
               , FPC_MATERIAL_MARGIN
               , FPC_MW_MARGIN
               , FPC_FIXED_COST
               , FPC_TOTAL_WITH_MARGIN
               , FPC_SESSION_ID
               , A_DATECRE
               , A_IDCRE
                )
         values (GetNewId
               , nFAL_PRECALC_GOOD_ID
               , nGCO_GOOD_ID
               , aGCO_GOOD_ID
               , nFAL_FACTORY_FLOOR_ID
               , nPAC_SUPPLIER_PARTNER_ID
               , vFPC_TASK_REF
               , vFPC_TSK_DESCR
               , vFPC_SECTION
               , aMachineCost
               , aManPowerCost
               , nFPC_TOTAL
               , nFPC_UNDERHEADING_MARGIN
               , nFPC_WORK_MARGIN
               , nFPC_MATERIAL_MARGIN
               , nFPC_MW_MARGIN
               , nFPC_FIXED_COST
               , nFPC_TOTAL_WITH_MARGIN
               , aFPC_SESSION_ID
               , sysdate
               , PCS.PC_PUBLIC.GETUSERINI
                );
  end LoadProductionCosts;

  /**
  * Procedure LoadProductionTime
  * Description
  *   Enregistrement table provisoire temps de production
  *
  * @author  Emmanuel Cassis
  * @version 16.07.2004
  * @public
  *
  */
  procedure LoadProductionTimes(
    aFAL_SCHEDULE_STEP_ID FAL_LIST_STEP_LINK.FAL_SCHEDULE_STEP_ID%type
  , aFPT_ADJUSTING        FAL_PRECALC_PROD_TIME.FPT_ADJUSTING%type
  , aFPT_WORK             FAL_PRECALC_PROD_TIME.FPT_WORK%type
  , aFPT_SESSION_ID       FAL_PRECALC_PROD_TIME.FPT_SESSION_ID%type
  , aGCO_GOOD_ID          GCO_GOOD.GCO_GOOD_ID%type
  )
  is
    nFAL_FACTORY_FLOOR_ID FAL_PRECALC_PROD_TIME.FAL_FACTORY_FLOOR_ID%type;
    vFPT_SECTION          FAL_PRECALC_PROD_TIME.FPT_SECTION%type;
    nGCO_GOOD_ID          GCO_GOOD.GCO_GOOD_ID%type;
    nFAL_PRECALC_GOOD_ID  FAL_PRECALC_GOOD.FAL_PRECALC_GOOD_ID%type;
  begin
    nFAL_FACTORY_FLOOR_ID  := null;
    vFPT_SECTION           := '';

    -- ID Dernière ligne produit
    select max(FAL_PRECALC_GOOD_ID)
      into nFAL_PRECALC_GOOD_ID
      from FAL_PRECALC_GOOD
     where FPG_SESSION_ID = aFPT_SESSION_ID;

    -- ID Produit terminé
    begin
      select GCO_GOOD_ID
        into nGCO_GOOD_ID
        from FAL_PRECALC_GOOD
       where FAL_PRECALC_GOOD_ID = (select max(FAL_PRECALC_GOOD_ID)
                                      from FAL_PRECALC_GOOD
                                     where FPG_SESSION_ID = aFPT_SESSION_ID
                                       and FPG_LEVEL = 0);
    exception
      when others then
        nGCO_GOOD_ID  := null;
    end;

    -- Opération, désignation, atelier, fournisseur, section
    begin
      select SCS.FAL_FACTORY_FLOOR_ID
           , FAL_PRECALC_TOOLS.GetProductionSection(FAC.FAL_FACTORY_FLOOR_ID)
        into nFAL_FACTORY_FLOOR_ID
           , vFPT_SECTION
        from FAL_LIST_STEP_LINK SCS
           , FAL_FACTORY_FLOOR FAC
       where SCS.FAL_FACTORY_FLOOR_ID = FAC.FAL_FACTORY_FLOOR_ID
         and SCS.FAL_SCHEDULE_STEP_ID = aFAL_SCHEDULE_STEP_ID;
    exception
      when no_data_found then
        null;
    end;

    -- Enregistrement table temps de production.
    insert into FAL_PRECALC_PROD_TIME
                (FAL_PRECALC_PROD_TIME_ID
               , FAL_PRECALC_GOOD_ID
               , GCO_GOOD_ID
               , GCO_GCO_GOOD_ID
               , FAL_FACTORY_FLOOR_ID
               , FPT_SECTION
               , FPT_ADJUSTING
               , FPT_WORK
               , FPT_SESSION_ID
               , A_DATECRE
               , A_IDCRE
                )
         values (GetNewId
               , nFAL_PRECALC_GOOD_ID
               , nGCO_GOOD_ID
               , aGCO_GOOD_ID
               , nFAL_FACTORY_FLOOR_ID
               , vFPT_SECTION
               , aFPT_ADJUSTING
               , aFPT_WORK
               , aFPT_SESSION_ID
               , sysdate
               , PCS.PC_PUBLIC.GETUSERINI
                );
  end;

  -- Calcul des champs aggrégés pour une ligne produit depuis crystal (Liste précalculation)
  function CalcAggregateField(
    aFieldName           PCS.PC_FLDSC.FLDNAME%type
  , aFPG_SESSION_ID      FAL_PRECALC_GOOD.FPG_SESSION_ID%type
  , aGCO_GOOD_ID         GCO_GOOD.GCO_GOOD_ID%type
  , aGCO_GCO_GOOD_ID     GCO_GOOD.GCO_GOOD_ID%type
  , aFPG_LEVEL           FAL_PRECALC_GOOD.FPG_LEVEL%type
  , aFAL_PRECALC_GOOD_ID FAL_PRECALC_GOOD.FAL_PRECALC_GOOD_ID%type
  )
    return number
  is
    BuffSQL              varchar2(2000);
    Cursor_Handle        integer;
    Execute_Cursor       integer;
    nAggregationResult   number;
    iCurrentLevel        integer;
    nFAL_PRECALC_GOOD_ID number;
    nGCO_GCO_GOOD_ID     number;
    nCurrentProductSum   number;
    NextID               number;
  begin
    nAggregationResult  := 0;
    nCurrentProductSum  := 0;
    -- Somme des ligne table coût de production du produit
    BuffSQL             :=
      '      SELECT SUM(NVL(FPC.' ||
      aFieldName ||
      ', FPG.' ||
      replace(aFieldName, 'FPC', 'FPG') ||
      ')) A_LEVEL_SUM' ||
      '        FROM FAL_PRECALC_GOOD FPG,     ' ||
      '             FAL_PRECALC_PROD_COST FPC ' ||
      '		 WHERE FPG.FAL_PRECALC_GOOD_ID = FPC.FAL_PRECALC_GOOD_ID (+) ' ||
      '         AND FPG.FPG_SESSION_ID = ''' ||
      aFPG_SESSION_ID ||
      '''' ||
      '         AND FPG.FPG_LEVEL = ' ||
      aFPG_LEVEL;

    if aFAL_PRECALC_GOOD_ID <> 0 then
      BuffSQL  := BuffSQL || '         AND FPG.FAL_PRECALC_GOOD_ID = ' || aFAL_PRECALC_GOOD_ID;
    end if;

    BuffSQL             := BuffSQL || '    ORDER BY FPG.FAL_PRECALC_GOOD_ID ASC ';
    Cursor_Handle       := DBMS_SQL.open_cursor;
    DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.V7);
    DBMS_SQL.Define_column(Cursor_Handle, 1, nCurrentProductSum);
    Execute_Cursor      := DBMS_SQL.execute(Cursor_Handle);

    loop
      if DBMS_SQL.fetch_rows(Cursor_Handle) > 0 then
        DBMS_SQL.column_value(Cursor_Handle, 1, nCurrentProductSum);
      else
        exit;
      end if;
    end loop;

    DBMS_SQL.close_cursor(Cursor_Handle);

    /* Pour chaque ligne Produit de niveau = niveau + 1 d'ID > à l'ID parent
    et inférieur au prochain ID de level <= LevelParent (Mini) */
    -- Recherche du prochain ID
    if aFAL_PRECALC_GOOD_ID <> 0 then
      begin
        select min(FPG.FAL_PRECALC_GOOD_ID)
          into NextID
          from FAL_PRECALC_GOOD FPG
         where FPG.FAL_PRECALC_GOOD_ID > aFAL_PRECALC_GOOD_ID
           and FPG.FPG_SESSION_ID = aFPG_SESSION_ID
           and FPG.GCO_GOOD_ID = aGCO_GOOD_ID
           and FPG.FPG_LEVEL <= aFPG_LEVEL;
      exception
        when others then
          NextID  := 0;
      end;
    else
      NextID  := 0;
    end if;

    BuffSQL             :=
      '      SELECT FPG.FPG_LEVEL,      ' ||
      '             FPG.FAL_PRECALC_GOOD_ID, ' ||
      '             FPG.GCO_GCO_GOOD_ID ' ||
      '        FROM FAL_PRECALC_GOOD FPG     ' ||
      '		 WHERE FPG.FAL_PRECALC_GOOD_ID >  ' ||
      aFAL_PRECALC_GOOD_ID ||
      '         AND FPG.FPG_SESSION_ID = ''' ||
      aFPG_SESSION_ID ||
      '''' ||
      '         AND FPG.GCO_GOOD_ID = ' ||
      aGCO_GOOD_ID ||
      '         AND FPG.FPG_LEVEL =' ||
      (aFPG_LEVEL + 1);

    if NextID <> 0 then
      BuffSQL  := BuffSQL || '         AND FPG.FAL_PRECALC_GOOD_ID < ' || NextID;
    end if;

    BuffSQL             := BuffSQL || '    ORDER BY FPG.FAL_PRECALC_GOOD_ID ASC ';
    Cursor_Handle       := DBMS_SQL.open_cursor;
    DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.V7);
    DBMS_SQL.Define_column(Cursor_Handle, 1, iCurrentLevel);
    DBMS_SQL.Define_column(Cursor_Handle, 2, nFAL_PRECALC_GOOD_ID);
    DBMS_SQL.Define_column(Cursor_Handle, 3, nGCO_GCO_GOOD_ID);
    Execute_Cursor      := DBMS_SQL.execute(Cursor_Handle);

    loop
      if DBMS_SQL.fetch_rows(Cursor_Handle) > 0 then
        DBMS_SQL.column_value(Cursor_Handle, 1, iCurrentLevel);
        DBMS_SQL.column_value(Cursor_Handle, 2, nFAL_PRECALC_GOOD_ID);
        DBMS_SQL.column_value(Cursor_Handle, 3, nGCO_GCO_GOOD_ID);
        nCurrentProductSum  :=
                      nCurrentProductSum + CalcAggregateField(aFieldName, aFPG_SESSION_ID, aGCO_GOOD_ID, nGCO_GCO_GOOD_ID, iCurrentLevel, nFAL_PRECALC_GOOD_ID);
      else
        exit;
      end if;
    end loop;

    DBMS_SQL.close_cursor(Cursor_Handle);
    return nCurrentProductSum;
  exception
    when others then
      raise;
      return nCurrentProductSum;
  end;

  /**
  * Procedure MAJProductListStruct
  * Description
  *   MAJ table provisoire produit (Liste pré-calculation, Grph evts : Génération structure
  *
  * @author  Emmanuel Cassis
  * @version 16.07.2004
  * @public
  *
  */
  procedure MAJProductListStruct(aQty number, aFPG_SESSION_ID FAL_PRECALC_GOOD.FPG_SESSION_ID%type)
  is
  begin
    update FAL_PRECALC_GOOD
       set FPG_QUANTITY = aQty
     where FAL_PRECALC_GOOD_ID = (select max(FAL_PRECALC_GOOD_ID)
                                    from FAL_PRECALC_GOOD
                                   where FPG_SESSION_ID = aFPG_SESSION_ID);
  end MAJProductListStruct;

  /**
  * Procedure CalcAggregateField
  * Description
  *   Calcul de tous les champs aggrégés pour une impression (session) donnée
  *
  * @author  Emmanuel Cassis
  * @version 16.07.2004
  * @public
  *
  */
  procedure CalcAllFields(aFPG_SESSION_ID FAL_PRECALC_GOOD.FPG_SESSION_ID%type)
  is
    cursor CUR_FAL_PRECALC_GOOD
    is
      select   GCO_GOOD_ID
             , GCO_GCO_GOOD_ID
             , FPG_LEVEL
             , FAL_PRECALC_GOOD_ID
          from FAL_PRECALC_GOOD
         where FAL_PRECALC_GOOD.FPG_SESSION_ID = aFPG_SESSION_ID
      order by FAL_PRECALC_GOOD_ID asc;

    CurFalPrecalcGood        CUR_FAL_PRECALC_GOOD%rowtype;
    aFieldName               varchar2(50);
    aFPC_TOTAL               number;
    aFPC_UNDERHEADING_MARGIN number;
    aFPC_WORK_MARGIN         number;
    aFPC_MATERIAL_MARGIN     number;
    aFPC_MW_MARGIN           number;
  begin
    for CurFalPrecalcGood in CUR_FAL_PRECALC_GOOD loop
      aFPC_TOTAL                := 0;
      aFPC_UNDERHEADING_MARGIN  := 0;
      aFPC_WORK_MARGIN          := 0;
      aFPC_MATERIAL_MARGIN      := 0;
      aFPC_MW_MARGIN            := 0;
      -- Calcul des champs aggrégé
      aFieldName                := 'FPC_TOTAL';
      aFPC_TOTAL                :=
        CalcAggregateField(aFieldName
                         , aFPG_SESSION_ID
                         , CurFalPrecalcGood.GCO_GOOD_ID
                         , CurFalPrecalcGood.GCO_GCO_GOOD_ID
                         , CurFalPrecalcGood.FPG_LEVEL
                         , CurFalPrecalcGood.FAL_PRECALC_GOOD_ID
                          );
      aFieldName                := 'FPC_UNDERHEADING_MARGIN';
      aFPC_UNDERHEADING_MARGIN  :=
        CalcAggregateField(aFieldName
                         , aFPG_SESSION_ID
                         , CurFalPrecalcGood.GCO_GOOD_ID
                         , CurFalPrecalcGood.GCO_GCO_GOOD_ID
                         , CurFalPrecalcGood.FPG_LEVEL
                         , CurFalPrecalcGood.FAL_PRECALC_GOOD_ID
                          );
      aFieldName                := 'FPC_WORK_MARGIN';
      aFPC_WORK_MARGIN          :=
        CalcAggregateField(aFieldName
                         , aFPG_SESSION_ID
                         , CurFalPrecalcGood.GCO_GOOD_ID
                         , CurFalPrecalcGood.GCO_GCO_GOOD_ID
                         , CurFalPrecalcGood.FPG_LEVEL
                         , CurFalPrecalcGood.FAL_PRECALC_GOOD_ID
                          );
      aFieldName                := 'FPC_MATERIAL_MARGIN';
      aFPC_MATERIAL_MARGIN      :=
        CalcAggregateField(aFieldName
                         , aFPG_SESSION_ID
                         , CurFalPrecalcGood.GCO_GOOD_ID
                         , CurFalPrecalcGood.GCO_GCO_GOOD_ID
                         , CurFalPrecalcGood.FPG_LEVEL
                         , CurFalPrecalcGood.FAL_PRECALC_GOOD_ID
                          );
      aFieldName                := 'FPC_MW_MARGIN';
      aFPC_MW_MARGIN            :=
        CalcAggregateField(aFieldName
                         , aFPG_SESSION_ID
                         , CurFalPrecalcGood.GCO_GOOD_ID
                         , CurFalPrecalcGood.GCO_GCO_GOOD_ID
                         , CurFalPrecalcGood.FPG_LEVEL
                         , CurFalPrecalcGood.FAL_PRECALC_GOOD_ID
                          );

      -- Update de la ligne produit
      update FAL_PRECALC_GOOD
         set FPG_TOTAL = aFPC_TOTAL
           , FPG_UNDERHEADING_MARGIN = aFPC_UNDERHEADING_MARGIN
           , FPG_WORK_MARGIN = aFPC_WORK_MARGIN
           , FPG_MATERIAL_MARGIN = aFPC_MATERIAL_MARGIN
           , FPG_MW_MARGIN = aFPC_MW_MARGIN
           , FPG_TOTAL_WITH_MARGIN = aFPC_TOTAL + aFPC_UNDERHEADING_MARGIN + aFPC_WORK_MARGIN + aFPC_MATERIAL_MARGIN + aFPC_MW_MARGIN + FPG_FIXED_COST
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_PRECALC_GOOD_ID = CurFalPrecalcGood.FAL_PRECALC_GOOD_ID;
    end loop;
  end CalcAllFields;

  -- Fonction de Formatage de la liste des séquences pour total (Structures de calcul)
  function GetRubricSequencesForTotal(aFAL_ADV_RATE_STRUCT_ID FAL_ADV_RATE_STRUCT.FAL_ADV_RATE_STRUCT_ID%type)
    return varchar2
  is
    cursor CUR_SEQUENCES_FOR_TOTAL
    is
      select   to_char(ARS.ARS_SEQUENCE) ARS_SEQUENCE
          from FAL_ADV_TOTAL_RATE ATR
             , FAL_ADV_RATE_STRUCT ARS
         where ATR.FAL_ADV_RATE_STRUCT_ID = aFAL_ADV_RATE_STRUCT_ID
           and ATR.FAL_FAL_ADV_RATE_STRUCT_ID = ARS.FAL_ADV_RATE_STRUCT_ID
      order by ARS.ARS_SEQUENCE;

    CurSequencesForTotal CUR_SEQUENCES_FOR_TOTAL%rowtype;
    aResult              varchar2(2000);
  begin
    aResult  := '';

    for CurSequencesForTotal in CUR_SEQUENCES_FOR_TOTAL loop
      aResult  := aResult || ',' || CurSequencesForTotal.ARS_SEQUENCE;
    end loop;

    return substr(aResult, 2);
  end GetRubricSequencesForTotal;

  -- Fonction de Formatage de la liste des séquences pour total (Structures de calcul)
  function GetRubricSequencesForPreCTotal(aFAL_ADV_RATE_STRUCT_ID FAL_ADV_RATE_STRUCT.FAL_ADV_RATE_STRUCT_ID%type)
    return varchar2
  is
    cursor CUR_SEQUENCES_FOR_TOTAL
    is
      select   to_char(ARS.ARS_SEQUENCE) ARS_SEQUENCE
          from FAL_ADV_TOTAL_RATE ATR
             , FAL_ADV_RATE_STRUCT ARS
         where ATR.FAL_ADV_RATE_STRUCT_ID = aFAL_ADV_RATE_STRUCT_ID
           and ATR.FAL_FAL_ADV_RATE_STRUCT_ID = ARS.FAL_ADV_RATE_STRUCT_ID(+)
           and (   ARS.C_BASIS_RUBRIC is null
                or ARS.C_BASIS_RUBRIC <> '5')
           and not exists(
                 select ARS2.FAL_ADV_RATE_STRUCT_ID
                   from FAL_ADV_RATE_STRUCT ARS2
                      , FAL_ADV_RATE_STRUCT ARS3
                  where ARS2.FAL_ADV_RATE_STRUCT_ID = ATR.FAL_FAL_ADV_RATE_STRUCT_ID
                    and (   ARS2.C_BASIS_RUBRIC is null
                         or ARS2.C_BASIS_RUBRIC = '')
                    and (ARS2.C_RUBRIC_TYPE = '2')
                    and ARS2.FAL_ADV_RATE_STRUCT1_ID = ARS3.FAL_ADV_RATE_STRUCT_ID
                    and ARS3.C_BASIS_RUBRIC = '5')
      order by ARS.ARS_SEQUENCE;

    CurSequencesForTotal CUR_SEQUENCES_FOR_TOTAL%rowtype;
    aResult              varchar2(2000);
  begin
    aResult  := '';

    for CurSequencesForTotal in CUR_SEQUENCES_FOR_TOTAL loop
      aResult  := aResult || ',' || CurSequencesForTotal.ARS_SEQUENCE;
    end loop;

    return substr(aResult, 2);
  end GetRubricSequencesForPreCTotal;

  -- Indique si la rubrique FAL_FAL_ADV_RATE_STRUCT_ID est utilisée comme total ou taux de FAL_ADV_RATE_STRUCT_ID
  function IsSequenceForTotalOrRate(
    aFAL_ADV_RATE_STRUCT_ID     FAL_ADV_RATE_STRUCT.FAL_ADV_RATE_STRUCT_ID%type
  , aFAL_FAL_ADV_RATE_STRUCT_ID FAL_ADV_RATE_STRUCT.FAL_ADV_RATE_STRUCT_ID%type
  , adestination                varchar2
  )
    return integer
  is
    aResult                integer;
    aFAL_ADV_TOTAL_RATE_ID number;
  begin
    if adestination = 'TOTAL' then
      select max(ATR.FAL_ADV_TOTAL_RATE_ID)
        into aFAL_ADV_TOTAL_RATE_ID
        from FAL_ADV_RATE_STRUCT ARS
           , FAL_ADV_TOTAL_RATE ATR
       where ARS.FAL_ADV_RATE_STRUCT_ID = aFAL_ADV_RATE_STRUCT_ID
         and ARS.FAL_ADV_RATE_STRUCT_ID = ATR.FAL_ADV_RATE_STRUCT_ID
         and ATR.FAL_FAL_ADV_RATE_STRUCT_ID = aFAL_FAL_ADV_RATE_STRUCT_ID;

      if     (aFAL_ADV_TOTAL_RATE_ID <> 0)
         and not(aFAL_ADV_TOTAL_RATE_ID is null) then
        return 1;
      else
        return 0;
      end if;
    elsif adestination = 'RATE' then
      select max(ARS.FAL_ADV_RATE_STRUCT_ID)
        into aFAL_ADV_TOTAL_RATE_ID
        from FAL_ADV_RATE_STRUCT ARS
       where ARS.FAL_ADV_RATE_STRUCT_ID = aFAL_ADV_RATE_STRUCT_ID
         and ARS.FAL_ADV_RATE_STRUCT1_ID = aFAL_FAL_ADV_RATE_STRUCT_ID;

      if     (aFAL_ADV_TOTAL_RATE_ID <> 0)
         and not(aFAL_ADV_TOTAL_RATE_ID is null) then
        return 1;
      else
        return 0;
      end if;
    else
      return 0;
    end if;
  exception
    when no_data_found then
      return 0;
  end IsSequenceForTotalOrRate;

  -- Suppression eventuelle d'enregistrement persistants dans les tables temporaires de MAJ des prix
  procedure ScanAndDeleteObsoleteCostP
  is
  begin
    delete from FAL_ADV_UPDATE_COSTPRICE
          where COM_FUNCTIONS.Is_Session_Alive(FAU_SESSION_ID) = 0;
  end ScanAndDeleteObsoleteCostP;

  /**
  * Fonction GetGoodDisplayedRef
  * Description: Renvoie la référence produit à afficher dans les calculations
  *
  * @author  ECA
  * @version 30.01.08
  * @public
  *
  * @param aGCO_GOOD_ID : bien
  * @return référence
  */
  function GetGoodDisplayedRef(aGCO_GOOD_ID number)
    return varchar2
  is
    aQry       varchar2(2000);
    aReference varchar2(61);
  begin
    -- Ref principale + description courte principale
    if PCS.PC_CONFIG.GETCONFIG('FAL_CALC_DISPLAY_REF') = '2' then
      aQry  :=
        ' SELECT GCO.GOO_MAJOR_REFERENCE || '' '' || DES.DES_SHORT_DESCRIPTION ' ||
        '   FROM GCO_GOOD GCO ' ||
        '      , GCO_DESCRIPTION DES ' ||
        '  WHERE GCO.GCO_GOOD_ID = :aGCO_GOOD_ID ' ||
        '    AND GCO.GCO_GOOD_ID = DES.GCO_GOOD_ID (+) ' ||
        '    AND DES.C_DESCRIPTION_TYPE (+) = ''01'' ' ||
        '    AND DES.PC_LANG_ID (+) = PCS.PC_PUBLIC.GETUSERLANGID';
    -- Ref principale + référence secondaire
    else
      aQry  :=
             ' SELECT GCO.GOO_MAJOR_REFERENCE || '' '' || GCO.GOO_SECONDARY_REFERENCE ' || '   FROM GCO_GOOD GCO ' || '  WHERE GCO.GCO_GOOD_ID = :aGCO_GOOD_ID';
    end if;

    execute immediate aQry
                 into aReference
                using aGCO_GOOD_ID;

    return aReference;
  exception
    when no_data_found then
      return PCS.PC_PUBLIC.TranslateWord('Référence inconnue!');
  end;

  /**
  * procedure InsertFixedCostprice
  * Description: Génération des prix calculés
  *
  * @author  ECA
  * @version 30.01.08
  * @lastUpdate KLA 25/11/2013
  * @public
  *
  * @param   aPTC_FIXED_COSTPRICE_ID : ID Prix de revient
  * @param   aGCO_GOOD_ID : Produit
  * @param   aDIC_FIXED_COSTPRICE_DESCR_ID : Type de prix de revient
  * @param   aC_COSTPRICE_STATUS : Status du prix
  * @param   aCPR_DEFAULT : Prix par défaut
  * @param   aCPR_DESCR : Description du prix
  * @param   aCPR_PRICE : Prix
  * @param   aFCP_OPTIONS : Détails prix
  * @param   aFCP_START_DATE : Date début validité
  * @param   aFCP_END_DATE : Date fin validité
  * @param   aLotRefCompl : Référence lot de fabrication
  * @return  aErrorCode : Erreur de mise à jour.
  */
  procedure InsertFixedCostprice(
    aPTC_FIXED_COSTPRICE_ID       in     number
  , aGCO_GOOD_ID                  in     number
  , aDIC_FIXED_COSTPRICE_DESCR_ID in     varchar2
  , aC_COSTPRICE_STATUS           in     varchar2
  , aCPR_DEFAULT                  in     integer default 0
  , aCPR_DESCR                    in     varchar2 default null
  , aCPR_PRICE                    in     number default 0
  , aFCP_OPTIONS                  in     clob default null
  , aFCP_START_DATE               in     date default null
  , aFCP_END_DATE                 in     date default null
  , aLotRefCompl                  in     varchar2
  , aErrorCode                    in out varchar2
  )
  is
  begin
    insert into PTC_FIXED_COSTPRICE
                (PTC_FIXED_COSTPRICE_ID
               , C_COSTPRICE_STATUS
               , GCO_GOOD_ID
               , CPR_DESCR
               , CPR_PRICE
               , CPR_DEFAULT
               , FCP_OPTIONS
               , FCP_START_DATE
               , FCP_END_DATE
               , DIC_FIXED_COSTPRICE_DESCR_ID
               , A_DATECRE
               , A_IDCRE
               , LOT_REFCOMPL
                )
         values (aPTC_FIXED_COSTPRICE_ID
               , nvl(aC_COSTPRICE_STATUS, 'ACT')
               , aGCO_GOOD_ID
               , aCPR_DESCR
               , aCPR_PRICE
               , aCPR_DEFAULT
               , aFCP_OPTIONS
               , aFCP_START_DATE
               , aFCP_END_DATE
               , aDIC_FIXED_COSTPRICE_DESCR_ID
               , sysdate
               , PCS.PC_I_LIB_SESSION.GETUSERINI
               , decode(aLotRefCompl, '<none>', '', aLotRefCompl)
                );
  exception
    when others then
      aErrorCode  := sqlcode || ' - ' || sqlerrm;
  end;

  /**
  * procedure InsertPRFCIDetail
  * Description : Dans le cadre de  l'utilisation de la comptabilité industrielle,
  *               insertion dans les tables du détail des éléments ayant servit au calcul
  *               du PRF ainsi que des éléments de coûts de celui-ci
  * @author  ECA
  * @version 30.01.08
  * @public
  *
  * @param   aPTC_FIXED_COSTPRICE_ID : Prix de revient fixe
  * @param   aSessionID : Session Oracle
  * @param   aGCO_GOOD_ID : Produit calculé
  * @param   aPPS_NOMENCLATURE_ID : Nomenclature du produit calculé
  * @param   aFAL_SCHEDULE_PLAN_ID : Gamme du produit calculé
  * @param   aFAL_ADV_STRUCT_CALC_ID : Structure de calcul
  * @param   aCPR_MANUFACTURE_ACCOUNTING : Flag Compta indus
  * @param   aGCO_COMPL_DATA_MANUFACTURE_ID : Donnée complémentaire de fabrication
  * @param   aGCO_COMPL_DATA_PURCHASE_ID : Donnée complémentaire d'achat
  * @param   aGCO_COMPL_DATA_SUBCONTRACT_ID : Donnée complémentaire de sous-traitance
  */
  procedure InsertPRFCIDetail(
    aPTC_FIXED_COSTPRICE_ID        in number
  , aSessionID                     in varchar2
  , aGCO_GOOD_ID                   in number
  , aPPS_NOMENCLATURE_ID           in number
  , aFAL_SCHEDULE_PLAN_ID          in number
  , aFAL_ADV_STRUCT_CALC_ID        in number
  , aCPR_MANUFACTURE_ACCOUNTING    in integer
  , aGCO_COMPL_DATA_MANUFACTURE_ID in number
  , aGCO_COMPL_DATA_PURCHASE_ID    in number
  , aGCO_COMPL_DATA_SUBCONTRACT_ID in number default null
  )
  is
    cursor crFAL_ADV_CALC_GOOD
    is
      select   CAG.GCO_GOOD_ID
             , CAG.GCO_CPT_GOOD_ID
             , CAG.C_SUPPLY_MODE
             , CAG.C_MANAGEMENT_MODE
             , CAG.CAG_INCREASE_COST
             , CAG.CAG_PRECIOUS_MAT
             , CAG.CAG_MP_INCREASE_COST
             , CAG.CAG_REJECT_PERCENT
             , CAG.CAG_REJECT_FIX_QTY
             , CAG.CAG_REJECT_REF_QTY
             , CAG.CAG_SCRAP_PERCENT
             , CAG.CAG_SCRAP_FIX_QTY
             , CAG.CAG_SCRAP_REF_QTY
             , CAG.CAG_NOM_COEF
             , CAG.CAG_NOM_REF_QTY
             , CAG.CAG_STANDARD_QTY
             , CAG.CAG_QUANTITY
             , CAG.CAG_PRICE
             , CAG.FAL_ADV_CALC_GOOD_ID
             , CAG.C_KIND_COM
             , CAG.CAG_SEQ
             , CAG.STM_STOCK_ID
             , CAG.STM_LOCATION_ID
          from FAL_ADV_CALC_GOOD CAG
         where CAG.CAG_SESSION_ID = aSessionID
           and CAG.GCO_GOOD_ID = aGCO_GOOD_ID
           and CAG.CAG_LEVEL <= 1
           and CAG.GCO_CPT_GOOD_ID is not null
      order by CAG.CAG_SEQ;

    cursor crFAL_ADV_CALC_TASK
    is
      select FAL_FACTORY_FLOOR_ID
           , FAL_FAL_FACTORY_FLOOR_ID
           , PAC_SUPPLIER_PARTNER_ID
           , GCO_GOOD_ID
           , C_SCHEDULE_PLANNING
           , C_TASK_IMPUTATION
           , C_TASK_TYPE
           , CAK_TASK_SEQ
           , CAK_ADJUSTING_TIME
           , CAK_WORK_TIME
           , CAK_AMOUNT
           , CAK_DIVISOR
           , CAK_MINUTE_RATE
           , CAK_MACH_RATE
           , CAK_MO_RATE
           , CAK_PERCENT_WORK_OPER
           , CAK_NUM_WORK_OPERATOR
           , CAK_WORK_OPERATOR
           , CAK_WORK_FLOOR
           , CAK_QTY_FIX_ADJUSTING
           , CAK_NUM_ADJUST_OPERATOR
           , CAK_ADJUSTING_OPERATOR
           , CAK_ADJUSTING_FLOOR
           , CAK_PERCENT_ADJUST_OPER
           , CAK_QTY_REF_WORK
           , CAK_WORK_RATE
           , CAK_ADJUSTING_RATE
           , FAL_ADV_CALC_TASK_ID
           , CAK_VALUE_DATE
           , FAL_TASK_ID
           , CAK_QTY_REF_AMOUNT
           , CAK_SCHED_WORK_TIME
           , CAK_SCHED_ADJUSTING_TIME
        from FAL_ADV_CALC_TASK
       where CAK_SESSION_ID = aSessionID
         and FAL_ADV_CALC_GOOD_ID = (select max(FAL_ADV_CALC_GOOD_ID)
                                       from FAL_ADV_CALC_GOOD
                                      where CAG_SESSION_ID = aSessionID
                                        and GCO_GOOD_ID = aGCO_GOOD_ID
                                        and GCO_GOOD_ID = GCO_CPT_GOOD_ID
                                        and CAG_LEVEL = 0);

    aPTC_USED_COMPONENT_ID number;
    aPTC_USED_TASK_ID      number;
    aNewID                 number;
    vC_SUPPLY_MODE         varchar2(10);
    vC_MANAGEMENT_MODE     varchar2(10);
    nPUC_SEQ               integer;
    nPDT_STOCK_MANAGEMENT  integer;
    aCOMPO_STOCK_ID        number;
    aCOMPO_LOCATION_ID     number;
    aPDT_STOCK_ID          number;
    aPDT_LOCATION_ID       number;
  begin
    -- Insertion du détail des composants et des éléments de coûts correspondants
    for tplFAL_ADV_CALC_GOOD in crFAL_ADV_CALC_GOOD loop
      if    tplFAL_ADV_CALC_GOOD.C_SUPPLY_MODE is null
         or tplFAL_ADV_CALC_GOOD.C_MANAGEMENT_MODE is null then
        begin
          select PDT.C_SUPPLY_MODE
               , GCO.C_MANAGEMENT_MODE
               , nvl(PDT.PDT_STOCK_MANAGEMENT, 0)
               , PDT.STM_STOCK_ID
               , PDT.STM_LOCATION_ID
            into vC_SUPPLY_MODE
               , vC_MANAGEMENT_MODE
               , nPDT_STOCK_MANAGEMENT
               , aPDT_STOCK_ID
               , aPDT_LOCATION_ID
            from GCO_GOOD GCO
               , GCO_PRODUCT PDT
           where GCO.GCO_GOOD_ID = nvl(tplFAL_ADV_CALC_GOOD.GCO_CPT_GOOD_ID, tplFAL_ADV_CALC_GOOD.GCO_GOOD_ID)
             and GCO.GCO_GOOD_ID = PDT.GCO_GOOD_ID;
        exception
          when others then
            begin
              vC_SUPPLY_MODE         := null;
              vC_MANAGEMENT_MODE     := null;
              nPDT_STOCK_MANAGEMENT  := null;
              aPDT_STOCK_ID          := null;
              aPDT_LOCATION_ID       := null;
            end;
        end;
      end if;

      -- Cascade de recherche des stocks
      GetStockAndLocation(aPdtStockManagement     => nPDT_STOCK_MANAGEMENT
                        , aNomStockId             => tplFAL_ADV_CALC_GOOD.STM_STOCK_ID
                        , aNomLocationId          => tplFAL_ADV_CALC_GOOD.STM_LOCATION_ID
                        , aProductStockId         => aPDT_STOCK_ID
                        , aProductLocationId      => aPDT_LOCATION_ID
                        , aBatchConsoStockId      => null
                        , aBatchConsoLocationId   => null
                        , aResultStockId          => aCOMPO_STOCK_ID
                        , aResultLocationId       => aCOMPO_LOCATION_ID
                         );

      -- Renumérotation des composants identique à l'of
      if tplFAL_ADV_CALC_GOOD.GCO_GOOD_ID <> tplFAL_ADV_CALC_GOOD.GCO_CPT_GOOD_ID then
        select nvl(max(PUC_SEQ), 0) + PCS.PC_CONFIG.GetConfig('FAL_COMPONENT_NUMBERING')
          into nPUC_SEQ
          from PTC_USED_COMPONENT
         where PTC_FIXED_COSTPRICE_ID = aPTC_FIXED_COSTPRICE_ID;
      else
        nPUC_SEQ            := null;
        aCOMPO_STOCK_ID     := null;
        aCOMPO_LOCATION_ID  := null;
      end if;

      insert into PTC_USED_COMPONENT
                  (PTC_USED_COMPONENT_ID
                 , PTC_FIXED_COSTPRICE_ID
                 , GCO_GOOD_ID
                 , GCO_GCO_GOOD_ID
                 , C_SUPPLY_MODE
                 , C_MANAGEMENT_MODE
                 , PUC_INCREASE_COST
                 , PUC_PRECIOUS_MAT
                 , PUC_MP_INCREASE_COST
                 , PUC_REJECT_PERCENT
                 , PUC_REJECT_FIX_QTY
                 , PUC_REJECT_REF_QTY
                 , PUC_SCRAP_PERCENT
                 , PUC_SCRAP_FIX_QTY
                 , PUC_SCRAP_REF_QTY
                 , PUC_UTIL_COEFF
                 , PUC_NOM_REF_QTY
                 , PUC_STANDARD_QTY
                 , PUC_CALCUL_QTY
                 , PUC_PRICE
                 , C_KIND_COM
                 , PUC_NUMBER_OF_DECIMAL
                 , PUC_SEQ
                 , STM_STOCK_ID
                 , STM_LOCATION_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 , aPTC_FIXED_COSTPRICE_ID
                 , (case
                      when tplFAL_ADV_CALC_GOOD.GCO_GOOD_ID = tplFAL_ADV_CALC_GOOD.GCO_CPT_GOOD_ID then tplFAL_ADV_CALC_GOOD.GCO_GOOD_ID
                      else null
                    end)
                 , (case
                      when tplFAL_ADV_CALC_GOOD.GCO_GOOD_ID = tplFAL_ADV_CALC_GOOD.GCO_CPT_GOOD_ID then null
                      else tplFAL_ADV_CALC_GOOD.GCO_CPT_GOOD_ID
                    end)
                 , nvl(tplFAL_ADV_CALC_GOOD.C_SUPPLY_MODE, vC_SUPPLY_MODE)
                 , nvl(tplFAL_ADV_CALC_GOOD.C_MANAGEMENT_MODE, vC_MANAGEMENT_MODE)
                 , tplFAL_ADV_CALC_GOOD.CAG_INCREASE_COST
                 , tplFAL_ADV_CALC_GOOD.CAG_PRECIOUS_MAT
                 , tplFAL_ADV_CALC_GOOD.CAG_MP_INCREASE_COST
                 , tplFAL_ADV_CALC_GOOD.CAG_REJECT_PERCENT
                 , tplFAL_ADV_CALC_GOOD.CAG_REJECT_FIX_QTY
                 , tplFAL_ADV_CALC_GOOD.CAG_REJECT_REF_QTY
                 , tplFAL_ADV_CALC_GOOD.CAG_SCRAP_PERCENT
                 , tplFAL_ADV_CALC_GOOD.CAG_SCRAP_FIX_QTY
                 , tplFAL_ADV_CALC_GOOD.CAG_SCRAP_REF_QTY
                 , tplFAL_ADV_CALC_GOOD.CAG_NOM_COEF
                 , tplFAL_ADV_CALC_GOOD.CAG_NOM_REF_QTY
                 , tplFAL_ADV_CALC_GOOD.CAG_STANDARD_QTY
                 , tplFAL_ADV_CALC_GOOD.CAG_QUANTITY
                 , tplFAL_ADV_CALC_GOOD.CAG_PRICE
                 , tplFAL_ADV_CALC_GOOD.C_KIND_COM
                 , FAL_TOOLS.GetGoo_Number_Of_Decimal(nvl(tplFAL_ADV_CALC_GOOD.GCO_CPT_GOOD_ID, tplFAL_ADV_CALC_GOOD.GCO_GOOD_ID) )
                 , nPUC_SEQ
                 , aCOMPO_STOCK_ID
                 , aCOMPO_LOCATION_ID
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GETUSERINI
                  )
        returning PTC_USED_COMPONENT_ID
             into aPTC_USED_COMPONENT_ID;

      -- pas de coût matière pour le produit terminé
      if tplFAL_ADV_CALC_GOOD.GCO_GOOD_ID <> tplFAL_ADV_CALC_GOOD.GCO_CPT_GOOD_ID then
        -- Si composant non pseudo
        if tplFAL_ADV_CALC_GOOD.C_KIND_COM <> '3' then
          -- Insertion des éléments de couts de type Matière des composants de premier niveaux
          -- (Incluant le travail, dans le cas de composants étant fabriqué)
          aNewID  := GetNewId;

          insert into PTC_ELEMENT_COST
                      (PTC_ELEMENT_COST_ID
                     , PTC_FIXED_COSTPRICE_ID
                     , PTC_USED_COMPONENT_ID
                     , C_COST_ELEMENT_TYPE
                     , ELC_AMOUNT
                     , A_DATECRE
                     , A_IDCRE
                      )
            select   aNewID
                   , aPTC_FIXED_COSTPRICE_ID
                   , aPTC_USED_COMPONENT_ID
                   , 'MAT'
                   , sum(CAV_VALUE)
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GETUSERINI
                from FAL_ADV_CALC_STRUCT_VAL
               where (    tplFAL_ADV_CALC_GOOD.GCO_GOOD_ID <> tplFAL_ADV_CALC_GOOD.GCO_CPT_GOOD_ID
                      and C_COST_ELEMENT_TYPE in('MAT', 'TMA', 'TMO', 'SST')
                      and FAL_ADV_CALC_GOOD_ID in(select     FAL_ADV_CALC_GOOD_ID
                                                        from FAL_ADV_CALC_GOOD CAV
                                                       where GCO_CPT_GOOD_ID is not null
                                                  start with FAL_ADV_CALC_GOOD_ID = tplFAL_ADV_CALC_GOOD.FAL_ADV_CALC_GOOD_ID
                                                  connect by prior FAL_ADV_CALC_GOOD_ID = FAL_PARENT_ADV_CALC_GOOD_ID)
                     )
                  or (    tplFAL_ADV_CALC_GOOD.GCO_GOOD_ID = tplFAL_ADV_CALC_GOOD.GCO_CPT_GOOD_ID
                      and C_COST_ELEMENT_TYPE = 'MAT'
                      and not exists(select 1
                                       from FAL_ADV_CALC_GOOD CAG2
                                      where FAL_PARENT_ADV_CALC_GOOD_ID = tplFAL_ADV_CALC_GOOD.FAL_ADV_CALC_GOOD_ID)
                      and FAL_ADV_CALC_GOOD_ID in(select     FAL_ADV_CALC_GOOD_ID
                                                        from FAL_ADV_CALC_GOOD CAV
                                                       where GCO_CPT_GOOD_ID is not null
                                                  start with FAL_ADV_CALC_GOOD_ID = tplFAL_ADV_CALC_GOOD.FAL_ADV_CALC_GOOD_ID
                                                  connect by prior FAL_ADV_CALC_GOOD_ID = FAL_PARENT_ADV_CALC_GOOD_ID)
                     )
            group by aNewID
                   , aPTC_FIXED_COSTPRICE_ID
                   , aPTC_USED_COMPONENT_ID
                   , 'MAT'
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GETUSERINI;
        -- Si Composant pseudo, on descends sa nomenclature jusqu'au bout afin d'y intégrer ses propres composants, sous
        -- l'élément de coûts matière.
        else
          InsertPseudoCostElements(tplFAL_ADV_CALC_GOOD.FAL_ADV_CALC_GOOD_ID, aSessionID, aPTC_FIXED_COSTPRICE_ID);
        end if;
      end if;
    end loop;

    -- Insertion du détail des opérations de la gamme du produit calculé
    -- ainsi que ses éléments de coûts correspondants
    for tplFAL_ADV_CALC_TASK in crFAL_ADV_CALC_TASK loop
      insert into PTC_USED_TASK
                  (PTC_USED_TASK_ID
                 , PTC_FIXED_COSTPRICE_ID
                 , FAL_FACTORY_FLOOR_ID
                 , FAL_FAL_FACTORY_FLOOR_ID
                 , PAC_SUPPLIER_PARTNER_ID
                 , GCO_GOOD_ID
                 , C_SCHEDULE_PLANNING
                 , C_TASK_IMPUTATION
                 , C_TASK_TYPE
                 , PUT_STEP_NUMBER
                 , PUT_ADJUSTING_TIME
                 , PUT_WORK_TIME
                 , PUT_AMOUNT
                 , PUT_DIVISOR
                 , PUT_MINUTE_RATE
                 , PUT_MACH_RATE
                 , PUT_MO_RATE
                 , PUT_PERCENT_WORK_OPER
                 , PUT_NUM_WORK_OPERATOR
                 , PUT_WORK_OPERATOR
                 , PUT_WORK_FLOOR
                 , PUT_QTY_FIX_ADJUSTING
                 , PUT_NUM_ADJUST_OPERATOR
                 , PUT_ADJUSTING_OPERATOR
                 , PUT_ADJUSTING_FLOOR
                 , PUT_PERCENT_ADJUST_OPER
                 , PUT_QTY_REF_WORK
                 , PUT_WORK_RATE
                 , PUT_ADJUSTING_RATE
                 , FAL_TASK_ID
                 , PUT_VALUE_DATE
                 , PUT_QTY_REF_AMOUNT
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 , aPTC_FIXED_COSTPRICE_ID
                 , tplFAL_ADV_CALC_TASK.FAL_FACTORY_FLOOR_ID
                 , tplFAL_ADV_CALC_TASK.FAL_FAL_FACTORY_FLOOR_ID
                 , tplFAL_ADV_CALC_TASK.PAC_SUPPLIER_PARTNER_ID
                 , tplFAL_ADV_CALC_TASK.GCO_GOOD_ID
                 , tplFAL_ADV_CALC_TASK.C_SCHEDULE_PLANNING
                 , tplFAL_ADV_CALC_TASK.C_TASK_IMPUTATION
                 , tplFAL_ADV_CALC_TASK.C_TASK_TYPE
                 , tplFAL_ADV_CALC_TASK.CAK_TASK_SEQ
                 , tplFAL_ADV_CALC_TASK.CAK_SCHED_ADJUSTING_TIME
                 , tplFAL_ADV_CALC_TASK.CAK_SCHED_WORK_TIME
                 , tplFAL_ADV_CALC_TASK.CAK_AMOUNT
                 , tplFAL_ADV_CALC_TASK.CAK_DIVISOR
                 , tplFAL_ADV_CALC_TASK.CAK_MINUTE_RATE
                 , tplFAL_ADV_CALC_TASK.CAK_MACH_RATE
                 , tplFAL_ADV_CALC_TASK.CAK_MO_RATE
                 , tplFAL_ADV_CALC_TASK.CAK_PERCENT_WORK_OPER
                 , tplFAL_ADV_CALC_TASK.CAK_NUM_WORK_OPERATOR
                 , tplFAL_ADV_CALC_TASK.CAK_WORK_OPERATOR
                 , tplFAL_ADV_CALC_TASK.CAK_WORK_FLOOR
                 , tplFAL_ADV_CALC_TASK.CAK_QTY_FIX_ADJUSTING
                 , tplFAL_ADV_CALC_TASK.CAK_NUM_ADJUST_OPERATOR
                 , tplFAL_ADV_CALC_TASK.CAK_ADJUSTING_OPERATOR
                 , tplFAL_ADV_CALC_TASK.CAK_ADJUSTING_FLOOR
                 , tplFAL_ADV_CALC_TASK.CAK_PERCENT_ADJUST_OPER
                 , tplFAL_ADV_CALC_TASK.CAK_QTY_REF_WORK
                 , tplFAL_ADV_CALC_TASK.CAK_WORK_RATE
                 , tplFAL_ADV_CALC_TASK.CAK_ADJUSTING_RATE
                 , tplFAL_ADV_CALC_TASK.FAL_TASK_ID
                 , tplFAL_ADV_CALC_TASK.CAK_VALUE_DATE
                 , tplFAL_ADV_CALC_TASK.CAK_QTY_REF_AMOUNT
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GETUSERINI
                  )
        returning PTC_USED_TASK_ID
             into aPTC_USED_TASK_ID;

      -- Insertion des éléments de coûts de type Travail machine
      insert into PTC_ELEMENT_COST
                  (PTC_ELEMENT_COST_ID
                 , PTC_FIXED_COSTPRICE_ID
                 , PTC_USED_TASK_ID
                 , C_COST_ELEMENT_TYPE
                 , ELC_AMOUNT
                 , A_DATECRE
                 , A_IDCRE
                  )
        select GetNewId
             , aPTC_FIXED_COSTPRICE_ID
             , aPTC_USED_TASK_ID
             , 'TMA'
             , CAK_MACHINE_COST
             , sysdate
             , PCS.PC_I_LIB_SESSION.GETUSERINI
          from FAL_ADV_CALC_TASK
         where FAL_ADV_CALC_TASK_ID = tplFAL_ADV_CALC_TASK.FAL_ADV_CALC_TASK_ID
           and C_TASK_TYPE = '1';

      -- Insertion des éléments de coûts de type Travail machine
      insert into PTC_ELEMENT_COST
                  (PTC_ELEMENT_COST_ID
                 , PTC_FIXED_COSTPRICE_ID
                 , PTC_USED_TASK_ID
                 , C_COST_ELEMENT_TYPE
                 , ELC_AMOUNT
                 , A_DATECRE
                 , A_IDCRE
                  )
        select GetNewId
             , aPTC_FIXED_COSTPRICE_ID
             , aPTC_USED_TASK_ID
             , 'TMO'
             , CAK_HUMAN_COST
             , sysdate
             , PCS.PC_I_LIB_SESSION.GETUSERINI
          from FAL_ADV_CALC_TASK
         where FAL_ADV_CALC_TASK_ID = tplFAL_ADV_CALC_TASK.FAL_ADV_CALC_TASK_ID
           and C_TASK_TYPE = '1';

      -- Insertion des éléments de coûts de type Travail machine
      insert into PTC_ELEMENT_COST
                  (PTC_ELEMENT_COST_ID
                 , PTC_FIXED_COSTPRICE_ID
                 , PTC_USED_TASK_ID
                 , C_COST_ELEMENT_TYPE
                 , ELC_AMOUNT
                 , A_DATECRE
                 , A_IDCRE
                  )
        select GetNewId
             , aPTC_FIXED_COSTPRICE_ID
             , aPTC_USED_TASK_ID
             , 'SST'
             , CAK_HUMAN_COST + CAK_MACHINE_COST
             , sysdate
             , PCS.PC_I_LIB_SESSION.GETUSERINI
          from FAL_ADV_CALC_TASK
         where FAL_ADV_CALC_TASK_ID = tplFAL_ADV_CALC_TASK.FAL_ADV_CALC_TASK_ID
           and C_TASK_TYPE = '2';

      -- Mise à jour des taux Machine ateliers utilsés dans ce calcul de PRF
      update FAL_FACTORY_RATE
         set FFR_USED_IN_PRECALC_FIN = 1
       where FAL_FACTORY_RATE_ID =
               (select max(FAL_FACTORY_RATE_ID)
                  from fal_factory_rate ffr
                 where ffr.fal_factory_floor_id = tplFAL_ADV_CALC_TASK.FAL_FACTORY_FLOOR_ID
                   and trunc(ffr.ffr_validity_date) =
                         (select max(trunc(ffr2.ffr_validity_date) )
                            from fal_factory_rate ffr2
                           where trunc(ffr2.ffr_validity_date) <= trunc(tplFAL_ADV_CALC_TASK.CAK_VALUE_DATE)
                             and ffr2.fal_factory_floor_id = tplFAL_ADV_CALC_TASK.FAL_FACTORY_FLOOR_ID) );

      -- Mise à jour des taux réglage opérateur utilsés dans ce calcul de PRF
      if     tplFAL_ADV_CALC_TASK.C_SCHEDULE_PLANNING = '3'
         and tplFAL_ADV_CALC_TASK.FAL_FAL_FACTORY_FLOOR_ID is not null then
        update FAL_FACTORY_RATE
           set FFR_USED_IN_PRECALC_FIN = 1
         where FAL_FACTORY_RATE_ID =
                 (select max(FAL_FACTORY_RATE_ID)
                    from fal_factory_rate ffr
                   where ffr.fal_factory_floor_id = tplFAL_ADV_CALC_TASK.FAL_FAL_FACTORY_FLOOR_ID
                     and trunc(ffr.ffr_validity_date) =
                           (select max(trunc(ffr2.ffr_validity_date) )
                              from fal_factory_rate ffr2
                             where trunc(ffr2.ffr_validity_date) <= trunc(tplFAL_ADV_CALC_TASK.CAK_VALUE_DATE)
                               and ffr2.fal_factory_floor_id = tplFAL_ADV_CALC_TASK.FAL_FAL_FACTORY_FLOOR_ID) );
      end if;
    end loop;

    -- Mise à jour du prix avec les informations supplémentaires, nomenclature, gamme ...etc
    update PTC_FIXED_COSTPRICE
       set PPS_NOMENCLATURE_ID = aPPS_NOMENCLATURE_ID
         , FAL_SCHEDULE_PLAN_ID = aFAL_SCHEDULE_PLAN_ID
         , FAL_ADV_STRUCT_CALC_ID = aFAL_ADV_STRUCT_CALC_ID
         , CPR_MANUFACTURE_ACCOUNTING = aCPR_MANUFACTURE_ACCOUNTING
         , GCO_COMPL_DATA_MANUFACTURE_ID = aGCO_COMPL_DATA_MANUFACTURE_ID
         , GCO_COMPL_DATA_PURCHASE_ID = aGCO_COMPL_DATA_PURCHASE_ID
         , GCO_COMPL_DATA_SUBCONTRACT_ID = aGCO_COMPL_DATA_SUBCONTRACT_ID
         , C_COSTPRICE_STATUS = 'FUT'
         , CPR_CALCUL_DATE = sysdate
     where PTC_FIXED_COSTPRICE_ID = aPTC_FIXED_COSTPRICE_ID;
  exception
    when others then
      raise;
  end;
end;
