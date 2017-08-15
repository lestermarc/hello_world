--------------------------------------------------------
--  DDL for Package Body DOC_TARIFF_SET
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_TARIFF_SET" 
as
  procedure UpdatePriceForOneSet(
    aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aSet        in DOC_POSITION.POS_TARIFF_SET%type
  , aSetQty        DOC_POSITION.POS_BASIS_QUANTITY%type
  )
  is
    cursor crPositions(cDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type, cSet DOC_POSITION.POS_TARIFF_SET%type)
    is
      select pos.doc_position_id
           , pos.gco_good_id
           , nvl(pos.dic_tariff_id, decode(GAP.GAP_FORCED_TARIFF, 1, GAP.DIC_TARIFF_ID, DMT.DIC_TARIFF_ID) ) DIC_TARIFF_ID
           , DMT.DIC_TARIFF_ID DMT_DIC_TARIFF_ID
           , nvl(POS.POS_TARIFF_DATE, nvl(DMT.DMT_TARIFF_DATE, DMT.DMT_DATE_DOCUMENT) ) POS_TARIFF_DATE
           , DMT_DATE_DOCUMENT
           , DMT_RATE_OF_EXCHANGE
           , DMT_BASE_PRICE
           , DMT.PAC_THIRD_ID
           , DMT.PAC_THIRD_TARIFF_ID
           , nvl(POS.DOC_RECORD_ID, DMT.DOC_RECORD_ID) DOC_RECORD_ID
           , DMT.ACS_FINANCIAL_CURRENCY_ID
           , GAU.C_ADMIN_DOMAIN
           , POS.POS_CONVERT_FACTOR
           , GAP.C_GAUGE_INIT_PRICE_POS
           , POS.C_GAUGE_TYPE_POS
           , POS.DOC_DOC_POSITION_ID
           , FATHER.C_GAUGE_TYPE_POS FATHER_GAUGE_TYPE_POS
        from DOC_POSITION POS
           , DOC_POSITION FATHER
           , DOC_GAUGE_POSITION GAP
           , DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
       where DMT.DOC_DOCUMENT_ID = cDocumentID
         and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
         and POS.POS_TARIFF_SET = cSet
         and FATHER.DOC_POSITION_ID(+) = POS.DOC_DOC_POSITION_ID
         and GAP.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
         and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and nvl(POS.POS_PRICE_TRANSFERED, 0) = 0
         and POS.C_DOC_POS_STATUS not in('04', '05')
         and POS.C_GAUGE_TYPE_POS in('1', '7', '10', '81', '91');

    unitValue        DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    roundType        varchar2(1);
    roundAmount      number(18, 5);
    priceCurrencyId  ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    posNetTariff     DOC_POSITION.POS_NET_TARIFF%type;
    posSpecialTariff DOC_POSITION.POS_SPECIAL_TARIFF%type;
    posFlatRate      DOC_POSITION.POS_FLAT_RATE%type;
    posTariffUnit    DOC_POSITION.POS_TARIFF_UNIT%type;
  begin
    for tplPosition in crPositions(aDocumentId, aSet) loop
      PriceCurrencyId  := tplPosition.ACS_FINANCIAL_CURRENCY_ID;
      -- recherche du prix unitaire
      unitValue        :=
        nvl(GCO_I_LIB_PRICE.GetGoodPrice(iGoodId              => tplPosition.GCO_GOOD_ID
                                       , iTypePrice           => tplPosition.C_GAUGE_INIT_PRICE_POS
                                       , iThirdId             => nvl(tplPosition.PAC_THIRD_TARIFF_ID, tplPosition.PAC_THIRD_ID)
                                       , iRecordId            => tplPosition.DOC_RECORD_ID
                                       , iFalScheduleStepId   => null
                                       , ioDicTariff          => tplPosition.DIC_TARIFF_ID
                                       , iQuantity            => aSetQty
                                       , iDateRef             => tplPosition.POS_TARIFF_DATE
                                       , ioRoundType          => roundtype
                                       , ioRoundAmount        => roundAmount
                                       , ioCurrencyId         => priceCurrencyId
                                       , oNet                 => posNetTariff
                                       , oSpecial             => posSpecialTariff
                                       , oFlatRate            => posFlatRate
                                       , oTariffUnit          => posTariffUnit
                                       , iDicTariff2          => tplPosition.DMT_DIC_TARIFF_ID
                                        ) *
            tplPosition.POS_CONVERT_FACTOR
          , 0
           );

      -- application du change si tarif trouvé dans une autre monnaie que celle du document
      if tplPosition.ACS_FINANCIAL_CURRENCY_ID <> priceCurrencyId then
        unitValue  :=
          ACS_FUNCTION.ConvertAmountForView(unitValue
                                          , priceCurrencyId
                                          , tplPosition.ACS_FINANCIAL_CURRENCY_ID
                                          , tplPosition.POS_TARIFF_DATE
                                          , tplPosition.DMT_RATE_OF_EXCHANGE
                                          , tplPosition.DMT_BASE_PRICE
                                          , 0
                                          , 5
                                           );   -- Cours logistique
      end if;

      --Mode TTC
      if DOC_FUNCTIONS.isDocumentTTC(aDocumentId) = 1 then
        if tplPosition.C_GAUGE_TYPE_POS = '81' then
          update DOC_POSITION
             set POS_GROSS_UNIT_VALUE2 = unitValue
               , POS_RECALC_AMOUNTS = 1
           where DOC_POSITION_ID = tplPosition.DOC_POSITION_ID;
        else
          update DOC_POSITION
             set POS_GROSS_UNIT_VALUE_INCL = unitValue
               , POS_GROSS_VALUE_INCL = unitValue * POS_BASIS_QUANTITY
               , POS_RECALC_AMOUNTS = 1
           where DOC_POSITION_ID = tplPosition.DOC_POSITION_ID;
        end if;
      -- Mode HT
      else
        if tplPosition.C_GAUGE_TYPE_POS = '81' then
          update DOC_POSITION
             set POS_GROSS_UNIT_VALUE2 = unitValue
               , POS_RECALC_AMOUNTS = 1
           where DOC_POSITION_ID = tplPosition.DOC_POSITION_ID;
        else
          update DOC_POSITION
             set POS_GROSS_UNIT_VALUE = unitValue
               , POS_GROSS_VALUE = unitValue * POS_BASIS_QUANTITY
               , POS_RECALC_AMOUNTS = 1
           where DOC_POSITION_ID = tplPosition.DOC_POSITION_ID;
        end if;
      end if;

      -- Mise à jour des montants de remises/taxes et de la positions
      if tplPosition.FATHER_GAUGE_TYPE_POS = '8' then
        DOC_POSITION_FUNCTIONS.CalculateAmountsPos8(tplPosition.DOC_DOC_POSITION_ID);
      else
        DOC_POSITION_FUNCTIONS.UpdateChargeAndAmount(tplPosition.DOC_POSITION_ID);
      end if;
    end loop;
  end UpdatePriceForOneSet;

  /**
  * Description
  *   Mise à jour des prix des positions gérées
  *   selon assortiment
  */
  procedure DocUpdatePriceForTariffSet(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    cursor crQtyBySet(cDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
    is
      select   POS.POS_TARIFF_SET
             , sum(POS.POS_BASIS_QUANTITY) SET_QUANTITY
          from DOC_POSITION POS
             , DOC_DOCUMENT DMT
         where DMT.DOC_DOCUMENT_ID = cDocumentId
           and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
           and POS.POS_TARIFF_SET is not null
           and POS.C_DOC_POS_STATUS <> '05'
           and POS.C_GAUGE_TYPE_POS in('1', '7', '10', '81', '91')
           and DMT.DMT_RECALC_TOTAL = 1
      group by POS_TARIFF_SET;
  begin
    for tplQtyBySet in crQtyBySet(aDocumentId) loop
      UpdatePriceForOneSet(aDocumentId, tplQtyBySet.POS_TARIFF_SET, tplQtyBySet.SET_QUANTITY);
    end loop;
  end DocUpdatePriceForTariffSet;
end DOC_TARIFF_SET;
