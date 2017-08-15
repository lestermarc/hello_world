--------------------------------------------------------
--  DDL for Package Body ACT_VAT_MANAGEMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_VAT_MANAGEMENT" 
is
  -------------------------

  function InsertMGMImput(aACS_FINANCIAL_CURRENCY_ID      in ACT_MGM_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type,
                          aACS_ACS_FINANCIAL_CURRENCY_ID  in ACT_MGM_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID%type,
                          aACS_PERIOD_ID                  in ACT_MGM_IMPUTATION.ACS_PERIOD_ID%type,
                          aACS_CPN_ACCOUNT_ID             in ACT_MGM_IMPUTATION.ACS_CPN_ACCOUNT_ID%type,
                          aACS_CDA_ACCOUNT_ID             in ACT_MGM_IMPUTATION.ACS_CDA_ACCOUNT_ID%type,
                          aACS_PF_ACCOUNT_ID              in ACT_MGM_IMPUTATION.ACS_PF_ACCOUNT_ID%type,
                          aACT_DOCUMENT_ID                in ACT_MGM_IMPUTATION.ACT_DOCUMENT_ID%type,
                          aACT_FINANCIAL_IMPUTATION_ID    in ACT_MGM_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type,
                          aIMM_TYPE                       in ACT_MGM_IMPUTATION.IMM_TYPE%type,
                          aIMM_GENRE                      in ACT_MGM_IMPUTATION.IMM_GENRE%type,
                          aIMM_PRIMARY                    in ACT_MGM_IMPUTATION.IMM_PRIMARY%type,
                          aIMM_DESCRIPTION                in ACT_MGM_IMPUTATION.IMM_DESCRIPTION%type,
                          aIMM_AMOUNT_LC_D                in ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_D%type,
                          aIMM_AMOUNT_LC_C                in ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_C%type,
                          aIMM_EXCHANGE_RATE              in ACT_MGM_IMPUTATION.IMM_EXCHANGE_RATE%type,
                          aIMM_BASE_PRICE                 in ACT_MGM_IMPUTATION.IMM_BASE_PRICE%type,
                          aIMM_AMOUNT_FC_D                in ACT_MGM_IMPUTATION.IMM_AMOUNT_FC_D%type,
                          aIMM_AMOUNT_FC_C                in ACT_MGM_IMPUTATION.IMM_AMOUNT_FC_C%type,
                          aIMM_VALUE_DATE                 in ACT_MGM_IMPUTATION.IMM_VALUE_DATE%type,
                          aIMM_TRANSACTION_DATE           in ACT_MGM_IMPUTATION.IMM_TRANSACTION_DATE%type,
                          aACS_QTY_UNIT_ID                in ACT_MGM_IMPUTATION.ACS_QTY_UNIT_ID%type,
                          aIMM_QUANTITY_D                 in ACT_MGM_IMPUTATION.IMM_QUANTITY_D%type,
                          aIMM_QUANTITY_C                 in ACT_MGM_IMPUTATION.IMM_QUANTITY_C%type,
                          aIMM_AMOUNT_EUR_D               in ACT_MGM_IMPUTATION.IMM_AMOUNT_EUR_D%type,
                          aIMM_AMOUNT_EUR_C               in ACT_MGM_IMPUTATION.IMM_AMOUNT_EUR_C%type) return ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type
  is
    id  ACT_MGM_IMPUTATION.ACT_MGM_IMPUTATION_ID%type;
  begin
    select init_id_seq.nextval into id from dual;

    insert into ACT_MGM_IMPUTATION
               (ACT_MGM_IMPUTATION_ID
              , ACS_FINANCIAL_CURRENCY_ID
              , ACS_ACS_FINANCIAL_CURRENCY_ID
              , ACS_PERIOD_ID
              , ACS_CPN_ACCOUNT_ID
              , ACS_CDA_ACCOUNT_ID
              , ACS_PF_ACCOUNT_ID
              , ACT_DOCUMENT_ID
              , ACT_FINANCIAL_IMPUTATION_ID
              , IMM_TYPE
              , IMM_GENRE
              , IMM_PRIMARY
              , IMM_DESCRIPTION
              , IMM_AMOUNT_LC_D
              , IMM_AMOUNT_LC_C
              , IMM_EXCHANGE_RATE
              , IMM_BASE_PRICE
              , IMM_AMOUNT_FC_D
              , IMM_AMOUNT_FC_C
              , IMM_VALUE_DATE
              , IMM_TRANSACTION_DATE
              , A_DATECRE
              , A_IDCRE
              , ACS_QTY_UNIT_ID
              , IMM_QUANTITY_D
              , IMM_QUANTITY_C
              , IMM_AMOUNT_EUR_D
              , IMM_AMOUNT_EUR_C
                )
        values (id
              , aACS_FINANCIAL_CURRENCY_ID
              , aACS_ACS_FINANCIAL_CURRENCY_ID
              , aACS_PERIOD_ID
              , aACS_CPN_ACCOUNT_ID
              , aACS_CDA_ACCOUNT_ID
              , aACS_PF_ACCOUNT_ID
              , aACT_DOCUMENT_ID
              , aACT_FINANCIAL_IMPUTATION_ID
              , aIMM_TYPE
              , aIMM_GENRE
              , aIMM_PRIMARY
              , aIMM_DESCRIPTION
              , aIMM_AMOUNT_LC_D
              , aIMM_AMOUNT_LC_C
              , aIMM_EXCHANGE_RATE
              , aIMM_BASE_PRICE
              , aIMM_AMOUNT_FC_D
              , aIMM_AMOUNT_FC_C
              , aIMM_VALUE_DATE
              , aIMM_TRANSACTION_DATE
              , sysdate
              , PCS.PC_I_LIB_SESSION.GetUserIni
              , aACS_QTY_UNIT_ID
              , aIMM_QUANTITY_D
              , aIMM_QUANTITY_C
              , aIMM_AMOUNT_EUR_D
              , aIMM_AMOUNT_EUR_C);

    return id;
  end InsertMGMImput;

  -------------------------

  function InsertMGMDist(aACT_MGM_IMPUTATION_ID  in  ACT_MGM_DISTRIBUTION.ACT_MGM_IMPUTATION_ID%type,
                          aACS_PJ_ACCOUNT_ID     in  ACT_MGM_DISTRIBUTION.ACS_PJ_ACCOUNT_ID%type,
                          aMGM_DESCRIPTION       in  ACT_MGM_DISTRIBUTION.MGM_DESCRIPTION%type,
                          aMGM_AMOUNT_LC_D       in  ACT_MGM_DISTRIBUTION.MGM_AMOUNT_LC_D%type,
                          aMGM_AMOUNT_FC_D       in  ACT_MGM_DISTRIBUTION.MGM_AMOUNT_FC_D%type,
                          aMGM_AMOUNT_LC_C       in  ACT_MGM_DISTRIBUTION.MGM_AMOUNT_LC_C%type,
                          aMGM_AMOUNT_FC_C       in  ACT_MGM_DISTRIBUTION.MGM_AMOUNT_FC_C%type,
                          aMGM_QUANTITY_D        in  ACT_MGM_DISTRIBUTION.MGM_QUANTITY_D%type,
                          aMGM_QUANTITY_C        in  ACT_MGM_DISTRIBUTION.MGM_QUANTITY_C%type,
                          aMGM_AMOUNT_EUR_D      in  ACT_MGM_DISTRIBUTION.MGM_AMOUNT_EUR_D%type,
                          aMGM_AMOUNT_EUR_C      in  ACT_MGM_DISTRIBUTION.MGM_AMOUNT_EUR_C%type) return ACT_MGM_DISTRIBUTION.ACT_MGM_DISTRIBUTION_ID%type
  is
    id  ACT_MGM_DISTRIBUTION.ACT_MGM_DISTRIBUTION_ID%type;
  begin
    select init_id_seq.nextval into id from dual;

    insert into ACT_MGM_DISTRIBUTION
               (ACT_MGM_DISTRIBUTION_ID
              , ACT_MGM_IMPUTATION_ID
              , ACS_PJ_ACCOUNT_ID
              , ACS_SUB_SET_ID
              , MGM_DESCRIPTION
              , MGM_AMOUNT_LC_D
              , MGM_AMOUNT_FC_D
              , MGM_AMOUNT_LC_C
              , MGM_AMOUNT_FC_C
              , A_DATECRE
              , A_IDCRE
              , MGM_QUANTITY_D
              , MGM_QUANTITY_C
              , MGM_AMOUNT_EUR_D
              , MGM_AMOUNT_EUR_C
                )
        values (id
              , aACT_MGM_IMPUTATION_ID
              , aACS_PJ_ACCOUNT_ID
              , ACS_FUNCTION.GetSubSetIdByAccount(aACS_PJ_ACCOUNT_ID)
              , aMGM_DESCRIPTION
              , aMGM_AMOUNT_LC_D
              , aMGM_AMOUNT_FC_D
              , aMGM_AMOUNT_LC_C
              , aMGM_AMOUNT_FC_C
              , sysdate
              , PCS.PC_I_LIB_SESSION.GetUserIni
              , aMGM_QUANTITY_D
              , aMGM_QUANTITY_C
              , aMGM_AMOUNT_EUR_D
              , aMGM_AMOUNT_EUR_C);

    return id;
  end InsertMGMDist;

  -------------------------

  function VatRound(aValue in number, aRoundType in varchar2 default '0', aRoundAmount in number default 0)
    return number
  is
  begin
    if    aRoundType = '0'
       or aRoundType is null then
      -- pas d'arrondi -> arrondi à 2 décimales
      return round(aValue, 2);
    else
      return ACS_FUNCTION.PcsRound(aValue, aRoundType, aRoundAmount);
    end if;
  end VatRound;

-------------------------
  function GetInfoVAT(aBaseInfo in BaseInfoRecType, aInfoVAT in out InfoVATRecType)
    return boolean
  is
  begin
    begin
      select ACS_TAX_CODE1_ID
           , ACS_TAX_CODE2_ID
           , nvl(ACC_INTEREST, 0)
           , ACS_PREA_ACCOUNT_ID
           , ACS_PROV_ACCOUNT_ID
           , C_ESTABLISHING_CALC_SHEET
           , nvl(VAT_RATE, TAX_RATE)
           , TAX_LIABLED_RATE
           , C_ROUND_TYPE
           , TAX_ROUNDED_AMOUNT
           , ACS_FINANCIAL_CURRENCY_ID
           , ACS_ACCOUNT.ACS_SUB_SET_ID
           , nvl(TAX_DEDUCTIBLE_RATE, 100)
           , ACS_NONDED_ACCOUNT_ID
        into aInfoVAT
        from ACS_VAT_RATE
           , ACS_VAT_DET_ACCOUNT
           , ACS_ACCOUNT
           , ACS_TAX_CODE
       where ACS_TAX_CODE.ACS_TAX_CODE_ID = aBaseInfo.TaxCodeId
         and ACS_TAX_CODE.ACS_TAX_CODE_ID = ACS_ACCOUNT.ACS_ACCOUNT_ID
         and ACS_TAX_CODE.ACS_VAT_DET_ACCOUNT_ID = ACS_VAT_DET_ACCOUNT.ACS_VAT_DET_ACCOUNT_ID
         and ACS_TAX_CODE.ACS_TAX_CODE_ID = ACS_VAT_RATE.ACS_TAX_CODE_ID(+)
         and nvl(aBaseInfo.DeliveryDate, aBaseInfo.ValueDate) between VAT_SINCE(+) and VAT_TO(+);
    exception
      when no_data_found then
        return false;
    end;

    return true;
  end GetInfoVAT;

-------------------------
  function CalcVAT(aBaseInfo in BaseInfoRecType, aInfoVAT in InfoVATRecType, aCalcVAT in out CalcVATRecType)
    return boolean
  is
    ExchangeRate       ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type;
    BasePrice          ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type;
    BaseChange         number(1);
    FixedRateEUR_MB    number(1);
    FixedRateEUR_ME    number(1);
    RateExchangeEUR_MB ACS_FINANCIAL_CURRENCY.FIN_EURO_RATE%type;
    RateExchangeEUR_ME ACS_FINANCIAL_CURRENCY.FIN_EURO_RATE%type;
    Flag               number(1);
    InputAmountsIE     ACT_DET_TAX.TAX_INCLUDED_EXCLUDED%type;
  begin
    aCalcVAT.FinCurrId_LC   := aBaseInfo.FinCurrId_LC;
    aCalcVAT.FinCurrId_FC   := aBaseInfo.FinCurrId_FC;
    InputAmountsIE          := aBaseInfo.AmountsIE;

    if aInfoVAT.Interest = 1 then
      aCalcVAT.IE  := 'I';
    elsif    (aInfoVAT.PreliminaryAccId is not null)
          or (aInfoVAT.CollectedAccId is not null) then
      aCalcVAT.IE     := 'S';
      InputAmountsIE  := null;   --Force saisie standard
    else
      aCalcVAT.IE  := aBaseInfo.IE;
    end if;

    aCalcVAT.Reduction      := 0;

    if aBaseInfo.AmountD_LC != 0 then
      aCalcVAT.LiabledAmount      := CalcLiabledAmount(aBaseInfo.AmountD_LC, aInfoVAT, aCalcVAT.IE, InputAmountsIE);
      aCalcVAT.LiabledAmount_FC   := CalcLiabledAmount(aBaseInfo.AmountD_FC, aInfoVAT, aCalcVAT.IE, InputAmountsIE);
      aCalcVAT.LiabledAmount_EUR  := CalcLiabledAmount(aBaseInfo.AmountD_EUR, aInfoVAT, aCalcVAT.IE, InputAmountsIE);
    else
      aCalcVAT.LiabledAmount      := CalcLiabledAmount(aBaseInfo.AmountC_LC * -1, aInfoVAT, aCalcVAT.IE
                                                     , InputAmountsIE);
      aCalcVAT.LiabledAmount_FC   := CalcLiabledAmount(aBaseInfo.AmountC_FC * -1, aInfoVAT, aCalcVAT.IE
                                                     , InputAmountsIE);
      aCalcVAT.LiabledAmount_EUR  :=
                                    CalcLiabledAmount(aBaseInfo.AmountC_EUR * -1, aInfoVAT, aCalcVAT.IE
                                                    , InputAmountsIE);
    end if;

    --Calcule du montant tot TVA sans arrondi
    aCalcVAT.TotAmount_LC   := CalcVAT(aCalcVAT.LiabledAmount, aInfoVAT.Rate, aCalcVAT.IE, null, null);
    aCalcVAT.TotAmount_FC   := CalcVAT(aCalcVAT.LiabledAmount_FC, aInfoVAT.Rate, aCalcVAT.IE, null, null);
    aCalcVAT.TotAmount_BC   := aCalcVAT.TotAmount_FC;
    aCalcVAT.TotAmount_EUR  := CalcVAT(aCalcVAT.LiabledAmount_EUR, aInfoVAT.Rate, aCalcVAT.IE, null, null);

    --Si taux deductible <> 100, calcule du montant TVA
    if aInfoVAT.DeductibleRate != 100 then
      if aInfoVAT.DeductibleRate <= 0 then
        aCalcVAT.Amount_LC   := 0;
        aCalcVAT.Amount_FC   := 0;
        aCalcVAT.Amount_BC   := 0;
        aCalcVAT.Amount_EUR  := 0;
      else
        aCalcVAT.Amount_LC   :=
            VatRound(aCalcVAT.TotAmount_LC * aInfoVAT.DeductibleRate / 100, aInfoVAT.RoundType, aInfoVAT.RoundedAmount);
        aCalcVAT.Amount_FC   :=
            VatRound(aCalcVAT.TotAmount_FC * aInfoVAT.DeductibleRate / 100, aInfoVAT.RoundType, aInfoVAT.RoundedAmount);
        aCalcVAT.Amount_BC   := aCalcVAT.Amount_FC;
        aCalcVAT.Amount_EUR  :=
           VatRound(aCalcVAT.TotAmount_EUR * aInfoVAT.DeductibleRate / 100, aInfoVAT.RoundType, aInfoVAT.RoundedAmount);
      end if;
    end if;

    --Arrondi des montants tot. TVA
    aCalcVAT.TotAmount_LC   := VatRound(aCalcVAT.TotAmount_LC, aInfoVAT.RoundType, aInfoVAT.RoundedAmount);
    aCalcVAT.TotAmount_FC   := VatRound(aCalcVAT.TotAmount_FC, aInfoVAT.RoundType, aInfoVAT.RoundedAmount);
    aCalcVAT.TotAmount_BC   := aCalcVAT.TotAmount_FC;
    aCalcVAT.TotAmount_EUR  := VatRound(aCalcVAT.TotAmount_EUR, aInfoVAT.RoundType, aInfoVAT.RoundedAmount);

    --Si taux deductible = 100, reprise du montant tot. TVA comme montant TVA
    if aInfoVAT.DeductibleRate = 100 then
      aCalcVAT.Amount_LC   := aCalcVAT.TotAmount_LC;
      aCalcVAT.Amount_FC   := aCalcVAT.TotAmount_FC;
      aCalcVAT.Amount_BC   := aCalcVAT.TotAmount_BC;
      aCalcVAT.Amount_EUR  := aCalcVAT.TotAmount_EUR;
    end if;

