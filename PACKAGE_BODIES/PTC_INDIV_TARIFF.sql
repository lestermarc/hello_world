--------------------------------------------------------
--  DDL for Package Body PTC_INDIV_TARIFF
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PTC_INDIV_TARIFF" 
is
  procedure GetIndivTariffPrice(
    good_id            in     number
  , third_id           in out number
  , record_id          in     number
  , doc_curr_id        in     number
  , tariff_id          in out varchar2
  , quantity           in     number
  , refdate            in     date
  , tariff_type        in     varchar2
  , tariffication_mode        varchar2
  , found_tariff_id    in out number
  , tariff_price       in out number
  , currency_id        in out number
  , Net                in out number
  , Special            in out number
  )
  is
  begin
    GetTariff(good_id
            , third_id
            , record_id
            , doc_curr_id
            , tariff_id
            , quantity
            , refdate
            , tariff_type
            , tariffication_mode
            , found_tariff_id
            , currency_id
            , net
            , special
             );

    if found_tariff_id is not null then
      tariff_price  := GetTariffPrice(found_tariff_id, quantity);
    else
      tariff_price  := 0;
    end if;
  end;

  -- procedure de recherche du tarif depuis un document
  -- paramètres : good_id : bien pour lequel on recherche le tarif
  --              third_id : tiers pour lequel on recherche le tarif
  --              doc_curr_id : monnaie du document
  --              refdate : date de référence
  --              tariff_type (A_FACTURER, A_PAYER) : vente/achat
  --              tarification_mode (fréquence de tarification)
  -- paramètres de retour : found_tariff_id : id du tariff trouvé (0 si pas trouvé)
  --                        currency_id : monnaie du tarif trouvé (pas toujours égale à la monnaie du document)
  --
  procedure GetTariff(
    good_id            in     number
  , third_id           in out number
  , record_id          in     number
  , doc_curr_id        in     number
  , tariff_id          in out varchar2
  , quantity           in     number
  , refdate            in     date
  , tariff_type        in     varchar2
  , tariffication_mode        varchar2
  , found_tariff_id    in out number
  , currency_id        in out number
  , net                in out number
  , special            in out number
  )
  is
    normal_tariff_id  PTC_TARIFF.PTC_TARIFF_ID%type;
    normal_price      PTC_TARIFF_TABLE.TTA_PRICE%type;
    normal_third_id   PTC_TARIFF.PAC_THIRD_ID%type;
    normal_coef       GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type      default 1;
    special_tariff_id PTC_TARIFF.PTC_TARIFF_ID%type;
    special_price     PTC_TARIFF_TABLE.TTA_PRICE%type;
    special_third_id  PTC_TARIFF.PAC_THIRD_ID%type;
    special_coef      GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type      default 1;
    docEuroCurId      ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    locCurId          ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    locEuroCurId      ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    net_normal        number(1);
    net_action        number(1);
  begin
    -- si la monnaie document est une monanie Euro,
    -- on recherche l'ID de l'Euro pour la recherche de 2ème niveau
    if ACS_FUNCTION.IsFinCurrInEuro(doc_curr_id, refdate) = 1 then
      docEuroCurId  := ACS_FUNCTION.GetEuroCurrency;
    end if;

    -- si la monnaie document est différente de la monnaie de base,
    -- on recherche l'ID de la monnaie de base pour la recherche de 3ème niveau
    if doc_curr_id <> ACS_FUNCTION.GetLocalCurrencyId then
      locCurId  := ACS_FUNCTION.GetLocalCurrencyId;

      -- si la monnaie de base est une monnaie Euro et que lka 2ème monnaie n'est pas l'Euro,
      -- on recherche l'ID de l'euro pour une recherche de 4ème niveau
      if     docEuroCurId is null
         and ACS_FUNCTION.IsFinCurrInEuro(ACS_FUNCTION.GetLocalCurrencyId, refdate) = 1 then
        locEuroCurId  := ACS_FUNCTION.GetEuroCurrency;
      end if;
    end if;

    normal_third_id   := third_id;
    GetNormalTariff(good_id
                  , normal_third_id
                  , record_id
                  , doc_curr_id
                  , tariff_id
                  , quantity
                  , refdate
                  , tariff_type
                  , tariffication_mode
                  , normal_tariff_id
                  , currency_id
                  , docEuroCurId
                  , locCurId
                  , locEuroCurId
                  , net_normal
                  , normal_price
                   );

    -- Si on a trouvé un tarif, la recherche du tarif action doit se faire dans la même monnaie
    if normal_tariff_id is not null then
      docEuroCurId  := currency_id;
      locCurId      := currency_id;
      locEuroCurId  := currency_id;
    end if;

    special_third_id  := third_id;
    GetSpecialTariff(good_id
                   , special_third_id
                   , record_id
                   , doc_curr_id
                   , tariff_id
                   , quantity
                   , refdate
                   , tariff_type
                   , tariffication_mode
                   , special_tariff_id
                   , currency_id
                   , docEuroCurId
                   , locCurId
                   , locEuroCurId
                   , net_action
                   , special_price
                    );

    -- si il y a lieu de comparer les prix, recherche des coeficient
    if     special_tariff_id is not null
       and normal_tariff_id is not null then
      -- recherche du coeficient à appliquer au prix pour la comparaison
      if tariff_type = 'A_FACTURER' then
        normal_coef   := GetSaleConvertFactor(good_id, normal_third_id) / GetSaleConvertFactor(good_id, null);
        special_coef  := GetSaleConvertFactor(good_id, special_third_id) / GetSaleConvertFactor(good_id, null);
      else
        normal_coef   := GetPurchaseConvertFactor(good_id, normal_third_id) / GetPurchaseConvertFactor(good_id, null);
        special_coef  := GetPurchaseConvertFactor(good_id, special_third_id) / GetPurchaseConvertFactor(good_id, null);
      end if;
    end if;

    if     special_tariff_id is not null
       and special_price is not null
       and (   normal_tariff_id is null
            or (normal_price / normal_coef > special_price / special_coef) ) then
      found_tariff_id  := special_tariff_id;
      third_id         := special_third_id;
      net              := net_action;
      special          := 1;
    elsif     normal_tariff_id is not null
          and normal_price is not null then
      found_tariff_id  := normal_tariff_id;
      third_id         := normal_third_id;
      net              := net_normal;
    end if;
  end;

  procedure GetNormalTariff(
    good_id            in     number
  , third_id           in out number
  , record_id          in     number
  , doc_curr_id        in     number
  , tariff_id          in out varchar2
  , quantity           in     number
  , refdate            in     date
  , tariff_type        in     varchar2
  , tariffication_mode        varchar2
  , found_tariff_id    in out number
  , currency_id        in out number
  , docEuroCurId       in     number
  , locCurId           in     number
  , locEuroCurId       in     number
  , net                in out number
  , price              in out number
  )
  is
    pur_struct   GCO_GOOD.DIC_PUR_TARIFF_STRUCT_ID%type;
    sale_struct  GCO_GOOD.DIC_SALE_TARIFF_STRUCT_ID%type;
    blnFound     number(1);

    -- curseur sur les tarifs
    cursor tariff(
      good_id            number
    , tariff_type        varchar2
    , third_id           number
    , tariff_id          varchar2
    , tariffication_mode varchar2
    , pur_struct         varchar2
    , sale_struct        varchar2
    , doc_curr_id        number
    , docEuroCurId       number
    , locCurId           number
    , locEuroCurId       number
    )
    is
      select   ptc_tariff_id
             , acs_financial_currency_id
             , trf_sql_conditional
             , trf_net_tariff
             , trf_special_tariff
             , pac_third_id
          from PTC_TARIFF
         where (   GCO_GOOD_ID = good_id
                or DIC_PUR_TARIFF_STRUCT_ID = pur_struct
                or DIC_SALE_TARIFF_STRUCT_ID = sale_struct)
           and C_TARIFF_TYPE = tariff_type
           and acs_financial_currency_id in(doc_curr_id, docEuroCurId, locCurId, locEuroCurId)
           and (   PAC_THIRD_ID = third_id
                or PAC_THIRD_ID is null)
           and refdate between nvl(TRF_STARTING_DATE, to_date('01.01.0001', 'DD.MM.YYYY') ) and nvl(TRF_ENDING_DATE, to_date('31.12.2999', 'DD.MM.YYYY') )
           and TRF_SPECIAL_TARIFF = 0
           and not(    PCS.PC_CONFIG.GetConfig('PTC_MANDATORY_TARIFF') = '1'
                   and not DIC_TARIFF_ID = tariff_id)
      order by decode(C_TARIFFICATION_MODE, tariffication_mode, '1', 'UNIQUE', '2', '3' || C_TARIFFICATION_MODE)
             , decode(gco_good_id, null, decode(sale_struct, null, decode(pur_struct, null, '3', '2'), '2'), '1')
             , decode(pac_third_id, third_id, '1', '2')
             , decode(dic_tariff_id, tariff_id, '1', '2' || dic_tariff_id)
             , decode(trf_sql_conditional, null, '2', '1')
             , decode(ACS_FINANCIAL_CURRENCY_ID, doc_curr_id, '1', docEuroCurId, '2', locCurId, '3', locEuroCurId, '4');

    tariff_tuple tariff%rowtype;
  begin
    -- Document client
    if tariff_type = 'A_FACTURER' then
      -- recherche de la structure tariffaire par rapport au client
      select nvl(tariff_id, max(DIC_TARIFF_ID) )
        into tariff_id
        from PAC_CUSTOM_PARTNER
       where PAC_CUSTOM_PARTNER_ID = third_id;

      -- recherche de la structure tariffaire de vente
      select DIC_SALE_TARIFF_STRUCT_ID
        into sale_struct
        from GCO_GOOD
       where GCO_GOOD_ID = good_id;
    end if;

    -- Document fournisseur
    if tariff_type = 'A_PAYER' then
      -- recherche de la structure tariffaire par rapport au fournisseur
      select nvl(tariff_id, max(DIC_TARIFF_ID) )
        into tariff_id
        from PAC_SUPPLIER_PARTNER
       where PAC_SUPPLIER_PARTNER_ID = third_id;

      -- recherche de la structure tariffaire d'achat
      select DIC_PUR_TARIFF_STRUCT_ID
        into pur_struct
        from GCO_GOOD
       where GCO_GOOD_ID = good_id;
    end if;

    blnFound         := 0;

    -- ouverture du curseur
    -- le premier tuple contient le tariff qui correspond le mieux aux critères passés
    -- en paramètre. Seul la condition SQL doit encore être validée
    open tariff(good_id, tariff_type, third_id, tariff_id, tariffication_mode, pur_struct, sale_struct, doc_curr_id, docEuroCurId, locCurId, locEuroCurId);

    -- positionnement sur le premier tuple
    fetch tariff
     into tariff_tuple;

    -- valeurs de retour pas défaut
    found_tariff_id  := 0;
    currency_id      := 0;

    -- boucle tant que le tarif n'a pas été validé
    while tariff%found
     and blnFound = 0 loop
      -- si il y a une condition SQL
      if tariff_tuple.trf_sql_conditional is not null then
        -- si la condition SQL est vérifiée, le tarif est OK
        if ConditionTest(third_id, record_id, tariff_tuple.trf_sql_conditional) = 1 then
          blnFound         := 1;
          found_tariff_id  := tariff_tuple.PTC_TARIFF_ID;
          net              := tariff_tuple.trf_net_tariff;
          currency_id      := tariff_tuple.ACS_FINANCIAL_CURRENCY_ID;
          third_id         := tariff_tuple.PAC_THIRD_ID;
        end if;
      -- si il n'y a pas de condition SQL, le tarif est OK
      else
        blnFound         := 1;
        net              := tariff_tuple.trf_net_tariff;
        found_tariff_id  := tariff_tuple.PTC_TARIFF_ID;
        currency_id      := tariff_tuple.ACS_FINANCIAL_CURRENCY_ID;
        third_id         := tariff_tuple.PAC_THIRD_ID;
      end if;

      -- tuple suivant
      fetch tariff
       into tariff_tuple;
    end loop;

    -- recherche du prix pour comparaison
    if blnFound = 1 then
      select max(TTA_PRICE)
        into price
        from PTC_TARIFF_TABLE
       where PTC_TARIFF_ID = found_tariff_id
         and quantity between TTA_FROM_QUANTITY and decode(TTA_TO_QUANTITY, 0, 9999999999999999, TTA_TO_QUANTITY);
    end if;

    -- fermeture du curseur
    close tariff;
  end;

  procedure GetSpecialTariff(
    good_id            in     number
  , third_id           in out number
  , record_id          in     number
  , doc_curr_id        in     number
  , tariff_id          in out varchar2
  , quantity           in     number
  , refdate            in     date
  , tariff_type        in     varchar2
  , tariffication_mode        varchar2
  , found_tariff_id    in out number
  , currency_id        in out number
  , docEuroCurId       in     number
  , locCurId           in     number
  , locEuroCurId       in     number
  , net                in out number
  , price              in out number
  )
  is
    pur_struct   GCO_GOOD.DIC_PUR_TARIFF_STRUCT_ID%type;
    sale_struct  GCO_GOOD.DIC_SALE_TARIFF_STRUCT_ID%type;
    blnFound     number(1);

    -- curseur sur les tarifs
    cursor tariff(
      good_id            number
    , tariff_type        varchar2
    , third_id           number
    , tariff_id          varchar2
    , tariffication_mode varchar2
    , pur_struct         varchar2
    , sale_struct        varchar2
    , doc_curr_id        number
    , docEuroCurId       number
    , locCurId           number
    , locEuroCurId       number
    )
    is
      select   ptc_tariff_id
             , acs_financial_currency_id
             , trf_sql_conditional
             , trf_net_tariff
             , trf_special_tariff
             , pac_third_id
          from PTC_TARIFF
         where (   GCO_GOOD_ID = good_id
                or DIC_PUR_TARIFF_STRUCT_ID = pur_struct
                or DIC_SALE_TARIFF_STRUCT_ID = sale_struct)
           and C_TARIFF_TYPE = tariff_type
           and acs_financial_currency_id in(doc_curr_id, docEuroCurId, locCurId, locEuroCurId)
           and (   PAC_THIRD_ID = third_id
                or PAC_THIRD_ID is null)
           and refdate between nvl(TRF_STARTING_DATE, to_date('01.01.0001', 'DD.MM.YYYY') ) and nvl(TRF_ENDING_DATE, to_date('31.12.2999', 'DD.MM.YYYY') )
           and TRF_SPECIAL_TARIFF = 1
           and not(    PCS.PC_CONFIG.GetConfig('PTC_MANDATORY_TARIFF') = '1'
                   and not DIC_TARIFF_ID = tariff_id)
      order by decode(C_TARIFFICATION_MODE, tariffication_mode, '1', 'UNIQUE', '2', '3' || C_TARIFFICATION_MODE)
             , decode(gco_good_id, null, decode(sale_struct, null, decode(pur_struct, null, '3', '2'), '2'), '1')
             , decode(pac_third_id, third_id, '1', '2')
             , decode(dic_tariff_id, tariff_id, '1', '2' || dic_tariff_id)
             , decode(trf_sql_conditional, null, '2', '1')
             , decode(ACS_FINANCIAL_CURRENCY_ID, doc_curr_id, '1', docEuroCurId, '2', locCurId, '3', locEuroCurId, '4');

    tariff_tuple tariff%rowtype;
  begin
    -- Document client
    if tariff_type = 'A_FACTURER' then
      -- recherche de la structure tariffaire par rapport au client
      select nvl(tariff_id, max(DIC_TARIFF_ID) )
        into tariff_id
        from PAC_CUSTOM_PARTNER
       where PAC_CUSTOM_PARTNER_ID = third_id;

      -- recherche de la structure tariffaire de vente
      select DIC_SALE_TARIFF_STRUCT_ID
        into sale_struct
        from GCO_GOOD
       where GCO_GOOD_ID = good_id;
    end if;

    -- Document fournisseur
    if tariff_type = 'A_PAYER' then
      -- recherche de la structure tariffaire par rapport au fournisseur
      select nvl(tariff_id, max(DIC_TARIFF_ID) )
        into tariff_id
        from PAC_SUPPLIER_PARTNER
       where PAC_SUPPLIER_PARTNER_ID = third_id;

      -- recherche de la structure tariffaire d'achat
      select DIC_PUR_TARIFF_STRUCT_ID
        into pur_struct
        from GCO_GOOD
       where GCO_GOOD_ID = good_id;
    end if;

    blnFound         := 0;

    -- ouverture du curseur
    -- le premier tuple contient le tariff qui correspond le mieux aux critères passés
    -- en paramètre. Seul la condition SQL doit encore être validée
    open tariff(good_id, tariff_type, third_id, tariff_id, tariffication_mode, pur_struct, sale_struct, doc_curr_id, docEuroCurId, locCurId, locEuroCurId);

    -- positionnement sur le premier tuple
    fetch tariff
     into tariff_tuple;

    -- valeurs de retour pas défaut
    found_tariff_id  := 0;

    -- boucle tant que le tarif n'a pas été validé
    while tariff%found
     and blnFound = 0 loop
      -- si il y a une condition SQL
      if tariff_tuple.trf_sql_conditional is not null then
        -- si la condition SQL est vérifiée, le tarif est OK
        if ConditionTest(third_id, record_id, tariff_tuple.trf_sql_conditional) = 1 then
          blnFound         := 1;
          found_tariff_id  := tariff_tuple.PTC_TARIFF_ID;
          currency_id      := tariff_tuple.ACS_FINANCIAL_CURRENCY_ID;
          third_id         := tariff_tuple.PAC_THIRD_ID;
        end if;
      -- si il n'y a pas de condition SQL, le tarif est OK
      else
        blnFound         := 1;
        found_tariff_id  := tariff_tuple.PTC_TARIFF_ID;
        currency_id      := tariff_tuple.ACS_FINANCIAL_CURRENCY_ID;
        third_id         := tariff_tuple.PAC_THIRD_ID;
      end if;

      -- tuple suivant
      fetch tariff
       into tariff_tuple;
    end loop;

    -- recherche du prix pour comparaison
    if blnFound = 1 then
      select max(TTA_PRICE)
        into price
        from PTC_TARIFF_TABLE
       where PTC_TARIFF_ID = found_tariff_id
         and quantity between TTA_FROM_QUANTITY and decode(TTA_TO_QUANTITY, 0, 9999999999999999, TTA_TO_QUANTITY);

      net  := tariff_tuple.trf_net_tariff;
    end if;

    -- fermeture du curseur
    close tariff;
  end;

  -- procedure de recherche des tarifs applicables dans un document
  -- paramètres : good_id : bien pour lequel on recherche le tarif
  --              third_id : tiers pour lequel on recherche le tarif
  --              doc_curr_id : monnaie du document
  --              refdate : date de référence
  --              tariff_type (A_FACTURER, A_PAYER) : vente/achat
  --              tarification_mode (fréquence de tarification)
  -- paramètres de retour : ListTariffId : Liste des tarifs trouvés
  --
  procedure GetAllTariff(
    good_id            in     number
  , third_id           in     number
  , record_id          in     number
  , doc_curr_id        in     number
  , tariff_id          in out varchar2
  , refdate            in     date
  , tariff_type        in     varchar2
  , tariffication_mode        varchar2
  , ListTariffId       in out varchar2
  )
  is
    docEuroCurId ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    locCurId     ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    locEuroCurId ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    pur_struct   GCO_GOOD.DIC_PUR_TARIFF_STRUCT_ID%type;
    sale_struct  GCO_GOOD.DIC_SALE_TARIFF_STRUCT_ID%type;
    blnFound     number(1);

    -- curseur sur les tarifs
    cursor tariff(
      good_id            number
    , tariff_type        varchar2
    , third_id           number
    , tariff_id          varchar2
    , tariffication_mode varchar2
    , pur_struct         varchar2
    , sale_struct        varchar2
    , doc_curr_id        number
    , docEuroCurId       number
    , locCurId           number
    , locEuroCurId       number
    , refdate            date
    )
    is
      select   ptc_tariff_id
             , acs_financial_currency_id
             , trf_sql_conditional
          from PTC_TARIFF
         where (   GCO_GOOD_ID = good_id
                or DIC_PUR_TARIFF_STRUCT_ID = pur_struct
                or DIC_SALE_TARIFF_STRUCT_ID = sale_struct)
           and C_TARIFF_TYPE = tariff_type
           and acs_financial_currency_id in(doc_curr_id, docEuroCurId, locCurId, locEuroCurId)
           and (   PAC_THIRD_ID = third_id
                or PAC_THIRD_ID is null)
           and refdate between nvl(TRF_STARTING_DATE, to_date('01.01.0001', 'DD.MM.YYYY') ) and nvl(TRF_ENDING_DATE, to_date('31.12.2999', 'DD.MM.YYYY') )
           and not(    PCS.PC_CONFIG.GetConfig('PTC_MANDATORY_TARIFF') = '1'
                   and not DIC_TARIFF_ID = tariff_id)
      order by decode(C_TARIFFICATION_MODE, tariffication_mode, '1', 'UNIQUE', '2', '3' || C_TARIFFICATION_MODE)
             , decode(gco_good_id, null, decode(sale_struct, null, decode(pur_struct, null, '3', '2'), '2'), '1')
             , decode(pac_third_id, third_id, '1', '2')
             , decode(dic_tariff_id, tariff_id, '1', '2' || dic_tariff_id)
             , decode(trf_sql_conditional, null, '2', '1')
             , decode(ACS_FINANCIAL_CURRENCY_ID, doc_curr_id, '1', docEuroCurId, '2', locCurId, '3', locEuroCurId, '4');

    tariff_tuple tariff%rowtype;
  begin
    -- si la monnaie document est une monanie Euro,
    -- on recherche l'ID de l'Euro pour la recherche de 2ème niveau
    if ACS_FUNCTION.IsFinCurrInEuro(doc_curr_id, refdate) = 1 then
      docEuroCurId  := ACS_FUNCTION.GetEuroCurrency;
    end if;

    -- si la monnaie document est différente de la monnaie de base,
    -- on recherche l'ID de la monnaie de base pour la recherche de 3ème niveau
    if    doc_curr_id <> ACS_FUNCTION.GetLocalCurrencyId
       or doc_curr_id is null then
      locCurId  := ACS_FUNCTION.GetLocalCurrencyId;

      -- si la monnaie de base est une monnaie Euro et que lka 2ème monnaie n'est pas l'Euro,
      -- on recherche l'ID de l'euro pour une recherche de 4ème niveau
      if     docEuroCurId is null
         and ACS_FUNCTION.IsFinCurrInEuro(ACS_FUNCTION.GetLocalCurrencyId, refdate) = 1 then
        locEuroCurId  := ACS_FUNCTION.GetEuroCurrency;
      end if;
    end if;

    -- Document client
    if tariff_type = 'A_FACTURER' then
      -- recherche de la structure tariffaire par rapport au client
      select nvl(tariff_id, max(DIC_TARIFF_ID) )
        into tariff_id
        from PAC_CUSTOM_PARTNER
       where PAC_CUSTOM_PARTNER_ID = third_id;

      -- recherche de la structure tariffaire de vente
      select DIC_SALE_TARIFF_STRUCT_ID
        into sale_struct
        from GCO_GOOD
       where GCO_GOOD_ID = good_id;
    end if;

    -- Document fournisseur
    if tariff_type = 'A_PAYER' then
      -- recherche de la structure tariffaire par rapport au fournisseur
      select nvl(tariff_id, max(DIC_TARIFF_ID) )
        into tariff_id
        from PAC_SUPPLIER_PARTNER
       where PAC_SUPPLIER_PARTNER_ID = third_id;

      -- recherche de la structure tariffaire d'achat
      select DIC_PUR_TARIFF_STRUCT_ID
        into pur_struct
        from GCO_GOOD
       where GCO_GOOD_ID = good_id;
    end if;

    blnFound      := 0;

    -- ouverture du curseur
    -- le premier tuple contient le tariff qui correspond le mieux aux critères passés
    -- en paramètre. Seul la condition SQL doit encore être validée
    open tariff(good_id
              , tariff_type
              , third_id
              , tariff_id
              , tariffication_mode
              , pur_struct
              , sale_struct
              , doc_curr_id
              , docEuroCurId
              , locCurId
              , locEuroCurId
              , refdate
               );

    -- positionnement sur le premier tuple
    fetch tariff
     into tariff_tuple;

    -- valeurs de retour pas défaut
    ListTariffId  := '0';

    -- boucle tant que le tarif n'a pas été validé
    while tariff%found loop
      -- si il y a une condition SQL
      if tariff_tuple.trf_sql_conditional is not null then
        -- si la condition SQL est vérifiée, le tarif est OK
        if ConditionTest(third_id, record_id, tariff_tuple.trf_sql_conditional) = 1 then
          ListTariffId  := ListTariffId || ',' || to_char(tariff_tuple.PTC_TARIFF_ID);
        end if;
      -- si il n'y a pas de condition SQL, le tarif est OK
      else
        ListTariffId  := ListTariffId || ',' || to_char(tariff_tuple.PTC_TARIFF_ID);
      end if;

      -- tuple suivant
      fetch tariff
       into tariff_tuple;
    end loop;

    -- fermeture du curseur
    close tariff;
  end;

  /**
  * Description
  *          recherche du prix selon l'id du tarif et la quantité
  */
  function GetTariffPrice(aTariffId in number, aQuantity in number)
    return number
  is
    result PTC_TARIFF_TABLE.TTA_PRICE%type;
  begin
    select max(TTA_PRICE / decode(nvl(TRF_UNIT, 0), 0, 1, TRF_UNIT) )
      into result
      from PTC_TARIFF_TABLE TTA
         , PTC_TARIFF TRF
     where TRF.PTC_TARIFF_ID = aTariffId
       and TTA.PTC_TARIFF_ID = TRF.PTC_TARIFF_ID
       and aQuantity between TTA_FROM_QUANTITY and decode(TTA_TO_QUANTITY, 0, 999999999999999999, TTA_TO_QUANTITY);

    return result;
  end;

  -- Teste une condition SQL et renvoie 1 si le select renvoie des valeurs
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
          raise_application_error(-20000, 'Mauvaise commande : ' || aDef_Condition);
        end if;
    end;

    return ReturnValue;
  end;

