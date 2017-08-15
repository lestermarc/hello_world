--------------------------------------------------------
--  DDL for Package Body FAL_REDO_ATTRIBS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_REDO_ATTRIBS" 
is
  -- Configurations
  cAttribOnCharactMode          constant integer   := to_number(PCS.PC_CONFIG.GETCONFIG('FAL_ATTRIB_ON_CHARACT_MODE') );
  cDocLocationLink              constant integer   := to_number(PCS.PC_CONFIG.GetConfig('DOC_LOCATION_LINK') );
  cAttribLogMode                constant integer   := to_number(PCS.PC_CONFIG.GetConfig('FAL_ATTRIB_LOG_MODE') );
  /* Indique si on prend tous les besoins ou seulement ceux issus de composants d'OF en traçabilité complète */
  cAllReqComplTrace             constant integer   := to_number(PCS.PC_CONFIG.GetConfig('FAL_ALL_REQ_ON_COMPLETE_TRACE') );
  /* Valeurs du type de réservation - C_RESERVATION_TYP ou config DOC_TYPE_AUTO_LINK */
  rtNoAllocation                constant integer   := 0;
  rtAllocStockOnTotalQty        constant integer   := 1;
  rtAllocStockPartialQty        constant integer   := 2;
  rtAllocStockAndProcOnTotalQty constant integer   := 3;
  rtAllocStockAndProcPartialQty constant integer   := 4;

  /**
   * cursor crStockPosition
   * description : Sélection des positions de stock du bien
   *
   * @created
   * @lastUpdate
   * @public
   * @param   ai1v1 ... ai5v5      : concaténation de "Id + valeur" des charact 1 à 5
   * @param   iGoodId              : Id du bien
   * @param   iSSTAStockId         : Id du stock sous-traitant
   * @param   iThirdId             : id du tiers
   * @param   iTimeLimitManagement : prise en compte ou non des positions de stock non périmée
   * @param   iDate                : date du besoin
   * @param   iStockListId         : Liste des stocks sélectionnés
   * @param   iSortOnChrono        : indique si on effectue ou non un tri chronologique et/ou de ré-analyse croissante (ASC)
   *                                 - 0 : pas de tri
   *                                 - 1 : tri ascendant sur la plus petite date entre la date de péremption et la date de ré-analyse
   *                                 - 2 : tri chronologique descendant
   */
  cursor crStockPosition(
    ai1v1                varchar2
  , ai2v2                varchar2
  , ai3v3                varchar2
  , ai4v4                varchar2
  , ai5v5                varchar2
  , iGoodId              GCO_GOOD.GCO_GOOD_ID%type
  , iThirdId             number
  , iTimeLimitManagement number
  , iDate                date
  , iStockListId         varchar2
  , iStockId             STM_STOCK.STM_STOCK_ID%type
  , iLocationId          STM_LOCATION.STM_LOCATION_ID%type
  , iSSTAStockId         number default null
  , iSortOnChrono        integer default 0
  )
  is
    select        SPO.SPO_AVAILABLE_QUANTITY
                , SPO.STM_STOCK_POSITION_ID
                , SPO.STM_LOCATION_ID
                , SPO.SPO_SET
             from STM_STOCK_POSITION SPO
                , STM_LOCATION B
                , GCO_CHARACTERIZATION CHAR1
                , GCO_CHARACTERIZATION CHAR2
                , GCO_CHARACTERIZATION CHAR3
                , GCO_CHARACTERIZATION CHAR4
                , GCO_CHARACTERIZATION CHAR5
                , STM_ELEMENT_NUMBER SEM
            where SPO.GCO_GOOD_ID = iGoodId
              and SPO.STM_LOCATION_ID = B.STM_LOCATION_ID
              and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = SEM.STM_ELEMENT_NUMBER_ID(+)
              and SPO.GCO_CHARACTERIZATION_ID = CHAR1.GCO_CHARACTERIZATION_ID(+)
              and SPO.GCO_GCO_CHARACTERIZATION_ID = CHAR2.GCO_CHARACTERIZATION_ID(+)
              and SPO.GCO2_GCO_CHARACTERIZATION_ID = CHAR3.GCO_CHARACTERIZATION_ID(+)
              and SPO.GCO3_GCO_CHARACTERIZATION_ID = CHAR4.GCO_CHARACTERIZATION_ID(+)
              and SPO.GCO4_GCO_CHARACTERIZATION_ID = CHAR5.GCO_CHARACTERIZATION_ID(+)
              and SPO.STM_STOCK_ID not in(select STM_STOCK_ID
                                            from STM_STOCK STO
                                           where STO.STO_SUBCONTRACT = 1
                                             and STO.PAC_SUPPLIER_PARTNER_ID is not null
                                             and STO.STM_STOCK_ID <> iSSTAStockId)
              and (    (SPO.STM_STOCK_ID = iSSTAStockId)
                   or (    cDocLocationLink = 1
                       and SPO.STM_LOCATION_ID = iLocationId)
                   or (    cDocLocationLink = 2
                       and SPO.STM_STOCK_ID = iStockId)
                   or (    cDocLocationLink = 3
                       and iStockListId is null
                       and exists(select STM_STOCK_ID
                                    from STM_STOCK
                                   where STM_STOCK_ID = SPO.STM_STOCK_ID
                                     and C_ACCESS_METHOD = 'PUBLIC'
                                     and STO_NEED_CALCULATION = 1)
                      )
                   or (    cDocLocationLink = 3
                       and instr(',' || iStockListId || ',', ',' || SPO.STM_STOCK_ID || ',') <> 0)
                  )
              and SPO.SPO_AVAILABLE_QUANTITY > 0
              and (    (     (cAttribOnCharactMode = 1)
                        and (    (    Ai1v1 || Ai2v2 || Ai3v3 || Ai4v4 || Ai5v5 is not null
                                  and (    (Ai1v1 in
                                              (concat(SPO.GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_1)
                                             , concat(SPO.GCO_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_2)
                                             , concat(SPO.GCO2_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_3)
                                             , concat(SPO.GCO3_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_4)
                                             , concat(SPO.GCO4_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_5)
                                              )
                                           )
                                       or (Ai1v1 is null)
                                      )
                                  and (    (Ai2v2 in
                                              (concat(SPO.GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_1)
                                             , concat(SPO.GCO_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_2)
                                             , concat(SPO.GCO2_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_3)
                                             , concat(SPO.GCO3_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_4)
                                             , concat(SPO.GCO4_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_5)
                                              )
                                           )
                                       or (Ai2v2 is null)
                                      )
                                  and (    (Ai3v3 in
                                              (concat(SPO.GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_1)
                                             , concat(SPO.GCO_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_2)
                                             , concat(SPO.GCO2_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_3)
                                             , concat(SPO.GCO3_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_4)
                                             , concat(SPO.GCO4_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_5)
                                              )
                                           )
                                       or (Ai3v3 is null)
                                      )
                                  and (    (Ai4v4 in
                                              (concat(SPO.GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_1)
                                             , concat(SPO.GCO_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_2)
                                             , concat(SPO.GCO2_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_3)
                                             , concat(SPO.GCO3_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_4)
                                             , concat(SPO.GCO4_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_5)
                                              )
                                           )
                                       or (Ai4v4 is null)
                                      )
                                  and (    (Ai5v5 in
                                              (concat(SPO.GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_1)
                                             , concat(SPO.GCO_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_2)
                                             , concat(SPO.GCO2_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_3)
                                             , concat(SPO.GCO3_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_4)
                                             , concat(SPO.GCO4_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_5)
                                              )
                                           )
                                       or (Ai5v5 is null)
                                      )
                                 )
                             or (    Ai1v1 || Ai2v2 || Ai3v3 || Ai4v4 || Ai5v5 is null
                                 and fal_tools.NullForNoMorpho(SPO.GCo_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_1, CHAR1.C_CHARACT_TYPE) ||
                                     fal_tools.NullForNoMorpho(SPO.GCo_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_2, CHAR2.C_CHARACT_TYPE) ||
                                     fal_tools.NullForNoMorpho(SPO.GCo2_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_3, CHAR3.C_CHARACT_TYPE) ||
                                     fal_tools.NullForNoMorpho(SPO.GCo3_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_4, CHAR4.C_CHARACT_TYPE) ||
                                     fal_tools.NullForNoMorpho(SPO.GCo4_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_5, CHAR5.C_CHARACT_TYPE) is null
                                )
                            )
                       )
                   or (     (cAttribOnCharactMode <> 1)
                       and (    (     (    (Ai1v1 in
                                              (concat(SPO.GCo_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_1)
                                             , concat(SPO.GCo_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_2)
                                             , concat(SPO.GCo2_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_3)
                                             , concat(SPO.GCo3_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_4)
                                             , concat(SPO.GCo4_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_5)
                                              )
                                           )
                                       or (Ai1v1 is null)
                                      )
                                 and (    (Ai2v2 in
                                             (concat(SPO.GCo_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_1)
                                            , concat(SPO.GCo_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_2)
                                            , concat(SPO.GCo2_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_3)
                                            , concat(SPO.GCo3_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_4)
                                            , concat(SPO.GCo4_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_5)
                                             )
                                          )
                                      or (Ai2v2 is null)
                                     )
                                 and (    (Ai3v3 in
                                             (concat(SPO.GCo_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_1)
                                            , concat(SPO.GCo_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_2)
                                            , concat(SPO.GCo2_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_3)
                                            , concat(SPO.GCo3_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_4)
                                            , concat(SPO.GCo4_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_5)
                                             )
                                          )
                                      or (Ai3v3 is null)
                                     )
                                 and (    (Ai4v4 in
                                             (concat(SPO.GCo_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_1)
                                            , concat(SPO.GCo_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_2)
                                            , concat(SPO.GCo2_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_3)
                                            , concat(SPO.GCo3_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_4)
                                            , concat(SPO.GCo4_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_5)
                                             )
                                          )
                                      or (Ai4v4 is null)
                                     )
                                 and (    (Ai5v5 in
                                             (concat(SPO.GCo_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_1)
                                            , concat(SPO.GCo_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_2)
                                            , concat(SPO.GCo2_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_3)
                                            , concat(SPO.GCo3_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_4)
                                            , concat(SPO.GCo4_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_5)
                                             )
                                          )
                                      or (Ai5v5 is null)
                                     )
                                )
                            or (fal_tools.NullForNoMorpho(SPO.GCo_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_1, CHAR1.C_CHARACT_TYPE) ||
                                fal_tools.NullForNoMorpho(SPO.GCo_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_2, CHAR2.C_CHARACT_TYPE) ||
                                fal_tools.NullForNoMorpho(SPO.GCo2_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_3, CHAR3.C_CHARACT_TYPE) ||
                                fal_tools.NullForNoMorpho(SPO.GCo3_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_4, CHAR4.C_CHARACT_TYPE) ||
                                fal_tools.NullForNoMorpho(SPO.GCo4_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_5, CHAR5.C_CHARACT_TYPE) is null
                               )
                           )
                      )
                  )
              -- Propose que les positions de stock non périmée pour la date spécifiée (en principe la date du besoin)
              and (    (iTimeLimitManagement = 0)
                   or (     (iTimeLimitManagement = 1)
                       and (   SPO.SPO_CHRONOLOGICAL is null
                            or GCO_I_LIB_CHARACTERIZATION.IsOutdated(iGoodID          => iGoodId
                                                                   , iThirdId         => iThirdId
                                                                   , iTimeLimitDate   => SPO.SPO_CHRONOLOGICAL
                                                                   , iDate            => iDate
                                                                    ) = 0
                           )
                      )
                  )
              -- Propose que les positions de stock avec statut qualité disponible pour le prévisionnel et les attributions ou sans gestion du statut qualité
              and (GCO_I_LIB_QUALITY_STATUS.IsNetworkLinkManagement(iQualityStatusId => SEM.GCO_QUALITY_STATUS_ID) = 1)
              -- Propose que les positions de stock qui n'ont pas dépassé la date de ré-analyse mais seulement si elles ne sont pas considérées
              -- comme disponible pour les traitements prévisionnels. La date de référence est la date du jour.
              and (    (PCS.PC_CONFIG.GetConfig('GCO_RETEST_PREV_MODE') = '0')
                   or (     (PCS.PC_CONFIG.GetConfig('GCO_RETEST_PREV_MODE') = '1')
                       and (STM_I_LIB_STOCK_POSITION.IsRetestNeeded(iStockPositionId => SPO.STM_STOCK_POSITION_ID, iDate => sysdate) = 0)
                      )
                  )
         order by (case
                     when iSSTAStockId = B.STM_STOCK_ID then 0
                     else 1
                   end)
                , (case   /* Tri ascendant sur la plus petite date entre la date de péremption et la date de ré-analyse */
                     when iSortOnChrono = 1 then least(nvl(SPO.SPO_CHRONOLOGICAL, '29991231'), nvl(to_char(SEM.SEM_RETEST_DATE, 'YYYYMMDD'), '29991231') )
                   end
                  ) asc
                , (case   /* Tri chronologique descendant */
                     when iSortOnChrono = 2 then SPO_CHRONOLOGICAL
                   end) desc
                , decode(SPO.STM_LOCATION_ID, nvl(iLocationId, 0), 0, 1)
                , B.LOC_CLASSIFICATION
                , PcsToNumber(SPO.SPO_CHARACTERIZATION_VALUE_1)
                , SPO.SPO_CHARACTERIZATION_VALUE_1
                , PcsToNumber(SPO.SPO_CHARACTERIZATION_VALUE_2)
                , SPO.SPO_CHARACTERIZATION_VALUE_2
                , PcsToNumber(SPO.SPO_CHARACTERIZATION_VALUE_3)
                , SPO.SPO_CHARACTERIZATION_VALUE_3
                , PcsToNumber(SPO.SPO_CHARACTERIZATION_VALUE_4)
                , SPO.SPO_CHARACTERIZATION_VALUE_4
                , PcsToNumber(SPO.SPO_CHARACTERIZATION_VALUE_5)
                , SPO.SPO_CHARACTERIZATION_VALUE_5
    for update of SPO.STM_STOCK_POSITION_ID;

  ExceptOnSPO_ASSIGN_QUANTITY            exception;
  pragma exception_init(ExceptOnSPO_ASSIGN_QUANTITY, -20102);

  /**
  * procedure : DeleteAttribOnSSTANeeds
  * Description : Destruction des attributions sur stock des besoins de la
  *               sous-traitance d'achat.
  *
  * @created
  * @lastUpdate
  * @public
  * @param   iGcoGoodId : Bien
  * @param   iInternalStockList : Liste des stocks internes sélectionnés
  * @param   iPreserveAttribOnSSTAStock : Conservation des attributions sur stock
  *          sous-traitants.
  */
  procedure DeleteAttribOnSSTANeeds(iGcoGoodId in number, iInternalStockList in varchar2 default '', iPreserveAttribOnSSTAStock in integer default 0)
  is
    lvSqlDeleteAttribs  varchar2(4000);
    TFalNetworkLinkId   T_FAL_NETWORK_LINK_ID;
    TFalNetworkNeedId   T_FAL_NETWORK_NEED_ID;
    TFalNetworkSupplyId T_FAL_NETWORK_SUPPLY_ID;
    TStmLocationId      T_STM_LOCATION_ID;
    TStmStockPositionId T_STM_STOCK_POSITION_ID;
    TFlnQty             T_FLN_QTY;
  begin
    lvSqlDeleteAttribs  :=
      ' select FNL.FAL_NETWORK_LINK_ID ' ||
      '      , FNL.FAL_NETWORK_NEED_ID ' ||
      '      , FNL.FAL_NETWORK_SUPPLY_ID ' ||
      '      , FNL.STM_STOCK_POSITION_ID ' ||
      '      , FNL.STM_LOCATION_ID ' ||
      '      , FNL.FLN_QTY ' ||
      '   from FAL_NETWORK_LINK FNL ' ||
      '      , FAL_NETWORK_NEED FNN ' ||
      '      , FAL_LOT LOT ' ||
      '      , FAL_LOT_PROP LOT_PROP ' ||
      '  where FNN.GCO_GOOD_ID = :iGcoGoodId ' ||
      '    and FNN.FAL_NETWORK_NEED_ID = FNL.FAL_NETWORK_NEED_ID ' ||
      '    and (FNN.FAL_LOT_ID is not null or FNN.FAL_LOT_PROP_ID is not null) ' ||
      '    and FNN.FAL_LOT_ID = LOT.FAL_LOT_ID (+) ' ||
      '    and FNN.FAL_LOT_PROP_ID = LOT_PROP.FAL_LOT_PROP_ID (+) ' ||
      '    and NVL(LOT.C_FAB_TYPE, NVL(LOT_PROP.C_FAB_TYPE, ''0'')) = ''4'' ' ||
      '    and not exists (select 1 ' ||
      '                      from GCO_SERVICE SER ' ||
      '                     where SER.GCO_GOOD_ID = :iGcoGoodId) ' ||
      '    and not exists (select 1 ' ||
      '                      from GCO_PSEUDO_GOOD PSE ' ||
      '                     where PSE.GCO_GOOD_ID = :iGcoGoodId) ';

    -- Restrictions des stocks du besoin aux stocks sélectionnés.
    if iInternalStockList is not null then
      lvSqlDeleteAttribs  := lvSqlDeleteAttribs || ' and FNN.STM_STOCK_ID in (' || iInternalStockList || ')';
    end if;

    -- Conservation des attributions sur les stocks sous-traitants.
    if iPreserveAttribOnSSTAStock = 1 then
      lvSqlDeleteAttribs  :=
        lvSqlDeleteAttribs ||
        ' and FNL.STM_STOCK_POSITION_ID not in (select POS.STM_STOCK_POSITION_ID ' ||
        '                                         from STM_STOCK_POSITION POS ' ||
        '                                            , STM_STOCK STO ' ||
        '                                        where STO.STM_STOCK_ID = POS.STM_STOCK_ID ' ||
        '                                          and STO.PAC_SUPPLIER_PARTNER_ID is not null ' ||
        '                                          and STO.STO_SUBCONTRACT = 1) ';
    end if;

    lvSqlDeleteAttribs  := lvSqlDeleteAttribs || ' FOR UPDATE';

    execute immediate lvSqlDeleteAttribs
    bulk collect into TFalNetworkLinkId
                    , TFalNetworkNeedId
                    , TFalNetworkSupplyId
                    , TStmStockPositionId
                    , TStmLocationId
                    , TFlnQty
                using iGcoGoodId, iGcoGoodId, iGcoGoodId;

    if TFalNetworkLinkId.count > 0 then
      for i in TFalNetworkLinkId.first .. TFalNetworkLinkId.last loop
        SuppressionAttribution(TFalNetworkLinkId(i), TFalNetworkNeedId(i), TFalNetworkSupplyId(i), TStmStockPositionId(i), TStmLocationId(i), TFlnQty(i) );
      end loop;
    end if;
  end DeleteAttribOnSSTANeeds;

  /**
  * procedure : DeleteAttribOnStandardNeeds
  * Description : Destruction des attributions sur stock des besoins standards
  *               logistique et fabrication
  *
  * @created
  * @lastUpdate
  * @public
  * @param   iGcoGoodId : Bien
  * @param   iInternalStockList : Liste des stocks internes sélectionnés
  * @param   iWithoutLogisticReqrmts : Conserver les attributions log existantes.
  * @param   iBesoinsLogistiquesGlobale : Globale -> Besoin log selon mode de gestion client
  * @param   iReconsBesOnProductMode : Besoin log selon mode de gestion client.
  */
  procedure DeleteAttribOnStandardNeeds(
    iGcoGoodId                 in number
  , iInternalStockList         in varchar2 default ''
  , iWithoutLogisticReqrmts    in integer default 0
  , iBesoinsLogistiquesGlobale in integer default 0
  , iReconsBesOnProductMode    in integer default 0
  )
  is
    lvSqlDeleteAttribs  varchar2(4000);
    TFalNetworkLinkId   T_FAL_NETWORK_LINK_ID;
    TFalNetworkNeedId   T_FAL_NETWORK_NEED_ID;
    TFalNetworkSupplyId T_FAL_NETWORK_SUPPLY_ID;
    TStmLocationId      T_STM_LOCATION_ID;
    TStmStockPositionId T_STM_STOCK_POSITION_ID;
    TFlnQty             T_FLN_QTY;
  begin
    -- Suppression des attributions d'un besoin du produit pour les stocks sélectionnés (Logistique et fabrication)
    lvSqlDeleteAttribs  :=
      ' select a.FAL_NETWORK_LINK_ID ' ||
      '      , a.FAL_NETWORK_NEED_ID ' ||
      '      , a.FAL_NETWORK_SUPPLY_ID ' ||
      '      , a.STM_STOCK_POSITION_ID ' ||
      '      , a.STM_LOCATION_ID ' ||
      '      , a.FLN_QTY ' ||
      '   from FAL_NETWORK_LINK a ' ||
      '      , FAL_NETWORK_NEED b ' ||
      '      , FAL_LOT LOT ' ||
      '      , FAL_LOT_PROP LOT_PROP ' ||
      '  where b.GCO_GOOD_ID = :iGcoGoodId ' ||
      '    and a.FAL_NETWORK_NEED_ID = b.FAL_NETWORK_NEED_ID ' ||
      '    and b.FAL_LOT_ID = LOT.FAL_LOT_ID (+) ' ||
      '    and b.FAL_LOT_PROP_ID = LOT_PROP.FAL_LOT_PROP_ID (+) ' ||
      '    and NVL(LOT.C_FAB_TYPE, NVL(LOT_PROP.C_FAB_TYPE, ''0'')) <> ''4'' ' ||
      '    and a.fal_network_link_id not in (select fcl.fal_network_link_id ' ||
      '                                        from fal_component_link fcl ' ||
      '                                       where fcl.fal_network_link_id = a.fal_network_link_id) ' ||
      '    and not exists (select 1 from gco_service     ser where b.gco_good_id = ser.gco_good_id) ' ||
      '    and not exists (select 1 from GCO_PSEUDO_GOOD pse where b.gco_good_id = pse.gco_good_id) ' ||
      '    and (doc_position_id is null ' ||
      '         or doc_position_id in (select doc_position_id from doc_position where c_gauge_type_pos not in (7,8,9,10))) ' ||
      '    and (doc_gauge_id is null ' ||
      '         or doc_gauge_id not in (select doc_gauge_id from fal_prop_def where c_prop_type = 4)) ';

    if iInternalStockList is not null then
      lvSqlDeleteAttribs  := lvSqlDeleteAttribs || ' and b.STM_STOCK_ID IN (' || iInternalStockList || ')';
    end if;

    if iWithoutLogisticReqrmts = 1 then
      lvSqlDeleteAttribs  := lvSqlDeleteAttribs || ' and (doc_position_detail_id is null)';
    elsif iBesoinsLogistiquesGlobale = 0 then
      lvSqlDeleteAttribs  :=
                      lvSqlDeleteAttribs || ' and ((DOC_POSITION_DETAIL_ID IS not NULL and STM_STOCK_POSITION_ID IS NULL) or (DOC_POSITION_DETAIL_ID IS NULL))';
    end if;

    -- On ne reconstruit pas les besoins de fabrication sur stock, donc on ne supprime pas ces attributions
    if iReconsBesOnProductMode = 0 then
      lvSqlDeleteAttribs  :=
        lvSqlDeleteAttribs ||
        '   AND ((FAL_LOT_MATERIAL_LINK_ID is not null and STM_STOCK_POSITION_ID IS NULL) or (FAL_LOT_MATERIAL_LINK_ID is null)) ' ||
        '   AND ((FAL_LOT_MAT_LINK_PROP_ID is not null and STM_STOCK_POSITION_ID IS NULL) or (FAL_LOT_MAT_LINK_PROP_ID is null)) ';
    end if;

    lvSqlDeleteAttribs  := lvSqlDeleteAttribs || ' FOR UPDATE';

    execute immediate lvSqlDeleteAttribs
    bulk collect into TFalNetworkLinkId
                    , TFalNetworkNeedId
                    , TFalNetworkSupplyId
                    , TStmStockPositionId
                    , TStmLocationId
                    , TFlnQty
                using iGcoGoodId;

    if TFalNetworkLinkId.count > 0 then
      for j in TFalNetworkLinkId.first .. TFalNetworkLinkId.last loop
        SuppressionAttribution(TFalNetworkLinkId(j), TFalNetworkNeedId(j), TFalNetworkSupplyId(j), TStmStockPositionId(j), TStmLocationId(j), TFlnQty(j) );
      end loop;
    end if;
  end DeleteAttribOnStandardNeeds;

  /**
  * procedure : DeleteSupplyAttribOnLocation
  * Description : Destruction des attributions sur stock
  *               approvisionnements.
  *
  * @created
  * @lastUpdate
  * @public
  * @param   iGcoGoodId : Bien
  * @param   iInternalStockList : Liste des stocks internes sélectionnés
  * @param   iWithoutLogisticReqrmts : Conserver les attributions log existantes.
  */
  procedure DeleteSupplyAttribOnLocation(iGcoGoodId in number, iInternalStockList in varchar2 default '', iWithoutLogisticReqrmts in integer default 0)
  is
    lvSqlDeleteAttribs  varchar2(4000);
    TFalNetworkLinkId   T_FAL_NETWORK_LINK_ID;
    TFalNetworkNeedId   T_FAL_NETWORK_NEED_ID;
    TFalNetworkSupplyId T_FAL_NETWORK_SUPPLY_ID;
    TStmLocationId      T_STM_LOCATION_ID;
    TStmStockPositionId T_STM_STOCK_POSITION_ID;
    TFlnQty             T_FLN_QTY;
  begin
    lvSqlDeleteAttribs  :=
      ' SELECT ' ||
      '  a.FAL_NETWORK_LINK_ID, ' ||
      '  a.FAL_NETWORK_NEED_ID, ' ||
      '  a.FAL_NETWORK_SUPPLY_ID, ' ||
      '  a.STM_STOCK_POSITION_ID, ' ||
      '  a.STM_LOCATION_ID, ' ||
      '  a.FLN_QTY ' ||
      ' FROM ' ||
      '  FAL_NETWORK_LINK a, ' ||
      '  FAL_NETWORK_SUPPLY b ' ||
      ' WHERE b.GCO_GOOD_ID = :iGcoGoodId ' ||
      '  and a.FAL_NETWORK_SUPPLY_ID = b.FAL_NETWORK_SUPPLY_ID ' ||
      '  and not exists (select 1 from gco_service     ser where b.gco_good_id = ser.gco_good_id) ' ||
      '  and not exists (select 1 from GCO_PSEUDO_GOOD pse where b.gco_good_id = pse.gco_good_id) ' ||
      '  and (doc_position_id is null ' ||
      '       or doc_position_id in (select doc_position_id from doc_position where c_gauge_type_pos not in (7,8,9,10)))' ||
      '  and (doc_gauge_id is null ' ||
      '       or doc_gauge_id not in (select doc_gauge_id from fal_prop_def where c_prop_type=4))';

    if iInternalStockList is not null then
      lvSqlDeleteAttribs  := lvSqlDeleteAttribs || ' and a.stm_location_id is NULL ' || ' and b.STM_STOCK_ID IN (' || iInternalStockList || ')';
    end if;

    if iWithoutLogisticReqrmts = 1 then
      lvSqlDeleteAttribs  :=
        lvSqlDeleteAttribs ||
        '   and not exists( ' ||
        '         select fal_network_need_id ' ||
        '           from fal_network_need fnn ' ||
        '          where fal_network_need_id = a.fal_network_need_id ' ||
        '            and fnn.doc_position_detail_id is not null )';
    end if;

    lvSqlDeleteAttribs  := lvSqlDeleteAttribs || ' FOR UPDATE';

    execute immediate lvSqlDeleteAttribs
    bulk collect into TFalNetworkLinkId
                    , TFalNetworkNeedId
                    , TFalNetworkSupplyId
                    , TStmStockPositionId
                    , TStmLocationId
                    , TFlnQty
                using iGcoGoodId;

    if TFalNetworkLinkId.count > 0 then
      for j in TFalNetworkLinkId.first .. TFalNetworkLinkId.last loop
        SuppressionAttribution(TFalNetworkLinkId(j), TFalNetworkNeedId(j), TFalNetworkSupplyId(j), TStmStockPositionId(j), TStmLocationId(j), TFlnQty(j) );
      end loop;
    end if;
  end DeleteSupplyAttribOnLocation;

  /**
  * function : IsTooManyAttribOnDifferentLot
  * Description : Permet de savoir si le nombre d'attributions respecte bien le coefficient de traçabilité
  *
  * @created
  * @lastUpdate
  * @public
  * @param   PrmGCO_GOOD_ID  :  Bien
  * @param   PrmFAL_NETWORK_NEED_ID : besoin
  */
  function IsTooManyAttribOnDifferentLot(PrmGCO_GOOD_ID GCO_GOOD.GCO_GOOD_ID%type, PrmFAL_NETWORK_NEED_ID FAL_NETWORK_NEED.FAL_NETWORK_NEED_ID%type)
    return number
  is
    cursor C1
    is
      select count(*)
        from (select distinct V
                         from (select FAL_TOOLS.ValueLotOfCaractLot(GCO_CHARACTERIZATION1_ID
                                                                  , FAN_CHAR_VALUE1
                                                                  , GCO_CHARACTERIZATION2_ID
                                                                  , FAN_CHAR_VALUE2
                                                                  , GCO_CHARACTERIZATION3_ID
                                                                  , FAN_CHAR_VALUE3
                                                                  , GCO_CHARACTERIZATION4_ID
                                                                  , FAN_CHAR_VALUE4
                                                                  , GCO_CHARACTERIZATION5_ID
                                                                  , FAN_CHAR_VALUE5
                                                                   ) as V
                                 from fal_network_supply S
                                where exists(
                                        select 1
                                          from fal_network_link L
                                         where S.fal_network_supply_id = L.fal_network_supply_id
                                           and gco_good_id = PrmGCO_GOOD_ID
                                           and FAL_NETWORK_NEED_ID = PrmFAL_NETWORK_NEED_ID)
                               union
                               select FAL_TOOLS.ValueLotOfCaractLot(GCO_CHARACTERIZATION_ID
                                                                  , SPO_CHARACTERIZATION_VALUE_1
                                                                  , GCO_GCO_CHARACTERIZATION_ID
                                                                  , SPO_CHARACTERIZATION_VALUE_2
                                                                  , GCO2_GCO_CHARACTERIZATION_ID
                                                                  , SPO_CHARACTERIZATION_VALUE_3
                                                                  , GCO3_GCO_CHARACTERIZATION_ID
                                                                  , SPO_CHARACTERIZATION_VALUE_4
                                                                  , GCO4_GCO_CHARACTERIZATION_ID
                                                                  , SPO_CHARACTERIZATION_VALUE_5
                                                                   )
                                 from stm_stock_position P
                                where exists(
                                        select 1
                                          from fal_network_link L
                                         where l.stm_stock_position_id = p.stm_stock_position_id
                                           and gco_good_id = PrmGCO_GOOD_ID
                                           and FAL_NETWORK_NEED_ID = PrmFAL_NETWORK_NEED_ID) ) );

    Combien                    number;
    aPDT_FULL_TRACABILITY_COEF GCO_PRODUCT.PDT_FULL_TRACABILITY_COEF%type;
  begin
    if FAl_TOOLS.IsFullTracability(PrmGCO_GOOD_ID) then
      Combien  := 0;

      open C1;

      fetch C1
       into Combien;

      close C1;

      select nvl(PDT_FULL_TRACABILITY_COEF, 1)
        into aPDT_FULL_TRACABILITY_COEF
        from GCO_PRODUCT
       where GCO_GOOD_ID = PrmGCO_GOOD_ID;

      if aPDT_FULL_TRACABILITY_COEF = 0 then
        aPDT_FULL_TRACABILITY_COEF  := 1;
      end if;

      if Combien > aPDT_FULL_TRACABILITY_COEF then
        return Combien;
      else
        return 0;
      end if;
    else
      return 0;
    end if;
  end IsTooManyAttribOnDifferentLot;

  /**
  * procedure : SuppressionAttribution
  * Description : Cette fonction permet de supprimer des attributions entre les
  *               différents élément en paramètres
  *
  * @created
  * @lastUpdate
  * @public
  * @param   PrmLINK_ID           : Attribution
  * @param   PrmNEED_ID           : Besoin
  * @param   PrmSUPPLY_ID         : Appro
  * @param   PrmSTOCK_POSITION_ID : Position de stock
  * @param   PrmLOCATION_ID       : Emplacement
  * @param   PrmQTY               : Quantité de l'attribution
  */
  procedure SuppressionAttribution(
    PrmLINK_ID           number
  , PrmNEED_ID           number
  , PrmSUPPLY_ID         number
  , PrmSTOCK_POSITION_ID number
  , PrmLOCATION_ID       number
  , PrmQTY               FAL_NETWORk_LINK.FLN_QTY%type
  , iDeleteNullQty       boolean default true
  )
  is
  begin
    FAL_PRC_ATTRIB.deleteAttrib(iNetworkLinkID     => PrmLINK_ID
                              , iNetworkNeedID     => PrmNEED_ID
                              , iNetworkSupplyID   => PrmSUPPLY_ID
                              , iStockPositionID   => PrmSTOCK_POSITION_ID
                              , iLocationID        => PrmLOCATION_ID
                              , iQty               => PrmQTY
                              , iDoDeleteNullQty   => iDeleteNullQty
                               );
  end SuppressionAttribution;

  -- Indique si le produit est lié à une caractérisation de type péremption
  function ProductHasPeremptionDate(PrmGCO_GOOD_ID GCO_GOOD.GCO_GOOD_ID%type)
    return boolean
  is
    Inused integer;
  begin
    select 1
      into Inused
      from GCO_CHARACTERIZATION
     where GCO_GOOD_ID = PrmGCO_GOOD_ID
       and c_charact_type = '5'
       and c_chronology_type = '3';

    return true;
  exception
    when no_data_found then
      return false;
  end ProductHasPeremptionDate;

  /**
  * function GetHorizonAttributionVente
  * Description : Recherche de l'horizon de réservation sur stock, depuis les données de vente du produit
  *
  * @created
  * @lastUpdate
  * @public
  * @param   iGoodId   Id du bien
  * @param   iThirdId  Id du tiers
  * @return  l'horizon de réservation sur stock du produit
  */
  function GetHorizonAttributionVente(iGoodId in GCO_GOOD.GCO_GOOD_ID%type, iThirdId in PAC_THIRD.PAC_THIRD_ID%type)
    return GCO_COMPL_DATA_SALE.CSA_SCALE_LINK%type
  is
    lnComplDataSaleId GCO_COMPL_DATA_SALE.GCO_COMPL_DATA_SALE_ID%type;
    liAllocHorizon    GCO_COMPL_DATA_SALE.CSA_SCALE_LINK%type           := 0;
  begin
    -- Recherche de la donnée complémentaire de vente
    lnComplDataSaleId  := GCO_FUNCTIONS.GetComplDataSaleId(iGoodId, iThirdId);

    if lnComplDataSaleId <> -1 then
      select nvl(CSA_SCALE_LINK, to_number(PCS.PC_CONFIG.GetConfig('DOC_SCALE_LINK') ) )
        into liAllocHorizon
        from GCO_COMPL_DATA_SALE
       where GCO_COMPL_DATA_SALE_ID = lnComplDataSaleId;
    else
      liAllocHorizon  := to_number(PCS.PC_CONFIG.GetConfig('DOC_SCALE_LINK') );
    end if;

    return nvl(liAllocHorizon, 0);
  end GetHorizonAttributionVente;

  /**
  * procedure : GetHorizonAttributionPdt
  * Description : Recherche de l'horizon d'attribution de la fiche produit
  *
  * @created
  * @lastUpdate
  * @public
  * @param   iGoodId   : Id du bien
  * @return  PDT_SCALE_LINK
  */
  function GetHorizonAttributionPdt(iGoodId GCo_GOOD.GCo_GOOD_ID%type)
    return GCo_PRODUCT.PDT_SCALE_LINK%type
  is
    resultat GCO_COMPL_DATA_SALE.CSA_SCALE_LINK%type;
  begin
    resultat  := null;

    select PDT_SCALE_LINK
      into Resultat
      from GCO_PRODUCT
     where GCO_GOOD_ID = iGoodId;

    return nvl(Resultat, 0);
  end GetHorizonAttributionPdt;

  function GetC_PARTNER_STATUS(iThirdId number)
    return PAC_CUSTOM_PARTNER.C_PARTNER_STATUS%type
  is
    ResC_PARTNER_STATUS PAC_CUSTOM_PARTNER.C_PARTNER_STATUS%type;
  begin
    select C_PARTNER_STATUS
      into ResC_PARTNER_STATUS
      from PAC_CUSTOM_PARTNER
     where PAC_CUSTOM_PARTNER_ID = iThirdId;

    return ResC_PARTNER_STATUS;
  exception
    when no_data_found then
      return null;
  end GetC_PARTNER_STATUS;

  /**
  * procedure : GetAllocationType
  * Description : Recherche le type de réservation du partenaire. Si non trouvé, retourne par défaut la valeur de la configuration DOC_TYPE_AUTO_LINK.
  *
  * @created
  * @lastUpdate
  * @public
  * @param   iThirdId   : Id du partenaire
  * @return  Type de réservation
  */
  function GetAllocationType(iThirdId in number)
    return integer
  is
    lvAllocationType PAC_CUSTOM_PARTNER.C_RESERVATION_TYP%type;
  begin
    select C_RESERVATION_TYP
      into lvAllocationType
      from PAC_CUSTOM_PARTNER
     where PAC_CUSTOM_PARTNER_ID = iThirdId;

    return to_number(nvl(lvAllocationType, PCS.PC_CONFIG.GetConfig('DOC_TYPE_AUTO_LINK') ) );
  exception
    when no_data_found then
      return to_number(PCS.PC_CONFIG.GetConfig('DOC_TYPE_AUTO_LINK') );
  end GetAllocationType;

  function GetGAS_AUTO_ATTRIBUTION(aDocPositionDetailId number)
    return integer
  is
    ValGAS_AUTO_ATTRIBUTION integer;
  begin
    select GAS_AUTO_ATTRIBUTION
      into ValGAS_AUTO_ATTRIBUTION
      from DOC_GAUGE_STRUCTURED
     where DOC_GAUGE_ID = (select DOC_GAUGE_ID
                             from DOC_POSITION_DETAIL
                            where DOC_POSITION_DETAIL_ID = aDocPositionDetailId);

    return ValGAS_AUTO_ATTRIBUTION;
  exception
    when no_data_found then
      return null;
  end GetGAS_AUTO_ATTRIBUTION;

  -- Initialisation du décalage du produit
  function GetDecalageProduct(PrmGCO_GOOD_ID GCO_GOOD.GCO_GOOD_ID%type)
    return GCO_COMPL_DATA_MANUFACTURE.CMA_SHIFT%type
  is
    result         GCO_COMPL_DATA_MANUFACTURE.CMA_SHIFT%type;
    aC_SUPPLY_MODE GCO_PRODUCT.C_SUPPLY_MODE%type;
  begin
    result  := null;

    -- Déterminer le Mode d'approvisionnement
    select C_SUPPLY_MODE
      into aC_SUPPLY_MODE
      from GCO_PRODUCT
     where GCO_GOOD_ID = PrmGCO_GOOD_ID;

    -- Produit fabriqué
    if aC_SUPPLY_MODE = '2' then
      begin
        select CMA_SHIFT
          into result
          from GCO_COMPL_DATA_MANUFACTURE
         where CMA_DEFAULT = 1
           and GCO_GOOD_ID = PrmGCO_GOOD_ID;
      exception
        when no_data_found then
          result  := null;
        when too_many_rows then
          raise_application_error(-20001
                                , 'The Product "' ||
                                  Fal_tools.getGOO_MAJOR_REFERENCE(PrmGCO_GOOD_ID) ||
                                  '" have too many defaults manufacturing definitions!. You must correct this directly on product definition.'
                                 );
      end;
    end if;

    -- Produit acheté
    if aC_SUPPLY_MODE = '1' then
      begin
        select CPU_SHIFT
          into result
          from GCO_COMPL_DATA_PURCHASE
         where CPU_DEFAULT_SUPPLIER = 1
           and GCO_GOOD_ID = PrmGCO_GOOD_ID;
      exception
        when no_data_found then
          result  := null;
        when too_many_rows then
          raise_application_error(-20001
                                , 'The Product "' ||
                                  Fal_tools.getGOO_MAJOR_REFERENCE(PrmGCO_GOOD_ID) ||
                                  '" have too many defaults sale definitions!. You must correct this directly on product definition.'
                                 );
      end;
    end if;

    -- Produit sous-traité
    if aC_SUPPLY_MODE = '3' then
      begin
        select CSU_SHIFT
          into result
          from GCO_COMPL_DATA_SUBCONTRACT
         where CSU_DEFAULT_SUBCONTRACTER = 1
           and GCO_GOOD_ID = PrmGCO_GOOD_ID;
      exception
        when no_data_found then
          result  := null;
        when too_many_rows then
          raise_application_error(-20001
                                , 'The Product "' ||
                                  Fal_tools.getGOO_MAJOR_REFERENCE(PrmGCO_GOOD_ID) ||
                                  '" have too many defaults sub-contracting definitions!. You must correct this directly on product definition.'
                                 );
      end;
    end if;

    return nvl(result, 0);
  end GetDecalageProduct;

  -- Retourne VRAI si le produit peux donner lieu à des attributions éventuelles pour le produit
  --          FAUX dans tous les autres cas.
  function GetPDT_STOCK_ALLOC_BATCH(PrmGCO_GOOD_ID GCO_GOOD.GCO_GOOD_ID%type)
    return boolean
  is
    aPDT_STOCK_ALLOC_BATCH GCO_PRODUCT.PDT_STOCK_ALLOC_BATCH%type;
  begin
    select PDT_STOCK_ALLOC_BATCH
      into aPDT_STOCK_ALLOC_BATCH
      from GCO_PRODUCT
     where GCO_GOOD_ID = PrmGCO_GOOD_ID;

    return aPDT_STOCK_ALLOC_BATCH = 1;
  exception
    when no_data_found then
      return false;
  end GetPDT_STOCK_ALLOC_BATCH;

  function GetSumApproSurStock(
    ai1v1                            varchar2
  , ai2v2                            varchar2
  , ai3v3                            varchar2
  , ai4v4                            varchar2
  , ai5v5                            varchar2
  , PrmGCO_GOOD_ID                   GCO_GOOD.GCO_GOOD_ID%type
  , PrmLstStock                      varchar
  , LstControleStocksIDs             varchar
  , PdtHasVersionOrCharacteristic    boolean
  , ibFEFO                        in boolean
  )
    return FAL_NETWORK_SUPPLY.FAN_STK_QTY%type
  is
    BuffSql             varchar2(32000);
    Ignore              integer;
    CurSumApproSurStock integer;
    Somme               FAL_NETWORK_SUPPLY.FAN_STK_QTY%type;
  begin
    buffSql              := ' SELECT SUM(FAN_STK_QTY)';
    buffSql              := BuffSql || ' FROM FAL_NETWORK_SUPPLY WHERE nvl(FAN_STK_QTY,0) > 0 AND GCO_GOOD_ID = ' || PrmGCO_GOOD_iD;

    -- Sur les stocks sélecionnés + éventuellement ceux issus de la PPS_STOCK_CTRL
    if LstControleStocksIDs is not null then
      BuffSql  := BuffSql || '    AND STM_STOCK_ID in (' || PrmLstStock || ',' || LstControleStocksIDs || ')';
    else
      BuffSql  := BuffSql || '    AND STM_STOCK_ID in (' || PrmLstStock || ')';
    end if;

    if PdtHasVersionOrCharacteristic then
      -- Tenir compte des caractérisations si pdt avec caractérisations de type version ou caractéristique
      BuffSql  := BuffSql || 'and';
      BuffSql  := BuffSql || '(';
      BuffSql  := BuffSql || ' (';
      BuffSql  := BuffSql || '  (TO_NUMBER(PCS.PC_CONFIG.GetConfig(''FAL_ATTRIB_ON_CHARACT_MODE'')) = 1)';
      BuffSql  := BuffSql || '  and';
      BuffSql  := BuffSql || '  (';
      BuffSql  := BuffSql || '      (';
      BuffSql  := BuffSql || '	     :Ai1v1 || :Ai2v2 || :Ai3v3 || :Ai4v4 || :Ai5v5 is not null';
      BuffSql  := BuffSql || '	     and';
      BuffSql  :=
        BuffSql ||
        '   	 ((:Ai1v1 in (   concat(GCO_CHARACTERIZATION1_ID,FAN_CHAR_VALUE1),concat(GCO_CHARACTERIZATION2_ID,FAN_CHAR_VALUE2),concat(GCO_CHARACTERIZATION3_ID,FAN_CHAR_VALUE3),concat(GCO_CHARACTERIZATION4_ID,FAN_CHAR_VALUE4),concat(GCO_CHARACTERIZATION5_ID,FAN_CHAR_VALUE5)     )) or (:Ai1v1 is null ))';
      BuffSql  := BuffSql || '	     and';
      BuffSql  :=
        BuffSql ||
        '	     ((:Ai2v2 in (   concat(GCO_CHARACTERIZATION1_ID,FAN_CHAR_VALUE1),concat(GCO_CHARACTERIZATION2_ID,FAN_CHAR_VALUE2),concat(GCO_CHARACTERIZATION3_ID,FAN_CHAR_VALUE3),concat(GCO_CHARACTERIZATION4_ID,FAN_CHAR_VALUE4),concat(GCO_CHARACTERIZATION5_ID,FAN_CHAR_VALUE5)     )) or (:Ai2v2 is null ))';
      BuffSql  := BuffSql || '	     and';
      BuffSql  :=
        BuffSql ||
        '	     ((:Ai3v3 in (   concat(GCO_CHARACTERIZATION1_ID,FAN_CHAR_VALUE1),concat(GCO_CHARACTERIZATION2_ID,FAN_CHAR_VALUE2),concat(GCO_CHARACTERIZATION3_ID,FAN_CHAR_VALUE3),concat(GCO_CHARACTERIZATION4_ID,FAN_CHAR_VALUE4),concat(GCO_CHARACTERIZATION5_ID,FAN_CHAR_VALUE5)     )) or (:Ai3v3 is null ))';
      BuffSql  := BuffSql || '	     and';
      BuffSql  :=
        BuffSql ||
        '	     ((:Ai4v4 in (   concat(GCO_CHARACTERIZATION1_ID,FAN_CHAR_VALUE1),concat(GCO_CHARACTERIZATION2_ID,FAN_CHAR_VALUE2),concat(GCO_CHARACTERIZATION3_ID,FAN_CHAR_VALUE3),concat(GCO_CHARACTERIZATION4_ID,FAN_CHAR_VALUE4),concat(GCO_CHARACTERIZATION5_ID,FAN_CHAR_VALUE5)     )) or (:Ai4v4 is null ))';
      BuffSql  := BuffSql || '	     and';
      BuffSql  :=
        BuffSql ||
        '	     ((:Ai5v5 in (   concat(GCO_CHARACTERIZATION1_ID,FAN_CHAR_VALUE1),concat(GCO_CHARACTERIZATION2_ID,FAN_CHAR_VALUE2),concat(GCO_CHARACTERIZATION3_ID,FAN_CHAR_VALUE3),concat(GCO_CHARACTERIZATION4_ID,FAN_CHAR_VALUE4),concat(GCO_CHARACTERIZATION5_ID,FAN_CHAR_VALUE5)     )) or (:Ai5v5 is null ))';
      BuffSql  := BuffSql || '	     )';
      BuffSql  := BuffSql || '	     or';
      BuffSql  := BuffSql || '	     (';
      BuffSql  := BuffSql || '	       :Ai1v1 || :Ai2v2 || :Ai3v3 || :Ai4v4 || :Ai5v5 is null';
      BuffSql  := BuffSql || '	       and fal_tools.NullForNoMorpho(GCO_CHARACTERIZATION1_ID  ,FAN_CHAR_VALUE1)';
      BuffSql  := BuffSql || '	           ||';
      BuffSql  := BuffSql || '		       fal_tools.NullForNoMorpho(GCO_CHARACTERIZATION2_ID  ,FAN_CHAR_VALUE2)';
      BuffSql  := BuffSql || '	           ||';
      BuffSql  := BuffSql || '	           fal_tools.NullForNoMorpho(GCO_CHARACTERIZATION3_ID  ,FAN_CHAR_VALUE3)';
      BuffSql  := BuffSql || '	           ||';
      BuffSql  := BuffSql || '		       fal_tools.NullForNoMorpho(GCO_CHARACTERIZATION4_ID  ,FAN_CHAR_VALUE4)';
      BuffSql  := BuffSql || '	           ||';
      BuffSql  := BuffSql || '		       fal_tools.NullForNoMorpho(GCO_CHARACTERIZATION5_ID,  FAN_CHAR_VALUE5) is null';
      BuffSql  := BuffSql || '	     )';
      BuffSql  := BuffSql || '  )';
      BuffSql  := BuffSql || ')';
      BuffSql  := BuffSql || 'OR';
      BuffSql  := BuffSql || '(';
      BuffSql  := BuffSql || '  (TO_NUMBER(PCS.PC_CONFIG.GetConfig(''FAL_ATTRIB_ON_CHARACT_MODE'')) <> 1)';
      BuffSql  := BuffSql || '  and';
      BuffSql  := BuffSql || '  (';
      BuffSql  := BuffSql || '      (';
      BuffSql  :=
        BuffSql ||
        '      ((:Ai1v1 in (   concat(GCO_CHARACTERIZATION1_ID,FAN_CHAR_VALUE1),concat(GCO_CHARACTERIZATION2_ID,FAN_CHAR_VALUE2),concat(GCO_CHARACTERIZATION3_ID,FAN_CHAR_VALUE3),concat(GCO_CHARACTERIZATION4_ID,FAN_CHAR_VALUE4),concat(GCO_CHARACTERIZATION5_ID,FAN_CHAR_VALUE5)     )) or (:Ai1v1 is null ))';
      BuffSql  := BuffSql || '      and';
      BuffSql  :=
        BuffSql ||
        '      ((:Ai2v2 in (   concat(GCO_CHARACTERIZATION1_ID,FAN_CHAR_VALUE1),concat(GCO_CHARACTERIZATION2_ID,FAN_CHAR_VALUE2),concat(GCO_CHARACTERIZATION3_ID,FAN_CHAR_VALUE3),concat(GCO_CHARACTERIZATION4_ID,FAN_CHAR_VALUE4),concat(GCO_CHARACTERIZATION5_ID,FAN_CHAR_VALUE5)     )) or (:Ai2v2 is null ))';
      BuffSql  := BuffSql || '      and';
      BuffSql  :=
        BuffSql ||
        '      ((:Ai3v3 in (   concat(GCO_CHARACTERIZATION1_ID,FAN_CHAR_VALUE1),concat(GCO_CHARACTERIZATION2_ID,FAN_CHAR_VALUE2),concat(GCO_CHARACTERIZATION3_ID,FAN_CHAR_VALUE3),concat(GCO_CHARACTERIZATION4_ID,FAN_CHAR_VALUE4),concat(GCO_CHARACTERIZATION5_ID,FAN_CHAR_VALUE5)     )) or (:Ai3v3 is null ))';
      BuffSql  := BuffSql || '      and';
      BuffSql  :=
        BuffSql ||
        '      ((:Ai4v4 in (   concat(GCO_CHARACTERIZATION1_ID,FAN_CHAR_VALUE1),concat(GCO_CHARACTERIZATION2_ID,FAN_CHAR_VALUE2),concat(GCO_CHARACTERIZATION3_ID,FAN_CHAR_VALUE3),concat(GCO_CHARACTERIZATION4_ID,FAN_CHAR_VALUE4),concat(GCO_CHARACTERIZATION5_ID,FAN_CHAR_VALUE5)     )) or (:Ai4v4 is null ))';
      BuffSql  := BuffSql || '      and';
      BuffSql  :=
        BuffSql ||
        '      ((:Ai5v5 in (   concat(GCO_CHARACTERIZATION1_ID,FAN_CHAR_VALUE1),concat(GCO_CHARACTERIZATION2_ID,FAN_CHAR_VALUE2),concat(GCO_CHARACTERIZATION3_ID,FAN_CHAR_VALUE3),concat(GCO_CHARACTERIZATION4_ID,FAN_CHAR_VALUE4),concat(GCO_CHARACTERIZATION5_ID,FAN_CHAR_VALUE5)     )) or (:Ai5v5 is null ))';
      BuffSql  := BuffSql || '      )';
      BuffSql  := BuffSql || '      or';
      BuffSql  := BuffSql || '      (';
      BuffSql  := BuffSql || '             fal_tools.NullForNoMorpho(GCO_CHARACTERIZATION1_ID  ,FAN_CHAR_VALUE1)';
      BuffSql  := BuffSql || '      	    ||';
      BuffSql  := BuffSql || '      		fal_tools.NullForNoMorpho(GCO_CHARACTERIZATION2_ID  ,FAN_CHAR_VALUE2)';
      BuffSql  := BuffSql || '      	    ||';
      BuffSql  := BuffSql || '      	    fal_tools.NullForNoMorpho(GCO_CHARACTERIZATION3_ID  ,FAN_CHAR_VALUE3)';
      BuffSql  := BuffSql || '      	    ||';
      BuffSql  := BuffSql || '      		fal_tools.NullForNoMorpho(GCO_CHARACTERIZATION4_ID  ,FAN_CHAR_VALUE4)';
      BuffSql  := BuffSql || '      	    ||';
      BuffSql  := BuffSql || '      		fal_tools.NullForNoMorpho(GCO_CHARACTERIZATION5_ID,  FAN_CHAR_VALUE5) is null';
      BuffSql  := BuffSql || '      )';
      BuffSql  := BuffSql || '  )';
      BuffSql  := BuffSql || ' )';
      BuffSql  := BuffSql || ')';
    end if;   -- Fin de if PdtHasVersionOrCharacteristic then

    if ibFEFO then
      -- TODO FDA stock mini
      null;
    end if;

    CurSumApproSurStock  := DBMS_SQL.open_cursor;
    DBMS_SQL.Parse(CurSumApproSurStock, BuffSql, DBMS_SQL.NATIVE);
    DBMS_SQL.Define_column(CurSumApproSurStock, 1, Somme);

    if PdtHasVersionOrCharacteristic then
      DBMS_SQL.BIND_VARIABLE(CurSumApproSurStock, 'Ai1v1', Ai1v1);
      DBMS_SQL.BIND_VARIABLE(CurSumApproSurStock, 'Ai2v2', Ai2v2);
      DBMS_SQL.BIND_VARIABLE(CurSumApproSurStock, 'Ai3v3', Ai3v3);
      DBMS_SQL.BIND_VARIABLE(CurSumApproSurStock, 'Ai4v4', Ai4v4);
      DBMS_SQL.BIND_VARIABLE(CurSumApproSurStock, 'Ai5v5', Ai5v5);
    end if;

    Ignore               := DBMS_SQL.execute(CurSumApproSurStock);
    Somme                := null;

    if DBMS_SQL.fetch_rows(CurSumApproSurStock) > 0 then
      DBMS_SQL.column_value(CurSumApproSurStock, 1, Somme);
    end if;

    DBMS_SQL.close_cursor(CurSumApproSurStock);
    return Somme;
  end GetSumApproSurStock;

  -- Récupère la somme des quantités stock mini pour un produit sur un ensemble de stocks donné.
  function GetSumCST_QUANTITY_MIN(PrmGOOD_ID GCo_GOOD.GCO_GOOD_ID%type, PrmLstStock varchar2, PrmLstControleStocks varchar)
    return number
  is
    CurSum    GCO_COMPL_DATA_STOCK.CST_QUANTITY_MIN%type;
    BuffSql   varchar2(4000);
    CursorSum integer;
    Ignore    integer;
  begin
    BuffSql    := 'SELECT SUM(CST_QUANTITY_MIN) from GCO_COMPL_DATA_STOCK WHERE ';
    Buffsql    := BuffSql || ' GCO_GOOD_ID = ' || PrmGOOD_ID;

    -- Tenir compte des stocks de controle
    if PrmLstControleStocks is not null then
      BuffSql  := BuffSql || ' AND STM_STOCK_ID in (' || PrmLstStock || ',' || PrmLstControleStocks || ')';
    else
      BuffSql  := BuffSql || ' AND STM_STOCK_ID in (' || PrmLstStock || ')';
    end if;

    CursorSum  := DBMS_SQL.open_cursor;
    DBMS_SQL.Parse(CursorSum, BuffSql, DBMS_SQL.NATIVE);
    DBMS_SQL.Define_column(CursorSum, 1, CurSUM);
    Ignore     := DBMS_SQL.execute(CursorSum);
    CurSUM     := null;

    if DBMS_SQL.fetch_rows(CursorSum) > 0 then
      DBMS_SQL.column_value(CursorSum, 1, CurSUM);
    end if;

    DBMS_SQL.close_cursor(CursorSum);
    return nvl(CurSUM, 0);
  end GetSumCST_QUANTITY_MIN;

  /**
  * procedure : SuppAttribSurNeedOnSupplies
  * Description : Supprime toutes les attribs sur appro d'un besoin
  *
  * @created
  * @lastUpdate
  * @public
  * @param   PrmFAL_NETWORK_NEED_ID  :  Besoin
  */
  procedure SuppAttribSurNeedOnSupplies(PrmFAL_NETWORK_NEED_ID fal_network_need.FAL_NETWORK_NEED_ID%type)
  is
    cursor CAttrib
    is
      select     a.FAL_NETWORK_LINK_ID
               , a.FAL_NETWORK_NEED_ID
               , a.FAL_NETWORK_SUPPLY_ID
               , a.FLN_QTY
            from FAL_NETWORK_LINK a
           where
                 -- Pour le besoin identifié
                 a.FAL_NETWORK_NEED_ID = PrmFAL_NETWORK_NEED_ID
             and
                 -- Et qui porte sur des appro
                 a.FAL_NETWORK_SUPPLY_ID is not null
      for update;

    EAttrib CAttrib%rowtype;
  begin
    open CAttrib;

    loop
      fetch CAttrib
       into EAttrib;

      exit when CAttrib%notfound;
      -- Supprimer l'attribution
      SuppressionAttribution(EAttrib.FAL_NETWORK_LINK_ID, EAttrib.FAL_NETWORK_NEED_ID, EAttrib.FAL_NETWORK_SUPPLY_ID, null, null, EAttrib.FLN_QTY);
    end loop;

    close CAttrib;
  end SuppAttribSurNeedOnSupplies;

  /**
  * procedure : SuppAttribSurNeedFab
  * Description : Supprimer toutes les attributions de besoins fabrication
  *
  * @created
  * @lastUpdate
  * @public
  * @param   PrmGCO_GOOD_ID  :  Bien
  * @param   PrmLstStock : Liste des stocks sélectionnés
  */
  procedure SuppAttribSurNeedFab(PrmGCO_GOOD_ID number, PrmlstStock varchar2)
  is
    BuffSql                  varchar2(2000);
    Ignore                   integer;
    CursorAttrib             integer;
    CurrentLINK_ID           number;
    CurrentNEED_ID           number;
    CurrentSUPPLY_ID         number;
    CurrentSTOCK_POSITION_ID number;
    CurrentSTM_LOCATION_ID   number;
    CurrentFLN_QTY           FAl_NETWORK_LINK.FLN_QTY%type;
  begin
    BuffSql       := ' SELECT';
    buffSql       := BuffSql || '  a.FAL_NETWORK_LINK_ID,';
    buffSql       := BuffSql || '  a.FAL_NETWORK_NEED_ID,';
    buffSql       := BuffSql || '  a.FAL_NETWORK_SUPPLY_ID,';
    buffSql       := BuffSql || '  a.STM_STOCk_POSITION_ID,';
    buffSql       := BuffSql || '  a.STM_LOCATION_ID,';
    buffSql       := BuffSql || '  a.FLN_QTY';
    buffSql       := BuffSql || ' FROM';
    buffSql       := BuffSql || '  FAL_NETWORK_LINK a, FAL_NETWORK_NEED b';
    buffSql       := BuffSql || '  WHERE b.GCO_GOOD_ID = ' || PrmGCO_GOOD_ID;
    buffSql       := BuffSql || '  AND a.FAL_NETWORK_NEED_ID = b.FAL_NETWORK_NEED_ID';
    buffSql       := BuffSql || '  AND STM_STOCK_POSITION_ID IS NOT NULL';
    buffSql       := BuffSql || '  AND';
    buffSql       := BuffSql || '  (';
    buffSql       := BuffSql || '    b.FAL_LOT_MATERIAL_LINK_ID IS NOT NULL OR FAL_LOT_MAT_LINK_PROP_ID IS NOT NULL';
    buffSql       := BuffSql || '  )';
    -- On ne supprime pas les attributions en cours de traitement dans les sortie de composants
    BuffSql       := BuffSql || '   and a.fal_network_link_id not in (select fcl.fal_network_link_id ';
    BuffSql       := BuffSql || '                                       from fal_component_link fcl ';
    BuffSql       := BuffSql || '                                      where fcl.fal_network_link_id = a.fal_network_link_id) ';

    if PrmLstStock is not null then
      buffSql  := BuffSql || ' and b.STM_STOCK_ID IN (' || PrmLstStock || ')';
    end if;

    buffSql       := BuffSql || '  FOR UPDATE';
    CursorAttrib  := DBMS_SQL.open_cursor;
    DBMS_SQL.Parse(CursorAttrib, BuffSql, DBMS_SQL.NATIVE);
    DBMS_SQL.Define_column(CursorAttrib, 1, CurrentLINK_ID);
    DBMS_SQL.Define_column(CursorAttrib, 2, CurrentNEED_ID);
    DBMS_SQL.Define_column(CursorAttrib, 3, CurrentSUPPLY_ID);
    DBMS_SQL.Define_column(CursorAttrib, 4, CurrentSTOCK_POSITION_ID);
    DBMS_SQL.Define_column(CursorAttrib, 5, CurrentSTM_LOCATION_ID);
    DBMS_SQL.Define_column(CursorAttrib, 6, CurrentFLN_QTY);
    Ignore        := DBMS_SQL.execute(CursorAttrib);

    while DBMS_SQL.fetch_rows(CursorAttrib) > 0 loop
      DBMS_SQL.column_value(CursorAttrib, 1, CurrentLINK_ID);
      DBMS_SQL.column_value(CursorAttrib, 2, CurrentNEED_ID);
      DBMS_SQL.column_value(CursorAttrib, 3, CurrentSUPPLY_ID);
      DBMS_SQL.column_value(CursorAttrib, 4, CurrentSTOCK_POSITION_ID);
      DBMS_SQL.column_value(CursorAttrib, 5, CurrentSTM_LOCATION_ID);
      DBMS_SQL.column_value(CursorAttrib, 6, CurrentFLN_QTY);
      SuppressionAttribution(CurrentLINK_ID, CurrentNEED_ID, CurrentSUPPLY_ID, CurrentSTOCK_POSITION_ID, CurrentSTM_LOCATION_ID, CurrentFLN_QTY);
    end loop;

    DBMS_SQL.close_cursor(CursorAttrib);
