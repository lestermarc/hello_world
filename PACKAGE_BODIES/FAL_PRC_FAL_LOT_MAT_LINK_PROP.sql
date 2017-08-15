--------------------------------------------------------
--  DDL for Package Body FAL_PRC_FAL_LOT_MAT_LINK_PROP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_FAL_LOT_MAT_LINK_PROP" 
is
  cFalBloc        constant integer := to_number(PCS.PC_CONFIG.GetConfig('FAL_BLOC') );
  cReplaceOnStock constant boolean := PCS.PC_CONFIG.GetBooleanConfig('FAL_CPT_REPLACE_ON_STOCK');
  cReplaceOnDate  constant boolean := PCS.PC_CONFIG.GetBooleanConfig('FAL_CPT_REPLACE_ON_DATE');

  type T_PPS_NOM_BOND is record(
    PPS_PPS_NOMENCLATURE_ID  PPS_NOM_BOND.PPS_PPS_NOMENCLATURE_ID%type
  , C_TYPE_COM               PPS_NOM_BOND.C_TYPE_COM%type
  , C_KIND_COM               PPS_NOM_BOND.C_KIND_COM%type
  , C_DISCHARGE_COM          PPS_NOM_BOND.C_DISCHARGE_COM%type
  , FAL_SCHEDULE_STEP_ID     PPS_NOM_BOND.FAL_SCHEDULE_STEP_ID%type
  , GCO_GOOD_ID              PPS_NOM_BOND.GCO_GOOD_ID%type
  , COM_UTIL_COEFF           PPS_NOM_BOND.COM_UTIL_COEFF%type
  , COM_PDIR_COEFF           PPS_NOM_BOND.COM_PDIR_COEFF%type
  , COM_REF_QTY              PPS_NOM_BOND.COM_REF_QTY%type
  , COM_RES_TEXT             PPS_NOM_BOND.COM_RES_TEXT%type
  , COM_PERCENT_WASTE        PPS_NOM_BOND.COM_PERCENT_WASTE%type
  , COM_FIXED_QUANTITY_WASTE PPS_NOM_BOND.COM_FIXED_QUANTITY_WASTE%type
  , COM_QTY_REFERENCE_LOSS   PPS_NOM_BOND.COM_QTY_REFERENCE_LOSS%type
  , COM_END_VALID            PPS_NOM_BOND.COM_END_VALID%type
  , COM_TEXT                 PPS_NOM_BOND.COM_TEXT%type
  , COM_POS                  PPS_NOM_BOND.COM_POS%type
  , COM_SUBSTITUT            PPS_NOM_BOND.COM_SUBSTITUT%type
  , COM_RES_NUM              PPS_NOM_BOND.COM_RES_NUM%type
  , C_REMPLACEMENT_NOM       PPS_NOM_BOND.C_REMPLACEMENT_NOM%type
  , COM_REMPLACEMENT         PPS_NOM_BOND.COM_REMPLACEMENT%type
  , COM_INTERVAL             PPS_NOM_BOND.COM_INTERVAL%type
  , COM_INCREASE_COST        PPS_NOM_BOND.COM_INCREASE_COST%type
  , PPS_NOM_BOND_ID          PPS_NOM_BOND.PPS_NOM_BOND_ID%type
  , STM_LOCATION_ID          PPS_NOM_BOND.STM_LOCATION_id%type
  , STM_STOCK_ID             PPS_NOM_BOND.STM_STOCK_ID%type
  , PDT_BLOCK_EQUI           GCO_PRODUCT.PDT_BLOCK_EQUI%type
  , PDT_STOCK_MANAGEMENT     GCO_PRODUCT.PDT_STOCK_MANAGEMENT%type
  , GOO_NUMBER_OF_DECIMAL    GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type
  , SCS_STEP_NUMBER          FAL_LIST_STEP_LINK.SCS_STEP_NUMBER%type
  , PAC_SUPPLIER_PARTNER_ID  FAL_LIST_STEP_LINK.PAC_SUPPLIER_PARTNER_ID%type
  , COM_MARK_TOPO            PPS_NOM_BOND.COM_MARK_TOPO%type
  , COM_WEIGHING             PPS_NOM_BOND.COM_WEIGHING%type
  , COM_WEIGHING_MANDATORY   PPS_NOM_BOND.COM_WEIGHING_MANDATORY%type
  );

  function Calcul_A(PrmQty number, PrmPPS_NOM_BOND T_PPS_NOM_BOND, context integer)
    return number
  is
  begin
    -- Détermine la quantité besoin ...
    if context = context_PDP then
      return FAL_TOOLS.ArrondiSuperieur(PrmQty * PrmPPS_NOM_BOND.COM_PDIR_COEFF / PrmPPS_NOM_BOND.COM_REF_QTY
                                      , PrmPPS_NOM_BOND.GCO_GOOD_ID
                                      , PrmPPS_NOM_BOND.GOO_NUMBER_OF_DECIMAL
                                       );
    end if;

    if context = context_CB then
      return FAL_TOOLS.ArrondiSuperieur(PrmQTY * PrmPPS_NOM_BOND.COM_UTIL_COEFF / PrmPPS_NOM_BOND.COM_REF_QTY
                                      , PrmPPS_NOM_BOND.GCO_GOOD_ID
                                      , PrmPPS_NOM_BOND.GOO_NUMBER_OF_DECIMAL
                                       );
    end if;
  end;

  function GetDefaultProdNomenclatureID(aGoodID number)
    return number
  is
    Resultat number;
  begin
    select PPS_NOMENCLATURE_ID
      into Resultat
      from PPS_NOMENCLATURE
     where GCO_GOOD_ID = aGoodID
       and C_TYPE_NOM = 2
       and NOM_DEFAULT = 1;

    return resultat;
  exception
    when no_data_found then
      return null;
  end;

  function GetFal_Schedule_Plan_ID(PrmNomenclatureID number)
    return number
  is
    resultat number;
  begin
    select FAL_SCHEDULE_PLAN_ID
      into resultat
      from PPS_NOMENCLATURE
     where PPS_NOMENCLATURE_ID = PrmNomenclatureID;

    return resultat;
  exception
    when no_data_found then
      return null;
  end;

  /**
  * function : GetOperationBeginPlanDate
  * Description : Recherche la date début planifiée d'une opération de proposition
  *
  * @created
  * @lastUpdate CLG
  * @public
  * @param   iPropId      Id de proposition
  * @param   iOpeSeq      Séquence de l'opération
  * @param   iDefaultDate Date par défaut si l'opération est non trouvée
  * @return  Date début d'opération
  *
  */
  function GetOperationBeginPlanDate(iPropId in number, iOpeSeq in integer, iDefaultDate in date)
    return date
  is
    ldBeginDate date;
  begin
    if nvl(iOpeSeq, 0) = 0 then
      return iDefaultDate;
    end if;

    select TAL_BEGIN_PLAN_DATE
      into ldBeginDate
      from FAL_TASK_LINK_PROP
     where FAL_LOT_PROP_ID = iPropId
       and TAL_SEQ_ORIGIN = iOpeSeq;   -- dans FAL_TASK_LINK_PROP, TAL_SEQ_ORIGIN = SCS_STEP_NUMBER

    return nvl(ldBeginDate, iDefaultDate);
  exception
    when no_data_found then
      return iDefaultDate;
  end;

  -- Initialisation de stock et emplacement conso
  procedure InitLocationAndStockId(iComponent in T_PPS_NOM_BOND, oStmStockId in out number, oStmLocationId in out number)
  is
    lProductStockId    number;
    lProductLocationId number;
  begin
    if iComponent.STM_LOCATION_ID is not null then
      oStmLocationId  := iComponent.STM_LOCATION_ID;
      oStmStockId     := iComponent.STM_STOCK_ID;
    elsif iComponent.STM_STOCK_ID is not null then
      oStmStockId     := iComponent.STM_STOCK_ID;
      -- Recherche sur le plus petit emplacement classification pour le stock en cours
      oStmLocationId  := FAL_TOOLS.GetMinClassifLocationOfStock(oStmStockId);
    else
      select STM_STOCK_ID
           , STM_LOCATION_ID
        into lProductStockId
           , lProductLocationId
        from GCO_PRODUCT
       where GCo_GOOD_ID = iComponent.GCO_GOOD_ID;

      if lProductLocationId is not null then
        oStmStockId     := lProductStockId;
        oStmLocationId  := lProductLocationId;
      elsif lProductStockId is not null then
        oStmStockId     := lProductStockId;
        oStmLocationId  := FAL_TOOLS.GetMinClassifLocationOfStock(oStmStockId);
      else
        oStmStockId     := FAL_TOOLS.GetConfig_StockID('GCO_DefltSTOCK');
        oStmLocationId  := FAL_TOOLS.GetMinClassifLocationOfStock(oStmStockId);
      end if;
    end if;
  end;

  /**
  * function GetSumSupplyFree
  * Description : Retoune la somme des appros libres pour le produit pour les stocks sélectionnés
  *
  * @created
  * @lastUpdate CLG
  * @public
  * @param iGoodId        Id du bien
  * @param iStockListId   Liste des stocks
  * @param iNeedDate      date du besoin
  * @return  Somme des appros libres
  */
  function GetSumSupplyFree(iGoodId GCO_GOOD.GCO_GOOD_ID%type, iStockListId varchar, iNeedDate date)
    return FAL_NETWORK_NEED.FAN_FREE_QTY%type
  is
    lnFreeQty FAL_NETWORK_SUPPLY.FAN_FREE_QTY%type;
  begin
    if iStockListId is null then
      return 0;
    end if;

    select sum(nvl(FAN.FAN_FREE_QTY, 0) )
      into lnFreeQty
      from FAL_NETWORK_SUPPLY FAN
         , table(IdListToTable(iStockListId) ) STO
     where FAN.STM_STOCK_ID = STO.column_value
       and FAN.GCO_GOOD_ID = iGoodId
       and STM_I_LIB_MOVEMENT.VerifyForecastStockPosCond(iGoodId            => FAN.GCO_GOOD_ID
                                                       , iPiece             => FAN.FAN_PIECE
                                                       , iSet               => FAN.FAN_SET
                                                       , iVersion           => FAN.FAN_VERSION
                                                       , iChronological     => FAN.FAN_CHRONOLOGICAL
                                                       , iQualityStatusId   => GCO_I_LIB_QUALITY_STATUS.GetReceiptStatus(FAN.GCO_GOOD_ID)
                                                       , iDateRequest       => iNeedDate
                                                        ) is not null;

    return nvl(lnFreeQty, 0);
  end;

  /**
  * function GetSumNeedFree
  * Description : Retoune la somme des besoins libres pour le produit pour les stocks sélectionnés
  *
  * @created
  * @lastUpdate CLG
  * @public
  * @param iGoodId        Id du bien
  * @param iStockListId   Liste des stocks
  * @param iNeedDate      date du besoin
  * @return  Somme des besoins libres
  */
  function GetSumNeedFree(iGoodId in GCO_GOOD.GCO_GOOD_ID%type, iStockListId in varchar2, iNeedDate in date)
    return FAL_NETWORK_NEED.FAN_FREE_QTY%type
  is
    lnFreeQty FAL_NETWORK_NEED.FAN_FREE_QTY%type;
  begin
    if iStockListId is null then
      return 0;
    end if;

    select sum(nvl(FAN.FAN_FREE_QTY, 0) )
      into lnFreeQty
      from FAL_NETWORK_NEED FAN
         , table(IdListToTable(iStockListId) ) STO
     where FAN.STM_STOCK_ID = STO.column_value
       and FAN.GCO_GOOD_ID = iGoodId
       and STM_I_LIB_MOVEMENT.VerifyForecastStockPosCond(iGoodId            => FAN.GCO_GOOD_ID
                                                       , iPiece             => FAN.FAN_PIECE
                                                       , iSet               => FAN.FAN_SET
                                                       , iVersion           => FAN.FAN_VERSION
                                                       , iChronological     => FAN.FAN_CHRONOLOGICAL
                                                       , iQualityStatusId   => GCO_I_LIB_QUALITY_STATUS.GetReceiptStatus(FAN.GCO_GOOD_ID)
                                                       , iDateRequest       => iNeedDate
                                                        ) is not null;

    return nvl(lnFreeQty, 0);
  end;

  procedure ProcessusGenePropComp(
    aPrmCBStandardLotQty           number
  , aPrmCBNomenclatureID           number
  , aPrmCBcSchedulePlanCode        number
  , aPrmCBGammeID                  number
  , aLotPropID                     number
  , aDocRecordID                   number
  , VarPPS_NOM_BOND         in out T_PPS_NOM_BOND
  , aSTM_STOCK_ID                  number
  , aSTM_LOCATION_ID               number
  , aLotPropBeginDate              date
  , aLotPropEndDate                date
  , aPrmaCalculByStock             integer
  , context                        integer
  , A                              number
  , X                              number   -- Uniquement utilisé pour le calcul des coeff !!!
  , aGCO_GCO_GOOD_ID               number   -- Produit générique d'origine
  , iSeqLinkOnCptOrigin            FAL_LOT_MAT_LINK_PROP.LOM_TASK_SEQ%type
  , aCMA_FIX_DELAY                 integer
  , aLotTotalQty                   number
  , aProductToReplace              boolean default false
  , aReplacingProduct              boolean default false
  , aReplaceQty                    number default 0
  , iStockReplace                  boolean default false
  , iDateReplace                   boolean default false
  )
  is
    liTaskSeq                integer;
    LocalSTM_STOCK_ID        number;
    LocalSTM_LOCATION_ID     number;
    aLOM_NEED_QTY            number;
    aInterval                number;
    aNeedDate                date;
    aPourcentDechet          number;
    aQteRefPerte             number;
    aQteFixeDechet           number;
    aGammeID                 number;
    aFAL_PIC_ID              number;
    NextLOM_SEQ              FAL_LOT_MAT_LINK_PROP.LOM_SEQ%type;
    agoo_secondary_reference GCo_GOOD.goo_secondary_reference%type;
    agoo_major_reference     GCo_GOOD.goo_major_reference%type;
    ades_short_description   GCo_DESCRIPTION.des_short_description%type;
    ades_long_description    GCo_DESCRIPTION.des_long_description%type;
    ades_free_description    GCo_DESCRIPTION.des_free_description%type;
    aLOM_BOM_REQ_QTY         FAL_LOT_MAT_LINK_PROP.LOM_BOM_REQ_QTY%type;
    aLOM_ADJUSTED_QTY        FAL_LOT_MAT_LINK_PROP.LOM_ADJUSTED_QTY%type;
    ForLOM_UTIL_COEF         FAL_LOT_MAT_LINK_PROP.LOM_UTIL_COEF%type;
    aLOM_FULL_REQ_QTY        FAL_LOT_MAT_LINK_PROP.LOM_FULL_REQ_QTY%type;
    liStockReplace           integer                                       := 0;
    liDateReplace            integer                                       := 0;
  begin
    if iStockReplace then
      liStockReplace  := 1;
    end if;

    if iDateReplace then
      liDateReplace  := 1;
    end if;

    -- Déterminer LOM_TASK_SEQ
    liTaskSeq          := nvl(iSeqLinkOnCptOrigin, VarPPS_NOM_BOND.SCS_STEP_NUMBER);

    if VarPPS_NOM_BOND.C_KIND_COM not in('4', '5') then   -- Si ce n'est pas un lien texte, ou fournit par le sous-traitant
      -- Déterminer le stock et l'emplacement
      if     (aPrmaCalculByStock = 1)
         and (context = context_CB) then
        LocalSTM_STOCK_ID     := aSTM_STOCK_ID;
        LocalSTM_LOCATION_ID  := aSTM_LOCATION_ID;
      else
        -- dans ce cas je dois bien initialiser ces 4 variables
        LocalSTM_STOCK_ID     := aSTM_STOCK_ID;
        LocalSTM_LOCATION_ID  := aSTM_LOCATION_ID;

        if VarPPS_NOM_BOND.PDT_STOCK_MANAGEMENT = 1 then
          -- Si ce n'est pas un service alors Initialisation des stock et emplacement selon les configurations
          InitLocationAndStockId(VarPPS_NOM_BOND, LocalSTM_STOCK_ID, LocalSTM_LOCATION_ID);
        end if;
      end if;

      FAL_TOOLS.GetMajorSecShortFreeLong(VarPPS_NOM_BOND.GCO_GOOD_iD
                                       , agoo_major_reference
                                       , agoo_secondary_reference
                                       , ades_short_description
                                       , ades_free_description
                                       , ades_long_description
                                        );
      aPourcentDechet  := VarPPS_NOM_BOND.COM_PERCENT_WASTE;
      aQteRefPerte     := VarPPS_NOM_BOND.COM_QTY_REFERENCE_LOSS;
      aQteFixeDechet   := VarPPS_NOM_BOND.COM_FIXED_QUANTITY_WASTE;
    else
      agoo_secondary_reference  := null;
      ades_short_description    := null;
      ades_long_description     := null;
      ades_free_description     := null;
      aPourcentDechet           := 0;
      aQteRefPerte              := 0;
      aQteFixeDechet            := 0;
    end if;

    if context = context_PDP then
      VarPPS_NOM_BOND.COM_PDIR_COEFF  := X * VarPPS_NOM_BOND.COM_PDIR_COEFF / FAL_TOOLS.nvla(VarPPS_NOM_BOND.cOM_REF_QTY, 1);
      ForLOM_UTIL_COEF                := VarPPS_NOM_BOND.COM_PDIR_COEFF;
    end if;

    if context = context_CB then
      VarPPS_NOM_BOND.COM_UTIL_COEFF  := X * VarPPS_NOM_BOND.COM_UTIL_COEFF / FAL_TOOLS.nvla(VarPPS_NOM_BOND.cOM_REF_QTY, 1);
      ForLOM_UTIL_COEF                := VarPPS_NOM_BOND.COM_UTIL_COEFF;
    end if;

    aLOM_BOM_REQ_QTY   := A;

    -- Cas du remplacement partiel, le produit est le remplacé, la qté sup inf sert à indiquer
    -- la quantité manquante, on ne tient pas compte des déchets de consomation
    if aProductToReplace then
      aLOM_ADJUSTED_QTY  := aReplaceQty - aLOM_BOM_REQ_QTY;
    -- Cas du remplacement partiel, le produit est le remplacant, la qté sup inf sert à indiquer
    -- la quantité en trop ainsi que les déchets de consommation
    elsif aReplacingProduct then
      if nvl(aReplaceQty, 0) <> 0 then
        aLOM_ADJUSTED_QTY  := -(aReplaceQty *(ForLOM_UTIL_COEF / X) );
      else
        aLOM_ADJUSTED_QTY  := 0;
      end if;

      aLOM_ADJUSTED_QTY  :=
        aLOM_ADJUSTED_QTY +
        FAL_TOOLS.CalcTotalTrashQuantity(aAskedQty            => (A + aLOM_ADJUSTED_QTY)
                                       , aTrashPercent        => aPourcentDechet
                                       , aTrashFixedQty       => aQteFixeDechet
                                       , aTrashReferenceQty   => aQteRefPerte
                                        );
    else
      -- Sinon calcul de la quantité de déchets
      aLOM_ADJUSTED_QTY  :=
        FAL_TOOLS.CalcTotalTrashQuantity(aAskedQty            => A, aTrashPercent => aPourcentDechet, aTrashFixedQty => aQteFixeDechet
                                       , aTrashReferenceQty   => aQteRefPerte);
    end if;

    -- Arrondi supérieur selon le produit
    aLOM_ADJUSTED_QTY  := FAL_TOOLS.ArrondiSuperieur(aLOM_ADJUSTED_QTY, VarPPS_NOM_BOND.GCO_GOOD_ID, VarPPS_NOM_BOND.GOO_NUMBER_OF_DECIMAL);
    -- Qté Besoin Cpt
    aLOM_NEED_QTY      := 0;

    if     (VarPPS_NOM_BOND.C_TYPE_COM = '1')
       and (VarPPS_NOM_BOND.C_KIND_COM = '1')
       and (VarPPS_NOM_BOND.PDT_STOCK_MANAGEMENT = 1) then
      aLOM_NEED_QTY  := nvl(A, 0) + nvl(aLOM_ADJUSTED_QTY, 0);
    end if;

    aLOM_FULL_REQ_QTY  := nvl(aLOM_BOM_REQ_QTY, 0) + nvl(aLOM_ADJUSTED_QTY, 0);

    -- Déterminer le décalage ...
    if aCMA_FIX_DELAY = 1 then
      aInterval  := nvl(VarPPS_NOM_BOND.COM_INTERVAL, 0);
    else
      aInterval  := (aLotTotalQty / FAL_TOOLS.nvla(aPrmCBStandardLotQty, 1) ) * nvl(VarPPS_NOM_BOND.COM_INTERVAL, 0);
    end if;

    -- Récupérer la gamme opératoire associée au produit ...
    aGammeID           := GetFal_Schedule_Plan_ID(aPrmCBNomenclatureID);
    -- Déterminer la date besoin ...
    aNeedDate          := aLotPropBeginDate;   -- Par défaut ...

    if    (aPrmCBcSchedulePlanCode = '1')
       or (     (aPrmCBGammeID <> nvl(aGammeID, 0) )
           and (nvl(aGammeID, 0) <> 0) ) then
      if aInterval = 0 then
        aNeedDate  := aLotPropBeginDate;
      else
        aNeedDate  :=
          FAL_SCHEDULE_FUNCTIONS.getdecalageforwarddate(null
                                                      , null
                                                      , null
                                                      , null
                                                      , null
                                                      , FAL_SCHEDULE_FUNCTIONS.getdefaultcalendar
                                                      , aLotPropBeginDate
                                                      , trunc(aInterval)
                                                       );

        if aNeedDate > aLotPropEndDate then
          aNeedDate  := aLotPropEndDate;
        end if;
      end if;
    end if;

    if    (aPrmCBcSchedulePlanCode = '2')
       or (aPrmCBcSchedulePlanCode = '3') then
      if nvl(liTaskSeq, 0) = 0 then
        aNeedDate  := aLotPropBeginDate;
      else
        aNeedDate  := GetOperationBeginPlanDate(aLotPropID, liTaskSeq, aLotPropBeginDate);
      end if;
    end if;

    -- Recherche du FAL_PIC_ID du FAL_LOT_PROP
    select FAL_PIC_ID
      into aFAL_PIC_ID
      from FAL_LOT_PROP
     where FAL_LOT_PROP_ID = aLotPropID;

    -- Récupération de la prochaine séquence du composant
    select nvl(max(LOM_SEQ), 0) + PCS.PC_CONFIG.GetConfig('FAL_COMPONENT_NUMBERING')
      into NextLOM_SEQ
      from FAL_LOT_MAT_LINK_PROP
     where FAL_LOT_PROP_ID = aLotPropID;

    -- Génération de la proposition du composant
    insert into FAL_LOT_MAT_LINK_PROP
                (FAL_LOT_MAT_LINK_PROP_ID
               , FAL_LOT_PROP_ID
               , DOC_RECORD_ID
               , GCO_GOOD_ID
               , GCO_GCO_GOOD_ID
               , LOM_TASK_SEQ
               , STM_STOCK_ID
               , STM_LOCATION_ID
               , LOM_NEED_QTY
               , LOM_INTERVAL
               , LOM_NEED_DATE
               , A_DATECRE
               , FAL_PIC_ID
               , A_IDCRE
               , LOM_SEQ
               , LOM_SUBSTITUT
               , LOM_STOCK_MANAGEMENT
               , LOM_SECONDARY_REF
               , LOM_SHORT_DESCR
               , LOM_LONG_DESCR
               , LOM_FREE_DECR
               , LOM_POS
               , LOM_FRE_NUM
               , LOM_TEXT
               , LOM_FREE_TEXT
               , LOM_UTIL_COEF
               , LOM_BOM_REQ_QTY
               , LOM_ADJUSTED_QTY
               , LOM_ADJUSTED_QTY_RECEIPT
               , LOM_FULL_REQ_QTY
               , LOM_CONSUMPTION_QTY
               , LOM_REJECTED_QTY
               , LOM_BACK_QTY
               , LOM_PT_REJECT_QTY
               , LOM_CPT_TRASH_QTY
               , LOM_CPT_RECOVER_QTY
               , LOM_CPT_REJECT_QTY
               , LOM_EXIT_RECEIPT
               , LOM_MAX_RECEIPT_QTY
               , LOM_MAX_FACT_QTY
               , LOM_AVAILABLE_QTY
               , LOM_PRICE
               , LOM_MISSING
               , LOM_REF_QTY
               , C_DISCHARGE_COM
               , C_CHRONOLOGY_TYPE
               , C_TYPE_COM
               , C_KIND_COM
               , PC_YEAR_WEEK_ID
               , LOM_PERCENT_WASTE
               , LOM_QTY_REFERENCE_LOSS
               , LOM_FIXED_QUANTITY_WASTE
               , LOM_INCREASE_COST
               , LOM_MARK_TOPO
               , LOM_WEIGHING
               , LOM_WEIGHING_MANDATORY
               , LOM_STK_REPLACE
               , LOM_DATE_REPLACE
                )
         values (GetNewId
               , aLotPropID   -- FAL_LOT_PROP_ID
               , aDocRecordID   -- DOC_RECORD_ID
               , VarPPS_NOM_BOND.GCO_GOOD_iD   -- GCO_GOOD_ID
               , aGCO_GCO_GOOD_ID   -- GCO_GCO_GOOD_ID (produit générique d'origine).
               , liTaskSeq   -- LOM_TASK_SEQ
               , LocalSTM_STOCK_ID   -- STM_STOCK_ID
               , localSTM_LOCATION_ID   -- STM_LOCATION_ID
               , aLOM_NEED_QTY   -- LOM_NEED_QTY
               , aInterval   -- LOM_INTERVAL
               , aneeddate   -- LOM_NEED_DATE
               , sysdate   -- A_DATECRE
               , aFAL_PIC_ID   -- FAL_PIC_ID
               , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
               , NextLOM_SEQ   -- LOM_SEQ
               , VarPPS_NOM_BOND.COM_SUBSTITUT   -- LOM_SUBSTITUT
               , VarPPS_NOM_BOND.PDT_STOCK_MANAGEMENT   -- LOM_STOCK_MANAGEMENT
               , agoo_secondary_reference   -- LOM_SECONDARY_REF
               , ades_short_description   -- LOM_SHORT_DESCR
               , ades_long_description   -- LOM_LONG_DESCR
               , ades_free_description   -- LOM_FREE_DECR
               , VarPPS_NOM_BOND.COM_POS   -- LOM_POS
               , VarPPS_NOM_BOND.COM_RES_NUM   -- LOM_FRE_NUM
               , VarPPS_NOM_BOND.COM_TEXT   -- LOM_TEXT
               , VarPPS_NOM_BOND.COM_RES_TEXT   -- LOM_FREE_TEXT
               , ForLOM_UTIL_COEF   -- LOM_UTIL_COEF
               , aLOM_BOM_REQ_QTY   -- LOM_BOM_REQ_QTY
               , aLOM_ADJUSTED_QTY   -- LOM_ADJUSTED_QTY
               , 0   -- LOM_ADJUSTED_QTY_RECEIPT
               , aLOM_FULL_REQ_QTY   -- LOM_FULL_REQ_QTY
               , 0   -- LOM_CONSUMPTION_QTY
               , 0   -- LOM_REJECTED_QTY
               , 0   -- LOM_BACK_QTY
               , 0   -- LOM_PT_REJECT_QTY
               , 0   -- LOM_CPT_TRASH_QTY
               , 0   -- LOM_CPT_RECOVER_QTY
               , 0   -- LOM_CPT_REJECT_QTY
               , 0   -- LOM_EXIT_RECEIPT
               , 0   -- LOM_MAX_RECEIPT_QTY
               , 0   -- LOM_MAX_FACT_QTY
               , 0   -- LOM_AVAILABLE_QTY
               , 0   -- LOM_PRICE
               , 0   -- LOM_MISSING
               , VarPPS_NOM_BOND.COM_REF_QTY   -- LOM_REF_QTY
               , VarPPS_NOM_BOND.C_DISCHARGE_COM   -- C_DISCHARGE_COM
               , (select C_CHRONOLOGY_TYPE
                    from GCO_CHARACTERIZATION
                   where GCO_GOOD_ID = VarPPS_NOM_BOND.GCO_GOOD_ID
                     and C_CHARACT_TYPE = '5')   -- C_CHRONOLOGY_TYPE
               , VarPPS_NOM_BOND.C_TYPE_COM   -- C_TYPE_COM
               , VarPPS_NOM_BOND.C_KIND_COM   -- C_KIND_COM
               , null   -- PC_YEAR_WEEK_ID
               , nvl(aPourcentDechet, 0)   -- LOM_PERCENT_WASTE
               , nvl(aQteRefPerte, 0)   -- LOM_QTY_REFERENCE_LOSS
               , nvl(aQteFixeDechet, 0)   -- LOM_FIXED_QUANTITY_WASTE
               , VarPPS_NOM_BOND.COM_INCREASE_COST
               , VarPPS_NOM_BOND.COM_MARK_TOPO
               , VarPPS_NOM_BOND.COM_WEIGHING   --LOM_WEIGHING
               , VarPPS_NOM_BOND.COM_WEIGHING_MANDATORY   --LOM_WEIGHING_MANDATORY
               , liStockReplace
               , liDateReplace
                );
  end;

  procedure GphGenePropComp(
    aPrmCBStandardLotQty    number
  , aPrmCBNomenclatureID    number
  , aPrmCBcSchedulePlanCode number
  , aPrmCBGammeID           number
  , aNomenclatureID         number
  , aCreatedPropID          number
  , aDocRecordID            number
  , aSTM_STOCK_ID           number
  , aSTM_LOCATION_ID        number
  , aLotTotalQty            number
  , aLotPropBeginDate       date
  , aLotPropEndDate         date
  , aPrmaCalculByStock      integer
  , context                 integer
  , X                       number
  , aPrmCBSelectedStocks    varchar
  , aFAL_SUPPLY_REQUEST_ID  number
  , iSeqLinkOnCptOrigin     FAL_LOT_MAT_LINK_PROP.LOM_TASK_SEQ%type
  , iLevel                  integer
  , aCMA_FIX_DELAY          integer
  , aProductToReplace       boolean default false
  , aReplacingProduct       boolean default false
  , aReplaceQty             number default 0
  , iGoodId                 number default null
  , iForceReplace           boolean default false
  )
  is
    -- Selection de tous les composants de la nomenclature de Type ACTIF, genre PSEUDO ou composant
    cursor CurComponent(PrmPPS_NOMENCLATURE_ID number)
    is
      select   NOM.PPS_PPS_NOMENCLATURE_ID
             , NOM.C_TYPE_COM
             , NOM.C_KIND_COM
             , NOM.C_DISCHARGE_COM
             , NOM.FAL_SCHEDULE_STEP_ID
             , NOM.GCO_GOOD_ID
             , nvl(NOM.COM_UTIL_COEFF, 1) COM_UTIL_COEFF
             , nvl(NOM.COM_PDIR_COEFF, 1) COM_PDIR_COEFF
             , nvl(NOM.COM_REF_QTY, 1) COM_REF_QTY
             , NOM.COM_RES_TEXT
             , nvl(NOM.COM_PERCENT_WASTE, 0) COM_PERCENT_WASTE
             , nvl(NOM.COM_FIXED_QUANTITY_WASTE, 0) COM_FIXED_QUANTITY_WASTE
             , nvl(NOM.COM_QTY_REFERENCE_LOSS, 0) COM_QTY_REFERENCE_LOSS
             , NOM.COM_END_VALID
             , NOM.COM_TEXT
             , NOM.COM_POS
             , NOM.COM_SUBSTITUT
             , NOM.COM_RES_NUM
             , NOM.C_REMPLACEMENT_NOM
             , NOM.COM_REMPLACEMENT
             , NOM.COM_INTERVAL
             , NOM.COM_INCREASE_COST
             , NOM.PPS_NOM_BOND_ID
             , NOM.STM_LOCATION_ID
             , NOM.STM_STOCK_ID
             , nvl(PDT.PDT_BLOCK_EQUI, 0) PDT_BLOCK_EQUI
             , case
                 when C_KIND_COM not in('4', '5')
                 and SER.GCO_GOOD_ID is null
                 and PGO.GCO_GOOD_ID is null then PDT.PDT_STOCK_MANAGEMENT
                 else 0
               end PDT_STOCK_MANAGEMENT
             , GOO.GOO_NUMBER_OF_DECIMAL
             , LSL.SCS_STEP_NUMBER   -- dans FAL_TASK_LINK_PROP, TAL_SEQ_ORIGIN = SCS_STEP_NUMBER
             , LSL.PAC_SUPPLIER_PARTNER_ID
             , NOM.COM_MARK_TOPO
             , NOM.COM_WEIGHING
             , NOM.COM_WEIGHING_MANDATORY
          from PPS_NOM_BOND NOM
             , GCO_PRODUCT PDT
             , GCO_GOOD GOO
             , GCO_SERVICE SER
             , GCO_PSEUDO_GOOD PGO
             , FAL_LIST_STEP_LINK LSL
         where NOM.PPS_NOMENCLATURE_ID = PrmPPS_NOMENCLATURE_ID
           and NOM.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+)
           and NOM.GCO_GOOD_ID = GOO.GCO_GOOD_ID(+)
           and NOM.GCO_GOOD_ID = SER.GCO_GOOD_ID(+)
           and NOM.GCO_GOOD_ID = PGO.GCO_GOOD_ID(+)
           and NOM.FAL_SCHEDULE_STEP_ID = LSL.FAL_SCHEDULE_STEP_ID(+)
           and NOM.C_TYPE_COM = '1'
           -- Si pas de gestion des blocs d'équivalence sur Stock : Actif et Composant + Dérivé + Pseudo
           and (    (    cFalBloc = 0
                     and (NOM.C_KIND_COM in('1', '2', '3') ) )
                -- Si gestion des blocs d'équivalence sur Stock : Actif + Texte et Composant + Dérivé + Pseudo
                or (    cFalBloc = 1
                    and (NOM.C_KIND_COM in('1', '2', '3', '4', '5') ) ) )
           and (   iGoodId is null
                or NOM.GCO_GOOD_ID = iGoodId)
      order by NOM.COM_SEQ;

    InVarNomenclatureId  number;
    Coeff                number;
    STD                  number;   -- Somme des stocks (QtéDisponible + QtéEntréeProvisoire)
    SBE                  number;   -- Somme des besoins libres
    SAP                  number;   -- Somme des appros libres
    QBE                  number;   -- Quantité Besoin
    A                    number;
    aLOM_ADJUSTED_QTY    number;
    xxx                  number;
    aNOM_REMPL_PART      PPS_NOMENCLATURE.NOM_REMPL_PART%type;
    nGCO_GCO_GOOD_ID     number;   -- Produit equivalent
    nReplacedPDT         number;   -- Produit générique d'orginie
    aPDT_BLOC_EQUI       number;
    lnSeqLinkOnCptOrigin FAL_LOT_MAT_LINK_PROP.LOM_TASK_SEQ%type;
    liLevel              integer;
    ldBeginDateOpe       FAL_TASK_LINK_PROP.TAL_BEGIN_PLAN_DATE%type   := aLotPropBeginDate;
    SaveCOM_UTIL_COEF    number;
    nCompSumQty          number;
    lnReplaceBillOfMatId number;
    lbReplaceOnDate      boolean;

    type TCOMP_TAB is table of T_PPS_NOM_BOND;

    COMP_TAB             TCOMP_TAB;

    type TCompSumQty is record(
      CompSumQty number
    );

    type TCompSumQtys is table of TCompSumQty
      index by varchar2(12);

    vCompSumQtys         TCompSumQtys;
  begin
    lnSeqLinkOnCptOrigin  := iSeqLinkOnCptOrigin;
    liLevel               := iLevel + 1;

    if aNomenclatureID is not null then
      -- Récupération en masse des composants de la nomenclature.
      open CurComponent(aNomenclatureID);

      fetch CurComponent
      bulk collect into COMP_TAB;

      close CurComponent;

      if COMP_TAB.first is not null then
        for i in COMP_TAB.first .. COMP_TAB.last loop
          -- Les op portées sur un composant pseudo doivent être reportées sur les niveaux inférieures.
          if liLevel = 1 then
            if COMP_TAB(i).FAL_SCHEDULE_STEP_ID is not null then
              lnSeqLinkOnCptOrigin  := COMP_TAB(i).SCS_STEP_NUMBER;
            else
              lnSeqLinkOnCptOrigin  := null;
            end if;
          end if;

          -- Si config FAL_BLOC = 1 et Appel depuis les demandes d'appro et produit "générique" avec bloc d'équivalence,
          -- alors -> Remplacement du produit générique
          nReplacedPDT  := null;

          if     cFalBloc = 1
             and aFAL_SUPPLY_REQUEST_ID is not null then
            -- S'agit-il d'un produit avec bloc d'équivalence?
            if COMP_TAB(i).PDT_BLOCK_EQUI = 1 then
              -- recherche produit equivalent
              nGCO_GCO_GOOD_ID  := GCO_FUNCTIONS.GetEquivalentPropComponent(COMP_TAB(i).GCO_GOOD_ID);

              -- Si non null --> Remplacement
              if nGCO_GCO_GOOD_ID <> 0 then
                -- remplacement
                nReplacedPDT             := COMP_TAB(i).GCO_GOOD_ID;
                COMP_TAB(i).GCO_GOOD_ID  := nGCO_GCO_GOOD_ID;

                -- Flag de la proposition, les composants seront à copier lors de la reprise et non pas à recréer
                update FAL_LOT_PROP
                   set LOT_CPT_CHANGE = 1
                 where FAL_LOT_PROP_ID = aCreatedPropID;
              end if;
            end if;
          end if;

          if COMP_TAB(i).C_KIND_COM = 1 then   -- Si Composant
            -- Y a t-il remplacement
            -- Il faut regarder s'il existe une opération associé au composant et dans ce
            -- cas la comparaison se fait sur la date de l'op.
            if COMP_TAB(i).FAL_SCHEDULE_STEP_ID is not null then
              -- Recherche de la date de l'op
              ldBeginDateOpe  := GetOperationBeginPlanDate(aCreatedPropID, lnSeqLinkOnCptOrigin, aLotPropBeginDate);
            end if;

            lnReplaceBillOfMatId  := PPS_I_LIB_FUNCTIONS.GetDefaultNomenclature(COMP_TAB(i).GCO_GOOD_ID, '6');
            lbReplaceOnDate       :=
                  (COMP_TAB(i).COM_END_VALID <= ldBeginDateOpe)
              and (COMP_TAB(i).COM_REMPLACEMENT = 1)
              and (COMP_TAB(i).C_REMPLACEMENT_NOM = 1)
              and (lnReplaceBillOfMatId is not null);

            if     lbReplaceOnDate
               and (   cReplaceOnDate
                    or iForceReplace) then
              /* On effectue le remplacement sur date maintenant */
              Coeff              := COMP_TAB(i).COM_UTIL_COEFF;
              SaveCOM_UTIL_COEF  := COMP_TAB(i).COM_UTIL_COEFF;
              GphGenePropComp(aPrmCBStandardLotQty
                            , aPrmCBNomenclatureID
                            , aPrmCBcSchedulePlanCode
                            , aPrmCBGammeID
                            , lnReplaceBillOfMatId
                            , aCreatedPropID
                            , aDocRecordId
                            , aSTM_STOCK_ID
                            , aSTM_LOCATION_ID
                            , ALotTotalQty
                            , aLotPropBeginDate
                            , aLotPropEndDAte
                            , aPrmaCalculByStock
                            , context
                            , X * SaveCOM_UTIL_COEF / fal_tools.nvla(COMP_TAB(i).COM_REF_QTY, 1)
                            , aPrmCBSelectedStocks
                            , aFAL_SUPPLY_REQUEST_ID
                            , lnSeqLinkOnCptOrigin
                            , liLevel
                            , aCMA_FIX_DELAY
                            , aProductToReplace
                            , aReplacingProduct
                            , aReplaceQty
                             );
            elsif     (COMP_TAB(i).COM_REMPLACEMENT = 1)   -- Condition de remplacement
                  and (COMP_TAB(i).C_REMPLACEMENT_NOM = 2)   -- Sur stock
                  -- Et qu'il existe une nomenclature de remplacement
                  and lnReplaceBillOfMatId is not null then
              /* Remplacement sur stock */
              select NOM_REMPL_PART
                into aNOM_REMPL_PART
                from PPS_NOMENCLATURE
               where PPS_NOMENCLATURE_ID = lnReplaceBillOfMatId;

              nCompSumQty        := 0;

              if (vCompSumQtys.exists(COMP_TAB(i).GCO_GOOD_ID) ) then
                nCompSumQty  := vCompSumQtys(COMP_TAB(i).GCO_GOOD_ID).CompSumQty;
              end if;

              STD                := FAL_INTERRO_MAITRISE.GetSumDispoOnSelectStock(COMP_TAB(i).GCO_GOOD_ID, aPrmCBSelectedStocks, aLotPropBeginDate)
                                    - nCompSumQty;
              SBE                := GetSumNeedFree(COMP_TAB(i).GCO_GOOD_ID, aPrmCBSelectedStocks, aLotPropBeginDate);
              SAP                := GetSumSupplyFree(COMP_TAB(i).GCO_GOOD_ID, aPrmCBSelectedStocks, aLotPropBeginDate);
              -- C'est la formule de LOM_NEED_QTY dans  le processus de "Génération Proposition Composant"
              A                  :=
                FAL_TOOLS.ArrondiSuperieur(aLotTotalQty * COMP_TAB(i).COM_UTIL_COEFF / COMP_TAB(i).COM_REF_QTY
                                         , COMP_TAB(i).GCO_GOOD_ID
                                         , COMP_TAB(i).GOO_NUMBER_OF_DECIMAL
                                          );
              A                  := A * X;
              -- Calcul de la quantité de déchets
              aLOM_ADJUSTED_QTY  :=
                FAL_TOOLS.CalcTotalTrashQuantity(aAskedQty            => A
                                               , aTrashPercent        => COMP_TAB(i).COM_PERCENT_WASTE
                                               , aTrashFixedQty       => COMP_TAB(i).COM_FIXED_QUANTITY_WASTE
                                               , aTrashReferenceQty   => COMP_TAB(i).COM_QTY_REFERENCE_LOSS
                                                );
              -- Arrondi supérieur selon le produit
              aLOM_ADJUSTED_QTY  := FAL_TOOLS.ArrondiSuperieur(aLOM_ADJUSTED_QTY, COMP_TAB(i).GCO_GOOD_ID, COMP_TAB(i).GOO_NUMBER_OF_DECIMAL);
              QBE                := 0;

              if COMP_TAB(i).PDT_STOCK_MANAGEMENT = 1 then
                QBE  := nvl(A, 0) + nvl(aLOM_ADJUSTED_QTY, 0);
              end if;

              QBE                := nvl(QBE, 0);
              STD                := nvl(STD, 0);
              SBE                := nvl(SBE, 0);
              SAP                := nvl(SAP, 0);

              /* Si le stock disponible couvre le besoin ou qu'on n'effectue pas automatiquement le remplacement sur stock
              (config FAL_CPT_REPLACE_ON_STOCK, iForceReplace permet de forcer le remplacement quelle que soit la configuration)  */
              if    (    not cReplaceOnStock
                     and not iForceReplace)
                 or (STD - SBE + SAP >= QBE) then
                vCompSumQtys(COMP_TAB(i).GCO_GOOD_ID).CompSumQty  := nCompSumQty + QBE;
                ProcessusGenePropComp(aPrmCBStandardLotQty
                                    , aPrmCBNomenclatureID
                                    , aPrmCBcSchedulePlanCode
                                    , aPrmCBGammeID
                                    , aCreatedPropID
                                    , aDocRecordId
                                    , COMP_TAB(i)
                                    , aSTM_STOCK_ID
                                    , aSTM_LOCATION_ID
                                    , aLotPropBeginDate
                                    , aLotPropEndDate
                                    , aPrmaCalculByStock
                                    , context
                                    , Calcul_A(aLotTotalQty, COMP_TAB(i), context) * X
                                    , X
                                    , nReplacedPDT
                                    , lnSeqLinkOnCptOrigin
                                    , aCMA_FIX_DELAY
                                    , aLotTotalQty
                                    , false
                                    , false
                                    , 0   -- aReplaceQty
                                    , true   -- iStockReplace
                                     );
              else
                -- IL faut activer le flag de la POF indiquant qu'il y a eu un remplacement de composant.
                update FAL_LOT_PROP
                   set LOT_CPT_CHANGE = 1
                 where FAL_LOT_PROP_ID = aCreatedPropID;

                -- Le remplacement est partiel, est-il autorisé par la nomenclature?
                if aNOM_REMPL_PART = 1 then
                  XXX                                               :=(STD - SBE + SAP);
                  vCompSumQtys(COMP_TAB(i).GCO_GOOD_ID).CompSumQty  := nCompSumQty + XXX;

                  if XXX > 0 then
                    SaveCOM_UTIL_COEF  := COMP_TAB(i).COM_UTIL_COEFF;
                    ProcessusGenePropComp(aPrmCBStandardLotQty
                                        , aPrmCBNomenclatureID
                                        , aPrmCBcSchedulePlanCode
                                        , aPrmCBGammeID
                                        , aCreatedPropID
                                        , aDocRecordId
                                        , COMP_TAB(i)
                                        , aSTM_STOCK_ID
                                        , aSTM_LOCATION_ID
                                        , aLotPropBeginDate
                                        , aLotPropEndDate
                                        , aPrmaCalculByStock
                                        , context
                                        , Calcul_A(aLotTotalQty, COMP_TAB(i), context) * X
                                        , X
                                        , nReplacedPDT
                                        , lnSeqLinkOnCptOrigin
                                        , aCMA_FIX_DELAY
                                        , aLotTotalQty
                                        , true
                                        , false
                                        , STD - SBE + SAP   -- aReplaceQty
                                        , true   -- iStockReplace
                                         );
                  else
                    SaveCOM_UTIL_COEF  := COMP_TAB(i).COM_UTIL_COEFF;
                  end if;

                  -- on ne tient pas compte du rebut du remplacé partiel
                  if (STD - SBE + SAP) > 0 then
                    XXX  :=(STD - SBE + SAP);
                  else
                    XXX  := 0;
                  end if;

                  GphGenePropComp(aPrmCBStandardLotQty
                                , aPrmCBNomenclatureID
                                , aPrmCBcSchedulePlanCode
                                , aPrmCBGammeID
                                , lnReplaceBillOfMatId
                                , aCreatedPropID
                                , aDocRecordId
                                , aSTM_STOCK_ID
                                , aSTM_LOCATION_ID
                                , aLotTotalQty
                                , aLotPropBeginDate
                                , aLotPropEndDAte
                                , aPrmaCalculByStock
                                , context
                                , X * SaveCOM_UTIL_COEF / fal_tools.nvla(COMP_TAB(i).COM_REF_QTY, 1)
                                , aPrmCBSelectedStocks
                                , aFAL_SUPPLY_REQUEST_ID
                                , lnSeqLinkOnCptOrigin
                                , liLevel
                                , aCMA_FIX_DELAY
                                , false
                                , true
                                , XXX   -- aReplaceQty
                                 );
                end if;   -- Fin de if aNOM_REMPL_PART = 1

                if aNOM_REMPL_PART <> 1 then
                  if context = context_PDP then
                    Coeff  := COMP_TAB(i).COM_PDIR_COEFF;
                  end if;

                  if context = context_CB then
                    Coeff  := COMP_TAB(i).COM_UTIL_COEFF;
                  end if;

                  GphGenePropComp(aPrmCBStandardLotQty
                                , aPrmCBNomenclatureID
                                , aPrmCBcSchedulePlanCode
                                , aPrmCBGammeID
                                , lnReplaceBillOfMatId
                                , aCreatedPropID
                                , aDocRecordId
                                , aSTM_STOCK_ID
                                , aSTM_LOCATION_ID
                                , QBE / X
                                , aLotPropBeginDate
                                , aLotPropEndDAte
                                , aPrmaCalculByStock
                                , context
                                , X
                                , aPrmCBSelectedStocks
                                , aFAL_SUPPLY_REQUEST_ID
                                , lnSeqLinkOnCptOrigin
                                , liLevel
                                , aCMA_FIX_DELAY
                                , aProductToReplace
                                , aReplacingProduct
                                , aReplaceQty
                                 );
                end if;   -- Fin de if aNOM_REMPL_PART <> 1
              end if;   -- Fin de if nvl(STD,0) - nvl(SBE,0) >= nvl(QBE,0)
            else
              -- Pas de remplacement
              ProcessusGenePropComp(aPrmCBStandardLotQty
                                  , aPrmCBNomenclatureID
                                  , aPrmCBcSchedulePlanCode
                                  , aPrmCBGammeID
                                  , aCreatedPropID
                                  , aDocRecordId
                                  , COMP_TAB(i)
                                  , aSTM_STOCK_ID
                                  , aSTM_LOCATION_ID
                                  , aLotPropBeginDate
                                  , aLotPropEndDate
                                  , aPrmaCalculByStock
                                  , context
                                  , Calcul_A(aLotTotalQty * X, COMP_TAB(i), context)
                                  , X
                                  , nReplacedPDT
                                  , lnSeqLinkOnCptOrigin
                                  , aCMA_FIX_DELAY
                                  , aLotTotalQty
                                  , aProductToReplace
                                  , aReplacingProduct
                                  , aReplaceQty
                                  , false   -- iStockReplace
                                  , lbReplaceOnDate
                                   );
            end if;
          end if;

          if COMP_TAB(i).C_KIND_COM = '2' then   -- Dérivé
            ProcessusGenePropComp(aPrmCBStandardLotQty
                                , aPrmCBNomenclatureID
                                , aPrmCBcSchedulePlanCode
                                , aPrmCBGammeID
                                , aCreatedPropID
                                , aDocRecordId
                                , COMP_TAB(i)
                                , aSTM_STOCK_ID
                                , aSTM_LOCATION_ID
                                , aLotPropBeginDate
                                , aLotPropEndDate
                                , aPrmaCalculByStock
                                , context
                                , Calcul_A(aLotTotalQty, COMP_TAB(i), context) * X
                                , X
                                , nReplacedPDT
                                , lnSeqLinkOnCptOrigin
                                , aCMA_FIX_DELAY
                                , aLotTotalQty
                                , aProductToReplace
                                , aReplacingProduct
                                , aReplaceQty
                                 );
          end if;   -- Fin de If C_KIND_COM = '2'

          if COMP_TAB(i).C_KIND_COM = '3' then   -- Pseudo
            if nvl(COMP_TAB(i).PPS_PPS_NOMENCLATURE_ID, 0) = 0 then
              InVarNomenclatureId  := GetDefaultProdNomenclatureID(COMP_TAB(i).GCO_GOOD_ID);
            else
              InVarNomenclatureId  := COMP_TAB(i).PPS_PPS_NOMENCLATURE_ID;
            end if;

            if context = context_PDP then
              Coeff  := COMP_TAB(i).COM_PDIR_COEFF;
            end if;

            if context = context_CB then
              Coeff  := COMP_TAB(i).COM_UTIL_COEFF;
            end if;

            GphGenePropComp(aPrmCBStandardLotQty
                          , aPrmCBNomenclatureID
                          , aPrmCBcSchedulePlanCode
                          , aPrmCBGammeID
                          , InVarNomenclatureId
                          , aCreatedPropID
                          , aDocRecordId
                          , aSTM_STOCK_ID
                          , aSTM_LOCATION_ID
                          , ALotTotalQty
                          , aLotPropBeginDate
                          , aLotPropEndDAte
                          , aPrmaCalculByStock
                          , context
                          , X * Coeff / fal_tools.nvla(COMP_TAB(i).COM_REF_QTY, 1)
                          , aPrmCBSelectedStocks
                          , aFAL_SUPPLY_REQUEST_ID
                          , lnSeqLinkOnCptOrigin
                          , liLevel
                          , aCMA_FIX_DELAY
                          , aProductToReplace
                          , aReplacingProduct
                          , aReplaceQty
                           );
          end if;

          -- Texte, ou Fournit par le sous-traitant
          -- Et si reprise des liens textes
          if     COMP_TAB(i).C_KIND_COM in('4', '5')
             and upper(PCS.PC_CONFIG.GetConfig('PPS_TYPE_COM') ) = 'TRUE' then
            ProcessusGenePropComp(aPrmCBStandardLotQty
                                , aPrmCBNomenclatureID
                                , aPrmCBcSchedulePlanCode
                                , aPrmCBGammeID
                                , aCreatedPropID
                                , aDocRecordId
                                , COMP_TAB(i)
                                , null
                                , null
                                , aLotPropBeginDate
                                , aLotPropEndDate
                                , aPrmaCalculByStock
                                , context
                                , Calcul_A(aLotTotalQty, COMP_TAB(i), context) * X
                                , X
                                , nReplacedPDT
                                , lnSeqLinkOnCptOrigin
                                , aCMA_FIX_DELAY
                                , aLotTotalQty
                                , aProductToReplace
                                , aReplacingProduct
                                , aReplaceQty
                                 );
          end if;
        end loop;
      end if;
    end if;
  end GphGenePropComp;

  /**
  * Procedure CreateFalLotMatLinkProp
  * Description : Génération des composants de proposition de fabrication
  *
  * @created ECA
  * @lastUpdate
  * @public
    iCreatedPropID         proposition
  , iCBStandardLotQty      Qté lot standard
  , iCBNomenclatureID      Nomenclature
  , iCBcSchedulePlanCode   Code planification
  , iCBSchedulePlanIDOfNom Gamme liée à la nomenclature
  , iCBNomenclatureID2     Nomenclature 2
  , iCalculByStock         Calcul par stock
  , iContext               Contexte (CB, PDP)
  , iCBSelectedStocks      Liste des stocks sélectionnés
  , iCMA_FIX_DELAY         Délai fixe
  */
  procedure CreateFalLotMatLinkProp(
    iCreatedPropID         in number
  , iCBStandardLotQty      in number
  , iCBNomenclatureID      in number
  , iCBcSchedulePlanCode   in number
  , iCBSchedulePlanIDOfNom in number
  , iCBNomenclatureID2     in number
  , iCalculByStock         in integer
  , iContext               in integer
  , iCBSelectedStocks      in varchar
  , iCMA_FIX_DELAY         in integer
  )
  is
    lnDOC_RECORD_ID         number;
    lnSTM_STOCK_ID          number;
    lnSTM_LOCATION_ID       number;
    lnLOT_TOTAL_QTY         number;
    ldLOT_PLAN_BEGIN_DTE    date;
    ldLOT_PLAN_END_DTE      date;
    lnFAL_SUPPLY_REQUEST_ID number;
    liLOM_TASK_SEQaReporter integer;
    lnLevel                 number;
  begin
    select LOT.DOC_RECORD_ID
         , LOT.STM_STOCK_ID
         , LOT.STM_LOCATION_ID
         , LOT.LOT_TOTAL_QTY
         , LOT.LOT_PLAN_BEGIN_DTE
         , LOT.LOT_PLAN_END_DTE
         , LOT.FAL_SUPPLY_REQUEST_ID
      into lnDOC_RECORD_ID
         , lnSTM_STOCK_ID
         , lnSTM_LOCATION_ID
         , lnLOT_TOTAL_QTY
         , ldLOT_PLAN_BEGIN_DTE
         , ldLOT_PLAN_END_DTE
         , lnFAL_SUPPLY_REQUEST_ID
      from FAL_LOT_PROP LOT
     where LOT.FAL_LOT_PROP_ID = iCreatedPropID;

    liLOM_TASK_SEQaReporter  := null;
    lnLevel                  := 0;
    GphGenePropComp(iCBStandardLotQty
                  , iCBNomenclatureID
                  , iCBcSchedulePlanCode
                  , iCBSchedulePlanIDOfNom
                  , iCBNomenclatureID2
                  , iCreatedPropID
                  , lnDOC_RECORD_ID
                  , lnSTM_STOCK_ID
                  , lnSTM_LOCATION_ID
                  , lnLOT_TOTAL_QTY
                  , ldLOT_PLAN_BEGIN_DTE
                  , ldLOT_PLAN_END_DTE
                  , iCalculByStock
                  , iContext
                  , 1
                  , iCBSelectedStocks
                  , lnFAL_SUPPLY_REQUEST_ID
                  , liLOM_TASK_SEQaReporter
                  , lnLevel
                  , iCMA_FIX_DELAY
                   );
  end;
end FAL_PRC_FAL_LOT_MAT_LINK_PROP;   -- Fin du Package
