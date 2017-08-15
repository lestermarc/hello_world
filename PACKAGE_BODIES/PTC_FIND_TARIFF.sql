--------------------------------------------------------
--  DDL for Package Body PTC_FIND_TARIFF
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PTC_FIND_TARIFF" 
is
  /**
  * function testQty
  * Description
  *   Teste si la quantité demandée est présente dans la tabelle du
  *   tarif ou si on autorise qu'elle n'y soit pas
  * @created fp 06.09.2005
  * @lastUpdate
  * @public
  * @param aTariffId : id du tarif à tester
  * @param aQuantity : quantité de recherche
  * @return
  */
  function testQty(aTariffId in PTC_TARIFF.PTC_TARIFF_ID%type, aQuantity PTC_TARIFF_TABLE.TTA_FROM_QUANTITY%type)
    return boolean
  is
    vTempId PTC_TARIFF.PTC_TARIFF_ID%type;
  begin
    if PCS.PC_CONFIG.GetBooleanConfig('PTC_RESTRICT_ON_TABLE') then
      select PTC_TARIFF_ID
        into vTempId
        from PTC_TARIFF_TABLE
       where PTC_TARIFF_ID = aTariffId
         and aQuantity between decode(TTA_FROM_QUANTITY, 0, aQuantity, TTA_FROM_QUANTITY) and decode(TTA_TO_QUANTITY, 0, aQuantity, TTA_TO_QUANTITY);
    end if;

    return true;
  exception
    when too_many_rows then
      declare
        vMajorRef GCO_GOOD.GOO_MAJOR_REFERENCE%type;
      begin
        select GOO.GOO_MAJOR_REFERENCE
          into vMajorRef
          from GCO_GOOD GOO
             , PTC_TARIFF TRF
         where TRF.PTC_TARIFF_ID = aTariffId
           and GOO.GCO_GOOD_ID(+) = TRF.GCO_GOOD_ID;

        raise_application_error(-20000, replace(PCS.PC_FUNCTIONS.TranslateWord('PCS - Tabelle de tarif ambigüe pour le bien  : [REF]'), '[REF]', vMajorRef) );
      end;
    when no_data_found then
      return false;
  end testQty;

  /**
  * Description
  *    procedure de recherche du tarif depuis un document
  */
  procedure GetTariff(
    aGoodId            in     number
  , aThirdId           in out number
  , aRecordId          in     number
  , aDocCurrId         in     number
  , aDicTariffId       in out varchar2
  , aQuantity          in     number
  , aRefDate           in     date
  , aTariffType        in     varchar2
  , aTarifficationMode        varchar2
  , aFoundTariffId     in out number
  , aCurrencyId        in out number
  , aNet               in out number
  , aSpecial           in out number
  , aDocDicTariffId    in     varchar2 default null
  )
  is
    vThirdId     PAC_THIRD.PAC_THIRD_ID%type;
    vDicTariffId DIC_TARIFF.DIC_TARIFF_ID%type;
  begin
    if     nvl(aDicTariffId, 'NULL') <> nvl(aDocDicTariffId, 'NULL')
       and aDocDicTariffId is not null
       and not PCS.PC_CONFIG.getbooleanConfig('PTC_MANDATORY_TARIFF') then
      vThirdId      := aThirdId;
      vDicTariffId  := aDicTariffid;
      GetTariff(aGoodId
              , vThirdId
              , aRecordId
              , aDocCurrId
              , vDicTariffId
              , aQuantity
              , aRefDate
              , aTariffType
              , aTarifficationMode
              , aFoundTariffId
              , aCurrencyId
              , aNet
              , aSpecial
              , true
               );

      if aFoundTariffId is null then
        vThirdId      := aThirdId;
        vDicTariffId  := aDocDicTariffid;
        GetTariff(aGoodId
                , vThirdId
                , aRecordId
                , aDocCurrId
                , vDicTariffId
                , aQuantity
                , aRefDate
                , aTariffType
                , aTarifficationMode
                , aFoundTariffId
                , aCurrencyId
                , aNet
                , aSpecial
                , true
                 );
      end if;
    end if;

    if aFoundTariffId is null then
      vThirdId      := aThirdId;
      vDicTariffId  := aDicTariffid;
      GetTariff(aGoodId
              , vThirdId
              , aRecordId
              , aDocCurrId
              , vDicTariffId
              , aQuantity
              , aRefDate
              , aTariffType
              , aTarifficationMode
              , aFoundTariffId
              , aCurrencyId
              , aNet
              , aSpecial
              , false
               );
    end if;

    aThirdId      := vThirdId;
    aDicTariffId  := vDicTariffid;
  end GetTariff;

  /**
  * Description
  *    procedure de recherche du tarif depuis un document
  */
  procedure GetTariff(
    aGoodId            in     number
  , aThirdId           in out number
  , aRecordId          in     number
  , aDocCurrId         in     number
  , aDicTariffId       in out varchar2
  , aQuantity          in     number
  , aRefDate           in     date
  , aTariffType        in     varchar2
  , aTarifficationMode        varchar2
  , aFoundTariffId     in out number
  , aCurrencyId        in out number
  , aNet               in out number
  , aSpecial           in out number
  , aMandatory         in     boolean
  )
  is
    vNormalTariffId   PTC_TARIFF.PTC_TARIFF_ID%type;
    vNormalPrice      PTC_TARIFF_TABLE.TTA_PRICE%type;
    vNormalThirdId    PTC_TARIFF.PAC_THIRD_ID%type;
    vNormalCoef       GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type      default 1;
    vSpecialTariffId  PTC_TARIFF.PTC_TARIFF_ID%type;
    vSpecialPrice     PTC_TARIFF_TABLE.TTA_PRICE%type;
    vSpecialThirdId   PTC_TARIFF.PAC_THIRD_ID%type;
    vSpecialCoef      GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type      default 1;
    vDocEuroCurId     ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    vLocCurId         ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    vLocEuroCurId     ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    vNetNormal        number(1);
    vNetAction        number(1);
    vChargeType       PTC_CHARGE.C_CHARGE_TYPE%type;
    vQuantity         PTC_TARIFF_TABLE.TTA_FROM_QUANTITY%type;
    vMandatory        number(1);
    vNormalDicTariff  PTC_TARIFF.DIC_TARIFF_ID%type;
    vSpecialDicTariff PTC_TARIFF.DIC_TARIFF_ID%type;
  begin
    -- Mode mandatory en fonction du paramètre et de la config
    if    PCS.PC_CONFIG.GetBooleanConfig('PTC_MANDATORY_TARIFF')
       or aMandatory then
      vMandatory  := 1;
    else
      vMandatory  := 0;
    end if;

    vNormalDicTariff   := aDicTariffId;
    vSpecialDicTariff  := aDicTariffId;
    aDicTariffId       := null;

    -- si la monnaie document est une monanie Euro,
    -- on recherche l'ID de l'Euro pour la recherche de 2ème niveau
    if ACS_FUNCTION.IsFinCurrInEuro(aDocCurrId, aRefDate) = 1 then
      vDocEuroCurId  := ACS_FUNCTION.GetEuroCurrency;
    end if;

    -- si la monnaie document est différente de la monnaie de base,
    -- on recherche l'ID de la monnaie de base pour la recherche de 3ème niveau
    if aDocCurrId <> ACS_FUNCTION.GetLocalCurrencyId then
      vLocCurId  := ACS_FUNCTION.GetLocalCurrencyId;

      -- si la monnaie de base est une monnaie Euro et que lka 2ème monnaie n'est pas l'Euro,
      -- on recherche l'ID de l'euro pour une recherche de 4ème niveau
      if     vDocEuroCurId is null
         and ACS_FUNCTION.IsFinCurrInEuro(ACS_FUNCTION.GetLocalCurrencyId, aRefDate) = 1 then
        vLocEuroCurId  := ACS_FUNCTION.GetEuroCurrency;
      end if;
    end if;

    vNormalThirdId     := aThirdId;
    GetNormalTariff(aGoodId
                  , vNormalThirdId
                  , aRecordId
                  , aDocCurrId
                  , vNormalDicTariff
                  , aQuantity
                  , aRefDate
                  , aTariffType
                  , aTarifficationMode
                  , vNormalTariffId
                  , aCurrencyId
                  , vDocEuroCurId
                  , vLocCurId
                  , vLocEuroCurId
                  , vNetNormal
                  , vNormalPrice
                  , vMandatory
                   );

    -- Si on a trouvé un tarif, la recherche du tarif action doit se faire dans la même monnaie
    if vNormalTariffId is not null then
      vDocEuroCurId  := aCurrencyId;
      vLocCurId      := aCurrencyId;
      vLocEuroCurId  := aCurrencyId;
    end if;

    vSpecialThirdId    := aThirdId;
    GetSpecialTariff(aGoodId
                   , vSpecialThirdId
                   , aRecordId
                   , aDocCurrId
                   , vSpecialDicTariff
                   , aQuantity
                   , aRefDate
                   , aTariffType
                   , aTarifficationMode
                   , vSpecialTariffId
                   , aCurrencyId
                   , vDocEuroCurId
                   , vLocCurId
                   , vLocEuroCurId
                   , vNetAction
                   , vSpecialPrice
                   , vMandatory
                    );

    -- si il y a lieu de comparer les prix, recherche des coeficient
    if     vSpecialTariffId is not null
       and vNormalTariffId is not null then
      -- recherche du coeficient à appliquer au prix pour la comparaison
      if aTariffType = 'A_FACTURER' then
        vNormalCoef   := GetSaleConvertFactor(aGoodId, vNormalThirdId) / GetSaleConvertFactor(aGoodId, null);
        vSpecialCoef  := GetSaleConvertFactor(aGoodId, vSpecialThirdId) / GetSaleConvertFactor(aGoodId, null);
      else
        vNormalCoef   := GetPurchaseConvertFactor(aGoodId, vNormalThirdId) / GetPurchaseConvertFactor(aGoodId, null);
        vSpecialCoef  := GetPurchaseConvertFactor(aGoodId, vSpecialThirdId) / GetPurchaseConvertFactor(aGoodId, null);
      end if;
    end if;

    -- code type tariff (achat/vente)
    if aTariffType = 'A_FACTURER' then
      vChargeType  := '1';
    else   -- aTariffType = 'A_PAYER'
      vChargeType  := '2';
    end if;

    -- si on a un tarif action
    if vSpecialTariffId is not null then
      if aQuantity = 0 then
        vQuantity  := 1;
      else
        vQuantity  := aQuantity;
      end if;

      -- si le tarif normal n'est pas net recherche du prix avec remises/taxes
      if     vNetNormal = 0
         and PCS.PC_CONFIG.GetBooleanConfig('PTC_COMPARE_WITH_CHARGE') then
        vNormalPrice  :=
          GetFullPrice(aGoodId
                     , vQuantity
                     , aThirdId
                     , aRecordId
                     , null   --gauge_id
                     , aDocCurrId
                     , aTariffType
                     , aTarifficationMode
                     , aDicTariffId
                     , aRefDate
                     , vChargeType
                     , null
                     , null
                     , 1   -- charge
                     , 1   -- discount
                     , vNormalTariffId
                      ) /
          vQuantity;
      end if;

      -- si le tariff action n'est pas net, recherche du prix avec remises/taxes
      if     vNetAction = 0
         and PCS.PC_CONFIG.GetBooleanConfig('PTC_COMPARE_WITH_CHARGE') then
        vSpecialPrice  :=
          GetFullPrice(aGoodId
                     , vQuantity
                     , aThirdId
                     , aRecordId
                     , null   --gauge_id
                     , aDocCurrId
                     , aTariffType
                     , aTarifficationMode
                     , aDicTariffId
                     , aRefDate
                     , vChargeType
                     , null
                     , null
                     , 1   -- charge
                     , 1   -- discount
                     , vSpecialTariffId
                      ) /
          vQuantity;
      end if;

      if (   vNormalTariffId is null
          or (vNormalPrice / vNormalCoef > vSpecialPrice / vSpecialCoef) ) then
        aFoundTariffId  := vSpecialTariffId;
        aThirdId        := vSpecialThirdId;
        aNet            := vNetAction;
        aSpecial        := 1;
        aDicTariffId    := vSpecialDicTariff;
      elsif vNormalTariffId is not null then
        aFoundTariffId  := vNormalTariffId;
        aThirdId        := vNormalThirdId;
        aNet            := vNetNormal;
        aDicTariffId    := vNormalDicTariff;
      end if;
    elsif vNormalTariffId is not null then
      aFoundTariffId  := vNormalTariffId;
      aThirdId        := vNormalThirdId;
      aNet            := vNetNormal;
      aDicTariffId    := vNormalDicTariff;
    end if;
  end GetTariff;

  /**
  * Description
  *    procedure de recherche du tarif normal (pas action)
  */
  procedure GetNormalTariff(
    aGoodId            in     number
  , aThirdId           in out number
  , aRecordId          in     number
  , aDocCurrId         in     number
  , aDicTariffId       in out varchar2
  , aQuantity          in     number
  , aRefDate           in     date
  , aTariffType        in     varchar2
  , aTarifficationMode        varchar2
  , aFoundTariffId     in out number
  , aCurrencyId        in out number
  , aDocEuroCurId      in     number
  , aLocCurId          in     number
  , aLocEuroCurId      in     number
  , aNet               in out number
  , aPrice             in out number
  , aMandatory         in     number
  )
  is
    vPurStruct        GCO_GOOD.DIC_PUR_TARIFF_STRUCT_ID%type;
    vSaleStruct       GCO_GOOD.DIC_SALE_TARIFF_STRUCT_ID%type;
    vFound            number(1);
    vThirdGroupId     PAC_THIRD.PAC_THIRD_ID%type;
    vThird1Id         PAC_THIRD.PAC_THIRD_ID%type;
    vThird2Id         PAC_THIRD.PAC_THIRD_ID%type;
    vDicTariffId      PTC_TARIFF.DIC_TARIFF_ID%type;
    vDicTariffGroupId PTC_TARIFF.DIC_TARIFF_ID%type;
    vDicTariffId0     PTC_TARIFF.DIC_TARIFF_ID%type;
    vDicTariffId1     PTC_TARIFF.DIC_TARIFF_ID%type;
    vDicTariffId2     PTC_TARIFF.DIC_TARIFF_ID%type;

    -- curseur sur les tarifs
    cursor crTariff(
      aGoodId            number
    , aTariffType        varchar2
    , aThirdId1          number
    , aThirdId2          number
    , aDicTariffID0      varchar2
    , aDicTariffID1      varchar2
    , aDicTariffID2      varchar2
    , aTarifficationMode varchar2
    , aPurStruct         varchar2
    , aSaleStruct        varchar2
    , aDocCurrId         number
    , aDocEuroCurId      number
    , aLocCurId          number
    , aLocEuroCurId      number
    , aRefDate           date
    , aMandatory         number
    )
    is
      select   PTC_TARIFF_ID
             , ACS_FINANCIAL_CURRENCY_ID
             , TRF_SQL_CONDITIONAL
             , TRF_NET_TARIFF
             , TRF_SPECIAL_TARIFF
             , PAC_THIRD_ID
             , DIC_TARIFF_ID
          from PTC_TARIFF
         where (   GCO_GOOD_ID = aGoodId
                or DIC_PUR_TARIFF_STRUCT_ID = vPurStruct
                or DIC_SALE_TARIFF_STRUCT_ID = vSaleStruct)
           and C_TARIFF_TYPE = aTariffType
           and ACS_FINANCIAL_CURRENCY_ID in(aDocCurrId, aDocEuroCurId, aLocCurId, aLocEuroCurId)
           and (   PAC_THIRD_ID in(aThirdId1, aThirdId2)
                or PAC_THIRD_ID is null)
           and trunc(aRefDate) between nvl(trunc(TRF_STARTING_DATE), to_date('31.12.1899', 'DD.MM.YYYY') )
                                   and nvl(trunc(TRF_ENDING_DATE), to_date('31.12.2999', 'DD.MM.YYYY') )
           and TRF_SPECIAL_TARIFF = 0
           and not(    aMandatory = 1
                   and not(   DIC_TARIFF_ID in(aDicTariffId1, aDicTariffId2)
                           or (    DIC_TARIFF_ID is null
                               and aDicTariffId0 is null) ) )
      order by decode(C_TARIFFICATION_MODE, aTarifficationMode, '1', 'UNIQUE', '2', '3' || C_TARIFFICATION_MODE)
             , decode(GCO_GOOD_ID, null, decode(aSaleStruct, null, decode(aPurStruct, null, '3', '2'), '2'), '1')
             , decode(PAC_THIRD_ID, aThirdId1, '1', aThirdId2, '2', '3')
             , case
                 when not(   nvl(DIC_TARIFF_ID, 'NULL') in(nvl(aDicTariffId1, 'NULL'), nvl(aDicTariffId2, 'NULL') )
                          or (    DIC_TARIFF_ID is null
                              and aDicTariffId0 is null)
                         ) then decode(ACS_FINANCIAL_CURRENCY_ID, aDocCurrId, '2', aDocEuroCurId, '3', aLocCurId, '4', aLocEuroCurId, '5')
                 else '1'
               end
             , decode(nvl(DIC_TARIFF_ID, 'NULL'), nvl(aDicTariffID0, 'NULL'), '1', aDicTariffID1, '2', aDicTariffID2, '3', '4' || dic_tariff_id)
             , decode(cleanstr(TRF_SQL_CONDITIONAL), null, '2', '1')
             , decode(ACS_FINANCIAL_CURRENCY_ID, aDocCurrId, '1', aDocEuroCurId, '2', aLocCurId, '3', aLocEuroCurId, '4')
             , decode(TRF_STARTING_DATE, null, to_date('31.12.1899', 'DD.MM.YYYY'), trunc(TRF_STARTING_DATE) ) desc
             , decode(TRF_ENDING_DATE, null, to_date('31.12.2999', 'DD.MM.YYYY'), trunc(TRF_ENDING_DATE) ) asc
             , TRF_DESCR asc;

    tplTariff         crTariff%rowtype;
  begin
    vDicTariffId0   := aDicTariffId;

    -- Document client
    if aTariffType = 'A_FACTURER' then
      if nvl(aThirdId, 0) <> 0 then
        -- recherche du code tariff et du tiers "groupe"
        begin
          select nvl(aDicTariffID, C1.DIC_TARIFF_ID)
               , nvl(C1.PAC_PAC_THIRD_1_ID, aThirdId)
            into vDicTariffID
               , vThirdGroupId
            from PAC_CUSTOM_PARTNER C1
           where C1.PAC_CUSTOM_PARTNER_ID = aThirdId;
        exception
          when no_data_found then
            null;
        end;

        if     vDicTariffId is null
           and vThirdGroupId is not null
           and vThirdGroupId <> aThirdId
           and PCS.PC_CONFIG.GetConfig('PTC_THIRD_GROUP_PRIORITY') <> '1' then
          select DIC_TARIFF_ID
            into vDicTariffGroupId
            from PAC_CUSTOM_PARTNER
           where PAC_CUSTOM_PARTNER_ID = vThirdGroupId;
        else
          vDicTariffGroupId  := vDicTariffId;
        end if;
      else
        vDicTariffGroupId  := aDicTariffId;
      end if;

      -- recherche de la structure tariffaire de vente
      select DIC_SALE_TARIFF_STRUCT_ID
        into vSaleStruct
        from GCO_GOOD
       where GCO_GOOD_ID = aGoodId;
    end if;

    -- Document fournisseur
    if aTariffType = 'A_PAYER' then
      if nvl(aThirdId, 0) <> 0 then
        begin
          -- recherche du code tariff et du tiers "groupe"
          select nvl(aDicTariffID, P1.DIC_TARIFF_ID)
               , nvl(P1.PAC_PAC_THIRD_1_ID, aThirdId)
            into vDicTariffID
               , vThirdGroupId
            from PAC_SUPPLIER_PARTNER P1
           where P1.PAC_SUPPLIER_PARTNER_ID = aThirdId;
        exception
          when no_data_found then
            null;
        end;

        if     vDicTariffId is null
           and vThirdGroupId is not null
           and vThirdGroupId <> aThirdId
           and PCS.PC_CONFIG.GetConfig('PTC_THIRD_GROUP_PRIORITY') <> '1' then
          select DIC_TARIFF_ID
            into vDicTariffGroupId
            from PAC_SUPPLIER_PARTNER
           where PAC_SUPPLIER_PARTNER_ID = vThirdGroupId;
        else
          vDicTariffGroupId  := vDicTariffId;
        end if;
      else
        vDicTariffGroupId  := aDicTariffId;
      end if;

      -- recherche de la structure tariffaire d'achat
      select DIC_PUR_TARIFF_STRUCT_ID
        into vPurStruct
        from GCO_GOOD
       where GCO_GOOD_ID = aGoodId;
    end if;

    -- only third (default)
    if PCS.PC_CONFIG.GetConfig('PTC_THIRD_GROUP_PRIORITY') = '1' then
      vThird1Id      := aThirdId;
      vThird2Id      := aThirdId;
      vDicTariffId1  := aDicTariffId;
      vDicTariffId2  := aDicTariffId;
    -- only third group
    elsif PCS.PC_CONFIG.GetConfig('PTC_THIRD_GROUP_PRIORITY') = '2' then
      vThird1Id      := nvl(vThirdGroupId, 0);
      vThird2Id      := nvl(vThirdGroupId, 0);
      vDicTariffId1  := vDicTariffGroupId;
      vDicTariffId2  := vDicTariffGroupId;
    -- first third, second group
    elsif PCS.PC_CONFIG.GetConfig('PTC_THIRD_GROUP_PRIORITY') = '3' then
      vThird1Id      := aThirdId;
      vThird2Id      := nvl(vThirdGroupId, aThirdId);
      vDicTariffId1  := aDicTariffId;
      vDicTariffId2  := nvl(vDicTariffGroupId, aDicTariffId);
    -- first group, second third
    elsif PCS.PC_CONFIG.GetConfig('PTC_THIRD_GROUP_PRIORITY') = '4' then
      vThird1Id      := nvl(vThirdGroupId, aThirdId);
      vThird2Id      := aThirdId;
      vDicTariffId1  := nvl(vDicTariffGroupId, aDicTariffId);
      vDicTariffId2  := aDicTariffId;
    end if;

    vFound          := 0;

    -- ouverture du curseur
    -- le premier tuple contient le tariff qui correspond le mieux aux critères passés
    -- en paramètre. Seul la condition SQL doit encore être validée
    open crTariff(aGoodId
                , aTariffType
                , vThird1Id
                , vThird2Id
                , vDicTariffId0
                , vDicTariffId1
                , vDicTariffId2
                , aTarifficationMode
                , vPurStruct
                , vSaleStruct
                , aDocCurrId
                , aDocEuroCurId
                , aLocCurId
                , aLocEuroCurId
                , aRefDate
                , aMandatory
                 );

    -- positionnement sur le premier tuple
    fetch crTariff
     into tplTariff;

    -- valeurs de retour pas défaut
    aFoundTariffId  := null;
    aCurrencyId     := null;

    -- boucle tant que le tarif n'a pas été validé
    while crTariff%found
     and vFound = 0 loop
      -- si il y a une condition SQL
      if cleanstr(tplTariff.trf_sql_conditional) is not null then
        -- si la condition SQL est vérifiée, le tarif est OK
        if     ConditionTest(aThirdId, aRecordId, tplTariff.trf_sql_conditional) = 1
           and testQty(tplTariff.PTC_TARIFF_ID, aQuantity) then
          vFound          := 1;
          aFoundTariffId  := tplTariff.PTC_TARIFF_ID;
          aNet            := tplTariff.trf_net_tariff;
          aCurrencyId     := tplTariff.ACS_FINANCIAL_CURRENCY_ID;
          aThirdId        := tplTariff.PAC_THIRD_ID;
          aDicTariffId    := tplTariff.DIC_TARIFF_ID;
        end if;
      -- si il n'y a pas de condition SQL, le tarif est OK
      elsif testQty(tplTariff.PTC_TARIFF_ID, aQuantity) then
        vFound          := 1;
        aNet            := tplTariff.trf_net_tariff;
        aFoundTariffId  := tplTariff.PTC_TARIFF_ID;
        aCurrencyId     := tplTariff.ACS_FINANCIAL_CURRENCY_ID;
        aThirdId        := tplTariff.PAC_THIRD_ID;
        aDicTariffId    := tplTariff.DIC_TARIFF_ID;
      end if;

      -- tuple suivant
      fetch crTariff
       into tplTariff;
    end loop;

    -- recherche du prix pour comparaison
    if vFound = 1 then
      select max(TTA_PRICE)
        into aPrice
        from PTC_TARIFF_TABLE
       where PTC_TARIFF_ID = aFoundTariffId
         and aQuantity between TTA_FROM_QUANTITY and decode(TTA_TO_QUANTITY, 0, 9999999999999999, TTA_TO_QUANTITY);
    end if;

    -- fermeture du curseur
    close crTariff;
  end GetNormalTariff;

  /**
  * Description
  *    procedure de recherche du tarif spécial "ACTION"
  */
  procedure GetSpecialTariff(
    aGoodId            in     number
  , aThirdID           in out number
  , aRecordId          in     number
  , aDocCurrId         in     number
  , aDicTariffId       in out varchar2
  , aQuantity          in     number
  , aRefDate           in     date
  , aTariffType        in     varchar2
  , aTarifficationMode        varchar2
  , aFoundTariffId     in out number
  , aCurrencyId        in out number
  , aDocEuroCurId      in     number
  , aLocCurId          in     number
  , aLocEuroCurId      in     number
  , aNet               in out number
  , aPrice             in out number
  , aMandatory         in     number
  )
  is
    vPurStruct        GCO_GOOD.DIC_PUR_TARIFF_STRUCT_ID%type;
    vSaleStruct       GCO_GOOD.DIC_SALE_TARIFF_STRUCT_ID%type;
    vFound            number(1);
    vThirdGroupId     PAC_THIRD.PAC_THIRD_ID%type;
    vThird1Id         PAC_THIRD.PAC_THIRD_ID%type;
    vThird2Id         PAC_THIRD.PAC_THIRD_ID%type;
    vDicTariffGroupId PTC_TARIFF.DIC_TARIFF_ID%type;
    vDicTariffId0     PTC_TARIFF.DIC_TARIFF_ID%type;
    vDicTariffId1     PTC_TARIFF.DIC_TARIFF_ID%type;
    vDicTariffId2     PTC_TARIFF.DIC_TARIFF_ID%type;

    -- curseur sur les tarifs
    cursor crTariff(
      aGoodId            number
    , aTariffType        varchar2
    , aThirdId1          number
    , aThirdId2          number
    , aDicTariffID0      varchar2
    , aDicTariffID1      varchar2
    , aDicTariffID2      varchar2
    , aTarifficationMode varchar2
    , vPurStruct         varchar2
    , vSaleStruct        varchar2
    , aDocCurrId         number
    , aDocEuroCurId      number
    , aLocCurId          number
    , aLocEuroCurId      number
    , aRefDate           date
    , aMandatory         number
    )
    is
      select   PTC_TARIFF_ID
             , ACS_FINANCIAL_CURRENCY_ID
             , TRF_SQL_CONDITIONAL
             , TRF_NET_TARIFF
             , TRF_SPECIAL_TARIFF
             , PAC_THIRD_ID
          from PTC_TARIFF
         where (   GCO_GOOD_ID = aGoodId
                or DIC_PUR_TARIFF_STRUCT_ID = vPurStruct
                or DIC_SALE_TARIFF_STRUCT_ID = vSaleStruct)
           and C_TARIFF_TYPE = aTariffType
           and acs_financial_currency_id in(aDocCurrId, aDocEuroCurId, aLocCurId, aLocEuroCurId)
           and (   PAC_THIRD_ID in(aThirdId1, aThirdId2)
                or PAC_THIRD_ID is null)
           and trunc(aRefDate) between nvl(trunc(TRF_STARTING_DATE), to_date('31.12.1899', 'DD.MM.YYYY') )
                                   and nvl(trunc(TRF_ENDING_DATE), to_date('31.12.2999', 'DD.MM.YYYY') )
           and TRF_SPECIAL_TARIFF = 1
           and not(    aMandatory = 1
                   and not(   DIC_TARIFF_ID in(aDicTariffId1, aDicTariffId2)
                           or (    DIC_TARIFF_ID is null
                               and aDicTariffId0 is null) ) )
      order by decode(C_TARIFFICATION_MODE, aTarifficationMode, '1', 'UNIQUE', '2', '3' || C_TARIFFICATION_MODE)
             , decode(gco_good_id, null, decode(vSaleStruct, null, decode(vPurStruct, null, '3', '2'), '2'), '1')
             , decode(pac_third_id, aThirdId1, '1', aThirdId2, '2', '3')
             , case
                 when not(   nvl(DIC_TARIFF_ID, 'NULL') in(nvl(aDicTariffId1, 'NULL'), nvl(aDicTariffId2, 'NULL') )
                          or (    DIC_TARIFF_ID is null
                              and aDicTariffId0 is null)
                         ) then decode(ACS_FINANCIAL_CURRENCY_ID, aDocCurrId, '2', aDocEuroCurId, '3', aLocCurId, '4', aLocEuroCurId, '5')
                 else '1'
               end
             , decode(nvl(DIC_TARIFF_ID, 'NULL'), nvl(aDicTariffID0, 'NULL'), '1', aDicTariffID1, '2', aDicTariffID2, '3', '4' || dic_tariff_id)
             , decode(cleanstr(trf_sql_conditional), null, '2', '1')
             , decode(ACS_FINANCIAL_CURRENCY_ID, aDocCurrId, '1', aDocEuroCurId, '2', aLocCurId, '3', aLocEuroCurId, '4')
             , decode(TRF_STARTING_DATE, null, to_date('31.12.1899', 'DD.MM.YYYY'), trunc(TRF_STARTING_DATE) ) desc
             , decode(TRF_ENDING_DATE, null, to_date('31.12.2999', 'DD.MM.YYYY'), trunc(TRF_ENDING_DATE) ) asc
             , TRF_DESCR asc;

    tplTariff         crTariff%rowtype;
  begin
    -- Document client
    if aTariffType = 'A_FACTURER' then
      if nvl(aThirdId, 0) <> 0 then
        begin
          -- recherche de la structure tariffaire par rapport au client
          -- if third does not belong to a group, thirdgroupid will be equal to thirdId
          select nvl(aDicTariffID, DIC_TARIFF_ID)
               , nvl(PAC_PAC_THIRD_1_ID, aThirdId)
            into aDicTariffID
               , vThirdGroupId
            from PAC_CUSTOM_PARTNER
           where PAC_CUSTOM_PARTNER_ID = aThirdId;
        exception
          when no_data_found then
            null;
        end;

        if     aDicTariffId is null
           and vThirdGroupId is not null
           and vThirdGroupId <> aThirdId
           and PCS.PC_CONFIG.GetConfig('PTC_THIRD_GROUP_PRIORITY') <> '1' then
          select DIC_TARIFF_ID
            into vDicTariffGroupId
            from PAC_CUSTOM_PARTNER
           where PAC_CUSTOM_PARTNER_ID = vThirdGroupId;
        else
          vDicTariffGroupId  := aDicTariffId;
        end if;
      else
        vDicTariffGroupId  := aDicTariffId;
      end if;

      -- recherche de la structure tariffaire de vente
      select DIC_SALE_TARIFF_STRUCT_ID
        into vSaleStruct
        from GCO_GOOD
       where GCO_GOOD_ID = aGoodId;
    end if;

    -- Document fournisseur
    if aTariffType = 'A_PAYER' then
      if nvl(aThirdId, 0) <> 0 then
        -- recherche de la structure tariffaire par rapport au fournisseur
        -- if third does not belong to a group, thirdgroupid will be equal to thirdId
        begin
          select nvl(aDicTariffID, DIC_TARIFF_ID)
               , nvl(PAC_PAC_THIRD_1_ID, aThirdId)
            into aDicTariffID
               , vThirdGroupId
            from PAC_SUPPLIER_PARTNER
           where PAC_SUPPLIER_PARTNER_ID = aThirdId;
        exception
          when no_data_found then
            null;
        end;

        if     aDicTariffId is null
           and vThirdGroupId is not null
           and vThirdGroupId <> aThirdId
           and PCS.PC_CONFIG.GetConfig('PTC_THIRD_GROUP_PRIORITY') <> '1' then
          select DIC_TARIFF_ID
            into vDicTariffGroupId
            from PAC_SUPPLIER_PARTNER
           where PAC_SUPPLIER_PARTNER_ID = vThirdGroupId;
        else
          vDicTariffGroupId  := aDicTariffId;
        end if;
      else
        vDicTariffGroupId  := aDicTariffId;
      end if;

      -- recherche de la structure tariffaire d'achat
      select DIC_PUR_TARIFF_STRUCT_ID
        into vPurStruct
        from GCO_GOOD
       where GCO_GOOD_ID = aGoodId;
    end if;

    -- only third (default)
    if PCS.PC_CONFIG.GetConfig('PTC_THIRD_GROUP_PRIORITY') = '1' then
      vThird1Id      := aThirdId;
      vThird2Id      := aThirdId;
      vDicTariffId1  := aDicTariffId;
      vDicTariffId2  := aDicTariffId;
    -- only third group
    elsif PCS.PC_CONFIG.GetConfig('PTC_THIRD_GROUP_PRIORITY') = '2' then
      vThird1Id      := nvl(vThirdGroupId, 0);
      vThird2Id      := nvl(vThirdGroupId, 0);
      vDicTariffId1  := vDicTariffGroupId;
      vDicTariffId2  := vDicTariffGroupId;
    -- first third, second group
    elsif PCS.PC_CONFIG.GetConfig('PTC_THIRD_GROUP_PRIORITY') = '3' then
      vThird1Id      := aThirdId;
      vThird2Id      := nvl(vThirdGroupId, aThirdId);
      vDicTariffId1  := aDicTariffId;
      vDicTariffId2  := nvl(vDicTariffGroupId, aDicTariffId);
    -- first group, second third
    elsif PCS.PC_CONFIG.GetConfig('PTC_THIRD_GROUP_PRIORITY') = '4' then
      vThird1Id      := nvl(vThirdGroupId, aThirdId);
      vThird2Id      := aThirdId;
      vDicTariffId1  := nvl(vDicTariffGroupId, aDicTariffId);
      vDicTariffId2  := aDicTariffId;
    end if;

    vFound          := 0;

    -- ouverture du curseur
    -- le premier tuple contient le crTariff qui correspond le mieux aux critères passés
    -- en paramètre. Seul la condition SQL doit encore être validée
    open crTariff(aGoodId
                , aTariffType
                , vThird1Id
                , vThird2Id
                , vDicTariffId0
                , vDicTariffId1
                , vDicTariffId2
                , aTarifficationMode
                , vPurStruct
                , vSaleStruct
                , aDocCurrId
                , aDocEuroCurId
                , aLocCurId
                , aLocEuroCurId
                , aRefDate
                , aMandatory
                 );

    -- positionnement sur le premier tuple
    fetch crTariff
     into tplTariff;

    -- valeurs de retour pas défaut
    aFoundTariffId  := null;

    -- boucle tant que le tarif n'a pas été validé
    while crTariff%found
     and vFound = 0 loop
      -- si il y a une condition SQL
      if cleanStr(tplTariff.trf_sql_conditional) is not null then
        -- si la condition SQL est vérifiée, le tarif est OK
        if     ConditionTest(aThirdId, aRecordId, tplTariff.trf_sql_conditional) = 1
           and testQty(tplTariff.PTC_TARIFF_ID, aQuantity) then
          vFound          := 1;
          aFoundTariffId  := tplTariff.PTC_TARIFF_ID;
          aCurrencyId     := tplTariff.ACS_FINANCIAL_CURRENCY_ID;
          aThirdId        := tplTariff.PAC_THIRD_ID;
        end if;
      -- si il n'y a pas de condition SQL, le tarif est OK
      elsif testQty(tplTariff.PTC_TARIFF_ID, aQuantity) then
        vFound          := 1;
        aFoundTariffId  := tplTariff.PTC_TARIFF_ID;
        aCurrencyId     := tplTariff.ACS_FINANCIAL_CURRENCY_ID;
        aThirdId        := tplTariff.PAC_THIRD_ID;
      end if;

      -- tuple suivant
      fetch crTariff
       into tplTariff;
    end loop;

    -- recherche du prix pour comparaison
    if vFound = 1 then
      select max(TTA_PRICE)
        into aPrice
        from PTC_TARIFF_TABLE
       where PTC_TARIFF_ID = aFoundTariffId
         and aQuantity between TTA_FROM_QUANTITY and decode(TTA_TO_QUANTITY, 0, 9999999999999999, TTA_TO_QUANTITY);

      aNet  := tplTariff.trf_net_tariff;
    end if;

    -- fermeture du curseur
    close crTariff;
  end GetSpecialTariff;

  /**
  * Description
  *    procedure de recherche de la liste des tarifs applicables
  *    à une situation
  */
  procedure GetAllTariff(
    aGoodId            in     number
  , aThirdId           in     number
  , aRecordId          in     number
  , aDocCurrId         in     number
  , aDicTariffId       in out varchar2
  , aRefDate           in     date
  , aTariffType        in     varchar2
  , aTarifficationMode        varchar2
  , aDateSelectionMode        varchar2 default '0'
  , aListTariffId      in out varchar2
  )
  is
    aDocEuroCurId ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    aLocCurId     ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    aLocEuroCurId ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    vPurStruct    GCO_GOOD.DIC_PUR_TARIFF_STRUCT_ID%type;
    vSaleStruct   GCO_GOOD.DIC_SALE_TARIFF_STRUCT_ID%type;
    vFound        number(1);

    -- curseur sur les tarifs
    cursor crTariff(
      aGoodId            number
    , aTariffType        varchar2
    , aThirdId           number
    , aDicTariffId       varchar2
    , aTarifficationMode varchar2
    , vPurStruct         varchar2
    , vSaleStruct        varchar2
    , aDocCurrId         number
    , aDocEuroCurId      number
    , aLocCurId          number
    , aLocEuroCurId      number
    , aRefDate           date
    , cDateSelectionMode varchar2
    )
    is
      select   ptc_tariff_id
             , acs_financial_currency_id
             , trf_sql_conditional
          from PTC_TARIFF
         where (   GCO_GOOD_ID = aGoodId
                or DIC_PUR_TARIFF_STRUCT_ID = vPurStruct
                or DIC_SALE_TARIFF_STRUCT_ID = vSaleStruct)
           and C_TARIFF_TYPE = aTariffType
           and acs_financial_currency_id in(aDocCurrId, aDocEuroCurId, aLocCurId, aLocEuroCurId)
           and (   PAC_THIRD_ID = aThirdId
                or PAC_THIRD_ID is null)
           and trunc(aRefDate) between decode(cDateSelectionMode
                                            , '3', trunc(aRefDate)
                                            , '1', trunc(aRefDate)
                                            , nvl(trunc(TRF_STARTING_DATE), to_date('31.12.1899', 'DD.MM.YYYY') )
                                             )
                                   and decode(cDateSelectionMode
                                            , '3', trunc(aRefDate)
                                            , '2', trunc(aRefDate)
                                            , nvl(trunc(TRF_ENDING_DATE), to_date('31.12.2999', 'DD.MM.YYYY') )
                                             )
           and not(    PCS.PC_CONFIG.GetConfig('PTC_MANDATORY_TARIFF') = '1'
                   and not DIC_TARIFF_ID = aDicTariffId)
      order by decode(C_TARIFFICATION_MODE, aTarifficationMode, '1', 'UNIQUE', '2', '3' || C_TARIFFICATION_MODE)
             , decode(gco_good_id, null, decode(vSaleStruct, null, decode(vPurStruct, null, '3', '2'), '2'), '1')
             , decode(pac_third_id, aThirdId, '1', '2')
             , decode(dic_tariff_id, aDicTariffId, '1', '2' || dic_tariff_id)
             , decode(cleanstr(trf_sql_conditional), null, '2', '1')
             , decode(ACS_FINANCIAL_CURRENCY_ID, aDocCurrId, '1', aDocEuroCurId, '2', aLocCurId, '3', aLocEuroCurId, '4')
             , decode(TRF_STARTING_DATE, null, to_date('31.12.1899', 'DD.MM.YYYY'), trunc(TRF_STARTING_DATE) ) desc
             , decode(TRF_ENDING_DATE, null, to_date('31.12.2999', 'DD.MM.YYYY'), trunc(TRF_ENDING_DATE) ) asc
             , TRF_DESCR asc;

    tplTariff     crTariff%rowtype;
  begin
    -- si la monnaie document est une monanie Euro,
    -- on recherche l'ID de l'Euro pour la recherche de 2ème niveau
    if ACS_FUNCTION.IsFinCurrInEuro(aDocCurrId, aRefDate) = 1 then
      aDocEuroCurId  := ACS_FUNCTION.GetEuroCurrency;
    end if;

    -- si la monnaie document est différente de la monnaie de base,
    -- on recherche l'ID de la monnaie de base pour la recherche de 3ème niveau
    if    aDocCurrId <> ACS_FUNCTION.GetLocalCurrencyId
       or aDocCurrId is null then
      aLocCurId  := ACS_FUNCTION.GetLocalCurrencyId;

      -- si la monnaie de base est une monnaie Euro et que lka 2ème monnaie n'est pas l'Euro,
      -- on recherche l'ID de l'euro pour une recherche de 4ème niveau
      if     aDocEuroCurId is null
         and ACS_FUNCTION.IsFinCurrInEuro(ACS_FUNCTION.GetLocalCurrencyId, aRefDate) = 1 then
        aLocEuroCurId  := ACS_FUNCTION.GetEuroCurrency;
      end if;
    end if;

    -- Document client
    if aTariffType = 'A_FACTURER' then
      -- recherche de la structure tariffaire par rapport au client
      select nvl(aDicTariffId, max(DIC_TARIFF_ID) )
        into aDicTariffId
        from PAC_CUSTOM_PARTNER
       where PAC_CUSTOM_PARTNER_ID = aThirdId;

      -- recherche de la structure tariffaire de vente
      select DIC_SALE_TARIFF_STRUCT_ID
        into vSaleStruct
        from GCO_GOOD
       where GCO_GOOD_ID = aGoodId;
    end if;

    -- Document fournisseur
    if aTariffType = 'A_PAYER' then
      -- recherche de la structure tariffaire par rapport au fournisseur
      select nvl(aDicTariffId, max(DIC_TARIFF_ID) )
        into aDicTariffId
        from PAC_SUPPLIER_PARTNER
       where PAC_SUPPLIER_PARTNER_ID = aThirdId;

      -- recherche de la structure tariffaire d'achat
      select DIC_PUR_TARIFF_STRUCT_ID
        into vPurStruct
        from GCO_GOOD
       where GCO_GOOD_ID = aGoodId;
    end if;

    vFound         := 0;

    -- ouverture du curseur
    -- le premier tuple contient le crTariff qui correspond le mieux aux critères passés
    -- en paramètre. Seul la condition SQL doit encore être validée
    open crTariff(aGoodId
                , aTariffType
                , aThirdId
                , aDicTariffId
                , aTarifficationMode
                , vPurStruct
                , vSaleStruct
                , aDocCurrId
                , aDocEuroCurId
                , aLocCurId
                , aLocEuroCurId
                , aRefDate
                , aDateSelectionMode
                 );

    -- positionnement sur le premier tuple
    fetch crTariff
     into tplTariff;

    -- valeurs de retour pas défaut
    aListTariffId  := '0';

    -- boucle tant que le tarif n'a pas été validé
    while crTariff%found loop
      -- si il y a une condition SQL
      if cleanstr(tplTariff.trf_sql_conditional) is not null then
        -- si la condition SQL est vérifiée, le tarif est OK
        if ConditionTest(aThirdId, aRecordId, tplTariff.trf_sql_conditional) = 1 then
          aListTariffId  := aListTariffId || ',' || to_char(tplTariff.PTC_TARIFF_ID);
        end if;
      -- si il n'y a pas de condition SQL, le tarif est OK
      else
        aListTariffId  := aListTariffId || ',' || to_char(tplTariff.PTC_TARIFF_ID);
      end if;

      -- tuple suivant
      fetch crTariff
       into tplTariff;
    end loop;

    -- fermeture du curseur
    close crTariff;
  end GetAllTariff;

  /**
  * Description
  *   fonction renvoyant l'id du crTariff s'appliquant à un bien, un tiers et un dossier
  *   Encapsulation de la procedure GetTariff. Cette fonction n'était pas réalisable en Oracle7,
  *   on était obligé de passer par une procedure si on utilisait le package DBMS_SQL
  */
  function GetTariffDirect(
    aGoodId            in number
  , aThirdId           in number
  , aRecordId          in number
  , aDocCurrId         in number
  , aDicTariffId       in varchar2
  , aQuantity          in number
  , aRefDate           in date
  , aTariffType        in varchar2
  , aTarifficationMode    varchar2
  )
    return number
  is
    vFoundTariffId number(18, 6);
    vCurrencyId    number(12);
    vNet           number(1);
    vSpecial       number(1);
    vDicTariffId   varchar2(10);
    vThirdId       number(12);
  begin
    vDicTariffId  := aDicTariffId;
    vThirdId      := aThirdId;
    PTC_FIND_TARIFF.GetTariff(aGoodId
                            , vThirdId
                            , aRecordId
                            , aDocCurrId
                            , vDicTariffId
                            , aQuantity
                            , aRefDate
                            , aTariffType
                            , aTarifficationMode
                            , vFoundTariffId
                            , vCurrencyId
                            , vNet
                            , vSpecial
                             );
    return vFoundTariffId;
  end GetTariffDirect;

  /**
  * Description
  *          recherche du prix selon l'id du tarif et la quantité
  */
  function GetTariffPrice(aTariffId in number, aQuantity in number, aRoundType out varchar2, aRoundAmount out number, aTariffUnit out number, aFlat out number)
    return number
  is
    vResult number(18, 6);
  begin
    select max(TTA_PRICE / decode(TTA_FLAT_RATE, 1, 1, decode(nvl(TRF_UNIT, 0), 0, 1, TRF_UNIT) ) )
         , max(C_ROUND_TYPE)
         , max(TRF_ROUND_AMOUNT)
         , max(TRF_UNIT)
         , max(TTA_FLAT_RATE)
      into vResult
         , aRoundType
         , aRoundAmount
         , aTariffUnit
         , aFlat
      from PTC_TARIFF_TABLE TTA
         , PTC_TARIFF TRF
     where TRF.PTC_TARIFF_ID = aTariffId
       and TTA.PTC_TARIFF_ID = TRF.PTC_TARIFF_ID
       and aQuantity between TTA_FROM_QUANTITY and decode(TTA_TO_QUANTITY, 0, 999999999999999999, TTA_TO_QUANTITY);

    -- en cas de tarif forfaitaire, on calcule le prix unitaire
    if     aFlat = 1
       and aQuantity <> 0 then
      vResult  := vResult / aQuantity;
    end if;

    return vResult;
  end GetTariffPrice;

  /**
  * Description
  *          recherche du prix selon l'id du tarif et la quantité
  */
  function GetTariffPrice(aTariffId in number, aQuantity in number, aRoundType out varchar2, aRoundAmount out number, aFlat out number)
    return number
  is
    tariffUnit DOC_POSITION.POS_TARIFF_UNIT%type;
    vResult    number(18, 6);
  begin
    return GetTariffPrice(aTariffId, aQuantity, aRoundType, aRoundAmount, tariffUnit, aFlat);
  end GetTariffPrice;

  /**
  * Description
  *          recherche du prix selon l'id du tarif et la quantité
  */
  function GetTariffPrice(aTariffId in number, aQuantity in number)
    return number
  is
    vResult     number(18, 6);
    roundType   varchar2(10);
    roundAmount number(18, 6);
    lFlat       number(1);
  begin
    vResult  := GetTariffPrice(aTariffId, aQuantity, roundType, roundAmount, lFlat);
    return vResult;
  end GetTariffPrice;

  /**
  * Description
  *   Teste une condition SQL et renvoie 1 si le select renvoie des valeurs
  */
  function ConditionTest(aThirdId number, aRecordId number, aDEF_CONDITION varchar2)
    return number
  is
    SqlCommand    PTC_TARIFF.TRF_SQL_CONDITIONAL%type;
    ReturnValue   number(1)                             default 0;
    DynamicCursor integer;
    ErrorCursor   integer;
  begin
    begin
      -- remplace le paramètre DOC_RECORD_ID s'il est présent
      SqlCommand     := replace(aDEF_CONDITION, ':DOC_RECORD_ID', to_char(aRecordId) );
      -- remplace le(s) éventuel(s) paramètre(s) restant(s) par l'id du tiers
      SqlCommand     := ReplaceParam(SqlCommand, aThirdId);
      --raise_application_error(-20000, SqlCommand);

      -- Attribution d'un Handle de curseur
      DynamicCursor  := DBMS_SQL.open_cursor;
      -- Vérification de la syntaxe de la commande SQL
      DBMS_SQL.Parse(DynamicCursor, SqlCommand, DBMS_SQL.V7);
      -- Exécution de la commande SQL
      ErrorCursor    := DBMS_SQL.execute(DynamicCursor);

      -- Obtenir le tuple suivant
      if DBMS_SQL.fetch_rows(DynamicCursor) > 0 then
        ReturnValue  := 1;
      end if;

      -- Ferme le curseur
      DBMS_SQL.close_cursor(DynamicCursor);
    exception
      when others then
        if DBMS_SQL.is_open(DynamicCursor) then
          DBMS_SQL.close_cursor(DynamicCursor);
          raise_application_error(-20000, 'Mauvaise commande : ' || aDef_Condition || chr(13) || SqlCommand);
        end if;
    end;

    return ReturnValue;
  end ConditionTest;

  /**
  * Description
  *   Remplace les paramètres dans une requête SQl
  */
  function ReplaceParam(aSqlCommand varchar2, aId number)
    return varchar2
  is
    ParamPos     number(4);
    ParamLength1 number(4);
    ParamLength2 number(4);
    ParamLength  number(4);
    Parameter    varchar2(30);
    SqlCommand   ACS_DEFAULT_ACCOUNT.DEF_CONDITION%type;
  begin
    SqlCommand  := aSqlCommand;
    ParamPos    := instr(aSqlCommand, ':');

    if ParamPos > 0 then
      ParamLength1  := instr(substr(aSqlCommand, ParamPos), ' ');

      if instr(substr(aSqlCommand, ParamPos), chr(13) || chr(10) ) > 0 then
        ParamLength2  := instr(substr(aSqlCommand, ParamPos), chr(13) || chr(10) );
      else
        ParamLength2  := length(aSqlCommand) - ParamPos + 2;
      end if;

      if     (ParamLength1 > ParamLength2)
         and (ParamLength2 > 0) then
        ParamLength  := ParamLength2;
      elsif     (ParamLength1 > ParamLength2)
            and (ParamLength2 = 0) then
        ParamLength  := ParamLength1;
      elsif     (ParamLength1 < ParamLength2)
            and (ParamLength1 > 0) then
        ParamLength  := ParamLength1;
      elsif     (ParamLength1 < ParamLength2)
            and (ParamLength1 = 0) then
        ParamLength  := ParamLength2;
      else
        ParamLength  := 0;
      end if;

      if ParamLength > 0 then
        Parameter  := substr(aSqlCommand, ParamPos, ParamLength - 1);
      else
        Parameter  := substr(aSqlCommand, ParamPos);
      end if;

      SqlCommand    := replace(aSqlCommand, Parameter, to_char(aId) );
    end if;

    return SqlCommand;
  end ReplaceParam;

  /**
  * Description
  *      Recherche et retourne le crTariff pour un bien/tiers/date... dans la monnaie passée en paramètre
  */
  procedure GetTariffConverted(
    aGoodId         in     DOC_POSITION.GCO_GOOD_ID%type   /*Bien*/
  , aQty            in     DOC_POSITION.POS_BASIS_QUANTITY%type   /*Qty*/
  , aThirdId        in     DOC_DOCUMENT.PAC_THIRD_ID%type   /*Tiers*/
  , aRecordId       in     DOC_DOCUMENT.DOC_RECORD_ID%type   /*Dossier*/
  , aConfigGaugeId  in     DOC_DOCUMENT.DOC_GAUGE_ID%type   /*Gabarit document*/
  , aCurrencyId     in     DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type   /* Monnaie du Document*/
  , aTarifType      in     PTC_TARIFF.C_TARIFF_TYPE%type   /*Mode de tariffication du partenaire*/
  , aTarifMode      in     PTC_TARIFF.C_TARIFFICATION_MODE%type   /*Mode de tariffication du partenaire*/
  , aTarifId        in     PTC_TARIFF.DIC_TARIFF_ID%type   /*Tarif*/
  , aDateRef        in     date   /* date de référence pour la recherche du cours logistique */
  , aGoodUnitPrice  in out DOC_POSITION.POS_GROSS_UNIT_VALUE%type   /*Prix unitaire du bien*/
  , aDiscountRate   in out DOC_INTERFACE_POSITION.DOP_DISCOUNT_RATE%type   /*Taux rabais*/
  , aGoodGrossPrice in out DOC_POSITION.POS_GROSS_UNIT_VALUE%type   /*Prix brut du bien*/
  , aNetPriceHt     in out DOC_POSITION.POS_NET_VALUE_EXCL%type   /*Valeur nette HT*/
  , aNetPriceTTC    in out DOC_POSITION.POS_NET_VALUE_INCL%type
  )   /*Valeur nette TTC*/
  is
    lNet           number(1);
    lSpecial       number(1);
    lFoundTariffId number(12);
    lFlat          number(1);
  begin
    GetTariffConverted(aGoodId
                     , aQty
                     , aThirdId
                     , aRecordId
                     , aConfigGaugeId
                     , aCurrencyId
                     , aTarifType
                     , aTarifMode
                     , aTarifId
                     , aDateRef
                     , aGoodUnitPrice
                     , aDiscountRate
                     , aGoodGrossPrice
                     , aNetPriceHt
                     , aNetPriceTTC
                     , lNet
                     , lSpecial
                     , lFlat
                     , lFoundTariffId
                      );
  end GetTariffConverted;

  /* Version 2 */
  procedure GetTariffConverted(
    aGoodId         in     DOC_POSITION.GCO_GOOD_ID%type   /*Bien*/
  , aQty            in     DOC_POSITION.POS_BASIS_QUANTITY%type   /*Qty*/
  , aThirdId        in     DOC_DOCUMENT.PAC_THIRD_ID%type   /*Tiers*/
  , aRecordId       in     DOC_DOCUMENT.DOC_RECORD_ID%type   /*Dossier*/
  , aConfigGaugeId  in     DOC_DOCUMENT.DOC_GAUGE_ID%type   /*Gabarit document*/
  , aCurrencyId     in     DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type   /* Monnaie du Document*/
  , aTarifType      in     PTC_TARIFF.C_TARIFF_TYPE%type   /*Mode de tariffication du partenaire*/
  , aTarifMode      in     PTC_TARIFF.C_TARIFFICATION_MODE%type   /*Mode de tariffication du partenaire*/
  , aTarifId        in     PTC_TARIFF.DIC_TARIFF_ID%type   /*Tarif*/
  , aDateRef        in     date   /* date de référence pour la recherche du cours logistique */
  , aGoodUnitPrice  in out DOC_POSITION.POS_GROSS_UNIT_VALUE%type   /*Prix unitaire du bien*/
  , aDiscountRate   in out DOC_INTERFACE_POSITION.DOP_DISCOUNT_RATE%type   /*Taux rabais*/
  , aGoodGrossPrice in out DOC_POSITION.POS_GROSS_UNIT_VALUE%type   /*Prix brut du bien*/
  , aNetPriceHt     in out DOC_POSITION.POS_NET_VALUE_EXCL%type   /*Valeur nette HT*/
  , aNetPriceTTC    in out DOC_POSITION.POS_NET_VALUE_INCL%type   /*Valeur nette TTC*/
  , aNet            in out PTC_TARIFF.TRF_NET_TARIFF%type   /*Tarif net*/
  , aSpecial        in out PTC_TARIFF.TRF_SPECIAL_TARIFF%type   /*Tarif spécial*/
  , aFlat           in out number
  , aFoundTariffId  in out PTC_TARIFF.PTC_TARIFF_ID%type
  , aTariffId       in     PTC_TARIFF.PTC_TARIFF_ID%type
  )   /* Tarif trouvé */
  is
    vTarifCurrencyId  ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    vThirdId          PAC_THIRD.PAC_THIRD_ID%type;
    vTarifId          PTC_TARIFF.DIC_TARIFF_ID%type;
    vRoundType        PTC_TARIFF.C_ROUND_TYPE%type;
    vRoundAmount      PTC_TARIFF.TRF_ROUND_AMOUNT%type;
    vGaugeRoundType   DOC_GAUGE_STRUCTURED.C_ROUND_TYPE%type;
    vGaugeRoundAmount DOC_GAUGE_STRUCTURED.GAS_ROUND_AMOUNT%type;
    lTariffUnit       PTC_TARIFF.TRF_UNIT%type;
    vEURAmount        DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    vConvertedAmount  DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    lRoundApplication DOC_GAUGE_POSITION.C_ROUND_APPLICATION%type;
  begin
    aGoodUnitPrice    := 0;
    aDiscountRate     := 0;
    aGoodGrossPrice   := 0;
    aNetPriceHt       := 0;
    aNetPriceTTC      := 0;
    aFoundTariffId    := null;
    aNet              := 0;
    aSpecial          := 0;
    vRoundType        := 0;
    vRoundAmount      := 0;
    vTarifCurrencyId  := aCurrencyId;
    vThirdId          := aThirdId;
    vTarifId          := aTarifId;

    if aTariffId is null then
      /* 1 - Recherche du tarif pour le bien,tiers...*/
      PTC_FIND_TARIFF.GetTariff(aGoodId
                              , vThirdId
                              , aRecordId
                              , aCurrencyId
                              , vTarifId
                              , aQty
                              , trunc(aDateRef)
                              , aTarifType
                              , aTarifMode
                              , aFoundTariffId
                              , vTarifCurrencyId
                              , aNet
                              , aSpecial
                               );
    else
      aFoundTariffId  := aTariffId;
    end if;

    /* 2 - Recherche prix selon tarif*/
    if aFoundTariffId <> 0 then
      begin
        select T.ACS_FINANCIAL_CURRENCY_ID
          into vTarifCurrencyId
          from PTC_TARIFF T
         where T.PTC_TARIFF_ID = aFoundTariffId;

        aGoodUnitPrice   := PTC_FIND_TARIFF.GetTariffPrice(aFoundTariffId, aQty, vRoundType, vRoundAmount, lTariffUnit, aFlat);

        /*Monnaie du document diffère de la monnaie du tarif*/
        if vTarifCurrencyId <> aCurrencyId then
          ACS_FUNCTION.ConvertAmount(aGoodUnitPrice   /*Prix selon tarif trouvé*/
                                   , vTarifCurrencyId   /*Monnaie tarif*/
                                   , aCurrencyId   /*Monnaie du document*/
                                   , trunc(aDateRef)   /*Date référence*/
                                   , 0
                                   , 0
                                   , 0   /*Pas d'Arrondi*/
                                   , vEURAmount   /*Montant Euro*/
                                   , vConvertedAmount   /*Montant converti*/
                                   , 5   /*Cours logistique*/
                                    );
          aGoodUnitPrice  := vConvertedAmount;
        end if;

        -- recherche de la méthode d'arrondi d'une position type "Bien"
        select max(GAP.C_ROUND_APPLICATION)
             , max(GAS.C_ROUND_TYPE)
             , max(GAS.GAS_ROUND_AMOUNT)
          into lRoundApplication
             , vGaugeRoundType
             , vGaugeRoundAmount
          from DOC_GAUGE_STRUCTURED GAS
             , DOC_GAUGE_POSITION GAP
         where GAS.DOC_GAUGE_ID = aConfigGaugeId
           and GAP.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
           and GAP.C_GAUGE_TYPE_POS = '1'
           and GAP.GAP_DEFAULT = 1;

        aGoodUnitPrice   :=
          DOC_POSITION_FUNCTIONS.roundPositionAmount(aAmount              => aGoodUnitPrice
                                                   , aDocCurrencyId       => vTarifCurrencyId
                                                   , aRoundApplication    => lRoundApplication
                                                   , aTariffRoundType     => vRoundType
                                                   , aTariffRoundAmount   => vRoundAmount
                                                   , aGaugeRoundType      => vGaugeRoundType
                                                   , aGaugeRoundAmount    => vGaugeRoundAmount
                                                    );
        aGoodGrossPrice  := aGoodUnitPrice -(aGoodUnitPrice * aDiscountRate / 100);
        aNetPriceHt      := aGoodUnitPrice * aQty;
        aNetPriceTtc     := aNetPriceHt;
      exception
        -- pas de tabelle pour la qté demandée
        when no_data_found then
          aFoundTariffId   := null;
          aGoodGrossPrice  := 0;
          aNetPriceHt      := 0;
          aNetPriceTtc     := 0;
      end;
    end if;
  end GetTariffConverted;

  /**
  * Description
  *    recherche un prix et le renvoie sous forme de memo détaillé
  *    avec les remises et taxes
  */
  procedure GetDetailledPrice(
    aGivenPrice        in     number
  , aGoodId            in     number
  , aQuantity          in     number
  , aThirdId           in     number
  , aRecordId          in     number
  , aGaugeId           in     number
  , aCurrencyId        in     number
  , aTariffType        in     varchar2
  , aTarifficationMode in     varchar2
  , aDicTariffId       in     varchar2
  , aDateRef           in     date
  , aChargeType        in     varchar2
  , aPositionId        in     number
  , aDocumentId        in     number
  , aBlnCharge         in     number
  , aBlnDiscount       in     number
  , aLangId            in     number
  , aFormattedPrice    out    varchar2
  , aGoodUnitPrice     out    DOC_POSITION.POS_NET_UNIT_VALUE%type
  , aDiscountRate      out    PTC_DISCOUNT.DNT_RATE%type
  , aGoodGrossPrice    out    DOC_POSITION.POS_GROSS_UNIT_VALUE%type
  , aNetPriceHt        out    DOC_POSITION.POS_NET_VALUE_EXCL%type
  , aNetPriceTtc       out    DOC_POSITION.POS_NET_VALUE_INCL%type
  , aNetTariff         out    DOC_POSITION.POS_NET_TARIFF%type
  , aSpecialTariff     out    DOC_POSITION.POS_SPECIAL_TARIFF%type
  , aFlat              out    number
  )
  is
    -- curseur sur les remises et taxes
    cursor crDiscountCharge(astrChargeList varchar2, astrDiscountList varchar2, lang_id number)
    is
      select   DNT.PTC_DISCOUNT_ID
             , 0 PTC_CHARGE_ID
             , nvl(DNT_IN_SERIES_CALCULATION, 0) cascade
             , 1 ORIGINAL
             , nvl(DID_DESCR, DNT_NAME) DESCR
             , DNT_NAME name
             , C_CALCULATION_MODE
             , DNT_RATE RATE
             , DNT_FRACTION FRACTION
             , DNT_FIXED_AMOUNT FIXED_AMOUNT_B
             ,   -- Toujours en monnaie de base sur ptc_discount
               DNT_EXCEEDING_AMOUNT_FROM EXCEEDED_AMOUNT_FROM
             , DNT_EXCEEDING_AMOUNT_TO EXCEEDED_AMOUNT_TO
             , DNT_MIN_AMOUNT MIN_AMOUNT
             , DNT_MAX_AMOUNT MAX_AMOUNT
             , DNT_QUANTITY_FROM QUANTITY_FROM
             , DNT_QUANTITY_TO QUANTITY_TO
             , DNT_DATE_FROM DATE_FROM
             , DNT_DATE_TO DATE_TO
             , DNT_IS_MULTIPLICATOR IS_MULTIPLICATOR
             , DNT_STORED_PROC STORED_PROC
             , C_ROUND_TYPE
             , DNT_ROUND_AMOUNT ROUND_AMOUNT
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , 1 AUTOMATIC_CALC
             , nvl(DNT_IN_SERIES_CALCULATION, 0) IN_SERIES_CALCULATION
             , DNT_TRANSFERT_PROP TRANSFERT_PROP
             , DNT_MODIFY MODIF
             , DNT_UNIT_DETAIL UNIT_DETAIL
             , null SQL_EXTERN_ITEM
             , C_DISCOUNT_TYPE CHARGE_TYPE
             , DNT_EXCLUSIVE EXCLUSIF
          from PTC_DISCOUNT DNT
             , PTC_DISCOUNT_DESCR DID
         where instr(astrDiscountList, ',' || to_char(DNT.PTC_DISCOUNT_ID) || ',') > 0
           and DNT.PTC_DISCOUNT_ID = DID.PTC_DISCOUNT_ID(+)
           and DID.PC_LANG_ID(+) = lang_id
      union
      select   0 PTC_DISCOUNT_ID
             , CRG.PTC_CHARGE_ID
             , nvl(CRG_IN_SERIE_CALCULATION, 0) cascade
             , 1 ORIGINAL
             , nvl(CHD_DESCR, CRG_NAME) DESCR
             , CRG_NAME name
             , C_CALCULATION_MODE
             , CRG_RATE RATE
             , CRG_FRACTION FRACTION
             , CRG_FIXED_AMOUNT FIXED_AMOUNT_B
             ,   -- Toujours en monnaie de base sur ptc_charge
               CRG_EXCEEDED_AMOUNT_FROM EXCEEDED_AMOUNT_FROM
             , CRG_EXCEEDED_AMOUNT_TO EXCEEDED_AMOUNT_TO
             , CRG_MIN_AMOUNT MIN_AMOUNT
             , CRG_MAX_AMOUNT MAX_AMOUNT
             , CRG_QUANTITY_FROM QUANTITY_FROM
             , CRG_QUANTITY_TO QUANTITY_TO
             , CRG_DATE_FROM DATE_FROM
             , CRG_DATE_TO DATE_TO
             , CRG_IS_MULTIPLICATOR IS_MULTIPLICATOR
             , CRG_STORED_PROC STORED_PROC
             , C_ROUND_TYPE
             , CRG_ROUND_AMOUNT ROUND_AMOUNT
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , CRG_AUTOMATIC_CALC AUTOMATIC_CALC
             , nvl(CRG_IN_SERIE_CALCULATION, 0) IN_SERIES_CALCULATION
             , CRG_TRANSFERT_PROP TRANSFERT_PROP
             , CRG_MODIFY MODIF
             , CRG_UNIT_DETAIL UNIT_DETAIL
             , CRG_SQL_EXTERN_ITEM SQL_EXTERN_ITEM
             , C_CHARGE_TYPE CHARGE_TYPE
             , CRG_EXCLUSIVE EXCLUSIF
          from PTC_CHARGE CRG
             , PTC_CHARGE_DESCRIPTION CHD
         where instr(astrChargeList, ',' || to_char(CRG.PTC_CHARGE_ID) || ',') > 0
           and CRG.PTC_CHARGE_ID = CHD.PTC_CHARGE_ID(+)
           and CHD.PC_LANG_ID(+) = lang_id
      order by 3
             , 6;

    tplDiscountCharge        crDiscountCharge%rowtype;
    goodReference            GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    templist                 varchar2(20000);
    chargelist               varchar2(20000);
    discountlist             varchar2(20000);
    numChanged               number(1);
    pchAmount                DOC_POSITION_CHARGE.PCH_AMOUNT%type;
    eurAmount                DOC_POSITION_CHARGE.PCH_AMOUNT%type;
    liabledAmount            DOC_POSITION_CHARGE.PCH_AMOUNT%type;
    unitLiabledAmount        DOC_POSITION_CHARGE.PCH_AMOUNT%type;
    CascadeAmount            DOC_POSITION_CHARGE.PCH_AMOUNT%type;
    chargeAmount             DOC_POSITION_CHARGE.PCH_AMOUNT%type     default 0;
    discountAmount           DOC_POSITION_CHARGE.PCH_AMOUNT%type     default 0;
    vFound                   number(1);
    foundTariffId            PTC_TARIFF.PTC_TARIFF_ID%type;
    vTmpDiscountCharge       varchar2(4000);
    vExclusiveDiscountId     PTC_DISCOUNT.PTC_DISCOUNT_ID%type;
    vExclusiveDiscountAmount DOC_POSITION.POS_DISCOUNT_AMOUNT%type   default 0;
    vExclusiveChargeId       PTC_CHARGE.PTC_CHARGE_ID%type;
    vExclusiveChargeAmount   DOC_POSITION.POS_CHARGE_AMOUNT%type     default 0;
  begin
    if aGivenPrice is null then
      -- recherche du prix et conversion dans la monnaie passée en paramètre
      PTC_FIND_TARIFF.GetTariffConverted(aGoodId
                                       , aQuantity
                                       , aThirdId
                                       , aRecordId
                                       , aGaugeId
                                       , aCurrencyId
                                       , aTariffType
                                       , aTarifficationMode
                                       , aDicTariffId
                                       , aDateRef
                                       , aGoodUnitPrice
                                       , aDiscountRate
                                       , aGoodGrossPrice
                                       , aNetPriceHt
                                       , aNetPriceTtc
                                       , aNetTariff
                                       , aSpecialTariff
                                       , aFlat
                                       , foundTariffId
                                        );
    else
      aGoodUnitPrice   := aGivenPrice;
      aDiscountRate    := 0;
      aGoodGrossPrice  := aGivenPrice;
      aNetPriceHt      := aGivenPrice * aQuantity;
      aNetPriceTtc     := aGivenPrice * aQuantity;
      foundTariffId    := 1;
    end if;

    LiabledAmount      := aGoodGrossPrice * aQuantity;
    CascadeAmount      := aGoodGrossPrice * aQuantity;
    unitLiabledAmount  := aGoodUnitPrice;

    -- recherche de la référence article
    select GOO_MAJOR_REFERENCE
      into goodReference
      from GCO_GOOD
     where GCO_GOOD_ID = aGoodId;

    if foundTariffId is not null then
      aFormattedPrice  :=
        cCRLF ||
        rpad(PCS.PC_FUNCTIONS.TranslateWord('Quantité'), 16, ' ') ||
        rpad(PCS.PC_FUNCTIONS.TranslateWord('Référence principale'), 22, ' ') ||
        lpad(PCS.PC_FUNCTIONS.TranslateWord('Prix unitaire'), 24, ' ') ||
        lpad(PCS.PC_FUNCTIONS.TranslateWord('Prix'), 32, ' ');

      if aNetTariff = 0 then
        aFormattedPrice  := aFormattedPrice || cCRLF || rpad(' ', 24, ' ') || PCS.PC_FUNCTIONS.TranslateWord('Remise/Taxe');
      end if;

      aFormattedPrice  := aFormattedPrice || cCRLF || rpad('-', 98, '-');
      aFormattedPrice  :=
        aFormattedPrice ||
        cCRLF ||
        rpad(to_char(aQuantity), 16, ' ') ||
        rpad(goodReference, 22, ' ') ||
        lpad(to_char(aGoodUnitPrice, '9999999990D999999'), 24, ' ') ||
        lpad(to_char(aQuantity * aGoodUnitPrice, '9999999990D99'), 32, ' ') ||
        ' ' ||
        ACS_FUNCTION.GetCurrencyName(aCurrencyId);

      if aNetTariff = 0 then
        -- recherche des remises/taxes
        PTC_FIND_DISCOUNT_CHARGE.TESTDETDISCOUNTCHARGE(nvl(aGaugeId, 0)
                                                     , nvl(aThirdId, 0)
                                                     , nvl(aRecordId, 0)
                                                     , nvl(aGoodId, 0)
                                                     , aChargeType
                                                     , aDateRef
                                                     , aBlnCharge
                                                     , aBlnDiscount
                                                     , numchanged
                                                      );   -- pas utilisé
        -- récupération de la liste des taxes
        templist      := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('CHARGE', 'DET');
        chargelist    := templist;

        while length(templist) > 1987 loop
          templist    := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('CHARGE', 'DET');
          chargelist  := chargeList || templist;
        end loop;

        -- récupération de la liste des remises
        templist      := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('DISCOUNT', 'DET');
        discountlist  := templist;

        while length(templist) > 1987 loop
          templist      := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('DISCOUNT', 'DET');
          discountlist  := discountlist || templist;
        end loop;

        -- ouverture d'un query sur les infos des remises/taxes
        for tplDiscountCharge in crDiscountCharge(chargelist, discountlist, aLangId) loop
          if tplDiscountCharge.cascade = 1 then
            LiabledAmount  := CascadeAmount;

            /* Recalcul le montant soumis unitaire lorsque la charge est en cascade.
               En effet, dans ce cas la, il ne faut pas prendre le montant unitaire
               de la position. */
            if (aQuantity <> 0) then
              unitLiabledAmount  := CascadeAmount / aQuantity;
            else
              unitLiabledAmount  := CascadeAmount;
            end if;
          end if;

          -- traitement des taxes
          if tplDiscountCharge.PTC_CHARGE_ID <> 0 then
            PTC_FUNCTIONS.CalcCharge(tplDiscountCharge.PTC_CHARGE_ID   /* Id de la taxe à calculer */
                                   , tplDiscountCharge.descr   /* Nom de la taxe */
                                   , unitLiabledAmount   /* Montant unitaire soumis à la taxe en monnaie document */
                                   , liabledAmount   /* Montant soumis à la taxe en monnaie document */
                                   , liabledAmount   /* Montant soumis à la taxe en monnaie document */
                                   , aQuantity   /* Pour les taxes de type détail, quantité de la position */
                                   , aGoodId   /* Identifiant du bien */
                                   , aThirdId   /* Identifiant de la position pour les taxes détaillées de type 8 (plsql) */
                                   , aPositionId   /* Identifiant de la position pour les taxes détaillées de type 8 (plsql) */
                                   , aDocumentId   /* Identifiant du document pour les taxes de type total de type 8 (plsql) */
                                   , aCurrencyId   /* Id de la monnaie du montant soumis */
                                   , 0   /* Taux de change */
                                   , 0   /* Diviseur */
                                   , aDateRef   /* Date de référence */
                                   , tplDiscountCharge.C_CALCULATION_MODE   /* Mode de calcul */
                                   , tplDiscountCharge.rate   /* Taux */
                                   , tplDiscountCharge.fraction   /* Fraction */
                                   , tplDiscountCharge.fixed_amount_b   /* Montant fixe en monnaie de base */
                                   , 0   /* Montant fixe en monnaie document (pas utilisé) */
                                   , tplDiscountCharge.quantity_from   /* Quantité de */
                                   , tplDiscountCharge.quantity_to   /* Quantité a */
                                   , tplDiscountCharge.min_amount   /* Montant minimum de remise/taxe */
                                   , tplDiscountCharge.max_amount   /* Montant maximum de remise/taxe */
                                   , tplDiscountCharge.exceeded_amount_from   /* Montant de dépassement de */
                                   , tplDiscountCharge.exceeded_amount_to   /* Montant de dépassement à */
                                   , tplDiscountCharge.stored_proc   /* Procedure stockée de calcul de remise/taxe */
                                   , tplDiscountCharge.is_multiplicator   /* Pour le montant fixe, multiplier par quantité ? */
                                   , tplDiscountCharge.automatic_calc   /* Calculation auto ou à partir de sql_Extern_item */
                                   , tplDiscountCharge.sql_extern_item   /* Commande sql de recherche du montant soumis à la calculation */
                                   , tplDiscountCharge.c_round_type   /* Type d'arrondi */
                                   , tplDiscountCharge.round_amount   /* Montant d'arrondi */
                                   , tplDiscountCharge.unit_detail   /* Détail unitaire */
                                   , tplDiscountCharge.original   /* Origine de la taxe (1 = création, 0 = modification) */
                                   , 0   /* mode cumul*/
                                   , pchAmount   /* Montant de la taxe */
                                   , vFound   /* Taxe trouvée */
                                    );
          -- traitement des remises
          else
            PTC_FUNCTIONS.CalcDiscount(tplDiscountCharge.PTC_DISCOUNT_ID   /* Id de la remise à calculer */
                                     , unitLiabledAmount   /* Montant unitaire soumis à la remise en monnaie document */
                                     , liabledAmount   /* Montant soumis à la remise en monnaie document */
                                     , liabledAmount   /* Montant soumis à la remise en monnaie document */
                                     , aQuantity   /* Pour les remises de type détail, quantité de la position */
                                     , aPositionId   /* Identifiant de la position pour les remises détaillées de type 8 (plsql) */
                                     , aDocumentId   /* Identifiant du document pour les remises de type total de type 8 (plsql) */
                                     , aCurrencyId   /* Id de la monnaie du montant soumis */
                                     , 0   /* Taux de change */
                                     , 0   /* Diviseur */
                                     , aDateRef   /* Date de référence */
                                     , tplDiscountCharge.C_CALCULATION_MODE   /* Mode de calcul */
                                     , tplDiscountCharge.rate   /* Taux */
                                     , tplDiscountCharge.fraction   /* Fraction */
                                     , tplDiscountCharge.fixed_amount_b   /* Montant fixe en monnaie de base */
                                     , 0   /* Montant fixe en monnaie document(pas utilisé)) */
                                     , tplDiscountCharge.quantity_from   /* Quantité de */
                                     , tplDiscountCharge.quantity_to   /* Quantité a */
                                     , tplDiscountCharge.min_amount   /* Montant minimum de remise/taxe */
                                     , tplDiscountCharge.max_amount   /* Montant maximum de remise/taxe */
                                     , tplDiscountCharge.exceeded_amount_from   /* Montant de dépassement de */
                                     , tplDiscountCharge.exceeded_amount_to   /* Montant de dépassement à */
                                     , tplDiscountCharge.stored_proc   /* Procedure stockée de calcul de remise/taxe */
                                     , tplDiscountCharge.is_multiplicator   /* Pour le montant fixe, multiplier par quantité ? */
                                     , tplDiscountCharge.c_round_type   /* Type d'arrondi */
                                     , tplDiscountCharge.round_amount   /* Montant d'arrondi */
                                     , tplDiscountCharge.unit_detail   /* Détail unitaire */
                                     , tplDiscountCharge.original   /* Origine de la remise (1 = création, 0 = modification) */
                                     , 0   /* mode cumul*/
                                     , pchAmount   /* Montant de la remise */
                                     , vFound   /* Remise trouvée */
                                      );
          end if;

          /*Monnaie du document diffère de la monnaie du tarif*/
          if     ACS_FUNCTION.GetLocalCurrencyId <> aCurrencyId
             and tplDiscountCharge.C_CALCULATION_MODE in('0', '1', '6') then
            ACS_FUNCTION.ConvertAmount(pchAmount   /*Prix selon tarif trouvé*/
                                     , aCurrencyId   /*Monnaie du document*/
                                     , ACS_FUNCTION.GetLocalCurrencyId   /*Monnaie de base*/
                                     , trunc(aDateRef)   /*Date référence*/
                                     , 0
                                     , 0
                                     , 0   /*Pas d'Arrondi*/
                                     , eurAmount   /*Montant Euro, pas utilisé */
                                     , pchAmount   /*Montant converti*/
                                     , 5
                                      );   /*Cours logistique*/
          end if;

          -- si remise trouvée (flag utile pour les remises sur dépassement ou sur plage de quantité)
          if vFound = 1 then
            if tplDiscountCharge.PTC_CHARGE_ID <> 0 then
              if     tplDiscountCharge.EXCLUSIF = 1
                 and (   abs(pchAmount) > abs(vExclusiveChargeAmount)
                      or vExclusiveChargeId is null) then
                vExclusiveChargeAmount  := pchAmount;
                vExclusiveChargeId      := tplDiscountCharge.PTC_CHARGE_ID;
              end if;

              vTmpDiscountCharge  :=
                vTmpDiscountCharge ||
                cCRLF ||
                rpad(' ', 24, ' ') ||
                rpad(tplDiscountCharge.Descr, 50, ' ') ||
                lpad(to_char(pchAmount, '9999999990D99'), 20, ' ') ||
                ' ' ||
                ACS_FUNCTION.GetCurrencyName(aCurrencyId);
            else
              if     tplDiscountCharge.EXCLUSIF = 1
                 and (   abs(pchAmount) > abs(vExclusiveDiscountAmount)
                      or vExclusiveDiscountId is null) then
                vExclusiveDiscountAmount  := pchAmount;
                vExclusiveDiscountId      := tplDiscountCharge.PTC_DISCOUNT_ID;
              end if;

              vTmpDiscountCharge  :=
                vTmpDiscountCharge ||
                cCRLF ||
                rpad(' ', 24, ' ') ||
                rpad(tplDiscountCharge.Descr, 50, ' ') ||
                lpad(to_char(-pchAmount, '9999999990D99'), 20, ' ') ||
                ' ' ||
                ACS_FUNCTION.GetCurrencyName(aCurrencyId);
            end if;

            select chargeAmount + decode(tplDiscountCharge.PTC_CHARGE_ID, 0, 0, pchAmount)
              into chargeAmount
              from dual;

            select discountAmount + decode(tplDiscountCharge.PTC_DISCOUNT_ID, 0, 0, pchAmount)
              into discountAmount
              from dual;

            select CascadeAmount + decode(tplDiscountCharge.PTC_CHARGE_ID, 0, -pchAmount, pchAmount)
              into CascadeAmount
              from dual;
          end if;
        end loop;

        if    vExclusiveDiscountId is not null
           or vExclusiveChargeId is not null then
          vTmpDiscountCharge  := '';
          LiabledAmount       := aGoodGrossPrice * aQuantity;
          CascadeAmount       := aGoodGrossPrice * aQuantity;
          unitLiabledAmount   := aGoodUnitPrice;
          chargeAmount        := 0;
          discountAmount      := 0;

          if vExclusiveDiscountId is not null then
            discountList  := ',' || vExclusiveDiscountId || ',';
          end if;

          if vExclusiveChargeId is not null then
            chargeList  := ',' || vExclusiveChargeId || ',';
          end if;

          -- calcul de chaque remise taxe order by XXX_CASCADE et XXX_DESCRIPTION
          for tplDiscountCharge in crDiscountCharge(chargelist, discountlist, aLangId) loop
            if tplDiscountCharge.cascade = 1 then
              LiabledAmount  := CascadeAmount;

              /* Recalcul le montant soumis unitaire lorsque la charge est en cascade.
                 En effet, dans ce cas la, il ne faut pas prendre le montant unitaire
                 de la position. */
              if (aQuantity <> 0) then
                unitLiabledAmount  := CascadeAmount / aQuantity;
              else
                unitLiabledAmount  := CascadeAmount;
              end if;
            end if;

            -- traitement des taxes
            if tplDiscountCharge.PTC_CHARGE_ID <> 0 then
              PTC_FUNCTIONS.CalcCharge(tplDiscountCharge.PTC_CHARGE_ID   /* Id de la taxe à calculer */
                                     , tplDiscountCharge.descr   /* Nom de la taxe */
                                     , unitLiabledAmount   /* Montant unitaire soumis à la taxe en monnaie document */
                                     , liabledAmount   /* Montant soumis à la taxe en monnaie document */
                                     , liabledAmount   /* Montant soumis à la taxe en monnaie document */
                                     , aQuantity   /* Pour les taxes de type détail, quantité de la position */
                                     , aGoodId   /* Identifiant du bien */
                                     , aThirdId   /* Identifiant de la position pour les taxes détaillées de type 8 (plsql) */
                                     , aPositionId   /* Identifiant de la position pour les taxes détaillées de type 8 (plsql) */
                                     , aDocumentId   /* Identifiant du document pour les taxes de type total de type 8 (plsql) */
                                     , aCurrencyId   /* Id de la monnaie du montant soumis */
                                     , 0   /* Taux de change */
                                     , 0   /* Diviseur */
                                     , aDateRef   /* Date de référence */
                                     , tplDiscountCharge.C_CALCULATION_MODE   /* Mode de calcul */
                                     , tplDiscountCharge.rate   /* Taux */
                                     , tplDiscountCharge.fraction   /* Fraction */
                                     , tplDiscountCharge.fixed_amount_b   /* Montant fixe en monnaie de base */
                                     , 0   /* Montant fixe en monnaie document (pas utilisé) */
                                     , tplDiscountCharge.quantity_from   /* Quantité de */
                                     , tplDiscountCharge.quantity_to   /* Quantité a */
                                     , tplDiscountCharge.min_amount   /* Montant minimum de remise/taxe */
                                     , tplDiscountCharge.max_amount   /* Montant maximum de remise/taxe */
                                     , tplDiscountCharge.exceeded_amount_from   /* Montant de dépassement de */
                                     , tplDiscountCharge.exceeded_amount_to   /* Montant de dépassement à */
                                     , tplDiscountCharge.stored_proc   /* Procedure stockée de calcul de remise/taxe */
                                     , tplDiscountCharge.is_multiplicator   /* Pour le montant fixe, multiplier par quantité ? */
                                     , tplDiscountCharge.automatic_calc   /* Calculation auto ou à partir de sql_Extern_item */
                                     , tplDiscountCharge.sql_extern_item   /* Commande sql de recherche du montant soumis à la calculation */
                                     , tplDiscountCharge.c_round_type   /* Type d'arrondi */
                                     , tplDiscountCharge.round_amount   /* Montant d'arrondi */
                                     , tplDiscountCharge.unit_detail   /* Détail unitaire */
                                     , tplDiscountCharge.original   /* Origine de la taxe (1 = création, 0 = modification) */
                                     , 0   /* mode cumul*/
                                     , pchAmount   /* Montant de la taxe */
                                     , vFound   /* Taxe trouvée */
                                      );
            -- traitement des remises
            else
              PTC_FUNCTIONS.CalcDiscount(tplDiscountCharge.PTC_DISCOUNT_ID   /* Id de la remise à calculer */
                                       , unitLiabledAmount   /* Montant unitaire soumis à la remise en monnaie document */
                                       , liabledAmount   /* Montant soumis à la remise en monnaie document */
                                       , liabledAmount   /* Montant soumis à la remise en monnaie document */
                                       , aQuantity   /* Pour les remises de type détail, quantité de la position */
                                       , aPositionId   /* Identifiant de la position pour les remises détaillées de type 8 (plsql) */
                                       , aDocumentId   /* Identifiant du document pour les remises de type total de type 8 (plsql) */
                                       , aCurrencyId   /* Id de la monnaie du montant soumis */
                                       , 0   /* Taux de change */
                                       , 0   /* Diviseur */
                                       , aDateRef   /* Date de référence */
                                       , tplDiscountCharge.C_CALCULATION_MODE   /* Mode de calcul */
                                       , tplDiscountCharge.rate   /* Taux */
                                       , tplDiscountCharge.fraction   /* Fraction */
                                       , tplDiscountCharge.fixed_amount_b   /* Montant fixe en monnaie de base */
                                       , 0   /* Montant fixe en monnaie document(pas utilisé)) */
                                       , tplDiscountCharge.quantity_from   /* Quantité de */
                                       , tplDiscountCharge.quantity_to   /* Quantité a */
                                       , tplDiscountCharge.min_amount   /* Montant minimum de remise/taxe */
                                       , tplDiscountCharge.max_amount   /* Montant maximum de remise/taxe */
                                       , tplDiscountCharge.exceeded_amount_from   /* Montant de dépassement de */
                                       , tplDiscountCharge.exceeded_amount_to   /* Montant de dépassement à */
                                       , tplDiscountCharge.stored_proc   /* Procedure stockée de calcul de remise/taxe */
                                       , tplDiscountCharge.is_multiplicator   /* Pour le montant fixe, multiplier par quantité ? */
                                       , tplDiscountCharge.c_round_type   /* Type d'arrondi */
                                       , tplDiscountCharge.round_amount   /* Montant d'arrondi */
                                       , tplDiscountCharge.unit_detail   /* Détail unitaire */
                                       , tplDiscountCharge.original   /* Origine de la remise (1 = création, 0 = modification) */
                                       , 0   /* mode cumul*/
                                       , pchAmount   /* Montant de la remise */
                                       , vFound   /* Remise trouvée */
                                        );
            end if;

            /*Monnaie du document diffère de la monnaie du tarif*/
            if     ACS_FUNCTION.GetLocalCurrencyId <> aCurrencyId
               and tplDiscountCharge.C_CALCULATION_MODE in('0', '1', '6') then
              ACS_FUNCTION.ConvertAmount(pchAmount   /*Prix selon tarif trouvé*/
                                       , aCurrencyId   /*Monnaie du document*/
                                       , ACS_FUNCTION.GetLocalCurrencyId   /*Monnaie de base*/
                                       , trunc(aDateRef)   /*Date référence*/
                                       , 0
                                       , 0
                                       , 0   /*Pas d'Arrondi*/
                                       , eurAmount   /*Montant Euro, pas utilisé */
                                       , pchAmount   /*Montant converti*/
                                       , 5
                                        );   /*Cours logistique*/
            end if;

            -- si remise trouvée (flag utile pour les remises sur dépassement ou sur plage de quantité)
            if vFound = 1 then
              if tplDiscountCharge.PTC_CHARGE_ID <> 0 then
                vTmpDiscountCharge  :=
                  vTmpDiscountCharge ||
                  cCRLF ||
                  rpad(' ', 24, ' ') ||
                  rpad(tplDiscountCharge.Descr, 50, ' ') ||
                  lpad(to_char(pchAmount, '9999999990D99'), 20, ' ') ||
                  ' ' ||
                  ACS_FUNCTION.GetCurrencyName(aCurrencyId);
              else
                vTmpDiscountCharge  :=
                  vTmpDiscountCharge ||
                  cCRLF ||
                  rpad(' ', 24, ' ') ||
                  rpad(tplDiscountCharge.Descr, 50, ' ') ||
                  lpad(to_char(-pchAmount, '9999999990D99'), 20, ' ') ||
                  ' ' ||
                  ACS_FUNCTION.GetCurrencyName(aCurrencyId);
              end if;

              select chargeAmount + decode(tplDiscountCharge.PTC_CHARGE_ID, 0, 0, pchAmount)
                into chargeAmount
                from dual;

              select discountAmount + decode(tplDiscountCharge.PTC_DISCOUNT_ID, 0, 0, pchAmount)
                into discountAmount
                from dual;

              select CascadeAmount + decode(tplDiscountCharge.PTC_CHARGE_ID, 0, -pchAmount, pchAmount)
                into CascadeAmount
                from dual;
            end if;
          end loop;
        end if;
      end if;

      -- Ajout de la partie remises/taxes
      aFormattedPrice  := aFormattedPrice || vTmpDiscountCharge;
      aFormattedPrice  := aFormattedPrice || cCRLF || rpad('-', 98, '-');
      aFormattedPrice  :=
        aFormattedPrice ||
        cCRLF ||
        rpad(PCS.PC_FUNCTIONS.TranslateWord('Total') || ' : ', 16, ' ') ||
        lpad(to_char(cascadeAmount, '9999999990D99'), 78, ' ') ||
        ' ' ||
        ACS_FUNCTION.GetCurrencyName(aCurrencyId);
      aFormattedPrice  := aFormattedPrice || cCRLF;
      aFormattedPrice  := aFormattedPrice || cCRLF;
    else   -- Pas de tarif trouvé
      aFormattedPrice  := PCS.PC_FUNCTIONS.TRANSLATEWORD('Pas de tarif trouvé') || cCRLF;
      aFormattedPrice  := aFormattedPrice || cCRLF;
    end if;
  end GetDetailledPrice;

  /**
  * Description
  *    retourne un prix avec remises/taxes
  */
  function GetFullPrice(
    aGoodId            in number
  , aQuantity          in number
  , aThirdId           in number
  , aRecordId          in number
  , aGaugeId           in number
  , aCurrencyId        in number
  , aTariffType        in varchar2
  , aTarifficationMode in varchar2
  , aDicTariffId       in varchar2
  , aDateRef           in date
  , aChargeType        in varchar2
  , aPositionId        in number
  , aDocumentId        in number
  , aBlnCharge         in number
  , aBlnDiscount       in number
  , aTariffId          in PTC_TARIFF.PTC_TARIFF_ID%type default null
  , aGivenPrice        in number default null
--  , aDocDicTariffId    in varchar2 default null
  )
    return number
  is
    -- curseur sur les remises et taxes
    cursor crDiscountCharge(astrChargeList varchar2, astrDiscountList varchar2)
    is
      select   DNT.PTC_DISCOUNT_ID
             , 0 PTC_CHARGE_ID
             , nvl(DNT_IN_SERIES_CALCULATION, 0) cascade
             , 1 ORIGINAL
             , DNT_NAME name
             , C_CALCULATION_MODE
             , DNT_RATE RATE
             , DNT_FRACTION FRACTION
             , DNT_FIXED_AMOUNT FIXED_AMOUNT_B
             ,   -- Toujours en monnaie de base sur ptc_discount
               DNT_EXCEEDING_AMOUNT_FROM EXCEEDED_AMOUNT_FROM
             , DNT_EXCEEDING_AMOUNT_TO EXCEEDED_AMOUNT_TO
             , DNT_MIN_AMOUNT MIN_AMOUNT
             , DNT_MAX_AMOUNT MAX_AMOUNT
             , DNT_QUANTITY_FROM QUANTITY_FROM
             , DNT_QUANTITY_TO QUANTITY_TO
             , DNT_DATE_FROM DATE_FROM
             , DNT_DATE_TO DATE_TO
             , DNT_IS_MULTIPLICATOR IS_MULTIPLICATOR
             , DNT_STORED_PROC STORED_PROC
             , C_ROUND_TYPE
             , DNT_ROUND_AMOUNT ROUND_AMOUNT
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , 1 AUTOMATIC_CALC
             , nvl(DNT_IN_SERIES_CALCULATION, 0) IN_SERIES_CALCULATION
             , DNT_TRANSFERT_PROP TRANSFERT_PROP
             , DNT_MODIFY MODIF
             , DNT_UNIT_DETAIL UNIT_DETAIL
             , null SQL_EXTERN_ITEM
             , C_DISCOUNT_TYPE CHARGE_TYPE
             , DNT_EXCLUSIVE EXCLUSIF
          from PTC_DISCOUNT DNT
         where instr(astrDiscountList, ',' || to_char(DNT.PTC_DISCOUNT_ID) || ',') > 0
      union
      select   0 PTC_DISCOUNT_ID
             , CRG.PTC_CHARGE_ID
             , nvl(CRG_IN_SERIE_CALCULATION, 0) cascade
             , 1 ORIGINAL
             , CRG_NAME name
             , C_CALCULATION_MODE
             , CRG_RATE RATE
             , CRG_FRACTION FRACTION
             , CRG_FIXED_AMOUNT FIXED_AMOUNT_B
             ,   -- Toujours en monnaie de base sur ptc_charge
               CRG_EXCEEDED_AMOUNT_FROM EXCEEDED_AMOUNT_FROM
             , CRG_EXCEEDED_AMOUNT_TO EXCEEDED_AMOUNT_TO
             , CRG_MIN_AMOUNT MIN_AMOUNT
             , CRG_MAX_AMOUNT MAX_AMOUNT
             , CRG_QUANTITY_FROM QUANTITY_FROM
             , CRG_QUANTITY_TO QUANTITY_TO
             , CRG_DATE_FROM DATE_FROM
             , CRG_DATE_TO DATE_TO
             , CRG_IS_MULTIPLICATOR IS_MULTIPLICATOR
             , CRG_STORED_PROC STORED_PROC
             , C_ROUND_TYPE
             , CRG_ROUND_AMOUNT ROUND_AMOUNT
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , CRG_AUTOMATIC_CALC AUTOMATIC_CALC
             , nvl(CRG_IN_SERIE_CALCULATION, 0) IN_SERIES_CALCULATION
             , CRG_TRANSFERT_PROP TRANSFERT_PROP
             , CRG_MODIFY MODIF
             , CRG_UNIT_DETAIL UNIT_DETAIL
             , CRG_SQL_EXTERN_ITEM SQL_EXTERN_ITEM
             , C_CHARGE_TYPE CHARGE_TYPE
             , CRG_EXCLUSIVE EXCLUSIF
          from PTC_CHARGE CRG
         where instr(astrChargeList, ',' || to_char(CRG.PTC_CHARGE_ID) || ',') > 0
      order by 3
             , 5;

    tplDiscountCharge        crDiscountCharge%rowtype;
    goodReference            GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    templist                 varchar2(20000);
    chargelist               varchar2(20000);
    discountlist             varchar2(20000);
    numChanged               number(1);
    pchAmount                DOC_POSITION_CHARGE.PCH_AMOUNT%type;
    eurAmount                DOC_POSITION_CHARGE.PCH_AMOUNT_E%type;
    liabledAmount            DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    unitLiabledAmount        DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    CascadeAmount            DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    chargeAmount             DOC_POSITION_CHARGE.PCH_AMOUNT%type      default 0;
    discountAmount           DOC_POSITION_CHARGE.PCH_AMOUNT%type      default 0;
    vFound                   number(1);
    foundTariffId            PTC_TARIFF.PTC_TARIFF_ID%type;
    vGoodUnitPrice           DOC_POSITION.POS_NET_UNIT_VALUE%type;
    vDiscountRate            PTC_DISCOUNT.DNT_RATE%type;
    vGoodGrossPrice          DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    vNetPriceHt              DOC_POSITION.POS_NET_VALUE_EXCL%type;
    vNetPriceTtc             DOC_POSITION.POS_NET_VALUE_INCL%type;
    vNetTariff               DOC_POSITION.POS_NET_TARIFF%type;
    vSpecialTariff           DOC_POSITION.POS_SPECIAL_TARIFF%type;
    vExclusiveDiscountId     PTC_DISCOUNT.PTC_DISCOUNT_ID%type;
    vExclusiveDiscountAmount DOC_POSITION.POS_DISCOUNT_AMOUNT%type    default 0;
    vExclusiveChargeId       PTC_CHARGE.PTC_CHARGE_ID%type;
    vExclusiveChargeAmount   DOC_POSITION.POS_CHARGE_AMOUNT%type      default 0;
    lFlat                    number(1);
  begin
    if aGivenPrice is null then
      -- recherche du prix et conversion dans la monnaie passée en paramètre
      PTC_FIND_TARIFF.GetTariffConverted(aGoodId
                                       , aQuantity
                                       , aThirdId
                                       , aRecordId
                                       , aGaugeId
                                       , aCurrencyId
                                       , aTariffType
                                       , aTarifficationMode
                                       , aDicTariffId
                                       , aDateRef
                                       , vGoodUnitPrice
                                       , vDiscountRate
                                       , vGoodGrossPrice
                                       , vNetPriceHt
                                       , vNetPriceTtc
                                       , vNetTariff
                                       , vSpecialTariff
                                       , lFlat
                                       , foundTariffId
                                       , aTariffId
                                        );
    else
      -- Le prix unitaire est donné.
      vGoodGrossPrice  := aGivenPrice;
      vGoodUnitPrice   := aGivenPrice;
      foundTariffId    := 1;
      vNetTariff       := 0;
    end if;

    LiabledAmount      := vGoodGrossPrice * aQuantity;
    CascadeAmount      := vGoodGrossPrice * aQuantity;
    unitLiabledAmount  := vGoodUnitPrice;

    if foundTariffId is not null then
      if vNetTariff = 0 then
        -- recherche des remises/taxes
        PTC_FIND_DISCOUNT_CHARGE.TESTDETDISCOUNTCHARGE(nvl(aGaugeId, 0)
                                                     , nvl(aThirdId, 0)
                                                     , nvl(aRecordId, 0)
                                                     , nvl(aGoodId, 0)
                                                     , aChargeType
                                                     , aDateRef
                                                     , aBlnCharge
                                                     , aBlnDiscount
                                                     , numchanged
                                                     , 1   -- remise à 0 des variables globales
                                                      );   -- pas utilisé
        -- récupération de la liste des taxes
        templist      := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('CHARGE', 'DET');
        chargelist    := templist;

        while length(templist) > 1987 loop
          templist    := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('CHARGE', 'DET');
          chargelist  := chargeList || templist;
        end loop;

        -- récupération de la liste des remises
        templist      := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('DISCOUNT', 'DET');
        discountlist  := templist;

        while length(templist) > 1987 loop
          templist      := PTC_FIND_DISCOUNT_CHARGE.GETDCRESULTLIST('DISCOUNT', 'DET');
          discountlist  := discountlist || templist;
        end loop;

        -- ouverture d'un query sur les infos des remises/taxes
        open crDiscountCharge(chargelist, discountlist);

        fetch crDiscountCharge
         into tplDiscountCharge;

        -- calcul de chaque remise taxe order by XXX_CASCADE et XXX_DESCRIPTION
        while crDiscountCharge%found loop
          if tplDiscountCharge.cascade = 1 then
            LiabledAmount  := CascadeAmount;

            /* Recalcul le montant soumis unitaire lorsque la charge est en cascade.
               En effet, dans ce cas la, il ne faut pas prendre le montant unitaire
               de la position. */
            if (aQuantity <> 0) then
              unitLiabledAmount  := CascadeAmount / aQuantity;
            else
              unitLiabledAmount  := CascadeAmount;
            end if;
          end if;

          -- traitement des taxes
          if tplDiscountCharge.PTC_CHARGE_ID <> 0 then
            PTC_FUNCTIONS.CalcCharge(tplDiscountCharge.PTC_CHARGE_ID   /* Id de la taxe à calculer */
                                   , tplDiscountCharge.name   /* Nom de la taxe */
                                   , unitLiabledAmount   /* Montant unitaire soumis à la taxe en monnaie document */
                                   , liabledAmount   /* Montant soumis à la taxe en monnaie document */
                                   , liabledAmount   /* Montant soumis à la taxe en monnaie document */
                                   , aQuantity   /* Pour les taxes de type détail, quantité de la position */
                                   , aGoodId   /* Identifiant du bien */
                                   , aThirdId   /* Identifiant du tiers */
                                   , aPositionId   /* Identifiant de la position pour les taxes détaillées de type 8 (plsql) */
                                   , aDocumentId   /* Identifiant du document pour les taxes de type total de type 8 (plsql) */
                                   , aCurrencyId   /* Id de la monnaie du montant soumis */
                                   , 0   /* Taux de change */
                                   , 0   /* Diviseur */
                                   , aDateRef   /* Date de référence */
                                   , tplDiscountCharge.C_CALCULATION_MODE   /* Mode de calcul */
                                   , tplDiscountCharge.rate   /* Taux */
                                   , tplDiscountCharge.fraction   /* Fraction */
                                   , tplDiscountCharge.fixed_amount_b   /* Montant fixe en monnaie de base */
                                   , 0 /* le montant fixe en monnaie document n'est pas utilisé en création de remise */ /* Montant fixe en monnaie document */
                                   , tplDiscountCharge.quantity_from   /* Quantité de */
                                   , tplDiscountCharge.quantity_to   /* Quantité a */
                                   , tplDiscountCharge.min_amount   /* Montant minimum de remise/taxe */
                                   , tplDiscountCharge.max_amount   /* Montant maximum de remise/taxe */
                                   , tplDiscountCharge.exceeded_amount_from   /* Montant de dépassement de */
                                   , tplDiscountCharge.exceeded_amount_to   /* Montant de dépassement à */
                                   , tplDiscountCharge.stored_proc   /* Procedure stockée de calcul de remise/taxe */
                                   , tplDiscountCharge.is_multiplicator   /* Pour le montant fixe, multiplier par quantité ? */
                                   , tplDiscountCharge.automatic_calc   /* Calculation auto ou à partir de sql_Extern_item */
                                   , tplDiscountCharge.sql_extern_item   /* Commande sql de recherche du montant soumis à la calculation */
                                   , tplDiscountCharge.c_round_type   /* Type d'arrondi */
                                   , tplDiscountCharge.round_amount   /* Montant d'arrondi */
                                   , tplDiscountCharge.unit_detail   /* Détail unitaire */
                                   , tplDiscountCharge.original   /* Origine de la taxe (1 = création, 0 = modification) */
                                   , 0   /* mode cumul*/
                                   , pchAmount   /* Montant de la taxe */
                                   , vFound   /* Taxe trouvée */
                                    );
          -- traitement des remises
          else
            PTC_FUNCTIONS.CalcDiscount(tplDiscountCharge.PTC_DISCOUNT_ID   /* Id de la remise à calculer */
                                     , unitLiabledAmount   /* Montant unitaire soumis à la remise en monnaie document */
                                     , liabledAmount   /* Montant soumis à la remise en monnaie document */
                                     , liabledAmount   /* Montant soumis à la remise en monnaie document */
                                     , aQuantity   /* Pour les remises de type détail, quantité de la position */
                                     , aPositionId   /* Identifiant de la position pour les remises détaillées de type 8 (plsql) */
                                     , aDocumentId   /* Identifiant du document pour les remises de type total de type 8 (plsql) */
                                     , aCurrencyId   /* Id de la monnaie du montant soumis */
                                     , 0   /* Taux de change */
                                     , 0   /* Diviseur */
                                     , aDateRef   /* Date de référence */
                                     , tplDiscountCharge.C_CALCULATION_MODE   /* Mode de calcul */
                                     , tplDiscountCharge.rate   /* Taux */
                                     , tplDiscountCharge.fraction   /* Fraction */
                                     , tplDiscountCharge.fixed_amount_b   /* Montant fixe en monnaie de base */
                                     , 0 /* le montant fixe en monnaie document n'est pas utilisé en création de taxe */ /* Montant fixe en monnaie document */
                                     , tplDiscountCharge.quantity_from   /* Quantité de */
                                     , tplDiscountCharge.quantity_to   /* Quantité a */
                                     , tplDiscountCharge.min_amount   /* Montant minimum de remise/taxe */
                                     , tplDiscountCharge.max_amount   /* Montant maximum de remise/taxe */
                                     , tplDiscountCharge.exceeded_amount_from   /* Montant de dépassement de */
                                     , tplDiscountCharge.exceeded_amount_to   /* Montant de dépassement à */
                                     , tplDiscountCharge.stored_proc   /* Procedure stockée de calcul de remise/taxe */
                                     , tplDiscountCharge.is_multiplicator   /* Pour le montant fixe, multiplier par quantité ? */
                                     , tplDiscountCharge.c_round_type   /* Type d'arrondi */
                                     , tplDiscountCharge.round_amount   /* Type d'arrondi */
                                     , tplDiscountCharge.unit_detail   /* Détail unitaire */
                                     , tplDiscountCharge.original   /* Origine de la remise (1 = création, 0 = modification) */
                                     , 0   /* mode cumul*/
                                     , pchAmount   /* Montant de la remise */
                                     , vFound   /* Remise trouvée */
                                      );
          end if;

          /*Monnaie du document diffère de la monnaie du tarif*/
          if     ACS_FUNCTION.GetLocalCurrencyId <> aCurrencyId
             and tplDiscountCharge.C_CALCULATION_MODE in('0', '1', '6') then
            ACS_FUNCTION.ConvertAmount(pchAmount   /*Prix selon tarif trouvé*/
                                     , aCurrencyId   /*Monnaie du document*/
                                     , ACS_FUNCTION.GetLocalCurrencyId   /*Monnaie de base*/
                                     , trunc(aDateRef)   /*Date référence*/
                                     , 0
                                     , 0
                                     , 0   /*Pas d'Arrondi*/
                                     , eurAmount   /*Montant Euro, pas utilisé */
                                     , pchAmount   /*Montant converti*/
                                     , 5
                                      );   /*Cours logistique*/
          end if;

          -- si remise trouvée (flag utile pour les remises sur dépassement ou sur plage de quantité)
          if vFound = 1 then
            if tplDiscountCharge.PTC_CHARGE_ID <> 0 then
              if     tplDiscountCharge.EXCLUSIF = 1
                 and (   abs(pchAmount) > abs(vExclusiveChargeAmount)
                      or vExclusiveChargeId is null) then
                vExclusiveChargeAmount  := pchAmount;
                vExclusiveChargeId      := tplDiscountCharge.PTC_CHARGE_ID;
              end if;
            else
              if     tplDiscountCharge.EXCLUSIF = 1
                 and (   abs(pchAmount) > abs(vExclusiveDiscountAmount)
                      or vExclusiveDiscountId is null) then
                vExclusiveDiscountAmount  := pchAmount;
                vExclusiveDiscountId      := tplDiscountCharge.PTC_DISCOUNT_ID;
              end if;
            end if;

            select chargeAmount + decode(tplDiscountCharge.PTC_CHARGE_ID, 0, 0, pchAmount)
              into chargeAmount
              from dual;

            select discountAmount + decode(tplDiscountCharge.PTC_DISCOUNT_ID, 0, 0, pchAmount)
              into discountAmount
              from dual;

            select CascadeAmount + decode(tplDiscountCharge.PTC_CHARGE_ID, 0, -pchAmount, pchAmount)
              into CascadeAmount
              from dual;
          end if;

          fetch crDiscountCharge
           into tplDiscountCharge;
        end loop;

        close crDiscountCharge;

        if    vExclusiveDiscountId is not null
           or vExclusiveChargeId is not null then
          LiabledAmount      := vGoodGrossPrice * aQuantity;
          CascadeAmount      := vGoodGrossPrice * aQuantity;
          unitLiabledAmount  := vGoodUnitPrice;
          chargeAmount       := 0;
          discountAmount     := 0;

          if vExclusiveDiscountId is not null then
            discountList  := ',' || vExclusiveDiscountId || ',';
          end if;

          if vExclusiveChargeId is not null then
            chargeList  := ',' || vExclusiveChargeId || ',';
          end if;

          -- calcul de chaque remise taxe order by XXX_CASCADE et XXX_DESCRIPTION
          for tplDiscountCharge in crDiscountCharge(chargelist, discountlist) loop
            if tplDiscountCharge.cascade = 1 then
              LiabledAmount  := CascadeAmount;

              /* Recalcul le montant soumis unitaire lorsque la charge est en cascade.
                 En effet, dans ce cas la, il ne faut pas prendre le montant unitaire
                 de la position. */
              if (aQuantity <> 0) then
                unitLiabledAmount  := CascadeAmount / aQuantity;
              else
                unitLiabledAmount  := CascadeAmount;
              end if;
            end if;

            -- traitement des taxes
            if tplDiscountCharge.PTC_CHARGE_ID <> 0 then
              PTC_FUNCTIONS.CalcCharge(tplDiscountCharge.PTC_CHARGE_ID   /* Id de la taxe à calculer */
                                     , tplDiscountCharge.name   /* Nom de la taxe */
                                     , unitLiabledAmount   /* Montant unitaire soumis à la taxe en monnaie document */
                                     , liabledAmount   /* Montant soumis à la taxe en monnaie document */
                                     , liabledAmount   /* Montant soumis à la taxe en monnaie document */
                                     , aQuantity   /* Pour les taxes de type détail, quantité de la position */
                                     , aGoodId   /* Identifiant du bien */
                                     , aThirdId   /* Identifiant de la position pour les taxes détaillées de type 8 (plsql) */
                                     , aPositionId   /* Identifiant de la position pour les taxes détaillées de type 8 (plsql) */
                                     , aDocumentId   /* Identifiant du document pour les taxes de type total de type 8 (plsql) */
                                     , aCurrencyId   /* Id de la monnaie du montant soumis */
                                     , 0   /* Taux de change */
                                     , 0   /* Diviseur */
                                     , aDateRef   /* Date de référence */
                                     , tplDiscountCharge.C_CALCULATION_MODE   /* Mode de calcul */
                                     , tplDiscountCharge.rate   /* Taux */
                                     , tplDiscountCharge.fraction   /* Fraction */
                                     , tplDiscountCharge.fixed_amount_b   /* Montant fixe en monnaie de base */
                                     , 0   /* Montant fixe en monnaie document (pas utilisé) */
                                     , tplDiscountCharge.quantity_from   /* Quantité de */
                                     , tplDiscountCharge.quantity_to   /* Quantité a */
                                     , tplDiscountCharge.min_amount   /* Montant minimum de remise/taxe */
                                     , tplDiscountCharge.max_amount   /* Montant maximum de remise/taxe */
                                     , tplDiscountCharge.exceeded_amount_from   /* Montant de dépassement de */
                                     , tplDiscountCharge.exceeded_amount_to   /* Montant de dépassement à */
                                     , tplDiscountCharge.stored_proc   /* Procedure stockée de calcul de remise/taxe */
                                     , tplDiscountCharge.is_multiplicator   /* Pour le montant fixe, multiplier par quantité ? */
                                     , tplDiscountCharge.automatic_calc   /* Calculation auto ou à partir de sql_Extern_item */
                                     , tplDiscountCharge.sql_extern_item   /* Commande sql de recherche du montant soumis à la calculation */
                                     , tplDiscountCharge.c_round_type   /* Type d'arrondi */
                                     , tplDiscountCharge.round_amount   /* Montant d'arrondi */
                                     , tplDiscountCharge.unit_detail   /* Détail unitaire */
                                     , tplDiscountCharge.original   /* Origine de la taxe (1 = création, 0 = modification) */
                                     , 0   /* mode cumul*/
                                     , pchAmount   /* Montant de la taxe */
                                     , vFound   /* Taxe trouvée */
                                      );
            -- traitement des remises
            else
              PTC_FUNCTIONS.CalcDiscount(tplDiscountCharge.PTC_DISCOUNT_ID   /* Id de la remise à calculer */
                                       , unitLiabledAmount   /* Montant unitaire soumis à la remise en monnaie document */
                                       , liabledAmount   /* Montant soumis à la remise en monnaie document */
                                       , liabledAmount   /* Montant soumis à la remise en monnaie document */
                                       , aQuantity   /* Pour les remises de type détail, quantité de la position */
                                       , aPositionId   /* Identifiant de la position pour les remises détaillées de type 8 (plsql) */
                                       , aDocumentId   /* Identifiant du document pour les remises de type total de type 8 (plsql) */
                                       , aCurrencyId   /* Id de la monnaie du montant soumis */
                                       , 0   /* Taux de change */
                                       , 0   /* Diviseur */
                                       , aDateRef   /* Date de référence */
                                       , tplDiscountCharge.C_CALCULATION_MODE   /* Mode de calcul */
                                       , tplDiscountCharge.rate   /* Taux */
                                       , tplDiscountCharge.fraction   /* Fraction */
                                       , tplDiscountCharge.fixed_amount_b   /* Montant fixe en monnaie de base */
                                       , 0   /* Montant fixe en monnaie document(pas utilisé)) */
                                       , tplDiscountCharge.quantity_from   /* Quantité de */
                                       , tplDiscountCharge.quantity_to   /* Quantité a */
                                       , tplDiscountCharge.min_amount   /* Montant minimum de remise/taxe */
                                       , tplDiscountCharge.max_amount   /* Montant maximum de remise/taxe */
                                       , tplDiscountCharge.exceeded_amount_from   /* Montant de dépassement de */
                                       , tplDiscountCharge.exceeded_amount_to   /* Montant de dépassement à */
                                       , tplDiscountCharge.stored_proc   /* Procedure stockée de calcul de remise/taxe */
                                       , tplDiscountCharge.is_multiplicator   /* Pour le montant fixe, multiplier par quantité ? */
                                       , tplDiscountCharge.c_round_type   /* Type d'arrondi */
                                       , tplDiscountCharge.round_amount   /* Montant d'arrondi */
                                       , tplDiscountCharge.unit_detail   /* Détail unitaire */
                                       , tplDiscountCharge.original   /* Origine de la remise (1 = création, 0 = modification) */
                                       , 0   /* mode cumul*/
                                       , pchAmount   /* Montant de la remise */
                                       , vFound   /* Remise trouvée */
                                        );
            end if;

            /*Monnaie du document diffère de la monnaie du tarif*/
            if     ACS_FUNCTION.GetLocalCurrencyId <> aCurrencyId
               and tplDiscountCharge.C_CALCULATION_MODE in('0', '1', '6') then
              ACS_FUNCTION.ConvertAmount(pchAmount   /*Prix selon tarif trouvé*/
                                       , aCurrencyId   /*Monnaie du document*/
                                       , ACS_FUNCTION.GetLocalCurrencyId   /*Monnaie de base*/
                                       , trunc(aDateRef)   /*Date référence*/
                                       , 0
                                       , 0
                                       , 0   /*Pas d'Arrondi*/
                                       , eurAmount   /*Montant Euro, pas utilisé */
                                       , pchAmount   /*Montant converti*/
                                       , 5
                                        );   /*Cours logistique*/
            end if;

            -- si remise trouvée (flag utile pour les remises sur dépassement ou sur plage de quantité)
            if vFound = 1 then
              select chargeAmount + decode(tplDiscountCharge.PTC_CHARGE_ID, 0, 0, pchAmount)
                into chargeAmount
                from dual;

              select discountAmount + decode(tplDiscountCharge.PTC_DISCOUNT_ID, 0, 0, pchAmount)
                into discountAmount
                from dual;

              select CascadeAmount + decode(tplDiscountCharge.PTC_CHARGE_ID, 0, -pchAmount, pchAmount)
                into CascadeAmount
                from dual;
            end if;
          end loop;
        end if;
      end if;

      return cascadeAmount;
    else
      -- Aucun crTariff trouvé
      return null;
    end if;
  end GetFullPrice;

  function GetSaleConvertFactor(aGoodId in number, aThirdId in number)
    return number
  is
    vResult      GCO_COMPL_DATA_SALE.CDA_CONVERSION_FACTOR%type;

    cursor crComplData(aGoodId number, aThirdId number)
    is
      select   rpad(decode(PAC_CUSTOM_PARTNER_ID, null, '1            ', '0' || to_char(PAC_CUSTOM_PARTNER_ID, '000000000000') ), 13, ' ') order1
             , '1          ' order2
             , CDA_CONVERSION_FACTOR
          from GCO_COMPL_DATA_SALE
         where GCO_GOOD_ID = aGoodId
           and DIC_COMPLEMENTARY_DATA_ID is null
           and (   PAC_CUSTOM_PARTNER_ID = aThirdId
                or PAC_CUSTOM_PARTNER_ID is null)
      union
      select   '1            ' order1
             , decode(A.DIC_COMPLEMENTARY_DATA_ID, null, '1          ', '0' || rpad(A.DIC_COMPLEMENTARY_DATA_ID, 10) ) order2
             , CDA_CONVERSION_FACTOR
          from GCO_COMPL_DATA_SALE A
             , PAC_CUSTOM_PARTNER B
         where GCO_GOOD_ID = aGoodId
           and A.PAC_CUSTOM_PARTNER_ID is null
           and A.DIC_COMPLEMENTARY_DATA_ID = B.DIC_COMPLEMENTARY_DATA_ID
           and B.PAC_CUSTOM_PARTNER_ID = aThirdId
      order by 1
             , 2;

    tplComplData crComplData%rowtype;
  begin
    open crComplData(aGoodId, aThirdId);

    fetch crComplData
     into tplComplData;

    if crComplData%notfound then
      vResult  := 1;
    else
      vResult  := tplComplData.CDA_CONVERSION_FACTOR;
    end if;

    close crComplData;

    return vResult;
  end GetSaleConvertFactor;

  function GetPurchaseConvertFactor(aGoodId in number, aThirdId in number)
    return number
  is
    vResult      GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type;

    cursor crComplData(aGoodId number, aThirdId number)
    is
      select   rpad(decode(PAC_SUPPLIER_PARTNER_ID, null, '1            ', '0' || to_char(PAC_SUPPLIER_PARTNER_ID) ), 13, ' ') order1
             , '1          ' order2
             , CDA_CONVERSION_FACTOR
             , CPU_DEFAULT_SUPPLIER
          from GCO_COMPL_DATA_PURCHASE
         where GCO_GOOD_ID = aGoodId
           and DIC_COMPLEMENTARY_DATA_ID is null
           and (   PAC_SUPPLIER_PARTNER_ID = aThirdId
                or PAC_SUPPLIER_PARTNER_ID is null)
      union
      select   '1            ' order1
             , decode(A.DIC_COMPLEMENTARY_DATA_ID, null, '1          ', '0' || rpad(A.DIC_COMPLEMENTARY_DATA_ID, 10) ) order2
             , CDA_CONVERSION_FACTOR
             , CPU_DEFAULT_SUPPLIER
          from GCO_COMPL_DATA_PURCHASE A
             , PAC_SUPPLIER_PARTNER B
         where GCO_GOOD_ID = aGoodId
           and A.PAC_SUPPLIER_PARTNER_ID is null
           and A.DIC_COMPLEMENTARY_DATA_ID = B.DIC_COMPLEMENTARY_DATA_ID
           and B.PAC_SUPPLIER_PARTNER_ID = aThirdId
      order by 1
             , 2
             , 4 desc;

    tplComplData crComplData%rowtype;
  begin
    open crComplData(aGoodId, aThirdId);

    fetch crComplData
     into tplComplData;

    if crComplData%notfound then
      vResult  := 1;
    else
      vResult  := tplComplData.CDA_CONVERSION_FACTOR;
    end if;

    close crComplData;

    return vResult;
  end GetPurchaseConvertFactor;

  -- Recherche le prix pour un article
  function GetTariff4View(
    aGoodId     in number
  , aThirdId    in number
  , aDicId      in varchar2
  , aTariffType in varchar2
  , aCurrencyId in varchar2
  , aRefqty     in number
  , aRefdate    in date
  , aRecordID   in number
  , aReturnMode in number default 1
  )
    return number
  is
    vTariffAmount     number(18, 5)                               default 0;
    vPpurchaseType    varchar2(10);
    vSaleType         varchar2(10);
    vTariffId         PTC_TARIFF.PTC_TARIFF_ID%type;
    vTariffTableId    PTC_TARIFF_TABLE.PTC_TARIFF_TABLE_ID%type;
    vTariffPrice      PTC_TARIFF_TABLE.TTA_PRICE%type;
    vTariffCurrencyId PTC_TARIFF.ACS_FINANCIAL_CURRENCY_ID%type;
    vTariffUnit       PTC_TARIFF.TRF_UNIT%type;
    vRoundType        PTC_TARIFF.C_ROUND_TYPE%type;
    vRoundAmount      PTC_TARIFF.TRF_ROUND_AMOUNT%type;
    vNetTariff        PTC_TARIFF.TRF_NET_TARIFF%type;
    vSpecialTariff    PTC_TARIFF.TRF_SPECIAL_TARIFF%type;
    vThirdId          PTC_TARIFF.PAC_THIRD_ID%type;
    vDicTariffId      PTC_TARIFF.DIC_TARIFF_ID%type;
    vAmountEUR        number;
  begin
    vThirdId      := aThirdId;
    vDicTariffId  := aDicId;

    -- Recherche du prix par la méthode INDIV
    if nvl(PCS.PC_CONFIG.GetConfig('DOC_INDIV_GET_TARIFF'), '0') = '1' then
      if aReturnMode in('1') then
        PTC_INDIV_TARIFF.GetIndivTariffPrice(aGoodId
                                           , vThirdId
                                           , aRecordId
                                           , aCurrencyId
                                           , vDicTariffId
                                           , aRefQty
                                           , aRefDate
                                           , aTariffType
                                           , 'UNIQUE'
                                           , vTariffId
                                           , vTariffPrice
                                           , vTariffCurrencyId
                                           , vNetTariff
                                           , vSpecialTariff
                                            );
        return vTariffPrice;
      else
        return null;
      end if;
    else
      PTC_FIND_TARIFF.GetTariff(aGoodId
                              , vThirdId
                              , aRecordId
                              , aCurrencyId
                              , vDicTariffId
                              , aRefQty
                              , aRefDate
                              , aTariffType
                              , 'UNIQUE'
                              , vTariffId
                              , vTariffCurrencyId
                              , vNetTariff
                              , vSpecialTariff
                               );

      if     aReturnMode = '1'
         and vTariffId is not null then
        vTariffPrice  := PTC_FIND_TARIFF.GetTariffPrice(vTariffId, aRefQty, vRoundType, vRoundAmount, vTariffUnit);

        if aCurrencyId = vTariffCurrencyId then
          return vTariffPrice;
        elsif vTariffCurrencyId is not null then
          ACS_FUNCTION.ConvertAmount(vTariffPrice, vTariffCurrencyId, aCurrencyId, aRefDate, 0, 0, 0, vAmountEUR, vTariffPrice, 5);
          return vTariffPrice;
        else
          return null;
        end if;
      elsif aReturnMode = '2' then
        return vTariffId;
      elsif aReturnMode = '3' then
        begin
          select PTC_TARIFF_TABLE_ID
            into vTariffTableId
            from PTC_TARIFF_TABLE
           where PTC_TARIFF_ID = vTariffId
             and aRefQty between decode(TTA_FROM_QUANTITY, 0, aRefQty, TTA_FROM_QUANTITY) and decode(TTA_TO_QUANTITY, 0, aRefQty, TTA_TO_QUANTITY);

          return vTariffTableId;
        exception
          when no_data_found then
            return null;
        end;
      end if;
    end if;

    return vTariffAmount;
  end GetTariff4View;

  -- Recherche le prix pour un article pour
  -- utilisation dans Crystal Report
  function GetTariff4Crystal(
    aGoodId     in number
  , aThirdId    in number
  , aDicId      in varchar2
  , aTariffType in varchar2
  , aCurrencyId in varchar2
  , aRefqty     in number
  , aRefdate    in varchar2
  , aRecordID   in number
  , aReturnMode in number default 1
  )
    return number
  is
  begin
    -- Recherche le prix pour un article
    return GetTariff4View(aGoodId, aThirdId, aDicId, aTariffType, aCurrencyId, aRefqty, to_date(aRefdate, 'DD.MM.YYYY'), aRecordID, aReturnMode);
  end GetTariff4Crystal;

  /**
  * Description
  *    procedure de recherche du tarif d'un service
  */
  procedure GetServiceTariff(
    aGoodId            in     number
  , aThirdId           in out number
  , aRecordId          in     number
  , aDocCurrId         in     number
  , aDicTariffId       in out varchar2
  , aQuantity          in     number
  , aRefDate           in     date
  , aTariffType        in     varchar2
  , aTarifficationMode        varchar2
  , aFoundTariffId     in out number
  , aCurrencyId        in out number
  , aNet               in out number
  , aSpecial           in out number
  )
  is
  begin
    for ltplCurrency in (select   AAFC.ACS_FINANCIAL_CURRENCY_ID
                             from ACS_AUX_ACCOUNT_S_FIN_CURR AAFC
                                , PAC_SUPPLIER_PARTNER PSP
                                , ACS_AUXILIARY_ACCOUNT ACCO
                            where AAFC.ACS_AUXILIARY_ACCOUNT_ID = ACCO.ACS_AUXILIARY_ACCOUNT_ID
                              and ACCO.ACS_AUXILIARY_ACCOUNT_ID = PSP.ACS_AUXILIARY_ACCOUNT_ID
                              and PSP.PAC_SUPPLIER_PARTNER_ID = aThirdId
                         order by AAFC.ASC_DEFAULT
                                , AAFC.ACS_FINANCIAL_CURRENCY_ID) loop
      GetTariff(aGoodId
              , aThirdId
              , aRecordId
              , ltplCurrency.ACS_FINANCIAL_CURRENCY_ID
              , aDicTariffId
              , aQuantity
              , aRefDate
              , aTariffType
              , aTarifficationMode
              , aFoundTariffId
              , aCurrencyId
              , aNet
              , aSpecial
               );

      if aCurrencyId is not null then
        return;
      end if;
    end loop;
  end GetServiceTariff;
end PTC_FIND_TARIFF;
