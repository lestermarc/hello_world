--------------------------------------------------------
--  DDL for Package Body PTC_PRC_PRICE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PTC_PRC_PRICE" 
is
  /**
  * Description
  *   Methode de surcharge du framework
  *   Arrondi les dates limites
  */
  procedure TruncPRFDates(iotPTC_FIXED_COSTPRICE in out nocopy fwk_i_typ_definition.t_crud_def)
  is
  begin
    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotPTC_FIXED_COSTPRICE, 'FCP_START_DATE')
       and not FWK_I_MGT_ENTITY_DATA.IsNull(iotPTC_FIXED_COSTPRICE, 'FCP_START_DATE') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotPTC_FIXED_COSTPRICE
                                    , 'FCP_START_DATE'
                                    , trunc(FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotPTC_FIXED_COSTPRICE
                                                                              , 'FCP_START_DATE')
                                           )
                                     );
    end if;

    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotPTC_FIXED_COSTPRICE, 'FCP_END_DATE')
       and not FWK_I_MGT_ENTITY_DATA.IsNull(iotPTC_FIXED_COSTPRICE, 'FCP_END_DATE') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotPTC_FIXED_COSTPRICE
                                    , 'FCP_END_DATE'
                                    , trunc(FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotPTC_FIXED_COSTPRICE, 'FCP_END_DATE') )
                                     );
    end if;
  end TruncPRFDates;

  /**
  * Description
  *   Methode de surcharge du framework
  *   Arrondi les dates limites
  */
  procedure TruncTariffDates(iotPTC_TARIFF in out nocopy fwk_i_typ_definition.t_crud_def)
  is
  begin
    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotPTC_TARIFF, 'TRF_STARTING_DATE')
       and not FWK_I_MGT_ENTITY_DATA.IsNull(iotPTC_TARIFF, 'TRF_STARTING_DATE') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotPTC_TARIFF
                                    , 'TRF_STARTING_DATE'
                                    , trunc(FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotPTC_TARIFF, 'TRF_STARTING_DATE') )
                                     );
    end if;

    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotPTC_TARIFF, 'TRF_ENDING_DATE')
       and not FWK_I_MGT_ENTITY_DATA.IsNull(iotPTC_TARIFF, 'TRF_ENDING_DATE') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotPTC_TARIFF
                                    , 'TRF_ENDING_DATE'
                                    , trunc(FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotPTC_TARIFF, 'TRF_ENDING_DATE') )
                                     );
    end if;
  end TruncTariffDates;

  /**
  * procedure createFIXED_COSTPRICE
  * Description
  *   création d'un prix de revient fixe
  * @created fp 14.12.2011
  * @lastUpdate
  * @public
  * @param
  */
  procedure createFIXED_COST_PRICE(
    ionPTC_FIXED_COSTPRICE_ID      in out PTC_FIXED_COSTPRICE.PTC_FIXED_COSTPRICE_ID%type
  , inGCO_GOOD_ID                  in     PTC_FIXED_COSTPRICE.GCO_GOOD_ID%type
  , inPAC_THIRD_ID                 in     PTC_FIXED_COSTPRICE.PAC_THIRD_ID%type default null
  , ivC_COSTPRICE_STATUS           in     PTC_FIXED_COSTPRICE.C_COSTPRICE_STATUS%type
  , ivDIC_FIXED_COSTPRICE_DESCR_ID in     PTC_FIXED_COSTPRICE.DIC_FIXED_COSTPRICE_DESCR_ID%type
  , ivCPR_DESCR                    in     PTC_FIXED_COSTPRICE.CPR_DESCR%type
  , ivCPR_TEXT                     in     PTC_FIXED_COSTPRICE.CPR_TEXT%type default null
  , inCPR_PRICE                    in     PTC_FIXED_COSTPRICE.CPR_PRICE%type
  , inCPR_DEFAULT                  in     PTC_FIXED_COSTPRICE.CPR_DEFAULT%type default 0
  , idFCP_START_DATE               in     PTC_FIXED_COSTPRICE.FCP_START_DATE%type default null
  , idFCP_END_DATE                 in     PTC_FIXED_COSTPRICE.FCP_END_DATE%type default null
  , inCPR_MANUFACTURE_ACCOUNTING   in     PTC_FIXED_COSTPRICE.CPR_MANUFACTURE_ACCOUNTING%type default null
  , idCPR_CALCUL_DATE              in     PTC_FIXED_COSTPRICE.CPR_CALCUL_DATE%type default null
  , inPTC_RECALC_JOB_ID            in     PTC_FIXED_COSTPRICE.PTC_RECALC_JOB_ID%type default null
  , inCPR_PRICE_BEFORE_RECALC      in     PTC_FIXED_COSTPRICE.CPR_PRICE_BEFORE_RECALC%type default null
  , ivFCP_OPTIONS                  in     PTC_FIXED_COSTPRICE.FCP_OPTIONS%type default null
  , inCPR_HISTORY_ID               in     PTC_FIXED_COSTPRICE.CPR_HISTORY_ID%type default null
  , inFAL_ADV_STRUCT_CALC_ID       in     PTC_FIXED_COSTPRICE.FAL_ADV_STRUCT_CALC_ID%type default null
  , inFAL_SCHEDULE_PLAN_ID         in     PTC_FIXED_COSTPRICE.FAL_SCHEDULE_PLAN_ID%type default null
  , inPPS_NOMENCLATURE_ID          in     PTC_FIXED_COSTPRICE.PPS_NOMENCLATURE_ID%type default null
  , inCOMPL_DATA_MANUFACTURE_ID    in     PTC_FIXED_COSTPRICE.GCO_COMPL_DATA_MANUFACTURE_ID%type default null
  , inCOMPL_DATA_PURCHASE_ID       in     PTC_FIXED_COSTPRICE.GCO_COMPL_DATA_PURCHASE_ID%type default null
  , inCOMPL_DATA_SUBCONTRACT_ID    in     PTC_FIXED_COSTPRICE.GCO_COMPL_DATA_SUBCONTRACT_ID%type default null
  )
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_PTC_ENTITY.gcPtcFixedCostprice, ltCRUD_DEF, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PTC_FIXED_COSTPRICE_ID', ionPTC_FIXED_COSTPRICE_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO_GOOD_ID', inGCO_GOOD_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_THIRD_ID', inPAC_THIRD_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_COSTPRICE_STATUS', ivC_COSTPRICE_STATUS);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_FIXED_COSTPRICE_DESCR_ID', ivDIC_FIXED_COSTPRICE_DESCR_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'CPR_DESCR', ivCPR_DESCR);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'CPR_TEXT', ivCPR_TEXT);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'CPR_PRICE', inCPR_PRICE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'CPR_DEFAULT', inCPR_DEFAULT);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FCP_START_DATE', idFCP_START_DATE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FCP_END_DATE', idFCP_END_DATE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'CPR_MANUFACTURE_ACCOUNTING', inCPR_MANUFACTURE_ACCOUNTING);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'CPR_CALCUL_DATE', idCPR_CALCUL_DATE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PTC_RECALC_JOB_ID', inPTC_RECALC_JOB_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'CPR_PRICE_BEFORE_RECALC', inCPR_PRICE_BEFORE_RECALC);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FCP_OPTIONS', ivFCP_OPTIONS);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'CPR_HISTORY_ID', inCPR_HISTORY_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FAL_ADV_STRUCT_CALC_ID', inFAL_ADV_STRUCT_CALC_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FAL_SCHEDULE_PLAN_ID', inFAL_SCHEDULE_PLAN_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PPS_NOMENCLATURE_ID', inPPS_NOMENCLATURE_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO_COMPL_DATA_MANUFACTURE_ID', inCOMPL_DATA_MANUFACTURE_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO_COMPL_DATA_PURCHASE_ID', inCOMPL_DATA_PURCHASE_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO_COMPL_DATA_SUBCONTRACT_ID', inCOMPL_DATA_SUBCONTRACT_ID);
    -- DML statement
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    ionPTC_FIXED_COSTPRICE_ID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCRUD_DEF, 'PTC_FIXED_COSTPRICE_ID');
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end createFIXED_COST_PRICE;

  /**
  * Description
  *   création d'un tarif
  */
  procedure pCreateTariff(
    ionPTC_TARIFF_ID            in out PTC_TARIFF.PTC_TARIFF_ID%type
  , inC_TARIFF_TYPE             in     PTC_TARIFF.C_TARIFF_TYPE%type
  , inGCO_GOOD_ID               in     PTC_TARIFF.GCO_GOOD_ID%type default null
  , inDIC_SALE_TARIFF_STRUCT_ID in     PTC_TARIFF.DIC_SALE_TARIFF_STRUCT_ID%type default null
  , inDIC_TARIFF_ID             in     PTC_TARIFF.DIC_TARIFF_ID%type
  , inUniquePrice               in     PTC_TARIFF_TABLE.TTA_PRICE%type default null
  , inPAC_THIRD_ID              in     PTC_TARIFF.PAC_THIRD_ID%type default null
  , inACS_FINANCIAL_CURRENCY_ID in     PTC_TARIFF.ACS_FINANCIAL_CURRENCY_ID%type default null
  , inC_TARIFFICATION_MODE      in     PTC_TARIFF.C_TARIFFICATION_MODE%type default null
  , inTRF_DESCR                 in     PTC_TARIFF.TRF_DESCR%type default null
  , inC_ROUND_TYPE              in     PTC_TARIFF.C_ROUND_TYPE%type default null
  , inTRF_ROUND_AMOUNT          in     PTC_TARIFF.TRF_ROUND_AMOUNT%type default null
  , inTRF_UNIT                  in     PTC_TARIFF.TRF_UNIT%type default null
  , inTRF_SQL_CONDITIONAL       in     PTC_TARIFF.TRF_SQL_CONDITIONAL%type default null
  , inTRF_STARTING_DATE         in     PTC_TARIFF.TRF_STARTING_DATE%type default null
  , inTRF_ENDING_DATE           in     PTC_TARIFF.TRF_ENDING_DATE%type default null
  , inTRF_NET_TARIFF            in     PTC_TARIFF.TRF_NET_TARIFF%type default null
  , inTRF_SPECIAL_TARIFF        in     PTC_TARIFF.TRF_SPECIAL_TARIFF%type default null
  , inPTC_FIXED_COSTPRICE_ID    in     PTC_TARIFF.PTC_FIXED_COSTPRICE_ID%type default null
  , inPTC_CALC_COSTPRICE_ID     in     PTC_TARIFF.PTC_CALC_COSTPRICE_ID%type default null
  )
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    if    (    inGCO_GOOD_ID is null
           and inDIC_SALE_TARIFF_STRUCT_ID is not null)
       or (    inGCO_GOOD_ID is not null
           and inDIC_SALE_TARIFF_STRUCT_ID is null) then
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_PTC_ENTITY.gcPtcTariff, ltCRUD_DEF, true);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PTC_TARIFF_ID', ionPTC_TARIFF_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_TARIFF_TYPE', inC_TARIFF_TYPE);

      if inGCO_GOOD_ID is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO_GOOD_ID', inGCO_GOOD_ID);
      end if;

      if inDIC_SALE_TARIFF_STRUCT_ID is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_SALE_TARIFF_STRUCT_ID', inDIC_SALE_TARIFF_STRUCT_ID);
      end if;

      if inPAC_THIRD_ID is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_THIRD_ID', inPAC_THIRD_ID);
      end if;

      if inDIC_TARIFF_ID is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_TARIFF_ID', inDIC_TARIFF_ID);
      end if;

      if inACS_FINANCIAL_CURRENCY_ID is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_FINANCIAL_CURRENCY_ID', inACS_FINANCIAL_CURRENCY_ID);
      end if;

      if inC_TARIFFICATION_MODE is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_TARIFFICATION_MODE', inC_TARIFFICATION_MODE);
      end if;

      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TRF_DESCR', inTRF_DESCR);

      if inC_ROUND_TYPE is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_ROUND_TYPE', inC_ROUND_TYPE);
      end if;

      if inTRF_ROUND_AMOUNT is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TRF_ROUND_AMOUNT', inTRF_ROUND_AMOUNT);
      end if;

      if inTRF_UNIT is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TRF_UNIT', inTRF_UNIT);
      end if;

      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TRF_SQL_CONDITIONAL', inTRF_SQL_CONDITIONAL);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TRF_STARTING_DATE', inTRF_STARTING_DATE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TRF_ENDING_DATE', inTRF_ENDING_DATE);

      if inTRF_NET_TARIFF is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TRF_NET_TARIFF', inTRF_NET_TARIFF);
      end if;

      if inTRF_SPECIAL_TARIFF is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TRF_SPECIAL_TARIFF', inTRF_SPECIAL_TARIFF);
      end if;

      if inPTC_FIXED_COSTPRICE_ID is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PTC_FIXED_COSTPRICE_ID', inPTC_FIXED_COSTPRICE_ID);
      end if;

      if inPTC_CALC_COSTPRICE_ID is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PTC_CALC_COSTPRICE_ID', inPTC_CALC_COSTPRICE_ID);
      end if;

      -- DML statement
      FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
      ionPTC_TARIFF_ID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCRUD_DEF, 'PTC_TARIFF_ID');

      if inUniquePrice is not null then
        -- si un prix unique est donné on créer la tabelle
        AddTariffTable(inPTC_TARIFF_ID => ionPTC_TARIFF_ID, inTTA_PRICE => inUniquePrice);
      end if;

      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    else
      fwk_i_mgt_exception.raise_exception
        (in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
       , iv_message       => PCS.PC_FUNCTIONS.TranslateWord
                               ('PCS - En création de tarif il est obligatoire de donner soit le bien, soit la structure tariffaire de vente.'
                               )
       , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
       , iv_cause         => 'CreateTariff'
        );
    end if;
  end pCreateTariff;

  /**
  * Description
  *   création d'un tarif de vente
  */
  procedure createSaleTariff(
    ionPTC_TARIFF_ID            in out PTC_TARIFF.PTC_TARIFF_ID%type
  , inGCO_GOOD_ID               in     PTC_TARIFF.GCO_GOOD_ID%type default null
  , inDIC_SALE_TARIFF_STRUCT_ID in     PTC_TARIFF.DIC_SALE_TARIFF_STRUCT_ID%type default null
  , inDIC_TARIFF_ID             in     PTC_TARIFF.DIC_TARIFF_ID%type
  , inUniquePrice               in     PTC_TARIFF_TABLE.TTA_PRICE%type default null
  , inPAC_THIRD_ID              in     PTC_TARIFF.PAC_THIRD_ID%type default null
  , inACS_FINANCIAL_CURRENCY_ID in     PTC_TARIFF.ACS_FINANCIAL_CURRENCY_ID%type default null
  , inC_TARIFFICATION_MODE      in     PTC_TARIFF.C_TARIFFICATION_MODE%type default null
  , inTRF_DESCR                 in     PTC_TARIFF.TRF_DESCR%type default null
  , inC_ROUND_TYPE              in     PTC_TARIFF.C_ROUND_TYPE%type default null
  , inTRF_ROUND_AMOUNT          in     PTC_TARIFF.TRF_ROUND_AMOUNT%type default null
  , inTRF_UNIT                  in     PTC_TARIFF.TRF_UNIT%type default null
  , inTRF_SQL_CONDITIONAL       in     PTC_TARIFF.TRF_SQL_CONDITIONAL%type default null
  , inTRF_STARTING_DATE         in     PTC_TARIFF.TRF_STARTING_DATE%type default null
  , inTRF_ENDING_DATE           in     PTC_TARIFF.TRF_ENDING_DATE%type default null
  , inTRF_NET_TARIFF            in     PTC_TARIFF.TRF_NET_TARIFF%type default null
  , inTRF_SPECIAL_TARIFF        in     PTC_TARIFF.TRF_SPECIAL_TARIFF%type default null
  , inPTC_FIXED_COSTPRICE_ID    in     PTC_TARIFF.PTC_FIXED_COSTPRICE_ID%type default null
  , inPTC_CALC_COSTPRICE_ID     in     PTC_TARIFF.PTC_CALC_COSTPRICE_ID%type default null
  )
  is
  begin
    pCreateTariff(ionPTC_TARIFF_ID              => ionPTC_TARIFF_ID
                , inC_TARIFF_TYPE               => 'A_FACTURER'
                , inGCO_GOOD_ID                 => inGCO_GOOD_ID
                , inDIC_SALE_TARIFF_STRUCT_ID   => inDIC_SALE_TARIFF_STRUCT_ID
                , inDIC_TARIFF_ID               => inDIC_TARIFF_ID
                , inUniquePrice                 => inUniquePrice
                , inPAC_THIRD_ID                => inPAC_THIRD_ID
                , inACS_FINANCIAL_CURRENCY_ID   => inACS_FINANCIAL_CURRENCY_ID
                , inC_TARIFFICATION_MODE        => inC_TARIFFICATION_MODE
                , inTRF_DESCR                   => inTRF_DESCR
                , inC_ROUND_TYPE                => inC_ROUND_TYPE
                , inTRF_ROUND_AMOUNT            => inTRF_ROUND_AMOUNT
                , inTRF_UNIT                    => inTRF_UNIT
                , inTRF_SQL_CONDITIONAL         => inTRF_SQL_CONDITIONAL
                , inTRF_STARTING_DATE           => inTRF_STARTING_DATE
                , inTRF_ENDING_DATE             => inTRF_ENDING_DATE
                , inTRF_NET_TARIFF              => inTRF_NET_TARIFF
                , inTRF_SPECIAL_TARIFF          => inTRF_SPECIAL_TARIFF
                , inPTC_FIXED_COSTPRICE_ID      => inPTC_FIXED_COSTPRICE_ID
                , inPTC_CALC_COSTPRICE_ID       => inPTC_CALC_COSTPRICE_ID
                 );
  end createSaleTariff;

  /**
  * Description
  *   création d'un tarif de vente
  */
  procedure createPurchaseTariff(
    ionPTC_TARIFF_ID            in out PTC_TARIFF.PTC_TARIFF_ID%type
  , inGCO_GOOD_ID               in     PTC_TARIFF.GCO_GOOD_ID%type default null
  , inDIC_SALE_TARIFF_STRUCT_ID in     PTC_TARIFF.DIC_SALE_TARIFF_STRUCT_ID%type default null
  , inDIC_TARIFF_ID             in     PTC_TARIFF.DIC_TARIFF_ID%type
  , inUniquePrice               in     PTC_TARIFF_TABLE.TTA_PRICE%type default null
  , inPAC_THIRD_ID              in     PTC_TARIFF.PAC_THIRD_ID%type default null
  , inACS_FINANCIAL_CURRENCY_ID in     PTC_TARIFF.ACS_FINANCIAL_CURRENCY_ID%type default null
  , inC_TARIFFICATION_MODE      in     PTC_TARIFF.C_TARIFFICATION_MODE%type default null
  , inTRF_DESCR                 in     PTC_TARIFF.TRF_DESCR%type default null
  , inC_ROUND_TYPE              in     PTC_TARIFF.C_ROUND_TYPE%type default null
  , inTRF_ROUND_AMOUNT          in     PTC_TARIFF.TRF_ROUND_AMOUNT%type default null
  , inTRF_UNIT                  in     PTC_TARIFF.TRF_UNIT%type default null
  , inTRF_SQL_CONDITIONAL       in     PTC_TARIFF.TRF_SQL_CONDITIONAL%type default null
  , inTRF_STARTING_DATE         in     PTC_TARIFF.TRF_STARTING_DATE%type default null
  , inTRF_ENDING_DATE           in     PTC_TARIFF.TRF_ENDING_DATE%type default null
  , inTRF_NET_TARIFF            in     PTC_TARIFF.TRF_NET_TARIFF%type default null
  , inTRF_SPECIAL_TARIFF        in     PTC_TARIFF.TRF_SPECIAL_TARIFF%type default null
  , inPTC_FIXED_COSTPRICE_ID    in     PTC_TARIFF.PTC_FIXED_COSTPRICE_ID%type default null
  , inPTC_CALC_COSTPRICE_ID     in     PTC_TARIFF.PTC_CALC_COSTPRICE_ID%type default null
  )
  is
  begin
    pCreateTariff(ionPTC_TARIFF_ID              => ionPTC_TARIFF_ID
                , inC_TARIFF_TYPE               => 'A_PAYER'
                , inGCO_GOOD_ID                 => inGCO_GOOD_ID
                , inDIC_SALE_TARIFF_STRUCT_ID   => inDIC_SALE_TARIFF_STRUCT_ID
                , inDIC_TARIFF_ID               => inDIC_TARIFF_ID
                , inUniquePrice                 => inUniquePrice
                , inPAC_THIRD_ID                => inPAC_THIRD_ID
                , inACS_FINANCIAL_CURRENCY_ID   => inACS_FINANCIAL_CURRENCY_ID
                , inC_TARIFFICATION_MODE        => inC_TARIFFICATION_MODE
                , inTRF_DESCR                   => inTRF_DESCR
                , inC_ROUND_TYPE                => inC_ROUND_TYPE
                , inTRF_ROUND_AMOUNT            => inTRF_ROUND_AMOUNT
                , inTRF_UNIT                    => inTRF_UNIT
                , inTRF_SQL_CONDITIONAL         => inTRF_SQL_CONDITIONAL
                , inTRF_STARTING_DATE           => inTRF_STARTING_DATE
                , inTRF_ENDING_DATE             => inTRF_ENDING_DATE
                , inTRF_NET_TARIFF              => inTRF_NET_TARIFF
                , inTRF_SPECIAL_TARIFF          => inTRF_SPECIAL_TARIFF
                , inPTC_FIXED_COSTPRICE_ID      => inPTC_FIXED_COSTPRICE_ID
                , inPTC_CALC_COSTPRICE_ID       => inPTC_CALC_COSTPRICE_ID
                 );
  end createPurchaseTariff;

  /**
  * Description
  *   création d'une ligne de tabelle de tarif
  */
  procedure AddTariffTable(
    inPTC_TARIFF_ID     in PTC_TARIFF.PTC_TARIFF_ID%type
  , inTTA_FROM_QUANTITY in PTC_TARIFF_TABLE.TTA_FROM_QUANTITY%type default 0
  , inTTA_TO_QUANTITY   in PTC_TARIFF_TABLE.TTA_TO_QUANTITY%type default 0
  , inTTA_PRICE         in PTC_TARIFF_TABLE.TTA_PRICE%type
  )
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_PTC_ENTITY.gcPtcTariffTable, ltCRUD_DEF, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PTC_TARIFF_ID', inPTC_TARIFF_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TTA_FROM_QUANTITY', inTTA_FROM_QUANTITY);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TTA_TO_QUANTITY', inTTA_TO_QUANTITY);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TTA_PRICE', inTTA_PRICE);
    -- DML statement
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end AddTariffTable;
end PTC_PRC_PRICE;
