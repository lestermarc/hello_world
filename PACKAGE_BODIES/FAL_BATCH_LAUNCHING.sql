--------------------------------------------------------
--  DDL for Package Body FAL_BATCH_LAUNCHING
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_BATCH_LAUNCHING" 
is
  -- ID unique de la session utilisé dans toutes les procédures de (dé)réservation
  cSessionId        constant FAL_LOT1.LT1_ORACLE_SESSION%type   := DBMS_SESSION.unique_session_id;
  cUseAccounting    constant boolean                            :=(PCS.PC_CONFIG.GetConfig('FAL_USE_ACCOUNTING') in('1', '2') );
  cProcBeforeLaunch constant varchar2(200)                      := PCS.PC_CONFIG.GetConfig('FAL_PROC_BEFORE_LAUNCH');

  /**
  * procedure ClearProcessData
  * Description
  *   Effacement des données la table COM_LIST_ID_TEMP liées au processus de lancement du lot
  */
  procedure ClearProcessData
  is
  begin
    COM_PRC_LIST_ID_TEMP.DeleteIDList(aCode => 'FAL_LOT_ID');
  end;

  /**
  * Function GetPreviousCoefCumul
  * Description :
  *
  * @created ECA
  * @lastUpdate
  * @private
  */
  function GetPreviousCoeffCumul(aGCO_GOOD_ID number, aRank integer, aSessionId varchar2)
    return number
  is
    aSumOfCoeff number;
  begin
    select sum(nvl(LOM.aLOM_CONSUMPTION_COEFF, 0) )
      into aSumOfCoeff
      from table(Table_FAL_LOT_MATERIAL_LINK) LOM
         , FAL_LOT1 LOT1
     where LOT1.FAL_LOT_ID = LOM.aFAL_LOT_ID
       and LOT1.LT1_LAUNCHABLE = 1
       and LOT1.LT1_ORDER_FIELD <= aRank
       and LOM.aGCO_GOOD_ID = aGCO_GOOD_ID;

    return aSumOfCoeff;
  exception
    when no_data_found then
      return 0;
  end;

  /**
  * Procedure CalcLaunchableBatches
  * Description : Algorithme de calcul des lots lancables
  *
  * @created ECA
  * @lastUpdate
  * @private
  *
  * @param   aSessionId   Session Oracle
  * @param   aOnlyUserSelectedBatches : Ne prendre en compte que les FAL_LTO1 dont LT1_SELECT = 1
  */
  procedure CalcLaunchableBatches(aSessionId varchar2, aOnlyUserSelectedBatches in integer default 0)
  is
    type T_BATCH_ID is table of number;

    type T_GOOD_ID is table of number;

    type T_COEFF is table of number;

    TabAllGood              T_GOOD_ID;
    TabAllCoeff             T_COEFF;
    TabBatchN               T_BATCH_ID;
    TabGoodN                T_GOOD_ID;
    TabCoeffN               T_COEFF;
    compatibleBatch         boolean;
    aStartRank              integer;
    aStrSelectCompoByRank   varchar2(4000);
    aStrSelectAllCompo      varchar2(4000);
    aNRank                  integer;
    aN1Rank                 integer;
    aMaxNRank               integer;
    existsCompatibleBatches boolean;
  begin
    -- initialisation des compteurs
    select nvl(min(LT1_ORDER_FIELD), 0)
         , nvl(max(LT1_ORDER_FIELD), 0)
      into aNRank
         , aMaxNRank
      from FAL_LOT1
     where LT1_LAUNCHABLE = 1
       and nvl(LT1_AVG_CONSUMPTION_COEFF, 0) > 0
       and LT1_ORACLE_SESSION = aSessionId
       and (   aOnlyUserSelectedBatches = 0
            or LT1_SELECT = 1);

    -- requête de sélection par rang
    aStrSelectCompoByRank    :=
      ' select   LOM.aFAL_LOT_ID ' ||
      '        , LOM.aGCO_GOOD_ID ' ||
      '        , LOM.aLOM_CONSUMPTION_COEFF ' ||
      '     from TABLE(FAL_BATCH_LAUNCHING.Table_FAL_LOT_MATERIAL_LINK) LOM ' ||
      '        , FAL_LOT1 LOT ' ||
      '    where LOT.FAL_LOT_ID = LOM.aFAL_LOT_ID ' ||
      '      and LOT.LT1_LAUNCHABLE = 1 ' ||
      '      and (:aOnlyUserSelectedBatches = 0 or LT1_SELECT = 1)' ||
      '      and NVL(LOT.LT1_AVG_CONSUMPTION_COEFF, 0) > 0 ' ||
      '      and NVL(LOM.aLOM_CONSUMPTION_COEFF, 0) > 0 ' ||
      '      and LOT.LT1_ORDER_FIELD = :aNRank ' ||
      '      and LOT.LT1_ORACLE_SESSION = :aSessionId ' ||
      ' order by LOT.LT1_ORDER_FIELD ' ||
      '        , NVL(LOT.LT1_AVG_CONSUMPTION_COEFF, 0) ' ||
      '        , LOT.LT1_LOT_PLAN_BEGIN_DTE ' ||
      '        , LOT.FAL_LOT_ID ' ||
      '        , LOM.aGCO_GOOD_ID asc ';
    aStartRank               := 1;
    existsCompatibleBatches  := false;

    loop
      exit when existsCompatibleBatches
            or aStartRank >= aMaxNRank;
      -- Sélection de tous les composants critiques
      aStrSelectAllCompo  :=
        ' select   DISTINCT ' ||
        '          LOM.aGCO_GOOD_ID ' ||
        '        , 0 ' ||
        '     from TABLE(FAL_BATCH_LAUNCHING.Table_FAL_LOT_MATERIAL_LINK) LOM ' ||
        '        , FAL_LOT1 LOT ' ||
        '    where LOT.FAL_LOT_ID = LOM.aFAL_LOT_ID ' ||
        '      and LOT.LT1_LAUNCHABLE = 1 ' ||
        '      and (:aOnlyUserSelectedBatches = 0 or LT1_SELECT = 1)' ||
        '      and NVL(LOT.LT1_AVG_CONSUMPTION_COEFF, 0) > 0 ' ||
        '      and NVL(LOM.aLOM_CONSUMPTION_COEFF, 0) > 0 ' ||
        '      and LOT.LT1_ORDER_FIELD >= :aStartRank ' ||
        '      and LOT.LT1_ORACLE_SESSION = :aSessionId ';

      execute immediate aStrSelectAllCompo
      bulk collect into TabAllGood
                      , TabAllCoeff
                  using aOnlyUserSelectedBatches, aStartRank, aSessionId;

      aNRank              := aStartRank;

      loop
        exit when aNRank > aMaxNRank;

        -- Sélection des composants de rang N
        execute immediate aStrSelectCompoByRank
        bulk collect into TabBatchN
                        , TabGoodN
                        , TabCoeffN
                    using aOnlyUserSelectedBatches, aNRank, aSessionId;

        if TabGoodN.count > 0 then
          CompatibleBatch  := true;

          for i in TabGoodN.first .. TabGoodN.last loop
            if TabAllGood.count > 0 then
              for j in TabAllGood.first .. TabAllGood.last loop
                if TabGoodN(i) = TabAllGood(j) then
                  if TabAllCoeff(j) + TabCoeffN(i) > 1 then
                    compatibleBatch  := false;

                    update FAL_LOT1
                       set LT1_LAUNCHABLE = 0
                     where FAL_LOT_ID = TabBatchN(i)
                       and LT1_ORACLE_SESSION = aSessionId;
                  end if;

                  TabAllCoeff(j)  := TabAllCoeff(j) + TabCoeffN(i);
                  exit;
                end if;
              end loop;
            end if;
          end loop;

          if not CompatibleBatch then
            for i in TabGoodN.first .. TabGoodN.last loop
              if TabAllGood.count > 0 then
                for j in TabAllGood.first .. TabAllGood.last loop
                  if TabGoodN(i) = TabAllGood(j) then
                    TabAllCoeff(j)  := TabAllCoeff(j) - TabCoeffN(i);
                    exit;
                  end if;
                end loop;
              end if;
            end loop;
          else
            existsCompatibleBatches  := true;
          end if;
        end if;

        aNRank  := aNRank + 1;
      end loop;

      if not existsCompatibleBatches then
        aStartRank  := aStartRank + 1;

        update FAL_LOT1
           set LT1_LAUNCHABLE = 1
         where (   aOnlyUserSelectedBatches = 0
                or LT1_SELECT = 1)
           and LT1_ORACLE_SESSION = aSessionId
           and LT1_ORDER_FIELD < aStartRank;

        update FAL_LOT1
           set LT1_LAUNCHABLE = 1
         where LT1_LAUNCHABLE = 0
           and (   aOnlyUserSelectedBatches = 0
                or LT1_SELECT = 1)
           and LT1_ORACLE_SESSION = aSessionId
           and LT1_ORDER_FIELD >= aStartRank;
      end if;
    end loop;
  end;

  /**
  * function Table_FAL_LOT_MATERIAL_LINK
  * Description : Récupération des composants sélectionnés pour l'optimisation
  *   du lancement
  *
  * @created ECA
  * @lastUpdate
  * @public
  */
  function Table_FAL_LOT_MATERIAL_LINK
    return TComponents pipelined
  is
  begin
    if TabComponents.count > 0 then
      for i in TabComponents.first .. TabComponents.last loop
        pipe row(TabComponents(i) );
      end loop;
    end if;
  end Table_FAL_LOT_MATERIAL_LINK;

  /**
  * procedure LoadComponents
  * Description : Optimisation du lancement, chargement en mémoire des composants
  *   des lots de fabrication lancables dont la quantité besoin totale est > à
  *   la quantité dispo en stock et calcul du coefficient de consommation du
  *   disponible de chacun.
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   aUseCDischargeCom       Selon code décharge
  * @param   aUseNeedQtyOnBatches    Prise en compte des qtés besoins sur OF
  * @param   aSessionId              Session Oracle
  * @param   aOnlyUserSelectedBatches : Ne prendre en compte que les FAL_LTO1 dont LT1_SELECT = 1
  */
  procedure LoadComponents(aUseCDischargeCom integer, aUseNeedQtyOnBatches integer, aSessionId varchar2, aOnlyUserSelectedBatches in integer default 0)
  is
    aStrSQLQuery varchar2(32000);
  begin
    aStrSQLQuery  :=
      ' select ' ||
      '     LOM.GCO_GOOD_ID ' ||
      '   , LOM.STM_STOCK_ID ' ||
      '   , LOM.STM_LOCATION_ID ' ||
      '   , LOM.FAL_LOT_ID ' ||
      '   , (FNN.FAN_FREE_QTY + FNN.FAN_NETW_QTY) as LOM_NEED_QTY ' ||
      '   , (FNN.FAN_FREE_QTY + FNN.FAN_NETW_QTY) ' ||
      '      / FAL_TOOLS.NVLA(FAL_COMPONENT_FUNCTIONS.GetAvailableComponentQty(LOM.GCO_GOOD_ID ' ||
      '                                                                      , LOM.STM_STOCK_ID ' ||
      '                                                                      , LOM.STM_LOCATION_ID ' ||
      '                                                                      , :aUseNeedQtyOnBatches), 1) as LOM_CONSUPTION_COEFF ' ||
      ' from ' ||
      '     FAL_LOT_MATERIAL_LINK LOM ' ||
      '   , FAL_LOT1 LOT ' ||
      '   , FAL_NETWORK_NEED FNN ' ||
      '   , (select SUM(FNN2.FAN_FREE_QTY + FNN2.FAN_NETW_QTY) LOM_NEED_QTY ' ||
      '           , LOM2.GCO_GOOD_ID ' ||
      '           , LOM2.STM_STOCK_ID ' ||
      '           , LOM2.STM_LOCATION_ID ' ||
      '        from FAL_LOT_MATERIAL_LINK LOM2 ' ||
      '           , FAL_LOT1 LOT2 ' ||
      '           , FAL_NETWORK_NEED FNN2 ' ||
      '       where LOT2.FAL_LOT_ID = LOM2.FAL_LOT_ID ' ||
      '         and LOM2.FAL_LOT_MATERIAL_LINK_ID = FNN2.FAL_LOT_MATERIAL_LINK_ID ' ||
      '         and LOT2.LT1_LAUNCHABLE = 1 ' ||
      '         and LOT2.LT1_ORACLE_SESSION = :aSessionId ' ||
      '         and (:aOnlyUserSelectedBatches = 0 or LOT2.LT1_SELECT = 1) ' ||
      '         and LOM2.C_TYPE_COM = ''1'' ' ||
      '         and LOM2.LOM_STOCK_MANAGEMENT = ''1'' ' ||
      '         and LOM2.C_KIND_COM = ''1'' ' ||
      '         and (:aUseCDischargeCom = 0 or LOM2.C_DISCHARGE_COM = ''1'' or LOM2.C_DISCHARGE_COM = ''5'' or LOM2.C_DISCHARGE_COM = ''6'' ) ' ||
      '       group by LOM2.GCO_GOOD_ID ' ||
      '              , LOM2.STM_STOCK_ID ' ||
      '              , LOM2.STM_LOCATION_ID) TOTAL_NEED_QTY ' ||
      '   , (select NVL(FAL_COMPONENT_FUNCTIONS.GetAvailableComponentQty(LOM3.GCO_GOOD_ID ' ||
      '                                                                , LOM3.STM_STOCK_ID ' ||
      '                                                                , LOM3.STM_LOCATION_ID ' ||
      '                                                                , :aUseNeedQtyOnBatches), 0) AVAILABLE_QTY ' ||
      '           , LOM3.GCO_GOOD_ID ' ||
      '           , LOM3.STM_STOCK_ID ' ||
      '           , LOM3.STM_LOCATION_ID ' ||
      '        from FAL_LOT_MATERIAL_LINK LOM3  ' ||
      '           , FAL_LOT1 LOT3 ' ||
      '       where LOT3.FAL_LOT_ID = LOM3.FAL_LOT_ID ' ||
      '         and LOT3.LT1_LAUNCHABLE = 1 ' ||
      '         and LOT3.LT1_ORACLE_SESSION = :aSessionId ' ||
      '         and (:aOnlyUserSelectedBatches = 0 or LOT3.LT1_SELECT = 1) ' ||
      '         and LOM3.C_TYPE_COM = ''1'' ' ||
      '         and LOM3.LOM_STOCK_MANAGEMENT = ''1'' ' ||
      '         and LOM3.C_KIND_COM = ''1'' ' ||
      '         and (:aUseCDischargeCom = 0 or LOM3.C_DISCHARGE_COM = ''1'' or LOM3.C_DISCHARGE_COM = ''5'' or LOM3.C_DISCHARGE_COM = ''6'' ) ' ||
      '      group by LOM3.GCO_GOOD_ID ' ||
      '             , LOM3.STM_STOCK_ID ' ||
      '             , LOM3.STM_LOCATION_ID) TOTAL_AVAILABLE_QTY' ||
      ' where ' ||
      '     LOM.FAL_LOT_ID = LOT.FAL_LOT_ID ' ||
      ' and LOT.LT1_ORACLE_SESSION = :aSessionId ' ||
      ' and LOM.FAL_LOT_MATERIAL_LINK_ID = FNN.FAL_LOT_MATERIAL_LINK_ID ' ||
      ' and LOT.LT1_LAUNCHABLE = 1 ' ||
      ' and (:aOnlyUserSelectedBatches = 0 or LOT.LT1_SELECT = 1) ' ||
      ' and LOM.C_TYPE_COM = ''1'' ' ||
      ' and LOM.LOM_STOCK_MANAGEMENT = ''1'' ' ||
      ' and LOM.C_KIND_COM = ''1'' ' ||
      ' and (:aUseCDischargeCom = 0 or LOM.C_DISCHARGE_COM = ''1'' or LOM.C_DISCHARGE_COM = ''5'' or LOM.C_DISCHARGE_COM = ''6'' )' ||
      ' and LOM.GCO_GOOD_ID = TOTAL_NEED_QTY.GCO_GOOD_ID (+) ' ||
      ' and LOM.STM_STOCK_ID = TOTAL_NEED_QTY.STM_STOCK_ID (+) ' ||
      ' and LOM.STM_LOCATION_ID = TOTAL_NEED_QTY.STM_LOCATION_ID (+) ' ||
      ' and LOM.GCO_GOOD_ID = TOTAL_AVAILABLE_QTY.GCO_GOOD_ID (+) ' ||
      ' and LOM.STM_STOCK_ID = TOTAL_AVAILABLE_QTY.STM_STOCK_ID (+) ' ||
      ' and LOM.STM_LOCATION_ID = TOTAL_AVAILABLE_QTY.STM_LOCATION_ID (+) ' ||
      ' and NVL(TOTAL_NEED_QTY.LOM_NEED_QTY, 0) > NVL(TOTAL_AVAILABLE_QTY.AVAILABLE_QTY, 0) ';

    execute immediate aStrSQLQuery
    bulk collect into TabComponents
                using aUseNeedQtyOnBatches
                    , aSessionId
                    , aOnlyUserSelectedBatches
                    , aUseCDischargeCom
                    , aUseNeedQtyOnBatches
                    , aSessionId
                    , aOnlyUserSelectedBatches
                    , aUseCDischargeCom
                    , aSessionId
                    , aOnlyUserSelectedBatches
                    , aUseCDischargeCom;
  exception
    when others then
      raise;
  end LoadComponents;

  /**
  * procedure CalcBatchAvgConsumptionCoef
  * Description : Calcul du coefficient Moyen de consommation du stock de chaque OF.
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   aSessionId   Sesison oracle
  * @param   aOnlyUserSelectedBatches : Ne prendre en compte que les FAL_LTO1 dont LT1_SELECT = 1
  */
  procedure CalcBatchAvgConsumptionCoef(aSessionId varchar2, aOnlyUserSelectedBatches in integer default 0)
  is
  begin
    update FAL_LOT1 LOT
       set LOT.LT1_AVG_CONSUMPTION_COEFF = nvl( (select sum(LOM.aLOM_CONSUMPTION_COEFF)
                                                   from table(Table_FAL_LOT_MATERIAL_LINK) LOM
                                                  where LOM.aFAL_LOT_ID = LOT.FAL_LOT_ID), 0)
     where LOT.LT1_LAUNCHABLE = 1
       and LOT.LT1_ORACLE_SESSION = aSessionId
       and (   aOnlyUserSelectedBatches = 0
            or LOT.LT1_SELECT = 1);
  exception
    when others then
      raise;
  end CalcBatchAvgConsumptionCoef;

  /**
  * procedure CalcBatchOrderField
  * Description : Calcul du Champ ordre de traitement.
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   aCOptimizationMethod  Méthode d'optimisation
  * @param   aSessionId   Session Oracle
  * @param   aOnlyUserSelectedBatches : Ne prendre en compte que les FAL_LTO1 dont LT1_SELECT = 1
  */
  procedure CalcBatchOrderField(aCOptimizationMethod varchar2, aSessionId varchar2)
  is
    type TTabBatchID is table of number;

    type TTabOrder is table of number;

    TabBatchID       TTabBatchID;
    TabOrder         TTabOrder;
    StrSelectBatches varchar2(1000);
  begin
    -- Méthode avec priorité au volume.
    if aCOptimizationMethod = omVolumePriority then
      StrSelectBatches  :=
        ' select FAL_LOT_ID ' ||
        '      , rownum ' ||
        '   from (select FAL_LOT_ID ' ||
        '           from FAL_LOT1 ' ||
        '          where LT1_ORACLE_SESSION = :aSessionId ' ||
        '       order by NVL(LT1_SELECT, 0) desc ' ||
        '              , LT1_AVG_CONSUMPTION_COEFF asc ' ||
        '              , LT1_LOT_PLAN_BEGIN_DTE asc ' ||
        '              , LT1_LOT_REFCOMPL asc ) ';
    -- Méthode avec priorité au délai.
    elsif aCOptimizationMethod = omDelayPriority then
      StrSelectBatches  :=
        ' select FAL_LOT_ID ' ||
        '      , rownum ' ||
        '   from (select FAL_LOT_ID ' ||
        '           from FAL_LOT1 ' ||
        '          where LT1_ORACLE_SESSION = :aSessionId ' ||
        '       order by NVL(LT1_SELECT, 0) desc ' ||
        '              , LT1_LOT_PLAN_BEGIN_DTE asc ' ||
        '              , LT1_LOT_REFCOMPL asc ) ';
    end if;

    execute immediate StrSelectBatches
    bulk collect into TabBatchID
                    , TabOrder
                using aSessionId;

    if TabBatchID.count > 0 then
      forall i in TabBatchID.first .. TabBatchID.last
        update FAL_LOT1
           set LT1_ORDER_FIELD = TabOrder(i)
         where FAL_LOT_ID = TabBatchID(i);
    end if;
  exception
    when others then
      raise;
  end CalcBatchOrderField;

  /**
  * procedure IdentifyUnLaunchableBatches
  * Description : Identification des lots non lancables, dans le cadre des procédures d'optimisation
  *               Mise à 0 du champ LT1_LAUNCHABLE des lots :
  *   1) Pour lesquels il existe un composant dont la quantité disponible en stock est  = 0
  *   2) Pour lesquels il existe un composant dont la quantité besoin est > à la quantité dispo en stock.
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   aUseCDischargeCom       Prise en compte du code décharge
  * @param   aUseOFRemainNeedQty     Prise en compte des qté à sortir sur les lots en cours de fabrication
  * @param   aSessionId              Session Oracle (délimite les OFs à prendre en compte)
  * @param   aOnlyUserSelectedBatches : Ne prendre en compte que les FAL_LTO1 dont LT1_SELECT = 1
  */
  procedure IdentifyUnLaunchableBatches(
    aUseCDischargeCom           integer default 1
  , aUseOFRemainNeedQty         integer default 0
  , aSessionId                  varchar2
  , aOnlyUserSelectedBatches in integer default 0
  )
  is
    aStrSelectQry varchar2(32000);
  begin
    aStrSelectQry  :=
      ' Update FAL_LOT1 LOT1 ' ||
      '    set LOT1.LT1_LAUNCHABLE = 0 ' ||
      '  where LOT1.FAL_LOT_ID IN (' ||
      ' select NEED_QTY.FAL_LOT_ID ' ||
      '   from (select   LOT.FAL_LOT_ID ' ||
      '                , LOM.GCO_GOOD_ID ' ||
      '                , LOM.STM_STOCK_ID ' ||
      '                , LOM.STM_LOCATION_ID ' ||
      '                , nvl(sum(FNN.FAN_FREE_QTY + FNN.FAN_NETW_QTY), 0) QTY ' ||
      '             from FAL_LOT_MATERIAL_LINK LOM ' ||
      '                , FAL_LOT1 LOT ' ||
      '                , FAL_NETWORK_NEED FNN ' ||
      '            where LOM.C_TYPE_COM = 1 ' ||
      '              and LOM.LOM_STOCK_MANAGEMENT = 1 ' ||
      '              and LOM.C_KIND_COM = 1 ' ||
      '              and (   :aUseCDischargeCom = 0 ' ||
      '                   or (    :aUseCDischargeCom = 1 ' ||
      '                       and (   LOM.C_DISCHARGE_COM = 1 ' ||
      '                            or LOM.C_DISCHARGE_COM = 5 ' ||
      '                            or LOM.C_DISCHARGE_COM = 6) ) ' ||
      '                  ) ' ||
      '              and LOM.FAL_LOT_ID = LOT.FAL_LOT_ID ' ||
      '              and LOM.FAL_LOT_MATERIAL_LINK_ID = FNN.FAL_LOT_MATERIAL_LINK_ID ' ||
      '              and (NVL(FNN.FAN_FREE_QTY, 0) + NVL(FNN.FAN_NETW_QTY, 0)) > 0 ' ||
      '              and LOT.LT1_ORACLE_SESSION = :aSessionId ' ||
      '              and (:aOnlyUserSelectedBatches = 0 or LT1_SELECT = 1) ' ||
      '         group by LOT.FAL_LOT_ID ' ||
      '                , LOM.GCO_GOOD_ID ' ||
      '                , LOM.STM_STOCK_ID ' ||
      '                , LOM.STM_LOCATION_ID) NEED_QTY ' ||
      '  where NEED_QTY.QTY > ' ||
      '          FAL_COMPONENT_FUNCTIONS.GetAvailableComponentQty(NEED_QTY.GCO_GOOD_ID ' ||
      '                                                         , NEED_QTY.STM_STOCK_ID ' ||
      '                                                         , NEED_QTY.STM_LOCATION_ID ' ||
      '                                                         , :aUseNeedQtyOnBatches) ' ||
      '     or FAL_COMPONENT_FUNCTIONS.GetAvailableComponentQty(NEED_QTY.GCO_GOOD_ID ' ||
      '                                                       , NEED_QTY.STM_STOCK_ID ' ||
      '                                                       , NEED_QTY.STM_LOCATION_ID ' ||
      '                                                       , :aUseNeedQtyOnBatches) = 0 )';

    execute immediate aStrSelectQry
                using aUseCDischargeCom, aUseCDischargeCom, aSessionId, aOnlyUserSelectedBatches, aUseOFRemainNeedQty, aUseOFRemainNeedQty;
  exception
    when others then
      raise;
  end IdentifyUnLaunchableBatches;

  /**
  * procedure : ReserveComponentsOnLaunch
  * Description : Réservation des composants pour les lots sélectionnés
  *
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aSessionId        Session Oracle
  * @param   aCaseReleaseCode  Tient compte ou non du code de décharge du composant
  * @param   aFalLotId         Lot à réserver (tous les lots1 sélectionnés si ce paramètre est null)
  * @param   aUseRemainNeedQty  Est-ce que l'on tient compte ou pas Qté besoins libres sur les OF Lancés
  * @param   aDisplayAllComponentsDispo Affichage de la disponibilité de tous les composants.
  */
  procedure ReserveComponentsOnLaunch(
    aSessionId                 FAL_LOT1.LT1_ORACLE_SESSION%type default null
  , aCaseReleaseCode           integer
  , aFalLotId                  FAL_LOT.FAL_LOT_ID%type default null
  , aUseRemainNeedQty          integer default 0
  , aDisplayAllComponentsDispo integer default 0
  )
  is
    cursor Cur_SelectedFalLot1
    is
      select   FAL_LOT_ID
          from FAL_LOT1
         where LT1_ORACLE_SESSION = nvl(aSessionId, cSessionId)
           and (    (    aFalLotId is not null
                     and FAL_LOT_ID = aFalLotId)
                or (    aFalLotId is null
                    and LT1_SELECT = 1) )
      order by LT1_LAUNCHABLE desc
             , LT1_ORDER_FIELD asc
             , LT1_LOT_PLAN_BEGIN_DTE asc
             , LT1_LOT_REFCOMPL asc;
  begin
    for CurSelectedFalLot1 in Cur_SelectedFalLot1 loop
      FAL_COMPONENT_MVT_SORTIE.ComponentAndLinkGenForOutput(aFAL_LOT_ID                  => CurSelectedFalLot1.FAL_LOT_ID
                                                          , aFCL_SESSION_ID              => nvl(aSessionId, cSessionId)
                                                          , aOpSeqFrom                   => null
                                                          , aOpSeqTo                     => null
                                                          , aComponentWithNeed           => 0
                                                          , aBalanceNeed                 => 1
                                                          , aContext                     => FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchLaunch
                                                          , aCaseReleaseCode             => aCaseReleaseCode
                                                          , aUseRemainNeedQty            => aUseRemainNeedQty
                                                          , aDisplayAllComponentsDispo   => aDisplayAllComponentsDispo
                                                           );
    end loop;

    FAL_LOT_MAT_LINK_TMP_FUNCTIONS.UpdateMaxReceiptQty(nvl(aSessionId, cSessionId) );
    FAL_BATCH_FUNCTIONS.UpdateMaxManufacturableQty(aSessionId => nvl(aSessionId, cSessionId), aFalLotId => aFalLotId, aCaseReleaseCode => aCaseReleaseCode);
  end ReserveComponentsOnLaunch;

  /**
  * procedure : LaunchBatch
  * Description : Lancement d'un lot de fabrication
  *
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aSessionId              Session Oracle
  * @param   aFalLotId               Id du Lot à lancer
  * @param   LotPlanBeginDate        Date début planifiée du lot
  * @param   FalOrderId              ID de l'ordre
  * @param   aLaunchDate             Date de lancement
  * @param   doComponentReservation  Indique s'il faut effectuer la réservation des composants du lot ou non
  * @param   aCaseReleaseCode        Tient compte ou non du code de décharge du composant pour la réservation
  */
  procedure LaunchBatch(
    aSessionId             FAL_LOT1.LT1_ORACLE_SESSION%type default null
  , aFalLotId              FAL_LOT.FAL_LOT_ID%type
  , LotPlanBeginDate       FAL_LOT1.LT1_LOT_PLAN_BEGIN_DTE%type
  , FalOrderId             FAL_LOT.FAL_ORDER_ID%type
  , aLaunchDate            date
  , doComponentReservation integer default 0
  , aCaseReleaseCode       integer default 1
  )
  is
    LocPreparedStockMovements FAL_STOCK_MOVEMENT_FUNCTIONS.TPreparedStockMovements;
    aErrorCode                varchar2(255);
    aErrorMsg                 varchar2(255);
    lvBatchType               FAL_LOT.C_FAB_TYPE%type;
  begin
    LocPreparedStockMovements  := FAL_STOCK_MOVEMENT_FUNCTIONS.TPreparedStockMovements();

    if doComponentReservation = 1 then
      FAL_LOT_MAT_LINK_TMP_FUNCTIONS.PurgeLotMatLinkTmpTable(aSessionId);
      ReserveComponentsOnLaunch(aSessionId, aCaseReleaseCode, aFalLotId);
    end if;

    -- Création des réservations sur stock des composants avec code décharge 5 et 6
    FAL_COMPONENT_FUNCTIONS.ReserveComponentDischargeCode5(aFalLotId => aFalLotId, aSessionId => aSessionId);
    -- Suppression des réservations pour les composants de type code décharge = 5 (dispo au lancement)
    -- et 6 (mouvements pour le stock sous-traitant)
    -- On en tient compte pour la simulation mais on ne sort pas les composants au lancement
    FAL_COMPONENT_LINK_FCT.DeleteCompoLinkReleaseCode5(aSessionId, aFalLotId);

    -- Si selon code décharge, suppression des composant avec code décharge 234, créé pour affichage
    -- et information de la disponibilité à l'utilisateur.
    if aCaseReleaseCode = 1 then
      FAL_COMPONENT_LINK_FUNCTIONS.DeleteCompoLinkReleaseCode234(aSessionId, aFalLotId);
    end if;

    -- Si une date de lancement est saisie, différence de la date début planifié du
    -- lot, on le replanifie.
    if nvl(aLaunchDate, LotPlanBeginDate) <> LotPlanBeginDate then
      FAL_PLANIF.PLANIFICATION_LOT(PrmFAL_LOT_ID              => aFalLotId
                                 , DatePlanification          => aLaunchDate
                                 , SelonDateDebut             => FAL_PLANIF.ctDateDebut
                                 , MAJReqLiensComposantsLot   => FAL_PLANIF.ctAvecMAJLienCompoLot
                                 , MAJ_Reseaux_Requise        => FAL_PLANIF.ctSansMAJReseau
                                  );
    end if;

    FAL_COMPONENT_FUNCTIONS.UpdateFalLotMatLinkafterOutput(aLOM_SESSION   => aSessionId
                                                         , aFAL_LOT_ID    => aFalLotId
                                                         , aContext       => FAL_COMPONENT_LINK_FUNCTIONS.ctxtComponentOutput
                                                          );

    -- Pour tous les composants non gérés en stock, la quantité consommation
    -- est égale à la quantité besoin totale
    update FAL_LOT_MATERIAL_LINK
       set LOM_CONSUMPTION_QTY = LOM_FULL_REQ_QTY
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_LOT_ID = aFalLotId
       and LOM_STOCK_MANAGEMENT <> 1;

    -- Recherche le type de fabrication du lot
    select nvl(C_FAB_TYPE, '0')
      into lvBatchType
      from FAL_LOT
     where FAL_LOT_ID = aFalLotId;

    -- Mise à jour lien tâche lot pseudo. Qté dispo = Qté solde pour la première opération principale du lot
    -- sauf dans le cas d'un lot sous-traitance d'achat (C_FAB_TYPE = '4').
    -- En effet, dans ce cas : Qté en cours = Qté solde
    update FAL_TASK_LINK
       set TAL_AVALAIBLE_QTY = decode(lvBatchType, '4', TAL_AVALAIBLE_QTY, TAL_DUE_QTY)
         , TAL_SUBCONTRACT_QTY = decode(lvBatchType, '4', TAL_DUE_QTY, TAL_SUBCONTRACT_QTY)
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_LOT_ID = aFalLotId
       and SCS_STEP_NUMBER = (select min(SCS_STEP_NUMBER)
                                from FAL_TASK_LINK
                               where FAL_LOT_ID = aFalLotId
                                 and C_OPERATION_TYPE = '1');

    -- Mise à jour lot pseudo
    FAL_BATCH_FUNCTIONS.UpdateBatch(aFalLotId => aFalLotId, aContext => FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchLaunch);

    -- Planification de base en fonction de la configuration FAL_INITIAL_PLANIFICATION
    if nvl(PCS.PC_CONFIG.GetConfig('FAL_INITIAL_PLANIFICATION'), '0') = '0' then
      FAL_BATCH_FUNCTIONS.DoBasisLotPlanification(aFalLotId);
    end if;

    -- mise à jour de l'ordre (En-cours)
    FAL_ORDER_FUNCTIONS.UpdateOrder(aFAL_ORDER_ID => FalOrderId, aC_ORDER_STATUS => '2');
    -- Création de l'historique de lancement
    FAL_BATCH_FUNCTIONS.CreateBatchHistory(aFAL_LOT_ID => aFalLotId, aC_EVEN_TYPE => '2');
    -- Création des entrées atelier pour le lot
    FAL_COMPONENT_FUNCTIONS.CreateAllFactoryMovements(aFAL_LOT_ID              => aFalLotId
                                                    , aFCL_SESSION             => aSessionId
                                                    , aPreparedStockMovement   => LocPreparedStockMovements
                                                    , aOUT_DATE                => sysdate
                                                    , aMovementKind            => FAL_STOCK_MOVEMENT_FUNCTIONS.mktSortieStockVersAtelier
                                                    , aC_IN_ORIGINE            => '1'   -- Lancement
                                                     );
    FAL_LOT_MAT_LINK_TMP_FCT.PurgeTemporaryTable(aFalLotId);
    -- Mise à jour Réseaux
    FAL_NETWORK.MiseAJourReseaux(aFalLotId, FAL_NETWORK.ncLancementLot, '');
    -- Déclencher les mouvements de stock préalablement préparés
    FAL_STOCK_MOVEMENT_FUNCTIONS.ApplyPreparedStockMovements(aErrorCode                => aErrorCode
                                                           , aErrorMsg                 => aErrorMsg
                                                           , aPreparedStockMovements   => LocPreparedStockMovements
                                                           , MvtsContext               => FAL_STOCK_MOVEMENT_FUNCTIONS.ctxDefault
                                                            );
    -- Mise à jour des Entrées Atelier avec les positions de stock créées
    -- dans le stock Atelier par les mouvements de stock
    FAL_STOCK_MOVEMENT_FUNCTIONS.UpdFactEntriesWthAppliedStkMvt(LocPreparedStockMovements);

    -- Génération automatique des numéros de série de détail lot selon que la config est activée ou non
    if     (upper(PCS.PC_CONFIG.GetConfig('FAL_GEN_DETAIL_AFTER_LAUNCH') ) = 'TRUE')
       and (lvBatchType <> '4') then
      FAL_LOT_DETAIL_FUNCTIONS.GeneratePieceLotDetailByLot(aFalLotId);
    end if;

    -- Comptabilité industrielle, mise à jour du prix avec le
    if cUseAccounting then
      FAL_ACCOUNTING_FUNCTIONS.UpdateBatchPRFCI(aFalLotId);
    end if;
  end LaunchBatch;

  /**
  * procedure : LaunchBatches
  * Description : Lancement des lots de fabrication sur la base des FAL_LOT1 sélectionnés
  *      ou du lot passé en paramètre s'il est non null
  *
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aSessionId        Session Oracle
  * @param   aFalLotId         Lot à lancer (si lancement d'un lot seul et non les lots1 sélectionnés)
  * @param   aSimulationDone   Indique si la simulation de lancement a été effectuée.
  *                            La fait si ce n'est pas le cas
  * @param   aCaseReleaseCode  Tiens compte ou non du code de décharge des composants pour la sortie
  * @param   aCaseMaxManufacturableQty  Tient compte ou non de la Qté max fabricable du lot
  * @param   aLaunchDate       Date de lancement du lot (Replanif à partir de cette date si non nulle)
  */
  procedure LaunchBatches(
    aSessionId                FAL_LOT1.LT1_ORACLE_SESSION%type default null
  , aFalLotId                 FAL_LOT.FAL_LOT_ID%type default null
  , aSimulationDone           integer default 0
  , aCaseReleaseCode          integer default 1
  , aCaseMaxManufacturableQty integer default 0
  , aLaunchDate               date default null
  )
  is
    cursor Cur_SelectedFalLot1
    is
      select   FAL_LOT_ID
             , LT1_LOT_PLAN_BEGIN_DTE
             , (select FAL_ORDER_ID
                  from FAL_LOT
                 where FAL_LOT_ID = LOT1.FAL_LOT_ID) FAL_ORDER_ID
          from FAL_LOT1 LOT1
         where LT1_ORACLE_SESSION = aSessionId
           and (    (    aFalLotId is not null
                     and FAL_LOT_ID = aFalLotId)
                or (    aFalLotId is null
                    and LT1_SELECT = 1) )
           and (    (aCaseMaxManufacturableQty = 0)
                or (    aCaseMaxManufacturableQty = 1
                    and LT1_LOT_TOTAL_QTY <= LT1_LOT_MAX_FAB_QTY) )
      order by LT1_LOT_PLAN_BEGIN_DTE asc
             , LT1_LOT_REFCOMPL asc;
  begin
    if aSimulationDone = 0 then
      FAL_LOT_MAT_LINK_TMP_FUNCTIONS.PurgeLotMatLinkTmpTable(aSessionId);
      ReserveComponentsOnLaunch(aSessionId, aCaseReleaseCode, aFalLotId);
    end if;

    for CurSelectedFalLot1 in Cur_SelectedFalLot1 loop
      LaunchBatch(aSessionId         => aSessionId
                , aFalLotId          => CurSelectedFalLot1.FAL_LOT_ID
                , LotPlanBeginDate   => CurSelectedFalLot1.LT1_LOT_PLAN_BEGIN_DTE
                , FalOrderId         => CurSelectedFalLot1.FAL_ORDER_ID
                , aLaunchDate        => aLaunchDate
                , aCaseReleaseCode   => aCaseReleaseCode
                 );
      commit;
    end loop;
  end LaunchBatches;

  /**
  * procedure : InitReservedBatchesAfterLaunch
  * Description : Suppression des FAL_LOT1 traités et remise à 0 des Qté max fabricable
  *               des FAL_LOT1 restants
  *
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aSessionId                 Session Oracle
  * @param   aCaseMaxManufacturableQty  Tient compte ou non de la Qté max fabricable du lot
  * @param   aFalLotId                  Lot à mettre à jour (tous les lots1 sélectionnés si ce paramètre est null)
  */
  procedure InitReservedBatchesAfterLaunch(
    aSessionId                FAL_LOT1.LT1_ORACLE_SESSION%type default null
  , aCaseMaxManufacturableQty integer default 0
  , aFalLotId                 FAL_LOT.FAL_LOT_ID%type default null
  )
  is
    pragma autonomous_transaction;
  begin
    -- Suppression des FAL_LOT1 traités et remise à 0 des Qté max fabricable des FAL_LOT1 restants
    delete from FAL_LOT1 LOT1
          where LT1_ORACLE_SESSION = nvl(aSessionId, cSessionId)
            and (    (    aFalLotId is not null
                      and FAL_LOT_ID = aFalLotId)
                 or (    aFalLotId is null
                     and LT1_SELECT = 1) )
            and (    (aCaseMaxManufacturableQty = 0)
                 or (    aCaseMaxManufacturableQty = 1
                     and LT1_LOT_TOTAL_QTY <= LT1_LOT_MAX_FAB_QTY) );

    -- remise à 0 des Qté max fabricable des FAL_LOT1 restants
    update FAL_LOT1
       set LT1_LOT_MAX_FAB_QTY = 0
     where LT1_ORACLE_SESSION = aSessionId;

    commit;
  end InitReservedBatchesAfterLaunch;

  /**
  * Procedure LaunchBatch
  * Description
  *   Lancement d'un lot
  * @author CLE
  * @lastUpdate
  * @public
  * @param   aSessionId        Session Oracle
  * @param   aFalLotId         Lot à lancer
  * @param   aCaseReleaseCode  Tiens compte ou non du code de décharge des composants pour la sortie
  * @param   aCaseMaxManufacturableQty  Tient compte ou non de la Qté max fabricable du lot
  * @param   aLaunchDate       Date de lancement du lot (Replanif à partir de cette date si non nulle)
  * @param   aManageBatchReservation   Gère ou pas la réservation, déréservation du lot de fabrication.
  */
  procedure LaunchBatch(
    aFalLotId                 FAL_LOT.FAL_LOT_ID%type
  , aSessionId                varchar2 default null
  , aCaseReleaseCode          integer default 1
  , aCaseMaxManufacturableQty integer default 0
  , aLaunchDate               date default null
  , aManageBatchReservation   integer default 1
  )
  is
    SessionId FAL_LOT1.LT1_ORACLE_SESSION%type;
    aErrorMsg varchar2(255);
  begin
    SessionId  := nvl(aSessionId, DBMS_SESSION.unique_session_id);

    if aManageBatchReservation = 1 then
      FAL_BATCH_RESERVATION.PurgeInactiveBatchReservation;
      FAL_BATCH_RESERVATION.BatchReservation(aFAL_LOT_ID => aFalLotId, aLT1_ORACLE_SESSION => SessionId, aErrorMsg => aErrorMsg);

      if trim(aErrorMsg) <> '' then
        raise_application_error(-20010, aErrorMsg);
      end if;
    end if;

    LaunchBatches(aSessionId                  => SessionId
                , aFalLotId                   => aFalLotId
                , aCaseReleaseCode            => aCaseReleaseCode
                , aCaseMaxManufacturableQty   => aCaseMaxManufacturableQty
                , aLaunchDate                 => aLaunchDate
                 );

    if aManageBatchReservation = 1 then
      FAL_BATCH_RESERVATION.ReleaseBatch(aFalLotId, SessionId);
    end if;
  end LaunchBatch;

