--------------------------------------------------------
--  DDL for Package Body FAL_BLOC_EQUIVALENCE_CONTROL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_BLOC_EQUIVALENCE_CONTROL" 
is
  /**
  *  Curseurs : CUR_FAL_NEED_COMP_POF
  *
  *  Description : Pour chaque Besoin de type composant POF, trié par date besoin croissante
  *              dont le produit est géré avec bloc d'équivalence
  *              attribué à une POA.
  */
  cursor CUR_FAL_NEED_COMP_POF(
    aRestrictOnFinalDate       in integer
  , aRestrictDate              in date
  , aRestrictOnDocRecordID     in number
  , iUseMasterPlanRequirements    integer
  , acfgFAL_TITLE_PLAN_DIR     in varchar2
  )
  is
    select   FAN.FAL_NETWORK_NEED_ID   -- Besoin
           , FAN.GCO_GOOD_ID GENERIC_NEED_PDT   -- Produit générique besoin
           , FAN.FAL_LOT_MAT_LINK_PROP_ID   -- Composant POF
           , LOM.GCO_GOOD_ID   -- Produit Composant POF
           , LOM.LOM_NEED_QTY   -- Quantité besoin
           , LOM.FAL_LOT_PROP_ID   -- POF
           , FNS.FAL_DOC_PROP_ID   -- POA
           , FNL.FLN_QTY   -- Q = Besoin à compenser = Qté attribuée
           , FAN.FAN_BEG_PLAN   -- Date début besoin
           , FAN.FAN_STK_QTY   -- Qté attribuée sur stock
           , FAN.FAN_FREE_QTY
           , FAN.FAN_NETW_QTY
           , LOTPROP.LOT_NUMBER
           , 0 FPL_LEVEL
        from FAL_NETWORK_NEED FAN
           , GCO_PRODUCT PDT
           , FAL_LOT_MAT_LINK_PROP LOM
           , FAL_NETWORK_LINK FNL
           , FAL_NETWORK_SUPPLY FNS
           , FAL_LOT_PROP LOTPROP
       where FAN.FAL_LOT_MAT_LINK_PROP_ID is not null
         and PDT.PDT_BLOCK_EQUI = 1
         and PDT.GCO_GOOD_ID = FAN.GCO_GOOD_ID
         and FAN.FAL_LOT_MAT_LINK_PROP_ID = LOM.FAL_LOT_MAT_LINK_PROP_ID
         and FAN.FAL_NETWORK_NEED_ID = FNL.FAL_NETWORK_NEED_ID
         and FNL.FAL_NETWORK_SUPPLY_ID = FNS.FAL_NETWORK_SUPPLY_ID
         and FNS.FAL_DOC_PROP_ID is not null
         and LOM.FAL_LOT_PROP_ID = LOTPROP.FAL_LOT_PROP_ID
         and LOTPROP.FAL_LOT_PROP_ID > 0
         -- Restriction sur date
         and (   aRestrictOnFinalDate = 0
              or FAN.FAN_BEG_PLAN <(aRestrictDate + 1) )
         -- Restriction sur le dossier
         and (   aRestrictOnDocRecordID = 0
              or FAN.DOC_RECORD_ID = aRestrictOnDocRecordID)
         -- Restriction sur besoins Plan directeur
         and (   iUseMasterPlanRequirements = 1
              or FAN.C_GAUGE_TITLE <> acfgFAL_TITLE_PLAN_DIR)
    order by trunc(FAN.FAN_BEG_PLAN) asc
           , FAN.FAL_NETWORK_NEED_ID asc;

  /**
  *  Curseurs : CUR_GCO_EQUIV_COMPONENT
  *
  *  Description : Pour chaque produits équivalents au composant dont les dates de validité sont OK et de statut
  *                actif  trié par stock le plus vieux (si FIFO):
  *
  *  Utilisation : Parcours pour compensation par le stock
  */
  cursor CUR_GCO_EQUIV_COMPONENT(aGCO_GOOD_ID GCO_GOOD.GCO_GOOD_ID%type, aFAN_BEG_PLAN FAL_NETWORK_NEED.FAN_BEG_PLAN%type, aPrmStockList in varchar2)
  is
    select   GEG.GCO_GCO_GOOD_ID   -- Produit equivalent
           , FAL_BLOC_EQUIVALENCE_CONTROL.GetFirstStockPositionFIFO(GEG.GCO_GCO_GOOD_ID, aPrmStockList)   -- Date de tri pour ordre de traitement des produits
        from GCO_GOOD GCO
           , GCO_EQUIVALENCE_GOOD GEG
       where GCO.GCO_GOOD_ID = aGCO_GOOD_ID
         and GCO.GCO_GOOD_ID = GEG.GCO_GOOD_ID
         and GEG.C_GEG_STATUS = '1'   -- Status actif
         and (    (GEG.GEG_BEGIN_DATE is null)
              or (    GEG.GEG_BEGIN_DATE is not null
                  and GEG.GEG_BEGIN_DATE <= aFAN_BEG_PLAN) )
         and (    (GEG.GEG_END_DATE is null)
              or (    GEG.GEG_END_DATE is not null
                  and GEG.GEG_END_DATE > aFAN_BEG_PLAN) )
    order by FAL_BLOC_EQUIVALENCE_CONTROL.GetFirstStockPositionFIFO(GEG.GCO_GCO_GOOD_ID, aPrmStockList) asc;

  /**
  *  Curseurs : CUR_GCO_EQUIV_COMPONENT
  *
  *  Description : Pour chaque produits équivalents au composant dont les dates de validité sont OK et de statut
  *                actif trié par 1) Produit non commun à un bloc
  *                               2) Produit commun à plusieurs blocs
  *  Utilisation : Parcours pour compensation par les approvisionnements
  */
  cursor CUR_GCO_EQUIV_COMPONENT_APPRO(aGCO_GOOD_ID GCO_GOOD.GCO_GOOD_ID%type, aFAN_BEG_PLAN FAL_NETWORK_NEED.FAN_BEG_PLAN%type)
  is
    select   GEG.GCO_GCO_GOOD_ID
           , 1 as FIRSTSORTORDER
        from GCO_GOOD GCO
           , GCO_EQUIVALENCE_GOOD GEG
       where GCO.GCO_GOOD_ID = aGCO_GOOD_ID
         and GCO.GCO_GOOD_ID = GEG.GCO_GOOD_ID
         and GEG.C_GEG_STATUS = '1'   -- Status actif
         and (    (GEG.GEG_BEGIN_DATE is null)
              or (    GEG.GEG_BEGIN_DATE is not null
                  and GEG.GEG_BEGIN_DATE <= aFAN_BEG_PLAN) )
         and (    (GEG.GEG_END_DATE is null)
              or (    GEG.GEG_END_DATE is not null
                  and GEG.GEG_END_DATE > aFAN_BEG_PLAN) )
         and not exists(select GEG2.GCO_EQUIVALENCE_GOOD_ID
                          from GCO_EQUIVALENCE_GOOD GEG2
                         where GEG2.GCO_GCO_GOOD_ID = GEG.GCO_GCO_GOOD_ID
                           and GEG2.GCO_GOOD_ID <> aGCO_GOOD_ID)
    union
    select   GEG.GCO_GCO_GOOD_ID
           , 0 as FIRSTSORTORDER
        from GCO_GOOD GCO
           , GCO_EQUIVALENCE_GOOD GEG
       where GCO.GCO_GOOD_ID = aGCO_GOOD_ID
         and GCO.GCO_GOOD_ID = GEG.GCO_GOOD_ID
         and GEG.C_GEG_STATUS = '1'   -- Status actif
         and (    (GEG.GEG_BEGIN_DATE is null)
              or (    GEG.GEG_BEGIN_DATE is not null
                  and GEG.GEG_BEGIN_DATE <= aFAN_BEG_PLAN) )
         and (    (GEG.GEG_END_DATE is null)
              or (    GEG.GEG_END_DATE is not null
                  and GEG.GEG_END_DATE > aFAN_BEG_PLAN) )
         and exists(select GEG2.GCO_EQUIVALENCE_GOOD_ID
                      from GCO_EQUIVALENCE_GOOD GEG2
                     where GEG2.GCO_GCO_GOOD_ID = GEG.GCO_GCO_GOOD_ID
                       and GEG2.GCO_GOOD_ID <> aGCO_GOOD_ID)
    order by FIRSTSORTORDER desc;

  type TTAB_NEED_COMP_POF is table of CUR_FAL_NEED_COMP_POF%rowtype;

  /**
  * Description :
  *    Renvoie la date aDate décallée du décalage achat du produit aGCO_GOOD_ID
  */
  function GetShiftedDate(aDate date, aGCO_GOOD_ID gco_good.GCO_GOOD_ID%type)
    return date
  is
    aShift integer;
  begin
    -- Recherche du décalage achat du produit
    select nvl(CPU_SHIFT, 0)
      into aShift
      from GCO_COMPL_DATA_PURCHASE
     where GCO_GOOD_ID = aGCO_GOOD_ID
       and CPU_DEFAULT_SUPPLIER = 1;

    -- Si le décalage est > au nbre de jours de décalage maximum calculés sur les calendriers
    if aShift > FAL_LIB_CONSTANT.gCfgCBShiftLimit then
      return aDate + aShift;
    else
      return trunc(FAL_SCHEDULE_FUNCTIONS.GetDecalage(null, null, null, null, null, FAL_SCHEDULE_FUNCTIONS.GetDefaultCalendar, trunc(aDate), aShift, 1));
    end if;
  exception
    when others then
      return aDate;
  end GetShiftedDate;

  /**
  * Procedure CompareDateAppro
  * Description : Function qui renvoie vrai si aDate1 <= aDate2
  *
  * @author ECA
  * @lastUpdate
  * @public
  */
  function CompareDate(aDate1 date, aDate2 date)
    return integer
  is
  begin
    if trunc(aDate1) <= trunc(aDate2) then
      return 1;
    else
      return 0;
    end if;
  exception
    when others then
      return 0;
  end CompareDate;

  /**
  * Procedure GetPOANetworkQty
  * @author ECA
  * @lastUpdate
  * @public
  * @param aFAL_DOC_PROP            : POA
  *        aFAN_NETW_QTY            : Produit équivalent
  */
  function GetPOANetworkQty(aFAL_DOC_PROP_ID in FAL_DOC_PROP.FAL_DOC_PROP_ID%type, aFAN_NETW_QTY in out FAL_NETWORK_SUPPLY.FAN_NETW_QTY%type)
    return boolean
  is
  begin
    select nvl(FNS.FAN_NETW_QTY, 0)
      into aFAN_NETW_QTY
      from FAL_DOC_PROP FDP
         , FAL_NETWORK_SUPPLY FNS
     where FDP.FAL_DOC_PROP_ID = aFAL_DOC_PROP_ID
       and FDP.FAL_DOC_PROP_ID = FNS.FAL_DOC_PROP_ID;

    return true;
  exception
    when others then
      begin
        aFAN_NETW_QTY  := 0;
        return false;
      end;
  end GetPOANetworkQty;

  /**
  * Procedure GetNEEDLomNeedQty
  * Description : Procedure de recherche du Produit équivalent au générique et de son fournisseur
  *               en fonction des informations de multisourcing.
  * @author ECA
  * @lastUpdate
  * @public
  * @param
  */
  function GetNEEDLomNeedQty(
    aFAL_LOT_MAT_LINK_PROP_ID in     FAL_LOT_MAT_LINK_PROP.FAL_LOT_MAT_LINK_PROP_ID%type
  , aLOM_NEED_QTY             in out FAL_LOT_MAT_LINK_PROP.LOM_NEED_QTY%type
  )
    return boolean
  is
  begin
    select LOM_NEED_QTY
      into aLOM_NEED_QTY
      from FAL_LOT_MAT_LINK_PROP
     where FAL_LOT_MAT_LINK_PROP_ID = aFAL_LOT_MAT_LINK_PROP_ID;

    return true;
  exception
    when others then
      begin
        aLOM_NEED_QTY  := 0;
        return false;
      end;
  end GetNEEDLomNeedQty;

  -- ATTENTION: Il a été nécessaire de dupliquer cette fonction
  --            Car on ne tient pas compte du liende nomenclature
  procedure Init_Emplacement_Conso(
    aGCO_GOOD_ID               in     GCO_GOOD.GCO_GOOD_ID%type
  , PrmPropSTM_STM_STOCK_ID    in     STM_STOCK.STM_STOCK_ID%type
  , PrmPropSTM_STM_LOCATION_ID in     STM_LOCATION.STM_LOCATION_ID%type
  , OutSTM_STOCK_ID            in out STM_STOCK.STM_STOCK_ID%type
  , OutSTM_LOCATION_ID         in out STM_LOCATION.STM_LOCATION_ID%type
  )
  is
    -- Variable pour le stockage du résultat
    Stm_location_id           number;
    Stm_Stock_id              number;
    -- Pour retrouver les infos nécessaires du composant en tant que produit (pour retrouver des valeurs par defaut)
    DefaultPDTStm_Stock_Id    number;
    DefaultPDTStm_Location_Id number;
    DefaultPDTStockManagement number;
  begin
    -- Stock, emplacement défaut
    begin
      select PDT.STM_STOCK_ID
           , PDT.STM_LOCATION_ID
           , PDT.PDT_STOCK_MANAGEMENT
        into DefaultPDTStm_Stock_Id
           , DefaultPDTStm_Location_Id
           , DefaultPDTStockManagement
        from GCO_PRODUCT PDT
       where GCO_GOOD_ID = aGCO_GOOD_ID;
    exception
      when no_data_found then
        begin
          DefaultPDTStm_Stock_Id     := null;
          DefaultPDTStm_Location_Id  := null;
          DefaultPDTStockManagement  := 0;
        end;
    end;

    Stm_Stock_id        := null;
    Stm_location_id     := null;

    if DefaultPDTStockManagement = 1 then
      if PrmPropSTM_STM_LOCATION_ID is null then   -- Proposition -> EmplacementConso = Vide
        if PrmPropSTM_STM_STOCK_ID is null then   -- Proposition -> StockConso = Vide
          if DefaultPDTStm_Location_Id is null then   -- Produit composant POF -> Emplacement defaut = Vide
            if DefaultPDTStm_Stock_id is null then   -- Produit composant POF  -> Stock defaut = Vide
              Stm_Stock_Id     := FAL_TOOLS.GetConfig_StockID('GCO_DefltSTOCK');   -- Affectation de la valeur issue de la config
              Stm_Location_id  := FAL_TOOLS.GetMinClassifLocationOfStock(Stm_Stock_id);   -- Recherche sur le plus petit loc classification pour le stock en cours
            else   -- Composant -> Stock defaut <> Vide
              Stm_Stock_Id     := DefaultPDTStm_Stock_ID;
              Stm_Location_Id  := FAL_TOOLS.GetMinClassifLocationOfStock(Stm_Stock_Id);   -- Recherche sur le plus petit loc classification pour le stock en cours
            end if;
          else   -- Composant -> Emplacement defaut <> Vide
            Stm_Stock_Id     := DefaultPDTStm_Stock_ID;
            Stm_Location_Id  := DefaultPDTStm_Location_id;
          end if;
        else   -- LotPseudo -> StockConso <> Vide
          Stm_Stock_Id     := PrmPropSTM_STM_STOCK_ID;
          Stm_Location_id  := FAL_TOOLS.GetMinClassifLocationOfStock(Stm_Stock_id);   -- Recherche sur le plus petit loc classification pour le stock en cours
        end if;
      else   -- LotPseudo -> EmplacementConso <> Vide
        Stm_Stock_Id     := PrmPropSTM_STM_STOCK_ID;
        Stm_Location_Id  := PrmPropSTM_STM_LOCATION_ID;
      end if;
    else
      stm_Stock_id     := FAL_TOOLS.GetDefaultStock;
      stm_location_id  := null;
    end if;

    OutSTM_STOCK_ID     := Stm_Stock_ID;
    OutSTM_LOCATION_ID  := Stm_Location_ID;
  end Init_Emplacement_Conso;

  /**
  * Procedure GetEquivalentPDTAndSupplier
  * Description : Procedure de recherche du Produit équivalent au générique et de son fournisseur
  *               en fonction des informations de multisourcing.
  * @author ECA
  * @lastUpdate
  * @public
  * @param aGCO_GOOD_ID             : Produit générique
  *        aGCO_GCO_GOOD_ID         : Produit équivalent
  *        aPAC_SUPPLIER_PARTNER_ID : Fournisseur
  */
  procedure GetEquivalentPDTAndSupplier(
    aGCO_GOOD_ID             in     GCO_GOOD.GCO_GOOD_ID%type
  , aGCO_GCO_GOOD_ID         in out GCO_GOOD.GCO_GOOD_ID%type
  , aPAC_SUPPLIER_PARTNER_ID in out PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  )
  is
    blnMultiSourcingPDT         integer;
    nGCO_COMPL_DATA_PURCHASE_ID GCO_COMPL_DATA_PURCHASE.GCO_COMPL_DATA_PURCHASE_ID%type;
  begin
    -- Produit en multi Sourcing?
    begin
      select PDT.PDT_MULTI_SOURCING
        into blnMultiSourcingPDT
        from GCO_PRODUCT PDT
       where PDT.GCO_GOOD_ID = aGCO_GOOD_ID;
    exception
      when others then
        blnMultiSourcingPDT  := 0;
    end;

    if blnMultiSourcingPDT = 1 then
      -- Si produit en multi sourcing, alors choix de la DCA en fonction des informations de multi-Sourcing
      FAL_MSOURCING_FUNCTIONS.GetMultiSourcingDCA(aGCO_GOOD_ID
                                                , 0   -- => Exercice : si = 0 recherche sur l'exercice actif
                                                , aGCO_GCO_GOOD_ID
                                                , aPAC_SUPPLIER_PARTNER_ID
                                                , nGCO_COMPL_DATA_PURCHASE_ID
                                                 );

      -- Si Pour une raison ou pour une autre on a pas trouvé de produit équivalent / Fournisseur via le multisourcing
      -- on se rabat sur les valeurs de la DCA par défaut (présence des données vérifiées plus haut dans le graph)
      if    aGCO_GCO_GOOD_ID = 0
         or aGCO_GCO_GOOD_ID is null
         or aPAC_SUPPLIER_PARTNER_ID = 0
         or aPAC_SUPPLIER_PARTNER_ID is null then
        select PUR.PAC_SUPPLIER_PARTNER_ID
             , PUR.GCO_GCO_GOOD_ID
          into aPAC_SUPPLIER_PARTNER_ID
             , aGCO_GCO_GOOD_ID
          from GCO_COMPL_DATA_PURCHASE PUR
         where PUR.CPU_DEFAULT_SUPPLIER = 1
           and PUR.GCO_GOOD_ID = aGCO_GOOD_ID;
      end if;
    else
      -- Fournisseur et produit équivalent de la donnée complémentaire d'achat par défaut du produit
      -- Note : Elle existe forcément, cela à été vérifié plus haut dans le graph ReplacePOAOnGenericPDT
      select PUR.PAC_SUPPLIER_PARTNER_ID
           , PUR.GCO_GCO_GOOD_ID
        into aPAC_SUPPLIER_PARTNER_ID
           , aGCO_GCO_GOOD_ID
        from GCO_COMPL_DATA_PURCHASE PUR
       where PUR.CPU_DEFAULT_SUPPLIER = 1
         and PUR.GCO_GOOD_ID = aGCO_GOOD_ID;
    end if;
  end;

  /**
  * Function ProductWithDCA
  * Description : Renvoie True si le produit comporte au moins une donnée complémentaire d'achat par défaut
  *               avec un produit fabricant.
  * @author ECA
  * @lastUpdate
  * @public
  * @param aGCO_GOOD_ID : Produit
  */
  function ProductWithDCA(aGCO_GOOD_ID in GCO_GOOD.GCO_GOOD_ID%type)
    return boolean
  is
    cursor CUR_PRODUCT_DCA
    is
      select GCO_COMPL_DATA_PURCHASE_ID
        from GCO_COMPL_DATA_PURCHASE
       where GCO_GOOD_ID = aGCO_GOOD_ID
         and GCO_GCO_GOOD_ID is not null
         and CPU_DEFAULT_SUPPLIER = 1;

    CurProductDCA CUR_PRODUCT_DCA%rowtype;
    result        boolean;
  begin
    result  := true;

    open CUR_PRODUCT_DCA;

    fetch CUR_PRODUCT_DCA
     into CurProductDCA;

    if CUR_PRODUCT_DCA%notfound then
      result  := false;
    end if;

    close CUR_PRODUCT_DCA;

    return result;
  exception
    when others then
      begin
        close CUR_PRODUCT_DCA;

        return false;
      end;
  end ProductWithDCA;

  /**
  * Function GetFirstStockPositionFIFO
  * Description : Renvoie dans le cas d'un produit géré en caractérization FIFO
  *               la date de la plus vielle position de stock, date du jour sinon
  * @author ECA
  * @lastUpdate
  * @public
  * @param aGCO_GOOD_ID : Produit
  */
  function GetFirstStockPositionFIFO(aGCO_GOOD_ID in GCO_GOOD.GCO_GOOD_ID%type, aPrmStockList in varchar2)
    return varchar2
  is
    ResultCharact  varchar2(30);
    BuffSQL        varchar2(2000);
    Cursor_Handle  integer;
    Execute_Cursor integer;
  begin
    BuffSQL         :=
      ' SELECT SPO.SPO_CHRONOLOGICAL              ' ||
      '   FROM STM_STOCK_POSITION SPO             ' ||
      '  WHERE SPO.GCO_GOOD_ID = ' ||
      to_char(aGCO_GOOD_ID) ||
      '    AND SPO.SPO_CHRONOLOGICAL IS NOT NULL  ';

    if aPrmStockList is not null then
      BuffSQL  := BuffSQL || '    AND SPO.STM_STOCK_ID IN (' || aPrmStockList || ')';
    end if;

    BuffSQL         := BuffSQL || '  ORDER BY SPO.SPO_CHRONOLOGICAL ASC ';
    Cursor_Handle   := DBMS_SQL.open_cursor;
    DBMS_SQL.parse(Cursor_Handle, BuffSQL, DBMS_SQL.V7);
    DBMS_SQL.define_column(Cursor_Handle, 1, ResultCharact, 30);
    Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);

    if DBMS_SQL.fetch_rows(Cursor_Handle) > 0 then
      DBMS_SQL.column_value(Cursor_Handle, 1, ResultCharact);
    else
      ResultCharact  := '999999';
    end if;

    DBMS_SQL.close_cursor(Cursor_Handle);
    return ResultCharact;
  exception
    when others then
      begin
        DBMS_SQL.close_cursor(Cursor_Handle);
        return '999999';
      end;
  end GetFirstStockPositionFIFO;

  /**
  * procedure GetStockQuantityDispo
  * Description : Recherche des quantité en stock pour vérification du dispo
  *
  * @author ECA
  * @lastUpdate
  * @public
  * @param in     aPrmStockList : Liste de stocks du CB.
  *        in     aGCO_GOOD_ID  : Produit
  *        in out aSTD          : Somme des (Quantité Dispo + Quantité entrées Provisoires).
  *        in out aSBE          : Somme des besoins libres.
  *        in out aSTMIN        : Somme des stock minimums.
  */
  procedure GetStockQuantityDispo(
    aPrmStockList in     varchar2
  , aGCO_GOOD_ID  in     GCO_GOOD.GCO_GOOD_ID%type
  , aSTD          in out number
  , aSBE          in out number
  , aSTMIN        in out number
  )
  is
    BuffSQL        varchar2(2000);
    Cursor_Handle  integer;
    Execute_Cursor integer;
  begin
    -- Calcul de la STD
    begin
      aSTD            := 0;
      BuffSQL         :=
        ' SELECT NVL(SUM(SPO.SPO_AVAILABLE_QUANTITY + SPO.SPO_PROVISORY_INPUT),0) STD_QTY ' ||
        '   FROM STM_STOCK_POSITION SPO ' ||
        '  WHERE SPO.GCO_GOOD_ID = :aGCO_GOOD_ID ';

      if aPrmStockList is not null then
        BuffSQL  := BuffSQL || '    AND SPO.STM_STOCK_ID IN (' || aPrmStockList || ')';
      end if;

      Cursor_Handle   := DBMS_SQL.open_cursor;
      DBMS_SQL.parse(Cursor_Handle, BuffSQL, DBMS_SQL.V7);
      DBMS_SQL.Bind_variable(Cursor_Handle, 'aGCO_GOOD_ID', aGCO_GOOD_ID);
      DBMS_SQL.define_column(Cursor_Handle, 1, aSTD);
      Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);

      if DBMS_SQL.fetch_rows(Cursor_Handle) > 0 then
        DBMS_SQL.column_value(Cursor_Handle, 1, aSTD);
      else
        aSTD  := 0;
      end if;

      DBMS_SQL.close_cursor(Cursor_Handle);
    exception
      when others then
        begin
          DBMS_SQL.Close_cursor(Cursor_Handle);
          aSTD  := 0;
        end;
    end;

    -- Calcul de la SBE
    aSBE  := 0;

    begin
      BuffSQL         := ' SELECT NVL(SUM(FAN.FAN_FREE_QTY),0) FAN_FREE_QTY ' || '	 FROM FAL_NETWORK_NEED FAN ' || '  WHERE FAN.GCO_GOOD_ID = :aGCO_GOOD_ID ';

      if aPrmStockList is not null then
        BuffSQL  := BuffSQL || '    AND FAN.STM_STOCK_ID IN (' || aPrmStockList || ')';
      end if;

      Cursor_Handle   := DBMS_SQL.open_cursor;
      DBMS_SQL.parse(Cursor_Handle, BuffSQL, DBMS_SQL.V7);
      DBMS_SQL.Bind_variable(Cursor_Handle, 'aGCO_GOOD_ID', aGCO_GOOD_ID);
      DBMS_SQL.define_column(Cursor_Handle, 1, aSBE);
      Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);

      if DBMS_SQL.fetch_rows(Cursor_Handle) > 0 then
        DBMS_SQL.column_value(Cursor_Handle, 1, aSBE);
      else
        aSBE  := 0;
      end if;

      DBMS_SQL.close_cursor(Cursor_Handle);
    exception
      when others then
        begin
          DBMS_SQL.Close_cursor(Cursor_Handle);
          aSBE  := 0;
        end;
    end;

    -- Calcul de la STMIN
    begin
      aSTMIN          := 0;
      BuffSQL         :=
                ' SELECT NVL(SUM(CDA.CST_QUANTITY_MIN)) CST_QUANTITY_MIN ' || '   FROM GCO_COMPL_DATA_STOCK CDA ' || '  WHERE CDA.GCO_GOOD_ID = :aGCO_GOOD_ID ';

      if aPrmStockList is not null then
        BuffSQL  := BuffSQL || '    AND CDA.STM_STOCK_ID IN (' || aPrmStockList || ')';
      end if;

      Cursor_Handle   := DBMS_SQL.open_cursor;
      DBMS_SQL.parse(Cursor_Handle, BuffSQL, DBMS_SQL.V7);
      DBMS_SQL.Bind_variable(Cursor_Handle, 'aGCO_GOOD_ID', aGCO_GOOD_ID);
      DBMS_SQL.define_column(Cursor_Handle, 1, aSTMIN);
      Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);

      if DBMS_SQL.fetch_rows(Cursor_Handle) > 0 then
        DBMS_SQL.column_value(Cursor_Handle, 1, aSTMIN);
      else
        aSTMIN  := 0;
      end if;

      DBMS_SQL.close_cursor(Cursor_Handle);
    exception
      when others then
        begin
          DBMS_SQL.Close_cursor(Cursor_Handle);
          aSTMIN  := 0;
        end;
    end;
  end GetStockQuantityDispo;

  /**
  * procedure MAJNewCompPOF
  * Description : Processus de modification d'un composant POF
  *
  * @author ECA
  * @lastUpdate
  * @public
  * @param in     aQuantity                 : Quantité
  *        in     aPAC_SUPPLIER_PARTNER_ID  : Fournisseur
  *        in     aFAL_LOT_MAT_LINK_PROP_ID : Composant POF
  */
  procedure MAJNewCompPOF(
    aFAL_LOT_MAT_LINK_PROP_ID in FAL_LOT_MAT_LINK_PROP.FAL_LOT_MAT_LINK_PROP_ID%type
  , aQuantity                 in number
  , aPAC_SUPPLIER_PARTNER_ID  in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  )
  is
  begin
    update FAL_LOT_MAT_LINK_PROP LOM
       set LOM.PAC_SUPPLIER_PARTNER_ID = aPAC_SUPPLIER_PARTNER_ID
         -- Qté Total = Nvelle QtéSupInf + Qté besoin
    ,      LOM.LOM_FULL_REQ_QTY = LOM.LOM_BOM_REQ_QTY + LOM.LOM_ADJUSTED_QTY + aQuantity
         -- Qté BesoinCPT = Qté Totale
    ,      LOM.LOM_NEED_QTY = LOM.LOM_BOM_REQ_QTY + LOM.LOM_ADJUSTED_QTY + aQuantity
         -- Nvelle Qtésupinf = QtéSupInf + Quantity
    ,      LOM.LOM_ADJUSTED_QTY = LOM.LOM_ADJUSTED_QTY + aQuantity
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where LOM.FAL_LOT_MAT_LINK_PROP_ID = aFAL_LOT_MAT_LINK_PROP_ID;
  end MAJNewCompPOF;

  /**
  * procedure CreateNewCompPOF
  * Description : Processus de Création d'un nouveau composant POF
  *
  * @author ECA
  * @lastUpdate
  * @public
  * @param aFAL_LOT_PROP_ID          : POF
  *        aFAL_LOT_MAT_LINK_PROP_ID : Composant POF
  *      aGCO_GOOD_ID              : Produit générique d'origine
  *      aGCO_GCO_GOOD_ID          : Produit equivalent
  *      aQuantity                 : Quantité
  *      aPAC_SUPPLIER_PARTNER_ID  : Fournisseur
  */
  procedure CreateNewCompPOF(
    aFAL_LOT_PROP_ID             in     FAL_LOT_PROP.FAL_LOT_PROP_ID%type
  , aFAL_LOT_MAT_LINK_PROP_ID    in     FAL_LOT_MAT_LINK_PROP.FAL_LOT_MAT_LINK_PROP_ID%type
  , aGCO_GOOD_ID                 in     GCO_GOOD.GCO_GOOD_ID%type
  , aGCO_GCO_GOOD_ID             in     GCO_GOOD.GCO_GOOD_ID%type
  , aQuantity                    in     number
  , aPAC_SUPPLIER_PARTNER_ID     in     PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  , aNewFAL_LOT_MAT_LINK_PROP_ID in out FAL_LOT_MAT_LINK_PROP.FAL_LOT_MAT_LINK_PROP_ID%type
  )
  is
    -- Cursor POF
    cursor CUR_FAL_LOT_PROP
    is
      select LOT.DOC_RECORD_ID
           , LOT.FAL_PIC_ID
           , LOT.LOT_TOTAL_QTY
        from FAL_LOT_PROP LOT
       where LOT.FAL_LOT_PROP_ID = aFAL_LOT_PROP_ID;

    -- Cursor Composant POF
    cursor CUR_FAL_LOT_MAT_LINK_PROP
    is
      select LOM.LOM_TASK_SEQ
           , LOM.LOM_NEED_DATE
           , LOM.LOM_POS
           , LOM.LOM_FRE_NUM
           , LOM.LOM_TEXT
           , LOM.LOM_FREE_TEXT
           , LOM.LOM_REF_QTY
           , LOM.LOM_UTIL_COEF
           , LOM.C_DISCHARGE_COM
           , LOM.C_TYPE_COM
           , LOM.C_KIND_COM
           , PROP.STM_STM_STOCK_ID
           , PROP.STM_STM_LOCATION_ID
           , PROP.FAL_LOT_PROP_ID
        from FAL_LOT_MAT_LINK_PROP LOM
           , FAL_LOT_PROP PROP
       where LOM.FAL_LOT_MAT_LINK_PROP_ID = aFAL_LOT_MAT_LINK_PROP_ID
         and LOM.FAL_LOT_PROP_ID = PROP.FAL_LOT_PROP_ID;

    CurFalLotProp         CUR_FAL_LOT_PROP%rowtype;
    CurFalLotMatLinkProp  CUR_FAL_LOT_MAT_LINK_PROP%rowtype;
    aLOM_BOM_REQ_QTY      number;
    aLOM_ADJUSTED_QTY     number;
    aLOM_FULL_REQ_QTY     number;
    aGOO_MAJOR_REFERENCE  varchar2(30);
    aLOM_SECONDARY_REF    varchar2(30);
    aLOM_SHORT_DESCR      varchar2(50);
    aLOM_LONG_DESCR       varchar2(4000);
    aLOM_FREE_DESCR       varchar2(4000);
    aLOM_STOCK_MANAGEMENT number;
    aC_CHRONOLOGY_TYPE    varchar2(10);
    blnContinue           boolean;
    aSTM_STOCK_ID         number;
    aSTM_LOCATION_ID      number;
    NextLOM_SEQ           FAL_LOT_MAT_LINK_PROP.LOM_SEQ%type;
  begin
    blnContinue                   := true;
    aNewFAL_LOT_MAT_LINK_PROP_ID  := 0;
    -- Récupération des description du produit
    FAL_TOOLS.GetMajorSecShortFreeLong(aGCO_GCO_GOOD_ID, aGOO_MAJOR_REFERENCE, aLOM_SECONDARY_REF, aLOM_SHORT_DESCR, aLOM_FREE_DESCR, aLOM_LONG_DESCR);

    -- Gestion de stock et type de chronologie
    begin
      select PDT.PDT_STOCK_MANAGEMENT
           , CHARACT.C_CHRONOLOGY_TYPE
        into aLOM_STOCK_MANAGEMENT
           , aC_CHRONOLOGY_TYPE
        from GCO_PRODUCT PDT
           , (select CHA.C_CHRONOLOGY_TYPE
                   , CHA.GCO_GOOD_ID
                from GCO_CHARACTERIZATION CHA
               where CHA.GCO_GOOD_ID = aGCO_GCO_GOOD_ID
                 and CHA.C_CHARACT_TYPE = '5') CHARACT
       where PDT.GCO_GOOD_ID = aGCO_GCO_GOOD_ID
         and PDT.GCO_GOOD_ID = CHARACT.GCO_GOOD_ID(+);
    exception
      when others then
        begin
          aLOM_STOCK_MANAGEMENT  := 0;
          aC_CHRONOLOGY_TYPE     := '';
        end;
    end;

    -- Récup Info FAL_LOT_PROP
    open CUR_FAL_LOT_PROP;

    fetch CUR_FAL_LOT_PROP
     into CurFalLotProp;

    if CUR_FAL_LOT_PROP%notfound then
      close CUR_FAL_LOT_PROP;

      raise_application_error(-20300, 'PCS - Proposition not found! Component proposition could not be created!');
      blnContinue  := false;
    end if;

    -- Récup info FAL_LOT_MAT_LINK_PROP
    open CUR_FAL_LOT_MAT_LINK_PROP;

    fetch CUR_FAL_LOT_MAT_LINK_PROP
     into CurFalLotMatLinkProp;

    if CUR_FAL_LOT_MAT_LINK_PROP%notfound then
      close CUR_FAL_LOT_MAT_LINK_PROP;

      raise_application_error(-20300, 'PCS - Component proposition not found! Component proposition could not be created!');
      blnContinue  := false;
    end if;

    if BlnContinue then
      -- Calcul quantité besoin = QtePropTotal * Coef utilisation / Qté référence
      if    (CurFalLotMatLinkProp.LOM_REF_QTY is null)
         or (CurFalLotMatLinkProp.LOM_REF_QTY = 0) then
        aLOM_BOM_REQ_QTY  := 0;
      else
        aLOM_BOM_REQ_QTY  := (CurFalLotProp.LOT_TOTAL_QTY * CurFalLotMatLinkProp.LOM_UTIL_COEF) / CurFalLotMatLinkProp.LOM_REF_QTY;
      end if;

      -- Calcul Quantité Sup Inf = Quantité - Quantité besoin
      aLOM_ADJUSTED_QTY             := aQuantity - aLOM_BOM_REQ_QTY;
      -- Calcul Quantité totale = QtéBesoin + QtéSupInf
      aLOM_FULL_REQ_QTY             := aLOM_BOM_REQ_QTY + aLOM_ADJUSTED_QTY;
      -- Initialisation stock et emplacement de consommation
      FAL_BLOC_EQUIVALENCE_CONTROL.Init_Emplacement_Conso(aGCO_GCO_GOOD_ID   -- Produit équivalent.
                                                        , CurFalLotMatLinkProp.STM_STM_STOCK_ID   -- Stock Conso de la proposition.
                                                        , CurFalLotMatLinkProp.STM_STM_LOCATION_ID   -- Emplacement conso de la proposition.
                                                        , aSTM_STOCK_ID
                                                        , aSTM_LOCATION_ID
                                                         );

      -- Récupération de la prochaine séquence du composant
      select nvl(max(LOM_SEQ), 0) + PCS.PC_CONFIG.GetConfig('FAL_COMPONENT_NUMBERING')
        into NextLOM_SEQ
        from FAL_LOT_MAT_LINK_PROP
       where FAL_LOT_PROP_ID = CurFalLotMatLinkProp.FAL_LOT_PROP_ID;

      -- ID du nouveau composant POF
      aNewFAL_LOT_MAT_LINK_PROP_ID  := GetNewId;

      insert into FAL_LOT_MAT_LINK_PROP
                  (FAL_LOT_MAT_LINK_PROP_ID   -- Id
                 , FAL_LOT_PROP_ID   -- Id Proposition Fabrication
                 , GCO_GCO_GOOD_ID   -- Produit Générique Origine
                 , PAC_SUPPLIER_PARTNER_ID   -- Fournisseur
                 , DOC_RECORD_ID   -- Dossier
                 , FAL_PIC_ID   -- PIC
                 , GCO_GOOD_ID   -- Produit
                 , LOM_TASK_SEQ   -- Sequence Operation
                 , STM_STOCK_ID   -- Stock Consommation
                 , STM_LOCATION_ID   -- Emplacement Consommation
                 , LOM_INTERVAL   -- Decalage
                 , LOM_NEED_DATE   -- Date Besoin
                 , LOM_SEQ   -- Séquence
                 , LOM_SUBSTITUT   -- Substitution
                 , LOM_STOCK_MANAGEMENT   -- Gestion Stock
                 , LOM_SECONDARY_REF   -- Ref secondaire
                 , LOM_SHORT_DESCR   -- Description courte
                 , LOM_LONG_DESCR   -- Description longue
                 , LOM_FREE_DECR   -- Description libre
                 , LOM_POS   -- Position
                 , LOM_FRE_NUM   -- Numérique libre
                 , LOM_TEXT   -- texte
                 , LOM_FREE_TEXT   -- Texte Libre
                 , LOM_REF_QTY   -- Qté référence
                 , LOM_PERCENT_WASTE   -- % Déchet
                 , LOM_QTY_REFERENCE_LOSS   -- Qté ref déchet
                 , LOM_FIXED_QUANTITY_WASTE   -- QtéFixeDéchet
                 , LOM_UTIL_COEF   -- Coef utilisation
                 , LOM_BOM_REQ_QTY   -- QtéBesoin
                 , LOM_ADJUSTED_QTY   -- QtéSupInf
                 , LOM_FULL_REQ_QTY   -- QtéTotale
                 , LOM_NEED_QTY   -- QteBesoin
                 , LOM_ADJUSTED_QTY_RECEIPT   -- QtéSupInfReception
                 , LOM_CONSUMPTION_QTY   -- Qté Conso
                 , LOM_REJECTED_QTY   -- QtéRebut
                 , LOM_BACK_QTY   -- QtéRetour
                 , LOM_PT_REJECT_QTY   -- Qté PT Rebut
                 , LOM_CPT_TRASH_QTY   -- Qté Démonté
                 , LOM_CPT_RECOVER_QTY   -- Qté Démonté Récupéré
                 , LOM_CPT_REJECT_QTY   -- Qté Démonté rebut
                 , LOM_EXIT_RECEIPT   -- Qté CPT réceptioné
                 , LOM_MAX_RECEIPT_QTY   -- Qté max récept
                 , LOM_MAX_FACT_QTY   -- Qté max fab
                 , LOM_AVAILABLE_QTY   -- QtéDipso
                 , LOM_PRICE   -- Prix
                 , LOM_MISSING   -- Manco
                 , C_DISCHARGE_COM   -- Code décharge
                 , C_CHRONOLOGY_TYPE   -- Type de caract chrono
                 , C_TYPE_COM   -- Type de lien
                 , C_KIND_COM   -- Genre de lien
                 , PC_YEAR_WEEK_ID   -- Semaine
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (aNewFAL_LOT_MAT_LINK_PROP_ID   -- Id
                 , aFAL_LOT_PROP_ID   -- Id Proposition Fabrication
                 , aGCO_GOOD_ID   -- Produit Générique Origine
                 , aPAC_SUPPLIER_PARTNER_ID   -- Fournisseur
                 , CurFalLotProp.DOC_RECORD_ID   -- Dossier
                 , CurFalLotProp.FAL_PIC_ID   -- PIC
                 , aGCO_GCO_GOOD_ID   -- Produit
                 , CurFalLotMatLinkProp.LOM_TASK_SEQ   -- Séquence opération
                 , aSTM_STOCK_ID   -- Stock : Voir initialisation avec Denis
                 , aSTM_LOCATION_ID   -- Emplacement : Voir initialisation avec Denis
                 , 0   -- Décalage
                 , CurFalLotMatLinkProp.LOM_NEED_DATE   -- Date besoin
                 , NextLOM_SEQ   -- Séquence : Voir comment l'initialiser
                 , 0   -- Substitution
                 , aLOM_STOCK_MANAGEMENT   -- Gestion de stock
                 , aLOM_SECONDARY_REF   -- Ref secondaire
                 , aLOM_SHORT_DESCR   -- Description courte
                 , aLOM_LONG_DESCR   -- Description longue
                 , aLOM_FREE_DESCR   -- Description libre
                 , CurFalLotMatLinkProp.LOM_POS   -- Position
                 , CurFalLotMatLinkProp.LOM_FRE_NUM   -- Numérique libre
                 , CurFalLotMatLinkProp.LOM_TEXT   -- Texte
                 , CurFalLotMatLinkProp.LOM_FREE_TEXT   -- Texte libre
                 , CurFalLotMatLinkProp.LOM_REF_QTY   -- Quantité de référence
                 , 0   -- % Déchet
                 , 1   -- Qté ref déchet
                 , 0   -- Qté fixe déchet
                 , CurFalLotMatLinkProp.LOM_UTIL_COEF   -- Coef d'utilisation
                 , aLOM_BOM_REQ_QTY   -- Quantité besoin
                 , aLOM_ADJUSTED_QTY   -- Qté sup inf
                 , aLOM_FULL_REQ_QTY   -- Qté totale
                 , aLOM_FULL_REQ_QTY   -- Qté besoin CPT
                 , 0   -- QtéSupInfReception
                 , 0   -- Qté Conso
                 , 0   -- QtéRebut
                 , 0   -- QtéRetour
                 , 0   -- Qté PT Rebut
                 , 0   -- Qté Démonté
                 , 0   -- Qté Démonté Récupéré
                 , 0   -- Qté Démonté rebut
                 , 0   -- Qté CPT réceptioné
                 , 0   -- Qté max récept
                 , 0   -- Qté max fab
                 , 0   -- QtéDipso
                 , 0   -- Prix
                 , 0   -- Manco
                 , CurFalLotMatLinkProp.C_DISCHARGE_COM   -- Code décharge
                 , aC_CHRONOLOGY_TYPE   -- Type de caract chrono
                 , CurFalLotMatLinkProp.C_TYPE_COM   -- Type de lien
                 , CurFalLotMatLinkProp.C_KIND_COM   -- Genre de lien
                 , null   -- Semaine
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GETUSERINI
                  );
    end if;   -- Fin if bln continue then...
  end CreateNewCompPOF;

  /**
  * procedure MAJOldCompPOF
  * Description : Processus de Mise à jour des composants POF
  *
  * @author ECA
  * @lastUpdate
  * @public
  * @param aFAL_LOT_MAT_LINK_PROP_ID : Composant POF mis à jour
  *        aQuantity                 : Quantité à mettre à jour
  */
  procedure MAJOldCompPOF(aFAL_LOT_MAT_LINK_PROP_ID FAL_LOT_MAT_LINK_PROP.FAL_LOT_MAT_LINK_PROP_ID%type, aQuantity in number)
  is
  begin
    update FAL_LOT_MAT_LINK_PROP LOM
       set   -- Qté Total = Nvelle QtéSupInf + Qté besoin
          LOM.LOM_FULL_REQ_QTY = LOM.LOM_BOM_REQ_QTY + LOM.LOM_ADJUSTED_QTY - aQuantity
        -- Qté BesoinCPT = Qté Totale
    ,     LOM.LOM_NEED_QTY = LOM.LOM_BOM_REQ_QTY + LOM.LOM_ADJUSTED_QTY - aQuantity
        -- Nvelle Qtésupinf = QtéSupInf + Quantity
    ,     LOM.LOM_ADJUSTED_QTY = LOM.LOM_ADJUSTED_QTY - aQuantity
        , A_DATEMOD = sysdate
        , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where LOM.FAL_LOT_MAT_LINK_PROP_ID = aFAL_LOT_MAT_LINK_PROP_ID;
  end MAJOldCompPOF;

  /**
  * procedure DeleteOldCompPOF
  * Description : Processus de Suppresssion d'un ancien composant POF
  *
  * @author ECA
  * @lastUpdate
  * @public
  * @param aFAL_LOT_MAT_LINK_PROP_ID : Composant POF
  */
  procedure DeleteOldCompPOF(aFAL_LOT_MAT_LINK_PROP_ID FAL_LOT_MAT_LINK_PROP.FAL_LOT_MAT_LINK_PROP_ID%type)
  is
  begin
    delete from FAL_LOT_MAT_LINK_PROP
          where FAL_LOT_MAT_LINK_PROP_ID = aFAL_LOT_MAT_LINK_PROP_ID;
  end;

  /**
  * procedure InsertFalCBCompLevel
  * Description : Insertion d'un nouveau produit (S'il n'existe pas) dans la table des niveaux complémentaires du CB.
  *
  * @author ECA
  * @lastUpdate
  * @public
  * @param aGCO_GOOD_ID : Composant POF
  *        aCCL_SESSION_ID           : ID SESSION Oracle
  */
  procedure InsertFalCBCompLevel(
    aGCO_GOOD_ID    GCO_GOOD.GCO_GOOD_ID%type
  ,   -- Produit equivalent
    aCCL_SESSION_ID FAL_CB_COMP_LEVEL.CCL_SESSION_ID%type
  , aCCL_LEVEL      FAL_CB_COMP_LEVEL.CCL_LEVEL%type default 0
  )
  is
    aFPL_LEVEL integer;
  begin
    insert into FAL_CB_COMP_LEVEL
                (FAL_CB_COMP_LEVEL_ID
               , GCO_GOOD_ID
               , CCL_LEVEL
               , CCL_SESSION_ID
               , A_DATECRE
               , A_IDCRE
                )
      select GetNewId
           , aGCO_GOOD_ID
           , nvl(aCCL_LEVEL, 0)   -- Niveau 0 car produit acheté (De plus bas niveau).
           , aCCL_SESSION_ID
           , sysdate
           , PCS.PC_I_LIB_SESSION.GETUSERINI
        from dual
       where not exists(select CCL.FAL_CB_COMP_LEVEL_ID
                          from FAL_CB_COMP_LEVEL CCL
                         where CCL.GCO_GOOD_ID = aGCO_GOOD_ID
                           and CCL.CCL_SESSION_ID = aCCL_SESSION_ID);
  end InsertFalCBCompLevel;

  /**
  * procedure MAJProposition
  * Description : Mise à jour du flag de la proposition indiquant que les composants en doivent pas être recréés
  *               à la reprise de la proposition
  *
  * @author ECA
  * @lastUpdate
  * @public
  * @param aFAL_LOT_PROP_ID
  */
  procedure MAJProposition(aFAL_LOT_PROP_ID FAL_LOT_PROP.FAL_LOT_PROP_ID%type)
  is
  begin
    update FAL_LOT_PROP
       set LOT_CPT_CHANGE = 1
     where FAL_LOT_PROP_ID = aFAL_LOT_PROP_ID;
  end MAJProposition;

  /**
  * procedure GetApproQuantityDispo
  * Description : Recherche des quantité en appro (Hors POA) disponible pour compensation du besoin en générique
  *
  * @author ECA
  * @lastUpdate
  * @public
  * @param aPrmFirstPass : Premier passage Appro sans générique ou = au générique du besoin à compenser
  *        aPrmStockList : Liste Stocks CB
  *        aGCO_GOOD_ID : Produit Equivalent
  *      aGCO_GCO_GOOD_ID : Produit Composant POF
  *      aFAN_BEG_PLAN : Date début besoin
  *      aRestrictOnFinalDate : Paramètre CB
  *      aRestrictDate : Paramètre CB
  *      aRestrictOnDocRecordID : Paramètre CB
  * @param   iUseMasterPlanProcurements     : Prise en compte des appros issus du plan directeur
  * @param   iUseMasterPlanRequirements     : Prise en compte des besoins issus du plan directeur
  *      aAPL in out NUMBER : Appro libre
  *      aSBE in out NUMBER : besoins libres
  *      aAPL1 in out NUMBER : Appro libres à date besoin + décalage du générique
  *      aSBE1 in out NUMBER : Besoins libres à date besoin + décalage du générique
  *      aSTD in out NUMBER : Somme des Qté dispo + Entrées provisoires en stock
  */
  procedure GetApproQuantityDispo(
    aPrmFirstPass              in     boolean
  , aPrmStockList              in     varchar2
  , aGCO_GOOD_ID               in     GCO_GOOD.GCO_GOOD_ID%type
  , aGCO_GCO_GOOD_ID           in     GCO_GOOD.GCO_GOOD_ID%type
  , aFAN_BEG_PLAN              in     FAL_NETWORK_NEED.FAN_BEG_PLAN%type
  , aRestrictOnFinalDate       in     integer
  , aRestrictDate              in     date
  , aRestrictOnDocRecordID     in     number
  , iUseMasterPlanProcurements in     integer
  , iUseMasterPlanRequirements in     integer
  , aAPL                       in out number
  , aSBE                       in out number
  , aAPL1                      in out number
  , aSBE1                      in out number
  , aSTD                       in out number
  )
  is
    BuffSQL        varchar2(2000);
    Cursor_Handle  integer;
    Execute_Cursor integer;
  begin
    -- Calcul de la Somme des appro libres et somme des appro libre en tenant compte des délais et du décalage...etc
    begin
      aAPL            := 0;
      aAPL1           := 0;
      BuffSQL         :=
        'SELECT NVL(SUM(FNS.FAN_FREE_QTY),0) APL ' ||
        '      ,NVL(SUM(DECODE(FAL_BLOC_EQUIVALENCE_CONTROL.CompareDate(TRUNC(FNS.FAN_END_PLAN),TRUNC(FAL_BLOC_EQUIVALENCE_CONTROL.GetShiftedDate(:aFAN_BEG_PLAN,:aCOMPOSANT_POF))) ' ||
        '                 ,1 ' ||
        '                 ,FNS.FAN_FREE_QTY ' ||
        '                 ,0)) ' ||
        '           ,0) APL1 ' ||
        '  FROM FAL_NETWORK_SUPPLY FNS ' ||
        '     , DOC_POSITION_DETAIL PDE ' ||
        ' WHERE FNS.GCO_GOOD_ID = :aGCO_GOOD_ID ' ||
        '   AND FNS.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID (+) ' ||
        '   AND FNS.FAL_DOC_PROP_ID IS NULL ';

      -- Restriction sur date fin des appro à considérer
      if aRestrictOnFinalDate <> 0 then
        BuffSQL  := BuffSQL || '   AND FNS.FAN_END_PLAN < :aRestrictDate';
      end if;

      -- Restriction sur le dossier
      if aRestrictOnDocRecordID <> 0 then
        BuffSQL  := BuffSQL || '   AND FNS.DOC_RECORD_ID < :aRestrictOnDocRecordID';
      end if;

      -- Restriction Hors plan directeur
      if iUseMasterPlanProcurements = 0 then
        BuffSQL  := BuffSQL || '   AND FNS.C_GAUGE_TITLE <> PCS.PC_CONFIG.GetConfig(''FAL_TITLE_PLAN_DIR'')';
      end if;

      -- Restriction stocks du CB
      if aPrmStockList is not null then
        BuffSQL  := BuffSQL || '   AND FNS.STM_STOCK_ID IN (' || aPrmStockList || ')';
      end if;

      -- Première ou second passe des produits équivalents
      if aPrmFirstPass then
        BuffSQL  :=
          BuffSQL ||
          '   AND ((FNS.DOC_POSITION_DETAIL_ID IS NULL) ' ||
          '        OR ' ||
          '        (FNS.DOC_POSITION_DETAIL_ID IS NOT NULL ' ||
          '           AND (PDE.GCO_GCO_GOOD_ID IS NULL OR PDE.GCO_GCO_GOOD_ID = :aGCO_GCO_GOOD_ID))) ';
      end if;

      Cursor_Handle   := DBMS_SQL.open_cursor;
      DBMS_SQL.parse(Cursor_Handle, BuffSQL, DBMS_SQL.V7);

      if aPrmFirstPass then
        DBMS_SQL.Bind_variable(Cursor_Handle, 'aGCO_GCO_GOOD_ID', aGCO_GCO_GOOD_ID);
      end if;

      DBMS_SQL.Bind_variable(Cursor_Handle, 'aGCO_GOOD_ID', aGCO_GOOD_ID);
      DBMS_SQL.Bind_variable(Cursor_Handle, 'aCOMPOSANT_POF', aGCO_GCO_GOOD_ID);
      DBMS_SQL.Bind_variable(Cursor_Handle, 'aFAN_BEG_PLAN', aFAN_BEG_PLAN);

      if aRestrictOnFinalDate <> 0 then
        DBMS_SQL.Bind_variable(Cursor_Handle, 'aRestrictDate', aRestrictDate);
      end if;

      if aRestrictOnDocRecordID <> 0 then
        DBMS_SQL.Bind_variable(Cursor_Handle, 'aRestrictOnDocRecordID', aRestrictOnDocRecordID);
      end if;

      DBMS_SQL.define_column(Cursor_Handle, 1, aAPL);
      DBMS_SQL.define_column(Cursor_Handle, 2, aAPL1);
      Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);

      if DBMS_SQL.fetch_rows(Cursor_Handle) > 0 then
        DBMS_SQL.column_value(Cursor_Handle, 1, aAPL);
        DBMS_SQL.column_value(Cursor_Handle, 2, aAPL1);
      else
        aAPL   := 0;
        aAPL1  := 0;
      end if;

      DBMS_SQL.close_cursor(Cursor_Handle);
    exception
      when others then
        begin
          DBMS_SQL.Close_cursor(Cursor_Handle);
          aAPL   := 0;
          aAPL1  := 0;
        end;
    end;

    -- Calcul de la Somme des besoins libres et somme des besoins libre en tenant compte des délais et du décalage
    begin
      aSBE            := 0;
      aSBE1           := 0;
      BuffSQL         :=
        'SELECT NVL(SUM(FNN.FAN_FREE_QTY),0) SBE ' ||
        '      ,NVL(SUM(DECODE(FAL_BLOC_EQUIVALENCE_CONTROL.CompareDate(TRUNC(FNN.FAN_BEG_PLAN),TRUNC(FAL_BLOC_EQUIVALENCE_CONTROL.GetShiftedDate(:aFAN_BEG_PLAN,:aCOMPOSANT_POF))) ' ||
        '                 ,1 ' ||
        '                 ,FNN.FAN_FREE_QTY ' ||
        '                 ,0)) ' ||
        '           ,0) SBE1 ' ||
        '  FROM FAL_NETWORK_NEED FNN ' ||
        ' WHERE FNN.GCO_GOOD_ID = :aGCO_GOOD_ID ';

      -- Restriction sur date fin des appro à considérer
      if aRestrictOnFinalDate <> 0 then
        BuffSQL  := BuffSQL || '   AND FNN.FAN_BEG_PLAN < :aRestrictDate';
      end if;

      -- Restriction sur le dossier
      if aRestrictOnDocRecordID <> 0 then
        BuffSQL  := BuffSQL || '   AND FNN.DOC_RECORD_ID < :aRestrictOnDocRecordID';
      end if;

      -- Restriction Hors plan directeur
      if iUseMasterPlanRequirements = 0 then
        BuffSQL  := BuffSQL || '   AND FNN.C_GAUGE_TITLE <> PCS.PC_CONFIG.GetConfig(''FAL_TITLE_PLAN_DIR'')';
      end if;

      if aPrmStockList is not null then
        BuffSQL  := BuffSQL || '   AND FNN.STM_STOCK_ID IN (' || aPrmStockList || ')';
      end if;

      Cursor_Handle   := DBMS_SQL.open_cursor;
      DBMS_SQL.parse(Cursor_Handle, BuffSQL, DBMS_SQL.V7);
      DBMS_SQL.Bind_variable(Cursor_Handle, 'aGCO_GOOD_ID', aGCO_GOOD_ID);
      DBMS_SQL.Bind_variable(Cursor_Handle, 'aCOMPOSANT_POF', aGCO_GCO_GOOD_ID);
      DBMS_SQL.Bind_variable(Cursor_Handle, 'aFAN_BEG_PLAN', aFAN_BEG_PLAN);

      if aRestrictOnFinalDate <> 0 then
        DBMS_SQL.Bind_variable(Cursor_Handle, 'aRestrictDate', aRestrictDate);
      end if;

      if aRestrictOnDocRecordID <> 0 then
        DBMS_SQL.Bind_variable(Cursor_Handle, 'aRestrictOnDocRecordID', aRestrictOnDocRecordID);
      end if;

      DBMS_SQL.define_column(Cursor_Handle, 1, aSBE);
      DBMS_SQL.define_column(Cursor_Handle, 2, aSBE1);
      Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);

      if DBMS_SQL.fetch_rows(Cursor_Handle) > 0 then
        DBMS_SQL.column_value(Cursor_Handle, 1, aSBE);
        DBMS_SQL.column_value(Cursor_Handle, 2, aSBE1);
      else
        aSBE   := 0;
        aSBE1  := 0;
      end if;

      DBMS_SQL.close_cursor(Cursor_Handle);
    exception
      when others then
        begin
          DBMS_SQL.Close_cursor(Cursor_Handle);
          aSBE   := 0;
          aSBE1  := 0;
          raise;
        end;
    end;

    -- Calcul de la STD
    begin
      aSTD            := 0;
      BuffSQL         :=
        ' SELECT NVL(SUM(SPO.SPO_AVAILABLE_QUANTITY + SPO.SPO_PROVISORY_INPUT),0) STD_QTY ' ||
        '   FROM STM_STOCK_POSITION SPO ' ||
        '  WHERE SPO.GCO_GOOD_ID = :aGCO_GOOD_ID ';

      if aPrmStockList is not null then
        BuffSQL  := BuffSQL || '    AND SPO.STM_STOCK_ID IN (' || aPrmStockList || ')';
      end if;

      Cursor_Handle   := DBMS_SQL.open_cursor;
      DBMS_SQL.parse(Cursor_Handle, BuffSQL, DBMS_SQL.V7);
      DBMS_SQL.Bind_variable(Cursor_Handle, 'aGCO_GOOD_ID', aGCO_GOOD_ID);
      DBMS_SQL.define_column(Cursor_Handle, 1, aSTD);
      Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);

      if DBMS_SQL.fetch_rows(Cursor_Handle) > 0 then
        DBMS_SQL.column_value(Cursor_Handle, 1, aSTD);
      else
        aSTD  := 0;
      end if;

      DBMS_SQL.close_cursor(Cursor_Handle);
    exception
      when others then
        begin
          DBMS_SQL.Close_cursor(Cursor_Handle);
          aSTD  := 0;
        end;
    end;
  end GetApproQuantityDispo;

  /**
  * Function ExistsPOFComponent
  * Description : Test l'existance d'un composant POF (Equivalent Générique)
  *
  * @author ECA
  * @lastUpdate
  * @public
  * @param aGCO_GOOD_ID     : Produit equivalent.
  *        aFAL_LOT_PROP_ID : Proposition.
  *        aGCO_GCO_GOOD_ID : Produit Générique.
  */
  function ExistsPOFComponent(
    aFAL_LOT_PROP_ID         FAL_LOT_PROP.FAL_LOT_PROP_ID%type
  , aGCO_GOOD_ID             GCO_GOOD.GCO_GOOD_ID%type
  , aGCO_GCO_GOOD_ID         GCO_GOOD.GCO_GOOD_ID%type
  , nPAC_SUPPLIER_PARTNER_ID PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  )
    return number
  is
    aFAL_LOT_MAT_LINK_PROP_ID FAL_LOT_MAT_LINK_PROP.FAL_LOT_MAT_LINK_PROP_ID%type;
  begin
    select max(FAL_LOT_MAT_LINK_PROP_ID)
      into aFAL_LOT_MAT_LINK_PROP_ID
      from FAL_LOT_MAT_LINK_PROP FLP
     where FLP.FAL_LOT_PROP_ID = aFAL_LOT_PROP_ID
       and FLP.GCO_GOOD_ID = aGCO_GOOD_ID   -- Equivalent
       and FLP.GCO_GCO_GOOD_ID = aGCO_GCO_GOOD_ID   -- Générique
       and nvl(FLP.PAC_SUPPLIER_PARTNER_ID, 0) = nvl(nPAC_SUPPLIER_PARTNER_ID, 0);

    return aFAL_LOT_MAT_LINK_PROP_ID;
  exception
    when others then
      return 0;
  end ExistsPOFComponent;

  /**
  * procedure EquivalenceBlocOnStockControl
  * Description : Controle des blocs d'équivalence sur stock
  *
  * @author ECA
  * @lastUpdate
  * @public
  * @param aPrmStockList : Liste de stocks
  */
  procedure EquivalenceBlocOnStockControl(
    aPrmStockList              in varchar2
  , aOracleSession             in varchar2
  , aPrmApproOnGenericProduct  in integer
  , aRestrictOnFinalDate       in integer
  , aRestrictDate              in date
  , aRestrictOnDocRecordID     in number
  , iUseMasterPlanProcurements in integer
  , iUseMasterPlanRequirements in integer
  )
  is
    -- Curseur
    Need_Comp_Pof_Tab         TTAB_NEED_COMP_POF;
    CurGcoEquivComponent      CUR_GCO_EQUIV_COMPONENT%rowtype;
    CurGcoEquivComponentAppro CUR_GCO_EQUIV_COMPONENT_APPRO%rowtype;
    -- Variables
    nFAL_LOT_MAT_LINK_PROP_ID FAL_LOT_MAT_LINK_PROP.FAL_LOT_MAT_LINK_PROP_ID%type;   -- Composant POF
    nFAL_LOT_PROP_ID          FAL_LOT_PROP.FAL_LOT_PROP_ID%type;   -- POF
    nFAL_DOC_PROP_ID          FAL_DOC_PROP.FAL_DOC_PROP_ID%type;   -- POA
    Q                         number;   -- Besoin à compenser
    nSTD                      number;   -- Somme des (QtéDisponible + QtéEntréeProvisoire)
    nSBE                      number;   -- Somme des besoins libre
    nSBE1                     number;   -- Somme des besoins libre tenant compte des délais et décalage
    nSBE1HS                   number;   -- Somme des besoins libre tenant compte des délais et décalage Hors stock disponible
    nSTMIN                    number;   -- Somme des stocks min
    nAPL                      number;   -- Somme des appro libres
    nAPL1                     number;   -- Somme des appro libre tenant compte des délais et décalage
    iATTSUIV                  integer;   -- Indique si l'on doit passer à l'attribution suivante (Besoin complètement compensé)
    nQteNewCpt                number;   -- Qté du composant de remplacement
    nCPTEQUIV                 number;   -- ID du Nouveau Compposant POF (null si inexistant)
    blnDoApproCompensation    boolean;   -- Indique s'il est nécessaire de passer à la compensation par les appros
    nNewPOFComponentID        number;   -- ID des nouveaux composants POF créés
    nFAN_NETW_QTY             number;   -- Nouvelle quantité POA attribuée sur besoin (après maj ou suppr des réseaux)
    nLOM_NEED_QTY             number;   -- Nouvelle quantité besoin après mise à jour des réseaux
    nATST                     number;   -- Qté attribuée sur stock
    acfgFAL_TITLE_PLAN_DIR    varchar2(255);
    blnPOAFounded             boolean;
    i                         integer;
  begin
    acfgFAL_TITLE_PLAN_DIR  := PCS.PC_CONFIG.GETCONFIG('FAL_TITLE_PLAN_DIR');

    -- Pour chaque attribution sur POA de chaque Besoin de type composant POF, trié par date besoin croissante
    --  . dont le produit est géré avec bloc d'équivalence
    --  . attribué à une POA.
    open CUR_FAL_NEED_COMP_POF(aRestrictOnFinalDate, aRestrictDate, aRestrictOnDocRecordID, iUseMasterPlanRequirements, acfgFAL_TITLE_PLAN_DIR);

    fetch CUR_FAL_NEED_COMP_POF
    bulk collect into Need_Comp_Pof_Tab;

    close CUR_FAL_NEED_COMP_POF;

    if Need_Comp_Pof_Tab.first is not null then
      for i in Need_Comp_Pof_Tab.first .. Need_Comp_Pof_Tab.last loop
        -- Besoin identifié
        nFAL_LOT_MAT_LINK_PROP_ID  := Need_Comp_Pof_Tab(i).FAL_LOT_MAT_LINK_PROP_ID;
        nFAL_LOT_PROP_ID           := Need_Comp_Pof_Tab(i).FAL_LOT_PROP_ID;
        nFAL_DOC_PROP_ID           := Need_Comp_Pof_Tab(i).FAL_DOC_PROP_ID;
        Q                          := Need_Comp_Pof_Tab(i).FLN_QTY;
        nATST                      := Need_Comp_Pof_Tab(i).FAN_STK_QTY;
        blnDoApproCompensation     := true;
        iATTSUIV                   := 0;

        -- 1) Premier parcours des produits équivalents : Compensation des besoins par les stocks
          -- Pour chaque produits équivalents au composant dont les dates de validité sont OK et de statut actif
        -- trié par stock le plus vieux (si FIFO):
        for CurGcoEquivComponent in CUR_GCO_EQUIV_COMPONENT(Need_Comp_Pof_Tab(i).GCO_GOOD_ID, Need_Comp_Pof_Tab(i).FAN_BEG_PLAN, aPrmStockList) loop
          -- Vérification de la disponibilité de stock pour les stocks du CB
          GetStockQuantityDispo(aPrmStockList, CurGcoEquivComponent.GCO_GCO_GOOD_ID   -- produit équivalent
                                                                                   , nSTD, nSBE, nSTMIN);

          if (nSTD - nSBE - nSTMIN) > 0 then
            -- Besoin complètement compensé
            if Q <= nSTD - nSBE then
              nQteNewCpt  := Q;
              iATTSUIV    := 1;
            -- Besoin partiellement compensé
            else
              nQteNewCpt  := nSTD - nSBE;
              iATTSUIV    := 0;
            end if;

            -- Le composant POF Existe-t-il déjà?
            nCPTEQUIV      :=
              ExistsPOFComponent(nFAL_LOT_PROP_ID
                               , CurGcoEquivComponent.GCO_GCO_GOOD_ID   -- Produit équivalent
                               , Need_Comp_Pof_Tab(i).GCO_GOOD_ID   -- Produit Générique
                               , null
                                );

            if nCPTEQUIV <> 0 then
              -- Processus MAJNewComposantPOF
              MAJNewCompPOF(nCPTEQUIV, nQteNewCpt, null);
              -- Mise à jour réseaux besoins
              FAL_NETWORK.ReseauBesoinPropCmpMAJ(nFAL_LOT_PROP_ID, nCPTEQUIV, nFAL_DOC_PROP_ID);
            else
              -- Processus CréationNewComposantPOF
              CreateNewCompPOF(nFAL_LOT_PROP_ID
                             , nFAL_LOT_MAT_LINK_PROP_ID   -- Composant à remplacer
                             , Need_Comp_Pof_Tab(i).GCO_GOOD_ID   -- Produit générique
                             , CurGcoEquivComponent.GCO_GCO_GOOD_ID   -- Produit équivalent
                             , nQteNewCpt   -- Quantité nouverau composant
                             , null   -- Fournisseur
                             , nNewPOFComponentID
                              );
              -- Création Réseaux besoin
              FAL_NETWORK_DOC.CreationReseauxBesoinPropComp(nFAL_LOT_PROP_ID, nNewPOFComponentID);
            end if;

            -- L'ancienne quantité besoin est-elle égale à celle du nouveau composant
            if GetNEEDLomNeedQty(nFAL_LOT_MAT_LINK_PROP_ID, nLOM_NEED_QTY) then
              if nLOM_NEED_QTY - nQteNewCpt = 0 then
                -- Suppression Enregistrement Réseaux besoin
                FAL_NETWORK.ReseauBesoinPropCmpSuppr(nFAL_LOT_MAT_LINK_PROP_ID);
                -- SuppressionOldComposantPOF
                DeleteOldCompPof(nFAL_LOT_MAT_LINK_PROP_ID);
              else
                -- Mise à jour de l'ancien composant POF
                MAJOldCompPOF(nFAL_LOT_MAT_LINK_PROP_ID, nQteNewCpt);
                -- Mise à jour réseaux besoins
                FAL_NETWORK.ReseauBesoinPropCmpMAJ(nFAL_LOT_PROP_ID, nFAL_LOT_MAT_LINK_PROP_ID, nFAL_DOC_PROP_ID);
              end if;
            end if;

            -- La quantité attribuée sur besoin de la POA =  0 ?
            blnPOAFounded  := GetPOANetworkQty(nFAL_DOC_PROP_ID, nFAN_NETW_QTY);

            if (   nFAN_NETW_QTY = 0
                or nFAN_NETW_QTY = nATST) then
              -- Suppresion POA
              FAL_PRC_FAL_DOC_PROP.DeleteOneDOCProposition(nFAL_DOC_PROP_ID, 1, 0, 0);
            else
              /* Si Appro sur produit générique --> Insertion du P. Générique dans la table des niveaux complémentaires,
               pour recalcul des POA sur générique qui n'ont pas été diminuées */
              if aPrmApproOnGenericProduct = 1 then
                InsertFalCBCompLevel(Need_Comp_Pof_Tab(i).GCO_GOOD_ID, aOracleSession);
              end if;
            end if;

            -- Ajout du produit s'il n'existe pas déjà dans la table des niveaux compl du CB
            InsertFalCBCompLevel(CurGcoEquivComponent.GCO_GCO_GOOD_ID, aOracleSession);
            -- Flag de non recréation des comp à la reprise de la proposition
            MAJProposition(nFAL_LOT_PROP_ID);

            -- Si Besoin partiellement compensé, nouvelle quantité à compenser
            if iATTSUIV = 0 then
              Q  := Q - nQteNewCpt;
            else
              blnDoApproCompensation  := false;
              exit;
            end if;
          end if;
        end loop;   -- Fin Parcours Prod Equiv avec compensation par les stocks

        -- Si les stocks n'ont pas permis de compenser le besoin en totalité, alors on continue sur  les appros
        if blnDoApproCompensation then
          -- 2) Second parcours des produits équivalents : Compensation des besoins par les appros
            -- sans générique ou avec générique identique au besoin à compenser (DOC_POSITION_DETAIL -> GCO_GCO_GOOD_ID )
          for CurGcoEquivComponentAppro in CUR_GCO_EQUIV_COMPONENT_APPRO(Need_Comp_Pof_Tab(i).GCO_GOOD_ID, Need_Comp_Pof_Tab(i).FAN_BEG_PLAN) loop
            GetApproQuantityDispo(true   --  Première passe
                                , aPrmStockList
                                , CurGcoEquivComponentAppro.GCO_GCO_GOOD_ID
                                , Need_Comp_Pof_Tab(i).GCO_GOOD_ID
                                , trunc(Need_Comp_Pof_Tab(i).FAN_BEG_PLAN)
                                , aRestrictOnFinalDate
                                , aRestrictDate
                                , aRestrictOnDocRecordID
                                , iUseMasterPlanProcurements
                                , iUseMasterPlanRequirements
                                , nAPL
                                , nSBE
                                , nAPL1
                                , nSBE1
                                , nSTD
                                 );
            -- Somme des besoins libres (Hors couverture par le stock)
            nSBE1HS  := nSTD - nSBE1;

            if nSBE1HS >= 0 then
              nSBE1HS  := 0;
            else
              nSBE1HS  := -1 * nSBE1HS;   -- Val Absolue
            end if;

            -- Vérification de la compatibilité des délais de ces appros avec le délai et le décalage autorisé du produit
            if nAPL1 - nSBE1HS > 0 then
              -- Calcul Q
              if Q <= nAPL1 - nSBE1HS then
                nQteNewCpt  := Q;
                iATTSUIV    := 1;
              else
                nQteNewCpt  := nAPL1 - nSBE1HS;
                iATTSUIV    := 0;
              end if;

              -- Le composant POF Existe-t-il déjà?
              nCPTEQUIV      := ExistsPOFComponent(nFAL_LOT_PROP_ID, CurGcoEquivComponentAppro.GCO_GCO_GOOD_ID, Need_Comp_Pof_Tab(i).GCO_GOOD_ID, null);

              if nCPTEQUIV <> 0 then
                -- Processus MAJNewComposantPOF
                MAJNewCompPOF(nCPTEQUIV, nQteNewCpt, null);
                -- Mise à jour réseaux besoins
                FAL_NETWORK.ReseauBesoinPropCmpMAJ(nFAL_LOT_PROP_ID, nCPTEQUIV, nFAL_DOC_PROP_ID);
              else
                -- Processus CréationNewComposantPOF
                CreateNewCompPOF(nFAL_LOT_PROP_ID
                               , nFAL_LOT_MAT_LINK_PROP_ID   -- Composant à remplacer
                               , Need_Comp_Pof_Tab(i).GCO_GOOD_ID   -- Produit générique
                               , CurGcoEquivComponentAppro.GCO_GCO_GOOD_ID   -- Produit équivalent
                               , nQteNewCpt   -- Quantité nouverau composant
                               , null   -- Fournisseur
                               , nNewPOFComponentID
                                );
                -- Création Réseaux besoin
                FAL_NETWORK_DOC.CreationReseauxBesoinPropComp(nFAL_LOT_PROP_ID, nNewPOFComponentID);
              end if;

              if GetNEEDLomNeedQty(nFAL_LOT_MAT_LINK_PROP_ID, nLOM_NEED_QTY) then
                -- L'ancienne quantité besoin est-elle égale à celle du nouveau composant
                if nLOM_NEED_QTY - nQteNewCpt = 0 then
                  -- Suppression Enregistrement Réseaux besoin
                  FAL_NETWORK.ReseauBesoinPropCmpSuppr(nFAL_LOT_MAT_LINK_PROP_ID);
                  -- SuppressionOldComposantPOF
                  DeleteOldCompPof(nFAL_LOT_MAT_LINK_PROP_ID);
                else
                  -- Mise à jour de l'ancien composant POF
                  MAJOldCompPOF(nFAL_LOT_MAT_LINK_PROP_ID, nQteNewCpt);
                  -- Mise à jour réseaux besoins
                  FAL_NETWORK.ReseauBesoinPropCmpMAJ(nFAL_LOT_PROP_ID, nFAL_LOT_MAT_LINK_PROP_ID, nFAL_DOC_PROP_ID);
                end if;
              end if;

              -- La quantité attribuée sur besoin de la POA =  0 ?
              blnPOAFounded  := GetPOANetworkQty(nFAL_DOC_PROP_ID, nFAN_NETW_QTY);

              if (   nFAN_NETW_QTY = 0
                  or nFAN_NETW_QTY = nATST) then
                -- Suppresion POA
                FAL_PRC_FAL_DOC_PROP.DeleteOneDOCProposition(nFAL_DOC_PROP_ID, 1, 0, 0);
              else
                /* Si Appro sur produit générique --> Insertion du P. Générique dans la table des niveaux complémentaires,
                   pour recalcul des POA sur générique qui n'ont pas été diminuées */
                if aPrmApproOnGenericProduct = 1 then
                  insertFalCBCompLevel(Need_Comp_Pof_Tab(i).GCO_GOOD_ID, aOracleSession);
                end if;
              end if;

              -- Ajout du produit s'il n'existe pas déjà dans la table des niveaux compl du CB
              InsertFalCBCompLevel(CurGcoEquivComponentAppro.GCO_GCO_GOOD_ID, aOracleSession);
              -- Flag de non recréation des comp à la reprise de la proposition
              MAJProposition(nFAL_LOT_PROP_ID);

              -- Si Besoin partiellement compensé, nouvelle quantité à compenser
              if iATTSUIV = 0 then
                Q  := Q - nQteNewCpt;
              else
                exit;
              end if;
            end if;
          end loop;   -- Fin 2) Second parcours des produits équivalents : Compensation des besoins par les appros

          -- 3) Troisième parcours des produits équivalents : Compensation des besoins par les appros
            -- avec générique <> du besoin à compenser (DOC_POSITION_DETAIL -> GCO_GCO_GOOD_ID )
          if iATTSUIV = 0 then
            for CurGcoEquivComponentAppro in CUR_GCO_EQUIV_COMPONENT_APPRO(Need_Comp_Pof_Tab(i).GCO_GOOD_ID, Need_Comp_Pof_Tab(i).FAN_BEG_PLAN) loop
              GetApproQuantityDispo(false   --  Seconde passe
                                  , aPrmStockList
                                  , CurGcoEquivComponentAppro.GCO_GCO_GOOD_ID
                                  , Need_Comp_Pof_Tab(i).GCO_GOOD_ID
                                  , trunc(Need_Comp_Pof_Tab(i).FAN_BEG_PLAN)
                                  , aRestrictOnFinalDate
                                  , aRestrictDate
                                  , aRestrictOnDocRecordID
                                  , iUseMasterPlanProcurements
                                  , iUseMasterPlanRequirements
                                  , nAPL
                                  , nSBE
                                  , nAPL1
                                  , nSBE1
                                  , nSTD
                                   );
              -- Somme des besoins libres (Hors couverture par le stock)
              nSBE1HS  := nSTD - nSBE1;

              if nSBE1HS >= 0 then
                nSBE1HS  := 0;
              else
                nSBE1HS  := -1 * nSBE1HS;   -- Val Absolue
              end if;

              -- Vérification de la compatibilité des délais de ces appros avec le délai et le décalage autorisé du produit
              if nAPL1 - nSBE1HS > 0 then
                -- Calcul Q
                if Q <= nAPL1 - nSBE1HS then
                  nQteNewCpt  := Q;
                  iATTSUIV    := 1;
                else
                  nQteNewCpt  := nAPL1 - nSBE1HS;
                  iATTSUIV    := 0;
                end if;

                -- Le composant POF Existe-t-il déjà?
                nCPTEQUIV      := ExistsPOFComponent(nFAL_LOT_PROP_ID, CurGcoEquivComponentAppro.GCO_GCO_GOOD_ID, Need_Comp_Pof_Tab(i).GCO_GOOD_ID, null);

                if nCPTEQUIV <> 0 then
                  -- Processus MAJNewComposantPOF
                  MAJNewCompPOF(nCPTEQUIV, nQteNewCpt, null);
                  -- Mise à jour réseaux besoins
                  FAL_NETWORK.ReseauBesoinPropCmpMAJ(nFAL_LOT_PROP_ID, nCPTEQUIV, nFAL_DOC_PROP_ID);
                else
                  -- Processus CréationNewComposantPOF
                  CreateNewCompPOF(nFAL_LOT_PROP_ID
                                 , nFAL_LOT_MAT_LINK_PROP_ID   -- Composant à remplacer
                                 , Need_Comp_Pof_Tab(i).GCO_GOOD_ID   -- Produit générique
                                 , CurGcoEquivComponentAppro.GCO_GCO_GOOD_ID   -- Produit équivalent
                                 , nQteNewCpt   -- Quantité nouverau composant
                                 , null   -- Fournisseur
                                 , nNewPOFComponentID
                                  );
                  -- Création Réseaux besoin
                  FAL_NETWORK_DOC.CreationReseauxBesoinPropComp(nFAL_LOT_PROP_ID, nNewPOFComponentID);
                end if;

                if GetNEEDLomNeedQty(nFAL_LOT_MAT_LINK_PROP_ID, nLOM_NEED_QTY) then
                  -- L'ancienne quantité besoin est-elle égale à celle du nouveau composant
                  if nLOM_NEED_QTY - nQteNewCpt = 0 then
                    -- Suppression Enregistrement Réseaux besoin
                    FAL_NETWORK.ReseauBesoinPropCmpSuppr(nFAL_LOT_MAT_LINK_PROP_ID);
                    -- SuppressionOldComposantPOF
                    DeleteOldCompPof(nFAL_LOT_MAT_LINK_PROP_ID);
                  else
                    -- Mise à jour de l'ancien composant POF
                    MAJOldCompPOF(nFAL_LOT_MAT_LINK_PROP_ID, nQteNewCpt);
                    -- Mise à jour réseaux besoins
                    FAL_NETWORK.ReseauBesoinPropCmpMAJ(nFAL_LOT_PROP_ID, nFAL_LOT_MAT_LINK_PROP_ID, nFAL_DOC_PROP_ID);
                  end if;
                end if;

                -- La quantité attribuée sur besoin de la POA =  0 ?
                blnPOAFounded  := GetPOANetworkQty(nFAL_DOC_PROP_ID, nFAN_NETW_QTY);

                if (   nFAN_NETW_QTY = 0
                    or nFAN_NETW_QTY = nATST) then
                  -- Suppresion POA
                  FAL_PRC_FAL_DOC_PROP.DeleteOneDOCProposition(nFAL_DOC_PROP_ID, 1, 0, 0);
                else
                  /* Si Appro sur produit générique --> Insertion du P. Générique dans la table des niveaux complémentaires,
                     pour recalcul des POA sur générique qui n'ont pas été diminuées */
                  if aPrmApproOnGenericProduct = 1 then
                    insertFalCBCompLevel(Need_Comp_Pof_Tab(i).GCO_GOOD_ID, aOracleSession);
                  end if;
                end if;

                -- Ajout du produit s'il n'existe pas déjà dans la table des niveaux compl du CB
                InsertFalCBCompLevel(CurGcoEquivComponentAppro.GCO_GCO_GOOD_ID, aOracleSession);
                -- Flag de non recréation des comp à la reprise de la proposition
                MAJProposition(nFAL_LOT_PROP_ID);

                -- Si Besoin partiellement compensé, nouvelle quantité à compenser
                if iATTSUIV = 0 then
                  Q  := Q - nQteNewCpt;
                else
                  exit;
                end if;
              end if;
            end loop;   -- Fin 3) Second parcours des produits équivalents : Compensation des besoins par les appros
          end if;
        end if;
      end loop;   -- Fin pour chaque attribution sur POA de chaque Besoin de type composant POF
    end if;
  end EquivalenceBlocOnStockControl;

  /**
  * procedure ReplacePOAOnGenericPDT
  * Description : Remplacement des POA sur articles génériques.
  * Graph analyse : EvtsRemplPOAArticleGenerique
  * @author ECA
  * @lastUpdate
  * @public
  * @param aPrmStockList  : Liste de stocks.
  *        aOracleSession : Session oracle (Multi-user sur la table FAL_CB_COMPL_LEVEL.
  */
  procedure ReplacePOAOnGenericPDT(
    aPrmStockList              in varchar2
  , aOracleSession             in varchar2
  , aRestrictOnFinalDate       in integer
  , aRestrictDate              in date
  , aRestrictOnDocRecordID     in number
  , iUseMasterPlanRequirements in integer
  )
  is
    Need_Comp_Pof_Tab            TTAB_NEED_COMP_POF;
    nFAL_LOT_MAT_LINK_PROP_ID    number;   -- Composant POF
    nFAL_LOT_PROP_ID             number;   -- POF
    nFAL_DOC_PROP_ID             number;   -- POA
    Q                            number;   -- Qté besoin à compenser
    nGCO_GOOD_ID                 number;   -- Produit Générique
    nGCO_GCO_GOOD_ID             number;   -- Produit équivalent
    nPAC_SUPPLIER_PARTNER_ID     number;   -- Fournisseur
    nCPTEQUIV                    number;   -- Composant POF = au prod equiv existant
    nNewFAL_LOT_MAT_LINK_PROP_ID number;   -- ID nouveaux composants POF (Remplacement).
    nFAN_NETW_QTY                number;   -- Qté attribuée sur besoin de la POA (Après MAJ ou Suppr Réseaux).
    nATST                        number;   -- Qté attribuée sur stock
    nLOM_NEED_QTY                number;   -- Nouvelle quantité besoin après mise à jour des réseaux
    acfgFAL_TITLE_PLAN_DIR       varchar2(255);
    blnPOAFounded                boolean;
  begin
    acfgFAL_TITLE_PLAN_DIR  := PCS.PC_CONFIG.GETCONFIG('FAL_TITLE_PLAN_DIR');

    -- Pour chaque attribution sur POA de chaque Besoin de type composant POF, trié par date besoin croissante
    --  . dont le produit est géré avec bloc d'équivalence
    --  . attribué à une POA.
    open CUR_FAL_NEED_COMP_POF(aRestrictOnFinalDate, aRestrictDate, aRestrictOnDocRecordID, iUseMasterPlanRequirements, acfgFAL_TITLE_PLAN_DIR);

    fetch CUR_FAL_NEED_COMP_POF
    bulk collect into Need_Comp_Pof_Tab;

    close CUR_FAL_NEED_COMP_POF;

    if Need_Comp_Pof_Tab.first is not null then
      for i in Need_Comp_Pof_Tab.first .. Need_Comp_Pof_Tab.last loop
        -- Besoin identifié
        nFAL_LOT_MAT_LINK_PROP_ID  := Need_Comp_Pof_Tab(i).FAL_LOT_MAT_LINK_PROP_ID;
        nFAL_LOT_PROP_ID           := Need_Comp_Pof_Tab(i).FAL_LOT_PROP_ID;
        nFAL_DOC_PROP_ID           := Need_Comp_Pof_Tab(i).FAL_DOC_PROP_ID;
        Q                          := Need_Comp_Pof_Tab(i).FLN_QTY;
        nGCO_GOOD_ID               := Need_Comp_Pof_Tab(i).GENERIC_NEED_PDT;
        nATST                      := Need_Comp_Pof_Tab(i).FAN_STK_QTY;

        -- Il existe une donnée complémentaire d'achat pour le produit générique et elle a un produit fabriquant
        if ProductWithDCA(nGCO_GOOD_ID) then
          -- recherche du produit équivalent et du fournisseur
          GetEquivalentPDTAndSupplier(nGCO_GOOD_ID, nGCO_GCO_GOOD_ID, nPAC_SUPPLIER_PARTNER_ID);
          -- Il existe déjà un composant de la POF portant sur le produit Equivalent?
          nCPTEQUIV      := ExistsPOFComponent(nFAL_LOT_PROP_ID, nGCO_GCO_GOOD_ID   -- Equivalent
                                                                                 , nGCO_GOOD_ID   -- Générique
                                                                                               , nPAC_SUPPLIER_PARTNER_ID);

          if nCPTEQUIV <> 0 then
            -- Processus MAJNewComposantPOF
            MAJNewCompPOF(nCPTEQUIV, Q, nPAC_SUPPLIER_PARTNER_ID);
            -- Mise à jour réseaux besoins
            FAL_NETWORK.ReseauBesoinPropCmpMAJ(nFAL_LOT_PROP_ID, nCPTEQUIV, nFAL_DOC_PROP_ID);
          else
            -- Processus CréationNewComposantPOF
            CreateNewCompPOF(nFAL_LOT_PROP_ID   -- POF
                           , nFAL_LOT_MAT_LINK_PROP_ID   -- Composant à remplacer
                           , nGCO_GOOD_ID   -- Produit générique
                           , nGCO_GCO_GOOD_ID   -- Produit équivalent
                           , Q   -- Quantité nouverau composant
                           , nPAC_SUPPLIER_PARTNER_ID   -- Fournisseur
                           , nNewFAL_LOT_MAT_LINK_PROP_ID
                            );
            -- Création Réseaux besoin
            FAL_NETWORK_DOC.CreationReseauxBesoinPropComp(nFAL_LOT_PROP_ID, nNewFAL_LOT_MAT_LINK_PROP_ID);
          end if;

          -- Le besoin est-il complétement compensé?
          if GetNEEDLomNeedQty(nFAL_LOT_MAT_LINK_PROP_ID, nLOM_NEED_QTY) then
            if nLOM_NEED_QTY - Q = 0 then
              -- Suppression Enregistrement Réseaux besoin
              FAL_NETWORK.ReseauBesoinPropCmpSuppr(nFAL_LOT_MAT_LINK_PROP_ID);
              -- SuppressionOldComposantPOF
              DeleteOldCompPof(nFAL_LOT_MAT_LINK_PROP_ID);
            else
              -- Mise à jour de l'ancien composant POF
              MAJOldCompPOF(nFAL_LOT_MAT_LINK_PROP_ID, Q);
              -- Mise à jour réseaux besoins
              FAL_NETWORK.ReseauBesoinPropCmpMAJ(nFAL_LOT_PROP_ID, nFAL_LOT_MAT_LINK_PROP_ID, nFAL_DOC_PROP_ID);
            end if;
          end if;

          -- La quantité attribuée sur besoin de la POA =  0 ?
          blnPOAFounded  := GetPOANetworkQty(nFAL_DOC_PROP_ID, nFAN_NETW_QTY);

          if (   nFAN_NETW_QTY = 0
              or nFAN_NETW_QTY = nATST) then
            -- Suppresion POA
            FAL_PRC_FAL_DOC_PROP.DeleteOneDOCProposition(nFAL_DOC_PROP_ID, 1, 0, 0);
          end if;

          -- Ajout du produit s'il n'existe pas déjà dans la table des niveaux compl du CB
          InsertFalCBCompLevel(nGCO_GCO_GOOD_ID, aOracleSession);
          -- Flag de non recréation des comp à la reprise de la proposition
          MAJProposition(nFAL_LOT_PROP_ID);
        end if;
      end loop;   -- Fin pour chaque POA...
    end if;
  end ReplacePOAOnGenericPDT;
end FAL_BLOC_EQUIVALENCE_CONTROL;
