--------------------------------------------------------
--  DDL for Package Body STM_STOCK_ANALYSE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_STOCK_ANALYSE" 
is
  /* Constante globale privée */
  gpCURRENT_ANALYSE_ID STM_ABC_STOCK_ANALYSE.STM_ABC_STOCK_ANALYSE_ID%type;

  /* Fonctions et procedures privées */
  /**
  * function pGetStockAtDate
  * Description
  *    Retourne la qté en stock à une date donnée
  * @created fp 16.10.2007
  * @lastUpdate
  * @private
  * @param aGoodId : id du bien
  * @param adateRef : date de référence
  * @return
  */
  function pGetStockAtDate(aGoodId in GCO_GOOD.GCO_GOOD_ID%type, aDateRef in date, aStockIdList in clob)
    return STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type
  is
  begin
    return STM_FUNCTIONS.GetSelectedStockAtDate(aGoodId, to_char(aDateRef, 'YYYYMMDD'), aStockIdList, null);
  end pGetStockAtDate;

  /**
  * procedure pDeleteElement
  * Description
  *    Suppression des éléments selon le type
  * @created fp 10.03.2008
  * @lastUpdate
  * @private
  * @param aAnalyseId : ID de l'analyse à laquelle sont rattachés les éléments
  * @param aTable : Abbréviation de la table dont les éléments sont issus
  */
  procedure pDeleteElement(aAnalyseId in STM_ABC_STOCK_ANALYSE.STM_ABC_STOCK_ANALYSE_ID%type, aTable in STM_ABC_STOCK_ANALYSE_ELEM.ABE_TABLENAME%type)
  is
  begin
    delete from STM_ABC_STOCK_ANALYSE_ELEM
          where ABE_TABLENAME = aTable;
  end pDeleteElement;

  /**
  * function getCurrentStock
  * Description
  *    Retourne la qté en stock à une date donnée
  * @created fp 16.10.2007
  * @lastUpdate
  * @private
  * @param aAnalyseId : id de l'analyse afin de considérer les mêmes stocks
  * @param aGoodId : id du bien
  * @return
  */
  function getCurrentStock(aAnalyseId in STM_ABC_STOCK_ANALYSE.STM_ABC_STOCK_ANALYSE_ID%type, aGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type
  is
    vStockList clob;
  begin
    -- Liste des stocks dans une variable texte
    select TableToCharList(cursor(select ABE_ID
                                    from STM_ABC_STOCK_ANALYSE_ELEM
                                   where ABE_TABLENAME = 'STO'
                                     and STM_ABC_STOCK_ANALYSE_ID = aAnalyseId) )
      into vStockList
      from dual;

    return STM_FUNCTIONS.GetSelectedStockAtDate(aGoodId, to_char(sysdate, 'YYYYMMDD'), vStockList, null);
  end getCurrentStock;

  /**
  * Description
  *    Assignation de la variable globale gCURRENT_ANALYSE_ID
  */
  procedure setCurrentAnalyseId(aAnalyseId in STM_ABC_STOCK_ANALYSE.STM_ABC_STOCK_ANALYSE_ID%type)
  is
  begin
    gpCURRENT_ANALYSE_ID  := aAnalyseId;
  end setCurrentAnalyseId;

  /**
  * Description
  *    Assignation de la variable globale gCURRENT_ANALYSE_ID
  */
  function getCurrentAnalyseId
    return STM_ABC_STOCK_ANALYSE.STM_ABC_STOCK_ANALYSE_ID%type
  is
  begin
    return gpCURRENT_ANALYSE_ID;
  end getCurrentAnalyseId;

  /**
  * Description
  *    Supprime les biens éventuellement existants dans la liste des éléments
  */
  procedure resetGoodList(aAnalyseId in STM_ABC_STOCK_ANALYSE.STM_ABC_STOCK_ANALYSE_ID%type)
  is
  begin
    pDeleteElement(aAnalyseId, 'GOO');
  end resetGoodList;

  /**
  * Description
  *    Supprime les stocks éventuellement existants dans la liste des éléments
  */
  procedure resetStockList(aAnalyseId in STM_ABC_STOCK_ANALYSE.STM_ABC_STOCK_ANALYSE_ID%type)
  is
  begin
    pDeleteElement(aAnalyseId, 'STO');
  end resetStockList;

  /**
  * Description
  *    Supprime les genres de mouvements éventuellement existants dans la liste des éléments
  */
  procedure resetMovementKindList(aAnalyseId in STM_ABC_STOCK_ANALYSE.STM_ABC_STOCK_ANALYSE_ID%type)
  is
  begin
    pDeleteElement(aAnalyseId, 'MOK');
  end resetMovementKindList;

  /**
  * Description
  *    Supprime toute la liste des éléments
  */
  procedure resetAllList(aAnalyseId in STM_ABC_STOCK_ANALYSE.STM_ABC_STOCK_ANALYSE_ID%type)
  is
  begin
    resetGoodList(aAnalyseId);
    resetStockList(aAnalyseId);
    resetMovementKindList(aAnalyseId);
  end resetAllList;

  /* Fonctions et procedures publiques */
  procedure initGoodList(aAnalyseId STM_ABC_STOCK_ANALYSE.STM_ABC_STOCK_ANALYSE_ID%type, aFilter in varchar2 default null)
  is
  begin
    -- Reinit des données
    resetGoodList(aAnalyseId);

    -- Initialisation avec la liste complète des biens
    execute immediate '
    insert into STM_ABC_STOCK_ANALYSE_ELEM
                (STM_ABC_STOCK_ANALYSE_ID
               , ABE_ID
               , ABE_TABLENAME
                )
      select distinct ' ||
                      aAnalyseId ||
                      '
           , V_GCO_GOOD_LIST.GCO_GOOD_ID
           , ''GOO''
        from V_GCO_GOOD_LIST, V_GCO_PRODUCT_LIST
       where V_GCO_GOOD_LIST.GCO_GOOD_ID = V_GCO_PRODUCT_LIST.GCO_GOOD_ID
         and C_SUPPLY_MODE <> ''3''' ||
                      aFilter;
  end initGoodList;

  procedure autoInitMoveKindList(aAnalyseId STM_ABC_STOCK_ANALYSE.STM_ABC_STOCK_ANALYSE_ID%type)
  is
  begin
    -- Reinit des données
    resetMovementKindList(aAnalyseId);

    -- Initialisation des genres de mouvements (filtre minimal)
    insert into STM_ABC_STOCK_ANALYSE_ELEM
                (STM_ABC_STOCK_ANALYSE_ID
               , ABE_ID
               , ABE_TABLENAME
                )
      select aAnalyseId
           , STM_MOVEMENT_KIND_ID
           , 'MOK'
        from STM_MOVEMENT_KIND MOK
       where MOK.C_MOVEMENT_SORT = 'SOR'
         and MOK.C_MOVEMENT_TYPE not in('ALT', 'EXE', 'TRC', 'INV', 'VAL')
         and MOK.MOK_CONSUMER_ANALYSE_USE = 1;
  end autoInitMoveKindList;

  procedure initMoveKindList(aAnalyseId STM_ABC_STOCK_ANALYSE.STM_ABC_STOCK_ANALYSE_ID%type, aFilter in varchar2)
  is
  begin
    -- Reinit des données
    resetMovementKindList(aAnalyseId);

    -- Initialisation des genres de mouvements
    execute immediate '
    insert into STM_ABC_STOCK_ANALYSE_ELEM
                (STM_ABC_STOCK_ANALYSE_ID
               , ABE_ID
               , ABE_TABLENAME
                )
      select ' ||
                      aAnalyseId ||
                      '
      ,STM_MOVEMENT_KIND_ID
           , ''MOK''
        from STM_MOVEMENT_KIND MOK
       where MOK.C_MOVEMENT_SORT = ''SOR''
         and MOK.C_MOVEMENT_TYPE not in(''ALT'', ''EXE'', ''TRC'', ''INV'', ''VAL'')';
  end initMoveKindList;

  procedure initStockList(aAnalyseId STM_ABC_STOCK_ANALYSE.STM_ABC_STOCK_ANALYSE_ID%type, aFilter in varchar2)
  is
  begin
    -- Reinit des données
    resetStockList(aAnalyseId);

    -- Initialisation des stocks
    execute immediate '
    insert into STM_ABC_STOCK_ANALYSE_ELEM
                (STM_ABC_STOCK_ANALYSE_ID
               , ABE_ID
               , ABE_TABLENAME
                )
      select ' ||
                      aAnalyseId ||
                      '
           , STO.STM_STOCK_ID
           , ''STO''
        from STM_STOCK STO
       where STO.STM_STOCK_ID = STO.STM_STOCK_ID ' ||
                      aFilter;
  end initStockList;

  procedure autoInitStockList(aAnalyseId STM_ABC_STOCK_ANALYSE.STM_ABC_STOCK_ANALYSE_ID%type)
  is
  begin
    -- Reinit des données
    resetStockList(aAnalyseId);

    -- Initialisation des stocks (filtre minimal)
    insert into STM_ABC_STOCK_ANALYSE_ELEM
                (STM_ABC_STOCK_ANALYSE_ID
               , ABE_ID
               , ABE_TABLENAME
                )
      select aAnalyseId
           , STO.STM_STOCK_ID
           , 'STO'
        from STM_STOCK STO
       where STO.C_ACCESS_METHOD = 'PUBLIC'
         and STO.STO_METAL_ACCOUNT <> 1
         and STO_CONSUMER_ANALYSE_USE = 1;
  end autoInitStockList;

  /**
  * Description
  *    Initialisation rapide de la table STM_ABC_STOCK_ANALYSE_ELEM
  */
  procedure quickInit(aAnalyseId STM_ABC_STOCK_ANALYSE.STM_ABC_STOCK_ANALYSE_ID%type)
  is
  begin
    initGoodList(aAnalyseId);
    autoInitMoveKindList(aAnalyseId);
    autoInitStockList(aAnalyseId);
  end quickInit;

  /**
  * Description
  *    Initialisation rapide de la table STM_ABC_STOCK_ANALYSE_ELEM
  */
  procedure InitGoodLine(aAnalyseId STM_ABC_STOCK_ANALYSE.STM_ABC_STOCK_ANALYSE_ID%type, aGoodLineId DIC_GOOD_LINE.DIC_GOOD_LINE_ID%type)
  is
  begin
    initGoodList(aAnalyseId, 'AND DIC_GOOD_LINE_ID = ''' || aGoodLineId || '''');
    autoInitMoveKindList(aAnalyseId);
    autoInitStockList(aAnalyseId);
  end InitGoodLine;

  /**
  * Description
  *   Recherche la dernière analyse réalisée pour 1 bien
  */
  function getLastGoodAnalyse(aGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return STM_ABC_STOCK_ANALYSE.STM_ABC_STOCK_ANALYSE_ID%type
  is
    vResult STM_ABC_STOCK_ANALYSE.STM_ABC_STOCK_ANALYSE_ID%type;
  begin
    select max(ABH.STM_ABC_STOCK_ANALYSE_ID)
      into vResult
      from STM_ABC_STOCK_ANALYSE ABH
         , STM_ABC_STOCK_ANALYSE_DET ABC
     where ABH.STM_ABC_STOCK_ANALYSE_ID = ABC.STM_ABC_STOCK_ANALYSE_ID
       and ABC.GCO_GOOD_ID = aGoodId;

    return vResult;
  end getLastGoodAnalyse;

  /**
  * Description
  *   fonction deterministic retournant le prix unitaire selon mode de gestion
  */
  function getCostPrice(aGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return GCO_GOOD_CALC_DATA.GOO_BASE_COST_PRICE%type deterministic
  is
  begin
    return GCO_FUNCTIONS.getCostPriceWithManagementMode(aGoodId);
  end getCostPrice;

  /**
  * Description
  *   recherche de la description d'une analyse
  */
  function getWording(aAnalyseId in STM_ABC_STOCK_ANALYSE.STM_ABC_STOCK_ANALYSE_ID%type)
    return STM_ABC_STOCK_ANALYSE.ABH_WORDING%type
  is
    vResult STM_ABC_STOCK_ANALYSE.ABH_WORDING%type;
  begin
    select ABH_WORDING
      into vResult
      from STM_ABC_STOCK_ANALYSE
     where STM_ABC_STOCK_ANALYSE_ID = aAnalyseId;

    return vResult;
  exception
    when no_data_found then
      return null;
  end getWording;

  /**
  * Description
  *    Retourne le numéro de mois relatif par rapport à une date de référence
  */
  function getInternalMonthNo(aDateRef in date, aDateTest in date)
    return pls_integer deterministic
  is
    vResult pls_integer;
  begin
    vResult  := round( (aDateTest - aDateRef) / 31);

    if aDateRef <= aDateTest then
      vResult  := greatest(vResult, 1);

      while trunc(aDateTest) > add_months(trunc(aDateRef), vResult) - 1 loop
        vResult  := vResult + 1;
      end loop;
    else
      vResult  := least(vResult, -1);

      while trunc(aDateTest) < add_months(trunc(aDateRef), vResult) + 1 loop
        vResult  := vResult - 1;
      end loop;
    end if;

    return vResult;
  end getInternalMonthNo;

  /**
  * Description
  *   retourne la description de la periode sous forme d'intervale de dates
  */
  function getPeriodDescr(aDateRef in date, aPerNo in pls_integer)
    return tNoPeriod deterministic
  is
    vResult tNoPeriod;
  begin
    if aPerNo < 0 then
      vResult  := to_char(add_months(aDateRef, aPerno) + 1, 'DD.MM.YYYY') || ' - ' || to_char(add_months(aDateRef, aPerno + 1), 'DD.MM.YYYY');
    end if;

    return vResult;
  end getPeriodDescr;

  /**
  * Description
  *    Delay d'approvisionnement moyen calculé
  */
  procedure getPurchaseSupplyDelayCorr(
    aGoodId       in     GCO_GOOD.GCO_GOOD_ID%type
  , aSupplyDelay  in     GCO_COMPL_DATA_PURCHASE.CPU_SUPPLY_DELAY%type
  , aStartDate    in     date
  , aEnddate      in     date
  , aAvgQty       out    number
  , aAvgCorrDelay out    number
  )
  is
    vNbDaysExpected  pls_integer;
    vNbDaysWait      pls_integer;
    vCumulQty        DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY_SU%type   := 0;
    vCumulCorrection DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY_SU%type   := 0;
    vOldId           DOC_DOCUMENT.DOC_DOCUMENT_ID%type                := 0;
    vNbDoc           pls_integer                                      := 0;
  begin
    aAvgQty  := 0;

    for tplDelay in (select   PDE_CHILD.PDE_BASIS_QUANTITY_SU
                            , PDE_FATHER.DOC_POSITION_DETAIL_ID FATHER_POSITION_DETAIL_ID
                            , PDE_CHILD.DOC_POSITION_DETAIL_ID CHILD_POSITION_DETAIL_ID
                            , PDE_FATHER.PDE_BASIS_DELAY
                            , PDE_FATHER.PDE_INTERMEDIATE_DELAY
                            , DMT_CHILD.DMT_DATE_DOCUMENT
                            , GAU_FATHER.C_ADMIN_DOMAIN
                            , DMT_CHILD.PAC_THIRD_ID
                         from DOC_GAUGE GAU_FATHER
                            , DOC_GAUGE_STRUCTURED GAS_FATHER
                            , DOC_POSITION_DETAIL PDE_FATHER
                            , DOC_DOCUMENT DMT_FATHER
                            , DOC_POSITION_DETAIL PDE_CHILD
                            , DOC_DOCUMENT DMT_CHILD
                            , DOC_GAUGE_STRUCTURED GAS_CHILD
                        where GAU_FATHER.C_ADMIN_DOMAIN = '1'
                          and GAU_FATHER.C_GAUGE_TYPE = '2'
                          and GAS_FATHER.DOC_GAUGE_ID = GAU_FATHER.DOC_GAUGE_ID
                          and GAS_FATHER.C_GAUGE_TITLE = '1'
                          and PDE_FATHER.DOC_GAUGE_ID = GAU_FATHER.DOC_GAUGE_ID
                          and PDE_FATHER.GCO_GOOD_ID = aGoodId
                          and PDE_FATHER.PDE_BALANCE_QUANTITY = 0
                          and DMT_FATHER.DOC_DOCUMENT_ID = PDE_FATHER.DOC_DOCUMENT_ID
                          and DMT_FATHER.DMT_DATE_DOCUMENT between aStartDate and aEndDate
                          and PDE_CHILD.DOC_DOC_POSITION_DETAIL_ID = PDE_FATHER.DOC_POSITION_DETAIL_ID
                          and DMT_CHILD.DOC_DOCUMENT_ID = PDE_CHILD.DOC_DOCUMENT_ID
                          and DMT_CHILD.DMT_DATE_DOCUMENT between aStartDate and aEndDate
                          and GAS_CHILD.DOC_GAUGE_ID = DMT_CHILD.DOC_GAUGE_ID
                          and GAS_CHILD.C_GAUGE_TITLE <> GAS_FATHER.C_GAUGE_TITLE
                     order by DMT_FATHER.DMT_DATE_DOCUMENT
                            , DMT_FATHER.DOC_DOCUMENT_ID
                            , PDE_FATHER.DOC_POSITION_DETAIL_ID) loop
      if vOldId <> tplDelay.FATHER_POSITION_DETAIL_ID then
        vNbDoc  := vNbDoc + 1;
        vOldId  := tplDelay.FATHER_POSITION_DETAIL_ID;
      end if;

      for tplDelayHisto in (select   DHI_BASIS_DELAY
                                   , DHI_INTERMEDIATE_DELAY
                                from DOC_DELAY_HISTORY
                               where DOC_POSITION_DETAIL_ID = tplDelay.FATHER_POSITION_DETAIL_ID
                            order by DOC_DELAY_HISTORY_ID) loop
        vNbDaysWait      :=
                 DOC_DELAY_FUNCTIONS.OpenDaysbetween(tplDelay.DMT_DATE_DOCUMENT, tplDelayHisto.DHI_BASIS_DELAY, tplDelay.C_ADMIN_DOMAIN, tplDelay.PAC_THIRD_ID);
        vNbDaysExpected  :=
          DOC_DELAY_FUNCTIONS.OpenDaysbetween(tplDelayHisto.DHI_BASIS_DELAY
                                            , tplDelayHisto.DHI_INTERMEDIATE_DELAY
                                            , tplDelay.C_ADMIN_DOMAIN
                                            , tplDelay.PAC_THIRD_ID
                                             );
        vCumulQty        := vCumulQty + tplDelay.PDE_BASIS_QUANTITY_SU;

        if vNbDaysWait < aSupplyDelay then
          vCumulCorrection  := vCumulCorrection + tplDelay.PDE_BASIS_QUANTITY_SU * greatest(-aSupplyDelay, vNbDaysWait - vNbDaysExpected);
        elsif vNbDaysWait > vNbDaysExpected then
          vCumulCorrection  := vCumulCorrection + tplDelay.PDE_BASIS_QUANTITY_SU *(vNbDaysWait - vNbDaysExpected);
        end if;

        exit;
      end loop;
    end loop;

    if vNbDoc > 0 then
      aAvgQty        := vCumulQty / vNbDoc;
      aAvgCorrDelay  := vCumulCorrection / vCumulQty;
    end if;
  end getPurchaseSupplyDelayCorr;

  /**
  * Description
  *   Recherche des différentes informations concernant le bien et ses données complémentaires
  */
  procedure getGoodInfos(
    aGoodId             in     GCO_GOOD.GCO_GOOD_Id%type
  , aReference          out    GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , aDescription        out    GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type
  , aSupplyMode         out    GCO_PRODUCT.C_SUPPLY_MODE%type
  , aQuantityMin        out    GCO_COMPL_DATA_STOCK.CST_QUANTITY_MIN%type
  , aQuantityMax        out    GCO_COMPL_DATA_STOCK.CST_QUANTITY_MAX%type
  , aTriggerPoint       out    GCO_COMPL_DATA_STOCK.CST_TRIGGER_POINT%type
  , aEconomicalQuantity out    GCO_COMPL_DATA_PURCHASE.CPU_ECONOMICAL_QUANTITY%type
  , aLotQuantity        out    GCO_COMPL_DATA_MANUFACTURE.CMA_LOT_QUANTITY%type
  , aSupplyDelay        out    GCO_COMPL_DATA_PURCHASE.CPU_SUPPLY_DELAY%type
  )
  is
  begin
    -- Descriptions...
    select GOO.GOO_MAJOR_REFERENCE
         , DES.DES_SHORT_DESCRIPTION
         , PDT.C_SUPPLY_MODE
      into aReference
         , aDescription
         , aSupplyMode
      from GCO_GOOD GOO
         , GCO_DESCRIPTION DES
         , GCO_PRODUCT PDT
     where GOO.GCO_GOOD_ID = aGoodId
       and DES.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
       and DES.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.GetUserLangId
       and DES.C_DESCRIPTION_TYPE(+) = '01'
       and PDT.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID;

    -- Données complémentaires de stock
    select sum(nvl(CST.CST_QUANTITY_MIN, 0) ) CST_QUANTITY_MIN
         , sum(nvl(CST.CST_QUANTITY_MAX, 0) ) CST_QUANTITY_MAX
         , sum(nvl(CST.CST_TRIGGER_POINT, 0) ) CST_TRIGGER_POINT
      into aQuantityMin
         , aQuantityMax
         , aTriggerPoint
      from GCO_COMPL_DATA_STOCK CST
         , STM_ABC_STOCK_ANALYSE_ELEM TMP
     where CST.GCO_GOOD_ID = aGoodId
       and CST.STM_STOCK_ID = TMP.ABE_ID
       and TMP.ABE_TABLENAME = 'STO';

    if aQuantityMin = 0 then
      aQuantityMin  := null;
    end if;

    if aQuantityMax = 0 then
      aQuantityMax  := null;
    end if;

    if aTriggerPoint = 0 then
      aTriggerPoint  := null;
    end if;

    if aSupplyMode = cSupplyModePurchased then
      -- Données complémentaires d'achat
      begin
        select CPU.CPU_ECONOMICAL_QUANTITY
             , CPU.CPU_SUPPLY_DELAY
          into aEconomicalQuantity
             , aSupplyDelay
          from GCO_COMPL_DATA_PURCHASE CPU
         where CPU.GCO_GOOD_ID(+) = aGoodId
           and CPU.CPU_DEFAULT_SUPPLIER(+) = 1;
      exception
        when no_data_found then
          null;
      end;
    elsif aSupplyMode = cSupplyModeManufactured then
      begin
        select CMA.CMA_ECONOMICAL_QUANTITY
             , CMA.CMA_LOT_QUANTITY
             , CMA.CMA_MANUFACTURING_DELAY
          into aEconomicalQuantity
             , aLotQuantity
             , aSupplyDelay
          from GCO_COMPL_DATA_MANUFACTURE CMA
         where CMA.GCO_GOOD_ID(+) = aGoodId
           and CMA.CMA_DEFAULT(+) = 1;
      exception
        when no_data_found then
          null;
      end;

      aLotQuantity         := nvl(aLotQuantity, 0);
      aEconomicalQuantity  := nvl(aEconomicalQuantity, 0);
    end if;
  exception
    when others then
      ra(replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Erreur lors de la recherche d''informations sur un produit! GCO_GOOD_ID : [GCO_GOOD_ID]')
               , '[GCO_GOOD_ID]'
               , aGoodId
                )
        );
  end getGoodInfos;

  /**
  * Description
  *    retourne la quantité approvisionnement libre
  */
  procedure getSupplyQties(aGoodId in GCO_GOOD.GCO_GOOD_ID%type, aFreeQty out FAL_NETWORK_SUPPLY.FAN_FREE_QTY%type
                                                                                                                  --, aBalanceQty out    FAL_NETWORK_SUPPLY.FAN_BALANCE_QTY%type
  )
  is
    vResult FAL_NETWORK_SUPPLY.FAN_FREE_QTY%type;
  begin
    select sum(nvl(FAN_FREE_QTY, 0) )
--         , sum(nvl(FAN_BALANCE_QTY,0))
    into   aFreeQty
--         , aBalanceQty
    from   FAL_NETWORK_SUPPLY FAS
         , STM_ABC_STOCK_ANALYSE_ELEM TMP
     where FAS.GCO_GOOD_ID = aGoodId
       and FAS.STM_STOCK_ID = TMP.ABE_ID
       and TMP.ABE_TABLENAME = 'STO';
  end getSupplyQties;

  /**
  * Description
  *    retourne la quantité besoin libre
  */
  function getFreeNeedQty(aGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return FAL_NETWORK_NEED.FAN_FREE_QTY%type
  is
    vResult FAL_NETWORK_SUPPLY.FAN_FREE_QTY%type;
  begin
    select sum(FAN_FREE_QTY)
      into vResult
      from FAL_NETWORK_NEED FAN
         , STM_ABC_STOCK_ANALYSE_ELEM TMP
     where FAN.GCO_GOOD_ID = aGoodId
       and FAN.STM_STOCK_ID = TMP.ABE_ID
       and TMP.ABE_TABLENAME = 'STO';

    return vResult;
  end getFreeNeedQty;

  /**
  * Description
  *    Mise à jour du stock mini selon analyse
  */
  procedure updateStockMin(aAnalyseDetailId in STM_ABC_STOCK_ANALYSE_DET.STM_ABC_STOCK_ANALYSE_DET_ID%type)
  is
    vGoodId      GCO_GOOD.GCO_GOOD_ID%type;
    vNewStockMin STM_ABC_STOCK_ANALYSE_DET.ABC_NEW_QUANTITY_MIN%type;
    vOldStockMin STM_ABC_STOCK_ANALYSE_DET.CST_QUANTITY_MIN%type;
    vNbCompl     pls_integer;
    vFirstPass   boolean                                               := true;
    vNullMode    boolean                                               := false;
  begin
    select GCO_GOOD_ID
         , CST_QUANTITY_MIN
         , ABC_NEW_QUANTITY_MIN
      into vGoodId
         , vOldStockMin
         , vNewStockMin
      from STM_ABC_STOCK_ANALYSE_DET
     where STM_ABC_STOCK_ANALYSE_DET_ID = aAnalyseDetailId;

    if    vOldStockMin is not null
       or vNewStockMin is not null then
      select count(*)
        into vNbCompl
        from GCO_COMPL_DATA_STOCK
       where GCO_GOOD_ID = vGoodId;

      -- pas de données complémentaires, on les crée
      if vNbCompl = 0 then
        insert into GCO_COMPL_DATA_STOCK
                    (GCO_COMPL_DATA_STOCK_ID
                   , DIC_UNIT_OF_MEASURE_ID
                   , GCO_GOOD_ID
                   , CDA_NUMBER_OF_DECIMAL
                   , CDA_CONVERSION_FACTOR
                   , CST_QUANTITY_MIN
                   , A_DATECRE
                   , A_IDCRE
                    )
          select INIT_ID_SEQ.nextval
               , DIC_UNIT_OF_MEASURE_ID
               , GCO_GOOD_ID
               , GOO_NUMBER_OF_DECIMAL
               , 1
               , vNewStockMin
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
            from GCO_GOOD
           where GCO_GOOD_ID = vGoodId;
      -- Une seule donnée complémentaire, on la met à jour
      elsif vNbCompl = 1 then
        update GCO_COMPL_DATA_STOCK
           set CST_QUANTITY_MIN = vNewStockMin
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where GCO_GOOD_ID = vGoodId;
      -- Plusieurs lignes de données complémentaires, on les met à jour par une règle de 3
      else
        for tplStockMin in (select   GCO_COMPL_DATA_STOCK_ID
                                   , CST_QUANTITY_MIN
                                from GCO_COMPL_DATA_STOCK
                               where GCO_GOOD_ID = vGoodId
                            order by CST_QUANTITY_MIN nulls last) loop
          -- cas ou les données existantes ont toutes la qté min à null
          if    (    vFirstPass
                 and tplStockMin.CST_QUANTITY_MIN is null)
             or vNullMode then
            update GCO_COMPL_DATA_STOCK
               set CST_QUANTITY_MIN = vNewStockMin / vNbCompl
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where GCO_COMPL_DATA_STOCK_ID = tplStockMin.GCO_COMPL_DATA_STOCK_ID;

            --Activation du mode null
            vNullMode  := true;
          -- cas normal
          elsif tplStockMin.CST_QUANTITY_MIN is not null then
            update GCO_COMPL_DATA_STOCK
               set CST_QUANTITY_MIN = vNewStockMin * tplStockMin.CST_QUANTITY_MIN / vOldStockMin
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where GCO_COMPL_DATA_STOCK_ID = tplStockMin.GCO_COMPL_DATA_STOCK_ID;
          end if;

          -- Indicateur de première passe
          if vFirstPass then
            vFirstPass  := false;
          end if;
        end loop;
      end if;

      -- maj infos analyse
      update STM_ABC_STOCK_ANALYSE_DET
         set ABC_SELECT = 0
           , ABC_INFO_UPDATE_QUANTITY_MIN = PCS.PC_I_LIB_SESSION.GetUserIni || ' - ' || to_char(sysdate, 'DD.MM.YYYY HH24:MI:SS')
       where STM_ABC_STOCK_ANALYSE_DET_ID = aAnalyseDetailId;
    end if;
  end updateStockMin;

  /**
  * Description
  *    Mise à jour du stock max selon analyse
  */
  procedure updateStockMax(aAnalyseDetailId in STM_ABC_STOCK_ANALYSE_DET.STM_ABC_STOCK_ANALYSE_DET_ID%type)
  is
    vGoodId      GCO_GOOD.GCO_GOOD_ID%type;
    vNewStockMax STM_ABC_STOCK_ANALYSE_DET.ABC_NEW_QUANTITY_MAX%type;
    vOldStockMax STM_ABC_STOCK_ANALYSE_DET.CST_QUANTITY_MAX%type;
    vNbCompl     pls_integer;
    vFirstPass   boolean                                               := true;
    vNullMode    boolean                                               := false;
  begin
    select GCO_GOOD_ID
         , CST_QUANTITY_MAX
         , ABC_NEW_QUANTITY_MAX
      into vGoodId
         , vOldStockMax
         , vNewStockMax
      from STM_ABC_STOCK_ANALYSE_DET
     where STM_ABC_STOCK_ANALYSE_DET_ID = aAnalyseDetailId;

    if    vOldStockMax is not null
       or vNewStockMax is not null then
      select count(*)
        into vNbCompl
        from GCO_COMPL_DATA_STOCK
       where GCO_GOOD_ID = vGoodId;

      -- pas de données complémentaires, on les crée
      if vNbCompl = 0 then
        insert into GCO_COMPL_DATA_STOCK
                    (GCO_COMPL_DATA_STOCK_ID
                   , DIC_UNIT_OF_MEASURE_ID
                   , GCO_GOOD_ID
                   , CDA_NUMBER_OF_DECIMAL
                   , CDA_CONVERSION_FACTOR
                   , CST_QUANTITY_MAX
                   , A_DATECRE
                   , A_IDCRE
                    )
          select INIT_ID_SEQ.nextval
               , DIC_UNIT_OF_MEASURE_ID
               , GCO_GOOD_ID
               , GOO_NUMBER_OF_DECIMAL
               , 1
               , vNewStockMax
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
            from GCO_GOOD
           where GCO_GOOD_ID = vGoodId;
      -- Une seule donnée complémentaire, on la met à jour
      elsif vNbCompl = 1 then
        update GCO_COMPL_DATA_STOCK
           set CST_QUANTITY_MAX = vNewStockMax
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where GCO_GOOD_ID = vGoodId;
      -- Plusieurs lignes de données complémentaires, on les met à jour par une règle de 3
      else
        for tplStockMax in (select   GCO_COMPL_DATA_STOCK_ID
                                   , CST_QUANTITY_MAX
                                from GCO_COMPL_DATA_STOCK
                               where GCO_GOOD_ID = vGoodId
                            order by CST_QUANTITY_MAX nulls last) loop
          -- cas ou les données existantes ont toutes la qté max à null
          if    (    vFirstPass
                 and tplStockMax.CST_QUANTITY_MAX is null)
             or vNullMode then
            update GCO_COMPL_DATA_STOCK
               set CST_QUANTITY_MAX = vNewStockMax / vNbCompl
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where GCO_COMPL_DATA_STOCK_ID = tplStockMax.GCO_COMPL_DATA_STOCK_ID;

            --Activation du mode null
            vNullMode  := true;
          -- cas normal
          elsif tplStockMax.CST_QUANTITY_MAX is not null then
            update GCO_COMPL_DATA_STOCK
               set CST_QUANTITY_MAX = vNewStockMax * tplStockMax.CST_QUANTITY_MAX / vOldStockMax
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where GCO_COMPL_DATA_STOCK_ID = tplStockMax.GCO_COMPL_DATA_STOCK_ID;
          end if;

          -- Indicateur de première passe
          if vFirstPass then
            vFirstPass  := false;
          end if;
        end loop;
      end if;

      -- maj infos analyse
      update STM_ABC_STOCK_ANALYSE_DET
         set ABC_SELECT = 0
           , ABC_INFO_UPDATE_QUANTITY_MAX = PCS.PC_I_LIB_SESSION.GetUserIni || ' - ' || to_char(sysdate, 'DD.MM.YYYY HH24:MI:SS')
       where STM_ABC_STOCK_ANALYSE_DET_ID = aAnalyseDetailId;
    end if;
  end updateStockMax;

  /**
  * Description
  *    Mise à jour du point de commande
  */
  procedure updateTriggerPoint(aAnalyseDetailId in STM_ABC_STOCK_ANALYSE_DET.STM_ABC_STOCK_ANALYSE_DET_ID%type)
  is
    vGoodId          GCO_GOOD.GCO_GOOD_ID%type;
    vNewTriggerPoint STM_ABC_STOCK_ANALYSE_DET.ABC_NEW_TRIGGER_POINT%type;
    vOldTriggerPoint STM_ABC_STOCK_ANALYSE_DET.CST_TRIGGER_POINT%type;
    vNbCompl         pls_integer;
    vFirstPass       boolean                                                := true;
    vNullMode        boolean                                                := false;
  begin
    select GCO_GOOD_ID
         , CST_TRIGGER_POINT
         , ABC_NEW_TRIGGER_POINT
      into vGoodId
         , vOldTriggerPoint
         , vNewTriggerPoint
      from STM_ABC_STOCK_ANALYSE_DET
     where STM_ABC_STOCK_ANALYSE_DET_ID = aAnalyseDetailId;

    if    vOldTriggerPoint is not null
       or vNewTriggerPoint is not null then
      select count(*)
        into vNbCompl
        from GCO_COMPL_DATA_STOCK
       where GCO_GOOD_ID = vGoodId;

      -- pas de données complémentaires, on les crée
      if vNbCompl = 0 then
        insert into GCO_COMPL_DATA_STOCK
                    (GCO_COMPL_DATA_STOCK_ID
                   , DIC_UNIT_OF_MEASURE_ID
                   , GCO_GOOD_ID
                   , CDA_NUMBER_OF_DECIMAL
                   , CDA_CONVERSION_FACTOR
                   , CST_TRIGGER_POINT
                   , A_DATECRE
                   , A_IDCRE
                    )
          select INIT_ID_SEQ.nextval
               , DIC_UNIT_OF_MEASURE_ID
               , GCO_GOOD_ID
               , GOO_NUMBER_OF_DECIMAL
               , 1
               , vNewTriggerPoint
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
            from GCO_GOOD
           where GCO_GOOD_ID = vGoodId;
      -- Une seule donnée complémentaire, on la met à jour
      elsif vNbCompl = 1 then
        update GCO_COMPL_DATA_STOCK
           set CST_TRIGGER_POINT = vNewTriggerPoint
         where GCO_GOOD_ID = vGoodId;
      -- Plusieurs lignes de données complémentaires, on les met à jour par une règle de 3
      else
        for tplTriggerPoint in (select   GCO_COMPL_DATA_STOCK_ID
                                       , CST_TRIGGER_POINT
                                    from GCO_COMPL_DATA_STOCK
                                   where GCO_GOOD_ID = vGoodId
                                order by CST_TRIGGER_POINT nulls last) loop
          -- cas ou les données existantes ont toutes le champ à null
          if    (    vFirstPass
                 and tplTriggerPoint.CST_TRIGGER_POINT is null)
             or vNullMode then
            update GCO_COMPL_DATA_STOCK
               set CST_TRIGGER_POINT = vNewTriggerPoint / vNbCompl
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where GCO_COMPL_DATA_STOCK_ID = tplTriggerPoint.GCO_COMPL_DATA_STOCK_ID;

            --Activation du mode null
            vNullMode  := true;
          -- cas normal
          elsif tplTriggerPoint.CST_TRIGGER_POINT is not null then
            update GCO_COMPL_DATA_STOCK
               set CST_TRIGGER_POINT = vNewTriggerPoint * tplTriggerPoint.CST_TRIGGER_POINT / vOldTriggerPoint
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where GCO_COMPL_DATA_STOCK_ID = tplTriggerPoint.GCO_COMPL_DATA_STOCK_ID;
          end if;

          -- Indicateur de première passe
          if vFirstPass then
            vFirstPass  := false;
          end if;
        end loop;
      end if;

      -- maj infos analyse
      update STM_ABC_STOCK_ANALYSE_DET
         set ABC_SELECT = 0
           , ABC_INFO_UPDATE_TRIGGER_POINT = PCS.PC_I_LIB_SESSION.GetUserIni || ' - ' || to_char(sysdate, 'DD.MM.YYYY HH24:MI:SS')
       where STM_ABC_STOCK_ANALYSE_DET_ID = aAnalyseDetailId;
    end if;
  end updateTriggerPoint;

  /**
  * Description
  *    Mise à jour du délai d'approvisionnement
  */
  procedure updateSupplyDelay(aAnalyseDetailId in STM_ABC_STOCK_ANALYSE_DET.STM_ABC_STOCK_ANALYSE_DET_ID%type, aMonthWorkingDays in number)
  is
    vGoodId         GCO_GOOD.GCO_GOOD_ID%type;
    vNewSupplyDelay STM_ABC_STOCK_ANALYSE_DET.ABC_NEW_SUPPLY_DELAY%type;
    vOldSupplyDelay STM_ABC_STOCK_ANALYSE_DET.ABC_SUPPLY_DELAY%type;
    vSupplyMode     STM_ABC_STOCK_ANALYSE_DET.C_SUPPLY_MODE%type;
  begin
    select ABC.GCO_GOOD_ID
         , round(ABC.ABC_NEW_SUPPLY_DELAY * aMonthWorkingDays)
         , round(ABC_SUPPLY_DELAY * aMonthWorkingDays)
         , ABC.C_SUPPLY_MODE
      into vGoodId
         , vNewSupplyDelay
         , vOldSupplyDelay
         , vSupplyMode
      from STM_ABC_STOCK_ANALYSE_DET ABC
     where ABC.STM_ABC_STOCK_ANALYSE_DET_ID = aAnalyseDetailId;

    if    vOldSupplyDelay is not null
       or vNewSupplyDelay is not null then
      if vNewSupplyDelay = 0 then
        vNewSupplyDelay  := null;
      end if;

      -- article acheté
      if vSupplyMode = '1' then
        begin
          update GCO_COMPL_DATA_PURCHASE
             set CPU_SUPPLY_DELAY = vNewSupplyDelay
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where GCO_GOOD_ID = vGoodId;
        exception
          when others then
            ra(vNewSupplyDelay);
        end;
      -- article fabriqué
      elsif vSupplyMode = '2' then
        update GCO_COMPL_DATA_MANUFACTURE
           set CMA_MANUFACTURING_DELAY = vNewSupplyDelay
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where GCO_GOOD_ID = vGoodId;
      end if;

      -- maj infos analyse
      update STM_ABC_STOCK_ANALYSE_DET
         set ABC_SELECT = 0
           , ABC_INFO_UPDATE_SUPPLY_DELAY = PCS.PC_I_LIB_SESSION.GetUserIni || ' - ' || to_char(sysdate, 'DD.MM.YYYY HH24:MI:SS')
       where STM_ABC_STOCK_ANALYSE_DET_ID = aAnalyseDetailId;
    end if;
  end updateSupplyDelay;

  procedure CreateHeader(
    aWording    in STM_ABC_STOCK_ANALYSE.ABH_WORDING%type
  , aAnalyseId  in STM_ABC_STOCK_ANALYSE.STM_ABC_STOCK_ANALYSE_ID%type
  , aXmlOptions in STM_ABC_STOCK_ANALYSE.ABH_OPTIONS%type
  )
  is
  begin
    insert into STM_ABC_STOCK_ANALYSE
                (STM_ABC_STOCK_ANALYSE_ID
               , ABH_WORDING
               , ABH_REF_DATE
               , ABH_START_DATE
               , ABH_OPTIONS
               , A_DATECRE
               , A_IDCRE
                )
         values (aAnalyseId
               , aWording
               , sysdate
               , sysdate
               , aXmlOptions
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end;

  /**
  * Description
  *    fonction retournant une table avec les biens à analyser et leur code ABC
  */
  procedure analyseABC(
    aWording                   in STM_ABC_STOCK_ANALYSE.ABH_WORDING%type
  , aAnalyseId                 in STM_ABC_STOCK_ANALYSE.STM_ABC_STOCK_ANALYSE_ID%type
  , aMode                      in pls_integer default 1
  , aNbMonth                   in pls_integer default 12
  , aThresholdB                in number default 80
  , aThresholdC                in number default 15
  , aDateRef                   in date default sysdate
  , aWindowMode                in pls_integer default 1
  , aAllowPartial              in number default 0
  , aCompPercentMargin         in number default 5
  , aSupplyDelayPercentMargin  in number default 20
  , aQtyMinPercentMargin       in number default 20
  , aTriggerPointPercentMargin in number default 20
  , aMinTurnoverRatio          in number default 0.5
  , aMonthWorkingDays          in number default 20
  )
  is
    -- curseur d'analyse principal
    cursor crGoodValues(acrAnalyseId in number, aCrMode in number, aCrNbMonth in pls_integer, aCrDateRef in date, aCrHalfDate in date)
    is
      select   TMP.GCO_GOOD_ID
             , ANA.*
          from (select GCO_GOOD_ID id
                     , case
                         when aCrMode in(2, 4) then SMO_GOOD_QUANTITY
                         when aCrMode in(1, 3) then SMO_GOOD_QUANTITY * getCostPrice(GCO_GOOD_ID)
                       end SMO_GOOD_VALUE
                     , SMO_GOOD_QUANTITY * getCostPrice(GCO_GOOD_ID) SMO_GOOD_PRICE
                     , SMO_GOOD_QUANTITY
                     , SMO_MIN_MOVEMENT_DATE
                     , SMO_MAX_MOVEMENT_DATE
                     , STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO_MAX_MOVEMENT_DATE) -
                       STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO_MIN_MOVEMENT_DATE) +
                       1 SMO_NB_MONTH
                     , SMO_GOOD_QUANTITY_01
                     , SMO_GOOD_QUANTITY_01 * getCostPrice(GCO_GOOD_ID) SMO_GOOD_PRICE_01
                     , SMO_GOOD_QUANTITY_02
                     , SMO_GOOD_QUANTITY_02 * getCostPrice(GCO_GOOD_ID) SMO_GOOD_PRICE_02
                     , SMO_GOOD_QUANTITY_03
                     , SMO_GOOD_QUANTITY_03 * getCostPrice(GCO_GOOD_ID) SMO_GOOD_PRICE_03
                     , SMO_GOOD_QUANTITY_04
                     , SMO_GOOD_QUANTITY_04 * getCostPrice(GCO_GOOD_ID) SMO_GOOD_PRICE_04
                     , SMO_GOOD_QUANTITY_05
                     , SMO_GOOD_QUANTITY_05 * getCostPrice(GCO_GOOD_ID) SMO_GOOD_PRICE_05
                     , SMO_GOOD_QUANTITY_06
                     , SMO_GOOD_QUANTITY_06 * getCostPrice(GCO_GOOD_ID) SMO_GOOD_PRICE_06
                     , SMO_GOOD_QUANTITY_07
                     , SMO_GOOD_QUANTITY_07 * getCostPrice(GCO_GOOD_ID) SMO_GOOD_PRICE_07
                     , SMO_GOOD_QUANTITY_08
                     , SMO_GOOD_QUANTITY_08 * getCostPrice(GCO_GOOD_ID) SMO_GOOD_PRICE_08
                     , SMO_GOOD_QUANTITY_09
                     , SMO_GOOD_QUANTITY_09 * getCostPrice(GCO_GOOD_ID) SMO_GOOD_PRICE_09
                     , SMO_GOOD_QUANTITY_10
                     , SMO_GOOD_QUANTITY_10 * getCostPrice(GCO_GOOD_ID) SMO_GOOD_PRICE_10
                     , SMO_GOOD_QUANTITY_11
                     , SMO_GOOD_QUANTITY_11 * getCostPrice(GCO_GOOD_ID) SMO_GOOD_PRICE_11
                     , SMO_GOOD_QUANTITY_12
                     , SMO_GOOD_QUANTITY_12 * getCostPrice(GCO_GOOD_ID) SMO_GOOD_PRICE_12
                     , SMO_GOOD_QUANTITY_13
                     , SMO_GOOD_QUANTITY_13 * getCostPrice(GCO_GOOD_ID) SMO_GOOD_PRICE_13
                     , SMO_GOOD_QUANTITY_14
                     , SMO_GOOD_QUANTITY_14 * getCostPrice(GCO_GOOD_ID) SMO_GOOD_PRICE_14
                     , SMO_GOOD_QUANTITY_15
                     , SMO_GOOD_QUANTITY_15 * getCostPrice(GCO_GOOD_ID) SMO_GOOD_PRICE_15
                     , decode(aCrMode, 2, SMO_GOOD_QUANTITY_H1, 1, SMO_GOOD_QUANTITY_H1 * getCostPrice(GCO_GOOD_ID) ) SMO_GOOD_VALUE_H1
                     , decode(aCrMode, 2, SMO_GOOD_QUANTITY_H2, 1, SMO_GOOD_QUANTITY_H2 * getCostPrice(GCO_GOOD_ID) ) SMO_GOOD_VALUE_H2
                  from (select   SMO.GCO_GOOD_ID
                               , sum(SMO.SMO_MOVEMENT_QUANTITY) SMO_GOOD_QUANTITY
                               , min(SMO.SMO_MOVEMENT_DATE) SMO_MIN_MOVEMENT_DATE
                               , max(SMO.SMO_MOVEMENT_DATE) SMO_MAX_MOVEMENT_DATE
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth, SMO_MOVEMENT_QUANTITY, 0) )
                                                                                                                                           SMO_GOOD_QUANTITY_01
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth, SMO_MOVEMENT_PRICE, 0) )
                                                                                                                                              SMO_GOOD_PRICE_01
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 1, SMO_MOVEMENT_QUANTITY, 0) )
                                                                                                                                           SMO_GOOD_QUANTITY_02
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 1, SMO_MOVEMENT_PRICE, 0) )
                                                                                                                                              SMO_GOOD_PRICE_02
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 2, SMO_MOVEMENT_QUANTITY, 0) )
                                                                                                                                           SMO_GOOD_QUANTITY_03
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 2, SMO_MOVEMENT_PRICE, 0) )
                                                                                                                                              SMO_GOOD_PRICE_03
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 3, SMO_MOVEMENT_QUANTITY, 0) )
                                                                                                                                           SMO_GOOD_QUANTITY_04
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 3, SMO_MOVEMENT_PRICE, 0) )
                                                                                                                                              SMO_GOOD_PRICE_04
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 4, SMO_MOVEMENT_QUANTITY, 0) )
                                                                                                                                           SMO_GOOD_QUANTITY_05
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 4, SMO_MOVEMENT_PRICE, 0) )
                                                                                                                                              SMO_GOOD_PRICE_05
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 5, SMO_MOVEMENT_QUANTITY, 0) )
                                                                                                                                           SMO_GOOD_QUANTITY_06
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 5, SMO_MOVEMENT_PRICE, 0) )
                                                                                                                                              SMO_GOOD_PRICE_06
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 6, SMO_MOVEMENT_QUANTITY, 0) )
                                                                                                                                           SMO_GOOD_QUANTITY_07
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 6, SMO_MOVEMENT_PRICE, 0) )
                                                                                                                                              SMO_GOOD_PRICE_07
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 7, SMO_MOVEMENT_QUANTITY, 0) )
                                                                                                                                           SMO_GOOD_QUANTITY_08
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 7, SMO_MOVEMENT_PRICE, 0) )
                                                                                                                                              SMO_GOOD_PRICE_08
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 8, SMO_MOVEMENT_QUANTITY, 0) )
                                                                                                                                           SMO_GOOD_QUANTITY_09
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 8, SMO_MOVEMENT_PRICE, 0) )
                                                                                                                                              SMO_GOOD_PRICE_09
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 9, SMO_MOVEMENT_QUANTITY, 0) )
                                                                                                                                           SMO_GOOD_QUANTITY_10
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 9, SMO_MOVEMENT_PRICE, 0) )
                                                                                                                                              SMO_GOOD_PRICE_10
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 10, SMO_MOVEMENT_QUANTITY, 0) )
                                                                                                                                           SMO_GOOD_QUANTITY_11
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 10, SMO_MOVEMENT_PRICE, 0) )
                                                                                                                                              SMO_GOOD_PRICE_11
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 11, SMO_MOVEMENT_QUANTITY, 0) )
                                                                                                                                           SMO_GOOD_QUANTITY_12
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 11, SMO_MOVEMENT_PRICE, 0) )
                                                                                                                                              SMO_GOOD_PRICE_12
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 12, SMO_MOVEMENT_QUANTITY, 0) )
                                                                                                                                           SMO_GOOD_QUANTITY_13
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 12, SMO_MOVEMENT_PRICE, 0) )
                                                                                                                                              SMO_GOOD_PRICE_13
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 13, SMO_MOVEMENT_QUANTITY, 0) )
                                                                                                                                           SMO_GOOD_QUANTITY_14
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 13, SMO_MOVEMENT_PRICE, 0) )
                                                                                                                                              SMO_GOOD_PRICE_14
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 14, SMO_MOVEMENT_QUANTITY, 0) )
                                                                                                                                           SMO_GOOD_QUANTITY_15
                               , sum(decode(STM_STOCK_ANALYSE.getInternalMonthNo(aCrDateRef, SMO.SMO_MOVEMENT_DATE), -aCrNbMonth + 14, SMO_MOVEMENT_PRICE, 0) )
                                                                                                                                              SMO_GOOD_PRICE_15
                               , sum(decode(sign(SMO_MOVEMENT_DATE - aCrHalfDate), -1, SMO_MOVEMENT_QUANTITY, 0) ) SMO_GOOD_QUANTITY_H1
                               , sum(decode(sign(SMO_MOVEMENT_DATE - aCrHalfDate), 0, SMO_MOVEMENT_QUANTITY, 1, SMO_MOVEMENT_QUANTITY, 0) )
                                                                                                                                           SMO_GOOD_QUANTITY_H2
                               , sum(decode(sign(SMO_MOVEMENT_DATE - aCrHalfDate), -1, SMO_MOVEMENT_PRICE, 0) ) SMO_GOOD_PRICE_H1
                               , sum(decode(sign(SMO_MOVEMENT_DATE - aCrHalfDate), 0, SMO_MOVEMENT_PRICE, 1, SMO_MOVEMENT_PRICE, 0) ) SMO_GOOD_PRICE_H2
                            from STM_ABC_STOCK_ANALYSE_ELEM TMP1
                               , STM_ABC_STOCK_ANALYSE_ELEM TMP2
                               , STM_ABC_STOCK_ANALYSE_ELEM TMP3
                               , STM_STOCK_MOVEMENT SMO
                           where TMP1.ABE_ID = SMO.GCO_GOOD_ID
                             and TMP1.ABE_TABLENAME = 'GOO'
                             and TMP1.STM_ABC_STOCK_ANALYSE_ID = aCrAnalyseId
                             and TMP2.ABE_ID = SMO.STM_MOVEMENT_KIND_ID
                             and TMP2.ABE_TABLENAME = 'MOK'
                             and TMP2.STM_ABC_STOCK_ANALYSE_ID = aCrAnalyseId
                             and SMO.SMO_MOVEMENT_DATE between add_months(trunc(aCrDateRef), -aCrNbMonth) + 1 and trunc(aCrDateRef)
                             and TMP3.ABE_TABLENAME = 'STO'
                             and TMP3.STM_ABC_STOCK_ANALYSE_ID = aCrAnalyseId
                             and TMP3.ABE_ID = SMO.STM_STOCK_ID
                        group by SMO.GCO_GOOD_ID) ) ANA
             , (select ABE_ID GCO_GOOD_ID
                     , GOO.GOO_MAJOR_REFERENCE
                     , PDT.C_SUPPLY_MODE
                  from STM_ABC_STOCK_ANALYSE_ELEM TMP
                     , GCO_GOOD GOO
                     , GCO_PRODUCT PDT
                 where TMP.ABE_TABLENAME = 'GOO'
                   and TMP.ABE_ID = GOO.GCO_GOOD_ID
                   and TMP.STM_ABC_STOCK_ANALYSE_ID = aCrAnalyseId
                   and PDT.GCO_GOOD_ID = GOO.GCO_GOOD_ID
                   and PDT.C_SUPPLY_MODE <> '3') TMP   -- exclusion des articles PRP
         where ANA.id(+) = TMP.GCO_GOOD_ID
      order by case
                 when 3 in(2, 4) then SMO_GOOD_QUANTITY
                 when 3 in(1, 3) then SMO_GOOD_QUANTITY * STM_STOCK_ANALYSE.getCostPrice(GCO_GOOD_ID)
               end desc nulls last
             , TMP.GOO_MAJOR_REFERENCE;

    type tTblGoodValues is table of crGoodValues%rowtype
      index by pls_integer;

    cursor crStockQuantities(aCrAnalyseId in number, aCrGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    is
      select sum(SPO_AVAILABLE_QUANTITY) SPO_AVAILABLE_QUANTITY
           , sum(SPO_AVAILABLE_QUANTITY - SPO_ASSIGN_QUANTITY) SPO_FREE_QUANTITY
        from STM_STOCK_POSITION SPO
           , STM_ABC_STOCK_ANALYSE_ELEM TMP
       where SPO.GCO_GOOD_ID = aCrGoodId
         and TMP.ABE_TABLENAME = 'STO'
         and TMP.STM_ABC_STOCK_ANALYSE_ID = aCrAnalyseId
         and SPO.STM_STOCK_ID = TMP.ABE_ID;

    vTblGoodValues    tTblGoodValues;
    vTotal            STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type   := 0;
    vCumulated        STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type   := 0;
    vCumulatedPercent number(5, 2);
    vAvgTrendQuantity number;
    vCurrentMode      varchar2(1)                                     := 'A';
    vDateRef          date;
    vStartDate        date;
    vEndDate          date;
    vHalfDate         date;
    vSupplyDelay      GCO_COMPL_DATA_PURCHASE.CPU_SUPPLY_DELAY%type;
    vStockList        clob;
  begin
    -- contrôle que le nombre de mois passé en paramètre soit cohérent
    if not(nvl(aNbMonth, 0) between 1 and cMAX_MONTH) then
      raise_application_error
                    (-20000
                   , replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Analyse ABC : le nombre de mois de l''analyse doit être compris entre 1 et [MAX_MONTH]!')
                           , '[MAX_MONTH]'
                           , cMAX_MONTH
                            )
                    );
    end if;

    -- Calcul de la date de référence
    if (aAllowPartial = 1) then
      if aWindowMode = 1 then
        vDateRef  := trunc(aDateRef);
      else
        vDateRef  := trunc(last_day(aDateRef) );
      end if;
    else
      if aWindowMode = 1 then
        vDateRef  := least(trunc(sysdate - 1), aDateRef);
      else
        vDateRef  := least(trunc(add_months(last_day(sysdate), -1) ), last_day(aDateRef) );
      end if;
    end if;

    begin
      insert into STM_ABC_STOCK_ANALYSE
                  (STM_ABC_STOCK_ANALYSE_ID
                 , ABH_WORDING
                 , ABH_REF_DATE
                 , ABH_START_DATE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (aAnalyseId
                 , aWording
                 , vDateRef
                 , sysdate
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    exception
      when dup_val_on_index then
        update STM_ABC_STOCK_ANALYSE
           set ABH_START_DATE = sysdate
             , ABH_REF_DATE = vDateRef
         where STM_ABC_STOCK_ANALYSE_ID = aAnalyseId;
    end;

    vHalfDate   := vDateRef - trunc( (vDateRef - add_months(vDateRef, -aNbMonth) + 1) / 2);
    vStartDate  := add_months(vDateRef, -aNbMonth) + 1;
    vEndDate    := vDateRef;

    -- ouverture du curseur et stockage de l'analyse dans une table PLSQL
    open crGoodValues(aAnalyseId, aMode, aNbMonth, vDateRef, vHalfDate);

    fetch crGoodValues
    bulk collect into vTblGoodValues;

    close crGoodValues;

    if vTblGoodValues.count > 0 then
      -- calcul du total
      for i in vTblGoodValues.first .. vTblGoodValues.last loop
        vTotal  := vTotal + nvl(vTblGoodValues(i).SMO_GOOD_VALUE, 0);
      end loop;

      -- exclusion des qté à 0
      if vTotal <> 0 then   -- avoid divide by zero
        -- traitement des stats ABC
        for i in vTblGoodValues.first .. vTblGoodValues.last loop
          declare
            vTplABC STM_ABC_STOCK_ANALYSE_DET%rowtype;
          begin
            -- id de la table de sortie
            vTplAbc.STM_ABC_STOCK_ANALYSE_ID       := aAnalyseId;
            -- ne pas présélectionner les enregistrement
            vTplAbc.ABC_SELECT                     := 0;
            -- bien courant
            vTplAbc.GCO_GOOD_ID                    := vTblGoodValues(i).GCO_GOOD_ID;
            -- init des flags
            vTplAbc.ABC_TURNING_RATE_ERROR         := 0;
            vTplAbc.ABC_TRIGGER_POINT_BASIS_ERROR  := 0;
            vTplAbc.ABC_SUPPLY_DELAY_ERROR         := 0;
            vTplAbc.ABC_TRG_PT_COVER_RATE_ERROR    := 0;
            vTplAbc.ABC_TRIGGER_POINT_BASIS_ERROR  := 0;
            vTplAbc.ABC_QUANTITY_MIN_DEV_ERROR     := 0;
            vTplAbc.ABC_TRIGGER_POINT_DEV_ERROR    := 0;
            vTplAbc.ABC_EXTREME_COVERING_ERROR     := 0;
            -- Période de l'interrogation
            vTplAbc.ABC_PERIOD                     := to_char(vStartDate, 'DD.MM.YYYY') || ' - ' || to_char(vEndDate, 'DD.MM.YYYY');

            if aMode in(1, 2) then
              -- Informations statiques
              getGoodInfos(vTplAbc.GCO_GOOD_ID
                         , vTplAbc.GOO_MAJOR_REFERENCE
                         , vTplAbc.DES_SHORT_DESCRIPTION
                         , vTplAbc.C_SUPPLY_MODE
                         , vTplAbc.CST_QUANTITY_MIN
                         , vTplAbc.CST_QUANTITY_MAX
                         , vTplAbc.CST_TRIGGER_POINT
                         , vTplAbc.CPU_ECONOMICAL_QUANTITY
                         , vTplAbc.CMA_LOT_QUANTITY
                         , vSupplyDelay
                          );
            end if;

            select init_id_seq.nextval
              into vTplAbc.STM_ABC_STOCK_ANALYSE_DET_ID
              from dual;

            if vTblGoodValues(i).SMO_GOOD_VALUE is not null then
              -- code ABC
              vTplAbc.ABC_CODE               := vCurrentMode;
              -- valeur cumulée pour stat ABC
              vCumulated                     := vCumulated + vTblGoodValues(i).SMO_GOOD_VALUE;
              -- pourcentage cumulé pour stat ABC
              vCumulatedPercent              := vCumulated * 100 / vTotal;
              -- valeur de comparaison ABC
              vTplAbc.ABC_VALUE              := vTblGoodValues(i).SMO_GOOD_VALUE;
              -- pourcentage par rapport au total (non cumulé)
              vTplAbc.ABC_PERCENT            := vTblGoodValues(i).SMO_GOOD_VALUE * 100 / vTotal;
              -- valeurs cumulées
              vTplAbc.ABC_CUMULATED_VALUES   := vCumulated;
              -- pourcentage cumulé
              vTplAbc.ABC_CUMULATED_PERCENT  := vCumulatedPercent;
              -- Total,  toujours la même valeur
              vTplAbc.ABC_TOTAL              := vTotal;

              -- clef de répartition ABC (pour le record suivant)
              case
                when vCumulatedPercent > aThresholdC + aThresholdB then
                  vCurrentMode  := 'C';
                when vCumulatedPercent > aThresholdB then
                  vCurrentMode  := 'B';
                else
                  null;
              end case;
            end if;

            if aMode in(1, 2) then
              if vTblGoodValues(i).SMO_GOOD_VALUE is not null then
                -- nombre de mois entre le premier et le dernier mouvements trouvés pour le bien courant
                vTplAbc.ABC_NB_MONTH                := vTblGoodValues(i).SMO_NB_MONTH;
                vTplAbc.ABC_FIRST_MOVEMENT_DATE     := vTblGoodValues(i).SMO_MIN_MOVEMENT_DATE;
                vTplAbc.ABC_LAST_MOVEMENT_DATE      := vTblGoodValues(i).SMO_MAX_MOVEMENT_DATE;

                -- Liste des stocks dans une variable texte
                select TableToCharList(cursor(select ABE_ID
                                                from STM_ABC_STOCK_ANALYSE_ELEM
                                               where ABE_TABLENAME = 'STO'
                                                 and STM_ABC_STOCK_ANALYSE_ID = aAnalyseId) )
                  into vStockList
                  from dual;

                -- données mensuelles moyennes
                vTplAbc.ABC_MONTH_AVERAGE_QUANTITY  := vTblGoodValues(i).SMO_GOOD_QUANTITY / aNbMonth;
                vTplAbc.ABC_MONTH_AVERAGE_PRICE     := vTblGoodValues(i).SMO_GOOD_PRICE / aNbMonth;
                -- Quantité en stock au début de la période
                vTplAbc.ABC_START_STOCK_QUANTITY    := pGetStockAtDate(vTplAbc.GCO_GOOD_ID, vStartDate, vStockList);
                -- Quantité en stock au début de la période
                vTplAbc.ABC_END_STOCK_QUANTITY      := pGetStockAtDate(vTplAbc.GCO_GOOD_ID, vEndDate, vStockList);

                -- taux de rotation
                if (vTplAbc.ABC_END_STOCK_QUANTITY + vTplAbc.ABC_START_STOCK_QUANTITY) <> 0 then
                  vTplAbc.ABC_TURNOVER_RATIO  := vTblGoodValues(i).SMO_GOOD_QUANTITY /( (vTplAbc.ABC_END_STOCK_QUANTITY + vTplAbc.ABC_START_STOCK_QUANTITY) / 2);

                  if vTplAbc.ABC_TURNOVER_RATIO < aMinTurnoverRatio then
                    vTplAbc.ABC_TURNING_RATE_ERROR  := 1;
                  else
                    vTplAbc.ABC_TURNING_RATE_ERROR  := 0;
                  end if;
                end if;

                vTplAbc.ABC_CONSUMED_QUANTITY       := vTblGoodValues(i).SMO_GOOD_QUANTITY;
                -- Données par mois
                vTplAbc.ABC_PERIOD_01               := getPeriodDescr(vDateRef, -aNbMonth);
                vTplAbc.ABC_MONTH_QUANTITY_01       := vTblGoodValues(i).SMO_GOOD_QUANTITY_01;
                vTplAbc.ABC_MONTH_PRICE_01          := vTblGoodValues(i).SMO_GOOD_PRICE_01;
                vTplAbc.ABC_PERIOD_02               := getPeriodDescr(vDateRef, -aNbMonth + 1);
                vTplAbc.ABC_MONTH_QUANTITY_02       := vTblGoodValues(i).SMO_GOOD_QUANTITY_02;
                vTplAbc.ABC_MONTH_PRICE_02          := vTblGoodValues(i).SMO_GOOD_PRICE_02;
                vTplAbc.ABC_PERIOD_03               := getPeriodDescr(vDateRef, -aNbMonth + 2);
                vTplAbc.ABC_MONTH_QUANTITY_03       := vTblGoodValues(i).SMO_GOOD_QUANTITY_03;
                vTplAbc.ABC_MONTH_PRICE_03          := vTblGoodValues(i).SMO_GOOD_PRICE_03;
                vTplAbc.ABC_PERIOD_04               := getPeriodDescr(vDateRef, -aNbMonth + 3);
                vTplAbc.ABC_MONTH_QUANTITY_04       := vTblGoodValues(i).SMO_GOOD_QUANTITY_04;
                vTplAbc.ABC_MONTH_PRICE_04          := vTblGoodValues(i).SMO_GOOD_PRICE_04;
                vTplAbc.ABC_PERIOD_05               := getPeriodDescr(vDateRef, -aNbMonth + 4);
                vTplAbc.ABC_MONTH_QUANTITY_05       := vTblGoodValues(i).SMO_GOOD_QUANTITY_05;
                vTplAbc.ABC_MONTH_PRICE_05          := vTblGoodValues(i).SMO_GOOD_PRICE_05;
                vTplAbc.ABC_PERIOD_06               := getPeriodDescr(vDateRef, -aNbMonth + 5);
                vTplAbc.ABC_MONTH_QUANTITY_06       := vTblGoodValues(i).SMO_GOOD_QUANTITY_06;
                vTplAbc.ABC_MONTH_PRICE_06          := vTblGoodValues(i).SMO_GOOD_PRICE_06;
                vTplAbc.ABC_PERIOD_07               := getPeriodDescr(vDateRef, -aNbMonth + 6);
                vTplAbc.ABC_MONTH_QUANTITY_07       := vTblGoodValues(i).SMO_GOOD_QUANTITY_07;
                vTplAbc.ABC_MONTH_PRICE_07          := vTblGoodValues(i).SMO_GOOD_PRICE_07;
                vTplAbc.ABC_PERIOD_08               := getPeriodDescr(vDateRef, -aNbMonth + 7);
                vTplAbc.ABC_MONTH_QUANTITY_08       := vTblGoodValues(i).SMO_GOOD_QUANTITY_08;
                vTplAbc.ABC_MONTH_PRICE_08          := vTblGoodValues(i).SMO_GOOD_PRICE_08;
                vTplAbc.ABC_PERIOD_09               := getPeriodDescr(vDateRef, -aNbMonth + 8);
                vTplAbc.ABC_MONTH_QUANTITY_09       := vTblGoodValues(i).SMO_GOOD_QUANTITY_09;
                vTplAbc.ABC_MONTH_PRICE_09          := vTblGoodValues(i).SMO_GOOD_PRICE_09;
                vTplAbc.ABC_PERIOD_10               := getPeriodDescr(vDateRef, -aNbMonth + 9);
                vTplAbc.ABC_MONTH_QUANTITY_10       := vTblGoodValues(i).SMO_GOOD_QUANTITY_10;
                vTplAbc.ABC_MONTH_PRICE_10          := vTblGoodValues(i).SMO_GOOD_PRICE_10;
                vTplAbc.ABC_PERIOD_11               := getPeriodDescr(vDateRef, -aNbMonth + 10);
                vTplAbc.ABC_MONTH_QUANTITY_11       := vTblGoodValues(i).SMO_GOOD_QUANTITY_11;
                vTplAbc.ABC_MONTH_PRICE_11          := vTblGoodValues(i).SMO_GOOD_PRICE_11;
                vTplAbc.ABC_PERIOD_12               := getPeriodDescr(vDateRef, -aNbMonth + 11);
                vTplAbc.ABC_MONTH_QUANTITY_12       := vTblGoodValues(i).SMO_GOOD_QUANTITY_12;
                vTplAbc.ABC_MONTH_PRICE_12          := vTblGoodValues(i).SMO_GOOD_PRICE_12;
                vTplAbc.ABC_PERIOD_13               := getPeriodDescr(vDateRef, -aNbMonth + 12);
                vTplAbc.ABC_MONTH_QUANTITY_13       := vTblGoodValues(i).SMO_GOOD_QUANTITY_13;
                vTplAbc.ABC_MONTH_PRICE_13          := vTblGoodValues(i).SMO_GOOD_PRICE_13;
                vTplAbc.ABC_PERIOD_14               := getPeriodDescr(vDateRef, -aNbMonth + 13);
                vTplAbc.ABC_MONTH_QUANTITY_14       := vTblGoodValues(i).SMO_GOOD_QUANTITY_14;
                vTplAbc.ABC_MONTH_PRICE_14          := vTblGoodValues(i).SMO_GOOD_PRICE_14;
                vTplAbc.ABC_PERIOD_15               := getPeriodDescr(vDateRef, -aNbMonth + 14);
                vTplAbc.ABC_MONTH_QUANTITY_15       := vTblGoodValues(i).SMO_GOOD_QUANTITY_15;
                vTplAbc.ABC_MONTH_PRICE_15          := vTblGoodValues(i).SMO_GOOD_PRICE_15;
                -- Plus grande valeur mensuelle
                vTplAbc.ABC_MAX_MONTH_VALUE         :=
                  greatest(vTblGoodValues(i).SMO_GOOD_QUANTITY_15
                         , vTblGoodValues(i).SMO_GOOD_QUANTITY_14
                         , vTblGoodValues(i).SMO_GOOD_QUANTITY_13
                         , vTblGoodValues(i).SMO_GOOD_QUANTITY_12
                         , vTblGoodValues(i).SMO_GOOD_QUANTITY_11
                         , vTblGoodValues(i).SMO_GOOD_QUANTITY_10
                         , vTblGoodValues(i).SMO_GOOD_QUANTITY_09
                         , vTblGoodValues(i).SMO_GOOD_QUANTITY_08
                         , vTblGoodValues(i).SMO_GOOD_QUANTITY_07
                         , vTblGoodValues(i).SMO_GOOD_QUANTITY_06
                         , vTblGoodValues(i).SMO_GOOD_QUANTITY_05
                         , vTblGoodValues(i).SMO_GOOD_QUANTITY_04
                         , vTblGoodValues(i).SMO_GOOD_QUANTITY_03
                         , vTblGoodValues(i).SMO_GOOD_QUANTITY_02
                         , vTblGoodValues(i).SMO_GOOD_QUANTITY_01
                          );

                -- Ecart-type de chaque période et calcul de l'écart-type total absolu
                if aNbMonth > 0 then
                  vTplAbc.ABC_STD_DEV_01   := vTblGoodValues(i).SMO_GOOD_QUANTITY_01 - vTplAbc.ABC_MONTH_AVERAGE_QUANTITY;
                  vTplAbc.ABC_TOT_STD_DEV  := vTplAbc.ABC_TOT_STD_DEV + vTplAbc.ABC_STD_DEV_01;
                end if;

                if aNbMonth > 1 then
                  vTplAbc.ABC_STD_DEV_02   := vTblGoodValues(i).SMO_GOOD_QUANTITY_02 - vTplAbc.ABC_MONTH_AVERAGE_QUANTITY;
                  vTplAbc.ABC_TOT_STD_DEV  := vTplAbc.ABC_TOT_STD_DEV + abs(vTplAbc.ABC_STD_DEV_02);
                end if;

                if aNbMonth > 2 then
                  vTplAbc.ABC_STD_DEV_03   := vTblGoodValues(i).SMO_GOOD_QUANTITY_03 - vTplAbc.ABC_MONTH_AVERAGE_QUANTITY;
                  vTplAbc.ABC_TOT_STD_DEV  := vTplAbc.ABC_TOT_STD_DEV + abs(vTplAbc.ABC_STD_DEV_03);
                end if;

                if aNbMonth > 3 then
                  vTplAbc.ABC_STD_DEV_04   := vTblGoodValues(i).SMO_GOOD_QUANTITY_04 - vTplAbc.ABC_MONTH_AVERAGE_QUANTITY;
                  vTplAbc.ABC_TOT_STD_DEV  := vTplAbc.ABC_TOT_STD_DEV + abs(vTplAbc.ABC_STD_DEV_04);
                end if;

                if aNbMonth > 4 then
                  vTplAbc.ABC_STD_DEV_05   := vTblGoodValues(i).SMO_GOOD_QUANTITY_05 - vTplAbc.ABC_MONTH_AVERAGE_QUANTITY;
                  vTplAbc.ABC_TOT_STD_DEV  := vTplAbc.ABC_TOT_STD_DEV + abs(vTplAbc.ABC_STD_DEV_05);
                end if;

                if aNbMonth > 5 then
                  vTplAbc.ABC_STD_DEV_06   := vTblGoodValues(i).SMO_GOOD_QUANTITY_06 - vTplAbc.ABC_MONTH_AVERAGE_QUANTITY;
                  vTplAbc.ABC_TOT_STD_DEV  := vTplAbc.ABC_TOT_STD_DEV + abs(vTplAbc.ABC_STD_DEV_06);
                end if;

                if aNbMonth > 6 then
                  vTplAbc.ABC_STD_DEV_07   := vTblGoodValues(i).SMO_GOOD_QUANTITY_07 - vTplAbc.ABC_MONTH_AVERAGE_QUANTITY;
                  vTplAbc.ABC_TOT_STD_DEV  := vTplAbc.ABC_TOT_STD_DEV + abs(vTplAbc.ABC_STD_DEV_07);
                end if;

                if aNbMonth > 7 then
                  vTplAbc.ABC_STD_DEV_08   := vTblGoodValues(i).SMO_GOOD_QUANTITY_08 - vTplAbc.ABC_MONTH_AVERAGE_QUANTITY;
                  vTplAbc.ABC_TOT_STD_DEV  := vTplAbc.ABC_TOT_STD_DEV + abs(vTplAbc.ABC_STD_DEV_08);
                end if;

                if aNbMonth > 8 then
                  vTplAbc.ABC_STD_DEV_09   := vTblGoodValues(i).SMO_GOOD_QUANTITY_09 - vTplAbc.ABC_MONTH_AVERAGE_QUANTITY;
                  vTplAbc.ABC_TOT_STD_DEV  := vTplAbc.ABC_TOT_STD_DEV + abs(vTplAbc.ABC_STD_DEV_09);
                end if;

                if aNbMonth > 9 then
                  vTplAbc.ABC_STD_DEV_10   := vTblGoodValues(i).SMO_GOOD_QUANTITY_10 - vTplAbc.ABC_MONTH_AVERAGE_QUANTITY;
                  vTplAbc.ABC_TOT_STD_DEV  := vTplAbc.ABC_TOT_STD_DEV + abs(vTplAbc.ABC_STD_DEV_10);
                end if;

                if aNbMonth > 10 then
                  vTplAbc.ABC_STD_DEV_11   := vTblGoodValues(i).SMO_GOOD_QUANTITY_11 - vTplAbc.ABC_MONTH_AVERAGE_QUANTITY;
                  vTplAbc.ABC_TOT_STD_DEV  := vTplAbc.ABC_TOT_STD_DEV + abs(vTplAbc.ABC_STD_DEV_11);
                end if;

                if aNbMonth > 11 then
                  vTplAbc.ABC_STD_DEV_12   := vTblGoodValues(i).SMO_GOOD_QUANTITY_12 - vTplAbc.ABC_MONTH_AVERAGE_QUANTITY;
                  vTplAbc.ABC_TOT_STD_DEV  := vTplAbc.ABC_TOT_STD_DEV + abs(vTplAbc.ABC_STD_DEV_12);
                end if;

                if aNbMonth > 12 then
                  vTplAbc.ABC_STD_DEV_13   := vTblGoodValues(i).SMO_GOOD_QUANTITY_13 - vTplAbc.ABC_MONTH_AVERAGE_QUANTITY;
                  vTplAbc.ABC_TOT_STD_DEV  := vTplAbc.ABC_TOT_STD_DEV + abs(vTplAbc.ABC_STD_DEV_13);
                end if;

                if aNbMonth > 13 then
                  vTplAbc.ABC_STD_DEV_14   := vTblGoodValues(i).SMO_GOOD_QUANTITY_14 - vTplAbc.ABC_MONTH_AVERAGE_QUANTITY;
                  vTplAbc.ABC_TOT_STD_DEV  := vTplAbc.ABC_TOT_STD_DEV + abs(vTplAbc.ABC_STD_DEV_14);
                end if;

                if aNbMonth > 14 then
                  vTplAbc.ABC_STD_DEV_15   := vTblGoodValues(i).SMO_GOOD_QUANTITY_15 - vTplAbc.ABC_MONTH_AVERAGE_QUANTITY;
                  vTplAbc.ABC_TOT_STD_DEV  := vTplAbc.ABC_TOT_STD_DEV + abs(vTplAbc.ABC_STD_DEV_15);
                end if;

                -- écart-type mensuel moyen
                vTplAbc.ABC_MONTH_AVG_STD_DEV       := vTplAbc.ABC_TOT_STD_DEV / aNbMonth;
                -- calcul valeur des 2 moitiés de l'interro
                vTplAbc.ABC_VALUE_H1                := vTblGoodValues(i).SMO_GOOD_VALUE_H1;
                vTplAbc.ABC_VALUE_H2                := vTblGoodValues(i).SMO_GOOD_VALUE_H2;

                -- calcul de la variation entre les 2 moitiés
                if vTblGoodValues(i).SMO_GOOD_VALUE_H1 + vTblGoodValues(i).SMO_GOOD_VALUE_H2 <> 0 then
                  vAvgTrendQuantity  := (vTblGoodValues(i).SMO_GOOD_VALUE_H1 + vTblGoodValues(i).SMO_GOOD_VALUE_H2) / 2;

                  -- Tendance
                  if vTblGoodValues(i).SMO_GOOD_VALUE_H1 < vAvgTrendQuantity *( (100 - aCompPercentMargin) / 100) then
                    vTplAbc.ABC_TREND  := '+';
                  elsif vTblGoodValues(i).SMO_GOOD_VALUE_H1 > vAvgTrendQuantity *( (100 + aCompPercentMargin) / 100) then
                    vTplAbc.ABC_TREND  := '-';
                  else
                    vTplAbc.ABC_TREND  := '=';
                  end if;
                else
                  vTplAbc.ABC_TREND  := '=';
                end if;

                -- prix de revient selon mode de gestion
                vTplAbc.ABC_UNIT_PRICE              := getCostPrice(vTplAbc.GCO_GOOD_ID);
                vTplAbc.ABC_THEORETICAL_QUANTITY    := nvl(nvl(vTplAbc.CPU_ECONOMICAL_QUANTITY, vTplAbc.CMA_LOT_QUANTITY), vTplAbc.ABC_MONTH_AVERAGE_QUANTITY);

                -- Délai d'approvisionnement calculé
                if vTplAbc.C_SUPPLY_MODE = cSupplyModePurchased then
                  -- Article acheté
                  declare
                    vCorrDelay number;
                  begin
                    getPurchaseSupplyDelayCorr(vTplAbc.GCO_GOOD_ID, vSupplyDelay, vStartDate, vEndDate, vTplAbc.ABC_AVG_SUPPLY_QUANTITY, vCorrDelay);
                    vTplAbc.ABC_SUPPLY_DELAY       := vSupplyDelay / aMonthWorkingDays;
                    vTplAbc.ABC_CALC_SUPPLY_DELAY  := (vSupplyDelay + vCorrDelay) / aMonthWorkingDays;
                  end;
                elsif vTplAbc.C_SUPPLY_MODE = cSupplyModeManufactured then
                  -- Article fabriqué
                  FAL_PLANIF.GetRealManufacturingDuration(vTplAbc.GCO_GOOD_ID
                                                        , vStartDate
                                                        , vEndDate
                                                        , vTplAbc.ABC_AVG_SUPPLY_QUANTITY
                                                        , vTplAbc.ABC_CALC_SUPPLY_DELAY
                                                         );
                  vTplAbc.ABC_CALC_SUPPLY_DELAY  := vTplAbc.ABC_CALC_SUPPLY_DELAY / aMonthWorkingDays;
                  vTplAbc.ABC_SUPPLY_DELAY       :=
                                  FAL_PLANIF.GetPrevManufacturingDuration(vTplAbc.GCO_GOOD_ID, least(vTplAbc.ABC_THEORETICAL_QUANTITY, 100) )
                                  / aMonthWorkingDays;
                end if;

                -- préinitialisatoin de la nouvelle valeur selon delai calculé
                vTplAbc.ABC_NEW_SUPPLY_DELAY        := vTplAbc.ABC_CALC_SUPPLY_DELAY;

                -- contrôle des délais
                if     not(    nvl(vTplAbc.ABC_SUPPLY_DELAY, 0) = 0
                           and nvl(vTplAbc.ABC_CALC_SUPPLY_DELAY, 0) = 0)
                   and not(nvl(vTplAbc.ABC_CALC_SUPPLY_DELAY, 0) * 100 between nvl(vTplAbc.ABC_SUPPLY_DELAY, 0) *(100 - aSupplyDelayPercentMargin)
                                                                           and nvl(vTplAbc.ABC_SUPPLY_DELAY, 0) *(100 + aSupplyDelayPercentMargin)
                          ) then
                  vTplAbc.ABC_SUPPLY_DELAY_ERROR  := 1;
                else
                  vTplAbc.ABC_SUPPLY_DELAY_ERROR  := 0;
                end if;

                -- Taux de couverture
                if vTplAbc.ABC_MONTH_AVERAGE_QUANTITY <> 0 then
                  vTplAbc.ABC_QUANTITY_MIN_COVER_RATE    := vTplAbc.CST_QUANTITY_MIN / vTplAbc.ABC_MONTH_AVERAGE_QUANTITY;
                  vTplAbc.ABC_TRIGGER_POINT_COVER_RATE   := vTplAbc.CST_TRIGGER_POINT / vTplAbc.ABC_MONTH_AVERAGE_QUANTITY;
                  vTplAbc.ABC_ECONOMICAL_QTY_COVER_RATE  := vTplAbc.CPU_ECONOMICAL_QUANTITY / vTplAbc.ABC_MONTH_AVERAGE_QUANTITY;
                end if;

                -- contrôle du taux de couverture
                if vTplAbc.ABC_TRIGGER_POINT_COVER_RATE < vTplAbc.ABC_SUPPLY_DELAY then
                  vTplAbc.ABC_TRG_PT_COVER_RATE_ERROR  := 1;
                else
                  vTplAbc.ABC_TRG_PT_COVER_RATE_ERROR  := 0;
                end if;

                -- contrôle point de commande
                if     vTplAbc.CST_TRIGGER_POINT is not null
                   and vTplAbc.CPU_ECONOMICAL_QUANTITY is null
                   and vTplAbc.CST_QUANTITY_MAX is null then
                  vTplAbc.ABC_TRIGGER_POINT_BASIS_ERROR  := 1;
                else
                  vTplAbc.ABC_TRIGGER_POINT_BASIS_ERROR  := 0;
                end if;

                -- Stock Mini Calculé (Tx service 95%)
                vTplAbc.ABC_CALC_QUANTITY_MIN_95    := vTplAbc.ABC_MONTH_AVG_STD_DEV * 2.06 * sqrt(vTplAbc.ABC_CALC_SUPPLY_DELAY);
                vTplAbc.ABC_CALC_TRIGGER_POINT_95   := (vTplAbc.ABC_CALC_SUPPLY_DELAY * vTplAbc.ABC_MONTH_AVERAGE_QUANTITY) + vTplAbc.ABC_CALC_QUANTITY_MIN_95;
                -- Stock Mini Calculé (Tx service 99%)
                vTplAbc.ABC_CALC_QUANTITY_MIN_99    := vTplAbc.ABC_MONTH_AVG_STD_DEV * 2.91 * sqrt(vTplAbc.ABC_CALC_SUPPLY_DELAY);
                vTplAbc.ABC_NEW_TRIGGER_POINT       := vTplAbc.ABC_CALC_TRIGGER_POINT_95;
                vTplAbc.ABC_CALC_TRIGGER_POINT_99   := (vTplAbc.ABC_CALC_SUPPLY_DELAY * vTplAbc.ABC_MONTH_AVERAGE_QUANTITY) + vTplAbc.ABC_CALC_QUANTITY_MIN_99;
                -- préinitialisatoin de la nouvelle valeur selon quantité minimum calculée pour un taux de service de 95%
                vTplAbc.ABC_NEW_QUANTITY_MIN        := vTplAbc.ABC_CALC_QUANTITY_MIN_95;
                -- préinitialisatoin de la nouvelle valeur selon point de commande calculée pour un taux de service de 95%
                getSupplyQties(vTplAbc.GCO_GOOD_ID, vTplAbc.ABC_FREE_SUPPLY_QUANTITY /*, vTplAbc.ABC_SUPPLY_QUANTITY*/);
                vTplAbc.ABC_FREE_NEED_QUANTITY      := getFreeNeedQty(vTplAbc.GCO_GOOD_ID);
                -- préinitialisatoin de la nouvelle valeur selon la plus grande valeur entre la qté min et la qté max
                vTplAbc.ABC_NEW_QUANTITY_MAX        := greatest(vTplAbc.ABC_NEW_QUANTITY_MIN, vTplAbc.CST_QUANTITY_MAX);

                -- Quantités stock
                for tplStockQuantities in crStockQuantities(aAnalyseId, vTplAbc.GCO_GOOD_ID) loop
                  vTplAbc.SPO_AVAILABLE_QUANTITY  := tplStockQuantities.SPO_AVAILABLE_QUANTITY;
                  vTplAbc.ABC_FREE_QUANTITY       := tplStockQuantities.SPO_FREE_QUANTITY - getFreeNeedQty(vTplAbc.GCO_GOOD_ID);
                end loop;

                -- contrôle du stock mini (taux de couverture 95%)
                if     not(    nvl(vTplAbc.CST_QUANTITY_MIN, 0) = 0
                           and nvl(vTplAbc.ABC_CALC_QUANTITY_MIN_95, 0) = 0)
                   and not(nvl(vTplAbc.ABC_CALC_QUANTITY_MIN_95, 0) * 100 between nvl(vTplAbc.CST_QUANTITY_MIN, 0) *(100 - aQtyMinPercentMargin)
                                                                              and nvl(vTplAbc.CST_QUANTITY_MIN, 0) *(100 + aQtyMinPercentMargin)
                          ) then
                  vTplAbc.ABC_QUANTITY_MIN_DEV_ERROR  := 1;
                else
                  vTplAbc.ABC_QUANTITY_MIN_DEV_ERROR  := 0;
                end if;

                -- contrôle du point de commande (taux de couverture 95%)
                if     not(    nvl(vTplAbc.CST_TRIGGER_POINT, 0) = 0
                           and nvl(vTplAbc.ABC_CALC_TRIGGER_POINT_95, 0) = 0)
                   and not(nvl(vTplAbc.ABC_CALC_TRIGGER_POINT_95, 0) * 100 between nvl(vTplAbc.CST_TRIGGER_POINT, 0) *(100 - aTriggerPointPercentMargin)
                                                                               and nvl(vTplAbc.CST_TRIGGER_POINT, 0) *(100 + aTriggerPointPercentMargin)
                          ) then
                  vTplAbc.ABC_TRIGGER_POINT_DEV_ERROR  := 1;
                else
                  vTplAbc.ABC_TRIGGER_POINT_DEV_ERROR  := 0;
                end if;

                if (vTplAbc.ABC_FREE_QUANTITY + vTplAbc.ABC_FREE_SUPPLY_QUANTITY - vTplAbc.ABC_FREE_NEED_QUANTITY) >
                                                                                                    (2 * vTplAbc.ABC_SUPPLY_DELAY * vTplAbc.ABC_MAX_MONTH_VALUE
                                                                                                    ) then
                  vTplAbc.ABC_EXTREME_COVERING_ERROR  := 1;
                else
                  vTplAbc.ABC_EXTREME_COVERING_ERROR  := 0;
                end if;
              end if;
            end if;

            insert into STM_ABC_STOCK_ANALYSE_DET
                 values vTplABC;
          end;
        end loop;
      end if;
    end if;

    update STM_ABC_STOCK_ANALYSE
       set ABH_END_DATE = sysdate
     where STM_ABC_STOCK_ANALYSE_ID = aAnalyseId;
  end analyseABC;

  /**
  * Description
  *    fonction retournant une table avec les biens à analyser et leur code ABC
  */
  procedure analyseABC(
    aMode                      in pls_integer default 1
  , aNbMonth                   in pls_integer default 12
  , aThresholdB                in number default 80
  , aThresholdC                in number default 15
  , aDateRef                   in date default sysdate
  , aWindowMode                in pls_integer default 1
  , aAllowPartial              in number default 0
  , aCompPercentMargin         in number default 5
  , aSupplyDelayPercentMargin  in number default 20
  , aQtyMinPercentMargin       in number default 20
  , aTriggerPointPercentMargin in number default 20
  , aMinTurnoverRatio          in number default 0.5
  , aMonthWorkingDays          in number default 20
  )
  is
    vWording   STM_ABC_STOCK_ANALYSE.ABH_WORDING%type;
    vAnalyseId STM_ABC_STOCK_ANALYSE.STM_ABC_STOCK_ANALYSE_ID%type;
  begin
    select init_id_seq.nextval
      into vAnalyseId
      from dual;

    vWording  := replace(PCS.PC_FUNCTIONS.TranslateWord('Extraction du [DATE]'), '[DATE]', to_char(sysdate, 'DD.MM.YYYY HH24:MI:SS') );
    -- appel de la fonction principale
    analyseABC(vWording
             , vAnalyseId
             , aMode
             , aNbMonth
             , aThresholdB
             , aThresholdC
             , aDateRef
             , aWindowMode
             , aAllowPartial
             , aCompPercentMargin
             , aSupplyDelayPercentMargin
             , aQtyMinPercentMargin
             , aTriggerPointPercentMargin
             , aMinTurnoverRatio
             , aMonthWorkingDays
              );
  end analyseABC;

  /**
  * function annualEvolution
  * Description
  *    Evolution annuelles via fonction table
  * @created fp 16.10.2007
  * @lastUpdate
  * @public
  * @param aGoodId : bien à interroger
  * @return
  */
  function annualEvolution(aGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return tTblAnnualEvolution pipelined
  is
    vResult tTblAnnualEvolution;
  begin
    for tplMovements in (select   *
                             from STM_STOCK_MOVEMENT
                            where GCO_GOOD_Id = aGoodId
                         order by STM_STOCK_MOVEMENT_ID) loop
      null;
    end loop;
  end annualEvolution;
end STM_STOCK_ANALYSE;