-- Fin itération sur les attributions d'un besoin du produit pour les stocks sélectionnés
  end SuppAttribSurNeedFab;

-----------------------------------------------
-- Routines de gestion de la table FAL_SUM_STOCK
-- 1) création de la table temporaire
-- 2) Recherche d'un élément dans la table temporaire
-- 3) Mise à jour d'un élément dans la table temporaire
-----------------------------------------------

  -- 1) création de la table temporaire
  procedure CreateFAL_SUM_STOCK(
    PrmGOOD_ID                    GCO_GOOD.GCO_GOOD_ID%type
  , PrmLstStock                   varchar
  , PdtHasVersionOrCharacteristic boolean
  , PrmCompensationStockControle  number
  , prmLstControleStocksIDs       varchar2
  , iTimeLimitManagement          boolean
  )
  is
    lvSQL                       varchar2(32000);
    CursorFAL_SUM_STOCK         integer;
    Ignore                      integer;
    CurGCO_CHARACTERIZATION1_ID FAl_NETWORK_NEED.GCO_CHARACTERIZATION1_ID%type;
    CurGCO_CHARACTERIZATION2_ID FAl_NETWORK_NEED.GCO_CHARACTERIZATION2_ID%type;
    CurGCO_CHARACTERIZATION3_ID FAl_NETWORK_NEED.GCO_CHARACTERIZATION3_ID%type;
    CurGCO_CHARACTERIZATION4_ID FAl_NETWORK_NEED.GCO_CHARACTERIZATION4_ID%type;
    CurGCO_CHARACTERIZATION5_ID FAl_NETWORK_NEED.GCO_CHARACTERIZATION5_ID%type;
    CurSomme                    STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type;
    CurVALUE1                   FAl_NETWORK_NEED.FAN_CHAR_VALUE1%type;
    CurVALUE2                   FAl_NETWORK_NEED.FAN_CHAR_VALUE2%type;
    CurVALUE3                   FAl_NETWORK_NEED.FAN_CHAR_VALUE3%type;
    CurVALUE4                   FAl_NETWORK_NEED.FAN_CHAR_VALUE4%type;
    CurVALUE5                   FAl_NETWORK_NEED.FAN_CHAR_VALUE5%type;
    XSumCST_QUANTITY_MIN        GCO_COMPL_DATA_STOCK.CST_QUANTITY_MIN%type;
    XSomme                      STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type;
    X                           STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type;
    SAS                         FAL_NETWORK_SUPPLY.FAN_STK_QTY%type;
    LstControleStocksIDs        varchar2(4000);
    lnNextColumn                number(2);
    ldFEFO                      STM_ELEMENT_NUMBER.SEM_RETEST_DATE%type;
    lbFEFO                      boolean                                          := false;
  begin
    -- Tenir compte des stocks de controle
    delete      FAL_SUM_STOCK;

    -- 10 --
    lvSQL                := 'select sum(nvl(SPO_AVAILABLE_QUANTITY, 0) + nvl(SPO_PROVISORY_INPUT, 0))';

    if PdtHasVersionOrCharacteristic then
      -- Seulement si le produit a des caractérisations morphologique (de types versions ou caractérisque)
      lvSQL  := lvSQL || ' , SPO.GCO_CHARACTERIZATION_ID';
      lvSQL  := lvSQL || ' , SPO.GCO_GCO_CHARACTERIZATION_ID';
      lvSQL  := lvSQL || ' , SPO.GCO2_GCO_CHARACTERIZATION_ID';
      lvSQL  := lvSQL || ' , SPO.GCO3_GCO_CHARACTERIZATION_ID';
      lvSQL  := lvSQL || ' , SPO.GCO4_GCO_CHARACTERIZATION_ID';
      lvSQL  := lvSQL || ' , fal_tools.NullForNoMorpho(SPO.GCO_CHARACTERIZATION_ID     , SPO.SPO_CHARACTERIZATION_VALUE_1) as Value1';
      lvSQL  := lvSQL || ' , fal_tools.NullForNoMorpho(SPO.GCO_GCO_CHARACTERIZATION_ID , SPO.SPO_CHARACTERIZATION_VALUE_2) as Value2';
      lvSQL  := lvSQL || ' , fal_tools.NullForNoMorpho(SPO.GCO2_GCO_CHARACTERIZATION_ID, SPO.SPO_CHARACTERIZATION_VALUE_3) as Value3';
      lvSQL  := lvSQL || ' , fal_tools.NullForNoMorpho(SPO.GCO3_GCO_CHARACTERIZATION_ID, SPO.SPO_CHARACTERIZATION_VALUE_4) as Value4';
      lvSQL  := lvSQL || ' , fal_tools.NullForNoMorpho(SPO.GCO4_GCO_CHARACTERIZATION_ID, SPO.SPO_CHARACTERIZATION_VALUE_5) as Value5';
    end if;

    -- Traitement du FEFO (First Expried First Out) si re-analyse et/ou péremption
    -- Prépare le remplissage du champ date limite d'utilisation (FSS_FEFO_DATE) avec la plus petite date entre les deux
    if    iTimeLimitManagement
       or (PCS.PC_CONFIG.GetConfig('GCO_RETEST_PREV_MODE') = '0') then
      lbFEFO  := true;

      if iTimeLimitManagement then
        lvSQL  :=
          lvSQL ||
          ' , least(nvl(trunc(GCO_I_LIB_CHARACTERIZATION.ChronoFormatToDate(SPO.SPO_CHRONOLOGICAL                                           ' ||
          '                                                               , GCO_I_LIB_CHARACTERIZATION.GetChronoCharID(SPO.GCO_GOOD_ID) ) ) ' ||
          '           , to_date(''29991231'', ''YYYYMMDD''))                                                                                ' ||
          '       , nvl(SEM.SEM_RETEST_DATE, to_date(''29991231'', ''YYYYMMDD''))) as SPO_FEFO_DATE                                         ';
      else
        lvSQL  := lvSQL || '     , nvl(SEM.SEM_RETEST_DATE, to_date(''29991231'', ''YYYYMMDD'')) SPO_FEFO_DATE';
      end if;
    end if;

    lvSQL                := lvSQL || '  from STM_STOCK_POSITION SPO';
    lvSQL                := lvSQL || '     , STM_ELEMENT_NUMBER SEM';
    -- Pour le produit
    lvSQL                := lvSQL || ' where SPO.GCO_GOOD_ID = ' || PrmGOOD_ID;
    lvSQL                := lvSQL || ' and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = SEM.STM_ELEMENT_NUMBER_ID(+) ';

    if PrmCompensationStockControle = 1 then
      LstControleStocksIDs  := prmLstControleStocksIDs;
    end if;

    -- Sur les stocks sélecionnés + éventuellement ceux issus de la PPS_STOCK_CTRL
    if LstControleStocksIDs is not null then
      lvSQL  := lvSQL || '    and SPO.STM_STOCK_ID in (' || PrmLstStock || ',' || LstControleStocksIDs || ')';
    else
      lvSQL  := lvSQL || '    and SPO.STM_STOCK_ID in (' || PrmLstStock || ')';
    end if;

    -- 0901
    if iTimeLimitManagement then
      lvSQL  := lvSQL || '    and ( GCO_I_LIB_CHARACTERIZATION.IsOutdated(iGoodID          => SPO.GCO_GOOD_ID';
      lvSQL  := lvSQL || '                                              , iThirdId         => null';
      lvSQL  := lvSQL || '                                              , iTimeLimitDate   => SPO.SPO_CHRONOLOGICAL';
      lvSQL  := lvSQL || '                                              , iDate            => sysdate';
      lvSQL  := lvSQL || '                                               ) = 0';
      lvSQL  := lvSQL || '        )';
    end if;

    -- Propose que les positions de stock avec statut qualité disponible pour le prévisionnel et les attributions ou sans gestion du statut qualité
    if STM_I_LIB_CONSTANT.gcCfgUseQualityStatus then
      lvSQL  := lvSQL || '    and ( GCO_I_LIB_QUALITY_STATUS.IsNetworkLinkManagement(iQualityStatusId => SEM.GCO_QUALITY_STATUS_ID) = 1 )';
    end if;

    -- Propose que les positions de stock qui n'ont pas dépassé la date de ré-analyse mais seulement si elles ne sont pas considérées
    -- comme disponible pour les traitements prévisionnels. La date de référence est la date du jour.
    if (PCS.PC_CONFIG.GetConfig('GCO_RETEST_PREV_MODE') = '0') then
      lvSQL  := lvSQL || '    and ( STM_I_LIB_STOCK_POSITION.IsRetestNeeded(iStockPositionId => SPO.STM_STOCK_POSITION_ID, iDate => sysdate) = 0) ';
    end if;

    -- Fin de 0901
    if PdtHasVersionOrCharacteristic then
        -- Créer le regroupement
      -- Seulement si le produit a des caractérisations morphologique (de types versions ou caractérisque)
      lvSQL  := lvSQL || ' group by SPO.GCO_CHARACTERIZATION_ID';
      lvSQL  := lvSQL || '        , SPO.GCO_GCO_CHARACTERIZATION_ID';
      lvSQL  := lvSQL || '        , SPO.GCO2_GCO_CHARACTERIZATION_ID';
      lvSQL  := lvSQL || '        , SPO.GCO3_GCO_CHARACTERIZATION_ID';
      lvSQL  := lvSQL || '        , SPO.GCO4_GCO_CHARACTERIZATION_ID';
      lvSQL  := lvSQL || '        , fal_tools.NullForNoMorpho(SPO.GCO_CHARACTERIZATION_ID     , SPO.SPO_CHARACTERIZATION_VALUE_1)';
      lvSQL  := lvSQL || '        , fal_tools.NullForNoMorpho(SPO.GCO_GCO_CHARACTERIZATION_ID , SPO.SPO_CHARACTERIZATION_VALUE_2)';
      lvSQL  := lvSQL || '        , fal_tools.NullForNoMorpho(SPO.GCO2_GCO_CHARACTERIZATION_ID, SPO.SPO_CHARACTERIZATION_VALUE_3)';
      lvSQL  := lvSQL || '        , fal_tools.NullForNoMorpho(SPO.GCO3_GCO_CHARACTERIZATION_ID, SPO.SPO_CHARACTERIZATION_VALUE_4)';
      lvSQL  := lvSQL || '        , fal_tools.NullForNoMorpho(SPO.GCO4_GCO_CHARACTERIZATION_ID, SPO.SPO_CHARACTERIZATION_VALUE_5)';
    end if;

    -- Traitement du FEFO (First Expried First Out) si re-analyse et/ou péremption
    if lbFEFO then
      if PdtHasVersionOrCharacteristic then
        lvSQL  := lvSQL || '      , ';
      else
        lvSQL  := lvSQL || ' group by ';
      end if;

      if iTimeLimitManagement then
        lvSQL  :=
          lvSQL ||
          '  least(nvl(trunc(GCO_I_LIB_CHARACTERIZATION.ChronoFormatToDate(SPO.SPO_CHRONOLOGICAL                                            ' ||
          '                                                               , GCO_I_LIB_CHARACTERIZATION.GetChronoCharID(SPO.GCO_GOOD_ID) ) ) ' ||
          '           , to_date(''29991231'', ''YYYYMMDD''))                                                                                ' ||
          '       , nvl(SEM.SEM_RETEST_DATE, to_date(''29991231'', ''YYYYMMDD'')))                                                          ';
      else
        lvSQL  := lvSQL || '       nvl(SEM.SEM_RETEST_DATE, to_date(''29991231'', ''YYYYMMDD''))';
      end if;

      if iTimeLimitManagement then
        lvSQL  :=
          lvSQL ||
          ' order by least(nvl(trunc(GCO_I_LIB_CHARACTERIZATION.ChronoFormatToDate(SPO.SPO_CHRONOLOGICAL                                    ' ||
          '                                                               , GCO_I_LIB_CHARACTERIZATION.GetChronoCharID(SPO.GCO_GOOD_ID) ) ) ' ||
          '           , to_date(''29991231'', ''YYYYMMDD''))                                                                                ' ||
          '       , nvl(SEM.SEM_RETEST_DATE, to_date(''29991231'', ''YYYYMMDD''))) desc                                                     ';
      else
        lvSQL  := lvSQL || 'order by nvl(SEM.SEM_RETEST_DATE, to_date(''29991231'', ''YYYYMMDD'')) desc';
      end if;
    end if;

    CursorFAL_SUM_STOCK  := DBMS_SQL.open_cursor;
    DBMS_SQL.Parse(CursorFAL_SUM_STOCK, lvSQL, DBMS_SQL.NATIVE);
    DBMS_SQL.Define_column(CursorFAL_SUM_STOCK, 1, CurSomme);

    if PdtHasVersionOrCharacteristic then
      -- Seulement si le produit a des caractérisations morphologique (de types versions ou caractérisque)
      DBMS_SQL.Define_column(CursorFAL_SUM_STOCK, 2, CurGCO_CHARACTERIZATION1_ID);
      DBMS_SQL.Define_column(CursorFAL_SUM_STOCK, 3, CurGCO_CHARACTERIZATION2_ID);
      DBMS_SQL.Define_column(CursorFAL_SUM_STOCK, 4, CurGCO_CHARACTERIZATION3_ID);
      DBMS_SQL.Define_column(CursorFAL_SUM_STOCK, 5, CurGCO_CHARACTERIZATION4_ID);
      DBMS_SQL.Define_column(CursorFAL_SUM_STOCK, 6, CurGCO_CHARACTERIZATION5_ID);
      DBMS_SQL.Define_column(CursorFAL_SUM_STOCK, 7, CurVALUE1, 30);
      DBMS_SQL.Define_column(CursorFAL_SUM_STOCK, 8, CurVALUE2, 30);
      DBMS_SQL.Define_column(CursorFAL_SUM_STOCK, 9, CurVALUE3, 30);
      DBMS_SQL.Define_column(CursorFAL_SUM_STOCK, 10, CurVALUE4, 30);
      DBMS_SQL.Define_column(CursorFAL_SUM_STOCK, 11, CurVALUE5, 30);
      lnNextColumn  := 12;
    else
      lnNextColumn  := 2;
    end if;

    if lbFEFO then
      DBMS_SQL.Define_column(CursorFAL_SUM_STOCK, lnNextColumn, ldFEFO);
    end if;

    Ignore               := DBMS_SQL.execute(CursorFAL_SUM_STOCK);

    -- Prise en compte des stocks mini
    if PdtHasVersionOrCharacteristic then
      -- On ne tiens pas compte des quantité min pour les produits ayant des
      -- caractérisations morphologique (Version ou caractéristique)
      XSumCST_QUANTITY_MIN  := 0;
    else
      if lbFEFO then
        -- En gérant la date limite d'utilisation (FEFO), on diminue le stock disponible à concurrence du disponible afin de n'avoir
        -- à la fin que le stock réellement disponible (dixit dans l'analyse ???)
        -- A revoir et à comprendre
        XSumCST_QUANTITY_MIN  := GetSumCST_QUANTITY_MIN(PrmGOOD_ID, PrmLstStock, LstControleStocksIDs);
      else
        -- Ici on ne gère ni péremption, ni ré-analyse, ni morphologique
        XSumCST_QUANTITY_MIN  := GetSumCST_QUANTITY_MIN(PrmGOOD_ID, PrmLstStock, LstControleStocksIDs);
      end if;
    end if;

    -- 11 --
    while DBMS_SQL.fetch_rows(CursorFAL_SUM_STOCK) > 0 loop
      CurGCO_CHARACTERIZATION1_ID  := null;
      CurGCO_CHARACTERIZATION2_ID  := null;
      CurGCO_CHARACTERIZATION3_ID  := null;
      CurGCO_CHARACTERIZATION4_ID  := null;
      CurGCO_CHARACTERIZATION5_ID  := null;
      CurVALUE1                    := null;
      CurVALUE2                    := null;
      CurVALUE3                    := null;
      CurVALUE4                    := null;
      CurVALUE5                    := null;
      DBMS_SQL.column_value(CursorFAL_SUM_STOCK, 1, CurSomme);

      if PdtHasVersionOrCharacteristic then
        -- Seulement si le produit a des caractérisations morphologique (de types versions ou caractérisque)
        DBMS_SQL.column_value(CursorFAL_SUM_STOCK, 2, CurGCO_CHARACTERIZATION1_ID);
        DBMS_SQL.column_value(CursorFAL_SUM_STOCK, 3, CurGCO_CHARACTERIZATION2_ID);
        DBMS_SQL.column_value(CursorFAL_SUM_STOCK, 4, CurGCO_CHARACTERIZATION3_ID);
        DBMS_SQL.column_value(CursorFAL_SUM_STOCK, 5, CurGCO_CHARACTERIZATION4_ID);
        DBMS_SQL.column_value(CursorFAL_SUM_STOCK, 6, CurGCO_CHARACTERIZATION5_ID);
        DBMS_SQL.column_value(CursorFAL_SUM_STOCK, 7, CurVALUE1);
        DBMS_SQL.column_value(CursorFAL_SUM_STOCK, 8, CurVALUE2);
        DBMS_SQL.column_value(CursorFAL_SUM_STOCK, 9, CurVALUE3);
        DBMS_SQL.column_value(CursorFAL_SUM_STOCK, 10, CurVALUE4);
        DBMS_SQL.column_value(CursorFAL_SUM_STOCK, 11, CurVALUE5);
        lnNextColumn  := 12;
      else
        lnNextColumn  := 2;
      end if;

      X                            := nvl(CurSomme, 0) - nvl(XSumCST_QUANTITY_MIN, 0);
      -- Ajouter les Qtés attribués d'appro sur stock
      SAS                          :=
        GetSumApproSurStock(concat(CurGCO_CHARACTERIZATION1_ID, CurVALUE1)
                          , concat(CurGCO_CHARACTERIZATION2_ID, CurVALUE2)
                          , concat(CurGCO_CHARACTERIZATION3_ID, CurVALUE3)
                          , concat(CurGCO_CHARACTERIZATION4_ID, CurVALUE4)
                          , concat(CurGCO_CHARACTERIZATION5_ID, CurVALUE5)
                          , PrmGOOD_ID
                          , PrmLstStock
                          , LstControleStocksIDs
                          , PdtHasVersionOrCharacteristic
                          , lbFEFO
                           );
      X                            := X + nvl(SAS, 0);

      if X < 0 then
        X  := 0;
      end if;

      -- Ajoute la date FEFO éventuelle
      ldFEFO                       := null;

      if lbFEFO then
        DBMS_SQL.column_value(CursorFAL_SUM_STOCK, lnNextColumn, ldFEFO);
      end if;

      -- Créer un record pour le groupe de caractérisations trouvées.
      insert into FAL_SUM_STOCK
                  (FAL_SUM_STOCK_ID
                 , GCO_CHARACTERIZATION1_ID
                 , GCO_CHARACTERIZATION2_ID
                 , GCO_CHARACTERIZATION3_ID
                 , GCO_CHARACTERIZATION4_ID
                 , GCO_CHARACTERIZATION5_ID
                 , FSS_SUM_ON_GROUP
                 , FSS_CHARACTERIZATION_VALUE1
                 , FSS_CHARACTERIZATION_VALUE2
                 , FSS_CHARACTERIZATION_VALUE3
                 , FSS_CHARACTERIZATION_VALUE4
                 , FSS_CHARACTERIZATION_VALUE5
                 , FSS_FEFO_DATE
                  )
           values (GetNewId
                 , CurGCO_CHARACTERIZATION1_ID
                 , CurGCO_CHARACTERIZATION2_ID
                 , CurGCO_CHARACTERIZATION3_ID
                 , CurGCO_CHARACTERIZATION4_ID
                 , CurGCO_CHARACTERIZATION5_ID
                 , X
                 , CurVALUE1
                 , CurVALUE2
                 , CurVALUE3
                 , CurVALUE4
                 , CurVALUE5
                 , ldFEFO
                  );
    end loop;

    DBMS_SQL.close_cursor(CursorFAL_SUM_STOCK);
  end CreateFAL_SUM_STOCK;

  -- Mise à jour de l'enregistrement pointé par aFAL_SUM_STOCK_ID
  procedure UpdateRecordWithMorpho(aFAL_SUM_STOCK_ID FAL_SUM_STOCK.FAL_SUM_STOCK_ID%type, NewValue FAL_SUM_STOCK.FSS_SUM_ON_GROUP%type)
  is
  begin
    update FAL_SUM_STOCK
       set FSS_SUM_ON_GROUP = NewValue
     where FAL_SUM_STOCK_ID = aFAL_SUM_STOCK_ID;
  end UpdateRecordWithMorpho;

  /**
  * function GetSortType
  * Description : Déterminer l'ordre de tri des positions de stock
  *
  * @created
  * @lastUpdate
  * @public
  * @return   0 : pas de tri - 1 : tri chrono ascendant - 2 : tri chrono descendant
  */
  function GetSortType(iFIFO in integer, iLIFO in integer, iTimeLimit in integer)
    return integer
  is
  begin
    if    (iFIFO = 1)
       or (iTimeLimit = 1) then
      return 1;
    elsif(iLIFO = 1) then
      return 2;
    end if;

    return 0;
  end;

  /**
  * procedure : getSumProcurements
  * Description : Recherche la somme des Appros libres
  *
  * @created
  * @lastUpdate
  * @public
  * @return   somme des Appros libres
  */
  function getSumProcurements(
    ai1v1                      varchar2
  , ai2v2                      varchar2
  , ai3v3                      varchar2
  , ai4v4                      varchar2
  , ai5v5                      varchar2
  , iGoodId                    GCO_GOOD.GCO_GOOD_ID%type
  , iUseMasterPlanProcurements integer
  , iDelay                     DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type
  , iStockId                   STM_STOCK.STM_STOCK_ID%type
  , iLocationId                STM_LOCATION.STM_LOCATION_ID%type
  )
    return FAL_NETWORK_SUPPLY.FAN_FREE_QTY%type
  is
    lnSumProcurements FAL_NETWORK_SUPPLY.FAN_FREE_QTY%type;
  begin
    select sum(FNS.FAN_FREE_QTY)
      into lnSumProcurements
      from FAL_NETWORK_SUPPLY FNS
         , gco_characterization char1
         , gco_characterization char2
         , gco_characterization char3
         , gco_characterization char4
         , gco_characterization char5
     where FNS.GCO_GOOD_ID = iGoodId
       and FNS.FAN_FREE_QTY > 0
       and FNS.GCO_CHARACTERIZATION1_ID = char1.GCO_CHARACTERIZATION_ID(+)
       and FNS.GCO_CHARACTERIZATION2_ID = char2.GCO_CHARACTERIZATION_ID(+)
       and FNS.GCO_CHARACTERIZATION3_ID = char3.GCO_CHARACTERIZATION_ID(+)
       and FNS.GCO_CHARACTERIZATION4_ID = char4.GCO_CHARACTERIZATION_ID(+)
       and FNS.GCO_CHARACTERIZATION5_ID = char5.GCO_CHARACTERIZATION_ID(+)
       and (    (    cDocLocationLink = 1
                 and FNS.STM_LOCATION_ID = iLocationId)
            or (    cDocLocationLink = 2
                and FNS.STM_STOCK_ID = iStockId)
            or (    cDocLocationLink = 3
                and FNS.STM_STOCK_ID in(
                      select STM_STOCK_ID
                        from STM_STOCK
                       where (    C_ACCESS_METHOD = 'PUBLIC'
                              and STO_NEED_CALCULATION = 1)
                          or (instr(';' || lower(PCS.PC_CONFIG.GetConfig('PPS_STOCK_CTRL') ) || ';', ';' || lower(sto_description) || ';') > 0) )
               )
           )
       and trunc(FNS.FAN_END_PLAN) <= trunc(iDelay)
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
       and (    (     (cAttribOnCharactMode = 1)
                 and (    (    Ai1v1 || Ai2v2 || Ai3v3 || Ai4v4 || Ai5v5 is not null
                           and (    (Ai1v1 in
                                       (concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1)
                                      , concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2)
                                      , concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3)
                                      , concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4)
                                      , concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)
                                       )
                                    )
                                or (Ai1v1 is null)
                               )
                           and (    (Ai2v2 in
                                       (concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1)
                                      , concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2)
                                      , concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3)
                                      , concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4)
                                      , concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)
                                       )
                                    )
                                or (Ai2v2 is null)
                               )
                           and (    (Ai3v3 in
                                       (concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1)
                                      , concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2)
                                      , concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3)
                                      , concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4)
                                      , concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)
                                       )
                                    )
                                or (Ai3v3 is null)
                               )
                           and (    (Ai4v4 in
                                       (concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1)
                                      , concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2)
                                      , concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3)
                                      , concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4)
                                      , concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)
                                       )
                                    )
                                or (Ai4v4 is null)
                               )
                           and (    (Ai5v5 in
                                       (concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1)
                                      , concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2)
                                      , concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3)
                                      , concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4)
                                      , concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)
                                       )
                                    )
                                or (Ai5v5 is null)
                               )
                          )
                      or (    Ai1v1 || Ai2v2 || Ai3v3 || Ai4v4 || Ai5v5 is null
                          and fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1, CHAR1.C_CHARACT_TYPE) ||
                              fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2, CHAR2.C_CHARACT_TYPE) ||
                              fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3, CHAR3.C_CHARACT_TYPE) ||
                              fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4, CHAR4.C_CHARACT_TYPE) ||
                              fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5, CHAR5.C_CHARACT_TYPE) is null
                         )
                     )
                )
            or (     (cAttribOnCharactMode <> 1)
                and (    (     (    (Ai1v1 in
                                       (concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1)
                                      , concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2)
                                      , concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3)
                                      , concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4)
                                      , concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)
                                       )
                                    )
                                or (Ai1v1 is null)
                               )
                          and (    (Ai2v2 in
                                      (concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1)
                                     , concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2)
                                     , concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3)
                                     , concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4)
                                     , concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)
                                      )
                                   )
                               or (Ai2v2 is null)
                              )
                          and (    (Ai3v3 in
                                      (concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1)
                                     , concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2)
                                     , concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3)
                                     , concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4)
                                     , concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)
                                      )
                                   )
                               or (Ai3v3 is null)
                              )
                          and (    (Ai4v4 in
                                      (concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1)
                                     , concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2)
                                     , concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3)
                                     , concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4)
                                     , concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)
                                      )
                                   )
                               or (Ai4v4 is null)
                              )
                          and (    (Ai5v5 in
                                      (concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1)
                                     , concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2)
                                     , concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3)
                                     , concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4)
                                     , concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)
                                      )
                                   )
                               or (Ai5v5 is null)
                              )
                         )
                     or (fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1, CHAR1.C_CHARACT_TYPE) ||
                         fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2, CHAR2.C_CHARACT_TYPE) ||
                         fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3, CHAR3.C_CHARACT_TYPE) ||
                         fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4, CHAR4.C_CHARACT_TYPE) ||
                         fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5, CHAR5.C_CHARACT_TYPE) is null
                        )
                    )
               )
           );

    return nvl(lnSumProcurements, 0);
  end;

  /**
  * procedure : getSumAvailStockQty
  * Description : Recherche la somme des quantités disponible en stock
  *
  * @created
  * @lastUpdate
  * @public
  * @return   somme des quantités disponible en stock
  */
  function getSumAvailStockQty(
    ai1v1                varchar2
  , ai2v2                varchar2
  , ai3v3                varchar2
  , ai4v4                varchar2
  , ai5v5                varchar2
  , iGoodId              GCO_GOOD.GCO_GOOD_ID%type
  , iThirdId             number
  , iTimeLimitManagement number
  , iDate                date
  , iStockId             STM_STOCK.STM_STOCK_ID%type
  , iLocationId          STM_LOCATION.STM_LOCATION_ID%type
  , iStockListId         varchar2
  )
    return STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type
  is
    lnAvailQty STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type;
  begin
    select sum(SPO_AVAILABLE_QUANTITY)
      into lnAvailQty
      from STM_STOCK_POSITION SPO
         , STM_ELEMENT_NUMBER SEM
         , GCO_CHARACTERIZATION CHAR1
         , GCO_CHARACTERIZATION CHAR2
         , GCO_CHARACTERIZATION CHAR3
         , GCO_CHARACTERIZATION CHAR4
         , GCO_CHARACTERIZATION CHAR5
     where SPO.GCO_GOOD_ID = iGoodId
       and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = SEM.STM_ELEMENT_NUMBER_ID(+)
       and (    (    cDocLocationLink = 1
                 and SPO.STM_LOCATION_ID = iLocationId)
            or (    cDocLocationLink = 2
                and SPO.STM_STOCK_ID = iStockId)
            or (    cDocLocationLink = 3
                and iStockListId is null
                and exists(select STM_STOCK_ID
                             from STM_STOCK
                            where STM_STOCK_ID = SPO.STM_STOCK_ID
                              and C_ACCESS_METHOD = 'PUBLIC'
                              and STO_NEED_CALCULATION = 1)
               )
            or (    cDocLocationLink = 3
                and instr(',' || iStockListId || ',', ',' || SPO.STM_STOCK_ID || ',') <> 0)
           )
       and SPO.SPO_AVAILABLE_QUANTITY > 0
       and SPO.GCO_CHARACTERIZATION_ID = char1.GCO_CHARACTERIZATION_ID(+)
       and SPO.GCO_GCO_CHARACTERIZATION_ID = char2.GCO_CHARACTERIZATION_ID(+)
       and SPO.GCO2_GCO_CHARACTERIZATION_ID = char3.GCO_CHARACTERIZATION_ID(+)
       and SPO.GCO3_GCO_CHARACTERIZATION_ID = char4.GCO_CHARACTERIZATION_ID(+)
       and SPO.GCO4_GCO_CHARACTERIZATION_ID = char5.GCO_CHARACTERIZATION_ID(+)
       and (    (     (cAttribOnCharactMode = 1)
                 and (    (    Ai1v1 || Ai2v2 || Ai3v3 || Ai4v4 || Ai5v5 is not null
                           and (    (Ai1v1 in
                                       (concat(SPO.GCo_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_1)
                                      , concat(SPO.GCo_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_2)
                                      , concat(SPO.GCo2_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_3)
                                      , concat(SPO.GCo3_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_4)
                                      , concat(SPO.GCo4_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_5)
                                       )
                                    )
                                or (Ai1v1 is null)
                               )
                           and (    (Ai2v2 in
                                       (concat(SPO.GCo_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_1)
                                      , concat(SPO.GCo_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_2)
                                      , concat(SPO.GCo2_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_3)
                                      , concat(SPO.GCo3_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_4)
                                      , concat(SPO.GCo4_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_5)
                                       )
                                    )
                                or (Ai2v2 is null)
                               )
                           and (    (Ai3v3 in
                                       (concat(SPO.GCo_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_1)
                                      , concat(SPO.GCo_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_2)
                                      , concat(SPO.GCo2_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_3)
                                      , concat(SPO.GCo3_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_4)
                                      , concat(SPO.GCo4_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_5)
                                       )
                                    )
                                or (Ai3v3 is null)
                               )
                           and (    (Ai4v4 in
                                       (concat(SPO.GCo_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_1)
                                      , concat(SPO.GCo_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_2)
                                      , concat(SPO.GCo2_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_3)
                                      , concat(SPO.GCo3_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_4)
                                      , concat(SPO.GCo4_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_5)
                                       )
                                    )
                                or (Ai4v4 is null)
                               )
                           and (    (Ai5v5 in
                                       (concat(SPO.GCo_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_1)
                                      , concat(SPO.GCo_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_2)
                                      , concat(SPO.GCo2_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_3)
                                      , concat(SPO.GCo3_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_4)
                                      , concat(SPO.GCo4_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_5)
                                       )
                                    )
                                or (Ai5v5 is null)
                               )
                          )
                      or (    Ai1v1 || Ai2v2 || Ai3v3 || Ai4v4 || Ai5v5 is null
                          and fal_tools.NullForNoMorpho(SPO.GCo_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_1, CHAR1.C_CHARACT_TYPE) ||
                              fal_tools.NullForNoMorpho(SPO.GCo_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_2, CHAR2.C_CHARACT_TYPE) ||
                              fal_tools.NullForNoMorpho(SPO.GCo2_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_3, CHAR3.C_CHARACT_TYPE) ||
                              fal_tools.NullForNoMorpho(SPO.GCo3_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_4, CHAR4.C_CHARACT_TYPE) ||
                              fal_tools.NullForNoMorpho(SPO.GCo4_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_5, CHAR5.C_CHARACT_TYPE) is null
                         )
                     )
                )
            or (     (cAttribOnCharactMode <> 1)
                and (    (     (    (Ai1v1 in
                                       (concat(SPO.GCo_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_1)
                                      , concat(SPO.GCo_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_2)
                                      , concat(SPO.GCo2_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_3)
                                      , concat(SPO.GCo3_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_4)
                                      , concat(SPO.GCo4_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_5)
                                       )
                                    )
                                or (Ai1v1 is null)
                               )
                          and (    (Ai2v2 in
                                      (concat(SPO.GCo_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_1)
                                     , concat(SPO.GCo_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_2)
                                     , concat(SPO.GCo2_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_3)
                                     , concat(SPO.GCo3_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_4)
                                     , concat(SPO.GCo4_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_5)
                                      )
                                   )
                               or (Ai2v2 is null)
                              )
                          and (    (Ai3v3 in
                                      (concat(SPO.GCo_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_1)
                                     , concat(SPO.GCo_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_2)
                                     , concat(SPO.GCo2_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_3)
                                     , concat(SPO.GCo3_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_4)
                                     , concat(SPO.GCo4_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_5)
                                      )
                                   )
                               or (Ai3v3 is null)
                              )
                          and (    (Ai4v4 in
                                      (concat(SPO.GCo_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_1)
                                     , concat(SPO.GCo_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_2)
                                     , concat(SPO.GCo2_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_3)
                                     , concat(SPO.GCo3_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_4)
                                     , concat(SPO.GCo4_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_5)
                                      )
                                   )
                               or (Ai4v4 is null)
                              )
                          and (    (Ai5v5 in
                                      (concat(SPO.GCo_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_1)
                                     , concat(SPO.GCo_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_2)
                                     , concat(SPO.GCo2_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_3)
                                     , concat(SPO.GCo3_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_4)
                                     , concat(SPO.GCo4_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_5)
                                      )
                                   )
                               or (Ai5v5 is null)
                              )
                         )
                     or (fal_tools.NullForNoMorpho(SPO.GCo_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_1, CHAR1.C_CHARACT_TYPE) ||
                         fal_tools.NullForNoMorpho(SPO.GCo_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_2, CHAR2.C_CHARACT_TYPE) ||
                         fal_tools.NullForNoMorpho(SPO.GCo2_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_3, CHAR3.C_CHARACT_TYPE) ||
                         fal_tools.NullForNoMorpho(SPO.GCo3_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_4, CHAR4.C_CHARACT_TYPE) ||
                         fal_tools.NullForNoMorpho(SPO.GCo4_GCO_CHARACTERIZATION_ID, SPO_CHARACTERIZATION_VALUE_5, CHAR5.C_CHARACT_TYPE) is null
                        )
                    )
               )
           )
       -- Propose que les positions de stock non périmée pour la date spécifiée (en principe la date du besoin)
       and (    (iTimeLimitManagement = 0)
            or (     (iTimeLimitManagement = 1)
                and (   SPO.SPO_CHRONOLOGICAL is null
                     or GCO_I_LIB_CHARACTERIZATION.IsOutdated(iGoodID          => iGoodId, iThirdId => iThirdId, iTimeLimitDate => SPO.SPO_CHRONOLOGICAL
                                                            , iDate            => iDate) = 0
                    )
               )
           )
       -- Propose que les positions de stock avec statut qualité disponible pour le prévisionnel et les attributions ou sans gestion du statut qualité
       and (GCO_I_LIB_QUALITY_STATUS.IsNetworkLinkManagement(iQualityStatusId => SEM.GCO_QUALITY_STATUS_ID) = 1)
       -- Propose que les positions de stock qui n'ont pas dépassé la date de ré-analyse mais seulement si elles ne sont pas considérées
       -- comme disponible pour les traitements prévisionnels. La date de référence est la date du jour.
       and (    (PCS.PC_CONFIG.GetConfig('GCO_RETEST_PREV_MODE') = '0')
            or (     (PCS.PC_CONFIG.GetConfig('GCO_RETEST_PREV_MODE') = '1')
                and (STM_I_LIB_STOCK_POSITION.IsRetestNeeded(iStockPositionId => SPO.STM_STOCK_POSITION_ID, iDate => sysdate) = 0)
               )
           );

    return nvl(lnAvailQty, 0);
  end;

  /**
  * procedure : ReconstructionAttribution2
  * Description : (analyse Graph = EvtsConstructAttrib2.vsd)
  *
  * @created
  * @lastUpdate
  * @public
  * @param   iNeedId                    : Id du besoin d'origine
  * @param   iUseMasterPlanProcurements : prise en compte des appros du plan directeur
  * @param   PrmMargeNegativeGlobale    : attrib sur appro même si marge négative
  * @param   iStockListId               : liste des stocks pris en compte dans le calcul
  */
  procedure ReconstructionAttribution2(iNeedId number, iUseMasterPlanProcurements integer, PrmMargeNegativeGlobale integer, iStockListId in varchar2)
  is
    /* Curseur de recherche des approvisionnements
     *
     * iWayDelay = 0 : Toutes les appros, par date du besoin croissant
     * iWayDelay = 1 : Les appros de délai < Date du besoin classé par DELAI FIN Dé-croissant
     * iWayDelay = 2 : Les appros de délai >= Date du besoin classé par DELAI FIN croissant
    */
    cursor crProcurements(
      ai1v1       varchar2
    , ai2v2       varchar2
    , ai3v3       varchar2
    , ai4v4       varchar2
    , ai5v5       varchar2
    , iGoodId     GCO_GOOD.GCO_GOOD_ID%type
    , iShiftDelay FAL_NETWORK_SUPPLY.FAN_END_PLAN%type
    , iStockId    STM_STOCK.STM_STOCK_ID%type
    , iLocationId STM_LOCATION.STM_LOCATION_ID%type
    , iWayDelay   integer
    , iReqDelay   FAL_NETWORK_NEED.FAN_BEG_PLAN%type default null
    )
    is
      select     FNS.FAN_FREE_QTY
               , FNS.FAL_NETWORK_SUPPLY_ID
            from FAL_NETWORK_SUPPLY FNS
               , gco_characterization char1
               , gco_characterization char2
               , gco_characterization char3
               , gco_characterization char4
               , gco_characterization char5
           where FNS.GCO_GOOD_ID = iGoodId
             and FNS.FAN_FREE_QTY > 0
             and FNS.GCO_CHARACTERIZATION1_ID = char1.GCO_CHARACTERIZATION_ID(+)
             and FNS.GCO_CHARACTERIZATION2_ID = char2.GCO_CHARACTERIZATION_ID(+)
             and FNS.GCO_CHARACTERIZATION3_ID = char3.GCO_CHARACTERIZATION_ID(+)
             and FNS.GCO_CHARACTERIZATION4_ID = char4.GCO_CHARACTERIZATION_ID(+)
             and FNS.GCO_CHARACTERIZATION5_ID = char5.GCO_CHARACTERIZATION_ID(+)
             and (    (    cDocLocationLink = 1
                       and FNS.STM_LOCATION_ID = iLocationId)
                  or (    cDocLocationLink = 2
                      and FNS.STM_STOCK_ID = iStockId)
                  or (    cDocLocationLink = 3
                      and iStockListId is null
                      and exists(select STM_STOCK_ID
                                   from STM_STOCK
                                  where STM_STOCK_ID = FNS.STM_STOCK_ID
                                    and C_ACCESS_METHOD = 'PUBLIC'
                                    and STO_NEED_CALCULATION = 1)
                     )
                  or (    cDocLocationLink = 3
                      and instr(',' || iStockListId || ',', ',' || FNS.STM_STOCK_ID || ',') <> 0)
                 )
             -- Cette valeur est nulle lorsque l'option avec marge négative est sélectionnée
             and (   iShiftDelay is null
                  or (trunc(FNS.FAN_END_PLAN) <= trunc(iShiftDelay) ) )
             and (    (iWayDelay = 0)
                  or (    iWayDelay = 1
                      and trunc(FNS.FAN_END_PLAN) < trunc(iReqDelay) )
                  or (    iWayDelay = 2
                      and trunc(FNS.FAN_END_PLAN) >= trunc(iReqDelay) )
                 )
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
             and (    (     (cAttribOnCharactMode = 1)
                       and (    (    Ai1v1 || Ai2v2 || Ai3v3 || Ai4v4 || Ai5v5 is not null
                                 and (    (Ai1v1 in
                                             (concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1)
                                            , concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2)
                                            , concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3)
                                            , concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4)
                                            , concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)
                                             )
                                          )
                                      or (Ai1v1 is null)
                                     )
                                 and (    (Ai2v2 in
                                             (concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1)
                                            , concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2)
                                            , concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3)
                                            , concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4)
                                            , concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)
                                             )
                                          )
                                      or (Ai2v2 is null)
                                     )
                                 and (    (Ai3v3 in
                                             (concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1)
                                            , concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2)
                                            , concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3)
                                            , concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4)
                                            , concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)
                                             )
                                          )
                                      or (Ai3v3 is null)
                                     )
                                 and (    (Ai4v4 in
                                             (concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1)
                                            , concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2)
                                            , concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3)
                                            , concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4)
                                            , concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)
                                             )
                                          )
                                      or (Ai4v4 is null)
                                     )
                                 and (    (Ai5v5 in
                                             (concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1)
                                            , concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2)
                                            , concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3)
                                            , concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4)
                                            , concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)
                                             )
                                          )
                                      or (Ai5v5 is null)
                                     )
                                )
                            or (    Ai1v1 || Ai2v2 || Ai3v3 || Ai4v4 || Ai5v5 is null
                                and fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1, CHAR1.C_CHARACT_TYPE) ||
                                    fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2, CHAR2.C_CHARACT_TYPE) ||
                                    fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3, CHAR3.C_CHARACT_TYPE) ||
                                    fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4, CHAR4.C_CHARACT_TYPE) ||
                                    fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5, CHAR5.C_CHARACT_TYPE) is null
                               )
                           )
                      )
                  or (     (cAttribOnCharactMode <> 1)
                      and (    (     (    (Ai1v1 in
                                             (concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1)
                                            , concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2)
                                            , concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3)
                                            , concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4)
                                            , concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)
                                             )
                                          )
                                      or (Ai1v1 is null)
                                     )
                                and (    (Ai2v2 in
                                            (concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1)
                                           , concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2)
                                           , concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3)
                                           , concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4)
                                           , concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)
                                            )
                                         )
                                     or (Ai2v2 is null)
                                    )
                                and (    (Ai3v3 in
                                            (concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1)
                                           , concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2)
                                           , concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3)
                                           , concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4)
                                           , concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)
                                            )
                                         )
                                     or (Ai3v3 is null)
                                    )
                                and (    (Ai4v4 in
                                            (concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1)
                                           , concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2)
                                           , concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3)
                                           , concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4)
                                           , concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)
                                            )
                                         )
                                     or (Ai4v4 is null)
                                    )
                                and (    (Ai5v5 in
                                            (concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1)
                                           , concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2)
                                           , concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3)
                                           , concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4)
                                           , concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)
                                            )
                                         )
                                     or (Ai5v5 is null)
                                    )
                               )
                           or (fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1, CHAR1.C_CHARACT_TYPE) ||
                               fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2, CHAR2.C_CHARACT_TYPE) ||
                               fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3, CHAR3.C_CHARACT_TYPE) ||
                               fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4, CHAR4.C_CHARACT_TYPE) ||
                               fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5, CHAR5.C_CHARACT_TYPE) is null
                              )
                          )
                     )
                 )
        order by (case
                    when iWayDelay = 1 then FNS.FAN_END_PLAN
                  end) desc
               , (case
                    when iWayDelay <> 1 then FNS.FAN_END_PLAN
                  end) asc
      for update;

    EnrNEED          FAL_NETWORK_NEED%rowtype;
    lnFreeQty        FAL_NETWORK_NEED.FAN_FREE_QTY%type;
    Delai            DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type;
    liAllocType      integer;
    valueCar1        STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type;
    valueCar2        STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type;
    valueCar3        STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type;
    valueCar4        STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type;
    valueCar5        STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type;
    IdCar1           GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    IdCar2           GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    IdCar3           GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    IdCar4           GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    IdCar5           GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    ST1              number;
    AP               number;
    lbAllIsAllocated boolean;
    lbReqInHorizon   boolean;
    lnFIFO           number(1)                                              := 0;
    lnLIFO           number(1)                                              := 0;
    lnTimeLimit      number(1)                                              := 0;
    liSortType       integer                                                := 0;
    ldShiftDelay     FAL_NETWORK_SUPPLY.FAN_END_PLAN%type;
    lnStockId        STM_STOCK.STM_STOCK_ID%type;
    lnLocationId     STM_LOCATION.STM_LOCATION_ID%type;
    lnShiftProduct   number(9);

    -- Lecture des position de stock
    procedure ForEachStockPosition(iTimeLimit in number default 0)
    is
    begin
      -- gérer itération sur les positions de stocks
      for tplStockPosition in crStockPosition(ai1v1                  => concat(idcar1, valuecar1)
                                            , ai2v2                  => concat(idcar2, valuecar2)
                                            , ai3v3                  => concat(idcar3, valuecar3)
                                            , ai4v4                  => concat(idcar4, valuecar4)
                                            , ai5v5                  => concat(idcar5, valuecar5)
                                            , iGoodId                => EnrNEED.GCO_GOOD_ID
                                            , iThirdId               => EnrNEED.PAC_THIRD_ID
                                            , iTimeLimitManagement   => iTimeLimit
                                            , iDate                  => EnrNEED.FAN_BEG_PLAN
                                            , iStockListId           => iStockListId
                                            , iStockId               => lnStockId
                                            , iLocationId            => lnLocationId
                                            , iSortOnChrono          => liSortType
                                             ) loop
        if tplStockPosition.SPO_AVAILABLE_QUANTITY >= lnFreeQty then
          FAl_NETWORK.CreateAttribBesoinStock(iNeedId, tplStockPosition.STM_STOCK_POSITION_ID, tplStockPosition.STM_LOCATION_ID, lnFreeQty);
          lnFreeQty  := 0;
          exit;   -- Retour re-construction besoin suivant
        else
          FAl_NETWORK.CreateAttribBesoinStock(iNeedId
                                            , tplStockPosition.STM_STOCK_POSITION_ID
                                            , tplStockPosition.STM_LOCATION_ID
                                            , tplStockPosition.SPO_AVAILABLE_QUANTITY
                                             );
          lnFreeQty  := lnFreeQty - tplStockPosition.SPO_AVAILABLE_QUANTITY;
        end if;
      end loop;
    end;