/*
    if (aCalcVAT.IE != 'I') or (aInfoVAT.Rate = 100) then
      aCalcVAT.Amount_LC := aCalcVAT.LiabledAmount * aInfoVAT.Rate / 100;
    else
      aCalcVAT.Amount_LC := aCalcVAT.LiabledAmount * aInfoVAT.Rate / (100 + aInfoVAT.Rate);
    end if;

    if aInfoVAT.RoundType = 1 then
      aCalcVAT.Amount_LC := ACS_FUNCTION.RoundNear(aCalcVAT.Amount_LC, 0.05, 0);
    elsif aInfoVAT.RoundType = 2 then
      aCalcVAT.Amount_LC := ACS_FUNCTION.RoundNear(aCalcVAT.Amount_LC, aInfoVAT.RoundedAmount, -1);
    elsif aInfoVAT.RoundType = 3 then
      aCalcVAT.Amount_LC := ACS_FUNCTION.RoundNear(aCalcVAT.Amount_LC, aInfoVAT.RoundedAmount, 0);
    elsif aInfoVAT.RoundType = 4 then
      aCalcVAT.Amount_LC := ACS_FUNCTION.RoundNear(aCalcVAT.Amount_LC, aInfoVAT.RoundedAmount, 1);
    else
      aCalcVAT.Amount_LC := Round(aCalcVAT.Amount_LC, 2);
    end if;
 */
    --Flag indiquant si la monnaie du décompte est utilisée.
    --Donc si c'est le cas, Amount_FC <> Amount_BC
    aCalcVAT.UseVatDetAccountCurrency := not (aBaseInfo.FinCurrId_LC = aInfoVAT.VatDetCurrId or aBaseInfo.FinCurrId_FC = aInfoVAT.VatDetCurrId);
    if    not aCalcVAT.UseVatDetAccountCurrency then
      if aBaseInfo.FinCurrId_LC != aBaseInfo.FinCurrId_FC then
        if    (not aBaseInfo.FixedVATAmounts)
           or (aBaseInfo.FixedVATAmounts is null) then
          -- Si cours de change TVA déjà initialisé (paiement), on ne le récupère pas
          if    nvl(aCalcVAT.ExchangeRate, 0) = 0
             or nvl(aCalcVAT.BasePrice, 0) = 0 then
            Flag  :=
              ACS_FUNCTION.GetRateOfExchangeEUR(aCalcVAT.FinCurrId_FC
                                              , 6
                                              , nvl(aBaseInfo.DeliveryDate, aBaseInfo.ValueDate)
                                              , ExchangeRate
                                              , BasePrice
                                              , BaseChange
                                              , RateExchangeEUR_ME
                                              , FixedRateEUR_ME
                                              , RateExchangeEUR_MB
                                              , FixedRateEUR_MB
                                               );

            if    (FixedRateEUR_ME != 1)
               or (FixedRateEUR_MB != 1) then
              -- Si le cours est en monnaie étrangère, alors il faut le convertir en monnaie base }
              if BaseChange = 1 then
                aCalcVAT.ExchangeRate  := ExchangeRate;
              else
                aCalcVAT.ExchangeRate  :=( (BasePrice * BasePrice) / ExchangeRate);
              end if;

              aCalcVAT.BasePrice  := BasePrice;
            else
              aCalcVAT.ExchangeRate  := 0;
              aCalcVAT.BasePrice     := 0;
            end if;
          end if;

          ACS_FUNCTION.ConvertAmount(aCalcVAT.Amount_FC
                                   , aCalcVAT.FinCurrId_FC
                                   , aCalcVAT.FinCurrId_LC
                                   , nvl(aBaseInfo.DeliveryDate, aBaseInfo.ValueDate)
                                   , aCalcVAT.ExchangeRate
                                   , aCalcVAT.BasePrice
                                   , 1
                                   , aCalcVAT.Amount_EUR
                                   , aCalcVAT.Amount_LC
                                   , 6
                                    );

          if     aBaseInfo.AmountD_EUR = 0
             and aBaseInfo.AmountC_EUR = 0 then
            aCalcVAT.Amount_EUR  := 0;
          end if;

          ACS_FUNCTION.ConvertAmount(aCalcVAT.TotAmount_FC
                                   , aCalcVAT.FinCurrId_FC
                                   , aCalcVAT.FinCurrId_LC
                                   , nvl(aBaseInfo.DeliveryDate, aBaseInfo.ValueDate)
                                   , aCalcVAT.ExchangeRate
                                   , aCalcVAT.BasePrice
                                   , 1
                                   , aCalcVAT.TotAmount_EUR
                                   , aCalcVAT.TotAmount_LC
                                   , 6
                                    );

          if     aBaseInfo.AmountD_EUR = 0
             and aBaseInfo.AmountC_EUR = 0 then
            aCalcVAT.TotAmount_EUR  := 0;
          end if;

          --Recalcule du montant soumis
          if aBaseInfo.AmountD_LC != 0 then
            aCalcVAT.LiabledAmount  := CalcLiabledAmount(aBaseInfo.AmountD_LC, aInfoVAT, aCalcVAT.IE, InputAmountsIE);
          else
            aCalcVAT.LiabledAmount  :=
                                     CalcLiabledAmount(aBaseInfo.AmountC_LC * -1, aInfoVAT, aCalcVAT.IE
                                                     , InputAmountsIE);
          end if;
        else
          aCalcVAT.ExchangeRate  := aBaseInfo.ExchangeRate;
          aCalcVAT.BasePrice     := aBaseInfo.BasePrice;
        end if;
      else
        aCalcVAT.Amount_EUR     := 0;
        aCalcVAT.Amount_FC      := 0;
        aCalcVAT.Amount_BC      := 0;
        aCalcVAT.TotAmount_EUR  := 0;
        aCalcVAT.TotAmount_FC   := 0;
        aCalcVAT.TotAmount_BC   := 0;
      end if;
    else
      --remplacement de la monnaie étrangère par la monnaie TVA et recalcule des montants
      if aBaseInfo.FinCurrId_LC != aInfoVAT.VatDetCurrId then
        aCalcVAT.FinCurrId_FC  := aInfoVAT.VatDetCurrId;
      end if;

      ACS_FUNCTION.ConvertAmount(aCalcVAT.Amount_LC
                               , aCalcVAT.FinCurrId_LC
                               , aCalcVAT.FinCurrId_FC
                               , nvl(aBaseInfo.DeliveryDate, aBaseInfo.ValueDate)
                               , 0
                               , 0
                               , 1
                               , aCalcVAT.Amount_EUR
                               , aCalcVAT.Amount_FC
                               , 6
                                );

      if     aBaseInfo.AmountD_EUR = 0
         and aBaseInfo.AmountC_EUR = 0 then
        aCalcVAT.Amount_EUR  := 0;
      end if;

      ACS_FUNCTION.ConvertAmount(aCalcVAT.TotAmount_LC
                               , aCalcVAT.FinCurrId_LC
                               , aCalcVAT.FinCurrId_FC
                               , nvl(aBaseInfo.DeliveryDate, aBaseInfo.ValueDate)
                               , 0
                               , 0
                               , 1
                               , aCalcVAT.TotAmount_EUR
                               , aCalcVAT.TotAmount_FC
                               , 6
                                );

      if     aBaseInfo.AmountD_EUR = 0
         and aBaseInfo.AmountC_EUR = 0 then
        aCalcVAT.TotAmount_EUR  := 0;
      end if;

      Flag  :=
        ACS_FUNCTION.GetRateOfExchangeEUR(aCalcVAT.FinCurrId_FC
                                        , 6
                                        , nvl(aBaseInfo.DeliveryDate, aBaseInfo.ValueDate)
                                        , ExchangeRate
                                        , BasePrice
                                        , BaseChange
                                        , RateExchangeEUR_ME
                                        , FixedRateEUR_ME
                                        , RateExchangeEUR_MB
                                        , FixedRateEUR_MB
                                         );

      if    (FixedRateEUR_ME != 1)
         or (FixedRateEUR_MB != 1) then
        -- Si le cours est en monnaie étrangère, alors il faut le convertir en monnaie base }
        if BaseChange = 1 then
          aCalcVAT.ExchangeRate  := ExchangeRate;
        else
          aCalcVAT.ExchangeRate  :=( (BasePrice * BasePrice) / ExchangeRate);
        end if;

        aCalcVAT.BasePrice  := BasePrice;
      else
        aCalcVAT.ExchangeRate  := 0;
        aCalcVAT.BasePrice     := 0;
      end if;
    end if;

    if     (aInfoVAT.EtabCalcSheet = '2')
       and (aBaseInfo.TypeCatalogue in('2', '5', '6') )
       and (upper(PCS.PC_CONFIG.GetConfig('ACT_TAX_VAT_ENCASHMENT') ) = 'TRUE') then
      aCalcVAT.Encashment  := 1;
    else
      aCalcVAT.Encashment  := 0;
    end if;

    return true;
  end CalcVAT;

  /**
  * Description
  *    Calcul de la TVA
  **/
  function CalcVAT(liabled_amount number, rate number, IE varchar2, RoundType number, RoundedAmount number)
    return number
  is
    divisor   ACS_VAT_RATE.VAT_RATE%type;
    VatAmount ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type;
  begin
    if rate = 100 then   -- tva pure
      divisor  := 0;
    else
      divisor  := rate;
    end if;

    if IE != 'I' then
      VatAmount  := liabled_amount * rate / 100;
    else
      VatAmount  := liabled_amount * rate /(100 + divisor);
    end if;

    if RoundType is not null then
      VatAmount  := VatRound(VatAmount, RoundType, RoundedAmount);
    end if;

    return VatAmount;
  end CalcVAT;

  /**
  * Description
  *    Calcul de la TVA
  **/
  function CalcVAT(liabled_amount number, rate number, IE varchar2, Taxe_Code_id number)
    return number
  is
    RoundType     ACS_TAX_CODE.C_ROUND_TYPE%type;
    RoundedAmount ACS_TAX_CODE.TAX_ROUNDED_AMOUNT%type;
  begin
    select C_ROUND_TYPE
         , TAX_ROUNDED_AMOUNT
      into RoundType
         , RoundedAmount
      from ACS_TAX_CODE
     where ACS_TAX_CODE_ID = Taxe_Code_id;

    return CalcVAT(liabled_amount, rate, IE, RoundType, RoundedAmount);
  end CalcVAT;

-------------------------
  function InsertImput(
    aACS_ACS_FINANCIAL_CURRENCY_ID in ACT_FINANCIAL_IMPUTATION.ACS_ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_FINANCIAL_ACCOUNT_ID      in ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID%type
  , aACS_FINANCIAL_CURRENCY_ID     in ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_PERIOD_ID                 in ACT_FINANCIAL_IMPUTATION.ACS_PERIOD_ID%type
  , aACS_TAX_CODE_ID               in ACT_FINANCIAL_IMPUTATION.ACS_TAX_CODE_ID%type
  , aACT_DOCUMENT_ID               in ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID%type
  , aACT_FINANCIAL_IMPUTATION_ID   in ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type
  , aACT_PART_IMPUTATION_ID        in ACT_FINANCIAL_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , aC_GENRE_TRANSACTION           in ACT_FINANCIAL_IMPUTATION.C_GENRE_TRANSACTION%type
  , aIMF_AMOUNT_EUR_C              in ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_C%type
  , aIMF_AMOUNT_EUR_D              in ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type
  , aIMF_AMOUNT_FC_C               in ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_C%type
  , aIMF_AMOUNT_FC_D               in ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
  , aIMF_AMOUNT_LC_C               in ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_C%type
  , aIMF_AMOUNT_LC_D               in ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
  , aIMF_BASE_PRICE                in ACT_FINANCIAL_IMPUTATION.IMF_BASE_PRICE%type
  , aIMF_DESCRIPTION               in ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
  , aIMF_EXCHANGE_RATE             in ACT_FINANCIAL_IMPUTATION.IMF_EXCHANGE_RATE%type
  , aIMF_GENRE                     in ACT_FINANCIAL_IMPUTATION.IMF_GENRE%type
  , aIMF_PRIMARY                   in ACT_FINANCIAL_IMPUTATION.IMF_PRIMARY%type
  , aIMF_TRANSACTION_DATE          in ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aIMF_TYPE                      in ACT_FINANCIAL_IMPUTATION.IMF_TYPE%type
  , aIMF_VALUE_DATE                in ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , aACT_DET_PAYMENT_ID            in ACT_FINANCIAL_IMPUTATION.ACT_DET_PAYMENT_ID%type
  , aACS_DIVISION_ACCOUNT_ID       in ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type default null
  )
    return boolean
  is
    DistributionId ACT_FINANCIAL_DISTRIBUTION.ACT_FINANCIAL_DISTRIBUTION_ID%type;
    DivAccId       ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type;
  begin
    insert into ACT_FINANCIAL_IMPUTATION
                (A_DATECRE
               , A_IDCRE
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_PERIOD_ID
               , ACS_TAX_CODE_ID
               , ACT_DET_PAYMENT_ID
               , ACT_DOCUMENT_ID
               , ACT_FINANCIAL_IMPUTATION_ID
               , ACT_PART_IMPUTATION_ID
               , C_GENRE_TRANSACTION
               , IMF_AMOUNT_EUR_C
               , IMF_AMOUNT_EUR_D
               , IMF_AMOUNT_FC_C
               , IMF_AMOUNT_FC_D
               , IMF_AMOUNT_LC_C
               , IMF_AMOUNT_LC_D
               , IMF_BASE_PRICE
               , IMF_DESCRIPTION
               , IMF_EXCHANGE_RATE
               , IMF_GENRE
               , IMF_PRIMARY
               , IMF_TRANSACTION_DATE
               , IMF_TYPE
               , IMF_VALUE_DATE
                )
         values (sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , aACS_ACS_FINANCIAL_CURRENCY_ID
               , aACS_FINANCIAL_ACCOUNT_ID
               , aACS_FINANCIAL_CURRENCY_ID
               , aACS_PERIOD_ID
               , aACS_TAX_CODE_ID
               , aACT_DET_PAYMENT_ID
               , aACT_DOCUMENT_ID
               , aACT_FINANCIAL_IMPUTATION_ID
               , aACT_PART_IMPUTATION_ID
               , aC_GENRE_TRANSACTION
               , aIMF_AMOUNT_EUR_C
               , aIMF_AMOUNT_EUR_D
               , aIMF_AMOUNT_FC_C
               , aIMF_AMOUNT_FC_D
               , aIMF_AMOUNT_LC_C
               , aIMF_AMOUNT_LC_D
               , aIMF_BASE_PRICE
               , aIMF_DESCRIPTION
               , aIMF_EXCHANGE_RATE
               , aIMF_GENRE
               , aIMF_PRIMARY
               , aIMF_TRANSACTION_DATE
               , aIMF_TYPE
               , aIMF_VALUE_DATE
                );

    if ACS_FUNCTION.ExistDIVI = 1 then
      select init_id_seq.nextval
        into DistributionId
        from dual;

      DivAccId  :=
        ACS_FUNCTION.GetDivisionOfAccount(aACS_FINANCIAL_ACCOUNT_ID
                                        , aACS_DIVISION_ACCOUNT_ID
                                        , aIMF_VALUE_DATE
                                        , PCS.PC_I_LIB_SESSION.GETUSERID
                                        , 1
                                         );

      insert into ACT_FINANCIAL_DISTRIBUTION
                  (A_DATECRE
                 , A_IDCRE
                 , ACS_DIVISION_ACCOUNT_ID
                 , ACS_SUB_SET_ID
                 , ACT_FINANCIAL_DISTRIBUTION_ID
                 , ACT_FINANCIAL_IMPUTATION_ID
                 , FIN_AMOUNT_EUR_C
                 , FIN_AMOUNT_EUR_D
                 , FIN_AMOUNT_FC_C
                 , FIN_AMOUNT_FC_D
                 , FIN_AMOUNT_LC_C
                 , FIN_AMOUNT_LC_D
                 , FIN_DESCRIPTION
                  )
           values (sysdate
                 , PCS.PC_I_LIB_SESSION.GETUSERINI
                 , DivAccId
                 , ACS_FUNCTION.GetSubSetIdByAccount(DivAccId)
                 , DistributionId
                 , aACT_FINANCIAL_IMPUTATION_ID
                 , aIMF_AMOUNT_EUR_C
                 , aIMF_AMOUNT_EUR_D
                 , aIMF_AMOUNT_FC_C
                 , aIMF_AMOUNT_FC_D
                 , aIMF_AMOUNT_LC_C
                 , aIMF_AMOUNT_LC_D
                 , aIMF_DESCRIPTION
                  );
    end if;

    return true;
  end InsertImput;

