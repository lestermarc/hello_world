--------------------------------------------------------
--  DDL for Package Body FAL_CALCUL_BESOIN
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_CALCUL_BESOIN" 
is
  EnrFAL_LIST_STEP_LINK FAL_LIST_STEP_LINK%rowtype;

  procedure GetEnrFAl_LIST_STEP_LINK(PrmScheduleStepId PCS_PK_ID)
  is
    cursor C1(PrmScheduleStepId PCS_PK_ID)
    is
      select *
        from FAL_LIST_STEP_LINK
       where FAL_SCHEDULE_STEP_ID = PrmScheduleStepID;
  begin
    open C1(PrmScheduleStepID);

    fetch C1
     into EnrFAL_LIST_STEP_LINK;

    close C1;
  end;

  /**
  * function GetStockPositionCursor
  * Description : retourne le curseur sur la liste des stock qui correspond à la date d'un besoin pour un article et une liste de strock
  */
  procedure GetStockPositionCursor(
    iGoodId                     STM_STOCK_POSITION.GCO_GOOD_ID%type
  , iListStockId                varchar2
  , iCheckPeremption            number := null
  , iLapsingMarge               number := null
  , iDateRecept                 date := trunc(sysdate)
  , io_cur_StockPosition in out tcur_StockPosition
  )
  is
  begin
    open io_cur_StockPosition for
      select   *
          from (select SPO.GCO_GOOD_ID
                     , SPO.STM_STOCK_ID
                     , SPO.GCO_CHARACTERIZATION_ID
                     , SPO.GCO_GCO_CHARACTERIZATION_ID
                     , SPO.GCO2_GCO_CHARACTERIZATION_ID
                     , SPO.GCO3_GCO_CHARACTERIZATION_ID
                     , SPO.GCO4_GCO_CHARACTERIZATION_ID
                     , fal_tools.NullForNoMorpho(SPO.GCO_CHARACTERIZATION_ID, SPO.SPO_CHARACTERIZATION_VALUE_1) SPO_CHARACTERIZATION_VALUE_1
                     , fal_tools.NullForNoMorpho(SPO.GCO_GCO_CHARACTERIZATION_ID, SPO.SPO_CHARACTERIZATION_VALUE_2) SPO_CHARACTERIZATION_VALUE_2
                     , fal_tools.NullForNoMorpho(SPO.GCO2_GCO_CHARACTERIZATION_ID, SPO.SPO_CHARACTERIZATION_VALUE_3) SPO_CHARACTERIZATION_VALUE_3
                     , fal_tools.NullForNoMorpho(SPO.GCO3_GCO_CHARACTERIZATION_ID, SPO.SPO_CHARACTERIZATION_VALUE_4) SPO_CHARACTERIZATION_VALUE_4
                     , fal_tools.NullForNoMorpho(SPO.GCO4_GCO_CHARACTERIZATION_ID, SPO.SPO_CHARACTERIZATION_VALUE_5) SPO_CHARACTERIZATION_VALUE_5
                     , nvl(SPO.SPO_AVAILABLE_QUANTITY, 0) + nvl(SPO.SPO_PROVISORY_INPUT, 0) AVAILABLE_QUANTITY
                     , FAL_CALCUL_BESOIN.IsStockPosAvailable(iGoodId            => SPO.GCO_GOOD_ID
                                                           , iPiece             => SPO.SPO_PIECE
                                                           , iSet               => SPO.SPO_SET
                                                           , iVersion           => SPO.SPO_VERSION
                                                           , iChronological     => SPO.SPO_CHRONOLOGICAL
                                                           , iQualityStatusId   => SEM.GCO_QUALITY_STATUS_ID
                                                           , iDateRequest       => iDateRecept
                                                           , iCheckPeremption   => iCheckPeremption
                                                           , iLapsingMarge      => iLapsingMarge
                                                            ) VALIDITY_DATE
                  from STM_STOCK_POSITION SPO
                     , STM_ELEMENT_NUMBER SEM
                 where SPO.GCO_GOOD_ID = iGoodId
                   and instr(iListStockId, ',' || trim(SPO.STM_STOCK_ID) || ',') > 0
                   and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = SEM.STM_ELEMENT_NUMBER_ID(+))
         where VALIDITY_DATE is not null
      order by STM_STOCK_ID
             , GCO_CHARACTERIZATION_ID
             , GCO_GCO_CHARACTERIZATION_ID
             , GCO2_GCO_CHARACTERIZATION_ID
             , GCO3_GCO_CHARACTERIZATION_ID
             , GCO4_GCO_CHARACTERIZATION_ID
             , SPO_CHARACTERIZATION_VALUE_1
             , SPO_CHARACTERIZATION_VALUE_2
             , SPO_CHARACTERIZATION_VALUE_3
             , SPO_CHARACTERIZATION_VALUE_4
             , SPO_CHARACTERIZATION_VALUE_5
             , VALIDITY_DATE;
  end GetStockPositionCursor;

  function IsStockPosAvailable(
    iGoodId          STM_STOCK_POSITION.GCO_GOOD_ID%type
  , iPiece           STM_STOCK_POSITION.SPO_PIECE%type
  , iSet             STM_STOCK_POSITION.SPO_SET%type
  , iVersion         STM_STOCK_POSITION.SPO_VERSION%type
  , iChronological   STM_STOCK_POSITION.SPO_CHRONOLOGICAL%type
  , iQualityStatusId STM_ELEMENT_NUMBER.GCO_QUALITY_STATUS_ID%type
  , iDateRequest     date := sysdate
  , iCheckPeremption number := null
  , iLapsingMarge    number := null
  )
    return date
  is
    lReturn date;
  begin
    lReturn  :=
      STM_I_LIB_MOVEMENT.VerifyForecastStockPosCond(iGoodId            => iGoodId
                                                  , iPiece             => iPiece
                                                  , iSet               => iSet
                                                  , iVersion           => iVersion
                                                  , iChronological     => iChronological
                                                  , iQualityStatusId   => iQualityStatusId
                                                  , iElementNumberId   => null
                                                  , iDateRequest       => iDateRequest
                                                  , iCheckPeremption   => iCheckPeremption
                                                  , iLapsingMarge      => iLapsingMarge
                                                   );
    return lReturn;
  end IsStockPosAvailable;

