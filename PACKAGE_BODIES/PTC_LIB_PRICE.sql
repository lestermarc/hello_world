--------------------------------------------------------
--  DDL for Package Body PTC_LIB_PRICE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PTC_LIB_PRICE" 
is
  /**
  * Description
  *   Methode de surcharge du framework
  *   Test qu'on ait pas déjà de prix de revient par défaut
  */
  procedure TestOtherDefaultPrice(iotPTC_FIXED_COSTPRICE in out nocopy fwk_i_typ_definition.t_crud_def, oError out varchar2)
  is
    lGoodId           PTC_FIXED_COSTPRICE.GCO_GOOD_ID%type              := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotPTC_FIXED_COSTPRICE, 'GCO_GOOD_ID');
    lThirdId          PTC_FIXED_COSTPRICE.PAC_THIRD_ID%type             := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotPTC_FIXED_COSTPRICE, 'PAC_THIRD_ID');
    lFixedCostpriceId PTC_FIXED_COSTPRICE.PTC_FIXED_COSTPRICE_ID%type
                                                                     := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotPTC_FIXED_COSTPRICE, 'PTC_FIXED_COSTPRICE_ID');
  begin
    for ltplActualDefaultPrice in (select *
                                     from PTC_FIXED_COSTPRICE
                                    where GCO_GOOD_ID = lGoodId
                                      and nvl(PAC_THIRD_ID, 0) = nvl(lThirdId, 0)
                                      and PTC_FIXED_COSTPRICE_ID != lFixedCostpriceId
                                      and CPR_DEFAULT = 1
                                      and C_COSTPRICE_STATUS = 'ACT') loop
      oError  := PCS.PC_FUNCTIONS.TranslateWord('PCS - Un prix de revient par défaut existe déjà pour ce couple bien/tiers.');
    end loop;
  end TestOtherDefaultPrice;

  /**
  * Description
  *   Methode de surcharge du framework
  *   Teste la cohérence des dates de validité du prix de revient fixe
  */
  procedure TestPRFDates(iotPTC_FIXED_COSTPRICE in out nocopy fwk_i_typ_definition.t_crud_def, oError out varchar2)
  is
  begin
    if     not(   FWK_I_MGT_ENTITY_DATA.IsNull(iotPTC_FIXED_COSTPRICE, 'FCP_END_DATE')
               or FWK_I_MGT_ENTITY_DATA.IsNull(iotPTC_FIXED_COSTPRICE, 'FCP_START_DATE') )
       and (FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotPTC_FIXED_COSTPRICE, 'FCP_START_DATE') >
                                                                                     FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotPTC_FIXED_COSTPRICE, 'FCP_END_DATE')
           ) then
      oError  := PCS.PC_FUNCTIONS.TranslateWord('La date de début ne peut pas être supérieure à la date de fin !');
    end if;
  end TestPRFDates;

  /**
  * Description
  *   Methode de surcharge du framework
  *   Teste la cohérence des dates de validité du tarif
  */
  procedure TestTariffDates(iotPTC_TARIFF in out nocopy fwk_i_typ_definition.t_crud_def, oError out varchar2)
  is
  begin
    if     not(   FWK_I_MGT_ENTITY_DATA.IsNull(iotPTC_TARIFF, 'TRF_ENDING_DATE')
               or FWK_I_MGT_ENTITY_DATA.IsNull(iotPTC_TARIFF, 'TRF_STARTING_DATE') )
       and (FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotPTC_TARIFF, 'TRF_STARTING_DATE') > FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotPTC_TARIFF, 'TRF_ENDING_DATE') ) then
      oError  := PCS.PC_FUNCTIONS.TranslateWord('La date de début ne peut pas être supérieure à la date de fin !');
    end if;
  end TestTariffDates;

  /**
  * Description
  *   Methode de surcharge du framework
  *   Teste d'éventuels conflits de date avec d'autres tarifs (non-bloquant)
  */
  procedure TestDateConflict(iotPTC_TARIFF in out nocopy fwk_i_typ_definition.t_crud_def, oError out varchar2)
  is
    lCount               pls_integer;
    lTariffId            PTC_TARIFF.PTC_TARIFF_ID%type               := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotPTC_TARIFF, 'PTC_TARIFF_ID');
    lStartingDate        PTC_TARIFF.TRF_STARTING_DATE%type           := FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotPTC_TARIFF, 'TRF_STARTING_DATE');
    lEndingDate          PTC_TARIFF.TRF_ENDING_DATE%type             := FWK_I_MGT_ENTITY_DATA.GetColumnDate(iotPTC_TARIFF, 'TRF_ENDING_DATE');
    lDicTariffId         PTC_TARIFF.DIC_TARIFF_ID%type               := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotPTC_TARIFF, 'PTC_TARIFF_ID');
    lThirdId             PTC_TARIFF.PAC_THIRD_ID%type                := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotPTC_TARIFF, 'PAC_THIRD_ID');
    lGoodId              PTC_TARIFF.GCO_GOOD_ID%type                 := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotPTC_TARIFF, 'GCO_GOOD_ID');
    lSaleTariffStructId  PTC_TARIFF.DIC_SALE_TARIFF_STRUCT_ID%type   := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotPTC_TARIFF, 'DIC_SALE_TARIFF_STRUCT_ID');
    lPurTariffStructId   PTC_TARIFF.DIC_PUR_TARIFF_STRUCT_ID%type    := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotPTC_TARIFF, 'DIC_PUR_TARIFF_STRUCT_ID');
    lFinancialCurrencyId PTC_TARIFF.ACS_FINANCIAL_CURRENCY_ID%type   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotPTC_TARIFF, 'ACS_FINANCIAL_CURRENCY_ID');
    lTarifficationMode   PTC_TARIFF.C_TARIFFICATION_MODE%type        := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotPTC_TARIFF, 'C_TARIFFICATION_MODE');
    lTariffType          PTC_TARIFF.C_TARIFF_TYPE%type               := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotPTC_TARIFF, 'C_TARIFF_TYPE');
    lTrfDescr            PTC_TARIFF.TRF_DESCR%type                   := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotPTC_TARIFF, 'TRF_DESCR');
  begin
    -- In the sql command, it is not possible to use direct calls to the framework.
    -- That's why we have to use variables instead.
    select count(*)
      into lCount
      from PTC_TARIFF
     where not PTC_TARIFF_ID = nvl(lTariffId, 0)
       and (    (    lStartingDate is null
                 and lEndingDate is null)
            or (    lStartingDate is not null
                and lStartingDate between nvl(TRF_STARTING_DATE, to_date('01.01.0001', 'DD.MM.YYYY') )
                                      and nvl(TRF_ENDING_DATE, to_date('31-12-2999', 'DD-MM-YYYY') )
               )
            or (    lEndingDate is not null
                and lEndingDate between nvl(TRF_STARTING_DATE, to_date('01.01.0001', 'DD.MM.YYYY') ) and nvl(TRF_ENDING_DATE
                                                                                                           , to_date('31-12-2999', 'DD-MM-YYYY')
                                                                                                            )
               )
            or (    lEndingDate is null
                and TRF_STARTING_DATE >= lStartingDate)
            or (    lStartingDate is null
                and TRF_STARTING_DATE <= lEndingDate)
           )
       and TRF_DESCR = lTrfDescr
       and C_TARIFF_TYPE = lTariffType
       and C_TARIFFICATION_MODE = lTarifficationMode
       and ACS_FINANCIAL_CURRENCY_ID = lFinancialCurrencyId
       and nvl(DIC_TARIFF_ID, 'NULL') = nvl(lDicTariffId, 'NULL')
       and nvl(DIC_PUR_TARIFF_STRUCT_ID, 'NULL') = nvl(lPurTariffStructId, 'NULL')
       and nvl(DIC_SALE_TARIFF_STRUCT_ID, 'NULL') = nvl(lSaleTariffStructId, 'NULL')
       and nvl(GCO_GOOD_ID, 0) = nvl(lGoodId, 0)
       and nvl(PAC_THIRD_ID, 0) = nvl(lThirdId, 0);

    if lCount > 0 then
      oError  := PCS.PC_FUNCTIONS.TranslateWord('Conflit avec les dates d''autre(s) tarif(s) ! Voulez-vous continuer ?');
    end if;
  end TestDateConflict;

  /**
  * Description
  *   Methode de surcharge du framework
  *   Test les quantités de la tabelle de tarif afin d'éviter des chevauchements
  */
  procedure TestTariffTableQuantities(iotPTC_TARIFF_TABLE in out nocopy fwk_i_typ_definition.t_crud_def, oError out varchar2)
  is
    lCount         pls_integer;
    lTariffTableId PTC_TARIFF_TABLE.PTC_TARIFF_TABLE_ID%type   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotPTC_TARIFF_TABLE, 'PTC_TARIFF_TABLE_ID');
    lTariffId      PTC_TARIFF_TABLE.PTC_TARIFF_ID%type         := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotPTC_TARIFF_TABLE, 'PTC_TARIFF_ID');
    lFromQuantity  PTC_TARIFF_TABLE.TTA_FROM_QUANTITY%type     := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotPTC_TARIFF_TABLE, 'TTA_FROM_QUANTITY');
    lToQuantity    PTC_TARIFF_TABLE.TTA_TO_QUANTITY%type       := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotPTC_TARIFF_TABLE, 'TTA_TO_QUANTITY');
    lMaxValue      PTC_TARIFF_TABLE.TTA_TO_QUANTITY%type       default 99999999999.9999;
  begin
    -- Test qui vérifie qu'il n'y ait pas de chevauchement de quantité lors
    -- de la saisie des tabelles
    if     lFromQuantity is not null
       and lToQuantity is not null then
      -- Si la qté "jusqu'à" est égale à 0 et que la qté "depuis" est supérieure à 0
      --  Alors on force la valeur max dans la qté "jusqu'à" à la place de la valeur 0
      --  Remarque : idem dans la cmde sql ci-dessous
      if     (lToQuantity = 0)
         and (sign(lFromQuantity) = 1) then
        lToQuantity  := lMaxValue;
      end if;

      select sign(nvl(max(PTC_TARIFF_TABLE_ID), 0) )
        into lCount
        from (select TTA_FROM_QUANTITY
                   , case
                       when(TTA_TO_QUANTITY = 0)
                       and (sign(TTA_FROM_QUANTITY) = 1) then lMaxValue
                       else TTA_TO_QUANTITY
                     end as TTA_TO_QUANTITY
                   , PTC_TARIFF_TABLE_ID
                from PTC_TARIFF_TABLE
               where PTC_TARIFF_ID = lTariffId
                 and PTC_TARIFF_TABLE_ID <> lTariffTableId)
       where (lFromQuantity between TTA_FROM_QUANTITY and TTA_TO_QUANTITY)
          or (lToQuantity between TTA_FROM_QUANTITY and TTA_TO_QUANTITY);

      -- si au moins 1 chevauchement trouvé, on signale une erreur
      if lCount > 0 then
        oError  := PCS.PC_FUNCTIONS.TranslateWord('Chevauchement de quantités dans la tabelle');
      end if;
    end if;
  end TestTariffTableQuantities;

  /**
  * Description
  *   Retourne l'id de la monnaie en fonction du code tarif
  */
  function getCurrIdFromDicTariff(iDicTariffId DIC_TARIFF.DIC_TARIFF_ID%type)
    return DIC_TARIFF.ACS_FINANCIAL_CURRENCY_ID%type
  is
    lcCurrId DIC_TARIFF.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    select nvl(max(ACS_FINANCIAL_CURRENCY_ID), 0)
      into lcCurrId
      from DIC_TARIFF
     where DIC_TARIFF_ID = iDicTariffId;

    return lcCurrId;
  end getCurrIdFromDicTariff;

  /**
  * Description
  *   Retourne 1 si au moins un des prix de la tabelle des tarifs
  *   est un tarif forfaitaire
  */
  function getTariffFlatRate(iTariffId PTC_TARIFF.PTC_TARIFF_ID%type)
    return number
  is
    lnResult number(1);
  begin
    select nvl(max(TTA_FLAT_RATE), 0)
      into lnResult
      from PTC_TARIFF_TABLE
     where PTC_TARIFF_ID = iTariffId;

    return lnResult;
  end getTariffFlatRate;

  /**
  * Description
  *    Return the price outside the current transaction
  */
  function getTableTariffPrice_Autonomous(iTariffTableId in PTC_TARIFF_TABLE.PTC_TARIFF_TABLE_ID%type)
    return PTC_TARIFF_TABLE.TTA_PRICE%type
  is
    pragma autonomous_transaction;
    lResult PTC_TARIFF_TABLE.TTA_PRICE%type;
  begin
    select TTA_PRICE
      into lResult
      from PTC_TARIFF_TABLE
     where PTC_TARIFF_TABLE_ID = iTariffTableId;

    return lResult;
  end getTableTariffPrice_Autonomous;
end PTC_LIB_PRICE;