-- MAIN RECONSTRUCTION ATTRIBUTION 2
  begin
    -- relecture du NEED (Je sais que l'on lit 2 fois le record mais il est pas evident que dans le curseur dyn cela fasse
    -- gagner plus de temps qu'ici
    select *
      into EnrNEED
      from FAL_NETWORK_NEED
     where FAL_NETWORK_NEED_ID = iNeedId;

    -- Initialisation des variables
    -- 1 --
    lnFreeQty       := EnrNEED.FAN_FREE_QTY;
    Delai           := EnrNEED.FAN_BEG_PLAN;
    lnStockId       := EnrNEED.STM_STOCK_ID;
    lnLocationId    := EnrNEED.STM_LOCATION_ID;
    -- Initialisation des valeur 1..5 des charactérisation de type version (1) ou caracteristique (2)
    ValueCar1       := null;
    ValueCar2       := null;
    ValueCar3       := null;
    ValueCar4       := null;
    ValueCar5       := null;
    IdCar1          := null;
    IdCar2          := null;
    IdCar3          := null;
    IdCar4          := null;
    IdCar5          := null;

    if fal_tools.VersionOrCharacteristicType(EnrNEED.GCO_CHARACTERIZATION1_ID) = 1 then
      valueCar1  := EnrNEED.FAN_CHAR_VALUE1;

      if valueCar1 is null then
        idCar1  := null;
      else
        IdCar1  := EnrNEED.GCO_CHARACTERIZATION1_ID;
      end if;
    end if;

    if fal_tools.VersionOrCharacteristicType(EnrNEED.GCO_CHARACTERIZATION2_ID) = 1 then
      valueCar2  := EnrNEED.FAN_CHAR_VALUE2;

      if valueCar2 is null then
        idCar2  := null;
      else
        IdCar2  := EnrNEED.GCO_CHARACTERIZATION2_ID;
      end if;
    end if;

    if fal_tools.VersionOrCharacteristicType(EnrNEED.GCO_CHARACTERIZATION3_ID) = 1 then
      valueCar3  := EnrNEED.FAN_CHAR_VALUE3;

      if valueCar3 is null then
        idCar3  := null;
      else
        IdCar3  := EnrNEED.GCO_CHARACTERIZATION3_ID;
      end if;
    end if;

    if fal_tools.VersionOrCharacteristicType(EnrNEED.GCO_CHARACTERIZATION4_ID) = 1 then
      valueCar4  := EnrNEED.FAN_CHAR_VALUE4;

      if valueCar4 is null then
        idCar4  := null;
      else
        IdCar4  := EnrNEED.GCO_CHARACTERIZATION4_ID;
      end if;
    end if;

    if fal_tools.VersionOrCharacteristicType(EnrNEED.GCO_CHARACTERIZATION5_ID) = 1 then
      valueCar5  := EnrNEED.FAN_CHAR_VALUE5;

      if valueCar5 is null then
        idCar5  := null;
      else
        IdCar5  := EnrNEED.GCO_CHARACTERIZATION5_ID;
      end if;
    end if;

    -- Récupère les informations des types chronoloqique
    GCO_I_LIB_CHARACTERIZATION.GetChronologicalType(iGoodID => EnrNEED.GCO_GOOD_ID, ioFIFO => lnFIFO, ioLIFO => lnLIFO, ioTimeLimit => lnTimeLimit);
    -- Déterminer l'ordre de tri des positions de stock
    liSortType      := GetSortType(lnFIFO, lnLIFO, lnTimeLimit);
    -- Selection des positions de stock supérieures à 0 du produit sur l'emplacement et ayant même valeur
    -- de caractérisations pour les caractérisations de type version ou caractéristique.
    -- 2 --
    ST1             := 0;
    /* Est-ce que le besoin est dans l'horizon de réservation sur stock ? */
    lbReqInHorizon  :=(EnrNEED.FAN_BEG_PLAN <= sysdate + GetHorizonAttributionVente(EnrNEED.GCO_GOOD_ID, EnrNEED.PAC_THIRD_ID) );

    if lbReqInHorizon then
      ST1  :=
        getSumAvailStockQty(ai1v1                  => concat(idcar1, valuecar1)
                          , ai2v2                  => concat(idcar2, valuecar2)
                          , ai3v3                  => concat(idcar3, valuecar3)
                          , ai4v4                  => concat(idcar4, valuecar4)
                          , ai5v5                  => concat(idcar5, valuecar5)
                          , iGoodId                => EnrNEED.GCO_GOOD_ID
                          , iThirdId               => EnrNEED.PAC_THIRD_ID
                          , iTimeLimitManagement   => lnTimeLimit
                          , iDate                  => EnrNEED.FAN_BEG_PLAN
                          , iStockId               => lnStockId
                          , iLocationId            => lnLocationId
                          , iStockListId           => iStockListId
                           );
    else
      ST1  := 0;
    end if;

    ST1             := nvl(ST1, 0);
    -- Selon la config DOC_TYPE_AUTO_LINK
    liAllocType     := GetAllocationType(EnrNEED.PAC_THIRD_ID);

    -- 3 --
    if liAllocType = rtAllocStockOnTotalQty then
      /* Réservation sur stock si qté totale attribuable */
      if     (ST1 >= lnFreeQty)
         and lbReqInHorizon then
        ForEachStockPosition(lnTimeLimit);
      end if;
    elsif liAllocType = rtAllocStockPartialQty then
      /* Réservation sur stock si qté partielle attribuable */
      if lbReqInHorizon then
        ForEachStockPosition(lnTimeLimit);
      end if;
    elsif liAllocType in(rtAllocStockAndProcOnTotalQty, rtAllocStockAndProcPartialQty) then
      /* Réservation sur stock + Appro */
      -- 7 --
      AP  :=
        getSumProcurements(concat(idcar1, valuecar1)
                         , concat(idcar2, valuecar2)
                         , concat(idcar3, valuecar3)
                         , concat(idcar4, valuecar4)
                         , concat(idcar5, valuecar5)
                         , EnrNEED.GCO_GOOD_ID
                         , iUseMasterPlanProcurements
                         , Delai
                         , lnStockId
                         , lnLocationId
                          );

      if    liAllocType = rtAllocStockAndProcPartialQty
         or (     (liAllocType = rtAllocStockAndProcOnTotalQty)
             and (ST1 + AP >= lnFreeQty) ) then
        /* Réservation sur stock + Appro avec attribution partielle ou totale si qté suffisante */
        -- 9 --
        if PrmMargeNegativeGlobale = 0 then
          lnShiftProduct  := GetDecalageProduct(EnrNEED.GCo_GOOD_ID);

          -- Si le décalage est > au nbre de jours de décalage maximum calculés sur les calendriers
          if lnShiftProduct > FAL_LIB_CONSTANT.gCfgCBShiftLimit then
            ldShiftDelay  := Delai + lnShiftProduct;
          else
            ldShiftDelay  :=
                  FAL_SCHEDULE_FUNCTIONS.GetDecalageForwardDate(null, null, null, null, null, FAL_SCHEDULE_FUNCTIONS.GetDefaultCalendar, Delai, lnShiftProduct);
          end if;
        else
          ldShiftDelay  := null;   -- Pour indiquer que le délai n'aura pas d'importance
        end if;

        lbAllIsAllocated  := false;

        /* Sélection des approvisionnements en fonction de la configuration FAL_ATTRIB_LOG_MODE.
           - 1 : on prend les appros dans l'ordre de délai croissant (Fan_end_Plan du plus petit au plus grand)
           - 2 : On prend les appros de délai < Date du besoin classé par DELAI FIN Dé-croissant
                 Si tout n'es pas attribué (lbAllIsAllocated = false), on prend ensuite les appro de délai >= date du besoin classé par DELAI FIN Croissant
        */
        for tplProcurements in crProcurements(concat(idcar1, valuecar1)
                                            , concat(idcar2, valuecar2)
                                            , concat(idcar3, valuecar3)
                                            , concat(idcar4, valuecar4)
                                            , concat(idcar5, valuecar5)
                                            , EnrNEED.GCO_GOOD_ID
                                            , ldShiftDelay
                                            , lnStockId
                                            , lnLocationId
                                            , 0   -- quel que soit le délai
                                             ) loop
          -- 10 --
          if tplProcurements.FAN_FREE_QTY >= lnFreeQty then
            -- 11 --
            FAl_NETWORK.CreateAttribBesoinAppro(iNeedId, tplProcurements.FAl_NETWORK_SUPPLY_ID, lnFreeQty);
            lbAllIsAllocated  := true;
            exit;   -- Retour re-construction besoin suivant
          else
            -- 12 --
            FAL_NETWORK.CreateAttribBesoinAppro(iNeedId, tplProcurements.FAl_NETWORK_SUPPLY_ID, tplProcurements.FAN_FREE_QTY);
            lnFreeQty  := lnFreeQty - tplProcurements.FAN_FREE_QTY;
          end if;
        end loop;

        -- (2)
        /*  FAL_ATTRIB_LOG_MODE = 2 et tout n'a pas été attribué
        */
        if     not lbAllIsAllocated
           and (cAttribLogMode = 2) then
          for tplProcurements in crProcurements(concat(idcar1, valuecar1)
                                              , concat(idcar2, valuecar2)
                                              , concat(idcar3, valuecar3)
                                              , concat(idcar4, valuecar4)
                                              , concat(idcar5, valuecar5)
                                              , EnrNEED.GCO_GOOD_ID
                                              , ldShiftDelay
                                              , lnStockId
                                              , lnLocationId
                                              , 2   -- On prend les appros supérieurs ou égaux au délai
                                              , delai
                                               ) loop
            -- 10 --
            if tplProcurements.FAN_FREE_QTY >= lnFreeQty then
              -- 11 --
              FAl_NETWORK.CreateAttribBesoinAppro(iNeedId, tplProcurements.FAL_NETWORK_SUPPLY_ID, lnFreeQty);
              lbAllIsAllocated  := true;
              exit;   -- Retour re-construction besoin suivant
            else
              -- 12 --
              FAL_NETWORK.CreateAttribBesoinAppro(iNeedId, tplProcurements.FAl_NETWORK_SUPPLY_ID, tplProcurements.FAN_FREE_QTY);
              lnFreeQty  := lnFreeQty - tplProcurements.FAN_FREE_QTY;
            end if;
          end loop;
        end if;
      end if;

      /* Si tout n'as pas été attribué et le besoin est dans l'horizon de réservation sur stock */
      if     not lbAllIsAllocated
         and lbReqInHorizon then
        -- gérer Itération position de stock selectionée
        ForEachStockPosition(lnTimeLimit);
      end if;
    end if;   -- Fin de if ValueForTest = 4 or ((ValueForTest = 3) and (ST+AP >= lnFreeQty))
  end ReconstructionAttribution2;

---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-- PARTIE ATTRIBUTIONS AUTOMATIQUES  Graph = EvtsConstructAttrib.vsd
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
  procedure PartieGlobale(
    PrmGOOD_ID                   number
  , prmlststock                  varchar2
  , PrmBesoinsLogistiquesGlobale integer
  , PrmMargeNegativeGlobale      integer
  , PrmCompensationStockControle integer
  , PrmQueSurLesDocumentsGlobale integer
  , iUseMasterPlanProcurements   integer
  , iUseMasterPlanRequirements   integer
  , PrmFAL_PIC_ID                number
  , prmLstControleStocksIDs      varchar2
  )
  is
    CursorBesoin                  integer;
    CursorApproOfProduct          integer;
    BuffSql                       varchar2(32000);
    BuffSql2                      varchar2(32000);
    Ignore                        integer;
    CurDOC_POSITION_DETAIL_ID     DOC_POSITION_DETAIl.DOC_POSITION_DETAIL_ID%type;
    CurFAL_NETWORK_SUPPLY_ID      FAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID%type;
    CurPAC_THIRD_ID               PAC_THIRD.PAC_THIRD_ID%type;
    CurFAN_FREE_QTY               FAL_NETWORK_NEED.FAN_FREE_QTY%type;
    CurFAN_BEG_PLAN               FAL_NETWORK_NEED.FAN_BEG_PLAN%type;
    CurFAL_NETWORK_NEED_ID        FAl_NETWORK_NEED.FAL_NETWORK_NEED_ID%type;
    CurGCO_CHARACTERIZATION1_ID   FAl_NETWORK_NEED.GCO_CHARACTERIZATION1_ID%type;
    CurGCO_CHARACTERIZATION2_ID   FAl_NETWORK_NEED.GCO_CHARACTERIZATION2_ID%type;
    CurGCO_CHARACTERIZATION3_ID   FAl_NETWORK_NEED.GCO_CHARACTERIZATION3_ID%type;
    CurGCO_CHARACTERIZATION4_ID   FAl_NETWORK_NEED.GCO_CHARACTERIZATION4_ID%type;
    CurGCO_CHARACTERIZATION5_ID   FAl_NETWORK_NEED.GCO_CHARACTERIZATION5_ID%type;
    CurFAN_CHAR_VALUE1            FAl_NETWORK_NEED.FAN_CHAR_VALUE1%type;
    CurFAN_CHAR_VALUE2            FAl_NETWORK_NEED.FAN_CHAR_VALUE2%type;
    CurFAN_CHAR_VALUE3            FAl_NETWORK_NEED.FAN_CHAR_VALUE3%type;
    CurFAN_CHAR_VALUE4            FAl_NETWORK_NEED.FAN_CHAR_VALUE4%type;
    CurFAN_CHAR_VALUE5            FAl_NETWORK_NEED.FAN_CHAR_VALUE5%type;
    -- Résultats de la concaténation de chaque CurGCO_CHARACTERIZATIONx_ID et FAN_CHAR_VALUEx
    ai1v1                         varchar(100);   -- 100 pour assurer mais 50 sont suffisant (ID=> longueur 12, Caractérisation => longueur 30)
    ai2v2                         varchar(100);   -- ...
    ai3v3                         varchar(100);   -- ...
    ai4v4                         varchar(100);   -- ...
    ai5v5                         varchar(100);
    -- ...
    aV1                           FAl_NETWORK_NEED.FAN_CHAR_VALUE1%type;
    aV2                           FAl_NETWORK_NEED.FAN_CHAR_VALUE1%type;
    aV3                           FAl_NETWORK_NEED.FAN_CHAR_VALUE1%type;
    aV4                           FAl_NETWORK_NEED.FAN_CHAR_VALUE1%type;
    aV5                           FAl_NETWORK_NEED.FAN_CHAR_VALUE1%type;
    PdtHasVersionOrCharacteristic boolean;
    isTimeLimitManagement         boolean;
    isRetestManagement            boolean;
    StOfGroupe                    STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type;
    Quantite                      FAL_NETWORK_NEED.FAN_FREE_QTY%type;
    DElai                         FAL_NETWORK_SUPPLY.FAN_END_PLAN%type;
    CurFAL_NETWORK_SUPPLY         integer;
    ValBranchement                integer;

    type TEnrCursorApproOfProduct is record(
      FAL_NETWORK_SUPPLY_ID number
    , FAn_FREE_QTY          FAl_NETWORK_SUPPLY.FAn_FREE_QTY%type
    );

    cursor CUR_FAL_SUM_STOCK
    is
      select   *
          from FAL_SUM_STOCK
      order by FSS_FEFO_DATE
             , FAL_SUM_STOCK_ID;

    EnrCursorApproOfProduct       TEnrCursorApproOfProduct;
    EnrCurFalSumStock             CUR_FAL_SUM_STOCK%rowtype;
    lbTimeLimiteManagement        boolean;
    lbDeduct                      boolean;
    ldShiftDelay                  FAL_NETWORK_SUPPLY.FAN_END_PLAN%type;
    lnShiftProduct                number(9);
  begin
    PdtHasVersionOrCharacteristic  := fal_tools.ProductHasVersionOrCharacteris(PrmGOOD_ID) = 1;
    lbTimeLimiteManagement         := GCO_I_LIB_CHARACTERIZATION.IsTimeLimitManagement(PrmGOOD_ID) = 1;
    -- Identifier une somme de qtés dispo par groupe de caractérisations morphologique
    -- 10 --
    CreateFAL_SUM_STOCK(prmGOOD_ID, PrmLstStock, PdtHasVersionOrCharacteristic, PrmCompensationStockControle, prmLstControleStocksIDs, lbTimeLimiteManagement);
    -- Gérer itération sur les besoins du produit pour les stocks sélectionnés
    -- 11 --
    buffSql                        :=
      '    select DOC_POSITION_DETAIL_ID ' ||
      '         , PAC_THIRD_ID ' ||
      '         , FAN_FREE_QTY ' ||
      '         , FAN_BEG_PLAN ' ||
      '         , FAL_NETWORK_NEED_ID';

    if PdtHasVersionOrCharacteristic then
      buffsql  :=
        Buffsql ||
        ' , GCO_CHARACTERIZATION1_ID' ||
        ' , GCO_CHARACTERIZATION2_ID' ||
        ' , GCO_CHARACTERIZATION3_ID' ||
        ' , GCO_CHARACTERIZATION4_ID' ||
        ' , GCO_CHARACTERIZATION5_ID' ||
        ' , FAN_CHAR_VALUE1' ||
        ' , FAN_CHAR_VALUE2' ||
        ' , FAN_CHAR_VALUE3' ||
        ' , FAN_CHAR_VALUE4' ||
        ' , FAN_CHAR_VALUE5';
    end if;

    buffsql                        :=
      Buffsql ||
      '  from FAL_NETWORK_NEED FNN ' ||
      ' where GCO_GOOD_ID =    ' ||
      PrmGOOD_ID ||
      '   and not exists (select 1 from GCO_SERVICE     SER where FNN.GCO_GOOD_ID = SER.GCO_GOOD_ID)' ||
      '   and not exists (select 1 from GCO_PSEUDO_GOOD PSE where FNN.GCO_GOOD_ID = PSE.GCO_GOOD_ID)';

    if PrmLstStock is not null then
      BuffSql  := BuffSql || ' and STM_STOCK_ID in (' || PrmLstStock || ')';
    end if;

    if iUseMasterPlanRequirements = 0 then
      -- Il ne faut pas prendre en compte les besoins de propositions issues d'un plan directeur
      BuffSql  :=
        BuffSql ||
        ' and (select FAL_PIC_ID ' ||
        '        from FAL_LOT_PROP PROP ' ||
        '       where PROP.FAL_LOT_PROP_ID = FNN.FAL_LOT_PROP_ID) is null ' ||
        ' and (select FAL_PIC_ID ' ||
        '        from FAL_DOC_PROP PROP ' ||
        '       where PROP.FAL_DOC_PROP_ID = FNN.FAL_DOC_PROP_ID) is null ';
    end if;

    BuffSql                        := BuffSql || ' and FAN_FREE_QTY > 0 order by FAN_BEG_PLAN, FAL_NETWORK_NEED_ID for update';
    CursorBesoin                   := DBMS_SQL.open_cursor;
    DBMS_SQL.Parse(CursorBesoin, BuffSql, DBMS_SQL.NATIVE);
    DBMS_SQL.Define_column(CursorBesoin, 1, CurDOC_POSITION_DETAIl_ID);
    DBMS_SQL.Define_column(CursorBesoin, 2, CurPAC_THIRD_ID);
    DBMS_SQL.Define_column(CursorBesoin, 3, CurFAN_FREE_QTY);
    DBMS_SQL.Define_column(CursorBesoin, 4, CurFAN_BEG_PLAN);
    DBMS_SQL.Define_column(CursorBesoin, 5, CurFAL_NETWORK_NEED_ID);

    if PdtHasVersionOrCharacteristic then
      DBMS_SQL.Define_column(CursorBesoin, 6, CurGCO_CHARACTERIZATION1_ID);
      DBMS_SQL.Define_column(CursorBesoin, 7, CurGCO_CHARACTERIZATION2_ID);
      DBMS_SQL.Define_column(CursorBesoin, 8, CurGCO_CHARACTERIZATION3_ID);
      DBMS_SQL.Define_column(CursorBesoin, 9, CurGCO_CHARACTERIZATION4_ID);
      DBMS_SQL.Define_column(CursorBesoin, 10, CurGCO_CHARACTERIZATION5_ID);
      DBMS_SQL.Define_column(CursorBesoin, 11, CurFAN_CHAR_VALUE1, 30);
      DBMS_SQL.Define_column(CursorBesoin, 12, CurFAN_CHAR_VALUE2, 30);
      DBMS_SQL.Define_column(CursorBesoin, 13, CurFAN_CHAR_VALUE3, 30);
      DBMS_SQL.Define_column(CursorBesoin, 14, CurFAN_CHAR_VALUE4, 30);
      DBMS_SQL.Define_column(CursorBesoin, 15, CurFAN_CHAR_VALUE5, 30);
    end if;

    Ignore                         := DBMS_SQL.execute(CursorBesoin);

    while DBMS_SQL.fetch_rows(CursorBesoin) > 0 loop
      DBMS_SQL.column_value(CursorBesoin, 1, CurDOC_POSITION_DETAIL_ID);
      DBMS_SQL.column_value(CursorBesoin, 2, CurPAC_THIRD_ID);
      DBMS_SQL.column_value(CursorBesoin, 3, CurFAN_FREE_QTY);
      DBMS_SQL.column_value(CursorBesoin, 4, CurFAN_BEG_PLAN);
      DBMS_SQL.column_value(CursorBesoin, 5, CurFAL_NETWORK_NEED_ID);

      if PdtHasVersionOrCharacteristic then
        DBMS_SQL.column_value(CursorBesoin, 6, CurGCO_CHARACTERIZATION1_ID);
        DBMS_SQL.column_value(CursorBesoin, 7, CurGCO_CHARACTERIZATION2_ID);
        DBMS_SQL.column_value(CursorBesoin, 8, CurGCO_CHARACTERIZATION3_ID);
        DBMS_SQL.column_value(CursorBesoin, 9, CurGCO_CHARACTERIZATION4_ID);
        DBMS_SQL.column_value(CursorBesoin, 10, CurGCO_CHARACTERIZATION5_ID);
        DBMS_SQL.column_value(CursorBesoin, 11, CurFAN_CHAR_VALUE1);
        DBMS_SQL.column_value(CursorBesoin, 12, CurFAN_CHAR_VALUE2);
        DBMS_SQL.column_value(CursorBesoin, 13, CurFAN_CHAR_VALUE3);
        DBMS_SQL.column_value(CursorBesoin, 14, CurFAN_CHAR_VALUE4);
        DBMS_SQL.column_value(CursorBesoin, 15, CurFAN_CHAR_VALUE5);
      end if;

      ai1v1           := null;
      ai2v2           := null;
      ai3v3           := null;
      ai4v4           := null;
      ai5v5           := null;
      aV1             := null;
      aV2             := null;
      aV3             := null;
      aV4             := null;
      aV5             := null;

      if PdtHasVersionOrCharacteristic then
        -- Initialisation des valeur 1..5 des charactérisation de type version (1) ou caracteristique (2)
        if fal_tools.VersionOrCharacteristicType(CurGCO_CHARACTERIZATION1_ID) = 1 then
          ai1v1  := concat(CurGCO_CHARACTERIZATION1_ID, CurFAN_CHAR_VALUE1);
          aV1    := CurFAN_CHAR_VALUE1;
        end if;

        if fal_tools.VersionOrCharacteristicType(CurGCO_CHARACTERIZATION2_ID) = 1 then
          ai2v2  := concat(CurGCO_CHARACTERIZATION2_ID, CurFAN_CHAR_VALUE2);
          aV2    := CurFAN_CHAR_VALUE2;
        end if;

        if fal_tools.VersionOrCharacteristicType(CurGCO_CHARACTERIZATION3_ID) = 1 then
          ai3v3  := concat(CurGCO_CHARACTERIZATION3_ID, CurFAN_CHAR_VALUE3);
          aV3    := CurFAN_CHAR_VALUE3;
        end if;

        if fal_tools.VersionOrCharacteristicType(CurGCO_CHARACTERIZATION4_ID) = 1 then
          ai4v4  := concat(CurGCO_CHARACTERIZATION4_ID, CurFAN_CHAR_VALUE4);
          aV4    := CurFAN_CHAR_VALUE4;
        end if;

        if fal_tools.VersionOrCharacteristicType(CurGCO_CHARACTERIZATION5_ID) = 1 then
          ai5v5  := concat(CurGCO_CHARACTERIZATION5_ID, CurFAN_CHAR_VALUE5);
          aV5    := CurFAN_CHAR_VALUE5;
        end if;
      end if;

      ValBranchement  := 0;

      if PrmBesoinsLogistiquesGlobale = 1 then
        if     CurDOC_POSITION_DETAIL_ID is not null
           and (   PrmQueSurLesDocumentsGlobale = 0
                or (    PrmQueSurLesDocumentsGlobale = 1
                    and GetGAS_AUTO_ATTRIBUTION(CurDOC_POSITION_DETAIl_ID) = 1) ) then
          if GetC_PARTNER_STATUS(CurPaC_THIRD_ID) <> 2 then
            if GetAllocationType(CurPAC_THIRD_ID) <> 0 then
              -- B --
              ReconstructionAttribution2(CurFAL_NETWORK_NEED_ID, iUseMasterPlanProcurements, PrmMargeNegativeGlobale, prmlststock);
            else
              ValBranchement  := 0;
            end if;
          end if;
        else
          ValBranchement  := 1;
        end if;
      end if;

      if    PrmBesoinsLogistiquesGlobale = 0
         or ValBranchement = 1 then
        -- Quantité à couvrir
        Quantite  := CurFAN_FREE_QTY;

        -- Parcours des stock sélectionnés en tri FEFO (First Expried First Out si péremption et ou ré-analyse définit)
        for EnrCurFalSumStock in CUR_FAL_SUM_STOCK loop
          -- Plus de quantité libre pour le besoin.
          exit when Quantite = 0;
          -- 14 --
          lbDeduct  := false;

          -- Le produit est avec caractérisations morphologiques
          if PdtHasVersionOrCharacteristic then
            -- La couverture par le stock de besoins caractérisés se fait :
            -- quelque soit cfgFAL_ATTRIB_ON_CHARACT_MODE, toujours sur des stocks de même jeu de caractérisation.
            if ( (aV1 || aV2 || aV3 || aV4 || aV5) is not null) then
              -- Vérification de la concordance des valeurs de caractérisations.
              if     nvl(fal_tools.NullForNoMorpho(EnrCurFalSumStock.GCO_CHARACTERIZATION1_ID, EnrCurFalSumStock.FSS_CHARACTERIZATION_VALUE1), 'NULL') =
                                                                                                                                               nvl(aV1, 'NULL')
                 and nvl(fal_tools.NullForNoMorpho(EnrCurFalSumStock.GCO_CHARACTERIZATION2_ID, EnrCurFalSumStock.FSS_CHARACTERIZATION_VALUE2), 'NULL') =
                                                                                                                                                nvl(aV2, 'NULL')
                 and nvl(fal_tools.NullForNoMorpho(EnrCurFalSumStock.GCO_CHARACTERIZATION3_ID, EnrCurFalSumStock.FSS_CHARACTERIZATION_VALUE3), 'NULL') =
                                                                                                                                                nvl(aV3, 'NULL')
                 and nvl(fal_tools.NullForNoMorpho(EnrCurFalSumStock.GCO_CHARACTERIZATION4_ID, EnrCurFalSumStock.FSS_CHARACTERIZATION_VALUE4), 'NULL') =
                                                                                                                                                nvl(aV4, 'NULL')
                 and nvl(fal_tools.NullForNoMorpho(EnrCurFalSumStock.GCO_CHARACTERIZATION5_ID, EnrCurFalSumStock.FSS_CHARACTERIZATION_VALUE5), 'NULL') =
                                                                                                                                                nvl(aV5, 'NULL') then
                -- Le besoin est couvert par le stock, on demande le retrait de la quantité restant à couvrir de la somme
                -- du groupe de position de stock courant.
                lbDeduct  := true;
              end if;
            else
              -- La couverture de besoins non-caractérisés se fait de la manière suivante en fonction de la valeur de config FAL_ATTRIB_ON_CHARACT_MODE :
              --   1 (Pas de couverture par le stock, celui-ci étant toujours caractérisé)
              --   2 ou 3 (Sur des stocks tous jeux de caractérisation)
              --   4 (On considère que l'on ne gère pas les caractérisations morpho dans la base)
              if cAttribOnCharactMode <> 1 then
                -- Le besoin est couvert par le stock, on demande le retrait de la quantité restant à couvrir de la somme
                -- du groupe de position de stock courant.
                lbDeduct  := true;
              else
                exit;
              end if;
            end if;
          -- Produit sans caractérisation morphologique
          else
            -- Produit avec caractérisation(s) FEFO (péremption et/ou ré-analyse)
            if EnrCurFalSumStock.FSS_FEFO_DATE is not null then
              -- La date de validité de la position de stock couvre-t-elle la date du besoin ?
              if (EnrCurFalSumStock.FSS_FEFO_DATE > CurFAN_BEG_PLAN) then
                -- Le besoin est couvert par le stock, on demande le retrait de la quantité restant à couvrir de la somme
                -- du groupe de position de stock courant.
                lbDeduct  := true;
              end if;
            else
              -- Produit sans caractérisation(s) FEFO
              -- Le besoin est couvert par le stock, on demande le retrait de la quantité restant à couvrir de la somme
              -- du groupe de position de stock courant.
              lbDeduct  := true;
            end if;
          end if;

          -- Décompte de l'enregistrement de stock temporaire concerné, ainsi que de la quantité restant à couvrir.
          if lbDeduct then
            STOfGroupe  := greatest(0, EnrCurFalSumStock.FSS_SUM_ON_GROUP - Quantite);
            Quantite    := greatest(0, Quantite - EnrCurFalSumStock.FSS_SUM_ON_GROUP);
            UpdateRecordWithMorpho(EnrCurFalSumStock.FAL_SUM_STOCK_ID, STOfGroupe);
          end if;
        end loop;

        -- Quantité encore à couvrir par des approvisionnements ?
        if Quantite > 0 then
          Delai                 := CurFAN_BEG_PLAN;

          if PrmMargeNegativeGlobale = 0 then
            lnShiftProduct  := GetDecalageProduct(PrmGOOD_ID);

            -- Si le décalage est > au nbre de jours de décalage maximum calculés sur les calendriers
            if lnShiftProduct > FAL_LIB_CONSTANT.gCfgCBShiftLimit then
              ldShiftDelay  := Delai + lnShiftProduct;
            else
              ldShiftDelay  :=
                  FAL_SCHEDULE_FUNCTIONS.GetDecalageForwardDate(null, null, null, null, null, FAL_SCHEDULE_FUNCTIONS.GetDefaultCalendar, Delai, lnShiftProduct);
            end if;
          else
            ldShiftDelay  := null;   -- Pour indiquer que le délai n'aura pas d'importance
          end if;

          -- gérer itération pour chaque appro du produit
          -- 15 --
          buffSql2              := ' SELECT FAL_NETWORK_SUPPLY_ID, FAN_FREE_QTY';
          buffSql2              := BuffSql2 || ' FROM FAL_NETWORK_SUPPLY FNS WHERE FAN_FREE_QTY > 0 AND GCO_GOOD_ID = ' || PrmGOOD_iD;

          if ldShiftDelay is not null then
            BuffSql2  := BuffSql2 || ' AND';
            buffSql2  := BuffSql2 || ' (';
            buffSql2  := BuffSql2 || '   trunc(FNS.FAN_END_PLAN) <= ''' || trunc(ldShiftDelay) || '''';
            buffSql2  := BuffSql2 || ' )';
          end if;

          if    (PrmLstStock is not null)
             or (prmLstControleStocksIDs is not null) then
            if prmLstControleStocksIDs is null then
              BuffSql2  := BuffSql2 || ' AND FNS.STM_STOCK_ID in (' || PrmLstStock || ')';
            elsif PrmLstStock is null then
              BuffSql2  := BuffSql2 || ' AND FNS.STM_STOCK_ID in (' || prmLstControleStocksIDs || ')';
            else
              BuffSql2  := BuffSql2 || ' AND FNS.STM_STOCK_ID in (' || PrmLstStock || ',' || prmLstControleStocksIDs || ')';
            end if;
          end if;

          if iUseMasterPlanProcurements = 0 then
            -- Il ne faut pas prendre en compte les appros de propositions issues d'un plan directeur
            BuffSql2  :=
              BuffSql2 ||
              ' and (select FAL_PIC_ID ' ||
              '        from FAL_LOT_PROP PROP ' ||
              '       where PROP.FAL_LOT_PROP_ID = FNS.FAL_LOT_PROP_ID) is null ' ||
              ' and (select FAL_PIC_ID ' ||
              '        from FAL_DOC_PROP PROP ' ||
              '       where PROP.FAL_DOC_PROP_ID = FNS.FAL_DOC_PROP_ID) is null ';
          end if;

          if PdtHasVersionOrCharacteristic then
            -- Tenir compte des caractérisations si pdt avec caractérisations de type version ou caractéristique
            BuffSql2  := BuffSql2 || 'and';
            BuffSql2  := BuffSql2 || '(';
            BuffSql2  := BuffSql2 || ' (';
            BuffSql2  := BuffSql2 || '  (TO_NUMBER(PCS.PC_CONFIG.GetConfig(''FAL_ATTRIB_ON_CHARACT_MODE'')) = 1)';
            BuffSql2  := BuffSql2 || '  and';
            BuffSql2  := BuffSql2 || '  (';
            BuffSql2  := BuffSql2 || '      (';
            BuffSql2  := BuffSql2 || '	     :Ai1v1 || :Ai2v2 || :Ai3v3 || :Ai4v4 || :Ai5v5 is not null';
            BuffSql2  := BuffSql2 || '	     and';
            BuffSql2  :=
              BuffSql2 ||
              '   	 ((:Ai1v1 in (      concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1),
                                        concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2),
                                        concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3),
                                        concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4),
                                        concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)     )) or (:Ai1v1 is null ))';
            BuffSql2  := BuffSql2 || '	     and';
            BuffSql2  :=
              BuffSql2 ||
              '	     ((:Ai2v2 in (      concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1),
                                        concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2),
                                        concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3),
                                        concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4),
                                        concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)     )) or (:Ai2v2 is null ))';
            BuffSql2  := BuffSql2 || '	     and';
            BuffSql2  :=
              BuffSql2 ||
              '	     ((:Ai3v3 in (      concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1),
                                        concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2),
                                        concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3),
                                        concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4),
                                        concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)     )) or (:Ai3v3 is null ))';
            BuffSql2  := BuffSql2 || '	     and';
            BuffSql2  :=
              BuffSql2 ||
              '	     ((:Ai4v4 in (      concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1),
                                        concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2),
                                        concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3),
                                        concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4),
                                        concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)     )) or (:Ai4v4 is null ))';
            BuffSql2  := BuffSql2 || '	     and';
            BuffSql2  :=
              BuffSql2 ||
              '	     ((:Ai5v5 in (      concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1),
                                        concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2),
                                        concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3),
                                        concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4),
                                        concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)     )) or (:Ai5v5 is null ))';
            BuffSql2  := BuffSql2 || '	     )';
            BuffSql2  := BuffSql2 || '	     or';
            BuffSql2  := BuffSql2 || '	     (';
            BuffSql2  := BuffSql2 || '	       :Ai1v1 || :Ai2v2 || :Ai3v3 || :Ai4v4 || :Ai5v5 is null';
            BuffSql2  := BuffSql2 || '	       and      fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1)';
            BuffSql2  := BuffSql2 || '	           ||';
            BuffSql2  := BuffSql2 || '		            fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2)';
            BuffSql2  := BuffSql2 || '	           ||';
            BuffSql2  := BuffSql2 || '	                fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3)';
            BuffSql2  := BuffSql2 || '	           ||';
            BuffSql2  := BuffSql2 || '		            fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4)';
            BuffSql2  := BuffSql2 || '	           ||';
            BuffSql2  := BuffSql2 || '		            fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5) is null';
            BuffSql2  := BuffSql2 || '	     )';
            BuffSql2  := BuffSql2 || '  )';
            BuffSql2  := BuffSql2 || ')';
            BuffSql2  := BuffSql2 || 'OR';
            BuffSql2  := BuffSql2 || '(';
            BuffSql2  := BuffSql2 || '  (TO_NUMBER(PCS.PC_CONFIG.GetConfig(''FAL_ATTRIB_ON_CHARACT_MODE'')) <> 1)';
            BuffSql2  := BuffSql2 || '  and';
            BuffSql2  := BuffSql2 || '  (';
            BuffSql2  := BuffSql2 || '      (';
            BuffSql2  :=
              BuffSql2 ||
              '      ((:Ai1v1 in (      concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1),
                                        concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2),
                                        concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3),
                                        concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4),
                                        concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)     )) or (:Ai1v1 is null ))';
            BuffSql2  := BuffSql2 || '      and';
            BuffSql2  :=
              BuffSql2 ||
              '      ((:Ai2v2 in (      concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1),
                                        concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2),
                                        concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3),
                                        concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4),
                                        concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)     )) or (:Ai2v2 is null ))';
            BuffSql2  := BuffSql2 || '      and';
            BuffSql2  :=
              BuffSql2 ||
              '      ((:Ai3v3 in (      concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1),
                                        concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2),
                                        concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3),
                                        concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4),
                                        concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)     )) or (:Ai3v3 is null ))';
            BuffSql2  := BuffSql2 || '      and';
            BuffSql2  :=
              BuffSql2 ||
              '      ((:Ai4v4 in (      concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1),
                                        concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2),
                                        concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3),
                                        concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4),
                                        concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)     )) or (:Ai4v4 is null ))';
            BuffSql2  := BuffSql2 || '      and';
            BuffSql2  :=
              BuffSql2 ||
              '      ((:Ai5v5 in (      concat(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1),
                                        concat(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2),
                                        concat(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3),
                                        concat(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4),
                                        concat(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5)     )) or (:Ai5v5 is null ))';
            BuffSql2  := BuffSql2 || '      )';
            BuffSql2  := BuffSql2 || '      or';
            BuffSql2  := BuffSql2 || '      (';
            BuffSql2  := BuffSql2 || '              fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION1_ID, FNS.FAN_CHAR_VALUE1)';
            BuffSql2  := BuffSql2 || '      	    ||';
            BuffSql2  := BuffSql2 || '      		fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION2_ID, FNS.FAN_CHAR_VALUE2)';
            BuffSql2  := BuffSql2 || '      	    ||';
            BuffSql2  := BuffSql2 || '      	    fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION3_ID, FNS.FAN_CHAR_VALUE3)';
            BuffSql2  := BuffSql2 || '      	    ||';
            BuffSql2  := BuffSql2 || '      		fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION4_ID, FNS.FAN_CHAR_VALUE4)';
            BuffSql2  := BuffSql2 || '      	    ||';
            BuffSql2  := BuffSql2 || '      		fal_tools.NullForNoMorpho(FNS.GCO_CHARACTERIZATION5_ID, FNS.FAN_CHAR_VALUE5) is null';
            BuffSql2  := BuffSql2 || '      )';
            BuffSql2  := BuffSql2 || '  )';
            BuffSql2  := BuffSql2 || ' )';
            BuffSql2  := BuffSql2 || ')';
          end if;   -- Fin de if PdtHasVersionOrCharacteristic then

          buffSql2              := BuffSql2 || ' order by FNS.FAN_END_PLAN';
          buffSql2              := BuffSql2 || ' FOR UPDATE';
          CursorApproOfProduct  := DBMS_SQL.open_cursor;
          DBMS_SQL.Parse(CursorApproOfProduct, BuffSql2, DBMS_SQL.NATIVE);
          DBMS_SQL.Define_column(CursorApproOfProduct, 1, EnrCursorApproOfProduct.FAL_NETWORK_SUPPLY_ID);
          DBMS_SQL.Define_column(CursorApproOfProduct, 2, EnrCursorApproOfProduct.FAN_FREE_QTY);

          if PdtHasVersionOrCharacteristic then
            DBMS_SQL.BIND_VARIABLE(CursorApproOfProduct, 'Ai1v1', Ai1v1);
            DBMS_SQL.BIND_VARIABLE(CursorApproOfProduct, 'Ai2v2', Ai2v2);
            DBMS_SQL.BIND_VARIABLE(CursorApproOfProduct, 'Ai3v3', Ai3v3);
            DBMS_SQL.BIND_VARIABLE(CursorApproOfProduct, 'Ai4v4', Ai4v4);
            DBMS_SQL.BIND_VARIABLE(CursorApproOfProduct, 'Ai5v5', Ai5v5);
          end if;

          Ignore                := DBMS_SQL.execute(CursorApproOfProduct);

          while DBMS_SQL.fetch_rows(CursorApproOfProduct) > 0 loop
            DBMS_SQL.column_value(CursorApproOfProduct, 1, EnrCursorApproOfProduct.FAL_NETWORK_SUPPLY_ID);
            DBMS_SQL.column_value(CursorApproOfProduct, 2, EnrCursorApproOfProduct.FAN_FREE_QTY);

            -- 16 --
            if EnrCursorApproOfProduct.FAN_FREE_QTY >= Quantite then
              -- 18 --
              FAl_NETWORK.CreateAttribBesoinAppro(CurFAL_NETWORK_NEED_ID, EnrCursorApproOfProduct.FAL_NETWORK_SUPPLY_ID, Quantite);
              exit;   -- 19 Besoin suivant
            else
              -- 17 --
              FAl_NETWORK.CreateAttribBesoinAppro(CurFAL_NETWORK_NEED_ID, EnrCursorApproOfProduct.FAL_NETWORK_SUPPLY_ID, EnrCursorApproOfProduct.FAN_FREE_QTY);
              Quantite  := Quantite - EnrCursorApproOfProduct.FAN_FREE_QTY;
            end if;
          end loop;

          DBMS_SQL.close_cursor(CursorApproOfProduct);
        -- Fin de  itération pour chaque appro du produit
        end if;   -- Fin if Quantite > 0
      end if;   -- Fin if PrmBesoinsLogistiquesGlobale = 0
    end loop;   -- WHILE sur CursorBesoin

    DBMS_SQL.close_cursor(CursorBesoin);
  end PartieGlobale;

  /**
  * procedure : SuppAttribSurApproBesoinLog
  * Description : Suppression attribution besoins logistique sur appro
  *
  * @created
  * @lastUpdate
  * @public
  * @param   PrmGCO_GOOD_ID   : Bien
  * @param   PrmLstStock      : Liste des stocks pris en compte
  */
  procedure SuppAttribSurApproBesoinLog(PrmGCO_GOOD_ID number, PrmlstStock varchar2)
  is
    BuffSql                  varchar2(2000);
    Ignore                   integer;
    CursorAttrib             integer;
    CurrentLINK_ID           number;
    CurrentNEED_ID           number;
    CurrentSUPPLY_ID         number;
    CurrentSTOCK_POSITION_ID number;
    CurrentSTM_LOCATION_ID   number;
    CurrentFLN_QTY           FAl_NETWORK_LINK.FLN_QTY%type;
  begin
    BuffSql       := ' SELECT';
    buffSql       := BuffSql || '  a.FAL_NETWORK_LINK_ID,';
    buffSql       := BuffSql || '  a.FAL_NETWORK_NEED_ID,';
    buffSql       := BuffSql || '  a.FAL_NETWORK_SUPPLY_ID,';
    buffSql       := BuffSql || '  a.STM_STOCk_POSITION_ID,';
    buffSql       := BuffSql || '  a.STM_LOCATION_ID,';
    buffSql       := BuffSql || '  a.FLN_QTY';
    buffSql       := BuffSql || ' FROM';
    buffSql       := BuffSql || '  FAL_NETWORK_LINK a, FAL_NETWORK_NEED b';
    buffSql       := BuffSql || '  WHERE b.GCO_GOOD_ID = ' || PrmGCO_GOOD_ID;
    buffSql       := BuffSql || '  AND a.FAL_NETWORK_NEED_ID = b.FAL_NETWORK_NEED_ID';

    if PrmLstStock is not null then
      buffSql  := BuffSql || ' and b.STM_STOCK_ID IN (' || PrmLstStock || ')';
    end if;

    BUffSql       := BuffSql || '  and not exists (select 1 from gco_service     ser where b.gco_good_id = ser.gco_good_id)';
    BUffSql       := BuffSql || '  and not exists (select 1 from GCO_PSEUDO_GOOD pse where b.gco_good_id = pse.gco_good_id)';
    buffSql       := BuffSql || ' AND ';
    buffSql       := BuffSql || ' DOC_POSITION_DETAIL_ID IS NOT NULL';
    buffSql       := BuffSql || ' AND ';
    buffSql       := BuffSql || ' (';
    buffSql       := BuffSql || '   doc_position_id is null';
    buffSql       := BuffSql || '   or';
    buffSql       := BuffSql || '   doc_position_id in (select doc_position_id from doc_position where c_gauge_type_pos not in (7,8,9,10))';
    buffSql       := BuffSql || ' )';
    buffSql       := BuffSql || '   AND ';
    buffSql       := BuffSql || ' (';
    buffSql       := BuffSql || '   doc_gauge_id is null';
    buffSql       := BuffSql || '   or';
    buffSql       := BuffSql || '   doc_gauge_id not in (select doc_gauge_id from fal_prop_def where c_prop_type=4)';
    buffSql       := BuffSql || ' )';
    buffSql       := BuffSql || ' AND';
    buffSql       := BuffSql || ' STM_STOCK_POSITION_ID IS NULL';
    buffSql       := BuffSql || ' FOR UPDATE';
    CursorAttrib  := DBMS_SQL.open_cursor;
    DBMS_SQL.Parse(CursorAttrib, BuffSql, DBMS_SQL.NATIVE);
    DBMS_SQL.Define_column(CursorAttrib, 1, CurrentLINK_ID);
    DBMS_SQL.Define_column(CursorAttrib, 2, CurrentNEED_ID);
    DBMS_SQL.Define_column(CursorAttrib, 3, CurrentSUPPLY_ID);
    DBMS_SQL.Define_column(CursorAttrib, 4, CurrentSTOCK_POSITION_ID);
    DBMS_SQL.Define_column(CursorAttrib, 5, CurrentSTM_LOCATION_ID);
    DBMS_SQL.Define_column(CursorAttrib, 6, CurrentFLN_QTY);
    Ignore        := DBMS_SQL.execute(CursorAttrib);

    while DBMS_SQL.fetch_rows(CursorAttrib) > 0 loop
      DBMS_SQL.column_value(CursorAttrib, 1, CurrentLINK_ID);
      DBMS_SQL.column_value(CursorAttrib, 2, CurrentNEED_ID);
      DBMS_SQL.column_value(CursorAttrib, 3, CurrentSUPPLY_ID);
      DBMS_SQL.column_value(CursorAttrib, 4, CurrentSTOCK_POSITION_ID);
      DBMS_SQL.column_value(CursorAttrib, 5, CurrentSTM_LOCATION_ID);
      DBMS_SQL.column_value(CursorAttrib, 6, CurrentFLN_QTY);
      SuppressionAttribution(CurrentLINK_ID, CurrentNEED_ID, CurrentSUPPLY_ID, CurrentSTOCK_POSITION_ID, CurrentSTM_LOCATION_ID, CurrentFLN_QTY);
    end loop;

    DBMS_SQL.close_cursor(CursorAttrib);
-- Fin itération sur les attributions d'un besoin du produit pour les stocks sélectionnés
  end SuppAttribSurApproBesoinLog;

  /**
  * procedure : GenereAttribTracabComplete
  * Description : Génération Attributions pour les produits en tracabilité complète
  *
  * @created
  * @lastUpdate
  * @public
  * @param   PrmGCO_GOOD_ID   : bien
  * @param   PrmLstStock : Liste des stocks
  */
  procedure GenereAttribTracabComplete(PrmGCO_GOOD_ID GCO_GOOD.GCO_GOOD_ID%type, PrmLstStock varchar)
  is
    cursor crRequirements
    is
      select     GCO_GOOD_ID
               , PAC_THIRD_ID
               , FAN_FREE_QTY
               , FAL_NETWORK_NEED_ID
               , STM_STOCK_ID
               , STM_LOCATION_ID
               , GCO_CHARACTERIZATION1_ID
               , GCO_CHARACTERIZATION2_ID
               , GCO_CHARACTERIZATION3_ID
               , GCO_CHARACTERIZATION4_ID
               , GCO_CHARACTERIZATION5_ID
               , FAN_CHAR_VALUE1
               , FAN_CHAR_VALUE2
               , FAN_CHAR_VALUE3
               , FAN_CHAR_VALUE4
               , FAN_CHAR_VALUE5
               , FAN_BEG_PLAN
            from FAL_NETWORK_NEED
               , (select nvl(PDT_SCALE_LINK, 0) PDT_SCALE_LINK
                    from GCO_PRODUCT
                   where GCO_GOOD_ID = PrmGCO_GOOD_ID) PDT
           where GCO_GOOD_ID = PrmGCO_GOOD_ID
             and (       cAllReqComplTrace = 0
                     and (   FAL_LOT_MATERIAL_LINK_ID is not null
                          or FAL_LOT_MAT_LINK_PROP_ID is not null)
                  or cAllReqComplTrace = 1)
             and FAN_FREE_QTY > 0
             and FAN_BEG_PLAN < sysdate + PDT.PDT_SCALE_LINK
             and (   PrmLstStock is null
                  or instr(',' || PrmLstStock || ',', ',' || STM_STOCK_ID || ',') <> 0)
        order by FAN_BEG_PLAN
      for update;

    cursor CGlobalASC
    is
      select     ATC_LOT
            from FAL_ALGO_TRACAB_COMPLETE_POS
        order by ATC_SUM_FOR_LOT_GROUP asc
               , ATC_LOT asc
      for update;

    lnIndex                       number(12);
    aPDT_FULL_TRACABILITY_COEF    GCO_PRODUCT.PDT_FULL_TRACABILITY_COEF%type;
    aPDT_FULL_TRACABILITY_RULE    GCO_PRODUCT.PDT_FULL_TRACABILITY_RULE%type;
    SommePositionSelection        STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type;
    UseAlgoTracabiliteCompleteLot boolean;
    QtePossible                   number(15, 4);
    UsedLot                       number;
    LastLot                       varchar2(30);
    valueCar1                     STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type;
    valueCar2                     STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type;
    valueCar3                     STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type;
    valueCar4                     STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type;
    valueCar5                     STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type;
    IdCar1                        GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    IdCar2                        GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    IdCar3                        GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    IdCar4                        GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    IdCar5                        GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lnQtyToLink                   STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type;
    PdtHasVersionOrCharacteristic boolean;
    lnFIFO                        number(1)                                              := 0;
    lnLIFO                        number(1)                                              := 0;
    lnTimeLimit                   number(1)                                              := 0;
    liSortType                    integer                                                := 0;
    lnStockId                     STM_STOCK.STM_STOCK_ID%type;
    lnLocationId                  STM_LOCATION.STM_LOCATION_ID%type;
    liTraceCoef                   GCO_PRODUCT.PDT_FULL_TRACABILITY_COEF%type;
    lbFound                       boolean;
    lnAvailQty                    STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type;
  begin
    PdtHasVersionOrCharacteristic  := FAL_TOOLS.ProductHasVersionOrCharacteris(PrmGCO_GOOD_ID) = 1;

    -- Récupère le coefficient de traçabilité permettant de connaitre le nb maxi de positions autorisées.
    select decode(nvl(PDT_FULL_TRACABILITY_COEF, 0), 0, 1, PDT_FULL_TRACABILITY_COEF)
         , nvl(PDT_FULL_TRACABILITY_RULE, 0)
      into aPDT_FULL_TRACABILITY_COEF
         , aPDT_FULL_TRACABILITY_RULE
      from GCO_PRODUCT
     where GCO_GOOD_ID = PrmGCO_GOOD_ID;

    for tplRequirements in crRequirements loop
      lnStockId                      := tplRequirements.STM_STOCK_ID;
      lnLocationId                   := tplRequirements.STM_LOCATION_ID;
      -- Initialisation des valeur 1..5 des charactérisation de type version (1) ou caracteristique (2)
      ValueCar1                      := null;
      ValueCar2                      := null;
      ValueCar3                      := null;
      ValueCar4                      := null;
      ValueCar5                      := null;
      IdCar1                         := null;
      IdCar2                         := null;
      IdCar3                         := null;
      IdCar4                         := null;
      IdCar5                         := null;

      if PdtHasVersionOrCharacteristic then
        if fal_tools.VersionOrCharacteristicType(tplRequirements.GCO_CHARACTERIZATION1_ID) = 1 then
          valueCar1  := tplRequirements.FAN_CHAR_VALUE1;
          IdCar1     := tplRequirements.GCO_CHARACTERIZATION1_ID;
        end if;

        if fal_tools.VersionOrCharacteristicType(tplRequirements.GCO_CHARACTERIZATION2_ID) = 1 then
          valueCar2  := tplRequirements.FAN_CHAR_VALUE2;
          IdCar2     := tplRequirements.GCO_CHARACTERIZATION2_ID;
        end if;

        if fal_tools.VersionOrCharacteristicType(tplRequirements.GCO_CHARACTERIZATION3_ID) = 1 then
          valueCar3  := tplRequirements.FAN_CHAR_VALUE3;
          IdCar3     := tplRequirements.GCO_CHARACTERIZATION3_ID;
        end if;

        if fal_tools.VersionOrCharacteristicType(tplRequirements.GCO_CHARACTERIZATION4_ID) = 1 then
          valueCar4  := tplRequirements.FAN_CHAR_VALUE4;
          IdCar4     := tplRequirements.GCO_CHARACTERIZATION4_ID;
        end if;

        if fal_tools.VersionOrCharacteristicType(tplRequirements.GCO_CHARACTERIZATION5_ID) = 1 then
          valueCar5  := tplRequirements.FAN_CHAR_VALUE5;
          IdCar5     := tplRequirements.GCO_CHARACTERIZATION5_ID;
        end if;
      end if;

      -- Récupère les informations des types chronoloqique
      GCO_I_LIB_CHARACTERIZATION.GetChronologicalType(iGoodID => tplRequirements.GCO_GOOD_ID, ioFIFO => lnFIFO, ioLIFO => lnLIFO, ioTimeLimit => lnTimeLimit);
      -- Déterminer l'ordre de tri des positions de stock
      liSortType                     := GetSortType(lnFIFO, lnLIFO, lnTimeLimit);
      /* L'usage de l'algo spécial pour la traçabilité complète sur les produits ayant une caractérisation lot est possible seulement
         si le produit est géré en lot mais qu'il n'y pas de caractérisation FIFO ou LIFO */
      UseAlgoTracabiliteCompleteLot  :=     GCO_I_LIB_CHARACTERIZATION.IsLotChar(tplRequirements.GCO_GOOD_ID) = 1
                                        and not(   lnLIFO = 1
                                                or lnFIFO = 1);
      lnQtyToLink                    := nvl(tplRequirements.FAN_FREE_QTY, 0);
      lnIndex                        := 0;

      delete from FAL_ALGO_TRACAB_COMPLETE_POS;

      if not UseAlgoTracabiliteCompleteLot then
        /***** ALGO BASIC *****/

        -- gérer itération sur les positions de stocks
        for tplStockPosition in crStockPosition(ai1v1                  => concat(idcar1, valuecar1)
                                              , ai2v2                  => concat(idcar2, valuecar2)
                                              , ai3v3                  => concat(idcar3, valuecar3)
                                              , ai4v4                  => concat(idcar4, valuecar4)
                                              , ai5v5                  => concat(idcar5, valuecar5)
                                              , iGoodId                => tplRequirements.GCO_GOOD_ID
                                              , iThirdId               => tplRequirements.PAC_THIRD_ID
                                              , iTimeLimitManagement   => lnTimeLimit
                                              , iDate                  => tplRequirements.FAN_BEG_PLAN
                                              , iStockListId           => PrmLstStock
                                              , iStockId               => lnStockId
                                              , iLocationId            => lnLocationId
                                              , iSortOnChrono          => liSortType
                                               ) loop
          if lnIndex >= aPDT_FULL_TRACABILITY_COEF then
            exit;
          end if;

          lnIndex  := lnIndex + 1;

          insert into FAL_ALGO_TRACAB_COMPLETE_POS
                      (STM_STOCK_POSITION_ID
                     , STM_LOCATION_ID
                     , ATC_AVAILABLE_QUANTITY
                     , ATC_SELECTED
                      )
               values (tplStockPosition.STM_STOCK_POSITION_ID
                     , tplStockPosition.STM_LOCATION_ID
                     , tplStockPosition.SPO_AVAILABLE_QUANTITY
                     , 1   -- ATC_SELECTED
                      );
        end loop;

        -- 1) Vérifier que la somme des disponible de la table temporaire Algo couvre bien
        --    le besoin
        select sum(ATC_AVAILABLE_QUANTITY)
          into SommePositionSelection
          from FAL_ALGO_TRACAB_COMPLETE_POS;

        if SommePositionSelection >= lnQtyToLink then
          -- OUI
            /* Parcours des enregistrements de la table temporaire précédemment sélectionnés */
          for tplTrace in (select   STM_STOCK_POSITION_ID
                                  , STM_LOCATION_ID
                                  , ATC_AVAILABLE_QUANTITY
                               from FAL_ALGO_TRACAB_COMPLETE_POS
                              where ATC_SELECTED = 1
                           order by ATC_AVAILABLE_QUANTITY asc) loop
            exit when(lnQtyToLink <= 0);
            -- Création Attribution Besoin Stock
            Fal_Network.CreateAttribBesoinStock(tplRequirements.FAL_NETWORK_NEED_ID
                                              , tplTrace.STM_STOCK_POSITION_ID
                                              , tplTrace.STM_LOCATION_ID
                                              , least(tplTrace.ATC_AVAILABLE_QUANTITY, lnQtyToLink)
                                               );
            lnQtyToLink  := lnQtyToLink - tplTrace.ATC_AVAILABLE_QUANTITY;
          end loop;
        -- NON pas assez de dispo: impossible d'affecter on passe au besoin suivant
        end if;
      end if;

      if UseAlgoTracabiliteCompleteLot then
        /*********************************************************************************
         ALGO SPECIAL TRACABILITE SUR PDT AVEC CARACTERISATION LOT (mais non FIFO ou LIFO)
         *********************************************************************************/

        -- Selection des positions de stock supérieures à 0 du produit sur l'emplacement et ayant même valeur
        -- de caractérisations pour les caractérisations de type version ou caractéristique.
        for tplStockPosition in crStockPosition(ai1v1                  => concat(idcar1, valuecar1)
                                              , ai2v2                  => concat(idcar2, valuecar2)
                                              , ai3v3                  => concat(idcar3, valuecar3)
                                              , ai4v4                  => concat(idcar4, valuecar4)
                                              , ai5v5                  => concat(idcar5, valuecar5)
                                              , iGoodId                => tplRequirements.GCO_GOOD_ID
                                              , iThirdId               => tplRequirements.PAC_THIRD_ID
                                              , iTimeLimitManagement   => lnTimeLimit
                                              , iDate                  => tplRequirements.FAN_BEG_PLAN
                                              , iStockListId           => PrmLstStock
                                              , iStockId               => lnStockId
                                              , iLocationId            => lnLocationId
                                              , iSortOnChrono          => liSortType
                                               ) loop
          lnIndex  := lnIndex + 1;

          insert into FAL_ALGO_TRACAB_COMPLETE_POS
                      (STM_STOCK_POSITION_ID
                     , STM_LOCATION_ID
                     , ATC_AVAILABLE_QUANTITY
                     , ATC_SELECTED
                     , ATC_INDICE
                     , ATC_LOT
                     , ATC_SUM_FOR_LOT_GROUP
                      )
               values (tplStockPosition.STM_STOCK_POSITION_ID
                     , tplStockPosition.STM_LOCATION_ID
                     , tplStockPosition.SPO_AVAILABLE_QUANTITY
                     , 0
                     , lnIndex
                     , tplStockPosition.SPO_SET
                     , 0
                      );
        end loop;

        -- Mettre à jour ATC_SUM_FOR_LOT_GROUP
        update FAL_ALGO_TRACAB_COMPLETE_POS A
           set ATC_SUM_FOR_LOT_GROUP = (select sum(ATC_AVAILABLE_QUANTITY)
                                          from FAL_ALGO_TRACAB_COMPLETE_POS B
                                         where A.ATC_LOT = B.ATC_LOT);

        if aPDT_FULL_TRACABILITY_RULE = 0 then
          /* FULL_TRACABILITY_RULE = 0 : Favoriser conso des plus grands */
          UsedLot      := 0;
          LastLot      := null;
          QtePossible  := 0;

          -- Note: Les indices ne sont pas utilisés dans cet Algo.

          --Lecture de la table temporaire Algo triée selon la somme des groupes de lot décroissant, les lots (peu importe) et les quantités dispo (décroissant)
          for tplTrace in (select     ATC_LOT
                                    , ATC_SUM_FOR_LOT_GROUP
                                 from FAL_ALGO_TRACAB_COMPLETE_POS
                             order by ATC_SUM_FOR_LOT_GROUP desc
                                    , ATC_LOT
                                    , ATC_AVAILABLE_QUANTITY desc
                           for update) loop
            if    LastLot is null
               or Lastlot <> tplTrace.ATC_LOT then
              -- On a un nouveau lot
              LastLot      := tplTrace.ATC_LOT;
              -- On affecte la Qté du groupe
              QtePossible  := QtePossible + tplTrace.ATC_SUM_FOR_LOT_GROUP;

              /* Tant qu'on n'atteint pas le coeff, on peut sélectionner. Pour le dernier lot sélectionné (UsedLot = aPDT_FULL_TRACABILITY_COEF après sélection),
                 il faut que toute la quantité à attribuer puisse être prise. */
              if    (UsedLot < aPDT_FULL_TRACABILITY_COEF - 1)
                 or (lnQtyToLink <= QtePossible) then
                -- On sélectionne toutes les positions de ce même lot
                update FAL_ALGO_TRACAB_COMPLETE_POS
                   set ATC_SELECTED = 1
                 where ATC_LOT = tplTrace.ATC_LOT;

                UsedLot  := UsedLot + 1;
              else
                exit;
              end if;
            end if;
          end loop;

          /* Si toute la quantité peut être attribuée ou s'il y a moins de lots sélectionnés que ne l'autorise le coeff (dans ce cas, on attribue et ce sera complété par proposition */
            /* Parcours des enregistrements de la table temporaire précédemment sélectionnés */
          for tplTrace in (select   STM_STOCK_POSITION_ID
                                  , STM_LOCATION_ID
                                  , ATC_AVAILABLE_QUANTITY
                               from FAL_ALGO_TRACAB_COMPLETE_POS
                              where ATC_SELECTED = 1
                           order by ATC_AVAILABLE_QUANTITY asc) loop
            exit when(lnQtyToLink <= 0);
            -- Création Attribution Besoin Stock
            Fal_Network.CreateAttribBesoinStock(tplRequirements.FAL_NETWORK_NEED_ID
                                              , tplTrace.STM_STOCK_POSITION_ID
                                              , tplTrace.STM_LOCATION_ID
                                              , least(tplTrace.ATC_AVAILABLE_QUANTITY, lnQtyToLink)
                                               );
            lnQtyToLink  := lnQtyToLink - tplTrace.ATC_AVAILABLE_QUANTITY;
          end loop;
        end if;

        if aPDT_FULL_TRACABILITY_RULE = 1 then
          /* FULL_TRACABILITY_RULE = 1 : Favoriser conso des plus petits */
          lnIndex      := 0;
          LastLot      := null;

          /* Mise à jour de ATC_INDICE :
             - l'indice permet de trier les lots par ordre de quantité disponible croissante (Qté dispo par référence de lot)
             - les positions de lots identiques ont le même indice */
          for tplTrace in CGlobalASC loop
            /* incrément de l'indice au changement de lot seulement */
            if    LastLot is null
               or Lastlot <> tplTrace.ATC_LOT then
              LastLot  := tplTrace.ATC_LOT;
              lnIndex  := lnIndex + 1;
            end if;

            -- Mise à jour de l'indice
            update FAL_ALGO_TRACAB_COMPLETE_POS
               set ATC_INDICE = lnIndex
             where current of CGlobalASC;
          end loop;

          /* liTraceCoef indique combien de lots on peut encore sélectionner */
          liTraceCoef  := aPDT_FULL_TRACABILITY_COEF;
          lbFound      := false;

          loop
            for tplTrace in (select   sum(ATC_AVAILABLE_QUANTITY) AVAIL_QTY
                                    , ATC_INDICE
                                 from FAL_ALGO_TRACAB_COMPLETE_POS
                             group by ATC_INDICE
                             order by ATC_INDICE) loop
              /* Recherche de la quantité attribuable avec l'indice courant + autant que le coef restant de taçabilité nous le permet
                 de quantité inférieure (indice plus petit) */
              select nvl(sum(ATC_AVAILABLE_QUANTITY), 0)
                into lnAvailQty
                from FAL_ALGO_TRACAB_COMPLETE_POS
               where ATC_INDICE <= tplTrace.ATC_INDICE
                 and ATC_INDICE > tplTrace.ATC_INDICE - liTraceCoef;

              if lnAvailQty >= lnQtyToLink then
                /* Cet enregistrement plus des plus petits que lui nous permet de tout attribuer en respectant le coeff. On le sélectionne puis on recommence
                   la recherche depuis le début avec la quantité restant à attribuer sur un nombre de lot -1 */
                update FAL_ALGO_TRACAB_COMPLETE_POS trace
                   set ATC_SELECTED = 1
                 where ATC_INDICE = tplTrace.ATC_INDICE;

                lbFound      := true;
                lnQtyToLink  := lnQtyToLink - tplTrace.AVAIL_QTY;
                liTraceCoef  := liTraceCoef - 1;
                exit;
              end if;
            end loop;

            exit when(liTraceCoef <= 0)
                  or (lnQtyToLink <= 0)
                  or (not lbFound);
          end loop;

          lnQtyToLink  := nvl(tplRequirements.FAN_FREE_QTY, 0);

          /* Création des attributions */
          if lbFound then
            /* Parcours des enregistrements de la table temporaire précédemment sélectionnés */
            for tplTrace in (select   STM_STOCK_POSITION_ID
                                    , STM_LOCATION_ID
                                    , ATC_AVAILABLE_QUANTITY
                                 from FAL_ALGO_TRACAB_COMPLETE_POS
                                where ATC_SELECTED = 1
                             order by ATC_AVAILABLE_QUANTITY asc) loop
              exit when(lnQtyToLink <= 0);
              -- Création Attribution Besoin Stock
              Fal_Network.CreateAttribBesoinStock(tplRequirements.FAL_NETWORK_NEED_ID
                                                , tplTrace.STM_STOCK_POSITION_ID
                                                , tplTrace.STM_LOCATION_ID
                                                , least(tplTrace.ATC_AVAILABLE_QUANTITY, lnQtyToLink)
                                                 );
              lnQtyToLink  := lnQtyToLink - tplTrace.ATC_AVAILABLE_QUANTITY;
            end loop;
          else
            /* On attribue sur les lots de plus petite quantité en prenant les N premiers lots où N = Coeff de traça -1. On laisse donc un lot possible qui sera créé par le calcul des besoins */
            for tplTrace in (select   ATC_INDICE
                                    , STM_STOCK_POSITION_ID
                                    , STM_LOCATION_ID
                                    , ATC_AVAILABLE_QUANTITY
                                 from FAL_ALGO_TRACAB_COMPLETE_POS
                             order by ATC_INDICE asc) loop
              exit when(lnQtyToLink <= 0)
                    or (tplTrace.ATC_INDICE >= aPDT_FULL_TRACABILITY_COEF);
              -- Création Attribution Besoin Stock
              Fal_Network.CreateAttribBesoinStock(tplRequirements.FAL_NETWORK_NEED_ID
                                                , tplTrace.STM_STOCK_POSITION_ID
                                                , tplTrace.STM_LOCATION_ID
                                                , least(tplTrace.ATC_AVAILABLE_QUANTITY, lnQtyToLink)
                                                 );
              lnQtyToLink  := lnQtyToLink - tplTrace.ATC_AVAILABLE_QUANTITY;
            end loop;
          end if;
        end if;

        -- Vider la table de l'aglo pour le besoin suivant
        delete      FAL_ALGO_TRACAB_COMPLETE_POS;
      end if;   -- Fin de if UseAlgoTracabiliteCompleteLot then
    end loop;
  end GenereAttribTracabComplete;

  /**
  * procedure : ReconstructionAttribTracCompl
  * Description Reconstruction des attributions pour la traçabilité complète
  *
  * @created
  * @lastUpdate
  * @param   PrmLstStock   : Liste des stocks sélectionnés
  */
  procedure ReconstructionAttribTracCompl(PrmLstStock varchar)
  is
    cursor crGood
    is
      select Bien.GCO_GOOD_ID
        from GCO_GOOD Bien
           , GCO_PRODUCT Product
       where Product.GCO_GOOD_ID = Bien.GCO_GOOD_ID
         -- Ne pas prendre les Services
         and not exists(select 1
                          from gco_service ser
                         where Bien.gco_good_id = ser.gco_good_id)
         -- Ni les pseudos biens.
         and not exists(select 1
                          from GCO_PSEUDO_GOOD pse
                         where Bien.gco_good_id = pse.gco_good_id);
  begin
    for tplGood in crGood loop
      -- Supprimer toutes les attributions de besoins fabrication pour le Pdt en cours
      -- Sur les stocks sélectionnés
      SuppAttribSurNeedFab(tplGood.GCO_GOOD_ID, PrmLstStock);
      -- génération attribution Traça Complète
      GenereAttribTracabComplete(tplGood.GCO_GOOD_ID, PrmLstStock);
    end loop;
  end ReconstructionAttribTracCompl;

  function GetStockControlIDFromConfig
    return varchar2
  is
    LstControleStocksIDs varchar2(4000);
    LstControleStocks    varchar2(4000);
    aSTO_DESCRIPTION     STM_STOCK.STO_DESCRIPTION%type;
  begin
    LstControleStocksIDs  := '';
    LstControleStocks     := PCS.PC_CONFIG.GetConfig('PPS_STOCK_CTRL');

    loop
      exit when LstControleStocks is null;
      aSTO_DESCRIPTION   := substr(LstControleStocks, instr(LstControleStocks, ';', -1) + 1, length(LstControleStocks) );

      if aSTO_DESCRIPTION is not null then
        if LstControleStocksIDs is not null then
          LstControleStocksIDs  := LstControleStocksIDs || ',';
        end if;

        LstControleStocksIDs  := LstControleStocksIDs || FAL_TOOLS.GetSTM_STOCK_ID(aSTO_DESCRIPTION);
      end if;

      LstControleStocks  := substr(LstControleStocks, 1, instr(LstControleStocks, ';', -1) - 1);
    end loop;

    return LstControleStocksIDs;
  exception
    when others then
      raise_application_error(-20001, PCS.PC_FUNCTIONS.TranslateWord('La valeur de la configuration PPS_STOCK_CTRL est probablement incorrecte.') );
  end GetStockControlIDFromConfig;

  /**
  * procedure : ReconstructionAttribs
  * Description : Lancement des procédures de reconstruction, ré-actualisation des
  *               attributions
  *
  * @created
  * @lastUpdate
  * @public
  * @param   PrmReconstructionPartielle     : Reconstruction partielle
  * @param   PrmReactualisation             : Partielle -> Ré-actualisation des attributions
  * @param   PrmReconstruction              : Partielle -> Re-Construction
  * @param   PrmQueSurLesDocumentsPartielle : Partielle -> Que sur les documents à attrib directes
  * @param   PrmPAC_THIRD_ID                : Tiers
  * @param   PrmReconstructionGlobale       : Reconstruction globale
  * @param   PrmBesoinsLogistiquesGlobale   : Globale -> Besoin log selon mode de gestion client
  * @param   PrmQueSurLesDocumentsGlobale   : Globale -> Que sur les documents à attrib directes
  * @param   PrmMargeNegativeGlobale        : Attrib sur appro même si marge négative
  * @param   PrmCompensationStockControle   : Compensation des stock de contrôle
  * @param   PrmGCO_GOOD_ID                 : Produit
  * @param   PrmGCO_GOOD_CATEGORY_ID        : Catégorie de produit
  * @param   PrmDIC_CATEGORY_FREE_2_ID      : Dico Catégorie de produit
  * @param   PrmCalculGlobal                : Calcul Global (tous stocks)
  * @param   PrmlstStock                    : Liste des stocks pris en compte
  * @param   iUseMasterPlanProcurements     : Prise en compte des appros issus du plan directeur
  * @param   iUseMasterPlanRequirements     : Prise en compte des besoins issus du plan directeur
  * @param   PrmFAL_PIC_ID                  : Plan directeur
  * @param   PrmFPL_SESSION_ID              : Session
  * @param   PrmReconstructionComposAttrStk : Reconstruction des besoin fab sur stock
  * @param   PrmReconsBesOnProductMode      : Besoin log selon mode de gestion client
  * @param   PrmWithoutLogisticReqrmts      : Conserver les attributions log existantes
  * @param   iRedoSSTAAttrStk               : Reconstruction des besoins de commandes d'achat Sous-traitance sur stock
  * @param   iPreserveAttribOnSSTAStock     : Conserver les attributions sur stock sous-traitants.
  * @param   iDeleteExpiredAttrib           : Supprime toutes les attributions périmées, dépassées ou hors prévisionnel.
  */
  procedure ReconstructionAttribs(
    PrmReconstructionPartielle     integer
  , PrmReactualisation             integer
  , PrmReconstruction              integer
  , PrmQueSurLesDocumentsPartielle integer
  , PrmPAC_THIRD_ID                number
  , PrmReconstructionGlobale       integer
  , PrmBesoinsLogistiquesGlobale   integer
  , PrmQueSurLesDocumentsGlobale   integer
  , PrmMargeNegativeGlobale        integer
  , PrmCompensationStockControle   integer
  , PrmGCO_GOOD_ID                 number
  , PrmGCO_GOOD_CATEGORY_ID        number
  , PrmDIC_CATEGORY_FREE_2_ID      varchar
  , PrmCalculGlobal                integer
  , PrmlstStock                    varchar2
  , iUseMasterPlanProcurements     integer
  , iUseMasterPlanRequirements     integer
  , PrmFAL_PIC_ID                  number
  , PrmFPL_SESSION_ID              FAL_PROD_LEVEL.FPL_SESSION_ID%type
  , PrmReconstructionComposAttrStk integer default 0
  , PrmReconsBesOnProductMode      integer default 0
  , prmWithoutLogisticReqrmts      integer default 0
  , iRedoSSTAAttrStk               integer default 0
  , iPreserveAttribOnSSTAStock     integer default 0
  , iDeleteExpiredAttrib           integer default 0
  )
  is
    TGcoGoodId               T_GCO_GOOD_ID;
    TFalNetworkLinkId        T_FAL_NETWORK_LINK_ID;
    TFalNetworkNeedId        T_FAL_NETWORK_NEED_ID;
    TFalNetworkSupplyId      T_FAL_NETWORK_SUPPLY_ID;
    TStmLocationId           T_STM_LOCATION_ID;
    TStmStockPositionId      T_STM_STOCK_POSITION_ID;
    TFlnQty                  T_FLN_QTY;
    CursorBesoin             integer;
    CursorAttribOfBesoin     integer;
    CursorBesoinGroup        integer;
    CurrentNEED_ID           GCO_GOOD.GCO_GOOD_ID%type;
    CurrentSUPPLY_ID         GCO_GOOD.GCO_GOOD_ID%type;
    CurrentLINK_ID           number;
    CurrentSTOCK_POSITION_ID number;
    CurrentSTM_LOCATION_ID   number;
    CurrentFLN_QTY           FAl_NETWORK_LINK.FLN_QTY%type;
    BuffSql                  varchar2(32000);
    BuffSql2                 varchar2(32000);
    Ignore                   integer;
    LstControleStocksIDs     varchar2(4000);
    LvCurGoodId              varchar2(4000);
    lbRedoStockAlloc         boolean;
  begin
    if trim(PrmlstStock) is null then
      return;
    end if;

    -- Récupération de la liste des stocks de contrôle
    LstControleStocksIDs  := GetStockControlIDFromConfig;

    -- Reconstruction Globale
    if PrmReconstructionGlobale = 1 then
      -- Construction de la requête de sélection du (des) produit(s) à reconstruire.
      LvCurGoodId  := ' select GCO.GCO_GOOD_ID from GCO_GOOD GCO ';

      if nvl(PrmDIC_CATEGORY_FREE_2_ID, '') <> '' then
        LvCurGoodId  := LvCurGoodId || '      , GCO_GOOD_CATEGORY CAT ';
      end if;

      LvCurGoodId  :=
        LvCurGoodId ||
        '  where not exists(select 1 ' ||
        '                     from GCO_SERVICE SER ' ||
        '                    where SER.GCO_GOOD_ID = GCO.GCO_GOOD_ID) ' ||
        '    and not exists(select 1 ' ||
        '                     from GCO_PSEUDO_GOOD PSE ' ||
        '                    where PSE.GCO_GOOD_ID = GCO.GCO_GOOD_ID) ' ||
        '    and exists (select 1 ' ||
        '                  from FAL_NETWORK_NEED FNN ' ||
        '                 where FNN.GCO_GOOD_ID = GCO.GCO_GOOD_ID) ';

      if nvl(PrmGCO_GOOD_ID, 0) <> 0 then
        if PrmGCO_GOOD_ID = -1 then
          LvCurGoodId  :=
            LvCurGoodId ||
            ' and GCO.GCO_GOOD_ID in (select FPL.GCO_GOOD_ID ' ||
            '                           from FAL_PROD_LEVEL FPL ' ||
            '                          where FPL.FAL_PROD_LEVEL_ID > 0) ';
        elsif PrmGCO_GOOD_ID = -2 then
          LvCurGoodId  :=
            LvCurGoodId ||
            ' and GCO.GCO_GOOD_ID in (select FPL.GCO_GOOD_ID ' ||
            '                           from FAL_PROD_LEVEL FPL ' ||
            '                          where FPL.FAL_PROD_LEVEL_ID < 0 ' ||
            '                            and FPL.FPL_SESSION_ID = ' ||
            PrmFPL_SESSION_ID ||
            ') ';
        else
          LvCurGoodId  := LvCurGoodId || ' and GCO.GCO_GOOD_ID = ' || PrmGCO_GOOD_ID;
        end if;
      end if;

      if nvl(PrmGCO_GOOD_CATEGORY_ID, 0) <> 0 then
        LvCurGoodId  := LvCurGoodId || ' and GCO.GCO_GOOD_CATEGORY_ID = ' || PrmGCO_GOOD_CATEGORY_ID;
      end if;

      if nvl(PrmDIC_CATEGORY_FREE_2_ID, '') <> '' then
        LvCurGoodId  :=
            LvCurGoodId || ' and GCO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID (+) ' || ' and CAT.DIC_CATEGORY_FREE_2_ID = ' || PrmDIC_CATEGORY_FREE_2_ID;
      end if;

      if not upper(PCS.PC_CONFIG.GetConfig('FAL_LINK_COMPLETE') ) = 'FALSE' then
        LvCurGoodId  :=
          LvCurGoodId ||
          ' and exists(select 1 ' ||
          '             from GCO_PRODUCT PDT ' ||
          '            where PDT.GCO_GOOD_ID = GCO.GCO_GOOD_ID ' ||
          '              and PDT.PDT_STOCK_MANAGEMENT = 1) ';
      end if;

      execute immediate LvCurGoodId
      bulk collect into TGcoGoodId;

      if TGcoGoodId.count > 0 then
        for i in TGcoGoodId.first .. TGcoGoodId.last loop
          -- On ne prends pas les produits gérés en Traçabilité totale
          if not FAL_TOOLS.IsFullTracability(TGcoGoodId(i) ) then
            -- Suppression des Attributions de besoins standards log et fab.
            DeleteAttribOnStandardNeeds(TGcoGoodId(i), PrmLstStock, PrmWithoutLogisticReqrmts, PrmBesoinsLogistiquesGlobale, PrmReconsBesOnProductMode);

            -- Suppression des Attributions de besoins de sous-traitance d'achat.
            if iRedoSSTAAttrStk = 1 then
              DeleteAttribOnSSTANeeds(TGcoGoodId(i), PrmLstStock, iPreserveAttribOnSSTAStock);
            end if;

            -- Suppression des attributions besoin sur stock expiré.
            if (nvl(iDeleteExpiredAttrib, 0) = 1) then
              DeleteAllExpiredAttrib(TGcoGoodId(i), PrmLstStock);
            end if;

            -- Suppression des attributions d'approvisionnement sur emplacement de stocks.
            DeleteSupplyAttribOnLocation(TGcoGoodId(i), PrmLstStock, PrmWithoutLogisticReqrmts);
            -- Est-ce qu'il faudra reconstruction les réservations sur stock ?
            lbRedoStockAlloc  :=     (   iRedoSSTAAttrStk = 1
                                      or PrmReconsBesOnProductMode = 1)
                                 and GetPDT_STOCK_ALLOC_BATCH(TGcoGoodId(i) );

            if PrmCalculGlobal = 1 then
              -- Calcul Global
              -- Reconstruction des réservations des composants de commandes d'achat sous-traitance selon mode de gestion du produit
              if     iRedoSSTAAttrStk = 1
                 and lbRedoStockAlloc then
                GenereAttribBesoinFabSurStock(TGcoGoodId(i), PrmLstStock, iUseMasterPlanRequirements, null, 1);
              end if;

              -- Reconstruction des Réservations des composants de lot selon mode de gestion produit
              if     PrmReconsBesOnProductMode = 1
                 and lbRedoStockAlloc then
                GenereAttribBesoinFabSurStock(TGcoGoodId(i), PrmLstStock, iUseMasterPlanRequirements);
              end if;

              PartieGlobale(TGcoGoodId(i)
                          , PrmLstStock
                          , PrmBesoinsLogistiquesGlobale
                          , PrmMargeNegativeGlobale
                          , PrmCompensationStockControle
                          , PrmQueSurLesDocumentsGlobale
                          , iUseMasterPlanProcurements
                          , iUseMasterPlanRequirements
                          , PrmFAL_PIC_ID
                          , LstControleStocksIDs
                           );
            else
              -- Calcul Stock par stock
              for tplStock in (select STM_STOCK_ID
                                 from STM_STOCK
                                where instr(',' || PrmLstStock || ',', ',' || STM_STOCK_ID || ',') <> 0) loop
                -- Reconstruction des réservations des composants de commandes d'achat sous-traitance selon mode de gestion du produit
                if     iRedoSSTAAttrStk = 1
                   and lbRedoStockAlloc then
                  GenereAttribBesoinFabSurStock(TGcoGoodId(i), tplStock.STM_STOCK_ID, iUseMasterPlanRequirements, null, 1);
                end if;

                -- Reconstruction des Réservations des composants de lot selon mode de gestion produit
                if     PrmReconsBesOnProductMode = 1
                   and lbRedoStockAlloc then
                  GenereAttribBesoinFabSurStock(TGcoGoodId(i), tplStock.STM_STOCK_ID, iUseMasterPlanRequirements);
                end if;

                PartieGlobale(TGcoGoodId(i)
                            , tplStock.STM_STOCK_ID
                            , PrmBesoinsLogistiquesGlobale
                            , PrmMargeNegativeGlobale
                            , PrmCompensationStockControle
                            , PrmQueSurLesDocumentsGlobale
                            , iUseMasterPlanProcurements
                            , iUseMasterPlanRequirements
                            , PrmFAL_PIC_ID
                            , LstControleStocksIDs
                             );
              end loop;
            end if;
          end if;
        end loop;
      end if;
    end if;

    -- Reconstruction partielle
    if PrmReconstructionPartielle = 1 then
      --Reconstruction
      if PrmReconstruction = 1 then
        buffsql       := ' select FAL_NETWORK_NEED_ID from FAL_NETWORK_NEED b';

        if PrmQueSurLesDocumentsPartielle = 1 then
          buffsql  := buffsql || '      , DOC_GAUGE_STRUCTURED s ';
        end if;

        buffsql       :=
          buffsql ||
          ' where b.DOC_POSITION_DETAIL_ID is not null ' ||
          '   and (doc_position_id in (select doc_position_id from doc_position where c_gauge_type_pos not in (7,8,9,10))) ' ||
          '   and (b.doc_gauge_id is null ' ||
          '        or b.doc_gauge_id not in (select doc_gauge_id from fal_prop_def where c_prop_type=4)) ' ||
          '  and not exists (select 1 from gco_service     ser where b.gco_good_id = ser.gco_good_id) ' ||
          '  and not exists (select 1 from GCO_PSEUDO_GOOD pse where b.gco_good_id = pse.gco_good_id) ';

        if PrmQueSurLesDocumentsPartielle = 1 then
          buffsql  := buffsql || ' and s.GAS_AUTO_ATTRIBUTION = 1 ' || ' and s.DOC_GAUGE_ID=b.DOC_GAUGE_ID ';
        end if;

        if nvl(PrmPAC_THIRD_ID, 0) <> 0 then
          buffsql  := buffsql || ' and  b.PAC_THIRD_ID = ' || PrmPAC_THIRD_ID;
        end if;

        CursorBesoin  := DBMS_SQL.open_cursor;
        DBMS_SQL.Parse(CursorBesoin, BuffSql || ' FOR UPDATE OF b.FAL_NETWORK_NEED_ID', DBMS_SQL.NATIVE);
        DBMS_SQL.Define_column(CursorBesoin, 1, CurrentNEED_ID);
        Ignore        := DBMS_SQL.execute(CursorBesoin);

        while DBMS_SQL.fetch_rows(CursorBesoin) > 0 loop
          DBMS_SQL.column_value(CursorBesoin, 1, CurrentNEED_ID);
          -- ( 4 ) Itération sur les attribs du besoins encours (On ne supprime pas les attributions en cours de traitement dans les sortie de composants)
          BuffSql2              :=
            ' SELECT FAL_NETWORK_LINK_ID ' ||
            '      , FAL_NETWORK_NEED_ID ' ||
            '      , FAL_NETWORK_SUPPLY_ID ' ||
            '      , STM_STOCK_POSITION_ID ' ||
            '      , STM_LOCATION_ID ' ||
            '      , FLN_QTY ' ||
            '   FROM FAL_NETWORK_LINK a ' ||
            '  WHERE FAL_NETWORK_NEED_ID = ' ||
            CurrentNEED_ID ||
            '   and a.fal_network_link_id not in (select fcl.fal_network_link_id ' ||
            '                                       from fal_component_link fcl ' ||
            '                                      where fcl.fal_network_link_id = a.fal_network_link_id) ' ||
            ' FOR UPDATE of a.FAL_NETWORK_LINK_ID';
          CursorAttribOfBesoin  := DBMS_SQL.open_cursor;
          DBMS_SQL.Parse(CursorAttribOfBesoin, BuffSql2, DBMS_SQL.NATIVE);
          DBMS_SQL.Define_column(CursorAttribOfBesoin, 1, CurrentLINK_ID);
          DBMS_SQL.Define_column(CursorAttribOfBesoin, 2, CurrentNEED_ID);
          DBMS_SQL.Define_column(CursorAttribOfBesoin, 3, CurrentSUPPLY_ID);
          DBMS_SQL.Define_column(CursorAttribOfBesoin, 4, CurrentSTOCk_POSITION_ID);
          DBMS_SQL.Define_column(CursorAttribOfBesoin, 5, CurrentSTM_LOCATION_ID);
          DBMS_SQL.Define_column(CursorAttribOfBesoin, 6, CurrentFLN_QTY);
          Ignore                := DBMS_SQL.execute(CursorAttribOfBesoin);

          while DBMS_SQL.fetch_rows(CursorAttribOfBesoin) > 0 loop
            DBMS_SQL.column_value(CursorAttribOfBesoin, 1, CurrentLINK_ID);
            DBMS_SQL.column_value(CursorAttribOfBesoin, 2, CurrentNEED_ID);
            DBMS_SQL.column_value(CursorAttribOfBesoin, 3, CurrentSUPPLY_ID);
            DBMS_SQL.column_value(CursorAttribOfBesoin, 4, CurrentSTOCK_POSITION_ID);
            DBMS_SQL.column_value(CursorAttribOfBesoin, 5, CurrentSTM_LOCATION_ID);
            DBMS_SQL.column_value(CursorAttribOfBesoin, 6, CurrentFLN_QTY);
            SuppressionAttribution(CurrentLINK_ID, CurrentNEED_ID, CurrentSUPPLY_ID, CurrentSTOCK_POSITION_ID, CurrentSTM_LOCATION_ID, CurrentFLN_QTY);
          end loop;

          DBMS_SQL.close_cursor(CursorAttribOfBesoin);
        -- Fin Itération sur les attribs du besoins encours
        end loop;

        DBMS_SQL.close_cursor(CursorBesoin);
      -- Fin itération sur les besoins logistiques
      elsif PrmReactualisation = 1 then
        -- Définir les besoins logistiques
        buffsql  := ' select b.FAL_NETWORK_NEED_ID from FAL_NETWORK_NEED b ';

        if PrmQueSurLesDocumentsPartielle = 1 then
          buffsql  := buffsql || ' , DOC_GAUGE_STRUCTURED s ';
        end if;

        buffsql  :=
          buffsql ||
          ' where b.DOC_POSITION_DETAIL_ID is not null ' ||
          '   and  b.FAN_FREE_QTY > 0 ' ||
          '   and (doc_position_id in (select doc_position_id from doc_position where c_gauge_type_pos not in (7,8,9,10))) ' ||
          '   and (b.doc_gauge_id is null ' ||
          '        or b.doc_gauge_id not in (select doc_gauge_id from fal_prop_def where c_prop_type=4)) ' ||
          '   and not exists (select 1 from gco_service     ser where b.gco_good_id = ser.gco_good_id) ' ||
          '   and not exists (select 1 from GCO_PSEUDO_GOOD pse where b.gco_good_id = pse.gco_good_id) ';

        if PrmQueSurLesDocumentsPartielle = 1 then
          buffsql  := buffsql || ' and  s.GAS_AUTO_ATTRIBUTION = 1 ' || ' and  s.DOC_GAUGE_ID         = b.DOC_GAUGE_ID ';
        end if;

        if nvl(PrmPAC_THIRD_ID, 0) <> 0 then
          buffsql  := buffsql || ' and  b.PAC_THIRD_ID = ' || PrmPAC_THIRD_ID;
        end if;
      end if;   -- Fin de PrmReactualisation = 1 then

      -- regroupement des besoins sélectionnés
      -- pour les tiers actifs et gérant les réservations
      if (BuffSql is not null) then
        BuffSql            :=
          BuffSql ||
          '      and (   PAC_THIRD_ID is null ' ||
          '           or exists(select PAC_CUSTOM_PARTNER_ID ' ||
          '                       from PAC_CUSTOM_PARTNER ' ||
          '                      where PAC_CUSTOM_PARTNER_ID = b.PAC_THIRD_ID ' ||
          '                        and C_RESERVATION_TYP <> ''0'' ' ||
          '                        and C_PARTNER_STATUS = ''1'') ' ||
          '          ) ' ||
          ' order by GCO_GOOD_ID ' ||
          '        , FAN_BEG_PLAN ' ||
          '        , FAN_DESCRIPTION ';
        CursorBesoinGroup  := DBMS_SQL.open_cursor;
        DBMS_SQL.Parse(CursorBesoinGroup, BuffSql || ' FOR UPDATE OF b.FAL_NETWORk_NEED_ID', DBMS_SQL.NATIVE);
        DBMS_SQL.Define_column(CursorBesoinGroup, 1, CurrentNEED_ID);
        Ignore             := DBMS_SQL.execute(CursorBesoinGroup);

        while DBMS_SQL.fetch_rows(CursorBesoinGroup) > 0 loop
          DBMS_SQL.column_value(CursorBesoinGroup, 1, CurrentNEED_ID);
          ReconstructionAttribution2(CurrentNEED_ID, iUseMasterPlanProcurements, PrmMargeNegativeGlobale, PrmlstStock);
        end loop;

        DBMS_SQL.close_cursor(CursorBesoinGroup);
      else
        -- les paramètres d'entrée de la procédure sont surement pas bons
        raise_application_error(-20101, 'PCS - Nothing To Do, Parameters are ambiguously defined');
      end if;
    end if;

    -- Re-construction attributions Traçabilité Complète
    if PrmReconstructionComposAttrStk = 1 then
      ReconstructionAttribTracCompl(PrmLstStock);
    end if;
  end ReconstructionAttribs;

-- Reconstruit les attribs pour un DOC_POSITION_DETAIL_ID
-- Note: Contexte définit si nous sommes en Reconstruction ou en Réactualisation
--       Contexte = 1 pour Reconstruction
--                = 2 pour Réactualisation
--------------------------------------------------------------------------------------
  procedure DoAllocationForPositionDetail(iPositionDetailId in number, iContext in integer)
  is
  begin
    -- On ne fait la suppression des attributions que si le contexte est reconstruction
    if iContext = ctx_Reconstruction then   -- Contexte de Reconstruction
      -- Itération sur les attribs du besoins encours
      -- ( 4 ) --
      for tplLinks in (select     FNL.FAL_NETWORK_LINK_ID
                                , FNL.FAL_NETWORK_NEED_ID
                                , FNL.FAL_NETWORK_SUPPLY_ID
                                , FNL.STM_STOCK_POSITION_ID
                                , FNL.STM_LOCATION_ID
                                , FNL.FLN_QTY
                             from FAL_NETWORK_LINK FNL
                                , FAL_NETWORK_NEED FNN
                            where FNL.FAL_NETWORK_NEED_ID = FNN.FAL_NETWORK_NEED_ID
                              and FNN.DOC_POSITION_DETAIL_ID = iPositionDetailId
                       for update) loop
        SuppressionAttribution(tplLinks.FAL_NETWORK_LINK_ID
                             , tplLinks.FAL_NETWORK_NEED_ID
                             , tplLinks.FAL_NETWORK_SUPPLY_ID
                             , tplLinks.STM_STOCK_POSITION_ID
                             , tplLinks.STM_LOCATION_ID
                             , tplLinks.FLN_QTY
                              );
      end loop;
    end if;

    -- Pour tous les besoins dont le tiers est actif et gère les réservations
    for tplRequirements in (select     FAL_NETWORK_NEED_ID
                                     , STM_STOCK_FUNCTIONS.getStockGroupListId(STM_STOCK_ID) STOCK_LIST
                                  from FAL_NETWORK_NEED FNN
                                 where DOC_POSITION_DETAIL_ID = iPositionDetailId
                                   and (   iContext = ctx_Reconstruction
                                        or FAN_FREE_QTY > 0)
                                   and (   PAC_THIRD_ID is null
                                        or exists(select PAC_CUSTOM_PARTNER_ID
                                                    from PAC_CUSTOM_PARTNER
                                                   where PAC_CUSTOM_PARTNER_ID = FNN.PAC_THIRD_ID
                                                     and C_RESERVATION_TYP <> '0'
                                                     and C_PARTNER_STATUS = '1')
                                       )
                              order by GCO_GOOD_ID
                                     , FAN_BEG_PLAN
                                     , FAN_DESCRIPTION
                            for update) loop
      ReconstructionAttribution2(iNeedId                      => tplRequirements.FAL_NETWORK_NEED_ID
                               , iUseMasterPlanProcurements   => 1
                               , PrmMargeNegativeGlobale      => 0
                               , iStockListId                 => tplRequirements.STOCK_LIST
                                );
    end loop;
  end DoAllocationForPositionDetail;

  /**
  * procedure : ReDoAttribsByDocOrPOS
  * Description : Cette fonction permet de reconstruire les attributions depuis un élément logistique
  *
  * @created
  * @lastUpdate
  * @public
  * @param   PrmDOC_DOCUMENT_ID : Document
  * @param   PrmDOC_POSITION_ID : Position de document
  */
  procedure RedoAttribsByDocOrPos(PrmDOC_DOCUMENT_ID number, PrmDOC_POSITION_ID number)
  is
    aDOC_POSITION_DETAIL_ID number;

    cursor CursorDocPositionDetail
    is
      select   pde.doc_position_detail_id
          from doc_position_detail pde
             , doc_position pos
         where pde.doc_document_id = PrmDoc_Document_id
           and pos.doc_position_id = pde.doc_position_id
           and pos.c_gauge_type_pos not in('7', '8', '9', '10')
           -- Et qui ne pointe pas sur un service
           and not exists(select 1
                            from gco_service ser
                           where pos.gco_good_id = ser.gco_good_id)
           -- Et qui ne pointe pas sur un pseudo bien
           and not exists(select 1
                            from GCO_PSEUDO_GOOD pse
                           where pos.gco_good_id = pse.gco_good_id)
           -- Et qui ont un bien renseigné
           and pos.gco_good_id is not null
      order by pde.pde_final_delay
             , pde.doc_position_detail_id;

    cursor CursorDocPositionDetailByPos
    is
      -- Traite les détails de position dont les positions ne sont pas 7,8,9,10
      select   pde_all.doc_position_detail_id
          from (select pde.doc_position_detail_id
                     , pde.pde_final_delay
                  from doc_position_detail pde
                     , doc_position pos
                 where pde.doc_position_id = PrmDOC_POSITION_ID
                   and pos.doc_position_id = pde.doc_position_id
                   and pos.c_gauge_type_pos not in('7', '8', '9', '10')
                   -- Et qui ne pointe pas sur un service
                   and not exists(select 1
                                    from gco_service ser
                                   where pos.gco_good_id = ser.gco_good_id)
                   -- Et qui ne pointe pas sur un pseudo bien
                   and not exists(select 1
                                    from GCO_PSEUDO_GOOD pse
                                   where pos.gco_good_id = pse.gco_good_id)
                   -- Et qui ont un bien renseigné
                   and pos.gco_good_id is not null
                union all
                -- Traite les détails de position des composants (71,81,91,101) de la position
                select pde.doc_position_detail_id
                     , pde.pde_final_delay
                  from doc_position_detail pde
                     , doc_position pos
                 where pos.doc_doc_position_id = PrmDOC_POSITION_ID
                   and pde.doc_position_id = pos.doc_position_id
                   -- Et qui ne pointe pas sur un service
                   and not exists(select 1
                                    from gco_service ser
                                   where pde.gco_good_id = ser.gco_good_id)
                   -- Et qui ne pointe pas sur un pseudo bien
                   and not exists(select 1
                                    from GCO_PSEUDO_GOOD pse
                                   where pde.gco_good_id = pse.gco_good_id)
                   -- Et qui ont un bien renseigné
                   and pde.gco_good_id is not null) pde_all
      order by pde_all.pde_final_delay
             , pde_all.doc_position_detail_id;
  begin
    -- Vérifie que l'on passe soit un PrmDOC_DOCUMENT_ID ou un DOC_POSITION_ID
    if    (    PrmDOC_POSITION_ID is null
           and PrmDOC_DOCUMENT_ID is null)
       or (    PrmDOC_POSITION_ID is not null
           and PrmDOC_DOCUMENT_ID is not null) then   -- Problème avertir l'user
      raise_application_error(-20101, 'PCS - Nothing To Do, Parameters are not correct!');
    end if;

    if PrmDOC_DOCUMENT_ID is not null then
      -- Le document_id est non nul on va donc boucler sur tous les doc_position_detail du document passé en paramètre
      open CursorDocPositionDetail;

      loop
        fetch CursorDocPositionDetail
         into aDOC_POSITION_DETAIL_ID;

        exit when CursorDocPositionDetail%notfound;
        -- On traite un detail position à la fois
        DoAllocationForPositionDetail(aDOC_POSITION_DETAIL_ID, ctx_Reconstruction);
      end loop;   -- Fin itération sur les DOC_POSITION_DETAIL_ID

      close CursorDocPositionDetail;
    else
      -- Le position_id est non nul on va donc boucler sur tous les
      -- doc_position_detail de la position passée en paramètre.
      open CursorDocPositionDetailByPos;

      loop
        fetch CursorDocPositionDetailByPos
         into aDOC_POSITION_DETAIL_ID;

        exit when CursorDocPositionDetailByPos%notfound;
        -- On traite un detail position à la fois
        DoAllocationForPositionDetail(aDOC_POSITION_DETAIL_ID, ctx_Reconstruction);
      end loop;   -- Fin itération sur les DOC_POSITION_DETAIL_ID

      close CursorDocPositionDetailByPos;
    end if;
  end RedoAttribsByDocOrPos;

  /**
  * procedure : ReactAttribsByDocOrPOS
  * Description : Cette fonction permet de ré-actualiser les attributions depuis un
  *               élément logistique
  *
  * @created
  * @lastUpdate
  * @public
  * @param   PrmDOC_DOCUMENT_ID   : Document
  * @param   PrmDOC_POSITION_ID   : Position de document
  * @param   iPositionDetailId  : Détail de position
  */
  procedure ReactAttribsByDocOrPos(PrmDOC_DOCUMENT_ID number, PrmDOC_POSITION_ID number, iPositionDetailId number default null)
  is
    aDOC_POSITION_DETAIL_ID number;

    cursor CursorDocPositionDetail
    is
      select   pde.doc_position_detail_id
          from doc_position_detail pde
             , doc_position pos
         where pde.doc_document_id = PrmDoc_Document_id
           and pos.doc_position_id = pde.doc_position_id
           and pos.c_gauge_type_pos not in('7', '8', '9', '10')
           -- Et qui ne pointe pas sur un service
           and not exists(select 1
                            from gco_service ser
                           where pos.gco_good_id = ser.gco_good_id)
           -- Et qui ne pointe pas sur un pseudo bien
           and not exists(select 1
                            from GCO_PSEUDO_GOOD pse
                           where pos.gco_good_id = pse.gco_good_id)
           -- Et qui ont un bien renseigné
           and pos.gco_good_id is not null
      order by pde.pde_final_delay
             , pde.doc_position_detail_id;

    cursor CursorDocPositionDetailByPos
    is
      -- Traite les détails de position dont les positions ne sont pas 7,8,9,10
      select   pde_all.doc_position_detail_id
          from (select pde.doc_position_detail_id
                     , pde.pde_final_delay
                  from doc_position_detail pde
                     , doc_position pos
                 where pde.doc_position_id = PrmDOC_POSITION_ID
                   and pos.doc_position_id = pde.doc_position_id
                   and pos.c_gauge_type_pos not in('7', '8', '9', '10')
                   -- Et qui ne pointe pas sur un service
                   and not exists(select 1
                                    from gco_service ser
                                   where pos.gco_good_id = ser.gco_good_id)
                   -- Et qui ne pointe pas sur un pseudo bien
                   and not exists(select 1
                                    from GCO_PSEUDO_GOOD pse
                                   where pos.gco_good_id = pse.gco_good_id)
                   -- Et qui ont un bien renseigné
                   and pos.gco_good_id is not null
                union all
                -- Traite les détails de position des composants (71,81,91,101) de la position
                select pde.doc_position_detail_id
                     , pde.pde_final_delay
                  from doc_position_detail pde
                     , doc_position pos
                 where pos.doc_doc_position_id = PrmDOC_POSITION_ID
                   and pde.doc_position_id = pos.doc_position_id
                   -- Et qui ne pointe pas sur un service
                   and not exists(select 1
                                    from gco_service ser
                                   where pde.gco_good_id = ser.gco_good_id)
                   -- Et qui ne pointe pas sur un pseudo bien
                   and not exists(select 1
                                    from GCO_PSEUDO_GOOD pse
                                   where pde.gco_good_id = pse.gco_good_id)
                   -- Et qui ont un bien renseigné
                   and pde.gco_good_id is not null) pde_all
      order by pde_all.pde_final_delay
             , pde_all.doc_position_detail_id;
  begin
    -- Vérifie que l'on passe soit un PrmDOC_DOCUMENT_ID ou un DOC_POSITION_ID
    if    (    PrmDOC_POSITION_ID is null
           and PrmDOC_DOCUMENT_ID is null
           and iPositionDetailId is null)
       or (    PrmDOC_POSITION_ID is not null
           and PrmDOC_DOCUMENT_ID is not null) then   -- Problème avertir l'user
      raise_application_error(-20101, 'PCS - Nothing To Do, Parameters are not correct!');
    end if;

    if iPositionDetailId is not null then
      -- Traitement d'un détail de position en particulier
      DoAllocationForPositionDetail(iPositionDetailId, ctx_Reactualisation);
    elsif PrmDOC_DOCUMENT_ID is not null then
      -- Le document_id est non nul on va donc boucler sur tous les doc_position_detail du document passé en paramètre
      open CursorDocPositionDetail;

      loop
        fetch CursorDocPositionDetail
         into aDOC_POSITION_DETAIL_ID;

        exit when CursorDocPositionDetail%notfound;
        -- On traite un detail position à la fois
        DoAllocationForPositionDetail(aDOC_POSITION_DETAIL_ID, ctx_Reactualisation);
      end loop;   -- Fin itération sur les DOC_POSITION_DETAIL_ID

      close CursorDocPositionDetail;
    else
      -- Le position_id est non nul on va donc boucler sur tous les
      -- doc_position_detail de la position passée en paramètre.
      open CursorDocPositionDetailByPos;

      loop
        fetch CursorDocPositionDetailByPos
         into aDOC_POSITION_DETAIL_ID;

        exit when CursorDocPositionDetailByPos%notfound;
        -- On traite un detail position à la fois
        DoAllocationForPositionDetail(aDOC_POSITION_DETAIL_ID, ctx_Reactualisation);
      end loop;

      close CursorDocPositionDetailByPos;
    end if;
  end ReactAttribsByDocOrPos;

  procedure GenerationAttributionForNeed(
    CurGCO_GOOD_ID                GCo_GOOD.GCo_GOOD_ID%type
  , CurPAC_THIRD_ID               PAC_THIRD.PAC_THIRD_ID%type
  , CurFAN_FREE_QTY               FAL_NETWORK_NEED.FAN_FREE_QTY%type
  , CurFAL_NETWORK_NEED_ID        FAl_NETWORK_NEED.FAL_NETWORK_NEED_ID%type
  , CurSTM_LOCATION_ID            STM_LOCATION.STM_LOCATION_iD%type
  , CurSTM_STOCK_ID               STM_STOCk.STM_STOCk_ID%type
  , CurGCO_CHARACTERIZATION1_ID   FAl_NETWORK_NEED.GCO_CHARACTERIZATION1_ID%type
  , CurGCO_CHARACTERIZATION2_ID   FAl_NETWORK_NEED.GCO_CHARACTERIZATION2_ID%type
  , CurGCO_CHARACTERIZATION3_ID   FAl_NETWORK_NEED.GCO_CHARACTERIZATION3_ID%type
  , CurGCO_CHARACTERIZATION4_ID   FAl_NETWORK_NEED.GCO_CHARACTERIZATION4_ID%type
  , CurGCO_CHARACTERIZATION5_ID   FAl_NETWORK_NEED.GCO_CHARACTERIZATION5_ID%type
  , CurFAN_CHAR_VALUE1            FAl_NETWORK_NEED.FAN_CHAR_VALUE1%type
  , CurFAN_CHAR_VALUE2            FAl_NETWORK_NEED.FAN_CHAR_VALUE2%type
  , CurFAN_CHAR_VALUE3            FAl_NETWORK_NEED.FAN_CHAR_VALUE3%type
  , CurFAN_CHAR_VALUE4            FAl_NETWORK_NEED.FAN_CHAR_VALUE4%type
  , CurFAN_CHAR_VALUE5            FAL_NETWORK_NEED.FAN_CHAR_VALUE5%type
  , PdtHasVersionOrCharacteristic boolean
  , iFIFO                         number
  , iLIFO                         number
  , iTimeLimit                    number
  , iSSTAStockId                  number
  , iDate                         FAL_NETWORK_NEED.FAN_BEG_PLAN%type
  , iStockListId                  varchar2
  )
  is
    valueCar1      STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type;
    valueCar2      STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type;
    valueCar3      STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type;
    valueCar4      STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type;
    valueCar5      STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type;
    IdCar1         GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    IdCar2         GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    IdCar3         GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    IdCar4         GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    IdCar5         GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    X              STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type;
    liSortOnChrono integer                                                := 0;
    lnStockId      STM_STOCK.STM_STOCK_ID%type;
    lnLocationId   STM_LOCATION.STM_LOCATION_ID%type;
  begin
    lnStockId     := CurSTM_STOCK_ID;
    lnLocationId  := CurSTM_LOCATION_ID;
    -- Initialisation des valeur 1..5 des charactérisation de type version (1) ou caracteristique (2)
    ValueCar1     := null;
    ValueCar2     := null;
    ValueCar3     := null;
    ValueCar4     := null;
    ValueCar5     := null;
    IdCar1        := null;
    IdCar2        := null;
    IdCar3        := null;
    IdCar4        := null;
    IdCar5        := null;

    if PdtHasVersionOrCharacteristic then
      if fal_tools.VersionOrCharacteristicType(CurGCO_CHARACTERIZATION1_ID) = 1 then
        valueCar1  := CurFAN_CHAR_VALUE1;
        IdCar1     := CurGCO_CHARACTERIZATION1_ID;
      end if;

      if fal_tools.VersionOrCharacteristicType(CurGCO_CHARACTERIZATION2_ID) = 1 then
        valueCar2  := CurFAN_CHAR_VALUE2;
        IdCar2     := CurGCO_CHARACTERIZATION2_ID;
      end if;

      if fal_tools.VersionOrCharacteristicType(CurGCO_CHARACTERIZATION3_ID) = 1 then
        valueCar3  := CurFAN_CHAR_VALUE3;
        IdCar3     := CurGCO_CHARACTERIZATION3_ID;
      end if;

      if fal_tools.VersionOrCharacteristicType(CurGCO_CHARACTERIZATION4_ID) = 1 then
        valueCar4  := CurFAN_CHAR_VALUE4;
        IdCar4     := CurGCO_CHARACTERIZATION4_ID;
      end if;

      if fal_tools.VersionOrCharacteristicType(CurGCO_CHARACTERIZATION5_ID) = 1 then
        valueCar5  := CurFAN_CHAR_VALUE5;
        IdCar5     := CurGCO_CHARACTERIZATION5_ID;
      end if;
    end if;

    X             := CurFAN_FREE_QTY;

    if     iFIFO = 0
       and iLIFO = 0
       and iTimeLimit = 0 then
      -- Pas de tri
      liSortOnChrono  := 0;
    elsif    iFIFO = 1
          or iTimeLimit = 1 then
      -- Produit en FIFO ou peremption : Tri croissant
      liSortOnChrono  := 1;
    elsif iLIFO = 1 then
      -- Produit en LIFO - Tri décroissant
      liSortOnChrono  := 2;
    end if;

    -- Selection des positions de stock supérieures à 0 du produit sur l'emplacement et ayant même valeur
    -- de caractérisations pour les caractérisations de type version ou caractéristique.
    for tplStockPosition in crStockPosition(ai1v1                  => concat(idcar1, valuecar1)
                                          , ai2v2                  => concat(idcar2, valuecar2)
                                          , ai3v3                  => concat(idcar3, valuecar3)
                                          , ai4v4                  => concat(idcar4, valuecar4)
                                          , ai5v5                  => concat(idcar5, valuecar5)
                                          , iGoodId                => CurGCO_GOOD_ID
                                          , iThirdId               => CurPAC_THIRD_ID
                                          , iTimeLimitManagement   => iTimeLimit
                                          , iDate                  => iDate
                                          , iStockListId           => iStockListId
                                          , iStockId               => lnStockId
                                          , iLocationId            => lnLocationId
                                          , iSSTAStockId           => iSSTAStockId
                                          , iSortOnChrono          => liSortOnChrono
                                           ) loop
      -- Création attribution besoin stock
      Fal_Network.CreateAttribBesoinStock(CurFAL_NETWORK_NEED_ID
                                        , tplStockPosition.STM_STOCK_POSITION_ID
                                        , tplStockPosition.STM_LOCATION_ID
                                        , least(X, tplStockPosition.SPO_AVAILABLE_QUANTITY)
                                         );

      if X <= tplStockPosition.SPO_AVAILABLE_QUANTITY then
        exit;
      end if;

      X  := X - tplStockPosition.SPO_AVAILABLE_QUANTITY;
    end loop;
  end GenerationAttributionForNeed;

  /**
  * procedure : IsNeedForSubcontracting
  * Description : Vérifie sir le besoin est issu d'un composant fourni par la sous-traitance (code de décharge = 6)
  *
  * @created CLG
  * @lastUpdate
  * @public
  * @param   iFalLotMatLinkId     : Id de composant d'OF
  * @param   iFalLotMatLinkPropId : Id de composant de proposition
  * @return  True si fourni par la sous-traitance, False sinon
  */
  function IsNeedForSubcontracting(iFalLotMatLinkId in number, iFalLotMatLinkPropId in number)
    return boolean
  is
    lCDischargeCom FAL_LOT_MATERIAL_LINK.C_DISCHARGE_COM%type;
  begin
    if iFalLotMatLinkId is not null then
      select C_DISCHARGE_COM
        into lCDischargeCom
        from FAL_LOT_MATERIAL_LINK
       where FAL_LOT_MATERIAL_LINK_ID = iFalLotMatLinkId;
    elsif iFalLotMatLinkPropId is not null then
      select C_DISCHARGE_COM
        into lCDischargeCom
        from FAL_LOT_MAT_LINK_PROP
       where FAL_LOT_MAT_LINK_PROP_ID = iFalLotMatLinkPropId;
    else
      return false;
    end if;

    return(lCDischargeCom = '6');
  end IsNeedForSubcontracting;

  /**
  * procedure : GenereAttribBesoinFabSurStock
  * Description : Génération Attributions besoins fab. sur stock d'un produit
  *
  * @created
  * @lastUpdate
  * @public
  * @param   PrmGCo_GOOD_ID             : Bien
  * @param   PrmLstStock                : Liste des stock sélectionnés
  * @param   iUseMasterPlanRequirements : Prise en compte des besoins issus du plan directeur
  * @param   iFalLotId                  : Lot (appel depuis un lot de fabrication)
  * @param   iSubContractPNeed          : Prise en compte des besoins issus de la sous-traitance d'achat
  * @param   iNetworkNeedId             : Traitement d'un besoin en particulier. Prioritaire si spécifié
  */
  procedure GenereAttribBesoinFabSurStock(
    PrmGCO_GOOD_ID                GCO_GOOD.GCO_GOOD_ID%type
  , PrmLstStock                   varchar
  , iUseMasterPlanRequirements    integer
  , iFalLotId                  in number default null
  , iSubContractPNeed          in integer default 0
  , iNetworkNeedId             in number default null
  )
  is
    cursor TableTemplateFAL_NETWORK_NEED
    is
      select FNN.FAL_LOT_ID
           , FNN.FAL_LOT_MATERIAL_LINK_ID
           , FNN.FAL_LOT_MAT_LINK_PROP_ID
           , FNN.FAL_LOT_PROP_ID
           , FNN.FAL_NETWORK_NEED_ID
           , FNN.FAN_CHAR_VALUE1
           , FNN.FAN_CHAR_VALUE2
           , FNN.FAN_CHAR_VALUE3
           , FNN.FAN_CHAR_VALUE4
           , FNN.FAN_CHAR_VALUE5
           , FNN.FAN_FREE_QTY
           , FNN.FAN_BEG_PLAN
           , FNN.GCO_CHARACTERIZATION1_ID
           , FNN.GCO_CHARACTERIZATION2_ID
           , FNN.GCO_CHARACTERIZATION3_ID
           , FNN.GCO_CHARACTERIZATION4_ID
           , FNN.GCO_CHARACTERIZATION5_ID
           , FNN.GCO_GOOD_ID
           , FNN.PAC_THIRD_ID
           , FNN.STM_LOCATION_ID
           , FNN.STM_STOCK_ID
           , LOT.C_FAB_TYPE
        from FAL_NETWORK_NEED FNN
           , FAL_LOT LOT;

    type TFAL_NETWORK_NEED is table of TableTemplateFAL_NETWORK_NEED%rowtype
      index by binary_integer;

    TFalNetworkNeed               TFAL_NETWORK_NEED;
    BuffSql                       varchar2(32000);
    PdtHasVersionOrCharacteristic boolean;
    liTabIndex                    integer;
    liHorizonAttrib               integer;
    lnGCO_CHARACTERIZATION1_ID    FAl_NETWORK_NEED.GCO_CHARACTERIZATION1_ID%type;
    lnGCO_CHARACTERIZATION2_ID    FAl_NETWORK_NEED.GCO_CHARACTERIZATION2_ID%type;
    lnGCO_CHARACTERIZATION3_ID    FAl_NETWORK_NEED.GCO_CHARACTERIZATION3_ID%type;
    lnGCO_CHARACTERIZATION4_ID    FAl_NETWORK_NEED.GCO_CHARACTERIZATION4_ID%type;
    lnGCO_CHARACTERIZATION5_ID    FAl_NETWORK_NEED.GCO_CHARACTERIZATION5_ID%type;
    lvFAN_CHAR_VALUE1             FAl_NETWORK_NEED.FAN_CHAR_VALUE1%type;
    lvFAN_CHAR_VALUE2             FAl_NETWORK_NEED.FAN_CHAR_VALUE2%type;
    lvFAN_CHAR_VALUE3             FAl_NETWORK_NEED.FAN_CHAR_VALUE3%type;
    lvFAN_CHAR_VALUE4             FAl_NETWORK_NEED.FAN_CHAR_VALUE4%type;
    lvFAN_CHAR_VALUE5             FAl_NETWORK_NEED.FAN_CHAR_VALUE5%type;
    lnFIFO                        number(1)                                        := 0;
    lnLIFO                        number(1)                                        := 0;
    lnTimeLimit                   number(1)                                        := 0;
    lnSSTAStockID                 number;
  begin
    -- Recherche de l'horizon d'attribution
    liHorizonAttrib  := GetHorizonAttributionPdt(PrmGCO_GOOD_ID);
    Buffsql          :=
      'select FNN.FAL_LOT_ID ' ||
      '     , FNN.FAL_LOT_MATERIAL_LINK_ID ' ||
      '     , FNN.FAL_LOT_MAT_LINK_PROP_ID ' ||
      '     , FNN.FAL_LOT_PROP_ID ' ||
      '     , FNN.FAL_NETWORK_NEED_ID ' ||
      '     , FNN.FAN_CHAR_VALUE1 ' ||
      '     , FNN.FAN_CHAR_VALUE2 ' ||
      '     , FNN.FAN_CHAR_VALUE3 ' ||
      '     , FNN.FAN_CHAR_VALUE4 ' ||
      '     , FNN.FAN_CHAR_VALUE5 ' ||
      '     , FNN.FAN_FREE_QTY ' ||
      '     , FNN.FAN_BEG_PLAN ' ||
      '     , FNN.GCO_CHARACTERIZATION1_ID ' ||
      '     , FNN.GCO_CHARACTERIZATION2_ID ' ||
      '     , FNN.GCO_CHARACTERIZATION3_ID ' ||
      '     , FNN.GCO_CHARACTERIZATION4_ID ' ||
      '     , FNN.GCO_CHARACTERIZATION5_ID ' ||
      '     , FNN.GCO_GOOD_ID ' ||
      '     , FNN.PAC_THIRD_ID ' ||
      '     , FNN.STM_LOCATION_ID ' ||
      '     , FNN.STM_STOCK_ID ';
    if nvl(iFalLotId, 0) <> 0 then
      Buffsql  :=
        BuffSql ||
      '     , nvl(LOT.C_FAB_TYPE, ''0'') C_FAB_TYPE ';
    else
      Buffsql  :=
        BuffSql ||
      '     , nvl(LOT.C_FAB_TYPE, nvl(PROP.C_FAB_TYPE, ''0'')) C_FAB_TYPE ';
    end if;

    -- Si appel pour un besoin de fabrication spécifique (lot ou proposition)
    if nvl(iNetworkNeedId, 0) <> 0 then
      Buffsql  :=
        BuffSql ||
        '  from FAL_NETWORK_NEED FNN ' ||
        '     , FAL_LOT LOT ' ||
        '     , FAL_LOT_PROP PROP ' ||
        ' where FNN.FAN_FREE_QTY > 0 ' ||
        '   and FNN.FAL_NETWORK_NEED_ID = :FAL_NETWORK_NEED_ID ' ||
        '   and FNN.FAN_BEG_PLAN < SYSDATE + :iHorizonAttrib ' ||
        '   and FNN.FAL_LOT_ID = LOT.FAL_LOT_ID (+) ' ||
        '   and FNN.FAL_LOT_PROP_ID = PROP.FAL_LOT_PROP_ID (+) ';
    -- Si appel pour un lot de fabrication
    elsif nvl(iFalLotId, 0) <> 0 then
      Buffsql  :=
        BuffSql ||
        '   from FAL_NETWORK_NEED FNN ' ||
        '      , GCO_PRODUCT PDT ' ||
        '      , FAL_LOT LOT ' ||
        '  where PDT.GCO_GOOD_ID = FNN.GCO_GOOD_ID ' ||
        '    and PDT.PDT_STOCK_ALLOC_BATCH = 1 ' ||
        '    and PDT.PDT_FULL_TRACABILITY = 0 ' ||
        '    and FNN.FAN_FREE_QTY > 0 ' ||
        '    and FNN.FAL_LOT_ID = :FAL_LOT_ID ' ||
        '    and FNN.FAN_BEG_PLAN < SYSDATE + :iHorizonAttrib ' ||
        '    and FNN.FAL_LOT_ID = LOT.FAL_LOT_ID ';
    else
      -- Recherche des besoins à traiter
      Buffsql  :=
        BuffSql ||
        '   from FAL_NETWORK_NEED FNN ' ||
        '      , FAL_LOT LOT ' ||
        '      , FAL_LOT_PROP PROP ' ||
        '  where FNN.GCO_GOOD_ID = :GCO_GOOD_ID ' ||
        '    and (FNN.FAL_LOT_MATERIAL_LINK_ID IS NOT NULL OR FNN.FAL_LOT_MAT_LINK_PROP_ID IS NOT NULL) ' ||
        '    and FNN.FAN_FREE_QTY > 0 ' ||
        '    and FNN.FAN_BEG_PLAN < SYSDATE + :iHorizonAttrib ' ||
        '    and FNN.FAL_LOT_ID = LOT.FAL_LOT_ID (+) ' ||
        '    and FNN.FAL_LOT_PROP_ID = PROP.FAL_LOT_PROP_ID (+) ';

      -- besoins de sous-traitance d'achat
      if iSubContractPNeed = 1 then
        Buffsql  := Buffsql || ' and NVL(LOT.C_FAB_TYPE, PROP.C_FAB_TYPE) = ''4'' ';
      -- Hors besoins de sous-traitance d'achat
      else
        Buffsql  := Buffsql || ' and NVL(LOT.C_FAB_TYPE, NVL(PROP.C_FAB_TYPE, ''0'')) <> ''4'' ';
      end if;
    end if;

    if PrmLstStock is not null then
      BuffSql  := BuffSql || '    and FNN.STM_STOCK_ID in (' || PrmLstStock || ')';
    end if;

    -- Si on ne tiens pas compte du plan directeur, il ne faut pas prendre en compte
    -- les besoins de propositions issues d'un plan directeur
    if iUseMasterPlanRequirements = 0 then
      -- Il ne faut pas prendre en compte les besoins de propositions issues d'un plan directeur
      BuffSql  :=
        BuffSql ||
        ' and (select FAL_PIC_ID ' ||
        '        from FAL_LOT_PROP PROP ' ||
        '       where PROP.FAL_LOT_PROP_ID = FNN.FAL_LOT_PROP_ID) is null ' ||
        ' and (select FAL_PIC_ID ' ||
        '        from FAL_DOC_PROP PROP ' ||
        '       where PROP.FAL_DOC_PROP_ID = FNN.FAL_DOC_PROP_ID) is null ';
    end if;

    -- Si cgf FAL_RESERVATION_ON_FIX_ORDER = 1, réservation sur stock uniquement sur les besoins fermes
    -- (c-a-d sur OF et pas sur les propositions)
    if PCS.PC_PUBLIC.GetConfig('FAL_RESERVATION_ON_FIX_ORDER') = 1 then
      BuffSql  := BuffSql || '    and FNN.FAL_LOT_ID IS NOT NULL ';
    end if;

    Buffsql          := Buffsql || ' order by FNN.FAN_BEG_PLAN ' || '   for Update of FNN.FAN_STK_QTY';

    -- Si appel pour un besoin de fabrication spécifique
    if nvl(iNetworkNeedId, 0) <> 0 then
      execute immediate buffSQL
      bulk collect into TFalNetworkNeed
                  using iNetworkNeedId, liHorizonAttrib;
    -- Si appel pour un lot de fabrication
    elsif nvl(iFalLotId, 0) <> 0 then
      execute immediate buffSQL
      bulk collect into TFalNetworkNeed
                  using iFalLotId, liHorizonAttrib;
    else
      execute immediate buffSQL
      bulk collect into TFalNetworkNeed
                  using PrmGCO_GOOD_ID, liHorizonAttrib;
    end if;

    -- Parcours des besoins concernés
    if TFalNetworkNeed.count > 0 then
      -- Recherche des caractérisations morphologiques
      PdtHasVersionOrCharacteristic  := FAL_TOOLS.ProductHasVersionOrCharacteris(PrmGCO_GOOD_ID) = 1;
      -- Récupère les informations des types chronoloqique
      GCO_I_LIB_CHARACTERIZATION.GetChronologicalType(iGoodID => PrmGCO_GOOD_ID, ioFIFO => lnFIFO, ioLIFO => lnLIFO, ioTimeLimit => lnTimeLimit);
      lnGCO_CHARACTERIZATION1_ID     := null;
      lnGCO_CHARACTERIZATION2_ID     := null;
      lnGCO_CHARACTERIZATION3_ID     := null;
      lnGCO_CHARACTERIZATION4_ID     := null;
      lnGCO_CHARACTERIZATION5_ID     := null;
      lvFAN_CHAR_VALUE1              := null;
      lvFAN_CHAR_VALUE2              := null;
      lvFAN_CHAR_VALUE3              := null;
      lvFAN_CHAR_VALUE4              := null;
      lvFAN_CHAR_VALUE5              := null;

      for liTabIndex in TFalNetworkNeed.first .. TFalNetworkNeed.last loop
        if PdtHasVersionOrCharacteristic then
          lnGCO_CHARACTERIZATION1_ID  := TFalNetworkNeed(liTabIndex).GCO_CHARACTERIZATION1_ID;
          lnGCO_CHARACTERIZATION2_ID  := TFalNetworkNeed(liTabIndex).GCO_CHARACTERIZATION2_ID;
          lnGCO_CHARACTERIZATION3_ID  := TFalNetworkNeed(liTabIndex).GCO_CHARACTERIZATION3_ID;
          lnGCO_CHARACTERIZATION4_ID  := TFalNetworkNeed(liTabIndex).GCO_CHARACTERIZATION4_ID;
          lnGCO_CHARACTERIZATION5_ID  := TFalNetworkNeed(liTabIndex).GCO_CHARACTERIZATION5_ID;
          lvFAN_CHAR_VALUE1           := TFalNetworkNeed(liTabIndex).FAN_CHAR_VALUE1;
          lvFAN_CHAR_VALUE2           := TFalNetworkNeed(liTabIndex).FAN_CHAR_VALUE2;
          lvFAN_CHAR_VALUE3           := TFalNetworkNeed(liTabIndex).FAN_CHAR_VALUE3;
          lvFAN_CHAR_VALUE4           := TFalNetworkNeed(liTabIndex).FAN_CHAR_VALUE4;
          lvFAN_CHAR_VALUE5           := TFalNetworkNeed(liTabIndex).FAN_CHAR_VALUE5;
        end if;

        -- Besoin pour une fabrication de type Sous-traitance d'achat
        if    (    iSubContractPNeed = 1
               and TFalNetworkNeed(liTabIndex).C_FAB_TYPE = '4')
           or IsNeedForSubcontracting(TFalNetworkNeed(liTabIndex).FAL_LOT_MATERIAL_LINK_ID, TFalNetworkNeed(liTabIndex).FAL_LOT_MAT_LINK_PROP_ID) then
          if TFalNetworkNeed(liTabIndex).C_FAB_TYPE = '4' then
            lnSSTAStockID  :=
              FAL_LIB_SUBCONTRACTP.GetStockSubcontractP(iFalLotId       => TFalNetworkNeed(liTabIndex).FAL_LOT_ID
                                                      , iFalLotPropId   => TFalNetworkNeed(liTabIndex).FAL_LOT_PROP_ID
                                                       );
          else
            lnSSTAStockID  :=
              FAL_LIB_SUBCONTRACTP.GetBatchCompoStockSubcontractP(iFalLotMatLinkId       => TFalNetworkNeed(liTabIndex).FAL_LOT_MATERIAL_LINK_ID
                                                                , iFalLotMatLinkPropId   => TFalNetworkNeed(liTabIndex).FAL_LOT_MAT_LINK_PROP_ID
                                                                 );
          end if;
        else
          lnSSTAStockID  := null;
        end if;

        -- Génération des attributions sur stock du besoin.
        GenerationAttributionForNeed(TFalNetworkNeed(liTabIndex).GCO_GOOD_ID
                                   , TFalNetworkNeed(liTabIndex).PAC_THIRD_ID
                                   , TFalNetworkNeed(liTabIndex).FAN_FREE_QTY
                                   , TFalNetworkNeed(liTabIndex).FAL_NETWORK_NEED_ID
                                   , TFalNetworkNeed(liTabIndex).STM_LOCATION_ID
                                   , TFalNetworkNeed(liTabIndex).STM_STOCK_ID
                                   , lnGCO_CHARACTERIZATION1_ID
                                   , lnGCO_CHARACTERIZATION2_ID
                                   , lnGCO_CHARACTERIZATION3_ID
                                   , lnGCO_CHARACTERIZATION4_ID
                                   , lnGCO_CHARACTERIZATION5_ID
                                   , lvFAN_CHAR_VALUE1
                                   , lvFAN_CHAR_VALUE2
                                   , lvFAN_CHAR_VALUE3
                                   , lvFAN_CHAR_VALUE4
                                   , lvFAN_CHAR_VALUE5
                                   , PdtHasVersionOrCharacteristic
                                   , lnFIFO
                                   , lnLIFO
                                   , lnTimeLimit
                                   , lnSSTAStockID
                                   , TFalNetworkNeed(liTabIndex).FAN_BEG_PLAN
                                   , PrmLstStock
                                    );
      end loop;
    end if;
  end GenereAttribBesoinFabSurStock;

  /**
  * procedure   : DeleteAllExpiredAttrib
  * description : Supprimer toutes les attributions besoin sur stock obsolètes
  */
  procedure DeleteAllExpiredAttrib(iGoodId in GCO_GOOD.GCO_GOOD_ID%type, iInternalStockList in varchar2 default '')
  is
  begin
    -- Suppression des attributions besoin sur stock dont le statut qualité n'est pas coché "Disponible pour le prévisionnel et pour les attributions"
    if STM_I_LIB_CONSTANT.gcCfgUseQualityStatus then
      for tplQualityStatus in (select     FNL.FAL_NETWORK_LINK_ID
                                        , FNL.FAL_NETWORK_NEED_ID
                                        , FNL.FAL_NETWORK_SUPPLY_ID
                                        , FNL.STM_STOCK_POSITION_ID
                                        , FNN.STM_STOCK_ID
                                        , FNL.STM_LOCATION_ID
                                        , FNL.FLN_QTY
                                     from FAL_NETWORK_LINK FNL
                                        , FAL_NETWORK_NEED FNN
                                        , STM_STOCK_POSITION SPO
                                        , STM_ELEMENT_NUMBER SEM
                                    where FNL.FAL_NETWORK_NEED_ID = FNN.FAL_NETWORK_NEED_ID
                                      and SPO.STM_STOCK_POSITION_ID = FNL.STM_STOCK_POSITION_ID
                                      and FNN.GCO_GOOD_ID = iGoodId
                                      and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = SEM.STM_ELEMENT_NUMBER_ID(+)
                                      and SEM.GCO_QUALITY_STATUS_ID is not null
                                      and instr(',' || nvl(iInternalStockList, FNN.STM_STOCK_ID) || ',', ',' || FNN.STM_STOCK_ID || ',') > 0
                                      and GCO_I_LIB_QUALITY_STATUS.IsNetworkLinkManagement(SEM.GCO_QUALITY_STATUS_ID) = 0
                                 order by FNN.FAN_BEG_PLAN
                               for update) loop
        SuppressionAttribution(tplQualityStatus.FAL_NETWORK_LINK_ID
                             , tplQualityStatus.FAL_NETWORK_NEED_ID
                             , tplQualityStatus.FAL_NETWORK_SUPPLY_ID
                             , tplQualityStatus.STM_STOCK_POSITION_ID
                             , tplQualityStatus.STM_LOCATION_ID
                             , tplQualityStatus.FLN_QTY
                              );
      end loop;
    end if;

    -- Suppression des attributions besoin sur stock périmé si le produit est géré avec une date de péremption
    if (GCO_I_LIB_CHARACTERIZATION.IsTimeLimitManagement(iGoodId) = 1) then
      for tplOutdated in (select     FNL.FAL_NETWORK_LINK_ID
                                   , FNL.FAL_NETWORK_NEED_ID
                                   , FNL.FAL_NETWORK_SUPPLY_ID
                                   , FNL.STM_STOCK_POSITION_ID
                                   , FNL.STM_LOCATION_ID
                                   , FNL.FLN_QTY
                                from FAL_NETWORK_LINK FNL
                                   , FAL_NETWORK_NEED FNN
                                   , STM_STOCK_POSITION SPO
                               where FNL.FAL_NETWORK_NEED_ID = FNN.FAL_NETWORK_NEED_ID
                                 and SPO.STM_STOCK_POSITION_ID = FNL.STM_STOCK_POSITION_ID
                                 and FNN.GCO_GOOD_ID = iGoodId
                                 and instr(',' || nvl(iInternalStockList, FNN.STM_STOCK_ID) || ',', ',' || FNN.STM_STOCK_ID || ',') > 0
                                 and GCO_I_LIB_CHARACTERIZATION.IsOutdated(FNN.GCO_GOOD_ID, FNN.PAC_THIRD_ID, SPO.SPO_CHRONOLOGICAL, FNN.FAN_BEG_PLAN, null) = 1
                            order by FNN.FAN_BEG_PLAN
                          for update) loop
        SuppressionAttribution(tplOutdated.FAL_NETWORK_LINK_ID
                             , tplOutdated.FAL_NETWORK_NEED_ID
                             , tplOutdated.FAL_NETWORK_SUPPLY_ID
                             , tplOutdated.STM_STOCK_POSITION_ID
                             , tplOutdated.STM_LOCATION_ID
                             , tplOutdated.FLN_QTY
                              );
      end loop;
    end if;

    -- Suppression des attributions besoin sur stock à ré-analyser
    for tplRetested in (select     FNL.FAL_NETWORK_LINK_ID
                                 , FNL.FAL_NETWORK_NEED_ID
                                 , FNL.FAL_NETWORK_SUPPLY_ID
                                 , FNL.STM_STOCK_POSITION_ID
                                 , FNL.STM_LOCATION_ID
                                 , FNL.FLN_QTY
                              from FAL_NETWORK_LINK FNL
                                 , FAL_NETWORK_NEED FNN
                                 , STM_STOCK_POSITION SPO
                             where FNL.FAL_NETWORK_NEED_ID = FNN.FAL_NETWORK_NEED_ID
                               and SPO.STM_STOCK_POSITION_ID = FNL.STM_STOCK_POSITION_ID
                               and FNN.GCO_GOOD_ID = iGoodId
                               and instr(',' || nvl(iInternalStockList, FNN.STM_STOCK_ID) || ',', ',' || FNN.STM_STOCK_ID || ',') > 0
                               and STM_I_LIB_STOCK_POSITION.IsRetestNeeded(SPO.STM_STOCK_POSITION_ID, FNN.FAN_BEG_PLAN) = 1
                          order by FNN.FAN_BEG_PLAN
                        for update) loop
      SuppressionAttribution(tplRetested.FAL_NETWORK_LINK_ID
                           , tplRetested.FAL_NETWORK_NEED_ID
                           , tplRetested.FAL_NETWORK_SUPPLY_ID
                           , tplRetested.STM_STOCK_POSITION_ID
                           , tplRetested.STM_LOCATION_ID
                           , tplRetested.FLN_QTY
                            );
    end loop;
  end DeleteAllExpiredAttrib;
end FAL_REDO_ATTRIBS;