-------------------------
  function InsertDetTax(
    aACS_ACCOUNT_ID2               in ACT_DET_TAX.ACS_ACCOUNT_ID2%type
  , aACS_SUB_SET_ID                in ACT_DET_TAX.ACS_SUB_SET_ID%type
  , aACT_ACT_FINANCIAL_IMPUTATION  in ACT_DET_TAX.ACT_ACT_FINANCIAL_IMPUTATION%type
  , aACT_DET_TAX_ID                in ACT_DET_TAX.ACT_DET_TAX_ID%type
  , aACT_FINANCIAL_IMPUTATION_ID   in ACT_DET_TAX.ACT_FINANCIAL_IMPUTATION_ID%type
  , aACT2_ACT_FINANCIAL_IMPUTATION in ACT_DET_TAX.ACT2_ACT_FINANCIAL_IMPUTATION%type
  , aACT2_DET_TAX_ID               in ACT_DET_TAX.ACT2_DET_TAX_ID%type
  , aDET_BASE_PRICE                in ACT_DET_TAX.DET_BASE_PRICE%type
  , aTAX_EXCHANGE_RATE             in ACT_DET_TAX.TAX_EXCHANGE_RATE%type
  , aTAX_INCLUDED_EXCLUDED         in ACT_DET_TAX.TAX_INCLUDED_EXCLUDED%type
  , aTAX_LIABLED_AMOUNT            in ACT_DET_TAX.TAX_LIABLED_AMOUNT%type
  , aTAX_LIABLED_RATE              in ACT_DET_TAX.TAX_LIABLED_RATE%type
  , aTAX_RATE                      in ACT_DET_TAX.TAX_RATE%type
  , aTAX_REDUCTION                 in ACT_DET_TAX.TAX_REDUCTION%type
  , aTAX_VAT_AMOUNT_EUR            in ACT_DET_TAX.TAX_VAT_AMOUNT_EUR%type
  , aTAX_VAT_AMOUNT_FC             in ACT_DET_TAX.TAX_VAT_AMOUNT_FC%type
  , aTAX_VAT_AMOUNT_LC             in ACT_DET_TAX.TAX_VAT_AMOUNT_LC%type
  , aTAX_TOT_VAT_AMOUNT_EUR        in ACT_DET_TAX.TAX_TOT_VAT_AMOUNT_EUR%type
  , aTAX_TOT_VAT_AMOUNT_FC         in ACT_DET_TAX.TAX_TOT_VAT_AMOUNT_FC%type
  , aTAX_TOT_VAT_AMOUNT_LC         in ACT_DET_TAX.TAX_TOT_VAT_AMOUNT_LC%type
  , aTAX_DEDUCTIBLE_RATE           in ACT_DET_TAX.TAX_DEDUCTIBLE_RATE%type
  , aACT_DED1_FINANCIAL_IMP_ID     in ACT_DET_TAX.ACT_DED1_FINANCIAL_IMP_ID%type
  , aACT_DED2_FINANCIAL_IMP_ID     in ACT_DET_TAX.ACT_DED2_FINANCIAL_IMP_ID%type
  , aTAX_TMP_VAT_ENCASHMENT        in ACT_DET_TAX.TAX_TMP_VAT_ENCASHMENT%type
  , aACT_ENCASHMENT_DET_PAY_ID     in ACT_DET_TAX.ACT_ENCASHMENT_DET_PAY_ID%type
  )
    return boolean
  is
  begin
    insert into ACT_DET_TAX
                (A_DATECRE
               , A_IDCRE
               , ACS_ACCOUNT_ID2
               , ACS_SUB_SET_ID
               , ACT_ACT_FINANCIAL_IMPUTATION
               , ACT_DET_TAX_ID
               , ACT_FINANCIAL_IMPUTATION_ID
               , ACT2_ACT_FINANCIAL_IMPUTATION
               , ACT2_DET_TAX_ID
               , DET_BASE_PRICE
               , TAX_EXCHANGE_RATE
               , TAX_INCLUDED_EXCLUDED
               , TAX_LIABLED_AMOUNT
               , TAX_LIABLED_RATE
               , TAX_RATE
               , TAX_REDUCTION
               , TAX_VAT_AMOUNT_EUR
               , TAX_VAT_AMOUNT_FC
               , TAX_VAT_AMOUNT_LC
               , TAX_TOT_VAT_AMOUNT_EUR
               , TAX_TOT_VAT_AMOUNT_FC
               , TAX_TOT_VAT_AMOUNT_LC
               , TAX_DEDUCTIBLE_RATE
               , ACT_DED1_FINANCIAL_IMP_ID
               , ACT_DED2_FINANCIAL_IMP_ID
               , TAX_TMP_VAT_ENCASHMENT
               , ACT_ENCASHMENT_DET_PAY_ID
                )
         values (sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , aACS_ACCOUNT_ID2
               , aACS_SUB_SET_ID
               , aACT_ACT_FINANCIAL_IMPUTATION
               , aACT_DET_TAX_ID
               , aACT_FINANCIAL_IMPUTATION_ID
               , aACT2_ACT_FINANCIAL_IMPUTATION
               , aACT2_DET_TAX_ID
               , aDET_BASE_PRICE
               , aTAX_EXCHANGE_RATE
               , aTAX_INCLUDED_EXCLUDED
               , aTAX_LIABLED_AMOUNT
               , aTAX_LIABLED_RATE
               , aTAX_RATE
               , aTAX_REDUCTION
               , aTAX_VAT_AMOUNT_EUR
               , aTAX_VAT_AMOUNT_FC
               , aTAX_VAT_AMOUNT_LC
               , aTAX_TOT_VAT_AMOUNT_EUR
               , aTAX_TOT_VAT_AMOUNT_FC
               , aTAX_TOT_VAT_AMOUNT_LC
               , aTAX_DEDUCTIBLE_RATE
               , aACT_DED1_FINANCIAL_IMP_ID
               , aACT_DED2_FINANCIAL_IMP_ID
               , aTAX_TMP_VAT_ENCASHMENT
               , aACT_ENCASHMENT_DET_PAY_ID
                );

    return true;
  end InsertDetTax;

  -------------------------

  procedure CreateVATSecMAN(aACT_FINANCIAL_IMPUTATION_ID  in ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type,
                            aVATMGMImputInfo              in ACT_MGM_IMPUTATION%rowtype,
                            aBaseInfo                     in BaseInfoRecType)
  is
    tblProportionMANImput  ACT_MGM_MANAGEMENT.tblProportionMANImputType;
    tblProportionMANDist   ACT_MGM_MANAGEMENT.tblProportionMANDistType;
    MGMImput               ACT_MGM_IMPUTATION%rowtype;
    MGMDist                ACT_MGM_DISTRIBUTION%rowtype;
    TotAmountImpLC         ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_D%type  := 0;
    TotAmountImpFC         ACT_MGM_IMPUTATION.IMM_AMOUNT_FC_D%type  := 0;
    TotAmountImpEUR        ACT_MGM_IMPUTATION.IMM_AMOUNT_EUR_D%type := 0;
    TotAmountDistLC        ACT_MGM_DISTRIBUTION.MGM_AMOUNT_LC_D%type;
    TotAmountDistFC        ACT_MGM_DISTRIBUTION.MGM_AMOUNT_FC_D%type;
    TotAmountDistEUR       ACT_MGM_DISTRIBUTION.MGM_AMOUNT_EUR_D%type;
    Pos                    integer;
    Pos2                   integer;
  begin
    if ACT_MGM_MANAGEMENT.CalcProportionMANImputation(aBaseInfo.FinImputId, tblProportionMANImput) then

      for Pos in 1..tblProportionMANImput.Count loop
        MGMImput := null;

        MGMImput.IMM_AMOUNT_FC_C  := 0;
        MGMImput.IMM_AMOUNT_FC_D  := 0;
        MGMImput.IMM_AMOUNT_EUR_C := 0;
        MGMImput.IMM_AMOUNT_EUR_D := 0;

        if Pos = tblProportionMANImput.Count then
          if (aVATMGMImputInfo.IMM_AMOUNT_LC_D - aVATMGMImputInfo.IMM_AMOUNT_LC_C) - TotAmountImpLC > 0 then
            MGMImput.IMM_AMOUNT_LC_D  := aVATMGMImputInfo.IMM_AMOUNT_LC_D - TotAmountImpLC;
            MGMImput.IMM_AMOUNT_LC_C  := 0;
            if aVATMGMImputInfo.ACS_FINANCIAL_CURRENCY_ID != aVATMGMImputInfo.ACS_ACS_FINANCIAL_CURRENCY_ID then
              MGMImput.IMM_AMOUNT_FC_D  := aVATMGMImputInfo.IMM_AMOUNT_FC_D - TotAmountImpFC;
              MGMImput.IMM_AMOUNT_EUR_D := aVATMGMImputInfo.IMM_AMOUNT_EUR_D - TotAmountImpEUR;
              MGMImput.IMM_AMOUNT_FC_C  := 0;
              MGMImput.IMM_AMOUNT_EUR_C := 0;
            end if;
          else
            MGMImput.IMM_AMOUNT_LC_C  := aVATMGMImputInfo.IMM_AMOUNT_LC_C + TotAmountImpLC;
            MGMImput.IMM_AMOUNT_LC_D  := 0;
            if aVATMGMImputInfo.ACS_FINANCIAL_CURRENCY_ID != aVATMGMImputInfo.ACS_ACS_FINANCIAL_CURRENCY_ID then
              MGMImput.IMM_AMOUNT_FC_C  := aVATMGMImputInfo.IMM_AMOUNT_FC_C + TotAmountImpFC;
              MGMImput.IMM_AMOUNT_EUR_C := aVATMGMImputInfo.IMM_AMOUNT_EUR_C + TotAmountImpEUR;
              MGMImput.IMM_AMOUNT_FC_D  := 0;
              MGMImput.IMM_AMOUNT_EUR_D := 0;
            end if;
          end if;
        else
          MGMImput.IMM_AMOUNT_LC_D := ACS_FUNCTION.RoundAmount(aVATMGMImputInfo.IMM_AMOUNT_LC_D * tblProportionMANImput(Pos).RATIO, aVATMGMImputInfo.ACS_ACS_FINANCIAL_CURRENCY_ID);
          MGMImput.IMM_AMOUNT_LC_C := ACS_FUNCTION.RoundAmount(aVATMGMImputInfo.IMM_AMOUNT_LC_C * tblProportionMANImput(Pos).RATIO, aVATMGMImputInfo.ACS_ACS_FINANCIAL_CURRENCY_ID);
          if aVATMGMImputInfo.ACS_FINANCIAL_CURRENCY_ID != aVATMGMImputInfo.ACS_ACS_FINANCIAL_CURRENCY_ID then
            MGMImput.IMM_AMOUNT_FC_D := ACS_FUNCTION.RoundAmount(aVATMGMImputInfo.IMM_AMOUNT_FC_D * tblProportionMANImput(Pos).RATIO, aVATMGMImputInfo.ACS_FINANCIAL_CURRENCY_ID);
            MGMImput.IMM_AMOUNT_FC_C := ACS_FUNCTION.RoundAmount(aVATMGMImputInfo.IMM_AMOUNT_FC_C * tblProportionMANImput(Pos).RATIO, aVATMGMImputInfo.ACS_FINANCIAL_CURRENCY_ID);
            MGMImput.IMM_AMOUNT_EUR_D := ACS_FUNCTION.RoundNear(aVATMGMImputInfo.IMM_AMOUNT_EUR_D * tblProportionMANImput(Pos).RATIO, ACS_FUNCTION.CONST_RoundAmountEUR, ACS_FUNCTION.CONST_RoundTypeEUR);
            MGMImput.IMM_AMOUNT_EUR_C := ACS_FUNCTION.RoundNear(aVATMGMImputInfo.IMM_AMOUNT_EUR_C * tblProportionMANImput(Pos).RATIO, ACS_FUNCTION.CONST_RoundAmountEUR, ACS_FUNCTION.CONST_RoundTypeEUR);
          end if;

          TotAmountImpLC := TotAmountImpLC + MGMImput.IMM_AMOUNT_LC_D - MGMImput.IMM_AMOUNT_LC_C;
          TotAmountImpFC := TotAmountImpFC + MGMImput.IMM_AMOUNT_FC_D - MGMImput.IMM_AMOUNT_FC_C;
          TotAmountImpEUR := TotAmountImpEUR + MGMImput.IMM_AMOUNT_EUR_D - MGMImput.IMM_AMOUNT_EUR_C;
        end if;

        MGMImput.ACT_MGM_IMPUTATION_ID := InsertMGMImput(aVATMGMImputInfo.ACS_FINANCIAL_CURRENCY_ID,
                            aVATMGMImputInfo.ACS_ACS_FINANCIAL_CURRENCY_ID,
                            aBaseInfo.PeriodId,
                            tblProportionMANImput(Pos).ACS_CPN_ACCOUNT_ID,
                            tblProportionMANImput(Pos).ACS_CDA_ACCOUNT_ID,
                            tblProportionMANImput(Pos).ACS_PF_ACCOUNT_ID,
                            aBaseInfo.DocumentId,
                            aACT_FINANCIAL_IMPUTATION_ID,
                            aVATMGMImputInfo.IMM_TYPE,
                            'STD',
                            0,
                            aVATMGMImputInfo.IMM_DESCRIPTION,
                            MGMImput.IMM_AMOUNT_LC_D,
                            MGMImput.IMM_AMOUNT_LC_C,
                            aVATMGMImputInfo.IMM_EXCHANGE_RATE,
                            aVATMGMImputInfo.IMM_BASE_PRICE,
                            MGMImput.IMM_AMOUNT_FC_D,
                            MGMImput.IMM_AMOUNT_FC_C,
                            aBaseInfo.ValueDate,
                            aBaseInfo.TransactionDate,
                            tblProportionMANImput(Pos).ACS_QTY_UNIT_ID,
                            0,
                            0,
                            MGMImput.IMM_AMOUNT_EUR_D,
                            MGMImput.IMM_AMOUNT_EUR_C);

        ACT_IMP_MANAGEMENT.SetInfoImputationValuesIMM(MGMImput.ACT_MGM_IMPUTATION_ID, aBaseInfo.InfoImputationValues);

        TotAmountDistLC   := 0;
        TotAmountDistFC   := 0;
        TotAmountDistEUR  := 0;

        if ACT_MGM_MANAGEMENT.CalcProportionMANDistribution(tblProportionMANImput(Pos).ACT_MGM_IMPUTATION_ID, tblProportionMANDist) then

          for Pos2 in 1..tblProportionMANDist.Count loop
            MGMDist := null;

            MGMDist.MGM_AMOUNT_FC_D  := 0;
            MGMDist.MGM_AMOUNT_FC_C  := 0;
            MGMDist.MGM_AMOUNT_EUR_D := 0;
            MGMDist.MGM_AMOUNT_EUR_C := 0;

            if Pos2 = tblProportionMANDist.Count then
              if (MGMImput.IMM_AMOUNT_LC_D - MGMImput.IMM_AMOUNT_LC_C) - TotAmountDistLC > 0 then
                MGMDist.MGM_AMOUNT_LC_D  := MGMImput.IMM_AMOUNT_LC_D - TotAmountDistLC;
                MGMDist.MGM_AMOUNT_LC_C  := 0;
                if aVATMGMImputInfo.ACS_FINANCIAL_CURRENCY_ID != aVATMGMImputInfo.ACS_ACS_FINANCIAL_CURRENCY_ID then
                  MGMDist.MGM_AMOUNT_FC_D  := MGMImput.IMM_AMOUNT_FC_D - TotAmountDistFC;
                  MGMDist.MGM_AMOUNT_EUR_D := MGMImput.IMM_AMOUNT_EUR_D - TotAmountDistEUR;
                  MGMDist.MGM_AMOUNT_FC_C  := 0;
                  MGMDist.MGM_AMOUNT_EUR_C := 0;
                end if;
              else
                MGMDist.MGM_AMOUNT_LC_C  := MGMImput.IMM_AMOUNT_LC_C + TotAmountDistLC;
                MGMDist.MGM_AMOUNT_LC_D  := 0;
                if aVATMGMImputInfo.ACS_FINANCIAL_CURRENCY_ID != aVATMGMImputInfo.ACS_ACS_FINANCIAL_CURRENCY_ID then
                  MGMDist.MGM_AMOUNT_FC_C  := MGMImput.IMM_AMOUNT_FC_C + TotAmountDistFC;
                  MGMDist.MGM_AMOUNT_EUR_C := MGMImput.IMM_AMOUNT_EUR_C + TotAmountDistEUR;
                  MGMDist.MGM_AMOUNT_FC_D  := 0;
                  MGMDist.MGM_AMOUNT_EUR_D := 0;
                end if;
              end if;
            else
              MGMDist.MGM_AMOUNT_LC_D := ACS_FUNCTION.RoundAmount(MGMImput.IMM_AMOUNT_LC_D * tblProportionMANDist(Pos2).RATIO, aVATMGMImputInfo.ACS_ACS_FINANCIAL_CURRENCY_ID);
              MGMDist.MGM_AMOUNT_LC_C := ACS_FUNCTION.RoundAmount(MGMImput.IMM_AMOUNT_LC_C * tblProportionMANDist(Pos2).RATIO, aVATMGMImputInfo.ACS_ACS_FINANCIAL_CURRENCY_ID);
              if aVATMGMImputInfo.ACS_FINANCIAL_CURRENCY_ID != aVATMGMImputInfo.ACS_ACS_FINANCIAL_CURRENCY_ID then
                MGMDist.MGM_AMOUNT_FC_D := ACS_FUNCTION.RoundAmount(MGMImput.IMM_AMOUNT_FC_D * tblProportionMANDist(Pos2).RATIO, aVATMGMImputInfo.ACS_FINANCIAL_CURRENCY_ID);
                MGMDist.MGM_AMOUNT_FC_C := ACS_FUNCTION.RoundAmount(MGMImput.IMM_AMOUNT_FC_C * tblProportionMANDist(Pos2).RATIO, aVATMGMImputInfo.ACS_FINANCIAL_CURRENCY_ID);
                MGMDist.MGM_AMOUNT_EUR_D := ACS_FUNCTION.RoundNear(MGMImput.IMM_AMOUNT_EUR_D * tblProportionMANDist(Pos2).RATIO, ACS_FUNCTION.CONST_RoundAmountEUR, ACS_FUNCTION.CONST_RoundTypeEUR);
                MGMDist.MGM_AMOUNT_EUR_C := ACS_FUNCTION.RoundNear(MGMImput.IMM_AMOUNT_EUR_C * tblProportionMANDist(Pos2).RATIO, ACS_FUNCTION.CONST_RoundAmountEUR, ACS_FUNCTION.CONST_RoundTypeEUR);
              end if;

              TotAmountDistLC := TotAmountDistLC + MGMDist.MGM_AMOUNT_LC_D - MGMDist.MGM_AMOUNT_LC_C;
              TotAmountDistFC := TotAmountDistFC + MGMDist.MGM_AMOUNT_FC_D - MGMDist.MGM_AMOUNT_FC_C;
              TotAmountDistEUR := TotAmountDistEUR + MGMDist.MGM_AMOUNT_EUR_D - MGMDist.MGM_AMOUNT_EUR_C;
            end if;

            MGMDist.ACT_MGM_DISTRIBUTION_ID := InsertMGMDist(MGMImput.ACT_MGM_IMPUTATION_ID,
                                tblProportionMANDist(Pos2).ACS_PJ_ACCOUNT_ID,
                                aVATMGMImputInfo.IMM_DESCRIPTION,
                                MGMDist.MGM_AMOUNT_LC_D,
                                MGMDist.MGM_AMOUNT_FC_D,
                                MGMDist.MGM_AMOUNT_LC_C,
                                MGMDist.MGM_AMOUNT_FC_C,
                                0,
                                0,
                                MGMDist.MGM_AMOUNT_EUR_D,
                                MGMDist.MGM_AMOUNT_EUR_C);

            ACT_IMP_MANAGEMENT.SetInfoImputationValuesMGM(MGMDist.ACT_MGM_DISTRIBUTION_ID, aBaseInfo.InfoImputationValues);

          end loop;
          tblProportionMANDist.Delete;
        end if;

      end loop;
    end if;
  end CreateVATSecMAN;

  -------------------------

  function InsertVATMain(
    aBaseInfo     in out BaseInfoRecType
  , aInfoVAT      in     InfoVATRecType
  , aCalcVAT      in     CalcVATRecType
  , aCreateImput  in     boolean
  , aCreateDetTax in     boolean
  )
    return boolean
  is
    Flag     boolean                                               := true;
    FinAccId ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
  begin
    if aCreateImput then
      select init_id_seq.nextval
        into aBaseInfo.FinImputId
        from dual;

      if    (aInfoVAT.EtabCalcSheet = '1')
         or (aBaseInfo.TypeCatalogue not in('1', '2', '5', '6') ) then
        FinAccId  := aInfoVAT.PreaAccId;
      else
        FinAccId  := aInfoVAT.ProvAccId;
      end if;

      Flag  :=
            Flag
        and InsertImput(aBaseInfo.FinCurrId_LC
                      , FinAccId
                      , aBaseInfo.FinCurrId_FC
                      , aBaseInfo.PeriodId
                      , aBaseInfo.TaxCodeId
                      , aBaseInfo.DocumentId
                      , aBaseInfo.FinImputId
                      , aBaseInfo.PartImputId
                      , '1'
                      , aBaseInfo.AmountC_EUR
                      , aBaseInfo.AmountD_EUR
                      , aBaseInfo.AmountC_FC
                      , aBaseInfo.AmountD_FC
                      , aBaseInfo.AmountC_LC
                      , aBaseInfo.AmountD_LC
                      , aBaseInfo.BasePrice
                      , aBaseInfo.Description
                      , aBaseInfo.ExchangeRate
                      , 'STD'
                      , aBaseInfo.primary
                      , aBaseInfo.TransactionDate
                      , 'MAN'
                      , aBaseInfo.ValueDate
                      , null
                      , aBaseInfo.DivAccId
                       );
      ACT_IMP_MANAGEMENT.SetInfoImputationValuesIMF(aBaseInfo.FinImputId, aBaseInfo.InfoImputationValues);
    end if;

    if aCreateDetTax then
      select init_id_seq.nextval
        into aBaseInfo.DetTaxId
        from dual;

      Flag  :=
            Flag
        and InsertDetTax(null
                       , aInfoVAT.SubSetId
                       , aBaseInfo.FinImputId1
                       , aBaseInfo.DetTaxId
                       , aBaseInfo.FinImputId
                       , aBaseInfo.FinImputId2
                       , aBaseInfo.DetTaxId1
                       , aCalcVAT.BasePrice
                       , aCalcVAT.ExchangeRate
                       , aCalcVAT.IE
                       , aCalcVAT.LiabledAmount
                       , aInfoVAT.LiabledRate
                       , aInfoVAT.Rate
                       , aCalcVAT.Reduction
                       , aCalcVAT.Amount_EUR
                       , aCalcVAT.Amount_FC
                       , aCalcVAT.Amount_LC
                       , aCalcVAT.TotAmount_EUR
                       , aCalcVAT.TotAmount_FC
                       , aCalcVAT.TotAmount_LC
                       , aInfoVAT.DeductibleRate
                       , null
                       , null
                       , aCalcVAT.Encashment
                       , null
                        );
    end if;

    return Flag;
  end InsertVATMain;