---------------------
-- Remplace les paramètres dans une requête SQl
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
  end;

  function GetSaleConvertFactor(aGoodId in number, aThirdId in number)
    return number
  is
    result           GCO_COMPL_DATA_SALE.CDA_CONVERSION_FACTOR%type;

    cursor compl_data(aGoodId number, aThirdId number)
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

    compl_data_tuple compl_data%rowtype;
  begin
    open compl_data(aGoodId, aThirdId);

    fetch Compl_data
     into compl_data_tuple;

    if Compl_data%notfound then
      result  := 1;
    else
      result  := compl_data_tuple.CDA_CONVERSION_FACTOR;
    end if;

    close compl_data;

    return result;
  end GetSaleConvertFactor;

  function GetPurchaseConvertFactor(aGoodId in number, aThirdId in number)
    return number
  is
    result           GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type;

    cursor compl_data(aGoodId number, aThirdId number)
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

    compl_data_tuple compl_data%rowtype;
  begin
    open compl_data(aGoodId, aThirdId);

    fetch Compl_data
     into compl_data_tuple;

    if Compl_data%notfound then
      result  := 1;
    else
      result  := compl_data_tuple.CDA_CONVERSION_FACTOR;
    end if;

    close compl_data;

    return result;
  end GetPurchaseConvertFactor;
end;
