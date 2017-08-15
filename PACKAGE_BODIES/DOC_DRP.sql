--------------------------------------------------------
--  DDL for Package Body DOC_DRP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_DRP" 
as
  /**
  *  procedure GenerateDRP
  *
  *  Description
  *    Lancement du processus de création des documents DRP (Distribution Ressource Planing)
  */
  procedure GenerateDRP(
    aGenDocsListID  out    varchar2
  , aDistUnitListID in     varchar2 default null
  , aSessionID      in     varchar2 default null
  , aFalDocPropID   in     number default null
  )
  is
    tmpFDP_ID FAL_DOC_PROP.FAL_DOC_PROP_ID%type;
  begin
    -- Liste des unités de distribution à traiter passée en param
    if aDistUnitListID is not null then
      -- Màj de la sélection des DRA à traiter en fonction des unités de distribution
      update FAL_DOC_PROP
         set FDP_SELECT = 1
           , FDP_ORACLE_SESSION = DBMS_SESSION.UNIQUE_SESSION_ID
           , FDP_DRP_QUANTITY = least(nvl(FDP_DRP_QUANTITY, FDP_DRP_BALANCE_QUANTITY), FDP_DRP_BALANCE_QUANTITY)
       where C_PREFIX_PROP = 'DRA'
         and instr(',' || aDistUnitListID || ',', ',' || STM_DISTRIBUTION_UNIT_ID || ',') > 0
         and DOC_DRP.GetGoodDistGenMode(GCO_GOOD_ID, STM_DISTRIBUTION_UNIT_ID) = 1
         and (   nvl(FDP_ORACLE_SESSION, DBMS_SESSION.UNIQUE_SESSION_ID) = DBMS_SESSION.UNIQUE_SESSION_ID
              or COM_FUNCTIONS.IS_SESSION_ALIVE(nvl(FDP_ORACLE_SESSION, '0') ) = 0
             );

      commit;
      -- Traiter le niveau d'unité de distribution
      ProcessDRP(aGenDocsListID, DBMS_SESSION.UNIQUE_SESSION_ID, null);

      -- Remettre disponnible pour les autres utilisateurs les DRA qui n'ont pas été complétement distribuées
      update FAL_DOC_PROP
         set FDP_SELECT = 0
           , FDP_ORACLE_SESSION = null
           , FDP_DRP_QUANTITY = least(nvl(FDP_DRP_QUANTITY, FDP_DRP_BALANCE_QUANTITY), FDP_DRP_BALANCE_QUANTITY)
       where C_PREFIX_PROP = 'DRA'
         and FDP_ORACLE_SESSION = DBMS_SESSION.UNIQUE_SESSION_ID;

      commit;
    --
    -- ID de la session a traiter dans la table FAL_DOC_PROP
    elsif aSessionID is not null then
      ProcessDRP(aGenDocsListID, aSessionID, null);
    --
    -- ID d'une DRA passé en param
    elsif aFalDocPropID is not null then
      -- Vérifier si c'est bien un ID d'une DRA qui n'est pas utilisé par un autre utilisateur
      select max(FAL_DOC_PROP_ID)
        into tmpFDP_ID
        from FAL_DOC_PROP
       where FAL_DOC_PROP_ID = aFalDocPropID
         and C_PREFIX_PROP = 'DRA'
         and (   nvl(FDP_ORACLE_SESSION, DBMS_SESSION.UNIQUE_SESSION_ID) = DBMS_SESSION.UNIQUE_SESSION_ID
              or COM_FUNCTIONS.IS_SESSION_ALIVE(nvl(FDP_ORACLE_SESSION, '0') ) = 0
             );

      -- l'ID de la DRA est valide et on peut effectuer le traitement de distribution
      if tmpFDP_ID is not null then
        update FAL_DOC_PROP
           set FDP_SELECT = 1
             , FDP_ORACLE_SESSION = DBMS_SESSION.UNIQUE_SESSION_ID
             , FDP_DRP_QUANTITY = least(nvl(FDP_DRP_QUANTITY, FDP_DRP_BALANCE_QUANTITY), FDP_DRP_BALANCE_QUANTITY)
         where FAL_DOC_PROP_ID = aFalDocPropID
           and C_PREFIX_PROP = 'DRA';

        commit;
        ProcessDRP(aGenDocsListID, DBMS_SESSION.UNIQUE_SESSION_ID, aFalDocPropID);
      end if;
    end if;
  end GenerateDRP;

  function START_DRP(PrmDISTRIB_UNITS_LIST in varchar)
    return integer
  is
    tmpGenDocsListID varchar2(32000);
  begin
    FAL_DRP_FUNCTIONS.EvtsSupprDRA(null, null, null, null);
    FAL_DRP_FUNCTIONS.EvtsGenDRAStockMini;
    GenerateDRP(tmpGenDocsListID, PrmDISTRIB_UNITS_LIST);
    return 1;
  exception
    when others then
      return 0;
  end START_DRP;

  /**
  * procedure START_DRP
  * Description
  *     Création DRA
  * @author ECA
  * @created 13.11.2006
  * @lastUpdate
  * @public
  * @param PrmDISTRIB_UNITS_LIST   Comma seperated DIU List
  * @param aResult Integer                0 Failed, 1 Success
  */
  procedure START_DRP(PrmDISTRIB_UNITS_LIST in varchar, aResult in out integer)
  is
  begin
    aResult  := START_DRP(PrmDISTRIB_UNITS_LIST);
  exception
    when others then
      aResult  := 0;
  end;

  procedure ProcessDRP(aGenDocsListID out varchar2, aSessionID in varchar2, aFalDocPropID in number default null)
  is
    /*****
    * Liste des demandes de réappro.
    *
    * Qté totale demandée
    *   Si Qté économique gérée = Oui alors
    *     somme( trunc(Qté solde / Qté Eco , Nbr Decimal ) * Qté Eco)
    *   sinon
    *     somme(Qté solde)
    *
    * Qté totale demandée avec le taux de couverture
    *   Si Qté économique gérée = Oui alors
    *     trunc( (Qté solde * Taux couv / 100) / Qté Eco, Nbr Dec) * Qté Eco
    *   sinon
    *     trunc( Qté Solde * Taux couv / 100, Nbr Dec)
    *****/
    cursor crDRPListGrouped(cSessionID in varchar2, cFDP_ID in number)
    is
      select   FDP.GCO_GOOD_ID
             , FDP.STM_STM_DISTRIBUTION_UNIT_ID   -- Centre de réappro
             , FDP.STM_STOCK_ID   -- Stock du centre de réappro
             , avg(DOC_DRP.GetStockQuantity(FDP.GCO_GOOD_ID
                                          , FDP.STM_STOCK_ID
                                          , null
                                          , FDP.GCO_CHARACTERIZATION1_ID
                                          , FDP.GCO_CHARACTERIZATION2_ID
                                          , FDP.GCO_CHARACTERIZATION3_ID
                                          , FDP.GCO_CHARACTERIZATION4_ID
                                          , FDP.GCO_CHARACTERIZATION5_ID
                                          , FDP.FDP_CHARACTERIZATION_VALUE_1
                                          , FDP.FDP_CHARACTERIZATION_VALUE_2
                                          , FDP.FDP_CHARACTERIZATION_VALUE_3
                                          , FDP.FDP_CHARACTERIZATION_VALUE_4
                                          , FDP.FDP_CHARACTERIZATION_VALUE_5
                                           )
                  ) STOCK_AVAILABLE_QTY   -- Qté dispo en stock en US
             , sum(decode(DOC_DRP.GetGoodDistEconomicalQty(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
                        , 0, FDP.FDP_DRP_QUANTITY
                        , trunc(FDP.FDP_DRP_QUANTITY / DOC_DRP.GetGoodDistEconomicalQty(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
                              , DOC_DRP.GetGoodDistNbrDecimal(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
                               ) *
                          DOC_DRP.GetGoodDistEconomicalQty(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
                         )
                  ) FDP_TOTAL_QTY   -- Qté totale demandée en US
             , sum(decode(DOC_DRP.GetGoodDistEconomicalQty(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
                        , 0, trunc(FDP.FDP_DRP_QUANTITY *(DOC_DRP.GetGoodDistCoverPercent(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID) / 100)
                                 , DOC_DRP.GetGoodDistNbrDecimal(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
                                  )
                        , trunc(FDP.FDP_DRP_QUANTITY *
                                (DOC_DRP.GetGoodDistCoverPercent(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID) / 100) /
                                DOC_DRP.GetGoodDistEconomicalQty(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
                              , DOC_DRP.GetGoodDistNbrDecimal(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
                               ) *
                          DOC_DRP.GetGoodDistEconomicalQty(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
                         )
                  ) FDP_COVER_PERCENT_QTY   -- Qté totale demandée avec le taux de couverture
             , FDP.GCO_CHARACTERIZATION1_ID
             , FDP.GCO_CHARACTERIZATION2_ID
             , FDP.GCO_CHARACTERIZATION3_ID
             , FDP.GCO_CHARACTERIZATION4_ID
             , FDP.GCO_CHARACTERIZATION5_ID
             , FDP.FDP_CHARACTERIZATION_VALUE_1
             , FDP.FDP_CHARACTERIZATION_VALUE_2
             , FDP.FDP_CHARACTERIZATION_VALUE_3
             , FDP.FDP_CHARACTERIZATION_VALUE_4
             , FDP.FDP_CHARACTERIZATION_VALUE_5
          from FAL_DOC_PROP FDP
             , STM_DISTRIBUTION_UNIT DIU
         where FDP.C_PREFIX_PROP = 'DRA'
           and FDP.FDP_SELECT = 1
           and FDP.FDP_ORACLE_SESSION = cSessionID
           and FDP.FAL_DOC_PROP_ID = nvl(cFDP_ID, FDP.FAL_DOC_PROP_ID)
           and FDP.STM_STM_DISTRIBUTION_UNIT_ID = DIU.STM_DISTRIBUTION_UNIT_ID
      group by FDP.GCO_GOOD_ID
             , FDP.STM_STM_DISTRIBUTION_UNIT_ID
             , DIU.DIU_LEVEL
             , DIU.DIU_NAME
             , FDP.STM_STOCK_ID
             , FDP.GCO_CHARACTERIZATION1_ID
             , FDP.GCO_CHARACTERIZATION2_ID
             , FDP.GCO_CHARACTERIZATION3_ID
             , FDP.GCO_CHARACTERIZATION4_ID
             , FDP.GCO_CHARACTERIZATION5_ID
             , FDP.FDP_CHARACTERIZATION_VALUE_1
             , FDP.FDP_CHARACTERIZATION_VALUE_2
             , FDP.FDP_CHARACTERIZATION_VALUE_3
             , FDP.FDP_CHARACTERIZATION_VALUE_4
             , FDP.FDP_CHARACTERIZATION_VALUE_5
      order by DIU.DIU_LEVEL
             , DIU.DIU_NAME;

    tplDRPListGrouped    crDRPListGrouped%rowtype;

    -- Listes des DRP à traiter pour l'insertion dans la table DOC_TMP_DRP pour une distribution complète ou partielle
    cursor crDRPDetail(
      cSessionID        in varchar2
    , cFDP_ID           in number
    , cDistribType      in number
    , cGoodID           in number
    , cCharID_1         in number
    , cCharID_2         in number
    , cCharID_3         in number
    , cCharID_4         in number
    , cCharID_5         in number
    , cCharValue_1      in varchar2
    , cCharValue_2      in varchar2
    , cCharValue_3      in varchar2
    , cCharValue_4      in varchar2
    , cCharValue_5      in varchar2
    , cStmStmDistUnitID in number
    , cStockID          in number
    )
    is
      select   FDP.FAL_DOC_PROP_ID
             , FDP.DOC_GAUGE_ID
             , FDP.STM_STOCK_ID
             , FDP.STM_LOCATION_ID
             , FDP.STM_STM_STOCK_ID
             , FDP.STM_STM_LOCATION_ID
             , FDP.GCO_GOOD_ID
             , FDP.GCO_CHARACTERIZATION1_ID
             , FDP.GCO_CHARACTERIZATION2_ID
             , FDP.GCO_CHARACTERIZATION3_ID
             , FDP.GCO_CHARACTERIZATION4_ID
             , FDP.GCO_CHARACTERIZATION5_ID
             , FDP.FDP_CHARACTERIZATION_VALUE_1
             , FDP.FDP_CHARACTERIZATION_VALUE_2
             , FDP.FDP_CHARACTERIZATION_VALUE_3
             , FDP.FDP_CHARACTERIZATION_VALUE_4
             , FDP.FDP_CHARACTERIZATION_VALUE_5
             , decode(DOC_DRP.GetGoodDistEconomicalQty(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
                    , 0, decode(cDistribType
                              , 1, FDP.FDP_DRP_QUANTITY
                              , trunc(FDP.FDP_DRP_QUANTITY *(DOC_DRP.GetGoodDistCoverPercent(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID) / 100)
                                    , DOC_DRP.GetGoodDistNbrDecimal(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
                                     )
                               )
                    , decode(cDistribType
                           , 1, trunc(FDP.FDP_DRP_QUANTITY / DOC_DRP.GetGoodDistEconomicalQty(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
                                    , DOC_DRP.GetGoodDistNbrDecimal(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
                                     ) *
                              DOC_DRP.GetGoodDistEconomicalQty(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
                           , trunc(FDP.FDP_DRP_QUANTITY *
                                   (DOC_DRP.GetGoodDistCoverPercent(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID) / 100) /
                                   DOC_DRP.GetGoodDistEconomicalQty(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
                                 , DOC_DRP.GetGoodDistNbrDecimal(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
                                  ) *
                             DOC_DRP.GetGoodDistEconomicalQty(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
                            )
                     ) FDP_QUANTITY   -- Qté de la position à créer en US
             , DOC_DRP.GetGoodDistUnitMeasure(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID) DIC_UNIT_OF_MEASURE_ID
             , DOC_DRP.GetGoodDistConvertFactor(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID) DRP_CONVERSION_FACTOR
             , DOC_DRP.GetGoodDistNbrDecimal(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID) DRP_NUMBER_OF_DECIMAL
             , DOC_DRP.GetGoodDistReliquat(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID) C_DRP_RELIQUAT
          from FAL_DOC_PROP FDP
             , STM_DISTRIBUTION_UNIT DIU
         where FDP.C_PREFIX_PROP = 'DRA'
           and FDP.FDP_SELECT = 1
           and FDP.FDP_ORACLE_SESSION = cSessionID
           and FDP.FAL_DOC_PROP_ID = nvl(cFDP_ID, FDP.FAL_DOC_PROP_ID)
           and FDP.STM_STM_DISTRIBUTION_UNIT_ID = cStmStmDistUnitID
           and FDP.STM_DISTRIBUTION_UNIT_ID = DIU.STM_DISTRIBUTION_UNIT_ID
           and FDP.STM_STOCK_ID = cStockID
           and FDP.GCO_GOOD_ID = cGoodID
           and (   FDP.GCO_CHARACTERIZATION1_ID = cCharID_1
                or cCharID_1 is null)
           and (   FDP.GCO_CHARACTERIZATION2_ID = cCharID_2
                or cCharID_2 is null)
           and (   FDP.GCO_CHARACTERIZATION3_ID = cCharID_3
                or cCharID_3 is null)
           and (   FDP.GCO_CHARACTERIZATION4_ID = cCharID_4
                or cCharID_4 is null)
           and (   FDP.GCO_CHARACTERIZATION5_ID = cCharID_5
                or cCharID_5 is null)
           and (   FDP.FDP_CHARACTERIZATION_VALUE_1 = cCharValue_1
                or cCharValue_1 is null)
           and (   FDP.FDP_CHARACTERIZATION_VALUE_2 = cCharValue_2
                or cCharValue_2 is null)
           and (   FDP.FDP_CHARACTERIZATION_VALUE_3 = cCharValue_3
                or cCharValue_3 is null)
           and (   FDP.FDP_CHARACTERIZATION_VALUE_4 = cCharValue_4
                or cCharValue_4 is null)
           and (   FDP.FDP_CHARACTERIZATION_VALUE_5 = cCharValue_5
                or cCharValue_5 is null)
      order by DOC_DRP.GetGoodDistUnitPriority(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
             , DIU.DIU_NAME;

    tplDRPDetail         crDRPDetail%rowtype;

    -- Listes des DRP à traiter pour l'insertion dans la table DOC_TMP_DRP pour une distribution prioritaire
    cursor crDRPDetailPriority(
      cSessionID        in varchar2
    , cFDP_ID           in number
    , cGoodID           in number
    , cCharID_1         in number
    , cCharID_2         in number
    , cCharID_3         in number
    , cCharID_4         in number
    , cCharID_5         in number
    , cCharValue_1      in varchar2
    , cCharValue_2      in varchar2
    , cCharValue_3      in varchar2
    , cCharValue_4      in varchar2
    , cCharValue_5      in varchar2
    , cStmStmDistUnitID in number
    , cStockID          in number
    )
    is
      select   FDP.FAL_DOC_PROP_ID
             , FDP.DOC_GAUGE_ID
             , FDP.STM_STOCK_ID
             , FDP.STM_LOCATION_ID
             , FDP.STM_STM_STOCK_ID
             , FDP.STM_STM_LOCATION_ID
             , FDP.GCO_GOOD_ID
             , FDP.GCO_CHARACTERIZATION1_ID
             , FDP.GCO_CHARACTERIZATION2_ID
             , FDP.GCO_CHARACTERIZATION3_ID
             , FDP.GCO_CHARACTERIZATION4_ID
             , FDP.GCO_CHARACTERIZATION5_ID
             , FDP.FDP_CHARACTERIZATION_VALUE_1
             , FDP.FDP_CHARACTERIZATION_VALUE_2
             , FDP.FDP_CHARACTERIZATION_VALUE_3
             , FDP.FDP_CHARACTERIZATION_VALUE_4
             , FDP.FDP_CHARACTERIZATION_VALUE_5
             , decode(DOC_DRP.GetGoodDistEconomicalQty(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
                    , 0, FDP.FDP_DRP_QUANTITY
                    , trunc(FDP.FDP_DRP_QUANTITY / DOC_DRP.GetGoodDistEconomicalQty(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
                          , DOC_DRP.GetGoodDistNbrDecimal(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
                           ) *
                      DOC_DRP.GetGoodDistEconomicalQty(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
                     ) FDP_QUANTITY   -- Qté demandée
             , decode(DOC_DRP.GetGoodDistEconomicalQty(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
                    , 0, trunc(FDP.FDP_DRP_QUANTITY *(DOC_DRP.GetGoodDistCoverPercent(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID) / 100)
                             , DOC_DRP.GetGoodDistNbrDecimal(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
                              )
                    , trunc(FDP.FDP_DRP_QUANTITY *
                            (DOC_DRP.GetGoodDistCoverPercent(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID) / 100) /
                            DOC_DRP.GetGoodDistEconomicalQty(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
                          , DOC_DRP.GetGoodDistNbrDecimal(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
                           ) *
                      DOC_DRP.GetGoodDistEconomicalQty(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
                     ) FDP_COVER_PERCENT_QTY   -- Qté totale demandée avec le taux de couverture
             , DOC_DRP.GetGoodDistUseCoverPercent(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID) USE_COVER_PERCENT
             , DOC_DRP.GetGoodDistUnitMeasure(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID) DIC_UNIT_OF_MEASURE_ID
             , DOC_DRP.GetGoodDistConvertFactor(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID) DRP_CONVERSION_FACTOR
             , DOC_DRP.GetGoodDistNbrDecimal(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID) DRP_NUMBER_OF_DECIMAL
             , DOC_DRP.GetGoodDistReliquat(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID) C_DRP_RELIQUAT
             , DOC_DRP.GetGoodDistEconomicalQty(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID) DRP_ECONOMICAL_QTY
          from FAL_DOC_PROP FDP
             , STM_DISTRIBUTION_UNIT DIU
         where FDP.C_PREFIX_PROP = 'DRA'
           and FDP.FDP_SELECT = 1
           and FDP.FDP_ORACLE_SESSION = cSessionID
           and FDP.FAL_DOC_PROP_ID = nvl(cFDP_ID, FDP.FAL_DOC_PROP_ID)
           and FDP.STM_STM_DISTRIBUTION_UNIT_ID = cStmStmDistUnitID
           and FDP.STM_STOCK_ID = cStockID
           and FDP.GCO_GOOD_ID = cGoodID
           and FDP.STM_DISTRIBUTION_UNIT_ID = DIU.STM_DISTRIBUTION_UNIT_ID
           and (   FDP.GCO_CHARACTERIZATION1_ID = cCharID_1
                or cCharID_1 is null)
           and (   FDP.GCO_CHARACTERIZATION2_ID = cCharID_2
                or cCharID_2 is null)
           and (   FDP.GCO_CHARACTERIZATION3_ID = cCharID_3
                or cCharID_3 is null)
           and (   FDP.GCO_CHARACTERIZATION4_ID = cCharID_4
                or cCharID_4 is null)
           and (   FDP.GCO_CHARACTERIZATION5_ID = cCharID_5
                or cCharID_5 is null)
           and (   FDP.FDP_CHARACTERIZATION_VALUE_1 = cCharValue_1
                or cCharValue_1 is null)
           and (   FDP.FDP_CHARACTERIZATION_VALUE_2 = cCharValue_2
                or cCharValue_2 is null)
           and (   FDP.FDP_CHARACTERIZATION_VALUE_3 = cCharValue_3
                or cCharValue_3 is null)
           and (   FDP.FDP_CHARACTERIZATION_VALUE_4 = cCharValue_4
                or cCharValue_4 is null)
           and (   FDP.FDP_CHARACTERIZATION_VALUE_5 = cCharValue_5
                or cCharValue_5 is null)
      order by DOC_DRP.GetGoodDistUnitPriority(FDP.GCO_GOOD_ID, FDP.STM_DISTRIBUTION_UNIT_ID)
             , DIU.DIU_NAME;

    tplDRPDetailPriority crDRPDetailPriority%rowtype;
    nAvailableQtyUS      STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type;
    nDistribType         number(2);
    tmpPosQuantity       FAL_DOC_PROP.FDP_DRP_QUANTITY%type;
  begin
    -- Effacer les données existantes dans la table temp de la création de documents
    delete from DOC_TMP_DRP;

    -- Liste des biens par centre de réappro.
    open crDRPListGrouped(aSessionID, aFalDocPropID);

    fetch crDRPListGrouped
     into tplDRPListGrouped;

    if crDRPListGrouped%found then
      while crDRPListGrouped%found loop
        -- Pas de stock disponnible
        if tplDRPListGrouped.STOCK_AVAILABLE_QTY = 0 then
          nDistribType  := 0;   -- None
        -- La qté en stock est suffisante pour combler toutes les demandes de réappro.
        elsif tplDRPListGrouped.FDP_TOTAL_QTY <= tplDRPListGrouped.STOCK_AVAILABLE_QTY then
          nDistribType  := 1;   -- All
        -- La qté en stock est suffisante pour combler toutes les demandes de réappro. en tenant compte des taux de couverture
        elsif tplDRPListGrouped.FDP_COVER_PERCENT_QTY <= tplDRPListGrouped.STOCK_AVAILABLE_QTY then
          nDistribType  := 2;   -- Partiel
        else
          -- Pas assez de stock disponnible pour toutes les demandes de réappro. à traiter
          nDistribType     := 3;   -- Priority
          nAvailableQtyUS  := tplDRPListGrouped.STOCK_AVAILABLE_QTY;
        end if;

        -- Distribution complète ou partielle
        if    (nDistribType = 1)
           or (nDistribType = 2) then
          open crDRPDetail(aSessionID
                         , aFalDocPropID
                         , nDistribType
                         , tplDRPListGrouped.GCO_GOOD_ID
                         , tplDRPListGrouped.GCO_CHARACTERIZATION1_ID
                         , tplDRPListGrouped.GCO_CHARACTERIZATION2_ID
                         , tplDRPListGrouped.GCO_CHARACTERIZATION3_ID
                         , tplDRPListGrouped.GCO_CHARACTERIZATION4_ID
                         , tplDRPListGrouped.GCO_CHARACTERIZATION5_ID
                         , tplDRPListGrouped.FDP_CHARACTERIZATION_VALUE_1
                         , tplDRPListGrouped.FDP_CHARACTERIZATION_VALUE_2
                         , tplDRPListGrouped.FDP_CHARACTERIZATION_VALUE_3
                         , tplDRPListGrouped.FDP_CHARACTERIZATION_VALUE_4
                         , tplDRPListGrouped.FDP_CHARACTERIZATION_VALUE_5
                         , tplDRPListGrouped.STM_STM_DISTRIBUTION_UNIT_ID
                         , tplDRPListGrouped.STM_STOCK_ID
                          );

          fetch crDRPDetail
           into tplDRPDetail;

          while crDRPDetail%found loop
            if tplDRPDetail.FDP_QUANTITY > 0 then
              CreateTmpDrp(tplDRPDetail.FAL_DOC_PROP_ID
                         , tplDRPDetail.DOC_GAUGE_ID
                         , tplDRPDetail.GCO_GOOD_ID
                         , tplDRPDetail.STM_STOCK_ID
                         , tplDRPDetail.STM_STM_STOCK_ID
                         , tplDRPDetail.STM_STM_LOCATION_ID
                         , tplDRPDetail.C_DRP_RELIQUAT
                         , tplDRPDetail.DIC_UNIT_OF_MEASURE_ID
                         , tplDRPDetail.DRP_CONVERSION_FACTOR
                         , tplDRPDetail.DRP_NUMBER_OF_DECIMAL
                         , tplDRPDetail.GCO_CHARACTERIZATION1_ID
                         , tplDRPDetail.GCO_CHARACTERIZATION2_ID
                         , tplDRPDetail.GCO_CHARACTERIZATION3_ID
                         , tplDRPDetail.GCO_CHARACTERIZATION4_ID
                         , tplDRPDetail.GCO_CHARACTERIZATION5_ID
                         , tplDRPDetail.FDP_CHARACTERIZATION_VALUE_1
                         , tplDRPDetail.FDP_CHARACTERIZATION_VALUE_2
                         , tplDRPDetail.FDP_CHARACTERIZATION_VALUE_3
                         , tplDRPDetail.FDP_CHARACTERIZATION_VALUE_4
                         , tplDRPDetail.FDP_CHARACTERIZATION_VALUE_5
                         , tplDRPDetail.FDP_QUANTITY
                          );
            end if;

            fetch crDRPDetail
             into tplDRPDetail;
          end loop;

          close crDRPDetail;
        -- Distribution prioritaire
        elsif(nDistribType = 3) then
          open crDRPDetailPriority(aSessionID
                                 , aFalDocPropID
                                 , tplDRPListGrouped.GCO_GOOD_ID
                                 , tplDRPListGrouped.GCO_CHARACTERIZATION1_ID
                                 , tplDRPListGrouped.GCO_CHARACTERIZATION2_ID
                                 , tplDRPListGrouped.GCO_CHARACTERIZATION3_ID
                                 , tplDRPListGrouped.GCO_CHARACTERIZATION4_ID
                                 , tplDRPListGrouped.GCO_CHARACTERIZATION5_ID
                                 , tplDRPListGrouped.FDP_CHARACTERIZATION_VALUE_1
                                 , tplDRPListGrouped.FDP_CHARACTERIZATION_VALUE_2
                                 , tplDRPListGrouped.FDP_CHARACTERIZATION_VALUE_3
                                 , tplDRPListGrouped.FDP_CHARACTERIZATION_VALUE_4
                                 , tplDRPListGrouped.FDP_CHARACTERIZATION_VALUE_5
                                 , tplDRPListGrouped.STM_STM_DISTRIBUTION_UNIT_ID
                                 , tplDRPListGrouped.STM_STOCK_ID
                                  );

          fetch crDRPDetailPriority
           into tplDRPDetailPriority;

          while(crDRPDetailPriority%found)
           and (nAvailableQtyUS > 0) loop
            if tplDRPDetailPriority.USE_COVER_PERCENT = 1 then   -- Oui
              tmpPosQuantity  := least(nAvailableQtyUS, tplDRPDetailPriority.FDP_COVER_PERCENT_QTY);
            else
              tmpPosQuantity  := least(nAvailableQtyUS, tplDRPDetailPriority.FDP_QUANTITY);
            end if;

            -- Màj du compteur de la qté disponnible restante
            nAvailableQtyUS  := nAvailableQtyUS - tmpPosQuantity;

            -- Remplir la table temp DRP
            if tmpPosQuantity > 0 then
              CreateTmpDrp(tplDRPDetailPriority.FAL_DOC_PROP_ID
                         , tplDRPDetailPriority.DOC_GAUGE_ID
                         , tplDRPDetailPriority.GCO_GOOD_ID
                         , tplDRPDetailPriority.STM_STOCK_ID
                         , tplDRPDetailPriority.STM_STM_STOCK_ID
                         , tplDRPDetailPriority.STM_STM_LOCATION_ID
                         , tplDRPDetailPriority.C_DRP_RELIQUAT
                         , tplDRPDetailPriority.DIC_UNIT_OF_MEASURE_ID
                         , tplDRPDetailPriority.DRP_CONVERSION_FACTOR
                         , tplDRPDetailPriority.DRP_NUMBER_OF_DECIMAL
                         , tplDRPDetailPriority.GCO_CHARACTERIZATION1_ID
                         , tplDRPDetailPriority.GCO_CHARACTERIZATION2_ID
                         , tplDRPDetailPriority.GCO_CHARACTERIZATION3_ID
                         , tplDRPDetailPriority.GCO_CHARACTERIZATION4_ID
                         , tplDRPDetailPriority.GCO_CHARACTERIZATION5_ID
                         , tplDRPDetailPriority.FDP_CHARACTERIZATION_VALUE_1
                         , tplDRPDetailPriority.FDP_CHARACTERIZATION_VALUE_2
                         , tplDRPDetailPriority.FDP_CHARACTERIZATION_VALUE_3
                         , tplDRPDetailPriority.FDP_CHARACTERIZATION_VALUE_4
                         , tplDRPDetailPriority.FDP_CHARACTERIZATION_VALUE_5
                         , tmpPosQuantity
                          );
            end if;

            fetch crDRPDetailPriority
             into tplDRPDetailPriority;
          end loop;

          close crDRPDetailPriority;
        end if;

        -- Bien et centre de réappro suivant
        fetch crDRPListGrouped
         into tplDRPListGrouped;
      end loop;

      -- Création des documents selon les données de la table temp DRP (DOC_TMP_DRP)
      GenerateDRPDocuments(aGenDocsListID);
    end if;

    close crDRPListGrouped;
  -- Lister les demandes de réappro. à traiter pour le niveau passé en param
  end ProcessDRP;

  procedure CreateTmpDrp(
    aDocPropId        in number
  , aGaugeId          in number
  , aGoodID           in number
  , aStockId          in number
  , aDestStockId      in number
  , aDestLocationId   in number
  , aReliquat         in varchar2
  , aDicUnitMeasureId in varchar2
  , aConvertFactor    in number
  , aNbrDecimal       in number
  , aCharID_1         in number
  , aCharID_2         in number
  , aCharID_3         in number
  , aCharID_4         in number
  , aCharID_5         in number
  , aCharValue_1      in varchar2
  , aCharValue_2      in varchar2
  , aCharValue_3      in varchar2
  , aCharValue_4      in varchar2
  , aCharValue_5      in varchar2
  , aQuantity         in number
  )
  is
  begin
    -- Remplir la table temp DRP
    insert into DOC_TMP_DRP
                (DOC_TMP_DRP_ID
               , DRP_SESSION_ID
               , FAL_DOC_PROP_ID
               , DOC_GAUGE_ID
               , STM_STOCK_ID
               , STM_STM_STOCK_ID
               , STM_STM_LOCATION_ID
               , GCO_GOOD_ID
               , GCO_CHARACTERIZATION_1_ID
               , GCO_CHARACTERIZATION_2_ID
               , GCO_CHARACTERIZATION_3_ID
               , GCO_CHARACTERIZATION_4_ID
               , GCO_CHARACTERIZATION_5_ID
               , DRP_CHARACTERIZATION_VALUE_1
               , DRP_CHARACTERIZATION_VALUE_2
               , DRP_CHARACTERIZATION_VALUE_3
               , DRP_CHARACTERIZATION_VALUE_4
               , DRP_CHARACTERIZATION_VALUE_5
               , DRP_QUANTITY
               , C_DRP_RELIQUAT
               , DIC_UNIT_OF_MEASURE_ID
               , DRP_CONVERSION_FACTOR
               , DRP_NUMBER_OF_DECIMAL
               , A_DATECRE
               , A_IDCRE
                )
         values (INIT_ID_SEQ.nextval
               , DBMS_SESSION.UNIQUE_SESSION_ID
               , aDocPropId
               , aGaugeId
               , aStockId
               , aDestStockId
               , aDestLocationId
               , aGoodId
               , aCharID_1
               , aCharID_2
               , aCharID_3
               , aCharID_4
               , aCharID_5
               , aCharValue_1
               , aCharValue_2
               , aCharValue_3
               , aCharValue_4
               , aCharValue_5
               , aQuantity
               , aReliquat
               , aDicUnitMeasureId
               , aConvertFactor
               , aNbrDecimal
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end CreateTmpDrp;

  /**
  *  procedure GenerateDRPDocuments
  *
  *  Description
  *    Création des documents selon les données de la table temp DRP (DOC_TMP_DRP)
  */
  procedure GenerateDRPDocuments(aGenDocsListID out varchar2)
  is
    -- Positions de stock
    cursor crStockPosition(
      cGoodID     in number
    , cStockID    in number
    , cCharID1    in number
    , cCharID2    in number
    , cCharID3    in number
    , cCharID4    in number
    , cCharID5    in number
    , cCharValue1 in varchar2
    , cCharValue2 in varchar2
    , cCharValue3 in varchar2
    , cCharValue4 in varchar2
    , cCharValue5 in varchar2
    , cFifo       in number
    )
    is
      select   SPO.SPO_AVAILABLE_QUANTITY
             , SPO.STM_LOCATION_ID
             , SPO.GCO_CHARACTERIZATION_ID
             , SPO.GCO_GCO_CHARACTERIZATION_ID
             , SPO.GCO2_GCO_CHARACTERIZATION_ID
             , SPO.GCO3_GCO_CHARACTERIZATION_ID
             , SPO.GCO4_GCO_CHARACTERIZATION_ID
             , SPO.SPO_CHARACTERIZATION_VALUE_1
             , SPO.SPO_CHARACTERIZATION_VALUE_2
             , SPO.SPO_CHARACTERIZATION_VALUE_3
             , SPO.SPO_CHARACTERIZATION_VALUE_4
             , SPO.SPO_CHARACTERIZATION_VALUE_5
          from STM_STOCK_POSITION SPO
             , STM_LOCATION LOC
             , STM_ELEMENT_NUMBER SEM
         where SPO.GCO_GOOD_ID = cGoodID
           and SPO.STM_STOCK_ID = cStockID
           and SPO.STM_LOCATION_ID = LOC.STM_LOCATION_ID
           and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = SEM.STM_ELEMENT_NUMBER_ID(+)
           and SPO.SPO_AVAILABLE_QUANTITY > 0
           and (    (    SPO.GCO_CHARACTERIZATION_ID = cCharID1
                     and SPO.SPO_CHARACTERIZATION_VALUE_1 = cCharValue1)
                or (cCharID1 is null) )
           and (    (    SPO.GCO_GCO_CHARACTERIZATION_ID = cCharID2
                     and SPO.SPO_CHARACTERIZATION_VALUE_2 = cCharValue2)
                or (cCharID2 is null) )
           and (    (    SPO.GCO2_GCO_CHARACTERIZATION_ID = cCharID3
                     and SPO.SPO_CHARACTERIZATION_VALUE_3 = cCharValue3)
                or (cCharID3 is null) )
           and (    (    SPO.GCO3_GCO_CHARACTERIZATION_ID = cCharID4
                     and SPO.SPO_CHARACTERIZATION_VALUE_4 = cCharValue4)
                or (cCharID4 is null) )
           and (    (    SPO.GCO4_GCO_CHARACTERIZATION_ID = cCharID5
                     and SPO.SPO_CHARACTERIZATION_VALUE_5 = cCharValue5)
                or (cCharID5 is null) )
           and STM_I_LIB_MOVEMENT.VerifyForecastStockPosCond(iGoodId            => SPO.GCO_GOOD_ID
                                                           , iPiece             => SPO.SPO_PIECE
                                                           , iSet               => SPO.SPO_SET
                                                           , iVersion           => SPO.SPO_VERSION
                                                           , iChronological     => SPO.SPO_CHRONOLOGICAL
                                                           , iQualityStatusId   => SEM.GCO_QUALITY_STATUS_ID
                                                            ) is not null
      order by LOC.LOC_CLASSIFICATION
             , decode(cFifo, 1, SPO.SPO_CHRONOLOGICAL) asc
             , decode(cFifo, 2, SPO.SPO_CHRONOLOGICAL) desc
             , decode(cFifo, 3, SPO.SPO_CHRONOLOGICAL) asc
             , SPO.SPO_PIECE
             , SPO.SPO_SET
             , SPO.SPO_VERSION;

    tplStockPosition          crStockPosition%rowtype;

    type TTmpDrp is ref cursor;   -- define weak REF CURSOR type

    crTmpDrp                  TTmpDrp;
    SqlCmd                    varchar2(32000);
    NewDocumentID             DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    NewPositionID             DOC_POSITION.DOC_POSITION_ID%type;
    NewDetailID               DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    tmpDOC_TMP_DRP_ID         DOC_TMP_DRP.DOC_TMP_DRP_ID%type;
    tmpFAL_DOC_PROP_ID        DOC_TMP_DRP.FAL_DOC_PROP_ID%type;
    tmpCURRENT_DOC_GAUGE_ID   DOC_TMP_DRP.DOC_GAUGE_ID%type;
    tmpPREVIOUS_DOC_GAUGE_ID  DOC_TMP_DRP.DOC_GAUGE_ID%type;
    tmpDRP_QUANTITY           DOC_TMP_DRP.DRP_QUANTITY%type;
    tmpSTM_STOCK_ID           DOC_TMP_DRP.STM_STOCK_ID%type;
    tmpSTM_STM_STOCK_ID       DOC_TMP_DRP.STM_STM_STOCK_ID%type;
    tmpSTM_LOCATION_ID        DOC_TMP_DRP.STM_LOCATION_ID%type;
    tmpSTM_STM_LOCATION_ID    DOC_TMP_DRP.STM_STM_LOCATION_ID%type;
    tmpGCO_GOOD_ID            DOC_TMP_DRP.GCO_GOOD_ID%type;
    tmpC_DRP_RELIQUAT         DOC_TMP_DRP.C_DRP_RELIQUAT%type;
    tmpDIC_UNIT_OF_MEASURE_ID DOC_TMP_DRP.DIC_UNIT_OF_MEASURE_ID%type;
    tmpDRP_CONVERSION_FACTOR  DOC_TMP_DRP.DRP_CONVERSION_FACTOR%type;
    tmpDRP_NUMBER_OF_DECIMAL  DOC_TMP_DRP.DRP_NUMBER_OF_DECIMAL%type;
    tmpDRP_CHAR_ID_1          DOC_TMP_DRP.GCO_CHARACTERIZATION_1_ID%type;
    tmpDRP_CHAR_ID_2          DOC_TMP_DRP.GCO_CHARACTERIZATION_2_ID%type;
    tmpDRP_CHAR_ID_3          DOC_TMP_DRP.GCO_CHARACTERIZATION_3_ID%type;
    tmpDRP_CHAR_ID_4          DOC_TMP_DRP.GCO_CHARACTERIZATION_4_ID%type;
    tmpDRP_CHAR_ID_5          DOC_TMP_DRP.GCO_CHARACTERIZATION_5_ID%type;
    tmpDRP_CHAR_VALUE_1       DOC_TMP_DRP.DRP_CHARACTERIZATION_VALUE_1%type;
    tmpDRP_CHAR_VALUE_2       DOC_TMP_DRP.DRP_CHARACTERIZATION_VALUE_2%type;
    tmpDRP_CHAR_VALUE_3       DOC_TMP_DRP.DRP_CHARACTERIZATION_VALUE_3%type;
    tmpDRP_CHAR_VALUE_4       DOC_TMP_DRP.DRP_CHARACTERIZATION_VALUE_4%type;
    tmpDRP_CHAR_VALUE_5       DOC_TMP_DRP.DRP_CHARACTERIZATION_VALUE_5%type;
    tmpCURRENT_REGROUP        varchar2(4000);
    tmpPREVIOUS_REGROUP       varchar2(4000);
    tmpPOS_BASIS_QUANTITY     DOC_POSITION.POS_BASIS_QUANTITY%type;
    tmpPDE_BASIS_QUANTITY     DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY%type;
    tmpErrorMsg               varchar2(4000);
    tmpTotalDetailQty         DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY%type;
    tmpGoodFifo               number(1);
  begin
    NewDocumentID  := null;
    -- Rechercher la cmd sql externe pour le regroupement et ordre de création des documents
    SqlCmd         := PCS.PC_FUNCTIONS.GetSql('DOC_TMP_DRP', 'GENERATE_DRP', 'DRP_LIST');

    if SqlCmd is not null then
      -- Remplacer le param SESSION_ID par la valeur passée en param
      SqlCmd  := replace(SqlCmd, ':DRP_SESSION_ID', '''' || DBMS_SESSION.UNIQUE_SESSION_ID || '''');

      -- Balayer la table DOC_TMP_DRP selon la cmd sql externe et créer les documents/positions
      open crTmpDrp for SqlCmd;

      loop
        -- reprendre les données de regroupement et de tri de la cmd sql utilisateur de l'affichage des propositions
        fetch crTmpDrp
         into tmpCURRENT_DOC_GAUGE_ID
            , tmpCURRENT_REGROUP
            , tmpGCO_GOOD_ID
            , tmpDOC_TMP_DRP_ID
            , tmpFAL_DOC_PROP_ID
            , tmpDRP_QUANTITY
            , tmpSTM_STOCK_ID
            , tmpSTM_STM_STOCK_ID
            , tmpSTM_LOCATION_ID
            , tmpSTM_STM_LOCATION_ID
            , tmpC_DRP_RELIQUAT
            , tmpDIC_UNIT_OF_MEASURE_ID
            , tmpDRP_CONVERSION_FACTOR
            , tmpDRP_NUMBER_OF_DECIMAL
            , tmpDRP_CHAR_ID_1
            , tmpDRP_CHAR_ID_2
            , tmpDRP_CHAR_ID_3
            , tmpDRP_CHAR_ID_4
            , tmpDRP_CHAR_ID_5
            , tmpDRP_CHAR_VALUE_1
            , tmpDRP_CHAR_VALUE_2
            , tmpDRP_CHAR_VALUE_3
            , tmpDRP_CHAR_VALUE_4
            , tmpDRP_CHAR_VALUE_5;

        exit when crTmpDrp%notfound;

        begin
          -- Vérifier si on doit créer un nouveau document s'il y a un changement de type de gabarit ou
          -- bien s'il y a un changement dans le champs de regroupement
          if    (nvl(tmpCURRENT_DOC_GAUGE_ID, 0) <> nvl(tmpPREVIOUS_DOC_GAUGE_ID, 0) )
             or (nvl(tmpCURRENT_REGROUP, 'null') <> nvl(tmpPREVIOUS_REGROUP, 'null') ) then
            -- Si un document a été créé auparavant il faut effecter les dernières màj à la suite de la création de ses positions
            if NewDocumentID is not null then
              begin
                DOC_FINALIZE.FinalizeDocument(NewDocumentID, 1, 1, 1);
                commit;
              exception
                when others then
                  tmpErrorMsg  := 'PCS - Erreur finalisation document' || co.cLineBreak || sqlerrm || co.cLineBreak || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

                  -- Màj du document logistique avec l'erreur obtenue lors de la finalisation du document et protèger le doc
                  update DOC_DOCUMENT
                     set DMT_ERROR_MESSAGE = tmpErrorMsg
                       , DMT_PROTECTED = 1
                   where DOC_DOCUMENT_ID = NewDocumentID;

                  commit;
              end;
            end if;

            -- Valeurs pour le test de changement de document (création d'un nouveau doc ou pas)
            tmpPREVIOUS_DOC_GAUGE_ID  := tmpCURRENT_DOC_GAUGE_ID;
            tmpPREVIOUS_REGROUP       := tmpCURRENT_REGROUP;
            NewDocumentID             := null;
            -- Création document
            DOC_DOCUMENT_GENERATE.GenerateDocument(aNewDocumentID   => NewDocumentID, aMode => '130'   -- Création document DRP
                                                 , aGaugeID         => tmpCURRENT_DOC_GAUGE_ID);

            -- Màj de la liste des documents créés
            if aGenDocsListID is null then
              aGenDocsListID  := to_char(NewDocumentID);
            else
              aGenDocsListID  := aGenDocsListID || ',' || to_char(NewDocumentID);
            end if;
          end if;

          -- Rechercher le type de chronologie(FIFO, LIFO ouPéremption) si le bien est géré avec une caractérisation de type chronologique
          select nvl(max(to_number(C_CHRONOLOGY_TYPE) ), 0) CHRONO_TYPE
            into tmpGoodFifo
            from GCO_CHARACTERIZATION
           where GCO_GOOD_ID = tmpGCO_GOOD_ID;

          -- Rechercher les positions de stock
          open crStockPosition(tmpGCO_GOOD_ID
                             , tmpSTM_STOCK_ID
                             , tmpDRP_CHAR_ID_1
                             , tmpDRP_CHAR_ID_2
                             , tmpDRP_CHAR_ID_3
                             , tmpDRP_CHAR_ID_4
                             , tmpDRP_CHAR_ID_5
                             , tmpDRP_CHAR_VALUE_1
                             , tmpDRP_CHAR_VALUE_2
                             , tmpDRP_CHAR_VALUE_3
                             , tmpDRP_CHAR_VALUE_4
                             , tmpDRP_CHAR_VALUE_5
                             , tmpGoodFifo
                              );

          fetch crStockPosition
           into tplStockPosition;

          if crStockPosition%found then
            NewPositionID                                                    := null;
            -- Init de l'unité de mesure et du facteur de conversion de la position par rapport aux données compl de distrib
            DOC_POSITION_GENERATE.ResetPositionInfo(DOC_POSITION_INITIALIZE.PositionInfo);
            DOC_POSITION_INITIALIZE.PositionInfo.CLEAR_POSITION_INFO         := 0;
            DOC_POSITION_INITIALIZE.PositionInfo.USE_DIC_UNIT_OF_MEASURE_ID  := 1;
            DOC_POSITION_INITIALIZE.PositionInfo.DIC_UNIT_OF_MEASURE_ID      := tmpDIC_UNIT_OF_MEASURE_ID;
            DOC_POSITION_INITIALIZE.PositionInfo.USE_POS_CONVERT_FACTOR      := 1;
            DOC_POSITION_INITIALIZE.PositionInfo.POS_CONVERT_FACTOR          := tmpDRP_CONVERSION_FACTOR;
            DOC_POSITION_INITIALIZE.PositionInfo.POS_CONVERT_FACTOR2         := tmpDRP_CONVERSION_FACTOR;
            -- Qté de la position
            tmpPOS_BASIS_QUANTITY                                            := trunc(tmpDRP_QUANTITY / tmpDRP_CONVERSION_FACTOR, tmpDRP_NUMBER_OF_DECIMAL);
            -- Création position
            DOC_POSITION_GENERATE.GeneratePosition(aPositionID           => NewPositionID
                                                 , aDocumentID           => NewDocumentID
                                                 , aPosCreateMode        => '130'   -- Création position DRP
                                                 , aTypePos              => '1'
                                                 , aGoodID               => tmpGCO_GOOD_ID
                                                 , aBasisQuantity        => tmpPOS_BASIS_QUANTITY
                                                 , aForceStockLocation   => 1
                                                 , aStockID              => tmpSTM_STOCK_ID
                                                 , aLocationID           => tplStockPosition.STM_LOCATION_ID
                                                 , aTraStockID           => tmpSTM_STM_STOCK_ID
                                                 , aTraLocationID        => tmpSTM_STM_LOCATION_ID
                                                 , aGenerateDetail       => 0
                                                  );
            tmpTotalDetailQty                                                := 0;

            -- Tant que l'on a du stock et que l'on pas créé tous les détails (somme des qtés des détails < qté position)
            while(crStockPosition%found)
             and (tmpTotalDetailQty < tmpPOS_BASIS_QUANTITY) loop
              NewDetailID            := null;
              -- Qté pour le détail
              tmpPDE_BASIS_QUANTITY  := least(tmpPOS_BASIS_QUANTITY - tmpTotalDetailQty, tplStockPosition.SPO_AVAILABLE_QUANTITY);
              -- Qté totale des détails créés
              tmpTotalDetailQty      := tmpTotalDetailQty + tmpPDE_BASIS_QUANTITY;
              -- Création du détail
              DOC_DETAIL_GENERATE.GenerateDetail(aDetailID         => NewDetailID
                                               , aPositionID       => NewPositionID
                                               , aPdeCreateMode    => '130'
                                               , aQuantity         => trunc(tmpPDE_BASIS_QUANTITY / tmpDRP_CONVERSION_FACTOR, tmpDRP_NUMBER_OF_DECIMAL)
                                               , aLocationID       => tplStockPosition.STM_LOCATION_ID
                                               , aTraLocationID    => tmpSTM_STM_LOCATION_ID
                                               , aCharactValue_1   => tplStockPosition.SPO_CHARACTERIZATION_VALUE_1
                                               , aCharactValue_2   => tplStockPosition.SPO_CHARACTERIZATION_VALUE_2
                                               , aCharactValue_3   => tplStockPosition.SPO_CHARACTERIZATION_VALUE_3
                                               , aCharactValue_4   => tplStockPosition.SPO_CHARACTERIZATION_VALUE_4
                                               , aCharactValue_5   => tplStockPosition.SPO_CHARACTERIZATION_VALUE_5
                                                );

              fetch crStockPosition
               into tplStockPosition;
            end loop;

            -- Màj de la DRA
            FAL_DRP_FUNCTIONS.EVTSMajDRA(tmpFAL_DOC_PROP_ID, 'DELIVERY', tmpDRP_QUANTITY, tmpC_DRP_RELIQUAT, NewDocumentID);
          end if;

          close crStockPosition;
        exception
          when others then
            tmpPREVIOUS_DOC_GAUGE_ID  := null;
            tmpPREVIOUS_REGROUP       := null;
        end;
      end loop;

      -- Si un document a été créé auparavant il faut effecter les dernières màj à la suite de la création de ses positions
      if NewDocumentID is not null then
        begin
          DOC_FINALIZE.FinalizeDocument(NewDocumentID, 1, 1, 1);
          commit;
        exception
          when others then
            tmpErrorMsg  := 'PCS - Erreur finalisation document' || co.cLineBreak || sqlerrm || co.cLineBreak || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

            -- Màj du document logistique avec l'erreur obtenue lors de la finalisation du document et protèger le doc
            update DOC_DOCUMENT
               set DMT_ERROR_MESSAGE = tmpErrorMsg
                 , DMT_PROTECTED = 1
             where DOC_DOCUMENT_ID = NewDocumentID;

            commit;
        end;
      end if;
    end if;
  end GenerateDRPDocuments;

  function GetStockQuantity(
    good_id     in number
  , stock_id    in number
  , location_id in number
  , charac1_id  in number
  , charac2_id  in number
  , charac3_id  in number
  , charac4_id  in number
  , charac5_id  in number
  , char_val_1  in varchar2
  , char_val_2  in varchar2
  , char_val_3  in varchar2
  , char_val_4  in varchar2
  , char_val_5  in varchar2
  )
    return number
  is
    result                   STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type;

    cursor stk_char(
      char1_id  number
    , char2_id  number
    , char3_id  number
    , char4_id  number
    , char5_id  number
    , char1_val varchar2
    , char2_val varchar2
    , char3_val varchar2
    , char4_val varchar2
    , char5_val varchar2
    )
    is
      select   GCO_CHARACTERIZATION_ID
             , char1_val char_value
             , 1 ordre
          from GCO_CHARACTERIZATION CHA
             , GCO_PRODUCT PDT
         where GCO_CHARACTERIZATION_ID = char1_id
           and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID
           and CHA_STOCK_MANAGEMENT = 1
           and PDT_STOCK_MANAGEMENT = 1
      union
      select   GCO_CHARACTERIZATION_ID
             , char2_val char_value
             , 2 ordre
          from GCO_CHARACTERIZATION CHA
             , GCO_PRODUCT PDT
         where GCO_CHARACTERIZATION_ID = char2_id
           and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID
           and CHA_STOCK_MANAGEMENT = 1
           and PDT_STOCK_MANAGEMENT = 1
      union
      select   GCO_CHARACTERIZATION_ID
             , char3_val char_value
             , 3 ordre
          from GCO_CHARACTERIZATION CHA
             , GCO_PRODUCT PDT
         where GCO_CHARACTERIZATION_ID = char3_id
           and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID
           and CHA_STOCK_MANAGEMENT = 1
           and PDT_STOCK_MANAGEMENT = 1
      union
      select   GCO_CHARACTERIZATION_ID
             , char4_val char_value
             , 4 ordre
          from GCO_CHARACTERIZATION CHA
             , GCO_PRODUCT PDT
         where GCO_CHARACTERIZATION_ID = char4_id
           and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID
           and CHA_STOCK_MANAGEMENT = 1
           and PDT_STOCK_MANAGEMENT = 1
      union
      select   GCO_CHARACTERIZATION_ID
             , char5_val char_value
             , 5 ordre
          from GCO_CHARACTERIZATION CHA
             , GCO_PRODUCT PDT
         where GCO_CHARACTERIZATION_ID = char5_id
           and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID
           and CHA_STOCK_MANAGEMENT = 1
           and PDT_STOCK_MANAGEMENT = 1
      order by 3;

    ordre                    number(1);
    characterization_id_1    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    characterization_id_2    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    characterization_id_3    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    characterization_id_4    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    characterization_id_5    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    characterization_value_1 STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type;
    characterization_value_2 STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type;
    characterization_value_3 STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type;
    characterization_value_4 STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type;
    characterization_value_5 STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type;
  begin
    -- si on a des caractérisation, vérification qu'elles soient gêrées en stock
    -- pour leur prise en compte dans la recehrche de la quantité
    if (charac1_id is not null) then
      open stk_char(charac1_id, charac2_id, charac3_id, charac4_id, charac5_id, char_val_1, char_val_2, char_val_3, char_val_4, char_val_5);

      fetch stk_char
       into characterization_id_1
          , characterization_value_1
          , ordre;

      fetch stk_char
       into characterization_id_2
          , characterization_value_2
          , ordre;

      fetch stk_char
       into characterization_id_3
          , characterization_value_3
          , ordre;

      fetch stk_char
       into characterization_id_4
          , characterization_value_4
          , ordre;

      fetch stk_char
       into characterization_id_5
          , characterization_value_5
          , ordre;

      close stk_char;
    end if;

    select nvl(sum(SPO.SPO_AVAILABLE_QUANTITY), 0)
      into result
      from STM_STOCK_POSITION SPO
         , STM_ELEMENT_NUMBER SEM
     where SPO.GCO_GOOD_ID = good_id
       and SPO.SPO_AVAILABLE_QUANTITY > 0
       and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = SEM.STM_ELEMENT_NUMBER_ID(+)
       and (   SPO.STM_STOCK_ID = stock_id
            or stock_id is null)
       and (   SPO.STM_LOCATION_ID = location_id
            or location_id is null)
       and (    (    SPO.GCO_CHARACTERIZATION_ID = characterization_id_1
                 and SPO.SPO_CHARACTERIZATION_VALUE_1 = characterization_value_1)
            or (characterization_id_1 is null)
           )
       and (    (    SPO.GCO_GCO_CHARACTERIZATION_ID = characterization_id_2
                 and SPO.SPO_CHARACTERIZATION_VALUE_2 = characterization_value_2)
            or (characterization_id_2 is null)
           )
       and (    (    SPO.GCO2_GCO_CHARACTERIZATION_ID = characterization_id_3
                 and SPO.SPO_CHARACTERIZATION_VALUE_3 = characterization_value_3)
            or (characterization_id_3 is null)
           )
       and (    (    SPO.GCO3_GCO_CHARACTERIZATION_ID = characterization_id_4
                 and SPO.SPO_CHARACTERIZATION_VALUE_4 = characterization_value_4)
            or (characterization_id_4 is null)
           )
       and (    (    SPO.GCO4_GCO_CHARACTERIZATION_ID = characterization_id_5
                 and SPO.SPO_CHARACTERIZATION_VALUE_5 = characterization_value_5)
            or (characterization_id_5 is null)
           )
       and STM_I_LIB_MOVEMENT.VerifyForecastStockPosCond(iGoodId            => SPO.GCO_GOOD_ID
                                                       , iPiece             => SPO.SPO_PIECE
                                                       , iSet               => SPO.SPO_SET
                                                       , iVersion           => SPO.SPO_VERSION
                                                       , iChronological     => SPO.SPO_CHRONOLOGICAL
                                                       , iQualityStatusId   => SEM.GCO_QUALITY_STATUS_ID
                                                        ) is not null;

    return result;
  end GetStockQuantity;

  function GetGoodDistCoverPercent(aGoodID in number, aDistribUnitID in number)
    return number
  is
    tmpResult           number(1);
    tmpDicUnitOfMeasure GCO_COMPL_DATA_DISTRIB.DIC_UNIT_OF_MEASURE_ID%type;
    tmpConvertFactor    GCO_COMPL_DATA_DISTRIB.CDA_CONVERSION_FACTOR%type;
    tmpNumberOfDecimal  GCO_COMPL_DATA_DISTRIB.CDA_NUMBER_OF_DECIMAL%type;
    tmpStockMin         GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MIN%type;
    tmpStockMax         GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MAX%type;
    tmpEconQuantity     GCO_COMPL_DATA_DISTRIB.CDI_ECONOMICAL_QUANTITY%type;
    tmpCDDBlockedFrom   GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_FROM%type;
    tmpCDDBlockedTo     GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_TO%type;
    tmpCoverPerCent     GCO_COMPL_DATA_DISTRIB.CDI_COVER_PERCENT%type;
    tmpUseCoverPercent  GCO_COMPL_DATA_DISTRIB.C_DRP_USE_COVER_PERCENT%type;
    tmpPriority         GCO_COMPL_DATA_DISTRIB.CDI_PRIORITY_CODE%type;
    tmpQuantityRule     GCO_COMPL_DATA_DISTRIB.C_DRP_QTY_RULE%type;
    tmpDocMode          GCO_COMPL_DATA_DISTRIB.C_DRP_DOC_MODE%type;
    tmpReliquat         GCO_COMPL_DATA_DISTRIB.C_DRP_RELIQUAT%type;
  begin
    GCO_FUNCTIONS.GetComplDataDistrib(aGoodID
                                    , aDistribUnitID
                                    , null   -- aDicDistribComplData
                                    , tmpResult
                                    , tmpDicUnitOfMeasure
                                    , tmpConvertFactor
                                    , tmpNumberOfDecimal
                                    , tmpStockMin
                                    , tmpStockMax
                                    , tmpEconQuantity
                                    , tmpCDDBlockedFrom
                                    , tmpCDDBlockedTo
                                    , tmpCoverPerCent
                                    , tmpUseCoverPercent
                                    , tmpPriority
                                    , tmpQuantityRule
                                    , tmpDocMode
                                    , tmpReliquat
                                     );
    return nvl(tmpCoverPerCent, 100);
  end GetGoodDistCoverPercent;

  function GetGoodDistNbrDecimal(aGoodID in number, aDistribUnitID in number)
    return number
  is
    tmpResult           number(1);
    tmpDicUnitOfMeasure GCO_COMPL_DATA_DISTRIB.DIC_UNIT_OF_MEASURE_ID%type;
    tmpConvertFactor    GCO_COMPL_DATA_DISTRIB.CDA_CONVERSION_FACTOR%type;
    tmpNumberOfDecimal  GCO_COMPL_DATA_DISTRIB.CDA_NUMBER_OF_DECIMAL%type;
    tmpStockMin         GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MIN%type;
    tmpStockMax         GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MAX%type;
    tmpEconQuantity     GCO_COMPL_DATA_DISTRIB.CDI_ECONOMICAL_QUANTITY%type;
    tmpCDDBlockedFrom   GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_FROM%type;
    tmpCDDBlockedTo     GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_TO%type;
    tmpCoverPerCent     GCO_COMPL_DATA_DISTRIB.CDI_COVER_PERCENT%type;
    tmpUseCoverPercent  GCO_COMPL_DATA_DISTRIB.C_DRP_USE_COVER_PERCENT%type;
    tmpPriority         GCO_COMPL_DATA_DISTRIB.CDI_PRIORITY_CODE%type;
    tmpQuantityRule     GCO_COMPL_DATA_DISTRIB.C_DRP_QTY_RULE%type;
    tmpDocMode          GCO_COMPL_DATA_DISTRIB.C_DRP_DOC_MODE%type;
    tmpReliquat         GCO_COMPL_DATA_DISTRIB.C_DRP_RELIQUAT%type;
  begin
    GCO_FUNCTIONS.GetComplDataDistrib(aGoodID
                                    , aDistribUnitID
                                    , null   -- aDicDistribComplData
                                    , tmpResult
                                    , tmpDicUnitOfMeasure
                                    , tmpConvertFactor
                                    , tmpNumberOfDecimal
                                    , tmpStockMin
                                    , tmpStockMax
                                    , tmpEconQuantity
                                    , tmpCDDBlockedFrom
                                    , tmpCDDBlockedTo
                                    , tmpCoverPerCent
                                    , tmpUseCoverPercent
                                    , tmpPriority
                                    , tmpQuantityRule
                                    , tmpDocMode
                                    , tmpReliquat
                                     );
    return nvl(tmpNumberOfDecimal, 0);
  end GetGoodDistNbrDecimal;

  function GetGoodDistUseCoverPercent(aGoodID in number, aDistribUnitID in number)
    return number
  is
    tmpResult           number(1);
    tmpDicUnitOfMeasure GCO_COMPL_DATA_DISTRIB.DIC_UNIT_OF_MEASURE_ID%type;
    tmpConvertFactor    GCO_COMPL_DATA_DISTRIB.CDA_CONVERSION_FACTOR%type;
    tmpNumberOfDecimal  GCO_COMPL_DATA_DISTRIB.CDA_NUMBER_OF_DECIMAL%type;
    tmpStockMin         GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MIN%type;
    tmpStockMax         GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MAX%type;
    tmpEconQuantity     GCO_COMPL_DATA_DISTRIB.CDI_ECONOMICAL_QUANTITY%type;
    tmpCDDBlockedFrom   GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_FROM%type;
    tmpCDDBlockedTo     GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_TO%type;
    tmpCoverPerCent     GCO_COMPL_DATA_DISTRIB.CDI_COVER_PERCENT%type;
    tmpUseCoverPercent  GCO_COMPL_DATA_DISTRIB.C_DRP_USE_COVER_PERCENT%type;
    tmpPriority         GCO_COMPL_DATA_DISTRIB.CDI_PRIORITY_CODE%type;
    tmpQuantityRule     GCO_COMPL_DATA_DISTRIB.C_DRP_QTY_RULE%type;
    tmpDocMode          GCO_COMPL_DATA_DISTRIB.C_DRP_DOC_MODE%type;
    tmpReliquat         GCO_COMPL_DATA_DISTRIB.C_DRP_RELIQUAT%type;
  begin
    GCO_FUNCTIONS.GetComplDataDistrib(aGoodID
                                    , aDistribUnitID
                                    , null   -- aDicDistribComplData
                                    , tmpResult
                                    , tmpDicUnitOfMeasure
                                    , tmpConvertFactor
                                    , tmpNumberOfDecimal
                                    , tmpStockMin
                                    , tmpStockMax
                                    , tmpEconQuantity
                                    , tmpCDDBlockedFrom
                                    , tmpCDDBlockedTo
                                    , tmpCoverPerCent
                                    , tmpUseCoverPercent
                                    , tmpPriority
                                    , tmpQuantityRule
                                    , tmpDocMode
                                    , tmpReliquat
                                     );
    -- UseCoverPercent -> 1 = Oui  et 2 = Non
    return nvl(to_number(tmpUseCoverPercent), 1);
  end GetGoodDistUseCoverPercent;

  function GetGoodDistUnitPriority(aGoodID in number, aDistribUnitID in number)
    return number
  is
    tmpResult           number(1);
    tmpDicUnitOfMeasure GCO_COMPL_DATA_DISTRIB.DIC_UNIT_OF_MEASURE_ID%type;
    tmpConvertFactor    GCO_COMPL_DATA_DISTRIB.CDA_CONVERSION_FACTOR%type;
    tmpNumberOfDecimal  GCO_COMPL_DATA_DISTRIB.CDA_NUMBER_OF_DECIMAL%type;
    tmpStockMin         GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MIN%type;
    tmpStockMax         GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MAX%type;
    tmpEconQuantity     GCO_COMPL_DATA_DISTRIB.CDI_ECONOMICAL_QUANTITY%type;
    tmpCDDBlockedFrom   GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_FROM%type;
    tmpCDDBlockedTo     GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_TO%type;
    tmpCoverPerCent     GCO_COMPL_DATA_DISTRIB.CDI_COVER_PERCENT%type;
    tmpUseCoverPercent  GCO_COMPL_DATA_DISTRIB.C_DRP_USE_COVER_PERCENT%type;
    tmpPriority         GCO_COMPL_DATA_DISTRIB.CDI_PRIORITY_CODE%type;
    tmpQuantityRule     GCO_COMPL_DATA_DISTRIB.C_DRP_QTY_RULE%type;
    tmpDocMode          GCO_COMPL_DATA_DISTRIB.C_DRP_DOC_MODE%type;
    tmpReliquat         GCO_COMPL_DATA_DISTRIB.C_DRP_RELIQUAT%type;
  begin
    GCO_FUNCTIONS.GetComplDataDistrib(aGoodID
                                    , aDistribUnitID
                                    , null   -- aDicDistribComplData
                                    , tmpResult
                                    , tmpDicUnitOfMeasure
                                    , tmpConvertFactor
                                    , tmpNumberOfDecimal
                                    , tmpStockMin
                                    , tmpStockMax
                                    , tmpEconQuantity
                                    , tmpCDDBlockedFrom
                                    , tmpCDDBlockedTo
                                    , tmpCoverPerCent
                                    , tmpUseCoverPercent
                                    , tmpPriority
                                    , tmpQuantityRule
                                    , tmpDocMode
                                    , tmpReliquat
                                     );
    return nvl(tmpPriority, 0);
  end GetGoodDistUnitPriority;

  function GetGoodDistGenMode(aGoodID in number, aDistribUnitID in number)
    return number
  is
    tmpResult           number(1);
    tmpDicUnitOfMeasure GCO_COMPL_DATA_DISTRIB.DIC_UNIT_OF_MEASURE_ID%type;
    tmpConvertFactor    GCO_COMPL_DATA_DISTRIB.CDA_CONVERSION_FACTOR%type;
    tmpNumberOfDecimal  GCO_COMPL_DATA_DISTRIB.CDA_NUMBER_OF_DECIMAL%type;
    tmpStockMin         GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MIN%type;
    tmpStockMax         GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MAX%type;
    tmpEconQuantity     GCO_COMPL_DATA_DISTRIB.CDI_ECONOMICAL_QUANTITY%type;
    tmpCDDBlockedFrom   GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_FROM%type;
    tmpCDDBlockedTo     GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_TO%type;
    tmpCoverPerCent     GCO_COMPL_DATA_DISTRIB.CDI_COVER_PERCENT%type;
    tmpUseCoverPercent  GCO_COMPL_DATA_DISTRIB.C_DRP_USE_COVER_PERCENT%type;
    tmpPriority         GCO_COMPL_DATA_DISTRIB.CDI_PRIORITY_CODE%type;
    tmpQuantityRule     GCO_COMPL_DATA_DISTRIB.C_DRP_QTY_RULE%type;
    tmpDocMode          GCO_COMPL_DATA_DISTRIB.C_DRP_DOC_MODE%type;
    tmpReliquat         GCO_COMPL_DATA_DISTRIB.C_DRP_RELIQUAT%type;
  begin
    GCO_FUNCTIONS.GetComplDataDistrib(aGoodID
                                    , aDistribUnitID
                                    , null   -- aDicDistribComplData
                                    , tmpResult
                                    , tmpDicUnitOfMeasure
                                    , tmpConvertFactor
                                    , tmpNumberOfDecimal
                                    , tmpStockMin
                                    , tmpStockMax
                                    , tmpEconQuantity
                                    , tmpCDDBlockedFrom
                                    , tmpCDDBlockedTo
                                    , tmpCoverPerCent
                                    , tmpUseCoverPercent
                                    , tmpPriority
                                    , tmpQuantityRule
                                    , tmpDocMode
                                    , tmpReliquat
                                     );
    return nvl(to_number(tmpDocMode), 0);
  end GetGoodDistGenMode;

  function GetGoodDistReliquat(aGoodID in number, aDistribUnitID in number)
    return varchar2
  is
    tmpResult           number(1);
    tmpDicUnitOfMeasure GCO_COMPL_DATA_DISTRIB.DIC_UNIT_OF_MEASURE_ID%type;
    tmpConvertFactor    GCO_COMPL_DATA_DISTRIB.CDA_CONVERSION_FACTOR%type;
    tmpNumberOfDecimal  GCO_COMPL_DATA_DISTRIB.CDA_NUMBER_OF_DECIMAL%type;
    tmpStockMin         GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MIN%type;
    tmpStockMax         GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MAX%type;
    tmpEconQuantity     GCO_COMPL_DATA_DISTRIB.CDI_ECONOMICAL_QUANTITY%type;
    tmpCDDBlockedFrom   GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_FROM%type;
    tmpCDDBlockedTo     GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_TO%type;
    tmpCoverPerCent     GCO_COMPL_DATA_DISTRIB.CDI_COVER_PERCENT%type;
    tmpUseCoverPercent  GCO_COMPL_DATA_DISTRIB.C_DRP_USE_COVER_PERCENT%type;
    tmpPriority         GCO_COMPL_DATA_DISTRIB.CDI_PRIORITY_CODE%type;
    tmpQuantityRule     GCO_COMPL_DATA_DISTRIB.C_DRP_QTY_RULE%type;
    tmpDocMode          GCO_COMPL_DATA_DISTRIB.C_DRP_DOC_MODE%type;
    tmpReliquat         GCO_COMPL_DATA_DISTRIB.C_DRP_RELIQUAT%type;
  begin
    GCO_FUNCTIONS.GetComplDataDistrib(aGoodID
                                    , aDistribUnitID
                                    , null   -- aDicDistribComplData
                                    , tmpResult
                                    , tmpDicUnitOfMeasure
                                    , tmpConvertFactor
                                    , tmpNumberOfDecimal
                                    , tmpStockMin
                                    , tmpStockMax
                                    , tmpEconQuantity
                                    , tmpCDDBlockedFrom
                                    , tmpCDDBlockedTo
                                    , tmpCoverPerCent
                                    , tmpUseCoverPercent
                                    , tmpPriority
                                    , tmpQuantityRule
                                    , tmpDocMode
                                    , tmpReliquat
                                     );
    return tmpReliquat;
  end GetGoodDistReliquat;

  function GetGoodDistConvertFactor(aGoodID in number, aDistribUnitID in number)
    return number
  is
    tmpResult           number(1);
    tmpDicUnitOfMeasure GCO_COMPL_DATA_DISTRIB.DIC_UNIT_OF_MEASURE_ID%type;
    tmpConvertFactor    GCO_COMPL_DATA_DISTRIB.CDA_CONVERSION_FACTOR%type;
    tmpNumberOfDecimal  GCO_COMPL_DATA_DISTRIB.CDA_NUMBER_OF_DECIMAL%type;
    tmpStockMin         GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MIN%type;
    tmpStockMax         GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MAX%type;
    tmpEconQuantity     GCO_COMPL_DATA_DISTRIB.CDI_ECONOMICAL_QUANTITY%type;
    tmpCDDBlockedFrom   GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_FROM%type;
    tmpCDDBlockedTo     GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_TO%type;
    tmpCoverPerCent     GCO_COMPL_DATA_DISTRIB.CDI_COVER_PERCENT%type;
    tmpUseCoverPercent  GCO_COMPL_DATA_DISTRIB.C_DRP_USE_COVER_PERCENT%type;
    tmpPriority         GCO_COMPL_DATA_DISTRIB.CDI_PRIORITY_CODE%type;
    tmpQuantityRule     GCO_COMPL_DATA_DISTRIB.C_DRP_QTY_RULE%type;
    tmpDocMode          GCO_COMPL_DATA_DISTRIB.C_DRP_DOC_MODE%type;
    tmpReliquat         GCO_COMPL_DATA_DISTRIB.C_DRP_RELIQUAT%type;
  begin
    GCO_FUNCTIONS.GetComplDataDistrib(aGoodID
                                    , aDistribUnitID
                                    , null   -- aDicDistribComplData
                                    , tmpResult
                                    , tmpDicUnitOfMeasure
                                    , tmpConvertFactor
                                    , tmpNumberOfDecimal
                                    , tmpStockMin
                                    , tmpStockMax
                                    , tmpEconQuantity
                                    , tmpCDDBlockedFrom
                                    , tmpCDDBlockedTo
                                    , tmpCoverPerCent
                                    , tmpUseCoverPercent
                                    , tmpPriority
                                    , tmpQuantityRule
                                    , tmpDocMode
                                    , tmpReliquat
                                     );
    return nvl(tmpConvertFactor, 1);
  end GetGoodDistConvertFactor;

  function GetGoodDistUnitMeasure(aGoodID in number, aDistribUnitID in number)
    return varchar2
  is
    tmpResult           number(1);
    tmpDicUnitOfMeasure GCO_COMPL_DATA_DISTRIB.DIC_UNIT_OF_MEASURE_ID%type;
    tmpConvertFactor    GCO_COMPL_DATA_DISTRIB.CDA_CONVERSION_FACTOR%type;
    tmpNumberOfDecimal  GCO_COMPL_DATA_DISTRIB.CDA_NUMBER_OF_DECIMAL%type;
    tmpStockMin         GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MIN%type;
    tmpStockMax         GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MAX%type;
    tmpEconQuantity     GCO_COMPL_DATA_DISTRIB.CDI_ECONOMICAL_QUANTITY%type;
    tmpCDDBlockedFrom   GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_FROM%type;
    tmpCDDBlockedTo     GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_TO%type;
    tmpCoverPerCent     GCO_COMPL_DATA_DISTRIB.CDI_COVER_PERCENT%type;
    tmpUseCoverPercent  GCO_COMPL_DATA_DISTRIB.C_DRP_USE_COVER_PERCENT%type;
    tmpPriority         GCO_COMPL_DATA_DISTRIB.CDI_PRIORITY_CODE%type;
    tmpQuantityRule     GCO_COMPL_DATA_DISTRIB.C_DRP_QTY_RULE%type;
    tmpDocMode          GCO_COMPL_DATA_DISTRIB.C_DRP_DOC_MODE%type;
    tmpReliquat         GCO_COMPL_DATA_DISTRIB.C_DRP_RELIQUAT%type;
  begin
    GCO_FUNCTIONS.GetComplDataDistrib(aGoodID
                                    , aDistribUnitID
                                    , null   -- aDicDistribComplData
                                    , tmpResult
                                    , tmpDicUnitOfMeasure
                                    , tmpConvertFactor
                                    , tmpNumberOfDecimal
                                    , tmpStockMin
                                    , tmpStockMax
                                    , tmpEconQuantity
                                    , tmpCDDBlockedFrom
                                    , tmpCDDBlockedTo
                                    , tmpCoverPerCent
                                    , tmpUseCoverPercent
                                    , tmpPriority
                                    , tmpQuantityRule
                                    , tmpDocMode
                                    , tmpReliquat
                                     );
    return tmpDicUnitOfMeasure;
  end GetGoodDistUnitMeasure;

  function GetGoodDistEconomicalQty(aGoodID in number, aDistribUnitID in number)
    return number
  is
    tmpResult           number(1);
    tmpDicUnitOfMeasure GCO_COMPL_DATA_DISTRIB.DIC_UNIT_OF_MEASURE_ID%type;
    tmpConvertFactor    GCO_COMPL_DATA_DISTRIB.CDA_CONVERSION_FACTOR%type;
    tmpNumberOfDecimal  GCO_COMPL_DATA_DISTRIB.CDA_NUMBER_OF_DECIMAL%type;
    tmpStockMin         GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MIN%type;
    tmpStockMax         GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MAX%type;
    tmpEconQuantity     GCO_COMPL_DATA_DISTRIB.CDI_ECONOMICAL_QUANTITY%type;
    tmpCDDBlockedFrom   GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_FROM%type;
    tmpCDDBlockedTo     GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_TO%type;
    tmpCoverPerCent     GCO_COMPL_DATA_DISTRIB.CDI_COVER_PERCENT%type;
    tmpUseCoverPercent  GCO_COMPL_DATA_DISTRIB.C_DRP_USE_COVER_PERCENT%type;
    tmpPriority         GCO_COMPL_DATA_DISTRIB.CDI_PRIORITY_CODE%type;
    tmpQuantityRule     GCO_COMPL_DATA_DISTRIB.C_DRP_QTY_RULE%type;
    tmpDocMode          GCO_COMPL_DATA_DISTRIB.C_DRP_DOC_MODE%type;
    tmpReliquat         GCO_COMPL_DATA_DISTRIB.C_DRP_RELIQUAT%type;
  begin
    GCO_FUNCTIONS.GetComplDataDistrib(aGoodID
                                    , aDistribUnitID
                                    , null   -- aDicDistribComplData
                                    , tmpResult
                                    , tmpDicUnitOfMeasure
                                    , tmpConvertFactor
                                    , tmpNumberOfDecimal
                                    , tmpStockMin
                                    , tmpStockMax
                                    , tmpEconQuantity
                                    , tmpCDDBlockedFrom
                                    , tmpCDDBlockedTo
                                    , tmpCoverPerCent
                                    , tmpUseCoverPercent
                                    , tmpPriority
                                    , tmpQuantityRule
                                    , tmpDocMode
                                    , tmpReliquat
                                     );
    return nvl(tmpEconQuantity, 0);
  end GetGoodDistEconomicalQty;
end DOC_DRP;