-------------------------
  function InsertVATSec(
    aBaseInfo     in out BaseInfoRecType
  , aInfoVAT      in     InfoVATRecType
  , aCalcVAT      in     CalcVATRecType
  , aCreateImput  in     boolean
  , aCreateDetTax in     boolean
  )
    return boolean
  is
    Flag     boolean                                               := true;
    FinAccId ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
  begin
    if aCreateImput then
      select init_id_seq.nextval
        into aBaseInfo.FinImputId
        from dual;

      if    (aInfoVAT.EtabCalcSheet = '1')
         or (aBaseInfo.TypeCatalogue not in('2', '5', '6') ) then
        FinAccId  := aInfoVAT.PreaAccId;
      else
        FinAccId  := aInfoVAT.ProvAccId;
      end if;

      Flag  :=
            Flag
        and InsertImput(aBaseInfo.FinCurrId_LC
                      , FinAccId
                      , aBaseInfo.FinCurrId_FC
                      , aBaseInfo.PeriodId
                      , aBaseInfo.TaxCodeId
                      , aBaseInfo.DocumentId
                      , aBaseInfo.FinImputId
                      , aBaseInfo.PartImputId
                      , '1'
                      , aBaseInfo.AmountC_EUR
                      , aBaseInfo.AmountD_EUR
                      , aBaseInfo.AmountC_FC
                      , aBaseInfo.AmountD_FC
                      , aBaseInfo.AmountC_LC
                      , aBaseInfo.AmountD_LC
                      , aBaseInfo.BasePrice
                      , aBaseInfo.Description
                      , aBaseInfo.ExchangeRate
                      , 'STD'
                      , aBaseInfo.primary
                      , aBaseInfo.TransactionDate
                      , 'MAN'
                      , aBaseInfo.ValueDate
                      , null
                       );
      ACT_IMP_MANAGEMENT.SetInfoImputationValuesIMF(aBaseInfo.FinImputId, aBaseInfo.InfoImputationValues);
    end if;

    if aCreateDetTax then
      select init_id_seq.nextval
        into aBaseInfo.DetTaxId
        from dual;

      Flag  :=
            Flag
        and InsertDetTax(null
                       , aInfoVAT.SubSetId
                       , aBaseInfo.FinImputId1
                       , aBaseInfo.DetTaxId
                       , aBaseInfo.FinImputId
                       , aBaseInfo.FinImputId2
                       , aBaseInfo.DetTaxId1
                       , aCalcVAT.BasePrice
                       , aCalcVAT.ExchangeRate
                       , aCalcVAT.IE
                       , aCalcVAT.LiabledAmount
                       , aInfoVAT.LiabledRate
                       , aInfoVAT.Rate
                       , aCalcVAT.Reduction
                       , aCalcVAT.Amount_EUR
                       , aCalcVAT.Amount_FC
                       , aCalcVAT.Amount_LC
                       , aCalcVAT.TotAmount_EUR
                       , aCalcVAT.TotAmount_FC
                       , aCalcVAT.TotAmount_LC
                       , aInfoVAT.DeductibleRate
                       , null
                       , null
                       , aCalcVAT.Encashment
                       , null
                        );
    end if;

    return Flag;
  end InsertVATSec;

