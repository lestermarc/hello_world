--------------------------------------------------------
--  DDL for Package Body PTC_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PTC_FUNCTIONS" 
is
  -- Recherche le prix pour un article selon
  --    Le bien
  --    Le DIC_TARIFF_ID
  --    La monnaie
  --    La date
  --    Le type de tarif (achat(A_PAYER)-vente(A_FACTURER))
  --    Le tiers (première recherche avec, si infructueuse, sans le tiers)
  --     Si le bien a une structure tariffaire, recherche dans les tarifs par structure
  function GetTariff(
    good_id     in number
  , third_id    in number
  , dic_id      in varchar2
  , tariff_type in varchar2
  , currency_id in varchar2
  , refqty      in number
  , refdate     in date
  )
    return varchar2
  is
    tariff_amount number(18, 5) default 0;
    purchase_type varchar2(10);
    sale_type     varchar2(10);
  begin
    -- Si on a donné un tiers, recherche d'abord sur le tiers
    select nvl(max(tta_price), 0)
      into tariff_amount
      from ptc_tariff a
         , ptc_tariff_table b
     where a.ptc_tariff_id = b.ptc_tariff_id
       and gco_good_id = good_id
       and (   pac_third_id = third_id
            or (    pac_third_id is null
                and nvl(third_id, 0) = 0) )
       and dic_tariff_id = dic_id
       and c_tariff_type = tariff_type
       and acs_financial_currency_id = currency_id
       and refqty between decode(sign(tta_from_quantity), 0, 0, tta_from_quantity) and decode(sign(tta_to_quantity), 0, 9999999999999999, tta_to_quantity)
       and nvl(refdate, sysdate) between nvl(trf_starting_date, to_date('01.01.0001', 'DD.MM.YYYY') ) and nvl(trf_ending_date
                                                                                                            , to_date('31.12.2999', 'DD.MM.YYYY')
                                                                                                             )
       and not exists(
             select PTC_TARIFF_ID
               from PTC_TARIFF SUB
              where a.GCO_GOOD_ID = SUB.GCO_GOOD_ID
                and nvl(a.DIC_PUR_TARIFF_STRUCT_ID, ' ') = nvl(SUB.DIC_PUR_TARIFF_STRUCT_ID, ' ')
                and nvl(a.DIC_SALE_TARIFF_STRUCT_ID, ' ') = nvl(SUB.DIC_SALE_TARIFF_STRUCT_ID, ' ')
                and nvl(a.DIC_TARIFF_ID, ' ') = nvl(SUB.DIC_TARIFF_ID, ' ')
                and nvl(a.PAC_THIRD_ID, 0) = nvl(SUB.PAC_THIRD_ID, 0)
                and nvl(a.ACS_FINANCIAL_CURRENCY_ID, 0) = nvl(SUB.ACS_FINANCIAL_CURRENCY_ID, 0)
                and nvl(a.TRF_SQL_CONDITIONAL, ' ') = nvl(SUB.TRF_SQL_CONDITIONAL, ' ')
                and nvl(a.C_TARIFFICATION_MODE, ' ') = nvl(SUB.C_TARIFFICATION_MODE, ' ')
                and nvl(a.C_TARIFF_TYPE, ' ') = nvl(SUB.C_TARIFF_TYPE, ' ')
                and SUB.PTC_TARIFF_ID != a.PTC_TARIFF_ID
                and (trunc(nvl(refdate, sysdate) ) between nvl(TRF_STARTING_DATE, to_date('01.01.0001', 'DD.MM.YYYY') )
                                                       and nvl(TRF_ENDING_DATE, to_date('31.12.2999', 'DD.MM.YYYY') )
                    )
                and nvl(SUB.TRF_STARTING_DATE, to_date('01.01.0001', 'DD.MM.YYYY') ) > nvl(a.TRF_STARTING_DATE, to_date('01.01.0001', 'DD.MM.YYYY') ) );

    -- structure tariffaire achat
    if     tariff_amount = 0
       and tariff_type = 'A_PAYER' then
      select DIC_PUR_TARIFF_STRUCT_ID
        into purchase_type
        from gco_good
       where gco_good_id = good_id;

      if purchase_type is not null then
        select nvl(max(tta_price), 0)
          into tariff_amount
          from ptc_tariff a
             , ptc_tariff_table b
         where a.ptc_tariff_id = b.ptc_tariff_id
           and gco_good_id is null
           and DIC_PUR_TARIFF_STRUCT_ID = purchase_type
           and (   pac_third_id = third_id
                or (    pac_third_id is null
                    and nvl(third_id, 0) = 0) )
           and dic_tariff_id = dic_id
           and c_tariff_type = tariff_type
           and acs_financial_currency_id = currency_id
           and refqty between decode(sign(tta_from_quantity), 0, 0, tta_from_quantity) and decode(sign(tta_to_quantity), 0, 9999999999999999, tta_to_quantity)
           and nvl(refdate, sysdate) between nvl(trf_starting_date, to_date('01.01.0001', 'DD.MM.YYYY') )
                                         and nvl(trf_ending_date, to_date('31.12.2999', 'DD.MM.YYYY') )
           and not exists(
                 select PTC_TARIFF_ID
                   from PTC_TARIFF SUB
                  where a.DIC_PUR_TARIFF_STRUCT_ID = SUB.DIC_PUR_TARIFF_STRUCT_ID
                    and nvl(a.GCO_GOOD_ID, 0) = nvl(SUB.GCO_GOOD_ID, 0)
                    and nvl(a.DIC_SALE_TARIFF_STRUCT_ID, ' ') = nvl(SUB.DIC_SALE_TARIFF_STRUCT_ID, ' ')
                    and nvl(a.DIC_TARIFF_ID, ' ') = nvl(SUB.DIC_TARIFF_ID, ' ')
                    and nvl(a.PAC_THIRD_ID, 0) = nvl(SUB.PAC_THIRD_ID, 0)
                    and nvl(a.ACS_FINANCIAL_CURRENCY_ID, 0) = nvl(SUB.ACS_FINANCIAL_CURRENCY_ID, 0)
                    and nvl(a.TRF_SQL_CONDITIONAL, ' ') = nvl(SUB.TRF_SQL_CONDITIONAL, ' ')
                    and nvl(a.C_TARIFFICATION_MODE, ' ') = nvl(SUB.C_TARIFFICATION_MODE, ' ')
                    and nvl(a.C_TARIFF_TYPE, ' ') = nvl(SUB.C_TARIFF_TYPE, ' ')
                    and SUB.PTC_TARIFF_ID != a.PTC_TARIFF_ID
                    and (trunc(nvl(refdate, sysdate) ) between nvl(TRF_STARTING_DATE, to_date('01.01.0001', 'DD.MM.YYYY') )
                                                           and nvl(TRF_ENDING_DATE, to_date('31.12.2999', 'DD.MM.YYYY') )
                        )
                    and nvl(SUB.TRF_STARTING_DATE, to_date('01.01.0001', 'DD.MM.YYYY') ) > nvl(a.TRF_STARTING_DATE, to_date('01.01.0001', 'DD.MM.YYYY') ) );
      end if;
    end if;

    -- structure tariffaire vente
    if     tariff_amount = 0
       and tariff_type = 'A_FACTURER' then
      select DIC_SALE_TARIFF_STRUCT_ID
        into sale_type
        from gco_good
       where gco_good_id = good_id;

      if sale_type is not null then
        select nvl(max(tta_price), 0)
          into tariff_amount
          from ptc_tariff a
             , ptc_tariff_table b
         where a.ptc_tariff_id = b.ptc_tariff_id
           and gco_good_id is null
           and DIC_SALE_TARIFF_STRUCT_ID = sale_type
           and (   pac_third_id = third_id
                or (    pac_third_id is null
                    and nvl(third_id, 0) = 0) )
           and dic_tariff_id = dic_id
           and c_tariff_type = tariff_type
           and acs_financial_currency_id = currency_id
           and refqty between decode(sign(tta_from_quantity), 0, 0, tta_from_quantity) and decode(sign(tta_to_quantity), 0, 9999999999999999, tta_to_quantity)
           and nvl(refdate, sysdate) between nvl(trf_starting_date, to_date('01.01.0001', 'DD.MM.YYYY') )
                                         and nvl(trf_ending_date, to_date('31.12.2999', 'DD.MM.YYYY') )
           and not exists(
                 select PTC_TARIFF_ID
                   from PTC_TARIFF SUB
                  where a.DIC_SALE_TARIFF_STRUCT_ID = SUB.DIC_SALE_TARIFF_STRUCT_ID
                    and nvl(a.GCO_GOOD_ID, 0) = nvl(SUB.GCO_GOOD_ID, 0)
                    and nvl(a.DIC_PUR_TARIFF_STRUCT_ID, ' ') = nvl(SUB.DIC_PUR_TARIFF_STRUCT_ID, ' ')
                    and nvl(a.DIC_TARIFF_ID, ' ') = nvl(SUB.DIC_TARIFF_ID, ' ')
                    and nvl(a.PAC_THIRD_ID, 0) = nvl(SUB.PAC_THIRD_ID, 0)
                    and nvl(a.ACS_FINANCIAL_CURRENCY_ID, 0) = nvl(SUB.ACS_FINANCIAL_CURRENCY_ID, 0)
                    and nvl(a.TRF_SQL_CONDITIONAL, ' ') = nvl(SUB.TRF_SQL_CONDITIONAL, ' ')
                    and nvl(a.C_TARIFFICATION_MODE, ' ') = nvl(SUB.C_TARIFFICATION_MODE, ' ')
                    and nvl(a.C_TARIFF_TYPE, ' ') = nvl(SUB.C_TARIFF_TYPE, ' ')
                    and SUB.PTC_TARIFF_ID != a.PTC_TARIFF_ID
                    and (trunc(nvl(refdate, sysdate) ) between nvl(TRF_STARTING_DATE, to_date('01.01.0001', 'DD.MM.YYYY') )
                                                           and nvl(TRF_ENDING_DATE, to_date('31.12.2999', 'DD.MM.YYYY') )
                        )
                    and nvl(SUB.TRF_STARTING_DATE, to_date('01.01.0001', 'DD.MM.YYYY') ) > nvl(a.TRF_STARTING_DATE, to_date('01.01.0001', 'DD.MM.YYYY') ) );
      end if;
    end if;

    -- Si on avait précisé un tiers, on refait la recherche sans tiers
    if     tariff_amount = 0
       and (   third_id <> 0
            or third_id is not null) then
      tariff_amount  := GetTariff(good_id, null, dic_id, tariff_type, currency_id, refqty, refdate);
    end if;

    return tariff_amount;
  end GetTariff;

    -- Recherche le prix pour un article selon
  --    Le bien
  --    Le DIC_TARIFF_ID
  --    La monnaie
  --    La date
  --    Le type de tarif (achat(A_PAYER)-vente(A_FACTURER))
  --    Le tiers (première recherche avec, si infructueuse, sans le tiers)
  --     Si le bien a une structure tariffaire, recherche dans les tarifs par structure
  function GetTariffCrystal(
    good_id     in number
  , third_id    in number
  , dic_id      in varchar2
  , tariff_type in varchar2
  , currency_id in varchar2
  , refqty      in number
  , refdate     in varchar2
  )
    return varchar2
  is
    tariff_amount number(18, 5) default 0;
    purchase_type varchar2(10);
    sale_type     varchar2(10);
  begin
    return GetTariff(good_id, third_id, dic_id, tariff_type, currency_id, refqty, to_date(refdate, 'DD.MM.YYYY') );
  end GetTariffCrystal;

  /**
  * Description
  *     Recherche du prix d'un tariff unique
  */
  function GetUniqueTariff(aTariffId in number, aLangId in number)
    return varchar2
  is
    result varchar2(22);
  begin
    select to_char(max(TTA_PRICE), '99G999G999G999G990D99')
      into result
      from PTC_TARIFF_TABLE
     where PTC_TARIFF_ID = aTariffId
       and TTA_FROM_QUANTITY = 0
       and TTA_TO_QUANTITY = 0;

    if result is null then
      select decode(max(sign(ptc_tariff_id) ), 1, PCS.PC_FUNCTIONS.TranslateWord2('Plusieurs', aLangId), null)
        into result
        from PTC_TARIFF_TABLE
       where PTC_TARIFF_ID = aTariffId;
    end if;

    return result;
  end GetUniqueTariff;

  /**
  * Description
  *     Assignation du prix à un tariff unique
  */
  procedure SetUniqueTariff(aTariffId in number, aPrice in number)
  is
    tariffTableId PTC_TARIFF_TABLE.PTC_TARIFF_TABLE_ID%type;
  begin
    -- mode création/modif
    if aPrice <> -1 then
      -- effacement des positions de la tabelle qui n'ont pas les quantités à 0
      delete from V_PTC_TARIFF_TABLE
            where PTC_TARIFF_ID = aTariffId
              and not(    TTA_FROM_QUANTITY = 0
                      and TTA_TO_QUANTITY = 0);

      begin
        -- recherche de l'id de tabelle qu'il faut mettre à jour
        select PTC_TARIFF_TABLE_ID
          into tariffTableId
          from PTC_TARIFF_TABLE
         where PTC_TARIFF_ID = aTariffId
           and TTA_FROM_QUANTITY = 0
           and TTA_TO_QUANTITY = 0;

        -- mise à jour de la tabelle
        update V_PTC_TARIFF_TABLE
           set TTA_PRICE = aPrice
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where PTC_TARIFF_TABLE_ID = tariffTableId;
      exception
        -- si on a pas trouvé de tabelle unique à mettre à jour, on la crée
        when no_data_found then
          select init_id_seq.nextval
            into tariffTableId
            from dual;

          insert into V_PTC_TARIFF_TABLE
                      (PTC_TARIFF_TABLE_ID
                     , PTC_TARIFF_ID
                     , TTA_FROM_QUANTITY
                     , TTA_TO_QUANTITY
                     , TTA_PRICE
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (tariffTableId
                     , aTariffId
                     , 0
                     , 0
                     , aPrice
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );
      end;
    -- mode suppression
    else
      -- effacement des positions de la tabelle qui ont les quantités à 0
      delete from V_PTC_TARIFF_TABLE
            where PTC_TARIFF_ID = aTariffId
              and TTA_FROM_QUANTITY = 0
              and TTA_TO_QUANTITY = 0;
    end if;
  end SetUniqueTariff;

  /**
  * Description  procedure de calcul du montant d'une remise
  */
  procedure CalcDiscount(
    discount_id                   in     number   /* Id de la remise à calculer */
  , unit_liabled_amount           in     number   /* Montant unitaire soumis à la remise en monnaie document */
  , liabled_amount                in     number   /* Montant soumis à la remise en monnaie document */
  , test_liabled_amount           in     number   /* Montant soumis à la remise en monnaie document */
  , quantity                      in     number   /* Pour les remises de type détail, quantité de la position */
  , test_quantity                 in     number   /* Quantité de référence pour les test d'application */
  , position_id                   in     number   /* Identifiant de la position pour les remises détaillées de type 8 (plsql) */
  , document_id                   in     number   /* Identifiant du document pour les remises de type total de type 8 (plsql) */
  , currency_id                   in     number   /* Id de la monnaie du montant soumis */
  , rate_of_exchange              in     number   /* Taux de change */
  , base_price                    in     number   /* Diviseur */
  , date_ref                      in     date   /* Date de référence */
  , calculation_mode              in     varchar2   /* Mode de calcul */
  , aRate                         in out number   /* Taux */
  , aFraction                     in out number   /* Fraction */
  , fixed_amount_b                in     number   /* Montant fixe en monnaie de base */
  , fixed_amount                  in     number   /* Montant fixe en monnaie document */
  , quantity_from                 in     number   /* Quantité de */
  , quantity_to                   in     number   /* Quantité a */
  , min_amount                    in     number   /* Montant minimum de remise/taxe */
  , max_amount                    in     number   /* Montant maximum de remise/taxe */
  , exceeded_amount_from          in     number   /* Montant de dépassement de */
  , exceeded_amount_to            in     number   /* Montant de dépassement à */
  , stored_proc                   in     varchar2   /* Procedure stockée de calcul de remise/taxe */
  , is_multiplicator              in     number   /* Pour le montant fixe, multiplier par quantité ? */
  , round_type                    in     varchar2   /* Type d'arrondi */
  , round_amount                  in     number   /* Montant d'arrondi */
  , unit_detail                   in     number   /* Détail unitaire */
  , original                      in     number   /* Origine de la remise (1 = création, 0 = modification) */
  , cumulative                    in     number   /* mode cumul*/
  , discount_amount               out    number   /* Montant de la remise */
  , blnfound                      out    number   /* Remise trouvée */
  , aApplicateQuantityConstraints in     number default 1   /* application des tests de validité des quantités */
  , aApplicateAmountConstraints   in     number default 1   /* application des tests de validité des montants */
  )
  is
    local_liabled_amount    DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    internal_liabled_amount DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    vQuantity               boolean;
    vDiscountSign           number;
    vDiscountAmount         DOC_POSITION_CHARGE.PCH_AMOUNT%type;
    vMinAmount              DOC_POSITION_CHARGE.PCH_MIN_AMOUNT%type;
    vMaxAmount              DOC_POSITION_CHARGE.PCH_MAX_AMOUNT%type;
  begin
    -- Valeur de retour par défaut
    discount_amount          := 0;
    blnFound                 := 0;

    /* Recherche le signe de la quantité pour calculer les remises à
       montant fixe. Pour les remises de pied le signe est automatiquement
       positif */
    if (sign(nvl(quantity, 0) ) = 0) then
      vDiscountSign  := 1;
    else
      vDiscountSign  := sign(quantity);
    end if;

    internal_liabled_amount  := liabled_amount;
    -- conversion du montant soumis en montant monnaie locale
    local_liabled_amount     :=
              ACS_FUNCTION.ConvertAmountForView(test_liabled_amount, currency_id, ACS_FUNCTION.GetLocalCurrencyId, date_ref, rate_of_exchange, base_price, 0, 5);
    /* Traitement du cas d'une gestion d'une remise sur le montant unitaire, il
       faut multiplier par la quantité après l'application de l'arrondi. */
    vQuantity                :=(nvl(unit_detail, 0) = 1);

    if (vQuantity) then
      internal_liabled_amount  := unit_liabled_amount;
    end if;

    if calculation_mode in('4', '5') then
      vMinAmount  := ACS_FUNCTION.ConvertAmountForView(min_amount, ACS_FUNCTION.GetLocalCurrencyId, currency_id, date_ref, rate_of_exchange, base_price, 0, 5);
      vMaxAmount  := ACS_FUNCTION.ConvertAmountForView(max_amount, ACS_FUNCTION.GetLocalCurrencyId, currency_id, date_ref, rate_of_exchange, base_price, 0, 5);
    end if;

    /**
    /* Montant */
    if calculation_mode = '0' then
      /* En création d'une remise à montant fixe, il faut convertir le montant
         inscrit dans la remise en monnaie document. */
      if (original = 1) then
        vDiscountAmount  :=
                  ACS_FUNCTION.ConvertAmountForView(fixed_amount_b, ACS_FUNCTION.GetLocalCurrencyId, currency_id, date_ref, rate_of_exchange, base_price, 0, 5);
        discount_amount  := vDiscountAmount;   -- arrondi à 2 décimales
      else
        /* En modification d'une remise à montant fixe, il faut utiliser le montant fixe
           de la remise en monnaie document. */
        discount_amount  := fixed_amount;
      end if;

      /* Le montant de la remise doit être du même signe que le montant soumis */
      discount_amount  := discount_amount * vDiscountSign;
      blnFound         := 1;
    /**
    /* Montant sur dépassement */
    elsif     calculation_mode = '1'
          and (    (     (    (local_liabled_amount >= exceeded_amount_from)
                          or exceeded_amount_from = 0)
                    and (    (local_liabled_amount <= exceeded_amount_to)
                         or exceeded_amount_to = 0)
                   )
               or cumulative = 1
               or aApplicateAmountConstraints = 0
              ) then
      /* En création d'une remise à montant fixe, il faut convertir le montant
         inscrit dans la remise en monnaie document. */
      if (original = 1) then
        vDiscountAmount  :=
                  ACS_FUNCTION.ConvertAmountForView(fixed_amount_b, ACS_FUNCTION.GetLocalCurrencyId, currency_id, date_ref, rate_of_exchange, base_price, 0, 5);
        discount_amount  := vDiscountAmount;   -- arrondi à 2 décimales
      else
        /* En modification d'une remise à montant fixe, il faut utiliser le montant fixe
           de la remise en monnaie document. */
        discount_amount  := fixed_amount;
      end if;

      /* Le montant de la remise doit être du même signe que le montant soumis */
      discount_amount  := discount_amount * vDiscountSign;
      blnFound         := 1;
    /**
    /* Taux */
    elsif calculation_mode = '2' then
      discount_amount  := internal_liabled_amount *(aRate / aFraction);
      blnFound         := 1;
    /**
    /* Taux sur dépassement */
    elsif     calculation_mode = '3'
          and (    (     (    (local_liabled_amount >= exceeded_amount_from)
                          or exceeded_amount_from = 0)
                    and (    (local_liabled_amount <= exceeded_amount_to)
                         or exceeded_amount_to = 0)
                   )
               or cumulative = 1
               or aApplicateAmountConstraints = 0
              ) then
      discount_amount  := internal_liabled_amount *(aRate / aFraction);
      blnFound         := 1;
    /**
    /* Taux avec Min/Max */
    elsif calculation_mode = '4' then
      if internal_liabled_amount *(aRate / aFraction) < vMinAmount then
        discount_amount  := vMinAmount;
        /* Désactivation du mode détail unitaire. */
        vQuantity        := false;
      elsif internal_liabled_amount *(aRate / aFraction) > vMaxAmount then
        discount_amount  := vMaxAmount;
        /* Désactivation du mode détail unitaire. */
        vQuantity        := false;
      else
        discount_amount  := internal_liabled_amount *(aRate / aFraction);
      end if;

      blnFound  := 1;
    /**
    /* Taux sur dépassement avec Min/Max */
    elsif     calculation_mode = '5'
          and (    (     (    (local_liabled_amount >= exceeded_amount_from)
                          or exceeded_amount_from = 0)
                    and (    (local_liabled_amount <= exceeded_amount_to)
                         or exceeded_amount_to = 0)
                   )
               or cumulative = 1
               or aApplicateAmountConstraints = 0
              ) then
      if internal_liabled_amount *(aRate / aFraction) < vMinAmount then
        discount_amount  := vMinAmount;
        /* Désactivation du mode détail unitaire. */
        vQuantity        := false;
      elsif internal_liabled_amount *(aRate / aFraction) > vMaxAmount then
        discount_amount  := vMaxAmount;
        /* Désactivation du mode détail unitaire. */
        vQuantity        := false;
      else
        discount_amount  := internal_liabled_amount *(aRate / aFraction);
      end if;

      blnFound  := 1;
    /**
    /* Montant sur quantité */
    elsif     calculation_mode = '6'
          and (    (     (    (abs(test_quantity) >= quantity_from)
                          or quantity_from = 0)
                    and (    (abs(test_quantity) <= quantity_to)
                         or quantity_to = 0) )
               or cumulative = 1
               or aApplicateQuantityConstraints = 0
              ) then
      /* En création d'une remise à montant fixe, il faut convertir le montant
         inscrit dans la remise en monnaie document. */
      if (original = 1) then
        vDiscountAmount  :=
                  ACS_FUNCTION.ConvertAmountForView(fixed_amount_b, ACS_FUNCTION.GetLocalCurrencyId, currency_id, date_ref, rate_of_exchange, base_price, 0, 5);
        discount_amount  := vDiscountAmount;   -- arrondi à 2 décimales
      else
        /* En modification d'une remise à montant fixe, il faut utiliser le montant fixe
           de la remise en monnaie document. */
        discount_amount  := fixed_amount;
      end if;

      blnFound         := 1;
      /* Le montant de la remise doit être du même signe que le montant soumis */
      discount_amount  := discount_amount * vDiscountSign;
    /**
    /* Taux sur quantité */
    elsif     calculation_mode = '7'
          and (    (     (    (abs(test_quantity) >= quantity_from)
                          or quantity_from = 0)
                    and (    (abs(test_quantity) <= quantity_to)
                         or quantity_to = 0) )
               or cumulative = 1
               or aApplicateQuantityConstraints = 0
              ) then
      discount_amount  := internal_liabled_amount *(aRate / aFraction);
      blnFound         := 1;
    /**
    /* Procedure stockée  montant */
    elsif calculation_mode = '8' then
      -- si on a pas l'id de la position ou de document on ne calcule pas (appel depuis GetFullPrice, risque de plantée)
      if nvl(position_id, document_id) is not null then
        discount_amount  := GetProcedureAmount(stored_proc, nvl(position_id, document_id) );

        if discount_amount is not null then
          /* Le montant de la remise doit être du même signe que le montant soumis */
          discount_amount  := discount_amount * vDiscountSign;
          blnFound         := 1;
        end if;
      end if;
    /* Procedure stockée taux */
    elsif calculation_mode = '9' then
      -- si on a pas l'id de la position ou de document on ne calcule pas (appel depuis GetFullPrice, risque de plantée)
      if nvl(position_id, document_id) is not null then
        aRate      := GetProcedureAmount(stored_proc, nvl(position_id, document_id) );
        aFraction  := 100;

        if aRate is not null then
          /* Le montant de la remise doit être du même signe que le montant soumis */
          discount_amount  := internal_liabled_amount * aRate / aFraction * vDiscountSign;
          blnFound         := 1;
        end if;
      end if;
    end if;

    -- pour les remises de type montant, si le flag multiplier par qte est activé,
    -- on multiplie le montant unitaire par la quantité
    if     calculation_mode in('0', '1', '6')
       and is_multiplicator = 1 then
      discount_amount  := discount_amount * abs(quantity);
    end if;

    discount_amount          := ACS_FUNCTION.PcsRound(discount_amount, round_type, round_amount);

    /* Dans le cadre d'une gestion d'une remise sur le montant unitaire, il
       faut multiplier par la quantité après l'application de l'arrondi. */
    if     calculation_mode in('2', '3', '4', '5', '7', '9')
       and vQuantity then
      discount_amount  := discount_amount * abs(quantity);
    end if;
  exception
    when no_data_found then
      discount_amount  := 0;
  end CalcDiscount;

  /**
  * Description  procedure de calcul du montant d'une remise
  */
  procedure CalcDiscount(
    discount_id                   in     number   /* Id de la remise à calculer */
  , unit_liabled_amount           in     number   /* Montant unitaire soumis à la remise en monnaie document */
  , liabled_amount                in     number   /* Montant soumis à la remise en monnaie document */
  , test_liabled_amount           in     number   /* Montant soumis à la remise en monnaie document */
  , quantity                      in     number   /* Pour les remises de type détail, quantité de la position */
  , position_id                   in     number   /* Identifiant de la position pour les remises détaillées de type 8 (plsql) */
  , document_id                   in     number   /* Identifiant du document pour les remises de type total de type 8 (plsql) */
  , currency_id                   in     number   /* Id de la monnaie du montant soumis */
  , rate_of_exchange              in     number   /* Taux de change */
  , base_price                    in     number   /* Diviseur */
  , date_ref                      in     date   /* Date de référence */
  , calculation_mode              in     varchar2   /* Mode de calcul */
  , aRate                         in out number   /* Taux */
  , aFraction                     in out number   /* Fraction */
  , fixed_amount_b                in     number   /* Montant fixe en monnaie de base */
  , fixed_amount                  in     number   /* Montant fixe en monnaie document */
  , quantity_from                 in     number   /* Quantité de */
  , quantity_to                   in     number   /* Quantité a */
  , min_amount                    in     number   /* Montant minimum de remise/taxe */
  , max_amount                    in     number   /* Montant maximum de remise/taxe */
  , exceeded_amount_from          in     number   /* Montant de dépassement de */
  , exceeded_amount_to            in     number   /* Montant de dépassement à */
  , stored_proc                   in     varchar2   /* Procedure stockée de calcul de remise/taxe */
  , is_multiplicator              in     number   /* Pour le montant fixe, multiplier par quantité ? */
  , round_type                    in     varchar2   /* Type d'arrondi */
  , round_amount                  in     number   /* Montant d'arrondi */
  , unit_detail                   in     number   /* Détail unitaire */
  , original                      in     number   /* Origine de la remise (1 = création, 0 = modification) */
  , cumulative                    in     number   /* mode cumul*/
  , discount_amount               out    number   /* Montant de la remise */
  , blnfound                      out    number   /* Remise trouvée */
  , aApplicateQuantityConstraints in     number default 1   /* application des tests de validité des quantités */
  , aApplicateAmountConstraints   in     number default 1
  )   /* application des tests de validité des montants */
  is
  begin
    CalcDiscount(discount_id
               , unit_liabled_amount
               , liabled_amount
               , test_liabled_amount
               , quantity
               , quantity
               , position_id
               , document_id
               , currency_id
               , rate_of_exchange
               , base_price
               , date_ref
               , calculation_mode
               , aRate
               , aFraction
               , fixed_amount_b
               , fixed_amount
               , quantity_from
               , quantity_to
               , min_amount
               , max_amount
               , exceeded_amount_from
               , exceeded_amount_to
               , stored_proc
               , is_multiplicator
               , round_type
               , round_amount
               , unit_detail
               , original
               , cumulative
               , discount_amount
               , blnfound
               , aApplicateQuantityConstraints
               , aApplicateAmountConstraints
                );
  end CalcDiscount;

  /**
  * Description  procedure de calcul du montant d'une taxe
  */
  procedure CalcCharge(
    charge_id                     in     number   /* Id de la taxe à calculer */
  , charge_name                   in     varchar2   /* Nom de la taxe */
  , unit_liabled_amount           in     number   /* Montant unitaire soumis à la taxe en monnaie document */
  , liabled_amount                in     number   /* Montant soumis à la taxe en monnaie document */
  , test_liabled_amount           in     number   /* Montant soumis à la remise en monnaie document */
  , quantity                      in     number   /* Pour les taxes de type détail, quantité de la position */
  , test_quantity                 in     number   /* Quantité de référence pour les test d'application */
  , good_id                       in     number   /* Identifiant du bien */
  , third_id                      in     number   /* Identifiant du tiers */
  , position_id                   in     number   /* Identifiant de la position pour les taxes détaillées de type 8 (plsql) */
  , document_id                   in     number   /* Identifiant du document pour les taxes de type total de type 8 (plsql) */
  , currency_id                   in     number   /* Id de la monnaie du montant soumis */
  , rate_of_exchange              in     number   /* Taux de change */
  , base_price                    in     number   /* Diviseur */
  , date_ref                      in     date   /* Date de référence */
  , calculation_mode              in     varchar2   /* Mode de calcul */
  , aRate                         in out number   /* Taux */
  , aFraction                     in out number   /* Fraction */
  , fixed_amount_b                in     number   /* Montant fixe en monnaie de base */
  , fixed_amount                  in     number   /* Montant fixe en monnaie document */
  , quantity_from                 in     number   /* Quantité de */
  , quantity_to                   in     number   /* Quantité a */
  , min_amount                    in     number   /* Montant minimum de remise/taxe */
  , max_amount                    in     number   /* Montant maximum de remise/taxe */
  , exceeded_amount_from          in     number   /* Montant de dépassement de */
  , exceeded_amount_to            in     number   /* Montant de dépassement à */
  , stored_proc                   in     varchar2   /* Procedure stockée de calcul de remise/taxe */
  , is_multiplicator              in     number   /* Pour le montant fixe, multiplier par quantité ? */
  , automatic_calc                in     number   /* Calculation auto ou à partir de sql_Extern_item */
  , sql_extern_item               in     varchar2   /* Commande sql de recherche du montant soumis à la calculation */
  , round_type                    in     varchar2   /* Type d'arrondi */
  , round_amount                  in     number   /* Montant d'arrondi */
  , unit_detail                   in     number   /* Détail unitaire */
  , original                      in     number   /* Origine de la taxe (1 = création, 0 = modification) */
  , cumulative                    in     number   /* mode cumul*/
  , charge_amount                 out    number   /* Montant de la taxe */
  , blnfound                      out    number   /* Remise trouvée */
  , aApplicateQuantityConstraints in     number default 1   /* application des tests de validité des quantités */
  , aApplicateAmountConstraints   in     number default 1
  )   /* application des tests de validité des montants */
  is
    local_liabled_amount    DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    internal_liabled_amount DOC_POSITION.POS_GROSS_UNIT_VALUE%type;
    vQuantity               boolean;
    vChargeSign             number;
    vChargeAmount           DOC_POSITION_CHARGE.PCH_AMOUNT%type;
    vMinAmount              DOC_POSITION_CHARGE.PCH_MIN_AMOUNT%type;
    vMaxAmount              DOC_POSITION_CHARGE.PCH_MAX_AMOUNT%type;
  begin
    -- Valeur de retour par défaut
    charge_amount         := 0;
    blnFound              := 0;

    /* Recherche le signe du montant soumis pour calculer les taxes à
       montant fixe. Pour les taxes de pied le signe est automatiquement positif */
    if (sign(nvl(quantity, 0) ) = 0) then
      vChargeSign  := 1;
    else
      vChargeSign  := sign(quantity);
    end if;

    if automatic_calc = 0 then
      internal_liabled_amount  := GetExternalValue(charge_name, sql_extern_item, good_id, third_id, document_id, position_id);
    else
      internal_liabled_amount  := liabled_amount;
    end if;

    /* Traitement du cas d'une gestion d'une remise sur le montant unitaire, il
       faut multiplier par la quantité après l'application de l'arrondi. */
    vQuantity             :=(nvl(unit_detail, 0) = 1);

    if (vQuantity) then
      /* Utilise la valeur soumise unitaire uniquement comme si le montant soumis ne
         provient pas d'une commande SQL externe. */
      if automatic_calc = 1 then
        internal_liabled_amount  := unit_liabled_amount;
      end if;
    end if;

    -- conversion du montant soumis en montant monnaie locale
    local_liabled_amount  :=
              ACS_FUNCTION.ConvertAmountForView(test_liabled_amount, currency_id, ACS_FUNCTION.GetLocalCurrencyId, date_ref, rate_of_exchange, base_price, 0, 5);

    if calculation_mode in('4', '5') then
      vMinAmount  := ACS_FUNCTION.ConvertAmountForView(min_amount, ACS_FUNCTION.GetLocalCurrencyId, currency_id, date_ref, rate_of_exchange, base_price, 0, 5);
      vMaxAmount  := ACS_FUNCTION.ConvertAmountForView(max_amount, ACS_FUNCTION.GetLocalCurrencyId, currency_id, date_ref, rate_of_exchange, base_price, 0, 5);
    end if;

    /**
    /* Montant */
    if calculation_mode = '0' then
      /* En création d'une taxe à montant fixe, il faut convertir le montant
         inscrit dans la taxe en monnaie document. */
      if (original = 1) then
        vChargeAmount  :=
                  ACS_FUNCTION.ConvertAmountForView(fixed_amount_b, ACS_FUNCTION.GetLocalCurrencyId, currency_id, date_ref, rate_of_exchange, base_price, 0, 5);
        charge_amount  := vChargeAmount;
      else
        /* En modification d'une taxe à montant fixe, il faut utiliser le montant fixe
           de la taxe en monnaie document. */
        charge_amount  := fixed_amount;
      end if;

      /* Le montant de la taxe doit être du même signe que le montant soumis */
      charge_amount  := charge_amount * vChargeSign;
      blnFound       := 1;
    /**
    /* Montant sur dépassement */
    elsif     calculation_mode = '1'
          and (    (     (    (local_liabled_amount >= exceeded_amount_from)
                          or exceeded_amount_from = 0)
                    and (    (local_liabled_amount <= exceeded_amount_to)
                         or exceeded_amount_to = 0)
                   )
               or cumulative = 1
               or aApplicateAmountConstraints = 0
              ) then
      /* En création d'une taxe à montant fixe, il faut convertir le montant
         inscrit dans la taxe en monnaie document. */
      if (original = 1) then
        vChargeAmount  :=
                  ACS_FUNCTION.ConvertAmountForView(fixed_amount_b, ACS_FUNCTION.GetLocalCurrencyId, currency_id, date_ref, rate_of_exchange, base_price, 0, 5);
        charge_amount  := vChargeAmount;
      else
        /* En modification d'une taxe à montant fixe, il faut utiliser le montant fixe
           de la taxe en monnaie document. */
        charge_amount  := fixed_amount;
      end if;

      /* Le montant de la taxe doit être du même signe que le montant soumis */
      charge_amount  := charge_amount * vChargeSign;
      blnFound       := 1;
    /**
    /* Taux */
    elsif calculation_mode = '2' then
      charge_amount  := internal_liabled_amount *(aRate / aFraction);
      blnFound       := 1;
    /**
    /* Taux sur dépassement */
    elsif     calculation_mode = '3'
          and (    (     (    (local_liabled_amount >= exceeded_amount_from)
                          or exceeded_amount_from = 0)
                    and (    (local_liabled_amount <= exceeded_amount_to)
                         or exceeded_amount_to = 0)
                   )
               or cumulative = 1
               or aApplicateAmountConstraints = 0
              ) then
      charge_amount  := internal_liabled_amount *(aRate / aFraction);
      blnFound       := 1;
    /**
    /* Taux avec Min/Max */
    elsif calculation_mode = '4' then
      if internal_liabled_amount *(aRate / aFraction) < vMinAmount then
        charge_amount  := vMinAmount;
        /* Désactivation du mode détail unitaire. */
        vQuantity      := false;
      elsif internal_liabled_amount *(aRate / aFraction) > vMaxAmount then
        charge_amount  := vMaxAmount;
        /* Désactivation du mode détail unitaire. */
        vQuantity      := false;
      else
        charge_amount  := internal_liabled_amount *(aRate / aFraction);
      end if;

      blnFound  := 1;
    /**
    /* Taux sur dépassement avec Min/Max */
    elsif     calculation_mode = '5'
          and (    (     (    (local_liabled_amount >= exceeded_amount_from)
                          or exceeded_amount_from = 0)
                    and (    (local_liabled_amount <= exceeded_amount_to)
                         or exceeded_amount_to = 0)
                   )
               or cumulative = 1
               or aApplicateAmountConstraints = 0
              ) then
      if internal_liabled_amount *(aRate / aFraction) < vMinAmount then
        charge_amount  := vMinAmount;
        /* Désactivation du mode détail unitaire. */
        vQuantity      := false;
      elsif internal_liabled_amount *(aRate / aFraction) > vMaxAmount then
        charge_amount  := vMaxAmount;
        /* Désactivation du mode détail unitaire. */
        vQuantity      := false;
      else
        charge_amount  := internal_liabled_amount *(aRate / aFraction);
      end if;

      blnFound  := 1;
    /**
    /* Montant sur quantité */
    elsif     calculation_mode = '6'
          and (    (     (    (abs(test_quantity) >= quantity_from)
                          or quantity_from = 0)
                    and (    (abs(test_quantity) <= quantity_to)
                         or quantity_to = 0) )
               or cumulative = 1
               or aApplicateQuantityConstraints = 0
              ) then
      /* En création d'une taxe à montant fixe, il faut convertir le montant
         inscrit dans la taxe en monnaie document. */
      if (original = 1) then
        vChargeAmount  :=
                  ACS_FUNCTION.ConvertAmountForView(fixed_amount_b, ACS_FUNCTION.GetLocalCurrencyId, currency_id, date_ref, rate_of_exchange, base_price, 0, 5);
        charge_amount  := vChargeAmount;
      else
        /* En modification d'une taxe à montant fixe, il faut utiliser le montant fixe
           de la taxe en monnaie document. */
        charge_amount  := fixed_amount;
      end if;

      /* Le montant de la taxe doit être du même signe que le montant soumis */
      charge_amount  := charge_amount * vChargeSign;
      blnFound       := 1;
    /**
    /* Taux sur quantité */
    elsif     calculation_mode = '7'
          and (    (     (    (abs(test_quantity) >= quantity_from)
                          or quantity_from = 0)
                    and (    (abs(test_quantity) <= quantity_to)
                         or quantity_to = 0) )
               or cumulative = 1
               or aApplicateQuantityConstraints = 0
              ) then
      charge_amount  := internal_liabled_amount *(aRate / aFraction);
      blnFound       := 1;
    /**
    /* Procedure stockée montant */
    elsif calculation_mode = '8' then
      -- si on a pas l'id de la position ou de document on ne calcule pas (appel depuis GetFullPrice, risque de plantée)
      if nvl(position_id, document_id) is not null then
        charge_amount  := GetProcedureAmount(stored_proc, nvl(position_id, document_id) );

        if charge_amount is not null then
          /* Le montant de la taxe doit être du même signe que le montant soumis */
          charge_amount  := charge_amount * vChargeSign;
          blnFound       := 1;
        end if;
      end if;
    /**
    /* Procedure stockée taux */
    elsif calculation_mode = '9' then
      -- si on a pas l'id de la position ou de document on ne calcule pas (appel depuis GetFullPrice, risque de plantée)
      if nvl(position_id, document_id) is not null then
        aRate      := GetProcedureAmount(stored_proc, nvl(position_id, document_id) );
        aFraction  := 100;

        if aRate is not null then
          /* Le montant de la taxe doit être du même signe que le montant soumis */
          charge_amount  := internal_liabled_amount * aRate / aFraction * vChargeSign;
          blnFound       := 1;
        end if;
      end if;
    end if;

    -- pour les taxes de type montant, si le flag multiplier par qte est activé,
    -- on multiplie le montant unitaire par la quantité
    if     calculation_mode in('0', '1', '6')
       and is_multiplicator = 1 then
      charge_amount  := charge_amount * abs(quantity);
    end if;

    charge_amount         := ACS_FUNCTION.PcsRound(charge_amount, round_type, round_amount);

    /* Dans le cadre d'une gestion d'une taxe sur le montant unitaire, il
       faut multiplier par la quantité après l'application de l'arrondi. */
    if     calculation_mode in('2', '3', '4', '5', '7', '9')
       and vQuantity then
      charge_amount  := charge_amount * abs(quantity);
    end if;
  exception
    when no_data_found then
      charge_amount  := 0;
  end CalcCharge;

  /**
  * Description  procedure de calcul du montant d'une taxe
  */
  procedure CalcCharge(
    charge_id                     in     number   /* Id de la taxe à calculer */
  , charge_name                   in     varchar2   /* Nom de la taxe */
  , unit_liabled_amount           in     number   /* Montant unitaire soumis à la taxe en monnaie document */
  , liabled_amount                in     number   /* Montant soumis à la taxe en monnaie document */
  , test_liabled_amount           in     number   /* Montant soumis à la remise en monnaie document */
  , quantity                      in     number   /* Pour les taxes de type détail, quantité de la position */
  , good_id                       in     number   /* Identifiant du bien */
  , third_id                      in     number   /* Identifiant du tiers */
  , position_id                   in     number   /* Identifiant de la position pour les taxes détaillées de type 8 (plsql) */
  , document_id                   in     number   /* Identifiant du document pour les taxes de type total de type 8 (plsql) */
  , currency_id                   in     number   /* Id de la monnaie du montant soumis */
  , rate_of_exchange              in     number   /* Taux de change */
  , base_price                    in     number   /* Diviseur */
  , date_ref                      in     date   /* Date de référence */
  , calculation_mode              in     varchar2   /* Mode de calcul */
  , aRate                         in out number   /* Taux */
  , aFraction                     in out number   /* Fraction */
  , fixed_amount_b                in     number   /* Montant fixe en monnaie de base */
  , fixed_amount                  in     number   /* Montant fixe en monnaie document */
  , quantity_from                 in     number   /* Quantité de */
  , quantity_to                   in     number   /* Quantité a */
  , min_amount                    in     number   /* Montant minimum de remise/taxe */
  , max_amount                    in     number   /* Montant maximum de remise/taxe */
  , exceeded_amount_from          in     number   /* Montant de dépassement de */
  , exceeded_amount_to            in     number   /* Montant de dépassement à */
  , stored_proc                   in     varchar2   /* Procedure stockée de calcul de remise/taxe */
  , is_multiplicator              in     number   /* Pour le montant fixe, multiplier par quantité ? */
  , automatic_calc                in     number   /* Calculation auto ou à partir de sql_Extern_item */
  , sql_extern_item               in     varchar2   /* Commande sql de recherche du montant soumis à la calculation */
  , round_type                    in     varchar2   /* Type d'arrondi */
  , round_amount                  in     number   /* Montant d'arrondi */
  , unit_detail                   in     number   /* Détail unitaire */
  , original                      in     number   /* Origine de la taxe (1 = création, 0 = modification) */
  , cumulative                    in     number   /* mode cumul*/
  , charge_amount                 out    number   /* Montant de la taxe */
  , blnfound                      out    number   /* Remise trouvée */
  , aApplicateQuantityConstraints in     number default 1   /* application des tests de validité des quantités */
  , aApplicateAmountConstraints   in     number default 1
  )   /* application des tests de validité des montants */
  is
  begin
    CalcCharge(charge_id
             , charge_name
             , unit_liabled_amount
             , liabled_amount
             , test_liabled_amount
             , quantity
             , quantity
             , good_id
             , third_id
             , position_id
             , document_id
             , currency_id
             , rate_of_exchange
             , base_price
             , date_ref
             , calculation_mode
             , aRate
             , aFraction
             , fixed_amount_b
             , fixed_amount
             , quantity_from
             , quantity_to
             , min_amount
             , max_amount
             , exceeded_amount_from
             , exceeded_amount_to
             , stored_proc
             , is_multiplicator
             , automatic_calc
             , sql_extern_item
             , round_type
             , round_amount
             , unit_detail
             , original
             , cumulative
             , charge_amount
             , blnfound
             , aApplicateQuantityConstraints
             , aApplicateAmountConstraints
              );
  end CalcCharge;

  /**
  * Description : fonction qui évalue et retourne  la valeur de la la fonction pl/sql
  */
  function GetProcedureAmount(procname in varchar2, param_id in number)
    return number
  is
    SqlCommand    varchar2(2000);
    DynamicCursor integer;
    ErrorCursor   integer;
    result        number(18, 5);
  begin
    SqlCommand     := 'SELECT ' || procname || '(' || param_id || ') FROM DUAL';
    -- Attribution d'un Handle de curseur
    DynamicCursor  := DBMS_SQL.open_cursor;
    -- Vérification de la syntaxe de la commande SQL
    DBMS_SQL.Parse(DynamicCursor, SqlCommand, DBMS_SQL.V7);
    -- Exécution de la commande SQL
    ErrorCursor    := DBMS_SQL.execute(DynamicCursor);
    DBMS_SQL.Define_column(DynamicCursor, 1, result);

    -- Extraction de la valeur de la procedure
    if DBMS_SQL.fetch_rows(DynamicCursor) > 0 then
      DBMS_SQL.column_value(DynamicCursor, 1, result);
    end if;

    -- Ferme le curseur
    DBMS_SQL.close_cursor(DynamicCursor);
    return result;
  exception
    when others then
      if DBMS_SQL.is_open(DynamicCursor) then
        DBMS_SQL.close_cursor(DynamicCursor);
        raise_application_error(-20000, 'PCS - Error with procedure : ' || procname || chr(13) || sqlerrm);
      end if;
  end GetProcedureAmount;

  /**
  * Description
  *         Evaluation de la commande sql externe
  */
  function GetExternalValue(ChargeName in varchar2, aSqlCommand in varchar2, good_id in number, third_id in number, document_id in number, position_id in number)
    return number
  is
    SqlCommand    varchar2(2000);
    DynamicCursor integer;
    ErrorCursor   integer;
    result        number(18, 5);
  begin
    SqlCommand     := aSqlCommand;
    SqlCommand     := replace(SqlCommand, ':GCO_GOOD_ID', to_char(good_id) );
    SqlCommand     := replace(SqlCommand, ':PAC_THIRD_ID', to_char(third_id) );
    SqlCommand     := replace(SqlCommand, ':DOC_DOCUMENT_ID', to_char(document_id) );
    SqlCommand     := replace(SqlCommand, ':DOC_POSITION_ID', to_char(position_id) );
    -- Attribution d'un Handle de curseur
    DynamicCursor  := DBMS_SQL.open_cursor;
    -- Vérification de la syntaxe de la commande SQL
    DBMS_SQL.Parse(DynamicCursor, SqlCommand, DBMS_SQL.V7);
    -- Exécution de la commande SQL
    ErrorCursor    := DBMS_SQL.execute(DynamicCursor);
    DBMS_SQL.Define_column(DynamicCursor, 1, result);

    -- Extraction de la valeur de la procedure
    if DBMS_SQL.fetch_rows(DynamicCursor) > 0 then
      DBMS_SQL.column_value(DynamicCursor, 1, result);
    end if;

    -- Ferme le curseur
    DBMS_SQL.close_cursor(DynamicCursor);
    return result;
  exception
    when others then
      if DBMS_SQL.is_open(DynamicCursor) then
        DBMS_SQL.close_cursor(DynamicCursor);
        raise_application_error(-20000, 'PCS - Error with external SQL command of ' || ChargeName);
      end if;
  end GetExternalValue;

  /**
  * Nom : ReturnNull
  * Description
  *       fonction de test retournant NULL pour les remises/taxes PLSQL
  */
  function ReturnNULL(id in number)
    return number
  is
  begin
    return null;
  end ReturnNULL;

  /**
  * Nom : ReturnOne
  * Description
  *       fonction de test retournant 1 pour les remises/taxes PLSQL
  */
  function ReturnOne(id in number)
    return number
  is
  begin
    return 1;
  end ReturnOne;

  /**
  * Description : Duplication des tarifs d'un bien vers un autre
  */
  procedure DuplicateAndHistoryTariff(
    aSourceTariffID     in     PTC_TARIFF.PTC_TARIFF_ID%type
  , aNewStartDate       in     date
  , aMultiplicationCoef in     number
  , aTargetTariffID     out    PTC_TARIFF.PTC_TARIFF_ID%type
  )
  is
    NewTariffID PTC_TARIFF.PTC_TARIFF_ID%type;
  begin
    -- ID du nouveau tarif
    select INIT_ID_SEQ.nextval
      into aTargetTariffID
      from dual;

    -- Mise à jour de la date de fin de validité du tariff de référence
    update PTC_TARIFF
       set TRF_ENDING_DATE = trunc(aNewStartDate - 1)
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where PTC_TARIFF_ID = aSourceTariffId;

    -- Création des données de la table PTC_TARIFF
    insert into PTC_TARIFF
                (PTC_TARIFF_ID
               , GCO_GOOD_ID
               , DIC_TARIFF_ID
               , ACS_FINANCIAL_CURRENCY_ID
               , C_TARIFFICATION_MODE
               , C_TARIFF_TYPE
               , C_ROUND_TYPE
               , PAC_THIRD_ID
               , TRF_DESCR
               , TRF_ROUND_AMOUNT
               , TRF_UNIT
               , TRF_SQL_CONDITIONAL
               , TRF_STARTING_DATE
               , TRF_ENDING_DATE
               , PTC_FIXED_COSTPRICE_ID
               , PTC_CALC_COSTPRICE_ID
               , DIC_PUR_TARIFF_STRUCT_ID
               , DIC_SALE_TARIFF_STRUCT_ID
               , TRF_NET_TARIFF
               , TRF_SPECIAL_TARIFF
               , A_DATECRE
               , A_IDCRE
                )
      select aTargetTariffID   -- PTC_TARIFF_ID
           , GCO_GOOD_ID
           , DIC_TARIFF_ID
           , ACS_FINANCIAL_CURRENCY_ID
           , C_TARIFFICATION_MODE
           , C_TARIFF_TYPE
           , C_ROUND_TYPE
           , PAC_THIRD_ID
           , TRF_DESCR
           , TRF_ROUND_AMOUNT
           , TRF_UNIT
           , TRF_SQL_CONDITIONAL
           , trunc(aNewStartDate)
           , null
           , PTC_FIXED_COSTPRICE_ID
           , PTC_CALC_COSTPRICE_ID
           , DIC_PUR_TARIFF_STRUCT_ID
           , DIC_SALE_TARIFF_STRUCT_ID
           , TRF_NET_TARIFF
           , TRF_SPECIAL_TARIFF
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from PTC_TARIFF
       where PTC_TARIFF_ID = aSourceTariffId;

    -- Création des données de la table PTC_TARIFF_TABLE pour le nouveau tarif
    -- et multiplication du prix par le coefficient passé en paramètre
    insert into PTC_TARIFF_TABLE
                (PTC_TARIFF_TABLE_ID
               , PTC_TARIFF_ID
               , TTA_FROM_QUANTITY
               , TTA_TO_QUANTITY
               , TTA_PRICE
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   -- PTC_TARIFF_TABLE_ID
           , aTargetTariffID   -- PTC_TARIFF_ID
           , TTA_FROM_QUANTITY
           , TTA_TO_QUANTITY
           , TTA_PRICE * aMultiplicationCoef
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from PTC_TARIFF_TABLE
       where PTC_TARIFF_ID = aSourceTariffId;
  end DuplicateAndHistoryTariff;

  /**
  * fonction GetAccountingFixedCostprice
  * Description : Recherche du prix de revient fixe "comptabilité industrielle"
  * @author ECA
  * @version Date 10.07.2008
  * @param   aGCO_GOOD_ID : Produit.
  * @return  ID prix de revient fixe compta indus
  */
  function GetAccountingFixedCostprice(aGCO_GOOD_ID number)
    return number
  is
    cursor crManufactureAccounting
    is
      select   PTC_FIXED_COSTPRICE_ID
          from PTC_FIXED_COSTPRICE
         where GCO_GOOD_ID = aGCO_GOOD_ID
           and CPR_MANUFACTURE_ACCOUNTING = 1
           and CPR_DEFAULT = 1
           and C_COSTPRICE_STATUS = 'ACT'
           and (   FCP_START_DATE is null
                or trunc(FCP_START_DATE) <= trunc(sysdate) )
           and (   FCP_END_DATE is null
                or trunc(FCP_END_DATE) >= trunc(sysdate) )
      order by PTC_FIXED_COSTPRICE_ID desc;

    vPTC_FIXED_COSTPRICE_ID number;
  begin
    vPTC_FIXED_COSTPRICE_ID  := null;

    for tplManufactureAccounting in crManufactureAccounting loop
      vPTC_FIXED_COSTPRICE_ID  := tplManufactureAccounting.PTC_FIXED_COSTPRICE_ID;
      exit;
    end loop;

    return vPTC_FIXED_COSTPRICE_ID;
  exception
    when no_data_found then
      return null;
  end GetAccountingFixedCostprice;
end PTC_FUNCTIONS;