/**
  * Procedure SelectBatchToLaunch
  * Description
  *   Sélection des lots à lancer selon les filtres
  * @author ECA
  * @lastUpdate
  * @public
  * @param aStartDateMin : Date debut min
  * @param aStartDateMax : Date début max
  * @param aEndDateMin : Date fin min
  * @param aEndDateMax : Date fin max
  * @param aProgMin : Programme de fab min
  * @param aProgMax : Programme de fab max
  * @param aOrdMin : Ordre Min
  * @param aOrdMax : Ordre Max
  * @param aCmdProg : Commande du programme
  * @param aPrioriteMin : Priorité min
  * @param aPrioriteMax  : Priorité max
  * @param aFamily : Famille
  * @param aDocRecordMin : Dossier min
  * @param aDocRecordMax : Dossier max
  * @param aCmdOrdre : Commande de l'ordre
  * @param aGroupe : Group de responsable
  * @param aFamilyProductCode : Code famille de produit
  * @param aProduct : Produit
  * @param aCmdNeed : Commande besoin inital.
  */
  procedure SelectBatchToLaunch(
    aStartDateMin      date
  , aStartDateMax      date
  , aEndDateMin        date
  , aEndDateMax        date
  , aProgMin           FAL_JOB_PROGRAM.JOP_REFERENCE%type
  , aProgMax           FAL_JOB_PROGRAM.JOP_REFERENCE%type
  , aOrdMin            FAL_ORDER.ORD_REF%type
  , aOrdMax            FAL_ORDER.ORD_REF%type
  , aCmdProg           DOC_DOCUMENT.DMT_NUMBER%type
  , aPrioriteMin       FAL_LOT.C_PRIORITY%type
  , aPrioriteMax       FAL_LOT.C_PRIORITY%type
  , aFamily            FAL_LOT.DIC_FAMILY_ID%type
  , aDocRecordMin      DOC_RECORD.RCO_TITLE%type
  , aDocRecordMax      DOC_RECORD.RCO_TITLE%type
  , aCmdOrdre          DOC_DOCUMENT.DMT_NUMBER%type
  , aGroupe            GCO_GOOD.DIC_ACCOUNTABLE_GROUP_ID%type
  , aFamilyProductCode GCO_GOOD.DIC_GOOD_FAMILY_ID%type
  , aProduct           GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , aCmdNeed           DOC_DOCUMENT.DMT_NUMBER%type
  )
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_LOT_ID';

    -- Sélection des ID de gammes à traiter
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct LOT.FAL_LOT_ID
                    , 'FAL_LOT_ID'
                 from FAL_LOT LOT
                where LOT.C_LOT_STATUS = '1'
                  and nvl(LOT.C_FAB_TYPE, '0') <> '4'
                  and (   aStartDateMin is null
                       or trunc(LOT.LOT_PLAN_BEGIN_DTE) >= trunc(aStartDateMin) )
                  and (   aStartDateMax is null
                       or trunc(LOT.LOT_PLAN_BEGIN_DTE) <= trunc(aStartDateMax) )
                  and (   aEndDateMin is null
                       or trunc(LOT.LOT_PLAN_END_DTE) >= trunc(aEndDateMin) )
                  and (   aEndDateMax is null
                       or trunc(LOT.LOT_PLAN_END_DTE) <= trunc(aEndDateMax) )
                  and (   aPrioriteMin is null
                       or LOT.C_PRIORITY >= aPrioriteMin)
                  and (   aPrioriteMax is null
                       or LOT.C_PRIORITY <= aPrioriteMax)
                  and (   aFamily is null
                       or LOT.DIC_FAMILY_ID = aFamily)
                  and (   aProduct is null
                       or LOT.GCO_GOOD_ID = (select GCO_GOOD_ID
                                               from GCO_GOOD
                                              where GOO_MAJOR_REFERENCE = aProduct) )
                  and (   aProgMin is null
                       or LOT.FAL_JOB_PROGRAM_ID = any (select FAL_JOB_PROGRAM_ID
                                                          from FAL_JOB_PROGRAM
                                                         where JOP_REFERENCE >= aProgMin) )
                  and (   aProgMax is null
                       or LOT.FAL_JOB_PROGRAM_ID = any (select FAL_JOB_PROGRAM_ID
                                                          from FAL_JOB_PROGRAM
                                                         where JOP_REFERENCE <= aProgMax) )
                  and (   aCmdProg is null
                       or LOT.FAL_JOB_PROGRAM_ID = any (select FAL_JOB_PROGRAM_ID
                                                          from FAL_JOB_PROGRAM
                                                         where DOC_DOCUMENT_ID = (select DOC_DOCUMENT_ID
                                                                                    from DOC_DOCUMENT
                                                                                   where DMT_NUMBER = aCmdProg) ) )
                  and (   aDocRecordMin is null
                       or LOT.DOC_RECORD_ID = any (select DOC_RECORD_ID
                                                     from DOC_RECORD
                                                    where RCO_TITLE >= aDocRecordMin) )
                  and (   aDocRecordMax is null
                       or LOT.DOC_RECORD_ID = any (select DOC_RECORD_ID
                                                     from DOC_RECORD
                                                    where RCO_TITLE <= aDocRecordMax) )
                  and (   aCmdOrdre is null
                       or LOT.FAL_ORDER_ID = any (select FAL_ORDER_ID
                                                    from FAL_ORDER
                                                   where DOC_DOCUMENT_ID = (select DOC_DOCUMENT_ID
                                                                              from DOC_DOCUMENT
                                                                             where DMT_NUMBER = aCmdOrdre) ) )
                  and (   aGroupe is null
                       or LOT.GCO_GOOD_ID = any (select GCO_GOOD_ID
                                                   from GCO_GOOD
                                                  where DIC_ACCOUNTABLE_GROUP_ID = aGroupe) )
                  and (   aFamilyProductCode is null
                       or LOT.GCO_GOOD_ID = any (select GCO_GOOD_ID
                                                   from GCO_GOOD
                                                  where DIC_GOOD_FAMILY_ID = aFamilyProductCode) )
                  and (   aOrdMin is null
                       or LOT.FAL_ORDER_ID = any (select FAL_ORDER_ID
                                                    from FAL_ORDER
                                                   where ORD_REF >= aOrdMin) )
                  and (   aOrdMax is null
                       or FAL_ORDER_ID = any (select FAL_ORDER_ID
                                                from FAL_ORDER
                                               where ORD_REF <= aOrdMax) )
                  and (   aCmdNeed is null
                       or FAL_TOOLS.CheckLotFromInitNeed(LOT.FAL_LOT_ID, aCmdNeed) = 1);
  end SelectBatchToLaunch;

  /**
  * Procedure BatchLaunchOptimization
  * Description
  *   Procédure d'optimisation du lancement des OF sélectionnés dans FAL_LOT1
  * @author ECA
  * @lastUpdate
  * @public
  * @param   aErrorMsg : Message d'erreur éventuel
  * @param   aSessionId : Session Oracle
  * @param   aUseCDischargeCom : Selon code décharge
  * @param   aUseOfRemainNeedQty : Prise en compte des Qté besoins libre sur OF lancés
  * @param   aCOptimizationMethod : Méthode d'optimisation
  * @param   aIndividualProc : Procédure individualisée d'optimisation
  * @param   aOnlyUserSelectedBatches : Ne prendre en compte que les FAL_LTO1 dont LT1_SELECT = 1
  */
  procedure BatchLaunchOptimization(
    aErrorMsg                in out varchar2
  , aSessionId               in     varchar2
  , aUseCDischargeCom        in     integer default 1
  , aUseOfRemainNeedQty      in     integer default 0
  , aCOptimizationMethod     in     varchar2 default '0'
  , aIndividualProc          in     varchar2 default ''
  , aOnlyUserSelectedBatches in     integer default 0
  )
  is
    aStrSQLIndivMethod varchar2(4000);
  begin
    aErrorMsg  := null;

    -- Pas d'optimisation
    if aCOptimizationMethod = omNone then
      return;
    -- Optimisation avec priorité au délai ou au volume
    elsif    aCOptimizationMethod = omVolumePriority
          or aCOptimizationMethod = omDelayPriority then
      -- Repérage des of pour lesquels il existe un composant dont la quantité disponible en stock est  = 0
      -- ou pour lesquels il existe des composants dont la quantité besoin est > à la quantité dispo en stock.
      -- Ces lots ne sont pas lancables quoiqu'il arrive.
      IdentifyUnLaunchableBatches(aUseCDischargeCom, aUseOfRemainNeedQty, aSessionId, aOnlyUserSelectedBatches);
      -- Chargement en mémoire des composants des lots de fabrication lancables
      -- et dont la quantité besoin totale est > à la quantité dispo en stock,
      -- , avec calcul du coefficient de consommation du disponible de chacun.
      Loadcomponents(aUseCDischargeCom, aUseOfRemainNeedQty, aSessionId, aOnlyUserSelectedBatches);
      -- Calcul du coefficient moyen de consommation par lot
      CalcBatchAvgConsumptionCoef(aSessionId, aOnlyUserSelectedBatches);
      -- Calcul du champ ordre de traitement
      CalcBatchOrderField(aCOptimizationMethod, aSessionId);
      -- Choix des lots lancables, parmis des restants
      CalcLaunchableBatches(aSessionId, aOnlyUserSelectedBatches);
    -- Optimisation avec Méthode individualisée
    elsif     aCOptimizationMethod = omIndividual
          and aIndividualProc is not null then
      aStrSQLIndivMethod  := ' BEGIN ' || aIndividualProc || '(:aSessionId); END; ';

      execute immediate aStrSQLIndivMethod
                  using aSessionId;
    end if;
  exception
    when others then
      aErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('Erreur durant l''exécution de la procédure d''optimisation !') || chr(10) || sqlerrm;
  end BatchLaunchOptimization;

  /**
  * procedure ClearOptimizationFields
  * Description : Remise à 0 des champs utilisés dans le cadre des calculs d'optimisation
  *               volume et délai du lancement
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   aSessionId   Session Oracle
  */
  procedure ClearOptimizationFields(aSessionId varchar2)
  is
  begin
    update FAL_LOT1
       set LT1_ORDER_FIELD = 0
         , LT1_LAUNCHABLE = 1
         , LT1_AVG_CONSUMPTION_COEFF = 0
     where LT1_ORACLE_SESSION = aSessionId;
  end ClearOptimizationFields;

  /**
  * function : pExecuteFct
  * Description : Exécution de la fonction de test passée en paramètre
  * @created CLE
  * @lastUpdate age 21.04.2015
  * @private
  * @param iFctName : Nom de la fonction à exécuter
  * @param iLotId   : Id de l'OF à tester
  * @return Message de retour de la fonction.
  */
  function pExecuteFct(iFctName varchar2, iLotId number)
    return varchar2
  is
    lvResult varchar2(4000);
  begin
    lvResult  := '';

    execute immediate 'begin  :ret := ' || iFctName || '(:iLotId); end;'
                using out lvResult, in iLotId;

    return lvResult;
  end pExecuteFct;

  /**
  * procedure ControlBeforeLaunch
  * Description : Procédure de controle avant le lancement des lots de fabrication.
  *               Contrôle le lot passé en paramètre, sinon ceux de la session,
  *               et renvoie un message, bloquant ou non.
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   iSessionId   Session Oracle
  * @param   iFalLotId   Lot de fabrication
  * @param   ioMessage   Message à l'attention du user
  * @param   ioAbortProcess   Permet de bloquer le processus
  */
  procedure ControlBeforeLaunch(
    iSessionId     in     FAL_LOT1.LT1_ORACLE_SESSION%type default null
  , iFalLotId      in     number default null
  , ioMessage      in out varchar2
  , ioAbortProcess in out integer
  )
  is
    cursor crBatchToLaunch
    is
      select LOT1.FAL_LOT_ID
           , PTC_FUNCTIONS.GetAccountingFixedCostprice(LOT1.GCO_GOOD_ID) PTC_FIXED_COSTPRICE_ID
           , LOT1.LT1_LOT_REFCOMPL
           , GOO.GOO_MAJOR_REFERENCE
        from FAL_LOT1 LOT1
           , GCO_GOOD GOO
       where LOT1.GCO_GOOD_ID = GOO.GCO_GOOD_ID
         and (   nvl(iFalLotId, 0) = LOT1.FAL_LOT_ID
              or (    LOT1.LT1_ORACLE_SESSION = nvl(iSessionId, ' ')
                  and LOT1.LT1_SELECT = 1) );


    lvControlMsg varchar2(4000);
    lvTotalCtrlMsg varchar2(32000);
  begin
    ioMessage       := '';
    ioAbortProcess  := 0;

    if    cUseAccounting
       or cProcBeforeLaunch is not null then
      for tplBatchToLaunch in crBatchToLaunch loop
        -- Contrôle la présence du Prix de revient Fixe "Compta indus", actif, par défaut, si le contexte le demande.
        if     cUseAccounting
           and tplBatchToLaunch.PTC_FIXED_COSTPRICE_ID is null then
          if ioMessage is null then
            ioMessage  :=
              PCS.PC_FUNCTIONS.TranslateWord
                ('Certains produits fabriqués ne possèdent pas de prix de revient fixe actifs, par défaut, pour comptabilité industrielle, ils ne peuvent être lancés'
                ) ||
              ' : ' ||
              chr(13) ||
              '   .' ||
              PCS.PC_FUNCTIONS.TranslateWord('(lot/produit)') ||
              chr(13) ||
              '   .' ||
              tplBatchToLaunch.LT1_LOT_REFCOMPL ||
              '/' ||
              tplBatchToLaunch.GOO_MAJOR_REFERENCE;
          else
            ioMessage  := ioMessage || chr(13) || '   .' || tplBatchToLaunch.LT1_LOT_REFCOMPL || '/' || tplBatchToLaunch.GOO_MAJOR_REFERENCE;
          end if;

          -- Si un seul lot est concerné, le processus d'interface est stoppé
          if nvl(iFalLotId, 0) <> 0 then
            ioAbortProcess  := 1;
          end if;

          -- Si une série de lots sont concernés, on désélectionne pour lancement ceux concernés
          if nvl(iFalLotId, 0) = 0 then
            update FAL_LOT1
               set LT1_SELECT = 0
             where FAL_LOT_ID = tplBatchToLaunch.FAL_LOT_ID
               and LT1_SELECT = 1;
          end if;
        end if;

        -- Exécution d'une function indiv avant lancement
        if cProcBeforeLaunch is not null then
          lvControlMsg  := pExecuteFct(cProcBeforeLaunch, tplBatchToLaunch.FAL_LOT_ID);

          if lvControlMsg is not null then
            -- Si une série de lots est concernée, on désélectionne pour lancement ceux concernés
            if nvl(iFalLotId, 0) = 0 then
              update FAL_LOT1
                 set LT1_SELECT = 0
               where FAL_LOT_ID = tplBatchToLaunch.FAL_LOT_ID
                 and LT1_SELECT = 1;
            end if;

            -- Si un seul lot est concerné,et que le message contient [ABORT], le processus d'interface est stoppé
            if     (instr(lvControlMsg, '[ABORT]') <> 0)
               and (nvl(iFalLotId, 0) <> 0) then
              ioAbortProcess  := 1;
            end if;

            lvTotalCtrlMsg  := lvTotalCtrlMsg || chr(13) || replace(lvControlMsg, '[ABORT]', '');
          end if;
        end if;
      end loop;

      ioMessage  := ioMessage || lvTotalCtrlMsg;
    end if;
  end ControlBeforeLaunch;
end;