-------------------------
  function InsertVAT(
    aBaseInfo     in out BaseInfoRecType
  , aInfoVAT      in     InfoVATRecType
  , aCalcVAT      in     CalcVATRecType
  , aCreateImput  in     boolean
  , aCreateDetTax in     boolean
  )
    return boolean
  is
    BaseInfoAuto1 BaseInfoRecType;
    BaseInfoAuto2 BaseInfoRecType;
    Flag          boolean         := true;
  begin
    if    (aInfoVAT.PreliminaryAccId is not null)
       or (aInfoVAT.CollectedAccId is not null) then
      --Auto-Taxation
      Flag  :=     Flag
               and InsertVATMain(aBaseInfo, aInfoVAT, aCalcVAT, aCreateImput, aCreateDetTax);

      if aInfoVAT.PreliminaryAccId is not null then
        if sign(aCalcVAT.Amount_LC) < 0 then
          BaseInfoAuto1.AmountC_LC   := -aCalcVAT.Amount_LC;
          BaseInfoAuto1.AmountC_FC   := -aCalcVAT.Amount_FC;
          BaseInfoAuto1.AmountC_EUR  := -aCalcVAT.Amount_EUR;
        else
          BaseInfoAuto1.AmountD_LC   := aCalcVAT.Amount_LC;
          BaseInfoAuto1.AmountD_FC   := aCalcVAT.Amount_FC;
          BaseInfoAuto1.AmountD_EUR  := aCalcVAT.Amount_EUR;
        end if;

        BaseInfoAuto1.FinCurrId_LC          := aCalcVAT.FinCurrId_LC;
        BaseInfoAuto1.FinCurrId_FC          := aCalcVAT.FinCurrId_FC;
        BaseInfoAuto1.TaxCodeId             := aInfoVAT.PreliminaryAccId;
        --Reprise du compte division de l'écriture à l'origine
        --Celui-ci est validé lors de l'insertion et remplacé si pas valide
        BaseInfoAuto1.DivAccId              := aBaseInfo.DivAccId;
        BaseInfoAuto1.ExchangeRate          := aCalcVAT.ExchangeRate;
        BaseInfoAuto1.BasePrice             := aCalcVAT.BasePrice;
        BaseInfoAuto1.primary               := 0;
        BaseInfoAuto1.ValueDate             := aBaseInfo.ValueDate;
        BaseInfoAuto1.TransactionDate       := aBaseInfo.TransactionDate;
        BaseInfoAuto1.IE                    := 'I';   --Forcé
        BaseInfoAuto1.TypeCatalogue         := aBaseInfo.TypeCatalogue;
        BaseInfoAuto1.InfoImputationValues  := aBaseInfo.InfoImputationValues;
        BaseInfoAuto1.DocumentId            := aBaseInfo.DocumentId;
        BaseInfoAuto1.PartImputId           := aBaseInfo.PartImputId;
        BaseInfoAuto1.DetTaxId1             := aBaseInfo.DetTaxId;
        BaseInfoAuto1.Description           := ACT_FUNCTIONS.FormatDescription
                                                  (aBaseInfo.Description
                                                 , ' / ' ||
                                                   PCS.PC_FUNCTIONS.TRANSLATEWORD('TVA')
                                                 , 100
                                                  );
        BaseInfoAuto1.InfoImputationValues  := aBaseInfo.InfoImputationValues;
        BaseInfoAuto1.PeriodId              := aBaseInfo.PeriodId;
        BaseInfoAuto1.FixedVATAmounts       := true;   --montant TVA fixes (pas de recalcule)
        Flag                                :=     Flag
                                               and CreateVAT(BaseInfoAuto1, true, true);
      end if;

      if aInfoVAT.CollectedAccId is not null then
        if sign(aCalcVAT.Amount_LC) < 0 then
          BaseInfoAuto2.AmountD_LC   := -aCalcVAT.Amount_LC;
          BaseInfoAuto2.AmountD_FC   := -aCalcVAT.Amount_FC;
          BaseInfoAuto2.AmountD_EUR  := -aCalcVAT.Amount_EUR;
        else
          BaseInfoAuto2.AmountC_LC   := aCalcVAT.Amount_LC;
          BaseInfoAuto2.AmountC_FC   := aCalcVAT.Amount_FC;
          BaseInfoAuto2.AmountC_EUR  := aCalcVAT.Amount_EUR;
        end if;

        BaseInfoAuto2.FinCurrId_LC          := aCalcVAT.FinCurrId_LC;
        BaseInfoAuto2.FinCurrId_FC          := aCalcVAT.FinCurrId_FC;
        BaseInfoAuto2.TaxCodeId             := aInfoVAT.CollectedAccId;
        --Reprise du compte division de l'écriture à l'origine
        --Celui-ci est validé lors de l'insertion et remplacé si pas valide
        BaseInfoAuto2.DivAccId              := aBaseInfo.DivAccId;
        BaseInfoAuto2.ExchangeRate          := aCalcVAT.ExchangeRate;
        BaseInfoAuto2.BasePrice             := aCalcVAT.BasePrice;
        BaseInfoAuto2.primary               := 0;
        BaseInfoAuto2.ValueDate             := aBaseInfo.ValueDate;
        BaseInfoAuto2.TransactionDate       := aBaseInfo.TransactionDate;
        BaseInfoAuto2.IE                    := 'I';   --Forcé
        BaseInfoAuto2.TypeCatalogue         := aBaseInfo.TypeCatalogue;
        BaseInfoAuto2.InfoImputationValues  := aBaseInfo.InfoImputationValues;
        BaseInfoAuto2.DocumentId            := aBaseInfo.DocumentId;
        BaseInfoAuto2.PartImputId           := aBaseInfo.PartImputId;
        BaseInfoAuto2.DetTaxId1             := aBaseInfo.DetTaxId;
        BaseInfoAuto2.Description           := ACT_FUNCTIONS.FormatDescription
                                                  (aBaseInfo.Description
                                                 , ' / ' ||
                                                   PCS.PC_FUNCTIONS.TRANSLATEWORD('TVA')
                                                 , 100
                                                  );
        BaseInfoAuto2.InfoImputationValues  := aBaseInfo.InfoImputationValues;
        BaseInfoAuto2.PeriodId              := aBaseInfo.PeriodId;
        BaseInfoAuto2.FixedVATAmounts       := true;   --montant TVA fixes (pas de recalcule)
        Flag                                :=     Flag
                                               and CreateVAT(BaseInfoAuto2, true, true);
      end if;
    else
--Todo
--        Flag  := InsertVATSec(aBaseInfo, aInfoVAT, aCalcVAT, aCreateImput, aCreateDetTax);
      Flag  :=     Flag
               and InsertVATMain(aBaseInfo, aInfoVAT, aCalcVAT, aCreateImput, aCreateDetTax);
    end if;

    return Flag;
  end InsertVAT;

-------------------------
  function CreateVAT(aBaseInfo in out BaseInfoRecType, aCreateImput in boolean, aCreateDetTax in boolean)
    return boolean
  is
    Flag       boolean        := true;
    InfoVATRec InfoVATRecType;
    CalcVATRec CalcVATRecType;
  begin
    Flag  :=     Flag
             and GetInfoVAT(aBaseInfo, InfoVATRec);
    Flag  :=     Flag
             and CalcVAT(aBaseInfo, InfoVATRec, CalcVATRec);
    Flag  :=     Flag
             and InsertVAT(aBaseInfo, InfoVATRec, CalcVATRec, aCreateImput, aCreateDetTax);
    return Flag;
  end CreateVAT;

-------------------------
  function CreateVAT_ACI(aACT_FINANCIAL_IMPUTATION_ID  in ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type,
                          aUpdateDetTaxLinks in boolean default False) return boolean
  is
    Flag        boolean         := true;
    BaseInfoRec BaseInfoRecType;
    InfoVATRec  InfoVATRecType;
    CalcVATRec  CalcVATRecType;
  begin
    begin
      select ACS_PERIOD_ID
           , ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID
           , IMF_PRIMARY
           , IMF_DESCRIPTION
           , IMF_AMOUNT_LC_D
           , IMF_AMOUNT_LC_C
           , IMF_AMOUNT_EUR_D
           , IMF_AMOUNT_EUR_C
           , IMF_EXCHANGE_RATE
           , IMF_AMOUNT_FC_D
           , IMF_AMOUNT_FC_C
           , IMF_VALUE_DATE
           , ACS_TAX_CODE_ID
           , IMF_TRANSACTION_DATE
           , IMF_BASE_PRICE
           , ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_CURRENCY_ID
           , ACS_ACS_FINANCIAL_CURRENCY_ID
           , ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID
           , ACT_PART_IMPUTATION_ID
           , C_TYPE_CATALOGUE
           , ACT_FINANCIAL_DISTRIBUTION.ACS_DIVISION_ACCOUNT_ID
           , ACT_FINANCIAL_IMPUTATION.ACS_FINANCIAL_ACCOUNT_ID
        into BaseInfoRec.PeriodId
           , BaseInfoRec.DocumentId
           , BaseInfoRec.primary
           , BaseInfoRec.Description
           , BaseInfoRec.AmountD_LC
           , BaseInfoRec.AmountC_LC
           , BaseInfoRec.AmountD_EUR
           , BaseInfoRec.AmountC_EUR
           , BaseInfoRec.ExchangeRate
           , BaseInfoRec.AmountD_FC
           , BaseInfoRec.AmountC_FC
           , BaseInfoRec.ValueDate
           , BaseInfoRec.TaxCodeId
           , BaseInfoRec.TransactionDate
           , BaseInfoRec.BasePrice
           , BaseInfoRec.FinCurrId_FC
           , BaseInfoRec.FinCurrId_LC
           , BaseInfoRec.FinImputId
           , BaseInfoRec.PartImputId
           , BaseInfoRec.TypeCatalogue
           , BaseInfoRec.DivAccId
           , BaseInfoRec.FinAccId
        from ACT_FINANCIAL_IMPUTATION
           , ACT_FINANCIAL_DISTRIBUTION
           , ACT_DOCUMENT
           , ACJ_CATALOGUE_DOCUMENT
       where ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID = aACT_FINANCIAL_IMPUTATION_ID
         and ACT_DOCUMENT.ACT_DOCUMENT_ID = ACT_FINANCIAL_IMPUTATION.ACT_DOCUMENT_ID
         and ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID = ACT_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID
         and ACT_FINANCIAL_DISTRIBUTION.ACT_FINANCIAL_IMPUTATION_ID (+) = ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID;

      Flag  :=     Flag
               and GetInfoVAT(BaseInfoRec, InfoVATRec);

      select ACT_DET_TAX_ID
           , ACS_SUB_SET_ID
           , TAX_EXCHANGE_RATE
           , TAX_INCLUDED_EXCLUDED
           , TAX_LIABLED_AMOUNT
           , TAX_LIABLED_RATE
           , TAX_RATE
           , TAX_VAT_AMOUNT_FC
           , TAX_VAT_AMOUNT_LC
           , TAX_REDUCTION
           , DET_BASE_PRICE
           , TAX_VAT_AMOUNT_EUR
        into BaseInfoRec.DetTaxId
           , InfoVATRec.SubSetId
           , CalcVATRec.ExchangeRate
           , CalcVATRec.IE
           , CalcVATRec.LiabledAmount
           , InfoVATRec.LiabledRate
           , InfoVATRec.Rate
           , CalcVATRec.Amount_FC
           , CalcVATRec.Amount_LC
           , CalcVATRec.Reduction
           , CalcVATRec.BasePrice
           , CalcVATRec.Amount_EUR
        from ACT_DET_TAX
       where ACT_DET_TAX.ACT_FINANCIAL_IMPUTATION_ID = aACT_FINANCIAL_IMPUTATION_ID;
    exception
      when no_data_found then
        return false;
    end;

    -- Pas necessaire ???
    BaseInfoRec.IE           := CalcVATRec.IE;
    CalcVATRec.FinCurrId_FC  := BaseInfoRec.FinCurrId_FC;
    CalcVATRec.FinCurrId_LC  := BaseInfoRec.FinCurrId_LC;
    ACT_IMP_MANAGEMENT.GetInfoImputationValuesIMF(aACT_FINANCIAL_IMPUTATION_ID, BaseInfoRec.InfoImputationValues);
    Flag                     :=     Flag
                                and InsertVAT(BaseInfoRec, InfoVATRec, CalcVATRec, false, false);

    -- Màj des liens du ACT_DET_TAX
    if aUpdateDetTaxLinks then
      update ACT_DET_TAX
         set ACT_ACT_FINANCIAL_IMPUTATION = BaseInfoRec.FinImputId1,
             ACT2_ACT_FINANCIAL_IMPUTATION = BaseInfoRec.FinImputId2
       where ACT_DET_TAX_ID = BaseInfoRec.DetTaxId;
    end if;

    return Flag;
  end CreateVAT_ACI;

-------------------------
  function CalcVATEncashmentSlice(
    aACT_EXPIRY_ID          in ACT_EXPIRY.ACT_EXPIRY_ID%type
  , aAmountVat_LC           in ACT_EXPIRY.EXP_AMOUNT_LC%type
  , aAmountVat_FC           in ACT_EXPIRY.EXP_AMOUNT_FC%type
  , aAmountLiabledAmount_LC in ACT_DET_TAX.TAX_LIABLED_AMOUNT%type
  , aACS_TAX_CODE_ID        in ACS_TAX_CODE.ACS_TAX_CODE_ID%type
  )
    return tblCalcVATEncashSliceRecType
  is
    --Recherche des montants des tranches de la facture et calcule des proportions
    cursor SLICE_RATIO(Expiry_id ACT_EXPIRY.ACT_EXPIRY_ID%type)
    is
      select   exp.exp_amount_lc
             , decode(total.tot_amount_lc, 0, 0,(exp.exp_amount_lc / total.tot_amount_lc) ) ratio_lc
             , exp.exp_amount_fc
             , decode(total.tot_amount_fc, 0, 0,(exp.exp_amount_fc / total.tot_amount_fc) ) ratio_fc
             , exp.ACT_EXPIRY_ID
          from act_expiry exp
             , act_expiry EXP2
             , (select sum(exp3.exp_amount_lc) tot_amount_lc
                     , sum(exp3.exp_amount_fc) tot_amount_fc
                  from act_expiry exp3
                     , act_expiry exp4
                 where exp4.act_expiry_id = Expiry_id
                   and exp3.act_document_id = exp4.act_document_id
                   and exp3.exp_calc_net = 1) total
         where EXP2.act_expiry_id = Expiry_id
           and exp.act_document_id = EXP2.act_document_id
           and exp.exp_calc_net = 1
      order by exp.exp_slice asc;

    tblVATEncashmentSlice tblVATEncashmentSliceType;
    TotVATEncashmentSlice tblCalcVATEncashSliceRecType;
    i                     integer                                := 1;
    slice                 ACT_EXPIRY.EXP_SLICE%type              := 1;
    RoundType             ACS_TAX_CODE.C_ROUND_TYPE%type;
    RoundedAmount         ACS_TAX_CODE.TAX_ROUNDED_AMOUNT%type;
  begin
    -- recherche des taux de taxe et des montants d'arrondi
    select C_ROUND_TYPE
         , TAX_ROUNDED_AMOUNT
      into RoundType
         , RoundedAmount
      from ACS_TAX_CODE
     where ACS_TAX_CODE.ACS_TAX_CODE_ID = aACS_TAX_CODE_ID;

    for SLICE_RATIO_tuple in SLICE_RATIO(aACT_EXPIRY_ID) loop
      tblVATEncashmentSlice(i).AMOUNT_LC          :=
                            ACS_FUNCTION.PcsRound(SLICE_RATIO_tuple.ratio_lc * aAmountVat_LC, RoundType, RoundedAmount);
      tblVATEncashmentSlice(i).RATIO_LC           := SLICE_RATIO_tuple.ratio_lc;
      tblVATEncashmentSlice(i).AMOUNT_FC          :=
                            ACS_FUNCTION.PcsRound(SLICE_RATIO_tuple.ratio_fc * aAmountVat_FC, RoundType, RoundedAmount);
      tblVATEncashmentSlice(i).RATIO_FC           := SLICE_RATIO_tuple.ratio_fc;
      tblVATEncashmentSlice(i).LIABLED_AMOUNT_LC  :=
                  ACS_FUNCTION.PcsRound(SLICE_RATIO_tuple.ratio_lc * aAmountLiabledAmount_LC, RoundType, RoundedAmount);
      --Sauvegarde des totaux
      TotVATEncashmentSlice.AMOUNT_LC             :=
                                                   TotVATEncashmentSlice.AMOUNT_LC + tblVATEncashmentSlice(i).AMOUNT_LC;
      TotVATEncashmentSlice.RATIO_LC              := TotVATEncashmentSlice.RATIO_LC + tblVATEncashmentSlice(i).RATIO_LC;
      TotVATEncashmentSlice.AMOUNT_FC             :=
                                                   TotVATEncashmentSlice.AMOUNT_FC + tblVATEncashmentSlice(i).AMOUNT_FC;
      TotVATEncashmentSlice.RATIO_FC              := TotVATEncashmentSlice.RATIO_FC + tblVATEncashmentSlice(i).RATIO_FC;
      TotVATEncashmentSlice.LIABLED_AMOUNT_LC     :=
                                   TotVATEncashmentSlice.LIABLED_AMOUNT_LC + tblVATEncashmentSlice(i).LIABLED_AMOUNT_LC;

      if SLICE_RATIO_tuple.ACT_EXPIRY_ID = aACT_EXPIRY_ID then
        slice  := i;
      end if;

      i                                           := i + 1;
    end loop;

    --Reste sur dernière tranche
    tblVATEncashmentSlice(i - 1).AMOUNT_LC          :=
                               tblVATEncashmentSlice(i - 1).AMOUNT_LC
                               +(aAmountVat_LC - TotVATEncashmentSlice.AMOUNT_LC);
    tblVATEncashmentSlice(i - 1).RATIO_LC           :=
                                             tblVATEncashmentSlice(i - 1).RATIO_LC
                                             +(1 - TotVATEncashmentSlice.RATIO_LC);
    tblVATEncashmentSlice(i - 1).AMOUNT_FC          :=
                               tblVATEncashmentSlice(i - 1).AMOUNT_FC
                               +(aAmountVat_FC - TotVATEncashmentSlice.AMOUNT_FC);
    tblVATEncashmentSlice(i - 1).RATIO_FC           :=
                                             tblVATEncashmentSlice(i - 1).RATIO_FC
                                             +(1 - TotVATEncashmentSlice.RATIO_FC);
    tblVATEncashmentSlice(i - 1).LIABLED_AMOUNT_LC  :=
      tblVATEncashmentSlice(i - 1).LIABLED_AMOUNT_LC +
      (aAmountLiabledAmount_LC - TotVATEncashmentSlice.LIABLED_AMOUNT_LC
      );
    return tblVATEncashmentSlice(slice);
  end CalcVATEncashmentSlice;