----------------------------------------------------------------------------------------------------
-- La qte Dispo sur stock est-elle supérieure au "Point de commande" du produit pour un stock donné
-- Rappel: Nous avons une contrainte qui dit que de toute façon "Qté Point de commande" >= "Qté stock minimum"
----------------------------------------------------------------------------------------------------
  function StockSuffisant(
    PrmGCO_GOOD_ID       GCO_GOOD.GCO_GOOD_ID%type
  , PrmSTM_STOCK_ID      STM_STOCK.STM_STOCK_ID%type
  , PrmCST_TRIGGER_POINT number
  , PrmDateRequest       date := sysdate
  )
    return boolean
  is
    N number;
  begin
    select count(*)
      into N
      from STM_STOCK_POSITION SPO
         , STM_ELEMENT_NUMBER SEM
     where SPO.STM_STOCK_ID = PrmSTM_STOCK_ID
       and SPO.GCO_GOOD_ID = PrmGCO_GOOD_ID
       and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = SEM.STM_ELEMENT_NUMBER_ID(+)
       and IsStockPosAvailable(iGoodId            => SPO.GCO_GOOD_ID
                             , iPiece             => SPO.SPO_PIECE
                             , iSet               => SPO.SPO_SET
                             , iVersion           => SPO.SPO_VERSION
                             , iChronological     => SPO.SPO_CHRONOLOGICAL
                             , iQualityStatusId   => SEM.GCO_QUALITY_STATUS_ID
                             , iDateRequest       => PrmDateRequest
                              ) is not null
    having sum(nvl(SPO.SPO_AVAILABLE_QUANTITY, 0) + nvl(SPO.SPO_PROVISORY_INPUT, 0) ) >= nvl(PrmCST_TRIGGER_POINT, 0);

    return N > 0;
  exception
    when no_data_found then
      return false;
  end;

  /****
  * function IsStockSuffisant
  * Description : Indique si le stock est suffisant pour couvrir les besoins liés aux données
  *               complémentaires de stock
  * @author ECA
  * @public
  * @param   PrmGCO_GOOD_ID : Produit
  * @param   PrmSTM_STOCK_ID : Stock
  * @param   PrmCST_TRIGGER_POINT : Point de cocmmande.
  */
  function IsStockSuffisant(
    PrmGCO_GOOD_ID       GCO_GOOD.GCO_GOOD_ID%type
  , PrmSTM_STOCK_ID      STM_STOCK.STM_STOCK_ID%type
  , PrmCST_TRIGGER_POINT number
  , PrmDateRequest       date := sysdate
  )
    return integer
  is
    result boolean;
  begin
    if PrmCST_TRIGGER_POINT > 0 then
      result  := StockSuffisant(PrmGCO_GOOD_ID, PrmSTM_STOCK_ID, PrmCST_TRIGGER_POINT, PrmDateRequest);

      if result = true then
        return 1;
      else
        return 0;
      end if;
    else
      return 1;
    end if;
  end;

  /****
  * function MustDoProduct
  * Description : Permet de savoir s'il est utile de traiter ce GoodId dans le calcul des besoins
  * @author ECA
  * @public
  * @param  aGoodID : Produit CB en cours de traitement
  * @param  StockListIn : Paramètre CB -> Liste des stocks sélectionnés
  * @param  aDoReconstructionAttrib : Paramètre CB -> Reconstruction attribution
  * @param  aSuppAttrExistOnPdtFullTrac : Paramètre CB -> Suppr"ssion préalables des attribs
  * @param  AttribSurApproSiMargeNegative : Paramètre CB -> Attrib sur Appro même si marge neg.
  */
  function MustDoProduct(
    aGoodID                       GCO_GOOD.GCO_GOOD_ID%type
  , StockListIn                   varchar
  , aDoReconstructionAttrib       number
  , aSuppAttrExistOnPdtFullTrac   number
  , AttribSurApproSiMargeNegative number
  )
    return boolean
  is
    nNeedCount number;
    vQuery     varchar(32000);
  begin
    -- Recherche de l'existence d'un besoin
    vQuery  := ' select count(*) from FAL_NETWORK_NEED where GCO_GOOD_ID = :GCO_GOOD_ID and STM_STOCK_ID in (' || StockListIn || ')';

    if    (    aDoReconstructionAttrib = 0
           and aSuppAttrExistOnPdtFullTrac = 0)
       or (    aDoReconstructionAttrib = 1
           and AttribSurApproSiMargeNegative = 1) then
      vQuery  := vQuery || ' and FAN_FREE_QTY > 0';
    end if;

    execute immediate vQuery
                 into nNeedCount
                using aGoodID;

    return(nNeedCount > 0);
  end;

  /****
  * function MustDoProduct
  * Description : Permet de savoir s'il est utile de traiter ce GoodId dans le calcul des besoins
  * @author ECA
  * @public
  * @param  aGoodID : Produit CB en cours de traitement
  * @param  StockListIn : Paramètre CB -> Liste des stocks sélectionnés
  * @param  aDoReconstructionAttrib : Paramètre CB -> Reconstruction attribution
  * @param  aSuppAttrExistOnPdtFullTrac : Paramètre CB -> Suppr"ssion préalables des attribs
  * @param  AttribSurApproSiMargeNegative : Paramètre CB -> Attrib sur Appro même si marge neg.
  */
  procedure MustDoProduct(
    aGoodID                           GCO_GOOD.GCO_GOOD_ID%type
  , StockListIn                       varchar
  , aDoReconstructionAttrib           number
  , aSuppAttrExistOnPdtFullTrac       number
  , AttribSurApproSiMargeNegative     number
  , aResult                       out integer
  )
  is
  begin
    if MustDoProduct(aGoodID, StockListIn, aDoReconstructionAttrib, aSuppAttrExistOnPdtFullTrac, AttribSurApproSiMargeNegative) then
      aResult  := 1;
    else
      aResult  := 0;
    end if;
  end;

  /****
  * function Graph_GestionDecalageStockMini
  * Description : Calcul du décalage stock mini afin de savoir s'il est nécessaire d'approvisionner
  *               ou pas , et de combien, pour subvenir aux données complémentaires de stock.
  * @author ECA
  * @public
  */
  procedure Graph_GestionDecalageStockMini(
    PrmGCO_GOOD_ID                     GCO_GOOD.GCO_GOOD_ID%type
  , PrmCalculDate                      date
  , PrmCBDecalage                      GCO_COMPL_DATA_MANUFACTURE.CMA_SHIFT%type
  , PrmCBSupplyMode                    GCO_PRODUCT.C_SUPPLY_MODE%type
  , PrmCBSupplyDelay                   number
  , PrmCBStandardLotQty                GCO_COMPL_DATA_MANUFACTURE.CMA_LOT_QUANTITY%type
  , PrmMinStkItemNeedMinStock          number
  , PrmMinStkItemNeedPtCde             number
  , PrmMinStkSTM_STOCK_ID              STM_STOCk.STM_STOCK_ID%type
  , gStockMinCurrStkItemStockID        STM_STOCk.STM_STOCK_ID%type
  , PrmMinStkCharactID1                FAL_NETWORK_SUPPLY.GCO_CHARACTERIZATION1_ID%type
  , PrmMinStkCharactID2                FAL_NETWORK_SUPPLY.GCO_CHARACTERIZATION2_ID%type
  , PrmMinStkCharactID3                FAL_NETWORK_SUPPLY.GCO_CHARACTERIZATION3_ID%type
  , PrmMinStkCharactID4                FAL_NETWORK_SUPPLY.GCO_CHARACTERIZATION4_ID%type
  , PrmMinStkCharactID5                FAL_NETWORK_SUPPLY.GCO_CHARACTERIZATION5_ID%type
  , PrmCharacterizationValue1          FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type
  , PrmCharacterizationValue2          FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE2%type
  , PrmCharacterizationValue3          FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE3%type
  , PrmCharacterizationValue4          FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE4%type
  , PrmCharacterizationValue5          FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE5%type
  , PrmStockListIn                     varchar
  , iUseMasterPlanProcurements         integer
  , outFAL_NETWORK_SUPPLY_ID    in out FAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID%type
  , outB                        in out FAL_NETWORK_SUPPLY.FAN_STK_QTY%type
  , outC                        in out FAL_NETWORK_SUPPLY.FAN_STK_QTY%type
  , result                      out    integer
  )
  is
    aDecalage              GCO_COMPL_DATA_MANUFACTURE.CMA_SHIFT%type;
    aFloatDecalage         GCO_COMPL_DATA_MANUFACTURE.CMA_SHIFT%type;
    aEndDate               date;
    AuMoinsUne             boolean;
    aFAL_NETWORK_SUPPLY_ID FAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID%type;
    aFAN_STK_QTY           FAL_NETWORK_SUPPLY.FAN_STK_QTY%type;
    aFAN_FREE_QTY          FAL_NETWORK_SUPPLY.FAN_FREE_QTY%type;
    aFAN_END_PLAN          FAL_NETWORK_SUPPLY.FAN_END_PLAN%type;
    QTE_LIBERE             FAL_NETWORK_SUPPLY.FAN_NETW_QTY%type;
    aFAL_NETWORK_LINK_ID   FAL_NETWORK_LINK.FAL_NETWORK_LINK_ID%type;
    aFAL_NETWORK_NEED_ID   FAL_NETWORK_LINK.FAL_NETWORK_NEED_ID%type;
    aSTM_STOCK_POSITION_ID FAL_NETWORK_LINK.STM_STOCK_POSITION_ID%type;
    aSTM_LOCATION_ID       FAL_NETWORK_LINK.STM_LOCATION_ID%type;
    aFLN_QTY               FAL_NETWORK_LINK.FLN_QTY%type;
    aSTM_STOCK_ID          STM_STOCK.STM_STOCK_ID%type;

    cursor CAppro1
    is
      select FLN_QTY
        from FAL_NETWORK_LINK L
       where STM_LOCATION_ID in(select STM_LOCATION_ID
                                  from STM_LOCATION
                                 where STM_STOCK_ID = PrmMinStkSTM_STOCK_ID)
         and FAL_NETWORK_SUPPLY_ID is not null
         and exists(select 1
                      from FAL_NETWORK_SUPPLY S
                     where L.FAL_NETWORK_SUPPLY_ID = S.FAL_NETWORK_SUPPLY_ID
                       and GCO_GOOD_ID = PrmGCO_GOOD_ID);

    cursor CAppro2
    is
      select   FAL_NETWORK_SUPPLY_ID
             , FAN_FREE_QTY
             , FAN_END_PLAN
          from FAL_NETWORK_SUPPLY FNS
         where GCO_GOOD_ID = PrmGCO_GOOD_ID
           and trunc(FAN_END_PLAN) <= trunc(sysdate)
           and FAN_FREE_QTY > 0
           and STM_STOCK_ID = PrmMinStkSTM_STOCK_ID
           -- Et qui ne sont pas des POT
           and (   DOC_GAUGE_ID is null
                or DOC_GAUGE_ID not in(select DOC_GAUGE_ID
                                         from FAL_PROP_DEF
                                        where C_PROP_TYPE = '4') )
           and   -- On tient compte des appros du plan directeur
               (    (iUseMasterPlanProcurements = 1)
                -- On ne tient compte des appros du plan directeur
                or (    (select FAL_PIC_ID
                           from FAL_LOT_PROP PROP
                          where PROP.FAL_LOT_PROP_ID = FNS.FAL_LOT_PROP_ID) is null
                    and (select FAL_PIC_ID
                           from FAL_DOC_PROP PROP
                          where PROP.FAL_DOC_PROP_ID = FNS.FAL_DOC_PROP_ID) is null)
               )
      order by trunc(FAN_END_PLAN)
             , FAL_NETWORK_SUPPLY_ID;

    cursor CAppro3
    is
      select   FAL_NETWORK_SUPPLY_ID
             , STM_STOCK_ID
          from FAL_NETWORK_SUPPLY FNS
         where GCO_GOOD_ID = PrmGCO_GOOD_ID
           and trunc(FAN_END_PLAN) <= trunc(sysdate)
           and FAN_NETW_QTY > 0
           and (   DOC_GAUGE_ID is null
                or DOC_GAUGE_ID not in(select DOC_GAUGE_ID
                                         from FAL_PROP_DEF
                                        where C_PROP_TYPE = '4') )
           and   -- On tient compte des appros du plan directeur
               (    (iUseMasterPlanProcurements = 1)
                -- On ne tient compte des appros du plan directeur
                or (    (select FAL_PIC_ID
                           from FAL_LOT_PROP PROP
                          where PROP.FAL_LOT_PROP_ID = FNS.FAL_LOT_PROP_ID) is null
                    and (select FAL_PIC_ID
                           from FAL_DOC_PROP PROP
                          where PROP.FAL_DOC_PROP_ID = FNS.FAL_DOC_PROP_ID) is null)
               )
      order by trunc(FAN_END_PLAN)
             , FAL_NETWORK_SUPPLY_ID;

    cursor CAttrib
    is
      select   FAL_NETWORK_LINK_ID
             , FAL_NETWORK_NEED_ID
             , STM_STOCK_POSITION_ID
             , STM_LOCATION_ID
             , FLN_QTY
          from FAL_NETWORK_LINK
         where FAL_NETWORK_SUPPLY_ID = aFAL_NETWORK_SUPPLY_ID
           and trunc(FLN_NEED_DELAY) >= trunc(sysdate)
      order by FLN_NEED_DELAY desc;

    cursor CAppro4
    is
      select   FAL_NETWORK_SUPPLY_ID
             , FAN_FREE_QTY
             , STM_STOCK_ID
             , FAN_END_PLAN
          from FAL_NETWORK_SUPPLY FNS
         where GCO_GOOD_ID = PrmGCO_GOOD_ID
           and trunc(FAN_END_PLAN) <= trunc(aEndDate) + 1
           and FAN_FREE_QTY > 0
           and (   DOC_GAUGE_ID is null
                or DOC_GAUGE_ID not in(select DOC_GAUGE_ID
                                         from FAL_PROP_DEF
                                        where C_PROP_TYPE = '4') )
           and   -- On tient compte des appros du plan directeur
               (    (iUseMasterPlanProcurements = 1)
                -- On ne tient compte des appros du plan directeur
                or (    (select FAL_PIC_ID
                           from FAL_LOT_PROP PROP
                          where PROP.FAL_LOT_PROP_ID = FNS.FAL_LOT_PROP_ID) is null
                    and (select FAL_PIC_ID
                           from FAL_DOC_PROP PROP
                          where PROP.FAL_DOC_PROP_ID = FNS.FAL_DOC_PROP_ID) is null)
               )
      order by trunc(FAN_END_PLAN)
             , FAL_NETWORK_SUPPLY_ID;
  begin
    result                    := 0;
    outFAL_NETWORK_SUPPLY_ID  := null;

    if nvl(PrmCBDecalage, 0) = 0 then
      -- Déterminer le mode d'approvisionnement du produit ...
      if PrmCBSupplyMode = '2' then   -- Produit Fabrique
        -- Produit fabriqué ...
        -- Déterminer le décalage ... (arrondi à l'entier supérieur)
        aFloatDecalage  := (abs(nvl(PrmMinStkItemNeedMinStock, 0) ) * nvl(PrmCBSupplyDelay, 0) ) / nvl(PrmCBStandardLotQty, 0);
        aDecalage       := trunc(FAL_TOOLS.RoundSuccInt(nvl(aFloatDecalage, 0) ) );
      else
        -- Produit non fabriqué ...
        -- Déterminer le décalage ...
        aDecalage  := nvl(PrmCBSupplyDelay, 0);
      end if;
    end if;

    if nvl(PrmCBDecalage, 0) <> 0 then
      aDecalage  := nvl(PrmCBDecalage, 0);
    end if;

    -- Calcul Date Fin décalage ...
    -- Si le décalage est > au nbre de jours de décalage maximum calculés sur les calendriers
    if aDecalage > FAL_LIB_CONSTANT.gCfgCBShiftLimit then
      aEndDate  := PrmCalculDate + aDecalage;
    else
      aEndDate  :=
               FAL_SCHEDULE_FUNCTIONS.GetDecalageForwardDate(null, null, null, null, null, FAL_SCHEDULE_FUNCTIONS.GetDefaultCalendar, PrmCalculDate, aDecalage);
    end if;

    if aEndDate is null then
      -- Décalage trop grand. On est hors des limites du PC_NUMBER. Décalage max. = 99'999 si tous les jours sont ouvrés. Sinon plus le calendrier
      -- contient de jours non ouvrés, et plus la limite du décalage est petite.
      ra('PCS - The shift defined (' ||
         aDecalage ||
         ') in complementary data of good ' ||
         PCS_FWK.FWK_LIB_ENTITY.getVarchar2FieldFromPk('GCO_GOOD', 'GOO_MAJOR_REFERENCE', PrmGCO_GOOD_ID) ||
         ' is too large !' ||
         co.cLineBreak
       , null
       , -20000
       , true
        );
    end if;

    outB                      :=(-1 * nvl(PrmMinStkItemNeedMinStock, 0) );
    outC                      :=(-1 * nvl(PrmMinStkItemNeedPtCde, 0) );
    outFAL_NETWORK_SUPPLY_ID  := null;

    open CAppro1;

    loop
      fetch CAppro1
       into aFLN_QTY;

      exit when result <> 0
            or CAppro1%notfound;

      if nvl(aFLN_QTY, 0) >= nvl(outB, 0) then
        OutC    := OutC - outB;
        result  := 1;
      else
        outB  := outB - nvl(aFLN_QTY, 0);
        OutC  := OutC - nvl(aFLN_QTY, 0);
      end if;
    end loop;

    close CAppro1;

    if result = 0 then
      open CAppro2;

      loop
        fetch CAppro2
         into aFAL_NETWORK_SUPPLY_ID
            , aFAN_FREE_QTY
            , aFAN_END_PLAN;

        exit when CAppro2%notfound
              or result <> 0;

        if nvl(aFAN_FREE_QTY, 0) >= nvl(outB, 0) then
          outFAL_NETWORK_SUPPLY_ID  := aFAL_NETWORK_SUPPLY_ID;
          OutC                      := OutC - outB;
          result                    := 2;
        else
          outB  := outB - nvl(aFAN_FREE_QTY, 0);
          OutC  := OutC - nvl(aFAN_FREE_QTY, 0);
          FAL_NETWORK.CreateAttribApproStock(aFAL_NETWORK_SUPPLY_ID
                                           , FAL_TOOLS.GetLocationFromCompldataStock(PrmGCO_GOOD_ID, gStockMinCurrStkItemStockID)
                                           , aFAN_FREE_QTY
                                           , aFAN_END_PLAN
                                           , aFAN_FREE_QTY
                                            );
        end if;
      end loop;

      close CAppro2;
    end if;

    if result = 0 then
      QTE_LIBERE  := 0;

      open CAppro3;

      loop
        fetch Cappro3
         into aFAL_NETWORK_SUPPLY_ID
            , aSTM_STOCK_ID;

        exit when CAppro3%notfound;

        -- Si le stock de l'appro est dans la liste des stocks sélectionnés
        if instr(PrmStockListIn, 's' || aSTM_STOCK_ID || 's') > 0 then
          -- Pour chaque Attribution sur Besoin de l'appro sélectionné Dont la date besoin est > à la date du jour pris dans l'ordre des  Date besoin croissant (Fal_Network_Link -> Fln_Need_Delay) Décroissant
          open CAttrib;

          loop
            fetch CAttrib
             into aFAL_NETWORK_LINK_ID
                , aFAL_NETWORK_NEED_ID
                , aSTM_STOCK_POSITION_ID
                , aSTM_LOCATION_ID
                , aFLN_QTY;

            exit when QTE_LIBERE >= outB
                  or CAttrib%notfound;
            QTE_LIBERE  := QTE_LIBERE + nvl(aFLN_QTY, 0);
            -- Suppression attribution
            FAL_REDO_ATTRIBS.SuppressionAttribution(aFAL_NETWORK_LINK_ID
                                                  , aFAL_NETWORK_NEED_ID
                                                  , aFAL_NETWORK_SUPPLY_ID
                                                  , aSTM_STOCK_POSITION_ID
                                                  , aSTM_LOCATION_ID
                                                  , aFLN_QTY
                                                   );
          end loop;

          close CAttrib;
        end if;
      end loop;

      close CAppro3;
    end if;

    if result = 0 then
      AuMoinsUne  := false;

      open CAppro4;

      loop
        fetch CAppro4
         into aFAL_NETWORK_SUPPLY_ID
            , aFAN_FREE_QTY
            , aSTM_STOCK_ID
            , aFAN_END_PLAN;

        exit when CAppro4%notfound
              or result <> 0;

        -- Si le stock de l'appro est dans la liste des stocks sélectionnés
        if instr(PrmStockListIn, 's' || aSTM_STOCK_ID || 's') > 0 then
          AuMoinsUne  := true;

          if nvl(aFAN_FREE_QTY, 0) >= nvl(outB, 0) then
            outFAL_NETWORK_SUPPLY_ID  := aFAL_NETWORK_SUPPLY_ID;
            outC                      := outC - outB;
            result                    := 2;
          else
            outB  := outB - nvl(aFAN_FREE_QTY, 0);
            outC  := outC - nvl(aFAN_FREE_QTY, 0);
            FAL_NETWORK.CreateAttribApproStock(aFAL_NETWORK_SUPPLY_ID
                                             , FAL_TOOLS.GetLocationFromCompldataStock(PrmGCO_GOOD_ID, gStockMinCurrStkItemStockID)
                                             , aFAN_FREE_QTY
                                             , aFAN_END_PLAN
                                             , aFAN_FREE_QTY
                                              );
          end if;
        end if;
      end loop;

      close CAppro4;

      if not AuMoinsUne then
        outC    := outC - outB;
        result  := 3;
      end if;

      if result = 0 then
        result  := 3;
        OutC    := OutC - OutB;
      end if;
    end if;
  end;

  /****
  * function GraphEvent_Decalage
  * Description : Calcul du décalage afin de savoir s'il est nécessaire d'approvisionner
  *               ou pas un produit pour combler ses besoins, en fonctions des appro à venir
  * @author ECA
  * @public
  */
  procedure GraphEvent_Decalage(
    aNeedDate                         date
  , aNeedQty                          FAL_NETWORK_NEED.FAN_FULL_QTY%type
  , aDoReconstructionAttrib           integer
  , AttribMemeSiMargeNegative         integer
  , PrmCharactID1                     FAL_NETWORK_SUPPLY.GCO_CHARACTERIZATION1_ID%type
  , PrmCharactID2                     FAL_NETWORK_SUPPLY.GCO_CHARACTERIZATION2_ID%type
  , PrmCharactID3                     FAL_NETWORK_SUPPLY.GCO_CHARACTERIZATION3_ID%type
  , PrmCharactID4                     FAL_NETWORK_SUPPLY.GCO_CHARACTERIZATION4_ID%type
  , PrmCharactID5                     FAL_NETWORK_SUPPLY.GCO_CHARACTERIZATION5_ID%type
  , PrmCharacterizationValue1         FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type
  , PrmCharacterizationValue2         FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE2%type
  , PrmCharacterizationValue3         FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE3%type
  , PrmCharacterizationValue4         FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE4%type
  , PrmCharacterizationValue5         FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE5%type
  , aSupplySQL                 in out clob
  , aCBParametersDecalage             GCO_COMPL_DATA_MANUFACTURE.CMA_SHIFT%type
  , aNeedID                           PCS_PK_ID
  , aSupplySQLParam_VariableD1        date
  , aSupplySQLParam_FinalDate         date
  , aGoodID                           PCS_PK_ID default 0
  , C                                 integer
  ,
    -- Variable en retour
    E                          in out FAL_NETWORK_NEED.FAN_FULL_QTY%type
  , result                     out    PCS_PK_ID
  )
  is
    aDecalage                     integer;
    aEndDate                      date;
    inNeedQty                     FAL_NETWORK_NEED.FAN_FULL_QTY%type;
    LocSource_Cursor              integer;
    Ignore                        integer;
    BuffSql                       varchar2(20000);
    lectfan_free_qty              FAL_NETWORK_NEED.FAN_FREE_QTY%type;
    LectNETWORK_ID                PCS_PK_ID;
    AttentionAuNombreAppro        boolean;
    X                             integer;
    ApproPrise                    integer;
    BindVariable1                 boolean;
    -- Résultats de la concaténation de chaque CurGCO_CHARACTERIZATIONx_ID et FAN_CHAR_VALUEx
    ai1v1                         varchar(100);   -- 100 pour assurer mais 50 sont suffisant (ID=> longueur 12, Caractérisation => longueur 30)
    ai2v2                         varchar(100);   -- ...
    ai3v3                         varchar(100);   -- ...
    ai4v4                         varchar(100);   -- ...
    ai5v5                         varchar(100);   -- ...
    PdtHasVersionOrCharacteristic boolean;
  begin
    -- Suppression éventuelle des [ COMPANY_OWNER].
    aSupplySQL  := replace(aSupplySQL, co.cCompanyOwner || '.', '');
    InNeedQty   := nvl(aNeedQty, 0);
    result      := 0;
    -- Déterminer le décalage
    aDecalage   := nvl(aCBParametersDecalage, 0);

    -- Si reconstruction avec marge négative, décalage maximal -> 4 ans
    if     (aDoReconstructionAttrib = 1)
       and (AttribMemeSiMargeNegative = 1) then
      adecalage  := 4 * 365;
    end if;

    if aDecalage = 0 then
      E  := -nvl(aNeedQty, 0);
    end if;

    if aDecalage <> 0 then
      -- Si reconstruction avec marge négative, décalage maximal -> 4 ans complet
      if     (aDoReconstructionAttrib = 1)
         and (AttribMemeSiMargeNegative = 1) then
        aEndDate  := trunc(aNeedDate) + aDecalage;
      -- Sinon calcul Date Fin décalage sur le calendrier par défaut de l'entreprise (Décalage en jours ouvrés)
      else
        -- Si le décalage est > au nbre de jours de décalage maximum calculés sur les calendriers
        if aDecalage > FAL_LIB_CONSTANT.gCfgCBShiftLimit then
          aEndDate  := trunc(aNeedDate) + aDecalage;
        else
          aEndDate  :=
            trunc(FAL_SCHEDULE_FUNCTIONS.GetDecalageForwardDate(null
                                                              , null
                                                              , null
                                                              , null
                                                              , null
                                                              , FAL_SCHEDULE_FUNCTIONS.GetDefaultCalendar
                                                              , trunc(aNeedDate)
                                                              , aDecalage
                                                               )
                 );
        end if;

        if aEndDate is null then
          -- Décalage trop grand. On est hors des limites du PC_NUMBER. Décalage max. = 99'999 si tous les jours sont ouvrés. Sinon plus le calendrier
          -- contient de jours non ouvrés, et plus la limite du décalage est petite.
          ra('PCS - The shift defined (' ||
             aDecalage ||
             ') in complementary data of good ' ||
             PCS_FWK.FWK_LIB_ENTITY.getVarchar2FieldFromPk('GCO_GOOD', 'GOO_MAJOR_REFERENCE', aGoodID) ||
             ' is too large !' ||
             co.cLineBreak
           , null
           , -20000
           , true
            );
        end if;
      end if;

      AttentionAuNombreAppro         := false;

      if nvl(aGoodID, 0) <> 0 then
        if     FAL_TOOLS.IsFullTracability(aGoodID)
           and FAL_TOOLS.OneReceiptSupplyIsOneLot(aGoodID) then
          AttentionAuNombreAppro  := true;

            -- Récupère le coefficient de traçabilité permettant de connaitre
          -- le nb maxi de positions autorisées.
          select PDT_FULL_TRACABILITY_COEF
            into X
            from GCO_PRODUCT
           where GCO_GOOD_ID = aGoodID;

          if nvl(X, 0) <= 0 then
            X  := 1;
          end if;
        end if;
      end if;

      -- Rechercher un approvisionnement arrivant dans le décalage ...
      -- Réutiliser aSupplySQL qui contient toutes les conditions de restrictions nécéssaires ...
      BuffSql                        := aSupplySql;
      BuffSql                        := BuffSql || ' AND TRUNC(FAN_END_PLAN) <= :ENDDATE';
      BindVariable1                  := false;

      if nvl(aGoodID, 0) <> 0 then
        if not(    FAL_TOOLS.IsFullTracability(aGoodID)
               and FAL_TOOLS.OneReceiptSupplyIsOneLot(aGoodID) ) then
            -- Selon remarque dans l'analyse, pour les Pdts gérés en "Traçàbilité complète" et "Chaque réception appro = 1 lot"
          -- On ne fait pas le test.
          BindVariable1  := true;
          BuffSql        := BuffSql || ' AND TRUNC(FAN_END_PLAN) > :NEEDDATE';
        end if;
      end if;

      BuffSql                        := BuffSql || ' AND FAN_FREE_QTY > 0';

      -- Et pour éviter le problème des BIND VARIABLE DOES NOT EXIST
      if aSupplySQLParam_VARIABLED1 is not null then
        BUffSql  := BuffSql || ' AND :VARIABLED1 = :VARIABLED1';
      end if;

      if aSupplySQLParam_FinalDate is not null then
        BUffSql  := BuffSql || ' AND :FINALDATE = :FINALDATE';
      end if;

      -- Et qui correspondent au jeu de caractérisation demandé
      ai1v1                          := null;
      ai2v2                          := null;
      ai3v3                          := null;
      ai4v4                          := null;
      ai5v5                          := null;
      -- optimisation: Juste pour ne pas rechercher cette info plus loin
      PdtHasVersionOrCharacteristic  := fal_tools.ProductHasVersionOrCharacteris(aGOODID) = 1;

      if PdtHasVersionOrCharacteristic then
        -- Initialisation des valeur 1..5 des charactérisation de type version (1) ou caracteristique (2)
        if fal_tools.VersionOrCharacteristicType(PrmCharactID1) = 1 then
          ai1v1  := concat(PrmCharactID1, PrmCharacterizationValue1);
        end if;

        if fal_tools.VersionOrCharacteristicType(PrmCharactID2) = 1 then
          ai2v2  := concat(PrmCharactID2, PrmCharacterizationValue2);
        end if;

        if fal_tools.VersionOrCharacteristicType(PrmCharactID3) = 1 then
          ai3v3  := concat(PrmCharactID3, PrmCharacterizationValue3);
        end if;

        if fal_tools.VersionOrCharacteristicType(PrmCharactID4) = 1 then
          ai4v4  := concat(PrmCharactID4, PrmCharacterizationValue4);
        end if;

        if fal_tools.VersionOrCharacteristicType(PrmCharactID5) = 1 then
          ai5v5  := concat(PrmCharactID5, PrmCharacterizationValue5);
        end if;
      end if;

      if PdtHasVersionOrCharacteristic then
            -- Même chose que dans la reconstruction des attribs.
        -- Tenir compte des caractérisations si pdt avec caractérisations de type version ou caractéristique
        buffsql  := buffsql || ' and';
        buffsql  := buffsql || '(';
        buffsql  := buffsql || ' (';
        buffsql  := buffsql || '  (TO_NUMBER(PCS.PC_CONFIG.GetConfig(''FAL_ATTRIB_ON_CHARACT_MODE'')) = 1)';
        buffsql  := buffsql || '  and';
        buffsql  := buffsql || '  (';
        buffsql  := buffsql || '      (';
        buffsql  := buffsql || '	     :Ai1v1 || :Ai2v2 || :Ai3v3 || :Ai4v4 || :Ai5v5 is not null';
        buffsql  := buffsql || '	     and';
        buffsql  :=
          buffsql ||
          '   	 ((:Ai1v1 in (   concat(GCO_CHARACTERIZATION1_ID,FAN_CHAR_VALUE1),concat(GCO_CHARACTERIZATION2_ID,FAN_CHAR_VALUE2),concat(GCO_CHARACTERIZATION3_ID,FAN_CHAR_VALUE3),concat(GCO_CHARACTERIZATION4_ID,FAN_CHAR_VALUE4),concat(GCO_CHARACTERIZATION5_ID,FAN_CHAR_VALUE5)     )) or (:Ai1v1 is null ))';
        buffsql  := buffsql || '	     and';
        buffsql  :=
          buffsql ||
          '	     ((:Ai2v2 in (   concat(GCO_CHARACTERIZATION1_ID,FAN_CHAR_VALUE1),concat(GCO_CHARACTERIZATION2_ID,FAN_CHAR_VALUE2),concat(GCO_CHARACTERIZATION3_ID,FAN_CHAR_VALUE3),concat(GCO_CHARACTERIZATION4_ID,FAN_CHAR_VALUE4),concat(GCO_CHARACTERIZATION5_ID,FAN_CHAR_VALUE5)     )) or (:Ai2v2 is null ))';
        buffsql  := buffsql || '	     and';
        buffsql  :=
          buffsql ||
          '	     ((:Ai3v3 in (   concat(GCO_CHARACTERIZATION1_ID,FAN_CHAR_VALUE1),concat(GCO_CHARACTERIZATION2_ID,FAN_CHAR_VALUE2),concat(GCO_CHARACTERIZATION3_ID,FAN_CHAR_VALUE3),concat(GCO_CHARACTERIZATION4_ID,FAN_CHAR_VALUE4),concat(GCO_CHARACTERIZATION5_ID,FAN_CHAR_VALUE5)     )) or (:Ai3v3 is null ))';
        buffsql  := buffsql || '	     and';
        buffsql  :=
          buffsql ||
          '	     ((:Ai4v4 in (   concat(GCO_CHARACTERIZATION1_ID,FAN_CHAR_VALUE1),concat(GCO_CHARACTERIZATION2_ID,FAN_CHAR_VALUE2),concat(GCO_CHARACTERIZATION3_ID,FAN_CHAR_VALUE3),concat(GCO_CHARACTERIZATION4_ID,FAN_CHAR_VALUE4),concat(GCO_CHARACTERIZATION5_ID,FAN_CHAR_VALUE5)     )) or (:Ai4v4 is null ))';
        buffsql  := buffsql || '	     and';
        buffsql  :=
          buffsql ||
          '	     ((:Ai5v5 in (   concat(GCO_CHARACTERIZATION1_ID,FAN_CHAR_VALUE1),concat(GCO_CHARACTERIZATION2_ID,FAN_CHAR_VALUE2),concat(GCO_CHARACTERIZATION3_ID,FAN_CHAR_VALUE3),concat(GCO_CHARACTERIZATION4_ID,FAN_CHAR_VALUE4),concat(GCO_CHARACTERIZATION5_ID,FAN_CHAR_VALUE5)     )) or (:Ai5v5 is null ))';
        buffsql  := buffsql || '	     )';
        buffsql  := buffsql || '	     or';
        buffsql  := buffsql || '	     (';
        buffsql  := buffsql || '	       :Ai1v1 || :Ai2v2 || :Ai3v3 || :Ai4v4 || :Ai5v5 is null';
        buffsql  := buffsql || '	       and fal_tools.NullForNoMorpho(GCO_CHARACTERIZATION1_ID  ,FAN_CHAR_VALUE1)';
        buffsql  := buffsql || '	           ||';
        buffsql  := buffsql || '		       fal_tools.NullForNoMorpho(GCO_CHARACTERIZATION2_ID  ,FAN_CHAR_VALUE2)';
        buffsql  := buffsql || '	           ||';
        buffsql  := buffsql || '	           fal_tools.NullForNoMorpho(GCO_CHARACTERIZATION3_ID  ,FAN_CHAR_VALUE3)';
        buffsql  := buffsql || '	           ||';
        buffsql  := buffsql || '		       fal_tools.NullForNoMorpho(GCO_CHARACTERIZATION4_ID  ,FAN_CHAR_VALUE4)';
        buffsql  := buffsql || '	           ||';
        buffsql  := buffsql || '		       fal_tools.NullForNoMorpho(GCO_CHARACTERIZATION5_ID,  FAN_CHAR_VALUE5) is null';
        buffsql  := buffsql || '	     )';
        buffsql  := buffsql || '  )';
        buffsql  := buffsql || ')';
        buffsql  := buffsql || 'OR';
        buffsql  := buffsql || '(';
        buffsql  := buffsql || '  (TO_NUMBER(PCS.PC_CONFIG.GetConfig(''FAL_ATTRIB_ON_CHARACT_MODE'')) <> 1)';
        buffsql  := buffsql || '  and';
        buffsql  := buffsql || '  (';
        buffsql  := buffsql || '      (';
        buffsql  :=
          buffsql ||
          '      ((:Ai1v1 in (   concat(GCO_CHARACTERIZATION1_ID,FAN_CHAR_VALUE1),concat(GCO_CHARACTERIZATION2_ID,FAN_CHAR_VALUE2),concat(GCO_CHARACTERIZATION3_ID,FAN_CHAR_VALUE3),concat(GCO_CHARACTERIZATION4_ID,FAN_CHAR_VALUE4),concat(GCO_CHARACTERIZATION5_ID,FAN_CHAR_VALUE5)     )) or (:Ai1v1 is null ))';
        buffsql  := buffsql || '      and';
        buffsql  :=
          buffsql ||
          '      ((:Ai2v2 in (   concat(GCO_CHARACTERIZATION1_ID,FAN_CHAR_VALUE1),concat(GCO_CHARACTERIZATION2_ID,FAN_CHAR_VALUE2),concat(GCO_CHARACTERIZATION3_ID,FAN_CHAR_VALUE3),concat(GCO_CHARACTERIZATION4_ID,FAN_CHAR_VALUE4),concat(GCO_CHARACTERIZATION5_ID,FAN_CHAR_VALUE5)     )) or (:Ai2v2 is null ))';
        buffsql  := buffsql || '      and';
        buffsql  :=
          buffsql ||
          '      ((:Ai3v3 in (   concat(GCO_CHARACTERIZATION1_ID,FAN_CHAR_VALUE1),concat(GCO_CHARACTERIZATION2_ID,FAN_CHAR_VALUE2),concat(GCO_CHARACTERIZATION3_ID,FAN_CHAR_VALUE3),concat(GCO_CHARACTERIZATION4_ID,FAN_CHAR_VALUE4),concat(GCO_CHARACTERIZATION5_ID,FAN_CHAR_VALUE5)     )) or (:Ai3v3 is null ))';
        buffsql  := buffsql || '      and';
        buffsql  :=
          buffsql ||
          '      ((:Ai4v4 in (   concat(GCO_CHARACTERIZATION1_ID,FAN_CHAR_VALUE1),concat(GCO_CHARACTERIZATION2_ID,FAN_CHAR_VALUE2),concat(GCO_CHARACTERIZATION3_ID,FAN_CHAR_VALUE3),concat(GCO_CHARACTERIZATION4_ID,FAN_CHAR_VALUE4),concat(GCO_CHARACTERIZATION5_ID,FAN_CHAR_VALUE5)     )) or (:Ai4v4 is null ))';
        buffsql  := buffsql || '      and';
        buffsql  :=
          buffsql ||
          '      ((:Ai5v5 in (   concat(GCO_CHARACTERIZATION1_ID,FAN_CHAR_VALUE1),concat(GCO_CHARACTERIZATION2_ID,FAN_CHAR_VALUE2),concat(GCO_CHARACTERIZATION3_ID,FAN_CHAR_VALUE3),concat(GCO_CHARACTERIZATION4_ID,FAN_CHAR_VALUE4),concat(GCO_CHARACTERIZATION5_ID,FAN_CHAR_VALUE5)     )) or (:Ai5v5 is null ))';
        buffsql  := buffsql || '      )';
        buffsql  := buffsql || '      or';
        buffsql  := buffsql || '      (';
        buffsql  := buffsql || '             fal_tools.NullForNoMorpho(GCO_CHARACTERIZATION1_ID  ,FAN_CHAR_VALUE1)';
        buffsql  := buffsql || '      	    ||';
        buffsql  := buffsql || '      		fal_tools.NullForNoMorpho(GCO_CHARACTERIZATION2_ID  ,FAN_CHAR_VALUE2)';
        buffsql  := buffsql || '      	    ||';
        buffsql  := buffsql || '      	    fal_tools.NullForNoMorpho(GCO_CHARACTERIZATION3_ID  ,FAN_CHAR_VALUE3)';
        buffsql  := buffsql || '      	    ||';
        buffsql  := buffsql || '      		fal_tools.NullForNoMorpho(GCO_CHARACTERIZATION4_ID  ,FAN_CHAR_VALUE4)';
        buffsql  := buffsql || '      	    ||';
        buffsql  := buffsql || '      		fal_tools.NullForNoMorpho(GCO_CHARACTERIZATION5_ID,  FAN_CHAR_VALUE5) is null';
        buffsql  := buffsql || '      )';
        buffsql  := buffsql || '  )';
        buffsql  := buffsql || ' )';
        buffsql  := buffsql || ')';
      end if;

      BuffSql                        := BuffSql || ' ORDER BY TRUNC(FAN_END_PLAN), FAL_NETWORK_SUPPLY_ID';
      LocSource_Cursor               := DBMS_SQL.open_cursor;
      DBMS_SQL.Parse(LocSource_Cursor, BuffSql, DBMS_SQL.V7);
      DBMS_SQL.Define_column(LocSource_Cursor, 1, LectFAN_FREE_QTY);
      DBMS_SQL.Define_column(LocSource_Cursor, 2, LectNETWORK_ID);
      -- Affecter les paramètres définit ici dans les BIND variables
      DBMS_SQL.BIND_VARIABLE(LocSource_Cursor, 'ENDDATE', aEndDate);

      if BindVariable1 then
        DBMS_SQL.BIND_VARIABLE(LocSource_Cursor, 'NEEDDATE', trunc(aNeedDate) );
      end if;

      -- Affecter les paramètres définit an amont dans les BIND variables
      if aSupplySQLParam_VARIABLED1 is not null then
        DBMS_SQL.BIND_VARIABLE(LocSource_Cursor, 'VARIABLED1', aSupplySQLParam_VARIABLED1 + 1);
      end if;

      if aSupplySQLParam_FinalDate is not null then
        DBMS_SQL.BIND_VARIABLE(LocSource_Cursor, 'FINALDATE', aSupplySQLParam_FinalDate + 1);
      end if;

      if PdtHasVersionOrCharacteristic then
        DBMS_SQL.BIND_VARIABLE(LocSource_Cursor, 'Ai1v1', Ai1v1);
        DBMS_SQL.BIND_VARIABLE(LocSource_Cursor, 'Ai2v2', Ai2v2);
        DBMS_SQL.BIND_VARIABLE(LocSource_Cursor, 'Ai3v3', Ai3v3);
        DBMS_SQL.BIND_VARIABLE(LocSource_Cursor, 'Ai4v4', Ai4v4);
        DBMS_SQL.BIND_VARIABLE(LocSource_Cursor, 'Ai5v5', Ai5v5);
      end if;

      Ignore                         := DBMS_SQL.execute(LocSource_cursor);
      ApproPrise                     := C;

      while DBMS_SQL.fetch_rows(Locsource_cursor) > 0
       and (result = 0) loop
        if AttentionAuNombreAppro then
          if ApproPrise >= X - 1 then   -- En effet il peut y avoir aussi échec dans le décalage et il faut garder 1 pour une éventuelle Pox
            exit;
          end if;
        end if;

        DBMS_SQL.column_value(Locsource_cursor, 1, LectFAN_FREE_QTY);
        DBMS_SQL.column_value(Locsource_cursor, 2, LectNETWORK_ID);
        LectFAN_FREE_QTY  := nvl(LectFAN_FREE_QTY, 0);

        if LectFAN_FREE_QTY >= InNeedQty then
          -- Decalage OK
          result  := 1;
          FAL_NETWORK.CreateAttribBesoinAppro(aNeedID,   -- Paramètre PrmFAL_NETWORK_NEED_ID
                                              LectNETWORK_ID,   -- Paramètre PrmId_reseauxApprocree
                                              InNeedQty   -- Paramètre PrmA
                                                       );
          E       := -InNeedQty;
        else
          FAL_NETWORK.CreateAttribBesoinAppro(aNeedID,   -- Paramètre PrmFAL_NETWORK_NEED_ID
                                              LectNETWORK_ID,   -- Paramètre PrmId_reseauxApprocree
                                              LectFAN_FREE_QTY   -- Paramètre PrmA
                                                              );
          InNeedQty  := InNeedQty - nvl(LectFAN_FREE_QTY, 0);
        end if;

        ApproPrise        := ApproPrise + 1;
      end loop;

      -- fermeture du curseur
      DBMS_SQL.close_cursor(Locsource_cursor);
      E                              := -nvl(InNeedQty, 0);
    end if;
  end;

  /**
  * Function GetStockWithNeedSupplyMin
  * Description : Retourne le disponible net d'un article (stock (Stock Dispo des stock Public et pris en compte dans le
  *               calcul des besoins) - besoins (libres) déjà existants à date + appros libres à date - stocks minimum).
  * @author DJE
  * @public
  * @param   PrmGCO_GOOD_ID : Produit CB en cours de traitement
  * @param   PrmDate : Date
  * @param   PrmTakeFreeOnSupply : Prends en compte le libre sur appro
  * @param   PrmWithStockMini : Prendre en compte les stocks mini
  */
  function GetStockWithNeedSupplyMin(
    PrmGCO_GOOD_ID      GCO_GOOD.GCO_GOOD_ID%type
  , PrmDate             FAL_NETWORK_NEED.FAN_BEG_PLAN%type
  , PrmTakeFreeOnSupply integer
  , PrmWithStockMini    integer
  )
    return number
  is
    SommeSPO_AVAILABLE_QUANTITY STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type;
    SommeBesoinsLibre           FAL_NETWORK_NEED.FAN_FREE_QTY%type;
    SommeApprosLibre            FAL_NETWORK_SUPPLY.FAN_FREE_QTY%type;
    SommeStocksMini             number;
  begin
    SommeSPO_AVAILABLE_QUANTITY  := 0;
    SommeBesoinsLibre            := 0;
    SommeApprosLibre             := 0;
    SommeStocksMini              := 0;

    -- Récupérer la Qté dispoinible enstock.
    select sum(SPO_AVAILABLE_QUANTITY)
      into SommeSPO_AVAILABLE_QUANTITY
      from STM_STOCK_POSITION
     where GCO_GOOD_ID = PrmGCO_GOOD_ID
       and STM_STOCK_ID in(select STM_STOCK_ID
                             from STM_STOCK
                            where C_ACCESS_METHOD = 'PUBLIC'
                              and STO_NEED_CALCULATION = 1);

    -- Récupérer la somme des besoins libres
    select sum(FAN_FREE_QTY)
      into SommeBesoinsLibre
      from FAL_NETWORK_NEED
     where GCO_GOOD_ID = PrmGCo_GOOD_ID
       and FAN_FREE_QTY > 0
       and trunc(FAN_BEG_PLAN) <= PrmDate;

    if PrmTakeFreeOnSupply = 1 then
      -- Récupérer la somme des Appros libres
      select sum(FAN_FREE_QTY)
        into SommeApprosLibre
        from FAL_NETWORK_SUPPLY
       where GCO_GOOD_ID = PrmGCo_GOOD_ID
         and FAN_FREE_QTY > 0
         and trunc(FAN_END_PLAN) <= PrmDate;
    end if;

    if PrmWithStockMini = 1 then
      -- Récupérer la somme des stocks minis
      select sum(CST_QUANTITY_MIN)
        into SommeStocksMini
        from GCO_COMPL_DATA_STOCK
       where GCO_GOOD_ID = PrmGCO_GOOD_ID;
    end if;

    return nvl(SommeSPO_AVAILABLE_QUANTITY, 0) - nvl(SommeBesoinsLibre, 0) + nvl(SommeApprosLibre, 0) - nvl(SommeStocksMini, 0);
  end;

  /**
  * Function initFAL_CB_INFORMER
  * Description : Ré-initialise la table trace du CB.
  *
  * @author DJE
  * @public
  */
  procedure initFAL_CB_INFORMER
  is
    pragma autonomous_transaction;
  begin
    delete from FAL_CB_INFORMER;

    commit;
  end;

  /**
  * Function WriteFAL_CB_INFORMER
  * Description : Ecrit une ligne d'information dans la table trace du le Calcul des besoins
  *
  * @author DJE
  * @public
  * @param   PrmFCI_PROP_COUNT : Nbre d epropositions créées
  * @param   PrmFCI_GOOD_COUNT : Nbre de produits traités
  * @param   PrmGCO_GOOD_ID : Produit en cours
  * @param   PrmFCI_DUREE : Date
  * @param   PrmFCI_DUREE_SS : Durée totale en secondes
  * @param   PrmFCI_BLOC : Partie traitement des blocs d'équivalence
  * @param   PrmFCI_INFO : Erreur eventuelle
  */
  procedure WriteFAL_CB_INFORMER(
    PrmFCI_PROP_COUNT FAL_CB_INFORMER.FAL_CB_INFORMER_ID%type
  , PrmFCI_GOOD_COUNT FAL_CB_INFORMER.FAL_CB_INFORMER_ID%type
  , PrmGCO_GOOD_ID    FAL_CB_INFORMER.FAL_CB_INFORMER_ID%type
  , PrmFCI_DUREE      FAL_CB_INFORMER.FCI_DUREE%type
  , PrmFCI_DUREE_SS   FAL_CB_INFORMER.FCI_DUREE_SS%type
  , PrmFCI_BLOC       FAL_CB_INFORMER.FCI_BLOC%type
  , PrmFCI_INFO       FAL_CB_INFORMER.FCI_INFO%type
  )
  is
    pragma autonomous_transaction;
  begin
    insert into FAL_CB_INFORMER
                (FAL_CB_INFORMER_ID
               , FCI_PROP_COUNT
               , FCI_GOOD_COUNT
               , FCI_DUREE
               , FCI_DUREE_SS
               , GCO_GOOD_ID
               , FCI_BLOC
               , FCI_INFO
               , A_IDCRE
               , A_DATECRE
                )
         values (GetNewId
               , PrmFCI_PROP_COUNT
               , PrmFCI_GOOD_COUNT
               , PrmFCI_DUREE
               , PrmFCI_DUREE_SS
               , PrmGCO_GOOD_ID
               , PrmFCI_BLOC
               , PrmFCI_INFO
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , sysdate
                );

    commit;
  end;

  /**
  * Function CALCUL_M
  * Description : Cf Analyse, calcul qté libre besoin - Qté libre appro
  *               (produits en délais fixes)
  * @author
  * @public
  */
  procedure CALCUL_M(
    Q                                    clob
  , cstSupplyFlag                        varchar2
  , cstNeedFlag                          varchar2
  , aSupplySQLParam_VariableD1           date
  , aSupplySQLParam_VariableD2           date
  , aSupplySQLParam_VariableDelay        varchar2
  , M                             in out FAL_NETWORK_NEED.FAN_FREE_QTY%type
  )
  is
    buffSql          varchar2(32767);
    Ignore           integer;
    LocSource_Cursor integer;
    LectFAN_FREE_QTY FAL_NETWORK_NEED.FAN_FREE_QTY%type;
    LectNETWORK_TYPE varchar2(2);
  begin
    BUffSql           := Q;
    BUffSql           := replace(BUffSql, co.cCompanyOwner || '.', '');
    LocSource_Cursor  := DBMS_SQL.open_cursor;
    DBMS_SQL.Parse(LocSource_Cursor, BuffSql, DBMS_SQL.V7);
    DBMS_SQL.Define_column(LocSource_Cursor, 1, LectFAN_FREE_QTY);
    DBMS_SQL.Define_column(LocSource_Cursor, 2, LectNETWORK_TYPE, 1);

    -- Affecter les paramètres définit an amont dans les BIND variables
    if instr(BUffSql, 'VARIABLED1', 1, 1) <> 0 then
      DBMS_SQL.BIND_VARIABLE(LocSource_Cursor, 'VARIABLED1', aSupplySQLParam_VARIABLED1);
    end if;

    if instr(BUffSql, 'VARIABLED2', 1, 1) <> 0 then
      DBMS_SQL.BIND_VARIABLE(LocSource_Cursor, 'VARIABLED2', aSupplySQLParam_VariableD2);
    end if;

    if instr(BUffSql, 'ADIC_DELAY_UPDATE_TYPE_ID', 1, 1) <> 0 then
      DBMS_SQL.BIND_VARIABLE(LocSource_Cursor, 'ADIC_DELAY_UPDATE_TYPE_ID', aSupplySQLParam_VariableDelay);
    end if;

    if instr(BUffSql, 'aDIC_DELAY_UPDATE_TYPE_ID', 1, 1) <> 0 then
      DBMS_SQL.BIND_VARIABLE(LocSource_Cursor, 'aDIC_DELAY_UPDATE_TYPE_ID', aSupplySQLParam_VariableDelay);
    end if;

    Ignore            := DBMS_SQL.execute(LocSource_cursor);
    M                 := 0;

    while DBMS_SQL.fetch_rows(Locsource_cursor) > 0 loop
      DBMS_SQL.column_value(Locsource_cursor, 1, LectFAN_FREE_QTY);
      DBMS_SQL.column_value(Locsource_cursor, 2, LectNETWORK_TYPE);

      if LectNETWORK_TYPE = cstNeedFlag then
        M  := M + nvl(LectFAN_FREE_QTY, 0);
      end if;

      if LectNETWORK_TYPE = cstSupplyFlag then
        M  := M - nvl(LectFAN_FREE_QTY, 0);
      end if;
    end loop;

    DBMS_SQL.close_cursor(Locsource_cursor);
  end;

  /**
  * Procedure CreateAllPropOpOfGamme
  * Description : Génération des opération pour une proposition
  *
  * @author ECA
  * @public
  * @param   iFAL_LOT_PROP_ID : Proposition
  * @param   iFAL_SCHEDULE_PLAN_ID : Gamme
  * @param   iQTE : Qté prop
  * @param   iC_SCHEDULE_PLANNING : Mode de planification
  * @param   iContext : 0 = POX, 4 = POAST
  * @param   iPacSupplierPartnerId   fournisseur
  * @param   iGcoGcoGoodId           Bien lié
  * @param   iScsAmount              Montant
  * @param   iScsQtyRefAmount        Qté référence montant
  * @param   iScsDivisorAmount       Diviseur
  * @param   iScsWeigh               Pesée matière précieuses
  * @param   iScsWeighMandatory      Pesée obligatoire
  */
  procedure CreateAllPropOpOfGamme(
    iFAL_LOT_PROP_ID      in FAL_LOT_PROP.FAL_LOT_PROP_ID%type
  , iFAL_SCHEDULE_PLAN_ID in FAL_SCHEDULE_PLAn.FAL_SCHEDULE_PLAN_ID%type
  , iQTE                  in number
  , iC_SCHEDULE_PLANNING  in FAL_SCHEDULE_PLAN.C_SCHEDULE_PLANNING%type
  , iContext              in integer default ctxtPOX
  , iPacSupplierPartnerId in number default null
  , iGcoGcoGoodId         in number default null
  , iScsAmount            in number default 0
  , iScsQtyRefAmount      in integer default 0
  , iScsDivisorAmount     in integer default 0
  , iScsWeigh             in integer default 0
  , iScsWeighMandatory    in integer default 0
  )
  is
    lnFalTaskLinkPropID    FAL_TASK_LINK_PROP.FAL_TASK_LINK_PROP_ID%type;

    cursor lcurFalListStepLinks(inFalSchedulePlanID in FAL_LIST_STEP_LINK.FAL_SCHEDULE_PLAN_ID%type)
    is
      select FAL_SCHEDULE_STEP_ID
           , SCS_STEP_NUMBER
           , C_TASK_TYPE
           , C_OPERATION_TYPE
           , FAL_TASK_ID
           , SCS_SHORT_DESCR
           , SCS_LONG_DESCR
           , SCS_FREE_DESCR
           , FAL_FACTORY_FLOOR_ID
           , SCS_ADJUSTING_TIME
           , SCS_WORK_TIME
           , SCS_PLAN_RATE
           , SCS_QTY_REF_WORK
           , SCS_WORK_RATE
           , SCS_NUM_FLOOR
           , PPS_PPS_OPERATION_PROCEDURE_ID
           , PPS_OPERATION_PROCEDURE_ID
           , PPS_TOOLS1_ID
           , PPS_TOOLS2_ID
           , DIC_FREE_TASK_CODE2_ID
           , DIC_FREE_TASK_CODE_ID
           , C_TASK_IMPUTATION
           , SCS_ADJUSTING_RATE
           , SCS_QTY_FIX_ADJUSTING
           , SCS_TRANSFERT_TIME
           , SCS_PLAN_PROP
           , C_RELATION_TYPE
           , SCS_DELAY
           , PPS_TOOLS3_ID
           , PPS_TOOLS4_ID
           , PPS_TOOLS5_ID
           , PPS_TOOLS6_ID
           , PPS_TOOLS7_ID
           , PPS_TOOLS8_ID
           , PPS_TOOLS9_ID
           , PPS_TOOLS10_ID
           , PPS_TOOLS11_ID
           , PPS_TOOLS12_ID
           , PPS_TOOLS13_ID
           , PPS_TOOLS14_ID
           , PPS_TOOLS15_ID
           , DIC_FREE_TASK_CODE3_ID
           , DIC_FREE_TASK_CODE4_ID
           , DIC_FREE_TASK_CODE5_ID
           , DIC_FREE_TASK_CODE6_ID
           , DIC_FREE_TASK_CODE7_ID
           , DIC_FREE_TASK_CODE8_ID
           , DIC_FREE_TASK_CODE9_ID
           , FAL_FAL_FACTORY_FLOOR_ID
           , SCS_ADJUSTING_FLOOR
           , SCS_ADJUSTING_OPERATOR
           , SCS_NUM_ADJUST_OPERATOR
           , SCS_PERCENT_ADJUST_OPER
           , SCS_WORK_FLOOR
           , SCS_WORK_OPERATOR
           , SCS_NUM_WORK_OPERATOR
           , SCS_PERCENT_WORK_OPER
           , DIC_UNIT_OF_MEASURE_ID
           , SCS_OPEN_TIME_MACHINE
           , PAC_SUPPLIER_PARTNER_ID
           , GCO_GCO_GOOD_ID
           , SCS_AMOUNT
           , SCS_QTY_REF_AMOUNT
           , SCS_DIVISOR_AMOUNT
        from FAL_LIST_STEP_LINK
       where FAL_SCHEDULE_PLAN_ID = inFalSchedulePlanID
         and C_OPERATION_TYPE <> '3';

    ltplFalListStepLink    lcurFalListStepLinks%rowtype;
    lnPacSupplierPartnerId number;
    lnGcoGcoGoodId         number;
    lnScsAmount            number;
    lnScsQtyRefAmount      integer;
    lnScsDivisorAmount     integer;
    lnScsWeigh             integer;
    lnScsWeighMandatory    integer;
  begin
    /* Définition des valeurs indépendantes de l'itération */
    if icontext = ctxtPOX then
      lnScsWeigh           := 1;
      lnScsWeighMandatory  := 0;
    else
      lnPacSupplierPartnerId  := iPacSupplierPartnerId;
      lnGcoGcoGoodId          := iGcoGcoGoodId;
      lnScsAmount             := iScsAmount;
      lnScsQtyRefAmount       := iScsQtyRefAmount;
      lnScsDivisorAmount      := iScsDivisorAmount;
      lnScsWeigh              := iScsWeigh;
      lnScsWeighMandatory     := iScsWeighMandatory;
    end if;

    open lcurFalListStepLinks(inFalSchedulePlanID => iFAL_SCHEDULE_PLAN_ID);

    loop
      fetch lcurFalListStepLinks
       into ltplFalListStepLink;

      exit when lcurFalListStepLinks%notfound;

      /* Définition des valeurs dépendantes de l'itération */
      if icontext = ctxtPOX then
        lnPacSupplierPartnerId  := ltplFalListStepLink.PAC_SUPPLIER_PARTNER_ID;
        lnGcoGcoGoodId          := ltplFalListStepLink.GCO_GCO_GOOD_ID;
        lnScsAmount             := ltplFalListStepLink.SCS_AMOUNT;
        lnScsQtyRefAmount       := ltplFalListStepLink.SCS_QTY_REF_AMOUNT;
        lnScsDivisorAmount      := ltplFalListStepLink.SCS_DIVISOR_AMOUNT;
      end if;

      /*  Récupération ID de la séquence principale */
      lnFalTaskLinkPropID  := getNewId;

      /* -- Création opérations de propositions */
      insert into FAL_TASK_LINK_PROP
                  (FAL_TASK_LINK_PROP_ID
                 , FAL_LOT_PROP_ID
                 , SCS_STEP_NUMBER
                 , TAL_SEQ_ORIGIN
                 , C_TASK_TYPE
                 , C_OPERATION_TYPE
                 , FAL_TASK_ID
                 , SCS_SHORT_DESCR
                 , SCH_LONG_DESCR
                 , SCH_FREE_DESCR
                 , FAL_FACTORY_FLOOR_ID
                 , TAL_DUE_QTY
                 , SCS_ADJUSTING_TIME
                 , SCS_WORK_TIME
                 , SCS_PLAN_RATE
                 , SCS_QTY_REF_WORK
                 , SCS_WORK_RATE
                 , TAL_NUM_UNITS_ALLOCATED
                 , TAL_PLAN_RATE
                 , PPS_PPS_OPERATION_PROCEDURE_ID
                 , PPS_OPERATION_PROCEDURE_ID
                 , PPS_TOOLS1_ID
                 , PPS_TOOLS2_ID
                 , DIC_FREE_TASK_CODE2_ID
                 , DIC_FREE_TASK_CODE_ID
                 , C_TASK_IMPUTATION
                 , SCS_ADJUSTING_RATE
                 , SCS_QTY_FIX_ADJUSTING
                 , SCS_TRANSFERT_TIME
                 , SCS_PLAN_PROP
                 , C_RELATION_TYPE
                 , SCS_DELAY
                 , A_DATECRE
                 , A_IDCRE
                 , PPS_TOOLS3_ID
                 , PPS_TOOLS4_ID
                 , PPS_TOOLS5_ID
                 , PPS_TOOLS6_ID
                 , PPS_TOOLS7_ID
                 , PPS_TOOLS8_ID
                 , PPS_TOOLS9_ID
                 , PPS_TOOLS10_ID
                 , PPS_TOOLS11_ID
                 , PPS_TOOLS12_ID
                 , PPS_TOOLS13_ID
                 , PPS_TOOLS14_ID
                 , PPS_TOOLS15_ID
                 , DIC_FREE_TASK_CODE3_ID
                 , DIC_FREE_TASK_CODE4_ID
                 , DIC_FREE_TASK_CODE5_ID
                 , DIC_FREE_TASK_CODE6_ID
                 , DIC_FREE_TASK_CODE7_ID
                 , DIC_FREE_TASK_CODE8_ID
                 , DIC_FREE_TASK_CODE9_ID
                 , FAL_FAL_FACTORY_FLOOR_ID
                 , SCS_ADJUSTING_FLOOR
                 , SCS_ADJUSTING_OPERATOR
                 , SCS_NUM_ADJUST_OPERATOR
                 , SCS_PERCENT_ADJUST_OPER
                 , SCS_WORK_FLOOR
                 , SCS_WORK_OPERATOR
                 , SCS_NUM_WORK_OPERATOR
                 , SCS_PERCENT_WORK_OPER
                 , TAL_TSK_AD_BALANCE
                 , TAL_TSK_W_BALANCE
                 , TAL_TSK_BALANCE
                 , DIC_UNIT_OF_MEASURE_ID
                 , SCS_OPEN_TIME_MACHINE
                 , PAC_SUPPLIER_PARTNER_ID
                 , GCO_GOOD_ID
                 , SCS_AMOUNT
                 , SCS_QTY_REF_AMOUNT
                 , SCS_DIVISOR_AMOUNT
                 , SCS_WEIGH
                 , SCS_WEIGH_MANDATORY
                  )
           values (lnFalTaskLinkPropID
                 , iFAL_LOT_PROP_ID
                 , ltplFalListStepLink.SCS_STEP_NUMBER
                 , ltplFalListStepLink.SCS_STEP_NUMBER
                 , ltplFalListStepLink.C_TASK_TYPE
                 , ltplFalListStepLink.C_OPERATION_TYPE
                 , ltplFalListStepLink.FAL_TASK_ID
                 , ltplFalListStepLink.SCS_SHORT_DESCR
                 , ltplFalListStepLink.SCS_LONG_DESCR
                 , ltplFalListStepLink.SCS_FREE_DESCR
                 , ltplFalListStepLink.FAL_FACTORY_FLOOR_ID
                 , iQTE
                 , ltplFalListStepLink.SCS_ADJUSTING_TIME
                 , ltplFalListStepLink.SCS_WORK_TIME
                 , ltplFalListStepLink.SCS_PLAN_RATE
                 , ltplFalListStepLink.SCS_QTY_REF_WORK
                 , ltplFalListStepLink.SCS_WORK_RATE
                 , ltplFalListStepLink.SCS_NUM_FLOOR
                 , (iQTE / FAL_TOOLS.nvla(ltplFalListStepLink.SCS_QTY_REF_WORK, 1) ) * nvl(ltplFalListStepLink.SCS_PLAN_RATE, 0)
                 , ltplFalListStepLink.PPS_PPS_OPERATION_PROCEDURE_ID
                 , ltplFalListStepLink.PPS_OPERATION_PROCEDURE_ID
                 , ltplFalListStepLink.PPS_TOOLS1_ID
                 , ltplFalListStepLink.PPS_TOOLS2_ID
                 , ltplFalListStepLink.DIC_FREE_TASK_CODE2_ID
                 , ltplFalListStepLink.DIC_FREE_TASK_CODE_ID
                 , ltplFalListStepLink.C_TASK_IMPUTATION
                 , ltplFalListStepLink.SCS_ADJUSTING_RATE
                 , ltplFalListStepLink.SCS_QTY_FIX_ADJUSTING
                 , ltplFalListStepLink.SCS_TRANSFERT_TIME
                 , ltplFalListStepLink.SCS_PLAN_PROP
                 , ltplFalListStepLink.C_RELATION_TYPE
                 , ltplFalListStepLink.SCS_DELAY
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                 , ltplFalListStepLink.PPS_TOOLS3_ID
                 , ltplFalListStepLink.PPS_TOOLS4_ID
                 , ltplFalListStepLink.PPS_TOOLS5_ID
                 , ltplFalListStepLink.PPS_TOOLS6_ID
                 , ltplFalListStepLink.PPS_TOOLS7_ID
                 , ltplFalListStepLink.PPS_TOOLS8_ID
                 , ltplFalListStepLink.PPS_TOOLS9_ID
                 , ltplFalListStepLink.PPS_TOOLS10_ID
                 , ltplFalListStepLink.PPS_TOOLS11_ID
                 , ltplFalListStepLink.PPS_TOOLS12_ID
                 , ltplFalListStepLink.PPS_TOOLS13_ID
                 , ltplFalListStepLink.PPS_TOOLS14_ID
                 , ltplFalListStepLink.PPS_TOOLS15_ID
                 , ltplFalListStepLink.DIC_FREE_TASK_CODE3_ID
                 , ltplFalListStepLink.DIC_FREE_TASK_CODE4_ID
                 , ltplFalListStepLink.DIC_FREE_TASK_CODE5_ID
                 , ltplFalListStepLink.DIC_FREE_TASK_CODE6_ID
                 , ltplFalListStepLink.DIC_FREE_TASK_CODE7_ID
                 , ltplFalListStepLink.DIC_FREE_TASK_CODE8_ID
                 , ltplFalListStepLink.DIC_FREE_TASK_CODE9_ID
                 , ltplFalListStepLink.FAL_FAL_FACTORY_FLOOR_ID
                 , ltplFalListStepLink.SCS_ADJUSTING_FLOOR
                 , ltplFalListStepLink.SCS_ADJUSTING_OPERATOR
                 , ltplFalListStepLink.SCS_NUM_ADJUST_OPERATOR
                 , ltplFalListStepLink.SCS_PERCENT_ADJUST_OPER
                 , ltplFalListStepLink.SCS_WORK_FLOOR
                 , ltplFalListStepLink.SCS_WORK_OPERATOR
                 , ltplFalListStepLink.SCS_NUM_WORK_OPERATOR
                 , ltplFalListStepLink.SCS_PERCENT_WORK_OPER
                 , (nvl(ceil(iQTE / FAL_TOOLS.NIFZ(ltplFalListStepLink.SCS_QTY_FIX_ADJUSTING) ), 1) * nvl(ltplFalListStepLink.SCS_ADJUSTING_TIME, 0) )
                 , ( (iQTE / ltplFalListStepLink.SCS_QTY_REF_WORK) * nvl(ltplFalListStepLink.SCS_WORK_TIME, 0) )
                 , (nvl( (nvl(ceil(iQTE / FAL_TOOLS.NIFZ(ltplFalListStepLink.SCS_QTY_FIX_ADJUSTING) ), 1) * nvl(ltplFalListStepLink.SCS_ADJUSTING_TIME, 0) )
                      , 0) +
                    nvl( ( (iQTE / ltplFalListStepLink.SCS_QTY_REF_WORK) * nvl(ltplFalListStepLink.SCS_WORK_TIME, 0) ), 0)
                   )
                 , ltplFalListStepLink.DIC_UNIT_OF_MEASURE_ID
                 , ltplFalListStepLink.SCS_OPEN_TIME_MACHINE
                 , lnPacSupplierPartnerId
                 , lnGcoGcoGoodId
                 , lnScsAmount
                 , lnScsQtyRefAmount
                 , lnScsDivisorAmount
                 , lnScsWeigh
                 , lnScsWeighMandatory
                  );

      /* Copie des informations déchets récupérables des opérations */

      /* Est-ce que la matière précieuse est gérée ? Si ce n'est pas le cas, on ne fait rien */
      if GCO_I_LIB_PRECIOUS_MAT.IsPreciousMat = 1 then
        /* Est-ce que le produit terminé contient un alliage de matière précieuse ? */
        if GCO_I_LIB_PRECIOUS_MAT.doesContainsPreciousMat(inGcoGoodID => FAL_LIB_LOT_PROP.getGcoGoodID(inFalLotPropID => iFAL_LOT_PROP_ID) ) = 1 then
          /* Copie des information de déchets récupérables (copeaux) pour chaque définition d'alliage de l'opération
             de gamme également présent dans le produit terminé. */
          FAL_I_PRC_TASK_CHIP.copyTaskChipInfos(inSrcTaskID                    => ltplFalListStepLink.FAL_SCHEDULE_STEP_ID
                                              , inDestTaskID                   => lnFalTaskLinkPropID
                                              , ivCSrcTaskKind                 => '2'   -- Gamme
                                              , ivCDestTaskKind                => '4'   -- Prop. lot
                                              , ibOnlyIfRefGoodContainsAlloy   => true
                                               );
--           FAL_I_PRC_TASK_CHIP.copyToTaskLinkProp(inFalListStepLinkID => ltplFalListStepLink.FAL_SCHEDULE_STEP_ID, inFalTaskLinkPropID => lnFalTaskLinkPropID);
        end if;
      end if;
    end loop;

    -- Machines utilisables
    insert into FAL_TASK_LINK_PROP_USE
                (FAL_TASK_LINK_PROP_USE_ID
               , FAL_FACTORY_FLOOR_ID
               , FAL_TASK_LINK_PROP_ID
               , SCS_QTY_REF_WORK
               , SCS_WORK_TIME
               , SCS_PRIORITY
               , SCS_EXCEPT_MACH
               , A_DATECRE
               , A_IDCRE
                )
      select GetNewId
           , LSU.FAL_FACTORY_FLOOR_ID
           , TLP.FAL_TASK_LINK_PROP_ID
           , LSU.LSU_QTY_REF_WORK
           , LSU.LSU_WORK_TIME
           , LSU.LSU_PRIORITY
           , LSU.LSU_EXCEPT_MACH
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        from FAL_TASK_LINK_PROP TLP
           , FAL_LIST_STEP_LINK LSL
           , FAL_LIST_STEP_USE LSU
       where TLP.FAL_LOT_PROP_ID = iFAL_LOT_PROP_ID
         and LSL.FAL_SCHEDULE_PLAN_ID = iFAL_SCHEDULE_PLAN_ID
         and TLP.SCS_STEP_NUMBER = LSL.SCS_STEP_NUMBER
         and LSL.FAL_SCHEDULE_STEP_ID = LSU.FAL_SCHEDULE_STEP_ID
         and LSL.C_OPERATION_TYPE <> '3';
  end;

  /**
  * Procedure GetSupplyQties
  * Description : Obtention des qtés d'une appro
  *
  * @author ECA
  * @public
  * @param   PrmFAL_NETWORK_SUPPLY_ID : Appro
  * @return  OutFAN_STK_QTY : Qté attribuée stock
  * @return  OutFAN_FREE_QTY : Qté libre
  */
  procedure GetSupplyQties(
    PrmFAL_NETWORK_SUPPLY_ID        FAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID%type
  , OutFAN_STK_QTY           in out FAL_NETWORK_SUPPLY.FAN_STK_QTY%type
  , OutFAN_FREE_QTY          in out FAL_NETWORK_SUPPLY.FAN_FREE_QTY%type
  )
  is
    cursor C1
    is
      select FAN_STK_QTY
           , FAN_FREE_QTY
        from FAL_NETWORK_SUPPLY
       where FAL_NETWORK_SUPPLY_ID = PrmFAL_NETWORK_SUPPLY_ID;
  begin
    open C1;

    fetch C1
     into OutFAN_STK_QTY
        , OutFAN_FREE_QTY;

    close C1;
  end;

/**
* Fonction GetDocumentLastDelay
* Description : Recherche du délais de sélection des Approvisionnements, dans le cas ou l'on est en délai fixe.
*
* aDOC_POSITION_DETAIL_ID   : Détail position de Document
* aDIC_DELAY_UPDATE_TYPE_ID : Type de délai recherché
* aDefaultLastDelay         : Valeur retournée si le type de délai n'existe pas pour le document
*/
  function GetApproFixDelay(
    aDOC_POSITION_DETAIL_ID   in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  , aDIC_DELAY_UPDATE_TYPE_ID in varchar2
  , aDefaultLastDelay         in date
  )
    return date
  is
    cursor CUR_DOC_DELAY_HISTORY(PrmDIC_DELAY_UPDATE_TYPE_ID varchar2)
    is
      select   DHI_FINAL_DELAY
          from DOC_DELAY_HISTORY
         where DOC_POSITION_DETAIL_ID = aDOC_POSITION_DETAIL_ID
           and DIC_DELAY_UPDATE_TYPE_ID = PrmDIC_DELAY_UPDATE_TYPE_ID
      order by DOC_DELAY_HISTORY_ID desc;

    aDHI_FINAL_DELAY          DOC_DELAY_HISTORY.DHI_FINAL_DELAY%type;
    vDIC_DELAY_UPDATE_TYPE_ID varchar2(10);
  begin
    vDIC_DELAY_UPDATE_TYPE_ID  := aDIC_DELAY_UPDATE_TYPE_ID;

    -- Si pas de détail position, on renvoie le délai par défaut
    if aDOC_POSITION_DETAIL_ID is null then
      return nvl(aDefaultLastDelay, sysdate);
    end if;

    -- Recherche de la configuration, si non précisée
    if    vDIC_DELAY_UPDATE_TYPE_ID is null
       or trim(vDIC_DELAY_UPDATE_TYPE_ID) = '' then
      vDIC_DELAY_UPDATE_TYPE_ID  := PCS.PC_PUBLIC.GetConfig('FAL_APPRO_DELAY_SELECTION');
    end if;

    -- Si toujours inexistante, renvoi du délais par défaut.
    if    vDIC_DELAY_UPDATE_TYPE_ID is null
       or trim(vDIC_DELAY_UPDATE_TYPE_ID) = '' then
      return nvl(aDefaultLastDelay, sysdate);
    -- Sinon recherche du dernier délai du document
    else
      begin
        open CUR_DOC_DELAY_HISTORY(vDIC_DELAY_UPDATE_TYPE_ID);

        fetch CUR_DOC_DELAY_HISTORY
         into aDHI_FINAL_DELAY;

        close CUR_DOC_DELAY_HISTORY;

        return nvl(aDHI_FINAL_DELAY, nvl(aDefaultLastDelay, sysdate) );
      exception
        when no_data_found then
          begin
            close CUR_DOC_DELAY_HISTORY;

            return nvl(aDefaultLastDelay, sysdate);
          end;
      end;
    end if;
  end GetApproFixDelay;

  /**
  * Procedure DeleteProfile
  * Description : Suppression d'un profil de paramètres CB
  *
  * @author ECA
  * @public
  * @param   aFAL_CB_PARAMETER_ID : Profil de paramètres
  */
  procedure DeleteProfile(aFAL_CB_PARAMETER_ID in number)
  is
  begin
    delete from FAL_CB_PARAMETERS
          where FAL_CB_PARAMETERS_id = aFAL_CB_PARAMETER_ID;
  end;
end FAL_CALCUL_BESOIN;   -- Fin du Package