-------------------------
  function CalcEncashmentVAT(
    aACT_EXPIRY_ID       in     ACT_EXPIRY.ACT_EXPIRY_ID%type
  , aAmountPaid_LC       in     ACT_DET_PAYMENT.DET_PAIED_LC%type
  , aAmountPaid_FC       in     ACT_DET_PAYMENT.DET_PAIED_FC%type
  , tblCalcVATEncashment out    tblCalcVATEncashmentType
  , aForcePartial        in     boolean default false
  , aACT_DET_PAYMENT_ID  in     ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID%type default null
  )
    return boolean
  is
    cursor IMP_VAT_AMOUNTS(Expiry_Id number, DetPayment_Id number)
    is
      select tax.act_det_tax_id
           , tax.tax_vat_amount_lc
           , tax.tax_vat_amount_fc
           , tax.tax_rate
           , tax.tax_liabled_rate
           , tax.tax_liabled_amount + decode(tax.tax_included_excluded, 'E', tax.tax_vat_amount_lc, 0)
                                                                                                     tax_liabled_amount
           , decode(imp2.acs_financial_account_id, null, decode(tax.tax_rate, 0, null, imp.acs_financial_account_id), imp2.acs_financial_account_id) acs_financial_account_id
           , imp.acs_tax_code_id
           , nvl(imp2.acs_financial_currency_id, imp.acs_financial_currency_id) acs_financial_currency_id
           , nvl(imp2.acs_acs_financial_currency_id, imp.acs_acs_financial_currency_id) acs_acs_financial_currency_id
           , nvl(imp2.imf_exchange_rate, tax.tax_exchange_rate) tax_exchange_rate
           , nvl(imp2.imf_base_price, tax.det_base_price) tax_base_price
           , nvl(imp2.imf_acs_division_account_id, imp.imf_acs_division_account_id) acs_division_account_id
           , acc.acc_interest
           , 0 as process_all
        from acs_account acc
           , act_financial_imputation imp2
           , act_det_tax tax
           , act_financial_imputation imp
           , act_expiry exp
       where exp.act_expiry_id = Expiry_Id
         and exp.act_document_id = imp.act_document_id
         and exp.act_part_imputation_id = imp.act_part_imputation_id(+)
         and tax.act_financial_imputation_id = imp.act_financial_imputation_id
         and tax.act_act_financial_imputation = imp2.act_financial_imputation_id(+)
         and acc.acs_account_id = imp.acs_tax_code_id
         and tax.tax_tmp_vat_encashment = 1
         and tax.tax_included_excluded not in ('R', 'S')
      union
      select tax.act_det_tax_id
           , tax.tax_vat_amount_lc
           , tax.tax_vat_amount_fc
           , tax.tax_rate
           , tax.tax_liabled_rate
           , tax.tax_liabled_amount + decode(tax.tax_included_excluded, 'E', tax.tax_vat_amount_lc, 0)
                                                                                                     tax_liabled_amount
           , decode(imp2.acs_financial_account_id, null, decode(tax.tax_rate, 0, null, imp.acs_financial_account_id), imp2.acs_financial_account_id) acs_financial_account_id
           , imp.acs_tax_code_id
           , nvl(imp2.acs_financial_currency_id, imp.acs_financial_currency_id) acs_financial_currency_id
           , nvl(imp2.acs_acs_financial_currency_id, imp.acs_acs_financial_currency_id) acs_acs_financial_currency_id
           , nvl(imp2.imf_exchange_rate, tax.tax_exchange_rate) tax_exchange_rate
           , nvl(imp2.imf_base_price, tax.det_base_price) tax_base_price
           , nvl(imp2.imf_acs_division_account_id, imp.imf_acs_division_account_id) acs_division_account_id
           , acc.acc_interest
           , 1 as process_all
        from acs_account acc
           , act_financial_imputation imp2
           , act_det_tax tax
           , act_financial_imputation imp
           , act_det_payment det
       where det.act_det_payment_id = DetPayment_Id
         and det.act_document_id = imp.act_document_id
         and det.act_part_imputation_id = imp.act_part_imputation_id(+)
         and tax.act_financial_imputation_id = imp.act_financial_imputation_id
         and tax.act_act_financial_imputation = imp2.act_financial_imputation_id(+)
         and acc.acs_account_id = imp.acs_tax_code_id
         and tax.tax_tmp_vat_encashment = 1
         and tax.tax_included_excluded not in ('R', 'S');

    IMP_VAT_AMOUNTS_tuple  IMP_VAT_AMOUNTS%rowtype;

    cursor VAT_PAID_AMOUNTS(DetTax_Id number, Expiry_Id number)
    is
      select nvl(sum(nvl(tax.TAX_VAT_AMOUNT_LC, 0) ), 0) PAIED_LC
           , nvl(sum(nvl(tax.TAX_VAT_AMOUNT_FC, 0) ), 0) PAIED_FC
           , nvl(sum(nvl(tax.TAX_LIABLED_AMOUNT, 0) + decode(tax.tax_included_excluded, 'E', tax.tax_vat_amount_lc, 0) )
               , 0
                ) TAX_LIABLED_AMOUNT_PAIED_LC
        from act_det_tax tax
           , act_financial_imputation imp
           , act_det_payment det
       where det.ACT_EXPIRY_ID = Expiry_Id
         and det.ACT_DET_PAYMENT_ID = nvl(tax.ACT_ENCASHMENT_DET_PAY_ID, imp.ACT_DET_PAYMENT_ID)
         and imp.ACT_FINANCIAL_IMPUTATION_ID = tax.ACT_FINANCIAL_IMPUTATION_ID
         and tax.ACT2_DET_TAX_ID = DetTax_Id
         and tax.tax_tmp_vat_encashment = 1;

    VAT_PAID_AMOUNTS_tuple VAT_PAID_AMOUNTS%rowtype;
    AmountTotPaid_LC       ACT_DET_PAYMENT.DET_PAIED_LC%type;
    AmountTotPaid_FC       ACT_DET_PAYMENT.DET_PAIED_FC%type;
    AmountExpiry_LC        ACT_EXPIRY.EXP_AMOUNT_LC%type;
    AmountExpiry_FC        ACT_EXPIRY.EXP_AMOUNT_FC%type;
    Ratio_LC               number(7, 6)                        := 1;
    Ratio_FC               number(7, 6)                        := 1;
    Pos                    integer                             := 1;
    vForcePartial          boolean;
    vPortfolio             integer;
    VATEncashmentSlice     tblCalcVATEncashSliceRecType;
  begin
    --Ouverture du curseur sur la TVA de la facture
    open IMP_VAT_AMOUNTS(aACT_EXPIRY_ID, aACT_DET_PAYMENT_ID);

    fetch IMP_VAT_AMOUNTS
     into IMP_VAT_AMOUNTS_tuple;

    --Test si TVA existe, sinon -> sortie
    if IMP_VAT_AMOUNTS%notfound then
      close IMP_VAT_AMOUNTS;

      return true;
    end if;

    --Recherche montants facture (tranche)
    select exp.exp_amount_lc
         , exp.exp_amount_fc
      into AmountExpiry_LC
         , AmountExpiry_FC
      from act_expiry exp
     where exp.act_expiry_id = aACT_EXPIRY_ID;

    --Recherche montants payés (inclu paiement en cours)
    ACT_EXPIRY_MANAGEMENT.TOTAL_PAYMENT_FC(aACT_EXPIRY_ID, AmountTotPaid_LC, AmountTotPaid_FC);
    vForcePartial  := aForcePartial;

    if not aForcePartial then
      --Force la reprise partiel si cover pas encore déchargé, la reprise du solde sera faite lors de la dernière décharge
      if    (AmountTotPaid_LC = AmountExpiry_LC)
         or (AmountExpiry_LC = 0) then
        select count(*)
          into vPortfolio
          from ACT_DET_PAYMENT DET
         where DET.ACT_EXPIRY_ID = aACT_EXPIRY_ID
           and ACT_VAT_MANAGEMENT.DelayedEncashmentVAT(det.ACT_DOCUMENT_ID) = 1
           and not exists(select 0
                            from ACT_COVER_DISCHARGED
                           where ACT_DOCUMENT_ID = DET.ACT_DOCUMENT_ID);

        vForcePartial  := vPortfolio > 0;
      end if;
    end if;

    if not vForcePartial then
      --Calcule des proportions
      if     (AmountTotPaid_FC != AmountExpiry_FC)
         and (AmountExpiry_FC != 0) then
        Ratio_FC  := aAmountPaid_FC / AmountExpiry_FC;
      end if;

      if     (AmountTotPaid_LC != AmountExpiry_LC)
         and (AmountExpiry_LC != 0) then
        if AmountExpiry_FC != 0 then
          Ratio_LC  := Ratio_FC;
        else
          Ratio_LC  := aAmountPaid_LC / AmountExpiry_LC;
        end if;
      end if;
    else
      --Calcule des proportions
      if AmountExpiry_FC != 0 then
        Ratio_FC  := aAmountPaid_FC / AmountExpiry_FC;
      end if;

      if AmountExpiry_LC != 0 then
        if AmountExpiry_FC != 0 then
          Ratio_LC  := Ratio_FC;
        else
          Ratio_LC  := aAmountPaid_LC / AmountExpiry_LC;
        end if;
      end if;
    end if;

    --Traitement de chaques positions de la facture avec TVA
    while IMP_VAT_AMOUNTS%found loop
      --Recherche du montant TVA déjà payé
      open VAT_PAID_AMOUNTS(IMP_VAT_AMOUNTS_tuple.ACT_DET_TAX_ID, aACT_EXPIRY_ID);

      fetch VAT_PAID_AMOUNTS
       into VAT_PAID_AMOUNTS_tuple;

      close VAT_PAID_AMOUNTS;

      --Calcul du montant TVA par rapport au tranche
      VATEncashmentSlice                                  :=
        CalcVATEncashmentSlice(aACT_EXPIRY_ID
                             , IMP_VAT_AMOUNTS_tuple.tax_vat_amount_lc
                             , IMP_VAT_AMOUNTS_tuple.tax_vat_amount_fc
                             , IMP_VAT_AMOUNTS_tuple.TAX_LIABLED_AMOUNT
                             , IMP_VAT_AMOUNTS_tuple.ACS_TAX_CODE_ID
                              );

      --Calcule du montant TVA
      if Ratio_LC = 1 then   --Paiement total -> reste
        tblCalcVATEncashment(Pos).AMOUNT_VAT_LC       :=
                                                     VATEncashmentSlice.AMOUNT_LC - VAT_PAID_AMOUNTS_tuple.PAIED_LC
                                                                                    * -1;
        tblCalcVATEncashment(Pos).TAX_LIABLED_AMOUNT  :=
                          VATEncashmentSlice.LIABLED_AMOUNT_LC - VAT_PAID_AMOUNTS_tuple.TAX_LIABLED_AMOUNT_PAIED_LC
                                                                 * -1;
      elsif IMP_VAT_AMOUNTS_tuple.process_all = 0 then   --Paiement partiel -> proportion sauf pour compensation de tva prov. de paiement (déduction, escompte)
        tblCalcVATEncashment(Pos).AMOUNT_VAT_LC       := VATEncashmentSlice.AMOUNT_LC * Ratio_LC;
        tblCalcVATEncashment(Pos).TAX_LIABLED_AMOUNT  := VATEncashmentSlice.LIABLED_AMOUNT_LC * Ratio_LC;
      else   --Compensation de tva prov. de paiement (déduction, escompte)
        tblCalcVATEncashment(Pos).AMOUNT_VAT_LC       := VATEncashmentSlice.AMOUNT_LC;
        tblCalcVATEncashment(Pos).TAX_LIABLED_AMOUNT  := VATEncashmentSlice.LIABLED_AMOUNT_LC;
      end if;

      if Ratio_FC = 1 then   --Paiement total -> reste
        tblCalcVATEncashment(Pos).AMOUNT_VAT_FC  := VATEncashmentSlice.AMOUNT_FC - VAT_PAID_AMOUNTS_tuple.PAIED_FC * -1;
      elsif IMP_VAT_AMOUNTS_tuple.process_all = 0 then   --Paiement partiel -> proportion sauf pour compensation de tva prov. de paiement (déduction, escompte)
        tblCalcVATEncashment(Pos).AMOUNT_VAT_FC  := VATEncashmentSlice.AMOUNT_FC * Ratio_FC;
      else   --Compensation de tva prov. de paiement (déduction, escompte)
        tblCalcVATEncashment(Pos).AMOUNT_VAT_FC  := VATEncashmentSlice.AMOUNT_FC;
      end if;

      --Initialisation montants écriture
      if tblCalcVATEncashment(Pos).AMOUNT_VAT_LC > 0 then
        tblCalcVATEncashment(Pos).AMOUNT_LC_D  := tblCalcVATEncashment(Pos).AMOUNT_VAT_LC;
        tblCalcVATEncashment(Pos).AMOUNT_FC_D  := tblCalcVATEncashment(Pos).AMOUNT_VAT_FC;
      else
        tblCalcVATEncashment(Pos).AMOUNT_LC_C  := tblCalcVATEncashment(Pos).AMOUNT_VAT_LC * -1;
        tblCalcVATEncashment(Pos).AMOUNT_FC_C  := tblCalcVATEncashment(Pos).AMOUNT_VAT_FC * -1;
      end if;

      --Initialisation des autres champs
      tblCalcVATEncashment(Pos).ACS_FINANCIAL_ACCOUNT_ID      := IMP_VAT_AMOUNTS_tuple.ACS_FINANCIAL_ACCOUNT_ID;
      tblCalcVATEncashment(Pos).ACS_TAX_CODE_ID               := IMP_VAT_AMOUNTS_tuple.ACS_TAX_CODE_ID;
      tblCalcVATEncashment(Pos).RATIO                         := Ratio_LC;
      tblCalcVATEncashment(Pos).TAX_RATE                      := IMP_VAT_AMOUNTS_tuple.TAX_RATE;
      tblCalcVATEncashment(Pos).ACT_DET_TAX_ID                := IMP_VAT_AMOUNTS_tuple.ACT_DET_TAX_ID;
      tblCalcVATEncashment(Pos).ACS_FINANCIAL_CURRENCY_ID     := IMP_VAT_AMOUNTS_tuple.ACS_FINANCIAL_CURRENCY_ID;
      tblCalcVATEncashment(Pos).ACS_ACS_FINANCIAL_CURRENCY_ID := IMP_VAT_AMOUNTS_tuple.ACS_ACS_FINANCIAL_CURRENCY_ID;
      tblCalcVATEncashment(Pos).IMF_EXCHANGE_RATE             := IMP_VAT_AMOUNTS_tuple.TAX_EXCHANGE_RATE;
      tblCalcVATEncashment(Pos).IMF_BASE_PRICE                := IMP_VAT_AMOUNTS_tuple.TAX_BASE_PRICE;
      tblCalcVATEncashment(Pos).ACS_DIVISION_ACCOUNT_ID       := IMP_VAT_AMOUNTS_tuple.ACS_DIVISION_ACCOUNT_ID;
      tblCalcVATEncashment(Pos).TAX_LIABLED_RATE              := IMP_VAT_AMOUNTS_tuple.TAX_LIABLED_RATE;
      Pos                                                     := Pos + 1;

      fetch IMP_VAT_AMOUNTS
       into IMP_VAT_AMOUNTS_tuple;
    end loop;

    close IMP_VAT_AMOUNTS;

    return true;
  end CalcEncashmentVAT;

-------------------------

  -------------------------------
/**
* Description
*    Création des imputations pour extourne TVA et enregistrement TVA dans ACT_DET_TAX.
**/
  function InsertEncashmentVAT(
    aACT_DOCUMENT_ID               ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aACS_PERIOD_ID                 ACS_PERIOD.ACS_PERIOD_ID%type
  , aACS_AUXILIARY_ACCOUNT_ID      ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACT_DET_PAYMENT_ID            ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID%type
  , aIMF_TRANSACTION_DATE          ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aIMF_VALUE_DATE                ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , aDescription                   ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
  , aACT_PART_IMPUTATION_ID        ACT_FINANCIAL_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , tblCalcVATEncashment           tblCalcVATEncashmentType
  , aPortfolio                     boolean default false
  )
    return boolean
  is
  begin
    return InsertEncashmentVAT(aACT_DOCUMENT_ID , aACS_PERIOD_ID , aACS_AUXILIARY_ACCOUNT_ID , aACT_DET_PAYMENT_ID , aIMF_TRANSACTION_DATE , aIMF_VALUE_DATE , aDescription , aACT_PART_IMPUTATION_ID , tblCalcVATEncashment , null , aPortfolio);
  end InsertEncashmentVAT;
  -------------------------------
/**
* Description
*    Création des imputations pour extourne TVA et enregistrement TVA dans ACT_DET_TAX.
**/
  function InsertEncashmentVAT(
    aACT_DOCUMENT_ID               ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aACS_PERIOD_ID                 ACS_PERIOD.ACS_PERIOD_ID%type
  , aACS_AUXILIARY_ACCOUNT_ID      ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aACT_DET_PAYMENT_ID            ACT_DET_PAYMENT.ACT_DET_PAYMENT_ID%type
  , aIMF_TRANSACTION_DATE          ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aIMF_VALUE_DATE                ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , aDescription                   ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
  , aACT_PART_IMPUTATION_ID        ACT_FINANCIAL_IMPUTATION.ACT_PART_IMPUTATION_ID%type
  , tblCalcVATEncashment           tblCalcVATEncashmentType
  , aInfoImputationValues          ACT_IMP_MANAGEMENT.InfoImputationValuesRecType
  , aPortfolio                     boolean default false
  )
    return boolean
  is
    FinImputation_id ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    PreaAccount_id   ACS_TAX_CODE.ACS_PREA_ACCOUNT_ID%type;
    ProvAccount_id   ACS_TAX_CODE.ACS_PROV_ACCOUNT_ID%type;
    DetTaxId         ACT_DET_TAX.ACT_DET_TAX_ID%type;
    FinDetPayId      ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    TaxDetPayId      ACT_FINANCIAL_IMPUTATION.ACT_FINANCIAL_IMPUTATION_ID%type;
    Flag             boolean                                                     := true;
  begin
    -- Si décharge portefeuille (document CG), on fait le lien sur le paiement à l'origine de la TVA par
    --  ACT_DET_TAX.ACT_ENCASHMENT_DET_PAY_ID, sinon par ACT_FINANCIAL_IMPUTATION.ACT_DET_PAYMENT_ID
    if aPortfolio then
      FinDetPayId  := null;
      TaxDetPayId  := aACT_DET_PAYMENT_ID;
    else
      FinDetPayId  := aACT_DET_PAYMENT_ID;
      TaxDetPayId  := null;
    end if;

    for i in 1 .. tblCalcVATEncashment.count loop
      select ACS_PREA_ACCOUNT_ID
           , ACS_PROV_ACCOUNT_ID
        into PreaAccount_id
           , ProvAccount_id
        from ACS_TAX_CODE CT
       where CT.ACS_TAX_CODE_ID = tblCalcVATEncashment(i).ACS_TAX_CODE_ID;

      if     (PreaAccount_id is not null) and
          -- DEVFIN-13227
          ((tblCalcVATEncashment(i).TAX_RATE = 0)
              or (    (tblCalcVATEncashment(i).AMOUNT_LC_D != 0)
                 or (tblCalcVATEncashment(i).AMOUNT_LC_C != 0) )) then
        --Extourne
        select init_id_seq.nextval
          into FinImputation_id
          from dual;

        Flag  :=
              Flag
          and InsertImput(tblCalcVATEncashment(i).ACS_ACS_FINANCIAL_CURRENCY_ID
                        , nvl(tblCalcVATEncashment(i).ACS_FINANCIAL_ACCOUNT_ID, ProvAccount_id)
                        , tblCalcVATEncashment(i).ACS_FINANCIAL_CURRENCY_ID
                        , aACS_PERIOD_ID
                        , tblCalcVATEncashment(i).ACS_TAX_CODE_ID
                        , aACT_DOCUMENT_ID
                        , FinImputation_id
                        , aACT_PART_IMPUTATION_ID
                        , '9'
                        , 0
                        , 0
                        , tblCalcVATEncashment(i).AMOUNT_FC_D
                        , tblCalcVATEncashment(i).AMOUNT_FC_C
                        , tblCalcVATEncashment(i).AMOUNT_LC_D
                        , tblCalcVATEncashment(i).AMOUNT_LC_C
                        , tblCalcVATEncashment(i).IMF_BASE_PRICE
                        , aDescription
                        , tblCalcVATEncashment(i).IMF_EXCHANGE_RATE
                        , 'STD'
                        , 0
                        , aIMF_TRANSACTION_DATE
                        , 'VAT'
                        , aIMF_VALUE_DATE
                        , FinDetPayId
                        , tblCalcVATEncashment(i).ACS_DIVISION_ACCOUNT_ID
                         );

        -- màj des info complémentaires
        if aInfoImputationValues.GroupType is not null then
          ACT_IMP_MANAGEMENT.SetInfoImputationValuesIMF(FinImputation_id, aInfoImputationValues);
        end if;

        select init_id_seq.nextval
          into DetTaxId
          from dual;

        Flag  :=
              Flag
          and InsertDetTax(null
                         , ACS_FUNCTION.GetSubSetIdByAccount(tblCalcVATEncashment(i).ACS_TAX_CODE_ID)
                         , null
                         , DetTaxId
                         , FinImputation_id
                         , null
                         , tblCalcVATEncashment(i).ACT_DET_TAX_ID
                         , tblCalcVATEncashment(i).IMF_BASE_PRICE
                         , tblCalcVATEncashment(i).IMF_EXCHANGE_RATE
                         , 'R'
                         , -(tblCalcVATEncashment(i).TAX_LIABLED_AMOUNT)
                         , tblCalcVATEncashment(i).TAX_LIABLED_RATE
                         , tblCalcVATEncashment(i).TAX_RATE
                         , 0
                         , 0
                         , -(tblCalcVATEncashment(i).AMOUNT_FC_D - tblCalcVATEncashment(i).AMOUNT_FC_C)
                         , -(tblCalcVATEncashment(i).AMOUNT_LC_D - tblCalcVATEncashment(i).AMOUNT_LC_C)
                         , 0
                         , -(tblCalcVATEncashment(i).AMOUNT_FC_D - tblCalcVATEncashment(i).AMOUNT_FC_C)
                         , -(tblCalcVATEncashment(i).AMOUNT_LC_D - tblCalcVATEncashment(i).AMOUNT_LC_C)
                         , 100
                         , null
                         , null
                         , 1
                         , TaxDetPayId
                          );

        --Passage de la TVA
        select init_id_seq.nextval
          into FinImputation_id
          from dual;

        Flag  :=
              Flag
          and InsertImput(tblCalcVATEncashment(i).ACS_ACS_FINANCIAL_CURRENCY_ID
                        , PreaAccount_id
                        , tblCalcVATEncashment(i).ACS_FINANCIAL_CURRENCY_ID
                        , aACS_PERIOD_ID
                        , tblCalcVATEncashment(i).ACS_TAX_CODE_ID
                        , aACT_DOCUMENT_ID
                        , FinImputation_id
                        , aACT_PART_IMPUTATION_ID
                        , '9'
                        , 0
                        , 0
                        , tblCalcVATEncashment(i).AMOUNT_FC_C
                        , tblCalcVATEncashment(i).AMOUNT_FC_D
                        , tblCalcVATEncashment(i).AMOUNT_LC_C
                        , tblCalcVATEncashment(i).AMOUNT_LC_D
                        , tblCalcVATEncashment(i).IMF_BASE_PRICE
                        , aDescription
                        , tblCalcVATEncashment(i).IMF_EXCHANGE_RATE
                        , 'STD'
                        , 0
                        , aIMF_TRANSACTION_DATE
                        , 'VAT'
                        , aIMF_VALUE_DATE
                        , FinDetPayId
                        , tblCalcVATEncashment(i).ACS_DIVISION_ACCOUNT_ID
                         );

        -- màj des info complémentaires
        if aInfoImputationValues.GroupType is not null then
          ACT_IMP_MANAGEMENT.SetInfoImputationValuesIMF(FinImputation_id, aInfoImputationValues);
        end if;

        select init_id_seq.nextval
          into DetTaxId
          from dual;

        Flag  :=
              Flag
          and InsertDetTax(null
                         , ACS_FUNCTION.GetSubSetIdByAccount(tblCalcVATEncashment(i).ACS_TAX_CODE_ID)
                         , null
                         , DetTaxId
                         , FinImputation_id
                         , null
                         , tblCalcVATEncashment(i).ACT_DET_TAX_ID
                         , tblCalcVATEncashment(i).IMF_BASE_PRICE
                         , tblCalcVATEncashment(i).IMF_EXCHANGE_RATE
                         , 'R'
                         , tblCalcVATEncashment(i).TAX_LIABLED_AMOUNT
                         , tblCalcVATEncashment(i).TAX_LIABLED_RATE
                         , tblCalcVATEncashment(i).TAX_RATE
                         , 0
                         , 0
                         , tblCalcVATEncashment(i).AMOUNT_FC_D - tblCalcVATEncashment(i).AMOUNT_FC_C
                         , tblCalcVATEncashment(i).AMOUNT_LC_D - tblCalcVATEncashment(i).AMOUNT_LC_C
                         , 0
                         , tblCalcVATEncashment(i).AMOUNT_FC_D - tblCalcVATEncashment(i).AMOUNT_FC_C
                         , tblCalcVATEncashment(i).AMOUNT_LC_D - tblCalcVATEncashment(i).AMOUNT_LC_C
                         , 100
                         , null
                         , null
                         , 0
                         , TaxDetPayId
                          );
      end if;
    end loop;

    return Flag;
  end InsertEncashmentVAT;

---------------------------------------------------------------------------------------------------------------------
  function DelayedEncashmentVAT(
    aACT_DOCUMENT_ID          ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type default null
  )
    return number
  is
    vResult   integer;
    vFinAccId ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
  begin
    if aACS_FINANCIAL_ACCOUNT_ID is null then
      --Recherche compte fin de l'écriture primaire
      select min(IMP.ACS_FINANCIAL_ACCOUNT_ID)
        into vFinAccId
        from ACT_FINANCIAL_IMPUTATION IMP
       where IMP.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and IMP.IMF_PRIMARY = 1;

      if vFinAccId is null then
        --Recherche compte fin du document (l'écriture primaire du SBVR est créé à la fin de la comptabilisation)
        select min(ACS_FINANCIAL_ACCOUNT_ID)
          into vFinAccId
          from ACT_DOCUMENT
         where ACT_DOCUMENT_ID = aACT_DOCUMENT_ID;
      end if;
    else
      vFinAccId  := aACS_FINANCIAL_ACCOUNT_ID;
    end if;

    --Recherche si type de compte portfolio
    select nvl(min(FIN.FIN_PORTFOLIO), 0)
      into vResult
      from ACS_FINANCIAL_ACCOUNT FIN
     where FIN.ACS_FINANCIAL_ACCOUNT_ID = vFinAccId;

    -- Test si un flux est définie pour ce type de document
    if vResult != 0 then
      select count(*)
        into vResult
        from ACJ_FLOW FLO
           , ACT_DOCUMENT DOC
       where DOC.ACT_DOCUMENT_ID = aACT_DOCUMENT_ID
         and FLO.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID;
    end if;

    if vResult != 0 then
      return 1;
    else
      return 0;
    end if;
  end DelayedEncashmentVAT;

---------------------------------------------------------------------------------------------------------------------
  procedure PortfolioEncashmentVAT(
    aACT_DOCUMENT_ID      ACT_DOCUMENT.ACT_DOCUMENT_ID%type
  , aACS_PERIOD_ID        ACS_PERIOD.ACS_PERIOD_ID%type
  , aIMF_TRANSACTION_DATE ACT_FINANCIAL_IMPUTATION.IMF_TRANSACTION_DATE%type
  , aIMF_VALUE_DATE       ACT_FINANCIAL_IMPUTATION.IMF_VALUE_DATE%type
  , aDescription          ACT_FINANCIAL_IMPUTATION.IMF_DESCRIPTION%type
  )
  is
    cursor DetPaymentCursor(DocId ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    is
      select   DET.*
             , nvl(PAR.PAR_EXCHANGE_RATE, 0) PAR_EXCHANGE_RATE
             , nvl(PAR.PAR_BASE_PRICE, 0) PAR_BASE_PRICE
             , PAR.ACS_FINANCIAL_CURRENCY_ID
             , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
             , COV.COV_NUMBER
             , rank() over(partition by DET.ACT_EXPIRY_ID order by COV.ACT_COVER_INFORMATION_ID) RANKING   --Numérotation des paiement sur la même expiry
          from ACT_PART_IMPUTATION PAR
             , ACT_DET_PAYMENT DET
             , ACT_COVER_INFORMATION COV
             , ACT_COVER_DISCHARGED DIS
             , ACT_FINANCIAL_IMPUTATION IMP
         where IMP.ACT_DOCUMENT_ID = DocId
           and DIS.ACT_FINANCIAL_IMPUTATION_ID = IMP.ACT_FINANCIAL_IMPUTATION_ID
           and DET.ACT_DOCUMENT_ID = DIS.ACT_DOCUMENT_ID
           and DET.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
           and COV.ACT_COVER_INFORMATION_ID = DIS.ACT_COVER_INFORMATION_ID
      order by DET.ACT_EXPIRY_ID
             , DET.DET_PAIED_LC;

    tblCalcVATEncashment ACT_VAT_MANAGEMENT.tblCalcVATEncashmentType;
    Flag                 boolean;
  begin
    --Création écriture reprise TVA provisoire
    if upper(PCS.PC_CONFIG.GetConfig('ACT_TAX_VAT_ENCASHMENT') ) = 'TRUE' then
      for DetPaymentTuple in DetPaymentCursor(aACT_DOCUMENT_ID) loop
        if ACT_VAT_MANAGEMENT.DelayedEncashmentVAT(DetPaymentTuple.ACT_DOCUMENT_ID) != 0 then
          tblCalcVATEncashment.delete;
          --Sur les lignes avec un RANKING <> 1 on force le calcul proportionnel pour s'assurer que seul
          -- la dernier paiement d'une échéance récupère le solde de la TVA prov.
          Flag  :=
                Flag
            and CalcEncashmentVAT(DetPaymentTuple.ACT_EXPIRY_ID
                                , DetPaymentTuple.DET_PAIED_LC +
                                  DetPaymentTuple.DET_DISCOUNT_LC +
                                  DetPaymentTuple.DET_DEDUCTION_LC +
                                  DetPaymentTuple.DET_DIFF_EXCHANGE
                                , DetPaymentTuple.DET_PAIED_FC +
                                  DetPaymentTuple.DET_DISCOUNT_FC +
                                  DetPaymentTuple.DET_DEDUCTION_FC
                                , tblCalcVATEncashment
                                , DetPaymentTuple.RANKING != 1
                                , DetPaymentTuple.ACT_DET_PAYMENT_ID
                                 );
          Flag  :=
                Flag
            and InsertEncashmentVAT
                  (aACT_DOCUMENT_ID
                 , aACS_PERIOD_ID
                 , null
                 , DetPaymentTuple.ACT_DET_PAYMENT_ID
                 , aIMF_TRANSACTION_DATE
                 , aIMF_VALUE_DATE
                 , ACT_FUNCTIONS.FormatDescription
                                                  (aDescription
                                                 , ' / ' ||
                                                   PCS.PC_FUNCTIONS.TRANSLATEWORD('TVA / contres prestations reçues') ||
                                                   ' / ' ||
                                                   DetPaymentTuple.COV_NUMBER
                                                 , 100
                                                  )
                 , null
                 , tblCalcVATEncashment
                 , true
                  );
        end if;
      end loop;
    end if;
  end PortfolioEncashmentVAT;

---------------------------------------------------------------------------------------------------------------------
  function GetAccountIdOfVat(aACT_FINANCIAL_IMPUTATION_ID number)
    return number
  is
    AccountId ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type;
  begin
    select ACS_FINANCIAL_ACCOUNT_ID
      into AccountId
      from ACT_FINANCIAL_IMPUTATION
     where ACT_FINANCIAL_IMPUTATION_ID = aACT_FINANCIAL_IMPUTATION_ID;

    return nvl(AccountId, 0);
  end GetAccountIdOfVat;

  ---------------------------------------------------------------------------------------------------------------------
/*
  function CalcLiabledAmount(Amount number,
                             Liabled_rate number) return number
  is
  begin
   return Round((Amount * Liabled_rate / 100), 2);
  end CalcLiabledAmount;
*/
  ---------------------------------------------------------------------------------------------------------------------
  function CalcLiabledAmount(
    aAmount   in number
  , aInfoVAT  in InfoVATRecType
  , aIE       in ACT_DET_TAX.TAX_INCLUDED_EXCLUDED%type
  , aAmountIE in ACT_DET_TAX.TAX_INCLUDED_EXCLUDED%type default ''
  )
    return ACT_DET_TAX.TAX_LIABLED_AMOUNT%type
  is
    result ACT_DET_TAX.TAX_LIABLED_AMOUNT%type;
  begin
    result  := 0;

    if     (aAmount != 0)
       and (aInfoVAT.LiabledRate <> 0) then
      if aIE != 'I' then
        if    aAmountIE = 'I'
           or aInfoVAT.Rate = 0 then
          result  := (aAmount * aInfoVAT.LiabledRate) /(100 + aInfoVAT.Rate);
        else
          result  :=
            ( (aAmount +( (aAmount * aInfoVAT.LiabledRate) /( (100 * 100 / aInfoVAT.Rate) + 100 - aInfoVAT.LiabledRate) )
              ) *
             aInfoVAT.LiabledRate
            ) /
            (100 + aInfoVAT.Rate);
        end if;
      else
        result  := (aAmount * aInfoVAT.LiabledRate) / 100;
      end if;

      --arrondi à deux décimales
      result  := round(result, 2);
    end if;

    return result;
  end CalcLiabledAmount;

---------------------------------------------------------------------------------------------------------------------
  function GetIEOfJobType(aACJ_JOB_TYPE_ID ACJ_JOB_TYPE.ACJ_JOB_TYPE_ID%type)
    return ACT_DET_TAX.TAX_INCLUDED_EXCLUDED%type
  is
    IE ACT_DET_TAX.TAX_INCLUDED_EXCLUDED%type;
  begin
    select decode(max(EVE_VAT_METHOD), 1, 'E', 0, 'I', '')
      into IE
      from ACJ_EVENT
     where ACJ_EVENT.ACJ_JOB_TYPE_ID = aACJ_JOB_TYPE_ID
       and C_TYPE_EVENT = '1';

    return IE;
  end GetIEOfJobType;

---------------------------------------------------------------------------------------------------------------------
  function GetFinVATPossible(aACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type)
    return number
  is
    VATPossible number(1);
  begin
    select nvl(max(FIN_VAT_POSSIBLE), 0)
      into VATPossible
      from ACS_FINANCIAL_ACCOUNT
     where ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID;

    return VATPossible;
  end GetFinVATPossible;

---------------------------------------------------------------------------------------------------------------------
  function GetFinDefaultVAT(aACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type)
    return ACS_TAX_CODE.ACS_TAX_CODE_ID%type
  is
    VATCode ACS_TAX_CODE.ACS_TAX_CODE_ID%type;
  begin
    select max(ACS_DEF_VAT_CODE_ID)
      into VATCode
      from ACS_FINANCIAL_ACCOUNT
     where ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID;

    return VATCode;
  end GetFinDefaultVAT;

---------------------------------------------------------------------------------------------------------------------
  function GetInitVATOld(
    aACJ_CATALOGUE_DOCUMENT_ID ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
  , aPAC_SUPPLIER_PARTNER_ID   PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  , aPAC_CUSTOM_PARTNER_ID     PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type
  )
    return ACS_TAX_CODE.ACS_TAX_CODE_ID%type
  is
    VATCode ACS_TAX_CODE.ACS_TAX_CODE_ID%type;
  begin
    if nvl(aPAC_SUPPLIER_PARTNER_ID, 0) != 0 then
      select ACS_TAX_CODE_ID
        into VATCode
        from (select   ACS_TAX_CODE.ACS_TAX_CODE_ID
                  from ACS_ACCOUNT
                     , ACJ_CATALOGUE_DOCUMENT
                     , ACS_TAX_CODE
                     , PAC_SUPPLIER_PARTNER
                 where PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID = aPAC_SUPPLIER_PARTNER_ID
                   and ACS_TAX_CODE.DIC_TYPE_SUBMISSION_ID = PAC_SUPPLIER_PARTNER.DIC_TYPE_SUBMISSION_ID
                   and ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID = aACJ_CATALOGUE_DOCUMENT_ID
                   and ACS_TAX_CODE.ACS_VAT_DET_ACCOUNT_ID = PAC_SUPPLIER_PARTNER.ACS_VAT_DET_ACCOUNT_ID
                   and (   ACS_TAX_CODE.DIC_TYPE_MOVEMENT_ID = ACJ_CATALOGUE_DOCUMENT.DIC_TYPE_MOVEMENT_ID
                        or ACJ_CATALOGUE_DOCUMENT.DIC_TYPE_MOVEMENT_ID is null
                       )
                   and ACS_TAX_CODE.ACS_TAX_CODE_ID = ACS_ACCOUNT.ACS_ACCOUNT_ID
              order by ACS_ACCOUNT.ACC_NUMBER asc)
       where rownum = 1;
    elsif nvl(aPAC_CUSTOM_PARTNER_ID, 0) != 0 then
      select ACS_TAX_CODE_ID
        into VATCode
        from (select   ACS_TAX_CODE.ACS_TAX_CODE_ID
                  from ACS_ACCOUNT
                     , ACJ_CATALOGUE_DOCUMENT
                     , ACS_TAX_CODE
                     , PAC_CUSTOM_PARTNER
                 where PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID = aPAC_CUSTOM_PARTNER_ID
                   and ACS_TAX_CODE.DIC_TYPE_SUBMISSION_ID = PAC_CUSTOM_PARTNER.DIC_TYPE_SUBMISSION_ID
                   and ACS_TAX_CODE.ACS_VAT_DET_ACCOUNT_ID = PAC_CUSTOM_PARTNER.ACS_VAT_DET_ACCOUNT_ID
                   and ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID = aACJ_CATALOGUE_DOCUMENT_ID
                   and (   ACS_TAX_CODE.DIC_TYPE_MOVEMENT_ID = ACJ_CATALOGUE_DOCUMENT.DIC_TYPE_MOVEMENT_ID
                        or ACJ_CATALOGUE_DOCUMENT.DIC_TYPE_MOVEMENT_ID is null
                       )
                   and ACS_TAX_CODE.ACS_TAX_CODE_ID = ACS_ACCOUNT.ACS_ACCOUNT_ID
              order by ACS_ACCOUNT.ACC_NUMBER asc)
       where rownum = 1;
    else
      select ACS_TAX_CODE_ID
        into VATCode
        from (select   ACS_TAX_CODE.ACS_TAX_CODE_ID
                  from ACS_ACCOUNT
                     , ACJ_CATALOGUE_DOCUMENT
                     , ACS_TAX_CODE
                 where ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID = aACJ_CATALOGUE_DOCUMENT_ID
                   and ACS_TAX_CODE.DIC_TYPE_MOVEMENT_ID = ACJ_CATALOGUE_DOCUMENT.DIC_TYPE_MOVEMENT_ID
                   and ACS_TAX_CODE.ACS_TAX_CODE_ID = ACS_ACCOUNT.ACS_ACCOUNT_ID
              order by ACS_ACCOUNT.ACC_NUMBER asc)
       where rownum = 1;
    end if;

    return VATCode;
  end GetInitVATOld;

---------------------------------------------------------------------------------------------------------------------
  function GetInitVAT(
    aACS_FINANCIAL_ACCOUNT_ID  ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type
  , aACJ_CATALOGUE_DOCUMENT_ID ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type
  , aPAC_SUPPLIER_PARTNER_ID   PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type
  , aPAC_CUSTOM_PARTNER_ID     PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type
  )
    return ACS_TAX_CODE.ACS_TAX_CODE_ID%type
  is
    vVATCode ACS_TAX_CODE.ACS_TAX_CODE_ID%type;
    vDefVATCode ACS_TAX_CODE.ACS_TAX_CODE_ID%type;
    vVATGoodId ACS_TAX_CODE.DIC_TYPE_VAT_GOOD_ID%type;
  begin
    vVATCode := null;

    select max(ACS_DEF_VAT_CODE_ID)
         , max(DIC_TYPE_VAT_GOOD_ID)
      into vDefVATCode
         , vVATGoodId
      from ACS_FINANCIAL_ACCOUNT
     where ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID = aACS_FINANCIAL_ACCOUNT_ID;

    -- Si sans partenaire et avec compte par défaut -> on retourne le compte
    if nvl(aPAC_SUPPLIER_PARTNER_ID, 0) = 0 and vDefVATCode is not null then
      vVATCode := vDefVATCode;
    end if;

    -- Recherche avec VAT_Good et tout les DICO
    if vVATCode is null and vVATGoodId is not null then
      if nvl(aPAC_SUPPLIER_PARTNER_ID, 0) != 0 then
        select ACS_TAX_CODE_ID
          into vVATCode
          from (select   ACS_TAX_CODE.ACS_TAX_CODE_ID
                    from ACS_ACCOUNT
                       , ACJ_CATALOGUE_DOCUMENT
                       , ACS_TAX_CODE
                       , PAC_SUPPLIER_PARTNER
                   where PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID = aPAC_SUPPLIER_PARTNER_ID
                     and ACS_TAX_CODE.DIC_TYPE_SUBMISSION_ID = PAC_SUPPLIER_PARTNER.DIC_TYPE_SUBMISSION_ID
                     and ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID = aACJ_CATALOGUE_DOCUMENT_ID
                     and ACS_TAX_CODE.DIC_TYPE_MOVEMENT_ID = ACJ_CATALOGUE_DOCUMENT.DIC_TYPE_MOVEMENT_ID
                     and ACS_TAX_CODE.ACS_TAX_CODE_ID = ACS_ACCOUNT.ACS_ACCOUNT_ID
                     and ACS_TAX_CODE.ACS_VAT_DET_ACCOUNT_ID = PAC_SUPPLIER_PARTNER.ACS_VAT_DET_ACCOUNT_ID
                     and ACS_TAX_CODE.DIC_TYPE_VAT_GOOD_ID = vVATGoodId
                     and nvl(ACS_ACCOUNT.ACC_BLOCKED, 0) != 1
                order by ACS_ACCOUNT.ACC_NUMBER asc)
         where rownum = 1;
      elsif nvl(aPAC_CUSTOM_PARTNER_ID, 0) != 0 then
        select ACS_TAX_CODE_ID
          into vVATCode
          from (select   ACS_TAX_CODE.ACS_TAX_CODE_ID
                    from ACS_ACCOUNT
                       , ACJ_CATALOGUE_DOCUMENT
                       , ACS_TAX_CODE
                       , PAC_CUSTOM_PARTNER
                   where PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID = aPAC_CUSTOM_PARTNER_ID
                     and ACS_TAX_CODE.DIC_TYPE_SUBMISSION_ID = PAC_CUSTOM_PARTNER.DIC_TYPE_SUBMISSION_ID
                     and ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID = aACJ_CATALOGUE_DOCUMENT_ID
                     and ACS_TAX_CODE.DIC_TYPE_MOVEMENT_ID = ACJ_CATALOGUE_DOCUMENT.DIC_TYPE_MOVEMENT_ID
                     and ACS_TAX_CODE.ACS_TAX_CODE_ID = ACS_ACCOUNT.ACS_ACCOUNT_ID
                     and ACS_TAX_CODE.ACS_VAT_DET_ACCOUNT_ID = PAC_CUSTOM_PARTNER.ACS_VAT_DET_ACCOUNT_ID
                     and ACS_TAX_CODE.DIC_TYPE_VAT_GOOD_ID = vVATGoodId
                     and nvl(ACS_ACCOUNT.ACC_BLOCKED, 0) != 1
                order by ACS_ACCOUNT.ACC_NUMBER asc)
         where rownum = 1;
      else
        select ACS_TAX_CODE_ID
          into vVATCode
          from (select   ACS_TAX_CODE.ACS_TAX_CODE_ID
                    from ACS_ACCOUNT
                       , ACJ_CATALOGUE_DOCUMENT
                       , ACS_TAX_CODE
                   where ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID = aACJ_CATALOGUE_DOCUMENT_ID
                     and ACS_TAX_CODE.DIC_TYPE_MOVEMENT_ID = ACJ_CATALOGUE_DOCUMENT.DIC_TYPE_MOVEMENT_ID
                     and ACS_TAX_CODE.ACS_TAX_CODE_ID = ACS_ACCOUNT.ACS_ACCOUNT_ID
                     and ACS_TAX_CODE.DIC_TYPE_VAT_GOOD_ID = vVATGoodId
                     and nvl(ACS_ACCOUNT.ACC_BLOCKED, 0) != 1
                order by ACS_ACCOUNT.ACC_NUMBER asc)
         where rownum = 1;
      end if;
    end if;

    -- Si doc avec partenaire et pas trouvé de cpte précédement, on prend le cpte par défaut.
    if vVATCode is null and vDefVATCode is not null then
      vVATCode := vDefVATCode;
    end if;

    -- Recherche avec l'ancienne méthode sans DIC_TYPE_VAT_GOOD_ID
    if vVATCode is null then
      vVATCode := GetInitVATOld(aACJ_CATALOGUE_DOCUMENT_ID, aPAC_SUPPLIER_PARTNER_ID, aPAC_CUSTOM_PARTNER_ID);
    end if;

    return vVATCode;
  end GetInitVAT;

end ACT_VAT_MANAGEMENT;
